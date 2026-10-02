# Install the reference implementation (pprof 1.0.3 from CRAN) into its own library.
# Usage: Rscript dev/design/audit/install_reference.R <library-dir>

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1) stop("Usage: Rscript install_reference.R <library-dir>", call. = FALSE)
lib_dir <- normalizePath(args[[1]], winslash = "/", mustWork = FALSE)
dir.create(lib_dir, recursive = TRUE, showWarnings = FALSE)

expected_md5 <- "6fa1344f4a265811059d27a105d06d6b" # CRAN PACKAGES index, pprof 1.0.3
tarball <- file.path(tempdir(), "pprof_1.0.3.tar.gz")
urls <- c(
  "https://cloud.r-project.org/src/contrib/pprof_1.0.3.tar.gz",
  "https://cloud.r-project.org/src/contrib/Archive/pprof/pprof_1.0.3.tar.gz"
)
ok <- FALSE
for (url in urls) {
  ok <- tryCatch({
    utils::download.file(url, tarball, mode = "wb", quiet = TRUE)
    TRUE
  }, error = function(e) FALSE, warning = function(w) FALSE)
  if (ok) break
}
if (!ok) stop("Could not download pprof 1.0.3 from CRAN.", call. = FALSE)

actual_md5 <- unname(tools::md5sum(tarball))
if (!identical(actual_md5, expected_md5)) {
  stop(sprintf("MD5 mismatch: expected %s, got %s", expected_md5, actual_md5), call. = FALSE)
}

utils::install.packages(tarball, lib = lib_dir, repos = NULL, type = "source")
installed <- utils::packageDescription("pprof", lib.loc = lib_dir)
cat(sprintf("Installed pprof %s into %s (MD5 %s)\n", installed$Version, lib_dir, actual_md5))
