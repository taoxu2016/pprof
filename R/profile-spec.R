# The family specification as the profiling layer reads it (ARCHITECTURE §B.4), and the
# helpers that every profiling function shares: the null value, the providers to report,
# and their observations.
#
# The profiling layer is written once against the model contract (§E.1). Where model
# families differ, it reads the difference from profile_spec() instead of branching on the
# class: the null options and default (K-60), the numerator of indirect measures, the
# measures, the mean and variance functions, the direct expectation, the funnel, and
# whether Wald inference warns about providers with no events or only events. The fields
# added in Phase 5 (DEC-046) are optional: a family that omits one gets the behavior of
# logistic fixed effects, the first family profiled (Phase 3).

profile_spec_fields <- c("family", "effect", "null_default", "null_options", "indirect_numerator", "measures")

# The optional fields of the family specification and their defaults (DEC-046):
#   test_default        the provider test when `test` is NULL (DEC-047);
#   comparison          "ratio": indirect O / E and direct E / total; "difference":
#                       indirect (O - E) / n_i and direct (E - total) / n (K-83, K-84);
#   direct_reference    the total of direct standardization: "observed", the sum of the
#                       outcome, or "null_expected", the sum of the outcomes expected under
#                       the null (linear fixed effects, K-83);
#   direct_limits       how direct limits sum over the population: "mean_function", R's sum
#                       of the mean function (K-91), or "direct_expected", the family's
#                       direct expectation (the C++ routine of logistic RE and CRE, K-93);
#   one_sided_extremes  whether providers with no events or only events get one-sided
#                       measure limits (K-91);
#   wald                the distributions of the provider Wald tests (`test`) and intervals
#                       (`interval`), "normal" or "t", and the degrees of freedom `df` of t.
# The CoxPH phase (COXPH_DESIGN §D.3, DEC-092 as amended by DEC-108) adds two:
#   count_distribution  the null distribution of a provider's count: "poisson_binomial", the sum of
#                       its observations' Bernoulli outcomes (the exact and bootstrap tests of
#                       binary outcomes), or "poisson", a Poisson count with the provider's expected
#                       count as its mean, which selects the Poisson tests, the limits of indirect
#                       measures, and the funnel limits of R/inference-poisson.R (K-140 to K-142, K-149);
#   direct_by_provider  NULL, or a function of the model and rows of the provider table giving each
#                       provider's directly standardized expected outcome, for families without
#                       provider effects (the provider-stratified Cox model, K-138).
# The covariate rule `coefficient_wald` is read by the inference layer
# (infer_coefficient_rule()).
profile_spec_defaults <- list(
  test_default = "exact", comparison = "ratio", direct_reference = "observed", direct_limits = "mean_function",
  one_sided_extremes = TRUE, wald = list(test = "normal", interval = "normal", df = NULL),
  count_distribution = "poisson_binomial", direct_by_provider = NULL
)

# Whether a family's provider counts are Poisson with their expected counts as means (DEC-108).
profile_poisson <- function(spec) {
  identical(profile_spec_option(spec, "count_distribution"), "poisson")
}

# D-70, K-147: one warning that counts the reported providers of a Poisson family with no expected
# events, whose indirect ratios are then undefined (0 / 0) or infinite; pprof_py reports the same
# values without a warning. `expected` holds the expected counts of the providers in `rows`.
profile_warn_zero_expected <- function(model, spec, expected, rows) {
  if (!profile_poisson(spec)) return(invisible(NULL))
  zero <- which(expected == 0)
  if (length(zero) == 0L) return(invisible(NULL))
  ids <- provider_table(model)$provider_id[rows[zero]]
  warn_zero_expected(sprintf("%d provider(s) have no expected events (%s), so their indirect ratios are %s.",
                             length(ids), paste(utils::head(ids, 10L), collapse = ", "), "undefined or infinite"),
                     providers = ids)
  invisible(NULL)
}

# An optional field of the family specification, or its default.
profile_spec_option <- function(spec, field) {
  value <- spec[[field]]
  if (is.null(value)) profile_spec_defaults[[field]] else value
}

# A standardized measure on the family's comparison scale (K-80 to K-84): `value` over
# `reference`, or their difference per observation, of the provider (`n_obs`, indirect
# standardization) or of the population (`n`, direct standardization). For indirect
# standardization `value` is the provider's numerator and `reference` its expected outcome
# under the null; for direct standardization `value` is the outcome expected in the
# population with the provider's effect and `reference` the reference total.
profile_compare <- function(spec, standardization, value, reference, n_obs, n) {
  if (!identical(profile_spec_option(spec, "comparison"), "difference")) return(value / reference)
  if (identical(standardization, "indirect")) (value - reference) / n_obs else (value - reference) / n
}

# The precision of each provider in a funnel plot: a function of the expected count and
# its null variance (K-110), and of the provider's number of observations when the function
# takes `n_obs` (K-111).
profile_funnel_precision <- function(funnel, expected, variance, n_obs) {
  if ("n_obs" %in% names(formals(funnel$precision))) {
    funnel$precision(expected, variance, n_obs = n_obs)
  } else {
    funnel$precision(expected, variance)
  }
}

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
# with no events or only events, whose maximum likelihood estimates are infinite (their
# fitted effects move toward the effect bound with every iteration; D-50). The reference
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
