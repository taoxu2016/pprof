# Paired benchmark of the Fine-Gray model against its survival calls

Run on 2026-10-16 at commit `085eaeb` (`dev/bench/cox/run_paired.R`, 2 round(s), package code unchanged from the commit): AMD EPYC 7763 64-Core Processor, 4 logical cores; R version 4.4.0 (2024-04-24) with survival 3.8.12; pprof 2.0.0 installed with `--preclean`. The R engines are single-threaded.

From Phase C5 (DEC-127), the Fine-Gray model, on the scenario's data with a second cause derived without random numbers (every third event row), cause 1, Breslow ties, the case weights, and one subject per row: `fine_gray` on `Surv(start, stop, cause)` with the subjects as `id`, `fine_gray_right` on `Surv(stop, cause)`, every entry at 0. Each round runs the engine side, the user's calls, and the fit, each in a fresh process, one after the other. The engine side is the survival calls the fit makes, written out: `finegray()` on each chunk of 50 providers (DEC-122), the case weights multiplied in (DEC-123), the fitter's inputs from the expansion's rows of positive weight, survival's fitter as `coxph()` calls it, and `coxph()`'s robust step clustered by subject (DEC-121); its process then times the preparation of its inputs, `data_prepare()` and the chunks' data frames (the median of three calls). The fit is `fit_fine_gray()` on the data frame, whose coefficients and robust variance must be the engine side's bitwise.

Rule (the brief's §3.7 MUST, DEC-105): a fit is too slow when, in every round, its median and its fastest run are more than 10% above the engine call's plus the preparation of its inputs, and its median at least 0.05 s above (DEC-038). The verdict against the engine call alone, the C2 plan's comparator, is given beside it. The fit's estimates must equal the engine call's bitwise (coefficients, and the robust variance). Times in seconds; peak memory of the process after the first run, in MB (recorded, DEC-004).

- Fits: 5; too slow against the engine call plus the preparation of its inputs (DEC-105): 0.
- Too slow against the engine call alone: 0; failed or differing from the engine call: 0.

## Notes on this run

- **The runner.** GitHub-hosted `ubuntu-24.04`, run 38957683403: AMD EPYC 7763 64-Core Processor, 4 processors, 15.6 GB of memory. Tasks selected with `--only " fine_gray"`, 2 rounds. The pprof_py times beside the package's are C1's and C5's, from the project lead's Windows machine, so their ratios are indicative.

## The fit against its engine call

| Scenario | Rows | Providers | Covariates | Task | Round | Engine median | Fit median | Ratio | Engine fastest | Fit fastest | Ratio | Fit − engine, median | Peak MB, engine / fit | Estimates | Verdict against the engine call alone |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| center | 100,000 | 1,000 | 20 | fine_gray | 1 | 5.17 | 5.41 | 1.047 | 5.01 | 5.28 | 1.053 | 0.242 | 1420 / 1398 | identical |  |
| center | 100,000 | 1,000 | 20 | fine_gray | 2 | 5.11 | 5.29 | 1.036 | 4.96 | 5.28 | 1.066 | 0.186 | 1419 / 1398 | identical | ok |
| center | 100,000 | 1,000 | 20 | fine_gray_right | 1 | 3.76 | 3.89 | 1.033 | 3.42 | 3.81 | 1.114 | 0.124 | 1275 / 1269 | identical |  |
| center | 100,000 | 1,000 | 20 | fine_gray_right | 2 | 3.85 | 3.83 | 0.994 | 3.57 | 3.78 | 1.061 | -0.0226 | 1275 / 1269 | identical | ok |
| providers-100 | 100,000 | 100 | 20 | fine_gray | 1 | 24.6 | 24.9 | 1.010 | 24.4 | 24.5 | 1.003 | 0.252 | 5239 / 5079 | identical |  |
| providers-100 | 100,000 | 100 | 20 | fine_gray | 2 | 24.3 | 24.8 | 1.018 | 24.3 | 24.7 | 1.014 | 0.442 | 5239 / 5079 | identical | ok |
| providers-7500 | 100,000 | 7,500 | 20 | fine_gray_right | 1 | 5.05 | 5.6 | 1.111 | 4.89 | 5.34 | 1.093 | 0.558 | 934 / 882 | identical |  |
| providers-7500 | 100,000 | 7,500 | 20 | fine_gray_right | 2 | 5.09 | 5.61 | 1.101 | 4.91 | 5.38 | 1.096 | 0.516 | 934 / 882 | identical | ok |
| covariates-5 | 100,000 | 1,000 | 5 | fine_gray | 1 | 3.67 | 4.21 | 1.145 | 3.6 | 3.81 | 1.061 | 0.533 | 987 / 994 | identical |  |
| covariates-5 | 100,000 | 1,000 | 5 | fine_gray | 2 | 3.61 | 4.19 | 1.160 | 3.55 | 3.81 | 1.075 | 0.576 | 987 / 994 | identical | ok |

## Where the fit's time goes

The fit's time beyond the engine call, the preparation of the engine's inputs from the data frame, and what is left: the adapter's own steps, the model object, and noise. The last column is the MUST's verdict (DEC-105): DEC-038's rule against the engine call plus the preparation (medians, and fastest runs plus the preparation).

| Scenario | Task | Round | Fit − engine, median | Inputs' preparation, median of 3 | Fit − engine − preparation | Ratio, fit / (engine + preparation), medians | Fastest | Verdict (DEC-105) |
|---|---|---|---|---|---|---|---|---|
| center | fine_gray | 1 | 0.242 | 0.156 | 0.0854 | 1.016 | 1.021 |  |
| center | fine_gray | 2 | 0.186 | 0.152 | 0.0339 | 1.006 | 1.034 | ok |
| center | fine_gray_right | 1 | 0.124 | 0.113 | 0.0108 | 1.003 | 1.078 |  |
| center | fine_gray_right | 2 | -0.0226 | 0.114 | -0.136 | 0.966 | 1.028 | ok |
| providers-100 | fine_gray | 1 | 0.252 | 0.122 | 0.13 | 1.005 | 0.998 |  |
| providers-100 | fine_gray | 2 | 0.442 | 0.121 | 0.322 | 1.013 | 1.009 | ok |
| providers-7500 | fine_gray_right | 1 | 0.558 | 0.427 | 0.131 | 1.024 | 1.005 |  |
| providers-7500 | fine_gray_right | 2 | 0.516 | 0.425 | 0.0914 | 1.017 | 1.009 | ok |
| covariates-5 | fine_gray | 1 | 0.533 | 0.147 | 0.386 | 1.101 | 1.019 |  |
| covariates-5 | fine_gray | 2 | 0.576 | 0.147 | 0.429 | 1.114 | 1.032 | ok |

## The fit against coxph() on the data frame

For the Fine-Gray tasks, the calls a user would make: `finegray()` once, with the provider as strata, the case weights multiplied in after it (its own `weights` argument misapplies them after the first stratum, DEC-123), and `coxph(cluster = subject)` on the rows of positive weight. Reported, not a gate.

| Scenario | Task | Round | coxph() median | Fit median | Ratio, fit / coxph() | Peak MB, coxph() / fit | coxph()'s largest relative difference from the engine call |
|---|---|---|---|---|---|---|---|
| center | fine_gray | 1 | 23.1 | 5.41 | 0.234 | 2181 / 1398 | 0 |
| center | fine_gray | 2 | 23 | 5.29 | 0.230 | 2168 / 1398 | 0 |
| center | fine_gray_right | 1 | 17.6 | 3.89 | 0.220 | 1716 / 1269 | 0 |
| center | fine_gray_right | 2 | 18.1 | 3.83 | 0.212 | 1716 / 1269 | 0 |
| providers-100 | fine_gray | 1 | 50.3 | 24.9 | 0.494 | 9414 / 5079 | 0 |
| providers-100 | fine_gray | 2 | 48.9 | 24.8 | 0.506 | 9414 / 5079 | 0 |
| providers-7500 | fine_gray_right | 1 | 97.3 | 5.6 | 0.058 | 1024 / 882 | 0 |
| providers-7500 | fine_gray_right | 2 | 97.5 | 5.61 | 0.058 | 1021 / 882 | 0 |
| covariates-5 | fine_gray | 1 | 19 | 4.21 | 0.221 | 1296 / 994 | 0 |
| covariates-5 | fine_gray | 2 | 19.2 | 4.19 | 0.218 | 1281 / 994 | 0 |

## The fits beside C1's baseline

C1's engine calls (`cox-engines-20261008-windows.csv`: `agreg.fit()` on the rows in the generator's order with the raw offset, and for robust `coxph(cluster = row)`, DEC-100) and pprof_py 0.7.0 on Python 3.12.3 with numba's default threads (8, `cox-pprof_py-20261008-windows.csv`), measured in another session, so the ratios are indicative only. The brief's §3.7 SHOULD (no slower than pprof_py) applies to the robust variance, not to the fits at large sizes (DEC-098). The fit's time is the median of its rounds' medians. For the penalized tasks, C1's glmnet path used glmnet's own grid, and its 10-fold cross-validation fitted 11 paths and evaluated `coxnet.deviance()` on all rows only.

pprof_py's times of the tasks it ran again come from `cox-c5-pprof_py-20261015-windows.csv`, run on 2026-10-15 with numba's default threads (8); "raises" marks a task whose pprof_py run raised an error, such as the `FloatingPointError` of D-80 where survival's weights are not finite.

| Scenario | Task | Fit median | C1 engine median | pprof_py median | Ratio, fit / pprof_py |
|---|---|---|---|---|---|
| center | fine_gray | 5.35 | - | 3.82 | 1.401 |
| center | fine_gray_right | 3.86 | - | 3.27 | 1.182 |
| providers-100 | fine_gray | 24.8 | - | - | - |
| providers-7500 | fine_gray_right | 5.61 | - | 5.04 | 1.112 |
| covariates-5 | fine_gray | 4.2 | - | raises | - |

## The Fine-Gray fits' expansions and objects

Recorded, not a gate (DEC-127): the expanded rows that the fit gives survival's fitter (those of positive weight; the engine side's must be the same), the size of the fit's object (`object.size()`, without the data, `keep_data = FALSE`), and the peak memory of each side's process after its first run, in MB.

| Scenario | Task | Round | Expanded rows, fit / engine | Object MB | Peak MB, engine / fit |
|---|---|---|---|---|---|
| center | fine_gray | 1 | 687,533 / 687,533 | 5.49 | 1420 / 1398 |
| center | fine_gray | 2 | 687,533 / 687,533 | 5.49 | 1419 / 1398 |
| center | fine_gray_right | 1 | 571,986 / 571,986 | 5.49 | 1275 / 1269 |
| center | fine_gray_right | 2 | 571,986 / 571,986 | 5.49 | 1275 / 1269 |
| providers-100 | fine_gray | 1 | 4,296,722 / 4,296,722 | 5.4 | 5239 / 5079 |
| providers-100 | fine_gray | 2 | 4,296,722 / 4,296,722 | 5.4 | 5239 / 5079 |
| providers-7500 | fine_gray_right | 1 | 165,301 / 165,301 | 6.14 | 934 / 882 |
| providers-7500 | fine_gray_right | 2 | 165,301 / 165,301 | 6.14 | 934 / 882 |
| covariates-5 | fine_gray | 1 | 726,019 / 726,019 | 5.47 | 987 / 994 |
| covariates-5 | fine_gray | 2 | 726,019 / 726,019 | 5.47 | 987 / 994 |
