#' Prepare data for a provider-profiling model
#'
#' Builds the `pprof_data` object that every fit function starts from: the response, the
#' covariate design matrix, each observation's provider in the provider order, the provider
#' table with its screening indicators, and the map back to the rows of `data`. It is part of
#' the interface for developers of new models: a fit function builds its data with
#' `data_prepare()` and its object with [new_pprof_model()]; see
#' `vignette("adding-a-model", package = "pprof")`.
#'
#' The steps reproduce the reference implementation (pprof 1.0.3) for every input it
#' supports:
#'
#' 1. For correlated random-effect models, each covariate in `within_between` is replaced by
#'    its provider mean (`<name>_bar`, over every row of `data`) and its deviation from that
#'    mean (`<name>_within`), before any row is dropped.
#' 2. Rows with a missing value in the response, the provider, or a covariate are dropped.
#' 3. The design matrix comes from [stats::model.matrix()] with the session's contrasts; unused
#'    factor levels are kept. Without an intercept, the intercept column is dropped.
#' 4. Providers are ordered by the levels of `factor()` of the provider column (numbers
#'    numerically, strings in the collation order of the session's locale) and observations
#'    are sorted by provider with a stable sort.
#' 5. With `min_provider_size`, providers with fewer complete observations are excluded,
#'    together with their observations. With `event_counts = TRUE`, the provider table also
#'    counts events and flags included providers with no events or only events.
#'
#' For survival data (`response_type = "survival"`, the Cox models), the response is a
#' [survival::Surv()] object, right-censored, `Surv(time, status)`, or with entry times,
#' `Surv(start, stop, status)`, and `formula` has none of survival's special terms
#' (`strata()`, `cluster()`, `tt()`, `frailty()`, `ridge()`, `pspline()`), since the provider
#' is the strata. `response` holds the status, which `Surv()` makes 0 or 1 from 0/1, logical,
#' and 1/2 codings, and the elements `start` (0 for right-censored data) and `stop` hold the
#' times; `settings$survival_type` is `"right"` or `"counting"`, the type of the response.
#' Right-censored times must be finite and above 0, and entry times finite and below
#' their exit times; a status `Surv()` cannot read, or an entry time not below its exit time, is
#' an error rather than a missing value. With `event_counts = TRUE` the provider table also has
#' `person_time`, the sum of `stop - start`. Rows with a missing value in the weights, the
#' cluster, or a variable of an `offset()` term are dropped too.
#'
#' @param formula A two-sided formula: the response on the left, the covariates on the right.
#'   The provider is not part of the formula.
#' @param data A data frame.
#' @param provider The name of the column of `data` that identifies providers.
#' @param within_between Names of covariate terms of `formula` to decompose into within-provider
#'   deviations and provider means, or `NULL`.
#' @param min_provider_size The smallest number of complete observations for a provider to be
#'   included, or `NULL` to include every provider.
#' @param intercept Whether the design matrix keeps the intercept column. Fixed-effect models
#'   use `FALSE`, because the provider effects absorb the intercept.
#' @param event_counts Whether to count events per provider and flag providers with no events
#'   or only events (binary outcomes).
#' @param response_type `"default"`, or `"survival"` for a `Surv()` response.
#' @param weights The name of a column of case weights, finite and at least 0, kept as
#'   `weights`, or `NULL`.
#' @param cluster The name of a column of clusters, kept as `cluster`: a factor as it is, other
#'   values as integer codes in the order of their first appearance among the observations;
#'   or `NULL`.
#' @param allow_offset Whether `formula` may contain `offset()` terms, whose sum is kept as
#'   `offset`.
#'
#' @return A list of class `pprof_data` with the elements `formula`, `terms`, `xlevels`,
#'   `response_name`, `provider_name`, `within_between`, `response`, `design`, `providers`,
#'   `provider_index`, `row_index`, `settings`, `n_input`, `n_incomplete`, and
#'   `n_excluded_obs`, and where they apply `start`, `stop`, `weights`, `cluster`, and
#'   `offset`, one value per observation. Observations of excluded providers are not part of
#'   `response`, `design`, `provider_index`, `row_index`, or these; the provider table lists
#'   every provider.
#'
#' @examples
#' data(ExampleDataBinary)
#' example <- data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID,
#'                       ExampleDataBinary$Z)
#' prepared <- data_prepare(y ~ z1 + z2, example, "hospital", min_provider_size = 10,
#'                          event_counts = TRUE)
#' dim(prepared$design)
#' head(prepared$providers)
#' @keywords internal
#' @export
data_prepare <- function(formula, data, provider, within_between = NULL, min_provider_size = NULL,
                         intercept = FALSE, event_counts = FALSE, response_type = "default", weights = NULL,
                         cluster = NULL, allow_offset = FALSE) {
  check_formula(formula)
  check_data_frame(data)
  check_string(provider, "provider")
  check_column(data, provider, "provider")
  if (!is.null(within_between)) check_names(within_between, "within_between")
  if (!is.null(min_provider_size)) check_count(min_provider_size, "min_provider_size", min = 1)
  check_flag(intercept, "intercept")
  check_flag(event_counts, "event_counts")
  check_choice(response_type, c("default", "survival"), "response_type")
  data_check_column_argument(data, weights, "weights")
  data_check_column_argument(data, cluster, "cluster")
  check_flag(allow_offset, "allow_offset")
  survival <- identical(response_type, "survival")
  # The data layer's settings beyond those of the existing families, recorded only when used, so
  # that the existing families' objects are unchanged (COXPH_DESIGN §C.2).
  extended <- survival || !is.null(weights) || !is.null(cluster) || allow_offset
  if (survival && (intercept || !is.null(within_between))) {
    abort_invalid_input("Survival data have no intercept and no within-between decomposition.",
                        arg = "response_type")
  }
  provider_values <- data[[provider]]
  if (!is.atomic(provider_values) || !is.null(dim(provider_values))) {
    abort_invalid_input(sprintf("The provider column '%s' must be an atomic vector or a factor.", provider),
                        arg = "provider")
  }

  parsed <- data_parse_formula(formula, data, provider, intercept, response_type = response_type,
                               allow_offset = allow_offset)
  terms <- parsed$terms
  if (!is.null(within_between)) {
    for (variable in within_between) check_column(data, variable, "within_between")
    formula_used <- data_decompose_formula(terms, within_between)
    data <- data_decompose_within_between(data, provider, within_between)
    parsed <- data_parse_formula(formula_used, data, provider, intercept)
    terms <- parsed$terms
  }

  complete <- data_complete_rows(data, c(parsed$variables, provider, weights, cluster))
  if (length(complete) == 0L) {
    abort_data(if (extended) {
      "No complete observations: every row has a missing response, provider, covariate, offset, weight, or cluster."
    } else {
      "No complete observations: every row has a missing response, provider, or covariate."
    })
  }
  model_frame <- if (survival) {
    data_without_surv_warnings(data_model_frame(terms, data, complete, inspect = data_check_survival_frame))
  } else {
    data_model_frame(terms, data, complete)
  }
  frame <- model_frame$frame
  rows <- model_frame$rows
  if (survival) {
    times <- data_survival_response(frame)
    data_check_survival_values(times)
    response <- times$status
  } else {
    response <- data_response(frame)
  }
  offset <- if (allow_offset) data_offset(frame)
  design <- data_build_design(terms, frame, intercept)

  index <- data_index_providers(data[[provider]][rows])
  sorted <- index$order
  codes <- index$codes[sorted]
  response <- response[sorted]
  design <- data_subset_design(design, sorted)
  rows <- rows[sorted]
  # Survival data's times, and the weights, clusters, and offsets of each observation, in the
  # sorted order; NULL where they do not apply.
  observations <- list(
    start = if (survival) times$start[sorted], stop = if (survival) times$stop[sorted],
    weights = if (!is.null(weights)) data_case_weights(data[[weights]][rows], weights),
    cluster = if (!is.null(cluster)) data_cluster_codes(data[[cluster]][rows], cluster),
    offset = if (!is.null(offset)) offset[sorted]
  )

  providers <- data_provider_table(index$levels, codes, data[[provider]][rows])
  providers <- data_screen_providers(providers, min_provider_size)
  if (event_counts) providers <- data_event_indicators(providers, response, codes)
  if (survival && event_counts) providers <- data_person_time(providers, observations$start, observations$stop, codes)
  if (!any(providers$included)) {
    abort_data(sprintf("No providers left after screening: every provider has fewer than %s complete observations.",
                       format(min_provider_size)))
  }

  kept <- providers$included[codes]
  settings <- list(min_provider_size = min_provider_size, intercept = intercept, event_counts = event_counts)
  if (extended) {
    settings <- c(settings, list(response_type = response_type, weights = weights, cluster = cluster,
                                 allow_offset = allow_offset))
    # The type of the Surv() response, which selects survival's fitter (R/model-survival.R).
    if (survival) settings$survival_type <- if (times$counting) "counting" else "right"
  }
  new_pprof_data(
    formula = formula,
    terms = terms,
    xlevels = stats::.getXlevels(terms, frame),
    response_name = parsed$response_name,
    provider_name = provider,
    within_between = within_between,
    response = response[kept],
    design = data_subset_design(design, kept),
    providers = providers,
    provider_index = codes[kept],
    row_index = rows[kept],
    settings = settings,
    n_input = nrow(data),
    n_incomplete = nrow(data) - length(rows),
    n_excluded_obs = sum(!kept),
    start = observations$start[kept], stop = observations$stop[kept], weights = observations$weights[kept],
    cluster = observations$cluster[kept], offset = observations$offset[kept]
  )
}
