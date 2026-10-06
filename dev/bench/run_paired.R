# Paired re-measurement of benchmark tasks (DEC-038). Every task matched by --only runs in
# fresh processes that alternate the pinned reference and the working tree (reference,
# working tree, reference, working tree, ...) for --rounds rounds, with the measurement of
# run_reference.R (harness.R). A task regresses in time when, in every round, both the
# median and the fastest run of the working tree are more than 10% above the reference's and
# the median is at least 0.05 s above it; in memory when, in every round, its peak is more
# than 10% and at least 50 MB above the reference's. Include an unchanged legacy function in
# --only as a control for the noise of the session.
#
# Usage, from the repository root:
#   Rscript dev/bench/run_paired.R --only REGEX [--rounds 2] [--lib dev/reference/lib] [--out DIR]
# Writes paired-<date>-<platform>.csv (one row per task, round, and implementation) and
# paired-<date>-<platform>.md (ratios and verdicts) to --out (default dev/bench/results).
# Exit status is 1 when a task regresses.

opts <- list(lib = "dev/reference/lib", out = "dev/bench/results", only = NULL, rounds = 2L)
args <- commandArgs(trailingOnly = TRUE)
k <- 1L
while (k <= length(args)) {
  switch(args[[k]], "--lib" = opts$lib <- args[[k + 1]], "--out" = opts$out <- args[[k + 1]],
         "--only" = opts$only <- args[[k + 1]], "--rounds" = opts$rounds <- as.integer(args[[k + 1]]),
         stop("Unknown argument: ", args[[k]], call. = FALSE))
  k <- k + 2L
}
if (is.null(opts$only)) stop("--only is required: name the tasks to re-measure.", call. = FALSE)
stopifnot(requireNamespace("callr", quietly = TRUE), requireNamespace("bench", quietly = TRUE), opts$rounds >= 1L)
source("dev/bench/scenarios.R")
source("dev/bench/harness.R")
ref_lib <- normalizePath(opts$lib, winslash = "/")
wt_lib <- bench_install_working_tree()
user_lib <- dirname(find.package("bench"))
scenarios <- bench_scenarios()
names(scenarios) <- vapply(scenarios, `[[`, character(1), "id")
tasks <- Filter(function(t) grepl(opts$only, paste(t$scenario, bench_task_id(t))), bench_tasks())
if (length(tasks) == 0L) stop("No task matches --only.", call. = FALSE)
dir.create(opts$out, recursive = TRUE, showWarnings = FALSE)

rows <- list()
for (t in tasks) {
  sc <- scenarios[[t$scenario]]
  for (round in seq_len(opts$rounds)) {
    for (implementation in c("reference", "working tree")) {
      lib <- if (identical(implementation, "reference")) ref_lib else wt_lib
      row <- bench_row(t, sc, bench_measure(sc, t, lib, ref_lib, user_lib))
      row$round <- round
      row$implementation <- implementation
      rows[[length(rows) + 1L]] <- row
      cat(sprintf("%-26s %-40s round %d %-12s %-7s %8.3f s (fastest %.3f)  peak %5.0f MB\n", t$scenario, bench_task_id(t),
                  round, implementation, row$status, row$median_s, row$min_s, row$peak_after_mb))
    }
  }
}
results <- do.call(rbind, rows)
stem <- file.path(opts$out, sprintf("paired-%s-%s", format(Sys.Date(), "%Y%m%d"), tolower(Sys.info()[["sysname"]])))
utils::write.csv(results, paste0(stem, ".csv"), row.names = FALSE)

ref <- results[results$implementation == "reference", ]
new <- results[results$implementation == "working tree", ]
pairs <- merge(ref, new, by = c("scenario", "task", "round"), suffixes = c("_ref", "_new"))
pairs$median_ratio <- pairs$median_s_new / pairs$median_s_ref
pairs$min_ratio <- pairs$min_s_new / pairs$min_s_ref
pairs$memory_ratio <- pairs$peak_after_mb_new / pairs$peak_after_mb_ref
pairs$time_slower <- pairs$median_ratio > 1.10 & pairs$min_ratio > 1.10 & (pairs$median_s_new - pairs$median_s_ref) >= 0.05
pairs$memory_higher <- pairs$memory_ratio > 1.10 & (pairs$peak_after_mb_new - pairs$peak_after_mb_ref) >= 50
verdict <- function(p) {
  time <- isTRUE(all(p$time_slower))
  memory <- isTRUE(all(p$memory_higher))
  if (time && memory) "REGRESSION (time, memory)" else if (time) "REGRESSION (time)" else if (memory) "REGRESSION (memory)" else "ok"
}
pairs <- pairs[order(pairs$scenario, pairs$task, pairs$round), ]
groups <- split(pairs, paste(pairs$scenario, pairs$task), drop = TRUE)
verdicts <- vapply(groups, verdict, character(1))
fmt <- function(x) formatC(x, digits = 3, format = "fg")
table_rows <- unlist(lapply(names(groups), function(g) {
  p <- groups[[g]]
  sprintf("| %s | %s | %d | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s |", p$scenario, p$task, p$round,
          fmt(p$median_s_ref), fmt(p$median_s_new), fmt(p$median_ratio), fmt(p$min_s_ref), fmt(p$min_s_new),
          fmt(p$min_ratio), fmt(p$peak_after_mb_ref), fmt(p$peak_after_mb_new), fmt(p$memory_ratio),
          fmt(p$gc_max_mb_ref), fmt(p$gc_max_mb_new), ifelse(p$round == max(p$round), verdicts[[g]], ""))
}))
report <- c(
  sprintf("# Paired benchmark: reference and working tree, %d round(s)", opts$rounds), "",
  sprintf("- Tasks: %d; regressions: %d.", length(groups), sum(verdicts != "ok")),
  "- Rule (DEC-038): a regression in time needs both the median and the fastest run more than 10% slower than the reference's, and the median at least 0.05 s slower, in every round; in memory, a peak more than 10% and 50 MB higher in every round.",
  "",
  "- Peak MB is the process's peak resident memory after the first run; gc max MB is gc()'s maximum of R's heap during it (Phase 8).",
  "",
  "| Scenario | Task | Round | Reference median s | New median s | Ratio | Reference fastest s | New fastest s | Ratio | Reference peak MB | New peak MB | Ratio | Reference gc max MB | New gc max MB | Verdict |",
  "|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|",
  table_rows
)
writeLines(report, paste0(stem, ".md"))
cat(sprintf("Wrote %s.csv and %s.md (%d tasks, %d regressions)\n", stem, stem, length(groups), sum(verdicts != "ok")))
if (any(verdicts != "ok")) quit(status = 1)
