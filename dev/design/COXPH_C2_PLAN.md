# CoxPH Phase C2 plan: the data layer and the provider-stratified Cox model

> **Status: approved by the project lead on 2026-10-08, with the seven decisions of §6 as recommended** (DEC-099 to DEC-104). It implements the brief's §4 row C2 (`dev/coxph_brief.md`; also §3.3, §3.7, §5.1, §5.2, §5.6, §6) and COXPH_DESIGN §B to §E, under DEC-086 to DEC-098.

C2 adds survival data to the data layer, the `survival` adapter, and `fit_cox_stratified()` with its object, coefficient inference, baselines, residuals, predictions, and methods. The existing families stay bitwise identical. The evidence gathered for this plan is in §2; the scripts are `dev/design/coxph-facts/17` to `20`.

## 1. Deliverables

| # | Deliverable | Where |
|---|---|---|
| 1 | Survival data in `data_prepare()`: `Surv()` responses (right-censored and counting-process), entry times, case weights, clusters, `offset()` terms, and person-time in the provider table | `R/data-survival.R` (new), `R/data-prepare.R`, `R/data-formula.R`, `R/data-frame.R`, `R/data-class.R`; `model_data_spec()` and `model_prepared_data()` in `R/model-class.R` |
| 2 | `check_data()` for survival data | `R/check-data.R`, `R/present-print.R` |
| 3 | The `survival` adapter (DEC-091, DEC-098) | `R/model-survival.R` (new) |
| 4 | `fit_cox_stratified()` and the `pprof_cox_stratified` object | `R/model-cox-stratified.R` (new) |
| 5 | Coefficient inference: `test_coefficients()`, `confint()`, `summary()`, `tidy()` | the shared methods; one option of the covariate rule in `R/inference-coefficients.R` |
| 6 | `baseline_hazard()`, `residuals()`, `predict()`, `nobs()`, `logLik()` | `R/model-cox-stratified.R` |
| 7 | The contract methods, and the two shared hooks that a model without provider effects needs (COXPH_DESIGN §D.3, items 1 and 2) | `R/model-cox-stratified.R`, `R/model-class.R`, `R/profile-effects.R` |
| 8 | `print()`, `glance()`, `augment()` | `R/present-print.R`, `R/present-tidy.R` |
| 9 | `survival` moved from Suggests to Imports (≥ 3.5-8, COXPH_DESIGN §H); `Surv()` re-exported | `DESCRIPTION`, `R/pprof-package.R`; `NAMESPACE` regenerated |
| 10 | Tests: the data layer, the `data_prepare()` snapshot, `check_data()`, engine identity, the fit and its methods, and the Cox fixtures with one regression test per register entry (§4) | `tests/testthat/` |
| 11 | Benchmarks: each fit against the engine calls it wraps, paired (DEC-038) | `dev/bench/cox/run_paired.R` (new), `dev/bench/results/` |
| 12 | Registers, help pages, the pkgdown index, `NEWS.md`, ARCHITECTURE §E.3 and §E.6 as built, the status document | `dev/`, `man/` (generated), `_pkgdown.yml`, `NEWS.md` |

**Not in C2** (brief §4): the expected counts at the national baseline (the `expected_events` field of COXPH_DESIGN §B.2 and `expected_outcome()`), standardized measures, Poisson tests, intervals, flags, funnels, plots, and `profile_providers()` for Cox fits, with COXPH_DESIGN §D.3 items 3 to 6 (all C3); penalized models (C4); Fine–Gray, and the profiling of cause-specific models (C5); the vignette and the simulation study (C6).

## 2. Evidence gathered for this plan

With survival 3.8-12 and R 4.4.0 on the C1 machine; 17 and 18 use the benchmark generator's data (`dev/bench/cox/scenarios.R`) and 20 the Cox fixtures. The outputs are beside the scripts.

1. **The fitters give `coxph()`'s fit bitwise only when called as `coxph()` calls them** (17, 18). Before it calls `coxph.fit()` or `agreg.fit()`, `coxph()` subtracts the mean of a nonzero offset, passes `nocenter = c(-1, 0, 1)` (columns whose values are all in {−1, 0, 1} are not centered), and codes the strata as integers. Called with those arguments, both fitters equal `coxph(timefix = FALSE, robust = FALSE)` bitwise in coefficients, variance, log-likelihoods, iterations, and martingale residuals, at 100,000 and 1,000,000 rows. Called as C1's baseline called `agreg.fit()` (the raw offset, no `nocenter`), the coefficients move by up to 3.5e-16 and the log-likelihood in its last digits. Sorting the rows by provider, as `data_prepare()` does, did not change the coefficients.
2. **A cheaper robust variance, bitwise `coxph()`'s** (17). `coxph()`'s robust step builds an object from the fitter's result (adding `x`, `y`, `weights`, `strata`, and `terms`) and applies survival's `residuals.coxph(type = "dfbeta", collapse = cluster, weighted = TRUE)`, then `crossprod()`. Doing exactly that on the adapter's fitter result gives `coxph(cluster = )`'s robust variance bitwise, with one cluster per row and with 40 clusters, for both fitters. At 1,000,000 rows of counting-process data it took 2.0 s against 20.7 s for `coxph()` with one cluster per row, which also builds a model frame, computes the concordance, and adds a robust score test at β = 0; the fit itself took 4.3 s.
3. **Timings here vary too much for unpaired comparisons** (18). Four fits of the same 1,000,000 rows in one process took 4.8 s to 11.6 s, whatever the row order and arguments, and C1's baseline recorded 17.2 s for this scenario. The C2 benchmarks time each fit and its engine call in the same session (§4.5).
4. **`coxph()` turns the robust variance on for non-integer weights** (brief §3.3, row 3), so every direct `coxph()` call in the tests passes `robust = FALSE` (17).
5. **The fitters' signals** (survival 3.8-12's source). `agreg.fit()` stops on data without events and `coxph.fit()` does not check. `coxph.fit()` signals reaching `iter.max` only by its warning "Ran out of iterations and did not converge"; `agreg.fit()` also records it in `info`. Aliased columns come back as NA coefficients.
6. **pprof_py's covariate p-values are upper tails.** Its `wald_statistics()` computes 2·`norm.sf(|z|)` (`pprof_py/inference/survival/inference.py:39-45`), and its intervals β ± Φ⁻¹(1 − α/2)·se with α = 1 − level, which is the package's default interval rule. The package's default p-value rule computes 2(1 − Φ(|z|)) (K-100), which is 0 for |z| above 8.3: in the `lt-stratified` fixture the first coefficient has z = 9.15 and pprof_py's p = 5.5e-20.
7. **What `Surv()` does with the inputs** (19). `all.vars()` of `survival::Surv(time, status)` is `time` and `status`. `model.frame()` fails when the formula's environment cannot see `Surv()`. `Surv()` turns a 0/1, logical, or 1/2 status into 0/1; it reads a 0/1/2 status as 1/2 coding (1 becomes 0, 2 becomes 1, 0 becomes NA) and a 2/3 status as NA, with a warning; it turns start ≥ stop into NA, with a warning; it accepts right-censored times of 0 and below. `model.offset()` sums several `offset()` terms.
8. **The baseline at x = 0 and offset 0** (20). On the two fixture cases with weights and an offset, `survfit()` of the fit with every covariate and the offset at 0 equals pprof_py's raw baseline, at x = 0 and offset 0, within 6.1e-10 relative with both tie methods. `basehaz(centered = FALSE)` equals pprof_py's reported `baseline_hazard_` instead: both carry the factor exp(the weighted mean offset), 2.7e-3 and 2.6e-2 relative here (D-60).
9. **Where the fixtures are.** The core set (`tests/testthat/fixtures/cox/`) has `tiny-ties`, `rc-stratified`, `lt-stratified`, `near-ties`, `empty-providers`, `competing-simple`, and `penalized-strata`. `zero-weights`, `large-mean`, `recurrent`, `rc-stratified-weights-offset`, and `lt-weights-offset` are in the full set (`validation/fixtures/cox/`, DEC-096), whose comparisons run under `devtools::test()` and not under `R CMD check`; unit tests carry the same decisions without fixtures (§4.3).

## 3. Approach

### 3.1 Survival data in `data_prepare()` (COXPH_DESIGN §C.1, DEC-092)

New arguments, after the existing ones: `response_type = "default"`, `weights = NULL`, `cluster = NULL`, `allow_offset = FALSE`. With the defaults no new code runs and the `pprof_data` object has exactly today's elements and settings: new elements, settings, and `data_spec` fields are added only when used, so that the existing families' data and model objects stay identical (§4.1).

With `response_type = "survival"`:

- **The formula.** The response is a `Surv()` call (`Surv()` or `survival::Surv()`) of type `"right"` or `"counting"`. `strata()`, `cluster()`, `tt()`, `frailty()`, `ridge()`, and `pspline()` terms are rejected, since the provider is the strata (DEC-003). Parsed with `terms()` and its specials.
- **The values**, after listwise deletion (COXPH_DESIGN §A.1, K-131): right-censored times finite and greater than 0; counting-process starts finite and below their stops; the status 0/1, which `Surv()` makes of 0/1, logical, and 1/2 codings (D-74). Where `Surv()` turns an invalid status or start ≥ stop into NA (§2.7), the data layer raises `pprof_error_invalid_input` saying what is invalid in how many rows, instead of letting the NA delete them; `Surv()`'s warning is muffled.
- **What is kept:** `response` (the status), `start` (0 for right-censored data), `stop`; `weights`, finite and at least 0, zeros allowed (M-25); `cluster`, as the integer codes `coxph()` makes (a factor's codes, otherwise the order of first appearance in the prepared rows), so that clusters are summed in `coxph()`'s order; `offset` (with `allow_offset = TRUE`), the finite sum of the `offset()` terms; and `settings$response_type`.
- **Listwise deletion** (K-03) extends to the `Surv()` variables, the variables of the offset terms, the weights, and the cluster.
- **The provider table**, with `event_counts = TRUE`: events counted from the status of every row, those with weight 0 included (K-137), and `person_time`, Σ(stop − start) (K-139). No screening (M-32).
- `validate_pprof_data()` checks the new elements when they are present. `model_data_spec()` records the survival settings, and `model_prepared_data()` passes them back to `data_prepare()` (DEC-005).

`Surv()` is re-exported from `survival`, as `tidy()`, `glance()`, and `augment()` are from `generics`, so that `library(pprof)` suffices to write a Cox formula (§2.7; proposed DEC-103).

### 3.2 `check_data()` for survival data (brief §5.1, COXPH_DESIGN §C.1)

`check_data(formula, data, provider, weights = NULL, cluster = NULL)`. With a `Surv()` response it adds a `survival` element, which `print()` lists, and still reports instead of stopping (DEC-073):

- near-tied times: the rows whose times `survival::aeqSurv()` would merge, which is survival's own rule (M-23);
- zero and negative weights;
- rows with start ≥ stop or a right-censored time of 0 or less, and invalid statuses;
- providers with no events, and with no person-time;
- aliased covariates: columns linearly dependent on the others within providers (QR with pivoting of the design centered within providers, as D-38's check does), which a fit stratified by provider cannot estimate;
- covariates with a large mean: |mean| above 100 standard deviations (a calendar year, for example), which survival handles by centering and pprof_py does not (D-64); the threshold is a named constant (proposed DEC-104).

The existing checks (missing values, near-zero variance, correlations, variance inflation) run on the design as now, and the missing-value table gains the weight, cluster, and offset variables. To report rather than stop, `check_data()` uses the data layer's parsing and extraction without its value checks. Without a `Surv()` response nothing changes, which the reference cases of `data_check()` confirm (§4.1).

### 3.3 The survival adapter (`R/model-survival.R`; DEC-091, DEC-098)

- **The fit.** `survival::coxph.fit()` for right-censored data, `survival::agreg.fit()` for counting-process data, on the rows with positive weight (M-25), in `data_prepare()`'s order, with the arguments `coxph()` passes (§2.1; proposed DEC-100): the design without intercept; `Surv(stop, status)` or `Surv(start, stop, status)`; integer strata codes of the providers; the offset minus its mean, or 0 without one; the weights, or `NULL`; `init = NULL`; `method = ties`; `control = coxph.control(eps = tol, iter.max = max_iter, timefix = FALSE)`; and `nocenter = c(-1, 0, 1)`. No `aeqSurv()` step (M-23).
- **Before the call:** no events among the fitted rows raises `pprof_error_data` (M-26).
- **Conditions.** survival's "Ran out of iterations" warning becomes a single `pprof_warning_not_converged`, with `converged = FALSE`; its other warnings (a coefficient that may be infinite) pass through, as lme4's do in the lme4 adapter; an engine error becomes `pprof_error_convergence` with `engine_message`; NA coefficients raise `pprof_error_data` naming the covariates (M-26).
- **What is extracted:** the coefficients, the model-based variance, the log-likelihoods at β = 0 and at β̂, the iterations and convergence, the martingale residuals (NA for rows with weight 0), and the linear predictor recomputed as Xβ, uncentered, for every row (K-135).
- **The robust variance** (proposed DEC-099, answering DEC-098). With `robust = TRUE` or a `cluster`: `residuals.coxph(type = "dfbeta", collapse = cluster, weighted = TRUE)` on the fitter's result, made into the object `coxph()` builds before its robust step, then `crossprod()` (§2.2). Clusters are the cluster codes, or one per fitted row. The model-based variance is kept as `naive_vcov`. This depends on what `residuals.coxph()` reads from that object; the engine-identity tests pin it against `coxph()`, and if a later survival breaks it, the fit falls back to DEC-091's `coxph()` call.
- **The `coxph()` object** (DEC-091), for `baseline_hazard()`, the cumulative-hazard and survival predictions, and the score and dfbeta residuals: `survival::coxph()` on a data frame of the prepared vectors (`.start`, `.stop`, `.status`, `.provider`, `.weight`, `.offset`, and the design's columns under generated names), with the generated formula `Surv(...) ~ <columns> + strata(.provider) + offset(.offset)`, the fit's settings, `robust = FALSE`, and `model = FALSE`. With `keep_data = TRUE` it is built at fit time and kept as `engine_fit`; otherwise the methods that need it build it from `data`, after `model_prepared_data()` has checked the data (DEC-005), and check its coefficients against the stored ones.

### 3.4 `fit_cox_stratified()` and its object (COXPH_DESIGN §B.1, §B.2)

`fit_cox_stratified(formula, data, provider, weights = NULL, cluster = NULL, ties = "breslow", robust = FALSE, max_iter = 20, tol = 1e-9, keep_data = FALSE, verbose = FALSE)` (NAMING §10): `data_prepare(response_type = "survival", allow_offset = TRUE, event_counts = TRUE, ...)`, the adapter, and `new_pprof_model(class = "pprof_cox_stratified")`. A `cluster` implies the robust variance. With `verbose`, it reports the events, the rows left out for weight 0, and the iterations.

The object: the shared fields, with `provider_effects = NULL`, `response` the status, `linear_predictor` Xβ, and `vcov` the robust covariance when one was requested; its own fields `start`, `stop`, `weights` and `offset` (NULL when absent), `naive_vcov` (robust fits), `loglik` (at β = 0 and at β̂), `n_events` (the events among the fitted rows, `coxph()`'s `nevent`), `n_zero_weight` (rows left out of the fit), `martingale_residuals`, and `engine_fit` (with `keep_data`); `convergence` with `iterations`, `converged`, `stop_rule = "relative_loglik"`, `tol`, and `max_iter`; and `spec` with the family, ties, robust, the weight and cluster columns, `max_iter`, `tol`, and `keep_data`. It has `new_pprof_cox_stratified()` and `validate_pprof_cox_stratified()`, and keeps about eight doubles per row (C3 adds `expected_events`).

### 3.5 The contract, and the shared hooks C2 needs (COXPH_DESIGN §D)

- `inference_capabilities()`: `coef_wald` only. C3 adds the profiling capabilities together with their hooks.
- `profile_spec()`: in C2 only the fields today's code reads (`family = "cox_stratified"`, `effect`, `null_default = 0`, `null_options`, `indirect_numerator = "observed"`, `measures = "ratio"`) and the covariate rule of §3.6; C3 completes COXPH_DESIGN §D.2.
- The shared accessors serve the model unchanged; `provider_estimates()` gives `NULL`.
- Two hooks of COXPH_DESIGN §D.3 come forward from C3, since without them the model cannot be built or safely passed to the profiling functions: `validate_pprof_model()` accepts `provider_effects = NULL` (item 1), and `provider_effects()` raises `pprof_error_unsupported_inference` when `provider_estimates()` is `NULL` (item 2; `profile_providers()` calls it first). Every profiling function then raises `pprof_error_unsupported_inference` on a C2 Cox fit. Items 3 to 6 stay in C3 (proposed DEC-102).

### 3.6 Coefficient inference

`test_coefficients(test = "wald")`, `confint()`, `summary()`, and `tidy()` work through the shared code with the family's covariate rule (DEC-046): z = β̂/se, the interval β̂ ∓ Φ⁻¹(1 − α/2)·se (the default interval rule, which is pprof_py's), and the p-value 2Φ̄(|z|) computed as an upper tail, as pprof_py computes it (§2.6). The rule gains that p-value form as an option (`p_value = "two_sided_upper"`), with today's form as the default (proposed DEC-101 and K-148). Likelihood-ratio and score tests are not declared.

### 3.7 Baselines, residuals, and predictions

- `baseline_hazard(model, data = NULL)`, a generic (C5's Fine–Gray model will have a method): each provider's baseline cumulative hazard at x = 0 and offset 0 (M-28, D-60), from survival's `survfit()` of the engine fit with every covariate and the offset at 0 (§2.8), at the provider's distinct event times (pprof_py's table). A data frame with `provider_id`, `time`, and `cumulative_hazard`. It underflows to 0 where x = 0 lies far from the data, as survival's and pprof_py's do (D-64's `large-mean` case).
- `residuals(type = c("martingale", "score", "dfbeta"), data = NULL)`: the martingale residuals from the fit; score and dfbeta residuals from `residuals.coxph()` of the engine fit, with survival's defaults (dfbeta weighted). One row per observation, in the order of the input data, NA for rows with weight 0.
- `predict(type = c("linear_predictor", "risk", "cumulative_hazard", "survival"), newdata = NULL, data = NULL)`: the linear predictor x'β̂ + offset and the risk, its exp(), uncentered (K-135), without pprof_py's clipping (D-64), for the fit's observations or for `newdata`; the cumulative hazard and the survival function from `survfit()` of the engine fit, for each row of `newdata` (required) at its provider's event times, as pprof_py's `predict_cumulative_hazard()`: a data frame with `row`, `provider_id`, `time`, and the value. Providers the model does not have give NA, with `pprof_warning_unknown_providers`.
- `nobs()`: the events of the fit, as `nobs.coxph()`. `logLik()`: the partial log-likelihood at β̂ with df = p and nobs = the events, as `logLik.coxph()`.

### 3.8 Presentation

- `print()`: the family and tie method, observations, providers, events, rows left out for weight 0, convergence, the variance (model-based, robust with one cluster per row, or clustered by the named column), and the coefficients.
- `summary()` and `tidy()`: the shared methods, with the Cox rule.
- `glance()`: the shared columns (`auc` missing) and `n_events`, with `loglik` at β̂ and `aic` and `bic` as `AIC()` and `BIC()` give for the `coxph()` fit.
- `augment()`: per observation, `row`, `provider_id`, `observed` (the status), `fitted` (the expected number of events under the fitted model, survival's `predict(type = "expected")`, which is the status minus the martingale residual), and `residual` (the martingale residual); missing for rows with weight 0 (proposed DEC-103). broom's `augment.coxph()` puts the linear predictor in `.fitted`; the package keeps NAMING §5's rule that `residual` is `observed` minus `fitted`.

## 4. How equivalence is checked

### 4.1 The existing families stay bitwise identical (COXPH_DESIGN §C.2)

1. `devtools::test()` and `validation/run-reference.R` at the C1 head (`78e3e15`) before any change, and again after each commit that touches a shared file (the data layer, `R/model-class.R`, `R/check-data.R`, `R/inference-coefficients.R`, `R/profile-effects.R`): no failure, the same counts of tests and expectations plus the new ones, and an equivalence report equal to the committed one but for its date and commit.
2. A snapshot of `data_prepare()`'s output. `dev/tools/data_prepare_snapshot.R` runs every core reference case with a recording binding of `new_pprof_data()`, through which `data_prepare()` and the compatibility conversions build every `pprof_data` object, and saves each distinct object's signature: every element, doubles and integers by bit checksums (`reference_signature()`, DEC-018). It runs in the first code commit, before any data-layer change, and writes `validation/fixtures/data-prepare-snapshot.rds`, outside the shipped fixtures, whose budget is spent (DEC-096). `tests/testthat/test-data-prepare-snapshot.R` replays the cases and compares with `identical()`, behind `skip_on_cran()`, on the fixtures' platform (DEC-080), when the snapshot is present.
3. The toy-model extension test, unchanged.

### 4.2 Engine identity (DEC-043's pattern; `cox_engine`, atol and rtol 0)

On every core Cox case with both tie methods, at default and tight control: the fit against `coxph(timefix = FALSE, robust = FALSE)` on the same prepared rows (coefficients, `vcov`, log-likelihoods, iterations, martingale residuals); the robust fits against `coxph(cluster = )`, with one cluster per row and with a cluster column (`vcov` and `naive_vcov`); `engine_fit`; and `baseline_hazard()`, the predictions, and the score and dfbeta residuals against direct `survfit()`, `basehaz()`, and `residuals()` calls on it. All bitwise.

### 4.3 The Cox fixtures, with one regression test per register entry

`tests/testthat/test-cox-reference.R` compares the package with pprof_py's outputs under the C1 tiers (DEC-097): the core cases always, the full set when present (`skip_on_cran()`). Tight fits use the generator's control, `tol = 1e-11` and `max_iter = 100`; `helper-cox-fixtures.R` gains the package fit of a case. Per case and tie method: default fits (iterations exactly; coefficients within the longer of the two last Newton steps), tight coefficients (`cox_coefficient`), standard errors and covariances (`cox_variance`), log-likelihoods (`cox_function`), martingale, score, and dfbeta residuals (`cox_residual`), robust variances (`cox_variance`), the baseline at x = 0 against pprof_py's raw baseline and the predictions of its three profiles (`cox_baseline`), and the coefficient table (its standard errors under `cox_variance`, its p-values through their statistics).

| Entry | Regression test |
|---|---|
| D-56 | The robust variances of `lt-stratified` (core), `recurrent`, and `lt-weights-offset` (full) equal survival's in the fixture under `cox_variance` for both tie methods; with Breslow ties pprof_py's differ beyond the tier, with Efron ties they agree within it |
| D-57 | Every case's default fit: iterations equal to pprof_py's, coefficients within the last-step bound; tight fits within `cox_coefficient` |
| D-58 | `zero-weights` (full): Breslow fits equal pprof_py's under the tiers, Efron fits equal survival's on the positive-weight rows; a unit test: zero weights give, bitwise, the fit without those rows, which the provider table keeps |
| D-59 | `pprof_error_data`, naming the covariates, for collinear, constant, and within-provider-constant covariates; `pprof_error_data` for data without events |
| D-60 | `baseline_hazard()` against pprof_py's `baseline_hazard_` divided by exp(its `offset_mean`) on `rc-stratified-weights-offset` and `lt-weights-offset` (full), and against its raw baseline on every case; a unit test: a constant added to the offset leaves `baseline_hazard()` unchanged to rounding |
| D-62 | Missing values in the times, status, covariates, weights, cluster, and offset give, bitwise, the fit without those rows |
| D-63 | Reordering the data's columns gives the identical fit (C3 extends it to the measures) |
| D-64 | `large-mean` (full): coefficients, standard errors, and log-likelihoods equal pprof_py's under the tiers; residuals, robust variances, and the baseline equal survival's in the fixture and are finite where survival's are; a unit test with a covariate near 3,000 against direct survival calls |
| D-74 | A status coded 1/2, or logical, gives the fit of the status coded 0/1, bitwise |

Also: `near-ties` (M-23), whose fits equal pprof_py's under the tiers while survival's `timefix = TRUE` fits differ beyond them; `empty-providers`, whose providers without events have no baseline rows; and `competing-simple`, where `Surv(time, event == k)` gives pprof_py's cause-specific fits (M-35; C5 profiles them). ℓ, U, and I at a fixed β are engine outputs that no package function returns; C1's fixture tests compare them.

### 4.4 Unit, metamorphic, and edge-case tests

- `test-data-survival.R`: every rule of §3.1 with its condition class.
- `test-check-data-survival.R`: each report of §3.2, and `check_data()` unchanged without a `Surv()` response.
- `test-model-survival.R`: the adapter's arguments, conditions, and robust path.
- `test-model-cox-stratified.R`: the arguments and their errors; the object and its validator; every method; the contract (the profiling functions raise `pprof_error_unsupported_inference`; `provider_estimates()` is `NULL`); `keep_data = TRUE` against `data` (DEC-005); the fit's part of the brief's §6 E, with DEC-043's rules: providers' blocks reordered and labels that keep their order (bitwise), rows shuffled within providers and duplicated rows against weight 2 with Breslow ties (`cox_coefficient` at tight control), times doubled (bitwise); and the fit's part of §6 F: providers with one row or no events, delayed entry at an event time (K-131's risk set), daily ties, separation (survival's warning passes through), a stratum without events, and a provider whose rows all have weight 0.

### 4.5 Benchmarks (brief §3.7; DEC-038, DEC-098)

`dev/bench/cox/run_paired.R` runs the C1 grid in fresh processes that alternate the engine call and the fit on the same data (engine, fit, engine, fit), with the package installed with `--preclean` (the harness's `bench_install_working_tree()`), and records peak memory:

- `fit_cox_stratified()` with Breslow and with Efron ties, against the fitter call it makes, with the inputs prepared outside the timing, as `run_engines.R` does;
- the robust fit (one cluster per row) against the fitter call plus `residuals.coxph()`, and against `coxph(cluster = row)`, DEC-098's comparator.

A fit fails when, in every round, its median and fastest times are more than 10% above the engine call's and its median is at least 0.05 s above (DEC-038's rule). The report, `dev/bench/results/cox-c2-paired-<date>-windows.md`, gives the ratios, the verdicts, and C1's pprof_py times beside them. C1's `cox-engines-20261008-windows.csv` stays the baseline of record, but its engine calls ran on rows in the generator's order with the raw offset (§2.1, §2.3), so the paired runs, not the CSV, decide.

## 5. Commit order

Small commits on `coxph/phase-2`. (S) marks the commits after which §4.1's checks run.

1. `docs: the CoxPH C2 plan`: this plan, the fact scripts 17 to 20, and the status entry.
2. `tests: a snapshot of data_prepare() on the reference cases`: the recorder, the snapshot from the unchanged code, and its test.
3. `data: survival responses, weights, clusters, and offsets` (S): the data layer, `model_data_spec()` and `model_prepared_data()`, `survival` in Imports, the `Surv()` re-export, and `test-data-survival.R`.
4. `model: models without provider effects` (S): `validate_pprof_model()`, the `provider_effects()` guard, and their help.
5. `inference: the covariate p-value as an upper tail` (S).
6. `check: survival data in check_data()` (S).
7. `model: the survival adapter`, with `test-model-survival.R`.
8. `model: fit_cox_stratified() and its methods`: the model file, the presentation methods, their tests, help, and the pkgdown index.
9. `tests: the stratified Cox model against the Cox fixtures`.
10. `bench: the stratified Cox fit against its engine calls`.
11. `docs: the CoxPH C2 registers and documents`, then the gate (`/phase-gate`).

## 6. Decisions this plan asks for

| # | Decision | Recommendation | Register |
|---|---|---|---|
| 1 | The robust variance from survival's `residuals.coxph()` on the fitter's result, bitwise `coxph()`'s (§2.2), with `coxph()` as the fallback | adopt (answers DEC-098) | DEC-099, amending DEC-091 |
| 2 | The fitters called as `coxph()` calls them: the offset minus its mean, `nocenter = c(-1, 0, 1)`, integer strata codes, and `coxph()`'s cluster codes (§2.1) | adopt | DEC-100 |
| 3 | The covariate p-value of Cox fits as pprof_py computes it, 2Φ̄(\|z\|), through an option of the covariate rule whose default is today's (§2.6) | adopt | DEC-101, K-148 |
| 4 | COXPH_DESIGN §D.3 items 1 and 2 in C2, items 3 to 6 in C3; C2 declares `coef_wald` only | adopt | DEC-102 |
| 5 | The presentation: `augment()`'s `fitted` is the expected events and its `residual` the martingale residual; `glance()` adds `n_events`, `aic`, and `bic`; `predict()` and `baseline_hazard()` give long tables at the providers' event times; rows with weight 0 are reported in the object, `print()`, and with `verbose`, without a warning; `Surv()` re-exported | adopt | DEC-103 |
| 6 | `check_data()` gains `weights` and `cluster`; near ties by `aeqSurv()`; a large mean is \|mean\| above 100 standard deviations | adopt | DEC-104 |
| 7 | The benchmark comparator is the engine call on the same prepared data in the same session, under DEC-038's rule with its 0.05 s floor (§4.5) | adopt | recorded with the C2 benchmarks, under DEC-098 |

## 7. Registers and documents updated in C2

- `dev/DECISIONS.md`: DEC-099 to DEC-104 as approved, with status notes on DEC-091 and DEC-098.
- `dev/DISCREPANCIES.md`: D-56 to D-60, D-62 to D-64, and D-74 marked "implemented in C2" with their tests; any new difference found.
- `dev/CONVENTIONS.md`: K-148, the covariate Wald test of Cox fits; the code locations of K-131 to K-135.
- `dev/NAMING.md` §10: the `baseline_hazard()` generic, the `n_zero_weight` field, `predict()`'s types, `check_data()`'s new arguments, the `"two_sided_upper"` value of the covariate rule.
- `NEWS.md`, the help pages, `_pkgdown.yml`, ARCHITECTURE §E.3 (the Cox column of the capability table) and §E.6 (as built), and `dev/COXPH_STATUS.md`.

## 8. Risks

- **survival's internals.** The robust path relies on how `residuals.coxph()` reads the object `coxph()` builds; the engine-identity tests pin it, and the fallback is `coxph()`. Bitwise identity with `coxph()` likewise relies on replicating its preprocessing: a survival release that changed `coxph()`'s defaults would show in those tests, not in users' results.
- **Small fits.** At 10⁴ rows the engine call takes about 0.08 s, so 10% is 8 ms, less than `data_prepare()`'s fixed cost of terms and model frames may be. DEC-038's 0.05 s floor applies there, and the report gives the raw ratios.
- **Fixtures outside the tarball.** The full-set comparisons (D-56's `recurrent`, D-58, D-60, D-64) don't run under `R CMD check`; unit tests carry each decision there.
- **Test time.** The snapshot test replays the core reference cases (about the reference suite's 100 s), and the Cox tests add more, to a `devtools::test()` of 7 to 13 minutes.
- **The version.** NEWS entries go under the unreleased 2.0.0 heading unless the project lead prefers another.
