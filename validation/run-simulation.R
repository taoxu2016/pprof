# Simulation study of the provider tests and intervals with known truth (ARCHITECTURE §G.5,
# DEC-053, Phase 5 plan step 4). For each family, data are simulated without provider
# effects and with six known outlying providers; the model is fit with its defaults, and the
# provider test, the provider-effect intervals, and the indirect measure intervals run at
# their default settings: the family's test (exact for logistic fixed effects, Wald
# otherwise), two-sided, level 0.95, the default null (the median provider effect for fixed
# effects, 0 for random effects), and intervals of the test's kind, as pprof 1.0.3's
# `confint()` computes them by default. The report gives
#
# - size: the share of the providers without an effect that are flagged;
# - power: the share of the outlying providers flagged in the direction of their effect;
# - coverage: the share of the intervals that contain the true provider effect or the true
#   indirect measure, for providers without and with an effect;
#
# each pooled over the replicates, with a Monte Carlo standard error that treats replicates
# as clusters (the providers of one fit share its estimates and null). The report is
# informational (DEC-053): it gates nothing, and a departure from nominal goes to the
# methodology owners as a question; nothing in the code changes because of it.
#
# True values. Every provider's outcome has linear predictor baseline + effect_i + z'beta.
# Fixed-effect models estimate gamma_i = baseline + effect_i, and their null is the median
# of the true gamma, the baseline, because most providers have no effect. Random-effect
# models estimate alpha_i = effect_i (the effects average 0), and their null is 0. Either
# way the true indirect measure compares the provider's expected outcome over its own
# patients with and without its effect: sum(expit(baseline + effect_i + z'beta)) /
# sum(expit(baseline + z'beta)) for logistic models (the ratio), and effect_i for linear
# models (the difference). The correlated random-effect models split x1 into its provider
# mean and the deviation from it; the simulation has no contextual effect, so their true
# values are those of the random-effect models.
#
# Usage, from the repository root:
#   Rscript validation/run-simulation.R [--replicates R] [--seed S] [--report FILE]
# Defaults: 200 replicates per family and scenario, seed 20261005, report
# validation/simulation-report.md.

opts <- list(replicates = 200L, seed = 20261005L, report = file.path("validation", "simulation-report.md"))
args <- commandArgs(trailingOnly = TRUE)
for (k in seq_len(length(args) %/% 2) * 2 - 1) {
  switch(args[[k]], "--replicates" = opts$replicates <- as.integer(args[[k + 1]]),
         "--seed" = opts$seed <- as.integer(args[[k + 1]]), "--report" = opts$report <- args[[k + 1]],
         stop("Unknown argument: ", args[[k]], call. = FALSE))
}
stopifnot(opts$replicates >= 2L, opts$replicates <= 5000L)
suppressMessages(devtools::load_all(quiet = TRUE))
withr::local_collate("C")

# --- Design --------------------------------------------------------------------------------------
design <- list(
  providers = 50L,
  outlier_effects = c(1, 1, 1, -1, -1, -1),
  beta = c(x1 = 0.5, x2 = -0.3, x3 = 0.2),
  logistic = list(sizes = 30:150, baseline = -1, effect = 0.8),
  linear = list(sizes = 10:60, baseline = 0, effect = 0.5, sigma = 1)
)
families <- c("logistic_fe", "linear_fe", "linear_re", "linear_cre", "logistic_re", "logistic_cre")
scenarios <- c(null = "no provider effects", outliers = "six outlying providers")

simulation_data <- function(family, scenario) {
  logistic <- startsWith(family, "logistic")
  setting <- if (logistic) design$logistic else design$linear
  m <- design$providers
  effects <- numeric(m)
  if (identical(scenario, "outliers")) effects[seq_along(design$outlier_effects)] <- design$outlier_effects * setting$effect
  provider <- rep(seq_len(m), sample(setting$sizes, m, replace = TRUE))
  n <- length(provider)
  x1 <- stats::rnorm(n) + stats::rnorm(m, 0, 0.5)[provider]
  x2 <- stats::rnorm(n)
  x3 <- stats::rbinom(n, 1, 0.4)
  fixed <- drop(cbind(x1, x2, x3) %*% design$beta)
  eta <- setting$baseline + effects[provider] + fixed
  y <- if (logistic) stats::rbinom(n, 1, stats::plogis(eta)) else eta + stats::rnorm(n, 0, setting$sigma)
  truth_measure <- if (logistic) {
    as.vector(tapply(stats::plogis(eta), provider, sum) / tapply(stats::plogis(setting$baseline + fixed), provider, sum))
  } else {
    effects
  }
  list(data = data.frame(y = y, hospital = provider, x1 = x1, x2 = x2, x3 = x3), effects = effects, logistic = logistic,
       truth_effect = if (endsWith(family, "_fe")) setting$baseline + effects else effects,
       truth_measure = truth_measure)
}

simulation_fit <- function(family, data) {
  formula <- y ~ x1 + x2 + x3
  switch(family,
    logistic_fe = fit_logistic_fe(formula, data, "hospital"),
    linear_fe = fit_linear_fe(formula, data, "hospital"),
    linear_re = fit_linear_re(formula, data, "hospital"),
    linear_cre = fit_linear_cre(formula, data, "hospital", within_between = "x1"),
    logistic_re = fit_logistic_re(formula, data, "hospital"),
    logistic_cre = fit_logistic_cre(formula, data, "hospital", within_between = "x1")
  )
}

# The counts of one replicate: providers without and with an effect, flags, and intervals
# that contain the truth (an interval with a missing limit counts as not computed).
simulation_replicate <- function(family, scenario) {
  sim <- simulation_data(family, scenario)
  fit <- tryCatch(suppressWarnings(suppressMessages(simulation_fit(family, sim$data))), error = identity)
  if (inherits(fit, "error")) return(c(error = 1))
  test <- profile_test_name(fit, NULL)
  ids <- as.character(seq_len(design$providers))
  row_of <- function(table) match(ids, as.character(table$provider_id))
  tests <- test_providers(fit)$table
  effects <- provider_effects(fit, interval = test)$table
  measures <- standardize_providers(fit, "indirect", measure = if (sim$logistic) "ratio" else "difference",
                                    interval = test)$table
  flag <- tests$flag[row_of(tests)]
  covered <- function(table, truth) {
    rows <- row_of(table)
    table$lower[rows] <= truth & truth <= table$upper[rows]
  }
  effect_covered <- covered(effects, sim$truth_effect)
  measure_covered <- covered(measures, sim$truth_measure)
  outlier <- sim$effects != 0
  direction <- sign(sim$effects)
  count <- function(x, rows) sum(x[rows], na.rm = TRUE)
  known <- function(x, rows) sum(!is.na(x[rows]))
  c(error = 0, singular = as.numeric(isTRUE(fit$convergence$singular)),
    null_tested = known(flag, !outlier), null_flagged = count(flag != 0, !outlier), null_missing = sum(is.na(flag[!outlier])),
    outlier_tested = known(flag, outlier), outlier_right = count(flag == direction, outlier),
    outlier_wrong = count(flag == -direction, outlier), outlier_missing = sum(is.na(flag[outlier])),
    effect_null_known = known(effect_covered, !outlier), effect_null_covered = count(effect_covered, !outlier),
    effect_outlier_known = known(effect_covered, outlier), effect_outlier_covered = count(effect_covered, outlier),
    measure_null_known = known(measure_covered, !outlier), measure_null_covered = count(measure_covered, !outlier),
    measure_outlier_known = known(measure_covered, outlier), measure_outlier_covered = count(measure_covered, outlier))
}

# A proportion pooled over replicates, with the Monte Carlo standard error of a ratio
# estimator over independent clusters (replicates).
cluster_rate <- function(hits, totals) {
  keep <- !is.na(totals) & totals > 0
  hits <- hits[keep]
  totals <- totals[keep]
  if (!length(totals)) return(c(rate = NA_real_, se = NA_real_))
  rate <- sum(hits) / sum(totals)
  r <- length(totals)
  se <- if (r > 1) sqrt(sum((hits - rate * totals)^2) / (r * (r - 1))) / mean(totals) else NA_real_
  c(rate = rate, se = se)
}

format_rate <- function(x) {
  if (is.na(x[["rate"]])) return("—")
  sprintf("%.1f (%.1f)", 100 * x[["rate"]], 100 * x[["se"]])
}

# --- Run -------------------------------------------------------------------------------------------
rows <- list()
started <- Sys.time()
for (f in seq_along(families)) {
  for (s in seq_along(scenarios)) {
    family <- families[[f]]
    scenario <- names(scenarios)[[s]]
    t0 <- Sys.time()
    counts <- lapply(seq_len(opts$replicates), function(r) {
      withr::with_seed(opts$seed + 10000L * (f - 1L) + 5000L * (s - 1L) + r, simulation_replicate(family, scenario))
    })
    errors <- sum(vapply(counts, function(x) x[["error"]], numeric(1)))
    counts <- do.call(rbind, Filter(function(x) x[["error"]] == 0, counts))
    column <- function(name) if (is.null(counts)) numeric(0) else counts[, name]
    rows[[length(rows) + 1L]] <- data.frame(
      family = family, scenario = scenarios[[s]], test = if (family == "logistic_fe") "exact" else "Wald",
      fits = opts$replicates - errors, errors = errors, singular = sum(column("singular")),
      size = format_rate(cluster_rate(column("null_flagged"), column("null_tested"))),
      power = if (scenario == "null") "—" else format_rate(cluster_rate(column("outlier_right"), column("outlier_tested"))),
      wrong = if (scenario == "null") "—" else as.character(sum(column("outlier_wrong"))),
      missing = as.character(sum(column("null_missing")) + sum(column("outlier_missing"))),
      effect_null = format_rate(cluster_rate(column("effect_null_covered"), column("effect_null_known"))),
      effect_outlier = if (scenario == "null") "—" else {
        format_rate(cluster_rate(column("effect_outlier_covered"), column("effect_outlier_known")))
      },
      measure_null = format_rate(cluster_rate(column("measure_null_covered"), column("measure_null_known"))),
      measure_outlier = if (scenario == "null") "—" else {
        format_rate(cluster_rate(column("measure_outlier_covered"), column("measure_outlier_known")))
      },
      seconds = as.numeric(difftime(Sys.time(), t0, units = "secs")), stringsAsFactors = FALSE
    )
    cat(sprintf("%s, %s: %d fits, %d errors, %.0f s\n", family, scenarios[[s]], opts$replicates - errors, errors,
                rows[[length(rows)]]$seconds))
  }
}
table <- do.call(rbind, rows)
total_seconds <- as.numeric(difftime(Sys.time(), started, units = "secs"))

# --- Report ----------------------------------------------------------------------------------------
versions <- vapply(c("lme4", "Matrix"), function(p) as.character(utils::packageVersion(p)), character(1))
lines <- c(
  "# Simulation report: provider tests and intervals with known truth", "",
  sprintf("Generated %s by `validation/run-simulation.R` on %s, %s; lme4 %s, Matrix %s.",
          format(Sys.time(), tz = "UTC", usetz = TRUE), R.version.string, utils::sessionInfo()$running,
          versions[["lme4"]], versions[["Matrix"]]),
  sprintf("Working tree at commit %s; %d replicates per family and scenario, seed %d; %.0f s.",
          system2("git", c("rev-parse", "--short", "HEAD"), stdout = TRUE), opts$replicates, opts$seed, total_seconds),
  "",
  "Informational (DEC-053): this report gates nothing. A departure from nominal is a question for the methodology",
  "owners; the procedures are those of pprof 1.0.3, and changing them would be Class B.",
  "", "## Design", "",
  sprintf("- %d providers. Logistic models: %d to %d patients per provider, baseline log-odds %g, outlying effects %+g",
          design$providers, min(design$logistic$sizes), max(design$logistic$sizes), design$logistic$baseline,
          design$logistic$effect),
  sprintf("  and %+g on the log-odds scale. Linear models: %d to %d patients per provider, baseline %g, residual", -design$logistic$effect,
          min(design$linear$sizes), max(design$linear$sizes), design$linear$baseline),
  sprintf("  standard deviation %g, outlying effects %+g and %+g.", design$linear$sigma, design$linear$effect,
          -design$linear$effect),
  sprintf("- Covariates: x1 = N(0, 1) plus a provider-level N(0, 0.25) shift, x2 = N(0, 1), x3 = Bernoulli(0.4);"),
  sprintf("  beta = (%s).", paste(sprintf("%g", design$beta), collapse = ", ")),
  "- Scenarios: no provider effects; six outlying providers (three above, three below), the others without an effect.",
  "- Each model is fit with its defaults (`fit_logistic_fe()`, `fit_linear_fe()`, `fit_linear_re()`,",
  "  `fit_linear_cre(within_between = \"x1\")`, `fit_logistic_re()`, `fit_logistic_cre(within_between = \"x1\")`),",
  "  then `test_providers()`, `provider_effects()`, and `standardize_providers(\"indirect\")` run at their defaults",
  "  (two-sided, level 0.95, the family's null) with intervals of the test's kind. True values: see the script's header.",
  "", "## Results", "",
  "Percentages with Monte Carlo standard errors in parentheses (replicates as clusters). Size: providers without an",
  "effect that are flagged. Power: outlying providers flagged in the direction of their effect; \"wrong\" counts those",
  "flagged in the other direction. Missing: providers whose test has no flag. Coverage: intervals that contain the",
  "true provider effect (\"effect\") or the true indirect measure (\"measure\"), for providers without (\"none\") and",
  "with (\"outlier\") an effect. Singular: lme4 fits on the boundary (provider variance 0).",
  "",
  paste("| Family | Scenario | Test | Fits | Errors | Singular | Size | Power | Wrong | Missing |",
        "Effect coverage, none | Effect coverage, outlier | Measure coverage, none | Measure coverage, outlier |"),
  "|---|---|---|---|---|---|---|---|---|---|---|---|---|---|",
  sprintf("| %s | %s | %s | %d | %d | %d | %s | %s | %s | %s | %s | %s | %s | %s |", table$family, table$scenario,
          table$test, table$fits, table$errors, table$singular, table$size, table$power, table$wrong, table$missing,
          table$effect_null, table$effect_outlier, table$measure_null, table$measure_outlier)
)
writeLines(lines, opts$report)
cat(sprintf("Wrote %s (%.0f s)\n", opts$report, total_seconds))
