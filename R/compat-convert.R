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

# The reference's `data_include` from a model fit with keep_data = TRUE: the included rows
# in provider order, data.frame(Y, ProvID, Z) with names passed through make.names(), the
# input's row names in their stored type, and the screening indicators.
compat_data_include <- function(model, inputs) {
  prepared <- model$data
  design <- prepared$design
  attr(design, "assign") <- NULL
  attr(design, "contrasts") <- NULL
  ids <- prepared$providers$provider_value[prepared$provider_index]
  out <- data.frame(prepared$response, ids, design)
  names(out) <- make.names(c(inputs$response_name, inputs$provider_name, colnames(design)), unique = TRUE)
  out$included <- 1
  out$no.events <- as.numeric(prepared$providers$no_events[prepared$provider_index])
  out$all.events <- as.numeric(prepared$providers$all_events[prepared$provider_index])
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
  provider <- factor(as.character(ids), levels = provider_order)
  if (anyNA(provider) || is.unsorted(as.integer(provider))) {
    abort_invalid_input("The fit's `data_include` does not match its provider effects.", arg = "fit")
  }
  design <- as.matrix(data[, 2L + seq_along(covariates), drop = FALSE])
  internal <- sprintf("covariate_%d", seq_along(covariates))
  frame <- data.frame(response = data[[chars$Y.char]], provider = provider, design)
  names(frame) <- c("response", "provider", internal)
  prepared <- data_prepare(stats::reformulate(internal, response = "response"), frame, "provider",
                           min_provider_size = 1, event_counts = TRUE)
  colnames(prepared$design) <- covariates
  prepared$providers$provider_value <- unique(ids)
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
