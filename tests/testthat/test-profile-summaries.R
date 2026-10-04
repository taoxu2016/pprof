# The computations the plots draw (DEC-056): K-112's reference values and interval flags, and
# K-113's size groups and flag shares, against hand computation.
local_strict_mode()

test_that("each measure has its reference value: 1, the population rate, or 0 (K-112)", {
  expect_identical(profile_reference_value("ratio"), 1)
  expect_identical(profile_reference_value("rate", 38.5), 38.5)
  expect_null(profile_reference_value("rate"))
  expect_identical(profile_reference_value("difference"), 0)
  expect_error(profile_reference_value("odds"), class = "pprof_error_invalid_input")
})

test_that("intervals are flagged against the reference as caterpillar_plot() flags them (K-112)", {
  lower <- c(0.5, 1.2, 0.8, NA, 0.9, 1.3)
  upper <- c(0.9, 1.5, 1.1, 1.2, NA, 0.8)
  # Two-sided: lower when the upper limit is below the reference, checked first, else higher
  # when the lower limit is above it; the last interval, whose limits are reversed, is lower.
  expect_identical(profile_interval_flags(lower, upper, 1), c(-1L, 1L, 0L, NA, NA, -1L))
  expect_identical(profile_interval_flags(lower, upper, 1, "greater"), c(0L, 1L, 0L, NA, 0L, 1L))
  expect_identical(profile_interval_flags(lower, upper, 1, "less"), c(-1L, 0L, 0L, 0L, NA, -1L))
  # The reference's rule, written out (R/caterpillar_plot.R at 5260838).
  reference <- ifelse(upper < 1, "Lower", ifelse(lower > 1, "Higher", "Normal"))
  expect_identical(c("Lower", "Normal", "Higher")[profile_interval_flags(lower, upper, 1) + 2L], reference)
  expect_identical(profile_interval_flags(c(-Inf, 2), c(0.5, Inf), 1), c(-1L, 1L))
  expect_error(profile_interval_flags(lower, upper, 1, "both"), class = "pprof_error_invalid_input")
})

test_that("providers are grouped at the quantiles of their sizes (K-113)", {
  n_obs <- c(5L, 8L, 12L, 12L, 20L, 31L, 40L, 55L)
  # Type 7 quantiles at 0, 1/4, 1/2, 3/4, 1: 5, 11, 16, 33.25, 55; intervals closed on the right.
  groups <- profile_size_groups(n_obs, 4)
  expect_identical(levels(groups), c("Q1", "Q2", "Q3", "Q4"))
  expect_identical(as.character(groups), c("Q1", "Q1", "Q2", "Q2", "Q3", "Q3", "Q4", "Q4"))
  expect_identical(groups, cut(n_obs, stats::quantile(n_obs, (0:4) / 4), include.lowest = TRUE,
                               labels = paste0("Q", 1:4)))
  # A size equal to a break belongs to the lower group.
  expect_identical(as.character(profile_size_groups(c(1L, 2L, 3L), 2)), c("Q1", "Q1", "Q2"))
  expect_identical(as.character(profile_size_groups(n_obs, 1)), rep("Q1", 8))
  expect_error(profile_size_groups(rep(50L, 8), 4), class = "pprof_error_invalid_input")
  expect_error(profile_size_groups(50L, 4), class = "pprof_error_invalid_input")
})

test_that("flag shares count the providers of each size group and overall, a missing flag included (K-113)", {
  n_obs <- c(5L, 8L, 12L, 12L, 20L, 31L, 40L, 55L)
  flag <- c(1L, 0L, 0L, -1L, NA, 0L, 1L, 0L)
  shares <- profile_flag_shares(flag, n_obs, 2)
  categories <- c("higher", "as expected", "lower")
  expected <- data.frame(
    group = factor(c("Q1", "Q1", "Q1", "Q2", "Q2", "Q2", "Overall", "Overall", "Overall", "Overall"),
                   levels = c("Q1", "Q2", "Overall")),
    category = factor(c("higher", "as expected", "lower", "higher", "as expected", NA,
                        "higher", "as expected", "lower", NA), levels = categories),
    count = c(1L, 2L, 1L, 1L, 2L, 1L, 2L, 4L, 1L, 1L),
    share = c(0.25, 0.5, 0.25, 0.25, 0.5, 0.25, 0.25, 0.5, 0.125, 0.125)
  )
  expect_identical(shares, expected)
  # Factor flags, as the old test() results have them, give the same shares.
  expect_identical(profile_flag_shares(factor(flag), n_obs, 2), expected)
  # Without missing flags there is no missing category, and only categories that occur appear.
  none <- profile_flag_shares(rep(0L, 8), n_obs, 2)
  expect_identical(as.character(none$category), rep("as expected", 3))
  expect_identical(none$share, c(1, 1, 1))
})
