# The elastic-net Cox model (COXPH_DESIGN §A.5, §B, §D.4; DEC-088, DEC-090, DEC-113 to DEC-120): the fit
# function, pprof_py's lambda grid (K-143), the `pprof_cox_penalized` object, and its methods. The paths
# are glmnet's (R/model-glmnet.R); the selection of lambda by cross-validation is R/model-cox-selection.R.

#' Fit an elastic-net Cox path stratified by provider
#'
#' Fits the elastic-net Cox model over a path of penalties, with one baseline hazard per provider and
#' coefficients shared by all providers: pprof_py's `PenalizedCoxPH(strata = provider)`, fitted by
#' [glmnet::glmnet()] on pprof_py's grid of penalties. It minimizes
#' \eqn{-\ell(\beta)/\sum_i w_i + \lambda \sum_j f_j [\alpha |\beta_j| + (1 - \alpha) \beta_j^2 / 2]}
#' at each \eqn{\lambda}, with \eqn{\ell} the Breslow or Efron partial log-likelihood and \eqn{f_j}
#' the penalty factors. [select_lambda()] chooses \eqn{\lambda} by cross-validation.
#'
#' - **The grid.** Without `lambda`, it is pprof_py's: `n_lambda` values from \eqn{\lambda_{max}} down
#'   to \eqn{\lambda_{max}} times `lambda_min_ratio`, evenly spaced in \eqn{\log \lambda}.
#'   \eqn{\lambda_{max}} is the smallest penalty at which every penalized coefficient is 0: the largest
#'   score at the null point (penalized coefficients 0, unpenalized ones fitted) over the weights' sum,
#'   divided by its penalty factor and by \eqn{\max(\alpha, 0.001)}. `lambda_min_ratio` defaults to
#'   0.01 when there are fewer observations than covariates and to 0.0001 otherwise.
#' - **Scaling.** With `standardize = TRUE` the penalty applies to each covariate divided by its
#'   weighted standard deviation, and the coefficients are reported on the covariates' own scale.
#'   Covariates with no variation are left out with a classed warning
#'   (`pprof_warning_degenerate_covariates`) and have coefficient 0 at every \eqn{\lambda}.
#' - **Penalty factors** are rescaled over the covariates kept to sum to their number; a factor of 0
#'   leaves a covariate unpenalized.
#' - **The path ends early** when glmnet stops before the end of the grid (its iteration limit,
#'   `max_iter`, counts its passes over the data at all values of \eqn{\lambda} together) or when its
#'   solution at a value is not finite or has a deviance above the null deviance, which no solution
#'   has. The fit then warns (`pprof_warning_not_converged`) and keeps the values reached. This can
#'   happen with fewer events than covariates.
#'
#' Rows with weight 0 are left out of the fit, and rows with a missing value are dropped, as for
#' [fit_cox_stratified()]. The model offers no inference: no standard errors, tests, or intervals of
#' the coefficients, and no provider profiling, so [summary()], [confint()], [test_coefficients()],
#' and the profiling functions raise a `pprof_error_unsupported_inference` condition. glmnet (5.0 or
#' later) must be installed; it is a suggested package.
#'
#' @inheritParams fit_cox_stratified
#' @param alpha The elastic-net mixing parameter, between 0 (ridge) and 1 (lasso, the default).
#' @param lambda Decreasing positive penalties to fit instead of the default grid (they are sorted),
#'   or `NULL`.
#' @param n_lambda The number of penalties of the default grid.
#' @param lambda_min_ratio The smallest penalty of the default grid as a fraction of
#'   \eqn{\lambda_{max}}, in (0, 1], or `NULL` for 0.01 when there are fewer observations than
#'   covariates and 0.0001 otherwise.
#' @param penalty_factor Penalty factors of at least 0, named by coefficient (the columns of the
#'   design, for example `sexmale` for a factor `sex`); coefficients not named get 1. `NULL` gives 1 to
#'   every coefficient.
#' @param standardize Whether the penalty applies to the covariates divided by their weighted standard
#'   deviations.
#' @param max_iter glmnet's limit on its passes over the data, over the whole grid (its `maxit`).
#' @param tol glmnet's convergence threshold (its `thresh`).
#' @param keep_data Whether to keep the prepared data and glmnet's object. [select_lambda()] needs the
#'   data: kept here, or passed to it.
#' @param verbose Whether to report the events, the rows left out for weight 0, the grid, and glmnet's
#'   passes.
#'
#' @return An object of class `c("pprof_cox_penalized", "pprof_model")` with the fields every model has
#'   (see [new_pprof_model()]: `coefficients` are those at the selected \eqn{\lambda}, or before
#'   selection at the last \eqn{\lambda} of the path; `vcov` is a matrix of `NA`; `provider_effects`
#'   is `NULL`; `linear_predictor` is \eqn{x'\beta} at that \eqn{\lambda}; `convergence` holds glmnet's
#'   passes, whether the path reached every \eqn{\lambda} of the grid, and how many it reached) and
#'   `start`, `stop`, `weights`, `offset`, `lambda` (the path's penalties, decreasing), `lambda_max`,
#'   `lambda_min_ratio`, `coefficient_path` (one row per coefficient and one column per \eqn{\lambda}),
#'   `penalty_factor` (as given, by coefficient), `column_scale` (each covariate's divisor for the
#'   penalty), `degenerate` (the covariates left out), `n_events`, `n_zero_weight`, `selected` and
#'   `cross_validation` (`NULL` until [select_lambda()]), and with `keep_data = TRUE`, `engine_fit`,
#'   glmnet's object.
#' @seealso [select_lambda()], [cox_penalized_methods], [fit_cox_stratified()].
#' @family fitting functions
#' @examples
#' if (requireNamespace("glmnet", quietly = TRUE)) {
#'   lung <- survival::lung
#'   fit <- fit_cox_penalized(Surv(time, status) ~ age + sex + ph.karno + wt.loss, lung,
#'                            provider = "inst", n_lambda = 20)
#'   fit
#'   coef(fit)[, 1:3]
#'   # The unpenalized age, and cross-validation over 5 folds.
#'   fit <- fit_cox_penalized(Surv(time, status) ~ age + sex + ph.karno + wt.loss, lung,
#'                            provider = "inst", n_lambda = 20, penalty_factor = c(age = 0))
#'   set.seed(1)
#'   select_lambda(fit, n_folds = 5, data = lung)
#' }
#' @export
fit_cox_penalized <- function(formula, data, provider, weights = NULL, alpha = 1, lambda = NULL, n_lambda = 100,
                              lambda_min_ratio = NULL, penalty_factor = NULL, standardize = TRUE, ties = "breslow",
                              max_iter = 100000, tol = 1e-12, keep_data = FALSE, verbose = FALSE) {
  call <- match.call()
  glmnet_require()
  check_number(alpha, "alpha", lower = 0, upper = 1)
  cox_penalized_check_lambda(lambda)
  check_count(n_lambda, "n_lambda", min = 1)
  if (!is.null(lambda_min_ratio)) {
    check_number(lambda_min_ratio, "lambda_min_ratio", lower = 0, upper = 1)
    if (lambda_min_ratio == 0) abort_invalid_input("`lambda_min_ratio` must be above 0.", arg = "lambda_min_ratio")
  }
  check_flag(standardize, "standardize")
  check_choice(ties, c("breslow", "efron"), "ties")
  check_count(max_iter, "max_iter", min = 1)
  check_number(tol, "tol", lower = 0, open = TRUE)
  check_flag(keep_data, "keep_data")
  check_flag(verbose, "verbose")
  prepared <- data_prepare(formula, data, provider, event_counts = TRUE, response_type = "survival",
                           weights = weights, allow_offset = TRUE)
  names <- colnames(prepared$design)
  if (length(names) == 0L) abort_invalid_input("A penalized path needs at least one covariate.", arg = "formula")
  if (!all(is.finite(range(prepared$design)))) abort_invalid_input("The covariates must be finite.", arg = "formula")
  factors <- cox_penalized_factors(penalty_factor, names)
  rows <- survival_fit_rows(prepared)
  if (length(rows) == 0L) abort_data("No observation has a positive weight, so there is no data to fit.")
  if (!any(prepared$response[rows] == 1)) {
    abort_data("No events among the observations with positive weight: a Cox model needs at least one event.")
  }
  spec <- list(family = "cox_penalized", alpha = alpha, ties = ties, standardize = standardize, n_lambda = n_lambda,
               lambda_min_ratio = lambda_min_ratio, lambda = lambda, weights = weights, max_iter = max_iter, tol = tol,
               keep_data = keep_data)
  columns <- cox_penalized_columns(prepared, rows, standardize, factors)
  lambda_max <- cox_penalized_lambda_max(prepared, rows, columns, alpha, ties)
  # K-143: the ratio of the default grid counts every observation, those with weight 0 too, as pprof_py's
  # n_obs does, against the covariates kept.
  ratio <- if (!is.null(lambda_min_ratio)) {
    lambda_min_ratio
  } else if (length(prepared$response) < sum(columns$keep)) {
    penalized_ratio_wide
  } else {
    penalized_ratio_long
  }
  grid <- if (is.null(lambda)) {
    cox_penalized_grid(lambda_max, n_lambda, ratio)
  } else {
    sort(as.double(lambda), decreasing = TRUE)
  }
  path <- glmnet_fit_path(columns$inputs, columns$keep, columns$factors, alpha, grid, standardize, ties, tol, max_iter)
  if (length(path$lambda) == 0L) {
    abort_convergence("glmnet found no solution at the first value of lambda.", engine_message = path$engine_message)
  }
  cox_penalized_report(prepared, rows, columns, path, grid, max_iter, verbose)
  new_pprof_cox_penalized(prepared, path, spec, factors = factors, scale = columns$scale, keep = columns$keep,
                          lambda_max = lambda_max, ratio = ratio, n_events = as.integer(sum(prepared$response[rows])),
                          n_zero_weight = length(prepared$response) - length(rows), call = call, keep_data = keep_data)
}

cox_penalized_check_lambda <- function(lambda) {
  if (is.null(lambda)) return(invisible(NULL))
  ok <- is.numeric(lambda) && length(lambda) >= 1L && all(is.finite(lambda)) && all(lambda > 0) &&
    anyDuplicated(lambda) == 0L
  if (!ok) abort_invalid_input("`lambda` must hold distinct, finite, positive numbers, or be NULL.", arg = "lambda")
  invisible(lambda)
}

# The penalty factor of every coefficient: the user's, named by coefficient, and 1 for the others (K-143).
cox_penalized_factors <- function(penalty_factor, names) {
  factors <- stats::setNames(rep(1, length(names)), names)
  if (is.null(penalty_factor)) return(factors)
  given <- names(penalty_factor)
  ok <- is.numeric(penalty_factor) && length(penalty_factor) >= 1L && !is.null(given) && all(nzchar(given)) &&
    anyDuplicated(given) == 0L && all(is.finite(penalty_factor)) && all(penalty_factor >= 0)
  if (!ok) {
    abort_invalid_input("`penalty_factor` must hold finite numbers of at least 0, named by coefficient.",
                        arg = "penalty_factor")
  }
  unknown <- setdiff(given, names)
  if (length(unknown) > 0L) {
    abort_invalid_input(sprintf("`penalty_factor` names coefficients the model does not have: %s.",
                                paste(unknown, collapse = ", ")), arg = "penalty_factor")
  }
  factors[given] <- as.double(penalty_factor)
  factors
}

# The columns of a path on the rows `rows` (K-143): glmnet's inputs, the columns kept (weighted population
# variance at least penalized_degenerate_variance), each column's divisor for the penalty (its weighted
# standard deviation with `standardize`, otherwise 1, and 1 for a column left out), and the kept columns'
# penalty factors rescaled to sum to their number.
cox_penalized_columns <- function(prepared, rows, standardize, factors) {
  inputs <- glmnet_inputs(prepared, rows)
  variance <- glmnet_column_variance(inputs$x, inputs$weights)
  keep <- !(variance < penalized_degenerate_variance)
  if (!any(keep)) {
    abort_data(sprintf(paste("No covariate varies among the observations with positive weight (%s), so there is no",
                             "path to fit."), paste(colnames(prepared$design), collapse = ", ")))
  }
  scale <- rep(1, length(keep))
  if (standardize) scale[keep] <- sqrt(variance[keep])
  kept <- unname(factors[keep])
  if (!any(kept > 0)) {
    abort_invalid_input("`penalty_factor` must not be 0 for every covariate of the path: nothing would be penalized.",
                        arg = "penalty_factor")
  }
  list(inputs = inputs, keep = keep, scale = scale, factors = kept * (sum(keep) / sum(kept)))
}

# lambda_max (K-143): at the null point, where the penalized coefficients are 0 and the unpenalized ones are
# fitted by survival at pprof_py's settings, the largest score over the weights' sum, on the scaled
# covariates, divided by its penalty factor, over max(alpha, penalized_alpha_floor).
cox_penalized_lambda_max <- function(prepared, rows, columns, alpha, ties) {
  eta <- if (is.null(columns$inputs$offset)) rep(0, length(rows)) else columns$inputs$offset
  free <- columns$factors == 0
  if (any(free)) {
    unpenalized <- which(columns$keep)[free]
    z <- sweep(columns$inputs$x[, unpenalized, drop = FALSE], 2L, columns$scale[unpenalized], "/")
    null <- survival_fit_columns(prepared, rows, z, ties, penalized_null_tol, penalized_null_max_iter)
    if (anyNA(null$coefficients)) {
      aliased <- colnames(prepared$design)[unpenalized[is.na(null$coefficients)]]
      abort_data(sprintf(paste("The unpenalized covariates are linearly dependent, or constant within every provider,",
                               "so the path cannot start: %s."), paste(aliased, collapse = ", ")), aliased = aliased)
    }
    if (!isTRUE(null$converged)) {
      warn_not_converged(sprintf(paste("The fit of the unpenalized covariates at the start of the path reached its",
                                       "iteration limit (%d) without converging."), penalized_null_max_iter),
                         iterations = null$iterations)
    }
    eta <- eta + drop(z %*% null$coefficients)
  }
  score <- glmnet_scaled_score(columns$inputs, columns$keep, columns$scale, eta, ties)
  penalized <- columns$factors > 0
  max(abs(score[penalized]) / columns$factors[penalized]) / max(alpha, penalized_alpha_floor)
}

# pprof_py's grid (K-143): n_lambda values from lambda_max to lambda_max * ratio, evenly spaced in log lambda,
# as numpy.linspace() spaces them; all 0 when lambda_max is 0.
cox_penalized_grid <- function(lambda_max, n_lambda, ratio) {
  if (lambda_max == 0) return(rep(0, n_lambda))
  if (n_lambda == 1) return(lambda_max)
  exp(seq(log(lambda_max), log(lambda_max * ratio), length.out = n_lambda))
}

# The fit's warnings (degenerate covariates; a path that ended early) and, with `verbose`, its summary.
cox_penalized_report <- function(prepared, rows, columns, path, grid, max_iter, verbose) {
  degenerate <- colnames(prepared$design)[!columns$keep]
  if (length(degenerate) > 0L) {
    warn_degenerate_covariates(sprintf(paste("Covariates with no variation among the observations with positive weight",
                                             "are left out of the path, with coefficient 0: %s."),
                                       paste(degenerate, collapse = ", ")), covariates = degenerate)
  }
  if (identical(path$end, "stopped")) {
    warn_not_converged(sprintf(paste("glmnet reached its iteration limit (max_iter = %d) at lambda %d of %d, so the",
                                     "path ends at lambda %d; a larger max_iter may let it go further."),
                               as.integer(max_iter), path$end_point, length(grid), path$end_point - 1L),
                       iterations = path$passes)
  } else if (identical(path$end, "failed")) {
    warn_not_converged(sprintf(paste("glmnet's solution at lambda %d of %d is not finite or has a deviance above the",
                                     "null deviance, so the path ends at lambda %d."),
                               path$end_point, length(grid), path$end_point - 1L), iterations = path$passes)
  }
  inform_message(verbose, sprintf("%d events among %d observations of %d providers.", sum(prepared$response[rows]),
                                  length(prepared$response), sum(prepared$providers$included)))
  if (length(rows) < length(prepared$response)) {
    inform_message(verbose, sprintf("%d observations with weight 0 are left out of the fit.",
                                    length(prepared$response) - length(rows)))
  }
  inform_message(verbose, sprintf("%d of %d values of lambda reached, from %s to %s, in %d passes of glmnet.",
                                  length(path$lambda), length(grid), format(signif(grid[1L], 4)),
                                  format(signif(utils::tail(path$lambda, 1L), 4)), path$passes))
}

# The model object (COXPH_DESIGN §B.2): the shared fields, at the path's last lambda before a selection,
# and the path's fields.
new_pprof_cox_penalized <- function(data, path, spec, factors, scale, keep, lambda_max, ratio, n_events, n_zero_weight,
                                    call = NULL, keep_data = FALSE) {
  names <- colnames(data$design)
  coefficient_path <- path$path
  dimnames(coefficient_path) <- list(names, NULL)
  coefficients <- stats::setNames(coefficient_path[, ncol(coefficient_path)], names)
  p <- length(names)
  model <- new_pprof_model(
    data, coefficients = coefficients, vcov = matrix(NA_real_, p, p, dimnames = list(names, names)),
    provider_effects = NULL, linear_predictor = unname(drop(data$design %*% coefficients)), spec = spec,
    start = data$start, stop = data$stop, weights = data$weights, offset = data$offset, lambda = path$lambda,
    lambda_max = lambda_max, lambda_min_ratio = ratio, coefficient_path = coefficient_path, penalty_factor = factors,
    column_scale = stats::setNames(scale, names), degenerate = names[!keep], n_events = n_events,
    n_zero_weight = n_zero_weight, selected = NULL, cross_validation = NULL,
    convergence = list(iterations = path$passes, converged = is.null(path$end), grid_points = length(path$lambda),
                       stop_rule = "relative_objective", tol = spec$tol, max_iter = spec$max_iter),
    call = call, keep_data = keep_data, class = "pprof_cox_penalized"
  )
  if (keep_data) model$engine_fit <- path$engine
  validate_pprof_cox_penalized(model)
  model
}

validate_pprof_cox_penalized <- function(x) {
  fail <- function(what) abort_invalid_input(sprintf("Invalid `pprof_cox_penalized` object: %s.", what), arg = "x")
  if (!inherits(x, "pprof_cox_penalized")) fail("not of class `pprof_cox_penalized`")
  validate_pprof_model(x)
  if (!identical(x$spec$family, "cox_penalized")) fail("`spec$family` must be \"cox_penalized\"")
  if (!is.null(x$provider_effects)) fail("an elastic-net Cox model has no provider effects")
  n <- x$n_obs
  per_observation <- function(value) is.double(value) && is.null(dim(value)) && length(value) == n
  if (!per_observation(x$start) || !per_observation(x$stop) || !all(x$start < x$stop)) {
    fail("`start` and `stop` must give each observation's interval")
  }
  if (!all(x$response %in% c(0, 1))) fail("`response` must be the status, 0 or 1")
  for (field in c("weights", "offset")) {
    if (!is.null(x[[field]]) && !per_observation(x[[field]])) {
      fail(sprintf("`%s` must be NULL or one value per observation", field))
    }
  }
  lambda <- x$lambda
  if (!is.double(lambda) || length(lambda) == 0L || !all(is.finite(lambda)) || any(lambda < 0) ||
        is.unsorted(rev(lambda))) {
    fail("`lambda` must hold the path's penalties, decreasing")
  }
  names <- names(x$coefficients)
  path <- x$coefficient_path
  if (!is.matrix(path) || !is.double(path) || !identical(dim(path), c(length(names), length(lambda))) ||
        !identical(rownames(path), names)) {
    fail("`coefficient_path` must have one row per coefficient and one column per lambda")
  }
  if (!all(is.na(x$vcov))) fail("`vcov` must be NA: the model offers no inference")
  if (!is.double(x$penalty_factor) || !identical(names(x$penalty_factor), names) || any(x$penalty_factor < 0)) {
    fail("`penalty_factor` must give each coefficient's factor")
  }
  if (!is.double(x$column_scale) || !identical(names(x$column_scale), names) || !all(x$column_scale > 0)) {
    fail("`column_scale` must give each covariate's positive divisor")
  }
  index <- length(lambda)
  if (!is.null(x$selected)) {
    index <- x$selected$index
    if (!is.numeric(index) || length(index) != 1L || !index %in% seq_along(lambda) ||
          !identical(x$selected$lambda, lambda[index])) {
      fail("`selected` must name a lambda of the path")
    }
  }
  if (!identical(unname(x$coefficients), unname(path[, index]))) {
    fail("`coefficients` must be the path's at the selected lambda")
  }
  if (!is.null(x$engine_fit) && !inherits(x$engine_fit, "glmnet")) fail("`engine_fit` must be a glmnet object")
  invisible(x)
}

# --- Contract methods (COXPH_DESIGN §D.4) -------------------------------------------------------

#' @export
inference_capabilities.pprof_cox_penalized <- function(model) {
  # M-34: no provider profiling at a selected lambda in this phase, and no information-based inference
  # for a penalized fit (ARCHITECTURE §E.5).
  character()
}

# --- Standard methods (COXPH_DESIGN §B.1) --------------------------------------------------------

#' Methods of the elastic-net Cox model
#'
#' For models from [fit_cox_penalized()]:
#'
#' - `coef()` gives the coefficient path, one row per coefficient and one column per value of
#'   `model$lambda`, or with `lambda` the coefficients at that value, which must be one of the path's:
#'   the path holds glmnet's solutions only, and coefficients between them are not interpolated (fit
#'   the model with `lambda =` for other values).
#' - `predict()` gives the linear predictor \eqn{x'\beta} + offset, or the risk
#'   \eqn{\exp(x'\beta + \text{offset})}, at the selected \eqn{\lambda} (before a selection, the last
#'   of the path) or at `lambda`, for the observations of the fit (in the order of the rows of the
#'   data, and named by those rows) or for `newdata`.
#' - `nobs()` is the number of events of the fit, as for survival's `coxph()`.
#'
#' The model has no variances: `vcov()` is a matrix of `NA`, and [summary()], [confint()], and
#' [test_coefficients()] raise a `pprof_error_unsupported_inference` condition.
#'
#' @param object A model from [fit_cox_penalized()].
#' @param lambda A value of `object$lambda`, or `NULL`.
#' @param newdata A data frame with the covariates and the variables of the offset terms, or `NULL`
#'   for the observations of the fit.
#' @param type `"linear_predictor"` or `"risk"`.
#' @param ... Not used.
#'
#' @family model methods
#' @examples
#' if (requireNamespace("glmnet", quietly = TRUE)) {
#'   lung <- survival::lung
#'   fit <- fit_cox_penalized(Surv(time, status) ~ age + sex + ph.karno, lung, provider = "inst",
#'                            n_lambda = 10)
#'   coef(fit, lambda = fit$lambda[5])
#'   predict(fit, newdata = data.frame(age = c(50, 70), sex = c(1, 2), ph.karno = 90), type = "risk")
#'   nobs(fit)
#' }
#' @name cox_penalized_methods
NULL

#' @rdname cox_penalized_methods
#' @export
coef.pprof_cox_penalized <- function(object, lambda = NULL, ...) {
  if (is.null(lambda)) return(object$coefficient_path)
  object$coefficient_path[, cox_penalized_lambda_index(object, lambda)]
}

# The position of `lambda` on the model's path; values off the path raise (D-79).
cox_penalized_lambda_index <- function(model, lambda) {
  index <- if (is.numeric(lambda) && length(lambda) == 1L && is.finite(lambda)) match(lambda, model$lambda) else NA
  if (is.na(index)) {
    abort_invalid_input(paste("`lambda` must be one of the model's values of lambda (`model$lambda`); for another",
                              "value, fit the model with `lambda =`."), arg = "lambda")
  }
  index
}

#' @rdname cox_penalized_methods
#' @export
predict.pprof_cox_penalized <- function(object, newdata = NULL, type = "linear_predictor", lambda = NULL, ...) {
  check_choice(type, c("linear_predictor", "risk"), "type")
  coefficients <- if (is.null(lambda)) object$coefficients else coef(object, lambda)
  eta <- if (!is.null(newdata)) {
    parts <- cox_stratified_newdata(object, newdata)
    unname(drop(parts$design %*% coefficients) + parts$offset)
  } else {
    lp <- if (is.null(lambda)) {
      object$linear_predictor
    } else if (!is.null(object$data)) {
      unname(drop(object$data$design %*% coefficients))
    } else {
      abort_data_required(paste("The observations' linear predictors at another lambda need the covariates: fit the",
                                "model with keep_data = TRUE, or pass them as `newdata`."))
    }
    model_input_order(object, if (is.null(object$offset)) lp else lp + object$offset)
  }
  if (identical(type, "risk")) exp(eta) else eta
}

#' @rdname cox_penalized_methods
#' @export
nobs.pprof_cox_penalized <- function(object, ...) object$n_events
