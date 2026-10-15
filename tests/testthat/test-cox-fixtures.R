# The Cox reference fixtures (dev/reference/cox/README.md; DEC-093) and the engines behind them.
# Every fixture matches its manifest, and the installed survival, and glmnet when it is installed at
# 5.0 or later, reproduce the fixtures' engine outputs within the calibrated tiers on every
# platform (COXPH_DESIGN §G.5; validation/cox-calibration-report.md). The package's own Cox code is
# compared with the fixtures from Phase C2 on.

# The upper triangle row by row, unnamed, as the fixtures store covariances.
packed_upper <- function(m) unname(unlist(lapply(seq_len(nrow(m)), function(i) m[i, i:ncol(m)])))

for (set in c("core", "full")) {
  test_that(sprintf("the %s Cox fixtures match their manifest", set), {
    manifest <- cox_manifest(set)
    if (is.null(manifest)) skip(sprintf("no %s Cox fixture set here", set))
    if (identical(set, "full")) skip_on_cran()
    dir <- cox_fixture_dir(set)
    expect_setequal(sub("\\.rds$", "", list.files(dir, pattern = "\\.rds$")), names(manifest$cases))
    for (id in names(manifest$cases)) {
      entry <- manifest$cases[[id]]
      expect_identical(unname(tools::md5sum(file.path(dir, entry$file))), entry$md5, info = id)
      fx <- cox_fixture(id, set)
      expect_named(fx, c("format_version", "case", "input", "pprof_py", "survival"))
      expect_identical(fx$format_version, 1L, info = id)
      expect_identical(fx$case$id, id)
      expect_identical(nrow(fx$input), as.integer(entry$rows), info = id)
      expect_true(all(c("breslow", "efron") %in% names(fx$pprof_py)), info = id)
    }
  })
}

test_that("the installed survival reproduces the core Cox fixtures' tight fits", {
  skip_if_not_installed("survival", minimum_version = "3.5-8")
  manifest <- cox_manifest("core")
  if (is.null(manifest)) skip("no core Cox fixture set here")
  for (id in names(manifest$cases)) {
    fx <- cox_fixture(id)
    fits <- list()
    if (identical(fx$case$kind, "cox")) {
      for (ties in c("breslow", "efron")) fits[[ties]] <- list(fx = fx, reference = fx$survival[[ties]]$tight)
    } else if (identical(fx$case$kind, "competing")) {
      # The cause-specific fits: one cause, the others censored, stratified by provider (M-35).
      for (ties in c("breslow", "efron")) {
        for (cause in names(fx$survival[[ties]]$cause_specific)) {
          recoded <- fx
          recoded$input$event <- as.integer(fx$input$event == as.integer(cause))
          recoded$case$stratified <- TRUE
          fits[[paste(ties, cause)]] <- list(fx = recoded, ties = ties,
                                             reference = fx$survival[[ties]]$cause_specific[[cause]]$tight)
        }
      }
    }
    for (key in names(fits)) {
      ties <- if (is.null(fits[[key]]$ties)) key else fits[[key]]$ties
      fit <- cox_survival_tight_fit(fits[[key]]$fx, ties)
      reference <- fits[[key]]$reference
      label <- paste(id, key)
      expect_null(reference_compare(unname(stats::coef(fit)), reference$coef, reference_tolerance("cox_coefficient")),
                  label = paste(label, "coefficients"))
      expect_null(reference_compare(fit$loglik[2], reference$loglik, reference_tolerance("cox_function")),
                  label = paste(label, "log-likelihood"))
      expect_null(reference_compare(packed_upper(stats::vcov(fit)), reference$covariance,
                                    reference_tolerance("cox_variance")), label = paste(label, "covariance"))
    }
  }
})

test_that("an installed glmnet 5.0 or later reproduces the core penalized fixtures' paths", {
  skip_if_not_installed("survival", minimum_version = "3.5-8")
  skip_if_not_installed("glmnet", minimum_version = "5.0")
  manifest <- cox_manifest("core")
  if (is.null(manifest)) skip("no core Cox fixture set here")
  for (id in names(manifest$cases)) {
    fx <- cox_fixture(id)
    if (!identical(fx$case$kind, "penalized")) next
    d <- fx$input
    x <- as.matrix(d[, unlist(fx$case$features), drop = FALSE])
    surv <- if ("start" %in% names(d)) survival::Surv(d$start, d$stop, d$event) else survival::Surv(d$stop, d$event)
    y <- if ("provider" %in% names(d)) glmnet::stratifySurv(surv, d$provider) else surv
    w <- if ("weight" %in% names(d)) d$weight else rep(1, nrow(d))
    offset_name <- intersect(c("offset1", "log_exposure"), names(d))
    o <- if (length(offset_name)) d[[offset_name]] else rep(0, nrow(d))
    pf <- if (is.null(fx$case$penalty_factor)) rep(1, ncol(x)) else as.numeric(unlist(fx$case$penalty_factor))
    for (ties in c("breslow", "efron")) {
      for (key in names(fx$survival[[ties]])) {
        reference <- fx$survival[[ties]][[key]]$path
        alpha <- as.numeric(sub("^alpha_", "", key))
        fit <- glmnet::glmnet(x, y, family = "cox", weights = w, offset = o, alpha = alpha, lambda = reference$lambda,
                              penalty.factor = pf, standardize = TRUE, cox.ties = ties,
                              control = list(thresh = 1e-12, maxit = 1e5, fdev = 0, devmax = 1))
        path <- lapply(seq_len(ncol(fit$beta)), function(j) as.numeric(fit$beta[, j]))
        expect_null(reference_compare(path, reference$coef_path, reference_tolerance("penalized_path")),
                    label = paste(id, ties, key))
      }
    }
  }
})

# Phase C5: survival's Fine-Gray records, made by finegray() (case weights multiplied after the call, which
# survival 3.8-12's weights argument misapplies after the first stratum) and coxph(cluster = id) on the
# expansion's rows of positive weight (dev/reference/cox/survival.R).
test_that("the installed survival reproduces the core competing-risk fixtures' Fine-Gray records", {
  skip_if_not_installed("survival", minimum_version = "3.5-8")
  manifest <- cox_manifest("core")
  if (is.null(manifest)) skip("no core Cox fixture set here")
  for (id in names(manifest$cases)) {
    fx <- cox_fixture(id)
    if (!identical(fx$case$kind, "competing")) next
    d <- fx$input
    d$.row <- seq_len(nrow(d)) - 1L
    d$.status <- factor(d$event, levels = c(0L, sort(setdiff(unique(d$event), 0L))))
    weighted <- isTRUE(fx$case$weighted)
    x_terms <- paste(unlist(fx$case$features), collapse = " + ")
    lhs <- if (isTRUE(fx$case$truncated)) "Surv(entry, time, .status)" else "Surv(time, .status)"
    env <- list2env(list(Surv = survival::Surv, strata = survival::strata), parent = globalenv())
    for (ties in c("breslow", "efron")) {
      for (key in names(fx$survival[[ties]]$fine_gray)) {
        label <- paste(id, ties, key)
        stratified <- !endsWith(key, "_unstratified")
        rhs <- paste(x_terms, "+ .row + id + stratum", if (stratified) "+ strata(stratum)" else "")
        fg <- survival::finegray(stats::as.formula(paste(lhs, "~", rhs), env = env), data = d,
                                 etype = sub("_unstratified", "", key, fixed = TRUE), id = id, timefix = FALSE)
        if (weighted) fg$fgwt <- fg$fgwt * d$weight[fg$.row + 1L]
        reference <- fx$survival[[ties]]$fine_gray[[key]]
        expect_null(reference_compare(fg$fgwt, reference$expanded$weight, reference_tolerance("closed_form")),
                    label = paste(label, "expanded weights"))
        fit_rows <- fg[fg$fgwt > 0, ]
        f <- stats::as.formula(paste("Surv(fgstart, fgstop, fgstatus) ~", x_terms,
                                     if (stratified) "+ strata(stratum)" else ""), env = env)
        fit <- survival::coxph(f, data = fit_rows, weights = fgwt, cluster = id, ties = ties,
                               control = survival::coxph.control(eps = 1e-11, iter.max = 100, timefix = FALSE))
        expect_null(reference_compare(unname(stats::coef(fit)), reference$tight$coef,
                                      reference_tolerance("cox_coefficient")), label = paste(label, "coefficients"))
        expect_null(reference_compare(packed_upper(fit$var), reference$tight$covariance,
                                      reference_tolerance("cox_variance")), label = paste(label, "robust covariance"))
        expect_null(reference_compare(packed_upper(fit$naive.var), reference$tight$naive_covariance,
                                      reference_tolerance("cox_variance")), label = paste(label, "model-based"))
        expect_null(reference_compare(fit$loglik[2], reference$tight$loglik, reference_tolerance("cox_function")),
                    label = paste(label, "log-likelihood"))
      }
    }
  }
})
