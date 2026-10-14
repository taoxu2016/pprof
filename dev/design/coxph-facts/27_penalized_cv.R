# CoxPH Phase C4 plan: pprof_py v0.7.0's cross-validation (COXPH_DESIGN §A.5, K-144) from glmnet's fold
# paths, against the two penalized fixtures that hold it (penalized-wide, 8 vendored folds; penalized-combined,
# 10 folds drawn by the generator), with both tie methods and alpha = 1.
#
# Each fold's path is glmnet's on its training rows over pprof_py's grid (the full-data grid). The fold
# deviance D_kj = [2 (lsat_all - l_all) - 2 (lsat_T - l_T)] / W_k takes the partial log-likelihood l of the
# tie method at the fold's coefficients, on all rows and on the training rows, from three sources:
#   (a) survival's fitter with no covariates and the linear predictor as offset, called as coxph() calls it
#       (the offset less its mean, integer strata codes; DEC-100), which returns the offsets' log-likelihood;
#   (b) coxph() itself, as the fixture generator computed it (dev/reference/cox/survival.R);
#   (c) glmnet's coxnet.deviance(), Breslow ties only, whose saturated term is pprof_py's there;
#   (d) coxnet.deviance() given every grid point's linear predictor at once (one call per fold and row set),
#       both tie methods: for Efron ties glmnet's saturated term differs from pprof_py's by a constant of the
#       rows, which one evaluation of (a) per row set, at the offsets, measures and removes.
# lsat is pprof_py's Breslow form, -sum(w_t log w_t) over each stratum's distinct event times, for both tie
# methods. Compared: the fold deviances, cvm, cvsd, lambda_min, and lambda_1se against the generator's R
# side (max relative difference) and against pprof_py's (cvm and cvsd in penalized_path units, the lambdas
# exactly); the three sources against one another; the deviances with the rows sorted by provider, as
# data_prepare() orders them; and each source's time per call on these data.
#
# Run from the repository root:
#   Rscript dev/design/coxph-facts/27_penalized_cv.R dev/design/coxph-facts/27_penalized_cv.txt
args <- commandArgs(trailingOnly = TRUE)
out_file <- if (length(args)) args[[1]] else "27_penalized_cv.txt"
stopifnot(requireNamespace("glmnet", quietly = TRUE))
suppressPackageStartupMessages(library(survival))
lines <- sprintf("R %s; survival %s; glmnet %s", getRversion(), packageVersion("survival"), packageVersion("glmnet"))
say <- function(...) lines <<- c(lines, sprintf(...))
rel <- function(a, b) max(abs(a - b) / pmax(abs(b), .Machine$double.xmin), na.rm = TRUE)

case_data <- function(d, features, pf = NULL) {
  surv <- if ("start" %in% names(d)) Surv(d$start, d$stop, d$event) else Surv(d$stop, d$event)
  provider <- if ("provider" %in% names(d)) d$provider else rep(0L, nrow(d))
  offset <- intersect(c("offset1", "log_exposure"), names(d))
  list(x = as.matrix(d[, features, drop = FALSE]), surv = surv, provider = provider,
       y = glmnet::stratifySurv(surv, provider), w = if ("weight" %in% names(d)) d$weight else rep(1, nrow(d)),
       o = if (length(offset)) d[[offset]] else rep(0, nrow(d)),
       pf = if (is.null(pf)) rep(1, length(features)) else as.numeric(pf), event = d$event)
}

# (a) The offsets' partial log-likelihood from survival's fitter, as coxph() calls it for a model with
# no covariates (R/model-survival.R's survival_inputs() and survival_run_fitter()).
loglik_fitter <- function(surv, strata, w, eta, ties) {
  fitter <- if (ncol(surv) == 3) agreg.fit else coxph.fit
  offset <- if (all(eta == 0)) rep(0, length(eta)) else eta - mean(eta)
  fit <- fitter(matrix(0, length(eta), 0), surv, as.integer(factor(strata)), offset, NULL,
                coxph.control(timefix = FALSE), weights = w, method = ties, rownames = NULL, nocenter = c(-1, 0, 1))
  fit$loglik
}
# (b) coxph() itself, as dev/reference/cox/survival.R calls it.
loglik_coxph <- function(surv, strata, w, eta, ties) {
  coxph(surv ~ offset(eta) + strata(strata), weights = w, ties = ties, control = coxph.control(timefix = FALSE))$loglik[1]
}
# pprof_py's saturated term (utils/deviance.py:43-63): the Breslow form for both tie methods.
lsat <- function(surv, strata, w) {
  event <- surv[, ncol(surv)] == 1
  wd <- tapply(w[event], list(strata[event], surv[event, ncol(surv) - 1]), sum)
  wd <- wd[!is.na(wd) & wd > 0]
  -sum(wd * log(wd))
}

cross_validation <- function(cd, grid, fold, ties, source, rows = seq_len(nrow(cd$x))) {
  pf <- cd$pf
  cd <- lapply(cd, function(v) if (is.matrix(v) || inherits(v, "Surv")) v[rows, , drop = FALSE] else v[rows])
  cd$pf <- pf
  cd$y <- glmnet::stratifySurv(cd$surv, cd$provider)
  fold <- fold[rows]
  labels <- sort(unique(fold))
  deviance <- matrix(NA_real_, length(labels), length(grid))
  held <- numeric(length(labels))
  lsat_all <- lsat(cd$surv, cd$provider, cd$w)
  for (i in seq_along(labels)) {
    train <- fold != labels[i]
    fit <- glmnet::glmnet(cd$x[train, , drop = FALSE], cd$y[train], family = "cox", weights = cd$w[train],
                          offset = cd$o[train], alpha = 1, lambda = grid, penalty.factor = cd$pf, standardize = TRUE,
                          cox.ties = ties, control = list(thresh = 1e-12, maxit = 1e5, fdev = 0, devmax = 1))
    eta <- cd$x %*% as.matrix(fit$beta) + cd$o
    held[i] <- sum(cd$w[!train] * cd$event[!train])
    lsat_train <- lsat(cd$surv[train, ], cd$provider[train], cd$w[train])
    if (identical(source, "matrix")) {
      # glmnet's deviances of every grid point at once, moved to pprof_py's saturated term: the shift is
      # glmnet's deviance less pprof_py's at one linear predictor (the offsets), 0 up to rounding for Breslow.
      pprof_py_deviance <- function(rows, linear) {
        dev <- glmnet::coxnet.deviance(pred = linear, y = cd$y[rows], weights = cd$w[rows], std.weights = FALSE,
                                       cox.ties = ties)
        at_offset <- glmnet::coxnet.deviance(pred = cd$o[rows], y = cd$y[rows], weights = cd$w[rows],
                                             std.weights = FALSE, cox.ties = ties)
        reference <- 2 * (lsat(cd$surv[rows, ], cd$provider[rows], cd$w[rows]) -
                            loglik_fitter(cd$surv[rows, ], cd$provider[rows], cd$w[rows], cd$o[rows], ties))
        dev - (at_offset - reference)
      }
      all_rows <- seq_len(nrow(cd$x))
      deviance[i, ] <- (pprof_py_deviance(all_rows, eta) - pprof_py_deviance(which(train), eta[train, , drop = FALSE])) /
        held[i]
      next
    }
    for (j in seq_along(grid)) {
      if (identical(source, "coxnet")) {
        all <- glmnet::coxnet.deviance(pred = eta[, j], y = cd$y, weights = cd$w, std.weights = FALSE, cox.ties = ties)
        part <- glmnet::coxnet.deviance(pred = eta[train, j], y = cd$y[train], weights = cd$w[train], std.weights = FALSE,
                                        cox.ties = ties)
      } else {
        loglik <- if (identical(source, "fitter")) loglik_fitter else loglik_coxph
        all <- 2 * (lsat_all - loglik(cd$surv, cd$provider, cd$w, eta[, j], ties))
        part <- 2 * (lsat_train - loglik(cd$surv[train, ], cd$provider[train], cd$w[train], eta[train, j], ties))
      }
      deviance[i, j] <- (all - part) / held[i]
    }
  }
  cvm <- colSums(held * deviance) / sum(held)
  cvsd <- sqrt(colSums(held * sweep(deviance, 2, cvm)^2) / sum(held) / (length(labels) - 1))
  best <- which.min(cvm)
  list(deviance = deviance, cvm = cvm, cvsd = cvsd, lambda_min = grid[best],
       lambda_1se = grid[which(cvm <= cvm[best] + cvsd[best])[1]])
}

say("")
say("Against the generator's R side (relative) and pprof_py (cvm, cvsd in penalized_path units; lambdas exactly):")
say("%-19s %-7s %-7s %9s %9s %9s %8s %8s %s", "case", "ties", "source", "fold_dev", "cvm", "cvsd", "py_cvm_u",
    "py_sd_u", "lambda_min, 1se equal to R side / pprof_py")
costs <- character()
for (id in c("penalized-wide", "penalized-combined")) {
  fx <- readRDS(file.path("validation", "fixtures", "cox", paste0(id, ".rds")))
  cd <- case_data(fx$input, unlist(fx$case$features), unlist(fx$case$penalty_factor))
  fold <- unlist(fx$pprof_py$fold)
  for (ties in c("breslow", "efron")) {
    grid <- unlist(fx$pprof_py[[ties]]$alpha_1$path$lambda)
    r_side <- fx$survival[[ties]]$alpha_1$cv
    py <- fx$pprof_py[[ties]]$alpha_1$cv
    results <- list()
    for (source in c("fitter", "coxph", if (ties == "breslow") "coxnet", "matrix")) {
      seconds <- system.time(cv <- cross_validation(cd, grid, fold, ties, source))[["elapsed"]]
      results[[source]] <- cv
      fold_r <- do.call(rbind, lapply(r_side$fold_deviance, unlist))
      say("%-19s %-7s %-7s %9.2g %9.2g %9.2g %8.4f %8.4f %s / %s", id, ties, source, rel(cv$deviance, fold_r),
          rel(cv$cvm, unlist(r_side$cvm)), rel(cv$cvsd, unlist(r_side$cvsd)),
          max(abs(cv$cvm - unlist(py$cvm))) / 5e-6, max(abs(cv$cvsd - unlist(py$cvsd))) / 5e-6,
          identical(c(cv$lambda_min, cv$lambda_1se), c(r_side$lambda_min, r_side$lambda_1se)),
          identical(c(cv$lambda_min, cv$lambda_1se), c(py$lambda_min, py$lambda_1se)))
      calls <- if (identical(source, "matrix")) 2 * nrow(cv$deviance) else 2 * nrow(cv$deviance) * ncol(cv$deviance)
      costs <- c(costs, sprintf("%-19s %-7s %-7s %6.2f s for %d calls and %d fold paths", id, ties, source, seconds,
                                calls, nrow(cv$deviance)))
    }
    say("  fitter against coxph(): fold deviances identical: %s (max relative difference %.2g)",
        identical(results$fitter$deviance, results$coxph$deviance), rel(results$fitter$deviance, results$coxph$deviance))
    if (ties == "breslow") {
      say("  coxnet.deviance() against the fitter: max relative difference of the fold deviances %.2g",
          rel(results$coxnet$deviance, results$fitter$deviance))
    }
    say("  one coxnet.deviance() call per fold and row set against the fitter: fold deviances %.2g, cvm %.2g, cvsd %.2g",
        rel(results$matrix$deviance, results$fitter$deviance), rel(results$matrix$cvm, results$fitter$cvm),
        rel(results$matrix$cvsd, results$fitter$cvsd))
    if (length(unique(cd$provider)) > 1) {
      sorted <- order(cd$provider, method = "radix")
      by_provider <- cross_validation(cd, grid, fold, ties, "fitter", rows = sorted)
      say("  rows sorted by provider: fold deviances %.2g, cvm %.2g, cvsd %.2g (relative to input order); lambdas equal: %s",
          rel(by_provider$deviance, results$fitter$deviance), rel(by_provider$cvm, results$fitter$cvm),
          rel(by_provider$cvsd, results$fitter$cvsd),
          identical(c(by_provider$lambda_min, by_provider$lambda_1se),
                    c(results$fitter$lambda_min, results$fitter$lambda_1se)))
    }
  }
}
say("")
say("Time (these small data; the machine paging, so indicative):")
lines <- c(lines, costs)

writeLines(lines, out_file)
cat(lines, sep = "\n")
