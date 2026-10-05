# Tests and intervals for covariate coefficients (K-100 to K-105).

# The help below states the family rules K-100 (logistic FE Wald), K-101 and K-102 (LR and
# score, with D-10's refits at the default settings), K-103 (linear FE), K-104 (linear RE
# and CRE), and K-105 (logistic RE and CRE, whose p-value keeps D-31, awaiting sign-off).
#' Tests of the covariate coefficients
#'
#' Tests each covariate coefficient of a model against `null`. The Wald test is available
#' for every family, with the family's rule as in pprof 1.0.3's `summary()`; the
#' likelihood-ratio and score tests for logistic fixed-effect and Firth models only.
#'
#' Wald tests and intervals of the other families, with alpha = 1 - `level`:
#'
#' - linear fixed effects: p-value 2 (1 - pt(|z|, n - m - p)), interval
#'   beta -/+ qt(1 - alpha / 2, n - m - p) se, for n observations, m providers, and p
#'   coefficients;
#' - linear random and correlated random effects, intercept included: p-value
#'   2 (1 - pt(|z|, n - p - m + 1)) with p counting the intercept, and lme4's Wald interval
#'   beta + se qnorm(a) at a = alpha / 2 and 1 - alpha / 2;
#' - logistic random and correlated random effects, intercept included: p-value
#'   2 (1 - pnorm(z)), as in pprof 1.0.3, which exceeds 1 for negative estimates, and lme4's
#'   Wald interval.
#'
#' For logistic fixed-effect models:
#'
#' - `"wald"`: z = (beta - null) / se with the standard error from [vcov()], the two-sided
#'   p-value 2 (1 - pnorm(|z|)), and the interval beta -/+ qnorm(1 - alpha / 2) se with
#'   alpha = 1 - `level`;
#' - `"lr"`: the likelihood-ratio statistic: the null model without the covariate is
#'   refit, and the statistic is the difference of the two -2 log-likelihoods, computed
#'   with provider effects clamped to within 10 of their median; chi-square p-value with
#'   one degree of freedom;
#' - `"score"`: the score of the covariate at the null fit divided by its efficient
#'   information; chi-square p-value with one degree of freedom.
#'
#' As in pprof 1.0.3, the null model of the likelihood-ratio and score tests is refit with
#' the default settings of [fit_logistic_fe()] (SerBIN, `tol = 1e-5`, `stop_rule = "any"`,
#' `effect_bound = 10`, `min_provider_size = 10`), whatever settings the model used; it
#' fails with a `pprof_error_data` condition when that minimum provider size would exclude
#' providers that the model includes. These two tests test against 0 only, and need the
#' covariates: the model must have been fit with `keep_data = TRUE`, or `data` must be the
#' data it was fit to. A model with one covariate has no null model for them.
#'
#' @param model A model object.
#' @param test `"wald"`, `"lr"`, or `"score"`.
#' @param parm The coefficients to test, by name or position; `NULL` for all.
#' @param level The confidence level of the Wald intervals.
#' @param null The value of the coefficients under the null hypothesis.
#' @param data The data the model was fit to, when the test needs the covariates and the
#'   model does not keep them.
#'
#' @return A `pprof_coefficient_tests` result: a `table` with one row per coefficient
#'   (`term`, `estimate`, `statistic`, `p_value`, and for the Wald test `std_error`,
#'   `lower`, and `upper`) and the settings `test`, `level`, and `null_value`.
#' @family covariate inference
#' @examples
#' data(ExampleDataBinary)
#' example <- data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID,
#'                       ExampleDataBinary$Z)
#' fit <- fit_logistic_fe(y ~ z1 + z2 + z3 + z4 + z5, example, provider = "hospital")
#' test_coefficients(fit)$table
#' # The likelihood-ratio test refits the model without each covariate, so it needs the data.
#' test_coefficients(fit, test = "lr", data = example)$table
#' @export
test_coefficients <- function(model, test = "wald", parm = NULL, level = 0.95, null = 0, data = NULL) {
  if (!inherits(model, "pprof_model")) {
    abort_invalid_input("`model` must be a pprof model object.", arg = "model")
  }
  check_choice(test, c("wald", "lr", "score"), "test")
  check_level(level)
  check_number(null, "null")
  require_capability(model, paste0("coef_", test))
  terms <- infer_coefficient_terms(model, parm)
  table <- switch(test,
    wald = infer_coefficient_wald(model, terms, level, null),
    lr = infer_coefficient_lr(model, terms, null, data),
    score = infer_coefficient_score(model, terms, null, data)
  )
  new_pprof_coefficient_tests(table, test = test, level = level, null_value = as.double(null))
}

#' Confidence intervals for the covariate coefficients
#'
#' Wald intervals for the covariate coefficients with the family's rule, as the summaries of
#' pprof 1.0.3 report them, with alpha = 1 - `level`: beta -/+ qnorm(1 - alpha / 2) se for
#' logistic fixed-effect and Firth models; beta -/+ qt(1 - alpha / 2, n - m - p) se for
#' linear fixed-effect models (n observations, m providers, p coefficients); and lme4's Wald
#' intervals, beta + se qnorm(a) with a = alpha / 2 and 1 - alpha / 2, for random-effect and
#' correlated random-effect models, intercept included. Models whose class declares no Wald
#' inference for coefficients raise `pprof_error_unsupported_inference`. Intervals for
#' provider effects and standardized measures come from [provider_effects()] and
#' [standardize_providers()].
#'
#' @param object A model object.
#' @param parm The coefficients, by name or position; all when missing.
#' @param level The confidence level.
#' @param ... Not used.
#'
#' @return A matrix with one row per coefficient and the lower and upper limits.
#' @family covariate inference
#' @examples
#' data(ExampleDataBinary)
#' example <- data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID,
#'                       ExampleDataBinary$Z)
#' fit <- fit_logistic_fe(y ~ z1 + z2 + z3 + z4 + z5, example, provider = "hospital")
#' confint(fit)
#' confint(fit, parm = "z1", level = 0.9)
#' @importFrom stats confint
#' @export
confint.pprof_model <- function(object, parm, level = 0.95, ...) {
  # Without this method, stats::confint.default() would compute normal intervals from
  # coef() and vcov() for any model, whatever rule its family uses (DEC-040).
  require_capability(object, "coef_wald")
  check_level(level)
  terms <- infer_coefficient_terms(object, if (missing(parm)) NULL else parm)
  table <- infer_coefficient_wald(object, terms, level, 0)
  alpha <- 1 - level
  percent <- paste(format(100 * c(alpha / 2, 1 - alpha / 2), trim = TRUE, scientific = FALSE, digits = 3), "%")
  matrix(c(table$lower, table$upper), ncol = 2L, dimnames = list(table$term, percent))
}

# The names of the coefficients `parm` selects: names, kept in the order of the model, or
# positions, kept in the order given (R/summary.logis_fe.R:54-61).
infer_coefficient_terms <- function(model, parm) {
  terms <- names(stats::coef(model))
  if (is.null(parm)) return(terms)
  if (is.character(parm) && !anyNA(parm)) {
    unknown <- setdiff(parm, terms)
    if (length(unknown) > 0L) {
      abort_invalid_input(sprintf("`parm` names coefficients the model does not have: %s.",
                                  paste(unknown, collapse = ", ")), arg = "parm")
    }
    return(terms[terms %in% parm])
  }
  if (is.numeric(parm) && !anyNA(parm) && all(parm == round(parm)) && all(parm >= 1 & parm <= length(terms))) {
    return(terms[parm])
  }
  abort_invalid_input("`parm` must name coefficients or give their positions.", arg = "parm")
}

# The covariate Wald rule of a model's family (`coefficient_wald` in its family
# specification, DEC-046): `p_value`, "two_sided" for 2 (1 - F(|z|)) or "upper_doubled" for
# 2 (1 - F(z)); `p_value_distribution`, "normal" or "t"; `interval`, "critical" for
# beta -/+ q(1 - alpha / 2) se or "quantile" for lme4's beta + se q(a); `interval_distribution`;
# and `df` for t. A family that sets none has the rule of logistic fixed effects (K-100).
infer_coefficient_default_rule <- list(p_value = "two_sided", p_value_distribution = "normal", interval = "critical",
                                       interval_distribution = "normal", df = NULL)

infer_coefficient_rule <- function(model) {
  rule <- profile_spec(model)$coefficient_wald
  if (is.null(rule)) infer_coefficient_default_rule else rule
}

# The covariate Wald tests and intervals with the family's rule: K-100 (R/summary.logis_fe.R:63-98), K-103
# (R/summary.linear_fe.R:47-52), K-104 (R/summary.linear_re.R:25-35), and K-105
# (R/summary.logis_re.R:45-50), whose p-values are 2 (1 - pnorm(z)) without abs() (D-31,
# reproduced until the methodology owners decide). lme4's intervals are computed from the
# coefficients and their covariance with lme4's expression, which equals
# confint(method = "Wald") bitwise.
infer_coefficient_wald <- function(model, terms, level, null) {
  rule <- infer_coefficient_rule(model)
  alpha <- 1 - level
  estimate <- stats::coef(model)
  std_error <- sqrt(diag(stats::vcov(model)))
  statistic <- (estimate - null) / std_error
  p_value <- switch(rule$p_value,
    two_sided = 2 * (1 - infer_cdf(abs(statistic), rule$p_value_distribution, rule$df)),
    upper_doubled = 2 * (1 - infer_cdf(statistic, rule$p_value_distribution, rule$df))
  )
  limits <- if (identical(rule$interval, "quantile")) {
    a <- (1 - level) / 2
    a <- c(a, 1 - a)
    estimate + std_error %o% infer_quantile(a, rule$interval_distribution, rule$df)
  } else {
    critical <- infer_quantile(1 - alpha / 2, rule$interval_distribution, rule$df)
    cbind(estimate - critical * std_error, estimate + critical * std_error)
  }
  table <- data.frame(
    term = names(estimate), estimate = unname(estimate), std_error = unname(std_error),
    statistic = unname(statistic), p_value = unname(p_value), lower = unname(limits[, 1]),
    upper = unname(limits[, 2]), stringsAsFactors = FALSE
  )
  table[match(terms, table$term), , drop = FALSE]
}

infer_require_null_zero <- function(null) {
  if (null != 0) {
    abort_invalid_input("The likelihood-ratio and score tests test against `null = 0` only.", arg = "null")
  }
}

# K-101 (R/summary.logis_fe.R:135-169): -2 log-likelihoods with provider effects clamped to
# median -/+ lr_effect_clamp in both models; each null model is fit once.
infer_coefficient_lr <- function(model, terms, null, data) {
  infer_require_null_zero(null)
  full <- infer_clamped_neg2_loglik(model)
  statistic <- vapply(terms, function(term) {
    infer_clamped_neg2_loglik(refit_without(model, term, data)) - full
  }, numeric(1), USE.NAMES = FALSE)
  data.frame(term = terms, estimate = unname(stats::coef(model)[terms]), statistic = statistic,
             p_value = stats::pchisq(statistic, 1, lower.tail = FALSE), stringsAsFactors = FALSE)
}

infer_clamped_neg2_loglik <- function(model) {
  effects <- unname(provider_estimates(model))
  centre <- stats::median(effects)
  clamped <- pmax(pmin(effects, centre + lr_effect_clamp), centre - lr_effect_clamp)
  eta <- infer_observation_values(model, clamped) + linear_predictor(model)
  -2 * sum(eta * observed_outcome(model) - log(1 + exp(eta)))
}

# K-102 (R/summary.logis_fe.R:170-205): the score of the added covariate at the null fit
# and its efficient information from the block inverse of the null model's information,
# with probabilities clamped to [probability_clamp, 1 - probability_clamp]. The expressions
# are the reference's, so that the statistics are bitwise identical.
infer_coefficient_score <- function(model, terms, null, data) {
  infer_require_null_zero(null)
  design <- model_prepared_data(model, data)$design
  response <- observed_outcome(model)
  index <- provider_index(model)
  providers <- which(provider_table(model)$included)
  rows <- split(seq_along(index), data_provider_factor(index, providers))
  statistic <- vapply(terms, function(term) {
    null_model <- refit_without(model, term, data)
    z_null <- design[, setdiff(colnames(design), term), drop = FALSE]
    z_add <- design[, term]
    gamma_obs <- infer_observation_values(null_model, unname(provider_estimates(null_model)))
    probs <- as.numeric(stats::plogis(gamma_obs + z_null %*% unname(stats::coef(null_model))))
    probs <- pmin(pmax(probs, probability_clamp), 1 - probability_clamp)
    weighted <- probs * (1 - probs) * z_null
    info_gamma_inv <- 1 / data_provider_sums(probs * (1 - probs), index, providers)
    info_beta_gamma <- matrix(vapply(rows, function(r) colSums(weighted[r, , drop = FALSE]), numeric(ncol(z_null))),
                              nrow = ncol(z_null))
    info_beta <- t(z_null) %*% (probs * (1 - probs) * z_null)
    mat_tmp <- info_gamma_inv * t(info_beta_gamma)
    schur_inv <- solve(info_beta - info_beta_gamma %*% mat_tmp)
    info_inv_11 <- mat_tmp %*% schur_inv %*% t(mat_tmp)
    diag(info_inv_11) <- diag(info_inv_11) + info_gamma_inv
    info_inv_21 <- -schur_inv %*% t(mat_tmp)
    add_gamma <- data_provider_sums(probs * (1 - probs) * z_add, index, providers)
    add_beta <- t(as.matrix(z_add)) %*% (probs * (1 - probs) * z_null)
    info_add <- t(z_add) %*% (probs * (1 - probs) * z_add) - t(add_gamma) %*% info_inv_11 %*% add_gamma -
      2 * add_beta %*% info_inv_21 %*% add_gamma - add_beta %*% schur_inv %*% t(add_beta)
    score_add <- t(as.matrix(z_add)) %*% (response - probs)
    drop(score_add^2 / info_add)
  }, numeric(1), USE.NAMES = FALSE)
  data.frame(term = terms, estimate = unname(stats::coef(model)[terms]), statistic = statistic,
             p_value = stats::pchisq(statistic, 1, lower.tail = FALSE), stringsAsFactors = FALSE)
}

# One value per observation from one value per included provider, through the contract
# (provider_table(), provider_index()).
infer_observation_values <- function(model, values) {
  included <- which(provider_table(model)$included)
  values[match(provider_index(model), included)]
}
