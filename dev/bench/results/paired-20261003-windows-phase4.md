# Paired benchmark: reference and working tree, 2 round(s)

- Tasks: 9; regressions: 7.
- Rule (DEC-038): a regression in time needs both the median and the fastest run more than 10% slower than the reference's, and the median at least 0.05 s slower, in every round; in memory, a peak more than 10% and 50 MB higher in every round.

| Scenario | Task | Round | Reference median s | New median s | Ratio | Reference fastest s | New fastest s | Ratio | Reference peak MB | New peak MB | Ratio | Verdict |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| bin-1e4-m100-p5 | logis_cre | 1 | 8.63 | 8.83 | 1.02 | 8.56 | 8.72 | 1.02 |  333 |  400 |  1.2 |  |
| bin-1e4-m100-p5 | logis_cre | 2 | 8.71 | 8.65 | 0.993 | 8.55 | 8.49 | 0.993 |  333 |  400 |  1.2 | REGRESSION (memory) |
| bin-1e4-m100-p5 | logis_firth | 1 | 0.0478 | 0.0632 | 1.32 | 0.0412 | 0.0453 |  1.1 |  304 |  369 | 1.21 |  |
| bin-1e4-m100-p5 | logis_firth | 2 | 0.0471 | 0.0331 | 0.704 | 0.0396 | 0.0303 | 0.766 |  308 |  368 |  1.2 | REGRESSION (memory) |
| bin-1e4-m100-p5 | logis_re | 1 | 3.84 | 3.94 | 1.03 | 3.73 | 3.71 | 0.994 |  331 |  400 | 1.21 |  |
| bin-1e4-m100-p5 | logis_re | 2 | 3.83 | 3.73 | 0.972 | 3.73 | 3.69 | 0.989 |  331 |  400 | 1.21 | REGRESSION (memory) |
| bin-1e5-m1000-p5 | logis_firth | 1 | 0.704 | 0.391 | 0.554 | 0.521 | 0.326 | 0.626 |  348 |  401 | 1.15 |  |
| bin-1e5-m1000-p5 | logis_firth | 2 | 0.66 | 0.339 | 0.513 | 0.515 | 0.305 | 0.592 |  349 |  402 | 1.15 | REGRESSION (memory) |
| bin-1e6-m1000-p5 | logis_firth | 1 |  5.3 |  3.1 | 0.585 | 4.91 | 2.81 | 0.573 |  750 |  673 | 0.897 |  |
| bin-1e6-m1000-p5 | logis_firth | 2 | 5.18 | 3.11 | 0.601 | 5.09 | 2.89 | 0.569 |  759 |  673 | 0.886 | ok |
| bin-1e6-m1000-p50 | logis_fe | 1 | 42.5 | 30.8 | 0.725 |   40 | 30.6 | 0.765 | 2070 | 2720 | 1.31 |  |
| bin-1e6-m1000-p50 | logis_fe | 2 | 39.1 | 32.6 | 0.835 | 38.9 | 30.2 | 0.776 | 2426 | 2717 | 1.12 | REGRESSION (memory) |
| lin-1e4-m100-p5 | linear_cre | 1 | 0.115 | 0.105 | 0.914 | 0.102 |  0.1 | 0.98 |  325 |  393 | 1.21 |  |
| lin-1e4-m100-p5 | linear_cre | 2 | 0.106 | 0.105 | 0.99 | 0.101 | 0.0989 | 0.975 |  326 |  392 |  1.2 | REGRESSION (memory) |
| lin-1e4-m100-p5 | linear_re | 1 | 0.097 | 0.0927 | 0.956 | 0.0903 | 0.0881 | 0.976 |  318 |  386 | 1.21 |  |
| lin-1e4-m100-p5 | linear_re | 2 | 0.0892 | 0.0902 | 1.01 | 0.0866 | 0.081 | 0.935 |  317 |  386 | 1.22 | REGRESSION (memory) |
| lin-1e5-m1000-p5 | test | 1 | 0.00438 | 0.00435 | 0.994 | 0.00355 | 0.00367 | 1.03 |  843 |  402 | 0.477 |  |
| lin-1e5-m1000-p5 | test | 2 | 0.00453 | 0.00433 | 0.956 | 0.00356 | 0.00359 | 1.01 |  841 |  405 | 0.482 | ok |
