# Final review, D-30 and D-55 (DEC-084): the null model of the one-covariate likelihood-ratio
# test has provider effects only, and with the default stopping rule ("or" in pprof 1.0.3,
# "any" here) its fit stops after one iteration, because the change in an empty coefficient
# vector is 0. Compares pprof 1.0.3's no-covariate fit (the fixture, made with R 4.5.0's
# reformulate() emulated) with the maximum-likelihood provider effects logit(mean), and the
# likelihood-ratio statistic against that null model with one against a converged null model.
# Run from the repository root: Rscript <this file> <output file>
out <- commandArgs(trailingOnly = TRUE)[1]
fixtures_dir <- "tests/testthat/fixtures/reference"
suppressMessages(devtools::load_all(".", quiet = TRUE, helpers = TRUE, export_all = TRUE))
sink(out)
fx <- readRDS(file.path(fixtures_dir, "logis_fe-screening-nocov.rds"))
cat("reference fit output:\n")
cat(head(fx$result$output, 20), sep = "\n")
v <- fx$result$value
gamma <- as.numeric(v$coefficient$gamma)
data <- v$data_include
y <- data$Y
prov <- data$ProvID
ybar <- tapply(y, factor(prov, levels = unique(prov)), mean)
mle <- stats::qlogis(as.numeric(ybar))
finite <- is.finite(mle)
cat(sprintf("\nproviders %d (all-or-none events %d); max |gamma - logit(mean)| over the others: %.3g\n",
            length(gamma), sum(!finite), max(abs(gamma[finite] - mle[finite]))))
# The likelihood-ratio statistic with the one-iteration null fit and with the converged one
# (tol 1e-12, stop "all"), for the one-covariate fit.
model <- model_case_fit("logis_fe-screening-onecov")
args <- model_case_arguments(model$fixture$case, reference_datasets_for(model$fixture$case, "core"))
null_model <- refit_without(model$fit, "x1", args$data)
stop_state <- null_model$convergence[setdiff(names(null_model$convergence), "history")]
cat(sprintf("package's null model: %d iterations, criteria at stop: %s\n", null_model$convergence$iterations,
            paste(utils::capture.output(str(stop_state)), collapse = " ")))
full <- infer_clamped_neg2_loglik(model$fit)
lr_reference_way <- infer_clamped_neg2_loglik(null_model) - full
prepared <- model_prepared_data(model$fit, args$data)
spec <- logistic_fe_null_spec
spec$stop_rule <- "all"
spec$tol <- 1e-12
null_prepared <- prepared
null_prepared$design <- prepared$design[, character(0), drop = FALSE]
converged <- new_pprof_logistic_fe(null_prepared, logistic_fe_estimate(null_prepared, spec, threads = 1L), spec)
lr_converged <- infer_clamped_neg2_loglik(converged) - full
cat(sprintf(paste("LR statistic: %.17g with the one-iteration null fit (pprof 1.0.3), %.17g with a converged one",
                  "(%d iterations)\n"), lr_reference_way, lr_converged, converged$convergence$iterations))
cat(sprintf("p-values: %.6g and %.6g\n", stats::pchisq(lr_reference_way, 1, lower.tail = FALSE),
            stats::pchisq(lr_converged, 1, lower.tail = FALSE)))
# For comparison: two covariates, whose null fit has one covariate.
two <- model_case_fit("logis_fe-screening-twocov")
two_args <- model_case_arguments(two$fixture$case, reference_datasets_for(two$fixture$case, "core"))
cat(sprintf("two-covariate fit: null model of x1 takes %d iterations\n",
            refit_without(two$fit, "x1", two_args$data)$convergence$iterations))
sink()
