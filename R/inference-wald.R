# Wald tests and intervals for provider effects (K-67 to K-70, K-90, K-92 to K-94).
#
# The reference distribution is the standard normal, or Student's t with `df` degrees of
# freedom where a family uses it (linear fixed effects, K-68, K-92, D-32). The distribution
# is named rather than encoded as df = Inf, so that the family specification says which one
# applies.

# Wald statistics for provider effects (K-67): (estimate - null) / standard error.
infer_wald_statistic <- function(estimate, null, std_error) {
  (estimate - null) / std_error
}

# The upper tail of a statistic under the normal or t distribution.
infer_upper_tail <- function(statistic, distribution = "normal", df = NULL) {
  if (identical(distribution, "t")) {
    stats::pt(statistic, df = df, lower.tail = FALSE)
  } else {
    stats::pnorm(statistic, lower.tail = FALSE)
  }
}

# The distribution function (lower tail) of the normal or t distribution.
infer_cdf <- function(x, distribution = "normal", df = NULL) {
  if (identical(distribution, "t")) stats::pt(x, df = df) else stats::pnorm(x)
}

# The quantile of the normal or t distribution.
infer_quantile <- function(p, distribution = "normal", df = NULL) {
  if (identical(distribution, "t")) stats::qt(p, df = df) else stats::qnorm(p)
}

# The tail of the Wald statistic that the flag rule compares with alpha (K-67): the upper
# tail, or for alternative = "less" 1 minus the upper tail, as the reference computes it
# (R/test.logis_fe.R:278-292, R/test.linear_fe.R:67-82).
infer_wald_tail <- function(statistic, alternative, distribution = "normal", df = NULL) {
  upper <- infer_upper_tail(statistic, distribution, df)
  if (identical(alternative, "less")) 1 - upper else upper
}

# Wald intervals estimate -/+ critical value * se, with the quantile at 1 - alpha / 2, or
# with the quantile at 1 - alpha on the side tested and an infinite limit on the other
# (K-90, K-92 to K-94).
infer_wald_interval <- function(estimate, std_error, level, alternative, distribution = "normal", df = NULL) {
  alpha <- 1 - level
  if (identical(alternative, "two.sided")) {
    critical <- infer_quantile(1 - alpha / 2, distribution, df)
    return(cbind(lower = estimate - critical * std_error, upper = estimate + critical * std_error))
  }
  critical <- infer_quantile(1 - alpha, distribution, df)
  if (identical(alternative, "greater")) {
    cbind(lower = estimate - critical * std_error, upper = Inf)
  } else {
    cbind(lower = -Inf, upper = estimate + critical * std_error)
  }
}
