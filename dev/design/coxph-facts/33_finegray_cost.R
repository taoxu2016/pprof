# CoxPH C5 plan, §2.7: the cost of the Fine-Gray fit's survival calls on the benchmark's data
# (dev/bench/cox/scenarios.R), with a second cause derived without random numbers (every third event row
# is of cause 2), cause 1 of interest, Breslow ties, the case weights, and each row its own subject:
#  - finegray() once, stratified by provider, timefix = FALSE, without the case weights, which survival
#    3.8-12's finegray() applies to the wrong rows after the first stratum (31_finegray_inputs.R, part B);
#  - the fitter's inputs from the expansion, the transform's weights times each row's case weight among
#    them; agreg.fit() as coxph() calls it; the robust step (DEC-099);
#  - coxph(cluster = id) on finegray()'s output, the call a user would make; are the two bitwise equal?
#  - finegray() once per provider, and whether its output is the stratified call's.
# Scenarios: center and covariates-5 as generated (delayed entry for about half the rows), and
# providers-7500 as generated and with every entry at 0 (right-censored). Times are elapsed and processor
# seconds of one run each: the machine pages, so elapsed times are indicative. The data are written to
# $COXPH_FACTS_SCRATCH/bench-<scenario>, where 33_finegray_cost.py reads them to time pprof_py's FineGrayPH.
# Run from the repository root: Rscript dev/design/coxph-facts/33_finegray_cost.R <output file>
suppressMessages(library(survival))
source(file.path("dev", "bench", "cox", "scenarios.R"))
scratch <- Sys.getenv("COXPH_FACTS_SCRATCH")
if (!nzchar(scratch)) stop("Set COXPH_FACTS_SCRATCH (see README.md)")
out <- character()
say <- function(...) {
  out <<- c(out, paste0(...))
  writeLines(out, commandArgs(TRUE)[1])
}
timed <- function(expr) {
  t <- system.time(value <- expr)
  list(value = value, elapsed = t[["elapsed"]], processor = t[["user.self"]] + t[["sys.self"]])
}
seconds <- function(t) sprintf("%.2f s (%.2f s processor)", t$elapsed, t$processor)
say(sprintf("%s, survival %s; %s", R.version.string, packageVersion("survival"), Sys.time()))
grid <- cox_bench_scenarios()
runs <- list(list(id = "center", right = FALSE), list(id = "covariates-5", right = FALSE),
             list(id = "providers-7500", right = FALSE), list(id = "providers-7500", right = TRUE))
for (run in runs) {
  s <- grid[grid$id == run$id, ]
  cox_bench_write(s, file.path(scratch, paste0("bench-", s$id)))
  d <- cox_bench_data(s$n, s$m, s$p, s$seed)
  if (run$right) d$start <- 0
  d$cause <- ifelse(d$event == 1, ifelse(seq_len(nrow(d)) %% 3 == 0, 2L, 1L), 0L)
  d$.status <- factor(d$cause, levels = 0:2)
  d$.row <- seq_len(nrow(d))
  d <- d[order(d$provider, method = "radix"), ]
  covariates <- grep("^x", names(d), value = TRUE)
  label <- sprintf("%s%s (%d rows, %d providers, %d covariates)", s$id, if (run$right) ", entry at 0" else "",
                   s$n, s$m, s$p)
  f <- if (run$right) Surv(stop, .status) ~ .row + strata(provider) else Surv(start, stop, .status) ~ .row + strata(provider)
  one <- timed(finegray(f, data = d, etype = "1", id = .row, timefix = FALSE))
  fg <- one$value
  finite <- is.finite(fg$fgwt)
  say(sprintf("%s: finegray() %s; %d expanded rows (%.2f per row), %d with a weight that is not finite", label,
              seconds(one), nrow(fg), nrow(fg) / s$n, sum(!finite)))
  f1 <- if (run$right) Surv(stop, .status) ~ .row else Surv(start, stop, .status) ~ .row
  each <- timed(do.call(rbind, lapply(split(d, d$provider), function(e) {
    if (!any(e$.status == "1")) return(NULL)
    finegray(f1, data = e, etype = "1", id = .row, timefix = FALSE)
  })))
  same <- identical(nrow(each$value), nrow(fg)) && identical(each$value$.row, fg$.row) &&
    identical(each$value$fgstart, fg$fgstart) && identical(each$value$fgstop, fg$fgstop) &&
    identical(each$value$fgwt, fg$fgwt)
  say(sprintf("  finegray() once per provider: %s; %d rows; the stratified call's output: %s", seconds(each),
              nrow(each$value), same))
  if (any(!finite)) next
  inputs <- timed({
    rows <- match(fg$.row, d$.row)
    weight <- fg$fgwt * d$weight[rows]
    x <- as.matrix(d[rows, covariates])
    y <- Surv(fg$fgstart, fg$fgstop, fg$fgstatus)
    strata <- as.integer(factor(d$provider[rows]))
    cluster <- match(fg$.row, unique(fg$.row))
    list(rows = rows, weight = weight, x = x, y = y, strata = strata, cluster = cluster)
  })
  v <- inputs$value
  control <- coxph.control(timefix = FALSE)
  fitter <- timed(agreg.fit(v$x, v$y, v$strata, rep(0, nrow(fg)), NULL, control, weights = v$weight, method = "breslow",
                            rownames = NULL, nocenter = c(-1, 0, 1)))
  fit <- fitter$value
  robust <- timed({
    object <- c(fit, list(x = v$x, y = v$y, weights = v$weight))
    object$naive.var <- fit$var
    object$strata <- v$strata
    object$terms <- stats::terms(v$y ~ v$x)
    object$class <- NULL
    class(object) <- fit$class
    crossprod(residuals(object, type = "dfbeta", collapse = v$cluster, weighted = TRUE))
  })
  frame <- data.frame(fgstart = fg$fgstart, fgstop = fg$fgstop, fgstatus = fg$fgstatus, fgwt = v$weight,
                      provider = d$provider[v$rows], id = fg$.row)
  frame <- cbind(frame, v$x)
  formula <- as.formula(paste("Surv(fgstart, fgstop, fgstatus) ~", paste(covariates, collapse = " + "), "+ strata(provider)"))
  direct <- timed(coxph(formula, data = frame, weights = fgwt, cluster = id, ties = "breslow", control = control))
  same <- identical(unname(coef(direct$value)), unname(fit$coefficients)) &&
    identical(unname(direct$value$var), unname(robust$value))
  say(sprintf("  the fitter's inputs %s; agreg.fit() %s, %d iterations; robust step %s; together %.2f s", seconds(inputs),
              seconds(fitter), fit$iter, seconds(robust), inputs$elapsed + fitter$elapsed + robust$elapsed))
  say(sprintf("  coxph(cluster = id) on finegray()'s output: %s; bitwise the fitter's and robust step's: %s",
              seconds(direct), same))
  rm(fg, frame, v, fit, d)
  invisible(gc())
}
