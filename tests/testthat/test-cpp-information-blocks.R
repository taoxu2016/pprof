# The block information routines of the C++ core (src/core/information_blocks), through
# the adapters that use them, against dense computations on the full information matrix
# with one indicator column per provider (brief §6 B). Agreement is at the closed-form
# tolerance: the dense and block computations differ only in the order of operations.
local_strict_mode()

closed_form <- reference_tolerance("closed_form")

expect_close <- function(actual, expected, label) {
  diffs <- reference_compare(as.numeric(actual), as.numeric(expected), closed_form)
  testthat::expect(is.null(diffs), sprintf("%s: %s", label, paste(diffs$detail, collapse = "; ")))
}

# The information matrix of (gamma, beta) with observation weights w, densely.
dense_information <- function(design, sizes, weights) {
  provider <- factor(rep(seq_along(sizes), sizes))
  x <- cbind(stats::model.matrix(~ 0 + provider), design)
  crossprod(x, x * weights)
}

dense_score <- function(response, design, sizes, p) {
  provider <- factor(rep(seq_along(sizes), sizes))
  x <- cbind(stats::model.matrix(~ 0 + provider), design)
  drop(crossprod(x, response - p))
}

fitted_probabilities <- function(inputs, gamma, beta) {
  stats::plogis(rep(gamma, inputs$sizes) + drop(inputs$design %*% beta))
}

test_that("the variances are the block inverse of the information with clamped probabilities (K-20)", {
  inputs <- engine_dataset_inputs("binary_example", paste0("z", 1:5))
  fit <- engine_fit(inputs)
  # One provider pushed to probabilities of exactly 1, where the clamp at 1e-10 applies.
  gamma <- fit$gamma
  gamma[1] <- 40
  p <- fitted_probabilities(inputs, gamma, fit$beta)
  expect_true(any(p == 1))
  p_clamped <- pmin(pmax(p, 1e-10), 1 - 1e-10)
  inverse <- solve(dense_information(inputs$design, inputs$sizes, p_clamped * (1 - p_clamped)))
  m <- length(inputs$sizes)
  variances <- cpp_logistic_variance(inputs$design, inputs$sizes, gamma, fit$beta)
  expect_close(variances$beta, inverse[-seq_len(m), -seq_len(m)], "Var(beta)")
  expect_close(variances$gamma, diag(inverse)[seq_len(m)], "Var(gamma)")
})

test_that("one SerBIN iteration without a line search is the dense Newton step (K-12)", {
  inputs <- engine_dataset_inputs("binary_example", paste0("z", 1:5))
  m <- length(inputs$sizes)
  p <- fitted_probabilities(inputs, inputs$gamma, inputs$beta)
  step <- solve(dense_information(inputs$design, inputs$sizes, p * (1 - p)),
                dense_score(inputs$response, inputs$design, inputs$sizes, p))
  # max_iter = 0 runs one iteration (K-17); the bound is wide enough that the clamp does
  # nothing.
  one <- cpp_logistic_fe_serbin(inputs$response, inputs$design, inputs$sizes, inputs$gamma, inputs$beta, 0L, 1e-5,
                                1e6, FALSE, "any", 1L)
  expect_identical(one$iterations, 1L)
  expect_close(one$gamma, inputs$gamma + step[seq_len(m)], "gamma after one step")
  expect_close(one$beta, inputs$beta + step[-seq_len(m)], "beta after one step")
})

test_that("SerBIN floors zero weights in the diagonal and covariate blocks only (K-13)", {
  inputs <- engine_dataset_inputs("binary_example", paste0("z", 1:5))
  gamma <- inputs$gamma
  gamma[1] <- 40
  expect_true(any(fitted_probabilities(inputs, gamma, inputs$beta) == 1))
  new <- cpp_logistic_fe_serbin(inputs$response, inputs$design, inputs$sizes, gamma, inputs$beta, 0L, 1e-5, 10,
                                FALSE, "any", 1L)
  port <- port_serbin(inputs$response, inputs$design, inputs$sizes, gamma, inputs$beta, max_iter = 0, bound = 10,
                      backtrack = FALSE)
  expect_true(all(is.finite(new$gamma)))
  expect_close(new$gamma, port$gamma, "gamma")
  expect_close(new$beta, port$beta, "beta")
})

test_that("the standard score statistics follow the variance-adjusted formula (K-66)", {
  inputs <- engine_dataset_inputs("binary_example", paste0("z", 1:5))
  fit <- engine_fit(inputs)
  m <- length(inputs$sizes)
  provider <- rep(seq_len(m), inputs$sizes)
  null <- stats::median(fit$gamma)
  p <- fitted_probabilities(inputs, fit$gamma, fit$beta)
  w <- p * (1 - p)
  w_floored <- ifelse(w == 0, 1e-20, w)
  p_null <- stats::plogis(null + drop(inputs$design %*% fit$beta))
  w_null <- p_null * (1 - p_null)
  tested <- c(1, 7, m)
  expected <- vapply(tested, function(i) {
    rows <- provider == i
    others <- setdiff(seq_len(m), i)
    w_beta <- ifelse(rows, w_null, w_floored)
    info_beta <- crossprod(inputs$design, inputs$design * w_beta)
    diagonal <- vapply(others, function(j) sum(w_floored[provider == j]), numeric(1))
    cross <- vapply(others, function(j) colSums(inputs$design[provider == j, , drop = FALSE] * w[provider == j]),
                    numeric(ncol(inputs$design)))
    schur <- info_beta - cross %*% (t(cross) / diagonal)
    info_alpha_beta <- colSums(inputs$design[rows, , drop = FALSE] * w_null[rows])
    variance <- sum(w_null[rows]) - drop(t(info_alpha_beta) %*% solve(schur, info_alpha_beta))
    sum(inputs$response[rows] - p_null[rows]) / sqrt(variance)
  }, numeric(1))
  result <- cpp_logistic_score_standard(inputs$response, inputs$design, inputs$sizes, fit$gamma, fit$beta, null,
                                        tested, 1L)
  expect_identical(result$failed, rep(FALSE, length(tested)))
  expect_close(result$statistic, expected, "standard score statistics")
})

test_that("direct expectations sum the fitted probabilities over every observation (K-81)", {
  inputs <- engine_random_inputs(20261002)
  fit <- engine_fit(inputs)
  linear_predictor <- drop(inputs$design %*% fit$beta)
  expected <- vapply(fit$gamma, function(effect) sum(stats::plogis(effect + linear_predictor)), numeric(1))
  expect_close(cpp_logistic_direct_expected(fit$gamma, linear_predictor, 1L), expected, "direct expectations")
  expect_identical(cpp_logistic_direct_expected(fit$gamma, linear_predictor, 2L),
                   cpp_logistic_direct_expected(fit$gamma, linear_predictor, 1L))
})
