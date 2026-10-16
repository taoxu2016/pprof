# The test coverage of the R lines added since a commit: covr::package_coverage() on the working tree,
# restricted to the lines of R/ that `git diff <base>` adds, with the uncovered ones listed. The CoxPH
# brief's §11 item 6 asks for at least 90% of the new R code; the phase gates of C2 to C5 measured each
# phase's lines, and the C6 gate the whole phase's (against `ea7c07b`, the last commit before it).
# Run from the repository root:
#   Rscript dev/tools/coverage_added.R <output file> <base commit>
# covr runs the tests as R CMD check would, with `NOT_CRAN` unset, so tests behind skip_on_cran(), the
# full Cox fixture set's among them, do not count.
args <- commandArgs(trailingOnly = TRUE)
out_file <- args[[1]]
base <- args[[2]]

# The lines of each R file that the diff against `base` adds, from its hunk headers.
diff <- system2("git", c("diff", "--unified=0", base, "--", "R"), stdout = TRUE)
added <- list()
file <- NULL
for (line in diff) {
  if (startsWith(line, "+++ ")) {
    file <- if (identical(line, "+++ /dev/null")) NULL else sub("^\\+\\+\\+ b/", "", line)
  } else if (startsWith(line, "@@") && !is.null(file)) {
    hunk <- regmatches(line, regexec("\\+([0-9]+)(,([0-9]+))?", line))[[1]]
    first <- as.integer(hunk[[2]])
    count <- if (nzchar(hunk[[4]])) as.integer(hunk[[4]]) else 1L
    if (count > 0L) added[[file]] <- c(added[[file]], seq(first, length.out = count))
  }
}

t0 <- Sys.time()
coverage <- covr::package_coverage(quiet = TRUE)
lines <- covr::tally_coverage(coverage, by = "line")
lines$filename <- sub("^.*?(R/)", "R/", lines$filename, perl = TRUE)
lines$added <- mapply(function(f, l) l %in% added[[f]], lines$filename, lines$line)
mine <- lines[lines$added, , drop = FALSE]
uncovered <- mine[mine$value == 0, , drop = FALSE]
uncovered <- uncovered[order(uncovered$filename, uncovered$line), , drop = FALSE]
by_file <- aggregate(cbind(relevant = 1, covered = value > 0) ~ filename, mine, sum)
source_line <- function(f, l) trimws(readLines(f, warn = FALSE)[[l]])
writeLines(c(
  sprintf("Coverage of the R lines added since %s, at %s (%s): %d of %d relevant lines covered, %.2f%%; the package %.2f%%; %.0f s.",
          base, system2("git", c("rev-parse", "--short", "HEAD"), stdout = TRUE), format(Sys.time(), tz = "UTC", usetz = TRUE),
          sum(mine$value > 0), nrow(mine), 100 * mean(mine$value > 0), covr::percent_coverage(coverage),
          as.numeric(difftime(Sys.time(), t0, units = "secs"))),
  "", "By file (relevant added lines, covered):",
  sprintf("  %-32s %5d %5d", by_file$filename, by_file$relevant, by_file$covered),
  "", "Uncovered added lines:",
  if (nrow(uncovered)) sprintf("  %s:%d  %s", uncovered$filename, uncovered$line,
                               mapply(source_line, uncovered$filename, uncovered$line)) else "  none"
), out_file)
