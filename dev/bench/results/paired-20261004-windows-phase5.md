# Paired benchmark: reference and working tree, 2 round(s)

- Tasks: 7; regressions: 4.
- Rule (DEC-038): a regression in time needs both the median and the fastest run more than 10% slower than the reference's, and the median at least 0.05 s slower, in every round; in memory, a peak more than 10% and 50 MB higher in every round.

| Scenario | Task | Round | Reference median s | New median s | Ratio | Reference fastest s | New fastest s | Ratio | Reference peak MB | New peak MB | Ratio | Verdict |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| bin-1e4-m100-p5 | logis_cre | 1 | 9.99 | 9.56 | 0.957 | 9.97 | 8.24 | 0.826 |  333 |  399 |  1.2 |  |
| bin-1e4-m100-p5 | logis_cre | 2 | 9.06 | 8.42 | 0.929 | 8.63 | 8.32 | 0.964 |  334 |  400 |  1.2 | REGRESSION (memory) |
| bin-1e4-m100-p5 | logis_re | 1 | 4.71 | 4.47 | 0.949 | 4.34 | 4.38 | 1.01 |  331 |  399 | 1.21 |  |
| bin-1e4-m100-p5 | logis_re | 2 | 4.32 | 4.31 | 0.997 | 4.22 | 4.26 | 1.01 |  331 |  399 |  1.2 | REGRESSION (memory) |
| bin-1e5-m1000-p5 | logis_re | 1 | 61.7 | 61.4 | 0.995 | 61.4 | 61.3 | 0.998 |  412 |  461 | 1.12 |  |
| bin-1e5-m1000-p5 | logis_re | 2 | 61.3 | 61.7 | 1.01 | 61.1 | 61.6 | 1.01 |  412 |  460 | 1.12 | ok |
| lin-1e5-m1000-p5 | confint.linear_re[option=SM,stdz=indirect+direct] | 1 | 1.63 | 1.19 | 0.731 | 1.44 | 1.09 | 0.757 |  399 |  470 | 1.18 |  |
| lin-1e5-m1000-p5 | confint.linear_re[option=SM,stdz=indirect+direct] | 2 | 1.58 |  1.1 | 0.697 | 1.48 | 1.07 | 0.724 |  400 |  470 | 1.17 | REGRESSION (memory) |
| lin-1e5-m1000-p5 | plot.linear_fe | 1 | 0.082 | 0.108 | 1.32 | 0.074 | 0.0994 | 1.34 |  705 |  408 | 0.578 |  |
| lin-1e5-m1000-p5 | plot.linear_fe | 2 | 0.0793 | 0.108 | 1.36 | 0.0715 | 0.101 | 1.41 |  822 |  411 |  0.5 | ok |
| lin-1e5-m1000-p5 | SM_output.linear_re[stdz=indirect+direct] | 1 | 0.812 | 0.399 | 0.492 | 0.621 | 0.37 | 0.596 |  398 |  467 | 1.17 |  |
| lin-1e5-m1000-p5 | SM_output.linear_re[stdz=indirect+direct] | 2 | 0.557 | 0.397 | 0.713 | 0.536 | 0.369 | 0.689 |  396 |  467 | 1.18 | REGRESSION (memory) |
| lin-1e5-m1000-p5 | summary.linear_fe | 1 | 0.000441 | 0.0162 | 36.6 | 0.000415 | 0.0103 | 24.7 |  843 |  391 | 0.464 |  |
| lin-1e5-m1000-p5 | summary.linear_fe | 2 | 0.000451 | 0.0161 | 35.7 | 0.000423 | 0.0107 | 25.3 |  843 |  392 | 0.465 | ok |
