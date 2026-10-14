# CoxPH Phase C4 plan: what the parts of a penalized path and of its cross-validation cost on the benchmark's
# penalized scenario (covariates-50: 100,000 rows, 1,000 providers, 50 covariates, delayed entry, daily
# ties, an offset, weights; dev/bench/cox/scenarios.R), with Breslow ties: pprof_py's grid from glmnet's
# coxgrad() (fact 26); glmnet's path on it; one fold's path; the product of the design and a fold's
# coefficient path; and one evaluation of the partial log-likelihood at a linear predictor, by survival's
# fitter called as coxph() calls it, by coxph(), and by glmnet's coxnet.deviance(), on all rows and on
# nine tenths of them. From these, the estimated time of select_lambda() with 10 folds, which evaluates
# the partial likelihood twice per fold and grid point (K-144).
#
# Run from the repository root:
#   Rscript dev/design/coxph-facts/28_penalized_cost.R dev/design/coxph-facts/28_penalized_cost.txt
args <- commandArgs(trailingOnly = TRUE)
out_file <- if (length(args)) args[[1]] else "28_penalized_cost.txt"
stopifnot(requireNamespace("glmnet", quietly = TRUE))
suppressPackageStartupMessages(library(survival))
source(file.path("dev", "bench", "cox", "scenarios.R"))
lines <- sprintf("R %s; survival %s; glmnet %s; %s", getRversion(), packageVersion("survival"), packageVersion("glmnet"),
                 Sys.getenv("PROCESSOR_IDENTIFIER", "unknown processor"))
say <- function(...) lines <<- c(lines, sprintf(...))
elapsed <- function(expr) system.time(expr)[["elapsed"]]

sc <- cox_bench_scenarios()
sc <- sc[sc$id == "covariates-50", ]
d <- cox_bench_data(sc$n, sc$m, sc$p, sc$seed)
x <- as.matrix(d[, grep("^x", names(d))])
surv <- Surv(d$start, d$stop, d$event)
y <- glmnet::stratifySurv(surv, d$provider)
w <- d$weight
o <- d$offset
n <- nrow(x)
say("covariates-50: %d rows, %d providers, %d covariates, %d events", n, length(unique(d$provider)), ncol(x), sum(d$event))

grid_time <- elapsed({
  wn <- w / sum(w)
  xs <- sqrt(colSums(sweep(x, 2, colSums(x * wn))^2 * wn))
  score <- drop(crossprod(sweep(x, 2, xs, "/"), glmnet::coxgrad(o, y, w, std.weights = TRUE, cox.ties = "breslow")))
  lambda_max <- max(abs(score))
  grid <- exp(seq(log(lambda_max), log(lambda_max * 1e-4), length.out = 100))
})
say("pprof_py's grid (scales, coxgrad() at the offset, lambda_max): %.2f s", grid_time)

path <- function(rows) {
  glmnet::glmnet(x[rows, , drop = FALSE], y[rows], family = "cox", weights = w[rows], offset = o[rows], alpha = 1,
                 lambda = grid, standardize = TRUE, cox.ties = "breslow",
                 control = list(thresh = 1e-12, maxit = 1e5, fdev = 0, devmax = 1))
}
path_time <- elapsed(full <- path(seq_len(n)))
say("glmnet's path on all rows, 100 grid points: %.1f s (%d passes)", path_time, full$npasses)
set.seed(1)  # a development script: package code never calls set.seed()
fold <- integer(n)
for (group in list(which(d$event == 1), which(d$event == 0))) fold[group] <- sample(rep_len(1:10, length(group)))
train <- fold != 1
fold_time <- elapsed(fit <- path(which(train)))
say("one fold's path (nine tenths of the rows): %.1f s (%d passes)", fold_time, fit$npasses)
product_time <- elapsed(eta <- x %*% as.matrix(fit$beta) + o)
say("the design times the fold's coefficient path (%d x %d by %d x %d): %.2f s", n, ncol(x), ncol(x), ncol(eta),
    product_time)

loglik_fitter <- function(rows, linear) {
  offset <- linear - mean(linear)
  agreg.fit(matrix(0, length(rows), 0), surv[rows, ], as.integer(factor(d$provider[rows])), offset, NULL,
            coxph.control(timefix = FALSE), weights = w[rows], method = "breslow", rownames = NULL,
            nocenter = c(-1, 0, 1))$loglik
}
loglik_coxph <- function(rows, linear) {
  s <- surv[rows, ]
  p <- d$provider[rows]
  coxph(s ~ offset(linear) + strata(p), weights = w[rows], ties = "breslow",
        control = coxph.control(timefix = FALSE))$loglik[1]
}
deviance_coxnet <- function(rows, linear) {
  glmnet::coxnet.deviance(pred = linear, y = y[rows], weights = w[rows], std.weights = FALSE, cox.ties = "breslow")
}
calls <- 5
per_call <- list()
for (source in c("fitter", "coxph", "coxnet")) {
  f <- switch(source, fitter = loglik_fitter, coxph = loglik_coxph, coxnet = deviance_coxnet)
  all_time <- elapsed(for (j in seq_len(calls)) f(seq_len(n), eta[, 50 + j]))
  train_rows <- which(train)
  train_time <- elapsed(for (j in seq_len(calls)) f(train_rows, eta[train_rows, 50 + j]))
  per_call[[source]] <- (all_time + train_time) / (2 * calls)
  say("one partial-likelihood evaluation, %-7s %.3f s on all rows, %.3f s on nine tenths", source, all_time / calls,
      train_time / calls)
}
train_rows <- which(train)
matrix_all <- elapsed(glmnet::coxnet.deviance(pred = eta, y = y, weights = w, std.weights = FALSE,
                                              cox.ties = "breslow"))
matrix_train <- elapsed(glmnet::coxnet.deviance(pred = eta[train_rows, ], y = y[train_rows], weights = w[train_rows],
                                                std.weights = FALSE, cox.ties = "breslow"))
say("coxnet.deviance() of all 100 grid points at once: %.2f s on all rows, %.2f s on nine tenths", matrix_all,
    matrix_train)
say("")
say("Estimated select_lambda() with 10 folds: 10 fold paths and 10 products, and 2,000 evaluations, or 20 calls of")
say("coxnet.deviance() with every grid point at once and 11 fitter evaluations for the saturated term's shift:")
for (source in names(per_call)) {
  evaluations <- 2000 * per_call[[source]]
  say("  %-7s %6.0f s, of which the evaluations %5.0f s (%2.0f%%)", source, 10 * (fold_time + product_time) + evaluations,
      evaluations, 100 * evaluations / (10 * (fold_time + product_time) + evaluations))
}
evaluations <- 10 * (matrix_all + matrix_train) + 11 * per_call$fitter
say("  %-7s %6.0f s, of which the evaluations %5.0f s (%2.0f%%)", "matrix", 10 * (fold_time + product_time) + evaluations,
    evaluations, 100 * evaluations / (10 * (fold_time + product_time) + evaluations))
say("C1 (dev/bench/results/cox-baseline-20261008-windows.md, glmnet's own grid): glmnet path 14.30 s; glmnet 10-fold CV")
say("204.06 s (11 paths and 1,000 coxnet.deviance() evaluations on all rows); pprof_py path 89.92 s, 10-fold CV 1716.53 s.")

writeLines(lines, out_file)
cat(lines, sep = "\n")
