# Argument validators for the API boundary.
local_strict_mode()

invalid <- function(expr) expect_error(expr, class = "pprof_error_invalid_input")

test_that("valid arguments are returned invisibly", {
  expect_invisible(check_level(0.95))
  expect_identical(check_level(0.95), 0.95)
  expect_identical(check_choice("score", c("exact", "score"), "test"), "score")
  expect_identical(check_count(10, "min_provider_size"), 10)
  expect_identical(check_threads(2L), 2L)
})

test_that("check_level() needs a number strictly between 0 and 1", {
  invalid(check_level(0))
  invalid(check_level(1))
  invalid(check_level(c(0.9, 0.95)))
  invalid(check_level("0.95"))
  invalid(check_level(NA_real_))
  expect_error(check_level(1.5), "`level` must be a single finite number strictly between 0 and 1.", fixed = TRUE)
})

test_that("check_choice() matches exactly, never partially", {
  invalid(check_choice("sco", c("exact", "score"), "test"))
  invalid(check_choice(c("exact", "score"), c("exact", "score"), "test"))
  expect_identical(check_choice(c("ratio", "rate"), c("ratio", "rate"), "measure", multiple = TRUE), c("ratio", "rate"))
  invalid(check_choice(c("ratio", "ratio"), c("ratio", "rate"), "measure", multiple = TRUE))
  error <- expect_error(check_choice("x", c("a", "b"), "test"), class = "pprof_error_invalid_input")
  expect_identical(error$arg, "test")
  expect_identical(error$choices, c("a", "b"))
})

test_that("counts, flags, numbers, strings, and names are checked", {
  invalid(check_count(0, "n"))
  invalid(check_count(1.5, "n"))
  invalid(check_count(Inf, "n"))
  invalid(check_threads(0))
  invalid(check_flag(NA, "verbose"))
  invalid(check_flag("TRUE", "verbose"))
  invalid(check_number(Inf, "tol"))
  invalid(check_number(-1, "tol", lower = 0))
  expect_identical(check_number(0, "tol", lower = 0), 0)
  invalid(check_string("", "provider"))
  invalid(check_string(NA_character_, "provider"))
  invalid(check_names(c("a", "a"), "within_between"))
  invalid(check_names(character(), "within_between"))
})

test_that("data frames, formulas, and columns are checked", {
  invalid(check_data_frame(list(a = 1)))
  invalid(check_formula(~ x))
  invalid(check_formula("y ~ x"))
  expect_identical(check_formula(y ~ x), y ~ x)
  invalid(check_column(data.frame(a = 1), "b", "provider"))
})
