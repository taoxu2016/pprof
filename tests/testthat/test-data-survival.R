# Survival data in the data layer (COXPH_DESIGN §C.1; the CoxPH C2 plan, §3.1; K-131, K-139).
local_strict_mode()

survival_data <- function() {
  data.frame(
    time = c(5, 3, 8, 2, 7, 4, 6, 9, 1, 10),
    entry = c(0, 1, 2, 0, 3, 0, 1, 4, 0, 2),
    status = c(1, 0, 1, 1, 0, 1, 0, 1, 1, 0),
    x = c(0.5, -1.2, 0.3, 2.1, -0.7, 1.4, 0.0, -0.4, 0.9, 1.8),
    f = factor(c("b", "a", "c", "a", "b", "c", "a", "b", "c", "a")),
    w = c(1, 2, 0.5, 1, 0, 1.5, 1, 2, 1, 0.5),
    e = c(1, 2, 1, 4, 2, 1, 3, 1, 2, 1),
    patient = c("p3", "p1", "p3", "p2", "p1", "p4", "p2", "p5", "p4", "p5"),
    id = c(30, 4, 30, 200, 4, 4, 200, 30, 200, 30)
  )
}

prepare_survival <- function(formula, data = survival_data(), ...) {
  data_prepare(formula, data, "id", response_type = "survival", event_counts = TRUE, ...)
}

# The elements of a prepared object that describe the observations, without the formula.
observation_elements <- c("response", "design", "providers", "provider_index", "row_index", "start", "stop",
                          "weights", "cluster", "offset")

test_that("right-censored data keep the status as the response, start 0, and stop the time (K-131)", {
  d <- survival_data()
  p <- prepare_survival(Surv(time, status) ~ x, d)
  expect_identical(p$row_index, c(2L, 5L, 6L, 1L, 3L, 8L, 10L, 4L, 7L, 9L))
  expect_identical(p$response, d$status[p$row_index])
  expect_identical(p$start, rep(0, 10))
  expect_identical(p$stop, d$time[p$row_index])
  expect_identical(p$settings$response_type, "survival")
  expect_identical(p$settings$survival_type, "right")
  expect_identical(names(p$settings), c("min_provider_size", "intercept", "event_counts", "response_type", "weights",
                                        "cluster", "allow_offset", "survival_type"))
  expect_null(p$weights)
  expect_null(p$offset)
  expect_identical(colnames(p$design), "x")
})

test_that("counting-process data keep the entry and exit times", {
  d <- survival_data()
  p <- prepare_survival(Surv(entry, time, status) ~ x + f, d)
  expect_identical(p$settings$survival_type, "counting")
  expect_identical(p$start, d$entry[p$row_index])
  expect_identical(p$stop, d$time[p$row_index])
  expect_identical(colnames(p$design), c("x", "fb", "fc"))
})

test_that("the provider table counts events of every row and sums person-time (K-137, K-139)", {
  d <- survival_data()
  p <- prepare_survival(Surv(entry, time, status) ~ x, d)
  expect_identical(p$providers$provider_id, c("4", "30", "200"))
  expect_identical(p$providers$n_events, c(1, 3, 2))
  expected_time <- vapply(split(d$time - d$entry, factor(d$id)), sum, numeric(1), USE.NAMES = FALSE)
  expect_identical(p$providers$person_time, expected_time)
})

test_that("a status coded 1/2 or logical gives the data of the status coded 0/1 (D-74)", {
  d <- survival_data()
  reference <- prepare_survival(Surv(time, status) ~ x, d)
  d$status_12 <- d$status + 1
  d$status_lgl <- d$status == 1
  for (formula in list(Surv(time, status_12) ~ x, Surv(time, status_lgl) ~ x, Surv(time, status == 1) ~ x)) {
    p <- prepare_survival(formula, d)
    for (element in observation_elements) expect_identical(p[[element]], reference[[element]], info = element)
  }
})

test_that("survival::Surv() is accepted, and Surv() is re-exported", {
  d <- survival_data()
  reference <- prepare_survival(Surv(time, status) ~ x, d)
  p <- prepare_survival(survival::Surv(time, status) ~ x, d)
  expect_identical(p$response, reference$response)
  expect_identical(Surv, survival::Surv)
})

test_that("an invalid status or interval is an error, not a missing value", {
  d <- survival_data()
  invalid <- function(expr) expect_error(expr, class = "pprof_error_invalid_input")
  d$status_012 <- c(0, 1, 2, 1, 0, 2, 1, 1, 0, 1)
  invalid(prepare_survival(Surv(time, status_012) ~ x, d))
  d$status_23 <- d$status + 2
  invalid(prepare_survival(Surv(time, status_23) ~ x, d))
  d$late <- d$time
  d$late[3] <- d$entry[3]
  invalid(prepare_survival(Surv(late, time, status) ~ x, d))
  invalid(prepare_survival(Surv(time, entry, status) ~ x, d))
  d$time_zero <- d$time
  d$time_zero[4] <- 0
  invalid(prepare_survival(Surv(time_zero, status) ~ x, d))
  d$time_negative <- d$time
  d$time_negative[4] <- -1
  invalid(prepare_survival(Surv(time_negative, status) ~ x, d))
  d$time_infinite <- d$time
  d$time_infinite[4] <- Inf
  invalid(prepare_survival(Surv(time_infinite, status) ~ x, d))
  # The error says what is wrong and in how many rows: Surv() reads 0/1/2 as 1/2 coding, so the
  # three zeros are the invalid ones.
  expect_error(prepare_survival(Surv(time, status_012) ~ x, d), "3 rows with a status")
})

test_that("only right-censored and counting-process responses with a 0/1 status are accepted", {
  d <- survival_data()
  invalid <- function(expr) expect_error(expr, class = "pprof_error_invalid_input")
  d$cause <- factor(c(0, 1, 2, 1, 0, 2, 1, 1, 0, 1))
  expect_error(prepare_survival(Surv(time, cause) ~ x, d), "status == 1", class = "pprof_error_invalid_input")
  invalid(prepare_survival(Surv(time, status, type = "left") ~ x, d))
  invalid(prepare_survival(time ~ x, d))
  invalid(data_prepare(Surv(time, status) ~ x, d, "id"))
})

test_that("Cox formulas have no special terms of coxph() and no intercept to remove", {
  d <- survival_data()
  invalid <- function(expr) expect_error(expr, class = "pprof_error_invalid_input")
  strata <- survival::strata
  cluster <- function(x) x
  invalid(prepare_survival(Surv(time, status) ~ x + strata(f), d))
  invalid(prepare_survival(Surv(time, status) ~ x + cluster(patient), d))
  invalid(prepare_survival(Surv(time, status) ~ x - 1, d))
  invalid(prepare_survival(Surv(time, status) ~ x, d, intercept = TRUE))
  invalid(data_prepare(Surv(time, status) ~ x, d, "id", response_type = "survival", within_between = "x"))
})

test_that("weights are kept, zeros included, and must be finite and not negative", {
  d <- survival_data()
  p <- prepare_survival(Surv(time, status) ~ x, d, weights = "w")
  expect_identical(p$weights, d$w[p$row_index])
  expect_identical(p$settings$weights, "w")
  d$w[2] <- -1
  expect_error(prepare_survival(Surv(time, status) ~ x, d, weights = "w"), class = "pprof_error_invalid_input")
  d$w <- as.character(survival_data()$w)
  expect_error(prepare_survival(Surv(time, status) ~ x, d, weights = "w"), class = "pprof_error_invalid_input")
  expect_error(prepare_survival(Surv(time, status) ~ x, d, weights = "weight"), class = "pprof_error_invalid_input")
})

test_that("clusters are coded as coxph() codes them (DEC-100)", {
  d <- survival_data()
  p <- prepare_survival(Surv(time, status) ~ x, d, cluster = "patient")
  in_order <- d$patient[p$row_index]
  expect_identical(p$cluster, match(in_order, unique(in_order)))
  d$patient <- factor(d$patient, levels = c("p5", "p4", "p3", "p2", "p1", "unused"))
  p <- prepare_survival(Surv(time, status) ~ x, d, cluster = "patient")
  expect_identical(p$cluster, d$patient[p$row_index])
})

test_that("offset() terms are summed when allowed and rejected otherwise", {
  d <- survival_data()
  p <- prepare_survival(Surv(time, status) ~ x + offset(log(e)) + offset(x), d, allow_offset = TRUE)
  expect_identical(p$offset, (log(d$e) + d$x)[p$row_index])
  expect_identical(colnames(p$design), "x")
  expect_error(prepare_survival(Surv(time, status) ~ x + offset(log(e)), d), class = "pprof_error_invalid_input")
  # An offset that is not finite is an error; one that is missing, such as log() of a negative
  # number, drops its row, as for any transformed variable (K-03).
  d$e[3] <- 0
  expect_error(prepare_survival(Surv(time, status) ~ x + offset(log(e)), d, allow_offset = TRUE),
               class = "pprof_error_invalid_input")
  expect_error(prepare_survival(Surv(time, status) ~ x + offset(log(missing_column)), d, allow_offset = TRUE),
               class = "pprof_error_invalid_input")
})

test_that("rows with a missing value anywhere in the model are dropped (K-03, D-62)", {
  d <- survival_data()
  formula <- Surv(entry, time, status) ~ x + offset(log(e))
  complete <- prepare_survival(formula, d[-c(2, 4, 5, 7, 8, 9), ], weights = "w", cluster = "patient",
                               allow_offset = TRUE)
  d$time[2] <- NA
  d$status[4] <- NA
  d$x[5] <- NA
  d$w[7] <- NA
  d$patient[8] <- NA
  d$e[9] <- NA
  p <- prepare_survival(formula, d, weights = "w", cluster = "patient", allow_offset = TRUE)
  expect_identical(p$n_incomplete, 6L)
  expect_identical(sort(p$row_index), c(1L, 3L, 6L, 10L))
  for (element in setdiff(observation_elements, "row_index")) {
    expect_identical(p[[element]], complete[[element]], info = element)
  }
})

test_that("the existing families' data have none of the survival elements", {
  d <- survival_data()
  p <- data_prepare(status ~ x, d, "id", event_counts = TRUE)
  expect_identical(names(p), c("formula", "terms", "xlevels", "response_name", "provider_name", "within_between",
                               "response", "design", "providers", "provider_index", "row_index", "settings",
                               "n_input", "n_incomplete", "n_excluded_obs"))
  expect_identical(names(p$settings), c("min_provider_size", "intercept", "event_counts"))
  expect_false("person_time" %in% names(p$providers))
  expect_identical(names(model_data_spec(p)), c("response_name", "provider_name", "within_between", "xlevels",
                                                "contrasts", "intercept", "min_provider_size", "event_counts"))
})

test_that("the model's data specification records the survival settings", {
  p <- prepare_survival(Surv(time, status) ~ x, weights = "w", cluster = "patient")
  spec <- model_data_spec(p)
  expect_identical(spec[c("response_type", "weights", "cluster", "allow_offset")],
                   list(response_type = "survival", weights = "w", cluster = "patient", allow_offset = FALSE))
})

test_that("the validator rejects inconsistent survival data", {
  p <- prepare_survival(Surv(entry, time, status) ~ x, weights = "w", cluster = "patient")
  rejected <- function(x) expect_error(validate_pprof_data(x), class = "pprof_error_invalid_input")
  x <- p
  x$start[1] <- x$stop[1]
  rejected(x)
  x <- p
  x$stop <- x$stop[-1]
  rejected(x)
  x <- p
  x$response[1] <- 2
  rejected(x)
  x <- p
  x$weights[1] <- -1
  rejected(x)
  x <- p
  x$cluster[1] <- NA
  rejected(x)
  x <- p
  x$providers$person_time <- NULL
  rejected(x)
  x <- p
  x$settings$survival_type <- "right"
  rejected(x)
  expect_identical(validate_pprof_data(p), p)
})

# --- Competing risks (the CoxPH C5 plan, §3.1 and decision 3) --------------------------------------

competing_data <- function() {
  d <- survival_data()
  d$cause <- factor(c(0, 1, 2, 1, 0, 2, 1, 1, 0, 2), levels = 0:2)
  d
}

prepare_competing <- function(formula, data = competing_data(), ...) {
  data_prepare(formula, data, "id", response_type = "competing_risks", ...)
}

test_that("a competing-risks response keeps each observation's state and the event types", {
  d <- competing_data()
  p <- prepare_competing(Surv(time, cause) ~ x, d)
  expect_identical(p$response, as.numeric(as.character(d$cause))[p$row_index])
  expect_identical(p$settings$states, c("1", "2"))
  expect_identical(p$settings$response_type, "competing_risks")
  expect_identical(p$settings$survival_type, "right")
  expect_identical(p$start, rep(0, 10))
  expect_identical(p$stop, d$time[p$row_index])
  expect_false(any(c("n_events", "person_time") %in% names(p$providers)))
  counting <- prepare_competing(Surv(entry, time, cause) ~ x, d)
  expect_identical(counting$settings$survival_type, "counting")
  expect_identical(counting$start, d$entry[counting$row_index])
  # Labels and unused event types: the factor's levels after the first, whatever they are called.
  labels <- c("none", "relapse", "death", "transplant")
  d$label <- factor(labels[as.integer(d$cause)], levels = labels)
  labelled <- prepare_competing(Surv(time, label) ~ x, d)
  expect_identical(labelled$settings$states, c("relapse", "death", "transplant"))
  expect_identical(labelled$response, p$response)
  # The times, design, providers, weights, and clusters are those of the survival data of any event.
  reference <- prepare_survival(Surv(entry, time, cause != "0") ~ x, d, weights = "w", cluster = "patient")
  competing <- prepare_competing(Surv(entry, time, cause) ~ x, d, weights = "w", cluster = "patient")
  for (element in setdiff(observation_elements, c("response", "providers"))) {
    expect_identical(competing[[element]], reference[[element]], info = element)
  }
  expect_identical(competing$providers[c("provider_id", "n_obs", "included")],
                   reference$providers[c("provider_id", "n_obs", "included")])
  expect_identical(competing$response > 0, reference$response == 1)
})

test_that("a competing-risks response needs a factor status and no event counts (D-74)", {
  d <- competing_data()
  invalid <- function(expr) expect_error(expr, class = "pprof_error_invalid_input")
  # A numeric status coded 0/1/2, which Surv() reads as 1/2 coding with its zeros missing.
  d$code <- as.numeric(as.character(d$cause))
  expect_error(prepare_competing(Surv(time, code) ~ x, d), "factor", class = "pprof_error_invalid_input")
  invalid(prepare_competing(Surv(time, status) ~ x, d))
  invalid(prepare_competing(Surv(time, cause) ~ x, d, event_counts = TRUE))
  strata <- survival::strata
  invalid(prepare_competing(Surv(time, cause) ~ x + strata(f), d))
  d$late <- d$time
  d$late[3] <- d$entry[3]
  invalid(prepare_competing(Surv(late, time, cause) ~ x, d))
  # A factor status in a Cox model's data names both models for several event types.
  expect_error(prepare_survival(Surv(time, cause) ~ x, d), "fit_fine_gray", class = "pprof_error_invalid_input")
})

test_that("a missing status drops its row (D-62)", {
  d <- competing_data()
  complete <- prepare_competing(Surv(time, cause) ~ x, d[-4, ])
  d$cause[4] <- NA
  p <- prepare_competing(Surv(time, cause) ~ x, d)
  expect_identical(p$n_incomplete, 1L)
  expect_false(4L %in% p$row_index)
  expect_identical(p$response, complete$response)
})

test_that("the model's data specification records the competing-risks settings", {
  p <- prepare_competing(Surv(time, cause) ~ x, weights = "w", cluster = "patient")
  spec <- model_data_spec(p)
  expect_identical(spec[c("response_type", "weights", "cluster", "allow_offset")],
                   list(response_type = "competing_risks", weights = "w", cluster = "patient", allow_offset = FALSE))
})

test_that("the validator checks the states of competing-risks data", {
  p <- prepare_competing(Surv(entry, time, cause) ~ x, weights = "w", cluster = "patient")
  rejected <- function(x) expect_error(validate_pprof_data(x), class = "pprof_error_invalid_input")
  x <- p
  x$response[1] <- 3
  rejected(x)
  x <- p
  x$response[1] <- 0.5
  rejected(x)
  x <- p
  x$settings$states <- NULL
  rejected(x)
  x <- p
  x$start[1] <- x$stop[1]
  rejected(x)
  expect_identical(validate_pprof_data(p), p)
})

test_that("no complete rows, and times that are not finite, are errors", {
  d <- survival_data()
  d$x <- NA_real_
  expect_error(prepare_survival(Surv(time, status) ~ x, d), class = "pprof_error_data")
  d <- survival_data()
  d$time[1] <- Inf
  expect_error(prepare_survival(Surv(time, status) ~ x, d), class = "pprof_error_invalid_input")
  expect_error(prepare_survival(Surv(entry, time, status) ~ x, d), class = "pprof_error_invalid_input")
})

test_that("the survival response's helpers refuse what is not a Surv() response of their type", {
  frame <- stats::model.frame(time ~ x, survival_data())
  expect_identical(data_survival_frame_problems(frame), list(status = integer(), times = integer()))
  expect_error(data_survival_response(frame), class = "pprof_error_invalid_input")
  right <- stats::model.frame(survival::Surv(time, status) ~ x, survival_data())
  expect_error(data_survival_response(right, competing = TRUE), class = "pprof_error_invalid_input")
})

test_that("the validator also checks the type of survival data and the offset", {
  p <- prepare_survival(Surv(time, status) ~ x + offset(e), allow_offset = TRUE)
  rejected <- function(x) expect_error(validate_pprof_data(x), class = "pprof_error_invalid_input")
  x <- p
  x$settings$survival_type <- "interval"
  rejected(x)
  x <- p
  x$offset[1] <- Inf
  rejected(x)
  expect_identical(validate_pprof_data(p), p)
})
