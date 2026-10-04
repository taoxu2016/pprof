# Benchmark comparison: `working-tree-20261003-windows-phase4.csv` versus baseline `reference-baseline-20261002-windows.csv`

- Tasks compared: 47; regressions: 31; to rerun: 0; status changes: 0.

| Scenario | Task | Baseline median s | Baseline fastest s | New median s | New fastest s | Median ratio | Fastest ratio | Baseline peak MB | New peak MB | Status |
|---|---|---|---|---|---|---|---|---|---|---|
| bin-1e4-m100-p5 | confint[option=gamma] | 1.94 | 1.94 | 1.92 | 1.92 | 0.99 | 0.988 | 332.18 | 392.55 | REGRESSION |
| bin-1e4-m100-p5 | confint[option=SM] | 2.21 | 2.15 | 1.94 | 1.92 | 0.877 | 0.893 | 324.38 | 391.21 | REGRESSION |
| bin-1e4-m100-p5 | logis_cre | 8.56 | 8.26 | 8.65 | 8.46 | 1.01 | 1.02 | 334.12 |  398.9 | REGRESSION |
| bin-1e4-m100-p5 | logis_fe | 0.0455 | 0.0386 | 0.033 | 0.0287 | 0.724 | 0.744 | 309.47 | 367.83 | REGRESSION |
| bin-1e4-m100-p5 | logis_fe[method=BAN] | 0.0652 | 0.0569 | 0.0543 | 0.0479 | 0.833 | 0.842 | 304.27 | 368.06 | REGRESSION |
| bin-1e4-m100-p5 | logis_firth | 0.0468 | 0.0397 | 0.0412 | 0.0352 | 0.88 | 0.886 | 309.23 | 368.25 | REGRESSION |
| bin-1e4-m100-p5 | logis_re | 4.06 |    4 | 3.72 |  3.7 | 0.916 | 0.925 | 331.58 | 399.34 | REGRESSION |
| bin-1e4-m100-p5 | SM_output[stdz=direct] | 0.0341 | 0.0337 | 0.0392 | 0.0378 | 1.15 | 1.12 | 308.92 | 373.55 | REGRESSION |
| bin-1e4-m100-p5 | SM_output[stdz=indirect] | 0.00207 | 0.00168 | 0.00883 | 0.00687 | 4.26 | 4.09 | 308.89 | 373.79 | REGRESSION |
| bin-1e4-m100-p5 | summary[test=lr] | 0.475 | 0.451 | 0.106 | 0.101 | 0.223 | 0.224 | 331.57 | 374.13 | ok |
| bin-1e4-m100-p5 | summary[test=wald] | 0.000508 | 0.00042 | 0.00481 | 0.00402 | 9.47 | 9.56 |    314 | 373.89 | REGRESSION |
| bin-1e4-m100-p5 | test[test=exact.poisbinom] | 0.0916 | 0.0899 | 0.0799 | 0.0774 | 0.872 | 0.861 | 308.82 | 374.01 | REGRESSION |
| bin-1e4-m100-p5 | test[test=score,score_modified=FALSE] | 0.0304 | 0.0296 | 0.034 | 0.0321 | 1.12 | 1.09 | 313.68 | 374.02 | REGRESSION |
| bin-1e4-m100-p5 | test[test=score] | 0.00661 | 0.00371 | 0.00603 | 0.00492 | 0.911 | 1.33 | 309.07 | 374.07 | REGRESSION |
| bin-1e4-m100-p5 | test[test=wald] | 0.00089 | 0.000791 | 0.00509 | 0.00414 | 5.72 | 5.24 | 308.93 |  373.7 | REGRESSION |
| bin-1e5-m1000-p20 | logis_fe | 1.61 | 1.52 | 1.04 | 0.872 | 0.647 | 0.575 |  449.8 | 468.63 | ok |
| bin-1e5-m1000-p5-common | logis_fe | 0.916 | 0.612 | 0.425 | 0.298 | 0.464 | 0.487 | 349.56 | 402.11 | REGRESSION |
| bin-1e5-m1000-p5-rare | logis_fe | 0.776 | 0.73 |  0.5 | 0.364 | 0.644 | 0.499 | 349.33 | 403.53 | REGRESSION |
| bin-1e5-m1000-p5-skewed | logis_fe | 0.864 |  0.6 | 0.329 | 0.297 | 0.381 | 0.495 |  348.7 | 415.47 | REGRESSION |
| bin-1e5-m1000-p5 | confint[option=gamma] | 19.6 | 19.6 | 19.1 | 19.1 | 0.973 | 0.971 | 376.56 | 408.22 | ok |
| bin-1e5-m1000-p5 | logis_fe | 0.712 | 0.69 | 0.435 | 0.337 | 0.611 | 0.489 | 349.28 | 402.98 | REGRESSION |
| bin-1e5-m1000-p5 | logis_fe[method=BAN] | 0.73 | 0.647 | 0.577 | 0.466 | 0.791 | 0.72 | 348.56 | 403.56 | REGRESSION |
| bin-1e5-m1000-p5 | logis_firth | 0.599 | 0.486 | 0.431 | 0.318 | 0.72 | 0.653 | 348.81 | 402.23 | REGRESSION |
| bin-1e5-m1000-p5 | logis_re | 52.8 | 52.7 | 55.3 | 54.5 | 1.05 | 1.03 | 412.71 | 463.09 | REGRESSION |
| bin-1e5-m1000-p5 | SM_output[stdz=direct] | 3.29 | 3.29 | 3.34 | 3.33 | 1.01 | 1.01 |  351.2 | 403.12 | REGRESSION |
| bin-1e5-m1000-p5 | SM_output[stdz=indirect] | 0.015 | 0.0128 | 0.0437 | 0.033 | 2.91 | 2.59 | 351.95 | 403.23 | REGRESSION |
| bin-1e5-m1000-p5 | summary[test=wald] | 0.000565 | 0.000485 | 0.023 | 0.0168 | 40.6 | 34.7 | 351.12 | 403.14 | REGRESSION |
| bin-1e5-m1000-p5 | test[test=exact.poisbinom] | 1.33 | 0.969 | 0.786 | 0.774 | 0.591 | 0.799 |  428.6 | 405.76 | ok |
| bin-1e5-m1000-p5 | test[test=score,score_modified=FALSE] |  3.1 |  3.1 | 3.29 |  3.2 | 1.06 | 1.03 | 351.22 | 403.46 | REGRESSION |
| bin-1e5-m1000-p5 | test[test=score] | 0.025 | 0.0176 | 0.0437 | 0.0403 | 1.75 | 2.29 | 351.87 | 403.21 | REGRESSION |
| bin-1e5-m1000-p5 | test[test=wald] | 0.00407 | 0.00317 | 0.0243 | 0.0175 | 5.97 | 5.53 | 351.71 | 402.98 | REGRESSION |
| bin-1e5-m10000-p5 | logis_fe | 0.904 | 0.862 | 0.635 | 0.598 | 0.702 | 0.693 | 344.69 | 394.91 | REGRESSION |
| bin-1e6-m1000-p5 | logis_fe | 5.22 | 4.88 |  3.2 | 2.98 | 0.613 | 0.611 | 701.35 | 685.01 | ok |
| bin-1e6-m1000-p5 | logis_fe[method=BAN] | 6.24 | 6.13 | 4.55 | 4.34 | 0.73 | 0.708 | 753.82 | 690.99 | ok |
| bin-1e6-m1000-p5 | logis_firth | 5.19 | 4.82 |  3.1 | 2.95 | 0.598 | 0.612 | 754.19 | 673.58 | ok |
| bin-1e6-m1000-p50 | logis_fe |   44 | 41.8 | 30.4 | 30.2 | 0.691 | 0.723 | 2101.6 | 2566.5 | REGRESSION |
| bin-1e6-m10000-p5 | logis_fe | 6.67 | 5.83 | 3.85 |  3.6 | 0.577 | 0.617 | 697.13 | 684.33 | ok |
| lin-1e4-m100-p5 | linear_cre | 0.105 | 0.0979 | 0.101 | 0.0953 | 0.959 | 0.973 | 324.76 | 392.53 | REGRESSION |
| lin-1e4-m100-p5 | linear_fe | 0.444 | 0.406 | 0.0084 | 0.00625 | 0.0189 | 0.0154 | 351.68 | 363.81 | ok |
| lin-1e4-m100-p5 | linear_re | 0.0864 | 0.081 | 0.101 | 0.088 | 1.16 | 1.09 | 319.12 | 386.13 | REGRESSION |
| lin-1e5-m100-p5 | linear_fe |  |  |  |  |  |  |  |  | ok |
| lin-1e5-m1000-p5 | confint | 0.0212 | 0.0169 | 0.0215 | 0.016 | 1.02 | 0.945 | 841.06 | 402.57 | ok |
| lin-1e5-m1000-p5 | linear_fe | 3.25 | 3.08 | 0.0771 | 0.0652 | 0.0237 | 0.0212 |  801.3 | 396.75 | ok |
| lin-1e5-m1000-p5 | linear_re | 1.04 | 0.98 | 1.03 | 0.994 | 0.983 | 1.01 | 392.82 | 429.83 | ok |
| lin-1e5-m1000-p5 | SM_output[stdz=indirect+direct] | 0.419 | 0.37 | 0.398 | 0.335 | 0.95 | 0.906 | 843.01 | 419.84 | ok |
| lin-1e5-m1000-p5 | test | 0.00424 | 0.00344 | 0.00413 | 0.00343 | 0.973 | 0.998 | 843.55 | 404.88 | ok |
| lin-1e5-m10000-p5 | linear_fe | 9.14 | 8.69 | 0.172 | 0.155 | 0.0188 | 0.0179 | 491.55 |  391.5 | ok |
| lin-1e6-m100000-p5 | linear_fe | 95.9 | 93.9 | 1.99 | 1.96 | 0.0207 | 0.0209 | 1290.5 | 608.96 | ok |
