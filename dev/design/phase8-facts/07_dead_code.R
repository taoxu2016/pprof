# Phase 8 planning: dead code and repository hygiene (brief §9, DEC-015).
# - R functions defined at the top level of R/ that nothing references: no call or symbol in
#   another R/ file or elsewhere in their own, no NAMESPACE entry, and where they are used instead
#   (tests, vignettes) if anywhere;
# - Rcpp exports and the R files that call them;
# - the files the architecture test lists as the reference's, and .lintr's exclusions;
# - .Rbuildignore patterns that match no tracked file;
# - tracked files that look like OS or editor leftovers.
# Run from the repository root: Rscript <this file> <output file>
args <- commandArgs(trailingOnly = TRUE)
out_file <- args[1]
lines <- character()
say <- function(...) lines <<- c(lines, paste0(...))

tokens <- function(file) {
  pd <- utils::getParseData(parse(file, keep.source = TRUE))
  pd[pd$terminal, c("line1", "token", "text")]
}
r_files <- list.files("R", pattern = "\\.R$", full.names = TRUE)
defs <- do.call(rbind, lapply(r_files, function(f) {
  exprs <- parse(f, keep.source = FALSE)
  is_def <- vapply(exprs, function(e) {
    is.call(e) && as.character(e[[1]]) %in% c("<-", "=") && is.call(e[[3]]) && identical(e[[3]][[1]], as.name("function"))
  }, logical(1))
  if (!any(is_def)) return(NULL)
  data.frame(name = vapply(exprs[is_def], function(e) as.character(e[[2]]), ""), file = f)
}))
used_in <- function(files) {
  toks <- do.call(rbind, lapply(files, function(f) cbind(file = f, tokens(f))))
  toks[toks$token %in% c("SYMBOL_FUNCTION_CALL", "SYMBOL", "STR_CONST"), ]
}
r_toks <- used_in(r_files)
other_files <- c(list.files("tests/testthat", pattern = "\\.R$", full.names = TRUE),
                 list.files("vignettes", pattern = "\\.Rmd$", full.names = TRUE))
other_text <- vapply(other_files, function(f) paste(readLines(f, warn = FALSE), collapse = "\n"), "")
namespace <- readLines("NAMESPACE")
# S3method(generic, class) registers the function generic.class.
s3 <- regmatches(namespace, regexec("^S3method\\(([^,]+), *([^,)]+)", namespace))
s3 <- vapply(Filter(length, s3), function(m) paste0(gsub("\"", "", m[2]), ".", m[3]), "")
namespace <- c(namespace, paste0("(", s3, ")"))
say("## R functions with no reference in R/ or NAMESPACE (", nrow(defs), " top-level functions in R/; ",
    length(s3), " registered S3 methods count as referenced)")
say("")
for (i in seq_len(nrow(defs))) {
  nm <- defs$name[i]
  txt <- gsub("^\"|\"$", "", r_toks$text)
  n_refs <- sum(txt == nm) - 1  # minus the definition itself
  in_ns <- any(grepl(paste0("(\\(|, *)", gsub(".", "\\.", nm, fixed = TRUE), "(\\)|,)"), namespace))
  if (n_refs > 0 || in_ns) next
  where <- basename(other_files[grepl(paste0("\\b", gsub(".", "\\.", nm, fixed = TRUE), "\\b"), other_text)])
  say("- `", nm, "()` in ", defs$file[i], "; used in: ", if (length(where)) paste(where, collapse = ", ") else "nothing")
}

say("")
say("## Rcpp exports and their R callers (other than R/RcppExports.R)")
cpp <- unlist(lapply(list.files("src", pattern = "\\.cpp$", full.names = TRUE), readLines))
exports <- unique(sub("^[^ ]+ +([A-Za-z0-9_]+)\\(.*$", "\\1", cpp[which(grepl("Rcpp::export", cpp)) + 1]))
for (e in exports) {
  callers <- basename(r_files[vapply(r_files, function(f) any(grepl(e, readLines(f), fixed = TRUE)), logical(1))])
  callers <- setdiff(callers, "RcppExports.R")
  tests <- basename(other_files[grepl(e, other_text, fixed = TRUE)])
  say("- ", e, ": R ", if (length(callers)) paste(callers, collapse = ", ") else "none",
      "; tests ", if (length(tests)) paste(tests, collapse = ", ") else "none")
}

say("")
say("## The reference's files and the lint exclusions")
arch <- readLines("tests/testthat/test-architecture.R")
say("- test-architecture.R, lines naming files of R/ as legacy: ",
    paste(trimws(grep("legacy|data_check|pprof\\.R|RcppExports", arch, value = TRUE)), collapse = " / "))
say("- .lintr: ", paste(trimws(readLines(".lintr")), collapse = " "))

say("")
say("## .Rbuildignore patterns that match no tracked file or directory")
tracked <- system2("git", c("ls-files"), stdout = TRUE)
paths <- unique(c(tracked, unlist(lapply(strsplit(tracked, "/"), function(p) {
  vapply(seq_along(p), function(k) paste(p[seq_len(k)], collapse = "/"), "")
}))))
patterns <- trimws(readLines(".Rbuildignore"))
patterns <- patterns[nzchar(patterns) & !startsWith(patterns, "#")]
for (p in patterns) {
  if (!any(grepl(p, paths, perl = TRUE))) say("- `", p, "`")
}

say("")
say("## Tracked files that look like leftovers")
leftovers <- grep("(\\.DS_Store|Thumbs\\.db|\\.Rhistory|\\.RData|~|\\.orig|\\.bak|\\.swp)$", tracked, value = TRUE)
say(if (length(leftovers)) paste("-", leftovers) else "- none")
say("- workflows: ", paste(list.files(".github/workflows"), collapse = ", "))

say("")
say("## Line widths of the C++ sources (for a clang-format column limit; RcppExports.cpp is generated)")
cpp_files <- setdiff(list.files("src", pattern = "\\.(cpp|h)$", recursive = TRUE, full.names = TRUE),
                     "src/RcppExports.cpp")
widths <- unlist(lapply(cpp_files, function(f) nchar(readLines(f, warn = FALSE), type = "chars")))
say("- ", length(cpp_files), " files, ", length(widths), " lines; widest ", max(widths), " characters; over 100: ",
    sum(widths > 100), "; over 110: ", sum(widths > 110), "; over 120: ", sum(widths > 120))
writeLines(lines, out_file)
