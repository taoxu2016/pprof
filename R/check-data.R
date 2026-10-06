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
#' @param formula A two-sided formula with the outcome on the left and the covariates on the
#'   right, as the fitting functions take it.
#' @param data A data frame with the variables of `formula` and the provider column.
#' @param provider The name of the provider column of `data`.
#'
#' @return A `pprof_data_check` result: a list whose `table` has one row for each variable of
#'   `formula` and for the provider, with `variable`, `role` (`"outcome"`, `"covariate"`, or
#'   `"provider"`), `n_missing`, and `percent_missing`; `n_obs` and `n_complete`, the numbers of
#'   observations and of complete observations; `design`, one row for each covariate column,
#'   with `term`, `frequency_ratio`, `percent_unique`, `zero_variance`, `near_zero_variance`,
#'   and `vif` (missing for a column without variation); `correlations`, the pairs of columns
#'   correlated above the threshold, with `term_1`, `term_2`, and `correlation`; and the
#'   thresholds used (`frequency_ratio_cut`, `percent_unique_cut`, `correlation_threshold`,
#'   `vif_threshold`). Printing it lists the problems found.
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
#' @export
check_data <- function(formula, data, provider) {
  check_formula(formula)
  check_data_frame(data)
  check_string(provider, "provider")
  check_column(data, provider, "provider")
  variables <- all.vars(formula)
  outcome <- all.vars(formula[[2L]])
  missing_columns <- setdiff(variables, names(data))
  if (length(missing_columns) > 0L) {
    abort_invalid_input(sprintf("`data` has no columns named %s.", paste(missing_columns, collapse = ", ")),
                        arg = "data")
  }
  variables <- unique(c(outcome, setdiff(variables, c(outcome, provider)), provider))
  role <- ifelse(variables %in% outcome, "outcome", ifelse(variables == provider, "provider", "covariate"))
  n_missing <- vapply(variables, function(v) sum(is.na(data[[v]])), integer(1L), USE.NAMES = FALSE)
  table <- data.frame(variable = variables, role = role, n_missing = n_missing,
                      percent_missing = 100 * n_missing / nrow(data))
  complete <- stats::complete.cases(data[variables])

  design <- data_prepare(formula, data, provider)$design
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
  new_pprof_data_check(
    table, n_obs = nrow(data), n_complete = sum(complete), design = design_table,
    correlations = check_correlations(design[, varies, drop = FALSE]),
    frequency_ratio_cut = near_zero_frequency_ratio, percent_unique_cut = near_zero_percent_unique,
    correlation_threshold = correlation_threshold, vif_threshold = vif_threshold
  )
}
