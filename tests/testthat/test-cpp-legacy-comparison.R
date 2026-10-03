# Live comparison of the new C++ core with the reference's routines while both are in the
# package (Phase 3 plan, step 1): on seeded random data, each new adapter must reproduce its
# old counterpart bitwise, or fail where it fails.
#
# Temporary. The comparisons of SerBIN, BAN, and the standard score test were removed with
# those routines at the switch to the compatibility wrappers, after they matched on every
# seed and fixture input. Remove the rest with logis_fe_var() and computeDirectExp(), when
# logis_firth() and the logistic RE/CRE methods are rewritten, and the Firth comparisons
# with src/Firth.cpp at the Phase 4 switch.
local_strict_mode()

legacy_seeds <- 20261002 + 1:12

legacy_outcome <- function(expr) {
  tryCatch(expr, error = function(e) structure(list(message = conditionMessage(e)), class = "legacy_error"))
}

test_that("variances and direct expectations reproduce the reference bitwise", {
  for (seed in legacy_seeds) {
    inputs <- engine_random_inputs(seed)
    fit <- engine_fit(inputs)
    old_variance <- legacy_outcome(logis_fe_var(inputs$response, inputs$design, inputs$sizes, fit$gamma, fit$beta))
    new_variance <- legacy_outcome(cpp_logistic_variance(inputs$design, inputs$sizes, fit$gamma, fit$beta))
    if (inherits(old_variance, "legacy_error")) {
      expect_true(inherits(new_variance, "legacy_error"),
                  label = sprintf("variance seed %d fails like the reference", seed))
    } else {
      expect_identical(new_variance$beta, old_variance$var.beta, label = sprintf("Var(beta) seed %d", seed))
      expect_identical(new_variance$gamma, as.numeric(old_variance$var.gamma),
                       label = sprintf("Var(gamma) seed %d", seed))
    }
    linear_predictor <- drop(inputs$design %*% fit$beta)
    for (threads in 1:2) {
      expect_identical(cpp_logistic_direct_expected(fit$gamma, linear_predictor, threads),
                       as.numeric(computeDirectExp(fit$gamma, linear_predictor, threads)),
                       label = sprintf("direct expectations seed %d threads %d", seed, threads))
    }
  }
})

# --- Firth (Phase 4 plan, step 1) -----------------------------------------------------------

# The reference's routine as logis_firth() calls it (stop = "beta"), keeping the penalized
# log-likelihood of every iteration.
legacy_firth <- function(inputs, max_iter, tol, bound = 10, threads = 1L) {
  logis_firth_prov(as.matrix(inputs$response), inputs$design, as.numeric(inputs$sizes), inputs$gamma, inputs$beta,
                   n_obs = length(inputs$response), m = length(inputs$sizes), threads = threads, tol = tol,
                   max_iter = as.integer(max_iter), bound = bound, message = FALSE, stop = "beta", need_trace = TRUE)
}

# The bundled example, syn_extreme (providers with no events and with only events), and the
# seeded random data (providers of 1 to 80 observations, most seeds with one provider
# without events and one with only events).
legacy_firth_configurations <- function() {
  configurations <- list(example = engine_dataset_inputs("binary_example", paste0("z", 1:5)),
                         extreme = engine_dataset_inputs("syn_extreme", c("x1", "x2", "x3")))
  for (seed in legacy_seeds) configurations[[paste("seed", seed)]] <- engine_random_inputs(seed)
  configurations
}

test_that("the Firth engine reproduces the reference routine bitwise", {
  configurations <- legacy_firth_configurations()
  for (name in names(configurations)) {
    inputs <- configurations[[name]]
    for (tol in c(1e-5, 1e-10)) {
      label <- sprintf("%s, tol %g", name, tol)
      old <- legacy_firth(inputs, 1000L, tol)
      new <- firth_fit(inputs, max_iter = 1000L, tol = tol)
      expect_identical(new$gamma, as.numeric(old$gamma), label = paste(label, "gamma"))
      expect_identical(new$beta, as.numeric(old$beta), label = paste(label, "beta"))
      expect_identical(new$iterations, old$iter, label = paste(label, "iterations"))
      expect_identical(new$criterion, old$crit, label = paste(label, "criterion"))
      expect_identical(new$penalized_loglik, old$loglik, label = paste(label, "penalized log-likelihood"))
      expect_identical(unname(new$history[, "penalized_loglik"]), as.numeric(old$history),
                       label = paste(label, "penalized log-likelihood of every iteration"))
      expect_true(new$converged, label = paste(label, "converged"))
    }
  }
})

test_that("the Firth engine matches the reference routine after every iteration", {
  configurations <- legacy_firth_configurations()[c("example", "extreme", "seed 20261003")]
  # Starting values far from the estimates: without a line search the fit diverges, the
  # clamp acts (checked below), and most weights are floored. Calling the reference on
  # inputs where it fails would terminate R (D-42); the new engine runs these 12 iterations
  # without failing.
  far <- configurations$example
  far$gamma[] <- 6
  far$beta[] <- 2
  configurations$far <- far
  # Provider 1 starts where every fitted probability rounds to exactly 1, so its weights are
  # floored at 1e-10 (K-31).
  floored <- configurations$example
  floored$gamma[1] <- 45
  configurations$floored <- floored
  for (name in names(configurations)) {
    inputs <- configurations[[name]]
    for (k in 1:12) {
      # The criterion is never negative, so with tol = -1 both run exactly k iterations.
      old <- legacy_firth(inputs, k, -1)
      new <- firth_fit(inputs, max_iter = k, tol = -1)
      label <- sprintf("%s, iteration %d", name, k)
      expect_identical(new$iterations, k, label = label)
      expect_identical(new$gamma, as.numeric(old$gamma), label = paste(label, "gamma"))
      expect_identical(new$beta, as.numeric(old$beta), label = paste(label, "beta"))
      expect_identical(new$criterion, old$crit, label = paste(label, "criterion"))
      expect_identical(unname(new$history[, "penalized_loglik"]), as.numeric(old$history),
                       label = paste(label, "penalized log-likelihood"))
    }
  }
  unclamped <- firth_fit(far, max_iter = 3L, tol = -1, bound = 1e6)
  expect_false(identical(unclamped$gamma, firth_fit(far, max_iter = 3L, tol = -1)$gamma))
})

test_that("the log-determinant reproduces the reference's logdet_info() (K-30)", {
  schur <- matrix(c(2, 0.5, 0.25, 0.5, 1, 0.1, 0.25, 0.1, 3), 3, 3)
  schur[1, 2] <- schur[1, 2] + 1e-15 # not exactly symmetric, as in a fit
  cases <- list(
    positive_definite = list(c(4, 0.5, 30), schur),
    small_diagonal = list(c(4, 1e-14, 1e-300), schur),
    ridge = list(c(1, 2), matrix(1, 2, 2)),
    failure = list(c(1, 2), -diag(2))
  )
  for (name in names(cases)) {
    old <- legacy_outcome(logdet_info(cases[[name]][[1]], cases[[name]][[2]]))
    new <- legacy_outcome(cpp_logistic_firth_log_determinant(cases[[name]][[1]], cases[[name]][[2]]))
    if (name == "failure") {
      expect_s3_class(old, "legacy_error")
      expect_s3_class(new, "legacy_error")
    } else {
      expect_identical(new, old, label = name)
    }
  }
})
