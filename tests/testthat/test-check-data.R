# check_data() and the data_check() wrapper (DEC-010, DEC-073; D-17, D-52): the computations that
# replace caret::nearZeroVar() and olsrr::ols_vif_tol() equal them (DEC-009), the report, and
# the wrapper's messages, warnings, and errors against pprof 1.0.3's.
local_strict_mode()

check_binary <- function() {
  data(ExampleDataBinary, package = "pprof", envir = environment())
  data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID, ExampleDataBinary$Z)
}

# The covariate sets of Phase 8's fact script 04_data_check.R (dev/README.md), as data_check()
# builds its data: the example covariates, a rare category, ties for the most frequent value, an
# integer covariate, near and exact collinearity, one and two covariates.
check_covariate_sets <- function() {
  data(ExampleDataBinary, package = "pprof", envir = environment())
  z <- as.matrix(ExampleDataBinary$Z)
  n <- nrow(z)
  withr::with_seed(20261005, {
    count <- stats::rpois(n, 2)
    noise <- stats::rnorm(n, sd = 0.01)
  })
  list(
    example = z,
    rare = cbind(z, rare = c(rep(1, 30), rep(0, n - 30))),
    ties = cbind(z, tie = rep(c(0, 1, 1, 2, 2), length.out = n)),
    integer = cbind(z, count = count),
    near_collinear = cbind(z, z12 = z[, 1] + z[, 2] + noise),
    exact_collinear = cbind(z, z12 = z[, 1] + z[, 2]),
    one = z[, 1, drop = FALSE],
    two = z[, 1:2]
  )
}

# summary.lm() warns of an essentially perfect fit for exactly collinear columns, in olsrr's
# computation and in its copy alike.
muffle_perfect_fit <- function(expr) {
  withCallingHandlers(expr, warning = function(w) {
    if (grepl("essentially perfect fit", conditionMessage(w), fixed = TRUE)) invokeRestart("muffleWarning")
  })
}

test_that("the near-zero-variance metrics and the VIF equal caret's and olsrr's (DEC-009, DEC-073)", {
  skip_if_not_installed("caret")
  skip_if_not_installed("olsrr")
  data(ExampleDataBinary, package = "pprof", envir = environment())
  sets <- check_covariate_sets()
  for (name in names(sets)) {
    z <- sets[[name]]
    data <- as.data.frame(cbind(Y = ExampleDataBinary$Y, ProvID = ExampleDataBinary$ProvID, z))
    covariates <- data[, colnames(z), drop = FALSE]
    expect_identical(check_near_zero(covariates), caret::nearZeroVar(covariates, saveMetrics = TRUE), label = name)
    if (ncol(z) < 2L) next # olsrr::ols_vif_tol() fails with one covariate
    model <- stats::lm(stats::as.formula(paste("Y ~", paste(colnames(z), collapse = "+"))), data = data)
    expect_identical(muffle_perfect_fit(check_vif(as.data.frame(stats::model.matrix(model))[, -1L, drop = FALSE])),
                     muffle_perfect_fit(suppressMessages(olsrr::ols_vif_tol(model))), label = name)
  }
})

test_that("the VIF of a column is 1 / (1 - R^2) of its regression on the others", {
  z <- as.data.frame(check_covariate_sets()$near_collinear)
  r_squared <- summary(stats::lm(z12 ~ z1 + z2 + z3 + z4 + z5, data = z))$r.squared
  expect_equal(check_vif(z)$VIF[6], 1 / (1 - r_squared), tolerance = reference_tolerance("closed_form")$rtol)
  # One column: no other column to explain it, so its VIF is 1.
  expect_identical(check_vif(z["z1"])$VIF, 1)
})

test_that("correlated pairs are listed as data_check() of pprof 1.0.3 lists them", {
  withr::with_seed(3, {
    x <- stats::rnorm(200)
    w <- stats::rnorm(200)
    z <- cbind(a = x, b = x + stats::rnorm(200, sd = 0.01), c = w, d = -w + stats::rnorm(200, sd = 0.01),
               e = stats::rnorm(200))
  })
  pairs <- check_correlations(z)
  # By column of the correlation matrix, then by row, as pprof 1.0.3's which() gives them.
  expect_identical(pairs$term_1, c("a", "c"))
  expect_identical(pairs$term_2, c("b", "d"))
  expect_true(pairs$correlation[1] > correlation_threshold && pairs$correlation[2] < -correlation_threshold)
  expect_identical(nrow(check_correlations(z[, 1, drop = FALSE])), 0L)
})

test_that("check_data() reports missing values, variation, correlation, and VIF without stopping (DEC-010, D-17)", {
  data <- check_binary()
  data$z1[c(5, 17)] <- NA
  data$y[3] <- NA
  data$rare <- c(rep(1, 30), rep(0, nrow(data) - 30))
  data$const <- 1
  data$z12 <- data$z1 + 0.1 * data$z2 # exactly collinear with z1 and z2, and correlated with z1
  check <- check_data(y ~ z1 + z2 + z3 + rare + const + z12, data, "hospital")
  expect_s3_class(check, "pprof_data_check")
  expect_identical(validate_pprof_data_check(check), check)
  expect_identical(check$table$variable, c("y", "z1", "z2", "z3", "rare", "const", "z12", "hospital"))
  expect_identical(check$table$role, c("outcome", rep("covariate", 6), "provider"))
  expect_identical(check$table$n_missing, c(1L, 2L, 0L, 0L, 0L, 0L, 2L, 0L))
  expect_identical(check$n_obs, nrow(data))
  expect_identical(check$n_complete, nrow(data) - 3L)
  design <- check$design
  expect_identical(design$term, c("z1", "z2", "z3", "rare", "const", "z12"))
  expect_identical(design$zero_variance, c(FALSE, FALSE, FALSE, FALSE, TRUE, FALSE))
  expect_identical(design$near_zero_variance, c(FALSE, FALSE, FALSE, TRUE, TRUE, FALSE))
  expect_true(is.na(design$vif[design$term == "const"]))
  expect_true(all(design$vif[design$term %in% c("z1", "z2", "z12")] >= vif_threshold))
  expect_identical(check$correlations$term_1, "z1")
  expect_identical(check$correlations$term_2, "z12")
  output <- utils::capture.output(print(check))
  expect_match(output[1], "7,944 observations, 7,941 complete", fixed = TRUE)
  expect_true(any(grepl("Missing values: y (1), z1 (2), z12 (2)", output, fixed = TRUE)))
  expect_true(any(grepl("No variation: const", output, fixed = TRUE)))
  expect_true(any(grepl("Near-zero variance: rare", output, fixed = TRUE)))
  expect_true(any(startsWith(output, "Correlation above 0.9 in absolute value: z1 and z12")))
  expect_true(any(startsWith(output, "Variance inflation factor of 10 or more: z1")))
})

test_that("check_data() codes a factor as the fits do, and finds no problem in the example data", {
  data <- check_binary()
  data$group <- factor(rep(c("a", "b", "c"), length.out = nrow(data)))
  check <- check_data(y ~ z1 + group, data, "hospital")
  expect_identical(check$design$term, c("z1", "groupb", "groupc"))
  clean <- check_data(y ~ z1 + z2 + z3 + z4 + z5, check_binary(), "hospital")
  expect_identical(utils::capture.output(print(clean))[-1], "No problems found.")
})

test_that("check_data() checks its arguments", {
  data <- check_binary()
  expect_error(check_data(y ~ z1 + nothing, data, "hospital"), class = "pprof_error_invalid_input")
  expect_error(check_data(y ~ z1, data, "clinic"), class = "pprof_error_invalid_input")
  expect_error(check_data("y ~ z1", data, "hospital"), class = "pprof_error_invalid_input")
})

test_that("data_check() gives pprof 1.0.3's messages, warnings, and errors (D-17)", {
  ids <- reference_case_ids("data_check")
  skip_if(length(ids) == 0L, "Reference fixtures not available")
  # summary.lm() warns of an "essentially perfect fit" when the residual variance of exactly
  # collinear columns falls below a threshold, which rounding decides: it warns on Linux for
  # data_check-collinear, and pprof 1.0.3 did not on the fixtures' platform. Off that platform
  # these warnings are left out of both sides (DEC-080).
  platform <- reference_platform()
  comparable <- function(warnings) {
    if (platform$ok) warnings else warnings[!grepl("essentially perfect fit", warnings, fixed = TRUE)]
  }
  for (id in ids) {
    fixture <- reference_fixture(id)$result
    result <- reference_run(id)
    expect_identical(result$messages, fixture$messages, label = paste(id, "messages"))
    expect_identical(comparable(result$warnings), comparable(fixture$warnings), label = paste(id, "warnings"))
    expect_identical(result$outcome, fixture$outcome, label = paste(id, "outcome"))
    if (identical(fixture$outcome, "error")) {
      expect_identical(result$error$message, fixture$error$message, label = paste(id, "error"))
      expect_true("pprof_error_data" %in% result$error$class, label = paste(id, "error class"))
    }
  }
})

test_that("data_check() completes its checks with one covariate, where pprof 1.0.3 failed in cor() (D-52)", {
  data(ExampleDataBinary, package = "pprof", envir = environment())
  messages <- character()
  withCallingHandlers(
    data_check(ExampleDataBinary$Y, ExampleDataBinary$Z[, 1, drop = FALSE], ExampleDataBinary$ProvID),
    message = function(m) {
      messages <<- c(messages, conditionMessage(m))
      invokeRestart("muffleMessage")
    }
  )
  expect_length(messages, 8L)
  expect_identical(messages[8], "Checking VIF of covariates completed!\n")
  one <- check_data(y ~ z1, check_binary(), "hospital")
  expect_identical(nrow(one$correlations), 0L)
  expect_identical(one$design$vif, 1)
})
