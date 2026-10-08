# CoxPH Phase C2 plan (M-28, D-60): which survival call gives the baseline cumulative hazard at x = 0
# and offset 0 of a fit with an offset, the table baseline_hazard() reports. On the two Cox fixture
# cases with weights and an offset (validation/fixtures/cox/, the full set), survival's tight fit as
# the generator makes it (dev/reference/cox/survival.R) against pprof_py's raw baseline (at x = 0 and
# offset 0) and its reported baseline_hazard_ (which includes exp(the weighted mean offset)), both tie
# methods: basehaz(centered = FALSE), the same divided by exp(the weighted mean offset), and survfit()
# with every covariate and the offset at 0.
# Run from the repository root: Rscript dev/design/coxph-facts/20_baseline_offset.R <output file>
suppressMessages(library(survival))
args <- commandArgs(trailingOnly = TRUE)
lines <- sprintf("%s, survival %s", R.version.string, packageVersion("survival"))
say <- function(...) lines <<- c(lines, sprintf(...))
relative <- function(a, b) max(abs(a - b) / abs(b))
for (id in c("rc-stratified-weights-offset", "lt-weights-offset")) {
  fx <- readRDS(file.path("validation", "fixtures", "cox", paste0(id, ".rds")))
  d <- fx$input
  d <- d[d$weight > 0, , drop = FALSE]
  features <- unlist(fx$case$features)
  lhs <- if (isTRUE(fx$case$truncated)) "Surv(entry, time, event)" else "Surv(time, event)"
  f <- as.formula(paste(lhs, "~", paste(features, collapse = " + "), "+ strata(stratum) + offset(offset)"))
  say("")
  say("%s: the offset's weighted mean %.8f (pprof_py's offset_mean %.8f), unweighted mean %.8f", id,
      weighted.mean(d$offset, d$weight), fx$pprof_py$breslow$baseline$offset_mean, mean(d$offset))
  for (ties in c("breslow", "efron")) {
    fit <- coxph(f, data = d, weights = weight, ties = ties, robust = FALSE,
                 control = coxph.control(eps = 1e-11, iter.max = 100, timefix = FALSE))
    py <- fx$pprof_py[[ties]]$baseline
    keys <- sprintf("%d|%a", unlist(py$raw$stratum), unlist(py$raw$time))
    raw <- unlist(py$raw$cumulative_hazard)
    public <- unlist(py$public_cumulative_hazard)
    bh <- basehaz(fit, centered = FALSE)
    at <- match(keys, sprintf("%s|%a", sub("^stratum=", "", bh$strata), bh$time))
    strata_used <- sort(unique(unlist(py$raw$stratum)))
    newdata <- as.data.frame(matrix(0, length(strata_used), length(features), dimnames = list(NULL, features)))
    newdata$offset <- 0
    newdata$stratum <- strata_used
    curves <- survfit(fit, newdata = newdata, se.fit = FALSE)
    zero <- do.call(rbind, lapply(seq_along(strata_used), function(i) {
      data.frame(key = sprintf("%d|%a", strata_used[i], curves[i]$time), cumulative_hazard = curves[i]$cumhaz)
    }))
    at_zero <- match(keys, zero$key)
    say("  %s ties, largest relative difference at pprof_py's %d event times:", ties, length(keys))
    say("    basehaz(centered = FALSE) against pprof_py's baseline_hazard_ %.1e, against its raw baseline %.1e",
        relative(bh$hazard[at], public), relative(bh$hazard[at], raw))
    say("    basehaz(centered = FALSE) / exp(weighted mean offset) against the raw baseline %.1e",
        relative(bh$hazard[at] / exp(weighted.mean(d$offset, d$weight)), raw))
    say("    survfit() at x = 0 and offset 0 against the raw baseline %.1e (%d points found)",
        relative(zero$cumulative_hazard[at_zero], raw), sum(!is.na(at_zero)))
  }
}
writeLines(lines, args[1])
