# Shared methods of the model contract and the capability check (ARCHITECTURE §E.1, §E.3).
local_strict_mode()

contract_model <- function() {
  d <- data.frame(y = c(1, 0, 1, 0, 1, 1), x = c(1, 2, 3, 4, 5, 6), id = c(2, 2, 2, 1, 1, 1))
  prepared <- data_prepare(y ~ x, d, "id")
  new_pprof_model(prepared, coefficients = c(x = 0.2), vcov = matrix(0.1, 1, 1, dimnames = list("x", "x")),
                  provider_effects = c(`1` = -0.5, `2` = 0.5), linear_predictor = 0.2 * prepared$design[, "x"],
                  spec = list(family = "test"), class = "pprof_contract_test")
}

test_that("accessors read the shared fields", {
  fit <- contract_model()
  expect_identical(provider_table(fit), fit$providers)
  expect_identical(provider_estimates(fit), c(`1` = -0.5, `2` = 0.5))
  expect_identical(provider_index(fit), c(1L, 1L, 1L, 2L, 2L, 2L))
  expect_identical(observed_outcome(fit), c(0, 1, 1, 1, 0, 1))
  expect_identical(linear_predictor(fit), 0.2 * c(4, 5, 6, 1, 2, 3))
})

test_that("a model declares no capabilities unless it says so", {
  fit <- contract_model()
  expect_identical(inference_capabilities(fit), character())
  for (capability in capability_names) {
    expect_error(require_capability(fit, capability), class = "pprof_error_unsupported_inference")
  }
})

test_that("generics without a shared method raise pprof_error_unsupported_inference", {
  fit <- contract_model()
  unsupported <- function(expr) expect_error(expr, class = "pprof_error_unsupported_inference")
  unsupported(expected_outcome(fit, 0))
  unsupported(null_effect(fit, "median"))
  unsupported(profile_spec(fit))
  unsupported(provider_estimate_se(fit))
  unsupported(provider_test(fit, "exact"))
  unsupported(refit_without(fit, "x", data.frame()))
})

test_that("the generics reject objects that are not models", {
  invalid <- function(expr) expect_error(expr, class = "pprof_error_invalid_input")
  not_a_model <- lm(dist ~ speed, data = cars)
  invalid(provider_table(not_a_model))
  invalid(provider_estimates(not_a_model))
  invalid(provider_index(not_a_model))
  invalid(linear_predictor(not_a_model))
  invalid(observed_outcome(not_a_model))
  invalid(inference_capabilities(not_a_model))
  invalid(expected_outcome(not_a_model, 0))
  invalid(null_effect(not_a_model, 0))
  invalid(profile_spec(not_a_model))
  invalid(provider_estimate_se(not_a_model))
  invalid(provider_test(not_a_model, "exact"))
  invalid(refit_without(not_a_model, "x", cars))
})

test_that("a capability list that is not character is rejected", {
  fit <- contract_model()
  .S3method("inference_capabilities", "pprof_contract_test_bad", function(model) 1)
  class(fit) <- c("pprof_contract_test_bad", "pprof_model")
  expect_error(require_capability(fit, "funnel"), class = "pprof_error_invalid_input")
})
