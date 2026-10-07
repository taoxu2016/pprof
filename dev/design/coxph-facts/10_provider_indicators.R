# CoxPH brief, §2.2 and Appendix A: the cost of an unstratified Cox model with explicit provider
# effects (K - 1 provider indicators) in survival::coxph(), against the provider-stratified model on
# the same data; 20 rows per provider and 10 covariates.
# Found on 2026-10-07: 1.4 s, 13 s and 144 s at 250, 500 and 1,000 providers (roughly K^3), against
# 0.03 s to 0.17 s stratified.
# Run from the repository root: Rscript dev/design/coxph-facts/10_provider_indicators.R <output file>
suppressMessages(library(survival))
args <- commandArgs(trailingOnly = TRUE)
lines <- sprintf("%s, survival %s", R.version.string, packageVersion("survival"))
for (K in c(250L, 500L, 1000L)) {
  set.seed(K)
  n <- 20L * K
  p <- 10L
  prov <- sample.int(K, n, replace = TRUE)
  X <- matrix(rnorm(n * p), n, p)
  eta <- drop(X %*% rep(c(0.3, -0.2), 5)) + rnorm(K, 0, 0.3)[prov]
  t <- rexp(n, exp(eta))
  cz <- rexp(n, 0.5)
  d <- data.frame(time = round(pmin(t, cz) * 365) / 365 + 1 / 365, event = as.integer(t <= cz), prov = factor(prov), X)
  gc(reset = TRUE)
  t_indicators <- system.time(fit <- coxph(Surv(time, event) ~ . - prov + prov, data = d, ties = "breslow"))[["elapsed"]]
  heap <- sum(gc()[, 6])
  t_strata <- system.time(coxph(Surv(time, event) ~ . - prov + strata(prov), data = d, ties = "breslow"))[["elapsed"]]
  lines <- c(lines, sprintf("K = %4d providers, n = %6d, p = %d: with K - 1 provider indicators %.1f s (%d iterations, R heap peak %.0f MB); stratified by provider %.2f s",
                            K, n, p, t_indicators, fit$iter, heap, t_strata))
  writeLines(lines, args[1])
}
