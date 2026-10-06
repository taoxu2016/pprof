# Compatibility wrappers for the fit functions of pprof 1.0.3 (ARCHITECTURE §I.2): they
# translate the old arguments, call the new fit functions, and return the old objects.

#' Main function for fitting the fixed effect logistic model
#'
#' Fit a fixed effect logistic model via Serial blockwise inversion Newton (SerBIN) or block
#' ascent Newton (BAN) algorithm. This is the interface of pprof 1.0.3, kept for existing
#' code; it calls [fit_logistic_fe()], whose estimates are identical, and returns the object
#' of pprof 1.0.3. It is deprecated as of pprof 2.0.0 and warns once per session; see
#' `vignette("migration", package = "pprof")`.
#'
#' @param formula a two-sided formula object describing the model to be fitted,
#' with the response variable on the left of a ~ operator and covariates on the right,
#' separated by + operators. The fixed effect of the provider identifier is specified using \code{id()}.
#' @param data a data frame containing the variables named in the `formula`,
#' or the columns specified by `Y.char`, `Z.char`, and `ProvID.char`.
#' @param Y.char a character string specifying the column name of the response variable in the `data`.
#' @param Z.char a character vector specifying the column names of the covariates in the `data`.
#' @param ProvID.char a character string specifying the column name of the provider identifier in the `data`.
#' @param Y a numeric vector representing the response variable.
#' @param Z a matrix or data frame representing the covariates, which can include both numeric and categorical
#'   variables.
#' @param ProvID a numeric vector representing the provider identifier.
#' @param method a string specifying the algorithm to be used. The default value is "SerBIN".
#'   \itemize{
#'   \item{\code{"SerBIN"}} uses the Serial blockwise inversion Newton algorithm to fit the model (See [Wu et al.
#'     (2022)](https://onlinelibrary.wiley.com/doi/full/10.1002/sim.9387)).
#'   \item{\code{"BAN"}} uses the block ascent Newton algorithm to fit the model (See [He et al.
#'     (2013)](https://link.springer.com/article/10.1007/s10985-013-9264-6)).
#'   }
#' @param max.iter maximum iteration number if the stopping criterion specified by `stop` is
#'   not satisfied. The default value is 10,000. SerBIN can run `max.iter + 1` iterations.
#' @param tol tolerance used for stopping the algorithm. See details in `stop` below. The default value is 1e-5.
#' @param bound a positive number to avoid inflation of provider effects. The default value is 10.
#' @param cutoff the minimum number of observations required for providers. Providers with
#'   fewer observations are excluded from model fitting and from `data_include`. The default is 10.
#' @param backtrack a Boolean indicating whether backtracking line search is implemented. The default is TRUE.
#' @param stop a character string specifying the stopping rule to determine convergence.
#' \itemize{
#' \item{\code{"beta"}} stop the algorithm when the infinity norm of the difference between current and previous
#'   beta coefficients is less than the `tol`.
#' \item{\code{"relch"}} stop the algorithm when the \eqn{(loglik(m)-loglik(m-1))/(loglik(m))} (the difference
#'   between the log-likelihood of
#' the current iteration and the previous iteration divided by the log-likelihood of the current iteration) is less
#'   than the `tol`.
#' \item{\code{"ratch"}} stop the algorithm when \eqn{(loglik(m)-loglik(m-1))/(loglik(m)-loglik(0))} (the
#'   difference between the log-likelihood of
#' the current iteration and the previous iteration divided by the difference of the log-likelihood of the current
#'   iteration and the initial iteration)
#' is less than the `tol`.
#' \item{\code{"all"}} stop the algorithm when all the stopping rules (`"beta"`, `"relch"`, `"ratch"`) are met.
#' \item{\code{"or"}} stop the algorithm if any one of the rules (`"beta"`, `"relch"`, `"ratch"`) is met.
#' }
#' The default value is `or`. If `max.iter` is reached, the algorithm stops whatever the rule.
#' @param threads a positive integer specifying the number of threads to be used. The default value is 1.
#' @param message a Boolean indicating whether to print the progress of the fitting process. The default is TRUE.
#'
#' @details
#' The function accepts three different input formats:
#' a formula and dataset, where the formula is of the form \code{response ~ covariates + id(provider)}, with
#'   \code{provider} representing the provider identifier;
#' a dataset along with the column names of the response, covariates, and provider identifier;
#' or the binary outcome vector \eqn{\boldsymbol{Y}}, the covariate matrix or data frame \eqn{\mathbf{Z}}, and the
#'   provider identifier vector.
#'
#' The default algorithm is based on Serial blockwise inversion Newton (SerBIN) proposed by
#' [Wu et al. (2022)](https://onlinelibrary.wiley.com/doi/full/10.1002/sim.9387),
#' but users can also choose to use the block ascent Newton (BAN) algorithm proposed by
#' [He et al. (2013)](https://link.springer.com/article/10.1007/s10985-013-9264-6) to fit the model.
#' Both methodologies build upon the Newton-Raphson method, yet SerBIN simultaneously updates both the provider
#'   effect and covariate coefficient.
#' This concurrent update necessitates the inversion of the whole information matrix at each iteration.
#' In contrast, BAN adopts a two-layer updating approach, where the covariate coefficient is sequentially fixed to
#'   update the provider effect,
#' followed by fixing the provider effect to update the covariate coefficient.
#'
#' We suggest using the default `"SerBIN"` option as it typically converges subsequently much faster for most datasets.
#' However, in rare cases where the SerBIN algorithm encounters second-order derivative irreversibility leading to
#'   an error,
#' users can consider using the `"BAN"` option as an alternative.
#' For a deeper understanding, please consult the original article for detailed insights.
#'
#' If issues arise during model fitting, consider using the \code{data_check} function to perform a data quality check,
#' which can help identify missing values, low variation in covariates, high-pairwise correlation, and
#'   multicollinearity.
#' For datasets with missing values, this function automatically removes observations (rows) with any missing
#'   values before fitting the model.
#'
#' Unlike pprof 1.0.3, the formula may contain transformed terms, interactions, and factors
#' whose levels contain spaces; the outcome must be 0/1 or logical; `max.iter`, `tol`, and
#' `bound` must be positive and `threads` at least 1; `backtrack` must be `TRUE` or `FALSE`
#' (or 0 or 1); and the screening warning counts only the providers actually excluded.
#'
#' @seealso \code{\link{fit_logistic_fe}}, \code{\link{data_check}}
#'
#' @return A list of objects with S3 class \code{"logis_fe"}:
#' \item{coefficient}{a list containing the estimated coefficients:
#'   \code{beta}, the fixed effects for each predictor, and \code{gamma}, the effect for each provider.}
#' \item{variance}{a list containing the variance estimates:
#'   \code{beta}, the variance-covariance matrix of the predictor coefficients, and \code{gamma}, the variance of
#'     the provider effects.}
#' \item{linear_pred}{the linear predictor of each individual.}
#' \item{fitted}{the predicted probability of each observation having a response of 1.}
#' \item{observation}{the original response of each individual.}
#' \item{Loglkd}{the log-likelihood.}
#' \item{AIC}{Akaike info criterion.}
#' \item{BIC}{Bayesian info criterion.}
#' \item{AUC}{area under the ROC curve.}
#' \item{char_list}{a list of the character vectors representing the column names for
#' the response variable, covariates, and provider identifier.
#' For categorical variables, the names reflect the dummy variables created for each category.}
#' \item{data_include}{the data used to fit the model, sorted by the provider identifier.
#' For categorical covariates, this includes the dummy variables created for
#' all categories except the reference level. Additionally, it contains three extra columns:
#' \code{included}, which is always 1, because excluded providers are dropped;
#' \code{all.events}, indicating if all observations in the provider are 1;
#' \code{no.events}, indicating if all observations in the provider are 0.}
#'
#' @examples
#' data(ExampleDataBinary)
#' outcome <- ExampleDataBinary$Y
#' covar <- ExampleDataBinary$Z
#' ProvID <- ExampleDataBinary$ProvID
#' data <- data.frame(outcome, ProvID, covar)
#' covar.char <- colnames(covar)
#' outcome.char <- colnames(data)[1]
#' ProvID.char <- colnames(data)[2]
#' formula <- as.formula(paste("outcome ~", paste(covar.char, collapse = " + "), "+ id(ProvID)"))
#'
#' # Fit logistic linear effect model using three input formats
#' fit_fe1 <- logis_fe(Y = outcome, Z = covar, ProvID = ProvID)
#' fit_fe2 <- logis_fe(data = data, Y.char = outcome.char,
#' Z.char = covar.char, ProvID.char = ProvID.char)
#' fit_fe3 <- logis_fe(formula, data)
#'
#' @references
#' He K, Kalbfleisch, J, Li, Y, and et al. (2013) Evaluating hospital readmission rates in dialysis providers;
#'   adjusting for hospital effects.
#' \emph{Lifetime Data Analysis}, \strong{19}: 490-512.
#' \cr
#'
#' Wu, W, Yang, Y, Kang, J, He, K. (2022) Improving large-scale estimation and inference for profiling health care
#'   providers.
#' \emph{Statistics in Medicine}, \strong{41(15)}: 2840-2853.
#' \cr
#'
#' @export
logis_fe <- function(formula = NULL, data = NULL,
                     Y.char = NULL, Z.char = NULL, ProvID.char = NULL, # nolint: object_name_linter.
                     Y = NULL, Z = NULL, ProvID = NULL, # nolint: object_name_linter.
                     method = "SerBIN", max.iter = 10000, tol = 1e-5, bound = 10, # nolint: object_name_linter.
                     cutoff = 10, backtrack = TRUE, stop = "or", threads = 1, message = TRUE) {
  compat_deprecate("logis_fe")
  inputs <- compat_fe_inputs(formula, data, Y.char, Z.char, ProvID.char, Y, Z, ProvID)
  if (isTRUE(message)) base::message("Input format: ", inputs$format, ".")
  settings <- compat_logis_fe_settings(method, max.iter, tol, bound, cutoff, backtrack, stop, threads)
  model <- withCallingHandlers(
    fit_logistic_fe(stats::reformulate(inputs$covariates, response = inputs$response), inputs$data,
                    inputs$provider, method = settings$method, max_iter = settings$max_iter, tol = tol,
                    stop_rule = settings$stop_rule, backtrack = settings$backtrack, effect_bound = bound,
                    min_provider_size = settings$min_provider_size, keep_data = TRUE, threads = threads),
    # The wrapper reports screening in the reference's words, and only with message = TRUE.
    # A fit that reaches the iteration limit warns (D-03).
    pprof_warning_screening = function(w) invokeRestart("muffleWarning")
  )
  if (isTRUE(message)) compat_logis_fe_report(model, method)
  compat_logis_fe_object(model, inputs)
}

# The old settings in the vocabulary of fit_logistic_fe() (NAMING.md §4). Values the
# reference accepts without checking are rejected by fit_logistic_fe() (D-22, D-23, D-39),
# except a non-integer max.iter, which the reference truncates, and a cutoff below 1 or
# between integers, which includes the same providers as the next integer above it.
compat_logis_fe_settings <- function(method, max_iter, tol, bound, cutoff, backtrack, stop, threads) {
  methods <- c(SerBIN = "serbin", BAN = "ban")
  if (!(is.character(method) && length(method) == 1L && method %in% names(methods))) {
    abort_invalid_input("Argument 'method' NOT as required!", arg = "method")
  }
  stop_rules <- c(or = "any", all = "all", beta = "coefficients", relch = "relative_loglik", ratch = "relative_gain")
  if (!(is.character(stop) && length(stop) == 1L && stop %in% names(stop_rules))) {
    abort_invalid_input("Argument 'stop' NOT as required!", arg = "stop")
  }
  if (is.numeric(backtrack) && length(backtrack) == 1L && !is.na(backtrack)) {
    # SerBIN tests backtrack as a C++ bool; BAN accepts only 0 and 1 (D-23).
    if (identical(method, "BAN") && !backtrack %in% c(0, 1)) {
      abort_invalid_input("`backtrack` must be TRUE or FALSE.", arg = "backtrack")
    }
    backtrack <- backtrack != 0
  }
  if (!(is.numeric(cutoff) && length(cutoff) == 1L && !is.na(cutoff))) {
    abort_invalid_input("`cutoff` must be a number.", arg = "cutoff")
  }
  list(
    method = methods[[method]], stop_rule = stop_rules[[stop]], backtrack = backtrack,
    max_iter = if (is.numeric(max_iter) && length(max_iter) == 1L && is.finite(max_iter)) trunc(max_iter) else max_iter,
    min_provider_size = max(1, ceiling(cutoff))
  )
}

# The reference's progress report (R/logis_fe.R:192-209, src/Fixed_effect.cpp): the
# screening report, and the iteration log, rebuilt from the fit's convergence history; a fit
# that reached the iteration limit says so (D-03).
compat_logis_fe_report <- function(model, method) {
  compat_screening_report(model)
  cat(sprintf("Implementing %s algorithm (Rcpp) for fixed provider effects model ...\n", method))
  convergence <- model$convergence
  labels <- c(any = "Minimum criterion across all checks", all = "Maximum criterion across all checks",
              coefficients = "Inf norm of running diff in est reg parm",
              relative_loglik = "Relative change in est log likelihood",
              relative_gain = "Adjusted relative change in est log likelihood")
  criteria <- convergence$history[, "rule"]
  for (k in seq_along(criteria)) {
    cat(sprintf("Iter %d: %s is %.3e;\n", k, labels[[convergence$stop_rule]], criteria[k]))
  }
  name <- if (identical(method, "SerBIN")) "serBIN" else "BAN"
  status <- if (isTRUE(convergence$converged)) "converged" else "not converged"
  cat(sprintf("%s (Rcpp) algorithm %s after %d iterations!\n", name, status, convergence$iterations))
  invisible(NULL)
}

# The screening report of the reference's logistic fixed-effect fits (R/logis_fe.R:192-209,
# R/logis_firth.R:160-176): the screening warning, with the count of the providers actually
# excluded (D-01), the counts of providers with no events and only events, and the event rate.
compat_screening_report <- function(model) {
  providers <- provider_table(model)
  warn_screening(sprintf("%d out of %d providers considered small and filtered out!", sum(!providers$included),
                         nrow(providers)))
  included <- providers[providers$included, , drop = FALSE]
  base::message(sprintf("%d out of %d remaining providers with no events.", sum(included$no_events), nrow(included)))
  base::message(sprintf("%d out of %d remaining providers with all events.", sum(included$all_events), nrow(included)))
  response <- model$response
  base::message(paste0("After screening, ", round(sum(response) / length(response) * 100, 2),
                       "% of all records exhibit occurrences of events (Y = 1)"))
  invisible(NULL)
}

# The help below lists the fixes the wrapper applies: D-18 (formulas), D-39 (input checks),
# D-05 (threads), D-42 (singular information), D-41 (factor IDs), and D-01 (the warning).
#' Main function for fitting the fixed effect logistic model using firth correction
#'
#' Fixed effects (FE) models suffer from separation issues when all outcomes in a cluster are the same,
#' leading to infinite estimates and unreliable inference.
#' Firth's corrected logistic regression (FLR) overcomes this limitation and
#' outperforms both FE and random effects (RE) models in terms of bias and RMSE.
#' This is the interface of pprof 1.0.3, kept for existing code; it calls [fit_logistic_firth()],
#' whose estimates are identical, and returns the object of pprof 1.0.3. It is deprecated as of
#' pprof 2.0.0 and warns once per session; see `vignette("migration", package = "pprof")`.
#'
#' @inheritParams logis_fe
#' @param max.iter maximum iteration number if the stopping criterion is not satisfied. The default value is 1,000.
#' @param tol tolerance used for stopping the algorithm: it stops when the largest absolute change of a
#'   coefficient is at most `tol`. The default value is 1e-5.
#' @param threads a positive integer specifying the number of threads to be used. The default value is 1.
#'   Results do not depend on it.
#'
#' @details
#' The function accepts three different input formats:
#' a formula and dataset, where the formula is of the form \code{response ~ covariates + id(provider)}, with
#'   \code{provider} representing the provider identifier;
#' a dataset along with the column names of the response, covariates, and provider identifier;
#' or the binary outcome vector \eqn{\boldsymbol{Y}}, the covariate matrix or data frame \eqn{\mathbf{Z}}, and the
#'   provider identifier vector.
#'
#' As in pprof 1.0.3, the variances, the log-likelihood, AIC, and BIC are those of the unpenalized likelihood at
#' the Firth estimates, and the object has class \code{"logis_fe"}, so the methods of [logis_fe()] apply.
#'
#' Unlike pprof 1.0.3, the formula may contain transformed terms, interactions, and factors whose levels contain
#' spaces; the outcome must be 0/1 or logical; `max.iter`, `tol`, and `bound` must be positive and `threads` at
#' least 1; two threads give the same results as one, where pprof 1.0.3 stopped early; a singular
#' information matrix gives an error, where pprof 1.0.3 ended the R session; factor provider IDs work when
#' providers are excluded; and the screening warning counts only the providers actually excluded.
#'
#' @seealso \code{\link{fit_logistic_firth}}, \code{\link{data_check}}
#'
#' @return A list of objects with S3 class \code{"logis_fe"}, as [logis_fe()] returns.
#'
#' @examples
#' data(ExampleDataBinary)
#' outcome <- ExampleDataBinary$Y
#' covar <- ExampleDataBinary$Z
#' ProvID <- ExampleDataBinary$ProvID
#' data <- data.frame(outcome, ProvID, covar)
#' covar.char <- colnames(covar)
#' outcome.char <- colnames(data)[1]
#' ProvID.char <- colnames(data)[2]
#' formula <- as.formula(paste("outcome ~", paste(covar.char, collapse = " + "), "+ id(ProvID)"))
#'
#' # Fit logistic linear effect model using three input formats
#' fit_fe1 <- logis_firth(Y = outcome, Z = covar, ProvID = ProvID)
#' fit_fe2 <- logis_firth(data = data, Y.char = outcome.char,
#' Z.char = covar.char, ProvID.char = ProvID.char)
#' fit_fe3 <- logis_firth(formula, data)
#'
#' @importFrom Rcpp evalCpp
#' @importFrom stats complete.cases terms model.matrix reformulate median
#'
#' @references
#' Firth, D. (1993) Bias reduction of maximum likelihood estimates.
#' \emph{Biometrika}, \strong{80(1)}: 27-38.
#' \cr
#'
#' @export
logis_firth <- function(formula = NULL, data = NULL,
                        Y.char = NULL, Z.char = NULL, ProvID.char = NULL, # nolint: object_name_linter.
                        Y = NULL, Z = NULL, ProvID = NULL, # nolint: object_name_linter.
                        max.iter = 1000, tol = 1e-5, bound = 10, # nolint: object_name_linter.
                        cutoff = 10, threads = 1, message = TRUE) {
  compat_deprecate("logis_firth")
  inputs <- compat_fe_inputs(formula, data, Y.char, Z.char, ProvID.char, Y, Z, ProvID)
  if (isTRUE(message)) base::message("Input format: ", inputs$format, ".")
  settings <- compat_logis_firth_settings(max.iter, cutoff)
  model <- withCallingHandlers(
    fit_logistic_firth(stats::reformulate(inputs$covariates, response = inputs$response), inputs$data,
                       inputs$provider, max_iter = settings$max_iter, tol = tol, effect_bound = bound,
                       min_provider_size = settings$min_provider_size, keep_data = TRUE, threads = threads),
    # The wrapper reports screening in the reference's words, and only with message = TRUE.
    # A fit that reaches the iteration limit warns (D-03).
    pprof_warning_screening = function(w) invokeRestart("muffleWarning")
  )
  if (isTRUE(message)) compat_logis_firth_report(model, threads)
  compat_logis_fe_object(model, inputs)
}

# The old settings of logis_firth() in the vocabulary of fit_logistic_firth(): max.iter
# truncated as Rcpp truncates it, and min_provider_size = max(1, ceiling(cutoff)), which
# includes the same providers as `cutoff`. The values the reference accepts without
# checking are rejected by fit_logistic_firth() (D-39).
compat_logis_firth_settings <- function(max_iter, cutoff) {
  if (!(is.numeric(cutoff) && length(cutoff) == 1L && !is.na(cutoff))) {
    abort_invalid_input("`cutoff` must be a number.", arg = "cutoff")
  }
  list(
    max_iter = if (is.numeric(max_iter) && length(max_iter) == 1L && is.finite(max_iter)) trunc(max_iter) else max_iter,
    min_provider_size = max(1, ceiling(cutoff))
  )
}

# The reference's progress report (R/logis_firth.R:160-176, src/Firth.cpp:88-131, :355-358,
# :406-408): the screening report and the iteration log, rebuilt from the fit's convergence
# history; a fit that reached the iteration limit says so (D-03).
compat_logis_firth_report <- function(model, threads) {
  compat_screening_report(model)
  cat("Implementing firth-corrected fixed provider effects model (Rcpp) ...\n")
  cat(sprintf("Algorithm (%d cores) ...\n", as.integer(threads)))
  convergence <- model$convergence
  criteria <- convergence$history[, "coefficients"]
  for (k in seq_along(criteria)) {
    cat(sprintf("Iter %d: Inf norm of running diff in est reg parm is %.3e;\n", k, criteria[k]))
  }
  status <- if (isTRUE(convergence$converged)) "converged" else "not converged"
  cat(sprintf("Algorithm with %d cores %s after %d iterations.\n", as.integer(threads), status,
              convergence$iterations))
  invisible(NULL)
}

#' Main function for fitting the fixed effect linear model
#'
#' Fit a fixed effect linear model via profile likelihood. This is the interface of pprof
#' 1.0.3, kept for existing code; it calls [fit_linear_fe()] and returns the object of
#' pprof 1.0.3. It is deprecated as of pprof 2.0.0 and warns once per session; see
#' `vignette("migration", package = "pprof")`.
#'
#' @inheritParams logis_fe
#' @param Y a numeric vector representing the response variable.
#' @param option.gamma.var a character string specifying the method to calculate the variance of provider effects
#'   \code{gamma}, must be \code{"full"} or \code{"simplified"}. You can specify just the initial letter.
#' \itemize{
#'    \item{\code{"simplified"}} (default) calculating the simplified variance of provider effects assuming
#'      regression coefficients are known.
#'    This approach is suitable for large datasets where the results of the full and simplified methods are similar,
#'    or when the full method may become unstable due to complex settings.
#'    \item{\code{"full"}} considering the correlation between provider effects and regression coefficients.
#' }
#'
#' @return A list of objects with S3 class \code{"linear_fe"}:
#' \item{coefficient}{a list containing the estimated coefficients:
#'   \code{beta}, the fixed effects for each predictor, and \code{gamma}, the effect for each provider.}
#' \item{variance}{a list containing the variance estimates:
#'   \code{beta}, the variance-covariance matrix of the predictor coefficients, and \code{gamma}, the variance of
#'   the provider effects.}
#' \item{sigma}{the residual standard error.}
#' \item{fitted}{the fitted values of each individual.}
#' \item{observation}{the original response of each individual.}
#' \item{residuals}{the residuals of each individual, that is response minus fitted values.}
#' \item{linear_pred}{the linear predictor of each individual.}
#' \item{data_include}{the data used to fit the model, sorted by the provider identifier.
#' For categorical covariates, this includes the dummy variables created for
#' all categories except the reference level.}
#' \item{char_list}{a list of the character vectors representing the column names for
#' the response variable, covariates, and provider identifier.
#' For categorical variables, the names reflect the dummy variables created for each category.}
#' \item{Loglkd}{log likelihood.}
#' \item{AIC}{Akaike information criterion.}
#' \item{BIC}{Bayesian information criterion.}
#'
#' @details
#' This function is used to fit a fixed effect linear model of the form:
#' \deqn{Y_{ij} = \gamma_i + \mathbf{Z}_{ij}^\top\boldsymbol\beta + \epsilon_{ij}}
#' where \eqn{Y_{ij}} is the continuous outcome for individual \eqn{j} in provider \eqn{i}, \eqn{\gamma_i} is the
#'   provider-specific effect,
#' \eqn{\mathbf{Z}_{ij}} are the covariates, and \eqn{\boldsymbol\beta} is the vector of coefficients for the
#'   covariates.
#'
#' The function accepts three different input formats:
#' a formula and dataset, where the formula is of the form \code{response ~ covariates + id(provider)}, with
#'   \code{provider} representing the provider identifier;
#' a dataset along with the column names of the response, covariates, and provider identifier;
#' or the outcome vector \eqn{\boldsymbol{Y}}, the covariate matrix or data frame \eqn{\mathbf{Z}}, and the provider
#'   identifier vector.
#'
#' If issues arise during model fitting, consider using the \code{data_check} function to perform a data quality
#'   check,
#' which can help identify missing values, low variation in covariates, high-pairwise correlation, and
#'   multicollinearity.
#' For datasets with missing values, this function automatically removes observations (rows) with any missing
#'   values before fitting the model.
#'
#' Unlike pprof 1.0.3, the coefficients come from the deviations of the outcome and the covariates from their
#' provider means instead of dense centering matrices, whose memory grows with the square of the provider sizes;
#' the estimates agree to rounding (about 1e-14). The formula may contain transformed terms, interactions, and
#' factors whose levels contain spaces.
#'
#' @seealso \code{\link{fit_linear_fe}}, \code{\link{data_check}}
#'
#' @importFrom stats complete.cases terms model.matrix reformulate as.formula
#'
#' @examples
#' data(ExampleDataLinear)
#' outcome <- ExampleDataLinear$Y
#' covar <- ExampleDataLinear$Z
#' ProvID <- ExampleDataLinear$ProvID
#' data <- data.frame(outcome, ProvID, covar)
#' covar.char <- colnames(covar)
#' outcome.char <- colnames(data)[1]
#' ProvID.char <- colnames(data)[2]
#' formula <- as.formula(paste("outcome ~", paste(covar.char, collapse = " + "), "+ id(ProvID)"))
#'
#' # Fit fixed linear effect model using three input formats
#' fit_fe1 <- linear_fe(Y = outcome, Z = covar, ProvID = ProvID)
#' fit_fe2 <- linear_fe(data = data, Y.char = outcome.char,
#' Z.char = covar.char, ProvID.char = ProvID.char)
#' fit_fe3 <- linear_fe(formula, data)
#'
#' @references
#' Hsiao, C. (2022). Analysis of panel data (No. 64). Cambridge university press.
#' \cr
#'
#' @export
linear_fe <- function(formula = NULL, data = NULL,
                      Y = NULL, Z = NULL, ProvID = NULL, # nolint: object_name_linter.
                      Y.char = NULL, Z.char = NULL, ProvID.char = NULL, # nolint: object_name_linter.
                      option.gamma.var = "simplified") { # nolint: object_name_linter.
  compat_deprecate("linear_fe")
  inputs <- compat_fe_inputs(formula, data, Y.char, Z.char, ProvID.char, Y, Z, ProvID)
  # D-36: linear_fe() always reports the input format.
  base::message("Input format: ", inputs$format, ".")
  model <- fit_linear_fe(stats::reformulate(inputs$covariates, response = inputs$response), inputs$data,
                         inputs$provider, provider_variance = compat_provider_variance(option.gamma.var),
                         keep_data = TRUE)
  compat_linear_fe_object(model, inputs)
}

# `option.gamma.var` in the vocabulary of fit_linear_fe() (K-42).
compat_provider_variance <- function(option) {
  if (is.character(option) && length(option) == 1L && option %in% c("full", "f")) return("full")
  if (is.character(option) && length(option) == 1L && option %in% c("simplified", "s")) return("simplified")
  abort_invalid_input("Argument 'option.gamma.var' should be 'full' or 'simplified'.", arg = "option.gamma.var")
}

#' Main Function for fitting the random effect linear model
#'
#' Fit a random effect linear model via \code{\link[lme4]{lmer}} from the \code{lme4} package. This is the
#' interface of pprof 1.0.3, kept for existing code; it fits the model with the same call as pprof 1.0.3 and
#' returns the object of pprof 1.0.3. [fit_linear_re()] is the new interface. It is deprecated as
#' of pprof 2.0.0 and warns once per session; see `vignette("migration", package = "pprof")`.
#'
#' @param formula a two-sided formula object describing the model to be fitted,
#' with the response variable on the left of a ~ operator and covariates on the right,
#' separated by + operators. The random effect of the provider identifier is specified using \code{(1 | )}.
#' @param data a data frame containing the variables named in the `formula`,
#' or the columns specified by `Y.char`, `Z.char`, and `ProvID.char`.
#' @param Y.char a character string specifying the column name of the response variable in the `data`.
#' @param Z.char a character vector specifying the column names of the covariates in the `data`.
#' @param ProvID.char a character string specifying the column name of the provider identifier in the `data`.
#' @param Y a numeric vector representing the response variable.
#' @param Z a matrix or data frame representing the covariates, which can include both numeric and categorical
#'   variables.
#' @param ProvID a numeric vector representing the provider identifier.
#' @param \dots additional arguments passed to \code{\link[lme4]{lmer}} for further customization.
#'
#' @return A list of objects with S3 class \code{"linear_re"}:
#' \item{coefficient}{a list containing the estimated coefficients:
#'   \code{FE}, the fixed effects for each predictor and the intercept, and \code{RE}, the random effects for each
#'   provider.}
#' \item{variance}{a list containing the variance estimates:
#'   \code{FE}, the variance-covariance matrix of the fixed effect coefficients, and \code{RE}, the variance of the
#'   random effects.}
#' \item{sigma}{the residual standard error.}
#' \item{fitted}{the fitted values of each individual.}
#' \item{observation}{the original response of each individual.}
#' \item{residuals}{the residuals of each individual, that is response minus fitted values.}
#' \item{linear_pred}{the linear predictor of each individual.}
#' \item{data_include}{the data used to fit the model, sorted by the provider identifier.
#' For categorical covariates, this includes the dummy variables created for
#' all categories except the reference level.}
#' \item{char_list}{a list of the character vectors representing the column names for
#' the response variable, covariates, and provider identifier.
#' For categorical variables, the names reflect the dummy variables created for each category.}
#' \item{Loglkd}{the log-likelihood.}
#' \item{AIC}{Akaike information criterion.}
#' \item{BIC}{Bayesian information criterion.}
#'
#' @details
#' This function is used to fit a random effect linear model of the form:
#' \deqn{Y_{ij} = \mu + \alpha_i + \mathbf{Z}_{ij}^\top\boldsymbol\beta + \epsilon_{ij}}
#' where \eqn{Y_{ij}} is the continuous outcome for individual \eqn{j} in provider \eqn{i},
#' \eqn{\mu} is the overall intercept, \eqn{\alpha_i} is the random effect for provider \eqn{i},
#' \eqn{\mathbf{Z}_{ij}} are the covariates, and \eqn{\boldsymbol\beta} is the vector of coefficients for the
#'   covariates.
#'
#' The model is fitted by overloading the \code{\link[lme4]{lmer}} function from the \code{lme4} package.
#' Three different input formats are accepted:
#' a formula and dataset, where the formula is of the form \code{response ~ covariates + (1 | provider)}, with
#'   \code{provider} representing the provider identifier;
#' a dataset along with the column names of the response, covariates, and provider identifier;
#' or the outcome vector \eqn{\boldsymbol{Y}}, the covariate matrix or data frame \eqn{\mathbf{Z}}, and the provider
#'   identifier vector.
#'
#' In addition to these input formats, all arguments from the \code{\link[lme4]{lmer}} function can be modified via
#'   \code{\dots},
#' allowing for customization of model fitting options such as controlling the optimization method or adjusting
#'   convergence criteria.
#' By default, the model is fitted using REML (restricted maximum likelihood).
#'
#' If issues arise during model fitting, consider using the \code{data_check} function to perform a data quality
#'   check,
#' which can help identify missing values, low variation in covariates, high-pairwise correlation, and
#'   multicollinearity.
#' For datasets with missing values, this function automatically removes observations (rows) with any missing
#'   values before fitting the model.
#'
#' Unlike pprof 1.0.3, a call that matches none of the three input formats, or a character `ProvID` with a matrix
#' `Z` (which `cbind()` would turn into text), gives a clear error.
#'
#' @seealso \code{\link{fit_linear_re}}, \code{\link{data_check}}
#'
#' @importFrom lme4 lmer fixef ranef
#' @importFrom stats complete.cases as.formula model.matrix fitted residuals logLik
#'
#' @export
#'
#' @examples
#' data(ExampleDataLinear)
#' outcome <- ExampleDataLinear$Y
#' covar <- ExampleDataLinear$Z
#' ProvID <- ExampleDataLinear$ProvID
#' data <- data.frame(outcome, ProvID, covar)
#' covar.char <- colnames(covar)
#' outcome.char <- colnames(data)[1]
#' ProvID.char <- colnames(data)[2]
#' formula <- as.formula(paste("outcome ~", paste(covar.char, collapse = " + "), "+ (1|ProvID)"))
#'
#' # Fit random effect linear model using three input formats
#' fit_re1 <- linear_re(Y = outcome, Z = covar, ProvID = ProvID)
#' fit_re2 <- linear_re(data = data, Y.char = outcome.char,
#' Z.char = covar.char, ProvID.char = ProvID.char)
#' fit_re3 <- linear_re(formula, data)
#'
#' @references
#' Bates D, Maechler M, Bolker B, Walker S (2015). \emph{Fitting Linear Mixed-Effects Models Using lme4}.
#' Journal of Statistical Software, 67(1), 1-48.
#' \cr
linear_re <- function(formula = NULL, data = NULL,
                      Y = NULL, Z = NULL, ProvID = NULL, # nolint: object_name_linter.
                      Y.char = NULL, Z.char = NULL, ProvID.char = NULL, ...) { # nolint: object_name_linter.
  compat_deprecate("linear_re")
  inputs <- compat_re_inputs(formula, data, Y.char, Z.char, ProvID.char, Y, Z, ProvID)
  # D-36: the random-effect fits always report the input format.
  base::message("Input format: ", inputs$format, ".")
  compat_re_object(compat_lme4_fit(inputs, "linear", ...), inputs, "linear_re")
}

#' Main Function for fitting the random effect logistic model
#'
#' Fit a random effect logistic model via \code{\link[lme4]{glmer}} from the \code{lme4} package. This is the
#' interface of pprof 1.0.3, kept for existing code; it fits the model with the same call as pprof 1.0.3 and
#' returns the object of pprof 1.0.3. [fit_logistic_re()] is the new interface. It is deprecated
#' as of pprof 2.0.0 and warns once per session; see `vignette("migration", package = "pprof")`.
#'
#' @inheritParams linear_re
#' @param \dots additional arguments passed to \code{\link[lme4]{glmer}} for further customization.
#'
#' @return A list of objects with S3 class \code{"logis_re"}:
#' \item{coefficient}{a list containing the estimated coefficients:
#'   \code{FE}, the fixed effects for each predictor and the intercept, and \code{RE}, the random effects for each
#'   provider.}
#' \item{variance}{a list containing the variance estimates:
#'   \code{FE}, the variance-covariance matrix of the fixed effect coefficients, and \code{RE}, the variance of the
#'   random effects.}
#' \item{fitted}{the predicted probability of each observation having a response of 1.}
#' \item{observation}{the original response of each individual.}
#' \item{linear_pred}{the linear predictor of each individual.}
#' \item{data_include}{the data used to fit the model, sorted by the provider identifier.
#' For categorical covariates, this includes the dummy variables created for
#' all categories except the reference level.}
#' \item{char_list}{a list of the character vectors representing the column names for
#' the response variable, covariates, and provider identifier.
#' For categorical variables, the names reflect the dummy variables created for each category.}
#' \item{Loglkd}{the log-likelihood.}
#' \item{AIC}{Akaike information criterion.}
#' \item{BIC}{Bayesian information criterion.}
#'
#' @details
#' This function is used to fit a random effect logistic model of the form:
#' \deqn{\text{logit}(P(Y_{ij} = 1 \mid \alpha_i, \mathbf{Z}_{ij})) = \mu + \alpha_i + \mathbf{Z}_{ij}^\top
#'   \boldsymbol{\beta},}
#' where \eqn{Y_{ij}} is the binary outcome for individual \eqn{j} in provider \eqn{i},
#' \eqn{\mu} is the overall intercept, \eqn{\alpha_i} is the random effect for provider \eqn{i},
#' \eqn{\mathbf{Z}_{ij}} are the covariates, and \eqn{\boldsymbol\beta} is the vector of coefficients for the
#'   covariates.
#'
#' The model is fitted by overloading the \code{\link[lme4]{glmer}} function from the \code{lme4} package.
#' Three different input formats are accepted:
#' a formula and dataset, where the formula is of the form \code{response ~ covariates + (1 | provider)}, with
#'   \code{provider} representing the provider identifier;
#' a dataset along with the column names of the response, covariates, and provider identifier;
#' or the outcome vector \eqn{\boldsymbol{Y}}, the covariate matrix or data frame \eqn{\mathbf{Z}}, and the provider
#'   identifier vector.
#'
#' In addition to these input formats, all arguments from the \code{\link[lme4]{glmer}} function can be modified
#'   via \code{\dots},
#' allowing for customization of model fitting options.
#'
#' If issues arise during model fitting, consider using the \code{data_check} function to perform a data quality
#'   check,
#' which can help identify missing values, low variation in covariates, high-pairwise correlation, and
#'   multicollinearity.
#' For datasets with missing values, this function automatically removes observations (rows) with any missing
#'   values before fitting the model.
#'
#' Unlike pprof 1.0.3, a call that matches none of the three input formats, or a character `ProvID` with a matrix
#' `Z` (which `cbind()` would turn into text), gives a clear error.
#'
#' @seealso \code{\link{fit_logistic_re}}, \code{\link{data_check}}
#'
#' @importFrom lme4 glmer fixef ranef
#' @importFrom stats complete.cases as.formula model.matrix fitted residuals logLik binomial
#'
#' @export
#'
#' @examples
#' data(ExampleDataBinary)
#' keep <- ExampleDataBinary$ProvID <= 20
#' outcome <- ExampleDataBinary$Y[keep]
#' covar <- ExampleDataBinary$Z[keep, ]
#' ProvID <- ExampleDataBinary$ProvID[keep]
#' data <- data.frame(outcome, ProvID, covar)
#' covar.char <- colnames(covar)
#' outcome.char <- colnames(data)[1]
#' ProvID.char <- colnames(data)[2]
#' formula <- as.formula(paste("outcome ~", paste(covar.char, collapse = " + "), "+ (1|ProvID)"))
#'
#' # Fit random effect logistic model using three input formats
#' fit_re1 <- logis_re(Y = outcome, Z = covar, ProvID = ProvID)
#' fit_re2 <- logis_re(data = data, Y.char = outcome.char,
#' Z.char = covar.char, ProvID.char = ProvID.char)
#' fit_re3 <- logis_re(formula, data)
#'
#' @references
#' Bates D, Maechler M, Bolker B, Walker S (2015). \emph{Fitting Linear Mixed-Effects Models Using lme4}.
#' Journal of Statistical Software, 67(1), 1-48.
#' \cr
logis_re <- function(formula = NULL, data = NULL,
                     Y = NULL, Z = NULL, ProvID = NULL, # nolint: object_name_linter.
                     Y.char = NULL, Z.char = NULL, ProvID.char = NULL, ...) { # nolint: object_name_linter.
  compat_deprecate("logis_re")
  inputs <- compat_re_inputs(formula, data, Y.char, Z.char, ProvID.char, Y, Z, ProvID)
  # D-36: the random-effect fits always report the input format.
  base::message("Input format: ", inputs$format, ".")
  compat_re_object(compat_lme4_fit(inputs, "logistic", ...), inputs, "logis_re")
}

#' Main Function for fitting correlated random effect linear model
#'
#' Fit a correlated  random effect linear model via \code{\link[lme4]{lmer}} from the \code{lme4} package. This is
#' the interface of pprof 1.0.3, kept for existing code; it fits the model with the same call as pprof 1.0.3 and
#' returns the object of pprof 1.0.3. [fit_linear_cre()] is the new interface. It is deprecated
#' as of pprof 2.0.0 and warns once per session; see `vignette("migration", package = "pprof")`.
#'
#' @param data a data frame containing all variables.
#' @param Y.char a character string specifying the column name of the response variable in the `data`.
#' @param wb.char a character vector specifying covariates to be decomposed into
#'   within (\code{*_within}) and between (\code{*_bar}) components.
#' @param other.char a character vector specifying additional covariates to include in the model without
#'   decomposition.
#' @param ProvID.char a character string specifying the column name of the provider identifier in the `data`.
#' @param \dots additional arguments passed to \code{\link[lme4]{lmer}} for further customization.
#'
#' @return A list of objects with S3 class \code{"linear_cre"}:
#' \item{coefficient}{a list containing the estimated coefficients:
#'   \code{FE}, the fixed effects for each predictor and the intercept, and \code{RE}, the random effects for each
#'   provider.}
#' \item{variance}{a list containing the variance estimates:
#'   \code{FE}, the variance-covariance matrix of the fixed effect coefficients, and \code{RE}, the variance of the
#'   random effects.}
#' \item{sigma}{the residual standard error.}
#' \item{fitted}{the fitted values of each individual.}
#' \item{observation}{the original response of each individual.}
#' \item{residuals}{the residuals of each individual, that is response minus fitted values.}
#' \item{linear_pred}{the linear predictor of each individual.}
#' \item{data_include}{the processed data used to fit the model, sorted by the provider identifier.
#' This includes the within-group (\code{*_within}) and between-group (\code{*_bar}) components for variables
#'   specified in \code{wb.char}.
#' For categorical covariates, it includes the dummy variables created for
#' all categories except the reference level.}
#' \item{char_list}{a list of the character vectors representing the column names for
#' the response variable, covariates, and provider identifier.
#' For categorical variables, the names reflect the dummy variables created for each category.}
#' \item{Loglkd}{the log-likelihood.}
#' \item{AIC}{Akaike information criterion.}
#' \item{BIC}{Bayesian information criterion.}
#'
#' @details
#' Fit a correlated random effect linear model using \code{\link[lme4]{lmer}} with a Mundlak
#' within-between decomposition for selected covariates. For each
#' decomposed covariate \eqn{Z_k}, the function constructs
#' \eqn{Z_{k,\mathrm{bar},i} = \frac{1}{n_i}\sum_j Z_{k,ij}} (the group mean, "between")
#' and \eqn{Z_{k,\mathrm{within},ij} = Z_{k,ij} - Z_{k,\mathrm{bar},i}} (the within-group deviation),
#' and estimates
#' \deqn{Y_{ij} = \mu + \alpha_i + \sum_k \beta_{k,W} Z_{k,\mathrm{within},ij}
#'       + \sum_k \beta_{k,B} Z_{k,\mathrm{bar},i}
#'       + \mathbf{X}_{ij}^\top\gamma + \varepsilon_{ij},}
#' where \eqn{\alpha_i \sim \mathcal{N}(0,\sigma_\alpha^2)} is a random intercept.
#'
#' The function creates, for every name in \code{wb.char}, two columns:
#' \code{<var>_bar} (group mean within \code{ProvID.char}) and
#' \code{<var>_within} (observation minus its group mean).
#' The fitted model is:
#' \preformatted{
#'   Y ~ <all *_within> + <all *_bar> + <other.char> + (1 | ProvID)
#' }
#'
#' All arguments from the \code{\link[lme4]{lmer}} function can be modified via \code{\dots},
#' allowing for customization of model fitting options such as controlling the optimization method or adjusting
#'   convergence criteria.
#' By default, the model is fitted using REML (restricted maximum likelihood).
#'
#' If issues arise during model fitting, consider using the \code{data_check} function to perform a data quality
#'   check,
#' which can help identify missing values, low variation in covariates, high-pairwise correlation, and
#'   multicollinearity.
#' For datasets with missing values, this function automatically removes observations (rows) with any missing
#'   values before fitting the model; the group means are computed over every row of `data`, before rows are
#'   removed.
#'
#' @seealso \code{\link{fit_linear_cre}}, \code{\link{data_check}}
#'
#' @importFrom lme4 lmer fixef ranef
#' @importFrom stats complete.cases as.formula model.matrix fitted residuals logLik
#'
#' @export
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
#'
#' # Fit a correlated random effect linear model
#' fit_cre <- linear_cre(data = data, Y.char = outcome.char, ProvID.char = ProvID.char,
#' wb.char = wb.char, other.char = other.char)
#'
#' @references
#' Bates D, Maechler M, Bolker B, Walker S (2015). \emph{Fitting Linear Mixed-Effects Models Using lme4}.
#' Journal of Statistical Software, 67(1), 1-48.
#' \cr
linear_cre <- function(data, Y.char, wb.char, other.char = NULL, ProvID.char, ...) { # nolint: object_name_linter.
  compat_deprecate("linear_cre")
  inputs <- compat_cre_inputs(data, Y.char, wb.char, other.char, ProvID.char)
  compat_re_object(compat_lme4_fit(inputs, "linear", ...), inputs, "linear_cre")
}

#' Main Function for fitting correlated random effect logistic model
#'
#' Fit a correlated random effect logistic model via \code{\link[lme4]{glmer}} from the \code{lme4} package. This
#' is the interface of pprof 1.0.3, kept for existing code; it fits the model with the same call as pprof 1.0.3
#' and returns the object of pprof 1.0.3. [fit_logistic_cre()] is the new interface. It is
#' deprecated as of pprof 2.0.0 and warns once per session; see
#' `vignette("migration", package = "pprof")`.
#'
#' @inheritParams linear_cre
#' @param \dots additional arguments passed to \code{\link[lme4]{glmer}} for further customization.
#'
#' @return A list of objects with S3 class \code{"logis_cre"}:
#' \item{coefficient}{a list containing the estimated coefficients:
#'   \code{FE}, the fixed effects for each predictor and the intercept, and \code{RE}, the random effects for each
#'   provider.}
#' \item{variance}{a list containing the variance estimates:
#'   \code{FE}, the variance-covariance matrix of the fixed effect coefficients, and \code{alpha}, the variance of
#'   the random effects.}
#' \item{fitted}{the predicted probability of each observation having a response of 1.}
#' \item{observation}{the original response of each individual.}
#' \item{linear_pred}{the linear predictor (on the logit scale, fixed effects only) of each individual.}
#' \item{data_include}{the processed data used to fit the model, sorted by the provider identifier.
#' This includes the within-group (\code{*_within}) and between-group (\code{*_bar}) components for variables
#'   specified in \code{wb.char}.}
#' \item{char_list}{a list of the character vectors representing the column names for
#' the response variable, the decomposed covariates, the other covariates, and provider identifier.}
#' \item{Loglkd}{the log-likelihood.}
#' \item{AIC}{Akaike information criterion.}
#' \item{BIC}{Bayesian information criterion.}
#'
#' @details
#' Fit a correlated random effect logistic model using \code{\link[lme4]{glmer}} with a Mundlak
#' within-between decomposition for selected covariates, as [linear_cre()] does. The fitted model is:
#' \preformatted{
#'   Y ~ <all *_within> + <all *_bar> + <other.char> + (1 | ProvID)
#' }
#' with a logit link and a normal random intercept, fitted with the Laplace approximation.
#'
#' All arguments from the \code{\link[lme4]{glmer}} function can be modified via \code{\dots}.
#'
#' For datasets with missing values, this function automatically removes observations (rows) with any missing
#'   values before fitting the model; the group means are computed over every row of `data`, before rows are
#'   removed.
#'
#' @seealso \code{\link{fit_logistic_cre}}, \code{\link{data_check}}
#'
#' @importFrom lme4 glmer fixef ranef
#' @importFrom stats complete.cases as.formula model.matrix fitted logLik
#'
#' @export
#'
#' @examples
#' data(ExampleDataBinary)
#' keep <- ExampleDataBinary$ProvID <= 20
#' data <- data.frame(outcome = ExampleDataBinary$Y[keep], ProvID = ExampleDataBinary$ProvID[keep],
#'                    ExampleDataBinary$Z[keep, ])
#'
#' # Fit a correlated random effect logistic model
#' fit_cre <- logis_cre(data = data, Y.char = "outcome", ProvID.char = "ProvID",
#' wb.char = c("z1", "z2"), other.char = c("z3", "z4", "z5"))
#'
#' @references
#' Bates D, Maechler M, Bolker B, Walker S (2015). \emph{Fitting Linear Mixed-Effects Models Using lme4}.
#' Journal of Statistical Software, 67(1), 1-48.
#' \cr
logis_cre <- function(data, Y.char, wb.char, other.char = NULL, ProvID.char, ...) { # nolint: object_name_linter.
  compat_deprecate("logis_cre")
  inputs <- compat_cre_inputs(data, Y.char, wb.char, other.char, ProvID.char)
  compat_logis_cre_object(compat_lme4_fit(inputs, "logistic", ...), inputs)
}

# The lme4 fit of a random-effect wrapper through the adapter, with the reference's formula
# and data (DEC-042). lme4's messages are printed, as the reference calls lme4 directly.
compat_lme4_fit <- function(inputs, outcome, ...) {
  engine <- lme4_fit(inputs$formula, inputs$data, outcome, ...)
  for (text in engine$messages) base::message(text)
  engine$fit
}
