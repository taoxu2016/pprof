# The Firth engine (src/logistic/firth) through its adapter: the step and the penalized
# log-likelihood against dense computations on the full information matrix, the weight
# floor, the log-determinant's branches, the loop bounds, the clamp, threads, failures,
# input checks, and interrupts (brief §6 B to D). The comparison with the reference's own
# routine is in test-cpp-legacy-comparison.R, and with the fixtures in
# test-cpp-reference-engines.R.
local_strict_mode()

closed_form <- reference_tolerance("closed_form")

expect_close <- function(actual, expected, label) {
  diffs <- reference_compare(as.numeric(actual), as.numeric(expected), closed_form)
  testthat::expect(is.null(diffs), sprintf("%s: %s", label, paste(diffs$detail, collapse = "; ")))
}

example_inputs <- function() engine_dataset_inputs("binary_example", paste0("z", 1:5))

# The design with one indicator column per provider followed by the covariates.
dense_design <- function(inputs) {
  provider <- factor(rep(seq_along(inputs$sizes), inputs$sizes))
  cbind(stats::model.matrix(~ 0 + provider), inputs$design)
}

# The Firth quantities at (gamma, beta), densely, with weights that are exactly 0 replaced
# by 1e-10 in every block (K-31): the information, the hat values, the modified score
# (K-32), and the penalized log-likelihood (K-30).
dense_firth <- function(inputs, gamma, beta) {
  x <- dense_design(inputs)
  eta <- rep(gamma, inputs$sizes) + drop(inputs$design %*% beta)
  p <- 1 / (1 + exp(-eta))
  w <- p * (1 - p)
  w[w == 0] <- 1e-10
  information <- crossprod(x, x * w)
  inverse <- solve(information)
  hat <- w * rowSums((x %*% inverse) * x)
  score <- drop(crossprod(x, inputs$response - p + hat * (0.5 - p)))
  loglik <- sum(eta * inputs$response - log(1 + exp(eta)))
  log_det <- as.numeric(determinant(information, logarithm = TRUE)$modulus)
  list(step = drop(inverse %*% score), penalized_loglik = loglik + log_det / 2)
}

test_that("one iteration is the full Newton step on the modified score (K-32)", {
  inputs <- example_inputs()
  m <- length(inputs$sizes)
  dense <- dense_firth(inputs, inputs$gamma, inputs$beta)
  # The bound is wide enough that the clamp does nothing.
  one <- firth_fit(inputs, max_iter = 1L, tol = 0, bound = 1e6)
  expect_identical(one$iterations, 1L)
  expect_close(one$gamma, inputs$gamma + dense$step[seq_len(m)], "gamma after one step")
  expect_close(one$beta, inputs$beta + dense$step[-seq_len(m)], "beta after one step")
  expect_close(one$history[, "coefficients"], max(abs(dense$step[-seq_len(m)])), "criterion")
})

test_that("the penalized log-likelihood is l + log det(I) / 2, at the start and after every iteration (K-30)", {
  inputs <- example_inputs()
  fit <- firth_fit(inputs, max_iter = 3L, tol = 0)
  expect_close(fit$penalized_loglik_initial, dense_firth(inputs, inputs$gamma, inputs$beta)$penalized_loglik,
               "at the starting values")
  expect_close(fit$penalized_loglik, dense_firth(inputs, fit$gamma, fit$beta)$penalized_loglik,
               "at the estimates")
  expect_identical(unname(fit$history[3, "penalized_loglik"]), fit$penalized_loglik)
})

test_that("weights that are exactly 0 are replaced by 1e-10 in every block (K-31)", {
  inputs <- example_inputs()
  m <- length(inputs$sizes)
  # Provider 1 starts at an effect where every fitted probability rounds to exactly 1. Its
  # step, about -6e9, is not clamped with this bound.
  inputs$gamma[1] <- 45
  eta <- inputs$gamma[1] + drop(inputs$design[seq_len(inputs$sizes[1]), ] %*% inputs$beta)
  expect_true(all(1 / (1 + exp(-eta)) == 1))
  dense <- dense_firth(inputs, inputs$gamma, inputs$beta)
  one <- firth_fit(inputs, max_iter = 1L, tol = 0, bound = 1e12)
  expect_close(one$gamma, inputs$gamma + dense$step[seq_len(m)], "gamma after one step")
  expect_close(one$beta, inputs$beta + dense$step[-seq_len(m)], "beta after one step")
  expect_close(one$penalized_loglik_initial, dense$penalized_loglik, "penalized log-likelihood")
})

test_that("the log-determinant floors the diagonal at 1e-12, retries with a 1e-8 ridge, then fails (K-30)", {
  schur <- matrix(c(2, 0.5, 0.25, 0.5, 1, 0.1, 0.25, 0.1, 3), 3, 3)
  log_det_schur <- as.numeric(determinant(schur, logarithm = TRUE)$modulus)
  expect_close(cpp_logistic_firth_log_determinant(c(4, 0.5, 30), schur), sum(log(c(4, 0.5, 30))) + log_det_schur,
               "positive definite")
  expect_close(cpp_logistic_firth_log_determinant(c(4, 1e-14, 1e-300), schur), sum(log(c(4, 1e-12, 1e-12))) +
                 log_det_schur, "floored diagonal")
  # A singular Schur complement fails the factorization; the ridge makes it positive
  # definite. The ridged matrix has a condition number near 1e8, so its log-determinant is
  # computed here, as K-30 defines it, from the Cholesky factor (R's chol() calls the same
  # LAPACK routine) rather than from an LU factorization, which differs by about 1e-8.
  singular <- matrix(1, 2, 2)
  expect_close(cpp_logistic_firth_log_determinant(c(1, 2), singular),
               log(2) + 2 * sum(log(diag(chol(singular + 1e-8 * diag(2))))), "ridge")
  # The factorization uses the symmetrized matrix.
  asymmetric <- schur
  asymmetric[1, 3] <- asymmetric[1, 3] + 0.5
  symmetric <- (asymmetric + t(asymmetric)) / 2
  expect_close(cpp_logistic_firth_log_determinant(c(1, 1, 1), asymmetric),
               as.numeric(determinant(symmetric, logarithm = TRUE)$modulus), "symmetrized")
  expect_error(cpp_logistic_firth_log_determinant(c(1, 2), -diag(2)), class = "std::runtime_error")
  expect_error(cpp_logistic_firth_log_determinant(1, matrix(1, 1, 2)), class = "std::invalid_argument")
})

test_that("the loop stops at the first criterion at most tol, or after max_iter iterations (K-33)", {
  inputs <- example_inputs()
  fit <- firth_fit(inputs, max_iter = 1000L, tol = 1e-5)
  criteria <- unname(fit$history[, "coefficients"])
  n <- length(criteria)
  expect_identical(fit$iterations, n)
  expect_true(fit$converged)
  expect_lte(criteria[n], 1e-5)
  expect_true(all(criteria[-n] > 1e-5))
  expect_identical(fit$criterion, criteria[n])

  # A criterion equal to tol stops the loop: the reference continues only while it is above.
  at_tol <- firth_fit(inputs, max_iter = 1000L, tol = criteria[3])
  expect_identical(at_tol$iterations, 3L)
  expect_true(at_tol$converged)

  limited <- firth_fit(inputs, max_iter = 3L, tol = 1e-300)
  expect_identical(limited$iterations, 3L)
  expect_false(limited$converged)
  expect_identical(nrow(limited$history), 3L)

  for (max_iter in c(0L, -1L)) {
    none <- firth_fit(inputs, max_iter = max_iter, tol = 1e-5)
    expect_identical(none$iterations, 0L)
    expect_false(none$converged)
    expect_identical(none$gamma, inputs$gamma)
    expect_identical(none$beta, inputs$beta)
    expect_identical(none$criterion, 1e9)
    expect_true(is.nan(none$penalized_loglik))
    expect_true(is.nan(none$penalized_loglik_initial))
    expect_identical(nrow(none$history), 0L)
  }
  # The criterion starts at 1e9, so a tol of at least 1e9 runs no iteration.
  expect_identical(firth_fit(inputs, max_iter = 10L, tol = 1e9)$iterations, 0L)
})

test_that("provider effects stay within effect_bound of their median (K-15)", {
  inputs <- engine_dataset_inputs("syn_extreme", c("x1", "x2", "x3"))
  spread <- utils::modifyList(inputs, list(gamma = seq(-30, 30, length.out = length(inputs$sizes))))
  unclamped <- firth_fit(spread, max_iter = 2L, tol = -1, bound = 1e12)
  for (bound in c(10, 2)) {
    fit <- firth_fit(spread, max_iter = 2L, tol = -1, bound = bound)
    expect_lte(max(abs(fit$gamma - stats::median(fit$gamma))), bound + 1e-12)
    expect_gt(max(abs(unclamped$gamma - stats::median(unclamped$gamma))), bound)
  }
})

test_that("two threads give results identical to one thread, and repeated runs agree (D-05)", {
  configurations <- list(example_inputs(), engine_dataset_inputs("syn_extreme", c("x1", "x2", "x3")),
                         engine_random_inputs(20261005), engine_random_inputs(20261012))
  for (inputs in configurations) {
    one <- firth_fit(inputs, threads = 1L, max_iter = 1000L)
    two <- firth_fit(inputs, threads = 2L, max_iter = 1000L)
    expect_identical(two, one)
    expect_identical(firth_fit(inputs, threads = 2L, max_iter = 1000L), two)
  }
})

test_that("the engine fits one provider, providers of one observation, and providers with only events", {
  inputs <- example_inputs()
  rows <- seq_len(inputs$sizes[1])
  single <- utils::modifyList(inputs, list(response = inputs$response[rows],
                                           design = inputs$design[rows, , drop = FALSE],
                                           sizes = inputs$sizes[1], gamma = inputs$gamma[1]))
  expect_true(firth_fit(single, max_iter = 1000L)$converged)
  small <- withr::with_seed(2, {
    y <- stats::rbinom(40, 1, 0.4)
    list(response = as.numeric(y), design = matrix(stats::rnorm(80), 40, 2), sizes = c(rep(1L, 10), rep(10L, 3)),
         gamma = rep(log(mean(y) / (1 - mean(y))), 13), beta = c(0, 0))
  })
  fit <- firth_fit(utils::modifyList(inputs, small), max_iter = 1000L)
  expect_true(fit$converged)
  expect_true(all(is.finite(c(fit$gamma, fit$beta))))
  # Firth's penalty keeps the effects of providers with only events or no events finite.
  separated <- inputs
  separated$response[seq_len(inputs$sizes[1])] <- 1
  separated$response[inputs$sizes[1] + seq_len(inputs$sizes[2])] <- 0
  fit <- firth_fit(separated, max_iter = 1000L)
  expect_true(fit$converged)
  expect_true(all(is.finite(c(fit$gamma, fit$beta))))
})

# Which C++ exception ends such a fit depends on the platform's LAPACK: where the
# factorization detects the singular matrix, inv_sympd() throws std::runtime_error; where it
# does not, a NaN reaches the clamp's median(), which throws std::logic_error (Linux CI,
# Phase 8). Either way the adapter turns it into an R error of class "C++Error", which is
# what these tests require, and fit_logistic_firth() into pprof_error_convergence.
test_that("a singular information matrix ends the fit with an error, where the reference terminated R (D-42)", {
  # A covariate column of zeros makes the Schur complement exactly singular.
  inputs <- example_inputs()
  inputs$design[, 2] <- 0
  expect_error(firth_fit(inputs, max_iter = 1000L), class = "C++Error")
  two_covariates <- example_inputs()
  two_covariates$design <- cbind(two_covariates$design[, 1], 0)
  two_covariates$beta <- c(0, 0)
  expect_error(firth_fit(two_covariates, max_iter = 1000L), class = "C++Error")
})

test_that("a non-finite design value ends the fit with an error", {
  inputs <- example_inputs()
  inputs$design[5, 2] <- NaN
  expect_error(firth_fit(inputs, max_iter = 1000L), class = "C++Error")
})

test_that("the adapter leaves its arguments unchanged", {
  inputs <- example_inputs()
  before <- unserialize(serialize(inputs, NULL))
  firth_fit(inputs, max_iter = 1000L)
  expect_identical(inputs, before)
})

test_that("the adapter rejects inconsistent inputs", {
  inputs <- example_inputs()
  firth <- function(...) firth_fit(utils::modifyList(inputs, list(...)), max_iter = 100L)
  expect_error(firth(response = inputs$response[-1]), class = "std::invalid_argument")
  expect_error(firth(gamma = inputs$gamma[-1]), class = "std::invalid_argument")
  expect_error(firth(beta = c(inputs$beta, 0)), class = "std::invalid_argument")
  expect_error(firth(sizes = c(inputs$sizes[-1], 0L, inputs$sizes[1])), class = "std::invalid_argument")
  expect_error(firth(threads = 0L), class = "std::invalid_argument")
})

test_that("a pending interrupt stops the engine between iterations", {
  skip_on_cran()
  inputs <- engine_random_inputs(99)
  started <- Sys.time()
  on.exit(setTimeLimit(), add = TRUE)
  # As in test-cpp-logistic-engines.R: the elapsed-time limit makes R's interrupt check
  # fire, which the engine runs before every iteration. With tol = -1 the criterion, which
  # is never negative, never stops the loop.
  utils::capture.output(type = "message", {
    outcome <- tryCatch({
      setTimeLimit(elapsed = 1, transient = TRUE)
      firth_fit(inputs, max_iter = 1000000L, tol = -1)
      "finished"
    }, interrupt = function(condition) "interrupted", error = function(condition) "error")
  })
  setTimeLimit()
  expect_identical(outcome, "interrupted")
  expect_lt(as.numeric(difftime(Sys.time(), started, units = "secs")), 30)
})
