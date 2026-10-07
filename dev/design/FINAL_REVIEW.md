# Final review of the pprof rewrite (Phase 8)

Branch `rewrite/phase-8` at the commit that adds this document, 2026-10-06; CI as read for `f934a04`, the last commit pushed (no package code changed after `5a291c6`). Reference: pprof 1.0.3, commit `5260838`. This document takes each success criterion of the brief (§12) with its evidence, lists the deviations from pprof 1.0.3 with their register entries, the decisions taken under the project lead's delegation for confirmation, and what the project lead and the methodology owners still decide. Evidence lives in the files named; nothing here replaces them.

## Summary

| Criterion (brief §12) | Status |
|---|---|
| 1. Reference fixtures pass on every CI platform; every deviation registered with a decision | Partly met: on the fixtures' platform locally, and against pprof 1.0.3 run on Windows and macOS; on Linux three exact-test statistics are outside the tolerance (D-53); CI's fixture-platform job fails 42 lme4-backed cases in some runs, cause not established; decisions open on D-53, DEC-082, and the Class B sign-offs |
| 2. Statistical behavior unchanged except signed-off Class B decisions | Met: every Class B item reproduces the reference; one known deviation on R 4.5 and later awaits the project lead (DEC-082) |
| 3. Cleaner R code; consistent, documented naming | Met |
| 4. Modern, modular C++ core, Rcpp-free outside the adapters, safe under multithreading | Met; the sanitizer job has not run on Phase 8's commits (it runs on pull requests or on demand) |
| 5. S3 architecture, compact objects, convergence diagnostics | Met |
| 6. Tidy outputs without tidyverse computation; ggplot2 plots; no tidymodels | Met |
| 7. Extension proof; Group Lasso walk-through | Met |
| 8. No unexplained performance or memory regressions | Met: no time regression; peak memory lower in 83 of 84 tasks; the 50-covariate fit's higher peak is explained (D-38's rank check) |
| 9. `R CMD check --as-cran` clean on all platforms; R coverage at least 90% | Met: 0 errors and 0 warnings on every platform; the remaining notes justified; R coverage 96.5% |
| 10. A documented, defensible set of dependencies | Met |
| 11. A model can be added by following the developer guide | Met (Phase 7) |

After the gate, the project lead settled the open decisions below on 2026-10-07; the section "After the gate" at the end gives the outcomes, which supersede the statements above where they differ.

## The criteria

### 1. Reference fixtures on every CI platform

- The fixtures' platform (Windows x86_64, R 4.4.0, R's BLAS, LAPACK 3.12.0): all 364 cases (332 core, 32 full) match locally in every run, with 18 reference errors reproduced and 22 per-case expectations (`tests/testthat/helper-reference-overrides.R`).
- Other platforms (DEC-080): the fixtures' numbers are compared only on their platform; elsewhere the tests compare everything that is not a number. CI builds pprof 1.0.3 on Linux, macOS, and Windows, regenerates the fixtures there, and runs the suite against them with the unchanged tolerances. pprof 1.0.3 itself moves on every platform (102 to 285 of the 332 core cases differ from the committed fixtures). Against pprof 1.0.3 on the same runner, the package matches all 364 cases on Windows (R 4.6.1) and macOS (R 4.5.3), and 361 on Linux (R 4.6.1, OpenBLAS): the exact test's statistic of `test-binary-exact-null0`, `test-binary-exact-null-integer` (4.5e-9 relative), and `test-medium-exact` (9.7e-4 relative) lies outside the iterative tolerance, with the p-values and flags within theirs (D-53; the decision below).
- CI's fixture-platform job is not deterministic: over the last four runs it matched all 364 cases twice (`6fce11f`, `5a291c6`) and failed the same 42 lme4-backed cases twice (`88ef274`, `f934a04`; logistic RE and CRE fits and their methods, up to 3.5e-4 relative, and one linear RE measure at 1.2e-8), with identical package code between a passing and a failing run, the same package versions (now reported), and the same platform string. The cause is not established; the annotations now record the runner's processor, in case the hosted Windows runners differ in it (`dev/design/phase8-facts/08_ci_diagnosis.md`, D-53). Locally, on the machine that produced the fixtures, every run matches.
- Every deviation has a register entry (`dev/DISCREPANCIES.md`, D-01 to D-53); the open decisions are listed below.

### 2. Statistical behavior

- Class B items (a change to a number, flag, inclusion, or default): none was made. D-12 and D-13 were signed off as "preserve" (Phase 4 gate); D-10, D-24, D-31, D-32, D-34, and D-43 are reproduced in the new interface and the wrappers and await sign-off.
- Class A entries (crashes, errors, `NULL`s, misaligned results, nondeterminism): D-04 to D-08, D-11, D-14, D-18, D-19, D-21 to D-23, D-27 to D-30, D-39, D-41, D-42, D-45, D-46, and D-52 (Phase 8); each entry gives its status and regression test, and the migration guide lists the fixes for users.
- D-30 (DEC-082): with one covariate, the likelihood-ratio and score tests raise a classed error, approved when pprof 1.0.3 failed there. From R 4.5.0 pprof 1.0.3 computes them against the model with provider effects only, so on R 4.5 and later the package deviates from it; the per-case expectation states it.

### 3. R code and naming

- `dev/NAMING.md` (approved with the Phase 0 gate) gives the vocabulary; the layers of ARCHITECTURE §B.2 are checked by `tests/testthat/test-architecture.R`; the only file of the reference left in `R/` is the generated `RcppExports.R`.
- `lintr::lint_package()` finds no lints, in CI (`rewrite-lint.yaml`).
- The namespace guard (`dev/design/phase7-facts/07_code_unchanged.R`) between the start of Phase 8 (`0e3cb3c`) and the working tree at `5a291c6`: of 393 functions compared, the ones the plan's steps changed and no other: the twelve old names and the two generics that now warn (step 2: `logis_fe`, `logis_firth`, `linear_fe`, `linear_re`, `logis_re`, `linear_cre`, `logis_cre`, `test`, `SM_output`, `caterpillar_plot`, `bar_plot`), `data_check` (step 3), `plot.logis_fe`, `test.logis_fe`, and `compat_caterpillar_draw` (step 4); added `check_data`, `check_near_zero`, `check_vif`, `check_correlations`, `print.pprof_data_check` (step 3), `compat_deprecate` (step 2), and `compat_logis_fe_test_frame` (step 4); removed `.fix_unused_globals` (step 3). The exports gain `check_data`; the registered S3 methods and the data sets are identical; the C++ sources differ in whitespace only (step 7).

### 4. The C++ core

- ARCHITECTURE §B.3: `src/core/` and `src/logistic/` without Rcpp types, behind the adapters of `src/rcpp_logistic.cpp`; OpenMP regions that never call R or let an exception escape; Firth's data race fixed (D-05); no reference C++ left.
- Formatted with clang-format in a whitespace-only commit and checked in CI (DEC-078).
- The sanitizer workflow (`rewrite-sanitizers.yaml`) runs on pull requests and on demand; it has not run on Phase 8's commits, which change no C++ but its whitespace (the project lead dispatches it, or opens the Phase 8 pull request on the fork).

### 5. S3 architecture

`pprof_` classes with `new_*()` and `validate_*()`; compact model objects that keep the design only with `keep_data = TRUE`; convergence diagnostics of every iteration in the logistic fits (ARCHITECTURE §C, §D).

### 6. Tidy outputs and plots

`tidy()`, `glance()`, and `augment()` methods through generics; data-frame results keyed by provider; numerical code in base R; ggplot2 plots built from result objects only; no tidymodels dependency (ARCHITECTURE §D, §H).

### 7. Extensibility

The toy model of `tests/testthat/helper-toy-model.R` plugs in through the model contract and is tested in `test-extension-toy-model.R`; ARCHITECTURE §E.5 walks through Group Lasso as an independent module; the vignette "Adding a model to pprof" builds the toy model step by step.

### 8. Performance and memory

`dev/bench/results/phase8-final-20261006.md`: all 85 tasks on the working tree against a baseline of pprof 1.0.3 regenerated the same day on the same machine, and the paired re-measurement over three rounds of the four tasks the comparison flagged. No time regression: the three flagged for time are within 4% of pprof 1.0.3 or faster in every paired round; over the 84 tasks the median time ratio is 0.86, and the other tasks slower by more than 10% are slower by at most 0.034 s, mostly the old methods' rebuild of the model (DEC-039). Peak memory is lower than pprof 1.0.3's in 83 of 84 tasks (median 66 MB lower), and before every task's first run (median 62 MB lower): DEC-044's load-order transient is gone. The exception is the 50-covariate fit (a million observations): its process peak is 7% to 28% above pprof 1.0.3's in the three rounds, not above 10% in each, so DEC-079 closes it with the measurements; R's heap peaks 13% (281 MB) above in every round, in the within-provider rank check added for D-38 (pprof 1.0.3 has none), while the fit takes 0.54 to 0.81 times pprof 1.0.3's time. Met, with that explained exception.

### 9. R CMD check and coverage

- Locally, `R CMD check --as-cran --no-manual` of the 2.0.0 tarball (4,447,888 bytes): 0 errors, 0 warnings, 2 notes: the package site's address answers 404 (justified in `cran-comments.md` until the owners publish the site), and "unable to verify current time" on this machine. No example takes over 5 s.
- CI, `R CMD check --as-cran` failing on warnings, on Linux, macOS, and Windows with R release (4.6.1), devel, and oldrel-1 (4.5.3), and R 4.4.0 on Linux and Windows, at `5a291c6`: all eleven jobs pass with 0 errors and 0 warnings; ten report no note; the Linux R 4.4.0 job reports two, the installed size (libs 8.6 MB, built with debug symbols there) and the suggested packages it does not install (caret, logistf, olsrr, pROC), both justified in `cran-comments.md`. CI does not run the CRAN incoming check, so the site's 404 shows only locally. At the final commit `f934a04`: the same, all eleven jobs passing with the same two notes on Linux R 4.4.0.
- Coverage (CI, `rewrite-coverage.yaml`, at `5a291c6`): 96.47% of 3,346 R lines and 99.10% of 555 C++ lines (96.85% in all); the job fails below 90% of R lines.

### 10. Dependencies

ARCHITECTURE §H as built: Imports are Rcpp, stats, utils, poibin, generics, ggplot2 (>= 4.0.0), lme4, scales, and tibble, with RcppArmadillo linked; caret, olsrr, logistf, and pROC are suggested for the tests that compare with them. 38 packages besides R's base packages install with pprof, against 130 for pprof 1.0.3. R >= 4.4.0 (DEC-081).

### 11. The developer guide

`vignettes/adding-a-model.Rmd` and `dev/DEVELOPER_GUIDE.md`; in Phase 7 an agent without the project's context added a model by following the guide (criterion 11's test, PROJECT_CONTEXT §10).

## Deviations from pprof 1.0.3

`dev/DISCREPANCIES.md` holds 53 entries, each with its status. By class: Class A as listed under criterion 2; Class B reproduced, two signed off as "preserve" and six awaiting sign-off; Class C (documentation and messages): D-01, D-02, D-03's message, D-17, D-25, D-26, D-33, D-35, D-37, D-38, D-44, D-48, D-50; presentation: D-09, D-15, D-36, D-47, D-49, D-51; no class (tolerance and platform): D-16, D-20, D-40, D-53. New in Phase 8: D-52 (fixed) and D-53; D-30 updated for R 4.5.

## Decisions taken under the project lead's delegation (2026-10-06), for confirmation

The project lead asked on 2026-10-06 that decisions of theirs follow the recommendation. These were taken that way:

- DEC-080: the committed fixtures' numbers are compared on their platform, and every other platform against pprof 1.0.3 run there.
- DEC-081: `R (>= 4.4.0)`, the oldest version CI finds working with the current dependencies (DEC-074's procedure); the owners may choose a higher one.
- DEC-082: D-30's classed error for one covariate stays until the project lead decides.
- DEC-029 amended: vectors with identical bit checksums match without comparing their summaries.
- Tests that compare platform-dependent outcomes or base R conditions only on the fixtures' platform: the constant and collinear logistic FE fits (rounding decides whether an exactly singular matrix inverts), and `summary.lm()`'s "essentially perfect fit" warning in `data_check()`.
- CI: CRAN's macOS build of gettext for R-devel's source builds; the suggested packages in the R 4.4.0 fixtures job; the generator's child session without the site library (`dev/reference/generate_fixtures.R`; the fixtures it writes are unchanged, shown by regenerating them); the dataset comparison of the diff tool by content.
- Not decided: the three Linux exact-test cases (below). No tolerance changed.

## What the project lead decides

1. The Phase 8 gate.
2. D-53, the three Linux exact-test cases. Options: (a) accept them as the platform's rounding, with a tolerance for the exact test's statistic in the per-platform comparison derived from its conditioning (the statistic of a provider whose tail probability is near 0 carries an absolute error of about the machine epsilon divided by the normal density at the statistic), signed off; (b) keep the design matrix in every logistic FE model so that the exact test can form the linear predictor provider by provider, as pprof 1.0.3 does (memory, and a check of the hypothesis on Linux first); (c) leave the Linux comparison failing on these cases. The diagnostic in the per-platform jobs (`dev/design/phase8-facts/09_linear_predictor_grouping.R`, at `5a291c6`) confirms one mechanism: with OpenBLAS, 52 of the 7,944 rows of ExampleDataBinary's linear predictor differ (by up to 8.9e-16) between the whole design and per-provider products, which moves the exact statistic with null 0 of 4 of 100 providers by up to 1.5e-10 relative; with R's BLAS (Windows, macOS) no row differs. The failing cases differ by more (4.5e-9 and 9.7e-4 relative), so other last-bit differences between the two implementations on OpenBLAS, such as in the fitted coefficients, may add to it; that part is not established. Recommendation: (a).
3. DEC-082 (D-30, one covariate). Recommendation: compute both tests as pprof 1.0.3 does from R 4.5, on every R version, with fixture cases generated on R 4.5 or later (a regeneration that needs the project lead's approval).
4. The sanitizer run on Phase 8's commits (dispatch, or the Phase 8 pull request on the fork).
5. The decisions taken under delegation, above.
6. CI's fixture-platform job, which fails 42 lme4-backed cases in some runs on identical code: let the next pushes record the runners' processors to test the hypothesis (the annotation is in place, not yet run), and meanwhile take the local runs on the machine that produced the fixtures as the evidence for that platform, which every run there matches.
7. The memory of the rank check (criterion 8): keep D-38's within-provider rank check as it is (the default), or check the rank from the crossproduct of the within-provider columns formed one at a time, which avoids two n-by-p copies but may decide the rank differently for nearly collinear designs, so the warning could change.

## What the methodology owners decide

Unchanged from the Phase 8 plan, with the defaults reproducing pprof 1.0.3 until they do:

- M-16: who the methodology owners are, for written sign-off; every item below waits on it.
- The Class B entries awaiting sign-off: D-10 (M-5), D-24 (M-4), D-31 (M-10), D-32 (M-8), D-34 (M-11), D-43 (M-18).
- M-12: the minimum R version (DEC-081 chose R 4.4.0), the release timeline, and the deprecation window (2.0.0 warns; the wrappers remain at least through 2.1.0; removal no earlier than 12 months after 2.0.0).
- The Phase 7 wording list (`dev/design/PHASE7_WORDING.md`).
- The other open questions: M-1, M-6, M-7 (D-26), M-9 (D-07), M-13, M-14, M-15, M-17 (D-38), M-19, and M-20's open part.
- Release decisions: publishing the site at its address or dropping it (DEC-066), the CRAN submission and its timing (`cran-comments.md`), and the authors or a CITATION file.

## After the gate (2026-10-07)

The project lead approved the gate and asked that the open items follow the recommendations ("Let's settle the open items, use your recommendation"). Outcomes, by the numbering of "What the project lead decides":

1. The gate: approved; the gate's commits are on the fork. The pull request into `rewrite/phase-7` is opened by the project lead from the compare page (the GitHub CLI is not installed here); none was open on the fork on 2026-10-07.
2. D-53: option (a), DEC-083. The exact test's statistic is compared on its tail probability, the scale on which it is computed and its p-value compared, within the case's tolerance; no other comparison and no fixture changed. Measured on the fixtures' platform (`dev/design/phase8-facts/11_exact_statistic_rule.R`): last-bit noise in the linear predictor moves up to 16 of the 1,000 statistics of `test-medium-exact` beyond the iterative tolerance (by up to 4.2e-3 at z = 7.8), and none beyond the rule, which still rejects a shift of the null by 1e-9 for 68% to 93% of providers. Locally no case needs it; CI on Linux is the test.
3. DEC-082 (D-30): superseded by DEC-084. With one covariate, the likelihood-ratio test is computed against the model with provider effects only, as pprof 1.0.3 computes it from R 4.5.0, on every R version, and matches pprof 1.0.3 bitwise. The score test keeps the classed error: pprof 1.0.3 fails on it also from R 4.5.0, so there is nothing to follow. The generator emulates R 4.5.0's one-line change to `reformulate()` on older R for the cases marked for it, and the core set was regenerated as approved: 331 cases identical, one changed from an error to pprof 1.0.3's value, four added (`dev/reference/diff-reports/20261007-r450-reformulate-core.md`). Implementing it found two new entries: D-54 (pprof 1.0.3 fits logistic models with no covariates from R 4.5.0; the package keeps its error, DEC-085, a decision for the project lead) and D-55 (with no coefficients, the default stopping rule ends the fit after one iteration, so the one-covariate statistic is computed against provider effects one step from their starting values: 18.31 against 15.21 with a converged null model in the example; Class B, for the methodology owners).
4. The sanitizer run: not yet; it runs when the Phase 8 pull request is opened on the fork, or on a dispatch, which needs a signed-in account.
5. The decisions taken under delegation: DEC-080, DEC-081, and DEC-029's amendment confirmed; DEC-082 superseded by DEC-084.
6. CI's fixture-platform job: the recommendation taken (DEC-080). The first processor reading, at `2becfb4`: the failing run was on an AMD EPYC ("AMD64 Family 25 Model 1"), the fixtures' machine has an Intel Core; one reading does not establish the cause (`dev/design/phase8-facts/08_ci_diagnosis.md`).
7. The rank check: kept as it is (DEC-079 closed).

New for the project lead: D-54 (models with no covariates; recommendation: keep the error for this release). New for the methodology owners: D-55, with D-10, D-24, D-31, D-32, D-34, and D-43 awaiting sign-off.

Checks after these changes: `devtools::test()`: 67 files, 1,122 tests, 7,762 expectations, 0 failed, 0 skipped, 0 warnings; `R CMD check --as-cran --no-manual`: 0 errors, 0 warnings, and the gate's two notes (the site's 404, the time check). `validation/equivalence-report.md` at `d3d4b42`: 368 of 368 cases (336 core, 32 full), 19 reference errors reproduced, 24 per-case expectations (22 for Class A fixes, 2 for D-54), 14 exact tests under DEC-083, none needing it on this platform. `validation/run-differential.R` was not rerun; DEC-083 can only accept more there, and every case matched before.
