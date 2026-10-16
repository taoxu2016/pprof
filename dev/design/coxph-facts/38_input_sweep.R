# CoxPH C6 plan, §2.4: invalid inputs to the Cox functions and their methods. For each call, the condition
# it raises: whether it is one of pprof's classed conditions or R's own ("RAW"), its class, and its
# message (the first 220 characters); or that the call returned, with any warnings.
# Run from the repository root:
#   Rscript dev/design/coxph-facts/38_input_sweep.R <output file>
# with an installed pprof from the library PPROF_FACTS_LIB when it is set, and devtools::load_all()
# otherwise. The penalized calls run when glmnet is installed.
out <- commandArgs(trailingOnly = TRUE)[[1]]
if (nzchar(Sys.getenv("PPROF_FACTS_LIB"))) {
  .libPaths(c(Sys.getenv("PPROF_FACTS_LIB"), .libPaths()))
  suppressPackageStartupMessages(library(pprof))
} else {
  suppressMessages(devtools::load_all(quiet = TRUE))
}
lung <- survival::lung
lung$id <- seq_len(nrow(lung))
mgus2 <- survival::mgus2
mgus2$etime <- with(mgus2, ifelse(pstat == 0, futime, ptime))
mgus2$event <- factor(with(mgus2, ifelse(pstat == 0, 2 * death, 1)), levels = 0:2,
                      labels = c("censored", "progression", "death"))
fit <- fit_cox_stratified(Surv(time, status) ~ age + sex, lung, provider = "inst")
fg <- fit_fine_gray(Surv(etime, event) ~ age + mspike, mgus2, provider = "sex", cause = "progression")
has_glmnet <- requireNamespace("glmnet", quietly = TRUE)
if (has_glmnet) pen <- fit_cox_penalized(Surv(time, status) ~ age + sex + ph.karno, lung, provider = "inst", n_lambda = 10)

calls <- alist(
  # fit_cox_stratified
  strat_formula_string = fit_cox_stratified("Surv(time, status) ~ age", lung, "inst"),
  strat_response_not_surv = fit_cox_stratified(time ~ age, lung, "inst"),
  strat_data_matrix = fit_cox_stratified(Surv(time, status) ~ age, as.matrix(lung), "inst"),
  strat_provider_missing = fit_cox_stratified(Surv(time, status) ~ age, lung, "nope"),
  strat_provider_two = fit_cox_stratified(Surv(time, status) ~ age, lung, c("inst", "sex")),
  strat_ties_bad = fit_cox_stratified(Surv(time, status) ~ age, lung, "inst", ties = "exact"),
  strat_robust_na = fit_cox_stratified(Surv(time, status) ~ age, lung, "inst", robust = NA),
  strat_weights_missing_col = fit_cox_stratified(Surv(time, status) ~ age, lung, "inst", weights = "w"),
  strat_weights_numeric = fit_cox_stratified(Surv(time, status) ~ age, lung, "inst", weights = rep(1, 228)),
  strat_cluster_missing_col = fit_cox_stratified(Surv(time, status) ~ age, lung, "inst", cluster = "patient"),
  strat_max_iter_zero = fit_cox_stratified(Surv(time, status) ~ age, lung, "inst", max_iter = 0),
  strat_max_iter_frac = fit_cox_stratified(Surv(time, status) ~ age, lung, "inst", max_iter = 2.5),
  strat_tol_negative = fit_cox_stratified(Surv(time, status) ~ age, lung, "inst", tol = -1),
  strat_keep_data_string = fit_cox_stratified(Surv(time, status) ~ age, lung, "inst", keep_data = "yes"),
  strat_verbose_two = fit_cox_stratified(Surv(time, status) ~ age, lung, "inst", verbose = c(TRUE, FALSE)),
  strat_strata_term = fit_cox_stratified(Surv(time, status) ~ age + strata(sex), lung, "inst"),
  strat_cluster_term = fit_cox_stratified(Surv(time, status) ~ age + cluster(id), lung, "inst"),
  strat_tt_term = fit_cox_stratified(Surv(time, status) ~ age + tt(age), lung, "inst"),
  strat_interval_censored = fit_cox_stratified(Surv(time, time + 1, status, type = "interval") ~ age, lung, "inst"),
  strat_left_censored = fit_cox_stratified(Surv(time, status, type = "left") ~ age, lung, "inst"),
  strat_no_rows = fit_cox_stratified(Surv(time, status) ~ age, lung[0, ], "inst"),
  # A response expression of fixed length, which no longer matches the rows once incomplete ones are dropped.
  strat_response_fixed_length = fit_cox_stratified(Surv(time, rep(1, 228)) ~ age, lung, "inst"),
  strat_unknown_argument = fit_cox_stratified(Surv(time, status) ~ age, lung, "inst", method = "efron"),
  # baseline_hazard and methods
  baseline_no_data = baseline_hazard(fit),
  baseline_wrong_data = baseline_hazard(fit, data = mgus2),
  predict_type_bad = predict(fit, type = "response"),
  predict_newdata_missing_cov = predict(fit, newdata = data.frame(age = 50)),
  predict_survival_no_data = predict(fit, newdata = lung[1:2, ], type = "survival"),
  residuals_type_bad = residuals(fit, type = "deviance"),
  residuals_score_no_data = residuals(fit, type = "score"),
  confint_level_bad = confint(fit, level = 2),
  test_coef_lr = test_coefficients(fit, test = "lr"),
  provider_effects_cox = provider_effects(fit),
  test_providers_wald = test_providers(fit, test = "wald"),
  test_providers_greater = test_providers(fit, alternative = "greater"),
  test_providers_level_bad = test_providers(fit, level = 1.5),
  test_providers_null_string = test_providers(fit, null = "median"),
  standardize_direct_interval = standardize_providers(fit, standardization = "direct", interval = "midp"),
  standardize_measure_rate = standardize_providers(fit, measure = "rate"),
  funnel_target_two = funnel_limits(fit, target = 2),
  profile_unknown_provider = profile_providers(fit, providers = 999),
  # check_data
  check_weights_missing_col = check_data(Surv(time, status) ~ age, lung, "inst", weights = "w"),
  check_factor_status = check_data(Surv(etime, event) ~ age, mgus2, "sex"),
  # fit_fine_gray
  fg_cause_missing = fit_fine_gray(Surv(etime, event) ~ age, mgus2, "sex"),
  fg_cause_censoring = fit_fine_gray(Surv(etime, event) ~ age, mgus2, "sex", cause = "censored"),
  fg_cause_unknown = fit_fine_gray(Surv(etime, event) ~ age, mgus2, "sex", cause = "relapse"),
  fg_cause_two = fit_fine_gray(Surv(etime, event) ~ age, mgus2, "sex", cause = c("progression", "death")),
  fg_status_numeric = fit_fine_gray(Surv(etime, as.integer(event) - 1L) ~ age, mgus2, "sex", cause = 1),
  fg_id_missing_col = fit_fine_gray(Surv(etime, event) ~ age, mgus2, "sex", cause = "progression", id = "subject"),
  fg_offset = fit_fine_gray(Surv(etime, event) ~ age + offset(mspike), mgus2, "sex", cause = "progression"),
  fg_ties_bad = fit_fine_gray(Surv(etime, event) ~ age, mgus2, "sex", cause = "progression", ties = "exact"),
  fg_predict_ci_no_data = predict(fg, newdata = mgus2[1:2, ], type = "cumulative_incidence"),
  fg_residuals = residuals(fg),
  fg_profile = profile_providers(fg),
  fg_baseline = baseline_hazard(fg)
)
if (has_glmnet) {
  calls <- c(calls, alist(
    pen_alpha_bad = fit_cox_penalized(Surv(time, status) ~ age + sex, lung, "inst", alpha = 2),
    pen_lambda_increasing = fit_cox_penalized(Surv(time, status) ~ age + sex, lung, "inst", lambda = c(0.01, 0.1)),
    pen_lambda_negative = fit_cox_penalized(Surv(time, status) ~ age + sex, lung, "inst", lambda = c(0.1, -1)),
    pen_n_lambda_one = fit_cox_penalized(Surv(time, status) ~ age + sex, lung, "inst", n_lambda = 1),
    pen_ratio_bad = fit_cox_penalized(Surv(time, status) ~ age + sex, lung, "inst", lambda_min_ratio = 1.5),
    pen_factor_unnamed = fit_cox_penalized(Surv(time, status) ~ age + sex, lung, "inst", penalty_factor = c(1, 0)),
    pen_factor_unknown = fit_cox_penalized(Surv(time, status) ~ age + sex, lung, "inst", penalty_factor = c(height = 0)),
    pen_factor_negative = fit_cox_penalized(Surv(time, status) ~ age + sex, lung, "inst", penalty_factor = c(age = -1)),
    pen_factor_all_zero = fit_cox_penalized(Surv(time, status) ~ age + sex, lung, "inst", penalty_factor = c(age = 0, sex = 0)),
    pen_no_covariates = fit_cox_penalized(Surv(time, status) ~ 1, lung, "inst"),
    pen_coef_off_grid = coef(pen, lambda = 0.123456),
    select_folds_short = select_lambda(pen, folds = 1:3, data = lung),
    select_n_folds_two = select_lambda(pen, n_folds = 2, data = lung),
    select_rule_bad = select_lambda(pen, rule = "max", data = lung),
    select_no_data = select_lambda(pen),
    pen_summary = summary(pen),
    pen_profile = test_providers(pen)
  ))
}
rows <- lapply(names(calls), function(name) {
  w <- character()
  result <- tryCatch(withCallingHandlers(eval(calls[[name]]), warning = function(cond) {
    w <<- c(w, sprintf("[%s] %s", class(cond)[[1]], conditionMessage(cond)))
    invokeRestart("muffleWarning")
  }), error = function(e) e)
  line <- if (inherits(result, "error")) {
    cls <- class(result)
    sprintf("%-32s %-6s %-40s %s", name, if (any(startsWith(cls, "pprof_"))) "pprof" else "RAW", cls[[1]],
            substr(gsub("[\r\n]+", " ", conditionMessage(result)), 1, 220))
  } else {
    sprintf("%-32s %-6s %-40s", name, "-", "returned")
  }
  c(line, if (length(w)) paste("    warning:", substr(gsub("[\r\n]+", " ", w), 1, 200)))
})
kinds <- vapply(rows, function(r) trimws(substr(r[[1]], 34, 39)), "")
writeLines(c(unlist(rows), "", sprintf("%d calls: %d raise pprof's classed conditions, %d R's own errors, %d return",
                                       length(rows), sum(kinds == "pprof"), sum(kinds == "RAW"), sum(kinds == "-"))), out)
