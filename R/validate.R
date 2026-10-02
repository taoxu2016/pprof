# Argument validators for the API boundary (brief §5.5).
#
# Each validator returns its input invisibly when it is valid and raises
# `pprof_error_invalid_input` otherwise, naming the argument in the message and in the
# condition's `arg` field. Choices are matched exactly; there is no partial matching.

check_data_frame <- function(x, arg = "data") {
  if (!is.data.frame(x)) {
    abort_invalid_input(sprintf("`%s` must be a data frame.", arg), arg = arg)
  }
  invisible(x)
}

check_formula <- function(x, arg = "formula") {
  if (!inherits(x, "formula") || length(x) != 3L) {
    abort_invalid_input(sprintf("`%s` must be a two-sided formula, such as `y ~ x1 + x2`.", arg), arg = arg)
  }
  invisible(x)
}

check_string <- function(x, arg) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(x)) {
    abort_invalid_input(sprintf("`%s` must be a single non-empty string.", arg), arg = arg)
  }
  invisible(x)
}

# A character vector of distinct, non-empty names.
check_names <- function(x, arg) {
  if (!is.character(x) || length(x) == 0L || anyNA(x) || !all(nzchar(x)) || anyDuplicated(x) > 0L) {
    abort_invalid_input(sprintf("`%s` must be a character vector of distinct, non-empty names.", arg), arg = arg)
  }
  invisible(x)
}

check_column <- function(data, column, arg) {
  if (!column %in% names(data)) {
    abort_invalid_input(sprintf("`%s` names column '%s', which is not in `data`.", arg, column), arg = arg)
  }
  invisible(column)
}

check_flag <- function(x, arg) {
  if (!is.logical(x) || length(x) != 1L || is.na(x)) {
    abort_invalid_input(sprintf("`%s` must be TRUE or FALSE.", arg), arg = arg)
  }
  invisible(x)
}

# A single finite number in [lower, upper], or in the open interval when `open` is TRUE.
check_number <- function(x, arg, lower = -Inf, upper = Inf, open = FALSE) {
  ok <- is.numeric(x) && length(x) == 1L && is.finite(x)
  if (ok) ok <- if (open) x > lower && x < upper else x >= lower && x <= upper
  if (!ok) {
    range_text <- if (is.infinite(lower) && is.infinite(upper)) {
      ""
    } else if (open) {
      sprintf(" strictly between %s and %s", format(lower), format(upper))
    } else {
      sprintf(" between %s and %s", format(lower), format(upper))
    }
    abort_invalid_input(sprintf("`%s` must be a single finite number%s.", arg, range_text), arg = arg)
  }
  invisible(x)
}

# A single whole number of at least `min`.
check_count <- function(x, arg, min = 1) {
  ok <- is.numeric(x) && length(x) == 1L && is.finite(x) && x == round(x) && x >= min
  if (!ok) {
    abort_invalid_input(sprintf("`%s` must be a single whole number of at least %s.", arg, format(min)), arg = arg)
  }
  invisible(x)
}

check_level <- function(x, arg = "level") {
  check_number(x, arg, lower = 0, upper = 1, open = TRUE)
}

check_threads <- function(x, arg = "threads") {
  check_count(x, arg, min = 1)
}

# One value of `choices`, or with `multiple = TRUE` one or more distinct values.
check_choice <- function(x, choices, arg, multiple = FALSE) {
  ok <- is.character(x) && length(x) >= 1L && !anyNA(x) && all(x %in% choices) &&
    (multiple || length(x) == 1L) && anyDuplicated(x) == 0L
  if (!ok) {
    abort_invalid_input(
      sprintf("`%s` must be %s of %s.", arg, if (multiple) "one or more" else "one",
              paste0('"', choices, '"', collapse = ", ")),
      arg = arg, choices = choices
    )
  }
  invisible(x)
}
