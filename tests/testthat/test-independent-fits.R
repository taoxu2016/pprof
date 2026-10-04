# Independent references (brief §6 E, ARCHITECTURE §G.5): the Phase 4 fits against other
# implementations of the same models, which agreement with pprof 1.0.3 alone cannot replace.
# Each test skips when its package is absent.
local_strict_mode()

independent_expect <- function(actual, expected, tolerance, label) {
  diffs <- reference_compare(actual, expected, tolerance)
  expect(is.null(diffs), sprintf("%s differs from the independent reference: %s", label,
                                 paste(sprintf("%s [%s] %s", diffs$path, diffs$kind, diffs$detail), collapse = "; ")))
}

# The coefficients of the provider indicators `factor(<provider>)<id>` of an lm() or logistf
# fit, named by provider ID.
independent_indicators <- function(values, provider) {
  prefix <- sprintf("factor(%s)", provider)
  kept <- values[startsWith(names(values), prefix)]
  stats::setNames(unname(kept), substring(names(kept), nchar(prefix) + 1L))
}

independent_linear_example <- function() {
  data(ExampleDataLinear, package = "pprof", envir = environment())
  data.frame(y = ExampleDataLinear$Y, hospital = ExampleDataLinear$ProvID, ExampleDataLinear$Z)
}

# Providers of 2 to 60 observations, a covariate that varies between providers, and rows in
# random order.
independent_linear_unbalanced <- function() {
  withr::local_seed(11)
  m <- 40
  sizes <- sample(2:60, m, replace = TRUE)
  index <- rep(seq_len(m), sizes)
  z <- matrix(stats::rnorm(sum(sizes) * 5), ncol = 5, dimnames = list(NULL, paste0("z", 1:5)))
  z[, 2] <- z[, 2] + stats::rnorm(m, 0, 2)[index]
  y <- stats::rnorm(m)[index] + drop(z %*% c(1, -0.5, 0.25, 0, 2)) + stats::rnorm(sum(sizes))
  data <- data.frame(y = y, hospital = sprintf("H%02d", index), z)
  data[sample(nrow(data)), ]
}

test_that("fit_linear_fe() agrees with lm() with provider indicators (V14.1)", {
  for (case in c("example", "unbalanced")) {
    data <- if (identical(case, "example")) independent_linear_example() else independent_linear_unbalanced()
    covariates <- paste0("z", 1:5)
    full <- fit_linear_fe(y ~ z1 + z2 + z3 + z4 + z5, data, "hospital", provider_variance = "full")
    simplified <- fit_linear_fe(y ~ z1 + z2 + z3 + z4 + z5, data, "hospital")
    reference <- stats::lm(y ~ 0 + factor(hospital) + z1 + z2 + z3 + z4 + z5, data)
    ids <- names(full$provider_effects)
    tolerance <- reference_tolerance("closed_form")
    independent_expect(full$coefficients, stats::coef(reference)[covariates], tolerance, paste(case, "coefficients"))
    independent_expect(full$provider_effects, independent_indicators(stats::coef(reference), "hospital")[ids],
                       tolerance, paste(case, "provider effects"))
    independent_expect(full$vcov, stats::vcov(reference)[covariates, covariates], tolerance, paste(case, "vcov"))
    # The full variance of a provider effect is that of its indicator's coefficient.
    independent_expect(full$provider_effect_variance,
                       independent_indicators(diag(stats::vcov(reference)), "hospital")[ids], tolerance,
                       paste(case, "full provider-effect variance"))
    sigma <- summary(reference)$sigma
    independent_expect(full$sigma, sigma, tolerance, paste(case, "sigma"))
    sizes <- table(data$hospital)[ids]
    independent_expect(simplified$provider_effect_variance, stats::setNames(sigma^2 / as.numeric(sizes), ids),
                       tolerance, paste(case, "simplified provider-effect variance"))
    loglik <- stats::logLik(full)
    independent_expect(as.numeric(loglik), as.numeric(stats::logLik(reference)), tolerance, paste(case, "loglik"))
    expect_identical(as.numeric(attr(loglik, "df")), as.numeric(attr(stats::logLik(reference), "df")))
    independent_expect(c(stats::AIC(full), stats::BIC(full)), c(stats::AIC(reference), stats::BIC(reference)),
                       tolerance, paste(case, "AIC and BIC"))
  }
})

# The fit's provider effects, their SDs, and the provider variance against lme4's own.
independent_expect_lme4 <- function(fit, direct, provider, label) {
  random <- lme4::ranef(direct, condVar = TRUE)[[provider]]
  expect_identical(fit$coefficients, lme4::fixef(direct), label = paste(label, "coefficients"))
  expect_identical(unname(fit$provider_effects), random[, 1], label = paste(label, "provider effects"))
  expect_identical(names(fit$provider_effects), rownames(random), label = paste(label, "provider IDs"))
  expect_identical(fit$vcov, as.matrix(stats::vcov(direct)), label = paste(label, "vcov"))
  expect_identical(fit$variance_components$provider, as.numeric(lme4::VarCorr(direct)[[provider]]),
                   label = paste(label, "provider variance"))
  expect_identical(fit$loglik, as.numeric(stats::logLik(direct)), label = paste(label, "loglik"))
  expect_identical(unname(fit$fitted), unname(stats::fitted(direct)), label = paste(label, "fitted values"))
  # The linear RE SD is K-69's closed form, the others lme4's conditional SD (K-70).
  independent_expect(unname(fit$provider_effect_sd), sqrt(attr(random, "postVar")[1, 1, ]),
                     reference_tolerance("closed_form"), paste(label, "provider-effect SD"))
}

independent_binary <- function() {
  withr::local_seed(4)
  n <- 900
  hospital <- rep(sprintf("P%02d", 1:30), each = 30)
  x1 <- stats::rnorm(n)
  y <- stats::rbinom(n, 1, stats::plogis(-0.5 + stats::rnorm(30, 0, 0.7)[match(hospital, unique(hospital))] +
                                           0.8 * x1))
  data.frame(y = y, hospital = hospital, x1 = x1, x2 = stats::rnorm(n))
}

test_that("the random-effect fits are the fits of direct lme4 calls (V15.1)", {
  linear <- independent_linear_example()
  fit <- fit_linear_re(y ~ z1 + z2 + z3 + z4 + z5, linear, "hospital")
  direct <- lme4::lmer(y ~ z1 + z2 + z3 + z4 + z5 + (1 | hospital), linear)
  independent_expect_lme4(fit, direct, "hospital", "linear RE")
  expect_identical(fit$sigma, stats::sigma(direct))

  # The within-between decomposition by hand: provider means of every row, and deviations.
  decomposed <- transform(linear, z1_bar = stats::ave(z1, hospital))
  decomposed$z1_within <- decomposed$z1 - decomposed$z1_bar
  fit <- fit_linear_cre(y ~ z1 + z2 + z3, linear, "hospital", within_between = "z1")
  direct <- lme4::lmer(y ~ z1_within + z1_bar + z2 + z3 + (1 | hospital), decomposed)
  independent_expect_lme4(fit, direct, "hospital", "linear CRE")

  binary <- independent_binary()
  fit <- fit_logistic_re(y ~ x1 + x2, binary, "hospital")
  direct <- lme4::glmer(y ~ x1 + x2 + (1 | hospital), binary, family = stats::binomial(link = "logit"))
  independent_expect_lme4(fit, direct, "hospital", "logistic RE")

  decomposed <- transform(binary, x1_bar = stats::ave(x1, hospital))
  decomposed$x1_within <- decomposed$x1 - decomposed$x1_bar
  fit <- fit_logistic_cre(y ~ x1 + x2, binary, "hospital", within_between = "x1")
  direct <- lme4::glmer(y ~ x1_within + x1_bar + x2 + (1 | hospital), decomposed,
                        family = stats::binomial(link = "logit"))
  independent_expect_lme4(fit, direct, "hospital", "logistic CRE")
})

# logistf and fit_logistic_firth() reach the same penalized maximum by different iterations
# that stop on different step sizes (1e-12 and 1e-10 here); on these two datasets they agreed
# to 2.2e-11 absolute and 1.6e-11 relative (V12.5; Phase 4 step 4). 1e-9 leaves a 45-fold margin
# (DEC-043).
independent_firth_tolerance <- list(atol = 1e-9, rtol = 1e-9)

independent_firth_data <- function(seed, m, sizes, intercept, sd, beta) {
  withr::local_seed(seed)
  sizes <- sample(sizes, m, replace = TRUE)
  index <- rep(seq_len(m), sizes)
  x <- matrix(stats::rnorm(length(index) * 2), ncol = 2, dimnames = list(NULL, c("x1", "x2")))
  y <- stats::rbinom(length(index), 1, stats::plogis(stats::rnorm(m, intercept, sd)[index] + drop(x %*% beta)))
  data.frame(Y = y, ProvID = sprintf("P%02d", index), x)
}

test_that("fit_logistic_firth() agrees with logistf with provider indicators (V12.5)", {
  skip_if_not_installed("logistf")
  datasets <- list(v12_5 = independent_firth_data(5, 12, 12:30, -0.5, 0.8, c(0.7, -0.4)),
                   larger = independent_firth_data(6, 25, 15:60, -1, 0.6, c(0.5, 0.3)))
  for (name in names(datasets)) {
    data <- datasets[[name]]
    # Without providers with no events or only events, the clamp of K-15 never acts.
    rates <- tapply(data$Y, data$ProvID, mean)
    expect_true(all(rates > 0 & rates < 1), label = paste(name, "has no extreme providers"))
    fit <- fit_logistic_firth(Y ~ x1 + x2, data, "ProvID", tol = 1e-10)
    reference <- logistf::logistf(Y ~ 0 + factor(ProvID) + x1 + x2, data = data,
                                  control = logistf::logistf.control(maxit = 200, maxstep = 5, lconv = 1e-12,
                                                                     gconv = 1e-12, xconv = 1e-12))
    estimates <- stats::coef(reference)
    independent_expect(fit$coefficients, estimates[c("x1", "x2")], independent_firth_tolerance,
                       paste(name, "coefficients"))
    independent_expect(fit$provider_effects, independent_indicators(estimates, "ProvID")[names(fit$provider_effects)],
                       independent_firth_tolerance, paste(name, "provider effects"))
    # At the maximum the penalized log-likelihood is insensitive to the estimates' last digits.
    independent_expect(fit$penalized_loglik, unname(reference$loglik["full"]), reference_tolerance("closed_form"),
                       paste(name, "penalized log-likelihood"))
  }
})

# glm() with provider indicators fits the logistic FE model without its effect bound; on data
# without providers with no events or only events the bound never acts, and both reach the
# same maximum. glm() reports the covariance of the weights at the start of its last
# iteration, so the variances are compared with one more glm() iteration started at its
# estimates. Measured in the Phase 5 plan (F13): estimates within 3.2e-13 absolute and
# 1.3e-13 relative, variances within 2.7e-13 relative; atol and rtol 1e-10 leave a 300-fold
# margin for the estimates (DEC-050), and the variances and log-likelihood are compared at the
# closed-form tier.
independent_glm_tolerance <- list(atol = 1e-10, rtol = 1e-10)

independent_glm_data <- function() {
  data(ExampleDataBinary, package = "pprof", envir = environment())
  example <- data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID, ExampleDataBinary$Z)
  rates <- tapply(example$y, example$hospital, mean)
  keep <- as.numeric(names(rates)[rates > 0 & rates < 1])
  withr::local_seed(20261004)
  m <- 60
  hospital <- rep(seq_len(m), sample(20:120, m, replace = TRUE))
  z <- matrix(stats::rnorm(length(hospital) * 5), ncol = 5, dimnames = list(NULL, paste0("z", 1:5)))
  eta <- stats::rnorm(m, -0.5, 0.4)[hospital] + drop(z %*% c(0.3, -0.2, 0.1, 0.4, -0.3))
  simulated <- data.frame(y = stats::rbinom(length(eta), 1, stats::plogis(eta)), hospital = hospital, z)
  list(example = example[example$hospital %in% keep, ], simulated = simulated)
}

test_that("fit_logistic_fe() agrees with glm() with provider indicators (ARCHITECTURE G.5, DEC-050)", {
  skip_on_cran()
  covariates <- paste0("z", 1:5)
  formula <- y ~ 0 + factor(hospital) + z1 + z2 + z3 + z4 + z5
  datasets <- independent_glm_data()
  for (name in names(datasets)) {
    data <- datasets[[name]]
    rates <- tapply(data$y, data$hospital, mean)
    expect_true(all(rates > 0 & rates < 1), label = paste(name, "has no extreme providers"))
    fit <- fit_logistic_fe(y ~ z1 + z2 + z3 + z4 + z5, data, "hospital", tol = 1e-12, stop_rule = "all",
                           min_provider_size = 1)
    reference <- stats::glm(formula, stats::binomial(), data,
                            control = stats::glm.control(epsilon = 1e-14, maxit = 100))
    at_estimates <- suppressWarnings(stats::glm(formula, stats::binomial(), data, start = stats::coef(reference),
                                                control = stats::glm.control(epsilon = 1e-14, maxit = 1)))
    ids <- names(fit$provider_effects)
    independent_expect(fit$coefficients, stats::coef(reference)[covariates], independent_glm_tolerance,
                       paste(name, "coefficients"))
    independent_expect(fit$provider_effects, independent_indicators(stats::coef(reference), "hospital")[ids],
                       independent_glm_tolerance, paste(name, "provider effects"))
    variances <- stats::vcov(at_estimates)
    tolerance <- reference_tolerance("closed_form")
    independent_expect(fit$vcov, variances[covariates, covariates], tolerance, paste(name, "vcov"))
    independent_expect(fit$provider_effect_variance, independent_indicators(diag(variances), "hospital")[ids],
                       tolerance, paste(name, "provider-effect variances"))
    independent_expect(fit$loglik, as.numeric(stats::logLik(reference)), tolerance, paste(name, "log-likelihood"))
  }
})

# The standardized measures of each family by hand (ARCHITECTURE G.5, K-80 to K-84), from the
# data and, for random effects, from a direct lme4 fit; the sums are taken in another order,
# so the closed-form tier applies.
independent_provider_sums <- function(values, provider) as.vector(tapply(values, provider, sum))

test_that("linear FE measures are the differences of K-83, computed by hand", {
  data <- independent_linear_example()
  fit <- fit_linear_fe(y ~ z1 + z2 + z3 + z4 + z5, data, "hospital")
  measures <- standardize_providers(fit, c("indirect", "direct"), null = "mean")
  null <- measures$null_value
  linear_predictor <- drop(as.matrix(data[paste0("z", 1:5)]) %*% fit$coefficients)
  n_obs <- as.vector(table(data$hospital))
  indirect <- (independent_provider_sums(data$y, data$hospital) -
                 independent_provider_sums(null + linear_predictor, data$hospital)) / n_obs
  direct <- (vapply(fit$provider_effects, function(effect) sum(effect + linear_predictor), numeric(1)) -
               sum(null + linear_predictor)) / nrow(data)
  tolerance <- reference_tolerance("closed_form")
  table <- measures$table
  independent_expect(table$estimate[table$standardization == "indirect"], indirect, tolerance, "indirect difference")
  independent_expect(table$estimate[table$standardization == "direct"], unname(direct), tolerance, "direct difference")
})

test_that("RE measures put lme4's fitted values over the expected outcomes (K-82, K-84), by hand", {
  tolerance <- reference_tolerance("closed_form")
  linear <- independent_linear_example()
  direct_fit <- lme4::lmer(y ~ z1 + z2 + z3 + z4 + z5 + (1 | hospital), linear)
  fit <- fit_linear_re(y ~ z1 + z2 + z3 + z4 + z5, linear, "hospital")
  fixed <- drop(stats::model.matrix(direct_fit) %*% lme4::fixef(direct_fit))
  effects <- lme4::ranef(direct_fit)$hospital[, 1]
  n_obs <- as.vector(table(linear$hospital))
  table <- standardize_providers(fit, c("indirect", "direct"))$table
  indirect <- (independent_provider_sums(stats::fitted(direct_fit), linear$hospital) -
                 independent_provider_sums(fixed, linear$hospital)) / n_obs
  direct <- (vapply(effects, function(effect) sum(effect + fixed), numeric(1)) - sum(linear$y)) / nrow(linear)
  independent_expect(table$estimate[table$standardization == "indirect"], indirect, tolerance, "linear RE indirect")
  independent_expect(table$estimate[table$standardization == "direct"], direct, tolerance, "linear RE direct")

  binary <- independent_binary()
  direct_fit <- lme4::glmer(y ~ x1 + x2 + (1 | hospital), binary, family = stats::binomial(link = "logit"))
  fit <- fit_logistic_re(y ~ x1 + x2, binary, "hospital")
  fixed <- drop(stats::model.matrix(direct_fit) %*% lme4::fixef(direct_fit))
  effects <- lme4::ranef(direct_fit)$hospital[, 1]
  table <- standardize_providers(fit, c("indirect", "direct"))$table
  rows <- function(standardization, measure) table$standardization == standardization & table$measure == measure
  indirect <- independent_provider_sums(stats::fitted(direct_fit), binary$hospital) /
    independent_provider_sums(stats::plogis(fixed), binary$hospital)
  direct <- vapply(effects, function(effect) sum(stats::plogis(effect + fixed)), numeric(1)) / sum(binary$y)
  rate <- 100 * sum(binary$y) / nrow(binary)
  independent_expect(table$estimate[rows("indirect", "ratio")], indirect, tolerance, "logistic RE indirect ratio")
  independent_expect(table$estimate[rows("direct", "ratio")], direct, tolerance, "logistic RE direct ratio")
  independent_expect(table$estimate[rows("indirect", "rate")], pmin(pmax(indirect * rate, 0), 100), tolerance,
                     "logistic RE indirect rate")
})
