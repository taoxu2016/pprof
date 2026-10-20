# Logistic extensions design (Phase L0), §A: behaviors of pprofR 0.2.0 that the design specifies and
# facts 02 to 08 do not show, each against a plain-R version of the definition the design gives it:
#   (a) the bootstrap test of binomial outcomes: its draws, in provider order, with rbinom()'s
#       size the rows' trials, and a size of 1 written as a vector or as a number;
#   (b) the modified score test and the model-based Wald standard errors of binomial outcomes,
#       the latter against the block inverse at clamped probabilities (K-20's rule);
#   (c) the robust and stabilized tests of providers with a single cluster;
#   (d) the exact and score intervals of binomial outcomes against the same equations solved with
#       pprof's root finder (uniroot() at its defaults in K-90's brackets);
#   (e) rows with zero trials, and a provider whose rows all have zero trials.
# Run from the repository root after 01: Rscript dev/design/logistic-facts/09_pprofr_specifications.R <output file>
source("dev/design/logistic-facts/facts_data.R")
args <- commandArgs(trailingOnly = TRUE)
facts_use_libraries()
suppressPackageStartupMessages(library(pprofR))
out <- c("# 09: pprofR's behaviors that the design specifies", "",
         sprintf("pprofR %s, %s.", utils::packageVersion("pprofR"), R.version.string), "")

d <- facts_simulate(m = 20, clusters = c(5, 15), trials = c(1, 12), seed = 12)
fit <- pprofR::logis_fe(facts_pprofr_prep(d, binomial = TRUE, cutoff = 1), tol = 1e-10, stop = "beta")
rows <- fit$data_include
gamma <- as.numeric(fit$gamma)
eta <- as.numeric(fit$linear_pred)
providers <- rownames(fit$gamma)
by_provider <- split(seq_len(nrow(rows)), factor(rows$provider, levels = providers))
null <- stats::median(gamma)
p0 <- stats::plogis(null + eta)
out <- c(out, facts_header("## (a) to (c): tests"))

# (a) The bootstrap: one rbinom() call per provider, in provider order, laid out as K-64 lays out
# the binary draws, with the rows' trials as the size.
set.seed(21)
boot <- pprofR::test_fe(fit, test = "exact.bootstrap", n = 500)
set.seed(21)
replica <- vapply(by_provider, function(r) {
  draws <- stats::rbinom(n = length(r) * 500, size = rep(rows$N[r], times = 500), prob = rep(p0[r], times = 500))
  totals <- colSums(matrix(draws, ncol = 500))
  o <- sum(rows$y[r])
  p <- (sum(totals > o) + 0.5 * sum(totals == o)) / 500
  2 * min(p, 1 - p)
}, numeric(1))
set.seed(22)
scalar <- stats::rbinom(1000, size = 1, prob = rep(0.3, 1000))
set.seed(22)
vector <- stats::rbinom(1000, size = rep(1, 1000), prob = rep(0.3, 1000))
out <- c(out, facts_row("(a) bootstrap p-values against the plain-R draws (seed 21, 500 draws)", boot$p, replica),
         sprintf("| (a) rbinom() with size 1 as a number and as a vector: identical draws | %s | | |",
                 identical(scalar, vector)))

# (b) The modified score test, and the Wald standard errors.
score <- pprofR::test_fe(fit, test = "score")
plain_score <- vapply(by_provider, function(r) {
  sum(rows$y[r] - rows$N[r] * p0[r]) / sqrt(sum(rows$N[r] * p0[r] * (1 - p0[r])))
}, numeric(1))
wald <- pprofR::test_fe(fit, test = "wald", null = 0)
design <- as.matrix(rows[c("x1", "x2", "x3")])
block_inverse_se <- function(p) {
  w <- rows$N * p * (1 - p)
  diagonal <- vapply(by_provider, function(r) sum(w[r]), numeric(1))
  cross <- vapply(by_provider, function(r) colSums(design[r, , drop = FALSE] * w[r]), numeric(3))
  schur <- crossprod(design, design * w) - cross %*% (t(cross) / diagonal)
  inverse <- solve(schur)
  vapply(seq_along(diagonal), function(i) {
    j <- cross[, i] / diagonal[i]
    sqrt(1 / diagonal[i] + drop(t(j) %*% inverse %*% j))
  }, numeric(1))
}
fitted_p <- stats::plogis(rep(gamma, lengths(by_provider)) + eta)
out <- c(out, facts_row("(b) score statistics against sum(y - n p0) / sqrt(sum(n p0 (1 - p0)))", score$stat, plain_score),
         facts_row("(b) Wald standard errors against the block inverse at unclamped probabilities", wald$se.gamma,
                   block_inverse_se(fitted_p)),
         facts_row("(b) Wald standard errors against the block inverse at clamped probabilities (K-20)", wald$se.gamma,
                   block_inverse_se(pmin(pmax(fitted_p, 1e-10), 1 - 1e-10))))

# (c) Every provider one cluster: the robust variance is the square of the provider's residual sum,
# while the stabilized one pools the within-cluster correlation over all clusters.
single <- d
single$cluster <- single$provider
fit_single <- pprofR::logis_fe(facts_pprofr_prep(single, binomial = TRUE, cutoff = 1), tol = 1e-10, stop = "beta")
robust_score <- pprofR::test_fe(fit_single, test = "robust_score")$stat
stable_score <- pprofR::test_fe(fit_single, test = "stabilized_score")$stat
stable_wald <- pprofR::test_fe(fit_single, test = "stabilized_wald", null = 0)
model_wald <- pprofR::test_fe(fit_single, test = "wald", null = 0)
out <- c(out, sprintf("| (c) one cluster per provider: robust score statistics, distinct values | %s | | |",
                      paste(sort(unique(robust_score)), collapse = ", ")),
         sprintf("| (c) one cluster per provider: stabilized score statistics, range | %.3g to %.3g | | |",
                 min(stable_score), max(stable_score)),
         sprintf("| (c) one cluster per provider: stabilized over model-based Wald standard errors, range | %.3g to %.3g | | |",
                 min(stable_wald$se.gamma / model_wald$se.gamma), max(stable_wald$se.gamma / model_wald$se.gamma)), "")

# (d) Intervals of binomial outcomes with pprof's root finder: uniroot() at its defaults in K-90's
# brackets, gamma -/+ 5 (k, k + 1) for k = 0, 1, 2, on pprofR's equations.
root_in <- function(f, brackets, none) {
  for (b in brackets) {
    r <- tryCatch(stats::uniroot(f, b)$root, error = function(e) NULL)
    if (!is.null(r)) return(r)
  }
  none
}
alpha <- 0.05
limits_k90 <- function(i, test) {
  r <- by_provider[[i]]
  zb <- eta[r]
  nt <- rows$N[r]
  o <- sum(rows$y[r])
  g <- gamma[i]
  if (test == "exact") {
    trial_p <- function(x) rep(stats::plogis(x + zb), nt)
    upper <- function(x) poibin::ppoibin(o - 1, trial_p(x)) + 0.5 * poibin::dpoibin(o, trial_p(x)) - alpha / 2
    lower <- function(x) 1 - poibin::ppoibin(o, trial_p(x)) + 0.5 * poibin::dpoibin(o, trial_p(x)) - alpha / 2
  } else {
    z_of <- function(x) {
      p <- stats::plogis(x + zb)
      (o - sum(nt * p)) / sqrt(sum(nt * p * (1 - p)))
    }
    q <- stats::qnorm(alpha / 2, lower.tail = FALSE)
    upper <- function(x) z_of(x) + q
    lower <- function(x) z_of(x) - q
  }
  c(root_in(lower, lapply(0:2, function(k) g - 5 * c(k + 1, k)), -Inf),
    root_in(upper, lapply(0:2, function(k) g + 5 * c(k, k + 1)), Inf))
}
finite <- which(!(tapply(rows$no.events, factor(rows$provider, levels = providers), max) |
                  tapply(rows$all.events, factor(rows$provider, levels = providers), max)))
out <- c(out, facts_header("## (d) Binomial intervals with pprof's root finder against pprofR's"))
for (test in c("exact", "score")) {
  ci <- stats::confint(fit, option = "gamma", test = test)
  ours <- t(vapply(finite, limits_k90, numeric(2), test = test))
  out <- c(out, facts_row(sprintf("(d) %s limits of the %d providers with events and non-events", test, length(finite)),
                          c(ci$gamma.lower[finite], ci$gamma.upper[finite]), c(ours[, 1], ours[, 2])))
}
out <- c(out, "")

# (e) Rows with zero trials, and a provider whose rows all have zero trials.
with_zero <- d
extra <- d[d$provider == d$provider[1], ][1:3, ]
extra$n <- 0L
extra$y <- 0L
extra$cluster <- paste0(extra$cluster, "z")
with_zero <- rbind(d, extra)
with_zero <- with_zero[order(with_zero$provider, with_zero$cluster), ]
fit_zero <- pprofR::logis_fe(facts_pprofr_prep(with_zero, binomial = TRUE, cutoff = 1), tol = 1e-10, stop = "beta")
out <- c(out, facts_header("## (e) Zero trials"),
         facts_row("(e) three rows with zero trials added: coefficients against the fit without them", fit_zero$beta, fit$beta),
         facts_row("(e) the same: provider effects", fit_zero$gamma, fit$gamma),
         sprintf("| (e) the same: BIC, with and without the rows (%d and %d rows) | %.10g, %.10g | | |", nrow(with_zero),
                 nrow(d), fit_zero$BIC, fit$BIC))
empty <- d
empty$n[empty$provider == empty$provider[1]] <- 0L
empty$y[empty$provider == empty$provider[1]] <- 0L
fit_empty <- tryCatch(pprofR::logis_fe(facts_pprofr_prep(empty, binomial = TRUE, cutoff = 1), tol = 1e-10, stop = "beta"),
                      error = function(e) conditionMessage(e))
out <- c(out, if (is.character(fit_empty)) {
  sprintf("| (e) a provider with no trials: an error, %s | | | |", fit_empty)
} else {
  sprintf("| (e) a provider with no trials: fitted; its effect %.4g (the median %.4g), its Wald standard error %.4g, flagged no events %s and all events %s | | | |",
          fit_empty$gamma[1], stats::median(fit_empty$gamma),
          pprofR::test_fe(fit_empty, test = "wald", null = 0)$se.gamma[1],
          any(fit_empty$data_include$no.events[fit_empty$data_include$provider == empty$provider[1]] == 1),
          any(fit_empty$data_include$all.events[fit_empty$data_include$provider == empty$provider[1]] == 1))
})
writeLines(out, args[1])
