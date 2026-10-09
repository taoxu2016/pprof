# Provider effects with standard errors and intervals (K-90).

# The help below states K-90 to K-94; the distributions of the linear FE intervals keep D-32
# (awaiting sign-off).
#' Provider effects
#'
#' The estimated provider effects, their standard errors where the model provides them,
#' and optionally two-sided intervals at `level`:
#'
#' - `"exact"` and `"score"` invert the exact and score tests of [test_providers()] for each
#'   provider, searching for each limit with [stats::uniroot()] in the brackets pprof 1.0.3
#'   uses. A provider with no events gets only an upper limit (the lower is `-Inf`) and one
#'   with only events only a lower limit (the upper is `Inf`); that limit solves its
#'   equation at alpha = 1 - `level`, not alpha / 2, as in pprof 1.0.3. A limit without a
#'   root in any bracket is infinite.
#' - `"wald"`: estimate -/+ qnorm(1 - alpha / 2) times the standard error; for logistic
#'   fixed-effect models it warns with class `pprof_warning_wald_unreliable` when it covers
#'   providers with no events or only events. Linear fixed-effect models use
#'   qt(1 - alpha / 2, n - m - p) with `provider_variance = "simplified"` and qnorm with
#'   `"full"`, the reverse of their tests, as pprof 1.0.3 does.
#'
#' Logistic fixed-effect and Firth models offer all three intervals; linear fixed-effect,
#' random-effect, and correlated random-effect models only the Wald interval. For
#' random-effect models, the Wald interval is centred on the conditional mode, which is shrunk
#' toward 0, with its conditional standard deviation;
#' `vignette("statistical-methods", package = "pprof")` describes how often such intervals
#' cover a provider's effect. Models without provider effects, such as the provider-stratified
#' Cox model of [fit_cox_stratified()], raise a `pprof_error_unsupported_inference` condition.
#'
#' @inheritParams test_providers
#' @param interval `"none"`, `"exact"`, `"score"`, or `"wald"`.
#'
#' @return A `pprof_provider_effects` result: a `table` with one row per provider in provider
#'   order (see "Provider order" in [fit_logistic_fe()]; `provider_id`, `n_obs`, `estimate`,
#'   `std_error` where the model provides it, and `lower` and `upper` with an interval) and
#'   the settings `interval` and `level`.
#' @family provider profiling
#' @examples
#' data(ExampleDataBinary)
#' example <- data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID,
#'                       ExampleDataBinary$Z)
#' fit <- fit_logistic_fe(y ~ z1 + z2 + z3 + z4 + z5, example, provider = "hospital")
#' head(provider_effects(fit, interval = "score", providers = 1:5)$table)
#' @export
provider_effects <- function(model, interval = "none", level = 0.95, providers = NULL) {
  profile_check_model(model)
  check_choice(interval, c("none", "exact", "score", "wald"), "interval")
  check_level(level)
  # A model without provider-effect estimates has none to report (COXPH_DESIGN §D.3, DEC-102).
  if (is.null(provider_estimates(model))) abort_unsupported_inference(model, "provider_effects()")
  if (!identical(interval, "none")) require_capability(model, paste0("interval_", interval))
  spec <- profile_family(model)
  rows <- profile_provider_rows(model, providers)
  positions <- profile_positions(model, rows)
  table <- data.frame(provider_id = provider_table(model)$provider_id[rows], n_obs = provider_table(model)$n_obs[rows],
                      estimate = unname(provider_estimates(model))[positions], stringsAsFactors = FALSE)
  if (profile_has_capability(model, "interval_wald") || profile_has_capability(model, "provider_wald")) {
    table$std_error <- unname(provider_estimate_se(model))[positions]
  }
  if (!identical(interval, "none")) {
    limits <- profile_effect_limits(model, spec, interval, level, "two.sided", rows)
    table$lower <- limits[, 1]
    table$upper <- limits[, 2]
  }
  new_pprof_provider_effects(table, interval = interval, level = level)
}
