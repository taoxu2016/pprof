# CoxPH C5 plan, §2.1 to §2.4: what survival 3.8-12's Surv() and finegray() do with the inputs of
# fit_fine_gray(), on small data (31_finegray_inputs.py gives pprof_py v0.7.0's side):
#  A. Surv()'s readings of a status with several event types;
#  B. finegray()'s case weights, which it applies to the wrong rows in every stratum after the first,
#     zero weights among them, a provider without events of the cause, `etype`, `id` with
#     right-censored data, one event type, and `timefix`;
#  C. finegray() decides delayed entry over all rows: called once per provider, it can expand a
#     provider's rows otherwise than one call stratified by provider;
#  D. weights that are not finite: with delayed entry, the censoring-times-entry curve can be 0 at a
#     competing event, and finegray() then gives its extension pieces NaN weights, on the benchmark's
#     rows-1e4 scenario (10 rows per provider) and on one of its providers alone; with the event of
#     interest before the competing events, no piece follows and every weight is finite.
# Run from the repository root: Rscript dev/design/coxph-facts/31_finegray_inputs.R <output file>
suppressMessages(library(survival))
source(file.path("dev", "bench", "cox", "scenarios.R"))
out <- character()
say <- function(...) out <<- c(out, paste0(...))
caught <- function(expr) {
  warnings <- character()
  value <- tryCatch(withCallingHandlers(expr, warning = function(w) {
    warnings <<- c(warnings, conditionMessage(w))
    invokeRestart("muffleWarning")
  }), error = function(e) structure(conditionMessage(e), class = "failure"))
  list(value = value, warnings = warnings)
}
describe <- function(s) {
  v <- s$value
  if (inherits(v, "failure")) return(paste("error:", unclass(v)))
  if (is.data.frame(v)) return(sprintf("accepted, %d rows", nrow(v)))
  states <- attr(v, "states")
  sprintf("type %s%s; status %s%s", attr(v, "type"),
          if (is.null(states)) "" else sprintf(", states %s", paste(states, collapse = ",")),
          paste(unclass(v)[, ncol(unclass(v))], collapse = ","),
          if (length(s$warnings)) sprintf("; warning: %s", paste(unique(s$warnings), collapse = " | ")) else "")
}
say(sprintf("%s, survival %s", R.version.string, packageVersion("survival")))

say("", "A. Surv() and a status with several event types (time 5, 3, 4, 6, 2, 1):")
time <- c(5, 3, 4, 6, 2, 1)
code <- c(0, 1, 2, 0, 2, 1)
say("  numeric 0/1/2:                      ", describe(caught(Surv(time, code))))
say("  numeric 0/1/2, type = \"mstate\":     ", describe(caught(Surv(time, code, type = "mstate"))))
say("  factor(0/1/2):                      ", describe(caught(Surv(time, factor(code)))))
say("  factor(0/1/2, levels = 0:2) with no 0s (1, 2, 2, 1, 1, 2): ",
    describe(caught(Surv(time, factor(c(1, 2, 2, 1, 1, 2), levels = 0:2)))))
say("  factor without its censoring level (1, 2, 2, 1, 1, 2): ", describe(caught(Surv(time, factor(c(1, 2, 2, 1, 1, 2))))))
say("  labelled factor (none, relapse, death): ",
    describe(caught(Surv(time, factor(c("none", "relapse", "death", "none", "death", "relapse"),
                                      levels = c("none", "relapse", "death"))))))
say("  factor with a missing value:        ", describe(caught(Surv(time, factor(c(0, 1, NA, 0, 2, 1))))))
say("  (start, stop] with a factor:        ", describe(caught(Surv(c(0, 0, 1, 0, 0, 0), time, factor(code)))))
say("  factor with one event level, factor(0/1): ", describe(caught(Surv(time, factor(c(0, 1, 1, 0, 1, 1))))))

say("", "B. finegray() on 60 rows in 3 providers of 20, cause 1 (timefix = FALSE unless stated):")
set.seed(1)  # a fact script: package code never calls set.seed()
d <- data.frame(id = 1:60, .row = 1:60, time = sample(1:20, 60, TRUE), x = rnorm(60), prov = rep(1:3, each = 20))
d$status <- factor(sample(0:2, 60, TRUE, prob = c(0.4, 0.3, 0.3)), levels = 0:2)
# Case weights 1 to 4 in provider 1, 10 to 40 in provider 2, 100 to 400 in provider 3; three of provider 2's are 0.
d$w <- rep(1:4, 15) * 10^(d$prov - 1)
d$w[c(22, 25, 29)] <- 0
plain <- finegray(Surv(time, status) ~ x + prov + .row + strata(prov), data = d, etype = "1", timefix = FALSE)
weighted <- finegray(Surv(time, status) ~ x + prov + .row + strata(prov), data = d, etype = "1", weights = w,
                     timefix = FALSE)
multiplied <- plain
multiplied$fgwt <- plain$fgwt * d$w[plain$.row]
say("  case weights (1 to 4, 10 to 40, and 100 to 400 by provider, three of provider 2's 0): ", nrow(weighted),
    " expanded rows, with the rows and times of the call without weights: ",
    identical(weighted$.row, plain$.row) && identical(weighted$fgstart, plain$fgstart) &&
      identical(weighted$fgstop, plain$fgstop),
    " (the censoring curve is unweighted, so case weights can only multiply the output weights)")
for (p in 1:3) {
  k <- plain$prov == p
  applied <- unique(weighted$fgwt[k] / plain$fgwt[k])
  say(sprintf("    provider %d: finegray(weights = w) equals the transform's weights times each row's own case weight: %s; the case weights it applied: %s",
              p, identical(weighted$fgwt[k], multiplied$fgwt[k]), paste(sort(applied), collapse = ",")))
}
say("    (survival 3.8-12's finegray() multiplies by user.weights[split$row], where split$row counts the rows of",
    " the stratum, so every stratum after the first gets the case weights of the data's first rows)")
fit_weighted <- coxph(Surv(fgstart, fgstop, fgstatus) ~ x + strata(prov), data = weighted[weighted$fgwt > 0, ],
                      weights = fgwt, control = coxph.control(timefix = FALSE))
fit_multiplied <- coxph(Surv(fgstart, fgstop, fgstatus) ~ x + strata(prov), data = multiplied[multiplied$fgwt > 0, ],
                        weights = fgwt, control = coxph.control(timefix = FALSE))
say("  the weighted fit's coefficient (rows of weight 0 left out): with finegray(weights = w) ",
    format(coef(fit_weighted), digits = 10), ", with the weights multiplied after the call ",
    format(coef(fit_multiplied), digits = 10))
say("  rows of case weight 0: ", sum(multiplied$fgwt == 0), " pieces of weight 0, and coxph() of them: ",
    describe(caught(coxph(Surv(fgstart, fgstop, fgstatus) ~ x + strata(prov), data = multiplied, weights = fgwt,
                          control = coxph.control(timefix = FALSE)))))
d2 <- d
d2$status[d2$prov == 3 & d2$status == "1"] <- "2"
none <- finegray(Surv(time, status) ~ x + prov + strata(prov), data = d2, etype = "1", timefix = FALSE)
say("  provider 3 without events of cause 1: providers in the output ", paste(sort(unique(none$prov)), collapse = ","),
    " (its rows are left out)")
say("  etype = 1, a number: ", nrow(finegray(Surv(time, status) ~ x, data = d, etype = 1, timefix = FALSE)),
    " rows; etype = \"0\", the censoring level: ",
    describe(caught(finegray(Surv(time, status) ~ x, data = d, etype = "0", timefix = FALSE))))
with_id <- finegray(Surv(time, status) ~ x + strata(prov), data = d, etype = "1", id = id, timefix = FALSE)
without <- finegray(Surv(time, status) ~ x + strata(prov), data = d, etype = "1", timefix = FALSE)
cols <- c("fgstart", "fgstop", "fgstatus", "fgwt")
say("  right-censored data: the same output with and without id: ", identical(with_id[, cols], without[, cols]))
d3 <- d
d3$id[2] <- d3$id[1]
say("  right-censored data with a repeated id: ",
    describe(caught(finegray(Surv(time, status) ~ x + strata(prov), data = d3, etype = "1", id = id, timefix = FALSE))),
    " (finegray() reads id only for (start, stop] data)")
say("  one event level, factor(0/1): ",
    describe(caught(finegray(Surv(time, factor(as.integer(status == "1"))) ~ x, data = d, timefix = FALSE))))
d4 <- d
d4$status <- factor(as.integer(d4$status == "1"), levels = 0:2)
say("  one event level with an unused second level, factor(0/1, levels = 0:2): ",
    nrow(finegray(Surv(time, status) ~ x, data = d4, etype = "1", timefix = FALSE)), " rows, all of weight 1: ",
    all(finegray(Surv(time, status) ~ x, data = d4, etype = "1", timefix = FALSE)$fgwt == 1))
near <- data.frame(time = c(0.1 + 0.2, 0.3, 0.5, 0.7, 0.9, 1.1), status = factor(c(2, 0, 1, 0, 1, 0), levels = 0:2))
exact <- finegray(Surv(time, status) ~ ., data = near, etype = "1", timefix = FALSE)
merged <- finegray(Surv(time, status) ~ ., data = near, etype = "1")
say("  near-tied times (0.1 + 0.2 and 0.3): timefix = FALSE gives ", nrow(exact), " rows, weights ",
    paste(format(exact$fgwt, digits = 4), collapse = ","), "; timefix = TRUE gives ", nrow(merged), " rows, weights ",
    paste(format(merged$fgwt, digits = 4), collapse = ","))

say("")
say("C. One call stratified by provider against one call per provider (provider 1's own data have no delayed")
say("   entry, and one of its entry times, 10, equals a competing event time; provider 2's make the whole data's")
say("   entry delayed):")
e <- data.frame(provider = c(1, 1, 1, 1, 1, 1, 2, 2, 2, 2), .row = 1:10,
                start = c(0, 10, 5, 0, 0, 2, 0, 0, 4, 0), stop = c(10, 30, 20, 25, 40, 35, 1, 3, 8, 12),
                cause = c(2, 0, 1, 0, 1, 2, 0, 1, 2, 1))
e$.status <- factor(e$cause, levels = 0:2)
one <- finegray(Surv(start, stop, .status) ~ .row + strata(provider), data = e, etype = "1", id = .row, timefix = FALSE)
alone <- finegray(Surv(start, stop, .status) ~ .row, data = e[e$provider == 1, ], etype = "1", id = .row,
                  timefix = FALSE)
show <- function(fg) sprintf("    row %d (%g, %g] status %d weight %.17g", fg$.row, fg$fgstart, fg$fgstop, fg$fgstatus, fg$fgwt)
say("  delayed entry over all rows: ", any(e$start > min(e$stop)), "; within provider 1: ",
    any(e$start[e$provider == 1] > min(e$stop[e$provider == 1])))
say("  provider 1 in the stratified call:")
say(show(one[one$.row <= 6, ]))
say("  provider 1 alone:")
say(show(alone))

say("", "D. Weights that are not finite (delayed entry, small providers):")
s <- cox_bench_scenarios()
s <- s[s$id == "rows-1e4", ]
b <- cox_bench_data(s$n, s$m, s$p, s$seed)
# The C5 benchmark's second cause, without random numbers: every third event row.
b$cause <- ifelse(b$event == 1, ifelse(seq_len(nrow(b)) %% 3 == 0, 2L, 1L), 0L)
b$.status <- factor(b$cause, levels = 0:2)
b$.row <- seq_len(nrow(b))
b <- b[order(b$provider), c("provider", "start", "stop", ".status", ".row")]
fg <- finegray(Surv(start, stop, .status) ~ .row + strata(provider), data = b, etype = "1", id = .row, timefix = FALSE)
bad <- !is.finite(fg$fgwt)
providers <- unique(b$provider[match(fg$.row[bad], b$.row)])
say("  rows-1e4 (10,000 rows, 1,000 providers): ", nrow(fg), " expanded rows, ", sum(bad), " whose weight is not finite (",
    paste(unique(format(fg$fgwt[bad])), collapse = ", "), "), all extension pieces (status 0), in ", length(providers),
    " providers")
cases <- list(
  "provider 43 of rows-1e4" = data.frame(.row = c(909, 3072, 3478, 5394, 5811, 6390, 8822),
                                         start = c(0, 0, 0, 192, 352, 0, 0), stop = c(65, 44, 286, 250, 385, 68, 162),
                                         cause = c(0, 2, 1, 2, 2, 2, 0)),
  "the same with its cause-1 event at 30" = data.frame(.row = c(909, 3072, 3478, 5394, 5811, 6390, 8822),
                                                       start = c(0, 0, 0, 192, 352, 0, 0),
                                                       stop = c(65, 44, 30, 250, 385, 68, 162),
                                                       cause = c(0, 2, 1, 2, 2, 2, 0))
)
for (label in names(cases)) {
  f <- cases[[label]]
  f$.status <- factor(f$cause, levels = 0:2)
  g <- finegray(Surv(start, stop, .status) ~ .row, data = f, etype = "1", id = .row, timefix = FALSE)
  say("  ", label, " alone:")
  say(show(g))
}
writeLines(out, commandArgs(TRUE)[1])
