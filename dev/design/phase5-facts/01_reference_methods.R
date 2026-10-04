# Phase 5 planning: facts from the pinned reference (pprof 1.0.3 in dev/reference/lib).
# Run from the repository root: Rscript <this file> <output file>
args <- commandArgs(trailingOnly = TRUE)
out_file <- args[1]
.libPaths(c("dev/reference/lib", .Library))
Sys.setenv(OMP_THREAD_LIMIT = "1")
Sys.setlocale("LC_COLLATE", "C")
lines <- character()
say <- function(...) lines <<- c(lines, paste0(...))
same <- function(a, b) identical(unname(as.numeric(a)), unname(as.numeric(b)))
maxdiff <- function(a, b) max(abs(as.numeric(a) - as.numeric(b)))
quiet <- function(expr) suppressMessages(suppressWarnings(expr))

suppressPackageStartupMessages(library(pprof))
say("pprof ", as.character(packageVersion("pprof")), " from ", find.package("pprof"))
say("lme4 ", as.character(packageVersion("lme4")), ", Matrix ", as.character(packageVersion("Matrix")),
    ", R ", R.version.string)

data(ExampleDataLinear)
data(ExampleDataBinary)
lin <- data.frame(Y = ExampleDataLinear$Y, ProvID = ExampleDataLinear$ProvID, ExampleDataLinear$Z)
bin <- data.frame(Y = ExampleDataBinary$Y, ProvID = ExampleDataBinary$ProvID, ExampleDataBinary$Z)
z <- paste0("z", 1:5)

fits <- list(
  linear_re = quiet(linear_re(data = lin, Y.char = "Y", Z.char = z, ProvID.char = "ProvID")),
  logis_re = quiet(logis_re(data = bin, Y.char = "Y", Z.char = z, ProvID.char = "ProvID")),
  linear_cre = quiet(linear_cre(data = lin, Y.char = "Y", ProvID.char = "ProvID", wb.char = c("z1", "z2"),
                                other.char = c("z3", "z4", "z5"))),
  logis_cre = quiet(logis_cre(data = bin, Y.char = "Y", ProvID.char = "ProvID", wb.char = c("z1", "z2"),
                              other.char = c("z3", "z4", "z5")))
)

say("")
say("## 1. lme4 Wald intervals of summary() against fixef + sqrt(diag(variance$FE)) %o% qnorm(a)")
for (name in names(fits)) {
  fit <- fits[[name]]
  model <- attr(fit, "model")
  for (level in c(0.95, 0.9)) {
    ci <- confint(model, parm = "beta_", method = "Wald", level = level)
    a <- (1 - level) / 2
    a <- c(a, 1 - a)
    se <- sqrt(diag(fit$variance$FE))
    manual <- as.numeric(fit$coefficient$FE) + se %o% stats::qnorm(a)
    manual2 <- cbind(as.numeric(fit$coefficient$FE) - stats::qnorm(1 - (1 - level) / 2) * se,
                     as.numeric(fit$coefficient$FE) + stats::qnorm(1 - (1 - level) / 2) * se)
    say(sprintf("%s level %.2f: identical to fixef + se %%o%% qnorm(a): %s (max diff %.3g); to beta -/+ qnorm(1 - alpha/2) se: %s (max diff %.3g)",
                name, level, identical(unname(ci), unname(manual)), maxdiff(ci, manual),
                identical(unname(ci), unname(manual2)), maxdiff(ci, manual2)))
  }
}

say("")
say("## 2. lme4 fitted values against the linear predictor plus the provider effect")
for (name in names(fits)) {
  fit <- fits[[name]]
  n_prov <- as.vector(table(factor(fit$data_include[, fit$char_list$ProvID.char])))
  eta <- rep(as.numeric(fit$coefficient$RE), n_prov) + as.numeric(fit$linear_pred)
  mean <- if (grepl("logis", name)) stats::plogis(eta) else eta
  say(sprintf("%s: fitted identical to %s: %s (max diff %.3g); provider sums identical: %s (max diff %.3g)", name,
              if (grepl("logis", name)) "plogis(alpha + X beta)" else "alpha + X beta",
              same(fit$fitted, mean), maxdiff(fit$fitted, mean),
              same(sapply(split(as.numeric(fit$fitted), rep(seq_along(n_prov), n_prov)), sum),
                   sapply(split(mean, rep(seq_along(n_prov), n_prov)), sum)),
              maxdiff(sapply(split(as.numeric(fit$fitted), rep(seq_along(n_prov), n_prov)), sum),
                      sapply(split(mean, rep(seq_along(n_prov), n_prov)), sum))))
}

say("")
say("## 3. computeDirectExp() against R's sum(plogis(effect + X beta)) (logistic RE/CRE direct limits)")
for (name in c("logis_re", "logis_cre")) {
  fit <- fits[[name]]
  alpha <- as.numeric(fit$coefficient$RE)
  zb <- as.numeric(fit$linear_pred)
  cpp <- as.numeric(pprof:::computeDirectExp(alpha, zb, 1))
  r_sum <- vapply(alpha, function(a) sum(stats::plogis(a + zb)), numeric(1))
  cpp2 <- as.numeric(pprof:::computeDirectExp(alpha, zb, 2))
  say(sprintf("%s: identical: %s; differing providers %d of %d; max relative diff %.3g; 1 vs 2 threads identical: %s",
              name, identical(cpp, r_sum), sum(cpp != r_sum), length(cpp), max(abs(cpp - r_sum) / abs(r_sum)),
              identical(cpp, cpp2)))
}

say("")
say("## 4. Conditional SDs recomputed from the stored lme4 fit")
for (name in c("logis_re", "linear_cre", "logis_cre")) {
  fit <- fits[[name]]
  model <- attr(fit, "model")
  pv1 <- attr(lme4::ranef(model, condVar = TRUE)[[fit$char_list$ProvID.char]], "postVar")[1, 1, ]
  pv2 <- attr(lme4::ranef(model, condVar = TRUE)[[fit$char_list$ProvID.char]], "postVar")[1, 1, ]
  t1 <- test(fit)
  say(sprintf("%s: repeated ranef() identical: %s; test()$Std.Error identical to sqrt(postVar): %s", name,
              identical(pv1, pv2), same(t1$Std.Error, sqrt(pv1))))
}

say("")
say("## 5. Linear FE: D-14 (integer null), D-32 (interval multipliers), direct observed total")
lfe <- quiet(linear_fe(data = lin, Y.char = "Y", Z.char = z, ProvID.char = "ProvID"))
lfe_full <- quiet(linear_fe(data = lin, Y.char = "Y", Z.char = z, ProvID.char = "ProvID", option.gamma.var = "full"))
for (call in c("test(lfe, null = 0L)", "SM_output(lfe, null = 0L)", "confint(lfe, null = 0L)", "plot(lfe, null = 0L)",
               "test(lfe, null = 0)", "SM_output(lfe, null = 0)", "test(lfe, null = c(0, 1))")) {
  res <- tryCatch({ value <- quiet(eval(parse(text = call))); "value" }, error = function(e) paste("error:", conditionMessage(e)))
  say(sprintf("%s -> %s", call, res))
}
n <- nrow(lfe$data_include); m <- length(lfe$coefficient$gamma); p <- length(lfe$coefficient$beta)
for (f in list(list(lfe, "simplified"), list(lfe_full, "full"))) {
  ci <- confint(f[[1]], option = "gamma")
  mult <- (ci$gamma.Upper - ci$gamma) / sqrt(f[[1]]$variance$gamma)
  say(sprintf("confint.linear_fe %s: multiplier %.7f (qt(0.975, %d) = %.7f, qnorm(0.975) = %.7f)", f[[2]],
              stats::median(mult), n - m - p, stats::qt(0.975, n - m - p), stats::qnorm(0.975)))
  tt <- test(f[[1]])
  prob_n <- stats::pnorm(tt$stat, lower.tail = FALSE)
  say(sprintf("test.linear_fe %s: p values from pnorm: %s; from pt(df = n - m - p): %s", f[[2]],
              same(tt$`p value`, 2 * pmin(prob_n, 1 - prob_n)),
              same(tt$`p value`, 2 * pmin(stats::pt(tt$stat, n - m - p, lower.tail = FALSE),
                                          1 - stats::pt(tt$stat, n - m - p, lower.tail = FALSE)))))
}
sm_med <- SM_output(lfe, stdz = "direct")
sm_mean <- SM_output(lfe, stdz = "direct", null = "mean")
say(sprintf("SM_output.linear_fe direct Obs: median %.10g, mean %.10g, sum(y) %.10g", sm_med$OE$OE_direct$Obs[1],
            sm_mean$OE$OE_direct$Obs[1], sum(lin$Y)))
say(sprintf("direct differences change with null: %s", !identical(sm_med$direct.difference, sm_mean$direct.difference)))
say(sprintf("qt(p, df = Inf) identical to qnorm(p): %s; pt(x, df = Inf) identical to pnorm(x): %s",
            identical(stats::qt(c(0.975, 0.95, 0.995), Inf), stats::qnorm(c(0.975, 0.95, 0.995))),
            identical(stats::pt(c(-3, 0.5, 2.1), Inf), stats::pnorm(c(-3, 0.5, 2.1)))))

say("")
say("## 6. plot.linear_fe(): layers")
pl <- quiet(plot(lfe, alpha = c(0.05, 0.01)))
built <- ggplot2::ggplot_build(pl)
for (k in seq_along(built$data)) {
  say(sprintf("layer %d (%s): %d rows", k, class(pl$layers[[k]]$geom)[1], nrow(built$data[[k]])))
}
pd <- pl$layers[[2]]$data
say(sprintf("line layer data: %d rows for %d providers and 2 levels; columns %s", nrow(pd), m,
            paste(names(pd), collapse = ", ")))
say(sprintf("lower limits below 0 (no floor): %s", any(pd$lower < 0)))
ord <- order(pd$precision)
flags_test <- test(lfe, level = 1 - 0.05)
say(sprintf("flags: table %s", paste(names(table(pl$layers[[1]]$data$flag)), table(pl$layers[[1]]$data$flag), collapse = "; ")))

say("")
say("## 7. RE/CRE methods: D-31, character IDs, parm, null validation, partial matches")
s <- summary(fits$logis_re)
say(sprintf("summary.logis_re p values: %s", paste(s$`p value`, collapse = ", ")))
say(sprintf("summary.logis_re rows: %s", paste(rownames(s), collapse = ", ")))
s2 <- tryCatch(summary(fits$linear_re, parm = "(Intercept)"), error = function(e) conditionMessage(e))
s3 <- summary(fits$linear_re, parm = "(intercept)")
say(sprintf("summary.linear_re(parm = '(Intercept)') rows: %d; parm = '(intercept)' rows: %d", NROW(s2), NROW(s3)))
res <- tryCatch(test(fits$linear_re, null = "median"), error = function(e) paste("error:", conditionMessage(e)))
say(sprintf("test.linear_re(null = 'median') -> %s", if (is.character(res)) res else "value"))
op <- options(warnPartialMatchDollar = TRUE)
w <- character()
withCallingHandlers(invisible(summary(fits$linear_re)), warning = function(x) { w <<- c(w, conditionMessage(x)); invokeRestart("muffleWarning") })
withCallingHandlers(invisible(confint(fits$logis_re)), warning = function(x) { w <<- c(w, conditionMessage(x)); invokeRestart("muffleWarning") })
withCallingHandlers(invisible(SM_output(fits$logis_re, threads = 1)), warning = function(x) { w <<- c(w, conditionMessage(x)); invokeRestart("muffleWarning") })
options(op)
say(sprintf("partial-match warnings (summary.linear_re, confint.logis_re, SM_output.logis_re): %s", paste(unique(w), collapse = " | ")))
chr <- bin
chr$ProvID <- sprintf("P%03d", chr$ProvID)
chr_fit <- quiet(logis_re(data = chr, Y.char = "Y", Z.char = z, ProvID.char = "ProvID"))
say(sprintf("logis_re with character IDs: data_include column classes %s",
            paste(unique(vapply(chr_fit$data_include, function(x) class(x)[1], "")), collapse = ", ")))
for (call in c("test(chr_fit, parm = c('P001', 'P040'))", "SM_output(chr_fit, parm = c('P001', 'P040'), threads = 1)",
               "confint(chr_fit, parm = c('P001', 'P040'))", "confint(chr_fit, option = 'alpha', parm = c('P001', 'P040'))",
               "test(chr_fit, parm = 1:2)", "test(fits$logis_re, parm = 1:2)", "test(fits$logis_re, parm = c(1L, 40L))")) {
  res <- tryCatch({ v <- quiet(eval(parse(text = call))); sprintf("value (%d rows)", NROW(if (is.data.frame(v)) v else v[[1]])) },
                  error = function(e) paste("error:", conditionMessage(e)))
  say(sprintf("%s -> %s", call, res))
}
say(sprintf("example binary data: providers with no events %s, all events %s",
            paste(names(which(tapply(bin$Y, bin$ProvID, sum) == 0)), collapse = " "),
            paste(names(which(tapply(bin$Y, bin$ProvID, mean) == 1)), collapse = " ")))
ci_re <- confint(fits$logis_re, stdz = c("indirect", "direct"))
say(sprintf("confint.logis_re: indirect ratio lower of no-event provider 40: %.6g (point %.6g)",
            ci_re$CI.indirect_ratio["40", "Ratio.Lower"], ci_re$CI.indirect_ratio["40", "Indirect.Ratio"]))
say(sprintf("confint.logis_re attributes: %s", paste(names(attributes(ci_re$CI.indirect_rate)), collapse = ", ")))
say(sprintf("confint.logis_cre indirect rate model attribute: %s; level attribute: %s",
            attr(confint(fits$logis_cre)$CI.indirect_rate, "model"), attr(confint(fits$logis_cre)$CI.indirect_rate, "confidence_level")))

say("")
say("## 8. Timing of the reference methods on the example data (one run each, seconds)")
timeit <- function(expr) { t <- system.time(quiet(expr))[["elapsed"]]; sprintf("%.2f", t) }
for (name in names(fits)) {
  fit <- fits[[name]]
  logistic <- grepl("logis", name)
  say(sprintf("%s: test %s, SM_output both %s, confint SM both %s, confint alpha %s, summary %s", name,
              timeit(test(fit)),
              timeit(if (logistic) SM_output(fit, stdz = c("indirect", "direct"), threads = 1) else SM_output(fit, stdz = c("indirect", "direct"))),
              timeit(confint(fit, stdz = c("indirect", "direct"))), timeit(confint(fit, option = "alpha")),
              timeit(summary(fit))))
}
say(sprintf("linear_fe: test %s, SM_output both %s, confint SM both %s, summary %s, plot %s", timeit(test(lfe)),
            timeit(SM_output(lfe, stdz = c("indirect", "direct"))), timeit(confint(lfe, stdz = c("indirect", "direct"))),
            timeit(summary(lfe)), timeit(plot(lfe))))

writeLines(lines, out_file)
