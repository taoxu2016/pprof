# D-53 with lme4 itself (follows 15): the lme4-backed reference cases depend on the L1 cache size
# Eigen uses, and fixing that size makes them independent of the processor (CoxPH Phase C1).
# lme4, at the fixtures' version, is built from source twice into scratch libraries with Eigen's
# cache query compiled out (EIGEN_NO_CPUID) and its default cache sizes set:
#   - "zen3": L1 32 KB, L2 512 KB, L3 32 MB, what Eigen reads on the AMD Zen 3 runners (Family 25
#     Model 1) on which CI's fixture-platform job fails;
#   - "fixture_machine": L1 48 KB, L2 1.25 MB, L3 8 MB, what Eigen reads on this machine (script
#     15's output), where the fixtures were made with CRAN's lme4 binary.
# The reference suite (validation/run-reference.R) then runs against each build, the scratch
# library first on the library path.
# Run from the repository root, with Rtools on the PATH (it compiles lme4):
#   Rscript dev/design/coxph-facts/16_lme4_cache_sizes.R <output file>
# The builds, their logs, and the reports go to $COXPH_FACTS_SCRATCH/lme4-cache-sizes.
args <- commandArgs(trailingOnly = TRUE)
out_file <- args[[1]]
scratch <- file.path(Sys.getenv("COXPH_FACTS_SCRATCH", tempdir()), "lme4-cache-sizes")
dir.create(scratch, showWarnings = FALSE, recursive = TRUE)
r_bin <- function(program) file.path(R.home("bin"), program)
# The child processes inherit these variables: on Windows, system2()'s env argument reaches only
# programs that read NAME=value arguments, which Rscript does not.
with_env <- function(vars, code) {
  old <- Sys.getenv(names(vars), unset = NA, names = TRUE)
  do.call(Sys.setenv, as.list(vars))
  on.exit(for (v in names(old)) {
    if (is.na(old[[v]])) Sys.unsetenv(v) else do.call(Sys.setenv, as.list(old[v]))
  })
  force(code)
}

manifest <- jsonlite::read_json("tests/testthat/fixtures/reference/manifest.json")
lme4_version <- manifest$numerically_relevant_packages$lme4
tarball <- file.path(scratch, sprintf("lme4_%s.tar.gz", lme4_version))
snapshot <- "https://packagemanager.posit.co/cran/2026-10-01/src/contrib/"
utils::download.file(paste0(snapshot, basename(tarball)), tarball, mode = "wb", quiet = TRUE)

builds <- list(
  zen3 = c(l1 = 32 * 1024, l2 = 512 * 1024, l3 = 32 * 1024^2),
  fixture_machine = c(l1 = 48 * 1024, l2 = 1280 * 1024, l3 = 8 * 1024^2)
)
lines <- c(sprintf("%s; lme4 %s from the CRAN snapshot of 2026-10-01; processor here: %s", R.version.string,
                   lme4_version, Sys.getenv("PROCESSOR_IDENTIFIER", "unknown")), "")
for (name in names(builds)) {
  sizes <- builds[[name]]
  lib <- file.path(scratch, name)
  dir.create(lib, showWarnings = FALSE)
  log <- function(step) file.path(scratch, sprintf("%s-%s.log", name, step))
  makevars <- file.path(scratch, paste0(name, ".mk"))
  flags <- sprintf(paste("-DEIGEN_NO_CPUID -DEIGEN_DEFAULT_L1_CACHE_SIZE=%d -DEIGEN_DEFAULT_L2_CACHE_SIZE=%d",
                         "-DEIGEN_DEFAULT_L3_CACHE_SIZE=%d"), sizes[["l1"]], sizes[["l2"]], sizes[["l3"]])
  writeLines(paste("CPPFLAGS +=", flags), makevars)
  status <- with_env(c(R_MAKEVARS_USER = makevars), system2(
    r_bin("R"), c("CMD", "INSTALL", "--preclean", paste0("--library=", lib), tarball),
    stdout = log("install"), stderr = log("install")))
  if (status != 0) stop("Building lme4 (", name, ") failed; see ", log("install"), call. = FALSE)
  if (!any(grepl("EIGEN_NO_CPUID", readLines(log("install"))))) {
    stop("The flags did not reach the compiler (", name, "); see ", log("install"), call. = FALSE)
  }
  loaded <- with_env(c(R_LIBS = lib), system2(r_bin("Rscript"), c("-e", "\"cat(find.package('lme4'))\""),
                                              stdout = TRUE))
  if (!identical(normalizePath(loaded, winslash = "/"), normalizePath(file.path(lib, "lme4"), winslash = "/"))) {
    stop("The child session loads lme4 from ", loaded, ", not the scratch build (", name, ").", call. = FALSE)
  }
  report <- file.path(scratch, paste0(name, "-report.md"))
  with_env(c(R_LIBS = lib), system2(r_bin("Rscript"), c("validation/run-reference.R", report),
                                    stdout = log("run"), stderr = log("run")))
  if (!file.exists(report)) stop("The reference suite wrote no report (", name, "); see ", log("run"), call. = FALSE)
  rows <- readLines(report)
  summary <- grep("^- (Compared and matching|Largest absolute)", rows, value = TRUE)
  cases <- sub("^\\| (core|full) \\| `([^`]+)`.*", "\\2", grep("^\\| (core|full) \\| `[^`]+` \\|.*\\| FAIL", rows,
                                                             value = TRUE))
  lines <- c(lines, sprintf("%s (%s):", name, flags), sprintf("  lme4 loaded from the scratch build: %s", loaded),
             paste(" ", summary), sprintf("  failing cases (%d): %s", length(cases), paste(cases, collapse = ", ")), "")
}
writeLines(lines, out_file)
