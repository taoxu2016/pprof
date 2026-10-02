# The model contract (ARCHITECTURE §E.1).
#
# The inference and profiling layers read a model only through these generics, never through
# its fields, so that a new model class plugs in without changes to those layers. The
# accessors have shared methods for `pprof_model` that read the fields new_pprof_model()
# fills. The other generics have no shared method: a model class that does not implement one
# raises `pprof_error_unsupported_inference`, so it never returns a number it was not built
# to compute.

#' Model contract for provider profiling
#'
#' The generics through which the inference and provider-profiling layers read a model. A new
#' model class builds its object with [new_pprof_model()] and provides methods for the
#' generics it needs:
#'
#' - `provider_table()`, `provider_estimates()`, `provider_index()`, `linear_predictor()`,
#'   `observed_outcome()`, and `inference_capabilities()` have shared methods that read the
#'   fields filled by [new_pprof_model()]; `inference_capabilities()` declares nothing.
#' - `expected_outcome()`, `null_effect()`, `profile_spec()`, `provider_estimate_se()`,
#'   `provider_test()`, and `refit_without()` have no shared method and raise
#'   `pprof_error_unsupported_inference` for a model class that does not implement them.
#'
#' @param model A model object inheriting from `pprof_model`.
#' @param effect A provider effect: a single value, or one value per included provider in
#'   provider order.
#' @param null The null value or population norm, as the model's family defines it (for
#'   example `"median"` or a number).
#' @param test The name of a provider test that the model declares.
#' @param covariates Names of the covariates to drop.
#' @param data The data frame the model was fit to.
#' @param ... Further arguments of methods.
#'
#' @return `provider_table()`: the provider table. `provider_estimates()`: the provider effects,
#'   named by provider ID. `provider_index()`: the provider of each observation, as a row of
#'   the provider table. `linear_predictor()`, `observed_outcome()`, `expected_outcome()`: one
#'   value per observation. `null_effect()`: a number. `profile_spec()`: the family
#'   specification. `inference_capabilities()`: a character vector. `provider_estimate_se()`:
#'   standard errors named like the provider effects. `provider_test()`: per-provider test
#'   results. `refit_without()`: a model object.
#'
#' @name model_contract
#' @keywords internal
NULL

contract_not_model <- function(model) {
  abort_invalid_input(sprintf("`model` must be a pprof model object, not an object of class '%s'.", class(model)[1]),
                      arg = "model")
}

#' @rdname model_contract
#' @export
provider_table <- function(model) UseMethod("provider_table")

#' @export
provider_table.pprof_model <- function(model) model[["providers"]]

#' @export
provider_table.default <- function(model) contract_not_model(model)

#' @rdname model_contract
#' @export
provider_estimates <- function(model) UseMethod("provider_estimates")

#' @export
provider_estimates.pprof_model <- function(model) model[["provider_effects"]]

#' @export
provider_estimates.default <- function(model) contract_not_model(model)

#' @rdname model_contract
#' @export
provider_index <- function(model) UseMethod("provider_index")

#' @export
provider_index.pprof_model <- function(model) model[["provider_index"]]

#' @export
provider_index.default <- function(model) contract_not_model(model)

#' @rdname model_contract
#' @export
linear_predictor <- function(model) UseMethod("linear_predictor")

#' @export
linear_predictor.pprof_model <- function(model) model[["linear_predictor"]]

#' @export
linear_predictor.default <- function(model) contract_not_model(model)

#' @rdname model_contract
#' @export
observed_outcome <- function(model) UseMethod("observed_outcome")

#' @export
observed_outcome.pprof_model <- function(model) model[["response"]]

#' @export
observed_outcome.default <- function(model) contract_not_model(model)

#' @rdname model_contract
#' @export
inference_capabilities <- function(model) UseMethod("inference_capabilities")

#' @export
inference_capabilities.pprof_model <- function(model) character()

#' @export
inference_capabilities.default <- function(model) contract_not_model(model)

#' @rdname model_contract
#' @export
expected_outcome <- function(model, effect, ...) UseMethod("expected_outcome")

#' @export
expected_outcome.pprof_model <- function(model, effect, ...) abort_unsupported_inference(model, "expected_outcome()")

#' @export
expected_outcome.default <- function(model, effect, ...) contract_not_model(model)

#' @rdname model_contract
#' @export
null_effect <- function(model, null, ...) UseMethod("null_effect")

#' @export
null_effect.pprof_model <- function(model, null, ...) abort_unsupported_inference(model, "null_effect()")

#' @export
null_effect.default <- function(model, null, ...) contract_not_model(model)

#' @rdname model_contract
#' @export
profile_spec <- function(model) UseMethod("profile_spec")

#' @export
profile_spec.pprof_model <- function(model) abort_unsupported_inference(model, "profile_spec()")

#' @export
profile_spec.default <- function(model) contract_not_model(model)

#' @rdname model_contract
#' @export
provider_estimate_se <- function(model) UseMethod("provider_estimate_se")

#' @export
provider_estimate_se.pprof_model <- function(model) abort_unsupported_inference(model, "provider_estimate_se()")

#' @export
provider_estimate_se.default <- function(model) contract_not_model(model)

#' @rdname model_contract
#' @export
provider_test <- function(model, test, ...) UseMethod("provider_test")

#' @export
provider_test.pprof_model <- function(model, test, ...) abort_unsupported_inference(model, "provider_test()")

#' @export
provider_test.default <- function(model, test, ...) contract_not_model(model)

#' @rdname model_contract
#' @export
refit_without <- function(model, covariates, data, ...) UseMethod("refit_without")

#' @export
refit_without.pprof_model <- function(model, covariates, data, ...) {
  abort_unsupported_inference(model, "refit_without()")
}

#' @export
refit_without.default <- function(model, covariates, data, ...) contract_not_model(model)
