# Phase 6, step 2: renders of the new plot functions for the project lead's check-in (the
# images are not committed). Working tree (devtools::load_all()).
# Run from the repository root: Rscript <this file> <output directory>
out_dir <- commandArgs(TRUE)[1]
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
Sys.setlocale("LC_COLLATE", "C")
suppressMessages(devtools::load_all(quiet = TRUE))
quiet <- function(expr) suppressMessages(suppressWarnings(expr))
save_png <- function(plot, name, width = 1000, height = 650) {
  grDevices::png(file.path(out_dir, paste0(name, ".png")), width = width, height = height, res = 120)
  print(plot)
  grDevices::dev.off()
}

data(ExampleDataBinary)
data(ExampleDataLinear)
bin <- data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID, ExampleDataBinary$Z)
lin <- data.frame(y = ExampleDataLinear$Y, hospital = ExampleDataLinear$ProvID, ExampleDataLinear$Z)
f <- y ~ z1 + z2 + z3 + z4 + z5
logistic <- fit_logistic_fe(f, bin, "hospital")
linear <- fit_linear_fe(f, lin, "hospital")
singular_data <- withr::with_seed(1, {
  provider <- rep(seq_len(20), sample(5:15, 20, replace = TRUE))
  n <- length(provider)
  x1 <- stats::rnorm(n) + stats::rnorm(20, 0, 0.5)[provider]
  x2 <- stats::rnorm(n)
  x3 <- stats::rbinom(n, 1, 0.4)
  data.frame(y = 0.5 * x1 - 0.3 * x2 + 0.2 * x3 + stats::rnorm(n), hospital = provider, x1 = x1, x2 = x2, x3 = x3)
})
singular <- quiet(fit_linear_re(y ~ x1 + x2 + x3, singular_data, "hospital"))

logistic_profile <- profile_providers(logistic, interval = "exact")
linear_profile <- profile_providers(linear, interval = "wald")
save_png(plot_funnel(funnel_limits(logistic, level = c(0.95, 0.99))), "01_funnel_logistic")
save_png(plot_funnel(linear_profile), "02_funnel_linear")
save_png(plot_caterpillar(logistic_profile$measures, use_flag = TRUE), "03_caterpillar_logistic")
save_png(plot_caterpillar(standardize_providers(linear, interval = "wald", alternative = "greater"), use_flag = TRUE),
         "04_caterpillar_linear_greater")
save_png(plot_caterpillar(provider_effects(logistic, interval = "exact"), reference = 0, orientation = "horizontal",
                          use_flag = TRUE), "05_caterpillar_effects_horizontal", height = 1100)
save_png(plot_flags(logistic_profile), "06_flags_logistic")
save_png(plot_flags(quiet(profile_providers(singular))), "07_flags_singular_re")
save_png(plot_volume(logistic_profile), "08_volume_logistic", width = 1300)
save_png(plot_volume(standardize_providers(linear, c("indirect", "direct"), interval = "wald")), "09_volume_linear",
         width = 1300)
cat(paste(list.files(out_dir), collapse = "\n"), "\n")
