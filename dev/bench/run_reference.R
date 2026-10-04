# Benchmark baseline for the reference implementation (brief §3.6), and the same measurements
# of the working tree.
#
# Usage, from the repository root:
#   Rscript dev/bench/run_reference.R [--lib dev/reference/lib] [--out dev/bench/results] [--only REGEX]
#     [--working-tree]
#
# With --working-tree, the working tree is installed into a temporary library placed before
# the reference library, and the results go to working-tree-<date>-<platform>.csv, for
# compare_to_baseline.R (DEC-023).
#
# Every task (a function on a scenario from scenarios.R) runs in a fresh R process whose
# library path puts the pinned reference library first, so pprof 1.0.3 and its whole
# dependency stack come from there; the bench package (measurement only) comes from the user
# library. Each process records:
#   - the elapsed time of a first run, then the median, minimum, and maximum of timed runs
#     with bench::mark(min_time = 1): at least 5 runs for calls whose first run takes under
#     10 s, otherwise 3; and the R allocations per run (calls under 10 s only, and missing
#     where bench's memory profiling fails);
#   - peak resident memory of the process before and after the first run
#     (bench::bench_process_memory()), so the increase is a lower bound for the call's peak.
# Results are assigned, never printed, inside the timed expressions.
# Methods (test, SM_output, confint, summary) are timed on a fit made beforehand in the
# same process, outside the timing. Configurations that cannot run on this machine are
# recorded as skipped with the reason, not dropped.

opts <- list(lib = "dev/reference/lib", out = "dev/bench/results", only = NULL, working_tree = FALSE)
args <- commandArgs(trailingOnly = TRUE)
k <- 1L
while (k <= length(args)) {
  if (identical(args[[k]], "--working-tree")) {
    opts$working_tree <- TRUE
    k <- k + 1L
    next
  }
  switch(args[[k]], "--lib" = opts$lib <- args[[k + 1]], "--out" = opts$out <- args[[k + 1]],
         "--only" = opts$only <- args[[k + 1]], stop("Unknown argument: ", args[[k]], call. = FALSE))
  k <- k + 2L
}
stopifnot(requireNamespace("callr", quietly = TRUE), requireNamespace("bench", quietly = TRUE),
          requireNamespace("jsonlite", quietly = TRUE))
source("dev/bench/scenarios.R")
source("dev/bench/harness.R")
ref_lib <- normalizePath(opts$lib, winslash = "/")
# With --working-tree, the package under test is the working tree, installed into a
# temporary library placed before the reference library (bench_install_working_tree()).
pprof_lib <- if (opts$working_tree) bench_install_working_tree() else ref_lib
user_lib <- dirname(find.package("bench"))
scenarios <- bench_scenarios()
names(scenarios) <- vapply(scenarios, `[[`, character(1), "id")
tasks <- bench_tasks()
if (!is.null(opts$only)) tasks <- Filter(function(t) grepl(opts$only, paste(t$scenario, bench_task_id(t))), tasks)
dir.create(opts$out, recursive = TRUE, showWarnings = FALSE)

rows <- list()
for (k in seq_along(tasks)) {
  t <- tasks[[k]]
  sc <- scenarios[[t$scenario]]
  started <- Sys.time()
  row <- bench_row(t, sc, bench_measure(sc, t, pprof_lib, ref_lib, user_lib))
  rows[[k]] <- row
  cat(sprintf("[%d/%d] %-26s %-40s %-8s %8.3f s (%s runs, %.3f-%.3f)  peak %5.0f MB  (%.0f s wall)\n", k, length(tasks), t$scenario,
              bench_task_id(t), row$status, row$median_s, row$runs, row$min_s, row$max_s, row$peak_after_mb,
              as.numeric(difftime(Sys.time(), started, units = "secs"))))
}
results <- do.call(rbind, rows)
stamp <- format(Sys.Date(), "%Y%m%d")
platform <- tolower(Sys.info()[["sysname"]])
csv <- file.path(opts$out, sprintf("%s-%s-%s.csv", if (opts$working_tree) "working-tree" else "reference-baseline",
                                   stamp, platform))
utils::write.csv(results, csv, row.names = FALSE)
env <- list(
  created = format(Sys.time(), tz = "UTC", usetz = TRUE), r_version = R.version.string, platform = R.version$platform,
  os = utils::sessionInfo()$running, cpu = Sys.getenv("PROCESSOR_IDENTIFIER"), cores = parallel::detectCores(),
  ram_gb = tryCatch(round(ps::ps_system_memory()$total / 2^30, 1), error = function(e) NA),
  blas = utils::sessionInfo()$BLAS, lapack = La_library(), lapack_version = La_version(),
  reference_library_lock_md5 = unname(tools::md5sum("dev/reference/library-lock.json")),
  threads = 1, timing = "first run, then the median of timed runs with bench::mark(min_time = 1): at least 5 runs for calls under 10 s, otherwise 3",
  memory = "peak resident set size of a fresh process (bench::bench_process_memory), before and after the first run"
)
jsonlite::write_json(env, sub("\\.csv$", ".json", csv), auto_unbox = TRUE, pretty = TRUE)
cat(sprintf("Wrote %s (%d tasks: %d ok, %d skipped, %d failed)\n", csv, nrow(results), sum(results$status == "ok"),
            sum(results$status == "skipped"), sum(!results$status %in% c("ok", "skipped"))))
