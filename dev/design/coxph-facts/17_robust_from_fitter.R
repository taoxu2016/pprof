# CoxPH Phase C2 plan (DEC-098): a cheaper robust variance than coxph() with one cluster per row.
# survival's fitters, called with the arguments coxph() passes them, give coxph()'s fit bitwise, and
# survival's own residuals.coxph(type = "dfbeta", collapse = cluster, weighted = TRUE) on the fitter's
# result, made into the object coxph() builds internally before its robust step, gives coxph()'s
# robust variance bitwise, without the rest of coxph() (its model frame, its concordance, and the
# score test at beta = 0 that its robust step adds). Counting-process data (agreg.fit()) and the same
# data as right-censored (coxph.fit()), per-row clusters and 40 clusters, on the benchmark
# generator's data (dev/bench/cox/scenarios.R) with 100,000 and 1,000,000 rows, sorted by provider as
# data_prepare() sorts them.
# Run from the repository root: Rscript dev/design/coxph-facts/17_robust_from_fitter.R <output file>
suppressMessages(library(survival))
args <- commandArgs(trailingOnly = TRUE)
source(file.path("dev", "bench", "cox", "scenarios.R"))
lines <- sprintf("%s, survival %s", R.version.string, packageVersion("survival"))
say <- function(...) lines <<- c(lines, sprintf(...))
elapsed <- function(expr) system.time(expr)[["elapsed"]]
control <- coxph.control(timefix = FALSE)

# What coxph() does before it calls a fitter (survival 3.8-12, coxph()): the offset minus its mean
# unless it is all 0, nocenter = c(-1, 0, 1), and the strata as integer codes.
fitter_call <- function(x, y, strata, offset, weights, counting) {
  offset <- if (all(offset == 0)) rep(0, length(offset)) else offset - mean(offset)
  fitter <- if (counting) agreg.fit else coxph.fit
  fitter(x, y, strata, offset, NULL, control, weights = weights, method = "breslow", rownames = NULL,
         nocenter = c(-1, 0, 1))
}
# coxph()'s robust step on the fitter's result: the object it builds (fit2), then the dfbeta
# residuals collapsed by cluster, then crossprod().
robust_from_fitter <- function(fit, x, y, strata, weights, cluster, terms) {
  fit2 <- c(fit, list(x = x, y = y, weights = weights))
  fit2$strata <- strata
  fit2$terms <- terms
  class(fit2) <- fit2$class
  fit2$class <- NULL
  crossprod(residuals(fit2, type = "dfbeta", collapse = cluster, weighted = TRUE))
}

for (n in c(1e5, 1e6)) {
  d <- cox_bench_data(n, 1000, 20, 101)
  d <- d[order(d$provider, method = "radix"), ]
  rownames(d) <- NULL
  d$.row <- seq_len(nrow(d))
  d$.cluster <- d$provider %% 40
  covariates <- grep("^x", names(d), value = TRUE)
  x <- as.matrix(d[, covariates])
  strata <- as.integer(factor(d$provider))
  say("")
  say("%d rows, 1,000 providers, 20 covariates, Breslow ties:", nrow(d))
  for (counting in c(TRUE, FALSE)) {
    y <- if (counting) Surv(d$start, d$stop, d$event) else Surv(d$stop, d$event)
    lhs <- if (counting) "Surv(start, stop, event)" else "Surv(stop, event)"
    f <- as.formula(paste(lhs, "~", paste(covariates, collapse = " + "), "+ strata(provider) + offset(offset)"))
    t_fit <- elapsed(fit <- fitter_call(x, y, strata, d$offset, d$weight, counting))
    # robust = FALSE explicitly: coxph() switches the robust variance on for non-integer weights.
    t_coxph <- elapsed(reference <- coxph(f, data = d, weights = weight, ties = "breslow", robust = FALSE,
                                          control = control))
    say("  %s: %s %.2f s; coxph() %.2f s", if (counting) "(start, stop]" else "right-censored",
        if (counting) "agreg.fit()" else "coxph.fit()", t_fit, t_coxph)
    say("    fitter against coxph(): coefficients %s, variance %s, log-likelihood %s, iterations %d and %d, martingale residuals %s",
        if (identical(unname(fit$coefficients), unname(coef(reference)))) "identical" else "differ",
        if (identical(unname(fit$var), unname(reference$var))) "identical" else "differ",
        if (identical(fit$loglik, reference$loglik)) "identical" else "differ", fit$iter, reference$iter,
        if (identical(unname(fit$residuals), unname(reference$residuals))) "identical" else "differ")
    for (clusters in c("row", "40 clusters")) {
      column <- if (clusters == "row") d$.row else d$.cluster
      # coxph()'s cluster codes for a column that is not a factor.
      codes <- match(column, unique(column))
      t_cheap <- elapsed(cheap <- robust_from_fitter(fit, x, y, strata, d$weight, codes, terms(f)))
      d$.cl <- column
      t_robust <- elapsed(robust <- coxph(f, data = d, weights = weight, cluster = .cl, ties = "breslow",
                                          control = control))
      say("    robust, %s: from the fitter's result %.2f s; coxph(cluster) %.2f s; variances %s (largest difference %.1e); naive variance %s",
          clusters, t_cheap, t_robust, if (identical(unname(cheap), unname(robust$var))) "identical" else "differ",
          max(abs(cheap - robust$var)),
          if (identical(unname(robust$naive.var), unname(fit$var))) "identical to the fitter's" else "differs")
    }
  }
  rm(d, x)
  invisible(gc())
}
writeLines(lines, args[1])
