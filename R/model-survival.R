# The survival adapter (COXPH_DESIGN §E.1; DEC-091, DEC-099, DEC-100): the Cox fits of the package
# are survival's, and the package never computes a partial likelihood, a Newton step, a variance, a
# residual, or a baseline hazard itself (the CoxPH brief's §1).
#
# - The fit calls survival's fitters, coxph.fit() for right-censored data and agreg.fit() for
#   counting-process data, with the arguments coxph() passes them, so that the fit is
#   coxph(timefix = FALSE, robust = FALSE)'s, bitwise (dev/design/coxph-facts/17 and 18).
# - The robust variance is coxph()'s own robust step on the fitter's result (DEC-099).
# - The methods that need a coxph object (baselines, cumulative hazards and survival curves, score
#   and dfbeta residuals) get one from coxph() on the prepared data, with the fit's settings.
# Rows with weight 0 are left out of every survival call and kept in the data (M-25).

# coxph()'s default: columns whose values are all among these are not centered (survival 3.8-12).
survival_nocenter <- c(-1, 0, 1)

# The rows of the prepared data that the Cox fits use: those with positive weight (M-25).
survival_fit_rows <- function(prepared) {
  weights <- prepared$weights
  if (is.null(weights)) seq_along(prepared$response) else which(weights > 0)
}

# The inputs of survival's fitters for the rows `rows`, as coxph() builds them before it calls one
# (DEC-100): the design, the Surv() response of the data's type, integer strata codes in provider
# order, the offset minus its mean (zeros when there is none or it is 0 everywhere), and the weights
# or NULL. coxph() rejects offsets whose exp() is not finite, and so does the adapter.
survival_inputs <- function(prepared, rows) {
  counting <- identical(prepared$settings$survival_type, "counting")
  response <- if (counting) {
    survival::Surv(prepared$start[rows], prepared$stop[rows], prepared$response[rows])
  } else {
    survival::Surv(prepared$stop[rows], prepared$response[rows])
  }
  offset <- if (is.null(prepared$offset)) rep(0, length(rows)) else prepared$offset[rows]
  if (!all(is.finite(exp(offset)))) {
    abort_invalid_input("The offsets must be small enough that their exp() is finite, as survival's coxph() needs.",
                        arg = "formula")
  }
  offset <- if (all(offset == 0)) rep(0, length(rows)) else offset - mean(offset)
  # The design itself when every row is fitted, without a copy (data_subset_design()).
  list(
    x = data_subset_design(prepared$design, rows), y = response,
    strata = as.integer(factor(prepared$provider_index[rows])), offset = offset,
    weights = if (is.null(prepared$weights)) NULL else prepared$weights[rows], counting = counting
  )
}

# An error of survival becomes pprof_error_convergence with survival's message, as lme4's do.
survival_abort <- function(e) {
  abort_convergence(sprintf("The survival fit failed: %s", conditionMessage(e)), engine_message = conditionMessage(e))
}

# Runs survival's fitter. Its warning that it reached the iteration limit is muffled: the fit
# function warns once, with pprof_warning_not_converged. Its other warnings (a coefficient that may
# be infinite) pass, and its errors become pprof_error_convergence, as in the lme4 adapter
# (R/model-mixed.R). Whether the fit converged comes from the fitter's result, since survival
# warns only when iter.max > 1: agreg.fit() records it in `info`, and coxph.fit() reports
# iter.max + 1 iterations, its loop counter, when it runs out. The iterations are those run, at most
# iter.max, as pprof_py counts them (survival's coxph() reports the counter).
survival_run_fitter <- function(inputs, ties, control) {
  fitter <- if (inputs$counting) survival::agreg.fit else survival::coxph.fit
  fit <- withCallingHandlers(
    tryCatch(
      fitter(inputs$x, inputs$y, inputs$strata, inputs$offset, NULL, control, weights = inputs$weights,
             method = ties, rownames = NULL, nocenter = survival_nocenter),
      error = survival_abort
    ),
    warning = function(w) {
      if (grepl("Ran out of iterations", conditionMessage(w), fixed = TRUE)) invokeRestart("muffleWarning")
    }
  )
  # Without covariates survival does not iterate; pprof_py reports one iteration, converged.
  if (is.null(fit$iter)) return(list(fit = fit, converged = TRUE, iterations = 1L))
  converged <- if (!is.null(fit$info)) unname(fit$info[["convergence"]]) == 0 else fit$iter <= control$iter.max
  list(fit = fit, converged = converged, iterations = as.integer(min(fit$iter, control$iter.max)))
}

# The robust (sandwich) covariance: coxph()'s robust step (survival 3.8-12, coxph()) on the fitter's
# result. It adds the design, the response, the weights, the strata, and the terms to the fitter's
# list, as coxph() does, and gives the dfbeta residuals, weighted and summed within clusters, to
# crossprod() (DEC-099).
survival_robust_vcov <- function(fit, inputs, cluster, terms) {
  object <- c(fit, list(x = inputs$x, y = inputs$y, weights = inputs$weights))
  object$naive.var <- fit$var
  object$strata <- inputs$strata
  object$terms <- terms
  object$class <- NULL
  class(object) <- fit$class
  crossprod(stats::residuals(object, type = "dfbeta", collapse = cluster, weighted = TRUE))
}

# The clusters of the robust variance for the fitted rows, coded as coxph() codes a cluster column
# (DEC-100): a factor's codes, otherwise the order of first appearance; without a cluster column,
# one cluster per row.
survival_cluster_codes <- function(prepared, rows) {
  cluster <- prepared$cluster
  if (is.null(cluster)) return(seq_along(rows))
  values <- cluster[rows]
  if (is.factor(values)) as.integer(values) else match(values, unique(values))
}

# The Cox fit stratified by provider (COXPH_DESIGN §E.1): survival's fitter on the rows with positive
# weight, and what the model keeps of it. Without covariates the fitters fit no coefficients and
# return the partial log-likelihood of the offsets alone.
survival_fit <- function(prepared, ties, robust, max_iter, tol) {
  rows <- survival_fit_rows(prepared)
  if (length(rows) == 0L) abort_data("No observation has a positive weight, so there is no data to fit.")
  if (!any(prepared$response[rows] == 1)) {
    abort_data("No events among the observations with positive weight: a Cox model needs at least one event.")
  }
  inputs <- survival_inputs(prepared, rows)
  control <- survival::coxph.control(eps = tol, iter.max = max_iter, timefix = FALSE)
  engine <- survival_run_fitter(inputs, ties, control)
  fit <- engine$fit
  names <- colnames(prepared$design)
  p <- length(names)
  if (p == 0L) {
    coefficients <- stats::setNames(numeric(), character())
    naive <- matrix(numeric(), 0L, 0L)
    loglik <- rep(fit$loglik, 2L)
  } else {
    coefficients <- fit$coefficients
    if (anyNA(coefficients)) {
      aliased <- names[is.na(coefficients)]
      abort_data(sprintf(paste("The covariates are linearly dependent, or constant within every provider, so a Cox",
                               "model stratified by provider cannot estimate the coefficients of %s."),
                         paste(aliased, collapse = ", ")), aliased = aliased)
    }
    naive <- matrix(fit$var, p, p, dimnames = list(names, names))
    loglik <- fit$loglik
  }
  vcov <- naive
  if (robust && p > 0L) {
    vcov <- survival_robust_vcov(fit, inputs, survival_cluster_codes(prepared, rows), prepared$terms)
    dimnames(vcov) <- list(names, names)
  }
  n <- length(prepared$response)
  martingale <- rep(NA_real_, n)
  martingale[rows] <- unname(fit$residuals)
  list(
    coefficients = coefficients, vcov = vcov, naive_vcov = if (robust) naive, loglik = unname(loglik),
    linear_predictor = if (p > 0L) unname(drop(prepared$design %*% coefficients)) else rep(0, n),
    martingale_residuals = martingale, n_events = as.integer(sum(prepared$response[rows])),
    n_zero_weight = n - length(rows), fit_rows = rows,
    convergence = list(iterations = engine$iterations, converged = engine$converged, stop_rule = "relative_loglik",
                       tol = tol, max_iter = max_iter)
  )
}

# The coxph() object of the prepared data, with the fit's settings (DEC-091): the prepared vectors
# under generated names, the formula of the data's type with the provider as strata and the offset,
# no robust variance (coxph() would switch it on for non-integer weights), and timefix = FALSE (M-23).
# survfit() and residuals() rebuild coxph()'s model frame from its call in the environment of its
# formula, so that environment holds the data frame the call names; the call refers to it by name,
# so that the object's call does not hold the data. The fit's warnings were given when the model was
# fit, so the refit's are not repeated.
survival_engine_fit <- function(prepared, ties, max_iter, tol) {
  rows <- survival_fit_rows(prepared)
  columns <- survival_engine_columns(ncol(prepared$design))
  frame <- data.frame(.start = prepared$start[rows], .stop = prepared$stop[rows], .status = prepared$response[rows],
                      .provider = prepared$provider_index[rows])
  if (!is.null(prepared$weights)) frame$.weight <- prepared$weights[rows]
  if (!is.null(prepared$offset)) frame$.offset <- prepared$offset[rows]
  for (j in seq_along(columns)) frame[[columns[j]]] <- unname(prepared$design[rows, j])
  counting <- identical(prepared$settings$survival_type, "counting")
  right_side <- c(columns, "strata(.provider)", if (!is.null(prepared$offset)) "offset(.offset)")
  env <- list2env(list(Surv = survival::Surv, strata = survival::strata, offset = stats::offset, frame = frame,
                       control = survival::coxph.control(eps = tol, iter.max = max_iter, timefix = FALSE)),
                  parent = baseenv())
  env$formula <- stats::as.formula(
    paste(if (counting) "Surv(.start, .stop, .status)" else "Surv(.stop, .status)", "~",
          paste(right_side, collapse = " + ")),
    env = env
  )
  call <- as.call(c(list(quote(survival::coxph), formula = quote(formula), data = quote(frame)),
                    if (!is.null(prepared$weights)) list(weights = quote(.weight)),
                    list(ties = ties, robust = FALSE, model = FALSE, control = quote(control))))
  tryCatch(
    suppressWarnings(eval(call, env)),
    error = survival_abort
  )
}

# The generated names of the design's `p` columns in survival_engine_fit()'s data.
survival_engine_columns <- function(p) {
  sprintf(".x%d", seq_len(p))
}

# New rows for survfit() of survival_engine_fit()'s object: the covariates (`design`, one column
# per coefficient) under the generated names, the offsets when the model has an offset term, and
# the providers as the codes of the fit's strata.
survival_engine_newdata <- function(design, offset, codes, has_offset) {
  frame <- data.frame(.provider = codes)
  columns <- survival_engine_columns(ncol(design))
  for (j in seq_along(columns)) frame[[columns[j]]] <- unname(design[, j])
  if (has_offset) frame$.offset <- offset
  frame
}
