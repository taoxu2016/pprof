# dev/reference/pprofr: the pprofR fixture generator

Produces the frozen fixtures of pprofR 0.2.0 (commit `f23c288`), the reference of the logistic extensions phase's new features: binomial outcomes, cluster-level inference, the extensions of standardization, and the test of a measure (`dev/logistic_brief.md` §3.1; LOGISTIC_DESIGN §G.1; `dev/design/LOGISTIC_L1_PLAN.md`; DEC-152, DEC-156, DEC-157). Tests never need pprofR: they compare the package with the fixtures' records.

pprofR's files are not part of this repository. The setup script reads them from the local object store with `git archive` into a temporary folder; nothing here quotes them, and the manifests record pprofR's commit and version only.

## Files

| File | Purpose |
|---|---|
| `setup_pprofr_library.R` | Builds the isolated library `lib/` (gitignored): pprofR from `git archive f23c288`, with Rcpp, RcppArmadillo, and poibin from the CRAN snapshot of 2026-10-01 at the versions of `../library-lock.json`; runs pprofR's own tests against it |
| `pprofr-library-lock.json` | Committed record of that library: the packages, their versions and sources, the platform, and pprofR's test results |
| `datasets.R` | The synthetic data sets, seeded: providers with clusters of correlated rows, one trial or several per row, and the negative controls' variants |
| `cases.R` | The cases: what pprofR computes on each data set, as records of calls |
| `generate.R` | Runs each case in a child session on the pprofR library and writes the fixtures and `manifest.json` |
| `compare.R` | Compares two fixture trees: the diff report of a regeneration, and the determinism check |
| `calibrate.R` | The calibration of the comparison rules against the independent references and the negative controls (`validation/pprofr-calibration-report.md`) |

## Generating fixtures

Commit `f23c288` must be in the local object store: fetch it read-only from the branch of the upstream repository that holds it. Then:

```sh
Rscript dev/reference/pprofr/setup_pprofr_library.R      # once per machine
Rscript dev/reference/pprofr/generate.R                   # writes validation/fixtures/pprofr/
```

The fixtures are the full set only, in `validation/fixtures/pprofr/` (build-ignored); no core set ships with the tests (DEC-153). The generator refuses to run when its inputs have uncommitted changes. `--allow-dirty` writes only to another directory (`--out`), and `--only` selects cases by a regular expression.

Each case runs in a child R session with these settings:

- its library path is the pprofR library plus base R (the site library dropped);
- `LC_COLLATE=C` and `OMP_THREAD_LIMIT=1`;
- `threads = 1` in every call that takes it;
- R's default random number generators, with an explicit seed before every call that draws random numbers (the bootstrap).

## Regenerating

Regenerating committed fixtures needs the project lead's explicit approval and a diff report (CLAUDE.md). It runs locally only; no workflow regenerates them (DEC-154):

```sh
Rscript dev/reference/pprofr/generate.R --out <tmp>/pprofr
Rscript dev/reference/pprofr/compare.R validation/fixtures/pprofr <tmp>/pprofr --report <tmp>/pprofr-diff.md
```

Fixtures are never edited by hand and never regenerated to make a failing test pass.

## What a fixture holds

Each `<case>.rds` is a list with these elements:

- `format_version`;
- `id` and `description`;
- `data`, the case's data sets as given to pprofR, before its sort;
- `records`, one per call, named by what it computes (for example `unclustered/test/exact.poisbinom/median/two.sided`).

Each record holds:

- the call's text, with the values of its loop variables;
- its seed;
- its value as pprofR returns it (data frames, matrices, lists), or its error;
- its warnings and messages.

Fits are stored as lists of their components: the coefficients, effects, provider table, iteration count in `control$iter`, criteria, and, for the fits that later calls use, the fitted probabilities and linear predictors.

`manifest.json` records:

- pprofR's commit and version;
- the generator's commit and inputs, and the library lock's checksum;
- R, the platform, the compiler, BLAS and LAPACK, long double, the random number generators, the locale, and the thread settings;
- the versions of pprofR, Rcpp, RcppArmadillo, and poibin;
- for each case, its file's MD5, its data sets, its records' calls and seeds, and the calls that raised errors.

The fixtures' checksums are of binary RDS files and hold on every platform.
