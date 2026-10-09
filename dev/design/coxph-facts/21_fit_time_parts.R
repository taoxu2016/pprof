# CoxPH Phase C2 gate (the brief's §3.7; DEC-100, DEC-105): where the time of fit_cox_stratified()
# goes, beyond the survival fitter it calls. On the benchmark generator's data (dev/bench/cox/
# scenarios.R) at 100,000 rows with 5 and 20 covariates and at 1,000,000 rows with 20, with Breslow
# ties: the fit; the fitter on the adapter's inputs (the paired benchmark's engine call); data_prepare()
# and, inside it, the model frame and the design as R builds them, the provider index, and the sort of
# the design by provider; the adapter's inputs (survival_inputs()); and the adapter's own steps after
# the fitter (the finite check of the design and the model object). Medians of bench::mark() in one
# process (the paired benchmark's fresh processes and rounds are what decide; these are the parts).
# The working tree is installed with --preclean, as the benchmarks install it (dev/bench/harness.R).
# Run from the repository root: Rscript dev/design/coxph-facts/21_fit_time_parts.R <output file> <data dir>
args <- commandArgs(trailingOnly = TRUE)
out <- args[[1]]
data_root <- args[[2]]
source(file.path("dev", "bench", "cox", "scenarios.R"))
source(file.path("dev", "bench", "harness.R"))
lib <- bench_install_working_tree()
.libPaths(c(lib, .libPaths()))
suppressPackageStartupMessages(library(pprof))
stopifnot(startsWith(normalizePath(find.package("pprof"), winslash = "/"), lib))
ns <- asNamespace("pprof")
lines <- sprintf("%s, survival %s, bench %s; pprof %s from the working tree at %s", R.version.string,
                 utils::packageVersion("survival"), utils::packageVersion("bench"), utils::packageVersion("pprof"),
                 system2("git", c("rev-parse", "--short", "HEAD"), stdout = TRUE))
grid <- cox_bench_scenarios()
for (id in c("covariates-5", "center", "rows-1e6")) {
  sc <- grid[grid$id == id, ]
  d <- cox_bench_read(cox_bench_write(sc, file.path(data_root, id)))
  covariates <- attr(d, "covariates")
  formula <- stats::as.formula(paste("Surv(start, stop, event) ~", paste(covariates, collapse = " + "),
                                     "+ offset(offset)"))
  prepare <- function() {
    ns$data_prepare(formula, d, "provider", event_counts = TRUE, response_type = "survival", weights = "weight",
                    allow_offset = TRUE)
  }
  prepared <- prepare()
  rows <- ns$survival_fit_rows(prepared)
  inputs <- ns$survival_inputs(prepared, rows)
  control <- survival::coxph.control(timefix = FALSE)
  estimates <- ns$survival_fit(prepared, "breslow", FALSE, 20, 1e-9)
  spec <- list(family = "cox_stratified", ties = "breslow", robust = FALSE, weights = "weight", cluster = NULL,
               max_iter = 20, tol = 1e-9, keep_data = FALSE)
  terms <- prepared$terms
  frame <- stats::model.frame(terms, d)
  index <- ns$data_index_providers(d$provider)
  design <- stats::model.matrix(terms, frame)
  iterations <- if (sc$n >= 1e6) 3L else 10L
  b <- bench::mark(
    fit = fit_cox_stratified(formula, d, "provider", weights = "weight"),
    fitter = survival::agreg.fit(inputs$x, inputs$y, inputs$strata, inputs$offset, NULL, control,
                                 weights = inputs$weights, method = "breslow", rownames = NULL,
                                 nocenter = c(-1, 0, 1)),
    data_prepare = prepare(),
    model_frame = stats::model.frame(terms, d),
    model_matrix = stats::model.matrix(terms, frame),
    provider_index = ns$data_index_providers(d$provider),
    sort_design = design[index$order, , drop = FALSE],
    survival_inputs = ns$survival_inputs(prepared, rows),
    finite_check = all(is.finite(range(prepared$design))),
    model_object = ns$new_pprof_cox_stratified(prepared, estimates, spec),
    min_iterations = iterations, max_iterations = iterations, check = FALSE, memory = FALSE, filter_gc = FALSE
  )
  median <- stats::setNames(as.numeric(b$median), as.character(b$expression))
  share <- function(part) 100 * median[[part]] / median[["fitter"]]
  rest <- median[["fit"]] - median[["fitter"]] - median[["data_prepare"]] - median[["survival_inputs"]]
  lines <- c(lines, "", sprintf("%s: %s rows, %d providers, %d covariates; medians of %d runs", id,
                                format(sc$n, big.mark = ",", scientific = FALSE), sc$m, sc$p, iterations),
             sprintf("  %-16s %8.3f s  %6.1f%% of the fitter", names(median), median, vapply(names(median), share, 0)),
             sprintf("  fit - fitter = %.3f s; data_prepare() + survival_inputs() = %.3f s; the rest %.3f s",
                     median[["fit"]] - median[["fitter"]], median[["data_prepare"]] + median[["survival_inputs"]],
                     rest))
  writeLines(lines, out)
}
