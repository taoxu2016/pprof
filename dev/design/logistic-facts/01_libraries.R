# Logistic extensions brief, Appendix A: the libraries the other scripts use, each in its own
# folder of the scratch directory, ahead of the site library:
#   lib-pprofr  pprofR 0.2.0 from commit f23c288, which must be in the local object store
#               (fetched read-only from the upstream repository);
#   lib-pprof   pprof from the commit this script runs at (the package files of HEAD);
#   lib-ref     the independent references not installed here: sandwich, from CRAN.
# Both packages are built from git archives with R CMD INSTALL (release flags, not load_all()'s
# -O0), against the site library's Rcpp, RcppArmadillo, and poibin, whose versions equal those of
# the pinned pprof 1.0.3 library (dev/reference/library-lock.json). Then pprofR's own tests run
# against the installed pprofR.
# Run from the repository root: Rscript dev/design/logistic-facts/01_libraries.R <output file>
source("dev/design/logistic-facts/facts_data.R")
args <- commandArgs(trailingOnly = TRUE)
scratch <- facts_scratch()
pprofr_commit <- "f23c2889b59108f9506da3f91327c3f239945a63"
head_commit <- system2("git", c("rev-parse", "HEAD"), stdout = TRUE)
r_cmd <- file.path(R.home("bin"), "R")
out <- c("# 01: libraries", "", sprintf("Run %s, %s, %s.", format(Sys.time(), "%Y-%m-%d %H:%M"), R.version.string,
                                         utils::sessionInfo()$running), "")

archive <- function(commit, paths, folder) {
  tar <- file.path(scratch, paste0(folder, ".tar"))
  status <- system2("git", c("archive", "--format=tar", "-o", shQuote(tar), commit, paths))
  if (status != 0L) stop("git archive failed for ", commit)
  target <- file.path(scratch, folder)
  unlink(target, recursive = TRUE)
  dir.create(target)
  utils::untar(tar, exdir = target, tar = "internal")
  unlink(tar)
  target
}
install <- function(source, library) {
  unlink(library, recursive = TRUE)
  dir.create(library)
  log <- file.path(scratch, paste0(basename(library), "-install.log"))
  status <- system2(r_cmd, c("CMD", "INSTALL", "--preclean", "--no-multiarch", "-l", shQuote(library), shQuote(source)),
                    stdout = log, stderr = log)
  c(status = status, log = log)
}

source_pprofr <- archive(pprofr_commit, character(), "src-pprofr")
installed_pprofr <- install(source_pprofr, file.path(scratch, "lib-pprofr"))
source_pprof <- archive("HEAD", c("DESCRIPTION", "NAMESPACE", "LICENSE", "R", "src", "man", "data"), "src-pprof")
installed_pprof <- install(source_pprof, file.path(scratch, "lib-pprof"))
lib_ref <- file.path(scratch, "lib-ref")
unlink(lib_ref, recursive = TRUE)
dir.create(lib_ref)
utils::install.packages("sandwich", lib = lib_ref, repos = "https://cloud.r-project.org", quiet = TRUE)

out <- c(out, sprintf("- pprofR from %s: R CMD INSTALL exit status %s", pprofr_commit, installed_pprofr[["status"]]),
         sprintf("- pprof from %s: R CMD INSTALL exit status %s", head_commit, installed_pprof[["status"]]))
facts_use_libraries()
versions <- vapply(c("pprofR", "pprof", "sandwich", "zoo", "Rcpp", "RcppArmadillo", "poibin", "testthat"), function(p) {
  as.character(utils::packageVersion(p))
}, character(1))
where <- vapply(names(versions), function(p) {
  path <- dirname(system.file(package = p))
  if (startsWith(path, scratch)) sub(scratch, "<scratch>", path, fixed = TRUE) else "the site library"
}, character(1))
out <- c(out, sprintf("- %s %s (%s)", names(versions), versions, where))
blas <- extSoftVersion()[["BLAS"]]
out <- c(out, sprintf("- BLAS %s; LAPACK %s; long double: %d bytes", if (nzchar(blas)) blas else "R's internal",
                      La_version(), .Machine$sizeof.longdouble))

# pprofR's own test suite, on the installed package.
library(testthat)
results <- as.data.frame(testthat::test_dir(file.path(source_pprofr, "tests", "testthat"), package = "pprofR",
                                            load_package = "installed", reporter = "silent", stop_on_failure = FALSE))
out <- c(out, "", "pprofR's tests (tests/testthat at f23c288), on the installed package:", "",
         sprintf("- %d test blocks, %d expectations: %d failed, %d skipped, %d warnings, %d errors",
                 nrow(results), sum(results$nb), sum(results$failed), sum(results$skipped), sum(results$warning),
                 sum(results$error)))
failing <- results[results$failed > 0 | results$error, c("file", "test")]
if (nrow(failing) > 0L) out <- c(out, sprintf("  - failed: %s, %s", failing$file, failing$test))
writeLines(out, args[1])
