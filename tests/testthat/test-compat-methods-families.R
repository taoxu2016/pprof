# The compatibility methods of linear_fe, linear_re, logis_re, linear_cre, and logis_cre
# objects (Phase 5, DEC-049): the Class A and C fixes and the behaviors they keep. Their
# results are checked against the reference's fixtures in test-reference-*.R.
local_strict_mode()

compat_family_data <- function(outcome) {
  data <- reference_datasets_for(list(args = list(ref_dataset(paste0(outcome, "_example")))), "core")
  data[[1]]
}

compat_family_fits <- function() {
  if (is.null(family_case_cache$compat_fits)) {
    linear <- compat_family_data("linear")
    binary <- compat_family_data("binary")
    z <- paste0("z", 1:5)
    family_case_cache$compat_fits <- withr::with_collate("C", suppressMessages(list(
      linear_fe = linear_fe(data = linear, Y.char = "Y", Z.char = z, ProvID.char = "ProvID"),
      linear_re = linear_re(data = linear, Y.char = "Y", Z.char = z, ProvID.char = "ProvID"),
      linear_cre = linear_cre(data = linear, Y.char = "Y", wb.char = c("z1", "z2"), other.char = z[3:5],
                              ProvID.char = "ProvID"),
      logis_re = logis_re(data = binary[binary$ProvID <= 40, ], Y.char = "Y", Z.char = z, ProvID.char = "ProvID")
    )))
  }
  family_case_cache$compat_fits
}

test_that("an integer null works in every linear FE method, as the equal double (D-14)", {
  skip_on_cran()
  fit <- compat_family_fits()$linear_fe
  expect_identical(test(fit, null = 0L), test(fit, null = 0))
  expect_identical(SM_output(fit, stdz = c("indirect", "direct"), null = 1L),
                   SM_output(fit, stdz = c("indirect", "direct"), null = 1))
  expect_identical(confint(fit, null = 0L), confint(fit, null = 0))
  expect_s3_class(plot(fit, null = 0L), "ggplot")
  expect_error(test(fit, null = "abc"), class = "pprof_error_invalid_input")
})

test_that("a linear_fe object without its variance type fails in the methods that need it (D-16)", {
  skip_on_cran()
  fit <- compat_family_fits()$linear_fe
  attr(fit$variance$gamma, "description") <- NULL
  expect_error(test(fit), class = "pprof_error_invalid_input")
  expect_error(confint(fit), class = "pprof_error_invalid_input")
  # SM_output() and summary() do not read the variance type, as in the reference.
  expect_identical(SM_output(fit), SM_output(compat_family_fits()$linear_fe))
  expect_identical(summary(fit), summary(compat_family_fits()$linear_fe))
})

test_that("the logistic RE intervals and measures do not depend on the thread count (D-21)", {
  skip_on_cran()
  fit <- compat_family_fits()$logis_re
  expect_identical(SM_output(fit, stdz = c("indirect", "direct"), threads = 1),
                   SM_output(fit, stdz = c("indirect", "direct"), threads = 2))
  expect_identical(SM_output(fit, stdz = "direct"), SM_output(fit, stdz = "direct", threads = 1))
  intervals <- confint(fit, stdz = c("indirect", "direct"))
  expect_named(intervals, c("CI.indirect_ratio", "CI.indirect_rate", "CI.direct_ratio", "CI.direct_rate"))
})

test_that("providers stored as integers can be selected with parm (D-27)", {
  skip_on_cran()
  linear <- compat_family_data("linear")
  linear$ProvID <- as.integer(linear$ProvID)
  fit <- suppressMessages(linear_fe(data = linear, Y.char = "Y", Z.char = paste0("z", 1:5), ProvID.char = "ProvID"))
  selected <- test(fit, parm = c(3L, 1L))
  expect_identical(rownames(selected), c("1", "3"))
  expect_identical(SM_output(fit, parm = 2:3)$indirect.difference,
                   SM_output(fit)$indirect.difference[2:3, , drop = FALSE])
  expect_identical(nrow(confint(fit, parm = 1:4)$CI.indirect), 4L)
  expect_error(test(fit, parm = "1"), class = "pprof_error_invalid_input")
})

test_that("the RE and CRE interval tables keep the reference's attributes (D-33)", {
  skip_on_cran()
  fits <- compat_family_fits()
  linear <- confint(fits$linear_re, stdz = c("indirect", "direct"), level = 0.9)
  expect_identical(attr(linear$CI.indirect, "confidence_level"), "0.9 %")
  expect_identical(attr(linear$CI.direct, "model"), "RE linear")
  expect_identical(attr(confint(fits$linear_cre)$CI.indirect, "model"), "CRE linear")
  logistic <- confint(fits$logis_re, stdz = "indirect", alternative = "greater")
  expect_identical(attr(logistic$CI.indirect_rate, "type"), "upper one-sided")
  expect_identical(attr(logistic$CI.indirect_rate, "model"), "RE logis")
  effects <- confint(fits$linear_re, option = "alpha")
  expect_identical(colnames(effects), c("Estimate", "alpha.Lower", "alpha.Upper"))
  expect_identical(attr(effects, "description"), "Provider Effects")
  expect_error(confint(fits$linear_re, option = "alpha", alternative = "less"), class = "pprof_error_invalid_input")
})

test_that("the RE and CRE summaries select the intercept only as \"(intercept)\" (D-44)", {
  skip_on_cran()
  fit <- compat_family_fits()$linear_re
  expect_identical(rownames(summary(fit, parm = "(intercept)")), "(Intercept)")
  expect_identical(nrow(summary(fit, parm = "(Intercept)")), 0L)
  expect_identical(rownames(summary(fit, parm = c(2, 1))), c("z1", "(Intercept)"))
  expect_error(summary(fit, parm = TRUE), class = "pprof_error_invalid_input")
})

test_that("the RE and CRE tests take a single number as the null (D-45)", {
  skip_on_cran()
  fits <- compat_family_fits()
  expect_identical(test(fits$linear_re, null = 0L), test(fits$linear_re, null = 0))
  expect_error(test(fits$linear_re, null = c(0, 0.1)), class = "pprof_error_invalid_input")
  expect_error(test(fits$logis_re, null = "median"), class = "pprof_error_invalid_input")
})

test_that("the methods of RE and CRE objects read no numbers from data_include (D-11)", {
  skip_on_cran()
  # With character IDs, data_include is text; the methods rebuild the model from the other
  # fields and give the results of the same fit with numeric IDs.
  linear <- compat_family_data("linear")
  numeric_fit <- compat_family_fits()$linear_re
  linear$ProvID <- sprintf("P%03d", linear$ProvID)
  character_fit <- suppressMessages(linear_re(data = linear, Y.char = "Y", Z.char = paste0("z", 1:5),
                                              ProvID.char = "ProvID"))
  expect_true(is.character(character_fit$data_include$Y))
  expect_identical(unname(as.matrix(test(character_fit)[-1])), unname(as.matrix(test(numeric_fit)[-1])))
  expect_identical(unname(as.matrix(SM_output(character_fit)$indirect.difference)),
                   unname(as.matrix(SM_output(numeric_fit)$indirect.difference)))
})

test_that("tests of fits whose provider variance is 0 have missing flags, as in the reference", {
  skip_on_cran()
  pinned <- reference_lme4_matches()
  skip_if_not(pinned$ok, pinned$detail)
  # Data without provider effects (seed 4 of dev/design/phase5-facts/09_singular_re_fits.R):
  # lme4 estimates the provider variance as 0, so the effects and their standard errors are 0,
  # and the reference's test() returns NaN statistics and p-values and missing flags (a factor
  # without levels) for every provider. Found by validation/run-simulation.R, where the
  # wrapper failed until the flags were stored as integers.
  data <- withr::with_seed(4, {
    provider <- rep(seq_len(50), sample(10:60, 50, replace = TRUE))
    n <- length(provider)
    x1 <- stats::rnorm(n) + stats::rnorm(50, 0, 0.5)[provider]
    x2 <- stats::rnorm(n)
    x3 <- stats::rbinom(n, 1, 0.4)
    data.frame(y = 0.5 * x1 - 0.3 * x2 + 0.2 * x3 + stats::rnorm(n), hospital = provider, x1 = x1, x2 = x2, x3 = x3)
  })
  fits <- withr::with_collate("C", suppressMessages(list(
    linear_re = linear_re(data = data, Y.char = "y", Z.char = c("x1", "x2", "x3"), ProvID.char = "hospital"),
    linear_cre = linear_cre(data = data, Y.char = "y", wb.char = "x1", other.char = c("x2", "x3"),
                            ProvID.char = "hospital")
  )))
  for (name in names(fits)) {
    expect_true(lme4::isSingular(attr(fits[[name]], "model")), label = paste(name, "is singular"))
    for (alternative in c("two.sided", "less")) {
      result <- test(fits[[name]], alternative = alternative)
      label <- paste(name, alternative)
      expect_identical(levels(result$flag), character(0), label = label)
      expect_true(all(is.na(result$flag)), label = label)
      expect_true(all(is.nan(result$`p value`)) && all(is.nan(result$stat)), label = label)
      expect_identical(result$Std.Error, rep(0, 50), label = label)
    }
  }
  model <- suppressMessages(fit_linear_re(y ~ x1 + x2 + x3, data, "hospital"))
  expect_identical(test_providers(model)$table$flag, rep(NA_integer_, 50))
})

test_that("only the methods that use the conditional standard deviations need the lme4 fit (D-46)", {
  skip_on_cran()
  fit <- compat_family_fits()$linear_cre
  stripped <- fit
  attr(stripped, "model") <- NULL
  # As in the reference, SM_output() does not need it, and test() and confint() of CRE fits fail.
  expect_identical(SM_output(stripped, stdz = c("indirect", "direct")), SM_output(fit, stdz = c("indirect", "direct")))
  expect_error(test(stripped), class = "pprof_error_invalid_input")
  expect_error(confint(stripped), class = "pprof_error_invalid_input")
  # The reference's summary() took its intervals from lme4's confint() of the fit and failed;
  # the wrapper computes them from the stored covariance, as lme4 does (D-46).
  expect_identical(summary(stripped), summary(fit))
})
