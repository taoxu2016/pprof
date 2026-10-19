# Cox equivalence report: the package against pprof_py v0.7.0, survival, and glmnet

Generated 2026-10-19 15:25:25 UTC by `validation/run-cox-reference.R` on R version 4.4.0 (2024-04-24 ucrt), Windows 11 x64 (build 22621); survival 3.8.12, glmnet 5.1; 81 s.
Package under test: pprof 2.0.0 from the working tree at commit bec3c21.
Fixtures: the core set (tests/testthat/fixtures/cox) and the full set (validation/fixtures/cox), generated at 76fabac by `dev/reference/cox/generate.py` from pprof_py v0.7.0 (commit 9320766) and the pinned survival and glmnet.

## Summary

- Test files: 7; tests 80, expectations 3705; failed 0, errors 0, skipped 0, warnings 0.
- Comparisons with the fixtures recorded: 1897; within their tier: 1871; differences beyond their tier that a register entry decides: 26; failing: 0.
- Largest ratio to its tier among the comparisons expected to match: 0.995 (cox_coefficient, `tiny-ties breslow coefficients`, test-cox-reference.R).
- Providers left out of a flag comparison, within tolerance of a threshold: 0.

A ratio is the largest difference over the allowed one, atol + rtol |b| elementwise, with the tiers of `tests/testthat/helper-tolerances.R` (DEC-097, DEC-109, DEC-116, DEC-125); the default fits are compared with the longer of the two last Newton steps (D-57). A comparison expected to match passes at a ratio of at most 1; a difference that a register entry decides must exceed 1.

## Test files

| File | Tests | Expectations | Failed | Errors | Skipped | Warnings |
|---|---|---|---|---|---|---|
| `test-cox-fixtures.R` | 5 | 224 | 0 | 0 | 0 | 0 |
| `test-cox-reference.R` | 17 | 2008 | 0 | 0 | 0 | 0 |
| `test-cox-penalized-reference.R` | 3 | 364 | 0 | 0 | 0 | 0 |
| `test-cox-fine-gray-reference.R` | 8 | 512 | 0 | 0 | 0 | 0 |
| `test-model-survival.R` | 20 | 330 | 0 | 0 | 0 | 0 |
| `test-model-glmnet.R` | 8 | 88 | 0 | 0 | 0 | 0 |
| `test-model-fine-gray.R` | 19 | 179 | 0 | 0 | 0 | 0 |

## Comparisons expected to match, by file, case, and tie method

The largest ratio to the tier in each group, and the comparison where it occurs.

| File | Case | Ties | Tier | Comparisons | Largest ratio | At |
|---|---|---|---|---|---|---|
| `test-cox-fine-gray-reference.R` | competing-simple |  | closed_form | 12 | 5.98e-06 | competing-simple 2 weights |
| `test-cox-fine-gray-reference.R` | competing-simple | breslow | cox_baseline | 18 | 0.00582 | competing-simple breslow 1 provider 0 profile 3 |
| `test-cox-fine-gray-reference.R` | competing-simple | breslow | cox_coefficient | 8 | 0.00511 | competing-simple breslow 1 coefficients |
| `test-cox-fine-gray-reference.R` | competing-simple | breslow | cox_function | 8 | 0.000812 | competing-simple breslow 1_unstratified log-likelihoods |
| `test-cox-fine-gray-reference.R` | competing-simple | breslow | cox_variance | 12 | 0.00115 | competing-simple breslow 1_unstratified model-based covariance |
| `test-cox-fine-gray-reference.R` | competing-simple | breslow | last Newton step | 4 | 3.26e-07 | competing-simple breslow 2_unstratified default |
| `test-cox-fine-gray-reference.R` | competing-simple | efron | cox_baseline | 18 | 2.43e-06 | competing-simple efron 1_unstratified provider 0 profile 3 |
| `test-cox-fine-gray-reference.R` | competing-simple | efron | cox_coefficient | 6 | 6.33e-08 | competing-simple efron 1_unstratified coefficients |
| `test-cox-fine-gray-reference.R` | competing-simple | efron | cox_function | 8 | 0.000955 | competing-simple efron 2_unstratified log-likelihoods |
| `test-cox-fine-gray-reference.R` | competing-simple | efron | cox_variance | 16 | 0.229 | competing-simple efron 2 robust covariance |
| `test-cox-fine-gray-reference.R` | competing-simple | efron | last Newton step | 4 | 0.955 | competing-simple efron 2_unstratified (D-57) |
| `test-cox-fine-gray-reference.R` | competing-truncated |  | closed_form | 12 | 9.87e-06 | competing-truncated 1 weights |
| `test-cox-fine-gray-reference.R` | competing-truncated | breslow | cox_baseline | 18 | 9.56e-07 | competing-truncated breslow 2_unstratified provider 0 profile 2 |
| `test-cox-fine-gray-reference.R` | competing-truncated | breslow | cox_coefficient | 8 | 5.46e-07 | competing-truncated breslow 1_unstratified coefficients |
| `test-cox-fine-gray-reference.R` | competing-truncated | breslow | cox_function | 8 | 0.00176 | competing-truncated breslow 1_unstratified log-likelihoods |
| `test-cox-fine-gray-reference.R` | competing-truncated | breslow | cox_variance | 12 | 1.44e-06 | competing-truncated breslow 1_unstratified model-based covariance |
| `test-cox-fine-gray-reference.R` | competing-truncated | breslow | last Newton step | 4 | 3.27e-10 | competing-truncated breslow 1_unstratified default |
| `test-cox-fine-gray-reference.R` | competing-truncated | efron | cox_baseline | 18 | 1.46e-06 | competing-truncated efron 1_unstratified provider 0 profile 3 |
| `test-cox-fine-gray-reference.R` | competing-truncated | efron | cox_coefficient | 8 | 8.38e-07 | competing-truncated efron 1_unstratified coefficients |
| `test-cox-fine-gray-reference.R` | competing-truncated | efron | cox_function | 8 | 0.00089 | competing-truncated efron 1 log-likelihoods |
| `test-cox-fine-gray-reference.R` | competing-truncated | efron | cox_variance | 16 | 7.74e-07 | competing-truncated efron 2_unstratified robust covariance |
| `test-cox-fine-gray-reference.R` | competing-truncated | efron | last Newton step | 4 | 6.74e-10 | competing-truncated efron 1_unstratified default |
| `test-cox-fine-gray-reference.R` | competing-weights |  | closed_form | 12 | 3.91e-06 | competing-weights 1 weights |
| `test-cox-fine-gray-reference.R` | competing-weights | breslow | cox_baseline | 18 | 7.17e-07 | competing-weights breslow 2_unstratified provider 0 profile 3 |
| `test-cox-fine-gray-reference.R` | competing-weights | breslow | cox_coefficient | 7 | 1.33e-06 | competing-weights breslow 2_unstratified coefficients |
| `test-cox-fine-gray-reference.R` | competing-weights | breslow | cox_function | 8 | 0.000827 | competing-weights breslow 1_unstratified log-likelihoods |
| `test-cox-fine-gray-reference.R` | competing-weights | breslow | cox_variance | 12 | 0.0748 | competing-weights breslow 1_unstratified model-based covariance |
| `test-cox-fine-gray-reference.R` | competing-weights | breslow | last Newton step | 4 | 0.978 | competing-weights breslow 1_unstratified (D-57) |
| `test-cox-fine-gray-reference.R` | competing-weights | efron | cox_baseline | 18 | 0 | competing-weights efron 1 provider 0 profile 1 |
| `test-cox-fine-gray-reference.R` | competing-weights | efron | cox_coefficient | 5 | 1.08e-07 | competing-weights efron 2 coefficients |
| `test-cox-fine-gray-reference.R` | competing-weights | efron | cox_function | 4 | 0 | competing-weights efron 1 log-likelihoods, survival |
| `test-cox-fine-gray-reference.R` | competing-weights | efron | cox_variance | 8 | 0 | competing-weights efron 1 robust covariance, survival |
| `test-cox-fixtures.R` | competing-simple | breslow | closed_form | 4 | 0 | competing-simple breslow 1 expanded weights |
| `test-cox-fixtures.R` | competing-simple | breslow | cox_coefficient | 6 | 0 | competing-simple breslow 1 coefficients |
| `test-cox-fixtures.R` | competing-simple | breslow | cox_function | 6 | 0 | competing-simple breslow 1 log-likelihood |
| `test-cox-fixtures.R` | competing-simple | breslow | cox_variance | 10 | 0 | competing-simple breslow 1 covariance |
| `test-cox-fixtures.R` | competing-simple | efron | closed_form | 4 | 0 | competing-simple efron 1 expanded weights |
| `test-cox-fixtures.R` | competing-simple | efron | cox_coefficient | 6 | 0 | competing-simple efron 1 coefficients |
| `test-cox-fixtures.R` | competing-simple | efron | cox_function | 6 | 0 | competing-simple efron 1 log-likelihood |
| `test-cox-fixtures.R` | competing-simple | efron | cox_variance | 10 | 0 | competing-simple efron 1 covariance |
| `test-cox-fixtures.R` | empty-providers | breslow | cox_coefficient | 1 | 0 | empty-providers breslow coefficients |
| `test-cox-fixtures.R` | empty-providers | breslow | cox_function | 1 | 0 | empty-providers breslow log-likelihood |
| `test-cox-fixtures.R` | empty-providers | breslow | cox_variance | 1 | 0 | empty-providers breslow covariance |
| `test-cox-fixtures.R` | empty-providers | efron | cox_coefficient | 1 | 0 | empty-providers efron coefficients |
| `test-cox-fixtures.R` | empty-providers | efron | cox_function | 1 | 0 | empty-providers efron log-likelihood |
| `test-cox-fixtures.R` | empty-providers | efron | cox_variance | 1 | 0 | empty-providers efron covariance |
| `test-cox-fixtures.R` | lt-stratified | breslow | cox_coefficient | 1 | 0 | lt-stratified breslow coefficients |
| `test-cox-fixtures.R` | lt-stratified | breslow | cox_function | 1 | 0 | lt-stratified breslow log-likelihood |
| `test-cox-fixtures.R` | lt-stratified | breslow | cox_variance | 1 | 0 | lt-stratified breslow covariance |
| `test-cox-fixtures.R` | lt-stratified | efron | cox_coefficient | 1 | 0 | lt-stratified efron coefficients |
| `test-cox-fixtures.R` | lt-stratified | efron | cox_function | 1 | 0 | lt-stratified efron log-likelihood |
| `test-cox-fixtures.R` | lt-stratified | efron | cox_variance | 1 | 0 | lt-stratified efron covariance |
| `test-cox-fixtures.R` | near-ties | breslow | cox_coefficient | 1 | 0 | near-ties breslow coefficients |
| `test-cox-fixtures.R` | near-ties | breslow | cox_function | 1 | 0 | near-ties breslow log-likelihood |
| `test-cox-fixtures.R` | near-ties | breslow | cox_variance | 1 | 0 | near-ties breslow covariance |
| `test-cox-fixtures.R` | near-ties | efron | cox_coefficient | 1 | 0 | near-ties efron coefficients |
| `test-cox-fixtures.R` | near-ties | efron | cox_function | 1 | 0 | near-ties efron log-likelihood |
| `test-cox-fixtures.R` | near-ties | efron | cox_variance | 1 | 0 | near-ties efron covariance |
| `test-cox-fixtures.R` | penalized-strata | breslow | penalized_path | 1 | 0 | penalized-strata breslow alpha_1 |
| `test-cox-fixtures.R` | penalized-strata | efron | penalized_path | 1 | 0 | penalized-strata efron alpha_1 |
| `test-cox-fixtures.R` | rc-stratified | breslow | cox_coefficient | 1 | 0 | rc-stratified breslow coefficients |
| `test-cox-fixtures.R` | rc-stratified | breslow | cox_function | 1 | 0 | rc-stratified breslow log-likelihood |
| `test-cox-fixtures.R` | rc-stratified | breslow | cox_variance | 1 | 0 | rc-stratified breslow covariance |
| `test-cox-fixtures.R` | rc-stratified | efron | cox_coefficient | 1 | 0 | rc-stratified efron coefficients |
| `test-cox-fixtures.R` | rc-stratified | efron | cox_function | 1 | 0 | rc-stratified efron log-likelihood |
| `test-cox-fixtures.R` | rc-stratified | efron | cox_variance | 1 | 0 | rc-stratified efron covariance |
| `test-cox-fixtures.R` | tiny-ties | breslow | cox_coefficient | 1 | 0 | tiny-ties breslow coefficients |
| `test-cox-fixtures.R` | tiny-ties | breslow | cox_function | 1 | 0 | tiny-ties breslow log-likelihood |
| `test-cox-fixtures.R` | tiny-ties | breslow | cox_variance | 1 | 0 | tiny-ties breslow covariance |
| `test-cox-fixtures.R` | tiny-ties | efron | cox_coefficient | 1 | 0 | tiny-ties efron coefficients |
| `test-cox-fixtures.R` | tiny-ties | efron | cox_function | 1 | 0 | tiny-ties efron log-likelihood |
| `test-cox-fixtures.R` | tiny-ties | efron | cox_variance | 1 | 0 | tiny-ties efron covariance |
| `test-cox-penalized-reference.R` | penalized-combined | breslow | closed_form | 10 | 0.00368 | penalized-combined breslow cvsd against glmnet and survival |
| `test-cox-penalized-reference.R` | penalized-combined | breslow | penalized_path | 7 | 0.0598 | penalized-combined breslow alpha_0.5 path against pprof_py |
| `test-cox-penalized-reference.R` | penalized-combined | efron | closed_form | 10 | 0.00377 | penalized-combined efron cvsd against glmnet and survival |
| `test-cox-penalized-reference.R` | penalized-combined | efron | penalized_path | 7 | 0.0675 | penalized-combined efron alpha_0.5 path against pprof_py |
| `test-cox-penalized-reference.R` | penalized-few-events | breslow | closed_form | 3 | 6.4e-06 | penalized-few-events breslow default grid |
| `test-cox-penalized-reference.R` | penalized-few-events | breslow | penalized_path | 2 | 0.0947 | penalized-few-events breslow default path to the 30th |
| `test-cox-penalized-reference.R` | penalized-few-events | efron | closed_form | 3 | 4.66e-06 | penalized-few-events efron default grid |
| `test-cox-penalized-reference.R` | penalized-few-events | efron | penalized_path | 2 | 0.159 | penalized-few-events efron default path to the 30th |
| `test-cox-penalized-reference.R` | penalized-offset | breslow | closed_form | 3 | 6.33e-06 | penalized-offset breslow alpha_1 column scales |
| `test-cox-penalized-reference.R` | penalized-offset | breslow | penalized_path | 2 | 0.0472 | penalized-offset breslow alpha_1 path against pprof_py |
| `test-cox-penalized-reference.R` | penalized-offset | efron | closed_form | 3 | 8.55e-06 | penalized-offset efron alpha_1 grid |
| `test-cox-penalized-reference.R` | penalized-offset | efron | penalized_path | 2 | 0.0597 | penalized-offset efron alpha_1 path against pprof_py |
| `test-cox-penalized-reference.R` | penalized-settings | breslow | closed_form | 21 | 1.32e-05 | penalized-settings breslow given-grid column scales |
| `test-cox-penalized-reference.R` | penalized-settings | breslow | penalized_path | 14 | 0.0615 | penalized-settings breslow unequal-factors path against pprof_py |
| `test-cox-penalized-reference.R` | penalized-settings | efron | closed_form | 21 | 1.67e-05 | penalized-settings efron one-covariate grid |
| `test-cox-penalized-reference.R` | penalized-settings | efron | penalized_path | 14 | 0.067 | penalized-settings efron unstandardized path against pprof_py |
| `test-cox-penalized-reference.R` | penalized-strata | breslow | closed_form | 3 | 1.19e-05 | penalized-strata breslow alpha_1 grid |
| `test-cox-penalized-reference.R` | penalized-strata | breslow | penalized_path | 2 | 0.0367 | penalized-strata breslow alpha_1 path against pprof_py |
| `test-cox-penalized-reference.R` | penalized-strata | efron | closed_form | 3 | 1.6e-05 | penalized-strata efron alpha_1 grid |
| `test-cox-penalized-reference.R` | penalized-strata | efron | penalized_path | 2 | 0.0387 | penalized-strata efron alpha_1 path against pprof_py |
| `test-cox-penalized-reference.R` | penalized-truncation | breslow | closed_form | 3 | 2.46e-05 | penalized-truncation breslow alpha_1 grid |
| `test-cox-penalized-reference.R` | penalized-truncation | breslow | penalized_path | 2 | 0.0343 | penalized-truncation breslow alpha_1 path against pprof_py |
| `test-cox-penalized-reference.R` | penalized-truncation | efron | closed_form | 3 | 3.32e-05 | penalized-truncation efron alpha_1 grid |
| `test-cox-penalized-reference.R` | penalized-truncation | efron | penalized_path | 2 | 0.038 | penalized-truncation efron alpha_1 path against pprof_py |
| `test-cox-penalized-reference.R` | penalized-weights | breslow | closed_form | 3 | 8.53e-05 | penalized-weights breslow alpha_1 lambda_max |
| `test-cox-penalized-reference.R` | penalized-weights | breslow | penalized_path | 2 | 0.0464 | penalized-weights breslow alpha_1 path against pprof_py |
| `test-cox-penalized-reference.R` | penalized-weights | efron | closed_form | 3 | 7.75e-05 | penalized-weights efron alpha_1 grid |
| `test-cox-penalized-reference.R` | penalized-weights | efron | penalized_path | 2 | 0.0515 | penalized-weights efron alpha_1 path against pprof_py |
| `test-cox-penalized-reference.R` | penalized-wide | breslow | closed_form | 10 | 0.00495 | penalized-wide breslow cvsd against glmnet and survival |
| `test-cox-penalized-reference.R` | penalized-wide | breslow | penalized_path | 7 | 0.21 | penalized-wide breslow alpha_0.5 path against pprof_py |
| `test-cox-penalized-reference.R` | penalized-wide | efron | closed_form | 10 | 0.00183 | penalized-wide efron fold deviances |
| `test-cox-penalized-reference.R` | penalized-wide | efron | penalized_path | 7 | 0.213 | penalized-wide efron alpha_1 path against pprof_py |
| `test-cox-reference.R` | competing-simple | breslow | closed_form | 14 | 3.24e-05 | competing-simple breslow cause 1 direct expected events |
| `test-cox-reference.R` | competing-simple | breslow | cox_baseline | 8 | 0.0104 | competing-simple breslow cause 1 direct expected events |
| `test-cox-reference.R` | competing-simple | breslow | cox_coefficient | 4 | 0.0757 | competing-simple breslow cause 1 coefficients |
| `test-cox-reference.R` | competing-simple | breslow | cox_root | 4 | 0.00319 | competing-simple breslow cause 1 midp lower limits |
| `test-cox-reference.R` | competing-simple | breslow | cox_statistic | 4 | 1.11e-05 | competing-simple breslow cause 1 exact statistics |
| `test-cox-reference.R` | competing-simple | breslow | cox_variance | 4 | 0.00197 | competing-simple breslow cause 1 covariance |
| `test-cox-reference.R` | competing-simple | breslow | exact | 2 | 0 | competing-simple breslow cause 1 funnel limits |
| `test-cox-reference.R` | competing-simple | breslow | probability | 4 | 3.42e-05 | competing-simple breslow cause 1 midp p-values |
| `test-cox-reference.R` | competing-simple | efron | closed_form | 14 | 2.27e-05 | competing-simple efron cause 1 direct expected events |
| `test-cox-reference.R` | competing-simple | efron | cox_baseline | 8 | 0.00532 | competing-simple efron cause 1 direct expected events |
| `test-cox-reference.R` | competing-simple | efron | cox_coefficient | 4 | 0.0391 | competing-simple efron cause 1 coefficients |
| `test-cox-reference.R` | competing-simple | efron | cox_root | 4 | 0.00319 | competing-simple efron cause 1 midp lower limits |
| `test-cox-reference.R` | competing-simple | efron | cox_statistic | 4 | 1.11e-05 | competing-simple efron cause 1 exact statistics |
| `test-cox-reference.R` | competing-simple | efron | cox_variance | 4 | 0.00098 | competing-simple efron cause 1 covariance |
| `test-cox-reference.R` | competing-simple | efron | exact | 2 | 0 | competing-simple efron cause 1 funnel limits |
| `test-cox-reference.R` | competing-simple | efron | probability | 4 | 2.34e-05 | competing-simple efron cause 2 midp p-values |
| `test-cox-reference.R` | competing-truncated | breslow | closed_form | 14 | 3.35e-05 | competing-truncated breslow cause 1 direct expected events |
| `test-cox-reference.R` | competing-truncated | breslow | cox_baseline | 8 | 0.0012 | competing-truncated breslow cause 1 direct expected events |
| `test-cox-reference.R` | competing-truncated | breslow | cox_coefficient | 2 | 0.0106 | competing-truncated breslow cause 1 coefficients |
| `test-cox-reference.R` | competing-truncated | breslow | cox_root | 4 | 0.0032 | competing-truncated breslow cause 1 midp lower limits |
| `test-cox-reference.R` | competing-truncated | breslow | cox_statistic | 4 | 2.28e-05 | competing-truncated breslow cause 1 exact statistics |
| `test-cox-reference.R` | competing-truncated | breslow | cox_variance | 2 | 0.00117 | competing-truncated breslow cause 1 covariance |
| `test-cox-reference.R` | competing-truncated | breslow | exact | 4 | 0 | competing-truncated breslow cause 1 funnel limits |
| `test-cox-reference.R` | competing-truncated | breslow | probability | 4 | 2.47e-05 | competing-truncated breslow cause 2 exact p-values |
| `test-cox-reference.R` | competing-truncated | efron | closed_form | 14 | 4.3e-05 | competing-truncated efron cause 2 direct expected events |
| `test-cox-reference.R` | competing-truncated | efron | cox_baseline | 8 | 4.53e-07 | competing-truncated efron cause 2 direct ratios |
| `test-cox-reference.R` | competing-truncated | efron | cox_coefficient | 2 | 1.71e-07 | competing-truncated efron cause 2 coefficients |
| `test-cox-reference.R` | competing-truncated | efron | cox_root | 4 | 0.0032 | competing-truncated efron cause 1 midp lower limits |
| `test-cox-reference.R` | competing-truncated | efron | cox_statistic | 4 | 8.59e-06 | competing-truncated efron cause 1 exact statistics |
| `test-cox-reference.R` | competing-truncated | efron | cox_variance | 2 | 1.34e-07 | competing-truncated efron cause 1 covariance |
| `test-cox-reference.R` | competing-truncated | efron | exact | 4 | 0 | competing-truncated efron cause 1 funnel limits |
| `test-cox-reference.R` | competing-truncated | efron | probability | 4 | 4.4e-05 | competing-truncated efron cause 2 midp p-values |
| `test-cox-reference.R` | competing-weights | breslow | closed_form | 14 | 5.61e-05 | competing-weights breslow cause 1 direct expected events |
| `test-cox-reference.R` | competing-weights | breslow | cox_baseline | 8 | 5.61e-07 | competing-weights breslow cause 1 direct expected events |
| `test-cox-reference.R` | competing-weights | breslow | cox_coefficient | 2 | 4.5e-07 | competing-weights breslow cause 2 coefficients |
| `test-cox-reference.R` | competing-weights | breslow | cox_root | 4 | 0.00323 | competing-weights breslow cause 2 midp lower limits |
| `test-cox-reference.R` | competing-weights | breslow | cox_statistic | 4 | 1.11e-05 | competing-weights breslow cause 2 exact statistics |
| `test-cox-reference.R` | competing-weights | breslow | cox_variance | 2 | 3.75e-08 | competing-weights breslow cause 1 covariance |
| `test-cox-reference.R` | competing-weights | breslow | exact | 4 | 0 | competing-weights breslow cause 1 funnel limits |
| `test-cox-reference.R` | competing-weights | breslow | probability | 4 | 3.26e-05 | competing-weights breslow cause 1 midp p-values |
| `test-cox-reference.R` | competing-weights | efron | closed_form | 14 | 6.35e-05 | competing-weights efron cause 1 direct expected events |
| `test-cox-reference.R` | competing-weights | efron | cox_baseline | 4 | 3.68e-07 | competing-weights efron cause 2 direct expected events |
| `test-cox-reference.R` | competing-weights | efron | cox_coefficient | 1 | 4.08e-07 | competing-weights efron cause 2 coefficients |
| `test-cox-reference.R` | competing-weights | efron | cox_root | 4 | 0.00323 | competing-weights efron cause 2 midp lower limits |
| `test-cox-reference.R` | competing-weights | efron | cox_statistic | 4 | 1.11e-05 | competing-weights efron cause 2 exact statistics |
| `test-cox-reference.R` | competing-weights | efron | cox_variance | 1 | 1.11e-07 | competing-weights efron cause 2 covariance |
| `test-cox-reference.R` | competing-weights | efron | exact | 4 | 0 | competing-weights efron cause 1 funnel limits |
| `test-cox-reference.R` | competing-weights | efron | probability | 4 | 4.81e-05 | competing-weights efron cause 1 midp p-values |
| `test-cox-reference.R` | empty-providers | breslow | closed_form | 7 | 5.93e-05 | empty-providers breslow direct expected events |
| `test-cox-reference.R` | empty-providers | breslow | cox_baseline | 18 | 0.00281 | empty-providers breslow cumulative_hazard, stratum 2, profile 2 |
| `test-cox-reference.R` | empty-providers | breslow | cox_coefficient | 1 | 0.00646 | empty-providers breslow coefficients |
| `test-cox-reference.R` | empty-providers | breslow | cox_function | 2 | 0.000399 | empty-providers breslow log-likelihood |
| `test-cox-reference.R` | empty-providers | breslow | cox_residual | 3 | 0.0102 | empty-providers breslow score |
| `test-cox-reference.R` | empty-providers | breslow | cox_root | 2 | 0.0023 | empty-providers breslow midp lower limits |
| `test-cox-reference.R` | empty-providers | breslow | cox_statistic | 2 | 1.64e-05 | empty-providers breslow midp statistics |
| `test-cox-reference.R` | empty-providers | breslow | cox_variance | 8 | 0.00825 | empty-providers breslow clustered |
| `test-cox-reference.R` | empty-providers | breslow | exact | 1 | 0 | empty-providers breslow funnel limits |
| `test-cox-reference.R` | empty-providers | breslow | last Newton step | 1 | 1.18e-11 | empty-providers breslow default |
| `test-cox-reference.R` | empty-providers | breslow | probability | 2 | 9.1e-05 | empty-providers breslow exact p-values |
| `test-cox-reference.R` | empty-providers | efron | closed_form | 7 | 0.000122 | empty-providers efron direct expected events |
| `test-cox-reference.R` | empty-providers | efron | cox_baseline | 18 | 1.28e-06 | empty-providers efron direct ratios |
| `test-cox-reference.R` | empty-providers | efron | cox_coefficient | 1 | 9.28e-08 | empty-providers efron coefficients |
| `test-cox-reference.R` | empty-providers | efron | cox_function | 2 | 0.000271 | empty-providers efron log-likelihood |
| `test-cox-reference.R` | empty-providers | efron | cox_residual | 3 | 1.07e-06 | empty-providers efron score |
| `test-cox-reference.R` | empty-providers | efron | cox_root | 2 | 0.0023 | empty-providers efron midp lower limits |
| `test-cox-reference.R` | empty-providers | efron | cox_statistic | 2 | 3.24e-05 | empty-providers efron midp statistics |
| `test-cox-reference.R` | empty-providers | efron | cox_variance | 8 | 4.36e-07 | empty-providers efron clustered |
| `test-cox-reference.R` | empty-providers | efron | exact | 1 | 0 | empty-providers efron funnel limits |
| `test-cox-reference.R` | empty-providers | efron | last Newton step | 1 | 2.71e-11 | empty-providers efron default |
| `test-cox-reference.R` | empty-providers | efron | probability | 2 | 0.000147 | empty-providers efron exact p-values |
| `test-cox-reference.R` | large-mean | breslow | closed_form | 7 | 0.00011 | large-mean breslow direct expected events |
| `test-cox-reference.R` | large-mean | breslow | cox_baseline | 4 | 7.47e-07 | large-mean breslow direct ratios |
| `test-cox-reference.R` | large-mean | breslow | cox_coefficient | 1 | 3.65e-08 | large-mean breslow coefficients |
| `test-cox-reference.R` | large-mean | breslow | cox_function | 2 | 0.000833 | large-mean breslow log-likelihood |
| `test-cox-reference.R` | large-mean | breslow | cox_residual | 3 | 0 | large-mean breslow martingale |
| `test-cox-reference.R` | large-mean | breslow | cox_root | 2 | 0.00179 | large-mean breslow midp upper limits |
| `test-cox-reference.R` | large-mean | breslow | cox_statistic | 2 | 4.01e-07 | large-mean breslow midp statistics |
| `test-cox-reference.R` | large-mean | breslow | cox_variance | 6 | 1.62e-08 | large-mean breslow covariance |
| `test-cox-reference.R` | large-mean | breslow | exact | 2 | 0 | large-mean breslow funnel limits |
| `test-cox-reference.R` | large-mean | breslow | last Newton step | 1 | 5.01e-11 | large-mean breslow default |
| `test-cox-reference.R` | large-mean | breslow | probability | 2 | 5.56e-05 | large-mean breslow midp p-values |
| `test-cox-reference.R` | large-mean | efron | closed_form | 7 | 0.000249 | large-mean efron expected events |
| `test-cox-reference.R` | large-mean | efron | cox_baseline | 4 | 2.5e-06 | large-mean efron indirect ratios |
| `test-cox-reference.R` | large-mean | efron | cox_coefficient | 1 | 1.69e-08 | large-mean efron coefficients |
| `test-cox-reference.R` | large-mean | efron | cox_function | 2 | 0.000337 | large-mean efron log-likelihood |
| `test-cox-reference.R` | large-mean | efron | cox_residual | 3 | 0 | large-mean efron martingale |
| `test-cox-reference.R` | large-mean | efron | cox_root | 2 | 0.00171 | large-mean efron midp upper limits |
| `test-cox-reference.R` | large-mean | efron | cox_statistic | 2 | 5.93e-07 | large-mean efron midp statistics |
| `test-cox-reference.R` | large-mean | efron | cox_variance | 6 | 7.46e-09 | large-mean efron covariance |
| `test-cox-reference.R` | large-mean | efron | exact | 2 | 0 | large-mean efron funnel limits |
| `test-cox-reference.R` | large-mean | efron | last Newton step | 1 | 8.48e-12 | large-mean efron default |
| `test-cox-reference.R` | large-mean | efron | probability | 2 | 4.55e-05 | large-mean efron midp p-values |
| `test-cox-reference.R` | lt-stratified | breslow | closed_form | 7 | 6.29e-05 | lt-stratified breslow direct expected events |
| `test-cox-reference.R` | lt-stratified | breslow | cox_baseline | 18 | 6.29e-06 | lt-stratified breslow survival, stratum 2, profile 1 |
| `test-cox-reference.R` | lt-stratified | breslow | cox_coefficient | 1 | 6.61e-07 | lt-stratified breslow coefficients |
| `test-cox-reference.R` | lt-stratified | breslow | cox_function | 2 | 0.000407 | lt-stratified breslow log-likelihood |
| `test-cox-reference.R` | lt-stratified | breslow | cox_residual | 3 | 1.42e-06 | lt-stratified breslow score |
| `test-cox-reference.R` | lt-stratified | breslow | cox_root | 2 | 0.000528 | lt-stratified breslow midp lower limits |
| `test-cox-reference.R` | lt-stratified | breslow | cox_statistic | 2 | 7.91e-07 | lt-stratified breslow exact statistics |
| `test-cox-reference.R` | lt-stratified | breslow | cox_variance | 6 | 9e-08 | lt-stratified breslow z |
| `test-cox-reference.R` | lt-stratified | breslow | exact | 1 | 0 | lt-stratified breslow funnel limits |
| `test-cox-reference.R` | lt-stratified | breslow | last Newton step | 1 | 2.21e-10 | lt-stratified breslow default |
| `test-cox-reference.R` | lt-stratified | breslow | probability | 2 | 0.000161 | lt-stratified breslow midp p-values |
| `test-cox-reference.R` | lt-stratified | efron | closed_form | 7 | 6e-05 | lt-stratified efron direct expected events |
| `test-cox-reference.R` | lt-stratified | efron | cox_baseline | 18 | 2.28e-05 | lt-stratified efron survival, stratum 2, profile 1 |
| `test-cox-reference.R` | lt-stratified | efron | cox_coefficient | 1 | 1.03e-06 | lt-stratified efron coefficients |
| `test-cox-reference.R` | lt-stratified | efron | cox_function | 2 | 0.000394 | lt-stratified efron null log-likelihood |
| `test-cox-reference.R` | lt-stratified | efron | cox_residual | 3 | 2.84e-06 | lt-stratified efron score |
| `test-cox-reference.R` | lt-stratified | efron | cox_root | 2 | 0.000536 | lt-stratified efron midp lower limits |
| `test-cox-reference.R` | lt-stratified | efron | cox_statistic | 2 | 8.32e-07 | lt-stratified efron exact statistics |
| `test-cox-reference.R` | lt-stratified | efron | cox_variance | 8 | 8.75e-07 | lt-stratified efron clustered |
| `test-cox-reference.R` | lt-stratified | efron | exact | 1 | 0 | lt-stratified efron funnel limits |
| `test-cox-reference.R` | lt-stratified | efron | last Newton step | 1 | 6.72e-11 | lt-stratified efron default |
| `test-cox-reference.R` | lt-stratified | efron | probability | 2 | 0.000206 | lt-stratified efron midp p-values |
| `test-cox-reference.R` | lt-weights-offset | breslow | closed_form | 7 | 0.000117 | lt-weights-offset breslow direct expected events |
| `test-cox-reference.R` | lt-weights-offset | breslow | cox_baseline | 18 | 5e-06 | lt-weights-offset breslow survival, stratum 1, profile 2 |
| `test-cox-reference.R` | lt-weights-offset | breslow | cox_coefficient | 1 | 1.62e-07 | lt-weights-offset breslow coefficients |
| `test-cox-reference.R` | lt-weights-offset | breslow | cox_function | 2 | 0.000277 | lt-weights-offset breslow log-likelihood |
| `test-cox-reference.R` | lt-weights-offset | breslow | cox_residual | 3 | 1.07e-06 | lt-weights-offset breslow score |
| `test-cox-reference.R` | lt-weights-offset | breslow | cox_root | 2 | 0.00168 | lt-weights-offset breslow midp upper limits |
| `test-cox-reference.R` | lt-weights-offset | breslow | cox_statistic | 2 | 1.25e-06 | lt-weights-offset breslow exact statistics |
| `test-cox-reference.R` | lt-weights-offset | breslow | cox_variance | 6 | 1.22e-07 | lt-weights-offset breslow covariance |
| `test-cox-reference.R` | lt-weights-offset | breslow | exact | 2 | 0 | lt-weights-offset breslow funnel limits |
| `test-cox-reference.R` | lt-weights-offset | breslow | last Newton step | 1 | 3.68e-11 | lt-weights-offset breslow default |
| `test-cox-reference.R` | lt-weights-offset | breslow | probability | 2 | 5.25e-05 | lt-weights-offset breslow midp p-values |
| `test-cox-reference.R` | lt-weights-offset | efron | closed_form | 7 | 6.52e-05 | lt-weights-offset efron direct expected events |
| `test-cox-reference.R` | lt-weights-offset | efron | cox_baseline | 18 | 3.38e-06 | lt-weights-offset efron survival, stratum 1, profile 2 |
| `test-cox-reference.R` | lt-weights-offset | efron | cox_coefficient | 1 | 1.15e-07 | lt-weights-offset efron coefficients |
| `test-cox-reference.R` | lt-weights-offset | efron | cox_function | 2 | 0.000845 | lt-weights-offset efron log-likelihood |
| `test-cox-reference.R` | lt-weights-offset | efron | cox_residual | 3 | 1.42e-06 | lt-weights-offset efron score |
| `test-cox-reference.R` | lt-weights-offset | efron | cox_root | 2 | 0.00168 | lt-weights-offset efron midp upper limits |
| `test-cox-reference.R` | lt-weights-offset | efron | cox_statistic | 2 | 7.62e-06 | lt-weights-offset efron exact statistics |
| `test-cox-reference.R` | lt-weights-offset | efron | cox_variance | 8 | 4.85e-07 | lt-weights-offset efron robust |
| `test-cox-reference.R` | lt-weights-offset | efron | exact | 2 | 0 | lt-weights-offset efron funnel limits |
| `test-cox-reference.R` | lt-weights-offset | efron | last Newton step | 1 | 6.08e-12 | lt-weights-offset efron default |
| `test-cox-reference.R` | lt-weights-offset | efron | probability | 2 | 5.32e-05 | lt-weights-offset efron midp p-values |
| `test-cox-reference.R` | near-ties | breslow | closed_form | 7 | 2.38e-05 | near-ties breslow direct expected events |
| `test-cox-reference.R` | near-ties | breslow | cox_baseline | 18 | 7.03e-07 | near-ties breslow baseline |
| `test-cox-reference.R` | near-ties | breslow | cox_coefficient | 1 | 6.13e-08 | near-ties breslow coefficients |
| `test-cox-reference.R` | near-ties | breslow | cox_function | 2 | 0.000375 | near-ties breslow log-likelihood |
| `test-cox-reference.R` | near-ties | breslow | cox_residual | 3 | 1.07e-06 | near-ties breslow score |
| `test-cox-reference.R` | near-ties | breslow | cox_root | 2 | 0.0032 | near-ties breslow midp lower limits |
| `test-cox-reference.R` | near-ties | breslow | cox_statistic | 2 | 8.44e-06 | near-ties breslow exact statistics |
| `test-cox-reference.R` | near-ties | breslow | cox_variance | 8 | 1.16e-07 | near-ties breslow clustered |
| `test-cox-reference.R` | near-ties | breslow | exact | 1 | 0 | near-ties breslow funnel limits |
| `test-cox-reference.R` | near-ties | breslow | last Newton step | 1 | 1.77e-08 | near-ties breslow default |
| `test-cox-reference.R` | near-ties | breslow | probability | 2 | 9.93e-05 | near-ties breslow midp p-values |
| `test-cox-reference.R` | near-ties | efron | closed_form | 7 | 3.69e-05 | near-ties efron direct expected events |
| `test-cox-reference.R` | near-ties | efron | cox_baseline | 18 | 7.43e-07 | near-ties efron baseline |
| `test-cox-reference.R` | near-ties | efron | cox_coefficient | 1 | 1.34e-07 | near-ties efron coefficients |
| `test-cox-reference.R` | near-ties | efron | cox_function | 2 | 0.000564 | near-ties efron log-likelihood |
| `test-cox-reference.R` | near-ties | efron | cox_residual | 3 | 1.33e-06 | near-ties efron score |
| `test-cox-reference.R` | near-ties | efron | cox_root | 2 | 0.0032 | near-ties efron midp lower limits |
| `test-cox-reference.R` | near-ties | efron | cox_statistic | 2 | 3.52e-06 | near-ties efron exact statistics |
| `test-cox-reference.R` | near-ties | efron | cox_variance | 8 | 4.08e-07 | near-ties efron clustered |
| `test-cox-reference.R` | near-ties | efron | exact | 1 | 0 | near-ties efron funnel limits |
| `test-cox-reference.R` | near-ties | efron | last Newton step | 1 | 1.76e-07 | near-ties efron default |
| `test-cox-reference.R` | near-ties | efron | probability | 2 | 8.22e-05 | near-ties efron midp p-values |
| `test-cox-reference.R` | provider-scale | breslow | closed_form | 7 | 0.0242 | provider-scale breslow direct expected events |
| `test-cox-reference.R` | provider-scale | breslow | cox_baseline | 18 | 0.000242 | provider-scale breslow direct expected events |
| `test-cox-reference.R` | provider-scale | breslow | cox_coefficient | 1 | 3.43e-08 | provider-scale breslow coefficients |
| `test-cox-reference.R` | provider-scale | breslow | cox_function | 2 | 0.0226 | provider-scale breslow null log-likelihood |
| `test-cox-reference.R` | provider-scale | breslow | cox_root | 2 | 0.00625 | provider-scale breslow midp lower limits |
| `test-cox-reference.R` | provider-scale | breslow | cox_statistic | 2 | 0.000112 | provider-scale breslow midp statistics |
| `test-cox-reference.R` | provider-scale | breslow | cox_variance | 3 | 4.14e-08 | provider-scale breslow covariance |
| `test-cox-reference.R` | provider-scale | breslow | exact | 2 | 0 | provider-scale breslow funnel limits |
| `test-cox-reference.R` | provider-scale | breslow | last Newton step | 1 | 5.69e-09 | provider-scale breslow default |
| `test-cox-reference.R` | provider-scale | breslow | probability | 2 | 0.00029 | provider-scale breslow midp p-values |
| `test-cox-reference.R` | provider-scale | efron | closed_form | 7 | 0.0188 | provider-scale efron direct expected events |
| `test-cox-reference.R` | provider-scale | efron | cox_baseline | 18 | 0.000188 | provider-scale efron direct expected events |
| `test-cox-reference.R` | provider-scale | efron | cox_coefficient | 1 | 6.1e-08 | provider-scale efron coefficients |
| `test-cox-reference.R` | provider-scale | efron | cox_function | 2 | 0.0238 | provider-scale efron null log-likelihood |
| `test-cox-reference.R` | provider-scale | efron | cox_root | 2 | 0.00629 | provider-scale efron midp lower limits |
| `test-cox-reference.R` | provider-scale | efron | cox_statistic | 2 | 0.00125 | provider-scale efron midp statistics |
| `test-cox-reference.R` | provider-scale | efron | cox_variance | 3 | 4.28e-08 | provider-scale efron covariance |
| `test-cox-reference.R` | provider-scale | efron | exact | 2 | 0 | provider-scale efron funnel limits |
| `test-cox-reference.R` | provider-scale | efron | last Newton step | 1 | 4.49e-09 | provider-scale efron default |
| `test-cox-reference.R` | provider-scale | efron | probability | 2 | 0.000169 | provider-scale efron midp p-values |
| `test-cox-reference.R` | rc-stratified | breslow | closed_form | 7 | 0.000136 | rc-stratified breslow direct expected events |
| `test-cox-reference.R` | rc-stratified | breslow | cox_baseline | 18 | 0.0386 | rc-stratified breslow survival, stratum 1, profile 2 |
| `test-cox-reference.R` | rc-stratified | breslow | cox_coefficient | 1 | 0.0162 | rc-stratified breslow coefficients |
| `test-cox-reference.R` | rc-stratified | breslow | cox_function | 2 | 0.00106 | rc-stratified breslow log-likelihood |
| `test-cox-reference.R` | rc-stratified | breslow | cox_residual | 3 | 0.0246 | rc-stratified breslow score |
| `test-cox-reference.R` | rc-stratified | breslow | cox_root | 2 | 0.00409 | rc-stratified breslow midp lower limits |
| `test-cox-reference.R` | rc-stratified | breslow | cox_statistic | 2 | 1.11e-05 | rc-stratified breslow exact statistics |
| `test-cox-reference.R` | rc-stratified | breslow | cox_variance | 8 | 0.0127 | rc-stratified breslow robust |
| `test-cox-reference.R` | rc-stratified | breslow | exact | 1 | 0 | rc-stratified breslow funnel limits |
| `test-cox-reference.R` | rc-stratified | breslow | last Newton step | 1 | 1.22e-11 | rc-stratified breslow default |
| `test-cox-reference.R` | rc-stratified | breslow | probability | 2 | 5.12e-05 | rc-stratified breslow exact p-values |
| `test-cox-reference.R` | rc-stratified | efron | closed_form | 7 | 0.000225 | rc-stratified efron direct expected events |
| `test-cox-reference.R` | rc-stratified | efron | cox_baseline | 18 | 2.25e-06 | rc-stratified efron direct expected events |
| `test-cox-reference.R` | rc-stratified | efron | cox_coefficient | 1 | 1.5e-07 | rc-stratified efron coefficients |
| `test-cox-reference.R` | rc-stratified | efron | cox_function | 2 | 0.000476 | rc-stratified efron log-likelihood |
| `test-cox-reference.R` | rc-stratified | efron | cox_residual | 3 | 1.42e-06 | rc-stratified efron score |
| `test-cox-reference.R` | rc-stratified | efron | cox_root | 2 | 0.00409 | rc-stratified efron midp lower limits |
| `test-cox-reference.R` | rc-stratified | efron | cox_statistic | 2 | 1.83e-05 | rc-stratified efron exact statistics |
| `test-cox-reference.R` | rc-stratified | efron | cox_variance | 8 | 3.8e-07 | rc-stratified efron robust |
| `test-cox-reference.R` | rc-stratified | efron | exact | 1 | 0 | rc-stratified efron funnel limits |
| `test-cox-reference.R` | rc-stratified | efron | last Newton step | 1 | 7.87e-12 | rc-stratified efron default |
| `test-cox-reference.R` | rc-stratified | efron | probability | 2 | 4.14e-05 | rc-stratified efron exact p-values |
| `test-cox-reference.R` | rc-stratified-weights-offset | breslow | closed_form | 7 | 0.000297 | rc-stratified-weights-offset breslow direct expected events |
| `test-cox-reference.R` | rc-stratified-weights-offset | breslow | cox_baseline | 18 | 0.0444 | rc-stratified-weights-offset breslow cumulative_hazard, stratum 2, profile 3 |
| `test-cox-reference.R` | rc-stratified-weights-offset | breslow | cox_coefficient | 1 | 0.12 | rc-stratified-weights-offset breslow coefficients |
| `test-cox-reference.R` | rc-stratified-weights-offset | breslow | cox_function | 2 | 0.00115 | rc-stratified-weights-offset breslow log-likelihood |
| `test-cox-reference.R` | rc-stratified-weights-offset | breslow | cox_residual | 3 | 0.142 | rc-stratified-weights-offset breslow score |
| `test-cox-reference.R` | rc-stratified-weights-offset | breslow | cox_root | 2 | 0.00409 | rc-stratified-weights-offset breslow midp lower limits |
| `test-cox-reference.R` | rc-stratified-weights-offset | breslow | cox_statistic | 2 | 1.11e-05 | rc-stratified-weights-offset breslow exact statistics |
| `test-cox-reference.R` | rc-stratified-weights-offset | breslow | cox_variance | 8 | 0.0161 | rc-stratified-weights-offset breslow z |
| `test-cox-reference.R` | rc-stratified-weights-offset | breslow | exact | 2 | 0 | rc-stratified-weights-offset breslow funnel limits |
| `test-cox-reference.R` | rc-stratified-weights-offset | breslow | last Newton step | 1 | 7.15e-12 | rc-stratified-weights-offset breslow default |
| `test-cox-reference.R` | rc-stratified-weights-offset | breslow | probability | 2 | 9.19e-05 | rc-stratified-weights-offset breslow midp p-values |
| `test-cox-reference.R` | rc-stratified-weights-offset | efron | closed_form | 7 | 0.000136 | rc-stratified-weights-offset efron direct expected events |
| `test-cox-reference.R` | rc-stratified-weights-offset | efron | cox_baseline | 18 | 0.0878 | rc-stratified-weights-offset efron cumulative_hazard, stratum 2, profile 3 |
| `test-cox-reference.R` | rc-stratified-weights-offset | efron | cox_coefficient | 1 | 0.277 | rc-stratified-weights-offset efron coefficients |
| `test-cox-reference.R` | rc-stratified-weights-offset | efron | cox_function | 2 | 0.000838 | rc-stratified-weights-offset efron log-likelihood |
| `test-cox-reference.R` | rc-stratified-weights-offset | efron | cox_residual | 3 | 0.279 | rc-stratified-weights-offset efron score |
| `test-cox-reference.R` | rc-stratified-weights-offset | efron | cox_root | 2 | 0.00409 | rc-stratified-weights-offset efron midp lower limits |
| `test-cox-reference.R` | rc-stratified-weights-offset | efron | cox_statistic | 2 | 1.11e-05 | rc-stratified-weights-offset efron exact statistics |
| `test-cox-reference.R` | rc-stratified-weights-offset | efron | cox_variance | 8 | 0.0395 | rc-stratified-weights-offset efron z |
| `test-cox-reference.R` | rc-stratified-weights-offset | efron | exact | 2 | 0 | rc-stratified-weights-offset efron funnel limits |
| `test-cox-reference.R` | rc-stratified-weights-offset | efron | last Newton step | 1 | 1.3e-11 | rc-stratified-weights-offset efron default |
| `test-cox-reference.R` | rc-stratified-weights-offset | efron | probability | 2 | 6.3e-05 | rc-stratified-weights-offset efron midp p-values |
| `test-cox-reference.R` | rc-unstratified | breslow | closed_form | 6 | 0.00012 | rc-unstratified breslow direct expected events |
| `test-cox-reference.R` | rc-unstratified | breslow | cox_baseline | 8 | 0.0697 | rc-unstratified breslow survival, stratum 0, profile 2 |
| `test-cox-reference.R` | rc-unstratified | breslow | cox_coefficient | 1 | 0.022 | rc-unstratified breslow coefficients |
| `test-cox-reference.R` | rc-unstratified | breslow | cox_function | 2 | 0.0015 | rc-unstratified breslow log-likelihood |
| `test-cox-reference.R` | rc-unstratified | breslow | cox_residual | 3 | 0.0853 | rc-unstratified breslow score |
| `test-cox-reference.R` | rc-unstratified | breslow | cox_root | 2 | 0.00262 | rc-unstratified breslow midp lower limits |
| `test-cox-reference.R` | rc-unstratified | breslow | cox_statistic | 2 | 1.11e-05 | rc-unstratified breslow exact statistics |
| `test-cox-reference.R` | rc-unstratified | breslow | cox_variance | 8 | 0.0213 | rc-unstratified breslow clustered |
| `test-cox-reference.R` | rc-unstratified | breslow | exact | 2 | 0 | rc-unstratified breslow funnel limits |
| `test-cox-reference.R` | rc-unstratified | breslow | last Newton step | 1 | 2.64e-11 | rc-unstratified breslow default |
| `test-cox-reference.R` | rc-unstratified | breslow | probability | 2 | 2.99e-05 | rc-unstratified breslow exact p-values |
| `test-cox-reference.R` | rc-unstratified | efron | closed_form | 6 | 6.18e-05 | rc-unstratified efron direct expected events |
| `test-cox-reference.R` | rc-unstratified | efron | cox_baseline | 8 | 0.0516 | rc-unstratified efron survival, stratum 0, profile 2 |
| `test-cox-reference.R` | rc-unstratified | efron | cox_coefficient | 1 | 0.0152 | rc-unstratified efron coefficients |
| `test-cox-reference.R` | rc-unstratified | efron | cox_function | 2 | 0.00242 | rc-unstratified efron log-likelihood |
| `test-cox-reference.R` | rc-unstratified | efron | cox_residual | 3 | 0.0735 | rc-unstratified efron score |
| `test-cox-reference.R` | rc-unstratified | efron | cox_root | 2 | 0.00262 | rc-unstratified efron midp lower limits |
| `test-cox-reference.R` | rc-unstratified | efron | cox_statistic | 2 | 1.11e-05 | rc-unstratified efron exact statistics |
| `test-cox-reference.R` | rc-unstratified | efron | cox_variance | 8 | 0.035 | rc-unstratified efron clustered |
| `test-cox-reference.R` | rc-unstratified | efron | exact | 2 | 0 | rc-unstratified efron funnel limits |
| `test-cox-reference.R` | rc-unstratified | efron | last Newton step | 1 | 2.49e-11 | rc-unstratified efron default |
| `test-cox-reference.R` | rc-unstratified | efron | probability | 2 | 3.03e-05 | rc-unstratified efron midp p-values |
| `test-cox-reference.R` | recurrent | breslow | closed_form | 7 | 5.74e-05 | recurrent breslow direct expected events |
| `test-cox-reference.R` | recurrent | breslow | cox_baseline | 18 | 5.76e-07 | recurrent breslow direct ratios |
| `test-cox-reference.R` | recurrent | breslow | cox_coefficient | 1 | 2.7e-08 | recurrent breslow coefficients |
| `test-cox-reference.R` | recurrent | breslow | cox_function | 2 | 0.000165 | recurrent breslow null log-likelihood |
| `test-cox-reference.R` | recurrent | breslow | cox_residual | 3 | 6.66e-07 | recurrent breslow score |
| `test-cox-reference.R` | recurrent | breslow | cox_root | 2 | 0.00405 | recurrent breslow midp lower limits |
| `test-cox-reference.R` | recurrent | breslow | cox_statistic | 2 | 1.11e-05 | recurrent breslow exact statistics |
| `test-cox-reference.R` | recurrent | breslow | cox_variance | 6 | 3.31e-08 | recurrent breslow covariance |
| `test-cox-reference.R` | recurrent | breslow | exact | 2 | 0 | recurrent breslow funnel limits |
| `test-cox-reference.R` | recurrent | breslow | last Newton step | 1 | 1.61e-08 | recurrent breslow default |
| `test-cox-reference.R` | recurrent | breslow | probability | 2 | 3.2e-05 | recurrent breslow midp p-values |
| `test-cox-reference.R` | recurrent | efron | closed_form | 7 | 6.78e-05 | recurrent efron direct expected events |
| `test-cox-reference.R` | recurrent | efron | cox_baseline | 18 | 6.81e-07 | recurrent efron direct ratios |
| `test-cox-reference.R` | recurrent | efron | cox_coefficient | 1 | 5.38e-08 | recurrent efron coefficients |
| `test-cox-reference.R` | recurrent | efron | cox_function | 2 | 0.00122 | recurrent efron log-likelihood |
| `test-cox-reference.R` | recurrent | efron | cox_residual | 3 | 7.11e-07 | recurrent efron score |
| `test-cox-reference.R` | recurrent | efron | cox_root | 2 | 0.00405 | recurrent efron midp lower limits |
| `test-cox-reference.R` | recurrent | efron | cox_statistic | 2 | 1.11e-05 | recurrent efron exact statistics |
| `test-cox-reference.R` | recurrent | efron | cox_variance | 8 | 1.3e-07 | recurrent efron clustered |
| `test-cox-reference.R` | recurrent | efron | exact | 2 | 0 | recurrent efron funnel limits |
| `test-cox-reference.R` | recurrent | efron | last Newton step | 1 | 3.11e-08 | recurrent efron default |
| `test-cox-reference.R` | recurrent | efron | probability | 2 | 2.65e-05 | recurrent efron midp p-values |
| `test-cox-reference.R` | tiny-ties | breslow | closed_form | 6 | 4.11e-06 | tiny-ties breslow direct expected events |
| `test-cox-reference.R` | tiny-ties | breslow | cox_baseline | 8 | 0.264 | tiny-ties breslow survival, stratum 0, profile 3 |
| `test-cox-reference.R` | tiny-ties | breslow | cox_coefficient | 1 | 0.995 | tiny-ties breslow coefficients |
| `test-cox-reference.R` | tiny-ties | breslow | cox_function | 2 | 0.000171 | tiny-ties breslow null log-likelihood |
| `test-cox-reference.R` | tiny-ties | breslow | cox_residual | 3 | 0.175 | tiny-ties breslow martingale |
| `test-cox-reference.R` | tiny-ties | breslow | cox_root | 2 | 0.000307 | tiny-ties breslow midp upper limits |
| `test-cox-reference.R` | tiny-ties | breslow | cox_statistic | 2 | 1.11e-05 | tiny-ties breslow exact statistics |
| `test-cox-reference.R` | tiny-ties | breslow | cox_variance | 8 | 0.105 | tiny-ties breslow z |
| `test-cox-reference.R` | tiny-ties | breslow | exact | 1 | 0 | tiny-ties breslow funnel limits |
| `test-cox-reference.R` | tiny-ties | breslow | last Newton step | 1 | 0.487 | tiny-ties breslow default |
| `test-cox-reference.R` | tiny-ties | breslow | probability | 2 | 8.51e-06 | tiny-ties breslow midp p-values |
| `test-cox-reference.R` | tiny-ties | efron | closed_form | 6 | 4.47e-06 | tiny-ties efron direct expected events |
| `test-cox-reference.R` | tiny-ties | efron | cox_baseline | 8 | 0.172 | tiny-ties efron survival, stratum 0, profile 3 |
| `test-cox-reference.R` | tiny-ties | efron | cox_coefficient | 1 | 0.596 | tiny-ties efron coefficients |
| `test-cox-reference.R` | tiny-ties | efron | cox_function | 2 | 0.000357 | tiny-ties efron log-likelihood |
| `test-cox-reference.R` | tiny-ties | efron | cox_residual | 3 | 0.101 | tiny-ties efron martingale |
| `test-cox-reference.R` | tiny-ties | efron | cox_root | 2 | 0.000293 | tiny-ties efron midp upper limits |
| `test-cox-reference.R` | tiny-ties | efron | cox_statistic | 2 | 1.11e-05 | tiny-ties efron exact statistics |
| `test-cox-reference.R` | tiny-ties | efron | cox_variance | 8 | 0.0629 | tiny-ties efron z |
| `test-cox-reference.R` | tiny-ties | efron | exact | 1 | 0 | tiny-ties efron funnel limits |
| `test-cox-reference.R` | tiny-ties | efron | last Newton step | 1 | 0.478 | tiny-ties efron default |
| `test-cox-reference.R` | tiny-ties | efron | probability | 2 | 7.25e-06 | tiny-ties efron midp p-values |
| `test-cox-reference.R` | zero-weights | breslow | closed_form | 7 | 0.000396 | zero-weights breslow direct expected events |
| `test-cox-reference.R` | zero-weights | breslow | cox_baseline | 18 | 3.95e-06 | zero-weights breslow direct ratios |
| `test-cox-reference.R` | zero-weights | breslow | cox_coefficient | 1 | 9.12e-08 | zero-weights breslow coefficients |
| `test-cox-reference.R` | zero-weights | breslow | cox_function | 2 | 0.00104 | zero-weights breslow null log-likelihood |
| `test-cox-reference.R` | zero-weights | breslow | cox_residual | 3 | 2.13e-06 | zero-weights breslow score |
| `test-cox-reference.R` | zero-weights | breslow | cox_root | 2 | 0.00174 | zero-weights breslow midp lower limits |
| `test-cox-reference.R` | zero-weights | breslow | cox_statistic | 2 | 1.11e-05 | zero-weights breslow exact statistics |
| `test-cox-reference.R` | zero-weights | breslow | cox_variance | 8 | 8.11e-07 | zero-weights breslow robust |
| `test-cox-reference.R` | zero-weights | breslow | exact | 2 | 0 | zero-weights breslow funnel limits |
| `test-cox-reference.R` | zero-weights | breslow | last Newton step | 1 | 5.16e-09 | zero-weights breslow default |
| `test-cox-reference.R` | zero-weights | breslow | probability | 2 | 5.64e-05 | zero-weights breslow exact p-values |
| `test-cox-reference.R` | zero-weights | efron | closed_form | 7 | 0.000296 | zero-weights efron direct expected events |
| `test-cox-reference.R` | zero-weights | efron | cox_coefficient | 2 | 0 | zero-weights efron default (D-58) |
| `test-cox-reference.R` | zero-weights | efron | cox_function | 2 | 0 | zero-weights efron log-likelihood |
| `test-cox-reference.R` | zero-weights | efron | cox_residual | 3 | 0 | zero-weights efron martingale |
| `test-cox-reference.R` | zero-weights | efron | cox_root | 2 | 0.00201 | zero-weights efron midp upper limits |
| `test-cox-reference.R` | zero-weights | efron | cox_statistic | 2 | 1.11e-05 | zero-weights efron exact statistics |
| `test-cox-reference.R` | zero-weights | efron | cox_variance | 5 | 1.47e-08 | zero-weights efron robust |
| `test-cox-reference.R` | zero-weights | efron | exact | 2 | 0 | zero-weights efron funnel limits |
| `test-cox-reference.R` | zero-weights | efron | probability | 2 | 7.4e-05 | zero-weights efron midp p-values |

## Differences from pprof_py that a register entry decides

Each must exceed its tier: the package gives survival's result where pprof_py's differs.

| File | Comparison | Tier | Ratio | Entry | Status |
|---|---|---|---|---|---|
| `test-cox-reference.R` | near-ties breslow timefix = TRUE | cox_coefficient | 4.28e+04 | M-23 | explained |
| `test-cox-reference.R` | near-ties efron timefix = TRUE | cox_coefficient | 5.24e+05 | M-23 | explained |
| `test-cox-reference.R` | lt-stratified breslow D-56 | cox_variance | 2.41e+06 | D-56 | explained |
| `test-cox-reference.R` | zero-weights efron pprof_py (D-58) | cox_coefficient | 2.75e+05 | D-58 | explained |
| `test-cox-reference.R` | lt-weights-offset breslow D-56 | cox_variance | 3.4e+06 | D-56 | explained |
| `test-cox-reference.R` | recurrent breslow D-56 | cox_variance | 9.1e+04 | D-56 | explained |
| `test-cox-reference.R` | zero-weights efron expected events (D-58) | cox_baseline | 4.48e+04 | D-58 | explained |
| `test-cox-reference.R` | zero-weights efron direct expected events (D-58) | cox_baseline | 5.97e+04 | D-58 | explained |
| `test-cox-reference.R` | competing-weights efron cause 1 expected events (D-58) | cox_baseline | 584 | D-58 | explained |
| `test-cox-reference.R` | competing-weights efron cause 1 direct expected events (D-58) | cox_baseline | 579 | D-58 | explained |
| `test-cox-reference.R` | competing-weights efron cause 1 pprof_py (D-58) | cox_coefficient | 4.01e+03 | D-58 | explained |
| `test-cox-fine-gray-reference.R` | competing-simple breslow 1 robust covariance (D-56) | cox_variance | 3.46e+05 | D-56 | explained |
| `test-cox-fine-gray-reference.R` | competing-simple breslow 1_unstratified robust covariance (D-56) | cox_variance | 3.75e+05 | D-56 | explained |
| `test-cox-fine-gray-reference.R` | competing-simple breslow 2 robust covariance (D-56) | cox_variance | 5.19e+04 | D-56 | explained |
| `test-cox-fine-gray-reference.R` | competing-simple breslow 2_unstratified robust covariance (D-56) | cox_variance | 5.09e+04 | D-56 | explained |
| `test-cox-fine-gray-reference.R` | competing-truncated breslow 1 robust covariance (D-56) | cox_variance | 1.84e+05 | D-56 | explained |
| `test-cox-fine-gray-reference.R` | competing-truncated breslow 1_unstratified robust covariance (D-56) | cox_variance | 7.19e+04 | D-56 | explained |
| `test-cox-fine-gray-reference.R` | competing-truncated breslow 2 robust covariance (D-56) | cox_variance | 5.14e+04 | D-56 | explained |
| `test-cox-fine-gray-reference.R` | competing-truncated breslow 2_unstratified robust covariance (D-56) | cox_variance | 5.03e+04 | D-56 | explained |
| `test-cox-fine-gray-reference.R` | competing-weights breslow 1 robust covariance (D-56) | cox_variance | 6.68e+05 | D-56 | explained |
| `test-cox-fine-gray-reference.R` | competing-weights breslow 1_unstratified robust covariance (D-56) | cox_variance | 7.71e+05 | D-56 | explained |
| `test-cox-fine-gray-reference.R` | competing-weights breslow 2 robust covariance (D-56) | cox_variance | 3.04e+05 | D-56 | explained |
| `test-cox-fine-gray-reference.R` | competing-weights breslow 2_unstratified robust covariance (D-56) | cox_variance | 2.95e+05 | D-56 | explained |
| `test-cox-fine-gray-reference.R` | competing-weights efron 1 pprof_py (D-58) | cox_coefficient | 3.96e+03 | D-58 | explained |
| `test-cox-fine-gray-reference.R` | competing-weights efron 1_unstratified pprof_py (D-58) | cox_coefficient | 5.32e+04 | D-58 | explained |
| `test-cox-fine-gray-reference.R` | competing-weights efron 2_unstratified pprof_py (D-58) | cox_coefficient | 1.86e+04 | D-58 | explained |

## Failing tests

Every expectation that failed or raised an error, whether or not it records a comparison.

None.

## Failing comparisons

None.

## Providers within tolerance of a flag threshold

A provider whose flag the test changes as its expected count moves within `cox_baseline`'s allowance is left out of the comparison of flags (the CoxPH brief's §3.5; `cox_near_threshold()`).

None.

## Engine identity

The adapters against direct survival and glmnet calls on the same data, bitwise (the `cox_engine` tier), in these files' tests:

- `test-model-survival.R`: 20 tests, 330 expectations, 0 failed, 0 skipped.
- `test-model-glmnet.R`: 8 tests, 88 expectations, 0 failed, 0 skipped.
- `test-model-fine-gray.R`: 19 tests, 179 expectations, 0 failed, 0 skipped.
- The reference files' tests of the installed engines and of the package's fits against direct `coxph()` calls are among the 3108 expectations above.

## The calibration

`validation/cox-calibration-report.md` (`dev/reference/cox/calibrate.R`, DEC-097): Result: 1058 of 1058 rows pass; 84 rows are explained by a register entry. Result: 4724 flags compared, 0 differ, 0 of them near a threshold; 0 records with other differences.
Explained rows by register entry: D-56 18, D-57 5, D-58 36, D-64 21, D-78 2, M-23 2.

## The register's CoxPH entries

From `dev/DISCREPANCIES.md`. Class B entries that await a methodology owner's sign-off are marked (M-16; the project lead signed off the CoxPH phase's on 2026-10-19, DEC-142).

| ID | Component | Class | Status | Awaiting a methodology owner |
|---|---|---|---|---|
| D-56 | Robust variance | B | verified; decided (delegation): `survival`'s; signed off 2026-10-19 (DEC-142) |  |
| D-57 | Newton–Raphson | B | verified; decided (delegation): `survival`'s; signed off 2026-10-19 (DEC-142) |  |
| D-58 | Zero case weights | B | verified; decided (delegation): left out of the fit; signed off 2026-10-19 (DEC-142) |  |
| D-59 | Aliased covariates, no events | B | verified; decided (delegation): classed error; signed off 2026-10-19 (DEC-142) |  |
| D-60 | Reported baseline hazard | B | verified; decided (delegation): at x = 0 and offset 0; signed off 2026-10-19 (DEC-142) |  |
| D-61 | Penalized cross-validation folds | B | verified; decided (delegation): R's random numbers; signed off 2026-10-19 (DEC-142) |  |
| D-62 | Missing values | A | verified; decided: listwise deletion |  |
| D-63 | Standardized measures | A | verified; does not arise |  |
| D-64 | Large linear predictors | B | verified; decided (delegation): `survival`'s; signed off 2026-10-19 (DEC-142) |  |
| D-65 | Provider-penalized Cox | A and B | verified; deferred to a later brief |  |
| D-66 | Discrete-time models | A and B | verified; deferred to a later brief |  |
| D-67 | Bootstrap standard error of the CV deviance | B | verified; not carried over |  |
| D-68 | `tmerge` | — | verified; not carried over |  |
| D-69 | pprof_py's documentation and R-comparison harness | C and A | verified; not carried over; reported upstream |  |
| D-70 | Providers with no expected events | Presentation | decided |  |
| D-71 | Exact test of an extreme provider | A | verified; decided: flag it |  |
| D-72 | Penalized coefficients at λ_max | B | verified; decided (delegation): exact zeros; signed off 2026-10-19 (DEC-142) |  |
| D-73 | Failures of pprof_py that cannot arise | A | verified; does not arise |  |
| D-74 | Status coded 1/2 | A | verified; decided: accepted |  |
| D-75 | Baselines and curves without covariates | B | verified; decided: unsupported, with a classed error |  |
| D-77 | Unknown provider IDs | Presentation | decided |  |
| D-78 | Penalized paths with few events per covariate | B | verified; decided: the path ends where glmnet's solutions end; signed off 2026-10-19 (DEC-142) |  |
| D-79 | Penalized paths' other outputs | B | verified; decided: not given in C4 |  |
| D-80 | Fine–Gray weights that are not finite | A | verified; decided: raise where survival's weights are not finite, fit otherwise |  |
| D-81 | Fine–Gray outputs not given | B | verified; decided: not given in C5 |  |
