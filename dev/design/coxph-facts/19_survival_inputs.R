# CoxPH Phase C2 plan, the data layer (COXPH_DESIGN §C.1): how R's formula tools and survival::Surv()
# treat the inputs data_prepare() must check. Which variables all.vars() finds in a Surv() response
# (with survival::); whether model.frame() finds Surv() when the formula's environment does not; the
# status codings Surv() accepts and those it turns into NA with a warning; start >= stop; times of 0
# and below; the sum of several offset() terms; and strata()'s integer codes.
# Run from the repository root: Rscript --vanilla dev/design/coxph-facts/19_survival_inputs.R <output file>
args <- commandArgs(trailingOnly = TRUE)
lines <- sprintf("%s, survival %s (not attached)", R.version.string, utils::packageVersion("survival"))
say <- function(label, expr) {
  value <- tryCatch(withCallingHandlers(expr, warning = function(w) {
    lines <<- c(lines, sprintf("%s: warning: %s", label, conditionMessage(w)))
    invokeRestart("muffleWarning")
  }), error = function(e) paste("error:", conditionMessage(e)))
  lines <<- c(lines, sprintf("%s: %s", label, paste(format(value), collapse = " | ")))
}
say("all.vars(survival::Surv(time, status))", all.vars(quote(survival::Surv(time, status))))
say("all.vars(Surv(time, status == 1))", all.vars(quote(Surv(time, status == 1))))
d <- data.frame(time = c(5, 3, 0, 7), status = c(1, 2, 1, 2), x = c(1, 2, 3, 4), e = c(0.1, 0.2, 0.3, 0.4))
# A formula made where survival is not attached, as in a session that has not called library(survival).
f_env <- new.env(parent = globalenv())
f <- stats::as.formula("Surv(time, status) ~ x + offset(log(e))", env = f_env)
say("model.frame() of Surv(time, status) ~ ...", class(stats::model.frame(f, d)[[1]]))
f2 <- stats::as.formula("survival::Surv(time, status) ~ x + offset(log(e))", env = f_env)
mf <- stats::model.frame(f2, d)
say("model.frame() of survival::Surv(time, status) ~ ...: class", class(mf[[1]]))
say("  type", attr(mf[[1]], "type"))
say("  status coded 1/2 becomes", unclass(mf[[1]])[, "status"])
say("  times, one of them 0", unclass(mf[[1]])[, "time"])
say("  model.offset()", stats::model.offset(mf))
f3 <- stats::as.formula("survival::Surv(time, status) ~ x + offset(log(e)) + offset(x)", env = f_env)
say("  two offset() terms, model.offset()", stats::model.offset(stats::model.frame(f3, d)))
t3 <- stats::terms(f3)
say("  attr(terms, \"offset\")", attr(t3, "offset"))
say("  term.labels", attr(t3, "term.labels"))
say("Surv(): logical status", unclass(survival::Surv(c(1, 2), c(TRUE, FALSE)))[, "status"])
say("Surv(): numeric status 0/1/2", unclass(survival::Surv(c(1, 2, 3), c(0, 1, 2)))[, "status"])
say("Surv(): numeric status 0/1/2, type", attr(survival::Surv(c(1, 2, 3), c(0, 1, 2)), "type"))
say("Surv(): factor status, type", attr(survival::Surv(c(1, 2, 3), factor(c(0, 1, 2))), "type"))
say("Surv(): start >= stop (start, stop, status by column)", unclass(survival::Surv(c(1, 3), c(2, 3), c(1, 0))))
say("Surv(): a negative right-censored time (time, status by column)", unclass(survival::Surv(c(-1, 2), c(1, 0))))
say("Surv(): a missing status (time, status by column)", unclass(survival::Surv(c(1, 2), c(NA, 1))))
say("Surv(): status 2/3 (time, status by column)", unclass(survival::Surv(c(1, 2), c(2, 3))))
say("as.integer(strata(c(3, 1, 3, 7)))", as.integer(survival::strata(c(3, 1, 3, 7))))
writeLines(lines, args[1])
