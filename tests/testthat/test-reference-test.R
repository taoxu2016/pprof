# Characterization tests (brief §6 A): provider tests, test(), against the reference fixtures.
reference_test_cases("test")

test_that("the exact tests' statistics, and no other statistic, are compared on their tail probability (DEC-083)", {
  skip_if_not_installed("jsonlite")
  ids <- reference_case_ids("test")
  exact <- ids[vapply(ids, reference_exact_statistic_id, logical(1))]
  binary <- paste0("test-binary-exact-", c("two.sided", "greater", "less", "null0", "null-negative", "null-integer",
                                           "level90", "parm"))
  expect_setequal(exact, c(binary, "test-binary-bad-null", "test-extreme-exact", "test-extreme-chr-exact-parm",
                           "test-extreme-int-parm", "test-firth-exact"))
})

test_that("an exact statistic matches within the tolerance on its tail probability, of the same sign (DEC-083)", {
  tol <- reference_tolerance("iterative")
  table <- function(stat, p = c(0.5, 7e-15)) {
    out <- data.frame(flag = factor(c(0, 1)), p = p, stat = stat)
    colnames(out) <- c("flag", "p value", "stat")
    out
  }
  reference <- table(c(0.25, 7.78431))
  # Last-bit noise moves an extreme statistic by about 4e-3 (D-53): within the rule, not the tier.
  noisy <- table(c(0.25, 7.78431 + 4e-3))
  expect_null(reference_compare(noisy, reference, tol, alpha = 0.05, exact_statistic = TRUE))
  expect_match(reference_compare(noisy, reference, tol, alpha = 0.05)$path, "$stat", fixed = TRUE)
  # A statistic in the body of the distribution is held to the tier.
  shifted <- table(c(0.25 + 1e-8, 7.78431))
  expect_match(reference_compare(shifted, reference, tol, alpha = 0.05, exact_statistic = TRUE)$detail,
               "1 of 2 exact statistics outside tolerance")
  # Statistics of the opposite sign, and infinite values in other positions, do not match.
  expect_false(is.null(reference_compare(table(c(-1e-3, 7.78431)), table(c(1e-3, 7.78431)), tol, alpha = 0.05,
                                         exact_statistic = TRUE)))
  expect_identical(reference_compare(table(c(0.25, Inf)), reference, tol, alpha = 0.05, exact_statistic = TRUE)$kind,
                   "infinite")
  # The rule applies to the statistic only: the p-values are compared as before.
  expect_match(reference_compare(table(c(0.25, 7.78431), p = c(0.5, 1e-11)), reference, tol, alpha = 0.05,
                                 exact_statistic = TRUE)$path, "$p value", fixed = TRUE)
})
