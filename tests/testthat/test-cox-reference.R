# The provider-stratified Cox model against the Cox fixtures (the CoxPH brief's §6 A; COXPH_DESIGN
# §G; the C2 plan, §4.3): pprof_py v0.7.0's outputs under the calibrated tiers (DEC-097), with one
# regression test per register entry Phase C2 implements. The core set always, the full set when
# it is present (validation/fixtures/cox/), behind skip_on_cran(). The package's numbers are
# survival's (test-model-survival.R); here they meet pprof_py's, as survival's did in the
# calibration (validation/cox-calibration-report.md).
local_strict_mode()

# The Cox cases of a fixture set (not the competing-risk and penalized ones).
cox_reference_ids <- function(set, kind = "cox") {
  manifest <- cox_manifest(set)
  if (is.null(manifest)) return(character())
  ids <- names(manifest$cases)
  ids[vapply(ids, function(id) identical(cox_fixture(id, set)$case$kind, kind), logical(1))]
}

# a matches b under a tier of helper-tolerances.R, elementwise.
cox_matches <- function(a, b, tier) {
  is.null(reference_compare(as.double(unlist(a)), as.double(unlist(b)), reference_tolerance(tier)))
}

expect_cox_match <- function(a, b, tier, label) {
  expect(cox_matches(a, b, tier), sprintf("%s: differs from the reference beyond %s", label, tier))
}

expect_cox_differ <- function(a, b, tier, label) {
  expect(!cox_matches(a, b, tier), sprintf("%s: expected to differ beyond %s", label, tier))
}

# The baseline of a fit at pprof_py's points: each (stratum, event time) of pprof_py's raw baseline,
# matched exactly to the package's (provider, time).
cox_baseline_at <- function(baseline, raw) {
  keys <- sprintf("%s|%a", as.character(unlist(raw$stratum)), unlist(raw$time))
  ours <- sprintf("%s|%a", baseline$provider_id, baseline$time)
  baseline$cumulative_hazard[match(keys, ours)]
}

for (set in c("core", "full")) {
  local({
    set_name <- set

    test_that(sprintf("fits of the %s Cox cases match pprof_py's (D-57, D-58, D-64, M-23)", set_name), {
      ids <- cox_reference_ids(set_name)
      if (!length(ids)) skip(sprintf("no %s Cox fixture set here", set_name))
      if (identical(set_name, "full")) skip_on_cran()
      for (id in ids) {
        fx <- cox_fixture(id, set_name)
        for (ties in c("breslow", "efron")) {
          label <- paste(id, ties)
          py <- fx$pprof_py[[ties]]
          r <- fx$survival[[ties]]
          default <- cox_case_fit(fx, ties)
          tight <- cox_case_fit(fx, ties, tight = TRUE)
          # D-57: the iteration counts match exactly; default fits stop within the longer of the two
          # last Newton steps of each other.
          # D-58: pprof_py counts zero-weight events among Efron's tied deaths; the package leaves those
          # rows out, as survival does (its fixture fits are on the positive-weight rows).
          d58 <- identical(id, "zero-weights") && identical(ties, "efron")
          expect_identical(default$convergence$iterations, as.integer(py$default$iterations), label = label)
          expect_identical(tight$convergence$iterations, as.integer(py$tight$iterations), label = label)
          if (d58) {
            expect_cox_match(coef(default), r$default$coef, "cox_coefficient", paste(label, "default (D-58)"))
            expect_cox_differ(coef(tight), py$tight$coef, "cox_coefficient", paste(label, "pprof_py (D-58)"))
          } else {
            bound <- cox_last_step_bound(coef(default), py$default$coef, py$iterates, py$default$iterations)
            expect_lte(max(abs(unname(coef(default)) - unlist(py$default$coef))), bound,
                       label = paste(label, "default"))
          }
          reference <- if (d58) r$tight else py$tight
          expect_cox_match(coef(tight), reference$coef, "cox_coefficient", paste(label, "coefficients"))
          expect_cox_match(sqrt(diag(vcov(tight))), reference$se, "cox_variance", paste(label, "standard errors"))
          expect_cox_match(cox_packed_upper(vcov(tight)), reference$covariance, "cox_variance",
                           paste(label, "covariance"))
          expect_cox_match(tight$loglik[2], reference$loglik, "cox_function", paste(label, "log-likelihood"))
          expect_cox_match(tight$loglik[1], reference$loglik_null, "cox_function", paste(label, "null log-likelihood"))
          # M-23: times are compared exactly; survival's default timefix = TRUE would merge the near ties.
          if (!is.null(r$tight_timefix)) {
            expect_cox_differ(coef(tight), r$tight_timefix$coef, "cox_coefficient", paste(label, "timefix = TRUE"))
          }
        }
      }
    })

    test_that(sprintf("coefficient tests of the %s Cox cases follow pprof_py's rule (DEC-101)", set_name), {
      ids <- cox_reference_ids(set_name)
      if (!length(ids)) skip(sprintf("no %s Cox fixture set here", set_name))
      if (identical(set_name, "full")) skip_on_cran()
      for (id in ids) {
        fx <- cox_fixture(id, set_name)
        for (ties in c("breslow", "efron")) {
          if (identical(id, "zero-weights") && identical(ties, "efron")) next
          label <- paste(id, ties)
          py <- fx$pprof_py[[ties]]$tight
          table <- test_coefficients(cox_case_fit(fx, ties, tight = TRUE))$table
          # z = beta / se, its upper-tail two-sided p-value, and beta -/+ qnorm(1 - alpha / 2) se,
          # with the estimates and standard errors compared above.
          expect_identical(table$statistic, table$estimate / table$std_error, label = label)
          expect_identical(table$p_value, 2 * stats::pnorm(abs(table$statistic), lower.tail = FALSE), label = label)
          critical <- stats::qnorm(1 - (1 - 0.95) / 2)
          expect_identical(table$lower, table$estimate - critical * table$std_error, label = label)
          expect_cox_match(table$statistic, py$z, "cox_variance", paste(label, "z"))
          # pprof_py's p-values below 1e-16 are reported, not 0 (lt-stratified: 5.5e-20); both are 0
          # only where the upper tail underflows (|z| above about 38).
          tiny <- unlist(py$p) > 0 & unlist(py$p) < 1e-16
          expect_true(all(table$p_value[tiny] > 0), label = label)
        }
      }
    })

    test_that(sprintf("residuals and robust variances of the %s Cox cases (D-56, D-58, D-64)", set_name), {
      ids <- cox_reference_ids(set_name)
      if (!length(ids)) skip(sprintf("no %s Cox fixture set here", set_name))
      if (identical(set_name, "full")) skip_on_cran()
      for (id in ids) {
        fx <- cox_fixture(id, set_name)
        if (isFALSE(fx$case$residuals)) next
        kept <- unlist(fx$survival$kept_rows) + 1L
        for (ties in c("breslow", "efron")) {
          label <- paste(id, ties)
          py <- fx$pprof_py[[ties]]$residuals
          r <- fx$survival[[ties]]$residuals
          fit <- cox_case_fit(fx, ties, tight = TRUE, keep_data = TRUE)
          # pprof_py's residuals of the rows survival fits; D-64: with a covariate of large mean,
          # pprof_py's uncentered exp() breaks them, and they are compared with survival's.
          large_mean <- identical(id, "large-mean")
          zero_efron <- identical(id, "zero-weights") && identical(ties, "efron")
          martingale <- unname(residuals(fit))[kept]
          score <- residuals(fit, type = "score")[kept, , drop = FALSE]
          dfbeta <- residuals(fit, type = "dfbeta")[kept, , drop = FALSE]
          if (large_mean || zero_efron) {
            expect_cox_match(martingale, r$martingale, "cox_residual", paste(label, "martingale"))
            expect_cox_match(score, r$score, "cox_residual", paste(label, "score"))
            expect_cox_match(dfbeta, r$dfbeta, "cox_residual", paste(label, "dfbeta"))
          } else {
            expect_cox_match(martingale, unlist(py$martingale)[kept], "cox_residual", paste(label, "martingale"))
            rows_of <- function(columns) lapply(columns, function(v) unlist(v)[kept])
            expect_cox_match(score, rows_of(py$score), "cox_residual", paste(label, "score"))
            expect_cox_match(dfbeta, rows_of(py$dfbeta), "cox_residual", paste(label, "dfbeta"))
          }
          per_row <- cox_case_fit(fx, ties, tight = TRUE, robust = TRUE)
          clustered <- cox_case_fit(fx, ties, tight = TRUE, cluster = ".cluster")
          expect_cox_match(cox_packed_upper(vcov(per_row)), r$robust_per_row, "cox_variance", paste(label, "robust"))
          expect_cox_match(cox_packed_upper(vcov(clustered)), r$robust_clustered, "cox_variance",
                           paste(label, "clustered"))
          expect_cox_match(cox_packed_upper(per_row$naive_vcov), r$naive_covariance, "cox_variance",
                           paste(label, "naive"))
          if (large_mean || zero_efron) next
          # D-56: with Breslow ties on (start, stop] data pprof_py applies Efron's formulas to tied
          # deaths in its robust kernel; with Efron ties, or right-censored data, the two agree.
          if (identical(ties, "breslow") && isTRUE(fx$case$truncated)) {
            expect_cox_differ(cox_packed_upper(vcov(per_row)), py$robust_per_row, "cox_variance", paste(label, "D-56"))
          } else {
            expect_cox_match(cox_packed_upper(vcov(per_row)), py$robust_per_row, "cox_variance", paste(label, "robust"))
            expect_cox_match(cox_packed_upper(vcov(clustered)), py$robust_clustered, "cox_variance",
                             paste(label, "clustered"))
          }
        }
      }
    })

    test_that(sprintf("baselines and curves of the %s Cox cases match pprof_py's (D-60)", set_name), {
      ids <- cox_reference_ids(set_name)
      if (!length(ids)) skip(sprintf("no %s Cox fixture set here", set_name))
      if (identical(set_name, "full")) skip_on_cran()
      for (id in ids) {
        fx <- cox_fixture(id, set_name)
        for (ties in c("breslow", "efron")) {
          if (identical(id, "zero-weights") && identical(ties, "efron")) next
          label <- paste(id, ties)
          py <- fx$pprof_py[[ties]]$baseline
          fit <- cox_case_fit(fx, ties, tight = TRUE, keep_data = TRUE)
          baseline <- baseline_hazard(fit)
          raw <- py$raw
          if (identical(id, "zero-weights")) {
            # pprof_py's baseline also has the times of zero-weight events (D-58).
            keep <- !is.na(match(sprintf("%s|%a", unlist(raw$stratum), unlist(raw$time)),
                                 sprintf("%s|%a", baseline$provider_id, baseline$time)))
            raw <- lapply(raw, function(v) unlist(v)[keep])
          }
          ours <- cox_baseline_at(baseline, raw)
          expect_false(anyNA(ours), label = paste(label, "every pprof_py point found"))
          if (identical(id, "large-mean")) next  # D-64: pprof_py's baseline at x = 0 differs or underflows
          expect_cox_match(ours, raw$cumulative_hazard, "cox_baseline", paste(label, "baseline"))
          # D-60: pprof_py's reported baseline_hazard_ carries exp(the weighted mean offset).
          public <- unlist(py$public_cumulative_hazard)
          if (identical(id, "zero-weights")) public <- public[keep]
          expect_cox_match(ours, public / exp(py$offset_mean), "cox_baseline", paste(label, "D-60"))
          # The curves of pprof_py's profiles in its first two strata.
          features <- unlist(fx$case$features)
          for (block in py$predictions) {
            profiles <- as.data.frame(do.call(rbind, lapply(py$profiles$x, unlist)))
            names(profiles) <- features
            profiles$offset <- unlist(py$profiles$offset)
            profiles$.provider <- block$stratum
            for (type in c("cumulative_hazard", "survival")) {
              curves <- predict(fit, newdata = profiles, type = type)
              for (k in seq_len(nrow(profiles))) {
                at <- curves[curves$row == k, , drop = FALSE]
                value <- at[[type]][match(sprintf("%a", unlist(block$time)), sprintf("%a", at$time))]
                reference <- unlist(block[[type]][[k]])
                if (identical(id, "zero-weights")) {
                  # pprof_py's curves also have the times of zero-weight events (D-58).
                  reference <- reference[!is.na(value)]
                  value <- value[!is.na(value)]
                }
                expect_cox_match(value, reference, "cox_baseline",
                                 sprintf("%s %s, stratum %s, profile %d", label, type, block$stratum, k))
              }
            }
          }
        }
      }
    })

    # Phase C3: the measures, tests, limits, and funnels, first given pprof_py's own inputs, which
    # isolates the closed forms of R/model-cox-measures.R and R/inference-poisson.R from the fit
    # (the CoxPH C3 plan, §4.2), on every Cox case and cause-specific record.
    test_that(sprintf("measures, tests, and funnels at pprof_py's inputs, %s Cox fixtures", set_name), {
      ids <- c(cox_reference_ids(set_name), cox_reference_ids(set_name, kind = "competing"))
      if (!length(ids)) skip(sprintf("no %s Cox fixture set here", set_name))
      if (identical(set_name, "full")) skip_on_cran()
      for (id in ids) {
        fx <- cox_fixture(id, set_name)
        for (ties in c("breslow", "efron")) {
          for (rec in cox_profile_records(fx, ties)) {
            label <- rec$label
            measures <- rec$py$measures
            labels <- sort(unique(rec$provider))
            codes <- match(rec$provider, labels)
            rows <- seq_along(labels)
            eta <- drop(rec$x %*% unlist(measures$beta)) + rec$offset
            expected <- cox_expected_events(eta, rec$start, rec$stop, rec$event)
            expect_identical(data_provider_sums(rec$event, codes, rows), unlist(measures$observed), label = label)
            expect_cox_match(data_provider_sums(expected, codes, rows), measures$expected, "closed_form",
                             paste(label, "expected events"))
            expect_cox_match(sum(expected), sum(rec$event), "closed_form", paste(label, "sum of the expected events"))
            expect_cox_match(data_provider_sums(rec$stop - rec$start, codes, rows), measures$person_time,
                             "closed_form", paste(label, "person-time"))
            model <- list(linear_predictor = eta, offset = NULL, provider_index = codes, response = rec$event,
                          start = rec$start, stop = rec$stop)
            expect_cox_match(cox_direct_expected(model, rows), measures$direct_expected, "closed_form",
                             paste(label, "direct expected events"))
            for (test in c("midp", "exact")) {
              py <- rec$py$tests[[test]]
              observed <- unlist(py$observed)
              expected_py <- unlist(py$expected)
              result <- infer_poisson_test(observed, expected_py, test, 0.95)
              expect_cox_match(result$statistic, py$z_raw, "cox_statistic", paste(label, test, "statistics"))
              expect_cox_match(result$p_value, py$p_value, "probability", paste(label, test, "p-values"))
              expect_identical(result$flag, as.integer(unlist(py$flag)), label = paste(label, test, "flags"))
              limits <- if (test == "midp") {
                infer_poisson_midp_limits(observed, expected_py, 0.95)
              } else {
                infer_poisson_exact_limits(observed, expected_py, 0.95)
              }
              tier <- if (test == "midp") "cox_root" else "closed_form"
              expect_cox_match(limits[, "lower"], py$ci_lower, tier, paste(label, test, "lower limits"))
              expect_cox_match(limits[, "upper"], py$ci_upper, tier, paste(label, test, "upper limits"))
            }
            # The funnel limits are counts and a half over the same expected count: equal (DEC-107).
            for (part in cox_funnel_parts(rec$py$funnel)) {
              expect_cox_match(unname(part$ours), part$theirs, "exact", paste(label, "funnel limits"))
            }
          }
        }
      }
    })

    # Then from the package's own tight fits, whose strata are pprof_py's providers in the stratified
    # cases: the expected events at each side's coefficients, and the flags, except for a provider within
    # tolerance of a threshold (the CoxPH brief's §3.5; none here, validation/cox-calibration-report.md).
    test_that(sprintf("measures and flags of the package's fits, %s Cox fixtures (D-58, M-29)", set_name), {
      ids <- c(cox_reference_ids(set_name), cox_reference_ids(set_name, kind = "competing"))
      if (!length(ids)) skip(sprintf("no %s Cox fixture set here", set_name))
      if (identical(set_name, "full")) skip_on_cran()
      quiet <- function(expr) {
        withCallingHandlers(expr, pprof_warning_zero_expected = function(w) invokeRestart("muffleWarning"))
      }
      for (id in ids) {
        fx <- cox_fixture(id, set_name)
        for (ties in c("breslow", "efron")) {
          for (rec in cox_profile_records(fx, ties)) {
            if (is.null(rec$fit)) next
            label <- rec$label
            fit <- rec$fit()
            measures <- quiet(standardize_providers(fit, c("indirect", "direct")))$table
            indirect <- measures[measures$standardization == "indirect", ]
            direct <- measures[measures$standardization == "direct", ]
            py <- rec$py$measures
            expect_identical(indirect$provider_id, as.character(unlist(py$provider)), label = label)
            expect_identical(indirect$observed, unlist(py$observed), label = label)
            expect_cox_match(fit$providers$person_time, py$person_time, "closed_form", paste(label, "person-time"))
            # D-58: pprof_py's Efron fit counts zero-weight events among tied deaths, so its coefficients,
            # and the expected events at them, differ; with Breslow ties they agree.
            d58 <- identical(id, "zero-weights") && identical(ties, "efron")
            check <- if (d58) expect_cox_differ else expect_cox_match
            check(indirect$expected, py$expected, "cox_baseline", paste(label, "expected events"))
            check(direct$expected, py$direct_expected, "cox_baseline", paste(label, "direct expected events"))
            if (d58) next
            expect_cox_match(indirect$estimate, py$indirect_ratio, "cox_baseline", paste(label, "indirect ratios"))
            expect_cox_match(direct$estimate, py$direct_ratio, "cox_baseline", paste(label, "direct ratios"))
            for (test in c("midp", "exact")) {
              flags <- quiet(test_providers(fit, test = test))$table$flag
              near <- cox_near_threshold(indirect$observed, indirect$expected, test)
              expect_identical(flags[!near], as.integer(unlist(rec$py$tests[[test]]$flag))[!near],
                               label = paste(label, test, "flags"))
            }
          }
        }
      }
    })
  })
}

test_that("Surv(time, event == k) gives pprof_py's cause-specific fits (M-35)", {
  ids <- cox_reference_ids("core", kind = "competing")
  if (!length(ids)) skip("no core competing-risk fixtures here")
  for (id in ids) {
    fx <- cox_fixture(id)
    d <- fx$input
    lhs <- if (isTRUE(fx$case$truncated)) "Surv(entry, time, event == %d)" else "Surv(time, event == %d)"
    for (ties in c("breslow", "efron")) {
      for (cause in names(fx$pprof_py[[ties]]$cause_specific)) {
        rhs <- paste(unlist(fx$case$features), collapse = " + ")
        f <- stats::as.formula(paste(sprintf(lhs, as.integer(cause)), "~", rhs))
        fit <- fit_cox_stratified(f, d, provider = "stratum", ties = ties, max_iter = 100, tol = 1e-11)
        py <- fx$pprof_py[[ties]]$cause_specific[[cause]]$tight
        label <- sprintf("%s %s cause %s", id, ties, cause)
        expect_identical(fit$convergence$iterations, as.integer(py$iterations), label = label)
        expect_cox_match(coef(fit), py$coef, "cox_coefficient", paste(label, "coefficients"))
        expect_cox_match(cox_packed_upper(vcov(fit)), py$covariance, "cox_variance", paste(label, "covariance"))
      }
    }
  }
})

test_that("the package's fits of the core Cox cases are survival's, bitwise (cox_engine)", {
  ids <- cox_reference_ids("core")
  if (!length(ids)) skip("no core Cox fixture set here")
  for (id in ids) {
    fx <- cox_fixture(id)
    for (ties in c("breslow", "efron")) {
      for (tight in c(FALSE, TRUE)) {
        label <- sprintf("%s %s %s", id, ties, if (tight) "tight" else "default")
        fit <- cox_case_fit(fx, ties, tight, keep_data = TRUE)
        direct <- cox_case_coxph(fx, ties, tight)
        expect_identical(unname(coef(fit)), unname(coef(direct)), label = paste(label, "coefficients"))
        expect_identical(unname(vcov(fit)), unname(direct$var), label = paste(label, "variance"))
        expect_identical(fit$loglik, direct$loglik, label = paste(label, "log-likelihoods"))
        expect_identical(fit$convergence$iterations, direct$iter, label = paste(label, "iterations"))
        rows <- survival_fit_rows(fit)
        expect_identical(fit$martingale_residuals[rows], unname(direct$residuals), label = paste(label, "martingale"))
        expect_identical(unname(coef(fit$engine_fit)), unname(coef(direct)), label = paste(label, "coxph() object"))
        # Score and dfbeta residuals, in the prepared order.
        prepared <- as.character(fit$row_index[rows])
        for (type in c("score", "dfbeta")) {
          expect_identical(unname(residuals(fit, type = type)[prepared, , drop = FALSE]),
                           unname(as.matrix(stats::residuals(direct, type = type))), label = paste(label, type))
        }
        for (cluster in c("row", ".cluster")) {
          robust <- if (identical(cluster, "row")) {
            cox_case_fit(fx, ties, tight, robust = TRUE)
          } else {
            cox_case_fit(fx, ties, tight, cluster = ".cluster")
          }
          direct_robust <- cox_case_coxph(fx, ties, tight, cluster = cluster)
          expect_identical(unname(vcov(robust)), unname(direct_robust$var), label = paste(label, "robust", cluster))
          expect_identical(unname(robust$naive_vcov), unname(direct_robust$naive.var),
                           label = paste(label, "naive", cluster))
        }
        if (!tight) next
        # The baseline at 0, from survfit() of the direct fit with every covariate and the offset 0.
        features <- unlist(fx$case$features)
        events <- fit$provider_index[rows][fit$response[rows] == 1]
        values <- fit$providers$provider_value[sort(unique(events))]
        zero <- as.data.frame(matrix(0, length(values), length(features), dimnames = list(NULL, features)))
        if (isTRUE(fx$case$offset)) zero$offset <- 0
        # survival's survfit() takes no stratum in new data for a model with one stratum.
        if (length(values) > 1L) zero$.provider <- values
        curves <- suppressWarnings(survival::survfit(direct, newdata = zero, se.fit = FALSE))
        expected <- do.call(rbind, lapply(seq_along(values), function(k) {
          curve <- curves[k]
          keep <- curve$n.event > 0
          data.frame(provider_id = as.character(values[k]), time = curve$time[keep],
                     cumulative_hazard = curve$cumhaz[keep], stringsAsFactors = FALSE)
        }))
        rownames(expected) <- NULL
        expect_identical(baseline_hazard(fit), expected, label = paste(label, "baseline"))
      }
    }
  }
})
