# The Cox benchmark baseline's report: the engines' and pprof_py's medians side by side per scenario,
# and the targets the package's Cox functions are measured against (CoxPH brief §3.7).
#
# Usage, from the repository root:
#   Rscript dev/bench/cox/summarize.R <engines csv> <pprof_py csv> <report md>
args <- commandArgs(trailingOnly = TRUE)
engines <- utils::read.csv(args[[1]])
py <- utils::read.csv(args[[2]])
report <- args[[3]]
machine <- jsonlite::read_json(sub("\\.csv$", ".json", args[[1]]))
py_machine <- jsonlite::read_json(sub("\\.csv$", ".json", args[[2]]))

median_of <- function(d, scenario, task) {
  v <- d$median_s[d$scenario == scenario & d$task == task]
  if (length(v) && !is.na(v)) v else NA_real_
}
peak_of <- function(d, scenario, task) {
  v <- d$peak_after_mb[d$scenario == scenario & d$task == task]
  if (length(v) && !is.na(v)) v else NA_real_
}
fmt <- function(x, digits = 2) ifelse(is.na(x), "-", formatC(x, format = "f", digits = digits))
scenarios <- unique(engines[, c("scenario", "n", "providers", "covariates")])

lines <- c(
  "# Cox benchmark baseline", "",
  sprintf("Run on %s at commit `%s` (`dev/bench/cox/`): %s, %d logical cores; %s with survival %s and glmnet %s;",
          machine$date, substr(machine$commit, 1, 7), machine$cpu, machine$logical_cores, machine$r,
          machine$packages$survival, machine$packages$glmnet),
  sprintf("pprof_py %s on Python %s with numba's default threads (%s). Medians in seconds; peak memory of the",
          py_machine$packages$pprof_py, py_machine$python, paste(unique(py$numba_threads), collapse = ", ")),
  "process after the first run, in MB. The R engines are single-threaded.", "",
  "## Fits", "",
  paste("| Scenario | Rows | Providers | Covariates | agreg.fit Breslow | agreg.fit Efron | coxph() robust |",
        "pprof_py Breslow | pprof_py Efron | pprof_py robust | Peak MB, engine / pprof_py |"),
  "|---|---|---|---|---|---|---|---|---|---|---|"
)
for (i in seq_len(nrow(scenarios))) {
  s <- scenarios$scenario[i]
  lines <- c(lines, sprintf("| %s | %s | %s | %d | %s | %s | %s | %s | %s | %s | %s / %s |", s,
                            format(scenarios$n[i], big.mark = ",", scientific = FALSE),
                            format(scenarios$providers[i], big.mark = ","), scenarios$covariates[i],
                            fmt(median_of(engines, s, "survival_breslow")), fmt(median_of(engines, s, "survival_efron")),
                            fmt(median_of(engines, s, "survival_robust_breslow")), fmt(median_of(py, s, "coxph_breslow")),
                            fmt(median_of(py, s, "coxph_efron")), fmt(median_of(py, s, "coxph_robust_breslow")),
                            fmt(peak_of(engines, s, "survival_breslow"), 0), fmt(peak_of(py, s, "coxph_breslow"), 0)))
}
lines <- c(lines, "", "## Measures and tests", "",
           paste("| Scenario | Providers | Expected counts, R closed form | pprof_py measures (indirect and direct) |",
                 "pprof_py mid-p test with limits | pprof_py exact test with limits |"),
           "|---|---|---|---|---|---|")
for (i in seq_len(nrow(scenarios))) {
  s <- scenarios$scenario[i]
  lines <- c(lines, sprintf("| %s | %s | %s | %s | %s | %s |", s, format(scenarios$providers[i], big.mark = ","),
                            fmt(median_of(engines, s, "expected_counts"), 3), fmt(median_of(py, s, "measures"), 3),
                            fmt(median_of(py, s, "test_midp")), fmt(median_of(py, s, "test_exact"), 3)))
}
pen <- scenarios$scenario[scenarios$scenario %in% engines$scenario[engines$task == "glmnet_path"]]
lines <- c(lines, "", "## Penalized paths (lasso, 100 lambda values)", "",
           "| Scenario | glmnet path (thresh 1e-12) | glmnet 10-fold CV | pprof_py path | pprof_py 10-fold CV |",
           "|---|---|---|---|---|",
           vapply(pen, function(s) {
             sprintf("| %s | %s | %s | %s | %s |", s, fmt(median_of(engines, s, "glmnet_path")),
                     fmt(median_of(engines, s, "glmnet_cv")), fmt(median_of(py, s, "penalized_path")),
                     fmt(median_of(py, s, "penalized_cv")))
           }, ""),
           "", "## Targets for the package (CoxPH brief §3.7)", "",
           paste("- A Cox fit is at most 10% slower than the engine call it wraps (the `agreg.fit` and `coxph()`",
                 "columns), measured in the same session with dev/bench/run_paired.R's pairing (DEC-038)."),
           "- The measures should cost about what the R closed form costs, a fraction of the fit, and no more than pprof_py's.",
           "- Mid-p limits must be substantially faster than pprof_py's (the mid-p column).",
           "- Peak memory is recorded with every timing; objects stay compact (DEC-004).")
notes <- character()
failed <- engines$status != "ok"
if (any(failed)) notes <- paste0("- ", engines$scenario[failed], " ", engines$task[failed], ": ", engines$status[failed])
# A run of some pprof_py tasks with one numba thread, when present, separates threads from algorithm.
one_thread_file <- sub("\\.csv$", "-1thread.csv", args[[2]])
if (file.exists(one_thread_file)) {
  one <- utils::read.csv(one_thread_file)
  notes <- c(notes, sprintf("- pprof_py with one numba thread (`%s`): %s.", basename(one_thread_file),
                            paste(sprintf("%s %s %s s (%s s with %d threads)", one$scenario, one$task, fmt(one$median_s),
                                          fmt(mapply(median_of, list(py), one$scenario, one$task)),
                                          max(py$numba_threads)), collapse = "; ")))
}
if (length(notes)) lines <- c(lines, "", "## Notes", "", notes)
writeLines(lines, report)
cat("wrote", report, "\n")
