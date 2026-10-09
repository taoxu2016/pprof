# fit_logistic_firth(): argument and data checks, the model object, the reference
# fixtures, threads (D-05), failures (D-42), warnings, verbosity, and the logistic
# fixed-effect methods and inference it inherits (DEC-004, D-12).
local_strict_mode()

firth_data <- function() {
  data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID, ExampleDataBinary$Z)
}
firth_formula <- y ~ z1 + z2 + z3 + z4 + z5

test_that("fit_logistic_firth() rejects invalid settings and data (D-39)", {
  data <- firth_data()
  invalid <- function(...) {
    expect_error(fit_logistic_firth(firth_formula, data, "hospital", ...), class = "pprof_error_invalid_input")
  }
  for (value in list(0, -1, 10.5, NA, "10")) invalid(max_iter = value)
  for (value in list(0, -1e-5, Inf, NA)) invalid(tol = value)
  for (value in list(0, -1, NA)) invalid(effect_bound = value)
  for (value in list(0, 1.5, NA)) invalid(min_provider_size = value)
  invalid(keep_data = "yes")
  for (value in list(0, -1, 1.5, NA)) invalid(threads = value)
  invalid(verbose = NA)
  expect_error(fit_logistic_firth(firth_formula, transform(data, y = y / 2), "hospital"),
               class = "pprof_error_invalid_input")
  expect_error(fit_logistic_firth(firth_formula, transform(data, y = 0), "hospital"), class = "pprof_error_data")
  expect_error(fit_logistic_firth(y ~ 1, data, "hospital"), class = "pprof_error_invalid_input")
})

test_that("the model holds the logistic fields, the penalized log-likelihood, and the convergence (K-34)", {
  fit <- fit_logistic_firth(firth_formula, firth_data(), "hospital")
  expect_s3_class(fit, c("pprof_logistic_firth", "pprof_logistic_fe", "pprof_model"), exact = TRUE)
  expect_identical(validate_pprof_logistic_firth(fit), fit)
  expect_identical(fit$spec$family, "logistic_firth")
  expect_identical(fit$n_obs, 7944L)
  expect_identical(names(fit$coefficients), paste0("z", 1:5))
  convergence <- fit$convergence
  expect_identical(convergence$iterations, 16L)
  expect_true(convergence$converged)
  expect_identical(convergence$stop_rule, "coefficients")
  expect_identical(dim(convergence$history), c(16L, 2L))
  expect_identical(convergence$criterion, unname(convergence$history[16, "coefficients"]))
  expect_identical(fit$penalized_loglik, unname(convergence$history[16, "penalized_loglik"]))
  # D-12: the log-likelihood, AIC, and BIC are the unpenalized ones at the Firth estimates
  # (V12.2: -2695.666 and the penalized -2576.678).
  eta <- fit$linear_predictor + rep(unname(fit$provider_effects), fit$providers$n_obs)
  expect_identical(fit$loglik, sum(eta * fit$response - log(1 + exp(eta))))
  expect_equal(fit$loglik, -2695.666, tolerance = 1e-6)
  expect_equal(fit$penalized_loglik, -2576.678, tolerance = 1e-6)
  expect_null(fit$data)
  expect_s3_class(fit_logistic_firth(firth_formula, firth_data(), "hospital", keep_data = TRUE)$data, "pprof_data")
})

test_that("fit_logistic_firth() reproduces the reference's logis_firth() fits (K-30 to K-34)", {
  # D-54: fit_logistic_firth() needs a covariate, where pprof 1.0.3 fits a model with none from
  # R 4.5.0; test-cpp-reference-engines.R checks that the Firth engine reproduces that fit.
  ids <- setdiff(model_new_case_ids("logis_firth"), "logis_firth-screening-nocov")
  skip_if(length(ids) == 0L, "Reference fixtures or jsonlite not available")
  for (id in ids) {
    new <- model_new_fit(id)
    fit <- new$fit
    expected <- new$fixture$result
    value <- expected$value
    named <- function(column) stats::setNames(as.numeric(column), rownames(column))
    expect_identical(fit$convergence$iterations, expected$iterations, label = id)
    expect_identical(firth_log(list(history = fit$convergence$history)), engine_reference_log(expected$output),
                     label = id)
    expect_reference_value(fit$coefficients, named(value$coefficient$beta), "iterative", paste(id, "coefficients"))
    expect_reference_value(fit$provider_effects, named(value$coefficient$gamma), "iterative", paste(id, "effects"))
    expect_reference_value(fit$vcov, value$variance$beta, "iterative", paste(id, "vcov"))
    expect_reference_value(fit$provider_effect_variance, named(value$variance$gamma), "iterative",
                           paste(id, "effect variances"))
    expect_reference_value(fit$loglik, value$Loglkd, "iterative", paste(id, "log-likelihood"))
    expect_reference_value(fit$aic, value$AIC, "iterative", paste(id, "AIC"))
    expect_reference_value(fit$bic, value$BIC, "iterative", paste(id, "BIC"))
    expect_reference_value(fit$auc, value$AUC, "closed_form", paste(id, "AUC"))
    expect_reference_value(model_reference_matrix(fit$linear_predictor, "Linear Predictor"), value$linear_pred,
                           "iterative", paste(id, "linear predictor"))
    expect_reference_value(model_reference_matrix(logistic_fe_probabilities(fit), "Predicted Probability"),
                           value$fitted, "iterative", paste(id, "fitted probabilities"))
  }
})

test_that("two threads give a fit identical to one thread (D-05)", {
  data <- firth_data()
  one <- fit_logistic_firth(firth_formula, data, "hospital")
  two <- fit_logistic_firth(firth_formula, data, "hospital", threads = 2)
  for (field in c("coefficients", "provider_effects", "vcov", "provider_effect_variance", "loglik", "penalized_loglik",
                  "convergence")) {
    expect_identical(two[[field]], one[[field]], label = field)
  }
})

test_that("a singular information matrix is a classed error, where the reference terminated R (D-42)", {
  data <- transform(firth_data(), zero = 0)
  expect_warning(
    expect_error(fit_logistic_firth(y ~ z1 + zero, data, "hospital"), class = "pprof_error_convergence"),
    class = "pprof_warning_rank_deficient"
  )
})

test_that("a fit that reaches the iteration limit warns and reports that it did not converge (K-33)", {
  warning <- expect_warning(
    fit <- fit_logistic_firth(firth_formula, firth_data(), "hospital", max_iter = 3, tol = 1e-12),
    class = "pprof_warning_not_converged"
  )
  expect_identical(warning$iterations, 3L)
  expect_false(fit$convergence$converged)
  expect_identical(fit$convergence$iterations, 3L)
})

test_that("providers below min_provider_size are excluded, and factor IDs work when they are (K-06, D-41)", {
  data <- firth_data()
  data$hospital <- sprintf("P%03d", data$hospital)
  as_factor <- transform(data, hospital = factor(hospital))
  expect_warning(character_fit <- fit_logistic_firth(firth_formula, data, "hospital", min_provider_size = 60),
                 class = "pprof_warning_screening")
  expect_warning(factor_fit <- fit_logistic_firth(firth_formula, as_factor, "hospital", min_provider_size = 60),
                 class = "pprof_warning_screening")
  expect_identical(factor_fit$n_excluded_providers, 3L)
  expect_identical(factor_fit$provider_effects, character_fit$provider_effects)
  expect_identical(factor_fit$coefficients, character_fit$coefficients)
})

test_that("verbose = FALSE prints nothing, and verbose = TRUE reports every iteration through pprof_message", {
  data <- firth_data()
  expect_silent(fit_logistic_firth(firth_formula, data, "hospital"))
  messages <- character()
  withCallingHandlers(fit_logistic_firth(firth_formula, data, "hospital", verbose = TRUE), pprof_message = function(m) {
    messages <<- c(messages, conditionMessage(m))
    invokeRestart("muffleMessage")
  })
  expect_length(messages, 2L + 16L + 1L)
  expect_match(messages[3], "Iteration 1: criterion 5.022e-01.", fixed = TRUE)
  expect_match(messages[19], "Firth converged after 16 iterations.", fixed = TRUE)
})

test_that("Firth models use the logistic fixed-effect methods, contract, and inference (DEC-004, D-12)", {
  fit <- fit_logistic_firth(firth_formula, firth_data(), "hospital")
  # Every capability but the Poisson tests and limits of Cox models (CoxPH Phase C3).
  expect_setequal(inference_capabilities(fit), setdiff(capability_names, c("provider_midp", "interval_midp")))
  expect_identical(profile_spec(fit)$family, "logistic_fe")
  expect_identical(unname(fitted(fit)), unname(logistic_fe_probabilities(fit)[order(fit$row_index)]))
  expect_identical(predict(fit, type = "response"), fitted(fit))
  expect_identical(as.numeric(logLik(fit)), fit$loglik)
  expect_identical(attr(logLik(fit), "df"), 105L)
  expect_identical(stats::AIC(fit), fit$aic)
  expect_identical(provider_estimate_se(fit), sqrt(fit$provider_effect_variance))
  expect_identical(null_effect(fit, "median"), stats::median(unname(fit$provider_effects)))
  tests <- test_providers(fit)
  expect_s3_class(tests, "pprof_provider_tests")
  expect_identical(nrow(tests$table), 100L)
  expect_identical(rownames(confint(fit)), names(fit$coefficients))
  expect_s3_class(summary(fit), "pprof_summary")
  expect_output(print(fit), "<pprof model: logistic_firth>", fixed = TRUE)
})
