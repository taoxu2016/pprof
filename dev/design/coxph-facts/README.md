# CoxPH facts

The scripts behind the evidence in the CoxPH phase brief (`dev/coxph_brief.md`, Appendices A and B), its Phase C0 design (`dev/design/COXPH_DESIGN.md`), and the Phase C2 to C6 plans (`dev/design/COXPH_C2_PLAN.md` to `dev/design/COXPH_C6_PLAN.md`), with the output each one produced. They compare pprof_py v0.7.0 with R's `survival` and `glmnet` and time them; 15 explains a CI failure found at the C0 gate. None of them is part of the package or its tests.

Each numbered script writes the output file of the same name (`.txt`). Where an R script and a Python script share a number, the R script runs first and leaves its results in the scratch directory, and the Python script compares and writes the output (07, 09, and 22 also write an R output, `_r.txt`); for 23 and 26 the order is reversed: the Python script runs pprof_py, and the R script compares and writes the output. In 31 and 33 each side writes its own output, the R script's `_r.txt`; 31's two sides are independent, and 33's Python script reads the data its R script writes to the scratch directory.

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
| `25_fit_measures_parts.R` | the fit with its measures against the engine call, its inputs' preparation, and the plain-R measures, interleaved in one process, and the parts of the measures: where the C3 paired run's two fits too slow stand against DEC-105's line (C3 benchmarks) | DEC-105, DEC-111, `dev/bench/results/cox-c3-paired-20261009-windows.md` |
| `26_penalized_grid.py`, `.R` | pprof_py's λ grid written in plain R from engine calls (`glmnet`'s `coxgrad()` for the score at the null point, survival's fitter for unpenalized columns), and `glmnet`'s paths on it, against pprof_py's grids and paths on the penalized fixtures and on settings they lack (a constant column, ridge, no standardization, given and short grids, unequal penalty factors, one covariate); `glmnet` stopping early, or diverging with Efron ties, on data with few events per covariate (C4 plan) | K-143, D-72, `dev/design/COXPH_C4_PLAN.md` §2 |
| `27_penalized_cv.R` | pprof_py's cross-validation from `glmnet`'s fold paths on the two penalized fixtures that hold it, with the partial likelihood from survival's fitter, `coxph()`, or `coxnet.deviance()` one grid point at a time or all at once (with the saturated term moved to pprof_py's), against the generator's R side and pprof_py (C4 plan) | K-144, M-30, `dev/design/COXPH_C4_PLAN.md` §2 |
| `28_penalized_cost.R` | the cost of a penalized path and of the parts of a cross-validation on the benchmark's `covariates-50` scenario, and the estimated time of a 10-fold cross-validation with each source of the partial likelihood (C4 plan) | the brief's §3.7, `dev/design/COXPH_C4_PLAN.md` §2 |
| `29_penalized_fit_parts.R` | `fit_cox_penalized()` and `select_lambda()` against their `glmnet` calls and their inputs' preparation, interleaved in one process, with the adapter's call beside `glmnet`'s own: where the C4 paired run's results on `covariates-50` stand against DEC-105's line (C4 benchmarks) | DEC-105, DEC-118, `dev/bench/results/cox-c4-paired-20261014-windows.md` |
| `30_penalized_cv_parts.R` | the parts of `select_lambda()`'s loop against those of the plain-R cross-validation, timed apart and interleaved fold by fold on `covariates-50`, with their results checked identical (C4 benchmarks) | DEC-105, DEC-118 |
| `31_finegray_inputs.R`, `.py` | what `Surv()` and `finegray()` do with the Fine–Gray model's inputs, and pprof_py's transform on the same data: a status with several event types; case weights, which survival 3.8-12's `finegray()` applies to the wrong rows after its first stratum; zero weights; a provider without events of the cause; `etype`, `id`, one event type, and `timefix`; delayed entry decided over all rows, so that a call per provider can differ; weights that are not finite with delayed entry in small providers, where pprof_py raises (C5 plan) | K-145, M-23, M-25, D-74, `dev/design/COXPH_C5_PLAN.md` §2 |
| `32_finegray_engine.R` | the Fine–Gray fit from survival's calls on the two competing-risk fixtures: `finegray()`, the fitter, and the robust step against `coxph(cluster = id)`, the fixtures' survival records, and pprof_py; the cumulative incidence from `survfit()` of a `coxph()` object built as the package builds one; pprof_py's log-likelihoods against survival's (C5 plan) | DEC-099, DEC-100, D-56, D-57, `dev/design/COXPH_C5_PLAN.md` §2 |
| `33_finegray_cost.R`, `.py` | the cost of the Fine–Gray fit's survival calls on the benchmark's data with a derived second cause (`finegray()` stratified and once per provider, the fitter, the robust step, and `coxph(cluster = id)`), and pprof_py's `FineGrayPH` on the same data (C5 plan) | the brief's §3.7, `dev/design/COXPH_C5_PLAN.md` §2 |
| `34_finegray_profile.R` | where `finegray()`'s time goes, by `Rprof`, and the size of its expansion at 1,000 rows per provider (C5 plan) | the brief's §3.7, `dev/design/COXPH_C5_PLAN.md` §2 |
| `35_finegray_chunks.R` | `finegray()` once per chunk of providers, each chunk deciding delayed entry as all rows do, against one call stratified by provider: identical outputs and their times (C5 plan) | DEC-122, `dev/design/COXPH_C5_PLAN.md` §2.3 |
| `36_tarball_parts.R` | where the package tarball's bytes go, the built vignettes' images, the bundled data resaved with gzip, bzip2, and xz, and a plot at 96 and 72 dpi (C6 plan) | `dev/design/COXPH_C6_PLAN.md` §2.1 |
| `37_vignette_prototype.R` | the computations a vignette on time-to-event outcomes would show, timed, on data derived from `ExampleDataBinary`, with the fit against `coxph()` (C6 plan) | the brief's §8, `dev/design/COXPH_C6_PLAN.md` §2.2 |
| `38_input_sweep.R` | 72 invalid calls to the Cox functions and their methods, and the condition each raises (C6 plan) | `dev/design/COXPH_C6_PLAN.md` §2.4 |
| `39_simulation_replicate.R` | a simulation of the Cox model's mid-p and exact tests and limits with provider strata, three scenarios, 100 replicates each (C6 plan) | the brief's §6 D, `dev/design/COXPH_C6_PLAN.md` §2.5 |
| `40_guide_dry_run.md` | not a script: the report of a subagent without the session's context, which designed two later models (frailty Cox profiling, discrete-time provider models) from the developer guide, "Adding a model to pprof", and ARCHITECTURE §E alone, with the gaps it found, and what changed in response (C6 plan) | the brief's §11 item 7, `dev/design/COXPH_C6_PLAN.md` §3.5 |

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
Rscript $f/25_fit_measures_parts.R $f/25_fit_measures_parts.txt <data dir>
python $f/26_penalized_grid.py && Rscript $f/26_penalized_grid.R $f/26_penalized_grid.txt
Rscript $f/27_penalized_cv.R $f/27_penalized_cv.txt
Rscript $f/28_penalized_cost.R $f/28_penalized_cost.txt
Rscript $f/29_penalized_fit_parts.R $f/29_penalized_fit_parts.txt <data dir>
Rscript $f/30_penalized_cv_parts.R $f/30_penalized_cv_parts.txt <data dir>
Rscript $f/31_finegray_inputs.R $f/31_finegray_inputs_r.txt && python $f/31_finegray_inputs.py $f/31_finegray_inputs.txt
Rscript $f/32_finegray_engine.R $f/32_finegray_engine.txt
Rscript $f/33_finegray_cost.R $f/33_finegray_cost_r.txt && python $f/33_finegray_cost.py $f/33_finegray_cost.txt
Rscript $f/34_finegray_profile.R $f/34_finegray_profile.txt
Rscript $f/35_finegray_chunks.R $f/35_finegray_chunks.txt
Rscript $f/36_tarball_parts.R $f/36_tarball_parts.txt <dir>/build/pprof_2.0.0.tar.gz <dir>/build-best/pprof_2.0.0.tar.gz
Rscript $f/37_vignette_prototype.R $f/37_vignette_prototype.txt
Rscript $f/38_input_sweep.R $f/38_input_sweep.txt
Rscript $f/39_simulation_replicate.R $f/39_simulation_replicate.txt 100
```

36 to 39 load the package from the library `PPROF_FACTS_LIB` when it is set (a release build: `R CMD INSTALL --preclean -l <library> <tarball>`), and with `devtools::load_all()` otherwise; 36 reads the tarballs of `R CMD build <repository>` and `R CMD build --resave-data=best <repository>`, each built into a directory of its own.

R needs `survival`, `glmnet` and `data.table`, for 15 `Rcpp`, `RcppEigen` and a C++ toolchain, and for 16 the package's dependencies and a C++ toolchain (Rtools on Windows, which 15 and 16 alone need on the PATH; 16 builds lme4 twice and runs the reference suite twice, about 20 minutes); Python needs pprof_py's dependencies (NumPy, SciPy, pandas, numba, fast_poibin) and pytest.

## The run behind the outputs

On 2026-10-07, on one Windows 11 machine (8 logical cores, 7.4 GB of memory): R 4.4.0 with `survival` 3.8-12, `glmnet` 5.1 and `data.table` 1.18.6.1; Python 3.9.7 with NumPy 1.24.4, SciPy 1.13.1, pandas 2.3.3 and numba 0.57.1 (pprof_py declares Python 3.10 or later; every script and test ran under 3.9). Timings vary from run to run: an earlier run, with other work on the machine, was 20–40% slower. The whole set took about 13 minutes. The PATH held R and Git Bash's tools but not Rtools: Rtools' MSYS2 `bash` and `grep` mixed with Git Bash's lose exported variables and garble pipes. Phase C1 of the brief measures again with committed benchmarks in `dev/bench/`. 15 and 16 ran on 2026-10-08 on the same machine (an Intel Family 6 Model 140 processor, Tiger Lake, whose 48 KB L1 data cache Eigen reads) with RcppEigen 0.3.4.0.2, and for 16 lme4 2.0-6 built from the snapshot's source. 17 to 20 ran there on 2026-10-08, one after another, with `survival` 3.8-12 (about 6 minutes; 17 and 18 hold 1,000,000-row data sets in memory, so they should not run alongside other work); 20 reads the full Cox fixture set in `validation/fixtures/cox/`. 21 ran there on 2026-10-09 at commit `464a269` (about 2.5 minutes, with the working tree installed into a temporary library first, as the benchmarks install it); its data are the benchmark generator's (`dev/bench/cox/scenarios.R`), written to the directory it is given, or read from there when present. The machine was paging throughout (about 10,000 pages per second with nothing of the session running, the other applications committing 17 GB on 7.4 GB of memory): the times are medians, and at 1,000,000 rows the fit and the fitter got about three-quarters of a processor each. 22 and 23 ran there on 2026-10-09 at commit `eedc5a1`, with the fixture generator's Python environment (Python 3.12.3, `dev/reference/cox/venv`; `PPROF_PY` the checkout at `9320766`) and R 4.4.0 with `survival` 3.8-12 (about 6 minutes in all, most of it pprof_py's mid-p limits); 22 reads both Cox fixture sets and the benchmark generator's corner-like data (1,000,000 rows, 7,500 providers, 5 covariates), and 23 rebuilds two fixture inputs with the generator's `cases.py`. The machine paged then too (about 1,000 pages per second, 0.4 GB of memory free), so 22's times are indicative; its R and pprof_py mid-p limits ran on the same data within minutes of each other. 24 ran there on 2026-10-09 with the package loaded by `devtools::load_all()` (its code is R alone), after the C3 benchmarks (about 3 minutes). 25 ran there on 2026-10-09 at commit `3ed22dd`, the same way, on the benchmark data (about 4 minutes), with the machine paging as during the benchmarks. 26 to 28 ran there on 2026-10-14 at commit `38dad40`, with R 4.4.0, `survival` 3.8-12, and `glmnet` 5.1, and for 26 the fixture generator's Python environment with pprof_py at `9320766` (about 3 minutes in all). 26 and 27 read both Cox fixture sets, and 26 reads two of pprof_py's vendored inputs (`dev/reference/cox/inputs/pprof_py`); 28 builds the benchmark generator's `covariates-50` data in memory. The machine paged (0.7 GB of 7.4 GB free, 17.5 GB committed), and two runs of 28 differed by up to 40%, so its times are indicative; the output is the second run. 31 to 35 ran there on 2026-10-14 on `coxph/phase-5`, from `main` at `4c7b028`, with R 4.4.0 and `survival` 3.8-12, and for 31 and 33 the fixture generator's Python environment with pprof_py at `9320766` (about 40 minutes in all, most of it the single `finegray()` calls on `providers-7500` in 33 and 35). 32 and 35 read both Cox fixture sets; 31, 33, 34, and 35 build the benchmark generator's data in memory, and 33 also writes them to the scratch directory for its Python side. The machine paged (0.6 to 0.9 GB of 7.4 GB free), so elapsed times ran 1.5 to 2.7 times the processor times, which the outputs give beside them.

36 to 39 ran there on 2026-10-15 and 2026-10-16 on `coxph/phase-6` at `a919c0b` (the package code of `main` at `8023d8f`), with R 4.4.0, `survival` 3.8-12, `glmnet` 5.1, lme4 2.0-6, and Matrix 1.7-6, against a release build of the package installed into a scratch library (`PPROF_FACTS_LIB`), in a few minutes in all. The tarballs of 36 were built from that commit; both held a stray `build.log` of 57 bytes at the top level, a log of a failed build attempt, deleted afterwards. 0.8 to 1.1 GB of the 7.4 GB of memory was free, so 37's and 39's times are indicative.
