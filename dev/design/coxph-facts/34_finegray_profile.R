# CoxPH C5 plan, §2.7: where survival 3.8-12's finegray() spends its time, and how large its expansion is
# with more rows per provider, on the benchmark's data with 33_finegray_cost.R's second cause (every third
# event row), cause 1, and each row its own subject:
#  - Rprof of one finegray() call stratified by provider on center (100,000 rows, 1,000 providers): the
#    functions that take the most time, in total and by themselves;
#  - the expansion of providers-100 (100,000 rows, 100 providers, so 1,000 rows per provider), against
#    center's 100.
# Run from the repository root: Rscript dev/design/coxph-facts/34_finegray_profile.R <output file>
suppressMessages(library(survival))
source(file.path("dev", "bench", "cox", "scenarios.R"))
out <- character()
say <- function(...) {
  out <<- c(out, paste0(...))
  writeLines(out, commandArgs(TRUE)[1])
}
say(sprintf("%s, survival %s", R.version.string, packageVersion("survival")))
prepare <- function(id) {
  s <- cox_bench_scenarios()
  s <- s[s$id == id, ]
  d <- cox_bench_data(s$n, s$m, s$p, s$seed)
  d$cause <- ifelse(d$event == 1, ifelse(seq_len(nrow(d)) %% 3 == 0, 2L, 1L), 0L)
  d$.status <- factor(d$cause, levels = 0:2)
  d$.row <- seq_len(nrow(d))
  d[order(d$provider, method = "radix"), c("provider", "start", "stop", ".status", ".row")]
}
d <- prepare("center")
profile <- tempfile(fileext = ".out")
Rprof(profile, interval = 0.01)
t <- system.time(fg <- finegray(Surv(start, stop, .status) ~ .row + strata(provider), data = d, etype = "1", id = .row,
                                timefix = FALSE))
Rprof(NULL)
summary <- summaryRprof(profile)
say(sprintf("center: finegray() %.2f s (%.2f s processor), %d expanded rows; the profile's %.2f s:", t[["elapsed"]],
            t[["user.self"]] + t[["sys.self"]], nrow(fg), summary$sampling.time))
by_total <- head(summary$by.total[!rownames(summary$by.total) %in% c("\"system.time\"", "\"finegray\""), ], 12)
say("  by total time (within finegray()):")
for (k in seq_len(nrow(by_total))) {
  say(sprintf("    %-22s %6.2f s %5.1f%%", rownames(by_total)[k], by_total$total.time[k], by_total$total.pct[k]))
}
by_self <- head(summary$by.self, 8)
say("  by self time:")
for (k in seq_len(nrow(by_self))) {
  say(sprintf("    %-22s %6.2f s %5.1f%%", rownames(by_self)[k], by_self$self.time[k], by_self$self.pct[k]))
}
rm(fg, d)
invisible(gc())
d <- prepare("providers-100")
t <- system.time(fg <- finegray(Surv(start, stop, .status) ~ .row + strata(provider), data = d, etype = "1", id = .row,
                                timefix = FALSE))
say(sprintf("providers-100 (100,000 rows, 100 providers): finegray() %.2f s (%.2f s processor), %d expanded rows (%.1f per row), %d with a weight that is not finite",
            t[["elapsed"]], t[["user.self"]] + t[["sys.self"]], nrow(fg), nrow(fg) / nrow(d), sum(!is.finite(fg$fgwt))))
