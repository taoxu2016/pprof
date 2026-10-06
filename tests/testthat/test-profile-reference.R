# The profiling functions against the reference's test(), SM_output(), confint(), and plot()
# fixtures on logis_fe() fits (K-62 to K-67, K-80, K-81, K-90, K-91, K-110). Cases where the
# reference fails or misaligns its results (Class A) are checked in
# test-profile-regression.R.
local_strict_mode()

profile_reference_class_a <- c(
  "test-binary-robust-wald", "test-binary-bad-null", "test-extreme-int-parm", "test-d04-score-standard",
  "SM_output-binary-null-integer", "confint-binary-gamma-greater", "confint-extreme-chr-gamma-exact",
  "confint-extreme-chr-sm-exact", "confint-extreme-fac-gamma-exact", "confint-extreme-hospital-sm-direct",
  "plot-binary-exact", "plot-binary-null-integer"
)

profile_reference_ids <- function() {
  ids <- reference_case_ids(c("test", "SM_output", "confint", "plot"))
  ids[vapply(ids, function(id) {
    startsWith(profile_case_parent_id(reference_fixture(id)$case), "logis_fe-")
  }, logical(1))]
}

for (id in setdiff(profile_reference_ids(), profile_reference_class_a)) {
  local({
    case_id <- id
    test_that(paste("the profiling functions reproduce the reference:", case_id), {
      fixture <- reference_fixture(case_id)
      case <- fixture$case
      if (isTRUE(case$heavy)) skip_on_cran()
      skip_off_reference_platform()
      expect_identical(fixture$result$outcome, "value")
      result <- profile_case_result(case)$value
      expected <- fixture$result$value
      settings <- profile_case_settings(case, profile_case_parent(case)$fit)
      switch(case$fun,
        test = expect_profile_tests(result, expected, case$tier),
        SM_output = expect_profile_measures(result, expected, case$tier),
        confint = if (identical(settings$option, "gamma")) {
          expect_profile_effects(result, expected, case$tier)
        } else {
          expect_profile_measure_intervals(result, expected, case$tier)
        },
        plot = expect_profile_funnel(result, expected, settings$alpha, case$tier)
      )
    })
  })
}

test_that("every logistic FE method case is checked here or as a Class A case", {
  ids <- profile_reference_ids()
  expect_true(length(ids) >= 60L)
  expect_true(all(profile_reference_class_a %in% reference_case_ids()))
})

test_that("Wald tests and intervals warn about providers with no events or only events (K-67)", {
  case <- reference_fixture("test-binary-wald-two.sided")$case
  expect_identical(profile_case_result(case)$warnings, "pprof_warning_wald_unreliable")
  case <- reference_fixture("confint-binary-sm-wald")$case
  expect_identical(profile_case_result(case)$warnings, "pprof_warning_wald_unreliable")
  case <- reference_fixture("test-binary-exact-two.sided")$case
  expect_identical(profile_case_result(case)$warnings, character())
})
