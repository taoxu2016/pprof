# Logistic extensions design (Phase L0)

> **Status: the Phase L0 deliverable of `dev/logistic_brief.md` (§9), 2026-10-20, at its gate.** Its decisions are the project lead's approval of the brief's recommendations (DEC-143, DEC-144; M-42 to M-65) and, where the brief made none, decisions under that approval ("If no recommendations, please use your best judgement"), DEC-145 to DEC-155. Phases L1 to L5 implement them; each part gets an "As built" note when it is built.

This document says how the features of pprofR 0.2.0 (commit `f23c288`) enter pprof:

- §A, what pprofR does;
- §B, the interface;
- §C, the data layer;
- §D, the contract and the profiling hooks;
- §E, the engines;
- §F, the algorithms and their cost;
- §G, validation;
- §H, dependencies;
- §I, benchmarks;
- §J, the register entries;
- §K, what each phase builds.

**Evidence** comes from the scripts and outputs in `dev/design/logistic-facts/` (cited by number) and from pprofR's code at `f23c288` (cited as `R/<file>:<lines>` and `src/Fixed_effect.cpp:<lines>`, pprofR's paths). Nothing of pprofR's files is copied here or anywhere in the repository, and its documentation is not quoted (CLAUDE.md).

**Notation.** Row j of provider i has y_ij events out of n_ij trials (n = 1 for binary outcomes), covariates z_ij, and linear predictor η_ij = z_ij'β; p_ij = expit(γ_i + η_ij) at the fit, p0_ij = expit(γ0 + η_ij) at the null γ0; r = y − n p and v = n p(1 − p); m providers, rows (observations), and p covariates. Clusters k are (provider, cluster label) pairs.

## A. What pprofR does: behavior specifications

### A.1 Data preparation (`fe_data_prep()`, `R/fe_data_prep.R:34-105`)

- **Inputs.** `N` (the trials; when missing, 1 for every row, with a message), `Y`, `Z` (columns must be named), `ProvID`, `PatientID` (optional, the clusters), `cutoff = 10`, `check = TRUE`, `message = TRUE`. The lengths must match, or it stops.
- **Sorting.** By `factor()` of the provider (K-05's order) and, with `PatientID`, by `factor()` of the cluster label within provider. A cluster's rows are then contiguous and keep their input order (the sort is stable).
- **Screening.** A provider is included when its size is at least `cutoff`; the size is its number of distinct cluster labels with `PatientID`, and its number of rows without. With `message = TRUE` a warning counts the providers below `cutoff`.
- **Indicators**, among included providers: no events when Σy = 0, all events when Σ(n − y) = 0.
- **Checks.** With `check = TRUE`, `data_check()`'s checks (§A.11), whose missing values stop. No check that 0 ≤ y ≤ n, that n is a non-negative integer, or that y is an integer (B1, fact 08); with `check = FALSE` a missing value reaches the solver, which fails (B2).

### A.2 The fit (`logis_fe()`, `R/logis_fe.R:57-130`; `src/Fixed_effect.cpp:109-307`)

- **Settings.** `algorithm` `"SerBIN"` (default) or `"BAN"`; `max.iter = 10000`; `tol = 1e-5`; `bound = 10`; `backtrack = TRUE`; `threads = 1`; `AUC = FALSE`; `message = FALSE`; `stop = "beta"` (default), `"relch"`, `"ratch"`, `"all"`, or `"or"`.
- **Start.** γ_i = logit(Σy / Σn) over the included rows, β = 0.
- **SerBIN and BAN** are pprof's (K-12 to K-17) with y − p replaced by y − n p and p(1 − p) by n p(1 − p), and the log-likelihood ℓ = Σ[(γ_i + η) y − n log(1 + exp(γ_i + η))], without the constant Σ log C(n, y). One difference: SerBIN's cross block uses the floored weights (K-12 uses them unfloored), which matters only where n p(1 − p) is 0 in double. The log-likelihood is evaluated only when the stopping rule needs it, which leaves the path unchanged. With one trial per row every fit of fact 02 is pprof's bitwise: 3 data sets, 2 methods, 2 stopping rules, 2 tolerances.
- **Outputs.** `beta`, `gamma` (named by provider), `linear_pred` (Zβ), `pred` (p), `neg2Loglkd`, AIC = −2ℓ + 2(m + p), BIC = −2ℓ + log(rows)(m + p), `obs`, `prov`, `df.prov`, `char_list`, `data_include`, `control` (with `iter`); `AUC` for binary outcomes only, missing with a warning otherwise (fact 08).
- **Against `glm()`** with `cbind(y, n - y)` and provider indicators: estimates within 8e-15, variances within 4e-9 (fact 03).

### A.3 Variances (`vcov.logis_fe()`, `R/logis_fe.R:168-180`; `src/Fixed_effect.cpp:311-338`)

K-20 with the trials: p clamped to [1e-10, 1 − 1e-10], weights n p(1 − p), the provider diagonal as their sum, the cross and covariate blocks, `inv_sympd()` of the Schur complement for Var(β), and Var(γ_i) = 1/D_i + J_i'S⁻¹J_i. The provider variances come as the attribute `var.gamma`.

### A.4 Provider tests (`test_fe()`, `R/test_fe.R:71-234`)

- **Null.** `"median"`, the median of γ̂, or the first element of a number.
- **`"exact.poisbinom"`** (default): each provider's events against the Poisson-binomial distribution of its individual trials, row j contributing n_ij trials of probability p0_ij, not clamped, with K-62's tails: the two-sided mid-p upper tail, the one-sided tails, and the statistic `qnorm()` of the tail.
- **`"exact.bootstrap"`**: K-64's layout with binomial draws: for each provider in provider order, `rbinom(n = rows × n, size = the rows' trials repeated n times, prob = p0 repeated)`, columns summed, tails as K-64. A size of 1 written as a vector draws as the number does (fact 09).
- **`"score"`**: z = Σ(y − n p0) / sqrt(Σ n p0(1 − p0)), p0 not clamped (fact 09).
- **`"wald"`**: z = (γ̂_i − γ0)/se with se from its own routine (`src/Fixed_effect.cpp:347-385`): the fitted p unclamped, the weights n p(1 − p) floored at 1e-20, and one solve of the Schur system per provider. It agrees with the block inverse at clamped or unclamped probabilities to 1 unit in the last place on ordinary data (fact 09).
- **p-values and flags**: from the upper tail 1 − Φ(z) as K-63 (`R/utils.R:25-46`).
- **Removed:** the standard score test; `score_modified = FALSE` raises an error.
- **Output:** a data frame with row names the providers, `flag` (a factor), `p`, `stat`, and `se.gamma` for Wald tests, and the attribute `"provider size"`.

### A.5 Cluster-level tests (`test_fe()`, `summary_fe_covar()`; `R/utils.R:52-95`; `src/Fixed_effect.cpp:390-413`, `452-511`, `612-694`)

- **Clusters** are (provider, cluster label) pairs, numbered in order of first appearance in the sorted data (`R/utils.R:52-58`). A label shared by two providers is two clusters (fact 04).
- **Residuals and variances**: r = y − n p and v = n p(1 − p), at the fit's p for the Wald tests and at p0 for the score tests, unclamped.
- **Robust Wald of γ_i**: se = sqrt(V_i)/I_i, with V_i = Σ_{k∈i}(Σ_{j∈k} r_j)², the cluster sums accumulated in long double in row order, and I_i = Σ_{j∈i} v_j with exact zeros floored at 1e-20. This sandwich treats β as known: 0.97 to 1.02 times the full sandwich's standard error on fact 04's data.
- **Robust score**: z = U_i / sqrt(V_i), U_i = Σ_{j∈i} r_j, at p0.
- **Stabilized**: one matrix R̂ pooled over every cluster of every provider by the position of a row in its cluster, entry (s, t) the average of e_s e_t, e = r / sqrt(v), over the clusters with at least max(s, t) rows; rows with v = 0 get a = e = 0 and still count in the averages; W_k = a_k'R̂a_k with a_k the sqrt(v) of cluster k's rows; V_i = Σ_{k∈i} W_k. The stabilized Wald se is sqrt(V_i)/I_i at the fit, the stabilized score z = U_i / sqrt(V_i) at p0. R̂ need not be positive semi-definite, so V_i can be negative: the statistic is then NaN, which becomes missing, after R's own warning (fact 09). The largest cluster may have 5,000 rows; beyond, an error.
- **Every provider enters** R̂ and the meats; `parm` selects the output only.
- **Statistics that are not finite** become missing, with missing p-values and flags.
- **One cluster per provider**: V_i = U_i² and U_i = 0 at the fit up to its convergence error, so robust Wald statistics are of order 1e15 and robust score statistics ±1 (B3; facts 08, 09); the stabilized statistics stay finite or become missing.
- **Robust coefficients** (`summary_fe_covar(test = "robust_wald")`): the bread from the information blocks at clamped probabilities, the meat from the clusters' sums of r and of z r, assembled as J₂ diag(A₀) J₂' − 2 J₂ A₁ S⁻¹ + S⁻¹ A₂ S⁻¹ (`src/Fixed_effect.cpp:456-500`), whose two cross terms are not symmetrized (B5); its diagonal is the sandwich's, equal to `sandwich::vcovCL(type = "HC0", cadjust = FALSE)` with clusters of (provider, label) pairs to 2e-10 (fact 04). The test uses p = 2 min(Φ(z), 1 − Φ(z)) and the interval β ∓ Φ⁻¹(1 − α/2) se.
- **Screening** counts clusters when `PatientID` is given (fact 04: 27 of 60 providers kept at `cutoff = 10`, 54 counting rows).
- **Dependence on row order**: only the stabilized tests depend on the order of a cluster's rows (up to 1% in fact 04).

### A.6 Intervals (`confint.logis_fe()`, `R/confint.logis_fe.R:37-229`)

- **Choices.** `test`: `"exact"` (default), `"score"`, `"wald"`, `"robust_wald"`; `option`: `"SM"` (default) or `"gamma"`, the latter two-sided only.
- **Wald.** γ̂ ∓ Φ⁻¹(1 − α/2) se, se from `vcov()`'s `var.gamma` (clamped, A.3) or the robust Wald's; one-sided with Φ⁻¹(1 − α) and an infinite limit.
- **Exact and score.** Per provider, `find_root()` (`:217-229`) in [γ̂ − s, γ̂] and [γ̂, γ̂ + s], s = 10 + max|η| over the provider's rows, widened by s up to five times, `uniroot(tol = 1e-8)`; the exact equations over the trials; the score equations with n. A provider with no events gets (−∞, U] solving exp(Σ n log(1 − p))/2 = α (exact) or Φ⁻¹(1 − α) − Σ n p / sqrt(Σ n p(1 − p)) = 0 (score) in [−s, s]; one with all events [L, ∞) with exp(Σ n log p)/2 = α or Σ n(1 − p)/sqrt(max(Σ n p(1 − p), 1e-20)) − Φ⁻¹(1 − α) = 0.
- **Measure limits.** Indirect: Σ n expit(limit + η)/E_i, an infinite limit giving Σn or 0; no events lower 0; all events upper Σ_i n / E_i; `"less"` lower 0; `"greater"` upper Σ_i n / E_i. Direct: the direct expectation at the limits over ΣO, the same rules with Σn over all rows.
- **Rates**: the ratios times ΣO / `N_pop`, clipped to [0, 1].
- With pprof's root finder on the same equations the limits move by up to 2.7e-5 (exact) and 1.8e-6 (score) (fact 09).

### A.7 Standardized measures (`SR_output()`, `direct_exp()`; `R/SR_output.R:43-151`)

- **Indirect.** E_i = Σ n p0, null variance Σ n p0(1 − p0), ratio O_i/E_i, rate = ratio × ΣO / `N_pop` clipped to [0, 1].
- **Direct.** E_i = Σ_k w_k expit(γ̂_i + η_k) over the fit's rows with w = n, by the algorithm of §A.8, which also gives V_i = Σ_k w_k p_ik(1 − p_ik); ratio E_i / ΣO; rate as above.
- **`N_pop`**, the rates' denominator, Σn by default.
- **`se = TRUE`** returns V_i as `numer_se`, with `N_pop` and the rate times `N_pop`; the standard error of the direct rate is V_i / `N_pop` × se(γ̂_i), with the standard error the caller chooses (fact 07: equal to the central difference of the rate to 3e-11).
- **Supplied effects**: replacing the fit's `gamma` by a longer matrix serves direct standardization; indirect standardization then fails, and its median null includes the supplied effects (B4, fact 07).
- **`direct_exp(gamma, Z_beta, N = 1, threads = 1)`**: the building block, a data frame of `Exp` and `Var`.

### A.8 The direct standardization algorithm (`src/Fixed_effect.cpp:532-599`)

- The rows are sorted by η with a stable sort and rows with equal η are merged, their weights summed in long double and rounded to double; without a sort when η has a missing value.
- a_u = exp(−η_u) for each distinct η, and a_max their largest.
- For each effect g, b = exp(−g); when b·a_max is finite, E = Σ_u w_u / (1 + b a_u) and V = Σ_u w_u t_u / (1 + t_u)² with t_u = b a_u; otherwise E = Σ_u w_u expit(g + η_u) and V = Σ_u w_u r_u(1 − r_u) evaluated directly; the sums in long double, rounded to double.
- The effects are split over threads; each sum is the same for any thread count.
- Against R's long-double sums: within 2e-16 and 1.1e-15 relative where pprof's double sums over rows are within 1.3e-13 and 3.7e-12; n − E for rates near 1 within 4e-6, where the double sums lose up to 19%; 27 times faster with a continuous η and more than 1,000 times with eight distinct values (fact 05).

### A.9 The test of a measure (`test_SM()`, `R/test_SM.R:43-87`)

- **Inputs**: `measure`, `se`, `ref`, `transform` (`"identity"` or `"logit"`), `location = 0`, `scale = 1`, `level = 0.95`, `crit = NULL`, `ci.location = location`, `alternative`.
- **Statistic**: z = (g(M) − g(ref)) / (g'(M) se), with g the identity or the logit and g'(M) = 1/(M(1 − M)) for the logit.
- **p-value**: F(z) = Φ((z − location)/scale); two-sided 2 min(F, 1 − F), one-sided the tail.
- **Flag**: 1 when (z − location)/scale > c, −1 when < −c (one-sided: one side), with c = Φ⁻¹(1 − α/2), or Φ⁻¹(1 − α) one-sided, or `crit`.
- **Interval**: g(M) − (`ci.location` ± c·scale) g'(M) se, mapped back with g⁻¹ (with exp() guarded above 700); one-sided intervals with an infinite side.
- At the defaults the interval excludes the reference exactly when the test flags (fact 07); a `crit` or `ci.location` of their own can break that.

### A.10 Covariate tests (`summary_fe_covar()`, `R/summary_fe_covar.R:23-128`)

- **`"wald"`**: K-20's variance with the trials (`src/Fixed_effect.cpp:421-450`), p = 2 min(Φ(z), 1 − Φ(z)) in C++ (pprof's K-100 computes 2(1 − Φ(|z|)) in R, 1e-12 relative apart, fact 02).
- **`"robust_wald"`**: §A.5.
- **`"lr"`, `"score"`**: `null` must be 0 and at least two covariates are needed; each null model is refit with the fit's own settings (pprof refits with its defaults, D-10); the LR statistic with γ clamped to the median ± 10 (K-101) and the score test as K-102, both with the trials.

### A.11 Data checks (`data_check()`, `R/data_check.R:23-124`)

pprof 1.0.3's `data_check()` (K-120) with the trials among the variables checked for missing values: missing values stop; covariates with zero variance stop and near-zero variance warn; correlations above 0.9 and variance inflation factors of 10 or more warn.

### A.12 Edges

Appendix B of the brief, B1 to B6, and from fact 09: a provider whose rows all have zero trials is fitted, with an effect near the start, a Wald standard error of order 1e9, and both indicators set (no events and all events); rows with zero trials leave the estimates unchanged up to the fit's convergence and count as rows in BIC and screening.

## B. The interface

The names follow `dev/NAMING.md`, extended in its §11 (DEC-145).

### B.1 Functions

`fit_logistic_fe(formula, data, provider, trials = NULL, cluster = NULL, method = "serbin", max_iter = 10000, tol = 1e-5, stop_rule = "any", backtrack = TRUE, effect_bound = 10, min_provider_size = 10, keep_data = FALSE, threads = 1, verbose = FALSE)`

- **`trials`**: `NULL`, one trial per row and a binary outcome, as now; or the name of a column of `data` with each row's number of trials, non-negative integers. The formula's response is then the number of events, integers from 0 to the trials. Trials that are all 1 give the binary model, identical to the fit without them (DEC-146). Rows with zero trials are kept (M-58); a provider whose rows have no trials raises `pprof_error_data` (D-100).
- **`cluster`**: `NULL`, or the name of a column of `data` (atomic or a factor) whose values label clusters of rows; clusters are (provider, label) pairs; `min_provider_size` then counts clusters (M-50); the model gains the robust and stabilized variances (§D.4).
- The two arguments follow `provider`, as `weights` and `cluster` do in `fit_cox_stratified()` (NAMING §4's order: data arguments first). Every internal call names the later arguments.
- `fit_logistic_firth()` takes neither (§2.2 of the brief).

`test_providers(model, test = NULL, null = NULL, level = 0.95, alternative = "two.sided", providers = NULL, score_type = "modified", se_type = "model", n_resamples = 10000, data = NULL, threads = 1)`

- **`se_type`**: `"model"` (the current tests), `"robust"`, or `"stabilized"`, for `test = "wald"` (the standard error of γ̂_i) and `test = "score"` with `score_type = "modified"` (the variance of the provider's score). With any other test, or the standard score test, a value other than `"model"` raises `pprof_error_invalid_input`.

`provider_effects(model, interval = "none", level = 0.95, providers = NULL, se_type = "model")`: `std_error` and the Wald intervals from the chosen standard error.

`standardize_providers(model, standardization = "indirect", measure = NULL, null = NULL, interval = "none", level = 0.95, alternative = "two.sided", providers = NULL, se_type = NULL, rate_denominator = NULL, effects = NULL, threads = 1)`

- **`se_type`**: `NULL`, as now (Wald intervals with the model-based standard error, no `std_error` column), or one of the three: the direct measures get `std_error` (§B.3) and the Wald intervals use that standard error.
- **`rate_denominator`**: `NULL`, the trials of the included rows (for binary outcomes their number, as now), or a positive number (M-44).
- **`effects`**: `NULL`, or provider effects named by provider ID, for direct standardization only (M-60): an included provider's supplied effect replaces its estimate there, and a provider excluded by screening is added to the direct rows; indirect standardization and its null use the fit's effects. IDs outside the provider table raise `pprof_error_invalid_input`.

`profile_providers(model, test = NULL, null = NULL, level = 0.95, alternative = "two.sided", interval = "none", providers = NULL, score_type = "modified", se_type = "model", n_resamples = 10000, data = NULL, threads = 1)`: passes `se_type` on to its tests and effects.

`test_coefficients(model, test = "wald", parm = NULL, level = 0.95, null = 0, se_type = "model", data = NULL)` and `confint(object, parm, level = 0.95, se_type = "model", ...)`: `se_type = "robust"` for the Wald test and intervals (no stabilized variance of the coefficients, as in pprofR).

`vcov(object, se_type = "model", ...)` of a logistic fixed-effect model: the model-based covariance, or the cluster-robust one (§F.3).

`test_measures(measures, reference = NULL, transform = "identity", null_location = 0, null_scale = 1, level = 0.95, alternative = "two.sided")`, new (DEC-145):

- tests the direct measures of a `pprof_measures` result that has standard errors (`standardize_providers(..., se_type = )`); others raise `pprof_error_invalid_input`;
- **`reference`**: `NULL` for the plots' references (NAMING §4), 1 for ratios and the population rate for rates (M-65), or a number, or one number per provider;
- **`transform`**: `"identity"` or `"logit"`, the latter for rates only, on the proportion scale (rate / 100);
- the critical value comes from `level` and the interval is centred at `null_location` (M-61): no `crit` or `ci.location`;
- returns `pprof_measure_tests` (§B.3).

`direct_expected(effects, linear_predictor, weights = NULL, threads = 1)`, new and exported (DEC-145): the building block of direct standardization over any standard population: for each effect, the expected total Σ_k w_k expit(effect + η_k) and Σ_k w_k p_k(1 − p_k), by §F.5's algorithm; `weights = NULL` is 1 for every row. Returns a data frame with `expected` and `variance`, one row per effect.

`check_data(formula, data, provider, weights = NULL, cluster = NULL, trials = NULL)`: `trials` is appended, so existing calls are unchanged, and `cluster` now applies to binary and binomial outcomes too (§C.3).

Model-contract generics, new (§D.1): `observation_trials()`, `trial_probability()`, `observation_clusters()`.

### B.2 What the model keeps

A `pprof_logistic_fe` model with trials or clusters is the same class with these additions, each present only when used, so that binary fits without them are unchanged (DEC-146):

- `trials`, each observation's trials (double), with the trials;
- `cluster`, each observation's cluster as an integer code 1..K of its (provider, label) pair, in order of first appearance among the sorted observations, with clusters;
- `robust_vcov`, the cluster-robust covariance of the coefficients (§F.3), with clusters;
- the provider table's `n_trials` (with trials) and `n_clusters` (with clusters);
- `spec$trials` and `spec$cluster`, the columns' names; `data_spec` records them for `model_prepared_data()` (DEC-005);
- `loglik` without Σ log C(n, y), `aic` and `bic` with m + p parameters and the rows (M-56), `auc` missing for binomial outcomes (M-57).

Memory: 8 more bytes per row with trials, and 4 with clusters; the robust covariance is p × p.

### B.3 Results

| Call | Result |
|---|---|
| `test_providers(fit, test, se_type)` | the current columns; with `se_type` other than `"model"`, `std_error` for Wald tests, and the setting `se_type`; providers whose robust variance or stabilized variance is undefined get missing statistics, p-values, and flags, with one `pprof_warning_undefined_statistics` (M-49, D-94, D-95) |
| `provider_effects(fit, interval, se_type)` | `std_error` from `se_type`; Wald limits from it; the setting `se_type` when not `"model"` |
| `standardize_providers(fit, ..., se_type, rate_denominator, effects)` | `std_error` (missing for indirect rows) when `se_type` is given; the settings `se_type`, `rate_denominator`, and `supplied` (the providers whose effects were supplied) when used; the supplied providers' direct rows have missing `std_error`, `lower`, and `upper` |
| `test_measures(measures)` | `pprof_measure_tests`: a `table` with `provider_id`, `standardization`, `measure`, `estimate`, `std_error`, `reference`, `statistic`, `p_value`, `flag`, `lower`, `upper`, and the settings `transform`, `null_location`, `null_scale`, `level`, `alternative` |
| `test_coefficients(fit, se_type = "robust")` | the Wald table from `robust_vcov`; the setting `se_type` |
| `provider_table(fit)` | adds `n_trials` and `n_clusters` where used |
| `fitted()`, `residuals()`, `augment()` of a binomial fit | `glm()`'s conventions: fitted probabilities; response residuals y/n − p, Pearson (y/n − p)/sqrt(p(1 − p)/n), deviance residuals from the binomial deviance; rows with zero trials have missing residuals; `augment()` gives `observed` = y/n and adds `trials` |
| `print()`, `glance()` | the print names the trials and the clusters; `glance()` is unchanged (its `auc` missing for binomial outcomes) |

## C. The data layer

### C.1 Changes to `data_prepare()`

Two arguments are appended, `trials = NULL` and `screen_clusters = FALSE`, whose defaults reproduce the current behavior (DEC-146).

- **`trials`.** A column of trials: listwise deletion covers it (K-03); its values must be numbers, finite, at least 0, and integer-valued (`data_trials()`), or `pprof_error_invalid_input`; the response must then be integer-valued from 0 to the trials (`data_check_events()`), or the same error (D-92). When every complete row has one trial, the data are binary: `trials` is not kept and nothing else changes, so the result is identical to a call without it but for `settings$trials`.
- **The provider table** with trials: `n_trials`, the sum of the trials over the provider's observations in their stored order (as `data_event_indicators()` sums events); `no_events` when Σy = 0 and `all_events` when Σ(n − y) = 0, among included providers.
- **`screen_clusters`.** With `cluster` given and `min_provider_size` set: the provider table adds `n_clusters`, the provider's distinct cluster labels among its complete observations, and screening compares it with `min_provider_size`. Without `screen_clusters` a cluster column is kept as now (the Cox models).
- **Settings.** `trials` and `screen_clusters` join the extended settings, recorded only when used.
- **`validate_pprof_data()`** checks the trials (one finite double of at least 0 per observation) and the new columns where present.
- **`model_data_spec()`** records `trials` and `screen_clusters`, so that `model_prepared_data()` rebuilds the data.

### C.2 The existing families stay unchanged

No existing caller passes `trials` or `screen_clusters`. Each commit of L2 and L3 that touches the data layer shows it three ways, as the CoxPH phase did (COXPH_DESIGN §C.2): the `data_prepare()` snapshot test (`validation/fixtures/data-prepare-snapshot.rds`), `devtools::test()`, and `validation/run-reference.R`, before and after, with the equivalence report changed only in its date and commit.

### C.3 `check_data()`

With `trials`, the result gains a `binomial` element: `n_trials`, the rows whose events are not integers or lie outside 0 to the trials, the rows with trials that are not integers or are negative, the rows with zero trials, the providers without trials, the providers with no events, and those with only events. With `cluster` for binary or binomial outcomes, a `clusters` element: the number of clusters, their sizes (the largest, and the number above the stabilized tests' 5,000 rows), the clusters of each provider (the providers with one cluster, and with fewer than `min_provider_size`), and the labels shared by several providers. Printing lists the problems found. The survival checks are unchanged.

## D. The contract and the profiling hooks

### D.1 The contract

Three generics are added (DEC-147), each with the existing behavior as its default:

| Generic | Returns | Shared method |
|---|---|---|
| `observation_trials(model)` | each observation's trials, or `NULL` for one trial per observation | yes: the model's `trials`, `NULL` when absent |
| `trial_probability(model, effect)` | each observation's probability of an event in one trial if its provider's effect were `effect` (one value, or one per included provider) | no; the logistic fixed-effect method is `plogis(effect + linear predictor)`, the expression `expected_outcome()` evaluates for binary outcomes |
| `observation_clusters(model)` | each observation's cluster code, or `NULL` | yes: the model's `cluster`, `NULL` when absent |

For a binomial model, `expected_outcome()` gives n times `trial_probability()`, the expected number of events of each row.

### D.2 The family specification

`profile_spec.pprof_logistic_fe()` is unchanged for binary models until L4 (§F.5). For a binomial model:

- `direct_expected` is a function of `(effects, linear_predictor, threads)` over the model's rows with their trials as weights (§F.5), and `direct_limits = "direct_expected"`, so that direct limits sum with the weights as pprofR's do;
- a new optional field, `direct_moments(effects, linear_predictor, threads)`, gives the expected totals and Σ w p(1 − p), which the standard errors of direct measures use; it defaults to `NULL`, which leaves direct measures without standard errors;
- the other fields are those of binary models: the binomial sums of §D.3 replace `variance_function` where the trials matter.

### D.3 Shared-layer changes

Each change runs only when its new input is present, so that every existing result follows the code it follows now (DEC-147):

1. **`R/model-contract.R`**: the three generics of §D.1.
2. **`R/profile-tests.R`**: with trials, the count tests take each row's trial probabilities (clamped, K-62) and trials: the exact test over the probabilities repeated by trials, and the bootstrap of K-154; the modified score test the binomial sums (K-155). With `se_type` other than `"model"`, the Wald and score tests take the clustered variances of `R/inference-clustered.R` (new).
3. **`R/inference-exact.R`, `R/inference-score.R`, `R/inference-invert.R`**: the binomial bootstrap, the binomial modified score, and the binomial interval equations (K-157), as new functions beside the binary ones.
4. **`R/inference-clustered.R`** (new): the cluster sums, the robust meats, the pooled within-cluster matrix and the stabilized meats (§F.3, §F.4).
5. **`R/profile-intervals.R`**: with trials, the effects' exact and score limits from the binomial equations, and the measure limits from Σ n expit(·); Wald limits with the chosen standard error.
6. **`R/profile-standardize.R`**: with trials, the indirect sums Σ n p0 and Σ n p0(1 − p0), the population rate Σy / Σn, the one-sided extremes' full counts Σn; the rates' denominator; the standard errors of direct measures from `direct_moments`; the supplied effects.
7. **`R/profile-effects.R`, `R/profile-providers.R`**: `se_type`.
8. **`R/inference-coefficients.R`**: with trials, the likelihood-ratio statistic's −2ℓ and the score test's weights and score with the trials; `se_type = "robust"` reads `vcov(model, se_type = "robust")`.
9. **`R/model-capabilities.R`**: `variance_robust` and `variance_stabilized` (§D.4).
10. **`R/results.R`**: `pprof_measure_tests`, and `std_error` in measures tables.
11. **`R/present-*.R`**: printing and tidying of `pprof_measure_tests`; the binomial model's print and `augment()`.
12. **`R/check-data.R`**: §C.3.
13. **`R/constants.R`**: `stabilized_max_cluster_rows` (5,000) and the constants of §F.

ARCHITECTURE §E.4's rule that a new model changes no other file does not apply: these features extend an existing model and the shared layers, as the Cox models did (the CoxPH brief's §5.6).

### D.4 Capabilities

- A logistic fixed-effect model with trials declares every capability of a binary one, the standard score test included (M-54).
- With clusters it adds `variance_robust` (the robust Wald and score tests of providers, their Wald intervals, the standard errors of direct measures, and the robust Wald test of the coefficients) and `variance_stabilized` (the stabilized Wald and score tests of providers, their Wald intervals, and the standard errors of direct measures). A request for either without it raises `pprof_error_unsupported_inference`, whose message says to fit with `cluster`.
- Firth models declare neither.

## E. The engines

### E.1 The binomial path (DEC-148)

New C++ in `src/logistic/binomial.{h,cpp}`, namespace `pprof::logistic`, behind the adapter `src/rcpp_logistic.cpp`, with the binary functions left as they are:

- `fit_serbin_binomial()` and `fit_ban_binomial()`: the iterations of `fit_serbin()` and `fit_ban()` with y − n p and n p(1 − p), the log-likelihood of `core::binomial_loglik()`, and pprof's conventions: SerBIN's weights floored at 1e-20 in the provider diagonal and the covariate block and unfloored in the cross block (K-12, K-13, D-83); BAN's covariate step unfloored; the clamp, line search, criteria, and loop bounds as now.
- `logistic_fe_variance_binomial()`: K-20 with the weights n p(1 − p) at clamped probabilities, the diagonal as their sum (pprofR's arithmetic, §A.3).
- `standard_score_test_binomial()`: K-66 with the trials (M-54), its reference the expansion into trials through the binary test (§G.3).
- `core::binomial_loglik()` in `src/core/loglik.cpp`, and `core::cross_block_weighted()` in `src/core/information_blocks.cpp`, the cross block from given weights.

Where pprof's conventions do not decide, the path performs pprofR's operations in pprofR's order (§A.2), so that it reproduces pprofR's iteration path (`dev/logistic_brief.md` §3.5).

### E.2 Dispatch

`logistic_fe_estimate()` calls the binomial adapters when the prepared data keep trials, and the binary ones otherwise; since trials of 1 are not kept (§C.1), a fit with them takes the binary path.

### E.3 Adapters

`cpp_logistic_fe_serbin_binomial()` and `cpp_logistic_fe_ban_binomial()` (the binary adapters' arguments with `trials` after `response`), `cpp_logistic_variance_binomial()`, `cpp_logistic_score_standard_binomial()`, and in L4 `cpp_logistic_direct_moments(effects, linear_predictor, weights, threads)`, which returns the expected totals and the sums Σ w p(1 − p). `Rcpp::compileAttributes()` regenerates the glue; every new object file joins `OBJECTS` in both Makevars files.

## F. Algorithms and their cost

### F.1 Fits

The binary iteration's cost, O(rows · p² + m · p²), with a few more multiplications per row.

### F.2 The exact and bootstrap tests

- The exact test of a binomial provider calls `poibin::ppoibin()` and `dpoibin()` on its rows' probabilities repeated by their trials, as pprofR does (DEC-150). poibin's DFT-CF method costs O(T_i²) for a provider with T_i trials: 34 s at 20,000 trials and 234 s at 50,000 on one machine (fact 03). The brief's §3.7 asks for an equivalent computation without the expansion; a convolution of the rows' binomial distributions agreed to 4e-12 at 50,000 trials, but poibin's own rounding error there exceeds the `probability` tier's absolute floor (1e-14), so no other algorithm can agree with pprofR within that tier, and the SHOULD is not met. The help says the score test serves providers with many trials.
- The bootstrap draws one binomial value per row and resample: O(rows · `n_resamples`).
- The clamp of null probabilities (K-62) applies before both (M-46).

### F.3 Cluster-robust variances

- **Provider level** (§A.5), at test time from the contract: the cluster sums Σ_{j∈k} r_j by `rowsum()` over the cluster codes, then V_i by provider: O(rows). The robust Wald standard error is sqrt(V_i)/I_i, with I_i = Σ v floored at 1e-20 (K-160).
- **Coefficients**, at fit time when clusters are given, stored as `robust_vcov` (DEC-149): the bread from the information blocks at clamped probabilities, B (p × m), D, C, S = C − B D⁻¹ B', J = S⁻¹ B D⁻¹; the meat from the cluster sums of r (one per cluster) and of z r (p per cluster): A₀ (per provider Σ_k r_k²), A₁ (per provider Σ_k r_k U_k'), A₂ (Σ_k U_k U_k'); Var(β) = J diag(A₀) J' − J A₁ S⁻¹ − S⁻¹ A₁' J' + S⁻¹ A₂ S⁻¹, symmetric (D-98: pprofR doubles one cross term, which leaves the diagonal unchanged). O(rows · p + m · p²) once, in R; C++ only with benchmark evidence.
- **Single-cluster providers**: the robust tests and the robust standard errors of their effects and direct measures are missing, with one `pprof_warning_undefined_statistics` naming them (M-49, D-94).

### F.4 The stabilized variance

R̂ (s × s, s the largest cluster's rows) is formed from the clusters' standardized residuals by position, S(k, l) = Σ_clusters e_k e_l over the clusters with at least max(k, l) rows divided by their number, and W_k = a_k'R̂a_k. In R, with the clusters laid out as a K × s matrix padded with zeros, R̂ = E'E / count and W = rowSums((A R̂) ∘ A), O(K · s²) time and K · s memory; above a memory bound (§I) in chunks of clusters. Clusters of more than 5,000 rows raise `pprof_error_data` (`stabilized_max_cluster_rows`, K-162). A negative V_i gives a missing statistic with the classed warning (D-95). C++ only with benchmark evidence against pprofR's (`src/Fixed_effect.cpp:639-694`).

### F.5 Direct standardization (DEC-151)

The algorithm of §A.8, reimplemented in `src/logistic/direct_moments.{h,cpp}` (L4): a stable sort of η, the merge of equal values with weights summed in long double, exp() once per distinct value and per effect, the factored terms when b·a_max is finite and the direct ones otherwise, long-double accumulators, and threads over effects. O(rows · log(rows) + m · u) for u distinct linear predictors, against O(m · rows) now. It serves `direct_expected()`, the binomial models, and, from L4 on, every direct measure of the new interface (M-45, D-89); the deprecated functions of pprof 1.0.3 keep `cpp_logistic_direct_expected()`, through a setting of the models they rebuild (`spec$direct_algorithm = "rows"`), so that they keep reproducing pprof 1.0.3.

### F.6 Intervals

Root finding as K-90 for binary and binomial models (M-47); each evaluation of an exact equation costs a Poisson-binomial distribution over the provider's trials (§F.2).

### F.7 Memory

No data are expanded into trials (8 bytes a trial would be 8 bytes a row times the trials). The stabilized variance's padded matrix is the largest new allocation, K · s doubles, bounded by §F.4's chunks.

## G. Validation

### G.1 Fixtures (DEC-152)

- **The generator**, `dev/reference/pprofr/`, in R:
  - `setup_pprofr_library.R` builds pprofR from `git archive f23c288` into `dev/reference/pprofr/lib/` (gitignored), against Rcpp, RcppArmadillo, and poibin at the versions of `dev/reference/library-lock.json`; the commit must be in the local object store (fetched read-only from the upstream repository); its sources go to a scratch folder, never into the working tree;
  - `datasets.R` makes the synthetic data sets with seeds, rows grouped by provider and cluster with zero-padded labels, so that pprofR's sort and pprof's agree (§A.1, D-97); the data sets are stored with the fixtures;
  - `cases.R` lists the cases; `generate.R` runs them in a child session whose library is pprofR's and base R's, with `threads = 1` and explicit seeds, and writes one RDS per case at full precision and `manifest.json` (pprofR's commit and version, never its DESCRIPTION's text; R, the platform, BLAS and LAPACK, the compiler, the package versions, the calls, the seeds, the checksums); `compare.R` writes the diff reports a regeneration needs.
- **The cases** (all synthetic):
  1. `binary-moderate`: binary outcomes, 40 providers: the fits (both methods, `"or"` and `"beta"`, tol 1e-5 and 1e-10), the variances, every provider test with each alternative, the bootstrap with a seed, the intervals of effects and measures (exact, score, Wald), the measures (indirect and direct, ratios and rates, `N_pop` default and given), the covariate tests;
  2. `binomial-moderate`: 1 to 20 trials a row: the same;
  3. `binomial-many-trials`: providers of a few thousand trials: the tests and intervals the cost allows;
  4. `clustered-binary` and `clustered-binomial`: clusters of 1 to 4 rows with a shared random intercept: the robust and stabilized tests, the robust Wald intervals, the robust coefficients, the direct rates' standard errors;
  5. `few-clusters`: providers with one, two, and three clusters, and a stabilized variance that is negative;
  6. `extreme-probabilities`: null probabilities below 1e-10;
  7. `extreme-providers`: binomial providers with no events and with only events;
  8. `standard-population`: `direct_exp()` with weights, repeated linear predictors, effects of ±15 and ±30, and rates near 1;
  9. `measure-tests`: `test_SM()` on direct rates with robust standard errors, both scales, two nulls, three alternatives;
  10. `zero-trials`: rows with zero trials;
  11. `supplied-effects`: direct standardization with supplied effects;
  12. `cluster-order`: the clustered data with each cluster's rows reversed.
- **Sets**: the full set in `validation/fixtures/pprofr/`. No core set ships at first: the tarball has 17 KB of room below the 5 MB note, which the phase's code, help, and tests will use (DEC-153); the tests that ship check the new features against the independent references of §G.3, which need no fixtures. L1 measures whether a core set of a few KB fits.
- **Regeneration** needs the project lead's approval and a diff report, and runs locally only (the brief's §12).

**As built (L1; DEC-156, DEC-157).** `dev/reference/pprofr/` makes eleven cases with 492 records, 1.4 MB in all (`dev/design/LOGISTIC_L1_PLAN.md` §2). It departs from the list above in four ways:

- the clustered cases of item 4 are the moderate cases' clustered fits;
- the many-trials case's providers have about 1,100 to 2,200 trials, as many as the cost of pprofR's exact intervals allows;
- the moderate and many-trials cases add tight fits, made without the line search, for the comparisons with `glm()` and `sandwich::vcovCL()`;
- pprofR's exact test of a provider without trials crashes R and is not recorded (D-100).

No core set ships: the smallest case is 8 KB, and every case with a binomial fit 59 KB or more, against 17 KB of room (DEC-153).

### G.2 Tolerance tiers

The existing tiers, applied as the brief's §3.5 says, calibrated in L1 against negative controls (one event moved between rows, one cluster split in two, the null shifted by 1e-9), each control at least 10 tolerance units away and the agreement within 1:

| Quantity | Tier |
|---|---|
| iteration counts, inclusion, indicators, sizes, flags | `exact` |
| binomial estimates | `iterative`, with the iteration count matched |
| variances given the estimates; robust and stabilized standard errors; measures and their standard errors; direct standardization; the measure test | `closed_form` |
| p-values | `probability`; the exact test's statistic by DEC-083's rule |
| interval limits | `root` (pprof's root finder against pprofR's, M-47) |

Where pprof's convention differs from pprofR's (§3.3 of the brief), the comparison expects the difference the register entry states, and the report lists such cases.

**As built (L1; DEC-158).** The table is applied in `tests/testthat/helper-pprofr-fixtures.R`. The calibration (`dev/reference/pprofr/calibrate.R`, `validation/pprofr-calibration-report.md`) found every agreement with an independent reference within its tier; 187 of 196 rows pass. In the nine others a control lies within 10 units: the limits under `root` (one event moved: 0.22 to 8.4 units) and the indirect measures under `closed_form` (the null shifted by 1e-9: about 7). M-66 put them to the project lead, who decided as proposed (DEC-161): the tiers stay, and from L2 the limits' equations are also compared at fixed effects.

### G.3 Test layers

- **A. Reference comparisons** against the pprofR fixtures: `tests/testthat/test-pprofr-reference.R`, run on the full set by `validation/run-pprofr-reference.R` (new), which writes `validation/pprofr-equivalence-report.md`, as `validation/run-cox-reference.R` does for the Cox fixtures (DEC-135). From L1, the binary cases (DEC-159).
- **B. Existing results**: §C.2, and the differential tests (`validation/run-differential.R`).
- **C. Closed-form units**: binomial sums by hand; the sandwich and the pooled matrix by hand on a few rows; the delta method against central differences; the measure test against its formulas; `direct_expected()` against R's long-double sums.
- **D. Independent references**, shipped:
  - `glm()` with `cbind(y, n - y)` and provider indicators at tight convergence (DEC-050's rule);
  - the expansion into trials through pprof's binary code: fits, every test, intervals, measures, the funnel, and the standard score test;
  - `sandwich::vcovCL(type = "HC0", cadjust = FALSE)` by (provider, label) pairs, skipped without sandwich;
  - plain-R versions of the robust and stabilized formulas.
- **E. Metamorphic tests**: trials of 1 against none (`identical()`); a provider's rows with equal covariates merged into one binomial row; row order, except within clusters for the stabilized tests; provider and cluster relabeling; the thread count of direct standardization.
- **F. Edge cases**: the brief's §6 F.
- **G. Regression tests**: one for each register entry of §J.

### G.4 Simulation (L5)

`validation/run-simulation.R` adds, after its existing families so that no existing seed moves, the logistic model with clusters (binary and binomial outcomes, clusters with a shared random intercept, and none): the size and power of the model-based, robust, and stabilized tests, and the coverage of their Wald intervals; and the binomial exact and score tests' size.

### G.5 CI

`rewrite-reference.yaml`'s four jobs run `validation/run-pprofr-reference.R` beside the Cox comparisons; the shipped tests run in `rewrite-check.yaml`; sandwich joins the CI packages.

## H. Dependencies

- **sandwich**: Suggests, for the independent reference of the tests (DEC-152); the tests skip without it.
- **No new Imports.** poibin, Rcpp, and RcppArmadillo are already in DESCRIPTION.
- **pprofR**: only in the generator's isolated library.

## I. Benchmarks

- **Grid**, in `dev/bench/` with paired runs (DEC-038): rows 10^4, 10^5, 10^6; providers 100 and 1,000; trials per row 1, 10, 100; clusters of 1 to 4 rows; covariates 5 and 20.
- **Tasks**: the binomial fits (SerBIN, BAN) and their variances; the exact, bootstrap, score, and Wald tests; the robust and stabilized tests; the robust coefficients; direct standardization (merged and by rows); the measure test.
- **Comparators**, in the same process: pprofR 0.2.0 from its library, for the binomial and clustered tasks (the brief's §3.7: no slower than pprofR); the baseline of the binary tasks (DEC-023), which must not regress.
- **Bound**: the stabilized variance's padded matrix at most 2.5 × 10^7 doubles at once (200 MB, the size of R̂ itself at the largest cluster allowed, 5,000 rows), with chunks of clusters beyond; L3 confirms the bound with the benchmarks.
- **Peak memory** with `gc()`'s maximum used.

**As built (L1; DEC-160).** `dev/bench/pprofr/` varies one factor at a time around the grid's centre instead of crossing it: six scenarios and 22 pprofR tasks. Exact tasks too costly here are timed for one provider instead. The baseline (`dev/bench/results/pprofr-baseline-20261021-windows.*`) gives pprofR's costs, which L2 to L4 measure again beside the package's, paired in one process. Its fits and z tests take under a second at 100,000 rows; its exact intervals take up to 383 s for one provider of 10,000 trials.

## J. Register entries

| Register | Entries |
|---|---|
| `dev/CONVENTIONS.md`, "Logistic extensions (pprofR 0.2.0)" | K-150 to K-167 |
| `dev/DISCREPANCIES.md`, "The logistic extensions phase" | D-82 to D-105 |
| `dev/OPEN_QUESTIONS.md`, "The logistic extensions phase" | M-42 to M-65 (the brief's Q1 to Q24), decided as recommended (DEC-144) |
| `dev/DECISIONS.md` | DEC-143 to DEC-155 |
| `dev/NAMING.md` | §11 |
| `dev/design/ARCHITECTURE.md` | §E.8, the plan |

## K. What each phase builds

| Phase | Builds | Files |
|---|---|---|
| L1 | the generator and its library, the full fixture set, the calibration report and the tiers' application, the benchmark baseline against pprofR | `dev/reference/pprofr/`, `validation/fixtures/pprofr/`, `validation/pprofr-calibration-report.md`, `dev/bench/` |
| L2 | trials in the data layer and `check_data()`; the binomial engine path; the fit, its statistics, and its methods; the contract's three generics; the binomial branches of the tests, intervals, measures, funnel, and covariate tests; the standard score test with trials; the shipped tests against `glm()` and the expansion; the pprofR comparisons of the binomial cases | `R/data-*.R`, `R/check-data.R`, `src/logistic/binomial.*`, `src/core/*`, `src/rcpp_logistic.cpp`, `R/model-logistic-fe.R`, `R/model-contract.R`, `R/profile-*.R`, `R/inference-*.R`, `R/present-*.R` |
| L3 | clusters in the data layer and `check_data()`; screening by clusters; `R/inference-clustered.R`; the robust and stabilized tests and intervals; the robust coefficients; `se_type`; the capabilities | as L2, and `R/model-capabilities.R` |
| L4 | `src/logistic/direct_moments.*`; `direct_expected()`; the standard errors of direct measures; the rates' denominator; supplied effects; `test_measures()`; every direct measure of the new interface on the merged algorithm, with its fixture-difference report (D-89); the deprecated functions on the old sums | `R/profile-standardize.R`, `R/profile-measure-tests.R` (new), `R/results.R`, `R/present-*.R`, `R/compat-convert.R` |
| L5 | help pages, the vignettes' sections, NEWS, the developer guide and ARCHITECTURE as built, the simulation study's rows, the final equivalence and benchmark reports, coverage, the final review | `man/`, `vignettes/`, `NEWS.md`, `dev/`, `validation/` |
