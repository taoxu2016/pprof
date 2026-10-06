# Phase 8, step 8 (DEC-044, DEC-079): where R's heap peaks in fit_logistic_fe() on the benchmark
# scenario bin-1e6-m1000-p50, stage by stage: before each stage the heap's maximum is reset, and
# after it gc() reports the maximum during the stage ("max used") and what stays live ("used").
# The paired benchmark found gc()'s maximum at 2,498 MB for the working tree and 2,217 MB for
# pprof 1.0.3, identical in every round.
# Run from the repository root: Rscript <this file> <output file>
args <- commandArgs(trailingOnly = TRUE)
suppressMessages(devtools::load_all(quiet = TRUE))
source("dev/bench/scenarios.R")
scenario <- Filter(function(s) identical(s$id, "bin-1e6-m1000-p50"), bench_scenarios())[[1]]
d <- bench_data(scenario)
covariates <- grep("^x", names(d), value = TRUE)
formula <- stats::reformulate(covariates, response = "Y")
megabytes <- function(column) {
  g <- gc()
  sum(g[, which(colnames(g) == column) + 1L])
}
lines <- c(sprintf("Scenario %s: %d rows, %d covariates; the data frame holds %.0f MB.", scenario$id, nrow(d),
                   length(covariates), as.numeric(utils::object.size(d)) / 2^20), "",
           "| Stage | Live before (MB) | Maximum during (MB) | Above live before (MB) | Live after (MB) |",
           "|---|---|---|---|---|")
stage <- function(name, expr) {
  before <- megabytes("used")
  invisible(gc(reset = TRUE))
  value <- force(expr)
  lines <<- c(lines, sprintf("| %s | %.0f | %.0f | %.0f | %.0f |", name, before, megabytes("max used"),
                             megabytes("max used") - before, megabytes("used")))
  value
}
spec <- list(family = "logistic_fe", method = "serbin", max_iter = 10000, tol = 1e-5, stop_rule = "any",
             backtrack = TRUE, effect_bound = 10, min_provider_size = 10, keep_data = FALSE)
prepared <- stage("data_prepare()", data_prepare(formula, d, "ProvID", min_provider_size = 10, event_counts = TRUE))
stage("logistic_fe_check_rank(): the within-provider rank check (D-38)", logistic_fe_check_rank(prepared))
estimates <- stage("logistic_fe_estimate(): the engine, the variances, the fit statistics",
                   logistic_fe_estimate(prepared, spec, 1L))
model <- stage("new_pprof_logistic_fe()", new_pprof_logistic_fe(prepared, estimates, spec))
rm(prepared, estimates, model)
fit <- stage("fit_logistic_fe(), the whole call", fit_logistic_fe(formula, d, "ProvID"))
lines <- c(lines, "", "The fit's design matrix alone is n x p doubles: 1e6 x 50 x 8 bytes = 381 MB.")
writeLines(lines, args[1])
