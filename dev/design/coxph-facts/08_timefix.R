# CoxPH brief, §3.3 row 2, Q1 and Appendix A: the R side of the timefix comparison on 06's data set A
# (08_timefix.py makes the comparison and writes the output). coxph() fits with timefix = TRUE (the
# default, which merges near-equal times through aeqSurv()) and FALSE: at default and tight control,
# and its first four Newton iterates from beta = 0. Also counts what aeqSurv() changes in these data.
# Writes timefix_r.csv and timefix_meta.txt to the scratch directory. coxph.control() warns that the
# tight eps (1e-14) is below its Cholesky tolerance; the default and tight fits still agree to 1e-12.
# Run from the repository root, after 06: Rscript dev/design/coxph-facts/08_timefix.R
suppressMessages({library(data.table); library(survival)})
scratch <- Sys.getenv("COXPH_FACTS_SCRATCH")
if (!nzchar(scratch)) stop("Set COXPH_FACTS_SCRATCH (see README.md)")
d <- fread(file.path(scratch, "bench_a.csv"), showProgress = FALSE)
xs <- grep("^x", names(d), value = TRUE)
f <- as.formula(paste("Surv(start, stop, event) ~", paste(xs, collapse = " + "), "+ offset(offset) + strata(provider)"))
rows <- list()
add <- function(fit, ties, timefix, control) {
  rows[[length(rows) + 1]] <<- data.frame(ties = ties, timefix = timefix, control = control, iter = fit$iter,
                                          term = names(coef(fit)), coef = unname(coef(fit)), loglik = fit$loglik[2])
}
for (ties in c("breslow", "efron")) {
  for (timefix in c(TRUE, FALSE)) {
    add(coxph(f, data = d, weights = weight, ties = ties, robust = FALSE,
              control = coxph.control(timefix = timefix)), ties, timefix, "default")
    add(coxph(f, data = d, weights = weight, ties = ties, robust = FALSE,
              control = coxph.control(timefix = timefix, eps = 1e-14, iter.max = 100)), ties, timefix, "tight")
    for (k in 1:4) {
      add(suppressWarnings(coxph(f, data = d, weights = weight, ties = ties, robust = FALSE,
                                 control = coxph.control(timefix = timefix, eps = 1e-300, iter.max = k))),
          ties, timefix, paste0("iterate", k))
    }
  }
}
fwrite(do.call(rbind, rows), file.path(scratch, "timefix_r.csv"))
y <- Surv(d$start, d$stop, d$event)
y_fixed <- aeqSurv(y)
writeLines(c(sprintf("%s, survival %s", R.version.string, packageVersion("survival")),
             sprintf("bench_a.csv: %d distinct start and stop values, %d after aeqSurv(); aeqSurv() changes the start or stop of %d of %d rows",
                     length(unique(c(d$start, d$stop))), length(unique(c(y_fixed[, 1], y_fixed[, 2]))),
                     sum(y[, 1] != y_fixed[, 1] | y[, 2] != y_fixed[, 2]), nrow(d))),
           file.path(scratch, "timefix_meta.txt"))
