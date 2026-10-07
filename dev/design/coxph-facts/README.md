# CoxPH facts

The scripts behind the evidence in the CoxPH phase brief (`dev/coxph_brief.md`, Appendices A and B), with the output each one produced. They compare pprof_py v0.7.0 with R's `survival` and `glmnet` and time them; none of them is part of the package or its tests.

Each numbered script writes the output file of the same name (`.txt`). Where an R script and a Python script share a number, the R script runs first and leaves its results in the scratch directory, and the Python script compares and writes the output (07 and 09 also write an R output, `_r.txt`).

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
```

R needs `survival`, `glmnet` and `data.table`; Python needs pprof_py's dependencies (NumPy, SciPy, pandas, numba, fast_poibin) and pytest.

## The run behind the outputs

On 2026-10-07, on one Windows 11 machine (8 logical cores, 7.4 GB of memory): R 4.4.0 with `survival` 3.8-12, `glmnet` 5.1 and `data.table` 1.18.6.1; Python 3.9.7 with NumPy 1.24.4, SciPy 1.13.1, pandas 2.3.3 and numba 0.57.1 (pprof_py declares Python 3.10 or later; every script and test ran under 3.9). Timings vary from run to run: an earlier run, with other work on the machine, was 20–40% slower. The whole set took about 13 minutes. The PATH held R and Git Bash's tools but not Rtools: Rtools' MSYS2 `bash` and `grep` mixed with Git Bash's lose exported variables and garble pipes. Phase C1 of the brief measures again with committed benchmarks in `dev/bench/`.
