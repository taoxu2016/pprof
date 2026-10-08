# Loading the Cox reference fixtures (dev/reference/cox/README.md; DEC-093).
#
# A Cox fixture holds, per case, pprof_py v0.7.0's outputs and survival's and glmnet's
# (list(format_version, case, input, pprof_py, survival)). The core set ships with the tests; the
# full set lives in validation/fixtures/cox/ and is read when present. PPROF_COX_CORE and
# PPROF_COX_FULL override the directories, for checking a newly generated set before it is
# committed.

cox_fixture_dir <- function(set = "core") {
  override <- Sys.getenv(if (identical(set, "core")) "PPROF_COX_CORE" else "PPROF_COX_FULL")
  if (nzchar(override)) return(override)
  if (identical(set, "core")) return(testthat::test_path("fixtures", "cox"))
  file.path(testthat::test_path(), "..", "..", "validation", "fixtures", "cox")
}

cox_manifest <- function(set = "core") {
  path <- file.path(cox_fixture_dir(set), "manifest.json")
  if (!file.exists(path) || !requireNamespace("jsonlite", quietly = TRUE)) return(NULL)
  jsonlite::read_json(path)
}

cox_fixture <- function(id, set = "core") readRDS(file.path(cox_fixture_dir(set), paste0(id, ".rds")))

# survival's tight fit of a Cox case as the fixture generator made it (dev/reference/cox/survival.R):
# timefix = FALSE, eps 1e-11, at most 100 iterations, rows with zero weight left out.
cox_survival_tight_fit <- function(fx, ties) {
  def <- fx$case
  d <- fx$input
  if (isTRUE(def$weighted)) d <- d[d$weight > 0, , drop = FALSE]
  d$.w <- if (isTRUE(def$weighted)) d$weight else rep(1, nrow(d))
  rhs <- paste(unlist(def$features), collapse = " + ")
  if (isTRUE(def$stratified)) rhs <- paste(rhs, "+ strata(stratum)")
  if (isTRUE(def$offset)) rhs <- paste(rhs, "+ offset(offset)")
  lhs <- if (isTRUE(def$truncated)) "Surv(entry, time, event)" else "Surv(time, event)"
  # coxph() recognizes strata() by name, so the formula keeps the bare names and its environment
  # binds them to survival's functions (the package does not attach survival).
  f <- stats::as.formula(paste(lhs, "~", rhs),
                         env = list2env(list(Surv = survival::Surv, strata = survival::strata), parent = environment()))
  survival::coxph(f, data = d, weights = .w, ties = ties, robust = FALSE,
                  control = survival::coxph.control(eps = 1e-11, iter.max = 100, timefix = FALSE))
}
