# The R code of README.md runs (DEC-067). README.md is not part of the installed package, so
# the test runs where the sources are (devtools::test()) and is skipped elsewhere.
local_strict_mode()

test_that("the example code of README.md runs", {
  skip_on_cran()
  readme <- test_path("..", "..", "README.md")
  skip_if_not(file.exists(readme), "README.md not available")
  text <- readLines(readme, warn = FALSE, encoding = "UTF-8")
  starts <- grep("^``` ?r$", text)
  ends <- grep("^```$", text)
  blocks <- lapply(starts, function(start) text[seq.int(start + 1L, min(ends[ends > start]) - 1L)])
  # Installation code is not run, and pprof is already attached.
  blocks <- Filter(function(code) !any(grepl("install", code)), blocks)
  code <- grep("^library\\(pprof\\)$", unlist(blocks), value = TRUE, invert = TRUE)
  expect_gt(length(code), 0L)
  readme_env <- new.env(parent = asNamespace("pprof"))
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  expect_no_error(for (expression in parse(text = code)) eval(expression, readme_env))
  expect_s3_class(readme_env$tests, "pprof_provider_tests")
})
