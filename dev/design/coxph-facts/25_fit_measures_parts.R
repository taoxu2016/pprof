# CoxPH Phase C3, after its benchmarks: the fit with its measures against the engine call, the
# preparation of its inputs, and the plain-R measures (DEC-105, DEC-111), interleaved in one process
# rather than in fresh ones, to separate the code's cost from the noise of the paired runs; and the
# parts of the measures. The C3 paired run (dev/bench/results/cox-c3-paired-20261009-windows.md) found
# 2 of 21 fits too slow by DEC-038's rule, providers-7500 with Breslow ties and covariates-5 robust,
# where C2's had none.
#
# A. For three scenarios of the benchmark grid and the Breslow and robust fits: the medians of 9
#    interleaved runs of each side, as dev/bench/cox/run_paired.R defines them: the engine call
#    (survival's fitter on the adapter's inputs, with coxph()'s robust step for robust, then the national
#    expected events by provider in plain R), the preparation of its inputs (data_prepare() and the
#    adapter's inputs), and the fit followed by standardize_providers(); and the fit alone.
# B. The parts of the measures on a Breslow fit: cox_expected_events(), which the fit runs, and
#    standardize_providers(), against the engine side's plain-R expected events; medians of 9 runs.
#
# Run from the repository root, with the benchmark data written by dev/bench/cox/run_paired.R (or
# dev/bench/cox/scenarios.R's cox_bench_write()) under <data dir>:
#   Rscript dev/design/coxph-facts/25_fit_measures_parts.R dev/design/coxph-facts/25_fit_measures_parts.txt <data dir>
args <- commandArgs(trailingOnly = TRUE)
out_file <- args[[1]]
data_root <- args[[2]]
suppressMessages(devtools::load_all(quiet = TRUE))
source(file.path("dev", "bench", "cox", "scenarios.R"))
lines <- sprintf("%s; survival %s", R.version.string, utils::packageVersion("survival"))
say <- function(...) lines <<- c(lines, sprintf(...))
control <- survival::coxph.control(timefix = FALSE)

# The engine side's measures (run_paired.R's plain_expected()): C1's closed form, by provider.
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
median_time <- function(f, n = 9) stats::median(vapply(seq_len(n), function(i) bench::bench_time(f())[["real"]], 0))

say("")
say("A. Medians of 9 interleaved runs (seconds); the ratio is DEC-105's: fit with measures over engine call plus preparation")
say("%-15s %-8s %8s %12s %10s %10s %8s", "scenario", "task", "engine", "preparation", "fit+meas.", "fit alone", "ratio")
scenarios <- cox_bench_scenarios()
for (id in c("center", "providers-7500", "covariates-5")) {
  dir <- cox_bench_write(scenarios[scenarios$id == id, ], file.path(data_root, id))
  d <- cox_bench_read(dir)
  covariates <- attr(d, "covariates")
  formula <- stats::as.formula(paste("Surv(start, stop, event) ~", paste(covariates, collapse = " + "),
                                     "+ offset(offset)"))
  prepare <- function() {
    prepared <- data_prepare(formula, d, "provider", event_counts = TRUE, response_type = "survival",
                             weights = "weight", allow_offset = TRUE)
    list(terms = prepared$terms, inputs = survival_inputs(prepared, survival_fit_rows(prepared)))
  }
  built <- prepare()
  inputs <- built$inputs
  fitter <- if (inputs$counting) survival::agreg.fit else survival::coxph.fit
  for (task in c("breslow", "robust")) {
    robust <- identical(task, "robust")
    engine <- function() {
      fit <- fitter(inputs$x, inputs$y, inputs$strata, inputs$offset, NULL, control, weights = inputs$weights,
                    method = "breslow", rownames = NULL, nocenter = c(-1, 0, 1))
      fit$expected <- plain_expected(inputs, fit$coefficients)
      if (robust) {
        object <- c(fit, list(x = inputs$x, y = inputs$y, weights = inputs$weights))
        object$naive.var <- fit$var
        object$strata <- inputs$strata
        object$terms <- built$terms
        object$class <- NULL
        class(object) <- fit$class
        fit$robust_var <- crossprod(stats::residuals(object, type = "dfbeta", collapse = seq_len(nrow(inputs$x)),
                                                     weighted = TRUE))
      }
      fit
    }
    fit_only <- function() fit_cox_stratified(formula, d, "provider", weights = "weight", robust = robust)
    fit_side <- function() {
      fit <- fit_only()
      standardize_providers(fit)
      fit
    }
    sides <- list(engine = engine, prepare = prepare, fit = fit_side, fit_only = fit_only)
    for (s in sides) s()
    times <- matrix(NA_real_, 9, length(sides), dimnames = list(NULL, names(sides)))
    for (i in seq_len(nrow(times))) for (s in names(sides)) times[i, s] <- bench::bench_time(sides[[s]]())[["real"]]
    m <- apply(times, 2, stats::median)
    say("%-15s %-8s %8.3f %12.3f %10.3f %10.3f %8.3f", id, task, m[["engine"]], m[["prepare"]], m[["fit"]],
        m[["fit_only"]], m[["fit"]] / (m[["engine"]] + m[["prepare"]]))
  }
  fit <- fit_cox_stratified(formula, d, "provider", weights = "weight")
  eta <- fit$linear_predictor + fit$offset
  fitted <- fitter(inputs$x, inputs$y, inputs$strata, inputs$offset, NULL, control, weights = inputs$weights,
                   method = "breslow", rownames = NULL, nocenter = c(-1, 0, 1))
  say("%-15s B. cox_expected_events() %.4f, standardize_providers() %.4f, plain-R expected events %.4f", id,
      median_time(function() cox_expected_events(eta, fit$start, fit$stop, fit$response)),
      median_time(function() standardize_providers(fit)),
      median_time(function() plain_expected(inputs, fitted$coefficients)))
}
writeLines(lines, out_file)
