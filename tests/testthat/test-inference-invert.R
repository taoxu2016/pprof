# Intervals for provider effects (K-90): brackets, roots, and the interval equations.
local_strict_mode()

test_that("roots are searched in the reference's brackets, in order (K-90)", {
  expect_identical(infer_brackets_above(1.5), list(c(1.5, 6.5), c(6.5, 11.5), c(11.5, 16.5)))
  expect_identical(infer_brackets_below(1.5), list(c(-3.5, 1.5), c(-8.5, -3.5), c(-13.5, -8.5)))
  expect_identical(infer_brackets_extreme(c(-2, 0.5, 1)), list(c(-12, 12), c(-24, 24), c(-36, 36)))
  # A root in the second bracket is found there; without a root, `none`.
  expect_equal(infer_root(function(x) x - 8, infer_brackets_above(0), Inf), 8, tolerance = 1e-4)
  expect_identical(infer_root(function(x) x^2 + 1, infer_brackets_above(0), Inf), Inf)
})

test_that("uniroot() runs at its default settings, as in the reference", {
  f <- function(x) stats::pnorm(x) - 0.3
  expect_identical(infer_root(f, list(c(-5, 5)), NA_real_), stats::uniroot(f, c(-5, 5))$root)
})

test_that("score limits solve the score statistic for -/+ the normal quantile (K-90)", {
  withr::with_seed(5, linear_predictor <- stats::rnorm(40, 0, 0.7))
  observed <- 13
  limits <- infer_effect_interval("finite", -0.4, observed, linear_predictor, "score", 0.95, "two.sided")
  statistic <- function(gamma) {
    p <- stats::plogis(gamma + linear_predictor)
    (observed - sum(p)) / sqrt(sum(p * (1 - p)))
  }
  z <- stats::qnorm(0.025, lower.tail = FALSE)
  expect_equal(statistic(limits[1]), z, tolerance = 1e-3)
  expect_equal(statistic(limits[2]), -z, tolerance = 1e-3)
  expect_identical(infer_effect_interval("finite", -0.4, observed, linear_predictor, "score", 0.95, "greater")[2], Inf)
  expect_identical(infer_effect_interval("finite", -0.4, observed, linear_predictor, "score", 0.95, "less")[1], -Inf)
})

test_that("exact limits solve the mid-p tails for alpha / 2 (K-90)", {
  withr::with_seed(6, linear_predictor <- stats::rnorm(30, 0, 0.5))
  observed <- 9
  limits <- infer_effect_interval("finite", -0.8, observed, linear_predictor, "exact", 0.95, "two.sided")
  upper_tail <- function(gamma) {
    p <- stats::plogis(gamma + linear_predictor)
    1 - poibin::ppoibin(observed, p) + 0.5 * poibin::dpoibin(observed, p)
  }
  expect_equal(upper_tail(limits[1]), 0.025, tolerance = 1e-3)
  expect_equal(1 - upper_tail(limits[2]), 0.025, tolerance = 1e-3)
})

test_that("providers with no events get only an upper limit and those with only events only a lower one (K-90)", {
  withr::with_seed(7, linear_predictor <- stats::rnorm(20, 0, 0.5))
  for (test in c("exact", "score")) {
    none <- infer_effect_interval("no_events", -10, 0, linear_predictor, test, 0.95, "two.sided")
    expect_identical(none[1], -Inf)
    expect_true(is.finite(none[2]))
    all <- infer_effect_interval("all_events", 10, 20, linear_predictor, test, 0.95, "two.sided")
    expect_true(is.finite(all[1]))
    expect_identical(all[2], Inf)
  }
  # The exact limit of a provider with no events solves prod(1 - p) / 2 = alpha (question M-15).
  upper <- infer_effect_interval("no_events", -10, 0, linear_predictor, "exact", 0.95, "two.sided")[2]
  expect_equal(prod(stats::plogis(-upper - linear_predictor)) / 2, 1 - 0.95, tolerance = 1e-3)
})
