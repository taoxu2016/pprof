# Compatibility wrappers for the fit functions of pprof 1.0.3 (ARCHITECTURE §I.2): they
# translate the old arguments, call the new fit functions, and return the old objects.

#' Main function for fitting the fixed effect logistic model
#'
#' Fit a fixed effect logistic model via Serial blockwise inversion Newton (SerBIN) or block
#' ascent Newton (BAN) algorithm. This is the interface of pprof 1.0.3, kept for existing
#' code; it calls [fit_logistic_fe()], whose estimates are identical, and returns the object
#' of pprof 1.0.3.
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
# screening warning, with the count of the providers actually excluded (D-01), the counts of
# providers with no events and only events, the event rate, and the iteration log, rebuilt
# from the fit's convergence history; a fit that reached the iteration limit says so (D-03).
compat_logis_fe_report <- function(model, method) {
  providers <- provider_table(model)
  warn_screening(sprintf("%d out of %d providers considered small and filtered out!", sum(!providers$included),
                         nrow(providers)))
  included <- providers[providers$included, , drop = FALSE]
  base::message(sprintf("%d out of %d remaining providers with no events.", sum(included$no_events), nrow(included)))
  base::message(sprintf("%d out of %d remaining providers with all events.", sum(included$all_events), nrow(included)))
  response <- model$response
  base::message(paste0("After screening, ", round(sum(response) / length(response) * 100, 2),
                       "% of all records exhibit occurrences of events (Y = 1)"))
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
