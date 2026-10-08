# The engine side of the Cox benchmark baseline (CoxPH brief §3.7; COXPH_DESIGN §I): direct
# survival and glmnet calls as the package's adapters will make them (COXPH_DESIGN §E.1, §E.2), and
# the closed-form expected counts of COXPH_DESIGN §F.1 in plain R (C0's prototype, fact script 07).
# From Phase C2 on, the package's Cox functions are measured against these calls (at most 10%
# slower than the call they wrap, brief §3.7), in the same session, with dev/bench/run_paired.R's
# pairing (DEC-038).
#
# Usage, from the repository root:
#   Rscript dev/bench/cox/run_engines.R <data dir> <output csv> [--only REGEX]
# Each task runs in a fresh R process, as dev/bench/harness.R's do: the first run's time, the
# process's peak memory before and after it, gc()'s maximum of R's heap, and bench::mark() with at
# least 5 runs (3 when the first run takes 10 s or more; 1 when it takes 60 s or more).
source(file.path("dev", "bench", "cox", "scenarios.R"))
args <- commandArgs(trailingOnly = TRUE)
data_root <- args[[1]]
out_file <- args[[2]]
only <- if (length(args) >= 4 && args[[3]] == "--only") args[[4]] else NULL
stopifnot(requireNamespace("callr", quietly = TRUE), requireNamespace("bench", quietly = TRUE),
          requireNamespace("survival", quietly = TRUE), requireNamespace("glmnet", quietly = TRUE))

tasks <- c("survival_breslow", "survival_efron", "survival_robust_breslow", "expected_counts", "glmnet_path",
           "glmnet_cv")
penalized_only <- c("glmnet_path", "glmnet_cv")

run_task <- function(dir, task, scenarios_file) {
  source(scenarios_file)
  d <- cox_bench_read(dir)
  covariates <- attr(d, "covariates")
  x <- as.matrix(d[, covariates])
  y <- survival::Surv(d$start, d$stop, d$event)
  control <- survival::coxph.control(timefix = FALSE)
  engine <- function(method) {
    survival::agreg.fit(x, y, strata = d$provider, offset = d$offset, init = NULL, control = control,
                        weights = d$weight, method = method, rownames = NULL)
  }
  call <- switch(task,
    survival_breslow = function() engine("breslow"),
    survival_efron = function() engine("efron"),
    survival_robust_breslow = {
      d$.row <- seq_len(nrow(d))
      f <- stats::as.formula(paste("Surv(start, stop, event) ~", paste(covariates, collapse = " + "),
                                   "+ strata(provider) + offset(offset)"),
                             env = list2env(list(Surv = survival::Surv, strata = survival::strata)))
      function() survival::coxph(f, data = d, weights = weight, cluster = .row, ties = "breslow", control = control)
    },
    expected_counts = {
      beta <- engine("breslow")$coefficients
      function() {
        eta <- drop(x %*% beta) + d$offset
        risk <- exp(eta - max(eta))
        event_times <- sort(unique(d$stop[d$event == 1]))
        k <- length(event_times)
        deaths <- tabulate(match(d$stop[d$event == 1], event_times), k)
        at_stop <- findInterval(d$stop, event_times)
        at_start <- findInterval(d$start, event_times)
        bin <- function(index) {
          a <- numeric(k + 1)
          s <- rowsum(risk, index)
          a[as.integer(rownames(s)) + 1] <- s
          a
        }
        suffix <- function(a) rev(cumsum(rev(a)))
        risk_set <- suffix(bin(at_stop))[2:(k + 1)] - suffix(bin(at_start))[2:(k + 1)]
        cumulative <- c(0, cumsum(deaths / risk_set))
        rowsum(risk * (cumulative[at_stop + 1] - cumulative[at_start + 1]), d$provider)
      }
    },
    glmnet_path = , glmnet_cv = {
      ys <- glmnet::stratifySurv(y, d$provider)
      path <- function(rows) {
        glmnet::glmnet(x[rows, , drop = FALSE], ys[rows], family = "cox", weights = d$weight[rows],
                       offset = d$offset[rows], alpha = 1, nlambda = 100, lambda.min.ratio = 1e-4, standardize = TRUE,
                       cox.ties = "breslow", control = list(thresh = 1e-12, maxit = 1e5, fdev = 0, devmax = 1))
      }
      if (task == "glmnet_path") {
        function() path(seq_len(nrow(d)))
      } else {
        # Event-stratified folds, as pprof_py draws them (K-144), with R's generator.
        set.seed(1)
        fold <- integer(nrow(d))
        for (group in list(which(d$event == 1), which(d$event == 0))) {
          fold[group] <- sample(rep_len(1:10, length(group)))
        }
        function() {
          full <- path(seq_len(nrow(d)))
          lapply(1:10, function(k) {
            fit <- path(which(fold != k))
            vapply(seq_along(fit$lambda), function(j) {
              glmnet::coxnet.deviance(pred = drop(x %*% fit$beta[, j]) + d$offset, y = ys, weights = d$weight,
                                      std.weights = FALSE, cox.ties = "breslow")
            }, 0)
          })
          full
        }
      }
    }
  )
  gc(reset = TRUE)
  before <- as.numeric(bench::bench_process_memory()[["max"]])
  first <- system.time(call())[["elapsed"]]
  after <- as.numeric(bench::bench_process_memory()[["max"]])
  heap <- gc()
  gc_max <- sum(heap[, ncol(heap)])  # "max used" in MB since the reset, R's heap only
  iterations <- if (first >= 60) 1L else if (first >= 10) 3L else 5L
  b <- bench::mark(call(), min_time = 1, min_iterations = iterations, max_iterations = max(iterations, 100L),
                   check = FALSE, memory = FALSE, filter_gc = FALSE)
  times <- as.numeric(b$time[[1]])
  list(first_s = first, median_s = stats::median(times), min_s = min(times), max_s = max(times), runs = length(times),
       peak_before_mb = before / 2^20, peak_after_mb = after / 2^20, gc_max_mb = gc_max)
}

scenarios <- cox_bench_scenarios()
# Every scenario's data, and the list run_pprof_py.py reads, before any task runs.
for (i in seq_len(nrow(scenarios))) cox_bench_write(scenarios[i, ], file.path(data_root, scenarios$id[i]))
jsonlite::write_json(scenarios, file.path(data_root, "scenarios.json"), dataframe = "rows", auto_unbox = TRUE)
rows <- list()
for (i in seq_len(nrow(scenarios))) {
  sc <- scenarios[i, ]
  dir <- file.path(data_root, sc$id)
  for (task in tasks) {
    if (task %in% penalized_only && !sc$penalized) next
    id <- paste(sc$id, task)
    if (!is.null(only) && !grepl(only, id)) next
    cat(id, "\n")
    scenarios_file <- file.path("dev", "bench", "cox", "scenarios.R")
    res <- tryCatch(
      callr::r(run_task, args = list(dir = dir, task = task, scenarios_file = scenarios_file),
               env = c(callr::rcmd_safe_env(), OMP_THREAD_LIMIT = "1", OMP_NUM_THREADS = "1"), timeout = 7200),
      error = function(e) list(status = gsub("[\r\n]+", " ", conditionMessage(e)))  # one CSV line
    )
    value <- function(name) if (is.null(res[[name]])) NA else res[[name]]
    measures <- c("first_s", "median_s", "min_s", "max_s", "runs", "peak_before_mb", "peak_after_mb", "gc_max_mb")
    rows[[length(rows) + 1]] <- data.frame(
      scenario = sc$id, n = sc$n, providers = sc$m, covariates = sc$p, task = task,
      status = if (is.null(res$status)) "ok" else res$status,
      as.list(stats::setNames(lapply(measures, value), measures))
    )
    utils::write.csv(do.call(rbind, rows), out_file, row.names = FALSE)
  }
}
jsonlite::write_json(list(
  date = format(Sys.Date()), commit = system2("git", c("rev-parse", "HEAD"), stdout = TRUE),
  r = R.version.string, platform = R.version$platform, os = utils::osVersion,
  cpu = Sys.getenv("PROCESSOR_IDENTIFIER", "unknown"), logical_cores = parallel::detectCores(),
  blas = sessionInfo()$BLAS, lapack = La_version(),
  packages = lapply(stats::setNames(nm = c("survival", "glmnet", "Matrix", "bench", "callr")),
                    function(p) as.character(utils::packageVersion(p))),
  threads = "OMP_THREAD_LIMIT = 1, OMP_NUM_THREADS = 1; survival and glmnet are single-threaded"
), sub("\\.csv$", ".json", out_file), auto_unbox = TRUE, pretty = TRUE)
cat("wrote", out_file, "\n")
