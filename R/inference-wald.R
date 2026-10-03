# Wald tests and intervals for provider effects (K-67, K-90, K-94).

# Wald statistics for provider effects (K-67): (estimate - null) / standard error.
infer_wald_statistic <- function(estimate, null, std_error) {
  (estimate - null) / std_error
}

# The tail of the Wald statistic that the flag rule compares with alpha (K-67): the upper
# tail, or for alternative = "less" 1 minus the upper tail, as the reference computes it
# (R/test.logis_fe.R:278-292).
infer_wald_tail <- function(statistic, alternative) {
  upper <- stats::pnorm(statistic, lower.tail = FALSE)
  if (identical(alternative, "less")) 1 - upper else upper
}

# Wald intervals estimate -/+ qnorm(1 - alpha / 2) * se, or with qnorm(1 - alpha) on the
# side tested and an infinite limit on the other (K-90, K-94).
infer_wald_interval <- function(estimate, std_error, level, alternative) {
  alpha <- 1 - level
  if (identical(alternative, "two.sided")) {
    critical <- stats::qnorm(1 - alpha / 2)
    return(cbind(lower = estimate - critical * std_error, upper = estimate + critical * std_error))
  }
  critical <- stats::qnorm(1 - alpha)
  if (identical(alternative, "greater")) {
    cbind(lower = estimate - critical * std_error, upper = Inf)
  } else {
    cbind(lower = -Inf, upper = estimate + critical * std_error)
  }
}
