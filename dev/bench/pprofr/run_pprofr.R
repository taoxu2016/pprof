# The pprofR benchmark baseline (LOGISTIC_L1_PLAN §3.7; LOGISTIC_DESIGN §I; DEC-160): pprofR 0.2.0's tasks on the
# scenarios of scenarios.R, each in a fresh R process with pprofR from its isolated library
# (dev/reference/pprofr/lib) and bench from the user library. From Phase L2 on, the package's binomial and clustered
# tasks are measured against these in the same process (DEC-038's pairing; the brief's §3.7: no slower than pprofR).
#
# Usage, from the repository root:
#   Rscript dev/bench/pprofr/run_pprofr.R <data dir> <output csv> [--only REGEX]
# The data directory receives each scenario's rows on first use. Each task follows dev/bench/harness.R's
# measurements: the first run's time, the process's peak memory before and after it, gc()'s maximum of R's heap,
# and bench::mark() with at least 5 runs (3 when the first run takes 10 s or more, 1 when it takes 60 s or more).
# Fits and the other inputs of a method are made untimed in the same process. A task whose cost is not affordable
# here is recorded as skipped with the reason: the exact test when a provider has more than 5,000 trials (pprofR's
# Poisson-binomial distribution over the trials costs O(T^2) per provider), its intervals beyond m T^2 = 1e8, and
# the bootstrap beyond 2e9 draws; test_exact_one and confint_exact_one time one provider instead.

source(file.path("dev", "bench", "pprofr", "scenarios.R"))
args <- commandArgs(trailingOnly = TRUE)
data_dir <- args[[1]]
out_file <- args[[2]]
only <- if (length(args) >= 4 && args[[3]] == "--only") args[[4]] else NULL
stopifnot(requireNamespace("callr", quietly = TRUE), requireNamespace("bench", quietly = TRUE),
          requireNamespace("jsonlite", quietly = TRUE))
lib <- normalizePath(file.path("dev", "reference", "pprofr", "lib"), winslash = "/", mustWork = TRUE)
dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)

tasks <- c("prep", "fit_serbin", "fit_ban", "vcov", "test_exact", "test_exact_one", "test_bootstrap", "test_score",
           "test_wald", "test_robust_wald", "test_stabilized_wald", "test_robust_score", "test_stabilized_score",
           "covar_wald", "covar_robust_wald", "confint_exact", "confint_exact_one", "confint_score", "confint_wald",
           "sr", "direct_exp", "test_sm")

run_task <- function(dir, scenario, task, scenarios_file, lib) {
  source(scenarios_file)
  suppressPackageStartupMessages(library(pprofR))
  if (!startsWith(normalizePath(find.package("pprofR"), winslash = "/"), lib)) stop("pprofR is not from ", lib)
  d <- pprofr_bench_data(dir, scenario)
  z <- grep("^x", names(d), value = TRUE)
  binomial <- any(d$n != 1L)
  prep_of <- function(clustered) {
    a <- list(Y = d["y"], Z = d[z], ProvID = d["provider"], cutoff = 10, check = FALSE, message = FALSE)
    if (binomial) a$N <- d$n
    if (clustered) a$PatientID <- d["cluster"]
    suppressWarnings(suppressMessages(do.call(fe_data_prep, a)))
  }
  max_trials <- max(tapply(d$n, d$provider, sum))
  info <- list(n = nrow(d), m = length(unique(d$provider)), max_trials = max_trials)
  if (task == "test_exact" && max_trials > 5000) {
    reason <- sprintf("a provider has %d trials: the Poisson-binomial distribution costs O(T^2) per provider",
                      max_trials)
    return(c(info, status = "skipped", message = paste(reason, "(see test_exact_one)")))
  }
  # The exact limits solve the tail equation by root finding, each evaluation a Poisson-binomial distribution:
  # about 4 minutes at m T^2 = 1e8 (100 providers of 1,000 trials).
  cost <- info$m * as.numeric(max_trials)^2
  if (task == "confint_exact" && cost > 1e8) {
    return(c(info, status = "skipped", message = sprintf("m T^2 = %.3g, more than 1e8 (see confint_exact_one)", cost)))
  }
  if (task == "test_bootstrap" && nrow(d) * 1e4 > 2e9) {
    return(c(info, status = "skipped", message = sprintf("%.3g draws (rows times 10,000 resamples)", nrow(d) * 1e4)))
  }
  clustered <- task %in% c("test_robust_wald", "test_stabilized_wald", "test_robust_score", "test_stabilized_score",
                           "covar_robust_wald")
  call <- if (task == "prep") {
    function() prep_of(FALSE)
  } else {
    prep <- prep_of(clustered)
    if (task %in% c("fit_serbin", "fit_ban")) {
      algorithm <- if (task == "fit_serbin") "SerBIN" else "BAN"
      function() logis_fe(prep, algorithm = algorithm, threads = 1)
    } else {
      fit <- logis_fe(prep, threads = 1)
      switch(
        task,
        vcov = function() stats::vcov(fit),
        test_exact = function() test_fe(fit, test = "exact.poisbinom", threads = 1),
        test_exact_one = {
          # pprofR compares the class of `parm` with its provider column's.
          one_provider <- fit$data_include[[fit$char_list$prov.char]][1]
          function() test_fe(fit, parm = one_provider, test = "exact.poisbinom", threads = 1)
        },
        confint_exact_one = {
          one_provider <- fit$data_include[[fit$char_list$prov.char]][1]
          function() stats::confint(fit, parm = one_provider, option = "gamma", test = "exact")
        },
        test_bootstrap = function() {
          set.seed(1)
          test_fe(fit, test = "exact.bootstrap", n = 10000, threads = 1)
        },
        test_score = function() test_fe(fit, test = "score", threads = 1),
        test_wald = function() test_fe(fit, test = "wald", threads = 1),
        test_robust_wald = function() test_fe(fit, test = "robust_wald", threads = 1),
        test_stabilized_wald = function() test_fe(fit, test = "stabilized_wald", threads = 1),
        test_robust_score = function() test_fe(fit, test = "robust_score", threads = 1),
        test_stabilized_score = function() test_fe(fit, test = "stabilized_score", threads = 1),
        covar_wald = function() summary_fe_covar(fit, test = "wald"),
        covar_robust_wald = function() summary_fe_covar(fit, test = "robust_wald"),
        confint_exact = function() stats::confint(fit, option = "gamma", test = "exact"),
        confint_score = function() stats::confint(fit, option = "gamma", test = "score"),
        confint_wald = function() stats::confint(fit, option = "gamma", test = "wald"),
        sr = function() {
          SR_output(fit, stdz = c("indirect", "direct"), measure = c("rate", "ratio"), threads = 1, se = TRUE)
        },
        direct_exp = {
          gamma <- as.numeric(fit$gamma)
          eta <- as.numeric(fit$linear_pred)
          column <- fit$char_list$N.char
          trials <- if (!is.null(column) && column %in% names(fit$data_include)) fit$data_include[[column]] else 1
          function() direct_exp(gamma, eta, N = trials, threads = 1)
        },
        test_sm = {
          measures <- SR_output(fit, stdz = "direct", measure = "rate", threads = 1, se = TRUE)
          se <- drop(measures$numer_se) / measures$N_pop * test_fe(fit, test = "wald", threads = 1)$se.gamma
          rate <- drop(measures$direct.rate)
          reference <- sum(fit$obs) / measures$N_pop
          function() test_SM(rate, se, reference, transform = "logit")
        },
        stop("Unknown task: ", task)
      )
    }
  }
  quiet_call <- function() suppressWarnings(suppressMessages(utils::capture.output(value <- call())))
  invisible(gc(reset = TRUE))
  before <- as.numeric(bench::bench_process_memory()[["max"]])
  first <- system.time(quiet_call())[["elapsed"]]
  after <- as.numeric(bench::bench_process_memory()[["max"]])
  heap <- gc()
  gc_max <- sum(heap[, which(colnames(heap) == "max used") + 1L])
  runs <- if (first >= 60) 1L else if (first >= 10) 3L else 5L
  times <- first
  if (runs > 1L) {
    b <- bench::mark(quiet_call(), min_time = 1, min_iterations = runs, max_iterations = 200, check = FALSE,
                     memory = FALSE, filter_gc = FALSE)
    times <- as.numeric(b$time[[1]])
  }
  c(info, status = "ok", message = "", median_s = stats::median(times), min_s = min(times), max_s = max(times),
    first_s = first, runs = length(times), peak_before_mb = before / 2^20, peak_after_mb = after / 2^20,
    gc_max_mb = gc_max)
}

value_of <- function(res, name) if (is.null(res[[name]])) NA else res[[name]]
scenarios_file <- normalizePath(file.path("dev", "bench", "pprofr", "scenarios.R"), winslash = "/")
child_env <- c(callr::rcmd_safe_env(), OMP_THREAD_LIMIT = "1", OMP_NUM_THREADS = "1", LC_COLLATE = "C")
# One task in a fresh process; a failure or a timeout is returned as the status.
measure <- function(scenario, task) {
  failed <- function(e) {
    list(status = if (inherits(e, "callr_timeout_error")) "timeout" else "error",
         message = gsub("[\r\n]+", " ", conditionMessage(e)))
  }
  tryCatch(
    callr::r(
      run_task,
      args = list(dir = normalizePath(data_dir, winslash = "/"), scenario = scenario, task = task,
                  scenarios_file = scenarios_file, lib = lib),
      libpath = c(lib, .libPaths()), env = child_env, user_profile = FALSE, system_profile = FALSE, timeout = 7200
    ),
    error = failed
  )
}
rows <- list()
for (k in seq_len(nrow(pprofr_bench_scenarios))) {
  sc <- pprofr_bench_scenarios[k, ]
  path <- file.path(data_dir, paste0(sc$scenario, ".rds"))
  for (task in tasks) {
    label <- paste(sc$scenario, task)
    if (!is.null(only) && !grepl(only, label)) next
    if (!file.exists(path)) saveRDS(pprofr_bench_make(sc$scenario), path)
    res <- measure(sc$scenario, task)
    rows[[length(rows) + 1L]] <- data.frame(
      scenario = sc$scenario, task = task, n = value_of(res, "n"), m = value_of(res, "m"), trials = sc$trials,
      p = sc$p, max_trials = value_of(res, "max_trials"), status = res$status, median_s = value_of(res, "median_s"),
      min_s = value_of(res, "min_s"), max_s = value_of(res, "max_s"), first_s = value_of(res, "first_s"),
      runs = value_of(res, "runs"), peak_before_mb = value_of(res, "peak_before_mb"),
      peak_after_mb = value_of(res, "peak_after_mb"), gc_max_mb = value_of(res, "gc_max_mb"),
      message = substr(value_of(res, "message"), 1, 200), stringsAsFactors = FALSE
    )
    cat(sprintf("%-14s %-22s %-8s %10s\n", sc$scenario, task, res$status,
                if (identical(res$status, "ok")) sprintf("%.3f s", as.numeric(res$median_s)) else ""))
    utils::write.csv(do.call(rbind, rows), out_file, row.names = FALSE)
  }
}

lock <- jsonlite::read_json(file.path("dev", "reference", "pprofr", "pprofr-library-lock.json"))
machine <- list(
  created = format(Sys.time(), tz = "UTC", usetz = TRUE), r_version = R.version.string,
  platform = R.version$platform, running = utils::sessionInfo()$running, cores = parallel::detectCores(),
  processor = Sys.getenv("PROCESSOR_IDENTIFIER"), git_commit = system2("git", c("rev-parse", "HEAD"), stdout = TRUE),
  pprofr = lock$pprofr, packages = lock$packages, bench = as.character(utils::packageVersion("bench")),
  threads = 1L, scenarios = pprofr_bench_scenarios
)
jsonlite::write_json(machine, sub("\\.csv$", ".json", out_file), auto_unbox = TRUE, pretty = TRUE, digits = NA)
cat(sprintf("wrote %d rows to %s\n", length(rows), out_file))
