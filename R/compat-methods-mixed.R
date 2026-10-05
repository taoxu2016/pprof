# Compatibility methods for the linear_re, logis_re, linear_cre, and logis_cre objects of
# pprof 1.0.3 (ARCHITECTURE §I.2, DEC-032, DEC-049): one implementation per method for the
# four classes, which rebuilds the model from the old object, calls the new API, and returns
# the old shapes (BEHAVIOR_SPECS §7.3, §8.3, §8.4, §9.3, §9.4, §10, §16), built in the
# reference's order of operations. The labels of each class are those of the reference,
# including its inconsistencies (D-33).

# --- test() ---------------------------------------------------------------------------------

#' Conduct hypothesis testing for provider effects from a fitted `linear_re` object
#'
#' Conduct hypothesis tests on provider effects and identify outlying providers for a random
#' effect linear model. This is the interface of pprof 1.0.3, kept for existing code; it calls
#' [test_providers()] and returns the results in the shape of pprof 1.0.3.
#'
#' @param fit a model fitted from \code{linear_re}.
#' @param parm specifies a subset of providers for which confidence intervals are to be given.
#' By default, all providers are included. Numeric values select numeric provider IDs; other
#' values must have the class of the provider IDs. IDs the fit does not have are ignored.
#' @param level the confidence level during the hypothesis test, meaning a significance level of \eqn{1 - \text{level}}.
#' The default value is 0.95.
#' @param null a number defining the null hypothesis for the provider effects.
#' The default value is 0.
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
#' level \eqn{1 - \text{level}}.
#'
#' @examples
#' data(ExampleDataLinear)
#' outcome <- ExampleDataLinear$Y
#' ProvID <- ExampleDataLinear$ProvID
#' covar <- ExampleDataLinear$Z
#' fit_re <- linear_re(Y = outcome, Z = covar, ProvID = ProvID)
#' test(fit_re)
#'
#' @exportS3Method test linear_re
test.linear_re <- function(fit, parm, level = 0.95, null = 0, alternative = "two.sided", ...) {
  compat_mixed_test(fit, parm, level, null, alternative)
}

#' Conduct hypothesis testing for provider effects from a fitted `logis_re` object
#'
#' Conduct hypothesis tests on provider effects and identify outlying providers for a random
#' effect logistic model. This is the interface of pprof 1.0.3, kept for existing code; it calls
#' [test_providers()] and returns the results in the shape of pprof 1.0.3.
#'
#' @inheritParams test.linear_re
#' @param fit a model fitted from \code{logis_re}.
#' @inherit test.linear_re return details
#'
#' @examples
#' data(ExampleDataBinary)
#' outcome <- ExampleDataBinary$Y
#' covar <- ExampleDataBinary$Z
#' ProvID <- ExampleDataBinary$ProvID
#' fit_re <- logis_re(Y = outcome, Z = covar, ProvID = ProvID)
#' test(fit_re)
#'
#' @exportS3Method test logis_re
test.logis_re <- function(fit, parm, level = 0.95, null = 0, alternative = "two.sided", ...) {
  compat_mixed_test(fit, parm, level, null, alternative)
}

#' Conduct hypothesis testing for provider effects from a fitted `linear_cre` object
#'
#' Conduct hypothesis tests on provider effects and identify outlying providers for a correlated
#' random effect linear model. This is the interface of pprof 1.0.3, kept for existing code; it
#' calls [test_providers()] and returns the results in the shape of pprof 1.0.3.
#'
#' @inheritParams test.linear_re
#' @param fit a model fitted from \code{linear_cre}.
#' @inherit test.linear_re return details
#'
#' @examples
#' data(ExampleDataLinear)
#' outcome <- ExampleDataLinear$Y
#' covar <- ExampleDataLinear$Z
#' ProvID <- ExampleDataLinear$ProvID
#' data <- data.frame(outcome, ProvID, covar)
#' outcome.char <- colnames(data)[1]
#' ProvID.char <- colnames(data)[2]
#' wb.char <- c("z1", "z2")
#' other.char <- c("z3", "z4", "z5")
#' fit_cre <- linear_cre(data = data, Y.char = outcome.char, ProvID.char = ProvID.char,
#' wb.char = wb.char, other.char = other.char)
#' test(fit_cre)
#'
#' @exportS3Method test linear_cre
test.linear_cre <- function(fit, parm, level = 0.95, null = 0, alternative = "two.sided", ...) {
  compat_mixed_test(fit, parm, level, null, alternative)
}

#' Conduct hypothesis testing for provider effects from a fitted `logis_cre` object
#'
#' Conduct hypothesis tests on provider effects and identify outlying providers for a correlated
#' random effect logistic model. This is the interface of pprof 1.0.3, kept for existing code;
#' it calls [test_providers()] and returns the results in the shape of pprof 1.0.3.
#'
#' @inheritParams test.linear_re
#' @param fit a model fitted from \code{logis_cre}.
#' @inherit test.linear_re return details
#'
#' @examples
#' data(ExampleDataBinary)
#' outcome <- ExampleDataBinary$Y
#' covar <- ExampleDataBinary$Z
#' ProvID <- ExampleDataBinary$ProvID
#' data <- data.frame(outcome, ProvID, covar)
#' outcome.char <- colnames(data)[1]
#' ProvID.char <- colnames(data)[2]
#' wb.char <- c("z1", "z2")
#' other.char <- c("z3", "z4", "z5")
#' fit_cre <- logis_cre(data = data, Y.char = outcome.char, ProvID.char = ProvID.char,
#' wb.char = wb.char, other.char = other.char)
#' test(fit_cre)
#'
#' @exportS3Method test logis_cre
test.logis_cre <- function(fit, parm, level = 0.95, null = 0, alternative = "two.sided", ...) {
  compat_mixed_test(fit, parm, level, null, alternative)
}

# --- SM_output() -----------------------------------------------------------------------------

#' Calculate direct/indirect standardized differences from a fitted `linear_re` object
#'
#' Provide direct/indirect standardized differences for a random effect linear model. This is
#' the interface of pprof 1.0.3, kept for existing code; it calls [standardize_providers()] and
#' returns the results in the shape of pprof 1.0.3.
#'
#' @param fit a model fitted from \code{linear_re}.
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
#' This function computes standardized differences for a random effect linear model
#' using either direct or indirect methods, or both when specified.
#' The function returns both the standardized differences and the observed and expected outcomes
#' used for their calculation. The indirect difference of a provider compares the sum of the
#' fitted values, which include the provider's estimated effect, with the sum of the expected
#' outcomes without a provider effect.
#'
#' @examples
#' data(ExampleDataLinear)
#' outcome <- ExampleDataLinear$Y
#' covar <- ExampleDataLinear$Z
#' ProvID <- ExampleDataLinear$ProvID
#' fit_linear <- linear_re(Y = outcome, Z = covar, ProvID = ProvID)
#' SM_output(fit_linear)
#'
#' @exportS3Method SM_output linear_re
SM_output.linear_re <- function(fit, parm, stdz = "indirect", ...) { # nolint: object_name_linter.
  compat_mixed_sm_output(fit, parm, stdz, class = "linear_re")
}

#' Calculate direct/indirect standardized differences from a fitted `linear_cre` object
#'
#' Provide direct/indirect standardized differences for a correlated random effect linear
#' model. This is the interface of pprof 1.0.3, kept for existing code; it calls
#' [standardize_providers()] and returns the results in the shape of pprof 1.0.3.
#'
#' @inheritParams SM_output.linear_re
#' @param fit a model fitted from \code{linear_cre}.
#' @inherit SM_output.linear_re return details
#'
#' @examples
#' data(ExampleDataLinear)
#' outcome <- ExampleDataLinear$Y
#' covar <- ExampleDataLinear$Z
#' ProvID <- ExampleDataLinear$ProvID
#' data <- data.frame(outcome, ProvID, covar)
#' outcome.char <- colnames(data)[1]
#' ProvID.char <- colnames(data)[2]
#' wb.char <- c("z1", "z2")
#' other.char <- c("z3", "z4", "z5")
#' fit_cre <- linear_cre(data = data, Y.char = outcome.char, ProvID.char = ProvID.char,
#' wb.char = wb.char, other.char = other.char)
#' SM_output(fit_cre)
#'
#' @exportS3Method SM_output linear_cre
SM_output.linear_cre <- function(fit, parm, stdz = "indirect", ...) { # nolint: object_name_linter.
  compat_mixed_sm_output(fit, parm, stdz, class = "linear_cre")
}

#' Calculate direct/indirect standardized ratios/rates from a fitted `logis_re` object
#'
#' Provide direct/indirect standardized ratios/rates for a random effect logistic model. This
#' is the interface of pprof 1.0.3, kept for existing code; it calls [standardize_providers()]
#' and returns the results in the shape of pprof 1.0.3.
#'
#' @param fit a model fitted from \code{logis_re}.
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
#' @param measure a character string or a vector indicating whether the output measure is "ratio" or "rate"
#' \itemize{
#'   \item{\code{"rate"}} output the standardized rate. The "rate" has been restricted to 0% - 100%.
#'   \item{\code{"ratio"}} output the standardized ratio.
#'   \item{\code{c("ratio", "rate")}} (default) output both the ratio and rate.
#' }
#' @param threads an integer specifying the number of threads to use. The default value is 2.
#' @param \dots additional arguments that can be passed to the function.
#'
#' @return A list contains standardized measures, as well as the observed and expected outcomes used for calculation,
#' depending on the user's choice of standardization method (`stdz`) and measure type (`measure`).
#' \item{indirect.ratio}{standardization ratio using indirect method if `stdz` includes \code{"indirect"} and
#'   `measure` includes \code{"ratio"}.}
#' \item{direct.ratio}{standardization ratio using direct method if `stdz` includes \code{"direct"} and `measure`
#'   includes \code{"ratio"}.}
#' \item{indirect.rate}{standardization rate using indirect method if `stdz` includes \code{"indirect"} and
#'   `measure` includes \code{"rate"}.}
#' \item{direct.rate}{standardization rate using direct method if `stdz` includes \code{"direct"} and `measure`
#'   includes \code{"rate"}.}
#' \item{OE}{a list of data frames containing the observed and expected outcomes used for calculating standardized
#'   measures.}
#'
#' @details
#' The indirect ratio of a provider is the sum of its fitted probabilities, which include the
#' provider's estimated effect, over the sum of the probabilities expected without a provider
#' effect.
#'
#' @examples
#' data(ExampleDataBinary)
#' outcome = ExampleDataBinary$Y
#' covar = ExampleDataBinary$Z
#' ProvID = ExampleDataBinary$ProvID
#' fit_re <- logis_re(Y = outcome, Z = covar, ProvID = ProvID)
#' SR <- SM_output(fit_re, stdz = "direct", measure = "rate")
#' SR$direct.rate
#'
#' @exportS3Method SM_output logis_re
SM_output.logis_re <- function(fit, parm, stdz = "indirect", measure = c("rate", "ratio"), # nolint: object_name_linter.
                               threads = 2, ...) {
  compat_mixed_sm_output(fit, parm, stdz, measure, threads, class = "logis_re")
}

#' Calculate direct/indirect standardized ratios/rates from a fitted `logis_cre` object
#'
#' Provide direct/indirect standardized ratios/rates for a correlated random effect logistic
#' model. This is the interface of pprof 1.0.3, kept for existing code; it calls
#' [standardize_providers()] and returns the results in the shape of pprof 1.0.3.
#'
#' @inheritParams SM_output.logis_re
#' @param fit a model fitted from \code{logis_cre}.
#' @inherit SM_output.logis_re return details
#'
#' @examples
#' data(ExampleDataBinary)
#' outcome <- ExampleDataBinary$Y
#' covar <- ExampleDataBinary$Z
#' ProvID <- ExampleDataBinary$ProvID
#' data <- data.frame(outcome, ProvID, covar)
#' outcome.char <- colnames(data)[1]
#' ProvID.char <- colnames(data)[2]
#' wb.char <- c("z1", "z2")
#' other.char <- c("z3", "z4", "z5")
#' fit_cre <- logis_cre(data = data, Y.char = outcome.char, ProvID.char = ProvID.char,
#' wb.char = wb.char, other.char = other.char)
#' SR <- SM_output(fit_cre, stdz = "direct", measure = "rate")
#' SR$direct.rate
#'
#' @exportS3Method SM_output logis_cre
SM_output.logis_cre <- function(fit, parm, stdz = "indirect", # nolint: object_name_linter.
                                measure = c("rate", "ratio"),
                                threads = 2, ...) {
  compat_mixed_sm_output(fit, parm, stdz, measure, threads, class = "logis_cre")
}

# --- confint() -------------------------------------------------------------------------------

#' Get confidence intervals for provider effects or standardized measures from a fitted `linear_re` object
#'
#' Provide confidence intervals for provider effects or standardized measures from a random
#' effect linear model. This is the interface of pprof 1.0.3, kept for existing code; it calls
#' [provider_effects()] or [standardize_providers()] and returns the results in the shape of
#' pprof 1.0.3.
#'
#' @param object a model fitted from \code{linear_re}.
#' @param parm specify a subset of providers for which confidence intervals are given.
#' By default, all providers are included. Numeric values select numeric provider IDs; other
#' values must have the class of the provider IDs.
#' @param level the confidence level. The default value is 0.95.
#' @param option 	a character string specifying whether the confidence intervals
#' should be provided for provider effects or standardized measures:
#'   \itemize{
#'   \item {\code{"alpha"}} provider effect.
#'   \item {\code{"SM"}} standardized measures.
#'   }
#' @param stdz a character string or a vector specifying the standardization method
#' if `option` includes \code{"SM"}. See `stdz` argument in \code{\link{SM_output.linear_re}}.
#' @param alternative a character string specifying the alternative hypothesis, must be one of
#' \code{"two.sided"} (default), \code{"greater"}, or \code{"less"}.
#' Note that \code{"alpha"} for argument `option` only supports \code{"two.sided"}.
#' @param \dots additional arguments that can be passed to the function.
#'
#' @return A list of data frames containing the confidence intervals based on the values of `option` and `stdz`.
#' \item{CI.alpha}{Confidence intervals for provider effects if `option` includes \code{"alpha"}.}
#' \item{CI.indirect}{Confidence intervals for indirect standardized differences if `option` includes \code{"SM"}
#'   and `stdz` includes \code{"indirect"}.}
#' \item{CI.direct}{Confidence intervals for direct standardized differences if `option` includes \code{"SM"} and
#'   `stdz` includes \code{"direct"}.}
#'
#' @examples
#' data(ExampleDataLinear)
#' outcome <- ExampleDataLinear$Y
#' ProvID <- ExampleDataLinear$ProvID
#' covar <- ExampleDataLinear$Z
#' fit_re <- linear_re(Y = outcome, Z = covar, ProvID = ProvID)
#' confint(fit_re)
#'
#' @exportS3Method confint linear_re
confint.linear_re <- function(object, parm, level = 0.95, option = "SM",
                              stdz = "indirect", alternative = "two.sided", ...) {
  compat_mixed_confint(object, parm, level, option, stdz = stdz, alternative = alternative, class = "linear_re")
}

#' Get confidence intervals for provider effects or standardized measures from a fitted `linear_cre` object
#'
#' Provide confidence intervals for provider effects or standardized measures from a correlated
#' random effect linear model. This is the interface of pprof 1.0.3, kept for existing code; it
#' calls [provider_effects()] or [standardize_providers()] and returns the results in the shape
#' of pprof 1.0.3.
#'
#' @inheritParams confint.linear_re
#' @param object a model fitted from \code{linear_cre}.
#' @param stdz a character string or a vector specifying the standardization method
#' if `option` includes \code{"SM"}. See `stdz` argument in \code{\link{SM_output.linear_cre}}.
#' @inherit confint.linear_re return
#'
#' @examples
#' data(ExampleDataLinear)
#' outcome <- ExampleDataLinear$Y
#' covar <- ExampleDataLinear$Z
#' ProvID <- ExampleDataLinear$ProvID
#' data <- data.frame(outcome, ProvID, covar)
#' outcome.char <- colnames(data)[1]
#' ProvID.char <- colnames(data)[2]
#' wb.char <- c("z1", "z2")
#' other.char <- c("z3", "z4", "z5")
#' fit_cre <- linear_cre(data = data, Y.char = outcome.char, ProvID.char = ProvID.char,
#' wb.char = wb.char, other.char = other.char)
#' confint(fit_cre)
#'
#' @exportS3Method confint linear_cre
confint.linear_cre <- function(object, parm, level = 0.95, option = "SM",
                               stdz = "indirect", alternative = "two.sided", ...) {
  compat_mixed_confint(object, parm, level, option, stdz = stdz, alternative = alternative, class = "linear_cre")
}

#' Get confidence intervals for provider effects or standardized measures from a fitted `logis_re` object
#'
#' Provide confidence intervals for provider effects or standardized measures from a random
#' effect logistic model. This is the interface of pprof 1.0.3, kept for existing code; it
#' calls [provider_effects()] or [standardize_providers()] and returns the results in the shape
#' of pprof 1.0.3.
#'
#' @inheritParams confint.linear_re
#' @param object a model fitted from \code{logis_re}.
#' @param measure a character string or a vector indicating whether the output measure is "ratio" or "rate" if
#'   \code{option = "SM"}. Both "rate" and "ratio" will be provided by default.
#' @inherit confint.linear_re return
#'
#' @examples
#' data(ExampleDataBinary)
#' outcome <- ExampleDataBinary$Y
#' ProvID <- ExampleDataBinary$ProvID
#' covar <- ExampleDataBinary$Z
#' fit_re <- logis_re(Y = outcome, Z = covar, ProvID = ProvID)
#' confint(fit_re)
#'
#' @exportS3Method confint logis_re
confint.logis_re <- function(object, parm, level = 0.95, option = "SM", measure = c("rate", "ratio"),
                             stdz = "indirect", alternative = "two.sided", ...) {
  compat_mixed_confint(object, parm, level, option, measure, stdz, alternative, class = "logis_re")
}

#' Get confidence intervals for provider effects or standardized measures from a fitted `logis_cre` object
#'
#' Provide confidence intervals for provider effects or standardized measures from a correlated
#' random effect logistic model. This is the interface of pprof 1.0.3, kept for existing code;
#' it calls [provider_effects()] or [standardize_providers()] and returns the results in the
#' shape of pprof 1.0.3.
#'
#' @inheritParams confint.logis_re
#' @param object a model fitted from \code{logis_cre}.
#' @inherit confint.linear_re return
#'
#' @examples
#' data(ExampleDataBinary)
#' outcome <- ExampleDataBinary$Y
#' covar <- ExampleDataBinary$Z
#' ProvID <- ExampleDataBinary$ProvID
#' data <- data.frame(outcome, ProvID, covar)
#' outcome.char <- colnames(data)[1]
#' ProvID.char <- colnames(data)[2]
#' wb.char <- c("z1", "z2")
#' other.char <- c("z3", "z4", "z5")
#' fit_cre <- logis_cre(data = data, Y.char = outcome.char, ProvID.char = ProvID.char,
#' wb.char = wb.char, other.char = other.char)
#' confint(fit_cre)
#'
#' @exportS3Method confint logis_cre
confint.logis_cre <- function(object, parm, level = 0.95, option = "SM", measure = c("rate", "ratio"),
                              stdz = "indirect", alternative = "two.sided", ...) {
  compat_mixed_confint(object, parm, level, option, measure, stdz, alternative, class = "logis_cre")
}

# --- summary() -------------------------------------------------------------------------------

#' @rdname summary.linear_fe
#'
#' @examples
#' data(ExampleDataLinear)
#' outcome <- ExampleDataLinear$Y
#' covar <- ExampleDataLinear$Z
#' ProvID <- ExampleDataLinear$ProvID
#' fit_re <- linear_re(Y = outcome, Z = covar, ProvID = ProvID)
#' summary(fit_re)
#'
#' @exportS3Method summary linear_re
summary.linear_re <- function(object, parm, level = 0.95, null = 0, ...) {
  compat_mixed_summary(object, parm, level, null, class = "linear_re")
}

#' @rdname summary.linear_fe
#'
#' @examples
#' data(ExampleDataLinear)
#' outcome <- ExampleDataLinear$Y
#' covar <- ExampleDataLinear$Z
#' ProvID <- ExampleDataLinear$ProvID
#' data <- data.frame(outcome, ProvID, covar)
#' outcome.char <- colnames(data)[1]
#' ProvID.char <- colnames(data)[2]
#' wb.char <- c("z1", "z2")
#' other.char <- c("z3", "z4", "z5")
#' fit_cre <- linear_cre(data = data, Y.char = outcome.char, ProvID.char = ProvID.char,
#' wb.char = wb.char, other.char = other.char)
#' summary(fit_cre)
#'
#' @exportS3Method summary linear_cre
summary.linear_cre <- function(object, parm, level = 0.95, null = 0, ...) {
  compat_mixed_summary(object, parm, level, null, class = "linear_cre")
}

#' Result Summaries of Covariate Estimates from a fitted `logis_re` or `logis_cre` object
#'
#' Provide the summary statistics for the covariate estimates for a random/correlated random
#' effect logistic model. This is the interface of pprof 1.0.3, kept for existing code; it calls
#' [test_coefficients()] and returns the results in the shape of pprof 1.0.3.
#'
#' @param object a model fitted from \code{logis_re} or \code{logis_cre}.
#' @param parm specifies a subset of covariates for which the result summaries should be output.
#' By default, all covariates are included. The summaries include the intercept, which is
#' selected by the name \code{"(intercept)"}, in lower case, although its row is named
#' \code{"(Intercept)"}.
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
#' @details
#' As in pprof 1.0.3, the p-value is computed as 2 (1 - pnorm(z)), which exceeds 1 for
#' coefficients with a negative statistic.
#'
#' @examples
#' \donttest{
#' data(ExampleDataBinary)
#' outcome <- ExampleDataBinary$Y
#' covar <- ExampleDataBinary$Z
#' ProvID <- ExampleDataBinary$ProvID
#' fit_re <- logis_re(Y = outcome, Z = covar, ProvID = ProvID)
#' summary(fit_re)
#' }
#'
#' @exportS3Method summary logis_re
summary.logis_re <- function(object, parm, level = 0.95, null = 0, ...) {
  compat_mixed_summary(object, parm, level, null, class = "logis_re")
}

#' @rdname summary.logis_re
#'
#' @examples
#' data(ExampleDataBinary)
#' outcome <- ExampleDataBinary$Y
#' covar <- ExampleDataBinary$Z
#' ProvID <- ExampleDataBinary$ProvID
#' data <- data.frame(outcome, ProvID, covar)
#' outcome.char <- colnames(data)[1]
#' ProvID.char <- colnames(data)[2]
#' wb.char <- c("z1", "z2")
#' other.char <- c("z3", "z4", "z5")
#' fit_cre <- logis_cre(data = data, Y.char = outcome.char, ProvID.char = ProvID.char,
#' wb.char = wb.char, other.char = other.char)
#' summary(fit_cre)
#'
#' @exportS3Method summary logis_cre
summary.logis_cre <- function(object, parm, level = 0.95, null = 0, ...) {
  compat_mixed_summary(object, parm, level, null, class = "logis_cre")
}

# --- Implementations -------------------------------------------------------------------------

# The labels of each class's interval tables (`model` attributes) and summaries.
compat_mixed_labels <- list(
  linear_re = list(logistic = FALSE, model = "RE linear"),
  logis_re = list(logistic = TRUE, model = "RE logis", indirect_rate = "RE logis"),
  linear_cre = list(logistic = FALSE, model = "CRE linear"),
  logis_cre = list(logistic = TRUE, model = "CRE logis", indirect_rate = "RE logis")
)

# test() for the four classes (R/test.linear_re.R, R/test.logis_re.R, and their CRE
# versions): the Wald test with the standard deviations of K-69 (linear RE) or K-70.
compat_mixed_test <- function(fit, parm, level = 0.95, null = 0, alternative = "two.sided") {
  null_value <- compat_mixed_null(null)
  compat_check_alternative(alternative, "Argument 'alternative' should be one of 'two.sided', 'less', 'greater'")
  model <- compat_model_from_mixed(fit, effect_sd = TRUE)
  table <- test_providers(model, "wald", null = null_value, level = level, alternative = alternative)$table
  compat_wald_test_result(table, fit, parm)
}

# SM_output() for the four classes (R/SM_output.linear_re.R, R/SM_output.logis_re.R, and
# their CRE versions): predicted over expected (K-82, K-84), as differences for linear
# models and as ratios and rates for logistic models; `measure` and `threads` apply to
# logistic models only.
compat_mixed_sm_output <- function(fit, parm, stdz = "indirect", measure = c("rate", "ratio"), threads = 2,
                                   class = compat_mixed_class(fit)) {
  compat_check_object(fit, missing(fit), "fit", class)
  logistic <- compat_mixed_labels[[class]]$logistic
  compat_check_stdz(stdz)
  if (logistic && !"rate" %in% measure && !"ratio" %in% measure) {
    abort_invalid_input("Argument 'measure' NOT as required!", arg = "measure")
  }
  ind <- compat_parm_rows(fit, parm, "Argument 'parm' includes invalid elements.")
  model <- compat_model_from_mixed(fit)
  ids <- compat_provider_labels(fit)
  methods <- c("indirect", "direct")[c("indirect" %in% stdz, "direct" %in% stdz)]
  if (!logistic) return(compat_mixed_differences(model, methods, ids, ind))
  measures <- standardize_providers(model, methods, c("ratio", "rate"), threads = threads)$table
  response <- compat_response_vector(fit$observation)
  return_list <- list()
  oe_list <- list()
  for (method in methods) {
    ratio <- compat_measure_rows(measures, method, "ratio")
    rate <- compat_measure_rows(measures, method, "rate")
    title <- paste0(toupper(substr(method, 1L, 1L)), substring(method, 2L))
    oe <- if (identical(method, "indirect")) {
      data.frame(Obs.indirect_provider = ratio$observed, Exp.indirect_provider = ratio$expected)
    } else {
      data.frame(Obs_all = compat_typed_sum(ratio$observed, response), Exp.direct_all = ratio$expected)
    }
    rownames(oe) <- ids
    oe_list[[paste0("OE_", method)]] <- oe[ind, ]
    if ("ratio" %in% measure) {
      return_list[[paste0(method, ".ratio")]] <- compat_measure_matrix(ratio$estimate, ids,
                                                                       paste0(title, "_standardized.ratio"), ind)
    }
    if ("rate" %in% measure) {
      return_list[[paste0(method, ".rate")]] <- compat_measure_matrix(rate$estimate, ids,
                                                                      paste0(title, "_standardized.rate"), ind)
    }
  }
  return_list$OE <- oe_list
  return_list
}

# The standardized differences of linear RE and CRE models (K-84) in the shape of the
# reference's SM_output(): the indirect OE table named by provider, the direct one with the
# automatic row names of data.frame().
compat_mixed_differences <- function(model, methods, ids, ind) {
  measures <- standardize_providers(model, methods, "difference")$table
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

# confint() for the four classes (R/confint.linear_re.R, R/confint.logis_re.R, and their CRE
# versions): Wald intervals for the provider effects (`option = "alpha"`, two-sided) or for
# the standardized measures (K-93, K-94). The direct limits of logistic models use one
# thread, where the reference hard-codes 4 (D-21; the results do not depend on it, K-85).
# `measure` applies to logistic models only.
compat_mixed_confint <- function(object, parm, level = 0.95, option = "SM", measure = c("rate", "ratio"),
                                 stdz = "indirect", alternative = "two.sided", class = compat_mixed_class(object)) {
  compat_check_object(object, missing(object), "object", class)
  labels <- compat_mixed_labels[[class]]
  if (!(identical(option, "alpha") || identical(option, "SM"))) {
    abort_invalid_input("Argument 'option' should be 'alpha' or 'SM'", arg = "option")
  }
  compat_check_stdz(stdz)
  if (identical(option, "alpha") && !identical(alternative, "two.sided")) {
    abort_invalid_input("Provider effect (option = 'alpha') only supports two-sided confidence intervals.",
                        arg = "alternative")
  }
  compat_check_alternative(alternative, "Argument 'alternative' should be one of 'two.sided', 'less', 'greater'")
  model <- compat_model_from_mixed(object, effect_sd = TRUE)
  ids <- compat_provider_labels(object)
  ind <- compat_parm_rows(object, parm)
  if (identical(option, "alpha")) {
    table <- provider_effects(model, interval = "wald", level = level)$table
    out <- data.frame(alpha = table$estimate, alpha.Lower = table$lower, alpha.Upper = table$upper, row.names = ids)
    colnames(out) <- c("Estimate", "alpha.Lower", "alpha.Upper")
    attr(out, "description") <- "Provider Effects"
    return(out[ind, ])
  }
  methods <- c("indirect", "direct")[c("indirect" %in% stdz, "direct" %in% stdz)]
  scales <- if (labels$logistic) c("ratio", "rate") else "difference"
  result <- standardize_providers(model, methods, scales, interval = "wald", level = level, alternative = alternative,
                                  threads = 1)
  # D-33: the RE and CRE tables give the level as a proportion ("0.95 %").
  annotate <- function(table, description, model_label, population_rate = NULL) {
    attr(table, "confidence_level") <- paste(level, "%")
    attr(table, "type") <- compat_interval_type(alternative)
    attr(table, "description") <- description
    attr(table, "model") <- model_label
    if (!is.null(population_rate)) attr(table, "population_rate") <- population_rate
    table
  }
  return_list <- list()
  for (method in methods) {
    title <- paste0(toupper(substr(method, 1L, 1L)), substring(method, 2L))
    if (!labels$logistic) {
      rows <- compat_measure_rows(result$table, method, "difference")
      out <- data.frame(SM = rows$estimate, Lower = rows$lower, Upper = rows$upper, row.names = ids)
      colnames(out) <- c(paste0(title, ".Difference"), paste0(method, ".Lower"), paste0(method, ".Upper"))
      out <- annotate(out, paste(title, "Standardized Difference"), labels$model)
      return_list[[paste0("CI.", method)]] <- out[ind, ]
      next
    }
    if ("ratio" %in% measure) {
      rows <- compat_measure_rows(result$table, method, "ratio")
      out <- data.frame(SR = rows$estimate, Lower = rows$lower, Upper = rows$upper, row.names = ids)
      colnames(out) <- c(paste0(title, ".Ratio"), "Ratio.Lower", "Ratio.Upper")
      out <- annotate(out, paste(title, "Standardized Ratio"), labels$model)
      return_list[[paste0("CI.", method, "_ratio")]] <- out[ind, ]
    }
    if ("rate" %in% measure) {
      rows <- compat_measure_rows(result$table, method, "rate")
      out <- data.frame(SR = rows$estimate, Lower = rows$lower, Upper = rows$upper, row.names = ids)
      colnames(out) <- c(paste0(title, ".Rate"), "Rate.Lower", "Rate.Upper")
      model_label <- if (identical(method, "indirect")) labels$indirect_rate else labels$model
      out <- annotate(out, paste(title, "Standardized Rate"), model_label, result$population_rate)
      return_list[[paste0("CI.", method, "_rate")]] <- out[ind, ]
    }
  }
  return_list
}

# summary() for the four classes (R/summary.linear_re.R, R/summary.logis_re.R, and their
# CRE versions): the intercept included; t p-values with n - p - m + 1 degrees of freedom for
# linear models (K-104) and 2 (1 - pnorm(z)) for logistic models (K-105, D-31); lme4's Wald
# intervals. `parm` names the intercept "(intercept)" (D-44).
compat_mixed_summary <- function(object, parm, level = 0.95, null = 0, class = compat_mixed_class(object)) {
  compat_check_object(object, missing(object), "object", class)
  chars <- object$char_list
  labels <- if (is.null(chars$within_terms)) {
    c("(intercept)", chars$Z.char)
  } else {
    c("(intercept)", chars$within_terms, chars$between_terms, chars$other.vars)
  }
  model <- compat_model_from_mixed(object)
  out <- compat_summary_table(test_coefficients(model, "wald", level = level, null = null)$table)
  out[compat_summary_rows(parm, labels), ]
}
