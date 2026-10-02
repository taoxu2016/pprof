# The single verbosity helper (brief §5.5, DEC-008).
#
# Every informational message of the rewrite goes through inform_message(), which signals a
# `pprof_message` condition only when `verbose` is TRUE and prints nothing otherwise.
# Warnings and errors do not go through this helper: they are classed conditions
# (conditions.R) that verbosity never suppresses.

inform_message <- function(verbose, ...) {
  if (!isTRUE(verbose)) {
    return(invisible(FALSE))
  }
  text <- paste0(..., collapse = "")
  condition <- structure(
    class = c("pprof_message", "message", "condition"),
    list(message = paste0(text, "\n"), call = NULL)
  )
  message(condition)
  invisible(TRUE)
}
