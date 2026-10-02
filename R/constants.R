# Named numerical conventions (ARCHITECTURE §K).
#
# Each constant is a value that the reference implementation (pprof 1.0.3, commit
# 5260838) uses, named here once, with its entry in the conventions register
# (dev/PROJECT_CONTEXT.md §5.7) and the reference location it reproduces. Changing a value
# changes results and is a Class B change (brief §3.3). Defaults of user-facing arguments
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

# K-90: the uniroot() defaults that the reference relies on, passed explicitly by the
# rewrite so that the root-finder settings are visible.
root_tolerance <- .Machine$double.eps^0.25
root_max_iter <- 1000L

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
# rate_scale * sum(y) / n, and rates are clipped to rate_limits.
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
