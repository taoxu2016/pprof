# CI diagnosis (Phase 8, step 1)

Every failure of the fork's CI, its cause, and its fix, read from the job annotations through the public GitHub API with `01_ci_runs.R` (the logs and artifacts need a signed-in account). The project lead did not provide the artifacts of F1; the annotation step of DEC-071 (`.github/scripts/ci-annotate.R`) made the causes readable instead. Plan cases (PHASE8_PLAN.md, step 1): (a) a defect of pprof; (b) a test that depends on its environment; (c) a fixture comparison outside its tolerance on a platform; (d) the workflow or the installation of dependencies.

## Before Phase 8 (F1)

Every push from `rewrite/phase-2` to `rewrite/phase-7` failed the check, reference, and coverage workflows. The causes below are those of the first readable runs. The earlier runs' annotations show the same symptoms where they were read: check ERRORs on every system at `69461c3` (Phase 2) and `0e3cb3c` (Phase 7), with "median(): detected NaN" on Linux at `8aa85cc` (Phase 6) and `0e3cb3c` but not at `69461c3`, before the Firth engine and its NaN test existed; the reference job failing in its dependency step and the coverage job in its tests at both.

## Runs at `f555d12` (2026-10-05) and `05a46d1` (2026-10-06)

| Symptom | Where | Cause | Case | Fix |
|---|---|---|---|---|
| The data layer's comparisons fail: `data_include$columns$z1#sum` and other sums of long vectors differ in the last digits | macOS (R 4.5.3, 4.6.1) | The fixtures store sums of long vectors, computed with x86_64's 80-bit `long double`; arm64 macOS has no extended precision, so `sum()` of the same values differs in the last digits | (b) | Vectors with identical bit checksums match without comparing summaries (`4956d6c`) |
| `test-cpp-firth.R`: a NaN in the design ends the Firth fit with `std::logic_error` ("median(): detected NaN") instead of `std::runtime_error` | Linux (R 4.5.3, 4.6.1, devel; also the coverage job) | Where LAPACK does not stop at the degenerate matrix, a NaN reaches the clamp's `median()` (`src/core/clamp.h:14`), the only `median()` call of the core; both are R errors of class `C++Error`, and `fit_logistic_firth()` turns either into `pprof_error_convergence` | (b) | The tests require the class `C++Error`, D-42's property (`3c02cc9`). The two "median(): detected NaN" annotations of each Linux job are this test |
| The reference job cannot install its dependencies | Linux, R 4.4.0, snapshot | `extra-packages: Matrix, lme4` made pak resolve lme4's suggested packages: semEff needs gsl, which needs R >= 4.5 | (d) | Hard dependencies only, plus devtools, jsonlite, withr, and testthat (`8a78750`) |
| The same job still cannot install them | Linux, R 4.4.0, snapshot | pprof's own Imports: olsrr needs car, which needs pbkrtest, doBy, and Deriv, which needs R >= 4.5. With olsrr in Imports, pprof cannot be installed from current CRAN on R < 4.5 | (d), and a fact for DEC-074 | Step 3 removes olsrr (and caret) from Imports; the jobs on R 4.4 and the minimum-R probes are expected to install then |
| Minimum-R probes (R 4.4.3, 4.2.3, 4.1.3) fail installing dependencies | Linux | The same chain, and, with "all", the suggested packages of rcmdcheck and sessioninfo | (d) | Probes install hard dependencies and the test suggestions (`8a78750`); the olsrr chain remains until step 3 |
| Jobs "not acquired by Runner even after multiple attempts" | 5 jobs at `f555d12` | GitHub's runner capacity | — | Rerun by the next push |
| Results outside the fixtures' tolerances: the tight-tolerance logistic FE fits (18 instead of 22 iterations, estimates about 5e-10 apart), the exact tests' statistics, the D-04 per-case expectation, lme4-backed results under R-devel | Linux | The platform's floating point differs from the fixtures' (Windows x86_64, R 4.4.0, internal BLAS, LAPACK 3.12.0) | (c) | DEC-080 (the project lead's delegation): numbers compared on the fixtures' platform, and on others against fixtures pprof 1.0.3 produces there; D-53 |
| The exact tests' statistics (1.6e-10 to 9.6% relative) and the collinear fit | macOS | As above | (c) | As above |
| The collinear fit; with R 4.6.1 and the manifest's lme4 and Matrix, most logistic RE and CRE cases | Windows, R 4.5.3, 4.6.1, devel (LAPACK 3.12.1) | As above | (c) | As above |
| "Problems with news in NEWS.md: No news entries found" (note) | Linux release | NEWS has no versioned heading | — | Step 5 (version 2.0.0) |

Passing at `05a46d1`: `rewrite-lint` (no lints), `rewrite-pkgdown`.

## Runs at `135a03a`, `2306366`, and `dbd5de8` (2026-10-06)

| Symptom | Where | Cause | Case | Fix |
|---|---|---|---|---|
| The fixture-platform reference job and the check job on R 4.4.0 cannot install the dependencies | Windows, R 4.4.0 | olsrr's chain (above) | (d) | Step 3 |
| "Child library path is not isolated": the generator stops before running a case | The three per-platform reference jobs (DEC-080) | The runners install packages into R's site library (`R_HOME/site-library`), and callr's profile for the child session sets `.Library.site` to the parent's, whatever `R_LIBS_SITE` says; the generator requires the child's library path to be only the reference library and base R, and the machine that produced the fixtures has no site library | (d) | First `R_LIBS_SITE=NULL` for the child (`b36d003`), which had no effect, since callr's profile overrides it (the jobs failed the same way at `d737acf`; the commit message's claim was wrong). Then the child drops the site library itself with `.libPaths(<reference library>, include.site = FALSE)` before loading anything but base R; the check is unchanged. Locally, with an empty directory as the parent's site library, the generator failed as on CI before the change and runs after it; regenerated into scratch directories with and without that site library, the fixtures (332 core and 32 full cases, every dataset) and the environment record are identical to the committed ones, the library path recorded without the site library |
| `test-independent-fits.R:99` and `:107`: "Expected linear RE (CRE) provider variance to be identical to `as.numeric(lme4::VarCorr(direct)[[provider]])`", 0.161524443211056384 against 0.161524443211056357, one unit in the last place; the fixed and random effects, vcov, log-likelihood, and fitted values identical | macOS (R 4.5.3, 4.6.1) | The fits take the provider variance as the square of lme4's `sdcor` (K-51, as pprof 1.0.3 does), a square root and a square away from `VarCorr()`'s variance; the two are equal to rounding, and bitwise only where the rounding happens to cancel, as on x86_64 for these data | (b) | The test checks the variance bitwise against K-51's computation on the direct fit, which holds wherever the fits are identical, and against `VarCorr()`'s variance with the closed-form tolerance |
| R-devel cannot install the dependencies: data.table, which caret needs, fails to compile ("'libintl.h' file not found") | macOS, R-devel (4.7) | R-devel has no macOS binary packages, so every dependency builds from source; data.table includes gettext's `libintl.h`, which CRAN's build machines have in `/opt/R/arm64` and the runner does not | (d) | The job installs CRAN's macOS build of gettext 0.22.5 (`https://mac.r-project.org/bin/darwin23/arm64/`) into `/opt/R/arm64` before the dependencies |
| Note "Package suggested but not available for checking: 'logistf'" | Windows, R 4.4.0 (fixtures) | The job installs pprof's hard dependencies only (above), and from step 3 caret and olsrr are suggested too | (d) | The job also installs pROC, logistf, caret, and olsrr, the suggested packages of the independent-reference tests |
| Minimum-R probes (R 4.4.3, 4.3.3, 4.2.3, 4.1.3) cannot resolve the dependencies: olsrr's chain (pbkrtest needs R >= 4.2.0; Deriv R >= 4.5) | Linux | As above | (d) | Step 3 |

Passing at `dbd5de8`: `rewrite-check` on Linux and Windows (release, devel, oldrel-1) and on Windows R 4.4.0 with the committed fixtures (one note, above), `rewrite-coverage`, `rewrite-lint`, `rewrite-pkgdown`.

## Runs at `d737acf` (2026-10-06)

| Symptom | Where | Cause | Case | Fix |
|---|---|---|---|---|
| `test-check-data.R`: the warnings of `data_check-collinear` differ from the fixture: three "essentially perfect fit: summary may be unreliable" before pprof's own VIF warning | Linux (coverage job, R release) | `summary.lm()` warns when the residual variance of exactly collinear columns falls below 1e-30 (mean(f)^2 + var(f)), f the fitted values, which rounding decides for exactly collinear columns; on the fixtures' platform neither pprof 1.0.3 (through olsrr) nor the wrapper warns | (b) | Off the fixtures' platform the test leaves these warnings out of both sides (DEC-080); on it, every warning is compared |

Passing at `d737acf`: the reference suite on the fixtures' platform with the committed fixtures (364 cases, all matching), `rewrite-lint`.
