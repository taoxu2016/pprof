# The R half of the Cox fixture generator (dev/reference/cox/README.md): survival's and glmnet's
# outputs for each staged case, as the package's adapters will call them (COXPH_DESIGN §E), so that
# the fixtures hold both references (CoxPH brief §3.1). Adapted from pprof_spark's
# reference/fixtures/cox_survival.R (MIT, commit e917a68), with timefix = FALSE stated (M-23).
#
# Usage (generate.py runs it): Rscript --vanilla survival.R <staging> <library> <case-id> ...
# It runs with only the isolated library and base R on the library path, checks that survival,
# glmnet, and jsonlite load from it at the locked versions, and writes <staging>/<id>/survival.json
# with doubles as hexadecimal strings ("%a"), which convert.R reads back exactly.
args <- commandArgs(trailingOnly = TRUE)
staging <- args[[1]]
library_dir <- normalizePath(args[[2]], winslash = "/")
ids <- args[-(1:2)]
.libPaths(c(library_dir, .Library))
suppressPackageStartupMessages({
  library(survival)
  library(glmnet)
  library(jsonlite)
})
lock <- read_json(file.path(dirname(library_dir), "cox-library-lock.json"))
for (p in c("survival", "glmnet", "jsonlite", "Matrix")) {
  if (!startsWith(normalizePath(find.package(p), winslash = "/"), library_dir)) {
    stop(p, " does not load from the isolated library ", library_dir, call. = FALSE)
  }
}
for (p in names(lock$engines)) {
  if (packageVersion(p) != package_version(lock$engines[[p]])) stop(p, " is not at the locked version", call. = FALSE)
}

ties_methods <- c("breslow", "efron")
hexes <- function(v) sprintf("%a", as.numeric(v))
packed <- function(m) {
  m <- as.matrix(m)
  hexes(unlist(lapply(seq_len(nrow(m)), function(i) m[i, i:ncol(m)])))
}
read_case <- function(case_dir) {
  definition <- read_json(file.path(case_dir, "case.json"), simplifyVector = TRUE)
  input <- read_json(file.path(case_dir, "input.json"))
  columns <- lapply(input$names, function(name) {
    v <- unlist(input$columns[[name]])
    if (identical(input$types[[name]], "double")) as.numeric(v) else as.integer(v)
  })
  names(columns) <- unlist(input$names)
  list(definition = definition, data = as.data.frame(columns, optional = TRUE),
       pprof_py = read_json(file.path(case_dir, "pprof_py.json"), simplifyVector = TRUE))
}
control_of <- function(label, timefix = FALSE) {
  if (label == "tight") coxph.control(eps = 1e-11, iter.max = 100, timefix = timefix)
  else coxph.control(timefix = timefix)
}

# Cox cases ------------------------------------------------------------------------------------

cox_formula <- function(def, response = NULL) {
  rhs <- paste(def$features, collapse = " + ")
  if (isTRUE(def$stratified)) rhs <- paste(rhs, "+ strata(stratum)")
  if (isTRUE(def$offset)) rhs <- paste(rhs, "+ offset(offset)")
  lhs <- response
  if (is.null(lhs)) lhs <- if (isTRUE(def$truncated)) "Surv(entry, time, event)" else "Surv(time, event)"
  as.formula(paste(lhs, "~", rhs))
}

fit_record <- function(fit) {
  list(coef = hexes(coef(fit)), se = hexes(sqrt(diag(vcov(fit)))), covariance = packed(vcov(fit)),
       loglik = hexes(fit$loglik[2]), loglik_null = hexes(fit$loglik[1]), iterations = fit$iter)
}

cox_outputs <- function(case) {
  def <- case$definition
  d <- case$data
  # Rows with zero weight are left out of the fits (M-25), as survival refuses them.
  kept <- if (isTRUE(def$weighted)) which(d$weight > 0) else seq_len(nrow(d))
  fd <- d[kept, , drop = FALSE]
  # coxph() evaluates weights and clusters in the data, so they are columns of it.
  fd$.w <- if (isTRUE(def$weighted)) fd$weight else rep(1, nrow(fd))
  fd$.cluster <- if ("cluster" %in% names(fd)) fd$cluster else fd$id %% 40
  fd$.row_cluster <- fd$id
  f <- cox_formula(def)
  environment(f) <- environment()  # coxph() evaluates data, weights, and clusters in the formula's environment
  p <- length(def$features)
  out <- list(kept_rows = kept - 1L)
  for (ties in ties_methods) {
    entry <- list()
    for (label in c("default", "tight")) {
      fit <- coxph(f, data = fd, weights = .w, ties = ties, robust = FALSE, control = control_of(label))
      entry[[label]] <- fit_record(fit)
      if (isTRUE(def$near_ties)) {
        merged <- coxph(f, data = fd, weights = .w, ties = ties, robust = FALSE, control = control_of(label, TRUE))
        entry[[paste0(label, "_timefix")]] <- fit_record(merged)
      }
      if (label == "tight") {
        bh <- basehaz(fit, centered = FALSE)
        bh_strata <- if (isTRUE(def$stratified)) as.integer(sub("^stratum=", "", bh$strata)) else NULL
        entry$basehaz <- list(time = hexes(bh$time), hazard = hexes(bh$hazard), stratum = bh_strata)
        if (!isFALSE(def$residuals)) {
          sc <- as.matrix(residuals(fit, type = "score"))
          db <- as.matrix(residuals(fit, type = "dfbeta"))
          fr <- coxph(f, data = fd, weights = .w, ties = ties, robust = TRUE, cluster = .row_cluster,
                      control = control_of(label))
          fc <- coxph(f, data = fd, weights = .w, ties = ties, robust = TRUE, cluster = .cluster,
                      control = control_of(label))
          entry$residuals <- list(
            martingale = hexes(residuals(fit, type = "martingale")),
            score = lapply(seq_len(p), function(j) hexes(sc[, j])),
            dfbeta = lapply(seq_len(p), function(j) hexes(db[, j])),
            robust_per_row = packed(fr$var), robust_clustered = packed(fc$var), naive_covariance = packed(fr$naive.var)
          )
        }
        entry$expected <- national_expected(def, d, coef(fit), case$pprof_py[[ties]]$measures$beta)
      }
    }
    for (name in c("beta_zero", "beta_fixed")) {
      beta <- if (name == "beta_zero") rep(0, p) else def$fixed_beta
      fit0 <- suppressWarnings(coxph(f, data = fd, weights = .w, ties = ties, init = beta, robust = FALSE,
                                     control = coxph.control(iter.max = 0, timefix = FALSE)))
      entry[[name]] <- list(loglik = hexes(fit0$loglik[1]),
                            score = hexes(colSums(as.matrix(residuals(fit0, type = "score")) * fd$.w)),
                            information = packed(solve(fit0$var)))
    }
    out[[ties]] <- entry
  }
  out
}

# The national Breslow baseline of the measures (K-136, K-137): all rows, unweighted, unstratified,
# with eta = x'beta + offset as an offset, at R's tight beta and at pprof_py's; per row and per provider.
national_expected <- function(def, d, beta_r, beta_py) {
  provider <- if (isTRUE(def$stratified)) d$stratum else d$id %% 10
  x <- as.matrix(d[, def$features, drop = FALSE])
  offset <- if (isTRUE(def$offset)) d$offset else rep(0, nrow(d))
  response <- if (isTRUE(def$truncated)) Surv(d$entry, d$time, d$event) else Surv(d$time, d$event)
  one <- function(beta) {
    # Shifted by its maximum, as K-136's r_i = exp(eta_i - max eta): the expected counts do not change,
    # and exp() cannot overflow when the linear predictor is large (D-64).
    eta <- drop(x %*% as.numeric(beta)) + offset
    eta <- eta - max(eta)
    fit <- coxph(response ~ offset(eta), ties = "breslow", control = coxph.control(timefix = FALSE))
    e <- predict(fit, type = "expected")
    sums <- tapply(e, provider, sum)
    list(row = hexes(e), provider = as.integer(names(sums)), provider_expected = hexes(sums))
  }
  list(at_r_beta = one(beta_r), at_pprof_py_beta = one(vapply(beta_py, function(h) as.numeric(h), 0)))
}

# Competing risks ------------------------------------------------------------------------------

competing_outputs <- function(case) {
  def <- case$definition
  d <- case$data
  d$.row <- seq_len(nrow(d)) - 1L
  causes <- sort(setdiff(unique(d$event), 0L))
  x_terms <- paste(def$features, collapse = " + ")
  out <- list()
  for (ties in ties_methods) {
    cause_specific <- list()
    for (cause in causes) {
      template <- if (isTRUE(def$truncated)) "Surv(entry, time, event == %d)" else "Surv(time, event == %d)"
      response <- sprintf(template, cause)
      f <- as.formula(paste(response, "~", x_terms, "+ strata(stratum)"))
      cause_specific[[as.character(cause)]] <- lapply(c(default = "default", tight = "tight"), function(label) {
        fit_record(coxph(f, data = d, ties = ties, control = control_of(label)))
      })
    }
    fine_gray <- list()
    for (cause in causes) {
      for (stratified in c(TRUE, FALSE)) {
        key <- paste0(cause, if (stratified) "" else "_unstratified")
        fine_gray[[key]] <- fine_gray_record(def, d, ties, cause, stratified, x_terms)
      }
    }
    out[[ties]] <- list(cause_specific = cause_specific, fine_gray = fine_gray)
  }
  out
}

fine_gray_record <- function(def, d, ties, cause, stratified, x_terms) {
  d$.status <- factor(d$event, levels = c(0L, sort(setdiff(unique(d$event), 0L))))
  response <- if (isTRUE(def$truncated)) "Surv(entry, time, .status)" else "Surv(time, .status)"
  # finegray() carries the plain terms into its output but not the strata() variable, which the
  # stratified fit needs, so stratum is also a plain term.
  rhs <- paste(x_terms, "+ .row + id + stratum", if (stratified) "+ strata(stratum)" else "")
  fg <- finegray(as.formula(paste(response, "~", rhs)), data = d, etype = as.character(cause), id = id,
                 timefix = FALSE)
  f <- as.formula(paste("Surv(fgstart, fgstop, fgstatus) ~", x_terms, if (stratified) "+ strata(stratum)" else ""))
  fits <- lapply(c(default = "default", tight = "tight"), function(label) {
    coxph(f, data = fg, weights = fgwt, cluster = id, ties = ties, control = control_of(label))
  })
  fit <- fits$tight
  profiles <- lapply(case_profiles(length(def$features)), function(v) v)
  newdata <- as.data.frame(do.call(rbind, profiles))
  names(newdata) <- def$features
  incidence <- list()
  strata_used <- if (stratified) sort(unique(d$stratum))[1:2] else NA
  for (s in strata_used) {
    nd <- newdata
    if (stratified) nd$stratum <- s
    # One curve per profile: survfit()'s layout for several rows depends on the strata.
    curves <- lapply(seq_len(nrow(nd)), function(i) survfit(fit, newdata = nd[i, , drop = FALSE]))
    incidence[[length(incidence) + 1]] <- list(
      stratum = if (stratified) s else NULL, time = hexes(curves[[1]]$time),
      cumulative_incidence = lapply(curves, function(sf) hexes(1 - sf$surv))
    )
  }
  c(list(expanded = list(row = fg$.row, start = hexes(fg$fgstart), stop = hexes(fg$fgstop), status = fg$fgstatus,
                         weight = hexes(fg$fgwt))),
    lapply(fits, function(fit) {
      list(coef = hexes(coef(fit)), covariance = packed(fit$var), naive_covariance = packed(fit$naive.var),
           loglik = hexes(fit$loglik[2]), loglik_null = hexes(fit$loglik[1]), iterations = fit$iter)
    }),
    list(cumulative_incidence = incidence))
}

case_profiles <- function(p) {
  rows <- list(c(0, 0, 0, 0, 0), c(0.5, -0.25, 0.125, 0.25, -0.5), c(-1, 0.75, 0.5, -0.25, 0.125))
  lapply(rows, function(r) r[seq_len(p)])
}

# Penalized cases ------------------------------------------------------------------------------

penalized_outputs <- function(case) {
  def <- case$definition
  d <- case$data
  x <- as.matrix(d[, def$features, drop = FALSE])
  surv <- if ("start" %in% names(d)) Surv(d$start, d$stop, d$event) else Surv(d$stop, d$event)
  strata <- if ("provider" %in% names(d)) d$provider else rep(0L, nrow(d))
  y <- if ("provider" %in% names(d)) stratifySurv(surv, d$provider) else surv
  w <- if ("weight" %in% names(d)) d$weight else rep(1, nrow(d))
  offset_name <- intersect(c("offset1", "log_exposure"), names(d))
  o <- if (length(offset_name)) d[[offset_name]] else rep(0, nrow(d))
  pf <- if (!is.null(def$penalty_factor)) as.numeric(def$penalty_factor) else rep(1, ncol(x))
  out <- list()
  for (ties in ties_methods) {
    entry <- list()
    for (alpha in def$alphas) {
      key <- paste0("alpha_", format(alpha))
      grid <- as.numeric(case$pprof_py[[ties]][[key]]$path$lambda)
      fit <- glmnet_path(x, y, w, o, pf, alpha, grid, ties)
      entry[[key]] <- list(path = list(lambda = hexes(fit$lambda), coef_path = path_rows(fit),
                                       deviance_ratio_path = hexes(fit$dev.ratio), nulldev = hexes(fit$nulldev),
                                       df = fit$df, passes = fit$npasses))
      if (isTRUE(def$cv) && alpha == 1) {
        fold <- as.integer(case$pprof_py$fold)
        entry[[key]]$cv <- cross_validation(x, y, w, o, pf, alpha, grid, ties, fold, d$event, surv, strata)
      }
    }
    out[[ties]] <- entry
  }
  out
}

glmnet_path <- function(x, y, w, o, pf, alpha, grid, ties) {
  glmnet(x, y, family = "cox", weights = w, offset = o, alpha = alpha, lambda = grid, penalty.factor = pf,
         standardize = TRUE, cox.ties = ties, control = list(thresh = 1e-12, maxit = 1e5, fdev = 0, devmax = 1))
}

path_rows <- function(fit) {
  b <- as.matrix(fit$beta)
  lapply(seq_len(ncol(b)), function(j) hexes(b[, j]))
}

# pprof_py's deviance (its utils/deviance.py): 2 (lsat - loglik), with the saturated term in the
# Breslow form -sum(w_t log w_t) over the tied event weights of each stratum, whatever the tie
# method (glmnet 4.1-8's coxnet.deviance2), and the partial log-likelihood of the tie method, here
# from survival. glmnet 5.x's coxnet.deviance() agrees with it for Breslow ties but uses another
# saturated term for Efron ties (dev/reference/cox/README.md), so it is not used here.
pprof_py_deviance <- function(eta, surv, w, strata, ties) {
  event <- surv[, ncol(surv)] == 1
  stop_time <- surv[, ncol(surv) - 1]
  groups <- interaction(strata[event], stop_time[event], drop = TRUE)
  wd <- tapply(w[event], groups, sum)
  wd <- wd[!is.na(wd) & wd > 0]
  loglik <- coxph(surv ~ offset(eta) + strata(strata), weights = w, ties = ties,
                  control = coxph.control(timefix = FALSE))$loglik[1]
  2 * (-sum(wd * log(wd)) - loglik)
}

# pprof_py's cross-validation (K-144) on glmnet's fold paths.
cross_validation <- function(x, y, w, o, pf, alpha, grid, ties, fold, event, surv, strata) {
  k_values <- sort(unique(fold))
  deviance <- matrix(NA_real_, length(k_values), length(grid))
  held_weight <- numeric(length(k_values))
  for (i in seq_along(k_values)) {
    train <- fold != k_values[i]
    fit <- glmnet_path(x[train, , drop = FALSE], y[train], w[train], o[train], pf, alpha, grid, ties)
    b <- as.matrix(fit$beta)
    held_weight[i] <- sum(w[!train] * event[!train])
    for (j in seq_along(grid)) {
      all <- pprof_py_deviance(drop(x %*% b[, j]) + o, surv, w, strata, ties)
      training <- pprof_py_deviance(drop(x[train, , drop = FALSE] %*% b[, j]) + o[train], surv[train], w[train],
                                    strata[train], ties)
      deviance[i, j] <- (all - training) / held_weight[i]
    }
  }
  cvm <- colSums(held_weight * deviance) / sum(held_weight)
  cvsd <- sqrt(colSums(held_weight * sweep(deviance, 2, cvm)^2) / sum(held_weight) / (length(k_values) - 1))
  best <- which.min(cvm)
  list(lambda = hexes(grid), fold_deviance = lapply(seq_along(k_values), function(i) hexes(deviance[i, ])),
       held_weight = hexes(held_weight), cvm = hexes(cvm), cvsd = hexes(cvsd),
       lambda_min = hexes(grid[best]), lambda_1se = hexes(grid[which(cvm <= cvm[best] + cvsd[best])[1]]))
}

# Driver ------------------------------------------------------------------------------------------

for (id in ids) {
  case_dir <- file.path(staging, id)
  case <- read_case(case_dir)
  cat(id, ": survival and glmnet\n", sep = "")
  out <- switch(case$definition$kind,
                cox = cox_outputs(case),
                competing = competing_outputs(case),
                penalized = penalized_outputs(case))
  write_json(out, file.path(case_dir, "survival.json"), auto_unbox = TRUE, digits = NA, null = "null", na = "string",
             pretty = 1)
}
write_json(list(r = R.version.string, platform = R.version$platform, os = utils::osVersion,
                lapack = La_version(), blas = sessionInfo()$BLAS,
                compiler = system2(file.path(R.home("bin"), "R"), c("CMD", "config", "CXX17"), stdout = TRUE),
                packages = lapply(setNames(nm = c("survival", "glmnet", "Matrix", "jsonlite")),
                                  function(p) as.character(packageVersion(p))),
                library = basename(library_dir)),
           file.path(staging, "r_environment.json"), auto_unbox = TRUE, pretty = TRUE)
