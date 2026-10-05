# Funnel plots from funnel_limits() or profile_providers() results.

# The help below states D-43 (awaiting sign-off) for linear FE fits with the full provider
# variance.
#' Funnel plot
#'
#' Plots each provider's indirectly standardized measure against its precision, with the
#' control limits and the target of [funnel_limits()], and the providers coloured by the flags
#' the funnel result carries, from the test at its first level.
#'
#' For logistic fixed-effect models, the points are the indirect ratios, the precision is
#' E_i^2 / V_i (the squared expected count over its null variance), the limits are those of
#' the score statistic around the target 1, and the flags come from the modified score test
#' (pprof 1.0.3's `plot()` of `logis_fe` fits). For linear fixed-effect models, the points are
#' the indirect differences, the precision is the provider's number of observations n_i, the
#' limits are target -/+ z sigma / sqrt(n_i) around the target 0, and the flags come from the
#' Wald test (`plot()` of `linear_fe` fits). With `provider_variance = "full"` the limits still
#' use sigma^2 / n_i while the Wald test uses the full variance and the t distribution, so a
#' point outside the limits may not be flagged, as in pprof 1.0.3. Random-effect models have
#' no funnel plot.
#'
#' Providers whose flag is missing are shown as "no flag". The plot is returned, not printed;
#' change its appearance with ggplot2's functions, for example
#' `+ ggplot2::scale_colour_manual(...)`.
#'
#' @param x A `pprof_funnel` result from [funnel_limits()], or a `pprof_profile` result from
#'   [profile_providers()] that has one.
#' @param point_size,point_alpha Size and opacity of the points.
#' @param line_width Width of the control limits and the target line.
#'
#' @return A ggplot object.
#' @seealso [funnel_limits()]
#' @family plots
#' @examples
#' data(ExampleDataBinary)
#' example <- data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID,
#'                       ExampleDataBinary$Z)
#' fit <- fit_logistic_fe(y ~ z1 + z2 + z3 + z4 + z5, example, provider = "hospital")
#' plot_funnel(funnel_limits(fit, level = c(0.95, 0.99)))
#' @export
plot_funnel <- function(x, point_size = 2, point_alpha = 0.8, line_width = 0.8) {
  plot_check_result(x, c("pprof_funnel", "pprof_profile"))
  plot_check_style(point_size = point_size, point_alpha = point_alpha, line_width = line_width)
  funnel <- if (inherits(x, "pprof_profile")) x$funnel else x
  if (is.null(funnel)) {
    abort_invalid_input("This profile has no funnel limits; its model does not support funnel plots.", arg = "x")
  }
  points <- funnel$providers
  points$flag <- plot_flag_factor(points$flag)
  limits <- funnel$table
  level <- factor(plot_level_text(limits$level), levels = plot_level_text(sort(unique(limits$level))))
  lines <- rbind(
    data.frame(precision = limits$precision, value = limits$upper, level = level, side = "upper"),
    data.frame(precision = limits$precision, value = limits$lower, level = level, side = "lower")
  )
  lines$group <- paste(lines$level, lines$side)
  ggplot2::ggplot() +
    ggplot2::geom_line(data = lines, ggplot2::aes(x = .data$precision, y = .data$value, group = .data$group,
                                                  linetype = .data$level), linewidth = line_width) +
    plot_reference_layer(funnel$target, vertical = TRUE, line_width = line_width, linetype = "longdash",
                         colour = "black") +
    ggplot2::geom_point(data = points, ggplot2::aes(x = .data$precision, y = .data$estimate, colour = .data$flag,
                                                    shape = .data$flag), size = point_size, alpha = point_alpha) +
    plot_flag_scales(points$flag) +
    ggplot2::labs(x = "Precision", y = plot_measure_label(funnel$measure, "indirect"), linetype = "Control limit",
                  title = "Funnel plot", subtitle = plot_subtitle(plot_test_subtitle(funnel$test, limits$level[1]))) +
    plot_theme()
}
