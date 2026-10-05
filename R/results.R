# Result objects (DEC-012).
#
# Every result is a list of class c("<result class>", "pprof_result") with a `table` (a base
# data frame keyed by provider or coefficient, with the column names of NAMING.md §5) and
# named fields for the settings used. Plots and printing read these fields, never attributes.
# Results are shared by the inference, profiling, and presentation layers, so their
# constructors are shared utilities. The validators check structure and types only, never
# the range of a number: the reference produces some values outside their mathematical range
# (for example p-values above 1, D-31) that the rewrite reproduces until sign-off.
#
# Each schema fixes the key, the required columns, and the required settings of a class.
# Later phases extend a schema when they add the function that builds the result.

result_schemas <- list(
  pprof_provider_effects = list(key = "provider_id", columns = "estimate", settings = c("interval", "level")),
  pprof_provider_tests = list(key = "provider_id", columns = c("statistic", "p_value", "flag"),
                              settings = c("test", "level", "alternative", "null_value")),
  pprof_measures = list(key = c("provider_id", "standardization", "measure"),
                        columns = c("observed", "expected", "estimate"),
                        settings = c("interval", "level", "null_value")),
  pprof_profile = list(key = "provider_id", columns = "n_obs", settings = character()),
  pprof_funnel = list(key = c("level", "precision"), columns = c("lower", "upper"), settings = c("target", "measure")),
  pprof_coefficient_tests = list(key = "term", columns = c("estimate", "statistic", "p_value"),
                                 settings = c("test", "level")),
  pprof_summary = list(key = "term", columns = c("estimate", "std_error", "statistic", "p_value"), settings = "level"),
  pprof_data_check = list(key = "variable", columns = "n_missing", settings = character())
)

result_character_columns <- c("provider_id", "term", "variable", "standardization", "measure")
result_count_columns <- c("n_obs", "n_missing")
result_numeric_columns <- c("observed", "expected", "estimate", "std_error", "statistic", "p_value", "lower", "upper",
                            "precision", "level")

# Constructors validate their object and return it visibly, so that a result prints when it
# is not assigned (D-51); validators return their argument invisibly.
new_pprof_result <- function(table, settings, class) {
  x <- structure(c(list(table = table), settings), class = c(class, "pprof_result"))
  validate_pprof_result(x)
  x
}

validate_pprof_result <- function(x) {
  result_class <- class(x)[1]
  fail <- function(what) abort_invalid_input(sprintf("Invalid `%s` object: %s.", result_class, what), arg = "x")
  schema <- result_schemas[[result_class]]
  if (!inherits(x, "pprof_result") || is.null(schema)) fail("not a known result class")
  table <- x[["table"]]
  if (!is.data.frame(table)) fail("`table` must be a data frame")
  missing <- setdiff(c(schema$key, schema$columns), names(table))
  if (length(missing) > 0L) fail(sprintf("`table` lacks the columns %s", paste(missing, collapse = ", ")))
  missing <- setdiff(schema$settings, names(x))
  if (length(missing) > 0L) fail(sprintf("the settings %s are missing", paste(missing, collapse = ", ")))
  key <- table[schema$key]
  if (any(vapply(key, anyNA, logical(1)))) fail("the key columns must not be missing")
  if (anyDuplicated(key) > 0L) fail(sprintf("the key (%s) must identify each row", paste(schema$key, collapse = ", ")))
  for (column in intersect(result_character_columns, names(table))) {
    if (!is.character(table[[column]])) fail(sprintf("column `%s` must be character", column))
  }
  for (column in intersect(result_count_columns, names(table))) {
    values <- table[[column]]
    if (!is.numeric(values) || any(values < 0 | values != round(values), na.rm = TRUE)) {
      fail(sprintf("column `%s` must hold counts", column))
    }
  }
  for (column in intersect(result_numeric_columns, names(table))) {
    if (!is.numeric(table[[column]])) fail(sprintf("column `%s` must be numeric", column))
  }
  if ("flag" %in% names(table)) {
    flag <- table[["flag"]]
    if (!is.integer(flag) || !all(flag %in% c(-1L, 0L, 1L, NA_integer_))) {
      fail("column `flag` must hold the integers -1, 0, 1")
    }
  }
  invisible(x)
}

new_pprof_provider_effects <- function(table, interval, level, ...) {
  check_choice(interval, c("none", "exact", "score", "wald"), "interval")
  check_level(level)
  new_pprof_result(table, list(interval = interval, level = level, ...), "pprof_provider_effects")
}

new_pprof_provider_tests <- function(table, test, level, alternative, null_value, ...) {
  check_string(test, "test")
  check_level(level)
  check_choice(alternative, c("two.sided", "greater", "less"), "alternative")
  check_number(null_value, "null_value")
  new_pprof_result(table, list(test = test, level = level, alternative = alternative, null_value = null_value, ...),
                   "pprof_provider_tests")
}

new_pprof_measures <- function(table, interval, level, null_value, ...) {
  check_choice(interval, c("none", "exact", "score", "wald"), "interval")
  check_level(level)
  check_number(null_value, "null_value")
  new_pprof_result(table, list(interval = interval, level = level, null_value = null_value, ...), "pprof_measures")
}

new_pprof_profile <- function(table, ...) {
  new_pprof_result(table, list(...), "pprof_profile")
}

new_pprof_funnel <- function(table, target, measure, ...) {
  check_number(target, "target")
  check_string(measure, "measure")
  new_pprof_result(table, list(target = target, measure = measure, ...), "pprof_funnel")
}

new_pprof_coefficient_tests <- function(table, test, level, ...) {
  check_string(test, "test")
  check_level(level)
  new_pprof_result(table, list(test = test, level = level, ...), "pprof_coefficient_tests")
}

new_pprof_summary <- function(table, level, ...) {
  check_level(level)
  new_pprof_result(table, list(level = level, ...), "pprof_summary")
}

new_pprof_data_check <- function(table, ...) {
  new_pprof_result(table, list(...), "pprof_data_check")
}

validate_result_class <- function(x, result_class) {
  if (!inherits(x, result_class)) {
    abort_invalid_input(sprintf("Expected a `%s` object, not an object of class '%s'.", result_class, class(x)[1]),
                        arg = "x")
  }
  validate_pprof_result(x)
}

validate_pprof_provider_effects <- function(x) validate_result_class(x, "pprof_provider_effects")
validate_pprof_provider_tests <- function(x) validate_result_class(x, "pprof_provider_tests")
validate_pprof_measures <- function(x) validate_result_class(x, "pprof_measures")
validate_pprof_profile <- function(x) validate_result_class(x, "pprof_profile")
validate_pprof_funnel <- function(x) validate_result_class(x, "pprof_funnel")
validate_pprof_coefficient_tests <- function(x) validate_result_class(x, "pprof_coefficient_tests")
validate_pprof_summary <- function(x) validate_result_class(x, "pprof_summary")
validate_pprof_data_check <- function(x) validate_result_class(x, "pprof_data_check")
