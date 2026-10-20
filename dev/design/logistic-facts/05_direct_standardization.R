# Logistic extensions brief, Appendix A: pprofR 0.2.0's direct standardization algorithm (rows
# with equal linear predictors merged, exp() factored out of the inner loop, sums in long double)
# against pprof's (the sum over every row, in double, as pprof 1.0.3's computeDirectExp() sums it),
# for accuracy and time, on one thread:
#   (a) differences between the two, and of each from a reference: R's sum() of plogis(), which
#       accumulates in long double here, over every row;
#   (b) the complement n - E for effects whose direct rate is near 1, where the double sum loses
#       digits;
#   (c) the time for 2,000 effects over 200,000 rows with a continuous linear predictor and with
#       eight distinct values, the two algorithms interleaved in one process.
# Effects range over typical values and a few far ones (+-15, +-30); the weights are 1 (binary
# outcomes), and for pprofR also a number of trials per row.
# Run from the repository root after 01: Rscript dev/design/logistic-facts/05_direct_standardization.R <output file>
source("dev/design/logistic-facts/facts_data.R")
args <- commandArgs(trailingOnly = TRUE)
facts_use_libraries()
suppressPackageStartupMessages({
  library(pprof)
  library(pprofR)
})
out <- c("# 05: the direct standardization algorithm", "",
         sprintf("pprofR %s, pprof %s, %s; long double of %d bytes.", utils::packageVersion("pprofR"),
                 utils::packageVersion("pprof"), R.version.string, .Machine$sizeof.longdouble), "")
pprof_direct <- function(effects, eta) pprof:::cpp_logistic_direct_expected(effects, eta, 1L)
pprofr_direct <- function(effects, eta, w = rep(1, length(eta))) pprofR:::computeDirectExp(effects, eta, w, 1L)
reference <- function(effects, eta, w = rep(1, length(eta))) {
  vapply(effects, function(g) sum(w * stats::plogis(g + eta)), numeric(1))
}
reference_complement <- function(effects, eta, w = rep(1, length(eta))) {
  vapply(effects, function(g) sum(w * stats::plogis(-(g + eta))), numeric(1))
}

set.seed(7)
n <- 200000
continuous <- drop(cbind(stats::rnorm(n), stats::rbinom(n, 1, 0.4), stats::runif(n, -1, 1)) %*% c(0.5, -0.4, 0.3))
categorical <- drop(cbind(stats::rbinom(n, 1, 0.3), stats::rbinom(n, 1, 0.5), stats::rbinom(n, 1, 0.2)) %*% c(0.7, -0.4, 1.1))
trials <- sample(1:30, n, replace = TRUE)
effects <- c(stats::rnorm(40, -1, 0.8), -15, 15, -30, 30)

out <- c(out, facts_header("## (a) Accuracy against R's long-double sum of plogis()"))
for (case in c("continuous", "categorical")) {
  eta <- get(case)
  ref <- reference(effects, eta)
  a <- pprof_direct(effects, eta)
  b <- pprofr_direct(effects, eta)
  out <- c(out, facts_row(sprintf("%s: pprofR against pprof", case), b[, 1], a),
           facts_row(sprintf("%s: pprof against the reference", case), a, ref),
           facts_row(sprintf("%s: pprofR against the reference", case), b[, 1], ref),
           facts_row(sprintf("%s: pprofR's sum of p (1 - p) against the reference, plogis(x) plogis(-x)", case),
                     b[, 2], vapply(effects, function(g) sum(stats::plogis(g + eta) * stats::plogis(-(g + eta))),
                                    numeric(1))))
  bw <- pprofr_direct(effects, eta, trials)
  out <- c(out, facts_row(sprintf("%s, trials 1 to 30: pprofR against the reference", case), bw[, 1],
                          reference(effects, eta, trials)))
}
out <- c(out, "", facts_header("## (b) The complement n - E, for effects with a direct rate near 1"))
near_one <- c(12, 15, 20, 25)
for (case in c("continuous", "categorical")) {
  eta <- get(case)
  ref <- reference_complement(near_one, eta)
  out <- c(out, facts_row(sprintf("%s: pprof, n - E", case), n - pprof_direct(near_one, eta), ref),
           facts_row(sprintf("%s: pprofR, n - E", case), n - pprofr_direct(near_one, eta)[, 1], ref))
}

out <- c(out, "", "## (c) Time, 2,000 effects over 200,000 rows, one thread (medians of 3, interleaved)", "",
         "| Linear predictor | Distinct values | pprof (s) | pprofR (s) | Ratio |", "|---|---|---|---|---|")
many <- stats::rnorm(2000, -1, 0.8)
for (case in c("continuous", "categorical")) {
  eta <- get(case)
  times <- matrix(NA_real_, 3, 2)
  for (k in 1:3) {
    times[k, 1] <- system.time(pprof_direct(many, eta))[["elapsed"]]
    times[k, 2] <- system.time(pprofr_direct(many, eta))[["elapsed"]]
  }
  medians <- apply(times, 2, stats::median)
  out <- c(out, sprintf("| %s | %d | %.2f | %.3f | %.1f |", case, length(unique(eta)), medians[1], medians[2],
                        medians[1] / max(medians[2], 1e-3)))
}
writeLines(out, args[1])
