# The provider-stratified Cox model (COXPH_DESIGN §B, §D; DEC-099 to DEC-103): the fit function,
# its object, its contract, its methods, the register entries C2 implements without fixtures
# (D-58, D-59, D-60, D-62, D-63, D-64, D-74), and the fit's part of the brief's metamorphic and
# edge-case tests (§6 E, F). test-model-survival.R tests the adapter, test-cox-reference.R the
# model against the Cox fixtures.
local_strict_mode()

lung <- function() survival::lung

# Data with providers, delayed entry, tied integer times, weights (some 0), an offset, and clusters.
cox_data <- function(n = 400, seed = 21) {
  withr::with_seed(seed, {
    provider <- sample(sprintf("p%02d", 1:8), n, replace = TRUE)
    x <- round(stats::rnorm(n) * 8) / 8
    z <- stats::rbinom(n, 1, 0.5)
    entry <- ifelse(stats::runif(n) < 0.3, floor(stats::runif(n, 0, 4)), 0)
    time <- entry + pmax(1, ceiling(stats::rexp(n, 0.08 * exp(0.5 * x - 0.4 * z))))
    data.frame(provider = provider, x = x, z = z, entry = entry, time = time, status = stats::rbinom(n, 1, 0.7),
               w = sample(c(0, 0.5, 1, 2), n, replace = TRUE, prob = c(0.05, 0.3, 0.5, 0.15)),
               o = round(stats::runif(n, -1, 1) * 4) / 4, patient = sample(60, n, replace = TRUE))
  })
}

# The parts of two fits that must be identical for the fits to be the same.
expect_same_fit <- function(a, b, label = "") {
  expect_identical(coef(a), coef(b), label = paste(label, "coefficients"))
  expect_identical(vcov(a), vcov(b), label = paste(label, "covariance"))
  expect_identical(a$loglik, b$loglik, label = paste(label, "log-likelihoods"))
  expect_identical(a$convergence$iterations, b$convergence$iterations, label = paste(label, "iterations"))
}

test_that("fit_cox_stratified() checks its arguments", {
  d <- cox_data()
  invalid <- function(expr) expect_error(expr, class = "pprof_error_invalid_input")
  f <- Surv(time, status) ~ x + z
  invalid(fit_cox_stratified(f, d, "provider", ties = "exact"))
  invalid(fit_cox_stratified(f, d, "provider", robust = NA))
  invalid(fit_cox_stratified(f, d, "provider", max_iter = 0))
  invalid(fit_cox_stratified(f, d, "provider", tol = 0))
  invalid(fit_cox_stratified(f, d, "provider", keep_data = "yes"))
  invalid(fit_cox_stratified(f, d, "provider", verbose = 1))
  invalid(fit_cox_stratified(status ~ x + z, d, "provider"))
  invalid(fit_cox_stratified(f, d, "hospital"))
  invalid(fit_cox_stratified(f, d, "provider", weights = "weight"))
  invalid(fit_cox_stratified(f, d, "provider", cluster = "subject"))
  d$x[3] <- Inf
  invalid(fit_cox_stratified(f, d, "provider"))
})

test_that("the object holds the fields of COXPH_DESIGN §B.2", {
  d <- cox_data()
  fit <- fit_cox_stratified(Surv(entry, time, status) ~ x + z + offset(o), d, "provider", weights = "w")
  expect_s3_class(fit, c("pprof_cox_stratified", "pprof_model"), exact = TRUE)
  expect_identical(validate_pprof_cox_stratified(fit), fit)
  expect_null(fit$provider_effects)
  expect_identical(fit$n_obs, nrow(d))
  expect_identical(fit$start, d$entry[fit$row_index])
  expect_identical(fit$stop, d$time[fit$row_index])
  expect_identical(fit$weights, d$w[fit$row_index])
  expect_identical(fit$offset, d$o[fit$row_index])
  # The status as Surv() stores it, a double.
  expect_identical(fit$response, as.double(d$status[fit$row_index]))
  expect_identical(fit$linear_predictor, unname(drop(cbind(d$x, d$z)[fit$row_index, ] %*% coef(fit))))
  expect_identical(fit$n_zero_weight, sum(d$w == 0))
  expect_identical(fit$n_events, as.integer(sum(d$status[d$w > 0])))
  expect_identical(nobs(fit), fit$n_events)
  expect_length(fit$loglik, 2L)
  expect_null(fit$naive_vcov)
  expect_null(fit$engine_fit)
  expect_null(fit$data)
  expect_identical(fit$spec[c("family", "ties", "robust", "weights", "cluster", "max_iter", "tol", "keep_data")],
                   list(family = "cox_stratified", ties = "breslow", robust = FALSE, weights = "w", cluster = NULL,
                        max_iter = 20, tol = 1e-9, keep_data = FALSE))
  expect_identical(fit$convergence$stop_rule, "relative_loglik")
  expect_true(all(c("n_events", "person_time") %in% names(fit$providers)))
  # The provider table counts every row, those with weight 0 too (M-25).
  expect_identical(sum(fit$providers$n_events), as.double(sum(d$status)))
  expect_identical(sum(fit$providers$n_obs), nrow(d))
  kept <- fit_cox_stratified(Surv(entry, time, status) ~ x + z + offset(o), d, "provider", weights = "w",
                             keep_data = TRUE)
  expect_s3_class(kept$data, "pprof_data")
  expect_s3_class(kept$engine_fit, "coxph")
  expect_identical(unname(coef(kept$engine_fit)), unname(coef(fit)))
  broken <- fit
  broken$start <- broken$stop
  expect_error(validate_pprof_cox_stratified(broken), class = "pprof_error_invalid_input")
})

test_that("a cluster implies the robust variance, and robust = TRUE alone clusters by row", {
  d <- cox_data()
  f <- Surv(time, status) ~ x + z
  clustered <- fit_cox_stratified(f, d, "provider", cluster = "patient")
  expect_true(clustered$spec$robust)
  expect_identical(clustered$naive_vcov, vcov(fit_cox_stratified(f, d, "provider")))
  per_row <- fit_cox_stratified(f, d, "provider", robust = TRUE)
  expect_false(identical(vcov(per_row), vcov(clustered)))
  expect_identical(coef(per_row), coef(clustered))
})

test_that("the model has no provider effects, and says so (DEC-102)", {
  # C3 adds the provider-level capabilities (test-profile-cox.R); the model still has no effects.
  fit <- fit_cox_stratified(Surv(time, status) ~ age + sex, lung(), "inst")
  expect_null(provider_estimates(fit))
  unsupported <- function(expr) expect_error(expr, class = "pprof_error_unsupported_inference")
  unsupported(provider_effects(fit))
  unsupported(test_coefficients(fit, "lr"))
  spec <- profile_spec(fit)
  expect_true(all(c("family", "effect", "null_default", "null_options", "indirect_numerator", "measures") %in%
                    names(spec)))
})

test_that("coefficient tests and intervals follow pprof_py's rule (DEC-101, K-148)", {
  fit <- fit_cox_stratified(Surv(time, status) ~ age + sex, lung(), "inst")
  table <- test_coefficients(fit)$table
  se <- sqrt(diag(vcov(fit)))
  expect_identical(table$std_error, unname(se))
  expect_identical(table$statistic, unname(coef(fit) / se))
  expect_identical(table$p_value, 2 * stats::pnorm(abs(table$statistic), lower.tail = FALSE))
  critical <- stats::qnorm(1 - (1 - 0.9) / 2)
  limits <- confint(fit, level = 0.9)
  expect_identical(unname(limits[, 1]), unname(coef(fit) - critical * se))
  expect_identical(unname(limits[, 2]), unname(coef(fit) + critical * se))
  expect_identical(tidy(fit)$p_value, table$p_value)
  expect_s3_class(summary(fit), "pprof_summary")
  # A large statistic keeps a p-value above 0, as pprof_py's does.
  d <- cox_data(n = 2000)
  d$time <- d$entry + pmax(1, ceiling(withr::with_seed(5, stats::rexp(nrow(d), 0.05 * exp(2 * d$x)))))
  strong <- test_coefficients(fit_cox_stratified(Surv(entry, time, status) ~ x, d, "provider"))$table
  expect_gt(abs(strong$statistic), 9)
  expect_gt(strong$p_value, 0)
})

test_that("print, glance, and augment describe the Cox fit (DEC-103)", {
  d <- cox_data()
  fit <- fit_cox_stratified(Surv(time, status) ~ x + z, d, "provider", weights = "w", ties = "efron")
  output <- capture.output(print(fit))
  expect_identical(output[1], "<pprof model: cox_stratified (Efron ties)>")
  expect_identical(output[2], sprintf("400 observations of 8 providers, %d events; %d %s", fit$n_events,
                                      fit$n_zero_weight, "observations with weight 0 left out of the fit"))
  expect_true("Variance: model-based" %in% output)
  clustered <- capture.output(print(fit_cox_stratified(Surv(time, status) ~ x, d, "provider", cluster = "patient")))
  expect_true("Variance: robust, clustered by patient" %in% clustered)
  glanced <- glance(fit)
  expect_identical(names(glanced), c("n_obs", "n_providers", "n_excluded_providers", "n_events", "loglik", "aic",
                                     "bic", "auc", "iterations", "converged"))
  direct <- survival::coxph(Surv(time, status) ~ x + z + strata(provider), data = d[d$w > 0, ], weights = w,
                            ties = "efron", robust = FALSE, control = survival::coxph.control(timefix = FALSE))
  expect_equal(glanced$aic, stats::AIC(direct), tolerance = 1e-12)
  expect_equal(glanced$bic, stats::BIC(direct), tolerance = 1e-12)
  expect_identical(glanced$n_events, fit$n_events)
  augmented <- augment(fit)
  expect_identical(names(augmented), c("row", "provider_id", "observed", "fitted", "residual"))
  expect_identical(augmented$row, seq_len(nrow(d)))
  expect_identical(augmented$observed, as.double(d$status))
  expect_identical(augmented$residual, unname(residuals(fit)))
  expect_identical(augmented$fitted, augmented$observed - augmented$residual)
  expect_true(all(is.na(augmented$fitted[d$w == 0])))
})

test_that("logLik() and nobs() follow survival's conventions for coxph()", {
  d <- cox_data()
  fit <- fit_cox_stratified(Surv(entry, time, status) ~ x + z, d, "provider")
  direct <- survival::coxph(Surv(entry, time, status) ~ x + z + strata(provider), data = d, ties = "breslow",
                            control = survival::coxph.control(timefix = FALSE))
  # coxph() here has the rows in the data's order, not sorted by provider: equal to rounding.
  expect_equal(as.numeric(logLik(fit)), as.numeric(logLik(direct)), tolerance = 1e-12)
  expect_identical(attr(logLik(fit), "df"), attr(logLik(direct), "df"))
  expect_identical(nobs(fit), as.integer(stats::nobs(direct)))
})

test_that("residuals and curves need the data or keep_data = TRUE, and check the data (DEC-005)", {
  d <- cox_data()
  f <- Surv(time, status) ~ x + z + offset(o)
  fit <- fit_cox_stratified(f, d, "provider", weights = "w")
  kept <- fit_cox_stratified(f, d, "provider", weights = "w", keep_data = TRUE)
  expect_error(residuals(fit, type = "score"), class = "pprof_error_data_required")
  expect_error(baseline_hazard(fit), class = "pprof_error_data_required")
  for (type in c("score", "dfbeta")) {
    expect_identical(residuals(fit, type = type, data = d), residuals(kept, type = type))
  }
  expect_identical(baseline_hazard(fit, data = d), baseline_hazard(kept))
  other <- d
  other$x <- rev(other$x)
  expect_error(residuals(fit, type = "score", data = other), class = "pprof_error_invalid_input")
  expect_error(residuals(fit, type = "deviance"), class = "pprof_error_invalid_input")
  expect_error(baseline_hazard(lm(time ~ x, d)), class = "pprof_error_invalid_input")
})

test_that("residuals are survival's, in the order of the data, missing for weight 0", {
  d <- cox_data()
  fit <- fit_cox_stratified(Surv(entry, time, status) ~ x + z, d, "provider", weights = "w", keep_data = TRUE)
  fitted <- which(d$w > 0)
  direct <- survival::coxph(Surv(entry, time, status) ~ x + z + strata(provider), data = d[fitted, ], weights = w,
                            ties = "breslow", robust = FALSE, control = survival::coxph.control(timefix = FALSE))
  martingale <- residuals(fit)
  expect_identical(names(martingale), as.character(seq_len(nrow(d))))
  expect_true(all(is.na(martingale[d$w == 0])))
  expect_equal(unname(martingale[fitted]), unname(residuals(direct)), tolerance = 1e-12)
  for (type in c("score", "dfbeta")) {
    values <- residuals(fit, type = type)
    expect_identical(dim(values), c(nrow(d), 2L))
    expect_identical(colnames(values), c("x", "z"))
    expect_equal(unname(values[fitted, ]), unname(residuals(direct, type = type)), tolerance = 1e-12)
  }
})

test_that("predictions: linear predictors and risks uncentered, curves from survfit() (K-135)", {
  d <- cox_data()
  fit <- fit_cox_stratified(Surv(time, status) ~ x + z + offset(o), d, "provider", keep_data = TRUE)
  eta <- predict(fit)
  expect_identical(unname(eta), unname(drop(cbind(d$x, d$z) %*% coef(fit)) + d$o))
  expect_identical(predict(fit, type = "risk"), exp(eta))
  profiles <- data.frame(x = c(0, 1, NA), z = c(0, 1, 0), o = c(0, 0.5, 0), provider = c("p01", "p02", "p03"))
  expect_identical(predict(fit, newdata = profiles), c(0, sum(coef(fit)) + 0.5, NA))
  expect_error(predict(fit, type = "survival"), class = "pprof_error_invalid_input")
  curves <- predict(fit, newdata = profiles, type = "cumulative_hazard")
  expect_identical(names(curves), c("row", "provider_id", "time", "cumulative_hazard"))
  # The first profile is the baseline of p01; the second is p02's baseline times exp(x'beta + offset).
  baseline <- baseline_hazard(fit)
  first <- curves[curves$row == 1, ]
  expect_equal(first$cumulative_hazard, baseline$cumulative_hazard[baseline$provider_id == "p01"], tolerance = 1e-12)
  second <- curves[curves$row == 2, ]
  expect_equal(second$cumulative_hazard,
               baseline$cumulative_hazard[baseline$provider_id == "p02"] * exp(sum(coef(fit)) + 0.5), tolerance = 1e-12)
  expect_true(is.na(curves$time[curves$row == 3]))
  survival_curves <- predict(fit, newdata = profiles[1:2, ], type = "survival")
  expect_equal(survival_curves$survival, exp(-curves$cumulative_hazard[curves$row < 3]), tolerance = 1e-12)
  unknown <- profiles[1, ]
  unknown$provider <- "elsewhere"
  expect_warning(curves <- predict(fit, newdata = unknown, type = "survival"),
                 class = "pprof_warning_unknown_providers")
  expect_true(is.na(curves$survival))
})

test_that("the baseline is at offset 0: a constant c added to the offset scales it by exp(-c) (M-28, D-60)", {
  d <- cox_data()
  fit <- fit_cox_stratified(Surv(time, status) ~ x + z + offset(o), d, "provider", keep_data = TRUE)
  d$shifted <- d$o + 1.5
  shifted <- fit_cox_stratified(Surv(time, status) ~ x + z + offset(shifted), d, "provider", keep_data = TRUE)
  expect_equal(coef(shifted), coef(fit), tolerance = 1e-12)
  a <- baseline_hazard(fit)
  b <- baseline_hazard(shifted)
  expect_identical(a[c("provider_id", "time")], b[c("provider_id", "time")])
  expect_equal(b$cumulative_hazard, a$cumulative_hazard * exp(-1.5), tolerance = 1e-10)
  # survival's basehaz(centered = FALSE) carries exp(the weighted mean offset), which the shift
  # leaves unchanged, as pprof_py's baseline_hazard_ does.
  basehaz_a <- survival::basehaz(fit$engine_fit, centered = FALSE)
  basehaz_b <- survival::basehaz(shifted$engine_fit, centered = FALSE)
  expect_equal(basehaz_b$hazard, basehaz_a$hazard, tolerance = 1e-10)
  # Providers without events among the fitted rows have no rows.
  expect_setequal(unique(a$provider_id), fit$providers$provider_id[fit$providers$n_events > 0])
})

test_that("zero weights leave rows out of the fit and in the provider table (M-25, D-58)", {
  d <- cox_data()
  for (ties in c("breslow", "efron")) {
    fit <- fit_cox_stratified(Surv(entry, time, status) ~ x + z, d, "provider", weights = "w", ties = ties)
    without <- fit_cox_stratified(Surv(entry, time, status) ~ x + z, d[d$w > 0, ], "provider", weights = "w",
                                  ties = ties)
    expect_same_fit(fit, without, ties)
    expect_identical(fit$n_obs, nrow(d))
    expect_identical(sum(fit$providers$n_obs), nrow(d))
  }
})

test_that("missing values drop their rows (K-03, D-62)", {
  d <- cox_data()
  incomplete <- d
  incomplete$time[3] <- NA
  incomplete$status[8] <- NA
  incomplete$x[12] <- NA
  incomplete$w[20] <- NA
  incomplete$o[25] <- NA
  incomplete$patient[30] <- NA
  f <- Surv(time, status) ~ x + z + offset(o)
  fit <- fit_cox_stratified(f, incomplete, "provider", weights = "w", cluster = "patient")
  complete <- fit_cox_stratified(f, d[-c(3, 8, 12, 20, 25, 30), ], "provider", weights = "w", cluster = "patient")
  expect_same_fit(fit, complete)
  expect_identical(fit$data_spec$weights, "w")
})

test_that("a status coded 1/2, or logical, gives the fit of 0/1 (D-74)", {
  d <- cox_data()
  reference <- fit_cox_stratified(Surv(time, status) ~ x + z, d, "provider")
  d$status_12 <- d$status + 1
  d$status_lgl <- d$status == 1
  expect_same_fit(fit_cox_stratified(Surv(time, status_12) ~ x + z, d, "provider"), reference, "1/2")
  expect_same_fit(fit_cox_stratified(Surv(time, status_lgl) ~ x + z, d, "provider"), reference, "logical")
  # One of several events, the others censored: the cause-specific model (M-35).
  d$cause <- ifelse(d$status == 1, 1 + d$z, 0)
  expect_same_fit(fit_cox_stratified(Surv(time, cause == 1) ~ x, d, "provider"),
                  fit_cox_stratified(Surv(time, as.numeric(cause == 1)) ~ x, d, "provider"), "cause")
})

test_that("covariates the stratified fit cannot estimate, and data without events, are errors (M-26, D-59)", {
  d <- cox_data()
  d$sum <- d$x + d$z
  d$constant <- 2
  d$size <- as.numeric(factor(d$provider))
  for (formula in list(Surv(time, status) ~ x + z + sum, Surv(time, status) ~ x + constant,
                       Surv(time, status) ~ x + size)) {
    expect_error(fit_cox_stratified(formula, d, "provider"), class = "pprof_error_data")
  }
  d$status <- 0
  expect_error(fit_cox_stratified(Surv(time, status) ~ x, d, "provider"), class = "pprof_error_data")
})

test_that("the formula, not the order of the data's columns, determines the fit (D-63)", {
  d <- cox_data()
  reference <- fit_cox_stratified(Surv(entry, time, status) ~ x + z + offset(o), d, "provider", weights = "w")
  expect_same_fit(fit_cox_stratified(Surv(entry, time, status) ~ x + z + offset(o), d[rev(names(d))], "provider",
                                     weights = "w"), reference)
})

test_that("a covariate of large mean gives survival's fit and finite residuals (D-64)", {
  d <- cox_data()
  d$year <- 3000 + d$x
  fit <- fit_cox_stratified(Surv(time, status) ~ year + z, d, "provider", keep_data = TRUE)
  direct <- survival::coxph(Surv(time, status) ~ year + z + strata(provider), data = d, ties = "breslow",
                            control = survival::coxph.control(timefix = FALSE))
  expect_identical(unname(coef(fit)), unname(coef(direct)))
  expect_true(all(is.finite(residuals(fit))))
  expect_true(all(is.finite(residuals(fit, type = "dfbeta"))))
  expect_true(all(is.finite(vcov(fit_cox_stratified(Surv(time, status) ~ year + z, d, "provider", robust = TRUE)))))
  # Uncentered, the risk is exp() of the linear predictor, which overflows above log(.Machine$double.xmax).
  eta <- predict(fit)
  expect_identical(predict(fit, type = "risk"), exp(eta))
  expect_identical(is.finite(exp(eta)), eta < log(.Machine$double.xmax))
})

test_that("reordered providers, relabelled providers, and doubled times give the same fit (§6 E)", {
  d <- cox_data()
  f <- Surv(entry, time, status) ~ x + z + offset(o)
  reference <- fit_cox_stratified(f, d, "provider", weights = "w", ties = "efron")
  # The providers' blocks in another order, and labels that keep the providers' order.
  blocks <- d[order(match(d$provider, rev(sort(unique(d$provider)))), seq_len(nrow(d))), ]
  expect_same_fit(fit_cox_stratified(f, blocks, "provider", weights = "w", ties = "efron"), reference, "blocks")
  relabelled <- d
  relabelled$provider <- paste0("hospital ", relabelled$provider)
  expect_same_fit(fit_cox_stratified(f, relabelled, "provider", weights = "w", ties = "efron"), reference, "labels")
  doubled <- d
  doubled$entry <- 2 * doubled$entry
  doubled$time <- 2 * doubled$time
  expect_same_fit(fit_cox_stratified(f, doubled, "provider", weights = "w", ties = "efron"), reference, "times")
})

test_that("shuffled rows, and duplicated rows against weight 2, give the fit to rounding (§6 E)", {
  d <- cox_data()
  d$w[d$w == 0] <- 1
  f <- Surv(entry, time, status) ~ x + z
  tier <- reference_tolerance("cox_coefficient")
  reference <- fit_cox_stratified(f, d, "provider", max_iter = 100, tol = 1e-11)
  shuffled <- d[withr::with_seed(3, sample(nrow(d))), ]
  expect_null(reference_compare(unname(coef(fit_cox_stratified(f, shuffled, "provider", max_iter = 100, tol = 1e-11))),
                                unname(coef(reference)), tier))
  twice <- d[c(seq_len(nrow(d)), 1:50), ]
  d$double <- ifelse(seq_len(nrow(d)) <= 50, 2, 1)
  duplicated <- fit_cox_stratified(f, twice, "provider", max_iter = 100, tol = 1e-11)
  weighted <- fit_cox_stratified(f, d, "provider", weights = "double", max_iter = 100, tol = 1e-11)
  expect_null(reference_compare(unname(coef(duplicated)), unname(coef(weighted)), tier))
})

test_that("edge cases of the data: one-row and event-free providers, entry at an event time (§6 F)", {
  d <- cox_data()
  d$provider[1] <- "single"
  d$status[d$provider == "p08"] <- 0
  fit <- fit_cox_stratified(Surv(entry, time, status) ~ x + z, d, "provider", keep_data = TRUE)
  expect_identical(fit$providers$n_obs[fit$providers$provider_id == "single"], 1L)
  expect_identical(fit$providers$n_events[fit$providers$provider_id == "p08"], 0)
  expect_false("p08" %in% baseline_hazard(fit)$provider_id)
  # A row that enters at an event time is not at risk at it (K-131): survival's risk set.
  d$entry[2] <- d$time[d$status == 1][1]
  d$time[2] <- d$entry[2] + 5
  direct <- survival::coxph(Surv(entry, time, status) ~ x + z + strata(provider), data = d, ties = "breslow",
                            control = survival::coxph.control(timefix = FALSE))
  expect_equal(unname(coef(fit_cox_stratified(Surv(entry, time, status) ~ x + z, d, "provider"))),
               unname(coef(direct)), tolerance = 1e-12)
  # A provider all of whose rows have weight 0 is in the table and not in the fit.
  d$w <- 1
  d$w[d$provider == "p07"] <- 0
  weighted <- fit_cox_stratified(Surv(entry, time, status) ~ x + z, d, "provider", weights = "w")
  expect_true("p07" %in% weighted$providers$provider_id)
  expect_identical(weighted$n_zero_weight, sum(d$provider == "p07"))
})

test_that("separation passes survival's warning, and the iteration limit warns once", {
  d <- cox_data(n = 200)
  d$separating <- as.numeric(d$status == 1 & d$time < 5)
  warnings <- character()
  withCallingHandlers(
    fit_cox_stratified(Surv(time, status) ~ separating, d, "provider", max_iter = 50),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  expect_true(any(grepl("may be infinite", warnings, fixed = TRUE)), label = paste(warnings, collapse = "; "))
  expect_warning(fit_cox_stratified(Surv(time, status) ~ x + z, d, "provider", max_iter = 1),
                 class = "pprof_warning_not_converged")
  fit <- suppressWarnings(fit_cox_stratified(Surv(time, status) ~ x + z, d, "provider", max_iter = 1))
  expect_false(fit$convergence$converged)
  expect_identical(fit$convergence$iterations, 1L)
  expect_true(any(startsWith(capture.output(print(fit)), "Not converged after 1 iterations")))
})

test_that("without covariates the fit holds the log-likelihood of the offsets alone", {
  d <- cox_data()
  fit <- fit_cox_stratified(Surv(time, status) ~ offset(o), d, "provider", keep_data = TRUE)
  expect_identical(coef(fit), stats::setNames(numeric(), character()))
  expect_identical(fit$loglik[1], fit$loglik[2])
  expect_identical(fit$convergence$iterations, 1L)
  expect_identical(nrow(test_coefficients(fit)$table), 0L)
  expect_identical(dim(residuals(fit, type = "score")), c(nrow(d), 0L))
  expect_identical(unname(predict(fit)), d$o[fit$row_index][order(fit$row_index)])
  # survival's survfit() gives no curves for new data of a model without covariates (D-75).
  expect_error(baseline_hazard(fit), class = "pprof_error_unsupported_inference")
  expect_error(predict(fit, newdata = d[1:2, ], type = "survival"), class = "pprof_error_unsupported_inference")
})

test_that("verbose reports the fit through pprof messages", {
  d <- cox_data()
  messages <- character()
  withCallingHandlers(
    fit_cox_stratified(Surv(time, status) ~ x, d, "provider", weights = "w", verbose = TRUE),
    pprof_message = function(m) {
      messages <<- c(messages, conditionMessage(m))
      invokeRestart("muffleMessage")
    }
  )
  expect_length(messages, 3L)
  expect_true(any(grepl("weight 0", messages, fixed = TRUE)))
  expect_silent(fit_cox_stratified(Surv(time, status) ~ x, d, "provider"))
})
