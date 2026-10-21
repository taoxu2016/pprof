# Build the isolated, pinned library that holds pprofR 0.2.0, the reference of the logistic extensions
# phase's new features (dev/logistic_brief.md §3.1; LOGISTIC_DESIGN §G.1; DEC-156).
#
# Usage, from the repository root:
#   Rscript dev/reference/pprofr/setup_pprofr_library.R [library-dir]
#
# The library (default dev/reference/pprofr/lib, gitignored) contains:
#   - pprofR built from commit f23c288 with `git archive`, which needs the commit in the local object
#     store (fetched read-only from the branch of the upstream repository that holds it). Its files are
#     extracted into a temporary folder, never into the working tree, and are not part of this
#     repository;
#   - its hard dependencies (Depends, Imports, LinkingTo: Rcpp, RcppArmadillo, poibin) from the CRAN
#     snapshot of the pprof 1.0.3 reference library (DEC-017), at the versions that
#     dev/reference/library-lock.json records.
# Nothing is taken from the user library. Then pprofR's own tests run against the installed package,
# with testthat from the user library.
#
# It writes dev/reference/pprofr/pprofr-library-lock.json, the committed record of the library: versions
# and checks only, never the text of pprofR's files.

pprofr_commit <- "f23c2889b59108f9506da3f91327c3f239945a63"
pprofr_version <- "0.2.0"
snapshot_date <- "2026-10-01"
snapshot_repo <- paste0("https://packagemanager.posit.co/cran/", snapshot_date)

args <- commandArgs(trailingOnly = TRUE)
lib_dir <- if (length(args) >= 1) args[[1]] else file.path("dev", "reference", "pprofr", "lib")
dir.create(lib_dir, recursive = TRUE, showWarnings = FALSE)
lib_dir <- normalizePath(lib_dir, winslash = "/")
lock_file <- file.path("dev", "reference", "pprofr", "pprofr-library-lock.json")
reference_lock_file <- file.path("dev", "reference", "library-lock.json")
stopifnot(requireNamespace("callr", quietly = TRUE), requireNamespace("jsonlite", quietly = TRUE),
          requireNamespace("testthat", quietly = TRUE))

# 1. pprofR's sources, from the local object store -----------------------------------------------
present <- system2("git", c("cat-file", "-e", paste0(pprofr_commit, "^{commit}")), stdout = FALSE, stderr = FALSE)
if (present != 0L) {
  stop("Commit f23c288 is not in the local object store. Fetch it read-only from the branch of the ",
       "upstream repository that holds it (git fetch <upstream> <branch>), and run this script again.",
       call. = FALSE)
}
source_dir <- file.path(tempdir(), "pprofr-source")
unlink(source_dir, recursive = TRUE)
dir.create(source_dir)
archive <- tempfile(fileext = ".tar")
if (system2("git", c("archive", "--format=tar", "-o", shQuote(archive), pprofr_commit)) != 0L) {
  stop("git archive of commit f23c288 failed.", call. = FALSE)
}
# git archive writes a pax header with the commit, which untar() skips with a warning.
withCallingHandlers(utils::untar(archive, exdir = source_dir, tar = "internal"), warning = function(w) {
  if (grepl("pax global extended headers", conditionMessage(w), fixed = TRUE)) invokeRestart("muffleWarning")
})
unlink(archive)
desc <- read.dcf(file.path(source_dir, "DESCRIPTION"),
                 fields = c("Package", "Version", "Depends", "Imports", "LinkingTo"))
if (!identical(unname(desc[1, "Package"]), "pprofR") || !identical(unname(desc[1, "Version"]), pprofr_version)) {
  stop("Commit f23c288 does not hold pprofR ", pprofr_version, ".", call. = FALSE)
}

# 2. The dependency closure, at the reference lock's versions --------------------------------------
direct <- unlist(lapply(c("Depends", "Imports", "LinkingTo"), function(field) {
  if (is.na(desc[1, field])) return(character())
  sub("[ (].*$", "", trimws(strsplit(desc[1, field], ",")[[1]]))
}))
base_pkgs <- rownames(utils::installed.packages(priority = "base"))
direct <- setdiff(direct, c("R", base_pkgs))
src_db <- utils::available.packages(repos = snapshot_repo, type = "source")
closure <- tools::package_dependencies(direct, db = src_db, which = c("Depends", "Imports", "LinkingTo"),
                                       recursive = TRUE)
needed <- sort(unique(setdiff(c(direct, unlist(closure)), base_pkgs)))
reference_lock <- jsonlite::read_json(reference_lock_file, simplifyVector = TRUE)$packages
locked <- stats::setNames(reference_lock$version, reference_lock$package)
unlocked <- setdiff(needed, names(locked))
if (length(unlocked)) stop("Not in the reference lock: ", paste(unlocked, collapse = ", "), call. = FALSE)
moved <- needed[unname(src_db[needed, "Version"]) != unname(locked[needed])]
if (length(moved)) {
  stop("The snapshot's versions differ from the reference lock: ", paste(moved, collapse = ", "), call. = FALSE)
}

# 3. Install the dependencies in an isolated child session -----------------------------------------
binary_type <- if (.Platform$OS.type == "windows") {
  "win.binary"
} else if (startsWith(.Platform$pkgType, "mac.binary")) {
  .Platform$pkgType
} else {
  "source"
}
bin_db <- utils::available.packages(repos = snapshot_repo, type = binary_type)
in_bin <- needed[needed %in% rownames(bin_db)]
as_binary <- in_bin[unname(bin_db[in_bin, "Version"]) == unname(src_db[in_bin, "Version"])]
as_source <- setdiff(needed, as_binary)
installed <- utils::installed.packages(lib.loc = lib_dir)
is_current <- function(pkg) {
  pkg %in% rownames(installed) && identical(unname(installed[pkg, "Version"]), unname(src_db[pkg, "Version"]))
}
binary_to_install <- as_binary[!vapply(as_binary, is_current, logical(1))]
source_to_install <- as_source[!vapply(as_source, is_current, logical(1))]
invisible(callr::r(function(binary, source, lib, repo, type) {
  if (length(binary)) {
    utils::install.packages(binary, lib = lib, repos = repo, type = type, dependencies = FALSE, quiet = TRUE)
  }
  if (length(source)) {
    utils::install.packages(source, lib = lib, repos = repo, type = "source", dependencies = FALSE, quiet = TRUE)
  }
  invisible()
}, args = list(binary = binary_to_install, source = source_to_install, lib = lib_dir, repo = snapshot_repo,
               type = binary_type), libpath = lib_dir, show = TRUE))
missing_after <- setdiff(needed, rownames(utils::installed.packages(lib.loc = lib_dir)))
if (length(missing_after)) stop("Failed to install: ", paste(missing_after, collapse = ", "), call. = FALSE)

# 4. Build pprofR from its sources against the pinned headers --------------------------------------
install_log <- callr::rcmd("INSTALL", c("--preclean", "--no-multiarch", paste0("--library=", lib_dir), source_dir),
                           libpath = lib_dir, show = FALSE, fail_on_status = FALSE)
if (install_log$status != 0) {
  cat(install_log$stdout, install_log$stderr, sep = "\n")
  stop("Installing pprofR failed.", call. = FALSE)
}

# 5. Verify isolation, run pprofR's own tests, and record the library ------------------------------
record <- callr::r(function(lib, needed) {
  suppressPackageStartupMessages(library(pprofR))
  ip <- utils::installed.packages(lib.loc = lib, fields = c("Repository", "Built"))
  resolved <- vapply(c("pprofR", needed), function(p) dirname(find.package(p)), character(1))
  list(
    lib_paths = .libPaths(),
    pprofr_version = as.character(utils::packageVersion("pprofR")),
    outside = resolved[!startsWith(normalizePath(resolved, winslash = "/"), normalizePath(lib, winslash = "/"))],
    packages = data.frame(package = ip[, "Package"], version = ip[, "Version"], built = ip[, "Built"],
                          row.names = NULL, stringsAsFactors = FALSE),
    r_version = R.version.string, platform = R.version$platform,
    la_version = La_version(), la_library = La_library(), blas = sessionInfo()$BLAS,
    long_double = .Machine$sizeof.longdouble,
    compiler = system2(file.path(R.home("bin"), "R"), c("CMD", "config", "CXX17"), stdout = TRUE)
  )
}, args = list(lib = lib_dir, needed = needed), libpath = lib_dir)
if (!identical(record$pprofr_version, pprofr_version)) {
  stop("pprofR in the library is not ", pprofr_version, ".", call. = FALSE)
}
if (length(record$outside)) {
  stop("Resolved outside the pprofR library: ", paste(names(record$outside), collapse = ", "), call. = FALSE)
}

# pprofR's tests, with testthat from the user library after the pprofR library, so that pprofR and its
# dependencies still resolve to the pinned library.
tests <- callr::r(function(lib, tests_dir, needed) {
  resolved <- vapply(c("pprofR", needed), function(p) dirname(find.package(p)), character(1))
  outside <- resolved[!startsWith(normalizePath(resolved, winslash = "/"), normalizePath(lib, winslash = "/"))]
  results <- as.data.frame(testthat::test_dir(tests_dir, package = "pprofR", load_package = "installed",
                                              reporter = "silent", stop_on_failure = FALSE))
  list(outside = names(outside), blocks = nrow(results), expectations = sum(results$nb),
       failed = sum(results$failed), skipped = sum(results$skipped), warnings = sum(results$warning),
       errors = sum(results$error), testthat = as.character(utils::packageVersion("testthat")))
}, args = list(lib = lib_dir, tests_dir = file.path(source_dir, "tests", "testthat"), needed = needed),
libpath = c(lib_dir, .libPaths()))
if (length(tests$outside)) stop("pprofR's tests resolved outside the library: ", paste(tests$outside, collapse = ", "),
                                call. = FALSE)
if (tests$failed > 0 || tests$errors > 0) stop("pprofR's own tests failed in the library.", call. = FALSE)

record$packages$source <- ifelse(record$packages$package == "pprofR",
                                 "git archive of commit f23c288 (built from source)",
                                 ifelse(record$packages$package %in% as_binary, "snapshot binary", "snapshot source"))
lock <- list(
  purpose = paste("Isolated library holding pprofR 0.2.0, the reference of the logistic extensions phase's new",
                  "features, for fixture generation (DEC-152, DEC-156)."),
  created = format(Sys.time(), tz = "UTC", usetz = TRUE),
  snapshot = snapshot_repo,
  pprofr = list(version = pprofr_version, git_commit = pprofr_commit, source = "git archive, built from source"),
  reference_lock = "dev/reference/library-lock.json: the dependencies' versions equal its",
  r_version = record$r_version, platform = record$platform, compiler = record$compiler, blas = record$blas,
  lapack = record$la_library, lapack_version = record$la_version, long_double_bytes = record$long_double,
  pprofr_tests = tests[c("blocks", "expectations", "failed", "skipped", "warnings", "errors", "testthat")],
  packages = record$packages[order(record$packages$package), ]
)
jsonlite::write_json(lock, lock_file, auto_unbox = TRUE, pretty = TRUE, dataframe = "rows")
unlink(source_dir, recursive = TRUE)
cat(sprintf("pprofR library ready: %d packages; pprofR's tests: %d blocks, %d expectations, %d failed; lock: %s\n",
            nrow(record$packages), tests$blocks, tests$expectations, tests$failed, lock_file))
