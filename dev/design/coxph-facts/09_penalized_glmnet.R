# CoxPH brief, §1 and Appendix A: the installed glmnet's lasso path for the Cox model on 06's data set
# for penalized fits (strata through stratifySurv(), (start, stop], offset, weights, Breslow ties set
# explicitly), timed at the default and a tight convergence threshold. 09_penalized_glmnet.py fits
# pprof_py's PenalizedCoxPH at the same lambda values and compares.
# Writes the lambda sequence and the coefficient path of the tight fit to the scratch directory.
# Found on 2026-10-07 with glmnet 5.1: 3.4 s (8.9 s at thresh = 1e-12); the path stopped at 26 of 50 lambdas.
# Run from the repository root, after 06: Rscript dev/design/coxph-facts/09_penalized_glmnet.R <output file>
suppressMessages({library(data.table); library(survival); library(glmnet)})
args <- commandArgs(trailingOnly = TRUE)
scratch <- Sys.getenv("COXPH_FACTS_SCRATCH")
if (!nzchar(scratch)) stop("Set COXPH_FACTS_SCRATCH (see README.md)")
d <- fread(file.path(scratch, "bench_pen.csv"), showProgress = FALSE)
xs <- grep("^x", names(d), value = TRUE)
X <- as.matrix(d[, ..xs])
y <- stratifySurv(Surv(d$start, d$stop, d$event), d$provider)
lines <- sprintf("%s, glmnet %s, survival %s; %d rows, %d providers, %d covariates", R.version.string,
                 packageVersion("glmnet"), packageVersion("survival"), nrow(d), uniqueN(d$provider), length(xs))
warned <- character()
for (thresh in c(1e-7, 1e-12)) {
  times <- numeric()
  for (r in 1:3) {
    times <- c(times, system.time(fit <- withCallingHandlers(
      glmnet(X, y, family = "cox", weights = d$weight, offset = d$offset, alpha = 1, nlambda = 50,
             cox.ties = "breslow", thresh = thresh, maxit = 1e6),
      warning = function(w) {
        warned <<- union(warned, conditionMessage(w))
        invokeRestart("muffleWarning")
      }))[["elapsed"]])
  }
  lines <- c(lines, sprintf("lasso path, thresh = %g: median %.2f s (runs %s); %d of 50 lambdas fitted", thresh,
                            median(times), paste(sprintf("%.2f", times), collapse = ", "), length(fit$lambda)))
}
fwrite(data.table(lambda = fit$lambda), file.path(scratch, "pen_lambda.csv"))
fwrite(as.data.table(t(as.matrix(fit$beta))), file.path(scratch, "pen_beta_r.csv"))
lines <- c(lines, "Warnings from glmnet (muffled):", paste0("  ", warned))
writeLines(lines, args[1])
