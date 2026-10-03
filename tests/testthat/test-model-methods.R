# Standard methods of the models (ARCHITECTURE §D.3), on logistic fixed-effect fits.
local_strict_mode()

shuffled_example <- function() {
  data <- data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID, ExampleDataBinary$Z)
  data[withr::with_seed(3, sample(nrow(data))), ]
}

test_that("coef(), vcov(), nobs(), formula(), and logLik() return the fit's quantities", {
  fit <- fit_logistic_fe(y ~ z1 + z2 + z3 + z4 + z5, shuffled_example(), "hospital")
  expect_identical(coef(fit), fit$coefficients)
  expect_identical(vcov(fit), fit$vcov)
  expect_identical(nobs(fit), 7944L)
  expect_identical(formula(fit), y ~ z1 + z2 + z3 + z4 + z5)
  loglik <- logLik(fit)
  expect_identical(as.numeric(loglik), fit$loglik)
  expect_identical(attr(loglik, "df"), 105L)
  expect_identical(stats::AIC(fit), fit$aic)
  expect_identical(stats::BIC(fit), fit$bic)
})

test_that("fitted() and residuals() follow the rows of the data", {
  data <- shuffled_example()
  fit <- fit_logistic_fe(y ~ z1 + z2 + z3 + z4 + z5, data, "hospital")
  fitted_values <- fitted(fit)
  expect_identical(names(fitted_values), as.character(seq_len(nrow(data))))
  # Row by row, the fitted probability is plogis(gamma of the row's provider + z'beta).
  design <- as.matrix(data[, paste0("z", 1:5)])
  expected <- stats::plogis(unname(fit$provider_effects[as.character(data$hospital)]) +
                              unname(drop(design %*% fit$coefficients)))
  expect_equal(unname(fitted_values), expected, tolerance = 1e-14)
  y <- data$y
  p <- unname(fitted_values)
  expect_equal(unname(residuals(fit, type = "response")), y - p, tolerance = 1e-14)
  expect_equal(unname(residuals(fit, type = "pearson")), (y - p) / sqrt(p * (1 - p)), tolerance = 1e-12)
  expect_equal(unname(residuals(fit)), sign(y - p) * sqrt(stats::binomial()$dev.resids(y, p, 1)), tolerance = 1e-12)
  expect_error(residuals(fit, type = "working"), class = "pprof_error_invalid_input")
})

test_that("predict() reproduces the fit on its own data and handles new data", {
  data <- shuffled_example()
  fit <- fit_logistic_fe(y ~ z1 + z2 + z3 + z4 + z5, data, "hospital")
  expect_identical(predict(fit, type = "response"), fitted(fit))
  expect_equal(unname(predict(fit, newdata = data[1:20, ], type = "response")), unname(fitted(fit)[1:20]),
               tolerance = 1e-14)
  link <- predict(fit, newdata = data[1:20, ])
  expect_equal(link, stats::qlogis(predict(fit, newdata = data[1:20, ], type = "response")), tolerance = 1e-12)
  new_rows <- data[1:3, ]
  new_rows$hospital[2] <- 999
  new_rows$z3[3] <- NA
  expect_warning(prediction <- predict(fit, newdata = new_rows), class = "pprof_warning_unknown_providers")
  expect_identical(names(prediction), rownames(new_rows))
  expect_identical(unname(is.na(prediction)), c(FALSE, TRUE, TRUE))
  expect_error(predict(fit, newdata = data[, -2]), class = "pprof_error_invalid_input")
  expect_error(predict(fit, type = "probability"), class = "pprof_error_invalid_input")
})

test_that("predict() codes factors with the levels and contrasts of the fit", {
  factors <- readRDS(reference_locate(file.path("datasets", "syn_factors.rds"), "core"))
  fit <- fit_logistic_fe(Y ~ x1 + grp, factors, "ProvID")
  one_level <- factors[factors$grp == "level two", ][1:5, ]
  expect_equal(unname(predict(fit, newdata = one_level, type = "response")),
               unname(fitted(fit)[as.character(as.integer(rownames(one_level)))]), tolerance = 1e-14)
})
