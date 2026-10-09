# The survival adapter (COXPH_DESIGN §E.1; DEC-091, DEC-099, DEC-100): survival_fit() is survival's
# coxph(timefix = FALSE, robust = FALSE) on the prepared rows, bitwise (the cox_engine tier, atol and
# rtol 0), and its robust variance is coxph()'s with a cluster. test-model-cox-stratified.R and
# test-cox-reference.R test the model built from it.
local_strict_mode()

# Data with providers, delayed entry, tied integer times, non-integer weights (some 0), an offset,
# a binary covariate (which coxph() does not center), and clusters.
adapter_data <- function(n = 300, seed = 11) {
  withr::with_seed(seed, {
    provider <- sample(c("h1", "h2", "h3", "h4", "h5", "h6"), n, replace = TRUE)
    x <- round(stats::rnorm(n) * 8) / 8
    z <- stats::rbinom(n, 1, 0.4)
    entry <- ifelse(stats::runif(n) < 0.4, floor(stats::runif(n, 0, 5)), 0)
    time <- entry + pmax(1, ceiling(stats::rexp(n, 0.1 * exp(0.4 * x - 0.3 * z))))
    status <- stats::rbinom(n, 1, 0.7)
    data.frame(provider = provider, x = x, z = z, entry = entry, time = time, status = status,
               w = sample(c(0, 0.5, 1, 1.5, 2), n, replace = TRUE, prob = c(0.05, 0.25, 0.4, 0.2, 0.1)),
               o = round(stats::runif(n, -1, 1) * 4) / 4, patient = sample(40, n, replace = TRUE))
  })
}

adapter_prepare <- function(formula, data = adapter_data(), ...) {
  data_prepare(formula, data, "provider", event_counts = TRUE, response_type = "survival", allow_offset = TRUE, ...)
}

# coxph() on the rows survival_fit() fits, in their prepared order.
adapter_coxph <- function(prepared, ties, control, cluster = NULL) {
  rows <- survival_fit_rows(prepared)
  d <- data.frame(start = prepared$start[rows], stop = prepared$stop[rows], status = prepared$response[rows],
                  provider = prepared$provider_index[rows])
  covariates <- colnames(prepared$design)
  for (name in covariates) d[[name]] <- unname(prepared$design[rows, name])
  terms <- c(covariates, "strata(provider)")
  if (!is.null(prepared$offset)) {
    d$o <- prepared$offset[rows]
    terms <- c(terms, "offset(o)")
  }
  counting <- identical(prepared$settings$survival_type, "counting")
  f <- stats::as.formula(paste(if (counting) "Surv(start, stop, status)" else "Surv(stop, status)", "~",
                               paste(terms, collapse = " + ")),
                         env = list2env(list(Surv = survival::Surv, strata = survival::strata), parent = environment()))
  args <- list(f, data = d, ties = ties, robust = !is.null(cluster), control = control)
  if (!is.null(prepared$weights)) args$weights <- prepared$weights[rows]
  if (!is.null(cluster)) args$cluster <- cluster
  do.call(survival::coxph, args)
}

test_that("the fit is coxph()'s, bitwise, for both data types and tie methods (cox_engine)", {
  formulas <- list(Surv(time, status) ~ x + z, Surv(entry, time, status) ~ x + z + offset(o))
  for (formula in formulas) {
    for (weights in list(NULL, "w")) {
      prepared <- adapter_prepare(formula, weights = weights)
      for (ties in c("breslow", "efron")) {
        for (tol in c(1e-9, 1e-11)) {
          label <- sprintf("%s, weights %s, %s, tol %g", deparse1(formula), !is.null(weights), ties, tol)
          fit <- survival_fit(prepared, ties, robust = FALSE, max_iter = 100, tol = tol)
          control <- survival::coxph.control(eps = tol, iter.max = 100, timefix = FALSE)
          direct <- adapter_coxph(prepared, ties, control)
          expect_identical(fit$coefficients, coef(direct), label = paste(label, "coefficients"))
          expect_identical(unname(fit$vcov), unname(direct$var), label = paste(label, "variance"))
          expect_identical(fit$loglik, direct$loglik, label = paste(label, "log-likelihoods"))
          expect_identical(fit$convergence$iterations, direct$iter, label = paste(label, "iterations"))
          expect_identical(fit$martingale_residuals[survival_fit_rows(prepared)], unname(direct$residuals),
                           label = paste(label, "martingale residuals"))
          expect_identical(fit$linear_predictor, unname(drop(prepared$design %*% coef(direct))), label = label)
        }
      }
    }
  }
})

test_that("the robust variance is coxph()'s with one cluster per row, or the cluster column (DEC-099)", {
  for (formula in list(Surv(time, status) ~ x + z, Surv(entry, time, status) ~ x + z + offset(o))) {
    prepared <- adapter_prepare(formula, weights = "w", cluster = "patient")
    rows <- survival_fit_rows(prepared)
    for (ties in c("breslow", "efron")) {
      control <- survival::coxph.control(eps = 1e-9, iter.max = 20, timefix = FALSE)
      clustered <- survival_fit(prepared, ties, robust = TRUE, max_iter = 20, tol = 1e-9)
      direct <- adapter_coxph(prepared, ties, control, cluster = prepared$cluster[rows])
      expect_identical(unname(clustered$vcov), unname(direct$var), label = paste(ties, "clustered"))
      expect_identical(unname(clustered$naive_vcov), unname(direct$naive.var), label = paste(ties, "naive"))
      per_row <- survival_fit(adapter_prepare(formula, weights = "w"), ties, robust = TRUE, max_iter = 20, tol = 1e-9)
      direct <- adapter_coxph(prepared, ties, control, cluster = seq_along(rows))
      expect_identical(unname(per_row$vcov), unname(direct$var), label = paste(ties, "per row"))
      expect_identical(dimnames(per_row$vcov), list(c("x", "z"), c("x", "z")))
    }
  }
})

test_that("rows with weight 0 are left out of the fit and kept in the data (M-25, D-58)", {
  d <- adapter_data()
  prepared <- adapter_prepare(Surv(time, status) ~ x + z, d, weights = "w")
  without <- adapter_prepare(Surv(time, status) ~ x + z, d[d$w > 0, ], weights = "w")
  for (ties in c("breslow", "efron")) {
    fit <- survival_fit(prepared, ties, robust = FALSE, max_iter = 20, tol = 1e-9)
    reference <- survival_fit(without, ties, robust = FALSE, max_iter = 20, tol = 1e-9)
    expect_identical(fit$coefficients, reference$coefficients)
    expect_identical(fit$vcov, reference$vcov)
    expect_identical(fit$loglik, reference$loglik)
    expect_identical(fit$n_zero_weight, sum(d$w == 0))
    expect_true(all(is.na(fit$martingale_residuals[prepared$weights == 0])))
    expect_identical(fit$n_events, as.integer(sum(d$status[d$w > 0])))
  }
})

test_that("data the Cox fit cannot use raise classed errors (M-26, D-59)", {
  d <- adapter_data()
  fit <- function(data, formula = Surv(time, status) ~ x + z, ...) {
    survival_fit(adapter_prepare(formula, data, ...), "breslow", robust = FALSE, max_iter = 20, tol = 1e-9)
  }
  no_events <- d
  no_events$status <- 0
  expect_error(fit(no_events), class = "pprof_error_data")
  zero_weights <- d
  zero_weights$w <- 0
  expect_error(fit(zero_weights, weights = "w"), class = "pprof_error_data")
  events_weightless <- d
  events_weightless$w[events_weightless$status == 1] <- 0
  expect_error(fit(events_weightless, weights = "w"), class = "pprof_error_data")
  collinear <- d
  collinear$x2 <- collinear$x + collinear$z
  condition <- expect_error(fit(collinear, Surv(time, status) ~ x + z + x2), class = "pprof_error_data")
  expect_identical(condition$aliased, "x2")
  constant <- d
  constant$k <- 3
  expect_error(fit(constant, Surv(time, status) ~ x + k), class = "pprof_error_data")
  # A covariate constant within every provider is the stratified model's aliasing.
  level <- d
  level$size <- as.numeric(factor(level$provider))
  condition <- expect_error(fit(level, Surv(time, status) ~ x + size), class = "pprof_error_data")
  expect_identical(condition$aliased, "size")
  huge <- d
  huge$o <- 800
  expect_error(fit(huge, Surv(time, status) ~ x + offset(o)), class = "pprof_error_invalid_input")
})

test_that("reaching the iteration limit is recorded, not printed", {
  right <- adapter_prepare(Surv(time, status) ~ x + z)
  counting <- adapter_prepare(Surv(entry, time, status) ~ x + z)
  # tol = 1e-11, the fixtures' tight control: survival's coxph.control() warns below its Cholesky
  # tolerance, about 1.8e-12.
  for (prepared in list(right, counting)) {
    fit <- survival_fit(prepared, "efron", robust = FALSE, max_iter = 2, tol = 1e-11)
    expect_false(fit$convergence$converged)
    expect_identical(fit$convergence$iterations, 2L)
    expect_true(survival_fit(prepared, "efron", robust = FALSE, max_iter = 20, tol = 1e-9)$convergence$converged)
  }
  # survival warns only when iter.max > 1, and coxph.fit() counts one iteration more when it runs out;
  # the record holds the iterations run, at most max_iter, and whether the fit converged.
  for (prepared in list(right, counting)) {
    fit <- survival_fit(prepared, "efron", robust = FALSE, max_iter = 1, tol = 1e-11)
    expect_false(fit$convergence$converged)
    expect_identical(fit$convergence$iterations, 1L)
  }
  expect_warning(
    direct <- adapter_coxph(right, "efron", survival::coxph.control(eps = 1e-11, iter.max = 2, timefix = FALSE)),
    "Ran out of iterations"
  )
  expect_identical(direct$iter, 3L)
})

test_that("an error of survival becomes pprof_error_convergence with survival's message", {
  prepared <- adapter_prepare(Surv(time, status) ~ x + z)
  local_mocked_bindings(coxph.fit = function(...) stop("simulated failure"), .package = "survival")
  condition <- expect_error(survival_fit(prepared, "breslow", robust = FALSE, max_iter = 20, tol = 1e-9),
                            class = "pprof_error_convergence")
  expect_identical(condition$engine_message, "simulated failure")
})

test_that("without covariates nothing is estimated, and the log-likelihood is survival's", {
  for (formula in list(Surv(time, status) ~ 1, Surv(entry, time, status) ~ offset(o))) {
    prepared <- adapter_prepare(formula, weights = "w")
    fit <- survival_fit(prepared, "breslow", robust = TRUE, max_iter = 20, tol = 1e-9)
    direct <- adapter_coxph(prepared, "breslow", survival::coxph.control(timefix = FALSE))
    expect_identical(fit$coefficients, stats::setNames(numeric(), character()))
    expect_identical(dim(fit$vcov), c(0L, 0L))
    expect_identical(fit$loglik, rep(direct$loglik, 2L))
    expect_identical(fit$martingale_residuals[survival_fit_rows(prepared)], unname(direct$residuals))
    # survival does not iterate; pprof_py reports one iteration.
    expect_identical(fit$convergence$iterations, 1L)
    expect_true(fit$convergence$converged)
  }
})

test_that("survival's coxph() object of the prepared data refits the model, bitwise", {
  for (formula in list(Surv(time, status) ~ x + z, Surv(entry, time, status) ~ x + z + offset(o))) {
    prepared <- adapter_prepare(formula, weights = "w")
    for (ties in c("breslow", "efron")) {
      fit <- survival_fit(prepared, ties, robust = FALSE, max_iter = 20, tol = 1e-9)
      engine <- survival_engine_fit(prepared, ties, max_iter = 20, tol = 1e-9)
      expect_s3_class(engine, "coxph")
      expect_identical(unname(coef(engine)), unname(fit$coefficients))
      expect_identical(unname(engine$var), unname(fit$vcov))
      expect_identical(engine$loglik, fit$loglik)
      expect_null(engine$naive.var)
      # The object's call names its data rather than holding it.
      expect_identical(engine$call$data, quote(frame))
    }
  }
})
