# Phase 5 planning: method fixture cases by function and by the family of their parent fit.
args <- commandArgs(trailingOnly = TRUE)
out_file <- args[1]
lines <- character()
say <- function(...) lines <<- c(lines, paste0(...))
for (set in c("core", "full")) {
  dir <- if (set == "core") "tests/testthat/fixtures/reference" else "validation/fixtures/reference"
  manifest <- jsonlite::read_json(file.path(dir, "manifest.json"))
  cases <- manifest$cases
  ids <- vapply(cases, function(x) x$id, "")
  funs <- vapply(cases, function(x) x$fun, "")
  names(funs) <- ids
  say(sprintf("%s: %d cases; manifest fields %s", set, length(cases), paste(names(cases[[1]]), collapse = ", ")))
  fixture <- function(id) readRDS(file.path(dir, paste0(id, ".rds")))
  parent_fun <- function(id) {
    case <- fixture(id)$case
    refs <- unlist(lapply(case$args, function(a) if (inherits(a, "pprof_ref_fit")) a$case_id))
    if (length(refs) == 0L) return(NA_character_)
    parent <- refs[1]
    if (parent %in% ids) funs[[parent]] else {
      core <- jsonlite::read_json("tests/testthat/fixtures/reference/manifest.json")$cases
      core_funs <- vapply(core, function(x) x$fun, "")
      names(core_funs) <- vapply(core, function(x) x$id, "")
      core_funs[[parent]]
    }
  }
  methods <- ids[funs %in% c("test", "SM_output", "confint", "summary", "plot")]
  if (length(methods) == 0L) next
  parents <- vapply(methods, function(id) tryCatch(parent_fun(id), error = function(e) paste("?", conditionMessage(e))), "")
  tab <- table(method = funs[methods], parent = parents)
  say(paste(capture.output(print(tab)), collapse = "\n"))
  for (fam in c("linear_fe", "linear_re", "logis_re", "linear_cre", "logis_cre")) {
    sel <- methods[parents == fam]
    tiers <- vapply(sel, function(id) fixture(id)$case$tier, "")
    outcome <- vapply(sel, function(id) { x <- fixture(id)$result; x$outcome }, "")
    say(sprintf("%s methods: %d cases; tiers %s; errors: %s", fam, length(sel),
                paste(names(table(tiers)), table(tiers), collapse = ", "),
                paste(sel[outcome == "error"], collapse = ", ")))
  }
}
writeLines(lines, out_file)
