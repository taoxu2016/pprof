# Phase 7: render each vignette in vignettes/ in its own R process, as R CMD build does, and
# report the elapsed time, the size of the HTML, and the number of embedded figures, against
# DEC-062's budget (each vignette's code at most 10 s, all at most 30 s; the installed doc/
# under 1 MB). The time includes starting R and pandoc, so it is an upper bound on the code's.
# Run from the repository root: Rscript <this file> <output file> <scratch directory> [<library>]
# With a library, pprof is loaded from it (a build of the working tree); otherwise from the
# default library paths.
args <- commandArgs(trailingOnly = TRUE)
out_file <- args[1]
scratch <- args[2]
lib <- if (length(args) > 2) args[3] else NULL
dir.create(scratch, showWarnings = FALSE, recursive = TRUE)
lines <- c(sprintf("pandoc %s; rmarkdown %s; knitr %s", rmarkdown::pandoc_version(), packageVersion("rmarkdown"),
                   packageVersion("knitr")),
           "vignette | elapsed s | exit status | HTML KB | figures | warnings")
total_time <- 0
total_size <- 0
# A baseline vignette that only attaches pprof and draws one plot measures the fixed cost of
# a render (starting R, loading the packages, knitr, pandoc); a vignette's code takes about
# its elapsed time minus the baseline's.
baseline <- file.path(scratch, "baseline.Rmd")
writeLines(c("---", "title: baseline", "output: rmarkdown::html_vignette", "vignette: >",
             "  %\\VignetteIndexEntry{baseline}", "---", "", "```{r}",
             "library(pprof)", "plot(ggplot2::ggplot(data.frame(x = 1:3, y = 1:3), ggplot2::aes(x, y)))", "```"),
           baseline)
vignettes <- c(baseline, sort(list.files("vignettes", pattern = "[.]Rmd$", full.names = TRUE)))
for (rmd in vignettes) {
  script <- file.path(scratch, paste0(basename(rmd), ".render.R"))
  log <- file.path(scratch, paste0(basename(rmd), ".log"))
  scratch_path <- normalizePath(scratch, winslash = "/")
  warnings_path <- paste0(scratch_path, "/", basename(rmd), ".warnings")
  writeLines(c(
    if (!is.null(lib)) sprintf(".libPaths(c(%s, .libPaths()))", deparse(normalizePath(lib, winslash = "/"))),
    "warnings_seen <- character()",
    "keep_warning <- function(w) {",
    "  warnings_seen <<- c(warnings_seen, conditionMessage(w))",
    "  invokeRestart(\"muffleWarning\")",
    "}",
    sprintf("withCallingHandlers(rmarkdown::render(%s, output_dir = %s, quiet = TRUE, envir = new.env()),",
            deparse(normalizePath(rmd, winslash = "/")), deparse(scratch_path)),
    "                    warning = keep_warning)",
    sprintf("writeLines(unique(warnings_seen), %s)", deparse(warnings_path))
  ), script)
  start <- Sys.time()
  status <- system2(file.path(R.home("bin"), "Rscript"), shQuote(script), stdout = log, stderr = log)
  elapsed <- as.numeric(difftime(Sys.time(), start, units = "secs"))
  html <- file.path(scratch, sub("[.]Rmd$", ".html", basename(rmd)))
  size <- if (file.exists(html)) file.size(html) / 1024 else NA
  figures <- if (file.exists(html)) {
    sum(gregexpr("data:image/", paste(readLines(html, warn = FALSE), collapse = ""))[[1]] > 0)
  } else {
    NA
  }
  warn_file <- file.path(scratch, paste0(basename(rmd), ".warnings"))
  warns <- if (file.exists(warn_file)) readLines(warn_file, warn = FALSE) else character()
  # knitr writes the warnings of chunks into the document ("#> Warning: ...").
  if (file.exists(html)) {
    text <- readLines(html, warn = FALSE)
    in_doc <- grep("#&gt; Warning", text, value = TRUE)
    warns <- c(warns, if (length(in_doc)) paste("in the document:", trimws(gsub("<[^>]+>", "", in_doc))))
  }
  if (rmd != baseline) {
    total_time <- total_time + elapsed
    total_size <- total_size + if (is.na(size)) 0 else size
  }
  lines <- c(lines, sprintf("%s | %.1f | %s | %.0f | %s | %s", basename(rmd), elapsed, status, size, figures,
                            if (length(warns)) paste(gsub("[[:space:]]+", " ", warns), collapse = " / ") else "none"))
}
lines <- c(lines, sprintf("total of the package's vignettes: %.1f s, %.0f KB of HTML", total_time, total_size))
writeLines(lines, out_file)
