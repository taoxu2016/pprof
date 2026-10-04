# Phase 6, step 1 (R-2): seeds for small datasets without provider effects whose RE and CRE
# fits have provider variance exactly 0 in the reference (M-19), for the core fixture set.
# The data have the shape of dev/design/phase5-facts/09_singular_re_fits.R with fewer and
# smaller providers; simulate_no_provider_effects() is the function dev/reference/datasets.R
# uses. Reports the first seeds whose fits are singular with every test flag missing.
# Run from the repository root: Rscript <this file> <output file>
.libPaths(c("dev/reference/lib", .Library))
Sys.setenv(OMP_THREAD_LIMIT = "1")
Sys.setlocale("LC_COLLATE", "C")
suppressPackageStartupMessages(library(pprof))
source("dev/reference/datasets.R")
out_file <- commandArgs(TRUE)[1]
lines <- character()
say <- function(...) lines <<- c(lines, paste0(...))
quiet <- function(expr) suppressMessages(suppressWarnings(expr))

fit_family <- function(fun, d) {
  args <- if (endsWith(fun, "cre")) {
    list(data = d, Y.char = "Y", wb.char = "x1", other.char = c("x2", "x3"), ProvID.char = "ProvID")
  } else {
    list(data = d, Y.char = "Y", Z.char = c("x1", "x2", "x3"), ProvID.char = "ProvID")
  }
  quiet(do.call(fun, args))
}
singular <- function(fun, d) {
  fit <- fit_family(fun, d)
  flags <- quiet(test(fit))$flag
  fit$variance$alpha[1] == 0 && all(is.na(flags))
}

settings <- list(
  linear = list(m = 20, sizes = 5:15, logistic = FALSE, funs = c("linear_re", "linear_cre")),
  logistic = list(m = 20, sizes = 15:40, logistic = TRUE, funs = c("logis_re", "logis_cre"))
)
for (name in names(settings)) {
  s <- settings[[name]]
  found <- list()
  for (seed in 1:400) {
    d <- simulate_no_provider_effects(s$m, s$sizes, s$logistic, seed)
    ok <- vapply(s$funs, singular, logical(1), d = d)
    if (all(ok)) {
      found$both <- c(found$both, seed)
    } else if (any(ok)) {
      found[[s$funs[ok]]] <- c(found[[s$funs[ok]]], seed)
    }
    if (length(found$both) >= 3) break
  }
  say(sprintf("%s (%d providers of %d to %d observations): seeds singular for both %s: %s; for one only: %s",
              name, s$m, min(s$sizes), max(s$sizes), paste(s$funs, collapse = " and "),
              paste(found$both, collapse = ", "),
              paste(vapply(setdiff(names(found), "both"), function(k) sprintf("%s %s", k, paste(utils::head(found[[k]], 5),
                                                                                                    collapse = ",")), ""),
                    collapse = "; ")))
  if (length(found$both)) {
    d <- simulate_no_provider_effects(s$m, s$sizes, s$logistic, found$both[1])
    for (fun in s$funs) {
      fit <- fit_family(fun, d)
      tests <- quiet(test(fit))
      say(sprintf("  seed %d, %s: %d rows; provider variance %g; lme4 singular %s; %d of %d flags missing; flag levels {%s}",
                  found$both[1], fun, nrow(d), fit$variance$alpha[1], lme4::isSingular(attr(fit, "model")),
                  sum(is.na(tests$flag)), nrow(tests), paste(levels(tests$flag), collapse = ",")))
    }
  }
}
writeLines(lines, out_file)
