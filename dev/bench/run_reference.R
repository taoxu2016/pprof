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
#     10 s, otherwise 3; and the R allocations per run (calls under 10 s only);
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
ref_lib <- normalizePath(opts$lib, winslash = "/")
# With --working-tree, the package under test is the working tree, installed into a
# temporary library placed before the reference library, so that every other package comes
# from the same pinned versions as in the baseline (DEC-023); packages the reference does not
# use (such as generics) come from the user library.
pprof_lib <- ref_lib
if (opts$working_tree) {
  pprof_lib <- normalizePath(file.path(tempdir(), "bench-working-tree"), winslash = "/", mustWork = FALSE)
  dir.create(pprof_lib, recursive = TRUE, showWarnings = FALSE)
  status <- system2(file.path(R.home("bin"), "R"), c("CMD", "INSTALL", "--no-docs", "--no-multiarch",
                                                       paste0("--library=", shQuote(pprof_lib)), "."))
  if (!identical(status, 0L)) stop("Installing the working tree failed.", call. = FALSE)
  pprof_lib <- normalizePath(pprof_lib, winslash = "/")
}
user_lib <- dirname(find.package("bench"))
source("dev/bench/scenarios.R")
scenarios <- bench_scenarios()
names(scenarios) <- vapply(scenarios, `[[`, character(1), "id")
tasks <- bench_tasks()
task_id <- function(t) {
  extra <- if (length(t$args)) paste0("[", paste(names(t$args), vapply(t$args, function(a) paste(a, collapse = "+"), ""), sep = "=", collapse = ","), "]") else ""
  paste0(t$fun, extra)
}
if (!is.null(opts$only)) tasks <- Filter(function(t) grepl(opts$only, paste(t$scenario, task_id(t))), tasks)
dir.create(opts$out, recursive = TRUE, showWarnings = FALSE)

run_task <- function(scenario, task, pprof_lib) {
  source("dev/bench/scenarios.R")
  suppressPackageStartupMessages(library(pprof))
  if (!startsWith(normalizePath(find.package("pprof"), winslash = "/"), pprof_lib)) stop("pprof is not from ", pprof_lib)
  d <- bench_data(scenario)
  sizes <- as.integer(table(d$ProvID))
  info <- list(n = nrow(d), m = length(sizes), sum_sq = sum(as.numeric(sizes)^2))
  needs_dense <- identical(task$fun, "linear_fe") || identical(task$fit$fun, "linear_fe")
  if (needs_dense && !bench_linear_fe_feasible(sizes)) {
    return(c(info, status = "skipped", message = sprintf("sum of squared provider sizes %.3g exceeds 2e7 (dense centering, B2)", info$sum_sq)))
  }
  z <- grep("^x", names(d), value = TRUE)
  fit_args <- function(fun) {
    a <- list(data = d, Y.char = "Y", ProvID.char = "ProvID")
    if (fun %in% c("linear_cre", "logis_cre")) a <- c(a, list(wb.char = z[1:2], other.char = z[-(1:2)])) else a$Z.char <- z
    if (fun %in% c("logis_fe", "logis_firth")) a <- c(a, list(message = FALSE, threads = 1))
    a
  }
  generic <- function(fun) switch(fun, confint = stats::confint, summary = base::summary, getExportedValue("pprof", fun))
  if (!is.null(task$fit)) {
    fit <- suppressWarnings(suppressMessages(do.call(generic(task$fit$fun), c(fit_args(task$fit$fun), task$fit$args))))
    method_args <- task$args
    if (task$fun %in% c("test", "SM_output") && inherits(fit, "logis_fe")) method_args$threads <- 1
    call <- function() do.call(generic(task$fun), c(list(fit), method_args))
  } else {
    call <- function() do.call(generic(task$fun), c(fit_args(task$fun), task$args))
  }
  quiet_call <- function() suppressWarnings(suppressMessages(utils::capture.output(value <- call())))
  invisible(gc())
  before <- as.numeric(bench::bench_process_memory()[["max"]])
  first <- system.time(quiet_call())[["elapsed"]]
  after <- as.numeric(bench::bench_process_memory()[["max"]])
  # Timed runs: at least 5 (and at least 1 s in total) for calls under 10 s, otherwise 3.
  # bench::mark profiles allocations in one extra, untimed run; that run is skipped for slow
  # calls, where profiling every allocation can take minutes.
  slow <- first >= 10
  b <- bench::mark(quiet_call(), min_time = 1, min_iterations = if (slow) 3L else 5L, max_iterations = 200,
                   check = FALSE, memory = !slow, filter_gc = FALSE)
  times <- as.numeric(b$time[[1]])
  c(info, status = "ok", message = "", median_s = stats::median(times), min_s = min(times), max_s = max(times),
    first_s = first, runs = length(times), r_alloc_mb = if (slow) NA_real_ else as.numeric(b$mem_alloc) / 2^20,
    peak_before_mb = before / 2^20, peak_after_mb = after / 2^20)
}

rows <- list()
for (k in seq_along(tasks)) {
  t <- tasks[[k]]
  sc <- scenarios[[t$scenario]]
  started <- Sys.time()
  res <- tryCatch(
    callr::r(run_task, args = list(scenario = sc, task = t, pprof_lib = pprof_lib),
             libpath = unique(c(pprof_lib, ref_lib, user_lib)),
             env = c(callr::rcmd_safe_env(), OMP_THREAD_LIMIT = "1", OMP_NUM_THREADS = "1", LC_COLLATE = "C"),
             user_profile = FALSE, system_profile = FALSE, timeout = 1800),
    error = function(e) list(status = if (inherits(e, "callr_timeout_error")) "timeout" else "error",
                             message = gsub("[\r\n]+", " ", conditionMessage(e))))
  row <- data.frame(scenario = t$scenario, task = task_id(t), outcome = sc$outcome, n_target = sc$n, m_target = sc$m, p = sc$p,
                    skewed = sc$skewed, rate = if (identical(sc$outcome, "binary")) sc$rate else NA,
                    n = if (is.null(res$n)) NA else res$n, m = if (is.null(res$m)) NA else res$m,
                    status = res$status, median_s = if (is.null(res$median_s)) NA else res$median_s,
                    min_s = if (is.null(res$min_s)) NA else res$min_s, max_s = if (is.null(res$max_s)) NA else res$max_s,
                    first_s = if (is.null(res$first_s)) NA else res$first_s, runs = if (is.null(res$runs)) NA else res$runs,
                    r_alloc_mb = if (is.null(res$r_alloc_mb)) NA else res$r_alloc_mb,
                    peak_before_mb = if (is.null(res$peak_before_mb)) NA else res$peak_before_mb,
                    peak_after_mb = if (is.null(res$peak_after_mb)) NA else res$peak_after_mb,
                    message = if (is.null(res$message)) "" else substr(res$message, 1, 200), stringsAsFactors = FALSE)
  rows[[k]] <- row
  cat(sprintf("[%d/%d] %-26s %-40s %-8s %8.3f s (%s runs, %.3f-%.3f)  peak %5.0f MB  (%.0f s wall)\n", k, length(tasks), t$scenario,
              task_id(t), row$status, row$median_s, row$runs, row$min_s, row$max_s, row$peak_after_mb,
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
