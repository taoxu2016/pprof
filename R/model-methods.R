# Standard methods that every model shares (ARCHITECTURE §D.3), and the helpers that build
# a design matrix and provider effects for new data.

#' Standard methods for provider-profiling models
#'
#' `coef()` returns the covariate coefficients, `vcov()` their covariance matrix, `nobs()`
#' the number of observations used in the fit (after screening), and `formula()` the model
#' formula.
#'
#' @param object,x A model object, of a class that inherits from `pprof_model`.
#' @param ... Not used.
#'
#' @family model methods
#' @examples
#' data(ExampleDataBinary)
#' example <- data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID,
#'                       ExampleDataBinary$Z)
#' fit <- fit_logistic_fe(y ~ z1 + z2 + z3 + z4 + z5, example, provider = "hospital")
#' coef(fit)
#' vcov(fit)[1:2, 1:2]
#' nobs(fit)
#' formula(fit)
#' @name pprof_model_methods
NULL

#' @rdname pprof_model_methods
#' @importFrom stats coef
#' @export
coef.pprof_model <- function(object, ...) object$coefficients

#' @rdname pprof_model_methods
#' @importFrom stats vcov
#' @export
vcov.pprof_model <- function(object, ...) object$vcov

#' @rdname pprof_model_methods
#' @importFrom stats nobs
#' @export
nobs.pprof_model <- function(object, ...) object$n_obs

#' @rdname pprof_model_methods
#' @importFrom stats formula
#' @export
formula.pprof_model <- function(x, ...) x$formula

# The covariate design matrix for new data, built as the data layer built the model's
# design (K-04): the model's terms without the response, the factor levels and contrasts of
# the fit, and no intercept column for fixed-effect models. Rows with a missing covariate
# give rows of NA.
model_design_for <- function(model, newdata) {
  check_data_frame(newdata, "newdata")
  terms <- stats::delete.response(model$terms)
  frame <- stats::model.frame(terms, newdata, na.action = stats::na.pass, xlev = model$data_spec$xlevels)
  design <- stats::model.matrix(terms, frame, contrasts.arg = model$data_spec$contrasts)
  if (!isTRUE(model$data_spec$intercept)) design <- design[, -1L, drop = FALSE]
  design
}

# The provider effect of each row of new data, matched by provider ID; NA, with a warning,
# for providers that the model has no effect for (absent from the fit or excluded).
model_effects_for <- function(model, newdata) {
  provider <- model$data_spec$provider_name
  check_column(newdata, provider, "newdata")
  ids <- as.character(newdata[[provider]])
  effects <- unname(model$provider_effects[match(ids, names(model$provider_effects))])
  unknown <- unique(ids[is.na(effects) & !is.na(ids)])
  if (length(unknown) > 0L) {
    warn_unknown_providers(
      sprintf("The model has no effect for %d provider%s of `newdata` (%s); their predictions are NA.", length(unknown),
              if (length(unknown) == 1L) "" else "s", paste(utils::head(unknown, 5L), collapse = ", ")),
      providers = unknown
    )
  }
  effects
}
