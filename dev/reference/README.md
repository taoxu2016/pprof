# dev/reference: reference fixture generator

Produces the frozen fixtures that define the reference behavior of pprof 1.0.3 (commit `5260838`) for the rewrite (brief §3.1, ARCHITECTURE §G.1). Tests never need the old package at run time: they replay each fixture's case against the package under test.

## Files

| File | Purpose |
|---|---|
| `setup_reference_library.R` | Builds the isolated reference library `dev/reference/lib/` (gitignored): pprof 1.0.3 from the MD5-checked CRAN tarball, and its dependency closure from the CRAN snapshot of 2026-10-01 (DEC-017) |
| `library-lock.json` | Committed record of that library: every package, version, and source |
| `datasets.R` | Bundled datasets and the seeded synthetic edge-case suite |
| `cases.R` | The case table: every public function and method over the argument grid |
| `generate_fixtures.R` | Runs the cases in isolated child sessions and writes fixtures, datasets, and manifests |
| `compare_fixtures.R` | Diff report between two fixture directories (regeneration, determinism checks) |
| `../../tests/testthat/helper-reference-cases.R` | The case runner, shared by the generator and the tests |

## Generating fixtures

```sh
Rscript dev/reference/setup_reference_library.R            # once per machine
Rscript dev/reference/generate_fixtures.R                   # writes both sets
```

- Core set: `tests/testthat/fixtures/reference/` (shipped with the package tests; at most 5 MB, DEC-018).
- Full set: `validation/fixtures/reference/` (build-ignored; run by `validation/run-reference.R`).

The generator refuses to run when its inputs have uncommitted changes, because fixtures must come from the committed generator. `--allow-dirty` exists only for runs into a scratch directory (`--out-core`, `--out-full`).

Each set runs in one child R session whose library path is only the reference library plus base R, with `LC_COLLATE=C` (as testthat 3e uses for tests; D-34), `OMP_THREAD_LIMIT=1` (one thread even where the reference hard-codes more; D-21), and `threads = 1` in every call that accepts it.

## Regenerating

Regenerating committed fixtures requires the project lead's explicit approval and a diff report (CLAUDE.md):

```sh
Rscript dev/reference/generate_fixtures.R --out-core <tmp>/core --out-full <tmp>/full
Rscript dev/reference/compare_fixtures.R tests/testthat/fixtures/reference <tmp>/core --report <tmp>/core-diff.md
Rscript dev/reference/compare_fixtures.R validation/fixtures/reference <tmp>/full --report <tmp>/full-diff.md
```

Fixtures are never edited by hand and never regenerated to make a failing test pass.

## What a fixture holds

Each `<case-id>.rds` is a list with `format_version`, the `case` (function, arguments with markers for datasets, formulas, parent results, and expressions evaluated when the case runs, such as lme4 control objects; seed; tolerance tier), and the `result`: outcome (`value` or `error`), the processed value, the error, warnings, messages, printed output, and the iteration count parsed from the C++ log. Values are processed by `reference_fixture_value()`: vectors longer than 5,000 elements become signatures (counts, sums, extremes, a sample, and an exact checksum), lme4 fits become their extracted components, and ggplot objects become the data of their layers.

`manifest.json` records the reference (version, commit, CRAN MD5), the generator commit, the library lock, R and platform, compiler, BLAS and LAPACK, locale, thread settings, every package version, and for each case its call, seed, tier, outcome, iteration count, and checksum.

The fixture checksums are of binary RDS files and hold on every platform. `library.lock_md5` is the checksum of `library-lock.json` as written on the generating machine (CRLF line endings on Windows), so it differs on a checkout with LF line endings; it is informational, and the lock's content is the record.
