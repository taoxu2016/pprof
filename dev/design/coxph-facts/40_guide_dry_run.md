# Fact 40: a dry run of the developer documentation

> The CoxPH C6 plan's §3.5, as DEC-063's dry run was for the rewrite: on 2026-10-16 a subagent without the session's context read `dev/DEVELOPER_GUIDE.md`, `vignettes/adding-a-model.Rmd`, and ARCHITECTURE §E, as drafted for the plan's commit 11, and designed two models of the CoxPH brief's §2.2 from them. Its report follows unchanged but for its title, made a second-level heading, and the local path of the repository, from the next heading to "What changed in response", which lists the fixes made to the three documents in the same commit. The report's section numbers, file references, and line contents describe the drafts it read.

## Dry run of the developer documentation: designing two later models

Date: 2026-10-16. Repository: the working tree of branch `coxph/phase-6`, read only.

**Method.** I first read three documents in full:

- `dev/DEVELOPER_GUIDE.md` ("the guide");
- `vignettes/adding-a-model.Rmd` ("the vignette");
- `dev/design/ARCHITECTURE.md` §E.1 to §E.7 ("ARCH").

Then I designed both models. I opened another file only when a design question had no answer in the three documents, and §3 records each opening.

**What was not done or verified.** I ran no R, no build, and no test, and I changed no file in the repository. Nothing below is verified by execution. What I say about coxme and survival's `frailty()` comes from their documentation as I know it, and it must be checked against the versions that would be pinned. The tool environment also displayed `.claude/rules/r-code.md` automatically when I opened R files. The three documents don't point to it, and I did not rely on it.

Files opened beyond the three documents, in order:

| # | File | The question that sent me there |
|---|---|---|
| 1 | `dev/NAMING.md` (in full) | names, the argument vocabulary, fields, classes, conditions (the guide's "Changing code" and the vignette's "Registering the methods" point to it) |
| 2 | `R/model-mixed.R` (in full) | "the lme4 adapter and `R/model-mixed.R` as the pattern" (the guide's "The later models") |
| 3 | `R/model-survival.R` (in full) | "the survival adapter for the Cox inputs" (same row) |
| 4 | `R/model-cox-stratified.R` (in full) | the Cox family specification's literal values, fields, and methods (ARCH §E.6) |
| 5 | `R/model-cox-measures.R` (in full) | `cox_expected_events()`, named by the table |
| 6 | `R/model-class.R` (in full) | what `new_pprof_model()` fills; `class` against `subclass` |
| 7 | `R/data-prepare.R` (in full) | `data_prepare()`'s arguments and its coding of factors (the vignette's "Further reading": `?data_prepare`) |
| 8 | `R/data-survival.R` (in full) | the table's starting point for the discrete-time model |
| 9 | `R/model-logistic-fe.R` (in full) | `fit_logistic_fe()`, the table's starting point |
| 10 | `R/model-glmnet.R` (grep) | `glmnet_require()` (the guide's rule 8) |
| 11 | `tests/testthat/helper-tolerances.R` (grep) | the `cox_engine` tier (rule 10) |
| 12 | `.claude/rules/tests.md` (in full) | the test rules the guide cites in "The rule that comes first" |
| 13 | `tests/testthat/test-architecture.R` (grep) | how a new file gets its layer |
| 14 | `R/present-tidy.R` (lines 1 to 165); greps of `R/present-*.R`, `plot-*.R`, `profile-*.R`, `inference-*.R`, and of `R/` for the `effect` field | where the Cox models' standard methods live; whether the profiling layer branches on `family` or reads `effect` |
| 15 | `R/profile-standardize.R` (lines 170 to 229) | the hooks of direct standardization |
| 16 | `R/profile-tests.R` (grep, lines 160 to 184) | what the Poisson tests read |
| 17 | `dev/DECISIONS.md` (DEC-105) | the threshold of the performance rule (rule 11) |
| 18 | `dev/coxph_brief.md` (grep) | what §2.2 says about these two models |
| 19 | `_pkgdown.yml` (grep) | whether new exports must be listed |

Every value below marked *proposed* is a placeholder for a decision that §5 leaves to the methodology owners. It is not a decision.

---

## 1. Design A: frailty Cox profiling

### A.0 Status

The guide's "The later models" says each later model "needs a methodology sign-off and a reference before it is built". This design is the plan that a brief would approve, with §5's questions still open.

### A.1 Interface

```r
fit_cox_re(formula, data, provider, weights = NULL, ties = "breslow", max_iter = 20, tol = 1e-8,
           keep_data = FALSE, verbose = FALSE)
```

- **Name.** `fit_cox_re()` follows NAMING §3.1's `fit_<outcome>_<effects>()` with the whitelisted `re`, as `fit_logistic_re()` does. The class is `c("pprof_cox_re", "pprof_model")`. The alternative is `fit_cox_frailty()`, the domain's word, which matches how the Cox fits name themselves (`fit_cox_stratified()`). The documents don't decide between them (§4, item 17).
- **`formula`.** `Surv(time, status) ~ terms`, or `Surv(start, stop, status) ~ terms` if coxme accepts counting-process data (to be checked), with `offset()` terms if coxme supports offsets. The formula has no provider and no `strata()`, `cluster()`, or `frailty()` terms; `data_prepare()` refuses them (`R/data-survival.R`).
- **`provider`.** The grouping factor of the random intercept. The adapter adds it as `(1 | .provider)`.
- **`weights`.** Case weights, from the Cox vocabulary (NAMING §10).
- **Arguments left out:**
  - `cluster` and `robust`: as far as its documentation goes, coxme gives no robust variance (to be confirmed).
  - `min_provider_size`: random-effect and Cox models screen no provider (K-07 in `R/model-mixed.R`; ARCH §E.6).
  - A `...` pass-through to the engine, which the lme4 fits have (NAMING §4): the guide's rule 4 forbids leaving settings to the engine (§4, item 4).
- **`ties`, `max_iter`, `tol`.** Cox vocabulary (NAMING §10), mapped to coxme's `ties` and to `coxme.control(iter.max, eps)`. The defaults are *proposed* from the Cox family (`"breslow"`, 20) and from coxme's documented `eps`. With no reference they are open (§5, A10). coxme's own default ties are Efron's, so the default must be passed explicitly whatever it is.
- **Order.** Data arguments, then model settings, then computational settings (NAMING §4).

### A.2 Data preparation

The fit prepares its data as the stratified Cox model does, without `cluster`:

```r
data_prepare(formula, data, provider, event_counts = TRUE, response_type = "survival",
             weights = weights, allow_offset = TRUE)
```

Nothing new is needed in the data layer. The call gives the status as `response`, the times as `start` (0 for right-censored data) and `stop`, `weights`, `offset`, `settings$survival_type`, and the provider table with `n_events` and `person_time`. It screens no provider.

After the call, the fit makes the stratified model's checks:

- finite covariates;
- at least one event among the rows with positive weight (`abort_data()`);
- *proposed*: at least two providers with fitted rows, without which the frailty variance cannot be estimated (`pprof_error_data`).

`?data_prepare` says the survival special terms are refused "since the provider is the strata". For this model the provider is not the strata, but the refusal still fits. Stratifying the baseline by another variable would need a data-layer change, which is out of scope here.

### A.3 The adapter

**Engine.** The choice is open (§5, A1): coxme, with a Gaussian log-frailty, or survival's `coxph()` with a `frailty()` term. This design uses coxme. With `frailty()`, the same functions would be `survival_frailty_*()` in the existing `R/model-survival.R`; rule 1 allows one adapter per engine.

**File.** The adapter is a new file, `R/model-coxme.R`. Its functions are named `coxme_*()`, and `coxme` must join NAMING §2's whitelist as lme4 and glmnet did (§4, item 16).

| Function | Role, and the existing function it follows |
|---|---|
| `coxme_minimum_version`, `coxme_available()`, `coxme_require()` | the suggested engine's check, as `glmnet_require()` does it: `pprof_error_invalid_input` with `package = "coxme"` (rule 8, DEC-088) |
| `coxme_frame(prepared, rows)` | the engine's data frame, built from the prepared vectors under generated names, as `survival_engine_fit()` builds one (details below) |
| `coxme_control(max_iter, tol)` | `coxme::coxme.control()` with every argument given |
| `coxme_fit(prepared, ties, max_iter, tol)` | the call, the classification of conditions, and the extraction of results |
| `coxme_convergence(fit, control)` | convergence read from the result, as `lme4_convergence()` reads it |
| `coxme_abort(e)` | `abort_convergence(..., engine_message = conditionMessage(e))`, as `survival_abort()` does |
| `coxme_engine_fit(model, data)` | the coxme object for methods that need it: `model$engine_fit` with `keep_data = TRUE`; otherwise rebuilt from `data` through `model_prepared_data()` and checked to reproduce the coefficients (`cox_stratified_engine_fit()`) |

`coxme_frame()` builds these columns:

- `.start`, `.stop`, `.status`;
- `.provider = prepared$provider_index[rows]`, integer codes, so that coxme's levels are pprof's provider order by construction;
- `.weight`, `.offset`;
- `.x1` to `.xp`, from `survival_engine_columns()`.

The formula is `Surv(.stop, .status) ~ .x1 + ... + (1 | .provider)`, plus `offset(.offset)` when there is one. It lives in an environment that holds the frame, as in `survival_engine_fit()`.

The other pattern is lme4's: the user's own columns (`mixed_lme4_data()`) with the engine's own design matrix. The documents don't choose between the two (§3, gap 9).

**The guide's rules, as this adapter would follow them:**

1. **One adapter per engine.** Every coxme call is in `R/model-coxme.R`, including the extractors `fixef()`, `ranef()`, `VarCorr()`, and `vcov()`, as `mixed_estimate()` holds lme4's. The model file calls only the adapter.
2. **Call the user-level function.** The adapter calls `coxme::coxme()` itself. Calling coxme's internal fitter would need a benchmark (DEC-091).
3. **Take what the user-level function adds from the engine.** From coxme: the fixed effects and their covariance, the predicted random effects, the variance θ̂, the log-likelihoods, the iterations, and the variances of the predicted effects as coxme documents them (which variance to use is §5, A6).
   coxme returns no baseline hazard, survival curves, or martingale residuals (to be confirmed). The documents don't settle where these come from (gap 6). There are two options:
   - (i) Compose them from survival's documented routine: survival's fitter, called as `coxph()` calls it, without covariates and with the full linear predictor x'β̂ + b̂ (+ offset) as offset. Its martingale residuals give each observation's expected events under the fitted model (status minus residual), and the expected events at b = 0 are those times exp(−b̂_i). This is `survival_partial_loglik()`'s pattern, as one new `survival_*()` function in `R/model-survival.R`.
   - (ii) Use `cox_expected_events(eta, start, stop, status)` from `R/model-cox-measures.R`, which is package code.
4. **Make every setting explicit.**
   - `ties`.
   - Every argument of `coxme.control()` that the pinned version has and that can change a number: as I know them, `eps`, `iter.max`, `toler.chol`, `inner.iter`, `sparse.calc`, `optpar` (the outer optimizer and its `reltol`), `refine.df`, `refine.detail`, `refine.method`, `sparse`, `varinit`, and `corinit`.
   - `refine.n = 0`. A positive value draws random numbers, which would make the fit nondeterministic (Class A) and would need a seed the package may not set.
   - `vfixed` and `vinit` left out on purpose.
   - Times: check whether coxme merges near-tied times, as `coxph(timefix = TRUE)` does, and whether that can be turned off. The Cox models compare times exactly (M-23).
5. **Classify what the engine says.**
   - coxme's errors become `pprof_error_convergence`, with coxme's message in `engine_message`.
   - Its iteration-limit warning is muffled and replaced by one `pprof_warning_not_converged` from the fit, as `cox_stratified_report()` does.
   - Other warnings pass through. coxme's messages are kept and shown only with `verbose`.
   - Whether the fit converged is read from the result (the iterations against `iter.max`, and the outer optimizer's code), not from warnings.
6. **Check what the engine does not.**
   - Fewer than two providers, and no events (`pprof_error_data`).
   - Weights of 0: the Cox models' M-25 rule leaves those rows out of the fit and keeps them in the provider table. Whether it applies here is open (§4, item 15).
   - Covariates that are not finite.
   - Aliased covariates: `coxph()` returns NA for them, but coxme may not. Check, and raise `pprof_error_data` as `survival_fit()` does.
   - Any coxme defect that the package works around gets a test that fails when the engine changes.
   - "Inputs ... the reference refuses" is undefined, because no reference is named (gap 19).
7. **Keep only what the methods need.** The object keeps the coxme object as `engine_fit` only with `keep_data = TRUE`.
8. **Suggest the engine.** coxme goes in Suggests. `coxme_require()` runs at the top of `fit_cox_re()` and of every method that calls the adapter. Tests and examples skip without coxme.
9. **Pin the versions.** DESCRIPTION gets `Suggests: coxme (>= x.y-z)`. The adapter's header names the coxme version whose source it follows. Fixture manifests record coxme, bdsmatrix, Matrix, and survival.
10. **Test against the engine, bitwise.** See A.8.
11. **Benchmark against the engine.** A paired benchmark in `dev/bench/cox/` compares the fit with `coxme()` plus the preparation of its inputs. DEC-105 reads the rule this way: a fit fails only if, in every round, its median and fastest runs are more than 10% above that sum, with its median at least 0.05 s above.

### A.4 The model object

The constructor `new_pprof_cox_re(prepared, estimates, spec, expected_events, call, keep_data, engine_fit)` calls `new_pprof_model()` with:

- `coefficients`: β̂, named by the design's columns;
- `vcov`: coxme's covariance of β̂, with dimnames;
- `provider_effects`: b̂, named by provider ID, in provider order;
- `linear_predictor`: x'β̂ without the offset, as the stratified Cox model stores it;
- `provider_effect_variance`: the variance of each predicted effect (which one is §5, A6). The RE families store a standard deviation in `provider_effect_sd` instead.
- `convergence`: a list of `iterations`, `converged`, `stop_rule`, `tol`, and `max_iter`, plus engine fields in the manner of lme4's (`optimizer`, `code`, `messages`, `engine_messages`);
- `spec`: `family = "cox_re"`, `engine = "coxme"`, `ties`, `weights`, `max_iter`, `tol`, `keep_data`, and every engine setting that `coxme_engine_fit()` needs to rebuild the engine object (DEC-005);
- `class = "pprof_cox_re"`.

The class cannot be `pprof_mixed`. That class's validator requires a family listed in `mixed_families` and an lme4 `engine_fit`, and NAMING §5 allows at most one intermediate class.

`new_pprof_model()` fills the shared fields: `call`, `formula`, `terms`, `data_spec`, `spec`, `providers`, `coefficients`, `vcov`, `provider_effects`, `provider_effect_variance`, `response` (the status), `linear_predictor`, `provider_index`, `row_index`, `convergence`, `n_obs`, `n_providers`, `n_excluded_providers`, `n_excluded_obs`, `package_version`, and `data` (with `keep_data = TRUE`).

The model's own fields reuse names from NAMING §5 and §10:

- `start`, `stop`, `weights`, `offset`;
- `expected_events`: each observation's expected events at b = 0 (A.3, rule 3);
- `fitted`: each observation's expected events with its provider's predicted effect, which `predicted_outcome()` returns if the numerator is "predicted";
- `martingale_residuals`;
- `variance_components = list(provider = θ̂, residual_sd = NULL)`, as for RE;
- `loglik`, `loglik_df`, `aic`, `bic` (which log-likelihood is §5, A8);
- `n_events`, `n_zero_weight`;
- `engine_fit`, with `keep_data = TRUE` only.

The validator, `validate_pprof_cox_re()`, calls `validate_pprof_model()` and then checks:

- the family;
- that the per-observation vectors have one value per observation;
- that `expected_events` has no negative value;
- that `engine_fit` inherits from `coxme`.

### A.5 Contract methods and standard methods

| Generic | Implementation |
|---|---|
| `provider_table`, `provider_estimates`, `provider_index`, `linear_predictor`, `observed_outcome` | the shared methods |
| `inference_capabilities` | A.7 |
| `expected_outcome(model, effect)` | `exp(model_observation_effects(model, effect)) * model$expected_events`, the stratified model's method (ARCH §E.6) |
| `null_effect(model, null)` | a single finite number, 0 by default, as for `pprof_mixed` and `pprof_cox_stratified` (*proposed*; §5, A5) |
| `profile_spec` | A.6 |
| `predicted_outcome` | `model$fitted`, needed only if `indirect_numerator = "predicted"` |
| `provider_estimate_se` | `sqrt(model$provider_effect_variance)`, needed only if Wald inference is declared |
| `provider_test`, `refit_without` | not implemented: `provider_score_standard`, `coef_lr`, and `coef_score` are not declared |

The standard methods follow the Cox models' set (NAMING §10):

- `nobs()`: the number of events.
- `logLik()`.
- `residuals(type = "martingale")`; score and dfbeta residuals only if coxme provides them.
- `predict(type = "linear_predictor" | "risk")`. Whether the prediction includes b̂ is a decision to record: RE's `predict()` includes the provider effect, and the stratified Cox model has none.
- `print()`, `glance()` (adding `n_events`), and `augment()` (`observed` the status, `fitted` the expected events, `residual` the martingale residual). The Cox precedent puts these in `R/present-print.R` and `R/present-tidy.R` (gap 11).
- A `baseline_hazard()` method, only if a baseline is composed.

### A.6 Family specification

| Field | *Proposed* value | Basis | Status |
|---|---|---|---|
| `family` | `"cox_re"` | NAMING §3.1 | a naming decision |
| `effect` | `"alpha"`, as RE, or a description such as "log frailty: the log ratio of the provider's hazard to that of the average provider" | the vignette's table: RE `"alpha"`, Cox a description. `R/profile-spec.R` requires the field (`profile_spec_fields`), but no code reads it (grep of `R/`, file 14). | a label |
| `null_default` | `0` | RE and Cox | open (§5, A5) |
| `null_options` | `character()` | RE and Cox (files 2, 4) | follows `null_default` |
| `indirect_numerator` | `"observed"` (variant O) or `"predicted"` (variant P) | the guide's table: a methodological question | open (§5, A2) |
| `measures` | `"ratio"` | Cox | open (§5, A3) |
| `test_default` | `"midp"` (O) or `"wald"` (P) | Cox; RE | depends on A2 and A6 |
| `comparison` | `"ratio"` | Cox | |
| `count_distribution` | `"poisson"` in variant O only | Cox | never with `"predicted"` (gap 7) |
| `variance_function` | `function(expected) expected` (O); none (P, as RE) | Cox; RE | |
| `mean_function` | none | Cox, whose direct standardization has no intervals | |
| `direct_expected`, `direct_by_provider` | `direct_expected = function(effects, linear_predictor, threads) exp(effects) * sum(model$expected_events)`, a closure built in `profile_spec(model)`; or `direct_by_provider` | gap 8 | open (technical, and §5, A3) |
| `direct_reference` | `"observed"` | RE and Cox | |
| `direct_limits` | left at the default; without `mean_function` there are no direct intervals | Cox | |
| `one_sided_extremes` | `FALSE` | RE and Cox | |
| `funnel` | O: `list(measure = "ratio", target = 1, test = "midp", precision = function(expected, variance) expected)`; P: none, as RE | Cox; RE | open (§5, A6) |
| `wald` | `list(test = "normal", interval = "normal", df = NULL)` | RE | if Wald inference is declared |
| `coefficient_wald` | Cox's `list(p_value = "two_sided_upper", p_value_distribution = "normal", interval = "critical", interval_distribution = "normal", df = NULL)`; or logistic RE's `"upper_doubled"`/`"quantile"` (D-31, awaiting sign-off); or the default, two-sided | files 2 and 4; NAMING §5 | open (§5, A7) |
| `wald_caution` | `FALSE` | RE and Cox | |

### A.7 Capabilities

Two coherent sets, depending on §5's A2 and A6:

- **Variant O.** Observed numerator and Poisson counts: the stratified model's column of ARCH §E.3, plus Wald inference on the predicted effects if that is accepted. The capabilities are `coef_wald`, `provider_exact`, `provider_midp`, `interval_exact`, `interval_midp`, `standardize_indirect`, `standardize_direct`, and `funnel`, with `provider_wald` and `interval_wald` optional.
- **Variant P.** Predicted numerator, as the RE families have it: `coef_wald`, `provider_wald`, `interval_wald`, `standardize_indirect`, and `standardize_direct`.

Neither variant declares `coef_lr`, `coef_score` (no `refit_without()`), `provider_score`, `provider_score_standard`, `provider_bootstrap`, or `interval_score` (these are for binary outcomes).

### A.8 Tests

Files: `tests/testthat/test-model-cox-re.R` for the model and `tests/testthat/test-model-coxme.R` for the adapter. Every test runs `skip_if_not_installed("coxme", minimum_version = ...)`.

- **Engine identity** (rule 10), with `expect_identical()` or the `cox_engine` tier (atol = rtol = 0):
  - `fit_cox_re()` against `coxme::coxme()` called directly on the adapter's frame, with the same settings. Compare the fixed effects, `vcov`, the random effects, θ̂, the log-likelihoods, and the iterations.
  - The same comparison on the user's data frame sorted by provider, as the vignette's `glm()` check does.
  - Variants: with weights, with an offset, with Efron ties, and with counting-process data if coxme supports it.
- **Composition identity** (if option (i) of A.3 is chosen): the expected events and martingale residuals against survival's `coxph()` with the same offset and `timefix = FALSE`, bitwise.
- **Independent implementation** (*proposed*): with the variance fixed, `coxme(vfixed = θ)` against `coxph(... + frailty(provider, distribution = "gaussian", theta = θ))`. Both should maximize the same penalized partial likelihood, so they should agree within the optimizers' tolerances, with a tolerance justified by measurement (tests.md, tier 2).
- **Contract:**
  - `validate_pprof_model()` passes;
  - for the declared capabilities, `test_providers()`, `standardize_providers()`, `provider_effects()`, `profile_providers()`, and `plot_caterpillar()` run;
  - undeclared inference raises `pprof_error_unsupported_inference`: `test = "score"`, `test_coefficients(test = "lr")`, and `funnel_limits()` in variant P.
- **Conditions:**
  - coxme absent (`local_mocked_bindings(coxme_available = function() FALSE)`) raises `pprof_error_invalid_input`;
  - an engine error raises `pprof_error_convergence` with `engine_message`;
  - reaching the iteration limit gives exactly one `pprof_warning_not_converged`;
  - one provider, or no events, raises `pprof_error_data`;
  - a `data` that is not the fit's raises `pprof_error_invalid_input`;
  - a method that needs data, on a model without it, raises `pprof_error_data_required`.
- **Determinism:** two fits are identical (with `refine.n = 0`).
- **Edge cases:**
  - providers with no events;
  - a single provider;
  - missing values, and small providers;
  - weights of 0;
  - a formula without covariates (`Surv(...) ~ 1`), if coxme accepts one;
  - offsets, and near-tied times.
- **Sentinels:** a test for each coxme defect worked around (rule 6).
- **Reference comparison:** once a brief names a reference, fixtures from a committed generator in `dev/reference/`, with a manifest recording coxme, bdsmatrix, Matrix, and survival; a calibrated tier; and a row in the simulation study (`validation/run-simulation.R` covers "every family").
- **Package checks:** R CMD check, lintr, the architecture test, strict partial matching (tests.md), and at most two threads.

### A.9 Files

- **New:** `R/model-cox-re.R` (the fit, constructor, validator, contract methods, and standard methods); `R/model-coxme.R` (the adapter); the two test files; a paired benchmark in `dev/bench/cox/`; and, once a reference exists, its generator in `dev/reference/`.
- **Changed:**
  - `R/model-survival.R`: one `survival_*()` function, if the baseline is composed;
  - `R/present-print.R` and `R/present-tidy.R`: `print()`, `glance()`, and `augment()` (§4, item 3);
  - `DESCRIPTION` (Suggests);
  - `_pkgdown.yml` (`fit_cox_re`, `cox_re_methods`);
  - `NEWS.md`;
  - `dev/NAMING.md`: the fit, the class, coxme in §2, the new fields;
  - `dev/DECISIONS.md`, `dev/DISCREPANCIES.md`, `dev/CONVENTIONS.md`, `dev/OPEN_QUESTIONS.md`;
  - ARCH §E.3's capability table and §E.7's adapter list;
  - the guide's "Delegated engines" and "The later models";
  - the user's time-to-event vignette;
  - possibly `tests/testthat/helper-tolerances.R`, if a new tier is added.
- **Generated:** `NAMESPACE` and `man/`.

---

## 2. Design B: discrete-time provider models

### B.0 Status

As for A, the model needs a brief, a sign-off, and a reference. The table says "what counts as an observation in the provider table and the measures is a methodological question", and that question shapes most of what follows.

### B.1 Interface

```r
fit_discrete_time_fe(formula, data, provider, breaks = NULL, method = "serbin", max_iter = 10000,
                     tol = 1e-5, stop_rule = "any", backtrack = TRUE, effect_bound = 10,
                     min_provider_size = 10, keep_data = FALSE, threads = 1, verbose = FALSE)
```

- **Name.** `fit_discrete_time_fe()` follows NAMING §3.1, with the outcome a time in discrete periods and fixed effects. The class is `c("pprof_discrete_time_fe", "pprof_logistic_fe", "pprof_model")`, with `pprof_logistic_fe` as the one intermediate class, as for Firth.
  The documents admit two other designs:
  - an option of `fit_logistic_fe()`, which would change an existing file;
  - an exported expansion function, which users would follow with `fit_logistic_fe()` themselves.
  See §4, item 7.
- **`formula`.** `Surv(time, status) ~ terms` or `Surv(start, stop, status) ~ terms`. There are no offsets and no `weights` or `cluster` arguments, because the logistic FE engine has none.
- **`breaks`.** A new vocabulary item (NAMING §9's checklist): increasing finite period boundaries, the first at or below the smallest entry time. *Proposed*: `NULL` means integer-valued times are the periods. The default and its conventions are open (§5, B2).
- **The rest.** `fit_logistic_fe()`'s arguments, in its order and with its defaults (NAMING §4: sibling functions share names, order, and defaults). The unit and default of `min_provider_size` are open (§5, B1).

### B.2 Data preparation: one new data-layer function

The guide's table puts "an expansion of survival data into one row per person and period" in the data layer, before `data_prepare()`. The new function is

```r
data_expand_person_period(formula, data, provider, breaks = NULL)
```

in a new `R/data-person-period.R`. It could instead be added to `R/data-survival.R`, but a new file keeps the existing data layer unchanged. It returns `list(formula, data, breaks, n_subjects, settings)`. Its steps:

1. Read and check the `Surv()` response with `R/data-survival.R`'s helpers: `data_check_survival_terms()`, `data_survival_response()`, `data_check_survival_values()`, and `data_without_surv_warnings()`. Drop the incomplete rows exactly as `data_prepare()` would, so that both agree on which input rows exist.
2. Expand each input row with interval (start, stop] into one row per period k, where b[k−1] < stop and b[k] > start (the convention is open, §5, B2):
   - `.event` is the status in the row's last period and 0 elsewhere;
   - `.period` is a factor with only the periods that occur, because `data_prepare()` keeps unused levels, which would give all-zero columns;
   - `.row` is the input row;
   - the covariate and provider columns are copied.
3. Rewrite the formula as `.event ~ .period + <the input formula's right-hand side>`, in the input formula's environment. The design matrix codes `.period` with its first level dropped, because `data_prepare(intercept = FALSE)` drops the intercept column of `model.matrix()` (file 7). The provider effects then absorb the first period.
4. Refuse:
   - generated names that collide with columns of `data` (`pprof_error_invalid_input`);
   - `offset()` terms;
   - *proposed*: periods without events, raising `pprof_error_data` that names them. Otherwise SerBIN would diverge, because `effect_bound` clamps provider effects but not coefficients (file 9; §5, B3).

Then the fit calls `data_prepare(expanded$formula, expanded$data, provider, min_provider_size = min_provider_size, event_counts = TRUE)`, unchanged. Its provider table counts person-periods as `n_obs`, and events as `n_events`. *Proposed*: the model adds an `n_subjects` column to the provider table, as the Fine–Gray model adds `n_competing` (NAMING §10, Phase C5).

### B.3 Estimation: the logistic FE engine, not a delegated one

The fit calls the logistic FE internals as Firth does:

1. `logistic_fe_check_data()`, which also requires at least one covariate (true whenever there are two or more periods);
2. `logistic_fe_report_screening()` and `logistic_fe_check_rank()`;
3. `logistic_fe_estimate(prepared, spec, threads)` and `logistic_fe_report_convergence()`;
4. `logistic_fe_model(prepared, estimates, spec, call, keep_data, class = c("pprof_discrete_time_fe", "pprof_logistic_fe"), ...)`.

`spec` holds the logistic FE settings with `family = "discrete_time_fe"`, plus `breaks` and the user's survival formula.

The guide's eleven rules for delegated engines apply only by analogy. The "engine identity" is with `fit_logistic_fe()` on the expanded frame, and the expansion's reference is survival's `survSplit()` (B.8).

### B.4 The model object

The shared fields are those of A.4, with two differences:

- `row_index` gives rows of the expanded frame, because that is what `data_prepare()` saw.
- `formula` is the expanded binary formula, because `new_pprof_model()` fills it from the prepared data and refuses it in `...`.

Both conflict with what the shared fields mean (gap 12).

The model also has the logistic FE fields: `loglik`, `aic`, `bic`, `auc`, `provider_effect_variance`, and `convergence` with its history. Its own fields are:

- `input_row`: each person-period's row in the input data;
- `period`: each person-period's period;
- `breaks`;
- `n_subjects`, `n_events`;
- `survival_formula`: the user's formula.

The validator, `validate_pprof_discrete_time_fe()`, calls `validate_pprof_logistic_fe(x, family = "discrete_time_fe")` (Firth's pattern) and then checks the model's own fields.

### B.5 Contract methods and standard methods

- **Inherited from `pprof_logistic_fe`:** `expected_outcome()`, `null_effect()`, `provider_estimate_se()`, `logLik()`, and, per person-period, `fitted()` and `residuals()`.
- **Overridden:**
  - `profile_spec()`: `NextMethod()` with `family` replaced, because the inherited method hard-codes `"logistic_fe"`;
  - `inference_capabilities()`: stated explicitly, so that the decision is recorded for this class (B.7);
  - `refit_without(model, covariates, data)` and `provider_test()` (the standard score test): without kept data, re-expand `data` with `spec$breaks` and the survival formula, check that the expansion matches the stored rows, then use the logistic FE code. Otherwise `model_prepared_data()` would call `data_prepare()` on the user's survival data with the binary formula and fail;
  - `predict()`: *proposed*: `newdata = NULL` only, until the meaning of new data (person-periods or subjects with a horizon) is decided;
  - `augment()`: *proposed*: raise `pprof_error_unsupported_inference`, as the Fine–Gray model does for expanded rows (D-81), unless one row per subject is wanted;
  - `glance()`: adds `n_subjects` and `n_events`;
  - `print()`: shows the periods and the subjects.
- **`nobs()`:** the number of person-periods, as logistic FE; open (§5, B1).

### B.6 Family specification

The values are logistic FE's (`profile_spec.pprof_logistic_fe`), with the family replaced:

| Field | Value | Status |
|---|---|---|
| `family` | `"discrete_time_fe"` | needs the override (B.5) |
| `effect` | `"gamma"` | |
| `null_default`, `null_options` | `"median"`, `"median"` | open (§5, B7) |
| `indirect_numerator` | `"observed"` (the events) | |
| `measures` | `c("ratio", "rate")` | the meaning of the rate is open (§5, B5) |
| `test_default` | `"exact"` | open (§5, B6) |
| `comparison` | `"ratio"` | |
| `mean_function` | `stats::plogis` | |
| `variance_function` | `function(mean) mean * (1 - mean)` | |
| `direct_expected` | `logistic_direct_expected`, summed over person-periods | §5, B5 |
| `direct_reference`, `direct_limits` | `"observed"`, `"mean_function"` | |
| `one_sided_extremes` | `TRUE` | |
| `count_distribution` | the default, `"poisson_binomial"` | |
| `funnel` | `list(measure = "ratio", target = 1, floor = 0, test = "score", precision = function(expected, variance) expected^2 / variance, half_width = function(critical, precision) critical * sqrt(1 / precision))` | §5, B6 |
| `wald` | `list(test = "normal", interval = "normal", df = NULL)` | |
| `coefficient_wald` | `list(p_value = "two_sided", p_value_distribution = "normal", interval = "critical", interval_distribution = "normal", df = NULL)` | |
| `wald_caution` | `TRUE` | |

### B.7 Capabilities

The candidates are logistic FE's fourteen: `coef_wald`, `coef_lr`, `coef_score`, `provider_exact`, `provider_bootstrap`, `provider_score`, `provider_score_standard`, `provider_wald`, `interval_exact`, `interval_score`, `interval_wald`, `standardize_indirect`, `standardize_direct`, and `funnel`.

Each needs the owners' confirmation, because person-periods are not independent subjects. The ones most in doubt:

- `provider_exact` and `provider_bootstrap`: they treat person-periods as fixed Bernoulli trials.
- `coef_lr` and `coef_score`: they refit at pprof 1.0.3's defaults (D-10).

The vignette's "Declare only what the model supports and what its authors have checked" applies.

### B.8 Tests

Files: `tests/testthat/test-data-person-period.R` and `tests/testthat/test-model-discrete-time-fe.R`.

- **The expansion:**
  - against `survival::survSplit()` at the same cut points: the same rows, intervals, and event indicators (tier 0);
  - small cases computed by hand;
  - times exactly at a break, late entry, counting-process input, and incomplete rows;
  - name collisions, periods without events, and times beyond the last break.
- **Identity:** `fit_discrete_time_fe()` against `fit_logistic_fe(.event ~ .period + x, expanded, provider)`, with `expect_identical()` on the coefficients, effects, variances, log-likelihood, and convergence history.
- **Independent implementation:** `glm(.event ~ 0 + provider + .period + x, family = binomial)` within a tolerance justified by measurement (tests.md, tier 2).
- **Contract:** `validate_pprof_model()` passes; the profiling functions run; any withheld capability raises `pprof_error_unsupported_inference`.
- **Metamorphic:**
  - permuting the input rows;
  - splitting (0, T] into (0, a] and (a, T] as counting-process rows;
  - scaling the times and the breaks by a constant;
  - relabeling the providers.
- **Edge cases:**
  - providers with no events (effects at the bound, with the Wald caution);
  - a single provider;
  - missing values;
  - small providers, screened on person-periods;
  - one period only.
- **Methods that take `data`:** `refit_without()` and the standard score test, with `keep_data = FALSE` and the input data passed.
- **Existing families unchanged:** check `data_prepare()` against §E.6's snapshot (`validation/fixtures/data-prepare-snapshot.rds`) if any existing data-layer file changes. I did not look up which test or script compares it.
- **Package checks:** R CMD check, lintr, the architecture test, strict partial matching, and at most two threads.

### B.9 Files

- **New:** `R/data-person-period.R`, `R/model-discrete-time-fe.R`, and the two test files.
- **Changed:**
  - `R/present-print.R` and `R/present-tidy.R`: `print()`, `glance()`, and `augment()` (§4, item 3);
  - `_pkgdown.yml`;
  - `NEWS.md`;
  - `dev/NAMING.md`: the fit, the class, `breaks`, and the fields;
  - `dev/DECISIONS.md` and `dev/OPEN_QUESTIONS.md`;
  - ARCH §E.3's table, and the guide's "The later models".
- **Generated:** `NAMESPACE` and `man/`.

No change to `R/model-logistic-fe.R` is needed if the subclass overrides `profile_spec()`.

---

## 3. Gaps in the documents

There are 19 gaps: 3 blocking (6, 12, 19) and 16 minor.

1. **Names** (minor).
   - *Needed:* the fit's name, the class, the arguments and their order, the fields, and the adapter's function names.
   - *Looked:* the guide's "Changing code" (points to NAMING); the vignette's "Registering the methods" (`pprof_<name>`, `R/model-<name>.R`); the walk-through's step 1 (an example interface); the guide's rule 1 (adapter names after the engine, NAMING §2).
   - *Opened:* `dev/NAMING.md`. It answered almost everything: the patterns and vocabulary (§3.1, §4), the fields (§5, §10), the conditions (§6), the Cox vocabulary (§10), and the types that `predict()` and `residuals()` take for Cox models.
   - *Not settled:* the frailty fit's name (§4, item 17); that a new engine's name must join §2's whitelist (item 16); and how `breaks` passes §9's checklist.
2. **`data_prepare()`'s interface** (minor).
   - *Needed:* its whole signature; the names of the survival fields in its result; how it codes a factor without an intercept (the period factor of B); what it refuses.
   - *Looked:* the vignette's toy fit (`min_provider_size`, `event_counts`); ARCH §E.6, "The data layer" (`response_type`, `weights`, `cluster`, `allow_offset`).
   - *Found:* no mention of `intercept` (which the RE fits pass as `TRUE`) or `within_between`, no defaults, and no coding of factors. The walk-through prints `colnames(design)`, but its output is not in the source.
   - *Opened:* `R/data-prepare.R` (`?data_prepare`) and `R/data-survival.R`. They showed:
     - the intercept column is dropped from `model.matrix()`, so factors keep treatment coding with the first level dropped;
     - unused levels are kept;
     - `strata()`, `cluster()`, `tt()`, `frailty()`, `ridge()`, and `pspline()` are refused;
     - `min_provider_size = NULL` screens nothing;
     - `start` is 0 for right-censored data.
3. **The model object** (minor).
   - *Needed:* the fields that `new_pprof_model()` fills and checks; what `spec` must hold; what `row_index` means.
   - *Looked:* the vignette's "What a fit function does" step 4, the toy model, and "Fitting into the rest of R"; ARCH §E.2 step 4.
   - *Found:* the call's arguments by example only. The vignette suggests running `names(fit)`, which needs R.
   - *Opened:* `R/model-class.R`. It showed:
     - the shared fields (`model_shared_fields`);
     - that extra fields come through `...` and cannot repeat a shared one;
     - that `provider_effects` may be `NULL`;
     - that `spec` needs only one string, `family`;
     - that `row_index` must be "the input row of every observation";
     - that the argument is `class`, not ARCH's `subclass` (§4, item 1).
   - *Still not documented:* that `spec` must hold every engine setting needed to rebuild the engine object (DEC-005). This is visible only in the Cox models' `spec`.
4. **The random-effect pattern** (minor).
   - *Needed:* whether "the lme4 adapter and `R/model-mixed.R` as the pattern" means inheriting `pprof_mixed` (ARCH §E.1: "mixed models share an lme4 implementation through the `pprof_mixed` class") or copying its structure; the RE families' literal specification; their screening.
   - *Looked:* the guide's table; the vignette's "Random effects" column ("the model's", "as the outcome's", `null_options` "none"); ARCH §E.3.
   - *Opened:* `R/model-mixed.R`. It showed:
     - `pprof_mixed`'s validator is lme4-specific, so a coxme model cannot inherit the class;
     - RE models screen no provider (K-07);
     - the literal values: `null_options = character()`, `test_default = "wald"`, `one_sided_extremes = FALSE`, no `variance_function`;
     - the field `provider_effect_sd`;
     - how the adapter keeps lme4's messages, and that it checks the engine fitted the same rows.
5. **The Cox specification's literal values** (minor).
   - *Needed:* the values to model a Cox-type family on. The vignette gives `effect` as "a description", and `coefficient_wald` only as "the rule of the coefficients' Wald tests and intervals".
   - *Looked:* the vignette's "The family specification" (both tables); ARCH §E.6, "The contract and the profiling hooks".
   - *Found:* prose. The vignette points to `str(profile_spec(fit))`, which needs R.
   - *Opened:* `R/model-cox-stratified.R`, `profile_spec.pprof_cox_stratified`. It showed:
     - `effect` is free text;
     - `variance_function = function(expected) expected`;
     - the Poisson funnel's fields;
     - `coefficient_wald`'s literal list, whose structure NAMING §5 also gives.
   - *Also opened:* greps of `R/`. The profiling layer never branches on `family`, so a new family name is safe. `effect` is required by `profile_spec_fields` but read nowhere, so it is only a label. The vignette says neither.
6. **Expected events and the baseline of a delegated Cox model** (**blocking**).
   - *Needed:* where the frailty model's per-observation expected events come from. They drive `expected_outcome()`, every test, every measure, and every limit, and coxme returns no baseline hazard, survival curves, or martingale residuals, as far as its documentation goes.
   - *Looked:*
     - the guide's rule 3: "never computed in the package: no partial likelihood, Newton step, variance, residual, or baseline hazard";
     - the opening of "Delegated engines": "the package owns the data, what it derives from the engine's results, and the profiling";
     - the table's row for explicit effects: "the expected events at the model's baseline, scaled by exp(effect)", pointing to `cox_expected_events()`;
     - ARCH §E.6.
   - *Opened:* `R/model-cox-measures.R` and `R/model-survival.R`. `cox_expected_events()` computes the Breslow estimator in package code ("the cumulative sum of d(t) / RS(t)"), while `R/model-survival.R`'s header repeats rule 3.
   - *Why it blocks:* the documents don't say which reading holds. They also don't say whether one model may use two engines (coxme for the fit, survival's fitter for a baseline at coxme's linear predictor). The choice changes numbers, so I could not proceed without guessing. A.3, rule 3, sets out both options.
7. **`indirect_numerator` and Poisson counts interact** (minor, but a trap).
   - *Needed:* whether these two fields can be chosen independently. A frailty model could take RE's `"predicted"` numerator together with Cox's Poisson counts.
   - *Looked:* the vignette's "The family specification" and "Capabilities", which present them as independent fields.
   - *Opened:* `R/profile-tests.R` (`profile_poisson_test_table()`) and `R/profile-standardize.R` (`profile_indirect()`). The Poisson tests and limits read the indirect table's `observed` column, which is `predicted_outcome()` when the numerator is `"predicted"`.
   - *Consequence:* such a family would run exact and mid-p Poisson tests on non-integer predicted counts, without an error. The documents give no warning.
8. **The direct standardization hook of a Cox model with provider effects** (minor).
   - *Needed:* which hook such a model uses.
   - *Looked:* the vignette's optional fields. `direct_expected(effects, linear_predictor, threads)` receives no baseline, but a Cox model's population expectation needs each observation's baseline cumulative hazard. `direct_by_provider` is documented as "for a model without provider effects".
   - *Opened:* `R/profile-standardize.R` (`profile_direct()`). `direct_by_provider` is used whenever the specification has it, and otherwise `direct_expected` is called with the linear predictor.
   - *Consequence:* a closure built in `profile_spec(model)` works, and so does `direct_by_provider`, but the documents' wording points away from both.
9. **How the adapter hands data to the engine** (minor).
   - *Needed:* the form of the engine's inputs.
   - *Looked:* the guide's rules 1 and 2; the vignette's `glm()` example (rows built from the prepared vectors).
   - *Opened:* `R/model-mixed.R` and `R/model-survival.R`. There are two patterns: lme4 gets the user's columns and builds its own design; survival gets the prepared vectors under generated names, with the provider as integer codes in provider order.
   - *Not settled:* the documents don't say which pattern a new adapter follows.
10. **The error of a missing suggested engine** (minor).
    - *Needed:* the class of rule 8's "classed error naming the package and its minimum version".
    - *Opened:* `R/model-glmnet.R`. `glmnet_require()` raises `pprof_error_invalid_input` with a `package` field, and `glmnet_available()` serves the skips.
11. **The standard methods of a survival model, and where they go** (minor).
    - *Needed:* which standard methods a Cox-type model must define, and in which files.
    - *Looked:* the vignette's "Fitting into the rest of R" (`augment()` uses `residuals(type = "response")`) and "Registering the methods" ("No other R file changes"); ARCH §E.4; ARCH §E.6 ("the model methods in the presentation files").
    - *Opened:* NAMING §10, `R/model-cox-stratified.R`, and a grep of `R/present-*.R`.
      - The Cox models' residuals are martingale, score, and dfbeta, and `nobs()` counts events.
      - `print.pprof_cox_stratified` is in `R/present-print.R`, and its `glance()` and `augment()` are in `R/present-tidy.R`, documented in the shared `pprof_tidy` topic.
    - *Consequence:* a frailty model needs its own `print()`, `glance()`, and `augment()`, and the precedent puts them where the vignette says no file changes (§4, item 3).
12. **A model whose fitted rows are not the input rows** (**blocking**).
    - *Needed:* how a model fit to person-periods fills the per-observation fields, and serves the methods that take `data`.
    - *Looked:* the vignette's toy model (`prepared$row_index` gives "each one's row in the input data") and "The model contract"; the guide's rule 7; the table's row (the observation question is methodological).
    - *Found:* nothing on expansions.
    - *Opened:* `R/model-class.R`, `R/model-logistic-fe.R`, `R/present-tidy.R`, and `R/model-survival.R`. They showed:
      - `validate_pprof_model()` requires `row_index` to be the input row;
      - `model_prepared_data()` rebuilds the data by calling `data_prepare(model$formula, data, ...)`, which after an expansion needs the expanded data, not the user's;
      - `formula` is filled from the prepared data, so `formula(fit)` is the binary formula;
      - `refit_without()` and `provider_test()` call `model_prepared_data()`;
      - `fitted()`, `residuals()`, and `predict()` order their values by `row_index`;
      - the Fine–Gray precedent keeps its expansion internal (`row`) and refuses `augment()` (D-81).
    - *Why it blocks:* with no rule, the meaning of `row_index`, `n_obs`, `nobs()`, `formula()`, `augment()`, and every `data` argument has to be guessed. B.4 and B.5 propose one answer.
13. **Where the expansion lives, and what it may call** (minor).
    - *Needed:* whether the data layer may call survival (`survSplit()` does this split), and whether the expansion must repeat `data_prepare()`'s reading of survival responses.
    - *Looked:* the table ("in the data layer, before `data_prepare()`", "`R/data-survival.R`"); rule 1 (every call that prepares an engine's inputs goes in the adapter); ARCH §E.6 (Fine–Gray's `finegray()`).
    - *Opened:*
      - `R/data-survival.R`, whose helpers can be reused;
      - `R/model-survival.R`, where Fine–Gray's expansion lives, in the adapter, after `data_prepare()`;
      - `tests/testthat/test-architecture.R`. Layers come from file prefixes (`check` is layer 2), and only calls between pprof's own functions are checked, so a data-layer `survival::survSplit()` passes the test even though rule 1 may forbid it.
14. **Reusing the logistic FE engine** (minor).
    - *Needed:* whether the new fit calls `fit_logistic_fe()` or its internals; how a subclass validates; what it inherits.
    - *Looked:* the table ("Where to start: `fit_logistic_fe()`"); the vignette's `glm()` subclass, which inherits the toy model's methods.
    - *Opened:* `R/model-logistic-fe.R`. It showed:
      - the internals `logistic_fe_estimate()`, `logistic_fe_model(..., class)`, and `validate_pprof_logistic_fe(x, family)`, which is Firth's pattern;
      - `profile_spec.pprof_logistic_fe` hard-codes `family = "logistic_fe"`;
      - the fit requires at least one covariate;
      - `effect_bound` clamps provider effects but not coefficients, so a period without events diverges.
15. **The threshold of the performance rule** (minor).
    - *Needed:* what rule 11's benchmark must show.
    - *Looked:* rule 11, which cites DEC-105 without stating the threshold.
    - *Opened:* `dev/DECISIONS.md`, DEC-105: 10% above the engine call plus the preparation of its inputs, with a floor of 0.05 s on the median (DEC-038), from the CoxPH brief's §3.7.
    - *Not settled:* whether the rule binds a later brief.
16. **Tolerances for a new engine** (minor).
    - *Needed:* the tier of coxme's engine-identity tests and of its reference comparisons.
    - *Looked:* rule 10 ("the `cox_engine` tier (no tolerance)"); the vignette's "Testing a model".
    - *Opened:* `helper-tolerances.R` and `.claude/rules/tests.md`. `cox_engine` is atol = rtol = 0, justified for "direct survival and glmnet calls". Tiers 0 to 4 each need a one-line justification and change only with sign-off.
    - *Not settled:* whether a new engine reuses `cox_engine` or adds a tier.
17. **The full list of files to touch** (minor).
    - *Needed:* every file a new exported model touches.
    - *Looked:* the walk-through's step 10 and ARCH §E.5's step 10; ARCH §E.4; the guide's "Changing code" (NEWS.md).
    - *Opened:* `_pkgdown.yml`. Its reference index lists every topic by name, so new exports must be added, because pkgdown refuses topics missing from the index.
    - *Also missing from the lists:* DESCRIPTION (Suggests), NAMING, the four registers, ARCH §E.3's table, and the guide's tables.
18. **The shared validators and the model helpers** (minor).
    - *Needed:* ARCH §E.2's "shared validators", and the internal helpers that a model inside pprof uses.
    - *Found:* the three documents name none. The vignette shows base R's `errorCondition()`, which is right for a model in another package.
    - *Seen while reading the model files:*
      - argument checks: `check_choice()`, `check_flag()`, `check_count()`, `check_number()`, `check_threads()`;
      - conditions: `abort_invalid_input()`, `abort_data()`, `abort_convergence()`, `abort_unsupported_inference()`, `warn_not_converged()`, `inform_message()`;
      - model helpers: `model_observation_effects()`, `model_input_order()`, `model_prepared_data()`, `model_design_for()`, `model_effects_for()`.
19. **No reference** (**blocking**, by design).
    - *Needed:* the reference that each later model "needs ... before it is built" (the guide). It sets the defaults (the Class B rule), what rule 6 refuses, and the fixtures.
    - *Looked:* the guide's "The later models"; rule 6.
    - *Opened:* `dev/coxph_brief.md` (grep). §2.2 lists both models and leaves coxme out of that brief. Neither the brief nor the guide names a candidate reference for either model.
    - *Why it blocks:* I had to guess every default (ties, `tol`, `max_iter`, `breaks`, `min_provider_size`). The documents rightly leave the reference to a brief, but they don't say what validation stands in when no external reference exists: engine identity, an independent implementation, or simulation.

---

## 4. Ambiguities and contradictions

1. **`subclass` or `class`.** ARCH §E.2 step 4 says `new_pprof_model(subclass = ..., ...)`. The vignette's code passes `class = ...`, which is what the code takes (`R/model-class.R`). ARCH is stale.
2. **Rule 3 against the measures code.** Rule 3 says the package computes "no ... baseline hazard", but `cox_expected_events()` computes Breslow's in package code, and the guide's table points to it. The opening of "Delegated engines" ("the package owns ... what it derives from the engine's results, and the profiling") supports exempting the measures. Both readings are defensible, and they give different designs (gap 6).
3. **"No other R file changes."** The vignette's "Registering the methods", the walk-through's step 10, and ARCH §E.4 ("Nothing in the data, inference, profiling, or presentation files changes") all say so. Against that:
   - the Cox models' `print()`, `glance()`, and `augment()` are in presentation files (ARCH §E.6 notes it without a rule);
   - rule 1's one adapter per engine sends any new survival call into the existing `R/model-survival.R`;
   - the discrete-time row requires an addition to the data layer.
4. **The lme4 pattern against rule 4.** The table names `R/model-mixed.R` as the frailty model's pattern, and the lme4 fits pass `...` to the engine and leave lme4's defaults in force (NAMING §4; rule 2: "as pprof 1.0.3 called them"). Rule 4 says "Every option that can change a number is passed, never left to the engine's default". Following the pattern breaks the rule.
5. **"As the pattern."** This can mean inheriting the class (ARCH §E.1: "share an lme4 implementation through the `pprof_mixed` class") or copying the file's structure. Only the second is possible (gap 4), and the documents don't say so.
6. **Where an expansion lives.** The discrete-time row says "in the data layer, before `data_prepare()`". Fine–Gray's expansion lives in the survival adapter, after `data_prepare()` (ARCH §E.6), and rule 1 puts calls that prepare an engine's inputs in the adapter.
7. **What the discrete-time interface is.** "Where to start: `fit_logistic_fe()`" admits three designs: a new fit function, an option of `fit_logistic_fe()`, or an exported expansion that users follow with `fit_logistic_fe()` themselves.
8. **`augment()` for survival models.** The vignette's "Fitting into the rest of R" says `augment()` uses `fitted()` and `residuals(type = "response")`. Cox models have no response residuals (NAMING §10), and they define their own `augment()` or refuse it (Fine–Gray, D-81).
9. **`direct_by_provider`.** The vignette documents it as "for a model without provider effects". The profiling code uses it whenever it is set, and `direct_expected`'s arguments cannot carry a Cox baseline (gap 8).
10. **Rule 7's `data`.** "Methods that need it otherwise rebuild it from `data`" reads as either the model's kept `data` field or the user's `data` argument. NAMING §10 and the code mean the argument.
11. **Licensing.** The guide's penalized row says "a package whose license allows its use (grplasso is GPL-3, pprof MIT)". The brief's §2.2 says the concern is copying grplasso's code. The guide's wording leaves unclear whether a license check is needed before suggesting coxme.
12. **Two places called `family`.** NAMING §10 (Phases C4 and C5) says "The family specification has `family = "cox_penalized"` and holds the fit's settings", but the code holds those settings in the model's `spec`, which NAMING §5 distinguishes from the family specification. It also isn't said whether `spec$family` and `profile_spec()$family` must agree. The RE families agree by construction, but logistic FE hard-codes its family, so a subclass inherits the wrong one.
13. **Whether `null_effect()` checks `null`.** The vignette says the method "receives a `null` that pprof has already checked". The existing methods (`pprof_mixed`, `pprof_cox_stratified`) check it again, so a reader can't tell whether the check is needed.
14. **The scope of `cox_engine`.** Its justification names survival and glmnet only. It isn't said whether another engine's identity tests may use it (gap 16).
15. **Which pprof_py conventions bind a later Cox model.** A Cox model whose reference is not pprof_py might or might not keep: zero weights left out of the fit (M-25), the `two_sided_upper` covariate rule (DEC-101), two-sided Poisson tests only, Breslow baselines whatever the ties (M-29), and `ties = "breslow"` as the default. The documents treat these as the Cox family's conventions and don't say.
16. **Engine names in NAMING §2.** lme4 and glmnet are whitelisted "in adapter names only", and survival needs no entry because it is a word. Rule 1 doesn't say that a new engine's name (coxme) must be added.
17. **The naming pattern.** NAMING §3.1's `fit_<outcome>_<effects>()` and the Cox fits' own names (`fit_cox_stratified()`, `fit_cox_penalized()`, `fit_fine_gray()`) lead to different names: `fit_cox_re()` or `fit_cox_frailty()`, and `fit_discrete_time_fe()` or something else.

---

## 5. Open questions the documents rightly leave to methodology owners

The guide's table flags A2, B1, and the measures of B5 explicitly. The others follow from the designs.

**A. Frailty Cox profiling**

- **A1. Estimator.** A Gaussian log-frailty through coxme (the Laplace-approximated integrated partial likelihood), or a gamma or Gaussian frailty through survival's `frailty()` (penalized partial likelihood, with θ by EM, REML, or AIC). This also chooses the engine.
- **A2. The indirect numerator** (`indirect_numerator`). Observed events over expected events at the null, or predicted over expected. For a Cox model the predicted version reduces to exp(b̂_i) when both sums use the same expected events.
- **A3. The measures.** A ratio only, and what direct standardization means under a frailty model.
- **A4. The baseline behind the expected events.** Conditional on the predicted frailties, or on the fitted β alone; Breslow's, or the fit's ties; whether rows with weight 0 count.
- **A5. The norm.** 0, the mean log-frailty, as for RE and Cox; or the median of the predicted effects.
- **A6. The provider tests and their default:**
  - Wald on the predicted effects, with which variance: conditional on θ̂ and β̂, as lme4's conditional variance; or the random block of the full inverse information;
  - Poisson exact or mid-p tests of observed against expected events at the null;
  - or both;
  - and whether to give a funnel.
- **A7. The covariate Wald rule.** `two_sided_upper` (Cox), `upper_doubled` (logistic RE, D-31, awaiting sign-off), or plain two-sided.
- **A8. The log-likelihood.** Integrated or penalized, for `logLik()`, AIC, and BIC, and with how many degrees of freedom.
- **A9. Edge cases.** Screening (none?), providers with no events, and the minimum number of providers.
- **A10. Defaults with no reference.** Ties, `tol`, `max_iter`, and the outer optimizer's settings.
- **A11. The reference.** What it is, and the equivalence contract it implies.

**B. Discrete-time provider models**

- **B1. What counts as an observation.** Persons or person-periods, for `n_obs`, screening by `min_provider_size`, the trials of the exact and bootstrap tests, the funnel's precision, the n of AIC and BIC, and `nobs()`.
- **B2. The periods:**
  - the default breaks;
  - which end of an interval is closed;
  - partial periods (a subject censored mid-period);
  - events exactly at a break;
  - late entry;
  - times beyond the last break.
- **B3. The baseline.** A factor of periods or a smooth function; and what to do with periods without events (merge them, drop them, or stop).
- **B4. The link.** The engine fixes the logit, a discrete proportional-odds model. The grouped-time proportional hazards model would use the complementary log-log. The owners should confirm the logit.
- **B5. The measures.** The ratio of observed to expected events; whether a rate (events per person-period) means anything; direct standardization over person-periods.
- **B6. The tests.** The Poisson-binomial exact and bootstrap tests treat person-periods as fixed Bernoulli trials. Are they, the score tests, and the funnel valid here?
- **B7. The norm.** The median of γ̂, as logistic FE?
- **B8. Inherited behavior.** Whether a new model with no pprof 1.0.3 reference keeps logistic FE's reproduced behaviors: the null refit at default settings (D-10), the `"any"` stopping rule's early stop (D-24), the clamping by `effect_bound`, and the rank warning (D-38).
- **B9. The reference.** What the model is validated against.
- **B10. Recurrent events.** Whether counting-process data with several events per subject are allowed.

---

## 6. Verdict

The documents are a good map. The guide's eleven adapter rules are concrete enough to act on, and by following them and the files they point to, a developer can lay out both designs: interface, files, adapter, contract methods, capabilities, and tests. But neither design can be completed from the three documents alone. I needed 19 other files, ten of them read in full, mostly for literal values and conventions that the documents give only in prose. Three questions cannot be settled without guessing:

- whether a delegated Cox model's expected events may be computed in package code (rule 3 against `cox_expected_events()`);
- how a model whose fitted rows are not the input rows fills the contract's per-observation fields and its `data` methods;
- which reference sets the defaults and the equivalence tests.

What would help most:

1. A "contract as built" appendix in the vignette: each family's literal specification values, the shared fields and what they mean, the internal helpers that a model inside pprof uses, and which hooks combine safely (the `"predicted"` numerator with Poisson counts).
2. A ruling on rule 3 for the measures.
3. A short section on models fit to expanded data, built on the Fine–Gray precedent.
4. Corrected claims about "no other R file changes" (presentation methods, an existing engine's adapter file, the data layer), and a fix to ARCH §E.2's `subclass`.

---

## What changed in response

The fixes, in the commit that adds this report. The gaps the documents rightly leave to a brief (§5's questions, and the reference itself, gap 19) stay open; the documents now say so.

| Gap or ambiguity | Fix |
|---|---|
| 6, and ambiguity 2: rule 3 against the measures' Breslow baseline (blocking) | The guide's rule 3 separates what the engine computes for the fitted model (partial likelihood, Newton steps, variance, residuals, the fit's baseline hazard, which `baseline_hazard()` takes from `survfit()`) from what profiling computes from the engine's results, the package's own by the brief's assignment: the measures' expected events at the national Breslow baseline (`cox_expected_events()`, K-136, K-137), the Poisson tests and limits, pprof_py's λ grid, and the fold deviances' saturated term; a later brief says on which side each of its quantities falls. The frailty row of "The later models" names the baseline of the expected events as a methodological question. |
| 12, and ambiguity 6: models fitted to expanded rows (blocking) | A paragraph "Models fitted to expanded rows" in the guide: the Fine–Gray pattern (the observations stay the input rows, the expansion is internal, its size a field, per-expanded-row methods refused, D-81), what `validate_pprof_model()` and `model_prepared_data()` assume, and that a model whose observations are the expanded rows departs from the pattern by its brief's decision. The discrete-time row says where an expansion lives: the data layer if the package computes it, an adapter if an engine's function does. |
| 19: no reference (blocking, by design) | "The later models" says that where no external reference exists, the brief names the validation that stands in: engine identity, an independent implementation, and the simulation study. |
| 1, ambiguity 16: engine names | Rule 1: a new engine's name joins NAMING §2's list. |
| 4, ambiguities 4 and 5: the lme4 pattern | Rule 4 names the lme4 fits as the reference's exception (they pass `...` and leave lme4's defaults, as pprof 1.0.3 did), which a new adapter does not copy; the frailty row says the `pprof_mixed` class is lme4's and cannot be inherited, the file's structure being the pattern. |
| 7: `"predicted"` with Poisson counts | The vignette's `count_distribution` row: the Poisson tests and limits read the observed counts, so `"poisson"` goes with `indirect_numerator = "observed"`. |
| 8, ambiguity 9: `direct_by_provider` | The vignette's row: used in place of `direct_expected` whenever it is given. |
| 9: how the adapter hands data to the engine | Rule 2: the survival and glmnet adapters give the engine the prepared data, the lme4 adapter the user's columns as pprof 1.0.3 did. |
| 10: the class of a missing suggested engine's error | Rule 8: `<engine>_require()` raises `pprof_error_invalid_input` with a `package` field; `<engine>_available()` gives the skips. |
| 11, ambiguity 3: "no other R file changes" | The vignette's "Registering the methods" and its walk-through, and ARCHITECTURE §E.4: a model's own `print()`, `glance()`, and `augment()` go in the presentation files, and a new call to an engine the package already uses goes in its adapter. |
| 12's `augment()`, ambiguity 8 | The vignette's "Fitting into the rest of R": the shared `augment()` uses response residuals, and a model without them has its own. |
| 5: `effect` | The vignette's table: a label that the profiling code does not read. |
| 14, ambiguity 12: subclasses and `family` | The guide: `spec$family` names the model, `profile_spec()$family` the specification it is profiled with, which a subclass may inherit (Firth's models are profiled as `"logistic_fe"`). The discrete-time row points to `fit_logistic_fe()`'s internals as Firth uses them. |
| 15: the performance rule's threshold | Rule 11 states it (10% above the engine calls plus the preparation of their inputs, by DEC-038's test with its 0.05 s floor) and that a later brief sets its own. |
| 16, ambiguity 14: tolerances for a new engine | Rule 10: a new engine's identity tests use `expect_identical()`; the tiers change only with sign-off. |
| 17: the files a new model touches | A paragraph "Files a new model touches" in the guide. |
| 18: the shared helpers | The guide names `check_*()`, `abort_*()`, `warn_*()`, `inform_message()`, and `model_*()` with their files. |
| 3: `spec` holds the settings to rebuild the engine's object | Rule 7 says how methods rebuild the engine's object from `data`: `model_prepared_data()`'s check, a refit with the fit's settings, and the check that it reproduces the coefficients. |
| Ambiguity 1: `subclass` | ARCHITECTURE §E.2 says `class`. |
| Ambiguity 11: licensing | The penalized row: grplasso's code could be copied only if its authors relicensed it; a suggested package raises no such question. |
| Ambiguity 13: `null_effect()` checks `null` again | Left: the vignette's statement holds (pprof checks it first), and checking again is harmless. |
| Ambiguity 15: which pprof_py conventions bind a later Cox model | Left to the later brief, with its reference (gap 19). |
| Ambiguity 17: naming pattern | Left to the later brief and NAMING §9's checklist. |
| 2: `data_prepare()`'s interface | Left to `?data_prepare`, which the vignette's "Further reading" names. |
