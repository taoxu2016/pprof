# Poisson tests of a provider's observed count O against its expected count E, their limits, and the
# funnel limits they give (CoxPH Phase C3; K-140 to K-142, K-147, K-149).
#
# These are pprof_py v0.7.0's tests of the standardized ratios of Cox models, under the theoretical
# null (pprof_py/inference/survival/provider_tests.py, inference/survival/inference.py:61-180,
# inference/survival/empirical_null.py:188-207, inference/decision.py:66-101, inference/funnel.py):
# the mid-p test, the default, and the exact test, each turned into a z-statistic whose two-sided
# p-value and sign give the flag. Every function takes the observed and expected counts of the
# providers tested and is vectorized over them. The profiling layer selects these tests for families
# whose specification says `count_distribution = "poisson"` (DEC-108).

# K-141: the mid-p statistic. p_min = 2 F(O; E) - f(O; E) and p_max = 2 (1 - F(O - 1; E)) - f(O; E),
# with 1 - F() computed as written, as pprof_py computes it; the smaller tail, halved and floored at
# midp_probability_floor, gives z = qnorm(p), negated when p_min > p_max (pprof_py's
# poisson_midp_zscore()). |z| is at most 4.7534.
infer_poisson_midp_statistic <- function(observed, expected) {
  probability <- stats::dpois(observed, expected)
  p_min <- 2 * stats::ppois(observed, expected) - probability
  p_max <- 2 * (1 - stats::ppois(observed - 1, expected)) - probability
  z <- stats::qnorm(pmax(midp_probability_floor, pmin(p_min, p_max) / 2))
  ifelse(p_min <= p_max, z, -z)
}

# K-140: the exact test's statistic. The two-sided p-value is 2 P(X >= O) when O / E > 1 and
# 2 P(X <= O) otherwise, X ~ Poisson(E), each tail computed as such and capped at exact_poisson_cap;
# z = sign(O - E) qnorm(p / 2, lower.tail = FALSE), infinite when p underflows to 0 (D-71), and 0
# when O = E. A provider with E = 0 (and so O = 0, K-147) has an undefined ratio, which pprof_py
# treats as O / E <= 1.
infer_poisson_exact_statistic <- function(observed, expected) {
  ratio <- observed / expected
  high <- !is.na(ratio) & ratio > 1
  p <- ifelse(high, 2 * stats::ppois(observed - 1, expected, lower.tail = FALSE), 2 * stats::ppois(observed, expected))
  sign(observed - expected) * stats::qnorm(pmin(exact_poisson_cap, p) / 2, lower.tail = FALSE)
}

# K-140, K-141: the two-sided p-value of a statistic under the theoretical null, 2 (1 - Phi(|z|))
# computed as an upper tail, as pprof_py's p_values() computes it: 0 for an infinite statistic.
infer_poisson_p_value <- function(statistic) {
  2 * stats::pnorm(abs(statistic), lower.tail = FALSE)
}

# K-142: 1 when p < alpha and z > 0, -1 when p < alpha and z < 0, and 0 otherwise, with
# alpha = 1 - level computed in floating point (K-61); the inequality is strict.
infer_poisson_flag <- function(statistic, p_value, level) {
  alpha <- 1 - level
  significant <- p_value < alpha
  flag <- ifelse(significant & statistic > 0, 1L, ifelse(significant & statistic < 0, -1L, 0L))
  storage.mode(flag) <- "integer"
  flag
}

# The statistic, p-value, and flag of each provider for the "midp" or "exact" test.
infer_poisson_test <- function(observed, expected, test, level) {
  statistic <- infer_poisson_statistic(observed, expected, test)
  p_value <- infer_poisson_p_value(statistic)
  list(statistic = statistic, p_value = p_value, flag = infer_poisson_flag(statistic, p_value, level))
}

infer_poisson_statistic <- function(observed, expected, test) {
  switch(test,
    midp = infer_poisson_midp_statistic(observed, expected),
    exact = infer_poisson_exact_statistic(observed, expected),
    abort_invalid_input(sprintf("No Poisson test \"%s\".", test), arg = "test")
  )
}

# K-140: the exact test's limits for the ratio O / E. Garwood's when E < byar_expected_threshold:
# qchisq(alpha / 2, 2 O) / 2 / E (0 when O = 0) and qchisq(1 - alpha / 2, 2 (O + 1)) / 2 / E, in
# pprof_py's order of operations; Byar's otherwise, with z = qnorm(1 - alpha / 2):
# (O / E) (1 - 1 / (9 O) - z / (3 sqrt(O)))^3 (0 when O = 0) and
# ((O + 1) / E) (1 - 1 / (9 (O + 1)) + z / (3 sqrt(O + 1)))^3. The limits are chosen by E, not O,
# so they can disagree with the test at the boundary, and Byar's lower limit can be negative at
# high levels, as in pprof_py. A matrix with columns lower and upper.
infer_poisson_exact_limits <- function(observed, expected, level) {
  alpha <- 1 - level
  critical <- stats::qnorm(1 - alpha / 2)
  garwood <- expected < byar_expected_threshold
  some <- observed > 0
  lower <- numeric(length(observed))
  upper <- numeric(length(observed))
  g <- garwood & some
  lower[g] <- stats::qchisq(alpha / 2, 2 * observed[g]) / 2 / expected[g]
  upper[garwood] <- stats::qchisq(1 - alpha / 2, 2 * (observed[garwood] + 1)) / 2 / expected[garwood]
  b <- !garwood & some
  lower[b] <- (observed[b] / expected[b]) * (1 - 1 / (9 * observed[b]) - critical / (3 * sqrt(observed[b])))^3
  next_count <- observed[!garwood] + 1
  upper[!garwood] <- (next_count / expected[!garwood]) *
    (1 - 1 / (9 * next_count) + critical / (3 * sqrt(next_count)))^3
  cbind(lower = lower, upper = upper)
}

# K-141: the mid-p limits for the ratio O / E (decision 5 of the CoxPH C3 plan, DEC-110). On the scale
# of the Poisson mean t, the calibrated p-value 2 Phi-bar(|z(O, t)|) rises from 2e-6 to 1 as t grows
# to the root of z(O, t), and falls on the other side, so the limits are the two roots of
# 2 Phi-bar(|z(O, t)|) = alpha. They depend on O alone: pprof_py's bracket and Brent tolerances only
# set how precisely it finds them (within 1e-10 max(E, 1)). They are found once per distinct O, to
# rounding, by bisection over all the distinct counts at once, then divided by E; pprof_py's
# decisions of 0 for the lower limit and Inf for the upper, where its equation is not negative at the
# ends of its bracket for that provider, are kept. With E = 0 the limits are NaN and Inf (K-147). A
# matrix with columns lower and upper.
infer_poisson_midp_limits <- function(observed, expected, level) {
  alpha <- 1 - level
  counts <- sort(unique(observed))
  roots <- infer_poisson_midp_roots(counts, alpha)
  at <- match(observed, counts)
  lower <- roots[1L, at]
  upper <- roots[2L, at]
  lower[infer_poisson_midp_excess(observed, midp_bracket_low * pmax(expected, 1), alpha) >= 0] <- 0
  upper[infer_poisson_midp_excess(observed, infer_poisson_midp_bracket_high(observed, expected), alpha) >= 0] <- Inf
  cbind(lower = lower / expected, upper = upper / expected)
}

# The equation of the mid-p limits: the calibrated p-value at the Poisson mean t, less alpha.
infer_poisson_midp_excess <- function(observed, mean, alpha) {
  infer_poisson_p_value(infer_poisson_midp_statistic(observed, mean)) - alpha
}

# The upper end of pprof_py's bracket for each provider: 10 (O + E + 10), multiplied by 10 while the
# statistic there exceeds max(null mean, midp_bracket_threshold), 0 under the theoretical null, and
# the end is below midp_bracket_max (provider_tests.py:43-45).
infer_poisson_midp_bracket_high <- function(observed, expected) {
  high <- midp_bracket_scale * (observed + expected + midp_bracket_scale)
  threshold <- max(0, midp_bracket_threshold)
  repeat {
    grow <- infer_poisson_midp_statistic(observed, high) > threshold & high < midp_bracket_max
    if (!any(grow)) return(high)
    high[grow] <- high[grow] * midp_bracket_scale
  }
}

# The two roots in the Poisson mean of the mid-p limits' equation for each count in `counts`, to
# rounding (DEC-110): as the mean grows, the statistic falls from 4.75 to -4.75, so the equation rises
# to 1 - alpha at the statistic's root and falls beyond it. Bisection over all the counts at once
# finds the statistic's root between the smallest positive mean and the end of pprof_py's bracket,
# then the lower root of the equation below it and the upper root above it. A side with no sign
# change has the lower limit 0 (O = 0) or the upper Inf (when alpha is at most the p-value floor's
# 2e-6). A matrix with rows lower and upper and a column per count.
infer_poisson_midp_roots <- function(counts, alpha) {
  k <- length(counts)
  low <- rep(.Machine$double.xmin, k)
  high <- infer_poisson_midp_bracket_high(counts, numeric(k))
  statistic <- function(i, mean) infer_poisson_midp_statistic(counts[i], mean)
  excess <- function(i, mean) infer_poisson_midp_excess(counts[i], mean, alpha)
  middle <- low
  split <- which(statistic(seq_len(k), low) > 0)
  middle[split] <- infer_poisson_bisect(function(i, mean) statistic(split[i], mean), low[split], high[split])
  lower <- numeric(k)
  upper <- rep(Inf, k)
  left <- which(excess(seq_len(k), low) < 0)
  lower[left] <- infer_poisson_bisect(function(i, mean) excess(left[i], mean), low[left], middle[left])
  right <- which(excess(seq_len(k), high) < 0)
  upper[right] <- infer_poisson_bisect(function(i, mean) excess(right[i], mean), middle[right], high[right])
  rbind(lower = lower, upper = upper)
}

# For each i, a root of f(i, x) between lower[i] and upper[i], where f has opposite signs or is 0 at an
# end; f(i, x) evaluates the functions numbered i at the points x, both vectors. Bisection until no
# double lies strictly between the ends, then the end where |f| is smaller (the lower one on a tie).
infer_poisson_bisect <- function(f, lower, upper) {
  if (length(lower) == 0L) return(numeric())
  sign_lower <- sign(f(seq_along(lower), lower))
  active <- which(sign_lower != 0 & sign(f(seq_along(upper), upper)) != 0)
  upper[sign_lower == 0] <- lower[sign_lower == 0]
  while (length(active)) {
    middle <- lower[active] + (upper[active] - lower[active]) / 2
    open <- middle > lower[active] & middle < upper[active]
    active <- active[open]
    middle <- middle[open]
    if (length(active) == 0L) break
    side <- sign(f(active, middle))
    # The root is above the middle where f keeps its sign at the lower end, below it otherwise, and at
    # it where f is 0.
    same <- side == sign_lower[active]
    lower[active[same | side == 0]] <- middle[same | side == 0]
    upper[active[!same]] <- middle[!same]
    active <- active[side != 0]
  }
  ifelse(abs(f(seq_along(lower), lower)) <= abs(f(seq_along(upper), upper)), lower, upper)
}

# K-149: the funnel limits at each expected count E > 0 in `expected`, for one level: the largest
# count the test flags low (o_lo) and the smallest it flags high (o_hi) among 0, ..., n with
# n = ceiling(E + funnel_count_spread sqrt(E) + funnel_count_margin), found by bisection over the
# counts as pprof_py's _bisect() finds them (the flags are monotone in the count), and the limits
# (o_lo + 1/2) / E and (o_hi - 1/2) / E on the ratio scale, -Inf and Inf where no count is flagged
# (pprof_py's poisson_funnel_limits() and its curves). A provider lies outside its limits exactly when
# the test flags it. A matrix with columns lower and upper.
infer_poisson_funnel_limits <- function(expected, test, level) {
  top <- ceiling(expected + funnel_count_spread * sqrt(expected) + funnel_count_margin)
  flag_at <- function(count, k) {
    statistic <- infer_poisson_statistic(count, expected[k], test)
    infer_poisson_flag(statistic, infer_poisson_p_value(statistic), level)
  }
  # target 1: the smallest count flagged high, top + 1 when none; target -1: the largest flagged
  # low, -1 when none.
  boundary <- function(target) {
    low <- rep(-1, length(expected))
    high <- top + 1
    active <- which(high - low > 1)
    while (length(active)) {
      middle <- (low[active] + high[active]) %/% 2
      hit <- flag_at(middle, active) == target
      if (target == 1L) {
        high[active[hit]] <- middle[hit]
        low[active[!hit]] <- middle[!hit]
      } else {
        low[active[hit]] <- middle[hit]
        high[active[!hit]] <- middle[!hit]
      }
      active <- active[high[active] - low[active] > 1]
    }
    if (target == 1L) high else low
  }
  count_high <- boundary(1L)
  count_low <- boundary(-1L)
  cbind(lower = ifelse(count_low >= 0, (count_low + funnel_count_offset) / expected, -Inf),
        upper = ifelse(count_high <= top, (count_high - funnel_count_offset) / expected, Inf))
}
