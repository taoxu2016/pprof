# CoxPH Phase C4, after its benchmarks: fit_cox_penalized() and select_lambda() against their glmnet calls and
# the preparation of their inputs (DEC-105, DEC-118), interleaved in one process rather than in fresh ones, to
# separate the code's cost from the noise of the paired runs. The C4 paired run
# (dev/bench/results/cox-c4-paired-20261014-windows.md) passed DEC-105's rule, but on covariates-50 the path's
# medians were 1.14 times the comparator in both rounds (fastest runs 0.99 and 1.12), and the cross-validation
# 0.85 and 1.15 times it in its two rounds of one run each.
#
# A. The path, for covariates-50 (5 runs) and rows-1e4 (9 runs): the medians of interleaved runs of the engine
#    call (glmnet() on the adapter's inputs over pprof_py's grid, as dev/bench/cox/run_paired.R calls it); the
#    adapter's call on the same inputs (glmnet_fit_path(), which adds the checks of DEC-115); the preparation of
#    the inputs (data_prepare(), the inputs, the column scales, and the grid from coxgrad()); and the fit
#    (fit_cox_penalized() on the data frame). The paths of the engine call, the adapter, and the fit are
#    checked to be identical.
# B. The cross-validation, for covariates-50 (3 runs): select_lambda() with run_paired.R's 10 folds on a fit made
#    outside the timing, against run_paired.R's plain-R cross-validation from the engines; their fold
#    deviances, cvm, and cvsd are checked to be identical.
#
# Run from the repository root, with the benchmark data written by dev/bench/cox/run_paired.R (or
# dev/bench/cox/scenarios.R's cox_bench_write()) under <data dir>:
#   Rscript dev/design/coxph-facts/29_penalized_fit_parts.R dev/design/coxph-facts/29_penalized_fit_parts.txt <data dir>
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
load_scenario <- function(id) {
  dir <- cox_bench_write(scenarios[scenarios$id == id, ], file.path(data_root, id))
  d <- cox_bench_read(dir)
  formula <- stats::as.formula(paste("Surv(start, stop, event) ~", paste(attr(d, "covariates"), collapse = " + "),
                                     "+ offset(offset)"))
  list(d = d, formula = formula)
}
interleave <- function(sides, runs) {
  times <- matrix(NA_real_, runs, length(sides), dimnames = list(NULL, names(sides)))
  for (i in seq_len(runs)) for (s in names(sides)) times[i, s] <- bench::bench_time(sides[[s]]())[["real"]]
  times
}

say("")
say("A. The path: medians of interleaved runs (seconds); the ratio is DEC-105's, the fit over the engine call plus")
say("   the preparation")
say("%-15s %5s %8s %8s %12s %8s %8s %10s", "scenario", "runs", "engine", "adapter", "preparation", "fit", "ratio",
    "identical")
for (id in c("covariates-50", "rows-1e4")) {
  runs <- if (identical(id, "covariates-50")) 5L else 9L
  scenario <- load_scenario(id)
  d <- scenario$d
  formula <- scenario$formula
  prepare <- function() {
    prepared <- data_prepare(formula, d, "provider", event_counts = TRUE, response_type = "survival",
                             weights = "weight", allow_offset = TRUE)
    rows <- survival_fit_rows(prepared)
    inputs <- glmnet_inputs(prepared, rows)
    scale <- sqrt(glmnet_column_variance(inputs$x, inputs$weights))
    score <- glmnet_scaled_score(inputs, rep(TRUE, ncol(inputs$x)), scale, inputs$offset, "breslow")
    lambda_max <- max(abs(score))
    list(inputs = inputs, grid = exp(seq(log(lambda_max), log(lambda_max * 1e-4), length.out = 100)))
  }
  built <- prepare()
  inputs <- built$inputs
  grid <- built$grid
  p <- ncol(inputs$x)
  sides <- list(
    engine = function() {
      glmnet::glmnet(inputs$x, inputs$y, family = "cox", weights = inputs$weights, offset = inputs$offset,
                     alpha = 1, lambda = grid, penalty.factor = rep(1, p), standardize = TRUE, cox.ties = "breslow",
                     control = control)
    },
    adapter = function() glmnet_fit_path(inputs, rep(TRUE, p), rep(1, p), 1, grid, TRUE, "breslow", 1e-12, 1e5),
    preparation = prepare,
    fit = function() fit_cox_penalized(formula, d, "provider", weights = "weight")
  )
  values <- lapply(sides, function(s) s())
  same <- identical(unname(as.matrix(values$engine$beta)), values$adapter$path) &&
    identical(values$adapter$path, unname(values$fit$coefficient_path))
  times <- interleave(sides, runs)
  m <- apply(times, 2, stats::median)
  say("%-15s %5d %8.3f %8.3f %12.3f %8.3f %8.3f %10s", id, runs, m[["engine"]], m[["adapter"]], m[["preparation"]],
      m[["fit"]], m[["fit"]] / (m[["engine"]] + m[["preparation"]]), same)
  say("%-15s fastest: engine %.3f, adapter %.3f, preparation %.3f, fit %.3f", "", min(times[, "engine"]),
      min(times[, "adapter"]), min(times[, "preparation"]), min(times[, "fit"]))
}

say("")
say("B. The cross-validation on covariates-50: medians of 3 interleaved runs (seconds); the ratio is DEC-105's,")
say("   select_lambda() over the plain-R cross-validation plus the preparation of its inputs")
scenario <- load_scenario("covariates-50")
d <- scenario$d
formula <- scenario$formula
set.seed(1)  # run_paired.R's folds (C1's): event-stratified, seed 1; a development script
folds <- integer(nrow(d))
for (group in list(which(d$event == 1), which(d$event == 0))) folds[group] <- sample(rep_len(1:10, length(group)))
model <- fit_cox_penalized(formula, d, "provider", weights = "weight")
grid <- model$lambda
prepare <- function() {
  prepared <- data_prepare(formula, d, "provider", event_counts = TRUE, response_type = "survival",
                           weights = "weight", allow_offset = TRUE)
  rows <- survival_fit_rows(prepared)
  list(prepared = prepared, rows = rows, inputs = glmnet_inputs(prepared, rows))
}
built <- prepare()
prepared <- built$prepared
rows <- built$rows
inputs <- built$inputs
p <- ncol(inputs$x)
# run_paired.R's engine side of penalized_cv, unchanged.
engine_cv <- function() {
  event_weight <- prepared$response * prepared$weights
  held <- vapply(1:10, function(k) sum(event_weight[folds[prepared$row_index] == k]), numeric(1))
  fold <- folds[prepared$row_index]
  shift <- function(rows, y, weights, offset) {
    glmnet_deviance <- glmnet::coxnet.deviance(pred = matrix(offset, ncol = 1L), y = y, weights = weights,
                                               std.weights = FALSE, cox.ties = "breslow")
    events <- rows[prepared$response[rows] == 1]
    times <- prepared$stop[events]
    distinct <- sort(unique(times))
    sums <- rowsum(prepared$weights[events], (prepared$provider_index[events] - 1) * length(distinct) +
                     match(times, distinct))
    sums <- sums[sums > 0]
    loglik <- survival::agreg.fit(matrix(0, length(rows), 0L),
                                  survival::Surv(prepared$start[rows], prepared$stop[rows], prepared$response[rows]),
                                  as.integer(factor(prepared$provider_index[rows])), offset - mean(offset),
                                  NULL, survival::coxph.control(timefix = FALSE), weights = weights,
                                  method = "breslow", rownames = NULL, nocenter = c(-1, 0, 1))$loglik
    glmnet_deviance - 2 * (-sum(sums * log(sums)) - loglik)
  }
  all_shift <- shift(rows, inputs$y, inputs$weights, inputs$offset)
  deviance <- matrix(NA_real_, 10, length(grid))
  for (k in 1:10) {
    train <- rows[fold[rows] != k]
    x <- prepared$design[train, , drop = FALSE]
    y <- glmnet::stratifySurv(survival::Surv(prepared$start[train], prepared$stop[train], prepared$response[train]),
                              as.integer(factor(prepared$provider_index[train])))
    path <- glmnet::glmnet(x, y, family = "cox", weights = prepared$weights[train], offset = prepared$offset[train],
                           alpha = 1, lambda = grid, penalty.factor = rep(1, p), standardize = TRUE,
                           cox.ties = "breslow", control = control)
    eta <- inputs$x %*% as.matrix(path$beta) + inputs$offset
    training <- match(train, rows)
    all_deviance <- glmnet::coxnet.deviance(pred = eta, y = inputs$y, weights = inputs$weights, std.weights = FALSE,
                                            cox.ties = "breslow") - all_shift
    train_deviance <- glmnet::coxnet.deviance(pred = eta[training, , drop = FALSE], y = y,
                                              weights = prepared$weights[train], std.weights = FALSE,
                                              cox.ties = "breslow") -
      shift(train, y, prepared$weights[train], prepared$offset[train])
    deviance[k, ] <- (all_deviance - train_deviance) / held[k]
  }
  cvm <- colSums(held * deviance) / sum(held)
  cvsd <- sqrt(colSums(held * sweep(deviance, 2L, cvm)^2) / sum(held) / 9)
  list(deviance = deviance, cvm = cvm, cvsd = cvsd)
}
sides <- list(engine = engine_cv, preparation = prepare,
              fit = function() select_lambda(model, folds = folds, data = d))
# The first round's values serve for the check, so that no run is spent on it alone.
times <- matrix(NA_real_, 3, length(sides), dimnames = list(NULL, names(sides)))
values <- list()
for (i in 1:3) {
  for (s in names(sides)) {
    times[i, s] <- bench::bench_time(value <- sides[[s]]())[["real"]]
    if (i == 1L) values[[s]] <- value
  }
}
cv <- values$fit$cross_validation
same <- identical(values$engine$deviance, cv$fold_deviance) && identical(values$engine$cvm, cv$cvm) &&
  identical(values$engine$cvsd, cv$cvsd)
m <- apply(times, 2, stats::median)
say("engine %.1f, preparation %.3f, select_lambda() %.1f; ratio %.3f; fastest: engine %.1f, select_lambda() %.1f;",
    m[["engine"]], m[["preparation"]], m[["fit"]], m[["fit"]] / (m[["engine"]] + m[["preparation"]]),
    min(times[, "engine"]), min(times[, "fit"]))
say("each run (engine, select_lambda()): %s; identical: %s",
    paste(sprintf("%.1f and %.1f", times[, "engine"], times[, "fit"]), collapse = "; "), same)
writeLines(lines, out_file)
