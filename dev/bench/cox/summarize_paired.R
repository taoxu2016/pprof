# The report of the paired Cox benchmark (dev/bench/cox/run_paired.R; COXPH_C2_PLAN §4.5): per
# scenario, task, and round, the fit's median and fastest times against its engine call's, with
# DEC-038's verdict (the brief §3.7's MUST); the fit against coxph() on the data frame (with one
# cluster per row for robust, DEC-098); and the fits beside C1's baseline, its engine calls and
# pprof_py (the brief §3.7's SHOULD).
#
# Usage, from the repository root:
#   Rscript dev/bench/cox/summarize_paired.R <report md> <C1 engines csv> <C1 pprof_py csv> <paired csv> [...]
# Several paired CSVs are the runs of one session, for example one per group of scenarios. Exit
# status is 1 when a fit is too slow by DEC-038's rule, fails, or differs from its engine call.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 4L) {
  stop(paste("Usage: Rscript dev/bench/cox/summarize_paired.R <report md> <C1 engines csv> <C1 pprof_py csv>",
             "<paired csv> ..."), call. = FALSE)
}
report <- args[[1]]
c1 <- utils::read.csv(args[[2]])
py <- utils::read.csv(args[[3]])
py_machine <- jsonlite::read_json(sub("\\.csv$", ".json", args[[3]]))
runs <- args[-(1:3)]
paired <- do.call(rbind, lapply(runs, utils::read.csv))
machines <- lapply(runs, function(f) jsonlite::read_json(sub("\\.csv$", ".json", f)))

scenario_order <- unique(paired$scenario)
task_order <- c("breslow", "efron", "robust")
key <- c("scenario", "task", "round")
columns <- c(key, "status", "median_s", "min_s", "peak_after_mb", "prep_s", "identical_to_engine",
             "max_rel_diff_engine")
side <- function(name) paired[paired$side == name, columns]
arrange <- function(p) p[order(match(p$scenario, scenario_order), match(p$task, task_order), p$round), ]
pairs <- arrange(merge(side("engine"), side("fit"), by = key, suffixes = c("_engine", "_fit")))
pairs$median_ratio <- pairs$median_s_fit / pairs$median_s_engine
pairs$min_ratio <- pairs$min_s_fit / pairs$min_s_engine
pairs$slower <- pairs$median_ratio > 1.10 & pairs$min_ratio > 1.10 &
  (pairs$median_s_fit - pairs$median_s_engine) >= 0.05
labels <- paste(pairs$scenario, pairs$task)
groups <- split(pairs, factor(labels, levels = unique(labels)))
verdict <- function(p) {
  if (any(p$status_engine != "ok" | p$status_fit != "ok")) return("FAILED")
  if (!all(p$identical_to_engine_fit %in% TRUE)) return("ESTIMATES DIFFER")
  if (all(p$slower)) "TOO SLOW" else "ok"
}
verdicts <- vapply(groups, verdict, character(1))

fmt <- function(x) ifelse(is.na(x), "-", trimws(formatC(x, digits = 3, format = "fg")))
ratio <- function(x) ifelse(is.na(x), "-", sprintf("%.3f", x))
size <- unique(paired[, c("scenario", "n", "providers", "covariates")])
size_of <- function(s) {
  r <- size[size$scenario == s, ][1, ]
  sprintf("%s | %s | %s | %d", s, format(r$n, big.mark = ",", scientific = FALSE),
          format(r$providers, big.mark = ","), r$covariates)
}

machine <- machines[[1]]
commits <- unique(vapply(machines, function(m) substr(m$commit, 1, 7), ""))
lines <- c(
  "# Paired benchmark of the stratified Cox fit against its engine calls", "",
  sprintf(paste("Run on %s at commit %s (`dev/bench/cox/run_paired.R`, %d round(s), package code %s from the",
                "commit): %s, %d logical cores; %s with survival %s; pprof %s installed with `--preclean`. The R",
                "engines are single-threaded."),
          paste(unique(vapply(machines, `[[`, "", "date")), collapse = " and "),
          paste0("`", commits, "`", collapse = " and "), machine$rounds,
          if (all(vapply(machines, function(m) isTRUE(m$package_code_clean), TRUE))) "unchanged" else "changed",
          machine$cpu, machine$logical_cores, machine$r, machine$packages$survival, machine$packages$pprof),
  "",
  paste("Each round runs the engine call, `coxph()`, and the fit, each in a fresh process, one after the other, on the",
        "same data (`dev/bench/cox/scenarios.R`, C1's grid). The engine call is survival's fitter as the adapter calls",
        "it, on the inputs the adapter builds, prepared outside the timing (DEC-100); for the robust fit, the fitter",
        "followed by coxph()'s robust step with one cluster per row (DEC-099). The fit is `fit_cox_stratified()` on",
        "the data frame, with weights and an offset, from the formula to the model object; the preparation of the",
        "engine's inputs from the data frame (`data_prepare()` and the adapter's inputs) is timed once per round."),
  "",
  paste("Rule (DEC-038, the brief's §3.7 MUST): a fit is too slow when, in every round, its median and its fastest",
        "run are more than 10% above the engine call's and its median at least 0.05 s above. The fit's estimates must",
        "equal the engine call's bitwise (coefficients, and the robust variance). Times in seconds; peak memory of the",
        "process after the first run, in MB (recorded, DEC-004)."),
  "",
  sprintf("- Fits: %d; too slow: %d; failed or differing from the engine call: %d.", length(verdicts),
          sum(verdicts == "TOO SLOW"), sum(verdicts %in% c("FAILED", "ESTIMATES DIFFER"))),
  "",
  "## The fit against its engine call", "",
  paste("| Scenario | Rows | Providers | Covariates | Task | Round | Engine median | Fit median | Ratio |",
        "Engine fastest | Fit fastest | Ratio | Fit − engine, median | Inputs' preparation, median of 3 |",
        "Peak MB, engine / fit | Estimates | Verdict |"),
  "|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|"
)
for (g in names(groups)) {
  p <- groups[[g]]
  for (j in seq_len(nrow(p))) {
    lines <- c(lines, sprintf("| %s | %s | %d | %s | %s | %s | %s | %s | %s | %s | %s | %s / %s | %s | %s |",
                              size_of(p$scenario[j]), p$task[j], p$round[j], fmt(p$median_s_engine[j]),
                              fmt(p$median_s_fit[j]), ratio(p$median_ratio[j]), fmt(p$min_s_engine[j]),
                              fmt(p$min_s_fit[j]), ratio(p$min_ratio[j]),
                              fmt(p$median_s_fit[j] - p$median_s_engine[j]), fmt(p$prep_s_engine[j]),
                              fmt(p$peak_after_mb_engine[j]), fmt(p$peak_after_mb_fit[j]),
                              if (isTRUE(p$identical_to_engine_fit[j])) "identical" else "DIFFER",
                              if (j == nrow(p)) verdicts[[g]] else ""))
  }
}

user <- arrange(merge(side("coxph"), side("fit"), by = key, suffixes = c("_coxph", "_fit")))
if (nrow(user)) {
  lines <- c(lines, "", "## The fit against coxph() on the data frame", "",
             paste("The call a user would make: `coxph()` with the provider as strata, the offset, and the weights,",
                   "and for robust one cluster per row (C1's comparator, DEC-098; the package called it before",
                   "DEC-099). Reported, not a gate. Its estimates come from rows in the generator's order, so they",
                   "can differ from the engine call's in the last bits."),
             "",
             paste("| Scenario | Task | Round | coxph() median | Fit median | Ratio, fit / coxph() |",
                   "Peak MB, coxph() / fit | coxph()'s largest relative difference from the engine call |"),
             "|---|---|---|---|---|---|---|---|")
  for (j in seq_len(nrow(user))) {
    lines <- c(lines, sprintf("| %s | %s | %d | %s | %s | %s | %s / %s | %s |", user$scenario[j], user$task[j],
                              user$round[j], fmt(user$median_s_coxph[j]), fmt(user$median_s_fit[j]),
                              ratio(user$median_s_fit[j] / user$median_s_coxph[j]), fmt(user$peak_after_mb_coxph[j]),
                              fmt(user$peak_after_mb_fit[j]),
                              trimws(formatC(user$max_rel_diff_engine_coxph[j], digits = 2, format = "g"))))
  }
}

c1_task <- c(breslow = "survival_breslow", efron = "survival_efron", robust = "survival_robust_breslow")
py_task <- c(breslow = "coxph_breslow", efron = "coxph_efron", robust = "coxph_robust_breslow")
median_of <- function(d, scenario, task) {
  v <- d$median_s[d$scenario == scenario & d$task == task]
  if (length(v)) v[1] else NA_real_
}
lines <- c(lines, "", "## The fits beside C1's baseline", "",
           sprintf(paste("C1's engine calls (`%s`: `agreg.fit()` on the rows in the generator's order with the raw",
                         "offset, and for robust `coxph(cluster = row)`, DEC-100) and pprof_py %s on Python %s with",
                         "numba's default threads (%s, `%s`), measured in another session, so the ratios are",
                         "indicative only. The brief's §3.7 SHOULD (no slower than pprof_py) applies to the robust",
                         "variance, not to the fits at large sizes (DEC-098). The fit's time is the median of its",
                         "rounds' medians."),
                   basename(args[[2]]), py_machine$packages$pprof_py, py_machine$python,
                   paste(unique(py$numba_threads), collapse = ", "), basename(args[[3]])),
           "",
           "| Scenario | Task | Fit median | C1 engine median | pprof_py median | Ratio, fit / pprof_py |",
           "|---|---|---|---|---|---|")
for (g in names(groups)) {
  p <- groups[[g]]
  fit_median <- stats::median(p$median_s_fit)
  py_median <- median_of(py, p$scenario[1], py_task[[p$task[1]]])
  lines <- c(lines, sprintf("| %s | %s | %s | %s | %s | %s |", p$scenario[1], p$task[1], fmt(fit_median),
                            fmt(median_of(c1, p$scenario[1], c1_task[[p$task[1]]])), fmt(py_median),
                            ratio(fit_median / py_median)))
}
writeLines(lines, report)
cat(sprintf("wrote %s: %d fits, %d too slow, %d failed or differing\n", report, length(verdicts),
            sum(verdicts == "TOO SLOW"), sum(verdicts %in% c("FAILED", "ESTIMATES DIFFER"))))
if (any(verdicts != "ok")) quit(status = 1)
