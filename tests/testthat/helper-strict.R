# Strict mode for the tests of the rewrite (brief §5.5, .claude/rules/tests.md).
#
# Partial matching of `$`, arguments, and attributes is reported, and every warning that a
# test does not expect becomes an error, so that a partial match fails the test. Expected
# warnings are still caught by expect_warning(), whose handler runs before the conversion.
# Call local_strict_mode() at the top of each test file of the rewrite; testthat restores the
# options when the file ends. The reference's own legacy tests do not use it (DEC-021).
local_strict_mode <- function(.local_envir = parent.frame()) {
  withr::local_options(
    warnPartialMatchDollar = TRUE, warnPartialMatchArgs = TRUE, warnPartialMatchAttr = TRUE, warn = 2,
    .local_envir = .local_envir
  )
}
