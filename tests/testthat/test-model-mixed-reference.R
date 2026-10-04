# The random-effect fits against the reference fixtures (Phase 4): for every linear_re(),
# logis_re(), linear_cre(), and logis_cre() fit case that returned a value, the new fit of
# the same data with the same lme4 arguments reproduces the reference's estimates,
# variances, fitted values, linear predictor, and fit statistics, the lme4 fit itself, and
# the standard errors that the reference's test() reported (K-69, K-70), at the lme4 tier,
# run only under the lme4 and Matrix versions of the fixtures (DEC-020). The lme4 formula
# puts the random intercept after the fixed terms (DEC-042); where the reference's formula
# did too (its formula interface and its CRE fits), the formulas are also compared.
local_strict_mode()

mixed_reference_funs <- c("linear_re", "logis_re", "linear_cre", "logis_cre")

for (set in c("core", "full")) {
  ids <- model_new_case_ids(mixed_reference_funs, set)
  if (set == "core" && length(ids) == 0L) {
    test_that("reference random-effect fixtures are available", skip("Reference fixtures or jsonlite not available"))
  }
  for (id in ids) {
    local({
      case_id <- id
      case_set <- set
      test_that(paste("the new random-effect fit reproduces the reference fit:", case_id), {
        fixture <- reference_fixture(case_id, case_set)
        case <- fixture$case
        if (identical(case_set, "full") || isTRUE(case$heavy)) skip_on_cran()
        versions <- reference_lme4_matches(case_set)
        if (!versions$ok) skip(paste("lme4-backed fixture not comparable:", versions$detail))
        fit <- model_new_fit(case_id, case_set, keep_data = TRUE)$fit
        value <- fixture$result$value
        named <- function(column) stats::setNames(as.numeric(column), rownames(column))
        expect_lme4 <- function(actual, expected, label) expect_reference_value(actual, expected, "lme4", label)

        expect_lme4(fit$coefficients, named(value$coefficient$FE), "fixed effects")
        expect_lme4(fit$provider_effects, named(value$coefficient$RE), "provider effects")
        expect_lme4(fit$variance_components$provider, as.numeric(value$variance$alpha), "provider variance")
        expect_lme4(fit$vcov, value$variance$FE, "vcov")
        if (case$fun %in% c("linear_re", "linear_cre")) expect_lme4(fit$sigma, value$sigma, "sigma")
        expect_lme4(fit$loglik, as.numeric(value$Loglkd), "log-likelihood")
        expect_identical(fit$loglik_df, attr(value$Loglkd, "df"))
        expect_lme4(fit$aic, value$AIC, "AIC")
        expect_lme4(fit$bic, value$BIC, "BIC")
        # logis_cre() returns its fitted values without row names; its linear predictor keeps
        # the row names of lme4's design, 1..n (BEHAVIOR_SPECS §6).
        row_names <- !identical(case$fun, "logis_cre")
        expect_lme4(model_reference_matrix(fit$fitted, "Prediction", case_set, row_names), value$fitted, "fitted")
        expect_lme4(model_reference_matrix(fit$linear_predictor, "Fixed Fitted", case_set), value$linear_pred,
                    "linear predictor")

        engine <- reference_fixture_value(fit$engine_fit, reference_manifest(case_set)$max_full_length)
        expected <- attr(value, "model")
        same_formula <- case$fun %in% c("linear_cre", "logis_cre") || !is.null(case$args$formula)
        fields <- if (same_formula) names(expected) else setdiff(names(expected), "formula")
        expect_lme4(unclass(engine)[fields], unclass(expected)[fields], "lme4 fit")

        se <- model_reference_std_errors(case_id, case_set)
        if (!is.null(se)) expect_lme4(provider_estimate_se(fit), se, "standard errors")
      })
    })
  }
}
