# Compatibility methods for the objects of pprof 1.0.3 (ARCHITECTURE §I.2, DEC-032): each
# rebuilds the model from the old object, calls the new API, and returns the old shapes
# (BEHAVIOR_SPECS §7.1, §8.1, §9.1, §10, §16).

compat_check_fit <- function(fit, is_missing, arg) {
  if (is_missing) abort_invalid_input(sprintf("Argument '%s' is required!", arg), arg = arg)
  if (!inherits(fit, "logis_fe")) {
    abort_invalid_input(sprintf("Object '%s' is not of the classes 'logis_fe'!", arg), arg = arg)
  }
  invisible(fit)
}

compat_wald_message <- paste("Wald test fails for datasets with providers having all or no events.",
                             "Score test or exact test are recommended.")

compat_check_stdz <- function(stdz) {
  if (!"indirect" %in% stdz && !"direct" %in% stdz) {
    abort_invalid_input("Argument 'stdz' NOT as required!", arg = "stdz")
  }
  invisible(stdz)
}

compat_check_alternative <- function(alternative, message) {
  if (!(is.character(alternative) && length(alternative) == 1L && alternative %in% c("two.sided", "greater", "less"))) {
    abort_invalid_input(message, arg = "alternative")
  }
  invisible(alternative)
}

# Runs `expr`, replacing the new API's Wald warning by the reference's.
compat_with_wald_warning <- function(expr, message) {
  warning(message, call. = FALSE)
  withCallingHandlers(expr, pprof_warning_wald_unreliable = function(w) invokeRestart("muffleWarning"))
}

# The rows of a measures table for one standardization and measure.
compat_measure_rows <- function(table, standardization, measure) {
  table[table$standardization == standardization & table$measure == measure, , drop = FALSE]
}

# The type of the reference's sums of the response: integer for integer or logical
# responses, double otherwise.
compat_typed_sum <- function(values, response) {
  if (is.double(response)) as.double(values) else as.integer(values)
}

#' Conduct hypothesis testing for provider effects from a fitted `logis_fe` object
#'
#' Conduct hypothesis tests on provider effects and identify outlying providers for a fixed
#' effect logistic model. This is the interface of pprof 1.0.3, kept for existing code; it
#' calls [test_providers()] and returns the results in the shape of pprof 1.0.3.
#'
#' @param fit a model fitted from \code{logis_fe}.
#' @param parm specifies a subset of providers for which confidence intervals are to be given.
#' By default, all providers are included. Numeric values select numeric provider IDs; other
#' values must have the class of the provider IDs. IDs the fit does not have are ignored.
#' @param level the confidence level during the hypothesis test, meaning a significance level of \eqn{1 - \text{level}}.
#' The default value is 0.95.
#' @param test a character string specifying the type of testing method to be conducted. The default is
#'   "exact.poisbinom".
#'   \itemize{
#'   \item{\code{"exact.poisbinom"}:} exact test based on Poisson-binomial distribution of \eqn{O_i|Z_i}.
#'   \item{\code{"exact.bootstrap"}:} exact test based on bootstrap procedure.
#'   \item{\code{"wald"}:} wald test.
#'   \item{\code{"score"}:} score test.
#'   }
#' @param score_modified a logical indicating whether to use the modified score test
#' ignoring the randomness of covariate coefficient for score teat (\code{"test = score"}). The default value is TRUE.
#' @param null a character string or a number specifying null hypotheses of fixed provider effects. The default is
#'   \code{"median"}.
#' @param n resample size for bootstrapping when (\code{"test = exact.bootstrap"}). The default value is 10,000.
#' @param threads an integer specifying the number of threads to use. The default value is 1.
#' @param alternative a character string specifying the alternative hypothesis, must be one of
#' \code{"two.sided"} (default), \code{"greater"}, or \code{"less"}.
#' @param \dots additional arguments that can be passed to the function.
#'
#' @details
#' By default, the function uses the `"exact.poisbinom"` method.
#' The wald test is invalid for extreme providers (i.e. when provider effect goes to infinity).
#' For the score test, consider that when the number of tested providers is large,
#' refitting the models to get the restricted MLEs will take a long time.
#' Therefore, we use unrestricted MLEs to replace the restricted MLEs during the testing procedure by default.
#' The user can specify \code{score_modified = FALSE} for a score test whose variance accounts
#' for the estimation of the covariate coefficients and the other providers' effects, still at
#' the unrestricted estimates; a provider whose statistic is not finite gets a missing p-value
#' and flag, with a warning.
#'
#' @return A data frame containing the results of the hypothesis test, with the following columns:
#' \item{flag}{a flagging indicator where \code{1} means statistically higher than expected
#' and \code{-1} means statistically lower than expected.}
#' \item{p-value}{the p-value of the hypothesis test.}
#' \item{stat}{the test statistic.}
#' \item{Std.Error}{The standard error of the provider effect estimate, included only when \code{test = "wald"}.}
#'
#' @examples
#' data(ExampleDataBinary)
#' outcome = ExampleDataBinary$Y
#' covar = ExampleDataBinary$Z
#' ProvID = ExampleDataBinary$ProvID
#' fit_fe <- logis_fe(Y = outcome, Z = covar, ProvID = ProvID, message = FALSE)
#' test(fit_fe, test = "score")
#'
#' @references
#' Wu, W, Yang, Y, Kang, J, He, K. (2022) Improving large-scale estimation and inference for profiling health care
#'   providers.
#' \emph{Statistics in Medicine}, \strong{41(15)}: 2840-2853.
#' \cr
#'
#' @exportS3Method test logis_fe
test.logis_fe <- function(fit, parm, level = 0.95, test = "exact.poisbinom", score_modified = TRUE,
                          null = "median", n = 10000, threads = 1, alternative = "two.sided", ...) {
  compat_check_fit(fit, missing(fit), "fit")
  tests <- c(exact.poisbinom = "exact", exact.bootstrap = "bootstrap", score = "score", wald = "wald")
  if (!(is.character(test) && length(test) == 1L && test %in% c(names(tests), "robust_wald"))) {
    abort_invalid_input("Argument 'test' NOT as required!", arg = "test")
  }
  if (identical(test, "robust_wald")) {
    # D-06: pprof 1.0.3 accepted the value and returned NULL; no robust Wald test exists.
    abort_invalid_input("No robust Wald test is implemented; `test = \"robust_wald\"` is not supported.", arg = "test")
  }
  null_value <- compat_null(null)
  compat_check_alternative(alternative, "Argument 'alternative' should be one of 'two.sided', 'greater', or 'less'")
  if (identical(test, "exact.bootstrap") && !(is.numeric(n) && length(n) == 1L && n > 0 && as.integer(n) == n)) {
    abort_invalid_input("Argument 'n' NOT a positive integer ! ", arg = "n")
  }
  model <- compat_model_from_logis_fe(fit)
  providers <- if (missing(parm)) NULL else compat_parm_providers(fit, parm)
  values <- provider_table(model)$provider_value
  if (identical(test, "wald")) {
    # The reference tests every provider and then selects rows, so the levels of its flag
    # factor come from all providers (D-15).
    result <- compat_with_wald_warning(test_providers(model, "wald", null = null_value, level = level,
                                                      alternative = alternative), compat_wald_message)
    table <- result$table
    out <- data.frame(flag = factor(table$flag), p = table$p_value, stat = table$statistic, Std.Error = table$std_error,
                      row.names = table$provider_id)
    colnames(out) <- c("flag", "p value", "stat", "Std.Error")
    sizes <- stats::setNames(table$n_obs, table$provider_id)
    if (is.null(providers)) {
      attr(out, "provider size") <- sizes
      return(out)
    }
    indices <- which(table$provider_id %in% providers)
    attr(out, "provider size") <- sizes[indices]
    return(out[indices, ])
  }
  score_type <- if (isFALSE(score_modified)) "standard" else "modified"
  result <- test_providers(model, tests[[test]], null = null_value, level = level, alternative = alternative,
                           providers = providers, score_type = score_type, n_resamples = n, threads = threads)
  table <- result$table
  rows <- match(table$provider_id, provider_table(model)$provider_id)
  out <- data.frame(flag = factor(table$flag), p = table$p_value, stat = table$statistic, row.names = values[rows])
  colnames(out) <- c("flag", "p value", "stat")
  attr(out, "provider size") <- stats::setNames(table$n_obs, table$provider_id)
  out
}

#' Calculate direct/indirect standardized ratios/rates from a fitted `logis_fe` object
#'
#' Provide direct/indirect standardized ratios/rates for a fixed effect logistic model. This
#' is the interface of pprof 1.0.3, kept for existing code; it calls
#' [standardize_providers()] and returns the results in the shape of pprof 1.0.3.
#'
#' @param fit a model fitted from \code{logis_fe}.
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
#' @param null if \code{"stdz = indirect"}, a character string or a number defining the population norm. The
#'   default is "median".
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
#' @examples
#' data(ExampleDataBinary)
#' outcome = ExampleDataBinary$Y
#' covar = ExampleDataBinary$Z
#' ProvID = ExampleDataBinary$ProvID
#' fit_fe <- logis_fe(Y = outcome, Z = covar, ProvID = ProvID, message = FALSE)
#' SR <- SM_output(fit_fe, stdz = "direct", measure = "rate")
#' SR$direct.rate
#'
#' @references
#' He, K. (2019). Indirect and direct standardization for evaluating transplant centers. \emph{Journal of Hospital
#'   Administration}, \strong{8(1)}, 9-14.
#' \cr
#'
#' @exportS3Method SM_output logis_fe
SM_output.logis_fe <- function(fit, parm, stdz = "indirect", measure = c("rate", "ratio"), # nolint: object_name_linter.
                               null = "median", threads = 2, ...) {
  compat_check_fit(fit, missing(fit), "fit")
  compat_check_stdz(stdz)
  if (!"rate" %in% measure && !"ratio" %in% measure) {
    abort_invalid_input("Argument 'measure' NOT as required!", arg = "measure")
  }
  model <- compat_model_from_logis_fe(fit)
  ids <- rownames(fit$coefficient$gamma)
  ind <- if (missing(parm)) {
    seq_along(ids)
  } else {
    which(ids %in% compat_parm_providers(fit, parm, "Argument 'parm' includes invalid elements."))
  }
  indirect <- "indirect" %in% stdz
  direct <- "direct" %in% stdz
  null_value <- if (indirect) compat_null(null)
  measures <- standardize_providers(model, c("indirect", "direct")[c(indirect, direct)], c("ratio", "rate"),
                                    null = null_value, threads = threads)$table
  response <- fit$observation
  return_list <- list()
  oe_list <- list()
  matrix_of <- function(values, column) matrix(values, ncol = 1L, dimnames = list(ids, column))[ind, , drop = FALSE]
  if (indirect) {
    ratio <- compat_measure_rows(measures, "indirect", "ratio")
    rate <- compat_measure_rows(measures, "indirect", "rate")
    oe <- data.frame(Obs_provider = compat_typed_sum(ratio$observed, response),
                     Exp.indirect_provider = ratio$expected, Var.indirect_provider = ratio$variance)
    rownames(oe) <- ids
    oe_list$OE_indirect <- oe[ind, ]
    if ("ratio" %in% measure) return_list$indirect.ratio <- matrix_of(ratio$estimate, "Indirect_standardized.ratio")
    if ("rate" %in% measure) return_list$indirect.rate <- matrix_of(rate$estimate, "Indirect_standardized.rate")
  }
  if (direct) {
    ratio <- compat_measure_rows(measures, "direct", "ratio")
    rate <- compat_measure_rows(measures, "direct", "rate")
    oe <- data.frame(Obs_all = compat_typed_sum(ratio$observed, response), Exp.direct_all = ratio$expected)
    rownames(oe) <- ids
    oe_list$OE_direct <- oe[ind, ]
    if ("ratio" %in% measure) return_list$direct.ratio <- matrix_of(ratio$estimate, "Direct_standardized.ratio")
    if ("rate" %in% measure) return_list$direct.rate <- matrix_of(rate$estimate, "Direct_standardized.rate")
  }
  return_list$OE <- oe_list
  return_list
}

#' Get confidence intervals for provider effects or standardized measures from a fitted `logis_fe` object
#'
#' Provide confidence intervals for provider effects or standardized measures from a fixed
#' effect logistic model. This is the interface of pprof 1.0.3, kept for existing code; it
#' calls [provider_effects()] or [standardize_providers()] and returns the results in the
#' shape of pprof 1.0.3.
#'
#' @param object a model fitted from \code{logis_fe}.
#' @param parm specify a subset of providers for which confidence intervals are given.
#' By default, all providers are included. Numeric values select numeric provider IDs; other
#' values must have the class of the provider IDs.
#' @param level the confidence level. The default value is 0.95.
#' @param test a character string specifying the type of testing method. The default is "exact".
#'   \itemize{
#'   \item {\code{"exact"}} exact test.
#'   \item {\code{"wald"}} wald test.
#'   \item {\code{"score"}} score test.
#'   }
#' @param option 	a character string specifying whether the confidence intervals
#' should be provided for provider effects or standardized measures:
#'   \itemize{
#'   \item {\code{"gamma"}} provider effect.
#'   \item {\code{"SM"}} standardized measures.
#'   }
#' @param stdz a character string or a vector specifying the standardization method
#' if \code{option = "SM"}. See `stdz` argument in \code{\link{SM_output.logis_fe}}.
#' @param null a character string or a number defining the population norm if \code{option = "SM"}.
#' @param measure a character string or a vector indicating whether the output measure is "ratio" or "rate" if
#'   \code{option = "SM"}.
#' Both "rate" and "ratio" will be provided by default.
#'   \itemize{
#'   \item {\code{"rate"}} output the standardized rate. The "rate" has been restricted to 0% - 100%.
#'   \item {\code{"ratio"}}  output the standardized ratio.
#'   \item {\code{c("ratio", "rate")}} output both the standardized rate and ratio.
#'   }
#' @param alternative a character string specifying the alternative hypothesis, must be one of
#' \code{"two.sided"} (default), \code{"greater"}, or \code{"less"}.
#' Note that \code{"gamma"} for argument `option` only supports \code{"two.sided"}.
#' @param \dots additional arguments that can be passed to the function.
#'
#' @details
#' The wald test is invalid for extreme providers (i.e. when provider effect goes to infinity).
#' We suggest using score or exact test to generate confidence intervals.
#'
#' @return A dataframe (\code{option = "gamma"}) or a list of data frames (\code{option = "SM"}) containing the
#'   point estimate, and lower and upper bounds of the estimate.
#'
#' @examples
#' data(ExampleDataBinary)
#' outcome = ExampleDataBinary$Y
#' covar = ExampleDataBinary$Z
#' ProvID = ExampleDataBinary$ProvID
#' fit_fe <- logis_fe(Y = outcome, Z = covar, ProvID = ProvID, message = FALSE)
#' confint(fit_fe, option = "gamma")
#' confint(fit_fe, option = "SM")
#'
#' @exportS3Method confint logis_fe
confint.logis_fe <- function(object, parm, level = 0.95, test = "exact", option = "SM", stdz = "indirect",
                             null = "median", measure = c("rate", "ratio"), alternative = "two.sided", ...) {
  compat_check_fit(object, missing(object), "object")
  if (!(identical(option, "gamma") || identical(option, "SM"))) {
    abort_invalid_input("Argument 'option' should be 'gamma' or 'SM'", arg = "option")
  }
  if (!(is.character(test) && length(test) == 1L && test %in% c("exact", "score", "wald"))) {
    abort_invalid_input("Argument 'test' NOT as required!", arg = "test")
  }
  compat_check_stdz(stdz)
  compat_check_alternative(alternative, "Argument 'alternative' should be one of 'two.sided', 'less', 'greater'.")
  model <- compat_model_from_logis_fe(object)
  providers <- if (missing(parm)) NULL else compat_parm_providers(object, parm)
  wald <- identical(test, "wald")
  run <- function(expr) {
    if (wald) compat_with_wald_warning(expr, paste("The", compat_wald_message)) else expr
  }
  if (identical(option, "gamma")) {
    if (!identical(alternative, "two.sided")) {
      abort_invalid_input("Provider effect (option = 'gamma') only supports two-sided confidence intervals.",
                          arg = "alternative")
    }
    table <- run(provider_effects(model, interval = test, level = level, providers = providers))$table
    out <- data.frame(gamma = table$estimate, gamma.lower = table$lower, gamma.upper = table$upper)
    # The reference names the exact and score rows by the provider values in their stored
    # type and then reorders them, and the Wald rows by the provider labels.
    rows <- match(table$provider_id, provider_table(model)$provider_id)
    rownames(out) <- if (wald) table$provider_id else provider_table(model)$provider_value[rows]
    out <- out[seq_len(nrow(out)), , drop = FALSE]
    attr(out, "description") <- "Provider Effects"
    return(out)
  }
  indirect <- "indirect" %in% stdz
  direct <- "direct" %in% stdz
  null_value <- if (indirect) compat_null(null)
  result <- run(standardize_providers(model, c("indirect", "direct")[c(indirect, direct)], c("ratio", "rate"),
                                      null = null_value, interval = test, level = level, alternative = alternative,
                                      providers = providers))
  population_rate <- result$population_rate
  type <- if (identical(alternative, "greater")) {
    "upper one-sided"
  } else if (identical(alternative, "less")) {
    "lower one-sided"
  } else {
    "two-sided"
  }
  label <- paste(level * 100, "%")
  annotate <- function(table, description, rate) {
    attr(table, "confidence_level") <- label
    attr(table, "type") <- type
    attr(table, "description") <- description
    attr(table, "model") <- "FE logis"
    if (rate) attr(table, "population_rate") <- population_rate
    table
  }
  return_list <- list()
  for (method in c("indirect", "direct")[c(indirect, direct)]) {
    ratio <- compat_measure_rows(result$table, method, "ratio")
    rate <- compat_measure_rows(result$table, method, "rate")
    title <- paste0(toupper(substr(method, 1L, 1L)), substring(method, 2L))
    if ("ratio" %in% measure) {
      ratios <- data.frame(ratio$estimate, ratio$lower, ratio$upper, row.names = ratio$provider_id)
      colnames(ratios) <- c(paste0(method, "_ratio"), "CI_ratio.lower", "CI_ratio.upper")
      return_list[[paste0("CI.", method, "_ratio")]] <- annotate(ratios, paste(title, "Standardized Ratio"),
                                                                 identical(method, "direct"))
    }
    if ("rate" %in% measure) {
      rates <- data.frame(rate$estimate, rate$lower, rate$upper, row.names = rate$provider_id)
      colnames(rates) <- c(paste0(method, "_rate"), "CI_rate.lower", "CI_rate.upper")
      return_list[[paste0("CI.", method, "_rate")]] <- annotate(rates, paste(title, "Standardized Rate"), TRUE)
    }
  }
  return_list
}

#' Result Summaries of Covariate Estimates from a fitted `logis_fe` object
#'
#' Provide the summary statistics for the covariate estimates for a fixed effect logistic
#' model. This is the interface of pprof 1.0.3, kept for existing code; it calls
#' [test_coefficients()] and returns the results in the shape of pprof 1.0.3.
#'
#' @param object a model fitted from \code{logis_fe}.
#' @param parm Specifies a subset of covariates for which the result summaries should be output.
#' By default, all covariates are included.
#' @param level the confidence level during the hypothesis test, meaning a significance level of \eqn{1 - \text{level}}.
#' The default value is 0.95.
#' @param test a character string specifying the type of testing method. The default is "wald".
#'   \itemize{
#'     \item{\code{"wald"}:} wald test.
#'     \item{\code{"lr"}:} likelihood ratio test.
#'     \item{\code{"score"}:} score test.
#'   }
#' @param null a number defining the null hypothesis for the covariate estimates. The default value is \code{0}.
#' @param \dots additional arguments that can be passed to the function.
#'
#' @details
#' The likelihood ratio and score tests refit the model without each covariate with the
#' default settings of \code{logis_fe}; they need at least two covariates and fail when the
#' fit used a `cutoff` below 10 that kept providers the refit would exclude.
#'
#' @return A data frame containing summary statistics for covariate estimates, with the following columns:
#' \item{Estimate}{the estimates of covariate coefficients.}
#' \item{Std.Error}{the standard error of the estimate, included only when \code{test = "wald"}.}
#' \item{Stat}{the test statistic.}
#' \item{p value}{the p-value for the hypothesis test.}
#' \item{CI.upper}{the lower bound of the confidence interval, included only when \code{test = "wald"}.}
#' \item{CI.lower}{the upper bound of the confidence interval, included only when \code{test = "wald"}.}
#'
#' @examples
#' data(ExampleDataBinary)
#' outcome = ExampleDataBinary$Y
#' covar = ExampleDataBinary$Z
#' ProvID = ExampleDataBinary$ProvID
#' fit_fe <- logis_fe(Y = outcome, Z = covar, ProvID = ProvID, message = FALSE)
#' summary.wald <- summary(fit_fe, level = 0.95, test = "wald")
#' summary.wald
#'
#' @exportS3Method summary logis_fe
summary.logis_fe <- function(object, parm, level = 0.95, test = "wald", null = 0, ...) {
  compat_check_fit(object, missing(object), "object")
  if (!(is.character(test) && length(test) == 1L && test %in% c("wald", "lr", "score"))) {
    abort_invalid_input("Argument 'test' NOT as required!", arg = "test")
  }
  covariates <- object$char_list$Z.char
  ind <- if (missing(parm)) {
    seq_along(covariates)
  } else if (is.character(parm)) {
    which(covariates %in% parm)
  } else if (is.numeric(parm) && length(parm) > 0L && all(parm == round(parm)) && !(0 %in% parm)) {
    parm
  } else {
    abort_invalid_input("Argument 'parm' includes invalid elements!", arg = "parm")
  }
  model <- compat_model_from_logis_fe(object)
  if (identical(test, "wald")) {
    table <- test_coefficients(model, "wald", level = level, null = null)$table
    out <- data.frame(table$estimate, table$std_error, table$statistic,
                      format.pval(table$p_value, digits = p_value_display_digits, eps = p_value_display_eps),
                      table$lower, table$upper, row.names = table$term)
    colnames(out) <- c("Estimate", "Std.Error", "Stat", "p value", "CI.Lower", "CI.Upper")
    return(out[ind, ])
  }
  if (null != 0) abort_invalid_input("Argument 'null' is invalid!", arg = "null")
  if (anyNA(covariates[ind]) || any(ind < 0)) {
    # The reference fails for such positions too, with unclassed errors.
    abort_invalid_input("Argument 'parm' includes invalid elements!", arg = "parm")
  }
  table <- test_coefficients(model, test, parm = ind)$table
  out <- data.frame(table$estimate, table$statistic, table$p_value, row.names = covariates[ind])
  colnames(out) <- c("Estimate", "stat", "p value")
  out
}
