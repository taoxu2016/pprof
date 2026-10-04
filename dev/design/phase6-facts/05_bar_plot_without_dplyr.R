# Phase 6 planning: can bar_plot()'s plot be built without dplyr? Compares the reference's plot
# (data from dplyr's grouped summary, to which ggplot2 adds a .group column) with the same
# drawing code given a base-R data frame of the same columns. Also: whether `bar_width` has an
# effect, and the fill colours when only some flag categories occur. Reference library.
# Run from the repository root: Rscript <this file> <output file>
.libPaths(c("dev/reference/lib", .Library))
Sys.setenv(OMP_THREAD_LIMIT = "1")
Sys.setlocale("LC_COLLATE", "C")
suppressPackageStartupMessages(library(pprof))
out_file <- commandArgs(TRUE)[1]
lines <- character()
say <- function(...) lines <<- c(lines, paste0(...))
quiet <- function(expr) suppressMessages(suppressWarnings(expr))

data(ExampleDataBinary)
bin <- data.frame(Y = ExampleDataBinary$Y, ProvID = ExampleDataBinary$ProvID, ExampleDataBinary$Z)
fit <- quiet(logis_fe(data = bin, Y.char = "Y", Z.char = paste0("z", 1:5), ProvID.char = "ProvID", message = FALSE))
tests <- quiet(test(fit))
reference <- quiet(bar_plot(tests))

# The same table in base R: counts by size group and category, observed combinations only,
# sorted by group and category, shares within each group, and the group index.
group_num <- 4
category <- factor(tests$flag, levels = c(1, 0, -1), labels = c("higher", "as expected", "lower"))
size <- attr(tests, "provider size")
groups <- c(paste0("Q", 1:group_num), "Overall")
group <- cut(size, breaks = stats::quantile(size, probs = (0:group_num) / group_num, na.rm = TRUE),
             include.lowest = TRUE, labels = paste0("Q", 1:group_num))
both <- data.frame(size = factor(c(as.character(group), rep("Overall", length(size))), levels = groups),
                   category = c(category, category))
counts <- as.data.frame(table(size = both$size, category = both$category, useNA = "ifany"), responseName = "count")
counts <- counts[counts$count > 0, , drop = FALSE]
counts <- counts[order(counts$size, counts$category), , drop = FALSE]
counts$count <- as.integer(counts$count)
counts$value <- counts$count / stats::ave(counts$count, counts$size, FUN = sum)
counts$.group <- as.integer(counts$size)
rownames(counts) <- NULL

ref_data <- as.data.frame(reference$data)
say("reference plot data class: ", paste(class(reference$data), collapse = "/"))
say("base-R table identical to as.data.frame(reference$data): ", identical(counts, ref_data))
if (!identical(counts, ref_data)) say(paste(utils::capture.output(all.equal(counts, ref_data)), collapse = "; "))

# Rebuild the plot with the reference's drawing code on the base-R table.
rebuilt <- reference
rebuilt$data <- counts
built_ref <- ggplot2::ggplot_build(reference)
built_new <- ggplot2::ggplot_build(rebuilt)
for (k in seq_along(reference$layers)) {
  same <- identical(built_ref$data[[k]], built_new$data[[k]])
  say(sprintf("layer %d (%s): built data identical: %s", k, class(reference$layers[[k]]$geom)[1], same))
  if (!same) say("  ", paste(utils::capture.output(all.equal(built_ref$data[[k]], built_new$data[[k]])), collapse = "; "))
}
# A plain data frame without the .group column, to see what the column does.
plain <- reference
plain$data <- counts[, c("size", "category", "count", "value")]
built_plain <- ggplot2::ggplot_build(plain)
say("without .group: layer 1 built data identical: ", identical(built_ref$data[[1]], built_plain$data[[1]]),
    "; group column equal: ", identical(built_ref$data[[1]]$group, built_plain$data[[1]]$group))

# The help documents `bar_width` as the width of the bars; the code draws width 0.7 whatever it is.
narrow <- quiet(bar_plot(tests, bar_width = 0.2))
say("bar_width = 0.2: built data identical to the default's: ",
    identical(ggplot2::ggplot_build(narrow)$data, built_ref$data),
    "; bar layer width parameter: ", format(narrow$layers[[1]]$geom_params$width %||% narrow$layers[[1]]$aes_params$width))

# The fill colours by category, when every category occurs and when only some do.
fill_map <- function(p) {
  scale <- ggplot2::ggplot_build(p)$plot$scales$get_scales("fill")
  limits <- scale$get_limits()
  paste(sprintf("%s=%s", limits, scale$map(limits)), collapse = ", ")
}
say("fill colours, every category present: ", fill_map(reference))
only_expected <- tests
only_expected$flag <- factor(rep(0, nrow(tests)))
say("fill colours, every provider as expected: ", fill_map(quiet(bar_plot(only_expected))))
no_higher <- tests
no_higher$flag <- factor(ifelse(as.character(tests$flag) == "1", "0", as.character(tests$flag)))
say("fill colours, no provider higher: ", fill_map(quiet(bar_plot(no_higher))))
writeLines(lines, out_file)
