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
# The package requires survival 3.8-11 or later (DEC-106): earlier versions' coxph() coded cluster
# columns by sorted value (to 3.8-9) and formed the robust variance as t(r) %*% r (to 3.8-3), which
# change its last bits, and found strata() in a formula only from its environment (before 3.7-3).

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
  # The design itself when every row is fitted, without a copy (data_subset_design()).
  c(list(x = data_subset_design(prepared$design, rows)), survival_row_inputs(prepared, rows))
}

# The inputs of survival_inputs() other than the design: the response, the strata codes, the offset
# (or `eta` in its place, a linear predictor of the rows), the weights, and the response's type.
survival_row_inputs <- function(prepared, rows, eta = NULL) {
  counting <- identical(prepared$settings$survival_type, "counting")
  response <- if (counting) {
    survival::Surv(prepared$start[rows], prepared$stop[rows], prepared$response[rows])
  } else {
    survival::Surv(prepared$stop[rows], prepared$response[rows])
  }
  offset <- if (!is.null(eta)) eta else if (is.null(prepared$offset)) rep(0, length(rows)) else prepared$offset[rows]
  if (!all(is.finite(exp(offset)))) {
    abort_invalid_input("The offsets must be small enough that their exp() is finite, as survival's coxph() needs.",
                        arg = "formula")
  }
  offset <- if (all(offset == 0)) rep(0, length(rows)) else offset - mean(offset)
  list(
    y = response, strata = as.integer(factor(prepared$provider_index[rows])), offset = offset,
    weights = if (is.null(prepared$weights)) NULL else prepared$weights[rows], counting = counting
  )
}

# survival's fit of the columns `x` (one row per row of `rows`) with the strata, offset, and weights of
# those rows, called as coxph() calls its fitters (DEC-100), at `tol` and `max_iter`: the unpenalized
# coefficients of a penalized path's null point (K-143), whose NA coefficients mark aliased columns.
survival_fit_columns <- function(prepared, rows, x, ties, tol, max_iter) {
  inputs <- c(list(x = x), survival_row_inputs(prepared, rows))
  engine <- survival_run_fitter(inputs, ties, survival::coxph.control(eps = tol, iter.max = max_iter, timefix = FALSE))
  list(coefficients = unname(engine$fit$coefficients), converged = engine$converged, iterations = engine$iterations)
}

# The partial log-likelihood of the linear predictors `eta` of the rows `rows`, from survival's fitter
# without covariates and with `eta` as the offset, called as coxph() calls it: the log-likelihood that
# coxph(Surv(...) ~ offset(eta) + strata(provider), weights) reports for those rows. The cross-validation
# of penalized paths takes pprof_py's saturated term from it (K-144, DEC-114).
survival_partial_loglik <- function(prepared, rows, eta, ties) {
  inputs <- c(list(x = matrix(0, length(rows), 0L)), survival_row_inputs(prepared, rows, eta))
  survival_run_fitter(inputs, ties, survival::coxph.control(timefix = FALSE))$fit$loglik
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
# (DEC-100; survival 3.8-11 and later, DEC-106): a factor's codes, otherwise the order of first
# appearance; without a cluster column, one cluster per row.
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

# --- The Fine-Gray model (the CoxPH C5 plan, §3.2; COXPH_DESIGN §E.3; DEC-121 to DEC-124) -------------
#
# survival's finegray() expands the data, and survival's fitter, called as coxph() calls it, with
# coxph()'s robust step clustered by subject, fits the weighted Cox model stratified by provider: the
# fit is coxph(cluster = id)'s on the expansion, bitwise (dev/design/coxph-facts/32). Three things about
# survival 3.8-12's finegray() shape the calls (dev/design/coxph-facts/31, 33, 35):
# - its weights argument multiplies the output weights by user.weights[split$row], where split$row counts
#   the rows of the stratum, so every stratum after the first gets the case weights of the data's first
#   rows: the case weights multiply its output weights after the call instead, K-145's definition;
# - its own steps go over all its rows once per stratum, so one call's time grows with rows times
#   providers: it is called once per chunk of providers, each chunk deciding delayed entry as all rows
#   do, which gives the stratified call's output bitwise;
# - with delayed entry its weights can be NaN or infinite, where pprof_py raises (D-80).
# Rows with weight 0 stay in the transform, whose censoring and entry distributions are unweighted, and
# their pieces, of weight 0, are left out of the fit (M-25).

# The subject of each observation: the `id` column's codes (the data layer keeps them as `cluster`), or
# each observation its own subject.
survival_fine_gray_subjects <- function(prepared) {
  if (is.null(prepared$cluster)) seq_along(prepared$response) else as.integer(prepared$cluster)
}

# DEC-124: pprof_py's rules for the subjects, which finegray() does not apply. (start, stop] data need
# `id` when an entry time is not 0; right-censored data have one row per subject; a subject's rows are
# in one provider.
survival_fine_gray_check_subjects <- function(prepared, has_id) {
  counting <- identical(prepared$settings$survival_type, "counting")
  if (counting && !has_id && any(prepared$start != 0)) {
    abort_invalid_input(paste("Data with entry times, Surv(start, stop, status), need `id`, the subject of each row,",
                              "when an entry time is not 0."), arg = "id")
  }
  if (!has_id) return(invisible(prepared))
  subjects <- as.integer(prepared$cluster)
  if (!counting && anyDuplicated(subjects) > 0L) {
    abort_invalid_input(paste("Right-censored data have one row per subject, but `id` repeats; for several rows per",
                              "subject, write the response as Surv(start, stop, status)."), arg = "id")
  }
  ordered <- order(subjects, prepared$provider_index)
  s <- subjects[ordered]
  p <- prepared$provider_index[ordered]
  n <- length(s)
  if (n > 1L && any(s[-1L] == s[-n] & p[-1L] != p[-n])) {
    abort_invalid_input("Each subject's rows must belong to one provider, but some subjects of `id` change provider.",
                        arg = "id")
  }
  invisible(prepared)
}

# DEC-122: the providers in chunks of `size`, in provider order. finegray() decides delayed entry over its
# rows (some subject's first row, by subject and exit time, enters later than the smallest exit) and then
# computes each stratum from its own rows; with delayed entry over all rows, each chunk also holds the
# provider of the smallest exit and the provider of the first such subject, so that it decides as all
# rows do. Right-censored data never have delayed entry in finegray().
survival_fine_gray_chunks <- function(prepared, subjects, size) {
  providers <- sort(unique(prepared$provider_index))
  anchors <- integer()
  if (identical(prepared$settings$survival_type, "counting")) {
    by_subject <- order(subjects, prepared$stop)
    first <- by_subject[!duplicated(subjects[by_subject])]
    late <- first[prepared$start[first] > min(prepared$stop)]
    if (length(late) > 0L) {
      anchors <- unique(c(prepared$provider_index[which.min(prepared$stop)], prepared$provider_index[late[1L]]))
    }
  }
  lapply(split(providers, ceiling(seq_along(providers) / size)), function(own) list(own = own, anchors = anchors))
}

# One finegray() call on the observations `rows`, stratified by provider: the event type `cause` (the
# state's code), the states as a factor with at least two event types (a single one gets an unused second
# level, which finegray() needs and which changes nothing, so that a single event type is fitted as pprof_py
# fits it), the subjects as `id` for (start, stop] data, and times compared exactly (M-23). The prepared
# vectors are a data frame held in the formula's environment, as survival_engine_fit() holds its own.
# Its errors (a subject with gaps, or with an event before its last row) are the data's.
survival_finegray_call <- function(prepared, rows, cause, subjects) {
  counting <- identical(prepared$settings$survival_type, "counting")
  levels <- 0:max(length(prepared$settings$states), 2L)
  frame <- data.frame(.stop = prepared$stop[rows], .status = factor(prepared$response[rows], levels = levels),
                      .row = rows, .provider = prepared$provider_index[rows])
  if (counting) {
    frame$.start <- prepared$start[rows]
    frame$.id <- subjects[rows]
  }
  env <- list2env(list(Surv = survival::Surv, strata = survival::strata, frame = frame), parent = baseenv())
  env$formula <- stats::as.formula(
    paste(if (counting) "Surv(.start, .stop, .status)" else "Surv(.stop, .status)", "~ .row + strata(.provider)"),
    env = env
  )
  call <- as.call(c(list(quote(survival::finegray), quote(formula), data = quote(frame), etype = as.character(cause)),
                    if (counting) list(id = quote(.id)), list(timefix = FALSE)))
  expanded <- tryCatch(eval(call, env), error = function(e) {
    abort_invalid_input(sprintf("survival's finegray() cannot expand the data: %s", conditionMessage(e)),
                        arg = "formula", engine_message = conditionMessage(e))
  })
  list(row = expanded$.row, start = expanded$fgstart, stop = expanded$fgstop, status = expanded$fgstatus,
       weight = expanded$fgwt)
}

# The Fine-Gray expansion of every observation for the event type `cause`, from finegray() called once per
# chunk of `size` providers (DEC-122): `row` (each expanded row's observation), `start`, `stop`, `status`
# (1 for an event of the cause), and `weight`, finegray()'s weight times the observation's case weight
# (DEC-123), in provider order as the stratified call orders them. Weights that are not finite raise
# (D-80); the case weights do not enter finegray()'s censoring and entry distributions.
survival_fine_gray_expand <- function(prepared, cause, subjects, size = fine_gray_chunk_providers) {
  parts <- lapply(survival_fine_gray_chunks(prepared, subjects, size), function(chunk) {
    own <- prepared$provider_index %in% chunk$own
    # finegray() leaves out the providers without events of the cause.
    if (!any(prepared$response[own] == cause)) return(NULL)
    part <- survival_finegray_call(prepared, which(own | prepared$provider_index %in% chunk$anchors), cause, subjects)
    kept <- prepared$provider_index[part$row] %in% chunk$own
    lapply(part, function(column) column[kept])
  })
  parts <- parts[!vapply(parts, is.null, logical(1))]
  fields <- c("row", "start", "stop", "status", "weight")
  expansion <- stats::setNames(lapply(fields, function(f) unlist(lapply(parts, `[[`, f), use.names = FALSE)), fields)
  undefined <- !is.finite(expansion$weight)
  if (any(undefined)) {
    ids <- prepared$providers$provider_id[sort(unique(prepared$provider_index[expansion$row[undefined]]))]
    abort_data(
      sprintf(paste("The Fine-Gray weights are undefined in %d provider(s) (%s): with entries after the first exits,",
                    "the probability of being under observation reaches 0 before a competing event, and survival's",
                    "finegray() gives such weights NaN or infinite values, where pprof_py raises an error. Larger",
                    "providers, or data without late entries, avoid it."),
              length(ids), paste(utils::head(ids, 10L), collapse = ", ")),
      providers = ids
    )
  }
  if (!is.null(prepared$weights)) expansion$weight <- expansion$weight * prepared$weights[expansion$row]
  expansion
}

# The clusters of the robust variance for the expanded rows of the observations `rows`: the subjects,
# coded as coxph() codes a cluster column (DEC-100, DEC-106), a factor's codes, otherwise the order of
# first appearance; without `id`, one cluster per observation.
survival_fine_gray_cluster_codes <- function(prepared, rows) {
  if (is.null(prepared$cluster)) return(match(rows, unique(rows)))
  values <- prepared$cluster[rows]
  if (is.factor(values)) as.integer(values) else match(values, unique(values))
}

# The Fine-Gray fit for the event type `cause` (DEC-121): the expansion, then survival's fitter on its rows
# with positive weight (M-25), called as coxph() calls it, and coxph()'s robust step clustered by subject;
# what the model keeps, and the fitted expansion, which the coxph() object of the curves needs.
survival_fine_gray_fit <- function(prepared, cause, has_id, ties, max_iter, tol, size = fine_gray_chunk_providers) {
  survival_fine_gray_check_subjects(prepared, has_id)
  label <- prepared$settings$states[cause]
  if (!any(prepared$response == cause)) {
    abort_data(sprintf("No observation has an event of the cause \"%s\", so there is nothing to fit.", label))
  }
  expansion <- survival_fine_gray_expand(prepared, cause, survival_fine_gray_subjects(prepared), size)
  fitted <- which(expansion$weight > 0)
  if (!any(expansion$status[fitted] == 1)) {
    abort_data(sprintf("No event of the cause \"%s\" has a positive weight, so there is nothing to fit.", label))
  }
  expansion <- lapply(expansion, function(column) column[fitted])
  rows <- expansion$row
  inputs <- list(
    x = data_subset_design(prepared$design, rows),
    y = survival::Surv(expansion$start, expansion$stop, expansion$status),
    strata = as.integer(factor(prepared$provider_index[rows])), offset = rep(0, length(rows)),
    weights = expansion$weight, counting = TRUE
  )
  control <- survival::coxph.control(eps = tol, iter.max = max_iter, timefix = FALSE)
  engine <- survival_run_fitter(inputs, ties, control)
  fit <- engine$fit
  names <- colnames(prepared$design)
  p <- length(names)
  if (p == 0L) {
    coefficients <- stats::setNames(numeric(), character())
    naive <- matrix(numeric(), 0L, 0L)
    vcov <- naive
    loglik <- rep(fit$loglik, 2L)
  } else {
    coefficients <- fit$coefficients
    if (anyNA(coefficients)) {
      aliased <- names[is.na(coefficients)]
      abort_data(sprintf(paste("The covariates are linearly dependent, or constant within every provider, so a",
                               "Fine-Gray model stratified by provider cannot estimate the coefficients of %s."),
                         paste(aliased, collapse = ", ")), aliased = aliased)
    }
    naive <- matrix(fit$var, p, p, dimnames = list(names, names))
    vcov <- survival_robust_vcov(fit, inputs, survival_fine_gray_cluster_codes(prepared, rows), prepared$terms)
    dimnames(vcov) <- list(names, names)
    loglik <- fit$loglik
  }
  n <- length(prepared$response)
  positive <- if (is.null(prepared$weights)) rep(TRUE, n) else prepared$weights > 0
  list(
    coefficients = coefficients, vcov = vcov, naive_vcov = naive, loglik = unname(loglik),
    linear_predictor = if (p > 0L) unname(drop(prepared$design %*% coefficients)) else rep(0, n),
    n_events = as.integer(sum(expansion$status == 1)),
    n_competing = as.integer(sum(positive & prepared$response != 0 & prepared$response != cause)),
    n_expanded = length(rows), n_zero_weight = sum(!positive), expansion = expansion,
    convergence = list(iterations = engine$iterations, converged = engine$converged, stop_rule = "relative_loglik",
                       tol = tol, max_iter = max_iter)
  )
}

# The coxph() object of the fitted expansion, with the fit's settings (COXPH_DESIGN §E.3, DEC-121), for
# the cumulative incidence: survival_engine_fit()'s pattern on the expanded rows, with their weights and
# the provider strata, no cluster, and robust = FALSE (the curves do not use the variance).
survival_fine_gray_engine_fit <- function(prepared, expansion, ties, max_iter, tol) {
  rows <- expansion$row
  columns <- survival_engine_columns(ncol(prepared$design))
  frame <- data.frame(.start = expansion$start, .stop = expansion$stop, .status = expansion$status,
                      .provider = prepared$provider_index[rows], .weight = expansion$weight)
  for (j in seq_along(columns)) frame[[columns[j]]] <- unname(prepared$design[rows, j])
  env <- list2env(list(Surv = survival::Surv, strata = survival::strata, frame = frame,
                       control = survival::coxph.control(eps = tol, iter.max = max_iter, timefix = FALSE)),
                  parent = baseenv())
  env$formula <- stats::as.formula(
    paste("Surv(.start, .stop, .status) ~", paste(c(columns, "strata(.provider)"), collapse = " + ")),
    env = env
  )
  call <- as.call(list(quote(survival::coxph), formula = quote(formula), data = quote(frame), weights = quote(.weight),
                       ties = ties, robust = FALSE, model = FALSE, control = quote(control)))
  tryCatch(
    suppressWarnings(eval(call, env)),
    error = survival_abort
  )
}
