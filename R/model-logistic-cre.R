# Logistic correlated random-effect models (ARCHITECTURE §B.2, §D): the fit function. The
# within-between decomposition is the data layer's (data-decompose.R); the lme4 adapter, the
# model object, and the methods are shared with the other mixed families (model-mixed.R).

#' Fit a logistic correlated random-effect model for provider profiling
#'
#' Fits the logistic random-effect model of [fit_logistic_re()] after splitting each
#' covariate in `within_between` into its provider mean (`<name>_bar`) and its deviation
#' from that mean (`<name>_within`), as [fit_linear_cre()] does. The model formula is
#' `outcome ~ <name>_within + <name>_bar + <other covariates> + (1 | provider)`.
#'
#' As in pprof 1.0.3, the provider means are computed over every row of `data` before rows
#' with missing values are dropped, the provider variance is the `vcov` column of lme4's
#' variance components, and the standard deviations of the provider effects are lme4's
#' conditional standard deviations.
#'
#' @inheritParams fit_linear_cre
#' @param formula A two-sided formula: the binary outcome (0 and 1, or `FALSE` and `TRUE`)
#'   on the left and the covariates on the right, including those of `within_between`,
#'   without random-effect terms.
#' @param ... Arguments passed to the lme4 fit, such as `control`.
#'
#' @return A model object of class `c("pprof_logistic_cre", "pprof_mixed", "pprof_model")`
#'   with the fields of [fit_logistic_re()] models; `spec$within_between` records the split
#'   covariates.
#'
#' @inheritSection fit_logistic_fe Provider order
#' @family fitting functions
#' @examples
#' data(ExampleDataBinary)
#' example <- data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID,
#'                       ExampleDataBinary$Z)
#' example <- example[example$hospital <= 20, ]
#' fit <- fit_logistic_cre(y ~ z1 + z2 + z3 + z4 + z5, example, provider = "hospital",
#'                         within_between = c("z1", "z2"))
#' fit$coefficients
#' @export
fit_logistic_cre <- function(formula, data, provider, within_between, keep_data = FALSE, verbose = FALSE, ...) {
  if (missing(within_between)) {
    abort_invalid_input("`within_between` must name the covariates to split.", arg = "within_between")
  }
  mixed_fit("logistic_cre", match.call(), formula, data, provider, within_between, keep_data, verbose, ...)
}
