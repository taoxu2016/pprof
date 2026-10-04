# Phase 5, step 3: the reference on inputs its RE and CRE methods mishandle (D-45, D-46).
# Run from the repository root: Rscript <this file> <output file>
.libPaths(c("dev/reference/lib", .Library))
Sys.setlocale("LC_COLLATE", "C")
suppressPackageStartupMessages(library(pprof))
out <- character()
d <- readRDS("tests/testthat/fixtures/reference/datasets/linear_example.rds")
z <- paste0("z", 1:5)
cre <- suppressMessages(linear_cre(data = d, Y.char = "Y", wb.char = c("z1", "z2"), other.char = z[3:5], ProvID.char = "ProvID"))
re <- suppressMessages(linear_re(data = d, Y.char = "Y", Z.char = z, ProvID.char = "ProvID"))
attr(cre, "model") <- NULL
attr(re, "model") <- NULL
try_call <- function(label, expr) {
  res <- tryCatch({ suppressWarnings(expr); "value" }, error = function(e) paste("error:", conditionMessage(e)))
  out <<- c(out, sprintf("%s -> %s", label, res))
}
try_call("summary(linear_cre without model)", summary(cre))
try_call("SM_output(linear_cre without model)", SM_output(cre))
try_call("test(linear_cre without model)", test(cre))
try_call("summary(linear_re without model)", summary(re))
try_call("test(linear_re without model)", test(re))
try_call("confint(linear_re without model)", confint(re))
re2 <- suppressMessages(linear_re(data = d, Y.char = "Y", Z.char = z, ProvID.char = "ProvID"))
try_call("test(linear_re, null = c(0, 0.1))", test(re2, null = c(0, 0.1)))
try_call("summary(linear_re, null = c(0, 0.1, 0, 0, 0, 0))", summary(re2, null = c(0, 0.1, 0, 0, 0, 0)))
writeLines(out, commandArgs(TRUE)[1])
