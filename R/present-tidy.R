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
augment.pprof_model <- function(x, ...) {
  fitted <- stats::fitted(x)
  order <- order(x$row_index)
  tibble::tibble(
    row = x$row_index[order], provider_id = provider_table(x)$provider_id[provider_index(x)][order],
    observed = as.numeric(observed_outcome(x))[order], fitted = unname(fitted),
    residual = unname(stats::residuals(x, type = "response"))
  )
}
