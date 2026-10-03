# The profiling functions on the reference's method fixtures (Phase 3).
#
# The test(), SM_output(), confint(), and plot() cases on logis_fe() fits, translated to the
# new API: the parent fit through model_case_fit() (under the C collation, as the case
# runner fits it), the settings to NAMING.md §4. The compatibility wrappers translate the
# same way; these helpers check the new API directly.

profile_case_cache <- new.env(parent = emptyenv())

# The parent fit of a method case, with the data it was fit to.
profile_case_parent <- function(case) {
  parent <- Filter(function(a) inherits(a, "pprof_ref_fit"), case$args)[[1]]$case_id
  if (is.null(profile_case_cache[[parent]])) {
    withr::with_collate("C", {
      fixture <- reference_fixture(parent)
      args <- model_case_arguments(fixture$case, reference_datasets_for(fixture$case, "core"))
      fit <- suppressWarnings(do.call(fit_logistic_fe, args))
    })
    profile_case_cache[[parent]] <- list(id = parent, fit = fit, data = args$data)
  }
  profile_case_cache[[parent]]
}

profile_case_parent_id <- function(case) {
  Filter(function(a) inherits(a, "pprof_ref_fit"), case$args)[[1]]$case_id
}

# The settings of a method case in the vocabulary of the new API. The reference selects
# providers silently, dropping IDs the fit does not have, and the compatibility wrapper
# does the same before calling the new API, which rejects unknown IDs; so do these helpers.
profile_case_settings <- function(case, fit) {
  args <- case$args
  setting <- function(name, default) if (is.null(args[[name]])) default else args[[name]]
  test <- setting("test", if (identical(case$fun, "test")) "exact.poisbinom" else "exact")
  null <- args[["null"]]
  parm <- args[["parm"]]
  list(
    test = switch(test, exact.poisbinom = "exact", exact.bootstrap = "bootstrap", test),
    score_type = if (isFALSE(args[["score_modified"]])) "standard" else "modified",
    n_resamples = setting("n", 10000),
    null = if (is.numeric(null)) null[1] else null,
    level = setting("level", 0.95),
    alternative = setting("alternative", "two.sided"),
    providers = if (is.null(parm)) NULL else intersect(as.character(parm), provider_table(fit)$provider_id),
    standardization = setting("stdz", "indirect"),
    measure = intersect(c("ratio", "rate"), setting("measure", c("rate", "ratio"))),
    option = setting("option", "SM"),
    alpha = setting("alpha", 0.05)
  )
}

# Runs a case's computation through the new API, with the case's seed.
profile_case_run <- function(case) {
  parent <- profile_case_parent(case)
  s <- profile_case_settings(case, parent$fit)
  run <- function() {
    switch(case$fun,
      test = test_providers(parent$fit, test = s$test, null = s$null, level = s$level, alternative = s$alternative,
                            providers = s$providers, score_type = s$score_type, n_resamples = s$n_resamples,
                            data = parent$data),
      SM_output = standardize_providers(parent$fit, s$standardization, s$measure, null = s$null,
                                        providers = s$providers),
      confint = if (identical(s$option, "gamma")) {
        provider_effects(parent$fit, interval = s$test, level = s$level, providers = s$providers)
      } else {
        standardize_providers(parent$fit, s$standardization, s$measure, null = s$null, interval = s$test,
                              level = s$level, alternative = s$alternative, providers = s$providers)
      },
      plot = funnel_limits(parent$fit, level = 1 - s$alpha, null = s$null)
    )
  }
  if (is.null(case$seed)) return(run())
  withr::with_seed(case$seed, run(), .rng_kind = "Mersenne-Twister", .rng_normal_kind = "Inversion",
                   .rng_sample_kind = "Rejection")
}

# Runs a case and collects the classes of the warnings it raises.
profile_case_result <- function(case) {
  warnings <- character()
  result <- withCallingHandlers(profile_case_run(case), warning = function(w) {
    warnings <<- c(warnings, class(w)[1])
    invokeRestart("muffleWarning")
  })
  list(value = result, warnings = warnings)
}

expect_profile_flags <- function(actual, expected, label) {
  testthat::expect(identical(actual, as.integer(as.character(expected))),
                   sprintf("%s: flags differ from the reference", label))
}

# A test() fixture: a data frame with provider IDs as row names, `flag` (a factor), `p value`,
# `stat`, and for the Wald test `Std.Error`, with the provider sizes as an attribute.
expect_profile_tests <- function(result, expected, tier) {
  table <- result$table
  testthat::expect_identical(table$provider_id, rownames(expected))
  testthat::expect_identical(table$n_obs, unname(attr(expected, "provider size")))
  expect_profile_flags(table$flag, expected$flag, "flag")
  expect_reference_value(table$p_value, expected[["p value"]], tier, "p-value")
  expect_reference_value(table$statistic, expected$stat, tier, "statistic")
  if (!is.null(expected$Std.Error)) expect_reference_value(table$std_error, expected$Std.Error, tier, "standard error")
}

profile_measure_rows <- function(table, standardization, measure) {
  table[table$standardization == standardization & table$measure == measure, , drop = FALSE]
}

# An SM_output() fixture: m x 1 matrices named like "indirect.ratio" and the OE tables.
expect_profile_measures <- function(result, expected, tier) {
  table <- result$table
  for (name in intersect(c("indirect.ratio", "indirect.rate", "direct.ratio", "direct.rate"), names(expected))) {
    parts <- strsplit(name, ".", fixed = TRUE)[[1]]
    rows <- profile_measure_rows(table, parts[1], parts[2])
    testthat::expect_identical(rows$provider_id, rownames(expected[[name]]))
    expect_reference_value(rows$estimate, unname(expected[[name]][, 1]), tier, name)
  }
  if (!is.null(expected$OE$OE_indirect)) {
    rows <- profile_measure_rows(table, "indirect", result$measure[1])
    expect_reference_value(rows$observed, expected$OE$OE_indirect$Obs_provider, tier, "indirect observed")
    expect_reference_value(rows$expected, expected$OE$OE_indirect$Exp.indirect_provider, tier, "indirect expected")
    expect_reference_value(rows$variance, expected$OE$OE_indirect$Var.indirect_provider, tier, "indirect variance")
  }
  if (!is.null(expected$OE$OE_direct)) {
    rows <- profile_measure_rows(table, "direct", result$measure[1])
    expect_reference_value(rows$observed, as.double(expected$OE$OE_direct$Obs_all), tier, "direct observed")
    expect_reference_value(rows$expected, expected$OE$OE_direct$Exp.direct_all, tier, "direct expected")
  }
}

# A confint(option = "gamma") fixture: `gamma`, `gamma.lower`, `gamma.upper`, with provider
# IDs as row names.
expect_profile_effects <- function(result, expected, tier) {
  table <- result$table
  testthat::expect_identical(table$provider_id, rownames(expected))
  expect_reference_value(table$estimate, expected$gamma, tier, "estimate")
  expect_reference_value(table$lower, expected$gamma.lower, tier, "lower limit")
  expect_reference_value(table$upper, expected$gamma.upper, tier, "upper limit")
}

# A confint(option = "SM") fixture: tables named like "CI.indirect_ratio" with the
# estimate and the two limits, and the population rate as an attribute of rate tables.
expect_profile_measure_intervals <- function(result, expected, tier) {
  table <- result$table
  for (name in names(expected)) {
    parts <- strsplit(substring(name, 4L), "_", fixed = TRUE)[[1]]
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

# A plot() fixture: the layers of the reference's funnel plot. The points (first layer,
# without the dummy rows for absent flag levels) are the providers in order of precision;
# the lines (second and third layers) give the limits at each provider's precision.
expect_profile_funnel <- function(result, expected, alpha, tier) {
  layers <- expected$layers
  points <- layers[[1]]$data
  points <- points[!is.na(points$precision), , drop = FALSE]
  providers <- result$providers[order(result$providers$precision), , drop = FALSE]
  expect_reference_value(providers$precision, points$precision, tier, "precision")
  expect_reference_value(providers$estimate, points$indicator, tier, "indicator")
  expect_reference_value(providers$expected, points$Exp, tier, "expected")
  expect_profile_flags(providers$flag, points$flag, "funnel flag")
  lines <- layers[[2]]$data
  for (value in alpha) {
    rows <- lines[as.character(lines$alpha) == as.character(value), , drop = FALSE]
    limits <- result$table[result$table$level == 1 - value, , drop = FALSE]
    at <- match(rows$precision, limits$precision)
    expect_reference_value(limits$lower[at], rows$lower, tier, paste("lower limit at alpha", value))
    expect_reference_value(limits$upper[at], rows$upper, tier, paste("upper limit at alpha", value))
  }
  expect_reference_value(result$target, layers[[4]]$data$yintercept, tier, "target")
}
