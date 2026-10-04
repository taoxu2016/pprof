# Linear random-effect models (ARCHITECTURE §B.2, §D): the fit function. The lme4 adapter,
# the model object, and the methods are shared with the other mixed families
# (model-mixed.R).

#' Fit a linear random-effect model for provider profiling
#'
#' Fits the model y = x'beta + alpha_i + e for an observation of provider i, with a fixed
#' intercept and covariate coefficients in beta, a random intercept alpha_i ~ N(0, var_alpha)
#' for each provider, and independent errors e ~ N(0, sigma^2), with [lme4::lmer()], by
#' restricted maximum likelihood (REML) unless `...` sets `REML = FALSE`. Every provider is
#' included, whatever its size.
#'
#' The provider effects are the conditional modes of the random intercepts. As in pprof
#' 1.0.3, their standard deviations are sqrt(R_i sigma^2 / n_i), with the shrinkage factor
#' R_i = var_alpha / (var_alpha + sigma^2 / n_i) for the n_i observations of provider i.
#'
#' @param formula A two-sided formula: the outcome on the left and the covariates on the
#'   right, without random-effect terms; the model adds a random intercept for the
#'   provider. Transformations, interactions, and factors are allowed.
#' @param data A data frame. Rows with a missing outcome, provider, or covariate are dropped.
#' @param provider The name of the column of `data` that identifies providers.
#' @param keep_data Whether to keep the prepared data, including the design matrix, and the
#'   lme4 fit (`engine_fit`) in the object.
#' @param verbose Whether to report lme4's messages, such as a note about a singular fit.
#' @param ... Arguments passed to the lme4 fit, such as `REML` or `control`.
#'
#' @return A model object of class `c("pprof_linear_re", "pprof_mixed", "pprof_model")`.
#'   Besides the fields of every model (see [new_pprof_model()]), with the fixed effects,
#'   intercept included, as `coefficients` and the conditional modes as `provider_effects`,
#'   it holds lme4's fitted values (`fitted`), the standard deviations of the provider
#'   effects (`provider_effect_sd`), the variance components (`variance_components`: the
#'   provider variance and the residual standard deviation), the residual standard
#'   deviation (`sigma`), lme4's log-likelihood, AIC, and BIC (`loglik`, `aic`, `bic`),
#'   and lme4's convergence diagnostics (`convergence`).
#'
#' @examples
#' data(ExampleDataLinear)
#' example <- data.frame(y = ExampleDataLinear$Y, hospital = ExampleDataLinear$ProvID,
#'                       ExampleDataLinear$Z)
#' fit <- fit_linear_re(y ~ z1 + z2 + z3 + z4 + z5, example, provider = "hospital")
#' fit$coefficients
#' head(fit$provider_effects)
#' @export
fit_linear_re <- function(formula, data, provider, keep_data = FALSE, verbose = FALSE, ...) {
  mixed_fit("linear_re", match.call(), formula, data, provider, NULL, keep_data, verbose, ...)
}
