# Logistic Extensions in `pprof` — Phase Brief

> **Status: approved by the project lead on 2026-10-20 (DEC-143), with its recommendations and §12's process changes.** Approving the brief approves its plan, scope, and gates. The questions of §10 are decided as recommended (DEC-144; M-42 to M-65), by the project lead as methodology owner where they are statistical (M-16, DEC-142); Phase L0's design (`dev/design/LOGISTIC_DESIGN.md`) decides what the brief left open.

## 0. How to use this brief

This brief states what the logistic extensions phase must deliver and which constraints are non-negotiable. The phase brings the features of pprofR 0.2.0 (commit `f23c288`), a fork of pprof's logistic fixed-effect model, into pprof. It continues the v2 rewrite's brief (`git show 5977087:dev/pprof_rewrite_brief.md`) and the CoxPH brief (`dev/coxph_brief.md`), whose principles, conflict order, discrepancy classes, and tolerance rules still apply. Where they differ for the new features, this brief governs. Its companions:

- `CLAUDE.md` and `.claude/rules/`: the working rules, among them the confidentiality rule.
- `dev/DEVELOPER_GUIDE.md` (with "Delegated engines" and "The later models") and `vignettes/adding-a-model.Rmd`: the model contract.
- `dev/design/ARCHITECTURE.md` and `dev/NAMING.md`: the design as built and the vocabulary.
- The registers: `dev/CONVENTIONS.md` (`K-xx`), `dev/DISCREPANCIES.md` (`D-xx`), `dev/DECISIONS.md` (`DEC-xxx`), `dev/OPEN_QUESTIONS.md` (`M-xx`).
- The phase's status document, `dev/LOGISTIC_STATUS.md`, created when Phase L0 starts: a dated entry after each session with material progress, naming the next step.

Requirement keywords:

- MUST / MUST NOT: hard requirements.
- SHOULD / SHOULD NOT: strong defaults; deviate only with a recorded reason in `dev/DECISIONS.md`.
- MAY: optional.

When principles conflict: preserve validated behavior > auditability > correctness and safety > clarity > performance > aesthetics.

Work proceeds in phases separated by gates (§4). At every gate, run `/phase-gate`, report, and STOP until the project lead approves.

The evidence behind this brief, measured on 2026-10-20, is in Appendix A, with its scripts and outputs in `dev/design/logistic-facts/`. Defects found in pprofR are in Appendix B; they MUST NOT be reproduced unless a decision says so.

**Confidentiality.** pprof is a general-purpose package, and the fork is public. pprofR's own files describe how it is used in production, and none of that enters the repository (CLAUDE.md, "Non-negotiables"). This brief and every later document, the code, help, vignettes, NEWS, tests, fixtures and their case names, branch names, commit messages, and pull requests:

- describe the features in general statistical terms, with synthetic data;
- refer to the source only as "pprofR 0.2.0 (commit `f23c288`)";
- never quote pprofR's documentation or copy its files: the fixture generator builds pprofR from the commit in the local object store and records only its commit and version.

Before each commit, the diff is searched for the production terms seen in pprofR, and the check is reported.

---

## 1. Objective and strategy

**Objective.** Extend the logistic fixed-effect model (`fit_logistic_fe()`) and its provider profiling with the five features of pprofR 0.2.0, through pprof's layers and its model contract:

1. **binomial outcomes:** a number of trials for each row, 1 by default;
2. **cluster-level inference** for clusters of rows, for example a subject with several rows: cluster-robust and "stabilized" tests and intervals;
3. **extensions of standardization:** direct standardization over any standard population with per-row weights, the standard errors of direct rates, a chosen denominator for rates, and provider effects supplied by the caller;
4. **a test of the standardized measure itself**, with the interval that inverts it;
5. **a faster direct standardization algorithm.**

**Strategy.**

1. **Reimplement through the layers, and don't port.** pprofR's code is evidence for the specification, not the design. Its features enter pprof as data-layer columns, an engine path, inference routines, profiling options, and presentation, named from `dev/NAMING.md`'s vocabulary. Its interface (`fe_data_prep()`, `logis_fe(data.prep)`, `test_fe()`, `SR_output()`, `direct_exp()`, `test_SM()`) is not carried over.
2. **Keep every existing result bitwise identical.** Binary outcomes are the case of one trial per row. The binary code paths stay as they are, and the binomial path is added beside them (§5.2), so that no existing number moves on any platform.
3. **pprofR 0.2.0 is the reference for the new features**, with independent references wherever they exist (§3.1).
4. **pprof's conventions hold where they exist.** Where an existing convention of pprof and pprofR's differ (§3.3), the new features follow pprof's unless the project lead decides otherwise (§10). Each difference from pprofR is registered with a class.

**Why** (Appendix A):

- **pprofR's binary results are pprof's.** On three data sets, and in every combination of method, stopping rule, and tolerance tried, pprofR's binary fits are bitwise those of pprof, and so of pprof 1.0.3: iterations, estimates, variances, log-likelihood, criteria, and AUC. So are its provider tests and indirect measures, except where a convention differs: the clamp of null probabilities, which matters only beyond 1e-10; the root finder of intervals; the summation of direct standardization; and the scale of rates.
- **Its new features agree with independent references.** Its binomial fit equals `glm()` with a two-column response to 8e-15, and pprof's own binary fit of the data expanded into one row per trial, with the same iterations. Its cluster-robust standard errors of the coefficients equal `sandwich::vcovCL()`'s to 2e-10. Its robust and stabilized tests equal plain-R versions of their formulas to 6e-16, and its standard errors of direct rates equal central differences to 3e-11.
- **Its direct standardization is faster and more accurate.** With 2,000 effects over 200,000 rows it was 27 times faster with a continuous linear predictor, and more than 1,000 times faster with eight distinct values. Its relative errors were about 1e-15, where pprof's double sums reach 4e-12, and for the complement n − E of rates near 1 it was within 4e-6, where pprof's sums were off by up to 19%.

---

## 2. Scope

### 2.1 In scope

1. **Binomial outcomes** for the logistic fixed-effect model: the number of events of each row out of its number of trials. It covers:
   - the data layer: the trials, their checks, the provider table's trials, and screening, with providers that have no events or events equal to their trials;
   - the fit (SerBIN and BAN), the log-likelihood, and the fit statistics;
   - the exact Poisson-binomial and bootstrap tests, the modified score test, and the Wald test;
   - the exact, score, and Wald intervals of provider effects and of standardized measures;
   - indirect and direct standardized ratios and rates and, through the contract, the funnel, `profile_providers()`, and the plots;
   - the covariate Wald, likelihood-ratio, and score tests;
   - `check_data()`.

   The standard score test, which pprof keeps and pprofR removed, extends to binomial outcomes only if Q13 adds it.
2. **Cluster-level inference**, for binary and binomial outcomes, with a column of clusters:
   - cluster-robust (sandwich) Wald tests and intervals for provider effects;
   - a cluster-robust Wald test, and intervals, for the covariates;
   - a cluster-robust score test for provider effects;
   - "stabilized" Wald and score tests, which pool one within-cluster correlation matrix over all clusters by the position of a row in its cluster;
   - screening by the number of clusters of each provider.
3. **Extensions of standardization:**
   - direct standardization over any standard population with per-row weights, exported as a building block;
   - the delta-method standard errors of direct rates (and ratios), from the model-based, robust, or stabilized standard errors of the provider effects;
   - a chosen denominator for rates;
   - direct standardization with provider effects supplied by the caller.
4. **A test of a standardized measure:** the z-test of a measure against a reference value on the identity or logit scale, with the null distribution N(location, scale²), its p-value and flag, and the confidence interval that inverts it.
5. **The faster direct standardization algorithm:** rows with equal linear predictors merged, each exponential taken once, sums in long double. It reaches the existing direct measures only if Q4 decides so (Class B).
6. **Documentation:** help pages, the vignettes' sections, `NEWS.md`, and the developer guide and ARCHITECTURE as built.

### 2.2 Later briefs

Each of these needs its own brief, a methodology decision, and a reference:

- binomial outcomes and clusters for the Firth model, the linear fixed-effect model, and the random-effect families (pprofR has none of them);
- small-sample adjustments of the cluster-robust variances (CR1, CR2), and the full sandwich variance of provider effects (Q7, Q10);
- empirical-null calibration for every family at once (the CoxPH brief's §2.2). The measure test's location and scale (item 4) let a caller supply a null estimated elsewhere.

### 2.3 Non-goals

- MUST NOT port pprofR's code or patch it in. MUST NOT carry over its interface or add compatibility wrappers for its functions; §2.4 maps each one to its place in pprof (Q23).
- MUST NOT change any existing result. The existing families stay bitwise identical, and the deprecated functions of pprof 1.0.3 keep reproducing pprof 1.0.3.
- MUST NOT carry over pprofR's removal of the standard score test.
- MUST NOT change an existing default (the stopping rule, the scale of rates) or number (item 5's algorithm) without the project lead's decision (Q1, Q2, Q4).
- No production data, measure, convention, or parameter value in any test, fixture, example, or document.
- A CRAN release is not part of this work unless requested, but the result MUST stay CRAN-ready.

### 2.4 Every pprofR capability, and where it goes

| pprofR 0.2.0 | What it does | Validated there against | Disposition in pprof |
|---|---|---|---|
| `fe_data_prep(N, Y, Z, ProvID, PatientID, cutoff, check, message)` | joins and sorts the columns; trials; clusters; screens by rows, or by clusters with a cluster column | its tests | the data layer: trials and cluster arguments of `fit_logistic_fe()` and `data_prepare()`, and `min_provider_size` (L2, L3); `check` is `check_data()` |
| `logis_fe(data.prep, algorithm, max.iter, tol, bound, backtrack, threads, AUC, message, stop)` | SerBIN and BAN with trials; five stopping rules, `"beta"` by default | `glm()`, binary and binomial | `fit_logistic_fe()`'s binomial path (L2); the default rule stays `"any"` unless Q1 decides otherwise |
| `coef()`, `vcov()` with the effects' variances | estimates; model-based variances | `glm()` | `coef()`, `vcov()`, `provider_effects()` (L2) |
| `test_fe()`: `"exact.poisbinom"`, `"exact.bootstrap"`, `"score"`, `"wald"` | provider tests with trials | the data expanded into trials (exact test); `glm()` (Wald) | `test_providers()` for binomial outcomes (L2) |
| `test_fe()`: `"robust_wald"`, `"stabilized_wald"`, `"robust_score"`, `"stabilized_score"` | clustered provider tests | plain-R versions of its formulas | `test_providers()` with a choice of variance (L3) |
| no standard score test | removed in pprofR 0.2.0 | — | not carried over: pprof keeps it (§2.3); binomial per Q13 |
| `summary_fe_covar()`: `"wald"`, `"robust_wald"`, `"lr"`, `"score"` | covariate tests; null refits with the fit's settings; two covariates at least | `glm()`, `drop1()` | `test_coefficients()`, `confint()`, and `summary()`, with the choice of variance (L2, L3); the refits per Q14 |
| `confint()`: `option = "gamma"` and `"SM"`; `test = "exact"`, `"score"`, `"wald"`, `"robust_wald"` | intervals of effects and of measures | the estimates lie inside them | the intervals of `provider_effects()` and `standardize_providers()` (L2, L3) |
| `SR_output(stdz, measure, null, threads, se, N_pop, parm)` | indirect and direct ratios and rates; the numerator of the direct rates' standard errors; the rates' denominator; effects replaced by the caller | their definitions | `standardize_providers()`, with standard errors of direct measures, the rates' denominator, and supplied effects (L4) |
| `direct_exp(gamma, Z_beta, N, threads)` | direct expectations over any standard population with weights | their definitions | an exported building block (L4) |
| `test_SM(measure, se, ref, transform, location, scale, level, crit, ci.location, alternative)` | the test of a measure and its interval | its formulas | a measure test on `pprof_measures` results (L4); `crit` and `ci.location` per Q20 |
| `data_check(Y, Z, ProvID, N, message)` | missing values, variation, correlation, variance inflation | — | `check_data()`, which already reports these; trials and clusters added (L2, L3) |
| the direct standardization algorithm | merged rows, sums in long double | its tests | the building block (L4); the existing measures per Q4 |
| AUC, binary outcomes only | missing for binomial outcomes | — | per Q16 |

Names are decided in Phase L0 (§5.6).

---

## 3. The equivalence contract

### 3.1 References

- **pprof 1.0.3** (commit `5260838`) stays the reference of every existing result (CLAUDE.md). The existing families MUST stay bitwise identical. As in the CoxPH phase (`dev/design/COXPH_FINAL_REVIEW.md` §1.3), every commit that touches shared code runs the `data_prepare()` snapshot, `devtools::test()`, and `validation/run-reference.R` before and after, and CI's per-platform reference jobs (DEC-080) run on every push of the phase's branches (§12).
- **pprofR 0.2.0** (commit `f23c288`) is the reference for the new features' definitions, defaults, and numbers, with the exceptions of §3.3 and Appendix B.
- **Independent references** test the method, where the comparison with pprofR tests the reimplementation:
  - `glm()` with `cbind(y, n - y)` and provider indicators at tight convergence: the binomial estimates, their variances (DEC-050's rule), and the log-likelihood up to the constant Σ log C(n, y);
  - pprof's own binary code on the data expanded into trials, each row into n rows of which y have the event: the fits, tests, intervals, measures, and funnel of binomial models;
  - `sandwich::vcovCL()` with clusters of (provider, cluster) pairs, `type = "HC0"`, and `cadjust = FALSE`: the cluster-robust variance of the coefficients;
  - plain-R versions of the robust and stabilized formulas, and direct calculation: central differences for the delta method, the measure test's formulas;
  - the simulation study (`validation/run-simulation.R`): the size and coverage of the clustered tests and intervals on data with correlated rows, and of the binomial tests.
- **How fixtures are made.** Fixtures come only from a committed generator in `dev/reference/` (*proposed* `dev/reference/pprofr/`). The generator:
  - builds pprofR from commit `f23c288` with `git archive` into an isolated library, against Rcpp, RcppArmadillo, and poibin at the versions of `dev/reference/library-lock.json`, and never copies pprofR's files into the repository;
  - runs each case in a separate R session, with `threads = 1` and explicit seeds, on synthetic data from its own seeded generators;
  - writes RDS fixtures at full precision, and a manifest of pprofR's commit and version (never its DESCRIPTION's text), R, the platform, BLAS and LAPACK, the compiler, the package versions, the calls, and the seeds.

  Tests MUST NOT need pprofR. Regenerating fixtures needs the project lead's approval and a diff report. *Proposed* folders: the core set in `tests/testthat/fixtures/pprofr/`, the full set in `validation/fixtures/pprofr/`. The tarball has 17 KB of room below the 5 MB at which `R CMD check` notes its size (COXPH_FINAL_REVIEW §5), so the core set stays small unless Q22 decides otherwise.

### 3.2 What must be preserved

Relative to pprofR 0.2.0, unless §3.3 or a decision says otherwise. Notation: row j of provider i has y_ij events out of n_ij trials, with p_ij = expit(γ_i + z_ij'β), r = y − n p, and v = n p(1 − p). Clusters k are (provider, cluster) pairs, and p0 = expit(γ0 + z'β̂) at the null γ0.

- **The model.** y_ij ~ Binomial(n_ij, p_ij), independent given the effects, with log-likelihood ℓ = Σ[(γ_i + z'β) y − n log(1 + exp(γ_i + z'β))], without the constant Σ log C(n, y).
- **Estimation.** SerBIN and BAN as for binary outcomes (K-10 to K-19), with the weights n p(1 − p):
  - the starting values logit(Σy / Σn) and β = 0;
  - the Armijo line search, the clamp to the median ± `effect_bound`, the criteria, and the loop bounds;
  - the same iteration count as pprofR's at the same settings.
- **Screening and the provider table.** A provider is included when it has at least `min_provider_size` rows, or clusters when a cluster column is given (Q9). It has no events when Σy = 0, and only events when Σ(n − y) = 0.
- **Fit statistics.** AIC and BIC with m + p parameters, and BIC with the logarithm of the number of rows (Q15).
- **Provider tests.**
  - The exact test: a provider's number of events is Poisson-binomial over its individual trials, row j contributing n_ij trials of probability p0_ij, with K-62's mid-p and one-sided tails.
  - The bootstrap: totals of binomial draws, in pprofR's order of draws.
  - The modified score test: z = Σ(y − n p0) / sqrt(Σ n p0(1 − p0)).
  - The Wald test: z = (γ̂ − γ0) / se, with the model-based variance of the block inverse.
- **Cluster-level tests.**
  - Robust Wald test of γ_i: se = sqrt(V_i) / I_i, with V_i = Σ_{k∈i} (Σ_{j∈k} r_j)² at the fit and I_i = Σ_{j∈i} v_j (Q7).
  - Robust Wald test of the coefficients: the coefficient block of the sandwich I⁻¹ M I⁻¹, with the information at clamped probabilities and the meat from the clusters' sums of scores.
  - Robust score test: z = U_i / sqrt(V_i), with U_i = Σ_{j∈i} r_j and V_i at p0.
  - Stabilized tests: V_i replaced by Σ_{k∈i} a_k' R̂ a_k, where a_k holds sqrt(v) of cluster k's rows and R̂ is pooled over all clusters of all providers: entry (s, t) is the average of e_s e_t, e = r / sqrt(v), over the clusters with at least max(s, t) rows; rows with v = 0 contribute 0 to the sums and still count in the averages.
- **Intervals.** The exact and score intervals invert their tests over the trials, with one-sided limits at α for providers with no events or only events (K-90, M-15). Wald intervals use the model-based or robust standard errors. Measure limits map the effects' limits through the sums of n expit(·).
- **Standardized measures.**
  - Indirect: E_i = Σ_{j∈i} n p0 with null variance Σ_{j∈i} n p0(1 − p0), and the ratio O_i / E_i.
  - Direct: E_i = Σ_k w_k expit(γ̂_i + η_k) over the standard population (by default the fit's rows, with w = n), and the ratio E_i / ΣO.
  - Rates: ratio × ΣO / D, with D the rates' denominator, by default Σn over the included rows (Q2, Q3).
- **Standard errors of direct measures.** se(rate_i) = (Σ_k w_k p_ik(1 − p_ik) / D) se(γ̂_i), with the standard error of γ̂_i chosen among the model-based, robust, and stabilized ones. pprofR gives the rates' numerator; the ratios' standard errors, the same over ΣO, follow from the same derivative and have no pprofR reference.
- **The measure test.**
  - The statistic z = (g(M) − g(M_ref)) / (g'(M) se(M)), with g the identity or the logit.
  - The null distribution N(location, scale²); the two-sided p-value 2 min(F(z), 1 − F(z)), or the one-sided tail.
  - The flag where |z − location| / scale exceeds Φ⁻¹(1 − α/2) (one-sided: Φ⁻¹(1 − α)).
  - The interval g⁻¹(g(M) − (location ± c·scale) g'(M) se(M)), c being that critical value.

Presentation MAY change, with documentation: names, container types, column names, row order (results are keyed by provider), messages, and condition classes.

### 3.3 Where pprof and pprofR differ

The new features MUST make each choice below explicit. A choice that changes a number of pprofR is Class B against pprofR; one that changes an existing number of pprof is Class B against pprof 1.0.3 (§3.4).

| # | Point | pprof, binary outcomes, as built | pprofR 0.2.0 | Proposed | Status |
|---|---|---|---|---|---|
| 1 | Null probabilities in the exact, bootstrap, and score tests | clamped to [1e-10, 1 − 1e-10] (K-62, K-64, K-65) | not clamped | pprof's, for binomial outcomes too | Q5; matters only beyond 1e-10 (8e-10 relative on fact 02's extreme data) |
| 2 | Weights exactly 0 in SerBIN's cross block | unfloored (K-12) | floored at 1e-20 | pprof's, so that one trial per row is the binary path | registered; arises only where p(1 − p) is 0 in double |
| 3 | Model-based standard error of a provider effect | K-20's variance: clamped probabilities, the block inverse | its own routine: unclamped, floored weights, one solve per provider | pprof's | registered; bitwise equal on ordinary data, 2e-10 relative on the extreme data |
| 4 | Root finder of exact and score intervals | `uniroot()` at its defaults (tol 1.2e-4) in K-90's brackets | `uniroot(tol = 1e-8)` in its own brackets, widened up to five times | pprof's | Q6; limits up to 3e-5 apart (fact 02) |
| 5 | Scale of rates | percent, clipped to [0, 100] (K-80) | proportion, clipped to [0, 1] | percent | Q2 |
| 6 | Denominator of rates | the number of observations | `N_pop`, by default Σn | Σn (for binary outcomes, the number of observations, as now), or the caller's | Q3 |
| 7 | Default stopping rule | `"any"` (D-24, M-4) | `"beta"` (pprof's `"coefficients"`) | `"any"` for both | Q1 |
| 8 | Direct standardization | a sum over every row in double (K-81) | rows merged, sums in long double | the merged algorithm for the new features; the existing measures per Q4 | Q4: Class B against pprof 1.0.3 for existing results, up to 4e-12 relative (fact 05) |
| 9 | Null refits of the covariate likelihood-ratio and score tests | the default settings (D-10, M-5) | the fit's settings | pprof's | Q14 |
| 10 | Likelihood-ratio and score tests with one covariate | the likelihood-ratio test computed (DEC-084), the score test an error | both an error | pprof's | registered |
| 11 | Standard score test | kept (K-66) | removed | kept | Q13 for binomial outcomes |
| 12 | Covariate Wald p-value | 2(1 − Φ(\|z\|)), in R (K-100) | 2 min(Φ(z), 1 − Φ(z)), in C++ | pprof's | registered; 1e-12 relative |
| 13 | Invalid binomial input: events above the trials; non-integer, negative, or missing trials | — | fitted silently, or a failed solve (B1, B2) | classed errors; rows with missing values dropped, as for every family | Class A (Q18); zero trials per Q17 |
| 14 | Providers with a single cluster | — | robust Wald statistics of order 1e15, robust score statistics ±1 (B3) | missing statistics with a classed warning | Q8 |
| 15 | Clusters too large for the stabilized tests | — | an error beyond 5,000 rows | a classed error at the same limit | registered |
| 16 | Row order within a provider | the input order (a stable sort by provider, K-05) | sorted by cluster label | pprof's: a cluster's rows keep their input order either way, which is the order the stabilized tests use (Q11) | registered: sums in another order, rounding only |
| 17 | Provider effects supplied by the caller | — | the fit's effects replaced; direct standardization only, since indirect fails and its median null moves (B4) | named effects for direct standardization, with the null from the fit's effects | Q19 |
| 18 | The measure test's critical value and the interval's centre | — | `crit` and `ci.location` arguments | from `level`, centred at the null location | Q20 |
| 19 | Long double | sums in double, except where R's `sum()` accumulates them as in pprof 1.0.3 | long-double accumulators in C++ | pprofR's, for its features; compared at `closed_form` where there is no long double (DEC-141) | registered |

### 3.4 Discrepancy protocol

- **Where differences go.** Every difference from pprofR 0.2.0 goes in `dev/DISCREPANCIES.md`, in a new section for this phase that names the reference, numbered from D-82. The fields and classes are CLAUDE.md's, with pprofR as the reference:
  - **Class A:** pprofR crashes, errors, misaligns results with providers, accepts invalid input silently, or depends on row order where it should not. Such an item MAY be fixed, with a regression test.
  - **Class B:** any change to a number, flag, inclusion decision, or default of pprofR. It MUST NOT be made without the project lead's written decision as methodology owner. Until then pprof reproduces pprofR; where an existing convention of pprof prevents that (§3.3), the phase stops at that item for the decision.
  - **Class C:** the documentation contradicts the behavior.
- **Existing results.** No difference from pprof 1.0.3 is allowed in this phase, except one the project lead signs off (Q4).
- **Known defects.** Appendix B lists the defects found so far; Phase L0 registers each one.
- **No shortcuts.** A discrepancy is never resolved by loosening a tolerance, editing a fixture, or dropping a case.

### 3.5 Tolerance policy

The existing tiers stay unchanged. Phase L1 proposes how each kind of result is compared with pprofR, with a one-line justification and a calibration against negative controls (the CoxPH rule: agreement within 1 tolerance unit, every control at least 10 units away):

- **Fits:** iteration counts MUST match pprofR's exactly, and the estimates are compared at the existing `iterative` tier. The binomial path performs pprofR's operations in pprofR's order wherever §3.3 does not choose pprof's convention (fact 02: bitwise for binary outcomes).
- **Closed-form results** (variances given the estimates, the sandwich and stabilized sums, measures and their standard errors, the measure test): `closed_form`.
- **Probabilities:** `probability`. The exact test's statistic is compared on its tail probability (DEC-083), since for a provider far in a tail the upper tail is at the level of its rounding error (fact 03).
- **Intervals:** the existing `root` tier. pprof's root finder against pprofR's (§3.3, row 4) moved limits by up to 3e-5, below the tier's 2.5e-4.
- **Independent references:**
  - `glm()` at DEC-050's tolerances, and `vcovCL()` at `closed_form` after tight fits;
  - the expansion into trials at `iterative` without backtracking, and otherwise within the length of the last Newton step: the line search's last decision compares a change of the log-likelihood near its rounding error, which the two layouts of the data round differently (fact 03).
- **Negative controls:** one event moved between rows, one cluster split in two, and the null shifted by 1e-9.
- **Flags** match exactly, except for providers within tolerance of a threshold, which the equivalence report lists.

### 3.6 Randomness, threads, and determinism

- **Randomness.** Package code never calls `set.seed()`. The bootstrap of binomial outcomes draws from R's generator in pprofR's order; with one trial per row, it draws exactly as the binary bootstrap does (K-64).
- **Threads.** Thread counts come only from `threads` (SerBIN's covariate block, direct standardization), default 1. Direct standardization MUST give identical results for every thread count.
- **Row order.** Results MUST NOT depend on the order of rows, except that the stabilized tests depend on the order of the rows within each cluster, by their definition (Q11). Metamorphic tests pin both.
- **Long double.** Sums in long double differ where the platform has none (arm64 macOS, CRAN's check without long double). Such results are compared at `closed_form` there (DEC-141).

### 3.7 Performance and memory

There is no pprof 1.0.3 baseline for the new features, so pprofR is the comparator. Phase L1 records a baseline in `dev/bench/`.

**Requirements.**

- The existing benchmarks MUST show no regression of the binary paths (DEC-023, DEC-038).
- A binomial fit SHOULD take no more time than pprofR's on the same data, and a clustered test no more than pprofR's.
- The exact test SHOULD NOT expand a provider into its individual trials where an equivalent computation exists. For one provider, pprofR's expansion took 34 s at 20,000 trials and 234 s at 50,000; a plain convolution of the rows' binomial distributions took 14 s and 75 s and agreed to 4e-12 (fact 03). Phase L0 chooses the algorithm, which MUST agree with pprofR's within the `probability` tier.
- Direct standardization: per Q4.
- Memory: no data expanded into trials. The trials and the cluster codes are kept per observation only when they are given, 8 and 4 bytes a row.

---

## 4. Phases and gates

Each phase is a pull request from its own branch (`logistic/phase-0` and so on) into `main`. At every phase:

- the package builds;
- `devtools::test()` and the full reference suite pass;
- `R CMD check` shows nothing new;
- the existing families are bitwise identical;
- the search of the phase's diff for production terms finds nothing.

| Phase | Deliverables | Gate |
|---|---|---|
| L0. Design and decisions | The design document (§9). The questions of §10 registered as M-42 onward and decided; conventions and discrepancy entries; the process changes of §12 listed | STOP for approval |
| L1. Reference capture | The pprofR fixture generator (`dev/reference/pprofr/`) with its isolated library; the synthetic cases of §6; manifests; the calibration report; the tolerance tiers; the benchmark baseline against pprofR | STOP |
| L2. Binomial outcomes | The trials in the data layer and in `check_data()`; the binomial engine path; fit statistics and screening; for binomial outcomes the tests, intervals, measures, funnel, and covariate tests; the contract hooks of §5.4 | STOP for architecture review |
| L3. Cluster-level inference | Clusters for the logistic fixed-effect model; screening by clusters; the robust and stabilized provider tests and intervals; the robust covariate tests; `check_data()` for clusters | STOP |
| L4. Standardization extensions and the measure test | The exported building block for direct standardization with weights, with the faster algorithm; standard errors of direct measures; the rates' denominator; supplied provider effects; the measure test | STOP |
| L5. Documentation and hardening | Help pages and the vignettes' sections; `NEWS.md`; the developer guide and ARCHITECTURE as built; the simulation study's new rows; the final equivalence and benchmark reports; coverage | STOP for final review |

L3 and L4 depend only on L2 and MAY run in either order. The robust and stabilized standard errors of direct measures (L4) come with L3.

---

## 5. Architecture requirements

### 5.1 Data layer

- **Trials.** A trials argument naming a column of `data`, `NULL` meaning one trial per row; the formula's response is the number of events.
  - The trials are non-negative integers, and the events integers from 0 to the trials. Anything else raises a classed error (§3.3, row 13); rows with zero trials per Q17.
  - The provider table adds each provider's number of trials. No events and only events are defined as in §3.2.
  - `glm()`'s two-column response, `cbind(events, non_events)`, is not accepted: the model has one way to be written.
- **Clusters.** `data_prepare()` already keeps a cluster column for the Cox models (NAMING §10); the logistic fixed-effect model uses it too. Clusters are (provider, cluster) pairs, and a cluster's rows keep their input order, which the stable sort by provider preserves.
- **Screening.** With a cluster column, `min_provider_size` counts clusters (Q9).
- **The binary path.** Without these arguments `data_prepare()`'s output is unchanged; the snapshot test (`validation/fixtures/data-prepare-snapshot.rds`) proves it at every commit that touches the data layer.
- **`check_data()`** also reports, for binomial outcomes and clusters:
  - events outside 0 to the trials; non-integer and negative trials; rows with zero trials;
  - providers with no events or only events;
  - the number of clusters of each provider; cluster labels shared by several providers; clusters too large for the stabilized tests.

### 5.2 The model module and its engines

- **The fit.** `fit_logistic_fe()` takes the trials and the clusters. *Proposed:* the class stays `pprof_logistic_fe`, with the trials and the cluster codes as fields; L0 decides. Firth fits refuse trials (§2.2).
- **A binomial path beside the binary one.** The binomial path is new C++ in `src/logistic/` (namespace `pprof::logistic`), behind the adapter, and the binary functions stay as they are. A shared expression with the trials multiplied in could round differently wherever a compiler contracts multiply-adds, as compilers for arm64 do (D-53), and so move existing numbers there; keeping the binary functions unchanged rules that out without having to measure it. *Proposed:* trials that are all 1 take the binary path, so that such a fit equals the fit without trials bitwise; L0 confirms.
- **The iteration path.** The binomial path performs pprofR's operations in pprofR's order wherever §3.3 does not choose pprof's convention, so that it reproduces pprofR's iteration path (§3.5).

### 5.3 Inference layer

- **Clustered variances:** the provider-level meats, the coefficient block of the sandwich, and the pooled within-cluster matrix. They are written in R first, and move to C++ only with benchmark evidence (CLAUDE.md), measured against pprofR's C++ routines.
- **The exact test over trials** (§3.7).
- **The measure test:** its statistic, p-value, flag, and interval.

### 5.4 Contract and shared-layer changes

The contract review found that binomial outcomes and clusters need changes outside the model module, as survival data did (the CoxPH brief's §5.6):

- `expected_outcome()` gives n p for a binomial model, but the exact and bootstrap tests need each trial's probability and the number of trials: a contract hook for each observation's trials, 1 by default;
- the family specification's `variance_function(mean)` knows no trials, while the null variance of indirect standardization and the funnel's precision become n p(1 − p);
- the score tests' sums, the intervals' equations (`infer_effect_interval()`), the measure limits' sums of the mean function, and the full count of the one-sided limits (n_i / E_i becomes Σn / E_i) take the trials;
- `direct_expected` takes weights;
- `test_providers()`, `provider_effects()`, `standardize_providers()`, and `test_coefficients()` take the choice of variance (model-based, robust, stabilized), with new capability names for what a model declares;
- `standardize_providers()` adds standard errors of direct measures, the rates' denominator, and supplied effects.

**How L0 handles them.** Each change is designed as a hook whose default reproduces the existing families, following DEC-046's pattern. The full reference suite, run before and after, proves bitwise identity.

### 5.5 Standardization extensions and the measure test

- **The building block:** given provider effects, a standard population's linear predictors, and its weights, the expected totals and the sums Σ w p(1 − p). It is exported.
- **The measure test** takes a `pprof_measures` result with standard errors and returns a result object keyed by provider.

### 5.6 Naming

In L0, `dev/NAMING.md` gets:

- the trials argument (proposed `trials`) and the provider table's column of trials (proposed `n_trials`);
- the choice of variance for tests and intervals: proposed `variance`, with the values `"model"`, `"robust"`, and `"stabilized"`, checked against the measures tables' `variance` column (or `se_type`), and the capability names it needs;
- the measure test's function and result class, and its arguments: the reference value, the transformation, and the null's location and scale;
- the building block's function, the rates' denominator, and the supplied effects;
- the new conditions, such as a warning for providers with a single cluster.

### 5.7 C++

The binomial engine path (§5.2) is planned. Anything else enters C++ only with benchmark evidence from `dev/bench/`, in `namespace pprof` behind a thin adapter, with every constant named in `src/core/constants.h` and registered (K-150 onward).

---

## 6. Testing and validation

These are required in addition to the existing test layers:

- **A. Reference comparisons** with the pprofR fixtures:
  - binary and binomial outcomes, with and without clusters;
  - both methods, the stopping rules, and default and tight tolerances;
  - every provider test, interval, and measure, the covariate tests, the measure test, and direct standardization with weights.
- **B. Existing results.** At every commit that touches shared code: the snapshot, `devtools::test()`, `validation/run-reference.R`, and the differential tests (`validation/run-differential.R`); the deprecated wrappers' fixtures.
- **C. Closed-form unit tests:**
  - binomial sums by hand;
  - the sandwich and the pooled matrix by hand on small data;
  - the delta method against central differences;
  - the measure test against its formulas;
  - the building block against R's long-double sums.
- **D. Independent references** (§3.1), with sandwich in Suggests and its tests skipped without it.
- **E. Metamorphic tests:**
  - trials of 1 against no trials;
  - the expansion into trials;
  - a provider's rows with equal covariates merged into one binomial row;
  - row order, except within clusters for the stabilized tests;
  - provider and cluster relabeling.
- **F. Edge cases:**
  - a provider whose events equal its trials;
  - providers with one cluster, one-row clusters, a cluster label in two providers, a cluster at the stabilized tests' limit;
  - many trials;
  - probabilities beyond the clamp;
  - direct rates near 0 and 1;
  - missing values and zero trials.
- **G. Regression tests:** one for each register entry.

**New cases**, synthetic only and with generic names:

- binomial data with varied numbers of trials, and with large ones;
- clustered binary and binomial data with correlated rows;
- providers with few clusters;
- extreme linear predictors;
- standard populations with weights and repeated linear predictors.

**Precision.** Inputs are exact in text: integers, and covariates on binary grids. Outputs are stored at full precision.

---

## 7. Dependencies

- **sandwich:** Suggests, as an independent reference in the tests. It is GPL-2 or GPL-3, and used as a separate package.
- **poibin:** already imported.
- No new Imports.
- **pprofR:** only in the fixture generator's isolated library, never in DESCRIPTION.

---

## 8. Documentation and user-facing changes

- **Help pages** for every new function and argument, with examples on synthetic or bundled data that use at most 2 threads.
- **The vignettes:** binomial outcomes and clustered inference in "Statistical methods"; their capability rows in "Models and what they support"; a short example in "Getting started". All in general terms, and within the tarball's room (§3.1).
- **Other updates:** `NEWS.md`; the developer guide; ARCHITECTURE as built.
- No document names a production use, a measure, its conventions, or a person.

---

## 9. Phase L0 deliverable: the design document

`dev/design/LOGISTIC_DESIGN.md`, with:

- **A. Behavior specifications** for every in-scope pprofR function: inputs, defaults, outputs, edge cases, and conventions, each verified against pprofR's outputs.
- **B. The API:** functions, arguments, classes, and result columns; the `dev/NAMING.md` changes.
- **C. Data-layer changes**, and the plan that proves the existing families unchanged.
- **D. The contract mapping:** generics, the family specification, capabilities, and the new hooks.
- **E. The engines:** the binomial path, and what it shares with the binary one.
- **F. The inference and profiling algorithms**, with their cost.
- **G. The validation plan:** cases, generator, environments, tolerance tiers and their calibration, independent references, and the simulation study.
- **H. Dependency decisions.**
- **I. The benchmark grid and targets.**
- **J. Register entries:** conventions (K-150 onward), discrepancies (D-82 onward), questions (M-42 onward), and decisions (DEC-143 onward).

---

## 10. Questions to raise rather than assume

Each question has a proposed default. Phase L0 registers them in `dev/OPEN_QUESTIONS.md` as M-42 onward. The project lead decides all of them; Q2, Q4, and Q21 to Q24 as project lead, the rest as methodology owner (M-16, DEC-142).

| # | Question | Proposed default |
|---|---|---|
| Q1 | The default stopping rule of `fit_logistic_fe()`, binary and binomial: keep `"any"` (pprof 1.0.3's; D-24, M-4), or adopt pprofR's `"coefficients"`, which changes every existing default fit (Class B)? On binomial data `"any"` stopped 1 to 4 iterations before a tight fit, with provider effects up to 7e-4 from it, and `"coefficients"` within 5e-8 (fact 06); D-24 found 0.04 at 1.2 million rows. | Keep `"any"` for both in this phase, so that binomial and binary fits behave alike; M-4 decides for both |
| Q2 | The scale of rates for binomial outcomes: percent, as pprof's rates are (K-80), or pprofR's proportions? | Percent; pprofR's rates are compared after multiplying by 100 |
| Q3 | The rates' denominator: by default the trials of the included rows (for binary outcomes the observations, as now), and a denominator the caller may choose, as pprofR's `N_pop`, for both standardizations? | Yes |
| Q4 | Direct standardization (item 5): the merged long-double algorithm for every direct measure, which changes the existing ones in their last digits (up to 4e-12 relative in fact 05, 7e-15 on ExampleDataBinary) and is more accurate, 27 times faster with a continuous linear predictor, and more than 1,000 times faster with few distinct ones; or the new algorithm for the new features only, and the existing sums for the existing measures? | The existing sums for every existing result until the project lead signs off the Class B change, and the new algorithm for the building block and binomial outcomes. Recommendation: adopt it everywhere |
| Q5 | The clamp of null probabilities in the exact, bootstrap, and score tests of binomial outcomes: pprof's [1e-10, 1 − 1e-10] (K-62, K-64, K-65), or none, as in pprofR? | pprof's (Class B against pprofR, only beyond 1e-10) |
| Q6 | The root finder of the exact and score intervals of binomial models: pprof's (`uniroot()` at its defaults in K-90's brackets) or pprofR's (`tol = 1e-8` in its own brackets)? | pprof's, compared with pprofR's at the `root` tier; a more accurate root finder for every family would be a separate Class B decision |
| Q7 | The robust standard error of a provider effect: pprofR's sqrt(V_i) / I_i, which treats the coefficients as known, or the full sandwich's, which carries their uncertainty? The two differed by up to 3% (fact 04). | pprofR's, documented as such; the full sandwich in a later brief |
| Q8 | Providers with a single cluster: their robust variance is 0 at the maximum likelihood estimates, where a provider's residuals sum to 0, so pprofR's robust Wald statistics are of order 1e15 and its robust score statistics ±1 (B3). Reproduce, or report missing statistics with a classed warning? | Missing statistics, p-values, and flags, with a classed warning (Class B against pprofR); pprofR's numbers for two clusters or more, with Q9's screening as the guard |
| Q9 | Screening with a cluster column: count clusters, as pprofR does, so that adding a cluster column can exclude providers that the same data include without it? At `min_provider_size = 10`, 27 of 60 providers stayed counting clusters, and 54 counting rows (fact 04). | Count clusters, documented |
| Q10 | A small-sample adjustment of the cluster-robust variances: none, as in pprofR; K/(K − 1), sandwich's default; or CR2? | None, as in pprofR |
| Q11 | The stabilized tests pool by the position of a row in its cluster, so they depend on the order of a cluster's rows (by up to 1% in fact 04). Take the input order, as pprofR does, and document that a cluster's rows must come in their natural order (for example by time), or add an argument that orders them? | The input order, documented |
| Q12 | The stabilized tests pool over the clusters of all providers, so a provider's result depends on every other provider, and `providers` only selects what is reported. Confirm? | Confirm |
| Q13 | The standard score test for binomial outcomes, which pprofR lacks: extend it, with the expansion into trials through pprof's binary test as its reference, or declare it unsupported for binomial models? | Extend it |
| Q14 | The null refits of the covariate likelihood-ratio and score tests of binomial models: pprof's rule (the default settings, D-10), or pprofR's (the fit's settings)? | pprof's, so that binomial and binary fits agree; M-5 decides for both |
| Q15 | The log-likelihood of binomial fits: without the constant Σ log C(n, y), as pprofR computes it (equal to that of the data expanded into trials), or with it, as `glm()`'s `logLik()`? BIC with the logarithm of the rows (pprofR, `glm()`) or of the trials? | Without the constant, and the rows; documented |
| Q16 | The AUC of binomial fits: missing, as in pprofR, or the AUC of the data expanded into trials? | Missing, documented |
| Q17 | Rows with zero trials: keep them, as pprofR does (they count as rows for screening and BIC, and add nothing else); drop them with a message; or refuse them? | Keep them; `check_data()` reports them |
| Q18 | Invalid binomial input that pprofR fits silently: events above the trials, and non-integer, negative, or missing trials (B1, B2). Classed errors (Class A), with missing values dropped with their rows as for every family? | Yes |
| Q19 | Provider effects supplied by the caller: for direct standardization only, as effects named by provider for providers in or beyond the fit, with indirect standardization's null computed from the fit's effects? pprofR replaces the fit's effects, which moves the median null and breaks indirect standardization (B4). | Yes |
| Q20 | The measure test's critical value and the centre of its interval: from `level`, centred at the null's location, so that the interval excludes the reference value exactly when the test flags (fact 07), or pprofR's `crit` and `ci.location` arguments, which can break that agreement? | From `level`, centred at the location; neither argument |
| Q21 | Attribution. pprofR's author has been an author of pprof (role `"aut"` in DESCRIPTION) since pprof 1.0.3. Should DESCRIPTION change, and should NEWS name pprofR as the source of the features? | No change to DESCRIPTION; NEWS describes the features in general terms, without naming pprofR |
| Q22 | The fixtures in the tarball, which has 17 KB of room below the 5 MB note: keep pprofR's core set within it, with the full set in `validation/` run on every CI platform (as the Cox full set is, DEC-135), or accept the note? | Within the room; the full set in `validation/` |
| Q23 | Compatibility wrappers for pprofR's functions? | None (§2.3) |
| Q24 | The measure test's default reference value: required, as in pprofR, or the plots' references, 1 for ratios and the population rate for rates (NAMING §4)? | The plots' references |

---

## 11. Success criteria

1. Every in-scope capability of pprofR is available through pprof's contract, and the dispositions of §2.4 hold.
2. All comparisons with pprofR pass under the calibrated tolerances on every CI platform. Every difference from pprofR has a register entry with a decision.
3. The existing families are bitwise identical to before the phase on every CI platform, and the full reference suite passes; the deprecated functions reproduce pprof 1.0.3.
4. Performance meets §3.7, with the evidence in `dev/bench/`.
5. `R CMD check --as-cran` is clean, and coverage of the new R code is at least 90%.
6. The search of the phase's diff from `main` finds no production term.
7. The developer guide says how another family would take binomial outcomes and clusters (§2.2).

---

## 12. Process changes only the project lead can make

- **`CLAUDE.md`:**
  - with the brief's approval, name it and the status document under "Current phase", which now names the brief as awaiting approval;
  - extend the fixture rule and "Equivalence essentials" to the pprofR fixtures and their reference, pprofR 0.2.0 at `f23c288` built in an isolated library.
- **`.claude/rules/tests.md`:** the third reference and its generator, and the rule that its manifest records no text of pprofR's files.
- **`.claude/settings.json`:** protect the pprofR fixture folder as the other fixture folders are protected.
- **`.claude/skills/phase-gate/SKILL.md`:** it names the CoxPH brief, its status document, the phases C0 to C6, and the pprof_py comparisons. Point it at this brief, `dev/LOGISTIC_STATUS.md`, the phases L0 to L5, the pprofR comparisons, and the search for production terms.
- **CI (`.github/workflows/`):**
  - add `logistic/**` to the branch triggers of the six workflows that run on `main`, `rewrite/**`, and `coxph/**`: `rewrite-check`, `rewrite-coverage`, `rewrite-lint`, `rewrite-pkgdown`, `rewrite-reference`, and `rewrite-sanitizers` (pull requests only);
  - run the pprofR comparisons on every platform in the reference workflow, as `validation/run-cox-reference.R` runs the Cox ones (DEC-135);
  - regenerate the pprofR fixtures only locally, since a workflow would have to fetch the upstream commit at run time, pprofR's files being kept out of the repository. *Proposed.*
- **The upstream repository:** fetched read-only, for commit `f23c288` only. Nothing is pushed, commented, or opened there.

---

## Appendix A. Evidence (2026-10-20)

**Setup.** One Windows 11 machine (8 logical cores, 7.4 GB of memory), R 4.4.0 with R's internal BLAS and LAPACK 3.12.0, and Rcpp 1.1.2, RcppArmadillo 15.6.0-1, and poibin 1.6, the versions of the pinned pprof 1.0.3 library. pprofR 0.2.0 was built from `git archive f23c288`, and pprof from this branch, both with `R CMD INSTALL`; sandwich 3.1.3 came from CRAN.

**Scripts.** Each row names the script in `dev/design/logistic-facts/` that produced it; its output sits beside it, and the folder's README says how to rerun them. Timings come from a machine under other load, which was paging during the runs, and moved by up to 30% between two runs of the same scripts; their ratios are the evidence, and Phase L1 measures again with committed benchmarks.

| Check | Result | Script |
|---|---|---|
| pprofR's build and tests | builds against the pinned versions; its 19 test blocks (102 expectations) pass | 01 |
| Binary outcomes: fits | On a synthetic data set (1,896 rows, 40 providers), ExampleDataBinary (7,944 rows, 100 providers, 3 without events), and data with 76 null probabilities below 1e-10: every fit of 2 methods × 2 stopping rules × 2 tolerances is bitwise pprof's, iteration counts included; so are the variances, log-likelihood, AIC, BIC, and AUC | 02 |
| Binary outcomes: inference | The exact (three alternatives), score, Wald, and seeded bootstrap tests are bitwise pprof's, except on the extreme data, where pprof's clamp moves p-values by up to 8e-10 and Wald standard errors by 2e-10, relative. Interval limits of effects differ by up to 3e-5 and of measures by 2e-5 (root finders). Indirect measures are bitwise, and indirect rates agree to 3e-16 once multiplied by 100; direct expectations, ratios, and rates differ by up to 8e-15 relative (summation). Covariate Wald statistics and likelihood-ratio tests are bitwise; the Wald p-value differs by 1e-12 relative and the score test by 7e-15 | 02 |
| Binomial outcomes against `glm()` | 953 rows, 12,072 trials, 30 providers: estimates within 8e-15 relative; variances within 4e-9, `glm()`'s covariance being its next-to-last iterate's (DEC-050); the log-likelihood plus Σ log C(n, y) equals `logLik()` to 1e-16 | 03 |
| Binomial outcomes against pprof on the expansion into trials | The same iteration counts; estimates within 7e-15, at tol 1e-5 and without backtracking at tol 1e-10, and within 1e-9, the last step's length, at tol 1e-10 with backtracking. The tests, intervals, and measures agree, and no flag differs; the exact p-values of providers far in a tail (around 1e-14) are rounding noise | 03 |
| The exact test with many trials | One provider: 34 s at 20,000 trials and 234 s at 50,000 with pprofR's expansion; 14 s and 75 s by a convolution of binomial distributions, agreeing to 4e-12 | 03 |
| Cluster-robust coefficients against sandwich | Equal to `vcovCL(type = "HC0", cadjust = FALSE)` to 2e-11 (binary) and 1.5e-10 (binomial). The robust standard errors were 1.01 (binary) and 1.31 to 1.38 (binomial) times the model-based ones in these data | 04 |
| Robust standard errors of provider effects | Equal to sqrt(V_i) / I_i to 6e-16, and 0.97 to 1.02 times the full sandwich's | 04 |
| Robust and stabilized tests | Equal to plain-R versions of pprofR's formulas to 6e-16. Reversing the rows within each cluster moves the stabilized statistics by up to 1% and the robust ones by rounding only. Clusters are (provider, label) pairs: `vcovCL()` by pairs agrees to 2e-10, and by label alone differs by up to 1e-3 | 04 |
| Screening by clusters | 60 providers, `min_provider_size = 10`: 27 included counting clusters, 54 counting rows | 04 |
| Direct standardization: accuracy | Against R's long-double sums over 200,000 rows, pprof's double sums are within 1.3e-13 (continuous linear predictor) and 3.7e-12 (eight distinct values) relative, and pprofR's within 2e-16 and 1.1e-15, with weights too. For n − E of rates near 1: pprof up to 1.2% and 19% off, pprofR 2e-6 and 4e-6 | 05 |
| Direct standardization: time | 2,000 effects over 200,000 rows, one thread: pprof 19.6 s against pprofR's 0.73 s (continuous), 25.4 s against 0.01 s, the timer's resolution (eight distinct values) | 05 |
| Stopping rules on binomial outcomes | 1 to 1,000 trials per row: `"any"` stopped after 3 to 4 iterations against the tight fit's 5 to 7, with effects up to 7e-4 from it; `"coefficients"` within 5e-8; no score or Wald flag changed | 06 |
| Standard errors of direct rates | pprofR's delta-method numerator over the denominator equals the central difference of the direct rate to 3e-11; doubling the denominator halves the rate | 07 |
| The measure test | Its statistics and p-values follow their formulas to 2e-15, on both scales and for two nulls; its interval excludes the reference exactly when it flags | 07 |
| Supplied provider effects | Direct standardization with two effects added gives 42 rates, the fit's 40 unchanged; indirect standardization fails; the median null moves from −0.460 to −0.440 | 07 |
| pprofR at the edges | Events above the trials, non-integer, zero, and negative trials: fitted silently. Missing trials: an error with the checks on, a failed solve with them off. One cluster per provider: robust Wald statistics of order 1e15, robust score statistics ±1. A 5,001-row cluster: an error from the stabilized tests | 08 |

---

## Appendix B. Defects in pprofR 0.2.0

These are not to be reproduced without a decision. Each was found by running code on 2026-10-20, with the script in `dev/design/logistic-facts/` named in the evidence column, except where that column cites the code.

| ID | Defect | Evidence |
|---|---|---|
| B1 | Invalid binomial input is fitted silently: events above the trials, and non-integer or negative trials; neither the data preparation nor the fit checks them | 08 |
| B2 | A missing number of trials makes the fit fail inside its solver (`solve(): solution not found`) when the data checks are off, instead of dropping the row | 08 |
| B3 | With one cluster per provider, the robust variance of a provider's score is the square of its residual sum, which is 0 at the maximum likelihood estimates and so only as large as the fit's remaining error: the robust Wald statistics are of order 1e15, so every provider is flagged, and the robust score statistics are ±1 | 08 |
| B4 | Provider effects supplied by replacing the fit's: indirect standardization fails, and the median null computed for it includes the supplied effects | 07 |
| B5 | The robust covariance of the coefficients is assembled with twice one cross term (2 J A₁ S⁻¹) where the sandwich has that term and its transpose, so the matrix is not symmetric. Only its diagonal is used, and the diagonal is the sandwich's | code (`src/Fixed_effect.cpp:485-487` at `f23c288`); 04 for the diagonal |
| B6 | The exact test expands each row into its trials before computing the Poisson-binomial distribution, at a cost quadratic in a provider's trials | 03 |
