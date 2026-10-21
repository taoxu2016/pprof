# The package against pprofR 0.2.0 (commit f23c288), through its fixtures (LOGISTIC_L1_PLAN §3.5; DEC-158,
# DEC-159). From Phase L1: binary outcomes, which the package computes already, on the binary-moderate case and the
# binary part of extreme-probabilities; later phases add binomial outcomes, clusters, and the extensions of
# standardization. The fixtures are the full set in validation/fixtures/pprofr/ (helper-pprofr-fixtures.R); the
# tests skip without it, as under R CMD check, where validation/ is not in the package.

pprofr_formula <- y ~ x1 + x2 + x3

pprofr_case_fit <- function(d, method = "serbin", stop_rule = "coefficients", tol = 1e-5) {
  fit_logistic_fe(pprofr_formula, d, "provider", method = method, stop_rule = stop_rule, tol = tol, threads = 1)
}

# The binary parts: a case, its data set, and the prefix of its records at pprofR's default fit.
pprofr_binary_parts <- list(
  list(id = "binary-moderate", data = "main", prefix = "unclustered", alternatives = c("two.sided", "greater", "less")),
  list(id = "extreme-probabilities", data = "binary", prefix = "binary", alternatives = "two.sided")
)

# Providers whose rows have a null probability beyond the clamp of the exact, bootstrap, and score tests
# ([1e-10, 1 - 1e-10]; K-62, K-64, K-65), where D-82 decides the difference from pprofR; with `null_value` NULL,
# a fitted probability beyond the clamp of the variances (K-20), where D-84 decides the Wald test's.
pprofr_clamped <- function(fit, null_value = NULL) {
  effects <- if (is.null(null_value)) provider_estimates(fit)[provider_index(fit)] else null_value
  p <- stats::plogis(effects + linear_predictor(fit))
  beyond <- p < 1e-10 | p > 1 - 1e-10
  providers <- provider_table(fit)$provider_id[provider_index(fit)]
  unique(providers[beyond])
}

# A provider test against pprofR's record: p-values, statistics, and flags, with the providers that a register
# entry explains (`explained`, by `entry`) compared apart.
expect_pprofr_test <- function(result, record, label, alpha, exact_statistic, explained = character(), entry = "") {
  ref <- pprofr_test_table(record)
  table <- result$table[match(ref$provider_id, result$table$provider_id), ]
  regular <- !ref$provider_id %in% explained
  statistic <- function(x, rows) if (exact_statistic) stats::pnorm(-abs(x[rows])) else x[rows]
  statistic_tier <- if (exact_statistic) "probability" else "closed_form"
  expect_pprofr_tier(table$p_value[regular], ref$p_value[regular], "probability", paste(label, "p"))
  expect_pprofr_tier(statistic(table$statistic, regular), statistic(ref$statistic, regular), statistic_tier,
                     paste(label, "statistic"))
  if (any(!regular)) {
    expect_pprofr_tier(table$p_value[!regular], ref$p_value[!regular], "probability", paste(label, "p", entry),
                       differ = entry)
  }
  near <- pprofr_near_threshold(ref$p_value, alpha)
  pprofr_record_near(paste(label, "flag"), ref$provider_id[near])
  expect_pprofr_tier(table$flag[!near], ref$flag[!near], "exact", paste(label, "flag"))
}

test_that("binary fits reproduce pprofR's iterations and estimates (binary-moderate's grid)", {
  skip_on_cran()
  skip_without_pprofr_fixtures()
  fx <- pprofr_fixture("binary-moderate")
  d <- fx$data$main
  for (algorithm in c("SerBIN", "BAN")) {
    for (stop in c("or", "beta")) {
      for (tol in c(1e-5, 1e-10)) {
        name <- sprintf("unclustered/fit/%s/%s/%g", algorithm, stop, tol)
        ref <- pprofr_value(fx, name)
        fit <- pprofr_case_fit(d, pprofr_method[[algorithm]], pprofr_stop_rule[[stop]], tol)
        label <- paste("binary-moderate", name)
        expect_pprofr_tier(fit$convergence$iterations, ref$control$iter, "exact", paste(label, "iterations"))
        expect_pprofr_tier(provider_estimates(fit)[rownames(ref$df.prov)], ref$df.prov$gamma_est, "iterative",
                           paste(label, "gamma"))
        expect_pprofr_tier(stats::coef(fit), as.numeric(ref$beta), "iterative", paste(label, "beta"))
        expect_pprofr_tier(-2 * generics::glance(fit)$loglik, ref$neg2Loglkd, "closed_form", paste(label, "-2 loglik"))
      }
    }
  }
})

test_that("the default binary fits match pprofR's: criteria, AUC, inclusion, indicators, and variances", {
  skip_on_cran()
  skip_without_pprofr_fixtures()
  for (part in pprofr_binary_parts) {
    fx <- pprofr_fixture(part$id)
    d <- fx$data[[part$data]]
    ref <- pprofr_value(fx, paste0(part$prefix, "/fit/default"))
    prep <- pprofr_value(fx, if (part$prefix == "unclustered") "prep" else paste0(part$prefix, "/prep"))$data
    fit <- pprofr_case_fit(d)
    label <- paste(part$id, part$prefix, "default fit")
    glance <- generics::glance(fit)
    expect_pprofr_tier(fit$convergence$iterations, ref$control$iter, "exact", paste(label, "iterations"))
    expect_pprofr_tier(provider_estimates(fit)[rownames(ref$df.prov)], ref$df.prov$gamma_est, "iterative",
                       paste(label, "gamma"))
    expect_pprofr_tier(stats::coef(fit), as.numeric(ref$beta), "iterative", paste(label, "beta"))
    expect_pprofr_tier(c(-2 * glance$loglik, glance$aic, glance$bic, glance$auc),
                       c(ref$neg2Loglkd, ref$AIC, ref$BIC, ref$AUC), "closed_form", paste(label, "criteria and AUC"))
    providers <- provider_table(fit)
    by_provider <- function(column) as.numeric(tapply(prep[[column]], prep$provider, max))[order(unique(prep$provider))]
    reference_table <- data.frame(provider_id = sort(unique(prep$provider)), included = by_provider("included"),
                                  no_events = by_provider("no.events"), all_events = by_provider("all.events"),
                                  n_obs = as.numeric(table(prep$provider)), stringsAsFactors = FALSE)
    providers <- providers[match(reference_table$provider_id, providers$provider_id), ]
    expect_pprofr_tier(c(as.numeric(providers$included), providers$n_obs),
                       c(reference_table$included, reference_table$n_obs), "exact", paste(label, "inclusion and sizes"))
    included <- providers$included
    expect_pprofr_tier(as.numeric(c(providers$no_events[included], providers$all_events[included])),
                       c(reference_table$no_events[included], reference_table$all_events[included]), "exact",
                       paste(label, "indicators"))
    variance <- pprofr_value(fx, paste0(part$prefix, "/vcov"))
    effects <- provider_effects(fit)$table
    expect_pprofr_tier(unname(stats::vcov(fit)), unname(unclass(variance)[seq_len(3), seq_len(3)]), "closed_form",
                       paste(label, "Var(beta)"))
    expect_pprofr_tier(effects$std_error[match(names(attr(variance, "var.gamma")), effects$provider_id)]^2,
                       unname(attr(variance, "var.gamma")), "closed_form", paste(label, "Var(gamma)"))
  }
})

test_that("binary provider tests match pprofR's, but where D-82 and D-84 decide", {
  skip_on_cran()
  skip_without_pprofr_fixtures()
  for (part in pprofr_binary_parts) {
    fx <- pprofr_fixture(part$id)
    d <- fx$data[[part$data]]
    fit <- pprofr_case_fit(d)
    null_value <- stats::median(provider_estimates(fit))
    clamped <- pprofr_clamped(fit, null_value)
    clamped_fitted <- pprofr_clamped(fit)
    explained_by <- function(test, null_clamped) {
      if (test %in% c("exact.poisbinom", "score")) return(list(providers = null_clamped, entry = "D-82"))
      if (test == "wald") return(list(providers = clamped_fitted, entry = "D-84"))
      list(providers = character(), entry = "")
    }
    for (test in names(pprofr_test)) {
      for (alternative in part$alternatives) {
        name <- sprintf("%s/test/%s/median/%s", part$prefix, test, alternative)
        record <- fx$records[[name]]
        if (!is.null(record$seed)) set.seed(record$seed)
        result <- test_providers(fit, test = pprofr_test[[test]], null = "median", alternative = alternative,
                                 n_resamples = 10000)
        explained <- explained_by(test, clamped)
        expect_pprofr_test(result, pprofr_value(fx, name), paste(part$id, name), alpha = 0.05,
                           exact_statistic = test %in% c("exact.poisbinom", "exact.bootstrap"),
                           explained = explained$providers, entry = explained$entry)
      }
    }
    for (test in c("exact.poisbinom", "score", "wald")) {
      name <- sprintf("%s/test/%s/0/two.sided", part$prefix, test)
      result <- test_providers(fit, test = pprofr_test[[test]], null = 0)
      explained <- explained_by(test, pprofr_clamped(fit, 0))
      expect_pprofr_test(result, pprofr_value(fx, name), paste(part$id, name), alpha = 0.05,
                         exact_statistic = test == "exact.poisbinom", explained = explained$providers,
                         entry = explained$entry)
    }
    name <- sprintf("%s/test/exact.poisbinom/median/two.sided/level-0.9", part$prefix)
    expect_pprofr_test(test_providers(fit, test = "exact", null = "median", level = 0.9), pprofr_value(fx, name),
                       paste(part$id, name), alpha = 0.1, exact_statistic = TRUE, explained = clamped, entry = "D-82")
  }
})

test_that("binary intervals of provider effects match pprofR's within the root tier (D-85)", {
  skip_on_cran()
  skip_without_pprofr_fixtures()
  for (part in pprofr_binary_parts) {
    fx <- pprofr_fixture(part$id)
    fit <- pprofr_case_fit(fx$data[[part$data]])
    for (test in c("exact", "score", "wald")) {
      name <- sprintf("%s/confint/gamma/%s", part$prefix, test)
      ref <- pprofr_value(fx, name)
      table <- provider_effects(fit, interval = test)$table
      table <- table[match(rownames(ref), table$provider_id), ]
      tier <- if (test == "wald") "closed_form" else "root"
      expect_pprofr_tier(c(table$lower, table$upper), c(ref$gamma.lower, ref$gamma.upper), tier,
                         paste(part$id, name, "limits"))
    }
  }
})

test_that("binary standardized measures and their intervals match pprofR's (rates in percent, D-87)", {
  skip_on_cran()
  skip_without_pprofr_fixtures()
  measure_rows <- function(table, standardization, measure, providers) {
    rows <- table[table$standardization == standardization & table$measure == measure, ]
    rows[match(providers, rows$provider_id), ]
  }
  for (part in pprofr_binary_parts) {
    fx <- pprofr_fixture(part$id)
    fit <- pprofr_case_fit(fx$data[[part$data]])
    for (null in c("median", "-0.5")) {
      ref <- pprofr_value(fx, sprintf("%s/sr/%s", part$prefix, null))
      null_value <- if (null == "median") "median" else as.numeric(null)
      table <- standardize_providers(fit, standardization = c("indirect", "direct"), measure = c("ratio", "rate"),
                                     null = null_value)$table
      providers <- rownames(ref$indirect.ratio)
      label <- sprintf("%s %s/sr/%s", part$id, part$prefix, null)
      indirect <- measure_rows(table, "indirect", "ratio", providers)
      direct <- measure_rows(table, "direct", "ratio", providers)
      expect_pprofr_tier(c(indirect$expected, indirect$variance, indirect$estimate),
                         c(ref$OE$OE_indirect$Exp.indirect_provider, ref$OE$OE_indirect$Var.indirect_provider,
                           as.numeric(ref$indirect.ratio)), "closed_form", paste(label, "indirect"))
      expect_pprofr_tier(c(direct$expected, direct$estimate),
                         c(ref$OE$OE_direct$Exp.direct_all, as.numeric(ref$direct.ratio)), "closed_form",
                         paste(label, "direct"))
      expect_pprofr_tier(c(measure_rows(table, "indirect", "rate", providers)$estimate,
                           measure_rows(table, "direct", "rate", providers)$estimate),
                         100 * c(as.numeric(ref$indirect.rate), as.numeric(ref$direct.rate)), "closed_form",
                         paste(label, "rates"))
    }
    for (test in c("exact", "score", "wald")) {
      for (alternative in part$alternatives) {
        name <- sprintf("%s/confint/SM/%s/%s", part$prefix, test, alternative)
        ref <- pprofr_value(fx, name)
        table <- standardize_providers(fit, standardization = c("indirect", "direct"), measure = c("ratio", "rate"),
                                       interval = test, alternative = alternative)$table
        tier <- if (test == "wald") "closed_form" else "root"
        for (standardization in c("indirect", "direct")) {
          ratio <- ref[[sprintf("CI.%s_ratio", standardization)]]
          rate <- ref[[sprintf("CI.%s_rate", standardization)]]
          providers <- rownames(ratio)
          ours <- measure_rows(table, standardization, "ratio", providers)
          ours_rate <- measure_rows(table, standardization, "rate", providers)
          label <- sprintf("%s %s %s", part$id, name, standardization)
          expect_pprofr_tier(c(ours$lower, ours$upper), c(ratio$CI_ratio.lower, ratio$CI_ratio.upper), tier,
                             paste(label, "ratio limits"))
          expect_pprofr_tier(c(ours_rate$lower, ours_rate$upper), 100 * c(rate$CI_rate.lower, rate$CI_rate.upper),
                             tier, paste(label, "rate limits"))
        }
      }
    }
  }
})

test_that("binary covariate tests match pprofR's", {
  skip_on_cran()
  skip_without_pprofr_fixtures()
  fx <- pprofr_fixture("binary-moderate")
  fit <- pprofr_case_fit(fx$data$main)
  ref <- pprofr_value(fx, "unclustered/covar/wald")
  table <- test_coefficients(fit, test = "wald")$table
  label <- "binary-moderate unclustered/covar/wald"
  expect_pprofr_tier(table$std_error, ref$se.beta, "closed_form", paste(label, "se"))
  expect_pprofr_tier(table$statistic, ref$Z, "closed_form", paste(label, "statistic"))
  expect_pprofr_tier(table$p_value, ref$p, "probability", paste(label, "p (D-103)"))
  expect_pprofr_tier(c(table$lower, table$upper), c(ref$CI.lower, ref$CI.upper), "closed_form", paste(label, "limits"))
  # The variances and the Wald test of a tight fit.
  tight <- pprofr_case_fit(fx$data$main, tol = 1e-13)
  ref_tight <- pprofr_value(fx, "unclustered/tight/vcov")
  expect_pprofr_tier(unname(stats::vcov(tight)), unname(unclass(ref_tight)[seq_len(3), seq_len(3)]), "closed_form",
                     "binary-moderate unclustered/tight/vcov")
  expect_pprofr_tier(test_coefficients(tight, test = "wald")$table$std_error,
                     pprofr_value(fx, "unclustered/tight/covar/wald")$se.beta, "closed_form",
                     "binary-moderate unclustered/tight/covar/wald se")
  # The likelihood-ratio and score tests: pprof refits the null models at its default settings, pprofR at the fit's
  # (D-90; the fit here at stop_rule = "coefficients", pprofR's "beta").
  for (test in c("lr", "score")) {
    ref <- pprofr_value(fx, sprintf("unclustered/covar/%s", test))
    table <- test_coefficients(fit, test = test, data = fx$data$main)$table
    label <- sprintf("binary-moderate unclustered/covar/%s", test)
    expect_pprofr_tier(table$statistic, ref$stat, "closed_form", paste(label, "statistic (D-90)"), differ = "D-90")
  }
})
