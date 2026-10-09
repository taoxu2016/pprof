# The shared model constructor and validator (ARCHITECTURE §D.1, §E.2).
local_strict_mode()

model_data <- function() {
  data.frame(
    y = c(1, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0, 1),
    x = c(0.5, -1.2, 0.3, 2.1, -0.7, 1.4, 0.0, -0.4, 0.9, 1.8, -0.3, 0.6),
    id = rep(c("a", "b", "c"), each = 4)
  )
}

minimal_model <- function(prepared = data_prepare(y ~ x, model_data(), "id"), ...) {
  ids <- prepared$providers$provider_id[prepared$providers$included]
  new_pprof_model(
    prepared,
    coefficients = c(x = 0.4),
    vcov = matrix(0.01, 1, 1, dimnames = list("x", "x")),
    provider_effects = stats::setNames(c(-0.2, 0.1, 0.3)[seq_along(ids)], ids),
    linear_predictor = 0.4 * prepared$design[, "x"],
    spec = list(family = "test"),
    ...
  )
}

test_that("the constructor fills the shared fields from the data layer", {
  prepared <- data_prepare(y ~ x, model_data(), "id")
  fit <- minimal_model(prepared, class = "pprof_test_model", auc = 0.7)
  expect_s3_class(fit, c("pprof_test_model", "pprof_model"), exact = TRUE)
  expect_identical(fit$providers, prepared$providers)
  expect_identical(fit$response, prepared$response)
  expect_identical(fit$provider_index, prepared$provider_index)
  expect_identical(fit$row_index, prepared$row_index)
  expect_identical(fit$n_obs, 12L)
  expect_identical(fit$n_providers, 3L)
  expect_identical(fit$n_excluded_providers, 0L)
  expect_identical(fit$auc, 0.7)
  expect_identical(fit$package_version, utils::packageVersion("pprof"))
  expect_null(fit$data)
  expect_s3_class(minimal_model(prepared, keep_data = TRUE)$data, "pprof_data")
})

test_that("screened-out providers stay in the provider table but have no effects", {
  prepared <- data_prepare(y ~ x, model_data()[-(1:2), ], "id", min_provider_size = 3)
  fit <- minimal_model(prepared)
  expect_identical(fit$providers$included, c(FALSE, TRUE, TRUE))
  expect_identical(names(fit$provider_effects), c("b", "c"))
  expect_identical(fit$n_excluded_providers, 1L)
  expect_identical(fit$n_excluded_obs, 2L)
})

test_that("the constructor rejects inconsistent inputs", {
  prepared <- data_prepare(y ~ x, model_data(), "id")
  invalid <- function(expr) expect_error(expr, class = "pprof_error_invalid_input")
  invalid(new_pprof_model(model_data(), c(x = 1), diag(1), c(a = 0, b = 0, c = 0), rep(0, 12), list(family = "test")))
  invalid(minimal_model(prepared, response = 1))
  invalid(minimal_model(prepared, 3))
  invalid(new_pprof_model(prepared, c(x = 1), diag(1), c(a = 0, b = 0, c = 0), rep(0, 12), list(family = "test")))
  invalid(new_pprof_model(prepared, c(x = 1), matrix(1, 1, 1, dimnames = list("x", "x")), c(c = 0, b = 0, a = 0),
                          rep(0, 12), list(family = "test")))
  invalid(new_pprof_model(prepared, c(x = 1), matrix(1, 1, 1, dimnames = list("x", "x")), c(a = 0, b = 0, c = 0),
                          rep(0, 11), list(family = "test")))
  invalid(new_pprof_model(prepared, c(x = 1), matrix(1, 1, 1, dimnames = list("x", "x")), c(a = 0, b = 0, c = 0),
                          rep(0, 12), list(method = "serbin")))
})

test_that("a model may have no provider effects, which the profiling functions do not report (DEC-102)", {
  prepared <- data_prepare(y ~ x, model_data(), "id")
  fit <- new_pprof_model(prepared, coefficients = c(x = 0.4), vcov = matrix(0.01, 1, 1, dimnames = list("x", "x")),
                         provider_effects = NULL, linear_predictor = 0.4 * prepared$design[, "x"],
                         spec = list(family = "test"), class = "pprof_test_model")
  expect_true("provider_effects" %in% names(fit))
  expect_null(provider_estimates(fit))
  condition <- expect_error(provider_effects(fit), class = "pprof_error_unsupported_inference")
  expect_identical(condition$requested, "provider_effects()")
  # profile_providers() skips the effects and fails at the first step the model does not support.
  condition <- expect_error(profile_providers(fit), class = "pprof_error_unsupported_inference")
  expect_identical(condition$requested, "profile_spec()")
  # A model with provider effects still needs one per included provider.
  expect_error(new_pprof_model(prepared, c(x = 1), matrix(1, 1, 1, dimnames = list("x", "x")), c(a = 0, b = 0),
                               rep(0, 12), list(family = "test")), class = "pprof_error_invalid_input")
})

test_that("the validator rejects objects that are not models", {
  fit <- minimal_model()
  invalid <- function(expr) expect_error(expr, class = "pprof_error_invalid_input")
  invalid(validate_pprof_model(unclass(fit)))
  broken <- fit
  broken$provider_index <- broken$provider_index + 5L
  invalid(validate_pprof_model(broken))
  broken <- fit
  broken$package_version <- "2.0.0"
  invalid(validate_pprof_model(broken))
})
