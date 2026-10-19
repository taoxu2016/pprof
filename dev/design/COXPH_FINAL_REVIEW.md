# CoxPH phase: final review

> **Status: approved by the project lead at the C6 gate (DEC-140), 2026-10-16.** The review of the CoxPH phase against its brief (`dev/coxph_brief.md`): the success criteria of its §11 with their evidence, the deliverables, the register entries that await a methodology owner, the open items for the project lead, and the known limits. Branch `coxph/phase-6`; the package as of `e772ce4`, the last commit that changed it.
>
> **Update, 2026-10-19:** the project lead, named the methodology owner (M-16), signed off the Class B items and the questions of §3 (DEC-142); the text below is as approved at the gate.

The CoxPH phase added Cox proportional hazards models to pprof, following pprof_py v0.7.0 (commit `9320766`), with estimation delegated to survival and glmnet (DEC-086), in seven phases on their own branches: C0 the design (`dev/design/COXPH_DESIGN.md`), C1 the fixtures and the baseline, C2 the data layer and the model stratified by provider, C3 its provider profiling, C4 the elastic-net model, C5 competing risks, and C6 the documentation and hardening. Each phase's plan is `dev/design/COXPH_C<n>_PLAN.md`, its evidence `dev/design/coxph-facts/`, and its dated log `dev/COXPH_STATUS.md`.

## 1. The brief's success criteria

| # | Criterion (§11) | Evidence | Status |
|---|---|---|---|
| 1 | Every in-scope pprof_py capability is available through the contract, and the dispositions of §2.4 hold | Table 1.1 | Met |
| 2 | The Cox comparisons pass under the calibrated tolerances on every CI platform; every difference from pprof_py has a register entry with a decision; statistical behavior unchanged except signed-off Class B items | §1.2 | Met on every platform (DEC-141); the Class B items' sign-off by a methodology owner is open (§3) |
| 3 | The existing families are bitwise identical to before the phase, and the full reference suite passes | §1.3 | Met |
| 4 | pprof contains no estimation code that survival or glmnet provides | Table 1.4 | Met |
| 5 | Performance meets §3.7, with the evidence in `dev/bench/` | §1.5 | Met: the MUST by every fit; the SHOULD not everywhere, as DEC-098 allows |
| 6 | `R CMD check --as-cran` is clean, and coverage of the new R code is at least 90% | §1.6 | Met: 0 errors, 0 warnings, the two notes of the earlier gates; 99.82% of the added R lines covered |
| 7 | Another developer can add the later models of §2.2 by following the developer guide | §1.7 | Met, after the dry run's fixes |

The Class B items of criterion 2 that statistical behavior depends on were decided under the project lead's delegation and confirmed by the project lead; their methodology owners' sign-off is open (§3, M-16).

### 1.1 The capabilities of §2.4

| pprof_py v0.7.0 | Disposition in the brief | As built |
|---|---|---|
| `CoxPH` | C2, delegated to survival | `fit_cox_stratified()`, survival's fitters called as `coxph()` calls them, bitwise its fit (DEC-091, DEC-099, DEC-100); `baseline_hazard()`, `predict()`, `residuals()` from survival |
| `calculate_standardized_measures()`, `test()` (mid-p, exact) | C3, implemented in pprof | `standardize_providers()`, `test_providers()`, `funnel_limits()`, `profile_providers()` for `fit_cox_stratified()` fits (K-136 to K-142, K-149) |
| Empirical null | later brief, for all families | not built |
| `PenalizedCoxPH`, `PenalizedCoxPHCV` | C4, delegated to glmnet ≥ 5.0; CV statistics in pprof | `fit_cox_penalized()` and `select_lambda()` (K-143, K-144; DEC-113 to DEC-120) |
| `CauseSpecificCoxPH` | C5, delegated | `fit_cox_stratified()` with the event of interest in `Surv()` (DEC-129) |
| `FineGrayPH` | C5, delegated | `fit_fine_gray()`, survival's `finegray()` per chunk of providers and the stratified fitter (K-145; DEC-121 to DEC-128) |
| `GroupLassoCoxPH(CV)`, `ProviderPenalizedCoxPH`, `DiscreteSurvival` and its penalized form, `FrailtyCoxPH`, `TimeVaryingCoxPH` | later briefs | not built; the developer guide says where each would start |
| `CoxPHSelector` | not carried over | not built |
| `tmerge`, `survsplit`, `finegray_transform` | not carried over | survival's own functions |
| Preflight report | `check_data()` | `check_data()` for survival data (DEC-104) |

Outputs pprof_py gives that the package does not, each decided by the project lead and changing no number: baselines and curves of fits without covariates (D-75), the penalized paths' per-λ log-likelihoods, interpolated coefficients, and per-λ convergence (D-79), and the Fine–Gray model's subdistribution cumulative hazard, baseline, and residuals (D-81).

### 1.2 The Cox comparisons on every platform

`validation/run-cox-reference.R` (DEC-135) runs the four Cox reference test files on both fixture sets and the adapters' engine-identity tests, and writes `validation/cox-equivalence-report.md`; `rewrite-reference.yaml` runs it on the fixtures' platform (Windows, R 4.4.0) and on Linux, macOS, and Windows with R release or oldrel-1. At the gate, at `e772ce4` on this machine: 1,897 comparisons, 1,871 within their tier (the largest ratio 0.995, `tiny-ties` Breslow coefficients), 26 beyond their tier as a register entry decides (D-56, D-58, M-23), none failing, and no test failing; `dev/reference/cox/calibrate.R` reproduces the calibration report byte for byte (1,058 of 1,058 rows; 84 explained by D-56, D-57, D-58, D-64, D-78, and M-23; 4,724 flags compared, none differing).

On CI, at `f1c8414` (runs 38942129736 and 38942133656), no comparison failed on any platform, and the fixtures' platform, Windows with R 4.6.1, and Ubuntu with R 4.6.1 passed every test. On macOS (R 4.5.3, arm64) two tests of the full set failed: the held-out event weights of `penalized-combined`'s cross-validation, sums of non-integer case weights, differed from the generator's in the last bit, since R's `sum()` accumulates in long double on x86_64, where the fixtures were made, and in double on arm64. They are now compared at the `closed_form` tier, as the cross-validation's other sums are (DEC-141, `085eaeb`). At `085eaeb` (run 38954075826) every platform passes: 1,897 comparisons, none failing, and no test failing.

Every difference from pprof_py has a register entry (D-56 to D-81), each with a decision (§3).

### 1.3 The existing families

- The `data_prepare()` snapshot (`validation/fixtures/data-prepare-snapshot.rds`), the signatures of the data objects of the 368 reference cases recorded before the phase changed the data layer, and its test, which runs in `devtools::test()`.
- `devtools::test()` and `validation/run-reference.R`, in a clean worktree, at every commit that touched shared code, C2 to C6: no failure, and 368 of 368 cases with the committed equivalence report reproduced but for its date and commit. In C6: at `2f26c8c`, `6df2b54`, and `266bb38` (1,317, 1,320, and 1,320 tests), and at the gate, at `e772ce4` (1,320 tests, 12,696 expectations, none failing, skipped, or warning).
- The namespace comparison (`dev/tools/namespace_compare.R`) from `a919c0b`, C6's base, to the working tree: only the three changes C6's commit `6df2b54` intended (`fit_fine_gray()`, `data_check_survival_values()`, and the added `profile_spec.pprof_cox_penalized()`); exports, data, and C++ unchanged. At the gate, from `a919c0b` to `e772ce4`: the same.
- CI's reference workflow matched pprof 1.0.3, run on each platform, on 368 of 368 cases on Windows, macOS, and Linux at `f1c8414`.

### 1.4 No estimation code that an engine provides

Every computation in the Cox files, and who does it:

| Computation | Where | Engine | Why |
|---|---|---|---|
| Partial likelihood, Newton-Raphson, information, variance | `survival_run_fitter()` | survival's `coxph.fit()`, `agreg.fit()` | delegated (DEC-091, DEC-100) |
| Robust variance | `survival_robust_vcov()` | survival's dfbeta residuals (`residuals.coxph()`) on the fitter's result | `coxph()`'s own step (DEC-099) |
| Baseline hazards, survival curves, cumulative incidence, score and dfbeta residuals | `survival_engine_fit()`, then `survfit()` and `residuals()` | survival | delegated (DEC-091) |
| Fine–Gray expansion | `survival_finegray_call()` | survival's `finegray()`, per chunk of 50 providers | delegated (DEC-121, DEC-122); the case weights multiplied after the call, where survival 3.8-12's own `weights` argument errs (DEC-123) |
| Elastic-net paths | `glmnet_fit_path()` | glmnet | delegated (DEC-113, DEC-115) |
| The score at the null point, for λ_max | `glmnet_scaled_score()`, `survival_fit_columns()` | glmnet's `coxgrad()` and survival's fitter | composed from the engines (DEC-113) |
| The λ grid's spacing, the column screen | `cox_penalized_grid()`, `cox_penalized_columns()` | none: pprof_py's definitions (K-143) | glmnet's own grid and early stop differ (COXPH_DESIGN §E.2) |
| Fold deviances | `glmnet_deviances()`; the saturated term in `cox_saturated_loglik()`; the shift with `survival_partial_loglik()` | glmnet's `coxnet.deviance()`; survival's fitter | composed; pprof_py's Breslow saturated term for both tie methods (K-144, DEC-114) |
| Cross-validation summaries and rules | `select_lambda()` | none: pprof_py's definitions (K-144) | the brief's §2.4: CV statistics computed in pprof |
| Near-tied times in `check_data()` | `aeqSurv()` | survival | delegated |
| Expected events at the national Breslow baseline | `cox_expected_events()` | none: He and Schaubel's measures as pprof_py computes them (K-136, K-137) | profiling, the brief's §2.1 and §5.3 |
| Direct expectations, Poisson tests, mid-p and exact limits, funnel limits | `cox_direct_expected()`; `R/inference-poisson.R`; `R/profile-funnel.R` | none (K-138, K-140 to K-142, K-149) | profiling |
| Covariate p-values and intervals from the engine's variance | `R/inference-coefficients.R` | none (K-148) | inference on the engine's estimates |

The developer guide's rule 3 states this line for later models.

### 1.5 Performance (§3.7)

`dev/bench/results/cox-final-20261016.md` gathers the phase's runs, C1's baseline to the C6 runner's run (38957683403, at `085eaeb`).

- **The MUST** (at most 10% slower than the engine calls plus the preparation of their inputs, DEC-105): every fit meets it in its latest run, with estimates equal to the engine calls' bitwise. The two fits C3 found at the rule's line (providers-7500 Breslow, covariates-5 robust) meet it on the C3 runner; the C6 dispatch used the workflow's default selection, the Fine–Gray tasks, which all meet it (0.97 to 1.11 times the comparator, medians), so those two were not measured again at the final code.
- **The SHOULD** (no slower than pprof_py, read by DEC-098 as applying to the robust variance, the measures, and the tests): met by the mid-p test with its limits (20 to 600 times faster), the exact test (faster but at 10,000 rows, both under 0.02 s), and the elastic-net model (4.5 and 9.3 times faster); not met, as DEC-098 allows, by large fits, by the robust variance beyond 5 covariates, by the measures at 10,000 rows and with 7,500 providers (0.02 s and 0.07 s more), and by the Fine–Gray fits (1.2 to 1.4 times pprof_py's time on its 8 threads, on center).

Status: met, with the SHOULD's exceptions DEC-098 allows.

### 1.6 `R CMD check` and coverage

- **Coverage** (`dev/tools/coverage_added.R` against `ea7c07b`, the phase's base, at `e772ce4`): 1,634 of the 1,637 R lines the phase added are covered, 99.82%, and the package's 97.58%; the brief asks for 90%. The three lines left are in §5.
- **`R CMD check --as-cran --no-manual`**, run alone at each documentation commit of C6 on a clean export of the commit: 0 errors, 0 warnings, and the two notes of the earlier gates, the website's address (404) and "unable to verify current time". On CI, every job of `rewrite-check` passes, with no note but on Ubuntu with R 4.4.0, which installs no suggested package (the installed size, the suggested packages, and the help's links to glmnet). At the gate (`e772ce4`, run alone on a clean export): the same, with `devtools::document()` leaving the generated files as committed and the tarball at 4,982,796 bytes. R-hub's check without long double was not run (DEC-138; §4).

### 1.7 The developer guide

`dev/DEVELOPER_GUIDE.md`'s "Delegated engines" gives the rules the adapters follow, the files a new model touches, models fitted to expanded rows, and where each later model of §2.2 would start; "Adding a model to pprof" shows a delegated model with a runnable `glm()` example; ARCHITECTURE §E.6 and §E.7 describe the survival models and the engines as built. A subagent without the session's context designed frailty Cox profiling and discrete-time provider models from these documents alone (`dev/design/coxph-facts/40_guide_dry_run.md`): it laid out both designs, found 19 gaps, 3 of them blocking, and the fixes are in `976836c`. The gaps left are those the documents rightly leave to a later brief: its reference, and its methodological questions.

## 2. Deliverables

The brief's §2.1, as built:

1. The model stratified by provider, with right-censored and counting-process data, strata, offsets, case weights, Breslow and Efron ties, model-based and robust variances, coefficient inference, baselines, residuals, and predictions (C2). The unstratified fit was not offered (C0, DEC-090).
2. Provider profiling: expected counts, indirect and direct ratios, person-time, the mid-p and exact tests with intervals and flags, funnel limits and plots, caterpillar plots, and `profile_providers()` (C3).
3. The elastic-net model with strata, counting-process data, offsets, and weights, its paths, cross-validation as pprof_py defines it, and λ selection; no profiling at a selected λ (M-34) (C4).
4. Competing risks: cause-specific models with their measures and tests, and the Fine–Gray model with predicted cumulative incidence (C5).
5. `check_data()` for survival data (C2).
6. Documentation: the help pages; the vignette "Profiling providers with time-to-event outcomes"; the Cox sections of "Models and what they support", "Statistical methods", and "Getting started"; NEWS; the developer guide and ARCHITECTURE as built (C6), with the wording list `dev/design/COXPH_C6_WORDING.md`, approved by the project lead.

And the validation the brief's §6 asks for: the Cox fixtures from pprof_py and the pinned engines with their generator (C1, DEC-093, DEC-096), the calibrated tiers (DEC-097, DEC-109, DEC-116, DEC-125), the final equivalence report (C6), the simulation study's Cox rows (C6, DEC-134), and the benchmarks against the engine calls (C1 to C6).

## 3. The register

**Differences from pprof_py** (`dev/DISCREPANCIES.md`, "The CoxPH phase"): D-56 to D-81 (D-76 unused), each with a decision; C6 found no new difference (DEC-141 concerns a test's arithmetic across platforms, not the package's results). The Class B entries decided under the project lead's delegation in C0, and D-78 decided in C4, await a methodology owner's sign-off (M-16): D-56 (the robust variance with Breslow ties and delayed entry), D-57 (Newton-Raphson's step order), D-58 (zero case weights), D-59 (aliased covariates, no events), D-60 (the reported baseline hazard), D-61 (the cross-validation's folds), D-64 (large linear predictors), D-72 (penalized coefficients at λ_max), and D-78 (penalized paths with few events per covariate). The other Class B entries change no number and were decided by the project lead: D-65 and D-66 (deferred to later briefs), D-67 (no bootstrap standard error), D-75, D-79, and D-81 (outputs not given).

**Questions** (`dev/OPEN_QUESTIONS.md`, "The CoxPH phase"): M-23 to M-41, the brief's §10 questions and C0's, decided under the delegation and confirmed by the project lead; their methodology owners' confirmation waits for M-16.

**Operating characteristics for the methodology owners** (the simulation study, DEC-134; informational, DEC-053): at level 0.95 the mid-p test flags 4.6% to 4.8% of the providers without an effect and the exact test 3.4% to 4.0%; the indirect ratios' intervals cover 95.2% to 95.4% (mid-p) and 96.0% to 96.5% (exact) of the null providers' ratios.

## 4. Open items for the project lead

- **The methodology owners** (M-16): the Class B items and questions of §3. Closed on 2026-10-19: the project lead, as methodology owner, signed them off (DEC-142).
- **Reports upstream**: survival's `finegray()`, which applies its `weights` argument to the wrong rows after the first stratum and goes over all rows once per stratum (DEC-122, DEC-123); and pprof_py's defects (the brief's Appendix B). Whether and how to report them is the project lead's decision.
- **The website's address**, which `R CMD check` notes as 404 until the site is published (DEC-066).
- **The CRAN submission** (`cran-comments.md`), deferred by the project lead on 2026-10-16, with R-hub's check without long double before it (DEC-138).
- **`CLAUDE.md`'s "Current phase"**, once the phase closes (the gate report proposes the text).
- **`main`**, which holds `f1c8414` at the project lead's request; the phase's later commits reach it with the gate's approval, best through a pull request, which also runs `rewrite-sanitizers`, a workflow that runs on pull requests only and has not run on this phase's pushes.
- **`rewrite-bench.yaml`'s first run** (DEC-137).

## 5. Known limits

- **The SHOULD of §3.7** (DEC-098): pprof_py is faster on large fits, on the robust variance beyond 5 covariates, on the Fine–Gray fits (1.2 to 1.4 times, against its eight threads), and on the measures at 10,000 rows and with 7,500 providers (0.02 s and 0.07 s). DEC-105's alternative 3, an adapter that copies its inputs less, was not taken.
- **Not run in C6**: `rewrite-bench.yaml`, whose setup was repaired (DEC-137); R-hub's check without long double (DEC-138), deferred with the CRAN submission by the project lead; and the two fits at DEC-105's line at the final code (§1.5).
- **Penalized paths with few events per covariate** end where glmnet's solutions end (D-78).
- **Fine–Gray weights** that small providers with late entries leave undefined raise an error naming the providers (D-80).
- **`plot_volume()`** counts rows, which with several rows per patient are not patients (DEC-133).
- **The tarball** is 4,982,796 bytes at `e772ce4`, 17,204 under the 5,000,000 at which `R CMD check` notes its size; the vignettes' plots are at 72 dpi (DEC-131), and more documentation would need the next fallback, one plot fewer, or a pkgdown-only article.
- **Lines no test reaches** (§1.6): `R/data-survival.R:189-190`, the refusal of a cluster column that is neither atomic nor a factor, which no input reaches: a list column stops earlier at R's own error in the complete-rows check, as in every family, and a matrix column arrives indexed as a vector, that is, as its first column; and `R/inference-poisson.R:127`, the growth of the mid-p limits' bracket, which pprof_py's code has for a null other than the theoretical one: under the theoretical null the statistic at the bracket's first end is already below its threshold.
