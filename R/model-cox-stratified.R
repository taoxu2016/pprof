# The provider-stratified Cox model (COXPH_DESIGN §B, §D; DEC-090 to DEC-092, DEC-099 to DEC-103):
# the fit function, the `pprof_cox_stratified` object, its contract methods, and its standard methods.
# The estimation is survival's (R/model-survival.R).

#' Fit the provider-stratified Cox model
#'
#' Fits the Cox proportional hazards model with one baseline hazard per provider and coefficients
#' shared by all providers, the first stage of He and Schaubel's two-stage standardized measures
#' (pprof_py's `CoxPH(strata = provider)`). The fit is survival's: [survival::coxph()]'s fitters,
#' called as `coxph()` calls them, with times compared exactly (`timefix = FALSE`), so that it equals
#' `coxph(Surv(...) ~ ... + strata(provider), ties = ties, timefix = FALSE)` on the same rows.
#'
#' - **The response** is `Surv(time, status)` or, with entry times (delayed entry, recurrent
#'   events), `Surv(start, stop, status)`. The status is 0/1, logical, or 1/2; for one of several
#'   events, write it in `Surv()`, for example `Surv(time, status == 1)`, which censors the other
#'   events (the cause-specific model). Right-censored times must be above 0, and entry times below
#'   their exit times. `offset()` terms add to the linear predictor.
#' - **Ties** of event times are handled by Breslow's method, or Efron's. Times are compared
#'   exactly, so times that differ only by rounding are different times; integer time units avoid
#'   such near ties, and [check_data()] reports them.
#' - **Weights** are case weights. Rows with weight 0 are left out of the fit and kept in the
#'   provider table, whose event counts and person-time count every row.
#' - **The variance** is the inverse of the information, or with `robust = TRUE` or a `cluster`
#'   the robust (sandwich) variance, as `coxph()` computes it: one cluster per observation with
#'   `robust = TRUE` alone, or the clusters of the `cluster` column. Non-integer weights do not
#'   switch the robust variance on.
#' - **Without covariates** (`Surv(time, status) ~ 1`, with or without offsets) nothing is
#'   estimated: the fit holds the partial log-likelihood of the offsets alone and reports one
#'   iteration, as pprof_py does. survival's `survfit()` gives no curves for new data of such a
#'   model, so [baseline_hazard()] and the curves of [predict()] are not available for it.
#'
#' Rows with a missing value in the response, a covariate, an offset, the provider, the weights,
#' or the cluster are dropped. No provider is screened out. The model has no provider effects:
#' providers are compared through the standardized measures of their expected events, and
#' [provider_effects()] raises a `pprof_error_unsupported_inference` condition.
#'
#' @param formula `Surv(time, status) ~ terms` or `Surv(start, stop, status) ~ terms`, with
#'   [survival::Surv()] and, optionally, `offset()` terms. The provider is not part of the formula,
#'   and the formula has no `strata()` or `cluster()` terms.
#' @param data A data frame.
#' @param provider The name of the provider column of `data`, the strata of the model.
#' @param weights The name of a column of case weights, finite and at least 0, or `NULL`.
#' @param cluster The name of a column of clusters for the robust variance, which it implies, or
#'   `NULL`.
#' @param ties The method for tied event times: `"breslow"` or `"efron"`.
#' @param robust Whether to report the robust variance; a `cluster` implies it.
#' @param max_iter The largest number of Newton-Raphson iterations.
#' @param tol The convergence tolerance on the relative change in the partial log-likelihood
#'   (survival's `eps`).
#' @param keep_data Whether to keep the prepared data and survival's `coxph()` object, which
#'   [baseline_hazard()], the cumulative hazards and survival curves of [predict()], and the
#'   score and dfbeta residuals use. Without them those methods need `data`, the data the model
#'   was fit to.
#' @param verbose Whether to report the events, the rows left out for weight 0, and the iterations.
#'
#' @return An object of class `c("pprof_cox_stratified", "pprof_model")` with the fields every
#'   model has (see [new_pprof_model()]; `provider_effects` is `NULL`, `response` is the status,
#'   `linear_predictor` is x'beta without the offset, and `vcov` is the robust covariance when one
#'   was requested) and `start` and `stop` (each observation's entry, 0 for right-censored data,
#'   and exit time), `weights` and `offset` (or `NULL`), `naive_vcov` (the model-based covariance
#'   of a robust fit), `loglik` (the partial log-likelihoods at beta = 0 and at the estimates),
#'   `n_events` (the events of the fitted rows), `n_zero_weight` (the rows left out for weight 0),
#'   `martingale_residuals` (missing for those rows), and with `keep_data = TRUE`, `engine_fit`,
#'   survival's `coxph()` object. The provider table has `n_events` and `person_time`.
#' @seealso [baseline_hazard()], [cox_stratified_methods], [test_coefficients()], [check_data()].
#' @family fitting functions
#' @examples
#' lung <- survival::lung
#' fit <- fit_cox_stratified(Surv(time, status) ~ age + sex, lung, provider = "inst")
#' fit
#' summary(fit)
#' # The robust variance, with each patient as a cluster.
#' fit_cox_stratified(Surv(time, status) ~ age + sex, lung, provider = "inst", robust = TRUE)
#' @export
fit_cox_stratified <- function(formula, data, provider, weights = NULL, cluster = NULL, ties = "breslow",
                               robust = FALSE, max_iter = 20, tol = 1e-9, keep_data = FALSE, verbose = FALSE) {
  call <- match.call()
  check_choice(ties, c("breslow", "efron"), "ties")
  check_flag(robust, "robust")
  check_count(max_iter, "max_iter", min = 1)
  check_number(tol, "tol", lower = 0, open = TRUE)
  check_flag(keep_data, "keep_data")
  check_flag(verbose, "verbose")
  prepared <- data_prepare(formula, data, provider, event_counts = TRUE, response_type = "survival",
                           weights = weights, cluster = cluster, allow_offset = TRUE)
  if (ncol(prepared$design) > 0L && !all(is.finite(range(prepared$design)))) {
    abort_invalid_input("The covariates must be finite.", arg = "formula")
  }
  robust <- robust || !is.null(cluster)
  spec <- list(family = "cox_stratified", ties = ties, robust = robust, weights = weights, cluster = cluster,
               max_iter = max_iter, tol = tol, keep_data = keep_data)
  estimates <- survival_fit(prepared, ties, robust, max_iter, tol)
  cox_stratified_report(prepared, estimates, verbose)
  engine_fit <- if (keep_data) survival_engine_fit(prepared, ties, max_iter, tol)
  new_pprof_cox_stratified(prepared, estimates, spec, call = call, keep_data = keep_data, engine_fit = engine_fit)
}

# The fit's convergence warning (K-133: reaching max_iter warns) and, with `verbose`, its summary.
cox_stratified_report <- function(prepared, estimates, verbose) {
  convergence <- estimates$convergence
  if (!isTRUE(convergence$converged)) {
    warn_not_converged(sprintf("The Cox fit reached the iteration limit (max_iter = %d) without converging.",
                               as.integer(convergence$max_iter)), iterations = convergence$iterations)
  }
  inform_message(verbose, sprintf("%d events among %d observations of %d providers.", estimates$n_events,
                                  length(prepared$response), sum(prepared$providers$included)))
  if (estimates$n_zero_weight > 0L) {
    inform_message(verbose, sprintf("%d observations with weight 0 are left out of the fit.", estimates$n_zero_weight))
  }
  status <- if (isTRUE(convergence$converged)) "Converged" else "Not converged"
  inform_message(verbose, sprintf("%s after %d iterations.", status, as.integer(convergence$iterations)))
}

# The model object (COXPH_DESIGN §B.2): the shared fields and the Cox fields.
new_pprof_cox_stratified <- function(data, estimates, spec, call = NULL, keep_data = FALSE, engine_fit = NULL) {
  model <- new_pprof_model(
    data, coefficients = estimates$coefficients, vcov = estimates$vcov, provider_effects = NULL,
    linear_predictor = estimates$linear_predictor, spec = spec,
    start = data$start, stop = data$stop, weights = data$weights, offset = data$offset,
    naive_vcov = estimates$naive_vcov, loglik = estimates$loglik, n_events = estimates$n_events,
    n_zero_weight = estimates$n_zero_weight, martingale_residuals = estimates$martingale_residuals,
    convergence = estimates$convergence, call = call, keep_data = keep_data, class = "pprof_cox_stratified"
  )
  if (!is.null(engine_fit)) model$engine_fit <- engine_fit
  validate_pprof_cox_stratified(model)
  model
}

validate_pprof_cox_stratified <- function(x) {
  fail <- function(what) abort_invalid_input(sprintf("Invalid `pprof_cox_stratified` object: %s.", what), arg = "x")
  if (!inherits(x, "pprof_cox_stratified")) fail("not of class `pprof_cox_stratified`")
  validate_pprof_model(x)
  if (!identical(x$spec$family, "cox_stratified")) fail("`spec$family` must be \"cox_stratified\"")
  if (!is.null(x$provider_effects)) fail("a provider-stratified Cox model has no provider effects")
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
  if (!is.double(x$loglik) || length(x$loglik) != 2L) {
    fail("`loglik` must hold the log-likelihoods at 0 and at the estimates")
  }
  if (!per_observation(x$martingale_residuals)) fail("`martingale_residuals` must have one value per observation")
  if (!is.null(x$naive_vcov) && !identical(dim(x$naive_vcov), dim(x$vcov))) fail("`naive_vcov` must be like `vcov`")
  if (!all(c("n_events", "person_time") %in% names(x$providers))) {
    fail("the provider table must have n_events and person_time")
  }
  if (!is.null(x$engine_fit) && !inherits(x$engine_fit, "coxph")) fail("`engine_fit` must be a coxph object")
  invisible(x)
}

# --- Contract methods (COXPH_DESIGN §D.1; DEC-102) -----------------------------------------------

#' @export
inference_capabilities.pprof_cox_stratified <- function(model) {
  # Coefficient inference only in Phase C2; the measures and Poisson tests come with C3.
  "coef_wald"
}

#' @export
profile_spec.pprof_cox_stratified <- function(model) {
  # The fields every family has, and the covariate rule: pprof_py's two-sided p-value computed as an
  # upper tail, 2 (1 - Phi(|z|)) evaluated as 2 pnorm(|z|, lower.tail = FALSE) (DEC-101, K-148),
  # with the default interval beta -/+ qnorm(1 - alpha / 2) se. C3 completes COXPH_DESIGN §D.2.
  list(
    family = "cox_stratified", effect = "log ratio of the provider's hazard to the national baseline",
    null_default = 0, null_options = character(), indirect_numerator = "observed", measures = "ratio",
    coefficient_wald = list(p_value = "two_sided_upper", p_value_distribution = "normal", interval = "critical",
                            interval_distribution = "normal", df = NULL)
  )
}

# --- survival's coxph() object -------------------------------------------------------------------

# The model's coxph() object: kept with keep_data = TRUE, or fit to `data` after the data have been
# checked against the model (DEC-005), and then checked to reproduce the model's coefficients.
cox_stratified_engine_fit <- function(model, data) {
  if (!is.null(model$engine_fit)) return(model$engine_fit)
  prepared <- model_prepared_data(model, data)
  engine <- survival_engine_fit(prepared, model$spec$ties, model$spec$max_iter, model$spec$tol)
  refit <- unname(stats::coef(engine))
  stored <- unname(model$coefficients)
  if (length(refit) != length(stored) || any(abs(refit - stored) > data_match_atol + data_match_rtol * abs(stored))) {
    abort_invalid_input("`data` is not the data the model was fit to.", arg = "data")
  }
  engine
}

# --- Standard methods (COXPH_DESIGN §B.1) --------------------------------------------------------

#' Methods of the provider-stratified Cox model
#'
#' For models from [fit_cox_stratified()]:
#'
#' - `nobs()` is the number of events of the fit, as for survival's `coxph()`, and `logLik()` the
#'   partial log-likelihood at the estimates, with as many degrees of freedom as coefficients.
#' - `residuals()` gives one value (martingale) or one row (score and dfbeta, one column per
#'   coefficient) per observation, in the order of the rows of the data and named by those rows:
#'   survival's martingale, score, and dfbeta residuals (the dfbeta residuals weighted, as
#'   survival's default), missing for rows with weight 0.
#' - `predict()` gives the linear predictor x'beta + offset, or the risk exp(x'beta + offset),
#'   for the observations of the fit (as `residuals()` orders them) or for `newdata`; and, for each
#'   row of `newdata`, the cumulative hazard or the survival function of its provider at that
#'   provider's event times, from survival's [survival::survfit()]: a data frame with `row` (the
#'   row of `newdata`), `provider_id`, `time`, and `cumulative_hazard` or `survival`. Rows of
#'   providers the model does not have (which warns) or with missing covariates give one row with
#'   missing values.
#'
#' The linear predictor and the risk are not centered, so the risk overflows to `Inf` when the
#' linear predictor exceeds about 709, as with covariates far from 0. Score and dfbeta residuals and
#' the curves need survival's `coxph()` object, which the model keeps with `keep_data = TRUE`;
#' otherwise pass the data the model was fit to as `data`.
#'
#' @param object A model from [fit_cox_stratified()].
#' @param type For `residuals()`: `"martingale"`, `"score"`, or `"dfbeta"`. For `predict()`:
#'   `"linear_predictor"`, `"risk"`, `"cumulative_hazard"`, or `"survival"`.
#' @param newdata A data frame with the covariates, the variables of the offset terms, and for
#'   cumulative hazards and survival curves the provider column; `NULL` for the observations of the
#'   fit.
#' @param data The data the model was fit to, when the model was fit without `keep_data = TRUE` and
#'   the method needs survival's `coxph()` object.
#' @param ... Not used.
#'
#' @family model methods
#' @examples
#' lung <- survival::lung
#' fit <- fit_cox_stratified(Surv(time, status) ~ age + sex, lung, provider = "inst")
#' nobs(fit)
#' logLik(fit)
#' head(residuals(fit))
#' head(residuals(fit, type = "dfbeta", data = lung))
#' profiles <- data.frame(age = c(50, 70), sex = c(1, 2), inst = c(1, 1))
#' predict(fit, newdata = profiles, type = "risk")
#' head(predict(fit, newdata = profiles, type = "survival", data = lung))
#' @name cox_stratified_methods
NULL

#' @rdname cox_stratified_methods
#' @export
nobs.pprof_cox_stratified <- function(object, ...) object$n_events

#' @rdname cox_stratified_methods
#' @export
logLik.pprof_cox_stratified <- function(object, ...) {
  structure(object$loglik[2L], df = length(object$coefficients), nobs = object$n_events, class = "logLik")
}

#' @rdname cox_stratified_methods
#' @export
residuals.pprof_cox_stratified <- function(object, type = "martingale", data = NULL, ...) {
  check_choice(type, c("martingale", "score", "dfbeta"), "type")
  if (identical(type, "martingale")) return(model_input_order(object, object$martingale_residuals))
  p <- length(object$coefficients)
  values <- matrix(NA_real_, object$n_obs, p, dimnames = list(NULL, names(object$coefficients)))
  if (p > 0L) {
    engine <- cox_stratified_engine_fit(object, data)
    values[survival_fit_rows(object), ] <- as.matrix(stats::residuals(engine, type = type))
  }
  order <- order(object$row_index)
  values <- values[order, , drop = FALSE]
  rownames(values) <- object$row_index[order]
  values
}

#' @rdname cox_stratified_methods
#' @export
predict.pprof_cox_stratified <- function(object, newdata = NULL, type = "linear_predictor", data = NULL, ...) {
  check_choice(type, c("linear_predictor", "risk", "cumulative_hazard", "survival"), "type")
  if (type %in% c("linear_predictor", "risk")) {
    eta <- if (is.null(newdata)) {
      lp <- object$linear_predictor
      model_input_order(object, if (is.null(object$offset)) lp else lp + object$offset)
    } else {
      parts <- cox_stratified_newdata(object, newdata)
      unname(drop(parts$design %*% object$coefficients) + parts$offset)
    }
    return(if (identical(type, "risk")) exp(eta) else eta)
  }
  if (is.null(newdata)) {
    abort_invalid_input("Cumulative hazards and survival curves need `newdata`, with the covariates and provider.",
                        arg = "newdata")
  }
  cox_stratified_curves(object, newdata, type, data)
}

# The design and the offset of new data, built as the data layer built the model's (K-04).
cox_stratified_newdata <- function(model, newdata) {
  design <- model_design_for(model, newdata)
  frame <- stats::model.frame(stats::delete.response(model$terms), newdata, na.action = stats::na.pass,
                              xlev = model$data_spec$xlevels)
  offset <- stats::model.offset(frame)
  list(design = design, offset = if (is.null(offset)) rep(0, nrow(design)) else unname(as.double(offset)))
}

# survival's survfit() of the model's coxph() object for rows the package builds, one curve per
# row, for its provider. survival's warnings here come from its internal steps and do not concern
# the curves: survival 3.8-12's agsurv() takes min(diff()) of a stratum's event times even when there
# is one, and survfit.coxph() of a model without covariates calls rep(length = n), which a session
# that reports partial argument matching flags. survival 3.8-12's survfit() also fails with new data
# that name the stratum of a model with one stratum (a fit with one provider); without the stratum,
# each row gets that stratum's curve.
cox_stratified_survfit <- function(model, engine, frame) {
  if (length(unique(model$provider_index[survival_fit_rows(model)])) == 1L) frame$.provider <- NULL
  suppressWarnings(survival::survfit(engine, newdata = frame, se.fit = FALSE))
}

# survival 3.8-12's survfit() fails with new data for a model without covariates (a coxph.null
# object), so such models have no baselines or curves (D-75).
cox_stratified_require_covariates <- function(model, what) {
  if (length(model$coefficients) == 0L) abort_unsupported_inference(model, paste(what, "of a model without covariates"))
  invisible(model)
}

# The survfit() curves of survival's coxph() object for the rows of `newdata` (one per row, its
# provider's), at the provider's event times: survival's cumulative hazard, or survival function.
cox_stratified_curves <- function(model, newdata, type, data) {
  cox_stratified_require_covariates(model, "cumulative hazards and survival curves")
  engine <- cox_stratified_engine_fit(model, data)
  parts <- cox_stratified_newdata(model, newdata)
  provider <- model$data_spec$provider_name
  check_column(newdata, provider, "newdata")
  ids <- as.character(newdata[[provider]])
  codes <- match(ids, model$providers$provider_id)
  unknown <- unique(ids[is.na(codes) & !is.na(ids)])
  if (length(unknown) > 0L) {
    warn_unknown_providers(
      sprintf("The model has no provider %s of `newdata`; their curves are missing.",
              paste(utils::head(unknown, 5L), collapse = ", ")),
      providers = unknown
    )
  }
  # A provider all of whose rows have weight 0 has no stratum in the fit, and so no curve.
  fitted <- unique(model$provider_index[survival_fit_rows(model)])
  usable <- codes %in% fitted & stats::complete.cases(parts$design) & is.finite(parts$offset)
  tables <- vector("list", length(ids))
  if (any(usable)) {
    rows <- which(usable)
    frame <- survival_engine_newdata(parts$design[rows, , drop = FALSE], parts$offset[rows], codes[rows],
                                     has_offset = !is.null(model$offset))
    curves <- cox_stratified_survfit(model, engine, frame)
    for (k in seq_along(rows)) {
      curve <- curves[k]
      events <- curve$n.event > 0
      value <- if (identical(type, "survival")) curve$surv[events] else curve$cumhaz[events]
      tables[[rows[k]]] <- data.frame(row = rows[k], provider_id = ids[rows[k]], time = curve$time[events],
                                      value = value, stringsAsFactors = FALSE)
    }
  }
  for (i in which(!usable)) {
    tables[[i]] <- data.frame(row = i, provider_id = ids[i], time = NA_real_, value = NA_real_,
                              stringsAsFactors = FALSE)
  }
  out <- do.call(rbind, tables)
  names(out)[names(out) == "value"] <- type
  rownames(out) <- NULL
  out
}

#' Baseline cumulative hazard of a Cox model
#'
#' Each provider's baseline cumulative hazard at its event times: the cumulative hazard of an
#' observation whose covariates and offset are all 0, from survival's [survival::survfit()] of the
#' model. Unlike `survival::basehaz(fit, centered = FALSE)` and pprof_py's `baseline_hazard_`,
#' which include the factor exp(mean offset) of a model with an offset, it is the baseline at
#' offset 0; without an offset the two are the same. Where covariates lie far from 0 (a calendar
#' year, for example), the baseline at 0 can be too small to represent and is 0. Models without
#' covariates raise `pprof_error_unsupported_inference`, since survival's `survfit()` gives no
#' curves for new data of such a model.
#'
#' @param model A model from [fit_cox_stratified()].
#' @param data The data the model was fit to, when the model was fit without `keep_data = TRUE`.
#' @param ... Not used.
#'
#' @return A data frame with one row per provider and event time of the fit: `provider_id`,
#'   `time`, and `cumulative_hazard`, in provider order and then by time. Providers without events
#'   among the fitted rows have no rows.
#' @examples
#' lung <- survival::lung
#' fit <- fit_cox_stratified(Surv(time, status) ~ age + sex, lung, provider = "inst",
#'                           keep_data = TRUE)
#' head(baseline_hazard(fit))
#' @export
baseline_hazard <- function(model, data = NULL, ...) UseMethod("baseline_hazard")

#' @export
baseline_hazard.default <- function(model, data = NULL, ...) {
  abort_invalid_input(sprintf("`model` must be a Cox model, not an object of class '%s'.", class(model)[1]),
                      arg = "model")
}

#' @export
baseline_hazard.pprof_cox_stratified <- function(model, data = NULL, ...) {
  cox_stratified_require_covariates(model, "baseline hazards")
  engine <- cox_stratified_engine_fit(model, data)
  rows <- survival_fit_rows(model)
  codes <- sort(unique(model$provider_index[rows][model$response[rows] == 1]))
  p <- length(model$coefficients)
  frame <- survival_engine_newdata(matrix(0, length(codes), p), rep(0, length(codes)), codes,
                                   has_offset = !is.null(model$offset))
  curves <- cox_stratified_survfit(model, engine, frame)
  ids <- model$providers$provider_id
  tables <- lapply(seq_along(codes), function(k) {
    curve <- curves[k]
    events <- curve$n.event > 0
    data.frame(provider_id = ids[codes[k]], time = curve$time[events], cumulative_hazard = curve$cumhaz[events],
               stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, tables)
  rownames(out) <- NULL
  out
}
