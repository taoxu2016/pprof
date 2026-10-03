# The family specification as the profiling layer reads it (ARCHITECTURE §B.4), and the
# helpers that every profiling function shares: the null value, the providers to report,
# and their observations.
#
# The profiling layer is written once against the model contract (§E.1). Where model
# families differ, it reads the difference from profile_spec() instead of branching on the
# class: the null options and default (K-60), the numerator of indirect measures, the
# measures, the mean and variance functions, the direct expectation, the funnel, and
# whether Wald inference warns about providers with no events or only events.

profile_spec_fields <- c("family", "effect", "null_default", "null_options", "indirect_numerator", "measures")

# The family specification of a model, checked for the fields every profiling function
# reads. Fields that only some functions need are checked where they are used.
profile_family <- function(model) {
  spec <- profile_spec(model)
  missing <- if (is.list(spec)) setdiff(profile_spec_fields, names(spec)) else profile_spec_fields
  if (length(missing) > 0L) {
    abort_invalid_input(sprintf("profile_spec() for class '%s' lacks the fields %s.", class(model)[1],
                                paste(missing, collapse = ", ")), arg = "model")
  }
  spec
}

# A field of the family specification that a computation needs.
profile_spec_field <- function(model, spec, field) {
  value <- spec[[field]]
  if (is.null(value)) {
    abort_invalid_input(sprintf("profile_spec() for class '%s' lacks the field %s.", class(model)[1], field),
                        arg = "model")
  }
  value
}

profile_check_model <- function(model) {
  if (!inherits(model, "pprof_model")) abort_invalid_input("`model` must be a pprof model object.", arg = "model")
  invisible(model)
}

# The null value (K-60): `null` is NULL for the family's default, one of the family's named
# options, or a single finite number, which an integer gives as the equal double (D-14).
profile_null_value <- function(model, spec, null) {
  if (is.null(null)) null <- spec$null_default
  named <- is.character(null) && length(null) == 1L && !is.na(null) && null %in% spec$null_options
  number <- is.numeric(null) && length(null) == 1L && is.finite(null)
  if (!named && !number) {
    options <- c(if (length(spec$null_options)) paste0('"', spec$null_options, '"'), "a single finite number")
    abort_invalid_input(sprintf("`null` must be %s.", paste(options, collapse = " or ")), arg = "null")
  }
  value <- null_effect(model, if (number) as.double(null) else null)
  if (!(is.numeric(value) && length(value) == 1L && is.finite(value))) {
    abort_invalid_input(sprintf("null_effect() for class '%s' must return a single finite number.", class(model)[1]),
                        arg = "model")
  }
  as.double(value)
}

# The rows of the provider table to report, in provider order: every included provider, or
# those whose IDs are in `providers`, compared as character (D-27).
profile_provider_rows <- function(model, providers) {
  table <- provider_table(model)
  included <- which(table$included)
  if (is.null(providers)) return(included)
  if (!is.atomic(providers) || length(providers) == 0L || anyNA(providers)) {
    abort_invalid_input("`providers` must be a vector of provider IDs.", arg = "providers")
  }
  ids <- as.character(providers)
  unknown <- setdiff(ids, table$provider_id[included])
  if (length(unknown) > 0L) {
    abort_invalid_input(sprintf("`providers` names providers that the model does not include: %s.",
                                paste(unknown, collapse = ", ")), arg = "providers")
  }
  included[table$provider_id[included] %in% ids]
}

# The positions of provider-table rows among the included providers, which index the
# contract's per-provider vectors (provider_estimates(), provider_estimate_se()).
profile_positions <- function(model, rows) {
  match(rows, which(provider_table(model)$included))
}

# The observations of each provider in `rows`, in their stored order.
profile_observations <- function(model, rows) {
  index <- provider_index(model)
  unname(split(seq_along(index), data_provider_factor(index, rows)))
}

# Whether each provider in `rows` has events and non-events ("finite"), no events, or only
# events; providers of the last two kinds get one-sided intervals (K-90, K-91).
profile_provider_kinds <- function(model, rows) {
  table <- provider_table(model)
  ifelse(table$no_events[rows], "no_events", ifelse(table$all_events[rows], "all_events", "finite"))
}

profile_has_capability <- function(model, capability) {
  capability %in% inference_capabilities(model)
}

# Families whose specification sets wald_caution warn when Wald inference covers providers
# with no events or only events, whose estimates sit at the effect bound. The reference
# warns on every Wald test and interval of logistic fixed effects (K-67).
profile_wald_caution <- function(model, spec, rows) {
  if (!isTRUE(spec$wald_caution)) return(invisible(NULL))
  table <- provider_table(model)
  extreme <- sum(table$no_events[rows] | table$all_events[rows])
  if (extreme > 0L) {
    warn_wald_unreliable(sprintf(paste(
      "Wald tests and intervals are unreliable for providers with no events or only events (%d of the %d",
      "providers reported); the exact or score test is recommended."
    ), extreme, length(rows)))
  }
  invisible(NULL)
}
