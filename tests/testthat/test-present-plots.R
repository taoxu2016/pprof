# Plots built from result objects (DEC-034): their layers carry the results' values.
local_strict_mode()

plot_example <- function() {
  data(ExampleDataBinary, package = "pprof", envir = environment())
  data <- data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID, ExampleDataBinary$Z)
  fit_logistic_fe(y ~ z1 + z2 + z3 + z4 + z5, data, "hospital")
}

layer_geoms <- function(plot) {
  vapply(plot$layers, function(layer) class(layer$geom)[1], character(1), USE.NAMES = FALSE)
}

test_that("plot_funnel() draws the funnel's points, limits, and target", {
  fit <- plot_example()
  funnel <- funnel_limits(fit, level = c(0.95, 0.99))
  plot <- plot_funnel(funnel)
  expect_s3_class(plot, "ggplot")
  expect_identical(layer_geoms(plot), c("GeomLine", "GeomHline", "GeomPoint"))
  lines <- plot$layers[[1]]$data
  expect_identical(lines$value, c(funnel$table$upper, funnel$table$lower))
  expect_identical(lines$precision, rep(funnel$table$precision, 2))
  expect_identical(levels(lines$level), c("95%", "99%"))
  points <- plot$layers[[3]]$data
  expect_identical(points$estimate, funnel$providers$estimate)
  expect_identical(as.character(points$flag), c("lower", "as expected", "higher")[funnel$providers$flag + 2L])
  expect_identical(plot$layers[[2]]$data$yintercept, 1)
  expect_identical(plot_funnel(profile_providers(fit))$layers[[3]]$data,
                   plot_funnel(funnel_limits(fit))$layers[[3]]$data)
  expect_s3_class(ggplot2::ggplot_build(plot), "ggplot_built")
})

test_that("plot_caterpillar() orders providers by estimate and flags intervals off the reference (K-112)", {
  fit <- plot_example()
  measures <- standardize_providers(fit, "indirect", c("ratio", "rate"), interval = "score")
  plot <- plot_caterpillar(measures, measure = "rate", use_flag = TRUE)
  expect_identical(layer_geoms(plot), c("GeomLinerange", "GeomPoint", "GeomHline"))
  expect_identical(plot$layers[[3]]$data$yintercept, measures$population_rate)
  data <- plot$data
  expected <- ifelse(data$lower > measures$population_rate, "higher",
                     ifelse(data$upper < measures$population_rate, "lower", "as expected"))
  expect_identical(as.character(data$flag), expected)
  expect_identical(levels(data$provider_id)[1], data$provider_id[which.min(data$estimate)] |> as.character())
  greater <- standardize_providers(fit, "indirect", "ratio", interval = "score", alternative = "greater")
  flags <- plot_caterpillar(greater, use_flag = TRUE)$data$flag
  expect_false(any(flags == "lower"))
  effects <- plot_caterpillar(provider_effects(fit, "score"), orientation = "horizontal")
  expect_identical(layer_geoms(effects), c("GeomLinerange", "GeomPoint"))
  expect_identical(layer_geoms(plot_caterpillar(provider_effects(fit, "score"), reference = -1)),
                   c("GeomLinerange", "GeomPoint", "GeomHline"))
  expect_s3_class(ggplot2::ggplot_build(effects), "ggplot_built")
})

test_that("plot_flags() shows the share of each flag by size quartile and overall (K-113)", {
  fit <- plot_example()
  tests <- test_providers(fit)
  plot <- plot_flags(tests)
  expect_identical(layer_geoms(plot), c("GeomCol", "GeomText"))
  shares <- plot$data
  expect_identical(levels(shares$group), c("Q1", "Q2", "Q3", "Q4", "Overall"))
  totals <- tapply(shares$share, shares$group, sum)
  expect_equal(as.vector(totals), rep(1, 5), tolerance = 1e-12)
  overall <- shares[shares$group == "Overall", ]
  expect_identical(overall$share[overall$category == "lower"], mean(tests$table$flag == -1L))
  size <- tests$table$n_obs
  quartile <- cut(size, stats::quantile(size, (0:4) / 4), include.lowest = TRUE, labels = paste0("Q", 1:4))
  first <- shares[shares$group == "Q1", ]
  expect_identical(first$share[first$category == "as expected"], mean(tests$table$flag[quartile == "Q1"] == 0L))
  expect_s3_class(ggplot2::ggplot_build(plot_flags(profile_providers(fit))), "ggplot_built")
})

test_that("the plot functions check their arguments", {
  fit <- plot_example()
  expect_error(plot_funnel(test_providers(fit)), class = "pprof_error_invalid_input")
  expect_error(plot_caterpillar(standardize_providers(fit)), class = "pprof_error_invalid_input")
  expect_error(plot_caterpillar(standardize_providers(fit, interval = "score"), measure = "difference"),
               class = "pprof_error_invalid_input")
  expect_error(plot_caterpillar(provider_effects(fit, "score"), orientation = "diagonal"),
               class = "pprof_error_invalid_input")
  expect_error(plot_flags(funnel_limits(fit)), class = "pprof_error_invalid_input")
  expect_error(plot_flags(test_providers(fit), group_count = 0), class = "pprof_error_invalid_input")
  tied <- test_providers(fit)
  tied$table$n_obs <- rep(50L, nrow(tied$table))
  expect_error(plot_flags(tied), class = "pprof_error_invalid_input")
})
