# Provider profiling of the provider-stratified Cox model (CoxPH Phase C3; COXPH_DESIGN §B.3, §D):
# test_providers(), standardize_providers(), funnel_limits(), and profile_providers() on
# fit_cox_stratified() fits, with the register entries C3 implements without fixtures (D-58, D-63,
# D-70, D-73, D-77, M-25, M-29, M-36, M-39, M-40, K-142, K-147, K-149) and the measures' part of the brief's
# metamorphic and edge-case tests (§6 E, F). test-inference-poisson.R tests the Poisson tests and
# limits, test-model-cox-measures.R the expected events, and test-cox-reference.R all of it against
# pprof_py's fixtures.
local_strict_mode()

cox_profile_fit <- function(d = cox_profile_data(), ...) {
  fit_cox_stratified(Surv(entry, time, status) ~ x + z + offset(o), d, "provider", weights = "w", ...)
}

# p10 has no expected events, so every profiling call warns once (D-70); most tests do not test that.
without_zero_warning <- function(expr) {
  withCallingHandlers(expr, pprof_warning_zero_expected = function(w) invokeRestart("muffleWarning"))
}

zero_warnings <- function(expr) {
  caught <- 0L
  withCallingHandlers(expr, pprof_warning_zero_expected = function(w) {
    caught <<- caught + 1L
    invokeRestart("muffleWarning")
  })
  caught
}

test_that("the model declares COXPH_DESIGN §D.1's capabilities, and the rest raise", {
  fit <- cox_profile_fit()
  expect_identical(inference_capabilities(fit), c("coef_wald", "provider_exact", "provider_midp", "interval_exact",
                                                  "interval_midp", "standardize_indirect", "standardize_direct",
                                                  "funnel"))
  expect_null(provider_estimates(fit))
  unsupported <- function(expr) expect_error(expr, class = "pprof_error_unsupported_inference")
  unsupported(provider_effects(fit))
  unsupported(test_providers(fit, test = "score"))
  unsupported(test_providers(fit, test = "wald"))
  unsupported(test_providers(fit, test = "bootstrap"))
  unsupported(standardize_providers(fit, interval = "wald"))
  unsupported(standardize_providers(fit, interval = "score"))
  unsupported(test_coefficients(fit, "lr"))
  unsupported(provider_estimate_se(fit))
  # The logistic fixed-effect family has no mid-p test (COXPH_DESIGN §D.3, item 4).
  data(ExampleDataBinary, package = "pprof", envir = environment())
  binary <- data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID, ExampleDataBinary$Z)
  logistic <- fit_logistic_fe(y ~ z1 + z2 + z3, binary[ExampleDataBinary$ProvID <= 20, ], "hospital")
  unsupported(test_providers(logistic, test = "midp"))
  unsupported(standardize_providers(logistic, interval = "midp"))
})

test_that("test_providers() gives the mid-p test by default, and the exact test (K-140 to K-142)", {
  fit <- cox_profile_fit()
  measures <- without_zero_warning(standardize_providers(fit))$table
  for (test in c("midp", "exact")) {
    tests <- without_zero_warning(test_providers(fit, test = if (test == "midp") NULL else test))
    expect_s3_class(tests, "pprof_provider_tests")
    expect_identical(tests$test, test)
    expect_identical(tests$table$provider_id, fit$providers$provider_id)
    expect_identical(tests$table$n_obs, fit$providers$n_obs)
    poisson <- infer_poisson_test(measures$observed, measures$expected, test, 0.95)
    expect_identical(tests$table$statistic, poisson$statistic)
    expect_identical(tests$table$p_value, poisson$p_value)
    expect_identical(tests$table$flag, poisson$flag)
  }
  # The mid-p statistic is floored (M-36): |z| <= 4.7534.
  tests <- without_zero_warning(test_providers(fit))
  expect_true(all(abs(tests$table$statistic) <= -qnorm(1e-6)))
  unsupported <- function(expr) expect_error(expr, class = "pprof_error_unsupported_inference")
  unsupported(test_providers(fit, alternative = "greater"))
  unsupported(test_providers(fit, test = "exact", alternative = "less"))
  # Providers are reported in provider order, whatever the order of `providers`.
  sub <- without_zero_warning(test_providers(fit, providers = c("p03", "p01")))
  chosen <- tests$table$provider_id %in% c("p01", "p03")
  expect_identical(sub$table$provider_id, c("p01", "p03"))
  expect_identical(sub$table$statistic, tests$table$statistic[chosen])
  expect_identical(sub$table$flag, tests$table$flag[chosen])
})

test_that("IDs in `providers` that the model does not have raise, where pprof_py ignores them (D-77)", {
  fit <- cox_profile_fit()
  invalid <- function(expr) expect_error(expr, class = "pprof_error_invalid_input")
  invalid(test_providers(fit, providers = c("p01", "p99")))
  invalid(standardize_providers(fit, providers = "p99"))
  invalid(funnel_limits(fit, providers = c("p99", "p02")))
  invalid(profile_providers(fit, providers = "p99"))
})

test_that("standardize_providers() gives the indirect and direct ratios (K-137 to K-139)", {
  d <- cox_profile_data()
  fit <- cox_profile_fit(d)
  measures <- without_zero_warning(standardize_providers(fit, c("indirect", "direct")))
  expect_identical(measures$measure, "ratio")
  indirect <- measures$table[measures$table$standardization == "indirect", ]
  direct <- measures$table[measures$table$standardization == "direct", ]
  rows <- seq_len(nrow(fit$providers))
  # Every row counts, those with weight 0 too (M-25, M-29, D-58).
  expect_identical(indirect$observed, as.double(tapply(d$status, d$provider, sum)[fit$providers$provider_id]))
  expect_identical(indirect$expected, data_provider_sums(fit$expected_events, fit$provider_index, rows))
  expect_identical(indirect$variance, indirect$expected)
  expect_identical(indirect$estimate, indirect$observed / indirect$expected)
  expect_identical(direct$observed, rep(as.double(sum(d$status)), length(rows)))
  expect_identical(direct$expected, cox_direct_expected(fit, rows))
  expect_identical(direct$estimate, direct$expected / direct$observed)
  expect_true(all(is.na(direct$variance)))
  # The expected events add up to the events.
  expect_lt(abs(sum(indirect$expected) - sum(d$status)), 1e-10 * sum(d$status))
  # A provider without events: indirect ratio 0 unless it has no expected events, direct ratio 0.
  p09 <- fit$providers$provider_id == "p09"
  expect_identical(c(indirect$estimate[p09], direct$estimate[p09]), c(0, 0))
})

test_that("the intervals are the exact and mid-p limits, two-sided, of indirect ratios only", {
  fit <- cox_profile_fit()
  base <- without_zero_warning(standardize_providers(fit))$table
  for (interval in c("exact", "midp")) {
    measures <- without_zero_warning(standardize_providers(fit, interval = interval, level = 0.9))
    limits <- if (interval == "exact") {
      infer_poisson_exact_limits(base$observed, base$expected, 0.9)
    } else {
      infer_poisson_midp_limits(base$observed, base$expected, 0.9)
    }
    expect_identical(measures$table$lower, unname(limits[, "lower"]))
    expect_identical(measures$table$upper, unname(limits[, "upper"]))
    expect_identical(measures$interval, interval)
  }
  # The mid-p limits invert the mid-p test: an interval excludes 1 exactly when the provider is flagged.
  midp <- without_zero_warning(standardize_providers(fit, interval = "midp"))$table
  flags <- without_zero_warning(test_providers(fit))$table$flag
  excludes <- midp$lower > 1 | midp$upper < 1
  expect_identical(flags != 0L, !is.na(excludes) & excludes)
  unsupported <- function(expr) expect_error(expr, class = "pprof_error_unsupported_inference")
  unsupported(standardize_providers(fit, "direct", interval = "midp"))
  unsupported(standardize_providers(fit, c("indirect", "direct"), interval = "exact"))
  unsupported(standardize_providers(fit, interval = "midp", alternative = "greater"))
})

test_that("a numeric null scales the expected events by exp(null) (M-40)", {
  fit <- cox_profile_fit()
  null <- log(1.5)
  base <- without_zero_warning(standardize_providers(fit))$table
  scaled <- without_zero_warning(standardize_providers(fit, c("indirect", "direct"), null = null))
  indirect <- scaled$table[scaled$table$standardization == "indirect", ]
  expect_identical(scaled$null_value, null)
  expect_identical(indirect$expected,
                   data_provider_sums(exp(null) * fit$expected_events, fit$provider_index, seq_along(base$expected)))
  # Direct standardization does not use the null.
  expect_identical(scaled$table$expected[scaled$table$standardization == "direct"],
                   cox_direct_expected(fit, seq_along(base$expected)))
  tests <- without_zero_warning(test_providers(fit, null = null))
  expect_identical(tests$table$statistic, infer_poisson_midp_statistic(indirect$observed, indirect$expected))
  expect_identical(tests$null_value, null)
  expect_error(test_providers(fit, null = "median"), class = "pprof_error_invalid_input")
  expect_identical(null_effect(fit, 1L), 1)
  expect_identical(expected_outcome(fit, 0), fit$expected_events)
})

test_that("providers without expected events: pprof_py's values and one warning per call (D-70, K-147)", {
  fit <- cox_profile_fit()
  p10 <- fit$providers$provider_id == "p10"
  expect_identical(zero_warnings(test_providers(fit)), 1L)
  expect_identical(zero_warnings(standardize_providers(fit, c("indirect", "direct"))), 1L)
  expect_identical(zero_warnings(standardize_providers(fit, interval = "midp")), 1L)
  expect_identical(zero_warnings(funnel_limits(fit)), 1L)
  expect_identical(zero_warnings(profile_providers(fit, interval = "midp")), 1L)
  expect_identical(zero_warnings(standardize_providers(fit, "direct")), 0L)
  expect_identical(zero_warnings(test_providers(fit, providers = c("p01", "p02"))), 0L)
  warning <- expect_warning(test_providers(fit), class = "pprof_warning_zero_expected")
  expect_identical(warning$providers, "p10")
  midp <- without_zero_warning(standardize_providers(fit, interval = "midp"))$table
  exact <- without_zero_warning(standardize_providers(fit, interval = "exact"))$table
  expect_identical(c(midp$observed[p10], midp$expected[p10]), c(0, 0))
  expect_identical(midp$estimate[p10], NaN)
  expect_identical(c(midp$lower[p10], midp$upper[p10]), c(NaN, Inf))
  expect_identical(c(exact$lower[p10], exact$upper[p10]), c(0, Inf))
  for (test in c("midp", "exact")) {
    row <- without_zero_warning(test_providers(fit, test = test))$table[p10, ]
    expect_identical(c(row$statistic, row$p_value), c(0, 1))
    expect_identical(row$flag, 0L)
  }
})

test_that("funnel_limits() gives pprof_py's count boundaries, which agree with the flags (K-149, M-39)", {
  fit <- cox_profile_fit()
  funnel <- without_zero_warning(funnel_limits(fit, level = c(0.95, 0.998)))
  measures <- without_zero_warning(standardize_providers(fit))$table
  points <- funnel$providers
  expect_identical(points$precision, measures$expected)
  expect_identical(points$estimate, measures$estimate)
  expect_identical(points$flag, without_zero_warning(test_providers(fit))$table$flag)
  expect_identical(funnel$test, "midp")
  expect_identical(funnel$target, 1)
  # One row per level and expected count above 0.
  precision <- sort(unique(measures$expected[measures$expected > 0]))
  expect_identical(funnel$table$precision, rep(precision, 2))
  for (level in c(0.95, 0.998)) {
    rows <- funnel$table[funnel$table$level == level, ]
    limits <- infer_poisson_funnel_limits(rows$precision, "midp", level)
    expect_identical(rows$lower, unname(limits[, "lower"]))
    expect_identical(rows$upper, unname(limits[, "upper"]))
  }
  # A provider lies outside its limits at the first level exactly when the mid-p test flags it.
  first <- funnel$table[funnel$table$level == 0.95, ]
  at <- match(points$precision, first$precision)
  tested <- !is.na(at)
  outside <- points$estimate[tested] < first$lower[at[tested]] | points$estimate[tested] > first$upper[at[tested]]
  expect_identical(points$flag[tested] != 0L, outside)
  expect_error(funnel_limits(fit, target = 2), class = "pprof_error_invalid_input")
})

test_that("profile_providers() collects the tests, the indirect measures, and the funnel", {
  fit <- cox_profile_fit()
  profile <- without_zero_warning(profile_providers(fit, interval = "midp"))
  expect_null(profile$effects)
  expect_identical(profile$test, "midp")
  expect_identical(profile$interval, "midp")
  expect_s3_class(profile$funnel, "pprof_funnel")
  expect_identical(profile$table$observed, profile$measures$table$observed)
  expect_identical(profile$table$flag, profile$tests$table$flag)
  expect_error(profile_providers(fit, alternative = "less"), class = "pprof_error_unsupported_inference")
})

test_that("the formula, not the order of the data's columns, determines the measures (D-63)", {
  d <- cox_profile_data()
  fit <- cox_profile_fit(d)
  reordered <- cox_profile_fit(d[, rev(names(d))])
  expect_identical(without_zero_warning(standardize_providers(reordered, c("indirect", "direct")))$table,
                   without_zero_warning(standardize_providers(fit, c("indirect", "direct")))$table)
  expect_identical(without_zero_warning(test_providers(reordered))$table,
                   without_zero_warning(test_providers(fit))$table)
})

test_that("relabelled providers, doubled times, and a shifted offset leave the measures as they are (§6 E)", {
  d <- cox_profile_data()
  measures <- function(data, ...) {
    without_zero_warning(standardize_providers(cox_profile_fit(data, ...), c("indirect", "direct")))$table
  }
  base <- measures(d)
  relabelled <- d
  relabelled$provider <- sub("^p", "q", d$provider)
  same <- measures(relabelled)
  expect_identical(same$provider_id, sub("^p", "q", base$provider_id))
  expect_identical(same[setdiff(names(same), "provider_id")], base[setdiff(names(base), "provider_id")])
  doubled <- d
  doubled$entry <- 2 * d$entry
  doubled$time <- 2 * d$time
  expect_identical(measures(doubled), base)
  shifted <- d
  shifted$o <- d$o + 3
  moved <- measures(shifted)
  tolerance <- reference_tolerance("closed_form")
  expect_true(all(abs(moved$expected - base$expected) <= tolerance$atol + tolerance$rtol * abs(base$expected)))
  expect_identical(moved$observed, base$observed)
})

test_that("shuffled rows give the measures to rounding; duplicated rows count twice (§6 E, M-29)", {
  d <- cox_profile_data()
  tight <- function(data, ...) cox_profile_fit(data, tol = 1e-11, max_iter = 100, ...)
  base <- without_zero_warning(standardize_providers(tight(d)))$table
  shuffled <- withr::with_seed(5, d[sample(nrow(d)), ])
  again <- without_zero_warning(standardize_providers(tight(shuffled)))$table
  tolerance <- reference_tolerance("cox_baseline")
  expect_true(all(abs(again$expected - base$expected) <= tolerance$atol + tolerance$rtol * abs(base$expected)))
  expect_identical(again$observed, base$observed)
  # The measures count rows, not weights: duplicating a row doubles its events, weight 2 does not.
  doubled <- rbind(d, d[d$provider == "p01", ])
  weighted <- d
  weighted$w[weighted$provider == "p01"] <- 2 * weighted$w[weighted$provider == "p01"]
  p01 <- base$provider_id == "p01"
  expect_identical(without_zero_warning(standardize_providers(tight(doubled)))$table$observed[p01],
                   2 * base$observed[p01])
  expect_identical(without_zero_warning(standardize_providers(tight(weighted)))$table$observed[p01],
                   base$observed[p01])
})

test_that("edge cases: no events, one-row providers, a large covariate mean (§6 F, D-64, D-73)", {
  d <- cox_profile_data()
  no_events <- d
  no_events$status <- 0
  expect_error(fit_cox_stratified(Surv(entry, time, status) ~ x + z, no_events, "provider"),
               class = "pprof_error_data")
  fit <- cox_profile_fit(d)
  measures <- without_zero_warning(standardize_providers(fit, interval = "midp"))$table
  p11 <- measures$provider_id == "p11"
  expect_identical(measures$observed[p11], 1)
  expect_true(measures$expected[p11] > 0 && measures$lower[p11] > 0 && is.finite(measures$upper[p11]))
  # Providers without events have the lower limit 0.
  expect_identical(measures$lower[measures$provider_id == "p09"], 0)
  # A covariate near 3,000: the same coefficients, so the same measures within cox_baseline (D-64).
  large <- d
  large$x <- d$x + 3000
  far <- without_zero_warning(standardize_providers(cox_profile_fit(large), interval = "midp"))$table
  tolerance <- reference_tolerance("cox_baseline")
  expect_true(all(is.finite(far$expected)))
  expect_true(all(abs(far$expected - measures$expected) <= tolerance$atol + tolerance$rtol * abs(measures$expected)))
})

test_that("a provider whose rows all have weight 0 is out of the fit and in the measures (M-25, M-29, D-58)", {
  d <- cox_profile_data()
  d$w[d$provider == "p03"] <- 0
  fit <- cox_profile_fit(d)
  expect_identical(as.integer(fit$n_zero_weight), sum(d$w == 0))
  # The fit is that of the other providers' rows.
  without <- cox_profile_fit(d[d$provider != "p03", ])
  tolerance <- reference_tolerance("closed_form")
  expect_true(all(abs(coef(fit) - coef(without)) <= tolerance$atol + tolerance$rtol * abs(coef(without))))
  # The measures count every row, p03's too.
  measures <- without_zero_warning(standardize_providers(fit, interval = "midp"))$table
  p03 <- measures$provider_id == "p03"
  expect_identical(measures$observed[p03], as.double(sum(d$status[d$provider == "p03"])))
  expect_true(measures$expected[p03] > 0 && all(is.finite(c(measures$lower[p03], measures$upper[p03]))))
  expect_true(abs(sum(measures$expected) - sum(d$status)) <= tolerance$atol + tolerance$rtol * sum(d$status))
})

test_that("the plots draw a Cox profile, leaving out a provider without expected events with a caption", {
  fit <- cox_profile_fit()
  profile <- without_zero_warning(profile_providers(fit, interval = "midp"))
  plots <- list(funnel = plot_funnel(profile), caterpillar = plot_caterpillar(profile$measures, use_flag = TRUE),
                flags = plot_flags(profile), volume = plot_volume(profile))
  for (name in names(plots)) {
    expect_s3_class(plots[[name]], "ggplot")
    expect_no_warning(ggplot2::ggplot_build(plots[[name]]))
  }
  caption <- "1 provider without a finite estimate (no expected events) not shown"
  for (name in c("funnel", "caterpillar", "volume")) expect_identical(plots[[name]]$labels$caption, caption)
  expect_null(plots$flags$labels$caption)
  expect_match(plots$funnel$labels$subtitle, "mid-p test at the 95% level")
  expect_match(plots$caterpillar$labels$subtitle, "Mid-p intervals at the 95% level")
  expect_identical(nrow(plots$funnel$layers[[3]]$data), nrow(fit$providers) - 1L)
})
