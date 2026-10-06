# Paired benchmark: reference and working tree, 3 round(s)

- Tasks: 5; regressions: 0.
- Rule (DEC-038): a regression in time needs both the median and the fastest run more than 10% slower than the reference's, and the median at least 0.05 s slower, in every round; in memory, a peak more than 10% and 50 MB higher in every round.

- Peak MB is the process's peak resident memory after the first run; gc max MB is gc()'s maximum of R's heap during it (Phase 8).

| Scenario | Task | Round | Reference median s | New median s | Ratio | Reference fastest s | New fastest s | Ratio | Reference peak MB | New peak MB | Ratio | Reference gc max MB | New gc max MB | Verdict |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| bin-1e5-m1000-p5 | logis_fe | 1 | 0.598 | 0.328 | 0.548 | 0.482 | 0.314 | 0.652 |  350 |  293 | 0.837 |  250 |  228 |  |
| bin-1e5-m1000-p5 | logis_fe | 2 | 0.585 | 0.382 | 0.653 | 0.472 | 0.316 | 0.67 |  350 |  296 | 0.845 |  250 |  228 |  |
| bin-1e5-m1000-p5 | logis_fe | 3 | 0.584 | 0.407 | 0.698 | 0.484 | 0.367 | 0.758 |  350 |  297 | 0.848 |  250 |  228 | ok |
| bin-1e5-m1000-p5 | logis_re | 1 | 56.5 | 58.2 | 1.03 | 55.8 | 55.1 | 0.988 |  398 |  357 | 0.895 |  282 |  274 |  |
| bin-1e5-m1000-p5 | logis_re | 2 | 58.8 | 55.1 | 0.937 | 57.2 |   55 | 0.961 |  398 |  355 | 0.893 |  282 |  274 |  |
| bin-1e5-m1000-p5 | logis_re | 3 | 57.4 | 57.2 | 0.997 | 57.4 | 56.7 | 0.988 |  398 |  355 | 0.893 |  282 |  274 | ok |
| bin-1e5-m1000-p5 | SM_output[stdz=direct] | 1 |  3.4 | 3.37 | 0.989 | 3.27 | 3.31 | 1.01 |  353 |  282 |  0.8 |  204 |  205 |  |
| bin-1e5-m1000-p5 | SM_output[stdz=direct] | 2 | 3.44 | 3.49 | 1.01 | 3.33 | 3.31 | 0.993 |  354 |  284 | 0.803 |  204 |  205 |  |
| bin-1e5-m1000-p5 | SM_output[stdz=direct] | 3 | 3.34 | 3.44 | 1.03 | 3.28 | 3.35 | 1.02 |  354 |  283 |  0.8 |  204 |  205 | ok |
| bin-1e6-m1000-p50 | logis_fe | 1 | 58.8 | 31.6 | 0.537 | 47.3 | 29.8 | 0.631 | 1975 | 2525 | 1.28 | 2217 | 2498 |  |
| bin-1e6-m1000-p50 | logis_fe | 2 | 49.4 | 39.8 | 0.805 | 41.8 | 38.2 | 0.915 | 2424 | 2585 | 1.07 | 2217 | 2498 |  |
| bin-1e6-m1000-p50 | logis_fe | 3 | 54.6 | 30.7 | 0.562 |   44 | 30.6 | 0.695 | 2240 | 2588 | 1.16 | 2217 | 2498 | ok |
| lin-1e5-m1000-p5 | linear_re | 1 | 1.12 | 0.968 | 0.861 | 0.999 | 0.94 | 0.942 |  385 |  324 | 0.842 |  278 |  248 |  |
| lin-1e5-m1000-p5 | linear_re | 2 |  1.1 | 0.989 | 0.897 | 1.01 | 0.951 | 0.941 |  385 |  327 | 0.85 |  278 |  248 |  |
| lin-1e5-m1000-p5 | linear_re | 3 |    1 | 0.957 | 0.953 | 0.981 | 0.943 | 0.961 |  384 |  324 | 0.844 |  278 |  248 | ok |
