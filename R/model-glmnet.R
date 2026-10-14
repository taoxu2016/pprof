# The glmnet adapter (COXPH_DESIGN §E.2; DEC-088, DEC-113 to DEC-115): the elastic-net Cox paths of the
# package are glmnet's, and the package computes no penalized likelihood, coordinate descent, score, or
# deviance itself (the CoxPH brief's §1).
#
# - glmnet is a suggested package (DEC-088): the functions that fit penalized paths call glmnet_require()
#   first, which raises a classed error naming it when it is missing or older than 5.0.
# - The call passes every argument that changes the path (the brief's §5.4): the grid, the tie method,
#   the standardization, the penalty factors, the response stratified by provider, the weights, the
#   offset, and control = list(thresh, maxit, fdev = 0, devmax = 1), so that glmnet keeps every point.
# - Columns whose weighted population variance is below penalized_degenerate_variance are left out
#   before the call, as pprof_py leaves them out (K-143): glmnet keeps such a column at 0 but rescales
#   the penalty factors over it too.
# - glmnet refuses a design of one column, so a single covariate gets a column of zeros beside it with
#   its penalty factor: glmnet leaves the constant column out of the fit, and its rescaling of the
#   factors leaves them as they are (dev/design/coxph-facts/26, part B).
# - The path ends at glmnet's last grid point when glmnet stops early (its iteration limit), and before
#   the first point whose solution is not one: coefficients that are not finite, or a deviance above
#   the null deviance (DEC-115, D-78).
# - The score at the null point of the grid comes from glmnet's coxgrad(), and the deviances of the
#   cross-validation from coxnet.deviance() (DEC-113, DEC-114).
# Rows with weight 0 are left out of every glmnet call (M-25).

# glmnet 5.0 or later: Cox models in its C++ engine, Efron ties (cox.ties), and per-call control.
glmnet_minimum_version <- "5.0"

glmnet_available <- function() {
  requireNamespace("glmnet", quietly = TRUE) && utils::packageVersion("glmnet") >= glmnet_minimum_version
}

glmnet_require <- function() {
  if (!glmnet_available()) {
    abort_invalid_input(sprintf(paste("Penalized Cox models are fitted by the package glmnet (%s or later), which is",
                                      "not installed: install.packages(\"glmnet\")."), glmnet_minimum_version),
                        package = "glmnet")
  }
  invisible(TRUE)
}

# The inputs of glmnet's Cox fits for the rows `rows`: the design, the Surv() response of the data's
# type stratified by provider (integer codes in provider order), and the weights and the offset, or NULL.
glmnet_inputs <- function(prepared, rows) {
  counting <- identical(prepared$settings$survival_type, "counting")
  response <- if (counting) {
    survival::Surv(prepared$start[rows], prepared$stop[rows], prepared$response[rows])
  } else {
    survival::Surv(prepared$stop[rows], prepared$response[rows])
  }
  list(
    x = data_subset_design(prepared$design, rows),
    y = glmnet::stratifySurv(response, as.integer(factor(prepared$provider_index[rows]))),
    weights = if (is.null(prepared$weights)) NULL else prepared$weights[rows],
    offset = if (is.null(prepared$offset)) NULL else prepared$offset[rows]
  )
}

# Each column's weighted population variance, with the weights normalized to sum to 1 (K-143).
glmnet_column_variance <- function(x, weights) {
  normalized <- if (is.null(weights)) rep(1 / nrow(x), nrow(x)) else weights / sum(weights)
  centered <- sweep(x, 2L, drop(crossprod(normalized, x)))
  drop(crossprod(normalized, centered^2))
}

# An error of glmnet becomes pprof_error_convergence with glmnet's message, as survival's do.
glmnet_abort <- function(e) {
  abort_convergence(sprintf("The glmnet fit failed: %s", conditionMessage(e)), engine_message = conditionMessage(e))
}

# glmnet's warning that it stopped before the end of the grid (a non-fatal error code: the iteration
# limit was reached at a grid point, and the solutions of the larger lambdas are returned).
glmnet_stopped_early <- function(message) {
  grepl("not reached", message, fixed = TRUE) || grepl("solutions for larger lambdas", message, fixed = TRUE)
}

# glmnet's path of the inputs' columns `keep` over `lambda`, with the penalty factors `factors` of those
# columns (DEC-113, DEC-115). Returns the path on the covariates' scale, one row per column of the
# design (0 for the columns left out) and one column per grid point reached; those points' lambda;
# glmnet's passes over the data; why the path ended early ("stopped", "failed", or NULL) and at which
# grid point; and glmnet's object.
glmnet_fit_path <- function(inputs, keep, factors, alpha, lambda, standardize, ties, tol, max_iter) {
  x <- inputs$x[, keep, drop = FALSE]
  if (ncol(x) == 1L) {
    x <- cbind(x, 0)
    factors <- c(factors, factors)
  }
  stopped <- NULL
  fit <- withCallingHandlers(
    tryCatch(
      glmnet::glmnet(x, inputs$y, family = "cox", weights = inputs$weights, offset = inputs$offset, alpha = alpha,
                     lambda = lambda, penalty.factor = factors, standardize = standardize, cox.ties = ties,
                     control = list(thresh = tol, maxit = max_iter, fdev = 0, devmax = 1)),
      error = glmnet_abort
    ),
    warning = function(w) {
      if (glmnet_stopped_early(conditionMessage(w))) {
        stopped <<- conditionMessage(w)
        invokeRestart("muffleWarning")
      }
    }
  )
  beta <- as.matrix(fit$beta)[seq_len(sum(keep)), , drop = FALSE]
  failed <- which(unname(fit$dev.ratio < penalized_deviance_ratio_floor | colSums(!is.finite(beta)) > 0))
  reached <- if (length(failed)) failed[1L] - 1L else length(fit$lambda)
  path <- matrix(0, length(keep), reached)
  path[keep, ] <- beta[, seq_len(reached)]
  end <- if (length(failed)) "failed" else if (!is.null(stopped)) "stopped"
  list(path = path, lambda = fit$lambda[seq_len(reached)], passes = as.integer(fit$npasses), end = end,
       end_point = if (!is.null(end)) reached + 1L, engine_message = stopped, engine = fit)
}

# The score of the partial likelihood over the weights' sum at the linear predictors `eta`, with respect
# to the coefficients of the inputs' columns `keep` divided by `scale` (pprof_py's scaled design): glmnet's
# gradient in the linear predictor (coxgrad(), with the weights normalized), times those columns.
glmnet_scaled_score <- function(inputs, keep, scale, eta, ties) {
  weights <- if (is.null(inputs$weights)) rep(1, nrow(inputs$x)) else inputs$weights
  gradient <- glmnet::coxgrad(eta, inputs$y, weights, std.weights = TRUE, cox.ties = ties)
  drop(crossprod(inputs$x[, keep, drop = FALSE], gradient)) / scale[keep]
}

# glmnet's Cox deviance of every column of `eta` (one linear predictor per column, offsets included)
# for the inputs' response and weights, with the weights as given: 2 (lsat - loglik), with glmnet's
# saturated term, which for Efron ties is not pprof_py's (K-144; the caller moves it).
glmnet_deviances <- function(inputs, eta, ties) {
  glmnet::coxnet.deviance(pred = eta, y = inputs$y, weights = inputs$weights, std.weights = FALSE, cox.ties = ties)
}
