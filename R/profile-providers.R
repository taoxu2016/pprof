# Everything a profiling report needs, keyed by provider.

#' Profile providers
#'
#' Runs the profiling steps for a model and collects their results: the provider effects
#' ([provider_effects()]), the tests and flags ([test_providers()]), the indirectly
#' standardized measures with optional intervals ([standardize_providers()]), and, for
#' models that support funnel plots, the funnel limits ([funnel_limits()]).
#'
#' @inheritParams test_providers
#' @param interval The interval of the standardized measures: `"none"`, `"exact"`,
#'   `"score"`, or `"wald"`.
#'
#' @return A `pprof_profile` result: a `table` with one row per provider (`provider_id`,
#'   `n_obs`, `observed`, `expected`, `statistic`, `p_value`, `flag`), the component results
#'   `effects`, `tests`, `measures`, and `funnel` (`NULL` for models without funnel
#'   limits), and the settings `test`, `level`, `alternative`, `null_value`, and
#'   `interval`.
#' @examples
#' data(ExampleDataBinary)
#' example <- data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID, ExampleDataBinary$Z)
#' fit <- fit_logistic_fe(y ~ z1 + z2 + z3 + z4 + z5, example, provider = "hospital")
#' profile <- profile_providers(fit)
#' head(profile$table)
#' @export
profile_providers <- function(model, test = "exact", null = NULL, level = 0.95, alternative = "two.sided",
                              interval = "none", providers = NULL, score_type = "modified", n_resamples = 10000,
                              data = NULL, threads = 1) {
  effects <- provider_effects(model, providers = providers)
  tests <- test_providers(model, test = test, null = null, level = level, alternative = alternative,
                          providers = providers, score_type = score_type, n_resamples = n_resamples, data = data,
                          threads = threads)
  measures <- standardize_providers(model, "indirect", null = null, interval = interval, level = level,
                                    alternative = alternative, providers = providers, threads = threads)
  funnel <- if (profile_has_capability(model, "funnel")) {
    funnel_limits(model, level = level, null = null, providers = providers)
  }
  first <- measures$table[measures$table$measure == measures$measure[1], , drop = FALSE]
  table <- data.frame(provider_id = tests$table$provider_id, n_obs = tests$table$n_obs, observed = first$observed,
                      expected = first$expected, statistic = tests$table$statistic, p_value = tests$table$p_value,
                      flag = tests$table$flag, stringsAsFactors = FALSE)
  new_pprof_profile(table, effects = effects, tests = tests, measures = measures, funnel = funnel, test = test,
                    level = level, alternative = alternative, null_value = tests$null_value, interval = interval)
}
