# summary() of models (ARCHITECTURE §D.3).

#' Summary of a model
#'
#' The covariate coefficients with their Wald tests and intervals (see
#' [test_coefficients()]), and the model's dimensions, fit statistics, and convergence.
#' The p-values are numbers; printing formats them as pprof 1.0.3's `summary()` does
#' (`format.pval()` with 7 digits and eps = 1e-10).
#'
#' @param object A model object.
#' @param level The confidence level of the coefficient intervals.
#' @param ... Not used.
#'
#' @return A `pprof_summary` result: a `table` with one row per coefficient (`term`,
#'   `estimate`, `std_error`, `statistic`, `p_value`, `lower`, `upper`), `level`, the
#'   model's `family` and `method`, and `fit`, a one-row data frame of [glance()].
#' @examples
#' data(ExampleDataBinary)
#' example <- data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID,
#'                       ExampleDataBinary$Z)
#' fit <- fit_logistic_fe(y ~ z1 + z2 + z3 + z4 + z5, example, provider = "hospital")
#' summary(fit)
#' @export
summary.pprof_model <- function(object, level = 0.95, ...) {
  table <- test_coefficients(object, "wald", level = level)$table
  new_pprof_summary(table, level = level, family = object$spec$family, method = object$spec$method,
                    fit = as.data.frame(glance(object)))
}
