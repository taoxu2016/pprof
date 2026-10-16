# The elastic-net Cox model against the penalized Cox fixtures (the CoxPH brief's §6 A; COXPH_C4_PLAN §4.2):
# pprof_py's grids, paths, and cross-validation (with its fold IDs, D-61), and glmnet's paths as the
# generator recorded them, on the core set's case always and the full set's when present, both tie methods,
# every alpha and setting. The tiers are DEC-097's and DEC-116's.

skip_if_not_installed("glmnet", minimum_version = "5.0")

# The cases of a fixture set whose kind is "penalized".
cox_penalized_cases <- function(set) {
  manifest <- cox_manifest(set)
  if (is.null(manifest)) return(character())
  names(Filter(function(entry) identical(entry$kind, "penalized"), manifest$cases))
}

# The keys of a case's records: its alphas ("alpha_1") or its settings, for a tie method.
cox_penalized_keys <- function(fx, ties) names(fx$pprof_py[[ties]])

compare_penalized_case <- function(fx, label_prefix) {
  for (ties in c("breslow", "efron")) {
    for (key in cox_penalized_keys(fx, ties)) {
      py <- fx$pprof_py[[ties]][[key]]$path
      r_side <- fx$survival[[ties]][[key]]$path
      label <- paste(label_prefix, ties, key)
      expected_end <- length(unlist(r_side$lambda)) < length(unlist(py$lambda))
      warned <- character()
      fit <- withCallingHandlers(cox_penalized_case_fit(fx, ties, key), warning = function(w) {
        warned <<- c(warned, class(w)[1])
        invokeRestart("muffleWarning")
      })
      # The grid (K-143): lambda_max and the scales always; the grid itself, exactly when it was given.
      expect_cox_tier(fit$lambda_max, py$lambda_max, "closed_form", paste(label, "lambda_max"))
      expect_cox_tier(unname(fit$column_scale), as.numeric(unlist(py$column_scale)), "closed_form",
                      paste(label, "column scales"))
      py_grid <- as.numeric(unlist(py$lambda))
      reached <- length(fit$lambda)
      expect_cox_tier(fit$lambda, py_grid[seq_len(reached)], "closed_form", paste(label, "grid"))
      expect_identical(unname(fit$penalty_factor), as.numeric(unlist(py$penalty_factor)),
                       label = paste(label, "factors"))
      expect_identical(fit$degenerate, as.character(unlist(r_side$degenerate)), label = paste(label, "degenerate"))
      expect_identical("pprof_warning_degenerate_covariates" %in% warned, length(fit$degenerate) > 0L,
                       label = paste(label, "degenerate warning"))
      # Paths: against pprof_py, and against glmnet as the generator called it, at the points reached.
      py_path <- cox_penalized_path(py$coef_path)
      r_path <- cox_penalized_path(r_side$coef_path)
      if (!expected_end) {
        expect_identical(reached, length(py_grid), label = paste(label, "points reached"))
        expect_cox_tier(unname(fit$coefficient_path), py_path, "penalized_path", paste(label, "path against pprof_py"))
        expect_identical(cox_active_set_differences(fit$coefficient_path, py_path), 0L,
                         label = paste(label, "active sets (D-72)"))
      } else {
        # D-78: glmnet stops (Breslow) or fails (Efron) where pprof_py converges; the path ends where the
        # generator's glmnet path ends, with a warning, and agrees with pprof_py's to the 30th point.
        expect_identical(reached, as.integer(r_side$reached), label = paste(label, "points reached (D-78)"))
        expect_true("pprof_warning_not_converged" %in% warned, label = paste(label, "warning (D-78)"))
        expect_identical(fit$convergence$converged, FALSE)
        first <- seq_len(30L)
        expect_cox_tier(unname(fit$coefficient_path[, first]), py_path[, first], "penalized_path",
                        paste(label, "path to the 30th"))
      }
      expect_cox_tier(unname(fit$coefficient_path), r_path, "penalized_path", paste(label, "path against glmnet"))
    }
  }
}

compare_penalized_cross_validation <- function(fx, label_prefix) {
  folds <- as.integer(unlist(fx$pprof_py$fold))
  for (ties in c("breslow", "efron")) {
    py <- fx$pprof_py[[ties]]$alpha_1$cv
    if (is.null(py)) next
    label <- paste(label_prefix, ties)
    fit <- cox_penalized_case_fit(fx, ties, "alpha_1", keep_data = TRUE)
    selected <- select_lambda(fit, folds = folds)
    cv <- selected$cross_validation
    py_grid <- as.numeric(unlist(py$lambda))
    expect_cox_tier(cv$cvm, as.numeric(unlist(py$cvm)), "penalized_path", paste(label, "cvm"))
    expect_cox_tier(cv$cvsd, as.numeric(unlist(py$cvsd)), "penalized_path", paste(label, "cvsd"))
    expect_identical(match(c(cv$lambda_min, cv$lambda_1se), fit$lambda),
                     match(as.numeric(c(py$lambda_min, py$lambda_1se)), py_grid), label = paste(label, "selection"))
    expect_identical(cv$n_folds_used, as.integer(unlist(py$folds_used)), label = paste(label, "folds used"))
    expect_cox_tier(unname(selected$coefficients), as.numeric(unlist(py$coef)), "penalized_path",
                    paste(label, "selected coefficients"))
    # Against the generator's R side on pprof_py's own grid: the same glmnet fold paths, with each fold's
    # deviances from survival's partial likelihood per lambda (dev/reference/cox/survival.R).
    r_side <- fx$survival[[ties]]$alpha_1$cv
    on_grid <- select_lambda(cox_penalized_case_fit(fx, ties, "alpha_1", lambda = py_grid, keep_data = TRUE),
                             folds = folds)$cross_validation
    expect_cox_tier(on_grid$fold_deviance, t(cox_penalized_path(r_side$fold_deviance)), "closed_form",
                    paste(label, "fold deviances"))
    expect_cox_tier(on_grid$cvm, as.numeric(unlist(r_side$cvm)), "closed_form",
                    paste(label, "cvm against glmnet and survival"))
    expect_cox_tier(on_grid$cvsd, as.numeric(unlist(r_side$cvsd)), "closed_form",
                    paste(label, "cvsd against glmnet and survival"))
    # Sums of the case weights, which R's sum() accumulates in long double on x86_64 and in double on arm64,
    # where they can differ from the recorded ones in the last bit (DEC-141).
    expect_cox_tier(on_grid$held_out_weight, as.numeric(unlist(r_side$held_weight)), "closed_form",
                    paste(label, "held-out weights"))
  }
}

test_that("penalized paths of the core Cox fixtures match pprof_py's and glmnet's", {
  cases <- cox_penalized_cases("core")
  if (!length(cases)) skip("no core Cox fixture set here")
  for (id in cases) compare_penalized_case(cox_fixture(id), id)
})

test_that("penalized paths and cross-validation of the full Cox fixtures match pprof_py's and glmnet's", {
  skip_on_cran()
  cases <- cox_penalized_cases("full")
  if (!length(cases)) skip("no full Cox fixture set here")
  for (id in cases) {
    fx <- cox_fixture(id, "full")
    compare_penalized_case(fx, id)
    if (isTRUE(fx$case$cv)) compare_penalized_cross_validation(fx, id)
  }
})

test_that("glmnet's first point has exact zeros where pprof_py's has 1e-12 (D-72)", {
  skip_on_cran()
  if (!"penalized-combined" %in% cox_penalized_cases("full")) skip("no full Cox fixture set here")
  fx <- cox_fixture("penalized-combined", "full")
  for (ties in c("breslow", "efron")) {
    fit <- cox_penalized_case_fit(fx, ties, "alpha_1")
    py_first <- as.numeric(unlist(fx$pprof_py[[ties]]$alpha_1$path$coef_path[[1]]))
    expect_identical(unname(fit$coefficient_path[c("x2", "x3"), 1]), c(0, 0))
    expect_gt(sum(py_first[2:3] != 0), 0L)
    expect_lt(max(abs(py_first[2:3])), 1e-10)
  }
})
