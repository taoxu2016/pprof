# P-values and flags of provider tests (K-61, K-63).
local_strict_mode()

test_that("two-sided flags compare the upper tail with alpha / 2 and 1 - alpha / 2 (K-63)", {
  alpha <- 1 - 0.95
  probability <- c(0, alpha / 2 - 1e-12, alpha / 2, 0.5, 1 - alpha / 2, 1 - alpha / 2 + 1e-12, 1, NA)
  decided <- infer_decide(probability, "two.sided", 0.95)
  expect_identical(decided$flag, c(1L, 1L, 0L, 0L, 0L, -1L, -1L, NA))
  expect_identical(decided$p_value, 2 * pmin(probability, 1 - probability))
})

test_that("one-sided flags compare the tested tail with alpha (K-63)", {
  alpha <- 1 - 0.9
  probability <- c(alpha - 1e-12, alpha, 0.5)
  greater <- infer_decide(probability, "greater", 0.9)
  expect_identical(greater$flag, c(1L, 0L, 0L))
  expect_identical(greater$p_value, probability)
  less <- infer_decide(probability, "less", 0.9)
  expect_identical(less$flag, c(-1L, 0L, 0L))
})

test_that("flags are integers when every probability is missing", {
  # ifelse() alone returns a logical vector here, which the result objects reject; the Wald
  # tests of a random-effect model whose provider variance is 0 have only missing
  # probabilities (dev/design/phase5-facts/09_singular_re_fits.R).
  for (alternative in c("two.sided", "greater", "less")) {
    expect_identical(infer_decide(c(NaN, NA), alternative, 0.95)$flag, c(NA_integer_, NA_integer_))
  }
})

test_that("alpha is 1 - level in floating point (K-61)", {
  # 1 - 0.95 is 0.050000000000000044, so a tail probability of exactly 0.025 is flagged.
  expect_identical(infer_decide(0.025, "two.sided", 0.95)$flag, 1L)
  expect_identical(infer_decide(0.05, "greater", 0.95)$flag, 1L)
})

test_that("score tests use the upper tail, and the lower tail directly for \"less\" (K-65)", {
  statistic <- c(-2.5, 0.3, 1.96)
  expect_identical(infer_normal_tail(statistic, "two.sided"), stats::pnorm(statistic, lower.tail = FALSE))
  expect_identical(infer_normal_tail(statistic, "greater"), stats::pnorm(statistic, lower.tail = FALSE))
  expect_identical(infer_normal_tail(statistic, "less"), stats::pnorm(statistic))
})
