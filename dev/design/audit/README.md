# Phase 0 audit scripts

These scripts check the hypotheses from the static audit (PROJECT_CONTEXT §5–6) by running the reference, pprof 1.0.3 (commit `5260838`). Each script writes a plain-text log to `output/`. `ARCHITECTURE.md`, `BEHAVIOR_SPECS.md`, `DISCREPANCIES.md`, and PROJECT_CONTEXT §5.7 cite those logs as evidence IDs such as `V10.3`.

They are audit tools, not the Phase 1 fixture generator. Nothing here writes fixtures or touches `tests/`.

## Setup

1. Install the reference from the CRAN tarball into a dedicated library that contains nothing else:

   ```sh
   Rscript dev/design/audit/install_reference.R <library-dir>
   ```

   The script downloads `pprof_1.0.3.tar.gz` from CRAN, checks its MD5 against the CRAN `PACKAGES` index (`6fa1344f4a265811059d27a105d06d6b`), and installs it into `<library-dir>`. Dependencies come from the normal user library.

2. Point the scripts at that library and run each one in its own R session:

   ```sh
   export PPROF_REF_LIB=<library-dir>
   Rscript dev/design/audit/10_logistic_fe_fit.R > dev/design/audit/output/10_logistic_fe_fit.log 2>&1
   ```

   `run_all.sh` does this for every script.

Every script loads the reference with `library(pprof, lib.loc = Sys.getenv("PPROF_REF_LIB"))` and stops unless the loaded version is 1.0.3 from that library. Checks that could crash R (undefined behavior in the C++ code) run in a child process through `callr`.

## Scripts

| Script | Covers |
|---|---|
| `01_cran_identity.sh` | CRAN tarball versus commit `5260838` |
| `10_logistic_fe_fit.R` | SerBIN and BAN iteration semantics, R ports of both algorithms, screening, ordering, design matrix, input formats |
| `11_logistic_fe_stopping.R` | Early stopping under `stop = "or"` at scale; `threads = 2` versus `threads = 1` |
| `12_firth.R` | Firth iteration, threading, returned object |
| `13_logistic_fe_inference.R` | `test`, `SM_output`, `confint`, `summary`, `plot` for `logis_fe` |
| `14_linear_fe.R` | `linear_fe` and its methods, agreement with `lm()` |
| `15_random_effects.R` | `linear_re`, `logis_re`, `linear_cre`, `logis_cre` and their methods |
| `16_misc.R` | `data_check`, plots, package-level behavior |
| `20_bench_phase0.R` | Preliminary timings for the R/C++ boundary (ARCHITECTURE §F) |

`12_firth.R` (V12.5) compares Firth estimates with `logistf` when it is installed, either in the normal library or in a `suggestslib` directory next to `PPROF_REF_LIB`; otherwise that check is skipped.

## Recorded environment

The committed logs were produced on 2026-10-02 on Windows 11 Enterprise 10.0.22621, R 4.4.0 (ucrt), Rtools44 with GCC 13.3.0 and OpenMP, R's reference BLAS and LAPACK, lme4 2.0-6, Matrix 1.7-6, RcppArmadillo 15.6.0-1, Rcpp 1.1.2, poibin 1.6, logistf 1.26.1, in an English (United States) locale. Each log starts with `sessionInfo()`. The reference library path is shown as `<PPROF_REF_LIB>`. Timings (B1 to B5) come from one machine with few repetitions; they are indicative, not a baseline.
