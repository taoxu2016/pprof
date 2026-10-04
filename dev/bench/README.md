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

Measurements per task: the first run's elapsed time; the median, minimum, and maximum of timed runs with `bench::mark(min_time = 1)`, at least 5 runs for calls whose first run takes under 10 s and 3 otherwise; R allocations per run (calls under 10 s only, because `bench::mark` profiles allocations in an extra untimed run that can take minutes for large calls); and the peak resident memory of the process before and after the first run. In a trial baseline with a single timed run per slow call, that run differed from the first run by up to 59% (`confint(option = "gamma")` on `bin-1e4-m100-p5`: 2.01 s, then 3.19 s), so single runs cannot support a 10% threshold. Even with repeated runs, some timings are bimodal (some runs include an expensive garbage collection): in the committed baseline, 8 of the 47 measured tasks have a median of at least 0.05 s that is more than 10% above their fastest run, by up to 50% (`logis_fe` on `bin-1e5-m1000-p5-common`), while the fastest run is stable. Hence the two-statistic rule in `compare_to_baseline.R`. A fresh process per task keeps peak memory attributable. Methods are timed on a fit made beforehand in the same process. Configurations known to be infeasible are recorded as skipped with the reason (for example `linear_fe` when the sum of squared provider sizes exceeds 2e7, because of its dense centering matrices; ARCHITECTURE §F, B2).

The baseline comes from one machine (recorded in the `.json`). Later phases compare on the same machine, or regenerate the baseline on a new machine before comparing; the reference library is pinned, so the baseline can be regenerated at any time. A full run takes about 30 minutes; nothing else should run on the machine meanwhile.
