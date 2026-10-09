# CoxPH facts

The scripts behind the evidence in the CoxPH phase brief (`dev/coxph_brief.md`, Appendices A and B), its Phase C0 design (`dev/design/COXPH_DESIGN.md`), and the Phase C2 and C3 plans (`dev/design/COXPH_C2_PLAN.md`, `dev/design/COXPH_C3_PLAN.md`), with the output each one produced. They compare pprof_py v0.7.0 with R's `survival` and `glmnet` and time them; 15 explains a CI failure found at the C0 gate. None of them is part of the package or its tests.

Each numbered script writes the output file of the same name (`.txt`). Where an R script and a Python script share a number, the R script runs first and leaves its results in the scratch directory, and the Python script compares and writes the output (07, 09, and 22 also write an R output, `_r.txt`); for 23 the order is reversed: the Python script runs pprof_py, and the R script compares and writes the output.

| Script | Shows | Brief |
|---|---|---|
| `01_pprof_py_suite.sh` | pprof_py's survival test suite here (one failure, Windows only: B13) | Appendix A, B13 |
| `02_r_reference_drift.R` | pprof_py's R reference results, regenerated with the installed `survival` and `glmnet` | Appendix A |
| `03_glmnet_reference_tests.sh` | pprof_py's `glmnet` tests against the installed `glmnet` (after 02) | Appendix A |
| `04_glmnet_cv_normalization.R` | what changed in `glmnet`'s Cox cross-validation (after 02) | §3.3 rows 10 and 13 |
| `05_robust_finegray.R`, `.py` | the robust variance with Breslow ties (B1); Fine–Gray with delayed entry | Appendix A, B1 |
| `06_benchmark_data.R` | the synthetic data sets for 07 to 09 | Appendix A |
| `07_cox_fit_timing.R`, `.py` | fit and measure times, `survival` and pprof_py | §3.7, Appendix A |
| `08_timefix.R`, `.py` | `timefix`: the whole difference between the two at default settings | §3.3 row 2, Q1 |
| `09_penalized_glmnet.R`, `.py` | `glmnet` against pprof_py's `PenalizedCoxPH` | §1, Appendix A |
| `10_provider_indicators.R` | the cost of explicit provider effects in `coxph()` | §2.2 |
| `11_survival_edge_cases.R` | what `coxph()` does where pprof_py differs | §3.3, §5.1 |
| `12_newton_path.R`, `.py` | pprof_py's Newton path against `coxph()`'s | §3.3 row 7, B6 |
| `13_pprof_py_probes.py` | pprof_py's defects B2–B5, B9, B10; the SMR golden file | Appendix A, B |
| `14_engine_interfaces.R` | what the adapters rely on: `survival`'s fitters against `coxph()`, per-row robust variance, `glmnet`'s per-call control and `coxnet.deviance()` (added in Phase C0) | COXPH_DESIGN §E |
| `15_eigen_cache_blocking.R`, `.cpp` | why CI's fixture-platform job fails the lme4-backed cases on some runners: Eigen sizes the blocks of its matrix products from the processor's L1 cache (added at the C0 gate) | D-53 |
| `16_lme4_cache_sizes.R` | the same with lme4 itself: lme4 built with Eigen's cache sizes fixed at Zen 3's fails the 42 cases, and at the fixtures' machine's matches all (Phase C1) | D-53, DEC-094 |
| `17_robust_from_fitter.R` | `survival`'s fitters called as `coxph()` calls them give its fit bitwise, and its own dfbeta residuals on the fitter's result give its robust variance bitwise, in a tenth of the time (C2 plan) | DEC-098, `dev/design/COXPH_C2_PLAN.md` §2 |
| `18_fitter_arguments.R` | what `coxph()`'s preprocessing and the row order change in `agreg.fit()`'s results, and how far single timings vary (C2 plan) | `dev/design/COXPH_C2_PLAN.md` §2 |
| `19_survival_inputs.R` | how `Surv()`, `all.vars()`, `model.frame()`, and `model.offset()` treat the inputs the data layer checks (C2 plan) | COXPH_DESIGN §C.1 |
| `20_baseline_offset.R` | which `survival` call gives the baseline at x = 0 and offset 0 of a fit with an offset: `survfit()` there, not `basehaz(centered = FALSE)`, on the full Cox fixture set's two offset cases (C2 plan) | M-28, D-60 |
| `21_fit_time_parts.R` | where the time of `fit_cox_stratified()` goes beyond the fitter it calls: `data_prepare()` and its model frame, design, provider index, and sort; the adapter's inputs; the finite check and the model object (C2 gate) | DEC-105, `dev/bench/results/cox-c2-paired-20261009-windows.md` |
| `22_measures_tests.R`, `.py` | pprof_py's measures and tests written in plain R, against the Cox fixtures: expected counts, person-time, and direct expected counts at pprof_py's coefficients; statistics, p-values, flags, and exact and mid-p limits at its observed and expected counts; the brief's negative controls for the statistic and limit tiers; and the mid-p limits computed once per distinct observed count, timed against pprof_py's on the same data (C3 plan) | DEC-097, `dev/design/COXPH_C3_PLAN.md` §2 |
| `23_funnel_limits.py`, `.R` | pprof_py's own Cox funnel limits (`CoxPH.funnel_limits()`), which agree with its flags, against the limits of M-39 and a plain-R construction of pprof_py's (C3 plan) | M-39, `dev/design/COXPH_C3_PLAN.md` §2 |
| `24_midp_bisection.R` | the package's mid-p limits found by bisection over all the distinct counts at once, against the same roots found with `uniroot()` one count at a time, as the package found them before: the roots agree to rounding, and the search is 4 to 7 times faster (C3 benchmarks) | DEC-110 |

## Running them

From the repository root, with R and Python on the PATH and these environment variables:

- `PPROF_PY`: a checkout of pprof_py at v0.7.0 (commit `9320766`); default `../../pprof_py`. Nothing is written into it: the Python scripts turn off numba's on-disk cache and bytecode files (`pprof_py_env.py`), and the test runs send numba's cache elsewhere.
- `COXPH_FACTS_SCRATCH`: a directory for generated data (about 400 MB) and intermediate results. On Windows give it with forward slashes (`C:/...`), since the Python scripts read it too.
- `NUMBA_CACHE_DIR` (01 and 03 only): where numba caches compiled code during the test runs; default `$COXPH_FACTS_SCRATCH/nbc`. On Windows numba's cache file names are long, so this path should be short (under about 100 characters).
- `PYTHON` (01 and 03 only): the Python interpreter; default `python`.

```sh
f=dev/design/coxph-facts
bash $f/01_pprof_py_suite.sh $f/01_pprof_py_suite.txt
Rscript $f/02_r_reference_drift.R $f/02_r_reference_drift.txt
bash $f/03_glmnet_reference_tests.sh $f/03_glmnet_reference_tests.txt
Rscript $f/04_glmnet_cv_normalization.R $f/04_glmnet_cv_normalization.txt
Rscript $f/05_robust_finegray.R && python $f/05_robust_finegray.py $f/05_robust_finegray.txt
Rscript $f/06_benchmark_data.R $f/06_benchmark_data.txt
Rscript $f/07_cox_fit_timing.R $f/07_cox_fit_timing_r.txt && python $f/07_cox_fit_timing.py $f/07_cox_fit_timing.txt
Rscript $f/08_timefix.R && python $f/08_timefix.py $f/08_timefix.txt
Rscript $f/09_penalized_glmnet.R $f/09_penalized_glmnet_r.txt && python $f/09_penalized_glmnet.py $f/09_penalized_glmnet.txt
Rscript $f/10_provider_indicators.R $f/10_provider_indicators.txt
Rscript $f/11_survival_edge_cases.R $f/11_survival_edge_cases.txt
Rscript $f/12_newton_path.R && python $f/12_newton_path.py $f/12_newton_path.txt
python $f/13_pprof_py_probes.py $f/13_pprof_py_probes.txt
Rscript $f/14_engine_interfaces.R $f/14_engine_interfaces.txt
Rscript $f/15_eigen_cache_blocking.R $f/15_eigen_cache_blocking.txt
Rscript $f/16_lme4_cache_sizes.R $f/16_lme4_cache_sizes.txt
Rscript $f/17_robust_from_fitter.R $f/17_robust_from_fitter.txt
Rscript $f/18_fitter_arguments.R $f/18_fitter_arguments.txt
Rscript --vanilla $f/19_survival_inputs.R $f/19_survival_inputs.txt
Rscript $f/20_baseline_offset.R $f/20_baseline_offset.txt
Rscript $f/21_fit_time_parts.R $f/21_fit_time_parts.txt <data dir>
Rscript $f/22_measures_tests.R $f/22_measures_tests_r.txt && python $f/22_measures_tests.py $f/22_measures_tests.txt
python $f/23_funnel_limits.py && Rscript $f/23_funnel_limits.R $f/23_funnel_limits.txt
Rscript $f/24_midp_bisection.R $f/24_midp_bisection.txt
```

R needs `survival`, `glmnet` and `data.table`, for 15 `Rcpp`, `RcppEigen` and a C++ toolchain, and for 16 the package's dependencies and a C++ toolchain (Rtools on Windows, which 15 and 16 alone need on the PATH; 16 builds lme4 twice and runs the reference suite twice, about 20 minutes); Python needs pprof_py's dependencies (NumPy, SciPy, pandas, numba, fast_poibin) and pytest.

## The run behind the outputs

On 2026-10-07, on one Windows 11 machine (8 logical cores, 7.4 GB of memory): R 4.4.0 with `survival` 3.8-12, `glmnet` 5.1 and `data.table` 1.18.6.1; Python 3.9.7 with NumPy 1.24.4, SciPy 1.13.1, pandas 2.3.3 and numba 0.57.1 (pprof_py declares Python 3.10 or later; every script and test ran under 3.9). Timings vary from run to run: an earlier run, with other work on the machine, was 20–40% slower. The whole set took about 13 minutes. The PATH held R and Git Bash's tools but not Rtools: Rtools' MSYS2 `bash` and `grep` mixed with Git Bash's lose exported variables and garble pipes. Phase C1 of the brief measures again with committed benchmarks in `dev/bench/`. 15 and 16 ran on 2026-10-08 on the same machine (an Intel Family 6 Model 140 processor, Tiger Lake, whose 48 KB L1 data cache Eigen reads) with RcppEigen 0.3.4.0.2, and for 16 lme4 2.0-6 built from the snapshot's source. 17 to 20 ran there on 2026-10-08, one after another, with `survival` 3.8-12 (about 6 minutes; 17 and 18 hold 1,000,000-row data sets in memory, so they should not run alongside other work); 20 reads the full Cox fixture set in `validation/fixtures/cox/`. 21 ran there on 2026-10-09 at commit `464a269` (about 2.5 minutes, with the working tree installed into a temporary library first, as the benchmarks install it); its data are the benchmark generator's (`dev/bench/cox/scenarios.R`), written to the directory it is given, or read from there when present. The machine was paging throughout (about 10,000 pages per second with nothing of the session running, the other applications committing 17 GB on 7.4 GB of memory): the times are medians, and at 1,000,000 rows the fit and the fitter got about three-quarters of a processor each. 22 and 23 ran there on 2026-10-09 at commit `eedc5a1`, with the fixture generator's Python environment (Python 3.12.3, `dev/reference/cox/venv`; `PPROF_PY` the checkout at `9320766`) and R 4.4.0 with `survival` 3.8-12 (about 6 minutes in all, most of it pprof_py's mid-p limits); 22 reads both Cox fixture sets and the benchmark generator's corner-like data (1,000,000 rows, 7,500 providers, 5 covariates), and 23 rebuilds two fixture inputs with the generator's `cases.py`. The machine paged then too (about 1,000 pages per second, 0.4 GB of memory free), so 22's times are indicative; its R and pprof_py mid-p limits ran on the same data within minutes of each other. 24 ran there on 2026-10-09 with the package loaded by `devtools::load_all()` (its code is R alone), after the C3 benchmarks (about 3 minutes).
