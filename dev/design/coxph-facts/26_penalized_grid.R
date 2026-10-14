# CoxPH Phase C4 plan: pprof_py v0.7.0's lambda grid (COXPH_DESIGN §A.5, K-143) written in plain R
# from engine calls, and glmnet's paths on it, against pprof_py's own grids and paths.
#
# The grid needs the score of the partial likelihood at the null point (the penalized coefficients 0,
# the unpenalized ones at their unpenalized fit). Here it comes from glmnet's exported coxgrad(), the
# gradient in the linear predictor, times the scaled design, and the unpenalized fit from survival's
# fitter called as coxph() calls it (DEC-100), at pprof_py's eps 1e-9 and 100 iterations; the score is
# checked against survival's score residuals at beta = 0. Compared, for every penalized case of both
# Cox fixture sets and for the settings of 26_penalized_grid.py (a constant column, ridge, no
# standardization, a given grid, a short grid, unequal penalty factors, fewer rows than columns), with
# both tie methods: lambda_max, the grid, and the column scales (relative differences); glmnet's path
# on this grid against pprof_py's path, in units of the penalized_path tier (atol 5e-6); glmnet's path
# on this grid against glmnet's on pprof_py's grid; the first grid point's penalized coefficients
# (D-72); glmnet with a constant column passed through; a single covariate, which glmnet refuses alone,
# given a column of zeros; glmnet's path with the rows sorted by provider, as data_prepare() orders
# them, against the input order; and (part C) glmnet on data with few events per covariate.
#
# Run from the repository root, after the Python script, with COXPH_FACTS_SCRATCH set:
#   Rscript dev/design/coxph-facts/26_penalized_grid.R dev/design/coxph-facts/26_penalized_grid.txt
args <- commandArgs(trailingOnly = TRUE)
out_file <- if (length(args)) args[[1]] else "26_penalized_grid.txt"
scratch <- Sys.getenv("COXPH_FACTS_SCRATCH")
stopifnot(nzchar(scratch), requireNamespace("glmnet", quietly = TRUE), requireNamespace("jsonlite", quietly = TRUE))
suppressPackageStartupMessages(library(survival))
lines <- sprintf("R %s; survival %s; glmnet %s", getRversion(), packageVersion("survival"), packageVersion("glmnet"))
say <- function(...) lines <<- c(lines, sprintf(...))
control <- function(eps, iter) coxph.control(eps = eps, iter.max = iter, timefix = FALSE)

# The response, strata, weights, offset, and penalty factors of a data frame in the fixtures' layout.
case_data <- function(d, features, pf = NULL) {
  surv <- if ("start" %in% names(d)) Surv(d$start, d$stop, d$event) else Surv(d$stop, d$event)
  provider <- if ("provider" %in% names(d)) d$provider else rep(0L, nrow(d))
  offset <- intersect(c("offset1", "log_exposure"), names(d))
  list(x = as.matrix(d[, features, drop = FALSE]), surv = surv, provider = provider,
       y = glmnet::stratifySurv(surv, provider), w = if ("weight" %in% names(d)) d$weight else rep(1, nrow(d)),
       o = if (length(offset)) d[[offset]] else rep(0, nrow(d)),
       pf = if (is.null(pf)) rep(1, length(features)) else as.numeric(pf))
}

# survival's fitter on the columns `x`, called as coxph() calls it (DEC-100; R/model-survival.R).
survival_null_fit <- function(cd, x, ties, eps, iter) {
  fitter <- if (ncol(cd$surv) == 3) agreg.fit else coxph.fit
  offset <- if (all(cd$o == 0)) rep(0, length(cd$o)) else cd$o - mean(cd$o)
  fit <- fitter(x, cd$surv, as.integer(factor(cd$provider)), offset, NULL, control(eps, iter), weights = cd$w,
                method = ties, rownames = NULL, nocenter = c(-1, 0, 1))
  unname(fit$coefficients)
}

# pprof_py's grid (penalized_coxph.py:192-356, coordinate_descent.py:361-429, penalty.py:87-148).
pprof_py_grid <- function(cd, alpha, ties, standardize = TRUE, n_lambda = 100, ratio = NULL, lambda = NULL,
                          eps = 1e-9, iter = 100) {
  wn <- cd$w / sum(cd$w)
  xm <- colSums(cd$x * wn)
  xv <- colSums(sweep(cd$x, 2, xm)^2 * wn)
  degenerate <- xv < 10 * .Machine$double.eps
  xs <- if (standardize) sqrt(ifelse(degenerate, 0, xv)) else rep(1, ncol(cd$x))
  xs[degenerate] <- 1
  keep <- !degenerate
  pf <- cd$pf[keep] * (sum(keep) / sum(cd$pf[keep]))
  x_fit <- sweep(cd$x[, keep, drop = FALSE], 2, xs[keep], "/")
  free <- pf == 0
  eta <- cd$o
  if (any(free) && !all(free)) {
    beta <- survival_null_fit(cd, x_fit[, free, drop = FALSE], ties, eps, iter)
    eta <- drop(x_fit[, free, drop = FALSE] %*% beta) + cd$o
  }
  score <- drop(crossprod(x_fit, glmnet::coxgrad(eta, cd$y, cd$w, std.weights = TRUE, cox.ties = ties)))
  lambda_max <- max(abs(score)[pf > 0] / pf[pf > 0]) / max(alpha, 1e-3)
  if (is.null(ratio)) ratio <- if (nrow(cd$x) < sum(keep)) 1e-2 else 1e-4
  grid <- if (!is.null(lambda)) {
    sort(lambda, decreasing = TRUE)
  } else if (n_lambda == 1) {
    lambda_max
  } else {
    exp(seq(log(lambda_max), log(lambda_max * ratio), length.out = n_lambda))
  }
  list(lambda_max = lambda_max, ratio = ratio, grid = grid, scale = xs, keep = keep, pf = pf)
}

# glmnet's path on `grid`, one column per grid point; when glmnet stops early (its iteration limit), the
# columns it did not reach are NA, and the attribute "stopped" holds its warning. glmnet refuses a design
# of one column, so a single covariate is given a column of zeros beside it with the same penalty factor:
# glmnet leaves a constant column out of the fit, and its rescaling of the factors then leaves them as
# they are.
glmnet_path <- function(cd, keep, alpha, grid, pf, ties, standardize = TRUE, rows = seq_len(nrow(cd$x))) {
  stopped <- NULL
  x <- cd$x[rows, keep, drop = FALSE]
  if (ncol(x) == 1L) {
    x <- cbind(x, 0)
    pf <- c(pf, pf)
  }
  fit <- withCallingHandlers(
    glmnet::glmnet(x, cd$y[rows], family = "cox", weights = cd$w[rows],
                   offset = cd$o[rows], alpha = alpha, lambda = grid, penalty.factor = pf, standardize = standardize,
                   cox.ties = ties, control = list(thresh = 1e-12, maxit = 1e5, fdev = 0, devmax = 1)),
    warning = function(w) {
      stopped <<- conditionMessage(w)
      invokeRestart("muffleWarning")
    }
  )
  path <- matrix(NA_real_, length(keep), length(grid))
  path[, seq_along(fit$lambda)] <- 0
  path[keep, seq_along(fit$lambda)] <- as.matrix(fit$beta)[seq_len(sum(keep)), , drop = FALSE]
  attr(path, "stopped") <- stopped
  attr(path, "passes") <- fit$npasses
  path
}
# Over the grid points both paths reached.
path_units <- function(a, b) {
  reached <- colSums(is.na(a)) == 0 & colSums(is.na(b)) == 0
  max(abs(a[, reached, drop = FALSE] - b[, reached, drop = FALSE])) / 5e-6
}
reached <- function(path) sum(colSums(is.na(path)) == 0)
stopped_notes <- character()
note_stop <- function(label, path) {
  if (!is.null(attr(path, "stopped"))) {
    stopped_notes <<- c(stopped_notes, sprintf("  %s: %d of %d grid points (%d passes); glmnet: %s", label,
                                               reached(path), ncol(path), attr(path, "passes"), attr(path, "stopped")))
  }
}

rel <- function(a, b) max(abs(a - b) / abs(b))

# --- Part A: the penalized fixture cases --------------------------------------------------------
say("")
say("A. Penalized fixture cases: the R grid against pprof_py's (relative differences), glmnet on it against")
say("   pprof_py's path (penalized_path units) and against glmnet on pprof_py's grid (max |difference|)")
say("%-22s %-7s %-5s %9s %9s %9s %9s %9s %s", "case", "ties", "alpha", "lam_max", "grid", "scale", "path_u",
    "vs_fx", "first-point penalized nonzero: pprof_py / glmnet")
sets <- list(core = "tests/testthat/fixtures/cox", full = "validation/fixtures/cox")
score_checks <- character()
order_checks <- character()
for (dir in sets) {
  for (file in list.files(dir, pattern = "^penalized-.*[.]rds$")) {
    fx <- readRDS(file.path(dir, file))
    cd <- case_data(fx$input, unlist(fx$case$features), unlist(fx$case$penalty_factor))
    for (ties in c("breslow", "efron")) {
      for (key in names(fx$pprof_py[[ties]])) {
        alpha <- as.numeric(sub("^alpha_", "", key))
        py <- fx$pprof_py[[ties]][[key]]$path
        g <- pprof_py_grid(cd, alpha, ties)
        path <- glmnet_path(cd, g$keep, alpha, g$grid, g$pf, ties)
        note_stop(sprintf("%s %s %s", fx$case$id, ties, key), path)
        py_path <- do.call(cbind, lapply(py$coef_path, unlist))
        fx_path <- do.call(cbind, lapply(fx$survival[[ties]][[key]]$path$coef_path, unlist))
        penalized <- cd$pf > 0
        say("%-22s %-7s %-5s %9.2g %9.2g %9.2g %9.3f %9.2g %d / %d", fx$case$id, ties, format(alpha),
            rel(g$lambda_max, py$lambda_max), rel(g$grid, unlist(py$lambda)), rel(g$scale, unlist(py$column_scale)),
            path_units(path, py_path), max(abs(path - fx_path), na.rm = TRUE), sum(py_path[penalized, 1] != 0),
            sum(path[penalized, 1] != 0))
        if (alpha == 1 && all(cd$pf > 0)) {
          # The score at beta = 0 from survival's score residuals, weighted and summed, over the weights' sum.
          f <- cd$surv ~ cd$x + strata(cd$provider) + offset(cd$o)
          fit0 <- suppressWarnings(coxph(f, weights = cd$w, ties = ties, init = rep(0, ncol(cd$x)),
                                         control = control(1e-9, 0)))
          u <- colSums(as.matrix(residuals(fit0, type = "score")) * cd$w) / sum(cd$w)
          grad <- drop(crossprod(cd$x, glmnet::coxgrad(cd$o, cd$y, cd$w, std.weights = TRUE, cox.ties = ties)))
          score_checks <- c(score_checks, sprintf("%-22s %-7s %9.2g", fx$case$id, ties, rel(abs(grad), abs(u))))
        }
        if (alpha == 1 && length(unique(cd$provider)) > 1) {
          sorted <- order(cd$provider, method = "radix")
          by_provider <- glmnet_path(cd, g$keep, alpha, g$grid, g$pf, ties, rows = sorted)
          order_checks <- c(order_checks, sprintf("%-22s %-7s %9.2g", fx$case$id, ties,
                                                  max(abs(by_provider - path), na.rm = TRUE)))
        }
      }
    }
  }
}
if (length(stopped_notes)) {
  say("")
  say("glmnet stopped before the end of the grid:")
  lines <- c(lines, stopped_notes)
  stopped_notes <- character()
}
say("")
say("The score at beta = 0: glmnet's coxgrad() times the design against survival's score residuals (relative):")
lines <- c(lines, score_checks)
say("")
say("glmnet's path with the rows sorted by provider against the input order (max |difference|):")
lines <- c(lines, order_checks)
fx <- readRDS("validation/fixtures/cox/penalized-combined.rds")
cd <- case_data(fx$input, unlist(fx$case$features), unlist(fx$case$penalty_factor))
say("")
say("penalized-combined (x1 unpenalized): lambda_max with the unpenalized fit at eps 1e-9 against eps 1e-12")
for (ties in c("breslow", "efron")) {
  py <- fx$pprof_py[[ties]]$alpha_1$path$lambda_max
  say("  %-7s eps 1e-9: %.3g; eps 1e-12: %.3g (relative to pprof_py's)", ties,
      rel(pprof_py_grid(cd, 1, ties)$lambda_max, py), rel(pprof_py_grid(cd, 1, ties, eps = 1e-12)$lambda_max, py))
}

# --- Part B: settings the fixtures do not cover (26_penalized_grid.py) ---------------------------
records <- jsonlite::read_json(file.path(scratch, "26_pprof_py.json"))
inputs <- file.path("dev", "reference", "cox", "inputs", "pprof_py")
combined <- read.csv(file.path(inputs, "combined.csv"))
frames <- list(combined = combined, constant = cbind(x0 = 1, combined),
               wide = read.csv(file.path(inputs, "penalized_wide.csv"))[1:15, ])
say("")
say("B. Settings the fixtures do not cover, against pprof_py 0.7.0 (%s, NumPy %s)", records$python, records$numpy)
say("%-19s %-7s %4s %9s %9s %9s %9s  %s", "setting", "ties", "n_l", "lam_max", "grid", "scale", "path_u",
    "pprof_py's warnings")
num <- function(v) as.numeric(unlist(v))
for (r in records$records) {
  settings <- r$settings
  frame <- switch(r$label, "constant-column" = frames$constant, "rows-below-columns" = frames$wide, frames$combined)
  cd <- case_data(frame, unlist(r$features), settings$penalty_factor)
  alpha <- if (is.null(settings$alpha)) 1 else settings$alpha
  standardize <- !isFALSE(settings$standardize)
  g <- pprof_py_grid(cd, alpha, r$ties, standardize = standardize,
                     n_lambda = if (is.null(settings$n_lambda)) 100 else settings$n_lambda,
                     ratio = settings$lambda_min_ratio, lambda = if (!is.null(settings$lambda_path)) num(settings$lambda_path))
  path <- glmnet_path(cd, g$keep, alpha, g$grid, g$pf, r$ties, standardize = standardize)
  note_stop(sprintf("%s %s", r$label, r$ties), path)
  py_path <- do.call(cbind, lapply(r$coef_path, num))
  say("%-19s %-7s %4d %9.2g %9.2g %9.2g %9.3f  %s", r$label, r$ties, length(g$grid), rel(g$lambda_max, num(r$lambda_max)),
      rel(g$grid, num(r$lambda)), rel(g$scale, num(r$column_scale)), path_units(path, py_path),
      if (length(r$warnings)) substr(paste(unlist(r$warnings), collapse = " | "), 1, 60) else "none")
  if (identical(r$label, "rows-below-columns")) {
    units <- apply(abs(path - py_path), 2, max) / 5e-6
    say("  %s: ratio %g (pprof_py's %g); %d rows, %d events; units by lambda: first above 1 at grid point %s of %d",
        r$ties, g$ratio, num(r$lambda_min_ratio), r$rows, r$events,
        if (any(units > 1, na.rm = TRUE)) which(units > 1)[1] else "none", ncol(path))
  }
  if (identical(r$label, "constant-column")) {
    # glmnet given the constant column, with its penalty factor: glmnet rescales the factors over every column.
    through <- glmnet::glmnet(cd$x, cd$y, family = "cox", weights = cd$w, offset = cd$o, alpha = 1, lambda = g$grid,
                              penalty.factor = cd$pf, standardize = TRUE, cox.ties = r$ties,
                              control = list(thresh = 1e-12, maxit = 1e5, fdev = 0, devmax = 1))
    say("  %s: constant column passed to glmnet: its coefficient is 0 throughout: %s; path against pprof_py %.3g units",
        r$ties, all(as.matrix(through$beta)[1, ] == 0), path_units(as.matrix(through$beta), py_path))
  }
}
if (length(stopped_notes)) {
  say("")
  say("glmnet stopped before the end of the grid:")
  lines <- c(lines, stopped_notes)
}

# --- Part C: glmnet with few events per covariate -------------------------------------------------
# The rows-below-columns setting again, on pprof_py's grid, with glmnet's iteration limit at the default
# 1e5 and at 1e6; then the first n rows of penalized_wide.csv on glmnet's own grid (lambda.min.ratio 0.01).
say("")
say("C. glmnet with few events per covariate (penalized_wide.csv, 20 covariates): grid points reached, the largest")
say("   |coefficient| at the last one, glmnet's deviance ratio (1 - deviance / null deviance), and its warning")
wide <- frames$wide
for (r in records$records) {
  if (!identical(r$label, "rows-below-columns")) next
  cd <- case_data(wide, unlist(r$features))
  for (maxit in c(1e5, 1e6)) {
    message <- NULL
    fit <- withCallingHandlers(
      glmnet::glmnet(cd$x, cd$y, family = "cox", alpha = 1, lambda = num(r$lambda), standardize = TRUE, cox.ties = r$ties,
                     control = list(thresh = 1e-12, maxit = maxit, fdev = 0, devmax = 1)),
      warning = function(w) {
        message <<- conditionMessage(w)
        invokeRestart("muffleWarning")
      }
    )
    largest <- apply(abs(as.matrix(fit$beta)), 2, max)
    py_largest <- apply(abs(do.call(cbind, lapply(r$coef_path, num))), 2, max)
    say("  15 rows, %-7s maxit %g: %3d of 100 points; largest |coef| %.3g (pprof_py's %.3g, converged at all %d); dev.ratio %s; %s",
        r$ties, maxit, length(fit$lambda), utils::tail(largest, 1), max(py_largest),
        sum(unlist(r$converged_path)), paste(format(range(fit$dev.ratio), digits = 3), collapse = " to "),
        if (is.null(message)) "no warning" else sub("^.*(Convergence for [0-9]+th lambda).*$", "\\1 value not reached", message))
    # Where the path first fails: a deviance above the null deviance (dev.ratio below -sqrt(eps)), which no
    # solution of the penalized problem has, or a coefficient that is not finite.
    bad <- which(fit$dev.ratio < -sqrt(.Machine$double.eps) | colSums(!is.finite(as.matrix(fit$beta))) > 0)
    reached <- length(fit$lambda)
    before <- if (length(bad)) bad[1] - 1 else reached
    say("    first point with a deviance above the null's or a coefficient not finite: %s; at point %d the largest |coef| %.3g (pprof_py's %.3g)",
        if (length(bad)) bad[1] else "none", before, largest[before], py_largest[before])
  }
}
for (n in c(19, 25, 40, 80)) {
  for (ties in c("breslow", "efron")) {
    cd <- case_data(read.csv(file.path(inputs, "penalized_wide.csv"))[seq_len(n), ], paste0("x", 1:20))
    message <- NULL
    fit <- withCallingHandlers(
      glmnet::glmnet(cd$x, cd$y, family = "cox", alpha = 1, nlambda = 100, lambda.min.ratio = 0.01, standardize = TRUE,
                     cox.ties = ties, control = list(thresh = 1e-12, maxit = 1e5, fdev = 0, devmax = 1)),
      warning = function(w) {
        message <<- conditionMessage(w)
        invokeRestart("muffleWarning")
      }
    )
    say("  %2d rows (%2d events), %-7s glmnet's grid: %3d of 100 points; largest |coef| %.3g; least dev.ratio %.3g; %s", n,
        sum(cd$surv[, 2]), ties, length(fit$lambda), max(abs(as.matrix(fit$beta))), min(fit$dev.ratio),
        if (is.null(message)) "no warning" else sub("^.*(Convergence for [0-9]+th lambda).*$", "\\1 value not reached", message))
  }
}

writeLines(lines, out_file)
cat(lines, sep = "\n")
