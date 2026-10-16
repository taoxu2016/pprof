# Which of the package's executable code a change touched: installs pprof from an old commit and from
# the working tree into two scratch libraries, dumps each installed namespace in its own R process
# (every function deparsed, so comments and roxygen text do not count; the exports; the registered S3
# methods; the bundled data sets, loaded), and compares the two dumps; the C++ sources are compared with
# git. The rewrite's Phase 7 guard (DEC-061; `git show 5977087:dev/design/phase7-facts/07_code_unchanged.R`),
# made reusable for the CoxPH C6 plan (§4.1, §4.3).
# Run from the repository root:
#   Rscript dev/tools/namespace_compare.R <output file> <scratch directory> <old commit> [<expected changes>]
# <expected changes>: the names of the functions the change may change or add, comma-separated. The
# output lists every changed, added, or removed function and says whether any lies outside them. The old
# commit's library is kept in the scratch directory and reused while that commit's is there.
args <- commandArgs(trailingOnly = TRUE)
out_file <- args[[1]]
scratch <- normalizePath(args[[2]], winslash = "/", mustWork = FALSE)
old_ref <- args[[3]]
expected <- if (length(args) > 3 && nzchar(args[[4]])) strsplit(args[[4]], ",", fixed = TRUE)[[1]] else character()
dir.create(scratch, showWarnings = FALSE, recursive = TRUE)
rscript <- file.path(R.home("bin"), "Rscript")
r_cmd <- file.path(R.home("bin"), "R")
run <- function(command, arguments, log) {
  status <- system2(command, arguments, stdout = log, stderr = log)
  if (!identical(status, 0L)) stop(sprintf("`%s %s` failed; see %s", command, paste(arguments, collapse = " "), log))
}
old_sha <- system2("git", c("rev-parse", "--short", old_ref), stdout = TRUE)

# Build and install a source tree, without vignettes, into its own library.
install <- function(source, name) {
  force(source)
  build_dir <- file.path(scratch, paste0("build-", name))
  lib <- file.path(scratch, paste0("lib-", name))
  unlink(c(build_dir, lib), recursive = TRUE)
  dir.create(build_dir)
  dir.create(lib)
  log <- file.path(scratch, paste0(name, ".log"))
  owd <- setwd(build_dir)
  on.exit(setwd(owd))
  run(r_cmd, c("CMD", "build", "--no-build-vignettes", "--no-manual", shQuote(source)), log)
  tarball <- list.files(build_dir, pattern = "[.]tar[.]gz$", full.names = TRUE)
  run(r_cmd, c("CMD", "INSTALL", "--preclean", paste0("--library=", shQuote(lib)), shQuote(tarball)), log)
  lib
}
old_lib <- file.path(scratch, paste0("lib-old-", old_sha))
if (!dir.exists(file.path(old_lib, "pprof"))) {
  old_source <- file.path(scratch, paste0("old-source-", old_sha))
  unlink(old_source, recursive = TRUE)
  dir.create(old_source)
  archive <- file.path(scratch, "old.tar")
  run("git", c("archive", "--format=tar", "-o", shQuote(archive), old_ref), file.path(scratch, "archive.log"))
  utils::untar(archive, exdir = old_source)
  old_lib <- install(old_source, paste0("old-", old_sha))
}
libs <- c(old = old_lib, new = install(normalizePath("."), "new"))

dump_script <- file.path(scratch, "dump.R")
writeLines(c(
  "args <- commandArgs(trailingOnly = TRUE)",
  "suppressPackageStartupMessages(library(pprof, lib.loc = args[1]))",
  "ns <- asNamespace('pprof')",
  "names <- sort(ls(ns, all.names = TRUE))",
  "functions <- Filter(Negate(is.null), lapply(stats::setNames(names, names), function(n) {",
  "  f <- get(n, envir = ns)",
  "  if (is.function(f)) paste(deparse(f), collapse = '\\n') else NULL",
  "}))",
  "datasets <- utils::data(package = 'pprof', lib.loc = args[1])$results[, 'Item']",
  "data_values <- lapply(stats::setNames(datasets, datasets), function(d) {",
  "  e <- new.env()",
  "  utils::data(list = d, package = 'pprof', lib.loc = args[1], envir = e)",
  "  get(d, envir = e)",
  "})",
  "saveRDS(list(functions = functions, exports = sort(getNamespaceExports(ns)),",
  "             s3 = sort(ls(get('.__S3MethodsTable__.', envir = ns))), data = data_values), args[2])"
), dump_script)
dumps <- lapply(names(libs), function(name) {
  file <- file.path(scratch, paste0("dump-", name, ".rds"))
  run(rscript, c(shQuote(dump_script), shQuote(libs[[name]]), shQuote(file)), file.path(scratch, "dump.log"))
  readRDS(file)
})
names(dumps) <- names(libs)
old <- dumps$old
new <- dumps$new

common <- intersect(names(old$functions), names(new$functions))
changed <- common[!vapply(common, function(n) identical(old$functions[[n]], new$functions[[n]]), logical(1))]
added <- setdiff(names(new$functions), names(old$functions))
removed <- setdiff(names(old$functions), names(new$functions))
unexpected <- setdiff(c(changed, added, removed), expected)
cpp <- system2("git", c("diff", "--stat", old_ref, "--", "src"), stdout = TRUE)
list_or_none <- function(x) if (length(x)) paste(x, collapse = ", ") else "none"
writeLines(c(
  sprintf("Old: %s; new: the working tree at %s (%s). Functions compared: %d.", old_sha,
          system2("git", c("rev-parse", "--short", "HEAD"), stdout = TRUE),
          if (length(system2("git", c("status", "--porcelain", "--", "R", "src", "data", "DESCRIPTION", "NAMESPACE"),
                             stdout = TRUE))) "with uncommitted changes to the package" else "no uncommitted changes to the package",
          length(common)),
  sprintf("Functions changed: %s", list_or_none(changed)),
  sprintf("Functions added: %s", list_or_none(added)),
  sprintf("Functions removed: %s", list_or_none(removed)),
  sprintf("Expected changes: %s", list_or_none(expected)),
  sprintf("Changes outside the expected: %s", list_or_none(unexpected)),
  sprintf("Exports identical: %s", identical(old$exports, new$exports)),
  sprintf("Registered S3 methods identical: %s%s", identical(old$s3, new$s3),
          if (identical(old$s3, new$s3)) "" else sprintf(" (added: %s; removed: %s)", list_or_none(setdiff(new$s3, old$s3)),
                                                         list_or_none(setdiff(old$s3, new$s3)))),
  sprintf("Data sets identical: %s (%s)", identical(old$data, new$data), paste(names(new$data), collapse = ", ")),
  sprintf("C++ sources changed since %s: %s", old_sha, if (length(cpp)) paste(cpp, collapse = " ") else "none")
), out_file)
