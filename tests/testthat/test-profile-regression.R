# Class A cases of the reference's method fixtures, in the new API: where pprof 1.0.3 fails
# or misaligns its results, the profiling functions return what the reference returns on
# the same data where it works (DISCREPANCIES.md).
local_strict_mode()

profile_case_fit <- function(id) {
  profile_case_parent(list(args = list(fit = structure(list(case_id = id), class = "pprof_ref_fit"))))
}

test_that("an unknown test, such as the reference's unimplemented robust Wald test, is rejected (D-06)", {
  fit <- profile_case_fit("logis_fe-binary-columns")$fit
  expect_error(test_providers(fit, test = "robust_wald"), class = "pprof_error_invalid_input")
  expect_error(test_providers(fit, null = "abc"), class = "pprof_error_invalid_input")
})

test_that("providers with integer IDs are selected by their IDs (D-27)", {
  skip_off_reference_platform()
  fit <- profile_case_fit("logis_fe-extreme-int")$fit
  tests <- test_providers(fit, providers = 1:3)
  all_providers <- reference_fixture("test-extreme-exact")$result$value
  expected <- all_providers[1:3, ]
  attr(expected, "provider size") <- attr(all_providers, "provider size")[1:3]
  expect_profile_tests(tests, expected, "iterative")
  expect_identical(test_providers(fit, providers = c("3", "1", "2"))$table, tests$table)
})

test_that("an integer null is used as the equal double (D-14)", {
  skip_off_reference_platform()
  fit <- profile_case_fit("logis_fe-binary-columns")$fit
  measures <- standardize_providers(fit, c("indirect", "direct"), null = 0L)
  expect_profile_measures(measures, reference_fixture("SM_output-binary-null0")$result$value, "iterative")
  expect_identical(test_providers(fit, null = 0L)$table, test_providers(fit, null = 0)$table)
  expect_profile_funnel(funnel_limits(fit, level = 1 - 0.05, null = 0L),
                        reference_fixture("plot-binary-null0")$result$value, 0.05, "iterative")
})

test_that("a non-finite standard score statistic keeps its place with a missing p-value and flag (D-04)", {
  skip_off_reference_platform()
  parent <- profile_case_fit("logis_fe-d04")
  warning <- expect_warning(tests <- test_providers(parent$fit, "score", score_type = "standard", data = parent$data),
                            class = "pprof_warning_undefined_statistics")
  table <- tests$table
  undefined <- !is.finite(table$statistic)
  expect_identical(table$provider_id[undefined], "5")
  expect_identical(warning$providers, "5")
  expect_true(all(is.na(table$p_value[undefined]) & is.na(table$flag[undefined])))
  expect_false(anyNA(table$p_value[!undefined]) || anyNA(table$flag[!undefined]))
  others <- test_providers(parent$fit, "score", score_type = "standard", providers = table$provider_id[!undefined],
                           data = parent$data)
  expect_identical(others$table, table[!undefined, , drop = FALSE], ignore_attr = "row.names")
  # The reference computes the other providers' statistics when it is asked only for them,
  # which it can do with the same data and double IDs (D-27).
  expect_profile_tests(others, reference_fixture("test-d04-score-standard-others")$result$value, "exact")
})

# The reference orders the limits of character IDs by as.numeric(ID), which is NA for every
# provider, so they stay in the order in which they were computed: providers with events
# and non-events, then providers with no events, then providers with only events, each in
# provider order. This returns the provider each row of its limits belongs to.
d19_reference_order <- function(fit) {
  providers <- provider_table(fit)[provider_table(fit)$included, ]
  kinds <- ifelse(providers$no_events, 2L, ifelse(providers$all_events, 3L, 1L))
  computed <- providers$provider_id[order(kinds)]
  computed[order(suppressWarnings(as.numeric(computed)))]
}

test_that("effect intervals of character IDs come in provider order (D-19)", {
  skip_off_reference_platform()
  fit <- profile_case_fit("logis_fe-extreme-chr")$fit
  effects <- provider_effects(fit, interval = "exact")
  expected <- reference_fixture("confint-extreme-chr-gamma-exact")$result$value
  expect_setequal(rownames(expected), effects$table$provider_id)
  expect_profile_effects(effects, expected[effects$table$provider_id, ], "root")
})

test_that("measure limits of character IDs belong to their providers (D-19)", {
  skip_off_reference_platform()
  fit <- profile_case_fit("logis_fe-extreme-chr")$fit
  measures <- standardize_providers(fit, interval = "exact")
  expected <- reference_fixture("confint-extreme-chr-sm-exact")$result$value
  order <- d19_reference_order(fit)
  expect_false(identical(order, provider_table(fit)$provider_id))
  repaired <- lapply(expected, function(table) {
    at <- match(rownames(table), order)
    table[[2]] <- table[[2]][at]
    table[[3]] <- table[[3]][at]
    table
  })
  expect_profile_measure_intervals(measures, repaired, "root")
  # With numeric IDs the reference pairs the limits correctly, and the same re-pairing
  # changes nothing.
  numeric_fit <- profile_case_fit("logis_fe-extreme")$fit
  expect_identical(d19_reference_order(numeric_fit), provider_table(numeric_fit)$provider_id)
})

test_that("effect intervals work with factor IDs (D-28)", {
  skip_off_reference_platform()
  fit <- profile_case_fit("logis_fe-extreme-fac")$fit
  effects <- provider_effects(fit, interval = "exact")
  expected <- reference_fixture("confint-extreme-gamma-exact")$result$value
  rownames(expected) <- as.character(as.numeric(rownames(expected)) * 10)
  expect_profile_effects(effects, expected, "root")
})

test_that("direct measure intervals work whatever the provider column is called (D-29)", {
  skip_off_reference_platform()
  fit <- profile_case_fit("logis_fe-extreme-hospital")$fit
  measures <- standardize_providers(fit, "direct", interval = "exact")
  expected <- reference_fixture("confint-extreme-sm-exact")$result$value
  expect_profile_measure_intervals(measures, expected[c("CI.direct_ratio", "CI.direct_rate")], "root")
})
