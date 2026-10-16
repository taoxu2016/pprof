# The elastic-net Cox model (R/model-cox-penalized.R; COXPH_DESIGN §A.5, §B, §D.4; K-143; DEC-113 to DEC-120).

skip_if_not_installed("glmnet", minimum_version = "5.0")

penalized_fit <- function(d = cox_penalized_data(), terms = c("x1", "x2", "x3", "x4", "x5"), ..., weights = "w",
                          offset = TRUE) {
  fit_cox_penalized(cox_penalized_formula(d, terms, offset), d, "provider", weights = weights, ...)
}

# pprof_py's lambda_max (K-143) written out in the test, from survival alone: the scaled covariates'
# score at the null point (unpenalized columns fitted by coxph() at pprof_py's eps 1e-9 and 100
# iterations), from survival's score residuals, over the weights' sum, by penalty factor and alpha.
lambda_max_by_survival <- function(d, terms, factors = rep(1, length(terms)), alpha = 1, ties = "breslow") {
  fd <- d[d$w > 0, ]
  x <- as.matrix(fd[, terms])
  wn <- fd$w / sum(fd$w)
  scale <- sqrt(colSums(sweep(x, 2, colSums(x * wn))^2 * wn))
  z <- sweep(x, 2, scale, "/")
  factors <- factors * length(factors) / sum(factors)
  env <- list2env(list(Surv = survival::Surv, strata = survival::strata, fd = fd, z = z), parent = globalenv())
  beta <- rep(0, length(terms))
  if (any(factors == 0)) {
    zf <- z[, factors == 0, drop = FALSE]
    env$zf <- zf
    beta[factors == 0] <- stats::coef(survival::coxph(
      stats::as.formula("Surv(entry, time, status) ~ zf + strata(provider) + offset(o)", env = env), data = fd,
      weights = w, ties = ties, control = survival::coxph.control(eps = 1e-9, iter.max = 100, timefix = FALSE)
    ))
  }
  null <- suppressWarnings(survival::coxph(
    stats::as.formula("Surv(entry, time, status) ~ z + strata(provider) + offset(o)", env = env), data = fd,
    weights = w, ties = ties, init = beta, control = survival::coxph.control(iter.max = 0, timefix = FALSE)
  ))
  score <- colSums(as.matrix(stats::residuals(null, type = "score")) * fd$w) / sum(fd$w)
  max(abs(score)[factors > 0] / factors[factors > 0]) / max(alpha, 1e-3)
}

test_that("fit_cox_penalized() raises a classed error when glmnet is missing (DEC-088)", {
  local_mocked_bindings(glmnet_available = function() FALSE)
  expect_error(penalized_fit(), class = "pprof_error_invalid_input")
})

test_that("arguments are checked at the boundary", {
  d <- cox_penalized_data()
  bad <- list(alpha = 1.5, alpha = -0.1, lambda = c(0.1, -0.1), lambda = c(0.1, 0.1), lambda = c(0.1, Inf),
              n_lambda = 0, lambda_min_ratio = 0, lambda_min_ratio = 1.5, standardize = NA, ties = "exact",
              max_iter = 0, tol = 0, keep_data = "yes", verbose = NA, penalty_factor = c(1, 2),
              penalty_factor = c(x1 = -1), penalty_factor = c(x1 = NaN), penalty_factor = c(age = 0))
  for (i in seq_along(bad)) {
    args <- stats::setNames(list(bad[[i]]), names(bad)[i])
    expect_error(do.call(penalized_fit, c(list(d = d), args)), class = "pprof_error_invalid_input",
                 label = paste(names(bad)[i], paste(format(bad[[i]]), collapse = ",")))
  }
  expect_error(fit_cox_penalized(Surv(entry, time, status) ~ 1, d, "provider"), class = "pprof_error_invalid_input")
  expect_error(penalized_fit(penalty_factor = c(x1 = 0, x2 = 0, x3 = 0, x4 = 0, x5 = 0)),
               class = "pprof_error_invalid_input")
  none <- d
  none$status <- 0
  expect_error(penalized_fit(none), class = "pprof_error_data")
})

test_that("the grid is pprof_py's (K-143): lambda_max, its ratio, and its spacing", {
  d <- cox_penalized_data()
  terms <- c("x1", "x2", "x3", "x4", "x5")
  for (ties in c("breslow", "efron")) {
    fit <- penalized_fit(d, ties = ties, n_lambda = 30)
    expect_null(reference_compare(fit$lambda_max, lambda_max_by_survival(d, terms, ties = ties),
                                  reference_tolerance("closed_form")), label = ties)
    expected <- exp(seq(log(fit$lambda_max), log(fit$lambda_max * 1e-4), length.out = 30))
    expect_identical(fit$lambda, expected)
    expect_identical(fit$lambda_min_ratio, 1e-4)
  }
  # An unpenalized covariate is fitted at the null point; alpha divides lambda_max, floored at 1e-3.
  fit <- penalized_fit(d, alpha = 0.5, penalty_factor = c(x5 = 0), n_lambda = 5)
  expect_null(reference_compare(fit$lambda_max, lambda_max_by_survival(d, terms, c(1, 1, 1, 1, 0), alpha = 0.5),
                                reference_tolerance("closed_form")))
  ridge <- penalized_fit(d, alpha = 0, n_lambda = 5)
  expect_null(reference_compare(ridge$lambda_max, lambda_max_by_survival(d, terms, alpha = 0),
                                reference_tolerance("closed_form")))
  # A given grid is sorted; one value of n_lambda is lambda_max alone; lambda_min_ratio sets the end.
  given <- penalized_fit(d, lambda = c(0.01, 0.1, 0.05))
  expect_identical(given$lambda, c(0.1, 0.05, 0.01))
  expect_identical(penalized_fit(d, n_lambda = 1)$lambda, penalized_fit(d, n_lambda = 1)$lambda_max)
  short <- penalized_fit(d, n_lambda = 4, lambda_min_ratio = 0.05)
  expect_identical(short$lambda[4], exp(log(short$lambda_max * 0.05)))
  # Fewer observations than covariates: the ratio is 1e-2 (n counts every observation).
  small <- data.frame(provider = "p1", x1 = c(1, 2, 3, 5), x2 = c(2, 1, 4, 3), x3 = c(0.5, 0.25, 1, 2),
                      x4 = c(3, 1, 2, 0), x5 = c(1, 0, 0, 1), entry = 0, time = c(2, 3, 5, 7), status = c(1, 1, 0, 1),
                      w = 1, o = 0)
  wide <- suppressWarnings(penalized_fit(small, n_lambda = 3))
  expect_identical(wide$lambda_min_ratio, 1e-2)
})

test_that("penalty factors: named, partial, kept as given, and rescaled over the covariates kept", {
  d <- cox_penalized_data()
  fit <- penalized_fit(d, penalty_factor = c(x2 = 2, x5 = 0), n_lambda = 10)
  expect_identical(fit$penalty_factor, c(x1 = 1, x2 = 2, x3 = 1, x4 = 1, x5 = 0))
  # The unpenalized covariate is in the model at every lambda; the path is glmnet's with the factors
  # rescaled to sum to 5.
  expect_true(all(fit$coefficient_path["x5", ] != 0))
  direct <- cox_penalized_direct_glmnet(d, c("x1", "x2", "x3", "x4", "x5"), factors = c(1, 2, 1, 1, 0), # sum 5
                                        lambda = fit$lambda)
  expect_identical(unname(fit$coefficient_path), unname(as.matrix(direct$beta)))
})

test_that("covariates without variation are left out with a classed warning and coefficient 0 (K-143)", {
  d <- cox_penalized_data()
  d$constant <- 2
  terms <- c("x1", "x2", "constant", "x5")
  condition <- tryCatch(penalized_fit(d, terms, n_lambda = 10), pprof_warning_degenerate_covariates = function(w) w)
  expect_s3_class(condition, "pprof_warning_degenerate_covariates")
  expect_identical(condition$covariates, "constant")
  fit <- suppressWarnings(penalized_fit(d, terms, n_lambda = 10))
  expect_identical(fit$degenerate, "constant")
  expect_true(all(fit$coefficient_path["constant", ] == 0))
  expect_identical(fit$column_scale[["constant"]], 1)
  # The others' path is the path without the column (the factors are rescaled over the columns kept).
  without <- penalized_fit(d, c("x1", "x2", "x5"), lambda = fit$lambda)
  expect_identical(unname(fit$coefficient_path[c("x1", "x2", "x5"), ]), unname(without$coefficient_path))
  # Without standardization too; every covariate without variation is an error.
  expect_warning(penalized_fit(d, terms, n_lambda = 5, standardize = FALSE),
                 class = "pprof_warning_degenerate_covariates")
  d$also <- -1
  expect_error(suppressWarnings(penalized_fit(d, c("constant", "also"))), class = "pprof_error_data")
})

test_that("rows with weight 0 are left out of the fit and kept in the data (M-25, D-58)", {
  d <- cox_penalized_data()
  fit <- penalized_fit(d, n_lambda = 10)
  expect_identical(fit$n_zero_weight, sum(d$w == 0))
  expect_identical(fit$n_obs, nrow(d))
  positive <- penalized_fit(d[d$w > 0, ], n_lambda = 10)
  expect_identical(fit$coefficient_path, positive$coefficient_path)
  expect_identical(fit$lambda, positive$lambda)
})

test_that("a single covariate, and an unpenalized covariate aliased with another", {
  d <- cox_penalized_data()
  one <- penalized_fit(d, "x2", n_lambda = 10)
  expect_identical(dim(one$coefficient_path), c(1L, 10L))
  expect_lt(abs(one$coefficient_path[1, 1]), 1e-10)  # 0 at lambda_max, up to rounding (D-72)
  expect_gt(abs(one$coefficient_path[1, 10]), 0)
  d$x6 <- d$x1
  expect_error(penalized_fit(d, c("x1", "x6", "x2"), penalty_factor = c(x1 = 0, x6 = 0), n_lambda = 5),
               class = "pprof_error_data")
})

test_that("covariates that are not finite, and data without a positive weight, are errors", {
  d <- cox_penalized_data()
  infinite <- d
  infinite$x1[3] <- Inf
  expect_error(penalized_fit(infinite, n_lambda = 5), class = "pprof_error_invalid_input")
  unweighted <- d
  unweighted$w <- 0
  expect_error(penalized_fit(unweighted, n_lambda = 5), class = "pprof_error_data")
})

test_that("a path that glmnet ends early warns once and keeps the points reached (DEC-115, D-78)", {
  d <- cox_penalized_data()
  real <- glmnet::glmnet
  # A solution with a deviance above the null deviance at the 5th point: the path ends at the 4th.
  local_mocked_bindings(glmnet = function(...) {
    fit <- real(...)
    fit$dev.ratio[5] <- -1e35
    fit
  }, .package = "glmnet")
  condition <- tryCatch(penalized_fit(d, n_lambda = 8), warning = function(w) w)
  expect_s3_class(condition, "pprof_warning_not_converged")
  fit <- suppressWarnings(penalized_fit(d, n_lambda = 8))
  expect_identical(dim(fit$coefficient_path), c(5L, 4L))
  expect_identical(fit$lambda, exp(seq(log(fit$lambda_max), log(fit$lambda_max * 1e-4), length.out = 8))[1:4])
  expect_identical(fit$convergence[c("converged", "grid_points")], list(converged = FALSE, grid_points = 4L))
  expect_output(print(fit), "ended early")
  # glmnet's own early stop (its iteration limit at the 6th point): the fit's warning replaces glmnet's.
  local_mocked_bindings(glmnet = function(...) {
    fit <- real(...)
    warning("from glmnet C++ code (error code -6); Convergence for 6th lambda value not reached after maxit=100000 ",
            "iterations; solutions for larger lambdas returned")
    fit$beta <- fit$beta[, 1:5]
    fit$lambda <- fit$lambda[1:5]
    fit$dev.ratio <- fit$dev.ratio[1:5]
    fit
  }, .package = "glmnet")
  condition <- tryCatch(penalized_fit(d, n_lambda = 8), warning = function(w) w)
  expect_s3_class(condition, "pprof_warning_not_converged")
  expect_identical(length(suppressWarnings(penalized_fit(d, n_lambda = 8))$lambda), 5L)
  # No solution at the first point: a classed error.
  local_mocked_bindings(glmnet = function(...) {
    fit <- real(...)
    fit$dev.ratio[1] <- -1e35
    fit
  }, .package = "glmnet")
  expect_error(penalized_fit(d, n_lambda = 8), class = "pprof_error_convergence")
})

test_that("the object: its fields, its validator, and no capability (M-34)", {
  d <- cox_penalized_data()
  fit <- penalized_fit(d, n_lambda = 12, keep_data = TRUE)
  expect_s3_class(fit, c("pprof_cox_penalized", "pprof_model"), exact = TRUE)
  expect_silent(validate_pprof_cox_penalized(fit))
  expect_null(fit$provider_effects)
  expect_null(fit$selected)
  expect_null(fit$cross_validation)
  expect_true(all(is.na(fit$vcov)))
  expect_identical(dimnames(fit$coefficient_path), list(names(fit$coefficients), NULL))
  expect_identical(fit$coefficients, fit$coefficient_path[, 12])
  expect_identical(fit$linear_predictor, unname(drop(fit$data$design %*% fit$coefficients)))
  expect_s3_class(fit$engine_fit, "glmnet")
  expect_identical(fit$convergence[c("converged", "grid_points", "stop_rule")],
                   list(converged = TRUE, grid_points = 12L, stop_rule = "relative_objective"))
  expect_identical(inference_capabilities(fit), character())
  for (call in list(quote(test_providers(fit)), quote(standardize_providers(fit)), quote(funnel_limits(fit)),
                    quote(profile_providers(fit)), quote(provider_effects(fit)), quote(test_coefficients(fit)),
                    quote(summary(fit)), quote(stats::confint(fit)), quote(augment(fit)))) {
    expect_error(eval(call), class = "pprof_error_unsupported_inference", label = deparse(call))
  }
  set_field <- function(field, value) {
    broken <- fit
    broken[[field]] <- value
    broken
  }
  spec <- fit$spec
  spec$family <- "cox_stratified"
  broken <- list(
    coefficients = set_field("coefficients", replace(fit$coefficients, 1, 99)),
    lambda = set_field("lambda", rev(fit$lambda)),
    class = structure(unclass(fit), class = c("pprof_cox_stratified", "pprof_model")),
    family = set_field("spec", spec),
    interval = set_field("stop", fit$start),
    response = set_field("response", replace(fit$response, 1, 2)),
    weights = set_field("weights", fit$weights[-1]),
    path = set_field("coefficient_path", fit$coefficient_path[, -1]),
    vcov = set_field("vcov", replace(fit$vcov, 1, 0)),
    penalty_factor = set_field("penalty_factor", unname(fit$penalty_factor)),
    column_scale = set_field("column_scale", replace(fit$column_scale, 1, 0)),
    selected = set_field("selected", list(lambda = 1, index = 99L, rule = "min")),
    engine_fit = set_field("engine_fit", list())
  )
  for (what in names(broken)) {
    expect_error(validate_pprof_cox_penalized(broken[[what]]), class = "pprof_error_invalid_input", label = what)
  }
})

test_that("coef(), predict(), nobs(), print(), tidy(), and glance() (D-79)", {
  d <- cox_penalized_data()
  fit <- penalized_fit(d, n_lambda = 8)
  expect_identical(coef(fit), fit$coefficient_path)
  expect_identical(coef(fit, lambda = fit$lambda[3]), fit$coefficient_path[, 3])
  expect_error(coef(fit, lambda = mean(fit$lambda[3:4])), class = "pprof_error_invalid_input")
  newdata <- data.frame(x1 = c(0.5, -1), x2 = 0, x3 = 1, x4 = 0, x5 = c(0, 1), o = c(0, 0.25))
  beta <- fit$coefficient_path[, 4]
  eta <- drop(as.matrix(newdata[, names(beta)]) %*% beta) + newdata$o
  expect_equal(predict(fit, newdata, lambda = fit$lambda[4]), eta, tolerance = 1e-14)
  expect_equal(predict(fit, newdata, type = "risk"), exp(drop(as.matrix(newdata[, names(beta)]) %*% fit$coefficients) +
                                                           newdata$o), tolerance = 1e-14)
  observed <- predict(fit)
  expect_identical(names(observed), as.character(seq_len(nrow(d))))
  expect_error(predict(fit, lambda = fit$lambda[2]), class = "pprof_error_data_required")
  kept <- penalized_fit(d, n_lambda = 8, keep_data = TRUE)
  expect_equal(unname(predict(kept, lambda = kept$lambda[2])),
               unname(drop(as.matrix(d[, names(beta)]) %*% kept$coefficient_path[, 2]) + d$o), tolerance = 1e-14)
  expect_identical(nobs(fit), as.integer(sum(d$status[d$w > 0])))
  expect_output(print(fit), "cox_penalized")
  expect_output(print(fit), "No lambda selected")
  expect_output(print(penalized_fit(d, lambda = 10 * fit$lambda_max)), "all 0")
  d$constant <- 1
  expect_output(print(suppressWarnings(penalized_fit(d, c("x1", "constant"), n_lambda = 3))), "without variation")
  expect_identical(tidy(fit), tibble::tibble(term = names(fit$coefficients), estimate = unname(fit$coefficients)))
  expect_identical(names(glance(fit)), c("n_obs", "n_providers", "n_excluded_providers", "n_events", "alpha",
                                         "n_lambda", "lambda", "rule", "iterations", "converged"))
  expect_message(penalized_fit(d, n_lambda = 3, verbose = TRUE), class = "pprof_message")
})

test_that("metamorphic: row order, provider labels, covariate order, time scale, offset shift, duplicates", {
  d <- cox_penalized_data()
  grid <- penalized_fit(d, n_lambda = 15)$lambda
  base <- penalized_fit(d, lambda = grid, ties = "breslow")
  close <- function(a, b, tier = "closed_form") expect_null(reference_compare(a, b, reference_tolerance(tier)))
  shuffled <- d[withr::with_seed(5, sample(nrow(d))), ]
  close(penalized_fit(shuffled, lambda = grid)$coefficient_path, base$coefficient_path)
  relabeled <- d
  relabeled$provider <- unname(c(p1 = "z", p2 = "y", p3 = "x", p4 = "w", p5 = "v", p6 = "u")[d$provider])
  close(penalized_fit(relabeled, lambda = grid)$coefficient_path, base$coefficient_path)
  reordered <- penalized_fit(d, c("x5", "x3", "x1", "x4", "x2"), lambda = grid)
  close(reordered$coefficient_path[rownames(base$coefficient_path), ], base$coefficient_path, "penalized_path")
  rescaled <- d
  rescaled$entry <- rescaled$entry * 2
  rescaled$time <- rescaled$time * 2
  expect_identical(penalized_fit(rescaled, lambda = grid)$coefficient_path, base$coefficient_path)
  shifted <- d
  shifted$o <- shifted$o + 0.75
  close(penalized_fit(shifted, lambda = grid)$coefficient_path, base$coefficient_path)
  # Breslow ties: a row of weight 2 is the same row twice with weight 1. glmnet stops on the change in the
  # objective, so its two runs agree to its convergence (1.5e-6 here), not to rounding, as with another
  # order of the covariates.
  doubled <- d[d$w == 2, ]
  doubled$w <- 1
  twice <- rbind(d[d$w != 2, ], doubled, doubled)
  close(penalized_fit(twice, lambda = grid)$coefficient_path, base$coefficient_path, "penalized_path")
})

test_that("the validator checks for provider effects; an unpenalized start that does not converge warns", {
  fit <- penalized_fit(n_lambda = 6)
  broken <- fit
  broken$provider_effects <- stats::setNames(rep(0, fit$n_providers), fit$providers$provider_id)
  expect_error(validate_pprof_cox_penalized(broken), class = "pprof_error_invalid_input")
  # survival's fit of the unpenalized covariates at the start of the path, as if it reached its limit.
  real <- survival_fit_columns
  local_mocked_bindings(survival_fit_columns = function(...) {
    null <- real(...)
    null$converged <- FALSE
    null
  })
  expect_warning(penalized_fit(n_lambda = 6, penalty_factor = c(x1 = 0)), class = "pprof_warning_not_converged")
  # A lambda_max of 0, where no penalized covariate moves the score at the null point, gives a grid of zeros.
  expect_identical(cox_penalized_grid(0, 4, 1e-4), rep(0, 4))
})
