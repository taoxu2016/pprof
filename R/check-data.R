# Data checks (DEC-010, DEC-073; ARCHITECTURE §B.2, the diagnostics layer).
#
# check_data() reports, without stopping, what data_check() of pprof 1.0.3 checked with stops
# and warnings (D-17): missing values; covariates without variation or nearly without, by the
# rule of caret::nearZeroVar() (K-120); pairs of covariates whose correlation exceeds 0.9 in
# absolute value; and variance inflation factors of 10 or more, computed as
# olsrr::ols_vif_tol() computes them. The three computations below repeat caret's and olsrr's
# definitions, so that pprof needs neither package (DEC-009); their tests compare them with
# both packages when these are installed, and data_check() (R/compat-data-check.R) uses them.

# caret's nearZeroVar(x, saveMetrics = TRUE) (caret:::nzv()): for each column, the ratio of the
# frequencies of the most common and the second most common value, the percentage of distinct
# values, whether the column has one value only, and whether it has near-zero variance (a ratio
# above freq_cut with at most unique_cut percent distinct values, or one value only). The row
# names are the column names.
check_near_zero <- function(x, freq_cut = near_zero_frequency_ratio, unique_cut = near_zero_percent_unique) {
  if (is.null(dim(x))) x <- matrix(x, ncol = 1L)
  freq_ratio <- apply(x, 2L, function(values) {
    counts <- table(values[!is.na(values)])
    if (length(counts) <= 1L) return(0)
    most <- which.max(counts)
    max(counts, na.rm = TRUE) / max(counts[-most], na.rm = TRUE)
  })
  n_unique <- apply(x, 2L, function(values) length(unique(values[!is.na(values)])))
  percent_unique <- 100 * n_unique / apply(x, 2L, length)
  zero_var <- (n_unique == 1L) | apply(x, 2L, function(values) all(is.na(values)))
  data.frame(freqRatio = freq_ratio, percentUnique = percent_unique, zeroVar = zero_var,
             nzv = (freq_ratio > freq_cut & percent_unique <= unique_cut) | zero_var)
}

# olsrr's ols_vif_tol() (olsrr:::viftol()) of a linear model whose design columns, without the
# intercept, are the columns of `columns`: each column regressed on the others with an
# intercept, its tolerance 1 - R^2, and its variance inflation factor 1 / (1 - R^2).
check_vif <- function(columns) {
  names <- names(columns)
  tolerance <- numeric()
  for (i in seq_along(names)) {
    formula <- stats::as.formula(paste0("`", names[i], "` ~ ."))
    tolerance[i] <- 1 - summary(stats::lm(formula, data = columns))$r.squared
  }
  data.frame(Variables = names, Tolerance = tolerance, VIF = 1 / tolerance)
}

# The pairs of columns whose correlation exceeds `threshold` in absolute value, in the order in
# which data_check() of pprof 1.0.3 lists them (by column of the correlation matrix, then row).
check_correlations <- function(x, threshold = correlation_threshold) {
  empty <- data.frame(term_1 = character(), term_2 = character(), correlation = numeric())
  if (NCOL(x) < 2L) return(empty)
  correlation <- stats::cor(x)
  upper <- correlation
  upper[lower.tri(upper, diag = TRUE)] <- 0
  index <- which(abs(upper) > threshold)
  if (length(index) == 0L) return(empty)
  cells <- arrayInd(index, dim(correlation))
  data.frame(term_1 = rownames(correlation)[cells[, 1L]], term_2 = colnames(correlation)[cells[, 2L]],
             correlation = correlation[index])
}

#' Check the data before fitting a model
#'
#' `check_data()` checks the data of a model as [data_check()] of pprof 1.0.3 did, but reports
#' instead of stopping: the missing values of each variable, which the fitting functions drop
#' with their rows; the covariates with no variation or nearly none; the pairs of covariates that
#' are highly correlated; and the variance inflation factors of the covariates. No model result
#' depends on it.
#'
#' The covariates are the columns of the design matrix that the fitting functions build from
#' `formula`, without the intercept, over the complete observations: a factor contributes one
#' column for each level but the first. A column has zero variance when it has one value only,
#' and near-zero variance when the most common value is more than 19 times as frequent as the
#' second most common and at most 10% of its values are distinct, the rule of
#' `caret::nearZeroVar()`. Pairs of columns are listed when their correlation exceeds 0.9 in
#' absolute value. The variance inflation factor of a column is 1 / (1 - R^2), with R^2 that of
#' the linear regression of the column on the other columns, as `olsrr::ols_vif_tol()` computes
#' it; a factor of 10 or more is commonly taken to indicate serious multicollinearity.
#' Correlations and variance inflation factors are computed over the columns that vary.
#'
#' For survival data, a `Surv()` response as [fit_cox_stratified()] takes it, the result also
#' reports, over the complete observations:
#'
#' - near-tied times: the rows whose times survival's [survival::aeqSurv()] would merge, which
#'   [survival::coxph()] does by default (`timefix = TRUE`) and the Cox fits of pprof do not, since
#'   they compare times exactly; integer time units avoid such ties;
#' - zero and negative weights (Cox fits leave rows with weight 0 out, and reject negative ones);
#' - rows whose status `Surv()` cannot read (0/1, logical, and 1/2 codings are read), and rows
#'   with an entry time not below the exit time, or a right-censored time of 0 or less;
#' - providers with no events, and with no person-time;
#' - covariates linearly dependent on the others within providers, such as a covariate that is
#'   constant within every provider, whose coefficients a model stratified by provider cannot
#'   estimate;
#' - covariates whose mean exceeds 100 standard deviations in absolute value, such as a calendar
#'   year: survival centers covariates, so its fits are unaffected, but software that evaluates
#'   exp() of the uncentered linear predictor may overflow.
#'
#' @param formula A two-sided formula with the outcome on the left and the covariates on the
#'   right, as the fitting functions take it.
#' @param data A data frame with the variables of `formula` and the provider column.
#' @param provider The name of the provider column of `data`.
#' @param weights For survival data, the name of a column of case weights, or `NULL`.
#' @param cluster For survival data, the name of a column of clusters, or `NULL`.
#'
#' @return A `pprof_data_check` result: a list whose `table` has one row for each variable of
#'   `formula` and for the provider, with `variable`, `role` (`"outcome"`, `"covariate"`, or
#'   `"provider"`, and for survival data also `"offset"`, `"weights"`, and `"cluster"`),
#'   `n_missing`, and `percent_missing`; `n_obs` and `n_complete`, the numbers of
#'   observations and of complete observations; `design`, one row for each covariate column,
#'   with `term`, `frequency_ratio`, `percent_unique`, `zero_variance`, `near_zero_variance`,
#'   and `vif` (missing for a column without variation); `correlations`, the pairs of columns
#'   correlated above the threshold, with `term_1`, `term_2`, and `correlation`; and the
#'   thresholds used (`frequency_ratio_cut`, `percent_unique_cut`, `correlation_threshold`,
#'   `vif_threshold`). For survival data, `survival` holds the checks above: `type`
#'   (`"right"` or `"counting"`), `n_events`, `near_tied_rows`, `zero_weights`,
#'   `negative_weights`, `invalid_status`, `invalid_times`, `providers_without_events`,
#'   `providers_without_person_time`, `aliased`, `large_mean`, and `large_mean_ratio`. Printing
#'   it lists the problems found.
#'
#' @seealso [fit_logistic_fe()] and the other fitting functions; [data_check()], the function
#'   of pprof 1.0.3 that stops at the first problem.
#'
#' @examples
#' data(ExampleDataBinary)
#' data <- data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID,
#'                    ExampleDataBinary$Z)
#' data$z1[c(5, 17)] <- NA
#' check_data(y ~ z1 + z2 + z3 + z4 + z5, data, "hospital")
#'
#' # Survival data: the lung cancer data of the survival package, by institution.
#' check_data(Surv(time, status) ~ age + sex, survival::lung, "inst")
#'
#' @export
check_data <- function(formula, data, provider, weights = NULL, cluster = NULL) {
  check_formula(formula)
  check_data_frame(data)
  check_string(provider, "provider")
  check_column(data, provider, "provider")
  survival <- data_is_surv_call(formula[[2L]])
  if (!survival && (!is.null(weights) || !is.null(cluster))) {
    abort_invalid_input("`weights` and `cluster` apply to survival data, with a Surv() response.",
                        arg = if (is.null(weights)) "cluster" else "weights")
  }
  data_check_column_argument(data, weights, "weights")
  data_check_column_argument(data, cluster, "cluster")
  variables <- all.vars(formula)
  outcome <- all.vars(formula[[2L]])
  missing_columns <- setdiff(variables, names(data))
  if (length(missing_columns) > 0L) {
    abort_invalid_input(sprintf("`data` has no columns named %s.", paste(missing_columns, collapse = ", ")),
                        arg = "data")
  }
  variables <- unique(c(outcome, setdiff(variables, c(outcome, provider)), provider))
  role <- ifelse(variables %in% outcome, "outcome", ifelse(variables == provider, "provider", "covariate"))
  if (survival) {
    role[variables %in% check_offset_only_variables(formula, data)] <- "offset"
    columns <- c(weights = weights, cluster = cluster)
    role <- c(role[!variables %in% columns], names(columns))
    variables <- c(variables[!variables %in% columns], unname(columns))
  }
  n_missing <- vapply(variables, function(v) sum(is.na(data[[v]])), integer(1L), USE.NAMES = FALSE)
  table <- data.frame(variable = variables, role = role, n_missing = n_missing,
                      percent_missing = 100 * n_missing / nrow(data))
  complete <- stats::complete.cases(data[variables])

  survival_check <- if (survival) check_survival(formula, data, provider, weights, cluster)
  design <- if (survival) survival_check$design else data_prepare(formula, data, provider)$design
  variation <- check_near_zero(design)
  varies <- !variation$zeroVar
  vif <- rep(NA_real_, ncol(design))
  if (any(varies)) {
    # summary.lm() warns of an "essentially perfect fit" for a column that the others determine
    # exactly; its VIF reports that (very large or infinite), so check_data() reports instead of
    # warning. data_check() lets the warning through, as pprof 1.0.3 did through olsrr.
    vif[varies] <- withCallingHandlers(
      check_vif(as.data.frame(design[, varies, drop = FALSE]))$VIF,
      warning = function(w) {
        if (grepl("essentially perfect fit", conditionMessage(w), fixed = TRUE)) invokeRestart("muffleWarning")
      }
    )
  }
  design_table <- data.frame(term = colnames(design), frequency_ratio = variation$freqRatio,
                             percent_unique = variation$percentUnique, zero_variance = variation$zeroVar,
                             near_zero_variance = variation$nzv, vif = vif)
  result <- new_pprof_data_check(
    table, n_obs = nrow(data), n_complete = sum(complete), design = design_table,
    correlations = check_correlations(design[, varies, drop = FALSE]),
    frequency_ratio_cut = near_zero_frequency_ratio, percent_unique_cut = near_zero_percent_unique,
    correlation_threshold = correlation_threshold, vif_threshold = vif_threshold
  )
  # Only survival data have the element, so that the other families' results are unchanged.
  if (survival) result$survival <- survival_check$report
  result
}

# The variables that appear only in the offset() terms of `formula`.
check_offset_only_variables <- function(formula, data) {
  terms <- stats::terms(formula, specials = data_survival_specials, data = data)
  labels <- attr(terms, "term.labels")
  covariates <- unique(unlist(lapply(labels, function(label) all.vars(str2lang(label)))))
  setdiff(data_offset_variables(terms), c(covariates, all.vars(formula[[2L]])))
}

# The checks of survival data (DEC-104): the design of the complete rows whose response Surv() can
# read, for the covariate checks, and the report. They read the data with the data layer's steps but
# without its value checks, so that they report what data_prepare() would stop at.
check_survival <- function(formula, data, provider, weights, cluster) {
  parsed <- data_parse_formula(formula, data, provider, intercept = FALSE, response_type = "survival",
                               allow_offset = TRUE)
  terms <- parsed$terms
  rows <- data_complete_rows(data, c(parsed$variables, provider, weights, cluster))
  if (length(rows) == 0L) {
    abort_data(paste("No complete observations: every row has a missing response, provider, covariate, offset,",
                     "weight, or cluster."))
  }
  found <- new.env(parent = emptyenv())
  model_frame <- data_without_surv_warnings(data_model_frame(terms, data, rows, inspect = function(frame) {
    found$problems <- data_survival_frame_problems(frame)
  }))
  frame <- model_frame$frame
  times <- data_survival_response(frame)
  design <- data_build_design(terms, frame, intercept = FALSE)
  index <- data_index_providers(data[[provider]][model_frame$rows])
  events <- tabulate(index$codes[times$status == 1], nbins = length(index$levels))
  person_time <- vapply(split(times$stop - times$start, factor(index$codes, levels = seq_along(index$levels))),
                        sum, numeric(1), USE.NAMES = FALSE)
  weight_values <- if (!is.null(weights)) data[[weights]][rows]
  if (!is.null(weight_values) && !is.numeric(weight_values)) {
    abort_invalid_input(sprintf("The weights column '%s' must be numeric.", weights), arg = "weights")
  }
  list(design = design, report = list(
    type = if (times$counting) "counting" else "right",
    n_events = sum(times$status),
    near_tied_rows = check_near_tied_rows(stats::model.response(frame)),
    zero_weights = if (is.null(weight_values)) 0L else sum(weight_values == 0),
    negative_weights = if (is.null(weight_values)) 0L else sum(weight_values < 0 | !is.finite(weight_values)),
    invalid_status = length(found$problems$status),
    invalid_times = length(found$problems$times) + sum(data_survival_invalid_times(times)),
    providers_without_events = index$levels[events == 0],
    providers_without_person_time = index$levels[person_time <= 0],
    aliased = check_aliased_within(design, index$codes),
    large_mean = check_large_means(design),
    large_mean_ratio = large_mean_ratio
  ))
}

# The rows whose times survival's aeqSurv() would change: times closer than its tolerance, which
# coxph() merges by default (timefix = TRUE; M-23).
check_near_tied_rows <- function(response) {
  merged <- unclass(survival::aeqSurv(response))
  original <- unclass(response)
  times <- seq_len(ncol(original) - 1L)
  sum(rowSums(merged[, times, drop = FALSE] != original[, times, drop = FALSE]) > 0)
}

# The covariates linearly dependent on the others once each is centered within providers, by QR
# with pivoting as the logistic fixed-effect fit's check (D-38): what a model stratified by
# provider cannot estimate.
check_aliased_within <- function(design, codes) {
  if (ncol(design) == 0L) return(character())
  within <- design
  dimnames(within) <- NULL
  for (j in seq_len(ncol(design))) within[, j] <- design[, j] - stats::ave(design[, j], codes)
  decomposition <- qr(within)
  if (decomposition$rank == ncol(design)) return(character())
  colnames(design)[decomposition$pivot[(decomposition$rank + 1L):ncol(design)]]
}

# The covariates whose mean exceeds `ratio` standard deviations in absolute value (DEC-104).
check_large_means <- function(design, ratio = large_mean_ratio) {
  if (ncol(design) == 0L || nrow(design) < 2L) return(character())
  means <- colMeans(design)
  deviations <- apply(design, 2L, stats::sd)
  colnames(design)[deviations > 0 & abs(means) > ratio * deviations]
}
