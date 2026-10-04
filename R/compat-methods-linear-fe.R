# Compatibility methods for the linear_fe objects of pprof 1.0.3 (ARCHITECTURE §I.2, DEC-032,
# DEC-049): each rebuilds the model from the old object, calls the new API, and returns the
# old shapes (BEHAVIOR_SPECS §7.2, §8.2, §9.2, §10, §16), building them in the reference's
# order of operations so that row names, column names, and attributes are the reference's.

#' Conduct hypothesis testing for provider effects from a fitted `linear_fe` object
#'
#' Conduct hypothesis tests on provider effects and identify outlying providers for a fixed
#' effect linear model. This is the interface of pprof 1.0.3, kept for existing code; it calls
#' [test_providers()] and returns the results in the shape of pprof 1.0.3.
#'
#' @param fit a model fitted from \code{linear_fe}.
#' @param parm specifies a subset of providers for which confidence intervals are to be given.
#' By default, all providers are included. Numeric values select numeric provider IDs; other
#' values must have the class of the provider IDs. IDs the fit does not have are ignored.
#' @param level the confidence level during the hypothesis test, meaning a significance level of \eqn{1 - \text{level}}.
#' The default value is 0.95.
#' @param null a character string or a number defining the null hypothesis for the provider effects.
#' The default value is \code{"median"}. The possible values are:
#' \itemize{
#'   \item{\code{"median"}}: The median of the provider effect estimates (\eqn{\hat{\gamma}_i}).
#'   \item{\code{"mean"}}: The weighted average of the provider effect estimates (\eqn{\hat{\gamma}_i}), where the
#'   weights correspond to the sample size of each provider.
#'   \item{numeric}: A user-defined numeric value representing the null hypothesis.
#' }
#' @param alternative a character string specifying the alternative hypothesis, must be one of
#' \code{"two.sided"} (default), \code{"greater"}, or \code{"less"}.
#' @param \dots additional arguments that can be passed to the function.
#'
#' @return A data frame containing the results of the hypothesis test, with the following columns:
#' \item{flag}{a flagging indicator where \code{1} means statistically higher than expected
#' and \code{-1} means statistically lower than expected.}
#' \item{p-value}{the p-value of the hypothesis test.}
#' \item{stat}{the test statistic.}
#' \item{Std.Error}{the standard error of the provider effect estimate.}
#'
#' @details
#' The function identifies outlying providers based on hypothesis test results.
#' For two-sided tests, \code{1} indicates performance significantly higher than expected, \code{-1} indicates lower,
#' For one-sided tests, \code{1} (right-tailed) or \code{-1} (left-tailed) flags are used.
#' Providers whose performance falls within the central range are flagged as \code{0}.
#' Outlying providers are determined by the test statistic falling beyond the threshold based on the significance
#' level \eqn{1 - \text{level}}. The test uses the normal distribution when the fit used the simplified variance of
#' the provider effects and the t distribution with n - m - p degrees of freedom when it used the full variance.
#'
#' @examples
#' data(ExampleDataLinear)
#' outcome <- ExampleDataLinear$Y
#' covar <- ExampleDataLinear$Z
#' ProvID <- ExampleDataLinear$ProvID
#' fit_linear <- linear_fe(Y = outcome, Z = covar, ProvID = ProvID)
#' test(fit_linear)
#'
#' @exportS3Method test linear_fe
test.linear_fe <- function(fit, parm, level = 0.95, null = "median", alternative = "two.sided", ...) {
  compat_linear_fe_test(fit, parm, level, null, alternative)
}

#' Calculate direct/indirect standardized differences from a fitted `linear_fe` object
#'
#' Provide direct/indirect standardized differences for a fixed effect linear model. This is
#' the interface of pprof 1.0.3, kept for existing code; it calls [standardize_providers()]
#' and returns the results in the shape of pprof 1.0.3.
#'
#' @param fit a model fitted from \code{linear_fe}.
#' @param parm specifies a subset of providers for which confidence intervals are to be given.
#' By default, all providers are included. Numeric values select numeric provider IDs; other
#' values must have the class of the provider IDs.
#' @param stdz a character string or a vector specifying the standardization method(s).
#' The possible values are:
#' \itemize{
#'   \item{\code{"indirect"}} (default) indirect standardization method.
#'   \item{\code{"direct"}} direct standardization method.
#'   \item{\code{c("indirect", "direct")}} outputs both direct and indirect standardized measures.
#' }
#' @param null a character string or a number defining the population norm.
#' The default value is \code{"median"}. The possible values are:
#' \itemize{
#'   \item{\code{"median"}} the median of the provider effect estimates (\eqn{\hat{\gamma}_i}).
#'   \item{\code{"mean"}} the weighted average of the provider effect estimates (\eqn{\hat{\gamma}_i}), where the
#'   weights correspond to the sample size of each provider.
#'   \item{numeric} a user-defined numeric value representing the population norm.
#' }
#' @param \dots additional arguments that can be passed to the function.
#'
#' @return A list containing the standardized differences based on the method(s) specified in `stdz`,
#' as well as the observed and expected outcomes used to calculate the standardized measures:
#' \item{indirect.difference}{indirect standardized differences, if `stdz` includes \code{"indirect"}.}
#' \item{direct.difference}{direct standardized differences, if `stdz` includes \code{"direct"}.}
#' \item{OE}{a list of data frames containing the observed and expected outcomes used for calculating standardized
#'   measures.}
#'
#' @details
#' This function computes standardized differences for a fixed effect linear model
#' using either direct or indirect methods, or both when specified.
#' For each method, the population norm is determined by the `null` argument.
#' The population norm can be the median of the estimates, their weighted mean
#' (with weights corresponding to provider sizes), or a user-defined numeric value.
#'
#' @examples
#' data(ExampleDataLinear)
#' outcome <- ExampleDataLinear$Y
#' covar <- ExampleDataLinear$Z
#' ProvID <- ExampleDataLinear$ProvID
#' fit_linear <- linear_fe(Y = outcome, Z = covar, ProvID = ProvID)
#' SM_output(fit_linear)
#' SM_output(fit_linear, stdz = "direct", null = "mean")
#'
#' @exportS3Method SM_output linear_fe
SM_output.linear_fe <- function(fit, parm, stdz = "indirect", null = "median", ...) { # nolint: object_name_linter.
  compat_linear_fe_sm_output(fit, parm, stdz, null)
}

#' Get confidence intervals for provider effects or standardized measures from a fitted `linear_fe` object
#'
#' Provide confidence intervals for provider effects or standardized measures from a fixed
#' effect linear model. This is the interface of pprof 1.0.3, kept for existing code; it
#' calls [provider_effects()] or [standardize_providers()] and returns the results in the shape
#' of pprof 1.0.3.
#'
#' @param object a model fitted from \code{linear_fe}.
#' @param parm specify a subset of providers for which confidence intervals are given.
#' By default, all providers are included. Numeric values select numeric provider IDs; other
#' values must have the class of the provider IDs.
#' @param level the confidence level. The default value is 0.95.
#' @param option 	a character string specifying whether the confidence intervals
#' should be provided for provider effects or standardized measures:
#'   \itemize{
#'   \item {\code{"gamma"}} provider effect (only supports \code{"two.sided"} confidence interval).
#'   \item {\code{"SM"}} standardized measures.
#'   }
#' @param stdz a character string or a vector specifying the standardization method
#' if `option` includes \code{"SM"}. See `stdz` argument in \code{\link{SM_output.linear_fe}}.
#' @param null a character string or a number specifying the population norm for calculating standardized measures
#' if `option` includes \code{"SM"}. See `null` argument in \code{\link{SM_output.linear_fe}}.
#' @param alternative a character string specifying the alternative hypothesis, must be one of
#' \code{"two.sided"} (default), \code{"greater"}, or \code{"less"}.
#' Note that \code{"gamma"} for argument `option` only supports \code{"two.sided"}.
#' @param \dots additional arguments that can be passed to the function.
#'
#' @details
#' The intervals use the t distribution with n - m - p degrees of freedom when the fit used the
#' simplified variance of the provider effects and the normal distribution when it used the full
#' variance, the reverse of \code{\link{test.linear_fe}}, as in pprof 1.0.3 (this is awaiting a
#' decision of the methodology owners).
#'
#' @return A list of data frames containing the confidence intervals based on the values of `option` and `stdz`.
#' \item{CI.gamma}{Confidence intervals for provider effects if `option` includes \code{"gamma"}.}
#' \item{CI.indirect}{Confidence intervals for indirect standardized differences if `option` includes \code{"SM"}
#'   and `stdz` includes \code{"indirect"}.}
#' \item{CI.direct}{Confidence intervals for direct standardized differences if `option` includes \code{"SM"} and
#'   `stdz` includes \code{"direct"}.}
#'
#' @examples
#' data(ExampleDataLinear)
#' outcome <- ExampleDataLinear$Y
#' covar <- ExampleDataLinear$Z
#' ProvID <- ExampleDataLinear$ProvID
#' fit_linear <- linear_fe(Y = outcome, Z = covar, ProvID = ProvID)
#' confint(fit_linear)
#'
#' @exportS3Method confint linear_fe
confint.linear_fe <- function(object, parm, level = 0.95, option = "SM", stdz = "indirect",
                              null = "median", alternative = "two.sided", ...) {
  compat_linear_fe_confint(object, parm, level, option, stdz, null, alternative)
}

#' Result Summaries of Covariate Estimates from a fitted `linear_fe`, `linear_re` or `linear_cre` object
#'
#' Provide the summary statistics for the covariate estimates for a fixed/random/correlated
#' random effect linear model. This is the interface of pprof 1.0.3, kept for existing code; it
#' calls [test_coefficients()] and returns the results in the shape of pprof 1.0.3.
#'
#' @param object a model fitted from \code{linear_fe} or \code{linear_re} or \code{linear_cre}.
#' @param parm specifies a subset of covariates for which the result summaries should be output.
#' By default, all covariates are included. For \code{linear_re} and \code{linear_cre} fits, whose
#' summaries include the intercept, the intercept is selected by the name \code{"(intercept)"}, in
#' lower case, although its row is named \code{"(Intercept)"}.
#' @param level the confidence level during the hypothesis test, meaning a significance level of \eqn{1 - \text{level}}.
#' The default value is 0.95.
#' @param null a number defining the null hypothesis for the covariate estimates. The default value is \code{0}.
#' @param \dots additional arguments that can be passed to the function.
#'
#' @return A data frame containing summary statistics for covariate estimates, with the following columns:
#' \item{Estimate}{the estimates of covariate coefficients.}
#' \item{Std.Error}{the standard error of the estimate.}
#' \item{Stat}{the test statistic.}
#' \item{p value}{the p-value for the hypothesis test.}
#' \item{CI.upper}{the lower bound of the confidence interval.}
#' \item{CI.lower}{the upper bound of the confidence interval.}
#'
#' @examples
#' data(ExampleDataLinear)
#' outcome <- ExampleDataLinear$Y
#' covar <- ExampleDataLinear$Z
#' ProvID <- ExampleDataLinear$ProvID
#' fit_fe <- linear_fe(Y = outcome, Z = covar, ProvID = ProvID)
#' summary(fit_fe)
#'
#' @exportS3Method summary linear_fe
summary.linear_fe <- function(object, parm, level = 0.95, null = 0, ...) {
  compat_linear_fe_summary(object, parm, level, null)
}

# test.linear_fe() (R/test.linear_fe.R in pprof 1.0.3): the Wald test with the normal
# distribution for the simplified provider variance and t(n - m - p) for the full one (K-68).
compat_linear_fe_test <- function(fit, parm, level = 0.95, null = "median", alternative = "two.sided") {
  null_value <- compat_linear_null(null)
  compat_check_alternative(alternative, "Argument 'alternative' should be one of 'two.sided', 'less', 'greater'")
  model <- compat_model_from_linear_fe(fit, require_variance_type = TRUE)
  table <- test_providers(model, "wald", null = null_value, level = level, alternative = alternative)$table
  compat_wald_test_result(table, fit, parm)
}

# SM_output.linear_fe() (R/SM_output.linear_fe.R): the indirect and direct differences
# (K-83) with the observed and expected outcomes. The direct OE table has the automatic row
# names of data.frame(), as in the reference.
compat_linear_fe_sm_output <- function(fit, parm, stdz = "indirect", null = "median") {
  compat_check_object(fit, missing(fit), "fit", "linear_fe")
  compat_check_stdz(stdz)
  ind <- compat_parm_rows(fit, parm, "Argument 'parm' includes invalid elements.")
  null_value <- compat_linear_null(null)
  model <- compat_model_from_linear_fe(fit)
  ids <- compat_provider_labels(fit)
  methods <- c("indirect", "direct")[c("indirect" %in% stdz, "direct" %in% stdz)]
  measures <- standardize_providers(model, methods, "difference", null = null_value)$table
  return_list <- list()
  oe_list <- list()
  if ("indirect" %in% methods) {
    rows <- compat_measure_rows(measures, "indirect", "difference")
    return_list$indirect.difference <- compat_measure_matrix(rows$estimate, ids, "Indirect_standardized.difference",
                                                             ind)
    oe <- data.frame(Obs = stats::setNames(rows$observed, ids), Exp = stats::setNames(rows$expected, ids))
    oe_list$OE_indirect <- oe[ind, ]
  }
  if ("direct" %in% methods) {
    rows <- compat_measure_rows(measures, "direct", "difference")
    return_list$direct.difference <- compat_measure_matrix(rows$estimate, ids, "Direct_standardized.difference", ind)
    oe <- data.frame(Obs = rows$observed[1], Exp = rows$expected)
    oe_list$OE_direct <- oe[ind, ]
  }
  return_list$OE <- oe_list
  return_list
}

# An m x 1 matrix of the reference's standardized measures, named by provider and measure,
# with the rows `ind`.
compat_measure_matrix <- function(values, ids, column, ind) {
  out <- matrix(values)
  dimnames(out) <- list(ids, column)
  out[ind, , drop = FALSE]
}

# confint.linear_fe() (R/confint.linear_fe.R): Wald intervals for the provider effects
# (`option = "gamma"`, two-sided) or for the standardized differences, with t(n - m - p)
# for the simplified provider variance and the normal distribution for the full one, the
# reverse of the tests (K-92, D-32, awaiting sign-off).
compat_linear_fe_confint <- function(object, parm, level = 0.95, option = "SM", stdz = "indirect", null = "median",
                                     alternative = "two.sided") {
  compat_check_object(object, missing(object), "object", "linear_fe")
  if (!(identical(option, "gamma") || identical(option, "SM"))) {
    abort_invalid_input("Argument 'option' should be 'gamma' or 'SM'", arg = "option")
  }
  compat_check_stdz(stdz)
  if (identical(option, "gamma") && !identical(alternative, "two.sided")) {
    abort_invalid_input("Provider effect (option = 'gamma') only supports two-sided confidence intervals.",
                        arg = "alternative")
  }
  compat_check_alternative(alternative, "Argument 'alternative' should be one of 'two.sided', 'less', 'greater'.")
  model <- compat_model_from_linear_fe(object, require_variance_type = TRUE)
  ids <- compat_provider_labels(object)
  ind <- compat_parm_rows(object, parm, "Argument 'parm' includes invalid elements.")
  if (identical(option, "gamma")) {
    table <- provider_effects(model, interval = "wald", level = level)$table
    out <- data.frame(gamma = table$estimate, gamma.Lower = table$lower, gamma.Upper = table$upper, row.names = ids)
    colnames(out) <- c("gamma", "gamma.Lower", "gamma.Upper")
    attr(out, "description") <- "Provider Effects"
    return(out[ind, ])
  }
  null_value <- compat_linear_null(null)
  methods <- c("indirect", "direct")[c("indirect" %in% stdz, "direct" %in% stdz)]
  measures <- standardize_providers(model, methods, "difference", null = null_value, interval = "wald", level = level,
                                    alternative = alternative)$table
  return_list <- list()
  for (method in methods) {
    rows <- compat_measure_rows(measures, method, "difference")
    title <- paste0(toupper(substr(method, 1L, 1L)), substring(method, 2L))
    out <- data.frame(SM = rows$estimate, Lower = rows$lower, Upper = rows$upper, row.names = ids)
    colnames(out) <- c(paste0(title, ".Difference"), paste0(method, ".Lower"), paste0(method, ".Upper"))
    attr(out, "confidence_level") <- paste(level * 100, "%")
    attr(out, "type") <- compat_interval_type(alternative)
    attr(out, "description") <- paste(title, "Standardized Difference")
    attr(out, "model") <- "FE linear"
    return_list[[paste0("CI.", method)]] <- out[ind, ]
  }
  return_list
}

# summary.linear_fe() (R/summary.linear_fe.R): t tests and intervals with n - p - m degrees
# of freedom (K-103).
compat_linear_fe_summary <- function(object, parm, level = 0.95, null = 0) {
  compat_check_object(object, missing(object), "object", "linear_fe")
  model <- compat_model_from_linear_fe(object)
  out <- compat_summary_table(test_coefficients(model, "wald", level = level, null = null)$table)
  out[compat_summary_rows(parm, object$char_list$Z.char), ]
}
