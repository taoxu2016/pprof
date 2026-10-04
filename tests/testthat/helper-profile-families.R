# The profiling and covariate functions on the reference's method fixtures of linear FE, RE,
# and CRE fits (Phase 5).
#
# The test(), SM_output(), confint(), summary(), and plot() cases on linear_fe(),
# linear_re(), logis_re(), linear_cre(), and logis_cre() fits, translated to the new API: the
# parent fit through model_new_fit() (the new fit function on the fixture's data,
# helper-model-cases.R), the settings to NAMING.md §4. The same translation runs the new API
# beside the old methods in the live comparison (test-profile-families-legacy.R).

family_reference_funs <- c("linear_fe", "linear_re", "logis_re", "linear_cre", "logis_cre")
family_method_funs <- c("test", "SM_output", "confint", "summary", "plot")
family_case_cache <- new.env(parent = emptyenv())

# The reference function of a case's parent fit.
family_parent_fun <- function(case) {
  reference_fixture(profile_case_parent_id(case))$case$fun
}

# Method cases on the five families whose reference call returned a value.
family_case_ids <- function() {
  ids <- reference_case_ids(family_method_funs)
  ids[vapply(ids, function(id) {
    fixture <- reference_fixture(id)
    identical(fixture$result$outcome, "value") && family_parent_fun(fixture$case) %in% family_reference_funs
  }, logical(1))]
}

# The new fit of a fixture case's parent, cached for the test run.
family_case_parent <- function(case) {
  parent <- profile_case_parent_id(case)
  if (is.null(family_case_cache[[parent]])) family_case_cache[[parent]] <- model_new_fit(parent)$fit
  family_case_cache[[parent]]
}

# The settings of a method case in the vocabulary of the new API. Providers are selected as
# the reference selects them, dropping IDs the fit does not have (without a fit, none is
# selected). The reference's summaries of RE and CRE fits name the intercept "(intercept)"
# in `parm` (D-44).
family_case_settings <- function(case, fit, parent_fun) {
  args <- case$args
  setting <- function(name, default) if (is.null(args[[name]])) default else args[[name]]
  null <- args[["null"]]
  parm <- args[["parm"]]
  logistic <- parent_fun %in% c("logis_re", "logis_cre")
  # Names select the coefficients the fit has, in the fit's order, dropping others, as the
  # reference's summaries select them (R/summary.linear_fe.R:84-92).
  coefficient_parm <- if (is.character(parm) && !is.null(fit)) {
    terms <- names(stats::coef(fit))
    terms[terms %in% sub("^\\(intercept\\)$", "(Intercept)", parm)]
  } else {
    parm
  }
  list(
    null = if (is.numeric(null)) null[1] else null,
    coefficient_null = setting("null", 0),
    level = setting("level", 0.95),
    alternative = setting("alternative", "two.sided"),
    providers = if (!is.null(parm) && !is.null(fit)) {
      intersect(as.character(parm), provider_table(fit)$provider_id)
    },
    coefficient_parm = coefficient_parm,
    standardization = setting("stdz", "indirect"),
    measure = if (logistic) intersect(c("ratio", "rate"), setting("measure", c("rate", "ratio"))) else "difference",
    option = setting("option", "SM"),
    alpha = setting("alpha", 0.05)
  )
}

# Runs a case's computation through the new API on `fit`.
family_case_run <- function(case, fit, parent_fun) {
  s <- family_case_settings(case, fit, parent_fun)
  suppressWarnings(switch(case$fun,
    test = test_providers(fit, null = s$null, level = s$level, alternative = s$alternative, providers = s$providers),
    SM_output = standardize_providers(fit, s$standardization, s$measure, null = s$null, providers = s$providers),
    confint = if (s$option %in% c("gamma", "alpha")) {
      provider_effects(fit, interval = "wald", level = s$level, providers = s$providers)
    } else {
      standardize_providers(fit, s$standardization, s$measure, null = s$null, interval = "wald", level = s$level,
                            alternative = s$alternative, providers = s$providers)
    },
    # Every coefficient, whose p-values the reference formats together before it selects
    # rows, and the selection.
    summary = list(all = test_coefficients(fit, "wald", level = s$level, null = s$coefficient_null),
                   selected = test_coefficients(fit, "wald", parm = s$coefficient_parm, level = s$level,
                                                null = s$coefficient_null)),
    plot = funnel_limits(fit, level = 1 - s$alpha, null = s$null)
  ))
}

# Compares the new API's result of a case with the reference's value (a fixture's value, or
# the old method's value processed as fixtures are) at `tier`.
expect_family_case <- function(case, result, expected, tier, parent_fun) {
  settings <- family_case_settings(case, NULL, parent_fun)
  switch(case$fun,
    test = expect_profile_tests(result, expected, tier),
    SM_output = expect_family_measures(result, expected, tier),
    confint = if (settings$option %in% c("gamma", "alpha")) {
      expect_family_effects(result, expected, tier)
    } else {
      expect_family_measure_intervals(result, expected, tier)
    },
    summary = expect_family_summary(result, expected, tier),
    plot = expect_profile_funnel(result, expected, settings$alpha, tier)
  )
}

# The name of a measure in the reference's outputs: "difference" for linear families.
family_measure_parts <- function(name) {
  parts <- strsplit(name, "[._]")[[1]]
  parts <- parts[parts %in% c("indirect", "direct", "ratio", "rate", "difference")]
  if (length(parts) == 1L) parts <- c(parts, "difference")
  parts
}

# An SM_output() fixture: m x 1 matrices named like "indirect.ratio" or
# "indirect.difference", and the OE tables, whose first two columns are the numerator (or
# the reference total) and the expected outcome.
expect_family_measures <- function(result, expected, tier) {
  table <- result$table
  names <- intersect(c("indirect.ratio", "indirect.rate", "direct.ratio", "direct.rate", "indirect.difference",
                       "direct.difference"), names(expected))
  for (name in names) {
    parts <- family_measure_parts(name)
    rows <- profile_measure_rows(table, parts[1], parts[2])
    testthat::expect_identical(rows$provider_id, rownames(expected[[name]]))
    expect_reference_value(rows$estimate, unname(expected[[name]][, 1]), tier, name)
  }
  for (method in c("indirect", "direct")) {
    oe <- expected$OE[[paste0("OE_", method)]]
    if (is.null(oe)) next
    rows <- profile_measure_rows(table, method, result$measure[1])
    expect_reference_value(rows$observed, as.double(oe[[1]]), tier, paste(method, "numerator or total"))
    expect_reference_value(rows$expected, oe[[2]], tier, paste(method, "expected"))
  }
}

# A confint(option = "gamma" or "alpha") fixture: the estimate and the two limits, with
# provider IDs as row names.
expect_family_effects <- function(result, expected, tier) {
  table <- result$table
  testthat::expect_identical(table$provider_id, rownames(expected))
  expect_reference_value(table$estimate, expected[[1]], tier, "estimate")
  expect_reference_value(table$lower, expected[[2]], tier, "lower limit")
  expect_reference_value(table$upper, expected[[3]], tier, "upper limit")
}

# A confint(option = "SM") fixture: tables named like "CI.indirect" (linear) or
# "CI.indirect_ratio" (logistic) with the estimate and the two limits, and the population
# rate as an attribute of rate tables.
expect_family_measure_intervals <- function(result, expected, tier) {
  table <- result$table
  for (name in names(expected)) {
    parts <- family_measure_parts(substring(name, 4L))
    rows <- profile_measure_rows(table, parts[1], parts[2])
    reference <- expected[[name]]
    testthat::expect_identical(rows$provider_id, rownames(reference))
    expect_reference_value(rows$estimate, reference[[1]], tier, paste(name, "estimate"))
    expect_reference_value(rows$lower, reference[[2]], tier, paste(name, "lower limit"))
    expect_reference_value(rows$upper, reference[[3]], tier, paste(name, "upper limit"))
    if (!is.null(attr(reference, "population_rate"))) {
      expect_reference_value(result$population_rate, attr(reference, "population_rate"), tier, "population rate")
    }
  }
}

# A summary() fixture: `Estimate`, `Std.Error`, `Stat`, `p value` (formatted as the
# reference formats it: every coefficient's together, then the rows selected), `CI.Lower`,
# `CI.Upper`, with the coefficient names as row names.
expect_family_summary <- function(result, expected, tier) {
  formatted <- stats::setNames(format.pval(result$all$table$p_value, digits = 7, eps = 1e-10), result$all$table$term)
  table <- result$selected$table
  testthat::expect_identical(table$term, rownames(expected))
  expect_reference_value(table$estimate, expected$Estimate, tier, "estimate")
  expect_reference_value(table$std_error, expected$Std.Error, tier, "standard error")
  expect_reference_value(table$statistic, expected$Stat, tier, "statistic")
  testthat::expect_identical(unname(formatted[table$term]), expected[["p value"]])
  expect_reference_value(table$lower, expected$CI.Lower, tier, "lower limit")
  expect_reference_value(table$upper, expected$CI.Upper, tier, "upper limit")
}
