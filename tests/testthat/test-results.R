# Result objects (DEC-012): a validated table keyed by provider or coefficient, plus settings.
local_strict_mode()

provider_test_table <- function() {
  data.frame(provider_id = c("a", "b", "c"), statistic = c(-2.1, 0.3, 2.5), p_value = c(0.036, 0.76, 0.012),
             flag = c(-1L, 0L, 1L), stringsAsFactors = FALSE)
}

test_that("each result class is built with its key, columns, and settings", {
  tests <- new_pprof_provider_tests(provider_test_table(), test = "exact", level = 0.95, alternative = "two.sided",
                                    null_value = 0.1)
  expect_s3_class(tests, c("pprof_provider_tests", "pprof_result"), exact = TRUE)
  expect_identical(tests$level, 0.95)
  expect_identical(validate_pprof_provider_tests(tests), tests)

  effects <- new_pprof_provider_effects(data.frame(provider_id = "a", estimate = 0.2), interval = "none", level = 0.95)
  expect_identical(validate_pprof_provider_effects(effects), effects)

  measures <- new_pprof_measures(
    data.frame(provider_id = c("a", "a"), standardization = c("indirect", "direct"), measure = "ratio",
               observed = c(3, 3), expected = c(2.5, 2.8), estimate = c(1.2, 1.07)),
    interval = "exact", level = 0.9, null_value = -0.4, population_rate = 12.5
  )
  expect_identical(measures$population_rate, 12.5)
  expect_identical(validate_pprof_measures(measures), measures)

  expect_identical(validate_pprof_profile(new_pprof_profile(data.frame(provider_id = "a", n_obs = 10L))),
                   new_pprof_profile(data.frame(provider_id = "a", n_obs = 10L)))
  funnel <- new_pprof_funnel(data.frame(level = 0.95, precision = c(1, 2), lower = c(0.1, 0.2), upper = c(1.9, 1.8)),
                             target = 1, measure = "ratio")
  expect_identical(validate_pprof_funnel(funnel), funnel)
  coefficient_tests <- new_pprof_coefficient_tests(
    data.frame(term = "x", estimate = 0.3, statistic = 2, p_value = 0.05),
    test = "lr", level = 0.95
  )
  expect_identical(validate_pprof_coefficient_tests(coefficient_tests), coefficient_tests)
  summary <- new_pprof_summary(data.frame(term = "x", estimate = 0.3, std_error = 0.1, statistic = 3, p_value = 0.003),
                               level = 0.95)
  expect_identical(validate_pprof_summary(summary), summary)
  check <- new_pprof_data_check(data.frame(variable = c("x", "z"), n_missing = c(0L, 2L), percent_missing = c(0, 20)),
                                n_obs = 10L, n_complete = 8L)
  expect_identical(validate_pprof_data_check(check), check)
})

test_that("tables must have the key and required columns, with the right types", {
  invalid <- function(expr) expect_error(expr, class = "pprof_error_invalid_input")
  tests <- function(table) new_pprof_provider_tests(table, "exact", 0.95, "two.sided", 0)
  table <- provider_test_table()
  invalid(tests(table[, -2]))
  invalid(tests(rbind(table, table[1, ])))
  bad <- table
  bad$provider_id[2] <- NA
  invalid(tests(bad))
  bad <- table
  bad$flag <- as.numeric(bad$flag)
  invalid(tests(bad))
  bad <- table
  bad$flag[1] <- 2L
  invalid(tests(bad))
  bad <- table
  bad$provider_id <- factor(bad$provider_id)
  invalid(tests(bad))
  bad <- table
  bad$p_value <- as.character(bad$p_value)
  invalid(tests(bad))
  invalid(new_pprof_profile(data.frame(provider_id = "a", n_obs = 2.5)))
})

test_that("settings are required and checked", {
  invalid <- function(expr) expect_error(expr, class = "pprof_error_invalid_input")
  invalid(new_pprof_provider_tests(provider_test_table(), "exact", 95, "two.sided", 0))
  invalid(new_pprof_provider_tests(provider_test_table(), "exact", 0.95, "two-sided", 0))
  invalid(new_pprof_provider_tests(provider_test_table(), "exact", 0.95, "two.sided", "median"))
  invalid(new_pprof_provider_effects(data.frame(provider_id = "a", estimate = 0.2), interval = "profile", level = 0.95))
  tests <- new_pprof_provider_tests(provider_test_table(), "exact", 0.95, "two.sided", 0)
  tests$alternative <- NULL
  invalid(validate_pprof_provider_tests(tests))
})

test_that("validators do not check the range of values, which the reference can exceed (D-31)", {
  table <- provider_test_table()
  table$p_value[1] <- 1.4
  expect_s3_class(new_pprof_provider_tests(table, "wald", 0.95, "two.sided", 0), "pprof_provider_tests")
})

test_that("class-specific validators reject other classes", {
  tests <- new_pprof_provider_tests(provider_test_table(), "exact", 0.95, "two.sided", 0)
  expect_error(validate_pprof_measures(tests), class = "pprof_error_invalid_input")
  expect_error(validate_pprof_result(structure(list(table = data.frame()), class = c("pprof_unknown", "pprof_result"))),
               class = "pprof_error_invalid_input")
})
