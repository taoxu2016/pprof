# Live comparison of the new C++ core with the reference's routines while both are in the
# package (Phase 3 plan, step 1): on seeded random data, each new adapter must reproduce its
# old counterpart bitwise, including the iteration count, or fail where it fails.
#
# Temporary: remove each block together with the routine it compares against, the engines
# and Modified_score() at the switch to the compatibility wrappers, logis_fe_var() and
# computeDirectExp() when logis_firth() and the logistic RE/CRE methods are rewritten.
local_strict_mode()

legacy_seeds <- 20261002 + 1:12

legacy_outcome <- function(expr) {
  tryCatch(expr, error = function(e) structure(list(message = conditionMessage(e)), class = "legacy_error"))
}

legacy_engine <- function(routine, inputs, stop, backtrack, threads) {
  output <- utils::capture.output(fit <- legacy_outcome(routine(inputs, stop, backtrack, threads)))
  if (inherits(fit, "legacy_error")) return(fit)
  list(gamma = as.numeric(fit$gamma), beta = as.numeric(fit$beta), iterations = reference_parse_iterations(output))
}

legacy_serbin <- function(inputs, stop, backtrack, threads) {
  logis_BIN_fe_prov(as.matrix(inputs$response), inputs$design, inputs$sizes, inputs$gamma, inputs$beta,
                    threads = threads, tol = inputs$tol, max_iter = inputs$max_iter, bound = inputs$bound,
                    message = TRUE, backtrack = backtrack, stop = stop)
}

legacy_ban <- function(inputs, stop, backtrack, threads) {
  logis_fe_prov(as.matrix(inputs$response), inputs$design, inputs$sizes, inputs$gamma, inputs$beta,
                backtrack = as.integer(backtrack), max_iter = inputs$max_iter, bound = inputs$bound,
                tol = inputs$tol, message = TRUE, stop = stop)
}

expect_same_fit <- function(new, old, label) {
  if (inherits(old, "legacy_error")) {
    expect_true(inherits(new, "legacy_error"), label = paste(label, "fails like the reference"))
    return(invisible())
  }
  expect_false(inherits(new, "legacy_error"), label = paste(label, "returns a fit"))
  expect_identical(new$gamma, old$gamma, label = paste(label, "gamma"))
  expect_identical(new$beta, old$beta, label = paste(label, "beta"))
  expect_identical(new$iterations, old$iterations, label = paste(label, "iterations"))
}

test_that("SerBIN and BAN reproduce the reference routines bitwise", {
  for (seed in legacy_seeds) {
    inputs <- engine_random_inputs(seed)
    for (stop in names(engine_stop_rules)) {
      for (backtrack in c(TRUE, FALSE)) {
        settings <- list(stop_rule = engine_stop_rules[[stop]], backtrack = backtrack)
        for (threads in 1:2) {
          new <- legacy_outcome(engine_fit(utils::modifyList(inputs, settings), threads = threads))
          old <- legacy_engine(legacy_serbin, inputs, stop, backtrack, threads)
          expect_same_fit(new, old, sprintf("SerBIN seed %d stop %s backtrack %s threads %d", seed, stop, backtrack,
                                            threads))
        }
        new <- legacy_outcome(engine_fit(utils::modifyList(inputs, c(settings, method = "BAN"))))
        old <- legacy_engine(legacy_ban, inputs, stop, backtrack, 1L)
        expect_same_fit(new, old, sprintf("BAN seed %d stop %s backtrack %s", seed, stop, backtrack))
      }
    }
  }
})

test_that("a diverging fit reproduces the reference, including its handling of NaN criteria", {
  # Full Newton steps from starting values far from the estimates diverge: the
  # log-likelihood overflows and two of the three criteria become NaN.
  inputs <- engine_dataset_inputs("binary_example", paste0("z", 1:5))
  inputs$gamma[] <- 6
  inputs$beta[] <- 2
  inputs$max_iter <- 20L
  for (stop in names(engine_stop_rules)) {
    settings <- list(stop_rule = engine_stop_rules[[stop]], backtrack = FALSE)
    new <- legacy_outcome(engine_fit(utils::modifyList(inputs, settings)))
    old <- legacy_engine(legacy_serbin, inputs, stop, FALSE, 1L)
    expect_same_fit(new, old, sprintf("diverging SerBIN stop %s", stop))
    new <- legacy_outcome(engine_fit(utils::modifyList(inputs, c(settings, method = "BAN"))))
    old <- legacy_engine(legacy_ban, inputs, stop, FALSE, 1L)
    expect_same_fit(new, old, sprintf("diverging BAN stop %s", stop))
  }
})

test_that("variances, standard score statistics, and direct expectations reproduce the reference bitwise", {
  for (seed in legacy_seeds) {
    inputs <- engine_random_inputs(seed)
    fit <- engine_fit(inputs)
    old_variance <- legacy_outcome(logis_fe_var(inputs$response, inputs$design, inputs$sizes, fit$gamma, fit$beta))
    new_variance <- legacy_outcome(cpp_logistic_variance(inputs$design, inputs$sizes, fit$gamma, fit$beta))
    if (inherits(old_variance, "legacy_error")) {
      expect_true(inherits(new_variance, "legacy_error"),
                  label = sprintf("variance seed %d fails like the reference", seed))
    } else {
      expect_identical(new_variance$beta, old_variance$var.beta, label = sprintf("Var(beta) seed %d", seed))
      expect_identical(new_variance$gamma, as.numeric(old_variance$var.gamma),
                       label = sprintf("Var(gamma) seed %d", seed))
    }

    m <- length(inputs$sizes)
    for (null in c(stats::median(fit$gamma), 0)) {
      for (threads in 1:2) {
        new <- cpp_logistic_score_standard(inputs$response, inputs$design, inputs$sizes, fit$gamma, fit$beta, null,
                                           seq_len(m), threads)
        old <- legacy_outcome(Modified_score(inputs$response, inputs$design, inputs$sizes, fit$gamma, fit$beta, null,
                                             m, seq_len(m) - 1, threads))
        if (inherits(old, "legacy_error")) next
        # The reference keeps only finite statistics (D-04); the new routine keeps every
        # provider in place.
        expect_identical(new$statistic[is.finite(new$statistic)], as.numeric(old),
                         label = sprintf("standard score seed %d null %g threads %d", seed, null, threads))
      }
    }

    linear_predictor <- drop(inputs$design %*% fit$beta)
    for (threads in 1:2) {
      expect_identical(cpp_logistic_direct_expected(fit$gamma, linear_predictor, threads),
                       as.numeric(computeDirectExp(fit$gamma, linear_predictor, threads)),
                       label = sprintf("direct expectations seed %d threads %d", seed, threads))
    }
  }
})

test_that("the standard score statistics of the D-04 fit's other providers reproduce the reference routine (D-04)", {
  # The reference fails on this fit because one statistic is not finite, and it cannot
  # select the other providers because their IDs are integers (D-27), so no fixture holds
  # their values; the reference's routine gives them while it is in the package.
  parent <- model_case_fit("logis_fe-d04")
  args <- model_case_arguments(parent$fixture$case, reference_datasets_for(parent$fixture$case, "core"))
  fit <- parent$fit
  tests <- suppressWarnings(test_providers(fit, "score", score_type = "standard", data = args$data))$table
  prepared <- model_prepared_data(fit, args$data)
  sizes <- as.integer(fit$providers$n_obs[fit$providers$included])
  old <- Modified_score(as.numeric(fit$response), prepared$design, sizes, unname(fit$provider_effects),
                        unname(fit$coefficients), unname(stats::median(fit$provider_effects)), length(sizes),
                        seq_along(sizes) - 1L, 1L)
  finite <- is.finite(tests$statistic)
  expect_identical(sum(!finite), 1L)
  expect_identical(tests$statistic[finite], as.numeric(old))
})
