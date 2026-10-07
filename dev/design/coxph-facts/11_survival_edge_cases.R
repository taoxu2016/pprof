# CoxPH brief, §3.3 rows 3, 5, 6 and 12, §5.1 and Appendix A: what survival::coxph() does with inputs
# where pprof_py v0.7.0 behaves differently: an aliased covariate (pprof_py: pseudo-inverse), zero case
# weights (pprof_py: accepted), no events (pprof_py: beta = 0), non-integer weights (pprof_py:
# model-based variance), a right-censored time of 0 (pprof_py: rejected), and a missing covariate
# value (pprof_py: error).
# Run from the repository root: Rscript dev/design/coxph-facts/11_survival_edge_cases.R <output file>
suppressMessages(library(survival))
args <- commandArgs(trailingOnly = TRUE)
set.seed(1)
n <- 200
d <- data.frame(time = rexp(n), event = rbinom(n, 1, 0.6), x1 = rnorm(n), x2 = rnorm(n), w = runif(n, 0.5, 1.5))
d$x3 <- d$x1 + d$x2
lines <- sprintf("%s, survival %s", R.version.string, packageVersion("survival"))
probe <- function(label, expr) {
  messages <- character()
  value <- withCallingHandlers(
    tryCatch(expr, error = function(e) paste("error:", conditionMessage(e))),
    warning = function(w) {
      messages <<- c(messages, conditionMessage(w))
      invokeRestart("muffleWarning")
    })
  text <- if (inherits(value, "coxph")) {
    paste("coefficients", paste(names(coef(value)), signif(coef(value), 4), collapse = ", "))
  } else {
    as.character(value)
  }
  lines <<- c(lines, sprintf("%s: %s%s", label, text,
                             if (length(messages)) paste0(" (warnings: ", paste(unique(messages), collapse = "; "), ")") else ""))
}
probe("Aliased covariate (x3 = x1 + x2)", coxph(Surv(time, event) ~ x1 + x2 + x3, data = d, ties = "breslow"))
zero <- d
zero$w[1:5] <- 0
probe("Five zero case weights", coxph(Surv(time, event) ~ x1 + x2, data = zero, weights = w, ties = "breslow"))
none <- d
none$event <- 0
probe("No events", coxph(Surv(time, event) ~ x1 + x2, data = none, ties = "breslow"))
probe("Non-integer case weights", {
  fit <- coxph(Surv(time, event) ~ x1, data = d, weights = w)
  sprintf("the reported variance is %s (var equals naive.var: %s)",
          if (isTRUE(all.equal(fit$var, fit$naive.var))) "model-based" else "robust",
          isTRUE(all.equal(fit$var, fit$naive.var)))
})
probe("A right-censored time of 0", {
  fit <- coxph(Surv(c(0, 1, 2, 3, 4, 5), c(1, 0, 1, 1, 0, 1)) ~ c(1, 2, 1, 2, 3, 1))
  sprintf("accepted (%d observations)", fit$n)
})
missing_x <- d[1:60, ]
missing_x$x1[3] <- NA
probe("A missing covariate value", {
  fit <- coxph(Surv(time, event) ~ x1 + x2, data = missing_x)
  sprintf("fitted on %d of 60 rows (na.action: %s)", fit$n, class(fit$na.action))
})
writeLines(lines, args[1])
