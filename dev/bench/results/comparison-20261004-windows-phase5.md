# Benchmark comparison: `working-tree-20261004-windows-phase5.csv` versus baseline `reference-baseline-20261002+20261004-windows.csv`

- Tasks compared: 79; regressions: 56; to rerun: 0; status changes: 0.

| Scenario | Task | Baseline median s | Baseline fastest s | New median s | New fastest s | Median ratio | Fastest ratio | Baseline peak MB | New peak MB | Status |
|---|---|---|---|---|---|---|---|---|---|---|
| bin-1e4-m100-p5 | confint.logis_cre[option=alpha] | 0.00163 | 0.00144 | 0.00434 | 0.00392 | 2.66 | 2.73 | 325.94 | 397.16 | REGRESSION |
| bin-1e4-m100-p5 | confint.logis_cre[option=SM,stdz=indirect+direct] | 0.107 | 0.106 | 0.11 | 0.11 | 1.03 | 1.03 |  327.4 | 394.65 | REGRESSION |
| bin-1e4-m100-p5 | confint.logis_re[option=alpha] | 0.00823 | 0.00729 | 0.00456 | 0.00411 | 0.554 | 0.564 | 320.94 | 394.65 | REGRESSION |
| bin-1e4-m100-p5 | confint.logis_re[option=SM,stdz=indirect+direct] | 0.145 | 0.143 | 0.111 | 0.111 | 0.767 | 0.773 | 317.93 | 391.02 | REGRESSION |
| bin-1e4-m100-p5 | confint[option=gamma] | 1.94 | 1.94 | 1.88 | 1.88 | 0.969 | 0.968 | 332.18 | 392.33 | REGRESSION |
| bin-1e4-m100-p5 | confint[option=SM] | 2.21 | 2.15 | 1.89 | 1.88 | 0.855 | 0.871 | 324.38 | 394.63 | REGRESSION |
| bin-1e4-m100-p5 | logis_cre | 8.56 | 8.26 | 10.1 | 8.49 | 1.18 | 1.03 | 334.12 |  400.8 | REGRESSION |
| bin-1e4-m100-p5 | logis_fe | 0.0455 | 0.0386 | 0.0452 | 0.0397 | 0.994 | 1.03 | 309.47 | 365.93 | REGRESSION |
| bin-1e4-m100-p5 | logis_fe[method=BAN] | 0.0652 | 0.0569 | 0.0532 | 0.0482 | 0.817 | 0.848 | 304.27 |  365.7 | REGRESSION |
| bin-1e4-m100-p5 | logis_firth | 0.0468 | 0.0397 | 0.0314 | 0.0291 | 0.671 | 0.734 | 309.23 | 369.26 | REGRESSION |
| bin-1e4-m100-p5 | logis_re | 4.06 |    4 |  4.2 | 4.08 | 1.04 | 1.02 | 331.58 | 400.32 | REGRESSION |
| bin-1e4-m100-p5 | SM_output.logis_cre[stdz=indirect+direct] | 0.0353 | 0.035 | 0.0403 | 0.0394 | 1.14 | 1.13 | 327.29 | 394.46 | REGRESSION |
| bin-1e4-m100-p5 | SM_output.logis_re[stdz=indirect+direct] | 0.0549 | 0.0522 | 0.0406 | 0.0397 | 0.739 | 0.761 | 317.84 | 390.46 | REGRESSION |
| bin-1e4-m100-p5 | SM_output[stdz=direct] | 0.0341 | 0.0337 | 0.0386 | 0.0379 | 1.13 | 1.13 | 308.92 | 373.92 | REGRESSION |
| bin-1e4-m100-p5 | SM_output[stdz=indirect] | 0.00207 | 0.00168 | 0.00687 | 0.00611 | 3.31 | 3.63 | 308.89 | 371.76 | REGRESSION |
| bin-1e4-m100-p5 | summary.logis_cre | 0.00181 | 0.00148 | 0.00356 | 0.00319 | 1.97 | 2.16 | 326.62 | 396.51 | REGRESSION |
| bin-1e4-m100-p5 | summary.logis_re | 0.00177 | 0.00147 | 0.00391 | 0.00341 | 2.21 | 2.32 | 321.07 | 391.41 | REGRESSION |
| bin-1e4-m100-p5 | summary[test=lr] | 0.475 | 0.451 | 0.104 | 0.0996 | 0.22 | 0.221 | 331.57 | 371.58 | ok |
| bin-1e4-m100-p5 | summary[test=wald] | 0.000508 | 0.00042 | 0.0046 | 0.00397 | 9.06 | 9.46 |    314 | 371.81 | REGRESSION |
| bin-1e4-m100-p5 | test.logis_cre | 0.00176 | 0.0016 | 0.0045 | 0.00404 | 2.56 | 2.52 | 326.36 | 395.14 | REGRESSION |
| bin-1e4-m100-p5 | test.logis_re | 0.00898 | 0.00761 | 0.00471 | 0.00425 | 0.524 | 0.558 | 318.17 | 391.02 | REGRESSION |
| bin-1e4-m100-p5 | test[test=exact.poisbinom] | 0.0916 | 0.0899 | 0.0784 | 0.0775 | 0.856 | 0.861 | 308.82 | 373.28 | REGRESSION |
| bin-1e4-m100-p5 | test[test=score,score_modified=FALSE] | 0.0304 | 0.0296 | 0.033 | 0.0321 | 1.08 | 1.08 | 313.68 | 371.64 | REGRESSION |
| bin-1e4-m100-p5 | test[test=score] | 0.00661 | 0.00371 | 0.00548 | 0.00489 | 0.829 | 1.32 | 309.07 | 373.96 | REGRESSION |
| bin-1e4-m100-p5 | test[test=wald] | 0.00089 | 0.000791 | 0.00458 | 0.00398 | 5.14 | 5.03 | 308.93 | 371.79 | REGRESSION |
| bin-1e5-m1000-p20 | logis_fe | 1.61 | 1.52 | 1.08 | 1.01 | 0.67 | 0.668 |  449.8 | 463.98 | ok |
| bin-1e5-m1000-p5-common | logis_fe | 0.916 | 0.612 | 0.395 | 0.295 | 0.431 | 0.482 | 349.56 | 402.92 | REGRESSION |
| bin-1e5-m1000-p5-rare | logis_fe | 0.776 | 0.73 | 0.487 | 0.367 | 0.627 | 0.502 | 349.33 | 401.34 | REGRESSION |
| bin-1e5-m1000-p5-skewed | logis_fe | 0.864 |  0.6 | 0.399 | 0.312 | 0.462 | 0.521 |  348.7 | 415.21 | REGRESSION |
| bin-1e5-m1000-p5 | confint.logis_re[option=alpha] | 0.071 | 0.0699 | 0.0238 | 0.0194 | 0.336 | 0.278 | 394.71 | 467.41 | REGRESSION |
| bin-1e5-m1000-p5 | confint.logis_re[option=SM,stdz=indirect+direct] | 10.3 | 10.2 | 9.89 | 9.88 | 0.959 | 0.969 | 394.32 | 467.14 | REGRESSION |
| bin-1e5-m1000-p5 | confint[option=gamma] | 19.6 | 19.6 | 18.7 | 18.7 | 0.954 | 0.954 | 376.56 | 407.94 | ok |
| bin-1e5-m1000-p5 | logis_fe | 0.712 | 0.69 | 0.421 | 0.303 | 0.591 | 0.439 | 349.28 | 404.53 | REGRESSION |
| bin-1e5-m1000-p5 | logis_fe[method=BAN] | 0.73 | 0.647 | 0.583 | 0.472 | 0.799 | 0.729 | 348.56 | 404.39 | REGRESSION |
| bin-1e5-m1000-p5 | logis_firth | 0.599 | 0.486 | 0.421 | 0.304 | 0.703 | 0.626 | 348.81 | 399.96 | REGRESSION |
| bin-1e5-m1000-p5 | logis_re | 52.8 | 52.7 | 61.9 | 61.5 | 1.17 | 1.17 | 412.71 |  463.6 | REGRESSION |
| bin-1e5-m1000-p5 | SM_output.logis_re[stdz=indirect+direct] | 3.64 | 3.47 |  3.3 | 3.27 | 0.905 | 0.943 | 393.59 | 472.09 | REGRESSION |
| bin-1e5-m1000-p5 | SM_output[stdz=direct] | 3.29 | 3.29 | 3.31 |  3.3 | 1.01 |    1 |  351.2 | 398.68 | ok |
| bin-1e5-m1000-p5 | SM_output[stdz=indirect] | 0.015 | 0.0128 | 0.0401 | 0.0321 | 2.67 | 2.51 | 351.95 | 399.07 | ok |
| bin-1e5-m1000-p5 | summary.logis_re | 0.00183 | 0.00147 | 0.0166 | 0.0117 | 9.06 | 7.97 | 393.69 | 472.39 | REGRESSION |
| bin-1e5-m1000-p5 | summary[test=wald] | 0.000565 | 0.000485 | 0.0216 | 0.0156 | 38.1 | 32.2 | 351.12 | 400.45 | ok |
| bin-1e5-m1000-p5 | test.logis_re | 0.0998 | 0.0963 | 0.0236 | 0.0197 | 0.236 | 0.205 | 393.51 | 471.99 | REGRESSION |
| bin-1e5-m1000-p5 | test[test=exact.poisbinom] | 1.33 | 0.969 | 0.791 | 0.762 | 0.595 | 0.786 |  428.6 | 407.33 | ok |
| bin-1e5-m1000-p5 | test[test=score,score_modified=FALSE] |  3.1 |  3.1 | 3.04 | 3.02 | 0.982 | 0.977 | 351.22 |  402.6 | REGRESSION |
| bin-1e5-m1000-p5 | test[test=score] | 0.025 | 0.0176 | 0.0347 | 0.0278 | 1.39 | 1.58 | 351.87 | 402.73 | REGRESSION |
| bin-1e5-m1000-p5 | test[test=wald] | 0.00407 | 0.00317 | 0.0233 | 0.0174 | 5.72 | 5.49 | 351.71 | 398.83 | ok |
| bin-1e5-m10000-p5 | logis_fe | 0.904 | 0.862 | 0.608 | 0.586 | 0.672 | 0.679 | 344.69 | 395.65 | REGRESSION |
| bin-1e6-m1000-p5 | logis_fe | 5.22 | 4.88 | 3.52 | 3.33 | 0.675 | 0.682 | 701.35 |  671.5 | ok |
| bin-1e6-m1000-p5 | logis_fe[method=BAN] | 6.24 | 6.13 | 5.11 | 4.77 | 0.82 | 0.778 | 753.82 | 681.14 | ok |
| bin-1e6-m1000-p5 | logis_firth | 5.19 | 4.82 | 3.46 | 3.22 | 0.668 | 0.668 | 754.19 | 673.14 | ok |
| bin-1e6-m1000-p50 | logis_fe |   44 | 41.8 | 35.3 | 34.1 | 0.802 | 0.816 | 2101.6 | 2280.3 | ok |
| bin-1e6-m10000-p5 | logis_fe | 6.67 | 5.83 |  4.3 |    4 | 0.644 | 0.686 | 697.13 | 677.71 | ok |
| lin-1e4-m100-p5 | confint.linear_cre[option=alpha] | 0.00762 | 0.00711 | 0.00441 | 0.00395 | 0.579 | 0.555 | 314.04 | 383.82 | REGRESSION |
| lin-1e4-m100-p5 | confint.linear_cre[option=SM,stdz=indirect+direct] | 0.0498 | 0.0439 | 0.0181 | 0.0117 | 0.363 | 0.268 | 331.25 | 396.19 | REGRESSION |
| lin-1e4-m100-p5 | confint.linear_re[option=alpha] | 0.00648 | 0.00616 | 0.00329 | 0.00286 | 0.508 | 0.464 | 311.75 | 380.76 | REGRESSION |
| lin-1e4-m100-p5 | confint.linear_re[option=SM,stdz=indirect+direct] | 0.0503 | 0.0429 | 0.0171 | 0.0107 | 0.34 | 0.249 | 324.12 | 391.53 | REGRESSION |
| lin-1e4-m100-p5 | linear_cre | 0.105 | 0.0979 | 0.0992 | 0.0973 | 0.941 | 0.993 | 324.76 |  392.3 | REGRESSION |
| lin-1e4-m100-p5 | linear_fe | 0.444 | 0.406 | 0.00779 | 0.0062 | 0.0175 | 0.0153 | 351.68 | 364.82 | ok |
| lin-1e4-m100-p5 | linear_re | 0.0864 | 0.081 | 0.0848 | 0.0806 | 0.981 | 0.994 | 319.12 | 386.13 | REGRESSION |
| lin-1e4-m100-p5 | SM_output.linear_cre[stdz=indirect+direct] | 0.0231 | 0.0197 | 0.00826 | 0.00647 | 0.358 | 0.328 | 314.48 | 381.44 | REGRESSION |
| lin-1e4-m100-p5 | SM_output.linear_re[stdz=indirect+direct] | 0.0258 | 0.02 | 0.00804 | 0.00641 | 0.312 | 0.32 | 311.84 | 380.43 | REGRESSION |
| lin-1e4-m100-p5 | summary.linear_cre | 0.00193 | 0.00158 | 0.0037 | 0.00329 | 1.92 | 2.09 |  314.7 | 383.57 | REGRESSION |
| lin-1e4-m100-p5 | summary.linear_re | 0.00183 | 0.00148 | 0.0037 | 0.00326 | 2.03 | 2.21 | 312.12 | 380.46 | REGRESSION |
| lin-1e4-m100-p5 | test.linear_cre | 0.00884 | 0.00761 | 0.00462 | 0.00414 | 0.523 | 0.544 |  313.7 |  381.7 | REGRESSION |
| lin-1e4-m100-p5 | test.linear_re | 0.00643 | 0.00624 | 0.00346 | 0.00304 | 0.538 | 0.487 | 312.26 | 380.35 | REGRESSION |
| lin-1e5-m100-p5 | linear_fe |  |  |  |  |  |  |  |  | ok |
| lin-1e5-m1000-p5 | confint | 0.0212 | 0.0169 | 0.0312 | 0.0241 | 1.47 | 1.42 | 841.06 | 405.56 | ok |
| lin-1e5-m1000-p5 | confint.linear_fe[option=gamma] | 0.00352 | 0.00265 | 0.0167 | 0.0109 | 4.74 |  4.1 | 842.27 | 404.77 | ok |
| lin-1e5-m1000-p5 | confint.linear_re[option=alpha] | 0.0629 | 0.0617 | 0.0136 | 0.0105 | 0.216 | 0.171 | 371.19 | 433.22 | REGRESSION |
| lin-1e5-m1000-p5 | confint.linear_re[option=SM,stdz=indirect+direct] | 1.44 | 1.41 |  1.1 | 1.05 | 0.764 | 0.748 | 398.66 | 470.99 | REGRESSION |
| lin-1e5-m1000-p5 | linear_fe | 3.25 | 3.08 | 0.0768 | 0.064 | 0.0236 | 0.0208 |  801.3 | 396.59 | ok |
| lin-1e5-m1000-p5 | linear_re | 1.04 | 0.98 | 0.998 | 0.973 | 0.957 | 0.993 | 392.82 | 432.14 | ok |
| lin-1e5-m1000-p5 | plot.linear_fe |  |  |  |  |  |  |  |  | ok |
| lin-1e5-m1000-p5 | SM_output.linear_re[stdz=indirect+direct] | 0.584 | 0.532 | 0.383 | 0.364 | 0.656 | 0.684 | 395.12 |  467.1 | REGRESSION |
| lin-1e5-m1000-p5 | SM_output[stdz=indirect+direct] | 0.419 | 0.37 | 0.383 | 0.365 | 0.916 | 0.986 | 843.01 | 420.22 | ok |
| lin-1e5-m1000-p5 | summary.linear_fe | 0.000484 | 0.000442 | 0.0161 | 0.0108 | 33.3 | 24.4 | 842.27 | 397.41 | ok |
| lin-1e5-m1000-p5 | summary.linear_re | 0.00182 | 0.00147 | 0.014 | 0.0105 | 7.69 | 7.13 | 372.42 |  432.8 | REGRESSION |
| lin-1e5-m1000-p5 | test | 0.00424 | 0.00344 | 0.0166 | 0.0111 | 3.92 | 3.23 | 843.55 | 402.09 | ok |
| lin-1e5-m1000-p5 | test.linear_re | 0.0641 | 0.0625 | 0.0144 | 0.0108 | 0.224 | 0.173 | 372.88 | 432.44 | REGRESSION |
| lin-1e5-m10000-p5 | linear_fe | 9.14 | 8.69 | 0.168 | 0.15 | 0.0184 | 0.0172 | 491.55 | 390.99 | ok |
| lin-1e6-m100000-p5 | linear_fe | 95.9 | 93.9 | 1.85 |  1.8 | 0.0192 | 0.0191 | 1290.5 | 607.94 | ok |
