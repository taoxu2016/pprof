# CoxPH C6 plan, §2.5: a replicate of a simulation study of the Cox model's provider tests, as
# validation/run-simulation.R runs the other families'. Data with provider strata: 50 providers, a common
# constant baseline hazard (in days), the other families' covariates (x1 with a provider-level shift),
# a quarter of the patients entering late, integer days (so tied times), and known provider hazard
# ratios. The provider-stratified fit, the mid-p and exact tests, and the indirect ratios with mid-p and
# exact limits at their defaults (two-sided, level 0.95). Three scenarios: no provider effects; six
# outlying providers with log hazard ratios of +0.5 (three) and -0.5 (three); no provider effects with
# 5 to 30 patients per provider, where the expected counts are small. The true indirect ratio of a
# provider is its hazard ratio, exp(effect): its expected events under its own hazard over those under
# the baseline hazard, over its patients' time at risk. Times are elapsed seconds.
# Run from the repository root:
#   Rscript dev/design/coxph-facts/39_simulation_replicate.R <output file> [replicates, default 100]
# with an installed pprof from the library PPROF_FACTS_LIB when it is set, and devtools::load_all()
# otherwise.
args <- commandArgs(trailingOnly = TRUE)
out <- args[[1]]
replicates <- if (length(args) >= 2) as.integer(args[[2]]) else 100L
if (nzchar(Sys.getenv("PPROF_FACTS_LIB"))) {
  .libPaths(c(Sys.getenv("PPROF_FACTS_LIB"), .libPaths()))
  suppressPackageStartupMessages(library(pprof))
} else {
  suppressMessages(devtools::load_all(quiet = TRUE))
}

design <- list(providers = 50L, outlier_effects = c(1, 1, 1, -1, -1, -1), effect = 0.5,
               beta = c(x1 = 0.5, x2 = -0.3, x3 = 0.2), rate = 1 / 1000, follow_up = 180:1095,
               late_share = 0.25, late_entry = 1:180)
scenarios <- list(null = list(sizes = 30:150, outliers = FALSE), outliers = list(sizes = 30:150, outliers = TRUE),
                  small = list(sizes = 5:30, outliers = FALSE))

simulate <- function(setting) {
  m <- design$providers
  effects <- numeric(m)
  if (setting$outliers) effects[seq_along(design$outlier_effects)] <- design$outlier_effects * design$effect
  provider <- rep(seq_len(m), sample(setting$sizes, m, replace = TRUE))
  n <- length(provider)
  x1 <- stats::rnorm(n) + stats::rnorm(m, 0, 0.5)[provider]
  x2 <- stats::rnorm(n)
  x3 <- stats::rbinom(n, 1, 0.4)
  eta <- effects[provider] + drop(cbind(x1, x2, x3) %*% design$beta)
  # Days; a quarter of the patients enter late. The hazard is constant, so a late entrant's time
  # from entry has the same distribution: its rows are (entry, exit].
  entry <- ifelse(stats::runif(n) < design$late_share, sample(design$late_entry, n, replace = TRUE), 0L)
  end <- entry + sample(design$follow_up, n, replace = TRUE)
  event <- entry + ceiling(stats::rexp(n, exp(eta) * design$rate))
  list(data = data.frame(hospital = provider, x1 = x1, x2 = x2, x3 = x3, entry = entry, exit = pmin(event, end),
                         status = as.integer(event <= end)),
       effects = effects)
}

replicate_one <- function(setting) {
  sim <- simulate(setting)
  fit <- fit_cox_stratified(Surv(entry, exit, status) ~ x1 + x2 + x3, sim$data, provider = "hospital")
  truth <- exp(sim$effects)
  outlier <- sim$effects != 0
  direction <- sign(sim$effects)
  out <- c(rows = nrow(sim$data), events = sum(sim$data$status))
  for (test in c("midp", "exact")) {
    flag <- test_providers(fit, test = test)$table$flag
    m <- standardize_providers(fit, interval = test)$table
    covers <- m$lower <= truth & truth <= m$upper
    out[paste0(test, c("_null_flagged", "_outlier_right", "_null_covered", "_outlier_covered"))] <-
      c(sum(flag[!outlier] != 0), sum(flag[outlier] == direction[outlier]), sum(covers[!outlier]), sum(covers[outlier]))
  }
  out[c("e_min", "e_median", "e_max")] <- stats::quantile(m$expected, c(0, 0.5, 1))
  out[["null_n"]] <- sum(!outlier)
  out[["outlier_n"]] <- sum(outlier)
  out
}

lines <- character()
set.seed(20261005)
for (name in names(scenarios)) {
  t <- system.time(res <- t(vapply(seq_len(replicates), function(r) replicate_one(scenarios[[name]]), numeric(15))))
  rate <- function(col, n) 100 * sum(res[, col]) / sum(res[, n])
  lines <- c(lines, sprintf("%s: %d replicates in %.1f s (%.3f s each); rows %.0f, events %.0f (means); expected events per provider: median of minima %.1f, of medians %.1f, of maxima %.1f",
                            name, replicates, t[["elapsed"]], t[["elapsed"]] / replicates, mean(res[, "rows"]), mean(res[, "events"]),
                            stats::median(res[, "e_min"]), stats::median(res[, "e_median"]), stats::median(res[, "e_max"])))
  for (test in c("midp", "exact")) {
    lines <- c(lines, sprintf("  %-5s size %.2f%%, coverage (none) %.2f%%%s", test,
                              rate(paste0(test, "_null_flagged"), "null_n"), rate(paste0(test, "_null_covered"), "null_n"),
                              if (sum(res[, "outlier_n"]) > 0) sprintf(", power %.1f%%, coverage (outliers) %.1f%%",
                                                                      rate(paste0(test, "_outlier_right"), "outlier_n"),
                                                                      rate(paste0(test, "_outlier_covered"), "outlier_n")) else ""))
  }
}
writeLines(lines, out)
