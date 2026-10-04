# The compatibility wrappers of pprof 1.0.3's plots (DEC-055): what they reproduce beyond the
# fixtures, their regression tests (D-36, D-47, D-48), and their classed errors.
local_strict_mode()

compat_plot_fit <- function() {
  data(ExampleDataBinary, package = "pprof", envir = environment())
  data <- data.frame(Y = ExampleDataBinary$Y, ProvID = ExampleDataBinary$ProvID, ExampleDataBinary$Z)
  suppressWarnings(logis_fe(data = data, Y.char = "Y", Z.char = paste0("z", 1:5), ProvID.char = "ProvID",
                            message = FALSE))
}

test_that("caterpillar_plot() and bar_plot() draw without ggplot2 warnings (D-36)", {
  fit <- compat_plot_fit()
  ci <- confint(fit, option = "SM", stdz = "indirect", measure = "ratio", test = "score")$CI.indirect_ratio
  # Vertical only: the horizontal plot keeps the reference's geom_errorbarh(), which ggplot2 4
  # deprecates (a warning in tests of pprof, not for users), because geom_errorbar() with
  # orientation = "y" builds different data (D-36).
  expect_no_warning(plot <- caterpillar_plot(ci, use_flag = TRUE))
  expect_no_warning(ggplot2::ggplot_build(plot))
  tests <- test(fit)
  expect_no_warning(plot <- bar_plot(tests))
  expect_no_warning(ggplot2::ggplot_build(plot))
})

test_that("the wrappers keep pprof 1.0.3's colours, which depend on the flags present (D-47)", {
  fit <- compat_plot_fit()
  colours <- c("#E69F00", "#56B4E9", "#009E73")
  less <- confint(fit, option = "SM", stdz = "indirect", measure = "ratio", test = "score",
                  alternative = "less")$CI.indirect_ratio
  plot <- caterpillar_plot(less, use_flag = TRUE)
  scale <- ggplot2::ggplot_build(plot)$plot$scales$get_scales("colour")
  expect_identical(scale$get_limits(), c("Lower", "Normal"))
  expect_identical(scale$map(c("Lower", "Normal")), colours[1:2])
  tests <- test(fit)
  tests$flag <- factor(rep(0, nrow(tests)))
  fill <- ggplot2::ggplot_build(bar_plot(tests))$plot$scales$get_scales("fill")
  expect_identical(fill$map(fill$get_limits()), "#66c2a5")
})

test_that("bar_plot()'s bar_width has no effect, as its help says (D-48)", {
  tests <- test(compat_plot_fit())
  expect_identical(ggplot2::layer_data(bar_plot(tests, bar_width = 0.2), 1), ggplot2::layer_data(bar_plot(tests), 1))
})

test_that("bar_plot()'s data are a data frame with the group index ggplot2 adds to dplyr's grouped data", {
  tests <- test(compat_plot_fit())
  data <- bar_plot(tests, group_num = 3)$data
  expect_identical(class(data), "data.frame")
  expect_identical(names(data), c("size", "category", "count", "value", ".group"))
  expect_identical(data$.group, as.integer(data$size))
  shares <- profile_flag_shares(tests$flag, attr(tests, "provider size"), 3)
  expect_identical(data$value, shares$share)
})

test_that("the wrappers raise classed errors where pprof 1.0.3 fails without a message of its own", {
  fit <- compat_plot_fit()
  ci <- confint(fit, option = "SM", stdz = "indirect", measure = "ratio", test = "score")$CI.indirect_ratio
  expect_error(caterpillar_plot(), class = "pprof_error_invalid_input")
  expect_error(caterpillar_plot(as.matrix(ci)), class = "pprof_error_invalid_input")
  expect_error(caterpillar_plot(tibble::as_tibble(ci)), class = "pprof_error_invalid_input")
  expect_error(caterpillar_plot(confint(fit, option = "gamma", test = "score")), class = "pprof_error_invalid_input")
  expect_error(caterpillar_plot(ci, orientation = "diagonal"), class = "pprof_error_invalid_input")
  unnamed <- ci
  attr(unnamed, "model") <- NULL
  expect_error(caterpillar_plot(unnamed), class = "pprof_error_invalid_input")
  no_reference <- ci
  attr(no_reference, "description") <- "Indirect Standardized Something"
  expect_error(caterpillar_plot(no_reference), class = "pprof_error_invalid_input")
  expect_s3_class(caterpillar_plot(no_reference, refline_value = 1), "ggplot")
  tests <- test(fit)
  expect_error(bar_plot(), class = "pprof_error_invalid_input")
  expect_error(bar_plot(as.matrix(tests)), class = "pprof_error_invalid_input")
  expect_error(bar_plot(tests, group_num = 60), class = "pprof_error_invalid_input")
  no_size <- tests
  attr(no_size, "provider size") <- NULL
  expect_error(bar_plot(no_size), class = "pprof_error_invalid_input")
})
