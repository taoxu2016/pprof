# Bar plots of flags by provider size, from test_providers() or profile_providers()
# results.

#' Flags by provider size
#'
#' The share of providers flagged higher than expected, as expected, and lower than
#' expected, in groups of providers by size and overall. Providers are grouped at the
#' quantiles of their sizes, `cut(n_obs, quantile(n_obs, (0:g) / g), include.lowest = TRUE)`
#' with g = `group_count`, as pprof 1.0.3's `bar_plot()` groups them (K-113). Providers
#' without a flag (a test statistic that is not finite) are left out.
#'
#' @param x A `pprof_provider_tests` result from [test_providers()], or a `pprof_profile`
#'   result from [profile_providers()].
#' @param group_count The number of size groups.
#' @param label_size Size of the percentage labels.
#'
#' @return A ggplot object.
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
  table <- if (inherits(x, "pprof_profile")) x$tests$table else x$table
  table <- table[!is.na(table$flag), , drop = FALSE]
  shares <- plot_flag_shares(table$flag, table$n_obs, group_count)
  ggplot2::ggplot(shares, ggplot2::aes(x = .data$group, y = .data$share, fill = .data$category)) +
    ggplot2::geom_col(colour = "black", width = 0.7) +
    ggplot2::geom_text(ggplot2::aes(label = sprintf("%.1f%%", 100 * .data$share)),
                       position = ggplot2::position_stack(vjust = 0.5), size = label_size) +
    ggplot2::scale_fill_manual(values = stats::setNames(rev(plot_flag_colors), rev(plot_flag_labels)),
                               drop = FALSE) +
    ggplot2::scale_y_continuous(labels = function(value) sprintf("%.0f%%", 100 * value), limits = c(0, 1)) +
    ggplot2::labs(x = "Provider size", y = "Share of providers", fill = "Flag", title = "Flags by provider size") +
    plot_theme()
}

# The share of each flag category among the providers of each size group and overall.
plot_flag_shares <- function(flag, size, group_count) {
  breaks <- stats::quantile(size, probs = (0:group_count) / group_count, names = FALSE)
  if (anyDuplicated(breaks) > 0L) {
    abort_invalid_input(sprintf("The provider sizes do not split into %d groups; use a smaller `group_count`.",
                                group_count), arg = "group_count")
  }
  groups <- paste0("Q", seq_len(group_count))
  group <- cut(size, breaks = breaks, include.lowest = TRUE, labels = groups)
  category <- factor(flag, levels = rev(plot_flag_values), labels = rev(plot_flag_labels))
  counts <- rbind(as.data.frame(table(group = group, category = category)),
                  as.data.frame(table(group = rep("Overall", length(flag)), category = category)))
  counts$group <- factor(counts$group, levels = c(groups, "Overall"))
  counts$share <- counts$Freq / stats::ave(counts$Freq, counts$group, FUN = sum)
  counts[counts$Freq > 0, c("group", "category", "share")]
}
