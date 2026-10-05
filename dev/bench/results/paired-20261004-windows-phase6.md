# Paired benchmark: reference and working tree, 2 round(s)

- Tasks: 6; regressions: 4.
- Rule (DEC-038): a regression in time needs both the median and the fastest run more than 10% slower than the reference's, and the median at least 0.05 s slower, in every round; in memory, a peak more than 10% and 50 MB higher in every round.

| Scenario | Task | Round | Reference median s | New median s | Ratio | Reference fastest s | New fastest s | Ratio | Reference peak MB | New peak MB | Ratio | Verdict |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| bin-1e4-m100-p5 | plot.logis_fe | 1 | 0.0644 | 0.0678 | 1.05 | 0.061 | 0.0627 | 1.03 |  315 |  373 | 1.18 |  |
| bin-1e4-m100-p5 | plot.logis_fe | 2 | 0.0649 | 0.0667 | 1.03 | 0.0607 | 0.0626 | 1.03 |  314 |  373 | 1.19 | REGRESSION (memory) |
| bin-1e5-m1000-p5 | bar_plot.logis_fe<test> | 1 | 0.0876 | 0.0428 | 0.489 | 0.0666 | 0.0399 |  0.6 |  346 |  400 | 1.16 |  |
| bin-1e5-m1000-p5 | bar_plot.logis_fe<test> | 2 | 0.0483 | 0.0413 | 0.855 | 0.0456 | 0.0391 | 0.859 |  346 |  401 | 1.16 | REGRESSION (memory) |
| bin-1e5-m1000-p5 | caterpillar_plot.logis_fe<confint> | 1 | 0.0404 | 0.0373 | 0.923 | 0.0339 | 0.0332 | 0.979 |  374 |  398 | 1.06 |  |
| bin-1e5-m1000-p5 | caterpillar_plot.logis_fe<confint> | 2 | 0.0378 | 0.0374 | 0.989 | 0.0332 | 0.0327 | 0.984 |  371 |  399 | 1.08 | ok |
| bin-1e5-m1000-p5 | logis_re | 1 | 62.4 | 62.3 | 0.997 | 62.4 | 61.8 | 0.99 |  388 |  460 | 1.18 |  |
| bin-1e5-m1000-p5 | logis_re | 2 | 64.1 | 62.9 | 0.982 | 62.9 | 62.9 |    1 |  390 |  461 | 1.18 | REGRESSION (memory) |
| bin-1e5-m1000-p5 | plot.logis_fe | 1 | 0.115 | 0.147 | 1.28 | 0.106 | 0.124 | 1.17 |  346 |  404 | 1.17 |  |
| bin-1e5-m1000-p5 | plot.logis_fe | 2 | 0.111 | 0.157 | 1.41 | 0.103 | 0.121 | 1.18 |  347 |  405 | 1.17 | REGRESSION (memory) |
| lin-1e5-m1000-p5 | plot.linear_fe | 1 | 0.0946 | 0.0994 | 1.05 | 0.0738 | 0.0902 | 1.22 |  842 |  408 | 0.485 |  |
| lin-1e5-m1000-p5 | plot.linear_fe | 2 | 0.0847 | 0.098 | 1.16 | 0.0702 | 0.0932 | 1.33 |  844 |  407 | 0.483 | ok |
