# Logistic extensions brief, Appendix A: the stopping rules on binomial outcomes. pprof's default
# rule, "any" (pprofR's "or", pprof 1.0.3's default, D-24, M-4), stops when the smallest of three
# criteria is below tol; two of them are changes of the log-likelihood relative to its size, which
# grows with the number of trials. pprofR's default rule, "beta" (pprof's "coefficients"), uses the
# change of the coefficients only. For data with 1, 10, 100, and 1,000 trials per row, pprofR's
# SerBIN fit at tol = 1e-5 with each rule against a tight fit (rule "all", tol = 1e-13): the
# iterations, the largest differences of the provider effects and the coefficients, and the flags
# of the score and Wald tests (two-sided, level 0.95) that differ from the tight fit's.
# Run from the repository root after 01: Rscript dev/design/logistic-facts/06_stopping_rules.R <output file>
source("dev/design/logistic-facts/facts_data.R")
args <- commandArgs(trailingOnly = TRUE)
facts_use_libraries()
suppressPackageStartupMessages(library(pprofR))
out <- c("# 06: stopping rules on binomial outcomes", "",
         sprintf("pprofR %s, %s. 60 providers of 20 to 60 rows; fits by SerBIN with backtracking.",
                 utils::packageVersion("pprofR"), R.version.string), "",
         "| Trials per row | Rule at tol 1e-5 | Iterations (tight fit's) | Largest difference of an effect | Largest difference of a coefficient | Score flags differing | Wald flags differing |",
         "|---|---|---|---|---|---|---|")
flags <- function(fit, test) as.integer(as.character(pprofR::test_fe(fit, test = test)$flag))
for (size in c(1, 10, 100, 1000)) {
  d <- facts_simulate(m = 60, clusters = c(20, 60), max_rows = 1, cluster_sd = 0, trials = c(size, size), seed = 8)
  prep <- facts_pprofr_prep(d, binomial = TRUE, cluster = FALSE, cutoff = 1)
  tight <- pprofR::logis_fe(prep, tol = 1e-13, stop = "all")
  for (rule in c("or", "beta")) {
    fit <- pprofR::logis_fe(prep, tol = 1e-5, stop = rule)
    out <- c(out, sprintf("| %d | %s | %d (%d) | %.2g | %.2g | %d | %d |", size,
                          c(or = "\"any\" (\"or\")", beta = "\"coefficients\" (\"beta\")")[[rule]],
                          fit$control$iter, tight$control$iter, max(abs(fit$gamma - tight$gamma)),
                          max(abs(fit$beta - tight$beta)), sum(flags(fit, "score") != flags(tight, "score")),
                          sum(flags(fit, "wald") != flags(tight, "wald"))))
  }
}
writeLines(out, args[1])
