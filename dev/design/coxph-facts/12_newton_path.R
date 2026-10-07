# CoxPH brief, §3.3 row 7, B6 and Appendix A: the R side of the Newton-path comparison
# (12_newton_path.py compares and writes the output). coxph()'s iterates 1 to 6 from beta = 0 on two
# of pprof_py's reference data sets: combined (strata, offset, weights, (start, stop], Breslow) and
# basic with Efron ties, fitted as pprof_py's r_reference/run_all.R fits them.
# Writes newton_path_r.csv to the scratch directory.
# Run from the repository root: Rscript dev/design/coxph-facts/12_newton_path.R
suppressMessages(library(survival))
pprof_py <- normalizePath(Sys.getenv("PPROF_PY", "../../pprof_py"), winslash = "/", mustWork = TRUE)
scratch <- Sys.getenv("COXPH_FACTS_SCRATCH")
if (!nzchar(scratch)) stop("Set COXPH_FACTS_SCRATCH (see README.md)")
data_dir <- file.path(pprof_py, "pprof_py", "r_reference", "data")
rows <- list()
combined <- read.csv(file.path(data_dir, "combined.csv"))
basic <- read.csv(file.path(data_dir, "basic.csv"))
for (k in 1:6) {
  fit <- suppressWarnings(coxph(Surv(start, stop, event) ~ x1 + x2 + x3 + strata(provider) + offset(offset1),
                                data = combined, weights = weight, ties = "breslow",
                                control = coxph.control(iter.max = k)))
  rows[[length(rows) + 1]] <- data.frame(case = "combined", iter_max = k, iter = fit$iter, term = names(coef(fit)),
                                         coef = unname(coef(fit)), loglik = fit$loglik[2])
  fit <- suppressWarnings(coxph(Surv(time, event) ~ x1 + x2 + x3, data = basic, ties = "efron",
                                control = coxph.control(iter.max = k)))
  rows[[length(rows) + 1]] <- data.frame(case = "basic_efron", iter_max = k, iter = fit$iter, term = names(coef(fit)),
                                         coef = unname(coef(fit)), loglik = fit$loglik[2])
}
write.csv(do.call(rbind, rows), file.path(scratch, "newton_path_r.csv"), row.names = FALSE)
