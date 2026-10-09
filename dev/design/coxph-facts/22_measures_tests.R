# CoxPH Phase C3 plan: the closed-form measures and the Poisson tests of pprof_py v0.7.0, written in
# plain R (base and stats only, no package code), against the Cox fixtures; and the cost of the mid-p
# limits. For every Cox case and every cause-specific record of the competing cases, both tie methods:
#
# A. Given pprof_py's tight beta (the fixture's measures$beta) and its provider grouping (the stratum,
#    or id mod 10 for unstratified cases), the observed and expected counts, person-time, and the
#    direct expected counts of K-136 to K-139, against pprof_py's, under the closed_form tier. The
#    direct counts two ways: (1) pprof_py's composite-key suffix sums over all rows; (2) suffix sums
#    within each provider's own rows.
# B. Given pprof_py's observed and expected counts (the fixture's tests), the mid-p and exact
#    statistics, p-values, flags, and limits of K-140 to K-142 against pprof_py's. The mid-p limits two
#    ways: (1) pprof_py's algorithm per provider with uniroot() (its bracket, split point, and Brent
#    tolerances); (2) once per distinct observed count O, to rounding, since the limits on the
#    Poisson-mean scale depend on O alone, then divided by E. Differences in units of pprof_py's xtol,
#    1e-10 max(E, 1) on the mean scale, and on the ratio scale under a candidate tier (1e-10, 1e-8).
# C. Negative controls for the statistic and limit tiers (the CoxPH brief's §3.5): the other tie
#    method's tests (pprof_py's), and the tests at the expected counts of the generator's moved-tie and
#    dropped-weight fits, against pprof_py's tests of this tie method.
# D. The time of the mid-p limits at 1,000, 3,000, and 7,500 synthetic providers, both ways; the data
#    sets go to COXPH_FACTS_SCRATCH for 22_measures_tests.py, which times pprof_py's on them.
# E. The time of the national and direct expected counts at 1,000,000 rows and 7,500 providers.
#
# Run from the repository root, with COXPH_FACTS_SCRATCH set:
#   Rscript dev/design/coxph-facts/22_measures_tests.R dev/design/coxph-facts/22_measures_tests_r.txt
args <- commandArgs(trailingOnly = TRUE)
out_file <- if (length(args) >= 1) args[[1]] else "22_measures_tests_r.txt"
source(file.path("tests", "testthat", "helper-tolerances.R"))
lines <- sprintf("%s", R.version.string)
say <- function(...) lines <<- c(lines, sprintf(...))

ratio <- function(a, b, tier) {
  a <- as.numeric(unlist(a))
  b <- as.numeric(unlist(b))
  stopifnot(length(a) == length(b))
  same <- (is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & a == b)
  if (any(!same & (!is.finite(a) | !is.finite(b)))) return(Inf)
  tol <- pprof_tolerances[[tier]]
  ok <- !same
  if (!any(ok)) return(0)
  max(abs(a[ok] - b[ok]) / (tol$atol + tol$rtol * abs(b[ok])))
}

# --- K-136 to K-139: the measures --------------------------------------------------------------------

# sum of r over rows whose key >= q, for each q: suffix sums of r sorted by key (stable), as pprof_py's
# _suffix_sums() and np.searchsorted(side = "left").
suffix_at <- function(keys, r, q) {
  o <- order(keys, method = "radix")
  k <- keys[o]
  s <- c(rev(cumsum(rev(r[o]))), 0)
  s[findInterval(q, k, left.open = TRUE) + 1L]
}
at_risk <- function(q, start, stop, r) suffix_at(stop, r, q) - suffix_at(start, r, q)

national <- function(eta, start, stop, event) {
  r <- exp(eta - max(eta))
  times <- sort(unique(stop[event == 1]))
  d <- tabulate(match(stop[event == 1], times), length(times))
  cumulative <- c(0, cumsum(d / at_risk(times, start, stop, r)))
  list(r = r, rows = r * (cumulative[findInterval(stop, times) + 1L] - cumulative[findInterval(start, times) + 1L]))
}

# pprof_py's direct expected counts: provider risk-set sums from composite keys (provider, time rank)
# over all rows.
direct_composite <- function(eta, start, stop, event, codes, m) {
  r <- exp(eta - max(eta))
  grid <- sort(unique(c(start, stop)))
  span <- length(grid) + 1
  key <- function(c, t) c * span + findInterval(t, grid, left.open = TRUE)
  is_event <- event == 1
  ev_codes <- codes[is_event]
  ev_times <- stop[is_event]
  lo <- key(ev_codes, ev_times)
  hi <- (ev_codes + 1) * span
  kx <- key(codes, stop)
  kb <- key(codes, start)
  rs_provider <- (suffix_at(kx, r, lo) - suffix_at(kx, r, hi)) - (suffix_at(kb, r, lo) - suffix_at(kb, r, hi))
  rs_pop <- at_risk(ev_times, start, stop, r)
  provider_sums(rs_pop / rs_provider, ev_codes, m)
}

# Sums by provider code 0..m-1 in row order (np.bincount's order).
provider_sums <- function(values, codes, m) {
  out <- numeric(m)
  s <- rowsum(values, codes, reorder = TRUE)
  out[as.integer(rownames(s)) + 1L] <- s[, 1]
  out
}

# Within each provider's own rows; the national sums at every event time once.
direct_blocks <- function(eta, start, stop, event, codes, m) {
  r <- exp(eta - max(eta))
  is_event <- event == 1
  times <- sort(unique(stop[is_event]))
  rs_pop <- at_risk(times, start, stop, r)
  by_provider <- split(seq_along(codes), codes)
  out <- numeric(m)
  for (key in names(by_provider)) {
    rows <- by_provider[[key]]
    ev <- rows[is_event[rows]]
    if (length(ev) == 0L) next
    t <- stop[ev]
    out[as.integer(key) + 1L] <- sum(rs_pop[match(t, times)] / at_risk(t, start[rows], stop[rows], r[rows]))
  }
  out
}

# --- K-140 to K-142: the tests -----------------------------------------------------------------------

midp_z <- function(O, E) {
  p_min <- 2 * stats::ppois(O, E) - stats::dpois(O, E)
  p_max <- 2 * (1 - stats::ppois(O - 1, E)) - stats::dpois(O, E)
  z <- stats::qnorm(pmax(1e-6, pmin(p_min, p_max) / 2))
  ifelse(p_min <= p_max, z, -z)
}
two_sided <- function(z) 2 * stats::pnorm(abs(z), lower.tail = FALSE)
flags <- function(z, p, alpha) as.integer(ifelse(!is.na(p) & p < alpha & z > 0, 1L, ifelse(!is.na(p) & p < alpha & z < 0, -1L, 0L)))

exact_test <- function(O, E, alpha) {
  high <- !is.na(O / E) & O / E > 1
  p <- ifelse(high, pmin(0.999, 2 * stats::ppois(O - 1, E, lower.tail = FALSE)), pmin(0.999, 2 * stats::ppois(O, E)))
  z <- sign(O - E) * stats::qnorm(p / 2, lower.tail = FALSE)
  zc <- stats::qnorm(1 - alpha / 2)
  garwood <- E < 100
  lower <- ifelse(O > 0, ifelse(garwood, stats::qchisq(alpha / 2, 2 * O) / 2 / E,
                                (O / E) * (1 - 1 / (9 * O) - zc / (3 * sqrt(O)))^3), 0)
  upper <- ifelse(garwood, stats::qchisq(1 - alpha / 2, 2 * (O + 1)) / 2 / E,
                  ((O + 1) / E) * (1 - 1 / (9 * (O + 1)) + zc / (3 * sqrt(O + 1)))^3)
  list(z = z, p = two_sided(z), lower = lower, upper = upper)
}

# (1) pprof_py's algorithm per provider (provider_tests.py:29-54), uniroot() for brentq.
midp_limits_one <- function(o, e, alpha, m = 0, s = 1) {
  z <- function(t) midp_z(o, t)
  excess <- function(t) 2 * stats::pnorm(abs(z(t) - m) / s, lower.tail = FALSE) - alpha
  lo <- 1e-10 * max(e, 1)
  hi <- 10 * (o + e + 10)
  while (z(hi) > max(m, -4.75) && hi < 1e12) hi <- hi * 10
  mode <- if (z(lo) <= m) lo else if (z(hi) >= m) hi else
    stats::uniroot(function(t) z(t) - m, c(lo, hi), tol = 1e-12 * max(e, 1), maxiter = 1000L)$root
  lower <- if (excess(lo) >= 0) 0 else stats::uniroot(excess, c(lo, mode), tol = 1e-10 * max(e, 1), maxiter = 1000L)$root
  upper <- if (excess(hi) >= 0) Inf else stats::uniroot(excess, c(mode, hi), tol = 1e-10 * max(e, 1), maxiter = 1000L)$root
  c(lower, upper)
}
midp_limits_each <- function(O, E, alpha) {
  t(vapply(seq_along(O), function(i) midp_limits_one(O[i], E[i], alpha), numeric(2)))
}

# (2) Once per distinct O, to rounding: the roots of 2 Phi-bar(|z(t)|) = alpha in the Poisson mean t
# depend on O alone; pprof_py's bracket only sets its tolerance. The decisions "0" and "Inf" are
# pprof_py's, at its own bracket ends for each provider.
midp_limits_distinct <- function(O, E, alpha) {
  values <- sort(unique(O))
  roots <- t(vapply(values, function(o) {
    z <- function(t) midp_z(o, t)
    excess <- function(t) two_sided(z(t)) - alpha
    lo <- 1e-300
    hi <- 10 * (o + 10)
    while (z(hi) > -4.75 && hi < 1e12) hi <- hi * 10
    mode <- if (z(lo) <= 0) lo else stats::uniroot(z, c(lo, hi), tol = 1e-300, maxiter = 2000L)$root
    lower <- if (excess(lo) >= 0) 0 else stats::uniroot(excess, c(lo, mode), tol = 1e-300, maxiter = 2000L)$root
    upper <- stats::uniroot(excess, c(mode, hi), tol = 1e-300, maxiter = 2000L)$root
    c(lower, upper)
  }, numeric(2)))
  at <- match(O, values)
  lower <- roots[at, 1]
  upper <- roots[at, 2]
  # pprof_py's own decisions at its bracket ends.
  lo <- 1e-10 * pmax(E, 1)
  lower[two_sided(midp_z(O, lo)) - alpha >= 0] <- 0
  unname(cbind(lower, upper))
}

# A candidate tier for the mid-p limits on the ratio scale (proposed `cox_root`): pprof_py's xtol,
# 1e-10 max(E, 1) on the Poisson-mean scale, is 1e-10 on the ratio scale when E >= 1 (atol), and at
# most 2e-9 of the limit when E < 1, since every nonzero mid-p limit at level 0.95 is at least 0.05
# (rtol, with a factor of 5).
pprof_tolerances$cox_root_candidate <- list(atol = 1e-10, rtol = 1e-8)


# --- The cases ---------------------------------------------------------------------------------------

# The generator's negative-control data (dev/reference/cox/generate.py): one of two or more tied events
# moved a day later (the first such (stratum, time) group in sorted order, its first row), and the first
# weight other than 1 set to 1 (the measures ignore weights, so only beta changes).
shifted_stop <- function(d) {
  ev <- which(d$event == 1)
  o <- order(d$stratum[ev], d$time[ev], ev)
  s <- d$stratum[ev][o]
  t <- d$time[ev][o]
  i <- which(s[-1] == s[-length(s)] & t[-1] == t[-length(t)])[1]
  stop <- d$time
  stop[ev[o][i]] <- stop[ev[o][i]] + 1
  stop
}

files <- c(list.files(file.path("tests", "testthat", "fixtures", "cox"), "\\.rds$", full.names = TRUE),
           list.files(file.path("validation", "fixtures", "cox"), "\\.rds$", full.names = TRUE))
records <- list()
for (path in files) {
  fx <- readRDS(path)
  id <- fx$case$id
  if (!fx$case$kind %in% c("cox", "competing")) next
  d <- fx$input
  features <- unlist(fx$case$features)
  truncated <- isTRUE(fx$case$truncated)
  for (ties in c("breslow", "efron")) {
    other <- if (ties == "breslow") "efron" else "breslow"
    entries <- if (fx$case$kind == "cox") {
      controls <- fx$pprof_py[[ties]]$negative_controls
      list(list(label = id, event = d$event, offset = if (isTRUE(fx$case$offset)) d$offset else 0,
                provider = if (isTRUE(fx$case$stratified)) d$stratum else d$id %% 10,
                py = fx$pprof_py[[ties]], other = fx$pprof_py[[other]],
                shifted = list(beta = unlist(controls$shifted_tie$coef), stop = shifted_stop(d)),
                dropped = if (!is.null(controls$dropped_weight)) list(beta = unlist(controls$dropped_weight$coef))))
    } else {
      lapply(names(fx$pprof_py[[ties]]$cause_specific), function(cause) {
        list(label = sprintf("%s cause %s", id, cause), event = as.numeric(d$event == as.integer(cause)), offset = 0,
             provider = d$stratum, py = fx$pprof_py[[ties]]$cause_specific[[cause]],
             other = fx$pprof_py[[other]]$cause_specific[[cause]])
      })
    }
    for (entry in entries) {
      records[[length(records) + 1L]] <- c(entry, list(ties = ties, start = if (truncated) d$entry else rep(0, nrow(d)),
                                                        stop = d$time, x = as.matrix(d[, features, drop = FALSE])))
    }
  }
}

# O, E, and person-time by provider code, from beta (K-136, K-137, K-139).
measures_at <- function(rec, beta, stop = rec$stop) {
  eta <- drop(rec$x %*% beta) + rec$offset
  labels <- sort(unique(rec$provider))
  codes <- match(rec$provider, labels) - 1L
  m <- length(labels)
  nat <- national(eta, rec$start, stop, rec$event)
  list(eta = eta, codes = codes, m = m, O = provider_sums(as.numeric(rec$event), codes, m),
       E = provider_sums(nat$rows, codes, m), person_time = provider_sums(stop - rec$start, codes, m))
}

say("")
say("A. Measures at pprof_py's beta, against pprof_py (ratios to the closed_form allowance, 1e-12 + 1e-10|b|)")
say("%-36s %-8s %8s %9s %9s %9s %10s %10s %7s", "case", "ties", "O exact", "E", "pers.time", "sum E=O",
    "direct (1)", "direct (2)", "E=0")
for (rec in records) {
  m_py <- rec$py$measures
  ms <- measures_at(rec, as.numeric(unlist(m_py$beta)))
  dc <- direct_composite(ms$eta, rec$start, rec$stop, rec$event, ms$codes, ms$m)
  db <- direct_blocks(ms$eta, rec$start, rec$stop, rec$event, ms$codes, ms$m)
  say("%-36s %-8s %8s %9.2g %9.2g %9.2g %10.2g %10.2g %7d", rec$label, rec$ties,
      identical(ms$O, as.numeric(unlist(m_py$observed))), ratio(ms$E, m_py$expected, "closed_form"),
      ratio(ms$person_time, m_py$person_time, "closed_form"), abs(sum(ms$E) - sum(rec$event)) / sum(rec$event),
      ratio(dc, m_py$direct_expected, "closed_form"), ratio(db, m_py$direct_expected, "closed_form"), sum(ms$E == 0))
}

# The tests of a set of observed and expected counts.
tests_of <- function(O, E) {
  z <- midp_z(O, E)
  xt <- exact_test(O, E, alpha)
  limits <- midp_limits_distinct(O, E, alpha)
  list(z = z, p = two_sided(z), flag = flags(z, two_sided(z), alpha), exact_z = xt$z, exact_p = xt$p,
       exact_flag = flags(xt$z, xt$p, alpha), exact_lower = xt$lower, exact_upper = xt$upper,
       midp_lower = limits[, 1] / E, midp_upper = limits[, 2] / E, mean_lower = limits[, 1], mean_upper = limits[, 2])
}

alpha <- 1 - 0.95
say("")
say("B. Tests given pprof_py's O and E (ratios to each tier's allowance; flags compared exactly). Mid-p limits:")
say("   once per distinct O (2), on the ratio scale under the candidate cox_root tier (1e-10, 1e-8), and on the")
say("   mean scale in units of pprof_py's xtol, 1e-10 max(E, 1); per provider as pprof_py (1), in xtol units.")
say("%-36s %-6s %7s %7s %5s %7s %7s %5s %8s %9s %8s %8s", "case", "ties", "midp z", "midp p", "flags",
    "exact z", "exact p", "flags", "exact ci", "midp root", "(2) xtol", "(1) xtol")
controls <- list()
for (rec in records) {
  mp <- rec$py$tests$midp
  ex <- rec$py$tests$exact
  O <- as.numeric(unlist(mp$observed))
  E <- as.numeric(unlist(mp$expected))
  r <- tests_of(O, E)
  l1 <- midp_limits_each(O, E, alpha)
  positive <- E > 0
  xtol <- 1e-10 * pmax(E, 1)
  units <- function(a, b) {
    a <- a[positive]
    b <- b[positive]
    if (any(xor(is.finite(a), is.finite(b)))) return(Inf)
    both <- is.finite(a) & is.finite(b)
    if (!any(both)) return(0)
    max(abs(a[both] - b[both]) / xtol[positive][both])
  }
  py_mean_lower <- as.numeric(unlist(mp$ci_lower)) * E
  py_mean_upper <- as.numeric(unlist(mp$ci_upper)) * E
  root_ratio <- max(ratio(r$midp_lower, mp$ci_lower, "cox_root_candidate"),
                    ratio(r$midp_upper, mp$ci_upper, "cox_root_candidate"))
  say("%-36s %-6s %7.2g %7.2g %5s %7.2g %7.2g %5s %8.2g %9.2g %8.2g %8.2g", rec$label, rec$ties,
      ratio(r$z, mp$z_raw, "cox_statistic"), ratio(r$p, mp$p_value, "probability"),
      identical(r$flag, as.integer(unlist(mp$flag))), ratio(r$exact_z, ex$z_raw, "cox_statistic"),
      ratio(r$exact_p, ex$p_value, "probability"), identical(r$exact_flag, as.integer(unlist(ex$flag))),
      max(ratio(r$exact_lower, ex$ci_lower, "closed_form"), ratio(r$exact_upper, ex$ci_upper, "closed_form")),
      root_ratio, max(units(r$mean_lower, py_mean_lower), units(r$mean_upper, py_mean_upper)),
      max(units(l1[, 1], py_mean_lower), units(l1[, 2], py_mean_upper)))
  # C. Negative controls, each against pprof_py's tests of this tie method, in the same units: the other
  # tie method's tests (pprof_py's), and the tests at the expected counts of the generator's moved-tie and
  # dropped-weight fits (E from the control's beta by the closed form above).
  versus <- function(name, c_r) {
    data.frame(case = rec$label, ties = rec$ties, control = name, z = ratio(c_r$z, mp$z_raw, "cox_statistic"),
               p = ratio(c_r$p, mp$p_value, "probability"),
               midp = max(ratio(c_r$midp_lower, mp$ci_lower, "cox_root_candidate"),
                          ratio(c_r$midp_upper, mp$ci_upper, "cox_root_candidate")),
               exact = max(ratio(c_r$exact_lower, ex$ci_lower, "closed_form"),
                           ratio(c_r$exact_upper, ex$ci_upper, "closed_form")))
  }
  om <- rec$other$tests$midp
  oe <- rec$other$tests$exact
  controls[[length(controls) + 1L]] <- versus("other ties", list(
    z = unlist(om$z_raw), p = unlist(om$p_value), midp_lower = unlist(om$ci_lower), midp_upper = unlist(om$ci_upper),
    exact_lower = unlist(oe$ci_lower), exact_upper = unlist(oe$ci_upper)))
  if (!is.null(rec$shifted)) {
    ms <- measures_at(rec, rec$shifted$beta, stop = rec$shifted$stop)
    controls[[length(controls) + 1L]] <- versus("moved tie", tests_of(ms$O, ms$E))
  }
  if (!is.null(rec$dropped)) {
    ms <- measures_at(rec, rec$dropped$beta)
    controls[[length(controls) + 1L]] <- versus("dropped weight", tests_of(ms$O, ms$E))
  }
}

say("")
say("C. Negative controls against pprof_py's tests of this tie method (same tiers as B; each must be >= 10)")
ctl <- do.call(rbind, controls)
for (i in seq_len(nrow(ctl))) {
  say("%-36s %-6s %-15s z %9.3g  p %9.3g  mid-p limits %9.3g  exact limits %9.3g", ctl$case[i], ctl$ties[i],
      ctl$control[i], ctl$z[i], ctl$p[i], ctl$midp[i], ctl$exact[i])
}
say("Weakest control: z %.3g, p %.3g, mid-p limits %.3g, exact limits %.3g", min(ctl$z), min(ctl$p), min(ctl$midp),
    min(ctl$exact))

say("")
say("D. Time of the mid-p limits (seconds; one run each, after a warm-up). The data sets go to")
say("   COXPH_FACTS_SCRATCH, where 22_measures_tests.py times pprof_py's own limits on them.")
scratch <- Sys.getenv("COXPH_FACTS_SCRATCH")
set.seed(20261009)  # a development script: package code never calls set.seed()
for (m in c(1000, 3000, 7500)) {
  E <- stats::rlnorm(m, log(20), 1)
  O <- stats::rpois(m, E * exp(stats::rnorm(m, 0, 0.25)))
  invisible(midp_limits_distinct(O[1:10], E[1:10], alpha))
  t1 <- system.time(l1 <- midp_limits_each(O, E, alpha))[["elapsed"]]
  t2 <- system.time(l2 <- midp_limits_distinct(O, E, alpha))[["elapsed"]]
  finite <- is.finite(l1)
  say("%5d providers, %4d distinct O: per provider %6.2f s; per distinct O %5.2f s; largest difference %.2g xtol",
      m, length(unique(O)), t1, t2, max(abs(l1 - l2)[finite] / (1e-10 * pmax(E, 1))[row(l1)[finite]]))
  if (nzchar(scratch)) {
    utils::write.csv(data.frame(observed = O, expected = sprintf("%a", E), lower = sprintf("%a", l2[, 1]),
                                upper = sprintf("%a", l2[, 2]), seconds = t2),
                     file.path(scratch, sprintf("22_midp_%d.csv", m)), row.names = FALSE)
  }
}

say("")
say("E. Time of the measures at 1,000,000 rows and 7,500 providers (the benchmark's corner data, 5 covariates;")
say("   seconds, one run each)")
source(file.path("dev", "bench", "cox", "scenarios.R"))
d <- cox_bench_data(1e6, 7500, 5, 108)
eta <- drop(as.matrix(d[, grep("^x", names(d))]) %*% c(0.3, -0.2, 0.15, -0.1, 0.05)) + d$offset
codes <- d$provider
t_nat <- system.time(nat <- national(eta, d$start, d$stop, d$event))[["elapsed"]]
t_sum <- system.time(E <- provider_sums(nat$rows, codes, 7500))[["elapsed"]]
t_dc <- system.time(dc <- direct_composite(eta, d$start, d$stop, d$event, codes, 7500))[["elapsed"]]
t_db <- system.time(db <- direct_blocks(eta, d$start, d$stop, d$event, codes, 7500))[["elapsed"]]
say("national expected counts per row %.2f s, summed by provider %.2f s; direct (1) composite keys %.2f s,", t_nat,
    t_sum, t_dc)
say("(2) within providers %.2f s; the two directs differ by at most %.2g relative; sum(E) - O = %.3g", t_db,
    max(abs(dc - db) / abs(db), na.rm = TRUE), sum(E) - sum(d$event))
writeLines(lines, out_file)
