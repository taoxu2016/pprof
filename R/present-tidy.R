# tidy(), glance(), and augment() through the generics package (ARCHITECTURE §D.3).

#' @importFrom generics tidy
#' @export
generics::tidy

#' @importFrom generics glance
#' @export
generics::glance

#' @importFrom generics augment
#' @export
generics::augment

#' Tidy outputs of models and results
#'
#' - `tidy()` of a model: the covariate coefficients with their Wald tests and intervals
#'   (see [test_coefficients()]); of a result object: its table.
#' - `glance()` of a model: one row with the dimensions, the fit statistics, and the
#'   convergence of the fit.
#' - `augment()` of a model: one row per observation used in the fit, in the order of the
#'   input data, with its row in the input data (`row`), provider, observed outcome, fitted
#'   value, and response residual.
#'
#' For Cox models from [fit_cox_stratified()], `glance()` also has `n_events`, and its `loglik`,
#' `aic`, and `bic` are those of the partial log-likelihood, as for survival's `coxph()` (with
#' the number of events as the number of observations); `augment()`'s `observed` is the status,
#' `fitted` each observation's expected number of events under the fitted model, and `residual`
#' the martingale residual, observed minus fitted, missing for observations with weight 0.
#'
#' For elastic-net Cox models from [fit_cox_penalized()], which offer no inference, `tidy()` gives
#' each coefficient (`term`) and its `estimate` at the selected \eqn{\lambda} (before a selection, the
#' last of the path); `glance()` the dimensions, `n_events`, `alpha`, the number of values of
#' \eqn{\lambda} (`n_lambda`), the selected `lambda` and `rule` (missing before a selection), glmnet's
#' passes over the data (`iterations`), and whether its path reached every value (`converged`); and
#' `augment()` raises a `pprof_error_unsupported_inference` condition.
#'
#' @param x A model object, or a result object of the profiling functions.
#' @param level The confidence level of the coefficient intervals.
#' @param ... Not used.
#'
#' @return A tibble.
#' @examples
#' data(ExampleDataBinary)
#' example <- data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID,
#'                       ExampleDataBinary$Z)
#' fit <- fit_logistic_fe(y ~ z1 + z2 + z3 + z4 + z5, example, provider = "hospital")
#' tidy(fit)
#' glance(fit)
#' head(augment(fit))
#' tidy(test_providers(fit))
#' @family model methods
#' @name pprof_tidy
NULL

#' @rdname pprof_tidy
#' @export
tidy.pprof_model <- function(x, level = 0.95, ...) {
  tibble::as_tibble(test_coefficients(x, "wald", level = level)$table)
}

#' @rdname pprof_tidy
#' @export
tidy.pprof_result <- function(x, ...) {
  tibble::as_tibble(x$table)
}

#' @rdname pprof_tidy
#' @export
glance.pprof_model <- function(x, ...) {
  field <- function(value) if (is.null(value)) NA_real_ else as.double(value)
  convergence <- x$convergence
  tibble::tibble(
    n_obs = x$n_obs, n_providers = x$n_providers, n_excluded_providers = x$n_excluded_providers,
    loglik = field(x$loglik), aic = field(x$aic), bic = field(x$bic), auc = field(x$auc),
    iterations = if (is.null(convergence$iterations)) NA_integer_ else as.integer(convergence$iterations),
    converged = if (is.null(convergence$converged)) NA else convergence$converged
  )
}

#' @rdname pprof_tidy
#' @export
glance.pprof_cox_stratified <- function(x, ...) {
  # The partial log-likelihood at the estimates, and AIC and BIC from it as for survival's coxph():
  # as many degrees of freedom as coefficients, and the events as the observations (DEC-103).
  partial <- stats::logLik(x)
  aic <- stats::AIC(partial)
  bic <- stats::BIC(partial)
  convergence <- x$convergence
  tibble::tibble(
    n_obs = x$n_obs, n_providers = x$n_providers, n_excluded_providers = x$n_excluded_providers,
    n_events = x$n_events, loglik = as.double(partial), aic = aic, bic = bic, auc = NA_real_,
    iterations = as.integer(convergence$iterations), converged = convergence$converged
  )
}

#' @rdname pprof_tidy
#' @export
augment.pprof_cox_stratified <- function(x, ...) {
  # The fitted value of an observation is its expected number of events under the fitted model,
  # the status minus the martingale residual (DEC-103); missing for rows with weight 0.
  order <- order(x$row_index)
  observed <- as.numeric(observed_outcome(x))[order]
  residual <- x$martingale_residuals[order]
  tibble::tibble(
    row = x$row_index[order], provider_id = provider_table(x)$provider_id[provider_index(x)][order],
    observed = observed, fitted = observed - residual, residual = residual
  )
}

#' @rdname pprof_tidy
#' @export
tidy.pprof_cox_penalized <- function(x, ...) {
  # No standard errors, tests, or intervals for a penalized fit (DEC-120).
  tibble::tibble(term = names(x$coefficients), estimate = unname(x$coefficients))
}

#' @rdname pprof_tidy
#' @export
glance.pprof_cox_penalized <- function(x, ...) {
  selected <- x$selected
  tibble::tibble(
    n_obs = x$n_obs, n_providers = x$n_providers, n_excluded_providers = x$n_excluded_providers,
    n_events = x$n_events, alpha = x$spec$alpha, n_lambda = length(x$lambda),
    lambda = if (is.null(selected)) NA_real_ else selected$lambda,
    rule = if (is.null(selected)) NA_character_ else selected$rule,
    iterations = as.integer(x$convergence$iterations), converged = x$convergence$converged
  )
}

#' @rdname pprof_tidy
#' @export
augment.pprof_cox_penalized <- function(x, ...) {
  abort_unsupported_inference(x, "augment()")
}

#' @rdname pprof_tidy
#' @export
glance.pprof_fine_gray <- function(x, ...) {
  # The stratified Cox model's columns (DEC-103), with the competing events (DEC-128); the log-likelihood,
  # AIC, and BIC are those of the weighted expanded data, as survival's coxph() reports them.
  partial <- stats::logLik(x)
  convergence <- x$convergence
  tibble::tibble(
    n_obs = x$n_obs, n_providers = x$n_providers, n_excluded_providers = x$n_excluded_providers,
    n_events = x$n_events, n_competing = x$n_competing, loglik = as.double(partial), aic = stats::AIC(partial),
    bic = stats::BIC(partial), auc = NA_real_, iterations = as.integer(convergence$iterations),
    converged = convergence$converged
  )
}

#' @rdname pprof_tidy
#' @export
augment.pprof_fine_gray <- function(x, ...) {
  # D-81: the fitted values and residuals of the expanded rows do not belong to the observations.
  abort_unsupported_inference(x, "augment()")
}

#' @rdname pprof_tidy
#' @export
augment.pprof_model <- function(x, ...) {
  fitted <- stats::fitted(x)
  order <- order(x$row_index)
  tibble::tibble(
    row = x$row_index[order], provider_id = provider_table(x)$provider_id[provider_index(x)][order],
    observed = as.numeric(observed_outcome(x))[order], fitted = unname(fitted),
    residual = unname(stats::residuals(x, type = "response"))
  )
}
