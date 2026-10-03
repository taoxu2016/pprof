# Live comparison of the new C++ core with the reference's routines while both are in the
# package (Phase 3 plan, step 1): on seeded random data, each new adapter must reproduce its
# old counterpart bitwise, or fail where it fails.
#
# Temporary. The comparisons of SerBIN, BAN, and the standard score test were removed with
# those routines at the switch to the compatibility wrappers, after they matched on every
# seed and fixture input. Remove the rest with logis_fe_var() and computeDirectExp(), when
# logis_firth() and the logistic RE/CRE methods are rewritten.
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
