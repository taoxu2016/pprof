# Tests and intervals for covariate coefficients (K-100 to K-102), against the reference's
# summary() fixtures, and the data rules of DEC-005.
local_strict_mode()

binary_fit <- function() {
  parent <- model_case_fit("logis_fe-binary-columns")
  args <- model_case_arguments(parent$fixture$case, reference_datasets_for(parent$fixture$case, "core"))
  list(fit = parent$fit, data = args$data)
}

# The reference's summary() selects names silently (unknown ones are dropped); the new API
# rejects unknown names, so the cases' parm is reduced to the known names, as the
# compatibility wrapper does.
summary_case_parm <- function(case, fit) {
  parm <- case$args$parm
  if (is.character(parm)) intersect(parm, names(fit$coefficients)) else parm
}

for (id in c("summary-binary-wald", "summary-binary-wald-parm", "summary-binary-wald-level90", "summary-binary-lr",
             "summary-binary-lr-parm", "summary-binary-score")) {
  local({
    case_id <- id
    test_that(paste("test_coefficients() reproduces the reference summary:", case_id), {
      fixture <- reference_fixture(case_id)
      if (isTRUE(fixture$case$heavy)) skip_on_cran()
      skip_off_reference_platform()
      model <- binary_fit()
      args <- fixture$case$args
      test <- if (is.null(args$test)) "wald" else args$test
      level <- if (is.null(args$level)) 0.95 else args$level
      table <- test_coefficients(model$fit, test = test, parm = summary_case_parm(fixture$case, model$fit),
                                 level = level, data = model$data)$table
      expected <- fixture$result$value
      expect_identical(table$term, rownames(expected))
      expect_reference_value(table$estimate, unname(expected$Estimate), "iterative", "estimate")
      if (test == "wald") {
        expect_reference_value(table$std_error, unname(expected$Std.Error), "iterative", "standard error")
        expect_reference_value(table$statistic, unname(expected$Stat), "iterative", "statistic")
        expect_reference_value(table$lower, unname(expected$CI.Lower), "iterative", "lower limit")
        expect_reference_value(table$upper, unname(expected$CI.Upper), "iterative", "upper limit")
        # K-100: the reference reports p-values as formatted strings.
        expect_identical(format.pval(table$p_value, digits = p_value_display_digits, eps = p_value_display_eps),
                         unname(expected[["p value"]]))
      } else {
        expect_reference_value(table$statistic, as.numeric(expected$stat), "iterative", "statistic")
        expect_reference_value(table$p_value, as.numeric(expected[["p value"]]), "probability", "p-value")
      }
    })
  })
}

test_that("with one covariate the likelihood-ratio test is against provider effects only, not the score test (D-30)", {
  model <- model_case_fit("logis_fe-screening-onecov")
  args <- model_case_arguments(model$fixture$case, reference_datasets_for(model$fixture$case, "core"))
  expect_error(test_coefficients(model$fit, "score", data = args$data), class = "pprof_error_unsupported_inference")
  table <- test_coefficients(model$fit, "lr", data = args$data)$table
  expect_identical(table$term, "x1")
  skip_off_reference_platform()
  # pprof 1.0.3 from R 4.5.0 (DEC-084; the fixtures emulate R 4.5.0 on R 4.4): its statistic,
  # and its null model, which is its fit of the data with no covariates.
  expected <- reference_fixture("summary-screening-onecov-lr")$result$value
  expect_reference_value(table$statistic, as.numeric(expected$stat), "iterative", "statistic")
  expect_reference_value(table$p_value, as.numeric(expected[["p value"]]), "probability", "p-value")
  null_model <- refit_without(model$fit, "x1", args$data)
  reference_null <- reference_fixture("logis_fe-screening-nocov")$result$value$coefficient$gamma
  expect_reference_value(unname(provider_estimates(null_model)), as.numeric(reference_null), "iterative",
                         "provider effects of the null model")
})

test_that("with two covariates the likelihood-ratio test refits each one-covariate model (D-30)", {
  skip_off_reference_platform()
  model <- model_case_fit("logis_fe-screening-twocov")
  args <- model_case_arguments(model$fixture$case, reference_datasets_for(model$fixture$case, "core"))
  table <- test_coefficients(model$fit, "lr", data = args$data)$table
  expect_identical(table$term, c("x1", "x2"))
  expect_true(all(is.finite(table$statistic) & table$statistic >= 0))
  # Each null model fits the other covariate alone to the same observations with the
  # default settings, which are the reference's fits logis_fe-screening-x2 (for x1) and
  # logis_fe-screening-onecov (for x2), so each statistic is K-101 computed with the
  # reference's expression from the fixtures.
  prepared <- model_prepared_data(model$fit, args$data)
  sizes <- prepared$providers$n_obs[prepared$providers$included]
  neg2_loglik <- function(value, design) {
    gamma <- value$coefficient$gamma
    gamma_obs <- rep(pmax(pmin(gamma, stats::median(gamma) + 10), stats::median(gamma) - 10), sizes)
    eta <- gamma_obs + design %*% value$coefficient$beta
    -2 * sum(eta * prepared$response - log(1 + exp(eta)))
  }
  full <- neg2_loglik(model$fixture$result$value, prepared$design)
  expected <- c(
    neg2_loglik(reference_fixture("logis_fe-screening-x2")$result$value, prepared$design[, "x2", drop = FALSE]),
    neg2_loglik(reference_fixture("logis_fe-screening-onecov")$result$value, prepared$design[, "x1", drop = FALSE])
  ) - full
  expect_reference_value(table$statistic, expected, "iterative", "statistics")
})

test_that("a null model that its default screening would shrink fails with a classed error (D-10)", {
  model <- model_case_fit("logis_fe-cutoff5")
  args <- model_case_arguments(model$fixture$case, reference_datasets_for(model$fixture$case, "core"))
  expect_error(test_coefficients(model$fit, "lr", data = args$data), class = "pprof_error_data")
})

test_that("the likelihood-ratio and score tests need the covariates of the fit (DEC-005)", {
  data <- data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID, ExampleDataBinary$Z)
  fit <- fit_logistic_fe(y ~ z1 + z2 + z3, data, "hospital")
  expect_error(test_coefficients(fit, "lr"), class = "pprof_error_data_required")
  expect_error(test_coefficients(fit, "lr", data = data[rev(seq_len(nrow(data))), ]),
               class = "pprof_error_invalid_input")
  other <- transform(data, z1 = z1 + 1)
  expect_error(test_coefficients(fit, "score", data = other), class = "pprof_error_invalid_input")
  kept <- fit_logistic_fe(y ~ z1 + z2 + z3, data, "hospital", keep_data = TRUE)
  expect_identical(test_coefficients(kept, "lr")$table, test_coefficients(fit, "lr", data = data)$table)
})

test_that("test_coefficients() checks its arguments", {
  data <- data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID, ExampleDataBinary$Z)
  fit <- fit_logistic_fe(y ~ z1 + z2 + z3, data, "hospital")
  expect_error(test_coefficients(data), class = "pprof_error_invalid_input")
  expect_error(test_coefficients(fit, "likelihood"), class = "pprof_error_invalid_input")
  expect_error(test_coefficients(fit, parm = "z9"), class = "pprof_error_invalid_input")
  expect_error(test_coefficients(fit, parm = 4), class = "pprof_error_invalid_input")
  expect_error(test_coefficients(fit, "lr", null = 1, data = data), class = "pprof_error_invalid_input")
  expect_identical(test_coefficients(fit, parm = c(3, 1))$table$term, c("z3", "z1"))
  expect_identical(test_coefficients(fit, parm = c("z3", "z1"))$table$term, c("z1", "z3"))
})

test_that("confint() returns the Wald limits of the coefficients (K-100)", {
  data <- data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID, ExampleDataBinary$Z)
  fit <- fit_logistic_fe(y ~ z1 + z2 + z3, data, "hospital")
  limits <- confint(fit, level = 0.9)
  table <- test_coefficients(fit, level = 0.9)$table
  expect_identical(dimnames(limits), list(c("z1", "z2", "z3"), c("5 %", "95 %")))
  expect_identical(unname(limits[, 1]), table$lower)
  expect_identical(unname(limits[, 2]), table$upper)
  expect_identical(rownames(confint(fit, parm = "z2")), "z2")
})
