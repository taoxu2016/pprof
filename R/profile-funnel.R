# Funnel-plot control limits (K-110, K-111).

#' Funnel-plot control limits
#'
#' The control limits of a funnel plot of the indirectly standardized measures, with the
#' providers' points. For logistic fixed-effect models (K-110), the points are the indirect
#' ratios, a provider's precision is E_i^2 / V_i, with E_i the expected number of events
#' under the null and V_i its null variance (see [standardize_providers()]); at precision w
#' the limits are target -/+ qnorm(1 - alpha / 2) sqrt(1 / w) with alpha = 1 - `level`, and
#' the lower limit is at least 0. The providers are flagged by the modified score test of
#' [test_providers()] at the first level. For linear fixed-effect models (K-111), the points
#' are the indirect differences, a provider's precision is its number of observations n_i,
#' the limits are target -/+ qnorm(1 - alpha / 2) sqrt(1 / n_i) sigma, without a floor, and
#' the providers are flagged by the Wald test. With `provider_variance = "full"`, the limits
#' still use sigma^2 / n_i while the Wald test uses the full variance and t, so a point
#' outside the limits may not be flagged (D-43, awaiting a decision of the methodology
#' owners). These are the limits and flags of pprof 1.0.3's funnel plots. Random-effect
#' models have no funnel plot.
#'
#' @inheritParams test_providers
#' @param level One or more confidence levels, each giving a pair of limits; the providers
#'   are flagged at the first.
#' @param target The value the limits are centred on: `NULL` for the family's default (1 for
#'   ratios, 0 for differences).
#'
#' @return A `pprof_funnel` result: a `table` with one row per level and distinct provider
#'   precision (`level`, `precision`, `lower`, `upper`), the settings `target`, `measure`,
#'   `null_value`, and `test`, and `providers`, a data frame with one row per provider
#'   (`provider_id`, `n_obs`, `observed`, `expected`, `variance`, `precision`, `estimate`,
#'   `flag`).
#' @examples
#' data(ExampleDataBinary)
#' example <- data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID,
#'                       ExampleDataBinary$Z)
#' fit <- fit_logistic_fe(y ~ z1 + z2 + z3 + z4 + z5, example, provider = "hospital")
#' funnel <- funnel_limits(fit, level = c(0.95, 0.99))
#' head(funnel$table)
#' @export
funnel_limits <- function(model, level = 0.95, null = NULL, target = NULL, providers = NULL) {
  profile_check_model(model)
  if (!is.numeric(level) || length(level) == 0L || anyDuplicated(level) > 0L) {
    abort_invalid_input("`level` must be one or more distinct numbers between 0 and 1.", arg = "level")
  }
  for (value in level) check_level(value)
  require_capability(model, "funnel")
  spec <- profile_family(model)
  funnel <- profile_spec_field(model, spec, "funnel")
  if (is.null(target)) target <- funnel$target
  check_number(target, "target")
  null_value <- profile_null_value(model, spec, null)
  rows <- profile_provider_rows(model, providers)
  test_capability <- profile_test_capability(funnel$test, "modified")
  require_capability(model, test_capability)
  base <- profile_indirect(model, spec, null_value, rows)
  n_obs <- provider_table(model)$n_obs[rows]
  precision <- profile_funnel_precision(funnel, base$expected, base$variance, n_obs)
  flags <- profile_test_table(model, spec, test_capability, null_value, level[1], "two.sided", rows)$flag
  estimate <- profile_compare(spec, "indirect", base$observed, base$expected, n_obs, NULL)
  points <- data.frame(provider_id = provider_table(model)$provider_id[rows], n_obs = n_obs,
                       observed = base$observed, expected = base$expected, variance = base$variance,
                       precision = precision, estimate = estimate, flag = flags, stringsAsFactors = FALSE)
  limits <- profile_funnel_limits(sort(unique(precision[is.finite(precision)])), 1 - level, target, funnel)
  table <- data.frame(level = level[match(limits$alpha, 1 - level)], precision = limits$precision,
                      lower = limits$lower, upper = limits$upper)
  new_pprof_funnel(table, target = as.double(target), measure = funnel$measure, null_value = null_value,
                   test = funnel$test, providers = points)
}

# Control limits at each precision for each alpha, used directly (K-110): the compatibility
# wrapper passes the user's alpha, which the reference uses as given, and funnel_limits()
# passes 1 - level.
profile_funnel_limits <- function(precision, alpha, target, funnel) {
  limits <- lapply(alpha, function(value) {
    half_width <- funnel$half_width(stats::qnorm(1 - value / 2), precision)
    data.frame(alpha = rep(value, length(precision)), precision = precision,
               lower = pmax(target - half_width, funnel$floor), upper = target + half_width)
  })
  do.call(rbind, limits)
}
