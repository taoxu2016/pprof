# Logistic random-effect models (ARCHITECTURE §B.2, §D): the fit function. The lme4
# adapter, the model object, and the methods are shared with the other mixed families
# (model-mixed.R).

#' Fit a logistic random-effect model for provider profiling
#'
#' Fits the model logit P(y = 1) = x'beta + alpha_i for an observation of provider i, with
#' a fixed intercept and covariate coefficients in beta and a random intercept
#' alpha_i ~ N(0, var_alpha) for each provider, with [lme4::glmer()] and the Laplace
#' approximation. Every provider is included, whatever its size.
#'
#' The provider effects are the conditional modes of the random intercepts and their
#' standard deviations lme4's conditional standard deviations, as in pprof 1.0.3.
#'
#' @inheritParams fit_linear_re
#' @param formula A two-sided formula: the binary outcome (0 and 1, or `FALSE` and `TRUE`)
#'   on the left and the covariates on the right, without random-effect terms; the model
#'   adds a random intercept for the provider. Transformations, interactions, and factors
#'   are allowed.
#' @param ... Arguments passed to the lme4 fit, such as `control`.
#'
#' @return A model object of class `c("pprof_logistic_re", "pprof_mixed", "pprof_model")`
#'   with the fields of [fit_linear_re()] models except the residual standard deviation;
#'   `fitted` holds lme4's fitted probabilities.
#'
#' @inheritSection fit_logistic_fe Provider order
#' @family fitting functions
#' @examples
#' data(ExampleDataBinary)
#' example <- data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID,
#'                       ExampleDataBinary$Z)
#' example <- example[example$hospital <= 20, ]
#' fit <- fit_logistic_re(y ~ z1 + z2 + z3 + z4 + z5, example, provider = "hospital")
#' fit$coefficients
#' head(fit$provider_effects)
#' @export
fit_logistic_re <- function(formula, data, provider, keep_data = FALSE, verbose = FALSE, ...) {
  mixed_fit("logistic_re", match.call(), formula, data, provider, NULL, keep_data, verbose, ...)
}
