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
| D-05 | `logis_firth(threads > 1)` | A | verified | Data race on `d_beta` stops the iteration after 1 to 5 steps; beta off by up to 0.57 |
| D-06 | `test.logis_fe(test = "robust_wald")` | A | verified | Passes validation, returns NULL |
| D-07 | `plot.logis_fe(test = "exact")` | A | verified | Always errors (`.data` pronoun outside a data mask) |
| D-08 | several methods | A | verified | Rely on partial matching of `$` (`fit$obs`, `object$data_includ`) |
| D-09 | `print` methods | Presentation | verified | `print.logis_cre` unregistered; all RE/CRE prints dump the whole object |
| D-10 | `summary.logis_fe(test = "lr"/"score")` | B | verified | Null refits ignore the original fit's settings; the likelihood clamp hard-codes 10; a smaller `cutoff` makes the refit fail |
| D-11 | `linear_re`, `logis_re` vector interface | A | verified | `cbind()` coerces mixed inputs to character; no final `else` |
| D-12 | `logis_firth` result | B (question M-2) | verified | Class `logis_fe` with unpenalized variance, log-likelihood, AIC, BIC |
| D-13 | `linear_cre`, `logis_cre` | B (question M-3) | verified | Provider means computed before complete-case filtering |
| D-14 | `null` validation | A | verified | Integer `null` accepted by `test()`, rejected by `SM_output()`, `confint()`, `plot()` |
| D-15 | `test` methods | Presentation | verified | Flags are factors whose levels depend on the data |
| D-16 | `test.linear_fe` | none (made explicit) | verified | Reference distribution chosen by a hidden attribute |
| D-17 | `data_check` | C | verified | Stops on any missing value; fits delete incomplete rows |
| D-18 | FE formula interface | A | verified; fixed in the data layer (Phase 2) | Transformed and interaction terms fail; factor levels with spaces break the design matrix |
| D-19 | `confint.logis_fe(option = "SM")` | A | verified | Non-numeric IDs misalign intervals with providers (61 of 100 in the example) |
| D-20 | `logis_fe(threads > 1)` | none (tolerance) | verified | Element-wise OpenMP information block differs from BLAS at 1e-15 relative |
| D-21 | thread counts | A (DEC-001) | verified | `threads = 4` hard-coded in logistic RE/CRE intervals; 2 by default in `SM_output()` |
| D-22 | `logis_fe(threads < 1)` | A | verified | Uninitialized information matrix; silently returns beta near 0 |
| D-23 | `logis_fe(method = "BAN", backtrack = 2)` | A | verified | Runs zero iterations and returns the starting values |
| D-24 | `logis_fe` default stopping rule | B | verified | `stop = "or"` can stop before provider effects converge (0.04 logit error at n = 1.2M) |
| D-25 | `logis_firth` help | C | verified | Help says `max.iter` defaults to 10,000; code default is 1,000 |
| D-26 | `test.logis_fe(score_modified = FALSE)` help | C (question M-7) | verified | Called a "standard score test" but does not refit under the null |
| D-27 | `parm` with integer provider IDs | A | verified | `parm = 1:3` fails the class check for an integer ID column |
| D-28 | factor provider IDs in `confint.logis_fe` | A | verified | Exact and score intervals look up gamma by the factor's integer code |
| D-29 | `confint.logis_fe(stdz = "direct")` | A | verified | Selects providers through `data$ProvID`; fails for any other column name |
| D-30 | `summary.logis_fe(test = "lr"/"score")` | A | verified | Fails with one or two covariates |
| D-31 | `summary.logis_re`, `summary.logis_cre` | B | verified | p = 2(1 - pnorm(z)) without `abs()`: p-values above 1 for negative estimates |
| D-32 | `confint.linear_fe` | B (question M-8) | verified | Uses t for the simplified variance and z for the full variance, the reverse of `test.linear_fe` |
| D-33 | interval attributes | C | verified | `confidence_level` is "95 %" (FE) or "0.95 %" (RE/CRE); `logis_cre` rate interval labeled "RE logis" |
| D-34 | provider ordering | B | verified | Character IDs are ordered by the session's collation locale, which also fixes the bootstrap draw order |
| D-35 | bundled data docs | C | verified | `ExampleDataBinary` has 7,944 observations, documented as 7,994 |
| D-36 | messages and side effects | Presentation | verified | `linear_fe`, `linear_re`, `logis_re` always print messages; attaching pprof prints a `car` message; `bar_plot()` triggers a ggplot2 deprecation warning |
| D-37 | vignettes | C | verified | Describe a different clamp, nonexistent functions, and calls that now fail |
| D-38 | `logis_fe` with collinear covariates | C | verified | Unidentified estimates with variances near 7e13 and no rank-deficiency warning |
| D-39 | `logis_fe` inputs | A | decided (fix) | Non-binary outcomes, `max.iter` <= 0, `tol` <= 0, and `bound` <= 0 return meaningless or unfitted results without a warning |
| D-40 | AUC without pROC | none (tolerance) | verified; awaiting decision | The Mann-Whitney AUC equals pROC's bitwise in 57 of 59 fits and differs in the last bit in 2 |
| D-41 | `logis_fe`, `logis_firth` with factor IDs | A | verified | Fail when screening excludes a provider: the excluded factor levels become empty provider blocks |

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
- Status: verified (V10.8); option (1) fixed: `fit_logistic_fe()` warns with `pprof_warning_screening` and the true count (Phase 3, step 2), and the `logis_fe()` wrapper keeps the reference's wording with the true count (Phase 3, step 5).
- Regression test: the inclusion rule (n_i >= `min_provider_size`, including a provider of exactly that size) in `tests/testthat/test-data-prepare.R` (Phase 2); the wrapper's warning and its count in `tests/testthat/test-compat-logis-fe.R`.

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
- Status: verified (V10.4); option (1) fixed: `fit_logistic_fe()` keeps the convergence diagnostics and warns with `pprof_warning_not_converged` (Phase 3, step 2); the `logis_fe()` wrapper prints "not converged after N iterations!" and passes the warning on (Phase 3, step 5).
- Regression test: `tests/testthat/test-model-logistic-fe.R` (4 SerBIN iterations for `max_iter = 3`, `converged = FALSE`, the warning class) and `tests/testthat/test-compat-logis-fe.R` (the wrapper's message and warning).

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
- Regression test: `tests/testthat/test-profile-regression.R` (the `logis_fe-d04` fit). No fixture can hold the reference's values for the other 29 providers, because `syn_d04` stores provider IDs as integers, which the reference cannot select (D-27); `tests/testthat/test-cpp-legacy-comparison.R` checked them against the reference's `Modified_score()` bitwise until that routine was removed at the switch (Phase 3, 2026-10-03). A derived dataset with double IDs would give a permanent fixture (question for the project lead, Phase 3 step 4).

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
- Status: verified (V12.3).
- Regression test: planned, `test-model-logistic-firth.R` compares `threads = 2` with `threads = 1` (runs where OpenMP is available; on CRAN at most 2 threads).

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
- Status: verified (V13.13, V15.7).
- Regression test: the rewrite's tests run in strict mode (`tests/testthat/helper-strict.R`, DEC-030), and the reference harness allows only the two D-08 matches (DEC-021).

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
- Status: verified (V15.8).
- Regression test: snapshot tests of the new print methods.

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
- Description: The vector interface builds its data with `as.data.frame(cbind(Y, ProvID, Z))`. With a character `ProvID` and a matrix `Z`, `cbind()` makes everything character and `lmer()` fails ("response must be numeric"). When no input format matches there is no final `else`, so the error is "object 'fit_re' not found". All RE/CRE fits also build `data_include` with `cbind()`, so with character IDs `data_include$Y` is character (methods use other fields, so numbers are unaffected).
- Minimal reproducible example:
  ```r
  data(ExampleDataLinear)
  linear_re(Y = ExampleDataLinear$Y, Z = as.matrix(ExampleDataLinear$Z), ProvID = paste0("P", ExampleDataLinear$ProvID))
  #> Error: response must be numeric
  linear_re(Y = ExampleDataLinear$Y)
  #> Error: object 'fit_re' not found
  ```
- Affected outputs: `linear_re`, `logis_re` vector interface; `data_include` of every RE/CRE fit.
- Statistical impact: none on cases that work.
- Options: build data frames column by column; validate inputs with classed errors.
- Recommendation: fix in the data layer; the compatibility wrappers keep accepting the vector interface.
- Decision owner: project lead.
- Status: verified (V15.9, V15.13).
- Regression test: planned, wrapper tests with character IDs and matrix covariates.

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
- Status: verified (V12.2); awaiting sign-off.
- Regression test: planned, fixtures for every method on Firth fits.

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
- Status: verified (V15.10); awaiting sign-off.
- Regression test: the data layer reproduces it (`tests/testthat/test-data-prepare.R`, and the fixture `linear_cre-missing` in `test-data-reference.R`); fit-level fixture from Phase 4.

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
- Status: verified (V13.9); the recommendation was approved with the Phase 3 plan (2026-10-02). Fixed in the profiling functions (Phase 3, step 3): `null` is checked once, and a numeric scalar, double or integer, is used as a double. The wrappers apply it from the switch (Phase 3, step 5).
- Regression test: `tests/testthat/test-profile-regression.R` (`null = 0L` gives the `SM_output-binary-null0` values, the same tests as `null = 0`, and the funnel of the `plot-binary-null0` fixture, added in Phase 3).

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
- Status: verified (V13.10). New result tables have integer flags (Phase 3, step 3); the wrappers reproduce the factor.
- Regression test: `tests/testthat/test-profile-reference.R` compares the integer flags with the labels of the reference's factor; the wrapper fixtures compare the factor exactly.

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
- Status: verified (V14.3).
- Regression test: linear FE fixtures for both variance types.

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
- Status: verified (V15.11, V13.14). Logistic FE: the new API takes `threads` with default 1, the `SM_output.logis_fe()` wrapper keeps its default of 2, and the direct expectations do not depend on the thread count (Phase 3). The logistic RE and CRE part follows in Phase 5.
- Regression test: `tests/testthat/test-profile-api.R` (the standard score test and the direct expectations with one and two threads); RE and CRE in Phase 5.

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
- Status: verified (V12.4).
- Regression test: documentation-versus-formals test.

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
- Status: verified (V13.11); fixed in the profiling functions (Phase 3, step 3): `providers` is compared as character with the provider IDs. The wrappers apply it from the switch (Phase 3, step 5).
- Regression test: `tests/testthat/test-profile-regression.R` (rows 1 to 3 of `test-extreme-exact` for the integer-ID fit) and `tests/testthat/test-profile-api.R`.

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
- Status: verified (V15.6); awaiting sign-off.
- Regression test: fixture for both summaries.

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
- Status: verified (V14.4); awaiting sign-off.
- Regression test: fixtures for both variance options.

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
- Status: verified (V15.12). New result objects carry the level as a number (Phase 3); the logistic FE wrapper reproduces the old attributes (its fixtures pass); RE and CRE follow in Phase 5.
- Regression test: wrapper fixtures.

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
- Status: verified (V10.10); awaiting sign-off for (2).
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

- Component: `linear_fe`, `linear_re`, `logis_re` (always call `message()`); package attach; `bar_plot`.
- Class (proposed): Presentation (brief §3.2)
- Description: `linear_fe`, `linear_re`, and `logis_re` print their input format with no way to turn it off (the CRE fits print nothing). Attaching pprof prints "Registered S3 method overwritten by 'car'" because `olsrr` loads `car`. `bar_plot()` triggers a ggplot2 deprecation warning for `element_line(size = )`.
- Minimal reproducible example: V14.7, V16.4, V16.2.
- Affected outputs: console output.
- Statistical impact: none.
- Options: one verbosity helper; drop `olsrr`; use `linewidth`.
- Recommendation: DEC-008 (verbosity) and the dependency plan (ARCHITECTURE §H).
- Decision owner: project lead.
- Status: verified.
- Regression test: tests that `verbose = FALSE` produces no output.

### D-37: Vignettes contradict the code

- Component: `vignettes/` (excluded from the package build; rendered on the pkgdown site).
- Class (proposed): C
- Description: `Logis-FE.Rmd` says provider effects are clamped to the previous iteration's median ± 10; the code uses the median of the current, freshly updated effects (K-15). It refers to functions `SR_output()` and `test_fe()`, which do not exist (`SM_output()`, `test()`), and says the Wald test raises an "error message" where the code warns. Its description of the score test (refit for a restricted MLE, then replaced by the full-model β) describes the modified test only; nothing explains what `score_modified = FALSE` computes (D-26). `Quick-start.Rmd` calls `logis_fe(data.prep)` and `confint(fit, option = "SR")`, both of which fail with the current API. `pprof.Rmd` says the package has three fitting functions (it has seven) and links to the site of a different package (`ppsrr`).
- Minimal reproducible example: `confint(fit, option = "SR")` errors "Argument 'option' should be 'gamma' or 'SM'"; compare `vignettes/Logis-FE.Rmd:36` with `src/Fixed_effect.cpp:417`.
- Affected outputs: documentation.
- Statistical impact: none (documentation only).
- Options: correct the vignettes now, or replace them with vignettes for the new API.
- Recommendation: replace them in Phase 7, written for the new API and built and checked as part of the package (brief §9); until then, leave the excluded vignettes unchanged.
- Decision owner: project lead.
- Status: verified by reading the vignettes against the code and the audit results (V10.2, V13.21, BEHAVIOR_SPECS §9).
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

### D-39: `logis_fe` accepts inputs without checking them

- Component: `logis_fe` (`R/logis_fe.R:125-312`, which validates no setting), `logis_BIN_fe_prov` and `logis_fe_prov` (`src/Fixed_effect.cpp`).
- Class (proposed): A, like D-22 and D-23; approved as Class A with the Phase 3 plan (2026-10-02).
- Description: The reference fits whatever it is given. Running it on `ExampleDataBinary` (2026-10-02) showed:
  - an outcome other than 0 and 1: with the values 0 and 0.5 it returns a quasi-likelihood fit (first coefficient 0.482 instead of 1.093); with 0 and 2 the fit diverges and runs to the iteration limit (10,001 SerBIN iterations, provider effects between 14 and 34), and reports convergence;
  - `max.iter` <= 0: SerBIN with 0 runs one iteration; BAN with 0, and both algorithms with a negative value, return the starting values (every coefficient 0, every provider effect -0.457), reported as converged;
  - `tol` <= 0: the stopping rule is never met, so the fit runs `max.iter + 1` (SerBIN) or `max.iter` (BAN) iterations and reports convergence;
  - `bound` = 0 sets every provider effect to their median (-0.874 for all 100 providers); a negative `bound` fails inside Armadillo ("clamp(): min_val must be less than max_val").
  These inputs work as one would expect: a logical outcome (identical to 0 and 1), any `cutoff` (inclusion is n_i >= `cutoff`, so values <= 1 include every provider and 9.5 acts as 10), and a non-integer `max.iter` (Rcpp truncates it).
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
- Status: decided (fix) with the Phase 3 plan; fixed in `fit_logistic_fe()` (Phase 3, step 2); the `logis_fe()` wrapper applies it from the switch (Phase 3, step 5).
- Regression test: `tests/testthat/test-model-logistic-fe.R` ("fit_logistic_fe() rejects invalid settings", "the outcome must be binary with both values").

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
- Status: verified (2026-10-02); awaiting the project lead's decision. The differential test (2026-10-03, `validation/differential-report.md`) found the same pattern on new data: in 9 of 90 fits the AUC differs from the reference's in the last bit, and it is the only value of those fits that is not bitwise identical.
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
- Status: verified (2026-10-02); fixed in `fit_logistic_fe()`; `logis_firth()` follows in Phase 4.
- Regression test: `tests/testthat/test-model-logistic-fe.R` ("factor provider IDs work when screening excludes providers").
