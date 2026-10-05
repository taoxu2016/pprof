# Phase 8 planning: what R CMD check --as-cran reports for the committed tree with the version set
# to 2.0.0, the Date to today, and NEWS.md's heading to "# pprof 2.0.0" (in a scratch copy made
# with git archive; nothing in the repository changes), and what makes the tarball large.
# Tests are not run (--no-tests); examples and vignettes are.
# Run from the repository root: Rscript <this file> <output file> <scratch directory>
args <- commandArgs(trailingOnly = TRUE)
out_file <- normalizePath(args[1], mustWork = FALSE)
scratch <- normalizePath(args[2], mustWork = FALSE)
force(out_file)
lines <- character()
say <- function(...) lines <<- c(lines, paste0(...))

src <- file.path(scratch, "pprof")
unlink(scratch, recursive = TRUE)
dir.create(src, recursive = TRUE)
archive <- file.path(scratch, "head.tar")
system2("git", c("archive", "--format=tar", "-o", shQuote(archive), "HEAD"))
utils::untar(archive, exdir = src)
commit <- system2("git", c("rev-parse", "--short", "HEAD"), stdout = TRUE)

desc <- readLines(file.path(src, "DESCRIPTION"))
desc <- sub("^Version: .*", "Version: 2.0.0", desc)
desc <- sub("^Date: .*", paste("Date:", Sys.Date()), desc)
writeLines(desc, file.path(src, "DESCRIPTION"))
news <- readLines(file.path(src, "NEWS.md"))
news[1] <- "# pprof 2.0.0"
writeLines(news, file.path(src, "NEWS.md"))

r_cmd <- file.path(R.home("bin"), "R")
owd <- setwd(scratch)
t0 <- Sys.time()
system2(r_cmd, c("CMD", "build", "pprof"), stdout = "build.log", stderr = "build.log")
t1 <- Sys.time()
system2(r_cmd, c("CMD", "check", "--as-cran", "--no-manual", "--no-tests", "--timings", "pprof_2.0.0.tar.gz"),
        stdout = "check.log", stderr = "check.log")
t2 <- Sys.time()
setwd(owd)

say("Commit ", commit, " with Version 2.0.0, Date ", Sys.Date(), ", and NEWS heading \"# pprof 2.0.0\"; ",
    R.version.string, ", ", utils::osVersion)
say("R CMD build: ", round(as.numeric(difftime(t1, t0, units = "mins")), 1), " min; R CMD check --as-cran ",
    "--no-manual --no-tests: ", round(as.numeric(difftime(t2, t1, units = "mins")), 1), " min")
check_log <- readLines(file.path(scratch, "pprof.Rcheck", "00check.log"))
say("")
say("## Status")
say(grep("^Status", check_log, value = TRUE))
say("")
say("## Items that are not OK")
starts <- grep("\\.\\.\\. .*(NOTE|WARNING|ERROR)$", check_log)
for (s in starts) {
  next_item <- grep("^\\* ", check_log)
  end <- min(c(next_item[next_item > s], length(check_log) + 1)) - 1
  say("")
  say(check_log[s:end])
}

say("")
say("## The tarball")
tarball <- file.path(scratch, "pprof_2.0.0.tar.gz")
say("Size: ", file.size(tarball), " bytes (R CMD check --as-cran notes tarballs over 5,000,000 bytes)")
files <- utils::untar(tarball, list = TRUE)
info <- file.info(file.path(scratch, "pprof.Rcheck", "00_pkg_src", files))
info <- info[!info$isdir & !is.na(info$size), ]
rel <- sub(".*00_pkg_src/pprof/", "", rownames(info))
area <- ifelse(grepl("^tests/testthat/fixtures/reference/datasets/", rel), "tests/testthat/fixtures/reference/datasets",
          ifelse(grepl("^tests/testthat/fixtures/", rel), "tests/testthat/fixtures/reference (cases, manifest)",
                 sub("/.*", "", rel)))
sizes <- sort(tapply(info$size, area, sum), decreasing = TRUE)
say("")
say("| Part (uncompressed bytes) | Bytes |")
say("|---|---|")
for (k in names(sizes)) say("| ", k, " | ", sizes[[k]], " |")
copies <- c("binary_example.rds", "binary_example_list.rds", "linear_example.rds", "linear_example_list.rds")
copy_sizes <- info$size[basename(rel) %in% copies & grepl("datasets/", rel)]
say("")
say("The four datasets copied from the bundled data (", paste(copies, collapse = ", "), "): ", sum(copy_sizes),
    " bytes; data/: ", sum(info$size[grepl("^data/", rel)]), " bytes")
writeLines(lines, out_file)
