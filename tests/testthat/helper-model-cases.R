# The new fit functions on the reference's fit fixture cases (Phase 4): the cases of
# linear_fe(), logis_firth(), linear_re(), logis_re(), linear_cre(), and logis_cre(),
# translated to fit_linear_fe(), fit_logistic_firth(), and the random-effect fits through
# the data-layer translation of each case (helper-reference-data.R). The compatibility
# wrappers translate the same way; these helpers let the tests check the new API against the
# fixtures directly.

model_new_fit_functions <- c(
  linear_fe = "fit_linear_fe", logis_firth = "fit_logistic_firth", linear_re = "fit_linear_re",
  logis_re = "fit_logistic_re", linear_cre = "fit_linear_cre", logis_cre = "fit_logistic_cre"
)

# Arguments of the reference's fit functions that the data translation consumes; the other
# arguments of a random-effect fit (REML, control) go to lme4 through `...`.
model_reference_data_arguments <- c("formula", "data", "Y.char", "Z.char", "ProvID.char", "Y", "Z", "ProvID", "wb.char",
                                    "other.char")

model_new_arguments <- function(case, datasets) {
  translation <- reference_data_translation(case, datasets)
  args <- reference_resolve_args(case$args, datasets, list())
  setting <- function(name, default) if (is.null(args[[name]])) default else args[[name]]
  out <- list(formula = translation$call$formula, data = translation$data, provider = translation$provider)
  if (identical(case$fun, "linear_fe")) {
    out$provider_variance <- if (setting("option.gamma.var", "simplified") %in% c("full", "f")) "full" else "simplified"
  } else if (identical(case$fun, "logis_firth")) {
    out <- c(out, list(max_iter = setting("max.iter", 1000), tol = setting("tol", 1e-5),
                       effect_bound = setting("bound", 10), min_provider_size = setting("cutoff", 10),
                       threads = setting("threads", 1)))
  } else {
    if (case$fun %in% c("linear_cre", "logis_cre")) out$within_between <- args[["wb.char"]]
    out <- c(out, args[setdiff(names(args), model_reference_data_arguments)])
  }
  out
}

# Fit cases of the given reference functions whose reference call returned a value.
model_new_case_ids <- function(funs, set = "core") {
  manifest <- reference_manifest(set)
  if (is.null(manifest)) return(character())
  keep <- vapply(manifest$cases, function(entry) {
    entry[["fun"]] %in% funs && identical(entry[["outcome"]], "value")
  }, logical(1))
  vapply(manifest$cases[keep], `[[`, character(1), "id")
}

# The new fit of a fixture case, in the collation of the fixture generation, with the
# warnings it raises collected rather than raised.
model_new_fit <- function(id, set = "core", keep_data = FALSE) {
  fixture <- reference_fixture(id, set)
  args <- model_new_arguments(fixture$case, reference_datasets_for(fixture$case, set))
  warnings <- character()
  fit <- withr::with_collate("C", withCallingHandlers(
    do.call(model_new_fit_functions[[fixture$case$fun]], c(args, list(keep_data = keep_data))),
    warning = function(w) {
      warnings <<- c(warnings, class(w)[1])
      invokeRestart("muffleWarning")
    }
  ))
  list(fit = fit, warnings = warnings, fixture = fixture)
}

# An n x 1 matrix in the shape the reference returned it, processed as the fixtures store
# it: with row names 1..n unless `row_names` is FALSE.
model_reference_matrix <- function(values, column, set = "core", row_names = TRUE) {
  rows <- if (row_names) seq_along(values) else NULL
  x <- matrix(values, ncol = 1L, dimnames = list(rows, column))
  reference_fixture_value(x, reference_manifest(set)$max_full_length)
}

# The standard errors of the provider effects that the reference's test() reported for the
# fit `fit_id`, from its two-sided test fixture, named by provider.
model_reference_std_errors <- function(fit_id, set = "core") {
  manifest <- reference_manifest(set)
  for (entry in manifest$cases) {
    if (!identical(entry[["fun"]], "test") || !identical(entry[["outcome"]], "value")) next
    case <- reference_fixture(entry[["id"]], set)$case
    parent <- case$args$fit
    alternative <- case$args$alternative
    plain <- setdiff(names(case$args), c("fit", "alternative"))
    if (inherits(parent, "pprof_ref_fit") && identical(parent$case_id, fit_id) && length(plain) == 0L &&
          (is.null(alternative) || identical(alternative, "two.sided"))) {
      table <- reference_fixture(entry[["id"]], set)$result$value
      return(stats::setNames(table[["Std.Error"]], rownames(table)))
    }
  }
  NULL
}
