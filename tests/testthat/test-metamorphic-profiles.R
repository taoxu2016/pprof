# Metamorphic relations of the profiling results of the linear FE, RE, and CRE families
# (brief §6 F, Phase 5): relabeling the providers without changing their order, with numeric,
# character, or factor IDs, leaves every result identical except the labels; shuffling the
# rows changes linear FE results only within the closed-form tier. lme4's estimates move at
# its optimizer's precision when the rows are reordered, so the lme4 fits get only the exact
# relation (DEC-043).
local_strict_mode()

metamorphic_relabel <- function(data, scheme) {
  ids <- data$hospital
  data$hospital <- switch(scheme,
    character = sprintf("H%03d", ids),
    factor = factor(sprintf("H%03d", ids)),
    numeric = ids * 10
  )
  data
}

# Every profiling and covariate result of a model, with the provider IDs removed from the
# tables so that two labelings can be compared.
metamorphic_results <- function(fit) {
  strip <- function(result) {
    result$table$provider_id <- NULL
    if (!is.null(result$providers)) result$providers$provider_id <- NULL
    result
  }
  results <- list(
    tests = test_providers(fit),
    tests_less = test_providers(fit, alternative = "less", level = 0.9),
    effects = provider_effects(fit, interval = "wald"),
    measures = standardize_providers(fit, c("indirect", "direct"), interval = "wald", alternative = "greater"),
    coefficients = test_coefficients(fit)
  )
  if ("funnel" %in% inference_capabilities(fit)) results$funnel <- funnel_limits(fit, level = c(0.95, 0.99))
  lapply(results, strip)
}

metamorphic_fit <- function(family, data) {
  formula <- if (family %in% c("linear_fe", "linear_re", "linear_cre")) {
    y ~ z1 + z2 + z3 + z4 + z5
  } else {
    y ~ x1 + x2
  }
  withr::local_collate("C")
  suppressMessages(switch(family,
    linear_fe = fit_linear_fe(formula, data, "hospital", provider_variance = "full"),
    linear_re = fit_linear_re(formula, data, "hospital"),
    linear_cre = fit_linear_cre(formula, data, "hospital", within_between = "z1"),
    logistic_re = fit_logistic_re(formula, data, "hospital"),
    logistic_cre = fit_logistic_cre(formula, data, "hospital", within_between = "x1")
  ))
}

metamorphic_data <- function(family) {
  if (family %in% c("linear_fe", "linear_re", "linear_cre")) {
    data(ExampleDataLinear, package = "pprof", envir = environment())
    data.frame(y = ExampleDataLinear$Y, hospital = ExampleDataLinear$ProvID, ExampleDataLinear$Z)
  } else {
    withr::local_seed(8)
    m <- 30
    hospital <- rep(seq_len(m), sample(20:50, m, replace = TRUE))
    x1 <- stats::rnorm(length(hospital))
    eta <- stats::rnorm(m, -0.4, 0.6)[hospital] + 0.7 * x1
    data.frame(y = stats::rbinom(length(eta), 1, stats::plogis(eta)), hospital = hospital, x1 = x1,
               x2 = stats::rnorm(length(hospital)))
  }
}

for (family in c("linear_fe", "linear_re", "linear_cre", "logistic_re", "logistic_cre")) {
  local({
    name <- family
    test_that(paste("relabeling the providers in order changes only the labels:", name), {
      skip_on_cran()
      data <- metamorphic_data(name)
      reference <- metamorphic_results(metamorphic_fit(name, data))
      for (scheme in c("character", "factor", "numeric")) {
        relabeled <- metamorphic_fit(name, metamorphic_relabel(data, scheme))
        expect_identical(metamorphic_results(relabeled), reference, label = paste(name, scheme))
      }
    })
  })
}

test_that("shuffling the rows changes linear FE results only within the closed-form tier", {
  skip_on_cran()
  data <- metamorphic_data("linear_fe")
  shuffled <- withr::with_seed(9, data[sample(nrow(data)), ])
  reference <- metamorphic_results(metamorphic_fit("linear_fe", data))
  results <- metamorphic_results(metamorphic_fit("linear_fe", shuffled))
  for (name in names(reference)) {
    diffs <- reference_compare(results[[name]], reference[[name]], reference_tolerance("closed_form"))
    expect(is.null(diffs), sprintf("%s: %s", name, paste(diffs$path, diffs$detail, collapse = "; ")))
  }
})
