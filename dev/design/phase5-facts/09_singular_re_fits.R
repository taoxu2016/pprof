# Phase 5, step 4: the reference's RE and CRE tests on fits whose provider variance lme4
# estimates as 0 (found by validation/run-simulation.R, where the working tree's test()
# failed on such fits until infer_decide() stored all-missing flags as integers).
# The data have no provider effects; the seeds are the first whose fits are singular.
# Run from the repository root: Rscript <this file> <output file>
.libPaths(c("dev/reference/lib", .Library))
Sys.setlocale("LC_COLLATE", "C")
suppressPackageStartupMessages(library(pprof))
singular_data <- function(seed, logistic) {
  withr::with_seed(seed, {
    m <- 50
    provider <- rep(seq_len(m), sample(if (logistic) 30:150 else 10:60, m, replace = TRUE))
    n <- length(provider)
    x1 <- stats::rnorm(n) + stats::rnorm(m, 0, 0.5)[provider]
    x2 <- stats::rnorm(n)
    x3 <- stats::rbinom(n, 1, 0.4)
    eta <- 0.5 * x1 - 0.3 * x2 + 0.2 * x3
    y <- if (logistic) stats::rbinom(n, 1, stats::plogis(-1 + eta)) else eta + stats::rnorm(n)
    data.frame(y = y, hospital = provider, x1 = x1, x2 = x2, x3 = x3)
  })
}
out <- sprintf("lme4 %s, Matrix %s", utils::packageVersion("lme4"), utils::packageVersion("Matrix"))
for (fun in c("linear_re", "linear_cre", "logis_re", "logis_cre")) {
  logistic <- startsWith(fun, "logis")
  seed <- if (logistic) 1L else 4L
  d <- singular_data(seed, logistic)
  args <- if (endsWith(fun, "cre")) {
    list(data = d, Y.char = "y", wb.char = "x1", other.char = c("x2", "x3"), ProvID.char = "hospital")
  } else {
    list(data = d, Y.char = "y", Z.char = c("x1", "x2", "x3"), ProvID.char = "hospital")
  }
  fit <- suppressWarnings(suppressMessages(do.call(fun, args)))
  tests <- test(fit)
  out <- c(out, sprintf(
    "%s (seed %d): singular %s; provider variance %g; %d providers; test(): flag %s with levels {%s}, %d missing; %d NaN p-values; %d NaN statistics; standard errors in [%g, %g]",
    fun, seed, lme4::isSingular(attr(fit, "model")), fit$variance$alpha[1], nrow(tests), class(tests$flag),
    paste(levels(tests$flag), collapse = ","), sum(is.na(tests$flag)), sum(is.nan(tests$`p value`)),
    sum(is.nan(tests$stat)), min(tests$Std.Error), max(tests$Std.Error)))
}
writeLines(out, commandArgs(TRUE)[1])
