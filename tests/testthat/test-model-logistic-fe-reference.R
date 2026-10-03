# fit_logistic_fe() against the reference fixtures (Phase 3): for every logis_fe() fit case
# that returned a value, the new fit of the same data with the same settings takes the same
# number of iterations (DEC-014) and reproduces the estimates, variances, fit statistics,
# linear predictor, and fitted probabilities of the reference. The AUC, which the rewrite
# computes without pROC, is compared at the closed-form tier (D-40).
local_strict_mode()

for (set in c("core", "full")) {
  ids <- engine_reference_ids(set)
  if (set == "core" && length(ids) == 0L) {
    test_that("reference fit fixtures are available", skip("Reference fixtures or jsonlite not available"))
  }
  for (id in ids) {
    local({
      case_id <- id
      case_set <- set
      test_that(paste("fit_logistic_fe() reproduces the reference fit:", case_id), {
        fixture <- reference_fixture(case_id, case_set)
        if (identical(case_set, "full") || isTRUE(fixture$case$heavy)) skip_on_cran()
        fit <- model_case_fit(case_id, case_set)$fit
        value <- fixture$result$value
        named <- function(column) stats::setNames(as.numeric(column), rownames(column))

        expect_identical(fit$convergence$iterations, fixture$result$iterations)
        expect_reference_value(fit$coefficients, named(value$coefficient$beta), "iterative", "coefficients")
        expect_reference_value(fit$provider_effects, named(value$coefficient$gamma), "iterative", "provider effects")
        expect_reference_value(fit$vcov, value$variance$beta, "iterative", "vcov")
        expect_reference_value(fit$provider_effect_variance, named(value$variance$gamma), "iterative",
                               "provider effect variances")
        expect_reference_value(fit$loglik, value$Loglkd, "iterative", "log-likelihood")
        expect_reference_value(fit$aic, value$AIC, "iterative", "AIC")
        expect_reference_value(fit$bic, value$BIC, "iterative", "BIC")
        expect_reference_value(fit$auc, value$AUC, "closed_form", "AUC")
        expect_reference_value(model_reference_column(fit$linear_predictor, "Linear Predictor", case_set),
                               value$linear_pred, "iterative", "linear predictor")
        probabilities <- model_reference_column(logistic_fe_probabilities(fit), "Predicted Probability", case_set)
        expect_reference_value(probabilities, value$fitted, "iterative", "fitted probabilities")
      })
    })
  }
}
