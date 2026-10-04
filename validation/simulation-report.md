# Simulation report: provider tests and intervals with known truth

Generated 2026-10-04 17:35:12 UTC by `validation/run-simulation.R` on R version 4.4.0 (2024-04-24 ucrt), Windows 11 x64 (build 22621); lme4 2.0.6, Matrix 1.7.6.
Working tree at commit 67cc9c2; 200 replicates per family and scenario, seed 20261005; 1896 s.

Informational (DEC-053): this report gates nothing. A departure from nominal is a question for the methodology
owners; the procedures are those of pprof 1.0.3, and changing them would be Class B.

## Design

- 50 providers. Logistic models: 30 to 150 patients per provider, baseline log-odds -1, outlying effects +0.8
  and -0.8 on the log-odds scale. Linear models: 10 to 60 patients per provider, baseline 0, residual
  standard deviation 1, outlying effects +0.5 and -0.5.
- Covariates: x1 = N(0, 1) plus a provider-level N(0, 0.25) shift, x2 = N(0, 1), x3 = Bernoulli(0.4);
  beta = (0.5, -0.3, 0.2).
- Scenarios: no provider effects; six outlying providers (three above, three below), the others without an effect.
- Each model is fit with its defaults (`fit_logistic_fe()`, `fit_linear_fe()`, `fit_linear_re()`,
  `fit_linear_cre(within_between = "x1")`, `fit_logistic_re()`, `fit_logistic_cre(within_between = "x1")`),
  then `test_providers()`, `provider_effects()`, and `standardize_providers("indirect")` run at their defaults
  (two-sided, level 0.95, the family's null) with intervals of the test's kind. True values: see the script's header.

## Results

Percentages with Monte Carlo standard errors in parentheses (replicates as clusters). Size: providers without an
effect that are flagged. Power: outlying providers flagged in the direction of their effect; "wrong" counts those
flagged in the other direction. Missing: providers whose test has no flag. Coverage: intervals that contain the
true provider effect ("effect") or the true indirect measure ("measure"), for providers without ("none") and
with ("outlier") an effect. Singular: lme4 fits on the boundary (provider variance 0).

| Family | Scenario | Test | Fits | Errors | Singular | Size | Power | Wrong | Missing | Effect coverage, none | Effect coverage, outlier | Measure coverage, none | Measure coverage, outlier |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| logistic_fe | no provider effects | exact | 200 | 0 | 0 | 4.9 (0.2) | — | — | 0 | 94.8 (0.2) | — | 95.1 (0.2) | — |
| logistic_fe | six outlying providers | exact | 200 | 0 | 0 | 5.0 (0.2) | 86.4 (1.0) | 0 | 0 | 94.8 (0.2) | 96.1 (0.6) | 95.0 (0.2) | 95.7 (0.6) |
| linear_fe | no provider effects | Wald | 200 | 0 | 0 | 5.5 (0.2) | — | — | 0 | 94.5 (0.2) | — | 94.5 (0.2) | — |
| linear_fe | six outlying providers | Wald | 200 | 0 | 0 | 5.5 (0.2) | 77.2 (1.1) | 0 | 0 | 94.5 (0.2) | 95.0 (0.6) | 94.5 (0.2) | 94.8 (0.7) |
| linear_re | no provider effects | Wald | 200 | 0 | 99 | 0.1 (0.0) | — | — | 4950 | 100.0 (0.0) | — | 100.0 (0.0) | — |
| linear_re | six outlying providers | Wald | 200 | 0 | 0 | 0.7 (0.1) | 49.6 (1.8) | 0 | 0 | 99.3 (0.1) | 40.8 (2.4) | 99.3 (0.1) | 40.8 (2.4) |
| linear_cre | no provider effects | Wald | 200 | 0 | 96 | 0.0 (0.0) | — | — | 4700 | 100.0 (0.0) | — | 100.0 (0.0) | — |
| linear_cre | six outlying providers | Wald | 200 | 0 | 0 | 0.8 (0.1) | 46.2 (1.8) | 0 | 0 | 99.2 (0.1) | 38.1 (2.3) | 99.2 (0.1) | 38.1 (2.3) |
| logistic_re | no provider effects | Wald | 200 | 0 | 110 | 0.0 (0.0) | — | — | 3350 | 100.0 (0.0) | — | 100.0 (0.0) | — |
| logistic_re | six outlying providers | Wald | 200 | 0 | 0 | 0.9 (0.1) | 60.3 (1.7) | 0 | 0 | 99.1 (0.1) | 44.5 (2.2) | 99.1 (0.1) | 44.1 (2.2) |
| logistic_cre | no provider effects | Wald | 200 | 0 | 124 | 0.0 (0.0) | — | — | 3900 | 100.0 (0.0) | — | 100.0 (0.0) | — |
| logistic_cre | six outlying providers | Wald | 200 | 0 | 0 | 0.7 (0.1) | 59.9 (1.6) | 0 | 0 | 99.3 (0.1) | 38.8 (2.2) | 99.3 (0.1) | 38.2 (2.2) |
