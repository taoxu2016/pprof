# dev/bench: benchmarks

The Phase 1 benchmark suite and the reference baseline (brief §3.6). The rewrite must not be materially slower or more memory-hungry than the reference at default settings: no regression worse than about 10%, with any exception documented.

| File | Purpose |
|---|---|
| `scenarios.R` | Synthetic scenarios (n from 1e4 to 1e6, m from 100 to 100,000, p of 5, 20, 50, balanced and skewed provider sizes, event rates of 1%, 10%, 50%) and the task list (function by scenario) |
| `run_reference.R` | Runs every task in a fresh R process on the pinned reference library and writes `results/reference-baseline-<date>-<platform>.csv` and a matching `.json` with the machine and settings; with `--working-tree`, installs the working tree into a temporary library placed before the reference library and writes `working-tree-<date>-<platform>.csv` (Phase 3). The install recompiles every object (`R CMD INSTALL --preclean`, from the Phase 4 gate), so the benchmark measures a release build even when `devtools::load_all()` has left debug objects in `src/` |
| `compare_to_baseline.R` | Compares a later run with the baseline and flags regressions: time when both the median and the fastest run are more than 10% slower (and the median at least 0.05 s slower), peak memory when more than 10% and at least 50 MB higher; a task where only one of the two timings is more than 10% slower is marked for a rerun (DEC-023) |
| `run_paired.R` | Measures the tasks a comparison flags again, alternating the reference and the working tree in fresh processes for two or more rounds, and writes `paired-<date>-<platform>.csv` and `.md` with ratios and verdicts: a task regresses only when it is slower or larger by the DEC-023 thresholds against the reference of every round (DEC-038) |
| `harness.R` | Code shared by `run_reference.R` and `run_paired.R`: task names, the install of the working tree, and the measurement of one task in a fresh process |
| `results/` | Committed baselines, and the runs and reports of the phase gates (from Phase 3) |

```sh
Rscript dev/bench/run_reference.R                       # the reference baseline
Rscript dev/bench/run_reference.R --working-tree        # the same tasks on the working tree
Rscript dev/bench/compare_to_baseline.R dev/bench/results/<baseline>.csv <new>.csv --report <report>.md
Rscript dev/bench/run_paired.R --only '<regex of flagged tasks and a control>'   # paired re-measurement
```

Measurements per task: the first run's elapsed time; the median, minimum, and maximum of timed runs with `bench::mark(min_time = 1)`, at least 5 runs for calls whose first run takes under 10 s and 3 otherwise; R allocations per run (calls under 10 s only, because `bench::mark` profiles allocations in an extra untimed run that can take minutes for large calls, and missing for calls whose profiling fails, such as `plot()` of a `linear_fe` fit, which are then timed without it); and the peak resident memory of the process before and after the first run. In a trial baseline with a single timed run per slow call, that run differed from the first run by up to 59% (`confint(option = "gamma")` on `bin-1e4-m100-p5`: 2.01 s, then 3.19 s), so single runs cannot support a 10% threshold. Even with repeated runs, some timings are bimodal (some runs include an expensive garbage collection): in the committed baseline, 8 of the 47 measured tasks have a median of at least 0.05 s that is more than 10% above their fastest run, by up to 50% (`logis_fe` on `bin-1e5-m1000-p5-common`), while the fastest run is stable. Hence the two-statistic rule in `compare_to_baseline.R`. A fresh process per task keeps peak memory attributable. Methods are timed on a fit made beforehand in the same process; functions that take a method's result, such as `caterpillar_plot()` and `bar_plot()` (Phase 6, DEC-060), are timed on that result, also computed beforehand. Configurations known to be infeasible are recorded as skipped with the reason (for example `linear_fe` when the sum of squared provider sizes exceeds 2e7, because of its dense centering matrices; ARCHITECTURE §F, B2).

The baseline comes from one machine (recorded in the `.json`). Later phases compare on the same machine, or regenerate the baseline on a new machine before comparing; the reference library is pinned, so the baseline can be regenerated at any time. A full run takes about 30 minutes; nothing else should run on the machine meanwhile.

## The Cox baseline (`cox/`)

There is no pprof 1.0.3 baseline for Cox models (CoxPH brief §3.7). The Cox baseline times instead what the package will wrap, and pprof_py v0.7.0 for reference; from Phase C2 on, each Cox function is measured against the engine call it wraps, in the same session, and must be at most 10% slower (DEC-038's pairing).

| File | Purpose |
|---|---|
| `cox/scenarios.R` | Eight scenarios, one factor at a time around 100,000 rows, 1,000 providers, and 20 covariates, and the corner of 1,000,000 rows, 7,500 providers, and 50 covariates; delayed entry, daily ties, offsets, weights, and provider effects; data written once as raw doubles that R and NumPy read exactly |
| `cox/run_engines.R` | `survival::agreg.fit()` (Breslow and Efron) and `coxph()` with robust variance, as the adapter calls them (COXPH_DESIGN §E.1); the closed-form expected counts of COXPH_DESIGN §F.1 in plain R; on the 50-covariate scenario, a `glmnet` path and a 10-fold cross-validation (§E.2) |
| `cox/run_pprof_py.py` | pprof_py's `CoxPH` fits, standardized measures, mid-p and exact tests, and penalized path and cross-validation, with the Cox generator's Python |
| `cox/summarize.R` | The baseline's report: the engines' and pprof_py's medians side by side (`results/cox-baseline-<date>-<platform>.md`) |
| `cox/run_paired.R` | From Phase C2: each Cox fit against the engine call it makes, on the same data, in fresh processes that alternate the engine call, `coxph()` on the data frame, and the fit, for two or more rounds (DEC-038, DEC-100); the working tree installed with `--preclean`; the fit's estimates checked bitwise against the engine call's |
| `cox/summarize_paired.R` | The paired runs' report: ratios and DEC-038's verdicts against the engine call, the fit against `coxph()`, and C1's pprof_py times beside the fits (`results/cox-c2-paired-<date>-<platform>.md`) |

```sh
Rscript dev/bench/cox/run_engines.R <data dir> dev/bench/results/cox-engines-<date>-<platform>.csv
dev/reference/cox/venv/Scripts/python dev/bench/cox/run_pprof_py.py <data dir> dev/bench/results/cox-pprof_py-<date>-<platform>.csv
Rscript dev/bench/cox/run_paired.R <data dir> <paired csv> [--only '<regex of "scenario task">'] [--rounds 2]
Rscript dev/bench/cox/summarize_paired.R <report md> dev/bench/results/cox-pprof_py-<date>-<platform>.csv <paired csv> [...]
```

Each task runs in a fresh process. The R tasks follow `harness.R`'s measurements (the first run, `bench::mark()` with at least 5 runs, 3 from 10 s, 1 from 60 s, the process's peak memory, and `gc()`'s maximum of R's heap); the Python tasks warm up on 2,000 rows first, so that numba's compilation is not timed. Each CSV has a `.json` with the machine and the versions.
