# The glmnet adapter (R/model-glmnet.R; COXPH_DESIGN §E.2; DEC-088, DEC-113 to DEC-115) and the survival
# adapter's functions for penalized paths (R/model-survival.R).

penalized_prepared <- function(d, terms = c("x1", "x2", "x3", "x4", "x5"), weights = "w", offset = TRUE) {
  data_prepare(cox_penalized_formula(d, terms, offset), d, "provider", event_counts = TRUE, response_type = "survival",
               weights = weights, allow_offset = TRUE)
}

test_that("glmnet_require() raises a classed error naming glmnet when it is missing (DEC-088)", {
  local_mocked_bindings(glmnet_available = function() FALSE)
  expect_error(glmnet_require(), class = "pprof_error_invalid_input")
  condition <- tryCatch(glmnet_require(), error = function(e) e)
  expect_identical(condition$package, "glmnet")
})

test_that("glmnet's inputs: the rows with positive weight, the response stratified by provider", {
  skip_if_not_installed("glmnet", minimum_version = "5.0")
  d <- cox_penalized_data()
  prepared <- penalized_prepared(d)
  rows <- survival_fit_rows(prepared)
  inputs <- glmnet_inputs(prepared, rows)
  expect_identical(nrow(inputs$x), length(rows))
  expect_identical(attr(inputs$y, "strata"), as.integer(factor(prepared$provider_index[rows])))
  expect_identical(unname(unclass(inputs$y)[, "start"]), prepared$start[rows])
  expect_identical(inputs$weights, prepared$weights[rows])
  expect_identical(inputs$offset, prepared$offset[rows])
  bare <- glmnet_inputs(penalized_prepared(cox_penalized_data(counting = FALSE), weights = NULL, offset = FALSE),
                        seq_len(300))
  expect_null(bare$weights)
  expect_null(bare$offset)
  expect_identical(ncol(bare$y), 2L)
})

test_that("the weighted population variance of each column (K-143)", {
  d <- cox_penalized_data()
  x <- as.matrix(d[, c("x1", "x2", "x5")])
  w <- d$w
  by_hand <- vapply(seq_len(ncol(x)), function(j) {
    m <- sum(w * x[, j]) / sum(w)
    sum(w * (x[, j] - m)^2) / sum(w)
  }, numeric(1))
  expect_null(reference_compare(unname(glmnet_column_variance(x, w)), by_hand, reference_tolerance("closed_form")))
  unweighted <- unname(apply(x, 2, function(v) mean((v - mean(v))^2)))
  expect_null(reference_compare(unname(glmnet_column_variance(x, NULL)), unweighted,
                                reference_tolerance("closed_form")))
  # Rows with weight 0 do not count.
  expect_null(reference_compare(glmnet_column_variance(x, w), glmnet_column_variance(x[w > 0, ], w[w > 0]),
                                reference_tolerance("closed_form")))
})

test_that("the adapter's path is glmnet's, called directly with the same inputs (cox_engine)", {
  skip_if_not_installed("glmnet", minimum_version = "5.0")
  terms <- c("x1", "x2", "x3", "x4", "x5")
  grid <- exp(seq(log(0.2), log(0.002), length.out = 15))
  check <- function(d, ties, alpha = 1, standardize = TRUE, keep = terms, factors = rep(1, length(keep)),
                    weights = TRUE, offset = TRUE) {
    prepared <- penalized_prepared(d, terms, weights = if (weights) "w", offset = offset)
    rows <- survival_fit_rows(prepared)
    path <- glmnet_fit_path(glmnet_inputs(prepared, rows), terms %in% keep, factors, alpha, grid, standardize, ties,
                            1e-12, 1e5)
    direct <- cox_penalized_direct_glmnet(d, terms, keep, factors, grid, alpha, ties, standardize, weights, offset)
    expected <- matrix(0, length(terms), length(direct$lambda))
    expected[terms %in% keep, ] <- as.matrix(direct$beta)[seq_along(keep), ]
    expect_identical(path$path, expected)
    expect_identical(path$lambda, direct$lambda)
    expect_identical(path$passes, as.integer(direct$npasses))
    expect_null(path$end)
  }
  for (ties in c("breslow", "efron")) {
    check(cox_penalized_data(), ties)
    check(cox_penalized_data(counting = FALSE), ties, weights = FALSE, offset = FALSE)
    check(cox_penalized_data(), ties, alpha = 0.5, factors = c(0, 1, 1, 2, 0.5))
    check(cox_penalized_data(), ties, alpha = 0, standardize = FALSE)
    # A column left out (as a degenerate one would be), and a single covariate beside a column of zeros.
    check(cox_penalized_data(), ties, keep = c("x1", "x2", "x3", "x5"))
    check(cox_penalized_data(), ties, keep = "x2")
  }
})

test_that("a path ends where glmnet stops, or before a solution that is not one (DEC-115, D-78)", {
  skip_if_not_installed("glmnet", minimum_version = "5.0")
  d <- cox_penalized_data()
  prepared <- penalized_prepared(d)
  inputs <- glmnet_inputs(prepared, survival_fit_rows(prepared))
  keep <- rep(TRUE, 5)
  grid <- exp(seq(log(0.2), log(0.002), length.out = 6))
  real <- glmnet::glmnet
  # glmnet's own early stop: a warning, and the solutions of the larger lambdas.
  local_mocked_bindings(glmnet = function(...) {
    fit <- real(...)
    warning("from glmnet C++ code (error code -5); Convergence for 5th lambda value not reached after maxit=100000 ",
            "iterations; solutions for larger lambdas returned")
    fit$beta <- fit$beta[, 1:4]
    fit$lambda <- fit$lambda[1:4]
    fit$dev.ratio <- fit$dev.ratio[1:4]
    fit
  }, .package = "glmnet")
  path <- expect_silent(glmnet_fit_path(inputs, keep, rep(1, 5), 1, grid, TRUE, "breslow", 1e-12, 1e5))
  expect_identical(path$end, "stopped")
  expect_identical(path$end_point, 5L)
  expect_identical(ncol(path$path), 4L)
  expect_match(path$engine_message, "not reached")
  # A deviance above the null deviance, or coefficients that are not finite: the path ends before them.
  local_mocked_bindings(glmnet = function(...) {
    fit <- real(...)
    fit$dev.ratio[4] <- -1e35
    fit
  }, .package = "glmnet")
  path <- glmnet_fit_path(inputs, keep, rep(1, 5), 1, grid, TRUE, "efron", 1e-12, 1e5)
  expect_identical(path$end, "failed")
  expect_identical(path$end_point, 4L)
  expect_identical(length(path$lambda), 3L)
  local_mocked_bindings(glmnet = function(...) {
    fit <- real(...)
    fit$beta[2, 6] <- Inf
    fit
  }, .package = "glmnet")
  path <- glmnet_fit_path(inputs, keep, rep(1, 5), 1, grid, TRUE, "breslow", 1e-12, 1e5)
  expect_identical(path$end_point, 6L)
  expect_identical(ncol(path$path), 5L)
  # glmnet's other warnings pass; its errors become pprof_error_convergence.
  local_mocked_bindings(glmnet = function(...) stop("simulated failure"), .package = "glmnet")
  expect_error(glmnet_fit_path(inputs, keep, rep(1, 5), 1, grid, TRUE, "breslow", 1e-12, 1e5),
               class = "pprof_error_convergence")
})

test_that("the score at the null point: glmnet's gradient times the scaled design, as survival's score", {
  skip_if_not_installed("glmnet", minimum_version = "5.0")
  d <- cox_penalized_data()
  prepared <- penalized_prepared(d)
  rows <- survival_fit_rows(prepared)
  inputs <- glmnet_inputs(prepared, rows)
  scale <- c(2, 0.5, 1, 1.5, 4)
  for (ties in c("breslow", "efron")) {
    score <- unname(glmnet_scaled_score(inputs, rep(TRUE, 5), scale, inputs$offset, ties))
    fd <- d[d$w > 0, ]
    # residuals() rebuilds coxph()'s model frame in the formula's environment, so it holds the data.
    f <- stats::as.formula("Surv(entry, time, status) ~ x1 + x2 + x3 + x4 + x5 + strata(provider) + offset(o)",
                           env = list2env(list(Surv = survival::Surv, strata = survival::strata, fd = fd),
                                          parent = globalenv()))
    fit0 <- suppressWarnings(survival::coxph(f, data = fd, weights = w, ties = ties, init = rep(0, 5),
                                             control = survival::coxph.control(iter.max = 0, timefix = FALSE)))
    expected <- colSums(as.matrix(stats::residuals(fit0, type = "score")) * fd$w) / sum(fd$w) / scale
    expect_null(reference_compare(score, unname(expected), reference_tolerance("cox_function")), label = ties)
  }
})

test_that("glmnet's deviances of several linear predictors at once equal one at a time", {
  skip_if_not_installed("glmnet", minimum_version = "5.0")
  d <- cox_penalized_data()
  prepared <- penalized_prepared(d)
  inputs <- glmnet_inputs(prepared, survival_fit_rows(prepared))
  eta <- inputs$x %*% cbind(c(0.1, 0, 0, 0, 0), c(0.5, -0.3, 0.1, 0, 0.2)) + inputs$offset
  for (ties in c("breslow", "efron")) {
    together <- glmnet_deviances(inputs, eta, ties)
    one_by_one <- vapply(1:2, function(j) glmnet_deviances(inputs, eta[, j, drop = FALSE], ties), numeric(1))
    expect_identical(together, one_by_one)
  }
})

test_that("survival's partial log-likelihood of given linear predictors, and the fit of given columns (cox_engine)", {
  for (counting in c(TRUE, FALSE)) {
    d <- cox_penalized_data(counting = counting)
    prepared <- penalized_prepared(d)
    rows <- survival_fit_rows(prepared)
    fd <- d[d$w > 0, ]
    fd <- fd[order(match(fd$provider, sort(unique(fd$provider))), method = "radix"), ]
    eta <- 0.3 * fd$x1 - 0.2 * fd$x5 + fd$o
    lhs <- if (counting) "Surv(entry, time, status)" else "Surv(time, status)"
    env <- list2env(list(Surv = survival::Surv, strata = survival::strata, eta = eta, fd = fd), parent = globalenv())
    for (ties in c("breslow", "efron")) {
      reference <- survival::coxph(stats::as.formula(paste(lhs, "~ offset(eta) + strata(provider)"), env = env),
                                   data = fd, weights = w, ties = ties,
                                   control = survival::coxph.control(timefix = FALSE))
      expect_identical(survival_partial_loglik(prepared, rows, eta, ties), reference$loglik[1], label = ties)
      columns <- survival_fit_columns(prepared, rows, as.matrix(fd[, c("x1", "x2")]), ties, 1e-9, 100)
      fit <- survival::coxph(stats::as.formula(paste(lhs, "~ x1 + x2 + strata(provider) + offset(o)"), env = env),
                             data = fd, weights = w, ties = ties,
                             control = survival::coxph.control(eps = 1e-9, iter.max = 100, timefix = FALSE))
      expect_identical(columns$coefficients, unname(stats::coef(fit)), label = ties)
      expect_true(columns$converged)
    }
  }
})
