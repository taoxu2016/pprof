# Caterpillar plots from standardize_providers() or provider_effects() results with
# intervals.

#' Caterpillar plot
#'
#' Plots each provider's estimate with its interval, in order of the estimate, and a
#' reference line. For standardized measures the reference is 1 for ratios, the population
#' rate for rates, and 0 for differences; providers whose interval lies above the reference
#' are flagged "higher" and those whose interval lies below it "lower" (for one-sided
#' intervals, only on the side tested), as pprof 1.0.3's `caterpillar_plot()` does.
#'
#' @param x A `pprof_measures` result from [standardize_providers()] or a
#'   `pprof_provider_effects` result from [provider_effects()], with an interval.
#' @param standardization,measure For measures: which standardization and measure to plot;
#'   the first in `x` by default.
#' @param reference The reference value; for provider effects, which have no default, the
#'   line and the flags are omitted unless it is given.
#' @param orientation `"vertical"` (providers along the x axis) or `"horizontal"`.
#' @param use_flag Whether to colour the intervals by flag.
#' @param point_size Size of the points.
#'
#' @return A ggplot object.
#' @examples
#' data(ExampleDataBinary)
#' example <- data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID,
#'                       ExampleDataBinary$Z)
#' fit <- fit_logistic_fe(y ~ z1 + z2 + z3 + z4 + z5, example, provider = "hospital")
#' plot_caterpillar(standardize_providers(fit, measure = "ratio", interval = "wald"), use_flag = TRUE)
#' @export
plot_caterpillar <- function(x, standardization = NULL, measure = NULL, reference = NULL, orientation = "vertical",
                             use_flag = FALSE, point_size = 2) {
  plot_check_result(x, c("pprof_measures", "pprof_provider_effects"))
  check_choice(orientation, c("vertical", "horizontal"), "orientation")
  check_flag(use_flag, "use_flag")
  if (identical(x$interval, "none")) {
    abort_invalid_input("`x` has no intervals; compute it with `interval` set.", arg = "x")
  }
  data <- plot_caterpillar_data(x, standardization, measure, reference)
  table <- data$table
  has_reference <- !is.na(data$reference)
  if (has_reference) {
    table$flag <- plot_flag_factor(plot_caterpillar_flags(table, data$reference, x$alternative))
  }
  table$provider_id <- stats::reorder(factor(table$provider_id), table$estimate)
  flagged <- use_flag && has_reference
  vertical <- identical(orientation, "vertical")
  plot <- if (vertical) {
    ggplot2::ggplot(table, ggplot2::aes(x = .data$provider_id, y = .data$estimate))
  } else {
    ggplot2::ggplot(table, ggplot2::aes(x = .data$estimate, y = .data$provider_id))
  }
  ranges <- if (vertical && flagged) {
    ggplot2::geom_linerange(ggplot2::aes(ymin = .data$lower, ymax = .data$upper, colour = .data$flag))
  } else if (vertical) {
    ggplot2::geom_linerange(ggplot2::aes(ymin = .data$lower, ymax = .data$upper), colour = "#94a3b8")
  } else if (flagged) {
    ggplot2::geom_linerange(ggplot2::aes(xmin = .data$lower, xmax = .data$upper, colour = .data$flag))
  } else {
    ggplot2::geom_linerange(ggplot2::aes(xmin = .data$lower, xmax = .data$upper), colour = "#94a3b8")
  }
  plot <- plot + ranges + ggplot2::geom_point(size = point_size, colour = "#475569")
  if (has_reference) {
    plot <- plot + if (vertical) {
      ggplot2::geom_hline(yintercept = data$reference, linetype = "dashed", colour = "#64748b")
    } else {
      ggplot2::geom_vline(xintercept = data$reference, linetype = "dashed", colour = "#64748b")
    }
  }
  if (flagged) {
    plot <- plot + ggplot2::scale_colour_manual(values = stats::setNames(plot_flag_colors, plot_flag_labels),
                                                drop = FALSE, name = NULL)
  }
  hidden <- if (vertical) {
    ggplot2::theme(axis.text.x = ggplot2::element_blank(), axis.ticks.x = ggplot2::element_blank())
  } else {
    ggplot2::theme(axis.text.y = ggplot2::element_blank(), axis.ticks.y = ggplot2::element_blank())
  }
  plot +
    ggplot2::labs(x = if (vertical) "Provider" else data$label, y = if (vertical) data$label else "Provider",
                  title = paste(data$label, "caterpillar plot")) +
    plot_theme() +
    hidden
}

# The rows to plot, their axis label, and the reference value.
plot_caterpillar_data <- function(x, standardization, measure, reference) {
  if (inherits(x, "pprof_provider_effects")) {
    if (!is.null(reference)) check_number(reference, "reference")
    return(list(table = x$table, label = "Provider effect",
                reference = if (is.null(reference)) NA_real_ else reference))
  }
  if (is.null(standardization)) standardization <- x$standardization[1]
  if (is.null(measure)) measure <- x$measure[1]
  check_choice(standardization, x$standardization, "standardization")
  check_choice(measure, x$measure, "measure")
  table <- x$table[x$table$standardization == standardization & x$table$measure == measure, , drop = FALSE]
  if (is.null(reference)) reference <- switch(measure, ratio = 1, rate = x$population_rate, difference = 0)
  check_number(reference, "reference")
  list(table = table, label = plot_measure_label(measure, standardization), reference = reference)
}

# K-112: higher when the interval lies above the reference, lower when it lies below; a
# one-sided interval flags only on its side.
plot_caterpillar_flags <- function(table, reference, alternative) {
  if (is.null(alternative)) alternative <- "two.sided"
  higher <- if (alternative == "less") rep(FALSE, nrow(table)) else table$lower > reference
  lower <- if (alternative == "greater") rep(FALSE, nrow(table)) else table$upper < reference
  ifelse(higher, 1L, ifelse(lower, -1L, 0L))
}
