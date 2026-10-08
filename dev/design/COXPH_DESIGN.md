# CoxPH design (Phase C0)

> **Status: the Phase C0 deliverable of `dev/coxph_brief.md` (§9), 2026-10-07, for the C0 gate.** Its decisions were made under the project lead's delegation of 2026-10-07 (DEC-087 to DEC-093; M-23 to M-41). The gate confirms them, and Phases C1 to C6 implement them.

This document says how the Cox models of pprof_py v0.7.0 enter `pprof`:

- §A, what pprof_py does;
- §B, the interface;
- §C, the data layer;
- §D, the contract and the profiling hooks;
- §E, the engine adapters;
- §F, the algorithms and their cost;
- §G, validation;
- §H, dependencies;
- §I, benchmarks;
- §J, the register entries.

**Evidence** comes from two sources:
- the scripts and outputs in `dev/design/coxph-facts/` (cited by file name);
- pprof_spark's Cox specifications (`docs/spec/cox/` in pprof_spark), which describe pprof_py v0.7.0.

**Notation** follows `dev/CONVENTIONS.md`:
- β, the coefficients;
- o_i, the offset;
- η_i = x_i'β + o_i;
- r_i, the risk score;
- (start_i, stop_i], an observation's interval at risk, with start_i = 0 for right-censored data;
- δ_i, the event indicator;
- O_j and E_j, provider j's observed and expected events;
- m providers and n observations (rows).

## A. What pprof_py does: behavior specifications

pprof_py v0.7.0, commit `9320766`; locations are relative to `pprof_py/`. Every statement was checked by reading the code and, where the code left a detail open, by running it (2026-10-07, the C0 specification review). The conventions each section fixes are registered as K-131 to K-147 (`dev/CONVENTIONS.md`).

**Notation.**
- Φ is the normal CDF and Φ̄ = 1 − Φ.
- F(k; μ) and f(k; μ) are the Poisson CDF and probability function, with F(−1; μ) = 0.
- α = 1 − level, computed in floating point: 0.050000000000000044 at the default 0.95.

### A.1 Inputs (`data/survival_validation.py:161-273`)

**What is accepted.**
- **X**: numeric covariates, every value finite. pprof_py has no formula interface.
- **Times**: either `duration` (then start = 0) or `start` and `stop`, with start < stop for every row.
  - This rejects a duration of 0 and negative durations; negative starts are allowed.
- **`event`**: 0/1 or logical. The 1/2 coding of `Surv()` is rejected.
- **`offset`**: a finite vector.
- **`sample_weight`**: finite and at least 0. Zero weights are accepted, even if every weight is 0.
- **`strata`**: any labels, coded by sorted label (`np.unique`).

**Missing values.** Any missing value is an error; nothing is deleted.

**Ties and strata.** Event times, ties, and strata are identified by exact equality: 0.1 + 0.2 and 0.3 are different times, with no `timefix` (K-131).

**The package's differences.**
- **Data.** The package reads the same data through a formula (`Surv(...) ~ terms + offset(...)`) and the `provider` argument, deletes incomplete rows listwise (D-62), and accepts what `Surv()` accepts (D-74).
- **Fits.** The package fails on aliased covariates and on data without events (D-59).
- **Intercept.** `fit_intercept` has no counterpart.

### A.2 `CoxPH` (`models/survival/coxph.py`, `algorithms/survival/`)

**The model.** `CoxPH(ties = "breslow", max_iter = 20, eps = 1e-9, robust = False)` fits the partial likelihood. The fit takes optional strata, offset, weights, and cluster. The package's model is this fit with the provider as the strata.

**Each stratum.**
- The risk set at event time t is {i : start_i < t ≤ stop_i} (K-131).
- The terms of tied deaths are Breslow's, or Efron's as `survival`'s `agfit4` computes them.
- Under Efron, the number of tied deaths d counts zero-weight rows too (B7, D-58).

**Estimation** (`algorithms/survival/optimization.py`).
- Newton–Raphson from β = 0 on covariates centered by their unweighted means.
- It stops when the relative change in the log-likelihood is below `eps`, within `max_iter` iterations.
- A step that lowers the log-likelihood is halved, up to 20 times, before convergence is tested. This is B6: pprof_py's iterates equal `survival`'s up to the last step, and the final estimates differ by up to 1e-8 (D-57; `dev/design/coxph-facts/12_newton_path.txt`).
- The fit warns when it reaches `max_iter`.

**Variance.**
- The default is the model-based variance, the inverse of the information. Non-integer weights do not switch the robust variance on, unlike `coxph()`.
- With `robust = True` or a `cluster`, the variance is the sandwich V (Σ_c s_c s_cᵀ) V, where s_c is the cluster sum of weighted score residuals and each row is its own cluster when no cluster is given (`inference/survival/robust.py:380-410`).
- Its counting-process kernel uses Efron's formulas for tied deaths whatever `ties` says (B1, D-56).

**Other outputs.**
- The linear predictor is x'β̂ + offset, uncentered.
- `baseline_hazard_` is the baseline at x = 0 and offset 0 times exp(the weighted mean offset), as `basehaz(centered = FALSE)` gives (D-60).
- Martingale residuals port `agmart3`; score and dfbeta residuals port `agscore3`; predictions use the baseline without the offset factor.
- With aliased covariates, the solve falls back to a pseudo-inverse; with no events, β̂ = 0 (B8, D-59).

**Agreement with `survival`.** pprof_py agrees with `coxph(timefix = FALSE)` to about 1e-15 on 200,000 rows (`08_timefix.txt`).

The package delegates all of this to `survival` (DEC-091), so it inherits `survival`'s convergence order, robust variance, and recentering (D-57, D-56, D-64).

### A.3 Standardized measures (`measures/survival/coxph.py:47-183`)

**The call.** `calculate_standardized_measures(X, duration or start/stop, event, provider_id, offset, providers, stdz)`.

- **What the computation uses.**
  - Only the fitted coefficients: η_i = x_i'β̂ + o_i.
  - It does not use the fit's strata, ties, or weights. An Efron fit gets Breslow baselines at its Efron β̂ (M-29).
  - Covariates are matched to coefficients by position (B4, D-63).
- **Risk scores.** r_i = exp(η_i − max η), with no clipping. Every output is invariant to the common factor (K-136).
- **The national baseline** (K-136).
  - Over all rows, unweighted.
  - At the distinct event times t, by exact equality, with d(t) the number of event rows at t: Λ0(t_k) = Σ_{l ≤ k} d(t_l) / RS(t_l), where RS(t) = Σ_i r_i 1(start_i < t ≤ stop_i).
  - Λ0 is right-continuous, and 0 before the first event time.
  - RS(t) is computed as the difference of two suffix sums. That loses precision only when the risk scores span about e^20 or more (late entrants with much higher η); the package computes it the same way, so it reproduces pprof_py (K-136).
- **Indirect** (K-137).
  - O_j is the number of provider j's events, and E_j = Σ_{i ∈ j} r_i [Λ0(stop_i) − Λ0(start_i)].
  - The ratio is O_j / E_j: NaN when O_j = E_j = 0, ∞ when only E_j = 0, and 0 when O_j = 0 < E_j.
  - Σ_j E_j = O.
- **Direct** (K-138).
  - E^(j) = Σ over provider j's event rows i of RS(t_i) / RS_j(t_i): one term per event row, where RS_j is the risk-set sum over provider j's rows.
  - The ratio is E^(j) / O, with O the total number of events; it is 0 for a provider without events.
  - E^(j) equals Σ_i r_i [Λ0j(stop_i) − Λ0j(start_i)] over every row, with Λ0j provider j's own unweighted Breslow baseline.
- **Person-time** is Σ_{i ∈ j} (stop_i − start_i) (K-139).
- **Outputs.**
  - Indirect: `provider_id`, `indirect_ratio`, `observed`, `expected`, `person_time`.
  - Direct: `provider_id`, `direct_ratio`, `observed` (the total O), `expected`, `n_pop` (the number of rows).
  - Providers come in sorted order.
  - The `providers` argument filters the output only, ignoring unknown IDs.
- **Edge cases.** No events at all raises `IndexError` (Class A; the package fails at the fit, D-59, D-73).

### A.4 Provider tests and intervals (`inference/survival/provider_tests.py:29-140`, `inference.py:61-180`, `empirical_null.py:188-207`, `inference/decision.py`)

**The call.** `test(X, ..., provider_id, offset, providers, test_method = "midp", null_model = None, level = 0.95)`. Each provider's indirect O_j and E_j are tested against the ratio 1, two-sided.

**Mid-p** (the default; K-141).

- **The probabilities** (`1 − F(O − 1; E)` is computed as written, not as the Poisson upper tail):
  - p_min = 2F(O; E) − f(O; E);
  - p_max = 2(1 − F(O − 1; E)) − f(O; E);
  - p* = max(1e-6, min(p_min, p_max) / 2).
- **The statistic.** z = Φ⁻¹(p*) if p_min ≤ p_max, otherwise −Φ⁻¹(p*).
  - Then |z| ≤ 4.7534243.
  - O = E does not give z = 0: O = E = 5 gives 0.0708.
  - O = E = 0 gives z = 0.
- **Under the theoretical null** (mean 0, sd 1): the p-value is 2Φ̄(|z|), which is 2p* to within 1.2e-15, so at least 2e-6.
- **Limits.**
  - Each provider's limits on the Poisson mean, L and U, solve 2Φ̄(|z(t) − m| / s) − α = 0 in t, with m = 0 and s = 1 for the theoretical null.
  - The bracket: from lo = 1e-10 max(E, 1) to hi = 10 (O + E + 10), multiplied by 10 while z(hi) > max(m, −4.75) and hi < 1e12.
  - The split point: lo if z(lo) ≤ m, hi if z(hi) ≥ m, and otherwise the root of z(t) − m, found by `brentq` with xtol 1e-12 max(E, 1).
  - L = 0 if the equation is non-negative at lo; otherwise its root on [lo, split point].
  - U = ∞ if the equation is non-negative at hi; otherwise its root on [split point, hi].
  - Both roots are found by `brentq` with xtol 1e-10 max(E, 1) and its default rtol 8.9e-16.
  - The ratio limits are L / E and U / E.
  - Under the theoretical null at level 0.95, L = 0 exactly when O = 0, and U is finite.

**Exact** (K-140).

- **The p-value.**
  - p_ex = min(0.999, 2P(X ≥ O)) when O/E > 1, otherwise min(0.999, 2F(O; E)), with X ~ Poisson(E).
  - When O = E the lower tail is used, which always reaches the cap.
- **The statistic.** z = sign(O − E) Φ̄⁻¹(p_ex / 2).
- **The reported p-value** is 2Φ̄(|z|). It equals p_ex to within a unit in the last place, except that O = E gives 1, not 0.999 (reproduced).
- **Underflow.** A p_ex that underflows to 0 gives an infinite z, which pprof_py reports as untested (flag missing). The package flags such a provider (D-71).
- **Limits on the ratio, chosen by E, not O.**
  - **E < 100 (Garwood).** Lower: `qchisq(α/2, 2O) / (2E)`, 0 when O = 0. Upper: `qchisq(1 − α/2, 2(O + 1)) / (2E)`.
  - **E ≥ 100 (Byar).** With z = Φ⁻¹(1 − α/2):
    - lower = (O/E)(1 − 1/(9O) − z/(3√O))³, 0 when O = 0;
    - upper = ((O + 1)/E)(1 − 1/(9(O + 1)) + z/(3√(O + 1)))³.
  - Byar's limits can disagree with the exact test's flag at the boundary, and the lower limit can be negative at high levels (reproduced).

**Flags** (K-142).
- +1 when p < α and z > 0, −1 when p < α and z < 0, and 0 otherwise. The inequality is strict, and the direction comes from the sign of the null-calibrated z.
- The default level is 0.95.

**Output.**
- A table by sorted provider: `estimate` (O/E), `null_value` (1), `z_raw`, `null_mean`, `null_sd`, `z_adjusted`, `p_value`, `flag`, `ci_lower`, `ci_upper`, `observed`, `expected`, and `person_time`, among others.
- The `providers` filter is applied after the null is fitted.

**Scope.**
- With E_j = 0: the estimate is NaN or ∞; the mid-p lower limit is NaN and the upper ∞; the exact limits are 0 and ∞ (K-147, D-70).
- Empirical nulls (`null_model`) are not in this phase (brief §2.2). Their mid-p limits can fail in pprof_py when O = 0 and the null mean is large (D-73).

### A.5 Penalized Cox (`models/survival/penalized_coxph.py`, `algorithms/survival/coordinate_descent.py`, `penalty.py`, `utils/deviance.py`)

**The call.** `PenalizedCoxPH(alpha = 1, n_lambda = 100, lambda_min_ratio = None, lambda_path = None, penalty_factor = None, standardize = True, ties = "breslow")`. The fit takes the same strata, start/stop, offset, and weights as `CoxPH`.

**Objective.** −c ℓ(β) + λ Σ_j pf_j [α|β_j| + ½(1 − α)β_j²], with c = 1/Σw. ℓ is the Breslow or Efron partial likelihood of `CoxPH` on the scaled design (K-143).

**Scaling.**
- With w̃ = w/Σw, each column's weighted population variance is v_j = Σ_i w̃_i (x_ij − x̄_j)².
- A column with v_j < 10ε (2.2e-15, in the column's units) is degenerate. It is left out with a `DegenerateFeatureWarning` and gets coefficient 0, with or without standardization. If every column is degenerate, the fit fails.
- With `standardize`, the other columns are divided by √v_j and are not centered.
- Coefficients are reported on the original scale.

**Penalty factors.**
- The user's factors must be finite and at least 0, and not all 0.
- They are rescaled over the non-degenerate columns to sum to their number.

**λ_max.**
- At the null point, the penalized coefficients are 0 and the unpenalized ones (factor 0) are fitted.
- λ_max = max_{j: pf_j > 0} |c U_j| / pf_j, divided by max(α, 1e-3).
- In pprof_py the unpenalized fit stops at eps 1e-9, so the first point can carry penalized coefficients of order 1e-11 (D-72).

**The grid.**
- exp(linspace(log λ_max, log(λ_max r), n_lambda)), descending.
- r is `lambda_min_ratio`, or 1e-2 if n < p (counting the non-degenerate columns) and 1e-4 otherwise.
- A given grid is sorted descending.

**The solver.**
- Proximal Newton on the exact information, with cyclic coordinate descent.
- Warm starts along the grid.
- Convergence on the KKT residual: below 1e-8 relative at the defaults.
- The package uses `glmnet` instead, on the same grid; the paths agree to 2.2e-7 at `thresh = 1e-12` (`09_penalized_glmnet.txt`; the `penalized_path` tier).

**Cross-validation (`PenalizedCoxPHCV`; K-144).**

- **Folds.**
  - Event-stratified: the event rows and then the censored rows, each in row order, receive a random permutation of the fold labels 0, 1, …, K − 1 repeated to their number.
  - There is one draw per group, from NumPy's legacy generator, so each fold gets ⌊m/K⌋ or ⌈m/K⌉ events.
  - The default is K = 10 (at least 3).
  - Given fold IDs (0..K − 1 or 1..K) are used as they are, and K = 2 is accepted.
- **Fold fits.** Each fold's path is fitted on its training rows over the full-data grid, with that fold's own scaling.
- **The fold deviance.** For the held-out rows H and the training rows T:
  - D_kj = [2(lsat_all − ℓ_all(β_kj)) − 2(lsat_T − ℓ_T(β_kj))] / W_k;
  - W_k = Σ_{i ∈ H} w_i δ_i, which must be positive;
  - lsat = −Σ over strata and distinct event times of w_t log w_t, where w_t is the summed weight of the events at t;
  - ℓ uses the fit's ties.
- **Summaries.**
  - cvm_j = Σ_k W_k D_kj / Σ_k W_k.
  - cvsd_j = √(Σ_k W_k (D_kj − cvm_j)² / Σ_k W_k / (K − 1)).
  - A λ at which any fold's deviance is not finite is dropped.
- **Selection.**
  - λ_min is the first λ, descending, at the minimum of cvm.
  - λ_1se is the first λ with cvm ≤ cvm(λ_min) + cvsd(λ_min).
  - The default rule is λ_1se.
  - The selected coefficients are the full-data path's at that grid point.
- **Bootstrap standard error.** The bootstrap option is not carried over (B10, D-67).

### A.6 Competing risks (`models/survival/competing_risks.py`, `algorithms/survival/finegray.py`)

**`CauseSpecificCoxPH`** (K-146).
- It fits one `CoxPH` per cause, with the event (event == cause) and the other causes censored, and the same covariates, strata, offset, and weights.
- It has no robust variance and no cumulative incidence.
- In the package: `fit_cox_stratified(Surv(time, status == k) ~ ...)` (M-35).

**`FineGrayPH(ties = "breslow")`** (K-145).
- **`finegray_transform()`**, which is `survival::finegray()`:
  - G, the censoring distribution: an unweighted Kaplan–Meier per stratum, on the integer time scale with event times shifted by −0.2;
  - H, the entry distribution, added when any first start exceeds the minimum stop;
  - each row with a competing event extended over the kept breakpoints, with weight curve(t)/curve(s);
  - case weights multiplying the weights only.
- **The fit.** `CoxPH` on the expanded data, weighted, with the strata, and with `cluster` = the subject (`id`, or the row), so the variance is robust.
- **Agreement with `survival`.** The transform and coefficients equal `survival`'s, delayed entry included; the robust SE with Breslow ties carries B1 (`05_robust_finegray.txt`).
- **Cumulative incidence.** 1 − exp(−H(t)) from the weighted baseline.
- **In the package:** `survival::finegray()` and `coxph()` (§E.3), stratified by provider (M-41).

## B. The interface

The names are those of `dev/NAMING.md` §10 (DEC-090).

### B.1 Functions

`fit_cox_stratified(formula, data, provider, weights = NULL, cluster = NULL, ties = "breslow", robust = FALSE, max_iter = 20, tol = 1e-9, keep_data = FALSE, verbose = FALSE)`

- **The model.** The Cox partial likelihood stratified by provider: each provider has its own baseline hazard, and the coefficients are shared. This is pprof_py's `CoxPH(strata = provider)` (§A.2) and the first stage of He and Schaubel's two-stage measures (§A.3).
- **`formula`.**
  - `Surv(time, status) ~ terms` or `Surv(start, stop, status) ~ terms`, with `survival::Surv()`.
  - `status` is 0/1 or logical, or an expression that gives it. `Surv(time, status == 1)` is the cause-specific model of cause 1, with the other causes censored (M-35).
  - `offset()` terms add to the linear predictor.
  - The provider is the `provider` argument (DEC-003); the formula has no `strata()` or `cluster()` terms.
- **`weights`.** Case weights, at least 0. Rows with weight 0 are left out of the fit and kept in the measures (M-25).
- **`cluster`, `robust`.** A `cluster` column gives the robust variance clustered by it and implies `robust = TRUE`; `robust = TRUE` alone makes each row its own cluster, as pprof_py does.
- **`ties`, `max_iter`, `tol`.** Breslow by default (pprof_py), or Efron; `survival`'s `iter.max` and `eps` (§A.2).
- **`keep_data`.** Keeps the prepared data and the engine's `coxph` object, which baselines, predictions, and score and dfbeta residuals use; without it they need `data` (DEC-005).
- **Returns** `c("pprof_cox_stratified", "pprof_model")`.

`fit_cox_penalized(formula, data, provider, weights = NULL, alpha = 1, lambda = NULL, n_lambda = 100, lambda_min_ratio = NULL, penalty_factor = NULL, standardize = TRUE, ties = "breslow", max_iter = 100000, tol = 1e-12, keep_data = FALSE, verbose = FALSE)`

- The elastic-net Cox path stratified by provider, pprof_py's `PenalizedCoxPH(strata = provider)`, fitted by `glmnet` (§E.2), on the λ grid of §A.5.
- `coef(model, lambda = NULL)`: the path, or the coefficients at one of the grid's λ values.
- `select_lambda(model, folds = NULL, n_folds = 10, rule = "1se", data = NULL)`: cross-validation as pprof_py's `PenalizedCoxPHCV` (§A.5); returns the model with `selected` and `cross_validation` set.
- `predict(type = "linear_predictor")`.
- Returns `c("pprof_cox_penalized", "pprof_model")`.

`fit_fine_gray(formula, data, provider, cause, id = NULL, weights = NULL, ties = "breslow", max_iter = 20, tol = 1e-9, keep_data = FALSE, verbose = FALSE)`

- **`formula`.** `Surv(time, status) ~ terms` or `Surv(start, stop, status) ~ terms`, the status a factor (or integer codes) with 0 for censoring.
- **`cause`.** The status of the event of interest.
- **`id`.** The subject of each row, required with (start, stop] data, as `survival::finegray()` requires.
- **The model.** Stratified by provider (M-41): `finegray()` estimates the censoring and entry distributions within provider, and the weighted Cox fit is stratified by provider, with the robust variance clustered by subject. This is pprof_py's `FineGrayPH(strata = provider)` (§A.6).
- `predict(type = "cumulative_incidence", newdata)`.
- Returns `c("pprof_fine_gray", "pprof_model")`.

`baseline_hazard(model, data = NULL)`

- For `pprof_cox_stratified`: each provider stratum's baseline cumulative hazard at x = 0 and offset 0 (M-28), from `survival::basehaz()` of the engine fit with the offset factor removed.
- One row per stratum and distinct event time: `provider_id`, `time`, `cumulative_hazard`.

Methods of `pprof_cox_stratified`: `print()`, `summary()`, `coef()`, `vcov()`, `confint()` (Wald, normal), `nobs()` (the number of events, as `nobs.coxph()` counts), `logLik()` (the partial log-likelihood), `predict(type = c("linear_predictor", "risk", "cumulative_hazard", "survival"), newdata, data)`, `residuals(type = c("martingale", "score", "dfbeta"), data)`, `tidy()`, `glance()`, `augment()`. The cumulative hazard, survival, and score and dfbeta residuals come from the engine fit (`survival::survfit()` and `residuals.coxph()`).

### B.2 What each model keeps

**`pprof_cox_stratified`**

- Shared fields:
  - `coefficients`;
  - `vcov`, the robust covariance when robust variance was requested and the model-based one otherwise;
  - `provider_effects = NULL` (M-33);
  - `response`, the event indicator;
  - `linear_predictor`, Xβ without the offset;
  - `providers`, with `n_events` and `person_time`;
  - `convergence`: `iterations`, `converged`, `stop_rule = "relative_loglik"`, `tol`, `max_iter`.
- Own fields: `start`, `stop`, `weights`, `offset`, `naive_vcov` (with robust variance), `loglik`, `n_events`, `expected_events` (§F.1), `martingale_residuals`, and `engine_fit` with `keep_data = TRUE`.
- Memory: about nine doubles per observation, 72 MB at 1,000,000 rows; no design matrix unless `keep_data = TRUE` (DEC-004).

**`pprof_cox_penalized`**

- Shared fields: `coefficients` at the selected λ (before selection, at the last λ); `vcov` a matrix of NA, since no information-based inference is offered; `provider_effects = NULL`.
- Own fields: `lambda`, `coefficient_path`, `selected`, `cross_validation` (the λ values, `cvm`, `cvsd`, the folds, `rule`, `lambda_min`, `lambda_1se`), `alpha`, `penalty_factor`, `standardize`, `ties`, and the survival vectors that cross-validation needs.

**`pprof_fine_gray`**

- Shared fields: `vcov`, the robust covariance clustered by subject; `provider_effects = NULL`.
- Own fields: `naive_vcov`, `cause`, `n_expanded` (the rows of the expanded data), `loglik`, and `engine_fit` with `keep_data = TRUE`, which predictions need, or `data`.

### B.3 Results

| Call on a `pprof_cox_stratified` fit | Result |
|---|---|
| `test_providers(fit, test = "midp" or "exact", null = 0, level = 0.95)` | `provider_id`, `n_obs`, `statistic` (z), `p_value`, `flag`. Two-sided only, as pprof_py; `alternative = "greater"` or `"less"` raises `pprof_error_unsupported_inference` |
| `standardize_providers(fit, standardization, measure = "ratio", interval = "none", "exact", or "midp")` | `provider_id`, `standardization`, `measure`, `n_obs`, `observed` (O_j, or the total O for direct standardization), `expected` (E_j, or E^(j)), `variance` (E_j, the Poisson null variance; missing for direct), `estimate`, and `lower` and `upper` for indirect standardization. pprof_py has no direct limits, so direct standardization with an interval raises `pprof_error_unsupported_inference` |
| `funnel_limits(fit)` | precision E_j; limits 1 ∓ z/√E_j with a floor of 0; flags from the mid-p test (M-39) |
| `profile_providers(fit)` | `effects` is `NULL`; tests, indirect measures, and funnel as for the other families |
| `provider_table(fit)` | adds `n_events` and `person_time` |
| `plot_funnel()`, `plot_caterpillar()`, `plot_flags()`, `plot_volume()` | unchanged: they read the results above |

The volume of a Cox provider in `plot_volume()` stays its number of rows; showing expected events or person-time is a presentation choice for C6.

## C. The data layer

### C.1 Changes to `data_prepare()`

The new arguments' defaults reproduce the current behavior (DEC-092).

- **`response_type = "default"`; `"survival"` for the Cox families.**
  - The response must then be a `Surv` object of type `"right"` or `"counting"`. `fit_fine_gray()` accepts the multi-state types (a factor status) and makes the cause indicator itself.
  - Right-censored times must be finite and greater than 0; counting-process data need start < stop, both finite (§A.1). These are pprof_py's rules.
  - The status is 0/1 (`Surv()`'s coding); `response` holds it, and the new elements `start` (0 for right-censored data) and `stop` hold the times.
- **`weights = NULL`.** A column of finite weights, at least 0, kept as `weights`.
- **`cluster = NULL`.** A column kept as integer codes, `cluster`.
- **`allow_offset = FALSE`.** With `TRUE`, `offset()` terms are allowed and their sum is kept as `offset` (`stats::model.offset()`); with `FALSE`, they are rejected as now.
- **Listwise deletion** (K-03) extends to the `Surv()` variables, the weights, the cluster, and the offset variables.
- **Event counts.** `event_counts = TRUE` counts events from the status, as now, and with survival data adds `person_time`, the sum of stop − start, to the provider table.
- **No screening** for Cox models (`min_provider_size = NULL`, M-32).
- **`validate_pprof_data()`** checks the new elements when they are present: one value per observation, finite, weights at least 0, start < stop.
- **`check_data()`** with survival data reports:
  - near-tied times: distinct times closer than `aeqSurv()`'s tolerance, √ε times their scale (M-23);
  - zero or negative weights;
  - intervals with start ≥ stop;
  - providers with no events or no person-time;
  - aliased covariates;
  - covariates with a large mean (D-64).
- **`model_data_spec()`** records the response type and the weight, cluster, and offset settings, so that `model_prepared_data()` can rebuild the data (DEC-005).

### C.2 The existing families stay unchanged

- The new branches run only when `response_type = "survival"`, or when `weights`, `cluster`, or `allow_offset` is given; no existing caller passes any of them.
- C2 shows it three ways:
  1. the full reference suite (`validation/run-reference.R`) and `devtools::test()` before and after each data-layer commit, bitwise identical;
  2. a test comparing `data_prepare()`'s output on every reference case, with `identical()`, against a snapshot taken before the change;
  3. the toy-model extension test, unchanged.

## D. The contract and the profiling hooks

### D.1 The provider-stratified model on the contract

| Generic | Method |
|---|---|
| `provider_table()`, `provider_index()`, `linear_predictor()`, `observed_outcome()` | shared; the provider table has `n_events` and `person_time`, the linear predictor is Xβ, and the observed outcome is the event indicator |
| `provider_estimates()` | shared, giving `NULL` (M-33) |
| `expected_outcome(model, effect)` | exp(effect) times each observation's expected events at the national baseline (§F.1); `effect` is a single value or one per included provider |
| `null_effect(model, null)` | the number, 0 by default (M-40) |
| `profile_spec()` | §D.2 |
| `inference_capabilities()` | `coef_wald`, `provider_exact`, `provider_midp`, `interval_exact`, `interval_midp`, `standardize_indirect`, `standardize_direct`, `funnel` |
| `predicted_outcome()`, `provider_estimate_se()`, `provider_test()`, `refit_without()` | not implemented: `pprof_error_unsupported_inference` |

### D.2 The family specification

```r
list(
  family = "cox_stratified",
  effect = "log ratio of the provider's hazard to the national baseline",
  null_default = 0, null_options = character(),
  indirect_numerator = "observed", measures = "ratio",
  test_default = "midp", comparison = "ratio", direct_reference = "observed",
  one_sided_extremes = FALSE,
  count_distribution = "poisson",
  variance_function = function(expected) expected,
  funnel = list(measure = "ratio", target = 1, floor = 0, test = "midp",
                precision = function(expected, variance) expected,
                half_width = function(critical, precision) critical / sqrt(precision)),
  measure_limits = cox_measure_limits,       # §F.3, §F.4: limits from O_j and E_j
  direct_by_provider = cox_direct_expected   # §F.2
)
```

The covariate Wald rule is the default one (normal, two-sided).

### D.3 Shared-layer changes

Each default is the current behavior (DEC-092), proved as in §C.2.

1. **`R/model-class.R`.** `validate_pprof_model()` accepts `provider_effects = NULL`, a model without provider-effect estimates; `provider_estimates()` then returns `NULL`.
2. **`R/profile-effects.R`, `R/profile-providers.R`.**
   - `provider_effects()` raises `pprof_error_unsupported_inference` when `provider_estimates()` is `NULL`.
   - `profile_providers()` then leaves `effects` `NULL`, which `new_pprof_profile()` accepts.
3. **`R/profile-spec.R`.** `profile_spec_defaults` gains `count_distribution = "poisson_binomial"`; `measure_limits` and `direct_by_provider` default to `NULL`.
4. **`R/profile-tests.R`.**
   - The test choices gain `"midp"`.
   - When `count_distribution` is `"poisson"`, `profile_test_table()` routes `provider_exact` and `provider_midp` to the Poisson tests of a new `R/inference-poisson.R`. These return p-values and flags by pprof_py's rules (K-140 to K-142), not through `infer_decide()`, and accept only `alternative = "two.sided"`.
   - When it is `"poisson_binomial"`, `provider_midp` raises `pprof_error_unsupported_inference`, and nothing else changes.
5. **`R/profile-standardize.R`.**
   - The interval choices gain `"midp"`.
   - With `measure_limits` in the specification, the limits come from it instead of `profile_effect_limits()` and `profile_measure_limits()`.
   - With `direct_by_provider`, `profile_direct()` uses it instead of the provider estimates and `direct_expected`.
6. **`R/model-capabilities.R`.** `capability_names` gains `provider_midp` and `interval_midp`.
7. **The data layer**, as §C describes.

### D.4 The penalized and Fine–Gray models

- **`pprof_cox_penalized`.**
  - It declares no capability: there is no provider profiling in this phase (M-34), so the profiling functions raise `pprof_error_unsupported_inference`.
  - It offers `coef()`, `predict()`, `select_lambda()`, `print()`, and `tidy()`.
- **`pprof_fine_gray`.**
  - It declares `coef_wald`, with the robust variance.
  - `predict(type = "cumulative_incidence", newdata)` comes from `survival::survfit()` of the engine fit.

## E. The engine adapters

### E.1 survival (DEC-091)

**The fit: `survival`'s fitters.**

- **The call.**
  - Response: `Surv(stop, status)` for right-censored data or `Surv(start, stop, status)` for counting-process data.
  - Data: the design without intercept, the provider codes as `strata`, the offset, and the weights of the rows with positive weight (M-25).
  - Fitter: `survival::coxph.fit()` or `survival::agreg.fit()` respectively, with `init = NULL`, `method = ties`, and `control = coxph.control(eps = tol, iter.max = max_iter)`.
  - These are the fitters `coxph()` calls with the same arguments, documented by `survival` for direct calls. Called directly they give `coxph()`'s results: `coxph.fit()` exactly, `agreg.fit()` on right-censored data as (0, time] within 3e-15 (`dev/design/coxph-facts/14_engine_interfaces.txt`).
  - No `aeqSurv()` step, so times are compared exactly (M-23).
- **Before the call.** No events raises `pprof_error_data` (M-26).
- **After the call.**
  - NA coefficients (aliased covariates, by `survival`'s `toler.chol`) raise `pprof_error_data` naming them (M-26).
  - Reaching `max_iter` warns with `pprof_warning_not_converged`.
- **Extracted components.**
  - The coefficients, the model-based variance, the two log-likelihoods, and the iterations.
  - The linear predictor, recomputed as Xβ uncentered (`survival`'s is centered).
  - The martingale residuals; rows left out of the fit (weight 0) get NA.
- **Engine messages** are captured, and engine errors become `pprof_error_convergence` with `engine_message`, as in the `lme4` adapter (`R/model-mixed.R`).

**The `coxph()` object, where one is needed.**

- **The call.**
  - Data: a data frame of the prepared vectors (`.start`, `.stop`, `.status`, `.provider`, `.weight`, `.offset`, `.cluster`, and the design's columns).
  - Formula: generated, `Surv(.start, .stop, .status) ~ <design columns> + strata(.provider) + offset(.offset)`.
  - `survival::coxph()` with `weights = .weight`, `cluster = .cluster` (the row number when robust variance is asked without a cluster), `ties`, `control = coxph.control(eps = tol, iter.max = max_iter, timefix = FALSE)`, and `model = FALSE`.
- **Uses.**
  1. Fits with robust variance: `$var` is the robust covariance and `$naive.var` the model-based one. Per-row robust variance is `crossprod()` of the dfbeta residuals (14_engine_interfaces.txt), pprof_py's `robust = True`.
  2. On demand: `baseline_hazard()`, `predict(type = "cumulative_hazard" or "survival")`, and score and dfbeta residuals. The engine fit is kept with `keep_data = TRUE`, or rebuilt from `data` and checked against the stored coefficients (DEC-005).
- **Engine identity (C2 tests).**
  - The fitters' results equal `coxph(timefix = FALSE)`'s.
  - The robust path's coefficients equal the fitter's.

### E.2 glmnet (DEC-088)

- **The call.**
  - `glmnet::glmnet(x = design, y = stratifySurv(Surv(start, stop, status), provider codes), family = "cox", weights, offset, alpha, lambda = grid, penalty.factor, standardize, cox.ties = ties, control = list(thresh = tol, maxit = max_iter, fdev = 0, devmax = 1))`.
  - `glmnet` ≥ 5.0 is required: Cox in glmnetpp and coxdev, `cox.ties`, and per-call `control`.
- **The grid.**
  - With `lambda = NULL`, pprof computes pprof_py's grid (§A.5) and passes it, so that `glmnet`'s own grid and early stopping, which could change across versions, never apply.
  - `fdev = 0` and `devmax = 1` keep every λ (14_engine_interfaces.txt).
  - `cox.ties` and the convergence threshold are always passed, since `glmnet` warns that its default ties will change (`04_glmnet_cv_normalization.txt`).
- **Standardization, penalty-factor rescaling, and unpenalized columns** are `glmnet`'s own; pprof_py reproduces them (§A.5).
- **Degenerate columns** (weighted population variance below 10ε) are handled as pprof_py handles them, before the call: left out with a classed warning, with coefficient 0. `glmnet`'s rescaling of the penalty factors over the remaining columns is then pprof_py's rescaling over its non-degenerate columns. M-26's error applies to the unpenalized fits only.
- **Cross-validation (`select_lambda()`).**
  - Folds: event-stratified, drawn with R's random numbers (D-61), or `folds` given.
  - Per fold: a `glmnet` path on the training rows with the full-data grid; the fold's deviance with `glmnet::coxnet.deviance()` as pprof_py defines it, normalized by the held-out event weight (§A.5, M-30).
  - `cvm`, `cvsd`, `lambda_min`, and `lambda_1se` by pprof_py's formulas.
  - Not `cv.glmnet()`, whose normalization changed in 5.0 (04).
- **The difference from pprof_py's proximal-Newton solver** is absorbed by the `penalized_path` tier: 2.2e-7 was measured at `thresh = 1e-12` (`09_penalized_glmnet.txt`).

### E.3 Fine–Gray

- **The transform.** `survival::finegray(Surv(.start, .stop, .status) ~ . + strata(.provider), data, etype = cause, id = .id)` on the prepared data, with a factor status. pprof_py's transform equals `finegray()`'s row for row, delayed entry included (`05_robust_finegray.txt`).
- **The fit.**
  - `survival::coxph(Surv(fgstart, fgstop, fgstatus) ~ <covariates> + strata(.provider), weights = fgwt times the case weight, cluster = .id, ties, control = coxph.control(eps = tol, iter.max = max_iter, timefix = FALSE))`.
  - Case weights multiply the Fine–Gray weights only and never enter the censoring or entry distributions, as in pprof_py (§A.6).
  - The robust variance with Breslow ties is `survival`'s (D-56).

## F. Algorithms and their cost

### F.1 Expected events at the national baseline

K-136, K-137.

- Computed once at fit time and stored per observation as `expected_events`; `expected_outcome()` scales it.
- Steps:
  1. Compute η_i = x_i'β̂ + o_i and r_i = exp(η_i − max η).
  2. Take the distinct event times and the number of events d(t) at each.
  3. Bin entries and exits with `findInterval()` and take suffix sums, giving the risk-set sums RS(t) = Σ_{start_i < t ≤ stop_i} r_i as the difference of two suffix sums, as pprof_py computes them (K-136).
  4. Λ0 is the cumulative sum of d(t) / RS(t).
  5. Each observation's expected events are r_i [Λ0(stop_i) − Λ0(start_i)].
- Cost: O(n log n); 0.34 s at 1,000,000 rows in plain R (`07_cox_fit_timing_r.txt`), with Σ_j E_j = O exactly.

### F.2 Direct standardization

K-138.

- E^(j) is the sum over provider j's event times t of d_j(t) RS(t) / RS_j(t). RS_j(t) comes from the same suffix sums within provider j, and RS(t) from the national sums by binary search.
- Cost: O(n log n).

### F.3 The exact test and its limits

K-140. Closed forms with `ppois()`, `qchisq()`, and Byar's approximation; O(m).

### F.4 The mid-p test and its limits

K-141.

- The test is a closed form, O(m).
- The limits come from root finding per provider: `uniroot()` on pprof_py's equation, bracket, and split point, with its tolerances (§A.4). R's `uniroot()` and SciPy's `brentq` take different paths to a root within those tolerances, which the `root` tier allows (§G.2).
- Target: under 1 s at 3,000 providers, against pprof_py's 50 s (`07_cox_fit_timing.txt`).

### F.5 Fits

- `survival`'s fitters: O(np²) per iteration plus O(n log n).
- `glmnet`'s path.
- Cross-validation: K + 1 paths.

### F.6 Memory

As §B.2.

## G. Validation

### G.1 Fixtures (DEC-093)

**Imported cases.** pprof_spark's six Cox cases (`fixtures/cox/`), each run with both tie methods:

- `tiny-ties`, `rc-unstratified`, `rc-stratified`, `rc-stratified-weights-offset`, `lt-stratified`, and `lt-weights-offset`;
- inputs exact in text;
- pprof_py's outputs: default and tight fits, iterates, ℓ, U, and I at β = 0 and at a fixed β, baselines, residuals, robust variances, measures, and tests;
- `survival`'s fits.

**New cases (C1).**

1. Provider scale: 20,000 rows, 1,000 providers, delayed entry, integer days.
2. Recurrent events: several rows per patient, SHR-shaped, with clusters.
3. Near-tied times, with `timefix` stated on the R side.
4. Zero weights.
5. Competing risks with and without delayed entry: pprof_py's `competing_risks_simple` and `competing_risks_truncated`.
6. Penalized: pprof_py's `penalized_wide`, strata, offset, weights, left-truncation, and combined data, with their fold IDs.
7. A covariate with a large mean (D-64).
8. Providers with no events, and with E_j = 0.

**The generator.**

- Python: `dev/reference/cox/generate.py`, adapted from pprof_spark's generator. Its `requirements.txt` pins pprof_py at `9320766` and the stack of pprof_spark's lock (Python 3.12, NumPy, SciPy, pandas, numba).
- R: `dev/reference/cox/survival.R`, run in the isolated library with `survival` and `glmnet` pinned.
- Output: JSON with doubles as hexadecimal strings, converted to RDS by an R step, and `manifest.json` with the versions and the SHA-256 of every file.
- Tests never need Python.

### G.2 Tolerance tiers

These are proposed values. C1 calibrates them with negative controls (brief §3.5). The pprof_py comparisons start from pprof_spark's classes, calibrated on the same cases.

| Tier | Compares | Proposed atol, rtol | Basis |
|---|---|---|---|
| `cox_engine` | pprof against direct `survival` and `glmnet` calls, same platform | 0, 0 for the engines' outputs | the same computation (`14_engine_interfaces.txt`) |
| `cox_function` | ℓ, U, and I at fixed β against pprof_py | 0, 1e-12 | pprof_spark's T-fn |
| `cox_coefficient` | tight-fit coefficients against pprof_py | 1e-10, 1e-8 | T-coef |
| `cox_variance` | standard errors and covariances against pprof_py | 0, 1e-7 | T-var |
| `cox_baseline` | baselines, and expected counts given each side's β̂ | 0, 1e-8 | T-base |
| `cox_residual` | residuals | 1e-9, 0 | T-res |
| `cox_statistic` | test statistics; p-values compared on the statistic | 0, 1e-8 | T-test, T-p |
| `penalized_path` | coefficient paths at the same λ values | 1e-6, 0 | 2.2e-7 measured (`09_penalized_glmnet.txt`) |
| `closed_form`, `probability`, `root` (existing) | measures given the same β̂; p-values; mid-p limits | as now | `tests/testthat/helper-tolerances.R` |

- **Fits at default settings:** iteration counts must match exactly, and coefficients must agree within the last Newton step (D-57).
- **Flags** match exactly, except for providers within tolerance of a threshold, which the equivalence report lists.

### G.3 Test layers (brief §6)

- **A. Reference comparisons:** §G.1's cases, both tie methods.
- **B. Engine identity:** the fitters, `coxph()`, and `glmnet` called directly (§E).
- **C. Closed-form units:**
  - expected counts by hand;
  - Σ_j E_j = O;
  - invariance to a common factor in exp(η);
  - direct measures against a per-provider recomputation;
  - the national baseline against `basehaz()` of `coxph(Surv(...) ~ offset(η), ties = "breslow")`, allowing for its offset factor;
  - Poisson tests against `ppois()`, and against `poisson.test()` where the two coincide.
- **D. Independent references:**
  - `coxph()` with provider indicators on small data (the same partial likelihood without strata);
  - the simulation of §G.4.
- **E. Metamorphic tests:**
  - row order;
  - provider relabeling;
  - the order of data columns (D-63);
  - rescaling time;
  - a constant shift of the offset, which leaves the measures unchanged;
  - duplicated rows against weight 2, with Breslow ties.
- **F. Edge cases:** the brief's §6, F.
- **G. Regression tests:** one per register entry, D-56 to D-74.

### G.4 Simulation

In C6, the size and coverage of the exact and mid-p tests and limits under the null, with provider strata, as `validation/run-simulation.R` does for the other families.

### G.5 CI

- The Cox reference comparisons run on every platform: `survival`'s results did not change across versions or platforms (`02_r_reference_drift.txt`).
- The `glmnet` tests skip without `glmnet` ≥ 5.0.
- Regenerating the fixtures is a manual workflow (brief §12).

## H. Dependencies

- **`survival`:** Imports, version 3.5-8 or later. pprof_py was validated against 3.5-8, and 3.5-8 to 3.8-12 give the same results (`02_r_reference_drift.txt`).
- **`glmnet`:** Suggests, version 5.0 or later (DEC-088).
- **Nothing else.** Python appears only in the fixture generator.

## I. Benchmarks

- **The grid, in `dev/bench/`, with paired runs (DEC-038):**
  - rows: 10^4, 10^5, 10^6;
  - providers: 100, 1,000, 7,500;
  - covariates: 5, 20, 50;
  - with delayed entry, daily ties, an offset, and weights.
- **Tasks:**
  - fits, Breslow and Efron;
  - fits with robust variance;
  - measures, indirect and direct;
  - tests with limits, exact and mid-p;
  - a penalized path with 50 covariates, and 10-fold cross-validation.
- **Comparators:**
  - the direct engine calls, in the same session, which gate the brief's §3.7: at most 10% overhead;
  - pprof_py v0.7.0, in a separate process, reported.
- **Peak memory** with `gc()`'s maximum used.

## J. Register entries

| Register | Entries |
|---|---|
| `dev/CONVENTIONS.md`, "Cox models (pprof_py v0.7.0)" | K-131 to K-147 |
| `dev/DISCREPANCIES.md`, "The CoxPH phase" | D-56 to D-74 |
| `dev/OPEN_QUESTIONS.md`, "The CoxPH phase" | M-23 to M-41, decided under the project lead's delegation |
| `dev/DECISIONS.md` | DEC-086 to DEC-093 |
