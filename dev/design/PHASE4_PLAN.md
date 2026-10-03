# Phase 4 plan: remaining models

Approved by the project lead on 2026-10-03, with decisions DEC-040, DEC-041, and DEC-042. Branch `rewrite/phase-4`, created from `rewrite/phase-3` at `c430436` (stacked until Phases 1 to 3 are merged into `rewrite/v2`). The gate is a STOP (brief §4): run `/phase-gate` and wait for approval.

The facts in the last sections were gathered by reading the code at `c430436` when the plan was written. Treat them as starting points and confirm each by running code before relying on it (CLAUDE.md).

## Scope (DEC-040)

Phase 4 builds, for linear fixed effects, Firth, and the linear and logistic random-effect (RE) and correlated random-effect (CRE) models:

- the fit functions and model objects;
- the model-contract accessors;
- the standard methods;
- the lme4 adapter;
- Firth in the C++ core;
- the six fit wrappers, which return the reference's objects exactly.

Phase 5 adds their inference: `profile_spec()` rows, capability declarations, provider tests, intervals, standardized measures, flags, covariate tests (`summary()`, `confint()`), and the wrappers of the old methods.

Between the two phases:

- The reference's method files (`test.*`, `SM_output.*`, `confint.*`, `summary.*`, `plot.linear_fe`) stay and run on the objects the wrappers return. The method fixtures therefore check those objects.
- Profiling functions, `summary()`, and `confint()` on the new linear FE, RE, and CRE models raise `pprof_error_unsupported_inference`.
- Firth inherits the logistic FE inference through its class (DEC-004), as the reference's Firth objects use the `logis_fe` methods, so Firth is complete in Phase 4.

## Steps

Work in this order. Commit small, scoped commits, and add a dated entry to PROJECT_CONTEXT §10 at the end of each step. Pause for a check-in after step 1, which settles the Firth iteration path, the riskiest part.

### Step 1: Firth in the C++ core

- **Files.** Add `src/logistic/firth.{h,cpp}` and the adapter `cpp_logistic_firth()` in `src/rcpp_logistic.cpp`, and list the new objects in `OBJECTS` in both `Makevars` and `Makevars.win`. Leave `src/Firth.cpp` in place for the live comparison.
- **Algorithm (K-30 to K-33).**
  - The block information comes from `core/information_blocks`, with weights w = p(1 − p) whose zero entries are replaced by 1e-10 in every block (K-31; DEC-007, the caller supplies the weights).
  - The penalized log-likelihood is ℓ* = ℓ + ½ log det I. The log-determinant is Σ log(max(D_i, 1e-12)) + 2 Σ log diag(chol((S + S')/2)). If the Cholesky factorization fails, retry once with a ridge of 1e-8·I, and fail if that also fails (K-30).
  - The step uses the modified residual y − p + h(½ − p), with hat values from the block inverse, and a full Newton step without line search (K-32).
  - Clamp γ after its update (K-15), then recompute the information after the clamp.
  - Stopping uses the β rule only: the criterion starts at 1e9, and the loop runs while `iter < max_iter` and the criterion > `tol` (K-33).
  - The engine returns the status, the iteration count, the final criterion, and the history, which the reference discards.
- **Summation order.** With one thread, the reference's parallel region (`src/Firth.cpp` lines 122–280) processes providers in chunks and accumulates under `critical` sections. Reproduce that order exactly so the iteration path matches.
  - With more threads, compute per-chunk results and combine them in chunk order, so the result does not depend on the thread count. This fixes D-05.
  - No R API calls and no escaping exceptions inside parallel regions: failures set a flag (ARCHITECTURE §B.3).
- **Checks.**
  - Bitwise against the old `logis_firth_prov()` on the bundled example and on 12 or more seeded random datasets, through a live comparison like the one for SerBIN and BAN in Phase 3 step 1. Cover tight and default `tol` and providers with no or only events.
  - `threads = 2` identical to `threads = 1`.
  - The four `logis_firth` fixture cases.
  - C++-path tests for non-convergence and singular information.

### Step 2: Model layer

New files, following ARCHITECTURE §B.2 and NAMING.md:

- **`R/model-logistic-firth.R`: `fit_logistic_firth(formula, data, provider, max_iter = 1000, tol = 1e-5, effect_bound = 10, min_provider_size = 10, keep_data = FALSE, threads = 1, verbose = FALSE)`.**
  - Class `c("pprof_logistic_firth", "pprof_logistic_fe", "pprof_model")`.
  - Data through `data_prepare()`, with screening and event counts as for logistic FE, and starting values K-10.
  - Variance, ℓ, AIC, and BIC are the unpenalized quantities at the Firth estimates, through `cpp_logistic_variance()` (K-34, D-12 reproduced until M-2 is answered).
  - AUC as for logistic FE (`logistic_fe_auc()`, D-40).
  - The convergence history is kept.
- **`R/model-linear-fe.R`: `fit_linear_fe(formula, data, provider, provider_variance = "simplified", keep_data = FALSE, verbose = FALSE)`.**
  - Class `c("pprof_linear_fe", "pprof_model")`.
  - No screening (K-07): `min_provider_size = NULL`; no intercept in the design.
  - Direct demeaning in R (DEC-006) instead of the reference's dense `Matrix::bdiag()` centering. β solves (Z̃'Z̃)β = Z̃'ỹ with Z̃ and ỹ centered within providers, and γ_i = ȳ_i − z̄_i'β (K-40).
  - σ² = SSR/(n − m − p) and Var(β) = σ²(Z̃'Z̃)⁻¹ (K-41).
  - Var(γ) is σ²/n_i (simplified) or σ²(1/n_i + z̄_i'(Z̃'Z̃)⁻¹z̄_i) (full) (K-42).
  - ℓ, AIC, and BIC with m + p + 1 parameters (K-43).
  - `provider_variance` is stored in `spec`, so D-16's hidden attribute becomes an explicit setting.
  - Results must agree with the reference at the closed-form tier (atol 1e-12, rtol 1e-10); Phase 0 measured 1.5e-14 on β (B2).
- **`R/model-mixed.R`: the lme4 adapter.** Class `pprof_mixed` (DEC-004), function names per NAMING.md (`lme4_fit()`).
  - It takes a complete lme4 formula and the data frame to pass (DEC-042), and calls `lme4::lmer(formula, data, ...)` (REML by default) or `lme4::glmer(formula, data, family = binomial(link = "logit"), ...)` (Laplace) exactly as the reference does (K-50).
  - It extracts `fixef()` (with intercept), `ranef(condVar = TRUE)` with the conditional variances, `VarCorr()`, σ, `vcov()`, `logLik()`, `AIC()`, `BIC()`, `fitted()`, and `model.matrix()`.
  - It keeps the merMod only with `keep_data = TRUE` (field `engine_fit`).
- **`R/model-linear-re.R`, `R/model-logistic-re.R`: `fit_linear_re(formula, data, provider, keep_data = FALSE, verbose = FALSE, ...)` and `fit_logistic_re()` with the same arguments.**
  - Data through `data_prepare(intercept = TRUE, min_provider_size = NULL)`.
  - The adapter receives the input rows in provider order (`row_index`) with the response, provider, and variable columns, and the formula `response ~ <fixed terms> + (1 | provider)`: random intercepts only (DEC-042).
- **`R/model-linear-cre.R`, `R/model-logistic-cre.R`: `fit_linear_cre(formula, data, provider, within_between, keep_data = FALSE, verbose = FALSE, ...)` and `fit_logistic_cre()` with the same arguments.**
  - The decomposition comes from the data layer (`data_decompose_within_between()`: means over every input row before deletion, K-54, D-13 reproduced).
  - The formula is `Y ~ <within> + <between> + <other> + (1 | provider)` (K-50).
  - The variance component follows K-51, including `vcov` for logistic CRE.
- **Object fields (ARCHITECTURE §D.1).** The shared fields, plus for mixed models `fitted` (lme4's fitted values, the numerator of K-82 and K-84), `provider_effect_sd` (computed once at fit time: the closed form of K-69 for linear RE and the conditional SD of K-70 for the others), and `variance_components`; `sigma` for the linear models.
- **Methods for every new class.**
  - Contract accessors: `provider_table`, `provider_estimates`, `provider_index`, `linear_predictor`, `observed_outcome`, `expected_outcome` (plogis for logistic, identity for linear), `null_effect`, `provider_estimate_se`.
  - Standard methods: `coef`, `vcov`, `nobs`, `logLik` (the family's degrees of freedom; lme4's for mixed models), `fitted`, `residuals`, `predict`, `formula`, and `print` (through `print.pprof_model`).
  - `inference_capabilities()` returns nothing yet for linear FE, RE, and CRE (DEC-040).
- **Checks.**
  - New-API tests against the fit fixtures: closed-form tier for linear FE, iterative for Firth, and lme4 tier for RE and CRE. The lme4-tier tests run only when the installed lme4 and Matrix equal the manifest's (DEC-020).
  - Tests of every accessor and standard method.
  - The extension proof and the architecture test still pass.

### Step 3: Compatibility wrappers and the switch

- **Wrappers.** Write them in `R/compat-fits.R` (and `compat-convert.R` for the conversions): `linear_fe()`, `logis_firth()`, `linear_re()`, `logis_re()`, `linear_cre()`, and `logis_cre()`.
  - Each calls the new fit with `keep_data = TRUE` and returns the reference's object exactly: field names, matrix shapes, dimnames, attributes, `data_include`, `char_list`, and for RE/CRE the merMod in `attr(fit, "model")` (BEHAVIOR_SPECS §3–§6, §16).
  - They reproduce the reference's messages: the unconditional "Input format: …" of `linear_fe()` and the RE fits; none for the CRE fits; for `logis_firth()` with `message = TRUE`, whatever the fixtures captured (its R code copies `logis_fe()`'s processing, BEHAVIOR_SPECS §3, but its C++ log may differ; check the captured output).
  - They accept the reference's input formats.
- **RE formulas (DEC-042).** The RE wrappers pass the user's formula to the adapter unchanged in the formula branch. In the column and vector branches they pass the reference's constructed formula: `paste(Y.char, "~ (1|", ProvID.char, ") +", paste(Z.char, collapse = " + "))`, and `Y ~ (1| ProvID)+z1+…` for vectors. The data are the reference's: the used columns, complete cases, sorted by `factor()` of the provider.
- **Class A fixes.**
  - D-11: in the vector interface, a character `ProvID` with matrix covariates, and a call where no input format matches, raise classed errors instead of "response must be numeric" and "object 'fit_re' not found".
  - D-41: `logis_firth()` with factor IDs when screening excludes a provider.
  - D-25: the help states `max.iter = 1000`.
  - Fixture cases where the reference errors because of these get per-case expectations (DEC-022) in `tests/testthat/helper-reference-overrides.R`.
- **Old object shapes to watch.**
  - `linear_fe`: `variance$gamma` carries the `"description"` attribute that the old `test.linear_fe()` reads (D-16).
  - RE/CRE: `data_include` is built with `as.data.frame(cbind(Y, ProvID, model.matrix(fit)))`, so every column becomes character with character IDs (D-11); CRE `data_include` row names are the positions 1..n.
  - `logis_cre`: `observation` is a one-column tibble, and `fitted` and `linear_pred` have no row names.
  - The CRE `char_list` records formula terms.
- **Print methods (D-09).** `print.linear_re`, `print.logis_re`, and `print.linear_cre` are registered: they remove `attr(, "model")` and call `print.default()`. Move them into `R/compat-*.R`. `print.logis_cre` is defined but not registered in the reference, so do not register one.
- **The switch.** After the wrappers pass every fit and method fixture:
  - Remove `R/linear_fe.R`, `R/logis_firth.R`, `R/linear_re.R`, `R/logis_re.R`, `R/linear_cre.R`, and `R/logis_cre.R`.
  - Remove `src/Firth.cpp`, and from `src/Fixed_effect.cpp` remove `logis_fe_var()` (used only by the old `logis_firth()`) and the dead `compute_profilkd_linear()`.
  - Keep `computeDirectExp()` until Phase 5: the old `SM_output.logis_re/.logis_cre` and `confint.logis_re/.logis_cre` call it, the latter with `threads = 4` hard-coded (D-21).
  - Regenerate `RcppExports`.
  - Remove the files from `.lintr` and from the legacy list in `tests/testthat/test-architecture.R` (DEC-031).
- **Dependencies (DEC-009).**
  - RcppParallel: the `PKG_LIBS` lines in both Makevars files, Imports, LinkingTo, the `importFrom` that the roxygen tag in `R/logis_firth.R` generates, and `SystemRequirements: GNU make`. This removes the GNU make note of R CMD check.
  - Matrix: used only by the old `linear_fe()`.
  - pROC: used only by the old `logis_firth()`.
  - logistf: added to Suggests (DEC-041).
  - dplyr, magrittr, tidyselect, rlang, and tibble stay: plots, `compat-plots.R`, and the CRE `observation` still use them.

### Step 4: Validation, benchmarks, documents, and the gate

- **Independent references (brief §6 E).** Each skips when its package is absent.
  - `lm()` with provider indicators for linear FE.
  - Direct `lme4::lmer()` and `glmer()` calls for RE and CRE.
  - `logistf` with provider indicators for Firth on small data without extreme providers (V12.5: agreement to 2e-11).
- **Metamorphic tests.** Row order, provider relabeling, and agreement across the input formats of the wrappers.
- **Reference suite.** `validation/run-reference.R` through the wrappers, which then also runs the old methods on the wrappers' objects. Extend `validation/run-differential.R` to the new fits.
- **Benchmarks.** `dev/bench/run_reference.R --working-tree` and `compare_to_baseline.R`; `dev/bench/run_paired.R` for flagged tasks with an unchanged control (DEC-038). Tasks exist for `linear_fe` (five scenarios; the baseline skipped `lin-1e5-m100-p5` as infeasible), `linear_re` (two), `linear_cre` (one), `logis_re` (two), `logis_cre` (one), and `logis_firth` (three).
- **Documents.**
  - ARCHITECTURE §B.2, §B.3, §D, and §E.3 as built.
  - NAMING.md for any new name.
  - NEWS.md.
  - DECISIONS for new decisions.
  - DISCREPANCIES statuses: D-05, D-09, D-11, D-12, D-13, D-16, D-25, and D-41.
  - PROJECT_CONTEXT §7 and §10, and the status line.
- **Gate.** `/phase-gate`, then stop for approval.

## Equivalence and tolerances

- Fit fixtures: 28 cases.
  - `linear_fe`: 8 (7 closed-form, 1 exact error case).
  - `linear_re`: 6. `linear_cre`: 4. `logis_re`: 3. `logis_cre`: 3. These 16 are lme4-tier.
  - `logis_firth`: 4, iterative.
  - The method cases on these fits use the closed-form tier (linear FE) and the lme4 tier (RE, CRE); the Firth method cases run through the Phase 3 logistic FE wrappers (iterative and root tiers).
- At non-exact tiers, long vectors stored as signatures compare their sums, extremes, and samples within the tolerance (`tests/testthat/helper-equivalence.R`). So the demeaned linear FE fit (`linear_fe-ecls`, n = 9,101) can pass at the closed-form tier. Only the exact tier requires bitwise identity (DEC-029).
- The iterative tier's tolerance assumes the iteration path is reproduced (ARCHITECTURE §G.4). Firth must reproduce the reference's path; check whether the Firth fixtures record an iteration count (DEC-014) and, if not, compare the path through the live comparison of step 1.
- No fixture regeneration is planned. Any regeneration needs the project lead's approval and a diff report.

## Facts gathered for the plan (2026-10-03, at `c430436`)

- **The reference's RE fits (`R/linear_re.R` lines 91–152; `R/logis_re.R` the same).**
  - Formula branch: response = first variable; provider = text after `|`; covariates = the other term labels; the user's formula goes to lme4 unchanged.
  - Column branch: formula `Y ~ (1| ProvID) + z1 + z2` (random term first).
  - Vector branch: `as.data.frame(cbind(Y, ProvID, Z))` and formula `Y ~ (1| ProvID)+z1+…`.
  - Every branch: `data[, c(Y.char, ProvID.char, Z.char)]`, then `complete.cases()`, then `order(factor(provider))`, then `lmer(formula, data, ...)`.
  - `ranef(fit)[[ProvID.char]]` gives the effects, with row names reset to the provider order (K-52).
- **The reference's CRE fits** compute the decomposition with dplyr `group_by()`/`mutate()` over the full input data, then select the columns, take complete cases, and call `glmer(f, data = df_use, family = binomial(link = "logit"), ...)` (logistic) or `lmer()` (linear).
- **C++.** `src/Firth.cpp` is the only user of RcppParallel (`#include <RcppParallel.h>`, `// [[Rcpp::depends(RcppParallel)]]`). `src/Fixed_effect.cpp` holds `computeDirectExp()`, `compute_profilkd_linear()` (dead), `logis_fe_var()`, and helpers. `src/header.h` includes RcppArmadillo; `src/header.cpp` holds the unused `modString`.
- **Dependencies.** Matrix is used only by `R/linear_fe.R`, pROC only by `R/logis_firth.R`, dplyr by `R/bar_plot.R`, `R/compat-plots.R`, `R/linear_cre.R`, `R/logis_cre.R`, and `R/plot.linear_fe.R`, and caret and olsrr by `R/data_check.R`. tibble is in Imports.
- **Print methods.** Registered: `print.linear_re` (`R/linear_re.R:238`), `print.logis_re` (`R/logis_re.R:238`), `print.linear_cre` (`R/linear_cre.R:206`). `print.logis_cre` (`R/logis_cre.R:199`) is not registered.
- **The data layer** already supports `intercept = TRUE`, `min_provider_size = NULL` (no screening), and `within_between`.
- **Development machine.** lme4 2.0-6 and Matrix 1.7-6 are installed and equal the manifest's, so the lme4-tier tests run. logistf is not installed: install it with `install.packages("logistf", repos = "https://cloud.r-project.org")`.

## Risks to watch

- The Firth iteration path depends on the reference's summation order inside its parallel region at one thread. Reproduce it before restructuring anything.
- lme4 results depend on the exact call: formula term order, data rows and their order, column types, and `...`. The adapter must pass what the reference passes; the merMod's stored `call` is not compared by the fixtures.
- The old method files read fields and attributes of the old objects (for example `attr(variance$gamma, "description")`, `attr(fit, "model")`). The method fixtures, which run on the wrappers' objects, are the check.
- Linear FE demeaning changes the numbers at the 1e-14 level. Flags of providers within tolerance of a threshold may differ; they are listed by the boundary rule, not failures.
- GitHub Actions is not enabled on the fork, so the sanitizer, Linux, and macOS jobs have not run.

## Register items in scope

Fix (Class A or C): D-05, D-09 (keep the reference's printing in the wrappers; `print.pprof_model` for the new classes), D-11, D-16 (made explicit), D-25, and D-41 (Firth).

Reproduce and keep awaiting sign-off (Class B): D-12, D-13, and D-34.

Phase 5 handles the inference items: D-21 for RE/CRE, D-31, D-32, and D-33.
