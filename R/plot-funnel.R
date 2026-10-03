# Funnel plots from funnel_limits() or profile_providers() results.

#' Funnel plot
#'
#' Plots each provider's indirectly standardized ratio against its precision, with the
#' control limits of [funnel_limits()] and the target line. Points are coloured by the flags
#' the funnel result carries (by default the modified score test at the first level).
#'
#' @param x A `pprof_funnel` result from [funnel_limits()], or a `pprof_profile` result from
#'   [profile_providers()] that has one.
#' @param point_size,point_alpha Size and opacity of the points.
#' @param line_size Width of the control-limit lines.
#'
#' @return A ggplot object.
#' @examples
#' data(ExampleDataBinary)
#' example <- data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID,
#'                       ExampleDataBinary$Z)
#' fit <- fit_logistic_fe(y ~ z1 + z2 + z3 + z4 + z5, example, provider = "hospital")
#' plot_funnel(funnel_limits(fit, level = c(0.95, 0.99)))
#' @export
plot_funnel <- function(x, point_size = 2, point_alpha = 0.8, line_size = 0.8) {
  plot_check_result(x, c("pprof_funnel", "pprof_profile"))
  funnel <- if (inherits(x, "pprof_profile")) x$funnel else x
  if (is.null(funnel)) {
    abort_invalid_input("This profile has no funnel limits; its model does not support funnel plots.", arg = "x")
  }
  points <- funnel$providers
  points$flag <- plot_flag_factor(points$flag)
  limits <- funnel$table
  level_labels <- sprintf("%s%%", format(100 * sort(unique(limits$level)), trim = TRUE))
  level <- factor(sprintf("%s%%", format(100 * limits$level, trim = TRUE)), levels = level_labels)
  lines <- rbind(
    data.frame(precision = limits$precision, value = limits$upper, level = level, side = "upper"),
    data.frame(precision = limits$precision, value = limits$lower, level = level, side = "lower")
  )
  lines$group <- paste(lines$level, lines$side)
  ggplot2::ggplot() +
    ggplot2::geom_line(data = lines, ggplot2::aes(x = .data$precision, y = .data$value, group = .data$group,
                                                  linetype = .data$level), linewidth = line_size) +
    ggplot2::geom_hline(yintercept = funnel$target, linetype = "longdash", linewidth = line_size) +
    ggplot2::geom_point(data = points, ggplot2::aes(x = .data$precision, y = .data$estimate, colour = .data$flag,
                                                    shape = .data$flag), size = point_size, alpha = point_alpha) +
    ggplot2::scale_colour_manual(values = stats::setNames(plot_flag_colors, plot_flag_labels),
                                 labels = plot_flag_legend(funnel$providers$flag), drop = FALSE, name = "Flag") +
    ggplot2::scale_shape_manual(values = stats::setNames(plot_flag_shapes, plot_flag_labels),
                                labels = plot_flag_legend(funnel$providers$flag), drop = FALSE, name = "Flag") +
    ggplot2::labs(x = "Precision", y = plot_measure_label(funnel$measure, "indirect"), linetype = "Control limit",
                  title = "Funnel plot") +
    plot_theme()
}
