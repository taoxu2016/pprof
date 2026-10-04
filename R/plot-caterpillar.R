# Caterpillar plots from standardize_providers() or provider_effects() results with
# intervals.

#' Caterpillar plot
#'
#' Plots each provider's estimate with its interval, in order of the estimate, and a
#' reference line. For standardized measures the reference is 1 for ratios, the population
#' rate for rates, and 0 for differences; a provider whose interval lies above the reference
#' is flagged "higher" and one whose interval lies below it "lower" (a one-sided interval only
#' on the side tested), as pprof 1.0.3's `caterpillar_plot()` flags them. These flags compare
#' the intervals with the line; the flags of [test_providers()] come from the tests, and the
#' two can differ where an interval and the test use different distributions.
#'
#' A two-sided interval is drawn from its lower to its upper limit, an infinite limit to the
#' edge of the panel; a one-sided interval is drawn from its bound to the estimate, as in
#' `caterpillar_plot()`. Providers with equal estimates keep their order in `x`. The plot is
#' returned, not printed.
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
#' @param line_width Width of the intervals and the reference line.
#'
#' @return A ggplot object.
#' @seealso [standardize_providers()], [provider_effects()], [plot_funnel()]
#' @examples
#' data(ExampleDataBinary)
#' example <- data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID,
#'                       ExampleDataBinary$Z)
#' fit <- fit_logistic_fe(y ~ z1 + z2 + z3 + z4 + z5, example, provider = "hospital")
#' plot_caterpillar(standardize_providers(fit, measure = "ratio", interval = "wald"), use_flag = TRUE)
#' @export
plot_caterpillar <- function(x, standardization = NULL, measure = NULL, reference = NULL, orientation = "vertical",
                             use_flag = FALSE, point_size = 2, line_width = 0.6) {
  plot_check_result(x, c("pprof_measures", "pprof_provider_effects"))
  check_choice(orientation, c("vertical", "horizontal"), "orientation")
  check_flag(use_flag, "use_flag")
  plot_check_style(point_size = point_size, line_width = line_width)
  if (identical(x$interval, "none")) {
    abort_invalid_input("`x` has no intervals; compute it with `interval` set.", arg = "x")
  }
  data <- plot_caterpillar_data(x, standardization, measure, reference)
  alternative <- if (is.null(x$alternative)) "two.sided" else x$alternative
  table <- plot_interval_ends(data$table, alternative)
  has_reference <- !is.null(data$reference)
  if (has_reference) {
    table$flag <- plot_flag_factor(profile_interval_flags(table$lower, table$upper, data$reference, alternative))
  }
  table$provider_id <- stats::reorder(factor(table$provider_id, levels = unique(table$provider_id)), table$estimate)
  flagged <- use_flag && has_reference
  vertical <- identical(orientation, "vertical")
  plot <- if (vertical) {
    ggplot2::ggplot(table, ggplot2::aes(x = .data$provider_id, y = .data$estimate))
  } else {
    ggplot2::ggplot(table, ggplot2::aes(x = .data$estimate, y = .data$provider_id))
  }
  ranges <- if (vertical && flagged) {
    ggplot2::geom_linerange(ggplot2::aes(ymin = .data$from, ymax = .data$to, colour = .data$flag),
                            linewidth = line_width)
  } else if (vertical) {
    ggplot2::geom_linerange(ggplot2::aes(ymin = .data$from, ymax = .data$to), colour = "#94a3b8",
                            linewidth = line_width)
  } else if (flagged) {
    ggplot2::geom_linerange(ggplot2::aes(xmin = .data$from, xmax = .data$to, colour = .data$flag),
                            linewidth = line_width)
  } else {
    ggplot2::geom_linerange(ggplot2::aes(xmin = .data$from, xmax = .data$to), colour = "#94a3b8",
                            linewidth = line_width)
  }
  plot <- plot + ranges + ggplot2::geom_point(size = point_size, colour = "#475569")
  if (has_reference) plot <- plot + plot_reference_layer(data$reference, vertical, line_width)
  if (flagged) plot <- plot + plot_flag_scales(table$flag, "colour")
  subtitle <- plot_subtitle(plot_interval_subtitle(x$interval, x$level, alternative),
                            if (has_reference) paste("reference", format(signif(data$reference, 4))))
  hidden <- if (vertical) {
    ggplot2::theme(axis.text.x = ggplot2::element_blank(), axis.ticks.x = ggplot2::element_blank())
  } else {
    ggplot2::theme(axis.text.y = ggplot2::element_blank(), axis.ticks.y = ggplot2::element_blank())
  }
  plot +
    ggplot2::labs(x = if (vertical) "Provider" else data$label, y = if (vertical) data$label else "Provider",
                  title = "Caterpillar plot", subtitle = subtitle) +
    plot_theme() +
    hidden
}

# The rows to plot, their axis label, and the reference value (NULL when there is none).
plot_caterpillar_data <- function(x, standardization, measure, reference) {
  if (inherits(x, "pprof_provider_effects")) {
    if (!is.null(reference)) check_number(reference, "reference")
    return(list(table = x$table, label = "Provider effect", reference = reference))
  }
  if (is.null(standardization)) standardization <- x$standardization[1]
  if (is.null(measure)) measure <- x$measure[1]
  check_choice(standardization, x$standardization, "standardization")
  check_choice(measure, x$measure, "measure")
  table <- x$table[x$table$standardization == standardization & x$table$measure == measure, , drop = FALSE]
  if (is.null(reference)) reference <- profile_reference_value(measure, x$population_rate)
  check_number(reference, "reference")
  list(table = table, label = plot_measure_label(measure, standardization), reference = reference)
}
