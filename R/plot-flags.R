# Bar plots of flags by provider size, from test_providers() or profile_providers()
# results.

#' Flags by provider size
#'
#' The share of providers flagged higher than expected, as expected, and lower than
#' expected, in groups of providers by size and overall. Providers are grouped at the
#' quantiles of their sizes, `cut(n_obs, quantile(n_obs, (0:g) / g), include.lowest = TRUE)`
#' with g = `group_count`, as pprof 1.0.3's `bar_plot()` groups them; each group is labelled
#' with the range of its providers' sizes. Providers without a flag (a test statistic that is
#' not finite, for example for every provider of a random-effect model whose provider
#' variance is estimated as 0) are counted as "no flag". The plot is returned, not printed.
#'
#' @param x A `pprof_provider_tests` result from [test_providers()], or a `pprof_profile`
#'   result from [profile_providers()].
#' @param group_count The number of size groups.
#' @param label_size Size of the percentage labels.
#'
#' @return A ggplot object.
#' @seealso [test_providers()]
#' @family plots
#' @examples
#' data(ExampleDataBinary)
#' example <- data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID,
#'                       ExampleDataBinary$Z)
#' fit <- fit_logistic_fe(y ~ z1 + z2 + z3 + z4 + z5, example, provider = "hospital")
#' plot_flags(test_providers(fit))
#' @export
plot_flags <- function(x, group_count = 4, label_size = 4) {
  plot_check_result(x, c("pprof_provider_tests", "pprof_profile"))
  check_count(group_count, "group_count")
  plot_check_style(label_size = label_size)
  tests <- if (inherits(x, "pprof_profile")) x$tests else x
  table <- tests$table
  shares <- profile_flag_shares(table$flag, table$n_obs, group_count)
  categories <- c(rev(plot_flag_labels), if (anyNA(shares$category)) plot_no_flag)
  shares$category <- factor(ifelse(is.na(shares$category), plot_no_flag, as.character(shares$category)),
                            levels = categories)
  ggplot2::ggplot(shares, ggplot2::aes(x = .data$group, y = .data$share, fill = .data$category)) +
    ggplot2::geom_col(colour = "white", width = 0.7) +
    ggplot2::geom_text(ggplot2::aes(label = sprintf("%.1f%%", 100 * .data$share)),
                       position = ggplot2::position_stack(vjust = 0.5), size = label_size) +
    plot_flag_scales(shares$category, "fill", counts = FALSE) +
    ggplot2::scale_x_discrete(labels = plot_size_group_labels(table$n_obs, group_count), drop = FALSE) +
    ggplot2::scale_y_continuous(labels = function(value) sprintf("%.0f%%", 100 * value), limits = c(0, 1)) +
    ggplot2::labs(x = "Provider size", y = "Share of providers", title = "Flags by provider size",
                  subtitle = plot_subtitle(plot_test_subtitle(tests$test, tests$level, tests$alternative,
                                                              tests$score_type))) +
    plot_theme()
}

# Each size group's label with the range of its providers' sizes, for example "Q1\n12-45";
# "Overall" for all providers.
plot_size_group_labels <- function(n_obs, group_count) {
  group <- profile_size_groups(n_obs, group_count)
  labels <- vapply(levels(group), function(name) {
    sizes <- n_obs[group == name]
    if (length(sizes) == 0L) return(name)
    sprintf("%s\n%s-%s", name, format(min(sizes)), format(max(sizes)))
  }, character(1))
  c(labels, Overall = sprintf("Overall\n%s-%s", format(min(n_obs)), format(max(n_obs))))
}
