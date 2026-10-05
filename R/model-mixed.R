# Random-effect and correlated random-effect models fit with lme4 (ARCHITECTURE §B.2, §D,
# §E; K-50 to K-54): the lme4 adapter, the fitting steps the four families share, the
# intermediate class pprof_mixed (DEC-004) with its constructor and validator, and the
# methods the families share. The fit functions are in model-linear-re.R,
# model-logistic-re.R, model-linear-cre.R, and model-logistic-cre.R. The family
# specification and the capabilities came with Phase 5 (DEC-046).

# What differs between the four families, as the reference computes it:
#   outcome    "linear" (lmer) or "logistic" (glmer);
#   variance   the provider variance from the first row of VarCorr: the square of its
#              `sdcor` or its `vcov` (K-51);
#   effect_sd  the standard deviation of the provider effects: the closed form of linear
#              random effects (K-69) or lme4's conditional standard deviation (K-70).
mixed_families <- list(
  linear_re = list(outcome = "linear", variance = "sdcor", effect_sd = "closed_form"),
  logistic_re = list(outcome = "logistic", variance = "sdcor", effect_sd = "conditional"),
  linear_cre = list(outcome = "linear", variance = "sdcor", effect_sd = "conditional"),
  logistic_cre = list(outcome = "logistic", variance = "vcov", effect_sd = "conditional")
)

# The fit of every mixed family: the data layer (no screening, K-07; the within-between
# decomposition for CRE models, K-54), the lme4 fit, and the model object. `...` goes to
# lmer() or glmer().
mixed_fit <- function(family, call, formula, data, provider, within_between, keep_data, verbose, ...) {
  check_flag(keep_data, "keep_data")
  check_flag(verbose, "verbose")
  rules <- mixed_families[[family]]
  prepared <- data_prepare(formula, data, provider, within_between = within_between, intercept = TRUE)
  mixed_check_data(prepared, rules$outcome)
  fit_data <- if (is.null(within_between)) data else data_decompose_within_between(data, provider, within_between)
  estimates <- mixed_estimate(prepared, fit_data, provider, rules, verbose, ...)
  spec <- list(
    family = family, outcome = rules$outcome, engine = if (identical(rules$outcome, "linear")) "lmer" else "glmer",
    within_between = within_between, engine_arguments = list(...), keep_data = keep_data
  )
  new_pprof_mixed(prepared, estimates, spec, call = call, keep_data = keep_data, class = paste0("pprof_", family))
}

# The data a mixed model needs: a finite outcome, binary with both values for logistic
# models, and finite covariates.
mixed_check_data <- function(prepared, outcome) {
  response <- prepared$response
  if (identical(outcome, "logistic")) {
    if (!is.logical(response) && !all(response %in% c(0, 1))) {
      abort_invalid_input("The outcome must be binary: 0 and 1, or FALSE and TRUE.", arg = "formula")
    }
    if (all(response == response[1])) {
      abort_data("The outcome has the same value for every observation; the model needs both outcomes.")
    }
  } else if (!all(is.finite(range(response)))) {
    abort_invalid_input("The outcome must be finite.", arg = "formula")
  }
  if (ncol(prepared$design) > 0L && !all(is.finite(range(prepared$design)))) {
    abort_invalid_input("The covariates must be finite.", arg = "formula")
  }
  invisible(prepared)
}

# Fits the model with lme4 and extracts what the reference reads from the fit
# (R/linear_re.R:154-209, R/logis_re.R, R/linear_cre.R, R/logis_cre.R:118-170), with the
# family's rules. `data` holds the input rows (decomposed for CRE models).
mixed_estimate <- function(prepared, data, provider, rules, verbose, ...) {
  engine <- lme4_fit(mixed_lme4_formula(prepared$terms, provider), mixed_lme4_data(data, prepared, provider),
                     rules$outcome, ...)
  for (text in engine$messages) inform_message(verbose, text)
  fit <- engine$fit
  ids <- prepared$providers$provider_id[prepared$providers$included]
  random <- lme4::ranef(fit, condVar = TRUE)[[provider]]
  # `...` must not change which observations and providers lme4 fits (for example through
  # `subset`), or the model would no longer describe its data.
  if (stats::nobs(fit) != length(prepared$response) || !identical(rownames(random), ids)) {
    abort_invalid_input("`...` changed the observations or providers that lme4 fits; select rows through `data`.",
                        arg = "...")
  }

  fit_summary <- summary(fit)
  fixed <- lme4::fixef(fit)
  varcor <- as.data.frame(fit_summary$varcor)
  provider_variance <- if (identical(rules$variance, "vcov")) varcor[1L, "vcov"] else varcor[1L, "sdcor"]^2
  sigma <- if (identical(rules$outcome, "linear")) fit_summary$sigma else NULL
  effect_sd <- if (identical(rules$effect_sd, "closed_form")) {
    linear_re_effect_sd(provider_variance, sigma, prepared$providers$n_obs[prepared$providers$included])
  } else {
    # K-70 (R/test.logis_re.R:12-15).
    sqrt(attr(random, "postVar")[1L, 1L, ])
  }
  vcov <- as.matrix(fit_summary$vcov)
  dimnames(vcov) <- list(names(fixed), names(fixed))
  loglik <- stats::logLik(fit)
  list(
    fit = fit, fixed = fixed, effects = random[, 1L], effect_sd = effect_sd, provider_variance = provider_variance,
    sigma = sigma, vcov = vcov,
    # K-53: X beta including the intercept, with lme4's design, and lme4's fitted values,
    # without lme4's row names.
    linear_predictor = unname(drop(stats::model.matrix(fit) %*% matrix(fixed))), fitted = unname(stats::fitted(fit)),
    loglik = as.numeric(loglik), loglik_df = attr(loglik, "df"), aic = stats::AIC(fit), bic = stats::BIC(fit),
    convergence = lme4_convergence(fit, engine$messages)
  )
}

# K-69: the standard deviation of a linear random effect, sqrt(R_i sigma^2 / n_i) with the
# shrinkage factor R_i = var_alpha / (var_alpha + sigma^2 / n_i), as the reference computes
# it (R/test.linear_re.R:11-21).
linear_re_effect_sd <- function(provider_variance, sigma, sizes) {
  sigma_sq <- sigma^2
  shrinkage <- provider_variance / (provider_variance + sigma_sq / sizes)
  sqrt(shrinkage * sigma_sq / sizes)
}

# --- The lme4 adapter (K-50) ------------------------------------------------------------

# Fits a model with lme4 as the reference calls it (K-50): lmer(formula, data, ...) for
# linear models, with REML unless `...` says otherwise, or glmer(formula, data,
# family = binomial(link = "logit"), ...), with the Laplace approximation, for logistic
# models. lme4's messages (for example about a singular fit) are returned rather than
# printed, so that the fit functions report them only when verbose; its warnings pass
# through, and an error of lme4 becomes pprof_error_convergence.
lme4_fit <- function(formula, data, outcome, ...) {
  messages <- character()
  fit <- withCallingHandlers(
    tryCatch(
      if (identical(outcome, "linear")) {
        lme4::lmer(formula, data, ...)
      } else {
        lme4::glmer(formula, data, family = stats::binomial(link = "logit"), ...)
      },
      error = function(e) {
        abort_convergence(sprintf("The lme4 fit failed: %s", conditionMessage(e)), engine_message = conditionMessage(e))
      }
    ),
    message = function(m) {
      messages <<- c(messages, sub("\n$", "", conditionMessage(m)))
      invokeRestart("muffleMessage")
    }
  )
  list(fit = fit, messages = messages)
}

# The lme4 formula of a random-intercept model (DEC-042): the model's terms, with the random
# intercept of the provider added last, response ~ <fixed terms> + (1 | provider), as the
# reference's CRE fits and the formula interface of its RE fits write it (K-50).
mixed_lme4_formula <- function(terms, provider) {
  random <- call("(", call("|", 1, as.name(provider)))
  formula <- eval(call("~", terms[[2L]], call("+", terms[[3L]], random)))
  environment(formula) <- environment(terms)
  formula
}

# The rows lme4 fits, as the reference passes them (K-50): the columns of the outcome, the
# provider, and the covariates, and the complete rows sorted by provider, which are the rows
# of the prepared data in their order.
mixed_lme4_data <- function(data, prepared, provider) {
  response <- all.vars(prepared$terms[[2L]])
  columns <- unique(c(response, provider, setdiff(all.vars(prepared$terms), response)))
  data[prepared$row_index, columns, drop = FALSE]
}

# The convergence diagnostics of an lme4 fit: the optimizer, its return code, lme4's
# convergence messages, whether the fit is singular, and the messages lme4 printed. The fit
# converged when the optimizer reports success and lme4 has no convergence message.
lme4_convergence <- function(fit, messages) {
  optinfo <- fit@optinfo
  code <- optinfo$conv$opt
  convergence_messages <- optinfo$conv$lme4$messages
  list(
    converged = length(convergence_messages) == 0L && (is.null(code) || identical(as.integer(code), 0L)),
    optimizer = optinfo$optimizer, code = code, messages = convergence_messages,
    singular = lme4::isSingular(fit), engine_messages = messages
  )
}

# --- The model object (ARCHITECTURE §D.1) -------------------------------------------------

# The shared fields, plus lme4's fitted values (the numerator of the reference's indirect
# measures, K-82 and K-84), the standard deviation of the provider effects (K-69, K-70), the
# variance components (K-51), the fit statistics from lme4, for linear models the residual
# standard deviation, and with keep_data the lme4 fit.
new_pprof_mixed <- function(data, estimates, spec, call = NULL, keep_data = FALSE, class = character()) {
  ids <- data$providers$provider_id[data$providers$included]
  model <- new_pprof_model(
    data,
    coefficients = estimates$fixed,
    vcov = estimates$vcov,
    provider_effects = stats::setNames(estimates$effects, ids),
    linear_predictor = estimates$linear_predictor,
    spec = spec,
    fitted = estimates$fitted,
    provider_effect_sd = stats::setNames(estimates$effect_sd, ids),
    variance_components = list(provider = estimates$provider_variance, residual_sd = estimates$sigma),
    loglik = estimates$loglik, loglik_df = estimates$loglik_df, aic = estimates$aic, bic = estimates$bic,
    convergence = estimates$convergence, call = call, keep_data = keep_data, class = c(class, "pprof_mixed")
  )
  if (!is.null(estimates$sigma)) model$sigma <- estimates$sigma
  if (keep_data) model$engine_fit <- estimates$fit
  validate_pprof_mixed(model)
  model
}

validate_pprof_mixed <- function(x) {
  fail <- function(what) abort_invalid_input(sprintf("Invalid `pprof_mixed` object: %s.", what), arg = "x")
  if (!inherits(x, "pprof_mixed")) fail("not of class `pprof_mixed`")
  validate_pprof_model(x)
  if (!x$spec$family %in% names(mixed_families)) fail("`spec$family` must be a random-effect family")
  outcome <- mixed_families[[x$spec$family]]$outcome
  if (!identical(x$spec$outcome, outcome)) fail(sprintf("`spec$outcome` must be \"%s\"", outcome))
  if (!is.numeric(x$fitted) || length(x$fitted) != x$n_obs) fail("`fitted` must have one value per observation")
  if (!is.numeric(x$provider_effect_sd) || !identical(names(x$provider_effect_sd), names(x$provider_effects))) {
    fail("`provider_effect_sd` must be numeric and named like `provider_effects`")
  }
  if (!is.list(x$variance_components) || !is.numeric(x$variance_components$provider)) {
    fail("`variance_components` must hold the provider variance")
  }
  for (field in c("loglik", "aic", "bic")) {
    if (!is.numeric(x[[field]]) || length(x[[field]]) != 1L) fail(sprintf("`%s` must be a number", field))
  }
  if (identical(outcome, "linear") && (!is.numeric(x$sigma) || length(x$sigma) != 1L)) {
    fail("`sigma` must be a number")
  }
  if (identical(outcome, "logistic") && !is.logical(x$response) && !all(x$response %in% c(0, 1))) {
    fail("`response` must be binary")
  }
  if (!is.null(x$engine_fit) && !inherits(x$engine_fit, "merMod")) fail("`engine_fit` must be an lme4 fit")
  invisible(x)
}

# --- Standard methods (ARCHITECTURE §D.3) ------------------------------------------------

#' Fitted values, residuals, predictions, and log-likelihood of a random-effect model
#'
#' For models from [fit_linear_re()], [fit_logistic_re()], [fit_linear_cre()], and
#' [fit_logistic_cre()]: `fitted()` returns lme4's fitted values (with the provider effects;
#' probabilities for logistic models) and `residuals()` the residuals of the observations
#' used in the fit, in the order of the rows of the data and named by those rows.
#' `predict()` returns alpha_i + x'beta, or its inverse logit for logistic models with
#' `type = "response"`, for the observations of the fit (as `fitted()` orders them) or for
#' new data that contain the covariates and the provider column; correlated random-effect
#' models predict only for their own observations. `logLik()` returns lme4's
#' log-likelihood with lme4's degrees of freedom.
#'
#' @param object A model of class `pprof_mixed`.
#' @param type For `residuals()`: `"response"`, and for logistic models also `"deviance"`
#'   (their default) and `"pearson"`. For `predict()`: `"link"` or `"response"`.
#' @param newdata A data frame with the covariates and the provider column, or `NULL` for
#'   the observations of the fit. Rows with a missing covariate, and rows of providers
#'   absent from the fit (which warns), give NA.
#' @param ... Not used.
#'
#' @family model methods
#' @examples
#' data(ExampleDataLinear)
#' example <- data.frame(y = ExampleDataLinear$Y, hospital = ExampleDataLinear$ProvID,
#'                       ExampleDataLinear$Z)
#' fit <- fit_linear_re(y ~ z1 + z2 + z3 + z4 + z5, example, provider = "hospital")
#' head(fitted(fit))
#' predict(fit, newdata = example[c(1, 500, 1000), ])
#' logLik(fit)
#' @name mixed_methods
NULL

#' @rdname mixed_methods
#' @export
fitted.pprof_mixed <- function(object, ...) {
  model_input_order(object, object$fitted)
}

#' @rdname mixed_methods
#' @export
residuals.pprof_mixed <- function(object, type = NULL, ...) {
  y <- as.numeric(object$response)
  if (identical(object$spec$outcome, "logistic")) {
    if (is.null(type)) type <- "deviance"
    check_choice(type, c("deviance", "pearson", "response"), "type")
    values <- logistic_residuals(y, object$fitted, type)
  } else {
    if (is.null(type)) type <- "response"
    check_choice(type, "response", "type")
    values <- y - object$fitted
  }
  model_input_order(object, values)
}

#' @rdname mixed_methods
#' @export
predict.pprof_mixed <- function(object, newdata = NULL, type = "link", ...) {
  check_choice(type, c("link", "response"), "type")
  eta <- if (is.null(newdata)) {
    model_input_order(object, model_observation_effects(object, object$provider_effects) + object$linear_predictor)
  } else {
    if (!is.null(object$spec$within_between)) {
      abort_unsupported_inference(object, "predict() with newdata")
    }
    model_effects_for(object, newdata) + drop(model_design_for(object, newdata) %*% object$coefficients)
  }
  if (identical(type, "response") && identical(object$spec$outcome, "logistic")) stats::plogis(eta) else eta
}

#' @rdname mixed_methods
#' @export
logLik.pprof_mixed <- function(object, ...) {
  structure(object$loglik, df = object$loglik_df, nobs = object$n_obs, class = "logLik")
}

# --- Contract methods (ARCHITECTURE §E.1) -----------------------------------------------

#' @export
expected_outcome.pprof_mixed <- function(model, effect, ...) {
  eta <- model_observation_effects(model, effect) + model$linear_predictor
  if (identical(model$spec$outcome, "logistic")) stats::plogis(eta) else eta
}

#' @export
null_effect.pprof_mixed <- function(model, null = 0, ...) {
  # K-60: a number (default 0); an integer is used as the equal double.
  if (is.numeric(null) && length(null) == 1L && is.finite(null)) return(as.double(null))
  abort_invalid_input("`null` must be a single finite number.", arg = "null")
}

#' @export
provider_estimate_se.pprof_mixed <- function(model) {
  model$provider_effect_sd
}

#' @export
predicted_outcome.pprof_mixed <- function(model) {
  # lme4's fitted values, with the provider effects: the numerator of the reference's
  # indirect measures (K-82, K-84).
  model$fitted
}

#' @export
profile_spec.pprof_mixed <- function(model) {
  # ARCHITECTURE §B.4, as the reference's RE and CRE methods compute (R/test.*_re.R,
  # R/SM_output.*_re.R, R/confint.*_re.R, R/summary.*_re.R and their CRE versions). The null
  # is a number, 0 by default (K-60). Indirect measures put lme4's fitted values over the
  # outcomes expected with a zero effect, predicted over expected (K-82, K-84, M-14);
  # logistic measures are ratios and rates, linear ones differences, with the direct
  # reference total sum(y). Logistic direct expectations and direct limits run in C++, as
  # the reference's computeDirectExp() (K-82, K-93); linear ones are R's sums. The provider
  # tests and intervals use the normal distribution with the standard deviations of K-69 and
  # K-70. The covariate p-values are 2 (1 - pnorm(z)) for logistic models (D-31, awaiting
  # sign-off) and two-sided t(n - p - m + 1), p counting the intercept, for linear models
  # (K-104, K-105); the intervals are lme4's Wald intervals.
  logistic <- identical(model$spec$outcome, "logistic")
  df <- model$n_obs - length(model$coefficients) - model$n_providers + 1
  coefficient_wald <- if (logistic) {
    list(p_value = "upper_doubled", p_value_distribution = "normal", interval = "quantile",
         interval_distribution = "normal", df = NULL)
  } else {
    list(p_value = "two_sided", p_value_distribution = "t", interval = "quantile", interval_distribution = "normal",
         df = df)
  }
  list(
    family = model$spec$family, effect = "alpha", null_default = 0, null_options = character(),
    test_default = "wald", indirect_numerator = "predicted", comparison = if (logistic) "ratio" else "difference",
    measures = if (logistic) c("ratio", "rate") else "difference",
    mean_function = if (logistic) stats::plogis else identity,
    direct_expected = if (logistic) {
      logistic_direct_expected
    } else {
      function(effects, linear_predictor, threads) {
        vapply(effects, function(effect) sum(effect + linear_predictor), numeric(1))
      }
    },
    direct_reference = "observed", direct_limits = if (logistic) "direct_expected" else "mean_function",
    one_sided_extremes = FALSE, wald = list(test = "normal", interval = "normal", df = NULL),
    coefficient_wald = coefficient_wald, wald_caution = FALSE
  )
}

#' @export
inference_capabilities.pprof_mixed <- function(model) {
  # ARCHITECTURE §E.3: the Wald tests and intervals and both standardizations; no funnel.
  c("coef_wald", "provider_wald", "interval_wald", "standardize_indirect", "standardize_direct")
}
