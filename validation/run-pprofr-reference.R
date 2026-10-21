# The equivalence report of the logistic extensions phase (DEC-152, DEC-159; LOGISTIC_L1_PLAN §3.5): the package
# against pprofR 0.2.0 (commit f23c288), through the pprofR fixtures (validation/fixtures/pprofr), with each
# comparison's margin.
#
# Usage, from the repository root:
#   Rscript validation/run-pprofr-reference.R [report-file]
# Default report: validation/pprofr-equivalence-report.md.
#
# It runs the pprofR reference tests (test-pprofr-reference.R) with NOT_CRAN set. They compare through
# expect_pprofr_tier() (tests/testthat/helper-pprofr-fixtures.R), which records each comparison when the option
# pprof.pprofr_comparisons holds an environment: its label, its tier, the ratio of the largest difference to the
# allowed one under the package's rule |a - b| <= atol + rtol * |b|, and whether a match or a difference beyond the
# tier was expected (a difference from pprofR that a register entry decides). The report adds the calibration
# (validation/pprofr-calibration-report.md, from dev/reference/pprofr/calibrate.R) and the register's entries of
# the phase (dev/DISCREPANCIES.md). The exit status is 1 when a test or a comparison fails.

args <- commandArgs(trailingOnly = TRUE)
report_file <- if (length(args)) args[[1]] else file.path("validation", "pprofr-equivalence-report.md")
Sys.setenv(NOT_CRAN = "true")
suppressMessages(devtools::load_all(quiet = TRUE))
withr::local_collate("C")

log <- new.env()
log$rows <- list()
log$near <- list()
log$failures <- list()
options(pprof.pprofr_comparisons = log)
files <- c("pprofr-reference")
started <- Sys.time()
results <- lapply(files, function(name) {
  log$file <- paste0("test-", name, ".R")
  res <- testthat::test_local(".", filter = paste0("^", name, "$"), reporter = testthat::SilentReporter$new(),
                              stop_on_failure = FALSE, load_package = "source")
  for (test in res) {
    for (e in test$results) {
      kinds <- c(error = "expectation_error", skip = "expectation_skip", failure = "expectation_failure")
      kind <- names(kinds)[vapply(kinds, function(k) inherits(e, k), logical(1))][1]
      if (!is.na(kind)) {
        first <- strsplit(conditionMessage(e), "\n", fixed = TRUE)[[1]][1]
        log$failures[[length(log$failures) + 1L]] <- data.frame(file = log$file, test = test$test, kind = kind,
                                                                message = substr(first, 1L, 300L),
                                                                stringsAsFactors = FALSE)
      }
    }
  }
  df <- as.data.frame(res)
  data.frame(file = paste0("test-", name, ".R"), tests = nrow(df), expectations = sum(df$nb),
             failed = sum(df$failed), errors = sum(df$error), skipped = sum(df$skipped), warnings = sum(df$warning),
             stringsAsFactors = FALSE)
})
results <- do.call(rbind, results)
seconds <- as.numeric(difftime(Sys.time(), started, units = "secs"))

rows <- if (length(log$rows)) {
  do.call(rbind, log$rows)
} else {
  data.frame(file = character(), label = character(), tier = character(), ratio = numeric(), expected = character(),
             entry = character())
}
rows$case <- vapply(strsplit(rows$label, " ", fixed = TRUE), `[`, "", 1L)
rows$status <- ifelse(rows$expected == "match", ifelse(rows$ratio <= 1, "within", "FAIL"),
                      ifelse(rows$ratio > 1, "explained", "FAIL"))
near <- if (length(log$near)) do.call(rbind, log$near) else data.frame(label = character(), provider = character())
failures <- if (length(log$failures)) {
  do.call(rbind, log$failures)
} else {
  data.frame(file = character(), test = character(), kind = character(), message = character())
}

fmt <- function(x) ifelse(is.infinite(x), "Inf", sprintf("%.3g", x))
manifest_path <- file.path("validation", "fixtures", "pprofr", "manifest.json")
manifest <- if (file.exists(manifest_path)) jsonlite::read_json(manifest_path) else NULL
failing_tests <- sum(results$failed) + sum(results$errors)
matches <- rows[rows$expected == "match", ]
largest <- if (nrow(matches)) matches[which.max(matches$ratio), ] else NULL

lines <- c(
  "# pprofR equivalence report: the package against pprofR 0.2.0", "",
  sprintf("Generated %s by `validation/run-pprofr-reference.R` on %s, %s; %.0f s.",
          format(Sys.time(), tz = "UTC", usetz = TRUE), R.version.string, utils::sessionInfo()$running, seconds),
  sprintf("Package under test: pprof %s from the working tree at commit %s.",
          as.character(utils::packageVersion("pprof")),
          system2("git", c("rev-parse", "--short", "HEAD"), stdout = TRUE)),
  if (is.null(manifest)) "Fixtures: absent (validation/fixtures/pprofr)." else
    sprintf(paste("Fixtures: validation/fixtures/pprofr, %d cases, generated at %s by",
                  "`dev/reference/pprofr/generate.R` from pprofR %s (commit %s) on %s."),
            length(manifest$cases), substr(manifest$generator$git_commit, 1, 7), manifest$reference$version,
            substr(manifest$reference$git_commit, 1, 7), manifest$session$r_version),
  "", "## Summary", "",
  sprintf("- Test files: %d; tests %d, expectations %d; failed %d, errors %d, skipped %d, warnings %d.", nrow(results),
          sum(results$tests), sum(results$expectations), sum(results$failed), sum(results$errors), sum(results$skipped),
          sum(results$warnings)),
  sprintf(paste("- Comparisons with the fixtures recorded: %d; within their tier: %d; differences beyond their tier",
                "that a register entry decides: %d; failing: %d."),
          nrow(rows), sum(rows$status == "within"), sum(rows$status == "explained"), sum(rows$status == "FAIL")),
  if (!is.null(largest)) sprintf("- Largest ratio to its tier among the comparisons expected to match: %s (%s, `%s`).",
                                 fmt(largest$ratio), largest$tier, largest$label),
  sprintf("- Providers left out of a flag comparison, within tolerance of a threshold: %d.", nrow(near)),
  "",
  paste("A ratio is the largest difference over the allowed one, atol + rtol |b| elementwise, with the tiers of",
        "`tests/testthat/helper-tolerances.R` as `tests/testthat/helper-pprofr-fixtures.R` applies them",
        "(LOGISTIC_L1_PLAN §3.4; DEC-158). A comparison expected to match passes at a ratio of at most 1; a difference",
        "that a register entry decides must exceed 1. From Phase L1 the comparisons cover binary outcomes, which the",
        "package computes already; later phases add binomial outcomes, clusters, and the extensions of",
        "standardization."),
  "", "## Test files", "",
  "| File | Tests | Expectations | Failed | Errors | Skipped | Warnings |", "|---|---|---|---|---|---|---|",
  sprintf("| `%s` | %d | %d | %d | %d | %d | %d |", results$file, results$tests, results$expectations, results$failed,
          results$errors, results$skipped, results$warnings),
  "", "## Comparisons expected to match, by case and tier", "",
  "The largest ratio to the tier in each group, and the comparison where it occurs.", "",
  "| Case | Tier | Comparisons | Largest ratio | At |", "|---|---|---|---|---|"
)
if (nrow(matches)) {
  groups <- split(matches, list(matches$case, matches$tier), drop = TRUE, lex.order = TRUE)
  for (g in groups) {
    top <- g[which.max(g$ratio), ]
    lines <- c(lines, sprintf("| %s | %s | %d | %s | %s |", top$case, top$tier, nrow(g), fmt(top$ratio), top$label))
  }
}
differ <- rows[rows$expected == "differ", ]
lines <- c(lines, "", "## Differences from pprofR that a register entry decides", "",
           "Each must exceed its tier: the package keeps its convention where pprofR's differs (the brief's §3.3).", "",
           if (nrow(differ)) c("| Comparison | Tier | Ratio | Entry | Status |", "|---|---|---|---|---|",
                               sprintf("| %s | %s | %s | %s | %s |", differ$label, differ$tier, fmt(differ$ratio),
                                       differ$entry, differ$status)) else "None.")
lines <- c(lines, "", "## Failing and skipped tests", "",
           "Every expectation that failed, raised an error, or was skipped, whether or not it records a comparison.",
           "",
           if (nrow(failures)) c("| File | Test | Kind | Message (first line) |", "|---|---|---|---|",
                                 sprintf("| `%s` | %s | %s | %s |", failures$file, failures$test, failures$kind,
                                         gsub("|", "\\|", failures$message, fixed = TRUE))) else "None.")
failing <- rows[rows$status == "FAIL", ]
lines <- c(lines, "", "## Failing comparisons", "",
           if (nrow(failing)) c("| Comparison | Tier | Ratio | Expected |", "|---|---|---|---|",
                                sprintf("| %s | %s | %s | %s |", failing$label, failing$tier, fmt(failing$ratio),
                                        failing$expected)) else "None.")
lines <- c(lines, "", "## Providers within tolerance of a flag threshold", "",
           paste("A provider whose pprofR p-value lies within the probability tier of the test's level is left out of",
                 "the comparison of flags (the brief's §3.5; `pprofr_near_threshold()`)."), "",
           if (nrow(near)) {
             c("| Comparison | Provider |", "|---|---|", sprintf("| %s | %s |", near$label, near$provider))
           } else {
             "None."
           })

calibration <- file.path("validation", "pprofr-calibration-report.md")
lines <- c(lines, "", "## The calibration", "")
if (file.exists(calibration)) {
  result <- grep("^Result:", readLines(calibration, warn = FALSE), value = TRUE)
  source_line <- "`validation/pprofr-calibration-report.md` (`dev/reference/pprofr/calibrate.R`, DEC-158)"
  outcome <- if (length(result)) paste(result, collapse = " ") else "no result line"
  lines <- c(lines, sprintf("%s: %s", source_line, outcome))
} else {
  lines <- c(lines, "The calibration report is absent.")
}

# The register's entries of the phase: its section of dev/DISCREPANCIES.md, to the next section.
register <- file.path("dev", "DISCREPANCIES.md")
lines <- c(lines, "", "## The register's entries of the logistic extensions phase", "")
if (file.exists(register)) {
  text <- readLines(register, warn = FALSE)
  start <- grep("^## The logistic extensions phase", text)
  section <- character()
  if (length(start)) {
    headings <- grep("^## ", text)
    end <- c(headings[headings > start[1]], length(text) + 1L)[[1]] - 1L
    section <- text[start[1]:end]
  }
  entries <- grep("^\\| D-[0-9]+ \\|", section, value = TRUE)
  cells <- lapply(strsplit(entries, "|", fixed = TRUE), function(x) trimws(x[-1]))
  lines <- c(lines, "From `dev/DISCREPANCIES.md`.", "", "| ID | Component | Class | Status |", "|---|---|---|---|",
             vapply(cells, function(x) sprintf("| %s | %s | %s | %s |", x[[1]], x[[2]], x[[3]], x[[4]]), ""))
} else {
  lines <- c(lines, "The register is absent.")
}

writeLines(lines, report_file)
failed <- failing_tests > 0L || any(rows$status == "FAIL")
summary_line <- sprintf("%d comparisons: %d within their tier, %d explained, %d failing; %d test failures or errors",
                        nrow(rows), sum(rows$status == "within"), sum(rows$status == "explained"),
                        sum(rows$status == "FAIL"), failing_tests)
cat(sprintf("Wrote %s: %s\n", report_file, summary_line))
if (nzchar(Sys.getenv("GITHUB_ACTIONS"))) {
  cat(sprintf("::%s title=pprofR comparisons::%s\n", if (failed) "error" else "notice", summary_line))
  # One annotation per failing test (the public API returns annotations without signing in).
  failing_rows <- failures[failures$kind != "skip", ]
  for (k in seq_len(min(nrow(failing_rows), 20L))) {
    cat(sprintf("::error title=pprofR test %s::%s: %s: %s\n", failing_rows$kind[k], failing_rows$file[k],
                failing_rows$test[k], gsub("[\r\n]", " ", failing_rows$message[k])))
  }
}
if (failed) quit(status = 1L)
