# The final equivalence report of the CoxPH phase (DEC-135; the CoxPH C6 plan, §3.6): the package's Cox
# models against pprof_py v0.7.0, survival, and glmnet, through the Cox fixtures (tests/testthat/fixtures/cox,
# validation/fixtures/cox), with each comparison's margin.
#
# Usage, from the repository root:
#   Rscript validation/run-cox-reference.R [report-file]
# Default report: validation/cox-equivalence-report.md.
#
# It runs the Cox reference tests (test-cox-fixtures.R, test-cox-reference.R, test-cox-penalized-reference.R,
# test-cox-fine-gray-reference.R) with NOT_CRAN set, so that the full set's comparisons run, and the
# engine-identity tests of the adapters (test-model-survival.R, test-model-glmnet.R, test-model-fine-gray.R).
# The reference tests compare through expect_cox_tier() and expect_cox_within_step()
# (tests/testthat/helper-cox-fixtures.R), which record each comparison when the option pprof.cox_comparisons
# holds an environment: its label, its tier, the ratio of the largest difference to the allowed one under the
# package's rule |a - b| <= atol + rtol * |b|, and whether a match or a difference beyond the tier was
# expected (a difference from pprof_py that a register entry decides). The report adds the calibration
# (validation/cox-calibration-report.md, from dev/reference/cox/calibrate.R) and the register's CoxPH
# entries (dev/DISCREPANCIES.md). The exit status is 1 when a test or a comparison fails.

args <- commandArgs(trailingOnly = TRUE)
report_file <- if (length(args)) args[[1]] else file.path("validation", "cox-equivalence-report.md")
Sys.setenv(NOT_CRAN = "true")
suppressMessages(devtools::load_all(quiet = TRUE))
withr::local_collate("C")

log <- new.env()
log$rows <- list()
log$near <- list()
options(pprof.cox_comparisons = log)
files <- c("cox-fixtures", "cox-reference", "cox-penalized-reference", "cox-fine-gray-reference",
           "model-survival", "model-glmnet", "model-fine-gray")
engine_files <- c("model-survival", "model-glmnet", "model-fine-gray")
started <- Sys.time()
# Each failing or erroring expectation: its file, its test, and the first line of its message.
log$failures <- list()
results <- lapply(files, function(name) {
  log$file <- paste0("test-", name, ".R")
  res <- testthat::test_local(".", filter = paste0("^", name, "$"), reporter = testthat::SilentReporter$new(),
                              stop_on_failure = FALSE, load_package = "source")
  for (test in res) {
    for (e in test$results) {
      if (inherits(e, "expectation_failure") || inherits(e, "expectation_error")) {
        first <- strsplit(conditionMessage(e), "\n", fixed = TRUE)[[1]][1]
        log$failures[[length(log$failures) + 1L]] <- data.frame(
          file = log$file, test = test$test, kind = if (inherits(e, "expectation_error")) "error" else "failure",
          message = substr(first, 1L, 300L), stringsAsFactors = FALSE)
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

rows <- if (length(log$rows)) do.call(rbind, log$rows) else
  data.frame(file = character(), label = character(), tier = character(), ratio = numeric(), expected = character())
tokens <- strsplit(rows$label, " ", fixed = TRUE)
rows$case <- vapply(tokens, `[`, "", 1L)
rows$ties <- vapply(tokens, function(t) if (length(t) > 1L && t[[2]] %in% c("breslow", "efron")) t[[2]] else "", "")
entry_of <- function(label) {
  found <- regmatches(label, regexpr("[DM]-[0-9]+", label))
  if (length(found)) found else if (grepl("timefix", label, fixed = TRUE)) "M-23" else ""
}
rows$entry <- vapply(rows$label, entry_of, "", USE.NAMES = FALSE)
rows$status <- ifelse(rows$expected == "match", ifelse(rows$ratio <= 1, "within", "FAIL"),
                      ifelse(rows$ratio > 1, "explained", "FAIL"))
near <- if (length(log$near)) do.call(rbind, log$near) else data.frame(label = character(), provider = character())

fmt <- function(x) ifelse(is.infinite(x), "Inf", sprintf("%.3g", x))
manifest_commit <- function(set) {
  path <- file.path(if (set == "core") file.path("tests", "testthat", "fixtures", "cox") else file.path("validation", "fixtures", "cox"),
                    "manifest.json")
  if (!file.exists(path)) return("absent")
  substr(jsonlite::read_json(path)$generator_commit, 1, 7)
}
version_of <- function(p) if (requireNamespace(p, quietly = TRUE)) as.character(utils::packageVersion(p)) else "absent"
failing_tests <- sum(results$failed) + sum(results$errors)
reference_results <- results[!gsub("^test-|\\.R$", "", results$file) %in% engine_files, ]
engine_results <- results[gsub("^test-|\\.R$", "", results$file) %in% engine_files, ]
fixture_commits <- unique(c(manifest_commit("core"), manifest_commit("full")))
matches <- rows[rows$expected == "match", ]
largest <- if (nrow(matches)) matches[which.max(matches$ratio), ] else NULL

lines <- c(
  "# Cox equivalence report: the package against pprof_py v0.7.0, survival, and glmnet", "",
  sprintf("Generated %s by `validation/run-cox-reference.R` on %s, %s; survival %s, glmnet %s; %.0f s.",
          format(Sys.time(), tz = "UTC", usetz = TRUE), R.version.string, utils::sessionInfo()$running,
          version_of("survival"), version_of("glmnet"), seconds),
  sprintf("Package under test: pprof %s from the working tree at commit %s.", as.character(utils::packageVersion("pprof")),
          system2("git", c("rev-parse", "--short", "HEAD"), stdout = TRUE)),
  sprintf("Fixtures: the core set (tests/testthat/fixtures/cox) and the full set (validation/fixtures/cox), generated at %s by `dev/reference/cox/generate.py` from pprof_py v0.7.0 (commit 9320766) and the pinned survival and glmnet.",
          if (length(fixture_commits) == 1L) fixture_commits else
            sprintf("%s (core) and %s (full)", manifest_commit("core"), manifest_commit("full"))),
  "", "## Summary", "",
  sprintf("- Test files: %d; tests %d, expectations %d; failed %d, errors %d, skipped %d, warnings %d.", nrow(results),
          sum(results$tests), sum(results$expectations), sum(results$failed), sum(results$errors), sum(results$skipped),
          sum(results$warnings)),
  sprintf("- Comparisons with the fixtures recorded: %d; within their tier: %d; differences beyond their tier that a register entry decides: %d; failing: %d.",
          nrow(rows), sum(rows$status == "within"), sum(rows$status == "explained"), sum(rows$status == "FAIL")),
  if (!is.null(largest)) sprintf("- Largest ratio to its tier among the comparisons expected to match: %s (%s, `%s`, %s).",
                                 fmt(largest$ratio), largest$tier, largest$label, largest$file),
  sprintf("- Providers left out of a flag comparison, within tolerance of a threshold: %d.", nrow(near)),
  "",
  "A ratio is the largest difference over the allowed one, atol + rtol |b| elementwise, with the tiers of `tests/testthat/helper-tolerances.R` (DEC-097, DEC-109, DEC-116, DEC-125); the default fits are compared with the longer of the two last Newton steps (D-57). A comparison expected to match passes at a ratio of at most 1; a difference that a register entry decides must exceed 1.",
  "", "## Test files", "",
  "| File | Tests | Expectations | Failed | Errors | Skipped | Warnings |", "|---|---|---|---|---|---|---|",
  sprintf("| `%s` | %d | %d | %d | %d | %d | %d |", results$file, results$tests, results$expectations, results$failed,
          results$errors, results$skipped, results$warnings),
  "", "## Comparisons expected to match, by file, case, and tie method", "",
  "The largest ratio to the tier in each group, and the comparison where it occurs.", "",
  "| File | Case | Ties | Tier | Comparisons | Largest ratio | At |", "|---|---|---|---|---|---|---|"
)
if (nrow(matches)) {
  groups <- split(matches, list(matches$file, matches$case, matches$ties, matches$tier), drop = TRUE, lex.order = TRUE)
  for (g in groups) {
    top <- g[which.max(g$ratio), ]
    lines <- c(lines, sprintf("| `%s` | %s | %s | %s | %d | %s | %s |", top$file, top$case, top$ties, top$tier, nrow(g),
                              fmt(top$ratio), top$label))
  }
}
differ <- rows[rows$expected == "differ", ]
lines <- c(lines, "", "## Differences from pprof_py that a register entry decides", "",
           "Each must exceed its tier: the package gives survival's result where pprof_py's differs.", "",
           "| File | Comparison | Tier | Ratio | Entry | Status |", "|---|---|---|---|---|---|",
           if (nrow(differ)) sprintf("| `%s` | %s | %s | %s | %s | %s |", differ$file, differ$label, differ$tier,
                                     fmt(differ$ratio), differ$entry, differ$status))
test_failures <- if (length(log$failures)) do.call(rbind, log$failures) else
  data.frame(file = character(), test = character(), kind = character(), message = character())
lines <- c(lines, "", "## Failing tests", "",
           "Every expectation that failed or raised an error, whether or not it records a comparison.", "",
           if (nrow(test_failures)) c("| File | Test | Kind | Message (first line) |", "|---|---|---|---|",
                                      sprintf("| `%s` | %s | %s | %s |", test_failures$file, test_failures$test,
                                              test_failures$kind, gsub("|", "\\|", test_failures$message, fixed = TRUE)))
           else "None.")
failing <- rows[rows$status == "FAIL", ]
lines <- c(lines, "", "## Failing comparisons", "",
           if (nrow(failing)) c("| File | Comparison | Tier | Ratio | Expected |", "|---|---|---|---|---|",
                                sprintf("| `%s` | %s | %s | %s | %s |", failing$file, failing$label, failing$tier,
                                        fmt(failing$ratio), failing$expected)) else "None.")
lines <- c(lines, "", "## Providers within tolerance of a flag threshold", "",
           "A provider whose flag the test changes as its expected count moves within `cox_baseline`'s allowance is left out of the comparison of flags (the CoxPH brief's §3.5; `cox_near_threshold()`).", "",
           if (nrow(near)) c("| Comparison | Provider |", "|---|---|", sprintf("| %s | %s |", near$label, near$provider)) else "None.")
lines <- c(lines, "", "## Engine identity", "",
           "The adapters against direct survival and glmnet calls on the same data, bitwise (the `cox_engine` tier), in these files' tests:", "",
           sprintf("- `%s`: %d tests, %d expectations, %d failed, %d skipped.", engine_results$file, engine_results$tests,
                   engine_results$expectations, engine_results$failed, engine_results$skipped),
           sprintf("- The reference files' tests of the installed engines and of the package's fits against direct `coxph()` calls are among the %d expectations above.",
                   sum(reference_results$expectations)))

calibration <- file.path("validation", "cox-calibration-report.md")
lines <- c(lines, "", "## The calibration", "")
if (file.exists(calibration)) {
  text <- readLines(calibration, warn = FALSE)
  result <- grep("^Result:", text, value = TRUE)
  # The rows of the calibration's table (Case, Ties, Quantity, Tier, the difference, the weakest control, OK,
  # Note) that a register entry explains: OK is "explained" and the note names the entry.
  cells <- lapply(strsplit(grep("^\\| ", text, value = TRUE), "|", fixed = TRUE), function(x) trimws(x[-1]))
  explained <- Filter(function(x) length(x) == 8L && identical(x[[7]], "explained"), cells)
  counts <- table(vapply(explained, function(x) x[[8]], ""))
  lines <- c(lines, sprintf("`validation/cox-calibration-report.md` (`dev/reference/cox/calibrate.R`, DEC-097): %s",
                            if (length(result)) paste(result, collapse = " ") else "no result line"),
             if (length(counts)) sprintf("Explained rows by register entry: %s.",
                                         paste(sprintf("%s %d", names(counts), as.vector(counts)), collapse = ", ")))
} else {
  lines <- c(lines, "The calibration report is absent.")
}

register <- file.path("dev", "DISCREPANCIES.md")
lines <- c(lines, "", "## The register's CoxPH entries", "")
if (file.exists(register)) {
  text <- readLines(register, warn = FALSE)
  start <- grep("^## The CoxPH phase", text)
  section <- character()
  if (length(start)) {
    # The CoxPH section runs to the register's next section (the logistic extensions phase's follows it).
    headings <- grep("^## ", text)
    end <- c(headings[headings > start[1]], length(text) + 1L)[[1]] - 1L
    section <- text[start[1]:end]
  }
  entries <- grep("^\\| D-[0-9]+ \\|", section, value = TRUE)
  cells <- lapply(strsplit(entries, "|", fixed = TRUE), function(x) trimws(x[-1]))
  # A Class B entry decided under the delegation, or marked awaiting, awaits a methodology owner until the register
  # records its sign-off (DEC-142 signed off the CoxPH phase's).
  awaiting <- vapply(cells, function(x) {
    grepl("B", x[[3]]) && grepl("delegation|awaiting", x[[4]]) && !grepl("signed off", x[[4]], fixed = TRUE)
  }, logical(1))
  lines <- c(lines, "From `dev/DISCREPANCIES.md`. Class B entries that await a methodology owner's sign-off are marked (M-16; the project lead signed off the CoxPH phase's on 2026-10-19, DEC-142).", "",
             "| ID | Component | Class | Status | Awaiting a methodology owner |", "|---|---|---|---|---|",
             vapply(seq_along(cells), function(k) sprintf("| %s | %s | %s | %s | %s |", cells[[k]][[1]], cells[[k]][[2]],
                                                          cells[[k]][[3]], cells[[k]][[4]], if (awaiting[[k]]) "yes" else ""), ""))
} else {
  lines <- c(lines, "The register is absent.")
}

writeLines(lines, report_file)
failed <- failing_tests > 0L || any(rows$status == "FAIL")
summary_line <- sprintf("%d comparisons: %d within their tier, %d explained, %d failing; %d test failures or errors",
                        nrow(rows), sum(rows$status == "within"), sum(rows$status == "explained"), sum(rows$status == "FAIL"),
                        failing_tests)
cat(sprintf("Wrote %s: %s\n", report_file, summary_line))
if (nzchar(Sys.getenv("GITHUB_ACTIONS"))) {
  cat(sprintf("::%s title=Cox comparisons::%s\n", if (failed) "error" else "notice", summary_line))
  # One annotation per failing test (the public API returns annotations without signing in).
  for (k in seq_len(min(nrow(test_failures), 20L))) {
    cat(sprintf("::error title=Cox test %s::%s: %s: %s\n", test_failures$kind[k], test_failures$file[k],
                test_failures$test[k], gsub("[\r\n]", " ", test_failures$message[k])))
  }
}
if (failed) quit(status = 1L)
