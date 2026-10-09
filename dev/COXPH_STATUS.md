# CoxPH phase: status

The dated log of the CoxPH phase (`dev/coxph_brief.md`, §0): an entry after each session with material progress, naming the next step. Newest last.

**Status:** Phase C2, the data layer and the stratified Cox model, is closed (2026-10-09) and in `main`. Phase C3, provider profiling for the stratified Cox model, has its plan (`dev/design/COXPH_C3_PLAN.md`), awaiting the project lead's approval.

## 2026-10-07

- The project lead approved the brief (`dev/coxph_brief.md`) and its §12 process changes (DEC-086).
- The evidence behind the brief, with its scripts and outputs, is in `dev/design/coxph-facts/` (commit `ed2e168`).
- Branch `coxph/phase-0`, from `main` at `ea7c07b`: the brief, the evidence, DEC-086, this document, and the §12 changes.
- Open: the brief's §10 questions (Q1–Q16) and the Class B items of its §3.3 still need their sign-offs; Phase C0 registers them as M-23 onward and D-56 onward. The Cox fixture folder is planned as `tests/testthat/fixtures/cox/` (protected in `.claude/settings.json`); Phase C1 confirms the path.
- Next step: Phase C0, the design document `dev/design/COXPH_DESIGN.md` (brief §9), when the project lead asks for it.

## 2026-10-08: Phase C0 at its gate

- On 2026-10-07 the project lead asked for Phase C0, delegated its decisions, the sign-offs the brief's §10 names among them ("use your best judgement or recommendation for the decisions"), and asked for the work to be pushed to `coxph/phase-0`.
- Delivered (brief §4 and §9):
  - `dev/design/COXPH_DESIGN.md`, parts A to J (`61991e7`); at the gate, two dangling cross-references were fixed (M-34, DEC-090), §F was split into subsections F.1 to F.6, which the design already cited, and §F.4 now roots the mid-p limits on pprof_py's bracket and split point (§A.4, K-141) instead of the exact limits, which need not enclose them;
  - the registers (`2bc0303`): K-131 to K-147, D-56 to D-74, M-23 to M-41, and DEC-087 to DEC-093;
  - `dev/NAMING.md` §10, and the note in `dev/design/ARCHITECTURE.md` §E.6 (`9a087c2`).
- Decided under the delegation: M-23 to M-41 as proposed, and with them the Class B items D-56 to D-61, D-64, and D-72. Each awaits confirmation by a methodology owner once M-16 names them.
- Gate checks. C0 changes no package code.
  - `devtools::document()` changed nothing.
  - `devtools::test()`: 67 files, 1,122 tests, 7,762 expectations; none failed or skipped, no warnings or errors, as at the rewrite's final gate. It took about 3 hours, with no sleep or standby in that time, on `load_all()`'s build of the C++ engines without optimization (`-O0 -g`) and with the heavy tests that `R CMD check` skips (`skip_on_cran()`). The reference suite took 98 s on the same build, so the time goes elsewhere in the suite; earlier phases did not time it, so whether it has slowed is not known.
  - `R CMD check --as-cran --no-manual`: 0 errors, 0 warnings, and the previous gate's 2 notes (the package site's address answers 404; "unable to verify current time"); 755 s.
  - `validation/run-reference.R`: 368 of 368 cases match, none skipped, and no provider lies within tolerance of a flag threshold; the report equals the committed `validation/equivalence-report.md` but for its date and commit; 98 s.
- CI on the pushed `6d18a29`: check, coverage, lint, and pkgdown passed. In `rewrite-reference` (run 37699886675), the per-platform jobs matched pprof 1.0.3 run on their runners (368 of 368 cases on Windows, macOS, and Linux), and the fixture-platform job failed the 42 lme4-backed cases it failed in four runs of Phase 8. The processor accounts for it: in the five runs of that job that record one, it failed on every AMD Zen 3 runner (32 KB L1 data cache) and passed on every Zen 5 runner (48 KB, as on the machine that produced the fixtures), and Eigen, through which lme4 forms its cross-products, sizes the blocks of its matrix products from the L1 cache, which would explain it; it is not yet reproduced with lme4 itself (D-53, updated; `dev/design/coxph-facts/15_eigen_cache_blocking.R`).
- Open for the project lead:
  - confirming the delegated decisions, or sending them to the methodology owners;
  - a remedy for the processor dependence of the fixture-platform job (D-53);
  - the brief's title still says "(draft)";
  - the manual workflow that regenerates the Cox fixtures (brief §12), which comes with the C1 generator;
  - timing `devtools::test()` per file, since COXPH_DESIGN §C.2 runs it before and after every data-layer commit of C2.
- Next step: the project lead's approval of the C0 gate; then the pull request of `coxph/phase-0` into `main`, and Phase C1 (reference capture) on `coxph/phase-1` when the lead asks for it.

## 2026-10-08: the C0 gate closed

- The project lead approved closing the C0 gate and asked to continue with the recommendations of the gate report wherever a decision is needed. In particular:
  - the delegated decisions stand: DEC-087 to DEC-093, M-23 to M-41, and the Class B items D-56 to D-61, D-64, and D-72 are confirmed by the project lead; a methodology owner's confirmation still waits for M-16;
  - the brief's title no longer says "(draft)";
  - the remedy for the processor dependence of the fixture-platform CI job (D-53), building lme4 there with Eigen's cache query turned off and its cache sizes fixed at the fixtures' machine's, is tried in C1 and kept only if it reproduces the fixtures;
  - `devtools::test()` is timed per file in C1.
- CI on `cb5b99e`, the C0 head: check, coverage, lint, and pkgdown passed; in `rewrite-reference` (run 37785727924), the three per-platform jobs matched pprof 1.0.3 on their runners (368 of 368), and the fixture-platform job failed the 42 lme4-backed cases on an AMD Zen 3 runner: the sixth run that records a processor, and the sixth to fit D-53's pattern.
- The pull request of `coxph/phase-0` into `main` goes through the compare page (`gh` is not installed here): <https://github.com/taoxu2016/pprof/compare/main...coxph/phase-0?expand=1>.
- Next step: Phase C1 on `coxph/phase-1`, stacked on `coxph/phase-0` until its pull request is merged; first, its plan.

## 2026-10-08: Phase C1 at its gate

- Plan: `dev/design/COXPH_C1_PLAN.md`, adopted under the project lead's delegation at the C0 gate; its decisions are DEC-094 to DEC-097.
- Delivered (brief §4, row C1):
  - the generator, `dev/reference/cox/` (`generate.py`, `cases.py`, `survival.R`, `convert.R`, `calibrate.R`, `compare.R`, README), with its pinned environments: Python 3.12.3 from `uv` with pprof_spark's pins and pprof_py at `9320766`, checked module by module; an isolated R library with `survival` 3.8-12, `glmnet` 5.1, and `jsonlite` from the DEC-017 snapshot (DEC-095);
  - the imported inputs, vendored from their commits with their SHA-256: pprof_spark's six Cox cases and pprof_py's penalized and competing-risk datasets;
  - 20 fixtures with manifests: 7 shipped in `tests/testthat/fixtures/cox/` (396 KB), 13 in `validation/fixtures/cox/` (2.1 MB); a second generation reproduced every fixture and manifest byte for byte (DEC-096);
  - the calibration report, `validation/cox-calibration-report.md`, and eight Cox tiers in `tests/testthat/helper-tolerances.R` (DEC-097): all 598 scored rows pass, and 46 rows are differences the registers explain (D-56 14, D-57 3, D-58 18, D-64 9, M-23 2); pprof_py here against pprof_spark's committed outputs: default fits within 1e-14, tight fits within 4e-9;
  - `tests/testthat/test-cox-fixtures.R`: every fixture against its manifest, and the installed `survival` and `glmnet` reproducing the fixtures' engine outputs; `survival` and `glmnet` in Suggests;
  - the benchmark baseline, `dev/bench/cox/` and `dev/bench/results/cox-*-20261008-windows.*`;
  - CI: `cox-fixtures.yaml`, which regenerates the fixtures by hand into an artifact (not yet dispatched), and the fixture-platform job's lme4 build (DEC-094), confirmed on a Zen 4 runner.
- Found:
  - with Efron ties, `glmnet` 5.x's `coxnet.deviance()` uses another saturated term than pprof_py (a constant 336.7 on `penalized_wide`), so the cross-validation deviance is computed with pprof_py's (K-144, COXPH_DESIGN §E.2);
  - D-57 occurs at tight control too: pprof_py halved the last step of a Fine–Gray fit with Efron ties once or five times;
  - the `large-mean` case exercises D-64 only in part: its fitted linear predictor stays below pprof_py's clipping at 700;
  - on the baseline's data pprof_py fits faster than `survival` at 1,000,000 rows, with one numba thread or eight (4.3 s against `agreg.fit()`'s 17.2 s; robust variance 5.2 s against `coxph()`'s 130 s), so the brief's "no slower than pprof_py" will not hold for large fits;
  - the first calibration report counted outputs it could not compare as passes; corrected in `ed9c04e`.
- `devtools::test()` per file: 13.1 minutes in all (68 files, the slowest 77 s), so the 3 hours at the C0 gate came from that run's circumstances.
- Gate checks:
  - `devtools::document()` changed nothing;
  - `devtools::test()`: 68 files, 1,126 tests, 7,928 expectations; none failed or skipped, no warnings or errors (424 s);
  - `R CMD check --as-cran --no-manual`: 0 errors, 0 warnings, the 2 notes of the previous gates (780 s);
  - `validation/run-reference.R`: 368 of 368 cases, none skipped, no provider within tolerance of a flag threshold; the report equals the committed one but for its date and commit (117 s);
  - the Cox comparisons: the calibration report above, and `test-cox-fixtures.R` (166 expectations).
- Open for the project lead:
  - approving the Cox tiers (DEC-097), since a tolerance changes only with sign-off;
  - regenerating the fixtures with a stronger `large-mean` case (a covariate near 3,000), which needs approval and a diff report;
  - the brief's "no slower than pprof_py" for large fits: accept it as not met, or look in C2 for a cheaper robust variance than `coxph()` with one cluster per row;
  - dispatching `cox-fixtures.yaml` once, to try the workflow.
- Next step: the project lead's approval of the C1 gate; then Phase C2 (the data layer and the stratified Cox model) on `coxph/phase-2`.

## 2026-10-08: the C1 gate closed

- The project lead approved closing the C1 gate and every recommendation of its report:
  - the Cox tiers are approved (DEC-097), and DEC-093 to DEC-096 confirmed;
  - the fixtures were regenerated with a stronger `large-mean` case, a covariate near 3,000, so that pprof_py's clipping shows (D-64). The diff reports (`dev/reference/diff-reports/20261008-cox-large-mean-core.md` and `-full.md`) show `large-mean` changed throughout and the other cases only in the R side's expected counts, by at most 9.5e-14 relative, from shifting the linear predictor by its maximum. The calibration passes 586 of 586 scored rows, with 58 explained (D-56 14, D-57 3, D-58 18, D-64 21, M-23 2), and `test-cox-fixtures.R` passes;
  - large fits may be slower than pprof_py's (DEC-098); C2 looks for a cheaper robust variance than `coxph()` with one cluster per row;
  - the project lead runs `cox-fixtures.yaml` once from the fork's Actions tab, to try it.
- Next step: Phase C2 in a new session. Its plan first, `dev/design/COXPH_C2_PLAN.md`, for the project lead's approval; then the data layer, the `survival` adapter, `fit_cox_stratified()`, and its methods (brief §4, row C2; COXPH_DESIGN §B to §E), on `coxph/phase-2` from `coxph/phase-1`.

## 2026-10-08: the C2 plan

- Branch `coxph/phase-2`, from `coxph/phase-1` at `78e3e15`.
- The plan, `dev/design/COXPH_C2_PLAN.md`, for the project lead's approval, with the evidence behind it in `dev/design/coxph-facts/17` to `20`. Found while planning:
  - `survival`'s fitters give `coxph()`'s fit bitwise only when called with `coxph()`'s preprocessing (the offset minus its mean, `nocenter = c(-1, 0, 1)`, integer strata codes); C1's engine baseline called `agreg.fit()` without it, on rows in the generator's order, so the C2 benchmarks pair each fit with its own engine call;
  - a robust variance bitwise equal to `coxph(cluster = row)`'s, from `survival`'s own dfbeta residuals on the fitter's result: 2.0 s against 20.7 s at 1,000,000 rows (DEC-098's search);
  - pprof_py computes the covariate p-values as upper tails, 2Φ̄(|z|), where the package's default rule gives 0 above |z| = 8.3;
  - `Surv()` reads a 0/1/2 status as 1/2 coding and turns start ≥ stop into NA, so the data layer must raise errors there rather than delete rows;
  - the fixtures of D-58, D-64, D-56's `recurrent`, and D-60 are in the full set, outside the tarball, so unit tests carry those decisions under `R CMD check`.
- Next step: the project lead's approval of the plan and its §6 decisions; then its §5 commits, starting with the `data_prepare()` snapshot.

## 2026-10-09: Phase C2 at its gate

- On 2026-10-08 the project lead approved the plan and its seven decisions as recommended (DEC-099 to DEC-104; decision 7, the benchmark comparator, under DEC-100).
- Delivered on `coxph/phase-2` (brief §4, row C2), in the plan's §5 order:
  - the plan and its evidence, `dev/design/coxph-facts/17` to `20` (`a039fed`, `7b0cb5e`; the plan's D-60 unit test corrected in `071dff3`);
  - a snapshot of `data_prepare()` on the 368 reference cases, taken from the unchanged code, and its test (`8b6908b`, `8260ed0`; `validation/fixtures/data-prepare-snapshot.rds`, `dev/tools/data_prepare_snapshot.R`);
  - the data layer: `Surv()` responses, entry times, weights, clusters, and offsets; `survival` in Imports and `Surv()` re-exported (`c290bd0`, `fde52e8`); models without provider effects (`f0fb94e`); the covariate p-value as an upper tail (`fc3e734`); survival data in `check_data()` (`6358f53`);
  - the survival adapter, `R/model-survival.R` (`f0fbe45`); `fit_cox_stratified()`, `baseline_hazard()`, and their methods, `R/model-cox-stratified.R` (`f5e6440`); the tests against the Cox fixtures, `tests/testthat/test-cox-reference.R` (`1b6db94`);
  - the paired benchmarks, `dev/bench/cox/run_paired.R` and `summarize_paired.R` (`120511b` to `464a269`), their report, `dev/bench/results/cox-c2-paired-20261009-windows.md` (`ec42837`), and fact 21, where a fit's time goes (`abd009b`);
  - the registers and documents (`65ea803`).
- The existing families are unchanged: at each data-layer commit (`c290bd0`, `fde52e8`, `f0fb94e`, `fc3e734`, `6358f53`) `devtools::test()` passed and `validation/run-reference.R` gave the committed equivalence report but for its date and commit, and the `data_prepare()` snapshot test passes.
- Found:
  - the benchmark rule: every fit's estimates equal its engine call's bitwise, but against the bare fitter call (the plan's decision 7) 17 of 21 fits are more than 10% slower, by the preparation of the inputs from the data frame (the model frame alone takes 13% of the fitter's time at 20 covariates); against the fitter plus that preparation none is, and the fits take 0.2 to 0.5 of `coxph()`'s time. DEC-105 proposes the reading with the preparation. The corner scenario could not be measured: the machine paged (17 GB committed on 7.4 GB of memory), and a corner fit got 11.0 s of processor time in 28.7 s;
  - the SHOULD for the robust variance (DEC-098) holds with 5 covariates and not at the other sizes: the robust step takes 2.0 to 2.4 s at 1,000,000 rows where pprof_py's adds 0.9 s;
  - D-75: survival's `survfit()` cannot give the baseline or the curves of a fit without covariates at offset 0, so the package raises `pprof_error_unsupported_inference` there, where pprof_py reports them (Class B, awaiting the project lead);
  - on D-38: the logistic rank warning names no covariate when the within-provider rank is 0 (Class C, existing family, not fixed);
  - survival 3.8-12's quirks, handled in the adapter and recorded in its comments: `coxph.control()` warns for `eps` below `toler.chol`; `coxph.fit()` reports `iter.max + 1` iterations when it does not converge and warns only when `iter.max > 1`; `survfit()` fails with new data that name the stratum of a one-stratum model, and with new data for a model without covariates.
- Gate checks:
  - `devtools::document()` changed nothing;
  - `devtools::test()`: 74 files, 1,191 tests, 9,846 expectations; none failed or skipped, no warnings or errors (965 s, beside `R CMD check`). The Cox comparisons: `test-cox-reference.R` 1,032 expectations on the core and full sets, `test-cox-fixtures.R` 166, `test-model-survival.R` 183, `test-model-cox-stratified.R` 189;
  - `R CMD check --as-cran --no-manual`: 0 errors, 0 warnings, the 2 notes of the previous gates (1,096 s, beside the coverage run); in a git worktree it adds a third note, the worktree's `.git` file, which `R CMD build` drops only as a directory;
  - `validation/run-reference.R`: 368 of 368 cases, none skipped, no provider within tolerance of a flag threshold; the report equals the committed one but for its date and commit (167 s);
  - `covr::package_coverage()`: 96.45% of the package; of the R lines C2 added (against `coxph/phase-1`), 598 of 628 relevant lines, 95.22%, the uncovered ones mostly the failure branches of `validate_pprof_cox_stratified()` (698 s; covr runs the tests without `skip_on_cran()`'s heavy ones);
  - `lintr`: the 30 changed package, test, and benchmark files are clean (the plan's fact scripts 17 to 20 keep `<<-` and long lines).
- Open for the project lead: DEC-105; D-75; the D-38 message; measuring the corner scenario on a machine with more memory.
- Next step: the project lead's review of the C2 gate.

## 2026-10-09: the C2 gate closed

- The project lead approved closing the C2 gate and asked for the gate report's recommendation on each open question:
  - DEC-105 is accepted: the 10% rule compares a fit with its engine call plus the preparation of the engine's inputs, under which no C2 fit is too slow; `dev/bench/cox/summarize_paired.R` gives that verdict as the rule's, and the report was regenerated from the same measurements;
  - D-75 is decided as option (1): no baselines or curves for a fit without covariates, with `pprof_error_unsupported_inference`;
  - D-38's message is fixed (`54572a9`): at within-provider rank 0 the warning names every covariate, with a regression test that fails without the fix; the logistic tests pass and the reference suite is unchanged (368 of 368);
  - the corner scenario is measured at the C3 gate, on a machine with enough free memory.
- The project lead asked for the work to be pushed to the fork's `main` and every other branch deleted: `coxph/phase-0`, `coxph/phase-1`, and `coxph/phase-2` are fast-forwards of `main`, so `main` takes `coxph/phase-2` as it is.
- Next step: Phase C3, provider profiling for the stratified Cox model (the brief's §4), in a new session and only when the project lead asks: its plan first, `dev/design/COXPH_C3_PLAN.md`, for approval, on a branch from `main`.

## 2026-10-09: CI on `main` after the C2 gate

- `main` at `e744e3f` was pushed to the fork, and the phase branches deleted there and locally, at the project lead's request. CI: reference, lint, and pkgdown passed; `rewrite-check` failed on every R but R-devel (Linux, macOS, Windows) and `rewrite-coverage` failed, on the same engine-identity tests (runs 37954936891 and 37954937202).
- The cause: those Rs bundle older survival, whose `coxph()` differs from the 3.8-12 that the adapter follows (survival's sources on CRAN): up to 3.8-9 it coded a cluster column by sorted value rather than first appearance, up to 3.8-3 it formed the robust variance as `t(temp) %*% temp` rather than `crossprod(temp)` (the same under R's reference BLAS, not under Ubuntu's OpenBLAS), and before 3.7-3 it found `strata()` only from a formula's environment, so five direct `coxph()` calls in the tests errored on R 4.4.0 (survival 3.5-8). The variances differ by about 1e-16 relative.
- Fixed at the project lead's request (DEC-106): DESCRIPTION requires survival 3.8-11 or later, the first version on CRAN with the behavior the adapter follows; no code changes. A first attempt, following each installed survival's cluster coding, was dropped for this: it would also have had to copy the older product and could not be checked here under OpenBLAS.
- Checked here: with survival 3.5-8 (R 4.4.0's, in a scratch library) the failures reproduce, and loading the package now stops with "The package "survival" (>= 3.8-11) is required"; with 3.8-11 and 3.8-12 the Cox and survival test files pass (67 tests, 2,071 expectations each).
- CI on `34243d6`: coverage, reference, lint, pkgdown, and `rewrite-check` on ten of its eleven jobs pass. The "fixtures" job (Windows, R 4.4.0) failed 229 lme4-backed comparisons with the pprof 1.0.3 fixtures, by about 1e-5 relative: survival 3.8-12 brought Matrix 1.7-6, the manifest's, so the job compared the lme4 cases, which it had skipped before (240 skips at `e744e3f`, 11 now; R 4.4.0 bundles Matrix 1.7-0, and the job logs, which would show the versions, need signing in), and CRAN's lme4 binary on its Zen 3 runner is D-53's case. The job now builds lme4 from source with the fixture machine's Eigen cache sizes before the check, as `rewrite-reference.yaml`'s fixture-platform job does (DEC-094).
- CI on `9882934`: every workflow passes, all eleven `rewrite-check` jobs among them (run 37966221816). The "fixtures" job, on a Zen 3 runner again, built lme4 2.0-6 with the fixed cache sizes against Matrix 1.7-6 and passed with the lme4-backed cases compared (8,511 expectations passed, none failed, 11 skipped).
- Next step: Phase C3 when the project lead asks.

## 2026-10-09: the C3 plan

- The project lead asked for Phase C3. Branch `coxph/phase-3`, from `main` at `eedc5a1`.
- The plan, `dev/design/COXPH_C3_PLAN.md`, for the project lead's approval, with the evidence behind it in `dev/design/coxph-facts/22` and `23`. Found while planning:
  - pprof_py v0.7.0 has funnel limits for Cox models, `CoxPH.funnel_limits()`: count boundaries under the test's Poisson null, which agree with its flags. The brief's §2.4 and COXPH_DESIGN §A do not record them, and M-39 chose normal limits for "Cox models, which pprof_py lacks"; on the `provider-scale` fixture those limits disagree with the mid-p flags for 13 of 1,000 providers. A plain-R construction reproduces pprof_py's limits exactly (the plan's decisions 1 and 2);
  - pprof_py's measures and tests, written in plain R, reproduce its fixture outputs on all 32 Cox and cause-specific records: expected counts within 2.5e-4 of `closed_form`, statistics within 1.2e-3 of `cox_statistic`, flags identical, mid-p limits within 0.25 of pprof_py's own root tolerance; the brief's negative controls differ by at least 4,000 tier units, which calibrates `cox_statistic` as it stands and a new tier for the mid-p limits (decision 4);
  - the mid-p limits on the Poisson-mean scale depend on the observed count alone, so computing them once per distinct count takes 0.43 s at 3,000 providers, where pprof_py took 62.6 s on the same data (decision 5);
  - a `measure_limits` function in the Cox model's specification could not call the inference layer's Poisson limits under the layer rules, so the plan routes the limits by `count_distribution` instead (decision 3).
- Next step: the project lead's approval of the plan and its §6 decisions; then its §5 commits, starting with §4.1's runs of the unchanged code.
