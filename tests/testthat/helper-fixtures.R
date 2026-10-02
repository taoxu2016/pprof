# Loading reference fixtures and checking the package under test against them.
#
# A reference test replays a fixture's case with run_reference_case()
# (helper-reference-cases.R) against the package under test, processes the result the same
# way the generator processed the reference, and compares the two with reference_compare()
# (helper-equivalence.R) at the case's tolerance tier (helper-tolerances.R).
#
# Results are cached for the whole test run, so a method case reuses its parent fit.

reference_cache <- new.env(parent = emptyenv())

# Partial matching is reported while reference cases run (brief §5.5). The reference relies
# on two partial matches (D-08); those are allowed until the code that contains them is
# rewritten. Any other partial match fails the test.
reference_allowed_partial_matches <- c(
  "partial match of 'obs' to 'observation'",
  "partial match of 'data_includ' to 'data_include'"
)

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
  res <- run_reference_case(case, reference_datasets_for(case, set), results,
                            allowed_warnings = reference_allowed_partial_matches)
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

# Collected boundary cases (brief §3.4); written to the equivalence report by validation/.
reference_boundary_log <- new.env(parent = emptyenv())

expect_reference_case <- function(id, set = "core") {
  fixture <- reference_fixture(id, set)
  case <- fixture$case
  expected <- fixture$result
  if (isTRUE(case$heavy)) testthat::skip_on_cran()
  if (identical(case$tier, "lme4")) {
    versions <- reference_lme4_matches(set)
    if (!versions$ok) testthat::skip(paste("lme4-backed fixture not comparable:", versions$detail))
  }
  res <- reference_run(id, set)
  m <- reference_manifest(set)
  actual <- reference_result_record(res, m$max_full_length)

  partial <- grep("partial match", res$warnings, value = TRUE, fixed = TRUE)
  testthat::expect(length(partial) == 0,
                   sprintf("Case %s triggered partial matching: %s", id, paste(unique(partial), collapse = "; ")))
  testthat::expect(identical(actual$outcome, expected$outcome),
                   sprintf("Case %s: outcome '%s', reference '%s'%s", id, actual$outcome, expected$outcome,
                           if (!is.null(actual$error)) paste0(" (", actual$error$message, ")") else ""))
  if (!identical(expected$outcome, "value") || !identical(actual$outcome, "value")) return(invisible(NULL))

  if (!is.na(expected$iterations)) {
    testthat::expect(identical(actual$iterations, expected$iterations),
                     sprintf("Case %s: %s iterations, reference %s", id, actual$iterations, expected$iterations))
  }
  if (isTRUE(expected$probe_identical)) {
    testthat::expect(isTRUE(actual$probe_identical), sprintf("Case %s: message = TRUE changed the estimates", id))
  }
  level <- if (!is.null(case$args$level)) case$args$level else 0.95
  diffs <- reference_compare(actual$value, expected$value, reference_tolerance(case$tier), alpha = 1 - level)
  boundary <- if (!is.null(diffs)) diffs[diffs$kind == "flag_boundary", , drop = FALSE] else NULL
  failures <- if (!is.null(diffs)) diffs[diffs$kind != "flag_boundary", , drop = FALSE] else NULL
  if (!is.null(boundary) && nrow(boundary)) assign(id, boundary, envir = reference_boundary_log)
  testthat::expect(is.null(failures) || nrow(failures) == 0,
                   sprintf("Case %s differs from the reference (tier %s):\n%s", id, case$tier,
                           paste(sprintf("  %s [%s] %s", failures$path, failures$kind, failures$detail), collapse = "\n")))
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
