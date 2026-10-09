# CoxPH Phase C3 plan: provider profiling for the stratified Cox model

> **Status: proposed on 2026-10-09, for the project lead's approval with the seven decisions of §6.** It implements the brief's §4 row C3 (`dev/coxph_brief.md`; also §3.2, §3.5, §3.7, §5.3, §5.6, §6) and COXPH_DESIGN §A.3, §A.4, §B.3, §D, §F.1 to §F.4, §G, and §I, under DEC-086 to DEC-106.

C3 gives `fit_cox_stratified()` fits pprof_py's provider profiling: expected counts at the national Breslow baseline, indirectly and directly standardized ratios, the mid-p and exact Poisson tests with their limits and flags, funnel limits, the plots, and `profile_providers()`, through the profiling layer that every family shares. The existing families stay bitwise identical.

Two findings of the planning change the C0 design and need decisions (§6): pprof_py v0.7.0 has funnel limits for Cox models, which M-39 was decided without (§2.5); and the family specification cannot carry the Poisson limits as a function without breaking the layer rules (§2.8). The evidence is in §2; its scripts are `dev/design/coxph-facts/22` and `23`.

## 1. Deliverables

| # | Deliverable | Where |
|---|---|---|
| 1 | The Poisson tests and their limits: mid-p and exact statistics, p-values, flags, Garwood and Byar limits, mid-p limits (K-140 to K-142, K-147) | `R/inference-poisson.R` (new); its constants in `R/constants.R` |
| 2 | Each observation's expected events at the national baseline, kept by the fit as `expected_events`, and the direct expected counts (K-136 to K-139) | `R/model-cox-measures.R` (new), `R/model-cox-stratified.R` |
| 3 | The family's contract: capabilities, the full family specification, `expected_outcome()`, `null_effect()` (COXPH_DESIGN §D.1, §D.2) | `R/model-cox-stratified.R` |
| 4 | The shared hooks, COXPH_DESIGN §D.3 items 3 to 6 as amended in §3.6: Poisson counts, provider-level direct expectations, `"midp"`, two capabilities, and the warning for providers without expected events (D-70) | `R/profile-spec.R`, `R/profile-tests.R`, `R/profile-standardize.R`, `R/profile-funnel.R`, `R/profile-providers.R`, `R/model-capabilities.R`, `R/results.R`, `R/conditions.R` |
| 5 | Funnel limits of Cox models (decision 1) | `R/inference-poisson.R`, `R/profile-funnel.R` |
| 6 | The four plots on Cox results | `R/plot-blocks.R` and the plot files |
| 7 | Tests (§4) | `tests/testthat/`: `test-inference-poisson.R`, `test-model-cox-measures.R`, `test-profile-cox.R` (new); `test-cox-reference.R`, `helper-cox-fixtures.R`, `helper-tolerances.R` (extended); the Cox capability test of `test-model-cox-stratified.R` and two capability expectations of the logistic tests (§4.1) |
| 8 | The calibration of `cox_statistic` and of a tier for the mid-p limits (DEC-097) | `dev/reference/cox/calibrate.R`, `validation/cox-calibration-report.md`, `tests/testthat/helper-tolerances.R` |
| 9 | pprof_py's funnel limits in the Cox fixtures (decision 2) | `dev/reference/cox/generate.py`; both fixture sets and their manifests; `dev/reference/diff-reports/` |
| 10 | Benchmarks: each fit with its measures against its engine call, the preparation of the engine's inputs, and the measures (DEC-105); the measures and tests against pprof_py; the corner scenario at the gate | `dev/bench/cox/run_paired.R`, `summarize_paired.R`, `dev/bench/results/` |
| 11 | Registers, help pages, `NEWS.md`, the vignette's tables, ARCHITECTURE §E.3 and §E.6 and COXPH_DESIGN as built, NAMING §10, the status document | `dev/`, `man/` (generated), `vignettes/adding-a-model.Rmd`, `NEWS.md` |

**Not in C3** (brief §4): penalized models (C4); Fine–Gray, and the documentation and interface of competing-risk profiling (C5), although C3's tests compare the cause-specific records of the competing fixtures, which are `fit_cox_stratified()` fits (M-35); the simulation study and the vignette (C6); empirical nulls (a later brief).

## 2. Evidence gathered for this plan

With R 4.4.0 and survival 3.8-12, and the fixture generator's Python environment with pprof_py at `9320766`, on the C1 machine; the outputs are beside the scripts. Script 22 writes pprof_py's formulas in plain R (base and stats only, no package code) and compares them with the fixtures, which hold pprof_py's measures and tests at its tight β̂ for every Cox case and every cause-specific record of the competing cases, with both tie methods: 32 records.

1. **The closed forms reproduce pprof_py's measures** (22, part A). At pprof_py's β̂ and with its grouping of providers (the stratum, or id mod 10 in the two unstratified cases), the observed counts are equal, person-time is equal bit for bit (summed in row order), the expected counts are within 2.5e-4 of the `closed_form` allowance (1e-12 + 1e-10·|b|), Σ_j E_j is within 2.2e-16 of O, and the direct expected counts are within 0.039 of the allowance when computed as pprof_py computes them (suffix sums over composite provider-time keys) and within 0.024 when the suffix sums run within each provider's rows. `empty-providers` has a provider with E_j = 0.
2. **The closed forms reproduce pprof_py's tests** (22, part B). Given pprof_py's O_j and E_j: the mid-p statistics are within 1.2e-3 of `cox_statistic` (rtol 1e-8) and the exact ones within 6e-5; the p-values within 2.9e-4 of `probability`; the flags of both tests are identical in all 32 records; the exact limits are within 1e-5 of `closed_form`; and the mid-p limits within 0.0063 of a candidate tier of atol 1e-10 and rtol 1e-8 on the ratio scale.
3. **Negative controls** (22, part C). The brief's three (§3.5), each acting through the expected counts: the other tie method (pprof_py's own tests), one tied event moved by a day, and one weight dropped (the generator's control fits, with their expected counts by the closed form). The weakest, in units of each tier: statistics 4.49e4, p-values 4.12e6, mid-p limits 4.13e3, exact limits 4.13e5.
4. **The mid-p limits depend on O_j alone** on the Poisson-mean scale (22, parts B and D). They are the roots in t of 2Φ̄(|z(O, t)|) = α; pprof_py's bracket, split point, and Brent tolerance (xtol 1e-10·max(E, 1)) only set how precisely it finds them. Computed once per distinct O to rounding with `uniroot()`, keeping pprof_py's decisions of 0 and ∞ at its own bracket ends, then divided by E_j, they are within 0.25 xtol of pprof_py's; pprof_py's algorithm run per provider with `uniroot()` for `brentq` is within 0.47 xtol. On the same synthetic data of 1,000, 3,000, and 7,500 providers (141 to 273 distinct counts) they took 0.22, 0.43, and 0.42 s, and pprof_py's 21.6, 62.6, and 184.6 s (its algorithm in R: 1.6, 5.0, and 13.3 s).
5. **pprof_py has funnel limits for Cox models** (23). `CoxPH.funnel_limits()` (`inference/survival/provider_tests.py:142-172`, `inference/funnel.py:poisson_funnel_limits`) is in v0.7.0 but not in the brief's §2.4 or COXPH_DESIGN §A, so M-39 was decided for "Cox models, which pprof_py lacks". For each expected count E it finds the largest count its test flags low and the smallest it flags high, under the test's own Poisson null, and sets the limits half-way between counts on the O/E scale, (o_lo + ½)/E and (o_hi − ½)/E, or −∞ and ∞ where there is no such count; its curves use a 200-point geometric grid of E for each level; and it checks that a provider lies outside its limits exactly when it is flagged. M-39's limits, 1 ∓ Φ⁻¹(1 − α/2)/√E with a floor of 0, disagree with the flags: on `provider-scale` 11 to 13 of 1,000 providers lie outside them unflagged and 2 flagged ones inside them (mid-p test), and 21 to 22 outside unflagged (exact test); on `rc-stratified` 1 of 25. A plain-R construction gives pprof_py's limits and curves exactly: equal on every provider and curve point of both cases, both tie methods, and both tests.
6. **Cost at 1,000,000 rows and 7,500 providers** (22, part E: 5 covariates, the machine paging, so indicative): the national expected counts of every row took 0.46 s, and their sums by provider 0.05 s; the direct counts 2.3 to 2.5 s with the prototypes, which loop over providers in R or sort the rows twice. pprof_py's measures took 1.4 s for both at the corner (C1 baseline).
7. **Precision of the direct counts.** pprof_py's provider risk-set sums are differences of suffix sums over all later providers' rows; at 1,000,000 rows the two prototypes differ by 7.9e-11 relative, inside `closed_form`'s 1e-10 but near it. The within-provider sums are the accurate form.
8. **The layer rules.** A model file is layer 2 and the inference layer 3 (ARCHITECTURE §B.1), and `test-architecture.R` checks every call in a file, closures included. A `measure_limits` function in the Cox model's specification (COXPH_DESIGN §D.2) could therefore not call the Poisson limits, which invert the tests that §D.3 item 4 places in `R/inference-poisson.R`.
9. **Tests that enumerate capabilities.** `test-model-logistic-fe.R:218` and `test-model-logistic-firth.R:139` expect logistic fixed-effect models to declare every name in `capability_names`; with `provider_midp` and `interval_midp` added they must name the logistic set without those two. No result changes. C2's own test that the Cox model declares only `coef_wald` (`test-model-cox-stratified.R`, DEC-102) is superseded by C3's capabilities.

## 3. Approach

### 3.1 Expected counts at the national baseline (K-136, K-137; COXPH_DESIGN §F.1)

- `fit_cox_stratified()` computes each observation's expected events once and keeps them as `expected_events` (COXPH_DESIGN §B.2, NAMING §10), from `cox_expected_events(eta, start, stop, event)` in `R/model-cox-measures.R`:
  - η = x'β̂ + offset on every row, rows with weight 0 included and rows unweighted (M-25, M-29), whatever ties fitted β̂;
  - r = exp(η − max η); the distinct event times by exact equality;
  - RS(t) as the difference of the suffix sums of r by exit and by entry, the rows sorted stably, as pprof_py computes it (K-136);
  - Λ0 the cumulative sum of d(t)/RS(t), right-continuous; E_i = r_i[Λ0(stop_i) − Λ0(start_i)].
- The sums are the package's own, as the brief's §1 assigns them; they sit in the model layer because the fit computes them, and the profiling layer reads them through `expected_outcome()`.
- The validator checks one finite, non-negative value per observation. Cost: about 0.5 s at 1,000,000 rows (§2.6), and one double per row.

### 3.2 Direct standardization (K-138; COXPH_DESIGN §F.2)

- `cox_direct_expected(model, rows)`, in the same file, is the specification's `direct_by_provider`: for the providers in `rows`, E^(j) = Σ over provider j's event rows of RS(t)/RS_j(t), with RS(t) the national sums at the distinct event times and RS_j(t) from suffix sums within provider j's own rows, which the data layer keeps together. All providers at once, by ordering the rows on provider and time; 0 for a provider without events.
- The within-provider sums are the accurate form (§2.7); on the fixtures pprof_py agrees with them within `closed_form`. Target: no slower than pprof_py's measures, about 1 s at 1,000,000 rows (DEC-098 reads the brief's SHOULD as applying to the measures).
- The reference total is O, the events of every row (`direct_reference = "observed"`), and the ratio E^(j)/O. pprof_py has no direct limits, so direct standardization with an interval raises `pprof_error_unsupported_inference` (COXPH_DESIGN §B.3).

### 3.3 The Poisson tests and their limits (`R/inference-poisson.R`; K-140 to K-142, K-147)

Functions of O_j and E_j, vectorized over providers, under the theoretical null:

- **Mid-p** (K-141): p_min = 2F(O; E) − f(O; E) and p_max = 2(1 − F(O − 1; E)) − f(O; E), with `1 - ppois()` as written; p* = max(1e-6, min(p_min, p_max)/2); z = Φ⁻¹(p*), negated when p_min > p_max.
- **Exact** (K-140): p_ex = min(0.999, 2P(X ≥ O)) when O/E > 1, otherwise min(0.999, 2P(X ≤ O)), each tail from `ppois()` with its `lower.tail`; z = sign(O − E)·Φ̄⁻¹(p_ex/2), infinite when p_ex underflows (D-71).
- **Both**: p = 2Φ̄(|z|), computed as an upper tail; the flag is +1 when p < α and z > 0, −1 when p < α and z < 0, and 0 otherwise (K-142), so a provider whose p_ex underflows gets p = 0 and is flagged (D-71); α = 1 − level (K-61).
- **Exact limits** (K-140): Garwood's when E < 100, `qchisq(α/2, 2O) / 2 / E` (0 when O = 0) and `qchisq(1 − α/2, 2(O + 1)) / 2 / E`, in pprof_py's order of operations; Byar's when E ≥ 100.
- **Mid-p limits** (K-141; decision 5): for each distinct O, the roots of 2Φ̄(|z(O, t)|) = α on either side of the root of z(O, t), found with `uniroot()` to rounding; the lower limit is 0 and the upper ∞ where pprof_py's equation is non-negative at its bracket ends for that provider (1e-10·max(E, 1); 10(O + E + 10), multiplied by 10 while z > −4.75 and below 1e12); then L/E_j and U/E_j, which are NaN and ∞ when E_j = 0 (K-147).
- The constants (1e-6, 0.999, 100, and the bracket's 1e-10, 10, 1e12, and −4.75) are named in `R/constants.R` with their K numbers and pprof_py's locations.
- One-sided alternatives raise `pprof_error_unsupported_inference`: pprof_py's tests and limits are two-sided (COXPH_DESIGN §B.3).

### 3.4 The funnel (decision 1)

- **Recommended: pprof_py's construction** (§2.5; new K-149). The points are the indirect ratios O_j/E_j with precision E_j. At each distinct E > 0 and each level, the funnel's test (mid-p, M-39) gives the largest count it flags low and the smallest it flags high among 0, …, ⌈E + 40√E + 50⌉, and the limits are (o_lo + ½)/E and (o_hi − ½)/E, or −∞ and ∞ where there is no such count. The flags come from the test at the first level, so a provider lies outside its limits exactly when it is flagged. Providers with E_j = 0 have no limits, as in pprof_py's curves.
  - The table keeps the package's shape, one row per level and distinct provider precision, where pprof_py's curves use a grid (a presentation difference); at each provider's E they equal pprof_py's limits for that provider, whose search range also covers O_j, which matters only where no count in range is flagged (a level of 0.999998 or more for the mid-p test).
  - `target` other than 1 is rejected for these limits, which are tied to the test.
- **The alternative: M-39 as decided.** 1 ∓ Φ⁻¹(1 − α/2)/√E_j with a floor of 0, and flags from the mid-p test. This is a Class B difference from pprof_py's `funnel_limits()` (to be registered as D-76 for sign-off), with the disagreement between points and flags of §2.5, as D-43 has for linear fixed effects.

### 3.5 The family's contract (COXPH_DESIGN §D.1, §D.2)

- `inference_capabilities()`: `coef_wald`, `provider_exact`, `provider_midp`, `interval_exact`, `interval_midp`, `standardize_indirect`, `standardize_direct`, `funnel`.
- `profile_spec()`: C2's fields and covariate rule (DEC-101), and `test_default = "midp"`, `comparison = "ratio"`, `direct_reference = "observed"`, `one_sided_extremes = FALSE`, `count_distribution = "poisson"`, `variance_function = function(expected) expected` (the Poisson null variance, the measures' `variance` column), `direct_by_provider = cox_direct_expected`, and `funnel = list(measure = "ratio", target = 1, test = "midp", precision = function(expected, variance) expected)`, with `floor = 0` and `half_width` under decision 1's alternative.
- `expected_outcome(model, effect)`: exp(effect) times `expected_events`, with one effect or one per included provider. `null_effect(model, null = 0)`: a single finite number, which scales every E_j by exp(null) (M-40); the default 0 gives pprof_py's tests.
- `provider_estimate_se()`, `provider_test()`, `refit_without()`, and `predicted_outcome()` stay unimplemented and raise `pprof_error_unsupported_inference`, as `provider_effects()` does (DEC-102). No provider is screened out (M-32).

### 3.6 The shared hooks (COXPH_DESIGN §D.3 items 3 to 6, amended by decision 3)

Each default is today's behavior (DEC-092), and no existing family sets the new fields.

- **Item 3**, `R/profile-spec.R`: the defaults gain `count_distribution = "poisson_binomial"` and `direct_by_provider = NULL`. There is no `measure_limits` field: with `count_distribution = "poisson"`, the profiling layer takes the limits of the measures, and of the funnel, from `R/inference-poisson.R`, as it takes the tests (§2.8).
- **Item 4**, `R/profile-tests.R`: the test choices gain `"midp"`. With `"poisson"`, `profile_test_table()` sums each reported provider's O_j and E_j, as `profile_indirect()` does, and calls the Poisson tests, whose p-values and flags follow K-142 rather than `infer_decide()`. With `"poisson_binomial"` nothing changes: no such family declares `provider_midp`, so `require_capability()` raises for it.
- **Item 5**, `R/profile-standardize.R`: the interval choices gain `"midp"` (in `new_pprof_measures()` and `profile_providers()` too). With `"poisson"`, the limits of the indirect ratios are the Poisson limits of O_j and E_j, with E_j scaled by the null, and `profile_effect_limits()` is not called; direct standardization with an interval and one-sided intervals raise `pprof_error_unsupported_inference`. With `direct_by_provider` set, `profile_direct()` takes E^(j) from it.
- **Item 6**, `R/model-capabilities.R`: `provider_midp` and `interval_midp`.
- **Also**: `R/profile-funnel.R` takes the Poisson limits of §3.4 with `"poisson"`; `R/conditions.R` adds `warn_zero_expected()`. `test_providers()`, `standardize_providers()`, and `funnel_limits()` each warn once per call with `pprof_warning_zero_expected` when reported providers have E_j = 0, counting them, and `profile_providers()` warns once in all (D-70, K-147).

### 3.7 Plots and presentation

- `plot_funnel()`, `plot_caterpillar()`, `plot_flags()`, and `plot_volume()` read the results as for the other families (COXPH_DESIGN §B.3); a Cox provider's volume stays its number of rows.
- Decision 7: the subtitles name the mid-p test and intervals ("mid-p test", not "midp test"), and points whose estimate is not finite (providers with E_j = 0, whose ratio is NaN) are left out with a caption that counts them, instead of ggplot2's warning about removed rows. No plot of the existing families changes: their estimates are finite.
- The help of `test_providers()`, `standardize_providers()`, `funnel_limits()`, and `profile_providers()` describes the Cox measures, tests, limits, and funnel, and that of `fit_cox_stratified()` its `expected_events` and its profiling.

## 4. How equivalence is checked

### 4.1 The existing families stay bitwise identical (COXPH_DESIGN §C.2)

1. `devtools::test()` and `validation/run-reference.R` at `main` (`eedc5a1`) before any change, and again after each commit marked (S) in §5: no failure, the previous run's counts of tests and expectations plus the new ones, and an equivalence report equal to the committed one but for its date and commit (368 of 368 cases).
2. The `data_prepare()` snapshot test (C2) runs unchanged: C3 does not touch the data layer.
3. The toy-model extension test runs unchanged.
4. The only edits to existing tests are the two capability expectations of §2.9, which will name the logistic fixed-effect set explicitly, and C2's Cox capability test, which becomes a test of C3's capabilities. No other existing expectation changes.

### 4.2 Against pprof_py: the Cox fixtures (`test-cox-reference.R`)

The core set always, the full set when present (`skip_on_cran()`), every Cox case and cause-specific record (M-35), both tie methods, in two layers.

**Given pprof_py's inputs**, through the package's internal functions, which isolates the closed forms from the fit:

| Quantity | Given pprof_py's | Tier |
|---|---|---|
| O_j | grouping of providers | `exact` |
| E_j, Σ_j E_j = O, person-time, E^(j) | β̂ and grouping (id mod 10 for the unstratified cases) | `closed_form` |
| mid-p and exact statistics | O_j and E_j | `cox_statistic` |
| p-values | O_j and E_j | `probability` |
| flags | O_j and E_j | `exact` |
| exact limits | O_j and E_j | `closed_form` |
| mid-p limits | O_j and E_j | `cox_root` (decision 4) |
| funnel limits, per provider and on the curves (decisions 1 and 2) | E_j, and the curves' grid | `exact`: counts ± ½ over the same E |

**From the package's own tight fit** (`tol = 1e-11`, `max_iter = 100`, the generator's control), for the stratified cases and the cause-specific records (in the unstratified cases pprof_py's providers are not the fit's strata):

- `standardize_providers(standardization = c("indirect", "direct"))`: O_j exactly; E_j, the indirect ratios, E^(j), and the direct ratios under `cox_baseline` (each side's β̂, as C1 calibrated it); person-time under `closed_form`.
- `test_providers()` with each test: flags exactly, except for a provider within tolerance of a threshold, one whose flag changes when its E_j moves within `cox_baseline`'s allowance; the calibration report lists such providers (fact 22 found no flag difference given the same counts). The statistics, p-values, and limits of the package's fit are the closed forms above at its own counts.
- `zero-weights` with Efron ties: E_j and the ratios differ beyond `cox_baseline`, as the fits do (D-58); with Breslow ties they agree.

### 4.3 Calibration of the C3 tiers (DEC-097)

`calibrate.R` gains rows for every Cox case and cause-specific record and both tie methods: pprof_py against R's own functions given pprof_py's inputs, a transcription of K-138 and K-140 to K-142 with `ppois()`, `qchisq()`, `qnorm()`, and `uniroot()`, independent of the package's code, as fact 22's. The rows: direct counts (`closed_form`), statistics (`cox_statistic`), p-values (`probability`), flags (`exact`), exact limits (`closed_form`), and mid-p limits (`cox_root`), each with the three negative controls of §2.3. A new section lists the providers near a flag threshold at each side's β̂ (R's: survival's tight fit, which the fixtures hold, through the transcription). C1's rows are unchanged. Fact 22 predicts agreement within 0.0012, 2.9e-4, 1e-5, and 0.0063 units, and weakest controls of 4.49e4, 4.12e6, 4.13e5, and 4.13e3.

### 4.4 Unit, metamorphic, and edge-case tests (brief §6 C, E, F)

- `test-inference-poisson.R`: the statistics against `ppois()`; the exact p-values against `poisson.test()`'s one-sided tails doubled, and the Garwood limits against its interval divided by E, where the two coincide; the mid-p limits against their defining equation; the floor (|z| = 4.7534, p = 2e-6), the cap (O = E gives p = 1), the switch from Garwood to Byar at E = 100, O = 0, E = 0 (K-147), and D-71 (O = 1000 against E = 10: z = ∞, p = 0, flag +1).
- `test-model-cox-measures.R`:
  - expected counts by hand on six rows with tied events and an entry at an event time (K-131's risk set); Σ_j E_j = O;
  - the national baseline and the counts per row against survival's own for `coxph(Surv(...) ~ offset(η), ties = "breslow", timefix = FALSE)`: its baseline allowing for the offset factor (D-60, D-75), and its `predict(type = "expected")`, as C1's R side, under `closed_form`;
  - the direct counts against their second form, Σ_i r_i[Λ0j(stop_i) − Λ0j(start_i)] over all rows with each provider's own Breslow baseline, computed in the test;
  - weights and ties do not enter the measures given β̂ (M-29), and rows with weight 0 count (M-25, D-58).
- Metamorphic, on Cox fits: row order and provider labels (`closed_form`); the order of the data's columns (identical; D-63); time rescaled (identical measures and tests, person-time scaled); a constant added to the offset (`closed_form`); duplicated rows, which count twice in the measures where weight 2 does not (M-29).
- Edge cases: no events (the fit's error; D-59, D-73); providers without events (the mid-p floor, a lower limit of 0); E_j = 0 (`empty-providers`: NaN ratio, z = 0, p = 1, flag 0, limits NaN and ∞ or 0 and ∞, one warning; D-70); one-row providers; a large covariate mean (finite measures; D-64); recurrent events; a provider all of whose rows have weight 0.
- `test-profile-cox.R`, the profiling functions on Cox fits: the defaults (mid-p, indirect, no interval); the exact test; a numeric `null` (E_j scaled by exp(null), tests against Poisson(exp(null)·E_j); M-40); `providers`; the unsupported requests (one-sided tests and intervals, direct limits, the score, Wald, and bootstrap tests, `provider_effects()`); `profile_providers()` (`effects` is `NULL`, one D-70 warning); the funnel (a provider lies outside its limits exactly when flagged); and the four plots of a profile with an E_j = 0 provider, without warnings.

One regression test per register entry:

| Entry | Regression test |
|---|---|
| D-58 | the measures count rows with weight 0; `zero-weights`' Efron measures differ from pprof_py's beyond `cox_baseline`, its Breslow measures agree |
| D-63 | reordered data columns give identical measures and tests |
| D-70, K-147 | providers with E_j = 0: pprof_py's values and one `pprof_warning_zero_expected` counting them, from each function and once from `profile_providers()` |
| D-71 | an exact test of O = 1000 against E = 10 flags +1, with p = 0 |
| D-73 | a fit without events fails before any measure; mid-p limits under an empirical null are not offered (no `null_model`) |
| M-29, K-136, K-137 | Breslow baselines at an Efron β̂, rows unweighted, against the fixtures and by hand |
| M-36, K-140, K-141 | the exact test's cap and the mid-p floor |
| M-39, K-149 (decision 1) | the funnel against pprof_py's limits and its flags |
| M-40 | a numeric null scales E_j by exp(null) |
| K-142 | flags by the strict inequality p < α and the sign of z, whatever O_j − E_j's sign |

### 4.5 Benchmarks (brief §3.7; DEC-038, DEC-098, DEC-105)

`run_paired.R` on C1's scenarios, in fresh processes that alternate the sides on the same data, with the package installed with `--preclean`:

- **The 10% rule** (a MUST). The fit side is `fit_cox_stratified()`, which now computes `expected_events`, followed by `standardize_providers(fit)`, the indirect measures. The engine side is the fitter call, the preparation of its inputs (C2), and the national expected counts by provider in plain R at the fitter's β̂ (C1's closed form in `run_engines.R`): "the direct engine call it wraps plus the measures", read with DEC-105's preparation. A fit is too slow when, in every round, its median and fastest run exceed that sum by more than 10% and its median by at least 0.05 s (DEC-038). Breslow, Efron, and robust fits, as in C2.
- **Measures and tests**, reported against pprof_py's C1 times (DEC-098's reading of the SHOULD): `standardize_providers(standardization = c("indirect", "direct"))`; `test_providers()` with each test, and `standardize_providers()` with its interval; `funnel_limits()`. The mid-p limits must be substantially faster than pprof_py's (a MUST): at least ten times, where fact 22 measured 100 to 440 times.
- Peak memory and `gc()`'s maximum for each side, and the object's size (one more double per row).
- The report: `dev/bench/results/cox-c3-paired-<date>-windows.md`.
- **The corner scenario** (1,000,000 rows, 7,500 providers, 50 covariates) at the gate (decision 6).

## 5. Commit order

Small commits on `coxph/phase-3`. (S) marks the commits after which §4.1's checks run.

0. Before any change: §4.1's runs at `eedc5a1`.
1. `docs: the CoxPH C3 plan`: this plan, fact scripts 22 and 23 with their outputs and README rows, and the status entry.
2. `reference: pprof_py's Cox funnel limits in the fixture generator` (decision 2): `generate.py` records `CoxPH.funnel_limits()` with the mid-p test at levels 0.95 and 0.998 for each Cox case and cause-specific record; both sets are regenerated, with `compare.R`'s diff reports in `dev/reference/diff-reports/` (only additions expected).
3. `tests: the C3 Cox tiers` (S): `calibrate.R`'s new rows and the regenerated report; in `helper-tolerances.R`, `cox_statistic`'s justification from its calibration, and `cox_root`.
4. `inference: the Poisson tests and their limits` (S): `R/inference-poisson.R`, the constants, `test-inference-poisson.R`.
5. `profile: Poisson counts and provider-level direct expectations` (S): the hooks of §3.6, the warning, the capability expectations of §2.9, and the profiling functions' help.
6. `model: expected events at the national baseline`: `R/model-cox-measures.R`, `expected_events` in the fit and its validator, `test-model-cox-measures.R`.
7. `model: provider profiling of the stratified Cox model`: §3.5, `test-profile-cox.R`, C2's capability test superseded, the help of `fit_cox_stratified()`.
8. `plot: Cox results in the plots` (S).
9. `tests: Cox measures, tests, and funnels against the fixtures`: `test-cox-reference.R`, `helper-cox-fixtures.R`.
10. `bench: Cox fits with their measures, and the tests, against the engines and pprof_py`.
11. `docs: the CoxPH C3 registers and documents`; then the gate (`/phase-gate`), with the corner scenario.

## 6. Decisions this plan asks for

| # | Decision | Recommendation | Register |
|---|---|---|---|
| 1 | The funnel of Cox models. M-39 chose normal limits for "Cox models, which pprof_py lacks", but pprof_py v0.7.0 has them (§2.5): (a) pprof_py's construction, count boundaries under the mid-p test, which agree with the flags by construction (§3.4); (b) M-39 as decided, a Class B difference from pprof_py (D-76) | (a) | DEC-107; M-39 re-decided; K-149 |
| 2 | pprof_py's funnel limits in the Cox fixtures: extend the generator and regenerate both sets, with diff reports, so that the package's funnel is compared with pprof_py's; without it, the funnel is checked only against its defining property and a recount by brute force | regenerate, with 1(a) | DEC-107; the diff reports |
| 3 | `count_distribution = "poisson"` selects the Poisson tests, the limits of the indirect measures, and the funnel's limits, all in `R/inference-poisson.R`; no `measure_limits` field, which the layer rules would not let the model fill (§2.8); `direct_by_provider(model, rows)` as designed | adopt | DEC-108, amending DEC-092; NAMING §10; COXPH_DESIGN §D.2, §D.3 |
| 4 | Tolerances: `cox_statistic` keeps (0, 1e-8), now calibrated (§2.2, §2.3); the mid-p limits get a new tier, `cox_root`, atol 1e-10 and rtol 1e-8 on the ratio scale, from pprof_py's xtol: 1e-10 on the ratio scale when E ≥ 1, and below 2e-9 of the limit when E < 1 at level 0.95, since every nonzero mid-p limit there is at least 0.05 on the mean scale; `root` stays as it is for the existing families (brief §3.5); p-values are compared directly under `probability`, so COXPH_DESIGN §G.2's comparison on the statistic is not needed | adopt (a tolerance needs sign-off) | DEC-109, amending DEC-097 |
| 5 | The mid-p limits computed once per distinct observed count, to rounding, with pprof_py's decisions of 0 and ∞ at its bracket ends: within 0.25 xtol of pprof_py's limits, in 0.43 s against its 62.6 s at 3,000 providers (§2.4) | adopt | DEC-110; K-141's note |
| 6 | Benchmarks: the measures of the 10% rule are the national expected counts by provider in plain R at the fitter's β̂, added to the engine call and its inputs' preparation (DEC-105); "substantially faster" mid-p limits means at least ten times faster than pprof_py's on the same scenario. The corner scenario is measured at the gate on this machine if at least 4 GB of memory is free then, which needs the project lead's other applications closed; otherwise on a machine the project lead names, or on a 16 GB GitHub runner through a manual job written for it, which the project lead dispatches | adopt | DEC-111 |
| 7 | Presentation: the plots leave out points whose estimate is not finite (E_j = 0) with a caption counting them, and name the mid-p test; IDs in `providers` that the model does not have raise `pprof_error_invalid_input`, as for every family, where pprof_py ignores them | adopt | DEC-112; D-77 (presentation) |

## 7. Registers and documents updated in C3

- `dev/DECISIONS.md`: DEC-107 to DEC-112 as approved, with status notes on DEC-092 (amended), DEC-097 (calibrated), DEC-102 (C3 completes §D.2), and DEC-105 (C3's measures timed).
- `dev/CONVENTIONS.md`: where K-136 to K-142 and K-147 are in the package; K-141's note on the roots per distinct count; K-149, the Cox funnel (decision 1).
- `dev/DISCREPANCIES.md`: D-58's measures, D-63, D-70, D-71, and D-73 implemented, with their tests; D-76 under decision 1(b); D-77; any difference found.
- `dev/OPEN_QUESTIONS.md`: M-39's premise corrected and its answer as decided.
- `dev/NAMING.md` §10: no `measure_limits`; `direct_by_provider`'s signature; the Cox funnel; the new constants of `R/constants.R`.
- `dev/design/COXPH_DESIGN.md` as built: §A.4 gains pprof_py's funnel limits; §B.3's funnel row; §D.2 and §D.3; §F.2 and §F.4; §G.2's tiers. The brief is approved and stays as it is; its §2.4 lacks `CoxPH.funnel_limits()`, which DEC-107 and COXPH_DESIGN §A.4 record.
- `dev/design/ARCHITECTURE.md` §E.3 (the Cox column) and §E.6 (as built in C3); the vignette `adding-a-model.Rmd` (the specification's optional fields and the capabilities); `NEWS.md` (Cox profiling, replacing C2's "not yet available"); the help pages; the status document.

## 8. Risks

- **Regenerating the fixtures** (decision 2). The generator reproduces every file byte for byte (DEC-096), and the change adds one output, so the diff reports should show additions only; any other difference stops the work for the project lead.
- **Mid-p limits with many distinct counts.** Their time grows with the number of distinct O_j, about 1.5 ms each here, not with the number of providers: 7,500 distinct counts would take about 11 s, still far faster than pprof_py, whose time grows with providers. A search vectorized over counts is the fallback if the benchmarks show it matters.
- **pprof_py's direct counts at scale** (§2.7). On data much larger than the fixtures, pprof_py's composite sums can drift from the exact value by more than `closed_form` allows. The reference comparisons use the fixtures (at most 20,000 rows); the benchmarks compare times, not numbers.
- **Test time.** The new comparisons run root searches over 32 records; `devtools::test()` took 965 s at the C2 gate. The full-set comparisons stay behind `skip_on_cran()`.
- **The corner scenario** depends on the memory free at the gate (decision 6).
- **The amendment of a decided hook** (decision 3). The `measure_limits` field had no user yet; NAMING §10 and COXPH_DESIGN §D change with it.
