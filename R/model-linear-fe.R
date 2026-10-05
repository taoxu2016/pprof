# Linear fixed-effect models (ARCHITECTURE §B.5, §D, §E): the fit function, the estimates
# by direct demeaning (DEC-006), the model object, the standard methods, and the contract
# methods, including the family specification and the capabilities (Phase 5, DEC-046).

#' Fit a linear fixed-effect model for provider profiling
#'
#' Fits the model y = gamma_i + z'beta + e for an observation of provider i, with one fixed
#' effect gamma_i per provider, covariate coefficients beta, and independent errors e of
#' variance sigma^2, by least squares. Every provider is included, whatever its size.
#'
#' The coefficients come from the deviations of the outcome and the covariates from their
#' provider means: beta = (Z'Z)^-1 Z'y with Z and y centered within providers, and
#' gamma_i = mean(y_i) - mean(z_i)'beta. pprof 1.0.3 computes the same estimates with dense
#' block-diagonal centering matrices, whose memory grows with the square of the provider
#' sizes; the two agree to rounding.
#'
#' The residual variance is sigma^2 = SSR / (n - m - p) for n observations, m providers,
#' and p coefficients, and Var(beta) = sigma^2 (Z'Z)^-1 with the centered Z. The variance of
#' a provider effect is sigma^2 / n_i (`provider_variance = "simplified"`, as in pprof 1.0.3
#' by default) or sigma^2 (1 / n_i + mean(z_i)' (Z'Z)^-1 mean(z_i)) (`"full"`). The
#' log-likelihood, AIC, and BIC count m + p + 1 parameters.
#'
#' @param formula A two-sided formula: the continuous outcome on the left and the covariates
#'   on the right. Transformations, interactions, and factors are allowed. The provider is
#'   not part of the formula, and the provider effects take the place of the intercept, so
#'   the formula keeps its intercept (no `- 1`).
#' @param data A data frame. Rows with a missing outcome, provider, or covariate are dropped.
#' @param provider The name of the column of `data` that identifies providers.
#' @param provider_variance The variance of the provider effects: `"simplified"` or `"full"`.
#' @param keep_data Whether to keep the prepared data, including the design matrix, in the
#'   object.
#' @param verbose Whether to report the size of the fit.
#'
#' @return A model object of class `c("pprof_linear_fe", "pprof_model")`. Besides the fields
#'   of every model (see [new_pprof_model()]), it holds the residual standard deviation
#'   (`sigma`), the log-likelihood (`loglik`), and AIC and BIC (`aic`, `bic`). The setting
#'   `provider_variance` is part of `spec`.
#'
#' @inheritSection fit_logistic_fe Provider order
#' @family fitting functions
#' @examples
#' data(ExampleDataLinear)
#' example <- data.frame(y = ExampleDataLinear$Y, hospital = ExampleDataLinear$ProvID,
#'                       ExampleDataLinear$Z)
#' fit <- fit_linear_fe(y ~ z1 + z2 + z3 + z4 + z5, example, provider = "hospital")
#' fit$coefficients
#' fit$sigma
#' @export
fit_linear_fe <- function(formula, data, provider, provider_variance = "simplified", keep_data = FALSE,
                          verbose = FALSE) {
  call <- match.call()
  check_choice(provider_variance, c("simplified", "full"), "provider_variance")
  check_flag(keep_data, "keep_data")
  check_flag(verbose, "verbose")

  # K-07: no screening; the intercept is absorbed by the provider effects.
  prepared <- data_prepare(formula, data, provider)
  linear_fe_check_data(prepared)
  spec <- list(family = "linear_fe", provider_variance = provider_variance, keep_data = keep_data)
  estimates <- linear_fe_estimate(prepared, provider_variance)
  inform_message(verbose, sprintf("%d observations of %d providers; residual standard deviation %s.",
                                  length(prepared$response), nrow(prepared$providers),
                                  format(signif(estimates$sigma, 6))))
  new_pprof_linear_fe(prepared, estimates, spec, call = call, keep_data = keep_data)
}

# The data a linear fixed-effect model needs: a finite outcome and at least one finite
# covariate.
linear_fe_check_data <- function(prepared) {
  if (!all(is.finite(range(prepared$response)))) {
    abort_invalid_input("The outcome must be finite.", arg = "formula")
  }
  if (ncol(prepared$design) == 0L) {
    abort_invalid_input("`formula` must have at least one covariate.", arg = "formula")
  }
  # range() is not finite exactly when some value is not, without the logical matrix of
  # is.finite(design).
  if (!all(is.finite(range(prepared$design)))) {
    abort_invalid_input("The covariates must be finite.", arg = "formula")
  }
  invisible(prepared)
}

# The estimates, variances, and fit statistics (K-40 to K-43). The provider means are
# computed as the reference computes them, mean() of the outcome and colMeans() of the
# covariates over each provider's observations (R/linear_fe.R:172-174), so that the provider
# effects differ from the reference only through beta. beta comes from the within-provider
# deviations instead of the reference's dense centering matrices (DEC-006); the two agree to
# rounding.
linear_fe_estimate <- function(prepared, provider_variance) {
  y <- as.numeric(prepared$response)
  z <- prepared$design
  index <- prepared$provider_index
  sizes <- prepared$providers$n_obs
  n <- length(y)
  m <- length(sizes)
  p <- ncol(z)
  rows <- split(seq_len(n), data_provider_factor(index, seq_len(m)))
  y_bar <- vapply(rows, function(r) mean(y[r]), numeric(1), USE.NAMES = FALSE)
  z_bar <- matrix(vapply(rows, function(r) colMeans(z[r, , drop = FALSE]), numeric(p), USE.NAMES = FALSE),
                  nrow = m, ncol = p, byrow = TRUE)

  # Column by column, so that the centered design is the only n-by-p copy of the design.
  within <- z
  attributes(within) <- list(dim = dim(z))
  for (j in seq_len(p)) within[, j] <- z[, j] - z_bar[index, j]
  inverse <- tryCatch(solve(crossprod(within)), error = function(e) {
    abort_data(sprintf(paste("The covariates are linearly dependent within providers, so the coefficients are not",
                             "identified: %s"), conditionMessage(e)))
  })
  beta <- drop(inverse %*% crossprod(within, y - y_bar[index]))
  gamma <- drop(y_bar - z_bar %*% beta)
  linear_predictor <- drop(z %*% beta)

  # K-41 to K-43, with the reference's expressions (R/linear_fe.R:191-221).
  residuals <- y - (gamma[index] + linear_predictor)
  ssr <- sum(residuals^2)
  sigma_sq <- ssr / (n - m - p)
  gamma_variance <- if (identical(provider_variance, "full")) {
    sigma_sq * (1 / sizes + rowSums((z_bar %*% inverse) * z_bar))
  } else {
    sigma_sq / sizes
  }
  loglik <- -(n / 2) * log(2 * pi) - (n / 2) * log(ssr / n) - (ssr / (2 * ssr / n))
  n_parameters <- m + p + 1
  list(
    gamma = gamma, beta = beta, vcov = sigma_sq * inverse, gamma_variance = gamma_variance,
    linear_predictor = linear_predictor, sigma = sqrt(sigma_sq), loglik = loglik,
    aic = -2 * loglik + 2 * n_parameters, bic = -2 * loglik + n_parameters * log(n)
  )
}

# The model object (ARCHITECTURE §D.1): the shared fields and the fit statistics.
new_pprof_linear_fe <- function(data, estimates, spec, call = NULL, keep_data = FALSE) {
  ids <- data$providers$provider_id
  covariates <- colnames(data$design)
  vcov <- estimates$vcov
  dimnames(vcov) <- list(covariates, covariates)
  model <- new_pprof_model(
    data,
    coefficients = stats::setNames(estimates$beta, covariates),
    vcov = vcov,
    provider_effects = stats::setNames(estimates$gamma, ids),
    linear_predictor = estimates$linear_predictor,
    spec = spec,
    sigma = estimates$sigma, loglik = estimates$loglik, aic = estimates$aic, bic = estimates$bic,
    provider_effect_variance = stats::setNames(estimates$gamma_variance, ids),
    call = call, keep_data = keep_data, class = "pprof_linear_fe"
  )
  validate_pprof_linear_fe(model)
  model
}

validate_pprof_linear_fe <- function(x) {
  fail <- function(what) abort_invalid_input(sprintf("Invalid `pprof_linear_fe` object: %s.", what), arg = "x")
  if (!inherits(x, "pprof_linear_fe")) fail("not of class `pprof_linear_fe`")
  validate_pprof_model(x)
  if (!identical(x$spec$family, "linear_fe")) fail("`spec$family` must be \"linear_fe\"")
  if (!x$spec$provider_variance %in% c("simplified", "full")) {
    fail("`spec$provider_variance` must be \"simplified\" or \"full\"")
  }
  if (!all(x$providers$included)) fail("every provider must be included")
  if (is.null(x$provider_effect_variance)) fail("`provider_effect_variance` is required")
  for (field in c("sigma", "loglik", "aic", "bic")) {
    if (!is.numeric(x[[field]]) || length(x[[field]]) != 1L) fail(sprintf("`%s` must be a number", field))
  }
  invisible(x)
}

# --- Standard methods (ARCHITECTURE §D.3) ------------------------------------------------

#' Fitted values, residuals, predictions, and log-likelihood of a linear fixed-effect model
#'
#' `fitted()` returns the fitted values gamma_i + z'beta and `residuals()` the residuals
#' y - fitted of the observations used in the fit, in the order of the rows of the data and
#' named by those rows. `predict()` returns gamma_i + z'beta for the observations of the
#' fit (as `fitted()` orders them) or for new data that contain the covariates and the
#' provider column (one value per row, named by the row names of `newdata`). `logLik()`
#' returns the log-likelihood with m + p + 1 degrees of freedom (m providers, p
#' coefficients, and the residual variance), so `AIC()` and `BIC()` agree with the fit's
#' `aic` and `bic`.
#'
#' @param object A `pprof_linear_fe` model.
#' @param type For `residuals()`: `"response"`, the only type.
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
#' fit <- fit_linear_fe(y ~ z1 + z2 + z3 + z4 + z5, example, provider = "hospital")
#' head(fitted(fit))
#' head(residuals(fit))
#' predict(fit, newdata = example[c(1, 500, 1000), ])
#' logLik(fit)
#' @name linear_fe_methods
NULL

#' @rdname linear_fe_methods
#' @export
fitted.pprof_linear_fe <- function(object, ...) {
  model_input_order(object, linear_fe_fitted(object))
}

#' @rdname linear_fe_methods
#' @export
residuals.pprof_linear_fe <- function(object, type = "response", ...) {
  check_choice(type, "response", "type")
  model_input_order(object, as.numeric(object$response) - linear_fe_fitted(object))
}

#' @rdname linear_fe_methods
#' @export
predict.pprof_linear_fe <- function(object, newdata = NULL, ...) {
  if (is.null(newdata)) return(stats::fitted(object))
  model_effects_for(object, newdata) + drop(model_design_for(object, newdata) %*% object$coefficients)
}

#' @rdname linear_fe_methods
#' @export
logLik.pprof_linear_fe <- function(object, ...) {
  structure(object$loglik, df = object$n_providers + length(object$coefficients) + 1, nobs = object$n_obs,
            class = "logLik")
}

# Fitted values gamma_i + z'beta in the order of the observations of the model, the sum the
# reference computes (R/linear_fe.R:187-188).
linear_fe_fitted <- function(model) {
  model_observation_effects(model, model$provider_effects) + model$linear_predictor
}

# --- Contract methods (ARCHITECTURE §E.1) -----------------------------------------------

#' @export
expected_outcome.pprof_linear_fe <- function(model, effect, ...) {
  model_observation_effects(model, effect) + model$linear_predictor
}

#' @export
null_effect.pprof_linear_fe <- function(model, null = "median", ...) {
  # K-60: the median of the provider effects, their mean weighted by provider size
  # (R/test.linear_fe.R:58-61), or a number; an integer is used as the equal double.
  effects <- unname(model$provider_effects)
  if (identical(null, "median")) return(stats::median(effects))
  if (identical(null, "mean")) return(sum(model$providers$n_obs * effects) / model$n_obs)
  if (is.numeric(null) && length(null) == 1L && is.finite(null)) return(as.double(null))
  abort_invalid_input("`null` must be \"median\", \"mean\", or a single finite number.", arg = "null")
}

#' @export
provider_estimate_se.pprof_linear_fe <- function(model) {
  sqrt(model$provider_effect_variance)
}

#' @export
profile_spec.pprof_linear_fe <- function(model) {
  # ARCHITECTURE §B.4, as the reference's linear FE methods compute (R/test.linear_fe.R,
  # R/SM_output.linear_fe.R, R/confint.linear_fe.R, R/summary.linear_fe.R,
  # R/plot.linear_fe.R). Measures are differences (K-83): indirect (O_i - E_i) / n_i with
  # E_i = sum(null + z'beta), direct (E_i - total) / n with E_i = sum(gamma_i + z'beta) over
  # all observations and the reference total sum(null + z'beta). The provider tests use the
  # normal distribution with the simplified variance and t(n - m - p) with the full one
  # (K-68), the intervals the reverse (K-92, D-32, awaiting sign-off); the covariate tests
  # and intervals use t(n - m - p) (K-103). The funnel's precision is n_i and its half-width
  # z * sqrt(1 / n_i) * sigma, without a floor, whatever the provider variance (K-111, D-43).
  df <- model$n_obs - model$n_providers - length(model$coefficients)
  sigma <- model$sigma
  full <- identical(model$spec$provider_variance, "full")
  list(
    family = "linear_fe", effect = "gamma", null_default = "median", null_options = c("median", "mean"),
    test_default = "wald", indirect_numerator = "observed", comparison = "difference", measures = "difference",
    mean_function = identity,
    direct_expected = function(effects, linear_predictor, threads) {
      vapply(effects, function(effect) sum(effect + linear_predictor), numeric(1))
    },
    direct_reference = "null_expected", direct_limits = "mean_function", one_sided_extremes = FALSE,
    wald = list(test = if (full) "t" else "normal", interval = if (full) "normal" else "t", df = df),
    coefficient_wald = list(p_value = "two_sided", p_value_distribution = "t", interval = "critical",
                            interval_distribution = "t", df = df),
    funnel = list(
      measure = "difference", target = 0, floor = -Inf, test = "wald",
      precision = function(expected, variance, n_obs) n_obs,
      half_width = function(critical, precision) critical * sqrt(1 / precision) * sigma
    ),
    wald_caution = FALSE
  )
}

#' @export
inference_capabilities.pprof_linear_fe <- function(model) {
  # ARCHITECTURE §E.3: the Wald tests and intervals, both standardizations, and the funnel.
  c("coef_wald", "provider_wald", "interval_wald", "standardize_indirect", "standardize_direct", "funnel")
}
