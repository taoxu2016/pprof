# Differential testing of the fitting functions and their methods against the reference
# (Phase 3 plan, "after the switch", for logistic fixed effects; Phase 4 plan, step 4, for the
# other fits): seeded random datasets; on each, the functions and methods of pprof 1.0.3 run on
# the pinned reference library in a separate R session, as the fixture generator runs them,
# and on the working tree, through the same case runner; the results are compared with the
# tolerance tiers of the fixtures.
#
# - Binary datasets vary the number and sizes of providers (some below the screening cutoff),
#   the event rate, providers with no events or only events, and the number of covariates.
#   Each gets every logistic FE function and method, and logis_firth() with logistic FE
#   methods on its object; the first ones also get logis_re() and logis_cre() with their
#   methods.
# - Linear datasets vary the number and sizes of providers (some of 2 to 4 observations), the
#   number of covariates, and the noise; the first covariate varies between providers, and
#   about half of the datasets have missing outcomes, which the CRE fits drop after the
#   within-between decomposition (D-13). Each gets linear_fe() (both provider variances),
#   linear_re(), and linear_cre(), with their methods.
#
# Usage, from the repository root:
#   Rscript validation/run-differential.R [--datasets N] [--mixed-datasets N] [--linear-datasets N] [--seed S]
#                                         [--lib dev/reference/lib] [--report FILE]
# Defaults: 30 binary datasets (the first 10 with RE and CRE fits), 15 linear datasets, seed
# 20261003, report validation/differential-report.md.
#
# Provider IDs are doubles, and every fit has at least three covariates, so that no case hits
# a defect the wrappers fix (D-19, D-27, D-28, D-29, D-30); a mismatch is reported and makes
# the exit status 1.

opts <- list(datasets = 30L, mixed = 10L, linear = 15L, seed = 20261003L, lib = "dev/reference/lib",
             report = file.path("validation", "differential-report.md"))
args <- commandArgs(trailingOnly = TRUE)
for (k in seq_len(length(args) %/% 2) * 2 - 1) {
  switch(args[[k]], "--datasets" = opts$datasets <- as.integer(args[[k + 1]]),
         "--mixed-datasets" = opts$mixed <- as.integer(args[[k + 1]]),
         "--linear-datasets" = opts$linear <- as.integer(args[[k + 1]]),
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
differential_linear_dataset <- function(k) {
  withr::with_seed(opts$seed + 500L + k, {
    m <- sample(c(15L, 25L, 40L), 1L)
    sizes <- c(sample(2:4, 2L, replace = TRUE), sample(10:60, m - 2L, replace = TRUE))
    p <- sample(3:5, 1L)
    prov <- rep(seq_len(m), sizes)
    z <- matrix(stats::rnorm(length(prov) * p), ncol = p, dimnames = list(NULL, paste0("x", seq_len(p))))
    z[, 1] <- z[, 1] + stats::rnorm(m)[prov]
    y <- 2 + stats::rnorm(m)[prov] + drop(z %*% stats::runif(p, -1, 1)) +
      stats::rnorm(length(prov), 0, sample(c(0.5, 1, 2), 1L))
    if (stats::runif(1) < 0.5) y[sample(length(y), 5L)] <- NA
    data.frame(Y = y, ProvID = as.numeric(prov), z)
  })
}
binary <- stats::setNames(lapply(seq_len(opts$datasets), differential_dataset),
                          sprintf("diff%02d", seq_len(opts$datasets)))
linear <- stats::setNames(lapply(seq_len(opts$linear), differential_linear_dataset),
                          sprintf("lin%02d", seq_len(opts$linear)))
datasets <- c(binary, linear)

# --- Cases ---------------------------------------------------------------------------------------
differential_cases <- function() {
  cases <- list()
  add <- function(id, fun, args, tier, seed = NULL) {
    cases[[id]] <<- list(id = id, set = "differential", fun = fun, args = args, seed = seed, tier = tier, heavy = FALSE)
  }
  for (name in names(binary)) {
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
    # Firth, and logistic FE methods on its object (Phase 4).
    firth <- paste0(name, "-firth")
    add(firth, "logis_firth", columns, "iterative")
    add(paste0(firth, "-exact"), "test", list(fit = ref_fit(firth), threads = 1), "iterative")
    add(paste0(firth, "-sm"), "SM_output", list(fit = ref_fit(firth), stdz = c("indirect", "direct"), threads = 1),
        "iterative")
    add(paste0(firth, "-gamma-score"), "confint", list(object = ref_fit(firth), option = "gamma", test = "score"),
        "root")
  }
  for (name in utils::head(names(binary), opts$mixed)) {
    z <- grep("^x", names(datasets[[name]]), value = TRUE)
    re <- paste0(name, "-logis-re")
    cre <- paste0(name, "-logis-cre")
    add(re, "logis_re", list(data = ref_dataset(name), Y.char = "Y", Z.char = z, ProvID.char = "ProvID"), "lme4")
    add(cre, "logis_cre", list(data = ref_dataset(name), Y.char = "Y", wb.char = "x1", other.char = z[-1],
                               ProvID.char = "ProvID"), "lme4")
    for (fit in c(re, cre)) {
      add(paste0(fit, "-test"), "test", list(fit = ref_fit(fit)), "lme4")
      add(paste0(fit, "-sm"), "SM_output",
          list(fit = ref_fit(fit), stdz = c("indirect", "direct"), measure = c("ratio", "rate"), threads = 1), "lme4")
    }
  }
  for (name in names(linear)) {
    z <- grep("^x", names(datasets[[name]]), value = TRUE)
    columns <- list(data = ref_dataset(name), Y.char = "Y", Z.char = z, ProvID.char = "ProvID")
    fe <- paste0(name, "-fe")
    add(fe, "linear_fe", columns, "closed_form")
    add(paste0(fe, "-full"), "linear_fe", c(columns, list(option.gamma.var = "full")), "closed_form")
    add(paste0(fe, "-test"), "test", list(fit = ref_fit(fe)), "closed_form")
    add(paste0(fe, "-sm"), "SM_output", list(fit = ref_fit(fe), stdz = c("indirect", "direct")), "closed_form")
    add(paste0(fe, "-confint"), "confint", list(object = ref_fit(fe), stdz = c("indirect", "direct")), "closed_form")
    add(paste0(fe, "-summary"), "summary", list(object = ref_fit(fe)), "closed_form")
    re <- paste0(name, "-re")
    cre <- paste0(name, "-cre")
    add(re, "linear_re", columns, "lme4")
    add(cre, "linear_cre", list(data = ref_dataset(name), Y.char = "Y", wb.char = "x1", other.char = z[-1],
                                ProvID.char = "ProvID"), "lme4")
    for (fit in c(re, cre)) {
      add(paste0(fit, "-test"), "test", list(fit = ref_fit(fit)), "lme4")
      add(paste0(fit, "-sm"), "SM_output", list(fit = ref_fit(fit), stdz = c("indirect", "direct")), "lme4")
      add(paste0(fit, "-confint"), "confint", list(object = ref_fit(fit), stdz = c("indirect", "direct")), "lme4")
      add(paste0(fit, "-summary"), "summary", list(object = ref_fit(fit)), "lme4")
    }
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

shapes <- vapply(names(datasets), function(name) {
  d <- datasets[[name]]
  sizes <- table(d$ProvID)
  p <- sum(startsWith(names(d), "x"))
  if (name %in% names(linear)) {
    return(sprintf("linear, n %d, m %d (%d below 5), p %d, %d missing outcomes", nrow(d), length(sizes),
                   sum(sizes < 5), p, sum(is.na(d$Y))))
  }
  sprintf("n %d, m %d (%d below 10), p %d, event rate %.2f%s", nrow(d), length(sizes), sum(sizes < 10), p, mean(d$Y),
          if (name %in% utils::head(names(binary), opts$mixed)) ", with RE and CRE fits" else "")
}, character(1))
lines <- c(
  "# Differential report: working tree versus the pprof 1.0.3 reference", "",
  sprintf("Generated %s by `validation/run-differential.R` on %s, %s.", format(Sys.time(), tz = "UTC", usetz = TRUE),
          R.version.string, utils::sessionInfo()$running),
  sprintf("Working tree at commit %s; %d binary datasets (%d with RE and CRE fits), %d linear datasets, seed %d.",
          system2("git", c("rev-parse", "--short", "HEAD"), stdout = TRUE), opts$datasets,
          min(opts$mixed, opts$datasets), opts$linear, opts$seed),
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
