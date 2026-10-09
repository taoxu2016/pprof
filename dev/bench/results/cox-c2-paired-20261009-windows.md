# Paired benchmark of the stratified Cox fit against its engine calls

Run on 2026-10-09 at commit `2b856ec` (`dev/bench/cox/run_paired.R`, 2 round(s), package code unchanged from the commit): Intel64 Family 6 Model 140 Stepping 1, GenuineIntel, 8 logical cores; R version 4.4.0 (2024-04-24 ucrt) with survival 3.8.12; pprof 2.0.0 installed with `--preclean`. The R engines are single-threaded.

Each round runs the engine call, `coxph()`, and the fit, each in a fresh process, one after the other, on the same data (`dev/bench/cox/scenarios.R`, C1's grid). The engine call is survival's fitter as the adapter calls it, on the inputs the adapter builds, prepared outside the timing (DEC-100); for the robust fit, the fitter followed by coxph()'s robust step with one cluster per row (DEC-099). The fit is `fit_cox_stratified()` on the data frame, with weights and an offset, from the formula to the model object. The preparation of the engine's inputs from the data frame (`data_prepare()` and the adapter's inputs) is timed in the engine's process after its measurement: the median of three calls.

Rule (the brief's §3.7 MUST, DEC-105): a fit is too slow when, in every round, its median and its fastest run are more than 10% above the engine call's plus the preparation of its inputs, and its median at least 0.05 s above (DEC-038). The verdict against the engine call alone, the C2 plan's comparator, is given beside it. The fit's estimates must equal the engine call's bitwise (coefficients, and the robust variance). Times in seconds; peak memory of the process after the first run, in MB (recorded, DEC-004).

- Fits: 21; too slow against the engine call plus the preparation of its inputs (DEC-105): 0.
- Too slow against the engine call alone: 17; failed or differing from the engine call: 0.

## Notes on this run

- **The corner scenario is not in this report.** The machine (7.4 GB of memory) paged throughout the session: about 10,000 pages per second with nothing of the session running, the other applications committing 17 GB. The corner (1,000,000 rows, 7,500 providers, 50 covariates) needs about 2 GB per process (C1's peaks), and one of its fits, in a fresh process, took 28.7 s of which 11.0 s on a processor. The one round run before the corner was stopped (Breslow ties: engine call 23.0 s, `coxph()` 94.2 s, fit 40.8 s, the inputs' preparation 3.9 s; the estimates identical) measures the paging as much as the code. C1's baseline (`cox-baseline-20261008-windows.md`) holds the corner's engine and pprof_py times.
- **At 1,000,000 rows** the processes got about three-quarters of a processor: in a separate check, the fitter took 4.1 s against 3.0 to 3.3 s of processor time and the fit 6.0 to 6.6 s against 4.5 to 4.8 s. The ratios of fit to engine call stand; the times are longer than on a quiet machine.
- **The parts of the fit**, in one process, are in `dev/design/coxph-facts/21_fit_time_parts.txt`: at 20 covariates the model frame alone takes 13% of the fitter's time, and `data_prepare()` 27% (100,000 rows) to 33% (1,000,000 rows).
- Single runs on this machine vary by up to a factor of 1.7 for the same call (`center`, Breslow: the fit's median 1.19 s in one round and 0.707 s in the next), which DEC-038's rule absorbs by asking for a slowdown in every round.

## The fit against its engine call

| Scenario | Rows | Providers | Covariates | Task | Round | Engine median | Fit median | Ratio | Engine fastest | Fit fastest | Ratio | Fit − engine, median | Peak MB, engine / fit | Estimates | Verdict against the engine call alone |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| center | 100,000 | 1,000 | 20 | breslow | 1 | 0.505 | 1.19 | 2.346 | 0.438 | 0.746 | 1.703 | 0.68 | 349 / 343 | identical |  |
| center | 100,000 | 1,000 | 20 | breslow | 2 | 0.501 | 0.707 | 1.412 | 0.421 | 0.587 | 1.392 | 0.206 | 344 / 355 | identical | TOO SLOW |
| center | 100,000 | 1,000 | 20 | efron | 1 | 0.507 | 0.716 | 1.410 | 0.453 | 0.597 | 1.319 | 0.208 | 349 / 354 | identical |  |
| center | 100,000 | 1,000 | 20 | efron | 2 | 0.468 | 0.806 | 1.721 | 0.429 | 0.573 | 1.335 | 0.337 | 349 / 355 | identical | TOO SLOW |
| center | 100,000 | 1,000 | 20 | robust | 1 | 0.67 | 0.796 | 1.188 | 0.574 | 0.707 | 1.231 | 0.126 | 357 / 390 | identical |  |
| center | 100,000 | 1,000 | 20 | robust | 2 | 0.637 | 0.812 | 1.274 | 0.537 | 0.682 | 1.270 | 0.175 | 355 / 390 | identical | TOO SLOW |
| rows-1e4 | 10,000 | 1,000 | 20 | breslow | 1 | 0.0624 | 0.06 | 0.962 | 0.0517 | 0.0535 | 1.036 | -0.00239 | 250 / 263 | identical |  |
| rows-1e4 | 10,000 | 1,000 | 20 | breslow | 2 | 0.0349 | 0.0597 | 1.709 | 0.0323 | 0.0533 | 1.652 | 0.0248 | 254 / 262 | identical | ok |
| rows-1e4 | 10,000 | 1,000 | 20 | efron | 1 | 0.0395 | 0.057 | 1.444 | 0.0363 | 0.0489 | 1.348 | 0.0175 | 250 / 263 | identical |  |
| rows-1e4 | 10,000 | 1,000 | 20 | efron | 2 | 0.0362 | 0.057 | 1.573 | 0.0321 | 0.0503 | 1.567 | 0.0208 | 254 / 263 | identical | ok |
| rows-1e4 | 10,000 | 1,000 | 20 | robust | 1 | 0.0662 | 0.0773 | 1.168 | 0.05 | 0.0651 | 1.303 | 0.0111 | 263 / 265 | identical |  |
| rows-1e4 | 10,000 | 1,000 | 20 | robust | 2 | 0.0525 | 0.0699 | 1.331 | 0.0455 | 0.0637 | 1.398 | 0.0174 | 262 / 264 | identical | ok |
| rows-1e6 | 1,000,000 | 1,000 | 20 | breslow | 1 | 5.09 | 7.65 | 1.503 | 4.89 | 7.47 | 1.527 | 2.56 | 1100 / 1181 | identical |  |
| rows-1e6 | 1,000,000 | 1,000 | 20 | breslow | 2 | 5.45 | 8.34 | 1.531 | 5.25 | 7.4 | 1.409 | 2.89 | 1181 / 1181 | identical | TOO SLOW |
| rows-1e6 | 1,000,000 | 1,000 | 20 | efron | 1 | 5.7 | 8.05 | 1.413 | 5.55 | 7.83 | 1.410 | 2.35 | 1181 / 1180 | identical |  |
| rows-1e6 | 1,000,000 | 1,000 | 20 | efron | 2 | 6.11 | 7.86 | 1.287 | 5.97 | 7.59 | 1.270 | 1.75 | 1181 / 1181 | identical | TOO SLOW |
| rows-1e6 | 1,000,000 | 1,000 | 20 | robust | 1 | 7.12 | 10.8 | 1.522 | 6.71 | 9.1 | 1.357 | 3.72 | 1339 / 1441 | identical |  |
| rows-1e6 | 1,000,000 | 1,000 | 20 | robust | 2 | 7.84 | 9.33 | 1.190 | 7.27 | 9.1 | 1.252 | 1.49 | 1339 / 1443 | identical | TOO SLOW |
| providers-100 | 100,000 | 100 | 20 | breslow | 1 | 0.55 | 0.615 | 1.119 | 0.436 | 0.589 | 1.352 | 0.0654 | 350 / 354 | identical |  |
| providers-100 | 100,000 | 100 | 20 | breslow | 2 | 0.386 | 0.599 | 1.552 | 0.381 | 0.595 | 1.562 | 0.213 | 349 / 355 | identical | TOO SLOW |
| providers-100 | 100,000 | 100 | 20 | efron | 1 | 0.528 | 0.763 | 1.445 | 0.458 | 0.686 | 1.497 | 0.235 | 349 / 355 | identical |  |
| providers-100 | 100,000 | 100 | 20 | efron | 2 | 0.443 | 0.719 | 1.620 | 0.416 | 0.656 | 1.577 | 0.275 | 349 / 354 | identical | TOO SLOW |
| providers-100 | 100,000 | 100 | 20 | robust | 1 | 0.643 | 0.775 | 1.206 | 0.636 | 0.735 | 1.154 | 0.132 | 353 / 377 | identical |  |
| providers-100 | 100,000 | 100 | 20 | robust | 2 | 0.614 | 0.807 | 1.313 | 0.519 | 0.784 | 1.511 | 0.192 | 357 / 377 | identical | TOO SLOW |
| providers-7500 | 100,000 | 7,500 | 20 | breslow | 1 | 0.455 | 0.819 | 1.802 | 0.424 | 0.69 | 1.628 | 0.365 | 344 / 345 | identical |  |
| providers-7500 | 100,000 | 7,500 | 20 | breslow | 2 | 0.431 | 0.656 | 1.524 | 0.361 | 0.632 | 1.751 | 0.226 | 350 / 344 | identical | TOO SLOW |
| providers-7500 | 100,000 | 7,500 | 20 | efron | 1 | 0.375 | 0.74 | 1.977 | 0.37 | 0.651 | 1.759 | 0.366 | 350 / 345 | identical |  |
| providers-7500 | 100,000 | 7,500 | 20 | efron | 2 | 0.366 | 0.647 | 1.770 | 0.357 | 0.641 | 1.794 | 0.282 | 349 / 345 | identical | TOO SLOW |
| providers-7500 | 100,000 | 7,500 | 20 | robust | 1 | 0.655 | 0.799 | 1.219 | 0.622 | 0.735 | 1.182 | 0.144 | 357 / 379 | identical |  |
| providers-7500 | 100,000 | 7,500 | 20 | robust | 2 | 0.604 | 0.806 | 1.335 | 0.519 | 0.8 | 1.540 | 0.202 | 357 / 379 | identical | TOO SLOW |
| covariates-5 | 100,000 | 1,000 | 5 | breslow | 1 | 0.127 | 0.242 | 1.912 | 0.123 | 0.239 | 1.946 | 0.115 | 298 / 299 | identical |  |
| covariates-5 | 100,000 | 1,000 | 5 | breslow | 2 | 0.119 | 0.264 | 2.209 | 0.115 | 0.23 | 2.001 | 0.144 | 297 / 299 | identical | TOO SLOW |
| covariates-5 | 100,000 | 1,000 | 5 | efron | 1 | 0.124 | 0.246 | 1.990 | 0.12 | 0.228 | 1.892 | 0.122 | 297 / 298 | identical |  |
| covariates-5 | 100,000 | 1,000 | 5 | efron | 2 | 0.122 | 0.244 | 2.004 | 0.114 | 0.238 | 2.092 | 0.122 | 296 / 299 | identical | TOO SLOW |
| covariates-5 | 100,000 | 1,000 | 5 | robust | 1 | 0.212 | 0.396 | 1.867 | 0.193 | 0.307 | 1.588 | 0.184 | 309 / 311 | identical |  |
| covariates-5 | 100,000 | 1,000 | 5 | robust | 2 | 0.185 | 0.396 | 2.141 | 0.17 | 0.311 | 1.832 | 0.211 | 309 / 307 | identical | TOO SLOW |
| covariates-50 | 100,000 | 1,000 | 50 | breslow | 1 | 2.01 | 2.42 | 1.202 | 1.58 | 1.83 | 1.159 | 0.406 | 429 / 460 | identical |  |
| covariates-50 | 100,000 | 1,000 | 50 | breslow | 2 | 2.04 | 2.32 | 1.136 | 1.57 | 1.87 | 1.192 | 0.278 | 429 / 460 | identical | TOO SLOW |
| covariates-50 | 100,000 | 1,000 | 50 | efron | 1 | 2.12 | 2.43 | 1.144 | 1.62 | 1.87 | 1.149 | 0.306 | 429 / 460 | identical |  |
| covariates-50 | 100,000 | 1,000 | 50 | efron | 2 | 2.12 | 2.42 | 1.144 | 1.6 | 1.91 | 1.197 | 0.306 | 430 / 460 | identical | TOO SLOW |
| covariates-50 | 100,000 | 1,000 | 50 | robust | 1 | 2.92 | 2.99 | 1.027 | 2.04 | 2.46 | 1.206 | 0.0782 | 528 / 502 | identical |  |
| covariates-50 | 100,000 | 1,000 | 50 | robust | 2 | 2.67 | 4.27 | 1.598 | 1.94 | 3.69 | 1.906 | 1.6 | 528 / 501 | identical | ok |

## Where the fit's time goes

The fit's time beyond the engine call, the preparation of the engine's inputs from the data frame, and what is left: the adapter's own steps, the model object, and noise. The last column is the MUST's verdict (DEC-105): DEC-038's rule against the engine call plus the preparation (medians, and fastest runs plus the preparation).

| Scenario | Task | Round | Fit − engine, median | Inputs' preparation, median of 3 | Fit − engine − preparation | Ratio, fit / (engine + preparation), medians | Fastest | Verdict (DEC-105) |
|---|---|---|---|---|---|---|---|---|
| center | breslow | 1 | 0.68 | 0.32 | 0.36 | 1.436 | 0.984 |  |
| center | breslow | 2 | 0.206 | 0.265 | -0.0584 | 0.924 | 0.855 | ok |
| center | efron | 1 | 0.208 | 0.259 | -0.0512 | 0.933 | 0.838 |  |
| center | efron | 2 | 0.337 | 0.255 | 0.0823 | 1.114 | 0.837 | ok |
| center | robust | 1 | 0.126 | 0.132 | -0.00642 | 0.992 | 1.001 |  |
| center | robust | 2 | 0.175 | 0.15 | 0.0251 | 1.032 | 0.994 | ok |
| rows-1e4 | breslow | 1 | -0.00239 | 0.0275 | -0.0299 | 0.668 | 0.676 |  |
| rows-1e4 | breslow | 2 | 0.0248 | 0.0147 | 0.0101 | 1.203 | 1.135 | ok |
| rows-1e4 | efron | 1 | 0.0175 | 0.0154 | 0.00209 | 1.038 | 0.946 |  |
| rows-1e4 | efron | 2 | 0.0208 | 0.0156 | 0.00518 | 1.100 | 1.055 | ok |
| rows-1e4 | robust | 1 | 0.0111 | 0.0214 | -0.0103 | 0.883 | 0.912 |  |
| rows-1e4 | robust | 2 | 0.0174 | 0.0185 | -0.00114 | 0.984 | 0.994 | ok |
| rows-1e6 | breslow | 1 | 2.56 | 2.5 | 0.0638 | 1.008 | 1.011 |  |
| rows-1e6 | breslow | 2 | 2.89 | 2.02 | 0.877 | 1.117 | 1.018 | ok |
| rows-1e6 | efron | 1 | 2.35 | 1.88 | 0.476 | 1.063 | 1.054 |  |
| rows-1e6 | efron | 2 | 1.75 | 2.3 | -0.551 | 0.934 | 0.917 | ok |
| rows-1e6 | robust | 1 | 3.72 | 2.31 | 1.41 | 1.149 | 1.009 |  |
| rows-1e6 | robust | 2 | 1.49 | 1.96 | -0.469 | 0.952 | 0.987 | ok |
| providers-100 | breslow | 1 | 0.0654 | 0.235 | -0.17 | 0.784 | 0.878 |  |
| providers-100 | breslow | 2 | 0.213 | 0.218 | -0.00506 | 0.992 | 0.994 | ok |
| providers-100 | efron | 1 | 0.235 | 0.211 | 0.0237 | 1.032 | 1.025 |  |
| providers-100 | efron | 2 | 0.275 | 0.215 | 0.0604 | 1.092 | 1.040 | ok |
| providers-100 | robust | 1 | 0.132 | 0.215 | -0.0829 | 0.903 | 0.863 |  |
| providers-100 | robust | 2 | 0.192 | 0.214 | -0.0212 | 0.974 | 1.070 | ok |
| providers-7500 | breslow | 1 | 0.365 | 0.295 | 0.0699 | 1.093 | 0.960 |  |
| providers-7500 | breslow | 2 | 0.226 | 0.37 | -0.144 | 0.820 | 0.865 | ok |
| providers-7500 | efron | 1 | 0.366 | 0.266 | 0.0998 | 1.156 | 1.023 |  |
| providers-7500 | efron | 2 | 0.282 | 0.263 | 0.0186 | 1.030 | 1.033 | ok |
| providers-7500 | robust | 1 | 0.144 | 0.267 | -0.123 | 0.866 | 0.827 |  |
| providers-7500 | robust | 2 | 0.202 | 0.167 | 0.035 | 1.045 | 1.165 | ok |
| covariates-5 | breslow | 1 | 0.115 | 0.115 | 0.0000098 | 1.000 | 1.002 |  |
| covariates-5 | breslow | 2 | 0.144 | 0.106 | 0.0382 | 1.169 | 1.041 | ok |
| covariates-5 | efron | 1 | 0.122 | 0.1 | 0.0219 | 1.098 | 1.031 |  |
| covariates-5 | efron | 2 | 0.122 | 0.103 | 0.0195 | 1.087 | 1.100 | ok |
| covariates-5 | robust | 1 | 0.184 | 0.124 | 0.0603 | 1.179 | 0.968 |  |
| covariates-5 | robust | 2 | 0.211 | 0.206 | 0.00511 | 1.013 | 0.827 | ok |
| covariates-50 | breslow | 1 | 0.406 | 0.37 | 0.0354 | 1.015 | 0.939 |  |
| covariates-50 | breslow | 2 | 0.278 | 0.368 | -0.09 | 0.963 | 0.965 | ok |
| covariates-50 | efron | 1 | 0.306 | 0.38 | -0.0734 | 0.971 | 0.932 |  |
| covariates-50 | efron | 2 | 0.306 | 0.367 | -0.0618 | 0.975 | 0.973 | ok |
| covariates-50 | robust | 1 | 0.0782 | 0.26 | -0.182 | 0.943 | 1.069 |  |
| covariates-50 | robust | 2 | 1.6 | 0.255 | 1.34 | 1.459 | 1.684 | ok |

## The fit against coxph() on the data frame

The call a user would make: `coxph()` with the provider as strata, the offset, and the weights, and for robust one cluster per row (C1's comparator, DEC-098; the package called it before DEC-099). Reported, not a gate. Its estimates come from rows in the generator's order, so they can differ from the engine call's in the last bits.

| Scenario | Task | Round | coxph() median | Fit median | Ratio, fit / coxph() | Peak MB, coxph() / fit | coxph()'s largest relative difference from the engine call |
|---|---|---|---|---|---|---|---|
| center | breslow | 1 | 2.5 | 1.19 | 0.475 | 414 / 343 | 0 |
| center | breslow | 2 | 2.83 | 0.707 | 0.250 | 414 / 355 | 0 |
| center | efron | 1 | 2.34 | 0.716 | 0.305 | 415 / 354 | 0 |
| center | efron | 2 | 2.45 | 0.806 | 0.329 | 414 / 355 | 0 |
| center | robust | 1 | 2.8 | 0.796 | 0.285 | 456 / 390 | 6.7e-13 |
| center | robust | 2 | 2.75 | 0.812 | 0.295 | 456 / 390 | 6.7e-13 |
| rows-1e4 | breslow | 1 | 0.114 | 0.06 | 0.529 | 266 / 263 | 0 |
| rows-1e4 | breslow | 2 | 0.113 | 0.0597 | 0.526 | 268 / 262 | 0 |
| rows-1e4 | efron | 1 | 0.13 | 0.057 | 0.439 | 266 / 263 | 0 |
| rows-1e4 | efron | 2 | 0.111 | 0.057 | 0.512 | 266 / 263 | 0 |
| rows-1e4 | robust | 1 | 0.187 | 0.0773 | 0.413 | 274 / 265 | 9.3e-14 |
| rows-1e4 | robust | 2 | 0.164 | 0.0699 | 0.426 | 273 / 264 | 9.3e-14 |
| rows-1e6 | breslow | 1 | 30.8 | 7.65 | 0.248 | 1458 / 1181 | 0 |
| rows-1e6 | breslow | 2 | 29.4 | 8.34 | 0.284 | 1457 / 1181 | 0 |
| rows-1e6 | efron | 1 | 28.1 | 8.05 | 0.286 | 1457 / 1180 | 0 |
| rows-1e6 | efron | 2 | 29.9 | 7.86 | 0.263 | 1458 / 1181 | 0 |
| rows-1e6 | robust | 1 | 34.9 | 10.8 | 0.311 | 2189 / 1441 | 1.9e-12 |
| rows-1e6 | robust | 2 | 41.3 | 9.33 | 0.226 | 2372 / 1443 | 1.9e-12 |
| providers-100 | breslow | 1 | 2.24 | 0.615 | 0.274 | 413 / 354 | 0 |
| providers-100 | breslow | 2 | 2 | 0.599 | 0.300 | 414 / 355 | 0 |
| providers-100 | efron | 1 | 2.19 | 0.763 | 0.348 | 414 / 355 | 0 |
| providers-100 | efron | 2 | 2.21 | 0.719 | 0.325 | 414 / 354 | 0 |
| providers-100 | robust | 1 | 3.8 | 0.775 | 0.204 | 453 / 377 | 2.8e-12 |
| providers-100 | robust | 2 | 2.91 | 0.807 | 0.277 | 453 / 377 | 2.8e-12 |
| providers-7500 | breslow | 1 | 2.47 | 0.819 | 0.332 | 435 / 345 | 0 |
| providers-7500 | breslow | 2 | 2.22 | 0.656 | 0.296 | 435 / 344 | 0 |
| providers-7500 | efron | 1 | 2.39 | 0.74 | 0.310 | 435 / 345 | 0 |
| providers-7500 | efron | 2 | 2.11 | 0.647 | 0.307 | 436 / 345 | 0 |
| providers-7500 | robust | 1 | 2.98 | 0.799 | 0.268 | 453 / 379 | 2.4e-13 |
| providers-7500 | robust | 2 | 3.03 | 0.806 | 0.266 | 453 / 379 | 2.4e-13 |
| covariates-5 | breslow | 1 | 0.743 | 0.242 | 0.326 | 337 / 299 | 0 |
| covariates-5 | breslow | 2 | 0.736 | 0.264 | 0.359 | 338 / 299 | 0 |
| covariates-5 | efron | 1 | 0.761 | 0.246 | 0.323 | 337 / 298 | 0 |
| covariates-5 | efron | 2 | 1.17 | 0.244 | 0.209 | 337 / 299 | 0 |
| covariates-5 | robust | 1 | 0.973 | 0.396 | 0.407 | 363 / 311 | 2.7e-14 |
| covariates-5 | robust | 2 | 0.958 | 0.396 | 0.414 | 360 / 307 | 2.7e-14 |
| covariates-50 | breslow | 1 | 7.05 | 2.42 | 0.343 | 527 / 460 | 0 |
| covariates-50 | breslow | 2 | 6.39 | 2.32 | 0.363 | 528 / 460 | 0 |
| covariates-50 | efron | 1 | 6.3 | 2.43 | 0.386 | 528 / 460 | 0 |
| covariates-50 | efron | 2 | 6.76 | 2.42 | 0.358 | 528 / 460 | 0 |
| covariates-50 | robust | 1 | 7.85 | 2.99 | 0.381 | 678 / 502 | 8.2e-12 |
| covariates-50 | robust | 2 | 19.7 | 4.27 | 0.216 | 560 / 501 | 8.2e-12 |

## The fits beside C1's baseline

C1's engine calls (`cox-engines-20261008-windows.csv`: `agreg.fit()` on the rows in the generator's order with the raw offset, and for robust `coxph(cluster = row)`, DEC-100) and pprof_py 0.7.0 on Python 3.12.3 with numba's default threads (8, `cox-pprof_py-20261008-windows.csv`), measured in another session, so the ratios are indicative only. The brief's §3.7 SHOULD (no slower than pprof_py) applies to the robust variance, not to the fits at large sizes (DEC-098). The fit's time is the median of its rounds' medians.

| Scenario | Task | Fit median | C1 engine median | pprof_py median | Ratio, fit / pprof_py |
|---|---|---|---|---|---|
| center | breslow | 0.946 | 0.879 | 1.15 | 0.822 |
| center | efron | 0.761 | 0.824 | 1.22 | 0.622 |
| center | robust | 0.804 | 3.24 | 1.11 | 0.725 |
| rows-1e4 | breslow | 0.0598 | 0.0818 | 0.375 | 0.160 |
| rows-1e4 | efron | 0.057 | 0.114 | 0.42 | 0.136 |
| rows-1e4 | robust | 0.0736 | 0.182 | 0.401 | 0.184 |
| rows-1e6 | breslow | 8 | 17.2 | 4.3 | 1.858 |
| rows-1e6 | efron | 7.96 | 22.3 | 6.83 | 1.165 |
| rows-1e6 | robust | 10.1 | 130 | 5.24 | 1.925 |
| providers-100 | breslow | 0.607 | 1.29 | 0.381 | 1.595 |
| providers-100 | efron | 0.741 | 2.89 | 0.59 | 1.255 |
| providers-100 | robust | 0.791 | 2.7 | 0.441 | 1.795 |
| providers-7500 | breslow | 0.738 | 0.86 | 3.65 | 0.202 |
| providers-7500 | efron | 0.694 | 0.842 | 4.02 | 0.172 |
| providers-7500 | robust | 0.803 | 2.85 | 3.73 | 0.215 |
| covariates-5 | breslow | 0.253 | 0.258 | 0.638 | 0.397 |
| covariates-5 | efron | 0.245 | 0.227 | 0.695 | 0.353 |
| covariates-5 | robust | 0.396 | 1.55 | 0.844 | 0.469 |
| covariates-50 | breslow | 2.37 | 3.37 | 1.67 | 1.420 |
| covariates-50 | efron | 2.43 | 5.34 | 3.53 | 0.687 |
| covariates-50 | robust | 3.63 | 8.84 | 1.83 | 1.980 |
