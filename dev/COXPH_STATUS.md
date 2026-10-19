# CoxPH phase: status

The dated log of the CoxPH phase (`dev/coxph_brief.md`, §0): an entry after each session with material progress, naming the next step. Newest last.

**Status:** Phase C2, the data layer and the stratified Cox model, is closed (2026-10-09) and in `main`. Phase C3, provider profiling for the stratified Cox model, is closed (2026-10-09) and in `main`, with its corner scenario measured on a GitHub runner (run 38004882689). Phase C4, the elastic-net Cox model, is closed (2026-10-14) and in `main`. Phase C5, competing risks, is closed (2026-10-15) and in `main`. Phase C6, documentation and hardening, the phase's last, is closed (2026-10-16) and in `main`: the CoxPH phase is complete (`dev/design/COXPH_FINAL_REVIEW.md`). On 2026-10-19 the project lead, as methodology owner (M-16), signed off its Class B items and questions (DEC-142).

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

## 2026-10-09: Phase C3 built

- The project lead approved the plan with its seven decisions as recommended (DEC-107 to DEC-112), and the plan went to `origin/coxph/phase-3` at `c81603e`.
- The commits, in the plan's §5 order:
  - `0bf2a54`, `7c0fe61`, `4e7f246`: the generator records pprof_py's funnel limits for every Cox case and cause-specific record, and both fixture sets were regenerated (DEC-107); the diff reports (`dev/reference/diff-reports/20261009-cox-funnel-*.md`) show only the added element, and a second generation reproduced the first;
  - `47d50a6`: the C3 calibration (DEC-109), `cox_statistic` as it stands and `cox_root` for the mid-p limits: the report passes 842 of 842 scored rows, and the 4,676 flags at each side's coefficients all agree;
  - `ed6e373`: `R/inference-poisson.R`, the Poisson tests, limits, and funnel limits;
  - `f277829`: the shared hooks, COXPH_DESIGN §D.3 items 3 to 6 as amended by DEC-108;
  - `0aa85c7`: the model's expected events, direct expectations, capabilities, and specification;
  - `21f40dd`: the plots (DEC-112); `1d4d2aa`: the comparisons with the fixtures;
  - `d46e985`, `0962c3b`: the benchmark code and results; `929cd32`: the mid-p limits by bisection; `3ed22dd`: two more tests;
  - the registers and documents (this commit).
- Departures from the plan:
  - the funnel curves are in the full fixture set only: in the core set they took the package tarball to 4,986,258 bytes, 14 KB under the 5 MB at which `R CMD check --as-cran` notes it (DEC-076). The providers' limits, which the tests compare, are in both sets;
  - the plan's commits 6 and 7 are one (`0aa85c7`): the model file holds both, and the profiling tests need both;
  - the mid-p limits' roots: the plan found them with `uniroot()` once per distinct count, which in the benchmarks' first run made the mid-p test with its limits only 8 times faster than pprof_py's at 100 providers, where nearly every provider has a count of its own (DEC-111 asks for ten). The package now bisects over all the distinct counts at once, the fallback the plan's §8 named: the same roots to rounding with the same decisions of 0 and ∞ (`dev/design/coxph-facts/24_midp_bisection.txt`), and 20 to 600 times faster than pprof_py in the second run (DEC-110);
  - two tests the plan implied: unknown IDs in `providers` raise (D-77), and a provider whose rows all have weight 0 is out of the fit and in the measures (its §4.4 list).
- The existing families stayed bitwise identical. `devtools::test()` and `validation/run-reference.R` ran in a clean worktree at the plan's commit and after each commit that touched shared code: at `c81603e` 1,192 tests (9,850 expectations), at `47d50a6` the same, at `ed6e373` 1,202 (9,945), at `f277829` 1,202 (9,947), and at `21f40dd` 1,220 (10,089), each with no failure, warning, or skip; each time the reference report differed from the committed one only in its date and commit lines, and the `data_prepare()` snapshot test passed.
- The benchmarks (`dev/bench/results/cox-c3-paired-20261009-windows.md`; every scenario but the corner, two rounds, the machine paging throughout):
  - every fit's estimates equal its engine call's bitwise;
  - the 10% rule with the measures on both sides (DEC-105, DEC-111): 2 of 21 fits are too slow, providers-7500 with Breslow ties and covariates-5 robust, where C2's run had none. In one process they sit at 1.11 and 1.09 times the comparator, and the center at 0.91 and 0.98 (`dev/design/coxph-facts/25_fit_measures_parts.txt`): the measures cost the fit side 0.011 s more than the engine side at 1,000 providers and 0.044 s more at 7,500, where `standardize_providers()` builds a table of 7,500 providers;
  - the measures beside pprof_py's (the SHOULD, DEC-098): faster at 1,000,000 rows (1.10 s against 1.32 s), about as fast at 100,000 rows with 100 or 1,000 providers, slower at 10,000 rows (0.031 s against 0.009 s) and with 7,500 providers (0.23 s against 0.13 s);
  - the corner scenario remains for the gate (DEC-111).
- Registers: DEC-107 to DEC-112; K-149 and where K-136 to K-147 are in the package; D-77, and the C3 status of D-58, D-63, D-70, D-71, and D-73; M-39 re-decided (DEC-107); NAMING §10, COXPH_DESIGN as built, ARCHITECTURE §E.3 and §E.6, the vignette "Adding a model to pprof", and NEWS.
- Next step: the C3 gate (`/phase-gate C3`), with the corner scenario if at least 4 GB of memory is free.

## 2026-10-09: Phase C3 at its gate

- Delivered on `coxph/phase-3` (brief §4, row C3), `c81603e` to `bcfb0ef`, as the entry above lists: expected counts at the national baseline in closed form, indirect and direct measures, the Poisson exact and mid-p tests with their limits and flags, funnels, plots, and `profile_providers()` for the stratified Cox model, with COXPH_DESIGN §D.3's items 3 to 6 and §D.2's capabilities.
- Gate checks, at `bcfb0ef`:
  - `devtools::document()` changed nothing;
  - `devtools::test()`, in a clean worktree: 77 files, 1,227 tests, 10,878 expectations; none failed or skipped, no warnings or errors (645 s);
  - `R CMD check --as-cran --no-manual`: 0 errors, 0 warnings, the 2 notes of the previous gates (798 s); the tarball is 4,921,651 bytes, under the 5 MB at which the check notes its size;
  - `validation/run-reference.R`, in a clean worktree: 368 of 368 cases, none skipped, no provider within tolerance of a flag threshold; the report equals the committed one but for its date and commit (114 s);
  - the Cox comparisons with the fixtures pass in `devtools::test()`, and `dev/reference/cox/calibrate.R` reproduces the committed calibration report byte for byte (842 of 842 scored rows; 4,676 flags, none differing);
  - `covr::package_coverage()`: 96.52% of the package; of the R lines C3 added (against `main`), 263 of 268 relevant lines, 98.13%, the uncovered ones defensive branches (296 s);
  - `lintr`: the 16 changed package files, the 12 changed test files, the benchmark scripts, and `compare.R` are clean; fact scripts 22 to 25 and C3's additions to `calibrate.R` keep the fact scripts' style (`<<-`, names such as `O` and `E`, a few long lines);
  - the benchmarks: `dev/bench/results/cox-c3-paired-20261009-windows.md`, as the entry above sums it up.
- The corner scenario could not be measured: at the gate 1.5 GB of the machine's 7.4 GB was free, with 18 GB committed by the open applications, against the 4 GB that DEC-111 asks for.
- Open for the project lead: the corner scenario, by one of DEC-111's ways; the two fits too slow by DEC-105's rule, at its line; the measures slower than pprof_py's at 10,000 rows and with 7,500 providers (a SHOULD); the push of the branch.
- Next step: the project lead's review of the C3 gate.

## 2026-10-09: the C3 gate closed

- The project lead approved closing the C3 gate, and on the open items:
  - the two fits too slow by DEC-105's rule, at its line, are accepted for C3 and measured again alongside the corner scenario (DEC-111);
  - the corner scenario is measured on a GitHub-hosted runner with 16 GB of memory: `.github/workflows/cox-bench.yaml`, dispatched by hand, runs `dev/bench/cox/run_paired.R` on the corner and those two fits (by default; its `only` input selects others) and uploads the CSV, the report, and the log; `dev/bench/cox/summarize_paired.R --notices` repeats the verdicts as notices, which `dev/tools/ci_runs.R` reads without signing in;
  - `coxph/phase-3` goes to the fork, and the fork's `main` takes it as a fast-forward.
- The job is on `coxph/phase-3` before the push, so that it reaches `main` with the merge: GitHub dispatches a manual workflow only from the default branch.
- Next step: the project lead dispatches `cox-bench` from the fork's Actions page; its results go to `dev/bench/results/` and this document. Phase C4, penalized Cox models, when the project lead asks.

## 2026-10-09: the corner scenario on a GitHub runner

Recorded on 2026-10-14, for the next session.

- The first dispatch of `cox-bench` (run 38003811342) failed while installing its dependencies ("cannot open the connection"), with the CRAN snapshot in `~/.Rprofile`, a setup copied from `rewrite-bench.yaml`, which has never run. At the project lead's request `main` took the fix as a fast-forward (`54488ae`): the job installs current binaries and the package's hard dependencies, as `rewrite-check.yaml`'s job with R 4.4.0 on the same image does, and reports a failed installation or measurement in annotations. `rewrite-bench.yaml` keeps the old setup.
- CI on `171b1b4` (`coxph/phase-3` and `main`) and on `54488ae` (`main`): every workflow passed.
- The second dispatch (run 38004882689; 28 minutes on an AMD EPYC 9V74 runner with 4 processors; R 4.4.0, survival 3.8-12), read from its notices:
  - no fit too slow by DEC-105's rule, and every fit's estimates equal its engine call's: the corner's Breslow, Efron, and robust fits at 1.02 to 1.05 times the engine call plus the preparation (medians and fastest runs, both rounds); covariates-5 robust at 1.01 to 1.04; providers-7500 with Breslow ties at medians of 1.45 and 1.46 but fastest runs of 1.11 and 1.09, so it passes by one round's fastest run and stays at the line;
  - the corner's mid-p test with its limits took 0.236 s, and the expected events 0.217 s, against pprof_py's 116 s in C1 on the project lead's machine: 256 times faster;
  - the run's CSV, JSON, report, and notes, from its artifact `cox-bench-results`, which the project lead downloaded, are `dev/bench/results/cox-c3-corner-20261009-linux.*`; the report regenerates from the CSV here byte for byte.
- `CLAUDE.md`'s "Current phase" section, which still named Phase C0, now names Phase C4 (the project lead, 2026-10-14).
- Open, outside the next phase unless the project lead says otherwise: the fits' overhead at 7,500 providers (DEC-105's alternative 3) and the measures' time at 10,000 rows and 7,500 providers (a SHOULD of the brief's §3.7); `rewrite-bench.yaml`'s setup.
- Next step: Phase C4, the elastic-net Cox model (the brief's §4, row C4), when the project lead asks: its plan first, `dev/design/COXPH_C4_PLAN.md`, for approval, on `coxph/phase-4` from `main`.

## 2026-10-14: the C4 plan

- The project lead asked for Phase C4. Branch `coxph/phase-4`, from `main` at `38dad40`.
- The plan, `dev/design/COXPH_C4_PLAN.md`, for the project lead's approval, with the evidence behind it in `dev/design/coxph-facts/26` to `28`. Found while planning:
  - pprof_py's λ grid comes from engine calls: `glmnet`'s exported `coxgrad()` gives the score at the null point, and survival's fitter the unpenalized coefficients at pprof_py's settings. They reproduce pprof_py's λ_max within 9e-15 on every penalized fixture case and on eight settings the fixtures lack, and `glmnet`'s paths on that grid agree with pprof_py's within 0.213 units of `penalized_path`;
  - `glmnet` refuses a single covariate, and a column of zeros beside it reproduces pprof_py's path. A constant column must be left out before the call: passed through, `glmnet`'s rescaling of the penalty factors puts the path 1e4 units off;
  - on 15 rows with 8 events and 20 covariates, `glmnet` stops at its iteration limit with Breslow ties, and with Efron ties it diverges at the 55th grid point without a warning (coefficients near 1e36), where pprof_py converges at every point. The plan proposes D-78;
  - the cross-validation computed from survival's fitter reproduces the generator's R side bitwise. One `coxnet.deviance()` call per fold over every grid point, moved to pprof_py's saturated term, agrees with it within 3.2e-13 and makes a 10-fold cross-validation on `covariates-50` about 1.6 times faster: 211 s estimated, against pprof_py's 1,717 s in C1;
  - `cox-bench.yaml` installs only the package's hard dependencies, so the penalized tasks need `glmnet` added to the job.
- Next step: the project lead's approval of the plan and its §6 decisions; then its §5 commits, starting with §4.1's runs of the unchanged code.

## 2026-10-14: Phase C4 built

- The project lead approved the plan with its eight decisions as recommended (DEC-113 to DEC-120).
- The commits, in the plan's §5 order:
  - `496367b`: the plan, with fact scripts 26 to 28 and their outputs;
  - `9932fed`, `087d5f8`: the generator's two penalized cases, `penalized-settings` and `penalized-few-events`, and both fixture sets regenerated (DEC-117); the diff reports (`dev/reference/diff-reports/20261014-cox-penalized-*.md`) show the core set's 7 cases identical and the full set's 13 identical with the 2 added, and a second generation reproduced every file;
  - `ee4d672`: the C4 calibration rows (DEC-116): the report passes 954 of 954 scored rows, 60 explained, the grid rows within 2.1e-5 of `closed_form` and their negative controls beyond 5e8;
  - `250247c`: the glmnet adapter (`R/model-glmnet.R`), survival's partial log-likelihood of given linear predictors and fit of given columns (`R/model-survival.R`), the constants, and the warning for degenerate covariates;
  - `4abced4`: `fit_cox_penalized()`, `select_lambda()`, the object, and its methods;
  - `f336a20`: the comparisons with the fixtures;
  - `ff79b18`, `0bbca18`: the benchmark code, and its results with facts 29 and 30;
  - the registers and documents (this commit).
- Departures from the plan:
  - the plan's commits 5 and 6 are one (`4abced4`): the object's validator and methods cover the selection that `select_lambda()` fills, and the tests of each use the other;
  - `R/model-survival.R` gained `survival_fit_columns()` besides `survival_partial_loglik()`, the fit of the unpenalized columns at the start of the path (decision 1), and its input builder was split so that the three share it;
  - a test helper, `tests/testthat/helper-cox-penalized.R`, holds the data, formulas, and direct `glmnet` calls that the adapter, model, and selection tests share;
  - the metamorphic test of duplicated rows against weight 2 compares under `penalized_path`, not `closed_form`: `glmnet` converges differently on the two data, by 1.5e-6 (DEC-116), as for covariate order;
  - `alpha`, `ties`, and `standardize` are in the model's `spec`, where COXPH_DESIGN §B.2 listed them as fields, and `cvm` and `cvsd` keep glmnet's and pprof_py's names (DEC-120, NAMING §2);
  - the benchmark's code and results are two commits, as in C3.
- The existing families and the stratified Cox model stayed bitwise identical. `devtools::test()` and `validation/run-reference.R` ran in a clean worktree at `38dad40` and after each commit that touched shared code: at `38dad40` 77 files, 1,227 tests (10,878 expectations); at `250247c` 78 files, 1,235 tests (10,978); at `4abced4` 80 files, 1,254 tests (11,133); each with no failure, warning, or skip. Each time the reference report differed from the committed one only in its date and commit lines (368 of 368 cases), and the `data_prepare()` snapshot test passed.
- Against pprof_py and glmnet:
  - the adapter's paths equal `glmnet()`'s called directly with the same inputs, bitwise, in 12 configurations: both tie methods, each with (start, stop] data with weights and an offset, right-censored data without them, the elastic net with unequal and zero penalty factors, ridge without standardization, a column left out, and one covariate;
  - λ_max is within 9e-15 of pprof_py's on every penalized case and setting, and the paths within 0.213 units of `penalized_path`;
  - with pprof_py's fold IDs, cvm is within 0.128 units and cvsd within 0.018, λ_min and λ_1se are the same, and the fold deviances are within 3.2e-13 of the generator's R side;
  - on the few-events case (D-78) the path ends at the 72nd grid point (Breslow) or the 54th (Efron), with the warning, and agrees with pprof_py's to the 30th.
- The benchmarks (`dev/bench/results/cox-c4-paired-20261014-windows.md`; two rounds, the machine paging throughout):
  - every result equals its engine side's bitwise, and no fit is too slow by DEC-105's rule;
  - on covariates-50 the path's medians sat at 1.14 times the comparator in both rounds (fastest runs 0.99 and 1.12) and the cross-validation's at 0.85 and 1.15, one run a round. In one process the path takes 0.97 times its comparator (1.03 on rows-1e4) and `select_lambda()` 1.075 (fact 29), and its loop, part by part and fold by fold, 0.998 times the plain-R loop's: the folds' column scales cost 4.2 s in all, about 2% of the cross-validation, and identical glmnet fold paths vary by up to 2.2 s from run to run (fact 30);
  - beside C1's pprof_py times, the path is 4.5 times faster (19.9 s against 89.9 s), and the path with its cross-validation 9.3 times faster (about 185 s against 1,717 s).
- Registers: DEC-113 to DEC-120, with DEC-088's and DEC-097's status; where K-143 and K-144 are in the package; D-78 and D-79, and the C4 status of D-58, D-61, D-67, and D-72; M-30, M-34, and M-37 implemented; NAMING §2 and §10, COXPH_DESIGN as built, ARCHITECTURE §E.3 and §E.6, and NEWS.
- Next step: the C4 gate (`/phase-gate C4`).

## 2026-10-14: Phase C4 at its gate

- Delivered on `coxph/phase-4` (brief §4, row C4), `496367b` to `0da9ac3`, as the entry above lists: the glmnet adapter, the elastic-net Cox path on pprof_py's λ grid, its cross-validation and the selection of λ, and the model's capabilities, none, since there is no provider profiling at a selected λ (M-34).
- Since the entry above: `4d42427` wraps a long line of the adapter's tests, and `0da9ac3` adds tests of the fit's early end (DEC-115, D-78) with glmnet mocked, which until then ran only in the full fixture set's tests that CRAN and covr skip, and of the input errors, the validator's checks, and the printed path. D-78's regression tests name the new one.
- Gate checks:
  - `devtools::document()` changed nothing;
  - `devtools::test()`, in a clean worktree: at `0da9ac3` 81 files, 1,259 tests, 11,521 expectations, none failed or skipped, no warnings or errors (2,052 s, beside the coverage run); at `2ce196d` 1,257 tests (11,497 expectations), likewise;
  - `R CMD check --as-cran --no-manual` at `0da9ac3`, run alone: 0 errors, 0 warnings, the 2 notes of the previous gates (966 s); the tarball is 4,953,987 bytes, under the 5 MB at which the check notes its size. At `2ce196d`, run beside the test suite, it added a third note, the `caterpillar_plot()` example's 5.14 s elapsed against a 5 s limit, an example C4 did not touch, which the same check's second run of the examples timed at 2.36 s and the run alone at 2.49 s;
  - `validation/run-reference.R`, in a clean worktree at `2ce196d` and at `0da9ac3`: 368 of 368 cases, none skipped, no provider within tolerance of a flag threshold; the report equals the committed one but for its date and commit;
  - the Cox comparisons with the fixtures pass in `devtools::test()`, and `dev/reference/cox/calibrate.R` reproduces the committed calibration report byte for byte (954 of 954 scored rows, 60 explained; 4,676 flags, none differing; 29 s);
  - `covr::package_coverage()` at `0da9ac3`: 96.67% of the package; of the R lines C4 added (against `main`), 395 of 401 relevant lines, 98.50%. The uncovered ones are defensive: the warning when the unpenalized fit at the start of the path does not converge in 100 iterations, the grid of a λ_max of exactly 0, the validator's check for provider effects, and the saturated term of rows without events. At `2ce196d` the added lines were at 92.02%, the fit's early end among the uncovered, which `0da9ac3`'s tests cover;
  - `lintr`: the 8 changed package files, the 6 changed test files, and the benchmark scripts are clean; fact scripts 26 to 30 and C4's additions to the generator's `survival.R` and to `calibrate.R` keep their style (`<<-`, a few long lines), as at the C3 gate;
  - the benchmarks: `dev/bench/results/cox-c4-paired-20261014-windows.md`, as the entry above sums it up.
- Open for the project lead: D-78, decided with the plan, awaits a methodology owner's confirmation (M-16), as the delegated C0 decisions do; `cox-bench.yaml` runs the penalized tasks on a GitHub runner when dispatched from `main`, so after the merge; the push of the branch.
- Next step: the project lead's review of the C4 gate.

## 2026-10-14: the C4 gate closed

- The project lead approved closing the C4 gate and asked for the work in `main`: `coxph/phase-4` goes to the fork, and the fork's `main` takes it as a fast-forward from `38dad40`.
- With the merge, `cox-bench.yaml` in `main` runs the penalized tasks by default when the project lead dispatches it (DEC-118); its corner run takes `only` = "^corner |^providers-7500 breslow$|^covariates-5 robust$".
- CI on `d2b6567`, on `main` and on `coxph/phase-4`: every workflow passed (`rewrite-check`, `rewrite-reference`, `rewrite-coverage`, `rewrite-lint`, and `rewrite-pkgdown`; `main`'s runs 38615447409 to 38615447785).
- At the project lead's request, the branches that `main` contains, `coxph/phase-3`, `coxph/phase-4`, and the local `coxph/cox-bench`, were deleted, locally and on the fork.
- Open, as at the gate: D-78 awaits a methodology owner's confirmation (M-16), with the decisions taken under delegation in C0; outside C4, the fits' overhead at 7,500 providers, the measures' time at 10,000 rows and 7,500 providers, and `rewrite-bench.yaml`'s setup. `CLAUDE.md`'s "Current phase" section, which still named Phase C4, now names Phase C5 (the project lead, 2026-10-14).
- Next step: Phase C5, competing risks (the brief's §4, row C5), when the project lead asks: its plan first, `dev/design/COXPH_C5_PLAN.md`, for approval, on `coxph/phase-5` from `main`.

## 2026-10-14: the C5 plan

- The project lead asked for Phase C5. Branch `coxph/phase-5`, from `main` at `4c7b028`.
- The plan, `dev/design/COXPH_C5_PLAN.md`, for the project lead's approval, with the evidence behind it in `dev/design/coxph-facts/31` to `35`. Found while planning:
  - survival 3.8-12's `finegray()` applies case weights to the wrong rows in every stratum after the first (`user.weights[split$row]`, where `split$row` counts the stratum's rows): the plan multiplies the weights after the call, as K-145 and pprof_py define them;
  - `finegray()`'s time grows with rows times providers, in survival's per-stratum steps: on 100,000 rows it takes 24 s with 1,000 providers, where pprof_py's whole fit takes 5.3 s, and 110 to 180 s with 7,500. Calls on chunks of 50 providers, each deciding delayed entry as all rows do, give its output bitwise in 3 to 14 times less time; calls on single providers can differ, since `finegray()` decides delayed entry over all rows;
  - with delayed entry and small providers the Fine–Gray weights can be undefined: survival gives NaN or infinite weights where pprof_py raises, and pprof_py also raises where survival's weights are all finite (the plan's D-80);
  - survival's fitter and the robust step on the expansion give `coxph(cluster = id)`'s fit bitwise in all 16 fixture configurations and reproduce the fixtures' survival records exactly; against pprof_py the differences are D-56's and D-57's;
  - a status with several event types must be a factor, and pprof_py rejects a repeated `id` on right-censored data and a subject that changes provider, which survival accepts.
- Next step: the project lead's approval of the plan and its §6 decisions; then its §5 commits, starting with §4.1's runs of the unchanged code.

## 2026-10-15: Phase C5 built

- The project lead approved the plan with its nine decisions as recommended (DEC-121 to DEC-129).
- The commits, in the plan's §5 order:
  - `cd377ed`: the plan, with fact scripts 31 to 35 and their outputs;
  - `76fabac`, `819eed4`: the generator's weighted competing-risk case, `competing-weights`, and both fixture sets regenerated (DEC-126); the diff reports (`dev/reference/diff-reports/20261015-cox-competing-weights-*.md`) show the core set's 7 cases identical and the full set's 15 identical with the new one added, and a second generation reproduced every file;
  - `c671786`: the C5 calibration rows (DEC-125): the report passes 1,058 of 1,058 scored rows, 84 explained, the Fine–Gray log-likelihoods within 0.0018 units of `cox_function` and their negative controls beyond 2.6e8;
  - `c5f1cc9`: the competing-risks response in the data layer;
  - `69673b0`: the Cox reference tests refit the full set's competing-risk records with their weights (below);
  - `07aff5b`: the Fine–Gray adapter, in the survival adapter;
  - `3b143f7`: `fit_fine_gray()`, its object, and its methods;
  - `ef63ce4`: the comparisons with the fixtures;
  - `8558c91`: the cause-specific models' tests;
  - `f843da1`, `4af4463`, `5e74c81`: the benchmark code, a wording fix of its report, and its results;
  - `3904480`: the comparisons name every Efron Fine–Gray record of the weighted case that D-58 moves;
  - the registers and documents (this commit).
- Departures from the plan:
  - the checks after `c5f1cc9` found 16 failing expectations in "measures and flags of the package's fits, full Cox fixtures (D-58, M-29)": the profiling tests refit every competing-risk record of the full set, and their refits left out the weights that pprof_py's fits of the new case took. The data layer was not the cause. `69673b0` refits with the case's weights and marks per record where D-58 applies; no other expectation changed;
  - `fit_cox_stratified()`'s help gained its competing-risks paragraph and example with `fit_fine_gray()` (`3b143f7`), not with the cause-specific tests (the plan's commit 8); `data_prepare()`'s help, regenerated there, gained the competing-risks response of `c5f1cc9`;
  - a test helper, `tests/testthat/helper-cox-fine-gray.R`, holds the data and the direct survival calls that the adapter and model tests share, as C4's `helper-cox-penalized.R` does;
  - the benchmark's engine side builds the fitter's inputs from the expansion within its timed call, since the expansion comes from that call; the preparation timed apart is `data_prepare()` and the chunks' data frames. The plan listed the fitter's inputs with the preparation; the rule compares the fit with their sum, which does not change. `run_paired.R` also writes the list of scenarios that `run_pprof_py.py` reads, and `summarize_paired.R` takes C5's pprof_py run with `--pprof-py` and reads runs whose columns differ;
  - `3904480`, after the benchmark code: the comparison test asserted D-58's difference for the weighted case's Efron fits of cause 1 only; the calibration report shows the unstratified fit of cause 2 moved too, and the stratified fit of cause 2 equal to pprof_py's, which the test now asserts.
- The existing families and the stratified and elastic-net Cox models stayed bitwise identical. `devtools::test()` and `validation/run-reference.R` ran in a clean worktree at `4c7b028` and after each commit marked (S): at `4c7b028` 81 files, 1,259 tests (11,521 expectations); at `c5f1cc9` 81 files, 1,264 tests, with the 16 failures above; at `07aff5b` 81 files, 1,273 tests (11,788); at `3b143f7` 82 files, 1,288 tests (11,952); at `3904480` 83 files, 1,301 tests (12,610); otherwise with no failure, warning, or skip. Each time the reference report differed from the committed one only in its date and commit lines (368 of 368 cases), and the `data_prepare()` snapshot test passed.
- Against survival and pprof_py:
  - the transform equals one stratified `finegray()` call's expansion bitwise in chunks of any size, with fact 31's counterexample to calls per provider among the cases; the fit equals `coxph(cluster = id)` on that expansion bitwise, with both tie methods, and the cumulative incidence 1 − `survfit()`'s survival;
  - on every Fine–Gray record of the three competing-risk cases (each cause, both tie methods, stratified and not), the expansion's rows and status equal pprof_py's and its times and weights lie within `closed_form`; iteration counts are equal; tight coefficients lie within `cox_coefficient` and default ones within the last Newton step; model-based variances, Efron robust variances, and log-likelihoods within their tiers; and the cumulative incidence within `cox_baseline`. The exceptions are those the calibration explains, where the fits equal survival's records: D-56 (the robust variances with Breslow ties), D-57 (three records whose last step pprof_py halved), and D-58 (the weighted case's Efron fits of cause 1, and of cause 2 without strata);
  - the cause-specific fits of the three cases equal `coxph()`'s on the same rows bitwise, default and tight, with pprof_py's iteration counts, and its tight fits within the tiers, except the weighted case's Efron fit of cause 1 (D-58);
  - on the D-80 example, pprof_py's transform raises where the package raises and where it fits (run 2026-10-15).
- The benchmarks (`dev/bench/results/cox-c5-paired-20261015-windows.md`; two rounds, the machine paging throughout):
  - every fit's coefficients and robust variance equal its survival calls' bitwise, and so do those of the user's calls, one stratified `finegray()` followed by `coxph(cluster = subject)`;
  - no fit is too slow by DEC-105's rule: the fit takes 0.84 to 1.04 times its survival calls plus their preparation (medians; fastest runs 0.78 to 1.00), and the user's calls four to five times the fit's time (44 s against 10.5 s on center);
  - beside pprof_py's `FineGrayPH` on numba's 8 threads, the fit takes 2.8 times its time on center (10.5 s against 3.8 s) and 2.5 times with every entry at 0 (8.0 s against 3.3 s): the brief's SHOULD is not met, as the plan expected (DEC-098, DEC-122). pprof_py raises on covariates-5 (D-80), where the fit takes about 7.2 s;
  - providers-100 (`fine_gray`) and providers-7500 (`fine_gray_right`) wait for `cox-bench.yaml`, which the project lead dispatches; pprof_py's time on providers-7500 with every entry at 0, 5.0 s, is in `cox-c5-pprof_py-20261015-windows.csv`.
- Registers: DEC-121 to DEC-129, with DEC-098's status; where K-145 and K-146 are in the package, with survival's case-weight defect; D-80 and D-81, and the C5 status of D-56, D-57, D-58, and D-74; M-35 and M-41 implemented, and M-23 and M-25 applied to the transform; NAMING §10, COXPH_DESIGN as built, ARCHITECTURE §E.3 and §E.6, NEWS, and the plan's status line.
- Next step: the C5 gate (`/phase-gate C5`).

## 2026-10-15: Phase C5 at its gate

- Delivered on `coxph/phase-5` (brief §4, row C5), `cd377ed` to `c1bcec9`, as the entry above lists: cause-specific models, `fit_cox_stratified()` with the event of interest written in `Surv()`, with their tests, help, and profiling (DEC-129); and the Fine–Gray model, `fit_fine_gray()`, stratified by provider, with the cumulative incidence of `predict()` and coefficient inference on the robust variance (DEC-121 to DEC-128).
- Since the entry above: `c1bcec9` adds two tests of the plan's cases that the gate's coverage run found missing: chunks of providers without events of the cause (§4.3), and covariates the fit cannot estimate (§4.4; M-26, D-59).
- Gate checks:
  - `devtools::document()` changed nothing;
  - `devtools::test()`, in a clean worktree: at `27d1ba1` 83 files, 1,301 tests, 12,610 expectations; at `c1bcec9` 83 files, 1,303 tests, 12,619 expectations (617 s); none failed or skipped, no warnings or errors;
  - `R CMD check --as-cran --no-manual` at `c1bcec9`, run alone: 0 errors, 0 warnings, the 2 notes of the previous gates (868 s); the tarball is 4,977,843 bytes, 22 KB under the 5 MB at which the check notes its size;
  - `validation/run-reference.R`, in a clean worktree at `27d1ba1` and at `c1bcec9`: 368 of 368 cases, none skipped, no provider within tolerance of a flag threshold; the report equals the committed one but for its date and commit;
  - the Cox comparisons with the fixtures pass in `devtools::test()`, and `dev/reference/cox/calibrate.R` reproduces the committed calibration report byte for byte (1,058 of 1,058 scored rows, 84 explained; 4,724 flags, none differing; 14 s);
  - `covr::package_coverage()` at `c1bcec9`: 96.72% of the package; of the R lines C5 added (against `main`), 344 of 353 relevant lines, 97.45%. The uncovered ones: the validator's checks of five fields, the error for covariates that are not finite, the error for `data` whose refit differs from the model (other data fail earlier, when checked against the model), the multi-state check of `data_survival_response()`, which `data_prepare()`'s own check makes unreachable, and the codes of an `id` that is a factor (as the stratified model's untested branch for a factor `cluster`). At `27d1ba1` the added lines were at 96.03%, the two cases `c1bcec9` tests among the uncovered;
  - `lintr`: the 10 changed package files, the 9 changed test files, and the 3 benchmark scripts are clean; fact scripts 31 to 35 keep their style (`<<-`, long lines, a few semicolons), and C5's additions to the generator's `survival.R` and to `calibrate.R` are clean, the lints of those files being older;
  - the benchmarks: `dev/bench/results/cox-c5-paired-20261015-windows.md`, as the entry above sums it up.
- Open for the project lead: the push of the branch; `cox-bench.yaml`'s Fine–Gray tasks on providers-100 and providers-7500, which run when the project lead dispatches it; telling survival's maintainers of `finegray()`'s case-weight defect and of its cost with many strata, an action outside the fork. D-78 still awaits a methodology owner's confirmation (M-16), with the decisions taken under delegation in C0, among them D-56 to D-58, which C5 applies to the Fine–Gray model.
- Next step: the project lead's review of the C5 gate.

## 2026-10-15: the C5 gate closed

- The project lead approved closing the C5 gate and asked for the work in `main`: `coxph/phase-5` goes to the fork, and the fork's `main` takes it as a fast-forward from `4c7b028`.
- With the merge, `cox-bench.yaml` in `main` runs the Fine–Gray tasks by default when the project lead dispatches it (DEC-127): `fine_gray` on center, covariates-5, and providers-100, and `fine_gray_right` on center and providers-7500. The penalized tasks take `only` = " penalized", and the corner run "^corner |^providers-7500 breslow$|^covariates-5 robust$".
- Open, as at the gate: D-78 awaits a methodology owner's confirmation (M-16), with the decisions taken under delegation in C0; the codes of an `id` (Fine–Gray) or a `cluster` (stratified model) that is a factor are untested; the package's tarball is 22 KB under the 5 MB at which `R CMD check` notes its size; telling survival's maintainers of `finegray()`'s case-weight defect and of its cost with many strata is the project lead's to take or ask for; and, from C4, the fits' overhead at 7,500 providers, the measures' time at 10,000 rows and 7,500 providers, and `rewrite-bench.yaml`'s setup. `CLAUDE.md`'s "Current phase" section still names Phase C5 as next; it changes with the project lead's approval.
- Next step: Phase C6, documentation and hardening (the brief's §4, row C6), when the project lead asks: its plan first, `dev/design/COXPH_C6_PLAN.md`, for approval, on `coxph/phase-6` from `main`.

## 2026-10-16: the C6 plan

- The project lead asked for Phase C6 on 2026-10-15. Branch `coxph/phase-6`, from `main` at `8023d8f`; `CLAUDE.md`'s "Current phase" section names Phase C6 (`a919c0b`, the project lead's approval in the request).
- CI on `8023d8f`, the C5 merge: every workflow passed on `main` (`rewrite-check` 38802825847, `rewrite-reference` 38802825883, `rewrite-coverage` 38802825917, `rewrite-lint` 38802825882, `rewrite-pkgdown` 38802825926) and on `coxph/phase-5`, read through the public API (`dev/tools/ci_runs.R`).
- The plan, `dev/design/COXPH_C6_PLAN.md`, for the project lead's approval, with the evidence behind it in `dev/design/coxph-facts/36` to `39`. Found while planning:
  - the tarball is 22,842 bytes under the 5,000,000 at which `R CMD check --as-cran` notes its size, and the vignette and the Cox sections of the methods vignette need about 65 KB; the bundled data resaved with xz free 48,217 bytes, their objects `identical()`;
  - the vignette's computations, on data derived from `ExampleDataBinary`, take 2.8 s, and its stratified fit is `identical()` to `coxph(ties = "breslow", timefix = FALSE)`'s; the five vignettes' rebuild under `R CMD check` takes 38 s;
  - CI never runs the full Cox fixture set: it checks the built tarball, without `validation/`, with `NOT_CRAN` unset;
  - of 72 invalid calls to the Cox functions, 66 raise pprof's classed conditions and 4 R's own errors, which every family shares; `fit_fine_gray()` names `cluster` for a missing `id` column, and profiling a penalized fit names the internal `profile_spec()`;
  - the examples of `fit_cox_penalized()` and `select_lambda()` take 1.1 to 1.2 s, above DEC-068's 1 s;
  - in a simulation with provider strata (100 replicates per scenario), the mid-p test flags 4.9% and the exact test 3.9% of providers without an effect, and with small providers 4.7% and 3.1%;
  - fact 35 was missing from the facts README; its row and command are added.
- A stray `build.log` that the session's first build attempt wrote into the repository's root was in the planning tarballs (a third note in their check) and was deleted; it was never committed.
- Next step: the project lead's approval of the plan and its §6 decisions; then its §5 commits, starting with §4.1's runs of the unchanged code.

## 2026-10-16: Phase C6 to the wording check-in

- The project lead approved the plan and its eleven decisions as recommended (DEC-130 to DEC-140, recorded with the registers in the plan's commit 14). Commits 2 to 9 of its §5, on `coxph/phase-6`, not pushed:
  - `2f26c8c` tests: factor clusters and subjects against `coxph()` and the direct Fine–Gray fit, bitwise, with an unused level; the validators' checks, covariates that are not finite, refits whose data differ, and the other reachable lines of the plan's §2.7. `991e310` tools: `dev/tools/namespace_compare.R` and `dev/tools/coverage_added.R`; the coverage of the R lines added since `ea7c07b` was 97.49% at `1a47062` (1,595 of 1,636; the package 96.88%).
  - `6df2b54` model: `fit_fine_gray()` names `id` when its column is missing; profiling a penalized fit names the capability it lacks, through the model's family specification without profiling hooks; invalid times are counted as "1 row is not" or "N rows are not". Each with a regression test.
  - `266bb38` data: the bundled data resaved with xz (DEC-131), the objects `identical()`.
  - `9c0a6a3` validation: the Cox model in the simulation study (DEC-134). At level 0.95 the mid-p test flags 4.6% to 4.8% of the providers without an effect and the exact test 3.4% to 4.0%, small providers included; at log hazard ratios of ±0.5 they flag 85.2% and 83.0% of the outlying providers; the indirect ratios' intervals cover 95.2% to 95.4% (mid-p) and 96.0% to 96.5% (exact) of the null providers' ratios. The existing families' rows are unchanged. The run took 5,050 s instead of about 35 minutes: the machine paged heavily under other applications.
  - `3481a02` validation: the final Cox equivalence report (DEC-135). One helper for the four Cox reference files, each file's expectations unchanged (512, 224, 364, and 2,008); `validation/run-cox-reference.R` and its report: 1,893 comparisons, 1,867 within their tier (the largest ratio 0.995, `tiny-ties` Breslow coefficients), 26 explained by D-56, D-58, and M-23, none failing.
  - `0a64fa9` ci: `rewrite-reference.yaml` runs the Cox comparisons on the fixtures' platform and on Linux, macOS, and Windows; `rewrite-bench.yaml` takes that workflow's Linux setup (DEC-137). Neither has run: the branch is not pushed.
  - `6e966cf` docs: the vignette "Profiling providers with time-to-event outcomes" (DEC-130). `fd17f8e` docs: the Cox models in "Models and what they support", "Statistical methods", "Getting started", the README, `?pprof`, and DESCRIPTION, with the wording list `dev/design/COXPH_C6_WORDING.md`. `5976ede` docs: the vignettes' plots at 72 dpi, DEC-131's first fallback, since `fd17f8e`'s tarball was 670 bytes over 5,000,000.
- Checks of the code commits, in the verification worktree after each of commits 2 to 4: `devtools::test()` with no failure (1,317 tests and 12,680 expectations at `2f26c8c`; 1,320 and 12,696 at `6df2b54` and `266bb38`), the `data_prepare()` snapshot among them; `validation/run-reference.R` with 368 of 368 cases, its report differing from the committed one only in its date and commit lines. The namespace from `a919c0b` to the working tree at `5976ede`: `fit_fine_gray()` and `data_check_survival_values()` changed and `profile_spec.pprof_cox_penalized()` added, as expected, and nothing else; exports, data, and C++ unchanged. `dev/reference/cox/calibrate.R` reproduces `validation/cox-calibration-report.md` byte for byte, with pprof_spark's files at `e917a68`.
- Checks of the documentation commits, at each commit: `devtools::document()` leaves the generated files as committed; `R CMD check --as-cran --no-manual`, run alone, gives 0 errors and 0 warnings. Its notes at `5976ede` are the two of the earlier gates, the website's address (404) and "unable to verify current time". The tarball is 4,978,069 bytes at `6e966cf`, 5,000,670 at `fd17f8e` (its size then added to the CRAN incoming note), and 4,975,472 at `5976ede`, 24,528 under. The checks of `6e966cf` and `fd17f8e` also noted `.git`, which in the worktree is a file that `R CMD build` keeps; built from the commit's export it is gone. The vignettes rebuild in 35 to 46 s; their code, sourced with the installed package three times, takes 4.1 s for the new vignette and 25.7 s for all six (DEC-132: 10 s and 40 s).
- In the working tree, not committed, for after the check-in: the help of `plot_volume()` (DEC-133) and `profile_providers()`; the developer guide's "Delegated engines" and "The later models"; ARCHITECTURE §E.6 as built and §E.7; and "Adding a model to pprof"'s section on delegating estimation, whose `glm()` example gives estimates `identical()` to a direct call, with the Cox column of its specification table. The guide's dry run (the plan's §3.5): a subagent without the session's context designed frailty Cox profiling and discrete-time provider models from the three documents and found 19 gaps, 3 of them blocking (whether rule 3 covers the measures' Breslow baseline, which is the package's own; models fitted to expanded rows; what validation stands in without an external reference). The fixes go into the plan's commit 11, with the report as fact 40.
- Next step: the project lead's decision on the wording (DEC-139), on the drafts of commits 8 and 9 and `dev/design/COXPH_C6_WORDING.md`. Then commits 10 to 14. CI on the branch, and the dispatches of `cox-bench.yaml`, `rewrite-bench.yaml`, and `rhub.yaml` (`nold`), need the branch pushed to the fork, which waits for the project lead's permission.

## 2026-10-16: Phase C6 at its gate

- After the check-in the project lead approved the wording list as it stood (DEC-139) and asked for `coxph/phase-6` to be merged into `main` and pushed: `main` was fast-forwarded to `f1c8414` and pushed to the fork with the branch (origin only); the branch's later commits were pushed at the project lead's request, `main` not again.
- Commits since the check-in: `c0ae91d` (the help pages: `plot_volume()`'s volume, `profile_providers()`, the penalized examples at 0.40 s and 0.55 s); `de6a5e5` (the Cox report names failing tests, in its report and in annotations); `976836c` (the developer guide's "Delegated engines" and "The later models", ARCHITECTURE §E.6 and §E.7, "Adding a model to pprof"'s delegated `glm()` example, with the dry run's fixes and its report as fact 40); `085eaeb` (DEC-141); `4effe06` (the runner's last Cox run and the final benchmark report); `e772ce4` (NEWS and `cran-comments.md`); `34759de` (the final review, DEC-130 to DEC-141, COXPH_DESIGN as built).
- CI. At `f1c8414` every workflow passed but `rewrite-reference`, whose new Cox comparisons failed no comparison on any platform but two tests on macOS (R 4.5.3, arm64): the cross-validation's held-out weights of `penalized-combined`, sums of non-integer case weights that R's `sum()` accumulates in long double on x86_64 and in double on arm64, one unit in the last place apart. The project lead chose to compare them at `closed_form` (DEC-141); at `085eaeb` every platform passes (run 38954075826: 1,897 comparisons, none failing). `rewrite-sanitizers` runs on pull requests only and has not run on this phase's pushes.
- The project lead's dispatches: `cox-bench.yaml` with its default selection, the Fine–Gray tasks, on the branch at `085eaeb` (run 38957683403) and on `main` at `f1c8414` (run 38952307742): 5 fits, none too slow by DEC-105's rule, estimates equal to the survival calls' bitwise; and `rewrite-reference.yaml` (run 38957603497, passed). `rewrite-bench.yaml` has not run (DEC-137). The CRAN submission, and R-hub's check without long double with it, are deferred by the project lead (2026-10-16).
- Gate checks, at `e772ce4`, whose package `34759de` leaves unchanged, in the verification worktree:
  - `devtools::document()`: no generated file changed;
  - `devtools::test()`: 83 files, 1,320 tests, 12,696 expectations, none failed, errored, skipped, or warning (506 s);
  - `R CMD check --as-cran --no-manual` on a clean export of the commit, run alone: 0 errors, 0 warnings, the 2 notes of the previous gates (the website's address, 404, and "unable to verify current time"); the tarball is 4,982,796 bytes, 17,204 under the 5,000,000 at which the check notes its size; the vignettes rebuild in 35 s;
  - `validation/run-reference.R`: 368 of 368 cases, none skipped, no provider within tolerance of a flag threshold; the report equals the committed one but for its date and commit (133 s);
  - `validation/run-cox-reference.R`: 1,897 comparisons, 1,871 within their tier, 26 explained by a register entry, none failing, no test failing, no provider near a threshold; its report equals the committed one but for its date and commit; `dev/reference/cox/calibrate.R` reproduces `validation/cox-calibration-report.md` byte for byte;
  - coverage (`dev/tools/coverage_added.R`, `covr::package_coverage()` against `ea7c07b`): 1,634 of the 1,637 R lines the phase added, 99.82%; the package 97.58%;
  - the namespace from `a919c0b`: only `fit_fine_gray()`, `data_check_survival_values()`, and the added `profile_spec.pprof_cox_penalized()`; exports, data, and C++ unchanged;
  - the benchmarks: `dev/bench/results/cox-final-20261016.md`, every fit meeting the MUST in its latest run.
- The final review, `dev/design/COXPH_FINAL_REVIEW.md`, gives each criterion of the brief's §11 with its evidence: all met, with the SHOULD of §3.7 not met where DEC-098 allows it, and the Class B items' sign-off by a methodology owner open (M-16).
- Next step: the project lead's approval of the gate. Then, with approval: the phase's later commits into `main`, best through a pull request (which runs `rewrite-sanitizers`); `CLAUDE.md`'s "Current phase", whose text the gate report proposes.

## 2026-10-16: the C6 gate closed

- The project lead approved closing the C6 gate, and with it the CoxPH phase, and asked for the work in `main`: the fork's `main` takes `coxph/phase-6` as a fast-forward from `f1c8414`, and the branch goes to the fork.
- `main` takes the work by push, not by a pull request, so `rewrite-sanitizers`, which runs on pull requests or by hand, has not run on the phase's code; the other workflows run on the push.
- Open, as at the gate (`dev/design/COXPH_FINAL_REVIEW.md` §4): the methodology owners' sign-off of the Class B items and the questions (M-16); reporting survival's `finegray()` defects and pprof_py's upstream; the website's address; the CRAN submission, with R-hub's check without long double, deferred by the project lead; `rewrite-bench.yaml`'s first run; and `CLAUDE.md`'s "Current phase", whose text the gate report proposed and which changes with the project lead's approval.
- Next step: none within the CoxPH phase. The next work, a brief for one of the later models (the CoxPH brief's §2.2, DEC-089) or the CRAN submission, is the project lead's to choose.

## 2026-10-19: the Class B items and questions signed off

- The project lead approved the recommendations for the decisions that awaited a methodology owner, and confirmed that the approval is the methodology owners' written sign-off: M-16 is answered, the methodology owner being the project lead, and D-56 to D-61, D-64, D-72, D-78, and M-23 to M-41 are signed off as decided (DEC-142).
- Recorded on the branch `coxph/sign-off`, from `main` at `bec3c21`: the registers (the CoxPH sections of DISCREPANCIES and OPEN_QUESTIONS, M-16 in ARCHITECTURE §M, the status of DEC-087 and DEC-115, and DEC-142), a dated note in the final review, and the Cox equivalence report, whose generator now reads the sign-off from the register and marks no CoxPH entry as awaiting. No package file and no number changed; the report's comparisons are as before (1,897, none failing).
- Still open: the rewrite's Class B entries and the open questions among M-1 to M-22, which now await the project lead's sign-off; and the other open items of the final review's §4.
- Next step: the project lead's approval to merge `coxph/sign-off` into `main` and push it to the fork.
