# Classed conditions (NAMING.md §6).
#
# Every error raised by the rewrite inherits from `pprof_error` and every warning from
# `pprof_warning`, so that callers and tests can match condition classes instead of message
# text (brief §5.5). The conditions are base R condition objects; extra named arguments are
# stored as fields of the condition.

abort_pprof <- function(class, message, ..., call = NULL) {
  stop(errorCondition(message, ..., class = c(class, "pprof_error"), call = call))
}

warn_pprof <- function(class, message, ..., call = NULL) {
  warning(warningCondition(message, ..., class = c(class, "pprof_warning"), call = call))
}

# An argument fails validation at the API boundary.
abort_invalid_input <- function(message, ..., call = NULL) {
  abort_pprof("pprof_error_invalid_input", message, ..., call = call)
}

# The data cannot support the requested model.
abort_data <- function(message, ..., call = NULL) {
  abort_pprof("pprof_error_data", message, ..., call = call)
}

# An engine fails in a way the reference also fails.
abort_convergence <- function(message, ..., call = NULL) {
  abort_pprof("pprof_error_convergence", message, ..., call = call)
}

# A model is asked for something it does not declare or implement: an inference capability
# missing from inference_capabilities(), or a contract generic without a method for its
# class. The condition carries the model class and what was requested.
abort_unsupported_inference <- function(model, requested, call = NULL) {
  model_class <- class(model)[1]
  abort_pprof(
    "pprof_error_unsupported_inference",
    sprintf("Models of class '%s' do not support '%s'.", model_class, requested),
    model_class = model_class, requested = requested, call = call
  )
}

# A method needs covariates that the model object does not keep, and `data` was not given.
abort_data_required <- function(message, ..., call = NULL) {
  abort_pprof("pprof_error_data_required", message, ..., call = call)
}

# The iteration limit was reached.
warn_not_converged <- function(message, ..., call = NULL) {
  warn_pprof("pprof_warning_not_converged", message, ..., call = call)
}

# Providers were excluded by min_provider_size.
warn_screening <- function(message, ..., call = NULL) {
  warn_pprof("pprof_warning_screening", message, ..., call = call)
}

# Deprecation warnings of the compatibility wrappers are given once per session and per
# `id` (DEC-013). The registry is an argument so that tests can use their own.
deprecation_registry <- new.env(parent = emptyenv())

warn_deprecated <- function(id, message, registry = deprecation_registry) {
  if (isTRUE(registry[[id]])) {
    return(invisible(FALSE))
  }
  assign(id, TRUE, envir = registry)
  warn_pprof("pprof_deprecated", message, id = id)
  invisible(TRUE)
}
