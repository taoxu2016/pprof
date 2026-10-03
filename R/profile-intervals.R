# Intervals for provider effects (K-90, K-94) and for standardized measures (K-91).

# Limits for the effects of the providers in `rows`: a matrix with columns lower and upper
# in the order of `rows`. The exact and score limits invert the test for each provider by
# its kind: providers with events and non-events get the limits `alternative` asks for;
# a provider with no events gets only an upper limit and one with only events only a lower
# limit, whatever the alternative, as in the reference (question M-15). Wald limits are
# estimate -/+ critical value times the standard error.
profile_effect_limits <- function(model, spec, interval, level, alternative, rows) {
  positions <- profile_positions(model, rows)
  estimate <- unname(provider_estimates(model))[positions]
  if (identical(interval, "wald")) {
    profile_wald_caution(model, spec, rows)
    std_error <- unname(provider_estimate_se(model))[positions]
    return(unname(infer_wald_interval(estimate, std_error, level, alternative)))
  }
  kinds <- profile_provider_kinds(model, rows)
  observed <- observed_outcome(model)
  linear_predictor <- linear_predictor(model)
  observations <- profile_observations(model, rows)
  limits <- vapply(seq_along(rows), function(k) {
    r <- observations[[k]]
    infer_effect_interval(kinds[k], estimate[k], sum(observed[r]), linear_predictor[r], interval, level, alternative)
  }, numeric(2))
  matrix(limits, ncol = 2L, byrow = TRUE)
}

# Limits of the standardized ratios of the providers in `rows` from the limits of their
# effects (K-91), for one standardization. Indirect: the expected number of events of the
# provider's own observations with the effect at its limit, over E_i; direct: the expected
# number of events of all observations with the effect at its limit, over the total
# number of events. A provider with no events has lower limit 0, and with
# alternative = "greater" upper limit n_i / E_i (indirect) or n / sum(y) (direct); one with
# only events has upper limit n_i / E_i or n / sum(y), and with alternative = "less" lower
# limit 0.
profile_ratio_limits <- function(model, spec, standardization, base, effect_limits, alternative, rows) {
  mean_function <- profile_spec_field(model, spec, "mean_function")
  linear_predictor <- linear_predictor(model)
  kinds <- profile_provider_kinds(model, rows)
  if (identical(standardization, "indirect")) {
    observations <- profile_observations(model, rows)
    expected_at <- function(effect, k) sum(mean_function(effect + linear_predictor[observations[[k]]]))
    denominator <- base$expected
    full <- provider_table(model)$n_obs[rows]
  } else {
    expected_at <- function(effect, k) sum(mean_function(effect + linear_predictor))
    denominator <- base$observed
    full <- rep(length(linear_predictor), length(rows))
  }
  limits <- vapply(seq_along(rows), function(k) {
    lower <- if (identical(kinds[k], "no_events") || (identical(kinds[k], "all_events") && alternative == "less")) {
      0
    } else {
      expected_at(effect_limits[k, 1], k) / denominator[k]
    }
    upper <- if (identical(kinds[k], "all_events") || (identical(kinds[k], "no_events") && alternative == "greater")) {
      full[k] / denominator[k]
    } else {
      expected_at(effect_limits[k, 2], k) / denominator[k]
    }
    c(lower, upper)
  }, numeric(2))
  matrix(limits, ncol = 2L, byrow = TRUE)
}
