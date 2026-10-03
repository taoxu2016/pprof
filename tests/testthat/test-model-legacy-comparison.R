# Live comparison of fit_logistic_fe() with the reference's logis_fe() while both are in the
# package (Phase 3 plan, step 2): on seeded random data with numeric, character, and factor
# provider IDs and shuffled rows, the new fit must reproduce the old one bitwise, apart from
# the AUC, which may differ in the last bit (D-40).
#
# Temporary: remove at the switch to the compatibility wrappers, when logis_fe() becomes one.
local_strict_mode()

legacy_model_data <- function(seed, id_type) {
  inputs <- engine_random_inputs(seed)
  provider <- rep(seq_along(inputs$sizes), inputs$sizes)
  labels <- sprintf("%s%02d", c("a", "B", "c", "D")[(seq_along(inputs$sizes) %% 4) + 1], rev(seq_along(inputs$sizes)))
  ids <- switch(id_type, numeric = provider * 10, character = labels[provider], factor = factor(labels[provider]))
  covariates <- inputs$design
  colnames(covariates) <- paste0("x", seq_len(ncol(covariates)))
  data <- data.frame(Y = inputs$response, ProvID = ids, covariates)
  rows <- withr::with_seed(seed, sample(nrow(data)))
  data[rows, ]
}

test_that("fit_logistic_fe() reproduces logis_fe() bitwise", {
  for (seed in 20261002 + 1:6) {
    for (id_type in c("numeric", "character", "factor")) {
      data <- legacy_model_data(seed, id_type)
      covariates <- setdiff(names(data), c("Y", "ProvID"))
      for (method in c("SerBIN", "BAN")) {
        label <- sprintf("seed %d, %s IDs, %s", seed, id_type, method)
        reference <- function(data) {
          tryCatch(logis_fe(data = data, Y.char = "Y", Z.char = covariates, ProvID.char = "ProvID", method = method,
                            message = FALSE), error = function(e) e)
        }
        old <- reference(data)
        # With factor IDs the reference fails whenever screening excludes a provider (D-41);
        # the same labels as strings give the fit it would have returned.
        if (id_type == "factor" && inherits(old, "error")) {
          old <- reference(transform(data, ProvID = as.character(ProvID)))
        }
        new <- tryCatch(suppressWarnings(fit_logistic_fe(stats::reformulate(covariates, "Y"), data, "ProvID",
                                                         method = tolower(method))),
                        error = function(e) e)
        if (inherits(old, "error")) {
          expect_true(inherits(new, "error"), label = paste(label, "fails like the reference"))
          next
        }
        expect_identical(new$coefficients, stats::setNames(as.numeric(old$coefficient$beta), covariates), label = label)
        expect_identical(new$provider_effects, stats::setNames(as.numeric(old$coefficient$gamma),
                                                               rownames(old$coefficient$gamma)), label = label)
        expect_identical(unname(new$vcov), unname(old$variance$beta), label = label)
        expect_identical(unname(new$provider_effect_variance), as.numeric(old$variance$gamma), label = label)
        expect_identical(c(new$loglik, new$aic, new$bic), c(old$Loglkd, old$AIC, old$BIC), label = label)
        expect_equal(new$auc, old$AUC, tolerance = 1e-15, label = label)
        expect_identical(new$linear_predictor, as.numeric(old$linear_pred), label = label)
        expect_identical(logistic_fe_probabilities(new), as.numeric(old$fitted), label = label)
      }
    }
  }
})
