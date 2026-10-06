# Build the isolated, pinned library that holds the reference implementation.
#
# Usage, from the repository root:
#   Rscript dev/reference/setup_reference_library.R [library-dir]
#
# The library (default dev/reference/lib, gitignored) contains:
#   - pprof 1.0.3 built from the CRAN tarball, checked against its CRAN MD5 (DEC-002);
#   - every recursive hard dependency of pprof (Depends, Imports, LinkingTo), including
#     recommended packages such as Matrix, installed from a dated CRAN snapshot (DEC-017).
# Nothing is taken from the user library: installation and verification run in child
# R sessions whose library path is only this library plus base R.
#
# It writes dev/reference/library-lock.json, the committed record of the library.

snapshot_date <- "2026-10-01"
snapshot_repo <- paste0("https://packagemanager.posit.co/cran/", snapshot_date)
# PPROF_REFERENCE_SNAPSHOT_REPO can name the same snapshot at another address of Posit Package
# Manager, such as its Linux binaries (".../cran/__linux__/noble/2026-10-01"), which CI uses to
# build the library without compiling every package (DEC-080). The versions are the same.
if (nzchar(Sys.getenv("PPROF_REFERENCE_SNAPSHOT_REPO"))) {
  snapshot_repo <- Sys.getenv("PPROF_REFERENCE_SNAPSHOT_REPO")
  if (!grepl(paste0("/", snapshot_date, "$"), snapshot_repo)) {
    stop("PPROF_REFERENCE_SNAPSHOT_REPO must be the ", snapshot_date, " snapshot.", call. = FALSE)
  }
}
pprof_tarball_urls <- c(
  "https://cloud.r-project.org/src/contrib/pprof_1.0.3.tar.gz",
  "https://cloud.r-project.org/src/contrib/Archive/pprof/pprof_1.0.3.tar.gz"
)
pprof_md5 <- "6fa1344f4a265811059d27a105d06d6b"

args <- commandArgs(trailingOnly = TRUE)
lib_dir <- if (length(args) >= 1) args[[1]] else file.path("dev", "reference", "lib")
dir.create(lib_dir, recursive = TRUE, showWarnings = FALSE)
lib_dir <- normalizePath(lib_dir, winslash = "/")
lock_file <- file.path("dev", "reference", "library-lock.json")
stopifnot(requireNamespace("callr", quietly = TRUE), requireNamespace("jsonlite", quietly = TRUE))

# 1. Download and verify the reference tarball -------------------------------------------
tarball <- file.path(tempdir(), "pprof_1.0.3.tar.gz")
downloaded <- FALSE
for (url in pprof_tarball_urls) {
  downloaded <- tryCatch({
    utils::download.file(url, tarball, mode = "wb", quiet = TRUE)
    TRUE
  }, error = function(e) FALSE, warning = function(w) FALSE)
  if (downloaded) break
}
if (!downloaded) stop("Could not download pprof 1.0.3 from CRAN.", call. = FALSE)
if (!identical(unname(tools::md5sum(tarball)), pprof_md5)) {
  stop("MD5 of the pprof 1.0.3 tarball does not match the CRAN index.", call. = FALSE)
}

# 2. Resolve the dependency closure in the snapshot ----------------------------------------
desc_dir <- file.path(tempdir(), "pprof-desc")
utils::untar(tarball, files = "pprof/DESCRIPTION", exdir = desc_dir)
desc <- read.dcf(file.path(desc_dir, "pprof", "DESCRIPTION"))
direct <- unlist(lapply(c("Depends", "Imports", "LinkingTo"), function(field) {
  if (!field %in% colnames(desc)) return(character())
  deps <- trimws(strsplit(desc[1, field], ",")[[1]])
  sub("[ (].*$", "", deps)
}))
base_pkgs <- rownames(utils::installed.packages(priority = "base"))
direct <- setdiff(direct, c("R", base_pkgs))

# Dependencies are resolved in the snapshot's source index. Posit Package Manager serves only
# packages whose R requirement this R version meets, so a package can be missing from the
# snapshot even though CRAN has it (for example Deriv, whose current CRAN version needs
# R >= 4.5). Such packages are installed from the CRAN Archive: the newest archived version
# whose R requirement this R satisfies. The lock file records them as archive installs.
src_db <- utils::available.packages(repos = snapshot_repo, type = "source")
# Binaries where the snapshot has them: Windows, and macOS (whose binary type names its
# build, for example mac.binary.big-sur-arm64); elsewhere packages are built from source.
binary_type <- if (.Platform$OS.type == "windows") {
  "win.binary"
} else if (startsWith(.Platform$pkgType, "mac.binary")) {
  .Platform$pkgType
} else {
  "source"
}
bin_db <- utils::available.packages(repos = snapshot_repo, type = binary_type)
closure <- tools::package_dependencies(direct, db = src_db, which = c("Depends", "Imports", "LinkingTo"),
                                       recursive = TRUE)
needed <- sort(unique(setdiff(c(direct, unlist(closure)), base_pkgs)))
from_archive <- setdiff(needed, rownames(src_db))
from_snapshot <- setdiff(needed, from_archive)
in_bin <- from_snapshot[from_snapshot %in% rownames(bin_db)]
as_binary <- in_bin[bin_db[in_bin, "Version"] == src_db[in_bin, "Version"]]
as_source <- setdiff(from_snapshot, as_binary)

r_requirement_met <- function(depends) {
  if (is.na(depends) || !grepl("R \\(", depends)) return(TRUE)
  req <- regmatches(depends, regexpr("R \\([^)]*\\)", depends))
  op <- sub("R \\(\\s*([<>=]+).*", "\\1", req)
  ver <- sub("R \\(\\s*[<>=]+\\s*([0-9.]+).*", "\\1", req)
  switch(op, ">=" = getRversion() >= ver, ">" = getRversion() > ver,
         "<=" = getRversion() <= ver, "<" = getRversion() < ver, "==" = getRversion() == ver, TRUE)
}

# Candidate archived versions, newest first, that declare an R requirement this R meets. A
# declared requirement can be incomplete (Deriv 4.3.0 uses Rf_allocLang, which R 4.4.0 lacks,
# without saying so), so installation falls back to the next older candidate on failure.
archive_candidates <- list()
for (pkg in from_archive) {
  listing <- readLines(sprintf("https://cloud.r-project.org/src/contrib/Archive/%s/", pkg), warn = FALSE)
  files <- unique(regmatches(listing, regexpr(sprintf("%s_[0-9][0-9.-]*\\.tar\\.gz", pkg), listing)))
  versions <- sub(sprintf("^%s_(.*)\\.tar\\.gz$", pkg), "\\1", files)
  files <- files[order(package_version(versions), decreasing = TRUE)]
  candidates <- character()
  for (f in files) {
    dest <- file.path(tempdir(), f)
    utils::download.file(sprintf("https://cloud.r-project.org/src/contrib/Archive/%s/%s", pkg, f),
                         dest, mode = "wb", quiet = TRUE)
    dcf_dir <- file.path(tempdir(), paste0(pkg, "-desc"))
    unlink(dcf_dir, recursive = TRUE)
    utils::untar(dest, files = paste0(pkg, "/DESCRIPTION"), exdir = dcf_dir)
    d <- read.dcf(file.path(dcf_dir, pkg, "DESCRIPTION"), fields = "Depends")
    if (r_requirement_met(d[1, "Depends"])) candidates <- c(candidates, dest)
    if (length(candidates) >= 3) break
  }
  if (!length(candidates)) stop("No archived version of ", pkg, " supports this R version.", call. = FALSE)
  archive_candidates[[pkg]] <- candidates
}

cat(sprintf("Installing %d packages into %s: %d binary and %d source from %s, %d from the CRAN Archive (%s)\n",
            length(needed), lib_dir, length(as_binary), length(as_source), snapshot_repo,
            length(from_archive), paste(names(archive_candidates), collapse = ", ")))

# 3. Install the dependencies in an isolated child session ----------------------------------
# Skip packages already present at the pinned version, so that rerunning the script is cheap.
present <- utils::installed.packages(lib.loc = lib_dir)
is_current <- function(pkg) {
  pkg %in% rownames(present) && identical(unname(present[pkg, "Version"]), unname(src_db[pkg, "Version"]))
}
binary_to_install <- as_binary[!vapply(as_binary, is_current, logical(1))]
source_to_install <- as_source[!vapply(as_source, is_current, logical(1))]

archive_used <- callr::r(function(binary, source, archive, lib, repo, type) {
  options(repos = c(CRAN = repo))
  if (length(binary)) {
    utils::install.packages(binary, lib = lib, repos = repo, type = type, dependencies = FALSE, quiet = TRUE)
  }
  if (length(source)) {
    utils::install.packages(source, lib = lib, repos = repo, type = "source", dependencies = FALSE, quiet = TRUE)
  }
  used <- character()
  for (pkg in names(archive)) {
    for (tb in archive[[pkg]]) {
      suppressWarnings(utils::install.packages(tb, lib = lib, repos = NULL, type = "source", quiet = TRUE))
      if (pkg %in% rownames(utils::installed.packages(lib.loc = lib))) {
        used[pkg] <- basename(tb)
        break
      }
    }
  }
  used
}, args = list(binary = binary_to_install, source = source_to_install, archive = archive_candidates,
               lib = lib_dir, repo = snapshot_repo, type = binary_type),
libpath = lib_dir, show = TRUE)
missing_after <- setdiff(needed, rownames(utils::installed.packages(lib.loc = lib_dir)))
if (length(missing_after)) stop("Failed to install: ", paste(missing_after, collapse = ", "), call. = FALSE)
archive_tarballs <- archive_used
cat("Installed from the CRAN Archive:", paste(archive_tarballs, collapse = ", "), "\n")

# 4. Build pprof 1.0.3 from source against the pinned headers -------------------------------
install_log <- callr::rcmd("INSTALL", c(paste0("--library=", lib_dir), tarball),
                           libpath = lib_dir, show = FALSE, fail_on_status = FALSE)
if (install_log$status != 0) {
  cat(install_log$stdout, install_log$stderr, sep = "\n")
  stop("Installing pprof 1.0.3 failed.", call. = FALSE)
}

# 5. Verify isolation and record the library ------------------------------------------------
record <- callr::r(function(lib, needed) {
  suppressPackageStartupMessages(library(pprof))
  ip <- utils::installed.packages(lib.loc = lib, fields = c("Repository", "Built", "Packaged"))
  resolved <- vapply(c("pprof", needed), function(p) dirname(find.package(p)), character(1))
  list(
    lib_paths = .libPaths(),
    pprof_path = find.package("pprof"),
    pprof_version = as.character(utils::packageVersion("pprof")),
    outside = resolved[!startsWith(normalizePath(resolved, winslash = "/"), normalizePath(lib, winslash = "/"))],
    packages = data.frame(package = ip[, "Package"], version = ip[, "Version"],
                          built = ip[, "Built"], repository = ip[, "Repository"],
                          row.names = NULL, stringsAsFactors = FALSE),
    r_version = R.version.string, platform = R.version$platform,
    la_version = La_version(), la_library = La_library(), blas = sessionInfo()$BLAS,
    compiler = system2(file.path(R.home("bin"), "R"), c("CMD", "config", "CXX17"), stdout = TRUE)
  )
}, args = list(lib = lib_dir, needed = needed), libpath = lib_dir)

if (!identical(record$pprof_version, "1.0.3")) stop("pprof in the library is not 1.0.3.", call. = FALSE)
if (length(record$outside)) {
  stop("Resolved outside the reference library: ", paste(names(record$outside), collapse = ", "), call. = FALSE)
}

record$packages$source <- ifelse(record$packages$package == "pprof", "CRAN tarball (built from source)",
                          ifelse(record$packages$package %in% names(archive_tarballs), "CRAN Archive (built from source)",
                          ifelse(record$packages$package %in% as_binary, "snapshot binary", "snapshot source")))
lock <- list(
  purpose = "Isolated library holding the pprof reference implementation for fixture generation (DEC-002, DEC-017).",
  created = format(Sys.time(), tz = "UTC", usetz = TRUE),
  snapshot = snapshot_repo,
  archive_installs = as.list(basename(archive_tarballs)),
  pprof = list(version = "1.0.3", source = "CRAN tarball", md5 = pprof_md5, git_commit = "5260838"),
  r_version = record$r_version, platform = record$platform,
  compiler = record$compiler, blas = record$blas, lapack = record$la_library, lapack_version = record$la_version,
  packages = record$packages[order(record$packages$package), ]
)
jsonlite::write_json(lock, lock_file, auto_unbox = TRUE, pretty = TRUE, dataframe = "rows")
cat(sprintf("Reference library ready: %d packages; lock written to %s\n", nrow(record$packages), lock_file))
