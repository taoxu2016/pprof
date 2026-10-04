# Phase 6 planning: the new plot functions of the working tree (devtools::load_all()) on the
# results of every family and on degenerate inputs, and the facts the rewrite of the old plot
# paths depends on.
# Run from the repository root: Rscript <this file> <output file> [<png directory>]
args <- commandArgs(trailingOnly = TRUE)
out_file <- args[1]
png_dir <- if (length(args) > 1) args[2] else NULL
Sys.setlocale("LC_COLLATE", "C")
suppressMessages(devtools::load_all(quiet = TRUE))
lines <- character()
say <- function(...) lines <<- c(lines, paste0(...))
quiet <- function(expr) suppressMessages(suppressWarnings(expr))

run <- function(expr) {
  warnings <- character()
  value <- withCallingHandlers(
    tryCatch(expr, error = function(e) {
      structure(list(message = conditionMessage(e), class = class(e)[1]), class = "run_error")
    }),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    },
    message = function(m) invokeRestart("muffleMessage")
  )
  list(value = value, warnings = unique(gsub("[[:space:]]+", " ", warnings)))
}
failed <- function(r) inherits(r$value, "run_error")
# Build a plot and report the outcome of construction and of ggplot_build().
outcome <- function(expr) {
  made <- run(expr)
  if (failed(made)) return(sprintf("error %s: %s", made$value$class, made$value$message))
  built <- run(ggplot2::ggplot_build(made$value))
  if (failed(built)) return(sprintf("built with error %s: %s", built$value$class, built$value$message))
  sprintf("ok; %d layers; warnings: %s", length(made$value$layers),
          paste(c(made$warnings, built$warnings), collapse = " | "))
}

say("ggplot2 ", as.character(packageVersion("ggplot2")), "; identical(ggplot2::.data, rlang::.data): ",
    identical(ggplot2::.data, rlang::.data))

data(ExampleDataLinear)
data(ExampleDataBinary)
lin <- data.frame(y = ExampleDataLinear$Y, hospital = ExampleDataLinear$ProvID, ExampleDataLinear$Z)
bin <- data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID, ExampleDataBinary$Z)
f <- y ~ z1 + z2 + z3 + z4 + z5
fits <- list(
  logistic_fe = fit_logistic_fe(f, bin, "hospital"),
  linear_fe = fit_linear_fe(f, lin, "hospital"),
  linear_re = quiet(fit_linear_re(f, lin, "hospital")),
  logistic_re = quiet(fit_logistic_re(f, bin, "hospital")),
  linear_cre = quiet(fit_linear_cre(f, lin, "hospital", within_between = c("z1", "z2"))),
  logistic_cre = quiet(fit_logistic_cre(f, bin, "hospital", within_between = c("z1", "z2")))
)

say("")
say("## 1. The new plot functions on every family")
for (name in names(fits)) {
  fit <- fits[[name]]
  profile <- quiet(profile_providers(fit, interval = "wald"))
  say(sprintf("%s: plot_funnel %s", name, outcome(plot_funnel(profile))))
  say(sprintf("%s: plot_flags %s", name, outcome(plot_flags(profile))))
  say(sprintf("%s: plot_caterpillar(measures) %s", name, outcome(plot_caterpillar(profile$measures, use_flag = TRUE))))
  say(sprintf("%s: plot_caterpillar(effects) %s", name, outcome(plot_caterpillar(profile$effects))))
}

say("")
say("## 2. Degenerate inputs")
ids <- fits$logistic_fe$providers$provider_id[fits$logistic_fe$providers$included]
say("plot_flags, one provider: ", outcome(plot_flags(test_providers(fits$logistic_fe, providers = ids[1]))))
say("plot_flags, three providers: ", outcome(plot_flags(test_providers(fits$logistic_fe, providers = ids[1:3]))))
say("plot_flags, group_count = 60: ", outcome(plot_flags(test_providers(fits$logistic_fe), group_count = 60)))
none <- test_providers(fits$logistic_fe, level = 0.999999)
say("plot_flags, (almost) no provider flagged: flags ", paste(names(table(none$table$flag)), table(none$table$flag),
                                                             collapse = ","), "; ", outcome(plot_flags(none)))
funnel_none <- funnel_limits(fits$logistic_fe, level = 0.999999)
say("plot_funnel at level 0.999999: flags ", paste(names(table(funnel_none$providers$flag)),
                                                   table(funnel_none$providers$flag), collapse = ","), "; ",
    outcome(plot_funnel(funnel_none)))
one_sided <- standardize_providers(fits$linear_fe, interval = "wald", alternative = "greater")
say("plot_caterpillar, linear FE one-sided (upper limits Inf: ", sum(one_sided$table$upper == Inf), "): ",
    outcome(plot_caterpillar(one_sided, use_flag = TRUE)))
exact_effects <- provider_effects(fits$logistic_fe, interval = "exact")
say("plot_caterpillar, logistic FE exact effects (infinite limits: ", sum(!is.finite(c(exact_effects$table$lower,
                                                                                       exact_effects$table$upper))),
    "): ", outcome(plot_caterpillar(exact_effects, reference = 0, use_flag = TRUE)))
rates <- standardize_providers(fits$logistic_fe, measure = "rate", interval = "exact")
rate_rows <- rates$table
say("plot_caterpillar, logistic FE exact rates (lower limits at 0: ", sum(rate_rows$lower == 0), ", upper at 100: ",
    sum(rate_rows$upper == 100), "): ", outcome(plot_caterpillar(rates, use_flag = TRUE)))

singular_data <- function(seed, logistic) {
  withr::with_seed(seed, {
    m <- 50
    provider <- rep(seq_len(m), sample(if (logistic) 30:150 else 10:60, m, replace = TRUE))
    n <- length(provider)
    x1 <- stats::rnorm(n) + stats::rnorm(m, 0, 0.5)[provider]
    x2 <- stats::rnorm(n)
    x3 <- stats::rbinom(n, 1, 0.4)
    eta <- 0.5 * x1 - 0.3 * x2 + 0.2 * x3
    y <- if (logistic) stats::rbinom(n, 1, stats::plogis(-1 + eta)) else eta + stats::rnorm(n)
    data.frame(y = y, hospital = provider, x1 = x1, x2 = x2, x3 = x3)
  })
}
singular <- quiet(fit_linear_re(y ~ x1 + x2 + x3, singular_data(4L, FALSE), "hospital"))
singular_profile <- quiet(profile_providers(singular, interval = "wald"))
say("singular linear RE fit: missing flags ", sum(is.na(singular_profile$tests$table$flag)), " of ",
    nrow(singular_profile$tests$table), "; plot_flags ", outcome(plot_flags(singular_profile)))
say("singular linear RE fit: plot_caterpillar ", outcome(plot_caterpillar(singular_profile$measures, use_flag = TRUE)))

say("")
say("## 3. The funnel wrappers' intermediate data (what a base-R rewrite must reproduce)")
old <- quiet(logis_fe(data = data.frame(Y = ExampleDataBinary$Y, ProvID = ExampleDataBinary$ProvID,
                                        ExampleDataBinary$Z), Y.char = "Y", Z.char = paste0("z", 1:5),
                      ProvID.char = "ProvID", message = FALSE))
p <- quiet(plot(old, alpha = c(0.05, 0.01)))
for (k in seq_along(p$layers)) {
  d <- p$layers[[k]]$data
  say(sprintf("plot.logis_fe layer %d (%s): class %s; %d rows; row names %s; alpha levels %s; flag levels %s",
              k, class(p$layers[[k]]$geom)[1], paste(class(d), collapse = "/"), nrow(d),
              paste(utils::capture.output(dput(.row_names_info(d, type = 0L))), collapse = ""),
              paste(levels(d$alpha), collapse = ","), paste(levels(d$flag), collapse = ",")))
}

say("")
say("## 4. Uses of tidyverse helpers in R/")
for (file in list.files("R", pattern = "[.]R$", full.names = TRUE)) {
  code <- readLines(file, warn = FALSE)
  hits <- c(data = sum(grepl(".data$", code, fixed = TRUE)), pipe = sum(grepl("%>%", code, fixed = TRUE)),
            dplyr = sum(grepl("importFrom dplyr|dplyr::|arrange\\(|cross_join\\(|bind_rows\\(|group_by\\(", code)),
            tidyselect = sum(grepl("tidyselect", code, fixed = TRUE)), scales = sum(grepl("percent", code, fixed = TRUE)))
  if (any(hits > 0)) say(basename(file), ": ", paste(names(hits), hits, sep = " ", collapse = ", "))
}

if (!is.null(png_dir)) {
  dir.create(png_dir, showWarnings = FALSE, recursive = TRUE)
  save_png <- function(plot, name) {
    grDevices::png(file.path(png_dir, paste0(name, ".png")), width = 900, height = 600, res = 110)
    print(plot)
    grDevices::dev.off()
  }
  profile <- quiet(profile_providers(fits$logistic_fe, interval = "exact"))
  save_png(plot_funnel(profile), "new_funnel_logistic")
  save_png(plot_caterpillar(profile$measures, use_flag = TRUE), "new_caterpillar_logistic")
  save_png(plot_flags(profile), "new_flags_logistic")
  save_png(plot_funnel(quiet(profile_providers(fits$linear_fe))), "new_funnel_linear")
  save_png(quiet(plot(old)), "old_funnel_logistic")
  save_png(quiet(caterpillar_plot(confint(old, option = "SM", stdz = "indirect", measure = "ratio")$CI.indirect_ratio,
                                  use_flag = TRUE)), "old_caterpillar_logistic")
  save_png(quiet(bar_plot(test(old))), "old_bar_logistic")
}
writeLines(lines, out_file)
