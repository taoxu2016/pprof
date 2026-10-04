# Metamorphic tests (brief §6 F, ARCHITECTURE §G.6) of the Phase 4 fits: row order, provider
# relabeling, and the input formats of the wrappers.
#
# Every fit sorts the rows by provider and keeps their order within a provider, so the order
# of the providers' blocks in the data and labels that keep the providers' order change
# nothing. Any other row order or relabeling changes the order of summation: the Firth and
# linear FE estimates then move at the level of rounding, while lme4's estimates move at its
# optimizer's precision (measured: 4e-9 relative for linear and up to 4e-4 for logistic
# models), so for the random-effect fits only the exact relations are tested (DEC-043).
local_strict_mode()

metamorphic_linear <- function() {
  data(ExampleDataLinear, package = "pprof", envir = environment())
  data.frame(y = ExampleDataLinear$Y, hospital = ExampleDataLinear$ProvID, ExampleDataLinear$Z)
}

metamorphic_binary <- function() {
  data(ExampleDataBinary, package = "pprof", envir = environment())
  data <- data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID, ExampleDataBinary$Z)
  data[data$hospital <= 20, ]
}

metamorphic_fits <- list(
  logistic_firth = function(data) fit_logistic_firth(y ~ z1 + z2 + z3 + z4 + z5, data, "hospital"),
  linear_fe = function(data) fit_linear_fe(y ~ z1 + z2 + z3 + z4 + z5, data, "hospital", provider_variance = "full"),
  linear_re = function(data) fit_linear_re(y ~ z1 + z2 + z3 + z4 + z5, data, "hospital"),
  logistic_re = function(data) fit_logistic_re(y ~ z1 + z2 + z3 + z4 + z5, data, "hospital"),
  linear_cre = function(data) fit_linear_cre(y ~ z1 + z2 + z3, data, "hospital", within_between = "z1"),
  logistic_cre = function(data) fit_logistic_cre(y ~ z1 + z2 + z3, data, "hospital", within_between = "z1")
)

metamorphic_data <- function(family) {
  if (startsWith(family, "logistic")) metamorphic_binary() else metamorphic_linear()
}

# The estimates of a fit, with the provider-level values in provider order and unnamed.
metamorphic_estimates <- function(fit) {
  values <- list(coefficients = fit$coefficients, vcov = fit$vcov, loglik = fit$loglik,
                 provider_effects = unname(fit$provider_effects),
                 provider_effect_sd = unname(fit$provider_effect_sd),
                 provider_effect_variance = unname(fit$provider_effect_variance),
                 iterations = fit$convergence$iterations)
  values[!vapply(values, is.null, logical(1))]
}

# Rows grouped by provider, the providers' blocks in a random order, and the rows of each
# block in their original order.
metamorphic_shuffle_blocks <- function(data, seed) {
  order <- withr::with_seed(seed, sample(unique(data$hospital)))
  data[order(match(data$hospital, order), seq_len(nrow(data))), ]
}

test_that("the order of the providers' blocks and labels that keep the providers' order change nothing", {
  for (family in names(metamorphic_fits)) {
    fit <- metamorphic_fits[[family]]
    data <- metamorphic_data(family)
    base <- fit(data)
    expected <- metamorphic_estimates(base)
    expect_identical(metamorphic_estimates(fit(metamorphic_shuffle_blocks(data, 1))), expected,
                     label = paste(family, "with the providers' blocks reordered"))
    text <- data
    text$hospital <- sprintf("H%03d", data$hospital)
    text_fit <- fit(text)
    expect_identical(metamorphic_estimates(text_fit), expected, label = paste(family, "with text IDs"))
    expect_identical(names(text_fit$provider_effects), sprintf("H%03d", as.numeric(names(base$provider_effects))),
                     label = paste(family, "provider IDs"))
    text$hospital <- factor(text$hospital)
    expect_identical(metamorphic_estimates(fit(text)), expected, label = paste(family, "with factor IDs"))
  }
})

test_that("the Firth and linear FE estimates do not depend on the row order or the providers' labels", {
  for (family in c("logistic_firth", "linear_fe")) {
    fit <- metamorphic_fits[[family]]
    data <- metamorphic_data(family)
    tier <- if (identical(family, "logistic_firth")) "iterative" else "closed_form"
    expected <- metamorphic_estimates(fit(data))
    for (seed in 1:3) {
      shuffled <- metamorphic_estimates(fit(data[withr::with_seed(seed, sample(nrow(data))), ]))
      expect_reference_value(shuffled, expected, tier, sprintf("%s with rows shuffled (seed %d)", family, seed))
    }
    # Labels in the reverse order: the providers' blocks are summed in the reverse order.
    reversed <- data
    reversed$hospital <- sprintf("R%03d", 1000 - data$hospital)
    relabeled <- fit(reversed)
    back <- order(1000 - as.numeric(substring(names(relabeled$provider_effects), 2)))
    estimates <- metamorphic_estimates(relabeled)
    provider_fields <- c("provider_effects", "provider_effect_sd", "provider_effect_variance")
    for (field in intersect(provider_fields, names(estimates))) {
      estimates[[field]] <- estimates[[field]][back]
    }
    expect_reference_value(estimates, expected, tier, paste(family, "with labels in the reverse order"))
  }
})

test_that("the input formats of the wrappers give the same fit", {
  binary <- metamorphic_binary()
  names(binary)[1:2] <- c("Y", "ProvID")
  z <- paste0("z", 1:5)
  columns <- logis_firth(data = binary, Y.char = "Y", Z.char = z, ProvID.char = "ProvID", message = FALSE)
  vectors <- logis_firth(Y = binary$Y, Z = as.matrix(binary[z]), ProvID = binary$ProvID, message = FALSE)
  formula <- logis_firth(Y ~ z1 + z2 + z3 + z4 + z5 + id(ProvID), binary, message = FALSE)
  for (other in list(vectors, formula)) {
    expect_identical(other$coefficient, columns$coefficient)
    expect_identical(other$variance, columns$variance)
  }

  linear <- metamorphic_linear()
  names(linear)[1:2] <- c("Y", "ProvID")
  wrappers <- list(linear_fe = linear_fe, linear_re = linear_re)
  for (name in names(wrappers)) {
    wrapper <- wrappers[[name]]
    columns <- suppressMessages(wrapper(data = linear, Y.char = "Y", Z.char = z, ProvID.char = "ProvID"))
    vectors <- suppressMessages(wrapper(Y = linear$Y, Z = as.matrix(linear[z]), ProvID = linear$ProvID))
    # The RE wrappers pass the user's formula to lme4, with the random term where the user puts it (DEC-042).
    formula <- if (identical(name, "linear_fe")) {
      Y ~ z1 + z2 + z3 + z4 + z5 + id(ProvID)
    } else {
      Y ~ z1 + z2 + z3 + z4 + z5 + (1 | ProvID)
    }
    formula <- suppressMessages(wrapper(formula, linear))
    for (other in list(vectors, formula)) {
      for (field in c("coefficient", "variance", "fitted", "residuals", "Loglkd")) {
        expect_identical(other[[field]], columns[[field]], label = paste(name, field))
      }
    }
  }
})
