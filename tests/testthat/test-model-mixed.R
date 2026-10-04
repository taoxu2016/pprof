# The lme4 adapter and the random-effect fits (ARCHITECTURE §B.2, §D; DEC-042; K-50 to
# K-54): the lme4 formula and data, `...`, lme4's messages, the model objects of the four
# families, and the methods and contract of the pprof_mixed class. The reference fixtures
# are compared in test-model-mixed-reference.R.
local_strict_mode()

linear_data <- function() {
  data.frame(y = ExampleDataLinear$Y, hospital = ExampleDataLinear$ProvID, ExampleDataLinear$Z)
}
# 20 providers of the binary example, so that glmer() takes well under a second.
binary_data <- function() {
  data <- data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID, ExampleDataBinary$Z)
  data[data$hospital <= 20, ]
}
linear_formula <- y ~ z1 + z2 + z3 + z4 + z5

test_that("the lme4 formula adds the provider's random intercept after the model's terms (DEC-042, K-50)", {
  terms <- stats::terms(y ~ z1 + log(z2) + z1:z3)
  formula <- mixed_lme4_formula(terms, "hospital")
  expect_identical(deparse1(formula), "y ~ z1 + log(z2) + z1:z3 + (1 | hospital)")
  expect_identical(environment(formula), environment(terms))
  expect_identical(deparse1(mixed_lme4_formula(stats::terms(y ~ 1), "School ID")), "y ~ 1 + (1 | `School ID`)")
})

test_that("lme4 fits the complete rows in provider order, with the used columns (K-50)", {
  data <- linear_data()
  data$z2[c(3, 50)] <- NA
  reversed <- data[rev(seq_len(nrow(data))), ]
  prepared <- data_prepare(y ~ z1 + z2, reversed, "hospital", intercept = TRUE)
  rows <- mixed_lme4_data(reversed, prepared, "hospital")
  expect_identical(names(rows), c("y", "hospital", "z1", "z2"))
  expect_identical(nrow(rows), nrow(data) - 2L)
  expect_false(is.unsorted(rows$hospital))
  expect_identical(rownames(rows), rownames(reversed)[prepared$row_index])
})

test_that("a linear random-effect model holds lme4's estimates and closed-form deviations (K-51 to K-53, K-69)", {
  fit <- fit_linear_re(linear_formula, linear_data(), "hospital", keep_data = TRUE)
  expect_s3_class(fit, c("pprof_linear_re", "pprof_mixed", "pprof_model"), exact = TRUE)
  expect_identical(validate_pprof_mixed(fit), fit)
  engine <- fit$engine_fit
  expect_s4_class(engine, "lmerMod")
  expect_s3_class(fit$data, "pprof_data")
  expect_identical(fit$spec$engine, "lmer")
  expect_identical(fit$coefficients, lme4::fixef(engine))
  expect_identical(unname(fit$provider_effects), lme4::ranef(engine)$hospital[, 1L])
  expect_identical(names(fit$provider_effects), as.character(1:100))
  expect_identical(fit$fitted, unname(stats::fitted(engine)))
  expect_identical(fit$linear_predictor, unname(drop(stats::model.matrix(engine) %*% lme4::fixef(engine))))
  expect_identical(fit$sigma, stats::sigma(engine))
  expect_identical(fit$variance_components$provider, as.data.frame(lme4::VarCorr(engine))[1L, "sdcor"]^2)
  expect_identical(unname(fit$vcov), unname(as.matrix(stats::vcov(engine))))
  expect_identical(fit$loglik, as.numeric(stats::logLik(engine)))
  expect_identical(fit$aic, stats::AIC(engine))
  expect_identical(fit$bic, stats::BIC(engine))
  sizes <- fit$providers$n_obs
  variance <- fit$variance_components$provider
  shrinkage <- variance / (variance + fit$sigma^2 / sizes)
  expect_identical(unname(fit$provider_effect_sd), sqrt(shrinkage * fit$sigma^2 / sizes))
  expect_true(fit$convergence$converged)
  expect_false(fit$convergence$singular)
  expect_null(fit_linear_re(linear_formula, linear_data(), "hospital")$engine_fit)
})

test_that("logistic and correlated random-effect models follow their families' rules (K-51, K-54, K-70)", {
  logistic <- fit_logistic_re(linear_formula, binary_data(), "hospital", keep_data = TRUE)
  expect_s3_class(logistic, c("pprof_logistic_re", "pprof_mixed", "pprof_model"), exact = TRUE)
  expect_s4_class(logistic$engine_fit, "glmerMod")
  expect_null(logistic$sigma)
  expect_identical(logistic$fitted, unname(stats::fitted(logistic$engine_fit)))
  post_sd <- sqrt(attr(lme4::ranef(logistic$engine_fit, condVar = TRUE)$hospital, "postVar")[1L, 1L, ])
  expect_identical(unname(logistic$provider_effect_sd), post_sd)

  cre <- fit_logistic_cre(linear_formula, binary_data(), "hospital", within_between = c("z1", "z2"), keep_data = TRUE)
  expect_s3_class(cre, c("pprof_logistic_cre", "pprof_mixed", "pprof_model"), exact = TRUE)
  expect_identical(names(cre$coefficients), c("(Intercept)", "z1_within", "z2_within", "z1_bar", "z2_bar", "z3", "z4",
                                              "z5"))
  expect_identical(deparse1(stats::formula(cre$engine_fit)),
                   "y ~ z1_within + z2_within + z1_bar + z2_bar + z3 + z4 + z5 + (1 | hospital)")
  expect_identical(cre$spec$within_between, c("z1", "z2"))
  expect_identical(cre$variance_components$provider, as.data.frame(lme4::VarCorr(cre$engine_fit))[1L, "vcov"])

  linear_cre <- fit_linear_cre(linear_formula, linear_data(), "hospital", within_between = "z1")
  expect_s3_class(linear_cre, c("pprof_linear_cre", "pprof_mixed", "pprof_model"), exact = TRUE)
  expect_true(is.numeric(linear_cre$sigma))
  expect_error(fit_linear_cre(linear_formula, linear_data(), "hospital"), class = "pprof_error_invalid_input")
  expect_error(fit_logistic_cre(linear_formula, binary_data(), "hospital"), class = "pprof_error_invalid_input")
})

test_that("`...` reaches lme4, and may not change the observations it fits", {
  data <- linear_data()
  ml <- fit_linear_re(linear_formula, data, "hospital", REML = FALSE, keep_data = TRUE)
  expect_false(lme4::isREML(ml$engine_fit))
  expect_identical(ml$spec$engine_arguments, list(REML = FALSE))
  expect_false(isTRUE(all.equal(ml$loglik, fit_linear_re(linear_formula, data, "hospital")$loglik)))
  control <- lme4::lmerControl(optimizer = "Nelder_Mead")
  nelder_mead <- fit_linear_re(linear_formula, data, "hospital", control = control, keep_data = TRUE)
  expect_identical(nelder_mead$convergence$optimizer, "Nelder_Mead")
  expect_error(fit_linear_re(linear_formula, data, "hospital", subset = hospital > 5), class = "pprof_error")
})

test_that("the outcome and covariates are checked for each family", {
  binary <- binary_data()
  expect_error(fit_logistic_re(linear_formula, transform(binary, y = y / 2), "hospital"),
               class = "pprof_error_invalid_input")
  expect_error(fit_logistic_re(linear_formula, transform(binary, y = 1), "hospital"), class = "pprof_error_data")
  linear <- linear_data()
  linear$z3[4] <- Inf
  expect_error(fit_linear_re(linear_formula, linear, "hospital"), class = "pprof_error_invalid_input")
  linear <- linear_data()
  linear$y[4] <- NaN
  expect_identical(fit_linear_re(linear_formula, linear, "hospital")$n_obs, 7900L)
  for (value in list("yes", NA)) {
    expect_error(fit_linear_re(linear_formula, linear_data(), "hospital", keep_data = value),
                 class = "pprof_error_invalid_input")
    expect_error(fit_linear_re(linear_formula, linear_data(), "hospital", verbose = value),
                 class = "pprof_error_invalid_input")
  }
})

test_that("lme4's messages are reported only with verbose = TRUE, and a singular fit is recorded", {
  # Every provider has the same mean outcome, so the provider variance is estimated at 0.
  data <- data.frame(y = rep(c(-1, 1), 50), hospital = rep(1:10, each = 10), x = rep(seq(-1, 1, length.out = 10), 10))
  expect_silent(fit <- fit_linear_re(y ~ x, data, "hospital"))
  expect_true(fit$convergence$singular)
  expect_match(fit$convergence$engine_messages, "singular", all = FALSE)
  messages <- character()
  withCallingHandlers(fit_linear_re(y ~ x, data, "hospital", verbose = TRUE), pprof_message = function(m) {
    messages <<- c(messages, conditionMessage(m))
    invokeRestart("muffleMessage")
  })
  expect_match(messages, "singular", all = FALSE)
})

test_that("the standard methods of pprof_mixed", {
  data <- linear_data()
  fit <- fit_linear_re(linear_formula, data, "hospital", keep_data = TRUE)
  values <- fitted(fit)
  expect_identical(names(values), as.character(sort(fit$row_index)))
  expect_identical(unname(values), fit$fitted[order(fit$row_index)])
  # lme4 names its residuals by the rows of the data it fit, which are the input rows.
  expect_identical(residuals(fit), stats::residuals(fit$engine_fit)[names(values)])
  expect_error(residuals(fit, type = "deviance"), class = "pprof_error_invalid_input")
  expect_equal(unname(predict(fit)), unname(values), tolerance = 1e-12)
  newdata <- data[c(5, 900, 2), ]
  expect_equal(unname(predict(fit, newdata)), unname(predict(fit)[c("5", "900", "2")]), tolerance = 1e-12)
  log_likelihood <- logLik(fit)
  expect_identical(as.numeric(log_likelihood), fit$loglik)
  expect_identical(attr(log_likelihood, "df"), attr(stats::logLik(fit$engine_fit), "df"))
  expect_identical(stats::AIC(fit), fit$aic)
  expect_identical(nobs(fit), 7901L)
  expect_output(print(fit), "<pprof model: linear_re>", fixed = TRUE)

  logistic <- fit_logistic_re(linear_formula, binary_data(), "hospital", keep_data = TRUE)
  # lme4 forms the deviance residuals with log(y / mu), which can differ in the last bit.
  deviance <- residuals(logistic)
  expect_equal(deviance, stats::residuals(logistic$engine_fit)[names(deviance)], tolerance = 1e-12)
  input_order <- order(logistic$row_index)
  expect_identical(unname(residuals(logistic, type = "response")),
                   as.numeric(logistic$response)[input_order] - logistic$fitted[input_order])
  expect_equal(unname(predict(logistic, type = "response")), unname(fitted(logistic)), tolerance = 1e-12)

  cre <- fit_linear_cre(linear_formula, data, "hospital", within_between = "z1")
  expect_error(predict(cre, data[1:3, ]), class = "pprof_error_unsupported_inference")
  expect_identical(nrow(augment(cre)), 7901L)
})

test_that("the contract methods of pprof_mixed (K-60)", {
  fit <- fit_linear_re(linear_formula, linear_data(), "hospital")
  expect_identical(expected_outcome(fit, 0), fit$linear_predictor)
  expect_identical(expected_outcome(fit, fit$provider_effects),
                   unname(fit$provider_effects)[fit$provider_index] + fit$linear_predictor)
  expect_identical(null_effect(fit, 0.5), 0.5)
  expect_identical(null_effect(fit, 1L), 1)
  expect_error(null_effect(fit, "median"), class = "pprof_error_invalid_input")
  expect_identical(provider_estimate_se(fit), fit$provider_effect_sd)
  logistic <- fit_logistic_re(linear_formula, binary_data(), "hospital")
  expect_identical(expected_outcome(logistic, 0), stats::plogis(logistic$linear_predictor))
})

test_that("random-effect models have Wald inference only, without a funnel (ARCHITECTURE §E.3, Phase 5)", {
  # The results are checked against the reference in test-profile-families.R.
  fit <- fit_linear_re(linear_formula, linear_data(), "hospital")
  unsupported <- function(expr) expect_error(expr, class = "pprof_error_unsupported_inference")
  unsupported(test_providers(fit, "exact"))
  unsupported(provider_effects(fit, interval = "exact"))
  unsupported(funnel_limits(fit))
  unsupported(test_coefficients(fit, "score"))
  expect_s3_class(test_providers(fit), "pprof_provider_tests")
  expect_s3_class(summary(fit), "pprof_summary")
  expect_s3_class(tidy(fit), "tbl_df")
  expect_s3_class(glance(fit), "tbl_df")
})
