# The Fine-Gray model of competing risks (COXPH_DESIGN §B, §D.4; the CoxPH C5 plan, §3.3; DEC-121 to
# DEC-128): the fit function, the `pprof_fine_gray` object, its contract methods, and its standard
# methods. The transform and the estimation are survival's (R/model-survival.R).

#' Fit the Fine-Gray model of competing risks
#'
#' Fits the Fine-Gray model of one event type among several, stratified by provider: pprof_py's
#' `FineGrayPH(strata = provider)`. survival's [survival::finegray()] expands the data, keeping
#' subjects with a competing event at risk with weights that decrease over time, and a weighted Cox
#' model with one baseline hazard per provider and the robust variance clustered by subject estimates
#' the coefficients, which are log subdistribution hazard ratios. [predict()] gives each provider's
#' cumulative incidence of the event.
#'
#' - **The response** is `Surv(time, status)` or, with entry times or several rows per subject,
#'   `Surv(start, stop, status)`, where `status` is a factor whose first level is censoring and whose
#'   other levels are the event types, as survival's `Surv()` reads a factor status: for example
#'   `Surv(time, factor(status, levels = 0:2))` for codes 0 (censored), 1, and 2. Give the levels when
#'   no observation is censored, since the first level is taken as censoring. A numeric status is read
#'   by `Surv()` as one event type and raises an error here.
#' - **`cause`** is the event of interest, one of the event types; the others are competing events.
#' - **Subjects.** With `Surv(start, stop, status)`, `id` names each row's subject: a subject's rows
#'   are contiguous in time, belong to one provider, and have an event on the last row only. `id` may be
#'   left out when every entry time is 0. With right-censored data each row is a subject, and `id`, if
#'   given, must not repeat.
#' - **The transform** is survival's `finegray()`, with the provider as the strata and times compared
#'   exactly (`timefix = FALSE`): the censoring distribution, and with late entries the entry
#'   distribution, are estimated within each provider, unweighted. With entries after the first exits,
#'   a small provider can reach a probability of being under observation of 0 before a competing event,
#'   where the weights are undefined; the fit then raises a `pprof_error_data` condition naming the
#'   providers, where pprof_py raises an error too.
#' - **Weights** are case weights, which multiply the transform's weights. Rows with weight 0 stay in
#'   the transform and are left out of the fit. (survival 3.8-12's `finegray()` would apply its own
#'   `weights` argument to the wrong rows after the first provider, so the package applies them after the
#'   call.)
#' - **The fit** is survival's, as `coxph(Surv(fgstart, fgstop, fgstatus) ~ terms + strata(provider),
#'   weights = fgwt, cluster = id, timefix = FALSE)` on the expanded data gives it, with Breslow's or
#'   Efron's ties. The variance is the robust variance clustered by subject, each row its own subject
#'   without `id`; the model-based variance is kept as `naive_vcov`. On data with many providers the
#'   transform is computed in chunks of providers, which gives the same expansion.
#'
#' Rows with a missing value in the response, a covariate, the provider, the weights, or `id` are
#' dropped. The model has no provider effects and no provider measures: [provider_effects()],
#' [test_providers()], [standardize_providers()], [funnel_limits()], and [profile_providers()] raise
#' a `pprof_error_unsupported_inference` condition. The cause-specific hazards of the same data come
#' from [fit_cox_stratified()] with the event of interest written in `Surv()`, for example
#' `Surv(time, status == "relapse")`, which censors the other events at their times; the Fine-Gray
#' model keeps subjects with a competing event at risk instead, and its coefficients describe the
#' cumulative incidence of the event of interest.
#'
#' @param formula `Surv(time, status) ~ terms` or `Surv(start, stop, status) ~ terms`, with
#'   [survival::Surv()] and a factor status. The provider is not part of the formula, and the formula
#'   has no `strata()`, `cluster()`, or `offset()` terms.
#' @param data A data frame.
#' @param provider The name of the provider column of `data`, the strata of the model.
#' @param cause The event of interest: a level of the status after the first, or a number equal to one.
#' @param id The name of the column of `data` that identifies each row's subject, or `NULL`.
#' @param weights The name of a column of case weights, finite and at least 0, or `NULL`.
#' @param ties The method for tied event times: `"breslow"` or `"efron"`.
#' @param max_iter The largest number of Newton-Raphson iterations.
#' @param tol The convergence tolerance on the relative change in the partial log-likelihood
#'   (survival's `eps`).
#' @param keep_data Whether to keep the prepared data and survival's `coxph()` object of the expanded
#'   data, which the cumulative incidence of [predict()] uses. Without them it needs `data`, the data
#'   the model was fit to.
#' @param verbose Whether to report the events, the expanded rows, the rows left out for weight 0, and
#'   the iterations.
#'
#' @return An object of class `c("pprof_fine_gray", "pprof_model")` with the fields every model has
#'   (see [new_pprof_model()]; `provider_effects` is `NULL`, `response` is the indicator of the event
#'   of interest, `linear_predictor` is x'beta, and `vcov` is the robust covariance), and `start` and
#'   `stop` (each observation's entry, 0 for right-censored data, and exit time), `weights` (or
#'   `NULL`), `status` (each observation's state: 0 for censoring and k for the k-th event type),
#'   `states` (the event types), `cause` (the event of interest), `naive_vcov` (the model-based
#'   covariance), `loglik` (the partial log-likelihoods of the weighted expansion at beta = 0 and at the
#'   estimates), `n_events` and `n_competing` (the events of interest, and the competing events, of the
#'   observations with positive weight), `n_expanded` (the rows of the expanded data in the fit),
#'   `n_zero_weight` (the observations left out for weight 0), and with `keep_data = TRUE`, `engine_fit`,
#'   survival's `coxph()` object of the expanded data. The provider table has `n_events` (the events of
#'   interest), `n_competing`, and `person_time`.
#' @seealso [fine_gray_methods], [fit_cox_stratified()], [test_coefficients()].
#' @family fitting functions
#' @examples
#' # Progression to a plasma cell malignancy, with death as a competing event, in the mgus2 data of
#' # the survival package; its two sexes stand in for providers.
#' mgus2 <- survival::mgus2
#' mgus2$etime <- with(mgus2, ifelse(pstat == 0, futime, ptime))
#' mgus2$event <- factor(with(mgus2, ifelse(pstat == 0, 2 * death, 1)), levels = 0:2,
#'                       labels = c("censored", "progression", "death"))
#' fit <- fit_fine_gray(Surv(etime, event) ~ age + mspike, mgus2, provider = "sex",
#'                      cause = "progression")
#' fit
#' summary(fit)
#' # The cumulative incidence of progression for a patient of 60 and one of 80, in each provider.
#' patients <- data.frame(age = c(60, 80, 60, 80), mspike = 1.2, sex = c("F", "F", "M", "M"))
#' head(predict(fit, newdata = patients, type = "cumulative_incidence", data = mgus2))
#' @export
fit_fine_gray <- function(formula, data, provider, cause, id = NULL, weights = NULL, ties = "breslow",
                          max_iter = 20, tol = 1e-9, keep_data = FALSE, verbose = FALSE) {
  call <- match.call()
  check_choice(ties, c("breslow", "efron"), "ties")
  check_count(max_iter, "max_iter", min = 1)
  check_number(tol, "tol", lower = 0, open = TRUE)
  check_flag(keep_data, "keep_data")
  check_flag(verbose, "verbose")
  prepared <- data_prepare(formula, data, provider, response_type = "competing_risks", weights = weights,
                           cluster = id)
  if (ncol(prepared$design) > 0L && !all(is.finite(range(prepared$design)))) {
    abort_invalid_input("The covariates must be finite.", arg = "formula")
  }
  states <- prepared$settings$states
  code <- fine_gray_cause_code(cause, states)
  spec <- list(family = "fine_gray", cause = states[code], id = id, ties = ties, weights = weights,
               max_iter = max_iter, tol = tol, keep_data = keep_data)
  estimates <- survival_fine_gray_fit(prepared, code, !is.null(id), ties, max_iter, tol)
  fine_gray_report(prepared, estimates, states[code], verbose)
  engine_fit <- if (keep_data) survival_fine_gray_engine_fit(prepared, estimates$expansion, ties, max_iter, tol)
  new_pprof_fine_gray(prepared, estimates, spec, code, call = call, keep_data = keep_data, engine_fit = engine_fit)
}

# The position of `cause` among the event types `states` (the factor's levels after censoring).
fine_gray_cause_code <- function(cause, states) {
  if (!(is.character(cause) || is.numeric(cause) || is.factor(cause)) || length(cause) != 1L || is.na(cause)) {
    abort_invalid_input("`cause` must be a single event type, a level of the status.", arg = "cause")
  }
  code <- match(as.character(cause), states)
  if (is.na(code)) {
    abort_invalid_input(sprintf("`cause` must be one of the event types of the status: %s.",
                                paste(states, collapse = ", ")), arg = "cause")
  }
  code
}

# The fit's convergence warning (K-133: reaching max_iter warns) and, with `verbose`, its summary.
fine_gray_report <- function(prepared, estimates, cause, verbose) {
  convergence <- estimates$convergence
  if (!isTRUE(convergence$converged)) {
    warn_not_converged(sprintf("The Fine-Gray fit reached the iteration limit (max_iter = %d) without converging.",
                               as.integer(convergence$max_iter)), iterations = convergence$iterations)
  }
  inform_message(verbose, sprintf("%d events of \"%s\" and %d competing events among %d observations of %d providers.",
                                  estimates$n_events, cause, estimates$n_competing, length(prepared$response),
                                  sum(prepared$providers$included)))
  inform_message(verbose, sprintf("%d rows of the expanded data in the fit.", estimates$n_expanded))
  if (estimates$n_zero_weight > 0L) {
    inform_message(verbose, sprintf("%d observations with weight 0 are left out of the fit.", estimates$n_zero_weight))
  }
  status <- if (isTRUE(convergence$converged)) "Converged" else "Not converged"
  inform_message(verbose, sprintf("%s after %d iterations.", status, as.integer(convergence$iterations)))
}

# The model object (COXPH_DESIGN §B.2; the C5 plan, §3.3): the shared fields, with the indicator of the
# event of interest as the response, and the Fine-Gray fields; the provider table counts the events of
# interest and the competing events of every observation, and sums the person-time.
new_pprof_fine_gray <- function(data, estimates, spec, code, call = NULL, keep_data = FALSE, engine_fit = NULL) {
  status <- data$response
  providers <- data_event_indicators(data$providers, as.numeric(status == code), data$provider_index)
  rows <- seq_len(nrow(providers))
  providers$n_competing <- data_provider_sums(as.numeric(status != 0 & status != code), data$provider_index, rows)
  data$providers <- data_person_time(providers, data$start, data$stop, data$provider_index)
  data$response <- as.numeric(status == code)
  model <- new_pprof_model(
    data, coefficients = estimates$coefficients, vcov = estimates$vcov, provider_effects = NULL,
    linear_predictor = estimates$linear_predictor, spec = spec,
    start = data$start, stop = data$stop, weights = data$weights, status = status, states = data$settings$states,
    cause = spec$cause, naive_vcov = estimates$naive_vcov, loglik = estimates$loglik, n_events = estimates$n_events,
    n_competing = estimates$n_competing, n_expanded = estimates$n_expanded, n_zero_weight = estimates$n_zero_weight,
    convergence = estimates$convergence, call = call, keep_data = keep_data, class = "pprof_fine_gray"
  )
  if (!is.null(engine_fit)) model$engine_fit <- engine_fit
  validate_pprof_fine_gray(model)
  model
}

validate_pprof_fine_gray <- function(x) {
  fail <- function(what) abort_invalid_input(sprintf("Invalid `pprof_fine_gray` object: %s.", what), arg = "x")
  if (!inherits(x, "pprof_fine_gray")) fail("not of class `pprof_fine_gray`")
  validate_pprof_model(x)
  if (!identical(x$spec$family, "fine_gray")) fail("`spec$family` must be \"fine_gray\"")
  if (!is.null(x$provider_effects)) fail("a Fine-Gray model has no provider effects")
  n <- x$n_obs
  per_observation <- function(value) is.double(value) && is.null(dim(value)) && length(value) == n
  if (!per_observation(x$start) || !per_observation(x$stop) || !all(x$start < x$stop)) {
    fail("`start` and `stop` must give each observation's interval")
  }
  if (!is.null(x$weights) && !per_observation(x$weights)) fail("`weights` must be NULL or one value per observation")
  if (!is.character(x$states) || length(x$states) == 0L || !is.character(x$cause) || !x$cause %in% x$states) {
    fail("`cause` must be one of `states`, the event types")
  }
  if (!per_observation(x$status) || !all(x$status %in% (0:length(x$states)))) {
    fail("`status` must give each observation's state")
  }
  if (!identical(x$response, as.numeric(x$status == match(x$cause, x$states)))) {
    fail("`response` must be the indicator of the event of interest")
  }
  if (!is.double(x$loglik) || length(x$loglik) != 2L) {
    fail("`loglik` must hold the log-likelihoods at 0 and at the estimates")
  }
  if (!identical(dim(x$naive_vcov), dim(x$vcov))) fail("`naive_vcov` must be like `vcov`")
  if (!all(c("n_events", "n_competing", "person_time") %in% names(x$providers))) {
    fail("the provider table must have n_events, n_competing, and person_time")
  }
  if (!is.null(x$engine_fit) && !inherits(x$engine_fit, "coxph")) fail("`engine_fit` must be a coxph object")
  invisible(x)
}

# --- Contract methods (COXPH_DESIGN §D.4; DEC-128) ----------------------------------------------

#' @export
inference_capabilities.pprof_fine_gray <- function(model) {
  # Coefficient inference on the robust variance; no provider measures (M-41).
  "coef_wald"
}

#' @export
profile_spec.pprof_fine_gray <- function(model) {
  # The fields every family has, and the covariate rule of the Cox models: pprof_py's two-sided p-value
  # computed as an upper tail (DEC-101, K-148), with the interval beta -/+ qnorm(1 - alpha / 2) se. The
  # model has no provider measures (M-41), so no profiling hook is set.
  list(
    family = "fine_gray", effect = "none: the Fine-Gray model has no provider effects", null_default = 0,
    null_options = character(), indirect_numerator = "observed", measures = "ratio",
    coefficient_wald = list(p_value = "two_sided_upper", p_value_distribution = "normal", interval = "critical",
                            interval_distribution = "normal", df = NULL),
    wald_caution = FALSE
  )
}

# --- survival's coxph() object of the expanded data -------------------------------------------------

# The model's coxph() object of the expanded data: kept with keep_data = TRUE, or fit to the expansion
# of `data` after the data have been checked against the model (DEC-005), and then checked to
# reproduce the model's coefficients.
fine_gray_engine_fit <- function(model, data) {
  if (!is.null(model$engine_fit)) return(model$engine_fit)
  prepared <- model_prepared_data(model, data)
  spec <- model$spec
  code <- match(model$cause, model$states)
  expansion <- survival_fine_gray_expand(prepared, code, survival_fine_gray_subjects(prepared))
  expansion <- lapply(expansion, function(column) column[expansion$weight > 0])
  engine <- survival_fine_gray_engine_fit(prepared, expansion, spec$ties, spec$max_iter, spec$tol)
  refit <- unname(stats::coef(engine))
  stored <- unname(model$coefficients)
  if (length(refit) != length(stored) || any(abs(refit - stored) > data_match_atol + data_match_rtol * abs(stored))) {
    abort_invalid_input("`data` is not the data the model was fit to.", arg = "data")
  }
  engine
}

# --- Standard methods (COXPH_DESIGN §B.1; DEC-128) ----------------------------------------------

#' Methods of the Fine-Gray model
#'
#' For models from [fit_fine_gray()]:
#'
#' - `nobs()` is the number of events of interest in the fit, as survival's `coxph()` counts them on
#'   the expanded data, and `logLik()` the partial log-likelihood of the weighted expanded data at the
#'   estimates, as `coxph()` reports it, with as many degrees of freedom as coefficients.
#' - `predict()` gives the linear predictor x'beta, or the relative subdistribution hazard
#'   exp(x'beta), for the observations of the fit (in the order of the rows of the data, and named by
#'   those rows) or for `newdata`; and, for each row of `newdata`, the cumulative incidence of the
#'   event of interest in its provider at that provider's event times, from survival's
#'   [survival::survfit()] of the fit: a data frame with `row` (the row of `newdata`), `provider_id`,
#'   `time`, and `cumulative_incidence`. Rows of providers the model does not have (which warns), or
#'   whose provider has no event of interest with positive weight, or with missing covariates, give
#'   one row with missing values.
#' - [summary()], [confint()], and [test_coefficients()] give Wald tests and intervals on the robust
#'   variance; `vcov()` is the robust covariance.
#'
#' The cumulative incidence needs survival's `coxph()` object of the expanded data, which the model
#' keeps with `keep_data = TRUE`; otherwise pass the data the model was fit to as `data`.
#' `residuals()`, `augment()`, and [baseline_hazard()] are not available for the Fine-Gray model: they
#' raise a `pprof_error_unsupported_inference` condition.
#'
#' @param object A model from [fit_fine_gray()].
#' @param newdata A data frame with the covariates, and for the cumulative incidence the provider
#'   column; `NULL` for the observations of the fit.
#' @param type For `predict()`: `"linear_predictor"`, `"risk"`, or `"cumulative_incidence"`.
#' @param data The data the model was fit to, when the model was fit without `keep_data = TRUE` and
#'   the method needs survival's `coxph()` object.
#' @param ... Not used.
#'
#' @family model methods
#' @examples
#' mgus2 <- survival::mgus2
#' mgus2$etime <- with(mgus2, ifelse(pstat == 0, futime, ptime))
#' mgus2$event <- factor(with(mgus2, ifelse(pstat == 0, 2 * death, 1)), levels = 0:2,
#'                       labels = c("censored", "progression", "death"))
#' fit <- fit_fine_gray(Surv(etime, event) ~ age + mspike, mgus2, provider = "sex",
#'                      cause = "progression", keep_data = TRUE)
#' nobs(fit)
#' logLik(fit)
#' predict(fit, newdata = data.frame(age = c(60, 80), mspike = 1.2), type = "risk")
#' patients <- data.frame(age = 70, mspike = 1.2, sex = c("F", "M"))
#' head(predict(fit, newdata = patients, type = "cumulative_incidence"))
#' @name fine_gray_methods
NULL

#' @rdname fine_gray_methods
#' @export
nobs.pprof_fine_gray <- function(object, ...) object$n_events

#' @rdname fine_gray_methods
#' @export
logLik.pprof_fine_gray <- function(object, ...) {
  structure(object$loglik[2L], df = length(object$coefficients), nobs = object$n_events, class = "logLik")
}

#' @rdname fine_gray_methods
#' @export
predict.pprof_fine_gray <- function(object, newdata = NULL, type = "linear_predictor", data = NULL, ...) {
  check_choice(type, c("linear_predictor", "risk", "cumulative_incidence"), "type")
  if (type %in% c("linear_predictor", "risk")) {
    eta <- if (is.null(newdata)) {
      model_input_order(object, object$linear_predictor)
    } else {
      parts <- cox_stratified_newdata(object, newdata)
      unname(drop(parts$design %*% object$coefficients))
    }
    return(if (identical(type, "risk")) exp(eta) else eta)
  }
  if (is.null(newdata)) {
    abort_invalid_input("The cumulative incidence needs `newdata`, with the covariates and the provider.",
                        arg = "newdata")
  }
  fine_gray_curves(object, newdata, data)
}

#' @rdname fine_gray_methods
#' @export
residuals.pprof_fine_gray <- function(object, ...) {
  # D-81: the residuals of the expanded rows do not belong to the observations.
  abort_unsupported_inference(object, "residuals")
}

#' @export
baseline_hazard.pprof_fine_gray <- function(model, data = NULL, ...) {
  # D-81: not given in this phase.
  abort_unsupported_inference(model, "baseline hazards")
}

# The providers that are strata of the fit, and those among them with an event of interest of positive
# weight, whose curves have events. finegray() keeps the providers with an event of interest, whatever
# its weight, and the fit leaves out the rows of weight 0; the original piece of a row of positive
# weight keeps a positive weight.
fine_gray_fitted_providers <- function(model) {
  positive <- if (is.null(model$weights)) rep(TRUE, model$n_obs) else model$weights > 0
  strata <- intersect(unique(model$provider_index[model$response == 1]), unique(model$provider_index[positive]))
  list(strata = strata, with_events = unique(model$provider_index[model$response == 1 & positive]))
}

# The cumulative incidence of the event of interest for the rows of `newdata` (one curve per row, its
# provider's), at the provider's event times: 1 - survival's survfit() of the expanded data's coxph().
fine_gray_curves <- function(model, newdata, data) {
  if (length(model$coefficients) == 0L) {
    abort_unsupported_inference(model, "the cumulative incidence of a model without covariates")
  }
  engine <- fine_gray_engine_fit(model, data)
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
  fitted <- fine_gray_fitted_providers(model)
  usable <- codes %in% fitted$with_events & stats::complete.cases(parts$design)
  tables <- vector("list", length(ids))
  if (any(usable)) {
    rows <- which(usable)
    frame <- survival_engine_newdata(parts$design[rows, , drop = FALSE], rep(0, length(rows)), codes[rows],
                                     has_offset = FALSE)
    # survival 3.8-12's survfit() fails with new data that name the stratum of a model with one stratum.
    if (length(fitted$strata) == 1L) frame$.provider <- NULL
    curves <- suppressWarnings(survival::survfit(engine, newdata = frame, se.fit = FALSE))
    for (k in seq_along(rows)) {
      curve <- curves[k]
      events <- curve$n.event > 0
      tables[[rows[k]]] <- data.frame(row = rows[k], provider_id = ids[rows[k]], time = curve$time[events],
                                      cumulative_incidence = 1 - curve$surv[events], stringsAsFactors = FALSE)
    }
  }
  for (i in which(!usable)) {
    tables[[i]] <- data.frame(row = i, provider_id = ids[i], time = NA_real_, cumulative_incidence = NA_real_,
                              stringsAsFactors = FALSE)
  }
  out <- do.call(rbind, tables)
  rownames(out) <- NULL
  out
}
