# Logistic extensions brief, Appendix A: pprofR 0.2.0 on binomial outcomes (a number of trials
# per row) against two independent references:
#   (a) glm() with the two-column response cbind(y, n - y) and provider indicators, at tight
#       convergence: the estimates, their covariance, and the log-likelihood, which pprofR computes
#       without the constant sum(lchoose(n, y));
#   (b) pprof's existing binary code on the data expanded into one row per trial (y rows with 1
#       and n - y with 0): the fit and its iteration path, the provider tests, the intervals, and
#       the standardized measures, whose definitions for binomial outcomes are those of the
#       expanded binary data.
# Then (c) the cost of the exact Poisson-binomial test when it works on the individual trials, as
# pprofR's does, against a convolution of the rows' binomial distributions.
# Run from the repository root after 01: Rscript dev/design/logistic-facts/03_binomial_references.R <output file>
source("dev/design/logistic-facts/facts_data.R")
args <- commandArgs(trailingOnly = TRUE)
facts_use_libraries()
suppressPackageStartupMessages({
  library(pprof)
  library(pprofR)
})
out <- c("# 03: binomial outcomes against glm() and the expanded binary data", "",
         sprintf("pprofR %s, pprof %s, %s.", utils::packageVersion("pprofR"), utils::packageVersion("pprof"),
                 R.version.string), "")

d <- facts_simulate(m = 30, clusters = c(6, 20), trials = c(5, 20), seed = 3)
prep <- facts_pprofr_prep(d, binomial = TRUE, cluster = FALSE, cutoff = 1)

# (a) glm() at tight convergence.
fit_tight <- pprofR::logis_fe(prep, tol = 1e-13, stop = "beta")
g <- stats::glm(cbind(y, n - y) ~ 0 + factor(provider) + x1 + x2 + x3, family = stats::binomial(), data = d,
                control = stats::glm.control(epsilon = 1e-15, maxit = 100))
cf <- stats::coef(g)
v <- stats::vcov(g)
effects <- grep("^factor", names(cf))
out <- c(out, facts_header(sprintf("## (a) pprofR against glm(cbind(y, n - y) ~ 0 + provider + x): %d rows, %d trials, %d providers",
                                   nrow(d), sum(d$n), length(unique(d$provider)))),
         sprintf("| pprofR iterations (stop = \"beta\", tol 1e-13); glm() iterations | %d; %d | | |", fit_tight$control$iter, g$iter),
         facts_row("coefficients", fit_tight$beta, cf[c("x1", "x2", "x3")]),
         facts_row("provider effects", fit_tight$gamma, cf[effects]),
         facts_row("covariance of the coefficients", vcov(fit_tight), v[c("x1", "x2", "x3"), c("x1", "x2", "x3")]),
         facts_row("variance of the provider effects", attr(vcov(fit_tight), "var.gamma"), diag(v)[effects]),
         facts_row("log-likelihood + sum(lchoose(n, y)) against logLik()", -fit_tight$neg2Loglkd / 2 + sum(lchoose(d$n, d$y)),
                   as.numeric(stats::logLik(g))),
         sprintf("| BIC: pprofR counts %d rows; the expanded binary data have %d observations | | | |", nrow(d), sum(d$n)), "")

# (b) The expanded binary data, fit by pprof with the same settings.
expand <- function(d) {
  index <- rep(seq_len(nrow(d)), d$n)
  outcome <- unlist(lapply(seq_len(nrow(d)), function(i) c(rep(1L, d$y[i]), rep(0L, d$n[i] - d$y[i]))))
  data.frame(y = outcome, provider = d$provider[index], d[index, c("x1", "x2", "x3")], row = index)
}
e <- expand(d)
out <- c(out, facts_header(sprintf("## (b) pprofR on the binomial rows against pprof on the %d expanded binary rows", nrow(e))))
for (stop in c("coefficients", "any")) for (tol in c(1e-5, 1e-10)) {
  fr <- pprofR::logis_fe(prep, tol = tol, stop = c(coefficients = "beta", any = "or")[[stop]])
  fp <- suppressWarnings(pprof::fit_logistic_fe(y ~ x1 + x2 + x3, e, "provider", tol = tol, stop_rule = stop,
                                                min_provider_size = 1, keep_data = TRUE))
  label <- sprintf("serbin, %s, tol %g", stop, tol)
  out <- c(out, sprintf("| %s: iterations (pprofR, pprof expanded) | %d, %d | | %s |", label, fr$control$iter,
                        fp$convergence$iterations, if (fr$control$iter == fp$convergence$iterations) "yes" else "no"),
           facts_row(paste(label, "coefficients"), fr$beta, coef(fp)),
           facts_row(paste(label, "provider effects"), fr$gamma, fp$provider_effects))
}
# Without backtracking: the line search's acceptance test at the last step compares a change of
# the log-likelihood near its rounding error, which the two layouts of the data round differently.
for (tol in c(1e-5, 1e-10)) {
  fr0 <- pprofR::logis_fe(prep, tol = tol, stop = "beta", backtrack = FALSE)
  fp0 <- suppressWarnings(pprof::fit_logistic_fe(y ~ x1 + x2 + x3, e, "provider", tol = tol, stop_rule = "coefficients",
                                                 backtrack = FALSE, min_provider_size = 1))
  label <- sprintf("serbin, coefficients, tol %g, no backtracking", tol)
  out <- c(out, sprintf("| %s: iterations (pprofR, pprof expanded) | %d, %d | | %s |", label, fr0$control$iter,
                        fp0$convergence$iterations, if (fr0$control$iter == fp0$convergence$iterations) "yes" else "no"),
           facts_row(paste(label, "coefficients"), fr0$beta, coef(fp0)),
           facts_row(paste(label, "provider effects"), fr0$gamma, fp0$provider_effects))
}
fr <- pprofR::logis_fe(prep, tol = 1e-10, stop = "beta")
fp <- suppressWarnings(pprof::fit_logistic_fe(y ~ x1 + x2 + x3, e, "provider", tol = 1e-10, stop_rule = "coefficients",
                                              min_provider_size = 1, keep_data = TRUE))
v_r <- vcov(fr)
out <- c(out, facts_row("tol 1e-10: covariance of the coefficients", v_r, vcov(fp)),
         facts_row("tol 1e-10: variance of the provider effects", attr(v_r, "var.gamma"), fp$provider_effect_variance),
         facts_row("tol 1e-10: log-likelihood", -fr$neg2Loglkd / 2, fp$loglik))
test_r <- function(...) {
  t <- pprofR::test_fe(fr, ...)
  list(p = t$p, stat = t$stat, flag = as.integer(as.character(t$flag)), se = t$se.gamma)
}
test_p <- function(...) {
  t <- suppressWarnings(pprof::test_providers(fp, ...))$table
  list(p = t$p_value, stat = t$statistic, flag = t$flag, se = t$std_error)
}
pairs <- list(`exact, two-sided` = list(test_r(test = "exact.poisbinom"), test_p(test = "exact")),
              `exact, greater` = list(test_r(test = "exact.poisbinom", alternative = "greater"),
                                      test_p(test = "exact", alternative = "greater")),
              `score (modified)` = list(test_r(test = "score"), test_p(test = "score")),
              `Wald` = list(test_r(test = "wald"), test_p(test = "wald")))
for (test in names(pairs)) {
  a <- pairs[[test]][[1]]
  b <- pairs[[test]][[2]]
  out <- c(out, facts_row(paste(test, "p-value"), a$p, b$p), facts_row(paste(test, "statistic"), a$stat, b$stat),
           sprintf("| %s flags differing | %d of %d | | |", test, sum(a$flag != b$flag, na.rm = TRUE), length(a$flag)))
  if (!is.null(a$se)) out <- c(out, facts_row(paste(test, "standard error"), a$se, b$se))
}
# The largest relative differences of the exact p-values: providers far in a tail, where the
# upper tail 1 - ppoibin() is at the level of its rounding error (DEC-083).
a <- pairs$`exact, two-sided`[[1]]
b <- pairs$`exact, two-sided`[[2]]
worst <- order(-abs(a$p - b$p) / pmax(b$p, 1e-300))[1:3]
out <- c(out, sprintf("| exact, two-sided, a provider far in a tail: p-values %.3g and %.3g, statistics %.4g and %.4g | | | |",
                      a$p[worst], b$p[worst], a$stat[worst], b$stat[worst]))
for (interval in c("exact", "score", "wald")) {
  ci_r <- suppressWarnings(stats::confint(fr, option = "gamma", test = interval))
  ci_p <- suppressWarnings(pprof::provider_effects(fp, interval = interval))$table
  out <- c(out, facts_row(sprintf("%s interval of the effects, lower and upper", interval),
                          c(ci_r$gamma.lower, ci_r$gamma.upper), c(ci_p$lower, ci_p$upper)))
}
sr <- pprofR::SR_output(fr, stdz = c("indirect", "direct"), measure = c("ratio", "rate"))
sm <- pprof::standardize_providers(fp, standardization = c("indirect", "direct"), measure = c("ratio", "rate"))$table
pick <- function(s, m) sm[sm$standardization == s & sm$measure == m, ]
out <- c(out,
         facts_row("indirect: expected", sr$OE$OE_indirect$Exp.indirect_provider, pick("indirect", "ratio")$expected),
         facts_row("indirect: null variance", sr$OE$OE_indirect$Var.indirect_provider, pick("indirect", "ratio")$variance),
         facts_row("indirect ratio", sr$indirect.ratio, pick("indirect", "ratio")$estimate),
         facts_row("indirect rate x 100 against the rate in percent", 100 * sr$indirect.rate, pick("indirect", "rate")$estimate),
         facts_row("direct: expected", sr$OE$OE_direct$Exp.direct_all, pick("direct", "ratio")$expected),
         facts_row("direct ratio", sr$direct.ratio, pick("direct", "ratio")$estimate),
         facts_row("direct rate x 100 against the rate in percent", 100 * sr$direct.rate, pick("direct", "rate")$estimate))
for (interval in c("exact", "score")) {
  ci_r <- suppressWarnings(stats::confint(fr, option = "SM", test = interval, stdz = c("indirect", "direct"), measure = "ratio"))
  ci_p <- suppressWarnings(pprof::standardize_providers(fp, standardization = c("indirect", "direct"), measure = "ratio",
                                                        interval = interval))$table
  out <- c(out, facts_row(sprintf("%s interval of the indirect and direct ratios", interval),
                          c(ci_r$CI.indirect_ratio$CI_ratio.lower, ci_r$CI.indirect_ratio$CI_ratio.upper,
                            ci_r$CI.direct_ratio$CI_ratio.lower, ci_r$CI.direct_ratio$CI_ratio.upper),
                          c(ci_p$lower[ci_p$standardization == "indirect"], ci_p$upper[ci_p$standardization == "indirect"],
                            ci_p$lower[ci_p$standardization == "direct"], ci_p$upper[ci_p$standardization == "direct"])))
}
for (test in c("wald", "lr", "score")) {
  s_r <- pprofR::summary_fe_covar(fr, test = test)
  s_p <- pprof::test_coefficients(fp, test = test, data = e)$table
  out <- c(out, facts_row(sprintf("covariates, %s: statistic", test), if (identical(test, "wald")) s_r$Z else s_r$stat,
                          s_p$statistic))
}
out <- c(out, "", "The covariate likelihood-ratio and score tests refit the null models: pprofR with the fit's settings, pprof with its defaults (D-10), here stop_rule \"any\" and tol 1e-5 against the fit's \"coefficients\" and 1e-10.", "")

# (c) The exact test on individual trials: poibin over rep(p, n), against the convolution of the
# rows' binomial distributions, for one provider with more and more trials.
convolve_binomials <- function(p, n) {
  pmf <- 1
  for (i in seq_along(p)) pmf <- stats::convolve(pmf, rev(stats::dbinom(0:n[i], n[i], p[i])), type = "open")
  pmax(pmf, 0)
}
mid_p_poibin <- function(o, p, n) {
  q <- rep(p, n)
  1 - poibin::ppoibin(o, q) + 0.5 * poibin::dpoibin(o, q)
}
mid_p_convolution <- function(o, p, n) {
  pmf <- convolve_binomials(p, n)
  sum(pmf[seq_along(pmf) > o + 1L]) + 0.5 * pmf[o + 1L]
}
out <- c(out, "## (c) The exact test of one provider with many trials", "",
         "| Rows | Trials per row | Trials | poibin on the trials (s) | convolution of binomials (s) | mid-p, poibin | mid-p, convolution |",
         "|---|---|---|---|---|---|---|")
set.seed(4)
for (setting in list(c(50, 20), c(50, 100), c(100, 200), c(200, 250))) {
  rows <- setting[1]
  size <- setting[2]
  p <- stats::plogis(stats::rnorm(rows, -2, 0.5))
  n <- rep(size, rows)
  o <- sum(stats::rbinom(rows, n, p))
  t1 <- system.time(a <- mid_p_poibin(o, p, n))[["elapsed"]]
  t2 <- system.time(b <- mid_p_convolution(o, p, n))[["elapsed"]]
  out <- c(out, sprintf("| %d | %d | %d | %.2f | %.3f | %.15g | %.15g |", rows, size, rows * size, t1, t2, a, b))
}
writeLines(out, args[1])
