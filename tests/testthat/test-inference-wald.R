# Wald tests and intervals for provider effects (K-67, K-90, K-94).
local_strict_mode()

test_that("Wald statistics divide the distance from the null by the standard error (K-67)", {
  expect_identical(infer_wald_statistic(c(1, -1), 0.5, c(2, 4)), c(0.25, -0.375))
})

test_that("the Wald test's lower tail is 1 minus its upper tail (K-67)", {
  statistic <- c(-2.5, 0.3, 1.96)
  expect_identical(infer_wald_tail(statistic, "two.sided"), stats::pnorm(statistic, lower.tail = FALSE))
  expect_identical(infer_wald_tail(statistic, "greater"), stats::pnorm(statistic, lower.tail = FALSE))
  expect_identical(infer_wald_tail(statistic, "less"), 1 - stats::pnorm(statistic, lower.tail = FALSE))
})

test_that("Wald intervals use qnorm(1 - alpha / 2), or qnorm(1 - alpha) on one side (K-90, K-94)", {
  two_sided <- infer_wald_interval(c(0.5, -1), c(0.1, 0.2), 0.95, "two.sided")
  critical <- stats::qnorm(1 - (1 - 0.95) / 2)
  expect_identical(unname(two_sided[, "lower"]), c(0.5, -1) - critical * c(0.1, 0.2))
  expect_identical(unname(two_sided[, "upper"]), c(0.5, -1) + critical * c(0.1, 0.2))
  greater <- infer_wald_interval(0.5, 0.1, 0.9, "greater")
  expect_identical(unname(greater[, "lower"]), 0.5 - stats::qnorm(1 - (1 - 0.9)) * 0.1)
  expect_identical(unname(greater[, "upper"]), Inf)
  expect_identical(unname(infer_wald_interval(0.5, 0.1, 0.9, "less")[, "lower"]), -Inf)
})
