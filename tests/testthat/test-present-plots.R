# Plots built from result objects (DEC-034, DEC-058, DEC-059): their layers carry the results'
# values, flags keep their colours whatever flags occur, and degenerate results draw.
local_strict_mode()

plot_example <- function() {
  data(ExampleDataBinary, package = "pprof", envir = environment())
  data <- data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID, ExampleDataBinary$Z)
  fit_logistic_fe(y ~ z1 + z2 + z3 + z4 + z5, data, "hospital")
}

plot_linear_example <- function() {
  data(ExampleDataLinear, package = "pprof", envir = environment())
  data <- data.frame(y = ExampleDataLinear$Y, hospital = ExampleDataLinear$ProvID, ExampleDataLinear$Z)
  fit_linear_fe(y ~ z1 + z2 + z3 + z4 + z5, data, "hospital")
}

# A linear RE fit whose provider variance lme4 estimates as 0, so that every test flag is
# missing (M-19): the data of the fixture dataset syn_singular_linear (dev/reference/datasets.R).
plot_singular_example <- function() {
  data <- withr::with_seed(1, {
    provider <- rep(seq_len(20), sample(5:15, 20, replace = TRUE))
    n <- length(provider)
    x1 <- stats::rnorm(n) + stats::rnorm(20, 0, 0.5)[provider]
    x2 <- stats::rnorm(n)
    x3 <- stats::rbinom(n, 1, 0.4)
    data.frame(y = 0.5 * x1 - 0.3 * x2 + 0.2 * x3 + stats::rnorm(n), hospital = provider, x1 = x1, x2 = x2, x3 = x3)
  })
  suppressMessages(fit_linear_re(y ~ x1 + x2 + x3, data, "hospital"))
}

layer_geoms <- function(plot) {
  vapply(plot$layers, function(layer) class(layer$geom)[1], character(1), USE.NAMES = FALSE)
}

# The colour (or fill) ggplot2 draws for each flag category of a built plot's layer.
built_colours <- function(plot, layer, column = "flag", aesthetic = "colour") {
  built <- ggplot2::layer_data(plot, layer)
  data <- if (is.data.frame(plot$layers[[layer]]$data)) plot$layers[[layer]]$data else plot$data
  unique(data.frame(category = as.character(data[[column]]), colour = built[[aesthetic]]))
}

expect_builds_quietly <- function(plot) {
  expect_no_warning(built <- ggplot2::ggplot_build(plot))
  expect_s3_class(built, "ggplot_built")
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
  expect_identical(points$precision, funnel$providers$precision)
  expect_identical(as.character(points$flag), c("lower", "as expected", "higher")[funnel$providers$flag + 2L])
  expect_identical(plot$layers[[2]]$data$yintercept, 1)
  expect_identical(plot_funnel(profile_providers(fit))$layers[[3]]$data,
                   plot_funnel(funnel_limits(fit))$layers[[3]]$data)
  expect_identical(plot$labels$subtitle, "Flags: score test at the 95% level, two-sided")
  expect_builds_quietly(plot)
  linear <- plot_funnel(funnel_limits(plot_linear_example()))
  expect_identical(linear$layers[[2]]$data$yintercept, 0)
  expect_identical(linear$labels$subtitle, "Flags: Wald test at the 95% level, two-sided")
  expect_builds_quietly(linear)
})

test_that("each flag has the same colour and shape in every plot, whatever flags occur (DEC-058, D-47)", {
  fit <- plot_example()
  colours <- c("lower" = "#E69F00", "as expected" = "#56B4E9", "higher" = "#009E73")
  for (level in c(0.95, 0.999999)) {
    plot <- plot_funnel(funnel_limits(fit, level = level))
    drawn <- built_colours(plot, 3)
    expect_identical(drawn$colour, unname(colours[drawn$category]))
  }
  only_expected <- plot_funnel(funnel_limits(fit, level = 0.999999))
  expect_identical(only_expected$scales$get_scales("colour")$get_labels(),
                   c("lower (0)", "as expected (100)", "higher (0)"))
  for (alternative in c("two.sided", "greater", "less")) {
    measures <- standardize_providers(fit, measure = "ratio", interval = "score", alternative = alternative)
    drawn <- built_colours(plot_caterpillar(measures, use_flag = TRUE), 1)
    expect_identical(drawn$colour, unname(colours[drawn$category]))
  }
})

test_that("plot_caterpillar() orders providers by estimate and flags intervals off the reference (K-112)", {
  fit <- plot_example()
  measures <- standardize_providers(fit, "indirect", c("ratio", "rate"), interval = "score")
  plot <- plot_caterpillar(measures, measure = "rate", use_flag = TRUE)
  expect_identical(layer_geoms(plot), c("GeomLinerange", "GeomPoint", "GeomHline"))
  expect_identical(plot$layers[[3]]$data$yintercept, measures$population_rate)
  data <- plot$data
  rates <- measures$table[measures$table$measure == "rate", ]
  expect_identical(data$estimate, rates$estimate)
  expect_identical(c(data$from, data$to), c(rates$lower, rates$upper))
  expected <- ifelse(data$upper < measures$population_rate, "lower",
                     ifelse(data$lower > measures$population_rate, "higher", "as expected"))
  expect_identical(as.character(data$flag), expected)
  expect_identical(levels(data$provider_id)[1], as.character(data$provider_id[which.min(data$estimate)]))
  expect_identical(plot$labels$subtitle, "Score intervals at the 95% level, two-sided; reference 38.77")
  expect_builds_quietly(plot)
  horizontal <- plot_caterpillar(measures, orientation = "horizontal", use_flag = TRUE)
  expect_identical(layer_geoms(horizontal), c("GeomLinerange", "GeomPoint", "GeomVline"))
  expect_builds_quietly(horizontal)
  effects <- plot_caterpillar(provider_effects(fit, "score"), orientation = "horizontal")
  expect_identical(layer_geoms(effects), c("GeomLinerange", "GeomPoint"))
  expect_null(effects$data$flag)
  expect_identical(layer_geoms(plot_caterpillar(provider_effects(fit, "score"), reference = -1)),
                   c("GeomLinerange", "GeomPoint", "GeomHline"))
  expect_builds_quietly(effects)
})

test_that("one-sided intervals run from their bound to the estimate and flag one side (K-112)", {
  fit <- plot_example()
  greater <- standardize_providers(fit, "indirect", "ratio", interval = "score", alternative = "greater")
  data <- plot_caterpillar(greater, use_flag = TRUE)$data
  expect_identical(data$from, greater$table$lower)
  expect_identical(data$to, greater$table$estimate)
  expect_false(any(data$flag == "lower"))
  less <- standardize_providers(fit, "indirect", "ratio", interval = "score", alternative = "less")
  data <- plot_caterpillar(less, use_flag = TRUE)$data
  expect_identical(data$from, less$table$estimate)
  expect_identical(data$to, less$table$upper)
  expect_false(any(data$flag == "higher"))
  linear <- standardize_providers(plot_linear_example(), interval = "wald", alternative = "greater")
  expect_true(all(linear$table$upper == Inf))
  expect_builds_quietly(plot_caterpillar(linear, use_flag = TRUE))
  # Infinite limits of two-sided intervals (exact intervals of providers without events).
  exact <- provider_effects(fit, interval = "exact")
  expect_true(any(!is.finite(c(exact$table$lower, exact$table$upper))))
  expect_builds_quietly(plot_caterpillar(exact, reference = 0, use_flag = TRUE))
})

test_that("providers with equal estimates keep their order in the caterpillar plot", {
  fit <- plot_example()
  measures <- standardize_providers(fit, "indirect", "ratio", interval = "score")
  measures$table$estimate <- rep(1, nrow(measures$table))
  expect_identical(levels(plot_caterpillar(measures)$data$provider_id), measures$table$provider_id)
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
  expected <- profile_flag_shares(tests$table$flag, tests$table$n_obs, 4)
  expect_identical(shares$share, expected$share)
  expect_identical(as.character(shares$category), as.character(expected$category))
  overall <- shares[shares$group == "Overall", ]
  expect_identical(overall$share[overall$category == "lower"], mean(tests$table$flag == -1L))
  labels <- ggplot2::get_guide_data(plot, "x")$.label
  size <- tests$table$n_obs
  quartile <- profile_size_groups(size, 4)
  expect_identical(labels[1], sprintf("Q1\n%d-%d", min(size[quartile == "Q1"]), max(size[quartile == "Q1"])))
  expect_identical(labels[5], sprintf("Overall\n%d-%d", min(size), max(size)))
  expect_identical(plot$labels$subtitle, "Flags: exact test at the 95% level, two-sided")
  expect_builds_quietly(plot)
  expect_builds_quietly(plot_flags(profile_providers(fit)))
})

test_that("plot_volume() draws the measures against volume, one panel each, with flags and intervals (DEC-059)", {
  fit <- plot_example()
  profile <- profile_providers(fit, interval = "score")
  plot <- plot_volume(profile)
  expect_identical(layer_geoms(plot), c("GeomLinerange", "GeomHline", "GeomPoint"))
  data <- plot$data
  expect_identical(levels(data$panel), c("Indirect standardized ratio", "Indirect standardized rate (%)"))
  expect_identical(data$estimate, profile$measures$table$estimate)
  expect_identical(data$n_obs, profile$measures$table$n_obs)
  flags <- profile$tests$table$flag[match(data$provider_id, profile$tests$table$provider_id)]
  expect_identical(as.character(data$flag), c("lower", "as expected", "higher")[flags + 2L])
  references <- plot$layers[[2]]$data
  expect_identical(references$reference, c(1, profile$measures$population_rate))
  expect_identical(plot$scales$get_scales("x")$get_transformation()$name, "log-10")
  expect_builds_quietly(plot)
  measures <- standardize_providers(fit, c("indirect", "direct"), "ratio")
  plain <- plot_volume(measures)
  expect_identical(layer_geoms(plain), c("GeomHline", "GeomPoint"))
  expect_identical(levels(plain$data$panel), c("Indirect standardized ratio", "Direct standardized ratio"))
  expect_null(plain$data$flag)
  expect_builds_quietly(plain)
  one <- plot_volume(profile, measure = "rate", use_flag = FALSE)
  expect_identical(levels(one$data$panel), "Indirect standardized rate (%)")
  expect_null(one$data$flag)
  linear <- plot_volume(profile_providers(plot_linear_example()))
  expect_identical(linear$layers[[1]]$data$reference, 0)
  expect_builds_quietly(linear)
})

test_that("results without flags draw them as 'no flag' (M-19)", {
  fit <- plot_singular_example()
  profile <- profile_providers(fit, interval = "wald")
  expect_true(all(is.na(profile$tests$table$flag)))
  flags <- plot_flags(profile)
  expect_identical(unique(as.character(flags$data$category)), "no flag")
  expect_identical(flags$data$share, rep(1, 5))
  expect_identical(unique(built_colours(flags, 1, "category", "fill")$colour), "#999999")
  expect_builds_quietly(flags)
  volume <- plot_volume(profile)
  expect_identical(levels(volume$data$flag), c("lower", "as expected", "higher", "no flag"))
  expect_builds_quietly(volume)
  expect_builds_quietly(plot_caterpillar(profile$measures, use_flag = TRUE))
})

test_that("the plot functions check their arguments", {
  fit <- plot_example()
  expect_error(plot_funnel(test_providers(fit)), class = "pprof_error_invalid_input")
  expect_error(plot_funnel(funnel_limits(fit), line_width = -1), class = "pprof_error_invalid_input")
  expect_error(plot_funnel(funnel_limits(fit), point_alpha = 2), class = "pprof_error_invalid_input")
  expect_error(plot_funnel(profile_providers(plot_singular_example())), class = "pprof_error_invalid_input")
  expect_error(plot_caterpillar(standardize_providers(fit)), class = "pprof_error_invalid_input")
  expect_error(plot_caterpillar(standardize_providers(fit, interval = "score"), measure = "difference"),
               class = "pprof_error_invalid_input")
  expect_error(plot_caterpillar(provider_effects(fit, "score"), orientation = "diagonal"),
               class = "pprof_error_invalid_input")
  expect_error(plot_flags(funnel_limits(fit)), class = "pprof_error_invalid_input")
  expect_error(plot_flags(test_providers(fit), group_count = 0), class = "pprof_error_invalid_input")
  expect_error(plot_flags(test_providers(fit), label_size = "big"), class = "pprof_error_invalid_input")
  tied <- test_providers(fit)
  tied$table$n_obs <- rep(50L, nrow(tied$table))
  expect_error(plot_flags(tied), class = "pprof_error_invalid_input")
  ids <- fit$providers$provider_id[fit$providers$included]
  expect_error(plot_flags(test_providers(fit, providers = ids[1])), class = "pprof_error_invalid_input")
  expect_error(plot_volume(test_providers(fit)), class = "pprof_error_invalid_input")
  expect_error(plot_volume(profile_providers(fit), measure = "difference"), class = "pprof_error_invalid_input")
  expect_error(plot_volume(profile_providers(fit), use_flag = NA), class = "pprof_error_invalid_input")
})
