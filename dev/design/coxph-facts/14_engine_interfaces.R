# CoxPH design (Phase C0), §E: the facts about survival's and glmnet's interfaces that the adapters
# rely on, on pprof_py's reference data.
#  1. survival's fitters, agreg.fit() and coxph.fit(), called directly with a prepared design, give
#     coxph()'s results: agreg.fit() on right-censored data as (0, time] intervals agrees with coxph()
#     to rounding, and coxph.fit() exactly.
#  2. coxph() refuses robust = TRUE on (start, stop] data without a cluster; cluster = the row number
#     gives the per-row sandwich, crossprod() of the dfbeta residuals, which is pprof_py's robust = True.
#  3. glmnet accepts per-call control, and with fdev = 0 and devmax = 1 fits every lambda of a given
#     grid; coxnet.deviance() evaluates stratified (start, stop] data with weights and offsets.
# Found on 2026-10-07 with survival 3.8-12 and glmnet 5.1: agreg.fit() within 2.2e-16 (Breslow) and
# 2.9e-15 (Efron) of coxph(), with the same iteration counts; coxph.fit() identical; the robust
# variance equal to crossprod(dfbeta); all 100 lambdas fitted.
# Run from the repository root: Rscript dev/design/coxph-facts/14_engine_interfaces.R <output file>
suppressMessages({library(survival); library(glmnet)})
args <- commandArgs(trailingOnly = TRUE)
pprof_py <- normalizePath(Sys.getenv("PPROF_PY", "../../pprof_py"), winslash = "/", mustWork = TRUE)
data_dir <- file.path(pprof_py, "pprof_py", "r_reference", "data")
lines <- sprintf("%s, survival %s, glmnet %s", R.version.string, packageVersion("survival"), packageVersion("glmnet"))
say <- function(...) lines <<- c(lines, sprintf(...))

basic <- read.csv(file.path(data_dir, "basic.csv"))
X <- as.matrix(basic[c("x1", "x2", "x3")])
say("")
say("1. The fitters against coxph() on basic.csv (right-censored), timefix = FALSE:")
for (ties in c("breslow", "efron")) {
  reference <- coxph(Surv(time, event) ~ x1 + x2 + x3, data = basic, ties = ties, control = coxph.control(timefix = FALSE))
  counting <- agreg.fit(X, Surv(rep(0, nrow(basic)), basic$time, basic$event), strata = NULL, offset = NULL, init = NULL,
                        control = coxph.control(), weights = NULL, method = ties, rownames = NULL)
  right <- coxph.fit(X, Surv(basic$time, basic$event), strata = NULL, offset = NULL, init = NULL,
                     control = coxph.control(), weights = NULL, method = ties, rownames = NULL)
  say("   %s: agreg.fit() coefficients %.1e, variance %.1e, log-likelihood %.1e, iterations %d (coxph() %d); coxph.fit() coefficients %.1e",
      ties, max(abs(counting$coefficients - coef(reference))), max(abs(counting$var - reference$var)),
      max(abs(counting$loglik - reference$loglik)), counting$iter, reference$iter,
      max(abs(right$coefficients - coef(reference))))
}
say("   agreg.fit() returns: %s", paste(names(counting), collapse = ", "))
say("   coxph.control() defaults: %s", paste(names(coxph.control()), unlist(coxph.control()), sep = " = ", collapse = ", "))

truncated <- read.csv(file.path(data_dir, "left_truncation.csv"))
refused <- tryCatch({
  coxph(Surv(start, stop, event) ~ x1 + x2, data = truncated, robust = TRUE)
  "accepted"
}, error = function(e) conditionMessage(e))
per_row <- coxph(Surv(start, stop, event) ~ x1 + x2, data = truncated, ties = "breslow", cluster = seq_len(nrow(truncated)))
say("")
say("2. Robust variance on left_truncation.csv:")
say("   robust = TRUE without a cluster: %s", refused)
say("   cluster = row number: largest difference between the robust variance and crossprod(dfbeta): %.1e",
    max(abs(per_row$var - crossprod(residuals(per_row, type = "dfbeta")))))

combined <- read.csv(file.path(data_dir, "combined.csv"))
Xc <- as.matrix(combined[c("x1", "x2", "x3")])
y <- stratifySurv(Surv(combined$start, combined$stop, combined$event), combined$provider)
grid <- exp(seq(log(0.2), log(0.0002), length.out = 100))
path <- glmnet(Xc, y, family = "cox", weights = combined$weight, offset = combined$offset1, lambda = grid,
               cox.ties = "breslow", control = list(thresh = 1e-12, fdev = 0, devmax = 1, maxit = 1e6))
deviance <- coxnet.deviance(pred = drop(Xc %*% as.matrix(path$beta)[, 50]) + combined$offset1, y = y, weights = combined$weight)
say("")
say("3. glmnet on combined.csv (strata, (start, stop], weights, offset, Breslow):")
say("   glmnet.control() parameters: %s", paste(names(glmnet.control()), collapse = ", "))
say("   per-call control = list(thresh = 1e-12, fdev = 0, devmax = 1, maxit = 1e6): %d of %d lambdas fitted",
    length(path$lambda), length(grid))
say("   coxnet.deviance() at the 50th lambda: %.6f; its arguments: %s", deviance, paste(names(formals(coxnet.deviance)), collapse = ", "))
writeLines(lines, args[1])
