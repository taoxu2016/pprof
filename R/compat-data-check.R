# The data check of pprof 1.0.3 (R/data_check.R there), over the computations of check_data()
# (R/check-data.R, DEC-073): it builds the data as pprof 1.0.3 did and gives its messages,
# warnings, and errors in the same order, including the stop on any missing value (D-17).
# With one covariate, where pprof 1.0.3 failed in cor() (D-52), it completes the checks.

#' Data quality check function
#'
#' Conduct data quality check including checking missingness, variation, correlation and VIF of variables.
#' This is the interface of pprof 1.0.3, kept for existing code; [check_data()] is the new
#' interface, which reports instead of stopping. It is deprecated as of pprof 2.0.0 and warns
#' once per session; see `vignette("migration", package = "pprof")`.
#'
#' @param Y a numeric vector indicating the outcome variable.
#' @param Z a matrix or data frame representing covariates.
#' @param ProvID a numeric vector representing the provider identifier.
#'
#' @details The function performs the following checks:
#'   \itemize{
#'     \item \strong{Missingness:} Checks for any missing values in the dataset and provides a summary of
#'       missing data.
#'     \item \strong{Variation:} Identifies covariates with zero or near-zero variance which might affect model
#'       stability.
#'     \item \strong{Correlation:} Analyzes pairwise correlation among covariates and highlights highly
#'       correlated pairs.
#'     \item \strong{VIF:} Computes the Variable Inflation Factors to identify covariates with potential
#'       multicollinearity issues.
#'   }
#' If issues arise when using the model functions \code{logis_fe}, \code{linear_fe} and \code{linear_re},
#' this function can be called for data quality checking purposes.
#'
#' When any value of `Y`, `Z`, or `ProvID` is missing, the function warns for each variable with missing values
#' and then stops with an error that gives the percentage of incomplete observations, so the other checks run only
#' on complete data. The fitting functions do not stop: they drop the incomplete observations.
#'
#' @return No return value, called for side effects.
#'
#' @examples
#' data(ExampleDataBinary)
#' outcome = ExampleDataBinary$Y
#' covar = ExampleDataBinary$Z
#' ProvID = ExampleDataBinary$ProvID
#' data_check(outcome, covar, ProvID)
#'
#' @export
data_check <- function(Y, Z, ProvID) { # nolint: object_name_linter.
  compat_deprecate("data_check")
  data <- as.data.frame(cbind(Y, ProvID, Z))
  response_name <- colnames(data)[1L]
  provider_name <- colnames(data)[2L]
  covariate_names <- colnames(Z)
  checked <- c(response_name, covariate_names, provider_name)

  message("Checking missingness of variables ... ")
  complete <- stats::complete.cases(data[, checked])
  if (sum(complete) == NROW(data)) {
    message("Missing values NOT found. Checking missingness of variables completed!")
  } else {
    for (name in checked) {
      n_missing <- sum(is.na(data[, name]))
      if (n_missing > 0L) {
        warning(n_missing, " out of ", NROW(data[, name]), " in '", name, "' missing!",
                immediate. = TRUE, call. = FALSE)
      }
    }
    missingness <- (1 - sum(complete) / NROW(data)) * 100
    abort_data(paste0(round(missingness, 2), "% of all observations are missing!"))
  }

  message("Checking variation in covariates ... ")
  variation <- check_near_zero(data[, covariate_names, drop = FALSE])
  if (any(variation$zeroVar)) {
    abort_data(paste0("Covariate(s) '", paste(rownames(variation)[variation$zeroVar], collapse = "', '"),
                      "' with zero variance(s)!"))
  } else if (any(variation$nzv)) {
    warning("Covariate(s) '", paste(rownames(variation)[variation$nzv], collapse = "', '"),
            "' with near zero variance(s)!", immediate. = TRUE, call. = FALSE)
  }
  message("Checking variation in covariates completed!")

  message("Checking pairwise correlation among covariates ... ")
  pairs <- check_correlations(data[, covariate_names, drop = FALSE])
  if (nrow(pairs) > 0L) {
    warning("The following ", nrow(pairs), " pair(s) of covariates are highly correlated (correlation > ",
            correlation_threshold, "): ", immediate. = TRUE, call. = FALSE)
    for (k in seq_len(nrow(pairs))) message('("', pairs$term_1[k], '", "', pairs$term_2[k], '")')
  }
  message("Checking pairwise correlation among covariates completed!")

  message("Checking VIF of covariates ... ")
  model <- stats::lm(stats::as.formula(paste(response_name, "~", paste(covariate_names, collapse = "+"))), data = data)
  vif <- check_vif(as.data.frame(stats::model.matrix(model))[, -1L, drop = FALSE])
  if (any(vif$VIF >= vif_threshold)) {
    warning("Covariate(s) '", paste(vif$Variables[vif$VIF >= vif_threshold], collapse = "', '"),
            "' with serious multicollinearity!", immediate. = TRUE, call. = FALSE)
  }
  message("Checking VIF of covariates completed!")
}
