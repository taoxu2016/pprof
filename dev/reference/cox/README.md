# dev/reference/cox: the Cox fixture generator

Produces the frozen fixtures that define the reference behavior of the Cox models (CoxPH brief §3.1 and §6, COXPH_DESIGN §G.1, DEC-093): pprof_py v0.7.0's outputs (commit `9320766`) and `survival`'s and `glmnet`'s, case by case. Tests never need Python or pprof_py at run time: they read the fixtures.

## Files

| File | Purpose |
|---|---|
| `requirements.txt` | The pinned Python environment: Python 3.12.3 and pprof_spark's pins (its `REFERENCE.lock`, commit `e917a68`) |
| `setup_cox_library.R`, `cox-library-lock.json` | The isolated R library `lib/` (gitignored): `survival` 3.8-12, `glmnet` 5.1, and `jsonlite` from the CRAN snapshot of DEC-017, and its committed record |
| `vendor_inputs.py`, `inputs/` | The imported inputs, copied from their pinned commits with their SHA-256 in `inputs/SOURCES.json`: pprof_spark's six Cox cases and pprof_py's penalized and competing-risk datasets (MIT) |
| `cases.py` | The cases: their kind, set, source, flags, and inputs (synthetic ones drawn from fixed seeds) |
| `generate.py` | The driver: pprof_py's outputs, then `survival.R` and `convert.R`, then the manifests |
| `survival.R` | `survival`'s and `glmnet`'s outputs, as the package's adapters will call them (`timefix = FALSE`) |
| `convert.R` | One RDS fixture per case, with every double read back exactly from its hexadecimal form |
| `calibrate.R` | The calibration report `validation/cox-calibration-report.md` (CoxPH brief §3.5) |
| `compare.R` | The diff report between two fixture trees (regeneration, determinism) |

## Setting up (once per machine)

```sh
python -m pip install --user uv                   # any Python; uv fetches Python 3.12.3 itself
uv python install 3.12.3
uv venv --python 3.12.3 dev/reference/cox/venv
uv pip install --python dev/reference/cox/venv/Scripts/python.exe -r dev/reference/cox/requirements.txt
uv pip install --python dev/reference/cox/venv/Scripts/python.exe --no-deps "pprof_py @ file:///<pprof_py checkout>"
Rscript dev/reference/cox/setup_cox_library.R
```

On Linux and macOS the environment's Python is `dev/reference/cox/venv/bin/python`. The pprof_py checkout must be at commit `9320766`; `generate.py` checks that every installed module equals the file at that commit. pandas 3 also installs `tzdata` on Windows, which pprof_spark's Linux environment did not need; it has no numerical role, and the manifest records it.

## Generating fixtures

From the repository root, with R on the PATH (`RSCRIPT` can name another `Rscript`) and `PPROF_PY` naming the pprof_py checkout (default `../../pprof_py`):

```sh
dev/reference/cox/venv/Scripts/python dev/reference/cox/generate.py
Rscript dev/reference/cox/calibrate.R
```

- Core set: `tests/testthat/fixtures/cox/`, shipped with the package tests and kept small.
- Full set: `validation/fixtures/cox/` (build-ignored).

Every thread pool runs one thread (numba, OpenMP, OpenBLAS, MKL), and synthetic inputs come from fixed seeds, so a rerun reproduces every file byte for byte on one machine. The generator refuses to run when this folder has uncommitted changes, because fixtures come only from the committed generator. `--allow-dirty`, `--cases`, `--staging`, and `--python-only` exist for development and work only with both outputs outside the fixture folders.

## Regenerating

Regenerating committed fixtures needs the project lead's approval and a diff report (CLAUDE.md):

```sh
dev/reference/cox/venv/Scripts/python dev/reference/cox/generate.py --out-core <tmp>/core --out-full <tmp>/full
Rscript dev/reference/cox/compare.R tests/testthat/fixtures/cox <tmp>/core --report <tmp>/core-diff.md
Rscript dev/reference/cox/compare.R validation/fixtures/cox <tmp>/full --report <tmp>/full-diff.md
```

Fixtures are never edited by hand and never regenerated to make a failing test pass. CI can regenerate them into an artifact with a diff report (`.github/workflows/cox-fixtures.yaml`, run by hand).

## What a fixture holds

Each `<case-id>.rds` is `list(format_version, case, input, pprof_py, survival)`:

- `case`: the definition from `cases.py`, with the features, the row and event counts, the fixed β, and for imported inputs their provenance (repository, commit, path, license, SHA-256);
- `input`: the input as a data frame of exact doubles and integers;
- `pprof_py` and `survival`: per tie method, nested lists of numeric, integer, logical, and character vectors. For Cox cases: default and tight fits, Newton iterates, ℓ, U, and I at β = 0 and at the fixed β, baselines and predictions, residuals and robust variances, measures, mid-p and exact tests, funnel limits (`CoxPH.funnel_limits()` with the mid-p test: each provider's limits and flag at level 0.95, and in the full set the curves at 0.95 and 0.998, which the shipped set leaves out for the tarball's size; added in Phase C3), negative controls, and on the R side the national expected counts at both sides' β̂. Competing-risk cases hold cause-specific fits, measures, tests, and funnel limits, and Fine–Gray expansions, fits, iterates, and cumulative incidences; penalized cases hold paths and, where folds are given, cross-validation.

`manifest.json` records the generator commit and whether its folder was clean, the Python environment (every installed distribution, the platform, the processor), the R environment (versions, platform, LAPACK, BLAS, compiler), the thread settings, the options, and for each case its kind, source, size, seed, provenance, and the SHA-256 and MD5 of its fixture. It has no timestamps.

## Conventions worth knowing

- Times are compared exactly (`timefix = FALSE`, M-23); the `near-ties` case also records `survival`'s default `timefix = TRUE` fits.
- Rows with zero weight are left out of `survival`'s fits and kept in the measures (M-25).
- pprof_py's cross-validation deviance uses the Breslow form of the saturated log-likelihood, −Σ w_t log w_t over tied event weights, for both tie methods (glmnet 4.1-8's `coxnet.deviance2`). `glmnet` 5.x's `coxnet.deviance()` agrees with it for Breslow ties but not for Efron ties, where its saturated term differs by a constant (336.7 on `penalized_wide`); `survival.R` therefore computes pprof_py's deviance from `survival`'s partial likelihood (K-144).
- Robust variances without a cluster column are clustered by `id mod 40`, as pprof_spark's.
