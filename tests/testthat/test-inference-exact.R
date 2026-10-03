# Exact and bootstrap tests of a provider's number of events (K-62, K-64), and the modified
# score statistics (K-65).
local_strict_mode()

# The Poisson-binomial distribution by direct convolution: P(O = k), k = 0, ..., n.
convolution_pmf <- function(probabilities) {
  Reduce(function(pmf, p) c(pmf * (1 - p), 0) + c(0, pmf * p), probabilities, 1)
}

test_that("the exact test's tail probabilities match direct convolution (K-62)", {
  probabilities <- c(0.05, 0.3, 0.42, 0.18, 0.77, 0.61, 0.09, 0.5)
  pmf <- convolution_pmf(probabilities)
  # poibin computes the distribution by a discrete Fourier transform, whose errors are
  # absolute (about 1e-16 here), so small tails are compared at the probability tier.
  for (observed in 0:8) {
    k <- observed + 1
    above <- sum(pmf[seq_along(pmf) > k])
    two_sided <- infer_exact_poisson_binomial(observed, probabilities, "two.sided")
    expect_reference_value(two_sided[["probability"]], above + pmf[k] / 2, "probability", "two-sided tail")
    expect_identical(two_sided[["statistic"]], stats::qnorm(two_sided[["probability"]], lower.tail = FALSE))
    greater <- infer_exact_poisson_binomial(observed, probabilities, "greater")
    expect_reference_value(greater[["probability"]], above + pmf[k], "probability", "upper tail")
    less <- infer_exact_poisson_binomial(observed, probabilities, "less")
    expect_reference_value(less[["probability"]], sum(pmf[seq_len(k)]), "probability", "lower tail")
    expect_identical(less[["statistic"]], stats::qnorm(less[["probability"]]))
  }
  expect_identical(infer_exact_poisson_binomial(0, probabilities, "greater")[["probability"]], 1)
})

test_that("the bootstrap test draws one block of Bernoulli variables in the reference's layout (K-64)", {
  probabilities <- c(0.2, 0.7, 0.4)
  withr::with_seed(20261002, {
    result <- infer_exact_bootstrap(2, probabilities, "two.sided", 50)
    after <- stats::runif(1)
  })
  withr::with_seed(20261002, {
    totals <- colSums(matrix(stats::rbinom(150, 1, rep(probabilities, times = 50)), ncol = 50))
    expected_after <- stats::runif(1)
  })
  expect_identical(result[["probability"]], (sum(totals > 2) + 0.5 * sum(totals == 2)) / 50)
  expect_identical(after, expected_after)
  withr::with_seed(1, greater <- infer_exact_bootstrap(2, probabilities, "greater", 50))
  withr::with_seed(1, less <- infer_exact_bootstrap(2, probabilities, "less", 50))
  withr::with_seed(1, totals <- colSums(matrix(stats::rbinom(150, 1, rep(probabilities, times = 50)), ncol = 50)))
  expect_identical(greater[["probability"]], sum(totals >= 2) / 50)
  expect_identical(less[["probability"]], sum(totals <= 2) / 50)
})

test_that("null probabilities are clamped to [1e-10, 1 - 1e-10] (K-62)", {
  expect_identical(infer_clamp_probabilities(c(0, 1e-12, 0.3, 1)), c(1e-10, 1e-10, 0.3, 1 - 1e-10))
})

test_that("modified score statistics sum each provider's residuals in the reference's order (K-65)", {
  response <- c(1, 0, 0, 1, 1, 0, 1)
  probabilities <- c(0.2, 0.3, 0.6, 0.5, 0.9, 0.1, 0.4)
  index <- c(1L, 1L, 1L, 3L, 3L, 4L, 4L)
  expected <- vapply(list(1:3, 4:5, 6:7), function(rows) {
    sum(response[rows] - probabilities[rows]) / sqrt(sum(probabilities[rows] * (1 - probabilities[rows])))
  }, numeric(1))
  expect_identical(infer_score_modified(response, probabilities, index, c(1L, 3L, 4L)), expected)
})
