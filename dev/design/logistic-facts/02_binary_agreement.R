# Logistic extensions brief, Appendix A: pprofR 0.2.0 against pprof on binary outcomes (one trial
# per row), quantity by quantity. pprof reproduces pprof 1.0.3 bitwise on this platform
# (validation/equivalence-report.md), so a difference from pprof is a difference from pprof 1.0.3.
# Data: a synthetic data set (facts_simulate(), 40 providers), ExampleDataBinary (with three
# providers without events), and the synthetic data with rows whose linear predictor is far below
# 0, where the null probabilities fall below 1e-10. Fits use pprof's defaults (SerBIN,
# tol = 1e-5, stopping rule "any" = pprofR's "or", backtracking, effect bound 10, providers of at
# least 10 rows), passed explicitly to pprofR, whose default stopping rule is "beta", and, for
# the fits alone, every combination of method, stopping rule, and tol below.
# Run from the repository root after 01: Rscript dev/design/logistic-facts/02_binary_agreement.R <output file>
source("dev/design/logistic-facts/facts_data.R")
args <- commandArgs(trailingOnly = TRUE)
facts_use_libraries()
suppressPackageStartupMessages({
  library(pprof)
  library(pprofR)
})
out <- c("# 02: pprofR against pprof on binary outcomes", "",
         sprintf("pprofR %s, pprof %s, %s.", utils::packageVersion("pprofR"), utils::packageVersion("pprof"),
                 R.version.string), "")

data(ExampleDataBinary, package = "pprof")
example <- data.frame(y = ExampleDataBinary$Y, n = 1L, provider = sprintf("P%03d", ExampleDataBinary$ProvID),
                      cluster = sprintf("C%05d", seq_along(ExampleDataBinary$Y)), ExampleDataBinary$Z)
names(example)[5:9] <- paste0("x", 1:5)
synthetic <- facts_simulate(m = 40, seed = 2)
extreme <- synthetic
extreme$x1[seq(1, nrow(extreme), by = 25)] <- -60
extreme$y[extreme$x1 == -60] <- 0L
datasets <- list(synthetic = synthetic, example = example, extreme = extreme)
covariates <- list(synthetic = c("x1", "x2", "x3"), example = paste0("x", 1:5), extreme = c("x1", "x2", "x3"))

prep <- function(d, z) {
  suppressWarnings(suppressMessages(pprofR::fe_data_prep(Y = d["y"], Z = d[z], ProvID = d["provider"], cutoff = 10,
                                                         check = FALSE, message = FALSE)))
}
fit_both <- function(d, z, method = "serbin", stop = "any", tol = 1e-5) {
  stop_r <- c(any = "or", coefficients = "beta")[[stop]]
  fit_r <- pprofR::logis_fe(prep(d, z), algorithm = c(serbin = "SerBIN", ban = "BAN")[[method]], tol = tol,
                            stop = stop_r, AUC = TRUE)
  formula <- stats::reformulate(z, response = "y")
  fit_p <- suppressWarnings(pprof::fit_logistic_fe(formula, d, "provider", method = method, tol = tol, stop_rule = stop,
                                                   keep_data = TRUE))
  list(r = fit_r, p = fit_p)
}
by_id <- function(x, ids) x[match(ids, names(x))]

for (name in names(datasets)) {
  d <- datasets[[name]]
  z <- covariates[[name]]
  out <- c(out, facts_header(sprintf("## %s: fits (%d rows)", name, nrow(d))))
  for (method in c("serbin", "ban")) for (stop in c("any", "coefficients")) for (tol in c(1e-5, 1e-10)) {
    f <- fit_both(d, z, method, stop, tol)
    label <- sprintf("%s, %s, tol %g", method, stop, tol)
    out <- c(out, sprintf("| %s: iterations (pprofR, pprof) | %d, %d | | %s |", label, f$r$control$iter,
                          f$p$convergence$iterations, if (f$r$control$iter == f$p$convergence$iterations) "yes" else "no"),
             facts_row(paste(label, "coefficients"), f$r$beta, coef(f$p)),
             facts_row(paste(label, "provider effects"), f$r$gamma, f$p$provider_effects))
  }
  f <- fit_both(d, z)
  ids <- names(f$p$provider_effects)
  v_r <- vcov(f$r)
  out <- c(out,
           facts_row("defaults: covariance of the coefficients", v_r, vcov(f$p)),
           facts_row("defaults: variance of the provider effects", by_id(attr(v_r, "var.gamma"), ids),
                     f$p$provider_effect_variance),
           facts_row("defaults: log-likelihood", -f$r$neg2Loglkd / 2, f$p$loglik),
           facts_row("defaults: AIC, BIC", c(f$r$AIC, f$r$BIC), c(f$p$aic, f$p$bic)),
           facts_row("defaults: AUC", f$r$AUC, f$p$auc), "")

  # Provider tests.
  out <- c(out, facts_header(sprintf("## %s: provider tests, intervals, and measures at the defaults", name)))
  test_r <- function(...) {
    t <- pprofR::test_fe(f$r, ...)
    list(p = t$p, stat = t$stat, flag = as.integer(as.character(t$flag)), se = t$se.gamma, id = rownames(t))
  }
  test_p <- function(...) {
    t <- suppressWarnings(pprof::test_providers(f$p, ...))$table
    list(p = t$p_value, stat = t$statistic, flag = t$flag, se = t$std_error, id = t$provider_id)
  }
  pairs <- list(
    `exact, two-sided` = list(test_r(test = "exact.poisbinom"), test_p(test = "exact")),
    `exact, greater` = list(test_r(test = "exact.poisbinom", alternative = "greater"),
                            test_p(test = "exact", alternative = "greater")),
    `exact, less` = list(test_r(test = "exact.poisbinom", alternative = "less"),
                         test_p(test = "exact", alternative = "less")),
    `score (modified)` = list(test_r(test = "score"), test_p(test = "score")),
    `Wald` = list(test_r(test = "wald"), test_p(test = "wald"))
  )
  set.seed(11)
  boot_r <- test_r(test = "exact.bootstrap", n = 2000)
  set.seed(11)
  boot_p <- test_p(test = "bootstrap", n_resamples = 2000)
  pairs$`bootstrap (seed 11, 2000 draws)` <- list(boot_r, boot_p)
  for (test in names(pairs)) {
    a <- pairs[[test]][[1]]
    b <- pairs[[test]][[2]]
    stopifnot(identical(a$id, b$id))
    out <- c(out, facts_row(paste(test, "p-value"), a$p, b$p), facts_row(paste(test, "statistic"), a$stat, b$stat),
             sprintf("| %s flags differing | %d of %d | | |", test, sum(a$flag != b$flag, na.rm = TRUE), length(a$flag)))
    if (!is.null(a$se)) out <- c(out, facts_row(paste(test, "standard error"), a$se, b$se))
  }

  # Intervals of the provider effects.
  for (interval in c("exact", "score", "wald")) {
    ci_r <- suppressWarnings(stats::confint(f$r, option = "gamma", test = interval))
    ci_p <- suppressWarnings(pprof::provider_effects(f$p, interval = interval))$table
    out <- c(out, facts_row(sprintf("%s interval of the effects, lower", interval), ci_r$gamma.lower, ci_p$lower),
             facts_row(sprintf("%s interval of the effects, upper", interval), ci_r$gamma.upper, ci_p$upper))
  }

  # Standardized measures; pprof's rates are in percent, pprofR's on 0 to 1.
  sr <- pprofR::SR_output(f$r, stdz = c("indirect", "direct"), measure = c("ratio", "rate"))
  sm <- pprof::standardize_providers(f$p, standardization = c("indirect", "direct"), measure = c("ratio", "rate"))$table
  pick <- function(s, m) sm[sm$standardization == s & sm$measure == m, ]
  out <- c(out,
           facts_row("indirect: expected", sr$OE$OE_indirect$Exp.indirect_provider, pick("indirect", "ratio")$expected),
           facts_row("indirect: null variance", sr$OE$OE_indirect$Var.indirect_provider, pick("indirect", "ratio")$variance),
           facts_row("indirect ratio", sr$indirect.ratio, pick("indirect", "ratio")$estimate),
           facts_row("indirect rate x 100 (pprofR) against the rate in percent (pprof)", 100 * sr$indirect.rate,
                     pick("indirect", "rate")$estimate),
           facts_row("direct: expected", sr$OE$OE_direct$Exp.direct_all, pick("direct", "ratio")$expected),
           facts_row("direct ratio", sr$direct.ratio, pick("direct", "ratio")$estimate),
           facts_row("direct rate x 100 against the rate in percent", 100 * sr$direct.rate, pick("direct", "rate")$estimate))
  for (interval in c("exact", "score")) {
    ci_r <- suppressWarnings(stats::confint(f$r, option = "SM", test = interval, stdz = c("indirect", "direct"),
                                            measure = c("ratio", "rate")))
    ci_p <- suppressWarnings(pprof::standardize_providers(f$p, standardization = c("indirect", "direct"),
                                                          measure = c("ratio", "rate"), interval = interval))$table
    pick_p <- function(s, m) ci_p[ci_p$standardization == s & ci_p$measure == m, ]
    out <- c(out,
             facts_row(sprintf("%s interval, indirect ratio, lower and upper", interval),
                       c(ci_r$CI.indirect_ratio$CI_ratio.lower, ci_r$CI.indirect_ratio$CI_ratio.upper),
                       c(pick_p("indirect", "ratio")$lower, pick_p("indirect", "ratio")$upper)),
             facts_row(sprintf("%s interval, direct ratio, lower and upper", interval),
                       c(ci_r$CI.direct_ratio$CI_ratio.lower, ci_r$CI.direct_ratio$CI_ratio.upper),
                       c(pick_p("direct", "ratio")$lower, pick_p("direct", "ratio")$upper)))
  }

  # Covariate tests; at the default settings both refit the null models alike (D-10 aside).
  for (test in c("wald", "lr", "score")) {
    s_r <- pprofR::summary_fe_covar(f$r, test = test)
    s_p <- pprof::test_coefficients(f$p, test = test)$table
    stat_r <- if (identical(test, "wald")) s_r$Z else s_r$stat
    out <- c(out, facts_row(sprintf("covariates, %s: statistic", test), stat_r, s_p$statistic),
             facts_row(sprintf("covariates, %s: p-value", test), s_r$p, s_p$p_value))
    if (identical(test, "wald")) out <- c(out, facts_row("covariates, wald: standard error", s_r$se.beta, s_p$std_error))
  }
  out <- c(out, "")
}

# Null probabilities beyond pprof's clamp in the extreme data set.
f <- fit_both(extreme, covariates$extreme)
p0 <- stats::plogis(stats::median(f$p$provider_effects) + f$p$linear_predictor)
out <- c(out, sprintf("extreme: %d of %d null probabilities below 1e-10 (pprof clamps them to 1e-10 in the exact, bootstrap, and score tests; pprofR does not).",
                      sum(p0 < 1e-10), length(p0)))
writeLines(out, args[1])
