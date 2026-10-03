# Differential testing of the logistic fixed-effect functions against the reference (Phase 3
# plan, "after the switch"): seeded random datasets, varying the number and sizes of
# providers (some below the screening cutoff), the event rate, providers with no events or
# only events, and the number of covariates; on each, every logistic FE function and method
# of pprof 1.0.3 runs on the pinned reference library in a separate R session, as the fixture
# generator runs it, and on the working tree, through the same case runner; the results are
# compared with the tolerance tiers of the fixtures.
#
# Usage, from the repository root:
#   Rscript validation/run-differential.R [--datasets N] [--seed S] [--lib dev/reference/lib] [--report FILE]
# Defaults: 30 datasets, seed 20261003, report validation/differential-report.md.
#
# Provider IDs are doubles, and every fit has at least three covariates, so that no case hits
# a defect the wrappers fix (D-19, D-27, D-28, D-29, D-30); a mismatch is reported and makes
# the exit status 1.

opts <- list(datasets = 30L, seed = 20261003L, lib = "dev/reference/lib",
             report = file.path("validation", "differential-report.md"))
args <- commandArgs(trailingOnly = TRUE)
for (k in seq_len(length(args) %/% 2) * 2 - 1) {
  switch(args[[k]], "--datasets" = opts$datasets <- as.integer(args[[k + 1]]),
         "--seed" = opts$seed <- as.integer(args[[k + 1]]), "--lib" = opts$lib <- args[[k + 1]],
         "--report" = opts$report <- args[[k + 1]], stop("Unknown argument: ", args[[k]], call. = FALSE))
}
stopifnot(requireNamespace("callr", quietly = TRUE))
ref_lib <- normalizePath(opts$lib, winslash = "/")
runner <- normalizePath(file.path("tests", "testthat", "helper-reference-cases.R"), winslash = "/")
suppressMessages(devtools::load_all(quiet = TRUE))
for (f in c("helper-reference-cases.R", "helper-tolerances.R", "helper-equivalence.R")) {
  source(file.path("tests", "testthat", f))
}
withr::local_collate("C")

# --- Datasets ------------------------------------------------------------------------------------
differential_dataset <- function(k) {
  withr::with_seed(opts$seed + k, {
    m <- sample(c(15L, 25L, 40L), 1L)
    sizes <- c(sample(5:9, 2L, replace = TRUE), sample(15:60, m - 2L, replace = TRUE))
    p <- sample(3:5, 1L)
    intercept <- sample(c(-3, -1, 1), 1L)
    prov <- rep(seq_len(m), sizes)
    z <- matrix(stats::rnorm(length(prov) * p), ncol = p, dimnames = list(NULL, paste0("x", seq_len(p))))
    gamma <- stats::rnorm(m, 0, 0.6)
    beta <- stats::runif(p, -0.8, 0.8)
    y <- stats::rbinom(length(prov), 1, stats::plogis(intercept + gamma[prov] + drop(z %*% beta)))
    if (stats::runif(1) < 0.7) y[prov == 3L] <- 0
    if (stats::runif(1) < 0.5) y[prov == 4L] <- 1
    data.frame(Y = y, ProvID = as.numeric(prov), z)
  })
}
datasets <- stats::setNames(lapply(seq_len(opts$datasets), differential_dataset),
                            sprintf("diff%02d", seq_len(opts$datasets)))

# --- Cases ---------------------------------------------------------------------------------------
differential_cases <- function() {
  cases <- list()
  add <- function(id, fun, args, tier, seed = NULL) {
    cases[[id]] <<- list(id = id, set = "differential", fun = fun, args = args, seed = seed, tier = tier, heavy = FALSE)
  }
  for (name in names(datasets)) {
    d <- datasets[[name]]
    z <- grep("^x", names(d), value = TRUE)
    columns <- list(data = ref_dataset(name), Y.char = "Y", Z.char = z, ProvID.char = "ProvID", threads = 1)
    fit <- paste0(name, "-fit")
    add(fit, "logis_fe", columns, "iterative")
    add(paste0(name, "-fit-ban"), "logis_fe", c(columns, list(method = "BAN")), "iterative")
    add(paste0(name, "-fit-all"), "logis_fe", c(columns, list(stop = "all", tol = 1e-8)), "iterative")
    f <- ref_fit(fit)
    for (alternative in c("two.sided", "greater", "less")) {
      add(paste0(name, "-exact-", alternative), "test", list(fit = f, alternative = alternative, threads = 1),
          "iterative")
      add(paste0(name, "-score-", alternative), "test", list(fit = f, test = "score", alternative = alternative,
                                                             threads = 1), "iterative")
    }
    add(paste0(name, "-bootstrap"), "test", list(fit = f, test = "exact.bootstrap", n = 200, threads = 1), "iterative",
        seed = opts$seed + 1000L)
    add(paste0(name, "-score-standard"), "test", list(fit = f, test = "score", score_modified = FALSE, threads = 1),
        "iterative")
    add(paste0(name, "-wald"), "test", list(fit = f, test = "wald", null = 0, threads = 1), "iterative")
    add(paste0(name, "-exact-parm"), "test", list(fit = f, parm = c(3, 4, 10, 11), threads = 1), "iterative")
    add(paste0(name, "-sm"), "SM_output", list(fit = f, stdz = c("indirect", "direct"), threads = 1), "iterative")
    add(paste0(name, "-sm-null0"), "SM_output", list(fit = f, null = 0, threads = 1), "iterative")
    for (test in c("exact", "score", "wald")) {
      tier <- if (identical(test, "wald")) "iterative" else "root"
      add(paste0(name, "-gamma-", test), "confint", list(object = f, option = "gamma", test = test), tier)
      add(paste0(name, "-sm-", test), "confint", list(object = f, test = test, stdz = c("indirect", "direct")), tier)
    }
    add(paste0(name, "-sm-score-greater"), "confint", list(object = f, test = "score", stdz = c("indirect", "direct"),
                                                           alternative = "greater"), "root")
    add(paste0(name, "-sm-exact-less"), "confint", list(object = f, alternative = "less", level = 0.9), "root")
    for (test in c("wald", "lr", "score")) {
      add(paste0(name, "-summary-", test), "summary", list(object = f, test = test), "iterative")
    }
    add(paste0(name, "-plot"), "plot", list(x = f, alpha = c(0.05, 0.01)), "iterative")
  }
  cases
}
cases <- differential_cases()

# --- The reference, in an isolated child session -----------------------------------------------------
started <- Sys.time()
reference <- callr::r(function(cases, datasets, runner, ref_lib) {
  Sys.setlocale("LC_COLLATE", "C")
  suppressPackageStartupMessages(library(pprof))
  if (!startsWith(normalizePath(find.package("pprof"), winslash = "/"), ref_lib)) stop("pprof is not the reference")
  source(runner, local = TRUE)
  results <- list()
  records <- list()
  for (id in names(cases)) {
    results[[id]] <- run_reference_case(cases[[id]], datasets, results)
    records[[id]] <- reference_result_record(results[[id]], 5000L)
  }
  records
}, args = list(cases = cases, datasets = datasets, runner = runner, ref_lib = ref_lib), libpath = ref_lib,
env = c(callr::rcmd_safe_env(), LC_COLLATE = "C", OMP_THREAD_LIMIT = "1", OMP_NUM_THREADS = "1"),
user_profile = FALSE, system_profile = FALSE, show = FALSE)
reference_seconds <- as.numeric(difftime(Sys.time(), started, units = "secs"))

# --- The working tree, and the comparison ---------------------------------------------------------------
started <- Sys.time()
results <- list()
rows <- list()
for (id in names(cases)) {
  case <- cases[[id]]
  results[[id]] <- run_reference_case(case, datasets, results)
  actual <- reference_result_record(results[[id]], 5000L)
  expected <- reference[[id]]
  status <- "match"
  detail <- ""
  if (!identical(actual$outcome, expected$outcome)) {
    status <- "MISMATCH"
    detail <- sprintf("outcome %s, reference %s%s", actual$outcome, expected$outcome,
                      if (!is.null(expected$error)) paste0(" (", expected$error$message, ")") else "")
  } else if (identical(expected$outcome, "value")) {
    if (!is.na(expected$iterations) && !identical(actual$iterations, expected$iterations)) {
      status <- "MISMATCH"
      detail <- sprintf("%s iterations, reference %s", actual$iterations, expected$iterations)
    }
    level <- if (!is.null(case$args$level)) case$args$level else 0.95
    diffs <- reference_compare(actual$value, expected$value, reference_tolerance(case$tier), alpha = 1 - level)
    failures <- if (!is.null(diffs)) diffs[diffs$kind != "flag_boundary", , drop = FALSE] else NULL
    if (!is.null(failures) && nrow(failures)) {
      status <- "MISMATCH"
      detail <- paste(sprintf("%s [%s] %s", failures$path, failures$kind, failures$detail), collapse = "; ")
    } else if (!is.null(diffs) && nrow(diffs)) {
      detail <- sprintf("%d flag(s) within tolerance of a threshold", nrow(diffs))
    }
    if (identical(status, "match")) {
      if (identical(actual$value, expected$value)) {
        detail <- "identical"
      } else if (!nzchar(detail)) {
        # Within tolerance but not bitwise: name the elements that differ.
        exact <- reference_compare(actual$value, expected$value, reference_tolerance("exact"))
        detail <- paste("within tolerance:", paste(unique(exact$path), collapse = ", "))
      }
    }
  }
  rows[[id]] <- data.frame(id = id, fun = case$fun, tier = case$tier, outcome = expected$outcome, status = status,
                           detail = substr(detail, 1, 300), stringsAsFactors = FALSE)
}
working_seconds <- as.numeric(difftime(Sys.time(), started, units = "secs"))
table <- do.call(rbind, rows)

shapes <- vapply(datasets, function(d) {
  sizes <- table(d$ProvID)
  sprintf("n %d, m %d (%d below 10), p %d, event rate %.2f", nrow(d), length(sizes), sum(sizes < 10),
          sum(startsWith(names(d), "x")), mean(d$Y))
}, character(1))
lines <- c(
  "# Differential report: working tree versus the pprof 1.0.3 reference", "",
  sprintf("Generated %s by `validation/run-differential.R` on %s, %s.", format(Sys.time(), tz = "UTC", usetz = TRUE),
          R.version.string, utils::sessionInfo()$running),
  sprintf("Working tree at commit %s; %d datasets from seed %d.",
          system2("git", c("rev-parse", "--short", "HEAD"), stdout = TRUE), opts$datasets, opts$seed),
  "", "## Summary", "",
  sprintf("- Cases: %d; matching: %d; identical: %d; mismatching: %d.", nrow(table), sum(table$status == "match"),
          sum(table$detail == "identical"), sum(table$status == "MISMATCH")),
  sprintf("- Reference errors reproduced: %d.", sum(table$outcome == "error" & table$status == "match")),
  sprintf("- Time: reference %.0f s, working tree %.0f s.", reference_seconds, working_seconds),
  "", "## Datasets", "", sprintf("- `%s`: %s", names(shapes), shapes),
  "", "## Cases", "", "| Case | Function | Tier | Reference outcome | Status | Detail |", "|---|---|---|---|---|---|",
  sprintf("| `%s` | %s | %s | %s | %s | %s |", table$id, table$fun, table$tier, table$outcome, table$status,
          gsub("|", "\\|", table$detail, fixed = TRUE))
)
writeLines(lines, opts$report)
cat(sprintf("Wrote %s: %d cases, %d matching (%d identical), %d mismatching\n", opts$report, nrow(table),
            sum(table$status == "match"), sum(table$detail == "identical"), sum(table$status == "MISMATCH")))
if (any(table$status == "MISMATCH")) quit(status = 1L)
