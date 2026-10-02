# Naming convention

Status: approved with the Phase 0 gate (2026-10-02). This file is authoritative for every name in the rewrite (brief §5.4). Example names elsewhere in the brief and in `PROJECT_CONTEXT.md` are illustrative only.

The reference names that this convention replaces are listed in [ARCHITECTURE.md §I](design/ARCHITECTURE.md#i-migration-strategy), with the compatibility wrapper that keeps each one working.

## 1. Principles

1. Names say what a thing is or does in the domain's words: provider, effect, standardization, measure, flag.
2. One concept has one name everywhere: in R functions, arguments, object fields, table columns, C++ identifiers, and documentation.
3. Functions that act are verbs (`fit_logistic_fe()`, `test_providers()`). Objects and fields are nouns (`provider_effects`, `linear_predictor`).
4. Abbreviations come only from the whitelist in §2.
5. No name collides with a common function or shadows one: no exported `test()`, no argument named `message`, `stop`, `t`, `c`, `data.frame`, and so on.
6. Names that leave the package (exports, arguments, result columns, condition classes) are stable API. Internal names may change freely but follow the same rules.

## 2. Abbreviation whitelist

Only these abbreviations may appear in names. Anything else is spelled out.

| Abbreviation | Meaning | Example |
|---|---|---|
| `fe` | fixed effects | `fit_logistic_fe()` |
| `re` | random effects | `fit_linear_re()` |
| `cre` | correlated random effects (Mundlak within-between) | `fit_logistic_cre()` |
| `se` | standard error | `provider_estimate_se()`, `std_error` column |
| `ci` | confidence interval | only in internal helpers such as `ci_from_roots()`; exported results say `lower`/`upper` |
| `id` | identifier | `provider_id` |
| `vcov` | variance-covariance matrix | the `stats::vcov()` generic |
| `n` | count, in `n_*` field names | `n_providers`, `n_obs` |
| `obs` | observation(s), only in `n_obs` | `n_obs` |
| `cpp` | C++ adapter prefix (§6) | `cpp_logistic_fe_serbin()` |
| `serbin`, `ban` | the algorithm names from the literature | `method = "serbin"` |
| `aic`, `bic`, `auc` | information criteria, area under the ROC curve | `fit$aic` |
| `lr` | likelihood ratio, in test-type values only | `test = "lr"` |
| `lme4` | the package, in adapter names only | `lme4_fit_glmer()` |

Not carried over: `logis`, `SM`, `stdz`, `Y.char`, `Z.char`, `ProvID`, `ProvID.char`, `wb.char`, `other.char`, `char_list`, `Loglkd`, `parm` (except as the `stats::confint()` argument), `prov`, `obs` as a field name.

## 3. R functions

### 3.1 Exported API

| Role | Pattern | Names |
|---|---|---|
| Fit a model | `fit_<outcome>_<effects>()` | `fit_logistic_fe()`, `fit_logistic_firth()`, `fit_linear_fe()`, `fit_logistic_re()`, `fit_linear_re()`, `fit_logistic_cre()`, `fit_linear_cre()` |
| Provider effects with SEs and optional intervals | noun | `provider_effects()` |
| Provider-level tests and flags | verb | `test_providers()` |
| Standardized measures with optional intervals | verb | `standardize_providers()` |
| Everything a profiling report needs, keyed by provider | verb | `profile_providers()` |
| Funnel-plot control limits | noun | `funnel_limits()` |
| Covariate-level tests (Wald, LR, score) | verb | `test_coefficients()` |
| Data diagnostics | verb | `check_data()` |
| Plots | `plot_<kind>()` | `plot_funnel()`, `plot_caterpillar()`, `plot_flags()` |
| Model-contract generics for extension developers | noun | `provider_table()`, `provider_index()`, `linear_predictor()`, `observed_outcome()`, `expected_outcome()`, `null_effect()`, `profile_spec()`, `inference_capabilities()`, `provider_estimates()`, `provider_estimate_se()`, `provider_test()`, `refit_without()` (ARCHITECTURE §E.1; documented in the developer guide, exported with `@keywords internal`). They return plain vectors and tables; the user-facing `provider_effects()` builds its result object from them |

Standard generics keep their base-R names and meanings: `print`, `summary`, `coef`, `vcov`, `confint`, `predict`, `fitted`, `residuals`, `nobs`, `logLik`, `formula`, `plot`, and `tidy`, `glance`, `augment` from `generics`.

`confint()` on a model returns intervals for the covariate coefficients, as `stats::confint()` does everywhere else in R. Provider-level intervals come from `provider_effects()` and `standardize_providers()` through their `interval` argument. This is the one place where the new API deliberately departs from the reference's use of a standard generic (the reference's `confint()` returns provider intervals); the compatibility wrapper keeps the old meaning for old objects.

### 3.2 Internal helpers

Internal functions are unexported, snake_case, and start with the name of their layer so that grouping is visible in file listings and stack traces:

| Layer | Prefix | Examples |
|---|---|---|
| Data | `data_` | `data_parse_formula()`, `data_build_design()`, `data_index_providers()`, `data_screen_providers()`, `data_decompose_within_between()` |
| Model engines | `<family>_` | `logistic_fe_engine()`, `linear_fe_engine()`, `lme4_fit()` |
| Inference | `infer_` | `infer_p_value()`, `infer_flag()`, `infer_invert_test()`, `infer_wald()` |
| Profiling | `profile_` | `profile_expected()`, `profile_indirect()`, `profile_direct()` |
| Presentation | `present_`, `plot_` (internal plot builders end in `_layer`) | `present_coefficient_table()`, `plot_funnel_layer()` |
| Conditions and messages | `abort_`, `warn_`, `inform_` | `abort_invalid_input()`, `inform_screening()` |
| Compatibility wrappers | `compat_` | `compat_logis_fe_result()` |

Constructors and validators follow the S3 convention exactly: `new_pprof_<class>()` and `validate_pprof_<class>()`. User-facing helpers that build validated objects, if any, are `pprof_<class>()`.

## 4. Argument vocabulary

Every function that takes one of these concepts uses the name, type, and default in this table. Sibling functions take shared arguments in the same order: data arguments first, then model settings, then inference settings, then computational settings (`threads`, `verbose`), then `...`.

| Concept | Name | Type and values | Default | Replaces |
|---|---|---|---|---|
| Model formula (response on the left, covariates on the right) | `formula` | two-sided formula | required | `formula`, `Y.char`, `Z.char`, `Y`, `Z` |
| Data | `data` | data frame | required | `data` |
| Provider identifier | `provider` | single string naming a column of `data` | required | `id()` term, `(1 | x)` term, `ProvID.char`, `ProvID` |
| Covariates split into within- and between-provider parts (CRE) | `within_between` | character vector of covariate names in `formula` | required for CRE | `wb.char` (`other.char` is the rest of the formula) |
| Fitting algorithm | `method` | `"serbin"`, `"ban"` | `"serbin"` | `method = "SerBIN"`/`"BAN"` |
| Maximum iterations | `max_iter` | positive integer | family default (10000 FE, 1000 Firth) | `max.iter` |
| Convergence tolerance | `tol` | positive number | `1e-5` | `tol` |
| Stopping rule | `stop_rule` | `"any"`, `"all"`, `"coefficients"`, `"relative_loglik"`, `"relative_gain"` | `"any"` (logistic FE) | `stop` = `"or"`, `"all"`, `"beta"`, `"relch"`, `"ratch"` |
| Line search | `backtrack` | `TRUE`/`FALSE` | `TRUE` | `backtrack` |
| Provider-effect bound | `effect_bound` | positive number | `10` | `bound` |
| Minimum provider size | `min_provider_size` | positive integer | `10` (logistic FE and Firth only) | `cutoff` |
| Provider-effect variance (linear FE) | `provider_variance` | `"simplified"`, `"full"` | `"simplified"` | `option.gamma.var` |
| Engine pass-through (lme4) | `...` | passed to `lmer()`/`glmer()` | none | `...` |
| Keep large data in the object | `keep_data` | `TRUE`/`FALSE` | `FALSE` | (new) |
| Providers to report | `providers` | vector of provider IDs, compared as character | all providers | `parm` (provider functions) |
| Coefficients to report | `parm` | names or positions, as in `stats::confint()` | all | `parm` (`summary`) |
| Confidence level | `level` | number in (0, 1) | `0.95` | `level`; funnel `alpha` |
| Alternative hypothesis | `alternative` | `"two.sided"`, `"greater"`, `"less"` | `"two.sided"` | `alternative` |
| Null value or population norm | `null` | `"median"`, `"mean"` (linear FE), or a number | family default (`"median"` FE, `0` RE) | `null` |
| Provider test | `test` | `"exact"`, `"bootstrap"`, `"score"`, `"wald"` | `"exact"` (logistic FE) | `test = "exact.poisbinom"`, `"exact.bootstrap"`, `"score"`, `"wald"` |
| Score-test variant | `score_type` | `"modified"`, `"standard"` | `"modified"` | `score_modified` |
| Bootstrap resamples | `n_resamples` | positive integer | `10000` | `n` |
| Covariate test | `test` (in `test_coefficients()` and `summary()`) | `"wald"`, `"lr"`, `"score"` | `"wald"` | `test` |
| Standardization | `standardization` | `"indirect"`, `"direct"`, or both | `"indirect"` | `stdz` |
| Measure scale | `measure` | `"ratio"`, `"rate"` (logistic); `"difference"` (linear) | `"ratio"` and `"rate"` (logistic), `"difference"` (linear) | `measure` |
| Interval type for provider effects and measures | `interval` | `"none"`, `"exact"`, `"score"`, `"wald"` | `"none"` | `confint(test = ...)` |
| Funnel target | `target` | number | `1` (ratio), `0` (difference) | `target` |
| Thread count | `threads` | positive integer | `1` | `threads` (and hard-coded 2 and 4) |
| Verbosity | `verbose` | `TRUE`/`FALSE` | `FALSE` | `message` |

Notes:

- Argument values are lowercase snake_case strings. Where a reference value is a historical abbreviation (`"or"`, `"relch"`, `"exact.poisbinom"`) the new value is descriptive, and the compatibility wrappers translate.
- `stop_rule = "any"` is the reference's `"or"`: stop as soon as the smallest of the three criteria falls below `tol`. `"all"` stops when the largest does. The criteria are defined in PROJECT_CONTEXT §5.7.
- Defaults are the reference defaults, except `threads` (DEC-001), `verbose` (DEC-008), and `keep_data` (new). A default that would change a number is Class B and is not changed here.
- `level` replaces the funnel plot's `alpha` so that every function speaks in confidence levels. Internally, alpha is computed as `1 - level`, as the reference's tests and intervals do (K-61; `1 - 0.95` is not `0.05` in floating point). The reference funnel plot uses its `alpha` argument directly for the control limits (K-110), so the compatibility wrapper passes `alpha` through unchanged; new funnel limits computed from `level` differ from the reference only at rounding level (Tier 1).

## 5. S3 classes and result objects

Every class starts with `pprof_`. Model classes have at most one intermediate class.

| Class vector | Built by |
|---|---|
| `c("pprof_logistic_fe", "pprof_model")` | `fit_logistic_fe()` |
| `c("pprof_logistic_firth", "pprof_logistic_fe", "pprof_model")` | `fit_logistic_firth()` (inheritance pending open question M-2) |
| `c("pprof_linear_fe", "pprof_model")` | `fit_linear_fe()` |
| `c("pprof_logistic_re", "pprof_mixed", "pprof_model")` | `fit_logistic_re()` |
| `c("pprof_logistic_cre", "pprof_mixed", "pprof_model")` | `fit_logistic_cre()` |
| `c("pprof_linear_re", "pprof_mixed", "pprof_model")` | `fit_linear_re()` |
| `c("pprof_linear_cre", "pprof_mixed", "pprof_model")` | `fit_linear_cre()` |
| `pprof_data` | the data layer |
| `pprof_provider_effects` | `provider_effects()` |
| `pprof_provider_tests` | `test_providers()` |
| `pprof_measures` | `standardize_providers()` |
| `pprof_profile` | `profile_providers()` |
| `pprof_funnel` | `funnel_limits()` |
| `pprof_coefficient_tests` | `test_coefficients()` |
| `pprof_summary` | `summary.pprof_model()` |
| `pprof_data_check` | `check_data()` |

Every result class also has the common class `pprof_result` (for example `c("pprof_measures", "pprof_result")`), which shared methods such as `tidy()` use (added in Phase 2, DEC-027).

Fields of model and result objects are snake_case nouns. Shared fields use the same names across classes:

| Field | Meaning |
|---|---|
| `call`, `formula`, `terms` | as in base R models |
| `spec` | the model specification: family, method, settings |
| `providers` | provider table: `provider_id`, `provider_value` (the ID as it appears in the data, keeping its type; DEC-028), `n_obs`, `n_events` (binary outcomes), `included`, `no_events`, `all_events` |
| `coefficients` | covariate coefficients, named numeric vector |
| `provider_effects` | provider effects (gamma for FE, alpha for RE), named by provider ID |
| `vcov` | covariance matrix of `coefficients` |
| `provider_effect_variance` | variance of each provider effect |
| `linear_predictor` | covariate linear predictor per included observation (Z beta; X beta including the intercept for RE) |
| `response` | outcome per included observation |
| `provider_index` | integer index into `providers` per included observation |
| `convergence` | `iterations`, `converged`, `criterion`, `stop_rule`, `tol`, `max_iter` |
| `loglik`, `aic`, `bic`, `auc`, `sigma` | fit statistics where defined |
| `n_obs`, `n_providers` | dimensions after screening |
| `package_version` | version of pprof that built the object |

Result tables (the `table` field of result objects, and what `tidy()` returns) use these column names: `provider_id`, `n_obs`, `observed`, `expected`, `estimate`, `std_error`, `statistic`, `p_value`, `lower`, `upper`, `flag`. Tables keyed by something other than the provider use `term` (coefficients), `variable` (data checks), `standardization` and `measure` (measures, one row per provider, standardization, and measure), or `level` and `precision` (funnel limits) (added in Phase 2, DEC-027). Flags are integers -1, 0, 1 with documented meaning (lower than expected, as expected, higher than expected), never factors whose levels depend on the data.

## 6. Conditions

Conditions carry classes so that tests and callers can match them without parsing messages:

| Class | Raised when |
|---|---|
| `pprof_error` | parent class of every pprof error |
| `pprof_error_invalid_input` | an argument fails validation at the API boundary |
| `pprof_error_data` | the data cannot support the requested model (no providers left after screening, no events, singular design) |
| `pprof_error_convergence` | an engine fails in a way the reference also fails (for example a singular information matrix) |
| `pprof_error_unsupported_inference` | a model is asked for inference it does not declare in `inference_capabilities()` |
| `pprof_error_data_required` | a method needs covariates that the object does not keep, and `data` was not supplied |
| `pprof_warning` | parent class of every pprof warning |
| `pprof_warning_not_converged` | the iteration limit was reached |
| `pprof_warning_screening` | providers were excluded by `min_provider_size` |
| `pprof_message` | parent class of every message from the verbosity helper |
| `pprof_deprecated` | a compatibility wrapper was called (warned once per session) |

## 7. C++

| Item | Convention | Example |
|---|---|---|
| Namespace | everything in `pprof`, one sub-namespace per module | `pprof::core`, `pprof::logistic`, `pprof::linear` |
| Types | PascalCase | `InformationBlocks`, `FitResult`, `StopRule` |
| Functions and variables | snake_case | `compute_information_blocks()`, `provider_offsets` |
| Constants | `k` + PascalCase, `constexpr`, each with a comment stating its contract and the reference location | `kFitWeightFloor = 1e-20`, `kArmijoSufficientDecrease = 0.01` |
| Files | snake_case, named after their main content; `.h` for headers | `src/core/information_blocks.h`, `src/logistic/serbin.cpp` |
| Rcpp adapters | top-level `src/` files named `rcpp_<module>.cpp`; exported functions named `cpp_<module>_<action>` and never exported from the R package | `src/rcpp_logistic.cpp`, `cpp_logistic_fe_serbin()` |

## 8. Files

| Area | Pattern | Examples |
|---|---|---|
| R source | `R/<layer>-<topic>.R` | `R/data-formula.R`, `R/model-logistic-fe.R`, `R/inference-provider-tests.R`, `R/profile-standardize.R`, `R/plot-funnel.R`, `R/compat-logis-fe.R` |
| Tests | `tests/testthat/test-<layer>-<topic>.R`, mirroring `R/` | `test-model-logistic-fe.R` |
| Reference tests | `tests/testthat/test-reference-<function>.R` | `test-reference-logis-fe.R` |
| Helpers | `tests/testthat/helper-<topic>.R` | `helper-tolerances.R`, `helper-fixtures.R` |
| Fixtures | `tests/testthat/fixtures/reference/<case-id>.rds` and `manifest.json` | `logis_fe-serbin-default-binary.rds` |
| C++ core | `src/<module>/<topic>.{h,cpp}` | `src/core/line_search.h` |

## 9. Checklist for a new name

1. Is it in the vocabulary table? Use that name.
2. Does it contain an abbreviation outside §2? Spell it out.
3. Does it collide with a base, stats, utils, or common package function, or shadow one as an argument? Rename.
4. Is it a verb for an action and a noun for an object?
5. Does the same concept have the same name in R, C++, result columns, and documentation?
