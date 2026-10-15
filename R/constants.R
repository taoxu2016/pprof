# Named numerical conventions (ARCHITECTURE §K).
#
# Each constant is a value that the reference implementation (pprof 1.0.3, commit
# 5260838) uses, named here once, with its entry in the conventions register
# (dev/CONVENTIONS.md) and the reference location it reproduces. Changing a value
# changes results and is a Class B change (dev/DISCREPANCIES.md). Defaults of user-facing arguments
# live in the function signatures instead (NAMING.md §4). The C++ conventions get their
# own header with the C++ core (DEC-025).

# K-62, K-64, K-65, K-102: null probabilities are clamped to
# [probability_clamp, 1 - probability_clamp] before the exact, bootstrap, and modified score
# provider tests and the covariate score test.
# Reference: R/test.logis_fe.R:104, :182, :214; R/summary.logis_fe.R:182.
probability_clamp <- 1e-10

# K-90: interval limits for provider effects are found with uniroot() at its default
# settings, searching the brackets estimate + root_bracket_width * c(k, k + 1) (upper limit)
# and estimate - root_bracket_width * c(k + 1, k) (lower limit) for
# k = 0, ..., root_bracket_attempts - 1; a limit with no bracketed root is +Inf or -Inf.
# Reference: R/confint.logis_fe.R:125-147 (score test), :230-252 (exact test).
root_bracket_width <- 5
root_bracket_attempts <- 3L

# K-90: for providers with no events or all events, the single finite limit is searched in
# (extreme_bracket_base + max(abs(linear predictor))) * c(-k, k) for
# k = 1, ..., root_bracket_attempts (the reference computes the maximum as
# norm(Z.beta, "I")).
# Reference: R/confint.logis_fe.R:165-176, :191-201 (score test), :267-279, :289-301 (exact
# test).
extreme_bracket_base <- 10

# K-90: in the score interval of a provider with only events, observation weights p(1 - p)
# that are exactly 0 are replaced by score_weight_floor.
# Reference: R/confint.logis_fe.R:187, in the score interval's equation.
score_weight_floor <- 1e-20

# K-90: the uniroot() defaults that the reference relies on, passed explicitly by the
# rewrite so that the root-finder settings are visible.
root_tolerance <- .Machine$double.eps^0.25
root_max_iter <- 1000L

# DEC-005: data passed to a method that needs the covariates must be the data of the fit.
# The rebuilt design times the coefficients must equal the stored linear predictor within
# |a - b| <= data_match_atol + data_match_rtol * |b|, the closed-form tolerance of the
# equivalence tests (ARCHITECTURE §G.4), which allows for a different BLAS.
data_match_atol <- 1e-12
data_match_rtol <- 1e-10

# K-100, K-103 to K-105: covariate p-values in summaries are formatted with
# format.pval(p, digits = p_value_display_digits, eps = p_value_display_eps).
# Reference: R/summary.logis_fe.R:95 and the corresponding lines of the other summary
# methods.
p_value_display_digits <- 7L
p_value_display_eps <- 1e-10

# K-101: the covariate likelihood-ratio test clamps provider effects to
# median(effects) +/- lr_effect_clamp in both log-likelihoods.
# Reference: R/summary.logis_fe.R:138, :149.
lr_effect_clamp <- 10

# K-80 to K-82, K-91: standardized rates are percentages: the population rate is
# sum(y) / n * rate_scale, computed in that order, and rates are clipped to rate_limits.
# Reference: R/SM_output.logis_fe.R:101-102, :133-134.
rate_scale <- 100
rate_limits <- c(0, 100)

# K-120: data checks use the defaults of caret::nearZeroVar() (frequency ratio cut 95/5,
# percent of unique values cut 10), flag absolute correlations above correlation_threshold,
# and flag variance inflation factors of at least vif_threshold.
# Reference: R/data_check.R:57, :70, :87.
near_zero_frequency_ratio <- 95 / 5
near_zero_percent_unique <- 10
correlation_threshold <- 0.9
vif_threshold <- 10

# DEC-104 (CoxPH Phase C2): for survival data, check_data() reports covariates whose mean exceeds
# large_mean_ratio standard deviations in absolute value, such as a calendar year, which survival's
# fits center and pprof_py's other outputs do not (D-64). A diagnostic of the package's own; no
# result depends on it. No reference: pprof_py's preflight report has no such check.
large_mean_ratio <- 100

# The Poisson tests of Cox models (CoxPH Phase C3; R/inference-poisson.R). Reference: pprof_py v0.7.0,
# commit 9320766.

# K-141: the mid-p test floors the smaller one-sided mid-p probability at midp_probability_floor
# before turning it into a z-statistic, so |z| <= 4.7534 and the p-value is at least 2e-6.
# Reference: pprof_py/inference/survival/empirical_null.py:205 (poisson_midp_zscore()).
midp_probability_floor <- 1e-6

# K-140: the exact test's two-sided p-value is capped at exact_poisson_cap, and its limits are
# Garwood's (chi-square) when the expected count is below byar_expected_threshold and Byar's
# otherwise.
# Reference: pprof_py/inference/survival/inference.py:64-66, :127-133 (poisson_exact_test()).
exact_poisson_cap <- 0.999
byar_expected_threshold <- 100

# K-141: pprof_py's bracket of the mid-p limits in the Poisson mean, whose ends decide where a limit
# is 0 or Inf: from midp_bracket_low * max(E, 1) to midp_bracket_scale * (O + E + midp_bracket_scale),
# the upper end multiplied by midp_bracket_scale while the statistic there exceeds
# max(null mean, midp_bracket_threshold) and the end is below midp_bracket_max.
# Reference: pprof_py/inference/survival/provider_tests.py:43-45 (_midp_limits()).
midp_bracket_low <- 1e-10
midp_bracket_scale <- 10
midp_bracket_threshold <- -4.75
midp_bracket_max <- 1e12

# K-149: the funnel limits of a Poisson count search the counts 0 to
# ceiling(E + funnel_count_spread * sqrt(E) + funnel_count_margin) and lie funnel_count_offset from
# the boundary counts, (o_lo + 1/2) / E and (o_hi - 1/2) / E.
# Reference: pprof_py/inference/funnel.py (_poisson_nmax(), _ratio_limits()).
funnel_count_spread <- 40
funnel_count_margin <- 50
funnel_count_offset <- 0.5

# The elastic-net Cox model (CoxPH Phase C4; R/model-cox-penalized.R, R/model-glmnet.R). Reference:
# pprof_py v0.7.0, commit 9320766.

# K-143: a column whose weighted population variance (the weights normalized to sum to 1) is below
# penalized_degenerate_variance, in the column's units, is degenerate: left out of the penalized path,
# with coefficient 0. The value is pprof_py's 10 machine epsilons, which follows glmnet's safeguard.
# Reference: pprof_py/algorithms/survival/penalty.py:112 (weighted_column_scale()).
penalized_degenerate_variance <- 10 * .Machine$double.eps

# K-143: lambda_max is divided by max(alpha, penalized_alpha_floor), so that a ridge path (alpha = 0)
# starts at a finite lambda, as glmnet's own grid does.
# Reference: pprof_py/algorithms/survival/coordinate_descent.py:397 (compute_lambda_max()).
penalized_alpha_floor <- 1e-3

# K-143: without lambda_min_ratio, the grid ends at lambda_max times penalized_ratio_wide when there are
# fewer observations than kept covariates, and times penalized_ratio_long otherwise.
# Reference: pprof_py/models/survival/penalized_coxph.py:105 (_resolve_lambda_path()).
penalized_ratio_wide <- 1e-2
penalized_ratio_long <- 1e-4

# K-143: the unpenalized coefficients of the null point (penalty factor 0) are fitted with
# penalized_null_tol and penalized_null_max_iter, pprof_py's outer_tol and max_outer_iter, which its
# CoxPH fit of those columns uses as eps and max_iter; lambda_max depends on where that fit stops
# (dev/design/coxph-facts/26: 1e-15 from pprof_py's at these settings, 1.5e-11 at eps 1e-12).
# Reference: pprof_py/models/survival/penalized_coxph.py:328-340 (_compute_null_point()).
penalized_null_tol <- 1e-9
penalized_null_max_iter <- 100L

# DEC-115, D-78: a grid point whose glmnet deviance ratio is below penalized_deviance_ratio_floor has a
# deviance above the null deviance, which no solution of the penalized problem has (the null point is
# feasible), so glmnet's path ends before it. The floor is rounding level below 0; glmnet's paths reach
# a deviance ratio of exactly 0 at their first point. A check of the package's own; no reference:
# pprof_py's solver converges where glmnet 5.1 diverges (dev/design/coxph-facts/26, part C).
penalized_deviance_ratio_floor <- -sqrt(.Machine$double.eps)

# K-145, DEC-122: the Fine-Gray transform calls survival's finegray() once per chunk of
# fine_gray_chunk_providers providers, each chunk deciding delayed entry as all rows do, whose output
# is the stratified call's bitwise; finegray()'s own steps go over all its rows once per stratum, so one
# call's time grows with rows times providers. A cost setting, not a number of the model: on the
# benchmark's data chunks of 50 took 3 to 14 times less time than one call
# (dev/design/coxph-facts/35_finegray_chunks.txt). No reference: pprof_py's transform is its own.
fine_gray_chunk_providers <- 50L
