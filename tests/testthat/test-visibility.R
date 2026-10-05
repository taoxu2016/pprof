# Functions that return a model or a result return it visibly, so that calling one at the
# console prints it, as pprof 1.0.3's functions do (D-51: the constructors returned their
# validators' invisible value). The calls are not wrapped in suppressWarnings() or similar,
# which would make any value visible.
local_strict_mode()

visibility_data <- function() {
  binary <- get(utils::data("ExampleDataBinary", package = "pprof", envir = environment()))
  linear <- get(utils::data("ExampleDataLinear", package = "pprof", envir = environment()))
  list(
    binary = data.frame(y = binary$Y, hospital = binary$ProvID, binary$Z)[binary$ProvID <= 20, ],
    linear = data.frame(y = linear$Y, hospital = linear$ProvID, linear$Z)[linear$ProvID <= 20, ]
  )
}

test_that("the fit functions return their models visibly (D-51)", {
  data <- visibility_data()
  f <- y ~ z1 + z2 + z3
  expect_true(withVisible(fit_logistic_fe(f, data$binary, "hospital"))$visible)
  expect_true(withVisible(fit_logistic_firth(f, data$binary, "hospital"))$visible)
  expect_true(withVisible(fit_linear_fe(f, data$linear, "hospital"))$visible)
  expect_true(withVisible(fit_linear_re(f, data$linear, "hospital"))$visible)
  expect_true(withVisible(fit_logistic_re(f, data$binary, "hospital"))$visible)
  expect_true(withVisible(fit_linear_cre(f, data$linear, "hospital", within_between = "z1"))$visible)
  expect_true(withVisible(fit_logistic_cre(f, data$binary, "hospital", within_between = "z1"))$visible)
})

test_that("the profiling functions, test_coefficients(), and summary() return their results visibly (D-51)", {
  data <- visibility_data()
  fit <- fit_logistic_fe(y ~ z1 + z2 + z3, data$binary, "hospital")
  expect_true(withVisible(provider_effects(fit))$visible)
  expect_true(withVisible(test_providers(fit))$visible)
  expect_true(withVisible(standardize_providers(fit))$visible)
  expect_true(withVisible(profile_providers(fit))$visible)
  expect_true(withVisible(funnel_limits(fit))$visible)
  expect_true(withVisible(test_coefficients(fit))$visible)
  expect_true(withVisible(summary(fit))$visible)
})

test_that("the developer interface returns its objects visibly (D-51)", {
  data <- visibility_data()
  expect_true(withVisible(data_prepare(y ~ 1, data$binary, "hospital", event_counts = TRUE))$visible)
  prepared <- data_prepare(y ~ 1, data$binary, "hospital", event_counts = TRUE)
  providers <- prepared$providers
  effects <- stats::setNames(stats::qlogis((providers$n_events + 0.5) / (providers$n_obs + 1)), providers$provider_id)
  expect_true(withVisible(new_pprof_model(prepared, coefficients = numeric(), vcov = matrix(numeric(), 0L, 0L),
                                          provider_effects = effects,
                                          linear_predictor = rep(0, length(prepared$response)),
                                          spec = list(family = "event rates"), class = "event_rate_model"))$visible)
})
