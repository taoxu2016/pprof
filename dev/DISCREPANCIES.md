# Discrepancy register

Every behavioral difference between the reference (pprof 1.0.3, commit 5260838) and the rewrite, whether intended or discovered.

Classes (brief §3.3):

- A: the reference crashes, errors, returns NULL, misaligns results with provider IDs, or behaves nondeterministically. May be fixed, with a regression test.
- B: any change to a numeric value, flag, inclusion decision, or default. Not made without written sign-off from a methodology owner. Until then, the rewrite reproduces the reference.
- C: documentation or messages contradict behavior. Fix the documentation or message to match the behavior.

Entries marked "Presentation (brief §3.2)" record changes the brief permits without sign-off: names, container shapes, column names, message wording, print formatting, internal object structure. They are listed so the migration guide can cite them.

A discrepancy is never resolved by loosening a tolerance, editing a fixture, or dropping a test case.

Status values: candidate, verified, decided (fix, preserve, or awaiting sign-off), resolved (with a regression test).

Evidence IDs (`V10.8` and so on) refer to the Phase 0 audit logs in `dev/design/audit/output/`. Code locations are `path:line` at commit `5260838`. Every minimal example below runs against the reference after `library(pprof)`.

## Summary

| ID | Component | Class | Status | One line |
|---|---|---|---|---|
| D-01 | `logis_fe`, `logis_firth` screening | C | verified | Warning counts `n_i <= cutoff`, inclusion is `n_i >= cutoff`; help says excluded rows are kept with `included = 0` |
| D-02 | `logis_fe` help | C | verified | `backtrack` documented default FALSE (code TRUE); `stop` help refers to `iter.max` |
| D-03 | C++ fitters | C (message); loop bounds preserved | verified | No convergence status; "converged" printed at the iteration limit; SerBIN can run `max_iter + 1` |
| D-04 | `test.logis_fe(score_modified = FALSE)` | A | verified | Non-finite statistics are dropped, so the result no longer aligns with providers and `test()` errors |
| D-05 | `logis_firth(threads > 1)` | A | verified; fixed (Phase 4) | Data race on `d_beta` stops the iteration after 1 to 5 steps; beta off by up to 0.57 |
| D-06 | `test.logis_fe(test = "robust_wald")` | A | verified | Passes validation, returns NULL |
| D-07 | `plot.logis_fe(test = "exact")` | A | verified | Always errors (`.data` pronoun outside a data mask) |
| D-08 | several methods | A | verified; resolved (Phases 3 and 5) | Rely on partial matching of `$` (`fit$obs`, `object$data_includ`) |
| D-09 | `print` methods | Presentation | verified | `print.logis_cre` unregistered; all RE/CRE prints dump the whole object |
| D-10 | `summary.logis_fe(test = "lr"/"score")` | B | verified; reproduced (Phase 3); awaiting sign-off | Null refits ignore the original fit's settings; the likelihood clamp hard-codes 10; a smaller `cutoff` makes the refit fail |
| D-11 | `linear_re`, `logis_re` vector interface | A | verified; fixed in the wrappers (Phase 4) | `cbind()` coerces mixed inputs to character; no final `else` |
| D-12 | `logis_firth` result | B (question M-2) | verified; signed off: preserve (Phase 4 gate) | Class `logis_fe` with unpenalized variance, log-likelihood, AIC, BIC |
| D-13 | `linear_cre`, `logis_cre` | B (question M-3) | verified; signed off: preserve (Phase 4 gate) | Provider means computed before complete-case filtering |
| D-14 | `null` validation | A | verified; fixed (Phases 3 and 5) | Integer `null` accepted by `test()`, rejected by `SM_output()`, `confint()`, `plot()` |
| D-15 | `test` methods | Presentation | verified; integer flags in the new API, the factor in the wrappers (Phases 3 and 5) | Flags are factors whose levels depend on the data |
| D-16 | `test.linear_fe` | none (made explicit) | verified | Reference distribution chosen by a hidden attribute |
| D-17 | `data_check` | C | verified | Stops on any missing value; fits delete incomplete rows |
| D-18 | FE formula interface | A | verified; fixed in the data layer (Phase 2) | Transformed and interaction terms fail; factor levels with spaces break the design matrix |
| D-19 | `confint.logis_fe(option = "SM")` | A | verified | Non-numeric IDs misalign intervals with providers (61 of 100 in the example) |
| D-20 | `logis_fe(threads > 1)` | none (tolerance) | verified | Element-wise OpenMP information block differs from BLAS at 1e-15 relative |
| D-21 | thread counts | A (DEC-001) | verified; fixed (Phases 3 and 5) | `threads = 4` hard-coded in logistic RE/CRE intervals; 2 by default in `SM_output()` |
| D-22 | `logis_fe(threads < 1)` | A | verified | Uninitialized information matrix; silently returns beta near 0 |
| D-23 | `logis_fe(method = "BAN", backtrack = 2)` | A | verified | Runs zero iterations and returns the starting values |
| D-24 | `logis_fe` default stopping rule | B | verified; preserved (Phase 3); awaiting sign-off for any default change | `stop = "or"` can stop before provider effects converge (0.04 logit error at n = 1.2M) |
| D-25 | `logis_firth` help | C | verified; fixed (Phase 4) | Help says `max.iter` defaults to 10,000; code default is 1,000 |
| D-26 | `test.logis_fe(score_modified = FALSE)` help | C (question M-7) | verified | Called a "standard score test" but does not refit under the null |
| D-27 | `parm` with integer provider IDs | A | verified; fixed (Phases 3 and 5) | `parm = 1:3` fails the class check for an integer ID column |
| D-28 | factor provider IDs in `confint.logis_fe` | A | verified | Exact and score intervals look up gamma by the factor's integer code |
| D-29 | `confint.logis_fe(stdz = "direct")` | A | verified | Selects providers through `data$ProvID`; fails for any other column name |
| D-30 | `summary.logis_fe(test = "lr"/"score")` | A | verified | Fails with one or two covariates |
| D-31 | `summary.logis_re`, `summary.logis_cre` | B | verified; reproduced in the new API and the wrappers (Phase 5); awaiting sign-off | p = 2(1 - pnorm(z)) without `abs()`: p-values above 1 for negative estimates |
| D-32 | `confint.linear_fe` | B (question M-8) | verified; reproduced in the new API and the wrappers (Phase 5); awaiting sign-off | Uses t for the simplified variance and z for the full variance, the reverse of `test.linear_fe` |
| D-33 | interval attributes | C | verified; results carry the level as a number, the wrappers keep the attributes (Phases 3 and 5) | `confidence_level` is "95 %" (FE) or "0.95 %" (RE/CRE); `logis_cre` rate interval labeled "RE logis" |
| D-34 | provider ordering | B | verified; reproduced (Phases 3 to 5); awaiting sign-off for (2) | Character IDs are ordered by the session's collation locale, which also fixes the bootstrap draw order |
| D-35 | bundled data docs | C | verified | `ExampleDataBinary` has 7,944 observations, documented as 7,994 |
| D-36 | messages and side effects | Presentation | verified; the plot warnings fixed in the wrappers (Phase 6) but `geom_errorbarh()`'s | `linear_fe`, `linear_re`, `logis_re` always print messages; attaching pprof prints a `car` message; `bar_plot()` triggers a ggplot2 deprecation warning, and `caterpillar_plot(use_flag = TRUE)` an unused-argument warning under ggplot2 4 |
| D-37 | vignettes | C | verified | Describe a different clamp, nonexistent functions, and calls that now fail |
| D-38 | `logis_fe` with collinear covariates | C | verified | Unidentified estimates with variances near 7e13 and no rank-deficiency warning |
| D-39 | `logis_fe`, `logis_firth` inputs | A | decided (fix) | Non-binary outcomes, `max.iter` <= 0, `tol` <= 0, and `bound` <= 0 return meaningless or unfitted results without a warning |
| D-40 | AUC without pROC | none (tolerance) | verified; decided (option 1, Phase 3 gate) | The Mann-Whitney AUC equals pROC's bitwise in 57 of 59 fits and differs in the last bit in 2 |
| D-41 | `logis_fe`, `logis_firth` with factor IDs | A | verified; fixed (Phases 3 and 4) | Fail when screening excludes a provider: the excluded factor levels become empty provider blocks |
| D-42 | `logis_firth` with singular information | A | verified; fixed (Phase 4) | Terminates the R session when the Schur complement of the information cannot be inverted |
| D-43 | `plot.linear_fe` with the full variance | B (question M-18) | verified; awaiting sign-off | Limits use σ/sqrt(n_i) and normal quantiles, flags the full variance and t, so points outside the limits can be unflagged |
| D-44 | RE and CRE `summary()` | C | verified; fixed in the help (Phase 5) | The intercept is selected only as `"(intercept)"`, while its row is named `"(Intercept)"`; the help does not say so |
| D-45 | `null` with more than one value | A | verified; fixed in the wrappers (Phases 3 and 5) | RE and CRE `test()` recycle it over the providers by position; every `summary()` applies it to the coefficients by position; documented as a number |
| D-46 | RE and CRE `summary()` without the lme4 fit | A | verified; fixed in the wrappers (Phase 5) | Fails when `attr(, "model")` is missing, though the intervals need only the stored covariance |
| D-47 | `caterpillar_plot()`, `bar_plot()` colours | Presentation | verified; reproduced in the wrappers, fixed in the new plots (Phase 6) | Colours go to the flags present in sorted order, so the same colour can mean higher, lower, or as expected, unlike the funnel plot |
| D-48 | `caterpillar_plot()`, `bar_plot()` help | C | verified; fixed in the help (Phase 6) | `bar_width` has no effect; the input is called `test_df`; infinite limits are said to arise for providers with all or no events and to be shortened |
| D-49 | `bar_plot()`'s plot data | Presentation | verified; documented (Phase 6) | The plot's data are a data frame, where pprof 1.0.3's are dplyr's grouped tibble; the data and the built plot are the same |

---

### D-01: Screening warning and help contradict the inclusion rule

- Component: `logis_fe` (`R/logis_fe.R:191-193`), `logis_firth` (`R/logis_firth.R:158-160`), help for `cutoff` and `data_include`.
- Class (proposed): C
- Description: Providers are included when `n_i >= cutoff`, but the warning counts `sum(prov.size <= cutoff)`, so providers of size exactly `cutoff` are reported as filtered out although they are kept. The help says excluded providers are "labeled as include = 0", and that `data_include` holds an `included` column; in fact excluded rows are dropped from `data_include`, so `included` is always 1.
- Minimal reproducible example:
  ```r
  set.seed(1)
  d <- data.frame(Y = rbinom(70, 1, 0.3), ProvID = rep(c("p09", "p10", "p11", "p40"), c(9, 10, 11, 40)), x1 = rnorm(70))
  fit <- logis_fe(data = d, Y.char = "Y", Z.char = "x1", ProvID.char = "ProvID")
  #> Warning: 2 out of 4 providers considered small and filtered out!
  rownames(fit$coefficient$gamma)   # "p10" "p11" "p40": only p09 was excluded
  nrow(fit$data_include)            # 61: the 9 rows of p09 are gone
  ```
- Affected outputs: warning text; documentation.
- Statistical impact: none. Inclusion follows `n_i >= cutoff` (V10.8).
- Options: (1) fix the count in the message; (2) also change inclusion to `>` to match the message (Class B, not proposed).
- Recommendation: (1). The new provider table keeps excluded providers with `included = FALSE` and the screening notice reports the true count.
- Decision owner: project lead.
- Status: verified (V10.8); option (1) fixed: `fit_logistic_fe()` warns with `pprof_warning_screening` and the true count (Phase 3, step 2), and the `logis_fe()` wrapper keeps the reference's wording with the true count (Phase 3, step 5). The same holds for `fit_logistic_firth()` (Phase 4, step 2) and the `logis_firth()` wrapper (Phase 4, step 3).
- Regression test: the inclusion rule (n_i >= `min_provider_size`, including a provider of exactly that size) in `tests/testthat/test-data-prepare.R` (Phase 2); the wrappers' warning and its count in `tests/testthat/test-compat-logis-fe.R` and `tests/testthat/test-compat-fits.R`.

### D-02: `logis_fe` help states wrong defaults

- Component: `logis_fe` roxygen (`R/logis_fe.R:26`, `:38`).
- Class (proposed): C
- Description: The help says `backtrack` defaults to FALSE; the code default is TRUE. The `stop` description says "If `iter.max` is achieved"; the argument is `max.iter`.
- Minimal reproducible example: `formals(logis_fe)$backtrack` returns `TRUE`; `?logis_fe` says "The default is FALSE."
- Affected outputs: documentation.
- Statistical impact: none.
- Options: fix the documentation.
- Recommendation: fix; the new help is generated from the argument vocabulary in `NAMING.md`.
- Decision owner: project lead.
- Status: verified (V10.18); fixed in the help of the `logis_fe()` wrapper (Phase 3): `backtrack` defaults to TRUE and the `stop` description names `max.iter`.
- Regression test: not applicable (documentation); a check of the help against `formals()` is planned with the documentation of Phase 8.

### D-03: No convergence status; "converged" printed at the iteration limit

- Component: `logis_BIN_fe_prov` (`src/Fixed_effect.cpp:358`, `:467-469`), `logis_fe_prov` (`:143`, `:250`, `:329-331`), `logis_firth_prov` (`src/Firth.cpp:138`, `:406-408`).
- Class (proposed): C for the message. The loop bounds are statistical behavior and are preserved.
- Description: SerBIN loops `while (iter <= max_iter)` and can run `max_iter + 1` iterations; BAN and Firth stop at `max_iter`. All three print "converged after N iterations" whether or not the criterion was met, and the C++ results carry no status. Firth's `iter` and `crit` are returned by C++ and discarded in R.
- Minimal reproducible example:
  ```r
  data(ExampleDataBinary)
  d <- data.frame(Y = ExampleDataBinary$Y, ProvID = ExampleDataBinary$ProvID, ExampleDataBinary$Z)
  fit <- logis_fe(data = d, Y.char = "Y", Z.char = paste0("z", 1:5), ProvID.char = "ProvID",
                  max.iter = 3, tol = 1e-300, stop = "beta")
  #> serBIN (Rcpp) algorithm converged after 4 iterations!
  ```
- Affected outputs: progress message; no convergence fields in the object.
- Statistical impact: none on estimates. Users cannot tell an unconverged fit from a converged one.
- Options: (1) keep the loop bounds, add diagnostics (iterations, converged flag, final criterion, stop rule) and warn with `pprof_warning_not_converged` when the limit is reached; (2) also change SerBIN to `iter < max_iter` (Class B, not proposed).
- Recommendation: (1). Diagnostics are additive (brief §5.2).
- Decision owner: project lead.
- Status: verified (V10.4); option (1) fixed: `fit_logistic_fe()` keeps the convergence diagnostics and warns with `pprof_warning_not_converged` (Phase 3, step 2); the `logis_fe()` wrapper prints "not converged after N iterations!" and passes the warning on (Phase 3, step 5). Likewise for Firth: `fit_logistic_firth()` keeps the diagnostics and warns (Phase 4, step 2), and the `logis_firth()` wrapper prints "Algorithm with N cores not converged after N iterations." and passes the warning on (Phase 4, step 3).
- Regression test: `tests/testthat/test-model-logistic-fe.R` (4 SerBIN iterations for `max_iter = 3`, `converged = FALSE`, the warning class), `tests/testthat/test-model-logistic-firth.R` (3 Firth iterations for `max_iter = 3`), and `tests/testthat/test-compat-logis-fe.R` and `tests/testthat/test-compat-fits.R` (the wrappers' messages and warnings).

### D-04: Standard score test drops non-finite statistics

- Component: `Modified_score` (`src/Fixed_effect.cpp:591-593`), `test.logis_fe` (`R/test.logis_fe.R:146-178`).
- Class (proposed): A
- Description: The C++ routine fills a vector with NaN, computes statistics for the requested providers, then keeps only finite values. A provider whose statistic is not finite (for example when every null probability rounds to exactly 0 or 1, so the variance is 0) disappears from the vector, the vector no longer lines up with the provider IDs, and `data.frame()` fails.
- Minimal reproducible example:
  ```r
  data(ExampleDataBinary)
  fit <- logis_fe(Y = ExampleDataBinary$Y, Z = ExampleDataBinary$Z, ProvID = ExampleDataBinary$ProvID, message = FALSE)
  test(fit, test = "score", score_modified = FALSE, null = 50)
  #> Error: row names supplied are of the wrong length
  ```
  A realistic trigger is a provider whose covariates push `plogis(gamma0 + Z beta)` to exactly 1 (V13.6: provider with covariate near 45 and beta near 1).
- Affected outputs: `test.logis_fe(test = "score", score_modified = FALSE)`.
- Statistical impact: none on cases that work today; failing cases error.
- Options: (1) keep non-finite statistics in place and report them as `NaN`/`Inf` with `p_value = NA` and `flag = NA`, plus a warning; (2) error with a classed condition naming the providers.
- Recommendation: (1), so that the other providers' results are still returned and aligned.
- Decision owner: project lead.
- Status: verified (V13.6); option (1) approved with the Phase 3 plan (2026-10-02). Fixed in `test_providers()` (Phase 3, step 3): every requested provider keeps its place, and a non-finite statistic gets a missing p-value and flag and a `pprof_warning_undefined_statistics` warning that names the providers. The wrapper applies it from the switch (Phase 3, step 5; per-case expectation in `tests/testthat/helper-reference-overrides.R`).
- Regression test: `tests/testthat/test-profile-regression.R` (the `logis_fe-d04` fit), and the per-case expectation of `test-d04-score-standard` in `tests/testthat/helper-reference-overrides.R`. The reference's values for the other 29 providers come from the fixture `test-d04-score-standard-others`, added at the Phase 3 gate (regeneration approved by the project lead, 2026-10-03): the reference's standard score test of those providers on `syn_d04_double`, the same data with the provider IDs stored as doubles, because `syn_d04` stores them as integers, which the reference cannot select (D-27). Both tests compare the new API's statistics, p-values, and flags with it bitwise. Before the gate, `tests/testthat/test-cpp-legacy-comparison.R` checked those statistics against the reference's `Modified_score()` until that routine was removed at the switch (Phase 3 step 5).

### D-05: Firth with `threads > 1` stops early because of a data race

- Component: `logis_firth_prov` (`src/Firth.cpp:253-260`, `:355-357`, and the whole parallel region `:133-399`).
- Class (proposed): A
- Description: `d_beta` is declared inside the parallel region, so each thread has its own copy. One thread assigns it in an `omp single` block; a later `omp single` block computes the stopping criterion from `d_beta` on whichever thread arrives first. When that is a different thread its `d_beta` is empty, the norm is 0, and the loop ends. The same region calls `Rcpp::Rcout`, `Rcpp::stop`, and Armadillo routines that can throw.
- Minimal reproducible example (run several times; needs OpenMP):
  ```r
  data(ExampleDataBinary)
  for (i in 1:4) print(logis_firth(Y = ExampleDataBinary$Y, Z = ExampleDataBinary$Z,
                                   ProvID = ExampleDataBinary$ProvID, threads = 2)$coefficient$beta[1])
  ```
  In eight separate sessions the iteration count was 5, 3, 2, 5, 1, 1, 1, 1 (16 with one thread) and beta differed from the single-threaded result by up to 0.57 (V12.3).
- Affected outputs: every output of `logis_firth(threads > 1)`.
- Statistical impact: severe and silent: estimates far from the Firth solution, varying between runs.
- Options: (1) restructure the parallel loop so the criterion is computed from shared state, with no R API calls or exceptions inside the region; (2) run Firth single-threaded only.
- Recommendation: (1). Results with `threads > 1` must then match `threads = 1` within the Tier 2 tolerance. Fixtures are generated with `threads = 1`, which the reference computes correctly (V12.1).
- Decision owner: project lead.
- Status: verified (V12.3); fixed in the C++ engine (Phase 4, step 1, 2026-10-03). `cpp_logistic_firth()` (`src/logistic/firth.cpp`) computes each provider's part in parallel into its own slots and adds every sum over providers in provider order, as the reference does with one thread. Its results with 2 threads are bitwise identical to those with 1 thread, which are bitwise identical to the reference's single-threaded routine. Its parallel regions contain no R API call, and no exception leaves them. `fit_logistic_firth()` uses it from step 2, and the `logis_firth()` wrapper from the switch (step 3).
- Regression test: `tests/testthat/test-cpp-firth.R` ("two threads give results identical to one thread, and repeated runs agree (D-05)": bitwise, on four datasets), `tests/testthat/test-model-logistic-firth.R` ("two threads give a fit identical to one thread (D-05)", for `fit_logistic_firth()`), and `tests/testthat/test-compat-fits.R` (the same for the wrapper); all run two threads where OpenMP is available.

### D-06: `test = "robust_wald"` returns NULL

- Component: `test.logis_fe` (`R/test.logis_fe.R:66`, `:308-310`).
- Class (proposed): A
- Description: Validation accepts `"robust_wald"`, but the branch tests `"robust wald"` (with a space), so no branch runs and the function returns NULL. No robust Wald test is implemented anywhere.
- Minimal reproducible example: `is.null(test(fit, test = "robust_wald"))` is TRUE.
- Affected outputs: `test.logis_fe`.
- Statistical impact: none (no numbers are produced).
- Options: (1) reject the value with `pprof_error_invalid_input`; (2) implement a robust Wald test (a new method; out of scope, brief §2.2).
- Recommendation: (1).
- Decision owner: project lead.
- Status: verified (V13.8); option (1) approved with the Phase 3 plan (2026-10-02). `test_providers()` accepts only `"exact"`, `"bootstrap"`, `"score"`, and `"wald"`, so other values raise `pprof_error_invalid_input` (Phase 3, step 3). The wrapper applies it from the switch (Phase 3, step 5; per-case expectation in `tests/testthat/helper-reference-overrides.R`).
- Regression test: `tests/testthat/test-profile-regression.R`.

### D-07: Exact funnel plot always errors

- Component: `plot.logis_fe` (`R/plot.logis_fe.R:79-142`).
- Class (proposed): A
- Description: The exact branch calls `sapply(probs_list, .data$qpoibin, ...)`. Outside a data mask, rlang's `.data` pronoun errors ("Can't subset `.data` outside of a data mask context"). `qpoibin` is not imported either. The branch has never produced output.
- Minimal reproducible example: `plot(fit, test = "exact")`.
- Affected outputs: `plot.logis_fe(test = "exact")`.
- Statistical impact: none today (no output exists). Implementing the evident intent (mid-p Poisson-binomial control limits, Wu et al. 2023) would create numbers that have no reference value.
- Options: (1) raise `pprof_error_unsupported_inference` for exact funnel limits; (2) implement exact limits in the profiling layer from the code's evident intent, validated independently, with methodology sign-off.
- Recommendation: (1) until a methodology owner approves (2). Recorded as open question M-9.
- Decision owner: methodology owner for (2); project lead for (1).
- Status: verified (V13.21); option (1) approved with the Phase 3 plan (2026-10-02). The new `funnel_limits()` computes the score-test limits of K-110 only, and `plot.logis_fe(test = "exact")` raises `pprof_error_unsupported_inference` (Phase 3, step 5); the fixture `plot-binary-exact` records an error, as before.
- Regression test: `tests/testthat/test-compat-logis-fe.R` (the error class).

### D-08: Reliance on partial matching of `$`

- Component: `SM_output.logis_fe` (`R/SM_output.logis_fe.R:101`, `:122`, `:133`: `fit$obs`); `confint.logis_re` and `confint.logis_cre` (`sum(object$obs)`); `summary.linear_re` and `summary.linear_cre` (`nrow(object$data_includ)`).
- Class (proposed): A (fragile; works today)
- Description: These lines work only because `$` partially matches `observation` and `data_include`. Adding any field whose name starts with the same letters would silently change the result to NULL-based arithmetic or an error.
- Minimal reproducible example: `options(warnPartialMatchDollar = TRUE); SM_output(fit, measure = "rate")` warns "partial match of 'obs' to 'observation'".
- Affected outputs: indirect and direct rates, RE/CRE interval rates, RE/CRE summaries.
- Statistical impact: none today.
- Options: use full names.
- Recommendation: the rewrite never relies on partial matching; tests run with `warnPartialMatchDollar` and `warnPartialMatchArgs` and treat the warnings as failures.
- Decision owner: project lead.
- Status: verified (V13.13, V15.7); resolved: the compatibility methods use full names (`SM_output.logis_fe()` from Phase 3, the RE and CRE `confint()` and `summary()` from Phase 5, step 3), and DEC-021's two allowances were removed with the reference's code (Phase 5, step 3).
- Regression test: the rewrite's tests run in strict mode (`tests/testthat/helper-strict.R`, DEC-030); the reference harness fails on any partial match, and `tests/testthat/test-reference-overrides.R` runs the cases that relied on the two matches (DEC-021).

### D-09: Print methods

- Component: `print.logis_cre` (`R/logis_cre.R:197-204`), `print.linear_re`, `print.logis_re`, `print.linear_cre`.
- Class (proposed): Presentation (brief §3.2)
- Description: `print.logis_cre` is defined but its roxygen tag says `@exportS3Method print linear_re`, so it is not registered and printing a `logis_cre` object falls through to `print.default`, including the full lme4 fit in `attr(, "model")`. The registered RE/CRE print methods drop the attribute but print the whole list, including `data_include` (39,891 lines for `logis_re` on the example data).
- Minimal reproducible example: `length(capture.output(print(logis_cre(...))))`.
- Affected outputs: console output only.
- Statistical impact: none.
- Options: new `print` methods that show a compact summary.
- Recommendation: new print methods for every class (Phase 3 onward).
- Decision owner: project lead.
- Status: verified (V15.8). The new models print compactly through `print.pprof_model()` (Phase 3; the Phase 4 models from step 2). The wrappers keep the reference's printing (Phase 4, step 3): `print.linear_re()`, `print.logis_re()`, and `print.linear_cre()` drop the lme4 fit and print the rest with `print.default()`, and no method is registered for `logis_cre`.
- Regression test: the snapshot in `tests/testthat/test-present.R` and the print checks in `tests/testthat/test-model-linear-fe.R`, `test-model-mixed.R`, and `test-model-logistic-firth.R` (the new print method); `tests/testthat/test-compat-fits.R` (the wrappers' printing).

### D-10: LR and score covariate tests refit with default settings

- Component: `summary.logis_fe` (`R/summary.logis_fe.R:135-208`).
- Class (proposed): B
- Description: For each covariate, the null model is refit by `logis_fe(data = data.null, Y.char, Z.char, ProvID.char, message = FALSE)`: SerBIN with `tol = 1e-5`, `stop = "or"`, `bound = 10`, `cutoff = 10`, `max.iter = 10000`, `backtrack = TRUE`, regardless of the original fit's method and settings. The LR statistic clamps gamma to `median(gamma) +/- 10` in both likelihoods, whatever `bound` the fit used. Each covariate is refit twice (once for the statistic, once for the p-value). When the original fit used `cutoff < 10`, the refit drops providers the original fit kept and `rep()` fails ("invalid 'times' argument").
- Minimal reproducible example:
  ```r
  set.seed(3)
  small <- data.frame(Y = rbinom(1000, 1, 0.3), ProvID = c(rep(1:40, each = 20), rep(41:65, each = 8)),
                      x1 = rnorm(1000), x2 = rnorm(1000), x3 = rnorm(1000))
  fit5 <- logis_fe(data = small, Y.char = "Y", Z.char = c("x1", "x2", "x3"), ProvID.char = "ProvID",
                   cutoff = 5, message = FALSE)
  summary(fit5, test = "lr")
  #> Error: invalid 'times' argument
  ```
- Affected outputs: `summary.logis_fe(test = "lr")` and `(test = "score")` statistics and p-values.
- Statistical impact: the null fit can stop at a different point than the full fit (D-24), so the LR statistic mixes two convergence levels; providers can be dropped from the null model.
- Options: (1) preserve: refit with the reference defaults (the rewrite reproduces this exactly, including the double refit's identical result, which can be computed once); (2) refit with the original fit's settings (Class B).
- Recommendation: preserve (1) until sign-off; propose (2) to the methodology owners (question M-5). Computing each null fit once is a pure performance change with identical results. The `cutoff < 10` failure is reproduced as an error with a classed condition until (2) is decided.
- Decision owner: methodology owner.
- Status: verified (V13.19); awaiting sign-off. Option (1) is reproduced in `test_coefficients()` (Phase 3, step 3): `refit_without()` refits with the reference defaults, once per covariate, and raises `pprof_error_data` when the default `min_provider_size` would exclude providers the model includes.
- Regression test: `tests/testthat/test-inference-coefficients.R` (the `summary-binary-lr` and `summary-binary-score` fixtures, and the classed error on the `logis_fe-cutoff5` fit).

### D-11: RE vector interface coerces inputs and has no final `else`

- Component: `linear_re` and `logis_re` (`R/linear_re.R:132-152`, `R/logis_re.R:132-151`), and the `data_include` construction in all RE/CRE fits.
- Class (proposed): A
- Description: The vector interface builds its data with `as.data.frame(cbind(Y, ProvID, Z))`. With a character `ProvID` and a matrix `Z`, `cbind()` makes everything character and `lmer()` fails ("response must be numeric"; `glmer()`: "response must be numeric or factor"), after making a factor level of every distinct covariate value. When no input format matches there is no final `else`, so the error is "object 'fit_re' not found". All RE/CRE fits also build `data_include` with `cbind()`, so with character IDs `data_include$Y` is character (methods use other fields, so numbers are unaffected).
- Minimal reproducible example:
  ```r
  data(ExampleDataLinear)
  linear_re(Y = ExampleDataLinear$Y, Z = as.matrix(ExampleDataLinear$Z), ProvID = paste0("P", ExampleDataLinear$ProvID))
  #> Error: response must be numeric
  linear_re(Y = ExampleDataLinear$Y)
  #> Error: object 'fit_re' not found
  ```
  On the full example data the first call runs for many minutes before it fails (more than 9 minutes and 2.3 GB on 2026-10-03, when it was stopped); V15.9 ran it on the first 12 rows of providers 1 to 5, where it fails at once.
- Affected outputs: `linear_re`, `logis_re` vector interface; `data_include` of every RE/CRE fit.
- Statistical impact: none on cases that work.
- Options: build data frames column by column; validate inputs with classed errors.
- Recommendation: fix in the data layer; the compatibility wrappers keep accepting the vector interface.
- Decision owner: project lead.
- Status: verified (V15.9, V15.13); fixed in the `linear_re()` and `logis_re()` wrappers (Phase 4, step 3, as the plan states): a character `ProvID` with a matrix `Z`, which `cbind()` turns into text, and a call that matches no input format raise `pprof_error_invalid_input`. No fixture covers the vector interface, so it was compared live with the reference (2026-10-03, reference library, lme4 2.0-6, Matrix 1.7-6): the reference fails on both inputs as described above (on 60 rows), and with numeric IDs (matrix or data frame `Z`) and with character IDs and a data frame `Z`, the wrappers' objects equal the reference's in every field, attribute, and message, and their lme4 fits differ only in the environments of their formulas. The wrappers build `data_include` with `cbind()` as the reference does, so it stays text with character IDs; the old methods read no numbers from it. The new fits take a formula, a data frame, and a provider column, so they have no vector interface.
- Regression test: `tests/testthat/test-compat-fits.R` ("linear_re() and logis_re() raise classed errors where the reference's vector interface failed (D-11)").

### D-12: Firth returns a `logis_fe` object with unpenalized summaries

- Component: `logis_firth` (`R/logis_firth.R:189-266`).
- Class (proposed): B (methodology question M-2)
- Description: `logis_firth` returns class `logis_fe`. `variance`, `Loglkd`, `AIC`, and `BIC` are the unpenalized maximum-likelihood quantities evaluated at the Firth estimates; the penalized log-likelihood computed by C++ is discarded. All `logis_fe` methods (tests, intervals, standardization) therefore apply to Firth fits unchanged.
- Minimal reproducible example: on `ExampleDataBinary`, `fit$Loglkd` is -2695.666 (unpenalized) while the penalized value returned by C++ is -2576.678 (V12.2).
- Affected outputs: class; `variance`; `Loglkd`, `AIC`, `BIC`; every downstream method.
- Statistical impact: Wald-type inference on Firth estimates uses the unpenalized information. Whether that is intended is a methodology question.
- Options: (1) preserve: Firth objects inherit the logistic FE methods and report unpenalized quantities, plus the penalized log-likelihood as an additional field; (2) report penalized quantities or penalized-information variances (Class B).
- Recommendation: (1) in the rewrite (`c("pprof_logistic_firth", "pprof_logistic_fe", "pprof_model")`), with the penalized log-likelihood and convergence diagnostics added. Ask question M-2.
- Decision owner: methodology owner.
- Status: verified (V12.2); signed off by the project lead with the Phase 4 gate (2026-10-04): option (1), preserve, as recommended, which answers M-2. Reproduced by `fit_logistic_firth()` (Phase 4, step 2): class `c("pprof_logistic_firth", "pprof_logistic_fe", "pprof_model")`, unpenalized variances, log-likelihood, AIC, and BIC, the logistic FE methods and capabilities, and the penalized log-likelihood as the additional field `penalized_loglik`, as recommended. The `logis_firth()` wrapper builds the reference's `logis_fe` object from it (step 3).
- Regression test: `tests/testthat/test-model-logistic-firth.R` (the four `logis_firth` fit fixtures; the unpenalized and penalized log-likelihoods of V12.2; the inherited methods); the fit fixtures and the method fixtures on Firth fits run through the wrappers from step 3 (`tests/testthat/test-reference-fits.R` and the method files).

### D-13: CRE provider means use rows that complete-case filtering later drops

- Component: `linear_cre` (`R/linear_cre.R:98-116`), `logis_cre` (`R/logis_cre.R:94-114`).
- Class (proposed): B (methodology question M-3)
- Description: For each covariate in `wb.char`, `*_bar` is the provider mean over all rows of the input data with `na.rm = TRUE`, computed before rows with missing response or other covariates are removed. The fitted model therefore uses provider means that include observations it does not use.
- Minimal reproducible example: on `ExampleDataLinear`, set `Y` to NA for five rows of provider 1; `z1_bar` for provider 1 is -0.1903 (mean over all its rows) rather than -0.2127 (mean over the rows used in the fit) (V15.10).
- Affected outputs: CRE design matrix, all CRE estimates and downstream results, whenever the data have missing values.
- Statistical impact: a real difference in estimates for incomplete data; none for complete data.
- Options: (1) preserve the order (decompose, then filter); (2) filter first, then decompose (Class B).
- Recommendation: preserve (1) explicitly in the data layer (`data_decompose_within_between()` runs before complete-case filtering, as an ordered, documented step), pending question M-3.
- Decision owner: methodology owner.
- Status: verified (V15.10); signed off by the project lead with the Phase 4 gate (2026-10-04): option (1), preserve the order (decompose, then filter), as recommended, which answers M-3.
- Regression test: the data layer reproduces it (`tests/testthat/test-data-prepare.R`, and the fixture `linear_cre-missing` in `test-data-reference.R`); `fit_linear_cre()` reproduces the reference's fit of `linear_cre-missing` (`tests/testthat/test-model-mixed-reference.R`, Phase 4), and so does the `linear_cre()` wrapper (`tests/testthat/test-reference-fits.R`, from Phase 4, step 3).

### D-14: Inconsistent validation of `null`

- Component: `test.logis_fe` (`is.numeric(null)`, `R/test.logis_fe.R:81-83`) versus `SM_output.logis_fe` (`class(null) == "numeric"`, `R/SM_output.logis_fe.R:84-86`), `plot.logis_fe` (`:72-74`), and `confint.logis_fe` through `SM_output`.
- Class (proposed): A
- Description: An integer `null` (for example `0L`) works in `test()` but fails with "Argument 'null' NOT as required!" in `SM_output()`, `confint()`, and `plot()`.
- Minimal reproducible example: `test(fit, null = 0L)` works; `SM_output(fit, null = 0L)` errors (V13.9).
- Affected outputs: error versus result.
- Statistical impact: none.
- Options: accept any finite numeric scalar everywhere.
- Recommendation: validate once in the inference layer; numeric (double or integer) scalars are accepted, and the value is used as a double, so results are identical to passing the double.
- Decision owner: project lead.
- Status: verified (V13.9); the recommendation was approved with the Phase 3 plan (2026-10-02). Fixed in the profiling functions (Phase 3, step 3): `null` is checked once, and a numeric scalar, double or integer, is used as a double. The wrappers apply it from the switch (Phase 3, step 5). Also verified for linear fixed effects (2026-10-04, Phase 5 planning, `dev/design/phase5-facts/01_reference_methods.R`): `test.linear_fe`, `SM_output.linear_fe`, `confint.linear_fe`, and `plot.linear_fe` all reject `null = 0L` with "Argument 'null' NOT as required!" (`class(null) == "numeric"`); the RE and CRE methods do not validate `null`. Fixed in the linear FE wrappers (Phase 5, step 3), with per-case expectations for the four `*-linear-null-integer` fixture cases (R-1).
- Regression test: `tests/testthat/test-profile-regression.R` (`null = 0L` gives the `SM_output-binary-null0` values, the same tests as `null = 0`, and the funnel of the `plot-binary-null0` fixture, added in Phase 3); `tests/testthat/test-compat-methods-families.R` and the four per-case expectations (linear FE, Phase 5).

### D-15: Flags are factors whose levels depend on the data

- Component: every `test` method (`factor(flag)`).
- Class (proposed): Presentation (brief §3.2)
- Description: `flag` is `factor(flag)`, so its levels are whichever of -1, 0, 1 occur. For `test = "wald"` with `parm`, levels come from all providers before subsetting.
- Minimal reproducible example: `levels(test(fit, test = "wald", parm = c(1, 2))$flag)` is `"-1" "0" "1"` though both flags are 0 (V13.10).
- Affected outputs: type of the `flag` column.
- Statistical impact: none.
- Options: integer flags; or a factor with fixed levels.
- Recommendation: integer flags -1/0/1 in new result tables; compatibility wrappers reproduce the factor.
- Decision owner: project lead.
- Status: verified (V13.10). New result tables have integer flags (Phase 3, step 3); the wrappers reproduce the factor. The same for the linear FE, RE, and CRE families (Phase 5, steps 2 and 3), including the factor without levels that the RE and CRE tests return when every flag is missing, on fits whose provider variance is 0 (`dev/design/phase5-facts/09_singular_re_fits.R`).
- Regression test: `tests/testthat/test-profile-reference.R` compares the integer flags with the labels of the reference's factor; the wrapper fixtures compare the factor exactly; `tests/testthat/test-profile-families.R` (the new API on the method fixtures of every family) and `tests/testthat/test-compat-methods-families.R` (singular fits, Phase 5).

### D-16: Linear FE test distribution set by a hidden attribute

- Component: `linear_fe` (`attr(var_gamma, "description")`, `R/linear_fe.R:202-210`), `test.linear_fe` (`R/test.linear_fe.R` `switch(attributes(...)$description, ...)`).
- Class (proposed): none (behavior preserved; the mechanism becomes explicit)
- Description: `test.linear_fe` uses a normal reference with the "simplified" variance and t with n - m - p degrees of freedom with "full", choosing by an attribute that is lost if the matrix is subset or rebuilt.
- Minimal reproducible example: V14.3.
- Affected outputs: none (mechanism only).
- Statistical impact: none.
- Options: store the variance type in the model specification.
- Recommendation: `spec$provider_variance` drives the choice. See D-32 for the related interval inconsistency.
- Decision owner: project lead.
- Status: verified (V14.3); made explicit in `fit_linear_fe()` (Phase 4, step 2): the setting `provider_variance` is stored in `spec$provider_variance`. The `linear_fe()` wrapper sets the attribute that the old methods read from it (step 3).
- Regression test: linear FE fixtures for both variance types (`tests/testthat/test-model-linear-fe.R` checks that `spec$provider_variance` matches the reference's attribute); `tests/testthat/test-compat-fits.R` (the wrapper's attribute for both settings).

### D-17: `data_check` stops on missing values while fits delete rows

- Component: `data_check` (`R/data_check.R`).
- Class (proposed): C
- Description: `data_check` stops with "x% of all observations are missing!" on any missing value, while every fitting function silently performs listwise deletion. The fitting functions' help recommends `data_check` when "issues arise". It reports only through messages and warnings and returns nothing.
- Minimal reproducible example: V16.1.
- Affected outputs: `data_check`.
- Statistical impact: none.
- Options: document; or make the new `check_data()` report missingness instead of stopping.
- Recommendation: document the behavior in the compatibility wrapper `data_check()` (unchanged); the new `check_data()` returns a report object that includes missingness, with the same thresholds for variation, correlation, and VIF (DEC-010).
- Decision owner: project lead.
- Status: verified (V16.1).
- Regression test: planned.

### D-18: FE formula interface handles only plain column names

- Component: formula path of `logis_fe`, `logis_firth`, `linear_fe` (`R/logis_fe.R:133-141` and copies).
- Class (proposed): A
- Description: The provider term is found with `gsub(".*id\\(([^)]+)\\).*", ...)` and every other term label must be a column name, so `log(w)`, `I(z^2)`, and `z1:z2` fail with "Formula contains variables not in the data or is incorrectly structured." With factors whose levels contain spaces, `model.matrix()` produces names such as `grplevel two`, `data.frame()` rewrites them to `grplevel.two`, and the next lookup fails with "undefined columns selected" (formula and column interfaces).
- Minimal reproducible example: V10.12.
- Affected outputs: errors for valid formulas.
- Statistical impact: none on cases that work.
- Options: parse with `terms()`, `model.frame()`, and `model.matrix()`; keep design-matrix column names as `model.matrix()` produces them.
- Recommendation: fix in the data layer. Inputs that work today produce the same design matrix, column names, and contrasts (checked by fixtures); inputs that failed now work, which is a fix of a Class A crash.
- Decision owner: project lead.
- Status: verified (V10.12); fixed in the data layer in Phase 2 (`data_prepare()` parses formulas with `terms()` and keeps `model.matrix()` names); the fits use it from Phase 3.
- Regression test: `tests/testthat/test-data-prepare.R` (transformed terms, interactions, and factor levels with spaces on the fixture datasets `syn_terms` and `syn_factors`) and `tests/testthat/test-model-logistic-fe.R` (the fits equal the reference's fits of the same models with the terms as columns and the levels renamed, the fixtures `logis_fe-terms-*-columns` and `logis_fe-factors-nospaces-formula`, added in Phase 3).

### D-19: SM intervals misaligned for non-numeric provider IDs

- Component: `confint.logis_fe` (`R/confint.logis_fe.R:320`, `:436-444`, `:537-546`).
- Class (proposed): A
- Description: Interval columns are computed in three groups (finite, no-event, all-event providers) and reordered with `order(as.numeric(colnames(...)))`. For character or factor IDs every value is NA, so the order stays finite, no-event, all-event, while the point estimates they are bound to are in provider order. From the first no-event provider onward, intervals belong to other providers. With `option = "gamma"` rows are labeled correctly but are not in provider order, and a coercion warning is issued.
- Minimal reproducible example:
  ```r
  data(ExampleDataBinary)
  d <- data.frame(Y = ExampleDataBinary$Y, ProvID = sprintf("P%03d", ExampleDataBinary$ProvID), ExampleDataBinary$Z)
  fit <- logis_fe(data = d, Y.char = "Y", Z.char = paste0("z", 1:5), ProvID.char = "ProvID", message = FALSE)
  confint(fit)$CI.indirect_ratio["P040", ]   # P040 has no events: ratio 0, yet the lower limit is 0.446
  ```
  61 of 100 providers carry another provider's interval (V13.16).
- Affected outputs: `confint.logis_fe(option = "SM")` for character and factor IDs whenever no-event or all-event providers exist; row order of `option = "gamma"`.
- Statistical impact: severe and silent (wrong intervals attached to providers).
- Options: key every intermediate result by provider ID.
- Recommendation: fix. For numeric IDs the reference is correct and the rewrite reproduces it exactly.
- Decision owner: project lead.
- Status: verified (V13.16); fixed in `provider_effects()` and `standardize_providers()` (Phase 3, step 3): results are keyed by `provider_id` in provider order, and each provider's measure limits come from its own effect limits. The wrapper applies it from the switch (Phase 3, step 5; per-case expectation in `tests/testthat/helper-reference-overrides.R`).
- Regression test: `tests/testthat/test-profile-regression.R` (the `confint-extreme-chr-*` fixtures with rows matched by ID and the measure limits re-paired, a re-pairing that leaves the numeric-ID case unchanged) and `tests/testthat/test-profile-api.R` (storing IDs as integers, characters, or factors changes no result).

### D-20: SerBIN with `threads > 1` differs at rounding level

- Component: `info_beta_omp` (`src/Fixed_effect.cpp:72-85`) versus the BLAS product (`:387`).
- Class (proposed): none (expected; tolerance)
- Description: With `threads > 1` the beta information block is computed with element-wise dot products; with one thread, with one BLAS product. On the example and an 80,000-row simulation, estimates differed by at most 2e-16 (beta) and 1.4e-15 (gamma) relative, with the same iteration count, and were identical across repeated two-thread runs.
- Minimal reproducible example: V11.2.
- Affected outputs: all logistic FE outputs at rounding level.
- Statistical impact: none.
- Options: none needed.
- Recommendation: the rewrite must agree with `threads = 1` within the Tier 2 tolerance for every thread count and be deterministic for a fixed count.
- Decision owner: project lead.
- Status: verified (V11.2). The new core keeps the element-wise beta block for `threads > 1` (Phase 3), so results match the reference at the same thread count and `threads = 1` within the Tier 2 tolerance.
- Regression test: `tests/testthat/test-model-logistic-fe.R` (two threads against one) and `tests/testthat/test-cpp-logistic-engines.R` (the engine with one and two threads).

### D-21: Hard-coded and inconsistent thread counts

- Component: `confint.logis_re`, `confint.logis_cre` (`computeDirectExp(..., threads = 4)`); `SM_output` for logistic models (default 2), called internally with that default by `confint.logis_fe`, `plot.logis_fe`, and the RE/CRE intervals.
- Class (proposed): A; the default change is DEC-001
- Description: `confint.logis_re(stdz = "direct")` calls `computeDirectExp` with 2 threads (through `SM_output`) and twice with 4, whatever the user asks, which conflicts with the CRAN two-core limit.
- Minimal reproducible example: tracing `computeDirectExp` during `confint(fit_re, stdz = "direct")` shows `threads = 2, 4, 4` (V15.11).
- Affected outputs: none numerically: `computeDirectExp` gives identical results for 1 and 2 threads (V13.14).
- Statistical impact: none.
- Options: one `threads` argument, default 1, passed everywhere.
- Recommendation: DEC-001.
- Decision owner: project lead.
- Status: verified (V15.11, V13.14). Logistic FE: the new API takes `threads` with default 1, the `SM_output.logis_fe()` wrapper keeps its default of 2, and the direct expectations do not depend on the thread count (Phase 3). Logistic RE and CRE (Phase 5, step 3): the `confint()` wrappers compute their intervals with one thread instead of the hard-coded 4, and `SM_output()` keeps its default of 2; no result depends on the count (K-85).
- Regression test: `tests/testthat/test-profile-api.R` (the standard score test and the direct expectations with one and two threads); `tests/testthat/test-compat-methods-families.R` (logistic RE measures and intervals with one and two threads).

### D-22: SerBIN with `threads < 1` uses an uninitialized matrix

- Component: `logis_BIN_fe_prov` (`src/Fixed_effect.cpp:382-388`).
- Class (proposed): A
- Description: `info_beta` is allocated without initialization and filled only if `threads > 1` or `threads == 1`. With `threads = 0` or a negative value neither branch runs, and the Newton step uses whatever memory held. On the example data the fit silently returned beta near 0 (about 1e-16) instead of about 1.
- Minimal reproducible example: `logis_fe(Y = ExampleDataBinary$Y, Z = ExampleDataBinary$Z, ProvID = ExampleDataBinary$ProvID, threads = 0)$coefficient$beta` (V10.7; undefined behavior, so results may vary).
- Affected outputs: everything from such a fit.
- Statistical impact: severe and silent.
- Options: validate `threads` as a positive integer.
- Recommendation: fix with `pprof_error_invalid_input`.
- Decision owner: project lead.
- Status: verified (V10.7); fixed: `threads` must be at least 1 (`pprof_error_invalid_input`) in `fit_logistic_fe()` and the `logis_fe()` wrapper (Phase 3).
- Regression test: `tests/testthat/test-model-logistic-fe.R` and `tests/testthat/test-compat-logis-fe.R`.

### D-23: BAN with an out-of-range `backtrack` runs no iterations

- Component: `logis_fe_prov` (`src/Fixed_effect.cpp:140`, `:248`).
- Class (proposed): A
- Description: `backtrack` is an `int` in BAN; only 0 and 1 select a branch. Any other value (for example `backtrack = 2`) skips the loop and returns the starting values (gamma = logit of the overall mean, beta = 0) without a message.
- Minimal reproducible example: `logis_fe(..., method = "BAN", backtrack = 2)$coefficient$beta` is all zeros (V10.6).
- Affected outputs: everything from such a fit.
- Statistical impact: severe and silent.
- Options: validate `backtrack` as a single logical.
- Recommendation: fix with `pprof_error_invalid_input`.
- Decision owner: project lead.
- Status: verified (V10.6); fixed: `backtrack` must be `TRUE` or `FALSE` in `fit_logistic_fe()`, and the `logis_fe()` wrapper accepts 0 and 1 for BAN and any number for SerBIN, as the reference reads them (Phase 3).
- Regression test: `tests/testthat/test-compat-logis-fe.R` and the per-case expectation of `logis_fe-binary-ban-backtrack2`.

### D-24: Default stopping rule can stop before provider effects converge

- Component: `logis_fe` default `stop = "or"`; criteria in `src/Fixed_effect.cpp:424-461`, `:205-242`.
- Class (proposed): B
- Description: Under `"or"` the fit stops as soon as the smallest of three criteria is below `tol`. The likelihood criteria are relative to |log-likelihood|, which grows with n, so on large data they fall below `tol` while individual provider effects are still moving. In four simulations (n from 8,000 to 1.2 million) beta was always within 4.2e-6 of a tight fit (`stop = "beta"`, `tol = 1e-12`), but gamma was off by up to 2.3e-3 (n = 8,093) and 4.0e-2 (n = 1.2 million, 4 iterations, last beta step 1.2e-3). The covariance of beta differed by up to 0.4% relative.
- Minimal reproducible example: `dev/design/audit/11_logistic_fe_stopping.R` (V11.1).
- Affected outputs: all logistic FE estimates, variances, tests, flags, and measures at default settings.
- Statistical impact: provider effects (the quantities being profiled) can be materially unconverged at default settings on large data.
- Options: (1) preserve the default and reproduce the iteration path exactly (required for equivalence); add diagnostics that report every criterion and warn when the coefficient criterion is far above `tol` at stop; (2) change the default to `"all"` or `"coefficients"` (Class B).
- Recommendation: (1) now; put (2) to the methodology owners (question M-4).
- Decision owner: methodology owner.
- Status: verified (V11.1); awaiting sign-off for any default change. Preserved in Phase 3: `stop_rule = "any"` is the default of `fit_logistic_fe()`, whose object keeps the criteria of every iteration so that an early stop can be seen, and the help explains the rule.
- Regression test: the fixtures at default settings and at `tol = 1e-10` (`logis_fe-binary-serbin-tight`, `-ban-tight`) and the full set's 80,000-row default fit (`logis_fe-medium-default`).

### D-25: `logis_firth` help states the wrong `max.iter` default

- Component: `logis_firth` roxygen (`R/logis_firth.R:19`).
- Class (proposed): C
- Description: The help says `max.iter` defaults to 10,000; the code default is 1,000. The help also does not say that the stopping rule is fixed to the coefficient criterion.
- Minimal reproducible example: `formals(logis_firth)$max.iter` is 1000 (V12.4).
- Affected outputs: documentation.
- Statistical impact: none.
- Options: fix the documentation.
- Recommendation: fix.
- Decision owner: project lead.
- Status: verified (V12.4); fixed in the help of the `logis_firth()` wrapper (Phase 4, step 3): `max.iter` defaults to 1,000, and `tol` is described as the bound on the largest absolute change of a coefficient, the only stopping rule.
- Regression test: not applicable (documentation); a check of the help against `formals()` is planned with the documentation of Phase 8, as for D-02.

### D-26: "Standard" score test is not the textbook standard score test

- Component: `test.logis_fe` help (`R/test.logis_fe.R:17-18`, `:30-33`); `Modified_score` (`src/Fixed_effect.cpp:510-594`).
- Class (proposed): C, with methodology question M-7
- Description: The help says `score_modified = FALSE` performs "a standard score test" as opposed to using unrestricted MLEs. The C++ routine does not refit under the null either: it plugs in the full-model estimates of the other providers' effects and of beta, uses the unclamped null probabilities for the tested provider, and adjusts the variance for estimating the nuisance parameters: V = I_aa - I_ab (I_bb* - I_bg I_gg^-1 I_gb)^-1 I_ba, where I_bb* uses null weights for the tested provider's rows. The difference from the modified test is the variance adjustment, not the estimates. An R reimplementation of that formula matches to 1e-15 (V13.5).
- Minimal reproducible example: V13.5.
- Affected outputs: documentation.
- Statistical impact: none (documentation); whether this is the intended test is a methodology question.
- Options: document what is computed.
- Recommendation: document it as "score test with nuisance-parameter variance adjustment, using unrestricted estimates" and ask question M-7.
- Decision owner: project lead (docs); methodology owner (question).
- Status: verified (V13.5); the documentation is fixed (Phase 3): the help of `test_providers()` and of the `test.logis_fe()` wrapper describes the variance adjustment at the unrestricted estimates; question M-7 stays open.
- Regression test: fixture for `score_modified = FALSE`.

### D-27: Integer provider IDs cannot be selected with `parm`

- Component: `test.logis_fe`, `SM_output.logis_fe`, `confint.logis_fe` (and the same pattern in other methods): `if (is.numeric(parm)) parm <- as.numeric(parm)` followed by `class(parm) == class(data[, ProvID.char])`.
- Class (proposed): A
- Description: When the provider column is integer, `parm` is converted to double, the classes differ, and the call fails with "Argument 'parm' includes invalid elements". Selecting by the same integers works only when IDs are stored as doubles.
- Minimal reproducible example: fit with `ProvID = as.integer(ProvID)`, then `test(fit, parm = 1:3)` errors (V13.11).
- Affected outputs: error versus result.
- Statistical impact: none.
- Options: match providers by their character representation.
- Recommendation: `providers` arguments are matched as character against provider IDs (NAMING.md §4).
- Decision owner: project lead.
- Status: verified (V13.11); fixed in the profiling functions (Phase 3, step 3): `providers` is compared as character with the provider IDs. The wrappers apply it from the switch (Phase 3, step 5). Also verified for the methods of `linear_fe` and `logis_cre` fits with integer IDs (2026-10-04, Phase 5 planning, `dev/design/phase5-facts/06_integer_ids_parm.R`): their `data_include` keeps the IDs as integers, and `test()`, `SM_output()`, and `confint()` with `parm = 1:3` fail the class check; `linear_re` and `linear_cre` are not affected, because `cbind()` turns their IDs into doubles. Fixed in those wrappers (Phase 5, step 3), with per-case expectations for `test-linear-syn-int-parm` and `test-logis-cre-extreme-int-parm` (R-1), the reference's tests of every provider without `parm`, of which the first three rows.
- Regression test: `tests/testthat/test-profile-regression.R` (rows 1 to 3 of `test-extreme-exact` for the integer-ID fit) and `tests/testthat/test-profile-api.R`; `tests/testthat/test-compat-methods-families.R` and the two per-case expectations (linear FE and logistic CRE, Phase 5).

### D-28: Factor provider IDs break exact and score intervals

- Component: `confint.logis_fe` helpers `CL.finite`, `CL.no.events`, `CL.all.events`, and the SM helpers (`prov <- ifelse(length(unique(...)) == 1, unique(...), stop(...))`).
- Class (proposed): A
- Description: `ifelse()` on a factor returns its integer code, and `gamma[as.character(prov), ]` then looks up the provider whose label equals that code. With labels such as "10", "20", ... the lookup fails ("subscript out of bounds"); when labels happen to be integers in a different order it would silently use another provider's estimate. Wald intervals, tests, and `SM_output` are not affected.
- Minimal reproducible example: fit with `ProvID = factor(ProvID * 10)`, then `confint(fit, option = "gamma")` errors (V13.18).
- Affected outputs: `confint.logis_fe` with `test = "exact"` or `"score"`.
- Statistical impact: error today; potential silent misalignment.
- Options: key by provider ID as character.
- Recommendation: fix.
- Decision owner: project lead.
- Status: verified (V13.18); fixed in `provider_effects()` (Phase 3, step 3). The wrapper applies it from the switch (Phase 3, step 5; per-case expectation in `tests/testthat/helper-reference-overrides.R`).
- Regression test: `tests/testthat/test-profile-regression.R` (the `confint-extreme-gamma-exact` values for the factor-ID fit) and `tests/testthat/test-profile-api.R`.

### D-29: Direct SM intervals require a column named `ProvID`

- Component: `confint.logis_fe` (`R/confint.logis_fe.R:528-536`: `unique(data[...,]$ProvID)`).
- Class (proposed): A
- Description: Providers for the direct-standardization intervals are taken from `data$ProvID` rather than `data[, ProvID.char]`. With any other provider column name (for example `id(hospital)` in a formula) the vector is NULL and the call fails ("length of 'dimnames' [2] not equal to array extent"). Partial matching could also pick up a column such as `ProvID_old`.
- Minimal reproducible example: rename the provider column to `hospital`, fit, then `confint(fit, stdz = "direct")` errors (V13.17).
- Affected outputs: `confint.logis_fe(option = "SM", stdz = "direct")`.
- Statistical impact: none on cases that work.
- Options: use the stored provider column.
- Recommendation: fix.
- Decision owner: project lead.
- Status: verified (V13.17); fixed in `standardize_providers()` (Phase 3, step 3). The wrapper applies it from the switch (Phase 3, step 5; per-case expectation in `tests/testthat/helper-reference-overrides.R`).
- Regression test: `tests/testthat/test-profile-regression.R` (the direct tables of `confint-extreme-sm-exact` for a provider column named `hospital`).

### D-30: LR and score covariate tests fail with one or two covariates

- Component: `summary.logis_fe` (`R/summary.logis_fe.R:141-147`, `:172-178`).
- Class (proposed): A
- Description: With one covariate, the null model has no covariates and `reformulate(character(0))` fails ("'termlabels' must be a character vector of length at least one"). With two, the single remaining covariate is a vector inside `cbind()`, so its column is named after the expression rather than the covariate, and the refit fails ("Some of the specified columns are not in the data!"). Three or more covariates work.
- Minimal reproducible example: `summary(logis_fe(..., Z.char = c("z1", "z2")), test = "lr")` (V13.19).
- Affected outputs: `summary.logis_fe(test = "lr")` and `(test = "score")`.
- Statistical impact: none on cases that work.
- Options: build the null data frame by name; for one covariate, the null model is the provider-effects-only model.
- Recommendation: fix for two covariates by building the null data by name (the null model is well defined and the reference algorithm applies unchanged). For one covariate, raise a classed error (`pprof_error_unsupported_inference`) until a provider-effects-only null fit is specified and validated, because no reference value exists for it.
- Decision owner: project lead.
- Status: verified (V13.19); the recommendation was approved with the Phase 3 plan (2026-10-02), and the expected value of `summary-screening-twocov-lr` comes from reference fits (the per-case expectations). Fixed in `test_coefficients()` (Phase 3, step 3): the null model is built from the design by column name, so two covariates work, and a model with one covariate raises `pprof_error_unsupported_inference`. The wrapper applies it from the switch (Phase 3, step 5; per-case expectation in `tests/testthat/helper-reference-overrides.R`).
- Regression test: `tests/testthat/test-inference-coefficients.R` (both statistics of a two-covariate fit against K-101 from the reference's one-covariate fits, `logis_fe-screening-x2`, added in Phase 3, and `logis_fe-screening-onecov`; the classed error with one covariate).

### D-31: Logistic RE/CRE summaries report p-values above 1

- Component: `summary.logis_re` (`R/summary.logis_re.R`), `summary.logis_cre` (`R/summary.logis_cre.R`): `p_value <- 2 * (1 - pnorm(stat))`.
- Class (proposed): B
- Description: The two-sided p-value omits `abs()`, so every negative estimate gets p = 2(1 - pnorm(z)) > 1. On the example data the intercept (z = -16.2) is reported with p-value 2. The linear RE/CRE and FE summaries use `abs()`.
- Minimal reproducible example: `summary(logis_re(Y = ExampleDataBinary$Y, Z = ExampleDataBinary$Z, ProvID = ExampleDataBinary$ProvID))` (V15.6).
- Affected outputs: the `p value` column of both summaries.
- Statistical impact: wrong p-values for every negative coefficient (values above 1, so no false significance, but significant negative effects are hidden).
- Options: (1) reproduce; (2) use `2 * (1 - pnorm(abs(stat)))` as everywhere else (Class B because a number changes).
- Recommendation: reproduce in the compatibility wrapper; strongly recommend sign-off for (2) in the new API (question M-10).
- Decision owner: methodology owner.
- Status: verified (V15.6); awaiting sign-off. Reproduced in the new API, where the covariate rule of logistic RE and CRE models computes 2(1 − Φ(z)) (`coefficient_wald$p_value = "upper_doubled"`, Phase 5, step 2), and in the wrappers (Phase 5, step 3).
- Regression test: fixture for both summaries; `tests/testthat/test-profile-families.R` (the new API's covariate tests on the summary fixtures of every family) and `tests/testthat/test-results.R` (result validators accept p-values above 1).

### D-32: Linear FE intervals and tests use opposite reference distributions

- Component: `confint.linear_fe` (`R/confint.linear_fe.R`: `ifelse(description == "full", qnorm(...), qt(...))`) versus `test.linear_fe` (`switch(description, simplified = pnorm, full = pt)`).
- Class (proposed): B (methodology question M-8)
- Description: Tests use the normal distribution with the simplified variance and t(n - m - p) with the full variance. Intervals do the opposite: t(n - m - p) with the simplified variance and normal with the full variance. A provider can be flagged by the test while its interval covers the null, or the reverse.
- Minimal reproducible example: on `ExampleDataLinear`, the simplified interval multiplier is 1.960268 = qt(0.975, 7796); the full multiplier is 1.959964 = qnorm(0.975) (V14.4).
- Affected outputs: `confint.linear_fe` for both variance options, and the SM intervals derived from them.
- Statistical impact: small at large df; can change conclusions for borderline providers and matters at small df.
- Options: (1) reproduce; (2) align the intervals with the tests (Class B).
- Recommendation: reproduce until question M-8 is answered.
- Decision owner: methodology owner.
- Status: verified (V14.4); awaiting sign-off. Reproduced in the new API through the linear FE specification's `wald` field (tests with t(n − m − p) for the full variance and normal for the simplified one; intervals the reverse; Phase 5, step 2) and in the wrappers (Phase 5, step 3).
- Regression test: fixtures for both variance options; `tests/testthat/test-profile-families.R` and `tests/testthat/test-inference-wald.R` (Phase 5); the differential tests run every linear FE method with both variances.

### D-33: Inconsistent interval attributes

- Component: `confint` methods for RE/CRE models and `confint.logis_cre`.
- Class (proposed): C
- Description: `attr(, "confidence_level")` is `paste(level * 100, "%")` ("95 %") for FE models but `paste(level, "%")` ("0.95 %") for RE/CRE models. `confint.logis_cre` labels its indirect rate interval `model = "RE logis"`.
- Minimal reproducible example: V15.12.
- Affected outputs: attributes used by `caterpillar_plot()`.
- Statistical impact: none.
- Options: fix the labels.
- Recommendation: result objects carry the level as a number in a named field, not as a string attribute; the wrappers reproduce the old attributes.
- Decision owner: project lead.
- Status: verified (V15.12). New result objects carry the level as a number (Phase 3); the logistic FE wrapper reproduces the old attributes (its fixtures pass); the linear FE, RE, and CRE wrappers reproduce them too (Phase 5, step 3), including "0.95 %" and the "RE logis" label of the `logis_cre` indirect rate. The `caterpillar_plot()` wrapper (Phase 6, step 3) reads these attributes, as the reference does, to choose the reference line and the flags; the new `plot_caterpillar()` reads the settings of result objects.
- Regression test: wrapper fixtures; `tests/testthat/test-compat-methods-families.R` (RE and CRE).

### D-34: Provider order depends on the collation locale

- Component: every fit (`order(factor(ProvID))`, `table()`, `split()`, `by()`).
- Class (proposed): B
- Description: Provider order is the order of `factor()` levels. For character IDs that is the session's collation order: with LC_COLLATE = C the IDs `b B a A _c 10 9` are ordered `10 9 A B _c a b`; in an English locale, `_c 10 9 a A b B` (V10.10). Order determines output row order and the order of random draws in the bootstrap test, so the same seed gives different provider-level bootstrap results in different locales.
- Minimal reproducible example: V10.10.
- Affected outputs: row order of every result; bootstrap p-values for a given seed.
- Statistical impact: none on deterministic results (they are keyed by provider); the bootstrap results differ across locales for the same seed.
- Options: (1) reproduce the session-locale order; (2) order character IDs in a locale-independent way (for example `sort(method = "radix")`), which changes bootstrap draws in non-C locales (Class B by brief §3.5).
- Recommendation: (1) for equivalence; propose (2) to the methodology owners. The fixture generator records the collation locale in the manifest.
- Decision owner: methodology owner.
- Status: verified (V10.10); awaiting sign-off for (2). The new API and the wrappers of every family keep the reference's order (Phase 5): the R-1 fixtures add character IDs for the RE families (`linear_re-syn`, `logis_re-extreme-chr`), and the differential tests run datasets whose character IDs ("P1", "P2", ...) sort differently under the C collation than their numbers.
- Regression test: fixtures generated under a recorded locale; a test that runs under both C and a non-C locale.

### D-35: `ExampleDataBinary` size documented wrongly

- Component: `R/Data.R` (and PROJECT_CONTEXT §5.8).
- Class (proposed): C
- Description: The help says 7,994 observations; the data have 7,944.
- Minimal reproducible example: `length(ExampleDataBinary$Y)` is 7944.
- Affected outputs: documentation.
- Statistical impact: none.
- Options: fix the documentation.
- Recommendation: fix.
- Decision owner: project lead.
- Status: verified (V16.7).
- Regression test: documentation test that reads dimensions from the data.

### D-36: Unconditional messages and side effects

- Component: `linear_fe`, `linear_re`, `logis_re` (always call `message()`); package attach; `bar_plot`; `caterpillar_plot` (`R/caterpillar_plot.R:114` and `:155-157`).
- Class (proposed): Presentation (brief §3.2)
- Description: `linear_fe`, `linear_re`, and `logis_re` print their input format with no way to turn it off (the CRE fits print nothing). Attaching pprof prints "Registered S3 method overwritten by 'car'" because `olsrr` loads `car`. `bar_plot()` triggers a ggplot2 deprecation warning for `element_line(size = )`. Under ggplot2 4, `caterpillar_plot(use_flag = TRUE)` warns "Arguments in `...` must be used. Problematic argument: box.linetype", because `guide_legend()` no longer takes `box.linetype` (found in Phase 6 planning; the warning is stored in the fixtures `caterpillar-binary-rate-flags` and `caterpillar-linear`, PHASE6_PLAN.md F3).
- Minimal reproducible example: V14.7, V16.4, V16.2; `caterpillar_plot(confint(fit)$CI.indirect_ratio, use_flag = TRUE)` on a `logis_fe()` fit (`dev/design/phase6-facts/02_reference_plots.R`).
- Affected outputs: console output.
- Statistical impact: none.
- Options: one verbosity helper; drop `olsrr`; use `linewidth`; drop the argument ggplot2 ignores.
- Recommendation: DEC-008 (verbosity) and the dependency plan (ARCHITECTURE §H). For the plots: `linewidth`, and no `box.linetype`, in the wrappers of Phase 6, provided the built plots stay identical (DEC-055).
- Decision owner: project lead.
- Status: verified. The new fits print nothing unless `verbose = TRUE` (Phase 3 for logistic fixed effects, Phase 4 for the others). The compatibility wrappers keep the reference's messages: `linear_fe()`, `linear_re()`, and `logis_re()` always report their input format, and the CRE wrappers print nothing (Phase 4, step 3). The plot warnings: the recommendation was approved with the Phase 6 plan (2026-10-04); the wrappers of Phase 6 (step 3) use `linewidth` in `element_line()` and no longer pass `box.linetype`, and the guard finds every built plot, guide, and theme of `bar_plot()` and `caterpillar_plot()` unchanged. One ggplot2 4 message remains: the horizontal `caterpillar_plot()` keeps the reference's `geom_errorbarh()`, which ggplot2 4.0.0 deprecates softly (a warning only where pprof itself is tested) and whose `height` it translates to `width` with the message "`height` was translated to `width`" when the plot is built; `geom_errorbar(orientation = "y")` would build a different `width` column (the ends of the bars are the same), so the change waits for Phase 8's minimum versions.
- Regression test: the tests that `verbose = FALSE` produces no output in `tests/testthat/test-model-*.R`; `tests/testthat/test-compat-fits.R` (the wrappers' messages); `tests/testthat/test-compat-plots.R` ("caterpillar_plot() and bar_plot() draw without ggplot2 warnings (D-36)").

### D-37: Vignettes contradict the code

- Component: `vignettes/` (excluded from the package build; rendered on the pkgdown site).
- Class (proposed): C
- Description: `Logis-FE.Rmd` says provider effects are clamped to the previous iteration's median ± 10; the code uses the median of the current, freshly updated effects (K-15). It refers to functions `SR_output()` and `test_fe()`, which do not exist (`SM_output()`, `test()`), and says the Wald test raises an "error message" where the code warns. Its description of the score test (refit for a restricted MLE, then replaced by the full-model β) describes the modified test only; nothing explains what `score_modified = FALSE` computes (D-26). `Quick-start.Rmd` calls `logis_fe(data.prep)` and `confint(fit, option = "SR")`, both of which fail with the current API. `pprof.Rmd` says the package has three fitting functions (it has seven) and links to the site of a different package (`ppsrr`). Found in Phase 7 planning (2026-10-04, `dev/design/phase7-facts/03_old_vignettes.R` and `02_pkgdown.R`): every chunk of `Quick-start.Rmd` fails, because it calls `fe_data_prep()`, `SR_output()`, `test_fe()`, and `summary_fe_covar()`, which pprof 1.0.3 does not have either (the code of `pprof.Rmd` runs); `pprof.Rmd` shows `Charts/pprof_flowchart.png`, which does not exist (the folder holds `pprof flowchart (v1).png` and `(v2).png`), so the published site shows a broken image, and both flowcharts list the old names only, the second placing `logis_fe` and `logis_firth` under random effects for binary outcomes; `Logis-FE.Rmd` says that a direct ratio's interval covers DSR_k when the provider-effect interval covers γ0, where by construction it covers the direct ratio at γ0; `Linear-FE.Rmd` gives σ²/n_i as the variance of γ̂_i, which is only the simplified option of `option.gamma.var` (K-42).
- Minimal reproducible example: `confint(fit, option = "SR")` errors "Argument 'option' should be 'gamma' or 'SM'"; compare `vignettes/Logis-FE.Rmd:36` with `src/Fixed_effect.cpp:417`.
- Affected outputs: documentation.
- Statistical impact: none (documentation only).
- Options: correct the vignettes now, or replace them with vignettes for the new API.
- Recommendation: replace them in Phase 7, written for the new API and built and checked as part of the package (brief §9); until then, leave the excluded vignettes unchanged.
- Decision owner: project lead.
- Status: verified by reading the vignettes against the code and the audit results (V10.2, V13.21, BEHAVIOR_SPECS §9); the Phase 7 planning items above verified by running the vignettes' code and reading them against the code (2026-10-04). The Phase 7 plan replaces the vignettes (`dev/design/PHASE7_PLAN.md`, DEC-062), awaiting approval.
- Regression test: vignettes are built during `R CMD check` from Phase 7 on.

### D-38: Collinear covariates give unidentified estimates without a rank-deficiency warning

- Component: `logis_fe` (SerBIN step `src/Fixed_effect.cpp:395-399`, variance `:660`).
- Class (proposed): C (a message is missing; the numbers are reproduced)
- Description: When covariates are exactly collinear (x3 = x1 + x2), the information matrix is singular in exact arithmetic, but `arma::solve(..., likely_sympd)` and `inv_sympd()` succeed numerically. The fit returns arbitrary coefficients for the collinear set with variances near 7e13 and no warning or message about it; the only warning is the routine screening count ("0 out of 20 providers considered small and filtered out!"). A constant covariate or a factor level that never occurs (an all-zero design column) instead makes the variance step fail with "inv_sympd(): matrix is singular or not positive definite" after the fit has iterated.
- Minimal reproducible example: fixture `logis_fe-collinear` (dataset `syn_collinear`): beta = (0.268, 0.038, 0.373), every entry of variance$beta about ±7.04e13; fixtures `logis_fe-constant` and `logis_fe-factors-unused-columns` for the error.
- Affected outputs: all outputs of such fits.
- Statistical impact: the coefficients of the collinear set and every Wald quantity based on them are meaningless; provider effects and fitted values are identified and unaffected in exact arithmetic.
- Options: (1) reproduce the numbers and add a classed warning (`pprof_warning_rank_deficient`) when the design is rank deficient; (2) stop with a classed error (Class B: a result becomes an error); (3) drop aliased columns as `glm()` does (Class B).
- Recommendation: (1). Methodology owners may prefer (3); recorded as part of question M-17.
- Decision owner: project lead for (1); methodology owner for (2) or (3).
- Status: verified (Phase 1 fixtures, 2026-10-02); option (1) implemented (Phase 3): `fit_logistic_fe()` warns with `pprof_warning_rank_deficient` when the provider-centered design is rank deficient and fits as the reference does, and the `logis_fe()` wrapper passes the warning on; options (2) and (3) remain question M-17.
- Regression test: the fixtures above, and `tests/testthat/test-model-logistic-fe.R` (the warning, with estimates as the reference's).

### D-39: `logis_fe` and `logis_firth` accept inputs without checking them

- Component: `logis_fe` (`R/logis_fe.R:125-312`, which validates no setting), `logis_BIN_fe_prov` and `logis_fe_prov` (`src/Fixed_effect.cpp`).
- Class (proposed): A, like D-22 and D-23; approved as Class A with the Phase 3 plan (2026-10-02).
- Description: The reference fits whatever it is given. Running it on `ExampleDataBinary` (2026-10-02) showed:
  - an outcome other than 0 and 1: with the values 0 and 0.5 it returns a quasi-likelihood fit (first coefficient 0.482 instead of 1.093); with 0 and 2 the fit diverges and runs to the iteration limit (10,001 SerBIN iterations, provider effects between 14 and 34), and reports convergence;
  - `max.iter` <= 0: SerBIN with 0 runs one iteration; BAN with 0, and both algorithms with a negative value, return the starting values (every coefficient 0, every provider effect -0.457), reported as converged;
  - `tol` <= 0: the stopping rule is never met, so the fit runs `max.iter + 1` (SerBIN) or `max.iter` (BAN) iterations and reports convergence;
  - `bound` = 0 sets every provider effect to their median (-0.874 for all 100 providers); a negative `bound` fails inside Armadillo ("clamp(): min_val must be less than max_val").
  These inputs work as one would expect: a logical outcome (identical to 0 and 1), any `cutoff` (inclusion is n_i >= `cutoff`, so values <= 1 include every provider and 9.5 acts as 10), and a non-integer `max.iter` (Rcpp truncates it).
  `logis_firth` (`R/logis_firth.R:94-190`, `src/Firth.cpp`), whose R code copies this processing, does the same (2026-10-03, `ExampleDataBinary`, each setting in its own process): `max.iter` <= 0 returns the starting values and reports convergence after 0 iterations; `tol` <= 0 runs all 1,000 iterations and reports convergence; `bound` = 0 sets every provider effect to their median (-0.857); a negative `bound` terminates R (exit status 127), because the Armadillo error is raised inside the OpenMP region, as in D-42.
- Minimal reproducible example:
  ```r
  data(ExampleDataBinary)
  d <- data.frame(Y = ExampleDataBinary$Y, ProvID = ExampleDataBinary$ProvID, ExampleDataBinary$Z)
  logis_fe(data = d, Y.char = "Y", Z.char = paste0("z", 1:5), ProvID.char = "ProvID", method = "BAN",
           max.iter = 0, message = FALSE)$coefficient$beta   # all 0
  ```
- Affected outputs: everything from such fits.
- Statistical impact: severe and silent where a result is returned.
- Options: (1) reject the values with `pprof_error_invalid_input`; (2) reproduce them in the compatibility wrapper (Class B).
- Recommendation: (1). `fit_logistic_fe()` requires a binary outcome and positive `max_iter`, `tol`, and `effect_bound` (NAMING.md §4), so the wrapper rejects these values too. The wrapper keeps the cases that work: it passes `min_provider_size = max(1, ceiling(cutoff))`, which includes the same providers, and truncates `max.iter` as Rcpp does. Two inputs that already failed fail earlier and with a classed condition: an outcome with a single value (the reference fails after fitting, in pROC: "'response' must have two levels") gives `pprof_error_data`, and an infinite covariate (the reference's solve fails: "solve(): solution not found") gives `pprof_error_invalid_input`.
- Decision owner: project lead.
- Status: decided (fix) with the Phase 3 plan; fixed in `fit_logistic_fe()` (Phase 3, step 2); the `logis_fe()` wrapper applies it from the switch (Phase 3, step 5). The same fix applies to Firth: `fit_logistic_firth()` rejects these values (Phase 4, step 2), and so does the `logis_firth()` wrapper from the switch (Phase 4, step 3), including the negative `bound` that terminated R.
- Regression test: `tests/testthat/test-model-logistic-fe.R` ("fit_logistic_fe() rejects invalid settings", "the outcome must be binary with both values"), `tests/testthat/test-model-logistic-firth.R` ("fit_logistic_firth() rejects invalid settings and data (D-39)"), and the wrappers in `tests/testthat/test-compat-logis-fe.R` and `tests/testthat/test-compat-fits.R`.

### D-40: The AUC computed without pROC differs from pROC's in the last bit for some fits

- Component: `fit_logistic_fe()` (`logistic_fe_auc()` in `R/model-logistic-fe.R`), which replaces `pROC::auc()` (`R/logis_fe.R:302-303`) under DEC-009.
- Class (proposed): none (tolerance), like D-20.
- Description: The rewrite computes the AUC of the fitted probabilities by the Mann-Whitney formula with ties counted one half, choosing the direction as `pROC::auc()` does by default (K-22). pROC integrates the ROC curve with the trapezoidal rule. The two agree in exact arithmetic. On the 59 `logis_fe` fit fixtures that return a value, the rewrite's AUC equals pROC's bitwise in 57 and differs by one unit in the last place in two (`logis_fe-binary-serbin-maxiter3`, 1.2e-16 relative; `logis_fe-medium-tight`, 1.4e-16), while pROC applied to the rewrite's fitted probabilities reproduces every fixture's AUC exactly.
- Minimal reproducible example: the AUC of `fit_logistic_fe()` for the case `logis_fe-binary-serbin-maxiter3` against the fixture's `AUC`.
- Affected outputs: `AUC` of logistic fixed-effect fits (and of Firth fits from Phase 4).
- Statistical impact: none.
- Options: (1) accept rounding-level differences and compare the AUC at the closed-form tier; (2) reimplement pROC's ROC-curve integration in base R to match it bitwise; (3) keep pROC.
- Recommendation: (1). The Mann-Whitney formula is the definition the conventions register states (K-22) and the easier one to audit. DEC-009 asked for an equality test proving identical results; the tests show equality to the last bit (tie-heavy data and both directions in `test-model-logistic-fe.R`, all 59 fits in `test-model-logistic-fe-reference.R`).
- Decision owner: project lead.
- Status: verified (2026-10-02); option (1) decided by the project lead with the Phase 3 gate (2026-10-03): rounding-level differences are accepted, and the AUC is compared at the closed-form tier (atol 1e-12, rtol 1e-10), as `test-model-logistic-fe-reference.R` does; the fits of the reference suite are compared at the iterative tier, which has the same tolerances. The differential test (2026-10-03, `validation/differential-report.md`) found the same pattern on new data: in 9 of 90 fits the AUC differs from the reference's in the last bit, and it is the only value of those fits that is not bitwise identical. In the reference suite at the Phase 3 gate (2026-10-03), the AUC is the only value that differs in 4 of the 68 `logis_fe()` fit cases that return a value, by one unit in the last place: the two above and `logis_fe-factors-spaces-formula` and `logis_fe-factors-nospaces-formula` (added at step 4), which share one dataset; the report's largest difference over all cases, 1.11e-16, is this. Firth fits compute their AUC the same way: the four `logis_firth` fixtures match bitwise, and in the Phase 4 differential test (2026-10-03) 1 of 30 `logis_firth()` fits on new data differs from the reference only in the last bit of the AUC.
- Regression test: the two tests above.

### D-41: `logis_fe` and `logis_firth` fail with factor provider IDs when screening excludes a provider

- Component: `logis_fe` (`R/logis_fe.R:214`, `n.prov <- sapply(split(data[, Y.char], data[, ProvID.char]), length)`), and the same code in `logis_firth` (`R/logis_firth.R`).
- Class (proposed): A
- Description: After screening, a factor provider column keeps the levels of the excluded providers, so `split()` returns empty groups and `n.prov` contains zeros. The C++ engines then address an empty block of rows and fail with "Col::subvec(): indices out of bounds or incorrectly used". With numeric or character IDs `split()` sees only the remaining values and the fit works; the fixtures with factor IDs (`logis_fe-extreme-fac`) exclude no provider. Found by the live comparison of `fit_logistic_fe()` with `logis_fe()` (Phase 3, step 2).
- Minimal reproducible example:
  ```r
  data(ExampleDataBinary)
  d <- data.frame(Y = ExampleDataBinary$Y, ProvID = factor(sprintf("P%03d", ExampleDataBinary$ProvID)),
                  ExampleDataBinary$Z)
  logis_fe(data = d, Y.char = "Y", Z.char = paste0("z", 1:5), ProvID.char = "ProvID", cutoff = 60, message = FALSE)
  #> Error: Col::subvec(): indices out of bounds or incorrectly used
  ```
  With `ProvID` as character strings the same call returns a fit of the 97 remaining providers.
- Affected outputs: `logis_fe()` and `logis_firth()` with factor IDs whenever a provider is excluded.
- Statistical impact: none on cases that work.
- Options: index providers through the data layer, which drops unused levels.
- Recommendation: fix. `fit_logistic_fe()` returns the same fit as with the labels as character strings.
- Decision owner: project lead.
- Status: verified (2026-10-02); fixed in `fit_logistic_fe()` (Phase 3), and so in the `logis_fe()` wrapper, and in `fit_logistic_firth()` (Phase 4, step 2), and so in the `logis_firth()` wrapper (Phase 4, step 3).
- Regression test: `tests/testthat/test-model-logistic-fe.R` ("factor provider IDs work when screening excludes providers"), `tests/testthat/test-model-logistic-firth.R` (the same check for Firth), and the wrappers in `tests/testthat/test-compat-logis-fe.R` and `tests/testthat/test-compat-fits.R`.

### D-42: `logis_firth` terminates R when the information is singular

- Component: `logis_firth_prov` (`src/Firth.cpp:194` and `:337`, `inv_sympd()`; `:41`, `Rcpp::stop()` in `logdet_info()`), called inside the OpenMP parallel region `:133-399`.
- Class (proposed): A
- Description: The routine inverts the Schur complement of the information with the throwing form of `inv_sympd()` inside an `omp single` block of its parallel region, with any number of threads. When the matrix is singular or not positive definite, the exception cannot leave the region, and the C++ runtime terminates the process: the R session ends, losing unsaved work. The `Rcpp::stop()` that `logdet_info()` calls when the Cholesky factorization fails even with a ridge sits in the same region; in practice `inv_sympd()` fails first on the same matrix. D-05 noted that the region contains routines that can throw; this entry records the confirmed consequence, which does not depend on the thread count.
- Minimal reproducible example (run it with `Rscript` in a separate process):
  ```r
  data(ExampleDataBinary)
  d <- data.frame(Y = ExampleDataBinary$Y, ProvID = ExampleDataBinary$ProvID, ExampleDataBinary$Z)
  d$zero <- 0
  logis_firth(data = d, Y.char = "Y", Z.char = c("z1", "zero"), ProvID.char = "ProvID", threads = 1,
              message = FALSE)
  #> terminate called after throwing an instance of 'std::runtime_error'
  #>   what():  inv_sympd(): matrix is singular or not positive definite
  ```
  `Rscript` exits with status 127 (2026-10-03, reference library `dev/reference/lib`).
- Affected outputs: the R session, whenever the Schur complement cannot be inverted at the starting values or after an iteration. Verified for a covariate that is constant at 0; other inputs that make the matrix singular, or non-finite, reach the same call (not run).
- Statistical impact: none on results; the session is lost.
- Options: report the failure as an R error.
- Recommendation: fix. The new engine inverts outside its parallel regions and throws there; the adapter turns the exception into an R error, and the model layer reclasses it as `pprof_error_convergence`, as for logistic fixed effects.
- Decision owner: project lead.
- Status: verified (2026-10-03); fixed in the C++ engine (Phase 4, step 1): `cpp_logistic_firth()` raises an R error, which `fit_logistic_firth()` reclasses as `pprof_error_convergence` (step 2), and the `logis_firth()` wrapper raises that error (step 3).
- Regression test: `tests/testthat/test-cpp-firth.R` ("a singular information matrix ends the fit with an error, where the reference terminated R (D-42)"), `tests/testthat/test-model-logistic-firth.R` (the same for `fit_logistic_firth()`, with the class `pprof_error_convergence`), and `tests/testthat/test-compat-fits.R` (the wrapper).

### D-43: The linear FE funnel plot draws limits with one variance and flags with another

- Component: `plot.linear_fe` (`R/plot.linear_fe.R:57-68`): the limits are `target -/+ qnorm(1 - alpha / 2) * sqrt(1 / n_i) * sigma` whatever `option.gamma.var` the fit used, and the flags come from `test.linear_fe(level = 1 - alpha[1])`, which uses the full variance and t(n - m - p) for `option.gamma.var = "full"` (K-68, K-111).
- Class (proposed): B (methodology question M-18)
- Description: With the simplified variance the limits and the flags use the same statistic, so a provider is flagged exactly when its point lies outside the limits at the first alpha. With the full variance the flags use the larger variance and the t distribution, while the limits do not change, so points outside the limits can be unflagged.
- Minimal reproducible example (`dev/design/phase5-facts/05_linear_funnel_flags.R`, reference library, 2026-10-04): 40 simulated providers of 3 to 8 observations whose covariate means differ between providers; with `option.gamma.var = "full"`, 21 points lie outside the 95% limits and 13 providers are flagged (8 disagree). With `"simplified"`, and on `ExampleDataLinear` with either option, points and flags agree.
- Affected outputs: `plot.linear_fe` for fits with `option.gamma.var = "full"`: the flags of points near the limits.
- Statistical impact: the plot can show a provider outside the control limits as "expected", or the reverse; the flags agree with `test()`, the limits with the simplified variance.
- Options: (1) reproduce; (2) draw the limits from the variance and distribution of the test (Class B: changes the limits of full-variance plots).
- Recommendation: reproduce (1) in the wrapper and in `funnel_limits()` for linear FE until the methodology owners answer M-18.
- Decision owner: methodology owner.
- Status: verified (2026-10-04, Phase 5 planning); awaiting sign-off. Reproduced in `funnel_limits()` for linear FE (limits from σ/sqrt(n_i) and normal quantiles, flags from the Wald test of the fit's provider variance; Phase 5, step 2) and in `plot.linear_fe()` (Phase 5, step 3); `plot_funnel()` draws those limits and flags, and its help states the discrepancy (Phase 6, step 2).
- Regression test: the R-1 fixture cases `plot-linear-full` (the full-variance fit of the linear example) and `plot-linear-funnel-full` (that of `syn_linear_funnel`, where 8 of 40 points disagree with their flags); `tests/testthat/test-profile-families.R` ("the linear funnel has precision n_i, half-width z sigma / sqrt(n_i), and Wald flags").

### D-44: The RE and CRE summaries select the intercept only as `"(intercept)"`

- Component: `summary.linear_re`, `summary.logis_re`, `summary.linear_cre`, `summary.logis_cre` (`R/summary.linear_re.R:23` and the same line in the others): `covar_char <- c("(intercept)", ...)`, matched against character `parm`.
- Class (proposed): C
- Description: The summaries name the intercept's row `"(Intercept)"`, as lme4 does, but select rows by a list that spells it `"(intercept)"`. `parm = "(Intercept)"` selects nothing and returns a data frame with no rows; `parm = "(intercept)"` selects the intercept. The help says only that `parm` "specifies a subset of covariates".
- Minimal reproducible example: `nrow(summary(linear_re(data = d, Y.char = "Y", Z.char = z, ProvID.char = "ProvID"), parm = "(Intercept)"))` is 0, and with `parm = "(intercept)"` it is 1 (`dev/design/phase5-facts/01_reference_methods.R`, 2026-10-04).
- Affected outputs: documentation; the rows selected by `parm`.
- Statistical impact: none.
- Options: document the spelling; or also accept `"(Intercept)"` (a result where the reference returns no rows).
- Recommendation: the wrappers keep the reference's selection and their help states that the intercept is selected as `"(intercept)"`; the new API's `test_coefficients()` and `confint()` use the coefficient names, so `"(Intercept)"`.
- Decision owner: project lead.
- Status: verified (2026-10-04, Phase 5 planning); the recommendation was approved with the Phase 5 plan (2026-10-04): the wrappers keep the selection and their help states it. Fixed in the help (Phase 5, step 3); the help example of `summary.linear_re()`, which fitted `linear_fe()`, now fits `linear_re()`.
- Regression test: the R-1 fixture cases `summary-linear-re-parm-level90` and `summary-linear-re-parm-intercept-capital`; `tests/testthat/test-compat-methods-families.R`.

### D-45: A `null` with more than one value is applied by position

- Component: `test.linear_re`, `test.logis_re`, `test.linear_cre`, `test.logis_cre` (`Z_score <- (fit$coefficient$RE - null)/PostSE`); every `summary()` (`stat <- (beta - null) / se.beta`, and the same for the RE and CRE fixed effects).
- Class (proposed): A
- Description: The help documents `null` as "a number". Given several values, the RE and CRE tests subtract them from the provider effects by position, recycling them over the providers in provider order, so each provider's null depends on its position; the summaries subtract them from the coefficients by position. The logistic and linear FE tests use the first value only (`null[1]`).
- Minimal reproducible example (reference library, 2026-10-04; `dev/design/phase5-facts/08_reference_edge_inputs.R`): `test(linear_re(data = d, Y.char = "Y", Z.char = z, ProvID.char = "ProvID"), null = c(0, 0.1))` and `summary(<that fit>, null = c(0, 0.1, 0, 0, 0, 0))` return values.
- Affected outputs: the statistics, p-values, and flags of those calls.
- Statistical impact: a provider's null depends on its position in the provider order, so the results are misaligned with provider IDs for any recycled vector.
- Options: (1) reproduce the recycling; (2) accept one number and raise `pprof_error_invalid_input` otherwise.
- Recommendation: (2). The new API takes one number (`test_providers()`, `test_coefficients()`); the wrappers of the FE tests keep using the first value, as the reference does.
- Decision owner: project lead.
- Status: verified on the reference (2026-10-04, Phase 5 step 3); fixed in the wrappers: `summary.logis_fe()` has rejected several values since Phase 3 (not recorded then), and the RE and CRE tests and the linear FE, RE, and CRE summaries from Phase 5.
- Regression test: `tests/testthat/test-compat-methods-families.R` ("the RE and CRE tests take a single number as the null (D-45)").

### D-46: RE and CRE summaries fail without the lme4 fit

- Component: `summary.linear_re`, `summary.logis_re`, `summary.linear_cre`, `summary.logis_cre` (`CI <- confint(model, parm = "beta_", method = "Wald", level = level)` with `model <- attributes(object)$model`).
- Class (proposed): A
- Description: The summaries take their intervals from lme4's `confint()` of the fit kept in `attr(, "model")`; when the attribute is missing (for example after the object is rebuilt or edited), they fail with "no applicable method for 'vcov' applied to an object of class \"NULL\"", although the intervals need only the fixed effects and their covariance, which the object keeps. The tests and intervals of the RE and CRE methods other than linear RE need the fit for the conditional standard deviations (K-70), and fail without it in the reference and in the wrappers alike.
- Minimal reproducible example (reference library, 2026-10-04; `dev/design/phase5-facts/08_reference_edge_inputs.R`): `fit <- linear_re(...); attr(fit, "model") <- NULL; summary(fit)` fails; `test(fit)`, `confint(fit)`, and `SM_output(fit)` work.
- Affected outputs: error versus result.
- Statistical impact: none (the wrapper's intervals equal lme4's bitwise, PHASE5_PLAN.md F3).
- Options: (1) fail as the reference does; (2) compute the intervals from the stored covariance.
- Recommendation: (2), which the new API does for every RE and CRE model.
- Decision owner: project lead.
- Status: verified (2026-10-04, Phase 5 step 3); fixed in the wrappers.
- Regression test: `tests/testthat/test-compat-methods-families.R` ("only the methods that use the conditional standard deviations need the lme4 fit (D-46)").

### D-47: The colours of `caterpillar_plot()` and `bar_plot()` depend on the flags present

- Component: `caterpillar_plot(use_flag = TRUE)` (`R/caterpillar_plot.R:114`, `:155`: `scale_color_manual(values = flag_color, ...)`); `bar_plot()` (`R/bar_plot.R:89`: `scale_fill_manual(values = bar_colors)`).
- Class (proposed): Presentation (brief §3.2)
- Description: Both functions pass their colours to a manual scale without names, so ggplot2 gives them, in order, to the categories present in the plot. In `caterpillar_plot()` the flags are the strings `"Higher"`, `"Lower"`, and `"Normal"`: with all three, Higher is orange, Lower blue, and Normal green; with Higher and Normal (one-sided `greater`), Higher is orange and Normal blue; with Lower and Normal (`less`), Lower is orange; with Normal only, Normal is orange. In `bar_plot()`, with every category present, higher is `#66c2a5`, as expected `#fc8d62`, and lower `#8da0cb`; when every provider is as expected, as expected is `#66c2a5`. The funnel plots, by contrast, map each flag to a fixed colour (lower orange, as expected blue, higher green). The help says which colours are used, not which flag gets which.
- Minimal reproducible example (reference library, 2026-10-04; `dev/design/phase6-facts/02_reference_plots.R` and `05_bar_plot_without_dplyr.R`): `caterpillar_plot(confint(fit, option = "SM", alternative = "less")$CI.indirect_ratio, use_flag = TRUE)` on a `logis_fe()` fit of the binary example draws the providers flagged lower in orange, and with `alternative = "greater"` those flagged higher; every interval of `caterpillar_plot(confint(logis_cre(...))$CI.indirect_ratio, use_flag = TRUE)` on the binary example is orange.
- Affected outputs: the colours of `caterpillar_plot(use_flag = TRUE)` and `bar_plot()`.
- Statistical impact: none; a reader who compares plots, or reads orange as in the funnel plot, can misread the flags.
- Options: (1) reproduce in the wrappers; (2) map colours to flags by name.
- Recommendation: (1) in `caterpillar_plot()` and `bar_plot()`, which reproduce the old presentation (DEC-013, DEC-055); (2) in the new plot functions, which share one fixed flag scale (DEC-058).
- Decision owner: project lead.
- Status: verified (2026-10-04, Phase 6 planning); the recommendation was approved with the Phase 6 plan (2026-10-04). Reproduced in the wrappers (Phase 6, step 3: the guard finds every built colour of `caterpillar_plot()` and `bar_plot()` unchanged) and stated in their help; the new plot functions map each flag to one colour (Phase 6, step 2, DEC-058).
- Regression test: `tests/testthat/test-compat-plots.R` ("the wrappers keep pprof 1.0.3's colours, which depend on the flags present (D-47)"); `tests/testthat/test-present-plots.R` ("each flag has the same colour and shape in every plot, whatever flags occur (DEC-058, D-47)"); the guard `dev/design/phase6-facts/08_plot_guard.R` (the built colours of every old plot).

### D-48: The help of `caterpillar_plot()` and `bar_plot()` contradicts their behavior

- Component: the help of `bar_plot()` (`R/bar_plot.R:8` and `:14`) and of `caterpillar_plot()` (`R/caterpillar_plot.R:35-36`).
- Class (proposed): C
- Description: `bar_plot()` documents `bar_width` as "width of the bars in the bar chart", but draws bars of width 0.7 whatever it is (`R/bar_plot.R:79`); its details call the input `test_df`, but the argument is `flag_df`. The details of `caterpillar_plot()` say that "where one side of the confidence interval is infinite, that side only extends to the standardized measure", for example for logistic FE providers with all events or none; but the code shortens the bars of one-sided intervals (by the table's `type`) whatever their limits, and the measure intervals of logistic FE providers with all events or none are finite (K-91).
- Minimal reproducible example (reference library, 2026-10-04): `bar_plot(test(fit), bar_width = 0.2)` builds the same data as `bar_plot(test(fit))` (`dev/design/phase6-facts/05_bar_plot_without_dplyr.R`); the two-sided measure tables of `confint(fit)` for a `logis_fe()` fit of the binary example, which has providers without events, have no infinite limit (`02_reference_plots.R`).
- Affected outputs: documentation.
- Statistical impact: none.
- Options: fix the help; or make `bar_width` set the width (a different plot for users who pass it).
- Recommendation: fix the help of the wrappers (Phase 6, step 3).
- Decision owner: project lead.
- Status: verified (2026-10-04, Phase 6 planning); the recommendation was approved with the Phase 6 plan (2026-10-04). Fixed in the help of the wrappers (Phase 6, step 3).
- Regression test: `tests/testthat/test-compat-plots.R` ("bar_plot()'s bar_width has no effect, as its help says (D-48)").

### D-49: `bar_plot()`'s plot data are a data frame instead of a grouped tibble

- Component: `bar_plot()` (`R/compat-plots.R`, `compat_bar_table()`; in pprof 1.0.3, `R/bar_plot.R:71-75`, the dplyr summary).
- Class (proposed): Presentation (brief §3.2: container types)
- Description: pprof 1.0.3 gives ggplot2 the result of `group_by() |> summarise() |> group_by() |> mutate()`, a grouped tibble, to which ggplot2 4 adds the column `.group`, the index of the size group. The wrapper of Phase 6 builds the same table in base R (DEC-055, DEC-057): a data frame with the columns `size`, `category`, `count`, `value`, and `.group`, the same rows, types, levels, and values. So `class(bar_plot(x)$data)` is `"data.frame"` instead of `c("grouped_df", "tbl_df", "tbl", "data.frame")`; `as.data.frame()` of either is identical, and so are the built layers, scales, guides, and theme.
- Minimal reproducible example: `class(bar_plot(test(fit))$data)` on a `logis_fe()` fit of the binary example (`dev/design/phase6-facts/05_bar_plot_without_dplyr.R`; the guard `08_plot_guard.R` lists the 79 records where this is the only difference).
- Affected outputs: the class of the plot object's `data`.
- Statistical impact: none.
- Options: (1) a data frame; (2) keep dplyr to build a grouped tibble.
- Recommendation: (1), which DEC-057 implies; stated in NEWS.
- Decision owner: project lead.
- Status: verified (2026-10-04, Phase 6, step 3); documented in NEWS.
- Regression test: `tests/testthat/test-compat-plots.R` ("bar_plot()'s data are a data frame with the group index ggplot2 adds to dplyr's grouped data"); the fixtures compare `as.data.frame()` of the plot data.
