# CoxPH Phase C4, after its benchmarks: where select_lambda()'s time goes on covariates-50, against the plain-R
# cross-validation from the engines that dev/bench/cox/run_paired.R times beside it (DEC-105, DEC-118). In one
# process (29_penalized_fit_parts.txt) select_lambda() took 1.075 times the plain-R cross-validation (medians of
# 3 runs of about 160 s), its fastest run 1.16 times.
#
# For each of run_paired.R's 10 folds, each part of the package's loop (cox_penalized_cross_validation() in
# R/model-cox-selection.R) and of the plain-R loop, timed apart and interleaved fold by fold: the fold's inputs
# (the package's cox_penalized_columns(), which also computes the column scales, against the subset of the
# design and the stratified response), the fold's glmnet path over the model's grid, the linear predictors of
# all rows, the glmnet deviances on all rows and on the training rows, and the shift to pprof_py's saturated
# term on the training rows. The paths, deviances, and shifts of the two loops are checked to be identical.
#
# Run from the repository root, with the benchmark data written by dev/bench/cox/run_paired.R (or
# dev/bench/cox/scenarios.R's cox_bench_write()) under <data dir>:
#   Rscript dev/design/coxph-facts/30_penalized_cv_parts.R dev/design/coxph-facts/30_penalized_cv_parts.txt <data dir>
args <- commandArgs(trailingOnly = TRUE)
out_file <- args[[1]]
data_root <- args[[2]]
suppressMessages(devtools::load_all(quiet = TRUE))
source(file.path("dev", "bench", "cox", "scenarios.R"))
lines <- sprintf("%s; survival %s; glmnet %s; %s", R.version.string, utils::packageVersion("survival"),
                 utils::packageVersion("glmnet"), Sys.getenv("PROCESSOR_IDENTIFIER", "unknown"))
say <- function(...) lines <<- c(lines, sprintf(...))
control <- list(thresh = 1e-12, maxit = 1e5, fdev = 0, devmax = 1)
scenarios <- cox_bench_scenarios()
dir <- cox_bench_write(scenarios[scenarios$id == "covariates-50", ], file.path(data_root, "covariates-50"))
d <- cox_bench_read(dir)
formula <- stats::as.formula(paste("Surv(start, stop, event) ~", paste(attr(d, "covariates"), collapse = " + "),
                                   "+ offset(offset)"))
set.seed(1)  # run_paired.R's folds (C1's): event-stratified, seed 1; a development script
folds <- integer(nrow(d))
for (group in list(which(d$event == 1), which(d$event == 0))) folds[group] <- sample(rep_len(1:10, length(group)))
model <- fit_cox_penalized(formula, d, "provider", weights = "weight")
grid <- model$lambda
prepared <- model_prepared_data(model, d)
rows <- survival_fit_rows(prepared)
inputs <- glmnet_inputs(prepared, rows)
p <- ncol(inputs$x)
fold <- folds[prepared$row_index]

parts <- c("inputs", "path", "eta", "all_deviance", "train_deviance", "shift")
package_parts <- stats::setNames(numeric(length(parts)), parts)
plain_parts <- stats::setNames(numeric(length(parts)), parts)
timed <- function(expr) bench::bench_time(expr)[["real"]]
say("")
say("Each fold's glmnet path (seconds), the package's and the plain-R loop's, and whether the two loops' results agree")
for (k in 1:10) {
  train <- rows[fold[rows] != k]
  training <- match(train, rows)
  # The package's loop.
  package_parts[["inputs"]] <- package_parts[["inputs"]] +
    timed(columns <- cox_penalized_columns(prepared, train, TRUE, model$penalty_factor))
  package_path <- timed(path <- glmnet_fit_path(columns$inputs, columns$keep, columns$factors, 1, grid, TRUE,
                                                "breslow", 1e-12, 1e5))
  package_parts[["path"]] <- package_parts[["path"]] + package_path
  package_parts[["eta"]] <- package_parts[["eta"]] + timed(eta <- inputs$x %*% path$path + inputs$offset)
  package_parts[["all_deviance"]] <- package_parts[["all_deviance"]] +
    timed(all_deviance <- glmnet_deviances(inputs, eta, "breslow"))
  package_parts[["train_deviance"]] <- package_parts[["train_deviance"]] +
    timed(train_deviance <- glmnet_deviances(columns$inputs, eta[training, , drop = FALSE], "breslow"))
  package_parts[["shift"]] <- package_parts[["shift"]] +
    timed(shift <- cox_penalized_deviance_shift(prepared, train, columns$inputs, "breslow"))
  # The plain-R loop, as run_paired.R writes it.
  plain_parts[["inputs"]] <- plain_parts[["inputs"]] + timed({
    x <- prepared$design[train, , drop = FALSE]
    y <- glmnet::stratifySurv(survival::Surv(prepared$start[train], prepared$stop[train], prepared$response[train]),
                              as.integer(factor(prepared$provider_index[train])))
  })
  plain_path <- timed({
    fit <- glmnet::glmnet(x, y, family = "cox", weights = prepared$weights[train], offset = prepared$offset[train],
                          alpha = 1, lambda = grid, penalty.factor = rep(1, p), standardize = TRUE,
                          cox.ties = "breslow", control = control)
  })
  plain_parts[["path"]] <- plain_parts[["path"]] + plain_path
  plain_parts[["eta"]] <- plain_parts[["eta"]] + timed(eta2 <- inputs$x %*% as.matrix(fit$beta) + inputs$offset)
  plain_parts[["all_deviance"]] <- plain_parts[["all_deviance"]] +
    timed(all_deviance2 <- glmnet::coxnet.deviance(pred = eta2, y = inputs$y, weights = inputs$weights,
                                                   std.weights = FALSE, cox.ties = "breslow"))
  plain_parts[["train_deviance"]] <- plain_parts[["train_deviance"]] +
    timed(train_deviance2 <- glmnet::coxnet.deviance(pred = eta2[training, , drop = FALSE], y = y,
                                                     weights = prepared$weights[train], std.weights = FALSE,
                                                     cox.ties = "breslow"))
  plain_parts[["shift"]] <- plain_parts[["shift"]] + timed({
    events <- train[prepared$response[train] == 1]
    times <- prepared$stop[events]
    distinct <- sort(unique(times))
    sums <- rowsum(prepared$weights[events], (prepared$provider_index[events] - 1) * length(distinct) +
                     match(times, distinct))
    sums <- sums[sums > 0]
    offset <- prepared$offset[train]
    loglik <- survival::agreg.fit(matrix(0, length(train), 0L),
                                  survival::Surv(prepared$start[train], prepared$stop[train],
                                                 prepared$response[train]),
                                  as.integer(factor(prepared$provider_index[train])), offset - mean(offset),
                                  NULL, survival::coxph.control(timefix = FALSE), weights = prepared$weights[train],
                                  method = "breslow", rownames = NULL, nocenter = c(-1, 0, 1))$loglik
    shift2 <- glmnet::coxnet.deviance(pred = matrix(offset, ncol = 1L), y = y, weights = prepared$weights[train],
                                      std.weights = FALSE, cox.ties = "breslow") - 2 * (-sum(sums * log(sums)) - loglik)
  })
  same <- identical(path$path, unname(as.matrix(fit$beta))) && identical(all_deviance, all_deviance2) &&
    identical(train_deviance, train_deviance2) && identical(shift, shift2)
  say("fold %2d: package %.2f, plain R %.2f (%d glmnet passes); identical %s", k, package_path, plain_path,
      fit$npasses, same)
}
say("")
say("The parts, summed over the 10 folds (seconds): the package's loop, the plain-R loop")
for (part in parts) say("  %-15s %8.2f %8.2f", part, package_parts[[part]], plain_parts[[part]])
say("  %-15s %8.2f %8.2f   ratio %.3f", "total", sum(package_parts), sum(plain_parts),
    sum(package_parts) / sum(plain_parts))
writeLines(lines, out_file)
