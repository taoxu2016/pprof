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

#' Get a caterpillar plot to display confidence intervals for standardized measures
#'
#' Generate a caterpillar plot for standardized measures from different models using a provided CI dataframe.
#' This is the interface of pprof 1.0.3, kept for existing code; see [plot_caterpillar()] and
#' [standardize_providers()] for the new interface.
#'
#' @param CI a dataframe from `confint` function containing the standardized measure values, along with their
#'   confidence intervals lower and upper bounds.
#' @param point_size size of the points in the caterpillar plot. The default value is 2.
#' @param point_color color of the points in the plot. The default value is "#475569".
#' @param refline_value value of the horizontal reference line, for which the standardized measures are compared. The
#'   default value is NULL.
#' @param refline_color color of the reference line. The default value is "#64748b".
#' @param refline_size size of the reference line. The default value is 1.
#' @param refline_type line type for the reference line. The default value is "dashed".
#' @param errorbar_width the width of the error bars (horizontal ends of the CI bars). The default value is 0.
#' @param errorbar_size the thickness of the error bars. The default value is 0.5.
#' @param errorbar_alpha transparency level for the error bars. A value between 0 and 1, where 0 is completely
#'   transparent and 1 is fully opaque. The default value is 0.5.
#' @param errorbar_color color of the error bars. The default value is "#94a3b8".
#' @param use_flag logical; if \code{TRUE}, the error bars are colored to show providers' flags based on their
#'   performance. The default is \code{FALSE}.
#' @param orientation a string specifies the orientation of the caterpillar plot:
#'   \describe{
#'     \item{"vertical"}{(default) providers on the x-axis and values on the y-axis.}
#'     \item{"horizontal"}{providers on the y-axis and values on the x-axis.}
#'   }
#' @param flag_color vector of colors used for flagging providers when \code{use_flag = TRUE}. The default value is
#'   \code{c("#E69F00", "#56B4E9", "#009E73")}.
#'
#' @details
#' This function creates a caterpillar plot to visualize the standardized measures (indirect or direct).
#' The input `CI` must be a dataframe output from package `pprof`'s `confint` function.
#' Each provider's standardized measure value is represented as a point, and a reference line is shown at the value
#' specified by `refline_value` (default is NULL).
#' If `refline_value` is not specified, for linear FE or RE models with indirect or direct standardized differences,
#' it will be set to 0;
#' for logistic FE models with indirect or direct ratios, it will be set to 1;
#' and for logistic FE with indirect or direct rates, it will be set to the population rate, which represents the
#' average rate across all observations.
#'
#' Confidence intervals (CI) are displayed as error bars: for \code{alternative = "two.sided"}, two-sided confidence
#' intervals are shown;
#' for \code{alternative = "greater"}, error bars extend from the lower bound to the standardized measure values;
#' and for \code{alternative = "less"}, they extend from the standardized measure values to the upper bound.
#' One-sided intervals are drawn this way whatever their other limit is, which is infinite for the linear and
#' random-effect models and a finite bound for logistic fixed-effect models; the limits of two-sided intervals of
#' standardized measures are finite.
#'
#' When \code{use_flag = TRUE}, the plot will use colors specified by `flag_color` to show the flags of providers.
#' Each error bar will be colored to reflect the flag, making it easy to identify providers with different
#' performance levels. The colors go to the flags that occur, in the order "Higher", "Lower", "Normal": with all
#' three, "Higher" gets the first color, "Lower" the second, and "Normal" the third; when only some occur, the first
#' colors go to those.
#' When \code{use_flag = FALSE}, all error bars will have the same color, specified by `errorbar_color`.
#' This provides a simpler visualization without flagging individual providers.
#'
#' @return A ggplot object which is a caterpillar plot for the standardized measures.
#'
#' @examples
#' data(ExampleDataLinear)
#' outcome <- ExampleDataLinear$Y
#' covar <- ExampleDataLinear$Z
#' ProvID <- ExampleDataLinear$ProvID
#' fit_linear <- linear_fe(Y = outcome, Z = covar, ProvID = ProvID)
#' CI_linear <- confint(fit_linear)
#' caterpillar_plot(CI_linear$CI.indirect, use_flag = TRUE,
#'                  errorbar_width = 0.5, errorbar_size = 1)
#'
#' data(ExampleDataBinary)
#' fit_logis <- logis_fe(Y = ExampleDataBinary$Y,
#'                       Z = ExampleDataBinary$Z,
#'                       ProvID = ExampleDataBinary$ProvID, message = FALSE)
#' CI_logis <- confint(fit_logis)
#' caterpillar_plot(CI_logis$CI.indirect_ratio, use_flag = TRUE,
#'                  errorbar_width = 0.5, errorbar_size = 1,
#'                  orientation = "horizontal")
#'
#' @seealso \code{\link{confint.linear_fe}}, \code{\link{confint.linear_re}}, \code{\link{confint.logis_fe}}
#'
#' @importFrom stats reorder
#' @importFrom ggplot2 ggplot geom_errorbar aes scale_color_manual guide_legend geom_point geom_hline
#'   scale_x_discrete expansion theme theme_bw labs element_blank element_text element_rect margin geom_errorbarh
#'   geom_vline scale_y_discrete
#' @export
caterpillar_plot <- function(CI, point_size = 2, point_color = "#475569", # nolint: object_name_linter.
                             refline_value = NULL, refline_color = "#64748b", refline_size = 1, refline_type = "dashed",
                             errorbar_width = 0, errorbar_size = 0.5, errorbar_alpha = 0.5, errorbar_color = "#94a3b8",
                             use_flag = FALSE, orientation = "vertical",
                             flag_color = c("#E69F00", "#56B4E9", "#009E73")) {
  if (missing(CI)) abort_invalid_input("Argument 'CI' is required!", arg = "CI")
  data <- compat_caterpillar_table(CI, refline_value)
  if (!(is.character(orientation) && length(orientation) == 1L && orientation %in% c("vertical", "horizontal"))) {
    abort_invalid_input("Argument 'orientation' should be 'vertical' or 'horizontal'.", arg = "orientation")
  }
  compat_caterpillar_draw(data$table, point_size, point_color, data$reference, refline_color, refline_size,
                          refline_type, errorbar_width, errorbar_size, errorbar_alpha, errorbar_color, use_flag,
                          orientation, flag_color)
}

# The plot data of caterpillar_plot(): the interval table of an old confint() result (a data
# frame with the attributes `description`, `model`, and `type`) with its columns renamed `SM`,
# `Lower`, and `Upper`, the provider in `prov`, and the flag of each interval against the
# reference line in `flag` (K-112: "Higher", "Lower", or "Normal"), as pprof 1.0.3 builds it.
# The reference line is the user's, else 0 for linear models, 1 for ratios, and the population
# rate for rates of logistic models; the function returns the table and the reference. Inputs
# on which the reference fails without a message of its own raise classed errors.
compat_caterpillar_table <- function(ci, refline_value) {
  if (!identical(class(ci), "data.frame")) abort_invalid_input("Object CI should be a data frame!", arg = "CI")
  description <- compat_table_attribute(ci, "description")
  if (identical(description, "Provider Effects")) {
    abort_invalid_input("Caterpillar plot only supports standardized measure", arg = "CI")
  }
  if (ncol(ci) != 3L) abort_invalid_input("`CI` must have three columns: the measure and its limits.", arg = "CI")
  model <- compat_table_attribute(ci, "model")
  type <- compat_table_attribute(ci, "type")
  colnames(ci) <- c("SM", "Lower", "Upper")
  ci$prov <- rownames(ci)
  if (is.null(refline_value)) {
    refline_value <- if (model %in% c("FE linear", "RE linear", "CRE linear")) {
      0
    } else if (model %in% c("FE logis", "RE logis", "CRE logis") && grepl("Ratio", description)) {
      1
    } else if (model %in% c("FE logis", "RE logis", "CRE logis") && grepl("Rate", description)) {
      attr(ci, "population_rate")
    }
  }
  alternative <- switch(type, "two-sided" = "two.sided", "upper one-sided" = "greater", "lower one-sided" = "less",
                        NULL)
  if (!is.null(alternative)) {
    if (is.null(refline_value)) {
      abort_invalid_input("This table has no reference value for the flags; give `refline_value`.",
                          arg = "refline_value")
    }
    flags <- profile_interval_flags(ci$Lower, ci$Upper, refline_value, alternative)
    # Missing flags stay missing; as the reference's ifelse(), the column is logical when every
    # flag is missing.
    ci$flag <- ifelse(is.na(flags), NA, c("Lower", "Normal", "Higher")[flags + 2L])
  }
  list(table = ci, reference = refline_value)
}

# A string attribute of an old interval table, which caterpillar_plot() requires.
compat_table_attribute <- function(ci, name) {
  value <- attr(ci, name)
  if (!is.character(value) || length(value) != 1L || is.na(value)) {
    abort_invalid_input(sprintf("`CI` must have the \"%s\" attribute of a confint() table.", name), arg = "CI")
  }
  value
}

# The reference's caterpillar plot builder (R/caterpillar_plot.R:83-190 in pprof 1.0.3),
# unchanged except that guide_legend() no longer receives `box.linetype`, which ggplot2 4
# ignores with a warning (D-36).
# The reference's code is kept unchanged (DEC-055), so it is not linted.
# nolint start
compat_caterpillar_draw <- function(CI, point_size, point_color, refline_value, refline_color, refline_size,
                                    refline_type, errorbar_width, errorbar_size, errorbar_alpha, errorbar_color,
                                    use_flag, orientation, flag_color) {
  if (orientation == "vertical") {
    caterpillar_p <- ggplot(CI, aes(x = reorder(.data$prov, .data$SM), y = .data$SM))
    if (use_flag == TRUE) {
      caterpillar_p <- caterpillar_p +
        geom_errorbar(aes(ymin = if (attr(CI, "type") == "lower one-sided") .data$SM else .data$Lower,
                          ymax = if (attr(CI, "type") == "upper one-sided") .data$SM else .data$Upper,
                          color = .data$flag),
                      width = errorbar_width, linewidth = errorbar_size, alpha = errorbar_alpha) +
        scale_color_manual(values = flag_color, guide = guide_legend(title = NULL,
                                                                     override.aes = list(linewidth = 1.5)))

    } else {
      caterpillar_p <- caterpillar_p +
        geom_errorbar(aes(ymin = if (attr(CI, "type") == "lower one-sided") .data$SM else .data$Lower,
                          ymax = if (attr(CI, "type") == "upper one-sided") .data$SM else .data$Upper),
                      width = errorbar_width, linewidth = errorbar_size, alpha = errorbar_alpha, color = errorbar_color)
    }

    caterpillar_p <- caterpillar_p +
      geom_point(size = point_size, color = point_color) +
      geom_hline(aes(yintercept = refline_value),
                 color = refline_color, linetype = refline_type, linewidth = refline_size) +
      scale_x_discrete(expand = expansion(add = 5)) +
      labs(x = "Provider", y = attr(CI, "description"), title = paste(attr(CI, "description"), "Caterpillar Plot")) +
      theme_bw() +
      theme(
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        axis.text.x = element_blank(),
        axis.ticks.x = element_blank(),
        axis.title = element_text(size = 18, face = "bold"),
        axis.text = element_text(size = 15, face = "bold"),
        plot.title = element_text(size = 20, face = "bold"),
        legend.position = c(0.95, 0.05),
        legend.justification = c("right", "bottom"),
        legend.box.background = element_rect(color = "black", linewidth = 0.5),
        legend.box.margin = margin(5, 5, 5, 5),
        legend.text = element_text(size = 15, face = "bold")
      )
  }
  else if (orientation == "horizontal") {
    caterpillar_p <- ggplot(CI, aes(x = .data$SM, y = reorder(.data$prov, .data$SM)))

    if (use_flag) {
      caterpillar_p <- caterpillar_p +
        geom_errorbarh(aes(xmin = if (attr(CI, "type") == "lower one-sided") .data$SM else .data$Lower,
                           xmax = if (attr(CI, "type") == "upper one-sided") .data$SM else .data$Upper,
                           color = .data$flag),
                       height = errorbar_width, linewidth = errorbar_size, alpha = errorbar_alpha) +
        scale_color_manual(values = flag_color,
                           guide = guide_legend(title = NULL,
                                                override.aes = list(linewidth = 1.5)))
    } else {
      caterpillar_p <- caterpillar_p +
        geom_errorbarh(aes(xmin = if (attr(CI, "type") == "lower one-sided") .data$SM else .data$Lower,
                           xmax = if (attr(CI, "type") == "upper one-sided") .data$SM else .data$Upper),
                       height = errorbar_width, linewidth = errorbar_size, alpha = errorbar_alpha, color = errorbar_color)
    }
    caterpillar_p <- caterpillar_p +
      geom_point(aes(x = .data$SM), size = point_size, color = point_color) +
      geom_vline(aes(xintercept = refline_value),
                 color = refline_color, linetype  = refline_type, linewidth = refline_size) +
      scale_y_discrete(expand = expansion(add = 5)) +
      labs(x = attr(CI, "description"), y = "Provider", title = paste(attr(CI, "description"), "Caterpillar Plot")) +
      theme_bw() +
      theme(
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        axis.text.y = element_blank(),
        axis.ticks.y = element_blank(),
        axis.title = element_text(size = 18, face = "bold"),
        axis.text = element_text(size = 15, face = "bold"),
        plot.title = element_text(size = 20, face = "bold"),
        legend.position = c(0.95, 0.05),
        legend.justification = c("right", "bottom"),
        legend.box.background = element_rect(color = "black", linewidth = 0.5),
        legend.box.margin = margin(5, 5, 5, 5),
        legend.text = element_text(size = 15, face = "bold")
      )
  }
  else {
    stop("Argument 'orientation' should be 'vertical' or 'horizontal'.")
  }

  return(caterpillar_p)
}
# nolint end

#' Get a bar plot for flagging percentage overall and stratified by provider sizes
#'
#' Generate a bar plot for flagging percentage.
#' This is the interface of pprof 1.0.3, kept for existing code; see [plot_flags()] and
#' [test_providers()] for the new interface.
#'
#' @param flag_df a data frame from `test` function containing the flag of each provider.
#' @param group_num number of groups into which providers are divided based on their sample sizes. The default is 4.
#' @param bar_colors a vector of colors used to fill the bars representing the categories. The default is
#'   c("#66c2a5", "#fc8d62", "#8da0cb").
#' @param bar_width not used: the bars have width 0.7 whatever it is, as in pprof 1.0.3.
#' @param label_color color of the text labels inside the bars. The default is "black".
#' @param label_size size of the text labels inside the bars. The default is 4.
#'
#' @details
#' This function generates a bar chart to visualize the percentage of flagging results based on provider sizes.
#' The input data frame `flag_df` must be the output from package `pprof`'s `test` function.
#' Providers are grouped into a specified number of groups (`group_num`) based on their sample sizes, where
#' the number of providers are approximately equal across groups. An additional "overall" group is
#' included to show the flagging results across all providers. Providers without a flag are counted in a
#' category of their own.
#'
#' The colors of `bar_colors` go to the categories that occur, in the order "higher", "as expected", "lower": when
#' all three occur, "higher" gets the first color; when only some do, the first colors go to those.
#'
#' @return A ggplot object representing the bar chart of flagging results.
#'
#' @examples
#' data(ExampleDataLinear)
#' outcome <- ExampleDataLinear$Y
#' covar <- ExampleDataLinear$Z
#' ProvID <- ExampleDataLinear$ProvID
#' fit_linear <- linear_fe(Y = outcome, Z = covar, ProvID = ProvID)
#' test_linear <- test(fit_linear)
#' bar_plot(test_linear)
#'
#' data(ExampleDataBinary)
#' fit_logis <- logis_fe(Y = ExampleDataBinary$Y,
#'                       Z = ExampleDataBinary$Z,
#'                       ProvID = ExampleDataBinary$ProvID, message = FALSE)
#' test_logis <- test(fit_logis)
#' bar_plot(test_logis)
#'
#' @seealso \code{\link{test.linear_fe}}, \code{\link{test.linear_re}}, \code{\link{test.logis_fe}}
#'
#' @importFrom ggplot2 ggplot geom_bar geom_text labs aes theme scale_y_continuous scale_fill_manual element_text
#'   element_line element_blank theme_minimal position_stack
#' @importFrom scales percent percent_format
#' @export
bar_plot <- function(flag_df, group_num = 4,
                     bar_colors = c("#66c2a5", "#fc8d62", "#8da0cb"), bar_width = 0.7,
                     label_color = "black", label_size = 4) {
  if (missing(flag_df)) abort_invalid_input("Argument 'flag_df' is required!", arg = "flag_df")
  if (!identical(class(flag_df), "data.frame")) {
    abort_invalid_input("Object flag_df should be a data frame!", arg = "flag_df")
  }
  if (!"flag" %in% colnames(flag_df) || is.null(attr(flag_df, "provider size"))) {
    abort_invalid_input("Dataframe must contain a 'flag' column and an attribute 'provider size'.", arg = "flag_df")
  }
  compat_bar_draw(compat_bar_table(flag_df$flag, attr(flag_df, "provider size"), group_num), bar_colors,
                  label_color, label_size)
}

# The plot data of bar_plot(), as pprof 1.0.3's dplyr summary gives them to ggplot2: the
# share of each flag category in each provider-size group and overall (K-113), in columns
# `size`, `category`, `count`, and `value`, and the index of the size group among those that
# occur in `.group`, which ggplot2 adds to dplyr's grouped data.
compat_bar_table <- function(flag, size, group_num) {
  shares <- profile_flag_shares(flag, size, group_num)
  table <- data.frame(size = shares$group, category = shares$category, count = shares$count, value = shares$share)
  table$.group <- as.integer(droplevels(table$size))
  table
}

# The reference's bar plot builder (R/bar_plot.R:76-101 in pprof 1.0.3), unchanged except
# that element_line() takes `linewidth`, as ggplot2 asks since 3.4.0 (D-36).
# The reference's code is kept unchanged (DEC-055), so it is not linted.
# nolint start
compat_bar_draw <- function(df_long, bar_colors, label_color, label_size) {
  # Plot the bar chart
  p <- ggplot(df_long, aes(x = .data$size, y = .data$value, fill = .data$category)) +
    geom_bar(stat = "identity", color = "black", width = 0.7) +
    geom_text(aes(label = percent(.data$value, accuracy = 0.1)),
              position = position_stack(vjust = 0.5),
              color = label_color, size = label_size) +
    labs(x = "Provider Size",
         y = "Flagging Percentage",
         title = "Flagging Results Based on Provider Size",
         fill = "Category") +
    scale_y_continuous(labels = percent_format(accuracy = 1), limits = c(0, 1)) +
    theme_minimal() +
    scale_fill_manual(values = bar_colors) +
    theme(
      plot.title = element_text(hjust = 0.5, face = "bold", size = 16),
      axis.title.x = element_text(face = "bold", size = 14),
      axis.title.y = element_text(face = "bold", size = 14),
      axis.text = element_text(size = 12),
      legend.title = element_text(size = 14),
      legend.text = element_text(size = 12),
      panel.grid.major = element_line(linewidth = 0.5, linetype = 'solid', color = 'grey80'),
      panel.grid.minor = element_blank()
    )

  return(p)
}
# nolint end
