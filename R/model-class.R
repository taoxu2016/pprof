# The shared model object (ARCHITECTURE §D.1).

# Fields that new_pprof_model() fills for every model; subclasses add their own through `...`.
model_shared_fields <- c(
  "call", "formula", "terms", "spec", "providers", "coefficients", "vcov", "provider_effects",
  "provider_effect_variance", "response", "linear_predictor", "provider_index", "row_index",
  "convergence", "n_obs", "n_providers", "n_excluded_providers", "n_excluded_obs",
  "package_version", "data"
)

#' Build a provider-profiling model object
#'
#' The constructor that every fit function uses to build its object (ARCHITECTURE §E.2). It
#' takes the [data_prepare()] output and the estimates, fills the fields that all models share,
#' adds the family's own fields from `...`, and checks the result with `validate_pprof_model()`.
#' Objects are compact: they keep per-observation vectors (response, linear predictor,
#' provider index, input row) but not the design matrix, unless `keep_data = TRUE`.
#'
#' @param data A `pprof_data` object from [data_prepare()].
#' @param coefficients Covariate coefficients, a named numeric vector (empty for models
#'   without covariates).
#' @param vcov The covariance matrix of `coefficients`, with matching row and column names.
#' @param provider_effects Effects of the included providers, named by provider ID, in
#'   provider order.
#' @param linear_predictor The covariate linear predictor of each observation, in the order of
#'   `data`.
#' @param spec The model specification: a list with the element `family` (a string) and the
#'   settings of the fit.
#' @param ... Further named fields of the model class.
#' @param provider_effect_variance The variance of each provider effect, named like
#'   `provider_effects`, or `NULL`.
#' @param convergence `NULL`, or a list of convergence diagnostics (iterations, whether the fit
#'   converged, the final criterion, the stopping rule, the tolerance, the iteration limit).
#' @param call The call of the fit function.
#' @param keep_data Whether to keep `data`, including the design matrix, in the object.
#' @param class The model's classes, most specific first; `"pprof_model"` is appended.
#'
#' @return An object of class `c(class, "pprof_model")`.
#'
#' @keywords internal
#' @export
new_pprof_model <- function(data, coefficients, vcov, provider_effects, linear_predictor, spec, ...,
                            provider_effect_variance = NULL, convergence = NULL, call = NULL,
                            keep_data = FALSE, class = character()) {
  if (!inherits(data, "pprof_data")) {
    abort_invalid_input("`data` must be a `pprof_data` object from data_prepare().", arg = "data")
  }
  check_flag(keep_data, "keep_data")
  extra <- list(...)
  if (length(extra) > 0L && (is.null(names(extra)) || any(!nzchar(names(extra))))) {
    abort_invalid_input("Further fields of a model must be named.", arg = "...")
  }
  clash <- intersect(names(extra), model_shared_fields)
  if (length(clash) > 0L) {
    abort_invalid_input(sprintf("Fields %s are filled by new_pprof_model() and cannot be given in `...`.",
                                paste(clash, collapse = ", ")), arg = "...")
  }
  providers <- data$providers
  shared <- list(
    call = call, formula = data$formula, terms = data$terms, spec = spec, providers = providers,
    coefficients = coefficients, vcov = vcov, provider_effects = provider_effects,
    provider_effect_variance = provider_effect_variance, response = data$response,
    linear_predictor = linear_predictor, provider_index = data$provider_index,
    row_index = data$row_index, convergence = convergence, n_obs = length(data$response),
    n_providers = sum(providers$included), n_excluded_providers = sum(!providers$included),
    n_excluded_obs = data$n_excluded_obs, package_version = utils::packageVersion("pprof"),
    data = if (keep_data) data else NULL
  )
  validate_pprof_model(structure(c(shared, extra), class = c(class, "pprof_model")))
}

#' @rdname new_pprof_model
#' @param x An object to check.
#' @export
validate_pprof_model <- function(x) {
  fail <- function(what) abort_invalid_input(sprintf("Invalid `pprof_model` object: %s.", what), arg = "x")
  classes <- class(x)
  if (!is.list(x) || classes[length(classes)] != "pprof_model") fail("its last class must be `pprof_model`")
  missing <- setdiff(model_shared_fields, names(x))
  missing <- setdiff(missing, c("call", "provider_effect_variance", "convergence", "data"))
  if (length(missing) > 0L) fail(sprintf("missing fields %s", paste(missing, collapse = ", ")))
  if (!is.list(x$spec) || !is.character(x$spec$family) || length(x$spec$family) != 1L) {
    fail("`spec` must be a list with a single string `family`")
  }
  providers <- x$providers
  if (!is.data.frame(providers) || !all(c("provider_id", "n_obs", "included") %in% names(providers))) {
    fail("`providers` must be a provider table with columns provider_id, n_obs, and included")
  }
  included_ids <- providers$provider_id[providers$included]
  if (!is.numeric(x$provider_effects) || !identical(names(x$provider_effects), included_ids)) {
    fail("`provider_effects` must be numeric and named by the included providers, in provider order")
  }
  if (!is.null(x$provider_effect_variance) &&
        (!is.numeric(x$provider_effect_variance) || !identical(names(x$provider_effect_variance), included_ids))) {
    fail("`provider_effect_variance` must be numeric and named like `provider_effects`")
  }
  coefficients <- x$coefficients
  p <- length(coefficients)
  if (!is.numeric(coefficients) || !is.null(dim(coefficients)) ||
        (p > 0L && (is.null(names(coefficients)) || anyDuplicated(names(coefficients)) > 0L))) {
    fail("`coefficients` must be a numeric vector with distinct names")
  }
  if (!is.matrix(x$vcov) || !is.numeric(x$vcov) || !identical(dim(x$vcov), c(p, p)) ||
        (p > 0L && !identical(dimnames(x$vcov), list(names(coefficients), names(coefficients))))) {
    fail("`vcov` must be a square numeric matrix named like `coefficients`")
  }
  n <- x$n_obs
  if (length(x$response) != n || length(x$linear_predictor) != n || !is.numeric(x$linear_predictor)) {
    fail("`response` and `linear_predictor` must have one value per observation")
  }
  index <- x$provider_index
  if (!is.integer(index) || length(index) != n || anyNA(index) || any(index < 1L | index > nrow(providers)) ||
        !all(providers$included[index])) {
    fail("`provider_index` must give an included provider for every observation")
  }
  if (!is.integer(x$row_index) || length(x$row_index) != n) {
    fail("`row_index` must give the input row of every observation")
  }
  if (x$n_providers != sum(providers$included) || x$n_excluded_providers != sum(!providers$included)) {
    fail("the provider counts do not match `providers`")
  }
  if (!is.null(x$convergence) && !is.list(x$convergence)) fail("`convergence` must be NULL or a list")
  if (!inherits(x$package_version, "package_version")) fail("`package_version` must be a package version")
  if (!is.null(x$data) && !inherits(x$data, "pprof_data")) fail("`data` must be NULL or a `pprof_data` object")
  invisible(x)
}
