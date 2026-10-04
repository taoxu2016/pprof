# Phase 6 planning: the reference's caterpillar_plot() and bar_plot() (pprof 1.0.3 in
# dev/reference/lib) on the outputs of every family, on one-sided intervals, and on
# degenerate inputs; what they put in the plot, the flag colours they draw, and run times.
# Run from the repository root: Rscript <this file> <output file>
.libPaths(c("dev/reference/lib", .Library))
Sys.setenv(OMP_THREAD_LIMIT = "1")
Sys.setlocale("LC_COLLATE", "C")
suppressPackageStartupMessages(library(pprof))
out_file <- commandArgs(TRUE)[1]
lines <- character()
say <- function(...) lines <<- c(lines, paste0(...))
quiet <- function(expr) suppressMessages(suppressWarnings(expr))
say("pprof ", as.character(packageVersion("pprof")), " from ", find.package("pprof"), "; ggplot2 ",
    as.character(packageVersion("ggplot2")), "; dplyr ", as.character(packageVersion("dplyr")), "; R ",
    R.version.string)

# Evaluate, keeping the value or the error message and the warnings.
run <- function(expr) {
  warnings <- character()
  value <- withCallingHandlers(
    tryCatch(expr, error = function(e) structure(list(message = conditionMessage(e)), class = "run_error")),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    },
    message = function(m) invokeRestart("muffleMessage")
  )
  list(value = value, warnings = unique(gsub("\n", " ", warnings)))
}
failed <- function(r) inherits(r$value, "run_error")
one_line <- function(x) paste(gsub("[[:space:]]+", " ", x), collapse = " | ")

# The colours a built plot gives to each flag value of its colour scale.
colour_map <- function(p) {
  built <- ggplot2::ggplot_build(p)
  scale <- built$plot$scales$get_scales("colour")
  if (is.null(scale)) return("no colour scale")
  limits <- scale$get_limits()
  paste(sprintf("%s=%s", limits, scale$map(limits)), collapse = ", ")
}

data(ExampleDataBinary)
data(ExampleDataLinear)
bin <- data.frame(Y = ExampleDataBinary$Y, ProvID = ExampleDataBinary$ProvID, ExampleDataBinary$Z)
lin <- data.frame(Y = ExampleDataLinear$Y, ProvID = ExampleDataLinear$ProvID, ExampleDataLinear$Z)
z <- paste0("z", 1:5)
fits <- list(
  logis_fe = quiet(logis_fe(data = bin, Y.char = "Y", Z.char = z, ProvID.char = "ProvID", message = FALSE)),
  linear_fe = quiet(linear_fe(data = lin, Y.char = "Y", Z.char = z, ProvID.char = "ProvID")),
  linear_re = quiet(linear_re(data = lin, Y.char = "Y", Z.char = z, ProvID.char = "ProvID")),
  logis_re = quiet(logis_re(data = bin, Y.char = "Y", Z.char = z, ProvID.char = "ProvID")),
  linear_cre = quiet(linear_cre(data = lin, Y.char = "Y", ProvID.char = "ProvID", wb.char = c("z1", "z2"),
                                other.char = c("z3", "z4", "z5"))),
  logis_cre = quiet(logis_cre(data = bin, Y.char = "Y", ProvID.char = "ProvID", wb.char = c("z1", "z2"),
                              other.char = c("z3", "z4", "z5")))
)

say("")
say("## 1. caterpillar_plot() on the confint(option = \"SM\") tables of every family")
say("Per table: attributes; non-finite limits; flags; outcome of the plot (vertical, use_flag = TRUE),",
    " its built colours by flag, and warnings while building.")
for (name in names(fits)) {
  fit <- fits[[name]]
  for (alternative in c("two.sided", "greater", "less")) {
    args <- list(fit, option = "SM", stdz = c("indirect", "direct"), alternative = alternative)
    if (name == "logis_fe") args$threads <- 1
    cis <- run(quiet(do.call(confint, args)))
    if (failed(cis)) {
      say(sprintf("%s %s: confint failed: %s", name, alternative, cis$value$message))
      next
    }
    for (element in names(cis$value)) {
      ci <- cis$value[[element]]
      if (!is.data.frame(ci)) next
      a <- attributes(ci)
      extra <- setdiff(names(a), c("names", "row.names", "class"))
      attr_text <- paste(sprintf("%s=%s", extra, vapply(extra, function(k) paste(format(a[[k]]), collapse = "|"), "")),
                         collapse = "; ")
      lims <- as.matrix(ci[, 2:3])
      p <- run(caterpillar_plot(ci, use_flag = TRUE))
      if (failed(p)) {
        say(sprintf("%s %s %s: [%s]; caterpillar_plot error: %s", name, alternative, element, attr_text,
                    p$value$message))
        next
      }
      built <- run(colour_map(p$value))
      flags <- table(p$value$data$flag, useNA = "ifany")
      say(sprintf("%s %s %s: [%s]; non-finite limits %d (Inf %d, -Inf %d); flags %s; colours %s; warnings: %s",
                  name, alternative, element, attr_text, sum(!is.finite(lims)), sum(lims == Inf),
                  sum(lims == -Inf), paste(names(flags), flags, sep = "=", collapse = ","),
                  if (failed(built)) paste("build error:", built$value$message) else built$value,
                  one_line(c(p$warnings, built$warnings))))
    }
  }
}

say("")
say("## 2. caterpillar_plot() details")
ci <- quiet(confint(fits$logis_fe, option = "SM", stdz = "indirect", measure = "ratio", threads = 1))$CI.indirect_ratio
p <- caterpillar_plot(ci)
say("plot data columns: ", paste(names(p$data), collapse = ", "), "; flag type ", class(p$data$flag),
    "; prov type ", class(p$data$prov))
say("layers: ", paste(vapply(p$layers, function(l) class(l$geom)[1], ""), collapse = ", "),
    "; errorbar params: ", paste(names(p$layers[[1]]$aes_params), collapse = ","), " / ",
    paste(names(p$layers[[1]]$geom_params), collapse = ","))
ph <- caterpillar_plot(ci, orientation = "horizontal")
say("horizontal layers: ", paste(vapply(ph$layers, function(l) class(l$geom)[1], ""), collapse = ", "),
    "; errorbar orientation param: ", format(ph$layers[[1]]$geom_params$orientation),
    "; width param: ", format(ph$layers[[1]]$geom_params$width))
one_sided <- quiet(confint(fits$logis_fe, option = "SM", stdz = "indirect", measure = "ratio", alternative = "greater",
                           threads = 1))$CI.indirect_ratio
pg <- caterpillar_plot(one_sided)
bg <- ggplot2::layer_data(pg, 1)
say("greater: the error bar of each provider runs from the lower limit to the estimate: ",
    isTRUE(all.equal(sort(bg$ymax), sort(one_sided[[1]]))), "; upper limits ", paste(unique(one_sided[[3]]), collapse = ","))
bad <- run(caterpillar_plot(ci, orientation = "diagonal"))
say("orientation = \"diagonal\": ", if (failed(bad)) bad$value$message else "no error")
gamma <- quiet(confint(fits$logis_fe, option = "gamma", test = "wald"))
r <- run(caterpillar_plot(gamma))
say("provider-effect table: ", if (failed(r)) r$value$message else "no error")
r <- run(caterpillar_plot(as.matrix(ci)))
say("a matrix: ", if (failed(r)) r$value$message else "no error")
ci_level <- quiet(confint(fits$logis_fe, option = "SM", stdz = "indirect", measure = "ratio", level = 0.5,
                          threads = 1))$CI.indirect_ratio
say("logis_fe ratio at level 0.5: flags ", paste(names(table(caterpillar_plot(ci_level)$data$flag)),
                                                table(caterpillar_plot(ci_level)$data$flag), collapse = ","),
    "; colours ", colour_map(caterpillar_plot(ci_level, use_flag = TRUE)))
ci_wide <- quiet(confint(fits$logis_re, option = "SM", stdz = "indirect", measure = "ratio"))$CI.indirect_ratio
say("logis_re ratio (no provider flagged?): flags ", paste(names(table(caterpillar_plot(ci_wide)$data$flag)),
                                                       table(caterpillar_plot(ci_wide)$data$flag), collapse = ","),
    "; colours ", colour_map(caterpillar_plot(ci_wide, use_flag = TRUE)))

say("")
say("## 3. bar_plot() on the test() results of every family")
describe_bar <- function(r) {
  if (failed(r)) return(paste("error:", r$value$message))
  p <- r$value
  d <- p$data
  sprintf("data class %s; columns %s; groups %s; %d rows; categories %s; warnings: %s",
          paste(class(d), collapse = "/"), paste(names(d), collapse = ","),
          paste(dplyr::group_vars(d), collapse = ","), nrow(d),
          paste(levels(d$category), collapse = "|"), one_line(r$warnings))
}
for (name in names(fits)) {
  tests <- quiet(test(fits[[name]]))
  say(sprintf("%s: %s", name, describe_bar(run(bar_plot(tests)))))
}
tests <- quiet(test(fits$logis_fe))
p <- bar_plot(tests)
d <- p$data
say("logis_fe data: ", paste(utils::capture.output(print(as.data.frame(d))), collapse = "\n"))
say("as.data.frame(p$data) columns: ", paste(names(as.data.frame(p$data)), collapse = ","),
    "; .group = group index of size: ", identical(as.data.frame(p$data)$.group, as.integer(d$size)))
say("layers: ", paste(vapply(p$layers, function(l) class(l$geom)[1], ""), collapse = ", "),
    "; bar stat ", class(p$layers[[1]]$stat)[1])

say("")
say("## 4. bar_plot() on degenerate inputs")
# test(parm = ) fails on this fit's integer IDs (D-27), so the subsets are taken by hand.
subset_tests <- function(rows) {
  out <- tests[rows, , drop = FALSE]
  attr(out, "provider size") <- attr(tests, "provider size")[rows]
  out
}
say("three providers: ", describe_bar(run(bar_plot(subset_tests(1:3)))))
say("one provider: ", describe_bar(run(bar_plot(subset_tests(1)))))
say("group_num = 1: ", describe_bar(run(bar_plot(tests, group_num = 1))))
say("group_num = 60: ", describe_bar(run(bar_plot(tests, group_num = 60))))
equal_sizes <- tests
attr(equal_sizes, "provider size") <- rep(50L, nrow(tests))
say("every provider of the same size: ", describe_bar(run(bar_plot(equal_sizes))))
none_flagged <- quiet(test(fits$logis_fe, level = 0.999999))
say("no provider flagged (level 0.999999): flags ", paste(names(table(none_flagged$flag)), table(none_flagged$flag),
                                                         collapse = ","), "; ", describe_bar(run(bar_plot(none_flagged))))

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
singular <- quiet(linear_re(data = singular_data(4L, FALSE), Y.char = "y", Z.char = c("x1", "x2", "x3"),
                            ProvID.char = "hospital"))
st <- quiet(test(singular))
say("singular linear_re fit (every flag missing): flag levels {", paste(levels(st$flag), collapse = ","), "}; ",
    describe_bar(run(bar_plot(st))))
r <- run(bar_plot(st))
if (!failed(r)) say("  its data: ", paste(utils::capture.output(print(as.data.frame(r$value$data))), collapse = "\n"),
                    "\n  build: ", one_line(run(ggplot2::ggplot_build(r$value))$warnings))
sci <- quiet(confint(singular, option = "SM"))$CI.indirect
r <- run(caterpillar_plot(sci, use_flag = TRUE))
say("singular linear_re fit, caterpillar: ", if (failed(r)) r$value$message else
      paste("flags", paste(names(table(r$value$data$flag, useNA = "ifany")), table(r$value$data$flag, useNA = "ifany"),
                           collapse = ","), "; widths 0:", all(sci[[2]] == sci[[3]])))

say("")
say("## 5. Run times of building the plot objects (not printing), seconds per call")
time_it <- function(f, reps = 20) {
  f()
  t <- system.time(for (k in seq_len(reps)) f())[["elapsed"]]
  signif(t / reps, 3)
}
ci_rate <- quiet(confint(fits$logis_fe, option = "SM", threads = 1))$CI.indirect_rate
say("caterpillar_plot (100 providers, use_flag): ", time_it(function() caterpillar_plot(ci_rate, use_flag = TRUE)))
say("bar_plot (100 providers): ", time_it(function() bar_plot(tests)))
say("plot.logis_fe (100 providers): ", time_it(function() quiet(plot(fits$logis_fe)), reps = 5))
writeLines(lines, out_file)
