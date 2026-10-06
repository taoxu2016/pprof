# The per-case expectations of Class A fixes (helper-reference-overrides.R): each derivation
# reproduces the reference where the reference is right (Phase 3 plan, risks).
local_strict_mode()

test_that("every per-case expectation names a register entry and an existing case", {
  ids <- names(reference_overrides)
  # 21 for the Class A fixes, and D-30's one-covariate error, kept on R 4.5 and later, where
  # pprof 1.0.3 computes the test (DEC-082).
  expect_length(ids, 22L)
  expect_true(all(ids %in% reference_case_ids()))
  entries <- vapply(reference_overrides, `[[`, character(1), "entry")
  expect_true(all(grepl("^D-[0-9]{2}$", entries)))
})

test_that("the logis_cre fit behind its D-27 expectation is the reference's fit of the same data (Phase 5)", {
  plain <- override_value("logis_cre-extreme")$coefficient
  integer_ids <- override_value("logis_cre-extreme-int")$coefficient
  expect_identical(integer_ids$FE, plain$FE)
  expect_identical(integer_ids$RE, plain$RE)
})

test_that("the fits behind the D-27, D-28, and D-29 expectations are the reference's fit of the same data", {
  plain <- override_value("logis_fe-extreme")$coefficient
  for (id in c("logis_fe-extreme-int", "logis_fe-extreme-fac", "logis_fe-extreme-hospital")) {
    other <- override_value(id)$coefficient
    expect_identical(unname(other$beta), unname(plain$beta), label = id)
    expect_identical(unname(other$gamma), unname(plain$gamma), label = id)
  }
  ids <- rownames(override_value("logis_fe-extreme-fac")$coefficient$gamma)
  expect_identical(ids, as.character(as.integer(rownames(plain$gamma)) * 10L))
})

test_that("re-pairing the measure limits leaves the numeric-ID case unchanged (D-19)", {
  order <- override_d19_limit_order(override_value("logis_fe-extreme"))
  expect_identical(order, rownames(override_value("logis_fe-extreme")$coefficient$gamma))
  value <- override_value("confint-extreme-sm-exact")
  expect_identical(override_d19_repair(value, order), value)
  chr_order <- override_d19_limit_order(override_value("logis_fe-extreme-chr"))
  expect_false(identical(chr_order, rownames(override_value("logis_fe-extreme-chr")$coefficient$gamma)))
})

test_that("renaming a fit without renames reproduces it (D-18)", {
  fixture <- reference_fixture("logis_fe-binary-columns")
  expect_identical(override_renamed_fit("logis_fe-binary-columns", character())(fixture), fixture$result)
})

test_that("the D-30 expectation applies K-101 to the reference's one-covariate fits (D-30)", {
  result <- override_lr_two_covariates(reference_fixture("summary-screening-twocov-lr"))
  expect_identical(rownames(result$value), c("x1", "x2"))
  expect_true(all(result$value$stat > 0))
  expect_identical(result$value[["p value"]], stats::pchisq(result$value$stat, 1, lower.tail = FALSE))
})

test_that("the methods that relied on partial matching no longer do (D-08, DEC-021)", {
  # The reference's confint() of logistic RE and CRE fits matched `obs`, and its summary() of
  # linear RE and CRE fits `data_includ`; reference_run() reports every partial match.
  for (id in c("confint-logis-re-extreme-sm", "confint-logis-cre-extreme-sm", "summary-linear-re", "summary-linear-cre",
               "SM_output-binary-default")) {
    result <- reference_run(id)
    expect_identical(result$outcome, "value")
    expect_false(any(grepl("partial match", result$warnings, fixed = TRUE)), info = id)
  }
})
