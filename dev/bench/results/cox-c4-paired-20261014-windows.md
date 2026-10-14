# Paired benchmark of the elastic-net Cox model against its engine calls

Run on 2026-10-14 at commit `ff79b18` (`dev/bench/cox/run_paired.R`, 2 round(s), package code unchanged from the commit): Intel64 Family 6 Model 140 Stepping 1, GenuineIntel, 8 logical cores; R version 4.4.0 (2024-04-24 ucrt) with survival 3.8.12; pprof 2.0.0 installed with `--preclean`. The R engines are single-threaded.

From Phase C4 (DEC-118), the elastic-net Cox model: each round runs the engine side and the fit, each in a fresh process, one after the other, on the same data (C1's grid), and the engine's process then times the preparation of its inputs from the data frame: the median of three calls. `penalized_path` times `fit_cox_penalized()` on the data frame against `glmnet()` on the adapter's inputs, whose preparation includes pprof_py's grid (glmnet's `coxgrad()` at the null point); `penalized_cv` times `select_lambda()` with 10 given folds on a fit made outside the timing against each fold's `glmnet()` path over the fit's grid, the fold deviances of every lambda from `coxnet.deviance()`, the saturated term's shift from survival's partial likelihood, and the summaries, written out in plain R as the package computes them. Their results (the path; the fold deviances, cvm, and cvsd) must be the engine side's bitwise.

Rule (the brief's §3.7 MUST, DEC-105): a fit is too slow when, in every round, its median and its fastest run are more than 10% above the engine call's plus the preparation of its inputs, and its median at least 0.05 s above (DEC-038). The verdict against the engine call alone, the C2 plan's comparator, is given beside it. The fit's estimates must equal the engine call's bitwise (coefficients, and the robust variance). Times in seconds; peak memory of the process after the first run, in MB (recorded, DEC-004).

- Fits: 3; too slow against the engine call plus the preparation of its inputs (DEC-105): 0.
- Too slow against the engine call alone: 0; failed or differing from the engine call: 0.

## Notes on this run

- **The tasks.** The elastic-net Cox model's two tasks (DEC-118): its path on covariates-50 and rows-1e4, and its 10-fold cross-validation on covariates-50. The stratified Cox fits were not measured again: C4 changed their code only by splitting the survival adapter's input builder, and their results are bitwise unchanged.
- **The machine paged throughout.** During the run (11:01 to 11:35), free memory averaged 0.65 GB (0.27 GB at least) with 19 GB committed on 7.4 GB, and paging averaged 5,700 pages per second (up to 51,000). The engine side's own time on covariates-50 moved between rounds by 16% for the path (18.1 s and 15.6 s) and 20% for the cross-validation (183 s and 152 s).
- **Covariates-50, in one process.** No fit is too slow by DEC-105's rule, but the path's medians sat at 1.14 times the comparator in both rounds (fastest runs 0.99 and 1.12), and the cross-validation, one run a round, at 0.85 and 1.15. Interleaved in one process (`dev/design/coxph-facts/29_penalized_fit_parts.txt`), the path takes 0.97 times glmnet's call plus its inputs' preparation (1.03 on rows-1e4), and `select_lambda()` 1.075 times the plain-R cross-validation (medians of 3 runs, the fastest 1.16). Timed part by part and fold by fold (`30_penalized_cv_parts.txt`), its loop costs 0.998 times the plain-R loop: the folds' inputs take 4.2 s more, for the column scales of pprof_py's per-fold degenerate check, and identical glmnet fold paths vary by up to 2.2 s from one run to the next.
- **Beside pprof_py** (C1's times, from another session): the path takes 19.9 s against pprof_py's 89.9 s, 4.5 times faster. pprof_py's `PenalizedCoxPHCV` fits the full path and then the folds, so its 1,717 s compare with the path and `select_lambda()` together, about 185 s: 9.3 times faster. C1's glmnet times used glmnet's own grid, and its cross-validation computed deviances on all rows only.

## The fit against its engine call

| Scenario | Rows | Providers | Covariates | Task | Round | Engine median | Fit median | Ratio | Engine fastest | Fit fastest | Ratio | Fit − engine, median | Peak MB, engine / fit | Estimates | Verdict against the engine call alone |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| rows-1e4 | 10,000 | 1,000 | 20 | penalized_path | 1 | 1.76 | 1.5 | 0.850 | 1.2 | 1.19 | 0.990 | -0.264 | 256 / 272 | identical |  |
| rows-1e4 | 10,000 | 1,000 | 20 | penalized_path | 2 | 1.63 | 1.35 | 0.828 | 1.25 | 1.15 | 0.917 | -0.28 | 256 / 272 | identical | ok |
| covariates-50 | 100,000 | 1,000 | 50 | penalized_path | 1 | 18.1 | 21.3 | 1.180 | 15.6 | 16.1 | 1.026 | 3.25 | 473 / 515 | identical |  |
| covariates-50 | 100,000 | 1,000 | 50 | penalized_path | 2 | 15.6 | 18.4 | 1.183 | 15 | 17.5 | 1.166 | 2.85 | 472 / 490 | identical | ok |
| covariates-50 | 100,000 | 1,000 | 50 | penalized_cv | 1 | 183 | 156 | 0.853 | 183 | 156 | 0.853 | -26.9 | 720 / 747 | identical |  |
| covariates-50 | 100,000 | 1,000 | 50 | penalized_cv | 2 | 152 | 175 | 1.148 | 152 | 175 | 1.148 | 22.5 | 689 / 762 | identical | ok |

## Where the fit's time goes

The fit's time beyond the engine call, the preparation of the engine's inputs from the data frame, and what is left: the adapter's own steps, the model object, and noise. The last column is the MUST's verdict (DEC-105): DEC-038's rule against the engine call plus the preparation (medians, and fastest runs plus the preparation).

| Scenario | Task | Round | Fit − engine, median | Inputs' preparation, median of 3 | Fit − engine − preparation | Ratio, fit / (engine + preparation), medians | Fastest | Verdict (DEC-105) |
|---|---|---|---|---|---|---|---|---|
| rows-1e4 | penalized_path | 1 | -0.264 | 0.0524 | -0.317 | 0.825 | 0.949 |  |
| rows-1e4 | penalized_path | 2 | -0.28 | 0.0759 | -0.356 | 0.792 | 0.865 | ok |
| covariates-50 | penalized_path | 1 | 3.25 | 0.654 | 2.6 | 1.139 | 0.985 |  |
| covariates-50 | penalized_path | 2 | 2.85 | 0.626 | 2.23 | 1.138 | 1.120 | ok |
| covariates-50 | penalized_cv | 1 | -26.9 | 0.334 | -27.2 | 0.852 | 0.852 |  |
| covariates-50 | penalized_cv | 2 | 22.5 | 0.312 | 22.2 | 1.146 | 1.146 | ok |

## The fits beside C1's baseline

C1's engine calls (`cox-engines-20261008-windows.csv`: `agreg.fit()` on the rows in the generator's order with the raw offset, and for robust `coxph(cluster = row)`, DEC-100) and pprof_py 0.7.0 on Python 3.12.3 with numba's default threads (8, `cox-pprof_py-20261008-windows.csv`), measured in another session, so the ratios are indicative only. The brief's §3.7 SHOULD (no slower than pprof_py) applies to the robust variance, not to the fits at large sizes (DEC-098). The fit's time is the median of its rounds' medians. For the penalized tasks, C1's glmnet path used glmnet's own grid, and its 10-fold cross-validation fitted 11 paths and evaluated `coxnet.deviance()` on all rows only.

| Scenario | Task | Fit median | C1 engine median | pprof_py median | Ratio, fit / pprof_py |
|---|---|---|---|---|---|
| rows-1e4 | penalized_path | 1.43 | - | - | - |
| covariates-50 | penalized_path | 19.9 | 14.3 | 89.9 | 0.221 |
| covariates-50 | penalized_cv | 165 | 204 | 1717 | 0.096 |
