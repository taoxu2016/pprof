# Calibrate the Cox tolerance tiers against the Cox fixtures (CoxPH brief §3.5; COXPH_DESIGN §G.2).
#
# Usage, from the repository root:
#   Rscript dev/reference/cox/calibrate.R [report] [core-dir] [full-dir]
# Default report: validation/cox-calibration-report.md. With PPROF_SPARK set to a checkout of
# pprof_spark at commit e917a68, the report also compares the imported cases' pprof_py outputs with
# those pprof_spark committed (another machine: how far pprof_py itself reproduces).
#
# The tiers are those of tests/testthat/helper-tolerances.R, under the package's rule: a value a
# matches its reference b when |a - b| <= atol + rtol * |b|, elementwise. For each case, tie method,
# and quantity, the report gives the ratio of the largest observed difference to the allowed one:
#   - pprof_py against survival or glmnet (two validated implementations): at most 1;
#   - each negative control (the other tie method, one tied event moved by a day, one weight
#     dropped) against pprof_py: at least 10, so that a real defect fails.
# Default fits stop at different points (D-57) and are compared with the size of pprof_py's last
# Newton step instead. Differences that a register entry explains (D-56, D-58, D-64) are reported
# with it and are not counted as calibration failures. Nothing here changes a tier.
args <- commandArgs(trailingOnly = TRUE)
report_file <- if (length(args) >= 1) args[[1]] else file.path("validation", "cox-calibration-report.md")
dirs <- c(if (length(args) >= 2) args[[2]] else file.path("tests", "testthat", "fixtures", "cox"),
          if (length(args) >= 3) args[[3]] else file.path("validation", "fixtures", "cox"))
source(file.path("tests", "testthat", "helper-tolerances.R"))
margin <- 10

ratio <- function(a, b, tier) {
  a <- unlist(a)
  b <- unlist(b)
  if (length(a) != length(b)) return(NA_real_)
  if (any(xor(is.finite(a), is.finite(b)))) return(Inf)
  ok <- is.finite(a) & is.finite(b)
  if (!any(ok)) return(0)
  tol <- pprof_tolerances[[tier]]
  diff <- abs(a[ok] - b[ok])
  allowed <- tol$atol + tol$rtol * abs(b[ok])
  max(ifelse(diff == 0, 0, diff / allowed))
}

state <- new.env()
state$rows <- list()
add <- function(case, ties, quantity, tier, agreement, controls = NULL, note = "") {
  weakest <- if (length(controls)) min(unlist(controls)) else NA_real_
  ok <- (is.na(agreement) || agreement <= 1) && (is.na(weakest) || weakest >= margin)
  state$rows[[length(state$rows) + 1]] <- data.frame(case = case, ties = ties, quantity = quantity, tier = tier,
                                                     agreement = agreement, weakest_control = weakest, ok = ok,
                                                     note = note)
}
other <- function(ties) if (ties == "breslow") "efron" else "breslow"

# When the last Newton step lowers the log-likelihood at rounding level, pprof_py halves it (up to
# 20 times) before it tests convergence and survival keeps it whole (D-57). The two paths agree up
# to the previous iterate, so both estimates lie along the same step from it: their difference is
# at most the longer of the two last steps. last_step_bound() is that bound plus the coefficient
# tier's atol; last_step_note() returns "D-57" when the coefficient tier fails but the bound holds.
last_step_bound <- function(a, b, iterates, iterations) {
  previous <- unlist(iterates[[max(iterations - 1, 1)]]$beta)
  max(abs(unlist(a) - previous), abs(unlist(b) - previous)) + pprof_tolerances$cox_coefficient$atol
}
last_step_note <- function(agreement, a, b, iterates, iterations) {
  if (is.na(agreement) || agreement <= 1 || length(iterates) < iterations || iterations < 2) return("")
  if (max(abs(unlist(a) - unlist(b))) <= last_step_bound(a, b, iterates, iterations)) "D-57" else ""
}

calibrate_cox <- function(id, fx) {
  def <- fx$case
  for (ties in c("breslow", "efron")) {
    py <- fx$pprof_py[[ties]]
    r <- fx$survival[[ties]]
    controls <- py$negative_controls
    # pprof_py counts zero-weight events among Efron's tied deaths (B7); survival leaves them out (M-25).
    fit_note <- if (identical(id, "zero-weights") && ties == "efron") "D-58" else ""
    # Covariates near 2,000: pprof_py computes with them uncentered (B5).
    mean_note <- if (identical(id, "large-mean")) "D-64" else ""
    note <- paste(c(fit_note, mean_note)[nzchar(c(fit_note, mean_note))], collapse = ", ")
    add(id, ties, "iterations, default and tight", "exact",
        ratio(c(py$default$iterations, py$tight$iterations), c(r$default$iterations, r$tight$iterations), "exact"),
        note = fit_note)
    tight_ratio <- ratio(py$tight$coef, r$tight$coef, "cox_coefficient")
    tight_note <- if (nzchar(fit_note)) fit_note else
      last_step_note(tight_ratio, py$tight$coef, r$tight$coef, py$iterates, py$tight$iterations)
    add(id, ties, "coefficients, tight", "cox_coefficient", tight_ratio,
        lapply(controls, function(cf) ratio(cf$coef, py$tight$coef, "cox_coefficient")), note = tight_note)
    add(id, ties, "log-likelihood, tight", "cox_function", ratio(py$tight$loglik, r$tight$loglik, "cox_function"),
        lapply(controls, function(cf) ratio(cf$loglik, py$tight$loglik, "cox_function")), note = fit_note)
    add(id, ties, "standard errors, tight", "cox_variance", ratio(py$tight$se, r$tight$se, "cox_variance"),
        lapply(controls, function(cf) ratio(cf$se, py$tight$se, "cox_variance")), note = fit_note)
    add(id, ties, "covariance, tight", "cox_variance", ratio(py$tight$covariance, r$tight$covariance, "cox_variance"),
        lapply(controls, function(cf) ratio(cf$covariance, py$tight$covariance, "cox_variance")), note = fit_note)
    # Default fits stop at different points (D-57): within the longer of the two last Newton steps.
    allowed <- last_step_bound(py$default$coef, r$default$coef, py$iterates, py$default$iterations)
    add(id, ties, sprintf("coefficients, default (last step %.1e)", allowed), "last step",
        max(abs(unlist(py$default$coef) - unlist(r$default$coef))) / allowed, note = fit_note)
    if (!is.null(r$default_timefix)) {
      add(id, ties, "coefficients, default, R with timefix = TRUE (informational)", "last step",
          max(abs(unlist(py$default$coef) - unlist(r$default_timefix$coef))) / allowed, note = "M-23")
    }
    for (at in c("beta_zero", "beta_fixed")) {
      for (q in c("loglik", "score", "information")) {
        add(id, ties, sprintf("%s at %s", q, at), "cox_function", ratio(py[[at]][[q]], r[[at]][[q]], "cox_function"),
            list(other_ties = ratio(fx$pprof_py[[other(ties)]][[at]][[q]], py[[at]][[q]], "cox_function")), note = note)
      }
    }
    # The national baseline: expected counts at pprof_py's beta (the closed form alone) and at each side's.
    add(id, ties, "expected counts at pprof_py's beta", "closed_form",
        ratio(py$measures$expected, r$expected$at_pprof_py_beta$provider_expected, "closed_form"),
        list(other_ties = ratio(fx$pprof_py[[other(ties)]]$measures$expected, py$measures$expected, "closed_form")))
    add(id, ties, "expected counts at each side's beta", "cox_baseline",
        ratio(py$measures$expected, r$expected$at_r_beta$provider_expected, "cox_baseline"),
        list(other_ties = ratio(fx$pprof_py[[other(ties)]]$measures$expected, py$measures$expected, "cox_baseline")),
        note = fit_note)
    add(id, ties, "baseline cumulative hazard (basehaz, centered = FALSE)", "cox_baseline",
        ratio(py$baseline$public_cumulative_hazard, r$basehaz$hazard, "cox_baseline"),
        list(other_ties = ratio(fx$pprof_py[[other(ties)]]$baseline$public_cumulative_hazard,
                                py$baseline$public_cumulative_hazard, "cox_baseline")), note = note)
    if (!is.null(py$residuals)) {
      kept <- unlist(fx$survival$kept_rows) + 1L
      for (q in c("martingale", "score", "dfbeta")) {
        add(id, ties, paste(q, "residuals"), "cox_residual",
            ratio(lapply(py$residuals[[q]], function(v) unlist(v)[kept]), r$residuals[[q]], "cox_residual"),
            list(other_ties = ratio(fx$pprof_py[[other(ties)]]$residuals[[q]], py$residuals[[q]], "cox_residual")),
            note = note)
      }
      robust_note <- if (ties == "breslow" && isTRUE(def$truncated)) "D-56" else note
      for (q in c("robust_per_row", "robust_clustered")) {
        add(id, ties, gsub("_", " ", q), "cox_variance", ratio(py$residuals[[q]], r$residuals[[q]], "cox_variance"),
            list(other_ties = ratio(fx$pprof_py[[other(ties)]]$residuals[[q]], py$residuals[[q]], "cox_variance")),
            note = robust_note)
      }
    }
  }
}

calibrate_competing <- function(id, fx) {
  for (ties in c("breslow", "efron")) {
    py <- fx$pprof_py[[ties]]
    r <- fx$survival[[ties]]
    for (cause in names(py$cause_specific)) {
      a <- py$cause_specific[[cause]]
      b <- r$cause_specific[[cause]]
      add(id, ties, sprintf("cause %s: iterations, default and tight", cause), "exact",
          ratio(c(a$default$iterations, a$tight$iterations), c(b$default$iterations, b$tight$iterations), "exact"))
      add(id, ties, sprintf("cause %s: coefficients, tight", cause), "cox_coefficient",
          ratio(a$tight$coef, b$tight$coef, "cox_coefficient"),
          list(other_ties = ratio(fx$pprof_py[[other(ties)]]$cause_specific[[cause]]$tight$coef, a$tight$coef,
                                  "cox_coefficient")))
      add(id, ties, sprintf("cause %s: covariance, tight", cause), "cox_variance",
          ratio(a$tight$covariance, b$tight$covariance, "cox_variance"))
    }
    for (key in names(py$fine_gray)) {
      a <- py$fine_gray[[key]]
      b <- r$fine_gray[[key]]
      ea <- a$expanded
      eb <- b$expanded
      order_a <- order(unlist(ea$row), unlist(ea$start))
      order_b <- order(unlist(eb$row), unlist(eb$start))
      same_rows <- length(order_a) == length(order_b) &&
        identical(as.integer(unlist(ea$row)[order_a]), as.integer(unlist(eb$row)[order_b])) &&
        identical(as.integer(unlist(ea$status)[order_a]), as.integer(unlist(eb$status)[order_b]))
      label <- function(what) sprintf("Fine-Gray %s: %s", key, what)
      add(id, ties, label("expanded rows and status"), "exact", if (same_rows) 0 else Inf)
      if (same_rows) {
        add(id, ties, label("expanded times and weights"), "closed_form",
            max(ratio(unlist(ea$start)[order_a], unlist(eb$start)[order_b], "closed_form"),
                ratio(unlist(ea$stop)[order_a], unlist(eb$stop)[order_b], "closed_form"),
                ratio(unlist(ea$weight)[order_a], unlist(eb$weight)[order_b], "closed_form")))
      }
      add(id, ties, label("iterations, default and tight"), "exact",
          ratio(c(a$default$iterations, a$tight$iterations), c(b$default$iterations, b$tight$iterations), "exact"))
      tight_ratio <- ratio(a$tight$coef, b$tight$coef, "cox_coefficient")
      add(id, ties, label("coefficients, tight"), "cox_coefficient", tight_ratio,
          list(other_ties = ratio(fx$pprof_py[[other(ties)]]$fine_gray[[key]]$tight$coef, a$tight$coef,
                                  "cox_coefficient")),
          note = last_step_note(tight_ratio, a$tight$coef, b$tight$coef, a$iterates, a$tight$iterations))
      add(id, ties, label("robust covariance, tight"), "cox_variance",
          ratio(a$tight$covariance, b$tight$covariance, "cox_variance"), note = if (ties == "breslow") "D-56" else "")
      add(id, ties, label("model-based covariance, tight"), "cox_variance",
          ratio(a$tight$naive_covariance, b$tight$naive_covariance, "cox_variance"))
      for (i in seq_along(a$cumulative_incidence)) {
        ca <- a$cumulative_incidence[[i]]
        cb <- b$cumulative_incidence[[i]]
        stratum <- if (is.null(ca$stratum)) "all" else ca$stratum
        add(id, ties, label(sprintf("cumulative incidence, stratum %s", stratum)),
            "cox_baseline", max(ratio(ca$time, cb$time, "exact"),
                                ratio(ca$cumulative_incidence, cb$cumulative_incidence, "cox_baseline")))
      }
    }
  }
}

calibrate_penalized <- function(id, fx) {
  for (ties in c("breslow", "efron")) {
    for (key in names(fx$survival[[ties]])) {
      a <- fx$pprof_py[[ties]][[key]]
      b <- fx$survival[[ties]][[key]]
      add(id, ties, sprintf("%s: coefficient path", key), "penalized_path",
          ratio(a$path$coef_path, b$path$coef_path, "penalized_path"),
          list(other_ties = ratio(a$negative_controls$other_ties$coef_path, a$path$coef_path, "penalized_path")))
      if (!is.null(b$cv)) {
        add(id, ties, sprintf("%s: cross-validation mean deviance", key), "penalized_path",
            ratio(a$cv$cvm, b$cv$cvm, "penalized_path"))
        add(id, ties, sprintf("%s: cross-validation standard error", key), "penalized_path",
            ratio(a$cv$cvsd, b$cv$cvsd, "penalized_path"))
        add(id, ties, sprintf("%s: selected lambda (min, 1se)", key), "exact",
            ratio(c(a$cv$lambda_min, a$cv$lambda_1se), c(b$cv$lambda_min, b$cv$lambda_1se), "exact"))
      }
    }
  }
}

files <- unlist(lapply(dirs[dir.exists(dirs)], function(d) list.files(d, pattern = "\\.rds$", full.names = TRUE)))
fixtures <- lapply(setNames(files, sub("\\.rds$", "", basename(files))), readRDS)
for (id in names(fixtures)) {
  fx <- fixtures[[id]]
  switch(fx$case$kind, cox = calibrate_cox(id, fx), competing = calibrate_competing(id, fx),
         penalized = calibrate_penalized(id, fx))
}
table <- do.call(rbind, state$rows)
fmt <- function(x) ifelse(is.na(x), "-", ifelse(is.infinite(x), "Inf", formatC(x, format = "g", digits = 3)))
scored <- !nzchar(table$note)
lines <- c("# Cox tolerance calibration", "",
           sprintf("Generated by `dev/reference/cox/calibrate.R` from %d Cox fixtures (%s).", length(files),
                   paste(dirs[dir.exists(dirs)], collapse = ", ")),
           "Ratios are the largest observed difference over the allowed one under the package's rule,",
           "|a - b| <= atol + rtol * |b| elementwise: pprof_py against survival or glmnet must be at most 1, and every",
           sprintf("negative control at least %g. Default fits, and tight fits whose last step was halved,", margin),
           "are compared with the longer of the two last Newton steps (D-57).",
           "Rows with a register entry in the note column are explained differences, not calibration failures.", "",
           "| Tier | atol | rtol | Justification |", "|---|---|---|---|",
           vapply(intersect(unique(table$tier), names(pprof_tolerances)), function(t) {
             sprintf("| `%s` | %g | %g | %s |", t, pprof_tolerances[[t]]$atol, pprof_tolerances[[t]]$rtol,
                     pprof_tolerances[[t]]$why)
           }, ""),
           "", sprintf("Result: %d of %d rows pass; %d rows are explained by a register entry.",
                       sum(table$ok & scored), sum(scored), sum(!scored)), "",
           "| Case | Ties | Quantity | Tier | pprof_py vs R | Weakest control | OK | Note |",
           "|---|---|---|---|---|---|---|---|",
           sprintf("| %s | %s | %s | %s | %s | %s | %s | %s |", table$case, table$ties, table$quantity, table$tier,
                   fmt(table$agreement), fmt(table$weakest_control),
                   ifelse(!scored, "explained", ifelse(table$ok, "yes", "**no**")), table$note))

# pprof_py on this machine against pprof_py on pprof_spark's (same pins, other platform).
spark <- Sys.getenv("PPROF_SPARK")
if (nzchar(spark)) {
  hexnum <- function(v) suppressWarnings(as.numeric(unlist(v)))
  lines <- c(lines, "", "## pprof_py on two machines", "",
             "The imported cases' pprof_py outputs, regenerated here, against those pprof_spark committed at e917a68",
             "(the same pins on another platform): the largest relative difference per quantity.", "",
             "| Case | Ties | Quantity | Largest relative difference | Bitwise equal |", "|---|---|---|---|---|")
  imported <- c("tiny-ties", "rc-unstratified", "rc-stratified", "rc-stratified-weights-offset", "lt-stratified",
                "lt-weights-offset")
  for (id in intersect(names(fixtures), imported)) {
    theirs <- jsonlite::read_json(file.path(spark, "fixtures", "cox", id, "pprof_py.json"), simplifyVector = TRUE,
                                  simplifyDataFrame = FALSE, simplifyMatrix = FALSE)
    ours <- fixtures[[id]]$pprof_py
    for (ties in c("breslow", "efron")) {
      for (q in list(c("default", "coef"), c("tight", "coef"), c("beta_fixed", "score"), c("measures", "expected"),
                     c("tests", "midp", "p_value"))) {
        a <- unlist(ours[[ties]][[q]])
        b <- hexnum(theirs[[ties]][[q]])
        rel <- max(abs(a - b) / pmax(abs(b), .Machine$double.xmin), na.rm = TRUE)
        lines <- c(lines, sprintf("| %s | %s | %s | %s | %s |", id, ties, paste(q, collapse = " "), fmt(rel),
                                  if (identical(a, b)) "yes" else "no"))
      }
    }
  }
}
writeLines(lines, report_file)
cat(lines[grep("^Result", lines)], "\n")
