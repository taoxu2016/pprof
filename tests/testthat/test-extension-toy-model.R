# The extension proof (brief §5.3, ARCHITECTURE §E.4, DEC-024): a model defined only in test
# code (helper-toy-model.R) works with the data layer, the shared constructor, the contract,
# and the capability checks, without any change to the files of pprof. Each later phase adds
# its profiling and plotting functions to this file.
local_strict_mode()
register_toy_model()

test_that("a model defined outside pprof is built through the data layer and the shared constructor", {
  fit <- toy_fit(y ~ 1, toy_model_data(), "hospital")
  expect_s3_class(fit, c("pprof_toy_model", "pprof_model"), exact = TRUE)
  expect_identical(validate_pprof_model(fit), fit)
  expect_identical(fit$n_obs, 60L)
  expect_identical(fit$n_providers, 5L)
  expect_null(fit$data)
  expect_identical(names(provider_estimates(fit)), sprintf("hospital %d", 1:5))
  expect_identical(unname(provider_estimates(fit)), stats::qlogis(c(3, 5, 2, 8, 6) / (10:14)))
})

test_that("the shared contract accessors work on it", {
  fit <- toy_fit(y ~ 1, toy_model_data(), "hospital")
  expect_identical(provider_table(fit)$provider_id, sprintf("hospital %d", 1:5))
  expect_identical(provider_index(fit), rep(1:5, 10:14))
  expect_identical(observed_outcome(fit), toy_model_data()$y)
  expect_identical(linear_predictor(fit), rep(0, 60))
})

test_that("core code dispatches to the methods it registers", {
  fit <- toy_fit(y ~ 1, toy_model_data(), "hospital")
  expect_identical(inference_capabilities(fit), c("provider_exact", "provider_score", "standardize_indirect", "funnel"))
  expect_invisible(require_capability(fit, "provider_exact"))
  expect_identical(require_capability(fit, "standardize_indirect"), fit)
  null <- null_effect(fit, "median")
  expect_identical(null, stats::median(provider_estimates(fit)))
  expect_identical(expected_outcome(fit, null), rep(stats::plogis(null), 60))
  expect_identical(profile_spec(fit)$family, "toy")
})

test_that("an undeclared capability raises pprof_error_unsupported_inference", {
  fit <- toy_fit(y ~ 1, toy_model_data(), "hospital")
  error <- expect_error(require_capability(fit, "provider_wald"), class = "pprof_error_unsupported_inference")
  expect_identical(error$model_class, "pprof_toy_model")
  expect_identical(error$requested, "provider_wald")
})

test_that("contract generics it does not implement raise pprof_error_unsupported_inference", {
  fit <- toy_fit(y ~ 1, toy_model_data(), "hospital")
  expect_error(provider_estimate_se(fit), class = "pprof_error_unsupported_inference")
  expect_error(provider_test(fit, "exact"), class = "pprof_error_unsupported_inference")
  expect_error(refit_without(fit, "x", toy_model_data()), class = "pprof_error_unsupported_inference")
})

test_that("screening of the data layer carries over to the toy model", {
  fit <- toy_fit(y ~ 1, toy_model_data(), "hospital", min_provider_size = 12)
  expect_identical(fit$n_providers, 3L)
  expect_identical(fit$n_excluded_providers, 2L)
  expect_identical(fit$n_excluded_obs, 21L)
  expect_identical(names(provider_estimates(fit)), sprintf("hospital %d", 3:5))
  expect_identical(expected_outcome(fit, 0), rep(0.5, 39))
})

test_that("the profiling functions work on it unchanged (Phase 3)", {
  fit <- toy_fit(y ~ 1, toy_model_data(), "hospital")
  null <- stats::median(provider_estimates(fit))
  events <- c(3, 5, 2, 8, 6)
  sizes <- 10:14
  # The exact test of each provider's events against plogis(null), as the inference layer
  # computes it.
  tests <- test_providers(fit)
  expected <- vapply(1:5, function(i) {
    infer_exact_poisson_binomial(events[i], rep(stats::plogis(null), sizes[i]), "two.sided")
  }, numeric(2))
  expect_identical(tests$table$provider_id, sprintf("hospital %d", 1:5))
  expect_identical(tests$table$statistic, unname(expected["statistic", ]))
  expect_identical(tests$table$p_value, unname(infer_decide(expected["probability", ], "two.sided", 0.95)$p_value))
  # Indirect standardization: observed over expected events under the null.
  measures <- standardize_providers(fit)
  expect_identical(measures$table$measure, rep("ratio", 5))
  expect_identical(measures$table$observed, events)
  expect_equal(measures$table$expected, sizes * stats::plogis(null), tolerance = 1e-14)
  expect_identical(measures$table$estimate, events / measures$table$expected)
  # Effects without standard errors, which the toy model does not declare.
  effects <- provider_effects(fit)
  expect_identical(effects$table$estimate, unname(provider_estimates(fit)))
  expect_null(effects$table$std_error)
  # The funnel uses the family's precision and half-width, and the modified score test.
  funnel <- funnel_limits(fit)
  expect_identical(funnel$providers$precision, measures$table$expected^2 / measures$table$variance)
  expect_identical(funnel$providers$flag, test_providers(fit, "score")$table$flag)
  profile <- profile_providers(fit)
  expect_identical(profile$tests, tests)
  expect_identical(profile$funnel, funnel)
})

test_that("profiling requests it does not declare raise pprof_error_unsupported_inference", {
  fit <- toy_fit(y ~ 1, toy_model_data(), "hospital")
  expect_error(test_providers(fit, "wald"), class = "pprof_error_unsupported_inference")
  expect_error(test_providers(fit, "bootstrap"), class = "pprof_error_unsupported_inference")
  expect_error(test_providers(fit, "score", score_type = "standard"), class = "pprof_error_unsupported_inference")
  expect_error(provider_effects(fit, "exact"), class = "pprof_error_unsupported_inference")
  expect_error(standardize_providers(fit, "direct"), class = "pprof_error_unsupported_inference")
})

test_that("no file of pprof refers to the toy model", {
  r_dir <- test_path("..", "..", "R")
  skip_if_not(dir.exists(r_dir), "package sources not available")
  sources <- unlist(lapply(list.files(r_dir, pattern = "[.]R$", full.names = TRUE), readLines, warn = FALSE))
  expect_false(any(grepl("toy", sources, fixed = TRUE)))
})
