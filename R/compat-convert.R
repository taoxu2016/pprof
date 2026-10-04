# Conversion between the objects of pprof 1.0.3 and the new API (ARCHITECTURE §I.2,
# DEC-032): the old fit functions' three input formats, the old fit object built from a new
# model, and a new model rebuilt from an old fit object for the old methods.

# The inputs of a fixed-effect fit in the reference's three formats (BEHAVIOR_SPECS §1),
# checked as the reference checks them and translated to fit_logistic_fe()'s formula, data,
# and provider. `response_name` and `provider_name` are the names the reference gives these
# columns in its `data_include`: data.frame(Y, ProvID, Z) names them after its variables, so
# after the column for the formula format and "Y" and "ProvID" otherwise.
compat_fe_inputs <- function(formula, data, Y.char, Z.char, ProvID.char, Y, Z, ProvID) { # nolint: object_name_linter.
  if (!is.null(formula) && !is.null(data)) {
    terms <- stats::terms(formula)
    response <- as.character(attr(terms, "variables"))[2]
    labels <- attr(terms, "term.labels")
    is_provider <- vapply(labels, function(label) {
      term <- str2lang(label)
      is.call(term) && identical(term[[1]], as.name("id")) && length(term) == 2L
    }, logical(1))
    provider <- vapply(labels[is_provider], function(label) deparse(str2lang(label)[[2]]), character(1))
    covariates <- labels[!is_provider]
    # The reference requires every term to be a column of the data, which rejects
    # transformed terms and interactions (D-18); the response and the provider must be.
    if (length(provider) != 1L || !all(c(response, provider) %in% colnames(data)) || length(covariates) == 0L) {
      abort_invalid_input("Formula contains variables not in the data or is incorrectly structured.", arg = "formula")
    }
    return(list(format = "formula and data", data = data, response = response, provider = unname(provider),
                covariates = covariates, response_name = response, provider_name = unname(provider)))
  }
  if (!is.null(data) && !is.null(Y.char) && !is.null(Z.char) && !is.null(ProvID.char)) {
    if (!all(c(Y.char, Z.char, ProvID.char) %in% colnames(data))) {
      abort_invalid_input("Some of the specified columns are not in the data!", arg = "data")
    }
    return(list(format = "data, Y.char, Z.char, and ProvID.char", data = data, response = Y.char,
                provider = ProvID.char, covariates = Z.char, response_name = "Y", provider_name = ProvID.char))
  }
  if (!is.null(Y) && !is.null(Z) && !is.null(ProvID)) {
    if (length(Y) != length(ProvID) || length(ProvID) != NROW(Z)) {
      abort_invalid_input("Dimensions of the input data do not match!!", arg = "Y")
    }
    data <- data.frame(Y, ProvID, Z)
    return(list(format = "Y, Z, and ProvID", data = data, response = "Y", provider = "ProvID",
                covariates = colnames(Z), response_name = "Y", provider_name = "ProvID"))
  }
  abort_invalid_input(paste(
    "Insufficient or incompatible arguments provided. Please provide either (1) formula and data,",
    "(2) data, Y.char, Z.char, and ProvID.char, or (3) Y, Z, and ProvID."
  ), arg = "data")
}

# The reference's `data_include` from a logistic model fit with keep_data = TRUE: the rows of
# compat_fe_data_frame() and the screening indicators.
compat_data_include <- function(model, inputs) {
  prepared <- model$data
  out <- compat_fe_data_frame(model, inputs)
  out$included <- 1
  out$no.events <- as.numeric(prepared$providers$no_events[prepared$provider_index])
  out$all.events <- as.numeric(prepared$providers$all_events[prepared$provider_index])
  out
}

# The data frame data.frame(Y, ProvID, Z) of the reference's fixed-effect fits, from a model
# fit with keep_data = TRUE: the included rows in provider order, with names passed through
# make.names() and the input's row names in their stored type. linear_fe() returns it as
# its `data_include`.
compat_fe_data_frame <- function(model, inputs) {
  prepared <- model$data
  # data.frame() takes only the columns of the design, not its `assign` and `contrasts`
  # attributes; removing them first would copy the design, which the model still holds.
  design <- prepared$design
  ids <- prepared$providers$provider_value[prepared$provider_index]
  out <- data.frame(prepared$response, ids, design)
  names(out) <- make.names(c(inputs$response_name, inputs$provider_name, colnames(design)), unique = TRUE)
  attr(out, "row.names") <- attr(inputs$data, "row.names")[prepared$row_index]
  out
}

# The reference's logis_fe object (BEHAVIOR_SPECS §2, §16) from a fit_logistic_fe() model
# fit with keep_data = TRUE.
compat_logis_fe_object <- function(model, inputs) {
  data_include <- compat_data_include(model, inputs)
  covariates <- names(model$coefficients)
  providers <- names(model$provider_effects)
  n <- length(model$response)
  linear_predictor <- matrix(model$linear_predictor, ncol = 1L, dimnames = list(seq_len(n), "Linear Predictor"))
  fitted <- matrix(logistic_fe_probabilities(model), ncol = 1L, dimnames = list(seq_len(n), "Predicted Probability"))
  variance_beta <- model$vcov
  dimnames(variance_beta) <- list(covariates, covariates)
  structure(
    list(
      coefficient = list(beta = matrix(unname(model$coefficients), ncol = 1L, dimnames = list(covariates, "beta")),
                         gamma = matrix(unname(model$provider_effects), ncol = 1L,
                                        dimnames = list(providers, "gamma"))),
      variance = list(beta = variance_beta,
                      gamma = matrix(unname(model$provider_effect_variance), ncol = 1L,
                                     dimnames = list(providers, "Variance.Gamma"))),
      fitted = fitted,
      observation = model$data$response,
      linear_pred = linear_predictor,
      Loglkd = model$loglik,
      AIC = model$aic,
      BIC = model$bic,
      AUC = model$auc,
      char_list = list(Y.char = names(data_include)[1], ProvID.char = names(data_include)[2], Z.char = covariates),
      data_include = data_include
    ),
    class = "logis_fe"
  )
}

# The reference's linear_fe object (BEHAVIOR_SPECS §4, §16) from a fit_linear_fe() model fit
# with keep_data = TRUE, with the reference's shapes (R/linear_fe.R:149-243): the observation
# as as.matrix() of the response column of `data_include`, and the variance type as the
# "description" attribute of the provider variances, which the old methods read (D-16).
compat_linear_fe_object <- function(model, inputs) {
  data_include <- compat_fe_data_frame(model, inputs)
  covariates <- names(model$coefficients)
  providers <- names(model$provider_effects)
  rows <- seq_along(model$response)
  fitted <- linear_fe_fitted(model)
  variance_beta <- model$vcov
  dimnames(variance_beta) <- list(covariates, covariates)
  variance_gamma <- matrix(unname(model$provider_effect_variance), ncol = 1L,
                           dimnames = list(providers, "Variance.Gamma"))
  attr(variance_gamma, "description") <- model$spec$provider_variance
  result <- structure(
    list(
      coefficient = list(beta = matrix(unname(model$coefficients), ncol = 1L, dimnames = list(covariates, "beta")),
                         gamma = matrix(unname(model$provider_effects), ncol = 1L,
                                        dimnames = list(providers, "gamma"))),
      variance = list(beta = variance_beta, gamma = variance_gamma),
      sigma = model$sigma,
      fitted = matrix(fitted, ncol = 1L, dimnames = list(rows, "Prediction")),
      observation = as.matrix(data_include[, 1L, drop = FALSE]),
      residuals = matrix(as.numeric(model$response) - fitted, ncol = 1L, dimnames = list(rows, "Residuals")),
      linear_pred = matrix(model$linear_predictor, ncol = 1L, dimnames = list(rows, "Linear Predictor")),
      Loglkd = model$loglik,
      AIC = model$aic,
      BIC = model$bic
    ),
    class = "linear_fe"
  )
  result$data_include <- data_include
  result$char_list <- list(Y.char = names(data_include)[1], ProvID.char = names(data_include)[2], Z.char = covariates)
  result
}

# A pprof_logistic_fe model rebuilt from an old logis_fe object, from logis_fe(),
# logis_firth(), or pprof 1.0.3 (DEC-032): the estimates, variances, fit statistics, and
# linear predictor are the object's own, and the data (kept in the model) are its
# `data_include`, in the provider order of its estimates.
compat_model_from_logis_fe <- function(fit) {
  chars <- fit$char_list
  data <- fit$data_include
  covariates <- chars$Z.char
  gamma <- fit$coefficient$gamma
  ids <- data[[chars$ProvID.char]]
  provider_order <- rownames(gamma)
  # match(as.character(ids), provider_order) through the distinct IDs, which converts only
  # m IDs to strings rather than n.
  keys <- unique(ids)
  codes <- match(as.character(keys), provider_order)[match(ids, keys)]
  if (anyNA(codes) || is.unsorted(codes) || any(tabulate(codes, nbins = length(provider_order)) == 0L)) {
    abort_invalid_input("The fit's `data_include` does not match its provider effects.", arg = "fit")
  }
  prepared <- compat_data_from_include(data[[chars$Y.char]], data[2L + seq_along(covariates)], covariates, ids,
                                       provider_order, codes)
  estimates <- list(
    gamma = as.numeric(gamma), beta = as.numeric(fit$coefficient$beta),
    variances = list(beta = unname(fit$variance$beta), gamma = as.numeric(fit$variance$gamma)),
    linear_predictor = as.numeric(fit$linear_pred), loglik = fit$Loglkd, aic = fit$AIC, bic = fit$BIC, auc = fit$AUC,
    convergence = list(iterations = NA_integer_, converged = NA, criterion = NA_real_, stop_rule = NA_character_,
                       tol = NA_real_, max_iter = NA_real_)
  )
  spec <- list(family = "logistic_fe", method = NA_character_, keep_data = TRUE)
  new_pprof_logistic_fe(prepared, estimates, spec, keep_data = TRUE)
}

# The `pprof_data` of an old object's `data_include`, built directly rather than through
# data_prepare(), whose model frame and sorting cost most of the old methods' run time
# (Phase 3 gate). The rows are complete, sorted by provider, and all included, so the object
# is the one data_prepare() returns for data.frame(response, provider, covariate_1, ...) with
# min_provider_size = 1 and event counts: the same response, design (with `assign`),
# provider table, and indices. `codes` give each row's provider in `provider_order`.
compat_data_from_include <- function(response, columns, covariates, ids, provider_order, codes) {
  design <- matrix(as.double(unlist(columns, use.names = FALSE)), ncol = length(covariates),
                   dimnames = list(NULL, covariates))
  if (anyNA(response) || anyNA(design)) abort_invalid_input("The fit's `data_include` has missing values.", arg = "fit")
  attr(design, "assign") <- seq_along(covariates)
  internal <- sprintf("covariate_%d", seq_along(covariates))
  formula <- stats::reformulate(internal, response = "response")
  terms <- stats::terms(formula)
  providers <- data_provider_table(provider_order, codes, ids)
  providers <- data_screen_providers(providers, 1)
  providers <- data_event_indicators(providers, response, codes)
  n <- length(response)
  new_pprof_data(
    formula = formula, terms = terms, xlevels = stats::.getXlevels(terms, stats::setNames(columns, internal)),
    response_name = "response", provider_name = "provider", within_between = NULL, response = response,
    design = design, providers = providers, provider_index = codes, row_index = seq_len(n),
    settings = list(min_provider_size = 1, intercept = FALSE, event_counts = TRUE),
    n_input = n, n_incomplete = 0L, n_excluded_obs = 0L
  )
}

# The rows of an old object's providers selected by `parm`, as the reference's methods
# select them: numeric values compared with numeric IDs (integer IDs included, which the
# reference rejects, D-27), other values with IDs of the same class; IDs the fit does not
# have are dropped. NULL selects every provider.
compat_parm_providers <- function(fit, parm, message = "Argument 'parm' includes invalid elements!") {
  if (is.null(parm)) return(NULL)
  ids <- fit$data_include[[fit$char_list$ProvID.char]]
  if (is.numeric(parm)) parm <- as.numeric(parm)
  same_class <- (is.numeric(parm) && is.numeric(ids)) || identical(class(parm), class(ids))
  if (!same_class) abort_invalid_input(message, arg = "parm")
  intersect(as.character(parm), rownames(fit$coefficient$gamma))
}

# The numeric null of the old methods: "median" or a number, of which the first element
# is used; an integer is accepted everywhere (D-14).
compat_null <- function(null) {
  if (identical(null, "median")) return("median")
  if (is.numeric(null) && length(null) >= 1L) return(as.double(null[1]))
  abort_invalid_input("Argument 'null' NOT as required!", arg = "null")
}

# --- Random-effect and correlated random-effect fits (Phase 4) ----------------------------
#
# The wrappers of linear_re(), logis_re(), linear_cre(), and logis_cre() prepare their data
# and lme4 formula exactly as the reference does, fit through the lme4 adapter (lme4_fit()),
# and build the reference's object from the lme4 fit as the reference does, so that every
# shape, including the coercions of cbind() (D-11) and the tibbles of the CRE fits, is the
# reference's (BEHAVIOR_SPECS §5, §6, §16). The lme4 calls are the reference's (DEC-042).

# The inputs of a random-effect fit in the reference's three formats (R/linear_re.R:91-152):
# the data (the used columns, the complete rows, sorted by provider) and the formula for
# lme4: the user's formula unchanged, or the formula the reference builds. Where the
# reference fails with "object 'fit_re' not found" (no format matches) or later in lme4 (a
# character ProvID with a matrix Z, which cbind() turns into text), the wrapper raises a
# classed error (D-11).
compat_re_inputs <- function(formula, data, Y.char, Z.char, ProvID.char, Y, Z, ProvID) { # nolint: object_name_linter.
  if (!is.null(formula) && !is.null(data)) {
    terms <- stats::terms(formula)
    response <- as.character(attr(terms, "variables"))[2]
    labels <- attr(terms, "term.labels")
    is_random <- vapply(labels, function(label) {
      term <- str2lang(label)
      is.call(term) && (identical(term[[1]], as.name("|")) || identical(term[[1]], as.name("||")))
    }, logical(1))
    provider <- vapply(labels[is_random], function(label) deparse(str2lang(label)[[3]]), character(1))
    covariates <- labels[!is_random]
    if (length(provider) != 1L || !all(c(response, covariates, provider) %in% colnames(data))) {
      abort_invalid_input("Formula contains variables not in the data or is incorrectly structured.", arg = "formula")
    }
    data <- data[, c(response, provider, covariates)]
    data <- data[stats::complete.cases(data), ]
    data <- data[order(factor(data[[provider]])), ]
    return(list(format = "formula and data", data = data, formula = formula, response = unname(response),
                provider = unname(provider)))
  }
  if (!is.null(data) && !is.null(Y.char) && !is.null(Z.char) && !is.null(ProvID.char)) {
    if (!all(c(Y.char, Z.char, ProvID.char) %in% colnames(data))) {
      abort_invalid_input("Some of the specified columns are not in the data!", arg = "data")
    }
    data <- data[, c(Y.char, ProvID.char, Z.char)]
    data <- data[stats::complete.cases(data), ]
    data <- data[order(factor(data[, ProvID.char])), ]
    formula <- stats::as.formula(paste(Y.char, "~ (1|", ProvID.char, ") +", paste(Z.char, collapse = " + ")))
    return(list(format = "data, Y.char, Z.char, and ProvID.char", data = data, formula = formula, response = Y.char,
                provider = ProvID.char))
  }
  if (!is.null(Y) && !is.null(Z) && !is.null(ProvID)) {
    if (length(Y) != length(ProvID) || length(ProvID) != NROW(Z)) {
      abort_invalid_input("Dimensions of the input data do not match!!", arg = "Y")
    }
    combined <- cbind(Y, ProvID, Z)
    if (is.character(combined)) {
      abort_invalid_input(paste(
        "cbind(Y, ProvID, Z) would turn every column into text, because the provider IDs are text and Z is a",
        "matrix; pass Z as a data frame, or use numeric provider IDs (D-11)."
      ), arg = "ProvID")
    }
    data <- as.data.frame(combined)
    data <- data[stats::complete.cases(data), ]
    response <- colnames(data)[1]
    provider <- colnames(data)[2]
    data <- data[order(factor(data[, provider])), ]
    formula <- stats::as.formula(paste(response, "~ (1|", provider, ")+", paste0(colnames(Z), collapse = "+")))
    return(list(format = "Y, Z, and ProvID", data = data, formula = formula, response = response, provider = provider))
  }
  abort_invalid_input(paste(
    "Insufficient or incompatible arguments provided. Please provide either (1) formula and data,",
    "(2) data, Y.char, Z.char, and ProvID.char, or (3) Y, Z, and ProvID."
  ), arg = "data")
}

# The inputs of a correlated random-effect fit (R/linear_cre.R:93-118, R/logis_cre.R:89-114):
# the within-between decomposition over every row of `data` (K-54, D-13), from the data layer,
# which computes the reference's dplyr means bitwise, as a tibble as dplyr returns it; then
# the used columns, the complete rows, sorted by provider; and the reference's formula. As
# dplyr's mutate() does, the decomposition replaces columns of `data` that have its names.
compat_cre_inputs <- function(data, Y.char, wb.char, other.char, ProvID.char) { # nolint: object_name_linter.
  needed <- c(Y.char, ProvID.char, wb.char, if (!is.null(other.char)) other.char)
  if (!all(needed %in% colnames(data))) {
    abort_invalid_input("Some specified columns are not in `data`.", arg = "data")
  }
  within_terms <- paste0(wb.char, "_within")
  between_terms <- paste0(wb.char, "_bar")
  data[intersect(c(between_terms, within_terms), names(data))] <- NULL
  decomposed <- tibble::as_tibble(data_decompose_within_between(data, ProvID.char, wb.char))
  rhs_terms <- c(within_terms, between_terms, other.char)
  used <- decomposed[, c(Y.char, ProvID.char, rhs_terms), drop = FALSE]
  used <- used[stats::complete.cases(used), ]
  used <- used[order(factor(used[[ProvID.char]])), ]
  formula <- stats::as.formula(paste(Y.char, "~", paste(rhs_terms, collapse = " + "), "+ (1 |", ProvID.char, ")"))
  list(data = used, formula = formula, response = Y.char, provider = ProvID.char, within_terms = within_terms,
       between_terms = between_terms, other = other.char)
}

# The reference's linear_re, logis_re, or linear_cre object (R/linear_re.R:154-232,
# R/logis_re.R:154-233, R/linear_cre.R:121-200) from the lme4 fit of `inputs`.
compat_re_object <- function(fit, inputs, class) {
  linear <- class %in% c("linear_re", "linear_cre")
  x_model <- stats::model.matrix(fit)
  response <- as.matrix(inputs$data[, inputs$response, drop = FALSE])
  provider <- as.matrix(inputs$data[, inputs$provider, drop = FALSE])
  data_include <- as.data.frame(cbind(response, provider, x_model))
  n_prov <- sapply(split(data_include[, inputs$response], data_include[, inputs$provider]), length)
  fixed <- lme4::fixef(fit)
  fe <- matrix(fixed, dimnames = list(names(fixed), "Coefficient"))
  re <- as.matrix(lme4::ranef(fit, condVar = TRUE)[[inputs$provider]])
  dimnames(re) <- list(names(n_prov), "alpha")
  fit_summary <- summary(fit)
  # K-51.
  var_alpha <- matrix(as.data.frame(fit_summary$varcor)[1, "sdcor"]^2, dimnames = list("ProvID", "Variance.Alpha"))
  varcov_fe <- matrix(fit_summary$vcov, ncol = length(fixed),
                      dimnames = list(rownames(fit_summary$vcov), colnames(fit_summary$vcov)))
  rows <- seq_len(nrow(x_model))
  linear_pred <- x_model %*% fe
  dimnames(linear_pred) <- list(rows, "Fixed Fitted")
  fields <- list(coefficient = list(FE = fe, RE = re), variance = list(alpha = var_alpha, FE = varcov_fe))
  if (linear) fields$sigma <- fit_summary$sigma
  fields$fitted <- matrix(stats::fitted(fit), ncol = 1L, dimnames = list(rows, "Prediction"))
  fields$observation <- response
  if (linear) fields$residuals <- matrix(stats::residuals(fit), ncol = 1L, dimnames = list(rows, "Residuals"))
  fields <- c(fields, list(linear_pred = linear_pred, Loglkd = stats::logLik(fit), AIC = stats::AIC(fit),
                           BIC = stats::BIC(fit)))
  result <- structure(fields, class = class)
  result$data_include <- data_include
  result$char_list <- if (identical(class, "linear_cre")) {
    list(Y.char = inputs$response, ProvID.char = inputs$provider, within_terms = inputs$within_terms,
         between_terms = inputs$between_terms, other.vars = inputs$other)
  } else {
    list(Y.char = inputs$response, ProvID.char = inputs$provider, Z.char = rownames(fe)[2:length(rownames(fe))])
  }
  attr(result, "model") <- fit
  result
}

# The reference's logis_cre object (R/logis_cre.R:118-193), whose shapes differ from those of
# the other three fits: tibble columns for the observation and data_include, no row names on
# the fitted values, the provider rows of ranef(), the variance as VarCorr's `vcov` (K-51), and
# as.matrix() of the summary's vcov.
compat_logis_cre_object <- function(fit, inputs) {
  x_model <- stats::model.matrix(fit)
  response <- inputs$data[, inputs$response, drop = FALSE]
  provider <- inputs$data[, inputs$provider, drop = FALSE]
  data_include <- as.data.frame(cbind(response, provider, x_model))
  fixed <- lme4::fixef(fit)
  fe <- matrix(fixed, dimnames = list(names(fixed), "Coefficient"))
  random <- lme4::ranef(fit)[[inputs$provider]]
  re <- as.matrix(random)
  dimnames(re) <- list(rownames(random), "alpha")
  fit_summary <- summary(fit)
  var_alpha <- matrix(as.data.frame(fit_summary$varcor)[1, "vcov"], dimnames = list(inputs$provider, "Variance.Alpha"))
  varcov_fe <- as.matrix(fit_summary$vcov)
  dimnames(varcov_fe) <- list(rownames(fit_summary$vcov), colnames(fit_summary$vcov))
  linear_pred <- x_model %*% fe
  colnames(linear_pred) <- "Fixed Fitted"
  structure(
    list(
      coefficient = list(FE = fe, RE = re), variance = list(alpha = var_alpha, FE = varcov_fe),
      fitted = matrix(stats::fitted(fit), ncol = 1L, dimnames = list(NULL, "Prediction")),
      observation = response, linear_pred = linear_pred, Loglkd = stats::logLik(fit), AIC = stats::AIC(fit),
      BIC = stats::BIC(fit), data_include = data_include,
      char_list = list(Y.char = inputs$response, ProvID.char = inputs$provider, within_terms = inputs$within_terms,
                       between_terms = inputs$between_terms, other.vars = inputs$other)
    ),
    class = "logis_cre",
    model = fit
  )
}
