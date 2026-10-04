# Compatibility wrappers for the plots of pprof 1.0.3 (DEC-034, DEC-045, DEC-055): plot() of
# logis_fe and linear_fe fits, caterpillar_plot(), and bar_plot(). The plot data are built by
# the new code (the profiling API, the funnel limits of profile_funnel_limits() at the user's
# alpha, K-110 and K-111, and the interval flags and flag shares of K-112 and K-113) in the
# reference's layout, and drawn by the reference's ggplot code, so that every layer is the
# reference's. The reference's dplyr and magrittr calls are base R here, with the same rows,
# row names, column types, and factor levels.

#' Get funnel plot from a fitted `logis_fe` object for institutional comparisons
#'
#' Creates a funnel plot from a logistic fixed effect model to compare provider performance.
#' This is the interface of pprof 1.0.3, kept for existing code; see [plot_funnel()] and
#' [funnel_limits()] for the new interface.
#'
#' @param x a model fitted from \code{logis_fe}.
#' @param null a character string or a number specifying null hypotheses of fixed provider effects. The default is
#'   \code{"median"}.
#' @param test a character string specifying the type of testing methods to be conducted.
#'   The default and only supported value is "score"; `"exact"` raises an error.
#' @param target a numeric value representing the target outcome. The default value is 1.
#' @param alpha a number or a vector of significance levels. The default is 0.05.
#' @param labels a vector of labels for the plot.
#' @param point_colors a vector of colors representing different provider flags. The default is \code{c("#E69F00",
#'   "#56B4E9", "#009E73")}.
#' @param point_shapes a vector of shapes representing different provider flags. The default is \code{c(15, 17, 19)}.
#' @param point_size size of the points. The default is 2.
#' @param point_alpha transparency level of the points. The default is 0.8.
#' @param line_size size of all lines, including control limits and the target line. The default is 0.8.
#' @param target_line_type line type for the target line. The default is "longdash".
#' @param \dots additional arguments that can be passed to the function.
#'
#' @details
#' This function generates a funnel plot from a logistic fixed-effect model. Currently, it only supports the
#'   indirect standardized ratio.
#' The parameter `alpha` is a vector used to calculate control limits at different significance levels.
#' The first value in the vector is used as the significance level for flagging each provider, utilizing the
#'   \code{\link{test.logis_fe}} function.
#'
#' @seealso \code{\link{logis_fe}}, \code{\link{SM_output.linear_re}}, \code{\link{test.logis_fe}}
#'
#' @return A ggplot object representing the funnel plot.
#'
#' @examples
#' data(ExampleDataBinary)
#' outcome <- ExampleDataBinary$Y
#' covar <- ExampleDataBinary$Z
#' ProvID <- ExampleDataBinary$ProvID
#' fit_fe <- logis_fe(Y = outcome, Z = covar, ProvID = ProvID)
#' plot(fit_fe)
#'
#' @references
#' Wu, W., Kuriakose, J. P., Weng, W., Burney, R. E., & He, K. (2023). Test-specific funnel plots for healthcare
#'   provider profiling leveraging
#' individual- and summary-level information. \emph{Health Services and Outcomes Research Methodology},
#'   \strong{23(1)}, 45-58.
#' \cr
#'
#' @exportS3Method plot logis_fe
plot.logis_fe <- function(x, null = "median", test = "score", target = 1, alpha = 0.05,
                          labels = c("lower", "expected", "higher"),
                          point_colors = c("#E69F00", "#56B4E9", "#009E73"),
                          point_shapes = c(15, 17, 19),
                          point_size = 2, point_alpha = 0.8,
                          line_size = 0.8,
                          target_line_type = "longdash", ...) {
  compat_check_fit(x, missing(x), "x")
  if (!(is.character(test) && length(test) == 1L && test %in% c("exact", "score"))) {
    abort_invalid_input("Argument 'test' NOT as required!", arg = "test")
  }
  model <- compat_model_from_logis_fe(x)
  if (identical(test, "exact")) {
    # D-07: the reference's exact funnel limits call a function that does not exist.
    abort_unsupported_inference(model, "exact funnel limits")
  }
  null_value <- compat_null(null)
  measures <- standardize_providers(model, "indirect", "ratio", null = null_value)$table
  flags <- test.logis_fe(x, level = 1 - alpha[1], test = "score", null = null)
  funnel <- profile_spec(model)$funnel
  processed_data <- data.frame(indicator = measures$estimate,
                               Obs = compat_typed_sum(measures$observed, x$observation),
                               Exp = measures$expected, Var = measures$variance,
                               row.names = rownames(x$coefficient$gamma))
  processed_data$precision <- funnel$precision(processed_data$Exp, processed_data$Var)
  processed_data <- cbind(processed_data, flags)
  plot_data <- compat_funnel_data(processed_data, alpha, target, funnel)
  compat_funnel_plot(plot_data, target, alpha, labels, point_colors, point_shapes, point_size, point_alpha, line_size,
                     target_line_type)
}

# The data of the funnel plots of pprof 1.0.3 (K-110, K-111), as its dplyr code gives them:
# the providers in order of precision (ties in provider order), each repeated for every alpha
# in turn, with the control limits of profile_funnel_limits() at that alpha; the columns
# precision, indicator, Exp, flag, alpha (a factor), lower, and upper; automatic row names.
compat_funnel_data <- function(processed_data, alpha, target, funnel) {
  ordered <- processed_data[order(processed_data$precision), , drop = FALSE]
  rows <- rep(seq_len(nrow(ordered)), each = length(alpha))
  plot_data <- ordered[rows, c("precision", "indicator", "Exp", "flag"), drop = FALSE]
  rownames(plot_data) <- NULL
  plot_data$alpha <- rep(alpha, times = nrow(ordered))
  plot_data$lower <- NA_real_
  plot_data$upper <- NA_real_
  for (value in unique(alpha)) {
    rows <- plot_data$alpha == value
    limits <- profile_funnel_limits(plot_data$precision[rows], value, target, funnel)
    plot_data$lower[rows] <- limits$lower
    plot_data$upper[rows] <- limits$upper
  }
  plot_data$alpha <- factor(plot_data$alpha)
  plot_data
}

# The funnel points at the first alpha, renumbered, as dplyr::filter(alpha == alpha[1]) gives
# them in the reference's drawing code.
compat_first_alpha_rows <- function(plot_data) {
  rows <- plot_data[which(plot_data$alpha == plot_data$alpha[1]), , drop = FALSE]
  rownames(rows) <- NULL
  rows
}

# dplyr::bind_rows(data, extra) where `extra` has some of data's columns: the other columns of
# the extra rows are missing, of their column's type; automatic row names.
compat_bind_rows <- function(data, extra) {
  rows <- data[rep(NA_integer_, nrow(extra)), , drop = FALSE]
  for (column in names(extra)) rows[[column]][] <- extra[[column]]
  combined <- rbind(data, rows)
  rownames(combined) <- NULL
  combined
}

# The reference's funnel plot builder (R/plot.logis_fe.R:184-311 in pprof 1.0.3), unchanged
# except that its dplyr calls are compat_first_alpha_rows() and compat_bind_rows().
#' @importFrom stats setNames
#' @importFrom ggplot2 ggplot scale_x_continuous scale_y_continuous geom_point aes scale_shape_manual
#'   scale_color_manual scale_linetype_manual geom_line geom_hline guides guide_legend theme labs theme_classic
#'   element_text element_rect
#' @noRd
# The reference's code is kept unchanged (DEC-034), so it is not linted.
# nolint start
compat_funnel_plot <- function(plot_data,
                           target,
                           alpha,
                           labels,
                           point_colors,
                           point_shapes,
                           point_size,
                           point_alpha,
                           line_size,
                           target_line_type,
                           xlab = "Precision",
                           ylab = "Outcome",
                           legend_justification = c(1, 1),
                           legend_position = c(0.95, 0.95),
                           point_legend_title = "Flagging",
                           linetype_legend_title = "Ctrl Limit",
                           legend_title_size = 14,
                           legend_size = 14,
                           legend_box = "horizontal",
                           axis_title_size = 14,
                           axis_text_size = 14,
                           plot_title = "Funnel Plot",
                           plot_title_size = 18
) {

  # Check if plot_data is a data frame
  if (!is.data.frame(plot_data)) {
    stop("plot_data must be a data frame")
  }

  data <- compat_first_alpha_rows(plot_data)

  # Ensure that data$flag is a factor
  data$flag <- factor(data$flag, levels = c(-1, 0, 1))

  # Create labels for the legend
  labs_color <- paste0(labels, " (", table(data$flag), ")")

  # Add dummy rows for missing levels with NA values
  missing_levels <- setdiff(c(-1, 0, 1), unique(data$flag))
  if (length(missing_levels) > 0) {
    dummy_data <- data.frame(flag = factor(missing_levels, levels = c(-1, 0, 1)),
                             precision = NA,
                             indicator = NA)
    data <- compat_bind_rows(data, dummy_data)
  }

  num_levels <- length(levels(data$flag))

  # # Check if the length of shapes and color_palette is the same as the number of levels
  # if (length(color_palette) != num_levels) {
  #   stop("The length of color_palette must be the same as the number of levels in data$flag")
  # }
  #
  # # Check if the length of labels is the same as the number of levels
  # if (length(labels) != num_levels) {
  #   stop("The length of labels must be the same as the number of levels in data$flag")
  # }


  # Assign each level of data$flag to a color from the palette
  color_mapping <- setNames(point_colors, levels(data$flag))
  # Assign each level of data$flag to a shape
  shapes_mapping <- setNames(point_shapes, levels(data$flag))

  # Create a named vector of lables for the legend
  labels <- setNames(labels, levels(data$flag))


  xmax <- max(plot_data$precision)
  ymax <- max(max(plot_data$upper), max(plot_data$indicator))

  labs_linetype <- paste0((1 - alpha) * 100, "%")

  values_linetype <- c('solid', 'dashed', 'dotted', 'dotdash', 'longdash', 'twodash')[1:length(alpha)]

  values_linetype <- values_linetype[order(alpha)]
  labs_linetype <- labs_linetype[order(alpha)]

  plot <-
    ggplot() +
    scale_x_continuous(limits = c(0, xmax),
                       expand = c(1, 1)/50) +
    scale_y_continuous(breaks = round(seq(0, ymax, by=1), 1),
                       limits = c(0, ymax),
                       expand = c(1, 1)/50) +
    geom_point(data = data, aes(x = .data$precision, y = .data$indicator, shape = .data$flag, color = .data$flag), size = point_size, alpha = point_alpha) +
    scale_shape_manual(
      name = bquote(.(point_legend_title) ~ "(" * alpha == .(alpha[1]) * ")"),
      labels = labs_color,
      values = shapes_mapping
    ) +
    scale_color_manual(
      name = bquote(.(point_legend_title) ~ "(" * alpha == .(alpha[1]) * ")"),
      labels = labs_color,
      values = color_mapping
    ) +
    geom_line(data = plot_data, aes(x = .data$precision, y = .data$lower, group = alpha, linetype = alpha), linewidth = line_size) +
    geom_line(data = plot_data, aes(x = .data$precision, y = .data$upper, group = alpha, linetype = alpha), linewidth = line_size) +
    scale_linetype_manual(
      name =  linetype_legend_title,
      values = values_linetype,
      labels = labs_linetype
    ) +
    guides(shape = guide_legend(order = 1), color = guide_legend(order = 1), linetype = guide_legend(reverse = TRUE, order = 2)) +
    geom_hline(yintercept = target, linewidth = line_size, linetype = target_line_type) +
    theme_classic() +
    theme(
      legend.justification = legend_justification,
      legend.position = legend_position,
      legend.box = legend_box,
      legend.title = element_text(size = legend_title_size),
      legend.text = element_text(size = legend_size),
      axis.title = element_text(size = axis_title_size, margin = margin(t = 0, r = 0, b = 0, l = 0)),
      axis.text = element_text(size = axis_text_size),
      plot.title = element_text(hjust = 0.5, size = plot_title_size),
      text = element_text(size = 13),
      legend.background = element_rect(fill = "transparent", colour = NULL, linewidth = 0, linetype = "solid"),
    ) +
    labs(
      x = xlab,
      y = ylab,
      title = plot_title
    )


  return(plot)
}
# nolint end

#' Get funnel plot from a fitted `linear_fe` object for institutional comparisons
#'
#' Creates a funnel plot from a linear fixed effect model to compare provider performance.
#' This is the interface of pprof 1.0.3, kept for existing code; see [plot_funnel()] and
#' [funnel_limits()] for the new interface.
#'
#' @param x a model fitted from \code{linear_fe}.
#' @param null a character string or a number specifying null hypotheses of fixed provider effects. The default is
#'   \code{"median"}.
#' @param target a numeric value representing the target outcome. The default value is 0.
#' @param alpha a number or a vector of significance levels. The default is 0.05.
#' @param labels a vector of labels for the plot.
#' @param point_colors a vector of colors representing different provider flags. The default is \code{c("#E69F00",
#'   "#56B4E9", "#009E73")}.
#' @param point_shapes a vector of shapes representing different provider flags. The default is \code{c(15, 17, 19)}.
#' @param point_size size of the points. The default is 2.
#' @param point_alpha transparency level of the points. The default is 0.8.
#' @param line_size size of all lines, including control limits and the target line. The default is 0.8.
#' @param target_line_type line type for the target line. The default is "longdash".
#' @param \dots additional arguments that can be passed to the function.
#'
#' @details
#' This function generates a funnel plot from a linear fixed effect model. Currently, it only supports the indirect
#'   standardized difference.
#' The parameter `alpha` is a vector used to calculate control limits at different significance levels.
#' The first value in the vector is used as the significance level for flagging each provider, utilizing the
#'   \code{\link{test.linear_fe}} function.
#' The control limits are target -/+ qnorm(1 - alpha / 2) sigma / sqrt(n_i) whatever variance of the provider effects
#'   the fit used, while the flags of a fit with the full variance come from the t test of
#'   \code{\link{test.linear_fe}}, so that a provider outside the limits may not be flagged; this is as in pprof 1.0.3
#'   and awaiting a decision of the methodology owners.
#'
#' @seealso \code{\link{linear_fe}}, \code{\link{SM_output.linear_fe}}, \code{\link{test.linear_fe}}
#'
#' @return A ggplot object representing the funnel plot.
#'
#' @examples
#' data(ExampleDataLinear)
#' outcome <- ExampleDataLinear$Y
#' covar <- ExampleDataLinear$Z
#' ProvID <- ExampleDataLinear$ProvID
#' fit_fe <- linear_fe(Y = outcome, Z = covar, ProvID = ProvID)
#' plot(fit_fe)
#'
#' @exportS3Method plot linear_fe
plot.linear_fe <- function(x, null = "median", target = 0, alpha = 0.05,
                           labels = c("lower", "expected", "higher"),
                           point_colors = c("#E69F00", "#56B4E9", "#009E73"),
                           point_shapes = c(15, 17, 19),
                           point_size = 2, point_alpha = 0.8,
                           line_size = 0.8,
                           target_line_type = "longdash", ...) {
  compat_linear_fe_plot(x, null, target, alpha, labels, point_colors, point_shapes, point_size, point_alpha,
                        line_size, target_line_type)
}

# The funnel plot of pprof 1.0.3's plot.linear_fe() (DEC-034, DEC-045): the plot data are
# built from the new API (indirect differences, flags from the Wald test of test.linear_fe()
# at level 1 - alpha[1], and the limits of profile_funnel_limits() at each provider's size
# for every alpha, K-111), in the reference's layout, and drawn by the reference's ggplot
# code, so that every layer is the reference's. With the full provider variance the limits
# still use sigma^2 / n_i (D-43).
compat_linear_fe_plot <- function(x, null = "median", target = 0, alpha = 0.05,
                                  labels = c("lower", "expected", "higher"),
                                  point_colors = c("#E69F00", "#56B4E9", "#009E73"),
                                  point_shapes = c(15, 17, 19),
                                  point_size = 2, point_alpha = 0.8,
                                  line_size = 0.8,
                                  target_line_type = "longdash") {
  compat_check_object(x, missing(x), "x", "linear_fe")
  null_value <- compat_linear_null(null)
  model <- compat_model_from_linear_fe(x, require_variance_type = TRUE)
  ids <- compat_provider_labels(x)
  measures <- standardize_providers(model, "indirect", "difference", null = null_value)$table
  funnel <- profile_spec(model)$funnel
  processed_data <- data.frame(indicator = measures$estimate, Obs = measures$observed, Exp = measures$expected,
                               row.names = ids)
  processed_data$precision <- profile_funnel_precision(funnel, measures$expected, measures$variance,
                                                       stats::setNames(measures$n_obs, ids))
  flagging <- compat_linear_fe_test(x, level = 1 - alpha[1], null = null)
  processed_data <- cbind(processed_data, flagging)
  plot_data <- compat_funnel_data(processed_data, alpha, target, funnel)
  compat_funnel_plot_linear(plot_data, target, alpha, labels, point_colors, point_shapes, point_size, point_alpha,
                            line_size, target_line_type)
}

# The reference's funnel plot builder of linear fixed effects (R/plot.linear_fe.R:96-224 in
# pprof 1.0.3, ppfunnel_linear()), unchanged except that its dplyr calls are compat_first_alpha_rows()
# and compat_bind_rows().
#' @importFrom stats setNames
#' @importFrom ggplot2 ggplot scale_x_continuous scale_y_continuous geom_point aes scale_shape_manual
#'   scale_color_manual scale_linetype_manual geom_line geom_hline guides guide_legend theme labs theme_classic
#'   element_text element_rect margin
#' @noRd
# The reference's code is kept unchanged (DEC-034), so it is not linted.
# nolint start
compat_funnel_plot_linear <- function(plot_data,
                            target,
                            alpha,
                            labels,
                            point_colors,
                            point_shapes,
                            point_size,
                            point_alpha,
                            line_size,
                            target_line_type,
                            xlab = "Precision",
                            ylab = "Outcome",
                            legend_justification = "center",
                            legend_position = "right",
                            point_legend_title = "Flagging",
                            linetype_legend_title = "Ctrl Limit",
                            legend_title_size = 14,
                            legend_size = 14,
                            legend_box = "vertical",
                            axis_title_size = 14,
                            axis_text_size = 14,
                            plot_title = "Funnel Plot",
                            plot_title_size = 18
) {

  # Check if plot_data is a data frame
  if (!is.data.frame(plot_data)) {
    stop("plot_data must be a data frame")
  }

  data <- compat_first_alpha_rows(plot_data)

  # Ensure that data$flag is a factor
  data$flag <- factor(data$flag, levels = c(-1, 0, 1))

  # Create labels for the legend
  labs_color <- paste0(labels, " (", table(data$flag), ")")

  # Add dummy rows for missing levels with NA values
  missing_levels <- setdiff(c(-1, 0, 1), unique(data$flag))
  if (length(missing_levels) > 0) {
    dummy_data <- data.frame(flag = factor(missing_levels, levels = c(-1, 0, 1)),
                             precision = NA,
                             indicator = NA)
    data <- compat_bind_rows(data, dummy_data)
  }

  num_levels <- length(levels(data$flag))

  # # Check if the length of shapes and color_palette is the same as the number of levels
  # if (length(color_palette) != num_levels) {
  #   stop("The length of color_palette must be the same as the number of levels in data$flag")
  # }
  #
  # # Check if the length of labels is the same as the number of levels
  # if (length(labels) != num_levels) {
  #   stop("The length of labels must be the same as the number of levels in data$flag")
  # }


  # Assign each level of data$flag to a color from the palette
  color_mapping <- setNames(point_colors, levels(data$flag))
  # Assign each level of data$flag to a shape
  shapes_mapping <- setNames(point_shapes, levels(data$flag))

  # Create a named vector of lables for the legend
  labels <- setNames(labels, levels(data$flag))

  xmax <- max(plot_data$precision)
  xmin <- min(plot_data$precision)
  ymax <- max(max(plot_data$upper), max(plot_data$indicator))
  ymin <- min(min(plot_data$lower), min(plot_data$indicator))

  labs_linetype <- paste0((1 - alpha) * 100, "%")

  values_linetype <- c('solid', 'dashed', 'dotted', 'dotdash', 'longdash', 'twodash')[1:length(alpha)]

  values_linetype <- values_linetype[order(alpha)]
  labs_linetype <- labs_linetype[order(alpha)]

  plot <-
    ggplot() +
    scale_x_continuous(limits = c(xmin, xmax),
                       expand = c(1, 1)/50) +
    scale_y_continuous(breaks = round(seq(0, ymax, by=1), 1),
                       limits = c(ymin, ymax),
                       expand = c(1, 1)/50) +
    geom_point(data = data, aes(x = .data$precision, y = .data$indicator, shape = .data$flag, color = .data$flag), size = point_size, alpha = point_alpha) +
    scale_shape_manual(
      name = bquote(.(point_legend_title) ~ "(" * alpha == .(alpha[1]) * ")"),
      labels = labs_color,
      values = shapes_mapping
    ) +
    scale_color_manual(
      name = bquote(.(point_legend_title) ~ "(" * alpha == .(alpha[1]) * ")"),
      labels = labs_color,
      values = color_mapping
    ) +
    geom_line(data = plot_data, aes(x = .data$precision, y = .data$lower, group = alpha, linetype = alpha), linewidth = line_size) +
    geom_line(data = plot_data, aes(x = .data$precision, y = .data$upper, group = alpha, linetype = alpha), linewidth = line_size) +
    scale_linetype_manual(
      name =  linetype_legend_title,
      values = values_linetype,
      labels = labs_linetype
    ) +
    guides(shape = guide_legend(order = 1), color = guide_legend(order = 1), linetype = guide_legend(reverse = TRUE, order = 2)) +
    geom_hline(yintercept = target, linewidth = line_size, linetype = target_line_type) +
    theme_classic() +
    theme(
      legend.justification = legend_justification,
      legend.position = legend_position,
      legend.box = legend_box,
      legend.title = element_text(size = legend_title_size),
      legend.text = element_text(size = legend_size),
      axis.title = element_text(size = axis_title_size, margin = margin(t = 0, r = 0, b = 0, l = 0)),
      axis.text = element_text(size = axis_text_size),
      plot.title = element_text(hjust = 0.5, size = plot_title_size),
      text = element_text(size = 13),
      legend.background = element_rect(fill = "transparent", colour = NULL, linewidth = 0, linetype = "solid"),
    ) +
    labs(
      x = xlab,
      y = ylab,
      title = plot_title
    )


  return(plot)
}
# nolint end
