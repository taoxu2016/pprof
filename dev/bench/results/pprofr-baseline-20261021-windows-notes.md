# Notes on the pprofR baseline of 2026-10-21

The run of `dev/bench/pprofr/run_pprofr.R` behind `pprofr-baseline-20261021-windows.md` (LOGISTIC_L1_PLAN §3.7; DEC-160).

- **The run.** 11:08 to 11:50 local time, 42 minutes, at commit `303d88a`, as a detached process, with nothing else of the session running. Before it started the machine was paging at about 7,000 pages a second with 0.43 GB of physical memory free, its usual state with its user's other applications open. The timings carry that noise; the comparisons of Phases L2 to L4 measure pprofR again beside the package in the same process, as DEC-038 pairs runs, and decide from those runs.
- **What it shows of pprofR's costs.**
  - The fits, variances, and every z test take under a second at 100,000 rows and a few seconds at 1,000,000.
  - The cluster-level tests, robust and stabilized, cost about what the model-based ones do: 0.03 to 0.04 s at 100,000 rows and 0.4 s at 1,000,000.
  - The exact test and its intervals grow with the square of a provider's trials (DEC-150):
    - the exact test takes 0.84 s with 100 trials a provider (one trial a row), 81 s with 1,000 (10 trials a row), and 9 s for one provider of 10,000;
    - the exact intervals take 0.05 s, 2.3 s, and 383 s for one provider of 100, 1,000, and 10,000 trials, so 1,000 providers of 10,000 trials would take about four days;
    - the skipped tasks are those of more than 5,000 trials a provider (the test) and of m T² above 1e8 (the intervals).
  - The bootstrap's 10,000 resamples take 73 to 148 s at 100,000 rows (13 s at 10,000), and were skipped at 1,000,000 rows (1e10 draws).
  - The peak memory of a process is 150 to 250 MB, and 684 MB at 1,000,000 rows.
- **For Phase L2.** The package's binomial tasks are measured against these: the brief's §3.7 asks that a binomial fit take no more time than pprofR's, and a clustered test no more than pprofR's.
