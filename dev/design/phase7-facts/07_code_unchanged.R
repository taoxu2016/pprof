# Phase 7 (DEC-061, amended at the check-in): the package's executable code is unchanged by
# Phase 7, except the seven constructors of D-51's fix. Installs pprof from the commit before
# Phase 7 (7d6d696) and from the working tree into two scratch libraries, dumps each
# namespace in its own R process (every function deparsed, so comments do not count; the
# exports; the registered S3 methods; the data sets), and compares the two dumps. The C++
# sources are compared with git.
# Run from the repository root: Rscript <this file> <output file> <scratch directory> [<old commit>]
args <- commandArgs(trailingOnly = TRUE)
out_file <- args[1]
scratch <- normalizePath(args[2], winslash = "/", mustWork = FALSE)
old_ref <- if (length(args) > 2) args[3] else "7d6d696"
dir.create(scratch, showWarnings = FALSE, recursive = TRUE)
expected_changes <- c("new_pprof_data", "new_pprof_linear_fe", "new_pprof_logistic_fe", "new_pprof_logistic_firth",
                      "new_pprof_mixed", "new_pprof_model", "new_pprof_result")
rscript <- file.path(R.home("bin"), "Rscript")
r_cmd <- file.path(R.home("bin"), "R")
run <- function(command, arguments, log) {
  status <- system2(command, arguments, stdout = log, stderr = log)
  if (!identical(status, 0L)) stop(sprintf("`%s %s` failed; see %s", command, paste(arguments, collapse = " "), log))
}

# Sources: the old commit through git archive, and the working tree.
old_source <- file.path(scratch, "old-source")
unlink(old_source, recursive = TRUE)
dir.create(old_source)
archive <- file.path(scratch, "old.tar")
run("git", c("archive", "--format=tar", "-o", shQuote(archive), old_ref), file.path(scratch, "archive.log"))
utils::untar(archive, exdir = old_source)

# Build and install each, without vignettes, into its own library.
install <- function(source, name) {
  force(source)  # before setwd(), since the working tree is passed as normalizePath(".")
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
  run(r_cmd, c("CMD", "INSTALL", paste0("--library=", shQuote(lib)), shQuote(tarball)), log)
  lib
}
libs <- c(old = install(old_source, "old"), new = install(normalizePath("."), "new"))

# Dump each namespace in its own process.
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
cpp <- system2("git", c("diff", "--stat", old_ref, "--", "src"), stdout = TRUE)
lines <- c(
  sprintf("Old: %s; new: the working tree. Functions compared: %d.", old_ref, length(common)),
  sprintf("Functions changed: %s", if (length(changed)) paste(changed, collapse = ", ") else "none"),
  sprintf("Changed functions outside D-51's fix: %s",
          if (length(setdiff(changed, expected_changes))) paste(setdiff(changed, expected_changes), collapse = ", ")
          else "none"),
  sprintf("D-51's constructors unchanged (not expected): %s",
          if (length(setdiff(expected_changes, changed))) paste(setdiff(expected_changes, changed), collapse = ", ")
          else "none"),
  sprintf("Functions added: %s", if (length(added)) paste(added, collapse = ", ") else "none"),
  sprintf("Functions removed: %s", if (length(removed)) paste(removed, collapse = ", ") else "none"),
  sprintf("Exports identical: %s", identical(old$exports, new$exports)),
  sprintf("Registered S3 methods identical: %s", identical(old$s3, new$s3)),
  sprintf("Data sets identical: %s (%s)", identical(old$data, new$data), paste(names(new$data), collapse = ", ")),
  sprintf("C++ sources changed since %s: %s", old_ref, if (length(cpp)) paste(cpp, collapse = " ") else "none")
)
writeLines(lines, out_file)
