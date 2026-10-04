# Provider-level tests and flags (K-62 to K-67).
#
# The exact, bootstrap, and modified score tests need only the observed and expected
# outcomes, and the Wald test only the estimates and their standard errors, so they are
# computed here for every model that declares them. Tests that need the model's internals,
# such as the standard score test, come from the model's provider_test() method.

#' Tests and flags for providers
#'
#' Tests each provider against the null value and flags it as higher than expected (1), as
#' expected (0), or lower than expected (-1). For logistic fixed-effect models, the null
#' probability of each observation is p0 = plogis(null + z'beta), and:
#'
#' - `"exact"`: the provider's number of events has a Poisson-binomial distribution under
#'   the null. The two-sided test uses the mid-p upper tail P(O > o) + P(O = o) / 2.
#' - `"bootstrap"`: the same distribution, simulated with `n_resamples` draws for each
#'   provider from R's random number generator, so set a seed to reproduce the results.
#' - `"score"` with `score_type = "modified"`: z = sum(y - p0) / sqrt(sum(p0 (1 - p0))),
#'   with the coefficients of the full model. With `score_type = "standard"`, the variance
#'   accounts for the estimation of the coefficients and the other providers' effects, at
#'   the full model's estimates (no refit under the null); it needs the covariates.
#' - `"wald"`: z = (gamma - null) / se.
#'
#' The exact, bootstrap, and modified score tests clamp p0 to \[1e-10, 1 - 1e-10\]. With
#' alpha = 1 - `level`, a two-sided test flags a provider when the upper-tail probability
#' P is below alpha / 2 (1) or above 1 - alpha / 2 (-1) and reports the p-value
#' 2 min(P, 1 - P); a one-sided test reports the probability of the tested tail as the
#' p-value and flags it when it is below alpha. These are the tests of pprof 1.0.3's
#' `test()`, whose results they reproduce.
#'
#' A standard score statistic that is not finite gets a missing p-value and flag, with a
#' `pprof_warning_undefined_statistics` warning. Wald tests warn with class
#' `pprof_warning_wald_unreliable` when they cover providers with no events or only events,
#' whose estimates sit at the effect bound.
#'
#' Linear fixed-effect, random-effect, and correlated random-effect models have only the
#' Wald test, which is their default: z = (estimate - null) / se, with the standard error of
#' the provider effect (the square root of the provider variance of [fit_linear_fe()]; for
#' random-effect models, the standard deviation of the conditional mode, as the models'
#' `provider_effect_sd` holds it). The reference distribution is the standard normal, except
#' for linear fixed-effect models with `provider_variance = "full"`, which use Student's t
#' with n - m - p degrees of freedom (n observations, m providers, p coefficients), as
#' pprof 1.0.3's `test()` does.
#'
#' @param model A model object, such as a [fit_logistic_fe()] fit.
#' @param test `"exact"`, `"bootstrap"`, `"score"`, or `"wald"`; `NULL` for the family's
#'   default test: `"exact"` for logistic fixed-effect models, `"wald"` for the others.
#' @param null The null value: `NULL` for the family's default (`"median"` for fixed-effect
#'   models, the median of the provider effects; 0 for random-effect models), one of the
#'   family's named options (`"median"`, and for linear fixed-effect models also `"mean"`, the
#'   mean of the provider effects weighted by provider size), or a number.
#' @param level The confidence level; alpha = 1 - `level`.
#' @param alternative `"two.sided"`, `"greater"`, or `"less"`.
#' @param providers The IDs of the providers to report, compared as character; `NULL` for
#'   all included providers.
#' @param score_type For `test = "score"`: `"modified"` or `"standard"`.
#' @param n_resamples For `test = "bootstrap"`: the number of simulated totals per provider.
#' @param data The data the model was fit to, for the standard score test when the model
#'   was fit without `keep_data = TRUE`.
#' @param threads The number of threads for the standard score test.
#'
#' @return A `pprof_provider_tests` result: a `table` with one row per provider in provider
#'   order (`provider_id`, `n_obs`, `statistic`, `p_value`, `flag`, and for the Wald test
#'   `std_error`) and the settings `test`, `level`, `alternative`, `null_value`, and
#'   `score_type` or `n_resamples` where they apply.
#' @examples
#' data(ExampleDataBinary)
#' example <- data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID,
#'                       ExampleDataBinary$Z)
#' fit <- fit_logistic_fe(y ~ z1 + z2 + z3 + z4 + z5, example, provider = "hospital")
#' tests <- test_providers(fit)
#' table(tests$table$flag)
#' @export
test_providers <- function(model, test = NULL, null = NULL, level = 0.95, alternative = "two.sided",
                           providers = NULL, score_type = "modified", n_resamples = 10000, data = NULL,
                           threads = 1) {
  profile_check_model(model)
  test <- profile_test_name(model, test)
  check_choice(test, c("exact", "bootstrap", "score", "wald"), "test")
  check_choice(score_type, c("modified", "standard"), "score_type")
  check_level(level)
  check_choice(alternative, c("two.sided", "greater", "less"), "alternative")
  check_count(n_resamples, "n_resamples")
  check_threads(threads)
  capability <- profile_test_capability(test, score_type)
  require_capability(model, capability)
  spec <- profile_family(model)
  null_value <- profile_null_value(model, spec, null)
  rows <- profile_provider_rows(model, providers)
  table <- profile_test_table(model, spec, capability, null_value, level, alternative, rows,
                              n_resamples = n_resamples, data = data, threads = threads)
  settings <- list(test = test, level = level, alternative = alternative, null_value = null_value)
  if (identical(test, "score")) settings$score_type <- score_type
  if (identical(test, "bootstrap")) settings$n_resamples <- as.integer(n_resamples)
  do.call(new_pprof_provider_tests, c(list(table), settings))
}

# The provider test: `test`, or the family's default when it is NULL (DEC-047).
profile_test_name <- function(model, test) {
  if (is.null(test)) profile_spec_option(profile_family(model), "test_default") else test
}

profile_test_capability <- function(test, score_type) {
  if (identical(test, "score")) {
    return(if (identical(score_type, "standard")) "provider_score_standard" else "provider_score")
  }
  paste0("provider_", test)
}

# The test table of the providers in `rows` for a declared test capability.
profile_test_table <- function(model, spec, capability, null_value, level, alternative, rows, n_resamples = NULL,
                               data = NULL, threads = 1L) {
  result <- switch(capability,
    provider_exact = profile_count_test(model, null_value, rows, function(observed, probabilities) {
      infer_exact_poisson_binomial(observed, probabilities, alternative)
    }),
    provider_bootstrap = profile_count_test(model, null_value, rows, function(observed, probabilities) {
      infer_exact_bootstrap(observed, probabilities, alternative, n_resamples)
    }),
    provider_score = profile_score_modified(model, null_value, alternative, rows),
    provider_score_standard = profile_score_standard(model, null_value, alternative, rows, data, threads),
    provider_wald = profile_wald_test(model, spec, null_value, alternative, rows)
  )
  decided <- infer_decide(result$probability, alternative, level)
  table <- data.frame(provider_id = provider_table(model)$provider_id[rows],
                      n_obs = provider_table(model)$n_obs[rows], statistic = unname(result$statistic),
                      p_value = unname(decided$p_value), flag = unname(decided$flag), stringsAsFactors = FALSE)
  if (!is.null(result$std_error)) table$std_error <- result$std_error
  table
}

# The exact and bootstrap tests (K-62, K-64): each provider's number of events against the
# null probabilities of its observations, clamped, one provider at a time in provider order,
# so that the bootstrap draws come from the random number stream in the reference's order.
profile_count_test <- function(model, null_value, rows, test_one) {
  observed <- observed_outcome(model)
  probabilities <- infer_clamp_probabilities(expected_outcome(model, null_value))
  results <- vapply(profile_observations(model, rows), function(r) {
    test_one(sum(observed[r]), probabilities[r])
  }, numeric(2))
  list(probability = results["probability", ], statistic = results["statistic", ])
}

# The modified score test (K-65).
profile_score_modified <- function(model, null_value, alternative, rows) {
  probabilities <- infer_clamp_probabilities(expected_outcome(model, null_value))
  statistic <- infer_score_modified(observed_outcome(model), probabilities, provider_index(model), rows)
  list(probability = infer_normal_tail(statistic, alternative), statistic = statistic)
}

# The standard score test (K-66) from the model's provider_test() method. A statistic that
# is not finite keeps its place with a missing probability, and so a missing p-value and
# flag (D-04).
profile_score_standard <- function(model, null_value, alternative, rows, data, threads) {
  result <- provider_test(model, "score_standard", null = null_value, providers = profile_positions(model, rows),
                          data = data, threads = threads)
  statistic <- result$statistic
  probability <- infer_normal_tail(statistic, alternative)
  undefined <- !is.finite(statistic)
  if (any(undefined)) {
    probability[undefined] <- NA_real_
    ids <- provider_table(model)$provider_id[rows[undefined]]
    warn_undefined_statistics(sprintf(paste(
      "The standard score statistic is not finite for %d provider(s) (%s), whose null probabilities are all",
      "close to 0 or 1; their p-values and flags are missing."
    ), length(ids), paste(ids, collapse = ", ")), providers = ids)
  }
  list(probability = probability, statistic = statistic)
}

# The Wald test (K-67 to K-70), with the family's reference distribution: normal, or t for
# linear fixed effects with the full provider variance (K-68).
profile_wald_test <- function(model, spec, null_value, alternative, rows) {
  profile_wald_caution(model, spec, rows)
  positions <- profile_positions(model, rows)
  std_error <- unname(provider_estimate_se(model))[positions]
  statistic <- infer_wald_statistic(unname(provider_estimates(model))[positions], null_value, std_error)
  wald <- profile_spec_option(spec, "wald")
  list(probability = infer_wald_tail(statistic, alternative, wald$test, wald$df), statistic = statistic,
       std_error = std_error)
}
