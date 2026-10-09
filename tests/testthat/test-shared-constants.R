# The named conventions keep the reference's values (ARCHITECTURE §K). Each constant's
# effect is tested with the code that uses it, in the phase that introduces that code.
local_strict_mode()

test_that("constants keep the reference values", {
  expect_identical(probability_clamp, 1e-10)                       # K-62, K-64, K-65, K-102
  expect_identical(root_bracket_width, 5)                          # K-90
  expect_identical(root_bracket_attempts, 3L)                      # K-90
  expect_identical(extreme_bracket_base, 10)                       # K-90
  expect_identical(score_weight_floor, 1e-20)                      # K-90
  expect_identical(root_tolerance, .Machine$double.eps^0.25)       # K-90: uniroot() default
  expect_identical(root_max_iter, 1000L)                           # K-90: uniroot() default
  expect_identical(data_match_atol, 1e-12)                         # DEC-005: the closed-form tier
  expect_identical(data_match_rtol, 1e-10)
  expect_identical(p_value_display_digits, 7L)                     # K-100, K-103 to K-105
  expect_identical(p_value_display_eps, 1e-10)
  expect_identical(lr_effect_clamp, 10)                            # K-101
  expect_identical(rate_scale, 100)                                # K-80
  expect_identical(rate_limits, c(0, 100))
  expect_identical(near_zero_frequency_ratio, 95 / 5)              # K-120
  expect_identical(near_zero_percent_unique, 10)
  expect_identical(correlation_threshold, 0.9)
  expect_identical(vif_threshold, 10)
})

test_that("the Poisson tests of Cox models keep pprof_py's values (K-140, K-141, K-149)", {
  expect_identical(midp_probability_floor, 1e-6)                   # K-141
  expect_identical(exact_poisson_cap, 0.999)                       # K-140
  expect_identical(byar_expected_threshold, 100)                   # K-140
  expect_identical(midp_bracket_low, 1e-10)                        # K-141: pprof_py's bracket
  expect_identical(midp_bracket_scale, 10)
  expect_identical(midp_bracket_threshold, -4.75)
  expect_identical(midp_bracket_max, 1e12)
  expect_identical(funnel_count_spread, 40)                        # K-149
  expect_identical(funnel_count_margin, 50)
  expect_identical(funnel_count_offset, 0.5)
})

test_that("the root-finder constants equal the defaults of uniroot()", {
  defaults <- formals(stats::uniroot)
  expect_identical(eval(defaults$tol), root_tolerance)
  expect_identical(as.integer(eval(defaults$maxiter)), root_max_iter)
})
