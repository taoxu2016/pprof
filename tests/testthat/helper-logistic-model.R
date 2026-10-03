# fit_logistic_fe() on the reference's logis_fe() fixture cases (Phase 3).
#
# The data, formula, and provider come from the data-layer translation of each case
# (helper-reference-data.R); the settings are the case's, translated to NAMING.md §4. The
# compatibility wrapper translates the same way; these helpers let the tests check the new
# API against the fixtures directly.

model_case_arguments <- function(case, datasets) {
  translation <- reference_data_translation(case, datasets)
  args <- reference_resolve_args(case$args, datasets, list())
  setting <- function(name, default) if (is.null(args[[name]])) default else args[[name]]
  list(
    formula = translation$call$formula, data = translation$data, provider = translation$provider,
    method = tolower(setting("method", "SerBIN")), max_iter = setting("max.iter", 10000), tol = setting("tol", 1e-5),
    stop_rule = engine_stop_rules[[setting("stop", "or")]], backtrack = setting("backtrack", TRUE),
    effect_bound = setting("bound", 10), min_provider_size = setting("cutoff", 10), threads = setting("threads", 1)
  )
}

# The fit for a fixture case, with the warnings it raises (screening, convergence, rank)
# collected rather than raised.
model_case_fit <- function(id, set = "core") {
  fixture <- reference_fixture(id, set)
  args <- model_case_arguments(fixture$case, reference_datasets_for(fixture$case, set))
  warnings <- character()
  fit <- withCallingHandlers(do.call(fit_logistic_fe, args), warning = function(w) {
    warnings <<- c(warnings, class(w)[1])
    invokeRestart("muffleWarning")
  })
  list(fit = fit, warnings = warnings, fixture = fixture)
}

# A model field in the shape logis_fe() returned it: an n x 1 matrix with row names 1..n,
# processed as the fixtures store it.
model_reference_column <- function(values, column, set = "core") {
  x <- matrix(values, ncol = 1L, dimnames = list(seq_along(values), column))
  reference_fixture_value(x, reference_manifest(set)$max_full_length)
}

expect_reference_value <- function(actual, expected, tier, label) {
  diffs <- reference_compare(actual, expected, reference_tolerance(tier))
  testthat::expect(is.null(diffs), sprintf("%s differs from the reference: %s", label,
                                           paste(sprintf("%s [%s] %s", diffs$path, diffs$kind, diffs$detail),
                                                 collapse = "; ")))
}
