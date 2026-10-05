# Phase 7 planning: the pkgdown configuration and the committed site. What
# pkgdown::check_pkgdown() reports, which help topics the reference index leaves out, what the
# committed docs/ holds (size, pkgdown version, build date, articles), and whether pandoc is
# available to build vignettes and the site.
# Run from the repository root: Rscript <this file> <output file>
args <- commandArgs(trailingOnly = TRUE)
out_file <- args[1]
lines <- character()
say <- function(...) lines <<- c(lines, paste0(...))
capture <- function(expr) {
  out <- character()
  value <- withCallingHandlers(
    tryCatch({
      out <- c(out, utils::capture.output(res <- expr, type = "message"))
      "ok"
    }, error = function(e) paste("error:", gsub("[[:space:]]+", " ", conditionMessage(e)))),
    warning = function(w) {
      out <<- c(out, paste("warning:", conditionMessage(w)))
      invokeRestart("muffleWarning")
    },
    message = function(m) {
      out <<- c(out, paste("message:", gsub("\n$", "", conditionMessage(m))))
      invokeRestart("muffleMessage")
    }
  )
  c(value, out)
}

say("pkgdown ", as.character(packageVersion("pkgdown")), "; knitr ", as.character(packageVersion("knitr")),
    "; rmarkdown ", as.character(packageVersion("rmarkdown")))
say("rmarkdown::pandoc_available(): ", rmarkdown::pandoc_available())
say("markdown package installed: ", requireNamespace("markdown", quietly = TRUE))

say("")
say("## 1. pkgdown::check_pkgdown()")
for (l in capture(pkgdown::check_pkgdown("."))) say(gsub("[^[:print:]]", "", l))

say("")
say("## 2. Help topics missing from the reference index of _pkgdown.yml")
config <- yaml::read_yaml("_pkgdown.yml")
listed <- unlist(lapply(config$reference, `[[`, "contents"))
db <- tools::Rd_db(dir = ".")
topics <- vapply(db, function(rd) tools:::.Rd_get_metadata(rd, "name"), character(1))
internal <- vapply(db, function(rd) "internal" %in% tools:::.Rd_get_metadata(rd, "keyword"), logical(1))
missing <- sort(setdiff(topics[!internal], listed))
say("listed: ", length(listed), "; topics (not internal): ", sum(!internal), "; internal: ", sum(internal))
say("not listed (", length(missing), "): ", paste(missing, collapse = ", "))
say("internal topics: ", paste(sort(topics[internal]), collapse = ", "))

say("")
say("## 3. The committed site, docs/")
files <- list.files("docs", recursive = TRUE, all.files = TRUE)
say("files: ", length(files), "; size: ", sprintf("%.1f MB", sum(file.size(file.path("docs", files))) / 2^20))
say("by top-level entry: ", paste(names(table(sub("/.*", "", files))), table(sub("/.*", "", files)),
                                  sep = " ", collapse = "; "))
site <- yaml::read_yaml("docs/pkgdown.yml")
say("docs/pkgdown.yml: pandoc ", site$pandoc, "; pkgdown ", site$pkgdown, "; last_built ", site$last_built,
    "; articles: ", paste(names(site$articles), collapse = ", "))
reference_pages <- sub("[.]html$", "", list.files("docs/reference", pattern = "[.]html$"))
say("reference pages: ", length(reference_pages), "; of the current topics, absent from docs/reference: ",
    paste(sort(setdiff(topics, reference_pages)), collapse = ", "))
say("git log of docs/ (last commit): ", paste(system2("git", c("log", "-1", "--format=%h|%ad|%s", "--date=short",
                                                               "--", "docs"), stdout = TRUE), collapse = " "))

say("")
say("## 4. Vignettes and the build")
say("vignettes/: ", paste(list.files("vignettes", recursive = TRUE), collapse = ", "))
say("DESCRIPTION VignetteBuilder: ", if (is.na(read.dcf("DESCRIPTION", fields = "VignetteBuilder")[1, 1])) "absent"
    else read.dcf("DESCRIPTION", fields = "VignetteBuilder")[1, 1])
rbuildignore <- readLines(".Rbuildignore")
say(".Rbuildignore lines about vignettes, docs, pkgdown, README: ",
    paste(grep("vignette|docs|pkgdown|README", rbuildignore, value = TRUE), collapse = " ; "))
images <- regmatches(readLines("vignettes/pprof.Rmd"), regexpr("[(]Charts/[^)]+[)]", readLines("vignettes/pprof.Rmd")))
for (img in images) {
  path <- file.path("vignettes", gsub("^[(]|[)]$", "", img))
  say("image referenced by pprof.Rmd: ", path, " exists: ", file.exists(path))
}
writeLines(lines, out_file)
