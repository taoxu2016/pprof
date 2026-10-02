# Classed conditions (NAMING.md §6) and the verbosity helper (DEC-008).
local_strict_mode()

test_that("errors carry their class, the parent class, and their fields", {
  error <- expect_error(abort_invalid_input("bad `level`", arg = "level"), class = "pprof_error_invalid_input")
  expect_s3_class(error, c("pprof_error_invalid_input", "pprof_error", "error", "condition"), exact = TRUE)
  expect_identical(conditionMessage(error), "bad `level`")
  expect_identical(error$arg, "level")
  expect_error(abort_data("no providers"), class = "pprof_error_data")
  expect_error(abort_convergence("singular"), class = "pprof_error_convergence")
  expect_error(abort_data_required("needs data"), class = "pprof_error_data_required")
})

test_that("unsupported inference names the model class and the request", {
  model <- structure(list(), class = c("pprof_toy_condition", "pprof_model"))
  error <- expect_error(abort_unsupported_inference(model, "provider_wald"),
                        class = "pprof_error_unsupported_inference")
  expect_identical(error$model_class, "pprof_toy_condition")
  expect_identical(error$requested, "provider_wald")
  expect_match(conditionMessage(error), "'pprof_toy_condition' do not support 'provider_wald'", fixed = TRUE)
})

test_that("warnings carry their class and the parent class", {
  warning <- expect_warning(warn_not_converged("limit reached"), class = "pprof_warning_not_converged")
  expect_s3_class(warning, c("pprof_warning_not_converged", "pprof_warning", "warning", "condition"), exact = TRUE)
  expect_warning(warn_screening("3 providers excluded"), class = "pprof_warning_screening")
})

test_that("deprecation warnings are given once per id", {
  registry <- new.env(parent = emptyenv())
  expect_warning(warn_deprecated("logis_fe", "use fit_logistic_fe()", registry = registry), class = "pprof_deprecated")
  expect_no_warning(warn_deprecated("logis_fe", "use fit_logistic_fe()", registry = registry))
  expect_warning(warn_deprecated("linear_fe", "use fit_linear_fe()", registry = registry), class = "pprof_deprecated")
})

test_that("inform_message() prints only when verbose and signals pprof_message", {
  expect_silent(inform_message(FALSE, "hidden"))
  expect_message(inform_message(TRUE, "shown: ", 3), "shown: 3", class = "pprof_message")
  expect_silent(inform_message(NA, "hidden"))
})
