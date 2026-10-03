# Intervals of standardized measures for providers with no events or only events (K-91),
# whose one-sided rules the reference fixtures exercise only in part.
local_strict_mode()

extreme_fit <- function() {
  withr::with_collate("C", {
    fixture <- reference_fixture("logis_fe-extreme")
    args <- model_case_arguments(fixture$case, reference_datasets_for(fixture$case, "core"))
    suppressWarnings(do.call(fit_logistic_fe, args))
  })
}

test_that("providers with no events or only events have the reference's one-sided measure limits (K-91)", {
  fit <- extreme_fit()
  providers <- provider_table(fit)
  no_events <- providers$provider_id[providers$no_events]
  all_events <- providers$provider_id[providers$all_events]
  expect_length(no_events, 3L)
  expect_length(all_events, 2L)
  n <- length(fit$response)
  total <- sum(fit$response)
  for (alternative in c("two.sided", "greater", "less")) {
    table <- standardize_providers(fit, c("indirect", "direct"), "ratio", interval = "score",
                                   alternative = alternative)$table
    indirect <- table[table$standardization == "indirect", ]
    direct <- table[table$standardization == "direct", ]
    none <- indirect$provider_id %in% no_events
    only <- indirect$provider_id %in% all_events
    expect_identical(indirect$lower[none], rep(0, 3))
    expect_identical(direct$lower[none], rep(0, 3))
    expect_identical(indirect$upper[only], indirect$n_obs[only] / indirect$expected[only])
    expect_identical(direct$upper[only], rep(n / total, 2))
    if (alternative == "greater") {
      expect_identical(indirect$upper[none], indirect$n_obs[none] / indirect$expected[none])
      expect_identical(direct$upper[none], rep(n / total, 3))
    } else {
      expect_true(all(indirect$upper[none] > 0 & indirect$upper[none] < indirect$n_obs[none] / indirect$expected[none]))
    }
    if (alternative == "less") {
      expect_identical(indirect$lower[only], c(0, 0))
      expect_identical(direct$lower[only], c(0, 0))
    } else {
      expect_true(all(indirect$lower[only] > 0))
    }
  }
})

test_that("finite providers' one-sided measure limits open at 0 or at all events (K-91, K-94)", {
  fit <- extreme_fit()
  finite <- !(provider_table(fit)$no_events | provider_table(fit)$all_events)
  greater <- standardize_providers(fit, "indirect", "ratio", interval = "exact", alternative = "greater")$table
  expect_identical(greater$upper[finite], greater$n_obs[finite] / greater$expected[finite])
  less <- standardize_providers(fit, "indirect", "ratio", interval = "exact", alternative = "less")$table
  expect_identical(less$lower[finite], rep(0, sum(finite)))
})

test_that("rate limits are ratio limits times the population rate, clipped to [0, 100] (K-80, K-91)", {
  fit <- extreme_fit()
  measures <- standardize_providers(fit, c("indirect", "direct"), interval = "score")
  table <- measures$table
  for (method in c("indirect", "direct")) {
    ratio <- table[table$standardization == method & table$measure == "ratio", ]
    rate <- table[table$standardization == method & table$measure == "rate", ]
    clip <- function(x) pmax(pmin(x * measures$population_rate, 100), 0)
    expect_identical(rate$estimate, clip(ratio$estimate))
    expect_identical(rate$lower, clip(ratio$lower))
    expect_identical(rate$upper, clip(ratio$upper))
  }
  expect_true(any(table$measure == "rate" & table$upper == 100))
})

test_that("effect intervals of providers with no events or only events are one-sided (K-90)", {
  fit <- extreme_fit()
  providers <- provider_table(fit)
  for (interval in c("exact", "score")) {
    effects <- provider_effects(fit, interval)$table
    expect_identical(effects$lower[providers$no_events], rep(-Inf, 3))
    expect_identical(effects$upper[providers$all_events], rep(Inf, 2))
    expect_true(all(is.finite(effects$upper[providers$no_events])))
    expect_true(all(is.finite(effects$lower[providers$all_events])))
  }
})
