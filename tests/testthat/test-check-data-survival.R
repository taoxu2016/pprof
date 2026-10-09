# check_data() for survival data (the CoxPH brief's §5.1; COXPH_DESIGN §C.1; DEC-104): it reports,
# and does not stop at, what data_prepare() and the Cox fits would reject or treat specially.
local_strict_mode()

check_survival_data <- function() {
  data.frame(
    time = c(5, 3, 8, 2, 7, 4, 6, 9, 1, 10, 3, 5),
    entry = c(0, 1, 2, 0, 3, 0, 1, 4, 0, 2, 0, 1),
    status = c(1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 0, 0),
    x = c(0.5, -1.2, 0.3, 2.1, -0.7, 1.4, 0.0, -0.4, 0.9, 1.8, 0.2, -0.1),
    w = c(1, 2, 0.5, 1, 0, 1.5, 1, 2, 1, 0.5, 1, 1),
    e = c(1, 2, 1, 4, 2, 1, 3, 1, 2, 1, 2, 1),
    patient = rep(c("a", "b", "c", "d", "e", "f"), 2),
    id = c(1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4)
  )
}

test_that("survival data get a report of their own, which prints with the other checks", {
  result <- check_data(Surv(time, status) ~ x, check_survival_data(), "id")
  survival <- result$survival
  expect_identical(survival$type, "right")
  expect_identical(survival$n_events, 6)
  expect_identical(survival$near_tied_rows, 0L)
  expect_identical(c(survival$zero_weights, survival$negative_weights, survival$invalid_status,
                     survival$invalid_times), c(0L, 0L, 0L, 0L))
  expect_identical(survival$providers_without_events, "4")
  expect_identical(survival$aliased, character())
  expect_identical(survival$large_mean, character())
  output <- capture.output(print(result))
  expect_identical(output[1],
                   "<pprof data check: 12 observations, 12 complete; survival data, right-censored, 6 events>")
  expect_true("Providers without events: 4" %in% output)
  counting <- check_data(Surv(entry, time, status) ~ x, check_survival_data(), "id")
  expect_identical(counting$survival$type, "counting")
})

test_that("weights, offsets, and clusters have their roles, and their missing values count", {
  d <- check_survival_data()
  d$w[3] <- NA
  d$patient[4] <- NA
  result <- check_data(Surv(time, status) ~ x + offset(log(e)), d, "id", weights = "w", cluster = "patient")
  expect_identical(result$table$variable, c("time", "status", "x", "e", "id", "w", "patient"))
  expect_identical(result$table$role, c("outcome", "outcome", "covariate", "offset", "provider", "weights", "cluster"))
  expect_identical(result$table$n_missing, c(0L, 0L, 0L, 0L, 0L, 1L, 1L))
  expect_identical(result$n_complete, 10L)
  expect_identical(result$survival$zero_weights, 1L)
})

test_that("invalid weights, statuses, and times are counted, not raised", {
  d <- check_survival_data()
  d$w[2] <- -1
  d$status_012 <- c(0, 1, 2, 1, 0, 2, 1, 1, 0, 1, 1, 1)
  d$late <- d$entry
  d$late[3] <- d$time[3]
  d$time_zero <- d$time
  d$time_zero[c(4, 7)] <- 0
  expect_identical(check_data(Surv(time, status) ~ x, d, "id", weights = "w")$survival$negative_weights, 1L)
  expect_identical(check_data(Surv(time, status_012) ~ x, d, "id")$survival$invalid_status, 3L)
  expect_identical(check_data(Surv(late, time, status) ~ x, d, "id")$survival$invalid_times, 1L)
  expect_identical(check_data(Surv(time_zero, status) ~ x, d, "id")$survival$invalid_times, 2L)
  output <- capture.output(print(check_data(Surv(time_zero, status) ~ x, d, "id")))
  expect_true(any(startsWith(output, "Invalid times: 2 rows")))
})

test_that("near-tied times are the rows survival's aeqSurv() would merge (M-23)", {
  d <- check_survival_data()
  d$time[2] <- d$time[1] + 1e-10
  result <- check_data(Surv(time, status) ~ x, d, "id")
  expect_identical(result$survival$near_tied_rows, 1L)
  expect_true(any(startsWith(capture.output(print(result)), "Near-tied times: 1 row ")))
})

test_that("covariates a provider-stratified fit cannot estimate, and large means, are listed", {
  d <- check_survival_data()
  d$size <- c(10, 10, 10, 20, 20, 20, 15, 15, 15, 30, 30, 30)
  d$double <- 2 * d$x
  d$year <- 2015 + c(0, 1, 0, 1, 0, 1, 0, 0, 1, 1, 0, 1) / 100
  result <- check_data(Surv(time, status) ~ x + size + double + year, d, "id")
  expect_setequal(result$survival$aliased, c("size", "double"))
  expect_identical(result$survival$large_mean, "year")
  output <- capture.output(print(result))
  expect_true(any(startsWith(output, "Linearly dependent within providers: ")))
  expect_true("Mean above 100 standard deviations: year" %in% output)
})

test_that("weights and clusters apply to survival data only, and other data are checked as before", {
  d <- check_survival_data()
  expect_error(check_data(status ~ x, d, "id", weights = "w"), class = "pprof_error_invalid_input")
  expect_error(check_data(status ~ x, d, "id", cluster = "patient"), class = "pprof_error_invalid_input")
  expect_error(check_data(Surv(time, status) ~ x, d, "id", weights = "weight"), class = "pprof_error_invalid_input")
  result <- check_data(status ~ x, d, "id")
  expect_null(result$survival)
  expect_false(any(grepl("survival", capture.output(print(result)), fixed = TRUE)))
})
