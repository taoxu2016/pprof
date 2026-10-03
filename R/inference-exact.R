# Exact tests of a provider's number of events (K-62, K-64).
#
# Under the null, a provider's events are independent Bernoulli variables with the null
# probabilities, so their number follows a Poisson-binomial distribution. Each function
# returns, for one provider, the probability the flag rule uses (infer_decide()) and the
# statistic the reference reports.

# The exact Poisson-binomial test with poibin's distribution function (K-62): for a
# two-sided test the upper mid-p probability P(O > o) + P(O = o) / 2, for "greater"
# P(O >= o), for "less" P(O <= o), as the reference computes them
# (R/test.logis_fe.R:204-226).
infer_exact_poisson_binomial <- function(observed, probabilities, alternative) {
  if (identical(alternative, "two.sided")) {
    p <- 1 - poibin::ppoibin(observed, probabilities) + 0.5 * poibin::dpoibin(observed, probabilities)
    c(probability = p, statistic = stats::qnorm(p, lower.tail = FALSE))
  } else if (identical(alternative, "greater")) {
    p <- 1 - poibin::ppoibin(observed - 1, probabilities)
    c(probability = p, statistic = stats::qnorm(p, lower.tail = FALSE))
  } else {
    p <- poibin::ppoibin(observed, probabilities)
    c(probability = p, statistic = stats::qnorm(p, lower.tail = TRUE))
  }
}

# The bootstrap version (K-64): n_resamples totals of Bernoulli draws with the null
# probabilities, drawn from the user's random number stream with one rbinom() call laid out
# as the reference lays it out (R/test.logis_fe.R:103-106), so that a seed reproduces the
# reference's draws; the two-sided probability counts ties as one half.
infer_exact_bootstrap <- function(observed, probabilities, alternative, n_resamples) {
  draws <- stats::rbinom(n = length(probabilities) * n_resamples, size = 1,
                         prob = rep(probabilities, times = n_resamples))
  totals <- colSums(matrix(draws, ncol = n_resamples))
  if (identical(alternative, "two.sided")) {
    p <- (sum(totals > observed) + 0.5 * sum(totals == observed)) / n_resamples
    c(probability = p, statistic = stats::qnorm(p, lower.tail = FALSE))
  } else if (identical(alternative, "greater")) {
    p <- sum(totals >= observed) / n_resamples
    c(probability = p, statistic = stats::qnorm(p, lower.tail = FALSE))
  } else {
    p <- sum(totals <= observed) / n_resamples
    c(probability = p, statistic = stats::qnorm(p, lower.tail = TRUE))
  }
}
