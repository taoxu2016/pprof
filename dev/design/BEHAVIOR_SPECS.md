# Behavior specifications of the reference

Companion to [ARCHITECTURE.md](ARCHITECTURE.md), section J. Reference: pprof 1.0.3 = commit `5260838` (confirmed identical to the CRAN tarball, `dev/design/audit/output/01_cran_identity.log`).

Each specification states what the reference does, so that the rewrite can reproduce it and the Phase 1 fixtures can be designed around it. Formulas and constants are not repeated here: rows cite the verified conventions register (PROJECT_CONTEXT §5.7, IDs `K-xx`), the discrepancy register (`D-xx`), and the audit evidence (`Vxx.y`, logs in `dev/design/audit/output/`). Statements marked "not verified" come from reading the code only; the Phase 1 edge-case suite must pin them down before Phase 3 relies on them.

Contents:

1. [Shared input processing for fixed-effect fits](#1-shared-input-processing-for-fixed-effect-fits)
2. [`logis_fe()`](#2-logis_fe)
3. [`logis_firth()`](#3-logis_firth)
4. [`linear_fe()`](#4-linear_fe)
5. [`linear_re()` and `logis_re()`](#5-linear_re-and-logis_re)
6. [`linear_cre()` and `logis_cre()`](#6-linear_cre-and-logis_cre)
7. [`test()` methods](#7-test-methods)
8. [`SM_output()` methods](#8-sm_output-methods)
9. [`confint()` methods](#9-confint-methods)
10. [`summary()` methods](#10-summary-methods)
11. [`plot()` methods](#11-plot-methods)
12. [`caterpillar_plot()` and `bar_plot()`](#12-caterpillar_plot-and-bar_plot)
13. [`data_check()`](#13-data_check)
14. [`print()` methods and generics](#14-print-methods-and-generics)
15. [Bundled data](#15-bundled-data)
16. [Output shapes that the compatibility wrappers must reproduce](#16-output-shapes-that-the-compatibility-wrappers-must-reproduce)

---

## 1. Shared input processing for fixed-effect fits

`logis_fe()`, `logis_firth()`, and `linear_fe()` repeat the same preparation (`R/logis_fe.R:130-216`, `R/logis_firth.R:97-185`, `R/linear_fe.R:93-163`).

| Step | Behavior | Refs |
|---|---|---|
| Format selection | First matching branch wins: (1) `formula` and `data` both non-NULL; (2) `data`, `Y.char`, `Z.char`, `ProvID.char` all non-NULL; (3) `Y`, `Z`, `ProvID` all non-NULL; otherwise error "Insufficient or incompatible arguments provided. …". | K-01 |
| Formula branch | `Y.char` = first variable of `terms(formula)`; `ProvID.char` = text inside `id(...)` of the term labels (regex); `Z.char` = the other term labels. Every one must be a column of `data`, otherwise "Formula contains variables not in the data or is incorrectly structured." Transformations and interactions therefore fail. | K-02, D-18 |
| Column branch | Same column check, message "Some of the specified columns are not in the data!". | |
| Vector branch | Lengths must match (`length(Y) == length(ProvID) == nrow(Z)`), otherwise "Dimensions of the input data do not match!!". `data.frame(Y, ProvID, Z)` names the columns `Y`, `ProvID`, and the columns of `Z`. | |
| Missing data | Keep only the response, provider, and covariate columns, then `complete.cases()`. | K-03 |
| Design matrix | `model.matrix(reformulate(Z.char), data)[, -1, drop = FALSE]`; factor coding from `options("contrasts")`; the result is put back into a data frame with `data.frame()`, which rewrites non-syntactic names (D-18). `Z.char` becomes the design-matrix column names. | K-04 |
| Provider column type | Kept from the input: numeric, integer, character, or factor (the formula and column branches keep `data`'s type; the vector branch keeps the vector's type). | V10.11 |
| Sorting | `data[order(factor(ProvID)), ]`; provider labels are the `factor()` levels. | K-05, D-34 |

## 2. `logis_fe()`

Signature: `logis_fe(formula = NULL, data = NULL, Y.char = NULL, Z.char = NULL, ProvID.char = NULL, Y = NULL, Z = NULL, ProvID = NULL, method = "SerBIN", max.iter = 10000, tol = 1e-5, bound = 10, cutoff = 10, backtrack = TRUE, stop = "or", threads = 1, message = TRUE)`.

Processing:

1. Input processing (§1).
2. Screening (K-06). With `message = TRUE`: message "Input format: …"; immediate warning "k out of m providers considered small and filtered out!" where k counts n_i ≤ cutoff (D-01); messages for no-event and all-event counts among included providers; message with the event rate after screening. With `message = FALSE` none of these appear, not even the warning.
3. Starting values (K-10).
4. Engine: `method = "SerBIN"` → `logis_BIN_fe_prov()` (K-12 to K-18); `"BAN"` → `logis_fe_prov()`; any other value → error "Argument 'method' NOT as required!". The C++ fitters print per-iteration criteria and a final "converged after N iterations" line through `Rcout` when `message = TRUE` (D-03). An invalid `stop` errors inside C++ after the first iteration ("Argument 'stop' NOT as required!").
5. Variance with `logis_fe_var()` (K-20).
6. Log-likelihood, AIC, BIC (K-11, K-21); linear predictor and fitted values (K-23); AUC (K-22; `pROC` messages suppressed when `message = FALSE`).

Output: a list of class `"logis_fe"` (shapes in §16):

| Field | Content |
|---|---|
| `coefficient$beta` | p × 1 matrix, dimnames (design-matrix column names, "beta") |
| `coefficient$gamma` | m × 1 matrix, dimnames (provider labels, "gamma") |
| `variance$beta` | p × p matrix, dimnames from `Z.char` |
| `variance$gamma` | m × 1 matrix, column "Variance.Gamma" |
| `fitted` | n × 1 matrix "Predicted Probability", row names "1".."n" |
| `observation` | numeric vector of y (included rows, sorted) |
| `linear_pred` | n × 1 matrix "Linear Predictor" (Zβ), row names "1".."n" |
| `Loglkd`, `AIC`, `BIC`, `AUC` | numeric scalars |
| `char_list` | `Y.char`, `ProvID.char`, `Z.char` |
| `data_include` | data frame of included rows only, sorted by provider: response, provider, design-matrix columns, `included` (always 1), `no.events`, `all.events` |

There are no convergence fields (D-03).

Edge cases:

| Case | Behavior | Refs |
|---|---|---|
| Provider with n_i < cutoff | Dropped from every output | K-06, V10.8 |
| No-event or all-event provider | Kept; gamma bounded by the clamp (all-event providers reach median + bound on the example) | K-15, V10.9 |
| `threads < 1` | Undefined behavior; observed beta ≈ 0 | D-22 |
| `method = "BAN"`, `backtrack` not 0 or 1 | No iterations; starting values returned | D-23 |
| `max.iter` reached | "converged" message anyway; SerBIN runs max.iter + 1 iterations | D-03 |
| Default `stop = "or"` on large data | Stops before provider effects settle | D-24 |
| `threads > 1` | Rounding-level differences, deterministic | D-20 |
| Response not 0/1, all providers excluded, singular Schur complement, collinear covariates | Not validated. Not verified; Phase 1 edge-case suite | |

## 3. `logis_firth()`

Signature: `logis_firth(formula = NULL, data = NULL, Y.char = NULL, Z.char = NULL, ProvID.char = NULL, Y = NULL, Z = NULL, ProvID = NULL, max.iter = 1000, tol = 1e-5, bound = 10, cutoff = 10, threads = 1, message = TRUE)`.

Processing: input processing and screening exactly as `logis_fe()` (the R code is a verbatim copy, including D-01), starting values K-10, then `logis_firth_prov()` (K-30 to K-33) with `stop` fixed to "beta". The C++ result also contains the penalized log-likelihood, its trace, the iteration count, and the final criterion; R discards them. Variance, log-likelihood, AIC, BIC, linear predictor, fitted values, and AUC are computed exactly as in `logis_fe()`, at the Firth estimates (K-34).

Output: identical structure and class to `logis_fe()` (D-12).

Edge cases: `threads > 1` races and stops early (D-05); the parallel region calls `Rcpp::stop` and can throw (undefined behavior on failure, not verified). Help states the wrong `max.iter` default (D-25). Independent check: estimates agree with `logistf` with provider indicators to 2e-11 on small data without extreme providers (V12.5).

## 4. `linear_fe()`

Signature: `linear_fe(formula = NULL, data = NULL, Y = NULL, Z = NULL, ProvID = NULL, Y.char = NULL, Z.char = NULL, ProvID.char = NULL, option.gamma.var = "simplified")`. Argument order differs from `logis_fe()`; there is no `message`, `cutoff`, or `threads` argument.

Processing: input processing (§1) with an unconditional "Input format: …" message; a second `complete.cases()` pass (no effect); no screening (K-07); estimates, variances, and criteria per K-40 to K-43. `option.gamma.var` must be "full"/"f" or "simplified"/"s", otherwise "Argument 'option.gamma.var' should be 'full' or 'simplified'." The variance type is stored as `attr(variance$gamma, "description")` and later selects the test distribution (D-16).

Output: list of class `"linear_fe"` with `coefficient$beta` (p × 1, "beta"), `coefficient$gamma` (m × 1, "gamma"), `variance$beta`, `variance$gamma` (m × 1 "Variance.Gamma", with the description attribute), `sigma` (σ̂), `fitted` (n × 1 "Prediction"), `observation` (n × 1 matrix), `residuals` (n × 1 "Residuals"), `linear_pred` (n × 1 "Linear Predictor"), `Loglkd`, `AIC`, `BIC`, `data_include` (response, provider, design columns; sorted), `char_list`.

Performance: memory and time grow with Σn_i² because of the dense centering blocks (4.35 GB allocated for 20 providers of 1,000 observations; ARCHITECTURE §F).

## 5. `linear_re()` and `logis_re()`

Signature: `linear_re(formula = NULL, data = NULL, Y = NULL, Z = NULL, ProvID = NULL, Y.char = NULL, Z.char = NULL, ProvID.char = NULL, ...)`; `logis_re()` takes the same arguments. `...` goes to `lmer()` / `glmer()`.

| Step | Behavior | Refs |
|---|---|---|
| Formula branch | Response = first variable; provider = text after `|` in the term containing `|`, trimmed; covariates = the other term labels, which must be columns. The user's formula is passed to lme4 unchanged, so any lme4 syntax in it reaches the engine | K-02 |
| Column branch | Formula built as `paste(Y.char, "~ (1|", ProvID.char, ") +", paste(Z.char, collapse = " + "))` | K-50 |
| Vector branch | `as.data.frame(cbind(Y, ProvID, Z))` (coercion, D-11); formula `Y ~ (1| ProvID)+z1+…` | D-11 |
| No branch matches | Error "object 'fit_re' not found" | D-11 |
| Missing data and sorting | Complete cases on the used columns, then sort by provider | K-03, K-05 |
| Engine | `lmer(formula, data, ...)` or `glmer(formula, data, family = binomial(link = "logit"), ...)` | K-50, V15.1 |

Output: list of class `"linear_re"` / `"logis_re"`: `coefficient$FE` (fixef as a column matrix "Coefficient"), `coefficient$RE` (ranef as a matrix "alpha", rows renamed to the provider order), `variance$alpha` (1 × 1 "Variance.Alpha", K-51), `variance$FE` (vcov), `sigma` (linear only), `fitted` ("Prediction", including α), `observation` (n × 1 matrix), `residuals` (linear only), `linear_pred` ("Fixed Fitted", Xβ with intercept), `Loglkd` (`logLik` object), `AIC`, `BIC`, `data_include` (`cbind()` of response, provider, and `model.matrix(fit)`; character when IDs are character, V15.13), `char_list` (`Z.char` = fixed-effect names without the intercept), and `attr(, "model")` = the full merMod.

Messages: an unconditional "Input format: …" message.

## 6. `linear_cre()` and `logis_cre()`

Signature: `linear_cre(data, Y.char, wb.char, other.char = NULL, ProvID.char, ...)`; `logis_cre()` the same. Column-name interface only.

| Step | Behavior | Refs |
|---|---|---|
| Validation | All named columns must exist ("Some specified columns are not in `data`.") | |
| Decomposition | With dplyr, per provider on the full input data: `<x>_bar` = mean(x, na.rm = TRUE), `<x>_within` = x − mean(x, na.rm = TRUE) | K-54, D-13 |
| Model data | Columns response, provider, `<wb>_within…`, `<wb>_bar…`, `other.char`; complete cases; sort by provider | K-03, K-05 |
| Formula | `Y ~ <within terms> + <between terms> + <other> + (1 | ProvID)` | K-50 |
| Engine | `lmer()` / `glmer(family = binomial(link = "logit"))` with `...` | K-50 |

Output: as RE models, with `char_list` holding `Y.char`, `ProvID.char`, `within_terms`, `between_terms`, `other.vars`. `logis_cre`: `variance$alpha` from `vcov` (K-51); `observation` is a one-column tibble; `fitted` and `linear_pred` have no row names; RE row names come from `ranef()` (same order). Neither CRE function prints a format message.

## 7. `test()` methods

`test()` is an exported S3 generic (`test(fit, ...)`).

### 7.1 `test.logis_fe(fit, parm, level = 0.95, test = "exact.poisbinom", score_modified = TRUE, null = "median", n = 10000, threads = 1, alternative = "two.sided", ...)`

| Item | Behavior | Refs |
|---|---|---|
| Validation | `fit` required and of class `logis_fe` (`!class(fit) %in% …`); `test` in "exact.poisbinom", "exact.bootstrap", "score", "wald", "robust_wald" | D-06 |
| Null | "median" → median(γ̂); numeric → first element; otherwise "Argument 'null' NOT as required!" | K-60 |
| `parm` | Doubles kept; integers converted to double; must have the provider column's class, else "Argument 'parm' includes invalid elements!" (D-27). For exact, bootstrap, and modified score tests, rows and sizes are subset to `parm`; for Wald and the standard score test, all providers are computed and the result is subset | |
| exact.poisbinom | Per provider with `by()` in provider order | K-62, K-63 |
| exact.bootstrap | `n` must be a positive integer | K-64 |
| score, modified | | K-65 |
| score, standard | C++ `Modified_score(…, threads)` | K-66, D-04, D-26 |
| wald | Always warns "Wald test fails for datasets with providers having all or no events. …" | K-67 |
| alternative | Other values → error "Argument 'alternative' should be one of 'two.sided', 'greater', or 'less'" (the Wald branch has a different wording) | K-63 |

Output: data frame with row names = provider labels, columns `flag` (factor, D-15), `p value`, `stat`, and `Std.Error` for Wald; attribute `"provider size"` = named n_i.

### 7.2 `test.linear_fe(fit, parm, level = 0.95, null = "median", alternative = "two.sided", ...)`

No class check. Null "median", "mean", or numeric (`class(null) == "numeric"`). Statistic and distribution K-68 (D-16). `parm`: integers converted to double; class must match; rows subset by row name. Output as 7.1 with `Std.Error`.

### 7.3 `test.linear_re`, `test.logis_re`, `test.linear_cre`, `test.logis_cre` `(fit, parm, level = 0.95, null = 0, alternative = "two.sided", ...)`

No validation of `fit` or `null`. Standard errors K-69 (`linear_re`) or K-70 (the others, recomputing `ranef(condVar = TRUE)` from the stored lme4 fit). Flags K-63. `parm` handling as 7.2 (`is.numeric` conversion). Output as 7.1 with `Std.Error`.

## 8. `SM_output()` methods

`SM_output()` is an exported S3 generic.

### 8.1 `SM_output.logis_fe(fit, parm, stdz = "indirect", measure = c("rate", "ratio"), null = "median", threads = 2, ...)`

Validation: `fit` required, class `logis_fe`; `stdz` must contain "indirect" or "direct"; `measure` must contain "rate" or "ratio". Null: "median" or `class(null) == "numeric"` (D-14). `parm`: numeric converted to double, class must match the provider column; selects rows of every output.

Computation: indirect K-80 (requires `null`), direct K-81 (`null` unused). Population rate uses `fit$obs` by partial matching (D-08).

Output: list with `indirect.ratio`, `indirect.rate`, `direct.ratio`, `direct.rate` (each an m × 1 matrix with row names = providers and column names "Indirect_standardized.ratio" and so on, present only when requested) and `OE` = list(`OE_indirect` = data frame `Obs_provider`, `Exp.indirect_provider`, `Var.indirect_provider`; `OE_direct` = data frame `Obs_all`, `Exp.direct_all`).

### 8.2 `SM_output.linear_fe(fit, parm, stdz = "indirect", null = "median", ...)`

Null "median", "mean", numeric. K-83. Output `indirect.difference`, `direct.difference` (m × 1 matrices), `OE` = list(`OE_indirect` = `Obs`, `Exp`; `OE_direct` = `Obs` (scalar repeated), `Exp`).

### 8.3 `SM_output.linear_re`, `SM_output.linear_cre` `(fit, parm, stdz = "indirect", ...)`

No `null` argument. K-84. Output as 8.2.

### 8.4 `SM_output.logis_re`, `SM_output.logis_cre` `(fit, parm, stdz = "indirect", measure = c("rate", "ratio"), threads = 2, ...)`

No `null` argument (α = 0 is the reference). K-82. Output as 8.1, with indirect columns `Obs.indirect_provider`, `Exp.indirect_provider` (no variance column).

## 9. `confint()` methods

### 9.1 `confint.logis_fe(object, parm, level = 0.95, test = "exact", option = "SM", stdz = "indirect", null = "median", measure = c("rate", "ratio"), alternative = "two.sided", ...)`

| Item | Behavior | Refs |
|---|---|---|
| Validation | class `logis_fe`; `option` "gamma" or "SM"; `test` "exact", "score", "wald"; `stdz` contains "indirect" or "direct"; `option = "gamma"` requires two-sided | |
| Provider-effect intervals | Groups: finite, no-event, all-event providers, each computed with `by()`; result rows reordered by `order(as.numeric(rownames))` | K-90, D-19, D-28 |
| Wald | Always warns; one-sided variants as K-94 | K-90 |
| SM intervals | Point estimates from `SM_output()` (default `threads = 2`); each provider's limits from a separate call to the provider-effect routine, which re-splits the whole data set | K-91, D-19, D-29 |
| Rates | Clipped; `population_rate` computed from `data_include` | K-80 |

Output: `option = "gamma"`: data frame `gamma`, `gamma.lower`, `gamma.upper` with attribute `description = "Provider Effects"`. `option = "SM"`: list with `CI.indirect_ratio` (`indirect_ratio`, `CI_ratio.lower`, `CI_ratio.upper`), `CI.indirect_rate` (`indirect_rate`, `CI_rate.lower`, `CI_rate.upper`), and the direct equivalents, present as requested; attributes `confidence_level` ("95 %"), `type` ("two-sided", "upper one-sided", "lower one-sided"), `description`, `model` ("FE logis"), and `population_rate` on rate tables and direct ratio tables.

Run time: 3.2 s (gamma) and 4.7 s (SM) for 400 providers of about 60 (ARCHITECTURE §F).

### 9.2 `confint.linear_fe(object, parm, level = 0.95, option = "SM", stdz = "indirect", null = "median", alternative = "two.sided", ...)`

K-92 (D-32). Output: `option = "gamma"` → data frame `gamma`, `gamma.Lower`, `gamma.Upper` with description; `option = "SM"` → list `CI.indirect` (`Indirect.Difference`, `indirect.Lower`, `indirect.Upper`), `CI.direct` (`Direct.Difference`, `direct.Lower`, `direct.Upper`) with attributes (`model = "FE linear"`).

### 9.3 `confint.linear_re`, `confint.linear_cre` `(object, parm, level = 0.95, option = "SM", stdz = "indirect", alternative = "two.sided", ...)`

`option` is "alpha" or "SM". K-93 with the K-69 (RE) or K-70 (CRE) standard errors. Output as 9.2 with `Estimate`, `alpha.Lower`, `alpha.Upper` for `option = "alpha"`; attributes `confidence_level` "0.95 %" (D-33), `model` "RE linear" / "CRE linear".

### 9.4 `confint.logis_re`, `confint.logis_cre` `(object, parm, level = 0.95, option = "SM", measure = c("rate", "ratio"), stdz = "indirect", alternative = "two.sided", ...)`

K-93 with K-70 standard errors; direct limits via `computeDirectExp(…, threads = 4)` (D-21); population rate through `object$obs` (D-08). Output: `option = "alpha"` as 9.3; SM lists `CI.indirect_ratio` (`Indirect.Ratio`, `Ratio.Lower`, `Ratio.Upper`), `CI.indirect_rate` (`Indirect.Rate`, `Rate.Lower`, `Rate.Upper`), and direct equivalents; `model` "RE logis" / "CRE logis" (the `logis_cre` indirect rate says "RE logis", D-33).

## 10. `summary()` methods

| Method | Signature | Behavior | Refs |
|---|---|---|---|
| `summary.logis_fe` | `(object, parm, level = 0.95, test = "wald", null = 0, ...)` | `test` in "wald", "lr", "score"; `parm` names or positive integer positions. Wald: data frame `Estimate`, `Std.Error`, `Stat`, `p value` (character), `CI.Lower`, `CI.Upper`. LR and score: `Estimate`, `stat`, `p value` (numeric); `null` must be 0 | K-100 to K-102, D-10, D-30 |
| `summary.linear_fe` | `(object, parm, level = 0.95, null = 0, ...)` | t-based table as Wald above | K-103 |
| `summary.linear_re`, `summary.linear_cre` | `(object, parm, level = 0.95, null = 0, ...)` | Includes the intercept (`parm` names use "(intercept)" in lower case for matching); t p-values, lme4 Wald intervals | K-104, D-08 |
| `summary.logis_re`, `summary.logis_cre` | `(object, parm, level = 0.95, null = 0, ...)` | Normal p-values without `abs()`; lme4 Wald intervals | K-105, D-31 |

The return values are plain data frames; there is no summary class or print method.

## 11. `plot()` methods

| Method | Behavior | Refs |
|---|---|---|
| `plot.logis_fe(x, null = "median", test = "score", target = 1, alpha = 0.05, labels, point_colors, point_shapes, point_size = 2, point_alpha = 0.8, line_size = 0.8, target_line_type = "longdash", ...)` | Funnel plot of the indirect standardized ratio against precision; `test = "score"` works, `"exact"` always errors (D-07); flags from `test()` at level `1 - alpha[1]`; returns a ggplot without printing | K-110, D-07, D-14 |
| `plot.linear_fe(x, null = "median", target = 0, alpha = 0.05, …)` | Funnel plot of the indirect standardized difference against provider size | K-111 |

Both pass `.data$` column references to `select()`, which tidyselect deprecates (warnings in recent versions, not verified).

## 12. `caterpillar_plot()` and `bar_plot()`

| Function | Behavior | Refs |
|---|---|---|
| `caterpillar_plot(CI, point_size = 2, point_color, refline_value = NULL, …, use_flag = FALSE, orientation = "vertical", flag_color)` | Takes one interval table from `confint(option = "SM")`; errors for `description = "Provider Effects"`; dispatches on the `model`, `description`, `type`, and `population_rate` attributes; flags from intervals versus the reference line; providers ordered by the measure | K-112 |
| `bar_plot(flag_df, group_num = 4, bar_colors, bar_width = 0.7, label_color, label_size = 4)` | Takes a `test()` result; requires a `flag` column and the `"provider size"` attribute; stacked bars of flag shares by size quantile group plus "Overall"; ggplot2 deprecation warning for `element_line(size = )` | K-113, D-36 |

## 13. `data_check()`

Signature: `data_check(Y, Z, ProvID)`. Builds `as.data.frame(cbind(Y, ProvID, Z))` and runs four checks with messages, warnings, and stops (K-120): missingness (stop with the percentage of incomplete rows, after per-column warnings), zero or near-zero variance, pairwise correlation above 0.9 (lists pairs), VIF ≥ 10 (from `lm(Y ~ Z)`). Returns `NULL` invisibly (the value of the last `message()`). D-17.

## 14. `print()` methods and generics

| Item | Behavior | Refs |
|---|---|---|
| `print.linear_re`, `print.logis_re`, `print.linear_cre` | Remove `attr(, "model")` and call `print.default()` on the whole list | D-09 |
| `print.logis_cre` | Defined, not registered; printing uses `print.default()` including the lme4 fit | D-09 |
| Other classes | No print method; `print.default()` | |
| Exported generics | `test()` (collides with `devtools::test()`, V16.3) and `SM_output()` | |

## 15. Bundled data

| Object | Content (verified, V16.7) | Notes |
|---|---|---|
| `ExampleDataBinary` | list `Y` (7,944 binary), `ProvID` (numeric, 100 providers of 50–103), `Z` (data frame `z1`–`z5`) | 3 no-event providers (IDs 40, 49, 81), none all-event. Help says 7,994 observations (D-35) |
| `ExampleDataLinear` | list `Y` (7,901), `ProvID` (100 providers of 54–99), `Z` (`z1`–`z5`) | |
| `ecls_data` | tibble 9,101 × 5: `Child_ID`, `School_ID` (numeric; 2,275 schools of 1–53 children, 334 with at least 10), `Math_Score`, `Income`, `Child_Sex` (factor "1"/"2") | Exercises screening (1,195 schools of size 1) and factor handling |

## 16. Output shapes that the compatibility wrappers must reproduce

The compatibility wrappers (ARCHITECTURE §I) return these shapes exactly, because user scripts index them:

- Model objects: the field names and nesting of §2 to §6, including matrix shapes and dimnames, `data_include` with its indicator columns, `char_list`, and for RE/CRE the merMod in `attr(, "model")`. Verified in Phase 2 by rebuilding `data_include` from the data layer for all 87 fit fixtures that return a value (`tests/testthat/helper-reference-data.R`): FE fits build it with `data.frame(Y, ProvID, Z)` (response and provider columns named after the input's variables or `Y` and `ProvID`, design names passed through `make.names()`, the input's row names in their stored type); RE fits with `as.data.frame(cbind(Y, ProvID, model.matrix(fit)))`, so every column is coerced to one type (character when the provider IDs are), with the input's row names, or the positions 1..n for a tibble input; CRE fits with the positions 1..n, because their data pass through dplyr; the CRE `char_list` records formula terms, not design column names.
- `test()` results: data frames with provider row names, column names `flag`, `p value`, `stat`, `Std.Error`, factor flags, and the `"provider size"` attribute.
- `SM_output()` results: the list names and matrix column names of §8.
- `confint()` results: the data frame column names and attributes of §9, including the D-33 inconsistencies.
- `summary()` results: the data frames of §10, including character p-values where the reference returns them.

Fixtures (Phase 1) store these objects in full so that the wrappers can be checked field by field.
