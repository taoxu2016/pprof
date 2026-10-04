# Live comparison of the new C++ core with the reference's routines while both are in the
# package (Phase 3 plan, step 1): on seeded random data, each new adapter must reproduce its
# old counterpart bitwise.
#
# Temporary. The comparisons of SerBIN, BAN, and the standard score test were removed with
# those routines at the Phase 3 switch, and those of the variances (logis_fe_var()) and of
# Firth (src/Firth.cpp) at the Phase 4 switch, after they matched on every seed and fixture
# input. Remove the rest with computeDirectExp(), when the logistic RE/CRE methods are
# rewritten (Phase 5).
local_strict_mode()

legacy_seeds <- 20261002 + 1:12

test_that("direct expectations reproduce the reference bitwise", {
  for (seed in legacy_seeds) {
    inputs <- engine_random_inputs(seed)
    fit <- engine_fit(inputs)
    linear_predictor <- drop(inputs$design %*% fit$beta)
    for (threads in 1:2) {
      expect_identical(cpp_logistic_direct_expected(fit$gamma, linear_predictor, threads),
                       as.numeric(computeDirectExp(fit$gamma, linear_predictor, threads)),
                       label = sprintf("direct expectations seed %d threads %d", seed, threads))
    }
  }
})
