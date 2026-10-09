# Shared building blocks of the plots (brief §5.7, DEC-058): the flag categories with their
# colours and shapes, the flag scales, the reference line, the ends of interval bars, labels
# and subtitles from the settings of result objects, the theme, and the argument checks.
# Plots read result objects only (ARCHITECTURE §B.1, rule 3); what they draw comes from the
# profiling layer (DEC-056).

# The plots and the compatibility wrappers of the old plots refer to columns through the
# `.data` pronoun, which ggplot2 re-exports from rlang (DEC-057).
#' @importFrom ggplot2 .data
#' @noRd
NULL

plot_flag_values <- c(-1L, 0L, 1L)
plot_flag_labels <- c("lower", "as expected", "higher")
plot_no_flag <- "no flag"
# The colours and shapes of pprof 1.0.3's funnel plot (Okabe-Ito colours), and grey and a
# cross for providers without a flag.
plot_flag_colors <- c("lower" = "#E69F00", "as expected" = "#56B4E9", "higher" = "#009E73", "no flag" = "#999999")
plot_flag_shapes <- c("lower" = 15, "as expected" = 17, "higher" = 19, "no flag" = 4)

# Flags as a factor with the three categories in a fixed order, and a "no flag" category for
# missing flags when there are any.
plot_flag_factor <- function(flag) {
  category <- factor(flag, levels = plot_flag_values, labels = plot_flag_labels)
  if (!anyNA(category)) return(category)
  factor(ifelse(is.na(category), plot_no_flag, as.character(category)), levels = c(plot_flag_labels, plot_no_flag))
}

# Manual scales of flag categories for the given aesthetics: each category has its colour or
# shape whatever categories occur, and the legend lists every category of `category`'s levels,
# with the number of providers when `counts` is TRUE.
plot_flag_scales <- function(category, aesthetics = c("colour", "shape"), name = "Flag", counts = TRUE) {
  categories <- levels(category)
  labels <- if (counts) sprintf("%s (%d)", categories, as.integer(table(category))) else categories
  lapply(aesthetics, function(aesthetic) {
    values <- if (identical(aesthetic, "shape")) plot_flag_shapes[categories] else plot_flag_colors[categories]
    ggplot2::scale_discrete_manual(aesthetic, values = values, breaks = categories, limits = categories,
                                   labels = labels, drop = FALSE, name = name)
  })
}

# A horizontal (vertical = TRUE) or vertical reference line.
plot_reference_layer <- function(value, vertical, line_width, linetype = "dashed", colour = "#64748b") {
  if (vertical) {
    ggplot2::geom_hline(yintercept = value, linetype = linetype, colour = colour, linewidth = line_width)
  } else {
    ggplot2::geom_vline(xintercept = value, linetype = linetype, colour = colour, linewidth = line_width)
  }
}

# The ends of each interval bar, `from` and `to`. Two-sided intervals run from the lower to the
# upper limit, an infinite limit to the edge of the panel; a one-sided interval runs from its
# bound to the estimate, as in pprof 1.0.3's caterpillar_plot().
plot_interval_ends <- function(table, alternative) {
  if (is.null(alternative)) alternative <- "two.sided"
  table$from <- if (identical(alternative, "less")) table$estimate else table$lower
  table$to <- if (identical(alternative, "greater")) table$estimate else table$upper
  table
}

# The axis label of a measure.
plot_measure_label <- function(measure, standardization = NULL) {
  scale <- switch(measure, ratio = "ratio", rate = "rate (%)", difference = "difference", measure)
  if (is.null(standardization)) return(paste("Standardized", scale))
  paste0(toupper(substr(standardization, 1L, 1L)), substring(standardization, 2L), " standardized ", scale)
}

plot_level_text <- function(level) {
  sprintf("%s%%", format(100 * level, trim = TRUE))
}

plot_alternative_text <- function(alternative) {
  if (is.null(alternative)) alternative <- "two.sided"
  switch(alternative, two.sided = "two-sided", greater = "one-sided (greater)", less = "one-sided (less)", alternative)
}

# "flags: exact test at the 95% level, two-sided".
plot_test_subtitle <- function(test, level, alternative = "two.sided", score_type = NULL) {
  name <- switch(test, exact = "exact test", bootstrap = "bootstrap test", wald = "Wald test", midp = "mid-p test",
                 score = if (identical(score_type, "standard")) "standard score test" else "score test",
                 paste(test, "test"))
  sprintf("flags: %s at the %s level, %s", name, plot_level_text(level), plot_alternative_text(alternative))
}

# "exact intervals at the 95% level, two-sided".
plot_interval_subtitle <- function(interval, level, alternative = "two.sided") {
  name <- switch(interval, wald = "Wald", midp = "mid-p", interval)
  sprintf("%s intervals at the %s level, %s", name, plot_level_text(level), plot_alternative_text(alternative))
}

# The rows of a table whose estimate is finite, and a caption counting the providers left out, or
# NULL when there are none: a Cox provider without expected events has an undefined ratio (K-147),
# which a plot cannot place. No provider of the other families is left out.
plot_finite_rows <- function(table) {
  finite <- is.finite(table$estimate)
  omitted <- sum(!finite)
  if (omitted == 0L) return(list(table = table, caption = NULL))
  caption <- sprintf("%d provider%s without a finite estimate (no expected events) not shown", omitted,
                     if (omitted == 1L) "" else "s")
  list(table = table[finite, , drop = FALSE], caption = caption)
}

# The plot with its caption, if any.
plot_add_caption <- function(plot, caption) {
  if (is.null(caption)) plot else plot + ggplot2::labs(caption = caption)
}

# The subtitle from its parts, joined by semicolons and starting with a capital; NULL without
# parts.
plot_subtitle <- function(...) {
  parts <- c(...)
  if (length(parts) == 0L) return(NULL)
  text <- paste(parts, collapse = "; ")
  paste0(toupper(substr(text, 1L, 1L)), substring(text, 2L))
}

plot_theme <- function(base_size = 12) {
  ggplot2::theme_classic(base_size = base_size) +
    ggplot2::theme(plot.title = ggplot2::element_text(face = "bold"),
                   plot.subtitle = ggplot2::element_text(colour = "grey30"),
                   plot.title.position = "plot")
}

plot_check_result <- function(x, classes, arg = "x") {
  if (!inherits(x, classes)) {
    abort_invalid_input(sprintf("`%s` must be %s.", arg, paste0("a `", classes, "` result", collapse = " or ")),
                        arg = arg)
  }
  invisible(x)
}

# The sizes of points and labels, the opacity of points, and the width of lines.
plot_check_style <- function(point_size = NULL, point_alpha = NULL, line_width = NULL, label_size = NULL) {
  if (!is.null(point_size)) check_number(point_size, "point_size", lower = 0)
  if (!is.null(point_alpha)) check_number(point_alpha, "point_alpha", lower = 0, upper = 1)
  if (!is.null(line_width)) check_number(line_width, "line_width", lower = 0)
  if (!is.null(label_size)) check_number(label_size, "label_size", lower = 0)
  invisible(NULL)
}
