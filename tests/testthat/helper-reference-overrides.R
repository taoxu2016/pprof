# Per-case expectations for Class A fixes (DEC-022, Phase 3 plan decision 2).
#
# Where the compatibility wrappers fix a reference defect (a crash, a NULL, misaligned
# results), the case no longer matches what its fixture recorded. Each entry here cites its
# register entry and gives the expected result instead, derived from fixtures where the
# reference is right: the fixture files are never edited. The equivalence report marks
# these cases.

reference_override <- function(entry, expected = NULL, error_class = NULL, check = NULL, tier = NULL) {
  list(entry = entry, expected = expected, error_class = error_class, check = check, tier = tier)
}

# The value of another case's fixture.
override_value <- function(id) reference_fixture(id)$result$value

# The first rows of a test() result, with their provider sizes, as the reference's `parm`
# selects them from a test of every provider.
override_first_rows <- function(value, n) {
  selected <- value[seq_len(n), ]
  attr(selected, "provider size") <- attr(value, "provider size")[seq_len(n)]
  selected
}

# A fixture's result record with another value, iteration count, and outcome.
override_result <- function(fixture, value, iterations = NA_integer_, probe_identical = NA) {
  result <- fixture$result
  result$outcome <- "value"
  result$value <- value
  result["error"] <- list(NULL)
  result$iterations <- iterations
  result$probe_identical <- probe_identical
  result
}

# D-18: the fit of a formula with transformed terms, interactions, or factor levels with
# spaces is the reference's fit of the same model with plain columns, renamed: the
# coefficient names become the model.matrix() names and the data_include columns their
# make.names() versions.
override_renamed_fit <- function(columns_id, renames) {
  function(fixture) {
    source <- reference_fixture(columns_id)
    value <- source$result$value
    rename <- function(x) {
      at <- match(x, names(renames))
      x[!is.na(at)] <- unname(renames[at[!is.na(at)]])
      x
    }
    rownames(value$coefficient$beta) <- rename(rownames(value$coefficient$beta))
    dimnames(value$variance$beta) <- lapply(dimnames(value$variance$beta), rename)
    value$char_list$Z.char <- rename(value$char_list$Z.char)
    names(value$data_include) <- make.names(rename(names(value$data_include)), unique = TRUE)
    override_result(fixture, value, source$result$iterations, source$result$probe_identical)
  }
}

# D-19: the reference pairs the measure limits of character IDs with the wrong providers:
# it computes them for the providers with events and non-events, then those with no events,
# then those with only events, and orders them by as.numeric(ID), which is NA for every
# character ID. Row k of its tables holds the limits of the k-th provider in that order.
override_d19_limit_order <- function(parent_value) {
  data <- parent_value$data_include
  id <- parent_value$char_list$ProvID.char
  computed <- c(unique(data[data$no.events == 0 & data$all.events == 0, id]), unique(data[data$no.events == 1, id]),
                unique(data[data$all.events == 1, id]))
  as.character(computed[order(suppressWarnings(as.numeric(computed)))])
}

override_d19_repair <- function(tables, order) {
  lapply(tables, function(table) {
    at <- match(rownames(table), order)
    table[[2]] <- table[[2]][at]
    table[[3]] <- table[[3]][at]
    table
  })
}

# D-30: K-101 from the reference's fits: the two-covariate fit and, for each covariate, the
# fit without it.
override_lr_two_covariates <- function(fixture) {
  full <- override_value("logis_fe-screening-twocov")
  data <- full$data_include
  sizes <- as.integer(table(factor(data$ProvID, levels = unique(data$ProvID))))
  neg2_loglik <- function(value, covariates) {
    gamma <- value$coefficient$gamma
    gamma_obs <- rep(pmax(pmin(gamma, stats::median(gamma) + 10), stats::median(gamma) - 10), sizes)
    eta <- gamma_obs + as.matrix(data[, covariates, drop = FALSE]) %*% value$coefficient$beta
    -2 * sum(eta * data$Y - log(1 + exp(eta)))
  }
  reference <- neg2_loglik(full, c("x1", "x2"))
  statistic <- c(neg2_loglik(override_value("logis_fe-screening-x2"), "x2"),
                 neg2_loglik(override_value("logis_fe-screening-onecov"), "x1")) - reference
  value <- data.frame(full$coefficient$beta[1:2], statistic, stats::pchisq(statistic, 1, lower.tail = FALSE))
  rownames(value) <- c("x1", "x2")
  colnames(value) <- c("Estimate", "stat", "p value")
  override_result(fixture, value)
}

# D-04: the reference fails; the wrapper keeps every provider, with a missing p-value and
# flag where the statistic is not finite (provider 5), and gives the other providers the
# values the reference computes when it is asked only for them, which it can do with the
# same data and double IDs (test-d04-score-standard-others; D-27).
override_check_d04 <- function(actual) {
  value <- actual$value
  undefined <- !is.finite(value$stat)
  others <- reference_fixture("test-d04-score-standard-others")$result$value
  ok <- identical(actual$outcome, "value") && nrow(value) == 30L && identical(rownames(value)[undefined], "5") &&
    is.na(value[["p value"]][undefined]) && is.na(value$flag[undefined]) &&
    identical(rownames(value)[!undefined], rownames(others)) && identical(value$stat[!undefined], others$stat) &&
    identical(value[["p value"]][!undefined], others[["p value"]]) &&
    identical(as.character(value$flag[!undefined]), as.character(others$flag))
  if (ok) NULL else "the D-04 standard score test does not match the reference's values with provider 5 in place"
}

reference_overrides <- list(
  "logis_fe-binary-ban-backtrack2" = reference_override("D-23", error_class = "pprof_error_invalid_input"),
  "logis_fe-terms-logw" = reference_override("D-18", override_renamed_fit("logis_fe-terms-logw-columns",
                                                                          c(logw = "log(w)"))),
  "logis_fe-terms-z1z2" = reference_override("D-18", override_renamed_fit("logis_fe-terms-z1z2-columns",
                                                                          c(z1z2 = "z1:z2"))),
  "logis_fe-terms-z12" = reference_override("D-18", override_renamed_fit("logis_fe-terms-z12-columns",
                                                                         c(z1sq = "I(z1^2)"))),
  "logis_fe-factors-spaces-formula" = reference_override(
    "D-18", override_renamed_fit("logis_fe-factors-nospaces-formula",
                                 c(grplevel_three = "grplevel three", grplevel_two = "grplevel two"))
  ),
  "test-binary-robust-wald" = reference_override("D-06", error_class = "pprof_error_invalid_input"),
  "test-extreme-int-parm" = reference_override("D-27", function(fixture) {
    all <- override_value("test-extreme-exact")
    value <- all[1:3, ]
    value$flag <- droplevels(value$flag)
    attr(value, "provider size") <- attr(all, "provider size")[1:3]
    override_result(fixture, value)
  }, tier = "iterative"),
  "test-d04-score-standard" = reference_override("D-04", check = override_check_d04),
  "SM_output-binary-null-integer" = reference_override("D-14", function(fixture) {
    override_result(fixture, override_value("SM_output-binary-null0"))
  }, tier = "iterative"),
  "plot-binary-null-integer" = reference_override("D-14", function(fixture) {
    override_result(fixture, override_value("plot-binary-null0"))
  }, tier = "iterative"),
  "confint-extreme-chr-gamma-exact" = reference_override("D-19", function(fixture) {
    value <- fixture$result$value
    order <- rownames(override_value("logis_fe-extreme-chr")$coefficient$gamma)
    override_result(fixture, value[order, ])
  }),
  "confint-extreme-chr-sm-exact" = reference_override("D-19", function(fixture) {
    order <- override_d19_limit_order(override_value("logis_fe-extreme-chr"))
    override_result(fixture, override_d19_repair(fixture$result$value, order))
  }),
  "confint-extreme-fac-gamma-exact" = reference_override("D-28", function(fixture) {
    value <- override_value("confint-extreme-gamma-exact")
    rownames(value) <- as.character(as.integer(rownames(value)) * 10L)
    override_result(fixture, value)
  }, tier = "root"),
  "confint-extreme-hospital-sm-direct" = reference_override("D-29", function(fixture) {
    override_result(fixture, override_value("confint-extreme-sm-exact")[c("CI.direct_ratio", "CI.direct_rate")])
  }, tier = "root"),
  "summary-screening-twocov-lr" = reference_override("D-30", override_lr_two_covariates, tier = "iterative"),
  # D-30: with one covariate the package raises a classed error, approved when pprof 1.0.3
  # failed here in reformulate(), as it does up to R 4.4. From R 4.5.0 reformulate() accepts no
  # terms, and pprof 1.0.3 returns the likelihood-ratio test against the model with provider
  # effects only; that difference awaits the project lead's decision (Phase 8).
  "summary-screening-onecov-lr" = reference_override("D-30", error_class = "pprof_error_unsupported_inference"),
  # Phase 5. D-14: the linear FE methods accept an integer null as the equal double.
  "test-linear-null-integer" = reference_override("D-14", function(fixture) {
    override_result(fixture, override_value("test-linear-null0"))
  }, tier = "closed_form"),
  "SM_output-linear-null-integer" = reference_override("D-14", function(fixture) {
    override_result(fixture, override_value("SM_output-linear-both-null0"))
  }, tier = "closed_form"),
  "confint-linear-null-integer" = reference_override("D-14", function(fixture) {
    override_result(fixture, override_value("confint-linear-null0"))
  }, tier = "closed_form"),
  "plot-linear-null-integer" = reference_override("D-14", function(fixture) {
    override_result(fixture, override_value("plot-linear-null0"))
  }, tier = "closed_form"),
  # D-27: providers stored as integers are selected with `parm`. The Wald tests of these
  # methods test every provider before selecting rows, so the flag factor keeps the levels of
  # all providers (D-15), unlike the exact test above.
  "test-linear-syn-int-parm" = reference_override("D-27", function(fixture) {
    override_result(fixture, override_first_rows(override_value("test-linear-syn-int"), 3L))
  }, tier = "closed_form"),
  "test-logis-cre-extreme-int-parm" = reference_override("D-27", function(fixture) {
    override_result(fixture, override_first_rows(override_value("test-logis-cre-extreme-two.sided"), 3L))
  }, tier = "lme4")
)

# The expected result of a case: its fixture's, or the override's.
reference_expected_result <- function(id, set = "core") {
  fixture <- reference_fixture(id, set)
  override <- reference_overrides[[id]]
  if (is.null(override) || is.null(override$expected)) {
    result <- fixture$result
    if (!is.null(override$error_class)) {
      result$outcome <- "error"
      result$value <- NULL
    }
    return(result)
  }
  override$expected(fixture)
}

reference_case_tier <- function(id, set = "core") {
  override <- reference_overrides[[id]]
  if (!is.null(override$tier)) override$tier else reference_fixture(id, set)$case$tier
}
