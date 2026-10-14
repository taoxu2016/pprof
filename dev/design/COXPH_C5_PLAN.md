# CoxPH Phase C5 plan: competing risks

> **Status: for the project lead's approval.** It implements the brief's §4 row C5 (`dev/coxph_brief.md`; also §2.1 item 4, §2.4's `CauseSpecificCoxPH` and `FineGrayPH` rows, §3.2's Fine–Gray item, §3.3 rows 2 to 6, §3.5, §3.7, §5.1, §5.5, §6, and §10's Q2, Q3, and Q13) and COXPH_DESIGN §A.6, §B.1, §B.2, §C.1, §D.4, §E.3, §G, §H, and §I, under DEC-086 to DEC-120.

C5 adds `fit_fine_gray()`, pprof_py's `FineGrayPH(strata = provider)`: survival's `finegray()` expands the data, and a weighted Cox fit stratified by provider, with the robust variance clustered by subject, estimates the subdistribution hazard ratios; the cumulative incidence comes from survival's `survfit()`. The model declares coefficient inference only: there are no Fine–Gray-based provider measures (M-41). Cause-specific models are already `fit_cox_stratified()` with the event of interest written in `Surv()` (DEC-090, M-35); C5 completes their tests and documentation. The existing families and the stratified and elastic-net Cox models stay bitwise identical.

The evidence (§2; `dev/design/coxph-facts/31` to `35`) confirms the C0 design in its main lines: survival's calls reproduce the competing-risk fixtures exactly, and pprof_py's within the calibrated tiers. It makes the design precise, or corrects it, in five places:

- survival 3.8-12's `finegray()` applies case weights to the wrong rows in every stratum after the first, so the case weights must multiply its output weights after the call.
- `finegray()`'s time grows with rows times providers: on 100,000 rows it takes 24 s with 1,000 providers, where pprof_py's whole fit takes 5.3 s, and 110 to 180 s with 7,500. Calls on chunks of 50 providers, each deciding delayed entry as all rows do, give its output bitwise in 3 to 14 times less time; calls on single providers do not always give it.
- With delayed entry, small providers can make the Fine–Gray weights undefined: survival returns NaN or infinite weights where pprof_py raises an error, and pprof_py also raises on data where survival's weights are all finite.
- The fitter and the robust step of DEC-099 and DEC-100 on the expanded data give `coxph(cluster = id)`'s fit bitwise, in 0.35 to 0.57 of its time.
- A status with several event types must be a factor, and pprof_py checks subjects in ways survival does not.

§6 lists the nine decisions the plan asks for.

## 1. Deliverables

| # | Deliverable | Where |
|---|---|---|
| 1 | The competing-risks response in the data layer: `response_type = "competing_risks"`, a `Surv()` response with a factor status, kept as each observation's state | `R/data-prepare.R`, `R/data-survival.R`, `R/data-formula.R`, `R/data-class.R` |
| 2 | The Fine–Gray part of the survival adapter: the `finegray()` call and its checks, the fitter's inputs from the expansion, the fit and robust variance through the adapter's fitter and robust step, and the `coxph()` object of the expansion | `R/model-survival.R` |
| 3 | `fit_fine_gray()`, the `pprof_fine_gray` object, its validator, its capability (`coef_wald`), and its methods, `predict(type = "cumulative_incidence")` among them | `R/model-fine-gray.R` (new), `R/present-print.R`, `R/present-tidy.R` |
| 4 | The cause-specific model's tests and help | `R/model-cox-stratified.R` (roxygen only), tests |
| 5 | Tests (§4) | `tests/testthat/`: `test-model-fine-gray.R` and `test-cox-fine-gray-reference.R` (new); `test-data-survival.R`, `test-model-survival.R`, `test-cox-reference.R`, `test-profile-cox.R`, `test-cox-fixtures.R`, and `helper-cox-fixtures.R` (extended) |
| 6 | A weighted competing-risk case in the fixture generator, and both sets regenerated (decision 6) | `dev/reference/cox/cases.py`, `generate.py`, `survival.R`; `validation/fixtures/cox/`; `dev/reference/diff-reports/` |
| 7 | Calibration rows: the Fine–Gray log-likelihoods, and the new case (decision 5) | `dev/reference/cox/calibrate.R`, `validation/cox-calibration-report.md` |
| 8 | Benchmarks: the fit against its survival calls and the preparation of their inputs (DEC-105), beside `coxph()` and pprof_py (decision 7) | `dev/bench/cox/run_paired.R`, `summarize_paired.R`, `scenarios.R`, `run_pprof_py.py`, `.github/workflows/cox-bench.yaml`, `dev/bench/results/` |
| 9 | Registers, help pages, `NEWS.md`, `_pkgdown.yml`, NAMING §10, COXPH_DESIGN as built, ARCHITECTURE §E.3 and §E.6, the status document | `dev/`, `man/` (generated), `NEWS.md`, `_pkgdown.yml` |

**Not in C5** (the brief's §4): Fine–Gray-based provider measures (M-41, the brief's §2.2 and §5.5); the vignette and the final reports (C6); the later briefs; `check_data()` for a status with several event types (decision 8). D-78 stays open for a methodology owner (M-16); nothing in C5 depends on it.

## 2. Evidence gathered for this plan

The evidence was gathered on 2026-10-14 on the C1 machine, with R 4.4.0, survival 3.8-12, and the fixture generator's Python environment, which holds pprof_py at `9320766`. The machine paged throughout (0.6 to 0.9 GB of 7.4 GB free), so elapsed times ran 1.5 to 2.7 times the processor times and are indicative. The scripts and their outputs are in `dev/design/coxph-facts/`:

- 31 (R and Python) shows what `Surv()` and `finegray()` do with the inputs of `fit_fine_gray()`, and what pprof_py's transform does with the same data.
- 32 fits the Fine–Gray model from survival's calls on the two competing-risk fixtures. It compares the fits with `coxph(cluster = id)`, the fixtures' survival records, and pprof_py: coefficients, variances, cumulative incidence, and log-likelihoods.
- 33 (R and Python) times the calls on the benchmark's data, and pprof_py's `FineGrayPH` on the same data.
- 34 profiles `finegray()`, and measures its expansion at 1,000 rows per provider.
- 35 compares `finegray()` called once per chunk of providers with one call stratified by provider.

### 2.1 The status (31, part A)

- `Surv()` reads a numeric status coded 0/1/2 as 1/2 coding: type `"right"`, with the 0s missing and a warning. `type = "mstate"` reads numeric codes, but survival deprecates it ("use a factor variable as status").
- A factor status gives the multi-state types, `"mright"` or `"mcounting"`. The factor's first level is censoring and the others are the event types (`states`), whatever their labels; unused levels stay event types.
- A factor without its censoring level, `factor(c(1, 2, 2, 1))`, takes "1" as censoring without a word. `factor(status, levels = 0:2)` avoids it.
- pprof_py takes numeric codes, 0 for censoring (D-74 records its 1/2 rule).

### 2.2 `finegray()`'s inputs (31, part B, and its pprof_py side)

- **Case weights.** `finegray(weights = w)` multiplies its output weights by `user.weights[split$row]`, where `split$row` counts the rows of the stratum, not of the data. So every stratum after the first gets the case weights of the data's first rows. In 31's example the rows of providers 2 and 3 got weights 1 to 4 instead of their own 10 to 40 and 100 to 400, provider 2's three zero weights were not applied, and the weighted fit's coefficient was 0.220 instead of −0.144. In the first stratum, and with one stratum, the result is the transform's weights times each row's case weight, which is K-145's definition and pprof_py's (`wt * user_weight[r]`).
- **The censoring and entry distributions are unweighted**, in survival and pprof_py alike: the expansion's rows and times are the same with any case weights.
- **Zero case weights.** A row of weight 0 keeps its place in the censoring and entry distributions, and its pieces get weight 0. `coxph()` refuses them ("Invalid weights, must be >0"). pprof_py passes them to `CoxPH` with weight 0, where Efron ties count them among tied deaths (B7, D-58).
- **A provider without events of the cause** is left out of the expansion, by survival and pprof_py alike; its stratum would add nothing to the partial likelihood.
- **`etype`** is an event type's label; a number matches its label; the censoring level is "not in the data".
- **`id`.** `finegray()` requires it for (start, stop] data. With right-censored data it does not read it, and accepts a repeated `id`. pprof_py rejects a repeated `id` there (in 31's example, "A subject has a non-zero event before their last time point"; its check also rejects a gap or overlap), and rejects a subject whose rows change stratum ("A subject cannot change strata during follow-up"), which `finegray()` does not check.
- **One event type.** `finegray()` refuses a status with a single event type ("survival time has only a single state"). Given an unused second level, it returns the rows unchanged with weight 1. pprof_py's `FineGrayPH` fits a 0/1 status.
- **`timefix`.** On near-tied times (0.1 + 0.2 and 0.3), `finegray(timefix = FALSE)` and its default give different expansions (7 and 8 rows), as `coxph()`'s fits differ (M-23).

### 2.3 Delayed entry is decided over all rows; chunks of providers (31, part C; 33; 35)

- `finegray()` adds the entry distribution H when any subject's first entry is later than the smallest exit over all rows. It then computes H in every stratum. pprof_py decides it the same way.
- Apart from that decision, survival 3.8-12's `finegray()` computes each stratum from its own rows (its source, `R/finegray.R`): its censoring and entry curves come from `survfit()` by stratum, on a rank scale of the times that keeps each stratum's order and ties, and its pieces from each stratum's rows, its own breakpoints, and its largest time.
- A call per provider decides delayed entry per provider. In 31's constructed case, provider 1's own rows have no late entry, and one of its entry times equals a competing event time. Alone, it gets different pieces and weights (0.5, where the stratified call gives 1.25 and 0.625); pprof_py's expansion is the stratified call's. On the benchmark's `providers-7500` data, the calls per provider gave one row fewer than the stratified call (33).
- Calls on chunks of providers, each chunk deciding delayed entry as all rows do, gave the stratified call's output bitwise in every case of 35. When the whole data have delayed entry, each chunk also holds the provider of the smallest exit and that of the first subject entering after it, so that the chunk's decision is the whole data's; each provider's rows come from the chunk that owns it. The cases: 31's counterexample and both fixtures, each cause, in chunks of one provider; `rows-1e4`, `center`, and `providers-7500` with and without delayed entry, in chunks of 50, their weights that are not finite included.

### 2.4 Weights that are not finite (31, part D; 33)

- With delayed entry, the product of the censoring and entry curves can be 0 at a competing event. `finegray()` then gives the competing event's later pieces NaN or infinite weights: 33 pieces in 22 providers of `rows-1e4` (10 rows per provider on average), and 207 on `providers-7500` (13 rows per provider). There are none on `center` (100 rows per provider).
- pprof_py raises `FloatingPointError` there ("censoring/truncation probability reached zero before a competing-event extension"). It also raises when no later piece follows the competing event (the event of interest occurs earlier), where `finegray()`'s weights are all finite: in 31's small example, and on the benchmark's `covariates-5` data, where one provider's competing event has probability 0 and no kept breakpoint after it (33).

### 2.5 The fit (32, part A)

- `finegray()` on the rows sorted by provider, then survival's fitter called as `coxph()` calls it (DEC-100) and `coxph()`'s robust step on its result clustered by subject (DEC-099), equals `coxph(cluster = id)` on `finegray()`'s output bitwise: coefficients, robust and model-based variances, log-likelihoods, and iterations, in all 16 configurations (2 fixtures, 2 causes, 2 tie methods, default and tight control).
- Both equal the fixtures' survival records bitwise. `finegray()` groups its output by stratum, so sorting the rows by provider first changes nothing.
- Against pprof_py:
  - the iteration counts are equal;
  - the coefficients are within 0.0052 units of `cox_coefficient`, the model-based variances within 8.0e-5 units of `cox_variance`, and with Efron ties the robust variances within 5.1e-7 units;
  - with Breslow ties the robust variances are 5.1e4 to 3.5e5 units off (D-56: every Fine–Gray fit is on (start, stop] data);
  - the Efron fit of cause 2 on `competing-simple` has its coefficients 1.43 units off, at default and tight control, and its variances within 0.069 (model-based) and 0.23 (robust) units: the calibration's D-57 row.

### 2.6 Cumulative incidence and log-likelihoods (32, parts B and C)

- `survfit()` of a `coxph()` object fit to the expansion as the package builds one (generated column names, no cluster, `robust = FALSE`; `survival_engine_fit()`'s pattern) gives the generator's curves bitwise: every time, profile, and stratum, both tie methods. The cumulative incidence is 1 minus its survival.
- Against pprof_py at its times: within 0.0059 units of `cox_baseline`, except D-57's record (1.02 units).
- pprof_py's log-likelihoods are within 0.0009 units of `cox_function`. The calibration report has no rows for them yet.

### 2.7 Cost (33, 34, 35)

The benchmark's data, a second cause derived without random numbers (every third event row), cause 1, Breslow ties, the case weights, and one subject per row. Elapsed seconds, with processor seconds in parentheses; one run each. The chunks' times are 35's, the others 33's; pprof_py ran with numba's 8 threads.

| Scenario | Expanded rows | `finegray()`: one call | per provider | chunks of 50 | Inputs, fitter, robust step | `coxph(cluster = id)` | pprof_py: transform; whole fit |
|---|---|---|---|---|---|---|---|
| `center` (100,000 rows, 1,000 providers, 20 covariates) | 687,533 | 24.0 (14.5) | 6.7 (3.8) | 4.5 (2.5) | 6.7 (3.9) | 9.4 (4.2) | 1.2; 5.3 |
| `covariates-5` (5 covariates) | 726,019 | 21.5 (9.4) | 7.5 (4.2) | | 2.2 (1.2) | 3.8 (2.3) | raises (§2.4) |
| `providers-7500` (7,500 providers; 7,263 with rows) | 186,200 | 178.1 (100.9) | 28.3 (16.3), one row fewer | 13.3 (6.5) | weights not finite (§2.4) | | raises |
| `providers-7500`, every entry at 0 | 165,301 | 109.0 (59.6) | 18.5 (10.5) | 11.6 (5.0) | 1.1 (0.6) | 2.6 (1.3) | 1.7; 6.4 |
| `rows-1e4` (10,000 rows, 1,000 providers) | 16,279 | 3.2 (1.9), in 35 | | 1.05 (0.54) | weights not finite (§2.4) | | |

- **Where the time goes** (34). The profile of one call on `center` puts it in survival's per-stratum steps: `survfit()` (45%, nearly all `survfitKM()`'s loop over strata), `[.survfit` taking each stratum's curves (30%), and `split()` (29%). Each step goes over all the rows once per stratum, so the time grows with rows times providers. pprof_py's transform selects each stratum's rows with one vectorized comparison and computes its curves by sorted searches.
- **Chunks of 50 providers** (35) take 3.0 (`rows-1e4`), 5.7 (`center`), 10 (`providers-7500`, every entry at 0), and 14 (`providers-7500`) times less time than one call, with the same output; in 35's runs one call took 25.6 s on `center` and 183 s on `providers-7500`.
- **The fit** on the expansion: the fitter and the robust step take 0.35 to 0.57 of `coxph(cluster = id)`'s time on the same rows.
- **The expansion's size** depends on the rows per provider: 6.9 rows per row at 100 rows per provider (`center`), and 43 at 1,000 (34: `providers-100`'s 100,000 rows give 4,296,722).

## 3. Approach

### 3.1 The competing-risks response (the data layer; COXPH_DESIGN §C.1, DEC-092)

`data_prepare(response_type = "competing_risks")` reads a `Surv()` response of type `"mright"` or `"mcounting"`, a factor status (decision 3):

- `response` holds each observation's state: 0 for censoring, and k for the k-th event type.
- `settings$states` holds the event types' labels, the factor's levels after the first; `settings$survival_type` is `"right"` or `"counting"`.
- `start` and `stop` follow pprof_py's rules, as for `"survival"` (K-131).
- Missing values are deleted listwise, the status's among them (D-62).
- `event_counts = TRUE` raises `pprof_error_invalid_input`: which events count depends on the event of interest, which the model chooses. `fit_fine_gray()` adds its own counts to the provider table.
- A status that is not a factor raises `pprof_error_invalid_input`. A numeric status coded 0/1/2 gets the hint `Surv(time, factor(status))`.

`response_type = "survival"` with a factor status keeps its error; its hint also names `fit_fine_gray()`. `validate_pprof_data()` gains the competing-risks branch. `model_data_spec()` and `model_prepared_data()` do not change: they already record and pass `response_type`, `weights`, and `cluster`. `check_data()` does not change (decision 8). No existing caller reaches the new branch (§4.1).

### 3.2 The Fine–Gray adapter (`R/model-survival.R`; COXPH_DESIGN §E.3; decisions 1 to 4)

**Before the transform** (decision 4):

- (start, stop] data need `id` when an entry time is not 0, and raise `pprof_error_invalid_input` without it, as pprof_py requires. When every entry time is 0, each observation is its own subject, as in pprof_py; `finegray()`, which needs an `id` for any (start, stop] data, gets the observations as subjects.
- With right-censored data, a repeated `id` raises, as pprof_py's check does.
- A subject whose rows have more than one provider raises, as pprof_py's check does.

**The transform** (decisions 2 and 3): `survival::finegray()` on every observation, those of weight 0 included, in `data_prepare()`'s order, called once per chunk of providers.

- The providers, in provider order, are split into chunks of 50 (a named constant). When the data have delayed entry by `finegray()`'s rule (some subject's first row, by subject and exit time, enters later than the smallest exit), every chunk also holds the provider of the smallest exit and the provider of the first such subject, so that it decides delayed entry as all rows do. Each provider's rows are kept from the chunk that owns it, and the chunks' rows, in provider order, are the stratified call's (§2.3). A chunk without an event of the cause is skipped, as `finegray()` leaves such providers out. With 50 providers or fewer, there is one call.
- The formula is `Surv(.start, .stop, .status)` or `Surv(.stop, .status)` `~ .row + strata(.provider)`, over a data frame of the prepared vectors held in the formula's environment, as `survival_engine_fit()` holds its own. `.row`, which `finegray()` carries into its output, gives each expanded row's observation, and through it the provider, the covariates, the case weight, and the subject.
- `.status` is the factor of the states with levels 0 to max(K, 2): an unused level when there is a single event type K = 1, so that `finegray()` accepts it, as pprof_py does (§2.2).
- Its other arguments are `etype` (the cause's state), `id` (the subjects, or none for right-censored data), and `timefix = FALSE`. No `weights`.
- The expanded rows' weights are `fgwt` times their observations' case weights (decision 3).
- `finegray()`'s errors (gaps, an event before a subject's last row) become `pprof_error_invalid_input` with survival's message in `engine_message`.
- Weights that are not finite raise `pprof_error_data`, which names the providers (D-80).
- No event of the cause among the expanded rows with positive weight raises `pprof_error_data` (M-26).

**The fit** (decision 1): the expanded rows with positive weight (M-25).

- The fitter's inputs: the design's rows of the expansion's observations, `Surv(fgstart, fgstop, fgstatus)`, integer strata codes in provider order, offsets of 0, and the weights.
- `survival_run_fitter()`, which calls `agreg.fit()` as `coxph()` calls it (DEC-100), with `coxph.control(eps = tol, iter.max = max_iter, timefix = FALSE)`.
- NA coefficients raise `pprof_error_data` naming the aliased covariates (M-26). Reaching `max_iter` warns (K-133).
- The robust variance is `survival_robust_vcov()`, with the subjects of the fitted expanded rows coded as `coxph()` codes a cluster column (DEC-100, DEC-106). It equals `coxph(cluster = id)`'s bitwise; the model-based variance is kept as `naive_vcov`.
- The `coxph()` object of the expansion, for the curves and `keep_data = TRUE`, follows `survival_engine_fit()`: the weights, the provider strata, no cluster, and `robust = FALSE`.

**Memory.** The expansion, its rows times the covariates, exists only during the fit, unless `keep_data = TRUE` keeps the `coxph()` object (DEC-004).

### 3.3 `fit_fine_gray()` and the `pprof_fine_gray` object (COXPH_DESIGN §B.1, §B.2, §D.4; decision 8)

**The signature** is the design's: `fit_fine_gray(formula, data, provider, cause, id = NULL, weights = NULL, ties = "breslow", max_iter = 20, tol = 1e-9, keep_data = FALSE, verbose = FALSE)`.

- The data come from `data_prepare(response_type = "competing_risks", weights, cluster = id, event_counts = FALSE)`. The subject column passes as `cluster`, so a missing `id` deletes its row, and subjects are coded as `coxph()` codes clusters. `offset()` terms are rejected, as for the existing families (decision 4).
- `cause` is one of the event types: its label, or a number equal to its label. The censoring level raises `pprof_error_invalid_input`.

**The object.**

- **Shared fields:**
  - `coefficients`;
  - `vcov`, the robust covariance clustered by subject;
  - `provider_effects = NULL`;
  - `response`, the indicator of the cause;
  - `linear_predictor`, x'β;
  - the provider table, with `n_events` (the cause's events), `n_competing` (the other event types'), and `person_time`;
  - `convergence`: `iterations`, `converged`, `stop_rule = "relative_loglik"`, `tol`, and `max_iter`.
- **Own fields:** `start`, `stop`, and `weights` per observation; `status` (each observation's state); `states`; `cause`; `naive_vcov`; `loglik`; `n_events`; `n_competing`; `n_expanded` (the expanded rows of the fit); `n_zero_weight`; and with `keep_data = TRUE`, `engine_fit`.
- **`spec`:** `family = "fine_gray"`, `cause`, `id`, `ties`, `weights`, `max_iter`, `tol`, and `keep_data`.
- **Memory:** about six doubles per observation; the expansion only with `keep_data = TRUE`.

**Capabilities.** `coef_wald` only, on the robust variance with DEC-101's covariate rule. The profiling functions raise `pprof_error_unsupported_inference` (M-41). `profile_spec()` has the required fields and the covariate rule, as C2's stratified model had before C3 (DEC-102).

**Methods.**

- `print()`: the tie method, the cause, the events and competing events, the expanded rows, rows of weight 0, convergence, and "robust, clustered by <id>" (or "one cluster per observation").
- `summary()`, `confint()`, and `test_coefficients()`: the Wald rule, through the shared methods.
- `coef()`, `vcov()`, `nobs()` (the cause's events among the fitted rows, as `coxph()` counts them on the expansion), and `logLik()` (the partial log-likelihood of the weighted expansion, as `coxph()` reports it).
- `predict(object, newdata = NULL, type = c("linear_predictor", "risk", "cumulative_incidence"), data = NULL)`. The cumulative incidence is, for each row of `newdata`, its provider's 1 − `survfit()` survival at that provider's event times of the cause: `row`, `provider_id`, `time`, and `cumulative_incidence`, as the stratified model's curves are laid out. It uses the kept `coxph()` object, or one rebuilt from `data` and checked against the stored coefficients (DEC-005). Providers outside the fit (unknown, which warns, or without events of the cause) give missing values; a model without covariates raises, as D-75's does.
- `tidy()` and `glance()`: as the stratified model's, `glance()` adding `n_competing`.
- `residuals()`, `augment()`, and `baseline_hazard()` raise `pprof_error_unsupported_inference` (D-81).

### 3.4 Cause-specific models (DEC-090, M-35, K-146)

They need no new function. What remains:

- **Tests** (§4.4): the full set, default fits, engine identity, a factor status, and profiling per cause.
- **Help:** `fit_cox_stratified()` gains a paragraph on competing risks and an example that fits each cause. `fit_fine_gray()`'s help says how the two models differ: cause-specific hazards with the other causes censored, against the subdistribution hazard with competing events kept at risk.
- **`NEWS.md`.**

### 3.5 Shared additions

Each addition is new code; no existing caller reaches it.

- `R/model-survival.R`: the Fine–Gray functions of §3.2, beside the stratified model's, which do not change.
- `R/constants.R`: the providers per `finegray()` call, 50, with its reason (decision 2; 35).
- `R/present-print.R`, `R/present-tidy.R`: the Fine–Gray model's methods.
- `R/data-*.R`: §3.1's branch.
- The hint of `data_survival_response()`'s error, which names `fit_fine_gray()`.
- Generated and index files: `NAMESPACE`, the help, `_pkgdown.yml`.

Nothing changes in the inference, profiling, or presentation layers beyond the new methods.

## 4. How equivalence is checked

### 4.1 The existing families and the Cox models stay bitwise identical

1. `devtools::test()` and `validation/run-reference.R` run in the verification worktree. They run at `main` (`4c7b028`) before any change, and again after each commit marked (S) in §5. Each run must have no failure, the previous run's tests and expectations plus the new ones, and an equivalence report equal to the committed one but for its date and commit (368 of 368 cases).
2. The `data_prepare()` snapshot test passes after each data-layer commit.
3. The stratified and elastic-net Cox models' tests pass unchanged: `test-model-survival.R`, `test-model-cox-stratified.R`, `test-model-cox-measures.R`, `test-profile-cox.R`, `test-cox-reference.R`, `test-inference-poisson.R`, `test-cox-fixtures.R`, `test-model-glmnet.R`, `test-model-cox-penalized.R`, `test-model-cox-selection.R`, and `test-cox-penalized-reference.R`. No existing expectation is edited; the C5 tests are added beside them.

### 4.2 Against pprof_py: the competing-risk fixtures (`test-cox-fine-gray-reference.R`)

The core set's `competing-simple` always runs. The full set's `competing-truncated` and decision 6's case run when present (`skip_on_cran()`). Every record runs: each cause, both tie methods, stratified, and unstratified (fitted with one provider).

| Quantity | How | Tier |
|---|---|---|
| The expansion's rows and status | the adapter's transform against pprof_py's `expanded` | `exact` |
| Its times and weights | the same | `closed_form`, as calibrated |
| Iterations | default and tight fits | `exact` |
| Default coefficients | within the longer of the two last Newton steps, from pprof_py's Fine–Gray iterates (D-57) | `cox_last_step_bound()` |
| Tight coefficients | | `cox_coefficient`; D-57's record within the last step |
| Model-based variances | | `cox_variance` |
| Robust variances | Efron ties against pprof_py; Breslow ties against the fixture's survival record, and beyond the tier from pprof_py's (D-56) | `cox_variance` |
| Log-likelihoods | at the estimates and at 0 | `cox_function` (decision 5) |
| Coefficient tests | z and the p-value from the robust standard errors by DEC-101's rule | as C2's |
| Cumulative incidence | at pprof_py's times, its three profiles, and the first two providers | `cox_baseline`; D-57's record against the fixture's survival record |
| Decision 6's case with Efron ties | where zero-weight events tie with other events, against the fixture's survival record, and beyond `cox_coefficient` from pprof_py's (D-58) | `cox_coefficient` |

### 4.3 Engine identity (the brief's §6 B; DEC-043's pattern)

- **The transform** equals one direct `finegray()` call stratified by provider followed by the case weights' product, bitwise (`cox_engine`), with the chunk size lowered so that the data take several chunks. The cases: right-censored and (start, stop] data; several rows per subject; case weights with zeros; an `id` and none; delayed entry over all rows that some chunks' own providers lack, with 31's counterexample among them (decision 2); a chunk without events of the cause; weights that are not finite.
- **The fit** equals `coxph(Surv(fgstart, fgstop, fgstatus) ~ x + strata(provider), weights, cluster = id, ties, timefix = FALSE)` on that expansion, rows of weight 0 removed: coefficients, both variances, log-likelihoods, and iterations, bitwise, both tie methods.
- **`predict(type = "cumulative_incidence")`** equals 1 − `survfit()` of that `coxph()`, bitwise.
- **The installed survival** reproduces the fixtures' Fine–Gray records (`test-cox-fixtures.R`), within the tiers, as it does the cause-specific records now.

### 4.4 Unit, metamorphic, and edge-case tests (the brief's §6 C, E, F)

**The data layer:** the competing-risks response (types `"mright"` and `"mcounting"`, the states and their codes, a missing status, labelled and unused levels); `event_counts = TRUE` raises; a numeric 0/1/2 status raises with its hint; the times, weights, and subjects as for `"survival"`.

**Inputs** (decisions 3 and 4):
- (start, stop] data without `id`, with an entry time other than 0 (raises) and with every entry at 0 (fits, each observation its own subject); a repeated `id` with right-censored data; a subject in two providers;
- `finegray()`'s own errors, classed;
- a `cause` that is censoring or not a state; a cause without events, or without events of positive weight;
- `offset()` terms; aliased covariates;
- weights that are not finite (D-80), with the providers named; and where pprof_py raises with no later piece, the fit (§2.4);
- a single event type, which fits as pprof_py fits it: equal, within `cox_coefficient`, to `fit_cox_stratified(..., cluster = id)` on the 0/1 status (its fitter is `coxph.fit()` for right-censored data, which agrees with `agreg.fit()` within 3e-15, COXPH_DESIGN §E.1).

**Weights:**
- rows of weight 0 stay in the transform and leave the fit (M-25, D-58): the fit equals the transform of every row with their pieces removed, and differs from the transform of the other rows alone;
- case weights multiply the transform's weights only, in every provider, against survival's `finegray(weights =)` in the first provider and the product elsewhere (§2.2);
- equal case weights c leave the coefficients unchanged (`cox_coefficient`).

**`timefix`** (M-23): on near-tied times the fit equals the transform and fit with `timefix = FALSE`, and differs from `finegray()`'s default.

**Metamorphic:**
- row order and provider relabeling (`cox_coefficient`: survival's sums change order);
- covariate order;
- subject relabeling, and time rescaled by a power of 2 (identical).

**Edge cases:**
- a provider without events of the cause: out of the fit, in the provider table, and its curve missing;
- one provider; no covariates (the fit, and its curves raising);
- every unsupported inference raising `pprof_error_unsupported_inference`.

**Methods:** `print()`, `summary()`, `confint()`, `tidy()`, `glance()`, `nobs()`, `logLik()`, and `predict()` for the fit's rows and `newdata`, with the data kept or passed, and `data` that is not the fit's raising.

**Cause-specific models** (`test-cox-reference.R`, `test-profile-cox.R`):
- the M-35 test runs on the full set too. Default fits: iteration counts as pprof_py's, and coefficients bitwise those of a direct `coxph(Surv(time, event == k) ~ ... + strata(stratum), timefix = FALSE)` (`cox_engine`; pprof_py's cause-specific records have no iterates for D-57's bound);
- a factor status, `Surv(time, status == "relapse")`, gives the fit of the numeric coding;
- `profile_providers()` on a cause-specific fit: its tables equal `test_providers()`, `standardize_providers()`, and `funnel_limits()` on the same fit, and the measures equal those of a fit to the recoded 0/1 status (K-146);
- `fit_cox_stratified()` with a factor status raises, with the hint naming both models.

**One regression test per register entry:**

| Entry | Regression test |
|---|---|
| D-56 | the Fine–Gray robust variances with Breslow ties differ from pprof_py's and equal survival's |
| D-57 | `competing-simple`'s Efron fit of cause 2 within the last Newton step |
| D-58, M-25 | rows of weight 0 in the transform and out of the fit; decision 6's case with Efron ties |
| D-74 | the factor status; a numeric 0/1/2 status raises with its hint |
| D-80 | weights that are not finite raise, naming the providers; the case pprof_py raises without a later piece fits |
| D-81 | the outputs not given raise |
| M-23 | the transform with `timefix = FALSE` |
| M-35, K-146 | the cause-specific tests above |
| M-41, K-145 | the capability, and the comparisons of §4.2 |

### 4.5 Calibration (DEC-097)

`calibrate.R` gains rows, and the rows of C1 to C4 stay unchanged:

- **The Fine–Gray log-likelihoods** of every competing-risk record, at the estimates and at 0, under `cox_function`. The negative control is the other tie method's log-likelihood, from the fixture's other record. §2.6 predicts at most 0.0009 units.
- **Decision 6's case**, with the rows every competing-risk case has: the cause-specific fits, measures, tests, and funnels, and the Fine–Gray expansion, fits, variances, and cumulative incidence. The rows that D-56, D-57, and D-58 explain are marked as such.

### 4.6 Benchmarks (the brief's §3.7; DEC-038, DEC-105; decision 7)

`run_paired.R` gains two tasks, `fine_gray` on the scenarios as they are and `fine_gray_right` with every entry at 0. Both use `scenarios.R`'s data with a second cause derived without random numbers (every third event row), cause 1, Breslow ties, the case weights, and one subject per row. No scenario's data change.

- **The fit side:** `fit_fine_gray()` on the data frame.
- **The engine side:** the survival calls the fit makes, written out in plain R: `finegray()` on each chunk of providers, the product of the case weights, survival's fitter, and the robust step, with the preparation of their inputs: `data_prepare()`, the chunks and `finegray()`'s data frames, and the fitter's inputs from the expansion. The coefficients and the robust variance must equal the fit side's bitwise.
- **The rule** is DEC-105's: too slow when, in every round, the median and fastest run are more than 10% above the engine side and the median at least 0.05 s above it.
- **Reported, not a gate:**
  - one `finegray()` call stratified by provider followed by `coxph(cluster = id)`, the calls a user would make;
  - pprof_py's `FineGrayPH` on the same data and cause (`run_pprof_py.py` gains both tasks), which raises on `covariates-5` and on `providers-7500` with delayed entry (D-80; §2.4);
  - peak memory and the object's size.
- **Scenarios.** `fine_gray`: `center`, `covariates-5`, and `providers-100`. `fine_gray_right`: `center`, and `providers-7500`, which runs only with every entry at 0, since its delayed entry makes the weights undefined (§2.4).
- **Not run:**
  - `rows-1e4`: its delayed entry makes the weights undefined in 22 providers, so the package raises, as pprof_py does wherever survival's weights are not finite (§2.4);
  - `rows-1e6`: at 1,000 rows per provider the expansion has 43 rows per row (34: `providers-100`'s 100,000 rows give 4.3 million), so about 43 million rows;
  - the corner: 1,000,000 rows of 7,500 providers with delayed entry. Its expansion, at 133 rows per provider on average, would hold several million rows of 50 covariates, and its many small providers may make the weights undefined, as on `providers-7500` (not checked).
- **Where.** `center` and `covariates-5` on this machine. All of them on `cox-bench.yaml` (DEC-111), whose default selection becomes the Fine–Gray tasks, as DEC-118 made it the penalized ones. pprof_py runs on this machine only, where its memory allows (`providers-100`'s expansion would need several GB).

## 5. Commit order

Small commits on `coxph/phase-5`. (S) marks the commits after which §4.1's checks run.

0. Before any change: §4.1's runs at `4c7b028`.
1. `docs: the CoxPH C5 plan`: this plan, fact scripts 31 to 35 with their outputs and README rows, and the status entry.
2. `reference: a weighted competing-risk case in the Cox fixture generator` (decision 6): `cases.py`, `generate.py`, and `survival.R`, whose R side calls survival as the adapter will (§3.2). Both sets are regenerated, with `compare.R`'s diff reports: every existing fixture identical, the full set with the case added. A second generation reproduces the first.
3. `tests: the C5 calibration rows` (decision 5): `calibrate.R`'s new rows and the regenerated report.
4. `data: the competing-risks response` (S): §3.1, and its tests in `test-data-survival.R`.
5. `model: the Fine–Gray adapter` (S): §3.2, and its tests in `test-model-survival.R`.
6. `model: fit_fine_gray() and its object` (S): `R/model-fine-gray.R`; the print, tidy, and glance methods; `NAMESPACE`, help, and `_pkgdown.yml`; `test-model-fine-gray.R`.
7. `tests: the Fine–Gray model against the fixtures`: `test-cox-fine-gray-reference.R`, `test-cox-fixtures.R`, `helper-cox-fixtures.R`.
8. `tests: cause-specific models` (S): `test-cox-reference.R`, `test-profile-cox.R`, and `fit_cox_stratified()`'s help.
9. `bench: the Fine–Gray model against its survival calls`: `run_paired.R`, `summarize_paired.R`, `scenarios.R`, `run_pprof_py.py`, `cox-bench.yaml`.
10. `bench: results of the C5 paired Cox benchmark`.
11. `docs: the CoxPH C5 registers and documents`; then the gate (`/phase-gate C5`).

## 6. Decisions this plan asks for

| # | Decision | Recommendation | Register |
|---|---|---|---|
| 1 | **The fit's engine calls** (§2.5, §3.2). (a) Survival's fitter on `finegray()`'s expansion, called as `coxph()` calls it (DEC-100), and `coxph()`'s robust step on its result clustered by subject (DEC-099): bitwise `coxph(cluster = id)`'s in all 16 fixture configurations and on the benchmark's data, in 0.35 to 0.57 of its time; `coxph()` only for the curves and `keep_data`. (b) `coxph(cluster = id)`, as COXPH_DESIGN §E.3 wrote it | (a) | DEC-121; COXPH_DESIGN §E.3 as built |
| 2 | **The transform** (§2.3, §2.7). (a) One `finegray()` call stratified by provider, as COXPH_DESIGN §E.3 wrote it: survival's and pprof_py's definition by construction, but its time grows with rows times providers: 24 s on `center`, and 109 s on `providers-7500` with every entry at 0, where pprof_py's whole fit takes 5.3 s and 6.4 s. (b) One call per provider: faster, but it decides delayed entry per provider, and so can differ from (a) (§2.3), a Class B difference. (c) One call per chunk of 50 providers, each chunk deciding delayed entry as all rows do (§3.2): (a)'s output bitwise in every case of 35, in 3 to 14 times less time (4.5 s on `center`, 11.6 s on `providers-7500` with every entry at 0). It rests on what survival 3.8-12's source shows, that `finegray()` computes each stratum from its own rows once that decision is made, and it restates `finegray()`'s rule for the decision; the engine-identity tests hold it to (a) bitwise on data built to exercise both. Under each of them the brief's §3.7 SHOULD (no slower than pprof_py) is not met everywhere: under (c) the fit's survival calls take about 11 s on `center` and 13 s on `providers-7500` with every entry at 0, against pprof_py's 5.3 s and 6.4 s (numba on 8 threads). DEC-098 is extended to the Fine–Gray fits; the MUST holds, since the transform is among the engine calls the rule compares with | (c) | DEC-122; DEC-098's status |
| 3 | **`finegray()`'s settings against the phase's conventions** (§2.1, §2.2). `timefix = FALSE`, as for every Cox fit (M-23). Case weights are not passed to `finegray()`, which applies them to the wrong rows after its first stratum; the expanded rows' weights are its weights times their observations' case weights, K-145's definition, pprof_py's product, and survival's own in its first stratum. Rows of weight 0 stay in the transform, whose censoring and entry distributions are unweighted, as in pprof_py; their pieces, of weight 0, leave the fit (M-25), so that with Efron ties a zero-weight event tied with others is not counted, as pprof_py counts it (D-58). The status is a factor whose first level is censoring, `Surv()`'s multi-state coding; a numeric status raises with the hint `factor()` (D-74). `cause` is one of the event types. A single event type is accepted, with an unused level added for `finegray()`, as pprof_py fits it | adopt | DEC-123; K-145; D-58, D-74 |
| 4 | **Inputs that `finegray()` does not check, or treats otherwise than pprof_py** (§2.2, §2.4). Each follows pprof_py: (start, stop] data need `id` when an entry time is not 0 (`finegray()` needs it for any such data, so with every entry at 0 it gets the observations as subjects); with right-censored data a repeated `id` raises; a subject whose rows have more than one provider raises; `finegray()`'s errors become `pprof_error_invalid_input`. Weights that are not finite raise `pprof_error_data` naming the providers, where pprof_py raises `FloatingPointError`; where pprof_py raises but no piece follows and every weight is finite, the package fits (new D-80, Class A). No `offset()` terms: pprof_py's `FineGrayPH` takes none. No `cluster` or `robust` argument: the variance is robust, clustered by subject | adopt | DEC-124; D-80 |
| 5 | **Tiers** (no tier changes; §4.2, §4.3, §4.5). The expansion's rows and status `exact`, its times and weights `closed_form`; coefficients, variances, and default fits as for the stratified model, with D-56 and D-57; the log-likelihoods `cox_function`, with new calibration rows; the cumulative incidence `cox_baseline`; the adapter against direct survival calls `cox_engine` | adopt (applying a tier needs sign-off) | DEC-125, applying DEC-097 |
| 6 | **The fixtures.** (a) One case in the full set, `competing-weights`: synthetic, about 360 subjects in 6 providers of 60, about a third with two or three contiguous (start, stop] rows and some entering late, a covariate that changes between a subject's rows, case weights on a 1/2 grid with some 0, zero-weight events tied with others, and both causes; providers large enough that pprof_py's transform does not raise (§2.4). Its records are those of every competing-risk case, with weights. Both sets regenerated, with diff reports: every existing fixture identical. (b) None: weights, zero weights, and several rows per subject are checked against direct survival calls only | (a) | DEC-126; the diff reports |
| 7 | **Benchmarks** (§4.6). `fine_gray` and `fine_gray_right` against the survival calls they make and the preparation of their inputs, by DEC-105's rule, bitwise; one stratified `finegray()` call followed by `coxph(cluster = id)`, and pprof_py's `FineGrayPH`, reported. `center` and `covariates-5` here; also `providers-100` and `providers-7500` (every entry at 0) on `cox-bench.yaml`, which the project lead dispatches; `rows-1e4`, `rows-1e6`, and the corner not run, for the reasons of §4.6 | adopt | DEC-127 |
| 8 | **Interface** (§3.1, §3.3). `data_prepare(response_type = "competing_risks")`; the signature and fields of §3.3; `n_competing` in the provider table; `predict(type = "cumulative_incidence")` laid out as the stratified model's curves. pprof_py's `FineGrayPH` also gives the subdistribution cumulative hazard (`predict_cumulative_hazard()`) and, through its inner `CoxPH`, the baseline hazard and the residuals of the expanded rows (new D-81, Class B by D-79's precedent): (a) leave them out, as the design does, with `residuals()`, `augment()`, and `baseline_hazard()` raising `pprof_error_unsupported_inference`; (b) add `predict(type = "cumulative_hazard")` and `baseline_hazard()`, compared with pprof_py through its cumulative incidence. `check_data()` keeps its 0/1 status, with a hint for a factor status | (a) | DEC-128; D-81; NAMING §10 |
| 9 | **Cause-specific models.** No new function (DEC-090): the tests, help, and `NEWS.md` of §3.4 | adopt | DEC-129; M-35 |

## 7. Registers and documents updated in C5

- **`dev/DECISIONS.md`:** DEC-121 to DEC-129 as approved, and DEC-098's status (the Fine–Gray fits).
- **`dev/CONVENTIONS.md`:** K-145 and K-146 as built, where they are in the package, and survival's case-weight defect.
- **`dev/DISCREPANCIES.md`:**
  - D-56, D-57, and D-58 implemented for the Fine–Gray model, with their tests;
  - D-74 extended to the factor status;
  - D-80 and D-81;
  - any difference found.
- **`dev/OPEN_QUESTIONS.md`:** M-35 and M-41 implemented; M-23 and M-25 applied to the transform.
- **`dev/NAMING.md` §10:** `response_type = "competing_risks"` and `settings$states`; the object's fields (`status`, `states`, `cause`, `n_competing`, `n_expanded`); `n_competing` in the provider table; `type = "cumulative_incidence"` and its column; `family = "fine_gray"`; the constant `fine_gray_chunk_providers`.
- **`dev/design/COXPH_DESIGN.md`, as built:**
  - §A.6: the transform's rules and survival's;
  - §B.1 and §B.2: the signature and fields;
  - §C.1: the competing-risks response;
  - §D.4;
  - §E.3: the calls of decisions 1 to 4;
  - §G.1: the new case;
  - §G.2: the tiers applied;
  - §I: the benchmarks.
- **Other documents:**
  - `dev/design/ARCHITECTURE.md` §E.3 (the Fine–Gray model's column: `coef_wald`) and §E.6;
  - `NEWS.md`: the Fine–Gray model, and cause-specific models;
  - the help pages;
  - `_pkgdown.yml`;
  - the status document.

## 8. Risks

- **survival's `finegray()`** (§2.2, §2.4).
  - The case-weight defect is avoided, not repaired: the package never passes `weights`, so a later survival that fixes it changes nothing. The engine-identity tests compare with `finegray()` without weights.
  - The weights that are not finite come from the data (small providers with delayed entry), and pprof_py fails on the same data. The error names the providers, and the help says so.
  - A change in a later survival to `finegray()`'s expansion would show in the engine-identity tests and the comparisons with the fixtures.
- **The chunked transform** (decision 2). It relies on `finegray()` computing each stratum from its own rows once delayed entry is decided, and restates `finegray()`'s rule for that decision. survival 3.8-12's source shows both, and the engine-identity tests hold the chunks to one stratified call bitwise; a later survival that changed either would fail them, and the fix would be one call, (a). With (a) instead, fits with thousands of providers take minutes.
- **Telling survival's maintainers.** The case-weight defect, and the transform's cost with many strata, are survival's. Reporting them is an action outside the fork, so it is the project lead's to take or to ask for.
- **Memory.** The expansion is several times the data at 100 rows per provider and 43 times at 1,000. A fit holds it, with its design, while survival runs.
- **Regenerating the fixtures** (decision 6). The generator reproduces every file byte for byte (DEC-096), and the change adds one case, so the diff reports should show additions only. Any other difference stops the work for the project lead.
- **Test time.** The fixtures' expansions have about 1,000 to 1,200 rows; the unit tests use small data. The new case's comparisons stay behind `skip_on_cran()`.
- **The tarball.** The core fixtures do not change but for the manifest. The new R code and help add a few kilobytes to C4's 4,953,987 bytes, 46 KB under the 5 MB at which `R CMD check --as-cran` notes the size.
