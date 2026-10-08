# Records the snapshot of the data layer's output on the reference cases (COXPH_DESIGN §C.2; the
# CoxPH C2 plan, §4.1): for every case of the core and full reference sets, the signature of each
# `pprof_data` object it builds (tests/testthat/helper-data-snapshot.R). The snapshot was recorded
# once, at commit 7b0cb5e, before the CoxPH phase changed the data layer, and
# tests/testthat/test-data-prepare-snapshot.R compares the code with it. Recording it again from
# changed code would defeat that test: do so only to extend it to new reference cases, from code
# whose data layer is unchanged for the existing ones, and say so in the commit.
#
# Usage, from the repository root:
#   Rscript dev/tools/data_prepare_snapshot.R [output]
# Default output: validation/fixtures/data-prepare-snapshot.rds.
args <- commandArgs(trailingOnly = TRUE)
out <- if (length(args)) args[[1]] else file.path("validation", "fixtures", "data-prepare-snapshot.rds")
fixture_dir <- function(path) normalizePath(path, winslash = "/", mustWork = TRUE)
Sys.setenv(PPROF_REFERENCE_CORE = fixture_dir(file.path("tests", "testthat", "fixtures", "reference")),
           PPROF_REFERENCE_FULL = fixture_dir(file.path("validation", "fixtures", "reference")))
suppressMessages(devtools::load_all(quiet = TRUE))
for (f in c("helper-reference-cases.R", "helper-fixtures.R", "helper-data-snapshot.R")) {
  source(file.path("tests", "testthat", f))
}
sets <- list()
for (set in c("core", "full")) {
  ids <- reference_case_ids(set = set)
  started <- Sys.time()
  sets[[set]] <- data_snapshot_record(ids, set)
  cat(sprintf("%s: %d cases, %d distinct pprof_data objects, %.0f s\n", set, length(ids),
              length(sets[[set]]$signatures), as.numeric(difftime(Sys.time(), started, units = "secs"))))
}
commit <- system2("git", c("rev-parse", "--short", "HEAD"), stdout = TRUE)
dirty <- length(system2("git", c("status", "--porcelain", "--", "R", "src"), stdout = TRUE)) > 0L
snapshot <- list(format_version = 1L, commit = commit, package_code_clean = !dirty, r_version = R.version.string,
                 platform = R.version$platform, sets = sets)
saveRDS(snapshot, out, version = 3)
cat("wrote", out, "\n")
