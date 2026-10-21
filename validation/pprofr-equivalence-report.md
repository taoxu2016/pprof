# pprofR equivalence report: the package against pprofR 0.2.0

Generated 2026-10-21 15:06:05 UTC by `validation/run-pprofr-reference.R` on R version 4.4.0 (2024-04-24 ucrt), Windows 11 x64 (build 22621); 10 s.
Package under test: pprof 2.0.0 from the working tree at commit 95f9090.
Fixtures: validation/fixtures/pprofr, 11 cases, generated at 95f9090 by `dev/reference/pprofr/generate.R` from pprofR 0.2.0 (commit f23c288) on R version 4.4.0 (2024-04-24 ucrt).

## Summary

- Test files: 1; tests 6, expectations 201; failed 0, errors 0, skipped 0, warnings 0.
- Comparisons with the fixtures recorded: 201; within their tier: 192; differences beyond their tier that a register entry decides: 9; failing: 0.
- Largest ratio to its tier among the comparisons expected to match: 0.615 (probability, `extreme-probabilities binary/test/wald/0/two.sided p`).
- Providers left out of a flag comparison, within tolerance of a threshold: 0.

A ratio is the largest difference over the allowed one, atol + rtol |b| elementwise, with the tiers of `tests/testthat/helper-tolerances.R` as `tests/testthat/helper-pprofr-fixtures.R` applies them (LOGISTIC_L1_PLAN §3.4; DEC-158). A comparison expected to match passes at a ratio of at most 1; a difference that a register entry decides must exceed 1. From Phase L1 the comparisons cover binary outcomes, which the package computes already; later phases add binomial outcomes, clusters, and the extensions of standardization.

## Test files

| File | Tests | Expectations | Failed | Errors | Skipped | Warnings |
|---|---|---|---|---|---|---|
| `test-pprofr-reference.R` | 6 | 201 | 0 | 0 | 0 | 0 |

## Comparisons expected to match, by case and tier

The largest ratio to the tier in each group, and the comparison where it occurs.

| Case | Tier | Comparisons | Largest ratio | At |
|---|---|---|---|---|
| binary-moderate | closed_form | 43 | 2.24e-05 | binary-moderate unclustered/sr/median direct |
| binary-moderate | exact | 27 | 0 | binary-moderate unclustered/fit/SerBIN/or/1e-05 iterations |
| binary-moderate | iterative | 18 | 0 | binary-moderate unclustered/fit/SerBIN/or/1e-05 gamma |
| binary-moderate | probability | 25 | 0.000186 | binary-moderate unclustered/test/wald/median/less p |
| binary-moderate | root | 26 | 0.0908 | binary-moderate unclustered/confint/SM/exact/greater direct rate limits |
| extreme-probabilities | closed_form | 18 | 0.234 | extreme-probabilities binary/test/wald/0/two.sided statistic |
| extreme-probabilities | exact | 11 | 0 | extreme-probabilities binary default fit iterations |
| extreme-probabilities | iterative | 2 | 0 | extreme-probabilities binary default fit gamma |
| extreme-probabilities | probability | 12 | 0.615 | extreme-probabilities binary/test/wald/0/two.sided p |
| extreme-probabilities | root | 10 | 0.0732 | extreme-probabilities binary/confint/gamma/exact limits |

## Differences from pprofR that a register entry decides

Each must exceed its tier: the package keeps its convention where pprofR's differs (the brief's §3.3).

| Comparison | Tier | Ratio | Entry | Status |
|---|---|---|---|---|
| extreme-probabilities binary/test/exact.poisbinom/median/two.sided p D-82 | probability | 4.06 | D-82 | explained |
| extreme-probabilities binary/test/score/median/two.sided p D-82 | probability | 4.05 | D-82 | explained |
| extreme-probabilities binary/test/wald/median/two.sided p D-84 | probability | 19.9 | D-84 | explained |
| extreme-probabilities binary/test/exact.poisbinom/0/two.sided p D-82 | probability | 1.73 | D-82 | explained |
| extreme-probabilities binary/test/score/0/two.sided p D-82 | probability | 1.51 | D-82 | explained |
| extreme-probabilities binary/test/wald/0/two.sided p D-84 | probability | 16.8 | D-84 | explained |
| extreme-probabilities binary/test/exact.poisbinom/median/two.sided/level-0.9 p D-82 | probability | 4.06 | D-82 | explained |
| binary-moderate unclustered/covar/lr statistic (D-90) | closed_form | 304 | D-90 | explained |
| binary-moderate unclustered/covar/score statistic (D-90) | closed_form | 2.14e+05 | D-90 | explained |

## Failing and skipped tests

Every expectation that failed, raised an error, or was skipped, whether or not it records a comparison.

None.

## Failing comparisons

None.

## Providers within tolerance of a flag threshold

A provider whose pprofR p-value lies within the probability tier of the test's level is left out of the comparison of flags (the brief's §3.5; `pprofr_near_threshold()`).

None.

## The calibration

`validation/pprofr-calibration-report.md` (`dev/reference/pprofr/calibrate.R`, DEC-158): Result: 187 of 196 calibrated rows pass; 11 rows of information.

## The register's entries of the logistic extensions phase

From `dev/DISCREPANCIES.md`.

| ID | Component | Class | Status |
|---|---|---|---|
| D-82 | Null probabilities of the binomial tests | B | decided: pprof's clamp; signed off 2026-10-20 (DEC-144) |
| D-83 | SerBIN's cross block | B | decided: unfloored, as K-12; signed off 2026-10-20 (DEC-144) |
| D-84 | Model-based standard errors of provider effects | B | decided: K-20's; signed off 2026-10-20 (DEC-144) |
| D-85 | Root finder of the exact and score intervals | B | decided: K-90's; signed off 2026-10-20 (DEC-144) |
| D-86 | Score interval of providers with only events | B | decided: K-90's floor of each weight; signed off 2026-10-20 (DEC-144) |
| D-87 | Scale of rates | B | decided: percent; signed off 2026-10-20 (DEC-144) |
| D-88 | Default stopping rule | B | decided: `"any"`; signed off 2026-10-20 (DEC-144) |
| D-89 | Direct standardization of the new interface (against pprof 1.0.3) | B | decided: the merged algorithm; signed off 2026-10-20 (DEC-144); to be built in L4 |
| D-90 | Null refits of the covariate likelihood-ratio and score tests | B | decided: pprof's defaults (D-10); signed off 2026-10-20 (DEC-144) |
| D-91 | Likelihood-ratio and score tests with one covariate | A | decided: pprof's (DEC-084) |
| D-92 | Invalid binomial input | A | decided: classed errors |
| D-93 | Missing values | A | decided: listwise deletion |
| D-94 | Providers with a single cluster | B | decided: missing robust results with a classed warning; signed off 2026-10-20 (DEC-144) |
| D-95 | Negative stabilized variances | Presentation | decided |
| D-96 | Clusters too large for the stabilized tests | Presentation | decided |
| D-97 | Row order within providers | none (rounding) | decided |
| D-98 | Robust covariance of the coefficients | none (does not arise) | decided |
| D-99 | Provider effects supplied by the caller | A | decided: an `effects` argument for direct standardization |
| D-100 | Providers whose rows all have zero trials | A | decided: a classed error |
| D-101 | The measure test's `crit` and `ci.location` | Presentation | decided: not offered |
| D-102 | AUC of binomial fits | Presentation | decided |
| D-103 | Covariate Wald p-value | none (rounding) | decided: K-100's |
| D-104 | The standard score test | none (pprof offers more) | decided: kept, and for binomial outcomes too |
| D-105 | Long-double sums | none (platform) | decided |
