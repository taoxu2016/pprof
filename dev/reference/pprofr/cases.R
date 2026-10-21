# The cases of the pprofR fixtures (LOGISTIC_L1_PLAN §2; DEC-157): what pprofR 0.2.0 (commit f23c288)
# computes on each synthetic data set of datasets.R.
#
# Sourced by generate.R's child session, whose library path holds only pprofR and its dependencies and
# base R; base R and pprofR only. pprofr_run_case() returns a case's fixture: its data and a named
# list of records, one per call, each with the call's text, its seed when it draws random numbers, and
# its value or error, with its warnings and messages. Values are as pprofR returns them (data frames,
# matrices, lists), except fits, which become lists of their components (pprofr_fit_value()).

pprofr_case_ids <- c("binary-moderate", "binomial-moderate", "binomial-many-trials", "few-clusters",
                     "extreme-probabilities", "extreme-providers", "zero-trials", "standard-population",
                     "measure-tests", "supplied-effects", "cluster-order")

pprofr_alternatives <- c("two.sided", "greater", "less")
pprofr_covariates <- c("x1", "x2", "x3")
pprofr_both <- c("indirect", "direct")
pprofr_measures <- c("rate", "ratio")

# A call's text, with the values of the variables it reads that are short atomic vectors (a loop's
# test, alternative, tolerance, or null), at full precision; objects such as fits stay names.
pprofr_call_text <- function(expr, env) {
  values <- list()
  for (v in all.vars(expr)) {
    if (exists(v, envir = env, inherits = TRUE)) {
      x <- get(v, envir = env, inherits = TRUE)
      if (is.atomic(x) && length(x) <= 3L && is.null(dim(x))) values[[v]] <- x
    }
  }
  text <- deparse(do.call(substitute, list(expr, values)), width.cutoff = 500L,
                  control = c("keepInteger", "niceNames", "digits17"))
  paste(text, collapse = " ")
}

# One call, recorded. `expr` is evaluated after set.seed(seed) when a seed is given.
pprofr_record <- function(expr, seed = NULL, value = identity) {
  call_text <- pprofr_call_text(substitute(expr), parent.frame())
  caught <- new.env()
  caught$warnings <- character()
  caught$messages <- character()
  on_warning <- function(w) {
    caught$warnings <- c(caught$warnings, conditionMessage(w))
    invokeRestart("muffleWarning")
  }
  on_message <- function(m) {
    caught$messages <- c(caught$messages, conditionMessage(m))
    invokeRestart("muffleMessage")
  }
  if (!is.null(seed)) set.seed(seed)
  result <- tryCatch(list(value = withCallingHandlers(expr, warning = on_warning, message = on_message), error = NULL),
                     error = function(e) list(value = NULL, error = conditionMessage(e)))
  list(call = call_text, seed = seed, value = if (is.null(result$error)) value(result$value) else NULL,
       error = result$error, warnings = caught$warnings, messages = caught$messages)
}

# A collector of records, in order: add() stores one under `prefix`/name, add_all() appends a list.
pprofr_collector <- function(prefix = NULL) {
  store <- new.env()
  store$records <- list()
  list(
    add = function(name, record) {
      store$records[[if (is.null(prefix)) name else paste0(prefix, "/", name)]] <- record
      invisible()
    },
    add_all = function(records) {
      store$records <- c(store$records, records)
      invisible()
    },
    records = function() store$records
  )
}

# A fit's components; `rows = FALSE` leaves out those with one element per observation.
pprofr_fit_value <- function(fit, rows = TRUE) {
  keep <- c("beta", "gamma", "neg2Loglkd", "AIC", "BIC", "AUC", "df.prov", "char_list", "control",
            if (rows) c("linear_pred", "pred", "obs", "prov"))
  unclass(fit)[intersect(keep, names(fit))]
}
pprofr_fit_summary <- function(fit) pprofr_fit_value(fit, rows = FALSE)

# pprofR's data preparation, without its checks (data_check() is recorded on its own) or messages.
pprofr_prep <- function(d, binomial, clustered, cutoff = 10) {
  arguments <- list(Y = d["y"], Z = d[pprofr_covariates], ProvID = d["provider"], cutoff = cutoff, check = FALSE,
                    message = FALSE)
  if (binomial) arguments$N <- d$n
  if (clustered) arguments$PatientID <- d["cluster"]
  do.call(pprofR::fe_data_prep, arguments)
}

# The fit's data preparation, recorded: the prepared rows (in pprofR's order, with the inclusion and
# indicator columns) and the column names.
pprofr_prep_record <- function(d, binomial, clustered, cutoff = 10) {
  record <- pprofr_record(pprofr_prep(d, binomial, clustered, cutoff), value = unclass)
  record$call <- sprintf("fe_data_prep(%s, Y, Z = %s, ProvID%s, cutoff = %s, check = FALSE, message = FALSE)",
                         if (binomial) "N" else "N missing", paste(pprofr_covariates, collapse = " + "),
                         if (clustered) ", PatientID" else "", cutoff)
  record
}

# The stopping rules, methods, and tolerances of the fits' grid (design §G.1, case 1).
pprofr_fit_grid <- function(prep, prefix) {
  collect <- pprofr_collector(prefix)
  for (algorithm in c("SerBIN", "BAN")) {
    for (stop_rule in c("or", "beta")) {
      for (tol in c(1e-5, 1e-10)) {
        collect$add(sprintf("fit/%s/%s/%g", algorithm, stop_rule, tol),
                    pprofr_record(pprofR::logis_fe(prep, algorithm = algorithm, tol = tol, stop = stop_rule,
                                                   threads = 1), value = pprofr_fit_summary))
      }
    }
  }
  collect$records()
}

# The fit at pprofR's defaults (SerBIN, "beta", tol 1e-5), with the AUC; returns the record and the fit.
pprofr_default_fit <- function(prep, prefix) {
  fit <- NULL
  record <- pprofr_record(fit <- pprofR::logis_fe(prep, threads = 1, AUC = TRUE), value = pprofr_fit_value)
  record$call <- "logis_fe(prep, threads = 1, AUC = TRUE)"
  list(records = stats::setNames(list(record), paste0(prefix, "/fit/default")), fit = fit)
}

# Seeds of the bootstrap: one per call, from a case's base seed.
pprofr_seed <- function(base, k) as.integer(base + k)

# The provider tests, intervals, measures, and covariate tests of a fit without clusters.
pprofr_profile <- function(fit, prefix, seed_base, tests = c("exact.poisbinom", "exact.bootstrap", "score", "wald"),
                           alternatives = pprofr_alternatives, intervals = c("exact", "score", "wald"),
                           covariate_tests = c("wald", "lr", "score"), n_resamples = 10000,
                           interval_alternatives = alternatives, n_pop_interval = TRUE) {
  collect <- pprofr_collector(prefix)
  add <- collect$add
  k <- 0L
  add("vcov", pprofr_record(stats::vcov(fit)))
  for (test in tests) {
    for (alternative in alternatives) {
      seed <- if (test == "exact.bootstrap") pprofr_seed(seed_base, k <- k + 1L) else NULL
      add(sprintf("test/%s/median/%s", test, alternative),
          pprofr_record(pprofR::test_fe(fit, test = test, null = "median", alternative = alternative,
                                        n = n_resamples, threads = 1), seed = seed))
    }
  }
  for (test in intersect(c("exact.poisbinom", "score", "wald"), tests)) {
    add(sprintf("test/%s/0/two.sided", test), pprofr_record(pprofR::test_fe(fit, test = test, null = 0, threads = 1)))
  }
  if ("exact.poisbinom" %in% tests) {
    add("test/exact.poisbinom/median/two.sided/level-0.9",
        pprofr_record(pprofR::test_fe(fit, test = "exact.poisbinom", level = 0.9, threads = 1)))
  }
  for (test in intervals) {
    add(sprintf("confint/gamma/%s", test), pprofr_record(stats::confint(fit, option = "gamma", test = test)))
  }
  for (test in intervals) {
    for (alternative in interval_alternatives) {
      add(sprintf("confint/SM/%s/%s", test, alternative),
          pprofr_record(stats::confint(fit, option = "SM", test = test, stdz = pprofr_both, measure = pprofr_measures,
                                       alternative = alternative)))
    }
  }
  standardized <- pprofr_record(pprofR::SR_output(fit, stdz = pprofr_both, measure = pprofr_measures, null = "median",
                                                  threads = 1, se = TRUE))
  add("sr/median", standardized)
  n_pop <- 2 * standardized$value$N_pop
  add("sr/median/N_pop", pprofr_record(pprofR::SR_output(fit, stdz = pprofr_both, measure = pprofr_measures,
                                                         null = "median", threads = 1, se = TRUE, N_pop = n_pop)))
  add("sr/-0.5", pprofr_record(pprofR::SR_output(fit, stdz = pprofr_both, measure = pprofr_measures, null = -0.5,
                                                 threads = 1, se = TRUE)))
  if ("exact" %in% intervals && n_pop_interval) {
    add("confint/SM/exact/two.sided/N_pop",
        pprofr_record(stats::confint(fit, option = "SM", test = "exact", stdz = pprofr_both, measure = pprofr_measures,
                                     N_pop = n_pop)))
  }
  for (test in covariate_tests) {
    add(sprintf("covar/%s", test), pprofr_record(pprofR::summary_fe_covar(fit, test = test)))
  }
  collect$records()
}

# The tests, intervals, measures, and covariate tests of a fit with clusters.
pprofr_profile_clustered <- function(fit, prefix, alternatives = pprofr_alternatives) {
  collect <- pprofr_collector(prefix)
  add <- collect$add
  add("vcov", pprofr_record(stats::vcov(fit)))
  for (test in c("robust_wald", "stabilized_wald", "robust_score", "stabilized_score", "wald", "score")) {
    for (alternative in alternatives) {
      add(sprintf("test/%s/median/%s", test, alternative),
          pprofr_record(pprofR::test_fe(fit, test = test, null = "median", alternative = alternative, threads = 1)))
    }
  }
  for (test in c("robust_wald", "stabilized_wald")) {
    add(sprintf("test/%s/0/two.sided", test), pprofr_record(pprofR::test_fe(fit, test = test, null = 0, threads = 1)))
  }
  for (test in c("robust_wald", "wald")) {
    add(sprintf("confint/gamma/%s", test), pprofr_record(stats::confint(fit, option = "gamma", test = test)))
  }
  for (alternative in alternatives) {
    add(sprintf("confint/SM/robust_wald/%s", alternative),
        pprofr_record(stats::confint(fit, option = "SM", test = "robust_wald", stdz = pprofr_both,
                                     measure = pprofr_measures, alternative = alternative)))
  }
  add("sr/median", pprofr_record(pprofR::SR_output(fit, stdz = pprofr_both, measure = pprofr_measures,
                                                   null = "median", threads = 1, se = TRUE)))
  for (test in c("robust_wald", "wald")) {
    add(sprintf("covar/%s", test), pprofr_record(pprofR::summary_fe_covar(fit, test = test)))
  }
  collect$records()
}

# A tight fit (SerBIN, "beta", tol 1e-13), its variances, and its covariate tests.
pprofr_tight <- function(prep, prefix, covariate_tests) {
  collect <- pprofr_collector(prefix)
  fit <- NULL
  record <- pprofr_record(fit <- pprofR::logis_fe(prep, tol = 1e-13, stop = "beta", threads = 1),
                          value = pprofr_fit_summary)
  record$call <- "logis_fe(prep, tol = 1e-13, stop = \"beta\", threads = 1)"
  collect$add("fit", record)
  collect$add("vcov", pprofr_record(stats::vcov(fit)))
  for (test in covariate_tests) {
    collect$add(sprintf("covar/%s", test), pprofr_record(pprofR::summary_fe_covar(fit, test = test)))
  }
  collect$records()
}

# The negative controls' results (the brief's §3.5): what each control's comparison needs.
pprofr_control_unclustered <- function(fit, prefix) {
  collect <- pprofr_collector(prefix)
  add <- collect$add
  add("vcov", pprofr_record(stats::vcov(fit)))
  for (test in c("exact.poisbinom", "score", "wald")) {
    add(sprintf("test/%s/median/two.sided", test), pprofr_record(pprofR::test_fe(fit, test = test, threads = 1)))
  }
  for (test in c("exact", "score", "wald")) {
    add(sprintf("confint/gamma/%s", test), pprofr_record(stats::confint(fit, option = "gamma", test = test)))
  }
  add("confint/SM/exact/two.sided",
      pprofr_record(stats::confint(fit, option = "SM", test = "exact", stdz = pprofr_both, measure = pprofr_measures)))
  add("sr/median", pprofr_record(pprofR::SR_output(fit, stdz = pprofr_both, measure = pprofr_measures,
                                                   null = "median", threads = 1, se = TRUE)))
  add("covar/wald", pprofr_record(pprofR::summary_fe_covar(fit, test = "wald")))
  collect$records()
}

pprofr_control_clustered <- function(fit, prefix) {
  collect <- pprofr_collector(prefix)
  add <- collect$add
  for (test in c("robust_wald", "stabilized_wald", "robust_score", "stabilized_score")) {
    add(sprintf("test/%s/median/two.sided", test), pprofr_record(pprofR::test_fe(fit, test = test, threads = 1)))
  }
  add("confint/gamma/robust_wald", pprofr_record(stats::confint(fit, option = "gamma", test = "robust_wald")))
  add("covar/robust_wald", pprofr_record(pprofR::summary_fe_covar(fit, test = "robust_wald")))
  collect$records()
}

# The null shifted by 1e-9 from the median of the effects.
pprofr_control_null <- function(fit, prefix, clustered = FALSE) {
  shifted <- stats::median(fit$gamma) + 1e-9
  collect <- pprofr_collector(prefix)
  add <- collect$add
  tests <- if (clustered) {
    c("robust_wald", "stabilized_wald", "robust_score", "stabilized_score")
  } else {
    c("exact.poisbinom", "score", "wald")
  }
  for (test in tests) {
    add(sprintf("test/%s/shifted/two.sided", test),
        pprofr_record(pprofR::test_fe(fit, test = test, null = shifted, threads = 1)))
  }
  if (!clustered) {
    add("sr/shifted", pprofr_record(pprofR::SR_output(fit, stdz = pprofr_both, measure = pprofr_measures,
                                                      null = shifted, threads = 1, se = TRUE)))
    add("confint/SM/exact/two.sided/shifted",
        pprofr_record(stats::confint(fit, option = "SM", test = "exact", stdz = "indirect", measure = pprofr_measures,
                                     null = shifted)))
  }
  collect$records()
}

# One of the moderate cases: the fits' grid, the default fit's profile, the clustered fit's, the data
# checks, the tight fits, and the negative controls.
pprofr_moderate_case <- function(datasets, kind, seed_base) {
  binomial <- kind == "binomial"
  d <- datasets[[paste0(kind, "-moderate")]]
  collect <- pprofr_collector()
  add_all <- collect$add_all
  add_all(list(prep = pprofr_prep_record(d, binomial, clustered = FALSE)))
  prep <- pprofr_prep(d, binomial, clustered = FALSE)
  add_all(pprofr_fit_grid(prep, "unclustered"))
  default <- pprofr_default_fit(prep, "unclustered")
  add_all(default$records)
  add_all(pprofr_profile(default$fit, "unclustered", seed_base))
  add_all(list(data_check = pprofr_record(pprofR::data_check(Y = d$y, Z = d[pprofr_covariates], ProvID = d$provider,
                                                             N = if (binomial) d$n else NULL))))
  # With the clusters: screening by clusters, the robust and stabilized inference.
  add_all(list(`clustered/prep` = pprofr_prep_record(d, binomial, clustered = TRUE)))
  prep_clustered <- pprofr_prep(d, binomial, clustered = TRUE)
  clustered <- pprofr_default_fit(prep_clustered, "clustered")
  add_all(clustered$records)
  add_all(pprofr_profile_clustered(clustered$fit, "clustered"))
  # Tight fits, for the comparisons with glm() and sandwich::vcovCL() at the maximum likelihood estimates.
  add_all(pprofr_tight(prep, "unclustered/tight", covariate_tests = "wald"))
  add_all(pprofr_tight(prep_clustered, "clustered/tight", covariate_tests = c("wald", "robust_wald")))
  # Negative controls.
  moved <- datasets[[paste0(kind, "-event-moved")]]
  moved_fit <- pprofr_default_fit(pprofr_prep(moved, binomial, clustered = FALSE), "control/event-moved/unclustered")
  add_all(moved_fit$records)
  add_all(pprofr_control_unclustered(moved_fit$fit, "control/event-moved/unclustered"))
  moved_clustered <- pprofr_default_fit(pprofr_prep(moved, binomial, clustered = TRUE),
                                        "control/event-moved/clustered")
  add_all(moved_clustered$records)
  add_all(pprofr_control_clustered(moved_clustered$fit, "control/event-moved/clustered"))
  split <- datasets[[paste0(kind, "-cluster-split")]]
  split_fit <- pprofr_default_fit(pprofr_prep(split, binomial, clustered = TRUE), "control/cluster-split/clustered")
  add_all(split_fit$records)
  add_all(pprofr_control_clustered(split_fit$fit, "control/cluster-split/clustered"))
  add_all(pprofr_control_null(default$fit, "control/null-shifted/unclustered"))
  add_all(pprofr_control_null(clustered$fit, "control/null-shifted/clustered", clustered = TRUE))
  list(data = list(main = d, `event-moved` = moved, `cluster-split` = split), records = collect$records())
}

pprofr_many_trials_case <- function(datasets) {
  d <- datasets[["binomial-many-trials"]]
  collect <- pprofr_collector()
  add_all <- collect$add_all
  add_all(list(prep = pprofr_prep_record(d, TRUE, FALSE)))
  prep <- pprofr_prep(d, TRUE, FALSE)
  grid <- data.frame(algorithm = c("BAN", "SerBIN", "SerBIN"), stop_rule = c("beta", "or", "beta"),
                     tol = c(1e-5, 1e-5, 1e-10), stringsAsFactors = FALSE)
  for (k in seq_len(nrow(grid))) {
    algorithm <- grid$algorithm[k]
    stop_rule <- grid$stop_rule[k]
    tol <- grid$tol[k]
    record <- pprofr_record(pprofR::logis_fe(prep, algorithm = algorithm, tol = tol, stop = stop_rule, threads = 1),
                            value = pprofr_fit_summary)
    add_all(stats::setNames(list(record), sprintf("unclustered/fit/%s/%s/%g", algorithm, stop_rule, tol)))
  }
  default <- pprofr_default_fit(prep, "unclustered")
  add_all(default$records)
  add_all(pprofr_profile(default$fit, "unclustered", seed_base = 3000L, n_resamples = 2000,
                         interval_alternatives = "two.sided", n_pop_interval = FALSE))
  moved <- pprofr_default_fit(pprofr_prep(datasets[["many-event-moved"]], TRUE, FALSE),
                              "control/event-moved/unclustered")
  add_all(moved$records)
  add_all(pprofr_control_unclustered(moved$fit, "control/event-moved/unclustered"))
  add_all(pprofr_control_null(default$fit, "control/null-shifted/unclustered"))
  list(data = list(main = d, `event-moved` = datasets[["many-event-moved"]]), records = collect$records())
}

pprofr_few_clusters_case <- function(datasets) {
  data <- list(main = datasets[["few-clusters"]], `one-cluster` = datasets[["one-cluster"]])
  collect <- pprofr_collector()
  for (part in names(data)) {
    prefix <- if (part == "main") "clustered" else "one-cluster"
    collect$add(paste0(prefix, "/prep"), pprofr_prep_record(data[[part]], TRUE, TRUE, cutoff = 1))
    fit <- pprofr_default_fit(pprofr_prep(data[[part]], TRUE, TRUE, cutoff = 1), prefix)
    collect$add_all(fit$records)
    collect$add_all(pprofr_profile_clustered(fit$fit, prefix, alternatives = "two.sided"))
  }
  list(data = data, records = collect$records())
}

pprofr_extreme_case <- function(datasets) {
  data <- list(binary = datasets[["extreme-binary"]], binomial = datasets[["extreme-binomial"]])
  collect <- pprofr_collector()
  for (part in names(data)) {
    binomial <- part == "binomial"
    collect$add(paste0(part, "/prep"), pprofr_prep_record(data[[part]], binomial, FALSE))
    prep <- pprofr_prep(data[[part]], binomial, FALSE)
    fit <- pprofr_default_fit(prep, part)
    collect$add_all(fit$records)
    collect$add(paste0(part, "/fit/SerBIN/beta/1e-10"),
                pprofr_record(pprofR::logis_fe(prep, tol = 1e-10, threads = 1), value = pprofr_fit_summary))
    collect$add_all(pprofr_profile(fit$fit, part, seed_base = if (binomial) 4100L else 4000L,
                                   alternatives = "two.sided", covariate_tests = "wald"))
  }
  list(data = data, records = collect$records())
}

pprofr_zero_trials_case <- function(datasets) {
  data <- list(main = datasets[["zero-trials"]], `zero-trial-provider` = datasets[["zero-trial-provider"]])
  collect <- pprofr_collector()
  collect$add("prep", pprofr_prep_record(data$main, TRUE, FALSE))
  fit <- pprofr_default_fit(pprofr_prep(data$main, TRUE, FALSE), "unclustered")
  collect$add_all(fit$records)
  collect$add_all(pprofr_profile(fit$fit, "unclustered", seed_base = 6000L, alternatives = "two.sided"))
  collect$add("zero-trial-provider/prep", pprofr_prep_record(data[["zero-trial-provider"]], TRUE, FALSE))
  zero <- pprofr_default_fit(pprofr_prep(data[["zero-trial-provider"]], TRUE, FALSE), "zero-trial-provider")
  collect$add_all(zero$records)
  # pprofR's exact test of this fit ends the R session: it passes poibin an empty vector of probabilities
  # for P030, and poibin::ppoibin(0, numeric(0)) crashes (D-100). Its score and Wald tests are recorded.
  collect$add_all(pprofr_profile(zero$fit, "zero-trial-provider", seed_base = 6100L, tests = c("score", "wald"),
                                 alternatives = "two.sided", intervals = character(), covariate_tests = "wald"))
  list(data = data, records = collect$records())
}

pprofr_standard_population_case <- function(populations) {
  p <- populations
  records <- list(
    `direct_exp/continuous` = pprofr_record(pprofR::direct_exp(p$effects, p$continuous, threads = 1)),
    `direct_exp/repeated` = pprofr_record(pprofR::direct_exp(p$effects, p$repeated, threads = 1)),
    `direct_exp/repeated/weights` = pprofr_record(pprofR::direct_exp(p$effects, p$repeated, N = p$weights,
                                                                     threads = 1)),
    `direct_exp/single` = pprofr_record(pprofR::direct_exp(p$effects, 0.25, N = 7, threads = 1))
  )
  list(data = list(populations = populations), records = records)
}

pprofr_measure_tests_case <- function(datasets) {
  d <- datasets[["binomial-moderate"]]
  fit <- pprofR::logis_fe(pprofr_prep(d, TRUE, TRUE), threads = 1)
  measures <- pprofR::SR_output(fit, stdz = "direct", measure = "rate", threads = 1, se = TRUE)
  rate <- drop(measures$direct.rate)
  reference <- sum(fit$obs) / measures$N_pop
  standard_errors <- list()
  for (test in c("wald", "robust_wald", "stabilized_wald")) {
    se_gamma <- pprofR::test_fe(fit, test = test, threads = 1)$se.gamma
    standard_errors[[test]] <- drop(measures$numer_se) / measures$N_pop * se_gamma
  }
  collect <- pprofr_collector()
  inputs <- list(rate = rate, se = standard_errors, reference = reference, numer_se = drop(measures$numer_se),
                 N_pop = measures$N_pop)
  collect$add("inputs", list(call = paste("the clustered fit's direct rates, their standard errors",
                                          "(numer_se / N_pop * se.gamma), and the population rate"),
                             seed = NULL, value = inputs, error = NULL, warnings = character(),
                             messages = character()))
  for (se_type in names(standard_errors)) {
    se <- standard_errors[[se_type]]
    for (transform in c("identity", "logit")) {
      for (null in list(c(0, 1), c(0.5, 1.5))) {
        location <- null[1]
        scale <- null[2]
        for (alternative in pprofr_alternatives) {
          collect$add(sprintf("test_SM/%s/%s/%g-%g/%s", se_type, transform, location, scale, alternative),
                      pprofr_record(pprofR::test_SM(rate, se, reference, transform = transform, location = location,
                                                    scale = scale, alternative = alternative)))
        }
      }
    }
  }
  list(data = list(main = d), records = collect$records())
}

pprofr_supplied_effects_case <- function(datasets) {
  d <- datasets[["binomial-moderate"]]
  fit <- pprofR::logis_fe(pprofr_prep(d, TRUE, FALSE), threads = 1)
  extended <- fit
  extended$gamma <- rbind(fit$gamma, matrix(c(2, 2.5), dimnames = list(c("P901", "P902"), "gamma")))
  records <- list(
    `sr/direct` = pprofr_record(pprofR::SR_output(extended, stdz = "direct", measure = pprofr_measures, threads = 1,
                                                  se = TRUE)),
    `sr/indirect` = pprofr_record(pprofR::SR_output(extended, stdz = "indirect", measure = pprofr_measures,
                                                    threads = 1)),
    `sr/direct/fit` = pprofr_record(pprofR::SR_output(fit, stdz = "direct", measure = pprofr_measures, threads = 1,
                                                      se = TRUE))
  )
  list(data = list(main = d), records = records)
}

pprofr_cluster_order_case <- function(datasets) {
  d <- datasets[["binomial-reversed"]]
  collect <- pprofr_collector()
  collect$add("clustered/prep", pprofr_prep_record(d, TRUE, TRUE))
  fit <- pprofr_default_fit(pprofr_prep(d, TRUE, TRUE), "clustered")
  collect$add_all(fit$records)
  for (test in c("robust_wald", "stabilized_wald", "robust_score", "stabilized_score")) {
    collect$add(sprintf("clustered/test/%s/median/two.sided", test),
                pprofr_record(pprofR::test_fe(fit$fit, test = test, threads = 1)))
  }
  list(data = list(main = d), records = collect$records())
}

pprofr_descriptions <- c(
  `binary-moderate` = "Binary outcomes, 40 providers, clusters of 1 to 4 rows: fits, profiles, tight fits, controls",
  `binomial-moderate` = "Binomial outcomes, 1 to 20 trials a row, 40 providers: fits, profiles, tight fits, controls",
  `binomial-many-trials` = "Binomial outcomes, 12 providers of about 1,100 to 2,200 trials: fits, tests, intervals",
  `few-clusters` = "Binomial outcomes, providers with one, two, and three clusters, and with one cluster each",
  `extreme-probabilities` = "Binary and binomial outcomes with null probabilities below 1e-10",
  `extreme-providers` = "Binomial outcomes; providers without events (P001 to P003), with only events (P004 to P006)",
  `zero-trials` = "Rows with zero trials; a provider (P030) without trials, whose exact test crashes pprofR (D-100)",
  `standard-population` = "direct_exp(): continuous and repeated linear predictors, weights, effects up to 30",
  `measure-tests` = "test_SM() on the direct rates of binomial-moderate's clustered fit, with three standard errors",
  `supplied-effects` = "binomial-moderate's fit with two more effects supplied as pprofR takes them (P901, P902)",
  `cluster-order` = "binomial-moderate with each cluster's rows reversed: the robust and stabilized tests"
)

pprofr_run_case <- function(id, datasets, populations) {
  case <- switch(id,
    `binary-moderate` = pprofr_moderate_case(datasets, "binary", seed_base = 1000L),
    `binomial-moderate` = pprofr_moderate_case(datasets, "binomial", seed_base = 2000L),
    `binomial-many-trials` = pprofr_many_trials_case(datasets),
    `few-clusters` = pprofr_few_clusters_case(datasets),
    `extreme-probabilities` = pprofr_extreme_case(datasets),
    `extreme-providers` = {
      d <- datasets[["extreme-providers"]]
      fit <- pprofr_default_fit(pprofr_prep(d, TRUE, FALSE), "unclustered")
      list(data = list(main = d),
           records = c(list(prep = pprofr_prep_record(d, TRUE, FALSE)), fit$records,
                       pprofr_profile(fit$fit, "unclustered", seed_base = 5000L, covariate_tests = "wald")))
    },
    `zero-trials` = pprofr_zero_trials_case(datasets),
    `standard-population` = pprofr_standard_population_case(populations),
    `measure-tests` = pprofr_measure_tests_case(datasets),
    `supplied-effects` = pprofr_supplied_effects_case(datasets),
    `cluster-order` = pprofr_cluster_order_case(datasets),
    stop("Unknown case: ", id)
  )
  list(id = id, description = pprofr_descriptions[[id]], data = case$data, records = case$records)
}
