# The Poisson tests of Cox models and their limits (R/inference-poisson.R; K-140 to K-142, K-147,
# K-149; the CoxPH brief's §6 C: against ppois() and poisson.test() where they coincide, and limits
# against their defining equations). Their agreement with pprof_py v0.7.0 is tested on the Cox
# fixtures (test-cox-reference.R).
local_strict_mode()

closed_form <- reference_tolerance("closed_form")
within_closed_form <- function(a, b) all(abs(a - b) <= closed_form$atol + closed_form$rtol * abs(b))

test_that("the mid-p statistic follows K-141: the smaller tail, floored, and signed", {
  observed <- c(0, 0, 1, 5, 5, 12, 40, 3)
  expected <- c(0, 30, 0.2, 5, 9.5, 4, 25, 3.2)
  z <- infer_poisson_midp_statistic(observed, expected)
  p_min <- 2 * ppois(observed, expected) - dpois(observed, expected)
  p_max <- 2 * (1 - ppois(observed - 1, expected)) - dpois(observed, expected)
  by_hand <- qnorm(pmax(1e-6, pmin(p_min, p_max) / 2)) * ifelse(p_min <= p_max, 1, -1)
  expect_identical(z, by_hand)
  # O = E = 0 gives 0; O = E = 5 does not (K-141); a provider far below or above its expected count
  # reaches the floor, |z| = 4.7534 (p = 2e-6).
  expect_identical(z[1], 0)
  expect_equal(z[4], 0.0708, tolerance = 1e-3)
  expect_identical(z[2], qnorm(1e-6))
  expect_identical(abs(infer_poisson_midp_statistic(80, 10)), -qnorm(1e-6))
  expect_true(all(abs(z) <= -qnorm(1e-6)))
  expect_true(z[6] > 0 && z[2] < 0 && z[7] > 0 && z[5] < 0)
})

test_that("the exact statistic follows K-140, with poisson.test()'s one-sided tails doubled", {
  observed <- c(8, 2, 12, 0, 30)
  expected <- c(3.5, 6.1, 10, 4.2, 18.7)
  z <- infer_poisson_exact_statistic(observed, expected)
  one_sided <- vapply(seq_along(observed), function(i) {
    alternative <- if (observed[i] / expected[i] > 1) "greater" else "less"
    stats::poisson.test(observed[i], expected[i], alternative = alternative)$p.value
  }, numeric(1))
  expect_identical(z, sign(observed - expected) * qnorm(pmin(0.999, 2 * one_sided) / 2, lower.tail = FALSE))
  expect_identical(infer_poisson_p_value(z), 2 * pnorm(abs(z), lower.tail = FALSE))
  # The cap: O = E always reaches it, and its reported p-value is 1 (K-140).
  expect_identical(infer_poisson_exact_statistic(5, 5), 0)
  expect_identical(infer_poisson_p_value(infer_poisson_exact_statistic(5, 5)), 1)
  capped <- infer_poisson_exact_statistic(10, 9.9)
  expect_identical(capped, qnorm(0.999 / 2, lower.tail = FALSE))
  # E = 0 (and so O = 0) is not above 1, so the lower tail: p = 0.999, z = 0 (K-147).
  expect_identical(infer_poisson_exact_statistic(0, 0), 0)
})

test_that("an exact p-value that underflows gives an infinite statistic, p-value 0, and a flag (D-71)", {
  test <- infer_poisson_test(c(1000, 0), c(10, 2000), "exact", 0.95)
  expect_identical(test$statistic, c(Inf, -Inf))
  expect_identical(test$p_value, c(0, 0))
  expect_identical(test$flag, c(1L, -1L))
})

test_that("flags follow K-142: a strict inequality on the p-value and the sign of the statistic", {
  alpha <- 1 - 0.95
  expect_identical(infer_poisson_flag(c(2, -2, 2, 0.1, -3), c(alpha / 2, alpha / 2, alpha, 0.9, 0.0027), 0.95),
                   c(1L, -1L, 0L, 0L, -1L))
  expect_type(infer_poisson_flag(numeric(), numeric(), 0.95), "integer")
  test <- infer_poisson_test(c(30, 2, 10), c(15, 9, 10), "midp", 0.95)
  expect_identical(test$flag, infer_poisson_flag(test$statistic, test$p_value, 0.95))
  expect_identical(test$flag, c(1L, -1L, 0L))
})

test_that("the exact limits are Garwood's below an expected count of 100 and Byar's from 100 (K-140)", {
  level <- 0.95
  alpha <- 1 - level
  observed <- c(0, 3, 17, 0, 120, 95)
  expected <- c(2.5, 4.1, 99.9, 150, 100, 130)
  limits <- infer_poisson_exact_limits(observed, expected, level)
  # Garwood's limits are poisson.test()'s interval for the rate, with the expected count as the time.
  for (i in 1:3) {
    interval <- stats::poisson.test(observed[i], expected[i], conf.level = level)$conf.int
    expect_true(within_closed_form(limits[i, ], as.numeric(interval)))
  }
  z <- qnorm(1 - alpha / 2)
  byar <- function(o, e) {
    c(if (o > 0) (o / e) * (1 - 1 / (9 * o) - z / (3 * sqrt(o)))^3 else 0,
      ((o + 1) / e) * (1 - 1 / (9 * (o + 1)) + z / (3 * sqrt(o + 1)))^3)
  }
  for (i in 4:6) expect_identical(unname(limits[i, ]), byar(observed[i], expected[i]))
  expect_identical(limits[c(1, 4), "lower"], c(0, 0))
  # With no expected events the ratio's limits are 0 and Inf (K-147).
  expect_identical(unname(infer_poisson_exact_limits(0, 0, level)[1, ]), c(0, Inf))
})

test_that("the mid-p limits solve their equation, on each side of the statistic's root (K-141)", {
  level <- 0.95
  alpha <- 1 - level
  observed <- c(0, 1, 4, 25, 4)
  expected <- c(3, 0.16, 7.5, 18.2, 2)
  limits <- infer_poisson_midp_limits(observed, expected, level)
  mean_lower <- limits[, "lower"] * expected
  mean_upper <- limits[, "upper"] * expected
  excess <- function(o, t) 2 * pnorm(abs(infer_poisson_midp_statistic(o, t)), lower.tail = FALSE) - alpha
  # O = 0 has lower limit 0; every other limit is a root, the equation changing sign across it.
  expect_identical(mean_lower[1], 0)
  for (i in seq_along(observed)) {
    if (mean_lower[i] > 0) {
      expect_lt(abs(excess(observed[i], mean_lower[i])), 1e-12)
      expect_lt(excess(observed[i], mean_lower[i] * (1 - 1e-9)), 0)
      expect_gt(excess(observed[i], mean_lower[i] * (1 + 1e-9)), 0)
    }
    expect_lt(abs(excess(observed[i], mean_upper[i])), 1e-12)
    expect_gt(excess(observed[i], mean_upper[i] * (1 - 1e-9)), 0)
    expect_lt(excess(observed[i], mean_upper[i] * (1 + 1e-9)), 0)
    expect_lt(mean_lower[i], observed[i] + 1)
  }
  # On the scale of the Poisson mean the limits depend on O alone: the same roots, divided by each E.
  roots <- infer_poisson_midp_roots(4, alpha)
  expect_identical(unname(limits[c(3, 5), ]), cbind(roots[1] / expected[c(3, 5)], roots[2] / expected[c(3, 5)]))
  # The limits invert the test: a provider is flagged exactly when its interval excludes the ratio 1.
  test <- infer_poisson_test(observed, expected, "midp", level)
  expect_identical(test$flag != 0L, limits[, "lower"] > 1 | limits[, "upper"] < 1)
})

test_that("the mid-p roots of several counts are those of each count alone (DEC-110)", {
  counts <- c(0, 1, 4, 25, 380, 2500)
  together <- infer_poisson_midp_roots(counts, 0.05)
  alone <- vapply(counts, function(count) infer_poisson_midp_roots(count, 0.05)[, 1], numeric(2))
  expect_identical(unname(together), unname(alone))
  # O = 0 has the lower limit 0.
  expect_identical(unname(together["lower", 1]), 0)
})

test_that("the mid-p limits of a provider without expected events are NaN and Inf (K-147)", {
  limits <- infer_poisson_midp_limits(c(0, 2), c(0, 1.5), 0.95)
  expect_identical(unname(limits[1, ]), c(NaN, Inf))
  expect_true(all(is.finite(limits[2, ])))
})

test_that("the mid-p limits keep pprof_py's 0 and Inf at the ends of its bracket", {
  # With alpha at most the floor's 2e-6 the equation is never negative, so pprof_py's limits are 0 and
  # Inf for every provider.
  limits <- infer_poisson_midp_limits(c(0, 3, 40), c(1, 2.5, 30), 1 - 1e-6)
  expect_identical(unname(limits[, "lower"]), c(0, 0, 0))
  expect_identical(unname(limits[, "upper"]), c(Inf, Inf, Inf))
  # pprof_py's bracket ends: 1e-10 max(E, 1), and 10 (O + E + 10) grown tenfold while z > 0.
  expect_identical(infer_poisson_midp_bracket_high(c(3, 0), c(2.5, 0)), c(155, 100))
})

test_that("the funnel limits are the count boundaries of the test, half-way between counts (K-149)", {
  level <- 0.95
  expected <- c(0.4, 3, 12.5, 47, 160)
  limits <- infer_poisson_funnel_limits(expected, "midp", level)
  # By brute force: every count from 0 to the search's end, flagged by the test.
  for (i in seq_along(expected)) {
    top <- ceiling(expected[i] + 40 * sqrt(expected[i]) + 50)
    counts <- 0:top
    flag <- infer_poisson_test(counts, rep(expected[i], length(counts)), "midp", level)$flag
    high <- if (any(flag == 1L)) min(counts[flag == 1L]) else NA
    low <- if (any(flag == -1L)) max(counts[flag == -1L]) else NA
    expect_identical(unname(limits[i, "upper"]), if (is.na(high)) Inf else (high - 0.5) / expected[i])
    expect_identical(unname(limits[i, "lower"]), if (is.na(low)) -Inf else (low + 0.5) / expected[i])
    # A count lies outside the limits exactly when it is flagged.
    ratio <- counts / expected[i]
    expect_identical(flag != 0L, ratio < limits[i, "lower"] | ratio > limits[i, "upper"])
  }
  # Small expected counts: no count is flagged low, so the lower limit is -Inf.
  expect_identical(unname(limits[1, "lower"]), -Inf)
  exact <- infer_poisson_funnel_limits(expected, "exact", level)
  expect_true(all(exact[, "upper"] >= limits[, "upper"]))
})
