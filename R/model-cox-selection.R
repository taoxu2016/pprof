# The selection of lambda of a penalized path by cross-validation (COXPH_DESIGN §A.5, §E.2; K-144, M-30,
# D-61; DEC-114): pprof_py's PenalizedCoxPHCV, with each fold's path from glmnet and the fold deviances,
# their summaries, and the rules computed here.

#' Select the penalty of a penalized model by cross-validation
#'
#' Chooses \eqn{\lambda} on the path of a model from [fit_cox_penalized()] by K-fold cross-validation,
#' as pprof_py's `PenalizedCoxPHCV` does, and returns the model with its coefficients at that
#' \eqn{\lambda}.
#'
#' - **Folds.** `folds` gives each row of the data its fold, 1 to K (or 0 to K - 1), with at least two
#'   folds. Without it, the folds are drawn with R's random numbers (set a seed with [set.seed()] to
#'   reproduce them): the observations with an event, then those without, each in the order of the
#'   data, get a random permutation of the labels 1 to `n_folds` repeated to their number, so that
#'   every fold has about the same number of events.
#' - **Each fold's path** is fitted on the other folds' observations over the model's \eqn{\lambda},
#'   with the model's settings; covariates with no variation there are left out of that fold's path.
#' - **The fold deviance** at each \eqn{\lambda} is the deviance of all observations less that of the
#'   training observations, both at the fold's coefficients, divided by the summed weight of the
#'   fold's events. The deviance is 2 (saturated log-likelihood - partial log-likelihood), with the
#'   saturated term in the Breslow form, \eqn{-\sum w_t \log w_t} over each provider's event times,
#'   whatever the tie method.
#' - **The summaries** are the mean of the fold deviances weighted by the folds' event weights
#'   (`cvm`) and its standard error (`cvsd`, the weighted standard deviation over \eqn{\sqrt{K - 1}}).
#'   A \eqn{\lambda} at which a fold's deviance is not finite, or which a fold's path did not reach, is
#'   not selected.
#' - **The rules.** `"min"` selects the first \eqn{\lambda} (the largest) with the smallest `cvm`;
#'   `"1se"`, the default, the first \eqn{\lambda} whose `cvm` is at most the smallest plus its `cvsd`.
#'
#' The fits are glmnet's; the deviances come from glmnet's `coxnet.deviance()`, with the saturated term
#' brought to the Breslow form through survival's partial log-likelihood. Rows with weight 0 have a fold
#' but are left out of the fits and the deviances. There is no bootstrap standard error.
#'
#' @param model A model from [fit_cox_penalized()].
#' @param folds The fold of each row of the data the model was fit to (rows dropped for missing values
#'   are ignored), or `NULL` to draw them.
#' @param n_folds The number of folds to draw, at least 3.
#' @param rule `"1se"` or `"min"`.
#' @param data The data the model was fit to, when the model was fit without `keep_data = TRUE`.
#' @param ... Not used.
#'
#' @return The model, with `coefficients` and `linear_predictor` at the selected \eqn{\lambda},
#'   `selected` (`lambda`, its `index` on the path, and the `rule`), and `cross_validation`: `lambda`,
#'   `cvm`, `cvsd`, `fold_deviance` (one row per fold), `held_out_weight` (each fold's summed event
#'   weight), `folds` (each row's fold, `NA` for rows not in the model), `n_folds_used` (the folds with a
#'   finite deviance at each \eqn{\lambda}), `lambda_min`, `lambda_1se`, and `rule`.
#' @seealso [fit_cox_penalized()].
#' @examples
#' if (requireNamespace("glmnet", quietly = TRUE)) {
#'   lung <- survival::lung
#'   fit <- fit_cox_penalized(Surv(time, status) ~ age + sex + ph.karno + wt.loss, lung,
#'                            provider = "inst", n_lambda = 10, keep_data = TRUE)
#'   set.seed(1)
#'   selected <- select_lambda(fit, n_folds = 3)
#'   selected$selected
#'   coef(selected, lambda = selected$cross_validation$lambda_min)
#' }
#' @export
select_lambda <- function(model, ...) UseMethod("select_lambda")

#' @export
select_lambda.default <- function(model, ...) {
  abort_invalid_input(sprintf("`model` must be a model from fit_cox_penalized(), not an object of class '%s'.",
                              class(model)[1]), arg = "model")
}

#' @rdname select_lambda
#' @export
select_lambda.pprof_cox_penalized <- function(model, folds = NULL, n_folds = 10, rule = "1se", data = NULL, ...) {
  glmnet_require()
  check_choice(rule, c("1se", "min"), "rule")
  if (length(model$lambda) < 2L) {
    abort_invalid_input("Cross-validation needs a path of at least two values of lambda.", arg = "model")
  }
  prepared <- model_prepared_data(model, data)
  if (is.null(folds)) {
    check_count(n_folds, "n_folds", min = 3)
    fold <- cox_penalized_draw_folds(prepared, n_folds)
  } else {
    fold <- cox_penalized_given_folds(folds, prepared)
  }
  cv <- cox_penalized_cross_validation(model, prepared, fold)
  index <- if (identical(rule, "min")) cv$best else cv$one_se
  model$coefficients <- model$coefficient_path[, index]
  model$linear_predictor <- unname(drop(prepared$design %*% model$coefficients))
  model$selected <- list(lambda = model$lambda[index], index = index, rule = rule)
  by_row <- rep(NA_integer_, prepared$n_input)
  by_row[prepared$row_index] <- fold
  model$cross_validation <- list(lambda = model$lambda, cvm = cv$cvm, cvsd = cv$cvsd, fold_deviance = cv$deviance,
                                 held_out_weight = cv$held_out_weight, folds = by_row, n_folds_used = cv$n_folds_used,
                                 lambda_min = model$lambda[cv$best], lambda_1se = model$lambda[cv$one_se], rule = rule)
  validate_pprof_cox_penalized(model)
  model
}

# Event-stratified folds drawn with R's random numbers (K-144, D-61): the observations with an event, then
# those without, each in the order of the input rows, get a random permutation of the labels 1..n_folds
# repeated to their number. One fold per observation of `prepared`, in its order.
cox_penalized_draw_folds <- function(prepared, n_folds) {
  input_order <- order(prepared$row_index)
  status <- prepared$response[input_order]
  folds <- integer(length(status))
  for (group in list(which(status == 1), which(status == 0))) {
    if (length(group) > 0L) {
      labels <- rep_len(seq_len(n_folds), length(group))
      folds[input_order[group]] <- labels[sample.int(length(group))]
    }
  }
  folds
}

# The folds given for the rows of the data (K-144): whole numbers, one per row, whose labels over the
# model's observations are 1..K or 0..K-1 with K at least 2, as pprof_py accepts. One fold per observation
# of `prepared`, in its order.
cox_penalized_given_folds <- function(folds, prepared) {
  fail <- function() {
    abort_invalid_input(sprintf(paste("`folds` must give each of the %d rows of the data a whole number, with labels 1",
                                      "to K or 0 to K - 1 over the model's observations and at least two folds."),
                                prepared$n_input), arg = "folds")
  }
  if (!is.numeric(folds) || length(folds) != prepared$n_input) fail()
  fold <- folds[prepared$row_index]
  if (!all(is.finite(fold)) || any(fold != round(fold))) fail()
  labels <- sort(unique(fold))
  k <- length(labels)
  contiguous <- isTRUE(all.equal(labels, seq_len(k), check.attributes = FALSE)) ||
    isTRUE(all.equal(labels, seq_len(k) - 1L, check.attributes = FALSE))
  if (k < 2L || !contiguous) fail()
  fold
}

# pprof_py's saturated log-likelihood of the rows `rows` (K-144; pprof_py/utils/deviance.py:43-63):
# -sum(w_t log w_t) over each provider's distinct event times, w_t the summed weight of the events at t,
# in the Breslow form whatever the tie method.
cox_saturated_loglik <- function(prepared, rows) {
  events <- rows[prepared$response[rows] == 1]
  if (length(events) == 0L) return(0)
  weights <- if (is.null(prepared$weights)) rep(1, length(events)) else prepared$weights[events]
  times <- prepared$stop[events]
  distinct <- sort(unique(times))
  key <- (prepared$provider_index[events] - 1) * length(distinct) + match(times, distinct)
  sums <- rowsum(weights, key)
  sums <- sums[sums > 0]
  -sum(sums * log(sums))
}

# The shift from glmnet's deviance to pprof_py's for the rows `rows` (K-144, DEC-114): glmnet's deviance at
# the offsets less 2 (lsat - loglik), with pprof_py's saturated term and survival's partial log-likelihood
# of the offsets. A deviance less the shift is pprof_py's, whatever the linear predictor, since both
# saturated terms are constants of the rows; with Breslow ties the shift is 0 up to rounding.
cox_penalized_deviance_shift <- function(prepared, rows, inputs, ties) {
  offset <- if (is.null(inputs$offset)) rep(0, length(rows)) else inputs$offset
  glmnet <- glmnet_deviances(inputs, matrix(offset, ncol = 1L), ties)
  glmnet - 2 * (cox_saturated_loglik(prepared, rows) - survival_partial_loglik(prepared, rows, offset, ties))
}

# pprof_py's cross-validation (K-144) of `model` on the observations of `prepared`, with the folds `fold`
# (one per observation): each fold's path on its training observations with positive weight over the
# model's lambda (glmnet), the fold deviances of every lambda at once (glmnet's coxnet.deviance(), moved to
# pprof_py's saturated term), cvm, cvsd, the folds with a finite deviance, and the positions of lambda_min
# and lambda_1se.
cox_penalized_cross_validation <- function(model, prepared, fold) {
  spec <- model$spec
  grid <- model$lambda
  rows <- survival_fit_rows(prepared)
  labels <- sort(unique(fold))
  event_weight <- prepared$response * (if (is.null(prepared$weights)) 1 else prepared$weights)
  held_out_weight <- vapply(labels, function(k) sum(event_weight[fold == k]), numeric(1))
  if (any(held_out_weight <= 0)) {
    abort_data(sprintf("Fold %s has no event with positive weight, so its deviance cannot be normalized.",
                       paste(labels[held_out_weight <= 0], collapse = ", ")))
  }
  all_inputs <- glmnet_inputs(prepared, rows)
  all_shift <- cox_penalized_deviance_shift(prepared, rows, all_inputs, spec$ties)
  deviance <- matrix(NA_real_, length(labels), length(grid))
  ended <- integer()
  for (i in seq_along(labels)) {
    train <- rows[fold[rows] != labels[i]]
    columns <- cox_penalized_columns(prepared, train, spec$standardize, model$penalty_factor)
    path <- glmnet_fit_path(columns$inputs, columns$keep, columns$factors, spec$alpha, grid, spec$standardize,
                            spec$ties, spec$tol, spec$max_iter)
    if (!is.null(path$end)) ended <- c(ended, labels[i])
    reached <- length(path$lambda)
    if (reached == 0L) next
    eta <- all_inputs$x %*% path$path
    if (!is.null(all_inputs$offset)) eta <- eta + all_inputs$offset
    training <- match(train, rows)
    all_deviance <- glmnet_deviances(all_inputs, eta, spec$ties) - all_shift
    train_deviance <- glmnet_deviances(columns$inputs, eta[training, , drop = FALSE], spec$ties) -
      cox_penalized_deviance_shift(prepared, train, columns$inputs, spec$ties)
    deviance[i, seq_len(reached)] <- (all_deviance - train_deviance) / held_out_weight[i]
  }
  if (length(ended) > 0L) {
    warn_not_converged(sprintf(paste("glmnet's path ended early in fold %s, so the values of lambda it did not reach",
                                     "there are not selected."), paste(ended, collapse = ", ")), folds = ended)
  }
  finite <- colSums(!is.finite(deviance)) == 0L
  cvm <- cvsd <- rep(NA_real_, length(grid))
  total <- sum(held_out_weight)
  cvm[finite] <- colSums(held_out_weight * deviance[, finite, drop = FALSE]) / total
  cvsd[finite] <- sqrt(colSums(held_out_weight * sweep(deviance[, finite, drop = FALSE], 2L, cvm[finite])^2) / total /
                         (length(labels) - 1L))
  valid <- is.finite(cvm) & is.finite(cvsd)
  if (!any(valid)) {
    abort_data("No value of lambda has a finite deviance in every fold, so cross-validation cannot select one.")
  }
  best <- which(valid)[which.min(cvm[valid])]
  one_se <- which(valid & cvm <= cvm[best] + cvsd[best])[1L]
  list(deviance = deviance, held_out_weight = held_out_weight, cvm = cvm, cvsd = cvsd,
       n_folds_used = as.integer(colSums(is.finite(deviance))), best = best, one_se = one_se)
}
