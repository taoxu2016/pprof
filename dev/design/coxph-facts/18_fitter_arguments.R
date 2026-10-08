# CoxPH Phase C2 plan: whether coxph()'s preprocessing and the row order change agreg.fit()'s results
# and times, on the C1 benchmark's rows-1e6 data (dev/bench/cox/scenarios.R, seed 103): the call
# C1's baseline timed (dev/bench/cox/run_engines.R: the raw offset, strata as given, no nocenter, rows
# in the generator's order) against the call coxph() makes (the offset minus its mean,
# nocenter = c(-1, 0, 1), integer strata codes), each on the rows as generated and sorted by provider
# as data_prepare() sorts them. Four fits in one process: the times are single runs, not a benchmark.
# Run from the repository root: Rscript dev/design/coxph-facts/18_fitter_arguments.R <output file>
suppressMessages(library(survival))
args <- commandArgs(trailingOnly = TRUE)
source(file.path("dev", "bench", "cox", "scenarios.R"))
generated <- cox_bench_data(1e6, 1000, 20, 103)
lines <- sprintf("%s, survival %s, %d rows", R.version.string, packageVersion("survival"), nrow(generated))
say <- function(...) lines <<- c(lines, sprintf(...))
covariates <- grep("^x", names(generated), value = TRUE)
control <- coxph.control(timefix = FALSE)
run <- function(d, label, as_coxph) {
  x <- as.matrix(d[, covariates])
  y <- Surv(d$start, d$stop, d$event)
  offset <- if (as_coxph) d$offset - mean(d$offset) else d$offset
  strata <- if (as_coxph) as.integer(factor(d$provider)) else d$provider
  nocenter <- if (as_coxph) c(-1, 0, 1) else NULL
  invisible(gc())
  t <- system.time(fit <- agreg.fit(x, y, strata, offset, NULL, control, weights = d$weight, method = "breslow",
                                    rownames = NULL, nocenter = nocenter))[["elapsed"]]
  say("%-45s %6.2f s, %d iterations, log-likelihood %.10f", label, t, fit$iter, fit$loglik[2])
  fit
}
a <- run(generated, "generated order, the baseline's call", FALSE)
b <- run(generated, "generated order, coxph()'s call", TRUE)
sorted <- generated[order(generated$provider, method = "radix"), ]
c1 <- run(sorted, "provider order, the baseline's call", FALSE)
c2 <- run(sorted, "provider order, coxph()'s call", TRUE)
say("coefficients, generated against provider order: %s with the baseline's call, %s with coxph()'s",
    if (identical(a$coefficients, c1$coefficients)) "identical" else "differ",
    if (identical(b$coefficients, c2$coefficients)) "identical" else "differ")
say("largest coefficient difference between the two calls: %.1e", max(abs(a$coefficients - b$coefficients)))
writeLines(lines, args[1])
