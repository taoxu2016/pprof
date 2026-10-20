# Logistic extensions brief, Appendix A: what pprofR 0.2.0 does with inputs at the edges of its
# features, each call in its own tryCatch(): its result, warning, or error. These decide which
# behaviors pprof follows, refuses with a classed error (Class A), or asks about.
# Run from the repository root after 01: Rscript dev/design/logistic-facts/08_pprofr_edges.R <output file>
source("dev/design/logistic-facts/facts_data.R")
args <- commandArgs(trailingOnly = TRUE)
facts_use_libraries()
suppressPackageStartupMessages(library(pprofR))
out <- c("# 08: pprofR at the edges of its features", "",
         sprintf("pprofR %s, %s.", utils::packageVersion("pprofR"), R.version.string), "",
         "| Input | What pprofR does |", "|---|---|")
probe <- function(label, expr) {
  warnings <- character()
  value <- withCallingHandlers(
    tryCatch(expr, error = function(e) paste("error:", conditionMessage(e))),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  text <- if (is.character(value)) value else paste(format(value), collapse = "; ")
  if (length(warnings) > 0L) text <- paste0(text, " (warning: ", paste(unique(warnings), collapse = "; "), ")")
  out <<- c(out, sprintf("| %s | %s |", label, gsub("\n", " ", text, fixed = TRUE)))
}
fit_of <- function(d, binomial = TRUE, cluster = TRUE, ...) {
  pprofR::logis_fe(facts_pprofr_prep(d, binomial = binomial, cluster = cluster, cutoff = 1), ...)
}
summary_of <- function(fit) {
  sprintf("fit returned: %d iterations, coefficients %s", fit$control$iter,
          paste(sprintf("%.4g", as.numeric(fit$beta)), collapse = ", "))
}
base <- facts_simulate(m = 12, trials = c(2, 8), seed = 10)

d <- base
d$y[1] <- d$n[1] + 3L
probe("an outcome above its number of trials", summary_of(fit_of(d)))
d <- base
d$n[1:5] <- d$n[1:5] + 0.5
probe("non-integer numbers of trials", summary_of(fit_of(d)))
d <- base
d$n[1:5] <- 0L
d$y[1:5] <- 0L
probe("rows with 0 trials", summary_of(fit_of(d)))
d <- base
d$n[1] <- -2L
d$y[1] <- 0L
probe("a negative number of trials", summary_of(fit_of(d)))
d <- base
d$n[3] <- NA
probe("a missing number of trials, with check = TRUE", {
  pprofR::fe_data_prep(N = d$n, Y = d["y"], Z = d[c("x1", "x2", "x3")], ProvID = d["provider"], message = FALSE)
  "prepared"
})
probe("the same with check = FALSE", summary_of(fit_of(d)))
d <- base
d$y[d$provider == d$provider[1]] <- d$n[d$provider == d$provider[1]]
fit_all <- fit_of(d)
probe("a provider whose outcomes equal their trials (all events)",
      sprintf("flagged all.events: %s; its effect %.4g, the median %.4g", any(fit_all$data_include$all.events == 1),
              fit_all$gamma[1], stats::median(fit_all$gamma)))
probe("no covariates", {
  pprofR::fe_data_prep(N = base$n, Y = base["y"], Z = base[character()], ProvID = base["provider"], check = FALSE,
                       message = FALSE)
  "prepared"
})
probe("the AUC with trials", fit_of(base, AUC = TRUE)$AUC)
probe("one covariate: the likelihood-ratio test", {
  one <- pprofR::logis_fe(suppressWarnings(suppressMessages(pprofR::fe_data_prep(
    N = base$n, Y = base["y"], Z = base["x1"], ProvID = base["provider"], cutoff = 1, check = FALSE, message = FALSE))))
  pprofR::summary_fe_covar(one, test = "lr")$stat
})
probe("the standard score test (score_modified = FALSE)", pprofR::test_fe(fit_of(base), test = "score", score_modified = FALSE))
probe("a clustered test without a cluster column",
      pprofR::test_fe(fit_of(base, cluster = FALSE), test = "robust_wald"))

# Providers with one cluster: the robust variance of the provider's score is the square of the
# score itself.
single <- base
single$cluster <- single$provider
fit_single <- fit_of(single)
probe("every provider one cluster: robust score statistics",
      paste(sprintf("%.3g", pprofR::test_fe(fit_single, test = "robust_score")$stat), collapse = ", "))
probe("every provider one cluster: robust Wald statistics",
      paste(sprintf("%.3g", pprofR::test_fe(fit_single, test = "robust_wald", null = 0)$stat), collapse = ", "))
big <- facts_simulate(m = 3, clusters = c(2, 2), max_rows = 1, seed = 11)
big <- big[rep(seq_len(nrow(big)), c(5001, rep(1, nrow(big) - 1))), ]
probe("a cluster of 5,001 rows: the stabilized score test",
      pprofR::test_fe(fit_of(big, binomial = FALSE), test = "stabilized_score")$stat)
writeLines(out, args[1])
