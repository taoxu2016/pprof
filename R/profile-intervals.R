# Intervals for provider effects (K-90, K-92 to K-94) and for standardized measures (K-91,
# K-92, K-93).

# Limits for the effects of the providers in `rows`: a matrix with columns lower and upper
# in the order of `rows`. The exact and score limits invert the test for each provider by
# its kind: providers with events and non-events get the limits `alternative` asks for;
# a provider with no events gets only an upper limit and one with only events only a lower
# limit, whatever the alternative, as in the reference (question M-15). Wald limits are
# estimate -/+ critical value times the standard error, with the family's distribution for
# intervals (t for linear fixed effects with the simplified variance, D-32).
profile_effect_limits <- function(model, spec, interval, level, alternative, rows) {
  positions <- profile_positions(model, rows)
  estimate <- unname(provider_estimates(model))[positions]
  if (identical(interval, "wald")) {
    profile_wald_caution(model, spec, rows)
    std_error <- unname(provider_estimate_se(model))[positions]
    wald <- profile_spec_option(spec, "wald")
    return(unname(infer_wald_interval(estimate, std_error, level, alternative, wald$interval, wald$df)))
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

# Limits of the standardized measures of the providers in `rows` from the limits of their
# effects, for one standardization, on the family's comparison scale (K-91, K-92, K-93).
# The expected outcome with the effect at its limit is summed over the provider's own
# observations (indirect) or over all observations (direct), and compared with the
# denominator of the measure as the point estimate is (profile_compare()). Direct sums are
# R's sums of the mean function or the family's direct expectation (`direct_limits`).
# Families with `one_sided_extremes` (logistic fixed effects) give a provider with no events
# lower limit 0, and with alternative = "greater" upper limit n_i / E_i (indirect) or
# n / total (direct), and a provider with only events upper limit n_i / E_i or n / total, and
# with alternative = "less" lower limit 0.
profile_measure_limits <- function(model, spec, standardization, base, effect_limits, alternative, rows, threads) {
  mean_function <- profile_spec_field(model, spec, "mean_function")
  linear_predictor <- linear_predictor(model)
  n_obs <- provider_table(model)$n_obs[rows]
  n <- length(linear_predictor)
  # The expected outcome with each provider's effect at a limit.
  expected_at <- if (identical(standardization, "indirect")) {
    observations <- profile_observations(model, rows)
    function(effects) {
      vapply(seq_along(rows), function(k) sum(mean_function(effects[k] + linear_predictor[observations[[k]]])),
             numeric(1))
    }
  } else if (identical(profile_spec_option(spec, "direct_limits"), "direct_expected")) {
    direct_expected <- profile_spec_field(model, spec, "direct_expected")
    function(effects) direct_expected(effects, linear_predictor, threads)
  } else {
    function(effects) vapply(effects, function(effect) sum(mean_function(effect + linear_predictor)), numeric(1))
  }
  # The denominator of the measure: the expected outcome under the null (indirect) or the
  # reference total (direct).
  reference <- if (identical(standardization, "indirect")) base$expected else base$observed
  lower <- profile_compare(spec, standardization, expected_at(effect_limits[, 1]), reference, n_obs, n)
  upper <- profile_compare(spec, standardization, expected_at(effect_limits[, 2]), reference, n_obs, n)
  if (isTRUE(profile_spec_option(spec, "one_sided_extremes"))) {
    kinds <- profile_provider_kinds(model, rows)
    full <- (if (identical(standardization, "indirect")) n_obs else rep(n, length(rows))) / reference
    lower[kinds == "no_events" | (kinds == "all_events" & alternative == "less")] <- 0
    upper_full <- kinds == "all_events" | (kinds == "no_events" & alternative == "greater")
    upper[upper_full] <- full[upper_full]
  }
  cbind(lower, upper, deparse.level = 0)
}
