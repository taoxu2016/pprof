# Loading reference fixtures and checking the package under test against them.
#
# A reference test replays a fixture's case with run_reference_case()
# (helper-reference-cases.R) against the package under test, processes the result the same
# way the generator processed the reference, and compares the two with reference_compare()
# (helper-equivalence.R) at the case's tolerance tier (helper-tolerances.R).
#
# Results are cached for the whole test run, so a method case reuses its parent fit.

reference_cache <- new.env(parent = emptyenv())

# Partial matching is reported while reference cases run (brief §5.5), and any partial match
# fails the test. The reference relied on two (D-08), allowed while its code ran (DEC-021):
# `obs` in confint() for logistic RE and CRE fits and in SM_output() for logistic FE fits, and
# `data_includ` in summary() for linear RE and CRE fits. The compatibility methods that
# replaced them (Phases 3 and 5) use full names, so no allowance is left.

# PPROF_REFERENCE_CORE and PPROF_REFERENCE_FULL override the fixture directories, for
# checking a newly generated set before it is committed and for the validation runner.
reference_fixture_dir <- function(set = "core") {
  override <- Sys.getenv(if (identical(set, "core")) "PPROF_REFERENCE_CORE" else "PPROF_REFERENCE_FULL")
  if (nzchar(override)) return(override)
  if (identical(set, "core")) return(testthat::test_path("fixtures", "reference"))
  file.path(testthat::test_path(), "..", "..", "validation", "fixtures", "reference")
}

reference_manifest <- function(set = "core") {
  key <- paste0("manifest_", set)
  if (is.null(reference_cache[[key]])) {
    path <- file.path(reference_fixture_dir(set), "manifest.json")
    if (!file.exists(path)) return(NULL)
    reference_cache[[key]] <- jsonlite::read_json(path)
  }
  reference_cache[[key]]
}

# Case ids in a fixture set, optionally restricted to some functions.
reference_case_ids <- function(funs = NULL, set = "core") {
  if (!requireNamespace("jsonlite", quietly = TRUE)) return(character())
  m <- reference_manifest(set)
  if (is.null(m)) return(character())
  ids <- vapply(m$cases, `[[`, character(1), "id")
  if (!is.null(funs)) ids <- ids[vapply(m$cases, `[[`, character(1), "fun") %in% funs]
  ids
}

# Find a fixture file in the given set first, then in the other set (a full-set case can
# depend on a core-set parent).
reference_locate <- function(file, set) {
  for (s in unique(c(set, "core", "full"))) {
    path <- file.path(reference_fixture_dir(s), file)
    if (file.exists(path)) return(path)
  }
  stop("Reference fixture file not found: ", file, call. = FALSE)
}

reference_fixture <- function(id, set = "core") {
  key <- paste0("fixture_", id)
  if (is.null(reference_cache[[key]])) {
    reference_cache[[key]] <- readRDS(reference_locate(paste0(id, ".rds"), set))
  }
  reference_cache[[key]]
}

reference_datasets_for <- function(case, set) {
  names_needed <- unique(unlist(lapply(case$args, function(a) {
    if (inherits(a, "pprof_ref_dataset") || inherits(a, "pprof_ref_element")) a$name else NULL
  })))
  for (nm in names_needed) {
    key <- paste0("dataset_", nm)
    if (is.null(reference_cache[[key]])) {
      reference_cache[[key]] <- readRDS(reference_locate(file.path("datasets", paste0(nm, ".rds")), set))
    }
  }
  stats::setNames(lapply(names_needed, function(nm) reference_cache[[paste0("dataset_", nm)]]), names_needed)
}

reference_parent_ids <- function(case) {
  unique(unlist(lapply(case$args, function(a) {
    if (inherits(a, "pprof_ref_fit") || inherits(a, "pprof_ref_value")) a$case_id else NULL
  })))
}

# Run a case (and, first, its parents) against the package under test.
reference_run <- function(id, set = "core") {
  key <- paste0("result_", id)
  if (!is.null(reference_cache[[key]])) return(reference_cache[[key]])
  fixture <- reference_fixture(id, set)
  case <- fixture$case
  results <- list()
  for (parent in reference_parent_ids(case)) results[[parent]] <- reference_run(parent, set)
  old <- options(warnPartialMatchDollar = TRUE, warnPartialMatchArgs = TRUE, warnPartialMatchAttr = TRUE)
  on.exit(options(old), add = TRUE)
  withr::local_collate("C")
  res <- run_reference_case(case, reference_datasets_for(case, set), results)
  reference_cache[[key]] <- res
  res
}

reference_lme4_matches <- function(set = "core") {
  want <- reference_manifest(set)$numerically_relevant_packages
  same <- vapply(c("lme4", "Matrix"), function(p) {
    utils::packageVersion(p) == package_version(want[[p]])
  }, logical(1))
  list(ok = all(same),
       detail = sprintf("lme4 %s and Matrix %s installed; fixtures were generated with lme4 %s and Matrix %s",
                        utils::packageVersion("lme4"), utils::packageVersion("Matrix"), want$lme4, want$Matrix))
}

# The platform that produced a fixture set (its manifest's environment) against this session
# (DEC-080). Results of iterations, root finding, and lme4 depend on the platform's floating
# point: its BLAS and LAPACK, its math library and compiler, and the R version. CI found the
# package's results outside the tolerances of some fixtures on Linux and macOS, and on Windows
# with R 4.5 and later in the collinear fit and the lme4-backed cases (Phase 8, step 1, D-53).
# So the fixtures' numbers are compared only on their own platform: R's platform string, major
# and minor version, LAPACK version, and BLAS library as the manifest records them. On every
# other platform, CI compares the package with fixtures that pprof 1.0.3 produces there
# (.github/workflows/rewrite-reference.yaml), and the tests here still compare everything but
# the numbers. PPROF_REFERENCE_OTHER_PLATFORM, when set, treats this session as another
# platform, to test that path where the fixtures were made.
reference_platform <- function(set = "core") {
  env <- reference_manifest(set)$environment
  minor <- sub("\\..*$", "", R.version$minor)
  here <- c(platform = R.version$platform, r = paste(R.version$major, minor, sep = "."),
            lapack = La_version(), blas = unname(extSoftVersion()[["BLAS"]]))
  there <- c(platform = env$platform, r = sub("^R version ([0-9]+\\.[0-9]+).*$", "\\1", env$r_version),
             lapack = env$lapack_version, blas = env$blas)
  same <- here == there
  forced <- nzchar(Sys.getenv("PPROF_REFERENCE_OTHER_PLATFORM"))
  list(ok = all(same) && !forced,
       detail = if (forced) "PPROF_REFERENCE_OTHER_PLATFORM is set" else
         paste(sprintf("%s %s (fixtures: %s)", names(here)[!same], here[!same], there[!same]), collapse = "; "))
}

reference_platform_skip_message <- function(platform) {
  paste("the fixtures' numbers are compared on the platform that produced them, and CI compares this",
        "platform with fixtures pprof 1.0.3 produces here (DEC-080):", platform$detail)
}

# For a test whose comparisons with the fixtures are numbers or iteration counts.
skip_off_reference_platform <- function(set = "core") {
  if (!requireNamespace("jsonlite", quietly = TRUE) || is.null(reference_manifest(set))) {
    testthat::skip("Reference fixtures or jsonlite not available")
  }
  platform <- reference_platform(set)
  if (!platform$ok) testthat::skip(reference_platform_skip_message(platform))
  invisible(TRUE)
}

# Collected boundary cases (brief §3.4); written to the equivalence report by validation/.
reference_boundary_log <- new.env(parent = emptyenv())

expect_reference_case <- function(id, set = "core") {
  fixture <- reference_fixture(id, set)
  case <- fixture$case
  # Class A fixes have per-case expectations (helper-reference-overrides.R, DEC-022).
  override <- reference_overrides[[id]]
  expected <- reference_expected_result(id, set)
  tier <- reference_case_tier(id, set)
  if (isTRUE(case$heavy)) testthat::skip_on_cran()
  if (identical(tier, "lme4")) {
    versions <- reference_lme4_matches(set)
    if (!versions$ok) testthat::skip(paste("lme4-backed fixture not comparable:", versions$detail))
  }
  res <- reference_run(id, set)
  m <- reference_manifest(set)
  actual <- reference_result_record(res, m$max_full_length)
  platform <- reference_platform(set)

  partial <- grep("partial match", res$warnings, value = TRUE, fixed = TRUE)
  testthat::expect(length(partial) == 0,
                   sprintf("Case %s triggered partial matching: %s", id, paste(unique(partial), collapse = "; ")))
  if (!is.null(override$check)) {
    # The per-case expectations compare numbers derived from the fixtures.
    if (!platform$ok) testthat::skip(reference_platform_skip_message(platform))
    problem <- override$check(actual)
    testthat::expect(is.null(problem), sprintf("Case %s (%s): %s", id, override$entry, problem))
    return(invisible(NULL))
  }
  testthat::expect(identical(actual$outcome, expected$outcome),
                   sprintf("Case %s: outcome '%s', reference '%s'%s", id, actual$outcome, expected$outcome,
                           if (!is.null(actual$error)) paste0(" (", actual$error$message, ")") else ""))
  if (!is.null(override$error_class) && identical(actual$outcome, "error")) {
    testthat::expect(override$error_class %in% actual$error$class,
                     sprintf("Case %s (%s): the error is not of class %s", id, override$entry, override$error_class))
  }
  if (!identical(expected$outcome, "value") || !identical(actual$outcome, "value")) return(invisible(NULL))

  # The iteration count and the stability under message = TRUE follow the platform's numbers.
  if (!is.na(expected$iterations) && platform$ok) {
    testthat::expect(identical(actual$iterations, expected$iterations),
                     sprintf("Case %s: %s iterations, reference %s", id, actual$iterations, expected$iterations))
  }
  if (isTRUE(expected$probe_identical) && platform$ok) {
    testthat::expect(isTRUE(actual$probe_identical), sprintf("Case %s: message = TRUE changed the estimates", id))
  }
  level <- if (!is.null(case$args$level)) case$args$level else 0.95
  diffs <- reference_compare(actual$value, expected$value, reference_tolerance(tier), alpha = 1 - level,
                             numeric = platform$ok)
  boundary <- if (!is.null(diffs)) diffs[diffs$kind == "flag_boundary", , drop = FALSE] else NULL
  failures <- if (!is.null(diffs)) diffs[diffs$kind != "flag_boundary", , drop = FALSE] else NULL
  if (!is.null(boundary) && nrow(boundary)) assign(id, boundary, envir = reference_boundary_log)
  details <- paste(sprintf("  %s [%s] %s", failures$path, failures$kind, failures$detail), collapse = "\n")
  testthat::expect(is.null(failures) || nrow(failures) == 0,
                   sprintf("Case %s differs from the reference (tier %s):\n%s", id, tier, details))
  if (!platform$ok) testthat::skip(reference_platform_skip_message(platform))
  invisible(diffs)
}

# One test_that() block per case of the given functions.
reference_test_cases <- function(funs, set = "core") {
  ids <- reference_case_ids(funs, set)
  if (!length(ids)) {
    testthat::test_that(paste("reference fixtures for", paste(funs, collapse = ", ")), {
      testthat::skip("Reference fixtures or jsonlite not available")
    })
    return(invisible(NULL))
  }
  for (id in ids) {
    local({
      case_id <- id
      testthat::test_that(paste("reference:", case_id), expect_reference_case(case_id, set))
    })
  }
}
