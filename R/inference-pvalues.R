# P-values and flags of provider tests (K-61, K-63).
#
# Every provider test ends in a probability that the flag rule compares with
# alpha = 1 - level, computed in floating point as the reference computes it (K-61), so
# that 1 - 0.95 is 0.050000000000000044: the upper tail probability for a two-sided test,
# and for a one-sided test the tail in the direction tested. The reference computes that
# probability differently for different tests (the lower tail of the Wald test as 1 minus
# its upper tail, that of the score tests directly), so each test passes its probability
# computed as the reference computes it.

# The two-sided p-value 2 min(p, 1 - p) and the flag 1 (higher than expected) when p is
# below alpha / 2, -1 (lower) when it is above 1 - alpha / 2, and 0 otherwise; one-sided,
# the p-value is the probability, flagged 1 ("greater") or -1 ("less") when below alpha.
# Flags are integers; a missing probability gives a missing p-value and flag.
infer_decide <- function(probability, alternative, level) {
  alpha <- 1 - level
  switch(alternative,
    two.sided = list(
      p_value = 2 * pmin(probability, 1 - probability),
      flag = ifelse(probability < alpha / 2, 1L, ifelse(probability <= 1 - alpha / 2, 0L, -1L))
    ),
    greater = list(p_value = probability, flag = ifelse(probability < alpha, 1L, 0L)),
    less = list(p_value = probability, flag = ifelse(probability < alpha, -1L, 0L))
  )
}

# The tail of a standard normal statistic that a score test compares with alpha (K-65,
# K-66): the upper tail, or the lower tail for alternative = "less"
# (R/test.logis_fe.R:155-165).
infer_normal_tail <- function(statistic, alternative) {
  stats::pnorm(statistic, lower.tail = identical(alternative, "less"))
}
