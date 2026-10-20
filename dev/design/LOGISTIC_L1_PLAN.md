# Logistic extensions Phase L1 plan: reference capture

> **Status: adopted on 2026-10-20 under the project lead's approval** ("I approve the plan and continue", after L0's gate closed), and carried out on `logistic/phase-1` (`dev/LOGISTIC_STATUS.md`). It implements the brief's §4 row L1 (`dev/logistic_brief.md`; also §3.1, §3.5, §3.6, §3.7, §6) and LOGISTIC_DESIGN §G and §I. Its decisions are DEC-156 onward.

L1 changes no package code under `R/` or `src/`. It produces:

- the pprofR reference fixtures;
- the rules they are compared under;
- the first comparisons, of binary outcomes, which pprof computes already;
- the benchmark baseline.

L2 to L4 then have a fixed target.

## 1. Deliverables

| # | Deliverable | Where |
|---|---|---|
| 1 | The pprofR library: pprofR 0.2.0 built from `git archive f23c288` with Rcpp, RcppArmadillo, and poibin at the versions of the reference lock (the CRAN snapshot of 2026-10-01, DEC-017), and its lock | `dev/reference/pprofr/setup_pprofr_library.R`, `dev/reference/pprofr/pprofr-library-lock.json`; the library in `dev/reference/pprofr/lib/` (gitignored) |
| 2 | The generator: the synthetic data sets, the case table, the runner, and the diff report | `dev/reference/pprofr/` (`datasets.R`, `cases.R`, `generate.R`, `compare.R`, `README.md`) |
| 3 | The full fixture set, with its manifest; each fixture holds its data | `validation/fixtures/pprofr/` |
| 4 | The calibration: each kind of result against pprofR's agreement with the independent references, and against the negative controls | `dev/reference/pprofr/calibrate.R`, `validation/pprofr-calibration-report.md` |
| 5 | The tiers' application: each kind of result's tier with its one-line justification, and the comparison helper | `tests/testthat/helper-pprofr-fixtures.R` |
| 6 | The comparisons of what pprof computes already: binary outcomes, with the register's differences where they arise | `tests/testthat/test-pprofr-reference.R`, `validation/run-pprofr-reference.R`, `validation/pprofr-equivalence-report.md` |
| 7 | CI: both jobs of the reference workflow run the comparisons (DEC-152, DEC-154) | `.github/workflows/rewrite-reference.yaml` |
| 8 | The benchmark baseline: pprofR's tasks on the grid of design §I, as far as their cost allows | `dev/bench/pprofr/`, `dev/bench/results/pprofr-baseline-<date>-windows.*` |
| 9 | The size of a core set, measured (DEC-153) | `dev/LOGISTIC_STATUS.md` |

## 2. Cases

The data are synthetic only, with generic names, and exact in text: integer events, trials, and labels, and covariates on a grid of 1/64. `datasets.R` makes them with explicit seeds. Rows come grouped by provider and, within a provider, by cluster, with zero-padded labels, so that pprofR's sort and pprof's agree (D-97). A cluster's rows share a random intercept, so rows within a cluster are correlated.

| Case | Data | What pprofR computes | Negative controls |
|---|---|---|---|
| `binary-moderate` | 40 providers, 8 to 30 clusters each of 1 to 4 rows, one trial per row, 3 covariates | fits: SerBIN and BAN, `"or"` and `"beta"`, tol 1e-5 and 1e-10; at pprofR's defaults, the variances, every test with each alternative (the bootstrap with a seed), the intervals of effects and measures, the measures (`N_pop` default and given), and the covariate tests; with the clusters (`PatientID`, screened by clusters), the robust and stabilized tests, the robust Wald intervals and coefficients, and the direct rates' standard errors | one event moved between rows; one cluster split in two; the null shifted by 1e-9 |
| `binomial-moderate` | the same layout, 1 to 20 trials a row | the same | the same |
| `binomial-many-trials` | 12 providers of 1,500 to 4,000 trials | fits, the tests, the intervals | one event moved; the null shifted |
| `few-clusters` | providers with one, two, and three clusters; and every provider with one cluster | the robust and stabilized tests and Wald intervals; a stabilized variance that is negative | — |
| `extreme-probabilities` | binary and binomial data with null probabilities below 1e-10 | fits, tests, measures | — |
| `extreme-providers` | binomial providers with no events, and with only events | fits, tests, intervals, measures | — |
| `zero-trials` | rows with zero trials among others; and a provider whose rows all have zero trials | fits, tests, measures | — |
| `standard-population` | `direct_exp()` with weights, repeated linear predictors, effects of ±15 and ±30, and rates near 1 | expected totals and their variances | — |
| `measure-tests` | `binomial-moderate`'s direct rates, with their model-based, robust, and stabilized standard errors | `test_SM()` on both scales, two nulls, three alternatives | — |
| `supplied-effects` | `binomial-moderate`'s fit with effects supplied as pprofR takes them (B4) | the direct measures | — |
| `cluster-order` | `binomial-moderate` with each cluster's rows reversed | the robust and stabilized tests | — |

Design §G.1 lists `clustered-binary` and `clustered-binomial` as cases of their own. They are the clustered fits of the two moderate cases here, whose data have clusters with a shared random intercept.

**What each fixture stores.** Plain R objects keyed by provider, not pprofR's classes:

- for each fit: its iteration count, β, γ, the provider table (sizes, inclusion, indicators), −2ℓ, AIC, BIC, AUC, the fitted probabilities and linear predictors, Var(β), and Var(γ);
- for each call: its value, error, warnings, and messages.

## 3. Approach

1. **The library.** `setup_pprofr_library.R`:
   - installs Rcpp, RcppArmadillo, and poibin from the 2026-10-01 snapshot into the library (binaries where the snapshot has them, as `setup_reference_library.R` does), and checks their versions against `dev/reference/library-lock.json`;
   - extracts `git archive f23c288` into a scratch folder, never the working tree, and installs it with `R CMD INSTALL --preclean`;
   - verifies the library's isolation in a child session;
   - writes the lock: pprofR's commit and version, the packages, R, the platform, the compiler, BLAS, LAPACK, and long double.

   The commit must be in the local object store; otherwise the script stops and says how to fetch it read-only.
2. **The generator.** `generate.R`:
   - refuses inputs with uncommitted changes, as the existing generators do;
   - builds the data sets in the parent;
   - runs each case in a child session whose library path is the pprofR library and base R only, with `LC_COLLATE=C`, `OMP_THREAD_LIMIT=1`, `threads = 1` in every call that takes it, and an explicit seed before every random call;
   - writes one RDS per case (format version, case, data, calls, outputs) and `manifest.json`.

   The manifest records:
   - pprofR's commit and version, never the text of its files;
   - R, the platform, the compiler, BLAS and LAPACK, long double, the RNG kinds, the locale, the thread settings, and the package versions;
   - the generator's commit;
   - each case's calls and seeds;
   - the SHA-256 of every file.

   `compare.R` compares two fixture trees, by bytes and by values, for regenerations and for the determinism check.
3. **The calibration.** `calibrate.R` runs in the development environment (`devtools::load_all()`, with sandwich). It compares each kind of result in each case with its independent reference (design §G.3, D):
   - `glm()` with `cbind(y, n - y)`, by DEC-050's rule;
   - the expansion into trials through pprof's binary code;
   - `sandwich::vcovCL(type = "HC0", cadjust = FALSE)`;
   - plain-R versions of the definitions at pprofR's estimates: the sums, variances, robust and stabilized meats, Poisson-binomial tails, the bootstrap's draws, the root finder at pprofR's settings, the delta method by central differences, and the measure test.

   It reports two numbers for each comparison:
   - the ratio of the largest difference to the tier's allowance, which must be at most 1;
   - for each negative control, the ratio against pprofR's own result, which must be at least 10.

   A tier that fails either bound is reported, not widened, and goes to the project lead (the brief's §3.5).
4. **The tiers' application** (`helper-pprofr-fixtures.R`):

   | Kind of result | Tier |
   |---|---|
   | counts, inclusion, indicators, flags | `exact` |
   | estimates, with the iteration count matched | `iterative` |
   | variances given the estimates, robust and stabilized standard errors, measures and their standard errors, direct standardization, the measure test | `closed_form` |
   | p-values (the exact test's statistic by DEC-083's rule) | `probability` |
   | limits | `root` |

   `expect_pprofr_tier()` records each comparison's ratio for the report, as `expect_cox_tier()` does (DEC-135).
5. **The comparisons in L1: binary outcomes.** `test-pprofr-reference.R` reads the full set when it is present and skips otherwise. `validation/` is build-ignored, so `R CMD check` skips it.
   - It compares pprof's results on the binary cases with pprofR's: fits (SerBIN and BAN, with `"or"` as `"any"` and `"beta"` as `"coefficients"`), variances, tests, intervals, measures (pprofR's rates times 100, D-87), and covariate tests.
   - It expects three register differences where they arise: D-82 (the clamp) where a null probability lies beyond it; D-84 where a fitted probability does; and D-85 (the root finder), within `root`.
   - `run-pprofr-reference.R` runs it with the margins and writes `pprofr-equivalence-report.md`, as `run-cox-reference.R` does.
6. **CI.** Both jobs of `rewrite-reference.yaml` run `run-pprofr-reference.R` after the Cox comparisons and upload its report.
7. **Benchmarks** (`dev/bench/pprofr/`):
   - `scenarios.R` varies one factor at a time around a centre of 100,000 rows, 1,000 providers, 10 trials a row, 5 covariates, and clusters of 1 to 4 rows. The other scenarios: one trial a row, 100 trials a row, 10,000 rows with 100 providers, 1,000,000 rows, and 20 covariates.
   - `run_pprofr.R` runs each task in a fresh process with `harness.R`'s measurements, pprofR from its library.
   - `summarize.R` writes the report.
   - Tasks: the fits (SerBIN, BAN), the variances, each provider test, the covariate tests, the intervals, the measures, `direct_exp()`, and `test_SM()`.
   - A task too costly to run here is skipped with the reason, and one provider's time is recorded instead: for example the exact test and its intervals at 100 trials a row, which cost O(T²) per provider.
8. **The core set.** Measure the compressed size of the cases L2 would ship, against the tarball's room.

## 4. How equivalence is checked in L1

- The fixtures are generated twice from a clean tree; the second run must reproduce every file byte for byte (`compare.R`).
- pprofR's own tests pass in its library, as in fact 01.
- The calibration report shows every kind of result within its tier against the independent references, and every control at least 10 units away.
- The binary comparisons pass, with the register's differences where they arise.
- The existing families are untouched: `devtools::test()`, `validation/run-reference.R`, and `validation/run-cox-reference.R` give the same results as at L0.

## 5. Order of work

1. The library and its lock.
2. The data sets and the case table; the generator; the fixtures, twice; the diff report.
3. The calibration and its report.
4. The helper, the binary comparisons, and their report; CI.
5. The benchmark baseline.
6. The core set's measurement; the registers, the documents, and L1's gate.

## 6. Decisions

Each is recorded as it is made:

- DEC-156: the library;
- DEC-157: the fixtures' format and cases;
- DEC-158: the comparison rules and the calibration;
- DEC-159: the comparisons from L1, and CI;
- DEC-160: the benchmark grid.
