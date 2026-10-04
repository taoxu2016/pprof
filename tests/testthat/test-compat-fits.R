# The compatibility wrappers of Phase 4 (ARCHITECTURE §I.2): logis_firth(), linear_fe(),
# linear_re(), logis_re(), linear_cre(), and logis_cre(). The reference fixtures check their
# results; these tests check what the fixtures do not: the messages and the progress report,
# the input checks and Class A fixes, the argument translation, and the print methods.
local_strict_mode()

compat_binary <- function() {
  data(ExampleDataBinary, package = "pprof", envir = environment())
  data.frame(Y = ExampleDataBinary$Y, ProvID = ExampleDataBinary$ProvID, ExampleDataBinary$Z)
}

compat_linear <- function() {
  data(ExampleDataLinear, package = "pprof", envir = environment())
  data.frame(Y = ExampleDataLinear$Y, ProvID = ExampleDataLinear$ProvID, ExampleDataLinear$Z)
}

# Binary data small enough for fast glmer() fits.
compat_small_binary <- function() {
  withr::local_seed(4)
  n <- 600
  data.frame(Y = stats::rbinom(n, 1, 0.3), ProvID = rep(sprintf("P%02d", 1:30), each = 20),
             x1 = stats::rnorm(n), x2 = stats::rnorm(n))
}

compat_firth <- function(data, ...) {
  logis_firth(data = data, Y.char = "Y", Z.char = paste0("z", 1:5), ProvID.char = "ProvID", ...)
}

test_that("the Firth progress report follows the reference, with the corrected screening count (D-01)", {
  withr::local_seed(1)
  small <- data.frame(Y = stats::rbinom(70, 1, 0.3), ProvID = rep(c("p09", "p10", "p11", "p40"), c(9, 10, 11, 40)),
                      x1 = stats::rnorm(70))
  messages <- character()
  warning <- NULL
  output <- utils::capture.output(withCallingHandlers(
    fit <- logis_firth(data = small, Y.char = "Y", Z.char = "x1", ProvID.char = "ProvID"),
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
  expect_identical(output[1:2], c("Implementing firth-corrected fixed provider effects model (Rcpp) ...",
                                  "Algorithm (1 cores) ..."))
  iterations <- length(output) - 3L
  expect_match(output[3], "^Iter 1: Inf norm of running diff in est reg parm is [0-9.]+e[-+][0-9]+;$")
  expect_identical(output[length(output)], sprintf("Algorithm with 1 cores converged after %d iterations.", iterations))
  expect_identical(reference_parse_iterations(output), iterations)
})

test_that("a Firth fit that reaches the iteration limit says so and warns (D-03)", {
  data <- compat_binary()
  output <- utils::capture.output(fit <- withCallingHandlers(
    compat_firth(data, max.iter = 3, tol = 1e-300),
    message = function(m) invokeRestart("muffleMessage"),
    pprof_warning_screening = function(w) invokeRestart("muffleWarning"),
    pprof_warning_not_converged = function(w) invokeRestart("muffleWarning")
  ))
  expect_identical(output[length(output)], "Algorithm with 1 cores not converged after 3 iterations.")
  expect_identical(reference_parse_iterations(output), 3L)
  expect_warning(compat_firth(data, max.iter = 3, tol = 1e-300, message = FALSE),
                 class = "pprof_warning_not_converged")
})

test_that("logis_firth() with message = FALSE prints nothing, and two threads give the fit of one (D-05)", {
  data <- compat_binary()
  expect_silent(fit <- compat_firth(data, message = FALSE))
  expect_s3_class(fit, "logis_fe", exact = TRUE)
  two <- compat_firth(data, threads = 2, message = FALSE)
  expect_identical(two$coefficient, fit$coefficient)
  expect_identical(two$variance, fit$variance)
})

test_that("logis_firth() rejects the inputs the reference accepted without checking (D-39)", {
  data <- compat_binary()
  expect_error(compat_firth(data, max.iter = 0, message = FALSE), class = "pprof_error_invalid_input")
  expect_error(compat_firth(data, tol = 0, message = FALSE), class = "pprof_error_invalid_input")
  expect_error(compat_firth(data, bound = 0, message = FALSE), class = "pprof_error_invalid_input")
  # The reference terminates R with a negative bound.
  expect_error(compat_firth(data, bound = -1, message = FALSE), class = "pprof_error_invalid_input")
  expect_error(compat_firth(data, threads = 0, message = FALSE), class = "pprof_error_invalid_input")
  expect_error(compat_firth(transform(data, Y = 2 * Y), message = FALSE), class = "pprof_error_invalid_input")
  expect_error(logis_firth(data = data, message = FALSE), class = "pprof_error_invalid_input")
})

test_that("logis_firth() works with factor IDs when screening excludes providers, as with text IDs (D-41)", {
  data <- compat_binary()
  data$ProvID <- sprintf("P%03d", data$ProvID)
  text <- compat_firth(data, cutoff = 60, message = FALSE)
  data$ProvID <- factor(data$ProvID)
  factors <- compat_firth(data, cutoff = 60, message = FALSE)
  expect_identical(nrow(factors$coefficient$gamma), 97L)
  expect_identical(factors$coefficient, text$coefficient)
  expect_identical(factors$variance, text$variance)
})

test_that("logis_firth() raises a classed error where the reference terminated R (D-42)", {
  data <- transform(compat_binary(), zero = 0)
  expect_warning(
    expect_error(logis_firth(data = data, Y.char = "Y", Z.char = c("z1", "zero"), ProvID.char = "ProvID",
                             message = FALSE),
                 class = "pprof_error_convergence"),
    class = "pprof_warning_rank_deficient"
  )
})

test_that("linear_fe() always reports its input format and translates option.gamma.var (D-16, D-36)", {
  data <- compat_linear()
  z <- paste0("z", 1:5)
  fe <- function(...) linear_fe(data = data, Y.char = "Y", Z.char = z, ProvID.char = "ProvID", ...)
  expect_message(fit <- fe(), "Input format: data, Y.char, Z.char, and ProvID.char.", fixed = TRUE)
  expect_identical(attr(fit$variance$gamma, "description"), "simplified")
  full <- suppressMessages(fe(option.gamma.var = "full"))
  expect_identical(attr(full$variance$gamma, "description"), "full")
  expect_identical(full$coefficient, fit$coefficient)
  expect_true(all(full$variance$gamma >= fit$variance$gamma))
  # The reference also accepts the first letters.
  expect_identical(suppressMessages(fe(option.gamma.var = "f"))$variance, full$variance)
  expect_identical(suppressMessages(fe(option.gamma.var = "s"))$variance, fit$variance)
  expect_error(suppressMessages(fe(option.gamma.var = "exact")), class = "pprof_error_invalid_input")
})

test_that("linear_re() and logis_re() raise classed errors where the reference's vector interface failed (D-11)", {
  data <- compat_linear()
  z <- as.matrix(data[paste0("z", 1:5)])
  # cbind() would turn every column into text; the reference failed in lme4.
  expect_error(linear_re(Y = data$Y, Z = z, ProvID = paste0("P", data$ProvID)), class = "pprof_error_invalid_input")
  # No input format matches; the reference failed with "object 'fit_re' not found".
  expect_error(linear_re(Y = data$Y), class = "pprof_error_invalid_input")
  small <- compat_small_binary()
  expect_error(logis_re(Y = small$Y, Z = as.matrix(small[c("x1", "x2")]), ProvID = small$ProvID),
               class = "pprof_error_invalid_input")
  expect_error(logis_re(Y = small$Y), class = "pprof_error_invalid_input")
  # Text IDs with a data frame Z work, and data_include is text, as in the reference.
  fit <- suppressMessages(linear_re(Y = data$Y, Z = data[paste0("z", 1:5)], ProvID = paste0("P", data$ProvID)))
  expect_s3_class(fit, "linear_re", exact = TRUE)
  expect_type(fit$data_include$Y, "character")
})

test_that("linear_re() and logis_re() always report their input format, and the CRE fits print nothing (D-36)", {
  data <- compat_linear()
  z <- paste0("z", 1:5)
  expect_message(linear_re(data = data, Y.char = "Y", Z.char = z, ProvID.char = "ProvID"),
                 "Input format: data, Y.char, Z.char, and ProvID.char.", fixed = TRUE)
  expect_silent(linear_cre(data = data, Y.char = "Y", wb.char = z[1:2], other.char = z[3:5], ProvID.char = "ProvID"))
  small <- compat_small_binary()
  expect_message(logis_re(data = small, Y.char = "Y", Z.char = c("x1", "x2"), ProvID.char = "ProvID"),
                 "Input format: data, Y.char, Z.char, and ProvID.char.", fixed = TRUE)
  expect_silent(logis_cre(data = small, Y.char = "Y", wb.char = "x1", other.char = "x2", ProvID.char = "ProvID"))
})

test_that("RE and CRE objects print as in the reference; logis_cre has no registered method (D-09)", {
  small <- compat_small_binary()
  fit <- suppressMessages(logis_re(data = small, Y.char = "Y", Z.char = c("x1", "x2"), ProvID.char = "ProvID"))
  printed <- utils::capture.output(print(fit))
  expect_identical(printed[1], "$coefficient")
  expect_false(any(grepl("attr(,\"model\")", printed, fixed = TRUE)))
  expect_s4_class(attr(fit, "model"), "glmerMod")
  cre <- logis_cre(data = small, Y.char = "Y", wb.char = "x1", other.char = "x2", ProvID.char = "ProvID")
  expect_true(any(grepl("attr(,\"model\")", utils::capture.output(print(cre)), fixed = TRUE)))
  expect_null(utils::getS3method("print", "logis_cre", optional = TRUE))
  for (class in c("linear_re", "logis_re", "linear_cre")) {
    expect_false(is.null(utils::getS3method("print", class, optional = TRUE)), label = class)
  }
})
