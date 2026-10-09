# Paired benchmark of the stratified Cox fit with its measures against its engine calls

Run on 2026-10-09 at commit `d46e985` and `3ed22dd` (`dev/bench/cox/run_paired.R`, 2 round(s), package code unchanged from the commit): Intel64 Family 6 Model 140 Stepping 1, GenuineIntel, 8 logical cores; R version 4.4.0 (2024-04-24 ucrt) with survival 3.8.12; pprof 2.0.0 installed with `--preclean`. The R engines are single-threaded.

A later run repeated, and its rows replace the earlier run's for: center profile, rows-1e4 profile, rows-1e6 profile, providers-100 profile, providers-7500 profile, covariates-5 profile, covariates-50 profile.

Each round runs the engine call, `coxph()`, and the fit, each in a fresh process, one after the other, on the same data (`dev/bench/cox/scenarios.R`, C1's grid). The engine call is survival's fitter as the adapter calls it, on the inputs the adapter builds, prepared outside the timing (DEC-100); for the robust fit, the fitter followed by coxph()'s robust step with one cluster per row (DEC-099). The fit is `fit_cox_stratified()` on the data frame, with weights and an offset, from the formula to the model object. The preparation of the engine's inputs from the data frame (`data_prepare()` and the adapter's inputs) is timed in the engine's process after its measurement: the median of three calls.

From Phase C3 (DEC-111), each side includes the measures: the fit side calls `standardize_providers()` on the fit, which computes each observation's expected events at the national baseline, and the engine side computes the national expected events by provider in plain R at the fitter's coefficients (C1's closed form): the brief's "direct engine call it wraps plus the measures".

Rule (the brief's §3.7 MUST, DEC-105): a fit is too slow when, in every round, its median and its fastest run are more than 10% above the engine call's plus the preparation of its inputs, and its median at least 0.05 s above (DEC-038). The verdict against the engine call alone, the C2 plan's comparator, is given beside it. The fit's estimates must equal the engine call's bitwise (coefficients, and the robust variance). Times in seconds; peak memory of the process after the first run, in MB (recorded, DEC-004).

- Fits: 21; too slow against the engine call plus the preparation of its inputs (DEC-105): 2.
- Too slow against the engine call alone: 14; failed or differing from the engine call: 0.

## Notes on this run

- **Two runs.** The first (commit `d46e985`) measured every scenario but the corner: the three fits and the `profile` task. In it the mid-p test with its limits was only 8 times faster than pprof_py's at 100 providers, short of DEC-111's ten, because the limits' roots were found with `uniroot()` one distinct observed count at a time and nearly every provider there has a count of its own. The package now bisects over all the distinct counts at once (`929cd32`; DEC-110, `dev/design/coxph-facts/24_midp_bisection.txt`: the same roots to rounding), and the second run (commit `3ed22dd`) measured the `profile` task again; its rows replace the first run's. The code the fits run did not change between the two.
- **The corner scenario is not in this report.** It is measured at the C3 gate if at least 4 GB of memory is free then (DEC-111).
- **The machine paged throughout.** During the first run (16:50 to 17:30), free memory averaged 0.9 GB (0.3 GB at least) with 20 GB committed on 7.4 GB, and paging averaged 7,400 pages per second (up to 41,000).
- **The two fits too slow** by DEC-105's rule, providers-7500 with Breslow ties and covariates-5 robust, sit at the rule's line. In one process, with the sides interleaved over nine runs (`dev/design/coxph-facts/25_fit_measures_parts.txt`), the fit with its measures takes 1.11 and 1.09 times the engine call plus its inputs' preparation and the plain-R measures there, and 0.91 and 0.98 at the center. The measures cost the fit side 0.011 s more than the engine side at 1,000 providers and 0.044 s more at 7,500, where `standardize_providers()` builds a table of 7,500 providers (0.048 s): 5% and 8% of the comparator. The preparation of the inputs, which the rule adds to the engine call, measured about half of C2's at providers-7500 in this run (0.16 s against 0.30 to 0.37 s), so the verdicts move with the noise around the line.
- **The measures beside pprof_py's** (the brief's SHOULD, as DEC-098 reads it): the package's measures with the expected events take 1.10 s against pprof_py's 1.32 s at 1,000,000 rows, about as long at 100,000 rows with 100 or 1,000 providers (0.10 to 0.12 s against 0.09 to 0.12 s), and longer at 10,000 rows (0.031 s against 0.009 s) and with 7,500 providers (0.23 s against 0.13 s). The exact test with its limits is faster than pprof_py's everywhere but at 10,000 rows, where both take under 0.02 s.

## The fit against its engine call

| Scenario | Rows | Providers | Covariates | Task | Round | Engine median | Fit median | Ratio | Engine fastest | Fit fastest | Ratio | Fit − engine, median | Peak MB, engine / fit | Estimates | Verdict against the engine call alone |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| center | 100,000 | 1,000 | 20 | breslow | 1 | 0.533 | 0.771 | 1.447 | 0.416 | 0.707 | 1.699 | 0.238 | 347 / 350 | identical |  |
| center | 100,000 | 1,000 | 20 | breslow | 2 | 0.664 | 0.818 | 1.232 | 0.486 | 0.743 | 1.529 | 0.154 | 344 / 338 | identical | TOO SLOW |
| center | 100,000 | 1,000 | 20 | efron | 1 | 0.558 | 0.728 | 1.303 | 0.444 | 0.715 | 1.610 | 0.169 | 347 / 350 | identical |  |
| center | 100,000 | 1,000 | 20 | efron | 2 | 0.517 | 0.888 | 1.718 | 0.419 | 0.723 | 1.725 | 0.371 | 346 / 343 | identical | TOO SLOW |
| center | 100,000 | 1,000 | 20 | robust | 1 | 0.671 | 0.972 | 1.448 | 0.627 | 0.857 | 1.367 | 0.301 | 351 / 385 | identical |  |
| center | 100,000 | 1,000 | 20 | robust | 2 | 0.984 | 1.03 | 1.045 | 0.878 | 0.885 | 1.008 | 0.0446 | 351 / 385 | identical | ok |
| rows-1e4 | 10,000 | 1,000 | 20 | breslow | 1 | 0.0494 | 0.0939 | 1.902 | 0.0429 | 0.0808 | 1.882 | 0.0445 | 247 / 261 | identical |  |
| rows-1e4 | 10,000 | 1,000 | 20 | breslow | 2 | 0.0421 | 0.0774 | 1.836 | 0.0376 | 0.0693 | 1.843 | 0.0352 | 247 / 261 | identical | ok |
| rows-1e4 | 10,000 | 1,000 | 20 | efron | 1 | 0.041 | 0.103 | 2.504 | 0.0355 | 0.0927 | 2.614 | 0.0616 | 248 / 261 | identical |  |
| rows-1e4 | 10,000 | 1,000 | 20 | efron | 2 | 0.0493 | 0.0855 | 1.735 | 0.0389 | 0.0809 | 2.079 | 0.0363 | 247 / 262 | identical | ok |
| rows-1e4 | 10,000 | 1,000 | 20 | robust | 1 | 0.107 | 0.124 | 1.152 | 0.0851 | 0.0962 | 1.131 | 0.0163 | 260 / 261 | identical |  |
| rows-1e4 | 10,000 | 1,000 | 20 | robust | 2 | 0.062 | 0.134 | 2.155 | 0.0549 | 0.112 | 2.042 | 0.0717 | 259 / 260 | identical | ok |
| rows-1e6 | 1,000,000 | 1,000 | 20 | breslow | 1 | 5.94 | 6.13 | 1.032 | 5.03 | 5.99 | 1.190 | 0.191 | 990 / 1230 | identical |  |
| rows-1e6 | 1,000,000 | 1,000 | 20 | breslow | 2 | 4.62 | 5.85 | 1.265 | 4.34 | 5.68 | 1.309 | 1.22 | 1177 / 1230 | identical | ok |
| rows-1e6 | 1,000,000 | 1,000 | 20 | efron | 1 | 4.82 | 6.77 | 1.405 | 4.63 | 6.37 | 1.376 | 1.95 | 1177 / 1230 | identical |  |
| rows-1e6 | 1,000,000 | 1,000 | 20 | efron | 2 | 5.25 | 7.06 | 1.346 | 4.94 | 6.31 | 1.277 | 1.82 | 1178 / 1230 | identical | TOO SLOW |
| rows-1e6 | 1,000,000 | 1,000 | 20 | robust | 1 | 5.62 | 8.32 | 1.480 | 5.55 | 7.63 | 1.375 | 2.7 | 1335 / 1440 | identical |  |
| rows-1e6 | 1,000,000 | 1,000 | 20 | robust | 2 | 5.82 | 10.2 | 1.758 | 5.72 | 8.21 | 1.434 | 4.41 | 1354 / 1440 | identical | TOO SLOW |
| providers-100 | 100,000 | 100 | 20 | breslow | 1 | 0.504 | 0.676 | 1.340 | 0.393 | 0.659 | 1.676 | 0.172 | 342 / 351 | identical |  |
| providers-100 | 100,000 | 100 | 20 | breslow | 2 | 0.518 | 0.66 | 1.274 | 0.496 | 0.624 | 1.259 | 0.142 | 347 / 351 | identical | TOO SLOW |
| providers-100 | 100,000 | 100 | 20 | efron | 1 | 0.564 | 0.709 | 1.258 | 0.447 | 0.676 | 1.514 | 0.145 | 347 / 351 | identical |  |
| providers-100 | 100,000 | 100 | 20 | efron | 2 | 0.536 | 0.693 | 1.293 | 0.447 | 0.673 | 1.504 | 0.157 | 347 / 350 | identical | TOO SLOW |
| providers-100 | 100,000 | 100 | 20 | robust | 1 | 0.714 | 0.868 | 1.216 | 0.547 | 0.79 | 1.445 | 0.154 | 351 / 373 | identical |  |
| providers-100 | 100,000 | 100 | 20 | robust | 2 | 0.723 | 0.804 | 1.113 | 0.525 | 0.761 | 1.448 | 0.0817 | 353 / 373 | identical | TOO SLOW |
| providers-7500 | 100,000 | 7,500 | 20 | breslow | 1 | 0.468 | 0.868 | 1.854 | 0.413 | 0.759 | 1.840 | 0.4 | 348 / 340 | identical |  |
| providers-7500 | 100,000 | 7,500 | 20 | breslow | 2 | 0.415 | 0.726 | 1.751 | 0.379 | 0.626 | 1.653 | 0.311 | 339 / 339 | identical | TOO SLOW |
| providers-7500 | 100,000 | 7,500 | 20 | efron | 1 | 0.414 | 0.708 | 1.710 | 0.391 | 0.612 | 1.564 | 0.294 | 347 / 340 | identical |  |
| providers-7500 | 100,000 | 7,500 | 20 | efron | 2 | 0.468 | 0.676 | 1.444 | 0.394 | 0.591 | 1.501 | 0.208 | 346 / 340 | identical | TOO SLOW |
| providers-7500 | 100,000 | 7,500 | 20 | robust | 1 | 0.631 | 0.912 | 1.444 | 0.557 | 0.756 | 1.357 | 0.281 | 350 / 372 | identical |  |
| providers-7500 | 100,000 | 7,500 | 20 | robust | 2 | 0.611 | 0.904 | 1.479 | 0.554 | 0.746 | 1.345 | 0.293 | 351 / 373 | identical | TOO SLOW |
| covariates-5 | 100,000 | 1,000 | 5 | breslow | 1 | 0.169 | 0.301 | 1.779 | 0.16 | 0.284 | 1.771 | 0.132 | 293 / 296 | identical |  |
| covariates-5 | 100,000 | 1,000 | 5 | breslow | 2 | 0.197 | 0.739 | 3.752 | 0.187 | 0.348 | 1.866 | 0.542 | 293 / 297 | identical | TOO SLOW |
| covariates-5 | 100,000 | 1,000 | 5 | efron | 1 | 0.156 | 0.309 | 1.982 | 0.153 | 0.263 | 1.728 | 0.153 | 298 / 298 | identical |  |
| covariates-5 | 100,000 | 1,000 | 5 | efron | 2 | 0.166 | 0.28 | 1.688 | 0.147 | 0.269 | 1.831 | 0.114 | 292 / 297 | identical | TOO SLOW |
| covariates-5 | 100,000 | 1,000 | 5 | robust | 1 | 0.22 | 0.414 | 1.879 | 0.192 | 0.327 | 1.701 | 0.194 | 300 / 306 | identical |  |
| covariates-5 | 100,000 | 1,000 | 5 | robust | 2 | 0.211 | 0.445 | 2.110 | 0.193 | 0.338 | 1.756 | 0.234 | 300 / 303 | identical | TOO SLOW |
| covariates-50 | 100,000 | 1,000 | 50 | breslow | 1 | 1.78 | 3.15 | 1.771 | 1.56 | 2.13 | 1.372 | 1.37 | 425 / 455 | identical |  |
| covariates-50 | 100,000 | 1,000 | 50 | breslow | 2 | 2.04 | 1.88 | 0.922 | 1.65 | 1.71 | 1.036 | -0.159 | 423 / 456 | identical | ok |
| covariates-50 | 100,000 | 1,000 | 50 | efron | 1 | 1.65 | 1.99 | 1.207 | 1.61 | 1.84 | 1.143 | 0.341 | 426 / 456 | identical |  |
| covariates-50 | 100,000 | 1,000 | 50 | efron | 2 | 1.67 | 1.96 | 1.175 | 1.62 | 1.95 | 1.207 | 0.292 | 426 / 457 | identical | TOO SLOW |
| covariates-50 | 100,000 | 1,000 | 50 | robust | 1 | 2.43 | 2.36 | 0.972 | 2.23 | 2.33 | 1.041 | -0.0681 | 529 / 511 | identical |  |
| covariates-50 | 100,000 | 1,000 | 50 | robust | 2 | 2.16 | 2.31 | 1.070 | 2 | 2.24 | 1.124 | 0.151 | 530 / 511 | identical | ok |

## Where the fit's time goes

The fit's time beyond the engine call, the preparation of the engine's inputs from the data frame, and what is left: the adapter's own steps, the model object, and noise. The last column is the MUST's verdict (DEC-105): DEC-038's rule against the engine call plus the preparation (medians, and fastest runs plus the preparation).

| Scenario | Task | Round | Fit − engine, median | Inputs' preparation, median of 3 | Fit − engine − preparation | Ratio, fit / (engine + preparation), medians | Fastest | Verdict (DEC-105) |
|---|---|---|---|---|---|---|---|---|
| center | breslow | 1 | 0.238 | 0.138 | 0.1 | 1.150 | 1.276 |  |
| center | breslow | 2 | 0.154 | 0.19 | -0.0354 | 0.958 | 1.100 | ok |
| center | efron | 1 | 0.169 | 0.165 | 0.00481 | 1.007 | 1.174 |  |
| center | efron | 2 | 0.371 | 0.142 | 0.229 | 1.347 | 1.288 | ok |
| center | robust | 1 | 0.301 | 0.153 | 0.147 | 1.179 | 1.098 |  |
| center | robust | 2 | 0.0446 | 0.17 | -0.125 | 0.892 | 0.845 | ok |
| rows-1e4 | breslow | 1 | 0.0445 | 0.0179 | 0.0266 | 1.396 | 1.329 |  |
| rows-1e4 | breslow | 2 | 0.0352 | 0.0156 | 0.0197 | 1.341 | 1.304 | ok |
| rows-1e4 | efron | 1 | 0.0616 | 0.0159 | 0.0457 | 1.804 | 1.805 |  |
| rows-1e4 | efron | 2 | 0.0363 | 0.0285 | 0.00775 | 1.100 | 1.200 | ok |
| rows-1e4 | robust | 1 | 0.0163 | 0.0285 | -0.0123 | 0.910 | 0.847 |  |
| rows-1e4 | robust | 2 | 0.0717 | 0.0169 | 0.0547 | 1.693 | 1.561 | ok |
| rows-1e6 | breslow | 1 | 0.191 | 2.4 | -2.21 | 0.735 | 0.806 |  |
| rows-1e6 | breslow | 2 | 1.22 | 1.79 | -0.565 | 0.912 | 0.927 | ok |
| rows-1e6 | efron | 1 | 1.95 | 1.43 | 0.522 | 1.084 | 1.051 |  |
| rows-1e6 | efron | 2 | 1.82 | 1.52 | 0.292 | 1.043 | 0.976 | ok |
| rows-1e6 | robust | 1 | 2.7 | 1.58 | 1.11 | 1.155 | 1.070 |  |
| rows-1e6 | robust | 2 | 4.41 | 1.61 | 2.8 | 1.378 | 1.120 | ok |
| providers-100 | breslow | 1 | 0.172 | 0.222 | -0.0504 | 0.931 | 1.071 |  |
| providers-100 | breslow | 2 | 0.142 | 0.21 | -0.0679 | 0.907 | 0.885 | ok |
| providers-100 | efron | 1 | 0.145 | 0.24 | -0.0948 | 0.882 | 0.985 |  |
| providers-100 | efron | 2 | 0.157 | 0.206 | -0.0495 | 0.933 | 1.029 | ok |
| providers-100 | robust | 1 | 0.154 | 0.109 | 0.0458 | 1.056 | 1.206 |  |
| providers-100 | robust | 2 | 0.0817 | 0.111 | -0.0291 | 0.965 | 1.196 | ok |
| providers-7500 | breslow | 1 | 0.4 | 0.158 | 0.241 | 1.385 | 1.330 |  |
| providers-7500 | breslow | 2 | 0.311 | 0.162 | 0.15 | 1.259 | 1.158 | TOO SLOW |
| providers-7500 | efron | 1 | 0.294 | 0.162 | 0.132 | 1.230 | 1.107 |  |
| providers-7500 | efron | 2 | 0.208 | 0.169 | 0.0394 | 1.062 | 1.051 | ok |
| providers-7500 | robust | 1 | 0.281 | 0.157 | 0.124 | 1.157 | 1.059 |  |
| providers-7500 | robust | 2 | 0.293 | 0.159 | 0.134 | 1.173 | 1.045 | ok |
| covariates-5 | breslow | 1 | 0.132 | 0.117 | 0.0151 | 1.053 | 1.025 |  |
| covariates-5 | breslow | 2 | 0.542 | 0.143 | 0.399 | 2.175 | 1.057 | ok |
| covariates-5 | efron | 1 | 0.153 | 0.113 | 0.0403 | 1.150 | 0.993 |  |
| covariates-5 | efron | 2 | 0.114 | 0.134 | -0.0199 | 0.934 | 0.959 | ok |
| covariates-5 | robust | 1 | 0.194 | 0.104 | 0.0897 | 1.277 | 1.104 |  |
| covariates-5 | robust | 2 | 0.234 | 0.106 | 0.128 | 1.402 | 1.131 | TOO SLOW |
| covariates-50 | breslow | 1 | 1.37 | 0.293 | 1.08 | 1.521 | 1.155 |  |
| covariates-50 | breslow | 2 | -0.159 | 0.271 | -0.43 | 0.814 | 0.889 | ok |
| covariates-50 | efron | 1 | 0.341 | 0.27 | 0.0716 | 1.037 | 0.979 |  |
| covariates-50 | efron | 2 | 0.292 | 0.275 | 0.0166 | 1.009 | 1.032 | ok |
| covariates-50 | robust | 1 | -0.0681 | 0.186 | -0.254 | 0.903 | 0.961 |  |
| covariates-50 | robust | 2 | 0.151 | 0.181 | -0.0297 | 0.987 | 1.031 | ok |

## The fit against coxph() on the data frame

The call a user would make: `coxph()` with the provider as strata, the offset, and the weights, and for robust one cluster per row (C1's comparator, DEC-098; the package called it before DEC-099). Reported, not a gate. Its estimates come from rows in the generator's order, so they can differ from the engine call's in the last bits.

| Scenario | Task | Round | coxph() median | Fit median | Ratio, fit / coxph() | Peak MB, coxph() / fit | coxph()'s largest relative difference from the engine call |
|---|---|---|---|---|---|---|---|
| center | breslow | 1 | 2.06 | 0.771 | 0.375 | 415 / 350 | 0 |
| center | breslow | 2 | 2 | 0.818 | 0.409 | 415 / 338 | 0 |
| center | efron | 1 | 2.21 | 0.728 | 0.329 | 415 / 350 | 0 |
| center | efron | 2 | 1.97 | 0.888 | 0.451 | 414 / 343 | 0 |
| center | robust | 1 | 3.71 | 0.972 | 0.262 | 453 / 385 | 6.7e-13 |
| center | robust | 2 | 2.79 | 1.03 | 0.369 | 454 / 385 | 6.7e-13 |
| rows-1e4 | breslow | 1 | 0.118 | 0.0939 | 0.796 | 262 / 261 | 0 |
| rows-1e4 | breslow | 2 | 0.124 | 0.0774 | 0.626 | 262 / 261 | 0 |
| rows-1e4 | efron | 1 | 0.115 | 0.103 | 0.896 | 264 / 261 | 0 |
| rows-1e4 | efron | 2 | 0.169 | 0.0855 | 0.505 | 264 / 262 | 0 |
| rows-1e4 | robust | 1 | 0.209 | 0.124 | 0.592 | 275 / 261 | 9.3e-14 |
| rows-1e4 | robust | 2 | 0.324 | 0.134 | 0.412 | 274 / 260 | 9.3e-14 |
| rows-1e6 | breslow | 1 | 26.2 | 6.13 | 0.234 | 1399 / 1230 | 0 |
| rows-1e6 | breslow | 2 | 20.4 | 5.85 | 0.286 | 1414 / 1230 | 0 |
| rows-1e6 | efron | 1 | 21.3 | 6.77 | 0.317 | 1415 / 1230 | 0 |
| rows-1e6 | efron | 2 | 21.1 | 7.06 | 0.334 | 1415 / 1230 | 0 |
| rows-1e6 | robust | 1 | 31.9 | 8.32 | 0.261 | 2143 / 1440 | 1.9e-12 |
| rows-1e6 | robust | 2 | 37.9 | 10.2 | 0.270 | 2234 / 1440 | 1.9e-12 |
| providers-100 | breslow | 1 | 1.67 | 0.676 | 0.405 | 414 / 351 | 0 |
| providers-100 | breslow | 2 | 1.53 | 0.66 | 0.432 | 414 / 351 | 0 |
| providers-100 | efron | 1 | 1.67 | 0.709 | 0.424 | 414 / 351 | 0 |
| providers-100 | efron | 2 | 1.68 | 0.693 | 0.412 | 414 / 350 | 0 |
| providers-100 | robust | 1 | 2.02 | 0.868 | 0.431 | 452 / 373 | 2.8e-12 |
| providers-100 | robust | 2 | 2.1 | 0.804 | 0.383 | 452 / 373 | 2.8e-12 |
| providers-7500 | breslow | 1 | 1.61 | 0.868 | 0.539 | 436 / 340 | 0 |
| providers-7500 | breslow | 2 | 1.97 | 0.726 | 0.369 | 436 / 339 | 0 |
| providers-7500 | efron | 1 | 1.61 | 0.708 | 0.441 | 436 / 340 | 0 |
| providers-7500 | efron | 2 | 1.65 | 0.676 | 0.411 | 435 / 340 | 0 |
| providers-7500 | robust | 1 | 2.04 | 0.912 | 0.447 | 452 / 372 | 2.4e-13 |
| providers-7500 | robust | 2 | 2.08 | 0.904 | 0.435 | 452 / 373 | 2.4e-13 |
| covariates-5 | breslow | 1 | 0.814 | 0.301 | 0.370 | 337 / 296 | 0 |
| covariates-5 | breslow | 2 | 0.711 | 0.739 | 1.039 | 336 / 297 | 0 |
| covariates-5 | efron | 1 | 0.758 | 0.309 | 0.408 | 338 / 298 | 0 |
| covariates-5 | efron | 2 | 0.864 | 0.28 | 0.324 | 337 / 297 | 0 |
| covariates-5 | robust | 1 | 0.973 | 0.414 | 0.425 | 366 / 306 | 2.7e-14 |
| covariates-5 | robust | 2 | 1.42 | 0.445 | 0.314 | 362 / 303 | 2.7e-14 |
| covariates-50 | breslow | 1 | 4.49 | 3.15 | 0.702 | 528 / 455 | 0 |
| covariates-50 | breslow | 2 | 4.5 | 1.88 | 0.418 | 528 / 456 | 0 |
| covariates-50 | efron | 1 | 4.54 | 1.99 | 0.439 | 528 / 456 | 0 |
| covariates-50 | efron | 2 | 4.71 | 1.96 | 0.417 | 500 / 457 | 0 |
| covariates-50 | robust | 1 | 5.57 | 2.36 | 0.424 | 577 / 511 | 8.2e-12 |
| covariates-50 | robust | 2 | 5.64 | 2.31 | 0.409 | 671 / 511 | 8.2e-12 |

## The fits beside C1's baseline

C1's engine calls (`cox-engines-20261008-windows.csv`: `agreg.fit()` on the rows in the generator's order with the raw offset, and for robust `coxph(cluster = row)`, DEC-100) and pprof_py 0.7.0 on Python 3.12.3 with numba's default threads (8, `cox-pprof_py-20261008-windows.csv`), measured in another session, so the ratios are indicative only. The brief's §3.7 SHOULD (no slower than pprof_py) applies to the robust variance, not to the fits at large sizes (DEC-098). The fit's time is the median of its rounds' medians.

| Scenario | Task | Fit median | C1 engine median | pprof_py median | Ratio, fit / pprof_py |
|---|---|---|---|---|---|
| center | breslow | 0.795 | 0.879 | 1.15 | 0.690 |
| center | efron | 0.808 | 0.824 | 1.22 | 0.661 |
| center | robust | 1 | 3.24 | 1.11 | 0.902 |
| rows-1e4 | breslow | 0.0856 | 0.0818 | 0.375 | 0.228 |
| rows-1e4 | efron | 0.0941 | 0.114 | 0.42 | 0.224 |
| rows-1e4 | robust | 0.129 | 0.182 | 0.401 | 0.321 |
| rows-1e6 | breslow | 5.99 | 17.2 | 4.3 | 1.391 |
| rows-1e6 | efron | 6.92 | 22.3 | 6.83 | 1.013 |
| rows-1e6 | robust | 9.28 | 130 | 5.24 | 1.770 |
| providers-100 | breslow | 0.668 | 1.29 | 0.381 | 1.754 |
| providers-100 | efron | 0.701 | 2.89 | 0.59 | 1.188 |
| providers-100 | robust | 0.836 | 2.7 | 0.441 | 1.899 |
| providers-7500 | breslow | 0.797 | 0.86 | 3.65 | 0.218 |
| providers-7500 | efron | 0.692 | 0.842 | 4.02 | 0.172 |
| providers-7500 | robust | 0.908 | 2.85 | 3.73 | 0.243 |
| covariates-5 | breslow | 0.52 | 0.258 | 0.638 | 0.816 |
| covariates-5 | efron | 0.294 | 0.227 | 0.695 | 0.424 |
| covariates-5 | robust | 0.429 | 1.55 | 0.844 | 0.508 |
| covariates-50 | breslow | 2.52 | 3.37 | 1.67 | 1.509 |
| covariates-50 | efron | 1.98 | 5.34 | 3.53 | 0.560 |
| covariates-50 | robust | 2.34 | 8.84 | 1.83 | 1.275 |

## Measures and tests beside pprof_py's

The `profile` task fits once outside the timing, then times on that fit: the expected events' closed form (`cox_expected_events()`, which the fit itself runs), `standardize_providers()` with both standardizations, `test_providers()` with each test followed by `standardize_providers()` with that test's interval, and `funnel_limits()`. pprof_py's `calculate_standardized_measures()` and `test()` compute the expected events themselves, so its times are set beside the package's plus the expected events. Medians of the rounds' medians, in seconds; pprof_py's are C1's, from another session, so the ratios are indicative. The brief's §3.7 MUST: mid-p limits substantially faster than pprof_py's, read as at least ten times (DEC-111).

| Scenario | Providers | Expected events | Measures | pprof_py measures | Mid-p test and limits | pprof_py mid-p | pprof_py / package, mid-p | Exact test and limits | pprof_py exact | Funnel | Mid-p verdict |
|---|---|---|---|---|---|---|---|---|---|---|---|
| center | 1,000 | 0.0281 | 0.0957 | 0.122 | 0.0766 | 10.7 | 102 | 0.0249 | 0.101 | 0.0423 | ok |
| rows-1e4 | 1,000 | 0.0033 | 0.0281 | 0.00879 | 0.0407 | 9.14 | 208 | 0.0161 | 0.0126 | 0.0324 | ok |
| rows-1e6 | 1,000 | 0.293 | 0.804 | 1.32 | 0.273 | 14.5 | 26 | 0.13 | 1.38 | 0.161 | ok |
| providers-100 | 100 | 0.028 | 0.0737 | 0.0919 | 0.0433 | 1.45 | 20 | 0.0151 | 0.0947 | 0.018 | ok |
| providers-7500 | 7,500 | 0.0292 | 0.201 | 0.128 | 0.11 | 83.4 | 601 | 0.0794 | 0.119 | 0.167 | ok |
| covariates-5 | 1,000 | 0.0291 | 0.088 | 0.0923 | 0.0719 | 12.5 | 124 | 0.0234 | 0.0973 | 0.0411 | ok |
| covariates-50 | 1,000 | 0.028 | 0.0923 | 0.106 | 0.0782 | 14.2 | 133 | 0.0253 | 0.162 | 0.0413 | ok |
