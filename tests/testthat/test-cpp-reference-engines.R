# The logistic fixed-effect engines against the reference fixtures (Phase 3).
#
# For every logis_fe() fit case that returned a value, the C++ engine, run on the case's
# data, starting values, and settings, must take the same number of iterations (DEC-014),
# report the same stopping criterion at every iteration as the reference printed it (four
# significant digits), and reach the same estimates and variances within the iterative
# tolerance. On the platform that generated the fixtures they are expected to be bitwise
# identical, which validation/ reports.
local_strict_mode()

expect_engine_values <- function(actual, expected, label) {
  diffs <- reference_compare(actual, as.numeric(expected), reference_tolerance("iterative"))
  testthat::expect(is.null(diffs), sprintf("%s differs from the reference: %s", label,
                                           paste(diffs$detail, collapse = "; ")))
}

for (set in c("core", "full")) {
  ids <- engine_reference_ids(set)
  if (set == "core" && length(ids) == 0L) {
    test_that("reference fit fixtures are available", skip("Reference fixtures or jsonlite not available"))
  }
  for (id in ids) {
    local({
      case_id <- id
      case_set <- set
      test_that(paste("the engine reproduces the reference fit:", case_id), {
        fixture <- reference_fixture(case_id, case_set)
        case <- fixture$case
        if (identical(case_set, "full") || isTRUE(case$heavy)) skip_on_cran()
        inputs <- engine_case_inputs(case, reference_datasets_for(case, case_set))
        fit <- engine_fit(inputs)
        expected <- fixture$result

        expect_identical(fit$iterations, expected$iterations)
        reference_log <- engine_reference_log(expected$output)
        if (length(reference_log) > 0L) expect_identical(engine_log(fit), reference_log)
        expect_engine_values(fit$gamma, expected$value$coefficient$gamma, "gamma")
        expect_engine_values(fit$beta, expected$value$coefficient$beta, "beta")

        variances <- cpp_logistic_variance(inputs$design, inputs$sizes, fit$gamma, fit$beta)
        expect_engine_values(as.numeric(variances$beta), expected$value$variance$beta, "Var(beta)")
        expect_engine_values(variances$gamma, expected$value$variance$gamma, "Var(gamma)")
      })
    })
  }
}
