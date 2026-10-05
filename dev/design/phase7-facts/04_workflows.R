# Phase 7 planning: the workflows the new vignettes would show, run on the bundled data with the
# working tree, and their run times (elapsed seconds, one thread). Part 1 times the new API by
# family; part 2 checks the before-and-after pairs a migration guide would show: each call of
# pprof 1.0.3's interface (the compatibility wrappers) against the new call that replaces it
# (ARCHITECTURE §I.1), reporting whether the numbers are identical and, if not, the largest
# absolute difference. Plots are built and drawn to a null device, as knitr would draw them.
# Run from the repository root: Rscript <this file> <output file> [<library with pprof installed>]
args <- commandArgs(trailingOnly = TRUE)
out_file <- args[1]
lib <- if (length(args) > 1) args[2] else NULL
Sys.setlocale("LC_COLLATE", "C")
if (is.null(lib)) {
  suppressMessages(devtools::load_all(quiet = TRUE))
} else {
  suppressPackageStartupMessages(library(pprof, lib.loc = lib))
}
lines <- character()
say <- function(...) lines <<- c(lines, paste0(...))
quiet <- function(expr) suppressMessages(suppressWarnings(expr))
draw <- function(p) {
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off())
  print(p)
  invisible(p)
}
total <- 0
timed <- function(label, expr) {
  warnings <- character()
  value <- NULL
  t <- system.time(value <- withCallingHandlers(
    tryCatch(expr, error = function(e) structure(conditionMessage(e), class = "timed_error")),
    warning = function(w) {
      warnings <<- c(warnings, gsub("[[:space:]]+", " ", conditionMessage(w)))
      invokeRestart("muffleWarning")
    },
    message = function(m) invokeRestart("muffleMessage")
  ))[["elapsed"]]
  total <<- total + t
  say(sprintf("%6.2f s  %s", t, label),
      if (inherits(value, "timed_error")) paste0("  ERROR: ", value) else "",
      if (length(warnings)) paste0("  [warnings: ", paste(unique(substr(warnings, 1, 90)), collapse = " | "), "]")
      else "")
  value
}
section <- function(title) {
  say("")
  say("## ", title, " (running total before: ", sprintf("%.1f s", total), ")")
}
compare <- function(label, old, new) {
  old <- unname(as.numeric(old))
  new <- unname(as.numeric(new))
  if (length(old) != length(new)) {
    say("  ", label, ": lengths differ (", length(old), " vs ", length(new), ")")
  } else if (identical(old, new)) {
    say("  ", label, ": identical (", length(old), " values)")
  } else {
    both <- is.finite(old) & is.finite(new)
    same_nonfinite <- identical(old[!both], new[!both])
    say("  ", label, ": max abs difference ", signif(max(abs(old[both] - new[both])), 3),
        if (!same_nonfinite) " (non-finite values differ)" else "", " (", length(old), " values)")
  }
}

data(ExampleDataBinary)
data(ExampleDataLinear)
data(ecls_data)
binary <- data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID, ExampleDataBinary$Z)
linear <- data.frame(y = ExampleDataLinear$Y, hospital = ExampleDataLinear$ProvID, ExampleDataLinear$Z)
binary20 <- binary[binary$hospital <= 20, ]
linear20 <- linear[linear$hospital <= 20, ]
covariates <- y ~ z1 + z2 + z3 + z4 + z5

say("# Part 1. The new API by family")
section("Logistic fixed effects, ExampleDataBinary (7,944 observations, 100 providers)")
fit <- timed("fit_logistic_fe()", fit_logistic_fe(covariates, binary, "hospital"))
timed("print() and summary()", utils::capture.output(print(fit), print(summary(fit))))
timed("confint()", confint(fit))
timed("test_coefficients(test = 'lr', data =)", test_coefficients(fit, "lr", data = binary))
timed("test_coefficients(test = 'score', data =)", test_coefficients(fit, "score", data = binary))
tests <- timed("test_providers() (exact)", test_providers(fit))
timed("test_providers('score')", test_providers(fit, "score"))
timed("test_providers('score', score_type = 'standard', data =)",
      test_providers(fit, "score", score_type = "standard", data = binary))
timed("test_providers('wald')", test_providers(fit, "wald"))
set.seed(1)
timed("test_providers('bootstrap') (10,000 resamples)", test_providers(fit, "bootstrap"))
timed("provider_effects(interval = 'exact')", provider_effects(fit, interval = "exact"))
timed("provider_effects(interval = 'score')", provider_effects(fit, interval = "score"))
measures <- timed("standardize_providers() (indirect ratio and rate)", standardize_providers(fit))
timed("standardize_providers(c('indirect', 'direct'))", standardize_providers(fit, c("indirect", "direct")))
measures_exact <- timed("standardize_providers(interval = 'exact')", standardize_providers(fit, interval = "exact"))
timed("standardize_providers(c('indirect', 'direct'), interval = 'exact')",
      standardize_providers(fit, c("indirect", "direct"), interval = "exact"))
timed("standardize_providers(interval = 'score')", standardize_providers(fit, interval = "score"))
funnel <- timed("funnel_limits(level = c(0.95, 0.998))", funnel_limits(fit, level = c(0.95, 0.998)))
profile <- timed("profile_providers()", profile_providers(fit))
profile_exact <- timed("profile_providers(interval = 'exact')", profile_providers(fit, interval = "exact"))
timed("plot_funnel(funnel), drawn", draw(plot_funnel(funnel)))
timed("plot_caterpillar(measures_exact, use_flag = TRUE), drawn",
      draw(plot_caterpillar(measures_exact, use_flag = TRUE)))
timed("plot_flags(tests), drawn", draw(plot_flags(tests)))
timed("plot_volume(profile_exact), drawn", draw(plot_volume(profile_exact)))
timed("tidy(), glance(), augment()", list(tidy(fit), glance(fit), augment(fit), tidy(measures)))
section("Firth, ExampleDataBinary")
firth <- timed("fit_logistic_firth()", fit_logistic_firth(covariates, binary, "hospital"))
timed("test_providers() and standardize_providers(interval = 'exact')",
      list(test_providers(firth), standardize_providers(firth, interval = "exact")))

section("Linear fixed effects, ExampleDataLinear (7,901 observations, 100 providers)")
lfit <- timed("fit_linear_fe()", fit_linear_fe(covariates, linear, "hospital"))
lfit_full <- timed("fit_linear_fe(provider_variance = 'full')",
                   fit_linear_fe(covariates, linear, "hospital", provider_variance = "full"))
timed("summary() and confint()", list(summary(lfit), confint(lfit)))
timed("test_providers()", test_providers(lfit))
timed("standardize_providers(c('indirect', 'direct'), interval = 'wald')",
      standardize_providers(lfit, c("indirect", "direct"), interval = "wald"))
lprofile <- timed("profile_providers(interval = 'wald')", profile_providers(lfit, interval = "wald"))
timed("plot_funnel(lprofile), drawn", draw(plot_funnel(lprofile)))
timed("plot_volume(lprofile), drawn", draw(plot_volume(lprofile)))
section("Linear fixed effects, ecls_data (9,101 children, 2,275 schools)")
efit <- timed("fit_linear_fe(Math_Score ~ Income + Child_Sex, provider = 'School_ID')",
              fit_linear_fe(Math_Score ~ Income + Child_Sex, ecls_data, "School_ID"))
eprofile <- timed("profile_providers(interval = 'wald')", profile_providers(efit, interval = "wald"))
timed("plot_funnel(eprofile), drawn", draw(plot_funnel(eprofile)))
timed("plot_flags(eprofile$tests), drawn", draw(plot_flags(eprofile$tests)))

section("Random effects, full example data")
refit_linear <- timed("fit_linear_re(), ExampleDataLinear", fit_linear_re(covariates, linear, "hospital"))
refit_logistic <- timed("fit_logistic_re(), ExampleDataBinary", fit_logistic_re(covariates, binary, "hospital"))
cre_linear <- timed("fit_linear_cre(within_between = c('z1', 'z2')), ExampleDataLinear",
                    fit_linear_cre(covariates, linear, "hospital", within_between = c("z1", "z2")))
cre_logistic <- timed("fit_logistic_cre(within_between = c('z1', 'z2')), ExampleDataBinary",
                      fit_logistic_cre(covariates, binary, "hospital", within_between = c("z1", "z2")))
for (m in list(list("linear RE", refit_linear), list("logistic RE", refit_logistic),
               list("linear CRE", cre_linear), list("logistic CRE", cre_logistic))) {
  timed(paste(m[[1]], "summary(), test_providers(), standardize_providers(c('indirect', 'direct'), interval = 'wald')"),
        list(summary(m[[2]]), test_providers(m[[2]]),
             standardize_providers(m[[2]], c("indirect", "direct"), interval = "wald")))
}
section("Random effects, providers 1 to 20 (as the help examples)")
timed("fit_logistic_re(), 20 providers", fit_logistic_re(covariates, binary20, "hospital"))
timed("fit_logistic_cre(), 20 providers",
      fit_logistic_cre(covariates, binary20, "hospital", within_between = c("z1", "z2")))
timed("fit_linear_re(), 20 providers", fit_linear_re(covariates, linear20, "hospital"))
say("")
say("Part 1 total: ", sprintf("%.1f s", total))

say("")
say("# Part 2. Before and after: pprof 1.0.3's interface against the new API")
total <- 0
section("logis_fe() against fit_logistic_fe()")
old <- timed("logis_fe(y ~ id(hospital) + z1 + ... + z5, data, message = FALSE)",
             logis_fe(y ~ id(hospital) + z1 + z2 + z3 + z4 + z5, data = binary, message = FALSE))
compare("coefficients: old$coefficient$beta vs coef(fit)", old$coefficient$beta, coef(fit))
compare("provider effects: old$coefficient$gamma vs provider_effects(fit)$table$estimate",
        old$coefficient$gamma, provider_effects(fit)$table$estimate)
compare("vcov: old$variance$beta vs vcov(fit)", old$variance$beta, vcov(fit))
old_test <- timed("test(old)", test(old))
compare("test(old)$`p value` vs test_providers(fit)$table$p_value", old_test[["p value"]], tests$table$p_value)
compare("flags: test(old)$flag (factor) vs test_providers(fit)$table$flag",
        as.integer(as.character(old_test$flag)), tests$table$flag)
old_sm <- timed("SM_output(old) (threads = 2 by default)", SM_output(old))
compare("SM_output(old)$indirect.ratio vs standardize_providers(fit) ratio",
        old_sm$indirect.ratio, measures$table$estimate[measures$table$measure == "ratio"])
compare("SM_output(old)$indirect.rate vs standardize_providers(fit) rate",
        old_sm$indirect.rate, measures$table$estimate[measures$table$measure == "rate"])
old_gamma <- timed("confint(old, option = 'gamma') (exact)", confint(old, option = "gamma"))
effects_exact <- provider_effects(fit, interval = "exact")
compare("confint(old, option = 'gamma') limits vs provider_effects(fit, interval = 'exact')",
        c(old_gamma$gamma.lower, old_gamma$gamma.upper), c(effects_exact$table$lower, effects_exact$table$upper))
old_sm_ci <- timed("confint(old) (SM, exact, indirect, ratio and rate)", confint(old))
ratio_rows <- measures_exact$table$measure == "ratio"
compare("confint(old)$CI.indirect_ratio limits vs standardize_providers(fit, interval = 'exact')",
        c(old_sm_ci$CI.indirect_ratio$CI_ratio.lower, old_sm_ci$CI.indirect_ratio$CI_ratio.upper),
        c(measures_exact$table$lower[ratio_rows], measures_exact$table$upper[ratio_rows]))
old_summary <- timed("summary(old) (Wald)", summary(old))
new_summary <- summary(fit)
compare("summary(old) estimates and limits vs test_coefficients(fit)",
        c(old_summary$Estimate, old_summary$CI.Lower, old_summary$CI.Upper),
        c(test_coefficients(fit)$table$estimate, confint(fit)))
old_lr <- timed("summary(old, test = 'lr')", summary(old, test = "lr"))
compare("summary(old, test = 'lr')$stat vs test_coefficients(fit, 'lr', data =)$table$statistic",
        old_lr$stat, test_coefficients(fit, "lr", data = binary)$table$statistic)
old_plot <- timed("plot(old), drawn", draw(plot(old)))
timed("plot_funnel(funnel_limits(fit)), drawn", draw(plot_funnel(funnel_limits(fit))))
compare("funnel points: plot(old) layer 1 indicator vs funnel_limits(fit)$providers$estimate",
        sort(old_plot$layers[[1]]$data$indicator), sort(funnel_limits(fit)$providers$estimate))
old_cat <- timed("caterpillar_plot(confint(old)$CI.indirect_ratio), drawn",
                 draw(caterpillar_plot(old_sm_ci$CI.indirect_ratio)))
old_bar <- timed("bar_plot(test(old)), drawn", draw(bar_plot(old_test)))
timed("plot_flags(test_providers(fit)), drawn", draw(plot_flags(tests)))

section("linear_fe() against fit_linear_fe()")
lold <- timed("linear_fe(y ~ id(hospital) + z1 + ... + z5, data)",
              linear_fe(y ~ id(hospital) + z1 + z2 + z3 + z4 + z5, data = linear))
compare("coefficients", lold$coefficient$beta, coef(lfit))
lold_test <- test(lold)
ltests <- test_providers(lfit)
compare("test(): p-values", lold_test[["p value"]], ltests$table$p_value)
compare("test(): flags", as.integer(as.character(lold_test$flag)), ltests$table$flag)
lold_ci <- confint(lold)
lmeasures <- standardize_providers(lfit, interval = "wald")
compare("confint(old)$CI.indirect limits vs standardize_providers(fit, interval = 'wald')",
        c(lold_ci$CI.indirect$indirect.Lower, lold_ci$CI.indirect$indirect.Upper),
        c(lmeasures$table$lower, lmeasures$table$upper))

section("linear_re() against fit_linear_re()")
rold <- timed("linear_re(y ~ (1 | hospital) + z1 + ... + z5, data)",
              linear_re(y ~ (1 | hospital) + z1 + z2 + z3 + z4 + z5, data = linear))
compare("fixed effects: old$coefficient$FE vs coef(fit)", rold$coefficient$FE, coef(refit_linear))
compare("random effects: old$coefficient$RE vs provider_estimates(fit)", rold$coefficient$RE,
        provider_estimates(refit_linear))
compare("test(): p-values", test(rold)[["p value"]], test_providers(refit_linear)$table$p_value)
rold_sm <- SM_output(rold)
compare("SM_output(old)$indirect.difference vs standardize_providers(fit)", rold_sm$indirect.difference,
        standardize_providers(refit_linear)$table$estimate)

section("linear_cre() against fit_linear_cre()")
cold <- timed("linear_cre(data, Y.char, wb.char = c('z1', 'z2'), other.char, ProvID.char)",
              linear_cre(data = linear, Y.char = "y", wb.char = c("z1", "z2"), other.char = c("z3", "z4", "z5"),
                         ProvID.char = "hospital"))
compare("fixed effects (sorted; the term order may differ)", sort(cold$coefficient$FE), sort(coef(cre_linear)))
say("  names: old ", paste(rownames(cold$coefficient$FE), collapse = " "), "; new ",
    paste(names(coef(cre_linear)), collapse = " "))

section("logis_firth() against fit_logistic_firth()")
fold <- timed("logis_firth(y ~ id(hospital) + z1 + ... + z5, data, message = FALSE)",
              logis_firth(y ~ id(hospital) + z1 + z2 + z3 + z4 + z5, data = binary, message = FALSE))
compare("coefficients", fold$coefficient$beta, coef(firth))
compare("provider effects", fold$coefficient$gamma, provider_estimates(firth))
say("")
say("Part 2 total: ", sprintf("%.1f s", total))
writeLines(lines, out_file)
