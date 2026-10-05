#' Prepare data for a provider-profiling model
#'
#' Builds the `pprof_data` object that every fit function starts from: the response, the
#' covariate design matrix, each observation's provider in the provider order, the provider
#' table with its screening indicators, and the map back to the rows of `data`. It is part of
#' the interface for developers of new models: a fit function builds its data with
#' `data_prepare()` and its object with [new_pprof_model()].
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
#'
#' @return A list of class `pprof_data` with the elements `formula`, `terms`, `xlevels`,
#'   `response_name`, `provider_name`, `within_between`, `response`, `design`, `providers`,
#'   `provider_index`, `row_index`, `settings`, `n_input`, `n_incomplete`, and
#'   `n_excluded_obs`. Observations of excluded providers are not part of `response`,
#'   `design`, `provider_index`, or `row_index`; the provider table lists every provider.
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
                         intercept = FALSE, event_counts = FALSE) {
  check_formula(formula)
  check_data_frame(data)
  check_string(provider, "provider")
  check_column(data, provider, "provider")
  if (!is.null(within_between)) check_names(within_between, "within_between")
  if (!is.null(min_provider_size)) check_count(min_provider_size, "min_provider_size", min = 1)
  check_flag(intercept, "intercept")
  check_flag(event_counts, "event_counts")
  provider_values <- data[[provider]]
  if (!is.atomic(provider_values) || !is.null(dim(provider_values))) {
    abort_invalid_input(sprintf("The provider column '%s' must be an atomic vector or a factor.", provider),
                        arg = "provider")
  }

  parsed <- data_parse_formula(formula, data, provider, intercept)
  terms <- parsed$terms
  if (!is.null(within_between)) {
    for (variable in within_between) check_column(data, variable, "within_between")
    formula_used <- data_decompose_formula(terms, within_between)
    data <- data_decompose_within_between(data, provider, within_between)
    parsed <- data_parse_formula(formula_used, data, provider, intercept)
    terms <- parsed$terms
  }

  complete <- data_complete_rows(data, c(parsed$variables, provider))
  if (length(complete) == 0L) {
    abort_data("No complete observations: every row has a missing response, provider, or covariate.")
  }
  model_frame <- data_model_frame(terms, data, complete)
  frame <- model_frame$frame
  rows <- model_frame$rows
  response <- data_response(frame)
  design <- data_build_design(terms, frame, intercept)

  index <- data_index_providers(data[[provider]][rows])
  sorted <- index$order
  codes <- index$codes[sorted]
  response <- response[sorted]
  design <- data_subset_design(design, sorted)
  rows <- rows[sorted]

  providers <- data_provider_table(index$levels, codes, data[[provider]][rows])
  providers <- data_screen_providers(providers, min_provider_size)
  if (event_counts) providers <- data_event_indicators(providers, response, codes)
  if (!any(providers$included)) {
    abort_data(sprintf("No providers left after screening: every provider has fewer than %s complete observations.",
                       format(min_provider_size)))
  }

  kept <- providers$included[codes]
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
    settings = list(min_provider_size = min_provider_size, intercept = intercept, event_counts = event_counts),
    n_input = nrow(data),
    n_incomplete = nrow(data) - length(rows),
    n_excluded_obs = sum(!kept)
  )
}
