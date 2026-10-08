# Cox Proportional Hazards Models in `pprof` — Phase Brief

> **Status: approved by the project lead on 2026-10-07 (DEC-086).** Approving the brief approves its plan, scope, and gates. Items marked *proposed* and the questions of §10 still need the sign-off that §10 names.

## 0. How to use this brief

This brief states what the CoxPH phase must deliver and which constraints are non-negotiable. It continues the v2 rewrite's brief (`git show 5977087:dev/pprof_rewrite_brief.md`), whose principles, conflict order, and discrepancy classes still apply. Where the two differ for Cox models, this brief governs. Its companions:

- `CLAUDE.md` and `.claude/rules/`: the working rules.
- `dev/DEVELOPER_GUIDE.md` and `vignettes/adding-a-model.Rmd`: the model contract.
- `dev/design/ARCHITECTURE.md`: the design as built. Its §E.6 sketched an unstratified Cox model with explicit provider effects; this brief starts with the provider-stratified model instead (§2), and Phase C0 updates §E.6.
- The registers: `dev/CONVENTIONS.md` (`K-xx`), `dev/DISCREPANCIES.md` (`D-xx`), `dev/DECISIONS.md` (`DEC-xxx`), `dev/OPEN_QUESTIONS.md` (`M-xx`).
- The phase's status document, `dev/COXPH_STATUS.md`, created when Phase C0 starts: a dated entry after each session with material progress, naming the next step.

Requirement keywords:

- MUST / MUST NOT: hard requirements.
- SHOULD / SHOULD NOT: strong defaults; deviate only with a recorded reason in `dev/DECISIONS.md`.
- MAY: optional.

When principles conflict: preserve validated behavior > auditability > correctness and safety > clarity > performance > aesthetics.

Work proceeds in phases separated by gates (§4). At every gate, run `/phase-gate`, report, and STOP until the project lead approves.

The evidence behind this brief, measured on 2026-10-07, is in Appendix A. Defects found in `pprof_py` are in Appendix B; they MUST NOT be reproduced unless a sign-off says so.

---

## 1. Objective and strategy

**Objective.** Add Cox proportional hazards models for provider profiling to `pprof`, through its model contract, reproducing the validated statistical behavior of `pprof_py` v0.7.0:

- the provider-stratified Cox model, with SMR/SHR-type standardized measures and provider tests;
- elastic-net Cox models;
- competing risks.

**Strategy.**

1. **Delegate estimation.** `survival` fits the Cox models; `glmnet` (≥ 5.0) fits the elastic-net Cox paths. `pprof` MUST NOT reimplement any of these:
   - the partial likelihood, tie methods, and risk sets;
   - Newton–Raphson;
   - the model-based and robust variances and the residuals;
   - the fitted model's baseline hazard and predictions;
   - Fine–Gray weighting and cumulative incidence;
   - the elastic-net solver.

   This is the rule the rewrite applied to `lme4`, for the same reason: the engine is mature, and it is itself the reference.
2. **Own what no R package provides.** This covers:
   - survival data in the data layer;
   - expected counts, standardized ratios, Poisson provider tests, intervals, flags, and funnels for time-to-event outcomes;
   - the integration with the contract, inference, and presentation layers.

   The closed-form Breslow sums behind the measures (§5.3) belong to this profiling layer, as in `pprof_py` and `pprof_spark`.
3. **Own estimators only where R cannot do the job, and only through later briefs** (§2.2):
   - explicit provider effects at national scale;
   - penalized provider models;
   - discrete-time provider models.

**Why** (Appendix A):

- **`pprof_py` reimplements `survival`.** Its Cox engine is a reimplementation of `survival::coxph()`, validated by agreeing with it. With conventions aligned, the two agree to 2e-15 on 200,000 rows and 3,000 strata.
- **`survival` is stable.** On `pprof_py`'s reference datasets, its outputs did not change from version 3.5-8 to 3.8-12, nor between Linux and Windows.
- **`survival` is fast.** Its engine runs faster than `pprof_py`'s.
- **`glmnet` reproduces the penalized paths.** Version 5.1 matches `pprof_py`'s paths to 2e-7 and runs 3–8 times faster.
- **Reimplementing adds risk.** It would recreate the risk that produced `pprof_py`'s R-parity defects (Appendix B) without adding any capability.
- **Independent validation comes from `pprof_py`.** Fixtures taken from `survival` alone would only test our adapter.

---

## 2. Scope

### 2.1 In scope

1. **The provider-stratified Cox model** (He and Schaubel's two-stage approach). It covers:
   - right-censored data, and counting-process `(start, stop]` data (delayed entry, recurrent events);
   - provider strata, offsets, and case weights;
   - Breslow and Efron ties;
   - model-based and cluster-robust variance, and coefficient inference;
   - the baseline hazard, and residuals and predictions as `survival` provides them.

   Phase C0 decides whether an unstratified (pooled) fit is also offered, as `pprof_py` allows.
2. **Provider profiling for time-to-event outcomes.** It covers:
   - indirect and direct expected counts, standardized ratios (SMR, SHR), and person-time;
   - the mid-p and exact Poisson tests, with intervals and flags;
   - funnel limits and plots, caterpillar plots, and `profile_providers()`.

   Only the theoretical null is in scope; §2.2 covers the empirical null.
3. **Elastic-net Cox** (lasso, ridge, elastic net), with strata, `(start, stop]` data, offsets, and weights. It covers:
   - coefficient paths;
   - cross-validation as `pprof_py` defines it;
   - λ selection.

   Profiling at a selected λ is in scope only if Q12 adds it.
4. **Competing risks**:
   - cause-specific Cox models, with cause-specific provider measures and tests;
   - the Fine–Gray model, through `survival::finegray()` and a weighted, cluster-robust Cox fit, with predicted cumulative incidence.
5. **Data checks** for survival data in `check_data()`.
6. **Documentation**:
   - help pages;
   - a vignette on profiling with time-to-event outcomes;
   - `NEWS.md`;
   - the developer guide and ARCHITECTURE, updated as built.

### 2.2 Later briefs

Each of these needs its own brief, a methodology sign-off, and a reference.

- **Explicit provider effects at national scale.** This is ARCHITECTURE §E.6's model, λ_ij(t) = λ0(t)·exp(γ_i + z_ij'β).
  - **Why a new engine.** `coxph()` with provider indicators takes 144 s at 1,000 providers, and the time grows about as K³ (Appendix A). This is where a new algorithm has clear value.
  - **What it would be.** A block Newton or MM engine in C++, analogous to SerBIN, with provider-effect tests and intervals.
  - **Starting point.** `pprof_py`'s `ProviderPenalizedCoxPH` is design input, not a reference, until B2 and B3 are fixed.
- **Penalized provider models**: group lasso Cox with strata, `(start, stop]` data, and ties; provider-penalized Cox; discrete-time provider models.
  - **Sources.** The group's `grplasso` package, and `pprof_py` once B2, B3, B9, and B10 are fixed.
  - **Licensing.** `grplasso` is GPL-3 and `pprof` is MIT, so copying `grplasso`'s code into `pprof` needs its authors to relicense it.
- **Unpenalized discrete-time provider models**, through person-period expansion and `pprof`'s own logistic FE engine.
- **Empirical-null calibration** of provider tests, for every family at once. No family in `pprof` has one, and adding it for Cox alone would split the families.
- **Further models**:
  - random-effect (frailty) Cox profiling, with `coxme` or `survival::frailty()`;
  - time-varying coefficients;
  - Fine–Gray-based provider measures, which would be new methodology.
- **Performance beyond §3.7**: threaded kernels, and data beyond one machine's memory. For the latter, interoperate with `pprof_spark`, which already implements the Cox workflows at parity with `pprof_py`.

### 2.3 Non-goals

- MUST NOT reimplement what §1 delegates, or port `pprof_py`'s engine code. Behavior specifications come from `pprof_py` v0.7.0's documented behavior, verified against its outputs.
- MUST NOT change any result of the existing families. The logistic, linear, Firth, RE, and CRE results stay bitwise identical.
- MUST NOT carry over `pprof_py`'s generic stepwise selection (`CoxPHSelector`). `MASS::stepAIC()` and `StepReg` cover it, and it is outside profiling's core.
- Exact ties are not offered. `pprof_py` has none, and `survival` provides them for anyone who needs them.
- No Python at run time. Python appears only in the fixture generator.
- A CRAN release is not part of this work unless requested, but the result MUST stay CRAN-ready.

### 2.4 Every `pprof_py` survival capability, and where it goes

| pprof_py v0.7.0 | Validated there against | Disposition |
|---|---|---|
| `CoxPH` | `survival::coxph()` | C2, delegated to `survival` |
| `calculate_standardized_measures()`, `test()` (mid-p, exact) | one R golden file; `pprof_spark`'s parity tests | C3, implemented in `pprof` |
| Empirical null (`null_model`) | `MASS::rlm()` golden files | later brief, for all families |
| `PenalizedCoxPH`, `PenalizedCoxPHCV` | `glmnet` 4.1-8 | C4, delegated to `glmnet` ≥ 5.0; CV statistics computed in `pprof` |
| `CauseSpecificCoxPH` | `survival::coxph()` | C5, delegated |
| `FineGrayPH` | `survival::finegray()` | C5, delegated |
| `GroupLassoCoxPH`, `GroupLassoCoxPHCV` | `grplasso::Strat.cox`, one stratum, no ties | later brief |
| `ProviderPenalizedCoxPH` | internal tests only | later brief, after B2 and B3 |
| `DiscreteSurvival`, `ProviderPenalizedDiscreteSurvival` (and CV classes) | internal tests only | later brief, after B9 |
| `FrailtyCoxPH` | none (no tests) | later brief |
| `TimeVaryingCoxPH` | none (no tests) | later brief |
| `CoxPHSelector` | a hand-written R loop | not carried over (§2.3) |
| `tmerge`, `survsplit`, `finegray_transform` | R's bundled cases | not carried over; `survival`'s `tmerge()`, `survSplit()`, and `finegray()` cover them |
| Preflight report, R-comparison harness | — | `check_data()` (C2); the harness is not needed in R |

---

## 3. The equivalence contract

### 3.1 References

- **`pprof_py` v0.7.0** (commit `9320766`, tag `v0.7.0`) is the reference for definitions, defaults, and numbers. It is the same pin as `pprof_spark`'s `reference/REFERENCE.lock`. `pprof_py` itself is validated against `survival` 3.5-8 and `glmnet` 4.1-8 for the components §2.4 marks so.
- **`survival`** is the engine. Its version is recorded in every fixture manifest. Delegated results are compared with direct `survival` calls, which tests the adapter, and with `pprof_py`, which tests the method.
- **`glmnet` ≥ 5.0** is the elastic-net engine, called with every behavior-relevant argument explicit (§5.4).
- **Fixture inputs.** Phase C1 starts from `pprof_spark`'s committed Cox cases (`fixtures/cox/`, its ADR-0005):
  - six cases, each run with both tie methods;
  - `pprof_py` outputs for fits, iterates, baselines, residuals, measures, and tests, plus `survival`'s outputs.

  They are imported with their provenance (repository, commit, SHA-256), and C1 adds the cases of §6.
- **How fixtures are made.** Fixtures come only from a committed generator in `dev/reference/`. It runs:
  - the pinned `pprof_py` in a pinned Python environment;
  - pinned R packages in an isolated library.

  Tests MUST NOT need Python or `pprof_py`. Regenerating fixtures needs the project lead's approval and a diff report.

### 3.2 What must be preserved

Relative to `pprof_py` v0.7.0, unless a sign-off (§3.4) says otherwise:

- **The model.**
  - The Cox partial likelihood, with risk set {i : start_i < t ≤ stop_i}.
  - Breslow and Efron ties, as `survival`'s `agfit4` computes them.
  - Strata, offsets, and case weights.
  - The model-based variance, and the robust sandwich built from cluster sums of weighted score residuals.
- **Estimation defaults.** β⁽⁰⁾ = 0, Breslow ties, eps 1e-9 on the relative change in log-likelihood, at most 20 iterations, and model-based variance unless robust variance is requested.
- **The measures' definitions.**
  - η_i = x_i'β̂ + offset_i.
  - The national baseline is the Breslow estimator over all rows with η as offset, whatever ties fitted β̂, with rows unweighted.
  - Indirect E_j = Σ_{i∈j} e^{η_i}[Λ0(stop_i) − Λ0(start_i)].
  - Direct E^(j) = Σ over provider j's events of RS(t)/RS_j(t).
  - The ratios are O_j/E_j and E^(j)/O, with Σ_j E_j = O.
  - Person-time is Σ(stop − start).
- **The tests.** The mid-p (default) and exact Poisson tests as `pprof_py` defines them:
  - the exact test's cap of 0.999;
  - the mid-p floor of 1e-6;
  - Garwood limits for E < 100 and Byar's for E ≥ 100;
  - flags at level 0.95.

  The definitions are written out in `pprof_spark`'s `docs/spec/cox/provider-workflows.md` §1–2, from `pprof_py`.
- **Penalized Cox.**
  - `glmnet`'s objective, standardization, and λ-path rules, as `pprof_py` reproduces them.
  - `pprof_py`'s cross-validation: the grouped deviance per fold, normalized by the fold's event weight; all folds fitted on the full-data grid; the λ_min and λ_1se rules, with λ_1se as the default.
- **Fine–Gray.** The weights of `survival::finegray()`, with which `pprof_py` agrees exactly at v0.7.0 (Appendix A), and the cluster-robust variance.

Presentation MAY change, with documentation: names, container types, column names, row order (results are keyed by provider), and messages.

### 3.3 Conventions the adapter must set

`survival` and `pprof_py` differ in defaults and edge cases. The adapter MUST make each choice below explicit. A choice that changes a `pprof_py` number is Class B (§3.4).

| # | Point | pprof_py v0.7.0 | survival / glmnet | Proposed | Status |
|---|---|---|---|---|---|
| 1 | Default tie method | Breslow | Efron | Breslow, passed explicitly | preserves pprof_py |
| 2 | Near-equal times | compared exactly | merged (`timefix = TRUE`, through `aeqSurv`) | `timefix = FALSE`; recommend integer time units; `check_data()` warns about near-ties | Q1 |
| 3 | Robust variance with non-integer weights | off | turned on automatically | off unless requested | preserves pprof_py |
| 4 | Robust SE with Breslow ties, `(start, stop]` data, and tied deaths | defect B1 | correct | `survival`'s | Q2 (Class B) |
| 5 | Zero case weights | accepted (Efron then miscounts, B7) | error | drop the rows and report it, or error | Q3 |
| 6 | Aliased covariates; no events | pseudo-inverse; β̂ = 0 | NA coefficients | fail with a classed error naming the covariates | Q4 |
| 7 | Order of step halving and the convergence test | halves before testing (B6) | tests the full step first | `survival`'s | Q5 (Class B, ≤ 1e-8) |
| 8 | Reported baseline hazard | `basehaz(centered = FALSE)` form, including exp(mean offset) | same | report the baseline at x = 0 and offset 0 and document the difference; the measures don't use it | Q6 |
| 9 | Measures: unweighted rows; Breslow baselines whatever the ties | as stated | n/a | keep | Q7 (confirm) |
| 10 | Normalization of the penalized CV | per fold by event weight, on the full-data grid | `glmnet` 5.x: per fold by total weight, on per-fold grids | compute the CV statistics in `pprof`, as `pprof_py` does | Q8 |
| 11 | CV fold assignment | event-stratified, NumPy's RNG | `sample()` | event-stratified, with R's RNG; fixtures pass fold IDs | Q8 |
| 12 | Missing values | error | dropped (`na.omit`) | listwise deletion, as for `pprof`'s other families | Class A (pprof_py errors) |
| 13 | `glmnet`'s tie default | Breslow | Breslow with a warning; a switch to Efron is announced | pass `cox.ties` explicitly | preserves pprof_py |

`pprof_spark`'s maintainer approved the same choices for rows 4–8 (its D-20, D-21, D-23, and D-25). That approval does not carry over.

### 3.4 Discrepancy protocol

- **Where differences go.** Every difference from `pprof_py` v0.7.0 goes in `dev/DISCREPANCIES.md`, in a new section for the CoxPH phase that names the reference. Numbering continues from D-56. The fields and classes are CLAUDE.md's, with `pprof_py` as the reference:
  - **Class A:** `pprof_py` crashes, errors, misaligns inputs or results, or depends on row order. Such an item MAY be fixed, with a regression test.
  - **Class B:** any change to a number, flag, inclusion decision, or default. It MUST NOT be made without written sign-off from a methodology owner. Until then, reproduce `pprof_py` wherever `survival` can be made to; where it can't, the phase stops at that item.
  - **Class C:** the documentation contradicts the behavior.
- **Known defects.** Appendix B lists the defects already found. Phase C0 registers each one.
- **Unvalidated components.** Components with no validated behavior in `pprof_py` (§2.4: "internal tests only" or "none") get specifications, not ports, in their later briefs.
- **No shortcuts.** A discrepancy is never resolved by loosening a tolerance, editing a fixture, or dropping a case.

### 3.5 Tolerance policy

The existing tiers stay unchanged for the existing families. Phase C1 proposes new named tiers in `tests/testthat/helper-tolerances.R`. Each needs a one-line justification and calibration with negative controls, as `pprof_spark` did:

- **The calibration rule.** Agreement between `pprof_py` and `survival` must be at most 1 tolerance unit. Each negative control must differ by at least 10 units. The negative controls are the other tie method, one tied event moved, and one weight dropped.

The proposed tiers:

- **engine:** `pprof` against direct `survival` or `glmnet` calls on the same platform. This is the same computation, so the tier is near bitwise.
- **cox_reference:** `pprof` against the `pprof_py` fixtures at tight convergence (eps 1e-11 or tighter), per quantity class: coefficients, variances, and functions such as ℓ, U, and I.
- **penalized_path:** coefficient paths against `pprof_py` at identical λ values. The measured agreement was 2e-7 at `thresh = 1e-12`.
- **closed_form** (the existing tier 1): expected counts, ratios, and test statistics given the same β̂.
- **root:** mid-p limits, justified from `pprof_py`'s root-finder settings.

**Fits at default tolerance.** Iteration counts must match exactly. Estimates are compared under a tolerance justified by the size of the last Newton step, since the two convergence orders differ (row 7).

**Flags.** Flags must match exactly, except for providers within tolerance of a threshold; the equivalence report lists those.

### 3.6 Randomness, threads, and determinism

- **Randomness.** Package code never calls `set.seed()`. Cross-validation folds are drawn from R's RNG. Results are reproducible with `set.seed()` or with explicit fold IDs, but never across languages.
- **Threads.** `survival` and `glmnet` are single-threaded. A `threads` argument appears only where `pprof`'s own code runs in parallel. It defaults to 1, and results must be identical across thread counts.
- **Row order.** Results MUST NOT depend on row order. In `pprof_py` that dependence is a Class A item (B6).

### 3.7 Performance and memory

There is no pprof 1.0.3 baseline for Cox models.

**The baseline.** Phase C1 records one in `dev/bench/`.
- The grid goes up to at least 1,000,000 rows, 7,500 providers, and 50 covariates, with delayed entry and daily ties.
- It times direct `survival` and `glmnet` calls, and `pprof_py` v0.7.0.

**Requirements.**
- A `pprof` fit MUST NOT be more than 10% slower than the direct engine call it wraps plus the measures. It SHOULD be no slower than `pprof_py`.
- Fits SHOULD avoid the cost of the engines' formula interfaces where benchmarks show it matters. At 1,000,000 rows the engine took 6.3 s and `coxph()` 18 s (Appendix A). Phase C0 weighs this against the stability of calling `survival`'s lower-level fitters.
- Expected counts SHOULD be computed in closed form, not through a second Cox fit. In plain R they took 0.34 s at 1,000,000 rows; the second fit took 7.3 s.
- Mid-p intervals MUST be substantially faster than `pprof_py`'s, which took 50 s at 3,000 providers, with equal results under the root tier.
- Peak memory is recorded with the timings, and objects stay compact (DEC-004).

---

## 4. Phases and gates

Each phase is a pull request from its own branch (`coxph/phase-0` and so on) into `main`. At every phase:

- the package builds;
- `devtools::test()` and the full reference suite pass;
- `R CMD check` shows nothing new;
- the existing families are bitwise identical.

| Phase | Deliverables | Gate |
|---|---|---|
| C0. Design and decisions | The design document (§9): behavior specifications, API and naming additions, data-layer and contract changes, adapter design, validation plan, dependency decisions. The questions of §10 registered; conventions and discrepancy entries; the process changes of §12 listed | STOP for approval |
| C1. Reference capture | The Cox fixture generator (`dev/reference/`) and its pinned Python environment; the imported `pprof_spark` cases and the new cases of §6; manifests; the calibration report; tolerance tiers; the benchmark baseline | STOP |
| C2. Data layer and the stratified Cox model | `Surv` responses, entry times, weights, and offsets; `check_data()`; the `survival` adapter; the fit function and object; coefficient inference; baseline, residuals, and predictions; contract methods; tidy and print methods | STOP for architecture review |
| C3. Provider profiling | Expected counts, standardized measures, Poisson tests, intervals, flags, funnels, plots, `profile_providers()`; the contract hooks of §5.6 | STOP |
| C4. Elastic-net Cox | The `glmnet` adapter, paths, cross-validation, selection, and capabilities; profiling at a selected λ only if Q12 adds it | STOP |
| C5. Competing risks | Cause-specific models and their profiling; Fine–Gray with predicted cumulative incidence | STOP |
| C6. Documentation and hardening | Vignette and help pages; `NEWS.md`; the developer guide and ARCHITECTURE as built; the final equivalence and benchmark reports; coverage | STOP for final review |

C4 and C5 depend only on C2 and C3, and MAY run in either order.

---

## 5. Architecture requirements

### 5.1 Data layer

- **Responses.**
  - Accept `Surv(time, event)` and `Surv(start, stop, event)` responses.
  - Events are 0/1 or logical; the competing-risk entry points also accept a cause code.
  - For `(start, stop]` data, start ≥ stop is an error.
  - `pprof_py` rejects a right-censored time of 0 and `survival` accepts it; C0 decides (Class A).
- **Weights and offsets.** Support case weights (a `weights` argument) and `offset()` terms for the families that declare them, without changing any existing family's results.
- **The gap today.** The data layer currently rejects weights, offsets, and any response with dimensions. It does not yet do what ARCHITECTURE §E.6's sketch assumed: pass a `Surv` response through, and screen on events.
- **Provider screening.**
  - Cox models screen no providers by default, as in `pprof_py` (Q10).
  - A provider with E_j = 0 gets the ratio `pprof_py` gives (Inf or NaN), and one classed warning counts such providers.
- **`check_data()` for survival data** checks for:
  - near-tied times (§3.3, row 2);
  - zero or negative weights;
  - intervals with start ≥ stop;
  - providers with no events or no person-time;
  - aliased covariates;
  - large covariate means (B5).

### 5.2 Model modules and engine adapters

- **One adapter per engine**, on the pattern of the `lme4` adapter (`R/model-mixed.R`):
  - the engine gets prepared data in `data_prepare()`'s row order;
  - the settings of §3.3 are explicit;
  - engine messages are captured, and engine errors become classed conditions;
  - only extracted components are kept: coefficients, both variances, log-likelihoods, iterations, convergence, the linear predictor, and whatever residuals and predictions need;
  - the engine object is kept only with `keep_data = TRUE`.
- **No provider-effect estimates.** The provider-stratified model has none.
  - Unless Q11 defines one, `provider_effects()` and the Wald provider tests raise `pprof_error_unsupported_inference`.
  - The model declares coefficient inference, the indirect and direct measures, its Poisson tests, and the funnel.
- **Standard methods** follow `survival` where it has a convention. For example, `nobs()` counts events, as `nobs.coxph()` does. C0 records each one.

### 5.3 Provider profiling for time-to-event outcomes

- **Measures.** Expected counts, ratios, and person-time are computed in `pprof` from the extracted β̂ and the data, as §3.2 defines them, and keyed by provider ID.
- **Tests.** The tests and intervals are `pprof_py`'s (§3.2). Their numerics use `stats` (`ppois()`, `qchisq()`, root finding) with documented settings.
- **Funnel.** The funnel uses Poisson precision E_j. Its flags come from the family's default test.

### 5.4 Elastic-net Cox

- **The call.** `glmnet` (≥ 5.0) is called with every behavior-relevant argument explicit:
  - `cox.ties`;
  - the λ grid;
  - `standardize` and the penalty factors;
  - strata (through `stratifySurv()`), offsets, and weights;
  - the convergence threshold.

  The default grid follows `pprof_py`'s rules, which reproduce `glmnet`'s.
- **Cross-validation.** CV statistics are computed in `pprof` from per-fold fits on the full-data grid, as `pprof_py` defines them (§3.3, row 10).
- **Inference.** No information-based inference is declared (ARCHITECTURE §E.5's rule for penalized models).

### 5.5 Competing risks

- **Cause-specific models.** One stratified fit per cause, with the other causes censored. Measures and tests are computed per cause, with competing events censored; this is what `pprof_py`'s `CoxPH` gives on recoded events. Q13 confirms the definition.
- **Fine–Gray.** `survival::finegray()` (with `id` for `(start, stop]` data) and a weighted Cox fit with cluster-robust variance. Predicted cumulative incidence comes through `survival`. There are no Fine–Gray-based provider measures (§2.2).

### 5.6 Contract and shared-layer changes

The contract review found that survival data needs changes outside a new module:

- the data layer (§5.1);
- `test_providers()`, which accepts only a closed list of binary-outcome tests;
- exact and score intervals, which hard-code the logistic model;
- indirect-measure limits, which can only use `mean_function(η)` and so cannot carry Λ̂0(t);
- direct standardization of a stratified fit, which needs provider positions;
- `validate_pprof_model()`, which requires provider effects.

**How C0 handles them.**
- It designs each change as a hook whose defaults reproduce the existing families, following DEC-046's pattern.
- It proves bitwise identity with the full reference suite, run before and after.
- ARCHITECTURE §E.4's rule that a new model changes no other file does not hold for this phase. C0 records why.

### 5.7 Naming

In C0, `dev/NAMING.md` gets:

- **The fit functions.** Proposed: `fit_cox_stratified()`, `fit_cox_penalized()`, `fit_cox_cause_specific()`, and `fit_fine_gray()`.
- **New arguments.** `weights`, `ties`, `robust`, and `cluster`, and how offsets and entry times are given.
- **Test values.** `"midp"`, and whether `"exact"` names each family's own exact test.
- **Result columns.** `person_time`.
- **"Rate" for time-to-event outcomes.** What it means; it is not offered until it is defined.

Names are spelled out (`cox`, `survival`); `ph` is not added to the whitelist.

### 5.8 C++

None is planned. C++ enters only with benchmark evidence from `dev/bench/` (CLAUDE.md). It goes in `namespace pprof::survival`, behind a thin adapter.

---

## 6. Testing and validation

These are required in addition to the rewrite's test layers:

- **A. Reference comparisons.** Every case of §3.1, with both tie methods and with default and tight fits, compared on:
  - ℓ, U, and I at β = 0 and at a fixed β;
  - iterates, baselines, residuals, and robust variances;
  - measures and tests;
  - penalized paths, and CV with fixed fold IDs.
- **B. Engine identity.** `pprof` against direct `survival` and `glmnet` calls, following DEC-043's pattern. These validate the adapter, not the method.
- **C. Closed-form unit tests.**
  - expected counts by hand on small data;
  - Σ_j E_j = O;
  - invariance to a common factor in e^η;
  - direct measures against a per-provider recomputation;
  - the national baseline against `basehaz()` of a `coxph()` fit with η as offset and Breslow ties, allowing for the offset factor of row 8;
  - Poisson tests against `ppois()`, and against `poisson.test()` where the two coincide;
  - limits against their defining equations.
- **D. Independent references.**
  - `coxph()` with provider indicators on small data, for the pooled model;
  - a simulation study of the size and coverage of the provider tests, as `validation/run-simulation.R` does for the other families.
- **E. Metamorphic tests.**
  - row order;
  - provider relabeling;
  - covariate order (B4);
  - rescaling time (β̂ and the measures are unchanged);
  - a constant shift of the offset (the measures are unchanged);
  - duplicated rows against weight 2, with Breslow ties.
- **F. Edge cases.**
  - no events at all;
  - providers with no events, with E_j = 0, or with one patient;
  - delayed entry at an event time;
  - daily ties, and near-tied times;
  - aliasing and separation;
  - large covariate means (B5);
  - missing values;
  - recurrent events with clusters;
  - strata without events.
- **G. Regression tests.** One per register entry.

**New cases**, beyond `pprof_spark`'s six:
- provider-scale data (thousands of providers) for measures and tests;
- recurrent events (SHR-shaped);
- near-tied times, with the `timefix` setting stated;
- zero weights;
- competing risks, with and without delayed entry;
- `pprof_py`'s penalized reference datasets.

**Precision.** Inputs are exact in text: integer times, and covariates on binary grids. Outputs are stored at full precision (hexadecimal floats, converted to RDS).

---

## 7. Dependencies

- **`survival`:** Imports. It is a recommended package shipped with R, LGPL ≥ 2. C0 sets the minimum version.
- **`glmnet` ≥ 5.0:** proposed for Suggests, with a classed error when it is absent (Q15). It is GPL-2 and adds foreach, shape, and RcppEigen.
- **`MASS`:** only with the empirical null (later brief).
- **Python, `pprof_py`, NumPy, numba:** only in the fixture generator's pinned environment, never in DESCRIPTION.
- **Not in this brief:** `grplasso` and `coxme`.

---

## 8. Documentation and user-facing changes

- **Help pages** for every new function, with examples that use at most 2 threads.
- **A vignette on profiling providers with time-to-event outcomes.** It covers:
  - data setup: `Surv`, delayed entry, recurrent events;
  - the stratified model, SMR/SHR, tests, and funnels;
  - competing risks and penalized models;
  - the conventions of §3.3, including the recommendation of integer time units and how results relate to `coxph()`'s defaults.
- **Other updates:**
  - `NEWS.md`;
  - the developer guide's account of delegated engines;
  - ARCHITECTURE §E.6, updated as built.

---

## 9. Phase C0 deliverable: the design document

`dev/design/COXPH_DESIGN.md`, with:

- **A. Behavior specifications** for every in-scope `pprof_py` function: inputs, defaults, outputs, edge cases, and conventions. Each is verified against `pprof_py`'s outputs and cites `pprof_spark`'s specifications where they apply.
- **B. The API**: functions, arguments, classes, and result columns; the `dev/NAMING.md` changes.
- **C. Data-layer changes**, and the plan that proves the existing families unchanged.
- **D. The contract mapping**: generics, family specification, and capabilities; the new hooks.
- **E. The adapters**: calls, settings (§3.3), extracted components, and error mapping.
- **F. The profiling algorithms**, with their cost.
- **G. The validation plan**: cases, generator, environments, tolerance tiers and their calibration, independent references, and the simulation study.
- **H. Dependency decisions.**
- **I. The benchmark grid and targets.**
- **J. Register entries**: conventions (K-131 onward), discrepancies (D-56 onward), questions (M-23 onward), and decisions (DEC-086 onward).

---

## 10. Questions to raise rather than assume

Each question has a proposed default. Phase C0 registers them in `dev/OPEN_QUESTIONS.md`. Q15 and Q16 are for the project lead; the rest are for the methodology owners.

| # | Question | Proposed default |
|---|---|---|
| Q1 | Near-equal times: compare them exactly, as `pprof_py` does, or merge them, as `coxph()` does by default? On day-resolution times stored as fractions of a year, the two differ by about 2e-4 in β̂. | Compare exactly (`timefix = FALSE`); recommend integer time units; warn about near-ties in `check_data()` |
| Q2 | Robust SE with Breslow ties on `(start, stop]` data with tied deaths: adopt `survival`'s correct value instead of `pprof_py`'s (B1, off by 0.4–11%)? | Adopt `survival`'s (Class B) |
| Q3 | Zero case weights: drop those rows, which equals omitting them, or raise an error, as `survival` does? | Drop them and report it |
| Q4 | Aliased covariates or no events: fail, return NA as `survival` does, or reproduce `pprof_py`'s pseudo-inverse? | Fail with a classed error naming the covariates |
| Q5 | Convergence order: adopt `survival`'s, which tests the full step, instead of `pprof_py`'s (≤ 1e-8 apart, row-order dependent)? | `survival`'s |
| Q6 | Reported baseline hazard: at x = 0 and offset 0, or in `basehaz(centered = FALSE)`'s form? | At x = 0 and offset 0, documented |
| Q7 | Measures: keep unweighted rows, and Breslow baselines whatever the fitted ties? | Keep |
| Q8 | Penalized CV: keep `pprof_py`'s normalization and full-data grid (equal to `glmnet` 4.1-8, not 5.x), and event-stratified folds? | Keep |
| Q9 | Which definitions must match: He and Schaubel's two-stage Breslow measures (`pprof_py`), a production measure such as CMS's SHR, or the internal `phregSHR` workflow, whose Breslow default `pprof_py` follows? | `pprof_py`'s; record how the others differ |
| Q10 | Provider screening for Cox models (M-13)? | None, as in `pprof_py` |
| Q11 | Should the stratified model report a provider "effect", for example log O/E with a standard error? | No: measures and Poisson tests only, as in `pprof_py` |
| Q12 | Profiling at a selected λ of a penalized model? `pprof_py` offers none. | Not in this phase |
| Q13 | Cause-specific measures with competing events censored, as `pprof_py`'s recoding gives? | Yes |
| Q14 | Test conventions: keep the exact test's cap of 0.999 and the mid-p floor of 1e-6? | Keep |
| Q15 | `glmnet` in Imports or in Suggests? (project lead) | Suggests |
| Q16 | Which later briefs of §2.2, and in what order? (project lead) | Explicit provider effects first |

---

## 11. Success criteria

1. Every in-scope `pprof_py` capability is available through `pprof`'s contract, and the dispositions of §2.4 hold.
2. All Cox reference comparisons pass under the calibrated tolerances on every CI platform. Every difference from `pprof_py` has a register entry with a decision, and statistical behavior is unchanged except for signed-off Class B items.
3. The existing families are bitwise identical to before the phase, and the full reference suite passes.
4. `pprof` contains no estimation code that `survival` or `glmnet` provides.
5. Performance meets §3.7, with the evidence in `dev/bench/`.
6. `R CMD check --as-cran` is clean, and coverage of the new R code is at least 90%.
7. Another developer can add the later models of §2.2 by following the developer guide.

---

## 12. Process changes only the project lead can make

- **`CLAUDE.md`**:
  - name this brief and the status document under "Current phase";
  - extend the fixture rule, which names only `tests/testthat/fixtures/reference/`, to the Cox fixtures and their second reference (`pprof_py`).
- **`.claude/rules/tests.md` and `.claude/settings.json`**: allow a second reference, and protect the Cox fixture folder as the existing one is protected.
- **`.claude/skills/phase-gate/SKILL.md`**:
  - it cites the removed `dev/pprof_rewrite_brief.md` and `dev/PROJECT_CONTEXT.md`, and "the Phase 1 baseline";
  - point it at this brief, at `dev/COXPH_STATUS.md`, and at the C1 baseline.
- **CI (`.github/workflows/`)**:
  - the workflows run only on `main` and `rewrite/**`; add `coxph/**`;
  - regenerating the fixtures needs a manual workflow with Python and the pinned `pprof_py`.

---

## Appendix A. Evidence (2026-10-07)

**Setup.** One Windows 11 machine (8 logical cores, 7.4 GB of memory):
- R 4.4.0 with `survival` 3.8-12, `glmnet` 5.1, and `data.table` 1.18.6.1;
- `pprof_py` v0.7.0 under Python 3.9.7, with NumPy 1.24.4, SciPy 1.13.1, pandas 2.3.3, and numba 0.57.1 (`pprof_py` declares Python ≥ 3.10).

**Scripts.** Each row names the script in `dev/design/coxph-facts/` that produced it. Its output sits beside it, and the folder's README says how to rerun them. Timings vary from run to run: an earlier run, with other work on the machine, was 20–40% slower. Phase C1 measures again with committed benchmarks in `dev/bench/`.

| Check | Result | Script |
|---|---|---|
| `pprof_py`'s survival tests | 283 passed, 1 skipped (`lifelines` absent), 1 failed. The failure is an end-to-end test of `pprof_py`'s R-comparison harness, which runs R only when `Rscript` is on the PATH and fails on Windows (B13); without `Rscript` it passes | 01 |
| `pprof_py`'s 87 `survival`-based reference outputs (R 4.3.3, `survival` 3.5-8, Linux), regenerated with `survival` 3.8-12 on R 4.4.0, Windows | 86 identical; 1 within 1e-15 | 02 |
| `pprof_py` against `survival` at tight convergence: 200,000 rows, 3,000 strata, 6 covariates, delayed entry, offset, weights, daily ties | Coefficients within 2e-15 (Breslow) and 1e-12 (Efron) with `timefix = FALSE`. With `coxph()`'s default `timefix = TRUE` they differ by 1.9e-4 and 1.6e-4 from the first Newton iterate on; `aeqSurv()` moved the times of 13,411 rows | 08 |
| Newton path, on `pprof_py`'s seven reference fits | `pprof_py`'s iterates equal R's to about 1e-14, and the iteration counts match at default settings. Final estimates are within 6e-9 (§3.3, row 7) | 12 |
| Fit time: 1,000,000 rows, 7,500 strata, 10 covariates | `survival::agreg.fit()` 6.3 s. `coxph()` 18.2 s (Breslow) and 14.8 s (Efron). `pprof_py` 9.4 s and 10.1 s. `coxph()` with clustered robust variance 17.8 s | 07 |
| Indirect expected counts, same data | Plain vectorized R: 0.34 s, with Σ_j E_j = O exactly. A second `coxph()` fit plus `basehaz()`: 7.3 s. `pprof_py`: 3.4 s | 07 |
| Fit time: 200,000 rows, 3,000 strata, 6 covariates | `coxph()` 2.0 s (engine 0.7 s); `pprof_py` 3.5 s (Breslow) and 2.6 s (Efron). `pprof_py`'s mid-p test with intervals: 50 s for its 2,997 providers | 07 |
| `glmnet` 4.1-8 → 5.1 on `pprof_py`'s penalized reference data | Paths moved by up to 2.5e-5. The CV normalization changed from fold events to fold weight: cvm shrank by exactly the event fraction (0.505), λ_1se moved from 0.0604 to 0.0876, and λ_min is unchanged. 12 of 13 of `pprof_py`'s `glmnet` tests still pass; the CV test fails | 02, 03, 04 |
| `glmnet` 5.1 against `pprof_py`: lasso, 100,000 rows, 500 strata, 50 covariates, delayed entry, offset, weights, the same 26 λ values | Coefficients within 2.2e-7, with the same active sets. 3.4 s (8.9 s at `thresh = 1e-12`) against 27 s | 09 |
| Provider effects as indicators in `coxph()` (20 rows per provider, 10 covariates) | 1.4 s, 13 s, and 144 s at 250, 500, and 1,000 providers. With provider strata: 0.03 s, 0.08 s, and 0.17 s | 10 |
| Fine–Gray with delayed entry | `pprof_py`'s transform equals `survival::finegray()` row for row (3,469 rows, weights within 6e-15). Coefficients are within 2e-14 for both tie methods. The robust SE is equal for Efron and 0.36% off for Breslow (B1) | 05 |
| SMR golden file (`tests/data/cox_smr/r_smr.json`, made with `survival` 3.5-8) | `pprof_py` reproduces it within 1.1e-14 | 13 |
| `survival`'s edge cases | Aliased covariate: NA. Zero weight: error. No events: NA coefficients. Non-integer weights: robust variance by default. A right-censored time of 0: accepted. A missing value: the row is dropped | 11 |

---

## Appendix B. Defects in `pprof_py` v0.7.0

These are not to be reproduced without a sign-off, and are to be reported upstream. Each was reproduced by running code on 2026-10-07, with the script in `dev/design/coxph-facts/` named in the evidence column, except where that column cites another source.

| ID | Defect | Evidence |
|---|---|---|
| B1 | Robust variance on `(start, stop]` data ignores Breslow ties for tied deaths (`inference/survival/robust.py:232`) | Robust SE 0.4% off R's here (05), and 8–11% off on `pprof_spark`'s fixtures (its X-015). Affects `FineGrayPH`'s default |
| B2 | The provider-effect score ignores delayed entry (`algorithms/survival/provider_effects.py:206-225`) | `ProviderPenalizedCoxPH` on left-truncated data: score off by 47, no convergence in 500 iterations, and the γ level drifts to 585 (13) |
| B3 | `ProviderPenalizedCoxPH` with Efron ties updates γ with the Breslow score. γ is identified only up to a constant | β off by 1.9e-3 and contrasts off by 2.7e-2, with convergence reported (13) |
| B4 | `calculate_standardized_measures()` matches covariates by position (`measures/survival/coxph.py:165`) | Reordering the columns changed E_j by up to 44% (13) |
| B5 | exp() is clipped at ±700 on the uncentered linear predictor (`utils/numerical.py:52`) | With a covariate shifted by 1,500, the coefficients are right but the martingale residuals move by 2.5, every subject gets the same cumulative hazard, and the robust variance raises `FloatingPointError` (13) |
| B6 | Step halving happens before the convergence test (`algorithms/survival/optimization.py:67-79`) | Estimates up to 6e-9 apart from R's on `pprof_py`'s own reference fits (12) and 1e-8 on `pprof_spark`'s; results depend on row order (`pprof_spark` X-010) |
| B7 | Efron counts zero-weight events among tied deaths | 0.67% coefficient change (`pprof_spark` X-013) |
| B8 | Singular designs are solved by pseudo-inverse without a warning; with no events, β̂ = 0 | `pprof_spark` X-011 and X-012 |
| B9 | Discrete-time models: `penalty_factor` raises `TypeError` (`models/survival/discrete_survival.py:281`); both classes ignore case weights; the provider version ignores `alpha` | Reproduced (13) |
| B10 | The bootstrap SE's likelihood is wrong with tied times (`utils/deviance.py:150-159`) | Off by 17 log-likelihood units on a tied example, exact without ties (13) |
| B11 | `tmerge`: a `tdc` without a value defaults to NaN, where R gives 0 (`data/timedep.py:309`) | From reading R's committed output |
| B12 | Stale documentation and missing provenance | The README's "26 failures"; the Fine–Gray "left-truncation mismatch", fixed in `22972ab`; "no convergence warning". No generator for `r_smr.json`, the empirical-null golden files, the selector data, or the `grplasso` golden files |
| B13 | The R-comparison harness writes Windows paths into its R script unescaped (`diagnostics/survival/validate_against_r.py:135`), so the script fails on Windows: R stops on `'\U'` | One test fails when `Rscript` is on the PATH (01) |
