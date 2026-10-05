# Phase 7 planning: the code of the five old vignettes (vignettes/*.Rmd) run on the working tree,
# chunk by chunk, with every chunk evaluated (four of the five set eval = FALSE for all chunks).
# Reports, per chunk, the outcome (ok, or the error), the warnings, and the elapsed time. The
# installation chunk and the knitr setup chunk are skipped.
# Run from the repository root: Rscript <this file> <output file> [<library with pprof installed>]
args <- commandArgs(trailingOnly = TRUE)
out_file <- args[1]
lib <- if (length(args) > 1) args[2] else NULL
Sys.setlocale("LC_COLLATE", "C")
grDevices::pdf(NULL) # plots are built on a null device, so no Rplots.pdf is written
if (is.null(lib)) {
  suppressMessages(devtools::load_all(quiet = TRUE))
} else {
  suppressPackageStartupMessages(library(pprof, lib.loc = lib))
}
lines <- character()
say <- function(...) lines <<- c(lines, paste0(...))

# The R chunks of an R Markdown file: their header and code.
rmd_chunks <- function(path) {
  text <- readLines(path, warn = FALSE)
  starts <- grep("^```[{][rR]", text)
  ends <- grep("^```[[:space:]]*$", text)
  lapply(starts, function(s) {
    e <- min(ends[ends > s])
    list(header = text[s], line = s, code = text[seq_len(e - s - 1L) + s])
  })
}

for (file in c("pprof.Rmd", "Quick-start.Rmd", "Risk-adjustment_Model.Rmd", "Logis-FE.Rmd", "Linear-FE.Rmd")) {
  path <- file.path("vignettes", file)
  chunks <- rmd_chunks(path)
  say("## ", file, ": ", length(chunks), " R chunks")
  env <- new.env(parent = globalenv())
  for (chunk in chunks) {
    if (grepl("include[[:space:]]*=[[:space:]]*(FALSE|F)\\b", chunk$header) &&
        any(grepl("opts_chunk", chunk$code))) {
      say("line ", chunk$line, ": knitr setup chunk, skipped")
      next
    }
    if (any(grepl("install_github", chunk$code))) {
      say("line ", chunk$line, ": installation chunk, skipped")
      next
    }
    warnings <- character()
    outcome <- "ok"
    timing <- system.time(
      withCallingHandlers(
        tryCatch({
          # Plots are built, as knitr would print them.
          out <- utils::capture.output(for (expr in parse(text = chunk$code)) {
            value <- eval(expr, env)
            if (inherits(value, "ggplot")) ggplot2::ggplot_build(value)
          })
          invisible(out)
        }, error = function(e) outcome <<- paste("error:", gsub("[[:space:]]+", " ", conditionMessage(e)))),
        warning = function(w) {
          warnings <<- c(warnings, gsub("[[:space:]]+", " ", conditionMessage(w)))
          invokeRestart("muffleWarning")
        },
        message = function(m) invokeRestart("muffleMessage")
      )
    )
    first <- chunk$code[nzchar(trimws(chunk$code))][1]
    say("line ", chunk$line, " (", sprintf("%.2f s", timing[["elapsed"]]), ") `", substr(first, 1, 70), "`: ", outcome,
        if (length(warnings)) paste0("; warnings: ", paste(unique(warnings), collapse = " | ")) else "")
  }
  say("")
}
writeLines(lines, out_file)
