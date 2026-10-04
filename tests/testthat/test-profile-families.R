# The profiling and covariate functions on the linear FE, RE, and CRE families (Phase 5,
# DEC-046): against the reference's test(), SM_output(), confint(), summary(), and plot()
# fixtures on linear_fe(), linear_re(), logis_re(), linear_cre(), and logis_cre() fits, with
# the new fits of the same data (K-60, K-68 to K-70, K-82 to K-84, K-92 to K-94, K-103 to
# K-105, K-111), and the family-specific behavior of the new API.
local_strict_mode()

# Cases that concern the old interfaces only: the reference's summaries select the intercept
# only as "(intercept)" (D-44), which the new API names "(Intercept)"; the wrappers are
# checked against this case.
family_wrapper_only <- "summary-linear-re-parm-intercept-capital"

for (id in setdiff(family_case_ids(), family_wrapper_only)) {
  local({
    case_id <- id
    test_that(paste("the new API reproduces the reference:", case_id), {
      fixture <- reference_fixture(case_id)
      case <- fixture$case
      if (isTRUE(case$heavy)) skip_on_cran()
      if (identical(case$tier, "lme4")) {
        versions <- reference_lme4_matches()
        if (!versions$ok) skip(paste("lme4-backed fixture not comparable:", versions$detail))
      }
      parent_fun <- family_parent_fun(case)
      fit <- family_case_parent(case)
      result <- family_case_run(case, fit, parent_fun)
      expect_family_case(case, result, fixture$result$value, case$tier, parent_fun)
    })
  })
}

test_that("every method case of the five families is checked here or is a reference error or wrapper case", {
  ids <- family_case_ids()
  expect_true(length(ids) >= 100L)
  expect_true(family_wrapper_only %in% ids)
})

family_example <- function(outcome) {
  data <- if (identical(outcome, "linear")) {
    reference_datasets_for(list(args = list(ref_dataset("linear_example"))), "core")$linear_example
  } else {
    reference_datasets_for(list(args = list(ref_dataset("binary_example"))), "core")$binary_example
  }
  names(data)[1:2] <- c("y", "hospital")
  data
}

family_formula <- y ~ z1 + z2 + z3 + z4 + z5

family_fits <- function() {
  if (is.null(family_case_cache$examples)) {
    linear <- family_example("linear")
    binary <- family_example("binary")
    family_case_cache$examples <- withr::with_collate("C", suppressMessages(list(
      linear_fe = fit_linear_fe(family_formula, linear, "hospital"),
      linear_fe_full = fit_linear_fe(family_formula, linear, "hospital", provider_variance = "full"),
      linear_re = fit_linear_re(family_formula, linear, "hospital"),
      logistic_re = fit_logistic_re(family_formula, binary, "hospital"),
      linear_cre = fit_linear_cre(family_formula, linear, "hospital", within_between = c("z1", "z2")),
      logistic_cre = fit_logistic_cre(family_formula, binary, "hospital", within_between = c("z1", "z2"))
    )))
  }
  family_case_cache$examples
}

test_that("each family declares the inference of ARCHITECTURE §E.3", {
  skip_on_cran()
  fits <- family_fits()
  mixed <- c("coef_wald", "provider_wald", "interval_wald", "standardize_indirect", "standardize_direct")
  expect_identical(inference_capabilities(fits$linear_fe), c(mixed, "funnel"))
  for (name in c("linear_re", "logistic_re", "linear_cre", "logistic_cre")) {
    expect_identical(inference_capabilities(fits[[name]]), mixed)
  }
  for (fit in fits) {
    for (test in c("exact", "bootstrap", "score")) {
      expect_error(test_providers(fit, test), class = "pprof_error_unsupported_inference")
    }
    expect_error(provider_effects(fit, interval = "exact"), class = "pprof_error_unsupported_inference")
    expect_error(standardize_providers(fit, interval = "score"), class = "pprof_error_unsupported_inference")
    expect_error(test_coefficients(fit, "lr"), class = "pprof_error_unsupported_inference")
  }
  expect_error(funnel_limits(fits$linear_re), class = "pprof_error_unsupported_inference")
  expect_error(funnel_limits(fits$logistic_cre), class = "pprof_error_unsupported_inference")
})

test_that("the default test is the family's: Wald for linear FE, RE, and CRE models (DEC-047)", {
  skip_on_cran()
  fits <- family_fits()
  for (fit in fits) {
    expect_identical(test_providers(fit), test_providers(fit, "wald"))
    expect_identical(profile_providers(fit)$test, "wald")
  }
})

test_that("the null is a family option: median or mean for linear FE, a number for RE and CRE (K-60, D-14)", {
  skip_on_cran()
  fits <- family_fits()
  effects <- unname(fits$linear_fe$provider_effects)
  mean_null <- sum(fits$linear_fe$providers$n_obs * effects) / fits$linear_fe$n_obs
  expect_identical(test_providers(fits$linear_fe, null = "mean")$null_value, mean_null)
  expect_identical(test_providers(fits$linear_fe)$null_value, stats::median(effects))
  expect_identical(test_providers(fits$linear_fe, null = 0L), test_providers(fits$linear_fe, null = 0))
  expect_identical(test_providers(fits$linear_re)$null_value, 0)
  expect_identical(standardize_providers(fits$logistic_re, null = 1L),
                   standardize_providers(fits$logistic_re, null = 1))
  expect_error(test_providers(fits$linear_re, null = "median"), class = "pprof_error_invalid_input")
  expect_error(standardize_providers(fits$logistic_cre, null = "mean"), class = "pprof_error_invalid_input")
})

test_that("RE and CRE indirect measures put lme4's fitted values over the expected outcomes (K-82, K-84)", {
  skip_on_cran()
  fits <- family_fits()
  for (name in c("linear_re", "logistic_re", "linear_cre", "logistic_cre")) {
    fit <- fits[[name]]
    expect_identical(predicted_outcome(fit), fit$fitted)
    measures <- standardize_providers(fit, c("indirect", "direct"))
    expect_identical(measures$indirect_numerator, "predicted")
    expect_identical(measures$direct_reference, "observed")
    table <- measures$table
    rows <- table[table$standardization == "indirect" & table$measure == measures$measure[1], ]
    groups <- factor(fit$provider_index, levels = seq_len(nrow(fit$providers)))
    expect_equal(rows$observed, as.vector(tapply(fit$fitted, groups, sum)), tolerance = 1e-12)
    expect_true(all(is.na(rows$variance)))
  }
  expect_error(predicted_outcome(fits$linear_fe), class = "pprof_error_unsupported_inference")
})

test_that("linear FE direct standardization compares with the outcomes expected under the null (K-83)", {
  skip_on_cran()
  fit <- family_fits()$linear_fe
  measures <- standardize_providers(fit, "direct")
  expect_identical(measures$direct_reference, "null_expected")
  null <- measures$null_value
  expect_identical(unique(measures$table$observed), sum(null + fit$linear_predictor))
  mean_measures <- standardize_providers(fit, "direct", null = "mean")
  expect_false(identical(measures$table$estimate, mean_measures$table$estimate))
  # Both differences equal gamma_i - null up to rounding (K-83).
  both <- standardize_providers(fit, c("indirect", "direct"))$table
  for (method in c("indirect", "direct")) {
    expect_equal(both$estimate[both$standardization == method], unname(fit$provider_effects) - null, tolerance = 1e-10)
  }
})

test_that("linear FE tests and intervals use opposite distributions for each provider variance (K-68, K-92, D-32)", {
  skip_on_cran()
  fits <- family_fits()
  df <- fits$linear_fe$n_obs - fits$linear_fe$n_providers - length(fits$linear_fe$coefficients)
  simplified <- provider_effects(fits$linear_fe, interval = "wald")$table
  full <- provider_effects(fits$linear_fe_full, interval = "wald")$table
  expect_equal((simplified$upper - simplified$estimate) / simplified$std_error, rep(stats::qt(0.975, df), 100),
               tolerance = 1e-12)
  expect_equal((full$upper - full$estimate) / full$std_error, rep(stats::qnorm(0.975), 100), tolerance = 1e-12)
  tests_simplified <- test_providers(fits$linear_fe, null = 0)$table
  tests_full <- test_providers(fits$linear_fe_full, null = 0)$table
  upper <- stats::pnorm(tests_simplified$statistic, lower.tail = FALSE)
  expect_identical(tests_simplified$p_value, 2 * pmin(upper, 1 - upper))
  upper <- stats::pt(tests_full$statistic, df, lower.tail = FALSE)
  expect_identical(tests_full$p_value, 2 * pmin(upper, 1 - upper))
})

test_that("covariate tests and intervals follow each family's rule (K-103 to K-105, D-31)", {
  skip_on_cran()
  fits <- family_fits()
  table <- summary(fits$logistic_re)$table
  expect_true(table$p_value[table$estimate < 0][1] > 1)
  expect_identical(table$p_value, unname(2 * (1 - stats::pnorm(table$statistic))))
  linear <- summary(fits$linear_re)$table
  df <- fits$linear_re$n_obs - length(fits$linear_re$coefficients) - fits$linear_re$n_providers + 1
  expect_identical(linear$p_value, unname(2 * (1 - stats::pt(abs(linear$statistic), df))))
  for (name in c("linear_re", "logistic_re", "linear_cre", "logistic_cre")) {
    fit <- fits[[name]]
    a <- c(0.05, 0.95)
    expected <- unname(fit$coefficients + sqrt(diag(fit$vcov)) %o% stats::qnorm(a))
    expect_identical(unname(confint(fit, level = 0.9)), expected)
    expect_identical(names(fit$coefficients)[1], "(Intercept)")
  }
  fe <- confint(fits$linear_fe, parm = "z2", level = 0.9)
  expect_identical(dimnames(fe), list("z2", c("5 %", "95 %")))
  expect_s3_class(tidy(fits$linear_cre), "tbl_df")
})

test_that("the linear funnel has precision n_i, half-width z sigma / sqrt(n_i), and Wald flags (K-111)", {
  skip_on_cran()
  fit <- family_fits()$linear_fe
  funnel <- funnel_limits(fit, level = c(0.95, 0.99))
  expect_identical(funnel$measure, "difference")
  expect_identical(funnel$target, 0)
  expect_identical(funnel$test, "wald")
  expect_identical(funnel$providers$precision, fit$providers$n_obs)
  limits <- funnel$table[funnel$table$level == 0.95, ]
  expect_identical(limits$upper, stats::qnorm(1 - (1 - 0.95) / 2) * sqrt(1 / limits$precision) * fit$sigma)
  expect_true(any(limits$lower < 0))
  expect_identical(funnel$providers$flag, test_providers(fit, "wald")$table$flag)
  expect_s3_class(plot_funnel(funnel), "ggplot")
})

test_that("the summaries and results of every family print", {
  skip_on_cran()
  fits <- family_fits()
  for (fit in fits) {
    expect_output(print(summary(fit)), "Coefficients with Wald tests")
    expect_output(print(test_providers(fit)))
    expect_output(print(standardize_providers(fit, c("indirect", "direct"), interval = "wald")))
    expect_output(print(provider_effects(fit, interval = "wald")))
  }
  expect_output(print(funnel_limits(fits$linear_fe)))
})

test_that("profile_providers() works for every family, with a funnel only where declared", {
  skip_on_cran()
  fits <- family_fits()
  for (name in names(fits)) {
    profile <- profile_providers(fits[[name]], interval = "wald")
    expect_s3_class(profile, "pprof_profile")
    expect_identical(is.null(profile$funnel), !grepl("^linear_fe", name))
    expect_s3_class(plot_flags(profile), "ggplot")
    expect_s3_class(plot_caterpillar(profile$measures), "ggplot")
  }
})
