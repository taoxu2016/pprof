# Funnel-plot control limits (K-110).
local_strict_mode()

funnel_example <- function() {
  data(ExampleDataBinary, package = "pprof", envir = environment())
  data <- data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID, ExampleDataBinary$Z)
  fit_logistic_fe(y ~ z1 + z2 + z3 + z4 + z5, data, "hospital")
}

test_that("the limits are target -/+ qnorm(1 - alpha / 2) sqrt(1 / precision), at least 0 (K-110)", {
  fit <- funnel_example()
  funnel <- funnel_limits(fit, level = c(0.95, 0.99))
  precision <- sort(unique(funnel$providers$precision))
  for (level in c(0.95, 0.99)) {
    limits <- funnel$table[funnel$table$level == level, ]
    expect_identical(limits$precision, precision)
    half_width <- stats::qnorm(1 - (1 - level) / 2) * sqrt(1 / precision)
    expect_identical(limits$upper, 1 + half_width)
    expect_identical(limits$lower, pmax(1 - half_width, 0))
  }
  shifted <- funnel_limits(fit, target = 1.2)
  expect_equal(shifted$table$upper, funnel$table$upper[funnel$table$level == 0.95] + 0.2, tolerance = 1e-14)
  expect_identical(shifted$target, 1.2)
})

test_that("the points are the indirect ratios at precision E^2 / V, flagged at the first level (K-110)", {
  fit <- funnel_example()
  funnel <- funnel_limits(fit, level = c(0.99, 0.95))
  measures <- standardize_providers(fit, measure = "ratio")$table
  expect_identical(funnel$providers$estimate, measures$estimate)
  expect_identical(funnel$providers$precision, measures$expected^2 / measures$variance)
  expect_identical(funnel$providers$flag, test_providers(fit, "score", level = 0.99)$table$flag)
  expect_identical(funnel[c("measure", "test", "null_value")],
                   list(measure = "ratio", test = "score", null_value = unname(stats::median(fit$provider_effects))))
})

test_that("providers with equal precision share their limits", {
  fit <- funnel_example()
  selected <- c("1", "2", "3")
  one <- funnel_limits(fit, providers = selected)
  expect_identical(nrow(one$table), 3L)
  tied <- profile_funnel_limits(c(2, 2, 5), 0.05, 1, profile_spec(fit)$funnel)
  expect_identical(tied$lower[1], tied$lower[2])
})
