# Intervals for provider effects (K-90): inversion of the exact and score tests with
# uniroot() in the reference's brackets. Wald intervals are in inference-wald.R.

# The root of f in the first of `brackets` in which uniroot() finds one, or `none`. The
# reference tries each bracket with try(uniroot(...)) and moves on when uniroot() fails,
# for example because f has the same sign at both ends (R/confint.logis_fe.R:131-150).
# uniroot() runs at the settings the reference uses, its defaults.
infer_root <- function(f, brackets, none) {
  for (bracket in brackets) {
    root <- tryCatch(stats::uniroot(f, bracket, tol = root_tolerance, maxiter = root_max_iter)$root,
                     error = function(error) NULL)
    if (!is.null(root)) return(root)
  }
  none
}

# The brackets for an upper limit, estimate + width * (k, k + 1), and for a lower limit,
# estimate - width * (k + 1, k), for k = 0, 1, 2 (R/confint.logis_fe.R:132, :143).
infer_brackets_above <- function(estimate) {
  lapply(seq_len(root_bracket_attempts) - 1L, function(k) estimate + root_bracket_width * c(k, k + 1L))
}

infer_brackets_below <- function(estimate) {
  lapply(seq_len(root_bracket_attempts) - 1L, function(k) estimate - root_bracket_width * c(k + 1L, k))
}

# The brackets for the single limit of a provider with no events or only events,
# (extreme_bracket_base + max |linear predictor|) * (-k, k) for k = 1, 2, 3
# (R/confint.logis_fe.R:159, :168).
infer_brackets_extreme <- function(linear_predictor) {
  width <- extreme_bracket_base + max(abs(linear_predictor))
  lapply(seq_len(root_bracket_attempts), function(k) width * c(-k, k))
}

# The exact or score interval of one provider's effect at the given level (K-90), from its
# estimate, its number of events, and its observations' covariate linear predictors.
# `kind` is "finite" for providers with both outcomes, "no_events", or "all_events". A
# provider with no events gets only an upper limit and one with only events only a lower
# limit, each solving its equation at alpha rather than alpha / 2, as in the reference
# (question M-15). A limit with no root in any bracket is infinite.
infer_effect_interval <- function(kind, estimate, observed, linear_predictor, test, level, alternative) {
  alpha <- 1 - level
  if (identical(kind, "no_events")) {
    f <- if (identical(test, "exact")) {
      function(x) prod(stats::plogis(-x - linear_predictor)) / 2 - alpha
    } else {
      z <- stats::qnorm(alpha, lower.tail = FALSE)
      function(gamma) {
        p <- stats::plogis(gamma + linear_predictor)
        z - sum(p) / sqrt(sum(p * (1 - p)))
      }
    }
    return(c(-Inf, infer_root(f, infer_brackets_extreme(linear_predictor), Inf)))
  }
  if (identical(kind, "all_events")) {
    f <- if (identical(test, "exact")) {
      function(x) prod(stats::plogis(x + linear_predictor)) / 2 - alpha
    } else {
      z <- stats::qnorm(alpha, lower.tail = FALSE)
      function(gamma) {
        p <- stats::plogis(gamma + linear_predictor)
        weights <- p * (1 - p)
        weights[weights == 0] <- score_weight_floor
        sum(1 - p) / sqrt(sum(weights)) - z
      }
    }
    return(c(infer_root(f, infer_brackets_extreme(linear_predictor), -Inf), Inf))
  }
  equations <- infer_interval_equations(observed, linear_predictor, test, alpha, alternative)
  lower <- if (alternative %in% c("two.sided", "greater")) {
    infer_root(equations$lower, infer_brackets_below(estimate), -Inf)
  } else {
    -Inf
  }
  upper <- if (alternative %in% c("two.sided", "less")) {
    infer_root(equations$upper, infer_brackets_above(estimate), Inf)
  } else {
    Inf
  }
  c(lower, upper)
}

# The equations whose roots are the limits for a provider with both outcomes
# (R/confint.logis_fe.R:102-119 for the score test, :207-222 for the exact test): the
# score statistic plus or minus a normal quantile, or the mid-p tail probability minus
# alpha / 2 (two-sided) or the plain tail minus alpha (one-sided).
infer_interval_equations <- function(observed, linear_predictor, test, alpha, alternative) {
  two_sided <- identical(alternative, "two.sided")
  if (identical(test, "score")) {
    z <- if (two_sided) stats::qnorm(alpha / 2, lower.tail = FALSE) else stats::qnorm(alpha, lower.tail = FALSE)
    statistic <- function(gamma) {
      p <- stats::plogis(gamma + linear_predictor)
      (observed - sum(p)) / sqrt(sum(p * (1 - p)))
    }
    return(list(upper = function(gamma) statistic(gamma) + z, lower = function(gamma) statistic(gamma) - z))
  }
  if (two_sided) {
    list(
      upper = function(gamma) {
        poibin::ppoibin(observed - 1, stats::plogis(gamma + linear_predictor)) +
          0.5 * poibin::dpoibin(observed, stats::plogis(gamma + linear_predictor)) - alpha / 2
      },
      lower = function(gamma) {
        1 - poibin::ppoibin(observed, stats::plogis(gamma + linear_predictor)) +
          0.5 * poibin::dpoibin(observed, stats::plogis(gamma + linear_predictor)) - alpha / 2
      }
    )
  } else {
    list(
      upper = function(gamma) poibin::ppoibin(observed, stats::plogis(gamma + linear_predictor)) - alpha,
      lower = function(gamma) 1 - poibin::ppoibin(observed - 1, stats::plogis(gamma + linear_predictor)) - alpha
    )
  }
}
