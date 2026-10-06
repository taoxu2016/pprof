# Differential testing of the fitting functions and their methods against the reference
# (Phase 3 plan, "after the switch", for logistic fixed effects; Phase 4 plan, step 4, for the
# other fits; Phase 5 plan, step 4, for the methods of the other fits): seeded random datasets;
# on each, the functions and methods of pprof 1.0.3 run on the pinned reference library in a
# separate R session, as the fixture generator runs them, and on the working tree, through the
# same case runner; the results are compared with the tolerance tiers of the fixtures.
#
# - Binary datasets vary the number and sizes of providers (some below the screening cutoff),
#   the event rate, providers with no events or only events, and the number of covariates.
#   Each gets every logistic FE function and method, and logis_firth() with logistic FE
#   methods on its object; the first ones also get logis_re() and logis_cre() with their
#   methods.
# - Linear datasets vary the number and sizes of providers (some of 2 to 4 observations), the
#   number of covariates, and the noise; the first covariate varies between providers, and
#   about half of the datasets have missing outcomes, which the CRE fits drop after the
#   within-between decomposition (D-13). Each gets linear_fe() (both provider variances),
#   linear_re(), and linear_cre(), with their methods.
# - Datasets with character IDs (Phase 5) are drawn as above, with the providers labeled
#   "P1", "P2", ..., so that their order under the C collation ("P1", "P10", "P11", ..., "P2")
#   differs from the numeric order. The linear ones get the linear fits; the binary ones only
#   logis_re() and logis_cre(), because the logistic FE intervals misalign character IDs in
#   the reference (D-19), which the wrappers fix.
# - Datasets without provider effects (Phase 5) are drawn as above with every provider effect
#   0 (and no providers forced to have no events or only events), so that lme4 often
#   estimates the provider variance as 0; the RE and CRE tests then have missing flags
#   (dev/design/phase5-facts/09_singular_re_fits.R). They get the same fits as the datasets
#   with character IDs; the report says whether the lme4 fit of each is singular.
# - The methods of the linear FE, RE, and CRE fits run over the grid of ARCHITECTURE §G.2
#   (Phase 5): the three alternatives, level = 0.9, numeric nulls, parm, and the provider
#   effects and covariate summaries; for linear FE, null = "mean" and plot() as well, with
#   both provider variances.
# - The old plots (Phase 6): plot() of logis_fe fits with several alphas and a numeric null,
#   and caterpillar_plot() and bar_plot() on the confint() tables and test() results of every
#   fit with RE, CRE, or linear FE methods and of the logistic FE fits (two-sided and one-sided,
#   flagged and unflagged, both orientations, two group counts). For every plot, the built data
#   of each layer (ggplot_build()) are compared as well, which the fixtures do not record; the
#   bars of the horizontal caterpillar plots have a built width of errorbar_width where pprof
#   1.0.3's have 0.9 (Phase 8, DEC-075), which is checked instead.
#
# Usage, from the repository root:
#   Rscript validation/run-differential.R [--datasets N] [--mixed-datasets N] [--linear-datasets N]
#                                         [--character-datasets N] [--null-datasets N] [--seed S]
#                                         [--lib dev/reference/lib] [--report FILE]
# Defaults: 30 binary datasets (the first 10 with RE and CRE fits), 15 linear datasets, 3
# linear and 3 binary datasets with character IDs, 2 linear and 2 binary datasets without
# provider effects, seed 20261003, report validation/differential-report.md.
#
# Numeric provider IDs are doubles, character IDs are selected by character `parm`, and every
# fit has at least three covariates, so that no case hits a defect the wrappers fix (D-19,
# D-27, D-28, D-29, D-30); a mismatch is reported and makes the exit status 1.

opts <- list(datasets = 30L, mixed = 10L, linear = 15L, character = 3L, null = 2L, seed = 20261003L,
             lib = "dev/reference/lib", report = file.path("validation", "differential-report.md"))
args <- commandArgs(trailingOnly = TRUE)
for (k in seq_len(length(args) %/% 2) * 2 - 1) {
  switch(args[[k]], "--datasets" = opts$datasets <- as.integer(args[[k + 1]]),
         "--mixed-datasets" = opts$mixed <- as.integer(args[[k + 1]]),
         "--linear-datasets" = opts$linear <- as.integer(args[[k + 1]]),
         "--character-datasets" = opts$character <- as.integer(args[[k + 1]]),
         "--null-datasets" = opts$null <- as.integer(args[[k + 1]]),
         "--seed" = opts$seed <- as.integer(args[[k + 1]]), "--lib" = opts$lib <- args[[k + 1]],
         "--report" = opts$report <- args[[k + 1]], stop("Unknown argument: ", args[[k]], call. = FALSE))
}
stopifnot(requireNamespace("callr", quietly = TRUE))
ref_lib <- normalizePath(opts$lib, winslash = "/")
runner <- normalizePath(file.path("tests", "testthat", "helper-reference-cases.R"), winslash = "/")
suppressMessages(devtools::load_all(quiet = TRUE))
for (f in c("helper-reference-cases.R", "helper-tolerances.R", "helper-equivalence.R")) {
  source(file.path("tests", "testthat", f))
}
withr::local_collate("C")

# --- Datasets ------------------------------------------------------------------------------------
# With `effects = 0`, every provider effect is 0 and no provider is forced to have no events or
# only events; the random draws are the same, so `effects = 1` gives the datasets of Phase 4.
differential_dataset <- function(k, effects = 1) {
  withr::with_seed(opts$seed + k, {
    m <- sample(c(15L, 25L, 40L), 1L)
    sizes <- c(sample(5:9, 2L, replace = TRUE), sample(15:60, m - 2L, replace = TRUE))
    p <- sample(3:5, 1L)
    intercept <- sample(c(-3, -1, 1), 1L)
    prov <- rep(seq_len(m), sizes)
    z <- matrix(stats::rnorm(length(prov) * p), ncol = p, dimnames = list(NULL, paste0("x", seq_len(p))))
    gamma <- stats::rnorm(m, 0, 0.6) * effects
    beta <- stats::runif(p, -0.8, 0.8)
    y <- stats::rbinom(length(prov), 1, stats::plogis(intercept + gamma[prov] + drop(z %*% beta)))
    if (stats::runif(1) < 0.7 && effects != 0) y[prov == 3L] <- 0
    if (stats::runif(1) < 0.5 && effects != 0) y[prov == 4L] <- 1
    data.frame(Y = y, ProvID = as.numeric(prov), z)
  })
}
differential_linear_dataset <- function(k, effects = 1) {
  withr::with_seed(opts$seed + 500L + k, {
    m <- sample(c(15L, 25L, 40L), 1L)
    sizes <- c(sample(2:4, 2L, replace = TRUE), sample(10:60, m - 2L, replace = TRUE))
    p <- sample(3:5, 1L)
    prov <- rep(seq_len(m), sizes)
    z <- matrix(stats::rnorm(length(prov) * p), ncol = p, dimnames = list(NULL, paste0("x", seq_len(p))))
    z[, 1] <- z[, 1] + stats::rnorm(m)[prov]
    y <- 2 + effects * stats::rnorm(m)[prov] + drop(z %*% stats::runif(p, -1, 1)) +
      stats::rnorm(length(prov), 0, sample(c(0.5, 1, 2), 1L))
    if (stats::runif(1) < 0.5) y[sample(length(y), 5L)] <- NA
    data.frame(Y = y, ProvID = as.numeric(prov), z)
  })
}
differential_character_ids <- function(d) {
  d$ProvID <- paste0("P", d$ProvID)
  d
}
binary <- stats::setNames(lapply(seq_len(opts$datasets), differential_dataset),
                          sprintf("diff%02d", seq_len(opts$datasets)))
linear <- stats::setNames(lapply(seq_len(opts$linear), differential_linear_dataset),
                          sprintf("lin%02d", seq_len(opts$linear)))
k_character <- 100L + seq_len(opts$character)
binary_character <- stats::setNames(lapply(lapply(k_character, differential_dataset), differential_character_ids),
                                    sprintf("chr-diff%02d", seq_len(opts$character)))
linear_character <- stats::setNames(lapply(lapply(k_character, differential_linear_dataset),
                                           differential_character_ids),
                                    sprintf("chr-lin%02d", seq_len(opts$character)))
k_null <- 200L + seq_len(opts$null)
binary_null <- stats::setNames(lapply(k_null, differential_dataset, effects = 0),
                               sprintf("null-diff%02d", seq_len(opts$null)))
linear_null <- stats::setNames(lapply(k_null, differential_linear_dataset, effects = 0),
                               sprintf("null-lin%02d", seq_len(opts$null)))
datasets <- c(binary, linear, binary_character, linear_character, binary_null, linear_null)
mixed_names <- c(utils::head(names(binary), opts$mixed), names(binary_character), names(binary_null))
linear_names <- c(names(linear), names(linear_character), names(linear_null))

# The providers in places `k` of the provider order (under the C collation), for `parm`.
differential_parm <- function(d, k) sort(unique(d$ProvID))[k]

# --- Cases ---------------------------------------------------------------------------------------
differential_cases <- function() {
  cases <- list()
  add <- function(id, fun, args, tier, seed = NULL) {
    cases[[id]] <<- list(id = id, set = "differential", fun = fun, args = args, seed = seed, tier = tier, heavy = FALSE)
  }
  # caterpillar_plot() on the tables of a two-sided and a one-sided confint() case, flagged and
  # unflagged, in both orientations, and bar_plot() on a test() case with two group counts
  # (Phase 6).
  add_plots <- function(prefix, sm, sm_one_sided, tests, logistic, tier, tier_one_sided = tier) {
    tables <- if (logistic) c("CI.indirect_ratio", "CI.direct_rate") else c("CI.indirect", "CI.direct")
    add(paste0(prefix, "-caterpillar"), "caterpillar_plot", list(CI = ref_value(sm, tables[1])), tier)
    add(paste0(prefix, "-caterpillar-flags"), "caterpillar_plot",
        list(CI = ref_value(sm, tables[2]), use_flag = TRUE, orientation = "horizontal"), tier)
    add(paste0(prefix, "-caterpillar-one-sided"), "caterpillar_plot",
        list(CI = ref_value(sm_one_sided, tables[2]), use_flag = TRUE), tier_one_sided)
    add(paste0(prefix, "-bar"), "bar_plot", list(flag_df = ref_fit(tests)), tier)
    add(paste0(prefix, "-bar-3"), "bar_plot", list(flag_df = ref_fit(tests), group_num = 3), tier)
  }
  for (name in names(binary)) {
    d <- datasets[[name]]
    z <- grep("^x", names(d), value = TRUE)
    columns <- list(data = ref_dataset(name), Y.char = "Y", Z.char = z, ProvID.char = "ProvID", threads = 1)
    fit <- paste0(name, "-fit")
    add(fit, "logis_fe", columns, "iterative")
    add(paste0(name, "-fit-ban"), "logis_fe", c(columns, list(method = "BAN")), "iterative")
    add(paste0(name, "-fit-all"), "logis_fe", c(columns, list(stop = "all", tol = 1e-8)), "iterative")
    f <- ref_fit(fit)
    for (alternative in c("two.sided", "greater", "less")) {
      add(paste0(name, "-exact-", alternative), "test", list(fit = f, alternative = alternative, threads = 1),
          "iterative")
      add(paste0(name, "-score-", alternative), "test", list(fit = f, test = "score", alternative = alternative,
                                                             threads = 1), "iterative")
    }
    add(paste0(name, "-bootstrap"), "test", list(fit = f, test = "exact.bootstrap", n = 200, threads = 1), "iterative",
        seed = opts$seed + 1000L)
    add(paste0(name, "-score-standard"), "test", list(fit = f, test = "score", score_modified = FALSE, threads = 1),
        "iterative")
    add(paste0(name, "-wald"), "test", list(fit = f, test = "wald", null = 0, threads = 1), "iterative")
    add(paste0(name, "-exact-parm"), "test", list(fit = f, parm = c(3, 4, 10, 11), threads = 1), "iterative")
    add(paste0(name, "-sm"), "SM_output", list(fit = f, stdz = c("indirect", "direct"), threads = 1), "iterative")
    add(paste0(name, "-sm-null0"), "SM_output", list(fit = f, null = 0, threads = 1), "iterative")
    for (test in c("exact", "score", "wald")) {
      tier <- if (identical(test, "wald")) "iterative" else "root"
      add(paste0(name, "-gamma-", test), "confint", list(object = f, option = "gamma", test = test), tier)
      add(paste0(name, "-sm-", test), "confint", list(object = f, test = test, stdz = c("indirect", "direct")), tier)
    }
    add(paste0(name, "-sm-score-greater"), "confint", list(object = f, test = "score", stdz = c("indirect", "direct"),
                                                           alternative = "greater"), "root")
    add(paste0(name, "-sm-exact-less"), "confint", list(object = f, alternative = "less", level = 0.9), "root")
    for (test in c("wald", "lr", "score")) {
      add(paste0(name, "-summary-", test), "summary", list(object = f, test = test), "iterative")
    }
    add(paste0(name, "-plot"), "plot", list(x = f, alpha = c(0.05, 0.01)), "iterative")
    add(paste0(name, "-plot-null"), "plot", list(x = f, null = 0, alpha = c(0.1, 0.05, 0.01)), "iterative")
    # The old plots on the old outputs (Phase 6).
    add_plots(name, sm = paste0(name, "-sm-wald"), sm_one_sided = paste0(name, "-sm-score-greater"),
              tests = paste0(name, "-exact-two.sided"), logistic = TRUE, tier = "iterative", tier_one_sided = "root")
    # Firth, and logistic FE methods on its object (Phase 4).
    firth <- paste0(name, "-firth")
    add(firth, "logis_firth", columns, "iterative")
    add(paste0(firth, "-exact"), "test", list(fit = ref_fit(firth), threads = 1), "iterative")
    add(paste0(firth, "-sm"), "SM_output", list(fit = ref_fit(firth), stdz = c("indirect", "direct"), threads = 1),
        "iterative")
    add(paste0(firth, "-gamma-score"), "confint", list(object = ref_fit(firth), option = "gamma", test = "score"),
        "root")
  }
  # The grid of the RE and CRE methods on the fit `fit` (Phase 5): one-sided tests and intervals,
  # level = 0.9, a non-zero null, parm, the provider effects (option = "alpha", which the
  # reference rejects with a one-sided alternative), and covariate summaries with parm, which
  # selects the intercept as "(intercept)" (D-44).
  add_mixed_methods <- function(fit, parm, logistic) {
    f <- ref_fit(fit)
    measure <- if (logistic) list(measure = c("ratio", "rate"))
    for (alternative in c("greater", "less")) {
      add(paste0(fit, "-test-", alternative), "test", list(fit = f, alternative = alternative, level = 0.9), "lme4")
      add(paste0(fit, "-confint-", alternative), "confint",
          c(list(object = f, stdz = c("indirect", "direct"), alternative = alternative,
                 level = if (identical(alternative, "less")) 0.9 else 0.95), measure), "lme4")
    }
    add(paste0(fit, "-test-null-parm"), "test", list(fit = f, null = 0.1, parm = parm), "lme4")
    add(paste0(fit, "-sm-parm"), "SM_output",
        c(list(fit = f, stdz = c("indirect", "direct"), parm = parm), measure, if (logistic) list(threads = 1)), "lme4")
    add(paste0(fit, "-confint-level-parm"), "confint",
        c(list(object = f, stdz = c("indirect", "direct"), level = 0.9, parm = parm), measure), "lme4")
    add(paste0(fit, "-confint-alpha"), "confint", list(object = f, option = "alpha", level = 0.9, parm = parm), "lme4")
    add(paste0(fit, "-confint-alpha-greater"), "confint", list(object = f, option = "alpha", alternative = "greater"),
        "lme4")
    add(paste0(fit, "-summary-parm"), "summary",
        list(object = f, parm = c("(intercept)", "x2"), level = 0.9, null = 0.1), "lme4")
  }
  for (name in mixed_names) {
    z <- grep("^x", names(datasets[[name]]), value = TRUE)
    re <- paste0(name, "-logis-re")
    cre <- paste0(name, "-logis-cre")
    add(re, "logis_re", list(data = ref_dataset(name), Y.char = "Y", Z.char = z, ProvID.char = "ProvID"), "lme4")
    add(cre, "logis_cre", list(data = ref_dataset(name), Y.char = "Y", wb.char = "x1", other.char = z[-1],
                               ProvID.char = "ProvID"), "lme4")
    for (fit in c(re, cre)) {
      add(paste0(fit, "-test"), "test", list(fit = ref_fit(fit)), "lme4")
      add(paste0(fit, "-sm"), "SM_output",
          list(fit = ref_fit(fit), stdz = c("indirect", "direct"), measure = c("ratio", "rate"), threads = 1), "lme4")
      add(paste0(fit, "-confint"), "confint",
          list(object = ref_fit(fit), stdz = c("indirect", "direct"), measure = c("ratio", "rate")), "lme4")
      add(paste0(fit, "-summary"), "summary", list(object = ref_fit(fit)), "lme4")
      add_mixed_methods(fit, differential_parm(datasets[[name]], c(3, 4, 10, 11)), logistic = TRUE)
      add_plots(fit, sm = paste0(fit, "-confint"), sm_one_sided = paste0(fit, "-confint-less"),
                tests = paste0(fit, "-test"), logistic = TRUE, tier = "lme4")
    }
  }
  for (name in linear_names) {
    z <- grep("^x", names(datasets[[name]]), value = TRUE)
    columns <- list(data = ref_dataset(name), Y.char = "Y", Z.char = z, ProvID.char = "ProvID")
    parm <- differential_parm(datasets[[name]], c(1, 4, 10))
    fe <- paste0(name, "-fe")
    add(fe, "linear_fe", columns, "closed_form")
    add(paste0(fe, "-full"), "linear_fe", c(columns, list(option.gamma.var = "full")), "closed_form")
    # Both provider variances over the grid of the linear FE methods (Phase 5 for the full one).
    for (fit in c(fe, paste0(fe, "-full"))) {
      f <- ref_fit(fit)
      add(paste0(fit, "-test"), "test", list(fit = f), "closed_form")
      add(paste0(fit, "-sm"), "SM_output", list(fit = f, stdz = c("indirect", "direct")), "closed_form")
      add(paste0(fit, "-confint"), "confint", list(object = f, stdz = c("indirect", "direct")), "closed_form")
      add(paste0(fit, "-summary"), "summary", list(object = f), "closed_form")
      for (alternative in c("greater", "less")) {
        add(paste0(fit, "-test-", alternative), "test", list(fit = f, alternative = alternative, level = 0.9),
            "closed_form")
        add(paste0(fit, "-confint-", alternative), "confint",
            list(object = f, stdz = c("indirect", "direct"), alternative = alternative), "closed_form")
      }
      add(paste0(fit, "-test-mean-parm"), "test", list(fit = f, null = "mean", parm = parm), "closed_form")
      add(paste0(fit, "-test-null"), "test", list(fit = f, null = 0.1, level = 0.9), "closed_form")
      add(paste0(fit, "-sm-null-parm"), "SM_output",
          list(fit = f, stdz = c("indirect", "direct"), null = 0.1, parm = parm), "closed_form")
      add(paste0(fit, "-sm-mean"), "SM_output", list(fit = f, stdz = c("indirect", "direct"), null = "mean"),
          "closed_form")
      add(paste0(fit, "-confint-gamma"), "confint", list(object = f, option = "gamma", level = 0.9), "closed_form")
      add(paste0(fit, "-confint-mean-parm"), "confint",
          list(object = f, stdz = c("indirect", "direct"), null = "mean", level = 0.9, parm = parm), "closed_form")
      add(paste0(fit, "-confint-null-less"), "confint",
          list(object = f, stdz = c("indirect", "direct"), null = 0.1, alternative = "less", level = 0.9),
          "closed_form")
      add(paste0(fit, "-summary-parm"), "summary", list(object = f, parm = c("x2", "x1"), level = 0.9, null = 0.1),
          "closed_form")
      add(paste0(fit, "-plot"), "plot", list(x = f, alpha = c(0.05, 0.01)), "closed_form")
      add(paste0(fit, "-plot-mean"), "plot", list(x = f, null = "mean"), "closed_form")
      add(paste0(fit, "-plot-null"), "plot", list(x = f, null = 0.1, alpha = 0.1), "closed_form")
      add_plots(fit, sm = paste0(fit, "-confint"), sm_one_sided = paste0(fit, "-confint-greater"),
                tests = paste0(fit, "-test"), logistic = FALSE, tier = "closed_form")
    }
    re <- paste0(name, "-re")
    cre <- paste0(name, "-cre")
    add(re, "linear_re", columns, "lme4")
    add(cre, "linear_cre", list(data = ref_dataset(name), Y.char = "Y", wb.char = "x1", other.char = z[-1],
                                ProvID.char = "ProvID"), "lme4")
    for (fit in c(re, cre)) {
      add(paste0(fit, "-test"), "test", list(fit = ref_fit(fit)), "lme4")
      add(paste0(fit, "-sm"), "SM_output", list(fit = ref_fit(fit), stdz = c("indirect", "direct")), "lme4")
      add(paste0(fit, "-confint"), "confint", list(object = ref_fit(fit), stdz = c("indirect", "direct")), "lme4")
      add(paste0(fit, "-summary"), "summary", list(object = ref_fit(fit)), "lme4")
      add_mixed_methods(fit, parm, logistic = FALSE)
      add_plots(fit, sm = paste0(fit, "-confint"), sm_one_sided = paste0(fit, "-confint-less"),
                tests = paste0(fit, "-test"), logistic = FALSE, tier = "lme4")
    }
  }
  cases
}
cases <- differential_cases()

# --- The reference, in an isolated child session -----------------------------------------------------
started <- Sys.time()
# The built data of each layer of a plot (ggplot_build()), which the fixtures do not record;
# compared too (Phase 6).
built_data <- function(value) {
  if (!inherits(value, "ggplot")) return(NULL)
  built <- tryCatch(suppressMessages(suppressWarnings(ggplot2::ggplot_build(value))), error = function(e) NULL)
  if (is.null(built)) return("build error")
  lapply(built$data, as.data.frame)
}
reference <- callr::r(function(cases, datasets, runner, ref_lib, built_data) {
  Sys.setlocale("LC_COLLATE", "C")
  suppressPackageStartupMessages(library(pprof))
  if (!startsWith(normalizePath(find.package("pprof"), winslash = "/"), ref_lib)) stop("pprof is not the reference")
  source(runner, local = TRUE)
  results <- list()
  records <- list()
  for (id in names(cases)) {
    results[[id]] <- run_reference_case(cases[[id]], datasets, results)
    records[[id]] <- reference_result_record(results[[id]], 5000L)
    records[[id]]$built <- built_data(results[[id]]$raw_value)
  }
  records
}, args = list(cases = cases, datasets = datasets, runner = runner, ref_lib = ref_lib, built_data = built_data),
libpath = ref_lib,
env = c(callr::rcmd_safe_env(), LC_COLLATE = "C", OMP_THREAD_LIMIT = "1", OMP_NUM_THREADS = "1"),
user_profile = FALSE, system_profile = FALSE, show = FALSE)
reference_seconds <- as.numeric(difftime(Sys.time(), started, units = "secs"))

# --- The working tree, and the comparison ---------------------------------------------------------------
started <- Sys.time()
results <- list()
rows <- list()
for (id in names(cases)) {
  case <- cases[[id]]
  results[[id]] <- run_reference_case(case, datasets, results)
  actual <- reference_result_record(results[[id]], 5000L)
  actual$built <- built_data(results[[id]]$raw_value)
  expected <- reference[[id]]
  # DEC-075: the horizontal caterpillar plot draws its bars with geom_errorbar(orientation = "y"),
  # whose built `width` column holds errorbar_width where pprof 1.0.3's geom_errorbarh() left
  # ggplot2's 0.9; the ends of the bars are the same. The column must hold errorbar_width, and
  # the rest of the built data is compared with the reference's.
  width_accepted <- FALSE
  if (identical(case$fun, "caterpillar_plot") && identical(case$args$orientation, "horizontal") &&
      is.list(actual$built) && is.list(expected$built) && length(actual$built) && length(expected$built)) {
    errorbar_width <- if (is.null(case$args$errorbar_width)) 0 else case$args$errorbar_width
    width_accepted <- isTRUE(all(actual$built[[1]]$width == errorbar_width))
    if (width_accepted) expected$built[[1]]$width <- actual$built[[1]]$width
  }
  status <- "match"
  detail <- ""
  if (!identical(actual$outcome, expected$outcome)) {
    status <- "MISMATCH"
    detail <- sprintf("outcome %s, reference %s%s", actual$outcome, expected$outcome,
                      if (!is.null(expected$error)) paste0(" (", expected$error$message, ")") else "")
  } else if (identical(expected$outcome, "value")) {
    if (!is.na(expected$iterations) && !identical(actual$iterations, expected$iterations)) {
      status <- "MISMATCH"
      detail <- sprintf("%s iterations, reference %s", actual$iterations, expected$iterations)
    }
    level <- if (!is.null(case$args$level)) case$args$level else 0.95
    diffs <- reference_compare(actual$value, expected$value, reference_tolerance(case$tier), alpha = 1 - level)
    if (!is.null(expected$built) || !is.null(actual$built)) {
      diffs <- rbind(diffs, reference_compare(actual$built, expected$built, reference_tolerance(case$tier), "built"))
    }
    failures <- if (!is.null(diffs)) diffs[diffs$kind != "flag_boundary", , drop = FALSE] else NULL
    if (!is.null(failures) && nrow(failures)) {
      status <- "MISMATCH"
      detail <- paste(sprintf("%s [%s] %s", failures$path, failures$kind, failures$detail), collapse = "; ")
    } else if (!is.null(diffs) && nrow(diffs)) {
      detail <- sprintf("%d flag(s) within tolerance of a threshold", nrow(diffs))
    }
    if (identical(status, "match")) {
      if (identical(actual$value, expected$value) && identical(actual$built, expected$built)) {
        detail <- "identical"
      } else if (!nzchar(detail)) {
        # Within tolerance but not bitwise: name the elements that differ.
        exact <- reference_compare(actual$value, expected$value, reference_tolerance("exact"))
        detail <- paste("within tolerance:", paste(unique(exact$path), collapse = ", "))
      }
    }
    if (width_accepted) {
      detail <- paste0("the bars' built width is errorbar_width (DEC-075); otherwise ", detail)
    }
  }
  rows[[id]] <- data.frame(id = id, fun = case$fun, tier = case$tier, outcome = expected$outcome, status = status,
                           detail = substr(detail, 1, 300), stringsAsFactors = FALSE)
}
working_seconds <- as.numeric(difftime(Sys.time(), started, units = "secs"))
table <- do.call(rbind, rows)

shapes <- vapply(names(datasets), function(name) {
  d <- datasets[[name]]
  sizes <- table(d$ProvID)
  p <- sum(startsWith(names(d), "x"))
  ids <- if (is.character(d$ProvID)) ", character IDs" else ""
  if (name %in% c(names(binary_null), names(linear_null))) {
    formula <- stats::reformulate(c(grep("^x", names(d), value = TRUE), "(1 | ProvID)"), "Y")
    fit <- suppressMessages(if (name %in% linear_names) lme4::lmer(formula, d) else {
      lme4::glmer(formula, d, family = stats::binomial())
    })
    ids <- sprintf("%s, no provider effects (the lme4 RE fit is %s)", ids,
                   if (lme4::isSingular(fit)) "singular" else "not singular")
  }
  if (name %in% linear_names) {
    return(sprintf("linear, n %d, m %d (%d below 5), p %d, %d missing outcomes%s", nrow(d), length(sizes),
                   sum(sizes < 5), p, sum(is.na(d$Y)), ids))
  }
  fits <- if (name %in% c(names(binary_character), names(binary_null))) {
    ", RE and CRE fits only"
  } else if (name %in% mixed_names) {
    ", with RE and CRE fits"
  } else {
    ""
  }
  sprintf("n %d, m %d (%d below 10), p %d, event rate %.2f%s%s", nrow(d), length(sizes), sum(sizes < 10), p,
          mean(d$Y), ids, fits)
}, character(1))
lines <- c(
  "# Differential report: working tree versus the pprof 1.0.3 reference", "",
  sprintf("Generated %s by `validation/run-differential.R` on %s, %s.", format(Sys.time(), tz = "UTC", usetz = TRUE),
          R.version.string, utils::sessionInfo()$running),
  sprintf(paste("Working tree at commit %s; %d binary datasets (%d with RE and CRE fits), %d linear datasets,",
                "%d binary (RE and CRE fits only) and %d linear datasets with character IDs, and %d binary",
                "(RE and CRE fits only) and %d linear datasets without provider effects; seed %d."),
          system2("git", c("rev-parse", "--short", "HEAD"), stdout = TRUE), opts$datasets,
          min(opts$mixed, opts$datasets), opts$linear, opts$character, opts$character, opts$null, opts$null,
          opts$seed),
  "", "## Summary", "",
  sprintf("- Cases: %d; matching: %d; identical: %d; mismatching: %d.", nrow(table), sum(table$status == "match"),
          sum(table$detail == "identical"), sum(table$status == "MISMATCH")),
  sprintf(paste("- Horizontal caterpillar plots whose bars' built width is errorbar_width, where pprof 1.0.3's",
                "is 0.9, with the rest of the built data compared (DEC-075): %d."),
          sum(startsWith(table$detail, "the bars' built width is errorbar_width (DEC-075)"))),
  sprintf("- Reference errors reproduced: %d.", sum(table$outcome == "error" & table$status == "match")),
  sprintf("- Time: reference %.0f s, working tree %.0f s.", reference_seconds, working_seconds),
  "", "## Datasets", "", sprintf("- `%s`: %s", names(shapes), shapes),
  "", "## Cases", "", "| Case | Function | Tier | Reference outcome | Status | Detail |", "|---|---|---|---|---|---|",
  sprintf("| `%s` | %s | %s | %s | %s | %s |", table$id, table$fun, table$tier, table$outcome, table$status,
          gsub("|", "\\|", table$detail, fixed = TRUE))
)
writeLines(lines, opts$report)
cat(sprintf("Wrote %s: %d cases, %d matching (%d identical), %d mismatching\n", opts$report, nrow(table),
            sum(table$status == "match"), sum(table$detail == "identical"), sum(table$status == "MISMATCH")))
if (any(table$status == "MISMATCH")) quit(status = 1L)
