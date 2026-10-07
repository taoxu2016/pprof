# CoxPH brief, Appendix A and B1: the R side of two checks of pprof_py v0.7.0 (05_robust_finegray.py
# makes the comparison and writes the output):
#  1. the robust variance with Breslow and with Efron ties on (start, stop] data with tied deaths
#     (pprof_py's robust_strata_truncation data, clustered);
#  2. Fine-Gray with delayed entry: survival::finegray()'s expanded data and weights, and the
#     weighted, clustered Cox fits with both tie methods (pprof_py's competing_risks_truncated data).
# Writes r_checks.csv, r_finegray_truncated.csv and r_checks_meta.txt to the scratch directory.
# Run from the repository root: Rscript dev/design/coxph-facts/05_robust_finegray.R
suppressMessages(library(survival))
pprof_py <- normalizePath(Sys.getenv("PPROF_PY", "../../pprof_py"), winslash = "/", mustWork = TRUE)
scratch <- Sys.getenv("COXPH_FACTS_SCRATCH")
if (!nzchar(scratch)) stop("Set COXPH_FACTS_SCRATCH (see README.md)")
data_dir <- file.path(pprof_py, "pprof_py", "r_reference", "data")
rows <- list()

d <- read.csv(file.path(data_dir, "robust_strata_truncation.csv"))
for (ties in c("breslow", "efron")) {
  fit <- coxph(Surv(start, stop, event) ~ x1 + x2 + strata(strata), data = d, cluster = cluster, ties = ties)
  rows[[length(rows) + 1]] <- data.frame(case = paste0("robust_strata_truncation/", ties),
    term = names(coef(fit)), coef = unname(coef(fit)),
    se_robust = sqrt(diag(fit$var)), se_naive = sqrt(diag(fit$naive.var)))
}
events <- d[d$event == 1, ]
key <- paste(events$strata, events$stop)
tied <- sum(duplicated(key) | duplicated(key, fromLast = TRUE))

d2 <- read.csv(file.path(data_dir, "competing_risks_truncated.csv"))
d2$event_f <- factor(d2$event, 0:2, c("censor", "cause1", "cause2"))
fg <- finegray(Surv(start, stop, event_f) ~ ., id = id, data = d2)
write.csv(fg[, c("id", "fgstart", "fgstop", "fgstatus", "fgwt")], file.path(scratch, "r_finegray_truncated.csv"),
          row.names = FALSE)
for (ties in c("breslow", "efron")) {
  fit <- coxph(Surv(fgstart, fgstop, fgstatus) ~ x1 + x2, data = fg, weights = fgwt, cluster = id, ties = ties)
  rows[[length(rows) + 1]] <- data.frame(case = paste0("finegray_truncated/", ties),
    term = names(coef(fit)), coef = unname(coef(fit)),
    se_robust = sqrt(diag(fit$var)), se_naive = sqrt(diag(fit$naive.var)))
}
write.csv(do.call(rbind, rows), file.path(scratch, "r_checks.csv"), row.names = FALSE)
writeLines(c(sprintf("%s, survival %s", R.version.string, packageVersion("survival")),
             sprintf("robust_strata_truncation: %d rows, %d events, %d of them tied with another event in their stratum",
                     nrow(d), sum(d$event), tied),
             sprintf("competing_risks_truncated: %d rows, expanded by finegray() to %d", nrow(d2), nrow(fg))),
           file.path(scratch, "r_checks_meta.txt"))
