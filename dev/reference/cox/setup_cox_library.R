# Build the isolated, pinned R library of the Cox fixture generator (dev/reference/cox/README.md).
#
# Usage, from the repository root:
#   Rscript dev/reference/cox/setup_cox_library.R [library-dir]
#
# The library (default dev/reference/cox/lib, gitignored) holds survival and glmnet, the engines
# whose outputs the Cox fixtures record next to pprof_py's, and their recursive hard dependencies
# (Depends, Imports, LinkingTo), all from the CRAN snapshot of DEC-017 (2026-10-01): survival
# 3.8-12 and glmnet 5.1. Nothing is taken from the user library: installation and verification run
# in child R sessions whose library path is only this library plus base R.
#
# It writes dev/reference/cox/cox-library-lock.json, the committed record of the library.

snapshot_date <- "2026-10-01"
snapshot_repo <- paste0("https://packagemanager.posit.co/cran/", snapshot_date)
# PPROF_REFERENCE_SNAPSHOT_REPO can name the same snapshot at another address of Posit Package
# Manager, such as its Linux binaries (".../cran/__linux__/noble/2026-10-01"), as in
# dev/reference/setup_reference_library.R. The versions are the same.
if (nzchar(Sys.getenv("PPROF_REFERENCE_SNAPSHOT_REPO"))) {
  snapshot_repo <- Sys.getenv("PPROF_REFERENCE_SNAPSHOT_REPO")
  if (!grepl(paste0("/", snapshot_date, "$"), snapshot_repo)) {
    stop("PPROF_REFERENCE_SNAPSHOT_REPO must be the ", snapshot_date, " snapshot.", call. = FALSE)
  }
}
engines <- c(survival = "3.8-12", glmnet = "5.1")

args <- commandArgs(trailingOnly = TRUE)
lib_dir <- if (length(args) >= 1) args[[1]] else file.path("dev", "reference", "cox", "lib")
dir.create(lib_dir, recursive = TRUE, showWarnings = FALSE)
lib_dir <- normalizePath(lib_dir, winslash = "/")
lock_file <- file.path("dev", "reference", "cox", "cox-library-lock.json")
stopifnot(requireNamespace("callr", quietly = TRUE), requireNamespace("jsonlite", quietly = TRUE))

# 1. Resolve the dependency closure in the snapshot -----------------------------------------
src_db <- utils::available.packages(repos = snapshot_repo, type = "source")
if (!all(src_db[names(engines), "Version"] == engines)) {
  stop("The snapshot does not have ", paste(names(engines), engines, collapse = ", "), ".", call. = FALSE)
}
binary_type <- if (.Platform$OS.type == "windows") {
  "win.binary"
} else if (startsWith(.Platform$pkgType, "mac.binary")) {
  .Platform$pkgType
} else {
  "source"
}
bin_db <- utils::available.packages(repos = snapshot_repo, type = binary_type)
base_pkgs <- rownames(utils::installed.packages(priority = "base"))
closure <- tools::package_dependencies(names(engines), db = src_db, which = c("Depends", "Imports", "LinkingTo"),
                                       recursive = TRUE)
needed <- sort(unique(setdiff(c(names(engines), unlist(closure)), base_pkgs)))
missing <- setdiff(needed, rownames(src_db))
if (length(missing)) stop("Not in the snapshot: ", paste(missing, collapse = ", "), call. = FALSE)
in_bin <- needed[needed %in% rownames(bin_db)]
as_binary <- in_bin[bin_db[in_bin, "Version"] == src_db[in_bin, "Version"]]
as_source <- setdiff(needed, as_binary)
cat(sprintf("Installing %d packages into %s: %d binary and %d source from %s\n",
            length(needed), lib_dir, length(as_binary), length(as_source), snapshot_repo))

# 2. Install in an isolated child session, skipping packages already at the pinned version ----
present <- utils::installed.packages(lib.loc = lib_dir)
is_current <- function(pkg) {
  pkg %in% rownames(present) && identical(unname(present[pkg, "Version"]), unname(src_db[pkg, "Version"]))
}
binary_to_install <- as_binary[!vapply(as_binary, is_current, logical(1))]
source_to_install <- as_source[!vapply(as_source, is_current, logical(1))]
callr::r(function(binary, source, lib, repo, type) {
  options(repos = c(CRAN = repo))
  if (length(binary)) {
    utils::install.packages(binary, lib = lib, repos = repo, type = type, dependencies = FALSE, quiet = TRUE)
  }
  if (length(source)) {
    utils::install.packages(source, lib = lib, repos = repo, type = "source", dependencies = FALSE, quiet = TRUE)
  }
  invisible(NULL)
}, args = list(binary = binary_to_install, source = source_to_install, lib = lib_dir, repo = snapshot_repo,
               type = binary_type), libpath = lib_dir, show = TRUE)
missing_after <- setdiff(needed, rownames(utils::installed.packages(lib.loc = lib_dir)))
if (length(missing_after)) stop("Failed to install: ", paste(missing_after, collapse = ", "), call. = FALSE)

# 3. Verify isolation and record the library ------------------------------------------------
record <- callr::r(function(lib, needed, engines) {
  for (p in names(engines)) suppressPackageStartupMessages(library(p, character.only = TRUE))
  ip <- utils::installed.packages(lib.loc = lib, fields = c("Repository", "Built"))
  resolved <- vapply(needed, function(p) dirname(find.package(p)), character(1))
  list(
    engines = vapply(names(engines), function(p) as.character(utils::packageVersion(p)), character(1)),
    outside = resolved[!startsWith(normalizePath(resolved, winslash = "/"), normalizePath(lib, winslash = "/"))],
    packages = data.frame(package = ip[, "Package"], version = ip[, "Version"], built = ip[, "Built"],
                          repository = ip[, "Repository"], row.names = NULL, stringsAsFactors = FALSE),
    r_version = R.version.string, platform = R.version$platform,
    la_version = La_version(), la_library = La_library(), blas = sessionInfo()$BLAS,
    compiler = system2(file.path(R.home("bin"), "R"), c("CMD", "config", "CXX17"), stdout = TRUE)
  )
}, args = list(lib = lib_dir, needed = needed, engines = engines), libpath = lib_dir)

if (!all(package_version(unname(record$engines)) == package_version(unname(engines)))) {
  stop("The library's engines are ", paste(names(record$engines), record$engines, collapse = ", "), ".", call. = FALSE)
}
if (length(record$outside)) {
  stop("Resolved outside the Cox library: ", paste(names(record$outside), collapse = ", "), call. = FALSE)
}
record$packages$source <- ifelse(record$packages$package %in% as_binary, "snapshot binary", "snapshot source")
lock <- list(
  purpose = "Isolated library of the Cox fixture generator: the engines survival and glmnet (DEC-093, DEC-017).",
  created = format(Sys.time(), tz = "UTC", usetz = TRUE),
  snapshot = snapshot_repo,
  engines = as.list(record$engines),
  r_version = record$r_version, platform = record$platform,
  compiler = record$compiler, blas = record$blas, lapack = record$la_library, lapack_version = record$la_version,
  packages = record$packages[order(record$packages$package), ]
)
jsonlite::write_json(lock, lock_file, auto_unbox = TRUE, pretty = TRUE, dataframe = "rows")
cat(sprintf("Cox library ready: %d packages; lock written to %s\n", nrow(record$packages), lock_file))
