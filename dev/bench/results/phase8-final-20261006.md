# Phase 8 final benchmarks (DEC-038, DEC-044, DEC-079)

2026-10-06, on the machine of every earlier baseline (Windows 11, Intel64 Family 6 Model 140, 8 cores, 7.4 GB; R 4.4.0, R's BLAS, LAPACK 3.12.0), nothing else running. The package code is that of `b74ed34` (no package code changed after it in Phase 8).

| File | Content |
|---|---|
| `reference-baseline-20261006-windows-phase8.csv`, `.json` | pprof 1.0.3 from the pinned library, all 85 tasks, regenerated the same day (47 minutes) |
| `working-tree-20261006-windows-phase8.csv`, `.json` | The same tasks on the working tree, installed with `R CMD INSTALL --preclean` (30 minutes) |
| `comparison-20261006-windows-phase8.md` | `compare_to_baseline.R`: 84 tasks compared (one is infeasible for pprof 1.0.3's dense `linear_fe` and skipped in both), 4 flagged |
| `paired-20261006-windows-phase8.csv`, `.md` | `run_paired.R`, three rounds alternating pprof 1.0.3 and the working tree in fresh processes: the 4 flagged tasks and a control; with `gc()`'s maximum of R's heap beside the process's peak (added in Phase 8) |
| `dev/design/phase8-facts/10_p50_memory.R`, `.txt` | R's heap stage by stage in the 50-covariate fit |

## Verdicts

- Time: no regression. The comparison flagged three tasks: `logis_re` (1e5 observations, 60 s against 75 s), `SM_output(stdz = "direct")` (1e5, 3.34 s against 3.75 s), and `linear_re` (1e5, 1.12 s against 1.33 s). Paired, all three are within 4% of pprof 1.0.3 or faster in every round (`logis_re` 0.94 to 1.03, `SM_output` 0.99 to 1.03, `linear_re` 0.86 to 0.95, median ratios), and so is the control (`logis_fe` on 1e5: 0.55 to 0.70). Over the 84 tasks of the comparison the median time ratio is 0.86: 44 tasks are more than 10% faster, 14 within 10%, and 26 more than 10% slower, of which the three above were noise and the other 23 are slower by at most 0.034 s, below DEC-023's 0.05 s. Most of those are the old methods' rebuild of the new model from the old object (DEC-039): `summary(fit, test = "wald")` of a `logis_fe` fit takes 0.028 s instead of 0.0004 s on 1e5 observations, `summary()` of a `linear_fe` fit 0.016 s instead of 0.0005 s.
- `plot()` of a `logis_fe` fit, which builds its model once since step 4 (DEC-075): 0.94 and 1.02 times pprof 1.0.3's time on 1e4 and 1e5 observations (0.065 s and 0.113 s), where it was 0.04 s slower on 1e5 before.
- The fits (median times): `logis_fe()` with SerBIN takes 0.25 to 0.54 times pprof 1.0.3's time, and with BAN 0.49 to 0.75 on 1e5 observations and more (on 1e4 its median, 0.109 s against 0.075 s, comes with a fastest run equal to the reference's); `logis_firth()` 0.52 to 0.71; `linear_fe()` 0.018 to 0.029 (for example 2.2 s instead of 95.5 s on 1e6 observations of 100,000 providers); the RE and CRE fits take the time of their lme4 calls.
- Memory: the peak resident memory after the first run is lower than pprof 1.0.3's in 83 of the 84 tasks (median 66 MB lower, up to 676 MB: `linear_fe` on 1e5 observations peaks at 276 MB instead of 842 MB), and higher in one, the 50-covariate fit (below). Before each task's first run (pprof attached and the data built), the working tree uses less memory than pprof 1.0.3 in every task (median 62 MB less, 30 to 564 MB): DEC-044's load-order transient, about 67 MB more at Phase 6, is gone with caret and olsrr (step 3), and turned into a saving.

## DEC-044 (2): the 50-covariate `logis_fe()` peak

- Paired, three rounds (DEC-079): the process's peak is 2,525, 2,585, and 2,588 MB for the working tree and 1,975, 2,424, and 2,240 MB for pprof 1.0.3, that is 28%, 7%, and 16% above. DEC-079's rule asks for an investigation when the working tree is more than 10% and 50 MB above in every round; it is not in the second round, so by the rule the exception closes with these measurements.
- `gc()`'s maximum of R's heap during the fit, which does not depend on the allocator, is the same in every round: 2,498 MB for the working tree and 2,217 MB for pprof 1.0.3, 281 MB (13%) more.
- Where it comes from (`10_p50_memory.txt`): R's heap peaks in the within-provider rank check that the package added for D-38 (pprof 1.0.3 has none), at 1,164 MB above the live data, for the n-by-p within-provider matrix (381 MB here) and the copy and work space of its QR decomposition. The data preparation peaks at 554 MB above what was live before it, the engine with the variances and fit statistics at 517 MB, and the model object at 76 MB. Without the rank check the fit's heap would peak well below pprof 1.0.3's.
- The time of the same fit is 0.54 to 0.81 times pprof 1.0.3's (31 to 40 s against 49 to 59 s).
- A cheaper rank check, from the p-by-p crossproduct of the within-provider columns formed one column at a time, would avoid both n-by-p copies, but its rank decision would differ from the QR's for nearly collinear designs, so the warning could change; DEC-079 allows only changes that leave every result identical, so it is not made. It is listed for the project lead.

## DEC-044 (1): the load-order transient

Closed: see "Memory" above.
