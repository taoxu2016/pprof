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

# --- The package's fits of the Cox cases (Phase C2) ----------------------------------------------

# A case's input with the provider column of the package's fits: the stratum for stratified cases
# and one provider for the others, whose fits are then pprof_py's unstratified fits.
cox_case_data <- function(fx) {
  d <- fx$input
  d$.provider <- if (isTRUE(fx$case$stratified)) d$stratum else 0L
  # The clusters of the generator's clustered robust variances (dev/reference/cox/survival.R).
  d$.cluster <- if ("cluster" %in% names(d)) d$cluster else d$id %% 40
  d
}

# The formula of a case for fit_cox_stratified(): the response of its type, its features, and its
# offset.
cox_case_formula <- function(fx) {
  def <- fx$case
  rhs <- paste(unlist(def$features), collapse = " + ")
  if (isTRUE(def$offset)) rhs <- paste(rhs, "+ offset(offset)")
  lhs <- if (isTRUE(def$truncated)) "Surv(entry, time, event)" else "Surv(time, event)"
  stats::as.formula(paste(lhs, "~", rhs), env = list2env(list(Surv = survival::Surv), parent = globalenv()))
}

# The package's fit of a case at the generator's default or tight control (dev/reference/cox/survival.R:
# eps 1e-9 and 20 iterations, or eps 1e-11 and 100 iterations).
cox_case_fit <- function(fx, ties, tight = FALSE, ...) {
  fit_cox_stratified(cox_case_formula(fx), cox_case_data(fx), provider = ".provider",
                     weights = if (isTRUE(fx$case$weighted)) "weight", ties = ties,
                     max_iter = if (tight) 100 else 20, tol = if (tight) 1e-11 else 1e-9, ...)
}

# survival's coxph() called directly on a case's rows in the package's order (data_prepare() sorts
# them by provider, stably), with the fit's settings: the engine-identity reference (DEC-043's
# pattern; COXPH_DESIGN §E.1). `cluster` names a column of clusters, or "row" for one per row.
cox_case_coxph <- function(fx, ties, tight = FALSE, cluster = NULL) {
  d <- cox_case_data(fx)
  if (isTRUE(fx$case$weighted)) d <- d[d$weight > 0, , drop = FALSE]
  d <- d[order(d$.provider, method = "radix"), , drop = FALSE]
  d$.row <- seq_len(nrow(d))
  def <- fx$case
  rhs <- c(unlist(def$features), "strata(.provider)", if (isTRUE(def$offset)) "offset(offset)")
  lhs <- if (isTRUE(def$truncated)) "Surv(entry, time, event)" else "Surv(time, event)"
  f <- stats::as.formula(paste(lhs, "~", paste(rhs, collapse = " + ")),
                         env = list2env(list(Surv = survival::Surv, strata = survival::strata), parent = environment()))
  d$.w <- if (isTRUE(def$weighted)) d$weight else rep(1, nrow(d))
  control <- survival::coxph.control(eps = if (tight) 1e-11 else 1e-9, iter.max = if (tight) 100 else 20,
                                     timefix = FALSE)
  args <- list(f, data = d, ties = ties, robust = !is.null(cluster), control = control)
  if (isTRUE(def$weighted)) args$weights <- d$.w
  if (!is.null(cluster)) args$cluster <- if (identical(cluster, "row")) d$.row else d[[cluster]]
  do.call(survival::coxph, args)
}

# The upper triangle of a covariance matrix row by row, as the fixtures store it.
cox_packed_upper <- function(m) unname(unlist(lapply(seq_len(nrow(m)), function(i) m[i, i:ncol(m)])))

# The longer of the two last Newton steps from pprof_py's previous iterate, plus the coefficient
# tier's atol: the bound on the difference of two fits that stop at different points of the same
# path (D-57; dev/reference/cox/calibrate.R's last_step_bound()).
cox_last_step_bound <- function(a, b, iterates, iterations) {
  previous <- unlist(iterates[[max(iterations - 1, 1)]]$beta)
  max(abs(unlist(a) - previous), abs(unlist(b) - previous)) + reference_tolerance("cox_coefficient")$atol
}

# --- The measures, tests, and funnels of the Cox cases (Phase C3) --------------------------------

# The records of a fixture for one tie method: a Cox case, or each cause of a competing-risk case with
# the other causes censored (M-35), with what the measures need: the event, the providers as pprof_py
# grouped them (the stratum, or id mod 10 in an unstratified case, dev/reference/cox/generate.py's
# providers_of()), the times, the offset, and the covariates; pprof_py's outputs (its `measures`,
# `tests`, and `funnel`); and for stratified records the package's tight fit, whose strata are those
# providers.
cox_profile_records <- function(fx, ties) {
  def <- fx$case
  d <- fx$input
  start <- if (isTRUE(def$truncated)) d$entry else rep(0, nrow(d))
  x <- as.matrix(d[, unlist(def$features), drop = FALSE])
  if (identical(def$kind, "cox")) {
    return(list(list(
      label = paste(def$id, ties), event = d$event, provider = if (isTRUE(def$stratified)) d$stratum else d$id %% 10,
      start = start, stop = d$time, offset = if (isTRUE(def$offset)) d$offset else 0, x = x,
      py = fx$pprof_py[[ties]], fit = if (isTRUE(def$stratified)) function() cox_case_fit(fx, ties, tight = TRUE)
    )))
  }
  lhs <- if (isTRUE(def$truncated)) "Surv(entry, time, event == %d)" else "Surv(time, event == %d)"
  lapply(names(fx$pprof_py[[ties]]$cause_specific), function(cause) {
    f <- stats::as.formula(paste(sprintf(lhs, as.integer(cause)), "~", paste(unlist(def$features), collapse = " + ")),
                           env = list2env(list(Surv = survival::Surv), parent = globalenv()))
    list(label = sprintf("%s %s cause %s", def$id, ties, cause), event = as.numeric(d$event == as.integer(cause)),
         provider = d$stratum, start = start, stop = d$time, offset = 0, x = x,
         py = fx$pprof_py[[ties]]$cause_specific[[cause]],
         fit = function() fit_cox_stratified(f, d, provider = "stratum", ties = ties, max_iter = 100, tol = 1e-11))
  })
}

# The providers whose flag the test changes as their expected count moves within cox_baseline's
# allowance: within tolerance of a threshold, so their flags are not compared (the CoxPH brief's §3.5).
cox_near_threshold <- function(observed, expected, test, level = 0.95) {
  tolerance <- reference_tolerance("cox_baseline")
  width <- tolerance$atol + tolerance$rtol * expected
  infer_poisson_test(observed, pmax(expected - width, 0), test, level)$flag !=
    infer_poisson_test(observed, expected + width, test, level)$flag
}

# pprof_py's count boundaries of the funnel at level 0.95, and its curves where the fixture has them,
# from the package's construction at pprof_py's expected counts (K-149).
cox_funnel_parts <- function(funnel) {
  parts <- list(providers = list(ours = infer_poisson_funnel_limits(unlist(funnel$expected), "midp", 0.95),
                                 theirs = cbind(unlist(funnel$lower), unlist(funnel$upper))))
  curves <- funnel$curves
  if (!is.null(curves)) {
    levels <- unlist(curves$level)
    ours <- do.call(rbind, lapply(sort(unique(levels)), function(level) {
      infer_poisson_funnel_limits(unlist(curves$precision)[levels == level], "midp", level)
    }))
    order <- order(levels, seq_along(levels))
    parts$curves <- list(ours = ours, theirs = cbind(unlist(curves$lower), unlist(curves$upper))[order, , drop = FALSE])
  }
  parts
}
