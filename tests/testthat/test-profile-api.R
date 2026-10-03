# The profiling API: argument checks, provider selection, settings, and invariance to how
# provider IDs are stored.
local_strict_mode()

profile_example <- function(ids = identity, keep_data = FALSE) {
  data(ExampleDataBinary, package = "pprof", envir = environment())
  data <- data.frame(y = ExampleDataBinary$Y, hospital = ids(ExampleDataBinary$ProvID), ExampleDataBinary$Z)
  data <- data[ExampleDataBinary$ProvID <= 20, ]
  list(data = data, fit = fit_logistic_fe(y ~ z1 + z2 + z3 + z4 + z5, data, "hospital", keep_data = keep_data))
}

test_that("the profiling functions check their arguments", {
  fit <- profile_example()$fit
  expect_error(test_providers(fit$coefficients), class = "pprof_error_invalid_input")
  expect_error(test_providers(fit, test = "exact.poisbinom"), class = "pprof_error_invalid_input")
  expect_error(test_providers(fit, score_type = "plain"), class = "pprof_error_invalid_input")
  expect_error(test_providers(fit, level = 1), class = "pprof_error_invalid_input")
  expect_error(test_providers(fit, alternative = "two-sided"), class = "pprof_error_invalid_input")
  expect_error(test_providers(fit, "bootstrap", n_resamples = 0), class = "pprof_error_invalid_input")
  expect_error(test_providers(fit, threads = 0), class = "pprof_error_invalid_input")
  expect_error(test_providers(fit, null = c(0, 1)), class = "pprof_error_invalid_input")
  expect_error(test_providers(fit, null = NA_real_), class = "pprof_error_invalid_input")
  expect_error(test_providers(fit, null = "mean"), class = "pprof_error_invalid_input")
  expect_error(test_providers(fit, providers = c(1, 99)), class = "pprof_error_invalid_input")
  expect_error(test_providers(fit, providers = list(1)), class = "pprof_error_invalid_input")
  expect_error(provider_effects(fit, interval = "profile"), class = "pprof_error_invalid_input")
  expect_error(standardize_providers(fit, "both"), class = "pprof_error_invalid_input")
  expect_error(standardize_providers(fit, measure = "difference"), class = "pprof_error_invalid_input")
  expect_error(funnel_limits(fit, level = c(0.95, 0.95)), class = "pprof_error_invalid_input")
  expect_error(funnel_limits(fit, level = c(0.95, 1.2)), class = "pprof_error_invalid_input")
  expect_error(funnel_limits(fit, target = "one"), class = "pprof_error_invalid_input")
})

test_that("the standard score test needs the covariates (DEC-005)", {
  example <- profile_example()
  expect_error(test_providers(example$fit, "score", score_type = "standard"), class = "pprof_error_data_required")
  kept <- profile_example(keep_data = TRUE)$fit
  expect_identical(test_providers(kept, "score", score_type = "standard"),
                   test_providers(example$fit, "score", score_type = "standard", data = example$data))
})

test_that("results record their settings", {
  fit <- profile_example()$fit
  tests <- test_providers(fit, "score", null = 0.5, level = 0.9, alternative = "less")
  expect_s3_class(tests, c("pprof_provider_tests", "pprof_result"), exact = TRUE)
  expect_identical(tests[c("test", "level", "alternative", "null_value", "score_type")],
                   list(test = "score", level = 0.9, alternative = "less", null_value = 0.5, score_type = "modified"))
  expect_null(tests$n_resamples)
  boot <- withr::with_seed(1, test_providers(fit, "bootstrap", n_resamples = 20))
  expect_identical(boot$n_resamples, 20L)
  expect_null(boot$score_type)
  expect_identical(test_providers(fit)$null_value, unname(stats::median(fit$provider_effects)))
  measures <- standardize_providers(fit, c("direct", "indirect"), c("rate", "ratio"))
  expect_identical(measures$standardization, c("indirect", "direct"))
  expect_identical(measures$measure, c("ratio", "rate"))
  expect_identical(unique(measures$table[c("standardization", "measure")]),
                   data.frame(standardization = rep(c("indirect", "direct"), each = 2), measure = c("ratio", "rate"),
                              row.names = c(1L, 21L, 41L, 61L)))
  expect_identical(measures$population_rate, sum(fit$response) / length(fit$response) * 100)
  expect_null(standardize_providers(fit, measure = "ratio")$population_rate)
})

test_that("providers are selected by their IDs as character and reported in provider order (D-27)", {
  fit <- profile_example()$fit
  selected <- test_providers(fit, providers = c("12", "3", "7"))
  expect_identical(selected$table$provider_id, c("3", "7", "12"))
  expect_identical(test_providers(fit, providers = c(12L, 3L, 7L)), selected)
  all <- test_providers(fit)$table
  expect_identical(selected$table, all[all$provider_id %in% c("3", "7", "12"), ], ignore_attr = "row.names")
})

test_that("results do not depend on how provider IDs are stored", {
  reference <- profile_example()$fit
  for (ids in list(as.integer, function(x) sprintf("P%03d", x), function(x) factor(sprintf("P%03d", x)))) {
    fit <- profile_example(ids)$fit
    same <- function(a, b) {
      a$table$provider_id <- NULL
      b$table$provider_id <- NULL
      expect_identical(a, b)
    }
    same(test_providers(fit, "score"), test_providers(reference, "score"))
    same(provider_effects(fit, "score"), provider_effects(reference, "score"))
    same(standardize_providers(fit, c("indirect", "direct"), interval = "score"),
         standardize_providers(reference, c("indirect", "direct"), interval = "score"))
  }
})

test_that("the thread count does not change the standard score test or the direct expectations", {
  example <- profile_example()
  one <- test_providers(example$fit, "score", score_type = "standard", data = example$data, threads = 1)
  two <- test_providers(example$fit, "score", score_type = "standard", data = example$data, threads = 2)
  expect_identical(one, two)
  expect_identical(standardize_providers(example$fit, "direct", threads = 2),
                   standardize_providers(example$fit, "direct", threads = 1))
})

test_that("direct standardization does not use the null value", {
  fit <- profile_example()$fit
  direct <- standardize_providers(fit, "direct", null = 0.3)$table
  expect_identical(direct, standardize_providers(fit, "direct")$table)
})

test_that("profile_providers() collects the results of the profiling functions", {
  fit <- profile_example()$fit
  profile <- profile_providers(fit, test = "score", interval = "score")
  expect_s3_class(profile, c("pprof_profile", "pprof_result"), exact = TRUE)
  expect_identical(profile$tests, test_providers(fit, "score"))
  expect_identical(profile$effects, provider_effects(fit))
  expect_identical(profile$measures, standardize_providers(fit, interval = "score"))
  expect_identical(profile$funnel, funnel_limits(fit))
  ratio <- profile$measures$table[profile$measures$table$measure == "ratio", ]
  expect_identical(profile$table$observed, ratio$observed)
  expect_identical(profile$table$expected, ratio$expected)
  expect_identical(profile$table$flag, profile$tests$table$flag)
  expect_identical(profile$table$provider_id, as.character(1:20))
})
