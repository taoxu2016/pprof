# Paired benchmark: reference and working tree, 2 round(s)

- Tasks: 6; regressions: 0.
- Rule (DEC-038): a regression in time needs both the median and the fastest run more than 10% slower than the reference's, and the median at least 0.05 s slower, in every round; in memory, a peak more than 10% and 50 MB higher in every round.

| Scenario | Task | Round | Reference median s | New median s | Ratio | Reference fastest s | New fastest s | Ratio | Reference peak MB | New peak MB | Ratio | Verdict |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| bin-1e4-m100-p5 | confint[option=gamma] | 1 | 1.92 | 1.87 | 0.974 | 1.91 | 1.87 | 0.979 |  332 |  332 |    1 |  |
| bin-1e4-m100-p5 | confint[option=gamma] | 2 | 1.93 | 1.88 | 0.977 | 1.91 | 1.86 | 0.978 |  332 |  332 |    1 | ok |
| bin-1e4-m100-p5 | logis_cre | 1 | 8.39 |  8.3 | 0.989 | 8.22 | 8.28 | 1.01 |  333 |  333 | 0.999 |  |
| bin-1e4-m100-p5 | logis_cre | 2 | 8.29 | 8.34 | 1.01 | 8.22 | 8.19 | 0.996 |  333 |  333 |    1 | ok |
| bin-1e4-m100-p5 | logis_re | 1 | 3.93 | 3.89 | 0.988 | 3.73 | 3.71 | 0.995 |  331 |  331 |    1 |  |
| bin-1e4-m100-p5 | logis_re | 2 | 3.87 | 3.85 | 0.995 | 3.65 | 3.72 | 1.02 |  331 |  331 |    1 | ok |
| bin-1e5-m1000-p5 | confint[option=gamma] | 1 | 23.1 | 22.4 | 0.968 | 22.5 | 21.8 | 0.97 |  376 |  356 | 0.945 |  |
| bin-1e5-m1000-p5 | confint[option=gamma] | 2 | 22.1 | 22.1 | 0.999 | 21.8 | 21.9 |    1 |  376 |  357 | 0.947 | ok |
| bin-1e5-m1000-p5 | SM_output[stdz=direct] | 1 | 3.25 | 3.32 | 1.02 | 3.24 | 3.29 | 1.01 |  352 |  333 | 0.946 |  |
| bin-1e5-m1000-p5 | SM_output[stdz=direct] | 2 | 3.24 | 3.28 | 1.01 | 3.24 | 3.28 | 1.01 |  351 |  333 | 0.948 | ok |
| bin-1e5-m1000-p5 | test[test=score,score_modified=FALSE] | 1 |    3 | 3.02 | 1.01 | 2.98 |    3 | 1.01 |  352 |  336 | 0.955 |  |
| bin-1e5-m1000-p5 | test[test=score,score_modified=FALSE] | 2 | 2.99 | 3.03 | 1.01 | 2.98 | 3.02 | 1.01 |  352 |  336 | 0.954 | ok |
