# Equivalence report: package under test versus the pprof 1.0.3 reference

Generated 2026-10-04 16:11:33 UTC by `validation/run-reference.R` on R version 4.4.0 (2024-04-24 ucrt), Windows 11 x64 (build 22621).
Package under test: pprof 1.0.3 from the working tree at commit 6fc0a91.
Fixtures: core set generated at 8821723, full set generated at 8821723.

## Summary

- Cases: 335 (core 303, full 32).
- Compared and matching: 335; failing: 0; skipped: 0.
- Largest absolute difference over all compared values: 2e-11; largest relative difference: 3.92.
- Long double vectors stored as signatures: 718; bitwise identical (same checksum of every value's bits): 703.
- Reference errors reproduced: 17.
- Per-case expectations for Class A fixes (tests/testthat/helper-reference-overrides.R): 21, all compared against values derived from fixtures where the reference is right.

## Providers within tolerance of a flag threshold

A provider is listed when its reference p-value lies within the probability tolerance of alpha = 1 - level (brief §3.4). Its flag may differ between implementations without counting as a failure.

None.

## Cases

Bitwise signatures: of the long double vectors stored as signatures, how many are bitwise identical to the reference.

| Set | Case | Function | Tier | Expected outcome | Expectation | Iterations | Max abs diff | Max rel diff | Bitwise signatures | Status |
|---|---|---|---|---|---|---|---|---|---|---|
| core | `logis_fe-binary-columns` | logis_fe | iterative | value |  | 8 | 0 | 0 | 13 of 13 | compared |
| core | `logis_fe-binary-formula` | logis_fe | iterative | value |  | 8 | 0 | 0 | 13 of 13 | compared |
| core | `logis_fe-binary-vectors` | logis_fe | iterative | value |  | 8 | 0 | 0 | 13 of 13 | compared |
| core | `logis_fe-binary-serbin-stop-beta` | logis_fe | iterative | value |  | 8 | 0 | 0 | 13 of 13 | compared |
| core | `logis_fe-binary-serbin-stop-relch` | logis_fe | iterative | value |  | 9 | 0 | 0 | 13 of 13 | compared |
| core | `logis_fe-binary-serbin-stop-ratch` | logis_fe | iterative | value |  | 9 | 0 | 0 | 13 of 13 | compared |
| core | `logis_fe-binary-serbin-stop-all` | logis_fe | iterative | value |  | 9 | 0 | 0 | 13 of 13 | compared |
| core | `logis_fe-binary-ban` | logis_fe | iterative | value |  | 8 | 0 | 0 | 13 of 13 | compared |
| core | `logis_fe-binary-ban-stop-beta` | logis_fe | iterative | value |  | 11 | 0 | 0 | 13 of 13 | compared |
| core | `logis_fe-binary-serbin-nobacktrack` | logis_fe | iterative | value |  | 8 | 0 | 0 | 13 of 13 | compared |
| core | `logis_fe-binary-ban-nobacktrack` | logis_fe | iterative | value |  | 8 | 0 | 0 | 13 of 13 | compared |
| core | `logis_fe-binary-serbin-tight` | logis_fe | iterative | value |  | 14 | 0 | 0 | 13 of 13 | compared |
| core | `logis_fe-binary-ban-tight` | logis_fe | iterative | value |  | 22 | 0 | 0 | 13 of 13 | compared |
| core | `logis_fe-binary-cutoff60` | logis_fe | iterative | value |  | 8 | 0 | 0 | 13 of 13 | compared |
| core | `logis_fe-binary-bound5` | logis_fe | iterative | value |  | 8 | 0 | 0 | 13 of 13 | compared |
| core | `logis_fe-binary-quiet` | logis_fe | iterative | value |  | 8 | 0 | 0 | 13 of 13 | compared |
| core | `logis_fe-binary-serbin-maxiter3` | logis_fe | iterative | value |  | 4 | 1.11e-16 | 1.2e-16 | 13 of 13 | compared |
| core | `logis_fe-binary-ban-maxiter3` | logis_fe | iterative | value |  | 3 | 0 | 0 | 13 of 13 | compared |
| core | `logis_fe-binary-ban-backtrack2` | logis_fe | iterative | error | D-23 | 0 |  |  |  | compared |
| core | `logis_fe-binary-bad-method` | logis_fe | exact | error |  |  |  |  |  | compared |
| core | `logis_fe-binary-bad-stop` | logis_fe | exact | error |  |  |  |  |  | compared |
| core | `logis_fe-screening-cutoff10` | logis_fe | iterative | value |  | 5 | 0 | 0 |  | compared |
| core | `logis_fe-screening-cutoff5` | logis_fe | iterative | value |  | 5 | 0 | 0 |  | compared |
| core | `logis_fe-screening-cutoff11` | logis_fe | iterative | value |  | 4 | 0 | 0 |  | compared |
| core | `logis_fe-screening-onecov` | logis_fe | iterative | value |  | 5 | 0 | 0 |  | compared |
| core | `logis_fe-screening-twocov` | logis_fe | iterative | value |  | 5 | 0 | 0 |  | compared |
| core | `logis_fe-screening-x2` | logis_fe | iterative | value |  | 5 | 0 | 0 |  | compared |
| core | `logis_fe-extreme` | logis_fe | iterative | value |  | 7 | 0 | 0 |  | compared |
| core | `logis_fe-extreme-chr` | logis_fe | iterative | value |  | 7 | 0 | 0 |  | compared |
| core | `logis_fe-extreme-fac` | logis_fe | iterative | value |  | 7 | 0 | 0 |  | compared |
| core | `logis_fe-extreme-int` | logis_fe | iterative | value |  | 7 | 0 | 0 |  | compared |
| core | `logis_fe-extreme-hospital` | logis_fe | iterative | value |  | 7 | 0 | 0 |  | compared |
| core | `logis_fe-separation` | logis_fe | iterative | value |  | 5 | 0 | 0 |  | compared |
| core | `logis_fe-collinear` | logis_fe | iterative | value |  | 4 | 0 | 0 |  | compared |
| core | `logis_fe-constant` | logis_fe | iterative | error |  | 4 |  |  |  | compared |
| core | `logis_fe-factors-spaces-formula` | logis_fe | iterative | value | D-18 | 4 | 1.11e-16 | 1.57e-16 |  | compared |
| core | `logis_fe-factors-nospaces-formula` | logis_fe | iterative | value |  | 4 | 1.11e-16 | 1.57e-16 |  | compared |
| core | `logis_fe-factors-unused-columns` | logis_fe | iterative | error |  | 4 |  |  |  | compared |
| core | `logis_fe-terms-logw` | logis_fe | iterative | value | D-18 | 4 | 0 | 0 |  | compared |
| core | `logis_fe-terms-z1z2` | logis_fe | iterative | value | D-18 | 4 | 0 | 0 |  | compared |
| core | `logis_fe-terms-z12` | logis_fe | iterative | value | D-18 | 4 | 0 | 0 |  | compared |
| core | `logis_fe-terms-logw-columns` | logis_fe | iterative | value |  | 4 | 0 | 0 |  | compared |
| core | `logis_fe-terms-z1z2-columns` | logis_fe | iterative | value |  | 4 | 0 | 0 |  | compared |
| core | `logis_fe-terms-z12-columns` | logis_fe | iterative | value |  | 4 | 0 | 0 |  | compared |
| core | `logis_fe-missing-formula` | logis_fe | iterative | value |  | 4 | 0 | 0 |  | compared |
| core | `logis_fe-missing-columns` | logis_fe | iterative | value |  | 4 | 0 | 0 |  | compared |
| core | `logis_fe-unequal` | logis_fe | iterative | value |  | 5 | 0 | 0 |  | compared |
| core | `logis_fe-rare` | logis_fe | iterative | value |  | 6 | 0 | 0 |  | compared |
| core | `logis_fe-common` | logis_fe | iterative | value |  | 6 | 0 | 0 |  | compared |
| core | `logis_fe-d04` | logis_fe | iterative | value |  | 4 | 0 | 0 |  | compared |
| core | `logis_fe-d04-double` | logis_fe | iterative | value |  | 4 | 0 | 0 |  | compared |
| core | `logis_fe-cutoff5` | logis_fe | iterative | value |  | 4 | 0 | 0 |  | compared |
| core | `logis_firth-binary-columns` | logis_firth | iterative | value |  | 16 | 0 | 0 | 13 of 13 | compared |
| core | `logis_firth-small-tight` | logis_firth | iterative | value |  | 10 | 0 | 0 |  | compared |
| core | `logis_firth-extreme` | logis_firth | iterative | value |  | 7 | 0 | 0 |  | compared |
| core | `logis_firth-screening` | logis_firth | iterative | value |  | 5 | 0 | 0 |  | compared |
| core | `linear_fe-linear-columns` | linear_fe | closed_form | value |  |  | 4.55e-13 | 3.92 | 8 of 11 | compared |
| core | `linear_fe-linear-columns-full` | linear_fe | closed_form | value |  |  | 4.55e-13 | 3.92 | 8 of 11 | compared |
| core | `linear_fe-linear-formula` | linear_fe | closed_form | value |  |  | 4.55e-13 | 3.92 | 8 of 11 | compared |
| core | `linear_fe-linear-vectors` | linear_fe | closed_form | value |  |  | 4.55e-13 | 3.92 | 8 of 11 | compared |
| core | `linear_fe-ecls` | linear_fe | closed_form | value |  |  | 1.27e-11 | 0.918 | 5 of 8 | compared |
| core | `linear_fe-syn` | linear_fe | closed_form | value |  |  | 7.55e-15 | 5.15e-12 |  | compared |
| core | `linear_fe-syn-full` | linear_fe | closed_form | value |  |  | 7.55e-15 | 5.15e-12 |  | compared |
| core | `linear_fe-bad-option` | linear_fe | exact | error |  |  |  |  |  | compared |
| core | `linear_fe-syn-int` | linear_fe | closed_form | value |  |  | 7.55e-15 | 5.15e-12 |  | compared |
| core | `linear_fe-funnel-full` | linear_fe | closed_form | value |  |  | 3.02e-14 | 1.03e-10 |  | compared |
| core | `linear_re-linear-columns` | linear_re | lme4 | value |  |  | 0 | 0 | 13 of 13 | compared |
| core | `linear_re-linear-formula` | linear_re | lme4 | value |  |  | 0 | 0 | 13 of 13 | compared |
| core | `linear_re-linear-ml` | linear_re | lme4 | value |  |  | 0 | 0 | 13 of 13 | compared |
| core | `linear_re-ecls` | linear_re | lme4 | value |  |  | 0 | 0 | 10 of 10 | compared |
| core | `linear_re-syn` | linear_re | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `logis_re-binary-columns` | logis_re | lme4 | value |  |  | 0 | 0 | 12 of 12 | compared |
| core | `logis_re-extreme` | logis_re | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `linear_cre-linear` | linear_cre | lme4 | value |  |  | 0 | 0 | 15 of 15 | compared |
| core | `linear_cre-missing` | linear_cre | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `logis_cre-binary` | logis_cre | lme4 | value |  |  | 0 | 0 | 14 of 14 | compared |
| core | `logis_cre-extreme` | logis_cre | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `linear_re-linear-control` | linear_re | lme4 | value |  |  | 0 | 0 | 13 of 13 | compared |
| core | `logis_re-extreme-control` | logis_re | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `linear_cre-linear-control` | linear_cre | lme4 | value |  |  | 0 | 0 | 15 of 15 | compared |
| core | `logis_cre-extreme-control` | logis_cre | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `linear_re-vectors-matrix` | linear_re | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `linear_re-vectors-df` | linear_re | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `linear_re-vectors-chr-df` | linear_re | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `logis_re-vectors-matrix` | logis_re | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `logis_re-vectors-chr-df` | logis_re | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `linear_re-vectors-chr-matrix` | linear_re | exact | error |  |  |  |  |  | compared |
| core | `linear_re-vectors-incomplete` | linear_re | exact | error |  |  |  |  |  | compared |
| core | `logis_re-extreme-chr` | logis_re | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `logis_cre-extreme-int` | logis_cre | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `test-binary-exact-two.sided` | test | iterative | value |  |  | 0 | 0 |  | compared |
| core | `test-binary-bootstrap-two.sided` | test | iterative | value |  |  | 0 | 0 |  | compared |
| core | `test-binary-score-two.sided` | test | iterative | value |  |  | 0 | 0 |  | compared |
| core | `test-binary-score-standard-two.sided` | test | iterative | value |  |  | 0 | 0 |  | compared |
| core | `test-binary-wald-two.sided` | test | iterative | value |  |  | 0 | 0 |  | compared |
| core | `test-binary-exact-greater` | test | iterative | value |  |  | 0 | 0 |  | compared |
| core | `test-binary-bootstrap-greater` | test | iterative | value |  |  | 0 | 0 |  | compared |
| core | `test-binary-score-greater` | test | iterative | value |  |  | 0 | 0 |  | compared |
| core | `test-binary-score-standard-greater` | test | iterative | value |  |  | 0 | 0 |  | compared |
| core | `test-binary-wald-greater` | test | iterative | value |  |  | 0 | 0 |  | compared |
| core | `test-binary-exact-less` | test | iterative | value |  |  | 0 | 0 |  | compared |
| core | `test-binary-bootstrap-less` | test | iterative | value |  |  | 0 | 0 |  | compared |
| core | `test-binary-score-less` | test | iterative | value |  |  | 0 | 0 |  | compared |
| core | `test-binary-score-standard-less` | test | iterative | value |  |  | 0 | 0 |  | compared |
| core | `test-binary-wald-less` | test | iterative | value |  |  | 0 | 0 |  | compared |
| core | `test-binary-bootstrap-two.sided-seed2` | test | iterative | value |  |  | 0 | 0 |  | compared |
| core | `test-binary-bootstrap-two.sided-seed3` | test | iterative | value |  |  | 0 | 0 |  | compared |
| core | `test-binary-exact-null0` | test | iterative | value |  |  | 0 | 0 |  | compared |
| core | `test-binary-exact-null-negative` | test | iterative | value |  |  | 0 | 0 |  | compared |
| core | `test-binary-exact-null-integer` | test | iterative | value |  |  | 0 | 0 |  | compared |
| core | `test-binary-wald-null0` | test | iterative | value |  |  | 0 | 0 |  | compared |
| core | `test-binary-exact-level90` | test | iterative | value |  |  | 0 | 0 |  | compared |
| core | `test-binary-wald-level90` | test | iterative | value |  |  | 0 | 0 |  | compared |
| core | `test-binary-exact-parm` | test | iterative | value |  |  | 0 | 0 |  | compared |
| core | `test-binary-wald-parm` | test | iterative | value |  |  | 0 | 0 |  | compared |
| core | `test-binary-score-standard-parm` | test | iterative | value |  |  | 0 | 0 |  | compared |
| core | `test-binary-robust-wald` | test | exact | error | D-06 |  |  |  |  | compared |
| core | `test-binary-bad-null` | test | exact | error |  |  |  |  |  | compared |
| core | `test-extreme-exact` | test | iterative | value |  |  | 0 | 0 |  | compared |
| core | `test-extreme-score-standard` | test | iterative | value |  |  | 0 | 0 |  | compared |
| core | `test-extreme-wald` | test | iterative | value |  |  | 0 | 0 |  | compared |
| core | `test-extreme-bootstrap` | test | iterative | value |  |  | 0 | 0 |  | compared |
| core | `test-extreme-chr-exact-parm` | test | iterative | value |  |  | 0 | 0 |  | compared |
| core | `test-extreme-int-parm` | test | iterative | value | D-27 |  | 0 | 0 |  | compared |
| core | `test-d04-score-standard` | test | exact | error | D-04 |  |  |  |  | compared |
| core | `test-d04-score-standard-others` | test | exact | value |  |  | 0 | 0 |  | compared |
| core | `test-firth-exact` | test | iterative | value |  |  | 0 | 0 |  | compared |
| core | `test-firth-wald` | test | iterative | value |  |  | 0 | 0 |  | compared |
| core | `SM_output-binary-default` | SM_output | iterative | value |  |  | 0 | 0 |  | compared |
| core | `SM_output-binary-direct` | SM_output | iterative | value |  |  | 0 | 0 |  | compared |
| core | `SM_output-binary-both` | SM_output | iterative | value |  |  | 0 | 0 |  | compared |
| core | `SM_output-binary-ratio` | SM_output | iterative | value |  |  | 0 | 0 |  | compared |
| core | `SM_output-binary-rate` | SM_output | iterative | value |  |  | 0 | 0 |  | compared |
| core | `SM_output-binary-null0` | SM_output | iterative | value |  |  | 0 | 0 |  | compared |
| core | `SM_output-binary-null-integer` | SM_output | iterative | value | D-14 |  | 0 | 0 |  | compared |
| core | `SM_output-binary-parm` | SM_output | iterative | value |  |  | 0 | 0 |  | compared |
| core | `SM_output-extreme-both` | SM_output | iterative | value |  |  | 0 | 0 |  | compared |
| core | `SM_output-extreme-chr-both` | SM_output | iterative | value |  |  | 0 | 0 |  | compared |
| core | `SM_output-firth-both` | SM_output | iterative | value |  |  | 0 | 0 |  | compared |
| core | `confint-binary-gamma-exact` | confint | root | value |  |  | 0 | 0 |  | compared |
| core | `confint-binary-sm-exact` | confint | root | value |  |  | 0 | 0 |  | compared |
| core | `confint-binary-gamma-score` | confint | root | value |  |  | 0 | 0 |  | compared |
| core | `confint-binary-sm-score` | confint | root | value |  |  | 0 | 0 |  | compared |
| core | `confint-binary-gamma-wald` | confint | iterative | value |  |  | 0 | 0 |  | compared |
| core | `confint-binary-sm-wald` | confint | iterative | value |  |  | 0 | 0 |  | compared |
| core | `confint-binary-sm-exact-greater` | confint | root | value |  |  | 0 | 0 |  | compared |
| core | `confint-binary-sm-exact-less` | confint | root | value |  |  | 0 | 0 |  | compared |
| core | `confint-binary-sm-exact-level90` | confint | root | value |  |  | 0 | 0 |  | compared |
| core | `confint-binary-gamma-exact-parm` | confint | root | value |  |  | 0 | 0 |  | compared |
| core | `confint-binary-sm-exact-parm` | confint | root | value |  |  | 0 | 0 |  | compared |
| core | `confint-binary-gamma-greater` | confint | exact | error |  |  |  |  |  | compared |
| core | `confint-extreme-gamma-exact` | confint | root | value |  |  | 0 | 0 |  | compared |
| core | `confint-extreme-gamma-score` | confint | root | value |  |  | 0 | 0 |  | compared |
| core | `confint-extreme-sm-exact` | confint | root | value |  |  | 0 | 0 |  | compared |
| core | `confint-extreme-chr-sm-exact` | confint | root | value | D-19 |  | 0 | 0 |  | compared |
| core | `confint-extreme-chr-gamma-exact` | confint | root | value | D-19 |  | 0 | 0 |  | compared |
| core | `confint-extreme-fac-gamma-exact` | confint | root | value | D-28 |  | 0 | 0 |  | compared |
| core | `confint-extreme-hospital-sm-direct` | confint | root | value | D-29 |  | 0 | 0 |  | compared |
| core | `confint-firth-sm-exact` | confint | root | value |  |  | 0 | 0 |  | compared |
| core | `summary-binary-wald` | summary | iterative | value |  |  | 0 | 0 |  | compared |
| core | `summary-binary-lr` | summary | iterative | value |  |  | 0 | 0 |  | compared |
| core | `summary-binary-score` | summary | iterative | value |  |  | 0 | 0 |  | compared |
| core | `summary-binary-wald-parm` | summary | iterative | value |  |  | 0 | 0 |  | compared |
| core | `summary-binary-wald-level90` | summary | iterative | value |  |  | 0 | 0 |  | compared |
| core | `summary-binary-lr-parm` | summary | iterative | value |  |  | 0 | 0 |  | compared |
| core | `summary-screening-onecov-lr` | summary | exact | error |  |  |  |  |  | compared |
| core | `summary-screening-twocov-lr` | summary | iterative | value | D-30 |  | 0 | 0 |  | compared |
| core | `summary-cutoff5-lr` | summary | exact | error |  |  |  |  |  | compared |
| core | `summary-firth-wald` | summary | iterative | value |  |  | 0 | 0 |  | compared |
| core | `plot-binary-score` | plot | iterative | value |  |  | 0 | 0 |  | compared |
| core | `plot-binary-score-two-levels` | plot | iterative | value |  |  | 0 | 0 |  | compared |
| core | `plot-binary-exact` | plot | exact | error |  |  |  |  |  | compared |
| core | `plot-binary-null-integer` | plot | iterative | value | D-14 |  | 0 | 0 |  | compared |
| core | `plot-binary-null0` | plot | iterative | value |  |  | 0 | 0 |  | compared |
| core | `test-linear-simplified-two.sided` | test | closed_form | value |  |  | 2.78e-14 | 3.93e-13 |  | compared |
| core | `test-linear-simplified-greater` | test | closed_form | value |  |  | 2.78e-14 | 3.93e-13 |  | compared |
| core | `test-linear-simplified-less` | test | closed_form | value |  |  | 2.78e-14 | 3.93e-13 |  | compared |
| core | `confint-linear-simplified-gamma` | confint | closed_form | value |  |  | 2.44e-15 | 2.86e-13 |  | compared |
| core | `confint-linear-simplified-sm` | confint | closed_form | value |  |  | 3.22e-15 | 3.4e-13 |  | compared |
| core | `test-linear-full-two.sided` | test | closed_form | value |  |  | 2.78e-14 | 3.93e-13 |  | compared |
| core | `test-linear-full-greater` | test | closed_form | value |  |  | 2.78e-14 | 3.93e-13 |  | compared |
| core | `test-linear-full-less` | test | closed_form | value |  |  | 2.78e-14 | 3.93e-13 |  | compared |
| core | `confint-linear-full-gamma` | confint | closed_form | value |  |  | 2.44e-15 | 2.88e-13 |  | compared |
| core | `confint-linear-full-sm` | confint | closed_form | value |  |  | 3.22e-15 | 3.4e-13 |  | compared |
| core | `test-linear-null-mean` | test | closed_form | value |  |  | 2.18e-14 | 2.1e-13 |  | compared |
| core | `test-linear-null0` | test | closed_form | value |  |  | 2.22e-14 | 5.42e-14 |  | compared |
| core | `test-linear-parm` | test | closed_form | value |  |  | 1.15e-14 | 4.83e-14 |  | compared |
| core | `test-linear-bad-null` | test | exact | error |  |  |  |  |  | compared |
| core | `SM_output-linear-indirect` | SM_output | closed_form | value |  |  | 2.56e-13 | 1.7e-12 |  | compared |
| core | `SM_output-linear-direct` | SM_output | closed_form | value |  |  | 2e-11 | 3.4e-13 |  | compared |
| core | `SM_output-linear-both-mean` | SM_output | closed_form | value |  |  | 2e-11 | 4.19e-13 |  | compared |
| core | `SM_output-linear-both-null0` | SM_output | closed_form | value |  |  | 2e-11 | 8.18e-14 |  | compared |
| core | `confint-linear-simplified-sm-greater` | confint | closed_form | value |  |  | 3.22e-15 | 3.4e-13 |  | compared |
| core | `confint-linear-simplified-sm-less` | confint | closed_form | value |  |  | 3.22e-15 | 3.4e-13 |  | compared |
| core | `confint-linear-gamma-greater` | confint | exact | error |  |  |  |  |  | compared |
| core | `summary-linear` | summary | closed_form | value |  |  | 3.69e-13 | 5.7e-15 |  | compared |
| core | `summary-linear-parm` | summary | closed_form | value |  |  | 1.42e-13 | 2.64e-15 |  | compared |
| core | `summary-linear-level90` | summary | closed_form | value |  |  | 3.69e-13 | 5.57e-15 |  | compared |
| core | `plot-linear` | plot | closed_form | value |  |  | 2.56e-13 | 1.7e-12 |  | compared |
| core | `plot-linear-two-levels` | plot | closed_form | value |  |  | 2.56e-13 | 1.7e-12 |  | compared |
| core | `test-linear-syn` | test | closed_form | value |  |  | 6.22e-15 | 7.43e-13 |  | compared |
| core | `SM_output-linear-syn` | SM_output | closed_form | value |  |  | 1.62e-12 | 7.49e-13 |  | compared |
| core | `confint-linear-syn-sm` | confint | closed_form | value |  |  | 1.33e-15 | 7.49e-13 |  | compared |
| core | `test-linear-null-integer` | test | closed_form | value | D-14 |  | 2.22e-14 | 5.42e-14 |  | compared |
| core | `SM_output-linear-null-integer` | SM_output | closed_form | value | D-14 |  | 2e-11 | 8.18e-14 |  | compared |
| core | `confint-linear-null-integer` | confint | closed_form | value | D-14 |  | 2.66e-15 | 2.91e-13 |  | compared |
| core | `plot-linear-null-integer` | plot | closed_form | value | D-14 |  | 1.99e-13 | 8.18e-14 |  | compared |
| core | `confint-linear-null0` | confint | closed_form | value |  |  | 2.66e-15 | 2.91e-13 |  | compared |
| core | `plot-linear-null0` | plot | closed_form | value |  |  | 1.99e-13 | 8.18e-14 |  | compared |
| core | `confint-linear-level90` | confint | closed_form | value |  |  | 3.22e-15 | 3.4e-13 |  | compared |
| core | `confint-linear-full-sm-greater` | confint | closed_form | value |  |  | 3.22e-15 | 3.4e-13 |  | compared |
| core | `confint-linear-full-sm-less` | confint | closed_form | value |  |  | 3.22e-15 | 3.4e-13 |  | compared |
| core | `plot-linear-null-mean` | plot | closed_form | value |  |  | 1.98e-13 | 4.19e-13 |  | compared |
| core | `plot-linear-full` | plot | closed_form | value |  |  | 2.56e-13 | 1.7e-12 |  | compared |
| core | `plot-linear-funnel-full` | plot | closed_form | value |  |  | 2.13e-13 | 1.66e-13 |  | compared |
| core | `SM_output-linear-parm` | SM_output | closed_form | value |  |  | 1e-11 | 1.29e-14 |  | compared |
| core | `test-linear-syn-int` | test | closed_form | value |  |  | 6.22e-15 | 7.43e-13 |  | compared |
| core | `test-linear-syn-int-parm` | test | closed_form | value | D-27 |  | 4e-15 | 7.43e-13 |  | compared |
| core | `test-linear-re-two.sided` | test | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `test-linear-re-greater` | test | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `test-linear-re-less` | test | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `SM_output-linear-re-both` | SM_output | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `confint-linear-re-alpha` | confint | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `confint-linear-re-sm` | confint | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `summary-linear-re` | summary | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `test-logis-re-two.sided` | test | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `test-logis-re-greater` | test | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `test-logis-re-less` | test | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `SM_output-logis-re-both` | SM_output | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `confint-logis-re-alpha` | confint | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `confint-logis-re-sm` | confint | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `summary-logis-re` | summary | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `test-linear-cre-two.sided` | test | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `test-linear-cre-greater` | test | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `test-linear-cre-less` | test | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `SM_output-linear-cre-both` | SM_output | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `confint-linear-cre-alpha` | confint | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `confint-linear-cre-sm` | confint | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `summary-linear-cre` | summary | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `test-logis-cre-two.sided` | test | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `test-logis-cre-greater` | test | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `test-logis-cre-less` | test | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `SM_output-logis-cre-both` | SM_output | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `confint-logis-cre-alpha` | confint | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `confint-logis-cre-sm` | confint | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `summary-logis-cre` | summary | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `test-logis-re-extreme-two.sided` | test | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `test-logis-re-extreme-greater` | test | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `test-logis-re-extreme-less` | test | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `SM_output-logis-re-extreme-both` | SM_output | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `confint-logis-re-extreme-alpha` | confint | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `confint-logis-re-extreme-sm` | confint | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `summary-logis-re-extreme` | summary | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `test-logis-cre-extreme-two.sided` | test | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `test-logis-cre-extreme-greater` | test | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `test-logis-cre-extreme-less` | test | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `SM_output-logis-cre-extreme-both` | SM_output | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `confint-logis-cre-extreme-alpha` | confint | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `confint-logis-cre-extreme-sm` | confint | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `summary-logis-cre-extreme` | summary | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `test-linear-re-null` | test | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `confint-logis-re-extreme-sm-greater` | confint | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `confint-linear-cre-missing-sm` | confint | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `confint-linear-re-sm-greater` | confint | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `confint-linear-re-sm-less` | confint | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `confint-logis-re-sm-less` | confint | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `confint-linear-cre-sm-greater` | confint | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `confint-linear-cre-sm-less` | confint | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `confint-logis-cre-sm-less` | confint | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `confint-linear-re-alpha-level90` | confint | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `confint-logis-re-alpha-level90` | confint | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `confint-linear-cre-sm-level90` | confint | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `confint-logis-cre-sm-level90` | confint | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `test-logis-re-parm-level90` | test | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `test-linear-cre-parm-level90` | test | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `test-logis-cre-parm-level90` | test | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `SM_output-linear-re-parm` | SM_output | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `SM_output-logis-re-parm` | SM_output | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `summary-linear-re-parm-level90` | summary | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `summary-logis-re-parm-level90` | summary | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `summary-linear-cre-parm-level90` | summary | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `summary-logis-cre-parm-level90` | summary | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `summary-linear-re-parm-intercept-capital` | summary | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `test-linear-re-syn-parm` | test | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `SM_output-linear-re-syn-parm` | SM_output | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `confint-linear-re-syn-sm-parm` | confint | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `confint-linear-re-syn-alpha-parm` | confint | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `summary-linear-re-syn` | summary | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `test-logis-re-extreme-chr` | test | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `SM_output-logis-re-extreme-chr` | SM_output | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `confint-logis-re-extreme-chr-sm` | confint | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `test-logis-cre-extreme-int-parm` | test | lme4 | value | D-27 |  | 0 | 0 |  | compared |
| core | `caterpillar-binary-ratio` | caterpillar_plot | iterative | value |  |  | 0 | 0 |  | compared |
| core | `caterpillar-binary-rate-flags` | caterpillar_plot | iterative | value |  |  | 0 | 0 |  | compared |
| core | `caterpillar-linear` | caterpillar_plot | closed_form | value |  |  | 3.16e-15 | 3.23e-13 |  | compared |
| core | `caterpillar-logis-re-extreme` | caterpillar_plot | lme4 | value |  |  | 0 | 0 |  | compared |
| core | `caterpillar-gamma` | caterpillar_plot | exact | error |  |  |  |  |  | compared |
| core | `bar_plot-binary` | bar_plot | iterative | value |  |  | 0 | 0 |  | compared |
| core | `bar_plot-linear` | bar_plot | closed_form | value |  |  | 0 | 0 |  | compared |
| core | `data_check-binary` | data_check | exact | value |  |  | 0 | 0 |  | compared |
| core | `data_check-missing` | data_check | exact | error |  |  |  |  |  | compared |
| core | `data_check-collinear` | data_check | exact | value |  |  | 0 | 0 |  | compared |
| core | `data_check-constant` | data_check | exact | error |  |  |  |  |  | compared |
| full | `logis_fe-binary-grid-serbin-or-bt` | logis_fe | iterative | value |  | 12 | 0 | 0 | 13 of 13 | compared |
| full | `logis_fe-binary-grid-serbin-or-nobt` | logis_fe | iterative | value |  | 12 | 0 | 0 | 13 of 13 | compared |
| full | `logis_fe-binary-grid-serbin-beta-bt` | logis_fe | iterative | value |  | 12 | 0 | 0 | 13 of 13 | compared |
| full | `logis_fe-binary-grid-serbin-beta-nobt` | logis_fe | iterative | value |  | 12 | 0 | 0 | 13 of 13 | compared |
| full | `logis_fe-binary-grid-serbin-relch-bt` | logis_fe | iterative | value |  | 14 | 0 | 0 | 13 of 13 | compared |
| full | `logis_fe-binary-grid-serbin-relch-nobt` | logis_fe | iterative | value |  | 14 | 0 | 0 | 13 of 13 | compared |
| full | `logis_fe-binary-grid-serbin-ratch-bt` | logis_fe | iterative | value |  | 14 | 0 | 0 | 13 of 13 | compared |
| full | `logis_fe-binary-grid-serbin-ratch-nobt` | logis_fe | iterative | value |  | 14 | 0 | 0 | 13 of 13 | compared |
| full | `logis_fe-binary-grid-serbin-all-bt` | logis_fe | iterative | value |  | 14 | 0 | 0 | 13 of 13 | compared |
| full | `logis_fe-binary-grid-serbin-all-nobt` | logis_fe | iterative | value |  | 14 | 0 | 0 | 13 of 13 | compared |
| full | `logis_fe-binary-grid-ban-or-bt` | logis_fe | iterative | value |  | 11 | 0 | 0 | 13 of 13 | compared |
| full | `logis_fe-binary-grid-ban-or-nobt` | logis_fe | iterative | value |  | 11 | 0 | 0 | 13 of 13 | compared |
| full | `logis_fe-binary-grid-ban-beta-bt` | logis_fe | iterative | value |  | 16 | 0 | 0 | 13 of 13 | compared |
| full | `logis_fe-binary-grid-ban-beta-nobt` | logis_fe | iterative | value |  | 16 | 0 | 0 | 13 of 13 | compared |
| full | `logis_fe-binary-grid-ban-relch-bt` | logis_fe | iterative | value |  | 11 | 0 | 0 | 13 of 13 | compared |
| full | `logis_fe-binary-grid-ban-relch-nobt` | logis_fe | iterative | value |  | 11 | 0 | 0 | 13 of 13 | compared |
| full | `logis_fe-binary-grid-ban-ratch-bt` | logis_fe | iterative | value |  | 11 | 0 | 0 | 13 of 13 | compared |
| full | `logis_fe-binary-grid-ban-ratch-nobt` | logis_fe | iterative | value |  | 11 | 0 | 0 | 13 of 13 | compared |
| full | `logis_fe-binary-grid-ban-all-bt` | logis_fe | iterative | value |  | 16 | 0 | 0 | 13 of 13 | compared |
| full | `logis_fe-binary-grid-ban-all-nobt` | logis_fe | iterative | value |  | 16 | 0 | 0 | 13 of 13 | compared |
| full | `test-binary-bootstrap-default-two.sided` | test | iterative | value |  |  | 0 | 0 |  | compared |
| full | `test-binary-bootstrap-default-greater` | test | iterative | value |  |  | 0 | 0 |  | compared |
| full | `test-binary-bootstrap-default-less` | test | iterative | value |  |  | 0 | 0 |  | compared |
| full | `confint-binary-sm-score-greater` | confint | root | value |  |  | 0 | 0 |  | compared |
| full | `confint-binary-sm-score-less` | confint | root | value |  |  | 0 | 0 |  | compared |
| full | `confint-binary-sm-wald-greater` | confint | iterative | value |  |  | 0 | 0 |  | compared |
| full | `confint-binary-sm-wald-less` | confint | iterative | value |  |  | 0 | 0 |  | compared |
| full | `logis_fe-medium-default` | logis_fe | iterative | value |  | 6 | 0 | 0 | 15 of 15 | compared |
| full | `logis_fe-medium-tight` | logis_fe | iterative | value |  | 12 | 1.11e-16 | 1.38e-16 | 15 of 15 | compared |
| full | `test-medium-exact` | test | iterative | value |  |  | 0 | 0 |  | compared |
| full | `SM_output-medium-both` | SM_output | iterative | value |  |  | 0 | 0 |  | compared |
| full | `linear_cre-ecls` | linear_cre | lme4 | value |  |  | 0 | 0 | 11 of 11 | compared |
