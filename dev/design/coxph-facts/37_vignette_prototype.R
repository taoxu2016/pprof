# CoxPH C6 plan, §2.2: the computations a vignette on time-to-event outcomes would show, timed step by
# step, on data derived from ExampleDataBinary: its 100 hospitals and its patients' five risk factors,
# with times in days simulated from a Cox model with hospital effects (a quarter of the patients entering
# late), a competing event (transplant), and recurrent hospitalizations as (start, stop] rows. Also: the
# fit against survival's coxph() with the package's settings and with coxph()'s defaults, the flags, the
# size of two plots as PNG files (6 by 4 inches at 96 dpi), and the Fine-Gray expansion's rows.
# Run from the repository root:
#   Rscript dev/design/coxph-facts/37_vignette_prototype.R <output file>
# with an installed pprof from the library PPROF_FACTS_LIB when it is set (the times in the output are
# those of a release build), and devtools::load_all() otherwise.
out_file <- commandArgs(trailingOnly = TRUE)[[1]]
if (nzchar(Sys.getenv("PPROF_FACTS_LIB"))) {
  .libPaths(c(Sys.getenv("PPROF_FACTS_LIB"), .libPaths()))
  suppressPackageStartupMessages(library(pprof))
} else {
  suppressMessages(devtools::load_all(quiet = TRUE))
}
timings <- list()
step <- function(name, expr) {
  t <- system.time(value <- force(expr))
  timings[[name]] <<- t[["elapsed"]]
  value
}
notes <- character()
note <- function(...) notes <<- c(notes, sprintf(...))

# --- Data: ExampleDataBinary's hospitals and risk factors, times in days ----------------------------
data(ExampleDataBinary)
data <- step("data", {
  set.seed(2026)
  patients <- data.frame(patient = seq_along(ExampleDataBinary$Y), hospital = ExampleDataBinary$ProvID,
                         ExampleDataBinary$Z)
  n <- nrow(patients)
  effect <- rnorm(100, 0, 0.2)[patients$hospital]
  eta <- with(patients, 0.4 * z1 - 0.3 * z2 + 0.2 * z3) + effect
  entry <- ifelse(runif(n) < 0.25, sample(1:180, n, replace = TRUE), 0L)
  end <- entry + sample(180:1095, n, replace = TRUE)
  death <- entry + ceiling(rexp(n, exp(eta) / 1500))
  transplant <- entry + ceiling(rexp(n, exp(-0.3 * patients$z1) / 2500))
  exit <- pmin(death, transplant, end)
  status <- ifelse(exit == end & end < pmin(death, transplant), "censored",
                   ifelse(death <= transplant, "death", "transplant"))
  patients$entry <- entry
  patients$exit <- exit
  patients$status <- factor(status, levels = c("censored", "death", "transplant"))
  patients$died <- as.integer(status == "death")
  patients
})
note("patients %d, deaths %d, transplants %d, late entries %d", nrow(data), sum(data$status == "death"),
     sum(data$status == "transplant"), sum(data$entry > 0))

# Recurrent hospitalizations: a Poisson process over each patient's follow-up, in days, at least a day
# apart, as (start, stop] rows that end at each hospitalization and at the end of follow-up.
recurrent <- step("recurrent data", {
  set.seed(2027)
  n <- nrow(data)
  rate <- exp(0.3 * data$z1 + 0.2 * data$z4) / 400
  days <- data$entry + t(apply(matrix(ceiling(rexp(n * 30, rate)), n), 1, cumsum))
  during <- days < data$exit
  patient <- c(row(days)[during], seq_len(n))
  stop <- c(days[during], data$exit)
  hospitalized <- c(rep(1L, sum(during)), rep(0L, n))
  order <- order(patient, stop)
  patient <- patient[order]
  stop <- stop[order]
  first <- !duplicated(patient)
  start <- c(NA, stop[-length(stop)])
  start[first] <- data$entry[patient[first]]
  data.frame(patient = patient, hospital = data$hospital[patient], z1 = data$z1[patient], z4 = data$z4[patient],
             start = start, stop = stop, hospitalized = hospitalized[order])
})
note("hospitalization rows %d, hospitalizations %d", nrow(recurrent), sum(recurrent$hospitalized))

# --- The stratified model, against coxph() ------------------------------------------------------------
step("check_data", check_data(Surv(entry, exit, died) ~ z1 + z2 + z3, data, provider = "hospital"))
fit <- step("fit", fit_cox_stratified(Surv(entry, exit, died) ~ z1 + z2 + z3, data, provider = "hospital"))
same <- step("coxph, the package's settings", survival::coxph(Surv(entry, exit, died) ~ z1 + z2 + z3 + strata(hospital),
                                                              data, ties = "breslow", timefix = FALSE))
note("coefficients identical() to coxph(ties = \"breslow\", timefix = FALSE): %s",
     identical(unname(coef(fit)), unname(coef(same))))
default <- step("coxph, its defaults", survival::coxph(Surv(entry, exit, died) ~ z1 + z2 + z3 + strata(hospital), data))
note("largest difference from coxph()'s defaults (Efron ties, timefix = TRUE): %.2g", max(abs(coef(fit) - coef(default))))
step("fit, robust", fit_cox_stratified(Surv(entry, exit, died) ~ z1 + z2 + z3, data, provider = "hospital",
                                       cluster = "patient"))
step("summary", summary(fit))

# --- Profiling ----------------------------------------------------------------------------------------
profile <- step("profile_providers, mid-p", profile_providers(fit, interval = "midp"))
flags <- table(factor(profile$tests$table$flag, levels = -1:1))
note("mid-p flags at level 0.95: %d lower, %d as expected, %d higher", flags[[1]], flags[[2]], flags[[3]])
step("test_providers, exact", test_providers(fit, test = "exact"))
step("standardize_providers, both", standardize_providers(fit, standardization = c("indirect", "direct")))
funnel <- step("funnel_limits, two levels", funnel_limits(fit, level = c(0.95, 0.998)))
draw <- function(plot) {
  file <- tempfile(fileext = ".png")
  grDevices::png(file, width = 6, height = 4, units = "in", res = 96)
  print(plot)
  grDevices::dev.off()
  file.size(file)
}
note("funnel plot %d bytes", step("plot_funnel", draw(plot_funnel(funnel))))
note("caterpillar plot %d bytes", step("plot_caterpillar", draw(plot_caterpillar(profile$measures, use_flag = TRUE))))

# --- Recurrent events, competing risks, and penalized paths -----------------------------------------------
shr <- step("fit, recurrent", fit_cox_stratified(Surv(start, stop, hospitalized) ~ z1 + z4, recurrent,
                                                 provider = "hospital", cluster = "patient"))
step("profile_providers, recurrent", profile_providers(shr, interval = "midp"))
step("cause-specific fit", fit_cox_stratified(Surv(entry, exit, status == "death") ~ z1 + z2 + z3, data,
                                              provider = "hospital"))
fine_gray <- step("fit_fine_gray", fit_fine_gray(Surv(entry, exit, status) ~ z1 + z2 + z3, data, provider = "hospital",
                                                 cause = "death", id = "patient"))
note("Fine-Gray expanded rows in the fit: %d", fine_gray$n_expanded)
step("cumulative incidence", predict(fine_gray, newdata = data.frame(z1 = c(-1, 1), z2 = 0, z3 = 0, hospital = 1),
                                     type = "cumulative_incidence", data = data))
if (requireNamespace("glmnet", quietly = TRUE)) {
  path <- step("fit_cox_penalized, 20 lambda values", fit_cox_penalized(Surv(entry, exit, died) ~ z1 + z2 + z3 + z4 + z5,
                                                                       data, provider = "hospital", n_lambda = 20))
  set.seed(1)
  selected <- step("select_lambda, 5 folds", select_lambda(path, n_folds = 5, data = data))
  note("selected lambda %.4g (rule 1se)", selected$selected$lambda)
}

writeLines(c(R.version.string, sprintf("survival %s, glmnet %s", packageVersion("survival"),
                                       if (requireNamespace("glmnet", quietly = TRUE)) packageVersion("glmnet") else "absent"),
             "", notes, "", "Elapsed seconds:",
             sprintf("  %-38s %6.2f", names(timings), unlist(timings)),
             sprintf("  %-38s %6.2f", "in all", sum(unlist(timings)))), out_file)
