# The package's help page, ?pprof, and the package's directives (ARCHITECTURE §B.2's shared
# file): the compiled code's registration, and Rcpp imported so that its namespace is loaded for
# the compiled code (the reference kept these in R/pprof.R, with a dummy function that only
# made globals look used, DEC-015, DEC-073).

#' pprof: Modeling, Standardization and Testing for Provider Profiling
#'
#' pprof fits risk-adjusted models with an effect for each provider (a hospital, a dialysis
#' facility, a transplant center, a school) and profiles the providers: it tests each
#' provider's effect and flags the providers whose outcomes are higher or lower than
#' expected, computes indirectly and directly standardized measures with their intervals,
#' and draws funnel, caterpillar, flag, and volume plots.
#'
#' @section Fitting:
#' For binary outcomes, [fit_logistic_fe()] fits a fixed effect for each provider with the
#' SerBIN or BAN algorithm, [fit_logistic_firth()] adds Firth's bias-reducing penalty,
#' [fit_logistic_re()] fits random effects, and [fit_logistic_cre()] correlated random
#' effects. For continuous outcomes, [fit_linear_fe()], [fit_linear_re()], and
#' [fit_linear_cre()] fit the corresponding linear models. Every fit takes a formula, a data
#' frame, and the name of the provider column. Before fitting, [check_data()] reports missing
#' values, covariates with little or no variation, highly correlated covariates, and variance
#' inflation factors.
#'
#' @section Profiling providers:
#' [test_providers()] tests and flags providers, [standardize_providers()] computes
#' standardized measures with optional intervals, [provider_effects()] gives the provider
#' effects with optional intervals, [funnel_limits()] computes the control limits of a
#' funnel plot, and [profile_providers()] runs all of these at once. For the covariates,
#' [summary()][summary.pprof_model()], [confint()][confint.pprof_model()], and
#' [test_coefficients()] give tests and intervals of the coefficients.
#'
#' @section Plots:
#' [plot_funnel()], [plot_caterpillar()], [plot_flags()], and [plot_volume()] draw the
#' results with ggplot2 and return the plot.
#'
#' @section Vignettes:
#' `vignette("pprof", package = "pprof")` goes through an analysis,
#' `vignette("models", package = "pprof")` describes the models and what each supports,
#' `vignette("statistical-methods", package = "pprof")` gives the formulas behind the results,
#' `vignette("migration", package = "pprof")` maps the functions of pprof 1.0.3 to the new
#' ones, and `vignette("adding-a-model", package = "pprof")` shows how to add a model.
#'
#' @section The interface of pprof 1.0.3:
#' [logis_fe()], [logis_firth()], [linear_fe()], [linear_re()], [logis_re()],
#' [linear_cre()], and [logis_cre()], the `test()`, `SM_output()`, `confint()`, `summary()`,
#' and `plot()` methods of their fits, [caterpillar_plot()], [bar_plot()], and
#' [data_check()] are kept for existing code and return the objects of pprof 1.0.3. They are
#' deprecated as of pprof 2.0.0: each warns once per session.
#'
#' @references
#' Bates D, Mächler M, Bolker B, Walker S (2015). Fitting linear mixed-effects models using
#' lme4. *Journal of Statistical Software*, 67(1), 1-48. \doi{10.18637/jss.v067.i01}
#'
#' Firth D (1993). Bias reduction of maximum likelihood estimates. *Biometrika*, 80(1), 27-38.
#'
#' He K, Kalbfleisch JD, Li Y, Li Y (2013). Evaluating hospital readmission rates in dialysis
#' facilities; adjusting for hospital effects. *Lifetime Data Analysis*, 19, 490-512.
#' \doi{10.1007/s10985-013-9264-6}
#'
#' He K (2019). Indirect and direct standardization for evaluating transplant centers.
#' *Journal of Hospital Administration*, 8(1), 9-14.
#'
#' Hsiao C (2022). *Analysis of Panel Data*. Cambridge University Press.
#'
#' Wu W, Kuriakose JP, Weng W, Burney RE, He K (2023). Test-specific funnel plots for
#' healthcare provider profiling leveraging individual- and summary-level information.
#' *Health Services and Outcomes Research Methodology*, 23(1), 45-58.
#'
#' Wu W, Yang Y, Kang J, He K (2022). Improving large-scale estimation and inference for
#' profiling health care providers. *Statistics in Medicine*, 41(15), 2840-2853.
#' \doi{10.1002/sim.9387}
#'
#' @useDynLib pprof, .registration = TRUE
#' @importFrom Rcpp sourceCpp
#' @importFrom stats plogis
"_PACKAGE"
