# Phase 6 planning: what the plot fixtures record (plot, caterpillar_plot, bar_plot cases).
# Run from the repository root: Rscript <this file> <output file>
args <- commandArgs(trailingOnly = TRUE)
out_file <- args[1]
lines <- character()
say <- function(...) lines <<- c(lines, paste0(...))

dir <- "tests/testthat/fixtures/reference"
manifest <- jsonlite::read_json(file.path(dir, "manifest.json"))
say("core manifest: ", length(manifest$cases), " cases; ggplot2 ",
    manifest$numerically_relevant_packages$ggplot2 %||% "(not recorded)", "; packages recorded: ",
    paste(names(manifest$numerically_relevant_packages), collapse = ", "))
ids <- vapply(manifest$cases, function(x) x$id, "")
funs <- vapply(manifest$cases, function(x) x$fun, "")
plot_ids <- ids[funs %in% c("plot", "caterpillar_plot", "bar_plot")]
say("plot cases: ", length(plot_ids), " (", paste(names(table(funs[funs %in% c("plot", "caterpillar_plot", "bar_plot")])),
    table(funs[funs %in% c("plot", "caterpillar_plot", "bar_plot")]), collapse = ", "), ")")

describe_df <- function(d) {
  if (is.null(d)) return("NULL")
  if (inherits(d, "pprof_reference_large_df")) {
    return(sprintf("large df %s; names %s", paste(d$dim, collapse = "x"), paste(d$names, collapse = ",")))
  }
  extra <- setdiff(names(attributes(d)), c("names", "row.names", "class"))
  rn <- attr(d, "row.names")
  sprintf("%s %dx%d; names %s; types %s; row names %s; extra attributes: %s",
          paste(class(d), collapse = "/"), nrow(d), ncol(d), paste(names(d), collapse = ","),
          paste(vapply(d, function(col) paste(class(col), collapse = "/"), ""), collapse = ","),
          if (is.integer(rn) && length(rn) == 2L && is.na(rn[1])) "automatic" else paste(utils::head(rn, 3), collapse = ","),
          if (length(extra)) paste(sprintf("%s=%s", extra, vapply(extra, function(a) {
            v <- attr(d, a)
            if (is.atomic(v) && length(v) <= 3) paste(format(v), collapse = "|") else paste(class(v), collapse = "/")
          }, "")), collapse = "; ") else "none")
}

for (id in plot_ids) {
  fx <- readRDS(file.path(dir, paste0(id, ".rds")))
  case <- fx$case
  res <- fx$result
  say("")
  say("### ", id, " (", case$fun, ", tier ", case$tier, if (!is.null(case$notes)) paste0(", ", case$notes), ")")
  say("outcome: ", res$outcome, if (identical(res$outcome, "error")) paste0(" - ", res$error$message))
  if (length(res$warnings)) say("warnings stored: ", paste(unique(res$warnings), collapse = " | "))
  if (!identical(res$outcome, "value")) next
  v <- res$value
  say("class of stored value: ", paste(class(v), collapse = "/"))
  say("plot data: ", describe_df(v$data))
  for (k in seq_along(v$layers)) {
    layer <- v$layers[[k]]
    say(sprintf("layer %d: %s; mapping {%s}; data: %s", k, layer$geom, paste(layer$mapping, collapse = ","),
                describe_df(layer$data)))
  }
}
writeLines(lines, out_file)
