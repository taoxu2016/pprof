# Phase 8 planning: two facts for the plot and site steps.
# 1. D-36: what ggplot2 builds for geom_errorbarh(), which the horizontal caterpillar_plot() keeps
#    from pprof 1.0.3, and for geom_errorbar(orientation = "y"), its replacement; and the
#    conditions each raises.
# 2. DEC-066: whether pkgdown can do without the site's address (`url` in _pkgdown.yml), which
#    `R CMD check --as-cran` reports as a 404: the parts of pkgdown's source that need it.
# Run from the repository root: Rscript <this file> <output file>
args <- commandArgs(trailingOnly = TRUE)
out_file <- args[1]
suppressMessages(library(ggplot2))
lines <- character()
say <- function(...) lines <<- c(lines, paste0(...))

conds <- character()
capture <- function(expr) {
  withCallingHandlers(expr,
    warning = function(w) {
      conds <<- c(conds, paste("warning:", gsub("\\s+", " ", conditionMessage(w))))
      invokeRestart("muffleWarning")
    },
    message = function(m) {
      conds <<- c(conds, paste("message:", gsub("\\s+", " ", conditionMessage(m))))
      invokeRestart("muffleMessage")
    }
  )
}
built_ends <- function(b) {
  d <- b$data[[1]][, c("xmin", "xmax", "ymin", "ymax", "width")]
  paste(apply(d, 1, function(r) paste(names(r), r, sep = "=", collapse = " ")), collapse = "; ")
}
d <- data.frame(id = factor(c("a", "b")), lo = c(0.5, 1.5), hi = c(1.5, 2.5))

say("## 1. Horizontal error bars, ggplot2 ", as.character(utils::packageVersion("ggplot2")))
conds <- character()
l1 <- capture(geom_errorbarh(aes(xmin = lo, xmax = hi, y = id), height = 0.2))
at_creation <- conds
conds <- character()
b1 <- capture(ggplot_build(ggplot(d) + l1))
say("- geom_errorbarh(height = 0.2): geom class ", class(l1$geom)[1], "; parameters ",
    paste(names(l1$geom_params), collapse = ", "))
say("  - when created: ", paste(at_creation, collapse = " | "))
say("  - when built: ", paste(conds, collapse = " | "))
say("  - built: ", built_ends(b1))
conds <- character()
l2 <- capture(geom_errorbar(aes(xmin = lo, xmax = hi, y = id), width = 0.2, orientation = "y"))
b2 <- capture(ggplot_build(ggplot(d) + l2))
say("- geom_errorbar(width = 0.2, orientation = \"y\"): geom class ", class(l2$geom)[1], "; parameters ",
    paste(names(l2$geom_params), collapse = ", "))
say("  - conditions: ", if (length(conds)) paste(conds, collapse = " | ") else "none")
say("  - built: ", built_ends(b2))
same <- c("xmin", "xmax", "ymin", "ymax")
say("- the bars' ends (xmin, xmax, ymin, ymax) identical: ",
    identical(b1$data[[1]][, same], b2$data[[1]][, same]), "; the width column identical: ",
    identical(b1$data[[1]]$width, b2$data[[1]]$width))

say("")
say("## 2. pkgdown ", as.character(utils::packageVersion("pkgdown")), " and the site's address")
show_lines <- function(fun, pattern) {
  src <- deparse(fun)
  i <- grep(pattern, src)
  trimws(src[sort(unique(c(i, i + 1)))])
}
say("- build_redirects(): ", paste(show_lines(pkgdown:::build_redirects, "has_url"), collapse = " "))
say("- check_urls(), called by check_pkgdown(): ",
    paste(show_lines(pkgdown:::check_urls, "is.null\\(url\\)|missing package url"), collapse = " "))
writeLines(lines, out_file)
