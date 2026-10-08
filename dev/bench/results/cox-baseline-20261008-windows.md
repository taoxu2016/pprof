# Cox benchmark baseline

Run on 2026-10-08 at commit `69d007d` (`dev/bench/cox/`): Intel64 Family 6 Model 140 Stepping 1, GenuineIntel, 8 logical cores; R version 4.4.0 (2024-04-24 ucrt) with survival 3.8.12 and glmnet 5.1;
pprof_py 0.7.0 on Python 3.12.3 with numba's default threads (8). Medians in seconds; peak memory of the
process after the first run, in MB. The R engines are single-threaded.

## Fits

| Scenario | Rows | Providers | Covariates | agreg.fit Breslow | agreg.fit Efron | coxph() robust | pprof_py Breslow | pprof_py Efron | pprof_py robust | Peak MB, engine / pprof_py |
|---|---|---|---|---|---|---|---|---|---|---|
| center | 100,000 | 1,000 | 20 | 0.88 | 0.82 | 3.24 | 1.15 | 1.22 | 1.11 | 302 / 246 |
| rows-1e4 | 10,000 | 1,000 | 20 | 0.08 | 0.11 | 0.18 | 0.37 | 0.42 | 0.40 | 222 / 184 |
| rows-1e6 | 1,000,000 | 1,000 | 20 | 17.17 | 22.28 | 129.75 | 4.30 | 6.83 | 5.24 | 641 / 821 |
| providers-100 | 100,000 | 100 | 20 | 1.29 | 2.89 | 2.70 | 0.38 | 0.59 | 0.44 | 302 / 239 |
| providers-7500 | 100,000 | 7,500 | 20 | 0.86 | 0.84 | 2.85 | 3.65 | 4.02 | 3.73 | 313 / 275 |
| covariates-5 | 100,000 | 1,000 | 5 | 0.26 | 0.23 | 1.55 | 0.64 | 0.69 | 0.84 | 266 / 211 |
| covariates-50 | 100,000 | 1,000 | 50 | 3.37 | 5.34 | 8.84 | 1.67 | 3.53 | 1.83 | 414 / 316 |
| corner | 1,000,000 | 7,500 | 50 | 39.33 | 42.45 | 251.30 | 24.49 | 117.18 | 18.74 | 1755 / 1137 |

## Measures and tests

| Scenario | Providers | Expected counts, R closed form | pprof_py measures (indirect and direct) | pprof_py mid-p test with limits | pprof_py exact test with limits |
|---|---|---|---|---|---|
| center | 1,000 | 0.039 | 0.122 | 10.66 | 0.101 |
| rows-1e4 | 1,000 | 0.004 | 0.009 | 9.14 | 0.013 |
| rows-1e6 | 1,000 | 0.383 | 1.317 | 14.51 | 1.377 |
| providers-100 | 100 | 0.034 | 0.092 | 1.45 | 0.095 |
| providers-7500 | 7,500 | 0.032 | 0.128 | 83.44 | 0.119 |
| covariates-5 | 1,000 | 0.034 | 0.092 | 12.54 | 0.097 |
| covariates-50 | 1,000 | 0.034 | 0.106 | 14.15 | 0.162 |
| corner | 7,500 | 0.366 | 1.441 | 116.07 | 1.516 |

## Penalized paths (lasso, 100 lambda values)

| Scenario | glmnet path (thresh 1e-12) | glmnet 10-fold CV | pprof_py path | pprof_py 10-fold CV |
|---|---|---|---|---|
| covariates-50 | 14.30 | 204.06 | 89.92 | 1716.53 |

## Targets for the package (CoxPH brief §3.7)

- A Cox fit is at most 10% slower than the engine call it wraps (the `agreg.fit` and `coxph()` columns), measured in the same session with dev/bench/run_paired.R's pairing (DEC-038).
- The measures should cost about what the R closed form costs, a fraction of the fit, and no more than pprof_py's.
- Mid-p limits must be substantially faster than pprof_py's (the mid-p column).
- Peak memory is recorded with every timing; objects stay compact (DEC-004).

## Notes

- rows-1e6 expected_counts: ok (rerun: the first attempt failed to open a callr temporary file)
- pprof_py with one numba thread (`cox-pprof_py-20261008-windows-1thread.csv`): rows-1e6 coxph_breslow 4.56 s (4.30 s with 8 threads); rows-1e6 coxph_robust_breslow 5.56 s (5.24 s with 8 threads).
