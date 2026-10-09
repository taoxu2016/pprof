# The report of the paired Cox benchmark (dev/bench/cox/run_paired.R; COXPH_C2_PLAN §4.5): per
# scenario, task, and round, the fit's median and fastest times against its engine call's; the
# brief §3.7's MUST by DEC-038's rule against the engine call plus the preparation of its inputs
# (DEC-105), with the verdict against the engine call alone beside it (the C2 plan's comparator);
# the fit against coxph() on the data frame (with one cluster per row for robust, DEC-098); and
# the fits beside C1's baseline, its engine calls and pprof_py (the brief §3.7's SHOULD). From Phase C3
# (DEC-111), both sides include the measures (the fit's indirect standardization, the engine's plain-R
# expected events), and the `profile` task's measures, tests with limits, and funnel are set beside
# pprof_py's, with the brief's MUST that mid-p limits be substantially faster: at least ten times.
#
# Usage, from the repository root:
#   Rscript dev/bench/cox/summarize_paired.R <report md> <C1 engines csv> <C1 pprof_py csv> <paired csv> [...]
#     [--notes <md file>]
# Several paired CSVs are the runs of one session, for example one per group of scenarios. A later run
# that repeats a scenario and task replaces the earlier runs' rows of it, for example a task run again
# after a change to the code it times; the report names them. A notes file (Markdown) goes into the
# report after its summary, for what the measurements do not show, such as the conditions of the run.
# Exit status is 1 when a fit is too slow by DEC-105's rule, fails, or differs from its engine call.
args <- commandArgs(trailingOnly = TRUE)
notes <- character()
at <- match("--notes", args)
if (!is.na(at)) {
  notes <- c(readLines(args[[at + 1L]], encoding = "UTF-8"), "")
  args <- args[-c(at, at + 1L)]
}
if (length(args) < 4L) {
  stop(paste("Usage: Rscript dev/bench/cox/summarize_paired.R <report md> <C1 engines csv> <C1 pprof_py csv>",
             "<paired csv> ..."), call. = FALSE)
}
report <- args[[1]]
c1 <- utils::read.csv(args[[2]])
py <- utils::read.csv(args[[3]])
py_machine <- jsonlite::read_json(sub("\\.csv$", ".json", args[[3]]))
runs <- args[-(1:3)]
paired <- do.call(rbind, lapply(seq_along(runs), function(r) cbind(utils::read.csv(runs[[r]]), run = r)))
machines <- lapply(runs, function(f) jsonlite::read_json(sub("\\.csv$", ".json", f)))
last_run <- stats::ave(paired$run, paired$scenario, paired$task, FUN = max)
superseded <- unique(paste(paired$scenario, paired$task)[paired$run < last_run])
paired <- paired[paired$run == last_run, , drop = FALSE]

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
# The same rule against the engine call plus the preparation of its inputs from the data frame.
pairs$prepared_median_ratio <- pairs$median_s_fit / (pairs$median_s_engine + pairs$prep_s_engine)
pairs$prepared_min_ratio <- pairs$min_s_fit / (pairs$min_s_engine + pairs$prep_s_engine)
pairs$prepared_slower <- pairs$prepared_median_ratio > 1.10 & pairs$prepared_min_ratio > 1.10 &
  (pairs$median_s_fit - pairs$median_s_engine - pairs$prep_s_engine) >= 0.05
labels <- paste(pairs$scenario, pairs$task)
groups <- split(pairs, factor(labels, levels = unique(labels)))
verdict <- function(p, slower) {
  if (any(p$status_engine != "ok" | p$status_fit != "ok")) return("FAILED")
  if (!all(p$identical_to_engine_fit %in% TRUE)) return("ESTIMATES DIFFER")
  if (all(slower)) "TOO SLOW" else "ok"
}
verdicts <- vapply(groups, function(p) verdict(p, p$slower), character(1))
prepared_verdicts <- vapply(groups, function(p) verdict(p, p$prepared_slower), character(1))

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
profile <- paired[paired$task == "profile", , drop = FALSE]
c3 <- nrow(profile) > 0L || "expected_s" %in% names(paired)
lines <- c(
  if (c3) {
    "# Paired benchmark of the stratified Cox fit with its measures against its engine calls"
  } else {
    "# Paired benchmark of the stratified Cox fit against its engine calls"
  }, "",
  sprintf(paste("Run on %s at commit %s (`dev/bench/cox/run_paired.R`, %d round(s), package code %s from the",
                "commit): %s, %d logical cores; %s with survival %s; pprof %s installed with `--preclean`. The R",
                "engines are single-threaded."),
          paste(unique(vapply(machines, `[[`, "", "date")), collapse = " and "),
          paste0("`", commits, "`", collapse = " and "), machine$rounds,
          if (all(vapply(machines, function(m) isTRUE(m$package_code_clean), TRUE))) "unchanged" else "changed",
          machine$cpu, machine$logical_cores, machine$r, machine$packages$survival, machine$packages$pprof),
  if (length(superseded)) {
    c("", sprintf("A later run repeated, and its rows replace the earlier run's for: %s.",
                  paste(superseded, collapse = ", ")))
  },
  "",
  paste("Each round runs the engine call, `coxph()`, and the fit, each in a fresh process, one after the other, on the",
        "same data (`dev/bench/cox/scenarios.R`, C1's grid). The engine call is survival's fitter as the adapter calls",
        "it, on the inputs the adapter builds, prepared outside the timing (DEC-100); for the robust fit, the fitter",
        "followed by coxph()'s robust step with one cluster per row (DEC-099). The fit is `fit_cox_stratified()` on",
        "the data frame, with weights and an offset, from the formula to the model object. The preparation of the",
        "engine's inputs from the data frame (`data_prepare()` and the adapter's inputs) is timed in the engine's",
        "process after its measurement: the median of three calls."),
  "",
  if (c3) {
    c(paste("From Phase C3 (DEC-111), each side includes the measures: the fit side calls `standardize_providers()`",
            "on the fit, which computes each observation's expected events at the national baseline, and the engine",
            "side computes the national expected events by provider in plain R at the fitter's coefficients (C1's",
            "closed form): the brief's \"direct engine call it wraps plus the measures\"."), "")
  },
  paste("Rule (the brief's §3.7 MUST, DEC-105): a fit is too slow when, in every round, its median and its fastest",
        "run are more than 10% above the engine call's plus the preparation of its inputs, and its median at least",
        "0.05 s above (DEC-038). The verdict against the engine call alone, the C2 plan's comparator, is given beside",
        "it. The fit's estimates must equal the engine call's bitwise (coefficients, and the robust variance). Times",
        "in seconds; peak memory of the process after the first run, in MB (recorded, DEC-004)."),
  "",
  sprintf("- Fits: %d; too slow against the engine call plus the preparation of its inputs (DEC-105): %d.",
          length(verdicts), sum(prepared_verdicts == "TOO SLOW")),
  sprintf("- Too slow against the engine call alone: %d; failed or differing from the engine call: %d.",
          sum(verdicts == "TOO SLOW"), sum(verdicts %in% c("FAILED", "ESTIMATES DIFFER"))),
  "",
  notes,
  "## The fit against its engine call", "",
  paste("| Scenario | Rows | Providers | Covariates | Task | Round | Engine median | Fit median | Ratio |",
        "Engine fastest | Fit fastest | Ratio | Fit − engine, median | Peak MB, engine / fit | Estimates |",
        "Verdict against the engine call alone |"),
  "|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|"
)
for (g in names(groups)) {
  p <- groups[[g]]
  for (j in seq_len(nrow(p))) {
    lines <- c(lines, sprintf("| %s | %s | %d | %s | %s | %s | %s | %s | %s | %s | %s / %s | %s | %s |",
                              size_of(p$scenario[j]), p$task[j], p$round[j], fmt(p$median_s_engine[j]),
                              fmt(p$median_s_fit[j]), ratio(p$median_ratio[j]), fmt(p$min_s_engine[j]),
                              fmt(p$min_s_fit[j]), ratio(p$min_ratio[j]),
                              fmt(p$median_s_fit[j] - p$median_s_engine[j]), fmt(p$peak_after_mb_engine[j]),
                              fmt(p$peak_after_mb_fit[j]),
                              if (isTRUE(p$identical_to_engine_fit[j])) "identical" else "DIFFER",
                              if (j == nrow(p)) verdicts[[g]] else ""))
  }
}
lines <- c(lines, "", "## Where the fit's time goes", "",
           paste("The fit's time beyond the engine call, the preparation of the engine's inputs from the data frame,",
                 "and what is left: the adapter's own steps, the model object, and noise. The last column is the",
                 "MUST's verdict (DEC-105): DEC-038's rule against the engine call plus the preparation (medians,",
                 "and fastest runs plus the preparation)."),
           "",
           paste("| Scenario | Task | Round | Fit − engine, median | Inputs' preparation, median of 3 |",
                 "Fit − engine − preparation | Ratio, fit / (engine + preparation), medians | Fastest |",
                 "Verdict (DEC-105) |"),
           "|---|---|---|---|---|---|---|---|---|")
for (g in names(groups)) {
  p <- groups[[g]]
  for (j in seq_len(nrow(p))) {
    excess <- p$median_s_fit[j] - p$median_s_engine[j]
    lines <- c(lines, sprintf("| %s | %s | %d | %s | %s | %s | %s | %s | %s |", p$scenario[j], p$task[j], p$round[j],
                              fmt(excess), fmt(p$prep_s_engine[j]), fmt(excess - p$prep_s_engine[j]),
                              ratio(p$prepared_median_ratio[j]), ratio(p$prepared_min_ratio[j]),
                              if (j == nrow(p)) prepared_verdicts[[g]] else ""))
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
midp_verdicts <- character()
if (nrow(profile)) {
  lines <- c(lines, "", "## Measures and tests beside pprof_py's", "",
             paste("The `profile` task fits once outside the timing, then times on that fit: the expected events'",
                   "closed form (`cox_expected_events()`, which the fit itself runs), `standardize_providers()`",
                   "with both standardizations, `test_providers()` with each test followed by",
                   "`standardize_providers()` with that test's interval, and `funnel_limits()`. pprof_py's",
                   "`calculate_standardized_measures()` and `test()` compute the expected events themselves, so its",
                   "times are set beside the package's plus the expected events. Medians of the rounds' medians, in",
                   "seconds; pprof_py's are C1's, from another session, so the ratios are indicative. The brief's",
                   "§3.7 MUST: mid-p limits substantially faster than pprof_py's, read as at least ten times",
                   "(DEC-111)."),
             "",
             paste("| Scenario | Providers | Expected events | Measures | pprof_py measures | Mid-p test and limits |",
                   "pprof_py mid-p | pprof_py / package, mid-p | Exact test and limits | pprof_py exact |",
                   "Funnel | Mid-p verdict |"),
             "|---|---|---|---|---|---|---|---|---|---|---|---|")
  for (s in unique(profile$scenario)) {
    p <- profile[profile$scenario == s, , drop = FALSE]
    of <- function(column) stats::median(p[[column]])
    if (any(p$status != "ok")) {
      midp_verdicts[[s]] <- "FAILED"
      lines <- c(lines, sprintf("| %s | %s | - | - | - | - | - | - | - | - | - | FAILED |", s, format(p$providers[1])))
      next
    }
    midp_ratio <- median_of(py, s, "test_midp") / (of("expected_s") + of("midp_s"))
    midp_verdicts[[s]] <- if (is.na(midp_ratio)) "-" else if (midp_ratio >= 10) "ok" else "NOT 10 TIMES FASTER"
    lines <- c(lines, sprintf("| %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s |", s,
                              format(p$providers[1], big.mark = ","), fmt(of("expected_s")), fmt(of("measures_s")),
                              fmt(median_of(py, s, "measures")), fmt(of("midp_s")), fmt(median_of(py, s, "test_midp")),
                              if (is.na(midp_ratio)) "-" else sprintf("%.0f", midp_ratio), fmt(of("exact_s")),
                              fmt(median_of(py, s, "test_exact")), fmt(of("funnel_s")), midp_verdicts[[s]]))
  }
}
writeLines(lines, report)
cat(sprintf("wrote %s: %d fits, %d too slow (DEC-105), %d against the engine call alone, %d failed or differing\n",
            report, length(verdicts), sum(prepared_verdicts == "TOO SLOW"), sum(verdicts == "TOO SLOW"),
            sum(verdicts %in% c("FAILED", "ESTIMATES DIFFER"))))
if (length(midp_verdicts)) {
  cat(sprintf("mid-p limits: %d scenarios, %d not ten times faster than pprof_py's or failed\n", length(midp_verdicts),
              sum(midp_verdicts %in% c("NOT 10 TIMES FASTER", "FAILED"))))
}
if (any(prepared_verdicts != "ok") || any(midp_verdicts %in% c("NOT 10 TIMES FASTER", "FAILED"))) quit(status = 1)
