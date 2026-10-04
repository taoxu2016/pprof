# fit_linear_fe(): argument and data checks, the model object, the reference fixtures at the
# closed-form tier (DEC-006: direct demeaning instead of dense centering), the provider
# variance (K-42, D-16), and the methods and contract of pprof_linear_fe.
local_strict_mode()

linear_data <- function() {
  data.frame(y = ExampleDataLinear$Y, hospital = ExampleDataLinear$ProvID, ExampleDataLinear$Z)
}
linear_formula <- y ~ z1 + z2 + z3 + z4 + z5

test_that("fit_linear_fe() rejects invalid settings and data", {
  data <- linear_data()
  invalid <- function(...) {
    expect_error(fit_linear_fe(linear_formula, data, "hospital", ...), class = "pprof_error_invalid_input")
  }
  # The new API takes the full names; the compatibility wrapper translates "s" and "f".
  for (value in list("s", "f", "Full", NA, c("simplified", "full"))) invalid(provider_variance = value)
  invalid(keep_data = "yes")
  invalid(verbose = NA)
  infinite <- data
  infinite$z2[10] <- Inf
  expect_error(fit_linear_fe(linear_formula, infinite, "hospital"), class = "pprof_error_invalid_input")
  infinite_outcome <- data
  infinite_outcome$y[3] <- -Inf
  expect_error(fit_linear_fe(linear_formula, infinite_outcome, "hospital"), class = "pprof_error_invalid_input")
  expect_error(fit_linear_fe(y ~ 1, data, "hospital"), class = "pprof_error_invalid_input")
  expect_error(fit_linear_fe(y ~ z1 - 1, data, "hospital"), class = "pprof_error_invalid_input")
})

test_that("the model holds the shared fields and the fit statistics, and includes every provider (K-07)", {
  data <- linear_data()
  # A provider of one observation is kept, unlike in the logistic models.
  data <- data[-which(data$hospital == 1)[-1], ]
  fit <- fit_linear_fe(linear_formula, data, "hospital")
  expect_s3_class(fit, c("pprof_linear_fe", "pprof_model"), exact = TRUE)
  expect_identical(validate_pprof_linear_fe(fit), fit)
  expect_true(all(fit$providers$included))
  expect_identical(fit$n_providers, 100L)
  expect_identical(fit$providers$n_obs[1], 1L)
  expect_identical(fit$spec$provider_variance, "simplified")
  expect_identical(names(fit$coefficients), paste0("z", 1:5))
  expect_null(fit$convergence)
  for (field in c("sigma", "loglik", "aic", "bic")) expect_true(is.numeric(fit[[field]]) && length(fit[[field]]) == 1L)
  expect_null(fit$data)
  expect_s3_class(fit_linear_fe(linear_formula, data, "hospital", keep_data = TRUE)$data, "pprof_data")
})

test_that("fit_linear_fe() reproduces the reference's linear_fe() fits at the closed-form tier (K-40 to K-43)", {
  ids <- model_new_case_ids("linear_fe")
  skip_if(length(ids) == 0L, "Reference fixtures or jsonlite not available")
  for (id in ids) {
    new <- model_new_fit(id)
    fit <- new$fit
    value <- new$fixture$result$value
    named <- function(column) stats::setNames(as.numeric(column), rownames(column))
    expect_reference_value(fit$coefficients, named(value$coefficient$beta), "closed_form", paste(id, "coefficients"))
    expect_reference_value(fit$provider_effects, named(value$coefficient$gamma), "closed_form", paste(id, "effects"))
    expect_reference_value(fit$vcov, value$variance$beta, "closed_form", paste(id, "vcov"))
    expect_reference_value(fit$provider_effect_variance, named(value$variance$gamma), "closed_form",
                           paste(id, "effect variances"))
    expect_identical(attr(value$variance$gamma, "description"), fit$spec$provider_variance)
    for (field in c("sigma", "loglik", "aic", "bic")) {
      reference <- switch(field, sigma = value$sigma, loglik = value$Loglkd, aic = value$AIC, bic = value$BIC)
      expect_reference_value(fit[[field]], reference, "closed_form", paste(id, field))
    }
    expect_reference_value(model_reference_matrix(fit$linear_predictor, "Linear Predictor"), value$linear_pred,
                           "closed_form", paste(id, "linear predictor"))
    expect_reference_value(model_reference_matrix(linear_fe_fitted(fit), "Prediction"), value$fitted, "closed_form",
                           paste(id, "fitted values"))
    expect_reference_value(model_reference_matrix(as.numeric(fit$response) - linear_fe_fitted(fit), "Residuals"),
                           value$residuals, "closed_form", paste(id, "residuals"))
    se <- model_reference_std_errors(id)
    if (!is.null(se)) expect_reference_value(provider_estimate_se(fit), se, "closed_form", paste(id, "std errors"))
  }
})

test_that("the full provider variance adds the coefficient uncertainty to the simplified one (K-42, D-16)", {
  data <- linear_data()
  simplified <- fit_linear_fe(linear_formula, data, "hospital")
  full <- fit_linear_fe(linear_formula, data, "hospital", provider_variance = "full")
  expect_identical(full$provider_effects, simplified$provider_effects)
  expect_identical(full$spec$provider_variance, "full")
  sizes <- simplified$providers$n_obs
  expect_identical(unname(simplified$provider_effect_variance), simplified$sigma^2 / sizes)
  expect_true(all(full$provider_effect_variance > simplified$provider_effect_variance))
})

test_that("covariates that are dependent within providers are a classed error", {
  data <- transform(linear_data(), constant = hospital %% 7)
  expect_error(fit_linear_fe(y ~ z1 + constant, data, "hospital"), class = "pprof_error_data")
})

test_that("verbose = FALSE prints nothing, and verbose = TRUE reports through pprof_message", {
  data <- linear_data()
  expect_silent(fit_linear_fe(linear_formula, data, "hospital"))
  expect_message(fit_linear_fe(linear_formula, data, "hospital", verbose = TRUE), class = "pprof_message")
})

test_that("the standard methods of pprof_linear_fe", {
  data <- linear_data()
  fit <- fit_linear_fe(linear_formula, data, "hospital")
  values <- fitted(fit)
  expect_identical(names(values), as.character(sort(fit$row_index)))
  expect_identical(unname(values), unname(linear_fe_fitted(fit)[order(fit$row_index)]))
  expect_identical(unname(residuals(fit)), data$y[sort(fit$row_index)] - unname(values))
  expect_error(residuals(fit, type = "pearson"), class = "pprof_error_invalid_input")
  expect_identical(predict(fit), values)
  newdata <- data[c(5, 900, 2), ]
  expect_equal(unname(predict(fit, newdata)), unname(values[c("5", "900", "2")]), tolerance = 1e-12)
  unknown <- transform(newdata, hospital = c(1000, newdata$hospital[2:3]))
  expect_warning(predicted <- predict(fit, unknown), class = "pprof_warning_unknown_providers")
  expect_true(is.na(predicted[1]))
  log_likelihood <- logLik(fit)
  expect_identical(as.numeric(log_likelihood), fit$loglik)
  expect_identical(attr(log_likelihood, "df"), 106)
  expect_identical(stats::AIC(fit), fit$aic)
  expect_equal(stats::BIC(fit), fit$bic, tolerance = 1e-14)
  expect_identical(coef(fit), fit$coefficients)
  expect_identical(vcov(fit), fit$vcov)
  expect_identical(nobs(fit), 7901L)
  expect_output(print(fit), "<pprof model: linear_fe>", fixed = TRUE)
})

test_that("the contract methods of pprof_linear_fe (K-60)", {
  fit <- fit_linear_fe(linear_formula, linear_data(), "hospital")
  effects <- unname(fit$provider_effects)
  expect_identical(expected_outcome(fit, 0), fit$linear_predictor)
  expect_identical(expected_outcome(fit, fit$provider_effects), linear_fe_fitted(fit))
  expect_identical(null_effect(fit, "median"), stats::median(effects))
  expect_identical(null_effect(fit, "mean"), sum(fit$providers$n_obs * effects) / fit$n_obs)
  expect_identical(null_effect(fit, 1L), 1)
  expect_error(null_effect(fit, "mode"), class = "pprof_error_invalid_input")
  expect_identical(provider_estimate_se(fit), sqrt(fit$provider_effect_variance))
})

test_that("linear fixed-effect models have Wald inference only (ARCHITECTURE §E.3, Phase 5)", {
  # The results are checked against the reference in test-profile-families.R.
  fit <- fit_linear_fe(linear_formula, linear_data(), "hospital")
  unsupported <- function(expr) expect_error(expr, class = "pprof_error_unsupported_inference")
  unsupported(test_providers(fit, "exact"))
  unsupported(test_providers(fit, "score"))
  unsupported(provider_effects(fit, interval = "score"))
  unsupported(test_coefficients(fit, "lr"))
  expect_s3_class(test_providers(fit), "pprof_provider_tests")
  expect_s3_class(summary(fit), "pprof_summary")
  expect_s3_class(tidy(fit), "tbl_df")
  expect_s3_class(glance(fit), "tbl_df")
  expect_identical(nrow(augment(fit)), 7901L)
})
