# CoxPH Phase C3 plan: the funnel limits of Cox models. After 23_funnel_limits.py, which ran pprof_py
# v0.7.0's CoxPH.funnel_limits() on the rc-stratified and provider-scale fixture cases, both tie
# methods, with the mid-p and exact tests at level 0.95 (curves at 0.95 and 0.998), compares:
#
# 1. pprof_py's limits with its own flags: a provider is outside its limits exactly when flagged;
# 2. M-39's limits (COXPH_DESIGN §B.3, §D.2: 1 -/+ qnorm(1 - alpha / 2) / sqrt(E), lower floored at 0)
#    with pprof_py's flags: providers outside them but not flagged, and flagged but inside;
# 3. pprof_py's limits, per provider and on its curves, with the same construction written in plain R
#    (base and stats only): for each expected count E, the largest count the test flags low (o_lo) and
#    the smallest it flags high (o_hi) among 0, ..., ceil(max(E, O) + 40 sqrt(E) + 50), and the limits
#    (o_lo + 1/2) / E and (o_hi - 1/2) / E on the O/E scale (-Inf and Inf where there is none).
#
# Run from the repository root, after the Python script, with COXPH_FACTS_SCRATCH set:
#   Rscript dev/design/coxph-facts/23_funnel_limits.R <output file>
args <- commandArgs(trailingOnly = TRUE)
out_file <- if (length(args) >= 1) args[[1]] else "23_funnel_limits.txt"
scratch <- Sys.getenv("COXPH_FACTS_SCRATCH")
lines <- sprintf("%s", R.version.string)
say <- function(...) lines <<- c(lines, sprintf(...))

midp_z <- function(O, E) {
  p_min <- 2 * stats::ppois(O, E) - stats::dpois(O, E)
  p_max <- 2 * (1 - stats::ppois(O - 1, E)) - stats::dpois(O, E)
  z <- stats::qnorm(pmax(1e-6, pmin(p_min, p_max) / 2))
  ifelse(p_min <= p_max, z, -z)
}
exact_z <- function(O, E) {
  high <- !is.na(O / E) & O / E > 1
  p <- ifelse(high, pmin(0.999, 2 * stats::ppois(O - 1, E, lower.tail = FALSE)), pmin(0.999, 2 * stats::ppois(O, E)))
  sign(O - E) * stats::qnorm(p / 2, lower.tail = FALSE)
}
decide <- function(z, alpha) {
  p <- 2 * stats::pnorm(abs(z), lower.tail = FALSE)
  ifelse(p < alpha & z > 0, 1L, ifelse(p < alpha & z < 0, -1L, 0L))
}
# The count boundaries at expected count E (pprof_py's _poisson_nmax(), _bisect(), _ratio_limits()).
count_limits <- function(E, O, z_of, alpha) {
  nmax <- ceiling(pmax(E, O) + 40 * sqrt(E) + 50)
  t(vapply(seq_along(E), function(i) {
    counts <- 0:nmax[i]
    f <- decide(z_of(counts, rep(E[i], length(counts))), alpha)
    o_hi <- if (any(f == 1L)) min(counts[f == 1L]) else nmax[i] + 1
    o_lo <- if (any(f == -1L)) max(counts[f == -1L]) else -1
    c(if (o_lo >= 0) (o_lo + 0.5) / E[i] else -Inf, if (o_hi <= nmax[i]) (o_hi - 0.5) / E[i] else Inf)
  }, numeric(2)))
}
same <- function(a, b) sum(!((is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & a == b)))

say("")
say("Columns: providers; flagged by pprof_py; tested providers outside pprof_py's limits but unflagged, and")
say("flagged but inside; under M-39's normal limits, the same two counts; and the providers (limits) and")
say("curve points (both levels) where the R construction differs from pprof_py's (exact comparison).")
say("%-15s %-8s %-6s %5s %7s %13s %13s %13s %13s %9s %9s", "case", "ties", "test", "n", "flagged",
    "py: out,unfl", "py: in,flag", "M-39: out,unfl", "M-39: in,flag", "R limits", "R curves")
for (case in c("rc-stratified", "provider-scale")) {
  for (ties in c("breslow", "efron")) {
    for (test in c("midp", "exact")) {
      stem <- file.path(scratch, sprintf("23_%s_%s_%s", case, ties, test))
      p <- utils::read.csv(paste0(stem, "_providers.csv"))
      curves <- utils::read.csv(paste0(stem, "_curves.csv"))
      z_of <- if (test == "midp") midp_z else exact_z
      alpha <- 1 - 0.95
      tested <- !is.na(p$flag)
      flagged <- tested & p$flag != 0
      outside <- p$estimate > p$upper | p$estimate < p$lower
      zc <- stats::qnorm(1 - alpha / 2)
      normal_lower <- pmax(1 - zc / sqrt(p$expected), 0)
      normal_upper <- 1 + zc / sqrt(p$expected)
      normal_outside <- p$estimate > normal_upper | p$estimate < normal_lower
      r <- count_limits(p$expected, p$observed, z_of, alpha)
      curve_diff <- 0
      for (level in unique(curves$level)) {
        k <- curves$level == level
        rc <- count_limits(curves$precision[k], rep(0, sum(k)), z_of, 1 - level)
        curve_diff <- curve_diff + same(rc[, 1], curves$lower[k]) + same(rc[, 2], curves$upper[k])
      }
      say("%-15s %-8s %-6s %5d %7d %13d %13d %13d %13d %9d %9d", case, ties, test, nrow(p), sum(flagged),
          sum(tested & outside & !flagged), sum(tested & !outside & flagged),
          sum(tested & normal_outside & !flagged), sum(tested & !normal_outside & flagged),
          same(r[, 1], p$lower) + same(r[, 2], p$upper), curve_diff)
    }
  }
}
writeLines(lines, out_file)
