# Differential report: working tree versus the pprof 1.0.3 reference

Generated 2026-10-04 23:25:20 UTC by `validation/run-differential.R` on R version 4.4.0 (2024-04-24 ucrt), Windows 11 x64 (build 22621).
Working tree at commit fc70833; 30 binary datasets (10 with RE and CRE fits), 15 linear datasets, 3 binary (RE and CRE fits only) and 3 linear datasets with character IDs, and 2 binary (RE and CRE fits only) and 2 linear datasets without provider effects; seed 20261003.

## Summary

- Cases: 3510; matching: 3510; identical: 2510; mismatching: 0.
- Reference errors reproduced: 70.
- Time: reference 235 s, working tree 167 s.

## Datasets

- `diff01`: n 517, m 15 (2 below 10), p 5, event rate 0.33, with RE and CRE fits
- `diff02`: n 857, m 25 (2 below 10), p 3, event rate 0.70, with RE and CRE fits
- `diff03`: n 468, m 15 (2 below 10), p 3, event rate 0.67, with RE and CRE fits
- `diff04`: n 534, m 15 (2 below 10), p 4, event rate 0.55, with RE and CRE fits
- `diff05`: n 418, m 15 (2 below 10), p 5, event rate 0.71, with RE and CRE fits
- `diff06`: n 885, m 25 (2 below 10), p 4, event rate 0.66, with RE and CRE fits
- `diff07`: n 458, m 15 (2 below 10), p 4, event rate 0.16, with RE and CRE fits
- `diff08`: n 550, m 15 (2 below 10), p 5, event rate 0.25, with RE and CRE fits
- `diff09`: n 814, m 25 (2 below 10), p 5, event rate 0.31, with RE and CRE fits
- `diff10`: n 1523, m 40 (2 below 10), p 3, event rate 0.26, with RE and CRE fits
- `diff11`: n 865, m 25 (2 below 10), p 5, event rate 0.33
- `diff12`: n 1449, m 40 (2 below 10), p 5, event rate 0.67
- `diff13`: n 441, m 15 (2 below 10), p 5, event rate 0.67
- `diff14`: n 991, m 25 (2 below 10), p 3, event rate 0.07
- `diff15`: n 526, m 15 (2 below 10), p 4, event rate 0.33
- `diff16`: n 846, m 25 (2 below 10), p 5, event rate 0.27
- `diff17`: n 769, m 25 (2 below 10), p 3, event rate 0.06
- `diff18`: n 568, m 15 (2 below 10), p 4, event rate 0.58
- `diff19`: n 873, m 25 (2 below 10), p 5, event rate 0.62
- `diff20`: n 1484, m 40 (2 below 10), p 3, event rate 0.70
- `diff21`: n 600, m 15 (2 below 10), p 5, event rate 0.13
- `diff22`: n 912, m 25 (2 below 10), p 5, event rate 0.69
- `diff23`: n 1428, m 40 (2 below 10), p 3, event rate 0.08
- `diff24`: n 828, m 25 (2 below 10), p 4, event rate 0.12
- `diff25`: n 1338, m 40 (2 below 10), p 3, event rate 0.28
- `diff26`: n 847, m 25 (2 below 10), p 4, event rate 0.09
- `diff27`: n 1429, m 40 (2 below 10), p 4, event rate 0.70
- `diff28`: n 1392, m 40 (2 below 10), p 5, event rate 0.36
- `diff29`: n 722, m 25 (2 below 10), p 3, event rate 0.27
- `diff30`: n 1238, m 40 (2 below 10), p 5, event rate 0.07
- `lin01`: linear, n 367, m 15 (2 below 5), p 3, 5 missing outcomes
- `lin02`: linear, n 510, m 15 (2 below 5), p 4, 0 missing outcomes
- `lin03`: linear, n 1464, m 40 (2 below 5), p 4, 5 missing outcomes
- `lin04`: linear, n 1289, m 40 (2 below 5), p 5, 0 missing outcomes
- `lin05`: linear, n 1314, m 40 (2 below 5), p 5, 5 missing outcomes
- `lin06`: linear, n 1340, m 40 (2 below 5), p 4, 0 missing outcomes
- `lin07`: linear, n 734, m 25 (2 below 5), p 4, 5 missing outcomes
- `lin08`: linear, n 854, m 25 (2 below 5), p 5, 5 missing outcomes
- `lin09`: linear, n 1181, m 40 (2 below 5), p 5, 0 missing outcomes
- `lin10`: linear, n 832, m 25 (2 below 5), p 4, 5 missing outcomes
- `lin11`: linear, n 797, m 25 (2 below 5), p 3, 0 missing outcomes
- `lin12`: linear, n 894, m 25 (2 below 5), p 4, 0 missing outcomes
- `lin13`: linear, n 841, m 25 (2 below 5), p 3, 5 missing outcomes
- `lin14`: linear, n 872, m 25 (2 below 5), p 5, 5 missing outcomes
- `lin15`: linear, n 1219, m 40 (2 below 5), p 5, 0 missing outcomes
- `chr-diff01`: n 918, m 25 (2 below 10), p 4, event rate 0.62, character IDs, RE and CRE fits only
- `chr-diff02`: n 1294, m 40 (2 below 10), p 5, event rate 0.35, character IDs, RE and CRE fits only
- `chr-diff03`: n 1565, m 40 (2 below 10), p 3, event rate 0.07, character IDs, RE and CRE fits only
- `chr-lin01`: linear, n 559, m 15 (2 below 5), p 4, 5 missing outcomes, character IDs
- `chr-lin02`: linear, n 371, m 15 (2 below 5), p 5, 5 missing outcomes, character IDs
- `chr-lin03`: linear, n 775, m 25 (2 below 5), p 3, 0 missing outcomes, character IDs
- `null-diff01`: n 859, m 25 (2 below 10), p 3, event rate 0.29, no provider effects (the lme4 RE fit is singular), RE and CRE fits only
- `null-diff02`: n 879, m 25 (2 below 10), p 3, event rate 0.29, no provider effects (the lme4 RE fit is singular), RE and CRE fits only
- `null-lin01`: linear, n 499, m 15 (2 below 5), p 3, 5 missing outcomes, no provider effects (the lme4 RE fit is not singular)
- `null-lin02`: linear, n 1238, m 40 (2 below 5), p 5, 0 missing outcomes, no provider effects (the lme4 RE fit is singular)

## Cases

| Case | Function | Tier | Reference outcome | Status | Detail |
|---|---|---|---|---|---|
| `diff01-fit` | logis_fe | iterative | value | match | within tolerance: AUC |
| `diff01-fit-ban` | logis_fe | iterative | value | match | within tolerance: AUC |
| `diff01-fit-all` | logis_fe | iterative | value | match | within tolerance: AUC |
| `diff01-exact-two.sided` | test | iterative | value | match | identical |
| `diff01-score-two.sided` | test | iterative | value | match | identical |
| `diff01-exact-greater` | test | iterative | value | match | identical |
| `diff01-score-greater` | test | iterative | value | match | identical |
| `diff01-exact-less` | test | iterative | value | match | identical |
| `diff01-score-less` | test | iterative | value | match | identical |
| `diff01-bootstrap` | test | iterative | value | match | identical |
| `diff01-score-standard` | test | iterative | value | match | identical |
| `diff01-wald` | test | iterative | value | match | identical |
| `diff01-exact-parm` | test | iterative | value | match | identical |
| `diff01-sm` | SM_output | iterative | value | match | identical |
| `diff01-sm-null0` | SM_output | iterative | value | match | identical |
| `diff01-gamma-exact` | confint | root | value | match | identical |
| `diff01-sm-exact` | confint | root | value | match | identical |
| `diff01-gamma-score` | confint | root | value | match | identical |
| `diff01-sm-score` | confint | root | value | match | identical |
| `diff01-gamma-wald` | confint | iterative | value | match | identical |
| `diff01-sm-wald` | confint | iterative | value | match | identical |
| `diff01-sm-score-greater` | confint | root | value | match | identical |
| `diff01-sm-exact-less` | confint | root | value | match | identical |
| `diff01-summary-wald` | summary | iterative | value | match | identical |
| `diff01-summary-lr` | summary | iterative | value | match | identical |
| `diff01-summary-score` | summary | iterative | value | match | identical |
| `diff01-plot` | plot | iterative | value | match | identical |
| `diff01-plot-null` | plot | iterative | value | match | identical |
| `diff01-caterpillar` | caterpillar_plot | iterative | value | match | identical |
| `diff01-caterpillar-flags` | caterpillar_plot | iterative | value | match | identical |
| `diff01-caterpillar-one-sided` | caterpillar_plot | root | value | match | identical |
| `diff01-bar` | bar_plot | iterative | value | match | identical |
| `diff01-bar-3` | bar_plot | iterative | value | match | identical |
| `diff01-firth` | logis_firth | iterative | value | match | identical |
| `diff01-firth-exact` | test | iterative | value | match | identical |
| `diff01-firth-sm` | SM_output | iterative | value | match | identical |
| `diff01-firth-gamma-score` | confint | root | value | match | identical |
| `diff02-fit` | logis_fe | iterative | value | match | identical |
| `diff02-fit-ban` | logis_fe | iterative | value | match | identical |
| `diff02-fit-all` | logis_fe | iterative | value | match | identical |
| `diff02-exact-two.sided` | test | iterative | value | match | identical |
| `diff02-score-two.sided` | test | iterative | value | match | identical |
| `diff02-exact-greater` | test | iterative | value | match | identical |
| `diff02-score-greater` | test | iterative | value | match | identical |
| `diff02-exact-less` | test | iterative | value | match | identical |
| `diff02-score-less` | test | iterative | value | match | identical |
| `diff02-bootstrap` | test | iterative | value | match | identical |
| `diff02-score-standard` | test | iterative | value | match | identical |
| `diff02-wald` | test | iterative | value | match | identical |
| `diff02-exact-parm` | test | iterative | value | match | identical |
| `diff02-sm` | SM_output | iterative | value | match | identical |
| `diff02-sm-null0` | SM_output | iterative | value | match | identical |
| `diff02-gamma-exact` | confint | root | value | match | identical |
| `diff02-sm-exact` | confint | root | value | match | identical |
| `diff02-gamma-score` | confint | root | value | match | identical |
| `diff02-sm-score` | confint | root | value | match | identical |
| `diff02-gamma-wald` | confint | iterative | value | match | identical |
| `diff02-sm-wald` | confint | iterative | value | match | identical |
| `diff02-sm-score-greater` | confint | root | value | match | identical |
| `diff02-sm-exact-less` | confint | root | value | match | identical |
| `diff02-summary-wald` | summary | iterative | value | match | identical |
| `diff02-summary-lr` | summary | iterative | value | match | identical |
| `diff02-summary-score` | summary | iterative | value | match | identical |
| `diff02-plot` | plot | iterative | value | match | identical |
| `diff02-plot-null` | plot | iterative | value | match | identical |
| `diff02-caterpillar` | caterpillar_plot | iterative | value | match | identical |
| `diff02-caterpillar-flags` | caterpillar_plot | iterative | value | match | identical |
| `diff02-caterpillar-one-sided` | caterpillar_plot | root | value | match | identical |
| `diff02-bar` | bar_plot | iterative | value | match | identical |
| `diff02-bar-3` | bar_plot | iterative | value | match | identical |
| `diff02-firth` | logis_firth | iterative | value | match | identical |
| `diff02-firth-exact` | test | iterative | value | match | identical |
| `diff02-firth-sm` | SM_output | iterative | value | match | identical |
| `diff02-firth-gamma-score` | confint | root | value | match | identical |
| `diff03-fit` | logis_fe | iterative | value | match | identical |
| `diff03-fit-ban` | logis_fe | iterative | value | match | identical |
| `diff03-fit-all` | logis_fe | iterative | value | match | identical |
| `diff03-exact-two.sided` | test | iterative | value | match | identical |
| `diff03-score-two.sided` | test | iterative | value | match | identical |
| `diff03-exact-greater` | test | iterative | value | match | identical |
| `diff03-score-greater` | test | iterative | value | match | identical |
| `diff03-exact-less` | test | iterative | value | match | identical |
| `diff03-score-less` | test | iterative | value | match | identical |
| `diff03-bootstrap` | test | iterative | value | match | identical |
| `diff03-score-standard` | test | iterative | value | match | identical |
| `diff03-wald` | test | iterative | value | match | identical |
| `diff03-exact-parm` | test | iterative | value | match | identical |
| `diff03-sm` | SM_output | iterative | value | match | identical |
| `diff03-sm-null0` | SM_output | iterative | value | match | identical |
| `diff03-gamma-exact` | confint | root | value | match | identical |
| `diff03-sm-exact` | confint | root | value | match | identical |
| `diff03-gamma-score` | confint | root | value | match | identical |
| `diff03-sm-score` | confint | root | value | match | identical |
| `diff03-gamma-wald` | confint | iterative | value | match | identical |
| `diff03-sm-wald` | confint | iterative | value | match | identical |
| `diff03-sm-score-greater` | confint | root | value | match | identical |
| `diff03-sm-exact-less` | confint | root | value | match | identical |
| `diff03-summary-wald` | summary | iterative | value | match | identical |
| `diff03-summary-lr` | summary | iterative | value | match | identical |
| `diff03-summary-score` | summary | iterative | value | match | identical |
| `diff03-plot` | plot | iterative | value | match | identical |
| `diff03-plot-null` | plot | iterative | value | match | identical |
| `diff03-caterpillar` | caterpillar_plot | iterative | value | match | identical |
| `diff03-caterpillar-flags` | caterpillar_plot | iterative | value | match | identical |
| `diff03-caterpillar-one-sided` | caterpillar_plot | root | value | match | identical |
| `diff03-bar` | bar_plot | iterative | value | match | identical |
| `diff03-bar-3` | bar_plot | iterative | value | match | identical |
| `diff03-firth` | logis_firth | iterative | value | match | identical |
| `diff03-firth-exact` | test | iterative | value | match | identical |
| `diff03-firth-sm` | SM_output | iterative | value | match | identical |
| `diff03-firth-gamma-score` | confint | root | value | match | identical |
| `diff04-fit` | logis_fe | iterative | value | match | identical |
| `diff04-fit-ban` | logis_fe | iterative | value | match | identical |
| `diff04-fit-all` | logis_fe | iterative | value | match | identical |
| `diff04-exact-two.sided` | test | iterative | value | match | identical |
| `diff04-score-two.sided` | test | iterative | value | match | identical |
| `diff04-exact-greater` | test | iterative | value | match | identical |
| `diff04-score-greater` | test | iterative | value | match | identical |
| `diff04-exact-less` | test | iterative | value | match | identical |
| `diff04-score-less` | test | iterative | value | match | identical |
| `diff04-bootstrap` | test | iterative | value | match | identical |
| `diff04-score-standard` | test | iterative | value | match | identical |
| `diff04-wald` | test | iterative | value | match | identical |
| `diff04-exact-parm` | test | iterative | value | match | identical |
| `diff04-sm` | SM_output | iterative | value | match | identical |
| `diff04-sm-null0` | SM_output | iterative | value | match | identical |
| `diff04-gamma-exact` | confint | root | value | match | identical |
| `diff04-sm-exact` | confint | root | value | match | identical |
| `diff04-gamma-score` | confint | root | value | match | identical |
| `diff04-sm-score` | confint | root | value | match | identical |
| `diff04-gamma-wald` | confint | iterative | value | match | identical |
| `diff04-sm-wald` | confint | iterative | value | match | identical |
| `diff04-sm-score-greater` | confint | root | value | match | identical |
| `diff04-sm-exact-less` | confint | root | value | match | identical |
| `diff04-summary-wald` | summary | iterative | value | match | identical |
| `diff04-summary-lr` | summary | iterative | value | match | identical |
| `diff04-summary-score` | summary | iterative | value | match | identical |
| `diff04-plot` | plot | iterative | value | match | identical |
| `diff04-plot-null` | plot | iterative | value | match | identical |
| `diff04-caterpillar` | caterpillar_plot | iterative | value | match | identical |
| `diff04-caterpillar-flags` | caterpillar_plot | iterative | value | match | identical |
| `diff04-caterpillar-one-sided` | caterpillar_plot | root | value | match | identical |
| `diff04-bar` | bar_plot | iterative | value | match | identical |
| `diff04-bar-3` | bar_plot | iterative | value | match | identical |
| `diff04-firth` | logis_firth | iterative | value | match | identical |
| `diff04-firth-exact` | test | iterative | value | match | identical |
| `diff04-firth-sm` | SM_output | iterative | value | match | identical |
| `diff04-firth-gamma-score` | confint | root | value | match | identical |
| `diff05-fit` | logis_fe | iterative | value | match | identical |
| `diff05-fit-ban` | logis_fe | iterative | value | match | identical |
| `diff05-fit-all` | logis_fe | iterative | value | match | identical |
| `diff05-exact-two.sided` | test | iterative | value | match | identical |
| `diff05-score-two.sided` | test | iterative | value | match | identical |
| `diff05-exact-greater` | test | iterative | value | match | identical |
| `diff05-score-greater` | test | iterative | value | match | identical |
| `diff05-exact-less` | test | iterative | value | match | identical |
| `diff05-score-less` | test | iterative | value | match | identical |
| `diff05-bootstrap` | test | iterative | value | match | identical |
| `diff05-score-standard` | test | iterative | value | match | identical |
| `diff05-wald` | test | iterative | value | match | identical |
| `diff05-exact-parm` | test | iterative | value | match | identical |
| `diff05-sm` | SM_output | iterative | value | match | identical |
| `diff05-sm-null0` | SM_output | iterative | value | match | identical |
| `diff05-gamma-exact` | confint | root | value | match | identical |
| `diff05-sm-exact` | confint | root | value | match | identical |
| `diff05-gamma-score` | confint | root | value | match | identical |
| `diff05-sm-score` | confint | root | value | match | identical |
| `diff05-gamma-wald` | confint | iterative | value | match | identical |
| `diff05-sm-wald` | confint | iterative | value | match | identical |
| `diff05-sm-score-greater` | confint | root | value | match | identical |
| `diff05-sm-exact-less` | confint | root | value | match | identical |
| `diff05-summary-wald` | summary | iterative | value | match | identical |
| `diff05-summary-lr` | summary | iterative | value | match | identical |
| `diff05-summary-score` | summary | iterative | value | match | identical |
| `diff05-plot` | plot | iterative | value | match | identical |
| `diff05-plot-null` | plot | iterative | value | match | identical |
| `diff05-caterpillar` | caterpillar_plot | iterative | value | match | identical |
| `diff05-caterpillar-flags` | caterpillar_plot | iterative | value | match | identical |
| `diff05-caterpillar-one-sided` | caterpillar_plot | root | value | match | identical |
| `diff05-bar` | bar_plot | iterative | value | match | identical |
| `diff05-bar-3` | bar_plot | iterative | value | match | identical |
| `diff05-firth` | logis_firth | iterative | value | match | identical |
| `diff05-firth-exact` | test | iterative | value | match | identical |
| `diff05-firth-sm` | SM_output | iterative | value | match | identical |
| `diff05-firth-gamma-score` | confint | root | value | match | identical |
| `diff06-fit` | logis_fe | iterative | value | match | identical |
| `diff06-fit-ban` | logis_fe | iterative | value | match | identical |
| `diff06-fit-all` | logis_fe | iterative | value | match | identical |
| `diff06-exact-two.sided` | test | iterative | value | match | identical |
| `diff06-score-two.sided` | test | iterative | value | match | identical |
| `diff06-exact-greater` | test | iterative | value | match | identical |
| `diff06-score-greater` | test | iterative | value | match | identical |
| `diff06-exact-less` | test | iterative | value | match | identical |
| `diff06-score-less` | test | iterative | value | match | identical |
| `diff06-bootstrap` | test | iterative | value | match | identical |
| `diff06-score-standard` | test | iterative | value | match | identical |
| `diff06-wald` | test | iterative | value | match | identical |
| `diff06-exact-parm` | test | iterative | value | match | identical |
| `diff06-sm` | SM_output | iterative | value | match | identical |
| `diff06-sm-null0` | SM_output | iterative | value | match | identical |
| `diff06-gamma-exact` | confint | root | value | match | identical |
| `diff06-sm-exact` | confint | root | value | match | identical |
| `diff06-gamma-score` | confint | root | value | match | identical |
| `diff06-sm-score` | confint | root | value | match | identical |
| `diff06-gamma-wald` | confint | iterative | value | match | identical |
| `diff06-sm-wald` | confint | iterative | value | match | identical |
| `diff06-sm-score-greater` | confint | root | value | match | identical |
| `diff06-sm-exact-less` | confint | root | value | match | identical |
| `diff06-summary-wald` | summary | iterative | value | match | identical |
| `diff06-summary-lr` | summary | iterative | value | match | identical |
| `diff06-summary-score` | summary | iterative | value | match | identical |
| `diff06-plot` | plot | iterative | value | match | identical |
| `diff06-plot-null` | plot | iterative | value | match | identical |
| `diff06-caterpillar` | caterpillar_plot | iterative | value | match | identical |
| `diff06-caterpillar-flags` | caterpillar_plot | iterative | value | match | identical |
| `diff06-caterpillar-one-sided` | caterpillar_plot | root | value | match | identical |
| `diff06-bar` | bar_plot | iterative | value | match | identical |
| `diff06-bar-3` | bar_plot | iterative | value | match | identical |
| `diff06-firth` | logis_firth | iterative | value | match | identical |
| `diff06-firth-exact` | test | iterative | value | match | identical |
| `diff06-firth-sm` | SM_output | iterative | value | match | identical |
| `diff06-firth-gamma-score` | confint | root | value | match | identical |
| `diff07-fit` | logis_fe | iterative | value | match | identical |
| `diff07-fit-ban` | logis_fe | iterative | value | match | identical |
| `diff07-fit-all` | logis_fe | iterative | value | match | identical |
| `diff07-exact-two.sided` | test | iterative | value | match | identical |
| `diff07-score-two.sided` | test | iterative | value | match | identical |
| `diff07-exact-greater` | test | iterative | value | match | identical |
| `diff07-score-greater` | test | iterative | value | match | identical |
| `diff07-exact-less` | test | iterative | value | match | identical |
| `diff07-score-less` | test | iterative | value | match | identical |
| `diff07-bootstrap` | test | iterative | value | match | identical |
| `diff07-score-standard` | test | iterative | value | match | identical |
| `diff07-wald` | test | iterative | value | match | identical |
| `diff07-exact-parm` | test | iterative | value | match | identical |
| `diff07-sm` | SM_output | iterative | value | match | identical |
| `diff07-sm-null0` | SM_output | iterative | value | match | identical |
| `diff07-gamma-exact` | confint | root | value | match | identical |
| `diff07-sm-exact` | confint | root | value | match | identical |
| `diff07-gamma-score` | confint | root | value | match | identical |
| `diff07-sm-score` | confint | root | value | match | identical |
| `diff07-gamma-wald` | confint | iterative | value | match | identical |
| `diff07-sm-wald` | confint | iterative | value | match | identical |
| `diff07-sm-score-greater` | confint | root | value | match | identical |
| `diff07-sm-exact-less` | confint | root | value | match | identical |
| `diff07-summary-wald` | summary | iterative | value | match | identical |
| `diff07-summary-lr` | summary | iterative | value | match | identical |
| `diff07-summary-score` | summary | iterative | value | match | identical |
| `diff07-plot` | plot | iterative | value | match | identical |
| `diff07-plot-null` | plot | iterative | value | match | identical |
| `diff07-caterpillar` | caterpillar_plot | iterative | value | match | identical |
| `diff07-caterpillar-flags` | caterpillar_plot | iterative | value | match | identical |
| `diff07-caterpillar-one-sided` | caterpillar_plot | root | value | match | identical |
| `diff07-bar` | bar_plot | iterative | value | match | identical |
| `diff07-bar-3` | bar_plot | iterative | value | match | identical |
| `diff07-firth` | logis_firth | iterative | value | match | identical |
| `diff07-firth-exact` | test | iterative | value | match | identical |
| `diff07-firth-sm` | SM_output | iterative | value | match | identical |
| `diff07-firth-gamma-score` | confint | root | value | match | identical |
| `diff08-fit` | logis_fe | iterative | value | match | identical |
| `diff08-fit-ban` | logis_fe | iterative | value | match | identical |
| `diff08-fit-all` | logis_fe | iterative | value | match | identical |
| `diff08-exact-two.sided` | test | iterative | value | match | identical |
| `diff08-score-two.sided` | test | iterative | value | match | identical |
| `diff08-exact-greater` | test | iterative | value | match | identical |
| `diff08-score-greater` | test | iterative | value | match | identical |
| `diff08-exact-less` | test | iterative | value | match | identical |
| `diff08-score-less` | test | iterative | value | match | identical |
| `diff08-bootstrap` | test | iterative | value | match | identical |
| `diff08-score-standard` | test | iterative | value | match | identical |
| `diff08-wald` | test | iterative | value | match | identical |
| `diff08-exact-parm` | test | iterative | value | match | identical |
| `diff08-sm` | SM_output | iterative | value | match | identical |
| `diff08-sm-null0` | SM_output | iterative | value | match | identical |
| `diff08-gamma-exact` | confint | root | value | match | identical |
| `diff08-sm-exact` | confint | root | value | match | identical |
| `diff08-gamma-score` | confint | root | value | match | identical |
| `diff08-sm-score` | confint | root | value | match | identical |
| `diff08-gamma-wald` | confint | iterative | value | match | identical |
| `diff08-sm-wald` | confint | iterative | value | match | identical |
| `diff08-sm-score-greater` | confint | root | value | match | identical |
| `diff08-sm-exact-less` | confint | root | value | match | identical |
| `diff08-summary-wald` | summary | iterative | value | match | identical |
| `diff08-summary-lr` | summary | iterative | value | match | identical |
| `diff08-summary-score` | summary | iterative | value | match | identical |
| `diff08-plot` | plot | iterative | value | match | identical |
| `diff08-plot-null` | plot | iterative | value | match | identical |
| `diff08-caterpillar` | caterpillar_plot | iterative | value | match | identical |
| `diff08-caterpillar-flags` | caterpillar_plot | iterative | value | match | identical |
| `diff08-caterpillar-one-sided` | caterpillar_plot | root | value | match | identical |
| `diff08-bar` | bar_plot | iterative | value | match | identical |
| `diff08-bar-3` | bar_plot | iterative | value | match | identical |
| `diff08-firth` | logis_firth | iterative | value | match | identical |
| `diff08-firth-exact` | test | iterative | value | match | identical |
| `diff08-firth-sm` | SM_output | iterative | value | match | identical |
| `diff08-firth-gamma-score` | confint | root | value | match | identical |
| `diff09-fit` | logis_fe | iterative | value | match | identical |
| `diff09-fit-ban` | logis_fe | iterative | value | match | identical |
| `diff09-fit-all` | logis_fe | iterative | value | match | identical |
| `diff09-exact-two.sided` | test | iterative | value | match | identical |
| `diff09-score-two.sided` | test | iterative | value | match | identical |
| `diff09-exact-greater` | test | iterative | value | match | identical |
| `diff09-score-greater` | test | iterative | value | match | identical |
| `diff09-exact-less` | test | iterative | value | match | identical |
| `diff09-score-less` | test | iterative | value | match | identical |
| `diff09-bootstrap` | test | iterative | value | match | identical |
| `diff09-score-standard` | test | iterative | value | match | identical |
| `diff09-wald` | test | iterative | value | match | identical |
| `diff09-exact-parm` | test | iterative | value | match | identical |
| `diff09-sm` | SM_output | iterative | value | match | identical |
| `diff09-sm-null0` | SM_output | iterative | value | match | identical |
| `diff09-gamma-exact` | confint | root | value | match | identical |
| `diff09-sm-exact` | confint | root | value | match | identical |
| `diff09-gamma-score` | confint | root | value | match | identical |
| `diff09-sm-score` | confint | root | value | match | identical |
| `diff09-gamma-wald` | confint | iterative | value | match | identical |
| `diff09-sm-wald` | confint | iterative | value | match | identical |
| `diff09-sm-score-greater` | confint | root | value | match | identical |
| `diff09-sm-exact-less` | confint | root | value | match | identical |
| `diff09-summary-wald` | summary | iterative | value | match | identical |
| `diff09-summary-lr` | summary | iterative | value | match | identical |
| `diff09-summary-score` | summary | iterative | value | match | identical |
| `diff09-plot` | plot | iterative | value | match | identical |
| `diff09-plot-null` | plot | iterative | value | match | identical |
| `diff09-caterpillar` | caterpillar_plot | iterative | value | match | identical |
| `diff09-caterpillar-flags` | caterpillar_plot | iterative | value | match | identical |
| `diff09-caterpillar-one-sided` | caterpillar_plot | root | value | match | identical |
| `diff09-bar` | bar_plot | iterative | value | match | identical |
| `diff09-bar-3` | bar_plot | iterative | value | match | identical |
| `diff09-firth` | logis_firth | iterative | value | match | identical |
| `diff09-firth-exact` | test | iterative | value | match | identical |
| `diff09-firth-sm` | SM_output | iterative | value | match | identical |
| `diff09-firth-gamma-score` | confint | root | value | match | identical |
| `diff10-fit` | logis_fe | iterative | value | match | identical |
| `diff10-fit-ban` | logis_fe | iterative | value | match | identical |
| `diff10-fit-all` | logis_fe | iterative | value | match | identical |
| `diff10-exact-two.sided` | test | iterative | value | match | identical |
| `diff10-score-two.sided` | test | iterative | value | match | identical |
| `diff10-exact-greater` | test | iterative | value | match | identical |
| `diff10-score-greater` | test | iterative | value | match | identical |
| `diff10-exact-less` | test | iterative | value | match | identical |
| `diff10-score-less` | test | iterative | value | match | identical |
| `diff10-bootstrap` | test | iterative | value | match | identical |
| `diff10-score-standard` | test | iterative | value | match | identical |
| `diff10-wald` | test | iterative | value | match | identical |
| `diff10-exact-parm` | test | iterative | value | match | identical |
| `diff10-sm` | SM_output | iterative | value | match | identical |
| `diff10-sm-null0` | SM_output | iterative | value | match | identical |
| `diff10-gamma-exact` | confint | root | value | match | identical |
| `diff10-sm-exact` | confint | root | value | match | identical |
| `diff10-gamma-score` | confint | root | value | match | identical |
| `diff10-sm-score` | confint | root | value | match | identical |
| `diff10-gamma-wald` | confint | iterative | value | match | identical |
| `diff10-sm-wald` | confint | iterative | value | match | identical |
| `diff10-sm-score-greater` | confint | root | value | match | identical |
| `diff10-sm-exact-less` | confint | root | value | match | identical |
| `diff10-summary-wald` | summary | iterative | value | match | identical |
| `diff10-summary-lr` | summary | iterative | value | match | identical |
| `diff10-summary-score` | summary | iterative | value | match | identical |
| `diff10-plot` | plot | iterative | value | match | identical |
| `diff10-plot-null` | plot | iterative | value | match | identical |
| `diff10-caterpillar` | caterpillar_plot | iterative | value | match | identical |
| `diff10-caterpillar-flags` | caterpillar_plot | iterative | value | match | identical |
| `diff10-caterpillar-one-sided` | caterpillar_plot | root | value | match | identical |
| `diff10-bar` | bar_plot | iterative | value | match | identical |
| `diff10-bar-3` | bar_plot | iterative | value | match | identical |
| `diff10-firth` | logis_firth | iterative | value | match | identical |
| `diff10-firth-exact` | test | iterative | value | match | identical |
| `diff10-firth-sm` | SM_output | iterative | value | match | identical |
| `diff10-firth-gamma-score` | confint | root | value | match | identical |
| `diff11-fit` | logis_fe | iterative | value | match | identical |
| `diff11-fit-ban` | logis_fe | iterative | value | match | identical |
| `diff11-fit-all` | logis_fe | iterative | value | match | identical |
| `diff11-exact-two.sided` | test | iterative | value | match | identical |
| `diff11-score-two.sided` | test | iterative | value | match | identical |
| `diff11-exact-greater` | test | iterative | value | match | identical |
| `diff11-score-greater` | test | iterative | value | match | identical |
| `diff11-exact-less` | test | iterative | value | match | identical |
| `diff11-score-less` | test | iterative | value | match | identical |
| `diff11-bootstrap` | test | iterative | value | match | identical |
| `diff11-score-standard` | test | iterative | value | match | identical |
| `diff11-wald` | test | iterative | value | match | identical |
| `diff11-exact-parm` | test | iterative | value | match | identical |
| `diff11-sm` | SM_output | iterative | value | match | identical |
| `diff11-sm-null0` | SM_output | iterative | value | match | identical |
| `diff11-gamma-exact` | confint | root | value | match | identical |
| `diff11-sm-exact` | confint | root | value | match | identical |
| `diff11-gamma-score` | confint | root | value | match | identical |
| `diff11-sm-score` | confint | root | value | match | identical |
| `diff11-gamma-wald` | confint | iterative | value | match | identical |
| `diff11-sm-wald` | confint | iterative | value | match | identical |
| `diff11-sm-score-greater` | confint | root | value | match | identical |
| `diff11-sm-exact-less` | confint | root | value | match | identical |
| `diff11-summary-wald` | summary | iterative | value | match | identical |
| `diff11-summary-lr` | summary | iterative | value | match | identical |
| `diff11-summary-score` | summary | iterative | value | match | identical |
| `diff11-plot` | plot | iterative | value | match | identical |
| `diff11-plot-null` | plot | iterative | value | match | identical |
| `diff11-caterpillar` | caterpillar_plot | iterative | value | match | identical |
| `diff11-caterpillar-flags` | caterpillar_plot | iterative | value | match | identical |
| `diff11-caterpillar-one-sided` | caterpillar_plot | root | value | match | identical |
| `diff11-bar` | bar_plot | iterative | value | match | identical |
| `diff11-bar-3` | bar_plot | iterative | value | match | identical |
| `diff11-firth` | logis_firth | iterative | value | match | identical |
| `diff11-firth-exact` | test | iterative | value | match | identical |
| `diff11-firth-sm` | SM_output | iterative | value | match | identical |
| `diff11-firth-gamma-score` | confint | root | value | match | identical |
| `diff12-fit` | logis_fe | iterative | value | match | identical |
| `diff12-fit-ban` | logis_fe | iterative | value | match | identical |
| `diff12-fit-all` | logis_fe | iterative | value | match | identical |
| `diff12-exact-two.sided` | test | iterative | value | match | identical |
| `diff12-score-two.sided` | test | iterative | value | match | identical |
| `diff12-exact-greater` | test | iterative | value | match | identical |
| `diff12-score-greater` | test | iterative | value | match | identical |
| `diff12-exact-less` | test | iterative | value | match | identical |
| `diff12-score-less` | test | iterative | value | match | identical |
| `diff12-bootstrap` | test | iterative | value | match | identical |
| `diff12-score-standard` | test | iterative | value | match | identical |
| `diff12-wald` | test | iterative | value | match | identical |
| `diff12-exact-parm` | test | iterative | value | match | identical |
| `diff12-sm` | SM_output | iterative | value | match | identical |
| `diff12-sm-null0` | SM_output | iterative | value | match | identical |
| `diff12-gamma-exact` | confint | root | value | match | identical |
| `diff12-sm-exact` | confint | root | value | match | identical |
| `diff12-gamma-score` | confint | root | value | match | identical |
| `diff12-sm-score` | confint | root | value | match | identical |
| `diff12-gamma-wald` | confint | iterative | value | match | identical |
| `diff12-sm-wald` | confint | iterative | value | match | identical |
| `diff12-sm-score-greater` | confint | root | value | match | identical |
| `diff12-sm-exact-less` | confint | root | value | match | identical |
| `diff12-summary-wald` | summary | iterative | value | match | identical |
| `diff12-summary-lr` | summary | iterative | value | match | identical |
| `diff12-summary-score` | summary | iterative | value | match | identical |
| `diff12-plot` | plot | iterative | value | match | identical |
| `diff12-plot-null` | plot | iterative | value | match | identical |
| `diff12-caterpillar` | caterpillar_plot | iterative | value | match | identical |
| `diff12-caterpillar-flags` | caterpillar_plot | iterative | value | match | identical |
| `diff12-caterpillar-one-sided` | caterpillar_plot | root | value | match | identical |
| `diff12-bar` | bar_plot | iterative | value | match | identical |
| `diff12-bar-3` | bar_plot | iterative | value | match | identical |
| `diff12-firth` | logis_firth | iterative | value | match | identical |
| `diff12-firth-exact` | test | iterative | value | match | identical |
| `diff12-firth-sm` | SM_output | iterative | value | match | identical |
| `diff12-firth-gamma-score` | confint | root | value | match | identical |
| `diff13-fit` | logis_fe | iterative | value | match | identical |
| `diff13-fit-ban` | logis_fe | iterative | value | match | identical |
| `diff13-fit-all` | logis_fe | iterative | value | match | identical |
| `diff13-exact-two.sided` | test | iterative | value | match | identical |
| `diff13-score-two.sided` | test | iterative | value | match | identical |
| `diff13-exact-greater` | test | iterative | value | match | identical |
| `diff13-score-greater` | test | iterative | value | match | identical |
| `diff13-exact-less` | test | iterative | value | match | identical |
| `diff13-score-less` | test | iterative | value | match | identical |
| `diff13-bootstrap` | test | iterative | value | match | identical |
| `diff13-score-standard` | test | iterative | value | match | identical |
| `diff13-wald` | test | iterative | value | match | identical |
| `diff13-exact-parm` | test | iterative | value | match | identical |
| `diff13-sm` | SM_output | iterative | value | match | identical |
| `diff13-sm-null0` | SM_output | iterative | value | match | identical |
| `diff13-gamma-exact` | confint | root | value | match | identical |
| `diff13-sm-exact` | confint | root | value | match | identical |
| `diff13-gamma-score` | confint | root | value | match | identical |
| `diff13-sm-score` | confint | root | value | match | identical |
| `diff13-gamma-wald` | confint | iterative | value | match | identical |
| `diff13-sm-wald` | confint | iterative | value | match | identical |
| `diff13-sm-score-greater` | confint | root | value | match | identical |
| `diff13-sm-exact-less` | confint | root | value | match | identical |
| `diff13-summary-wald` | summary | iterative | value | match | identical |
| `diff13-summary-lr` | summary | iterative | value | match | identical |
| `diff13-summary-score` | summary | iterative | value | match | identical |
| `diff13-plot` | plot | iterative | value | match | identical |
| `diff13-plot-null` | plot | iterative | value | match | identical |
| `diff13-caterpillar` | caterpillar_plot | iterative | value | match | identical |
| `diff13-caterpillar-flags` | caterpillar_plot | iterative | value | match | identical |
| `diff13-caterpillar-one-sided` | caterpillar_plot | root | value | match | identical |
| `diff13-bar` | bar_plot | iterative | value | match | identical |
| `diff13-bar-3` | bar_plot | iterative | value | match | identical |
| `diff13-firth` | logis_firth | iterative | value | match | identical |
| `diff13-firth-exact` | test | iterative | value | match | identical |
| `diff13-firth-sm` | SM_output | iterative | value | match | identical |
| `diff13-firth-gamma-score` | confint | root | value | match | identical |
| `diff14-fit` | logis_fe | iterative | value | match | identical |
| `diff14-fit-ban` | logis_fe | iterative | value | match | identical |
| `diff14-fit-all` | logis_fe | iterative | value | match | identical |
| `diff14-exact-two.sided` | test | iterative | value | match | identical |
| `diff14-score-two.sided` | test | iterative | value | match | identical |
| `diff14-exact-greater` | test | iterative | value | match | identical |
| `diff14-score-greater` | test | iterative | value | match | identical |
| `diff14-exact-less` | test | iterative | value | match | identical |
| `diff14-score-less` | test | iterative | value | match | identical |
| `diff14-bootstrap` | test | iterative | value | match | identical |
| `diff14-score-standard` | test | iterative | value | match | identical |
| `diff14-wald` | test | iterative | value | match | identical |
| `diff14-exact-parm` | test | iterative | value | match | identical |
| `diff14-sm` | SM_output | iterative | value | match | identical |
| `diff14-sm-null0` | SM_output | iterative | value | match | identical |
| `diff14-gamma-exact` | confint | root | value | match | identical |
| `diff14-sm-exact` | confint | root | value | match | identical |
| `diff14-gamma-score` | confint | root | value | match | identical |
| `diff14-sm-score` | confint | root | value | match | identical |
| `diff14-gamma-wald` | confint | iterative | value | match | identical |
| `diff14-sm-wald` | confint | iterative | value | match | identical |
| `diff14-sm-score-greater` | confint | root | value | match | identical |
| `diff14-sm-exact-less` | confint | root | value | match | identical |
| `diff14-summary-wald` | summary | iterative | value | match | identical |
| `diff14-summary-lr` | summary | iterative | value | match | identical |
| `diff14-summary-score` | summary | iterative | value | match | identical |
| `diff14-plot` | plot | iterative | value | match | identical |
| `diff14-plot-null` | plot | iterative | value | match | identical |
| `diff14-caterpillar` | caterpillar_plot | iterative | value | match | identical |
| `diff14-caterpillar-flags` | caterpillar_plot | iterative | value | match | identical |
| `diff14-caterpillar-one-sided` | caterpillar_plot | root | value | match | identical |
| `diff14-bar` | bar_plot | iterative | value | match | identical |
| `diff14-bar-3` | bar_plot | iterative | value | match | identical |
| `diff14-firth` | logis_firth | iterative | value | match | identical |
| `diff14-firth-exact` | test | iterative | value | match | identical |
| `diff14-firth-sm` | SM_output | iterative | value | match | identical |
| `diff14-firth-gamma-score` | confint | root | value | match | identical |
| `diff15-fit` | logis_fe | iterative | value | match | identical |
| `diff15-fit-ban` | logis_fe | iterative | value | match | identical |
| `diff15-fit-all` | logis_fe | iterative | value | match | identical |
| `diff15-exact-two.sided` | test | iterative | value | match | identical |
| `diff15-score-two.sided` | test | iterative | value | match | identical |
| `diff15-exact-greater` | test | iterative | value | match | identical |
| `diff15-score-greater` | test | iterative | value | match | identical |
| `diff15-exact-less` | test | iterative | value | match | identical |
| `diff15-score-less` | test | iterative | value | match | identical |
| `diff15-bootstrap` | test | iterative | value | match | identical |
| `diff15-score-standard` | test | iterative | value | match | identical |
| `diff15-wald` | test | iterative | value | match | identical |
| `diff15-exact-parm` | test | iterative | value | match | identical |
| `diff15-sm` | SM_output | iterative | value | match | identical |
| `diff15-sm-null0` | SM_output | iterative | value | match | identical |
| `diff15-gamma-exact` | confint | root | value | match | identical |
| `diff15-sm-exact` | confint | root | value | match | identical |
| `diff15-gamma-score` | confint | root | value | match | identical |
| `diff15-sm-score` | confint | root | value | match | identical |
| `diff15-gamma-wald` | confint | iterative | value | match | identical |
| `diff15-sm-wald` | confint | iterative | value | match | identical |
| `diff15-sm-score-greater` | confint | root | value | match | identical |
| `diff15-sm-exact-less` | confint | root | value | match | identical |
| `diff15-summary-wald` | summary | iterative | value | match | identical |
| `diff15-summary-lr` | summary | iterative | value | match | identical |
| `diff15-summary-score` | summary | iterative | value | match | identical |
| `diff15-plot` | plot | iterative | value | match | identical |
| `diff15-plot-null` | plot | iterative | value | match | identical |
| `diff15-caterpillar` | caterpillar_plot | iterative | value | match | identical |
| `diff15-caterpillar-flags` | caterpillar_plot | iterative | value | match | identical |
| `diff15-caterpillar-one-sided` | caterpillar_plot | root | value | match | identical |
| `diff15-bar` | bar_plot | iterative | value | match | identical |
| `diff15-bar-3` | bar_plot | iterative | value | match | identical |
| `diff15-firth` | logis_firth | iterative | value | match | identical |
| `diff15-firth-exact` | test | iterative | value | match | identical |
| `diff15-firth-sm` | SM_output | iterative | value | match | identical |
| `diff15-firth-gamma-score` | confint | root | value | match | identical |
| `diff16-fit` | logis_fe | iterative | value | match | identical |
| `diff16-fit-ban` | logis_fe | iterative | value | match | identical |
| `diff16-fit-all` | logis_fe | iterative | value | match | identical |
| `diff16-exact-two.sided` | test | iterative | value | match | identical |
| `diff16-score-two.sided` | test | iterative | value | match | identical |
| `diff16-exact-greater` | test | iterative | value | match | identical |
| `diff16-score-greater` | test | iterative | value | match | identical |
| `diff16-exact-less` | test | iterative | value | match | identical |
| `diff16-score-less` | test | iterative | value | match | identical |
| `diff16-bootstrap` | test | iterative | value | match | identical |
| `diff16-score-standard` | test | iterative | value | match | identical |
| `diff16-wald` | test | iterative | value | match | identical |
| `diff16-exact-parm` | test | iterative | value | match | identical |
| `diff16-sm` | SM_output | iterative | value | match | identical |
| `diff16-sm-null0` | SM_output | iterative | value | match | identical |
| `diff16-gamma-exact` | confint | root | value | match | identical |
| `diff16-sm-exact` | confint | root | value | match | identical |
| `diff16-gamma-score` | confint | root | value | match | identical |
| `diff16-sm-score` | confint | root | value | match | identical |
| `diff16-gamma-wald` | confint | iterative | value | match | identical |
| `diff16-sm-wald` | confint | iterative | value | match | identical |
| `diff16-sm-score-greater` | confint | root | value | match | identical |
| `diff16-sm-exact-less` | confint | root | value | match | identical |
| `diff16-summary-wald` | summary | iterative | value | match | identical |
| `diff16-summary-lr` | summary | iterative | value | match | identical |
| `diff16-summary-score` | summary | iterative | value | match | identical |
| `diff16-plot` | plot | iterative | value | match | identical |
| `diff16-plot-null` | plot | iterative | value | match | identical |
| `diff16-caterpillar` | caterpillar_plot | iterative | value | match | identical |
| `diff16-caterpillar-flags` | caterpillar_plot | iterative | value | match | identical |
| `diff16-caterpillar-one-sided` | caterpillar_plot | root | value | match | identical |
| `diff16-bar` | bar_plot | iterative | value | match | identical |
| `diff16-bar-3` | bar_plot | iterative | value | match | identical |
| `diff16-firth` | logis_firth | iterative | value | match | identical |
| `diff16-firth-exact` | test | iterative | value | match | identical |
| `diff16-firth-sm` | SM_output | iterative | value | match | identical |
| `diff16-firth-gamma-score` | confint | root | value | match | identical |
| `diff17-fit` | logis_fe | iterative | value | match | identical |
| `diff17-fit-ban` | logis_fe | iterative | value | match | identical |
| `diff17-fit-all` | logis_fe | iterative | value | match | identical |
| `diff17-exact-two.sided` | test | iterative | value | match | identical |
| `diff17-score-two.sided` | test | iterative | value | match | identical |
| `diff17-exact-greater` | test | iterative | value | match | identical |
| `diff17-score-greater` | test | iterative | value | match | identical |
| `diff17-exact-less` | test | iterative | value | match | identical |
| `diff17-score-less` | test | iterative | value | match | identical |
| `diff17-bootstrap` | test | iterative | value | match | identical |
| `diff17-score-standard` | test | iterative | value | match | identical |
| `diff17-wald` | test | iterative | value | match | identical |
| `diff17-exact-parm` | test | iterative | value | match | identical |
| `diff17-sm` | SM_output | iterative | value | match | identical |
| `diff17-sm-null0` | SM_output | iterative | value | match | identical |
| `diff17-gamma-exact` | confint | root | value | match | identical |
| `diff17-sm-exact` | confint | root | value | match | identical |
| `diff17-gamma-score` | confint | root | value | match | identical |
| `diff17-sm-score` | confint | root | value | match | identical |
| `diff17-gamma-wald` | confint | iterative | value | match | identical |
| `diff17-sm-wald` | confint | iterative | value | match | identical |
| `diff17-sm-score-greater` | confint | root | value | match | identical |
| `diff17-sm-exact-less` | confint | root | value | match | identical |
| `diff17-summary-wald` | summary | iterative | value | match | identical |
| `diff17-summary-lr` | summary | iterative | value | match | identical |
| `diff17-summary-score` | summary | iterative | value | match | identical |
| `diff17-plot` | plot | iterative | value | match | identical |
| `diff17-plot-null` | plot | iterative | value | match | identical |
| `diff17-caterpillar` | caterpillar_plot | iterative | value | match | identical |
| `diff17-caterpillar-flags` | caterpillar_plot | iterative | value | match | identical |
| `diff17-caterpillar-one-sided` | caterpillar_plot | root | value | match | identical |
| `diff17-bar` | bar_plot | iterative | value | match | identical |
| `diff17-bar-3` | bar_plot | iterative | value | match | identical |
| `diff17-firth` | logis_firth | iterative | value | match | identical |
| `diff17-firth-exact` | test | iterative | value | match | identical |
| `diff17-firth-sm` | SM_output | iterative | value | match | identical |
| `diff17-firth-gamma-score` | confint | root | value | match | identical |
| `diff18-fit` | logis_fe | iterative | value | match | identical |
| `diff18-fit-ban` | logis_fe | iterative | value | match | identical |
| `diff18-fit-all` | logis_fe | iterative | value | match | identical |
| `diff18-exact-two.sided` | test | iterative | value | match | identical |
| `diff18-score-two.sided` | test | iterative | value | match | identical |
| `diff18-exact-greater` | test | iterative | value | match | identical |
| `diff18-score-greater` | test | iterative | value | match | identical |
| `diff18-exact-less` | test | iterative | value | match | identical |
| `diff18-score-less` | test | iterative | value | match | identical |
| `diff18-bootstrap` | test | iterative | value | match | identical |
| `diff18-score-standard` | test | iterative | value | match | identical |
| `diff18-wald` | test | iterative | value | match | identical |
| `diff18-exact-parm` | test | iterative | value | match | identical |
| `diff18-sm` | SM_output | iterative | value | match | identical |
| `diff18-sm-null0` | SM_output | iterative | value | match | identical |
| `diff18-gamma-exact` | confint | root | value | match | identical |
| `diff18-sm-exact` | confint | root | value | match | identical |
| `diff18-gamma-score` | confint | root | value | match | identical |
| `diff18-sm-score` | confint | root | value | match | identical |
| `diff18-gamma-wald` | confint | iterative | value | match | identical |
| `diff18-sm-wald` | confint | iterative | value | match | identical |
| `diff18-sm-score-greater` | confint | root | value | match | identical |
| `diff18-sm-exact-less` | confint | root | value | match | identical |
| `diff18-summary-wald` | summary | iterative | value | match | identical |
| `diff18-summary-lr` | summary | iterative | value | match | identical |
| `diff18-summary-score` | summary | iterative | value | match | identical |
| `diff18-plot` | plot | iterative | value | match | identical |
| `diff18-plot-null` | plot | iterative | value | match | identical |
| `diff18-caterpillar` | caterpillar_plot | iterative | value | match | identical |
| `diff18-caterpillar-flags` | caterpillar_plot | iterative | value | match | identical |
| `diff18-caterpillar-one-sided` | caterpillar_plot | root | value | match | identical |
| `diff18-bar` | bar_plot | iterative | value | match | identical |
| `diff18-bar-3` | bar_plot | iterative | value | match | identical |
| `diff18-firth` | logis_firth | iterative | value | match | identical |
| `diff18-firth-exact` | test | iterative | value | match | identical |
| `diff18-firth-sm` | SM_output | iterative | value | match | identical |
| `diff18-firth-gamma-score` | confint | root | value | match | identical |
| `diff19-fit` | logis_fe | iterative | value | match | identical |
| `diff19-fit-ban` | logis_fe | iterative | value | match | identical |
| `diff19-fit-all` | logis_fe | iterative | value | match | identical |
| `diff19-exact-two.sided` | test | iterative | value | match | identical |
| `diff19-score-two.sided` | test | iterative | value | match | identical |
| `diff19-exact-greater` | test | iterative | value | match | identical |
| `diff19-score-greater` | test | iterative | value | match | identical |
| `diff19-exact-less` | test | iterative | value | match | identical |
| `diff19-score-less` | test | iterative | value | match | identical |
| `diff19-bootstrap` | test | iterative | value | match | identical |
| `diff19-score-standard` | test | iterative | value | match | identical |
| `diff19-wald` | test | iterative | value | match | identical |
| `diff19-exact-parm` | test | iterative | value | match | identical |
| `diff19-sm` | SM_output | iterative | value | match | identical |
| `diff19-sm-null0` | SM_output | iterative | value | match | identical |
| `diff19-gamma-exact` | confint | root | value | match | identical |
| `diff19-sm-exact` | confint | root | value | match | identical |
| `diff19-gamma-score` | confint | root | value | match | identical |
| `diff19-sm-score` | confint | root | value | match | identical |
| `diff19-gamma-wald` | confint | iterative | value | match | identical |
| `diff19-sm-wald` | confint | iterative | value | match | identical |
| `diff19-sm-score-greater` | confint | root | value | match | identical |
| `diff19-sm-exact-less` | confint | root | value | match | identical |
| `diff19-summary-wald` | summary | iterative | value | match | identical |
| `diff19-summary-lr` | summary | iterative | value | match | identical |
| `diff19-summary-score` | summary | iterative | value | match | identical |
| `diff19-plot` | plot | iterative | value | match | identical |
| `diff19-plot-null` | plot | iterative | value | match | identical |
| `diff19-caterpillar` | caterpillar_plot | iterative | value | match | identical |
| `diff19-caterpillar-flags` | caterpillar_plot | iterative | value | match | identical |
| `diff19-caterpillar-one-sided` | caterpillar_plot | root | value | match | identical |
| `diff19-bar` | bar_plot | iterative | value | match | identical |
| `diff19-bar-3` | bar_plot | iterative | value | match | identical |
| `diff19-firth` | logis_firth | iterative | value | match | identical |
| `diff19-firth-exact` | test | iterative | value | match | identical |
| `diff19-firth-sm` | SM_output | iterative | value | match | identical |
| `diff19-firth-gamma-score` | confint | root | value | match | identical |
| `diff20-fit` | logis_fe | iterative | value | match | identical |
| `diff20-fit-ban` | logis_fe | iterative | value | match | identical |
| `diff20-fit-all` | logis_fe | iterative | value | match | identical |
| `diff20-exact-two.sided` | test | iterative | value | match | identical |
| `diff20-score-two.sided` | test | iterative | value | match | identical |
| `diff20-exact-greater` | test | iterative | value | match | identical |
| `diff20-score-greater` | test | iterative | value | match | identical |
| `diff20-exact-less` | test | iterative | value | match | identical |
| `diff20-score-less` | test | iterative | value | match | identical |
| `diff20-bootstrap` | test | iterative | value | match | identical |
| `diff20-score-standard` | test | iterative | value | match | identical |
| `diff20-wald` | test | iterative | value | match | identical |
| `diff20-exact-parm` | test | iterative | value | match | identical |
| `diff20-sm` | SM_output | iterative | value | match | identical |
| `diff20-sm-null0` | SM_output | iterative | value | match | identical |
| `diff20-gamma-exact` | confint | root | value | match | identical |
| `diff20-sm-exact` | confint | root | value | match | identical |
| `diff20-gamma-score` | confint | root | value | match | identical |
| `diff20-sm-score` | confint | root | value | match | identical |
| `diff20-gamma-wald` | confint | iterative | value | match | identical |
| `diff20-sm-wald` | confint | iterative | value | match | identical |
| `diff20-sm-score-greater` | confint | root | value | match | identical |
| `diff20-sm-exact-less` | confint | root | value | match | identical |
| `diff20-summary-wald` | summary | iterative | value | match | identical |
| `diff20-summary-lr` | summary | iterative | value | match | identical |
| `diff20-summary-score` | summary | iterative | value | match | identical |
| `diff20-plot` | plot | iterative | value | match | identical |
| `diff20-plot-null` | plot | iterative | value | match | identical |
| `diff20-caterpillar` | caterpillar_plot | iterative | value | match | identical |
| `diff20-caterpillar-flags` | caterpillar_plot | iterative | value | match | identical |
| `diff20-caterpillar-one-sided` | caterpillar_plot | root | value | match | identical |
| `diff20-bar` | bar_plot | iterative | value | match | identical |
| `diff20-bar-3` | bar_plot | iterative | value | match | identical |
| `diff20-firth` | logis_firth | iterative | value | match | identical |
| `diff20-firth-exact` | test | iterative | value | match | identical |
| `diff20-firth-sm` | SM_output | iterative | value | match | identical |
| `diff20-firth-gamma-score` | confint | root | value | match | identical |
| `diff21-fit` | logis_fe | iterative | value | match | identical |
| `diff21-fit-ban` | logis_fe | iterative | value | match | within tolerance: AUC |
| `diff21-fit-all` | logis_fe | iterative | value | match | identical |
| `diff21-exact-two.sided` | test | iterative | value | match | identical |
| `diff21-score-two.sided` | test | iterative | value | match | identical |
| `diff21-exact-greater` | test | iterative | value | match | identical |
| `diff21-score-greater` | test | iterative | value | match | identical |
| `diff21-exact-less` | test | iterative | value | match | identical |
| `diff21-score-less` | test | iterative | value | match | identical |
| `diff21-bootstrap` | test | iterative | value | match | identical |
| `diff21-score-standard` | test | iterative | value | match | identical |
| `diff21-wald` | test | iterative | value | match | identical |
| `diff21-exact-parm` | test | iterative | value | match | identical |
| `diff21-sm` | SM_output | iterative | value | match | identical |
| `diff21-sm-null0` | SM_output | iterative | value | match | identical |
| `diff21-gamma-exact` | confint | root | value | match | identical |
| `diff21-sm-exact` | confint | root | value | match | identical |
| `diff21-gamma-score` | confint | root | value | match | identical |
| `diff21-sm-score` | confint | root | value | match | identical |
| `diff21-gamma-wald` | confint | iterative | value | match | identical |
| `diff21-sm-wald` | confint | iterative | value | match | identical |
| `diff21-sm-score-greater` | confint | root | value | match | identical |
| `diff21-sm-exact-less` | confint | root | value | match | identical |
| `diff21-summary-wald` | summary | iterative | value | match | identical |
| `diff21-summary-lr` | summary | iterative | value | match | identical |
| `diff21-summary-score` | summary | iterative | value | match | identical |
| `diff21-plot` | plot | iterative | value | match | identical |
| `diff21-plot-null` | plot | iterative | value | match | identical |
| `diff21-caterpillar` | caterpillar_plot | iterative | value | match | identical |
| `diff21-caterpillar-flags` | caterpillar_plot | iterative | value | match | identical |
| `diff21-caterpillar-one-sided` | caterpillar_plot | root | value | match | identical |
| `diff21-bar` | bar_plot | iterative | value | match | identical |
| `diff21-bar-3` | bar_plot | iterative | value | match | identical |
| `diff21-firth` | logis_firth | iterative | value | match | identical |
| `diff21-firth-exact` | test | iterative | value | match | identical |
| `diff21-firth-sm` | SM_output | iterative | value | match | identical |
| `diff21-firth-gamma-score` | confint | root | value | match | identical |
| `diff22-fit` | logis_fe | iterative | value | match | identical |
| `diff22-fit-ban` | logis_fe | iterative | value | match | within tolerance: AUC |
| `diff22-fit-all` | logis_fe | iterative | value | match | identical |
| `diff22-exact-two.sided` | test | iterative | value | match | identical |
| `diff22-score-two.sided` | test | iterative | value | match | identical |
| `diff22-exact-greater` | test | iterative | value | match | identical |
| `diff22-score-greater` | test | iterative | value | match | identical |
| `diff22-exact-less` | test | iterative | value | match | identical |
| `diff22-score-less` | test | iterative | value | match | identical |
| `diff22-bootstrap` | test | iterative | value | match | identical |
| `diff22-score-standard` | test | iterative | value | match | identical |
| `diff22-wald` | test | iterative | value | match | identical |
| `diff22-exact-parm` | test | iterative | value | match | identical |
| `diff22-sm` | SM_output | iterative | value | match | identical |
| `diff22-sm-null0` | SM_output | iterative | value | match | identical |
| `diff22-gamma-exact` | confint | root | value | match | identical |
| `diff22-sm-exact` | confint | root | value | match | identical |
| `diff22-gamma-score` | confint | root | value | match | identical |
| `diff22-sm-score` | confint | root | value | match | identical |
| `diff22-gamma-wald` | confint | iterative | value | match | identical |
| `diff22-sm-wald` | confint | iterative | value | match | identical |
| `diff22-sm-score-greater` | confint | root | value | match | identical |
| `diff22-sm-exact-less` | confint | root | value | match | identical |
| `diff22-summary-wald` | summary | iterative | value | match | identical |
| `diff22-summary-lr` | summary | iterative | value | match | identical |
| `diff22-summary-score` | summary | iterative | value | match | identical |
| `diff22-plot` | plot | iterative | value | match | identical |
| `diff22-plot-null` | plot | iterative | value | match | identical |
| `diff22-caterpillar` | caterpillar_plot | iterative | value | match | identical |
| `diff22-caterpillar-flags` | caterpillar_plot | iterative | value | match | identical |
| `diff22-caterpillar-one-sided` | caterpillar_plot | root | value | match | identical |
| `diff22-bar` | bar_plot | iterative | value | match | identical |
| `diff22-bar-3` | bar_plot | iterative | value | match | identical |
| `diff22-firth` | logis_firth | iterative | value | match | identical |
| `diff22-firth-exact` | test | iterative | value | match | identical |
| `diff22-firth-sm` | SM_output | iterative | value | match | identical |
| `diff22-firth-gamma-score` | confint | root | value | match | identical |
| `diff23-fit` | logis_fe | iterative | value | match | identical |
| `diff23-fit-ban` | logis_fe | iterative | value | match | identical |
| `diff23-fit-all` | logis_fe | iterative | value | match | identical |
| `diff23-exact-two.sided` | test | iterative | value | match | identical |
| `diff23-score-two.sided` | test | iterative | value | match | identical |
| `diff23-exact-greater` | test | iterative | value | match | identical |
| `diff23-score-greater` | test | iterative | value | match | identical |
| `diff23-exact-less` | test | iterative | value | match | identical |
| `diff23-score-less` | test | iterative | value | match | identical |
| `diff23-bootstrap` | test | iterative | value | match | identical |
| `diff23-score-standard` | test | iterative | value | match | identical |
| `diff23-wald` | test | iterative | value | match | identical |
| `diff23-exact-parm` | test | iterative | value | match | identical |
| `diff23-sm` | SM_output | iterative | value | match | identical |
| `diff23-sm-null0` | SM_output | iterative | value | match | identical |
| `diff23-gamma-exact` | confint | root | value | match | identical |
| `diff23-sm-exact` | confint | root | value | match | identical |
| `diff23-gamma-score` | confint | root | value | match | identical |
| `diff23-sm-score` | confint | root | value | match | identical |
| `diff23-gamma-wald` | confint | iterative | value | match | identical |
| `diff23-sm-wald` | confint | iterative | value | match | identical |
| `diff23-sm-score-greater` | confint | root | value | match | identical |
| `diff23-sm-exact-less` | confint | root | value | match | identical |
| `diff23-summary-wald` | summary | iterative | value | match | identical |
| `diff23-summary-lr` | summary | iterative | value | match | identical |
| `diff23-summary-score` | summary | iterative | value | match | identical |
| `diff23-plot` | plot | iterative | value | match | identical |
| `diff23-plot-null` | plot | iterative | value | match | identical |
| `diff23-caterpillar` | caterpillar_plot | iterative | value | match | identical |
| `diff23-caterpillar-flags` | caterpillar_plot | iterative | value | match | identical |
| `diff23-caterpillar-one-sided` | caterpillar_plot | root | value | match | identical |
| `diff23-bar` | bar_plot | iterative | value | match | identical |
| `diff23-bar-3` | bar_plot | iterative | value | match | identical |
| `diff23-firth` | logis_firth | iterative | value | match | identical |
| `diff23-firth-exact` | test | iterative | value | match | identical |
| `diff23-firth-sm` | SM_output | iterative | value | match | identical |
| `diff23-firth-gamma-score` | confint | root | value | match | identical |
| `diff24-fit` | logis_fe | iterative | value | match | identical |
| `diff24-fit-ban` | logis_fe | iterative | value | match | identical |
| `diff24-fit-all` | logis_fe | iterative | value | match | identical |
| `diff24-exact-two.sided` | test | iterative | value | match | identical |
| `diff24-score-two.sided` | test | iterative | value | match | identical |
| `diff24-exact-greater` | test | iterative | value | match | identical |
| `diff24-score-greater` | test | iterative | value | match | identical |
| `diff24-exact-less` | test | iterative | value | match | identical |
| `diff24-score-less` | test | iterative | value | match | identical |
| `diff24-bootstrap` | test | iterative | value | match | identical |
| `diff24-score-standard` | test | iterative | value | match | identical |
| `diff24-wald` | test | iterative | value | match | identical |
| `diff24-exact-parm` | test | iterative | value | match | identical |
| `diff24-sm` | SM_output | iterative | value | match | identical |
| `diff24-sm-null0` | SM_output | iterative | value | match | identical |
| `diff24-gamma-exact` | confint | root | value | match | identical |
| `diff24-sm-exact` | confint | root | value | match | identical |
| `diff24-gamma-score` | confint | root | value | match | identical |
| `diff24-sm-score` | confint | root | value | match | identical |
| `diff24-gamma-wald` | confint | iterative | value | match | identical |
| `diff24-sm-wald` | confint | iterative | value | match | identical |
| `diff24-sm-score-greater` | confint | root | value | match | identical |
| `diff24-sm-exact-less` | confint | root | value | match | identical |
| `diff24-summary-wald` | summary | iterative | value | match | identical |
| `diff24-summary-lr` | summary | iterative | value | match | identical |
| `diff24-summary-score` | summary | iterative | value | match | identical |
| `diff24-plot` | plot | iterative | value | match | identical |
| `diff24-plot-null` | plot | iterative | value | match | identical |
| `diff24-caterpillar` | caterpillar_plot | iterative | value | match | identical |
| `diff24-caterpillar-flags` | caterpillar_plot | iterative | value | match | identical |
| `diff24-caterpillar-one-sided` | caterpillar_plot | root | value | match | identical |
| `diff24-bar` | bar_plot | iterative | value | match | identical |
| `diff24-bar-3` | bar_plot | iterative | value | match | identical |
| `diff24-firth` | logis_firth | iterative | value | match | identical |
| `diff24-firth-exact` | test | iterative | value | match | identical |
| `diff24-firth-sm` | SM_output | iterative | value | match | identical |
| `diff24-firth-gamma-score` | confint | root | value | match | identical |
| `diff25-fit` | logis_fe | iterative | value | match | identical |
| `diff25-fit-ban` | logis_fe | iterative | value | match | within tolerance: AUC |
| `diff25-fit-all` | logis_fe | iterative | value | match | identical |
| `diff25-exact-two.sided` | test | iterative | value | match | identical |
| `diff25-score-two.sided` | test | iterative | value | match | identical |
| `diff25-exact-greater` | test | iterative | value | match | identical |
| `diff25-score-greater` | test | iterative | value | match | identical |
| `diff25-exact-less` | test | iterative | value | match | identical |
| `diff25-score-less` | test | iterative | value | match | identical |
| `diff25-bootstrap` | test | iterative | value | match | identical |
| `diff25-score-standard` | test | iterative | value | match | identical |
| `diff25-wald` | test | iterative | value | match | identical |
| `diff25-exact-parm` | test | iterative | value | match | identical |
| `diff25-sm` | SM_output | iterative | value | match | identical |
| `diff25-sm-null0` | SM_output | iterative | value | match | identical |
| `diff25-gamma-exact` | confint | root | value | match | identical |
| `diff25-sm-exact` | confint | root | value | match | identical |
| `diff25-gamma-score` | confint | root | value | match | identical |
| `diff25-sm-score` | confint | root | value | match | identical |
| `diff25-gamma-wald` | confint | iterative | value | match | identical |
| `diff25-sm-wald` | confint | iterative | value | match | identical |
| `diff25-sm-score-greater` | confint | root | value | match | identical |
| `diff25-sm-exact-less` | confint | root | value | match | identical |
| `diff25-summary-wald` | summary | iterative | value | match | identical |
| `diff25-summary-lr` | summary | iterative | value | match | identical |
| `diff25-summary-score` | summary | iterative | value | match | identical |
| `diff25-plot` | plot | iterative | value | match | identical |
| `diff25-plot-null` | plot | iterative | value | match | identical |
| `diff25-caterpillar` | caterpillar_plot | iterative | value | match | identical |
| `diff25-caterpillar-flags` | caterpillar_plot | iterative | value | match | identical |
| `diff25-caterpillar-one-sided` | caterpillar_plot | root | value | match | identical |
| `diff25-bar` | bar_plot | iterative | value | match | identical |
| `diff25-bar-3` | bar_plot | iterative | value | match | identical |
| `diff25-firth` | logis_firth | iterative | value | match | identical |
| `diff25-firth-exact` | test | iterative | value | match | identical |
| `diff25-firth-sm` | SM_output | iterative | value | match | identical |
| `diff25-firth-gamma-score` | confint | root | value | match | identical |
| `diff26-fit` | logis_fe | iterative | value | match | identical |
| `diff26-fit-ban` | logis_fe | iterative | value | match | identical |
| `diff26-fit-all` | logis_fe | iterative | value | match | identical |
| `diff26-exact-two.sided` | test | iterative | value | match | identical |
| `diff26-score-two.sided` | test | iterative | value | match | identical |
| `diff26-exact-greater` | test | iterative | value | match | identical |
| `diff26-score-greater` | test | iterative | value | match | identical |
| `diff26-exact-less` | test | iterative | value | match | identical |
| `diff26-score-less` | test | iterative | value | match | identical |
| `diff26-bootstrap` | test | iterative | value | match | identical |
| `diff26-score-standard` | test | iterative | value | match | identical |
| `diff26-wald` | test | iterative | value | match | identical |
| `diff26-exact-parm` | test | iterative | value | match | identical |
| `diff26-sm` | SM_output | iterative | value | match | identical |
| `diff26-sm-null0` | SM_output | iterative | value | match | identical |
| `diff26-gamma-exact` | confint | root | value | match | identical |
| `diff26-sm-exact` | confint | root | value | match | identical |
| `diff26-gamma-score` | confint | root | value | match | identical |
| `diff26-sm-score` | confint | root | value | match | identical |
| `diff26-gamma-wald` | confint | iterative | value | match | identical |
| `diff26-sm-wald` | confint | iterative | value | match | identical |
| `diff26-sm-score-greater` | confint | root | value | match | identical |
| `diff26-sm-exact-less` | confint | root | value | match | identical |
| `diff26-summary-wald` | summary | iterative | value | match | identical |
| `diff26-summary-lr` | summary | iterative | value | match | identical |
| `diff26-summary-score` | summary | iterative | value | match | identical |
| `diff26-plot` | plot | iterative | value | match | identical |
| `diff26-plot-null` | plot | iterative | value | match | identical |
| `diff26-caterpillar` | caterpillar_plot | iterative | value | match | identical |
| `diff26-caterpillar-flags` | caterpillar_plot | iterative | value | match | identical |
| `diff26-caterpillar-one-sided` | caterpillar_plot | root | value | match | identical |
| `diff26-bar` | bar_plot | iterative | value | match | identical |
| `diff26-bar-3` | bar_plot | iterative | value | match | identical |
| `diff26-firth` | logis_firth | iterative | value | match | within tolerance: AUC |
| `diff26-firth-exact` | test | iterative | value | match | identical |
| `diff26-firth-sm` | SM_output | iterative | value | match | identical |
| `diff26-firth-gamma-score` | confint | root | value | match | identical |
| `diff27-fit` | logis_fe | iterative | value | match | identical |
| `diff27-fit-ban` | logis_fe | iterative | value | match | identical |
| `diff27-fit-all` | logis_fe | iterative | value | match | identical |
| `diff27-exact-two.sided` | test | iterative | value | match | identical |
| `diff27-score-two.sided` | test | iterative | value | match | identical |
| `diff27-exact-greater` | test | iterative | value | match | identical |
| `diff27-score-greater` | test | iterative | value | match | identical |
| `diff27-exact-less` | test | iterative | value | match | identical |
| `diff27-score-less` | test | iterative | value | match | identical |
| `diff27-bootstrap` | test | iterative | value | match | identical |
| `diff27-score-standard` | test | iterative | value | match | identical |
| `diff27-wald` | test | iterative | value | match | identical |
| `diff27-exact-parm` | test | iterative | value | match | identical |
| `diff27-sm` | SM_output | iterative | value | match | identical |
| `diff27-sm-null0` | SM_output | iterative | value | match | identical |
| `diff27-gamma-exact` | confint | root | value | match | identical |
| `diff27-sm-exact` | confint | root | value | match | identical |
| `diff27-gamma-score` | confint | root | value | match | identical |
| `diff27-sm-score` | confint | root | value | match | identical |
| `diff27-gamma-wald` | confint | iterative | value | match | identical |
| `diff27-sm-wald` | confint | iterative | value | match | identical |
| `diff27-sm-score-greater` | confint | root | value | match | identical |
| `diff27-sm-exact-less` | confint | root | value | match | identical |
| `diff27-summary-wald` | summary | iterative | value | match | identical |
| `diff27-summary-lr` | summary | iterative | value | match | identical |
| `diff27-summary-score` | summary | iterative | value | match | identical |
| `diff27-plot` | plot | iterative | value | match | identical |
| `diff27-plot-null` | plot | iterative | value | match | identical |
| `diff27-caterpillar` | caterpillar_plot | iterative | value | match | identical |
| `diff27-caterpillar-flags` | caterpillar_plot | iterative | value | match | identical |
| `diff27-caterpillar-one-sided` | caterpillar_plot | root | value | match | identical |
| `diff27-bar` | bar_plot | iterative | value | match | identical |
| `diff27-bar-3` | bar_plot | iterative | value | match | identical |
| `diff27-firth` | logis_firth | iterative | value | match | identical |
| `diff27-firth-exact` | test | iterative | value | match | identical |
| `diff27-firth-sm` | SM_output | iterative | value | match | identical |
| `diff27-firth-gamma-score` | confint | root | value | match | identical |
| `diff28-fit` | logis_fe | iterative | value | match | identical |
| `diff28-fit-ban` | logis_fe | iterative | value | match | identical |
| `diff28-fit-all` | logis_fe | iterative | value | match | identical |
| `diff28-exact-two.sided` | test | iterative | value | match | identical |
| `diff28-score-two.sided` | test | iterative | value | match | identical |
| `diff28-exact-greater` | test | iterative | value | match | identical |
| `diff28-score-greater` | test | iterative | value | match | identical |
| `diff28-exact-less` | test | iterative | value | match | identical |
| `diff28-score-less` | test | iterative | value | match | identical |
| `diff28-bootstrap` | test | iterative | value | match | identical |
| `diff28-score-standard` | test | iterative | value | match | identical |
| `diff28-wald` | test | iterative | value | match | identical |
| `diff28-exact-parm` | test | iterative | value | match | identical |
| `diff28-sm` | SM_output | iterative | value | match | identical |
| `diff28-sm-null0` | SM_output | iterative | value | match | identical |
| `diff28-gamma-exact` | confint | root | value | match | identical |
| `diff28-sm-exact` | confint | root | value | match | identical |
| `diff28-gamma-score` | confint | root | value | match | identical |
| `diff28-sm-score` | confint | root | value | match | identical |
| `diff28-gamma-wald` | confint | iterative | value | match | identical |
| `diff28-sm-wald` | confint | iterative | value | match | identical |
| `diff28-sm-score-greater` | confint | root | value | match | identical |
| `diff28-sm-exact-less` | confint | root | value | match | identical |
| `diff28-summary-wald` | summary | iterative | value | match | identical |
| `diff28-summary-lr` | summary | iterative | value | match | identical |
| `diff28-summary-score` | summary | iterative | value | match | identical |
| `diff28-plot` | plot | iterative | value | match | identical |
| `diff28-plot-null` | plot | iterative | value | match | identical |
| `diff28-caterpillar` | caterpillar_plot | iterative | value | match | identical |
| `diff28-caterpillar-flags` | caterpillar_plot | iterative | value | match | identical |
| `diff28-caterpillar-one-sided` | caterpillar_plot | root | value | match | identical |
| `diff28-bar` | bar_plot | iterative | value | match | identical |
| `diff28-bar-3` | bar_plot | iterative | value | match | identical |
| `diff28-firth` | logis_firth | iterative | value | match | identical |
| `diff28-firth-exact` | test | iterative | value | match | identical |
| `diff28-firth-sm` | SM_output | iterative | value | match | identical |
| `diff28-firth-gamma-score` | confint | root | value | match | identical |
| `diff29-fit` | logis_fe | iterative | value | match | within tolerance: AUC |
| `diff29-fit-ban` | logis_fe | iterative | value | match | within tolerance: AUC |
| `diff29-fit-all` | logis_fe | iterative | value | match | within tolerance: AUC |
| `diff29-exact-two.sided` | test | iterative | value | match | identical |
| `diff29-score-two.sided` | test | iterative | value | match | identical |
| `diff29-exact-greater` | test | iterative | value | match | identical |
| `diff29-score-greater` | test | iterative | value | match | identical |
| `diff29-exact-less` | test | iterative | value | match | identical |
| `diff29-score-less` | test | iterative | value | match | identical |
| `diff29-bootstrap` | test | iterative | value | match | identical |
| `diff29-score-standard` | test | iterative | value | match | identical |
| `diff29-wald` | test | iterative | value | match | identical |
| `diff29-exact-parm` | test | iterative | value | match | identical |
| `diff29-sm` | SM_output | iterative | value | match | identical |
| `diff29-sm-null0` | SM_output | iterative | value | match | identical |
| `diff29-gamma-exact` | confint | root | value | match | identical |
| `diff29-sm-exact` | confint | root | value | match | identical |
| `diff29-gamma-score` | confint | root | value | match | identical |
| `diff29-sm-score` | confint | root | value | match | identical |
| `diff29-gamma-wald` | confint | iterative | value | match | identical |
| `diff29-sm-wald` | confint | iterative | value | match | identical |
| `diff29-sm-score-greater` | confint | root | value | match | identical |
| `diff29-sm-exact-less` | confint | root | value | match | identical |
| `diff29-summary-wald` | summary | iterative | value | match | identical |
| `diff29-summary-lr` | summary | iterative | value | match | identical |
| `diff29-summary-score` | summary | iterative | value | match | identical |
| `diff29-plot` | plot | iterative | value | match | identical |
| `diff29-plot-null` | plot | iterative | value | match | identical |
| `diff29-caterpillar` | caterpillar_plot | iterative | value | match | identical |
| `diff29-caterpillar-flags` | caterpillar_plot | iterative | value | match | identical |
| `diff29-caterpillar-one-sided` | caterpillar_plot | root | value | match | identical |
| `diff29-bar` | bar_plot | iterative | value | match | identical |
| `diff29-bar-3` | bar_plot | iterative | value | match | identical |
| `diff29-firth` | logis_firth | iterative | value | match | identical |
| `diff29-firth-exact` | test | iterative | value | match | identical |
| `diff29-firth-sm` | SM_output | iterative | value | match | identical |
| `diff29-firth-gamma-score` | confint | root | value | match | identical |
| `diff30-fit` | logis_fe | iterative | value | match | identical |
| `diff30-fit-ban` | logis_fe | iterative | value | match | identical |
| `diff30-fit-all` | logis_fe | iterative | value | match | identical |
| `diff30-exact-two.sided` | test | iterative | value | match | identical |
| `diff30-score-two.sided` | test | iterative | value | match | identical |
| `diff30-exact-greater` | test | iterative | value | match | identical |
| `diff30-score-greater` | test | iterative | value | match | identical |
| `diff30-exact-less` | test | iterative | value | match | identical |
| `diff30-score-less` | test | iterative | value | match | identical |
| `diff30-bootstrap` | test | iterative | value | match | identical |
| `diff30-score-standard` | test | iterative | value | match | identical |
| `diff30-wald` | test | iterative | value | match | identical |
| `diff30-exact-parm` | test | iterative | value | match | identical |
| `diff30-sm` | SM_output | iterative | value | match | identical |
| `diff30-sm-null0` | SM_output | iterative | value | match | identical |
| `diff30-gamma-exact` | confint | root | value | match | identical |
| `diff30-sm-exact` | confint | root | value | match | identical |
| `diff30-gamma-score` | confint | root | value | match | identical |
| `diff30-sm-score` | confint | root | value | match | identical |
| `diff30-gamma-wald` | confint | iterative | value | match | identical |
| `diff30-sm-wald` | confint | iterative | value | match | identical |
| `diff30-sm-score-greater` | confint | root | value | match | identical |
| `diff30-sm-exact-less` | confint | root | value | match | identical |
| `diff30-summary-wald` | summary | iterative | value | match | identical |
| `diff30-summary-lr` | summary | iterative | value | match | identical |
| `diff30-summary-score` | summary | iterative | value | match | identical |
| `diff30-plot` | plot | iterative | value | match | identical |
| `diff30-plot-null` | plot | iterative | value | match | identical |
| `diff30-caterpillar` | caterpillar_plot | iterative | value | match | identical |
| `diff30-caterpillar-flags` | caterpillar_plot | iterative | value | match | identical |
| `diff30-caterpillar-one-sided` | caterpillar_plot | root | value | match | identical |
| `diff30-bar` | bar_plot | iterative | value | match | identical |
| `diff30-bar-3` | bar_plot | iterative | value | match | identical |
| `diff30-firth` | logis_firth | iterative | value | match | identical |
| `diff30-firth-exact` | test | iterative | value | match | identical |
| `diff30-firth-sm` | SM_output | iterative | value | match | identical |
| `diff30-firth-gamma-score` | confint | root | value | match | identical |
| `diff01-logis-re` | logis_re | lme4 | value | match | identical |
| `diff01-logis-cre` | logis_cre | lme4 | value | match | identical |
| `diff01-logis-re-test` | test | lme4 | value | match | identical |
| `diff01-logis-re-sm` | SM_output | lme4 | value | match | identical |
| `diff01-logis-re-confint` | confint | lme4 | value | match | identical |
| `diff01-logis-re-summary` | summary | lme4 | value | match | identical |
| `diff01-logis-re-test-greater` | test | lme4 | value | match | identical |
| `diff01-logis-re-confint-greater` | confint | lme4 | value | match | identical |
| `diff01-logis-re-test-less` | test | lme4 | value | match | identical |
| `diff01-logis-re-confint-less` | confint | lme4 | value | match | identical |
| `diff01-logis-re-test-null-parm` | test | lme4 | value | match | identical |
| `diff01-logis-re-sm-parm` | SM_output | lme4 | value | match | identical |
| `diff01-logis-re-confint-level-parm` | confint | lme4 | value | match | identical |
| `diff01-logis-re-confint-alpha` | confint | lme4 | value | match | identical |
| `diff01-logis-re-confint-alpha-greater` | confint | lme4 | error | match |  |
| `diff01-logis-re-summary-parm` | summary | lme4 | value | match | identical |
| `diff01-logis-re-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `diff01-logis-re-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `diff01-logis-re-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `diff01-logis-re-bar` | bar_plot | lme4 | value | match | identical |
| `diff01-logis-re-bar-3` | bar_plot | lme4 | value | match | identical |
| `diff01-logis-cre-test` | test | lme4 | value | match | identical |
| `diff01-logis-cre-sm` | SM_output | lme4 | value | match | identical |
| `diff01-logis-cre-confint` | confint | lme4 | value | match | identical |
| `diff01-logis-cre-summary` | summary | lme4 | value | match | identical |
| `diff01-logis-cre-test-greater` | test | lme4 | value | match | identical |
| `diff01-logis-cre-confint-greater` | confint | lme4 | value | match | identical |
| `diff01-logis-cre-test-less` | test | lme4 | value | match | identical |
| `diff01-logis-cre-confint-less` | confint | lme4 | value | match | identical |
| `diff01-logis-cre-test-null-parm` | test | lme4 | value | match | identical |
| `diff01-logis-cre-sm-parm` | SM_output | lme4 | value | match | identical |
| `diff01-logis-cre-confint-level-parm` | confint | lme4 | value | match | identical |
| `diff01-logis-cre-confint-alpha` | confint | lme4 | value | match | identical |
| `diff01-logis-cre-confint-alpha-greater` | confint | lme4 | error | match |  |
| `diff01-logis-cre-summary-parm` | summary | lme4 | value | match | identical |
| `diff01-logis-cre-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `diff01-logis-cre-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `diff01-logis-cre-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `diff01-logis-cre-bar` | bar_plot | lme4 | value | match | identical |
| `diff01-logis-cre-bar-3` | bar_plot | lme4 | value | match | identical |
| `diff02-logis-re` | logis_re | lme4 | value | match | identical |
| `diff02-logis-cre` | logis_cre | lme4 | value | match | identical |
| `diff02-logis-re-test` | test | lme4 | value | match | identical |
| `diff02-logis-re-sm` | SM_output | lme4 | value | match | identical |
| `diff02-logis-re-confint` | confint | lme4 | value | match | identical |
| `diff02-logis-re-summary` | summary | lme4 | value | match | identical |
| `diff02-logis-re-test-greater` | test | lme4 | value | match | identical |
| `diff02-logis-re-confint-greater` | confint | lme4 | value | match | identical |
| `diff02-logis-re-test-less` | test | lme4 | value | match | identical |
| `diff02-logis-re-confint-less` | confint | lme4 | value | match | identical |
| `diff02-logis-re-test-null-parm` | test | lme4 | value | match | identical |
| `diff02-logis-re-sm-parm` | SM_output | lme4 | value | match | identical |
| `diff02-logis-re-confint-level-parm` | confint | lme4 | value | match | identical |
| `diff02-logis-re-confint-alpha` | confint | lme4 | value | match | identical |
| `diff02-logis-re-confint-alpha-greater` | confint | lme4 | error | match |  |
| `diff02-logis-re-summary-parm` | summary | lme4 | value | match | identical |
| `diff02-logis-re-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `diff02-logis-re-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `diff02-logis-re-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `diff02-logis-re-bar` | bar_plot | lme4 | value | match | identical |
| `diff02-logis-re-bar-3` | bar_plot | lme4 | value | match | identical |
| `diff02-logis-cre-test` | test | lme4 | value | match | identical |
| `diff02-logis-cre-sm` | SM_output | lme4 | value | match | identical |
| `diff02-logis-cre-confint` | confint | lme4 | value | match | identical |
| `diff02-logis-cre-summary` | summary | lme4 | value | match | identical |
| `diff02-logis-cre-test-greater` | test | lme4 | value | match | identical |
| `diff02-logis-cre-confint-greater` | confint | lme4 | value | match | identical |
| `diff02-logis-cre-test-less` | test | lme4 | value | match | identical |
| `diff02-logis-cre-confint-less` | confint | lme4 | value | match | identical |
| `diff02-logis-cre-test-null-parm` | test | lme4 | value | match | identical |
| `diff02-logis-cre-sm-parm` | SM_output | lme4 | value | match | identical |
| `diff02-logis-cre-confint-level-parm` | confint | lme4 | value | match | identical |
| `diff02-logis-cre-confint-alpha` | confint | lme4 | value | match | identical |
| `diff02-logis-cre-confint-alpha-greater` | confint | lme4 | error | match |  |
| `diff02-logis-cre-summary-parm` | summary | lme4 | value | match | identical |
| `diff02-logis-cre-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `diff02-logis-cre-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `diff02-logis-cre-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `diff02-logis-cre-bar` | bar_plot | lme4 | value | match | identical |
| `diff02-logis-cre-bar-3` | bar_plot | lme4 | value | match | identical |
| `diff03-logis-re` | logis_re | lme4 | value | match | identical |
| `diff03-logis-cre` | logis_cre | lme4 | value | match | identical |
| `diff03-logis-re-test` | test | lme4 | value | match | identical |
| `diff03-logis-re-sm` | SM_output | lme4 | value | match | identical |
| `diff03-logis-re-confint` | confint | lme4 | value | match | identical |
| `diff03-logis-re-summary` | summary | lme4 | value | match | identical |
| `diff03-logis-re-test-greater` | test | lme4 | value | match | identical |
| `diff03-logis-re-confint-greater` | confint | lme4 | value | match | identical |
| `diff03-logis-re-test-less` | test | lme4 | value | match | identical |
| `diff03-logis-re-confint-less` | confint | lme4 | value | match | identical |
| `diff03-logis-re-test-null-parm` | test | lme4 | value | match | identical |
| `diff03-logis-re-sm-parm` | SM_output | lme4 | value | match | identical |
| `diff03-logis-re-confint-level-parm` | confint | lme4 | value | match | identical |
| `diff03-logis-re-confint-alpha` | confint | lme4 | value | match | identical |
| `diff03-logis-re-confint-alpha-greater` | confint | lme4 | error | match |  |
| `diff03-logis-re-summary-parm` | summary | lme4 | value | match | identical |
| `diff03-logis-re-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `diff03-logis-re-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `diff03-logis-re-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `diff03-logis-re-bar` | bar_plot | lme4 | value | match | identical |
| `diff03-logis-re-bar-3` | bar_plot | lme4 | value | match | identical |
| `diff03-logis-cre-test` | test | lme4 | value | match | identical |
| `diff03-logis-cre-sm` | SM_output | lme4 | value | match | identical |
| `diff03-logis-cre-confint` | confint | lme4 | value | match | identical |
| `diff03-logis-cre-summary` | summary | lme4 | value | match | identical |
| `diff03-logis-cre-test-greater` | test | lme4 | value | match | identical |
| `diff03-logis-cre-confint-greater` | confint | lme4 | value | match | identical |
| `diff03-logis-cre-test-less` | test | lme4 | value | match | identical |
| `diff03-logis-cre-confint-less` | confint | lme4 | value | match | identical |
| `diff03-logis-cre-test-null-parm` | test | lme4 | value | match | identical |
| `diff03-logis-cre-sm-parm` | SM_output | lme4 | value | match | identical |
| `diff03-logis-cre-confint-level-parm` | confint | lme4 | value | match | identical |
| `diff03-logis-cre-confint-alpha` | confint | lme4 | value | match | identical |
| `diff03-logis-cre-confint-alpha-greater` | confint | lme4 | error | match |  |
| `diff03-logis-cre-summary-parm` | summary | lme4 | value | match | identical |
| `diff03-logis-cre-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `diff03-logis-cre-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `diff03-logis-cre-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `diff03-logis-cre-bar` | bar_plot | lme4 | value | match | identical |
| `diff03-logis-cre-bar-3` | bar_plot | lme4 | value | match | identical |
| `diff04-logis-re` | logis_re | lme4 | value | match | identical |
| `diff04-logis-cre` | logis_cre | lme4 | value | match | identical |
| `diff04-logis-re-test` | test | lme4 | value | match | identical |
| `diff04-logis-re-sm` | SM_output | lme4 | value | match | identical |
| `diff04-logis-re-confint` | confint | lme4 | value | match | identical |
| `diff04-logis-re-summary` | summary | lme4 | value | match | identical |
| `diff04-logis-re-test-greater` | test | lme4 | value | match | identical |
| `diff04-logis-re-confint-greater` | confint | lme4 | value | match | identical |
| `diff04-logis-re-test-less` | test | lme4 | value | match | identical |
| `diff04-logis-re-confint-less` | confint | lme4 | value | match | identical |
| `diff04-logis-re-test-null-parm` | test | lme4 | value | match | identical |
| `diff04-logis-re-sm-parm` | SM_output | lme4 | value | match | identical |
| `diff04-logis-re-confint-level-parm` | confint | lme4 | value | match | identical |
| `diff04-logis-re-confint-alpha` | confint | lme4 | value | match | identical |
| `diff04-logis-re-confint-alpha-greater` | confint | lme4 | error | match |  |
| `diff04-logis-re-summary-parm` | summary | lme4 | value | match | identical |
| `diff04-logis-re-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `diff04-logis-re-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `diff04-logis-re-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `diff04-logis-re-bar` | bar_plot | lme4 | value | match | identical |
| `diff04-logis-re-bar-3` | bar_plot | lme4 | value | match | identical |
| `diff04-logis-cre-test` | test | lme4 | value | match | identical |
| `diff04-logis-cre-sm` | SM_output | lme4 | value | match | identical |
| `diff04-logis-cre-confint` | confint | lme4 | value | match | identical |
| `diff04-logis-cre-summary` | summary | lme4 | value | match | identical |
| `diff04-logis-cre-test-greater` | test | lme4 | value | match | identical |
| `diff04-logis-cre-confint-greater` | confint | lme4 | value | match | identical |
| `diff04-logis-cre-test-less` | test | lme4 | value | match | identical |
| `diff04-logis-cre-confint-less` | confint | lme4 | value | match | identical |
| `diff04-logis-cre-test-null-parm` | test | lme4 | value | match | identical |
| `diff04-logis-cre-sm-parm` | SM_output | lme4 | value | match | identical |
| `diff04-logis-cre-confint-level-parm` | confint | lme4 | value | match | identical |
| `diff04-logis-cre-confint-alpha` | confint | lme4 | value | match | identical |
| `diff04-logis-cre-confint-alpha-greater` | confint | lme4 | error | match |  |
| `diff04-logis-cre-summary-parm` | summary | lme4 | value | match | identical |
| `diff04-logis-cre-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `diff04-logis-cre-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `diff04-logis-cre-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `diff04-logis-cre-bar` | bar_plot | lme4 | value | match | identical |
| `diff04-logis-cre-bar-3` | bar_plot | lme4 | value | match | identical |
| `diff05-logis-re` | logis_re | lme4 | value | match | identical |
| `diff05-logis-cre` | logis_cre | lme4 | value | match | identical |
| `diff05-logis-re-test` | test | lme4 | value | match | identical |
| `diff05-logis-re-sm` | SM_output | lme4 | value | match | identical |
| `diff05-logis-re-confint` | confint | lme4 | value | match | identical |
| `diff05-logis-re-summary` | summary | lme4 | value | match | identical |
| `diff05-logis-re-test-greater` | test | lme4 | value | match | identical |
| `diff05-logis-re-confint-greater` | confint | lme4 | value | match | identical |
| `diff05-logis-re-test-less` | test | lme4 | value | match | identical |
| `diff05-logis-re-confint-less` | confint | lme4 | value | match | identical |
| `diff05-logis-re-test-null-parm` | test | lme4 | value | match | identical |
| `diff05-logis-re-sm-parm` | SM_output | lme4 | value | match | identical |
| `diff05-logis-re-confint-level-parm` | confint | lme4 | value | match | identical |
| `diff05-logis-re-confint-alpha` | confint | lme4 | value | match | identical |
| `diff05-logis-re-confint-alpha-greater` | confint | lme4 | error | match |  |
| `diff05-logis-re-summary-parm` | summary | lme4 | value | match | identical |
| `diff05-logis-re-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `diff05-logis-re-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `diff05-logis-re-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `diff05-logis-re-bar` | bar_plot | lme4 | value | match | identical |
| `diff05-logis-re-bar-3` | bar_plot | lme4 | value | match | identical |
| `diff05-logis-cre-test` | test | lme4 | value | match | identical |
| `diff05-logis-cre-sm` | SM_output | lme4 | value | match | identical |
| `diff05-logis-cre-confint` | confint | lme4 | value | match | identical |
| `diff05-logis-cre-summary` | summary | lme4 | value | match | identical |
| `diff05-logis-cre-test-greater` | test | lme4 | value | match | identical |
| `diff05-logis-cre-confint-greater` | confint | lme4 | value | match | identical |
| `diff05-logis-cre-test-less` | test | lme4 | value | match | identical |
| `diff05-logis-cre-confint-less` | confint | lme4 | value | match | identical |
| `diff05-logis-cre-test-null-parm` | test | lme4 | value | match | identical |
| `diff05-logis-cre-sm-parm` | SM_output | lme4 | value | match | identical |
| `diff05-logis-cre-confint-level-parm` | confint | lme4 | value | match | identical |
| `diff05-logis-cre-confint-alpha` | confint | lme4 | value | match | identical |
| `diff05-logis-cre-confint-alpha-greater` | confint | lme4 | error | match |  |
| `diff05-logis-cre-summary-parm` | summary | lme4 | value | match | identical |
| `diff05-logis-cre-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `diff05-logis-cre-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `diff05-logis-cre-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `diff05-logis-cre-bar` | bar_plot | lme4 | value | match | identical |
| `diff05-logis-cre-bar-3` | bar_plot | lme4 | value | match | identical |
| `diff06-logis-re` | logis_re | lme4 | value | match | identical |
| `diff06-logis-cre` | logis_cre | lme4 | value | match | identical |
| `diff06-logis-re-test` | test | lme4 | value | match | identical |
| `diff06-logis-re-sm` | SM_output | lme4 | value | match | identical |
| `diff06-logis-re-confint` | confint | lme4 | value | match | identical |
| `diff06-logis-re-summary` | summary | lme4 | value | match | identical |
| `diff06-logis-re-test-greater` | test | lme4 | value | match | identical |
| `diff06-logis-re-confint-greater` | confint | lme4 | value | match | identical |
| `diff06-logis-re-test-less` | test | lme4 | value | match | identical |
| `diff06-logis-re-confint-less` | confint | lme4 | value | match | identical |
| `diff06-logis-re-test-null-parm` | test | lme4 | value | match | identical |
| `diff06-logis-re-sm-parm` | SM_output | lme4 | value | match | identical |
| `diff06-logis-re-confint-level-parm` | confint | lme4 | value | match | identical |
| `diff06-logis-re-confint-alpha` | confint | lme4 | value | match | identical |
| `diff06-logis-re-confint-alpha-greater` | confint | lme4 | error | match |  |
| `diff06-logis-re-summary-parm` | summary | lme4 | value | match | identical |
| `diff06-logis-re-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `diff06-logis-re-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `diff06-logis-re-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `diff06-logis-re-bar` | bar_plot | lme4 | value | match | identical |
| `diff06-logis-re-bar-3` | bar_plot | lme4 | value | match | identical |
| `diff06-logis-cre-test` | test | lme4 | value | match | identical |
| `diff06-logis-cre-sm` | SM_output | lme4 | value | match | identical |
| `diff06-logis-cre-confint` | confint | lme4 | value | match | identical |
| `diff06-logis-cre-summary` | summary | lme4 | value | match | identical |
| `diff06-logis-cre-test-greater` | test | lme4 | value | match | identical |
| `diff06-logis-cre-confint-greater` | confint | lme4 | value | match | identical |
| `diff06-logis-cre-test-less` | test | lme4 | value | match | identical |
| `diff06-logis-cre-confint-less` | confint | lme4 | value | match | identical |
| `diff06-logis-cre-test-null-parm` | test | lme4 | value | match | identical |
| `diff06-logis-cre-sm-parm` | SM_output | lme4 | value | match | identical |
| `diff06-logis-cre-confint-level-parm` | confint | lme4 | value | match | identical |
| `diff06-logis-cre-confint-alpha` | confint | lme4 | value | match | identical |
| `diff06-logis-cre-confint-alpha-greater` | confint | lme4 | error | match |  |
| `diff06-logis-cre-summary-parm` | summary | lme4 | value | match | identical |
| `diff06-logis-cre-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `diff06-logis-cre-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `diff06-logis-cre-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `diff06-logis-cre-bar` | bar_plot | lme4 | value | match | identical |
| `diff06-logis-cre-bar-3` | bar_plot | lme4 | value | match | identical |
| `diff07-logis-re` | logis_re | lme4 | value | match | identical |
| `diff07-logis-cre` | logis_cre | lme4 | value | match | identical |
| `diff07-logis-re-test` | test | lme4 | value | match | identical |
| `diff07-logis-re-sm` | SM_output | lme4 | value | match | identical |
| `diff07-logis-re-confint` | confint | lme4 | value | match | identical |
| `diff07-logis-re-summary` | summary | lme4 | value | match | identical |
| `diff07-logis-re-test-greater` | test | lme4 | value | match | identical |
| `diff07-logis-re-confint-greater` | confint | lme4 | value | match | identical |
| `diff07-logis-re-test-less` | test | lme4 | value | match | identical |
| `diff07-logis-re-confint-less` | confint | lme4 | value | match | identical |
| `diff07-logis-re-test-null-parm` | test | lme4 | value | match | identical |
| `diff07-logis-re-sm-parm` | SM_output | lme4 | value | match | identical |
| `diff07-logis-re-confint-level-parm` | confint | lme4 | value | match | identical |
| `diff07-logis-re-confint-alpha` | confint | lme4 | value | match | identical |
| `diff07-logis-re-confint-alpha-greater` | confint | lme4 | error | match |  |
| `diff07-logis-re-summary-parm` | summary | lme4 | value | match | identical |
| `diff07-logis-re-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `diff07-logis-re-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `diff07-logis-re-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `diff07-logis-re-bar` | bar_plot | lme4 | value | match | identical |
| `diff07-logis-re-bar-3` | bar_plot | lme4 | value | match | identical |
| `diff07-logis-cre-test` | test | lme4 | value | match | identical |
| `diff07-logis-cre-sm` | SM_output | lme4 | value | match | identical |
| `diff07-logis-cre-confint` | confint | lme4 | value | match | identical |
| `diff07-logis-cre-summary` | summary | lme4 | value | match | identical |
| `diff07-logis-cre-test-greater` | test | lme4 | value | match | identical |
| `diff07-logis-cre-confint-greater` | confint | lme4 | value | match | identical |
| `diff07-logis-cre-test-less` | test | lme4 | value | match | identical |
| `diff07-logis-cre-confint-less` | confint | lme4 | value | match | identical |
| `diff07-logis-cre-test-null-parm` | test | lme4 | value | match | identical |
| `diff07-logis-cre-sm-parm` | SM_output | lme4 | value | match | identical |
| `diff07-logis-cre-confint-level-parm` | confint | lme4 | value | match | identical |
| `diff07-logis-cre-confint-alpha` | confint | lme4 | value | match | identical |
| `diff07-logis-cre-confint-alpha-greater` | confint | lme4 | error | match |  |
| `diff07-logis-cre-summary-parm` | summary | lme4 | value | match | identical |
| `diff07-logis-cre-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `diff07-logis-cre-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `diff07-logis-cre-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `diff07-logis-cre-bar` | bar_plot | lme4 | value | match | identical |
| `diff07-logis-cre-bar-3` | bar_plot | lme4 | value | match | identical |
| `diff08-logis-re` | logis_re | lme4 | value | match | identical |
| `diff08-logis-cre` | logis_cre | lme4 | value | match | identical |
| `diff08-logis-re-test` | test | lme4 | value | match | identical |
| `diff08-logis-re-sm` | SM_output | lme4 | value | match | identical |
| `diff08-logis-re-confint` | confint | lme4 | value | match | identical |
| `diff08-logis-re-summary` | summary | lme4 | value | match | identical |
| `diff08-logis-re-test-greater` | test | lme4 | value | match | identical |
| `diff08-logis-re-confint-greater` | confint | lme4 | value | match | identical |
| `diff08-logis-re-test-less` | test | lme4 | value | match | identical |
| `diff08-logis-re-confint-less` | confint | lme4 | value | match | identical |
| `diff08-logis-re-test-null-parm` | test | lme4 | value | match | identical |
| `diff08-logis-re-sm-parm` | SM_output | lme4 | value | match | identical |
| `diff08-logis-re-confint-level-parm` | confint | lme4 | value | match | identical |
| `diff08-logis-re-confint-alpha` | confint | lme4 | value | match | identical |
| `diff08-logis-re-confint-alpha-greater` | confint | lme4 | error | match |  |
| `diff08-logis-re-summary-parm` | summary | lme4 | value | match | identical |
| `diff08-logis-re-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `diff08-logis-re-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `diff08-logis-re-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `diff08-logis-re-bar` | bar_plot | lme4 | value | match | identical |
| `diff08-logis-re-bar-3` | bar_plot | lme4 | value | match | identical |
| `diff08-logis-cre-test` | test | lme4 | value | match | identical |
| `diff08-logis-cre-sm` | SM_output | lme4 | value | match | identical |
| `diff08-logis-cre-confint` | confint | lme4 | value | match | identical |
| `diff08-logis-cre-summary` | summary | lme4 | value | match | identical |
| `diff08-logis-cre-test-greater` | test | lme4 | value | match | identical |
| `diff08-logis-cre-confint-greater` | confint | lme4 | value | match | identical |
| `diff08-logis-cre-test-less` | test | lme4 | value | match | identical |
| `diff08-logis-cre-confint-less` | confint | lme4 | value | match | identical |
| `diff08-logis-cre-test-null-parm` | test | lme4 | value | match | identical |
| `diff08-logis-cre-sm-parm` | SM_output | lme4 | value | match | identical |
| `diff08-logis-cre-confint-level-parm` | confint | lme4 | value | match | identical |
| `diff08-logis-cre-confint-alpha` | confint | lme4 | value | match | identical |
| `diff08-logis-cre-confint-alpha-greater` | confint | lme4 | error | match |  |
| `diff08-logis-cre-summary-parm` | summary | lme4 | value | match | identical |
| `diff08-logis-cre-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `diff08-logis-cre-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `diff08-logis-cre-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `diff08-logis-cre-bar` | bar_plot | lme4 | value | match | identical |
| `diff08-logis-cre-bar-3` | bar_plot | lme4 | value | match | identical |
| `diff09-logis-re` | logis_re | lme4 | value | match | identical |
| `diff09-logis-cre` | logis_cre | lme4 | value | match | identical |
| `diff09-logis-re-test` | test | lme4 | value | match | identical |
| `diff09-logis-re-sm` | SM_output | lme4 | value | match | identical |
| `diff09-logis-re-confint` | confint | lme4 | value | match | identical |
| `diff09-logis-re-summary` | summary | lme4 | value | match | identical |
| `diff09-logis-re-test-greater` | test | lme4 | value | match | identical |
| `diff09-logis-re-confint-greater` | confint | lme4 | value | match | identical |
| `diff09-logis-re-test-less` | test | lme4 | value | match | identical |
| `diff09-logis-re-confint-less` | confint | lme4 | value | match | identical |
| `diff09-logis-re-test-null-parm` | test | lme4 | value | match | identical |
| `diff09-logis-re-sm-parm` | SM_output | lme4 | value | match | identical |
| `diff09-logis-re-confint-level-parm` | confint | lme4 | value | match | identical |
| `diff09-logis-re-confint-alpha` | confint | lme4 | value | match | identical |
| `diff09-logis-re-confint-alpha-greater` | confint | lme4 | error | match |  |
| `diff09-logis-re-summary-parm` | summary | lme4 | value | match | identical |
| `diff09-logis-re-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `diff09-logis-re-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `diff09-logis-re-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `diff09-logis-re-bar` | bar_plot | lme4 | value | match | identical |
| `diff09-logis-re-bar-3` | bar_plot | lme4 | value | match | identical |
| `diff09-logis-cre-test` | test | lme4 | value | match | identical |
| `diff09-logis-cre-sm` | SM_output | lme4 | value | match | identical |
| `diff09-logis-cre-confint` | confint | lme4 | value | match | identical |
| `diff09-logis-cre-summary` | summary | lme4 | value | match | identical |
| `diff09-logis-cre-test-greater` | test | lme4 | value | match | identical |
| `diff09-logis-cre-confint-greater` | confint | lme4 | value | match | identical |
| `diff09-logis-cre-test-less` | test | lme4 | value | match | identical |
| `diff09-logis-cre-confint-less` | confint | lme4 | value | match | identical |
| `diff09-logis-cre-test-null-parm` | test | lme4 | value | match | identical |
| `diff09-logis-cre-sm-parm` | SM_output | lme4 | value | match | identical |
| `diff09-logis-cre-confint-level-parm` | confint | lme4 | value | match | identical |
| `diff09-logis-cre-confint-alpha` | confint | lme4 | value | match | identical |
| `diff09-logis-cre-confint-alpha-greater` | confint | lme4 | error | match |  |
| `diff09-logis-cre-summary-parm` | summary | lme4 | value | match | identical |
| `diff09-logis-cre-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `diff09-logis-cre-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `diff09-logis-cre-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `diff09-logis-cre-bar` | bar_plot | lme4 | value | match | identical |
| `diff09-logis-cre-bar-3` | bar_plot | lme4 | value | match | identical |
| `diff10-logis-re` | logis_re | lme4 | value | match | identical |
| `diff10-logis-cre` | logis_cre | lme4 | value | match | identical |
| `diff10-logis-re-test` | test | lme4 | value | match | identical |
| `diff10-logis-re-sm` | SM_output | lme4 | value | match | identical |
| `diff10-logis-re-confint` | confint | lme4 | value | match | identical |
| `diff10-logis-re-summary` | summary | lme4 | value | match | identical |
| `diff10-logis-re-test-greater` | test | lme4 | value | match | identical |
| `diff10-logis-re-confint-greater` | confint | lme4 | value | match | identical |
| `diff10-logis-re-test-less` | test | lme4 | value | match | identical |
| `diff10-logis-re-confint-less` | confint | lme4 | value | match | identical |
| `diff10-logis-re-test-null-parm` | test | lme4 | value | match | identical |
| `diff10-logis-re-sm-parm` | SM_output | lme4 | value | match | identical |
| `diff10-logis-re-confint-level-parm` | confint | lme4 | value | match | identical |
| `diff10-logis-re-confint-alpha` | confint | lme4 | value | match | identical |
| `diff10-logis-re-confint-alpha-greater` | confint | lme4 | error | match |  |
| `diff10-logis-re-summary-parm` | summary | lme4 | value | match | identical |
| `diff10-logis-re-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `diff10-logis-re-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `diff10-logis-re-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `diff10-logis-re-bar` | bar_plot | lme4 | value | match | identical |
| `diff10-logis-re-bar-3` | bar_plot | lme4 | value | match | identical |
| `diff10-logis-cre-test` | test | lme4 | value | match | identical |
| `diff10-logis-cre-sm` | SM_output | lme4 | value | match | identical |
| `diff10-logis-cre-confint` | confint | lme4 | value | match | identical |
| `diff10-logis-cre-summary` | summary | lme4 | value | match | identical |
| `diff10-logis-cre-test-greater` | test | lme4 | value | match | identical |
| `diff10-logis-cre-confint-greater` | confint | lme4 | value | match | identical |
| `diff10-logis-cre-test-less` | test | lme4 | value | match | identical |
| `diff10-logis-cre-confint-less` | confint | lme4 | value | match | identical |
| `diff10-logis-cre-test-null-parm` | test | lme4 | value | match | identical |
| `diff10-logis-cre-sm-parm` | SM_output | lme4 | value | match | identical |
| `diff10-logis-cre-confint-level-parm` | confint | lme4 | value | match | identical |
| `diff10-logis-cre-confint-alpha` | confint | lme4 | value | match | identical |
| `diff10-logis-cre-confint-alpha-greater` | confint | lme4 | error | match |  |
| `diff10-logis-cre-summary-parm` | summary | lme4 | value | match | identical |
| `diff10-logis-cre-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `diff10-logis-cre-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `diff10-logis-cre-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `diff10-logis-cre-bar` | bar_plot | lme4 | value | match | identical |
| `diff10-logis-cre-bar-3` | bar_plot | lme4 | value | match | identical |
| `chr-diff01-logis-re` | logis_re | lme4 | value | match | identical |
| `chr-diff01-logis-cre` | logis_cre | lme4 | value | match | identical |
| `chr-diff01-logis-re-test` | test | lme4 | value | match | identical |
| `chr-diff01-logis-re-sm` | SM_output | lme4 | value | match | identical |
| `chr-diff01-logis-re-confint` | confint | lme4 | value | match | identical |
| `chr-diff01-logis-re-summary` | summary | lme4 | value | match | identical |
| `chr-diff01-logis-re-test-greater` | test | lme4 | value | match | identical |
| `chr-diff01-logis-re-confint-greater` | confint | lme4 | value | match | identical |
| `chr-diff01-logis-re-test-less` | test | lme4 | value | match | identical |
| `chr-diff01-logis-re-confint-less` | confint | lme4 | value | match | identical |
| `chr-diff01-logis-re-test-null-parm` | test | lme4 | value | match | identical |
| `chr-diff01-logis-re-sm-parm` | SM_output | lme4 | value | match | identical |
| `chr-diff01-logis-re-confint-level-parm` | confint | lme4 | value | match | identical |
| `chr-diff01-logis-re-confint-alpha` | confint | lme4 | value | match | identical |
| `chr-diff01-logis-re-confint-alpha-greater` | confint | lme4 | error | match |  |
| `chr-diff01-logis-re-summary-parm` | summary | lme4 | value | match | identical |
| `chr-diff01-logis-re-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `chr-diff01-logis-re-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `chr-diff01-logis-re-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `chr-diff01-logis-re-bar` | bar_plot | lme4 | value | match | identical |
| `chr-diff01-logis-re-bar-3` | bar_plot | lme4 | value | match | identical |
| `chr-diff01-logis-cre-test` | test | lme4 | value | match | identical |
| `chr-diff01-logis-cre-sm` | SM_output | lme4 | value | match | identical |
| `chr-diff01-logis-cre-confint` | confint | lme4 | value | match | identical |
| `chr-diff01-logis-cre-summary` | summary | lme4 | value | match | identical |
| `chr-diff01-logis-cre-test-greater` | test | lme4 | value | match | identical |
| `chr-diff01-logis-cre-confint-greater` | confint | lme4 | value | match | identical |
| `chr-diff01-logis-cre-test-less` | test | lme4 | value | match | identical |
| `chr-diff01-logis-cre-confint-less` | confint | lme4 | value | match | identical |
| `chr-diff01-logis-cre-test-null-parm` | test | lme4 | value | match | identical |
| `chr-diff01-logis-cre-sm-parm` | SM_output | lme4 | value | match | identical |
| `chr-diff01-logis-cre-confint-level-parm` | confint | lme4 | value | match | identical |
| `chr-diff01-logis-cre-confint-alpha` | confint | lme4 | value | match | identical |
| `chr-diff01-logis-cre-confint-alpha-greater` | confint | lme4 | error | match |  |
| `chr-diff01-logis-cre-summary-parm` | summary | lme4 | value | match | identical |
| `chr-diff01-logis-cre-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `chr-diff01-logis-cre-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `chr-diff01-logis-cre-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `chr-diff01-logis-cre-bar` | bar_plot | lme4 | value | match | identical |
| `chr-diff01-logis-cre-bar-3` | bar_plot | lme4 | value | match | identical |
| `chr-diff02-logis-re` | logis_re | lme4 | value | match | identical |
| `chr-diff02-logis-cre` | logis_cre | lme4 | value | match | identical |
| `chr-diff02-logis-re-test` | test | lme4 | value | match | identical |
| `chr-diff02-logis-re-sm` | SM_output | lme4 | value | match | identical |
| `chr-diff02-logis-re-confint` | confint | lme4 | value | match | identical |
| `chr-diff02-logis-re-summary` | summary | lme4 | value | match | identical |
| `chr-diff02-logis-re-test-greater` | test | lme4 | value | match | identical |
| `chr-diff02-logis-re-confint-greater` | confint | lme4 | value | match | identical |
| `chr-diff02-logis-re-test-less` | test | lme4 | value | match | identical |
| `chr-diff02-logis-re-confint-less` | confint | lme4 | value | match | identical |
| `chr-diff02-logis-re-test-null-parm` | test | lme4 | value | match | identical |
| `chr-diff02-logis-re-sm-parm` | SM_output | lme4 | value | match | identical |
| `chr-diff02-logis-re-confint-level-parm` | confint | lme4 | value | match | identical |
| `chr-diff02-logis-re-confint-alpha` | confint | lme4 | value | match | identical |
| `chr-diff02-logis-re-confint-alpha-greater` | confint | lme4 | error | match |  |
| `chr-diff02-logis-re-summary-parm` | summary | lme4 | value | match | identical |
| `chr-diff02-logis-re-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `chr-diff02-logis-re-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `chr-diff02-logis-re-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `chr-diff02-logis-re-bar` | bar_plot | lme4 | value | match | identical |
| `chr-diff02-logis-re-bar-3` | bar_plot | lme4 | value | match | identical |
| `chr-diff02-logis-cre-test` | test | lme4 | value | match | identical |
| `chr-diff02-logis-cre-sm` | SM_output | lme4 | value | match | identical |
| `chr-diff02-logis-cre-confint` | confint | lme4 | value | match | identical |
| `chr-diff02-logis-cre-summary` | summary | lme4 | value | match | identical |
| `chr-diff02-logis-cre-test-greater` | test | lme4 | value | match | identical |
| `chr-diff02-logis-cre-confint-greater` | confint | lme4 | value | match | identical |
| `chr-diff02-logis-cre-test-less` | test | lme4 | value | match | identical |
| `chr-diff02-logis-cre-confint-less` | confint | lme4 | value | match | identical |
| `chr-diff02-logis-cre-test-null-parm` | test | lme4 | value | match | identical |
| `chr-diff02-logis-cre-sm-parm` | SM_output | lme4 | value | match | identical |
| `chr-diff02-logis-cre-confint-level-parm` | confint | lme4 | value | match | identical |
| `chr-diff02-logis-cre-confint-alpha` | confint | lme4 | value | match | identical |
| `chr-diff02-logis-cre-confint-alpha-greater` | confint | lme4 | error | match |  |
| `chr-diff02-logis-cre-summary-parm` | summary | lme4 | value | match | identical |
| `chr-diff02-logis-cre-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `chr-diff02-logis-cre-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `chr-diff02-logis-cre-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `chr-diff02-logis-cre-bar` | bar_plot | lme4 | value | match | identical |
| `chr-diff02-logis-cre-bar-3` | bar_plot | lme4 | value | match | identical |
| `chr-diff03-logis-re` | logis_re | lme4 | value | match | identical |
| `chr-diff03-logis-cre` | logis_cre | lme4 | value | match | identical |
| `chr-diff03-logis-re-test` | test | lme4 | value | match | identical |
| `chr-diff03-logis-re-sm` | SM_output | lme4 | value | match | identical |
| `chr-diff03-logis-re-confint` | confint | lme4 | value | match | identical |
| `chr-diff03-logis-re-summary` | summary | lme4 | value | match | identical |
| `chr-diff03-logis-re-test-greater` | test | lme4 | value | match | identical |
| `chr-diff03-logis-re-confint-greater` | confint | lme4 | value | match | identical |
| `chr-diff03-logis-re-test-less` | test | lme4 | value | match | identical |
| `chr-diff03-logis-re-confint-less` | confint | lme4 | value | match | identical |
| `chr-diff03-logis-re-test-null-parm` | test | lme4 | value | match | identical |
| `chr-diff03-logis-re-sm-parm` | SM_output | lme4 | value | match | identical |
| `chr-diff03-logis-re-confint-level-parm` | confint | lme4 | value | match | identical |
| `chr-diff03-logis-re-confint-alpha` | confint | lme4 | value | match | identical |
| `chr-diff03-logis-re-confint-alpha-greater` | confint | lme4 | error | match |  |
| `chr-diff03-logis-re-summary-parm` | summary | lme4 | value | match | identical |
| `chr-diff03-logis-re-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `chr-diff03-logis-re-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `chr-diff03-logis-re-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `chr-diff03-logis-re-bar` | bar_plot | lme4 | value | match | identical |
| `chr-diff03-logis-re-bar-3` | bar_plot | lme4 | value | match | identical |
| `chr-diff03-logis-cre-test` | test | lme4 | value | match | identical |
| `chr-diff03-logis-cre-sm` | SM_output | lme4 | value | match | identical |
| `chr-diff03-logis-cre-confint` | confint | lme4 | value | match | identical |
| `chr-diff03-logis-cre-summary` | summary | lme4 | value | match | identical |
| `chr-diff03-logis-cre-test-greater` | test | lme4 | value | match | identical |
| `chr-diff03-logis-cre-confint-greater` | confint | lme4 | value | match | identical |
| `chr-diff03-logis-cre-test-less` | test | lme4 | value | match | identical |
| `chr-diff03-logis-cre-confint-less` | confint | lme4 | value | match | identical |
| `chr-diff03-logis-cre-test-null-parm` | test | lme4 | value | match | identical |
| `chr-diff03-logis-cre-sm-parm` | SM_output | lme4 | value | match | identical |
| `chr-diff03-logis-cre-confint-level-parm` | confint | lme4 | value | match | identical |
| `chr-diff03-logis-cre-confint-alpha` | confint | lme4 | value | match | identical |
| `chr-diff03-logis-cre-confint-alpha-greater` | confint | lme4 | error | match |  |
| `chr-diff03-logis-cre-summary-parm` | summary | lme4 | value | match | identical |
| `chr-diff03-logis-cre-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `chr-diff03-logis-cre-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `chr-diff03-logis-cre-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `chr-diff03-logis-cre-bar` | bar_plot | lme4 | value | match | identical |
| `chr-diff03-logis-cre-bar-3` | bar_plot | lme4 | value | match | identical |
| `null-diff01-logis-re` | logis_re | lme4 | value | match | identical |
| `null-diff01-logis-cre` | logis_cre | lme4 | value | match | identical |
| `null-diff01-logis-re-test` | test | lme4 | value | match | identical |
| `null-diff01-logis-re-sm` | SM_output | lme4 | value | match | identical |
| `null-diff01-logis-re-confint` | confint | lme4 | value | match | identical |
| `null-diff01-logis-re-summary` | summary | lme4 | value | match | identical |
| `null-diff01-logis-re-test-greater` | test | lme4 | value | match | identical |
| `null-diff01-logis-re-confint-greater` | confint | lme4 | value | match | identical |
| `null-diff01-logis-re-test-less` | test | lme4 | value | match | identical |
| `null-diff01-logis-re-confint-less` | confint | lme4 | value | match | identical |
| `null-diff01-logis-re-test-null-parm` | test | lme4 | value | match | identical |
| `null-diff01-logis-re-sm-parm` | SM_output | lme4 | value | match | identical |
| `null-diff01-logis-re-confint-level-parm` | confint | lme4 | value | match | identical |
| `null-diff01-logis-re-confint-alpha` | confint | lme4 | value | match | identical |
| `null-diff01-logis-re-confint-alpha-greater` | confint | lme4 | error | match |  |
| `null-diff01-logis-re-summary-parm` | summary | lme4 | value | match | identical |
| `null-diff01-logis-re-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `null-diff01-logis-re-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `null-diff01-logis-re-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `null-diff01-logis-re-bar` | bar_plot | lme4 | value | match | identical |
| `null-diff01-logis-re-bar-3` | bar_plot | lme4 | value | match | identical |
| `null-diff01-logis-cre-test` | test | lme4 | value | match | identical |
| `null-diff01-logis-cre-sm` | SM_output | lme4 | value | match | identical |
| `null-diff01-logis-cre-confint` | confint | lme4 | value | match | identical |
| `null-diff01-logis-cre-summary` | summary | lme4 | value | match | identical |
| `null-diff01-logis-cre-test-greater` | test | lme4 | value | match | identical |
| `null-diff01-logis-cre-confint-greater` | confint | lme4 | value | match | identical |
| `null-diff01-logis-cre-test-less` | test | lme4 | value | match | identical |
| `null-diff01-logis-cre-confint-less` | confint | lme4 | value | match | identical |
| `null-diff01-logis-cre-test-null-parm` | test | lme4 | value | match | identical |
| `null-diff01-logis-cre-sm-parm` | SM_output | lme4 | value | match | identical |
| `null-diff01-logis-cre-confint-level-parm` | confint | lme4 | value | match | identical |
| `null-diff01-logis-cre-confint-alpha` | confint | lme4 | value | match | identical |
| `null-diff01-logis-cre-confint-alpha-greater` | confint | lme4 | error | match |  |
| `null-diff01-logis-cre-summary-parm` | summary | lme4 | value | match | identical |
| `null-diff01-logis-cre-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `null-diff01-logis-cre-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `null-diff01-logis-cre-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `null-diff01-logis-cre-bar` | bar_plot | lme4 | value | match | identical |
| `null-diff01-logis-cre-bar-3` | bar_plot | lme4 | value | match | identical |
| `null-diff02-logis-re` | logis_re | lme4 | value | match | identical |
| `null-diff02-logis-cre` | logis_cre | lme4 | value | match | identical |
| `null-diff02-logis-re-test` | test | lme4 | value | match | identical |
| `null-diff02-logis-re-sm` | SM_output | lme4 | value | match | identical |
| `null-diff02-logis-re-confint` | confint | lme4 | value | match | identical |
| `null-diff02-logis-re-summary` | summary | lme4 | value | match | identical |
| `null-diff02-logis-re-test-greater` | test | lme4 | value | match | identical |
| `null-diff02-logis-re-confint-greater` | confint | lme4 | value | match | identical |
| `null-diff02-logis-re-test-less` | test | lme4 | value | match | identical |
| `null-diff02-logis-re-confint-less` | confint | lme4 | value | match | identical |
| `null-diff02-logis-re-test-null-parm` | test | lme4 | value | match | identical |
| `null-diff02-logis-re-sm-parm` | SM_output | lme4 | value | match | identical |
| `null-diff02-logis-re-confint-level-parm` | confint | lme4 | value | match | identical |
| `null-diff02-logis-re-confint-alpha` | confint | lme4 | value | match | identical |
| `null-diff02-logis-re-confint-alpha-greater` | confint | lme4 | error | match |  |
| `null-diff02-logis-re-summary-parm` | summary | lme4 | value | match | identical |
| `null-diff02-logis-re-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `null-diff02-logis-re-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `null-diff02-logis-re-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `null-diff02-logis-re-bar` | bar_plot | lme4 | value | match | identical |
| `null-diff02-logis-re-bar-3` | bar_plot | lme4 | value | match | identical |
| `null-diff02-logis-cre-test` | test | lme4 | value | match | identical |
| `null-diff02-logis-cre-sm` | SM_output | lme4 | value | match | identical |
| `null-diff02-logis-cre-confint` | confint | lme4 | value | match | identical |
| `null-diff02-logis-cre-summary` | summary | lme4 | value | match | identical |
| `null-diff02-logis-cre-test-greater` | test | lme4 | value | match | identical |
| `null-diff02-logis-cre-confint-greater` | confint | lme4 | value | match | identical |
| `null-diff02-logis-cre-test-less` | test | lme4 | value | match | identical |
| `null-diff02-logis-cre-confint-less` | confint | lme4 | value | match | identical |
| `null-diff02-logis-cre-test-null-parm` | test | lme4 | value | match | identical |
| `null-diff02-logis-cre-sm-parm` | SM_output | lme4 | value | match | identical |
| `null-diff02-logis-cre-confint-level-parm` | confint | lme4 | value | match | identical |
| `null-diff02-logis-cre-confint-alpha` | confint | lme4 | value | match | identical |
| `null-diff02-logis-cre-confint-alpha-greater` | confint | lme4 | error | match |  |
| `null-diff02-logis-cre-summary-parm` | summary | lme4 | value | match | identical |
| `null-diff02-logis-cre-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `null-diff02-logis-cre-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `null-diff02-logis-cre-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `null-diff02-logis-cre-bar` | bar_plot | lme4 | value | match | identical |
| `null-diff02-logis-cre-bar-3` | bar_plot | lme4 | value | match | identical |
| `lin01-fe` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, fitted, residuals, linear_pred |
| `lin01-fe-full` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, variance$gamma, fitted, residuals, linear_pred |
| `lin01-fe-test` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin01-fe-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin01-fe-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin01-fe-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin01-fe-test-greater` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin01-fe-confint-greater` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.direct$Direct.Difference, CI.direct$direct.Lower |
| `lin01-fe-test-less` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin01-fe-confint-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin01-fe-test-mean-parm` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin01-fe-test-null` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin01-fe-sm-null-parm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin01-fe-sm-mean` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin01-fe-confint-gamma` | confint | closed_form | value | match | within tolerance: $gamma, $gamma.Lower, $gamma.Upper |
| `lin01-fe-confint-mean-parm` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin01-fe-confint-null-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin01-fe-summary-parm` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin01-fe-plot` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin01-fe-plot-mean` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin01-fe-plot-null` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin01-fe-caterpillar` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin01-fe-caterpillar-flags` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin01-fe-caterpillar-one-sided` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower |
| `lin01-fe-bar` | bar_plot | closed_form | value | match | identical |
| `lin01-fe-bar-3` | bar_plot | closed_form | value | match | identical |
| `lin01-fe-full-test` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin01-fe-full-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin01-fe-full-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin01-fe-full-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin01-fe-full-test-greater` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin01-fe-full-confint-greater` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.direct$Direct.Difference, CI.direct$direct.Lower |
| `lin01-fe-full-test-less` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin01-fe-full-confint-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin01-fe-full-test-mean-parm` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin01-fe-full-test-null` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin01-fe-full-sm-null-parm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin01-fe-full-sm-mean` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin01-fe-full-confint-gamma` | confint | closed_form | value | match | within tolerance: $gamma, $gamma.Lower, $gamma.Upper |
| `lin01-fe-full-confint-mean-parm` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin01-fe-full-confint-null-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin01-fe-full-summary-parm` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin01-fe-full-plot` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin01-fe-full-plot-mean` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin01-fe-full-plot-null` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin01-fe-full-caterpillar` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin01-fe-full-caterpillar-flags` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin01-fe-full-caterpillar-one-sided` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower |
| `lin01-fe-full-bar` | bar_plot | closed_form | value | match | identical |
| `lin01-fe-full-bar-3` | bar_plot | closed_form | value | match | identical |
| `lin01-re` | linear_re | lme4 | value | match | identical |
| `lin01-cre` | linear_cre | lme4 | value | match | identical |
| `lin01-re-test` | test | lme4 | value | match | identical |
| `lin01-re-sm` | SM_output | lme4 | value | match | identical |
| `lin01-re-confint` | confint | lme4 | value | match | identical |
| `lin01-re-summary` | summary | lme4 | value | match | identical |
| `lin01-re-test-greater` | test | lme4 | value | match | identical |
| `lin01-re-confint-greater` | confint | lme4 | value | match | identical |
| `lin01-re-test-less` | test | lme4 | value | match | identical |
| `lin01-re-confint-less` | confint | lme4 | value | match | identical |
| `lin01-re-test-null-parm` | test | lme4 | value | match | identical |
| `lin01-re-sm-parm` | SM_output | lme4 | value | match | identical |
| `lin01-re-confint-level-parm` | confint | lme4 | value | match | identical |
| `lin01-re-confint-alpha` | confint | lme4 | value | match | identical |
| `lin01-re-confint-alpha-greater` | confint | lme4 | error | match |  |
| `lin01-re-summary-parm` | summary | lme4 | value | match | identical |
| `lin01-re-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `lin01-re-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `lin01-re-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `lin01-re-bar` | bar_plot | lme4 | value | match | identical |
| `lin01-re-bar-3` | bar_plot | lme4 | value | match | identical |
| `lin01-cre-test` | test | lme4 | value | match | identical |
| `lin01-cre-sm` | SM_output | lme4 | value | match | identical |
| `lin01-cre-confint` | confint | lme4 | value | match | identical |
| `lin01-cre-summary` | summary | lme4 | value | match | identical |
| `lin01-cre-test-greater` | test | lme4 | value | match | identical |
| `lin01-cre-confint-greater` | confint | lme4 | value | match | identical |
| `lin01-cre-test-less` | test | lme4 | value | match | identical |
| `lin01-cre-confint-less` | confint | lme4 | value | match | identical |
| `lin01-cre-test-null-parm` | test | lme4 | value | match | identical |
| `lin01-cre-sm-parm` | SM_output | lme4 | value | match | identical |
| `lin01-cre-confint-level-parm` | confint | lme4 | value | match | identical |
| `lin01-cre-confint-alpha` | confint | lme4 | value | match | identical |
| `lin01-cre-confint-alpha-greater` | confint | lme4 | error | match |  |
| `lin01-cre-summary-parm` | summary | lme4 | value | match | identical |
| `lin01-cre-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `lin01-cre-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `lin01-cre-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `lin01-cre-bar` | bar_plot | lme4 | value | match | identical |
| `lin01-cre-bar-3` | bar_plot | lme4 | value | match | identical |
| `lin02-fe` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, fitted, residuals, linear_pred |
| `lin02-fe-full` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, fitted, residuals, linear_pred |
| `lin02-fe-test` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin02-fe-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `lin02-fe-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin02-fe-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin02-fe-test-greater` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin02-fe-confint-greater` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.direct$Direct.Difference, CI.direct$direct.Lower |
| `lin02-fe-test-less` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin02-fe-confint-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin02-fe-test-mean-parm` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin02-fe-test-null` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin02-fe-sm-null-parm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin02-fe-sm-mean` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin02-fe-confint-gamma` | confint | closed_form | value | match | within tolerance: $gamma, $gamma.Lower, $gamma.Upper |
| `lin02-fe-confint-mean-parm` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin02-fe-confint-null-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin02-fe-summary-parm` | summary | closed_form | value | match | within tolerance: $Estimate, $Stat, $CI.Lower, $CI.Upper |
| `lin02-fe-plot` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin02-fe-plot-mean` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin02-fe-plot-null` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin02-fe-caterpillar` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin02-fe-caterpillar-flags` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin02-fe-caterpillar-one-sided` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower |
| `lin02-fe-bar` | bar_plot | closed_form | value | match | identical |
| `lin02-fe-bar-3` | bar_plot | closed_form | value | match | identical |
| `lin02-fe-full-test` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin02-fe-full-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `lin02-fe-full-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin02-fe-full-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin02-fe-full-test-greater` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin02-fe-full-confint-greater` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.direct$Direct.Difference, CI.direct$direct.Lower |
| `lin02-fe-full-test-less` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin02-fe-full-confint-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin02-fe-full-test-mean-parm` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin02-fe-full-test-null` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin02-fe-full-sm-null-parm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin02-fe-full-sm-mean` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin02-fe-full-confint-gamma` | confint | closed_form | value | match | within tolerance: $gamma, $gamma.Lower, $gamma.Upper |
| `lin02-fe-full-confint-mean-parm` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin02-fe-full-confint-null-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin02-fe-full-summary-parm` | summary | closed_form | value | match | within tolerance: $Estimate, $Stat, $CI.Lower, $CI.Upper |
| `lin02-fe-full-plot` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin02-fe-full-plot-mean` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin02-fe-full-plot-null` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin02-fe-full-caterpillar` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin02-fe-full-caterpillar-flags` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin02-fe-full-caterpillar-one-sided` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower |
| `lin02-fe-full-bar` | bar_plot | closed_form | value | match | identical |
| `lin02-fe-full-bar-3` | bar_plot | closed_form | value | match | identical |
| `lin02-re` | linear_re | lme4 | value | match | identical |
| `lin02-cre` | linear_cre | lme4 | value | match | identical |
| `lin02-re-test` | test | lme4 | value | match | identical |
| `lin02-re-sm` | SM_output | lme4 | value | match | identical |
| `lin02-re-confint` | confint | lme4 | value | match | identical |
| `lin02-re-summary` | summary | lme4 | value | match | identical |
| `lin02-re-test-greater` | test | lme4 | value | match | identical |
| `lin02-re-confint-greater` | confint | lme4 | value | match | identical |
| `lin02-re-test-less` | test | lme4 | value | match | identical |
| `lin02-re-confint-less` | confint | lme4 | value | match | identical |
| `lin02-re-test-null-parm` | test | lme4 | value | match | identical |
| `lin02-re-sm-parm` | SM_output | lme4 | value | match | identical |
| `lin02-re-confint-level-parm` | confint | lme4 | value | match | identical |
| `lin02-re-confint-alpha` | confint | lme4 | value | match | identical |
| `lin02-re-confint-alpha-greater` | confint | lme4 | error | match |  |
| `lin02-re-summary-parm` | summary | lme4 | value | match | identical |
| `lin02-re-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `lin02-re-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `lin02-re-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `lin02-re-bar` | bar_plot | lme4 | value | match | identical |
| `lin02-re-bar-3` | bar_plot | lme4 | value | match | identical |
| `lin02-cre-test` | test | lme4 | value | match | identical |
| `lin02-cre-sm` | SM_output | lme4 | value | match | identical |
| `lin02-cre-confint` | confint | lme4 | value | match | identical |
| `lin02-cre-summary` | summary | lme4 | value | match | identical |
| `lin02-cre-test-greater` | test | lme4 | value | match | identical |
| `lin02-cre-confint-greater` | confint | lme4 | value | match | identical |
| `lin02-cre-test-less` | test | lme4 | value | match | identical |
| `lin02-cre-confint-less` | confint | lme4 | value | match | identical |
| `lin02-cre-test-null-parm` | test | lme4 | value | match | identical |
| `lin02-cre-sm-parm` | SM_output | lme4 | value | match | identical |
| `lin02-cre-confint-level-parm` | confint | lme4 | value | match | identical |
| `lin02-cre-confint-alpha` | confint | lme4 | value | match | identical |
| `lin02-cre-confint-alpha-greater` | confint | lme4 | error | match |  |
| `lin02-cre-summary-parm` | summary | lme4 | value | match | identical |
| `lin02-cre-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `lin02-cre-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `lin02-cre-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `lin02-cre-bar` | bar_plot | lme4 | value | match | identical |
| `lin02-cre-bar-3` | bar_plot | lme4 | value | match | identical |
| `lin03-fe` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, fitted, residuals, linear_pred |
| `lin03-fe-full` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, variance$gamma, fitted, residuals, linear_pred |
| `lin03-fe-test` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin03-fe-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `lin03-fe-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin03-fe-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin03-fe-test-greater` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin03-fe-confint-greater` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.direct$Direct.Difference, CI.direct$direct.Lower |
| `lin03-fe-test-less` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin03-fe-confint-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin03-fe-test-mean-parm` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin03-fe-test-null` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin03-fe-sm-null-parm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin03-fe-sm-mean` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin03-fe-confint-gamma` | confint | closed_form | value | match | within tolerance: $gamma, $gamma.Lower, $gamma.Upper |
| `lin03-fe-confint-mean-parm` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin03-fe-confint-null-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin03-fe-summary-parm` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin03-fe-plot` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin03-fe-plot-mean` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin03-fe-plot-null` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin03-fe-caterpillar` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin03-fe-caterpillar-flags` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin03-fe-caterpillar-one-sided` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower |
| `lin03-fe-bar` | bar_plot | closed_form | value | match | identical |
| `lin03-fe-bar-3` | bar_plot | closed_form | value | match | identical |
| `lin03-fe-full-test` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin03-fe-full-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `lin03-fe-full-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin03-fe-full-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin03-fe-full-test-greater` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin03-fe-full-confint-greater` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.direct$Direct.Difference, CI.direct$direct.Lower |
| `lin03-fe-full-test-less` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin03-fe-full-confint-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin03-fe-full-test-mean-parm` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin03-fe-full-test-null` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin03-fe-full-sm-null-parm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin03-fe-full-sm-mean` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin03-fe-full-confint-gamma` | confint | closed_form | value | match | within tolerance: $gamma, $gamma.Lower, $gamma.Upper |
| `lin03-fe-full-confint-mean-parm` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin03-fe-full-confint-null-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin03-fe-full-summary-parm` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin03-fe-full-plot` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin03-fe-full-plot-mean` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin03-fe-full-plot-null` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin03-fe-full-caterpillar` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin03-fe-full-caterpillar-flags` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin03-fe-full-caterpillar-one-sided` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower |
| `lin03-fe-full-bar` | bar_plot | closed_form | value | match | identical |
| `lin03-fe-full-bar-3` | bar_plot | closed_form | value | match | identical |
| `lin03-re` | linear_re | lme4 | value | match | identical |
| `lin03-cre` | linear_cre | lme4 | value | match | identical |
| `lin03-re-test` | test | lme4 | value | match | identical |
| `lin03-re-sm` | SM_output | lme4 | value | match | identical |
| `lin03-re-confint` | confint | lme4 | value | match | identical |
| `lin03-re-summary` | summary | lme4 | value | match | identical |
| `lin03-re-test-greater` | test | lme4 | value | match | identical |
| `lin03-re-confint-greater` | confint | lme4 | value | match | identical |
| `lin03-re-test-less` | test | lme4 | value | match | identical |
| `lin03-re-confint-less` | confint | lme4 | value | match | identical |
| `lin03-re-test-null-parm` | test | lme4 | value | match | identical |
| `lin03-re-sm-parm` | SM_output | lme4 | value | match | identical |
| `lin03-re-confint-level-parm` | confint | lme4 | value | match | identical |
| `lin03-re-confint-alpha` | confint | lme4 | value | match | identical |
| `lin03-re-confint-alpha-greater` | confint | lme4 | error | match |  |
| `lin03-re-summary-parm` | summary | lme4 | value | match | identical |
| `lin03-re-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `lin03-re-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `lin03-re-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `lin03-re-bar` | bar_plot | lme4 | value | match | identical |
| `lin03-re-bar-3` | bar_plot | lme4 | value | match | identical |
| `lin03-cre-test` | test | lme4 | value | match | identical |
| `lin03-cre-sm` | SM_output | lme4 | value | match | identical |
| `lin03-cre-confint` | confint | lme4 | value | match | identical |
| `lin03-cre-summary` | summary | lme4 | value | match | identical |
| `lin03-cre-test-greater` | test | lme4 | value | match | identical |
| `lin03-cre-confint-greater` | confint | lme4 | value | match | identical |
| `lin03-cre-test-less` | test | lme4 | value | match | identical |
| `lin03-cre-confint-less` | confint | lme4 | value | match | identical |
| `lin03-cre-test-null-parm` | test | lme4 | value | match | identical |
| `lin03-cre-sm-parm` | SM_output | lme4 | value | match | identical |
| `lin03-cre-confint-level-parm` | confint | lme4 | value | match | identical |
| `lin03-cre-confint-alpha` | confint | lme4 | value | match | identical |
| `lin03-cre-confint-alpha-greater` | confint | lme4 | error | match |  |
| `lin03-cre-summary-parm` | summary | lme4 | value | match | identical |
| `lin03-cre-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `lin03-cre-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `lin03-cre-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `lin03-cre-bar` | bar_plot | lme4 | value | match | identical |
| `lin03-cre-bar-3` | bar_plot | lme4 | value | match | identical |
| `lin04-fe` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, fitted, residuals, linear_pred |
| `lin04-fe-full` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, variance$gamma, fitted, residuals, linear_pred |
| `lin04-fe-test` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin04-fe-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin04-fe-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin04-fe-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin04-fe-test-greater` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin04-fe-confint-greater` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.direct$Direct.Difference, CI.direct$direct.Lower |
| `lin04-fe-test-less` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin04-fe-confint-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin04-fe-test-mean-parm` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin04-fe-test-null` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin04-fe-sm-null-parm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `lin04-fe-sm-mean` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `lin04-fe-confint-gamma` | confint | closed_form | value | match | within tolerance: $gamma, $gamma.Lower, $gamma.Upper |
| `lin04-fe-confint-mean-parm` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin04-fe-confint-null-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin04-fe-summary-parm` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin04-fe-plot` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin04-fe-plot-mean` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin04-fe-plot-null` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin04-fe-caterpillar` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin04-fe-caterpillar-flags` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin04-fe-caterpillar-one-sided` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower |
| `lin04-fe-bar` | bar_plot | closed_form | value | match | identical |
| `lin04-fe-bar-3` | bar_plot | closed_form | value | match | identical |
| `lin04-fe-full-test` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin04-fe-full-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin04-fe-full-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin04-fe-full-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin04-fe-full-test-greater` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin04-fe-full-confint-greater` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.direct$Direct.Difference, CI.direct$direct.Lower |
| `lin04-fe-full-test-less` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin04-fe-full-confint-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin04-fe-full-test-mean-parm` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin04-fe-full-test-null` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin04-fe-full-sm-null-parm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `lin04-fe-full-sm-mean` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `lin04-fe-full-confint-gamma` | confint | closed_form | value | match | within tolerance: $gamma, $gamma.Lower, $gamma.Upper |
| `lin04-fe-full-confint-mean-parm` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin04-fe-full-confint-null-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin04-fe-full-summary-parm` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin04-fe-full-plot` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin04-fe-full-plot-mean` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin04-fe-full-plot-null` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin04-fe-full-caterpillar` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin04-fe-full-caterpillar-flags` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin04-fe-full-caterpillar-one-sided` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower |
| `lin04-fe-full-bar` | bar_plot | closed_form | value | match | identical |
| `lin04-fe-full-bar-3` | bar_plot | closed_form | value | match | identical |
| `lin04-re` | linear_re | lme4 | value | match | identical |
| `lin04-cre` | linear_cre | lme4 | value | match | identical |
| `lin04-re-test` | test | lme4 | value | match | identical |
| `lin04-re-sm` | SM_output | lme4 | value | match | identical |
| `lin04-re-confint` | confint | lme4 | value | match | identical |
| `lin04-re-summary` | summary | lme4 | value | match | identical |
| `lin04-re-test-greater` | test | lme4 | value | match | identical |
| `lin04-re-confint-greater` | confint | lme4 | value | match | identical |
| `lin04-re-test-less` | test | lme4 | value | match | identical |
| `lin04-re-confint-less` | confint | lme4 | value | match | identical |
| `lin04-re-test-null-parm` | test | lme4 | value | match | identical |
| `lin04-re-sm-parm` | SM_output | lme4 | value | match | identical |
| `lin04-re-confint-level-parm` | confint | lme4 | value | match | identical |
| `lin04-re-confint-alpha` | confint | lme4 | value | match | identical |
| `lin04-re-confint-alpha-greater` | confint | lme4 | error | match |  |
| `lin04-re-summary-parm` | summary | lme4 | value | match | identical |
| `lin04-re-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `lin04-re-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `lin04-re-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `lin04-re-bar` | bar_plot | lme4 | value | match | identical |
| `lin04-re-bar-3` | bar_plot | lme4 | value | match | identical |
| `lin04-cre-test` | test | lme4 | value | match | identical |
| `lin04-cre-sm` | SM_output | lme4 | value | match | identical |
| `lin04-cre-confint` | confint | lme4 | value | match | identical |
| `lin04-cre-summary` | summary | lme4 | value | match | identical |
| `lin04-cre-test-greater` | test | lme4 | value | match | identical |
| `lin04-cre-confint-greater` | confint | lme4 | value | match | identical |
| `lin04-cre-test-less` | test | lme4 | value | match | identical |
| `lin04-cre-confint-less` | confint | lme4 | value | match | identical |
| `lin04-cre-test-null-parm` | test | lme4 | value | match | identical |
| `lin04-cre-sm-parm` | SM_output | lme4 | value | match | identical |
| `lin04-cre-confint-level-parm` | confint | lme4 | value | match | identical |
| `lin04-cre-confint-alpha` | confint | lme4 | value | match | identical |
| `lin04-cre-confint-alpha-greater` | confint | lme4 | error | match |  |
| `lin04-cre-summary-parm` | summary | lme4 | value | match | identical |
| `lin04-cre-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `lin04-cre-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `lin04-cre-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `lin04-cre-bar` | bar_plot | lme4 | value | match | identical |
| `lin04-cre-bar-3` | bar_plot | lme4 | value | match | identical |
| `lin05-fe` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, fitted, residuals, linear_pred |
| `lin05-fe-full` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, variance$gamma, fitted, residuals, linear_pred |
| `lin05-fe-test` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin05-fe-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin05-fe-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin05-fe-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin05-fe-test-greater` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin05-fe-confint-greater` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.direct$Direct.Difference, CI.direct$direct.Lower |
| `lin05-fe-test-less` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin05-fe-confint-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin05-fe-test-mean-parm` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin05-fe-test-null` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin05-fe-sm-null-parm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin05-fe-sm-mean` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin05-fe-confint-gamma` | confint | closed_form | value | match | within tolerance: $gamma, $gamma.Lower, $gamma.Upper |
| `lin05-fe-confint-mean-parm` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin05-fe-confint-null-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin05-fe-summary-parm` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin05-fe-plot` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin05-fe-plot-mean` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin05-fe-plot-null` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin05-fe-caterpillar` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin05-fe-caterpillar-flags` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin05-fe-caterpillar-one-sided` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower |
| `lin05-fe-bar` | bar_plot | closed_form | value | match | identical |
| `lin05-fe-bar-3` | bar_plot | closed_form | value | match | identical |
| `lin05-fe-full-test` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin05-fe-full-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin05-fe-full-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin05-fe-full-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin05-fe-full-test-greater` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin05-fe-full-confint-greater` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.direct$Direct.Difference, CI.direct$direct.Lower |
| `lin05-fe-full-test-less` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin05-fe-full-confint-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin05-fe-full-test-mean-parm` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin05-fe-full-test-null` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin05-fe-full-sm-null-parm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin05-fe-full-sm-mean` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin05-fe-full-confint-gamma` | confint | closed_form | value | match | within tolerance: $gamma, $gamma.Lower, $gamma.Upper |
| `lin05-fe-full-confint-mean-parm` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin05-fe-full-confint-null-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin05-fe-full-summary-parm` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin05-fe-full-plot` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin05-fe-full-plot-mean` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin05-fe-full-plot-null` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin05-fe-full-caterpillar` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin05-fe-full-caterpillar-flags` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin05-fe-full-caterpillar-one-sided` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower |
| `lin05-fe-full-bar` | bar_plot | closed_form | value | match | identical |
| `lin05-fe-full-bar-3` | bar_plot | closed_form | value | match | identical |
| `lin05-re` | linear_re | lme4 | value | match | identical |
| `lin05-cre` | linear_cre | lme4 | value | match | identical |
| `lin05-re-test` | test | lme4 | value | match | identical |
| `lin05-re-sm` | SM_output | lme4 | value | match | identical |
| `lin05-re-confint` | confint | lme4 | value | match | identical |
| `lin05-re-summary` | summary | lme4 | value | match | identical |
| `lin05-re-test-greater` | test | lme4 | value | match | identical |
| `lin05-re-confint-greater` | confint | lme4 | value | match | identical |
| `lin05-re-test-less` | test | lme4 | value | match | identical |
| `lin05-re-confint-less` | confint | lme4 | value | match | identical |
| `lin05-re-test-null-parm` | test | lme4 | value | match | identical |
| `lin05-re-sm-parm` | SM_output | lme4 | value | match | identical |
| `lin05-re-confint-level-parm` | confint | lme4 | value | match | identical |
| `lin05-re-confint-alpha` | confint | lme4 | value | match | identical |
| `lin05-re-confint-alpha-greater` | confint | lme4 | error | match |  |
| `lin05-re-summary-parm` | summary | lme4 | value | match | identical |
| `lin05-re-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `lin05-re-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `lin05-re-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `lin05-re-bar` | bar_plot | lme4 | value | match | identical |
| `lin05-re-bar-3` | bar_plot | lme4 | value | match | identical |
| `lin05-cre-test` | test | lme4 | value | match | identical |
| `lin05-cre-sm` | SM_output | lme4 | value | match | identical |
| `lin05-cre-confint` | confint | lme4 | value | match | identical |
| `lin05-cre-summary` | summary | lme4 | value | match | identical |
| `lin05-cre-test-greater` | test | lme4 | value | match | identical |
| `lin05-cre-confint-greater` | confint | lme4 | value | match | identical |
| `lin05-cre-test-less` | test | lme4 | value | match | identical |
| `lin05-cre-confint-less` | confint | lme4 | value | match | identical |
| `lin05-cre-test-null-parm` | test | lme4 | value | match | identical |
| `lin05-cre-sm-parm` | SM_output | lme4 | value | match | identical |
| `lin05-cre-confint-level-parm` | confint | lme4 | value | match | identical |
| `lin05-cre-confint-alpha` | confint | lme4 | value | match | identical |
| `lin05-cre-confint-alpha-greater` | confint | lme4 | error | match |  |
| `lin05-cre-summary-parm` | summary | lme4 | value | match | identical |
| `lin05-cre-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `lin05-cre-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `lin05-cre-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `lin05-cre-bar` | bar_plot | lme4 | value | match | identical |
| `lin05-cre-bar-3` | bar_plot | lme4 | value | match | identical |
| `lin06-fe` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, fitted, residuals, linear_pred |
| `lin06-fe-full` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, variance$gamma, fitted, residuals, linear_pred |
| `lin06-fe-test` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin06-fe-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `lin06-fe-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin06-fe-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin06-fe-test-greater` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin06-fe-confint-greater` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.direct$Direct.Difference, CI.direct$direct.Lower |
| `lin06-fe-test-less` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin06-fe-confint-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin06-fe-test-mean-parm` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin06-fe-test-null` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin06-fe-sm-null-parm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin06-fe-sm-mean` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `lin06-fe-confint-gamma` | confint | closed_form | value | match | within tolerance: $gamma, $gamma.Lower, $gamma.Upper |
| `lin06-fe-confint-mean-parm` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin06-fe-confint-null-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin06-fe-summary-parm` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin06-fe-plot` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin06-fe-plot-mean` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin06-fe-plot-null` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin06-fe-caterpillar` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin06-fe-caterpillar-flags` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin06-fe-caterpillar-one-sided` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower |
| `lin06-fe-bar` | bar_plot | closed_form | value | match | identical |
| `lin06-fe-bar-3` | bar_plot | closed_form | value | match | identical |
| `lin06-fe-full-test` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin06-fe-full-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `lin06-fe-full-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin06-fe-full-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin06-fe-full-test-greater` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin06-fe-full-confint-greater` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.direct$Direct.Difference, CI.direct$direct.Lower |
| `lin06-fe-full-test-less` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin06-fe-full-confint-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin06-fe-full-test-mean-parm` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin06-fe-full-test-null` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin06-fe-full-sm-null-parm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin06-fe-full-sm-mean` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `lin06-fe-full-confint-gamma` | confint | closed_form | value | match | within tolerance: $gamma, $gamma.Lower, $gamma.Upper |
| `lin06-fe-full-confint-mean-parm` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin06-fe-full-confint-null-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin06-fe-full-summary-parm` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin06-fe-full-plot` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin06-fe-full-plot-mean` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin06-fe-full-plot-null` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin06-fe-full-caterpillar` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin06-fe-full-caterpillar-flags` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin06-fe-full-caterpillar-one-sided` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower |
| `lin06-fe-full-bar` | bar_plot | closed_form | value | match | identical |
| `lin06-fe-full-bar-3` | bar_plot | closed_form | value | match | identical |
| `lin06-re` | linear_re | lme4 | value | match | identical |
| `lin06-cre` | linear_cre | lme4 | value | match | identical |
| `lin06-re-test` | test | lme4 | value | match | identical |
| `lin06-re-sm` | SM_output | lme4 | value | match | identical |
| `lin06-re-confint` | confint | lme4 | value | match | identical |
| `lin06-re-summary` | summary | lme4 | value | match | identical |
| `lin06-re-test-greater` | test | lme4 | value | match | identical |
| `lin06-re-confint-greater` | confint | lme4 | value | match | identical |
| `lin06-re-test-less` | test | lme4 | value | match | identical |
| `lin06-re-confint-less` | confint | lme4 | value | match | identical |
| `lin06-re-test-null-parm` | test | lme4 | value | match | identical |
| `lin06-re-sm-parm` | SM_output | lme4 | value | match | identical |
| `lin06-re-confint-level-parm` | confint | lme4 | value | match | identical |
| `lin06-re-confint-alpha` | confint | lme4 | value | match | identical |
| `lin06-re-confint-alpha-greater` | confint | lme4 | error | match |  |
| `lin06-re-summary-parm` | summary | lme4 | value | match | identical |
| `lin06-re-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `lin06-re-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `lin06-re-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `lin06-re-bar` | bar_plot | lme4 | value | match | identical |
| `lin06-re-bar-3` | bar_plot | lme4 | value | match | identical |
| `lin06-cre-test` | test | lme4 | value | match | identical |
| `lin06-cre-sm` | SM_output | lme4 | value | match | identical |
| `lin06-cre-confint` | confint | lme4 | value | match | identical |
| `lin06-cre-summary` | summary | lme4 | value | match | identical |
| `lin06-cre-test-greater` | test | lme4 | value | match | identical |
| `lin06-cre-confint-greater` | confint | lme4 | value | match | identical |
| `lin06-cre-test-less` | test | lme4 | value | match | identical |
| `lin06-cre-confint-less` | confint | lme4 | value | match | identical |
| `lin06-cre-test-null-parm` | test | lme4 | value | match | identical |
| `lin06-cre-sm-parm` | SM_output | lme4 | value | match | identical |
| `lin06-cre-confint-level-parm` | confint | lme4 | value | match | identical |
| `lin06-cre-confint-alpha` | confint | lme4 | value | match | identical |
| `lin06-cre-confint-alpha-greater` | confint | lme4 | error | match |  |
| `lin06-cre-summary-parm` | summary | lme4 | value | match | identical |
| `lin06-cre-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `lin06-cre-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `lin06-cre-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `lin06-cre-bar` | bar_plot | lme4 | value | match | identical |
| `lin06-cre-bar-3` | bar_plot | lme4 | value | match | identical |
| `lin07-fe` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, fitted, residuals, linear_pred |
| `lin07-fe-full` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, variance$gamma, fitted, residuals, linear_pred |
| `lin07-fe-test` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin07-fe-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `lin07-fe-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin07-fe-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin07-fe-test-greater` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin07-fe-confint-greater` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.direct$Direct.Difference, CI.direct$direct.Lower |
| `lin07-fe-test-less` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin07-fe-confint-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin07-fe-test-mean-parm` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin07-fe-test-null` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin07-fe-sm-null-parm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin07-fe-sm-mean` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `lin07-fe-confint-gamma` | confint | closed_form | value | match | within tolerance: $gamma, $gamma.Lower, $gamma.Upper |
| `lin07-fe-confint-mean-parm` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin07-fe-confint-null-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin07-fe-summary-parm` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin07-fe-plot` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin07-fe-plot-mean` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin07-fe-plot-null` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin07-fe-caterpillar` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin07-fe-caterpillar-flags` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin07-fe-caterpillar-one-sided` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower |
| `lin07-fe-bar` | bar_plot | closed_form | value | match | identical |
| `lin07-fe-bar-3` | bar_plot | closed_form | value | match | identical |
| `lin07-fe-full-test` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin07-fe-full-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `lin07-fe-full-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin07-fe-full-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin07-fe-full-test-greater` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin07-fe-full-confint-greater` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.direct$Direct.Difference, CI.direct$direct.Lower |
| `lin07-fe-full-test-less` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin07-fe-full-confint-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin07-fe-full-test-mean-parm` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin07-fe-full-test-null` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin07-fe-full-sm-null-parm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin07-fe-full-sm-mean` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `lin07-fe-full-confint-gamma` | confint | closed_form | value | match | within tolerance: $gamma, $gamma.Lower, $gamma.Upper |
| `lin07-fe-full-confint-mean-parm` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin07-fe-full-confint-null-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin07-fe-full-summary-parm` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin07-fe-full-plot` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin07-fe-full-plot-mean` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin07-fe-full-plot-null` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin07-fe-full-caterpillar` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin07-fe-full-caterpillar-flags` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin07-fe-full-caterpillar-one-sided` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower |
| `lin07-fe-full-bar` | bar_plot | closed_form | value | match | identical |
| `lin07-fe-full-bar-3` | bar_plot | closed_form | value | match | identical |
| `lin07-re` | linear_re | lme4 | value | match | identical |
| `lin07-cre` | linear_cre | lme4 | value | match | identical |
| `lin07-re-test` | test | lme4 | value | match | identical |
| `lin07-re-sm` | SM_output | lme4 | value | match | identical |
| `lin07-re-confint` | confint | lme4 | value | match | identical |
| `lin07-re-summary` | summary | lme4 | value | match | identical |
| `lin07-re-test-greater` | test | lme4 | value | match | identical |
| `lin07-re-confint-greater` | confint | lme4 | value | match | identical |
| `lin07-re-test-less` | test | lme4 | value | match | identical |
| `lin07-re-confint-less` | confint | lme4 | value | match | identical |
| `lin07-re-test-null-parm` | test | lme4 | value | match | identical |
| `lin07-re-sm-parm` | SM_output | lme4 | value | match | identical |
| `lin07-re-confint-level-parm` | confint | lme4 | value | match | identical |
| `lin07-re-confint-alpha` | confint | lme4 | value | match | identical |
| `lin07-re-confint-alpha-greater` | confint | lme4 | error | match |  |
| `lin07-re-summary-parm` | summary | lme4 | value | match | identical |
| `lin07-re-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `lin07-re-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `lin07-re-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `lin07-re-bar` | bar_plot | lme4 | value | match | identical |
| `lin07-re-bar-3` | bar_plot | lme4 | value | match | identical |
| `lin07-cre-test` | test | lme4 | value | match | identical |
| `lin07-cre-sm` | SM_output | lme4 | value | match | identical |
| `lin07-cre-confint` | confint | lme4 | value | match | identical |
| `lin07-cre-summary` | summary | lme4 | value | match | identical |
| `lin07-cre-test-greater` | test | lme4 | value | match | identical |
| `lin07-cre-confint-greater` | confint | lme4 | value | match | identical |
| `lin07-cre-test-less` | test | lme4 | value | match | identical |
| `lin07-cre-confint-less` | confint | lme4 | value | match | identical |
| `lin07-cre-test-null-parm` | test | lme4 | value | match | identical |
| `lin07-cre-sm-parm` | SM_output | lme4 | value | match | identical |
| `lin07-cre-confint-level-parm` | confint | lme4 | value | match | identical |
| `lin07-cre-confint-alpha` | confint | lme4 | value | match | identical |
| `lin07-cre-confint-alpha-greater` | confint | lme4 | error | match |  |
| `lin07-cre-summary-parm` | summary | lme4 | value | match | identical |
| `lin07-cre-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `lin07-cre-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `lin07-cre-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `lin07-cre-bar` | bar_plot | lme4 | value | match | identical |
| `lin07-cre-bar-3` | bar_plot | lme4 | value | match | identical |
| `lin08-fe` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, fitted, residuals, linear_pred |
| `lin08-fe-full` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, variance$gamma, fitted, residuals, linear_pred |
| `lin08-fe-test` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin08-fe-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin08-fe-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin08-fe-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin08-fe-test-greater` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin08-fe-confint-greater` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.direct$Direct.Difference, CI.direct$direct.Lower |
| `lin08-fe-test-less` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin08-fe-confint-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin08-fe-test-mean-parm` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin08-fe-test-null` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin08-fe-sm-null-parm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin08-fe-sm-mean` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `lin08-fe-confint-gamma` | confint | closed_form | value | match | within tolerance: $gamma, $gamma.Lower, $gamma.Upper |
| `lin08-fe-confint-mean-parm` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin08-fe-confint-null-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin08-fe-summary-parm` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin08-fe-plot` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin08-fe-plot-mean` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin08-fe-plot-null` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin08-fe-caterpillar` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin08-fe-caterpillar-flags` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin08-fe-caterpillar-one-sided` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower |
| `lin08-fe-bar` | bar_plot | closed_form | value | match | identical |
| `lin08-fe-bar-3` | bar_plot | closed_form | value | match | identical |
| `lin08-fe-full-test` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin08-fe-full-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin08-fe-full-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin08-fe-full-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin08-fe-full-test-greater` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin08-fe-full-confint-greater` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.direct$Direct.Difference, CI.direct$direct.Lower |
| `lin08-fe-full-test-less` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin08-fe-full-confint-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin08-fe-full-test-mean-parm` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin08-fe-full-test-null` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin08-fe-full-sm-null-parm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin08-fe-full-sm-mean` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `lin08-fe-full-confint-gamma` | confint | closed_form | value | match | within tolerance: $gamma, $gamma.Lower, $gamma.Upper |
| `lin08-fe-full-confint-mean-parm` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin08-fe-full-confint-null-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin08-fe-full-summary-parm` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin08-fe-full-plot` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin08-fe-full-plot-mean` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin08-fe-full-plot-null` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin08-fe-full-caterpillar` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin08-fe-full-caterpillar-flags` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin08-fe-full-caterpillar-one-sided` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower |
| `lin08-fe-full-bar` | bar_plot | closed_form | value | match | identical |
| `lin08-fe-full-bar-3` | bar_plot | closed_form | value | match | identical |
| `lin08-re` | linear_re | lme4 | value | match | identical |
| `lin08-cre` | linear_cre | lme4 | value | match | identical |
| `lin08-re-test` | test | lme4 | value | match | identical |
| `lin08-re-sm` | SM_output | lme4 | value | match | identical |
| `lin08-re-confint` | confint | lme4 | value | match | identical |
| `lin08-re-summary` | summary | lme4 | value | match | identical |
| `lin08-re-test-greater` | test | lme4 | value | match | identical |
| `lin08-re-confint-greater` | confint | lme4 | value | match | identical |
| `lin08-re-test-less` | test | lme4 | value | match | identical |
| `lin08-re-confint-less` | confint | lme4 | value | match | identical |
| `lin08-re-test-null-parm` | test | lme4 | value | match | identical |
| `lin08-re-sm-parm` | SM_output | lme4 | value | match | identical |
| `lin08-re-confint-level-parm` | confint | lme4 | value | match | identical |
| `lin08-re-confint-alpha` | confint | lme4 | value | match | identical |
| `lin08-re-confint-alpha-greater` | confint | lme4 | error | match |  |
| `lin08-re-summary-parm` | summary | lme4 | value | match | identical |
| `lin08-re-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `lin08-re-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `lin08-re-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `lin08-re-bar` | bar_plot | lme4 | value | match | identical |
| `lin08-re-bar-3` | bar_plot | lme4 | value | match | identical |
| `lin08-cre-test` | test | lme4 | value | match | identical |
| `lin08-cre-sm` | SM_output | lme4 | value | match | identical |
| `lin08-cre-confint` | confint | lme4 | value | match | identical |
| `lin08-cre-summary` | summary | lme4 | value | match | identical |
| `lin08-cre-test-greater` | test | lme4 | value | match | identical |
| `lin08-cre-confint-greater` | confint | lme4 | value | match | identical |
| `lin08-cre-test-less` | test | lme4 | value | match | identical |
| `lin08-cre-confint-less` | confint | lme4 | value | match | identical |
| `lin08-cre-test-null-parm` | test | lme4 | value | match | identical |
| `lin08-cre-sm-parm` | SM_output | lme4 | value | match | identical |
| `lin08-cre-confint-level-parm` | confint | lme4 | value | match | identical |
| `lin08-cre-confint-alpha` | confint | lme4 | value | match | identical |
| `lin08-cre-confint-alpha-greater` | confint | lme4 | error | match |  |
| `lin08-cre-summary-parm` | summary | lme4 | value | match | identical |
| `lin08-cre-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `lin08-cre-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `lin08-cre-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `lin08-cre-bar` | bar_plot | lme4 | value | match | identical |
| `lin08-cre-bar-3` | bar_plot | lme4 | value | match | identical |
| `lin09-fe` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, fitted, residuals, linear_pred |
| `lin09-fe-full` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, variance$gamma, fitted, residuals, linear_pred |
| `lin09-fe-test` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin09-fe-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin09-fe-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin09-fe-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin09-fe-test-greater` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin09-fe-confint-greater` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.direct$Direct.Difference, CI.direct$direct.Lower |
| `lin09-fe-test-less` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin09-fe-confint-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin09-fe-test-mean-parm` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin09-fe-test-null` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin09-fe-sm-null-parm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin09-fe-sm-mean` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `lin09-fe-confint-gamma` | confint | closed_form | value | match | within tolerance: $gamma, $gamma.Lower, $gamma.Upper |
| `lin09-fe-confint-mean-parm` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin09-fe-confint-null-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin09-fe-summary-parm` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin09-fe-plot` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin09-fe-plot-mean` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin09-fe-plot-null` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin09-fe-caterpillar` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin09-fe-caterpillar-flags` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin09-fe-caterpillar-one-sided` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower |
| `lin09-fe-bar` | bar_plot | closed_form | value | match | identical |
| `lin09-fe-bar-3` | bar_plot | closed_form | value | match | identical |
| `lin09-fe-full-test` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin09-fe-full-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin09-fe-full-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin09-fe-full-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin09-fe-full-test-greater` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin09-fe-full-confint-greater` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.direct$Direct.Difference, CI.direct$direct.Lower |
| `lin09-fe-full-test-less` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin09-fe-full-confint-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin09-fe-full-test-mean-parm` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin09-fe-full-test-null` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin09-fe-full-sm-null-parm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin09-fe-full-sm-mean` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `lin09-fe-full-confint-gamma` | confint | closed_form | value | match | within tolerance: $gamma, $gamma.Lower, $gamma.Upper |
| `lin09-fe-full-confint-mean-parm` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin09-fe-full-confint-null-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin09-fe-full-summary-parm` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin09-fe-full-plot` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin09-fe-full-plot-mean` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin09-fe-full-plot-null` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin09-fe-full-caterpillar` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin09-fe-full-caterpillar-flags` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin09-fe-full-caterpillar-one-sided` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower |
| `lin09-fe-full-bar` | bar_plot | closed_form | value | match | identical |
| `lin09-fe-full-bar-3` | bar_plot | closed_form | value | match | identical |
| `lin09-re` | linear_re | lme4 | value | match | identical |
| `lin09-cre` | linear_cre | lme4 | value | match | identical |
| `lin09-re-test` | test | lme4 | value | match | identical |
| `lin09-re-sm` | SM_output | lme4 | value | match | identical |
| `lin09-re-confint` | confint | lme4 | value | match | identical |
| `lin09-re-summary` | summary | lme4 | value | match | identical |
| `lin09-re-test-greater` | test | lme4 | value | match | identical |
| `lin09-re-confint-greater` | confint | lme4 | value | match | identical |
| `lin09-re-test-less` | test | lme4 | value | match | identical |
| `lin09-re-confint-less` | confint | lme4 | value | match | identical |
| `lin09-re-test-null-parm` | test | lme4 | value | match | identical |
| `lin09-re-sm-parm` | SM_output | lme4 | value | match | identical |
| `lin09-re-confint-level-parm` | confint | lme4 | value | match | identical |
| `lin09-re-confint-alpha` | confint | lme4 | value | match | identical |
| `lin09-re-confint-alpha-greater` | confint | lme4 | error | match |  |
| `lin09-re-summary-parm` | summary | lme4 | value | match | identical |
| `lin09-re-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `lin09-re-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `lin09-re-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `lin09-re-bar` | bar_plot | lme4 | value | match | identical |
| `lin09-re-bar-3` | bar_plot | lme4 | value | match | identical |
| `lin09-cre-test` | test | lme4 | value | match | identical |
| `lin09-cre-sm` | SM_output | lme4 | value | match | identical |
| `lin09-cre-confint` | confint | lme4 | value | match | identical |
| `lin09-cre-summary` | summary | lme4 | value | match | identical |
| `lin09-cre-test-greater` | test | lme4 | value | match | identical |
| `lin09-cre-confint-greater` | confint | lme4 | value | match | identical |
| `lin09-cre-test-less` | test | lme4 | value | match | identical |
| `lin09-cre-confint-less` | confint | lme4 | value | match | identical |
| `lin09-cre-test-null-parm` | test | lme4 | value | match | identical |
| `lin09-cre-sm-parm` | SM_output | lme4 | value | match | identical |
| `lin09-cre-confint-level-parm` | confint | lme4 | value | match | identical |
| `lin09-cre-confint-alpha` | confint | lme4 | value | match | identical |
| `lin09-cre-confint-alpha-greater` | confint | lme4 | error | match |  |
| `lin09-cre-summary-parm` | summary | lme4 | value | match | identical |
| `lin09-cre-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `lin09-cre-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `lin09-cre-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `lin09-cre-bar` | bar_plot | lme4 | value | match | identical |
| `lin09-cre-bar-3` | bar_plot | lme4 | value | match | identical |
| `lin10-fe` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, fitted, residuals, linear_pred |
| `lin10-fe-full` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, variance$gamma, fitted, residuals, linear_pred |
| `lin10-fe-test` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin10-fe-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin10-fe-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin10-fe-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin10-fe-test-greater` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin10-fe-confint-greater` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.direct$Direct.Difference, CI.direct$direct.Lower |
| `lin10-fe-test-less` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin10-fe-confint-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin10-fe-test-mean-parm` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin10-fe-test-null` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin10-fe-sm-null-parm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin10-fe-sm-mean` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `lin10-fe-confint-gamma` | confint | closed_form | value | match | within tolerance: $gamma, $gamma.Lower, $gamma.Upper |
| `lin10-fe-confint-mean-parm` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin10-fe-confint-null-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin10-fe-summary-parm` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin10-fe-plot` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin10-fe-plot-mean` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin10-fe-plot-null` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin10-fe-caterpillar` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin10-fe-caterpillar-flags` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin10-fe-caterpillar-one-sided` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower |
| `lin10-fe-bar` | bar_plot | closed_form | value | match | identical |
| `lin10-fe-bar-3` | bar_plot | closed_form | value | match | identical |
| `lin10-fe-full-test` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin10-fe-full-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin10-fe-full-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin10-fe-full-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin10-fe-full-test-greater` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin10-fe-full-confint-greater` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.direct$Direct.Difference, CI.direct$direct.Lower |
| `lin10-fe-full-test-less` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin10-fe-full-confint-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin10-fe-full-test-mean-parm` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin10-fe-full-test-null` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin10-fe-full-sm-null-parm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin10-fe-full-sm-mean` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `lin10-fe-full-confint-gamma` | confint | closed_form | value | match | within tolerance: $gamma, $gamma.Lower, $gamma.Upper |
| `lin10-fe-full-confint-mean-parm` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin10-fe-full-confint-null-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin10-fe-full-summary-parm` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin10-fe-full-plot` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin10-fe-full-plot-mean` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin10-fe-full-plot-null` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin10-fe-full-caterpillar` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin10-fe-full-caterpillar-flags` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin10-fe-full-caterpillar-one-sided` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower |
| `lin10-fe-full-bar` | bar_plot | closed_form | value | match | identical |
| `lin10-fe-full-bar-3` | bar_plot | closed_form | value | match | identical |
| `lin10-re` | linear_re | lme4 | value | match | identical |
| `lin10-cre` | linear_cre | lme4 | value | match | identical |
| `lin10-re-test` | test | lme4 | value | match | identical |
| `lin10-re-sm` | SM_output | lme4 | value | match | identical |
| `lin10-re-confint` | confint | lme4 | value | match | identical |
| `lin10-re-summary` | summary | lme4 | value | match | identical |
| `lin10-re-test-greater` | test | lme4 | value | match | identical |
| `lin10-re-confint-greater` | confint | lme4 | value | match | identical |
| `lin10-re-test-less` | test | lme4 | value | match | identical |
| `lin10-re-confint-less` | confint | lme4 | value | match | identical |
| `lin10-re-test-null-parm` | test | lme4 | value | match | identical |
| `lin10-re-sm-parm` | SM_output | lme4 | value | match | identical |
| `lin10-re-confint-level-parm` | confint | lme4 | value | match | identical |
| `lin10-re-confint-alpha` | confint | lme4 | value | match | identical |
| `lin10-re-confint-alpha-greater` | confint | lme4 | error | match |  |
| `lin10-re-summary-parm` | summary | lme4 | value | match | identical |
| `lin10-re-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `lin10-re-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `lin10-re-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `lin10-re-bar` | bar_plot | lme4 | value | match | identical |
| `lin10-re-bar-3` | bar_plot | lme4 | value | match | identical |
| `lin10-cre-test` | test | lme4 | value | match | identical |
| `lin10-cre-sm` | SM_output | lme4 | value | match | identical |
| `lin10-cre-confint` | confint | lme4 | value | match | identical |
| `lin10-cre-summary` | summary | lme4 | value | match | identical |
| `lin10-cre-test-greater` | test | lme4 | value | match | identical |
| `lin10-cre-confint-greater` | confint | lme4 | value | match | identical |
| `lin10-cre-test-less` | test | lme4 | value | match | identical |
| `lin10-cre-confint-less` | confint | lme4 | value | match | identical |
| `lin10-cre-test-null-parm` | test | lme4 | value | match | identical |
| `lin10-cre-sm-parm` | SM_output | lme4 | value | match | identical |
| `lin10-cre-confint-level-parm` | confint | lme4 | value | match | identical |
| `lin10-cre-confint-alpha` | confint | lme4 | value | match | identical |
| `lin10-cre-confint-alpha-greater` | confint | lme4 | error | match |  |
| `lin10-cre-summary-parm` | summary | lme4 | value | match | identical |
| `lin10-cre-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `lin10-cre-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `lin10-cre-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `lin10-cre-bar` | bar_plot | lme4 | value | match | identical |
| `lin10-cre-bar-3` | bar_plot | lme4 | value | match | identical |
| `lin11-fe` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, fitted, residuals, linear_pred |
| `lin11-fe-full` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, variance$gamma, fitted, residuals, linear_pred |
| `lin11-fe-test` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin11-fe-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin11-fe-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin11-fe-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin11-fe-test-greater` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin11-fe-confint-greater` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.direct$Direct.Difference, CI.direct$direct.Lower |
| `lin11-fe-test-less` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin11-fe-confint-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin11-fe-test-mean-parm` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin11-fe-test-null` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin11-fe-sm-null-parm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin11-fe-sm-mean` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `lin11-fe-confint-gamma` | confint | closed_form | value | match | within tolerance: $gamma, $gamma.Lower, $gamma.Upper |
| `lin11-fe-confint-mean-parm` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin11-fe-confint-null-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin11-fe-summary-parm` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin11-fe-plot` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin11-fe-plot-mean` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin11-fe-plot-null` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin11-fe-caterpillar` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin11-fe-caterpillar-flags` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin11-fe-caterpillar-one-sided` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower |
| `lin11-fe-bar` | bar_plot | closed_form | value | match | identical |
| `lin11-fe-bar-3` | bar_plot | closed_form | value | match | identical |
| `lin11-fe-full-test` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin11-fe-full-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin11-fe-full-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin11-fe-full-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin11-fe-full-test-greater` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin11-fe-full-confint-greater` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.direct$Direct.Difference, CI.direct$direct.Lower |
| `lin11-fe-full-test-less` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin11-fe-full-confint-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin11-fe-full-test-mean-parm` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin11-fe-full-test-null` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin11-fe-full-sm-null-parm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin11-fe-full-sm-mean` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `lin11-fe-full-confint-gamma` | confint | closed_form | value | match | within tolerance: $gamma, $gamma.Lower, $gamma.Upper |
| `lin11-fe-full-confint-mean-parm` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin11-fe-full-confint-null-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin11-fe-full-summary-parm` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin11-fe-full-plot` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin11-fe-full-plot-mean` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin11-fe-full-plot-null` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin11-fe-full-caterpillar` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin11-fe-full-caterpillar-flags` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin11-fe-full-caterpillar-one-sided` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower |
| `lin11-fe-full-bar` | bar_plot | closed_form | value | match | identical |
| `lin11-fe-full-bar-3` | bar_plot | closed_form | value | match | identical |
| `lin11-re` | linear_re | lme4 | value | match | identical |
| `lin11-cre` | linear_cre | lme4 | value | match | identical |
| `lin11-re-test` | test | lme4 | value | match | identical |
| `lin11-re-sm` | SM_output | lme4 | value | match | identical |
| `lin11-re-confint` | confint | lme4 | value | match | identical |
| `lin11-re-summary` | summary | lme4 | value | match | identical |
| `lin11-re-test-greater` | test | lme4 | value | match | identical |
| `lin11-re-confint-greater` | confint | lme4 | value | match | identical |
| `lin11-re-test-less` | test | lme4 | value | match | identical |
| `lin11-re-confint-less` | confint | lme4 | value | match | identical |
| `lin11-re-test-null-parm` | test | lme4 | value | match | identical |
| `lin11-re-sm-parm` | SM_output | lme4 | value | match | identical |
| `lin11-re-confint-level-parm` | confint | lme4 | value | match | identical |
| `lin11-re-confint-alpha` | confint | lme4 | value | match | identical |
| `lin11-re-confint-alpha-greater` | confint | lme4 | error | match |  |
| `lin11-re-summary-parm` | summary | lme4 | value | match | identical |
| `lin11-re-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `lin11-re-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `lin11-re-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `lin11-re-bar` | bar_plot | lme4 | value | match | identical |
| `lin11-re-bar-3` | bar_plot | lme4 | value | match | identical |
| `lin11-cre-test` | test | lme4 | value | match | identical |
| `lin11-cre-sm` | SM_output | lme4 | value | match | identical |
| `lin11-cre-confint` | confint | lme4 | value | match | identical |
| `lin11-cre-summary` | summary | lme4 | value | match | identical |
| `lin11-cre-test-greater` | test | lme4 | value | match | identical |
| `lin11-cre-confint-greater` | confint | lme4 | value | match | identical |
| `lin11-cre-test-less` | test | lme4 | value | match | identical |
| `lin11-cre-confint-less` | confint | lme4 | value | match | identical |
| `lin11-cre-test-null-parm` | test | lme4 | value | match | identical |
| `lin11-cre-sm-parm` | SM_output | lme4 | value | match | identical |
| `lin11-cre-confint-level-parm` | confint | lme4 | value | match | identical |
| `lin11-cre-confint-alpha` | confint | lme4 | value | match | identical |
| `lin11-cre-confint-alpha-greater` | confint | lme4 | error | match |  |
| `lin11-cre-summary-parm` | summary | lme4 | value | match | identical |
| `lin11-cre-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `lin11-cre-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `lin11-cre-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `lin11-cre-bar` | bar_plot | lme4 | value | match | identical |
| `lin11-cre-bar-3` | bar_plot | lme4 | value | match | identical |
| `lin12-fe` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, fitted, residuals, linear_pred |
| `lin12-fe-full` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, variance$gamma, fitted, residuals, linear_pred |
| `lin12-fe-test` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin12-fe-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin12-fe-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin12-fe-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin12-fe-test-greater` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin12-fe-confint-greater` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.direct$Direct.Difference, CI.direct$direct.Lower |
| `lin12-fe-test-less` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin12-fe-confint-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin12-fe-test-mean-parm` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin12-fe-test-null` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin12-fe-sm-null-parm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin12-fe-sm-mean` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin12-fe-confint-gamma` | confint | closed_form | value | match | within tolerance: $gamma, $gamma.Lower, $gamma.Upper |
| `lin12-fe-confint-mean-parm` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin12-fe-confint-null-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin12-fe-summary-parm` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin12-fe-plot` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin12-fe-plot-mean` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin12-fe-plot-null` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin12-fe-caterpillar` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin12-fe-caterpillar-flags` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin12-fe-caterpillar-one-sided` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower |
| `lin12-fe-bar` | bar_plot | closed_form | value | match | identical |
| `lin12-fe-bar-3` | bar_plot | closed_form | value | match | identical |
| `lin12-fe-full-test` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin12-fe-full-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin12-fe-full-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin12-fe-full-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin12-fe-full-test-greater` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin12-fe-full-confint-greater` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.direct$Direct.Difference, CI.direct$direct.Lower |
| `lin12-fe-full-test-less` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin12-fe-full-confint-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin12-fe-full-test-mean-parm` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin12-fe-full-test-null` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin12-fe-full-sm-null-parm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin12-fe-full-sm-mean` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin12-fe-full-confint-gamma` | confint | closed_form | value | match | within tolerance: $gamma, $gamma.Lower, $gamma.Upper |
| `lin12-fe-full-confint-mean-parm` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin12-fe-full-confint-null-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin12-fe-full-summary-parm` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin12-fe-full-plot` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin12-fe-full-plot-mean` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin12-fe-full-plot-null` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin12-fe-full-caterpillar` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin12-fe-full-caterpillar-flags` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin12-fe-full-caterpillar-one-sided` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower |
| `lin12-fe-full-bar` | bar_plot | closed_form | value | match | identical |
| `lin12-fe-full-bar-3` | bar_plot | closed_form | value | match | identical |
| `lin12-re` | linear_re | lme4 | value | match | identical |
| `lin12-cre` | linear_cre | lme4 | value | match | identical |
| `lin12-re-test` | test | lme4 | value | match | identical |
| `lin12-re-sm` | SM_output | lme4 | value | match | identical |
| `lin12-re-confint` | confint | lme4 | value | match | identical |
| `lin12-re-summary` | summary | lme4 | value | match | identical |
| `lin12-re-test-greater` | test | lme4 | value | match | identical |
| `lin12-re-confint-greater` | confint | lme4 | value | match | identical |
| `lin12-re-test-less` | test | lme4 | value | match | identical |
| `lin12-re-confint-less` | confint | lme4 | value | match | identical |
| `lin12-re-test-null-parm` | test | lme4 | value | match | identical |
| `lin12-re-sm-parm` | SM_output | lme4 | value | match | identical |
| `lin12-re-confint-level-parm` | confint | lme4 | value | match | identical |
| `lin12-re-confint-alpha` | confint | lme4 | value | match | identical |
| `lin12-re-confint-alpha-greater` | confint | lme4 | error | match |  |
| `lin12-re-summary-parm` | summary | lme4 | value | match | identical |
| `lin12-re-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `lin12-re-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `lin12-re-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `lin12-re-bar` | bar_plot | lme4 | value | match | identical |
| `lin12-re-bar-3` | bar_plot | lme4 | value | match | identical |
| `lin12-cre-test` | test | lme4 | value | match | identical |
| `lin12-cre-sm` | SM_output | lme4 | value | match | identical |
| `lin12-cre-confint` | confint | lme4 | value | match | identical |
| `lin12-cre-summary` | summary | lme4 | value | match | identical |
| `lin12-cre-test-greater` | test | lme4 | value | match | identical |
| `lin12-cre-confint-greater` | confint | lme4 | value | match | identical |
| `lin12-cre-test-less` | test | lme4 | value | match | identical |
| `lin12-cre-confint-less` | confint | lme4 | value | match | identical |
| `lin12-cre-test-null-parm` | test | lme4 | value | match | identical |
| `lin12-cre-sm-parm` | SM_output | lme4 | value | match | identical |
| `lin12-cre-confint-level-parm` | confint | lme4 | value | match | identical |
| `lin12-cre-confint-alpha` | confint | lme4 | value | match | identical |
| `lin12-cre-confint-alpha-greater` | confint | lme4 | error | match |  |
| `lin12-cre-summary-parm` | summary | lme4 | value | match | identical |
| `lin12-cre-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `lin12-cre-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `lin12-cre-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `lin12-cre-bar` | bar_plot | lme4 | value | match | identical |
| `lin12-cre-bar-3` | bar_plot | lme4 | value | match | identical |
| `lin13-fe` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, fitted, residuals, linear_pred |
| `lin13-fe-full` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, variance$gamma, fitted, residuals, linear_pred |
| `lin13-fe-test` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin13-fe-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `lin13-fe-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin13-fe-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin13-fe-test-greater` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin13-fe-confint-greater` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.direct$Direct.Difference, CI.direct$direct.Lower |
| `lin13-fe-test-less` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin13-fe-confint-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin13-fe-test-mean-parm` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin13-fe-test-null` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin13-fe-sm-null-parm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin13-fe-sm-mean` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `lin13-fe-confint-gamma` | confint | closed_form | value | match | within tolerance: $gamma, $gamma.Lower, $gamma.Upper |
| `lin13-fe-confint-mean-parm` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin13-fe-confint-null-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin13-fe-summary-parm` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin13-fe-plot` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin13-fe-plot-mean` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin13-fe-plot-null` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin13-fe-caterpillar` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin13-fe-caterpillar-flags` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin13-fe-caterpillar-one-sided` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower |
| `lin13-fe-bar` | bar_plot | closed_form | value | match | identical |
| `lin13-fe-bar-3` | bar_plot | closed_form | value | match | identical |
| `lin13-fe-full-test` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin13-fe-full-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `lin13-fe-full-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin13-fe-full-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin13-fe-full-test-greater` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin13-fe-full-confint-greater` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.direct$Direct.Difference, CI.direct$direct.Lower |
| `lin13-fe-full-test-less` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin13-fe-full-confint-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin13-fe-full-test-mean-parm` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin13-fe-full-test-null` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin13-fe-full-sm-null-parm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin13-fe-full-sm-mean` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `lin13-fe-full-confint-gamma` | confint | closed_form | value | match | within tolerance: $gamma, $gamma.Lower, $gamma.Upper |
| `lin13-fe-full-confint-mean-parm` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin13-fe-full-confint-null-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin13-fe-full-summary-parm` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin13-fe-full-plot` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin13-fe-full-plot-mean` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin13-fe-full-plot-null` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin13-fe-full-caterpillar` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin13-fe-full-caterpillar-flags` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin13-fe-full-caterpillar-one-sided` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower |
| `lin13-fe-full-bar` | bar_plot | closed_form | value | match | identical |
| `lin13-fe-full-bar-3` | bar_plot | closed_form | value | match | identical |
| `lin13-re` | linear_re | lme4 | value | match | identical |
| `lin13-cre` | linear_cre | lme4 | value | match | identical |
| `lin13-re-test` | test | lme4 | value | match | identical |
| `lin13-re-sm` | SM_output | lme4 | value | match | identical |
| `lin13-re-confint` | confint | lme4 | value | match | identical |
| `lin13-re-summary` | summary | lme4 | value | match | identical |
| `lin13-re-test-greater` | test | lme4 | value | match | identical |
| `lin13-re-confint-greater` | confint | lme4 | value | match | identical |
| `lin13-re-test-less` | test | lme4 | value | match | identical |
| `lin13-re-confint-less` | confint | lme4 | value | match | identical |
| `lin13-re-test-null-parm` | test | lme4 | value | match | identical |
| `lin13-re-sm-parm` | SM_output | lme4 | value | match | identical |
| `lin13-re-confint-level-parm` | confint | lme4 | value | match | identical |
| `lin13-re-confint-alpha` | confint | lme4 | value | match | identical |
| `lin13-re-confint-alpha-greater` | confint | lme4 | error | match |  |
| `lin13-re-summary-parm` | summary | lme4 | value | match | identical |
| `lin13-re-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `lin13-re-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `lin13-re-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `lin13-re-bar` | bar_plot | lme4 | value | match | identical |
| `lin13-re-bar-3` | bar_plot | lme4 | value | match | identical |
| `lin13-cre-test` | test | lme4 | value | match | identical |
| `lin13-cre-sm` | SM_output | lme4 | value | match | identical |
| `lin13-cre-confint` | confint | lme4 | value | match | identical |
| `lin13-cre-summary` | summary | lme4 | value | match | identical |
| `lin13-cre-test-greater` | test | lme4 | value | match | identical |
| `lin13-cre-confint-greater` | confint | lme4 | value | match | identical |
| `lin13-cre-test-less` | test | lme4 | value | match | identical |
| `lin13-cre-confint-less` | confint | lme4 | value | match | identical |
| `lin13-cre-test-null-parm` | test | lme4 | value | match | identical |
| `lin13-cre-sm-parm` | SM_output | lme4 | value | match | identical |
| `lin13-cre-confint-level-parm` | confint | lme4 | value | match | identical |
| `lin13-cre-confint-alpha` | confint | lme4 | value | match | identical |
| `lin13-cre-confint-alpha-greater` | confint | lme4 | error | match |  |
| `lin13-cre-summary-parm` | summary | lme4 | value | match | identical |
| `lin13-cre-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `lin13-cre-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `lin13-cre-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `lin13-cre-bar` | bar_plot | lme4 | value | match | identical |
| `lin13-cre-bar-3` | bar_plot | lme4 | value | match | identical |
| `lin14-fe` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, fitted, residuals, linear_pred |
| `lin14-fe-full` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, variance$gamma, fitted, residuals, linear_pred |
| `lin14-fe-test` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin14-fe-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin14-fe-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin14-fe-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin14-fe-test-greater` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin14-fe-confint-greater` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.direct$Direct.Difference, CI.direct$direct.Lower |
| `lin14-fe-test-less` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin14-fe-confint-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin14-fe-test-mean-parm` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin14-fe-test-null` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin14-fe-sm-null-parm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin14-fe-sm-mean` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin14-fe-confint-gamma` | confint | closed_form | value | match | within tolerance: $gamma, $gamma.Lower, $gamma.Upper |
| `lin14-fe-confint-mean-parm` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin14-fe-confint-null-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin14-fe-summary-parm` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin14-fe-plot` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin14-fe-plot-mean` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin14-fe-plot-null` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin14-fe-caterpillar` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin14-fe-caterpillar-flags` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin14-fe-caterpillar-one-sided` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower |
| `lin14-fe-bar` | bar_plot | closed_form | value | match | identical |
| `lin14-fe-bar-3` | bar_plot | closed_form | value | match | identical |
| `lin14-fe-full-test` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin14-fe-full-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin14-fe-full-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin14-fe-full-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin14-fe-full-test-greater` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin14-fe-full-confint-greater` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.direct$Direct.Difference, CI.direct$direct.Lower |
| `lin14-fe-full-test-less` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin14-fe-full-confint-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin14-fe-full-test-mean-parm` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin14-fe-full-test-null` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin14-fe-full-sm-null-parm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin14-fe-full-sm-mean` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin14-fe-full-confint-gamma` | confint | closed_form | value | match | within tolerance: $gamma, $gamma.Lower, $gamma.Upper |
| `lin14-fe-full-confint-mean-parm` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin14-fe-full-confint-null-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin14-fe-full-summary-parm` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin14-fe-full-plot` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin14-fe-full-plot-mean` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin14-fe-full-plot-null` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin14-fe-full-caterpillar` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin14-fe-full-caterpillar-flags` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin14-fe-full-caterpillar-one-sided` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower |
| `lin14-fe-full-bar` | bar_plot | closed_form | value | match | identical |
| `lin14-fe-full-bar-3` | bar_plot | closed_form | value | match | identical |
| `lin14-re` | linear_re | lme4 | value | match | identical |
| `lin14-cre` | linear_cre | lme4 | value | match | identical |
| `lin14-re-test` | test | lme4 | value | match | identical |
| `lin14-re-sm` | SM_output | lme4 | value | match | identical |
| `lin14-re-confint` | confint | lme4 | value | match | identical |
| `lin14-re-summary` | summary | lme4 | value | match | identical |
| `lin14-re-test-greater` | test | lme4 | value | match | identical |
| `lin14-re-confint-greater` | confint | lme4 | value | match | identical |
| `lin14-re-test-less` | test | lme4 | value | match | identical |
| `lin14-re-confint-less` | confint | lme4 | value | match | identical |
| `lin14-re-test-null-parm` | test | lme4 | value | match | identical |
| `lin14-re-sm-parm` | SM_output | lme4 | value | match | identical |
| `lin14-re-confint-level-parm` | confint | lme4 | value | match | identical |
| `lin14-re-confint-alpha` | confint | lme4 | value | match | identical |
| `lin14-re-confint-alpha-greater` | confint | lme4 | error | match |  |
| `lin14-re-summary-parm` | summary | lme4 | value | match | identical |
| `lin14-re-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `lin14-re-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `lin14-re-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `lin14-re-bar` | bar_plot | lme4 | value | match | identical |
| `lin14-re-bar-3` | bar_plot | lme4 | value | match | identical |
| `lin14-cre-test` | test | lme4 | value | match | identical |
| `lin14-cre-sm` | SM_output | lme4 | value | match | identical |
| `lin14-cre-confint` | confint | lme4 | value | match | identical |
| `lin14-cre-summary` | summary | lme4 | value | match | identical |
| `lin14-cre-test-greater` | test | lme4 | value | match | identical |
| `lin14-cre-confint-greater` | confint | lme4 | value | match | identical |
| `lin14-cre-test-less` | test | lme4 | value | match | identical |
| `lin14-cre-confint-less` | confint | lme4 | value | match | identical |
| `lin14-cre-test-null-parm` | test | lme4 | value | match | identical |
| `lin14-cre-sm-parm` | SM_output | lme4 | value | match | identical |
| `lin14-cre-confint-level-parm` | confint | lme4 | value | match | identical |
| `lin14-cre-confint-alpha` | confint | lme4 | value | match | identical |
| `lin14-cre-confint-alpha-greater` | confint | lme4 | error | match |  |
| `lin14-cre-summary-parm` | summary | lme4 | value | match | identical |
| `lin14-cre-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `lin14-cre-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `lin14-cre-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `lin14-cre-bar` | bar_plot | lme4 | value | match | identical |
| `lin14-cre-bar-3` | bar_plot | lme4 | value | match | identical |
| `lin15-fe` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, fitted, residuals, linear_pred |
| `lin15-fe-full` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, variance$gamma, fitted, residuals, linear_pred |
| `lin15-fe-test` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin15-fe-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `lin15-fe-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin15-fe-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin15-fe-test-greater` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin15-fe-confint-greater` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.direct$Direct.Difference, CI.direct$direct.Lower |
| `lin15-fe-test-less` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin15-fe-confint-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin15-fe-test-mean-parm` | test | closed_form | value | match | within tolerance: $stat |
| `lin15-fe-test-null` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin15-fe-sm-null-parm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin15-fe-sm-mean` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin15-fe-confint-gamma` | confint | closed_form | value | match | within tolerance: $gamma, $gamma.Lower, $gamma.Upper |
| `lin15-fe-confint-mean-parm` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin15-fe-confint-null-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin15-fe-summary-parm` | summary | closed_form | value | match | within tolerance: $Std.Error, $Stat, $CI.Lower |
| `lin15-fe-plot` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin15-fe-plot-mean` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin15-fe-plot-null` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin15-fe-caterpillar` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin15-fe-caterpillar-flags` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin15-fe-caterpillar-one-sided` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower |
| `lin15-fe-bar` | bar_plot | closed_form | value | match | identical |
| `lin15-fe-bar-3` | bar_plot | closed_form | value | match | identical |
| `lin15-fe-full-test` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin15-fe-full-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `lin15-fe-full-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin15-fe-full-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin15-fe-full-test-greater` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin15-fe-full-confint-greater` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.direct$Direct.Difference, CI.direct$direct.Lower |
| `lin15-fe-full-test-less` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin15-fe-full-confint-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin15-fe-full-test-mean-parm` | test | closed_form | value | match | within tolerance: $stat |
| `lin15-fe-full-test-null` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `lin15-fe-full-sm-null-parm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin15-fe-full-sm-mean` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin15-fe-full-confint-gamma` | confint | closed_form | value | match | within tolerance: $gamma, $gamma.Lower, $gamma.Upper |
| `lin15-fe-full-confint-mean-parm` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin15-fe-full-confint-null-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `lin15-fe-full-summary-parm` | summary | closed_form | value | match | within tolerance: $Std.Error, $Stat, $CI.Lower |
| `lin15-fe-full-plot` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin15-fe-full-plot-mean` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin15-fe-full-plot-null` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `lin15-fe-full-caterpillar` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin15-fe-full-caterpillar-flags` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `lin15-fe-full-caterpillar-one-sided` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower |
| `lin15-fe-full-bar` | bar_plot | closed_form | value | match | identical |
| `lin15-fe-full-bar-3` | bar_plot | closed_form | value | match | identical |
| `lin15-re` | linear_re | lme4 | value | match | identical |
| `lin15-cre` | linear_cre | lme4 | value | match | identical |
| `lin15-re-test` | test | lme4 | value | match | identical |
| `lin15-re-sm` | SM_output | lme4 | value | match | identical |
| `lin15-re-confint` | confint | lme4 | value | match | identical |
| `lin15-re-summary` | summary | lme4 | value | match | identical |
| `lin15-re-test-greater` | test | lme4 | value | match | identical |
| `lin15-re-confint-greater` | confint | lme4 | value | match | identical |
| `lin15-re-test-less` | test | lme4 | value | match | identical |
| `lin15-re-confint-less` | confint | lme4 | value | match | identical |
| `lin15-re-test-null-parm` | test | lme4 | value | match | identical |
| `lin15-re-sm-parm` | SM_output | lme4 | value | match | identical |
| `lin15-re-confint-level-parm` | confint | lme4 | value | match | identical |
| `lin15-re-confint-alpha` | confint | lme4 | value | match | identical |
| `lin15-re-confint-alpha-greater` | confint | lme4 | error | match |  |
| `lin15-re-summary-parm` | summary | lme4 | value | match | identical |
| `lin15-re-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `lin15-re-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `lin15-re-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `lin15-re-bar` | bar_plot | lme4 | value | match | identical |
| `lin15-re-bar-3` | bar_plot | lme4 | value | match | identical |
| `lin15-cre-test` | test | lme4 | value | match | identical |
| `lin15-cre-sm` | SM_output | lme4 | value | match | identical |
| `lin15-cre-confint` | confint | lme4 | value | match | identical |
| `lin15-cre-summary` | summary | lme4 | value | match | identical |
| `lin15-cre-test-greater` | test | lme4 | value | match | identical |
| `lin15-cre-confint-greater` | confint | lme4 | value | match | identical |
| `lin15-cre-test-less` | test | lme4 | value | match | identical |
| `lin15-cre-confint-less` | confint | lme4 | value | match | identical |
| `lin15-cre-test-null-parm` | test | lme4 | value | match | identical |
| `lin15-cre-sm-parm` | SM_output | lme4 | value | match | identical |
| `lin15-cre-confint-level-parm` | confint | lme4 | value | match | identical |
| `lin15-cre-confint-alpha` | confint | lme4 | value | match | identical |
| `lin15-cre-confint-alpha-greater` | confint | lme4 | error | match |  |
| `lin15-cre-summary-parm` | summary | lme4 | value | match | identical |
| `lin15-cre-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `lin15-cre-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `lin15-cre-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `lin15-cre-bar` | bar_plot | lme4 | value | match | identical |
| `lin15-cre-bar-3` | bar_plot | lme4 | value | match | identical |
| `chr-lin01-fe` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, fitted, residuals, linear_pred |
| `chr-lin01-fe-full` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, fitted, residuals, linear_pred |
| `chr-lin01-fe-test` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `chr-lin01-fe-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `chr-lin01-fe-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `chr-lin01-fe-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `chr-lin01-fe-test-greater` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `chr-lin01-fe-confint-greater` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.direct$Direct.Difference, CI.direct$direct.Lower |
| `chr-lin01-fe-test-less` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `chr-lin01-fe-confint-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `chr-lin01-fe-test-mean-parm` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `chr-lin01-fe-test-null` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `chr-lin01-fe-sm-null-parm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `chr-lin01-fe-sm-mean` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `chr-lin01-fe-confint-gamma` | confint | closed_form | value | match | within tolerance: $gamma, $gamma.Lower, $gamma.Upper |
| `chr-lin01-fe-confint-mean-parm` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `chr-lin01-fe-confint-null-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `chr-lin01-fe-summary-parm` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `chr-lin01-fe-plot` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `chr-lin01-fe-plot-mean` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `chr-lin01-fe-plot-null` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `chr-lin01-fe-caterpillar` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `chr-lin01-fe-caterpillar-flags` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `chr-lin01-fe-caterpillar-one-sided` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower |
| `chr-lin01-fe-bar` | bar_plot | closed_form | value | match | identical |
| `chr-lin01-fe-bar-3` | bar_plot | closed_form | value | match | identical |
| `chr-lin01-fe-full-test` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `chr-lin01-fe-full-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `chr-lin01-fe-full-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `chr-lin01-fe-full-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `chr-lin01-fe-full-test-greater` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `chr-lin01-fe-full-confint-greater` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.direct$Direct.Difference, CI.direct$direct.Lower |
| `chr-lin01-fe-full-test-less` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `chr-lin01-fe-full-confint-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `chr-lin01-fe-full-test-mean-parm` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `chr-lin01-fe-full-test-null` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `chr-lin01-fe-full-sm-null-parm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `chr-lin01-fe-full-sm-mean` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `chr-lin01-fe-full-confint-gamma` | confint | closed_form | value | match | within tolerance: $gamma, $gamma.Lower, $gamma.Upper |
| `chr-lin01-fe-full-confint-mean-parm` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `chr-lin01-fe-full-confint-null-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `chr-lin01-fe-full-summary-parm` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `chr-lin01-fe-full-plot` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `chr-lin01-fe-full-plot-mean` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `chr-lin01-fe-full-plot-null` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `chr-lin01-fe-full-caterpillar` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `chr-lin01-fe-full-caterpillar-flags` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `chr-lin01-fe-full-caterpillar-one-sided` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower |
| `chr-lin01-fe-full-bar` | bar_plot | closed_form | value | match | identical |
| `chr-lin01-fe-full-bar-3` | bar_plot | closed_form | value | match | identical |
| `chr-lin01-re` | linear_re | lme4 | value | match | identical |
| `chr-lin01-cre` | linear_cre | lme4 | value | match | identical |
| `chr-lin01-re-test` | test | lme4 | value | match | identical |
| `chr-lin01-re-sm` | SM_output | lme4 | value | match | identical |
| `chr-lin01-re-confint` | confint | lme4 | value | match | identical |
| `chr-lin01-re-summary` | summary | lme4 | value | match | identical |
| `chr-lin01-re-test-greater` | test | lme4 | value | match | identical |
| `chr-lin01-re-confint-greater` | confint | lme4 | value | match | identical |
| `chr-lin01-re-test-less` | test | lme4 | value | match | identical |
| `chr-lin01-re-confint-less` | confint | lme4 | value | match | identical |
| `chr-lin01-re-test-null-parm` | test | lme4 | value | match | identical |
| `chr-lin01-re-sm-parm` | SM_output | lme4 | value | match | identical |
| `chr-lin01-re-confint-level-parm` | confint | lme4 | value | match | identical |
| `chr-lin01-re-confint-alpha` | confint | lme4 | value | match | identical |
| `chr-lin01-re-confint-alpha-greater` | confint | lme4 | error | match |  |
| `chr-lin01-re-summary-parm` | summary | lme4 | value | match | identical |
| `chr-lin01-re-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `chr-lin01-re-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `chr-lin01-re-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `chr-lin01-re-bar` | bar_plot | lme4 | value | match | identical |
| `chr-lin01-re-bar-3` | bar_plot | lme4 | value | match | identical |
| `chr-lin01-cre-test` | test | lme4 | value | match | identical |
| `chr-lin01-cre-sm` | SM_output | lme4 | value | match | identical |
| `chr-lin01-cre-confint` | confint | lme4 | value | match | identical |
| `chr-lin01-cre-summary` | summary | lme4 | value | match | identical |
| `chr-lin01-cre-test-greater` | test | lme4 | value | match | identical |
| `chr-lin01-cre-confint-greater` | confint | lme4 | value | match | identical |
| `chr-lin01-cre-test-less` | test | lme4 | value | match | identical |
| `chr-lin01-cre-confint-less` | confint | lme4 | value | match | identical |
| `chr-lin01-cre-test-null-parm` | test | lme4 | value | match | identical |
| `chr-lin01-cre-sm-parm` | SM_output | lme4 | value | match | identical |
| `chr-lin01-cre-confint-level-parm` | confint | lme4 | value | match | identical |
| `chr-lin01-cre-confint-alpha` | confint | lme4 | value | match | identical |
| `chr-lin01-cre-confint-alpha-greater` | confint | lme4 | error | match |  |
| `chr-lin01-cre-summary-parm` | summary | lme4 | value | match | identical |
| `chr-lin01-cre-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `chr-lin01-cre-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `chr-lin01-cre-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `chr-lin01-cre-bar` | bar_plot | lme4 | value | match | identical |
| `chr-lin01-cre-bar-3` | bar_plot | lme4 | value | match | identical |
| `chr-lin02-fe` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, fitted, residuals, linear_pred |
| `chr-lin02-fe-full` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, variance$gamma, fitted, residuals, linear_pred |
| `chr-lin02-fe-test` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `chr-lin02-fe-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `chr-lin02-fe-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `chr-lin02-fe-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `chr-lin02-fe-test-greater` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `chr-lin02-fe-confint-greater` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.direct$Direct.Difference, CI.direct$direct.Lower |
| `chr-lin02-fe-test-less` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `chr-lin02-fe-confint-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `chr-lin02-fe-test-mean-parm` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `chr-lin02-fe-test-null` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `chr-lin02-fe-sm-null-parm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `chr-lin02-fe-sm-mean` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `chr-lin02-fe-confint-gamma` | confint | closed_form | value | match | within tolerance: $gamma, $gamma.Lower, $gamma.Upper |
| `chr-lin02-fe-confint-mean-parm` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `chr-lin02-fe-confint-null-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `chr-lin02-fe-summary-parm` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `chr-lin02-fe-plot` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `chr-lin02-fe-plot-mean` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `chr-lin02-fe-plot-null` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `chr-lin02-fe-caterpillar` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `chr-lin02-fe-caterpillar-flags` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `chr-lin02-fe-caterpillar-one-sided` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower |
| `chr-lin02-fe-bar` | bar_plot | closed_form | value | match | identical |
| `chr-lin02-fe-bar-3` | bar_plot | closed_form | value | match | identical |
| `chr-lin02-fe-full-test` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `chr-lin02-fe-full-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `chr-lin02-fe-full-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `chr-lin02-fe-full-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `chr-lin02-fe-full-test-greater` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `chr-lin02-fe-full-confint-greater` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.direct$Direct.Difference, CI.direct$direct.Lower |
| `chr-lin02-fe-full-test-less` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `chr-lin02-fe-full-confint-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `chr-lin02-fe-full-test-mean-parm` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `chr-lin02-fe-full-test-null` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `chr-lin02-fe-full-sm-null-parm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `chr-lin02-fe-full-sm-mean` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `chr-lin02-fe-full-confint-gamma` | confint | closed_form | value | match | within tolerance: $gamma, $gamma.Lower, $gamma.Upper |
| `chr-lin02-fe-full-confint-mean-parm` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `chr-lin02-fe-full-confint-null-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `chr-lin02-fe-full-summary-parm` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `chr-lin02-fe-full-plot` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `chr-lin02-fe-full-plot-mean` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `chr-lin02-fe-full-plot-null` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `chr-lin02-fe-full-caterpillar` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `chr-lin02-fe-full-caterpillar-flags` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `chr-lin02-fe-full-caterpillar-one-sided` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower |
| `chr-lin02-fe-full-bar` | bar_plot | closed_form | value | match | identical |
| `chr-lin02-fe-full-bar-3` | bar_plot | closed_form | value | match | identical |
| `chr-lin02-re` | linear_re | lme4 | value | match | identical |
| `chr-lin02-cre` | linear_cre | lme4 | value | match | identical |
| `chr-lin02-re-test` | test | lme4 | value | match | identical |
| `chr-lin02-re-sm` | SM_output | lme4 | value | match | identical |
| `chr-lin02-re-confint` | confint | lme4 | value | match | identical |
| `chr-lin02-re-summary` | summary | lme4 | value | match | identical |
| `chr-lin02-re-test-greater` | test | lme4 | value | match | identical |
| `chr-lin02-re-confint-greater` | confint | lme4 | value | match | identical |
| `chr-lin02-re-test-less` | test | lme4 | value | match | identical |
| `chr-lin02-re-confint-less` | confint | lme4 | value | match | identical |
| `chr-lin02-re-test-null-parm` | test | lme4 | value | match | identical |
| `chr-lin02-re-sm-parm` | SM_output | lme4 | value | match | identical |
| `chr-lin02-re-confint-level-parm` | confint | lme4 | value | match | identical |
| `chr-lin02-re-confint-alpha` | confint | lme4 | value | match | identical |
| `chr-lin02-re-confint-alpha-greater` | confint | lme4 | error | match |  |
| `chr-lin02-re-summary-parm` | summary | lme4 | value | match | identical |
| `chr-lin02-re-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `chr-lin02-re-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `chr-lin02-re-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `chr-lin02-re-bar` | bar_plot | lme4 | value | match | identical |
| `chr-lin02-re-bar-3` | bar_plot | lme4 | value | match | identical |
| `chr-lin02-cre-test` | test | lme4 | value | match | identical |
| `chr-lin02-cre-sm` | SM_output | lme4 | value | match | identical |
| `chr-lin02-cre-confint` | confint | lme4 | value | match | identical |
| `chr-lin02-cre-summary` | summary | lme4 | value | match | identical |
| `chr-lin02-cre-test-greater` | test | lme4 | value | match | identical |
| `chr-lin02-cre-confint-greater` | confint | lme4 | value | match | identical |
| `chr-lin02-cre-test-less` | test | lme4 | value | match | identical |
| `chr-lin02-cre-confint-less` | confint | lme4 | value | match | identical |
| `chr-lin02-cre-test-null-parm` | test | lme4 | value | match | identical |
| `chr-lin02-cre-sm-parm` | SM_output | lme4 | value | match | identical |
| `chr-lin02-cre-confint-level-parm` | confint | lme4 | value | match | identical |
| `chr-lin02-cre-confint-alpha` | confint | lme4 | value | match | identical |
| `chr-lin02-cre-confint-alpha-greater` | confint | lme4 | error | match |  |
| `chr-lin02-cre-summary-parm` | summary | lme4 | value | match | identical |
| `chr-lin02-cre-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `chr-lin02-cre-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `chr-lin02-cre-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `chr-lin02-cre-bar` | bar_plot | lme4 | value | match | identical |
| `chr-lin02-cre-bar-3` | bar_plot | lme4 | value | match | identical |
| `chr-lin03-fe` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, variance$gamma, fitted, residuals, linear_pred |
| `chr-lin03-fe-full` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, variance$gamma, fitted, residuals, linear_pred |
| `chr-lin03-fe-test` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `chr-lin03-fe-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `chr-lin03-fe-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `chr-lin03-fe-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `chr-lin03-fe-test-greater` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `chr-lin03-fe-confint-greater` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.direct$Direct.Difference, CI.direct$direct.Lower |
| `chr-lin03-fe-test-less` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `chr-lin03-fe-confint-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `chr-lin03-fe-test-mean-parm` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `chr-lin03-fe-test-null` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `chr-lin03-fe-sm-null-parm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `chr-lin03-fe-sm-mean` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `chr-lin03-fe-confint-gamma` | confint | closed_form | value | match | within tolerance: $gamma, $gamma.Lower, $gamma.Upper |
| `chr-lin03-fe-confint-mean-parm` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `chr-lin03-fe-confint-null-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `chr-lin03-fe-summary-parm` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `chr-lin03-fe-plot` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `chr-lin03-fe-plot-mean` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `chr-lin03-fe-plot-null` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `chr-lin03-fe-caterpillar` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `chr-lin03-fe-caterpillar-flags` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `chr-lin03-fe-caterpillar-one-sided` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower |
| `chr-lin03-fe-bar` | bar_plot | closed_form | value | match | identical |
| `chr-lin03-fe-bar-3` | bar_plot | closed_form | value | match | identical |
| `chr-lin03-fe-full-test` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `chr-lin03-fe-full-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `chr-lin03-fe-full-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `chr-lin03-fe-full-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `chr-lin03-fe-full-test-greater` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `chr-lin03-fe-full-confint-greater` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.direct$Direct.Difference, CI.direct$direct.Lower |
| `chr-lin03-fe-full-test-less` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `chr-lin03-fe-full-confint-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `chr-lin03-fe-full-test-mean-parm` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `chr-lin03-fe-full-test-null` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `chr-lin03-fe-full-sm-null-parm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `chr-lin03-fe-full-sm-mean` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `chr-lin03-fe-full-confint-gamma` | confint | closed_form | value | match | within tolerance: $gamma, $gamma.Lower, $gamma.Upper |
| `chr-lin03-fe-full-confint-mean-parm` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `chr-lin03-fe-full-confint-null-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `chr-lin03-fe-full-summary-parm` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `chr-lin03-fe-full-plot` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `chr-lin03-fe-full-plot-mean` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `chr-lin03-fe-full-plot-null` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `chr-lin03-fe-full-caterpillar` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `chr-lin03-fe-full-caterpillar-flags` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `chr-lin03-fe-full-caterpillar-one-sided` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower |
| `chr-lin03-fe-full-bar` | bar_plot | closed_form | value | match | identical |
| `chr-lin03-fe-full-bar-3` | bar_plot | closed_form | value | match | identical |
| `chr-lin03-re` | linear_re | lme4 | value | match | identical |
| `chr-lin03-cre` | linear_cre | lme4 | value | match | identical |
| `chr-lin03-re-test` | test | lme4 | value | match | identical |
| `chr-lin03-re-sm` | SM_output | lme4 | value | match | identical |
| `chr-lin03-re-confint` | confint | lme4 | value | match | identical |
| `chr-lin03-re-summary` | summary | lme4 | value | match | identical |
| `chr-lin03-re-test-greater` | test | lme4 | value | match | identical |
| `chr-lin03-re-confint-greater` | confint | lme4 | value | match | identical |
| `chr-lin03-re-test-less` | test | lme4 | value | match | identical |
| `chr-lin03-re-confint-less` | confint | lme4 | value | match | identical |
| `chr-lin03-re-test-null-parm` | test | lme4 | value | match | identical |
| `chr-lin03-re-sm-parm` | SM_output | lme4 | value | match | identical |
| `chr-lin03-re-confint-level-parm` | confint | lme4 | value | match | identical |
| `chr-lin03-re-confint-alpha` | confint | lme4 | value | match | identical |
| `chr-lin03-re-confint-alpha-greater` | confint | lme4 | error | match |  |
| `chr-lin03-re-summary-parm` | summary | lme4 | value | match | identical |
| `chr-lin03-re-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `chr-lin03-re-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `chr-lin03-re-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `chr-lin03-re-bar` | bar_plot | lme4 | value | match | identical |
| `chr-lin03-re-bar-3` | bar_plot | lme4 | value | match | identical |
| `chr-lin03-cre-test` | test | lme4 | value | match | identical |
| `chr-lin03-cre-sm` | SM_output | lme4 | value | match | identical |
| `chr-lin03-cre-confint` | confint | lme4 | value | match | identical |
| `chr-lin03-cre-summary` | summary | lme4 | value | match | identical |
| `chr-lin03-cre-test-greater` | test | lme4 | value | match | identical |
| `chr-lin03-cre-confint-greater` | confint | lme4 | value | match | identical |
| `chr-lin03-cre-test-less` | test | lme4 | value | match | identical |
| `chr-lin03-cre-confint-less` | confint | lme4 | value | match | identical |
| `chr-lin03-cre-test-null-parm` | test | lme4 | value | match | identical |
| `chr-lin03-cre-sm-parm` | SM_output | lme4 | value | match | identical |
| `chr-lin03-cre-confint-level-parm` | confint | lme4 | value | match | identical |
| `chr-lin03-cre-confint-alpha` | confint | lme4 | value | match | identical |
| `chr-lin03-cre-confint-alpha-greater` | confint | lme4 | error | match |  |
| `chr-lin03-cre-summary-parm` | summary | lme4 | value | match | identical |
| `chr-lin03-cre-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `chr-lin03-cre-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `chr-lin03-cre-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `chr-lin03-cre-bar` | bar_plot | lme4 | value | match | identical |
| `chr-lin03-cre-bar-3` | bar_plot | lme4 | value | match | identical |
| `null-lin01-fe` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, variance$gamma, sigma, fitted, residuals, linear_pred, Loglkd, AIC, BIC |
| `null-lin01-fe-full` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, variance$gamma, sigma, fitted, residuals, linear_pred, Loglkd, AIC, BIC |
| `null-lin01-fe-test` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `null-lin01-fe-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `null-lin01-fe-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `null-lin01-fe-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `null-lin01-fe-test-greater` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `null-lin01-fe-confint-greater` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.direct$Direct.Difference, CI.direct$direct.Lower |
| `null-lin01-fe-test-less` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `null-lin01-fe-confint-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `null-lin01-fe-test-mean-parm` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `null-lin01-fe-test-null` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `null-lin01-fe-sm-null-parm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `null-lin01-fe-sm-mean` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `null-lin01-fe-confint-gamma` | confint | closed_form | value | match | within tolerance: $gamma, $gamma.Lower, $gamma.Upper |
| `null-lin01-fe-confint-mean-parm` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `null-lin01-fe-confint-null-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `null-lin01-fe-summary-parm` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $CI.Lower, $CI.Upper |
| `null-lin01-fe-plot` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[1]]$data$lower, layers$[[1]]$data$upper, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[2]]$data$lower, layers$[[2]]$data$upper, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp, layers$[[3]]$data$lower, l |
| `null-lin01-fe-plot-mean` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[1]]$data$lower, layers$[[1]]$data$upper, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[2]]$data$lower, layers$[[2]]$data$upper, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp, layers$[[3]]$data$lower, l |
| `null-lin01-fe-plot-null` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[1]]$data$lower, layers$[[1]]$data$upper, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[2]]$data$lower, layers$[[2]]$data$upper, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp, layers$[[3]]$data$lower, l |
| `null-lin01-fe-caterpillar` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `null-lin01-fe-caterpillar-flags` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `null-lin01-fe-caterpillar-one-sided` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower |
| `null-lin01-fe-bar` | bar_plot | closed_form | value | match | identical |
| `null-lin01-fe-bar-3` | bar_plot | closed_form | value | match | identical |
| `null-lin01-fe-full-test` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `null-lin01-fe-full-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `null-lin01-fe-full-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `null-lin01-fe-full-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `null-lin01-fe-full-test-greater` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `null-lin01-fe-full-confint-greater` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.direct$Direct.Difference, CI.direct$direct.Lower |
| `null-lin01-fe-full-test-less` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `null-lin01-fe-full-confint-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `null-lin01-fe-full-test-mean-parm` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `null-lin01-fe-full-test-null` | test | closed_form | value | match | within tolerance: $p value, $stat, $Std.Error |
| `null-lin01-fe-full-sm-null-parm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `null-lin01-fe-full-sm-mean` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `null-lin01-fe-full-confint-gamma` | confint | closed_form | value | match | within tolerance: $gamma, $gamma.Lower, $gamma.Upper |
| `null-lin01-fe-full-confint-mean-parm` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `null-lin01-fe-full-confint-null-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `null-lin01-fe-full-summary-parm` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $CI.Lower, $CI.Upper |
| `null-lin01-fe-full-plot` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[1]]$data$lower, layers$[[1]]$data$upper, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[2]]$data$lower, layers$[[2]]$data$upper, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp, layers$[[3]]$data$lower, l |
| `null-lin01-fe-full-plot-mean` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[1]]$data$lower, layers$[[1]]$data$upper, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[2]]$data$lower, layers$[[2]]$data$upper, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp, layers$[[3]]$data$lower, l |
| `null-lin01-fe-full-plot-null` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[1]]$data$lower, layers$[[1]]$data$upper, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[2]]$data$lower, layers$[[2]]$data$upper, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp, layers$[[3]]$data$lower, l |
| `null-lin01-fe-full-caterpillar` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `null-lin01-fe-full-caterpillar-flags` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `null-lin01-fe-full-caterpillar-one-sided` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower |
| `null-lin01-fe-full-bar` | bar_plot | closed_form | value | match | identical |
| `null-lin01-fe-full-bar-3` | bar_plot | closed_form | value | match | identical |
| `null-lin01-re` | linear_re | lme4 | value | match | identical |
| `null-lin01-cre` | linear_cre | lme4 | value | match | identical |
| `null-lin01-re-test` | test | lme4 | value | match | identical |
| `null-lin01-re-sm` | SM_output | lme4 | value | match | identical |
| `null-lin01-re-confint` | confint | lme4 | value | match | identical |
| `null-lin01-re-summary` | summary | lme4 | value | match | identical |
| `null-lin01-re-test-greater` | test | lme4 | value | match | identical |
| `null-lin01-re-confint-greater` | confint | lme4 | value | match | identical |
| `null-lin01-re-test-less` | test | lme4 | value | match | identical |
| `null-lin01-re-confint-less` | confint | lme4 | value | match | identical |
| `null-lin01-re-test-null-parm` | test | lme4 | value | match | identical |
| `null-lin01-re-sm-parm` | SM_output | lme4 | value | match | identical |
| `null-lin01-re-confint-level-parm` | confint | lme4 | value | match | identical |
| `null-lin01-re-confint-alpha` | confint | lme4 | value | match | identical |
| `null-lin01-re-confint-alpha-greater` | confint | lme4 | error | match |  |
| `null-lin01-re-summary-parm` | summary | lme4 | value | match | identical |
| `null-lin01-re-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `null-lin01-re-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `null-lin01-re-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `null-lin01-re-bar` | bar_plot | lme4 | value | match | identical |
| `null-lin01-re-bar-3` | bar_plot | lme4 | value | match | identical |
| `null-lin01-cre-test` | test | lme4 | value | match | identical |
| `null-lin01-cre-sm` | SM_output | lme4 | value | match | identical |
| `null-lin01-cre-confint` | confint | lme4 | value | match | identical |
| `null-lin01-cre-summary` | summary | lme4 | value | match | identical |
| `null-lin01-cre-test-greater` | test | lme4 | value | match | identical |
| `null-lin01-cre-confint-greater` | confint | lme4 | value | match | identical |
| `null-lin01-cre-test-less` | test | lme4 | value | match | identical |
| `null-lin01-cre-confint-less` | confint | lme4 | value | match | identical |
| `null-lin01-cre-test-null-parm` | test | lme4 | value | match | identical |
| `null-lin01-cre-sm-parm` | SM_output | lme4 | value | match | identical |
| `null-lin01-cre-confint-level-parm` | confint | lme4 | value | match | identical |
| `null-lin01-cre-confint-alpha` | confint | lme4 | value | match | identical |
| `null-lin01-cre-confint-alpha-greater` | confint | lme4 | error | match |  |
| `null-lin01-cre-summary-parm` | summary | lme4 | value | match | identical |
| `null-lin01-cre-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `null-lin01-cre-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `null-lin01-cre-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `null-lin01-cre-bar` | bar_plot | lme4 | value | match | identical |
| `null-lin01-cre-bar-3` | bar_plot | lme4 | value | match | identical |
| `null-lin02-fe` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, fitted, residuals, linear_pred |
| `null-lin02-fe-full` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, fitted, residuals, linear_pred |
| `null-lin02-fe-test` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `null-lin02-fe-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `null-lin02-fe-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `null-lin02-fe-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `null-lin02-fe-test-greater` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `null-lin02-fe-confint-greater` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.direct$Direct.Difference, CI.direct$direct.Lower |
| `null-lin02-fe-test-less` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `null-lin02-fe-confint-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `null-lin02-fe-test-mean-parm` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `null-lin02-fe-test-null` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `null-lin02-fe-sm-null-parm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `null-lin02-fe-sm-mean` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `null-lin02-fe-confint-gamma` | confint | closed_form | value | match | within tolerance: $gamma, $gamma.Lower, $gamma.Upper |
| `null-lin02-fe-confint-mean-parm` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `null-lin02-fe-confint-null-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `null-lin02-fe-summary-parm` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `null-lin02-fe-plot` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `null-lin02-fe-plot-mean` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `null-lin02-fe-plot-null` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `null-lin02-fe-caterpillar` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `null-lin02-fe-caterpillar-flags` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `null-lin02-fe-caterpillar-one-sided` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower |
| `null-lin02-fe-bar` | bar_plot | closed_form | value | match | identical |
| `null-lin02-fe-bar-3` | bar_plot | closed_form | value | match | identical |
| `null-lin02-fe-full-test` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `null-lin02-fe-full-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `null-lin02-fe-full-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `null-lin02-fe-full-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `null-lin02-fe-full-test-greater` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `null-lin02-fe-full-confint-greater` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.direct$Direct.Difference, CI.direct$direct.Lower |
| `null-lin02-fe-full-test-less` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `null-lin02-fe-full-confint-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `null-lin02-fe-full-test-mean-parm` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `null-lin02-fe-full-test-null` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `null-lin02-fe-full-sm-null-parm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `null-lin02-fe-full-sm-mean` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `null-lin02-fe-full-confint-gamma` | confint | closed_form | value | match | within tolerance: $gamma, $gamma.Lower, $gamma.Upper |
| `null-lin02-fe-full-confint-mean-parm` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `null-lin02-fe-full-confint-null-less` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Upper |
| `null-lin02-fe-full-summary-parm` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `null-lin02-fe-full-plot` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `null-lin02-fe-full-plot-mean` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `null-lin02-fe-full-plot-null` | plot | closed_form | value | match | within tolerance: layers$[[1]]$data$indicator, layers$[[1]]$data$Exp, layers$[[2]]$data$indicator, layers$[[2]]$data$Exp, layers$[[3]]$data$indicator, layers$[[3]]$data$Exp |
| `null-lin02-fe-full-caterpillar` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `null-lin02-fe-full-caterpillar-flags` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower, data$Upper |
| `null-lin02-fe-full-caterpillar-one-sided` | caterpillar_plot | closed_form | value | match | within tolerance: data$SM, data$Lower |
| `null-lin02-fe-full-bar` | bar_plot | closed_form | value | match | identical |
| `null-lin02-fe-full-bar-3` | bar_plot | closed_form | value | match | identical |
| `null-lin02-re` | linear_re | lme4 | value | match | identical |
| `null-lin02-cre` | linear_cre | lme4 | value | match | identical |
| `null-lin02-re-test` | test | lme4 | value | match | identical |
| `null-lin02-re-sm` | SM_output | lme4 | value | match | identical |
| `null-lin02-re-confint` | confint | lme4 | value | match | identical |
| `null-lin02-re-summary` | summary | lme4 | value | match | identical |
| `null-lin02-re-test-greater` | test | lme4 | value | match | identical |
| `null-lin02-re-confint-greater` | confint | lme4 | value | match | identical |
| `null-lin02-re-test-less` | test | lme4 | value | match | identical |
| `null-lin02-re-confint-less` | confint | lme4 | value | match | identical |
| `null-lin02-re-test-null-parm` | test | lme4 | value | match | identical |
| `null-lin02-re-sm-parm` | SM_output | lme4 | value | match | identical |
| `null-lin02-re-confint-level-parm` | confint | lme4 | value | match | identical |
| `null-lin02-re-confint-alpha` | confint | lme4 | value | match | identical |
| `null-lin02-re-confint-alpha-greater` | confint | lme4 | error | match |  |
| `null-lin02-re-summary-parm` | summary | lme4 | value | match | identical |
| `null-lin02-re-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `null-lin02-re-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `null-lin02-re-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `null-lin02-re-bar` | bar_plot | lme4 | value | match | identical |
| `null-lin02-re-bar-3` | bar_plot | lme4 | value | match | identical |
| `null-lin02-cre-test` | test | lme4 | value | match | identical |
| `null-lin02-cre-sm` | SM_output | lme4 | value | match | identical |
| `null-lin02-cre-confint` | confint | lme4 | value | match | identical |
| `null-lin02-cre-summary` | summary | lme4 | value | match | identical |
| `null-lin02-cre-test-greater` | test | lme4 | value | match | identical |
| `null-lin02-cre-confint-greater` | confint | lme4 | value | match | identical |
| `null-lin02-cre-test-less` | test | lme4 | value | match | identical |
| `null-lin02-cre-confint-less` | confint | lme4 | value | match | identical |
| `null-lin02-cre-test-null-parm` | test | lme4 | value | match | identical |
| `null-lin02-cre-sm-parm` | SM_output | lme4 | value | match | identical |
| `null-lin02-cre-confint-level-parm` | confint | lme4 | value | match | identical |
| `null-lin02-cre-confint-alpha` | confint | lme4 | value | match | identical |
| `null-lin02-cre-confint-alpha-greater` | confint | lme4 | error | match |  |
| `null-lin02-cre-summary-parm` | summary | lme4 | value | match | identical |
| `null-lin02-cre-caterpillar` | caterpillar_plot | lme4 | value | match | identical |
| `null-lin02-cre-caterpillar-flags` | caterpillar_plot | lme4 | value | match | identical |
| `null-lin02-cre-caterpillar-one-sided` | caterpillar_plot | lme4 | value | match | identical |
| `null-lin02-cre-bar` | bar_plot | lme4 | value | match | identical |
| `null-lin02-cre-bar-3` | bar_plot | lme4 | value | match | identical |
