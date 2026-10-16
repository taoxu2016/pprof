# The survival adapter (COXPH_DESIGN §E.1; DEC-091, DEC-099, DEC-100): survival_fit() is survival's
# coxph(timefix = FALSE, robust = FALSE) on the prepared rows, bitwise (the cox_engine tier, atol and
# rtol 0), and its robust variance is coxph()'s with a cluster. test-model-cox-stratified.R and
# test-cox-reference.R test the model built from it. From Phase C5, the Fine-Gray part: its expansion is
# one stratified finegray() call's in chunks of any size, and its fit coxph(cluster = id)'s on the
# expansion, bitwise (DEC-121 to DEC-124); test-model-fine-gray.R tests the model.
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

test_that("a cluster column that is a factor keeps its codes, as coxph() codes it (DEC-100)", {
  d <- adapter_data()
  # Levels in another order than the clusters' first appearance, with a level no row has.
  d$patient <- factor(d$patient, levels = c(rev(sort(unique(d$patient))), 99L))
  for (formula in list(Surv(time, status) ~ x + z, Surv(entry, time, status) ~ x + z + offset(o))) {
    prepared <- adapter_prepare(formula, data = d, weights = "w", cluster = "patient")
    expect_true(is.factor(prepared$cluster))
    rows <- survival_fit_rows(prepared)
    for (ties in c("breslow", "efron")) {
      control <- survival::coxph.control(eps = 1e-9, iter.max = 20, timefix = FALSE)
      clustered <- survival_fit(prepared, ties, robust = TRUE, max_iter = 20, tol = 1e-9)
      direct <- adapter_coxph(prepared, ties, control, cluster = prepared$cluster[rows])
      expect_identical(unname(clustered$vcov), unname(direct$var), label = paste(ties, "factor clusters"))
      expect_identical(unname(clustered$naive_vcov), unname(direct$naive.var), label = paste(ties, "naive"))
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

# --- The Fine-Gray model (the CoxPH C5 plan, §3.2 and §4.3; DEC-121 to DEC-124) --------------------

test_that("the transform is one stratified finegray() call's, bitwise, in chunks of any size (DEC-122, DEC-123)", {
  cases <- list(
    list(formula = Surv(stop, cause) ~ x1, data = fine_gray_data(split = FALSE, late = 0), id = NULL),
    list(formula = Surv(start, stop, cause) ~ x1 + x2, data = fine_gray_data(), id = "id")
  )
  for (case in cases) {
    for (weights in list(NULL, "w")) {
      prepared <- fine_gray_prepare(case$formula, case$data, weights = weights, cluster = case$id)
      for (cause in 1:2) {
        direct <- fine_gray_direct_expansion(prepared, cause)
        for (size in c(1L, 2L, 4L, 50L)) {
          label <- sprintf("%s, weights %s, cause %d, chunks of %d", deparse1(case$formula), !is.null(weights), cause,
                           size)
          expansion <- survival_fine_gray_expand(prepared, cause, survival_fine_gray_subjects(prepared), size)
          expect_identical(expansion, direct, label = label)
        }
      }
    }
  }
})

test_that("chunks without events of the cause are skipped, as finegray() leaves their providers out (DEC-122)", {
  d <- fine_gray_data()
  # Providers p01 and p02 without events of cause 1: theirs become censoring. With delayed entry, they can
  # still be the chunks' anchors.
  d$cause[d$provider %in% c("p01", "p02") & d$cause == "1"] <- "0"
  prepared <- fine_gray_prepare(Surv(start, stop, cause) ~ x1 + x2, d, weights = "w", cluster = "id")
  direct <- fine_gray_direct_expansion(prepared, 1)
  expect_false(any(prepared$provider_index[direct$row] %in% 1:2))
  for (size in c(1L, 2L, 3L, 50L)) {
    expansion <- survival_fine_gray_expand(prepared, 1, survival_fine_gray_subjects(prepared), size)
    expect_identical(expansion, direct, label = sprintf("chunks of %d", size))
  }
})

test_that("each chunk decides delayed entry as all rows do (DEC-122)", {
  # Provider 1's own rows have no late entry, and its entry time 10 equals a competing event time;
  # provider 2's rows make the whole data's entry delayed (dev/design/coxph-facts/31, part C).
  d <- data.frame(provider = c(1, 1, 1, 1, 1, 1, 2, 2, 2, 2), id = 1:10, start = c(0, 10, 5, 0, 0, 2, 0, 0, 4, 0),
                  stop = c(10, 30, 20, 25, 40, 35, 1, 3, 8, 12), x1 = c(1, 0, 1, 0, 1, 0, 1, 1, 0, 0))
  d$cause <- factor(c(2, 0, 1, 0, 1, 2, 0, 1, 2, 1), levels = 0:2)
  prepared <- fine_gray_prepare(Surv(start, stop, cause) ~ x1, d, cluster = "id")
  direct <- fine_gray_direct_expansion(prepared, 1)
  expect_identical(survival_fine_gray_expand(prepared, 1, survival_fine_gray_subjects(prepared), 1L), direct)
  # finegray() on provider 1 alone decides that its entry is not delayed, and expands its rows otherwise.
  alone <- fine_gray_direct_expansion(fine_gray_prepare(Surv(start, stop, cause) ~ x1, d[d$provider == 1, ],
                                                        cluster = "id"), 1)
  expect_false(identical(alone$weight, direct$weight[prepared$provider_index[direct$row] == 1]))
})

test_that("the fit is coxph(cluster = id)'s on the expansion, bitwise (DEC-121)", {
  cases <- list(
    list(formula = Surv(stop, cause) ~ x1, data = fine_gray_data(split = FALSE, late = 0), id = NULL),
    list(formula = Surv(start, stop, cause) ~ x1 + x2, data = fine_gray_data(), id = "id")
  )
  for (case in cases) {
    prepared <- fine_gray_prepare(case$formula, case$data, weights = "w", cluster = case$id)
    for (ties in c("breslow", "efron")) {
      for (cause in 1:2) {
        label <- sprintf("%s, %s, cause %d", deparse1(case$formula), ties, cause)
        fit <- survival_fine_gray_fit(prepared, cause, !is.null(case$id), ties, max_iter = 20, tol = 1e-9, size = 2L)
        direct <- fine_gray_direct_coxph(prepared, fine_gray_direct_expansion(prepared, cause), ties)
        expect_identical(fit$coefficients, coef(direct), label = paste(label, "coefficients"))
        expect_identical(unname(fit$vcov), unname(direct$var), label = paste(label, "robust variance"))
        expect_identical(unname(fit$naive_vcov), unname(direct$naive.var), label = paste(label, "model-based variance"))
        expect_identical(fit$loglik, direct$loglik, label = paste(label, "log-likelihoods"))
        expect_identical(fit$convergence$iterations, direct$iter, label = paste(label, "iterations"))
        expect_identical(fit$n_events, as.integer(direct$nevent), label = paste(label, "events"))
        expect_identical(fit$n_expanded, direct$n, label = paste(label, "expanded rows"))
        # The coxph() object of the curves refits the model, bitwise.
        engine <- survival_fine_gray_engine_fit(prepared, fit$expansion, ties, max_iter = 20, tol = 1e-9)
        expect_identical(unname(coef(engine)), unname(fit$coefficients), label = paste(label, "engine fit"))
      }
    }
  }
})

test_that("subjects given by a factor keep its codes, as coxph() codes a factor cluster (DEC-100, DEC-121)", {
  d <- fine_gray_data()
  # Levels in another order than the subjects' first appearance, with a level no row has.
  d$id <- factor(d$id, levels = c(rev(sort(unique(d$id))), 9999L))
  prepared <- fine_gray_prepare(Surv(start, stop, cause) ~ x1 + x2, d, weights = "w", cluster = "id")
  expect_true(is.factor(prepared$cluster))
  for (ties in c("breslow", "efron")) {
    fit <- survival_fine_gray_fit(prepared, 1, TRUE, ties, max_iter = 20, tol = 1e-9, size = 2L)
    direct <- fine_gray_direct_coxph(prepared, fine_gray_direct_expansion(prepared, 1), ties)
    expect_identical(fit$coefficients, coef(direct), label = paste(ties, "coefficients"))
    expect_identical(unname(fit$vcov), unname(direct$var), label = paste(ties, "robust variance"))
    expect_identical(unname(fit$naive_vcov), unname(direct$naive.var), label = paste(ties, "model-based variance"))
  }
})

test_that("rows of weight 0 stay in the transform and leave the fit (M-25, D-58)", {
  d <- fine_gray_data()
  prepared <- fine_gray_prepare(Surv(start, stop, cause) ~ x1, d, weights = "w", cluster = "id")
  subjects <- survival_fine_gray_subjects(prepared)
  weighted <- survival_fine_gray_expand(prepared, 1, subjects)
  unweighted <- survival_fine_gray_expand(fine_gray_prepare(Surv(start, stop, cause) ~ x1, d, cluster = "id"), 1,
                                          subjects)
  # The transform does not see the case weights: the same rows and times, the weights multiplied.
  expect_identical(weighted[c("row", "start", "stop", "status")], unweighted[c("row", "start", "stop", "status")])
  expect_identical(weighted$weight, unweighted$weight * prepared$weights[unweighted$row])
  expect_true(any(weighted$weight == 0))
  fit <- survival_fine_gray_fit(prepared, 1, TRUE, "breslow", max_iter = 20, tol = 1e-9)
  expect_true(all(fit$expansion$weight > 0))
  expect_identical(fit$n_zero_weight, sum(prepared$weights == 0))
  # Leaving the rows of weight 0 out of the transform too would change the censoring distribution.
  kept <- fine_gray_prepare(Surv(start, stop, cause) ~ x1, d[d$w > 0, ], weights = "w", cluster = "id")
  without <- survival_fine_gray_fit(kept, 1, TRUE, "breslow", max_iter = 20, tol = 1e-9)
  expect_false(identical(without$coefficients, fit$coefficients))
})

test_that("finegray()'s case weights would misapply after its first stratum, so they are applied after it (DEC-123)", {
  d <- fine_gray_data(split = FALSE, late = 0)
  prepared <- fine_gray_prepare(Surv(stop, cause) ~ x1, d, weights = "w")
  ours <- survival_fine_gray_expand(prepared, 1, survival_fine_gray_subjects(prepared))
  frame <- data.frame(.stop = prepared$stop, .status = factor(prepared$response, levels = 0:2),
                      .row = seq_along(prepared$response), .provider = prepared$provider_index, .w = prepared$weights)
  f <- stats::as.formula("Surv(.stop, .status) ~ .row + strata(.provider)",
                         env = list2env(list(Surv = survival::Surv, strata = survival::strata), parent = globalenv()))
  theirs <- survival::finegray(f, data = frame, etype = "1", weights = .w, timefix = FALSE)
  first <- prepared$provider_index[theirs$.row] == 1L
  expect_identical(theirs$fgwt[first], ours$weight[first])
  expect_false(identical(theirs$fgwt[!first], ours$weight[!first]))
})

test_that("weights that are not finite raise, naming the providers (D-80)", {
  # A provider of the benchmark's rows-1e4 data, where the censoring-times-entry probability is 0 at its
  # competing events (dev/design/coxph-facts/31, part D), beside a provider of larger data.
  small <- data.frame(provider = "a", id = 1:7, start = c(0, 0, 0, 192, 352, 0, 0),
                      stop = c(65, 44, 286, 250, 385, 68, 162), status = c(0, 2, 1, 2, 2, 2, 0))
  large <- fine_gray_data(subjects = 60, providers = 1, late = 0, split = FALSE)
  large <- data.frame(provider = "b", id = large$id + 100, start = large$start, stop = large$stop,
                      status = large$status)
  d <- rbind(small, large)
  d$x1 <- seq_len(nrow(d)) %% 3
  d$cause <- factor(d$status, levels = 0:2)
  prepared <- fine_gray_prepare(Surv(start, stop, cause) ~ x1, d, cluster = "id")
  direct <- fine_gray_direct_expansion(prepared, 1)
  expect_true(any(!is.finite(direct$weight)))
  condition <- expect_error(survival_fine_gray_fit(prepared, 1, TRUE, "breslow", max_iter = 20, tol = 1e-9),
                            class = "pprof_error_data")
  expect_identical(condition$providers, "a")
  # With the event of interest before its competing events, no later piece follows and every weight is
  # finite: the fit runs, where pprof_py's transform raises.
  d$stop[3] <- 30
  prepared <- fine_gray_prepare(Surv(start, stop, cause) ~ x1, d, cluster = "id")
  expect_true(all(is.finite(fine_gray_direct_expansion(prepared, 1)$weight)))
  expect_no_error(survival_fine_gray_fit(prepared, 1, TRUE, "breslow", max_iter = 20, tol = 1e-9))
})

test_that("the subjects follow pprof_py's rules, and finegray()'s own errors are classed (DEC-124)", {
  d <- fine_gray_data()
  invalid <- function(expr) expect_error(expr, class = "pprof_error_invalid_input")
  fit <- function(prepared, has_id) survival_fine_gray_fit(prepared, 1, has_id, "breslow", max_iter = 20, tol = 1e-9)
  # (start, stop] data need id when an entry time is not 0.
  invalid(fit(fine_gray_prepare(Surv(start, stop, cause) ~ x1, d), FALSE))
  # Without entry times other than 0, each observation is its own subject, and the fit is the
  # right-censored data's: finegray() starts both at 0, and both expansions are (start, stop] data.
  one <- fine_gray_data(split = FALSE, late = 0)
  counting <- fit(fine_gray_prepare(Surv(start, stop, cause) ~ x1, one), FALSE)
  right <- fit(fine_gray_prepare(Surv(stop, cause) ~ x1, one), FALSE)
  expect_identical(counting$coefficients, right$coefficients)
  expect_identical(counting$vcov, right$vcov)
  # Right-censored data have one row per subject.
  one$id[2] <- one$id[1]
  invalid(fit(fine_gray_prepare(Surv(stop, cause) ~ x1, one, cluster = "id"), TRUE))
  # A subject's rows belong to one provider.
  moved <- d
  twice <- moved$id[duplicated(moved$id)][1]
  moved$provider[moved$id == twice][1] <- if (moved$provider[moved$id == twice][2] == "p01") "p02" else "p01"
  invalid(fit(fine_gray_prepare(Surv(start, stop, cause) ~ x1, moved, cluster = "id"), TRUE))
  # finegray(): a gap in a subject's rows.
  gap <- d
  first_row <- which(gap$id == twice)[1]
  gap$start[first_row + 1L] <- gap$start[first_row + 1L] + 0.5
  condition <- expect_error(fit(fine_gray_prepare(Surv(start, stop, cause) ~ x1, gap, cluster = "id"), TRUE),
                            class = "pprof_error_invalid_input")
  expect_match(condition$engine_message, "gaps")
})

test_that("a single event type is fitted, with an unused level for finegray() (DEC-123)", {
  d <- fine_gray_data(split = FALSE, late = 0)
  d$single <- factor(as.integer(d$cause == "1"), levels = 0:1)
  prepared <- fine_gray_prepare(Surv(stop, single) ~ x1, d)
  expect_identical(prepared$settings$states, "1")
  expansion <- survival_fine_gray_expand(prepared, 1, survival_fine_gray_subjects(prepared))
  # Without competing events nothing is expanded: every observation once, with weight 1, over (0, time].
  expect_identical(sort(expansion$row), seq_along(prepared$response))
  expect_true(all(expansion$weight == 1))
  expect_identical(expansion$stop[order(expansion$row)], prepared$stop)
})

test_that("a cause without events, or without events of positive weight, raises (M-26)", {
  d <- fine_gray_data()
  prepared <- fine_gray_prepare(Surv(start, stop, cause) ~ x1, d, cluster = "id")
  d$cause[d$cause == "2"] <- "1"
  only_one <- fine_gray_prepare(Surv(start, stop, cause) ~ x1, d, cluster = "id")
  expect_error(survival_fine_gray_fit(only_one, 2, TRUE, "breslow", max_iter = 20, tol = 1e-9),
               class = "pprof_error_data")
  d <- fine_gray_data()
  d$w[d$cause == "1"] <- 0
  zero <- fine_gray_prepare(Surv(start, stop, cause) ~ x1, d, weights = "w", cluster = "id")
  expect_error(survival_fine_gray_fit(zero, 1, TRUE, "breslow", max_iter = 20, tol = 1e-9),
               class = "pprof_error_data")
  expect_no_error(survival_fine_gray_fit(prepared, 2, TRUE, "breslow", max_iter = 20, tol = 1e-9))
})
