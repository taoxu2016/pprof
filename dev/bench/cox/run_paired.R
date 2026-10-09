# Paired benchmark of fit_cox_stratified() against the engine calls it makes (CoxPH brief §3.7;
# COXPH_C2_PLAN §4.5; DEC-038, DEC-098, DEC-100). On each scenario of the C1 grid
# (dev/bench/cox/scenarios.R), every round runs, each in a fresh process and on the same data:
#
# - engine: for breslow and efron, survival's fitter as the adapter calls it (R/model-survival.R), on
#   the inputs the adapter builds, prepared outside the timing; for robust, the same fitter call
#   followed by coxph()'s robust step with one cluster per row (residuals.coxph(type = "dfbeta",
#   collapse = row, weighted = TRUE), then crossprod(); DEC-099). After its measurement, the process
#   also times the preparation of those inputs from the data frame (data_prepare() and the
#   adapter's inputs): the median of three calls, after the first one that built them;
# - coxph: survival's coxph() on the data frame, the call a user would make, with one cluster per row
#   for robust (C1's comparator, DEC-098); reported, not a gate;
# - fit: fit_cox_stratified() on the data frame, with robust = TRUE for robust.
#
# From Phase C3 (DEC-105, DEC-111), the brief's rule compares a fit plus its measures with the engine
# call plus the measures: the fit side also standardizes the providers (indirect ratios, from the
# expected events the fit computes), and the engine side also computes the national expected events by
# provider in plain R at the fitter's coefficients (C1's closed form, run_engines.R). A fourth task,
# `profile`, fits once outside the timing and times, on that fit, the expected events' closed form, the
# indirect and direct measures, each test with its limits, and the funnel, which the report sets beside
# pprof_py's measures and tests (the brief's SHOULD, and its MUST that mid-p limits be substantially
# faster).
#
# The package is the working tree, installed with --preclean (dev/bench/harness.R) and placed first
# on the library path, before the libraries that hold survival. Each process measures as
# run_engines.R does: the first run's time, the process's peak memory before and after it, gc()'s
# maximum of R's heap, and bench::mark() with at least 5 runs (3 when the first run takes 10 s or
# more; 1 when it takes 60 s or more). Each also returns the coefficients of its first run, and for
# robust the variance: the fit's must equal its engine call's bitwise (DEC-100), and coxph()'s largest
# relative difference from them is recorded (its rows reach the fitter in another order).
#
# Usage, from the repository root:
#   Rscript dev/bench/cox/run_paired.R <data dir> <output csv> [--only REGEX] [--rounds 2]
# --only matches "<scenario> <task>", for example "^corner" or "robust$". The data are written to
# <data dir> first (dev/bench/cox/scenarios.R; existing data are reused); the CSV is rewritten after
# every round, with a .json beside it that records the machine and the versions. The report comes
# from dev/bench/cox/summarize_paired.R. Exit status is 1 when a fit fails or its estimates differ
# from its engine call's.
source(file.path("dev", "bench", "cox", "scenarios.R"))
source(file.path("dev", "bench", "harness.R"))
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2L) {
  stop("Usage: Rscript dev/bench/cox/run_paired.R <data dir> <output csv> [--only REGEX] [--rounds 2]", call. = FALSE)
}
data_root <- args[[1]]
out_file <- args[[2]]
opts <- list(only = NULL, rounds = 2L)
k <- 3L
while (k <= length(args)) {
  switch(args[[k]], "--only" = opts$only <- args[[k + 1]], "--rounds" = opts$rounds <- as.integer(args[[k + 1]]),
         stop("Unknown argument: ", args[[k]], call. = FALSE))
  k <- k + 2L
}
stopifnot(requireNamespace("callr", quietly = TRUE), requireNamespace("bench", quietly = TRUE), opts$rounds >= 1L)

tasks <- c("breslow", "efron", "robust", "profile")
sides <- c("engine", "coxph", "fit")  # the order of every round
task_sides <- function(task) if (identical(task, "profile")) "fit" else sides

run_side <- function(dir, task, side, scenarios_file, pprof_lib) {
  source(scenarios_file)
  suppressPackageStartupMessages(library(pprof))
  if (!startsWith(normalizePath(find.package("pprof"), winslash = "/"), pprof_lib)) {
    stop("pprof is not from ", pprof_lib)
  }
  d <- cox_bench_read(dir)
  covariates <- attr(d, "covariates")
  formula <- stats::as.formula(paste("Surv(start, stop, event) ~", paste(covariates, collapse = " + "),
                                     "+ offset(offset)"))
  ties <- if (identical(task, "efron")) "efron" else "breslow"
  robust <- identical(task, "robust")
  control <- survival::coxph.control(timefix = FALSE)  # eps = 1e-9 and iter.max = 20, the fit's defaults
  # A call's first run with the process's peak memory before and after it and gc()'s maximum of R's
  # heap, then bench::mark() with at least 5 runs (3 when the first takes 10 s or more; 1 from 60 s).
  measure <- function(call) {
    invisible(gc(reset = TRUE))
    before <- as.numeric(bench::bench_process_memory()[["max"]])
    first <- system.time(value <- call())[["elapsed"]]
    after <- as.numeric(bench::bench_process_memory()[["max"]])
    heap <- gc()
    iterations <- if (first >= 60) 1L else if (first >= 10) 3L else 5L
    b <- bench::mark(call(), min_time = 1, min_iterations = iterations, max_iterations = max(iterations, 100L),
                     check = FALSE, memory = FALSE, filter_gc = FALSE)
    list(value = value, first = first, before = before, after = after, gc_max = sum(heap[, ncol(heap)]),
         times = as.numeric(b$time[[1]]))
  }
  profile_columns <- c("expected_s", "measures_s", "midp_s", "exact_s", "funnel_s")
  if (identical(task, "profile")) {
    # The profiling functions on one fit, made outside the timing: the expected events' closed form
    # (which the fit computes), the indirect and direct measures, each test with its limits (pprof_py's
    # test() computes the measures, the test, and the limits), and the funnel.
    fit <- fit_cox_stratified(formula, d, "provider", weights = "weight")
    eta <- fit$linear_predictor + fit$offset
    calls <- list(
      expected_s = function() pprof:::cox_expected_events(eta, fit$start, fit$stop, fit$response),
      measures_s = function() standardize_providers(fit, c("indirect", "direct")),
      midp_s = function() list(test_providers(fit, test = "midp"), standardize_providers(fit, interval = "midp")),
      exact_s = function() list(test_providers(fit, test = "exact"), standardize_providers(fit, interval = "exact")),
      funnel_s = function() funnel_limits(fit)
    )
    timed <- lapply(calls, measure)
    peak <- max(vapply(timed, `[[`, numeric(1), "after"))
    return(c(list(first_s = NA_real_, median_s = NA_real_, min_s = NA_real_, max_s = NA_real_, runs = NA_integer_,
                  peak_before_mb = NA_real_, peak_after_mb = peak / 2^20, gc_max_mb = NA_real_, prep_s = NA_real_),
             lapply(timed, function(t) stats::median(t$times)),
             list(coefficients = unname(fit$coefficients), variance = NULL)))
  }
  # The national Breslow expected events by provider in plain R (K-136, K-137; C1's closed form in
  # run_engines.R), from the engine's inputs: the design, the offset, the Surv() response, the strata.
  plain_expected <- function(inputs, beta) {
    eta <- drop(inputs$x %*% beta) + inputs$offset
    risk <- exp(eta - max(eta))
    y <- unclass(inputs$y)
    start <- if (ncol(y) == 3L) y[, 1] else rep(0, nrow(y))
    stop <- y[, ncol(y) - 1L]
    event <- y[, ncol(y)]
    times <- sort(unique(stop[event == 1]))
    k <- length(times)
    deaths <- tabulate(match(stop[event == 1], times), k)
    at_stop <- findInterval(stop, times)
    at_start <- findInterval(start, times)
    bin <- function(index) {
      a <- numeric(k + 1)
      s <- rowsum(risk, index)
      a[as.integer(rownames(s)) + 1] <- s
      a
    }
    suffix <- function(a) rev(cumsum(rev(a)))
    risk_set <- suffix(bin(at_stop))[2:(k + 1)] - suffix(bin(at_start))[2:(k + 1)]
    cumulative <- c(0, cumsum(deaths / risk_set))
    rowsum(risk * (cumulative[at_stop + 1] - cumulative[at_start + 1]), inputs$strata)
  }
  prepare <- NULL
  call <- switch(side,
    # The fit and its indirect measures (DEC-105, DEC-111).
    fit = function() {
      fit <- fit_cox_stratified(formula, d, "provider", weights = "weight", ties = ties, robust = robust)
      standardize_providers(fit)
      fit
    },
    coxph = {
      d$.row <- seq_len(nrow(d))
      f <- stats::as.formula(paste("Surv(start, stop, event) ~", paste(covariates, collapse = " + "),
                                   "+ strata(provider) + offset(offset)"),
                             env = list2env(list(Surv = survival::Surv, strata = survival::strata)))
      if (robust) {
        function() survival::coxph(f, data = d, weights = weight, cluster = .row, ties = ties, control = control)
      } else {
        # robust = FALSE: coxph() would turn the robust variance on for the non-integer weights.
        function() survival::coxph(f, data = d, weights = weight, ties = ties, robust = FALSE, control = control)
      }
    },
    engine = {
      # The adapter's inputs (DEC-100), built outside the timing; their preparation is timed after the
      # engine call's measurement (below).
      prepare <- function() {
        prepared <- pprof:::data_prepare(formula, d, "provider", event_counts = TRUE, response_type = "survival",
                                         weights = "weight", allow_offset = TRUE)
        list(terms = prepared$terms, inputs = pprof:::survival_inputs(prepared, pprof:::survival_fit_rows(prepared)))
      }
      built <- prepare()
      inputs <- built$inputs
      terms <- built$terms
      rm(built)
      fitter <- if (inputs$counting) survival::agreg.fit else survival::coxph.fit
      # The fitter and the measures at its coefficients (DEC-105, DEC-111).
      engine <- function() {
        fit <- fitter(inputs$x, inputs$y, inputs$strata, inputs$offset, NULL, control, weights = inputs$weights,
                      method = ties, rownames = NULL, nocenter = c(-1, 0, 1))
        fit$expected <- plain_expected(inputs, fit$coefficients)
        fit
      }
      if (!robust) {
        engine
      } else {
        # coxph()'s robust step on the fitter's result, as the adapter takes it (DEC-099).
        function() {
          fit <- engine()
          object <- c(fit, list(x = inputs$x, y = inputs$y, weights = inputs$weights))
          object$naive.var <- fit$var
          object$strata <- inputs$strata
          object$terms <- terms
          object$class <- NULL
          class(object) <- fit$class
          fit$robust_var <- crossprod(stats::residuals(object, type = "dfbeta", collapse = seq_len(nrow(inputs$x)),
                                                       weighted = TRUE))
          fit
        }
      }
    }
  )
  estimates <- function(value) {
    variance <- if (inherits(value, "pprof_cox_stratified")) value$vcov else if (inherits(value, "coxph")) value$var
    if (!robust) variance <- NULL else if (is.null(variance)) variance <- value$robust_var
    list(coefficients = unname(value$coefficients), variance = if (!is.null(variance)) unname(variance))
  }
  timed <- measure(call)
  result <- estimates(timed$value)
  timed$value <- NULL
  times <- timed$times
  # The engine's inputs' preparation: the median of three calls, after the measurement so that its
  # garbage does not burden the engine call, and after the first call, which pays one-off costs.
  prep_s <- NA_real_
  if (!is.null(prepare)) {
    prep_s <- stats::median(vapply(1:3, function(i) as.numeric(bench::bench_time(prepare())[["real"]]), numeric(1)))
  }
  c(list(first_s = timed$first, median_s = stats::median(times), min_s = min(times), max_s = max(times),
         runs = length(times), peak_before_mb = timed$before / 2^20, peak_after_mb = timed$after / 2^20,
         gc_max_mb = timed$gc_max, prep_s = prep_s),
    stats::setNames(as.list(rep(NA_real_, length(profile_columns))), profile_columns), result)
}

# The largest relative difference of the estimates `a` from `b`, 0 when they are identical.
max_relative_difference <- function(a, b) {
  x <- c(a$coefficients, a$variance)
  y <- c(b$coefficients, b$variance)
  if (identical(x, y)) return(0)
  if (length(x) != length(y)) return(NA_real_)
  max(abs(x - y) / pmax(abs(y), .Machine$double.xmin))
}

wt_lib <- bench_install_working_tree()
scenarios_file <- file.path("dev", "bench", "cox", "scenarios.R")
scenarios <- cox_bench_scenarios()
measures <- c("first_s", "median_s", "min_s", "max_s", "runs", "peak_before_mb", "peak_after_mb", "gc_max_mb", "prep_s",
              "expected_s", "measures_s", "midp_s", "exact_s", "funnel_s")
rows <- list()
mismatches <- 0L
for (i in seq_len(nrow(scenarios))) {
  sc <- scenarios[i, ]
  for (task in tasks) {
    if (!is.null(opts$only) && !grepl(opts$only, paste(sc$id, task))) next
    dir <- cox_bench_write(sc, file.path(data_root, sc$id))
    for (round in seq_len(opts$rounds)) {
      results <- list()
      for (side in task_sides(task)) {
        results[[side]] <- tryCatch(
          callr::r(run_side, args = list(dir = dir, task = task, side = side, scenarios_file = scenarios_file,
                                         pprof_lib = wt_lib),
                   libpath = unique(c(wt_lib, .libPaths())),
                   env = c(callr::rcmd_safe_env(), OMP_THREAD_LIMIT = "1", OMP_NUM_THREADS = "1", LC_COLLATE = "C"),
                   user_profile = FALSE, system_profile = FALSE, timeout = 7200),
          error = function(e) list(status = gsub("[\r\n]+", " ", conditionMessage(e)))  # one CSV line
        )
      }
      engine <- results[["engine"]]
      for (side in task_sides(task)) {
        res <- results[[side]]
        ok <- is.null(res$status) && is.null(engine$status)
        value <- function(name) if (is.null(res[[name]])) NA else res[[name]]
        paired <- !identical(task, "profile")
        same <- if (side == "engine" || !ok || !paired) {
          NA
        } else {
          identical(res$coefficients, engine$coefficients) && identical(res$variance, engine$variance)
        }
        if (identical(side, "fit") && paired && !isTRUE(same)) mismatches <- mismatches + 1L
        if (identical(side, "fit") && !paired && !ok) mismatches <- mismatches + 1L
        rows[[length(rows) + 1L]] <- data.frame(
          scenario = sc$id, n = sc$n, providers = sc$m, covariates = sc$p, task = task, side = side, round = round,
          status = if (is.null(res$status)) "ok" else res$status,
          as.list(stats::setNames(lapply(measures, value), measures)),
          identical_to_engine = same,
          max_rel_diff_engine = if (side == "engine" || !ok || !paired) NA else max_relative_difference(res, engine)
        )
        if (paired) {
          cat(sprintf("%-15s %-8s round %d %-7s %8.3f s (fastest %.3f)  peak %5.0f MB%s\n", sc$id, task, round, side,
                      value("median_s"), value("min_s"), value("peak_after_mb"),
                      if (identical(side, "fit") && isFALSE(same)) "  ESTIMATES DIFFER FROM THE ENGINE CALL'S" else ""))
        } else {
          cat(sprintf("%-15s %-8s round %d  expected %.3f, measures %.3f, mid-p %.3f, exact %.3f, funnel %.3f s%s\n",
                      sc$id, task, round, value("expected_s"), value("measures_s"), value("midp_s"), value("exact_s"),
                      value("funnel_s"), if (ok) "" else paste(" FAILED:", res$status)))
        }
      }
      utils::write.csv(do.call(rbind, rows), out_file, row.names = FALSE)
    }
  }
}
if (length(rows) == 0L) stop("No task matches --only.", call. = FALSE)
git <- function(...) system2("git", c(...), stdout = TRUE)
jsonlite::write_json(list(
  date = format(Sys.Date()), commit = git("rev-parse", "HEAD"),
  package_code_clean = length(git("status", "--porcelain", "--", "R", "src", "DESCRIPTION", "NAMESPACE")) == 0L,
  r = R.version.string, platform = R.version$platform, os = utils::osVersion,
  cpu = Sys.getenv("PROCESSOR_IDENTIFIER", "unknown"), logical_cores = parallel::detectCores(),
  blas = sessionInfo()$BLAS, lapack = La_version(), rounds = opts$rounds,
  only = if (is.null(opts$only)) "" else opts$only,
  packages = c(list(pprof = as.character(read.dcf("DESCRIPTION", fields = "Version"))),
               lapply(stats::setNames(nm = c("survival", "Matrix", "bench", "callr")),
                      function(p) as.character(utils::packageVersion(p)))),
  threads = "OMP_THREAD_LIMIT = 1, OMP_NUM_THREADS = 1; survival is single-threaded"
), sub("\\.csv$", ".json", out_file), auto_unbox = TRUE, pretty = TRUE)
cat(sprintf("wrote %s (%d rows; %d fits that failed or whose estimates differ from their engine call's)\n", out_file,
            length(rows), mismatches))
if (mismatches > 0L) quit(status = 1)
