# Compare a benchmark run with the reference baseline (brief §3.6).
#
# Usage, from the repository root:
#   Rscript dev/bench/compare_to_baseline.R <baseline.csv> <new.csv> [--report FILE]
#
# Tasks are matched by scenario and task. Timings of one task can be bimodal (some runs
# include an expensive garbage collection), so the median alone moves by more than 10%
# between identical runs; the fastest run is stable. A task therefore regresses in time when
# both its median and its fastest run are more than 10% above the baseline's and the median
# is at least 0.05 s slower (below that, timer noise dominates); when only one of the two is
# more than 10% above, the task is marked "rerun" for a second measurement. A task regresses
# in memory when its peak process memory after the first run is more than 10% and at least
# 50 MB above the baseline. Exit status is 1 when anything regresses.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) stop("Usage: Rscript compare_to_baseline.R <baseline.csv> <new.csv> [--report FILE]", call. = FALSE)
base <- utils::read.csv(args[[1]], stringsAsFactors = FALSE)
new <- utils::read.csv(args[[2]], stringsAsFactors = FALSE)
report_file <- if (length(args) >= 4 && args[[3]] == "--report") args[[4]] else NULL

key <- c("scenario", "task")
merged <- merge(base, new, by = key, suffixes = c("_base", "_new"), all = TRUE)
merged$time_ratio <- merged$median_s_new / merged$median_s_base
merged$min_ratio <- merged$min_s_new / merged$min_s_base
merged$memory_ratio <- merged$peak_after_mb_new / merged$peak_after_mb_base
slower <- with(merged, !is.na(time_ratio) & (median_s_new - median_s_base) >= 0.05)
median_up <- !is.na(merged$time_ratio) & merged$time_ratio > 1.10
min_up <- !is.na(merged$min_ratio) & merged$min_ratio > 1.10
merged$time_regression <- slower & median_up & min_up
merged$time_rerun <- slower & xor(median_up, min_up)
merged$memory_regression <- with(merged, !is.na(memory_ratio) & memory_ratio > 1.10 & (peak_after_mb_new - peak_after_mb_base) >= 50)
merged$status <- ifelse(is.na(merged$status_base), "new task",
                 ifelse(is.na(merged$status_new), "missing in new run",
                 ifelse(merged$status_base != merged$status_new, paste(merged$status_base, "->", merged$status_new),
                 ifelse(merged$time_regression | merged$memory_regression, "REGRESSION",
                 ifelse(merged$time_rerun, "rerun", "ok")))))

fmt <- function(x, d = 3) ifelse(is.na(x), "", formatC(x, digits = d, format = "g"))
lines <- c(sprintf("# Benchmark comparison: `%s` versus baseline `%s`", basename(args[[2]]), basename(args[[1]])), "",
           sprintf("- Tasks compared: %d; regressions: %d; to rerun: %d; status changes: %d.", sum(!is.na(merged$time_ratio)),
                   sum(merged$status == "REGRESSION"), sum(merged$status == "rerun"), sum(grepl("->", merged$status))), "",
           "| Scenario | Task | Baseline median s | Baseline fastest s | New median s | New fastest s | Median ratio | Fastest ratio | Baseline peak MB | New peak MB | Status |",
           "|---|---|---|---|---|---|---|---|---|---|---|",
           sprintf("| %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s |", merged$scenario, merged$task,
                   fmt(merged$median_s_base), fmt(merged$min_s_base), fmt(merged$median_s_new), fmt(merged$min_s_new),
                   fmt(merged$time_ratio), fmt(merged$min_ratio), fmt(merged$peak_after_mb_base, 5), fmt(merged$peak_after_mb_new, 5),
                   merged$status))
if (is.null(report_file)) cat(lines, sep = "\n") else writeLines(lines, report_file)
quit(status = if (any(merged$status == "REGRESSION")) 1L else 0L)
