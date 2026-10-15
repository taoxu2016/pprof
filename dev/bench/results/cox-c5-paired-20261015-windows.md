# Paired benchmark of the Fine-Gray model against its survival calls

Run on 2026-10-15 at commit `3904480` (`dev/bench/cox/run_paired.R`, 2 round(s), package code unchanged from the commit): Intel64 Family 6 Model 140 Stepping 1, GenuineIntel, 8 logical cores; R version 4.4.0 (2024-04-24 ucrt) with survival 3.8.12; pprof 2.0.0 installed with `--preclean`. The R engines are single-threaded.

From Phase C5 (DEC-127), the Fine-Gray model, on the scenario's data with a second cause derived without random numbers (every third event row), cause 1, Breslow ties, the case weights, and one subject per row: `fine_gray` on `Surv(start, stop, cause)` with the subjects as `id`, `fine_gray_right` on `Surv(stop, cause)`, every entry at 0. Each round runs the engine side, the user's calls, and the fit, each in a fresh process, one after the other. The engine side is the survival calls the fit makes, written out: `finegray()` on each chunk of 50 providers (DEC-122), the case weights multiplied in (DEC-123), the fitter's inputs from the expansion's rows of positive weight, survival's fitter as `coxph()` calls it, and `coxph()`'s robust step clustered by subject (DEC-121); its process then times the preparation of its inputs, `data_prepare()` and the chunks' data frames (the median of three calls). The fit is `fit_fine_gray()` on the data frame, whose coefficients and robust variance must be the engine side's bitwise.

Rule (the brief's §3.7 MUST, DEC-105): a fit is too slow when, in every round, its median and its fastest run are more than 10% above the engine call's plus the preparation of its inputs, and its median at least 0.05 s above (DEC-038). The verdict against the engine call alone, the C2 plan's comparator, is given beside it. The fit's estimates must equal the engine call's bitwise (coefficients, and the robust variance). Times in seconds; peak memory of the process after the first run, in MB (recorded, DEC-004).

- Fits: 3; too slow against the engine call plus the preparation of its inputs (DEC-105): 0.
- Too slow against the engine call alone: 0; failed or differing from the engine call: 0.

## Notes on this run

- **The tasks.** The Fine–Gray model's two tasks (DEC-127): `fine_gray` on center and covariates-5, and `fine_gray_right` on center, two rounds, from 14:12 to 14:40; then pprof_py's `FineGrayPH` on the same data, from 14:40 to 14:42 (`cox-c5-pprof_py-20261015-windows.csv`), with `fine_gray_right` on providers-7500 too, whose package side runs on the GitHub runner with providers-100 (`cox-bench.yaml`). The stratified and elastic-net Cox fits were not measured again: C5 changed none of their code.
- **The machine paged throughout.** Free memory averaged 1.08 GB (0.44 GB at least), with 19.9 GB committed on 7.4 GB, and paging averaged 2,500 pages per second (up to 26,700).
- **The estimates.** Every fit's coefficients and robust variance equal its engine side's bitwise, and so do those of the user's calls, one stratified `finegray()` call followed by `coxph(cluster = subject)`: the chunks of providers give that call's expansion (DEC-122), and the fitter and robust step give `coxph()`'s fit (DEC-121).
- **Beside pprof_py.** On center the fit takes about 10.5 s, against pprof_py's 3.8 s on numba's 8 threads, and with every entry at 0 about 8.0 s against 3.3 s: the brief's §3.7 SHOULD is not met, as the C5 plan expected (DEC-122, DEC-098). The time is the survival calls': the engine side alone takes 10.1 to 11.1 s on center. On covariates-5 pprof_py raises `FloatingPointError` (D-80), where the package fits in 6.6 to 7.7 s.

## The fit against its engine call

| Scenario | Rows | Providers | Covariates | Task | Round | Engine median | Fit median | Ratio | Engine fastest | Fit fastest | Ratio | Fit − engine, median | Peak MB, engine / fit | Estimates | Verdict against the engine call alone |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| center | 100,000 | 1,000 | 20 | fine_gray | 1 | 10.1 | 10.7 | 1.061 | 9.87 | 10.3 | 1.041 | 0.614 | 915 / 938 | identical |  |
| center | 100,000 | 1,000 | 20 | fine_gray | 2 | 11.1 | 10.3 | 0.929 | 10.9 | 9.77 | 0.899 | -0.792 | 971 / 939 | identical | ok |
| center | 100,000 | 1,000 | 20 | fine_gray_right | 1 | 7.53 | 8.12 | 1.079 | 7.12 | 7.35 | 1.032 | 0.593 | 860 / 844 | identical |  |
| center | 100,000 | 1,000 | 20 | fine_gray_right | 2 | 7.57 | 7.91 | 1.045 | 7.24 | 6.81 | 0.941 | 0.337 | 847 / 847 | identical | ok |
| covariates-5 | 100,000 | 1,000 | 5 | fine_gray | 1 | 8.69 | 7.74 | 0.891 | 7.7 | 7.63 | 0.991 | -0.945 | 582 / 588 | identical |  |
| covariates-5 | 100,000 | 1,000 | 5 | fine_gray | 2 | 7.11 | 6.65 | 0.936 | 6.62 | 5.49 | 0.830 | -0.457 | 587 / 590 | identical | ok |

## Where the fit's time goes

The fit's time beyond the engine call, the preparation of the engine's inputs from the data frame, and what is left: the adapter's own steps, the model object, and noise. The last column is the MUST's verdict (DEC-105): DEC-038's rule against the engine call plus the preparation (medians, and fastest runs plus the preparation).

| Scenario | Task | Round | Fit − engine, median | Inputs' preparation, median of 3 | Fit − engine − preparation | Ratio, fit / (engine + preparation), medians | Fastest | Verdict (DEC-105) |
|---|---|---|---|---|---|---|---|---|
| center | fine_gray | 1 | 0.614 | 0.392 | 0.222 | 1.021 | 1.001 |  |
| center | fine_gray | 2 | -0.792 | 0.605 | -1.4 | 0.880 | 0.852 | ok |
| center | fine_gray_right | 1 | 0.593 | 0.302 | 0.291 | 1.037 | 0.990 |  |
| center | fine_gray_right | 2 | 0.337 | 0.279 | 0.0587 | 1.007 | 0.906 | ok |
| covariates-5 | fine_gray | 1 | -0.945 | 0.492 | -1.44 | 0.843 | 0.932 |  |
| covariates-5 | fine_gray | 2 | -0.457 | 0.45 | -0.907 | 0.880 | 0.777 | ok |

## The fit against coxph() on the data frame

For the Fine-Gray tasks, the calls a user would make: `finegray()` once, with the provider as strata, the case weights multiplied in after it (its own `weights` argument misapplies them after the first stratum, DEC-123), and `coxph(cluster = subject)` on the rows of positive weight. Reported, not a gate.

| Scenario | Task | Round | coxph() median | Fit median | Ratio, fit / coxph() | Peak MB, coxph() / fit | coxph()'s largest relative difference from the engine call |
|---|---|---|---|---|---|---|---|
| center | fine_gray | 1 | 44 | 10.7 | 0.244 | 1538 / 938 | 0 |
| center | fine_gray | 2 | 44.8 | 10.3 | 0.230 | 1632 / 939 | 0 |
| center | fine_gray_right | 1 | 32.4 | 8.12 | 0.250 | 1477 / 844 | 0 |
| center | fine_gray_right | 2 | 31.8 | 7.91 | 0.249 | 1519 / 847 | 0 |
| covariates-5 | fine_gray | 1 | 38.7 | 7.74 | 0.200 | 803 / 588 | 0 |
| covariates-5 | fine_gray | 2 | 34.3 | 6.65 | 0.194 | 843 / 590 | 0 |

## The fits beside C1's baseline

C1's engine calls (`cox-engines-20261008-windows.csv`: `agreg.fit()` on the rows in the generator's order with the raw offset, and for robust `coxph(cluster = row)`, DEC-100) and pprof_py 0.7.0 on Python 3.12.3 with numba's default threads (8, `cox-pprof_py-20261008-windows.csv`), measured in another session, so the ratios are indicative only. The brief's §3.7 SHOULD (no slower than pprof_py) applies to the robust variance, not to the fits at large sizes (DEC-098). The fit's time is the median of its rounds' medians. For the penalized tasks, C1's glmnet path used glmnet's own grid, and its 10-fold cross-validation fitted 11 paths and evaluated `coxnet.deviance()` on all rows only.

pprof_py's times of the tasks it ran again come from `cox-c5-pprof_py-20261015-windows.csv`, run on 2026-10-15 with numba's default threads (8); "raises" marks a task whose pprof_py run raised an error, such as the `FloatingPointError` of D-80 where survival's weights are not finite.

| Scenario | Task | Fit median | C1 engine median | pprof_py median | Ratio, fit / pprof_py |
|---|---|---|---|---|---|
| center | fine_gray | 10.5 | - | 3.82 | 2.750 |
| center | fine_gray_right | 8.01 | - | 3.27 | 2.454 |
| covariates-5 | fine_gray | 7.2 | - | raises | - |

## The Fine-Gray fits' expansions and objects

Recorded, not a gate (DEC-127): the expanded rows that the fit gives survival's fitter (those of positive weight; the engine side's must be the same), the size of the fit's object (`object.size()`, without the data, `keep_data = FALSE`), and the peak memory of each side's process after its first run, in MB.

| Scenario | Task | Round | Expanded rows, fit / engine | Object MB | Peak MB, engine / fit |
|---|---|---|---|---|---|
| center | fine_gray | 1 | 687,533 / 687,533 | 5.49 | 915 / 938 |
| center | fine_gray | 2 | 687,533 / 687,533 | 5.49 | 971 / 939 |
| center | fine_gray_right | 1 | 571,986 / 571,986 | 5.49 | 860 / 844 |
| center | fine_gray_right | 2 | 571,986 / 571,986 | 5.49 | 847 / 847 |
| covariates-5 | fine_gray | 1 | 726,019 / 726,019 | 5.47 | 582 / 588 |
| covariates-5 | fine_gray | 2 | 726,019 / 726,019 | 5.47 | 587 / 590 |
