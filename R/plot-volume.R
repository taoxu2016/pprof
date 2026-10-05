# Volume panels (DEC-059): standardized measures against provider volume, from
# profile_providers() or standardize_providers() results.

#' Standardized measures by provider volume
#'
#' Plots each provider's standardized measure against its volume (its number of
#' observations, on a log scale), with one panel per standardization and measure, each with
#' its reference line: 1 for ratios, the population rate for rates, and 0 for differences.
#' For a [profile_providers()] result, the points are coloured by the flags of its tests; the
#' measures' intervals are drawn when the result has them, a one-sided interval from its
#' bound to the estimate. The plot draws the results as they are and computes nothing; it is
#' returned, not printed.
#'
#' @param x A `pprof_profile` result from [profile_providers()], or a `pprof_measures` result
#'   from [standardize_providers()] (then without flags).
#' @param standardization,measure The standardizations and measures to plot, one panel each;
#'   all of those in `x` by default.
#' @param use_flag Whether to colour the points by the flags of the profile's tests.
#' @param point_size,point_alpha Size and opacity of the points.
#' @param line_width Width of the intervals and the reference lines.
#'
#' @return A ggplot object.
#' @seealso [profile_providers()], [standardize_providers()]
#' @family plots
#' @examples
#' data(ExampleDataBinary)
#' example <- data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID,
#'                       ExampleDataBinary$Z)
#' fit <- fit_logistic_fe(y ~ z1 + z2 + z3 + z4 + z5, example, provider = "hospital")
#' plot_volume(profile_providers(fit, interval = "score"))
#' @export
plot_volume <- function(x, standardization = NULL, measure = NULL, use_flag = TRUE, point_size = 2, point_alpha = 0.8,
                        line_width = 0.5) {
  plot_check_result(x, c("pprof_profile", "pprof_measures"))
  check_flag(use_flag, "use_flag")
  plot_check_style(point_size = point_size, point_alpha = point_alpha, line_width = line_width)
  measures <- if (inherits(x, "pprof_profile")) x$measures else x
  tests <- if (inherits(x, "pprof_profile")) x$tests
  if (is.null(standardization)) standardization <- measures$standardization
  if (is.null(measure)) measure <- measures$measure
  check_choice(standardization, measures$standardization, "standardization", multiple = TRUE)
  check_choice(measure, measures$measure, "measure", multiple = TRUE)
  panels <- expand.grid(measure = measure, standardization = standardization, stringsAsFactors = FALSE)
  panels$label <- mapply(plot_measure_label, panels$measure, panels$standardization, USE.NAMES = FALSE)
  panels$reference <- vapply(panels$measure, function(m) {
    value <- profile_reference_value(m, measures$population_rate)
    if (is.null(value)) NA_real_ else value
  }, numeric(1))
  table <- measures$table[measures$table$standardization %in% standardization & measures$table$measure %in% measure, ,
                          drop = FALSE]
  key <- paste(table$standardization, table$measure)
  table$panel <- factor(panels$label[match(key, paste(panels$standardization, panels$measure))], levels = panels$label)
  panels$panel <- factor(panels$label, levels = panels$label)
  intervals <- !identical(measures$interval, "none")
  if (intervals) table <- plot_interval_ends(table, measures$alternative)
  flagged <- use_flag && !is.null(tests)
  if (flagged) {
    provider_flags <- plot_flag_factor(tests$table$flag)
    table$flag <- provider_flags[match(table$provider_id, tests$table$provider_id)]
  }
  plot <- ggplot2::ggplot(table, ggplot2::aes(x = .data$n_obs, y = .data$estimate))
  if (intervals) {
    plot <- plot + ggplot2::geom_linerange(ggplot2::aes(ymin = .data$from, ymax = .data$to), colour = "#94a3b8",
                                           linewidth = line_width)
  }
  plot <- plot + ggplot2::geom_hline(data = panels[!is.na(panels$reference), , drop = FALSE],
                                     ggplot2::aes(yintercept = .data$reference), linetype = "dashed",
                                     colour = "#64748b", linewidth = line_width)
  plot <- if (flagged) {
    plot + ggplot2::geom_point(ggplot2::aes(colour = .data$flag, shape = .data$flag), size = point_size,
                               alpha = point_alpha) +
      plot_flag_scales(provider_flags)
  } else {
    plot + ggplot2::geom_point(colour = "#475569", size = point_size, alpha = point_alpha)
  }
  subtitle <- plot_subtitle(
    if (flagged) plot_test_subtitle(tests$test, tests$level, tests$alternative, tests$score_type),
    if (intervals) plot_interval_subtitle(measures$interval, measures$level, measures$alternative)
  )
  plot +
    ggplot2::facet_wrap(ggplot2::vars(.data$panel), scales = "free_y") +
    ggplot2::scale_x_log10() +
    ggplot2::labs(x = "Provider volume (observations, log scale)", y = "Standardized measure",
                  title = "Standardized measures by provider volume", subtitle = subtitle) +
    plot_theme()
}
