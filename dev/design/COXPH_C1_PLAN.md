# CoxPH Phase C1 plan: reference capture

> **Status: adopted on 2026-10-08 under the project lead's delegation** ("continue with all your recommendations if you need decisions", at the C0 gate), and carried out the same day; the project lead approved its gate on 2026-10-08 (`dev/COXPH_STATUS.md`). It implements the brief's §4 row C1 (`dev/coxph_brief.md`; also §3.1, §3.5, §3.7, §6, §12) and COXPH_DESIGN §G and §I. Its decisions are DEC-094 to DEC-097.

C1 changes no package code under `R/` or `src/`. It produces the Cox reference fixtures, the tolerance tiers they are compared under, and the benchmark baseline, so that C2 to C5 have a fixed target.

## 1. Deliverables

| # | Deliverable | Where |
|---|---|---|
| 1 | The Cox fixture generator: Python (pprof_py) and R (`survival`, `glmnet`) halves, the conversion to RDS, and the diff report | `dev/reference/cox/` |
| 2 | Its pinned environments: Python 3.12.3 with pprof_spark's pins and pprof_py at `9320766`; an isolated R library with `survival` and `glmnet` from a CRAN snapshot, with a committed lock | `dev/reference/cox/requirements.txt`, `setup_cox_library.R`, `cox-library-lock.json` |
| 3 | Fixtures: a core set shipped with the tests and a full set for validation, each with a manifest | `tests/testthat/fixtures/cox/`, `validation/fixtures/cox/` |
| 4 | The calibration report: every proposed tier against pprof_py–`survival` agreement and the negative controls | `validation/cox-calibration-report.md` |
| 5 | The Cox tolerance tiers, each with its one-line justification | `tests/testthat/helper-tolerances.R` |
| 6 | Tests of the fixtures themselves: manifest checksums, and `survival` (and `glmnet` when installed) reproducing the fixtures' engine outputs | `tests/testthat/test-cox-fixtures.R` |
| 7 | The benchmark baseline: direct engine calls and pprof_py v0.7.0 on the grid of COXPH_DESIGN §I | `dev/bench/cox/`, `dev/bench/results/` |
| 8 | The manual CI workflow that regenerates the Cox fixtures into an artifact with a diff report (brief §12) | `.github/workflows/cox-fixtures.yaml` |
| 9 | The D-53 remedy, if it holds: the fixture-platform job builds lme4 with Eigen's cache query off and the fixtures' machine's cache sizes | `.github/workflows/rewrite-reference.yaml` |
| 10 | `devtools::test()` timed per file (3 hours at the C0 gate) | `dev/COXPH_STATUS.md` |

## 2. Cases

All inputs are exact in text (brief §6): integer times, covariates on binary grids.

**Imported from pprof_spark** (commit `e917a68`; its `fixtures/cox/`, MIT): `tiny-ties`, `rc-unstratified`, `rc-stratified`, `rc-stratified-weights-offset`, `lt-stratified`, `lt-weights-offset`. Their `input.csv` files are vendored with their SHA-256 and provenance; every output is recomputed by this generator, and the calibration report compares the recomputed pprof_py outputs with pprof_spark's committed ones (another platform: a check of the environment, not a tolerance).

**New** (COXPH_DESIGN §G.1):

| Case | Shape | Set |
|---|---|---|
| `provider-scale` | 20,000 rows, 1,000 providers, delayed entry, integer days | full |
| `recurrent` | several (start, stop] rows per patient, clustered by patient, SHR-shaped | core |
| `near-ties` | times differing below `aeqSurv()`'s tolerance; R outputs with `timefix = FALSE` and `TRUE` | core |
| `zero-weights` | some case weights 0 (pprof_py's Efron count B7; the R side leaves them out, M-25) | core |
| `large-mean` | a covariate with a large mean (D-64) | core |
| `empty-providers` | providers with no events, and with E_j = 0 | core |
| `competing-simple`, `competing-truncated` | pprof_py's `competing_risks_simple.csv` and `competing_risks_truncated.csv`: cause-specific fits and Fine–Gray | core |
| `penalized-*` | pprof_py's `penalized_wide.csv` with its fold IDs, and penalized fits with strata, offset, weights, and delayed entry | core or full by size |

**Outputs per case and tie method**, as pprof_spark's generator: default and tight fits, Newton iterates, ℓ, U, and I at β = 0 and at a fixed β, baselines and predictions, residuals and robust variances, measures, mid-p and exact tests, and the negative controls (the other tie method, one tied event moved by a day, one weight dropped). Penalized cases add the λ grid, the path, and the cross-validation with fixed folds; competing-risk cases add the Fine–Gray expansion, fit, robust variance, and cumulative incidence. The R side computes the same quantities with `survival` (with `timefix = FALSE` stated, as the adapter will call it) and `glmnet`.

## 3. Approach

1. **Environments.**
   - Python: `uv` (installed with the machine's Python into the user site), Python 3.12.3 from `uv python install`, a virtual environment outside the repository, `requirements.txt` equal to pprof_spark's pins, and pprof_py installed from the local checkout after checking that it is at `9320766` and clean.
   - R: `setup_cox_library.R` builds `dev/reference/cox/lib/` (gitignored and build-ignored) from the CRAN snapshot of DEC-017 (2026-10-01) if it has `glmnet` ≥ 5.0, otherwise from the first snapshot that does; `cox-library-lock.json` records it.
2. **The D-53 remedy, first locally.** Build lme4 from source twice into scratch libraries with `-DEIGEN_NO_CPUID` and the default cache sizes set to 32 KB and to 48 KB L1 (the fixture machine's L2 and L3), and run the reference suite against each. It is kept only if 32 KB reproduces CI's 42 failures and 48 KB matches every case; then the CI job builds lme4 so, and two or more runs confirm it.
3. **Per-file test timing** in the background, with no other `load_all()` running.
4. **The generator.** `generate.py` writes inputs, pprof_py's outputs, and the case definitions as JSON with hexadecimal doubles; `survival.R` writes the R outputs; `convert.R` turns both into one RDS per case and writes the manifest (versions of Python, its packages, pprof_py, R, `survival`, `glmnet`; platform; SHA-256 of every input and fixture). `compare.R` gives the diff report between two fixture trees. The generator refuses uncommitted inputs, as `dev/reference/generate_fixtures.R` does.
5. **Calibration** (`calibrate.R`) under the package's rule, |a − b| ≤ atol + rtol·|b| elementwise: for each tier, the largest ratio of observed to allowed difference between pprof_py and `survival` (at most 1), and for each negative control against pprof_py (at least 10). The tiers start from COXPH_DESIGN §G.2 and pprof_spark's calibrated classes; a tier that fails either bound is reported, not widened silently.
6. **Benchmarks** with the paired harness of DEC-038 where it applies; pprof_py in a separate process.

## 4. How equivalence is checked in C1

- Fixtures are generated twice from a clean tree; the second run must reproduce every file byte for byte (the diff report says so).
- The imported cases' pprof_py outputs are compared with pprof_spark's committed outputs.
- The calibration report shows every tier against its bounds.
- `test-cox-fixtures.R` checks the manifests and that the installed `survival` (and `glmnet`) reproduce the fixtures' R outputs within `cox_engine`.
- The existing families are untouched: `devtools::test()` and `validation/run-reference.R` as at C0.

## 5. Order of work

1. Environments, and their scripts and locks.
2. The D-53 remedy, local verification, then CI.
3. Per-file test timing (background).
4. The generator on the six imported cases, cross-checked with pprof_spark.
5. The new cases.
6. Calibration, the tiers, and the fixture tests.
7. The benchmark baseline.
8. The manual regeneration workflow.
9. Registers, documents, and the C1 gate.
