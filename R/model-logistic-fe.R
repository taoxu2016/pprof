# Logistic fixed-effect models (ARCHITECTURE §B.5, §D, §E): the fit function, the call of
# the C++ engines, the model object, the contract methods, and the declared inference
# capabilities.

# Stopping rules in the vocabulary of NAMING.md §4; the reference calls them "or", "all",
# "beta", "relch", and "ratch" (K-16).
logistic_fe_stop_rules <- c("any", "all", "coefficients", "relative_loglik", "relative_gain")

#' Fit a logistic fixed-effect model for provider profiling
#'
#' Fits the model logit P(y = 1) = gamma_i + z'beta for an observation of provider i, with
#' one fixed effect gamma_i per provider and covariate coefficients beta, by maximum
#' likelihood. Both algorithms reproduce the iterations of pprof 1.0.3 exactly:
#'
#' - `"serbin"` (serial blockwise inversion Newton) updates gamma and beta together with a
#'   Newton step that inverts the information matrix through its block structure;
#' - `"ban"` (block ascent Newton) alternates a Newton step for gamma with beta fixed and a
#'   Newton step for beta with the new gamma.
#'
#' With `backtrack = TRUE`, Armijo backtracking shortens each step until the
#' log-likelihood increases enough. After every update the provider effects are clamped to
#' within `effect_bound` of their median, which keeps the effects of providers with no
#' events or only events finite. Providers with fewer than `min_provider_size` complete
#' observations are excluded with a warning; providers with no events or only events are
#' kept.
#'
#' Every provider starts at the logit of the overall event rate and every coefficient at 0.
#' The fit stops when the criterion of the stopping rule falls below `tol`. There are three
#' criteria: the largest absolute change of a coefficient (`"coefficients"`), the change of
#' the log-likelihood relative to its new value (`"relative_loglik"`), and the change
#' relative to the gain since the starting values (`"relative_gain"`). `"any"`, the
#' default, stops as soon as the smallest of the three is below `tol`; `"all"` waits for the
#' largest. Because the two log-likelihood criteria shrink as the data grow, a fit on large
#' data with `"any"` can stop while provider effects still change noticeably; the criteria
#' of every iteration are kept in the object. SerBIN runs at most `max_iter + 1` iterations
#' and BAN at most `max_iter`; a fit that reaches the limit without meeting the stopping rule
#' warns with class `pprof_warning_not_converged`.
#'
#' @param formula A two-sided formula: the binary outcome (0 and 1, or `FALSE` and `TRUE`)
#'   on the left and the covariates on the right. Transformations, interactions, and factors
#'   are allowed. The provider is not part of the formula, and the provider effects take the
#'   place of the intercept, so the formula keeps its intercept (no `- 1`).
#' @param data A data frame. Rows with a missing outcome, provider, or covariate are dropped.
#' @param provider The name of the column of `data` that identifies providers.
#' @param method The algorithm: `"serbin"` or `"ban"`.
#' @param max_iter The iteration limit.
#' @param tol The convergence tolerance, a positive number.
#' @param stop_rule The stopping rule: `"any"`, `"all"`, `"coefficients"`,
#'   `"relative_loglik"`, or `"relative_gain"`.
#' @param backtrack Whether to shorten the Newton steps by Armijo backtracking.
#' @param effect_bound How far provider effects may be from their median.
#' @param min_provider_size The smallest number of complete observations with which a
#'   provider is included.
#' @param keep_data Whether to keep the prepared data, including the design matrix, in the
#'   object. Methods that need the covariates use them, or take `data` instead.
#' @param threads The number of threads for SerBIN's covariate information block.
#' @param verbose Whether to report the screening and the criterion of every iteration.
#'
#' @return A model object of class `c("pprof_logistic_fe", "pprof_model")`. Besides the
#'   fields of every model (see [new_pprof_model()]), it holds the log-likelihood (`loglik`),
#'   AIC and BIC with m + p parameters (`aic`, `bic`), the area under the ROC curve of the
#'   fitted probabilities (`auc`), and the convergence diagnostics (`convergence`): the
#'   number of iterations, whether the stopping rule was met, the final criteria, and the
#'   criteria of every iteration.
#'
#' @references
#' He K, Kalbfleisch JD, Li Y, Li Y (2013). Evaluating hospital readmission rates in dialysis
#' facilities; adjusting for hospital effects. *Lifetime Data Analysis*, 19, 490-512.
#'
#' Wu W, Yang Y, Kang J, He K (2022). Improving large-scale estimation and inference for
#' profiling health care providers. *Statistics in Medicine*, 41(15), 2840-2853.
#'
#' @examples
#' data(ExampleDataBinary)
#' example <- data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID,
#'                       ExampleDataBinary$Z)
#' fit <- fit_logistic_fe(y ~ z1 + z2 + z3 + z4 + z5, example, provider = "hospital")
#' fit$coefficients
#' fit$convergence$iterations
#' @export
fit_logistic_fe <- function(formula, data, provider, method = "serbin", max_iter = 10000, tol = 1e-5,
                            stop_rule = "any", backtrack = TRUE, effect_bound = 10, min_provider_size = 10,
                            keep_data = FALSE, threads = 1, verbose = FALSE) {
  call <- match.call()
  check_choice(method, c("serbin", "ban"), "method")
  check_count(max_iter, "max_iter", min = 1)
  check_number(tol, "tol", lower = 0, open = TRUE)
  check_choice(stop_rule, logistic_fe_stop_rules, "stop_rule")
  check_flag(backtrack, "backtrack")
  check_number(effect_bound, "effect_bound", lower = 0, open = TRUE)
  check_count(min_provider_size, "min_provider_size", min = 1)
  check_flag(keep_data, "keep_data")
  check_threads(threads)
  check_flag(verbose, "verbose")

  prepared <- data_prepare(formula, data, provider, min_provider_size = min_provider_size, event_counts = TRUE)
  logistic_fe_check_data(prepared)
  logistic_fe_report_screening(prepared, min_provider_size, verbose)
  logistic_fe_check_rank(prepared)
  spec <- list(
    family = "logistic_fe", method = method, max_iter = max_iter, tol = tol, stop_rule = stop_rule,
    backtrack = backtrack, effect_bound = effect_bound, min_provider_size = min_provider_size, keep_data = keep_data
  )
  estimates <- logistic_fe_estimate(prepared, spec, threads)
  logistic_fe_report_convergence(estimates$convergence, method, verbose)
  new_pprof_logistic_fe(prepared, estimates, spec, call = call, keep_data = keep_data)
}

# The data a logistic fixed-effect model needs: a binary outcome with both values (D-39;
# the reference fits any numeric outcome and fails only later, in pROC, when every outcome
# is the same) and at least one finite covariate.
logistic_fe_check_data <- function(prepared) {
  response <- prepared$response
  if (!is.logical(response) && !all(response %in% c(0, 1))) {
    abort_invalid_input("The outcome must be binary: 0 and 1, or FALSE and TRUE.", arg = "formula")
  }
  if (all(response == response[1])) {
    abort_data("The outcome has the same value for every included observation; the model needs both outcomes.")
  }
  if (ncol(prepared$design) == 0L) {
    abort_invalid_input("`formula` must have at least one covariate.", arg = "formula")
  }
  if (!all(is.finite(prepared$design))) {
    abort_invalid_input("The covariates must be finite.", arg = "formula")
  }
  invisible(prepared)
}

# Screening (K-06): a warning when providers were excluded (with the true count, D-01), and
# with `verbose` a summary of the included providers.
logistic_fe_report_screening <- function(prepared, min_provider_size, verbose) {
  providers <- prepared$providers
  n_excluded <- sum(!providers$included)
  if (n_excluded > 0L) {
    warn_screening(
      sprintf("%d of %d providers have fewer than %d complete observations and were excluded.", n_excluded,
              nrow(providers), min_provider_size),
      n_excluded = n_excluded, n_providers = nrow(providers)
    )
  }
  included <- providers[providers$included, , drop = FALSE]
  inform_message(verbose, sprintf("%d providers included, %d excluded; %d with no events and %d with only events.",
                                  nrow(included), n_excluded, sum(included$no_events), sum(included$all_events)))
  inform_message(verbose, sprintf("Events in %.2f%% of the %d included observations.", 100 * mean(prepared$response),
                                  length(prepared$response)))
}

# D-38: with covariates that are linearly dependent once the provider effects are accounted
# for, some coefficients are not identified. The fit proceeds as the reference does and
# warns, naming the columns that QR with pivoting finds dependent on the others.
logistic_fe_check_rank <- function(prepared) {
  design <- prepared$design
  within <- design - apply(design, 2L, function(column) stats::ave(column, prepared$provider_index))
  decomposition <- qr(within)
  if (decomposition$rank < ncol(design)) {
    aliased <- colnames(design)[decomposition$pivot[-seq_len(decomposition$rank)]]
    warn_rank_deficient(
      sprintf(paste("The covariates are linearly dependent within providers (rank %d of %d),",
                    "so these coefficients are not identified: %s."),
              decomposition$rank, ncol(design), paste(aliased, collapse = ", ")),
      rank = decomposition$rank, aliased = aliased
    )
  }
}

# Runs the engine and the variance routine, then computes the fit statistics in R exactly
# as the reference does (R/logis_fe.R:217-304), so that they are bitwise identical.
logistic_fe_estimate <- function(prepared, spec, threads) {
  response <- prepared$response
  design <- prepared$design
  sizes <- as.integer(prepared$providers$n_obs[prepared$providers$included])
  # K-10: every provider starts at the logit of the overall event rate, from mean() of the
  # outcome as stored; beta starts at 0.
  rate <- mean(response)
  start <- log(rate / (1 - rate))
  engine <- if (identical(spec$method, "serbin")) cpp_logistic_fe_serbin else cpp_logistic_fe_ban
  fit <- logistic_fe_engine_call(
    toupper(spec$method),
    engine(as.numeric(response), design, sizes, rep(start, length(sizes)), rep(0, ncol(design)),
           as.integer(spec$max_iter), spec$tol, spec$effect_bound, spec$backtrack, spec$stop_rule, as.integer(threads))
  )
  variances <- logistic_fe_engine_call("variance", cpp_logistic_variance(design, sizes, fit$gamma, fit$beta))

  # K-11, K-21, K-23: the log-likelihood with the linear predictor evaluated directly, AIC
  # and BIC with m + p parameters and the included observations, and the fitted
  # probabilities.
  linear_predictor <- drop(design %*% fit$beta)
  eta <- rep(fit$gamma, sizes) + linear_predictor
  loglik <- sum(eta * response - log(1 + exp(eta)))
  n_parameters <- length(fit$gamma) + length(fit$beta)
  history <- fit$history
  final <- history[nrow(history), ]
  list(
    gamma = fit$gamma, beta = fit$beta, variances = variances, linear_predictor = linear_predictor,
    loglik = loglik, aic = -2 * loglik + 2 * n_parameters, bic = -2 * loglik + log(length(response)) * n_parameters,
    auc = logistic_fe_auc(response, stats::plogis(eta)),
    convergence = list(
      iterations = fit$iterations, converged = fit$converged, criterion = unname(final["rule"]),
      criteria = final[c("coefficients", "relative_loglik", "relative_gain")], stop_rule = spec$stop_rule,
      tol = spec$tol, max_iter = spec$max_iter, history = history
    )
  )
}

# Errors of the C++ routines (for example a singular information matrix, where the
# reference also fails) become pprof_error_convergence.
logistic_fe_engine_call <- function(routine, expr) {
  tryCatch(expr, "C++Error" = function(error) {
    abort_convergence(sprintf("The %s computation failed: %s", routine, conditionMessage(error)),
                      engine_message = conditionMessage(error))
  })
}

# K-22: the area under the ROC curve of the fitted probabilities, as pROC::auc() computes it
# by default (the direction puts cases above controls unless the controls' median is the
# larger), by the Mann-Whitney formula with ties counted one half. pROC integrates the ROC
# curve instead, which can differ in the last bit (D-40).
logistic_fe_auc <- function(response, fitted) {
  cases <- response == 1
  predictor <- if (stats::median(fitted[!cases]) > stats::median(fitted[cases])) -fitted else fitted
  ranks <- rank(predictor)
  n_cases <- as.numeric(sum(cases))
  n_controls <- as.numeric(sum(!cases))
  (sum(ranks[cases]) - n_cases * (n_cases + 1) / 2) / (n_cases * n_controls)
}

# Non-convergence warns whatever `verbose` is (DEC-008); `verbose` adds every iteration's
# criterion, formatted as the reference printed it.
logistic_fe_report_convergence <- function(convergence, method, verbose) {
  label <- c(serbin = "SerBIN", ban = "BAN")[[method]]
  if (!isTRUE(convergence$converged)) {
    warn_not_converged(
      sprintf(paste("%s reached the iteration limit after %d iterations without meeting the stopping rule",
                    "\"%s\" (criterion %s, tol %s)."),
              label, convergence$iterations, convergence$stop_rule, format(convergence$criterion),
              format(convergence$tol)),
      iterations = convergence$iterations, criterion = convergence$criterion
    )
  }
  if (isTRUE(verbose)) {
    history <- convergence$history
    for (k in seq_len(nrow(history))) {
      inform_message(verbose, sprintf("Iteration %d: criterion %s.", k,
                                      formatC(history[k, "rule"], format = "e", digits = 3)))
    }
    outcome <- if (isTRUE(convergence$converged)) "converged" else "stopped"
    inform_message(verbose, sprintf("%s %s after %d iterations.", label, outcome, convergence$iterations))
  }
}

# The model object (ARCHITECTURE §D.1): the shared fields, plus the fit statistics and the
# convergence diagnostics.
new_pprof_logistic_fe <- function(data, estimates, spec, call = NULL, keep_data = FALSE) {
  included <- data$providers$provider_id[data$providers$included]
  covariates <- colnames(data$design)
  vcov <- estimates$variances$beta
  dimnames(vcov) <- list(covariates, covariates)
  model <- new_pprof_model(
    data,
    coefficients = stats::setNames(estimates$beta, covariates),
    vcov = vcov,
    provider_effects = stats::setNames(estimates$gamma, included),
    linear_predictor = estimates$linear_predictor,
    spec = spec,
    loglik = estimates$loglik, aic = estimates$aic, bic = estimates$bic, auc = estimates$auc,
    provider_effect_variance = stats::setNames(estimates$variances$gamma, included),
    convergence = estimates$convergence, call = call, keep_data = keep_data, class = "pprof_logistic_fe"
  )
  validate_pprof_logistic_fe(model)
}

validate_pprof_logistic_fe <- function(x) {
  fail <- function(what) abort_invalid_input(sprintf("Invalid `pprof_logistic_fe` object: %s.", what), arg = "x")
  if (!inherits(x, "pprof_logistic_fe")) fail("not of class `pprof_logistic_fe`")
  validate_pprof_model(x)
  if (!identical(x$spec$family, "logistic_fe")) fail("`spec$family` must be \"logistic_fe\"")
  if (!is.logical(x$response) && !all(x$response %in% c(0, 1))) fail("`response` must be binary")
  if (is.null(x$provider_effect_variance)) fail("`provider_effect_variance` is required")
  for (field in c("loglik", "aic", "bic", "auc")) {
    if (!is.numeric(x[[field]]) || length(x[[field]]) != 1L) fail(sprintf("`%s` must be a number", field))
  }
  required <- c("iterations", "converged", "criterion", "stop_rule", "tol", "max_iter")
  if (!is.list(x$convergence) || !all(required %in% names(x$convergence))) {
    fail(sprintf("`convergence` must hold %s", paste(required, collapse = ", ")))
  }
  invisible(x)
}

# --- Standard methods (ARCHITECTURE §D.3) ------------------------------------------------

#' Fitted values, residuals, predictions, and log-likelihood of a logistic fixed-effect model
#'
#' `fitted()` returns the fitted probabilities plogis(gamma_i + z'beta) and `residuals()`
#' the residuals of the observations used in the fit, in the order of the rows of the data
#' and named by those rows. `predict()` returns the linear predictor gamma_i + z'beta or the
#' probability, for the observations of the fit (as `fitted()` orders them) or for new data
#' that contain the covariates and the provider column (one value per row, named by the row
#' names of `newdata`). `logLik()` returns the log-likelihood with m + p degrees of
#' freedom (m providers, p coefficients), so `AIC()` and `BIC()` agree with the fit's `aic`
#' and `bic`.
#'
#' @param object A `pprof_logistic_fe` model.
#' @param type For `residuals()`: `"deviance"` (the default, as for [stats::glm()]),
#'   `"pearson"`, or `"response"`. For `predict()`: `"link"` or `"response"`.
#' @param newdata A data frame with the covariates and the provider column, or `NULL` for
#'   the observations of the fit. Rows with a missing covariate, and rows of providers
#'   without an effect (absent from the fit or excluded by screening, which warns), give NA.
#' @param ... Not used.
#'
#' @name logistic_fe_methods
NULL

#' @rdname logistic_fe_methods
#' @importFrom stats fitted
#' @export
fitted.pprof_logistic_fe <- function(object, ...) {
  model_input_order(object, logistic_fe_probabilities(object))
}

#' @rdname logistic_fe_methods
#' @importFrom stats residuals
#' @export
residuals.pprof_logistic_fe <- function(object, type = "deviance", ...) {
  check_choice(type, c("deviance", "pearson", "response"), "type")
  y <- as.numeric(object$response)
  p <- logistic_fe_probabilities(object)
  values <- switch(type,
    response = y - p,
    pearson = (y - p) / sqrt(p * (1 - p)),
    deviance = sign(y - p) * sqrt(-2 * ifelse(y == 1, log(p), log(1 - p)))
  )
  model_input_order(object, values)
}

#' @rdname logistic_fe_methods
#' @importFrom stats predict
#' @export
predict.pprof_logistic_fe <- function(object, newdata = NULL, type = "link", ...) {
  check_choice(type, c("link", "response"), "type")
  eta <- if (is.null(newdata)) {
    model_input_order(object, model_observation_effects(object, object$provider_effects) + object$linear_predictor)
  } else {
    model_effects_for(object, newdata) + drop(model_design_for(object, newdata) %*% object$coefficients)
  }
  if (identical(type, "response")) stats::plogis(eta) else eta
}

#' @rdname logistic_fe_methods
#' @importFrom stats logLik
#' @export
logLik.pprof_logistic_fe <- function(object, ...) {
  structure(object$loglik, df = object$n_providers + length(object$coefficients), nobs = object$n_obs,
            class = "logLik")
}

# K-23: fitted probabilities plogis(gamma_i + z'beta), unclamped, in the order of the
# observations of the model.
logistic_fe_probabilities <- function(model) {
  stats::plogis(model_observation_effects(model, model$provider_effects) + model$linear_predictor)
}

# --- Contract methods (ARCHITECTURE §E.1) -----------------------------------------------

#' @export
expected_outcome.pprof_logistic_fe <- function(model, effect, ...) {
  stats::plogis(model_observation_effects(model, effect) + model$linear_predictor)
}

#' @export
null_effect.pprof_logistic_fe <- function(model, null = "median", ...) {
  # K-60: the median of the provider effects (R's median, as the reference computes it), or
  # a number; an integer is used as the equal double (D-14).
  if (identical(null, "median")) return(unname(stats::median(model$provider_effects)))
  if (is.numeric(null) && length(null) == 1L && is.finite(null)) return(as.double(null))
  abort_invalid_input("`null` must be \"median\" or a single finite number.", arg = "null")
}

#' @export
profile_spec.pprof_logistic_fe <- function(model) {
  # ARCHITECTURE §B.4. The direct expectation runs in C++, as the reference's
  # computeDirectExp() does (K-81); the funnel is K-110; Wald inference warns about providers
  # with no events or only events (K-67).
  list(
    family = "logistic_fe", effect = "gamma", null_default = "median", null_options = "median",
    indirect_numerator = "observed", measures = c("ratio", "rate"), mean_function = stats::plogis,
    variance_function = function(mean) mean * (1 - mean),
    direct_expected = function(effects, linear_predictor, threads) {
      logistic_fe_engine_call("direct expectation",
                              cpp_logistic_direct_expected(effects, linear_predictor, as.integer(threads)))
    },
    funnel = list(
      measure = "ratio", target = 1, floor = 0, test = "score",
      precision = function(expected, variance) expected^2 / variance,
      half_width = function(critical, precision) critical * sqrt(1 / precision)
    ),
    wald_caution = TRUE
  )
}

#' @export
inference_capabilities.pprof_logistic_fe <- function(model) {
  c("coef_wald", "coef_lr", "coef_score", "provider_exact", "provider_bootstrap", "provider_score",
    "provider_score_standard", "provider_wald", "interval_exact", "interval_score", "interval_wald",
    "standardize_indirect", "standardize_direct", "funnel")
}

#' @export
provider_estimate_se.pprof_logistic_fe <- function(model) {
  sqrt(model$provider_effect_variance)
}

# The settings of the null fits of the covariate likelihood-ratio and score tests: the
# defaults of logis_fe(), whatever settings the model used, as the reference refits
# (R/summary.logis_fe.R:147, :178; D-10, awaiting sign-off).
logistic_fe_null_spec <- list(
  family = "logistic_fe", method = "serbin", max_iter = 10000, tol = 1e-5, stop_rule = "any", backtrack = TRUE,
  effect_bound = 10, min_provider_size = 10, keep_data = FALSE
)

#' @export
refit_without.pprof_logistic_fe <- function(model, covariates, data = NULL, ...) {
  prepared <- model_prepared_data(model, data)
  keep <- setdiff(colnames(prepared$design), covariates)
  if (length(keep) == 0L) {
    # D-30: the reference has no null model without covariates.
    abort_unsupported_inference(model, "a covariate test whose null model has no covariates")
  }
  sizes <- prepared$providers$n_obs[prepared$providers$included]
  if (any(sizes < logistic_fe_null_spec$min_provider_size)) {
    # D-10: the reference's null fit screens again at its default minimum provider size and
    # then fails; reproduced as a classed error until the methodology owners decide.
    abort_data(sprintf(paste("The null model is refit with min_provider_size = %d, which would exclude",
                             "providers the model includes."), logistic_fe_null_spec$min_provider_size))
  }
  null_prepared <- prepared
  null_prepared$design <- prepared$design[, keep, drop = FALSE]
  estimates <- logistic_fe_estimate(null_prepared, logistic_fe_null_spec, threads = 1L)
  new_pprof_logistic_fe(null_prepared, estimates, logistic_fe_null_spec)
}

#' @export
provider_test.pprof_logistic_fe <- function(model, test, null, providers = NULL, data = NULL, threads = 1, ...) {
  # K-66: the "standard" score test, from the full-model estimates without a refit. The
  # other provider tests need only expected outcomes and are computed by the profiling
  # layer.
  if (!identical(test, "score_standard")) abort_unsupported_inference(model, sprintf("provider_test(\"%s\")", test))
  prepared <- model_prepared_data(model, data)
  sizes <- as.integer(model$providers$n_obs[model$providers$included])
  positions <- if (is.null(providers)) seq_along(sizes) else as.integer(providers)
  result <- logistic_fe_engine_call(
    "standard score test",
    cpp_logistic_score_standard(as.numeric(model$response), prepared$design, sizes, unname(model$provider_effects),
                                unname(model$coefficients), null, positions, as.integer(threads))
  )
  list(statistic = result$statistic, failed = result$failed)
}
