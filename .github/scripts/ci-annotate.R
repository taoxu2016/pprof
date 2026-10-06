# Copies the results of a CI step into GitHub annotations (DEC-071). The public GitHub API
# returns a job's annotations without signing in, while its logs and artifacts need an account,
# so the annotations are how the results of the fork's CI can be read
# (dev/design/phase8-facts/01_ci_runs.R reads them). Base R only.
#
# Usage, from the repository root:
#   Rscript .github/scripts/ci-annotate.R check <check directory>   R CMD check results
#   Rscript .github/scripts/ci-annotate.R rout <file> ...            failures in testthat output
#   Rscript .github/scripts/ci-annotate.R report <report> <log>      the reference suite
#   Rscript .github/scripts/ci-annotate.R tail <title> <file> [n]    the last n lines of a log
#   Rscript .github/scripts/ci-annotate.R fixture-diff <title> <report>   a compare_fixtures.R report
#   Rscript .github/scripts/ci-annotate.R dependencies <types> <upgrade> <ref> ...
#     replays a failed installation of the dependencies (types such as Config/Needs/check,all;
#     upgrade TRUE or FALSE)
#
# GitHub keeps at most 10 annotations of each level per step, so each mode stays within that.

max_chars <- 4000L

escape_data <- function(x) {
  x <- gsub("%", "%25", x, fixed = TRUE)
  x <- gsub("\r", "%0D", x, fixed = TRUE)
  gsub("\n", "%0A", x, fixed = TRUE)
}

escape_property <- function(x) {
  x <- escape_data(x)
  x <- gsub(":", "%3A", x, fixed = TRUE)
  gsub(",", "%2C", x, fixed = TRUE)
}

annotate <- function(level, title, lines) {
  text <- paste(lines, collapse = "\n")
  if (nchar(text, type = "chars") > max_chars) {
    text <- paste0(substr(text, 1L, max_chars), "\n[cut at ", max_chars, " characters]")
  }
  cat(sprintf("::%s title=%s::%s\n", level, escape_property(title), escape_data(text)))
}

read_text <- function(file) {
  readLines(file, warn = FALSE, encoding = "UTF-8")
}

# The platform, with what makes floating-point results differ between platforms: the BLAS and
# LAPACK that R (and so Armadillo) uses, and the C++ compiler and its flags.
platform <- function() {
  blas <- tryCatch(extSoftVersion()[["BLAS"]], error = function(e) "")
  config <- function(var) {
    out <- tryCatch(system2(file.path(R.home("bin"), "R"), c("CMD", "config", var), stdout = TRUE, stderr = FALSE),
                    error = function(e) "?", warning = function(w) "?")
    trimws(gsub("\\s+", " ", paste(out, collapse = " ")))
  }
  paste0(R.version.string, "; ", utils::sessionInfo()$running, "; ", R.version$platform,
         "; BLAS: ", if (nzchar(blas)) blas else "R's internal BLAS",
         "; LAPACK: ", La_library(), " ", La_version(),
         "; CXX17: ", config("CXX17"), " ", config("CXX17FLAGS"))
}

# Failures in the output of a testthat run (testthat.Rout.fail, or a log that holds it): one
# annotation for each failing test, up to `budget`, and a listing of all of them.
annotate_rout <- function(file, budget = 4L) {
  lines <- read_text(file)
  summary <- utils::tail(grep("^\\[ FAIL", lines, value = TRUE), 1L)
  start <- grep("(═|=)+ Failed tests", lines)
  if (!length(start)) {
    annotate("error", paste("Tests:", basename(file)), c(summary, utils::tail(lines, 60L)))
    return(invisible())
  }
  body <- lines[(start[1] + 1L):length(lines)]
  heads <- grep("^(──|--) (Error|Failure|Warning|Skip)", body)
  if (!length(heads)) {
    annotate("error", paste("Tests:", basename(file)), c(summary, utils::head(body, 80L)))
    return(invisible())
  }
  ends <- c(heads[-1] - 1L, length(body))
  titles <- sub("^(──|--) ", "", sub(" *(─|-)+$", "", body[heads]))
  for (k in seq_len(min(length(heads), budget))) {
    block <- body[heads[k]:ends[k]]
    block <- block[!grepl("^\\[ FAIL|^Error: Test failures|^Execution halted", block)]
    annotate("error", paste("Test", titles[k]), c(block[-1], "", summary))
  }
  # Every failing test, one line each ("Failure ('file:line'): name :: the first line of its
  # message"), in up to three annotations, so that the inventory is complete.
  first_lines <- vapply(seq_along(heads), function(k) {
    message <- trimws(body[heads[k]:ends[k]][-1])
    message <- message[nzchar(message)]
    if (length(message)) substr(message[1], 1L, 160L) else ""
  }, "")
  listing <- paste(titles, first_lines, sep = " :: ")
  chunks <- split(listing, cumsum(nchar(listing, type = "chars") + 1L) %/% (max_chars - 200L))
  for (k in seq_len(min(length(chunks), 3L))) {
    annotate("error", sprintf("Failing tests, all %d (part %d)", length(listing), k), chunks[[k]])
  }
  invisible()
}

# R CMD check: every item that is not OK (errors as errors, warnings as warnings, notes as
# notices), the status, the test summary, and the failing tests.
annotate_check <- function(check_dir) {
  logs <- Sys.glob(file.path(check_dir, "*.Rcheck", "00check.log"))
  if (!length(logs)) {
    annotate("error", "R CMD check", sprintf("No 00check.log under %s: the check did not run. %s", check_dir,
                                             platform()))
    return(invisible())
  }
  rcheck <- dirname(logs[1])
  log <- read_text(logs[1])
  items <- grep("^\\* ", log)
  counts <- c(error = 0L, warning = 0L, notice = 0L)
  for (k in seq_along(items)) {
    s <- items[k]
    end <- if (k < length(items)) items[k + 1L] - 1L else length(log)
    section <- log[s:end]
    # An item's result ends its first line ("... NOTE") or a line of its own (the tests'
    # " ERROR" after "Running 'testthat.R'"); the closing "* DONE" holds only the status.
    if (grepl("^\\* DONE", section[1])) next
    marks <- regmatches(section, regexpr("(^|[] ])(ERROR|WARNING|NOTE)\\s*$", section))
    marks <- trimws(gsub("]", "", marks, fixed = TRUE))
    if (!length(marks)) next
    level <- if ("ERROR" %in% marks) "error" else if ("WARNING" %in% marks) "warning" else "notice"
    if (counts[[level]] >= 3L) next
    counts[[level]] <- counts[[level]] + 1L
    item <- sub(" \\.\\.\\..*$", "", sub("^\\* checking ", "", section[1]))
    annotate(level, paste("R CMD check:", item), section)
  }
  status <- grep("^Status:", log, value = TRUE)
  tests <- Sys.glob(file.path(rcheck, "tests*", "testthat.Rout*"))
  test_summary <- unlist(lapply(tests, function(f) utils::tail(grep("^\\[ FAIL", read_text(f), value = TRUE), 1L)))
  annotate("notice", "R CMD check status", c(if (length(status)) status else "no status line", test_summary,
                                              platform()))
  for (f in tests[grepl("\\.fail$", tests)]) annotate_rout(f)
  install <- file.path(rcheck, "00install.out")
  if (any(grepl("can be installed \\.\\.\\. ERROR", log)) && file.exists(install)) {
    annotate("error", "Installation", utils::tail(read_text(install), 60L))
  }
  invisible()
}

# The reference suite: the summary of its report and the failing cases, or the end of the run's
# log when it stopped before writing the report.
annotate_report <- function(report, log_file) {
  if (!file.exists(report)) {
    lines <- if (file.exists(log_file)) utils::tail(read_text(log_file), 60L) else "no log"
    annotate("error", "Reference suite: no report", c(lines, platform()))
    return(invisible())
  }
  lines <- read_text(report)
  annotate("notice", "Reference suite", c(utils::head(grep("^- ", lines, value = TRUE), 6L), platform()))
  fails <- grep("\\| FAIL", lines, value = TRUE)
  if (length(fails)) annotate("error", sprintf("Reference suite: %d failing cases", length(fails)), fails)
  invisible()
}

# A diff report of dev/reference/compare_fixtures.R between the committed fixtures and those
# pprof 1.0.3 produced on the runner (DEC-080): how far the reference itself moves on this
# platform. Informational: its summary, the environment's changes, and the changed cases.
annotate_fixture_diff <- function(title, report) {
  if (!file.exists(report)) {
    annotate("warning", title, c("no report", platform()))
    return(invisible())
  }
  lines <- read_text(report)
  env <- lines[startsWith(lines, "- ") & grepl(" -> ", lines, fixed = TRUE)]
  summary <- grep("^- (Cases|Datasets)", lines, value = TRUE)
  changed <- sub("^### ", "", grep("^### ", lines, value = TRUE))
  annotate("notice", title, c(summary, env, sprintf("Changed cases (%d): %s", length(changed),
                                                    paste(changed, collapse = ", ")), platform()))
}

# A failed r-lib/actions/setup-r-dependencies step, whose own log is not readable without
# signing in: resolve and install the same references with pak, in a library of their own,
# and copy the end of the output into an annotation.
annotate_dependencies <- function(dependencies, upgrade, refs) {
  # `dependencies` lists pak's dependency types separated by commas, as the action passes
  # them: for example "Config/Needs/check,all".
  dependencies <- sprintf("c(%s)", paste(sprintf('"%s"', strsplit(dependencies, ",", fixed = TRUE)[[1]]),
                                         collapse = ", "))
  log_file <- tempfile(fileext = ".log")
  code <- c(
    'lib <- file.path(tempdir(), "pak"); dir.create(lib)',
    'install.packages("pak", lib = lib, repos = sprintf("https://r-lib.github.io/p/pak/stable/%s/%s/%s",',
    '                 .Platform$pkgType, R.Version()$os, R.Version()$arch))',
    'library(pak, lib.loc = lib)',
    'Sys.setenv(PKGCACHE_HTTP_VERSION = "2")',
    'print(getOption("repos"))',
    sprintf('pak::lockfile_create(c(%s), lockfile = file.path(tempdir(), "replay.lock"), upgrade = %s,',
            paste(sprintf('"%s"', refs), collapse = ", "), upgrade),
    sprintf('                     dependencies = %s)', dependencies),
    # A library of its own, so that the replay never changes the libraries R uses.
    'replay_lib <- file.path(tempdir(), "replay-lib"); dir.create(replay_lib)',
    'pak::lockfile_install(file.path(tempdir(), "replay.lock"), lib = replay_lib)'
  )
  script <- tempfile(fileext = ".R")
  writeLines(code, script)
  system2(file.path(R.home("bin"), "Rscript"), script, stdout = log_file, stderr = log_file)
  annotate("error", "Installing the dependencies failed; the replay ends",
           c(utils::tail(read_text(log_file), 40L), platform()))
}

args <- commandArgs(trailingOnly = TRUE)
if (length(args)) {
  mode <- args[1]
  if (identical(mode, "check")) {
    annotate_check(args[2])
  } else if (identical(mode, "rout")) {
    for (f in args[-1]) annotate_rout(f)
  } else if (identical(mode, "report")) {
    annotate_report(args[2], args[3])
  } else if (identical(mode, "fixture-diff")) {
    annotate_fixture_diff(args[2], args[3])
  } else if (identical(mode, "dependencies")) {
    annotate_dependencies(args[2], args[3], args[-(1:3)])
  } else if (identical(mode, "tail")) {
    n <- if (length(args) > 3) as.integer(args[4]) else 60L
    lines <- if (file.exists(args[3])) utils::tail(read_text(args[3]), n) else paste("no file", args[3])
    annotate("error", args[2], c(lines, platform()))
  } else {
    stop("unknown mode: ", mode)
  }
}
