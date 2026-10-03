# Standardized measures (K-80 to K-82) and their intervals (K-91).

#' Standardized measures for providers
#'
#' Indirectly and directly standardized ratios and rates. For logistic fixed-effect models:
#'
#' - indirect (K-80): the provider's observed number of events O_i over its expected number
#'   E_i = sum of p0 = plogis(null + z'beta) over its observations, the number expected if
#'   the provider's effect were the null value;
#' - direct (K-81): the number of events expected in the whole population if every
#'   observation had the provider's effect, sum over all observations of
#'   plogis(gamma_i + z'beta), over the population's number of events;
#' - rates are ratios times the population rate 100 sum(y) / n, in percent, clipped to
#'   \[0, 100\].
#'
#' Intervals map the limits of the provider effect from [provider_effects()] through the
#' same sums, with the one-sided limits of providers with no events or only events: a
#' provider with no events has lower limit 0 and one with only events upper limit n_i / E_i
#' (indirect) or n / sum(y) (direct). These are the measures and intervals of pprof 1.0.3's
#' `SM_output()` and `confint()`, whose results they reproduce.
#'
#' @inheritParams test_providers
#' @param standardization `"indirect"`, `"direct"`, or both.
#' @param measure The measures: `NULL` for all the family's measures (`"ratio"` and `"rate"`
#'   for logistic models), or some of them.
#' @param null The null value of indirect standardization: `NULL` for the family's default
#'   (`"median"` for fixed-effect models), one of the family's named options, or a number.
#'   Direct standardization does not use it.
#' @param interval `"none"`, `"exact"`, `"score"`, or `"wald"`.
#' @param threads The number of threads for the direct expectations.
#'
#' @return A `pprof_measures` result: a `table` with one row per standardization, measure,
#'   and provider (`provider_id`, `standardization`, `measure`, `n_obs`, `observed`,
#'   `expected`, `variance`, `estimate`, and with an interval `lower` and `upper`) and the
#'   settings `interval`, `level`, `alternative`, `null_value`, `standardization`,
#'   `measure`, and `population_rate` (for rates). For indirect standardization `observed`
#'   and `expected` are O_i and E_i and `variance` is sum of p0 (1 - p0); for direct
#'   standardization `observed` is the population's number of events, `expected` the
#'   provider's expected number in the population, and `variance` is missing.
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
  check_choice(interval, c("none", "exact", "score", "wald"), "interval")
  check_level(level)
  check_choice(alternative, c("two.sided", "greater", "less"), "alternative")
  check_threads(threads)
  for (method in standardization) require_capability(model, paste0("standardize_", method))
  if (!identical(interval, "none")) require_capability(model, paste0("interval_", interval))
  null_value <- profile_null_value(model, spec, null)
  rows <- profile_provider_rows(model, providers)
  standardization <- intersect(c("indirect", "direct"), standardization)
  measure <- intersect(spec$measures, measure)
  effect_limits <- if (!identical(interval, "none")) {
    profile_effect_limits(model, spec, interval, level, alternative, rows)
  }
  population_rate <- if ("rate" %in% measure) profile_population_rate(model)
  parts <- list()
  for (method in standardization) {
    base <- if (identical(method, "indirect")) {
      profile_indirect(model, spec, null_value, rows)
    } else {
      profile_direct(model, spec, rows, threads)
    }
    ratio <- if (identical(method, "indirect")) base$observed / base$expected else base$expected / base$observed
    ratio_limits <- if (!is.null(effect_limits)) {
      profile_ratio_limits(model, spec, method, base, effect_limits, alternative, rows)
    }
    for (scale in measure) {
      part <- data.frame(provider_id = provider_table(model)$provider_id[rows], standardization = method,
                         measure = scale, n_obs = provider_table(model)$n_obs[rows], observed = base$observed,
                         expected = base$expected, variance = base$variance,
                         estimate = profile_measure_value(model, ratio, scale, population_rate),
                         stringsAsFactors = FALSE)
      if (!is.null(ratio_limits)) {
        part$lower <- profile_measure_value(model, ratio_limits[, 1], scale, population_rate)
        part$upper <- profile_measure_value(model, ratio_limits[, 2], scale, population_rate)
      }
      parts[[length(parts) + 1L]] <- part
    }
  }
  table <- do.call(rbind, parts)
  rownames(table) <- NULL
  settings <- list(interval = interval, level = level, null_value = null_value, alternative = alternative,
                   standardization = standardization, measure = measure)
  if (!is.null(population_rate)) settings$population_rate <- population_rate
  do.call(new_pprof_measures, c(list(table), settings))
}

# Indirect standardization (K-80): per provider, the observed number of events, the number
# expected under the null, and its null variance, each summed over the provider's
# observations in their stored order, as the reference sums them.
profile_indirect <- function(model, spec, null_value, rows) {
  if (!identical(spec$indirect_numerator, "observed")) {
    abort_unsupported_inference(model, sprintf("indirect standardization with numerator '%s'",
                                               spec$indirect_numerator))
  }
  index <- provider_index(model)
  expected <- expected_outcome(model, null_value)
  variance <- if (is.null(spec$variance_function)) {
    rep(NA_real_, length(rows))
  } else {
    data_provider_sums(spec$variance_function(expected), index, rows)
  }
  data.frame(observed = data_provider_sums(observed_outcome(model), index, rows),
             expected = data_provider_sums(expected, index, rows), variance = variance)
}

# Direct standardization (K-81): the population's number of events, and per provider the
# number expected in the population with the provider's effect, from the family's direct
# expectation (computed in C++ for logistic models, as the reference computes it).
profile_direct <- function(model, spec, rows, threads) {
  direct_expected <- profile_spec_field(model, spec, "direct_expected")
  effects <- unname(provider_estimates(model))[profile_positions(model, rows)]
  total <- as.double(sum(observed_outcome(model)))
  data.frame(observed = rep(total, length(rows)),
             expected = direct_expected(effects, linear_predictor(model), threads), variance = NA_real_)
}

# The population rate in percent (K-80): sum(y) / n * rate_scale over the included
# observations, in the reference's order of operations.
profile_population_rate <- function(model) {
  observed <- observed_outcome(model)
  sum(observed) / length(observed) * rate_scale
}

# A ratio on the scale of a measure: the ratio itself, or the rate, the ratio times the
# population rate clipped to rate_limits (K-80).
profile_measure_value <- function(model, ratio, measure, population_rate) {
  switch(measure,
    ratio = ratio,
    rate = pmax(pmin(ratio * population_rate, rate_limits[2]), rate_limits[1]),
    abort_unsupported_inference(model, sprintf("the measure '%s'", measure))
  )
}
