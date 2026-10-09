# CoxPH Phase C3, after its benchmarks: the package's mid-p limits found by bisection over all the
# distinct observed counts at once (infer_poisson_midp_roots(), DEC-110), against the same roots found
# with uniroot() one count at a time, as the package found them before (the C3 plan's §3.3, written out
# below). The C3 benchmarks found the per-count search too slow where nearly every provider has a count
# of its own (100 providers: 8 times faster than pprof_py, where DEC-111 asks for 10).
#
# A. For the counts 0 to 3,000 and some larger ones, at seven levels: how many roots are identical, the
#    largest relative difference, whether the decisions of 0 and Inf agree, and the equation
#    2 Phi-bar(|z(O, t)|) - alpha at the bisection's roots.
# B. The time of both on 100, 1,000, and 3,000 distinct counts at level 0.95 (median of 5 runs).
#
# Run from the repository root:
#   Rscript dev/design/coxph-facts/24_midp_bisection.R dev/design/coxph-facts/24_midp_bisection.txt
args <- commandArgs(trailingOnly = TRUE)
out_file <- if (length(args) >= 1) args[[1]] else "24_midp_bisection.txt"
suppressMessages(devtools::load_all(quiet = TRUE))
lines <- sprintf("%s", R.version.string)
say <- function(...) lines <<- c(lines, sprintf(...))

# The package's search before the change: per count, uniroot() to rounding on the statistic's root and
# on each side of it, with pprof_py's bracket end.
per_count <- function(observed, alpha) {
  statistic <- function(mean) infer_poisson_midp_statistic(observed, mean)
  excess <- function(mean) infer_poisson_midp_excess(observed, mean, alpha)
  low <- .Machine$double.xmin
  high <- infer_poisson_midp_bracket_high(observed, 0)
  root <- function(f, lower, upper) stats::uniroot(f, c(lower, upper), tol = 1e-300, maxiter = 2000L)$root
  middle <- if (statistic(low) <= 0) low else root(statistic, low, high)
  c(if (excess(low) >= 0) 0 else root(excess, low, middle),
    if (excess(high) >= 0) Inf else root(excess, middle, high))
}
uniroot_roots <- function(counts, alpha) vapply(counts, per_count, numeric(2), alpha = alpha)

say("")
say("A. Bisection over the counts against uniroot() per count, counts 0 to 3,000 and 3,500, 5,000, 1e4, 5e4, 2e5")
say("%-10s %16s %14s %10s %12s %24s", "level", "identical roots", "largest rel.", "in ulp", "0/Inf agree",
    "max |equation| at roots")
counts <- c(0:3000, 3500, 5000, 1e4, 5e4, 2e5)
relative <- function(a, b) ifelse(a == b, 0, abs(a - b) / pmax(abs(a), abs(b)))
for (level in c(0.5, 0.8, 0.95, 0.99, 0.998, 1 - 1e-5, 1 - 1e-6)) {
  alpha <- 1 - level
  a <- uniroot_roots(counts, alpha)
  b <- unname(infer_poisson_midp_roots(counts, alpha))
  agree <- identical(is.infinite(a), is.infinite(b)) && identical(a == 0, b == 0)
  both <- is.finite(a) & is.finite(b) & a > 0 & b > 0
  largest <- if (any(both)) max(relative(a[both], b[both])) else 0
  at <- matrix(counts, 2, length(counts), byrow = TRUE)
  equation <- if (any(both)) max(abs(infer_poisson_midp_excess(at[both], b[both], alpha))) else 0
  say("%-10s %8d of %5d %14.2e %10.1f %12s %24.2e", format(level), sum(a == b), length(a), largest,
      largest / .Machine$double.eps, agree, equation)
}

say("")
say("B. Time at level 0.95, median of 5 runs (seconds)")
for (k in c(100, 1000, 3000)) {
  set <- seq_len(k) + 50
  time_of <- function(f) stats::median(vapply(1:5, function(i) system.time(f(set, 0.05))[["elapsed"]], numeric(1)))
  say("%5d distinct counts (51 to %d): uniroot() per count %.3f, bisection over the counts %.3f", k, k + 50,
      time_of(uniroot_roots), time_of(infer_poisson_midp_roots))
}
writeLines(lines, out_file)
