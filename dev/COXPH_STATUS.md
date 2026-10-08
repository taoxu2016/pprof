# CoxPH phase: status

The dated log of the CoxPH phase (`dev/coxph_brief.md`, §0): an entry after each session with material progress, naming the next step. Newest last.

**Status:** Phase C2, the data layer and the stratified Cox model, is in progress on `coxph/phase-2`: its plan, `dev/design/COXPH_C2_PLAN.md`, awaits the project lead's approval.

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
