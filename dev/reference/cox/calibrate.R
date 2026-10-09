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
# A missing ratio means the two outputs could not be compared (their lengths differ): a failure
# unless a register entry explains it, never a pass.
add <- function(case, ties, quantity, tier, agreement, controls = NULL, note = "") {
  weakest <- if (length(controls)) min(unlist(controls)) else NA_real_
  ok <- !is.na(agreement) && agreement <= 1 && (is.na(weakest) || weakest >= margin)
  if (ok) note <- ""  # a row that passes needs no explanation
  state$rows[[length(state$rows) + 1]] <- data.frame(case = case, ties = ties, quantity = quantity, tier = tier,
                                                     agreement = agreement, weakest_control = weakest, ok = ok,
                                                     note = note)
}
other <- function(ties) if (ties == "breslow") "efron" else "breslow"

# Step functions on different grids, compared where pprof_py reports them: pprof_py gives the
# baseline at event times and the cumulative incidence at its own times, survival at every distinct
# time (censoring times and strata without events included). Each pprof_py point is matched to
# survival's at the same stratum and the same time, bit for bit; a point survival lacks leaves the
# reference value missing, so the row fails as not comparable.
at_points <- function(keys, reference_keys, reference_values) {
  reference_values <- unlist(reference_values)
  index <- match(keys, reference_keys)
  if (anyNA(index)) return(rep(NA_real_, length(keys) + 1))
  reference_values[index]
}
baseline_keys <- function(stratum, time, stratified) {
  if (stratified) sprintf("%s|%a", unlist(stratum), unlist(time)) else sprintf("%a", unlist(time))
}

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
    stratified <- isTRUE(def$stratified)
    py_keys <- baseline_keys(py$baseline$raw$stratum, py$baseline$raw$time, stratified)
    r_keys <- baseline_keys(r$basehaz$stratum, r$basehaz$time, stratified)
    py_hazard <- unlist(py$baseline$public_cumulative_hazard)
    baseline_note <- note
    if (identical(id, "zero-weights") && anyNA(match(py_keys, r_keys))) {
      # pprof_py's baseline also has the times of zero-weight events, which survival's fit leaves out
      # (M-25): the common times are compared, and the extra ones are D-58's.
      common <- !is.na(match(py_keys, r_keys))
      py_keys <- py_keys[common]
      py_hazard <- py_hazard[common]
      baseline_note <- "D-58"
    }
    survival_hazard <- at_points(py_keys, r_keys, r$basehaz$hazard)
    add(id, ties, "baseline cumulative hazard at pprof_py's times (basehaz, centered = FALSE)", "cox_baseline",
        ratio(py_hazard, survival_hazard, "cox_baseline"),
        list(other_ties = ratio(fx$pprof_py[[other(ties)]]$baseline$public_cumulative_hazard,
                                py$baseline$public_cumulative_hazard, "cox_baseline")), note = baseline_note)
    if (!is.null(py$residuals)) {
      kept <- unlist(fx$survival$kept_rows) + 1L
      # pprof_py's residuals for the rows survival fitted: a vector (martingale) or a list of columns.
      kept_rows <- function(v) if (is.list(v)) lapply(v, function(column) unlist(column)[kept]) else unlist(v)[kept]
      for (q in c("martingale", "score", "dfbeta")) {
        add(id, ties, paste(q, "residuals"), "cox_residual",
            ratio(kept_rows(py$residuals[[q]]), r$residuals[[q]], "cox_residual"),
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
      fit_note <- last_step_note(tight_ratio, a$tight$coef, b$tight$coef, a$iterates, a$tight$iterations)
      add(id, ties, label("coefficients, tight"), "cox_coefficient", tight_ratio,
          list(other_ties = ratio(fx$pprof_py[[other(ties)]]$fine_gray[[key]]$tight$coef, a$tight$coef,
                                  "cox_coefficient")), note = fit_note)
      add(id, ties, label("robust covariance, tight"), "cox_variance",
          ratio(a$tight$covariance, b$tight$covariance, "cox_variance"), note = if (ties == "breslow") "D-56" else "")
      add(id, ties, label("model-based covariance, tight"), "cox_variance",
          ratio(a$tight$naive_covariance, b$tight$naive_covariance, "cox_variance"))
      for (i in seq_along(a$cumulative_incidence)) {
        ca <- a$cumulative_incidence[[i]]
        cb <- b$cumulative_incidence[[i]]
        stratum <- if (is.null(ca$stratum)) "all" else ca$stratum
        keys <- sprintf("%a", unlist(ca$time))
        reference_keys <- sprintf("%a", unlist(cb$time))
        survival_incidence <- lapply(cb$cumulative_incidence, function(v) at_points(keys, reference_keys, v))
        incidence_ratio <- ratio(ca$cumulative_incidence, survival_incidence, "cox_baseline")
        # The incidence inherits the coefficients' difference when D-57 explains it.
        add(id, ties, label(sprintf("cumulative incidence at pprof_py's times, stratum %s", stratum)),
            "cox_baseline", incidence_ratio, note = if (!is.na(incidence_ratio) && incidence_ratio > 1) fit_note else "")
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

# --- Phase C3: the measures, tests, limits, and funnels (DEC-097, DEC-109) ------------------------------
#
# pprof_py's measures and tests given its own inputs, against R's functions: a transcription of K-136 to
# K-142 and K-149 with ppois(), qnorm(), qchisq(), and uniroot(), written here apart from the package's
# code (dev/design/coxph-facts/22_measures_tests.R and 23_funnel_limits.R). The direct expected counts at
# pprof_py's beta and grouping of providers; the statistics, p-values, flags, and limits at its observed
# and expected counts; the funnel limits at its expected counts. Negative controls, each through the
# expected counts: the other tie method (pprof_py's), and for Cox cases the generator's moved-tie and
# dropped-weight fits (their expected counts by the transcription). A last section compares the flags at
# each side's tight beta, listing providers whose flag changes within cox_baseline of their expected count.

# Sums of `values` by provider code 0..m-1, in row order.
c3_sums <- function(values, codes, m) {
  out <- numeric(m)
  s <- rowsum(values, codes, reorder = TRUE)
  out[as.integer(rownames(s)) + 1L] <- s[, 1]
  out
}
# The sum of r over the rows whose key is at least q, for each q (pprof_py's suffix sums).
c3_suffix_at <- function(keys, r, q) {
  o <- order(keys, method = "radix")
  s <- c(rev(cumsum(rev(r[o]))), 0)
  s[findInterval(q, keys[o], left.open = TRUE) + 1L]
}
c3_at_risk <- function(q, start, stop, r) c3_suffix_at(stop, r, q) - c3_suffix_at(start, r, q)
# K-136 to K-138: O, E, and the direct expected counts by provider code at linear predictor eta.
c3_measures <- function(eta, start, stop, event, codes, m) {
  r <- exp(eta - max(eta))
  times <- sort(unique(stop[event == 1]))
  rs <- c3_at_risk(times, start, stop, r)
  cumulative <- c(0, cumsum(tabulate(match(stop[event == 1], times), length(times)) / rs))
  rows <- r * (cumulative[findInterval(stop, times) + 1L] - cumulative[findInterval(start, times) + 1L])
  direct <- numeric(m)
  for (j in which(tabulate(codes[event == 1] + 1L, m) > 0)) {
    own <- which(codes == j - 1L)
    ev <- own[event[own] == 1]
    direct[j] <- sum(rs[match(stop[ev], times)] / c3_at_risk(stop[ev], start[own], stop[own], r[own]))
  }
  list(O = c3_sums(as.numeric(event), codes, m), E = c3_sums(rows, codes, m), direct = direct)
}
c3_midp_z <- function(O, E) {
  p_min <- 2 * stats::ppois(O, E) - stats::dpois(O, E)
  p_max <- 2 * (1 - stats::ppois(O - 1, E)) - stats::dpois(O, E)
  z <- stats::qnorm(pmax(1e-6, pmin(p_min, p_max) / 2))
  ifelse(p_min <= p_max, z, -z)
}
c3_exact_z <- function(O, E) {
  high <- !is.na(O / E) & O / E > 1
  p <- ifelse(high, pmin(0.999, 2 * stats::ppois(O - 1, E, lower.tail = FALSE)), pmin(0.999, 2 * stats::ppois(O, E)))
  sign(O - E) * stats::qnorm(p / 2, lower.tail = FALSE)
}
c3_p <- function(z) 2 * stats::pnorm(abs(z), lower.tail = FALSE)
c3_flag <- function(z, alpha) {
  p <- c3_p(z)
  as.integer(ifelse(p < alpha & z > 0, 1L, ifelse(p < alpha & z < 0, -1L, 0L)))
}
c3_exact_limits <- function(O, E, alpha) {
  zc <- stats::qnorm(1 - alpha / 2)
  garwood <- E < 100
  lower <- ifelse(O > 0, ifelse(garwood, stats::qchisq(alpha / 2, 2 * O) / 2 / E,
                                (O / E) * (1 - 1 / (9 * O) - zc / (3 * sqrt(O)))^3), 0)
  upper <- ifelse(garwood, stats::qchisq(1 - alpha / 2, 2 * (O + 1)) / 2 / E,
                  ((O + 1) / E) * (1 - 1 / (9 * (O + 1)) + zc / (3 * sqrt(O + 1)))^3)
  c(lower, upper)
}
# The mid-p limits on the ratio scale: the roots in the Poisson mean once per distinct O, to rounding,
# with pprof_py's 0 where its equation is not negative at its bracket's lower end.
c3_midp_limits <- function(O, E, alpha) {
  values <- sort(unique(O))
  roots <- vapply(values, function(o) {
    excess <- function(t) c3_p(c3_midp_z(o, t)) - alpha
    low <- .Machine$double.xmin
    high <- 10 * (o + 10)
    middle <- if (c3_midp_z(o, low) <= 0) low else
      stats::uniroot(function(t) c3_midp_z(o, t), c(low, high), tol = 1e-300, maxiter = 2000L)$root
    c(if (excess(low) >= 0) 0 else stats::uniroot(excess, c(low, middle), tol = 1e-300, maxiter = 2000L)$root,
      stats::uniroot(excess, c(middle, high), tol = 1e-300, maxiter = 2000L)$root)
  }, numeric(2))
  lower <- roots[1, match(O, values)]
  lower[c3_p(c3_midp_z(O, 1e-10 * pmax(E, 1))) - alpha >= 0] <- 0
  c(lower / E, roots[2, match(O, values)] / E)
}
# K-149: the count boundaries of the mid-p test, by brute force over 0..n, at each expected count.
c3_funnel_limits <- function(E, O, alpha) {
  n <- ceiling(pmax(E, O) + 40 * sqrt(E) + 50)
  limits <- vapply(seq_along(E), function(i) {
    counts <- 0:n[i]
    f <- c3_flag(c3_midp_z(counts, rep(E[i], length(counts))), alpha)
    c(if (any(f == -1L)) (max(counts[f == -1L]) + 0.5) / E[i] else -Inf,
      if (any(f == 1L)) (min(counts[f == 1L]) - 0.5) / E[i] else Inf)
  }, numeric(2))
  c(limits[1, ], limits[2, ])
}
# Everything compared, from observed and expected counts.
c3_tests <- function(O, E, alpha) {
  list(midp_z = c3_midp_z(O, E), exact_z = c3_exact_z(O, E), p = c3_p(c(c3_midp_z(O, E), c3_exact_z(O, E))),
       exact_limits = c3_exact_limits(O, E, alpha), midp_limits = c3_midp_limits(O, E, alpha))
}
c3_py_tests <- function(t) {
  list(midp_z = unlist(t$midp$z_raw), exact_z = unlist(t$exact$z_raw), p = unlist(c(t$midp$p_value, t$exact$p_value)),
       exact_limits = unlist(c(t$exact$ci_lower, t$exact$ci_upper)),
       midp_limits = unlist(c(t$midp$ci_lower, t$midp$ci_upper)))
}

# The generator's moved tie (generate.py's shifted_tie()): the first (stratum, time) of two or more events,
# its first row a day later.
c3_shifted_stop <- function(d) {
  ev <- which(d$event == 1)
  o <- order(d$stratum[ev], d$time[ev], ev)
  i <- which(d$stratum[ev][o][-1] == d$stratum[ev][o][-length(ev)] & d$time[ev][o][-1] == d$time[ev][o][-length(ev)])[1]
  stop <- d$time
  stop[ev[o][i]] <- stop[ev[o][i]] + 1
  stop
}

state$flags <- list()
calibrate_profiling <- function(id, fx) {
  def <- fx$case
  d <- fx$input
  truncated <- isTRUE(def$truncated)
  start <- if (truncated) d$entry else rep(0, nrow(d))
  x <- as.matrix(d[, unlist(def$features), drop = FALSE])
  alpha <- 1 - 0.95
  for (ties in c("breslow", "efron")) {
    records <- if (identical(def$kind, "cox")) {
      list(list(label = "", event = d$event, offset = if (isTRUE(def$offset)) d$offset else 0,
                provider = if (isTRUE(def$stratified)) d$stratum else d$id %% 10, py = fx$pprof_py[[ties]],
                other = fx$pprof_py[[other(ties)]], r_beta = unlist(fx$survival[[ties]]$tight$coef),
                controls = fx$pprof_py[[ties]]$negative_controls))
    } else {
      lapply(names(fx$pprof_py[[ties]]$cause_specific), function(cause) {
        list(label = sprintf("cause %s: ", cause), event = as.numeric(d$event == as.integer(cause)), offset = 0,
             provider = d$stratum, py = fx$pprof_py[[ties]]$cause_specific[[cause]],
             other = fx$pprof_py[[other(ties)]]$cause_specific[[cause]],
             r_beta = unlist(fx$survival[[ties]]$cause_specific[[cause]]$tight$coef), controls = NULL)
      })
    }
    for (rec in records) {
      labels <- sort(unique(rec$provider))
      codes <- match(rec$provider, labels) - 1L
      m <- length(labels)
      at <- function(beta, stop = d$time) c3_measures(drop(x %*% beta) + rec$offset, start, stop, rec$event, codes, m)
      py <- rec$py
      O <- unlist(py$tests$midp$observed)
      E <- unlist(py$tests$midp$expected)
      mine <- c3_tests(O, E, alpha)
      theirs <- c3_py_tests(py$tests)
      # The controls' tests, through their expected counts.
      control_tests <- list(other_ties = c3_py_tests(rec$other$tests))
      if (!is.null(rec$controls)) {
        moved <- at(unlist(rec$controls$shifted_tie$coef), c3_shifted_stop(d))
        control_tests$moved_tie <- c3_tests(moved$O, moved$E, alpha)
        if (!is.null(rec$controls$dropped_weight)) {
          dropped <- at(unlist(rec$controls$dropped_weight$coef))
          control_tests$dropped_weight <- c3_tests(dropped$O, dropped$E, alpha)
        }
      }
      controls_of <- function(part, tier) lapply(control_tests, function(ct) ratio(ct[[part]], theirs[[part]], tier))
      label <- function(what) paste0(rec$label, what)
      direct <- at(unlist(py$measures$beta))$direct
      add(id, ties, label("direct expected counts at pprof_py's beta"), "closed_form",
          ratio(direct, py$measures$direct_expected, "closed_form"),
          list(other_ties = ratio(rec$other$measures$direct_expected, py$measures$direct_expected, "closed_form")))
      add(id, ties, label("mid-p statistics at pprof_py's counts"), "cox_statistic",
          ratio(mine$midp_z, theirs$midp_z, "cox_statistic"), controls_of("midp_z", "cox_statistic"))
      add(id, ties, label("exact statistics at pprof_py's counts"), "cox_statistic",
          ratio(mine$exact_z, theirs$exact_z, "cox_statistic"), controls_of("exact_z", "cox_statistic"))
      add(id, ties, label("p-values, mid-p and exact"), "probability", ratio(mine$p, theirs$p, "probability"),
          controls_of("p", "probability"))
      add(id, ties, label("flags, mid-p and exact"), "exact",
          ratio(c(c3_flag(mine$midp_z, alpha), c3_flag(mine$exact_z, alpha)),
                unlist(c(py$tests$midp$flag, py$tests$exact$flag)), "exact"))
      add(id, ties, label("exact limits"), "closed_form", ratio(mine$exact_limits, theirs$exact_limits, "closed_form"),
          controls_of("exact_limits", "closed_form"))
      add(id, ties, label("mid-p limits"), "cox_root", ratio(mine$midp_limits, theirs$midp_limits, "cox_root"),
          controls_of("midp_limits", "cox_root"))
      funnel <- py$funnel
      curves <- funnel$curves
      curve_limits <- unlist(lapply(sort(unique(unlist(curves$level))), function(level) {
        k <- unlist(curves$level) == level
        c3_funnel_limits(unlist(curves$precision)[k], rep(0, sum(k)), 1 - level)
      }))
      curve_reference <- unlist(lapply(sort(unique(unlist(curves$level))), function(level) {
        k <- unlist(curves$level) == level
        c(unlist(curves$lower)[k], unlist(curves$upper)[k])
      }))
      add(id, ties, label("funnel limits at pprof_py's expected counts, and its curves"), "exact",
          max(ratio(c3_funnel_limits(unlist(funnel$expected), unlist(funnel$observed), alpha),
                    unlist(c(funnel$lower, funnel$upper)), "exact"),
              ratio(curve_limits, curve_reference, "exact")),
          list(other_ties = ratio(unlist(c(rec$other$funnel$lower, rec$other$funnel$upper)),
                                  unlist(c(funnel$lower, funnel$upper)), "exact")))
      # The flags at each side's tight beta: R's counts at survival's beta against pprof_py's tests.
      ours <- at(rec$r_beta)
      allowance <- reference_tolerance("cox_baseline")
      for (test in c("midp", "exact")) {
        z_of <- if (test == "midp") c3_midp_z else c3_exact_z
        flags_r <- c3_flag(z_of(ours$O, ours$E), alpha)
        flags_py <- unlist(py$tests[[test]]$flag)
        differ <- which(flags_r != flags_py)
        width <- allowance$atol + allowance$rtol * ours$E
        near <- differ[c3_flag(z_of(ours$O[differ], ours$E[differ] - width[differ]), alpha) !=
                         c3_flag(z_of(ours$O[differ], ours$E[differ] + width[differ]), alpha)]
        state$flags[[length(state$flags) + 1L]] <- data.frame(
          case = id, ties = ties, record = sub(": $", "", rec$label), test = test, providers = length(flags_r),
          differ = length(differ), near = length(near),
          ids = paste(labels[setdiff(differ, near)], collapse = " "))
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
  if (fx$case$kind %in% c("cox", "competing")) calibrate_profiling(id, fx)
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

# Phase C3: the flags at each side's coefficients.
flag_table <- do.call(rbind, state$flags)
flag_table$note <- ifelse(flag_table$case == "zero-weights" & flag_table$ties == "efron", "D-58", "")
unexplained <- flag_table$differ - flag_table$near > 0 & !nzchar(flag_table$note)
lines <- c(lines, "", "## Flags at each side's coefficients", "",
           "Every Cox case and cause-specific record, both tie methods and both tests: R's flags at survival's tight",
           "coefficients (the expected counts by this script's transcription) against pprof_py's at its own. A provider",
           "whose flag differs is near a threshold when its flag changes as its expected count moves within",
           "`cox_baseline`'s allowance (the CoxPH C3 plan, §4.2). Rows without a differing flag are not listed.", "",
           sprintf("Result: %d flags compared, %d differ, %d of them near a threshold; %d records with other differences.",
                   sum(flag_table$providers), sum(flag_table$differ), sum(flag_table$near), sum(unexplained)), "")
listed <- flag_table[flag_table$differ > 0, , drop = FALSE]
if (nrow(listed)) {
  lines <- c(lines, "| Case | Ties | Record | Test | Providers | Differing | Near a threshold | Others | Note |",
             "|---|---|---|---|---|---|---|---|---|",
             sprintf("| %s | %s | %s | %s | %d | %d | %d | %s | %s |", listed$case, listed$ties, listed$record,
                     listed$test, listed$providers, listed$differ, listed$near, listed$ids, listed$note))
}

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
