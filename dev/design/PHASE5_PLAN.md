# Phase 5 plan: inference and profiling

Approved by the project lead on 2026-10-04, with decisions DEC-045 to DEC-053 (`dev/DECISIONS.md`), the fixture regeneration R-1 as listed below, and the recommendations of "Questions for the project lead": RE and CRE standardization accepts a numeric `null`, the measures tables follow DEC-048, and D-43 and D-44 are recorded as proposed. Branch `rewrite/phase-5`, created from `rewrite/phase-4` at `400f84b` (stacked until Phases 1 to 4 are merged into `rewrite/v2`). The gate is a STOP (brief §4): run `/phase-gate` and wait for approval.

The facts in "Facts gathered" were confirmed by running the pinned reference (`dev/reference/lib`) and the working tree at `71e0c73` on 2026-10-04. Treat anything else here as a hypothesis to confirm by running code before relying on it (CLAUDE.md).

## Goal and scope

Brief §4: "All tests, confidence intervals, standardized measures, and flags for every family, routed through the shared layers." DEC-040 assigns to Phase 5, for linear FE, linear and logistic RE, and linear and logistic CRE:

- the `profile_spec()` rows and capability declarations;
- provider tests, flags, provider-effect intervals, standardized measures and their intervals, and funnel limits, through the existing profiling functions;
- covariate tests and intervals (`test_coefficients()`, `summary()`, `confint()`);
- the wrappers of the old methods (`test`, `SM_output`, `confint`, `summary`) for `linear_fe`, `linear_re`, `logis_re`, `linear_cre`, and `logis_cre` objects;
- the removal of the 20 reference method files and of the reference's remaining C++ (`computeDirectExp()` and the rest of `src/Fixed_effect.cpp`, `src/header.{h,cpp}`, `src/myomp.h`).

Logistic FE and Firth are complete since Phases 3 and 4; Phase 5 must leave every one of their results bitwise unchanged.

### Scoping questions of the handoff

1. **`plot.linear_fe()` and the linear funnel (K-111): Phase 5** (DEC-045). `funnel_limits()` for linear FE is profiling, the family's capability table (ARCHITECTURE §E.3) lists it, and it is the last place where linear FE flags are computed. `plot.linear_fe()` becomes a wrapper in `R/compat-plots.R`, as `plot.logis_fe()` did in Phase 3: plot data from the new API, drawn by the reference's `ppfunnel_linear()` code unchanged, because the fixtures compare layer data. Phase 5 makes `plot_funnel()`, `plot_caterpillar()`, and `plot_flags()` work on the new families' results where a label or scale would otherwise fail (for example the y-axis label of a difference); their styling stays Phase 6. `caterpillar_plot()` and `bar_plot()` stay reference code until Phase 6 (DEC-034).
2. **The generics `test()` and `SM_output()`: move to the compatibility layer** (DEC-045). They are the exported entry points of the old methods, so they stay, unchanged, until the wrappers are removed after the deprecation window (ARCHITECTURE §I.3; warnings from Phase 8, DEC-033). Their roxygen moves with them to `R/compat-generics.R`; `R/test.R` and `R/SM_output.R` are deleted and leave the legacy lists.

### Items carried over from Phase 4 (handoff §5)

- **Fixture cases for the RE vector interface (D-11).** Proposed with R-1, the regeneration this phase needs for the method grid (below).
- **The `glm()` independent check of logistic FE (ARCHITECTURE §G.5).** Written in step 4, with the tolerance of DEC-050. Measured: estimates agree to 3.2e-13; variances agree to 2.7e-13 once `glm()`'s covariance is evaluated at its own estimates (facts F13).
- **DEC-044 (peak memory of `logis_fe()` with 50 covariates on 1e6 observations): investigate in Phase 8** (DEC-045). Phase 5 does not touch the logistic FE engine or variance routine; Phase 8 has the dependency reduction and the final benchmark report, where the investigation and any fix can be measured together. The comparisons of this gate will flag it again, as accepted.
- **Benchmarks.** New tasks for every method Phase 5 replaces, measured on the reference with `run_reference.R --only` before the working tree is compared (DEC-051).

### Out of scope

`caterpillar_plot()`, `bar_plot()`, and the styling of the new plots (Phase 6); `data_check()` and `check_data()` with the removal of caret and olsrr (not assigned to Phase 5 by the brief or DEC-040; Phase 8 at the latest); deprecation warnings (Phase 8, DEC-033); any Class B change.

## Steps

Work in this order. Commit small, scoped commits, and add a dated entry to PROJECT_CONTEXT §10 at the end of each step. Pause for a check-in after step 2, which changes the profiling code that logistic FE uses.

### Step 1: Fixture regeneration R-1 (needs approval)

- **Why.** The method fixtures of the families Phase 5 rewrites cover the defaults well but little of the grid of ARCHITECTURE §G.2 (alternative × level × `parm` × null): of 45 RE and CRE method cases, only one interval case is one-sided, none sets `level`, and one sets `parm`; no RE or CRE fit has character IDs. The differential tests compare live on random data, but the frozen fixtures are the authority (brief §3.1). R-1 also adds the RE vector interface cases carried over from Phase 4.
- **Files.** `dev/reference/cases.R`, `dev/reference/datasets.R` (four derived datasets), the regenerated fixtures and manifests, and diff reports `dev/reference/diff-reports/20261004-phase5-grid-core.md` and `-full.md`.
- **Cases (50, all core; logistic RE/CRE fits and their interval cases marked heavy).**
  - D-11, the RE vector interface (7): `linear_re()` with a matrix `Z`, a data-frame `Z`, and character IDs with a data-frame `Z`; `logis_re()` with a matrix `Z` and with character IDs and a data-frame `Z`; and the reference's two failures on a 60-row subset (V15.9), a character `ProvID` with a matrix `Z` and a call that matches no input format. Both failures remain errors in the wrappers (classed), so they pass without per-case expectations (DEC-022 compares the outcome type).
  - RE and CRE methods (20): `confint(option = "SM")` with `alternative = "greater"` and `"less"` for linear RE and CRE, and `"less"` for logistic RE and CRE; `confint()` at `level = 0.9` (`option = "alpha"` for linear and logistic RE, `"SM"` for linear and logistic CRE); `test()` with `parm` and `level = 0.9` on logistic RE, linear CRE, and logistic CRE; `SM_output()` with `parm` on linear and logistic RE; `summary()` with `parm` and `level = 0.9` on all four (selecting the intercept as `"(intercept)"`), and with `parm = "(Intercept)"`, which selects nothing (D-44).
  - Character and integer IDs (7): a `linear_re()` fit with character IDs and its four methods with character `parm`; a `logis_cre()` fit with integer IDs and `test(parm = 1:3)`, which the reference rejects (D-27).
  - Linear FE (16): `null = 0L` in `test()`, `SM_output()`, `confint()`, and `plot()`, which the reference rejects (D-14), with `confint()` and `plot()` at `null = 0` as their expected results (the `test()` and `SM_output()` ones exist); `confint()` at `level = 0.9`; one-sided `confint(option = "SM")` with the full variance (two); `plot()` with `null = "mean"` and on the full-variance fit of the example; a full-variance fit of the D-43 dataset and its `plot()`, where points and flags disagree; `SM_output()` with `parm`; a fit with integer IDs and `test(parm = 1:3)` (D-27).
  - Derived datasets: the linear example with character IDs, the binary example with integer IDs, the 60-row subset of the linear example, and the seeded simulation of `dev/design/phase5-facts/05_linear_funnel_flags.R` (40 providers of 3 to 8 observations with provider-level covariate shifts, D-43).
- **Checks.** Second generation in place identical to the first; every existing core and full case and every existing dataset identical in the diff report; the new cases pass against the current tree, where the reference's method code still runs on the Phase 4 wrappers' objects (the D-14 and D-27 cases are reference errors until the step 3 fixes); the core set stays under 5 MB (now 3.85 MB; the new cases are estimated at under 0.4 MB, because long vectors are stored as signatures).
- If R-1 is not approved, steps 2 to 4 proceed with the existing fixtures, and the grid is covered only by the live comparisons and the differential tests.
- **As built (2026-10-04).** 55 cases rather than 50, and small synthetic datasets rather than copies of the example data, because each copy of the example data costs 0.30 to 0.36 MB of the 5 MB budget: the vector interface runs on `syn_linear_vectors` and `syn_extreme_vectors` (from `syn_linear` and `syn_extreme`), whose failures are fast without a 60-row subset; the character-ID methods run on the existing `linear_re-syn` fit and on a new `logis_re()` fit of `syn_extreme_chr`, whose IDs sort differently in C and English collation (three more cases); the integer-ID cases run on `syn_linear_int` and `syn_extreme_int`, with the results without `parm` as their expected results (one more case); the D-43 data are `syn_linear_funnel`. The 8 new reference errors are the D-11, D-14, and D-27 cases.

### Step 2: Inference and profiling for every family

- **Files.**
  - Profiling: `R/profile-spec.R`, `-tests.R`, `-effects.R`, `-intervals.R`, `-standardize.R`, `-funnel.R`, `-providers.R`.
  - Inference: `R/inference-wald.R` (t or normal tails and critical values), `R/inference-coefficients.R` (the family's covariate Wald rule; one `confint.pprof_model()` for every family, replacing `confint.pprof_logistic_fe()`).
  - Model: `R/model-contract.R` (the generic `predicted_outcome()`), `R/model-linear-fe.R` and `R/model-mixed.R` (`profile_spec()`, `inference_capabilities()`, `predicted_outcome.pprof_mixed()`), `R/model-logistic-fe.R` (its specification states the new fields explicitly, with no change of value).
  - Results: `R/results.R` (settings of the measures and funnel results).
  - Presentation: `R/present-summary.R` and the plot label helpers, only where the new families fail.
  - Tests: `test-profile-families.R` (new), `test-profile-reference.R` (the new families against the method fixtures), `test-inference-coefficients.R`, `test-inference-wald.R`, `test-extension-toy-model.R` (must pass unchanged), `test-architecture.R`.
  - Documents: NAMING §5 (the new fields and settings), ARCHITECTURE §B.4, §E.1, §E.3.
- **Approach: the family differences as data (ARCHITECTURE §B.4, DEC-046).** The profiling layer stays written once; each difference the reference makes between families becomes a field of `profile_spec()`, with a default equal to the Phase 3 behavior so that the toy model and logistic FE need no change:

  | Field | Logistic FE, Firth | Linear FE | Logistic RE, CRE | Linear RE, CRE | Source |
  |---|---|---|---|---|---|
  | `null_default`, `null_options` | `"median"`; median | `"median"`; median, mean | 0; none | 0; none | K-60 |
  | `test_default` (new) | `"exact"` | `"wald"` | `"wald"` | `"wald"` | DEC-047 |
  | `indirect_numerator` | observed Σy | observed Σy | predicted Σ fitted | predicted Σ fitted | K-82, K-84 |
  | `comparison` (new) | ratio | difference | ratio | difference | K-80 to K-84 |
  | `measures` | ratio, rate | difference | ratio, rate | difference | |
  | `mean_function` | plogis | identity | plogis | identity | |
  | `variance_function` | p(1 − p) | none | none | none | K-80 |
  | `direct_expected` | C++ | R sums Σ(γ_i + Zβ) | C++ | R sums Σ(α_i + Xβ) | K-81 to K-84, F5 |
  | `direct_reference` (new) | observed Σy | null-expected Σ(γ0 + Zβ) | observed Σy | observed Σy | K-83, F7 |
  | `direct_limits` (new) | R sums of the mean function | R sums | the direct expectation (C++) | R sums | K-91, K-93, F5 |
  | `one_sided_extremes` (new) | yes | no | no | no | K-91, F10 |
  | `wald` (new): test, interval | normal, normal | simplified: normal, t(n − m − p); full: t(n − m − p), normal | normal, normal | normal, normal | K-67 to K-70, K-92 to K-94, D-32 |
  | `coefficient_wald` (new): p-value, interval | normal 2(1 − Φ(\|z\|)), β ∓ z·se | t(n − p − m) two-sided, β ∓ t·se | 2(1 − Φ(z)) (D-31), lme4's β + se·Φ⁻¹(a) | t(n − p − m + 1) two-sided, with p counting the intercept; lme4's β + se·Φ⁻¹(a) | K-100, K-103 to K-105, F3 |
  | `funnel` | ratio; score; E²/V; z·sqrt(1/w); floor 0; target 1 | difference; Wald; n_i; z·sqrt(1/n_i)·σ; no floor; target 0 | none | none | K-110, K-111, F8 |
  | `wald_caution` | yes | no | no | no | K-67, DEC-037 |

  - The predicted numerator of RE indirect measures comes from the new contract generic `predicted_outcome()`; for `pprof_mixed` it returns lme4's fitted values, stored at fit time, which the reference sums (K-82, K-84). On the example data they equal α̂ + Xβ (or its inverse logit) bitwise (F4), but lme4 does not guarantee it, so the plan reads the stored values. The default method raises `pprof_error_unsupported_inference`.
  - The measures table keeps `observed` and `expected` as the two sums each measure compares, as the reference's `OE` tables do, and records `indirect_numerator` and `direct_reference` among its settings (DEC-048).
  - `test_providers()` and `profile_providers()` take `test = NULL` for the family's default test (DEC-047), as `null = NULL` already does for the null.
  - `funnel_limits()` takes the precision from `funnel$precision(expected, variance, n_obs)`, the point from the family's comparison, and the floor from the specification; the linear half-width closes over the model's σ in the reference's order of operations (`qnorm(1 - alpha / 2) * sqrt(1 / precision) * sigma`).
  - Covariate tests: `test_coefficients(test = "wald")`, `summary()`, `confint()`, and `tidy()` apply `coefficient_wald`. The lme4 Wald intervals are computed from the model's coefficients and covariance with lme4's expression, so no lme4 fit is needed (F3).
  - Capabilities (ARCHITECTURE §E.3): linear FE declares `coef_wald`, `provider_wald`, `interval_wald`, `standardize_indirect`, `standardize_direct`, and `funnel`; the four mixed families the same without `funnel`.
  - The new API reproduces the Class B items awaiting sign-off, as Phase 3 did (D-10, M-15): D-31 in the logistic RE and CRE covariate p-values, D-32 in the linear FE intervals, and M-14's predicted numerator; each is stated in the help with its register entry.
- **Checks.**
  - Logistic FE and Firth unchanged: before the first change, a script saves every profiling and covariate result of the logistic FE and Firth method fixtures and of 12 seeded fits; after each commit of this step they must be identical (`identical()`), and the full reference suite must pass.
  - The new families against the method fixtures: the new API on `fit_linear_fe()`, `fit_linear_re()`, `fit_logistic_re()`, `fit_linear_cre()`, and `fit_logistic_cre()` models of the fixtures' data, matched by provider ID and coefficient name, at the fixtures' tiers. Expected: bitwise for RE and CRE, because the Phase 4 fits reproduce the reference's lme4 fits bitwise; within the closed-form tier for linear FE, whose estimates come from demeaning (DEC-006).
  - Live comparison with the old methods, still in the package, run on the Phase 4 wrappers' objects of the fixture fits and of seeded random datasets, against the new API on the new fits of the same data, over alternatives, levels, nulls, `parm`, and standardization and measure choices: bitwise for every family, because the wrappers' objects hold the new fits' estimates (for linear FE too).
  - Unit tests of every new field and of `predicted_outcome()`; the extension proof and the architecture test pass with no change to the toy model.
- **Check-in** with the project lead after this step.

### Step 3: The wrappers of the old methods, and the switch

- **Files.**
  - New: `R/compat-methods-linear-fe.R` (`test`, `SM_output`, `confint`, `summary` for `linear_fe`), `R/compat-methods-mixed.R` (the same four for `linear_re`, `logis_re`, `linear_cre`, `logis_cre`, from shared helpers parameterized by class), `R/compat-generics.R` (`test()`, `SM_output()`, moved).
  - Changed: `R/compat-convert.R` (models rebuilt from `linear_fe` and from RE and CRE objects; `compat_parm_providers()` for every class), `R/compat-plots.R` (`plot.linear_fe()` and the reference's `ppfunnel_linear()`, unchanged and unlinted, as for `compat_funnel_plot()`).
  - Removed at the switch: `R/test.linear_fe.R`, `R/test.linear_re.R`, `R/test.logis_re.R`, `R/test.linear_cre.R`, `R/test.logis_cre.R`, the five `R/SM_output.*.R`, five `R/confint.*.R`, and five `R/summary.*.R` method files, `R/plot.linear_fe.R`, `R/test.R`, and `R/SM_output.R` (about 2,770 lines); `src/Fixed_effect.cpp`, `src/header.{h,cpp}`, `src/myomp.h`, their objects in `OBJECTS` of both Makevars files, and `tests/testthat/test-cpp-legacy-comparison.R`.
  - Housekeeping: `Rcpp::compileAttributes()`, `devtools::document()`; the removed files leave `.lintr`'s exclusions and the legacy list of `tests/testthat/test-architecture.R` (DEC-031); the two partial-match allowances of DEC-021 leave `tests/testthat/helper-fixtures.R`; `tests/testthat/helper-reference-overrides.R` gains the per-case expectations of the Class A fixes (D-14, D-27; DEC-022).
- **Approach (DEC-032, DEC-049).** Each old method rebuilds a model from the old object, calls the new API, and converts the results to the reference's shapes (BEHAVIOR_SPECS §7 to §11 and §16).
  - The `linear_fe` model is rebuilt like the `logis_fe` one: estimates, variances, σ, and linear predictor from the object, and the data from `data_include`, with `spec$provider_variance` from the `"description"` attribute (D-16).
  - An RE or CRE model is rebuilt from `coefficient$FE` and `$RE`, `variance$FE` and `$alpha`, `sigma`, `fitted`, `linear_pred`, `observation`, the provider order of the `RE` row names, and `attr(, "model")`: the conditional SDs are recomputed from the lme4 fit, as each reference method does (K-70; identical on repeated calls, F6), and the linear RE SDs by K-69 from the object's fields. Nothing is parsed from `data_include`, which is text when IDs are character (D-11). No design matrix is kept, because no RE method needs one.
  - The wrappers reproduce: the factor flags with levels from all providers (D-15), the `"provider size"` attributes, row names, column names, and the `OE` tables with typed sums; the interval attributes, including `"0.95 %"` for RE and CRE and the `"RE logis"` label of the `logis_cre` indirect rate (D-33); the selection of the intercept as `"(intercept)"` in RE and CRE summaries (D-44); D-31 and D-32; the reference's arguments and defaults, including `threads = 2` in `SM_output()` for logistic RE and CRE.
  - Class A fixes: D-08 (full names); D-14 (an integer `null` in every linear FE method); D-21 (the logistic RE and CRE intervals use one thread instead of a hard-coded 4; no number changes, K-85, F5); D-27 (providers stored as integers can be selected with `parm` in the linear FE and logistic CRE methods, F10). Inputs the reference fails on without a message of its own (for example `test.linear_re(null = "median")`) raise classed errors.
  - **Live comparison before the switch.** The wrappers are first written as internal functions beside the registered old methods and compared with them bitwise on every fixture fit (including R-1's) and on seeded random datasets with numeric, character, and integer IDs, over every argument of the grid; then they are registered under the old names, and the old files are deleted in the same commit.
  - The C++ removal follows once no R code calls `computeDirectExp()`: the build lists, the regenerated `RcppExports`, and a build without warnings. `RcppExports.cpp` keeps including `RcppArmadillo.h` while RcppArmadillo is in LinkingTo (F14), so the Makevars settings of DEC-035 stay (DEC-052).
- **Checks.** The reference suite through the wrappers: every method fixture of the five classes, including R-1's, at its tier, and the D-14 and D-27 cases against their per-case expectations; the old object's estimates are used as they are, so the RE and CRE methods are expected to match bitwise, and the linear FE methods within the closed-form tier (their fits come from `fit_linear_fe()`). The legacy tests of pprof 1.0.3 pass against the wrappers. Regression tests for D-08 (strict mode, no allowances left), D-14, D-21, D-27, D-33, and D-44. `lintr` on the new and changed files; `devtools::test()`; `R CMD check` without tests.

### Step 4: Validation, benchmarks, and documents

- **Reference suite.** `validation/run-reference.R`, with the boundary rule's list of providers within tolerance of a flag threshold.
- **Differential tests.** `validation/run-differential.R` extended to: `confint()` (`option = "SM"` and `"alpha"`) and `summary()` for logistic RE and CRE; the three alternatives and `level = 0.9` for every family's intervals and tests; `parm` subsets; character IDs; `null = "mean"` and numbers for linear FE; both provider variances in `test()`, `confint()`, and `plot()`.
- **Independent references.** The `glm()` check of logistic FE in `tests/testthat/test-independent-fits.R` (DEC-050); the measures of each family against direct formulas: K-82 and K-84 from lme4's fitted values, and K-83's identity of both linear FE differences with γ̂ − γ0 up to rounding.
- **Tests and intervals with known truth (ARCHITECTURE §G.5, DEC-053).** `validation/run-simulation.R`: under data simulated without provider effects, and with a few known outliers, the empirical size and power of the provider tests and the coverage of the intervals of every family, with Monte Carlo errors; the report `validation/simulation-report.md` is informational, and any departure from nominal goes to the methodology owners, not into the code.
- **Metamorphic tests.** Relabeling providers in an order-preserving way, with numeric, character, and factor IDs, leaves every profiling result of every family identical, keyed by ID; for linear FE also a row shuffle, within the closed-form tier; for the lme4 fits only the exact relations, as in DEC-043.
- **Benchmarks (DEC-051).** Add the new tasks to `dev/bench/scenarios.R`, measure them on the reference (`run_reference.R --only`) into a supplementary baseline, then run the working tree, the comparison, and the paired re-measurement of flagged tasks (DEC-038). Report: `dev/bench/results/phase5-gate-<date>.md`.
- **Documents.** ARCHITECTURE §B.2, §B.3 (no reference C++ left), §B.4, §D.3, §E.1, §E.3, §G.5, and §I as built; NAMING §5; NEWS; DECISIONS; DISCREPANCIES (D-08, D-14, D-15, D-21, D-27, D-31, D-32, D-33, D-34, D-43, D-44); PROJECT_CONTEXT §7, §9, §10, and the status line.

### Step 5: Gate

`/phase-gate`, then stop for approval.

## Equivalence and tolerances

- **Fixtures in scope (F2).** Core set: 29 methods on linear FE fits (27 closed-form, 2 reference errors: `test-linear-bad-null`, `confint-linear-gamma-greater`) and 45 on RE and CRE fits (lme4 tier: linear RE 8, logistic RE 15, linear CRE 8, logistic CRE 14); the full set has none. `caterpillar-linear`, `caterpillar-logis-re-extreme`, and `bar_plot-linear` run the reference's plot code on the wrappers' outputs (DEC-034). R-1 adds 50.
- **Tiers.** Unchanged: closed-form for linear FE, lme4 for RE and CRE (run only under the manifest's lme4 2.0-6 and Matrix 1.7-6, DEC-020, which this machine has, F1). No root-finding is involved: the new families have Wald intervals only. Flags exactly, except for providers within tolerance of a threshold, which the equivalence report lists.
- **What is expected to match bitwise.** RE and CRE results everywhere (same lme4 fits, same expressions, the C++ direct expectations, lme4's interval expression); linear FE methods on the wrappers' objects against the old method code (the same estimates); logistic FE and Firth results before and after step 2.
- **Live comparisons are checks, not the authority.** Fixtures remain the authority (brief §3.1).
- **No tolerance changes.** The one new tolerance is that of the `glm()` comparison, which lives with its justification in the test file, as DEC-043's do (DEC-050).
- **Fixture regeneration** only as R-1, with approval and a diff report.

## Facts gathered (2026-10-04, at `71e0c73`)

The scripts and their outputs are in `dev/design/phase5-facts/` (run from the repository root, `Rscript <script> <output>`); F15 is a plain `devtools::test()` run.

- **F1. Environment.** The reference library has pprof 1.0.3, lme4 2.0-6, and Matrix 1.7-6, the versions of the user library, so the lme4-tier tests run here. R 4.4.0 (ucrt).
- **F2. Fixture counts.** From the manifests: core 248 cases, full 32; method cases by parent fit as listed under "Equivalence". The two linear FE error cases are reference errors that the wrappers keep as errors.
- **F3. lme4's Wald intervals.** In the reference, `confint(model, parm = "beta_", method = "Wald", level)` in the RE and CRE summaries equals `fixef + sqrt(diag(variance$FE)) %o% qnorm(a)` with `a = c((1 - level) / 2, 1 - (1 - level) / 2)` bitwise for all four families at levels 0.95 and 0.9, while β ∓ qnorm(1 − α/2)·se differs by up to 4.4e-16 at 0.9. So the covariate intervals reproduce lme4's expression from the stored coefficients and covariance.
- **F4. lme4's fitted values** equal α̂ + Xβ (linear) and plogis(α̂ + Xβ) (logistic) bitwise on the example data, in the reference's objects and in the Phase 4 models, for all four families.
- **F5. Direct expectations.** The reference's `computeDirectExp()` and R's `sum(plogis(α + Xβ))` differ for 98 of 100 providers (logistic RE) and 97 of 100 (logistic CRE), by up to 5.6e-15 relative; so the logistic RE and CRE direct limits must use the C++ routine, as the reference does, while logistic FE's use R sums (K-91). `cpp_logistic_direct_expected()` equals `computeDirectExp()` bitwise on RE and CRE inputs (α, and Xβ with the intercept), with 1 and 2 threads.
- **F6. Conditional SDs.** `ranef(condVar = TRUE)` on the stored lme4 fit is identical on repeated calls, and its square root equals `test()`'s `Std.Error` for logistic RE, linear CRE, and logistic CRE.
- **F7. Linear FE.** `test()`, `SM_output()`, `confint()`, and `plot()` all reject `null = 0L` ("Argument 'null' NOT as required!"), so D-14 extends to every linear FE method; `null = c(0, 1)` uses the first element. D-32 confirmed: the interval multiplier is qt(0.975, 7796) = 1.9602683 with the simplified variance and qnorm(0.975) = 1.9599640 with the full one, while the tests use pnorm and pt(7796) respectively. The direct standardization's reference total is Σ(γ0 + Zβ), so it changes with `null` (−7348.64 at the median, −7376.69 = Σy at the mean). `qt()` and `pt()` with `df = Inf` equal `qnorm()` and `pnorm()` bitwise.
- **F8. `plot.linear_fe()`.** Four layers: the points (one per provider), two lines with one row per provider and level (limits at each provider's size, not at distinct precisions), and the target; the lower limit has no floor and goes below 0.
- **F9. The linear funnel and its flags (new, D-43).** With `option.gamma.var = "full"`, the limits still use σ/sqrt(n_i) and normal quantiles while the flags come from the test with the full variance and t: on 40 simulated providers of 3 to 8 observations with provider-level covariate shifts, 21 lie outside the 95% limits but 13 are flagged (8 disagree). With the simplified variance, and on the example data with either, points and flags agree.
- **F10. RE and CRE methods.** `summary.logis_re()` reports p-value 2 for the intercept (D-31). `summary.linear_re(parm = "(Intercept)")` returns no rows and `parm = "(intercept)"` the intercept (D-44). `test.linear_re(null = "median")` fails with "non-numeric argument to binary operator". The partial matches `data_includ` and `obs` are confirmed (D-08). With character IDs every column of `data_include` is character, character `parm` works in every method, and numeric `parm` fails the class check. With integer IDs, `parm` fails in the linear FE and logistic CRE methods (their `data_include` keeps integer IDs) and works for linear RE and CRE (`cbind()` makes them double) (D-27). The logistic RE intervals of provider 40, which has no events, are two-sided and positive (indirect ratio lower limit 0.484), so the RE families have no one-sided treatment of extreme providers. `confint.logis_cre()` labels its indirect rate `"RE logis"` with level `"0.95 %"` (D-33).
- **F11. Reference run times** on the example data: at most 0.13 s per method call.
- **F12. Current code.** The Phase 4 models declare no capabilities, and `test_providers()`, `standardize_providers()`, `provider_effects()`, `funnel_limits()`, `summary()`, `confint()`, and `test_coefficients()` raise `pprof_error_unsupported_inference` for all five. Their provider tables have no event columns (`provider_id`, `provider_value`, `n_obs`, `included`).
- **F13. `glm()` against `fit_logistic_fe()`** (`tol = 1e-12`, `stop_rule = "all"`) with provider indicators: on the example without its three no-event providers (97 providers, 7,698 observations) estimates agree to 3.2e-13 absolute (1.3e-13 relative), and to 9.1e-15 on a seeded simulation (60 providers); log-likelihoods are identical. `glm()`'s covariance is that of its last iteration's starting point and differs by up to 9.3e-8 relative; one more `glm()` iteration started at its estimates gives agreement to 8e-15 (Var β) and 2.7e-13 (Var γ).
- **F14. `RcppExports.cpp` without the old C++.** `Rcpp::compileAttributes()` on a copy of the package without `Fixed_effect.cpp`, `header.{h,cpp}`, and `myomp.h` still writes `#include <RcppArmadillo.h>`, because RcppArmadillo is in LinkingTo; it exports the seven `cpp_logistic_*` adapters. The handoff (§3) expected the include to go.
- **F15. Baseline.** `devtools::test()`: 57 files, 813 tests, 5,469 expectations, 0 failed, 0 skipped, 0 warnings (250 s), as at the Phase 4 gate.
- **F16. Code to replace.** The 20 method files, `plot.linear_fe.R`, and the two generics hold about 2,770 lines; `R/compat-methods.R` has 501.
- **F17. Coverage today.** `validation/run-differential.R` runs `test()`, `SM_output()`, `confint()`, and `summary()` on linear FE, RE, and CRE fits, but only `test()` and `SM_output()` on logistic RE and CRE fits. The benchmark tasks include linear FE methods only on `lin-1e5-m1000-p5` and no RE or CRE method.

## Decisions proposed

Recorded in `dev/DECISIONS.md` with status "proposed":

| ID | Decision |
|---|---|
| DEC-045 | Phase 5 scope: `plot.linear_fe()` and the linear funnel in Phase 5; the generics `test()` and `SM_output()` to the compatibility layer; DEC-044's investigation in Phase 8 |
| DEC-046 | The family specification carries the remaining family differences (the table in step 2), with defaults equal to the Phase 3 behavior; one new contract generic, `predicted_outcome()` |
| DEC-047 | `test = NULL` in `test_providers()` and `profile_providers()` means the family's default test |
| DEC-048 | Measures tables keep `observed` and `expected` as the two sums each measure compares, and record `indirect_numerator` and `direct_reference` |
| DEC-049 | The old methods of `linear_fe`, RE, and CRE objects rebuild the model from the old object (extends DEC-032); the compatibility files are split by family |
| DEC-050 | The `glm()` independent check: estimates within atol and rtol 1e-10, variances (at `glm()`'s own estimates) and log-likelihood within the closed-form tier |
| DEC-051 | Benchmark tasks for every replaced method, measured on the reference into a supplementary baseline |
| DEC-052 | `RcppExports.cpp` keeps including `RcppArmadillo.h`; DEC-035's Makevars settings stay |
| DEC-053 | A simulation study of size, power, and coverage in `validation/`, informational |

## Questions for the project lead

1. Approve R-1 (step 1) with its case list, or trim it.
2. Approve DEC-045 to DEC-053.
3. RE and CRE indirect standardization with a `null` other than 0: the reference offers no `null` in RE `SM_output()`, but its test takes one. Proposed: accept a number, which gives the same expected-count formula as a numeric `null` for fixed effects (Σ plogis(null + Xβ)); the default 0 reproduces the reference, and the wrappers never pass another. The alternative is to reject it with `pprof_error_unsupported_inference`, which then also breaks `profile_providers(null = )` for these families.
4. DEC-048: the recommended table semantics, or the alternative (a `predicted` column for RE indirect rows, with `observed` always Σy).
5. Register: D-43 (Class B, awaiting sign-off) and D-44 (Class C), recorded during planning, and the D-14 and D-27 extensions to the linear FE and logistic CRE methods.

## Questions for the methodology owners (defaults reproduce the reference)

- M-8 (D-32): now also the linear FE intervals of `provider_effects()` and `standardize_providers()`.
- M-10 (D-31): now also `test_coefficients()`, `summary()`, and `tidy()` of logistic RE and CRE models.
- M-14 (K-82, K-84): the predicted numerator, now in `standardize_providers()` for RE and CRE models.
- M-11 (D-34): unchanged.
- M-18 (new, D-43): in the linear FE funnel plot with the full provider variance, the control limits use σ/sqrt(n_i) and normal quantiles while the flags use the full variance and t(n − m − p), so points outside the limits can be unflagged. Intended? Proposed default: preserve.
- M-16 (who signs off) remains open.

## Risks

- **Changing Phase 3 code.** Step 2 generalizes the profiling functions that logistic FE uses. Mitigation: the saved-results check after every commit of step 2, the full reference suite, and separate commits for the generalization and for each family.
- **RE objects with character IDs.** Their `data_include` is text (D-11); the rebuild reads numbers only from numeric fields and the lme4 fit.
- **lme4 versions.** The lme4-tier tests skip under other versions (DEC-020), and the CI job that pins them has not run: GitHub Actions is still not enabled on the fork.
- **Plot layer data.** The linear funnel is compared by layer position and row; its rows are per provider and level (F8), unlike the distinct precisions of `funnel_limits()`.
- **Rebuild cost.** The RE methods rebuild the model and recompute the conditional SDs on every call, as the reference recomputes them; DEC-039's exception covers the rebuild, and the benchmarks will show whether anything beyond it is slower.
- **The extension proof.** New specification fields could break the toy model; their defaults keep the Phase 3 behavior, and the proof must pass unchanged.
- **Size of the phase.** About 2,770 lines of reference code and 74 method fixtures (124 with R-1); the check-in after step 2 and the live comparison before the switch limit the risk of a late surprise.
- **Slow examples.** The help pages of the RE and CRE methods keep the reference's examples, which fit lme4 models; R CMD check's slow-examples note may list more of them. No example may use more than 2 threads.

## Register items in scope

- Fix (Class A or C): D-08 (old methods), D-14 (linear FE methods), D-21 (logistic RE and CRE intervals), D-27 (linear FE and logistic CRE methods), D-33 (new results carry the level as a number; the wrappers keep the attributes), D-44 (the help says how to select the intercept).
- Reproduce, awaiting sign-off (Class B): D-31, D-32, D-34, D-43, and M-14's numerator.
- Presentation: D-15 (integer flags in new results, factors in the wrappers).
- Made explicit in Phase 4 and used here: D-16 (`spec$provider_variance` selects the Wald distributions).
