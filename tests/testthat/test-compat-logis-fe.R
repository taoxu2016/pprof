# The logis_fe() compatibility wrapper and the methods for old objects (ARCHITECTURE §I.2,
# DEC-032). The reference fixtures check their results; these tests check what the fixtures
# do not: the progress report, input checks, argument translation, and the model rebuilt
# from an old object.
local_strict_mode()

compat_example <- function() {
  data(ExampleDataBinary, package = "pprof", envir = environment())
  data.frame(Y = ExampleDataBinary$Y, ProvID = ExampleDataBinary$ProvID, ExampleDataBinary$Z)
}

compat_columns <- function(data, ...) {
  logis_fe(data = data, Y.char = "Y", Z.char = paste0("z", 1:5), ProvID.char = "ProvID", ...)
}

test_that("the progress report follows the reference, with the corrected screening count (D-01)", {
  withr::local_seed(1)
  small <- data.frame(Y = stats::rbinom(70, 1, 0.3), ProvID = rep(c("p09", "p10", "p11", "p40"), c(9, 10, 11, 40)),
                      x1 = stats::rnorm(70))
  output <- character()
  messages <- character()
  warning <- NULL
  output <- utils::capture.output(withCallingHandlers(
    fit <- logis_fe(data = small, Y.char = "Y", Z.char = "x1", ProvID.char = "ProvID"),
    message = function(m) {
      messages <<- c(messages, conditionMessage(m))
      invokeRestart("muffleMessage")
    },
    pprof_warning_screening = function(w) {
      warning <<- w
      invokeRestart("muffleWarning")
    }
  ))
  expect_identical(conditionMessage(warning), "1 out of 4 providers considered small and filtered out!")
  expect_identical(rownames(fit$coefficient$gamma), c("p10", "p11", "p40"))
  expect_identical(trimws(messages[1]), "Input format: data, Y.char, Z.char, and ProvID.char.")
  expect_match(messages[2], "out of 3 remaining providers with no events.", fixed = TRUE)
  expect_identical(output[1], "Implementing SerBIN algorithm (Rcpp) for fixed provider effects model ...")
  iterations <- length(output) - 2L
  expect_match(output[2], "^Iter 1: Minimum criterion across all checks is [0-9.]+e[-+][0-9]+;$")
  expect_identical(output[length(output)], sprintf("serBIN (Rcpp) algorithm converged after %d iterations!", iterations))
  expect_identical(reference_parse_iterations(output), iterations)
})

test_that("a fit that reaches the iteration limit says so and warns (D-03)", {
  data <- compat_example()
  output <- utils::capture.output(fit <- withCallingHandlers(
    compat_columns(data, max.iter = 3, tol = 1e-300, stop = "beta"),
    message = function(m) invokeRestart("muffleMessage"),
    pprof_warning_screening = function(w) invokeRestart("muffleWarning"),
    pprof_warning_not_converged = function(w) invokeRestart("muffleWarning")
  ))
  expect_identical(output[length(output)], "serBIN (Rcpp) algorithm not converged after 4 iterations!")
  expect_match(output[2], "^Iter 1: Inf norm of running diff in est reg parm is ")
  expect_identical(reference_parse_iterations(output), 4L)
  expect_warning(compat_columns(data, max.iter = 3, tol = 1e-300, stop = "beta", message = FALSE),
                 class = "pprof_warning_not_converged")
})

test_that("with message = FALSE nothing is printed", {
  data <- compat_example()
  expect_silent(fit <- compat_columns(data, message = FALSE))
  expect_s3_class(fit, "logis_fe", exact = TRUE)
})

test_that("the three input formats give the same fit", {
  data <- compat_example()
  columns <- compat_columns(data, message = FALSE)
  vectors <- logis_fe(Y = data$Y, Z = as.matrix(data[paste0("z", 1:5)]), ProvID = data$ProvID, message = FALSE)
  formula <- logis_fe(Y ~ z1 + z2 + z3 + z4 + z5 + id(ProvID), data, message = FALSE)
  expect_identical(vectors$coefficient, columns$coefficient)
  expect_identical(formula$coefficient, columns$coefficient)
  expect_identical(formula$char_list, list(Y.char = "Y", ProvID.char = "ProvID", Z.char = paste0("z", 1:5)))
})

test_that("inputs the reference accepted without checking raise classed errors (D-22, D-23, D-39)", {
  data <- compat_example()
  expect_error(compat_columns(data, method = "BAN", backtrack = 2, message = FALSE), class = "pprof_error_invalid_input")
  expect_error(compat_columns(data, max.iter = 0, message = FALSE), class = "pprof_error_invalid_input")
  expect_error(compat_columns(data, tol = 0, message = FALSE), class = "pprof_error_invalid_input")
  expect_error(compat_columns(data, bound = 0, message = FALSE), class = "pprof_error_invalid_input")
  expect_error(compat_columns(data, threads = 0, message = FALSE), class = "pprof_error_invalid_input")
  expect_error(compat_columns(transform(data, Y = 2 * Y), message = FALSE), class = "pprof_error_invalid_input")
  expect_error(compat_columns(data, method = "Newton", message = FALSE), class = "pprof_error_invalid_input")
  expect_error(compat_columns(data, stop = "never", message = FALSE), class = "pprof_error_invalid_input")
  expect_error(logis_fe(data = data, message = FALSE), class = "pprof_error_invalid_input")
  expect_error(logis_fe(Y ~ z1, data, message = FALSE), class = "pprof_error_invalid_input")
})

test_that("settings the reference accepts are translated as it reads them", {
  data <- compat_example()
  # Rcpp truncates a non-integer max.iter; SerBIN reads any non-zero backtrack as TRUE; a
  # cutoff below 1 includes every provider, and a cutoff between integers acts as the next.
  expect_identical(suppressWarnings(compat_columns(data, max.iter = 3.7, message = FALSE))$coefficient,
                   suppressWarnings(compat_columns(data, max.iter = 3, message = FALSE))$coefficient)
  expect_identical(compat_columns(data, backtrack = 2, message = FALSE)$coefficient,
                   compat_columns(data, message = FALSE)$coefficient)
  expect_identical(compat_columns(data, cutoff = 0, message = FALSE)$coefficient,
                   compat_columns(data, cutoff = 1, message = FALSE)$coefficient)
  expect_identical(compat_columns(data, cutoff = 59.5, message = FALSE)$coefficient,
                   compat_columns(data, cutoff = 60, message = FALSE)$coefficient)
})

test_that("the model rebuilt from an old object is the model of the fit (DEC-032)", {
  data <- compat_example()
  old <- compat_columns(data, message = FALSE)
  model <- compat_model_from_logis_fe(old)
  fit <- fit_logistic_fe(Y ~ z1 + z2 + z3 + z4 + z5, data, "ProvID")
  expect_identical(model$coefficients, fit$coefficients)
  expect_identical(model$provider_effects, fit$provider_effects)
  expect_identical(model$vcov, fit$vcov)
  expect_identical(model$linear_predictor, fit$linear_predictor)
  expect_identical(provider_table(model)$provider_id, provider_table(fit)$provider_id[provider_table(fit)$included])
  expect_identical(test_providers(model)$table, test_providers(fit)$table)
  broken <- old
  broken$data_include <- broken$data_include[rev(seq_len(nrow(broken$data_include))), ]
  expect_error(compat_model_from_logis_fe(broken), class = "pprof_error_invalid_input")
})

test_that("the old methods read the old object's fields", {
  data <- compat_example()
  old <- compat_columns(data, message = FALSE)
  edited <- old
  edited$coefficient$gamma[] <- edited$coefficient$gamma + 0.1
  expect_false(identical(SM_output(edited, stdz = "direct")$direct.ratio, SM_output(old, stdz = "direct")$direct.ratio))
})

test_that("summary() fails, as the reference does, for coefficient positions it cannot refit", {
  data <- compat_example()
  old <- compat_columns(data, message = FALSE)
  expect_error(summary(old, parm = -1, test = "lr"), class = "pprof_error_invalid_input")
  expect_error(summary(old, parm = 9, test = "score"), class = "pprof_error_invalid_input")
  expect_identical(rownames(summary(old, parm = -1)), paste0("z", 2:5))
})

test_that("the exact funnel plot raises a classed error (D-07)", {
  old <- compat_columns(compat_example(), message = FALSE)
  expect_error(plot(old, test = "exact"), class = "pprof_error_unsupported_inference")
})
