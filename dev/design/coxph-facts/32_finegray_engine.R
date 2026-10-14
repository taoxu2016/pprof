# CoxPH C5 plan, §2.5 and §2.6: the Fine-Gray fit from survival's calls, on the two competing-risk
# fixtures (competing-simple, competing-truncated), each cause, both tie methods, default and tight:
#  A. finegray() on the rows sorted by provider (data_prepare()'s order), with the provider strata and
#     timefix = FALSE, then survival's fitter agreg.fit() called as coxph() calls it (DEC-100) and
#     coxph()'s robust step on its result clustered by subject (DEC-099), against coxph(cluster = id)
#     on finegray()'s output, as COXPH_DESIGN §E.3 wrote it and the generator's R side ran it: bitwise?
#     And both against the fixtures' survival records and pprof_py's, in units of the tiers;
#  B. survfit() of a coxph() object fit to the expansion as the package builds one (generated column
#     names, no cluster, robust = FALSE; R/model-survival.R's survival_engine_fit()), against the
#     generator's curves (survfit() of its coxph(cluster = id)) and pprof_py's cumulative incidence;
#  C. pprof_py's log-likelihoods against survival's, which the calibration report does not yet hold.
# Run from the repository root: Rscript dev/design/coxph-facts/32_finegray_engine.R <output file>
suppressMessages(library(survival))
out <- character()
say <- function(...) out <<- c(out, paste0(...))
packed <- function(m) unname(unlist(lapply(seq_len(nrow(m)), function(i) m[i, i:ncol(m)])))
# The largest |a - b| / (atol + rtol |b|): the package's elementwise rule, in units of a tier.
units <- function(a, b, tier) {
  a <- unlist(a); b <- unlist(b)
  max(abs(a - b) / (tier[1] + tier[2] * abs(b)))
}
cox_coefficient <- c(1e-10, 1e-8); cox_variance <- c(1e-12, 1e-7); cox_baseline <- c(1e-12, 1e-8)
cox_function <- c(1e-12, 1e-12)
say(sprintf("%s, survival %s", R.version.string, packageVersion("survival")))
say("")
say("A. The fit: fitter and robust step against coxph(cluster = id); in units of the tiers against the fixtures")
fixtures <- c("tests/testthat/fixtures/cox/competing-simple.rds", "validation/fixtures/cox/competing-truncated.rds")
for (path in fixtures) {
  fx <- readRDS(path)
  d <- fx$input
  d$.row <- seq_len(nrow(d))
  truncated <- isTRUE(fx$case$truncated)
  d$.status <- factor(d$event, levels = 0:2)
  x_names <- unlist(fx$case$features)
  d <- d[order(d$stratum, method = "radix"), ]
  lhs <- if (truncated) "Surv(entry, time, .status)" else "Surv(time, .status)"
  for (ties in c("breslow", "efron")) for (cause in c("1", "2")) for (setting in c("default", "tight")) {
    control <- if (setting == "tight") coxph.control(eps = 1e-11, iter.max = 100, timefix = FALSE) else
      coxph.control(timefix = FALSE)
    fg <- finegray(as.formula(paste(lhs, "~ .row + strata(stratum)")), data = d, etype = cause, id = id,
                   timefix = FALSE)
    rows <- match(fg$.row, d$.row)
    X <- as.matrix(d[rows, x_names])
    frame <- cbind(fg, X, id = d$id[rows], stratum = d$stratum[rows])
    f <- as.formula(paste("Surv(fgstart, fgstop, fgstatus) ~", paste(x_names, collapse = " + "), "+ strata(stratum)"))
    direct <- coxph(f, data = frame, weights = fgwt, cluster = id, ties = ties, control = control)
    y <- Surv(fg$fgstart, fg$fgstop, fg$fgstatus)
    strata <- as.integer(factor(d$stratum[rows]))
    fit <- agreg.fit(X, y, strata, rep(0, nrow(fg)), NULL, control, weights = fg$fgwt, method = ties,
                     rownames = NULL, nocenter = c(-1, 0, 1))
    object <- c(fit, list(x = X, y = y, weights = fg$fgwt))
    object$naive.var <- fit$var
    object$strata <- strata
    object$terms <- direct$terms
    object$class <- NULL
    class(object) <- fit$class
    subject <- d$id[rows]
    robust <- crossprod(residuals(object, type = "dfbeta", collapse = match(subject, unique(subject)), weighted = TRUE))
    same <- c(coefficients = identical(unname(coef(direct)), unname(fit$coefficients)),
              robust = identical(unname(direct$var), unname(robust)),
              model_based = identical(unname(direct$naive.var), unname(fit$var)),
              loglik = identical(direct$loglik, fit$loglik), iterations = identical(direct$iter, fit$iter))
    r <- fx$survival[[ties]]$fine_gray[[cause]][[setting]]
    py <- fx$pprof_py[[ties]]$fine_gray[[cause]][[setting]]
    say(sprintf("  %-20s %-7s cause %s %-7s rows %d -> %d; bitwise: %s; against the fixture's survival record: %s; against pprof_py: coefficients %.3g, robust %.3g, model-based %.3g; iterations %d and pprof_py's %d",
                fx$case$id, ties, cause, setting, nrow(d), nrow(fg),
                paste(names(same), same, sep = " ", collapse = ", "),
                if (identical(unname(coef(direct)), unlist(r$coef)) && identical(packed(direct$var), unlist(r$covariance)))
                  "identical" else "differs",
                units(fit$coefficients, py$coef, cox_coefficient), units(packed(robust), py$covariance, cox_variance),
                units(packed(fit$var), py$naive_covariance, cox_variance), min(fit$iter, control$iter.max),
                as.integer(py$iterations)))
  }
}

say("")
say("B. Cumulative incidence: survfit() of the package-style coxph() object (tight fits)")
say("C. Log-likelihoods: pprof_py's against survival's (tight fits), in units of cox_function")
for (path in fixtures) {
  fx <- readRDS(path)
  d <- fx$input
  d$.row <- seq_len(nrow(d))
  truncated <- isTRUE(fx$case$truncated)
  d$.status <- factor(d$event, levels = 0:2)
  x_names <- unlist(fx$case$features)
  d <- d[order(d$stratum, method = "radix"), ]
  lhs <- if (truncated) "Surv(entry, time, .status)" else "Surv(time, .status)"
  for (ties in c("breslow", "efron")) for (cause in c("1", "2")) {
    fg <- finegray(as.formula(paste(lhs, "~ .row + strata(stratum)")), data = d, etype = cause, id = id,
                   timefix = FALSE)
    rows <- match(fg$.row, d$.row)
    frame <- data.frame(.start = fg$fgstart, .stop = fg$fgstop, .status = fg$fgstatus, .weight = fg$fgwt,
                        .provider = d$stratum[rows])
    for (j in seq_along(x_names)) frame[[sprintf(".x%d", j)]] <- d[[x_names[j]]][rows]
    f <- as.formula(paste("Surv(.start, .stop, .status) ~", paste(sprintf(".x%d", seq_along(x_names)), collapse = " + "),
                          "+ strata(.provider)"))
    engine <- coxph(f, data = frame, weights = .weight, ties = ties, robust = FALSE, model = FALSE,
                    control = coxph.control(eps = 1e-11, iter.max = 100, timefix = FALSE))
    r <- fx$survival[[ties]]$fine_gray[[cause]]
    py <- fx$pprof_py[[ties]]$fine_gray[[cause]]
    identical_curves <- TRUE
    worst_py <- 0
    for (k in seq_along(r$cumulative_incidence)) {
      block <- r$cumulative_incidence[[k]]
      py_block <- py$cumulative_incidence[[k]]
      for (i in seq_along(py$profiles)) {
        newdata <- data.frame(.provider = block$stratum)
        for (j in seq_along(x_names)) newdata[[sprintf(".x%d", j)]] <- unlist(py$profiles[[i]])[j]
        curve <- survfit(engine, newdata = newdata, se.fit = FALSE)
        incidence <- 1 - curve$surv
        identical_curves <- identical_curves && identical(curve$time, unlist(block$time)) &&
          identical(incidence, unlist(block$cumulative_incidence[[i]]))
        at <- match(unlist(py_block$time), curve$time)
        worst_py <- max(worst_py, units(incidence[at], py_block$cumulative_incidence[[i]], cox_baseline))
      }
    }
    say(sprintf("  %-20s %-7s cause %s: curves identical to the generator's %s; against pprof_py at its times %.3g units of cox_baseline; log-likelihood %.3g and null %.3g units of cox_function; the engine object's log-likelihoods equal the record's: %s",
                fx$case$id, ties, cause, identical_curves, worst_py,
                units(py$tight$loglik, r$tight$loglik, cox_function), units(py$tight$loglik_null, r$tight$loglik_null, cox_function),
                identical(engine$loglik, c(unlist(r$tight$loglik_null), unlist(r$tight$loglik)))))
  }
}
writeLines(out, commandArgs(TRUE)[1])
