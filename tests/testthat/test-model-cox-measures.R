# The closed-form sums of the Cox measures (R/model-cox-measures.R; K-136 to K-138; the CoxPH brief's
# §6 C): expected counts by hand, against survival's Breslow estimator, the identity sum_j E_j = O, and
# the direct counts against their second form. Their agreement with pprof_py is tested on the Cox
# fixtures (test-cox-reference.R).
local_strict_mode()

closed_form <- reference_tolerance("closed_form")
expect_closed_form <- function(a, b, label = "") {
  expect(all(abs(a - b) <= closed_form$atol + closed_form$rtol * abs(b)),
         sprintf("%s differs beyond the closed_form tier (largest difference %.3g)", label, max(abs(a - b))))
}

# Six rows: two tied events at t = 2, a row entering at 2 (not at risk then, K-131), a row leaving
# before any event, and providers A (rows 1 to 3) and B (rows 4 to 6, no events).
six <- data.frame(start = c(0, 0, 2, 0, 1, 0), stop = c(2, 2, 5, 3, 5, 1), event = c(1, 1, 1, 0, 0, 0),
                  eta = c(0.5, -0.3, 0.1, 0, 0.7, -1), provider = c(1L, 1L, 1L, 2L, 2L, 2L))

test_that("expected counts at the national baseline, by hand (K-136, K-137)", {
  r <- exp(six$eta)
  at_2 <- r[1] + r[2] + r[4] + r[5]
  at_5 <- r[3] + r[5]
  lambda_2 <- 2 / at_2
  lambda_5 <- lambda_2 + 1 / at_5
  by_hand <- c(r[1] * lambda_2, r[2] * lambda_2, r[3] * (lambda_5 - lambda_2), r[4] * lambda_2, r[5] * lambda_5, 0)
  expected <- cox_expected_events(six$eta, six$start, six$stop, six$event)
  expect_closed_form(expected, by_hand, "expected events")
  expect_identical(expected[6], 0)
  expect_closed_form(sum(expected), 3, "their sum")
  # A common factor in exp(eta) changes nothing.
  expect_closed_form(cox_expected_events(six$eta + 40, six$start, six$stop, six$event), expected, "shifted")
})

test_that("direct expected counts, by hand and in their second form (K-138)", {
  model <- list(linear_predictor = six$eta, offset = NULL, provider_index = six$provider, response = six$event,
                start = six$start, stop = six$stop)
  r <- exp(six$eta)
  by_hand <- 2 * (r[1] + r[2] + r[4] + r[5]) / (r[1] + r[2]) + (r[3] + r[5]) / r[3]
  expect_closed_form(cox_direct_expected(model, 1:2), c(by_hand, 0), "direct expected events")
  expect_identical(cox_direct_expected(model, 2L), 0)
})

test_that("the fit's expected events are survival's Breslow estimator at its coefficients (K-136, M-29)", {
  d <- cox_profile_data()
  for (ties in c("breslow", "efron")) {
    fit <- fit_cox_stratified(Surv(entry, time, status) ~ x + z + offset(o), d, "provider", weights = "w",
                              ties = ties)
    eta <- fit$linear_predictor + fit$offset
    # Every row counts, those with weight 0 too, unweighted, with Breslow's baseline whatever the ties.
    expect_closed_form(fit$expected_events, cox_survival_expected(eta, fit$start, fit$stop, fit$response),
                       paste(ties, "expected events"))
    expect_closed_form(sum(fit$expected_events), sum(fit$response), paste(ties, "sum"))
    expect_true(all(fit$expected_events[fit$weights == 0] >= 0))
    expect_identical(fit$expected_events[fit$provider_index == match("p10", fit$providers$provider_id)],
                     rep(0, sum(d$provider == "p10")))
  }
  # Right-censored data: starts at 0.
  right <- fit_cox_stratified(Surv(time, status) ~ x + z, d, "provider")
  expect_closed_form(right$expected_events,
                     cox_survival_expected(right$linear_predictor, right$start, right$stop, right$response),
                     "right-censored")
})

test_that("the national baseline is survival's, allowing for its offset factor (the brief's §6 C, D-60)", {
  d <- cox_profile_data()
  fit <- fit_cox_stratified(Surv(entry, time, status) ~ x + z + offset(o), d, "provider")
  eta <- fit$linear_predictor + fit$offset
  null <- survival::coxph(survival::Surv(fit$start, fit$stop, fit$response) ~ offset(eta), ties = "breslow",
                          control = survival::coxph.control(timefix = FALSE))
  # survfit() of a model without covariates gives the curve at the offsets' mean (D-75); survival 3.8-12
  # calls rep(length = n) there, which strict mode's partial-matching warning would turn into an error.
  curve <- suppressWarnings(survival::survfit(null))
  cumulative <- function(t) c(0, curve$cumhaz)[findInterval(t, curve$time) + 1L]
  from_survival <- exp(eta - mean(eta)) * (cumulative(fit$stop) - cumulative(fit$start))
  expect_closed_form(fit$expected_events, from_survival, "expected events from survfit()")
})

test_that("direct expected counts equal their second form on a fit (K-138)", {
  d <- cox_profile_data()
  fit <- fit_cox_stratified(Surv(entry, time, status) ~ x + z + offset(o), d, "provider", weights = "w")
  rows <- seq_len(nrow(fit$providers))
  direct <- cox_direct_expected(fit, rows)
  r <- exp(fit$linear_predictor + fit$offset)
  second <- vapply(rows, function(j) {
    own <- fit$provider_index == j
    times <- sort(unique(fit$stop[own & fit$response == 1]))
    if (length(times) == 0L) return(0)
    increments <- vapply(times, function(t) {
      sum(fit$response[own] == 1 & fit$stop[own] == t) / sum(r[own] * (fit$start[own] < t & t <= fit$stop[own]))
    }, numeric(1))
    baseline <- function(t) c(0, cumsum(increments))[findInterval(t, times) + 1L]
    sum(r * (baseline(fit$stop) - baseline(fit$start)))
  }, numeric(1))
  expect_closed_form(direct, second, "direct expected events")
  # Providers without events have none; providers with events have some.
  expect_identical(direct[fit$providers$n_events == 0], c(0, 0))
  expect_true(all(direct[fit$providers$n_events > 0] > 0))
})
