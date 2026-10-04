# Phase 6 planning: do the reference caterpillar plot's flags (interval against the reference
# line, K-112) agree with the flags of the provider tests (K-63)? Reference library.
# Run from the repository root: Rscript <this file> <output file>
.libPaths(c("dev/reference/lib", .Library))
Sys.setenv(OMP_THREAD_LIMIT = "1")
Sys.setlocale("LC_COLLATE", "C")
suppressPackageStartupMessages(library(pprof))
out_file <- commandArgs(TRUE)[1]
lines <- character()
say <- function(...) lines <<- c(lines, paste0(...))
quiet <- function(expr) suppressMessages(suppressWarnings(expr))
label <- c("-1" = "Lower", "0" = "Normal", "1" = "Higher")

data(ExampleDataBinary)
data(ExampleDataLinear)
bin <- data.frame(Y = ExampleDataBinary$Y, ProvID = ExampleDataBinary$ProvID, ExampleDataBinary$Z)
lin <- data.frame(Y = ExampleDataLinear$Y, ProvID = ExampleDataLinear$ProvID, ExampleDataLinear$Z)
z <- paste0("z", 1:5)
fits <- list(
  logis_fe = quiet(logis_fe(data = bin, Y.char = "Y", Z.char = z, ProvID.char = "ProvID", message = FALSE)),
  linear_fe = quiet(linear_fe(data = lin, Y.char = "Y", Z.char = z, ProvID.char = "ProvID")),
  linear_fe_full = quiet(linear_fe(data = lin, Y.char = "Y", Z.char = z, ProvID.char = "ProvID",
                                   option.gamma.var = "full")),
  linear_re = quiet(linear_re(data = lin, Y.char = "Y", Z.char = z, ProvID.char = "ProvID")),
  logis_re = quiet(logis_re(data = bin, Y.char = "Y", Z.char = z, ProvID.char = "ProvID"))
)
compare <- function(name, test_args, ci_args, element) {
  fit <- fits[[name]]
  tests <- quiet(do.call(test, c(list(fit), test_args)))
  ci <- quiet(do.call(confint, c(list(fit, option = "SM", stdz = "indirect"), ci_args)))[[element]]
  plot_flags <- caterpillar_plot(ci)$data$flag
  test_flags <- unname(label[as.character(tests$flag)])
  differ <- which(plot_flags != test_flags)
  say(sprintf("%s, test(%s) against confint(%s)$%s: %d of %d providers differ%s", name,
              paste(names(test_args), unlist(test_args), sep = " = ", collapse = ", "),
              paste(names(ci_args), unlist(ci_args), sep = " = ", collapse = ", "), element, length(differ),
              length(test_flags),
              if (length(differ)) paste0(" (", paste(sprintf("%s: plot %s, test %s, p %.4g", rownames(tests)[differ],
                                                             plot_flags[differ], test_flags[differ],
                                                             tests$`p value`[differ]), collapse = "; "), ")") else ""))
}
compare("logis_fe", list(test = "exact.poisbinom", threads = 1), list(test = "exact", threads = 1), "CI.indirect_ratio")
compare("logis_fe", list(test = "score"), list(test = "score", threads = 1), "CI.indirect_ratio")
compare("logis_fe", list(test = "wald"), list(test = "wald", threads = 1), "CI.indirect_ratio")
compare("linear_fe", list(), list(), "CI.indirect")
compare("linear_fe_full", list(), list(), "CI.indirect")
compare("linear_re", list(), list(), "CI.indirect")
compare("logis_re", list(), list(), "CI.indirect_ratio")
writeLines(lines, out_file)
