# fit_logistic_fe(): argument and data checks, the model object, warnings, verbosity, and
# the contract methods of pprof_logistic_fe (ARCHITECTURE §B.5, §D, §E).
local_strict_mode()

example_data <- function() {
  data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID, ExampleDataBinary$Z)
}
example_formula <- y ~ z1 + z2 + z3 + z4 + z5

fixture_dataset <- function(name) readRDS(reference_locate(file.path("datasets", paste0(name, ".rds")), "core"))

test_that("fit_logistic_fe() rejects invalid settings (D-22, D-23, D-39)", {
  data <- example_data()
  invalid <- function(...) {
    expect_error(fit_logistic_fe(example_formula, data, "hospital", ...), class = "pprof_error_invalid_input")
  }
  invalid(method = "SerBIN")
  invalid(method = "newton")
  for (value in list(0, -1, 10.5, NA, "10")) invalid(max_iter = value)
  for (value in list(0, -1e-5, Inf, NA)) invalid(tol = value)
  invalid(stop_rule = "or")
  for (value in list(2, NA, "TRUE")) invalid(backtrack = value)
  for (value in list(0, -1, NA)) invalid(effect_bound = value)
  for (value in list(0, 1.5, NA)) invalid(min_provider_size = value)
  invalid(keep_data = "yes")
  for (value in list(0, -1, 1.5, NA)) invalid(threads = value)
  invalid(verbose = NA)
})

test_that("the outcome must be binary with both values, and the covariates finite (D-39)", {
  data <- example_data()
  half <- transform(data, y = y / 2)
  expect_error(fit_logistic_fe(example_formula, half, "hospital"), class = "pprof_error_invalid_input")
  none <- transform(data, y = 0)
  expect_error(fit_logistic_fe(example_formula, none, "hospital"), class = "pprof_error_data")
  infinite <- data
  infinite$z2[10] <- Inf
  expect_error(fit_logistic_fe(example_formula, infinite, "hospital"), class = "pprof_error_invalid_input")
  expect_error(fit_logistic_fe(y ~ 1, data, "hospital"), class = "pprof_error_invalid_input")
  logical_outcome <- transform(data, y = y == 1)
  expect_identical(fit_logistic_fe(example_formula, logical_outcome, "hospital")$coefficients,
                   fit_logistic_fe(example_formula, data, "hospital")$coefficients)
})

test_that("the model holds the shared fields, the fit statistics, and the convergence diagnostics", {
  fit <- fit_logistic_fe(example_formula, example_data(), "hospital")
  expect_s3_class(fit, c("pprof_logistic_fe", "pprof_model"), exact = TRUE)
  expect_identical(validate_pprof_logistic_fe(fit), fit)
  expect_identical(fit$n_obs, 7944L)
  expect_identical(fit$n_providers, 100L)
  expect_identical(names(fit$coefficients), paste0("z", 1:5))
  expect_identical(names(fit$provider_effects), as.character(sort(unique(ExampleDataBinary$ProvID))))
  expect_identical(names(fit$provider_effect_variance), names(fit$provider_effects))
  expect_identical(fit$spec$method, "serbin")
  expect_identical(fit$data_spec$provider_name, "hospital")
  expect_null(fit$data)
  convergence <- fit$convergence
  expect_identical(convergence$iterations, 8L)
  expect_true(convergence$converged)
  expect_identical(dim(convergence$history), c(8L, 4L))
  expect_identical(convergence$criterion, unname(convergence$history[8, "rule"]))
  expect_identical(convergence$criterion, min(convergence$criteria))
  expect_identical(convergence$stop_rule, "any")
  expect_identical(convergence$tol, 1e-5)
  expect_identical(convergence$max_iter, 10000)
  for (field in c("loglik", "aic", "bic", "auc")) expect_true(is.numeric(fit[[field]]) && length(fit[[field]]) == 1L)
  expect_s3_class(fit_logistic_fe(example_formula, example_data(), "hospital", keep_data = TRUE)$data, "pprof_data")
})

test_that("providers with fewer than min_provider_size observations are excluded, with the true count (K-06, D-01)", {
  data <- fixture_dataset("syn_screening")
  # Providers of sizes 5, 9, 10, and 11 next to 26 providers of 25: sizes 5 and 9 are
  # excluded; the reference's warning also counted the provider of size 10 (D-01).
  warning <- expect_warning(fit <- fit_logistic_fe(Y ~ x1 + x2 + x3, data, "ProvID"), class = "pprof_warning_screening")
  expect_identical(warning$n_excluded, 2L)
  expect_identical(fit$n_excluded_providers, 2L)
  expect_identical(sort(fit$providers$n_obs[!fit$providers$included]), c(5L, 9L))
  expect_true(10L %in% fit$providers$n_obs[fit$providers$included])
})

test_that("factor provider IDs work when screening excludes providers, as character IDs do (D-41)", {
  data <- example_data()
  data$hospital <- sprintf("P%03d", data$hospital)
  as_factor <- transform(data, hospital = factor(hospital))
  expect_warning(character_fit <- fit_logistic_fe(example_formula, data, "hospital", min_provider_size = 60),
                 class = "pprof_warning_screening")
  expect_warning(factor_fit <- fit_logistic_fe(example_formula, as_factor, "hospital", min_provider_size = 60),
                 class = "pprof_warning_screening")
  expect_identical(factor_fit$provider_effects, character_fit$provider_effects)
  expect_identical(factor_fit$coefficients, character_fit$coefficients)
  expect_identical(factor_fit$n_excluded_providers, 3L)
})

test_that("a fit that reaches the iteration limit warns and reports that it did not converge (K-17, D-03)", {
  data <- example_data()
  warning <- expect_warning(
    fit <- fit_logistic_fe(example_formula, data, "hospital", max_iter = 3, tol = 1e-300, stop_rule = "coefficients"),
    class = "pprof_warning_not_converged"
  )
  expect_identical(warning$iterations, 4L)
  expect_false(fit$convergence$converged)
  expect_warning(fit <- fit_logistic_fe(example_formula, data, "hospital", method = "ban", max_iter = 3, tol = 1e-300),
                 class = "pprof_warning_not_converged")
  expect_identical(fit$convergence$iterations, 3L)
})

test_that("covariates that are dependent within providers warn but are fitted as the reference fits them (D-38)", {
  warning <- expect_warning(fit <- fit_logistic_fe(Y ~ x1 + x2 + x3, fixture_dataset("syn_collinear"), "ProvID"),
                            class = "pprof_warning_rank_deficient")
  expect_identical(warning$rank, 2L)
  expect_identical(warning$aliased, "x3")
  expect_true(all(is.finite(fit$coefficients)))
  # A covariate that is constant within providers is absorbed by the provider effects; the
  # variance step then fails, as in the reference.
  expect_warning(
    expect_error(fit_logistic_fe(Y ~ x1 + x2 + xc, fixture_dataset("syn_constant"), "ProvID"),
                 class = "pprof_error_convergence"),
    class = "pprof_warning_rank_deficient"
  )
})

test_that("verbose = FALSE prints nothing, and verbose = TRUE reports through pprof_message", {
  data <- example_data()
  expect_silent(fit_logistic_fe(example_formula, data, "hospital"))
  messages <- character()
  withCallingHandlers(fit_logistic_fe(example_formula, data, "hospital", verbose = TRUE), pprof_message = function(m) {
    messages <<- c(messages, conditionMessage(m))
    invokeRestart("muffleMessage")
  })
  expect_length(messages, 2L + 8L + 1L)
  expect_match(messages[3], "Iteration 1: criterion 5.022e-01.", fixed = TRUE)
  expect_match(messages[11], "SerBIN converged after 8 iterations.", fixed = TRUE)
})

test_that("transformed terms, interactions, and factor levels with spaces are fitted (D-18)", {
  terms_data <- fixture_dataset("syn_terms")
  precomputed <- transform(terms_data, logw = log(w), z1z2 = z1 * z2, z1sq = z1^2)
  pairs <- list(c("log(w)", "logw"), c("z1:z2", "z1z2"), c("I(z1^2)", "z1sq"))
  for (pair in pairs) {
    transformed <- fit_logistic_fe(stats::reformulate(c("z1", "z2", pair[1]), "Y"), terms_data, "ProvID")
    columns <- fit_logistic_fe(stats::reformulate(c("z1", "z2", pair[2]), "Y"), precomputed, "ProvID")
    expect_identical(unname(transformed$coefficients), unname(columns$coefficients), label = pair[1])
    expect_identical(transformed$provider_effects, columns$provider_effects, label = pair[1])
    expect_identical(names(transformed$coefficients)[3], pair[1])
  }
  factors <- fixture_dataset("syn_factors")
  fit <- fit_logistic_fe(Y ~ x1 + grp, factors, "ProvID")
  expect_identical(names(fit$coefficients), c("x1", "grplevel three", "grplevel two"))
})

test_that("the fits the reference cannot make equal its fits of the same models with plain columns (D-18)", {
  skip_off_reference_platform()
  # The reference fails on transformed terms, interactions, and factor levels with spaces;
  # it fits the same models with the terms computed as columns and the levels renamed
  # (logis_fe-terms-*-columns, logis_fe-factors-nospaces-formula).
  expect_reference_fit <- function(fit, id) {
    expected <- reference_fixture(id)$result$value$coefficient
    expect_reference_value(unname(fit$coefficients), as.numeric(expected$beta), "iterative", paste(id, "beta"))
    expect_reference_value(unname(fit$provider_effects), as.numeric(expected$gamma), "iterative", paste(id, "gamma"))
  }
  terms_data <- fixture_dataset("syn_terms")
  for (pair in list(c("log(w)", "logw"), c("z1:z2", "z1z2"), c("I(z1^2)", "z12"))) {
    fit <- fit_logistic_fe(stats::reformulate(c("z1", "z2", pair[1]), "Y"), terms_data, "ProvID")
    expect_reference_fit(fit, paste0("logis_fe-terms-", pair[2], "-columns"))
  }
  withr::with_collate("C", fit <- fit_logistic_fe(Y ~ x1 + grp, fixture_dataset("syn_factors"), "ProvID"))
  expect_reference_fit(fit, "logis_fe-factors-nospaces-formula")
})

test_that("two threads give the same fit as one, up to rounding (D-20)", {
  data <- example_data()
  one <- fit_logistic_fe(example_formula, data, "hospital")
  two <- fit_logistic_fe(example_formula, data, "hospital", threads = 2)
  expect_identical(two$convergence$iterations, one$convergence$iterations)
  expect_equal(two$coefficients, one$coefficients, tolerance = 1e-12)
  expect_equal(two$provider_effects, one$provider_effects, tolerance = 1e-12)
})

test_that("the contract methods of pprof_logistic_fe", {
  fit <- fit_logistic_fe(example_formula, example_data(), "hospital")
  effects <- fit$provider_effects
  expect_identical(expected_outcome(fit, 0), stats::plogis(fit$linear_predictor))
  expect_identical(expected_outcome(fit, effects), logistic_fe_probabilities(fit))
  expect_error(expected_outcome(fit, effects[-1]), class = "pprof_error_invalid_input")
  expect_identical(null_effect(fit, "median"), stats::median(unname(effects)))
  expect_identical(null_effect(fit, -0.5), -0.5)
  expect_identical(null_effect(fit, 0L), 0)
  expect_error(null_effect(fit, "mean"), class = "pprof_error_invalid_input")
  expect_error(null_effect(fit, c(0, 1)), class = "pprof_error_invalid_input")
  expect_identical(provider_estimate_se(fit), sqrt(fit$provider_effect_variance))
  expect_identical(profile_spec(fit)$family, "logistic_fe")
  expect_setequal(inference_capabilities(fit), capability_names)
})

test_that("the AUC equals pROC's, including pROC's choice of direction (DEC-009, D-40)", {
  skip_if_not_installed("pROC")
  proc_auc <- function(response, predictor) as.numeric(suppressMessages(pROC::auc(response, predictor)))
  fit <- fit_logistic_fe(example_formula, example_data(), "hospital")
  expect_equal(fit$auc, proc_auc(fit$response, logistic_fe_probabilities(fit)), tolerance = 1e-15)
  # Many ties, and a predictor whose controls have the higher median.
  withr::with_seed(11, {
    response <- stats::rbinom(500, 1, 0.3)
    tied <- round(stats::runif(500) + 0.3 * response, 1)
  })
  expect_equal(logistic_fe_auc(response, tied), proc_auc(response, tied), tolerance = 1e-15)
  expect_equal(logistic_fe_auc(response, -tied), proc_auc(response, -tied), tolerance = 1e-15)
})
