# The logistic fixed-effect engines (src/logistic/serbin, src/logistic/ban) through their
# adapters: the iteration path against the Phase 0 ports, loop bounds, stopping rules,
# clamping, threads, edge cases, input checks, and interrupts (brief §6 B to D).
local_strict_mode()

expect_iterative <- function(actual, expected, label) {
  diffs <- reference_compare(as.numeric(actual), as.numeric(expected), reference_tolerance("iterative"))
  testthat::expect(is.null(diffs), sprintf("%s: %s", label, paste(diffs$detail, collapse = "; ")))
}

example_inputs <- function() engine_dataset_inputs("binary_example", paste0("z", 1:5))

# Configurations whose paths exercise the line search and the clamp: the bundled example
# from its starting values (neither happens), from starting values far from the estimates
# (21 SerBIN backtracking steps, one clamped effect), and syn_extreme, whose providers with
# no events or only events are clamped once the fit runs long enough.
path_configurations <- function() {
  example <- example_inputs()
  far <- example
  far$gamma[] <- 6
  far$beta[] <- 2
  list(example = example, far = far, extreme = engine_dataset_inputs("syn_extreme", c("x1", "x2", "x3")))
}

test_that("SerBIN matches the Phase 0 port after every iteration (K-12 to K-15)", {
  configurations <- path_configurations()
  for (name in names(configurations)) {
    inputs <- configurations[[name]]
    for (backtrack in c(TRUE, FALSE)) {
      # From the far starting values, full Newton steps diverge and the log-likelihood
      # criteria become NaN, which the port's min() propagates and the reference's
      # Armadillo min() ignores; that path is checked against the reference routine itself
      # (test-cpp-legacy-comparison.R) and below.
      if (name == "far" && !backtrack) next
      for (k in 1:12) {
        # tol = 0 is never met, so both run exactly max_iter + 1 = k iterations.
        new <- cpp_logistic_fe_serbin(inputs$response, inputs$design, inputs$sizes, inputs$gamma, inputs$beta, k - 1L,
                                      0, 10, backtrack, "any", 1L)
        port <- port_serbin(inputs$response, inputs$design, inputs$sizes, inputs$gamma, inputs$beta, tol = 0,
                            max_iter = k - 1, bound = 10, backtrack = backtrack)
        label <- sprintf("%s, backtrack %s, iteration %d", name, backtrack, k)
        expect_identical(new$iterations, as.integer(port$iter), label = label)
        expect_iterative(new$gamma, port$gamma, paste(label, "gamma"))
        expect_iterative(new$beta, port$beta, paste(label, "beta"))
        expect_iterative(new$history[, "coefficients"], port$trace[, "beta"], paste(label, "criterion"))
      }
    }
  }
})

test_that("BAN matches the Phase 0 port after every iteration (K-13 to K-15)", {
  configurations <- path_configurations()
  for (name in names(configurations)) {
    inputs <- configurations[[name]]
    for (backtrack in c(TRUE, FALSE)) {
      for (k in 1:12) {
        new <- cpp_logistic_fe_ban(inputs$response, inputs$design, inputs$sizes, inputs$gamma, inputs$beta, k, 0, 10,
                                   backtrack, "any", 1L)
        port <- port_ban(inputs$response, inputs$design, inputs$sizes, inputs$gamma, inputs$beta,
                         backtrack = as.integer(backtrack), max_iter = k, bound = 10, tol = 0)
        label <- sprintf("%s, backtrack %s, iteration %d", name, backtrack, k)
        expect_identical(new$iterations, as.integer(port$iter), label = label)
        expect_iterative(new$gamma, port$gamma, paste(label, "gamma"))
        expect_iterative(new$beta, port$beta, paste(label, "beta"))
      }
    }
  }
})

test_that("the configurations above exercise backtracking and clamping", {
  configurations <- path_configurations()
  far <- configurations$far
  port <- port_serbin(far$response, far$design, far$sizes, far$gamma, far$beta)
  expect_gt(port$n_backtracks, 0)
  extreme <- configurations$extreme
  port <- port_serbin(extreme$response, extreme$design, extreme$sizes, extreme$gamma, extreme$beta, max_iter = 11,
                      tol = 0)
  expect_gt(port$n_clamped, 0)
})

test_that("SerBIN runs max_iter + 1 iterations and BAN max_iter when the rule is never met (K-17, D-03)", {
  inputs <- utils::modifyList(example_inputs(), list(max_iter = 3L, tol = 1e-300, stop_rule = "coefficients"))
  serbin <- engine_fit(inputs)
  expect_identical(serbin$iterations, 4L)
  expect_false(serbin$converged)
  expect_identical(nrow(serbin$history), 4L)
  ban <- engine_fit(utils::modifyList(inputs, list(method = "BAN")))
  expect_identical(ban$iterations, 3L)
  expect_false(ban$converged)
})

test_that("each stopping rule stops at the first iteration whose criterion is below tol (K-16)", {
  inputs <- example_inputs()
  for (method in c("SerBIN", "BAN")) {
    for (rule in engine_stop_rules) {
      fit <- engine_fit(utils::modifyList(inputs, list(method = method, stop_rule = rule)))
      history <- fit$history
      criteria <- history[, c("coefficients", "relative_loglik", "relative_gain")]
      expected <- switch(rule,
                         any = apply(criteria, 1, min), all = apply(criteria, 1, max),
                         coefficients = criteria[, 1], relative_loglik = criteria[, 2], relative_gain = criteria[, 3])
      label <- paste(method, rule)
      expect_identical(unname(history[, "rule"]), unname(expected), label = label)
      n <- nrow(history)
      expect_true(fit$converged, label = label)
      expect_true(history[n, "rule"] < inputs$tol, label = label)
      expect_true(all(history[-n, "rule"] >= inputs$tol), label = label)
    }
  }
})

test_that("the rules any and all ignore a criterion that is NaN, as the reference's Armadillo min() and max() do", {
  far <- path_configurations()$far
  fit <- cpp_logistic_fe_serbin(far$response, far$design, far$sizes, far$gamma, far$beta, 3L, 0, 10, FALSE, "any", 1L)
  history <- fit$history
  diverged <- is.nan(history[, "relative_loglik"]) & is.nan(history[, "relative_gain"])
  expect_true(any(diverged))
  expect_identical(history[diverged, "rule"], history[diverged, "coefficients"])
})

test_that("provider effects stay within effect_bound of their median (K-15)", {
  inputs <- engine_dataset_inputs("syn_extreme", c("x1", "x2", "x3"))
  for (bound in c(10, 5)) {
    fit <- engine_fit(utils::modifyList(inputs, list(tol = 1e-10, stop_rule = "all", bound = bound)))
    expect_lte(diff(range(fit$gamma)), 2 * bound)
    # Providers 4 and 5 have only events; their effects end at the upper bound.
    expect_identical(fit$gamma[4], max(fit$gamma))
    expect_identical(fit$gamma[5], max(fit$gamma))
  }
})

test_that("SerBIN with two threads agrees with one thread and is deterministic (D-20)", {
  inputs <- example_inputs()
  one <- engine_fit(inputs, threads = 1L)
  two <- engine_fit(inputs, threads = 2L)
  expect_identical(engine_fit(inputs, threads = 2L), two)
  expect_identical(two$iterations, one$iterations)
  expect_iterative(two$gamma, one$gamma, "gamma")
  expect_iterative(two$beta, one$beta, "beta")
})

test_that("the adapters leave their arguments unchanged", {
  inputs <- example_inputs()
  before <- unserialize(serialize(inputs, NULL))
  fit <- engine_fit(inputs)
  engine_fit(utils::modifyList(inputs, list(method = "BAN")))
  cpp_logistic_variance(inputs$design, inputs$sizes, fit$gamma, fit$beta)
  cpp_logistic_score_standard(inputs$response, inputs$design, inputs$sizes, fit$gamma, fit$beta, 0,
                              seq_along(inputs$sizes), 1L)
  expect_identical(inputs, before)
})

test_that("the adapters reject inconsistent inputs", {
  inputs <- example_inputs()
  serbin <- function(...) {
    args <- utils::modifyList(inputs, list(...))
    cpp_logistic_fe_serbin(args$response, args$design, args$sizes, args$gamma, args$beta, 100L, 1e-5, 10, TRUE,
                           args$stop_rule, args$threads)
  }
  expect_error(serbin(response = inputs$response[-1]), class = "std::invalid_argument")
  expect_error(serbin(gamma = inputs$gamma[-1]), class = "std::invalid_argument")
  expect_error(serbin(beta = c(inputs$beta, 0)), class = "std::invalid_argument")
  expect_error(serbin(sizes = c(inputs$sizes[-1], 0L, inputs$sizes[1])), class = "std::invalid_argument")
  expect_error(serbin(threads = 0L), class = "std::invalid_argument")
  expect_error(serbin(stop_rule = "or"), class = "std::invalid_argument")
  expect_error(cpp_logistic_score_standard(inputs$response, inputs$design, inputs$sizes, inputs$gamma, inputs$beta, 0,
                                           length(inputs$sizes) + 1L, 1L),
               class = "std::invalid_argument")
})

test_that("the engines fit a single provider, one-observation providers, and all-event providers", {
  inputs <- example_inputs()
  rows <- seq_len(inputs$sizes[1])
  single <- utils::modifyList(inputs, list(response = inputs$response[rows],
                                           design = inputs$design[rows, , drop = FALSE],
                                           sizes = inputs$sizes[1], gamma = inputs$gamma[1]))
  for (method in c("SerBIN", "BAN")) {
    fit <- engine_fit(utils::modifyList(single, list(method = method)))
    expect_true(fit$converged, label = method)
  }
  small <- withr::with_seed(2, {
    y <- stats::rbinom(40, 1, 0.4)
    list(response = as.numeric(y), design = matrix(stats::rnorm(80), 40, 2), sizes = c(rep(1L, 10), rep(10L, 3)),
         gamma = rep(log(mean(y) / (1 - mean(y))), 13), beta = c(0, 0))
  })
  fit <- engine_fit(utils::modifyList(inputs, small))
  expect_true(fit$converged)
  expect_true(all(is.finite(fit$gamma)))
  all_events <- inputs
  all_events$response[] <- 1
  all_events$gamma[] <- 0
  fit <- engine_fit(all_events)
  expect_true(all(is.finite(c(fit$gamma, fit$beta))))
})

test_that("a non-finite design value ends the fit with an error instead of a hang", {
  inputs <- example_inputs()
  inputs$design[5, 2] <- NaN
  expect_error(engine_fit(inputs), class = "std::runtime_error")
})

test_that("a pending interrupt stops an engine between iterations", {
  skip_on_cran()
  inputs <- utils::modifyList(engine_random_inputs(99), list(tol = 0, stop_rule = "coefficients", max_iter = 1000000L))
  started <- Sys.time()
  on.exit(setTimeLimit(), add = TRUE)
  # The elapsed-time limit makes R's interrupt check fire, which the engine runs before
  # every iteration; R prints the limit's message, which is captured here.
  utils::capture.output(type = "message", {
    outcome <- tryCatch({
      setTimeLimit(elapsed = 1, transient = TRUE)
      engine_fit(inputs)
      "finished"
    }, interrupt = function(condition) "interrupted", error = function(condition) "error")
  })
  setTimeLimit()
  expect_identical(outcome, "interrupted")
  expect_lt(as.numeric(difftime(Sys.time(), started, units = "secs")), 30)
})
