# Differential report: working tree versus the pprof 1.0.3 reference

Generated 2026-10-04 02:02:22 UTC by `validation/run-differential.R` on R version 4.4.0 (2024-04-24 ucrt), Windows 11 x64 (build 22621).
Working tree at commit 8d55614; 30 binary datasets (10 with RE and CRE fits), 15 linear datasets, seed 20261003.

## Summary

- Cases: 1230; matching: 1230; identical: 1130; mismatching: 0.
- Reference errors reproduced: 0.
- Time: reference 57 s, working tree 35 s.

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
| `diff30-firth` | logis_firth | iterative | value | match | identical |
| `diff30-firth-exact` | test | iterative | value | match | identical |
| `diff30-firth-sm` | SM_output | iterative | value | match | identical |
| `diff30-firth-gamma-score` | confint | root | value | match | identical |
| `diff01-logis-re` | logis_re | lme4 | value | match | identical |
| `diff01-logis-cre` | logis_cre | lme4 | value | match | identical |
| `diff01-logis-re-test` | test | lme4 | value | match | identical |
| `diff01-logis-re-sm` | SM_output | lme4 | value | match | identical |
| `diff01-logis-cre-test` | test | lme4 | value | match | identical |
| `diff01-logis-cre-sm` | SM_output | lme4 | value | match | identical |
| `diff02-logis-re` | logis_re | lme4 | value | match | identical |
| `diff02-logis-cre` | logis_cre | lme4 | value | match | identical |
| `diff02-logis-re-test` | test | lme4 | value | match | identical |
| `diff02-logis-re-sm` | SM_output | lme4 | value | match | identical |
| `diff02-logis-cre-test` | test | lme4 | value | match | identical |
| `diff02-logis-cre-sm` | SM_output | lme4 | value | match | identical |
| `diff03-logis-re` | logis_re | lme4 | value | match | identical |
| `diff03-logis-cre` | logis_cre | lme4 | value | match | identical |
| `diff03-logis-re-test` | test | lme4 | value | match | identical |
| `diff03-logis-re-sm` | SM_output | lme4 | value | match | identical |
| `diff03-logis-cre-test` | test | lme4 | value | match | identical |
| `diff03-logis-cre-sm` | SM_output | lme4 | value | match | identical |
| `diff04-logis-re` | logis_re | lme4 | value | match | identical |
| `diff04-logis-cre` | logis_cre | lme4 | value | match | identical |
| `diff04-logis-re-test` | test | lme4 | value | match | identical |
| `diff04-logis-re-sm` | SM_output | lme4 | value | match | identical |
| `diff04-logis-cre-test` | test | lme4 | value | match | identical |
| `diff04-logis-cre-sm` | SM_output | lme4 | value | match | identical |
| `diff05-logis-re` | logis_re | lme4 | value | match | identical |
| `diff05-logis-cre` | logis_cre | lme4 | value | match | identical |
| `diff05-logis-re-test` | test | lme4 | value | match | identical |
| `diff05-logis-re-sm` | SM_output | lme4 | value | match | identical |
| `diff05-logis-cre-test` | test | lme4 | value | match | identical |
| `diff05-logis-cre-sm` | SM_output | lme4 | value | match | identical |
| `diff06-logis-re` | logis_re | lme4 | value | match | identical |
| `diff06-logis-cre` | logis_cre | lme4 | value | match | identical |
| `diff06-logis-re-test` | test | lme4 | value | match | identical |
| `diff06-logis-re-sm` | SM_output | lme4 | value | match | identical |
| `diff06-logis-cre-test` | test | lme4 | value | match | identical |
| `diff06-logis-cre-sm` | SM_output | lme4 | value | match | identical |
| `diff07-logis-re` | logis_re | lme4 | value | match | identical |
| `diff07-logis-cre` | logis_cre | lme4 | value | match | identical |
| `diff07-logis-re-test` | test | lme4 | value | match | identical |
| `diff07-logis-re-sm` | SM_output | lme4 | value | match | identical |
| `diff07-logis-cre-test` | test | lme4 | value | match | identical |
| `diff07-logis-cre-sm` | SM_output | lme4 | value | match | identical |
| `diff08-logis-re` | logis_re | lme4 | value | match | identical |
| `diff08-logis-cre` | logis_cre | lme4 | value | match | identical |
| `diff08-logis-re-test` | test | lme4 | value | match | identical |
| `diff08-logis-re-sm` | SM_output | lme4 | value | match | identical |
| `diff08-logis-cre-test` | test | lme4 | value | match | identical |
| `diff08-logis-cre-sm` | SM_output | lme4 | value | match | identical |
| `diff09-logis-re` | logis_re | lme4 | value | match | identical |
| `diff09-logis-cre` | logis_cre | lme4 | value | match | identical |
| `diff09-logis-re-test` | test | lme4 | value | match | identical |
| `diff09-logis-re-sm` | SM_output | lme4 | value | match | identical |
| `diff09-logis-cre-test` | test | lme4 | value | match | identical |
| `diff09-logis-cre-sm` | SM_output | lme4 | value | match | identical |
| `diff10-logis-re` | logis_re | lme4 | value | match | identical |
| `diff10-logis-cre` | logis_cre | lme4 | value | match | identical |
| `diff10-logis-re-test` | test | lme4 | value | match | identical |
| `diff10-logis-re-sm` | SM_output | lme4 | value | match | identical |
| `diff10-logis-cre-test` | test | lme4 | value | match | identical |
| `diff10-logis-cre-sm` | SM_output | lme4 | value | match | identical |
| `lin01-fe` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, fitted, residuals, linear_pred |
| `lin01-fe-full` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, variance$gamma, fitted, residuals, linear_pred |
| `lin01-fe-test` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin01-fe-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin01-fe-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin01-fe-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin01-re` | linear_re | lme4 | value | match | identical |
| `lin01-cre` | linear_cre | lme4 | value | match | identical |
| `lin01-re-test` | test | lme4 | value | match | identical |
| `lin01-re-sm` | SM_output | lme4 | value | match | identical |
| `lin01-re-confint` | confint | lme4 | value | match | identical |
| `lin01-re-summary` | summary | lme4 | value | match | identical |
| `lin01-cre-test` | test | lme4 | value | match | identical |
| `lin01-cre-sm` | SM_output | lme4 | value | match | identical |
| `lin01-cre-confint` | confint | lme4 | value | match | identical |
| `lin01-cre-summary` | summary | lme4 | value | match | identical |
| `lin02-fe` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, fitted, residuals, linear_pred |
| `lin02-fe-full` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, fitted, residuals, linear_pred |
| `lin02-fe-test` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin02-fe-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `lin02-fe-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin02-fe-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin02-re` | linear_re | lme4 | value | match | identical |
| `lin02-cre` | linear_cre | lme4 | value | match | identical |
| `lin02-re-test` | test | lme4 | value | match | identical |
| `lin02-re-sm` | SM_output | lme4 | value | match | identical |
| `lin02-re-confint` | confint | lme4 | value | match | identical |
| `lin02-re-summary` | summary | lme4 | value | match | identical |
| `lin02-cre-test` | test | lme4 | value | match | identical |
| `lin02-cre-sm` | SM_output | lme4 | value | match | identical |
| `lin02-cre-confint` | confint | lme4 | value | match | identical |
| `lin02-cre-summary` | summary | lme4 | value | match | identical |
| `lin03-fe` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, fitted, residuals, linear_pred |
| `lin03-fe-full` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, variance$gamma, fitted, residuals, linear_pred |
| `lin03-fe-test` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin03-fe-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `lin03-fe-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin03-fe-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin03-re` | linear_re | lme4 | value | match | identical |
| `lin03-cre` | linear_cre | lme4 | value | match | identical |
| `lin03-re-test` | test | lme4 | value | match | identical |
| `lin03-re-sm` | SM_output | lme4 | value | match | identical |
| `lin03-re-confint` | confint | lme4 | value | match | identical |
| `lin03-re-summary` | summary | lme4 | value | match | identical |
| `lin03-cre-test` | test | lme4 | value | match | identical |
| `lin03-cre-sm` | SM_output | lme4 | value | match | identical |
| `lin03-cre-confint` | confint | lme4 | value | match | identical |
| `lin03-cre-summary` | summary | lme4 | value | match | identical |
| `lin04-fe` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, fitted, residuals, linear_pred |
| `lin04-fe-full` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, variance$gamma, fitted, residuals, linear_pred |
| `lin04-fe-test` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin04-fe-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin04-fe-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin04-fe-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin04-re` | linear_re | lme4 | value | match | identical |
| `lin04-cre` | linear_cre | lme4 | value | match | identical |
| `lin04-re-test` | test | lme4 | value | match | identical |
| `lin04-re-sm` | SM_output | lme4 | value | match | identical |
| `lin04-re-confint` | confint | lme4 | value | match | identical |
| `lin04-re-summary` | summary | lme4 | value | match | identical |
| `lin04-cre-test` | test | lme4 | value | match | identical |
| `lin04-cre-sm` | SM_output | lme4 | value | match | identical |
| `lin04-cre-confint` | confint | lme4 | value | match | identical |
| `lin04-cre-summary` | summary | lme4 | value | match | identical |
| `lin05-fe` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, fitted, residuals, linear_pred |
| `lin05-fe-full` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, variance$gamma, fitted, residuals, linear_pred |
| `lin05-fe-test` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin05-fe-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin05-fe-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin05-fe-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin05-re` | linear_re | lme4 | value | match | identical |
| `lin05-cre` | linear_cre | lme4 | value | match | identical |
| `lin05-re-test` | test | lme4 | value | match | identical |
| `lin05-re-sm` | SM_output | lme4 | value | match | identical |
| `lin05-re-confint` | confint | lme4 | value | match | identical |
| `lin05-re-summary` | summary | lme4 | value | match | identical |
| `lin05-cre-test` | test | lme4 | value | match | identical |
| `lin05-cre-sm` | SM_output | lme4 | value | match | identical |
| `lin05-cre-confint` | confint | lme4 | value | match | identical |
| `lin05-cre-summary` | summary | lme4 | value | match | identical |
| `lin06-fe` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, fitted, residuals, linear_pred |
| `lin06-fe-full` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, variance$gamma, fitted, residuals, linear_pred |
| `lin06-fe-test` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin06-fe-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `lin06-fe-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin06-fe-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin06-re` | linear_re | lme4 | value | match | identical |
| `lin06-cre` | linear_cre | lme4 | value | match | identical |
| `lin06-re-test` | test | lme4 | value | match | identical |
| `lin06-re-sm` | SM_output | lme4 | value | match | identical |
| `lin06-re-confint` | confint | lme4 | value | match | identical |
| `lin06-re-summary` | summary | lme4 | value | match | identical |
| `lin06-cre-test` | test | lme4 | value | match | identical |
| `lin06-cre-sm` | SM_output | lme4 | value | match | identical |
| `lin06-cre-confint` | confint | lme4 | value | match | identical |
| `lin06-cre-summary` | summary | lme4 | value | match | identical |
| `lin07-fe` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, fitted, residuals, linear_pred |
| `lin07-fe-full` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, variance$gamma, fitted, residuals, linear_pred |
| `lin07-fe-test` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin07-fe-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `lin07-fe-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin07-fe-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin07-re` | linear_re | lme4 | value | match | identical |
| `lin07-cre` | linear_cre | lme4 | value | match | identical |
| `lin07-re-test` | test | lme4 | value | match | identical |
| `lin07-re-sm` | SM_output | lme4 | value | match | identical |
| `lin07-re-confint` | confint | lme4 | value | match | identical |
| `lin07-re-summary` | summary | lme4 | value | match | identical |
| `lin07-cre-test` | test | lme4 | value | match | identical |
| `lin07-cre-sm` | SM_output | lme4 | value | match | identical |
| `lin07-cre-confint` | confint | lme4 | value | match | identical |
| `lin07-cre-summary` | summary | lme4 | value | match | identical |
| `lin08-fe` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, fitted, residuals, linear_pred |
| `lin08-fe-full` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, variance$gamma, fitted, residuals, linear_pred |
| `lin08-fe-test` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin08-fe-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin08-fe-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin08-fe-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin08-re` | linear_re | lme4 | value | match | identical |
| `lin08-cre` | linear_cre | lme4 | value | match | identical |
| `lin08-re-test` | test | lme4 | value | match | identical |
| `lin08-re-sm` | SM_output | lme4 | value | match | identical |
| `lin08-re-confint` | confint | lme4 | value | match | identical |
| `lin08-re-summary` | summary | lme4 | value | match | identical |
| `lin08-cre-test` | test | lme4 | value | match | identical |
| `lin08-cre-sm` | SM_output | lme4 | value | match | identical |
| `lin08-cre-confint` | confint | lme4 | value | match | identical |
| `lin08-cre-summary` | summary | lme4 | value | match | identical |
| `lin09-fe` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, fitted, residuals, linear_pred |
| `lin09-fe-full` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, variance$gamma, fitted, residuals, linear_pred |
| `lin09-fe-test` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin09-fe-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin09-fe-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin09-fe-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin09-re` | linear_re | lme4 | value | match | identical |
| `lin09-cre` | linear_cre | lme4 | value | match | identical |
| `lin09-re-test` | test | lme4 | value | match | identical |
| `lin09-re-sm` | SM_output | lme4 | value | match | identical |
| `lin09-re-confint` | confint | lme4 | value | match | identical |
| `lin09-re-summary` | summary | lme4 | value | match | identical |
| `lin09-cre-test` | test | lme4 | value | match | identical |
| `lin09-cre-sm` | SM_output | lme4 | value | match | identical |
| `lin09-cre-confint` | confint | lme4 | value | match | identical |
| `lin09-cre-summary` | summary | lme4 | value | match | identical |
| `lin10-fe` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, fitted, residuals, linear_pred |
| `lin10-fe-full` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, variance$gamma, fitted, residuals, linear_pred |
| `lin10-fe-test` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin10-fe-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin10-fe-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin10-fe-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin10-re` | linear_re | lme4 | value | match | identical |
| `lin10-cre` | linear_cre | lme4 | value | match | identical |
| `lin10-re-test` | test | lme4 | value | match | identical |
| `lin10-re-sm` | SM_output | lme4 | value | match | identical |
| `lin10-re-confint` | confint | lme4 | value | match | identical |
| `lin10-re-summary` | summary | lme4 | value | match | identical |
| `lin10-cre-test` | test | lme4 | value | match | identical |
| `lin10-cre-sm` | SM_output | lme4 | value | match | identical |
| `lin10-cre-confint` | confint | lme4 | value | match | identical |
| `lin10-cre-summary` | summary | lme4 | value | match | identical |
| `lin11-fe` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, fitted, residuals, linear_pred |
| `lin11-fe-full` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, variance$gamma, fitted, residuals, linear_pred |
| `lin11-fe-test` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin11-fe-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin11-fe-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin11-fe-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin11-re` | linear_re | lme4 | value | match | identical |
| `lin11-cre` | linear_cre | lme4 | value | match | identical |
| `lin11-re-test` | test | lme4 | value | match | identical |
| `lin11-re-sm` | SM_output | lme4 | value | match | identical |
| `lin11-re-confint` | confint | lme4 | value | match | identical |
| `lin11-re-summary` | summary | lme4 | value | match | identical |
| `lin11-cre-test` | test | lme4 | value | match | identical |
| `lin11-cre-sm` | SM_output | lme4 | value | match | identical |
| `lin11-cre-confint` | confint | lme4 | value | match | identical |
| `lin11-cre-summary` | summary | lme4 | value | match | identical |
| `lin12-fe` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, fitted, residuals, linear_pred |
| `lin12-fe-full` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, variance$gamma, fitted, residuals, linear_pred |
| `lin12-fe-test` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin12-fe-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin12-fe-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin12-fe-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin12-re` | linear_re | lme4 | value | match | identical |
| `lin12-cre` | linear_cre | lme4 | value | match | identical |
| `lin12-re-test` | test | lme4 | value | match | identical |
| `lin12-re-sm` | SM_output | lme4 | value | match | identical |
| `lin12-re-confint` | confint | lme4 | value | match | identical |
| `lin12-re-summary` | summary | lme4 | value | match | identical |
| `lin12-cre-test` | test | lme4 | value | match | identical |
| `lin12-cre-sm` | SM_output | lme4 | value | match | identical |
| `lin12-cre-confint` | confint | lme4 | value | match | identical |
| `lin12-cre-summary` | summary | lme4 | value | match | identical |
| `lin13-fe` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, fitted, residuals, linear_pred |
| `lin13-fe-full` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, variance$gamma, fitted, residuals, linear_pred |
| `lin13-fe-test` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin13-fe-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `lin13-fe-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin13-fe-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin13-re` | linear_re | lme4 | value | match | identical |
| `lin13-cre` | linear_cre | lme4 | value | match | identical |
| `lin13-re-test` | test | lme4 | value | match | identical |
| `lin13-re-sm` | SM_output | lme4 | value | match | identical |
| `lin13-re-confint` | confint | lme4 | value | match | identical |
| `lin13-re-summary` | summary | lme4 | value | match | identical |
| `lin13-cre-test` | test | lme4 | value | match | identical |
| `lin13-cre-sm` | SM_output | lme4 | value | match | identical |
| `lin13-cre-confint` | confint | lme4 | value | match | identical |
| `lin13-cre-summary` | summary | lme4 | value | match | identical |
| `lin14-fe` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, fitted, residuals, linear_pred |
| `lin14-fe-full` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, variance$gamma, fitted, residuals, linear_pred |
| `lin14-fe-test` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin14-fe-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Obs, OE$OE_direct$Exp |
| `lin14-fe-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin14-fe-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin14-re` | linear_re | lme4 | value | match | identical |
| `lin14-cre` | linear_cre | lme4 | value | match | identical |
| `lin14-re-test` | test | lme4 | value | match | identical |
| `lin14-re-sm` | SM_output | lme4 | value | match | identical |
| `lin14-re-confint` | confint | lme4 | value | match | identical |
| `lin14-re-summary` | summary | lme4 | value | match | identical |
| `lin14-cre-test` | test | lme4 | value | match | identical |
| `lin14-cre-sm` | SM_output | lme4 | value | match | identical |
| `lin14-cre-confint` | confint | lme4 | value | match | identical |
| `lin14-cre-summary` | summary | lme4 | value | match | identical |
| `lin15-fe` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, fitted, residuals, linear_pred |
| `lin15-fe-full` | linear_fe | closed_form | value | match | within tolerance: coefficient$beta, coefficient$gamma, variance$beta, variance$gamma, fitted, residuals, linear_pred |
| `lin15-fe-test` | test | closed_form | value | match | within tolerance: $p value, $stat |
| `lin15-fe-sm` | SM_output | closed_form | value | match | within tolerance: indirect.difference, direct.difference, OE$OE_indirect$Exp, OE$OE_direct$Exp |
| `lin15-fe-confint` | confint | closed_form | value | match | within tolerance: CI.indirect$Indirect.Difference, CI.indirect$indirect.Lower, CI.indirect$indirect.Upper, CI.direct$Direct.Difference, CI.direct$direct.Lower, CI.direct$direct.Upper |
| `lin15-fe-summary` | summary | closed_form | value | match | within tolerance: $Estimate, $Std.Error, $Stat, $CI.Lower, $CI.Upper |
| `lin15-re` | linear_re | lme4 | value | match | identical |
| `lin15-cre` | linear_cre | lme4 | value | match | identical |
| `lin15-re-test` | test | lme4 | value | match | identical |
| `lin15-re-sm` | SM_output | lme4 | value | match | identical |
| `lin15-re-confint` | confint | lme4 | value | match | identical |
| `lin15-re-summary` | summary | lme4 | value | match | identical |
| `lin15-cre-test` | test | lme4 | value | match | identical |
| `lin15-cre-sm` | SM_output | lme4 | value | match | identical |
| `lin15-cre-confint` | confint | lme4 | value | match | identical |
| `lin15-cre-summary` | summary | lme4 | value | match | identical |
