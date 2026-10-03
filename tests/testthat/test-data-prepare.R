# Unit tests of the data layer (data_prepare() and its helpers).
local_strict_mode()

toy_data <- function() {
  data.frame(
    y = c(1, 0, 1, 1, 0, 0, 1, 0, 1, 1),
    x = c(0.5, -1.2, 0.3, 2.1, -0.7, 1.4, 0.0, -0.4, 0.9, 1.8),
    f = factor(c("b", "a", "c", "a", "b", "c", "a", "b", "c", "a")),
    id = c(30, 4, 30, 200, 4, 4, 200, 30, 200, 30)
  )
}

reference_dataset_file <- function(name) {
  readRDS(test_path("fixtures", "reference", "datasets", paste0(name, ".rds")))
}

# A matrix with its values and dimensions only.
plain_matrix <- function(m) {
  attributes(m) <- list(dim = dim(m))
  m
}

test_that("providers are ordered by factor levels and observations sorted stably (K-05)", {
  d <- toy_data()
  p <- data_prepare(y ~ x, d, "id")
  expect_identical(p$providers$provider_id, c("4", "30", "200"))
  expect_identical(p$providers$provider_value, c(4, 30, 200))
  expect_identical(p$provider_index, c(1L, 1L, 1L, 2L, 2L, 2L, 2L, 3L, 3L, 3L))
  # Within a provider, rows keep their input order.
  expect_identical(p$row_index, c(2L, 5L, 6L, 1L, 3L, 8L, 10L, 4L, 7L, 9L))
  expect_identical(p$response, d$y[p$row_index])
  expect_identical(unname(p$design[, "x"]), d$x[p$row_index])
})

test_that("character IDs follow the collation order and factor IDs their level order", {
  d <- toy_data()
  withr::local_collate("C")
  d$id <- c("b", "B", "b", "a", "B", "B", "a", "b", "a", "b")
  expect_identical(data_prepare(y ~ x, d, "id")$providers$provider_id, c("B", "a", "b"))
  d$id <- factor(d$id, levels = c("b", "unused", "a", "B"))
  p <- data_prepare(y ~ x, d, "id")
  expect_identical(p$providers$provider_id, c("b", "a", "B"))
  expect_true(is.factor(p$providers$provider_value))
})

test_that("rows with a missing response, provider, or covariate are dropped, and no others (K-03)", {
  d <- toy_data()
  d$y[2] <- NA
  d$x[5] <- NA
  d$id[7] <- NA
  d$unused <- NA
  p <- data_prepare(y ~ x, d, "id")
  expect_identical(sort(p$row_index), setdiff(1:10, c(2L, 5L, 7L)))
  expect_identical(p$n_incomplete, 3L)
  expect_identical(p$n_input, 10L)
})

test_that("screening keeps providers with at least min_provider_size observations (K-06)", {
  d <- toy_data()
  p <- data_prepare(y ~ x, d, "id", min_provider_size = 4, event_counts = TRUE)
  expect_identical(p$providers$n_obs, c(3L, 4L, 3L))
  expect_identical(p$providers$included, c(FALSE, TRUE, FALSE))
  expect_identical(unique(p$provider_index), 2L)
  expect_identical(p$n_excluded_obs, 6L)
  # A provider with exactly min_provider_size observations is included.
  expect_identical(data_prepare(y ~ x, d, "id", min_provider_size = 3)$providers$included, c(TRUE, TRUE, TRUE))
  # Without min_provider_size every provider is kept (K-07).
  expect_true(all(data_prepare(y ~ x, d, "id")$providers$included))
})

test_that("event indicators flag included providers with no events or only events (K-06)", {
  d <- toy_data()
  d$y <- c(1, 0, 1, 1, 0, 0, 1, 1, 1, 1)
  p <- data_prepare(y ~ x, d, "id", event_counts = TRUE)
  expect_identical(p$providers$n_events, c(0, 4, 3))
  expect_identical(p$providers$no_events, c(TRUE, FALSE, FALSE))
  expect_identical(p$providers$all_events, c(FALSE, TRUE, TRUE))
  p <- data_prepare(y ~ x, d, "id", min_provider_size = 4, event_counts = TRUE)
  expect_identical(p$providers$no_events, c(FALSE, FALSE, FALSE))
  expect_identical(p$providers$all_events, c(FALSE, TRUE, FALSE))
})

test_that("fixed-effect designs drop the intercept and keep treatment coding (K-04)", {
  d <- toy_data()
  p <- data_prepare(y ~ x + f, d, "id")
  expect_identical(colnames(p$design), c("x", "fb", "fc"))
  expect_identical(attr(p$design, "assign"), c(1L, 2L, 2L))
  expect_identical(attr(p$design, "contrasts"), list(f = "contr.treatment"))
  reference <- stats::model.matrix(~ x + f, d)[p$row_index, -1, drop = FALSE]
  expect_identical(plain_matrix(p$design), plain_matrix(reference))
  expect_identical(p$xlevels, list(f = c("a", "b", "c")))
})

test_that("random-effect designs keep the intercept", {
  p <- data_prepare(y ~ x + f, toy_data(), "id", intercept = TRUE)
  expect_identical(colnames(p$design), c("(Intercept)", "x", "fb", "fc"))
  expect_identical(attr(p$design, "assign"), c(0L, 1L, 2L, 2L))
})

test_that("unused factor levels are kept as zero columns, as in the reference", {
  d <- toy_data()
  d$f <- factor(as.character(d$f), levels = c("a", "b", "c", "never"))
  p <- data_prepare(y ~ f, d, "id")
  expect_identical(colnames(p$design), c("fb", "fc", "fnever"))
  expect_true(all(p$design[, "fnever"] == 0))
})

test_that("a formula without covariates gives an empty design", {
  p <- data_prepare(y ~ 1, toy_data(), "id")
  expect_identical(dim(p$design), c(10L, 0L))
})

test_that("transformed and interaction terms work (D-18)", {
  d <- reference_dataset_file("syn_terms")
  for (rhs in c("z1 + z2 + log(w)", "z1 + z2 + z1:z2", "z1 + z2 + I(z1^2)")) {
    formula <- stats::as.formula(paste("Y ~", rhs))
    p <- data_prepare(formula, d, "ProvID")
    expected <- stats::model.matrix(formula, d)[p$row_index, -1, drop = FALSE]
    expect_identical(colnames(p$design), colnames(expected), info = rhs)
    expect_identical(plain_matrix(p$design), plain_matrix(expected), info = rhs)
  }
})

test_that("factor levels with spaces keep model.matrix() names (D-18)", {
  d <- reference_dataset_file("syn_factors")
  p <- data_prepare(Y ~ x1 + grp, d, "ProvID")
  expect_identical(colnames(p$design), c("x1", "grplevel three", "grplevel two"))
})

test_that("the within-between decomposition uses every row of the input data (K-54, D-13)", {
  d <- toy_data()
  d$y[1] <- NA
  p <- data_prepare(y ~ x + f, d, "id", within_between = "x", intercept = TRUE)
  expect_identical(colnames(p$design), c("(Intercept)", "x_within", "x_bar", "fb", "fc"))
  expect_identical(attr(p$terms, "term.labels"), c("x_within", "x_bar", "f"))
  # Row 1 is dropped for its missing response but still counts in its provider's mean.
  means <- vapply(split(d$x, d$id), mean, numeric(1))
  provider_of_row <- as.character(d$id[p$row_index])
  expect_identical(unname(p$design[, "x_bar"]), unname(means[provider_of_row]))
  expect_identical(unname(p$design[, "x_within"]), d$x[p$row_index] - unname(means[provider_of_row]))
  expect_false(1L %in% p$row_index)
})

test_that("provider means ignore missing covariate values", {
  d <- toy_data()
  d$x[2] <- NA
  p <- data_prepare(y ~ x, d, "id", within_between = "x", intercept = TRUE)
  expect_identical(unname(p$design[p$provider_index == 1L, "x_bar"]), rep(mean(c(-0.7, 1.4)), 2))
})

test_that("invalid inputs raise pprof_error_invalid_input", {
  d <- toy_data()
  invalid <- function(expr) expect_error(expr, class = "pprof_error_invalid_input")
  invalid(data_prepare("y ~ x", d, "id"))
  invalid(data_prepare(~ x, d, "id"))
  invalid(data_prepare(y ~ x, as.list(d), "id"))
  invalid(data_prepare(y ~ x, d, c("id", "y")))
  invalid(data_prepare(y ~ x, d, "hospital"))
  invalid(data_prepare(y ~ x + id, d, "id"))
  invalid(data_prepare(y ~ x + w, d, "id"))
  invalid(data_prepare(y ~ x + offset(x), d, "id"))
  invalid(data_prepare(y ~ x - 1, d, "id"))
  invalid(data_prepare(y ~ x, d, "id", min_provider_size = 0))
  invalid(data_prepare(y ~ x, d, "id", min_provider_size = 2.5))
  invalid(data_prepare(y ~ x, d, "id", within_between = "f", intercept = TRUE))
  invalid(data_prepare(y ~ x + f, d, "id", within_between = "f", intercept = TRUE))
  invalid(data_prepare(y ~ x, d, "id", within_between = "z", intercept = TRUE))
  invalid(data_prepare(f ~ x, d, "id"))
  d$x_bar <- 1
  invalid(data_prepare(y ~ x, d, "id", within_between = "x", intercept = TRUE))
})

test_that("data that support no model raise pprof_error_data", {
  d <- toy_data()
  expect_error(data_prepare(y ~ x, d[0, ], "id"), class = "pprof_error_data")
  d$x <- NA
  expect_error(data_prepare(y ~ x, d, "id"), class = "pprof_error_data")
  expect_error(data_prepare(y ~ f, toy_data(), "id", min_provider_size = 5), class = "pprof_error_data")
})

test_that("the validator rejects inconsistent objects", {
  p <- data_prepare(y ~ x, toy_data(), "id")
  broken <- p
  broken$provider_index <- rev(broken$provider_index)
  expect_error(validate_pprof_data(broken), class = "pprof_error_invalid_input")
  broken <- p
  broken$row_index <- broken$row_index[-1]
  expect_error(validate_pprof_data(broken), class = "pprof_error_invalid_input")
  broken <- p
  broken$providers$n_obs[1] <- 99L
  expect_error(validate_pprof_data(broken), class = "pprof_error_invalid_input")
  expect_identical(validate_pprof_data(p), p)
})

test_that("row_index holds positions in the input, whatever its row names", {
  d <- toy_data()
  rownames(d) <- paste0("patient", 10:1)
  p <- data_prepare(y ~ x, d, "id")
  expect_identical(p$row_index, c(2L, 5L, 6L, 1L, 3L, 8L, 10L, 4L, 7L, 9L))
})

test_that("printing a pprof_data object is compact", {
  p <- data_prepare(y ~ x + f, toy_data(), "id", min_provider_size = 4)
  output <- capture.output(print(p))
  expect_identical(output, c(
    "<pprof_data>",
    "Response: y; provider: id",
    "Observations: 4 used, 6 excluded by screening, 0 with missing values (of 10)",
    "Providers: 1 included, 2 excluded",
    "Design: 3 columns (x, fb, fc)"
  ))
})

test_that("the provider factor is factor() of the provider rows", {
  withr::local_seed(3)
  index <- sample(8L, 200L, replace = TRUE)
  for (levels in list(seq_len(8L), c(2L, 5L, 7L), 8:1, integer(0), c(3, 6))) {
    expect_identical(data_provider_factor(index, levels), factor(index, levels = levels))
    expect_identical(split(seq_along(index), data_provider_factor(index, levels)),
                     split(seq_along(index), factor(index, levels = levels)))
  }
})
