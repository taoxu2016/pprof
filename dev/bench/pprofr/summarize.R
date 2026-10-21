# The pprofR baseline's report (LOGISTIC_L1_PLAN §3.7; DEC-160): each task's median time on each scenario, with the
# first run's time, the runs, and the process's peak memory, from run_pprofr.R's CSV and JSON.
#
# Usage, from the repository root:
#   Rscript dev/bench/pprofr/summarize.R <report md> <baseline csv>

args <- commandArgs(trailingOnly = TRUE)
report_file <- args[[1]]
csv_file <- args[[2]]
rows <- utils::read.csv(csv_file, stringsAsFactors = FALSE)
machine <- jsonlite::read_json(sub("\\.csv$", ".json", csv_file))
scenarios <- unique(rows$scenario)
tasks <- unique(rows$task)
cell <- function(r) {
  if (!nrow(r)) return("")
  if (r$status != "ok") return(r$status)
  if (r$runs == 1) sprintf("%.3g (1 run)", r$median_s) else sprintf("%.3g", r$median_s)
}
grid <- vapply(scenarios, function(s) vapply(tasks, function(t) cell(rows[rows$scenario == s & rows$task == t, ]), ""),
               character(length(tasks)))
grid <- matrix(grid, nrow = length(tasks), dimnames = list(tasks, scenarios))
peak <- stats::aggregate(peak_after_mb ~ scenario, data = rows[rows$status == "ok", ], FUN = max)
sc <- do.call(rbind, lapply(machine$scenarios, as.data.frame))
lines <- c(
  "# pprofR benchmark baseline", "",
  sprintf(paste("Generated from `%s` by `dev/bench/pprofr/summarize.R`. Measured %s on %s, %s, %s cores (%s), at",
                "commit %s; pprofR %s (commit %s) from its isolated library, one thread."),
          basename(csv_file), machine$created, machine$r_version, machine$running, machine$cores, machine$processor,
          substr(machine$git_commit, 1, 7), machine$pprofr$version, substr(machine$pprofr$git_commit, 1, 7)), "",
  paste("Each task ran in a fresh R process (`dev/bench/pprofr/run_pprofr.R`): the median of 5 timed runs, 3 when the",
        "first took 10 s or more, and the first run alone when it took 60 s or more. Fits and other inputs were made",
        "untimed in the same process. The comparisons of Phases L2 to L4 measure pprofR again beside the package, in",
        "the same process (DEC-038); this baseline records the scale and the cost of each task."), "",
  "## Scenarios", "",
  "| Scenario | Rows | Providers | Trials a row | Covariates |", "|---|---|---|---|---|",
  sprintf("| %s | %s | %s | %s | %s |", sc$scenario, format(sc$n, big.mark = ",", scientific = FALSE, trim = TRUE),
          format(sc$m, big.mark = ",", trim = TRUE), sc$trials, sc$p),
  "", "## Median time (s)", "",
  paste0("| Task | ", paste(scenarios, collapse = " | "), " |"), paste0("|---|", strrep("---|", length(scenarios))),
  sprintf("| %s | %s |", tasks, apply(grid, 1, paste, collapse = " | ")),
  "", "## Peak memory of the process (MB), largest over the tasks", "",
  "| Scenario | Peak |", "|---|---|", sprintf("| %s | %.0f |", peak$scenario, peak$peak_after_mb),
  "", "## Tasks not run", ""
)
skipped <- rows[rows$status != "ok", ]
lines <- c(lines, if (nrow(skipped)) sprintf("- %s, %s: %s (%s).", skipped$scenario, skipped$task, skipped$status,
                                             skipped$message) else "None.")
writeLines(lines, report_file)
cat(sprintf("wrote %s\n", report_file))
