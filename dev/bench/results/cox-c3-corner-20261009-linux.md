# Paired benchmark of the stratified Cox fit with its measures against its engine calls

Run on 2026-10-09 at commit `54488ae` (`dev/bench/cox/run_paired.R`, 2 round(s), package code unchanged from the commit): AMD EPYC 9V74 80-Core Processor, 4 logical cores; R version 4.4.0 (2024-04-24) with survival 3.8.12; pprof 2.0.0 installed with `--preclean`. The R engines are single-threaded.

Each round runs the engine call, `coxph()`, and the fit, each in a fresh process, one after the other, on the same data (`dev/bench/cox/scenarios.R`, C1's grid). The engine call is survival's fitter as the adapter calls it, on the inputs the adapter builds, prepared outside the timing (DEC-100); for the robust fit, the fitter followed by coxph()'s robust step with one cluster per row (DEC-099). The fit is `fit_cox_stratified()` on the data frame, with weights and an offset, from the formula to the model object. The preparation of the engine's inputs from the data frame (`data_prepare()` and the adapter's inputs) is timed in the engine's process after its measurement: the median of three calls.

From Phase C3 (DEC-111), each side includes the measures: the fit side calls `standardize_providers()` on the fit, which computes each observation's expected events at the national baseline, and the engine side computes the national expected events by provider in plain R at the fitter's coefficients (C1's closed form): the brief's "direct engine call it wraps plus the measures".

Rule (the brief's §3.7 MUST, DEC-105): a fit is too slow when, in every round, its median and its fastest run are more than 10% above the engine call's plus the preparation of its inputs, and its median at least 0.05 s above (DEC-038). The verdict against the engine call alone, the C2 plan's comparator, is given beside it. The fit's estimates must equal the engine call's bitwise (coefficients, and the robust variance). Times in seconds; peak memory of the process after the first run, in MB (recorded, DEC-004).

- Fits: 5; too slow against the engine call plus the preparation of its inputs (DEC-105): 0.
- Too slow against the engine call alone: 5; failed or differing from the engine call: 0.

## Notes on this run

- **The runner.** GitHub-hosted `ubuntu-24.04`, run 38004882689: AMD EPYC 9V74 80-Core Processor, 4 processors, 15.6 GB of memory. Tasks selected with `--only "^corner |^providers-7500 breslow$|^covariates-5 robust$"`, 2 rounds. The pprof_py times beside the package's are C1's, from the project lead's Windows machine, so their ratios are indicative.

## The fit against its engine call

| Scenario | Rows | Providers | Covariates | Task | Round | Engine median | Fit median | Ratio | Engine fastest | Fit fastest | Ratio | Fit − engine, median | Peak MB, engine / fit | Estimates | Verdict against the engine call alone |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| providers-7500 | 100,000 | 7,500 | 20 | breslow | 1 | 0.283 | 0.548 | 1.935 | 0.275 | 0.412 | 1.495 | 0.265 | 650 / 668 | identical |  |
| providers-7500 | 100,000 | 7,500 | 20 | breslow | 2 | 0.285 | 0.556 | 1.948 | 0.281 | 0.412 | 1.465 | 0.27 | 650 / 668 | identical | TOO SLOW |
| covariates-5 | 100,000 | 1,000 | 5 | robust | 1 | 0.265 | 0.349 | 1.316 | 0.118 | 0.189 | 1.597 | 0.0837 | 602 / 596 | identical |  |
| covariates-5 | 100,000 | 1,000 | 5 | robust | 2 | 0.27 | 0.347 | 1.282 | 0.119 | 0.19 | 1.590 | 0.0763 | 602 / 596 | identical | TOO SLOW |
| corner | 1,000,000 | 7,500 | 50 | breslow | 1 | 11.9 | 13.4 | 1.123 | 11.8 | 13.3 | 1.129 | 1.47 | 2999 / 3501 | identical |  |
| corner | 1,000,000 | 7,500 | 50 | breslow | 2 | 11.7 | 13.3 | 1.138 | 11.7 | 13.3 | 1.131 | 1.62 | 2999 / 3501 | identical | TOO SLOW |
| corner | 1,000,000 | 7,500 | 50 | efron | 1 | 13.2 | 14.9 | 1.131 | 13.1 | 14.6 | 1.117 | 1.72 | 2999 / 3501 | identical |  |
| corner | 1,000,000 | 7,500 | 50 | efron | 2 | 13.3 | 14.8 | 1.114 | 13.2 | 14.6 | 1.108 | 1.52 | 2999 / 3501 | identical | TOO SLOW |
| corner | 1,000,000 | 7,500 | 50 | robust | 1 | 12.9 | 14.4 | 1.113 | 12.8 | 14.3 | 1.115 | 1.46 | 3443 / 3612 | identical |  |
| corner | 1,000,000 | 7,500 | 50 | robust | 2 | 12.9 | 14.3 | 1.106 | 12.9 | 14.2 | 1.104 | 1.37 | 3443 / 3612 | identical | TOO SLOW |

## Where the fit's time goes

The fit's time beyond the engine call, the preparation of the engine's inputs from the data frame, and what is left: the adapter's own steps, the model object, and noise. The last column is the MUST's verdict (DEC-105): DEC-038's rule against the engine call plus the preparation (medians, and fastest runs plus the preparation).

| Scenario | Task | Round | Fit − engine, median | Inputs' preparation, median of 3 | Fit − engine − preparation | Ratio, fit / (engine + preparation), medians | Fastest | Verdict (DEC-105) |
|---|---|---|---|---|---|---|---|---|
| providers-7500 | breslow | 1 | 0.265 | 0.0959 | 0.169 | 1.445 | 1.109 |  |
| providers-7500 | breslow | 2 | 0.27 | 0.0958 | 0.175 | 1.458 | 1.093 | ok |
| covariates-5 | robust | 1 | 0.0837 | 0.0694 | 0.0143 | 1.043 | 1.006 |  |
| covariates-5 | robust | 2 | 0.0763 | 0.0679 | 0.00837 | 1.025 | 1.013 | ok |
| corner | breslow | 1 | 1.47 | 1.09 | 0.377 | 1.029 | 1.034 |  |
| corner | breslow | 2 | 1.62 | 1.09 | 0.528 | 1.041 | 1.035 | ok |
| corner | efron | 1 | 1.72 | 1.07 | 0.653 | 1.046 | 1.033 |  |
| corner | efron | 2 | 1.52 | 1.07 | 0.447 | 1.031 | 1.025 | ok |
| corner | robust | 1 | 1.46 | 1.08 | 0.387 | 1.028 | 1.029 |  |
| corner | robust | 2 | 1.37 | 1.11 | 0.264 | 1.019 | 1.016 | ok |

## The fit against coxph() on the data frame

The call a user would make: `coxph()` with the provider as strata, the offset, and the weights, and for robust one cluster per row (C1's comparator, DEC-098; the package called it before DEC-099). Reported, not a gate. Its estimates come from rows in the generator's order, so they can differ from the engine call's in the last bits.

| Scenario | Task | Round | coxph() median | Fit median | Ratio, fit / coxph() | Peak MB, coxph() / fit | coxph()'s largest relative difference from the engine call |
|---|---|---|---|---|---|---|---|
| providers-7500 | breslow | 1 | 0.912 | 0.548 | 0.600 | 721 / 668 | 0 |
| providers-7500 | breslow | 2 | 0.912 | 0.556 | 0.609 | 721 / 668 | 0 |
| covariates-5 | robust | 1 | 0.652 | 0.349 | 0.534 | 645 / 596 | 5e-15 |
| covariates-5 | robust | 2 | 0.656 | 0.347 | 0.529 | 645 / 596 | 5e-15 |
| corner | breslow | 1 | 25.7 | 13.4 | 0.521 | 3734 / 3501 | 4.7e-16 |
| corner | breslow | 2 | 24.9 | 13.3 | 0.537 | 3734 / 3501 | 4.7e-16 |
| corner | efron | 1 | 27 | 14.9 | 0.551 | 3734 / 3501 | 1.4e-15 |
| corner | efron | 2 | 25.9 | 14.8 | 0.570 | 3734 / 3501 | 1.4e-15 |
| corner | robust | 1 | 29.9 | 14.4 | 0.481 | 5179 / 3612 | 1.8e-12 |
| corner | robust | 2 | 30 | 14.3 | 0.477 | 5179 / 3612 | 1.8e-12 |

## The fits beside C1's baseline

C1's engine calls (`cox-engines-20261008-windows.csv`: `agreg.fit()` on the rows in the generator's order with the raw offset, and for robust `coxph(cluster = row)`, DEC-100) and pprof_py 0.7.0 on Python 3.12.3 with numba's default threads (8, `cox-pprof_py-20261008-windows.csv`), measured in another session, so the ratios are indicative only. The brief's §3.7 SHOULD (no slower than pprof_py) applies to the robust variance, not to the fits at large sizes (DEC-098). The fit's time is the median of its rounds' medians.

| Scenario | Task | Fit median | C1 engine median | pprof_py median | Ratio, fit / pprof_py |
|---|---|---|---|---|---|
| providers-7500 | breslow | 0.552 | 0.86 | 3.65 | 0.151 |
| covariates-5 | robust | 0.348 | 1.55 | 0.844 | 0.412 |
| corner | breslow | 13.4 | 39.3 | 24.5 | 0.546 |
| corner | efron | 14.8 | 42.4 | 117 | 0.126 |
| corner | robust | 14.3 | 251 | 18.7 | 0.765 |

## Measures and tests beside pprof_py's

The `profile` task fits once outside the timing, then times on that fit: the expected events' closed form (`cox_expected_events()`, which the fit itself runs), `standardize_providers()` with both standardizations, `test_providers()` with each test followed by `standardize_providers()` with that test's interval, and `funnel_limits()`. pprof_py's `calculate_standardized_measures()` and `test()` compute the expected events themselves, so its times are set beside the package's plus the expected events. Medians of the rounds' medians, in seconds; pprof_py's are C1's, from another session, so the ratios are indicative. The brief's §3.7 MUST: mid-p limits substantially faster than pprof_py's, read as at least ten times (DEC-111).

| Scenario | Providers | Expected events | Measures | pprof_py measures | Mid-p test and limits | pprof_py mid-p | pprof_py / package, mid-p | Exact test and limits | pprof_py exact | Funnel | Mid-p verdict |
|---|---|---|---|---|---|---|---|---|---|---|---|
| corner | 7,500 | 0.217 | 0.549 | 1.44 | 0.236 | 116 | 256 | 0.175 | 1.52 | 0.241 | ok |
