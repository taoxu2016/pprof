# Shared helpers for the Phase 0 audit scripts. Sourced by every script.

ref_lib <- Sys.getenv("PPROF_REF_LIB")
if (!nzchar(ref_lib) || !dir.exists(ref_lib)) {
  stop("Set PPROF_REF_LIB to the library that holds the reference pprof 1.0.3.", call. = FALSE)
}
suppressPackageStartupMessages(library(pprof, lib.loc = ref_lib))
stopifnot(
  identical(as.character(utils::packageVersion("pprof", lib.loc = ref_lib)), "1.0.3"),
  startsWith(normalizePath(find.package("pprof"), winslash = "/"),
             normalizePath(ref_lib, winslash = "/"))
)

audit_header <- function(title) {
  cat(strrep("=", 78), "\n", title, "\n", strrep("=", 78), "\n", sep = "")
  cat("pprof loaded from:", find.package("pprof"), "\n")
  cat("Run at:", format(Sys.time(), tz = "UTC", usetz = TRUE), "\n\n")
  print(utils::sessionInfo())
  cat("\n")
}

# Print one verification result. `status` is CONFIRMED, REFUTED, or NOTE.
report <- function(id, status, claim, evidence = NULL) {
  cat(sprintf("\n[%s] %s: %s\n", id, status, claim))
  if (!is.null(evidence)) {
    lines <- if (is.character(evidence)) evidence else utils::capture.output(print(evidence))
    cat(paste0("    ", lines), sep = "\n")
  }
  invisible(NULL)
}

# Evaluate an expression, returning either its value or the condition it raised.
try_capture <- function(expr) {
  warnings <- character()
  value <- withCallingHandlers(
    tryCatch(expr, error = function(e) e),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  list(value = value, error = inherits(value, "error"),
       message = if (inherits(value, "error")) conditionMessage(value) else NA_character_,
       warnings = warnings)
}

# Capture C++ Rcout output (iteration logs) together with the result.
with_output <- function(expr) {
  value <- NULL
  out <- utils::capture.output(value <- suppressWarnings(suppressMessages(expr)))
  list(value = value, output = out)
}

# Parse "converged after N iterations" from captured C++ output.
iterations_from_log <- function(lines) {
  hit <- grep("converged after", lines, value = TRUE)
  if (length(hit) == 0) return(NA_integer_)
  as.integer(sub(".*converged after ([0-9]+) iterations.*", "\\1", hit[length(hit)]))
}

max_rel_diff <- function(a, b) {
  a <- as.numeric(a); b <- as.numeric(b)
  max(abs(a - b) / pmax(abs(b), .Machine$double.xmin))
}

max_abs_diff <- function(a, b) max(abs(as.numeric(a) - as.numeric(b)))

load_binary_example <- function() {
  e <- new.env()
  utils::data("ExampleDataBinary", package = "pprof", lib.loc = ref_lib, envir = e)
  d <- e$ExampleDataBinary
  data.frame(Y = d$Y, ProvID = d$ProvID, d$Z)
}

load_linear_example <- function() {
  e <- new.env()
  utils::data("ExampleDataLinear", package = "pprof", lib.loc = ref_lib, envir = e)
  d <- e$ExampleDataLinear
  data.frame(Y = d$Y, ProvID = d$ProvID, d$Z)
}

covariate_names <- paste0("z", 1:5)

quiet_logis_fe <- function(...) suppressWarnings(suppressMessages(pprof::logis_fe(..., message = FALSE)))
