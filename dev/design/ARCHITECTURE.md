# pprof 2.0: architecture and design (Phase 0)

Status: approved with the Phase 0 gate on 2026-10-02. Branch: `rewrite/v2`. Open questions (§M) remain open until the methodology owners answer them.

> Citations of the v2 rewrite's working documents (the brief, PROJECT_CONTEXT, the phase plans and handoffs, the Phase 0 audit's evidence IDs, the phase fact scripts, the final review) refer to files removed when the rewrite closed on 2026-10-07; `dev/README.md` says where they are. PROJECT_CONTEXT §5.7 is now `dev/CONVENTIONS.md`, and §9 `dev/OPEN_QUESTIONS.md`.

This is the Phase 0 design document required by brief §10. Its companions:

| Section | Where |
|---|---|
| A–I, K summary, M | this file |
| C. Naming convention | [`dev/NAMING.md`](../NAMING.md) |
| J. Behavior specifications | [`BEHAVIOR_SPECS.md`](BEHAVIOR_SPECS.md) |
| K. Verified numerical conventions register | [`CONVENTIONS.md`](../CONVENTIONS.md) (IDs `K-xx`) |
| L. Discrepancy register | [`dev/DISCREPANCIES.md`](../DISCREPANCIES.md) (IDs `D-xx`) |
| Decisions | [`dev/DECISIONS.md`](../DECISIONS.md) (IDs `DEC-xxx`) |
| Evidence | [`audit/`](audit/) scripts and [`audit/output/`](audit/output/) logs (IDs `Vxx.y`, `Bx`) |

## Summary

- **The reference is confirmed.** The CRAN tarball of pprof 1.0.3 (MD5 `6fa1344f…`) is identical to commit `5260838` in `R/`, `src/`, `tests/`, `data/`, `man/`, and `NAMESPACE`; `DESCRIPTION` differs only by `R CMD build` normalization. No CRAN package depends on pprof in any field.
- **The static audit holds up.** 76 runtime checks confirmed or refined every hypothesis in PROJECT_CONTEXT §6; none was refuted. They also found 16 new discrepancies (D-22 to D-37). The most serious are silent: Firth with `threads > 1` stops after 1 to 5 iterations with beta off by up to 0.57 (D-05); interval tables attach intervals to the wrong providers when IDs are not numeric (D-19, 61 of 100 providers in the example); invalid `threads` or `backtrack` values return unfitted estimates (D-22, D-23); and the default stopping rule can leave provider effects 0.04 logit units from convergence at n = 1.2M (D-24).
- **Reproducing the reference is feasible.** Line-by-line R ports of SerBIN, BAN, and Firth reproduce the C++ results with the same iteration counts (beta bitwise, gamma within 2e-15), including clamping and backtracking, so the conventions register is complete for the engines and the brief's preferred Tier 2 strategy (reproduce the iteration path) works.
- **Architecture.** Five layers with one-way dependencies; S3 classes prefixed `pprof_`; a model contract of a few generics plus declared inference capabilities; profiling written once against a per-family specification that keeps the families' different semantics explicit; an Rcpp-free C++ core in `namespace pprof` with one information-block routine; one lme4 adapter.
- **R/C++ boundary, measured.** Keep the logistic engines in C++ (1.6–2.3× faster than an equivalent R port, with far less memory). Move linear FE to direct demeaning in R: the dense centering matrices allocate 4.35 GB for 20 providers of 1,000 observations, while demeaning needs 1.8 MB and agrees to 1.5e-14.
- **Dependencies.** The install tree shrinks from 131 packages to 38.
- **Open questions.** 16 questions for the methodology owners (§M), each with a default that reproduces the reference.

---

## A. Current-state assessment

### A.1 Worth keeping

- **The methodology.** SerBIN's block-structured Newton step, BAN, the exact Poisson-binomial mid-p test, the modified score test, indirect and direct standardization with family-specific semantics, test-based funnel limits, and the Firth correction implemented on the same block structure. Phase 0 found independent agreement where it could be checked: Firth matches `logistf` with provider indicators to 2e-11 (V12.5), linear FE matches `lm()` to 2e-14 (V14.1), and the RE fits are exactly the lme4 calls (V15.1).
- **The numerical kernels.** The C++ is compact and follows a clean mathematical specification: R ports written from the conventions register reproduce it exactly (V10.1–V10.3, V12.1).
- **Determinism.** With one thread every fit is bitwise reproducible, and the bootstrap test draws from the user's RNG stream in a fixed order (V13.3).
- **Interface parity.** The three input formats give bitwise-identical estimates (V10.11).
- **Delegation to lme4** for random and correlated random effects.

### A.2 Duplicated or poorly organized

- Input parsing, screening, sorting, and design-matrix construction are copied into all seven fitting functions; `logis_firth()` repeats about 150 lines of `logis_fe()` verbatim, including its bugs (D-01).
- The block information matrix is computed in eight places: SerBIN, BAN's β step, `logis_fe_var`, `wald_covar`, `Modified_score`, Firth (twice), and again in R in `summary.logis_fe(test = "score")`. Each copy handles weights slightly differently (K-13, K-20, K-31, K-66).
- The p-value and flag logic for three alternatives is copied about 30 times across `test`, `confint`, and `summary` files.
- Post-estimation methods re-derive provider sizes and sums from `data_include` with `split()` on every call, and `confint.logis_fe(option = "SM")` calls the provider-interval routine once per provider, re-splitting the whole data set each time.
- The RE and CRE method files are near copies of each other; a `diff` of `confint.logis_re.R` and `confint.logis_cre.R` differs only in class names and labels.
- About 755 lines of commented-out code, including a pure-R SerBIN/BAN that differs from the C++ (BAN with t = 0.8, inclusion with `>`).

### A.3 Inconsistent naming

- Model names mix abbreviations (`logis_fe`, `SM_output`) and stringly typed metadata (`char_list`, `Y.char`, `ProvID.char`, attributes `"provider size"`, `"description"`, `"model"`).
- The same concept has different names: provider effects are `gamma` in FE models and `alpha` in RE models, and `confint()` selects them with `option = "gamma"` or `option = "alpha"`; column names alternate between `gamma.lower` and `gamma.Lower`; `parm` means providers in `test()` and covariates in `summary()`.
- Equivalent arguments are in different orders in `logis_fe()` and `linear_fe()`.
- Argument names shadow base functions (`stop`, `message`), and the exported generic `test()` collides with `devtools::test()` (V16.3).

### A.4 R and C++ responsibilities mixed

- C++ prints progress with `Rcout` and raises R errors with `Rcpp::stop`, including inside OpenMP regions (Firth).
- C++ validates the stopping-rule string, after one iteration has already run.
- R recomputes the log-likelihood the C++ already computed, and copies data into matrices for each call.

### A.5 Statistics mixed with data manipulation

- Each fitting function also screens providers, builds the design matrix, computes the AUC, and assembles a large output object including the whole processed data.
- Post-estimation methods reach into `data_include` by column name and recompute what the fit already knew.
- `confint.logis_fe` mixes standardization, test inversion, and result ordering in one function, which is where D-19 and D-29 come from.
- The CRE decomposition runs through dplyr inside the fit, before complete-case filtering (D-13).

### A.6 Unnecessarily complex C++

- Firth runs one large OpenMP region with critical sections, chunk counters, and thread-private state shared across `omp single` blocks: the source of D-05.
- Two parallel frameworks (OpenMP and an unused RcppParallel/TBB worker); nested OpenMP regions in `computeDirectExp`.
- Dead exports: `wald_covar`, `compute_profilkd_linear`, `Loglkd_firth`, `info_beta_tbb`, `modString`.
- `using namespace` for Rcpp, RcppParallel, std, and arma at global scope; `myomp.h` and `configure.txt` copied from data.table.

### A.7 Performance-critical code (measured)

| Component | Measurement | Evidence |
|---|---|---|
| `logis_fe()` | 0.69 s at n = 80k, 2.8 s at n = 300k; the C++ engine is about a quarter of that (26% and 25%), the R wrapper the rest | B1 |
| `linear_fe()` | 5.1 s and 4.35 GB allocated for 20 providers × 1,000 (grows with Σn_i²) | B2 |
| Direct standardization | 2.8 s for m = 1,000, n = 80k (m·n logistic evaluations) | B3 |
| Provider intervals | 3.2 s (`option = "gamma"`) and 4.7 s (`option = "SM"`) for 400 providers of about 60 | B4 |
| Standard score test | O(m·n·p²): recomputes the full β block for every provider | B4, code |
| Covariate LR and score tests | two refits per covariate | V13.19 |

### A.8 Unnecessary dependencies

`caret` (72 recursive dependencies) and `olsrr` (94) serve one function each inside `data_check()`; `pROC` only computes the AUC, which equals the rank-based Mann–Whitney estimate (V10.15); `RcppParallel` supports only dead code yet forces `SystemRequirements: GNU make`; `globals` is imported to silence a check note; `Matrix` provides only `bdiag()`; `dplyr`, `tidyselect`, and `magrittr` serve the CRE decomposition and plot data handling. Together the current imports pull 131 packages into the install tree (V16.5). Attaching pprof prints a message from `car`, loaded through `olsrr` (V16.4).

### A.9 Public behavior that matters

The full specification is [BEHAVIOR_SPECS.md](BEHAVIOR_SPECS.md). The parts most easily broken by a rewrite are: the iteration path of the logistic engines at default settings (K-16, K-17, K-19); screening and the treatment of no-event and all-event providers (K-06, K-15); the family-specific numerators of standardized measures (K-80 to K-84); the test-inversion brackets and the use of α rather than α/2 for extreme providers (K-90); α computed as `1 - level` (K-61); provider order (K-05); the bootstrap draw order (K-64); and the output shapes the compatibility wrappers must keep (BEHAVIOR_SPECS §16).

### A.10 Candidates for reusable infrastructure

| Infrastructure | Replaces |
|---|---|
| Data preparation: formula, model frame, design matrix, provider index, provider table | seven copies |
| Screening as a parameterized step | two copies (FE logistic, Firth) |
| One C++ information-block routine taking the weights each caller uses | eight copies |
| Provider-level sums through an integer provider index (`rowsum()` in R, offsets in C++) | `split()`/`by()` in every method |
| One p-value-and-flag helper per alternative | about 30 copies |
| One test-inversion helper reproducing the `uniroot()` brackets | six copies |
| One standardization engine driven by a family specification | six `SM_output` methods |
| One lme4 adapter | four fitting functions and their methods |
| Result-object constructors with `tidy()` methods and plot building blocks | ad hoc data frames and attributes |

---

## B. Proposed architecture

### B.1 Layers and dependency rules

```
 presentation  print, format, summary printing, tidy/glance/augment, plot_*()
      ^          consumes result objects only
 profiling     provider_effects(), test_providers(), standardize_providers(),
      ^          profile_providers(), funnel_limits()   [written once, driven by a family spec]
 inference     provider tests, coefficient tests, test inversion, p-values and flags
      ^          [uses the model contract only]
 model         fit_*() functions, engines (C++ adapters, lme4 adapter), constructors and validators
      ^
 data          formula and provider parsing, model frame, missing data, design matrix,
                 provider index and order, screening, within-between decomposition
```

Shared utilities sit beside the layers and may be used by all of them: classed conditions, the verbosity helper, named constants, and argument validators.

Rules:

1. A layer calls only layers below it and the shared utilities.
2. Profiling and inference read models only through the model contract (§E.1), never through fields such as `fit$response`. This is what lets a new model plug in without editing them.
3. Presentation reads only result objects (`pprof_provider_tests`, `pprof_measures`, `pprof_profile`, `pprof_funnel`, `pprof_summary`, `pprof_coefficient_tests`), never model internals or string attributes.
4. Numerical code (data, model, inference, profiling) uses base R vectors, matrices, lists, and data frames. Tidyverse packages may appear only in presentation code.
5. Thread counts come only from a `threads` argument, default 1, passed down explicitly.

An architecture test (`tests/testthat/test-architecture.R`, Phase 2) parses `R/` and checks that files of each layer call only functions of their own or lower layers, using the file prefixes of NAMING.md §8. It keeps rules 1–3 from eroding.

### B.2 R modules

| Layer | Files (NAMING.md §8) | Responsibilities |
|---|---|---|
| Shared | `R/pprof-package.R`, `R/constants.R`, `R/conditions.R`, `R/messages.R`, `R/validate.R`, `R/results.R` | named conventions (§K), classed conditions (NAMING.md §6), the single verbosity helper, argument validators, result constructors and validators (moved from the profiling layer in Phase 2, DEC-027) |
| Data | `R/data-prepare.R`, `R/data-formula.R`, `R/data-frame.R`, `R/data-providers.R`, `R/data-screening.R`, `R/data-decompose.R`, `R/data-class.R`, `R/data-bundled.R` | `pprof_data` objects: parsed formula and `terms`, response, design matrix with `assign` and contrasts, provider index (integer), provider levels in the reference order (K-05), provider table, screening indicators (K-06), row map back to the input data, CRE decomposition in the reference order (K-54) |
| Model | `R/model-class.R`, `R/model-contract.R`, `R/model-capabilities.R`, `R/model-logistic-fe.R`, `R/model-logistic-firth.R`, `R/model-linear-fe.R`, `R/model-mixed.R`, `R/model-logistic-re.R`, `R/model-linear-re.R`, `R/model-logistic-cre.R`, `R/model-linear-cre.R` | fit functions, engines, `new_pprof_model()`/`validate_pprof_model()`, contract methods, capability declarations, standard methods (`coef`, `vcov`, `nobs`, `logLik`, `fitted`, `residuals`, `predict`, `formula`) |
| Inference | `R/inference-pvalues.R`, `R/inference-exact.R`, `R/inference-score.R`, `R/inference-wald.R`, `R/inference-invert.R`, `R/inference-coefficients.R` | p-value and flag rules (K-61, K-63), exact Poisson-binomial and bootstrap tests (K-62, K-64), score tests (K-65, K-66), Wald tests, `uniroot()` inversion with the reference brackets (K-90), covariate Wald/LR/score tests (K-100 to K-105) |
| Profiling | `R/profile-spec.R`, `R/profile-effects.R`, `R/profile-tests.R`, `R/profile-standardize.R`, `R/profile-intervals.R`, `R/profile-funnel.R`, `R/profile-providers.R`, `R/profile-summaries.R` | family specifications (§B.4), the profiling API, the summaries that plots draw (K-112, K-113; Phase 6, DEC-056) |
| Presentation | `R/present-print.R`, `R/present-summary.R`, `R/present-tidy.R`, `R/plot-funnel.R`, `R/plot-caterpillar.R`, `R/plot-flags.R`, `R/plot-volume.R`, `R/plot-blocks.R` | printing, `tidy`/`glance`/`augment`, ggplot2 plots built from result objects and shared building blocks (Phase 6, DEC-058) |
| Diagnostics | `R/check-data.R` | `check_data()` (DEC-010) |
| Compatibility | `R/compat-fits.R`, `R/compat-methods.R`, `R/compat-plots.R`, `R/compat-data-check.R`, `R/compat-convert.R`, `R/compat-deprecate.R` | old names, translation, old output shapes, once-per-session deprecation (§I) |

As built through Phase 4: the model layer has the files listed, and `R/model-methods.R` for the standard methods that every model shares (Phase 3). The compatibility layer has `R/compat-fits.R` (the seven fitting functions of pprof 1.0.3), `R/compat-methods.R` (the methods of `logis_fe` objects, which Firth fits share, and the print methods of the RE and CRE objects), `R/compat-plots.R`, and `R/compat-convert.R`. `R/check-data.R`, `R/compat-data-check.R`, `R/compat-deprecate.R`, and `R/pprof-package.R` come in later phases; the reference's `R/pprof.R` still declares `useDynLib`. The methods of the linear, RE, and CRE objects are still the reference's files until Phase 5 (DEC-040).

As built in Phase 5 (step 3): the methods of `linear_fe`, `linear_re`, `logis_re`, `linear_cre`, and `logis_cre` objects are compatibility methods over the new API (DEC-049): `R/compat-methods-linear-fe.R` (`test()`, `SM_output()`, `confint()`, `summary()`), `R/compat-methods-mixed.R` (the same four for the four RE and CRE classes), and `plot.linear_fe()` in `R/compat-plots.R`, with the reference's `ppfunnel_linear()` unchanged (DEC-034). The generics `test()` and `SM_output()` moved unchanged to `R/compat-generics.R` (DEC-045). `R/compat-convert.R` rebuilds a model from an old object (`compat_model_from_linear_fe()`, `compat_model_from_mixed()`) and builds the old result shapes. The 23 reference method files are gone; the reference's files left in `R/` are `Data.R`, `RcppExports.R` (generated), `bar_plot.R`, `caterpillar_plot.R`, `data_check.R`, and `pprof.R`, which the architecture test lists as legacy (DEC-031).

As built in Phase 6: the profiling layer gained `R/profile-summaries.R` (the interval flags and reference values of K-112, the size groups and flag shares of K-113; DEC-056), which the new plots and the compatibility wrappers of the old ones share. The presentation layer's plots are built from `R/plot-blocks.R` (one flag scale, the reference line, interval ends, subtitles from the results' settings, the theme; DEC-058), which replaces `R/plot-theme.R`, and `R/plot-volume.R` adds the volume panels (DEC-059). `caterpillar_plot()` and `bar_plot()` moved to `R/compat-plots.R` (DEC-055); the reference's files left in `R/` are `Data.R`, `RcppExports.R` (generated), `data_check.R`, and `pprof.R`.

As built in Phase 7: the documentation of the bundled data sets moved from the reference's `R/Data.R` to `R/data-bundled.R` (documentation only, no code; D-35 fixed), and `R/pprof-package.R` holds the package's help page, `?pprof`. The reference's files left in `R/` are `RcppExports.R` (generated), `data_check.R`, and `pprof.R`. The user documentation is in `vignettes/` (five vignettes, built and checked by `R CMD check`, DEC-062), `README.md`, and the pkgdown configuration `_pkgdown.yml`; the site is built by CI and no longer committed (DEC-066).

As built in Phase 8: `R/check-data.R` holds `check_data()` and the base-R versions of caret's near-zero-variance rule and olsrr's variance inflation factors that it and `data_check()` use (DEC-073); `R/compat-data-check.R` is `data_check()` over them; `R/compat-deprecate.R` holds the table of the twelve old names with their replacements and `compat_deprecate()` (DEC-072); `R/pprof-package.R` also carries the package's directives (`useDynLib`, and the imports of Rcpp and `plogis`). The reference's `R/data_check.R` and `R/pprof.R` are gone, so the only file of the reference left in `R/` is the generated `RcppExports.R`.

### B.3 C++ modules

```
src/
  rcpp_logistic.cpp          Rcpp adapters: cpp_logistic_fe_serbin(), cpp_logistic_fe_ban(),
                             cpp_logistic_firth(), cpp_logistic_variance(),
                             cpp_logistic_score_standard(), cpp_logistic_direct_expected(), and
                             cpp_logistic_firth_log_determinant() (tests only)
  RcppExports.cpp            generated
  core/
    armadillo.h              the one Armadillo configuration of the core: BLAS and LAPACK, 32-bit words,
                             Armadillo's own OpenMP and warnings off, output to a discarding stream (DEC-035)
    constants.h              named conventions (§K): weight floors, clamps, Armijo constants, initial criteria
    types.h                  StopRule, IterationCriteria, FitSettings, FitResult
    provider_layout.{h,cpp}  offsets from provider sizes; per-provider sums
    information_blocks.{h,cpp}  diagonal, cross block, beta block, Schur complement, and the variance
                             diagonal; weights passed in by the caller
    loglik.{h,cpp}           logistic log-likelihood (K-11)
    clamp.h                  provider-effect clamp (K-15)
    line_search.h            Armijo backtracking (K-14), a template over the gain function
    convergence.{h,cpp}      stopping criteria and rules (K-16)
  logistic/
    serbin.{h,cpp}  ban.{h,cpp}  variance.{h,cpp}  score_test.{h,cpp}  direct_expected.{h,cpp}
    firth.{h,cpp}
  Makevars, Makevars.win     every subdirectory object listed in OBJECTS; OpenMP flags; plain `=`
                             assignments, so no GNU make is needed (Phase 4)
```

As built in Phase 3, OpenMP regions are written in place with `num_threads(threads)` clauses rather than through a `parallel.h`, and the engines report a failed solve or inversion by throwing outside any parallel region: Rcpp's generated wrappers turn the exception into an R error, which the model layer reclasses as `pprof_error_convergence` (`logistic_fe_engine_call()`). Inside parallel regions only bool-returning Armadillo functions are used, and a failure sets a flag (the standard score test's `failed`).

As built in Phase 4, `logistic/firth.{h,cpp}` reproduces the reference's `logis_firth_prov()` operation by operation in the order it computes with one thread (K-30 to K-33): each provider's blocks, hat values, and modified score are computed in parallel into the provider's own slots, and every sum over providers (the Schur complement, the covariate score) is then added in provider order, so the results do not depend on the thread count (D-05). The Schur complement is inverted and its log-determinant taken outside the parallel regions, and a failure throws there (D-42). The block routine gained `provider_blocks()`, which Firth calls with its 1e-10 weight floor (K-31). With `src/Firth.cpp` gone, RcppParallel and its `$(shell ...)` lines left the build.

As built in Phase 5 (step 3): no reference C++ is left. The logistic RE and CRE methods take their direct expectations from `cpp_logistic_direct_expected()`, which equals the reference's `computeDirectExp()` on their inputs (F5 of the Phase 5 plan), so `src/Fixed_effect.cpp`, `src/header.{h,cpp}`, and `src/myomp.h` were removed with their objects in both Makevars files. `RcppExports.cpp` still includes `RcppArmadillo.h`, because `Rcpp::compileAttributes()` adds it for every LinkingTo package that has a header of its name, so the Makevars keep DEC-035's settings for every translation unit (DEC-052).

As built in Phase 8: the core and the adapters are formatted with clang-format (`.clang-format`: Google style, 120 columns, nothing sorted or reflowed, DEC-078), in a commit that changed only whitespace, and CI checks the format; `RcppExports.cpp` is generated and left alone.

Contracts of the core:

- No Rcpp headers, R API, `Rcout`, or `Rcpp::stop`. Inputs and outputs are Armadillo and standard types; every engine returns a result struct with `status`, `iterations`, every stopping criterion's final value, and the estimates.
- One information-block routine serves fitting, variance, both score tests, and Firth. Because the reference uses different weights in different places (floored diagonal with unfloored cross block in SerBIN; clamped probabilities in the variance; null weights for one provider in the standard score test; 1e-10 floor everywhere in Firth), the routine takes the weight vectors as arguments instead of choosing them. Each caller passes exactly what the reference used. This removes the duplication without homogenizing the conventions.
- To keep the iteration path, the core performs the same floating-point operations as the reference where the order matters: the same BLAS product for the β block with one thread, the same `arma::solve` options (`likely_sympd` in SerBIN, `fast + likely_sympd` in BAN), and `inv_sympd` for variances. The R ports show this is enough to reproduce the path (V10.1).
- Parallel regions never call the R API, never let an exception escape (failures set a status flag), and keep all shared state explicit (the D-05 pattern is impossible by construction). `threads > 1` must match `threads = 1` within the Tier 2 tolerance.
- Errors surface as status values; the adapter converts them into R conditions (`pprof_error_convergence` and friends) after the core returns.

### B.4 How family differences are parameterized

The profiling layer is written once and reads a family specification returned by the contract generic `profile_spec(model)`. The reference's family differences become data in this table instead of code paths scattered over 24 methods:

| Family | Effect | Null options (default) | Indirect numerator | Expected under the null | Indirect measure | Direct reference total | Measures | Provider tests | Interval types |
|---|---|---|---|---|---|---|---|---|---|
| Logistic FE, Firth | γ | median, number ("median") | observed Σy | Σ plogis(γ0 + Zβ) | ratio O/E, rate | Σy | ratio, rate | exact, bootstrap, score (modified, standard), Wald | exact, score, Wald |
| Linear FE | γ | median, mean, number ("median") | observed Σy | Σ(γ0 + Zβ) | difference (O − E)/n_i | Σ(γ0 + Zβ) | difference | Wald (z or t by `provider_variance`, K-68) | Wald (t or z, K-92) |
| Logistic RE, CRE | α | number (0) | predicted Σ fitted | Σ plogis(Xβ) | ratio, rate | Σy | ratio, rate | Wald (conditional SD) | Wald |
| Linear RE | α | number (0) | predicted Σ fitted | ΣXβ | difference | Σy | difference | Wald (closed-form SD, K-69) | Wald |
| Linear CRE | α | number (0) | predicted Σ fitted | ΣXβ | difference | Σy | difference | Wald (conditional SD, K-70) | Wald |

Sources: K-60, K-68 to K-70, K-80 to K-84, K-92, K-93. The rows differ where the reference differs, including in places that look like accidents (linear RE uses a closed-form SD where linear CRE uses lme4's; D-31 and D-32 are reproduced in the compatibility layer and flagged for sign-off).

As built in Phase 3 (logistic FE; NAMING §5 lists the fields): `profile_spec()` returns a list with `family`, `effect`, `null_default`, `null_options`, `indirect_numerator`, and `measures`, and, where a family supports them, `mean_function` and `variance_function` (measure intervals and the null variance of indirect standardization), `direct_expected` (a function of the effects, the linear predictor, and the thread count; the C++ direct expectations for logistic models), `funnel` (`measure`, `target`, `floor`, `test`, and the functions `precision` and `half_width`, so that the logistic funnel's E²/V and sqrt(1/w) and the linear funnel's n_i and σ/sqrt(n_i) are both data), and `wald_caution` (DEC-037). The exact, bootstrap, modified score, and Wald provider tests are computed by the profiling layer from the contract; `provider_test()` serves the tests that need a model's internals, such as the standard score test (DEC-036).

As built in Phase 5 (DEC-046; the values per family are the table in `dev/design/PHASE5_PLAN.md`, step 2): the specification gains optional fields whose defaults are the behavior of logistic fixed effects, so a family states only where it differs: `test_default` (DEC-047), `comparison` (ratios O/E and E/total, or differences (O − E)/n_i and (E − total)/n), `direct_reference` (Σy, or Σ(γ0 + Zβ) for linear FE, K-83), `direct_limits` (R's sums of the mean function, or the family's direct expectation: logistic RE and CRE use the C++ routine, whose last bits differ from R's sums), `one_sided_extremes` (logistic FE only, K-91), `wald` (the distributions of the provider tests and intervals: t(n − m − p) for linear FE tests with the full variance and intervals with the simplified one, D-32), and `coefficient_wald` (the covariate p-value form, including D-31's 2(1 − Φ(z)), its distribution and degrees of freedom, and the interval form: β ∓ q·se, or lme4's β + se·Φ⁻¹(a), which reproduces `confint(method = "Wald")` bitwise without the lme4 fit). The predicted numerator of RE indirect measures (K-82, K-84) is read through the contract generic `predicted_outcome()`, which returns lme4's fitted values for `pprof_mixed`. The inference layer owns the default of `coefficient_wald`, and the profiling layer those of the other fields, so neither reaches into the other (§B.1). The new API reproduces D-31, D-32, D-43, and M-14 until the methodology owners decide. Where lme4 estimates the provider variance as 0, the RE and CRE effects and their standard deviations are 0, and the Wald tests have NaN statistics and p-values and missing flags, as in the reference (`dev/design/phase5-facts/09_singular_re_fits.R`).

### B.5 A fit and a profile, step by step

`fit_logistic_fe(formula, data, provider, method = "serbin", ...)`:

1. Validate arguments at the boundary (`pprof_error_invalid_input`).
2. `data_prepare()` builds a `pprof_data` object: model frame from `terms()`, listwise deletion on the used columns, design matrix with `model.matrix()` (K-04), provider index in the reference order (K-05), provider table, screening with `min_provider_size` (K-06).
3. The engine calls the C++ adapter with the response, design, provider sizes, and starting values (K-10), and gets estimates, iterations, criteria, and status.
4. The variance routine (same information-block code) gives Var(β) and Var(γ) (K-20).
5. Log-likelihood, AIC, BIC, AUC (K-11, K-21, K-22).
6. `new_pprof_logistic_fe()` builds the compact object (§D) and `validate_pprof_logistic_fe()` checks it.

`test_providers(fit, test = "exact", null = "median", level = 0.95, alternative = "two.sided")`:

1. `require_capability(fit, "provider_exact")`.
2. `null_effect(fit, "median")` gives γ0; `expected_outcome(fit, γ0)` gives p0 per observation.
3. The inference helpers compute the mid-p probabilities, p-values, statistics, and flags per provider (K-62, K-63), in provider order.
4. `new_pprof_provider_tests()` returns a table keyed by `provider_id` plus the settings used.

---

## C. Naming convention

Specified in [`dev/NAMING.md`](../NAMING.md): principles, abbreviation whitelist, function patterns (`fit_<outcome>_<effects>()`, `test_providers()`, `standardize_providers()`, `profile_providers()`, `plot_<kind>()`), the argument vocabulary table with types and defaults, class and field names, condition classes, C++ conventions (`namespace pprof::<module>`, PascalCase types, `k`-prefixed constants, `cpp_` adapter prefix), and file names. Highlights:

- The provider is a `provider = "<column>"` argument used identically by every family (DEC-003); covariates and the response come from one formula grammar parsed with `terms()`.
- `confint()` returns covariate intervals as everywhere else in R; provider-level intervals come from `provider_effects()` and `standardize_providers()` (`interval = "exact"`, `"score"`, `"wald"`).
- Historical abbreviations (`logis`, `SM`, `stdz`, `relch`, `ratch`, `Y.char`, `ProvID.char`) are replaced; the compatibility wrappers translate them.

---

## D. Model-object design

### D.1 Components

A model object is a list with class `c("pprof_<family>", ["pprof_mixed",] "pprof_model")`.

| Field | Content | Size | Needed by |
|---|---|---|---|
| `call`, `formula`, `terms` | as in base R; `terms` carries contrasts and factor levels | small | printing, `predict`, rebuilding data (D.2) |
| `spec` | family, method, every setting (`max_iter`, `tol`, `stop_rule`, `backtrack`, `effect_bound`, `min_provider_size`, `provider_variance`, lme4 arguments), `keep_data` | small | refits, reproducibility, compatibility wrappers |
| `providers` | data frame: `provider_id` (character), the original ID values, `n_obs`, `n_events` (binary), `included`, `no_events`, `all_events` | O(m), excluded providers included | every provider-level method |
| `coefficients`, `vcov` | β and its covariance | O(p²) | `coef`, `vcov`, `confint`, Wald tests |
| `provider_effects`, `provider_effect_variance` | γ (or α) and its variance, in provider order | O(m) | profiling |
| `response` | outcome per included observation (integer for binary outcomes) | 4n or 8n bytes | tests, measures |
| `linear_predictor` | Zβ (or Xβ with intercept) per included observation | 8n | expected outcomes, intervals |
| `provider_index` | integer index into `providers` per included observation | 4n | provider sums |
| `row_index` | input row of each included observation | 4n | `augment()`, rebuilding data (D.2) |
| `fitted` | RE/CRE only: lme4's fitted values (the reference numerator, K-82, K-84) | 8n | RE standardization |
| `provider_effect_sd` | RE/CRE only: conditional SD of α (K-69, K-70), computed once at fit time | O(m) | RE tests and intervals |
| `variance_components` | RE/CRE only: σ²_α, σ | small | RE methods |
| `loglik`, `aic`, `bic`, `auc`, `sigma` | fit statistics as defined per family | small | `logLik`, `glance` |
| `convergence` | `iterations`, `converged`, every criterion's final value, `stop_rule`, `tol`, `max_iter`, `status` | small | diagnostics (new, additive, brief §5.2) |
| `n_obs`, `n_providers`, `n_excluded_providers`, `n_excluded_obs` | dimensions | small | printing, `nobs` |
| `package_version` | pprof version that built the object | small | reproducibility |
| `data` | only with `keep_data = TRUE`: the `pprof_data` object including the design matrix | 8np + … | covariate-level methods (D.2) |
| `engine_fit` | only with `keep_data = TRUE`, RE/CRE: the merMod | large | users who want lme4 methods |

Fitted values and residuals of FE models are not stored: they are recomputed as `plogis(provider_effects[provider_index] + linear_predictor)` (or the identity for linear models), the same expression the reference evaluates, so the result is bitwise identical.

Memory budget with `keep_data = FALSE`: per observation, 4 bytes of provider index, 4 of input-row index, 8 of linear predictor, and 4 (binary) or 8 (continuous) of response, so at most 24 bytes for FE models and 32 for RE/CRE models (which also keep lme4's fitted values); plus O(m) for the provider table and effects and O(p²) for the covariance, independent of the number of covariates. The design matrix adds 8np bytes and is kept only on request. Measured on simulated logistic FE fits with p = 10 (B5; the compact measurement omits the 4-byte row index):

| n | m | Reference object | of which `data_include` | of which `fitted` and `linear_pred` (character row names) | Proposed compact fields | Design matrix, only with `keep_data = TRUE` |
|---|---|---|---|---|---|---|
| 79,779 | 1,000 | 19.9 MB | 8.5 MB | 11.0 MB | 1.4 MB | 6.1 MB |
| 300,166 | 3,000 | 74.9 MB | 32.1 MB | 41.2 MB | 5.1 MB | 22.9 MB |

The reference object is about 15 times larger, mostly because of `data_include` and the "1".."n" character row names on two n × 1 matrices.

As built in Phase 4 (NAMING §5 lists the fields):

- Firth models keep every logistic FE field, with the unpenalized variances and statistics at the Firth estimates (D-12), and add `penalized_loglik`; their convergence history holds the criterion and the penalized log-likelihood of every iteration.
- Linear FE models keep `sigma` and `provider_effect_variance`, whose formula `spec$provider_variance` records (D-16); they screen no provider.
- RE and CRE models (`pprof_mixed`) keep `fitted`, `provider_effect_sd`, `variance_components` (`provider`, as the reference reports it under K-51, and `residual_sd` for linear models), `loglik_df` (lme4's degrees of freedom), `sigma` for linear models, and with `keep_data = TRUE` the merMod as `engine_fit`. They store no `provider_effect_variance`; their provider effects are lme4's conditional modes. Their `convergence` holds lme4's optimizer and its code, lme4's convergence messages, whether the fit is singular, and the messages lme4 printed; their `spec` holds the outcome, the engine, `within_between`, and the `...` passed to lme4 as `engine_arguments`.

### D.2 Methods that need the covariates

Most provider-level methods need only the linear predictor, the response, and the provider index: exact and bootstrap tests, the modified score test, standardization, intervals, and funnel limits. Three need the covariates themselves: the standard provider score test (K-66) and the covariate LR and score tests (K-101, K-102).

Decision (DEC-005, proposed): objects do not keep the design matrix by default. Those three methods take a `data` argument. If the object was fit with `keep_data = TRUE` they use the stored design; otherwise they rebuild it from `data` with the stored `terms`, provider column, and settings, and verify that the rebuilt data match the fit (same included rows in the same order, same provider index, and the recomputed Zβ equal to the stored linear predictor within the Tier 1 tolerance) before proceeding. Without either, they fail with `pprof_error_data_required`. The compatibility wrappers fit with `keep_data = TRUE`, because the old methods never asked for data.

Alternatives considered: always keeping the design matrix (simple, but brief §5.2 asks for compact objects and most methods never use it); recomputing from `call` and the caller's environment (fragile and unauditable).

### D.3 Standard and pprof-specific methods

| Method | Behavior |
|---|---|
| `print` | compact description: family, method, n, providers kept and excluded, convergence, first coefficients |
| `summary` | returns `pprof_summary` (numeric coefficient table with the family's test and interval rules, K-100 to K-105, and model information); `print.pprof_summary` formats p-values for display only |
| `coef`, `vcov` | β and its covariance |
| `confint` | covariate intervals with the family's rule (normal for logistic FE and Firth, t for linear FE, lme4 Wald for RE/CRE; K-100, K-103 to K-105) |
| `predict` | linear predictor or response scale for `newdata` that contains the provider column; providers absent from the fit give NA with a warning |
| `fitted`, `residuals` | per included observation, in input order through `row_index` |
| `nobs`, `logLik`, `formula` | as in base R; `logLik` carries the family's degrees of freedom (m + p logistic FE, m + p + 1 linear FE, lme4's for RE) |
| `tidy`, `glance`, `augment` | through `generics`: coefficient table; one-row fit summary including convergence; per-observation fitted values keyed by input row |
| `provider_effects()`, `test_providers()`, `standardize_providers()`, `profile_providers()`, `funnel_limits()`, `test_coefficients()` | the pprof API (§B.1); each returns a result object with a `table` keyed by `provider_id` (or coefficient) and the settings used |

Result objects are lists with a validated `table` (a base data frame) and named fields for settings (`level`, `alternative`, `null_value`, `standardization`, `measure`, `population_rate`, family). Plots read these fields; they never parse attributes. `tidy()` on a result object returns its table as a tibble.

---

## E. Extension architecture

### E.1 The model contract

The inference and profiling layers rely on these generics only:

| Generic | Returns | Used by |
|---|---|---|
| `provider_table(model)` | provider data frame (§D.1) | everything provider-level |
| `provider_estimates(model)` | named effect estimates (γ̂ or α̂) in provider order | profiling, Wald tests and intervals |
| `provider_index(model)` | integer index per observation | provider sums |
| `linear_predictor(model)` | covariate linear predictor per observation | expected outcomes |
| `observed_outcome(model)` | outcome per observation | tests, standardization |
| `expected_outcome(model, effect)` | expected outcome per observation given a provider effect (a scalar or a vector indexed by provider) | tests, standardization, intervals |
| `predicted_outcome(model)` | the model's prediction per observation with its own provider effects (lme4's fitted values for random-effect models; added in Phase 5, DEC-046) | indirect standardization of families whose numerator is `"predicted"` (K-82, K-84) |
| `null_effect(model, null)` | the numeric null value for a `null` choice | tests, standardization |
| `profile_spec(model)` | the family specification of §B.4 | profiling |
| `inference_capabilities(model)` | character vector of supported inference | capability checks |
| `provider_estimate_se(model)` | standard errors of the effects (when Wald inference is declared) | Wald tests and intervals |
| `provider_test(model, test, ...)` | per-provider probabilities and statistics for a declared test | `test_providers()` |
| `refit_without(model, covariates, data)` | null fit for covariate LR and score tests (when declared) | `test_coefficients()` |

Logistic models share one implementation of `expected_outcome()` (plogis of effect plus linear predictor) and of `provider_test()`; linear models share theirs; mixed models share an lme4 implementation through the `pprof_mixed` class. Each family overrides only what differs.

### E.2 What a fit function must do

1. Validate arguments with the shared validators.
2. Build its data through `data_prepare()`, passing its screening rule, if any.
3. Call its estimation engine.
4. Build the object with `new_pprof_model(subclass = ..., ...)`, which fills the shared fields and checks them, and add family-specific fields.
5. Declare its capabilities with a method for `inference_capabilities()`.
6. Implement the contract generics that differ from the shared defaults.

### E.3 Capabilities

Capability names: `coef_wald`, `coef_lr`, `coef_score`, `provider_exact`, `provider_bootstrap`, `provider_score`, `provider_score_standard`, `provider_wald`, `interval_exact`, `interval_score`, `interval_wald`, `standardize_indirect`, `standardize_direct`, `funnel`. Every entry point calls `require_capability(model, name)` first; a model that does not declare the capability gets `pprof_error_unsupported_inference`, naming the model class and the capability. A model never receives a request it has not declared, so a penalized model cannot return a Wald number by accident.

| Capability | Logistic FE | Firth | Linear FE | Logistic RE/CRE | Linear RE/CRE |
|---|---|---|---|---|---|
| coef_wald | yes | yes | yes | yes | yes |
| coef_lr, coef_score | yes | yes (D-12, M-2) | no | no | no |
| provider_exact, provider_bootstrap, provider_score, provider_score_standard | yes | yes | no | no | no |
| provider_wald | yes | yes | yes | yes | yes |
| interval_exact, interval_score | yes | yes | no | no | no |
| interval_wald | yes | yes | yes | yes | yes |
| standardize_indirect, standardize_direct | yes | yes | yes | yes | yes |
| funnel | yes (score-test limits, K-110; exact limits unsupported, D-07) | yes | yes (normal limits, K-111) | no | no |

The table mirrors exactly what the reference offers per class; it adds no inference.

As built in Phase 4 (DEC-040): Firth models have the logistic FE capabilities through their class, as the table shows. Linear FE, RE, and CRE models declare none yet (the shared `inference_capabilities.pprof_model()` returns an empty vector); their columns of the table arrive with their inference in Phase 5. Until then every entry point raises `pprof_error_unsupported_inference` for them, including `confint()`, whose method for `pprof_model` checks `coef_wald` so that `stats::confint.default()` cannot answer with normal intervals. The old methods of the reference's linear, RE, and CRE objects are unaffected: they still run the reference's code on the wrappers' objects.

As built in Phase 5 (step 2): linear FE models declare `coef_wald`, `provider_wald`, `interval_wald`, `standardize_indirect`, `standardize_direct`, and `funnel`; the four mixed families the same without `funnel`, exactly the columns of the table. One `confint.pprof_model()` serves every family that declares `coef_wald`, with the family's covariate rule.

### E.4 Registration and the extension proof

A new model is a module: its own `R/model-<name>.R` file (and `src/<module>/` files with an adapter, if it needs C++), roxygen `@export` and `S3method` tags, tests, and documentation. Nothing in the data, inference, profiling, or presentation files changes. The one exception is the build list: new C++ files must be added to `OBJECTS` in `Makevars` and `Makevars.win`.

Phase 2 proves this with a test-only toy model defined in `tests/testthat/helper-toy-model.R`: a binary-outcome model with provider effects and no covariates, fit in closed form, which registers its contract methods and capabilities in the test environment. The tests show that `test_providers()`, `standardize_providers()`, `profile_providers()`, and `plot_funnel()` work on it unchanged, and that an undeclared capability (Wald) raises `pprof_error_unsupported_inference`. Phase 2 implemented the part of this proof that the layers existing then allow (DEC-024): the toy model uses `data_prepare()`, `new_pprof_model()`, the contract generics, and the capability checks, registering its methods with `.S3method()`; each later phase adds its profiling and plotting functions to `test-extension-toy-model.R`.

As built in Phase 7 (DEC-063): the vignette "Adding a model to pprof" (`vignettes/adding-a-model.Rmd`, §E.5) uses this toy model as its worked example, defined and registered in the vignette, with results identical to the test's, and shows registration in another package's NAMESPACE (`@exportS3Method pprof::<generic>`) as well as in pprof.

### E.5 Walk-through: adding Group Lasso

Target model: logistic (or linear) provider fixed effects with a group lasso penalty on the covariate coefficients, minimizing −ℓ(γ, β) + λ Σ_g w_g ‖β_g‖₂, with provider effects unpenalized. Nothing below changes the existing families.

1. **Interface.** `fit_logistic_grouplasso(formula, data, provider, groups = NULL, lambda = NULL, n_lambda = 100, lambda_min_ratio = 1e-3, group_weights = NULL, standardize = TRUE, min_provider_size = 10, effect_bound = 10, tol = 1e-7, max_iter = 10000, threads = 1, verbose = FALSE)`. Arguments shared with other fits keep their vocabulary names.
2. **Data layer, reused unchanged.** `data_prepare()` gives the response, design matrix, provider index, screening. Default groups come from the design matrix's `assign` attribute, so each formula term is one group and a factor's dummy columns stay together; `groups` overrides this.
3. **Covariate standardization.** Inside the module, not the data layer, because it is estimator-specific: center and orthonormalize each group (as grpreg does), keep the transformation, and report coefficients on the original scale.
4. **Engine.** `src/penalized/group_lasso.{h,cpp}`: block coordinate descent alternating a provider-effect step (per-provider Newton using `core/information_blocks` and `core/clamp`) with group-wise proximal steps for β on a local quadratic approximation; a λ path from λ_max (the smallest λ with β = 0, from the provider-only fit) down to `lambda_min_ratio · λ_max`, with warm starts. Adapter `src/rcpp_penalized.cpp` (`cpp_penalized_group_lasso_path()`).
5. **Object.** `c("pprof_logistic_grouplasso", "pprof_model")` with the shared fields plus `lambda` (length L), `coefficient_path` (p × L, original scale), `provider_effect_path` (m × L), `df` per λ (group degrees of freedom), `deviance` per λ, `convergence` per λ, and `selected` (the index of the selected λ, initially NULL).
6. **Coefficient paths.** `coef(fit)` returns the p × L path; `coef(fit, lambda = x)` returns the solution at a grid value, or refits at an off-grid value from the nearest warm start. There is no interpolation, so every reported number is an actual solution.
7. **Selection.** `select_lambda(fit, criterion = c("cv", "bic", "aic"), folds = NULL)` sets `selected` and stores the linear predictor at that λ. The fold design (observations stratified within providers, so every provider effect stays estimable) is a methodology decision for that phase.
8. **Provider profiling at the selected λ.** The contract methods read the selected solution: `provider_estimates()` is γ̂(λ_sel), `linear_predictor()` is Zβ̂(λ_sel), and `expected_outcome()` reuses the logistic implementation. `profile_spec()` is the logistic FE row of §B.4. Standardized measures, exact and bootstrap tests, the modified score test, and exact and score intervals then work unchanged, conditional on the selected covariate fit. Calling them before a λ is selected raises `pprof_error_invalid_input`.
9. **Inference that is not available.** Penalization and selection invalidate the information-based variances, so the model does not declare `coef_wald`, `coef_lr`, `coef_score`, `provider_wald`, `interval_wald`, or `provider_score_standard`. Asking for them raises `pprof_error_unsupported_inference`. Whether the conditional provider tests of step 8 should be offered at all, or flagged as ignoring selection, is decided by the methodology owners when the model is designed; the capability table is where that decision is recorded.
10. **Files added.** `R/model-logistic-grouplasso.R` (fit, constructor, contract methods, capabilities), `R/model-grouplasso-path.R` (`coef`, `select_lambda`, path accessors), `R/plot-coefficient-path.R` (presentation), `src/penalized/group_lasso.h`, `src/penalized/group_lasso.cpp`, `src/rcpp_penalized.cpp`, two `OBJECTS` lines in `Makevars` and `Makevars.win`, `tests/testthat/test-model-logistic-grouplasso.R`, and a developer-guide entry. No existing R file changes. A linear variant adds `R/model-linear-grouplasso.R` with a Gaussian loss in the same engine.

As built in Phase 7 (DEC-063): the developer guide for model authors is the vignette `vignettes/adding-a-model.Rmd`, "Adding a model to pprof". It presents §B.1's layers, §E.2's steps, §E.1's contract with the shared methods as built, the family specification's required and optional fields (§B.4, NAMING §5), §E.3's capabilities with what each needs from a model, the registration of methods (`.S3method()` in a script, `@exportS3Method pprof::<generic>` in another package, `R/model-<name>.R` in pprof), the tests a model needs, compiled code (§E.4's `OBJECTS` lines), and this walk-through, updated to the contract as built (`new_pprof_model()`, the design matrix's `assign` attribute for the default groups, shown in the vignette). Its worked example is §E.4's toy model, run from outside the package on exported functions alone. Contributors to pprof itself have `dev/DEVELOPER_GUIDE.md`.

### E.6 Sketch: a survival model

A Cox model with provider effects, λ_ij(t) = λ0(t) exp(γ_i + z_ij'β), shows that the profiling layer assumes neither binary nor Gaussian outcomes:

- Data: the response is a `Surv` object; the data layer passes it through as an opaque response with n rows. Screening is parameterized, so the module can screen on events rather than size.
- Contract: `observed_outcome()` is the event indicator; `expected_outcome(model, effect)` is the expected number of events given follow-up, Λ̂0(t_ij) exp(effect + z_ij'β) with the Breslow estimate of the cumulative baseline hazard. Indirect standardization (Σ observed / Σ expected under the null) and direct standardization (Σ over all patients of Λ̂0(t_j) exp(γ_i + z_j'β), divided by the total number of events) then come from the same profiling code, because that code only sums observed and expected values by provider.
- Tests: the exact Poisson-binomial test does not apply; the module declares its own capability (for example a Poisson exact test of O_i against E_i) and implements `provider_test()` for it. The funnel precision comes from the family specification's variance function (E_i for Poisson counts).

---

## F. R/C++ boundary

| Component | Reference | Proposed | Evidence | Reason |
|---|---|---|---|---|
| SerBIN and BAN fitting | C++ | C++ core, R orchestration | B1: C++ 0.18 s versus 0.42 s for an R port with identical iterations (n = 80k), 0.70 s versus 1.14 s (n = 300k); the R port allocates 169–632 MB | 1.6–2.3× faster with far less memory; exact control of the iteration path |
| `logis_fe()` wrapper | R | R, restructured | B1: 0.69 s and 2.8 s in total, of which the engine is about 25% | the larger win is removing copies and `split()` passes in R, not C++ work |
| Firth | C++ | C++ | per-observation hat values cost O(np²) per iteration; the R port needed an n × m intermediate | memory and speed; and the race (D-05) must be fixed where it lives |
| Variances (block inverse) | C++ | C++, through the shared information-block routine | brief §5.6 | one tested routine |
| Standard score test | C++ | C++ | O(m·n·p²); 0.29 s at m = 400 (B4) | per-provider β-block recomputation is C++-scale work |
| Direct expectations | C++ | C++ | B3: 2.8 s versus 4.4 s for R `vapply()`, which allocates 1.2 GB | memory |
| Linear FE | R with dense centering | R with direct demeaning | B2: 5.1 s and 4.35 GB versus 2 ms and 1.8 MB; β agrees to 1.5e-14 | O(np) instead of O(Σn_i²), numerically equivalent within Tier 1 (to be confirmed on the fixture suite) |
| Exact Poisson-binomial tests | R (poibin) | R (poibin) | 0.23 s at m = 400 (B4) | not a bottleneck |
| Bootstrap test | R | R | must draw from R's RNG in the reference order (K-64) | moving it would change draws |
| Test inversion | R (`uniroot`) | R (`uniroot`), with per-provider data computed once | B4: 3.2–4.7 s at m = 400, dominated by repeated data splitting and root finding | identical roots require the same `uniroot()` calls; the speed-up is structural |
| Covariate LR and score tests | R | R, one null fit per covariate instead of two | V13.19 | identical numbers at half the cost |
| lme4 models | R | R, one adapter | | brief §2.2 |

Moving anything else across the boundary needs benchmark evidence from the Phase 1 suite in `dev/bench/`. These Phase 0 timings come from one Windows machine with R's reference BLAS and few repetitions; the Phase 1 suite repeats them across scales on CI.

---

## G. Validation strategy

### G.1 Fixture generation (Phase 1)

- **Generator.** `dev/reference/` holds `install_reference.R` (the audit installer, extended to a pinned dependency library), `cases.R` (the case table), `datasets.R` (seeded generators for synthetic data), and `generate_fixtures.R` (runs every case in a separate R session through `callr` with the reference library first on the library path).
- **Pinned environment.** A dedicated library with pprof 1.0.3 and pinned versions of lme4, Matrix, Rcpp, RcppArmadillo, poibin, pROC, caret, olsrr, and their dependencies. The manifest records them together with R, BLAS/LAPACK, OS, compiler, OpenMP availability, collation locale (D-34), thread count, seeds, and each case's exact call.
- **Inputs.** The bundled datasets and a synthetic edge-case suite (brief §6 H): providers just below, at, and above the cutoff; no-event and all-event providers; separation; collinear and constant covariates; factors with unused levels or spaces; transformed and interaction terms (expected errors in the reference, D-18); character, numeric, integer, and factor IDs; missing values; very unequal sizes; rare and common outcomes; extreme covariates (D-04). Generated datasets are stored in the fixtures so that tests do not depend on RNG versions.
- **Outputs.** The full reference return value (for wrapper tests), with RE/CRE merMod objects replaced by their extracted components (fixef, ranef, conditional variances, VarCorr, logLik, fitted values, vcov), plus intermediates: provider sizes and event counts, screening indicators, included rows, linear predictors, expected values under the null, and the iteration count parsed from the C++ log, so the iteration path length is a Tier 0 check.
- **Format.** RDS at full precision plus `manifest.json`. Fixtures shipped in the package stay under about 5 MB; larger suites go to `validation/`.
- **Regeneration** needs approval and produces a diff report (brief §3.1).

### G.2 Case grid

| Function | Grid |
|---|---|
| `logis_fe` | datasets × method {SerBIN, BAN} × stop {or, beta, relch, ratch, all} × backtrack {TRUE, FALSE} × tol {1e-5, 1e-10} × cutoff {10, 5} × bound {10, 5} × input format {formula, columns, vectors} (pruned to a covering design) |
| `logis_firth` | datasets × tol {1e-5, 1e-10}, threads = 1 |
| `test.logis_fe` | test {exact.poisbinom, exact.bootstrap (3 seeds), score modified, score standard, wald} × alternative × null {median, 0, −0.5} × level {0.95, 0.90} × parm {all, subset} |
| `SM_output` | per family: stdz × measure × null |
| `confint` | per family: option × test × stdz × measure × alternative × level × parm |
| `summary` | per family: test × parm × level |
| plots | the numbers behind each plot (`ggplot_build()` layer data), not images |
| RE/CRE fits | defaults and representative `...` (`REML = FALSE`, `control`) |
| `data_check` | captured messages, warnings, and errors |

The full grid is enumerated in `cases.R`; the expected order of magnitude is a few hundred cases.

### G.3 Equivalence test plan

1. **Phase 1.** Characterization tests compare the current code (still the reference) with the fixtures: they must pass at Tier 0 everywhere, which proves the fixtures are reproducible on the generating platform and shows the cross-platform differences on CI. Implemented in Phase 1: the tests apply each case's tier, and `validation/equivalence-report.md` records each case's largest difference and whether its long double vectors are bitwise identical, which shows whether Tier 0 holds.
2. **Phase 3 onward.** The same suite runs against the new code twice: through the compatibility wrappers (old shapes, field by field) and through the new API (results matched by `provider_id` and coefficient name).
3. **Live comparison during migration.** Because old and new names differ, both implementations can be called in one session; tests compare them on cases the fixtures do not cover. Fixtures remain the authority.
4. **Comparison helper.** `expect_equivalent(actual, expected, tolerance = tol_<name>)` applies |a − b| ≤ atol + rtol·|b| elementwise and reports the worst element. Implemented in Phase 1 as `reference_compare()` (`tests/testthat/helper-equivalence.R`), called by `expect_reference_case()` with the tolerance `pprof_tolerances$<tier>` (tiers `exact`, `closed_form`, `iterative`, `probability`, `root`, `lme4`).
5. **Flag boundary rule.** A helper lists providers whose p-value lies within the applicable tolerance of a decision threshold (α/2, 1 − α/2, α); flags must match exactly for all others, and the listed providers go in the equivalence report (`validation/equivalence-report.md`, generated at each gate from Phase 3 on). Implemented in Phase 1 on the reported p-value with the threshold α = 1 − level. This is equivalent, because in every family the reported two-sided p-value is 2·min(p, 1 − p) of the upper tail probability p that the flag compares with α/2 and 1 − α/2, and the reported one-sided p-value is the tail that the flag compares with α.
6. **Discrepancies.** Every Class A fix gets a regression test; every Class B item is reproduced in the wrappers and, if signed off, implemented in the new API with its own fixture-difference report.

### G.4 Tolerances (proposed `tests/testthat/helper-tolerances.R`)

| Name | Tier | atol | rtol | Applies to | Justification |
|---|---|---|---|---|---|
| `tol_exact` | 0 | 0 | 0 | inclusion, sizes, event counts, screening indicators, ordering, dimensions, iteration counts, flags (boundary rule aside) | discrete |
| `tol_closed_form` | 1 | 1e-12 | 1e-10 | O/E and measures, variances given the estimates, Wald statistics, linear FE estimates | recomputation with a different summation order differs by at most 1.1e-14 relative in Phase 0 (V10.17, V13.12, V14.1, B2); four orders of magnitude of margin for BLAS and compiler differences, to be checked on every CI platform |
| `tol_iterative_path` | 2 | 1e-12 | 1e-10 | SerBIN, BAN, Firth estimates when the iteration count matches | ports with identical paths differ by at most 2e-15 (V10.1, V10.2, V12.1); same margin argument |
| `tol_probability` | 1 | 1e-14 | 1e-10 | p-values and tail probabilities | probabilities near 0 need an absolute floor; 1e-14 is above the observed recomputation noise (V13.4: 2.7e-15 in statistics) |
| `tol_root` | 3 | 2.5e-4 | 2.5e-4 (DEC-019; 0 before Phase 1) | every value of a root-based interval table: provider-effect limits and ratio and rate limits (DEC-019) | twice the default `uniroot()` tolerance (1.22e-4). With function values reproduced to rounding, roots matched bitwise in Phase 0 (V13.15), so this is a fallback for platform differences |
| `tol_lme4` | 4 | 1e-10 | 1e-8 | lme4-backed estimates under pinned lme4 and Matrix | identical calls give identical results (V15.1); the margin covers optimizer sensitivity to rounding across platforms and must be validated per quantity |

Rules: each tolerance changes only with sign-off; a failing comparison is never fixed by loosening it (brief §3.3). If the iteration count differs (Tier 2 path not reproduced), the comparison falls back to the brief's procedure: quantify the divergence at default settings and at `tol = 1e-10` on both implementations, then justify a case-specific tolerance in the equivalence report.

Phase 1 implements this table in `tests/testthat/helper-tolerances.R` as `pprof_tolerances`, with the names shortened to `exact`, `closed_form`, `iterative`, `probability`, `root`, and `lme4`. Its `root` entry applies the relative component of DEC-019 (signed off on 2026-10-02) to every value of a root-based interval table.

### G.5 Independent references (Suggests, skipped when absent)

| Check | Reference | Phase 0 evidence |
|---|---|---|
| Logistic FE on data without extreme providers, tight tolerance | `glm(y ~ 0 + factor(provider) + Z, binomial)` | (Phase 1) |
| Linear FE | `lm()` with provider indicators | V14.1: 2e-14 |
| Firth on small data | `logistf` with provider indicators | V12.5: 2e-11 |
| RE and CRE | direct `lmer()`/`glmer()` calls | V15.1: identical |
| Poisson-binomial | brute-force convolution on small n | (Phase 2) |
| AUC | Mann–Whitney statistic | V10.15: identical |
| Standardization | hand calculation | V13.12, V14.5, V15.4 |
| Tests and intervals | simulations with known truth (size, coverage), in `validation/` only | (Phase 5) |

As built through Phase 4: `tests/testthat/test-independent-fits.R` implements the linear FE, Firth, and RE and CRE rows, with the tolerances of DEC-043, and `tests/testthat/test-metamorphic-fits.R` the metamorphic layer for the Phase 4 fits. The `glm()` check of logistic FE, planned for Phase 1, has not been written yet (raised at the Phase 4 gate).

As built in Phase 5 (step 4): `test-independent-fits.R` adds the logistic FE row, `fit_logistic_fe()` against `glm()` with provider indicators on the example data without its extreme providers and on a seeded simulation (estimates within 1e-10, DEC-050; variances and log-likelihood at the closed-form tier, with `glm()`'s covariance taken after one more iteration from its estimates), and the standardization row for linear FE (K-83) and linear and logistic RE (K-82, K-84), computed by hand from the data and a direct lme4 fit. The tests-and-intervals row is `validation/run-simulation.R` with its report `validation/simulation-report.md` (DEC-053): the size and power of the provider tests and the coverage of the provider-effect and indirect-measure intervals of every family under data without provider effects and with six outlying providers, with Monte Carlo standard errors; informational, it gates nothing.

### G.6 Test layers (brief §6)

| Layer | Where | From phase |
|---|---|---|
| A. Characterization | `test-reference-*.R` against fixtures | 1 |
| B. Numerical units (likelihood, score, information versus finite differences; block inverse versus dense inverse; Poisson-binomial; standardization; AUC) | `test-core-*.R`, `test-inference-*.R` | 2–3 |
| C. C++ (convergence, singular information, one-observation providers, all/no events, p ≥ n, non-finite inputs, threads) | through the adapters, `test-cpp-*.R`; sanitizer job in CI | 3 |
| D. Integration (R → Rcpp → C++, error propagation, interrupts) | `test-integration-*.R` | 3 |
| E. Independent references | `test-independent-*.R` | 1–4 |
| F. Metamorphic (row order, provider relabeling including character and factor IDs, affine covariate transforms, equivalent interfaces) | `test-metamorphic-*.R` | 3 |
| G. Regression (one per D-xx and per future bug) | `test-regression-*.R` | as fixed |
| H. Synthetic edge cases | datasets from `dev/reference/datasets.R` stored in fixtures | 1 |

R line coverage target 90%; C++ coverage measured with `covr` (gcov) on Linux CI.

As built in Phase 5: `test-metamorphic-profiles.R` extends layer F to the profiling results of the linear FE, RE, and CRE families (relabeling with character, factor, and numeric IDs gives identical results; shuffling rows changes linear FE results only within the closed-form tier). Regression tests for the Phase 5 register entries are in `test-compat-methods-families.R`, next to the wrappers they test, and in `test-reference-overrides.R` for the cases with per-case expectations.

---

## H. Dependency strategy

| Package | Current use | Needed | Base-R alternative | License | Recursive cost (V16.5) | Decision |
|---|---|---|---|---|---|---|
| Rcpp | R/C++ bridge | yes | none | GPL ≥ 2 | 0 | keep (Imports, LinkingTo) |
| RcppArmadillo | linear algebra | yes | none; changing would change numerical paths (brief §5.6) | GPL ≥ 2 | 1 | keep (LinkingTo) |
| RcppParallel | unused TBB worker, link flags | no | OpenMP, already used | GPL ≥ 3 | 1 | remove; also removes TBB linking and `SystemRequirements: GNU make` |
| stats, utils, graphics, grDevices | core | yes | | base | 0 | keep |
| lme4 | RE/CRE engine | yes | none (brief §2.2) | GPL ≥ 2 | 12 | keep, behind one adapter |
| Matrix | `bdiag()` in `linear_fe` | no, after demeaning | `rowsum()` demeaning (B2) | GPL ≥ 2 | 0 beyond lme4 | remove from Imports (still installed with lme4) |
| poibin | Poisson-binomial distribution | yes | own implementation would need an equivalence test | GPL-2 | 0 | keep |
| pROC | AUC | no | rank-based AUC, identical (V10.15) | GPL ≥ 3 | 1 | remove after an equality test |
| caret | `nearZeroVar()` in `data_check` | no | frequency-ratio and percent-unique rule with the same thresholds | GPL ≥ 2 | 72 (51 beyond ggplot2 and lme4) | remove after an equality test |
| olsrr | VIF in `data_check` | no | VIF_j = 1/(1 − R²_j) from `lm()` | MIT | 94 (65 beyond) | remove after an equality test; also removes the `car` attach message |
| dplyr | CRE decomposition, plot data, `bar_plot` | no | `ave()`, `rowsum()`, base data frames | MIT | 14 (8 beyond) | removed from Imports in Phase 6 (DEC-057): its last uses, the old plots' data preparation, are base R |
| tidyselect | `all_of()` in CRE | no | | MIT | 6 | removed from Imports in Phase 6 (DEC-057) with the unused import tags |
| magrittr | `%>%` | no | native pipe (R ≥ 4.1) | MIT | 0 | removed from Imports in Phase 6 (DEC-057) |
| rlang | `.data` pronoun in plots | presentation only, if at all | `aes()` with column names and `utils::globalVariables()` | MIT | 0 beyond ggplot2 | decided in Phase 6 (DEC-057): the pronoun stays in presentation and compatibility code, imported from ggplot2, which re-exports it; rlang left Imports; never in numerical code |
| globals | nothing (silences a check note) | no | | LGPL ≥ 2.1 | 1 | remove |
| ggplot2 | plots | yes | | MIT | 16 | keep (Imports) |
| scales | percent labels | yes, in plots | | MIT | 0 beyond ggplot2 | keep |
| tibble | little use now; `tidy()` outputs | yes, for tidy outputs | data frames | MIT | 5 beyond ggplot2 and lme4 | keep for `tidy()`/`glance()`/`augment()` |
| generics | `tidy`, `glance`, `augment` generics | yes | | MIT | 0 | add |

Suggests: `testthat (>= 3.0.0)`, `withr`, `knitr`, `rmarkdown`, `logistf` (independent reference), `jsonlite` (reading the fixture manifest in tests). Development-only tools (`bench`, `callr`, `covr`, `lintr`) stay out of `DESCRIPTION`.

Result: the install tree shrinks from 131 to 38 packages (V16.5). Licenses: pprof is MIT; its kept GPL dependencies (Rcpp, RcppArmadillo, lme4, poibin) are used as separate packages, as now; nothing is vendored.

R version: keep `R (>= 4.1.0)`, the current requirement, which the native pipe needs; compile as C++17 (`CXX_STD = CXX17`, the default from R 4.3). Question M-12.

As built in Phase 8: caret, olsrr, and globals left Imports (DEC-073); caret and olsrr are suggested, for the tests that compare `check_data()`'s computations with theirs, as pROC is for the AUC and logistf for the Firth fit. The packages installed with pprof (recursive Depends, Imports, and LinkingTo on CRAN, besides R's base packages) went from 130 to 38 (PHASE8_PLAN F2). DESCRIPTION requires `ggplot2 (>= 4.0.0)`, under which the plots were compared with pprof 1.0.3's (DEC-074), and `R (>= 4.4.0)`, the oldest version CI finds working with the current dependencies: R 4.1 cannot install them, and on R 4.2 and 4.3 printing an lme4 fit fails in reformulas, which calls base R's `%||%` (DEC-081).

---

## I. Migration strategy

### I.1 Old to new

| Reference | New | Wrapper kept |
|---|---|---|
| `logis_fe(formula with id(), data, …)`, `logis_fe(data, Y.char, Z.char, ProvID.char, …)`, `logis_fe(Y, Z, ProvID, …)` | `fit_logistic_fe(formula, data, provider, method = "serbin", …)` | `logis_fe()` |
| `logis_firth(…)` | `fit_logistic_firth(formula, data, provider, …)` | `logis_firth()` |
| `linear_fe(…, option.gamma.var)` | `fit_linear_fe(formula, data, provider, provider_variance = "simplified")` | `linear_fe()` |
| `linear_re(formula with (1 | id), …)`, column and vector forms | `fit_linear_re(formula, data, provider, …)` | `linear_re()` |
| `logis_re(…)` | `fit_logistic_re(formula, data, provider, …)` | `logis_re()` |
| `linear_cre(data, Y.char, wb.char, other.char, ProvID.char, …)` | `fit_linear_cre(formula, data, provider, within_between, …)` | `linear_cre()` |
| `logis_cre(…)` | `fit_logistic_cre(formula, data, provider, within_between, …)` | `logis_cre()` |
| `test(fit, test = "exact.poisbinom", score_modified, n, …)` | `test_providers(fit, test = "exact", score_type, n_resamples, …)` | generic `test()` with methods for old classes |
| `SM_output(fit, stdz, measure, null, threads)` | `standardize_providers(fit, standardization, measure, null, threads)` | generic `SM_output()` with methods for old classes |
| `confint(fit, option = "gamma", test)` | `provider_effects(fit, interval = test)` | `confint()` methods for old classes |
| `confint(fit, option = "SM", stdz, measure, test)` | `standardize_providers(fit, …, interval = test)` | as above |
| `summary(fit, test = "wald"/"lr"/"score")` | `summary(fit)` (Wald) and `test_coefficients(fit, test = "lr", data = …)` | `summary()` methods for old classes |
| `plot(fit)` (funnel) | `plot_funnel(profile_providers(fit))` or `plot_funnel(funnel_limits(fit))` | `plot()` methods for old classes |
| `caterpillar_plot(CI)` | `plot_caterpillar(standardize_providers(fit, interval = "exact"))` | `caterpillar_plot()` |
| `bar_plot(test(fit))` | `plot_flags(test_providers(fit))` | `bar_plot()` |
| `data_check(Y, Z, ProvID)` | `check_data(formula, data, provider)` | `data_check()` |

As built in Phase 7: the migration guide (`vignettes/migration.Rmd`, §I.4) gives this table with a migration path for each row; `plot_volume()` (DEC-059) and `profile_providers()` are new, without an old counterpart; `check_data()` comes in Phase 8, so the guide tells users to keep `data_check()`.

As built in Phase 8: `check_data()` (DEC-073) replaces `data_check()`, and the guide's row says how to migrate: `check_data()` reports every problem instead of stopping at the first.

### I.2 How the wrappers work

- They live only in `R/compat-*.R` and contain translation logic only (brief §8).
- A wrapper fit translates arguments (including `id()` and `(1 | id)` formulas, `Y.char`-style names, and the vector interface), calls the new fit with `keep_data = TRUE`, and converts the result into the exact old shape (BEHAVIOR_SPECS §16), without an attribute. Old methods (`test.logis_fe` and so on) rebuild the new model from the old object's fields, call the new API, and convert the results back to the old shapes, so they also work on old objects from code not yet replaced and on fits saved with pprof 1.0.3 (DEC-032, which replaced the earlier design of storing the model in `attr(, "pprof_model")`).
- They reproduce the reference including the Class B items awaiting sign-off (D-10, D-12, D-13, D-24, D-31, D-32, D-34), the presentation details (factor flags, character p-values, string attributes), and messages. Class A fixes apply (a crash becomes a result or a classed error) and are listed in the migration guide.
- Each wrapper warns once per session with class `pprof_deprecated`, through a small internal helper (no `lifecycle` dependency).
- They are tested against the fixtures field by field.

As built through Phase 5: every fitting function and every method of pprof 1.0.3 except `bar_plot()`, `caterpillar_plot()`, and `data_check()` is a wrapper over the new API. The methods of `linear_fe`, `linear_re`, `logis_re`, `linear_cre`, and `logis_cre` objects (Phase 5, DEC-049) rebuild the model with `compat_model_from_linear_fe()` or `compat_model_from_mixed()`, which read numbers only from the numeric fields and the lme4 fit, never from `data_include`, whose columns are text when the IDs are (D-11); the standard deviations of the RE effects are recomputed from the stored variance (K-69) or read from the lme4 fit when a method needs them, as the reference does (D-46). Before the switch, a live comparison found the wrappers' values `identical()` to the old methods' on every method fixture and a grid of about 280 settings. The once-per-session deprecation warning is not in place yet (`R/compat-deprecate.R`, a later phase).

As built in Phase 6: `caterpillar_plot()` and `bar_plot()` are wrappers too (DEC-055), so every function of pprof 1.0.3 except `data_check()` (Phase 8) runs on the new code. The four old plot functions live in `R/compat-plots.R`: their data come from the new code (the profiling API, `profile_funnel_limits()`, and the K-112 and K-113 functions of `R/profile-summaries.R`), in the reference's layout, and they draw with the reference's ggplot code, kept unlinted as the record of the old appearance; their data preparation is base R instead of dplyr and magrittr. A guard (`dev/design/phase6-facts/08_plot_guard.R`) compared the plots of 687 calls before and after: the built data, labels, scales, guides, and themes are identical, except that `bar_plot()`'s plot data are a data frame instead of a grouped tibble, and inputs the reference failed on without a message of its own raise classed errors.

As built in Phase 8: every function of pprof 1.0.3 runs on the new code, `data_check()` too, which gives pprof 1.0.3's messages, warnings, and errors through `check_data()`'s computations and completes its checks with one covariate (D-52, DEC-073). The twelve exported names warn once per session with class `pprof_deprecated` (DEC-072); `test()` and `SM_output()` warn in the generic, and the methods of base generics for the old classes do not warn. `plot.logis_fe()` builds the model once, taking its flags from the conversion `test.logis_fe()` shares, and the horizontal `caterpillar_plot()` draws its bars with `geom_errorbar(orientation = "y")`, which builds the same bars with a different `width` column (DEC-075).

### I.3 Timeline

- 2.0.0: the new API, with all wrappers present and warning once per session.
- At least one further minor release (2.1.0) with the wrappers.
- Removal no earlier than the release after that and at least 12 months after 2.0.0, as the owners decide (question M-12). The removal is itself a breaking change listed in NEWS.

### I.4 Migration guide (Phase 7)

A vignette with the table above, worked before-and-after examples for each workflow (fit, test, standardize, intervals, plots), the list of Class A behavior changes (errors that became results), the new argument vocabulary, and the changed default thread count (DEC-001).

As built in Phase 7 (DEC-064): `vignettes/migration.Rmd`, "Migrating from pprof 1.0.3". Its table is §I.1's with a migration path for each row (`data_check()` has no replacement until `check_data()`, Phase 8); its argument table is NAMING §4's "Replaces" column; each workflow (fitting in the three input formats, tests, measures, intervals, covariates, the funnel plot, and the linear FE, RE, CRE, and Firth fits) runs the old and the new call and stops the build unless the numbers are identical (18 comparisons). The user documentation cites no register IDs; its list of changes maps to the register as follows:

| Item of the guide | Register |
|---|---|
| Formulas with transformed terms, interactions, factor levels with spaces | D-18 |
| Factor provider IDs when providers are excluded | D-41 |
| Settings that returned meaningless fits now raise errors (`threads` < 1, `backtrack` with BAN, non-binary outcomes, non-positive `max.iter`, `tol`, `bound`) | D-22, D-23, D-39 |
| `logis_firth()` with several threads; singular information | D-05, D-42 |
| `linear_re()` and `logis_re()` vector interface | D-11 |
| Screening warning count; "not converged"; pROC and ggplot2 messages | D-01, D-03, D-36 |
| `confint()` with character and factor IDs and any provider column name | D-19, D-28, D-29 |
| Integer IDs in `parm`; integer `null`; a `null` of several values | D-27, D-14, D-45 |
| `test = "robust_wald"`; standard score statistic not computable | D-06, D-04 |
| `summary(test = "lr")` with one or two covariates, `"score"` with two; RE summaries without the lme4 fit | D-30, D-46 |
| One thread in the logistic RE and CRE `confint()` | D-21 |
| `plot(test = "exact")`; classed errors of `caterpillar_plot()` and `bar_plot()`; `bar_plot()`'s data frame | D-07, DEC-055, D-49 |
| The new interface: results, integer flags, `confint()`, quiet fits, one thread, compact models, classed conditions, visible results | DEC-012, D-15, DEC-011, DEC-008, DEC-001, DEC-005, NAMING §6, D-51 |

Not listed because users never saw it: D-08 (partial matching, which worked). Unchanged and so not listed: the behaviors awaiting sign-off (D-10, D-24, D-31, D-32, D-34, D-43) and those signed off (D-12, D-13).

---

## J. Behavior specifications

See [BEHAVIOR_SPECS.md](BEHAVIOR_SPECS.md): shared input processing; every fitting function; every `test`, `SM_output`, `confint`, `summary`, and `plot` method; the two plot helpers; `data_check`; print methods; bundled data; and the output shapes the wrappers must reproduce. Each specification cites the register IDs it relies on and the discrepancies that affect it, and marks behavior that is not yet verified by running code.

---

## K. Verified numerical conventions register

The register is [CONVENTIONS.md](../CONVENTIONS.md) (PROJECT_CONTEXT §5.7 during the rewrite), the single source of truth. Phase 0 expanded it from 21 unverified rows to 69 verified entries (K-01 to K-130), each with evidence.

How the rewrite carries the conventions:

- Every constant gets a name and a comment stating its contract and its reference location, in `R/constants.R` or `src/core/constants.h`:

  | Register | Name (proposed) | Value |
  |---|---|---|
  | K-13 | `kFitWeightFloor` | 1e-20 |
  | K-14 | `kArmijoSufficientIncrease`, `kArmijoShrink` | 0.01, 0.6 |
  | K-16 | `kInitialCriterion` | 100 |
  | K-20 | `kVarianceProbabilityClamp` | 1e-10 |
  | K-30 | `kLogdetFloor`, `kCholeskyRidge` | 1e-12, 1e-8 |
  | K-31 | `kFirthWeightFloor` | 1e-10 |
  | K-33 | `kFirthInitialCriterion` | 1e9 |
  | K-62, K-65 | `probability_clamp` | 1e-10 |
  | K-90 | `root_bracket_width`, `root_bracket_attempts`, `extreme_bracket_base` | 5, 3, 10 |
  | K-100, K-103 | `p_value_display_digits`, `p_value_display_eps` | 7, 1e-10 |
  | K-101 | `lr_effect_clamp` | 10 |
  | K-80 | `rate_limits` | c(0, 100) |
  | K-120 | `near_zero_frequency_ratio`, `near_zero_percent_unique`, `correlation_threshold`, `vif_threshold` | 95/5, 10, 0.9, 10 |

- Defaults (K-17, K-33, K-42, K-60, K-64) live in the function signatures, following NAMING.md §4.
- Each register entry gets a unit test that pins the constant's effect (for example, a SerBIN run that must take max_iter + 1 iterations; a variance computed with clamped probabilities).

---

## L. Initial discrepancy register

See [DISCREPANCIES.md](../DISCREPANCIES.md). All 21 candidates from the static audit were verified by running code (D-03 and D-20 needed nuance; none was refuted), and 16 new entries were added (D-22 to D-37). Classes: 16 A, 7 B (each awaiting sign-off and reproduced in the meantime), 9 C, 3 presentation-only, 2 with no class (behavior preserved). Three entries are both silent and severe for users who hit them: D-05, D-19, and D-22/D-23. One, D-24, affects every default fit on large data.

---

## M. Open questions for the methodology owners

Each question has a proposed default; the default always reproduces the reference, so work can proceed while the questions are open. Questions 1–5 and 12 are the brief's §11 list.

| ID | Question | Proposed default | Related |
|---|---|---|---|
| M-1 | Which components are considered validated, and by what evidence (papers, simulations, internal checks)? The CRE models (August 2025) and the Firth correction (February 2026) are the newest. Phase 0 adds independent agreement for Firth (`logistf`, V12.5), linear FE (`lm`, V14.1), and RE (lme4, V15.1). | treat every component as validated behavior to reproduce | brief §11 Q1 |
| M-2 | Should Firth fits keep returning logistic FE objects whose variance, log-likelihood, AIC, and BIC are the unpenalized versions? | yes, as `c("pprof_logistic_firth", "pprof_logistic_fe", "pprof_model")`, plus the penalized log-likelihood as an extra field. Answered with the Phase 4 gate (2026-10-04): the default, as built in Phase 4 | D-12, Q2 |
| M-3 | In the CRE models, provider means are computed before complete-case filtering. Intended? | preserve. Answered with the Phase 4 gate (2026-10-04): preserve | D-13, Q3 |
| M-4 | Should the default stopping rule stay `"or"`, given that it can stop before provider effects converge on large data? | preserve, add diagnostics and a warning when the coefficient criterion is far above `tol` at stop | D-24 |
| M-5 | Should covariate LR and score tests refit the null model with the original fit's settings rather than the defaults? | preserve (defaults) | D-10 |
| M-6 | Which input interfaces must survive in the new API (formula; data plus column names; separate vectors)? | new API: formula, data, and a `provider` column name; all three old formats only through the compatibility wrappers | DEC-003, Q4 |
| M-7 | Is the "standard" score test (no refit; unrestricted nuisance estimates with a variance adjustment) the intended test? | preserve, document precisely | D-26 |
| M-8 | Linear FE intervals use t with the simplified variance and z with the full variance, the reverse of the tests. Which is intended? | preserve | D-32 |
| M-9 | Should exact funnel limits be implemented (the reference's exact funnel never ran)? | no; classed "unsupported" error | D-07 |
| M-10 | May the new API fix the logistic RE/CRE p-values above 1? | reproduce until signed off; fixing is strongly recommended | D-31 |
| M-11 | May provider order become locale-independent, which changes bootstrap draws for a given seed in non-C locales? | preserve the session-locale order | D-34 |
| M-12 | Minimum R version, release timeline, and deprecation window for the old names? | R ≥ 4.1.0; 2.0.0 with wrappers; removal no earlier than one further minor release and 12 months | §I.3, Q5 |
| M-13 | Should screening by provider size remain specific to the logistic FE models? | preserve | earlier question 6 (`dev/OPEN_QUESTIONS.md`) |
| M-14 | Is the "predicted over expected" numerator of RE indirect measures the intended estimand? | preserve | K-82, K-84 |
| M-15 | Exact and score intervals for no-event and all-event providers use α, not α/2, for their single finite limit even when two-sided. Intended? | preserve | K-90 |
| M-16 | Who are the designated methodology owners for written sign-off on Class B items? | to be named by the project lead | brief §3.3 |
