# The selection of lambda by cross-validation (R/model-cox-selection.R; COXPH_DESIGN §A.5, §E.2; K-144, M-30,
# D-61, D-67; DEC-114).

skip_if_not_installed("glmnet", minimum_version = "5.0")

selection_fit <- function(d = cox_penalized_data(), ..., keep_data = TRUE) {
  fit_cox_penalized(cox_penalized_formula(d), d, "provider", weights = "w", n_lambda = 12, keep_data = keep_data, ...)
}

# pprof_py's cross-validation written out in the test (K-144), apart from the package's adapter: each
# fold's path from glmnet called directly on its training rows with positive weight, and the fold
# deviances from survival's coxph() with the linear predictor as offset and the saturated term in the
# Breslow form, as the fixture generator computes them (dev/reference/cox/survival.R).
cross_validation_by_hand <- function(d, folds, grid, ties = "breslow") {
  keep <- d$w > 0
  d <- d[keep, ]
  folds <- folds[keep]
  sorted <- order(match(d$provider, sort(unique(d$provider))), method = "radix")
  d <- d[sorted, ]
  folds <- folds[sorted]
  terms <- c("x1", "x2", "x3", "x4", "x5")
  x <- as.matrix(d[, terms])
  deviance_of <- function(rows, eta) {
    fd <- d[rows, ]
    env <- list2env(list(Surv = survival::Surv, strata = survival::strata, eta = eta), parent = globalenv())
    f <- stats::as.formula("Surv(entry, time, status) ~ offset(eta) + strata(provider)", env = env)
    loglik <- survival::coxph(f, data = fd, weights = w, ties = ties,
                              control = survival::coxph.control(timefix = FALSE))$loglik[1]
    events <- fd$status == 1
    wd <- tapply(fd$w[events], list(fd$provider[events], fd$time[events]), sum)
    wd <- wd[!is.na(wd) & wd > 0]
    2 * (-sum(wd * log(wd)) - loglik)
  }
  labels <- sort(unique(folds))
  held <- vapply(labels, function(k) sum(d$w[folds == k] * d$status[folds == k]), numeric(1))
  deviance <- matrix(NA_real_, length(labels), length(grid))
  for (i in seq_along(labels)) {
    train <- folds != labels[i]
    fit <- cox_penalized_direct_glmnet(d[train, ], terms, lambda = grid, ties = ties)
    eta <- x %*% as.matrix(fit$beta) + d$o
    for (j in seq_along(grid)) {
      deviance[i, j] <- (deviance_of(seq_len(nrow(d)), eta[, j]) - deviance_of(which(train), eta[train, j])) / held[i]
    }
  }
  cvm <- colSums(held * deviance) / sum(held)
  cvsd <- sqrt(colSums(held * sweep(deviance, 2, cvm)^2) / sum(held) / (length(labels) - 1))
  best <- which.min(cvm)
  list(deviance = deviance, cvm = cvm, cvsd = cvsd, best = best, one_se = which(cvm <= cvm[best] + cvsd[best])[1])
}

test_that("select_lambda() needs a penalized model and glmnet (DEC-088)", {
  expect_error(select_lambda(list()), class = "pprof_error_invalid_input")
  fit <- selection_fit()
  local_mocked_bindings(glmnet_available = function() FALSE)
  expect_error(select_lambda(fit), class = "pprof_error_invalid_input")
})

test_that("pprof_py's cross-validation, against its transcription with survival's partial likelihood (K-144)", {
  d <- cox_penalized_data()
  folds <- rep_len(1:4, nrow(d))
  for (ties in c("breslow", "efron")) {
    fit <- selection_fit(d, ties = ties)
    selected <- select_lambda(fit, folds = folds)
    cv <- selected$cross_validation
    by_hand <- cross_validation_by_hand(d, folds, fit$lambda, ties)
    expect_null(reference_compare(cv$fold_deviance, by_hand$deviance, reference_tolerance("closed_form")), label = ties)
    expect_null(reference_compare(cv$cvm, by_hand$cvm, reference_tolerance("closed_form")), label = ties)
    expect_null(reference_compare(cv$cvsd, by_hand$cvsd, reference_tolerance("closed_form")), label = ties)
    expect_identical(cv$lambda_min, fit$lambda[by_hand$best])
    expect_identical(cv$lambda_1se, fit$lambda[by_hand$one_se])
    expect_identical(selected$selected, list(lambda = cv$lambda_1se, index = by_hand$one_se, rule = "1se"))
    expect_identical(selected$coefficients, fit$coefficient_path[, by_hand$one_se])
    expect_identical(cv$n_folds_used, rep(4L, 12))
    expect_identical(cv$held_out_weight, vapply(1:4, function(k) sum((d$w * d$status)[folds == k]), numeric(1)))
    by_min <- select_lambda(fit, folds = folds, rule = "min")
    expect_identical(by_min$selected$index, by_hand$best)
    expect_identical(by_min$cross_validation$cvm, cv$cvm)
  }
})

test_that("the deviances' saturated term: glmnet's is pprof_py's with Breslow ties, a constant away with Efron's", {
  d <- cox_penalized_data()
  prepared <- data_prepare(cox_penalized_formula(d), d, "provider", event_counts = TRUE, response_type = "survival",
                           weights = "w", allow_offset = TRUE)
  rows <- survival_fit_rows(prepared)
  inputs <- glmnet_inputs(prepared, rows)
  eta <- inputs$x %*% cbind(c(0.1, 0, 0, 0, 0), c(0.5, -0.3, 0.1, 0, 0.2)) + inputs$offset
  for (ties in c("breslow", "efron")) {
    loglik <- vapply(1:2, function(j) survival_partial_loglik(prepared, rows, eta[, j], ties), numeric(1))
    pprof_py <- 2 * (cox_saturated_loglik(prepared, rows) - loglik)
    # The shift measured at the offsets moves glmnet's deviance to pprof_py's at other linear predictors.
    moved <- glmnet_deviances(inputs, eta, ties) - cox_penalized_deviance_shift(prepared, rows, inputs, ties)
    expect_null(reference_compare(moved, pprof_py, reference_tolerance("closed_form")), label = ties)
    if (ties == "breslow") {
      expect_null(reference_compare(glmnet_deviances(inputs, eta, ties), pprof_py, reference_tolerance("closed_form")))
    }
  }
})

test_that("given folds: 1 to K or 0 to K - 1, at least two, one per row of the data", {
  d <- cox_penalized_data()
  fit <- selection_fit(d)
  folds <- rep_len(1:3, nrow(d))
  one <- select_lambda(fit, folds = folds)$cross_validation
  zero <- select_lambda(fit, folds = folds - 1L)$cross_validation
  expect_identical(one$cvm, zero$cvm)
  expect_identical(one$folds, folds)
  two <- select_lambda(fit, folds = rep_len(1:2, nrow(d)))
  expect_identical(nrow(two$cross_validation$fold_deviance), 2L)
  for (bad in list(folds[-1], replace(folds, 1, 1.5), replace(folds, folds == 2, 4), rep(1, nrow(d)),
                   replace(folds, 1, NA))) {
    expect_error(select_lambda(fit, folds = bad), class = "pprof_error_invalid_input")
  }
  # A fold whose held-out events have no weight cannot normalize its deviance.
  empty <- folds
  empty[d$status == 1] <- withr::with_seed(3, sample(c(1, 2), sum(d$status == 1), replace = TRUE))
  expect_error(select_lambda(fit, folds = empty), class = "pprof_error_data")
  expect_error(select_lambda(fit, n_folds = 2), class = "pprof_error_invalid_input")
  expect_error(select_lambda(fit, rule = "max"), class = "pprof_error_invalid_input")
})

test_that("drawn folds: event-stratified, balanced, reproducible with a seed (D-61)", {
  d <- cox_penalized_data()
  fit <- selection_fit(d)
  a <- withr::with_seed(11, select_lambda(fit, n_folds = 5))
  b <- withr::with_seed(11, select_lambda(fit, n_folds = 5))
  expect_identical(a$cross_validation, b$cross_validation)
  folds <- a$cross_validation$folds
  expect_setequal(unique(folds), 1:5)
  for (status in c(0, 1)) {
    sizes <- tabulate(folds[d$status == status], 5)
    expect_true(all(sizes %in% c(floor(sum(d$status == status) / 5), ceiling(sum(d$status == status) / 5))))
  }
  # The draw is the permutation of the labels, events first, in the order of the data.
  withr::with_seed(11, {
    expected <- integer(nrow(d))
    for (group in list(which(d$status == 1), which(d$status == 0))) {
      labels <- rep_len(1:5, length(group))
      expected[group] <- labels[sample.int(length(group))]
    }
  })
  expect_identical(folds, expected)
})

test_that("rows with weight 0 have a fold and are out of the fits and the deviances (M-25, D-58)", {
  d <- cox_penalized_data()
  folds <- rep_len(1:4, nrow(d))
  fit <- selection_fit(d, lambda = selection_fit(d)$lambda)
  positive <- selection_fit(d[d$w > 0, ], lambda = fit$lambda)
  a <- select_lambda(fit, folds = folds)$cross_validation
  b <- select_lambda(positive, folds = folds[d$w > 0])$cross_validation
  expect_identical(a$fold_deviance, b$fold_deviance)
  expect_identical(a$held_out_weight, b$held_out_weight)
})

test_that("the data the model was fit to, and the selected model's methods", {
  d <- cox_penalized_data()
  fit <- selection_fit(d, keep_data = FALSE)
  expect_error(select_lambda(fit, folds = rep_len(1:3, nrow(d))), class = "pprof_error_data_required")
  other <- d
  other$x1 <- -other$x1
  expect_error(select_lambda(fit, folds = rep_len(1:3, nrow(d)), data = other), class = "pprof_error_invalid_input")
  selected <- select_lambda(fit, folds = rep_len(1:3, nrow(d)), data = d)
  expect_silent(validate_pprof_cox_penalized(selected))
  sorted <- d[order(match(d$provider, sort(unique(d$provider))), method = "radix"), names(selected$coefficients)]
  expect_null(reference_compare(selected$linear_predictor, unname(drop(as.matrix(sorted) %*% selected$coefficients)),
                                reference_tolerance("closed_form")))
  expect_output(print(selected), "Selected lambda")
  expect_identical(glance(selected)$rule, "1se")
  expect_identical(glance(selected)$lambda, selected$selected$lambda)
  expect_identical(tidy(selected)$estimate, unname(selected$coefficients))
})

test_that("a lambda that a fold's path did not reach, or whose deviance is not finite, is not selected", {
  d <- cox_penalized_data()
  fit <- selection_fit(d)
  folds <- rep_len(1:3, nrow(d))
  real <- glmnet_fit_path
  calls <- 0L
  local_mocked_bindings(glmnet_fit_path = function(...) {
    calls <<- calls + 1L
    path <- real(...)
    if (calls == 2L) {
      path$path <- path$path[, 1:9, drop = FALSE]
      path$lambda <- path$lambda[1:9]
      path$end <- "stopped"
      path$end_point <- 10L
    }
    path
  })
  warned <- FALSE
  selected <- withCallingHandlers(select_lambda(fit, folds = folds), pprof_warning_not_converged = function(w) {
    warned <<- TRUE
    invokeRestart("muffleWarning")
  })
  expect_true(warned)
  cv <- selected$cross_validation
  expect_true(all(is.na(cv$cvm[10:12])))
  expect_identical(cv$n_folds_used, c(rep(3L, 9), rep(2L, 3)))
  expect_lte(selected$selected$index, 9L)
  # Paths without a single solution leave no lambda to select: a classed error.
  local_mocked_bindings(glmnet_fit_path = function(...) {
    path <- real(...)
    path$path <- path$path[, 0L, drop = FALSE]
    path$lambda <- numeric()
    path$end <- "failed"
    path$end_point <- 1L
    path
  })
  expect_error(suppressWarnings(select_lambda(fit, folds = folds)), class = "pprof_error_data")
})

test_that("select_lambda() offers no bootstrap standard error (D-67), and needs two values of lambda", {
  expect_false(any(c("se_method", "n_bootstrap") %in% names(formals(select_lambda.pprof_cox_penalized))))
  d <- cox_penalized_data()
  one <- fit_cox_penalized(cox_penalized_formula(d), d, "provider", weights = "w", n_lambda = 1, keep_data = TRUE)
  expect_error(select_lambda(one), class = "pprof_error_invalid_input")
})
