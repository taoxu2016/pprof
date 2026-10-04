# Shared code of the benchmark scripts (run_reference.R, run_paired.R): task names, the
# install of the working tree, and the measurement of one task in a fresh R process.
# Source it after scenarios.R, from the repository root.

bench_task_id <- function(t) {
  extra <- if (length(t$args)) paste0("[", paste(names(t$args), vapply(t$args, function(a) paste(a, collapse = "+"), ""), sep = "=", collapse = ","), "]") else ""
  input <- if (!is.null(t$input)) paste0("<", t$input$fun, ">") else ""
  paste0(t$fun, if (isTRUE(t$method_id)) paste0(".", t$fit$fun), input, extra)
}

# The working tree installed into a temporary library, to be placed before the reference
# library, so that every other package comes from the same pinned versions as in the
# baseline (DEC-023); packages the reference does not use (such as generics) come from the
# user library. --preclean removes the compiled code in src/ first: without it the install
# reuses whatever objects are there, such as those devtools::load_all() compiles with -g -O0,
# and the benchmark measures a debug build (found at the Phase 4 gate).
bench_install_working_tree <- function() {
  lib <- normalizePath(file.path(tempdir(), "bench-working-tree"), winslash = "/", mustWork = FALSE)
  dir.create(lib, recursive = TRUE, showWarnings = FALSE)
  status <- system2(file.path(R.home("bin"), "R"), c("CMD", "INSTALL", "--preclean", "--no-docs", "--no-multiarch",
                                                       paste0("--library=", shQuote(lib)), "."))
  if (!identical(status, 0L)) stop("Installing the working tree failed.", call. = FALSE)
  normalizePath(lib, winslash = "/")
}

# One task, run in the process callr starts: the first run's time and the peak memory
# around it, then the timed runs.
bench_run_task <- function(scenario, task, pprof_lib) {
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
  generic <- function(fun) {
    switch(fun, confint = stats::confint, summary = base::summary, plot = base::plot, getExportedValue("pprof", fun))
  }
  if (!is.null(task$fit)) {
    fit <- suppressWarnings(suppressMessages(do.call(generic(task$fit$fun), c(fit_args(task$fit$fun), task$fit$args))))
    method_args <- task$args
    if (task$fun %in% c("test", "SM_output") && inherits(fit, "logis_fe")) method_args$threads <- 1
    # Tasks whose input is a method's result (Phase 6, DEC-060): the method runs untimed, and
    # its result, or one element of it, is the timed function's first argument.
    if (!is.null(task$input)) {
      fit <- suppressWarnings(suppressMessages(do.call(generic(task$input$fun), c(list(fit), task$input$args))))
      if (!is.null(task$input$element)) fit <- fit[[task$input$element]]
    }
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
  # calls, where profiling every allocation can take minutes. Profiling fails on some calls
  # ("Memory profiling failed", for example on the ggplot2 code of plot.linear_fe, in pprof
  # 1.0.3 and in the rewrite alike); those are timed without it, and their allocations are
  # missing (Phase 5).
  slow <- first >= 10
  mark <- function(memory) {
    bench::mark(quiet_call(), min_time = 1, min_iterations = if (slow) 3L else 5L, max_iterations = 200,
                check = FALSE, memory = memory, filter_gc = FALSE)
  }
  b <- tryCatch(mark(!slow), error = function(e) {
    if (!grepl("Memory profiling failed", conditionMessage(e), fixed = TRUE)) stop(e)
    NULL
  })
  profiled <- !slow && !is.null(b)
  if (is.null(b)) b <- mark(FALSE)
  times <- as.numeric(b$time[[1]])
  c(info, status = "ok", message = "", median_s = stats::median(times), min_s = min(times), max_s = max(times),
    first_s = first, runs = length(times), r_alloc_mb = if (profiled) as.numeric(b$mem_alloc) / 2^20 else NA_real_,
    peak_before_mb = before / 2^20, peak_after_mb = after / 2^20)
}

# bench_run_task() in a fresh process with `pprof_lib` first on the library path; a failure
# or a timeout is returned as the status.
bench_measure <- function(scenario, task, pprof_lib, ref_lib, user_lib) {
  tryCatch(
    callr::r(bench_run_task, args = list(scenario = scenario, task = task, pprof_lib = pprof_lib),
             libpath = unique(c(pprof_lib, ref_lib, user_lib)),
             env = c(callr::rcmd_safe_env(), OMP_THREAD_LIMIT = "1", OMP_NUM_THREADS = "1", LC_COLLATE = "C"),
             user_profile = FALSE, system_profile = FALSE, timeout = 1800),
    error = function(e) list(status = if (inherits(e, "callr_timeout_error")) "timeout" else "error",
                             message = gsub("[\r\n]+", " ", conditionMessage(e))))
}

# One row of results for task `t` on scenario `sc` from what bench_measure() returned.
bench_row <- function(t, sc, res) {
  data.frame(scenario = t$scenario, task = bench_task_id(t), outcome = sc$outcome, n_target = sc$n, m_target = sc$m, p = sc$p,
             skewed = sc$skewed, rate = if (identical(sc$outcome, "binary")) sc$rate else NA,
             n = if (is.null(res$n)) NA else res$n, m = if (is.null(res$m)) NA else res$m,
             status = res$status, median_s = if (is.null(res$median_s)) NA else res$median_s,
             min_s = if (is.null(res$min_s)) NA else res$min_s, max_s = if (is.null(res$max_s)) NA else res$max_s,
             first_s = if (is.null(res$first_s)) NA else res$first_s, runs = if (is.null(res$runs)) NA else res$runs,
             r_alloc_mb = if (is.null(res$r_alloc_mb)) NA else res$r_alloc_mb,
             peak_before_mb = if (is.null(res$peak_before_mb)) NA else res$peak_before_mb,
             peak_after_mb = if (is.null(res$peak_after_mb)) NA else res$peak_after_mb,
             message = if (is.null(res$message)) "" else substr(res$message, 1, 200), stringsAsFactors = FALSE)
}
