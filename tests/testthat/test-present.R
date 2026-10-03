# Presentation: print(), summary(), tidy(), glance(), augment() (ARCHITECTURE §D.3).
local_strict_mode()

present_example <- function() {
  data(ExampleDataBinary, package = "pprof", envir = environment())
  data <- data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID, ExampleDataBinary$Z)
  data <- data[ExampleDataBinary$ProvID <= 20, ]
  fit_logistic_fe(y ~ z1 + z2 + z3 + z4 + z5, data, "hospital")
}

test_that("models, summaries, and results print compactly", {
  fit <- present_example()
  expect_snapshot({
    print(fit)
    print(summary(fit))
    print(test_providers(fit), n = 3)
    print(provider_effects(fit, "score"), n = 3)
    print(standardize_providers(fit, c("indirect", "direct"), interval = "score"), n = 3)
    print(funnel_limits(fit, c(0.95, 0.99)), n = 3)
    print(profile_providers(fit), n = 3)
    print(test_coefficients(fit))
  })
})

test_that("print() returns its argument invisibly", {
  fit <- present_example()
  tests <- test_providers(fit)
  utils::capture.output(shown <- withVisible(print(tests)))
  expect_false(shown$visible)
  expect_identical(shown$value, tests)
  utils::capture.output(shown <- withVisible(print(fit)))
  expect_false(shown$visible)
  expect_identical(shown$value, fit)
})

test_that("summary() returns the Wald coefficient table and the fit statistics as numbers", {
  fit <- present_example()
  result <- summary(fit, level = 0.9)
  expect_s3_class(result, c("pprof_summary", "pprof_result"), exact = TRUE)
  expect_identical(result$table, test_coefficients(fit, level = 0.9)$table)
  expect_identical(result$level, 0.9)
  expect_identical(result$fit, as.data.frame(glance(fit)))
  expect_identical(result[c("family", "method")], list(family = "logistic_fe", method = "serbin"))
})

test_that("tidy(), glance(), and augment() describe the model", {
  fit <- present_example()
  expect_identical(tidy(fit), tibble::as_tibble(test_coefficients(fit)$table))
  expect_identical(tidy(fit, level = 0.9)$lower, test_coefficients(fit, level = 0.9)$table$lower)
  one <- glance(fit)
  expect_identical(nrow(one), 1L)
  expect_identical(one$loglik, fit$loglik)
  expect_identical(one$auc, fit$auc)
  expect_identical(one$iterations, fit$convergence$iterations)
  expect_identical(one$converged, fit$convergence$converged)
  expect_identical(one$n_providers, fit$n_providers)
  rows <- augment(fit)
  expect_identical(rows$row, sort(fit$row_index))
  expect_identical(rows$fitted, unname(stats::fitted(fit)))
  expect_identical(rows$residual, rows$observed - rows$fitted)
  ids <- provider_table(fit)$provider_id[provider_index(fit)]
  expect_identical(rows$provider_id, ids[order(fit$row_index)])
})

test_that("tidy() of a result is its table", {
  fit <- present_example()
  for (result in list(test_providers(fit), provider_effects(fit), standardize_providers(fit), funnel_limits(fit),
                      profile_providers(fit), test_coefficients(fit))) {
    expect_identical(tidy(result), tibble::as_tibble(result$table))
  }
})
