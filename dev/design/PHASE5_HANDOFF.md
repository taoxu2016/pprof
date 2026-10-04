# Phase 5 handoff: inference and profiling

Written at the end of Phase 4 (2026-10-04) for the session that plans Phase 5. This is not the plan. The first deliverable of Phase 5 is `dev/design/PHASE5_PLAN.md`, for the project lead's approval, written in the format of `PHASE4_PLAN.md`. The facts below describe the repository at `400f84b` (the approved Phase 4); confirm anything numerical by running code before relying on it (CLAUDE.md).

## 1. Scope

- Brief §4: "All tests, confidence intervals, standardized measures, and flags for every family, routed through the shared layers." The gate is a STOP.
- DEC-040 assigns to Phase 5, for linear FE, linear and logistic RE, and linear and logistic CRE: `profile_spec()` rows, capability declarations, provider tests, intervals, measures, flags, covariate tests (`summary()`, `confint()`), and the wrappers of the old methods. Firth already has the logistic FE inference through its class (DEC-004).
- The targets: ARCHITECTURE §B.4 (what differs between families, as data), §E.3 (capabilities per family; as built in Phase 4 the new families declare none), §D.3 (standard methods), §I (wrappers), §G (validation).
- Scoping questions for the plan:
  - `plot.linear_fe()`, the linear funnel (K-111): Phase 5, with `funnel_limits()` for linear FE, as `plot.logis_fe()` came with Phase 3's slice, or Phase 6. DEC-034 keeps `caterpillar_plot()` and `bar_plot()` as reference code until Phase 6.
  - The reference's generics `test()` and `SM_output()` (`R/test.R`, `R/SM_output.R`) once no reference method is left.

## 2. What exists to build on

- The profiling API (Phase 3, DEC-036): `test_providers()`, `provider_effects()`, `standardize_providers()`, `funnel_limits()`, `profile_providers()`, and `test_coefficients()` (`R/profile-*.R`, `R/inference-*.R`), driven by `profile_spec()` (`R/profile-spec.R`; fields in NAMING §5) and by capabilities (`R/model-capabilities.R`). `provider_test()` is the hook for tests that need a model's internals; Wald caution is opt-in per family (DEC-037).
- Contract methods the new families already have (Phase 4): `expected_outcome()`, `null_effect()`, and `provider_estimate_se()` for `pprof_linear_fe` and `pprof_mixed` (`R/model-linear-fe.R`, `R/model-mixed.R`), and the standard methods. They have no `profile_spec()` row and no `inference_capabilities()` method: `inference_capabilities.pprof_model()` returns an empty vector, so every entry point raises `pprof_error_unsupported_inference`, `confint()` included (`R/inference-coefficients.R`).
- The wrapper pattern for old methods (DEC-032, DEC-039): `test.logis_fe()` and its siblings in `R/compat-methods.R` rebuild a model from the old object (`compat_model_from_logis_fe()` in `R/compat-convert.R`), call the new API, and convert the results to the old shapes. The old RE and CRE objects carry the lme4 fit in `attr(, "model")`; their shapes are in BEHAVIOR_SPECS §16.
- Validation: the method fixtures (core manifest: `test` 68 cases, `confint` 42, `SM_output` 22, `summary` 19, `plot` 7, `caterpillar_plot` 5, `bar_plot` 2) include cases on linear FE, RE, and CRE fits (`dev/reference/cases.R`, from line 320), and now run the reference's method code on the Phase 4 wrappers' objects. `validation/run-differential.R` already runs `test()`, `SM_output()`, `confint()`, and `summary()` on random linear FE, RE, and CRE fits, and `test()` and `SM_output()` on logistic RE and CRE fits. Tolerance tiers: closed-form for linear FE, lme4 for RE and CRE (only under the pinned lme4 and Matrix, DEC-020), root for `uniroot()` limits.

## 3. What Phase 5 replaces

| Reference code (lines) | Notes |
|---|---|
| `R/test.linear_fe.R` (106), `R/test.linear_re.R` (101), `R/test.logis_re.R` (96), `R/test.linear_cre.R` (102), `R/test.logis_cre.R` (102) | K-68 to K-70 |
| `R/SM_output.linear_fe.R` (112), `R/SM_output.linear_re.R` (98), `R/SM_output.logis_re.R` (135), `R/SM_output.linear_cre.R` (104), `R/SM_output.logis_cre.R` (142) | K-82 to K-85 |
| `R/confint.linear_fe.R` (190), `R/confint.linear_re.R` (201), `R/confint.logis_re.R` (202), `R/confint.linear_cre.R` (207), `R/confint.logis_cre.R` (207) | K-92 to K-94 |
| `R/summary.linear_fe.R` (96), `R/summary.linear_re.R` (122), `R/summary.logis_re.R` (68), `R/summary.linear_cre.R` (63), `R/summary.logis_cre.R` (54) | K-103 to K-105 |
| `R/plot.linear_fe.R` (225) | scoping question above (K-111) |
| `computeDirectExp()` in `src/Fixed_effect.cpp`, used by `SM_output.logis_re/.logis_cre` and `confint.logis_re/.logis_cre` | with it go the rest of `Fixed_effect.cpp` (`logist()`, `Exp_direct()`, the dead `p_binomial()`), `src/header.{h,cpp}` (unused `modString()`), `src/myomp.h`, and `tests/testthat/test-cpp-legacy-comparison.R`. `Fixed_effect.cpp` holds the only `// [[Rcpp::depends(RcppArmadillo)]]`, and the adapters take Rcpp types, so the regenerated `RcppExports.cpp` should no longer include RcppArmadillo, leaving `src/core/armadillo.h` as the only way in (DEC-035); check after `Rcpp::compileAttributes()` (RcppArmadillo stays in LinkingTo for the headers) |

Housekeeping that goes with the replacements: the files leave `.lintr`'s exclusions and the legacy list of `tests/testthat/test-architecture.R` (DEC-031); the two partial-match allowances of DEC-021 in `tests/testthat/helper-fixtures.R` (`obs` in `confint()` of logistic RE and CRE fits, `data_includ` in `summary()` of linear RE and CRE fits) go when those methods are replaced.

## 4. Conventions, register entries, and questions in play

- Conventions: PROJECT_CONTEXT §5.7, K-60 to K-70 (tests), K-80 to K-85 (standardization), K-90 to K-94 (intervals), K-100 to K-105 (covariate tests), K-110 to K-113 (funnel and flag plots).
- Behavior: BEHAVIOR_SPECS §7.2–§7.3, §8.2–§8.4, §9.2–§9.4, §10, §11, §14, §16.
- Register entries (status at `400f84b`):
  - D-08: the old methods rely on partial matching of `$`; the new code must not.
  - D-14: integer `null`, fixed in the profiling functions (Phase 3); the wrappers of the new families inherit the fix.
  - D-15: flags are factors in the old outputs; integer flags in results (Phase 3).
  - D-16: the linear FE test distribution follows `spec$provider_variance` (Phase 4).
  - D-21: `threads = 4` hard-coded in the logistic RE/CRE intervals and 2 by default in `SM_output()` (DEC-001).
  - D-31 (Class B, M-10): `summary.logis_re/.logis_cre` give p-values above 1; awaiting sign-off, so reproduced.
  - D-32 (Class B, M-8): linear FE intervals use t with the simplified variance and z with the full one, the reverse of the tests; awaiting sign-off, so reproduced.
  - D-33 (Class C): interval attributes; "RE and CRE follow in Phase 5".
  - D-34 (Class B, M-11): provider order follows the session's collation locale.
- Open questions for the methodology owners: M-8 (D-32), M-10 (D-31), M-11 (D-34), and M-14 (the "predicted over expected" numerator of RE indirect measures, K-82, K-84). M-2 and M-3 were answered at the Phase 4 gate (preserve).
- Decisions that constrain the design: DEC-001 (threads), DEC-011 (`confint()` means covariate intervals), DEC-012 (result objects), DEC-013 (wrappers reproduce the reference, including items awaiting sign-off), DEC-020, DEC-021, DEC-022, DEC-032, DEC-034, DEC-036, DEC-037, DEC-039, DEC-040.

## 5. Carried over from Phase 4 (decided at its gate, 2026-10-04)

- Fixture cases for the RE vector interface (D-11): to be proposed with the first regeneration Phase 5 needs; until then the live comparison of Phase 4 step 3 covers the interface.
- The `glm()` independent check of logistic FE (ARCHITECTURE §G.5), planned for Phase 1 and never written.
- DEC-044: the process peak of `logis_fe()` with 50 covariates on 1e6 observations (R's heap peak is 40 MB above the reference's; the rest lies outside R's heap) is to be investigated in Phase 5 or Phase 8; the memory transient while the dependencies load stays until caret leaves Imports (DEC-009).
- Benchmarks: the task list (`dev/bench/scenarios.R`) has no RE or CRE method tasks, and linear FE methods only on `lin-1e5-m1000-p5`; the baseline has no rows for new tasks, which would have to be measured on the reference (`run_reference.R --only`). A plan item.

## 6. Lessons from Phase 4

- Time and benchmark compiled code only as a release build: `devtools::load_all()` compiles with `-g -O0`, and `R CMD INSTALL .` reuses those objects unless given `--preclean` (the benchmark harness now passes it). Step 1's engine timing was wrong for this reason.
- Benchmark peak memory is the process's peak working set, so transients count; measure R's heap with `gc()` ("max used") alongside to tell them apart.
- lme4's estimates move at the optimizer's precision when the order of observations changes (DEC-043); only identical calls give identical results.
- A live comparison of each new routine with the old one, bitwise on seeded data and fixture inputs, before switching the wrappers, found every difference early (Phases 3 and 4).
- Rough durations on the development machine: `devtools::test()` 4 min, `R CMD check` with tests 9 min, coverage 4 min, `validation/run-reference.R` 3 min, `validation/run-differential.R` 2 min, a full benchmark run 35 min plus the paired re-measurement.

## 7. Suggested start for the planning session

1. Follow "Starting a session" in CLAUDE.md on `rewrite/phase-5`.
2. Read the brief's Phase 5 row, DEC-040, this file, ARCHITECTURE §B.4, §D.3, §E, §G, and §I, BEHAVIOR_SPECS §7 to §11 and §16, PROJECT_CONTEXT §5.7 K-60 to K-113, and the register entries of §4 above.
3. Gather the plan's facts by running code: the reference library is `dev/reference/lib`, and the reference's method files are still in `R/`.
4. Write `dev/design/PHASE5_PLAN.md` (goal; steps with files, approach, and checks; equivalence and tolerances; facts gathered; risks), propose the decisions it needs from DEC-045 on, and stop for approval.
