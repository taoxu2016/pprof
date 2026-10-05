# Linear correlated random-effect models (ARCHITECTURE §B.2, §D): the fit function. The
# within-between decomposition is the data layer's (data-decompose.R); the lme4 adapter, the
# model object, and the methods are shared with the other mixed families (model-mixed.R).

#' Fit a linear correlated random-effect model for provider profiling
#'
#' Fits the linear random-effect model of [fit_linear_re()] after splitting each covariate
#' in `within_between` into its provider mean (`<name>_bar`) and its deviation from that
#' mean (`<name>_within`), so that the covariate's within-provider and between-provider
#' associations have their own coefficients and the provider effects are not confounded
#' with the covariate's provider means (the Mundlak device). The model formula is
#' `outcome ~ <name>_within + <name>_bar + <other covariates> + (1 | provider)`.
#'
#' As in pprof 1.0.3, the provider means are computed over every row of `data`, with
#' missing values of the covariate removed, before rows with missing values are dropped, and
#' the standard deviations of the provider effects are lme4's conditional standard
#' deviations.
#'
#' @inheritParams fit_linear_re
#' @param formula A two-sided formula: the outcome on the left and the covariates on the
#'   right, including those of `within_between`, without random-effect terms.
#' @param within_between The names of covariates of `formula` to split into within-provider
#'   and between-provider parts. They must be numeric columns of `data`.
#'
#' @return A model object of class `c("pprof_linear_cre", "pprof_mixed", "pprof_model")`
#'   with the fields of [fit_linear_re()] models; `spec$within_between` records the split
#'   covariates.
#'
#' @inheritSection fit_logistic_fe Provider order
#' @family fitting functions
#' @examples
#' data(ExampleDataLinear)
#' example <- data.frame(y = ExampleDataLinear$Y, hospital = ExampleDataLinear$ProvID,
#'                       ExampleDataLinear$Z)
#' fit <- fit_linear_cre(y ~ z1 + z2 + z3 + z4 + z5, example, provider = "hospital",
#'                       within_between = c("z1", "z2"))
#' fit$coefficients
#' @export
fit_linear_cre <- function(formula, data, provider, within_between, keep_data = FALSE, verbose = FALSE, ...) {
  if (missing(within_between)) {
    abort_invalid_input("`within_between` must name the covariates to split.", arg = "within_between")
  }
  mixed_fit("linear_cre", match.call(), formula, data, provider, within_between, keep_data, verbose, ...)
}
