# Shared building blocks of the plots: flag categories, their colours and shapes, and the
# theme. Plots read result objects only (ARCHITECTURE §B.1, rule 3).

plot_flag_values <- c(-1L, 0L, 1L)
plot_flag_labels <- c("lower", "as expected", "higher")
plot_flag_colors <- c("#E69F00", "#56B4E9", "#009E73")
plot_flag_shapes <- c(15, 17, 19)

# Flags as a factor with the three categories in a fixed order; missing flags stay missing.
plot_flag_factor <- function(flag) {
  factor(flag, levels = plot_flag_values, labels = plot_flag_labels)
}

# Legend labels with the number of providers in each category.
plot_flag_legend <- function(flag) {
  counts <- table(plot_flag_factor(flag))
  stats::setNames(sprintf("%s (%d)", plot_flag_labels, as.integer(counts)), plot_flag_labels)
}

plot_theme <- function(base_size = 13) {
  ggplot2::theme_classic(base_size = base_size) +
    ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0.5))
}

plot_check_result <- function(x, classes, arg = "x") {
  if (!inherits(x, classes)) {
    abort_invalid_input(sprintf("`%s` must be %s.", arg, paste0("a `", classes, "` result", collapse = " or ")),
                        arg = arg)
  }
  invisible(x)
}

# The axis label of a measure.
plot_measure_label <- function(measure, standardization = NULL) {
  scale <- switch(measure, ratio = "ratio", rate = "rate (%)", difference = "difference", measure)
  if (is.null(standardization)) return(paste("Standardized", scale))
  paste0(toupper(substr(standardization, 1L, 1L)), substring(standardization, 2L), " standardized ", scale)
}
