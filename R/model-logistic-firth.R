# Firth-corrected logistic fixed-effect models (ARCHITECTURE §B.5, §D, §E): the fit
# function, the call of the C++ engine, and the model object. The class inherits from
# pprof_logistic_fe (DEC-004), so the logistic fixed-effect methods, contract methods, and
# inference capabilities apply to Firth models as pprof 1.0.3's logis_fe methods applied to
# its Firth fits (D-12, signed off 2026-10-04).

#' Fit a Firth-corrected logistic fixed-effect model for provider profiling
#'
#' Fits the model logit P(y = 1) = gamma_i + z'beta for an observation of provider i, with
#' one fixed effect gamma_i per provider and covariate coefficients beta, by maximizing
#' Firth's penalized log-likelihood l + log det(I) / 2, where I is the information matrix.
#' The penalty removes the first-order bias of maximum likelihood and keeps the effects of
#' providers with no events or only events finite. The algorithm reproduces the iterations
#' of pprof 1.0.3's `logis_firth()` exactly: full Newton steps on the Firth-modified score,
#' whose residuals are y - p + h (1/2 - p) with the hat values h, without a line search,
#' and after every update the provider effects are clamped to within `effect_bound` of
#' their median.
#'
#' Every provider starts at the logit of the overall event rate and every coefficient at 0.
#' The fit stops when the largest absolute change of a coefficient is at most `tol`, or
#' after `max_iter` iterations, which warns with class `pprof_warning_not_converged`.
#' Providers with fewer than `min_provider_size` complete observations are excluded with a
#' warning.
#'
#' As in pprof 1.0.3, the variances, the log-likelihood, AIC, and BIC are the unpenalized
#' quantities at the Firth estimates, and the tests, intervals, and standardized measures are
#' those of [fit_logistic_fe()]. The penalized log-likelihood is kept as `penalized_loglik`.
#'
#' @inheritParams fit_logistic_fe
#' @param max_iter The iteration limit.
#' @param threads The number of threads. Results do not depend on it.
#' @param verbose Whether to report the screening and the criterion of every iteration.
#'
#' @return A model object of class `c("pprof_logistic_firth", "pprof_logistic_fe",
#'   "pprof_model")` with the fields of [fit_logistic_fe()] models, the penalized
#'   log-likelihood at the estimates (`penalized_loglik`), and convergence diagnostics whose
#'   `history` holds the criterion and the penalized log-likelihood of every iteration.
#'
#' @references
#' Firth D (1993). Bias reduction of maximum likelihood estimates. *Biometrika*, 80(1),
#' 27-38.
#'
#' @inheritSection fit_logistic_fe Provider order
#' @family fitting functions
#' @examples
#' data(ExampleDataBinary)
#' example <- data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID,
#'                       ExampleDataBinary$Z)
#' fit <- fit_logistic_firth(y ~ z1 + z2 + z3 + z4 + z5, example, provider = "hospital")
#' fit$coefficients
#' fit$penalized_loglik
#' @export
fit_logistic_firth <- function(formula, data, provider, max_iter = 1000, tol = 1e-5, effect_bound = 10,
                               min_provider_size = 10, keep_data = FALSE, threads = 1, verbose = FALSE) {
  call <- match.call()
  check_count(max_iter, "max_iter", min = 1)
  check_number(tol, "tol", lower = 0, open = TRUE)
  check_number(effect_bound, "effect_bound", lower = 0, open = TRUE)
  check_count(min_provider_size, "min_provider_size", min = 1)
  check_flag(keep_data, "keep_data")
  check_threads(threads)
  check_flag(verbose, "verbose")

  prepared <- data_prepare(formula, data, provider, min_provider_size = min_provider_size, event_counts = TRUE)
  logistic_fe_check_data(prepared)
  logistic_fe_report_screening(prepared, min_provider_size, verbose)
  logistic_fe_check_rank(prepared)
  spec <- list(
    family = "logistic_firth", max_iter = max_iter, tol = tol, effect_bound = effect_bound,
    min_provider_size = min_provider_size, keep_data = keep_data
  )
  estimates <- logistic_firth_estimate(prepared, spec, threads)
  logistic_firth_report_convergence(estimates$convergence, verbose)
  new_pprof_logistic_firth(prepared, estimates, spec, call = call, keep_data = keep_data)
}

# Runs the Firth engine from the starting values of K-10, then computes the variances and
# fit statistics at the Firth estimates as the reference does (K-34, R/logis_firth.R:206-262).
# The stopping rule is fixed to the coefficients criterion (K-33).
logistic_firth_estimate <- function(prepared, spec, threads) {
  response <- prepared$response
  design <- prepared$design
  sizes <- as.integer(prepared$providers$n_obs[prepared$providers$included])
  fit <- logistic_fe_engine_call(
    "Firth",
    cpp_logistic_firth(as.numeric(response), design, sizes, logistic_fe_start(response, length(sizes)),
                       rep(0, ncol(design)), as.integer(spec$max_iter), spec$tol, spec$effect_bound,
                       as.integer(threads))
  )
  estimates <- logistic_fe_fit_statistics(prepared, fit$gamma, fit$beta)
  estimates$penalized_loglik <- fit$penalized_loglik
  estimates$convergence <- list(
    iterations = fit$iterations, converged = fit$converged, criterion = fit$criterion, stop_rule = "coefficients",
    tol = spec$tol, max_iter = spec$max_iter, penalized_loglik_initial = fit$penalized_loglik_initial,
    history = fit$history
  )
  estimates
}

# Non-convergence warns whatever `verbose` is (DEC-008); `verbose` adds every iteration's
# criterion, formatted as the reference printed it.
logistic_firth_report_convergence <- function(convergence, verbose) {
  if (!isTRUE(convergence$converged)) {
    warn_not_converged(
      sprintf("Firth reached the iteration limit after %d iterations (criterion %s, tol %s).",
              convergence$iterations, format(convergence$criterion), format(convergence$tol)),
      iterations = convergence$iterations, criterion = convergence$criterion
    )
  }
  if (isTRUE(verbose)) {
    history <- convergence$history
    for (k in seq_len(nrow(history))) {
      inform_message(verbose, sprintf("Iteration %d: criterion %s.", k,
                                      formatC(history[k, "coefficients"], format = "e", digits = 3)))
    }
    outcome <- if (isTRUE(convergence$converged)) "converged" else "stopped"
    inform_message(verbose, sprintf("Firth %s after %d iterations.", outcome, convergence$iterations))
  }
}

# The model object (ARCHITECTURE §D.1): the fields of logistic fixed-effect models and the
# penalized log-likelihood.
new_pprof_logistic_firth <- function(data, estimates, spec, call = NULL, keep_data = FALSE) {
  model <- logistic_fe_model(data, estimates, spec, call, keep_data,
                             class = c("pprof_logistic_firth", "pprof_logistic_fe"),
                             penalized_loglik = estimates$penalized_loglik)
  validate_pprof_logistic_firth(model)
  model
}

validate_pprof_logistic_firth <- function(x) {
  fail <- function(what) abort_invalid_input(sprintf("Invalid `pprof_logistic_firth` object: %s.", what), arg = "x")
  if (!inherits(x, "pprof_logistic_firth")) fail("not of class `pprof_logistic_firth`")
  validate_pprof_logistic_fe(x, family = "logistic_firth")
  if (!is.numeric(x$penalized_loglik) || length(x$penalized_loglik) != 1L) {
    fail("`penalized_loglik` must be a number")
  }
  invisible(x)
}
