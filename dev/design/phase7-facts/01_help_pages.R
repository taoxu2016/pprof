# Phase 7 planning: the help pages of the working tree. For each page in man/: its aliases,
# whether it is internal, whether it has examples and a "See also" section, which functions it
# links to, and, for the pages of the old interface, whether it names the function that replaces
# it (ARCHITECTURE §I.1). Then the run time of each page's examples, as R CMD check runs them.
# Run from the repository root: Rscript <this file> <output file> [<library with pprof installed>]
# Without a library, the examples run on devtools::load_all().
args <- commandArgs(trailingOnly = TRUE)
out_file <- args[1]
lib <- if (length(args) > 1) args[2] else NULL
lines <- character()
say <- function(...) lines <<- c(lines, paste0(...))

rd_get <- function(rd, tag) tools:::.Rd_get_metadata(rd, tag)
rd_has_section <- function(rd, tag) any(vapply(rd, function(x) identical(attr(x, "Rd_tag"), tag), logical(1)))
rd_links <- function(rd) {
  found <- character()
  walk <- function(x) {
    if (identical(attr(x, "Rd_tag"), "\\link")) found <<- c(found, paste(unlist(x), collapse = ""))
    if (is.list(x)) for (y in x) walk(y)
  }
  walk(rd)
  unique(found)
}
rd_text <- function(rd) paste(utils::capture.output(tools::Rd2txt(rd, options = list(underline_titles = FALSE))),
                              collapse = " ")

db <- tools::Rd_db(dir = ".")
names(db) <- basename(names(db))

# The replacement each page of the old interface should name (ARCHITECTURE §I.1).
old_pages <- list(
  logis_fe.Rd = "fit_logistic_fe", logis_firth.Rd = "fit_logistic_firth", linear_fe.Rd = "fit_linear_fe",
  linear_re.Rd = "fit_linear_re", logis_re.Rd = "fit_logistic_re", linear_cre.Rd = "fit_linear_cre",
  logis_cre.Rd = "fit_logistic_cre", test.Rd = "test_providers", SM_output.Rd = "standardize_providers",
  test.logis_fe.Rd = "test_providers", test.linear_fe.Rd = "test_providers", test.linear_re.Rd = "test_providers",
  test.logis_re.Rd = "test_providers", test.linear_cre.Rd = "test_providers", test.logis_cre.Rd = "test_providers",
  SM_output.logis_fe.Rd = "standardize_providers", SM_output.linear_fe.Rd = "standardize_providers",
  SM_output.linear_re.Rd = "standardize_providers", SM_output.logis_re.Rd = "standardize_providers",
  SM_output.linear_cre.Rd = "standardize_providers", SM_output.logis_cre.Rd = "standardize_providers",
  confint.logis_fe.Rd = c("provider_effects", "standardize_providers"),
  confint.linear_fe.Rd = c("provider_effects", "standardize_providers"),
  confint.linear_re.Rd = c("provider_effects", "standardize_providers"),
  confint.logis_re.Rd = c("provider_effects", "standardize_providers"),
  confint.linear_cre.Rd = c("provider_effects", "standardize_providers"),
  confint.logis_cre.Rd = c("provider_effects", "standardize_providers"),
  summary.logis_fe.Rd = "test_coefficients", summary.linear_fe.Rd = "test_coefficients",
  summary.logis_re.Rd = "test_coefficients", plot.logis_fe.Rd = "plot_funnel", plot.linear_fe.Rd = "plot_funnel",
  caterpillar_plot.Rd = "plot_caterpillar", bar_plot.Rd = "plot_flags", data_check.Rd = "check_data"
)

say("## 1. Help pages (", length(db), ")")
say("file | internal | examples (lines) | see also | links")
for (file in sort(names(db))) {
  rd <- db[[file]]
  keywords <- rd_get(rd, "keyword")
  example_lines <- if (rd_has_section(rd, "\\examples")) {
    length(strsplit(paste(unlist(tools:::.Rd_get_section(rd, "examples")), collapse = ""), "\n")[[1]])
  } else 0L
  say(file, " | ", "internal" %in% keywords, " | ", example_lines, " | ", rd_has_section(rd, "\\seealso"), " | ",
      paste(rd_links(rd), collapse = ", "))
}

say("")
say("## 2. Pages of the old interface: does the page name its replacement?")
for (file in names(old_pages)) {
  if (!file %in% names(db)) {
    say(file, ": no such page")
    next
  }
  text <- rd_text(db[[file]])
  named <- vapply(old_pages[[file]], function(f) grepl(f, text, fixed = TRUE), logical(1))
  say(file, ": ", paste(sprintf("%s %s", old_pages[[file]], ifelse(named, "named", "NOT named")), collapse = "; "))
}

say("")
say("## 3. Exported functions without a help alias")
exports <- getNamespaceExports(if (is.null(lib)) {
  suppressMessages(devtools::load_all(quiet = TRUE))
  "pprof"
} else {
  suppressPackageStartupMessages(library(pprof, lib.loc = lib))
  "pprof"
})
aliases <- unlist(lapply(db, rd_get, "alias"))
say(paste(sort(setdiff(exports, aliases)), collapse = ", "), if (!length(setdiff(exports, aliases))) "none")

say("")
say("## 4. Example run times (each page's examples in a fresh environment, pprof attached, 1 thread)")
say("file | elapsed s | user+system s | outcome")
total <- 0
for (file in sort(names(db))) {
  rd <- db[[file]]
  if (!rd_has_section(rd, "\\examples")) next
  code_file <- tempfile(fileext = ".R")
  tools::Rd2ex(rd, out = code_file, commentDontrun = TRUE, commentDonttest = FALSE)
  if (!file.exists(code_file)) next
  outcome <- "ok"
  timing <- system.time(
    withCallingHandlers(
      tryCatch(sys.source(code_file, envir = new.env(parent = globalenv())),
               error = function(e) outcome <<- paste("error:", conditionMessage(e))),
      warning = function(w) invokeRestart("muffleWarning"),
      message = function(m) invokeRestart("muffleMessage")
    )
  )
  total <- total + timing[["elapsed"]]
  say(file, " | ", sprintf("%.2f", timing[["elapsed"]]), " | ",
      sprintf("%.2f", timing[["user.self"]] + timing[["sys.self"]]), " | ", outcome)
}
say("total elapsed: ", sprintf("%.1f", total), " s")
writeLines(lines, out_file)
