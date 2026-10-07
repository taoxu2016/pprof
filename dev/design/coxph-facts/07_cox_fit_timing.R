# CoxPH brief, §3.7 and Appendix A: survival on the provider-stratified Cox model of 06's data sets A
# and B ((start, stop], offset, case weights, model-based variance, Breslow and Efron ties), and the
# indirect expected counts of the two-stage SMR/SHR computed in closed form. 07_cox_fit_timing.py
# runs pprof_py on the same data and compares.
# Writes the coefficients and expected counts to the scratch directory for the Python side.
# Found on 2026-10-07 (8 logical cores): at 1,000,000 rows and 7,500 providers, agreg.fit() 6.3 s,
# coxph() 18 s (Breslow) and 15 s (Efron), with clustered robust variance 18 s; the expected counts
# 0.34 s in plain R, against 7.3 s through a second coxph() fit. An earlier run on the same machine,
# with other work running, took 20% to 40% longer throughout.
# Run from the repository root, after 06: Rscript dev/design/coxph-facts/07_cox_fit_timing.R <output file>
suppressMessages({library(data.table); library(survival)})
args <- commandArgs(trailingOnly = TRUE)
scratch <- Sys.getenv("COXPH_FACTS_SCRATCH")
if (!nzchar(scratch)) stop("Set COXPH_FACTS_SCRATCH (see README.md)")
lines <- sprintf("%s, survival %s, data.table %s", R.version.string, packageVersion("survival"),
                 packageVersion("data.table"))
for (case in c("a", "b")) {
  d <- fread(file.path(scratch, sprintf("bench_%s.csv", case)), showProgress = FALSE)
  label <- sprintf("%s (%d rows, %d providers, %d covariates)", toupper(case), nrow(d), uniqueN(d$provider),
                   length(grep("^x", names(d))))
  xs <- grep("^x", names(d), value = TRUE)
  f <- as.formula(paste("Surv(start, stop, event) ~", paste(xs, collapse = " + "), "+ offset(offset) + strata(provider)"))
  for (ties in c("breslow", "efron")) {
    times <- numeric()
    for (r in 1:3) {
      gc(reset = TRUE)
      times <- c(times, system.time(fit <- coxph(f, data = d, weights = weight, ties = ties, robust = FALSE))[["elapsed"]])
    }
    heap <- sum(gc()[, 6])
    lines <- c(lines, sprintf("%s coxph() %-7s median %.2f s (runs %s), %d iterations, R heap peak %.0f MB",
                              label, ties, median(times), paste(sprintf("%.2f", times), collapse = ", "), fit$iter, heap))
    write.csv(data.frame(term = names(coef(fit)), coef = unname(coef(fit)), se = sqrt(diag(fit$var))),
              file.path(scratch, sprintf("bench_%s_r_coef_%s.csv", case, ties)), row.names = FALSE)
    if (ties == "breslow") fit_breslow <- fit
  }
  Y <- Surv(d$start, d$stop, d$event)
  X <- as.matrix(d[, ..xs])
  times <- numeric()
  for (r in 1:3) {
    times <- c(times, system.time(agreg.fit(X, Y, strata = d$provider, offset = d$offset, init = NULL,
                                            control = coxph.control(), weights = d$weight, method = "breslow",
                                            rownames = NULL))[["elapsed"]])
  }
  lines <- c(lines, sprintf("%s agreg.fit() breslow, the engine without the formula interface: median %.2f s",
                            label, median(times)))
  t_robust <- system.time(coxph(f, data = d, weights = weight, ties = "breslow", cluster = provider))[["elapsed"]]
  lines <- c(lines, sprintf("%s coxph() breslow with clustered robust variance: %.2f s", label, t_robust))
  # Two-stage indirect expected counts: the national Breslow baseline with eta = X beta + offset as
  # offset, rows unweighted (pprof_py's definition); the risk set at event time t is start < t <= stop.
  t_expected <- system.time({
    eta <- drop(X %*% coef(fit_breslow)) + d$offset
    risk <- exp(eta - max(eta))
    event_times <- sort(unique(d$stop[d$event == 1]))
    K <- length(event_times)
    deaths <- tabulate(match(d$stop[d$event == 1], event_times), K)
    at_stop <- findInterval(d$stop, event_times)
    at_start <- findInterval(d$start, event_times)
    bin <- function(index) {
      A <- numeric(K + 1)
      s <- rowsum(risk, index)
      A[as.integer(rownames(s)) + 1] <- s
      A
    }
    suffix <- function(A) rev(cumsum(rev(A)))
    risk_set <- suffix(bin(at_stop))[2:(K + 1)] - suffix(bin(at_start))[2:(K + 1)]
    cumulative <- c(0, cumsum(deaths / risk_set))
    expected <- rowsum(risk * (cumulative[at_stop + 1] - cumulative[at_start + 1]), d$provider)
  })[["elapsed"]]
  observed <- rowsum(d$event, d$provider)
  lines <- c(lines, sprintf("%s indirect expected counts in plain R: %.2f s; sum of E = %.6f, observed events = %d",
                            label, t_expected, sum(expected), sum(observed)))
  write.csv(data.frame(provider = as.integer(rownames(expected)), observed = observed[, 1], expected = expected[, 1]),
            file.path(scratch, sprintf("bench_%s_r_expected.csv", case)), row.names = FALSE)
  t_stage2 <- system.time({
    stage2 <- coxph(Surv(start, stop, event) ~ offset(eta), data = d, ties = "breslow")
    baseline <- basehaz(stage2, centered = FALSE)
  })[["elapsed"]]
  lines <- c(lines, sprintf("%s the same baseline through a second coxph() fit and basehaz(): %.2f s", label, t_stage2))
  rm(d, X, Y, fit, fit_breslow, stage2)
  invisible(gc())
}
writeLines(lines, args[1])
