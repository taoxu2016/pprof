# Integrity of the reference fixtures (brief §3.1): files match the manifest, and the manifest
# records the pinned reference and the generation settings.

test_that("core fixture files match the manifest checksums", {
  skip_if_not_installed("jsonlite")
  m <- reference_manifest("core")
  skip_if(is.null(m), "core fixtures not present")
  dir <- reference_fixture_dir("core")
  for (case in m$cases) {
    expect_identical(unname(tools::md5sum(file.path(dir, case$file))), case$md5, info = case$id)
  }
  for (d in m$datasets) {
    expect_identical(unname(tools::md5sum(file.path(dir, d$file))), d$md5, info = d$name)
  }
})

test_that("the core manifest records the reference and the generation settings", {
  skip_if_not_installed("jsonlite")
  m <- reference_manifest("core")
  skip_if(is.null(m), "core fixtures not present")
  expect_identical(m$reference$version, "1.0.3")
  expect_identical(m$reference$git_commit, "5260838")
  expect_identical(m$reference$md5, "6fa1344f4a265811059d27a105d06d6b")
  expect_identical(m$threads, 1L)
  expect_identical(m$environment$collate, "C")
  expect_identical(m$environment$omp_thread_limit, "1")
  expect_false(isTRUE(m$generator$dirty))
  for (p in c("lme4", "Matrix", "RcppArmadillo", "Rcpp", "poibin")) {
    expect_true(!is.null(m$numerically_relevant_packages[[p]]), info = p)
  }
})

test_that("every fixture case was generated with threads = 1 where the function takes threads", {
  skip_if_not_installed("jsonlite")
  m <- reference_manifest("core")
  skip_if(is.null(m), "core fixtures not present")
  takes_threads <- c("logis_fe", "logis_firth")
  for (case in m$cases) {
    if (case$fun %in% takes_threads) expect_match(case$call, "threads = 1", fixed = TRUE, info = case$id)
  }
})
