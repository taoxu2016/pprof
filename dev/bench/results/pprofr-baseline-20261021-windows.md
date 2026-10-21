# pprofR benchmark baseline

Generated from `pprofr-baseline-20261021-windows.csv` by `dev/bench/pprofr/summarize.R`. Measured 2026-10-21 15:50:14 UTC on R version 4.4.0 (2024-04-24 ucrt), Windows 11 x64 (build 22621), 8 cores (Intel64 Family 6 Model 140 Stepping 1, GenuineIntel), at commit e69c2b5; pprofR 0.2.0 (commit f23c288) from its isolated library, one thread.

Each task ran in a fresh R process (`dev/bench/pprofr/run_pprofr.R`): the median of 5 timed runs, 3 when the first took 10 s or more, and the first run alone when it took 60 s or more. Fits and other inputs were made untimed in the same process. The comparisons of Phases L2 to L4 measure pprofR again beside the package, in the same process (DEC-038); this baseline records the scale and the cost of each task.

## Scenarios

| Scenario | Rows | Providers | Trials a row | Covariates |
|---|---|---|---|---|
| centre | 100,000 | 1,000 | 10 | 5 |
| binary | 100,000 | 1,000 | 1 | 5 |
| trials-100 | 100,000 | 1,000 | 100 | 5 |
| rows-1e4 | 10,000 | 100 | 10 | 5 |
| rows-1e6 | 1,000,000 | 1,000 | 10 | 5 |
| covariates-20 | 100,000 | 1,000 | 10 | 20 |

## Median time (s)

| Task | centre | binary | trials-100 | rows-1e4 | rows-1e6 | covariates-20 |
|---|---|---|---|---|---|---|
| prep | 0.0399 | 0.0433 | 0.0407 | 0.00496 | 0.411 | 0.072 |
| fit_serbin | 0.207 | 0.176 | 0.185 | 0.0299 | 1.97 | 0.539 |
| fit_ban | 0.333 | 0.28 | 0.421 | 0.0264 | 3.07 | 0.625 |
| vcov | 0.03 | 0.0169 | 0.0163 | 0.00189 | 0.213 | 0.122 |
| test_exact | 80.8 (1 run) | 0.841 | skipped | 7.08 | skipped | 70.2 (1 run) |
| test_exact_one | 0.124 | 0.00989 | 9.01 | 0.324 | 6.36 | 0.069 |
| test_bootstrap | 88 (1 run) | 72.9 (1 run) | 148 (1 run) | 12.6 | skipped | 81.5 (1 run) |
| test_score | 0.038 | 0.0483 | 0.0463 | 0.00403 | 0.412 | 0.0544 |
| test_wald | 0.0204 | 0.0146 | 0.0278 | 0.00177 | 0.195 | 0.0968 |
| test_robust_wald | 0.0337 | 0.0351 | 0.0422 | 0.00302 | 0.442 | 0.0416 |
| test_stabilized_wald | 0.0406 | 0.0378 | 0.0334 | 0.00486 | 0.384 | 0.035 |
| test_robust_score | 0.033 | 0.0355 | 0.0341 | 0.00534 | 0.381 | 0.0327 |
| test_stabilized_score | 0.0417 | 0.0438 | 0.0337 | 0.00975 | 0.39 | 0.0389 |
| covar_wald | 0.0184 | 0.0186 | 0.0156 | 0.00376 | 0.164 | 0.0864 |
| covar_robust_wald | 0.0626 | 0.0664 | 0.0573 | 0.00684 | 0.602 | 0.173 |
| confint_exact | skipped | 28.1 | skipped | 305 (1 run) | skipped | skipped |
| confint_exact_one | 2.3 | 0.0504 | 383 (1 run) | 2.75 | 260 (1 run) | 2.71 |
| confint_score | 0.402 | 0.45 | 0.792 | 0.0446 | 3.33 | 0.369 |
| confint_wald | 0.0342 | 0.0194 | 0.0446 | 0.00438 | 0.383 | 0.074 |
| sr | 0.216 | 0.161 | 0.446 | 0.00781 | 2.56 | 0.154 |
| direct_exp | 0.187 | 0.535 | 0.326 | 0.00299 | 3.11 | 0.145 |
| test_sm | 0.00145 | 0.00242 | 0.00205 | 0.00068 | 0.00272 | 0.00143 |

## Peak memory of the process (MB), largest over the tasks

| Scenario | Peak |
|---|---|
| binary | 196 |
| centre | 209 |
| covariates-20 | 253 |
| rows-1e4 | 149 |
| rows-1e6 | 684 |
| trials-100 | 212 |

## Tasks not run

- centre, confint_exact: skipped (m T^2 = 1e+09, more than 1e8 (see confint_exact_one)).
- trials-100, test_exact: skipped (a provider has 10000 trials: the Poisson-binomial distribution costs O(T^2) per provider (see test_exact_one)).
- trials-100, confint_exact: skipped (m T^2 = 1e+11, more than 1e8 (see confint_exact_one)).
- rows-1e6, test_exact: skipped (a provider has 10000 trials: the Poisson-binomial distribution costs O(T^2) per provider (see test_exact_one)).
- rows-1e6, test_bootstrap: skipped (1e+10 draws (rows times 10,000 resamples)).
- rows-1e6, confint_exact: skipped (m T^2 = 1e+11, more than 1e8 (see confint_exact_one)).
- covariates-20, confint_exact: skipped (m T^2 = 1e+09, more than 1e8 (see confint_exact_one)).
