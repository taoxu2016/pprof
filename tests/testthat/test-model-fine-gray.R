# The Fine-Gray model (COXPH_DESIGN §B, §D.4; the CoxPH C5 plan, §3.3 and §4.4; DEC-121 to DEC-128):
# fit_fine_gray(), its object, and its methods. test-model-survival.R tests the adapter it calls, and
# test-cox-fine-gray-reference.R compares it with pprof_py's fixtures.
local_strict_mode()

fine_gray_fit <- function(formula = Surv(start, stop, cause) ~ x1 + x2, data = fine_gray_data(), cause = 1,
                          id = "id", weights = "w", ...) {
  fit_fine_gray(formula, data, provider = "provider", cause = cause, id = id, weights = weights, ...)
}

test_that("fit_fine_gray() is the adapter's fit, with the object's fields (COXPH_DESIGN §B.2)", {
  d <- fine_gray_data()
  for (ties in c("breslow", "efron")) {
    fit <- fine_gray_fit(data = d, ties = ties)
    prepared <- fine_gray_prepare(Surv(start, stop, cause) ~ x1 + x2, d, weights = "w", cluster = "id")
    estimates <- survival_fine_gray_fit(prepared, 1, TRUE, ties, max_iter = 20, tol = 1e-9)
    expect_s3_class(fit, c("pprof_fine_gray", "pprof_model"), exact = TRUE)
    expect_identical(fit$coefficients, estimates$coefficients)
    expect_identical(fit$vcov, estimates$vcov)
    expect_identical(fit$naive_vcov, estimates$naive_vcov)
    expect_identical(fit$loglik, estimates$loglik)
    expect_identical(fit$status, prepared$response)
    expect_identical(fit$response, as.numeric(prepared$response == 1))
    expect_identical(fit$states, c("1", "2"))
    expect_identical(fit$cause, "1")
    expect_identical(fit$start, prepared$start)
    expect_identical(fit$weights, prepared$weights)
    expect_null(fit$provider_effects)
    expect_null(fit$engine_fit)
    expect_identical(fit$n_events, estimates$n_events)
    expect_identical(fit$n_competing, estimates$n_competing)
    expect_identical(fit$n_expanded, estimates$n_expanded)
    expect_identical(fit$n_zero_weight, sum(d$w == 0))
    providers <- fit$providers
    expect_identical(providers$n_events, as.numeric(tabulate(prepared$provider_index[prepared$response == 1],
                                                             nrow(providers))))
    expect_identical(providers$n_competing, as.numeric(tabulate(prepared$provider_index[prepared$response == 2],
                                                                nrow(providers))))
    expect_equal(providers$person_time, as.numeric(tapply(d$stop - d$start, d$provider, sum)), tolerance = 0)
    expect_identical(nobs(fit), fit$n_events)
    expect_identical(as.double(logLik(fit)), fit$loglik[2])
    expect_identical(fit$spec[c("family", "cause", "id", "ties")],
                     list(family = "fine_gray", cause = "1", id = "id", ties = ties))
  }
})

test_that("the fit is coxph(cluster = id)'s on finegray()'s expansion, bitwise (cox_engine, DEC-121)", {
  cases <- list(
    list(formula = Surv(stop, cause) ~ x1, data = fine_gray_data(split = FALSE, late = 0), id = NULL),
    list(formula = Surv(start, stop, cause) ~ x1 + x2, data = fine_gray_data(), id = "id")
  )
  for (case in cases) {
    prepared <- fine_gray_prepare(case$formula, case$data, weights = "w", cluster = case$id)
    for (ties in c("breslow", "efron")) {
      for (cause in 1:2) {
        label <- sprintf("%s, %s, cause %d", deparse1(case$formula), ties, cause)
        fit <- fit_fine_gray(case$formula, case$data, "provider", cause = cause, id = case$id, weights = "w",
                             ties = ties)
        direct <- fine_gray_direct_coxph(prepared, fine_gray_direct_expansion(prepared, cause), ties)
        expect_identical(fit$coefficients, coef(direct), label = paste(label, "coefficients"))
        expect_identical(unname(fit$vcov), unname(direct$var), label = paste(label, "robust variance"))
        expect_identical(unname(fit$naive_vcov), unname(direct$naive.var), label = paste(label, "model-based"))
        expect_identical(fit$convergence$iterations, direct$iter, label = paste(label, "iterations"))
      }
    }
  }
})

test_that("predict() gives the linear predictor, the risk, and survfit()'s cumulative incidence", {
  d <- fine_gray_data()
  fit <- fine_gray_fit(data = d, keep_data = TRUE)
  expect_s3_class(fit$engine_fit, "coxph")
  # The linear predictor x'beta for the observations, in the order of the data's rows, and for new data.
  lp <- predict(fit)
  x <- as.matrix(d[, c("x1", "x2")])
  expect_equal(unname(lp), drop(x %*% fit$coefficients)[as.integer(names(lp))], tolerance = 1e-14)
  newdata <- data.frame(x1 = c(0, 0.5, -1), x2 = c(0, -0.25, 0.75), provider = c("p01", "p02", "p02"))
  expect_equal(predict(fit, newdata = newdata, type = "risk"), exp(drop(as.matrix(newdata[1:2]) %*% fit$coefficients)),
               tolerance = 1e-15)
  # The cumulative incidence: 1 - survfit() of coxph() on the expansion, at the provider's event times.
  incidence <- predict(fit, newdata = newdata, type = "cumulative_incidence")
  expect_named(incidence, c("row", "provider_id", "time", "cumulative_incidence"))
  prepared <- fine_gray_prepare(Surv(start, stop, cause) ~ x1 + x2, d, weights = "w", cluster = "id")
  direct <- fine_gray_direct_coxph(prepared, fine_gray_direct_expansion(prepared, 1), "breslow")
  codes <- match(newdata$provider, fit$providers$provider_id)
  for (k in seq_len(nrow(newdata))) {
    curve <- survival::survfit(direct, newdata = data.frame(x1 = newdata$x1[k], x2 = newdata$x2[k],
                                                            provider = codes[k]), se.fit = FALSE)
    events <- curve$n.event > 0
    ours <- incidence[incidence$row == k, ]
    expect_identical(ours$time, curve$time[events], label = sprintf("row %d times", k))
    expect_identical(ours$cumulative_incidence, 1 - curve$surv[events], label = sprintf("row %d incidence", k))
    expect_true(all(ours$provider_id == newdata$provider[k]))
  }
  # Without keep_data, the data the model was fit to give the same curves, and other data raise.
  plain <- fine_gray_fit(data = d)
  expect_identical(predict(plain, newdata = newdata, type = "cumulative_incidence", data = d), incidence)
  expect_error(predict(plain, newdata = newdata, type = "cumulative_incidence"), class = "pprof_error_data_required")
  expect_error(predict(plain, newdata = newdata, type = "cumulative_incidence", data = d[-1, ]),
               class = "pprof_error_invalid_input")
  expect_error(predict(fit, type = "cumulative_incidence"), class = "pprof_error_invalid_input")
  # A provider the model does not have warns, and its row is missing.
  unknown <- data.frame(x1 = 0, x2 = 0, provider = "p99")
  expect_warning(missing <- predict(fit, newdata = unknown, type = "cumulative_incidence"),
                 class = "pprof_warning_unknown_providers")
  expect_true(is.na(missing$cumulative_incidence))
})

test_that("a provider without events of interest is in the table, out of the fit, and without a curve", {
  d <- fine_gray_data()
  d$cause[d$provider == "p03" & d$cause == "1"] <- "2"
  fit <- fine_gray_fit(data = d, keep_data = TRUE)
  expect_identical(fit$providers$n_events[fit$providers$provider_id == "p03"], 0)
  expect_true("p03" %in% fit$providers$provider_id[fit$providers$included])
  incidence <- predict(fit, newdata = data.frame(x1 = 0, x2 = 0, provider = c("p03", "p04")),
                       type = "cumulative_incidence")
  expect_true(is.na(incidence$cumulative_incidence[incidence$row == 1]))
  expect_true(all(!is.na(incidence$cumulative_incidence[incidence$row == 2])))
})

test_that("one provider, and a model without covariates", {
  d <- fine_gray_data(providers = 1)
  fit <- fine_gray_fit(data = d, keep_data = TRUE)
  incidence <- predict(fit, newdata = data.frame(x1 = 0, x2 = 0, provider = "p01"), type = "cumulative_incidence")
  expect_true(nrow(incidence) > 1L && all(diff(incidence$cumulative_incidence) >= 0))
  bare <- fine_gray_fit(Surv(start, stop, cause) ~ 1, data = fine_gray_data(), keep_data = TRUE)
  expect_length(bare$coefficients, 0L)
  expect_identical(bare$loglik[1], bare$loglik[2])
  expect_error(predict(bare, newdata = data.frame(provider = "p01"), type = "cumulative_incidence"),
               class = "pprof_error_unsupported_inference")
})

test_that("cause is an event type, by label or number (DEC-123)", {
  d <- fine_gray_data()
  labels <- c("none", "relapse", "death")
  d$event <- factor(labels[as.integer(d$cause)], levels = labels)
  by_label <- fine_gray_fit(Surv(start, stop, event) ~ x1, d, cause = "death")
  by_code <- fine_gray_fit(Surv(start, stop, cause) ~ x1, d, cause = 2)
  expect_identical(by_label$coefficients, by_code$coefficients)
  expect_identical(by_label$cause, "death")
  expect_identical(fine_gray_fit(Surv(start, stop, cause) ~ x1, d, cause = "2")$coefficients, by_code$coefficients)
  invalid <- function(expr) expect_error(expr, class = "pprof_error_invalid_input")
  invalid(fine_gray_fit(Surv(start, stop, event) ~ x1, d, cause = "none"))
  invalid(fine_gray_fit(Surv(start, stop, event) ~ x1, d, cause = 1))
  invalid(fine_gray_fit(Surv(start, stop, cause) ~ x1, d, cause = c(1, 2)))
  invalid(fine_gray_fit(Surv(start, stop, cause) ~ x1, d, cause = NA))
})

test_that("inputs: a factor status, no offsets, missing values dropped (DEC-123, DEC-124, D-62, D-74)", {
  d <- fine_gray_data()
  invalid <- function(expr) expect_error(expr, class = "pprof_error_invalid_input")
  d$code <- d$status
  invalid(fine_gray_fit(Surv(start, stop, code) ~ x1, d))
  invalid(fine_gray_fit(Surv(start, stop, cause) ~ x1 + offset(x2), d))
  invalid(fine_gray_fit(data = d, ties = "exact"))
  invalid(fine_gray_fit(data = d, id = NULL))
  invalid(fine_gray_fit(data = d, max_iter = 0))
  # A missing value anywhere in the model drops its row: here, whole subjects, so that the rest stays valid.
  dropped <- d$id %in% c(4, 9, 15)
  complete <- fine_gray_fit(data = d[!dropped, ])
  d$x1[d$id == 4] <- NA
  d$w[d$id == 9] <- NA
  d$cause[d$id == 15] <- NA
  fit <- fine_gray_fit(data = d)
  expect_identical(fit$coefficients, complete$coefficients)
  expect_identical(nrow(d) - fit$n_obs, sum(dropped))
})

test_that("a single event type is fitted as pprof_py fits it: the Cox model clustered by subject (DEC-123)", {
  d <- fine_gray_data(split = FALSE, late = 0)
  d$single <- factor(as.integer(d$cause == "1"), levels = 0:1)
  fit <- fit_fine_gray(Surv(stop, single) ~ x1, d, "provider", cause = 1, id = "id", weights = "w")
  cox <- fit_cox_stratified(Surv(stop, single == "1") ~ x1, d, "provider", weights = "w", cluster = "id")
  expect_equal(fit$coefficients, cox$coefficients, tolerance = 1e-12)
  expect_equal(fit$vcov, cox$vcov, tolerance = 1e-12)
  expect_identical(fit$n_competing, 0L)
})

test_that("equal case weights leave the coefficients unchanged, and weights multiply the transform's only", {
  d <- fine_gray_data()
  d$w <- 1
  unweighted <- fine_gray_fit(data = d, weights = NULL)
  d$w <- 2.5
  scaled <- fine_gray_fit(data = d)
  expect_equal(scaled$coefficients, unweighted$coefficients, tolerance = 1e-12)
  expect_identical(scaled$n_expanded, unweighted$n_expanded)
})

test_that("times are compared exactly (timefix = FALSE, M-23)", {
  d <- fine_gray_data(split = FALSE, late = 0)
  # Times in years, and in each provider two events at times that differ by a relative 1e-12, as two
  # computations of the same date can give.
  d$years <- d$stop / 365.25
  for (p in unique(d$provider)) {
    events <- which(d$provider == p & d$cause != "0")
    d$years[events[2]] <- d$years[events[1]] * (1 + 1e-12)
  }
  fit <- fit_fine_gray(Surv(years, cause) ~ x1, d, "provider", cause = 1, weights = "w")
  prepared <- fine_gray_prepare(Surv(years, cause) ~ x1, d, weights = "w")
  exact <- fine_gray_direct_coxph(prepared, fine_gray_direct_expansion(prepared, 1), "breslow")
  expect_identical(fit$coefficients, coef(exact))
  # finegray()'s default timefix = TRUE merges the near ties and gives another fit.
  frame <- data.frame(.stop = prepared$stop, .status = factor(prepared$response, levels = 0:2),
                      .row = seq_along(prepared$response), .provider = prepared$provider_index)
  f <- stats::as.formula("Surv(.stop, .status) ~ .row + strata(.provider)",
                         env = list2env(list(Surv = survival::Surv, strata = survival::strata), parent = globalenv()))
  merged <- survival::finegray(f, data = frame, etype = "1")
  merged_expansion <- list(row = merged$.row, start = merged$fgstart, stop = merged$fgstop, status = merged$fgstatus,
                           weight = merged$fgwt * prepared$weights[merged$.row])
  expect_false(identical(coef(fine_gray_direct_coxph(prepared, merged_expansion, "breslow")), fit$coefficients))
})

test_that("metamorphic: row order, provider labels, covariate order, subject labels, and time scale", {
  d <- fine_gray_data()
  fit <- fine_gray_fit(data = d)
  # Row order: survival's sums run in another order.
  shuffled <- withr::with_seed(5, d[sample(nrow(d)), ])
  expect_equal(fine_gray_fit(data = shuffled)$coefficients, fit$coefficients, tolerance = 1e-12)
  # Provider labels that sort the same way, and subject labels: the same fit.
  relabelled <- d
  relabelled$provider <- sub("p", "h", relabelled$provider)
  relabelled$id <- relabelled$id * 7 + 1000
  expect_identical(fine_gray_fit(data = relabelled)$coefficients, fit$coefficients)
  # Covariate order.
  swapped <- fine_gray_fit(Surv(start, stop, cause) ~ x2 + x1, data = d)
  expect_equal(swapped$coefficients[c("x1", "x2")], fit$coefficients, tolerance = 1e-12)
  # Times scaled by a power of 2: exactly the same fit.
  scaled <- d
  scaled$start <- scaled$start * 4
  scaled$stop <- scaled$stop * 4
  expect_identical(fine_gray_fit(data = scaled)$coefficients, fit$coefficients)
})

test_that("the model declares coefficient inference only (M-41, D-81)", {
  fit <- fine_gray_fit(keep_data = TRUE)
  expect_identical(inference_capabilities(fit), "coef_wald")
  unsupported <- function(expr) expect_error(expr, class = "pprof_error_unsupported_inference")
  unsupported(provider_effects(fit))
  unsupported(test_providers(fit))
  unsupported(standardize_providers(fit))
  unsupported(funnel_limits(fit))
  unsupported(profile_providers(fit))
  unsupported(residuals(fit))
  unsupported(augment(fit))
  unsupported(baseline_hazard(fit))
})

test_that("coefficient tests, summary, confint, tidy, glance, and print (DEC-101, DEC-128)", {
  fit <- fine_gray_fit()
  table <- test_coefficients(fit)$table
  se <- sqrt(diag(fit$vcov))
  expect_identical(table$std_error, unname(se))
  expect_identical(table$statistic, table$estimate / table$std_error)
  expect_identical(table$p_value, 2 * stats::pnorm(abs(table$statistic), lower.tail = FALSE))
  critical <- stats::qnorm(1 - (1 - 0.95) / 2)
  expect_identical(table$lower, table$estimate - critical * table$std_error)
  expect_identical(unname(confint(fit)[, 1]), table$lower)
  expect_s3_class(summary(fit), "pprof_summary")
  expect_identical(tidy(fit)$estimate, unname(fit$coefficients))
  glance_row <- glance(fit)
  expect_named(glance_row, c("n_obs", "n_providers", "n_excluded_providers", "n_events", "n_competing", "loglik",
                             "aic", "bic", "auc", "iterations", "converged"))
  expect_identical(glance_row$n_competing, fit$n_competing)
  expect_output(print(fit), "fine_gray \\(Breslow ties\\)")
  expect_output(print(fit), "clustered by id")
  expect_output(print(fine_gray_fit(id = NULL, formula = Surv(stop, cause) ~ x1,
                                    data = fine_gray_data(split = FALSE, late = 0))),
                "one cluster per observation")
})

test_that("reaching the iteration limit warns, and verbose reports (K-133)", {
  expect_warning(fit <- fine_gray_fit(max_iter = 1), class = "pprof_warning_not_converged")
  expect_false(fit$convergence$converged)
  messages <- character()
  withCallingHandlers(
    fine_gray_fit(verbose = TRUE),
    pprof_message = function(m) {
      messages <<- c(messages, conditionMessage(m))
      invokeRestart("muffleMessage")
    }
  )
  expect_true(any(grepl("rows of the expanded data", messages)))
  expect_true(any(grepl("left out of the fit", messages)))
  expect_silent(fine_gray_fit())
})

test_that("the validator rejects inconsistent objects", {
  fit <- fine_gray_fit()
  rejected <- function(x) expect_error(validate_pprof_fine_gray(x), class = "pprof_error_invalid_input")
  x <- fit
  x$spec$family <- "cox_stratified"
  rejected(x)
  x <- fit
  x$response[1] <- 1 - x$response[1]
  rejected(x)
  x <- fit
  x$status[1] <- 7
  rejected(x)
  x <- fit
  x$cause <- "censored"
  rejected(x)
  x <- fit
  x$loglik <- 1
  rejected(x)
  x <- fit
  x$providers$n_competing <- NULL
  rejected(x)
  x <- fit
  x$provider_effects <- stats::setNames(rep(0, x$n_providers), x$providers$provider_id)
  expect_error(validate_pprof_fine_gray(x), class = "pprof_error_invalid_input")
  expect_identical(validate_pprof_fine_gray(fit), fit)
})
