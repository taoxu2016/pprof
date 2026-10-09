# Standardized measures (K-80 to K-84) and their intervals (K-91 to K-93).

# The help below states K-80 (logistic FE indirect), K-81 (direct), K-83 (linear FE), K-82
# and K-84 (RE and CRE, predicted over expected), and K-91 to K-93 for the intervals; the
# linear FE intervals keep D-32 (awaiting sign-off).
#' Standardized measures for providers
#'
#' Indirectly and directly standardized measures. For logistic fixed-effect models, ratios
#' and rates:
#'
#' - indirect: the provider's observed number of events O_i over its expected number
#'   E_i = sum of p0 = plogis(null + z'beta) over its observations, the number expected if
#'   the provider's effect were the null value;
#' - direct: the number of events expected in the whole population if every
#'   observation had the provider's effect, sum over all observations of
#'   plogis(gamma_i + z'beta), over the population's number of events;
#' - rates are ratios times the population rate 100 sum(y) / n, in percent, clipped to
#'   \[0, 100\].
#'
#' For linear fixed-effect models, differences: indirect (O_i - E_i) / n_i with
#' E_i = sum of (null + z'beta) over the provider's n_i observations, and direct
#' (sum over all observations of (gamma_i + z'beta) - sum over all observations of
#' (null + z'beta)) / n, so that direct standardization also uses `null`. Both are
#' gamma_i - null up to rounding.
#'
#' For random-effect and correlated random-effect models, the numerator of indirect measures
#' is the sum of the model's fitted values over the provider's observations, which include
#' the provider's estimated effect, not its observed outcomes (predicted over expected, as in
#' pprof 1.0.3); the expected outcomes use the null effect, 0 by default.
#' Logistic models give ratios and rates, with the population's number of events as the
#' direct denominator; linear models give differences, (sum of fitted - sum of x'beta) / n_i
#' (indirect) and (sum over all observations of (alpha_i + x'beta) - sum(y)) / n (direct).
#'
#' Intervals map the limits of the provider effect from [provider_effects()] (at
#' `alternative`, one-sided if asked) through the same sums. Logistic fixed-effect models
#' give providers with no events or only events one-sided limits: a provider with no events
#' has lower limit 0 and one with only events upper limit n_i / E_i (indirect) or n / sum(y)
#' (direct). For linear fixed-effect models the intervals use the distribution of the Wald
#' intervals of [provider_effects()]: Student's t with n - m - p degrees of freedom with
#' `provider_variance = "simplified"` and the normal with `"full"`, the reverse of the tests
#' of [test_providers()]. For random-effect models, the intervals carry those of the shrunk
#' conditional modes (see [provider_effects()] and
#' `vignette("statistical-methods", package = "pprof")`). These are the measures and
#' intervals of pprof 1.0.3's `SM_output()` and `confint()`, whose results they reproduce.
#'
#' For provider-stratified Cox models ([fit_cox_stratified()]), ratios, He and Schaubel's
#' two-stage measures as pprof_py computes them:
#'
#' - indirect: the provider's observed events O_i over its expected events E_i, the sum over its
#'   observations of exp(eta) (L0(stop) - L0(start)), where L0 is the Breslow estimator of the
#'   cumulative baseline hazard over all observations with the linear predictor
#'   eta = x'beta + offset as offset (times exp(`null`) for a numeric `null`); the E_i add up to the
#'   events;
#' - direct: the events expected in the whole population with the provider's own baseline, the sum
#'   over the provider's events of the population's risk-set sum of exp(eta) over the provider's,
#'   over the population's number of events.
#'
#' They use the fitted coefficients only: every observation counts once, observations with weight
#' 0 included, and the baselines are Breslow's whatever the ties of the fit. A provider without
#' expected events has an undefined or infinite indirect ratio and a
#' `pprof_warning_zero_expected` warning. The intervals of indirect ratios are `"exact"`, Garwood's
#' limits when E_i < 100 and Byar's otherwise, or `"midp"`, the limits that invert the mid-p test
#' of [test_providers()], so that an interval excludes 1 exactly when the test flags the provider;
#' both are two-sided, and direct standardization has none. `variance` is E_i, the Poisson null
#' variance.
#'
#' @inheritParams test_providers
#' @param standardization `"indirect"`, `"direct"`, or both.
#' @param measure The measures: `NULL` for all the family's measures (`"ratio"` and `"rate"`
#'   for logistic models, `"difference"` for linear models, `"ratio"` for Cox models), or some of
#'   them.
#' @param null The null value: `NULL` for the family's default (`"median"` for fixed-effect
#'   models, 0 for random-effect and Cox models), one of the family's named options, or a number.
#'   Direct standardization uses it only for linear fixed-effect models.
#' @param interval `"none"`, `"exact"`, `"score"`, `"wald"`, or `"midp"`.
#' @param threads The number of threads for the direct expectations of logistic models.
#'
#' @return A `pprof_measures` result: a `table` with one row per standardization, measure,
#'   and provider (`provider_id`, `standardization`, `measure`, `n_obs`, `observed`,
#'   `expected`, `variance`, `estimate`, and with an interval `lower` and `upper`) and the
#'   settings `interval`, `level`, `alternative`, `null_value`, `standardization`,
#'   `measure`, `indirect_numerator`, `direct_reference`, and `population_rate` (for rates).
#'   `observed` and `expected` are the two sums each measure compares, as in pprof 1.0.3's
#'   `OE` tables. For indirect standardization, `observed` is the numerator (O_i, or the sum
#'   of the fitted values when `indirect_numerator` is `"predicted"`), `expected` is E_i, and
#'   `variance` is the sum of p0 (1 - p0) for logistic fixed-effect models and missing
#'   otherwise; for direct standardization, `observed` is the reference total (the
#'   population's outcome, or for linear fixed-effect models, whose `direct_reference` is
#'   `"null_expected"`, the sum of null + z'beta), `expected` the provider's expected outcome
#'   in the population, and `variance` is missing. The rows come in blocks, one per
#'   standardization and measure, each with the providers in provider order (see "Provider
#'   order" in [fit_logistic_fe()]).
#' @family provider profiling
#' @examples
#' data(ExampleDataBinary)
#' example <- data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID,
#'                       ExampleDataBinary$Z)
#' fit <- fit_logistic_fe(y ~ z1 + z2 + z3 + z4 + z5, example, provider = "hospital")
#' measures <- standardize_providers(fit, measure = "ratio", interval = "score", providers = 1:5)
#' measures$table
#' @export
standardize_providers <- function(model, standardization = "indirect", measure = NULL, null = NULL,
                                  interval = "none", level = 0.95, alternative = "two.sided", providers = NULL,
                                  threads = 1) {
  profile_check_model(model)
  check_choice(standardization, c("indirect", "direct"), "standardization", multiple = TRUE)
  spec <- profile_family(model)
  if (is.null(measure)) measure <- spec$measures
  check_choice(measure, spec$measures, "measure", multiple = TRUE)
  check_choice(interval, c("none", "exact", "score", "wald", "midp"), "interval")
  check_level(level)
  check_choice(alternative, c("two.sided", "greater", "less"), "alternative")
  check_threads(threads)
  for (method in standardization) require_capability(model, paste0("standardize_", method))
  if (!identical(interval, "none")) require_capability(model, paste0("interval_", interval))
  # Families with Poisson counts take their limits from O_j and E_j, two-sided and for indirect
  # standardization only, as pprof_py gives them (DEC-108).
  poisson <- profile_poisson(spec)
  if (poisson && !identical(interval, "none")) {
    if ("direct" %in% standardization) abort_unsupported_inference(model, "intervals of direct standardization")
    if (!identical(alternative, "two.sided")) {
      abort_unsupported_inference(model, sprintf("one-sided intervals (alternative = \"%s\")", alternative))
    }
  }
  null_value <- profile_null_value(model, spec, null)
  rows <- profile_provider_rows(model, providers)
  standardization <- intersect(c("indirect", "direct"), standardization)
  measure <- intersect(spec$measures, measure)
  effect_limits <- if (!identical(interval, "none") && !poisson) {
    profile_effect_limits(model, spec, interval, level, alternative, rows)
  }
  population_rate <- if ("rate" %in% measure) profile_population_rate(model)
  n_obs <- provider_table(model)$n_obs[rows]
  n <- length(observed_outcome(model))
  parts <- list()
  for (method in standardization) {
    base <- if (identical(method, "indirect")) {
      profile_indirect(model, spec, null_value, rows)
    } else {
      profile_direct(model, spec, null_value, rows, threads)
    }
    value <- if (identical(method, "indirect")) {
      profile_compare(spec, method, base$observed, base$expected, n_obs, n)
    } else {
      profile_compare(spec, method, base$expected, base$observed, n_obs, n)
    }
    if (poisson && identical(method, "indirect")) profile_warn_zero_expected(model, spec, base$expected, rows)
    value_limits <- if (poisson && !identical(interval, "none")) {
      profile_poisson_limits(base, interval, level)
    } else if (!is.null(effect_limits)) {
      profile_measure_limits(model, spec, method, base, effect_limits, alternative, rows, threads)
    }
    for (scale in measure) {
      part <- data.frame(provider_id = provider_table(model)$provider_id[rows], standardization = method,
                         measure = scale, n_obs = n_obs, observed = base$observed,
                         expected = base$expected, variance = base$variance,
                         estimate = profile_measure_value(model, value, scale, population_rate),
                         stringsAsFactors = FALSE)
      if (!is.null(value_limits)) {
        part$lower <- profile_measure_value(model, value_limits[, 1], scale, population_rate)
        part$upper <- profile_measure_value(model, value_limits[, 2], scale, population_rate)
      }
      parts[[length(parts) + 1L]] <- part
    }
  }
  table <- do.call(rbind, parts)
  rownames(table) <- NULL
  settings <- list(interval = interval, level = level, null_value = null_value, alternative = alternative,
                   standardization = standardization, measure = measure,
                   indirect_numerator = spec$indirect_numerator,
                   direct_reference = profile_spec_option(spec, "direct_reference"))
  if (!is.null(population_rate)) settings$population_rate <- population_rate
  do.call(new_pprof_measures, c(list(table), settings))
}

# Indirect standardization (K-80, K-82 to K-84): per provider, the numerator (the observed
# outcomes, or the model's predictions with its own provider effects for random-effect
# models), the outcomes expected under the null, and their null variance where the family
# has one, each summed over the provider's observations in their stored order, as the
# reference sums them. The table calls the numerator `observed` (DEC-048).
profile_indirect <- function(model, spec, null_value, rows) {
  numerator <- switch(spec$indirect_numerator,
    observed = observed_outcome(model),
    predicted = predicted_outcome(model),
    abort_unsupported_inference(model, sprintf("indirect standardization with numerator '%s'",
                                               spec$indirect_numerator))
  )
  index <- provider_index(model)
  expected <- expected_outcome(model, null_value)
  variance <- if (is.null(spec$variance_function)) {
    rep(NA_real_, length(rows))
  } else {
    data_provider_sums(spec$variance_function(expected), index, rows)
  }
  data.frame(observed = data_provider_sums(numerator, index, rows),
             expected = data_provider_sums(expected, index, rows), variance = variance)
}

# Direct standardization (K-81 to K-84): the reference total, and per provider the outcome
# expected in the population with the provider's effect, from the family's direct
# expectation (computed in C++ for logistic models, as the reference computes it). The
# reference total is the sum of the outcomes, or for linear fixed effects the sum of the
# outcomes expected under the null (K-83), which the table calls `observed` (DEC-048).
profile_direct <- function(model, spec, null_value, rows, threads) {
  # A family without provider effects gives each provider's direct expectation itself (K-138).
  direct_by_provider <- profile_spec_option(spec, "direct_by_provider")
  if (is.null(direct_by_provider)) {
    direct_expected <- profile_spec_field(model, spec, "direct_expected")
    effects <- unname(provider_estimates(model))[profile_positions(model, rows)]
  }
  total <- switch(profile_spec_option(spec, "direct_reference"),
    observed = as.double(sum(observed_outcome(model))),
    null_expected = sum(expected_outcome(model, null_value)),
    abort_unsupported_inference(model, sprintf("direct standardization with the reference total '%s'",
                                               spec$direct_reference))
  )
  expected <- if (is.null(direct_by_provider)) {
    direct_expected(effects, linear_predictor(model), threads)
  } else {
    direct_by_provider(model, rows)
  }
  data.frame(observed = rep(total, length(rows)), expected = expected, variance = NA_real_)
}

# The limits of indirect ratios of a family with Poisson counts (K-140, K-141): the exact test's
# Garwood or Byar limits, or the mid-p limits, from each provider's O_j and E_j (E_j at the null),
# on the ratio scale.
profile_poisson_limits <- function(base, interval, level) {
  limits <- switch(interval,
    exact = infer_poisson_exact_limits(base$observed, base$expected, level),
    midp = infer_poisson_midp_limits(base$observed, base$expected, level)
  )
  unname(limits)
}

# The population rate in percent (K-80): sum(y) / n * rate_scale over the included
# observations, in the reference's order of operations.
profile_population_rate <- function(model) {
  observed <- observed_outcome(model)
  sum(observed) / length(observed) * rate_scale
}

# A ratio or difference on the scale of a measure: the ratio or difference itself, or the
# rate, the ratio times the population rate clipped to rate_limits (K-80).
profile_measure_value <- function(model, value, measure, population_rate) {
  switch(measure,
    ratio = value,
    difference = value,
    rate = pmax(pmin(value * population_rate, rate_limits[2]), rate_limits[1]),
    abort_unsupported_inference(model, sprintf("the measure '%s'", measure))
  )
}
