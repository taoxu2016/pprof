# The `pprof_data` class: the data layer's output (ARCHITECTURE §B.2), built by
# data_prepare().

new_pprof_data <- function(formula, terms, xlevels, response_name, provider_name, within_between,
                           response, design, providers, provider_index, row_index, settings,
                           n_input, n_incomplete, n_excluded_obs, start = NULL, stop = NULL, weights = NULL,
                           cluster = NULL, offset = NULL) {
  # The elements of survival data, weights, clusters, and offsets are present only where they
  # apply, so that the existing families' objects are unchanged (COXPH_DESIGN §C.2).
  optional <- list(start = start, stop = stop, weights = weights, cluster = cluster, offset = offset)
  x <- structure(
    c(
      list(
        formula = formula, terms = terms, xlevels = xlevels, response_name = response_name,
        provider_name = provider_name, within_between = within_between, response = response,
        design = design, providers = providers, provider_index = provider_index,
        row_index = row_index, settings = settings, n_input = as.integer(n_input),
        n_incomplete = as.integer(n_incomplete), n_excluded_obs = as.integer(n_excluded_obs)
      ),
      optional[!vapply(optional, is.null, logical(1))]
    ),
    class = "pprof_data"
  )
  validate_pprof_data(x)
  x
}

# Internal consistency of a `pprof_data` object. Every check failure is reported as
# invalid input, naming the offending element.
validate_pprof_data <- function(x) {
  fail <- function(what) abort_invalid_input(sprintf("Invalid `pprof_data` object: %s.", what), arg = "x")
  if (!inherits(x, "pprof_data")) fail("not of class `pprof_data`")
  n <- length(x$response)
  if (!(is.numeric(x$response) || is.logical(x$response)) || !is.null(dim(x$response))) {
    fail("`response` must be a numeric or logical vector")
  }
  if (!is.matrix(x$design) || !is.numeric(x$design) || nrow(x$design) != n) {
    fail("`design` must be a numeric matrix with one row per observation")
  }
  if (is.null(colnames(x$design)) && ncol(x$design) > 0L) fail("`design` must have column names")
  if (!isTRUE(x$settings$intercept) && "(Intercept)" %in% colnames(x$design)) {
    fail("`design` has an intercept column although `settings$intercept` is FALSE")
  }
  providers <- x$providers
  required <- c("provider_id", "provider_value", "n_obs", "included")
  if (isTRUE(x$settings$event_counts)) required <- c(required, "n_events", "no_events", "all_events")
  if (!is.data.frame(providers) || !all(required %in% names(providers))) {
    fail(sprintf("`providers` must be a data frame with columns %s", paste(required, collapse = ", ")))
  }
  ids <- providers$provider_id
  if (!is.character(ids) || anyNA(ids) || anyDuplicated(ids) > 0L) {
    fail("`providers$provider_id` must be distinct, non-missing strings")
  }
  if (!is.logical(providers$included) || anyNA(providers$included)) fail("`providers$included` must be TRUE or FALSE")
  index <- x$provider_index
  if (!is.integer(index) || length(index) != n || anyNA(index) || any(index < 1L | index > nrow(providers))) {
    fail("`provider_index` must give a row of `providers` for every observation")
  }
  if (is.unsorted(index)) fail("observations must be sorted by provider")
  if (!all(providers$included[index])) fail("every observation must belong to an included provider")
  counts <- tabulate(index, nbins = nrow(providers))
  if (!identical(counts[providers$included], as.integer(providers$n_obs[providers$included])) ||
        any(counts[!providers$included] != 0L)) {
    fail("`providers$n_obs` does not match the observations")
  }
  if (!is.integer(x$row_index) || length(x$row_index) != n || anyNA(x$row_index) ||
        anyDuplicated(x$row_index) > 0L || any(x$row_index < 1L | x$row_index > x$n_input)) {
    fail("`row_index` must give a distinct row of the input data for every observation")
  }
  if (x$n_input != n + x$n_excluded_obs + x$n_incomplete) {
    fail("`n_input` must equal the observations kept, excluded by screening, and incomplete")
  }
  validate_pprof_data_survival(x, n)
  invisible(x)
}

# The elements of survival data, weights, clusters, and offsets, where present (COXPH_DESIGN §C.1).
validate_pprof_data_survival <- function(x, n) {
  fail <- function(what) abort_invalid_input(sprintf("Invalid `pprof_data` object: %s.", what), arg = "x")
  per_observation <- function(value) is.double(value) && is.null(dim(value)) && length(value) == n
  if (identical(x[["settings"]][["response_type"]], "survival")) {
    if (!per_observation(x[["start"]]) || !per_observation(x[["stop"]])) {
      fail("survival data must have `start` and `stop` times for every observation")
    }
    if (!all(is.finite(x[["start"]]) & is.finite(x[["stop"]]) & x[["start"]] < x[["stop"]])) {
      fail("every `start` time must be finite and below its finite `stop` time")
    }
    type <- x[["settings"]][["survival_type"]]
    if (!(identical(type, "right") || identical(type, "counting"))) {
      fail("`settings$survival_type` must be \"right\" or \"counting\"")
    }
    if (identical(type, "right") && any(x[["start"]] != 0)) fail("right-censored data must start at 0")
    if (!is.numeric(x[["response"]]) || !all(x[["response"]] %in% c(0, 1))) fail("the status must be 0 or 1")
    if (isTRUE(x[["settings"]][["event_counts"]]) && !"person_time" %in% names(x[["providers"]])) {
      fail("the provider table of survival data must have `person_time`")
    }
  }
  weights <- x[["weights"]]
  if (!is.null(weights) && (!per_observation(weights) || !all(is.finite(weights) & weights >= 0))) {
    fail("`weights` must be finite numbers of at least 0, one per observation")
  }
  cluster <- x[["cluster"]]
  if (!is.null(cluster) && (!(is.integer(cluster) || is.factor(cluster)) || length(cluster) != n || anyNA(cluster))) {
    fail("`cluster` must give an integer code or factor level for every observation")
  }
  offset <- x[["offset"]]
  if (!is.null(offset) && (!per_observation(offset) || !all(is.finite(offset)))) {
    fail("`offset` must be a finite number for every observation")
  }
  invisible(x)
}

#' @export
print.pprof_data <- function(x, ...) {
  providers <- x$providers
  cat("<pprof_data>\n")
  cat(sprintf("Response: %s; provider: %s\n", x$response_name, x$provider_name))
  cat(sprintf("Observations: %d used, %d excluded by screening, %d with missing values (of %d)\n",
              length(x$response), x$n_excluded_obs, x$n_incomplete, x$n_input))
  cat(sprintf("Providers: %d included, %d excluded\n", sum(providers$included), sum(!providers$included)))
  covariates <- colnames(x$design)
  cat(sprintf("Design: %d column%s%s\n", length(covariates), if (length(covariates) == 1L) "" else "s",
              if (length(covariates) > 0L) paste0(" (", paste(utils::head(covariates, 6L), collapse = ", "),
                                                  if (length(covariates) > 6L) ", ..." else "", ")") else ""))
  invisible(x)
}
