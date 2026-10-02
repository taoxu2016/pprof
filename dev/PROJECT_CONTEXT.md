# pprof rewrite: project context

Living reference for the `pprof` rewrite. Requirements live in `pprof_rewrite_brief.md`; this file holds facts, conventions, and status. Sections 5 and 6 come from a static read of `main` at commit `5260838`. Nothing in them has been executed yet, so treat each item as a hypothesis to confirm in Phase 0.

Last updated: 2026-10-02. Status: local setup complete on branch rewrite/v2; Phase 0 not started.

---

## 1. Project at a glance

| Item | Value |
|---|---|
| Package | `pprof`: *Modeling, Standardization and Testing for Provider Profiling* |
| Purpose | Fit risk-adjusted models with provider effects (hospitals, facilities, transplant centers, schools), then compute standardized measures, provider-level tests and flags, confidence intervals, and plots |
| Group | Kevin He group, University of Michigan |
| Authors | Xiaohan Liu (maintainer), Lingfeng Luo, Yubo Shao, Xiangeng Fang, Wenbo Wu, Kevin He |
| Repository | https://github.com/UM-KevinHe/pprof (MIT license) |
| CRAN | 1.0.3 published 2026-02-10; 1.0.2 published 2025-06-20; first release December 2024 |
| Reverse dependencies | None reported (R Observatory, August 2026). Confirm with `tools::package_dependencies("pprof", reverse = TRUE)`. If confirmed, breaking changes affect user scripts only |
| Reference oracle | 1.0.3, believed to be `main` at `5260838` (2026-02-09, "debug for cran"). Confirm by diffing against the CRAN tarball |
| Other refs | Tag `v1.0.2` is `20adc5d`. Branches `CRAN`, `SMR`, `Lingfeng`, `Xiaohan`, `Yubo`, and `JOSS` are stale side branches (several declare `Version: 1.3`); none of them is the reference |
| R requirement | R >= 4.1.0 |

---

## 2. The rewrite in brief

Rebuild the package's architecture, naming, R code, C++ code, tests, and documentation while preserving its statistical behavior exactly. Non-negotiables:

1. The pinned reference (1.0.3) is the oracle for statistical behavior. Numbers, flags, inclusion decisions, and defaults do not change without methodology sign-off.
2. Every behavioral difference is logged in `dev/DISCREPANCIES.md` and classified: A (crash, `NULL`, misalignment, nondeterminism: may fix with a regression test), B (any numeric, flag, inclusion, or default change: needs sign-off), C (docs or messages wrong: fix the docs).
3. Equivalence is proven against frozen fixtures generated from the pinned reference with `threads = 1` and fixed seeds, under the tiered tolerance policy in the brief.
4. Work is phased with stop gates. Phase 0 produces the design document; no large-scale rewriting before approval.
5. No new statistical methods. Random-effect and CRE models stay on `lme4`.
6. Target design: S3 objects, base-R numerical core, thin Rcpp boundary over a Rcpp-free C++ core, `ggplot2` plots, tidy outputs via `generics`, extensible model contract.

---

## 3. Domain primer and glossary

| Term | Meaning in pprof |
|---|---|
| Provider | The unit being profiled. Identified by `ProvID` in the current API |
| Provider effect | Fixed-effect models: γ_i, one estimated parameter per provider. Random-effect models: α_i, a random intercept predicted by `lme4` |
| Risk adjustment | Covariate coefficients β, which describe the patient mix |
| Logistic FE model | logit P(Y_ij = 1) = γ_i + Z_ij'β |
| SerBIN | Serial blockwise inversion Newton: Newton–Raphson updating (γ, β) jointly, using the block structure of the information matrix and its Schur complement |
| BAN | Block ascent Newton: alternates γ updates with β fixed and β updates with γ fixed |
| Firth correction | Penalized likelihood ℓ(θ) + ½ log det I(θ), which reduces small-sample bias and keeps estimates finite |
| Screening | Logistic FE only: providers with fewer than `cutoff` observations are excluded; providers with no events or all events are flagged but kept, and their γ stay finite because each iteration clamps γ to median(γ) ± `bound` |
| Linear FE ("profile" method) | β from the within-provider (demeaned) regression; γ_i = ȳ_i − z̄_i'β |
| CRE | Correlated random effects (Mundlak): chosen covariates are split into provider means (`*_bar`) and within-provider deviations (`*_within`), then fitted with `lme4` |
| Indirect standardization | Compares a provider with what its own patients would experience at a reference ("null") provider. Logistic: ratio O_i/E_i; rate = ratio × population rate in %, clipped to [0, 100] |
| Direct standardization | Applies each provider's effect to the whole population: E_i(direct) / ΣO |
| Standardized difference | Linear models report differences rather than ratios |
| Null (population norm) | Reference provider effect: median of γ̂ by default for FE models; 0 for RE models |
| Flag | 1 = higher than expected, 0 = as expected, −1 = lower than expected |
| Exact Poisson-binomial test | Under the null, a provider's event count given covariates is Poisson-binomial; pprof uses a mid-p version |
| Modified score test | Score test that plugs in the unrestricted β̂ to avoid refitting (default in pprof) |
| Funnel plot | Standardized measure against precision, with control limits |

---

## 4. Methodological references

| Reference | Underpins |
|---|---|
| Wu W, Yang Y, Kang J, He K (2022). *Statistics in Medicine* 41(15):2840–2853. doi:10.1002/sim.9387 | SerBIN; score and exact tests at scale |
| He K, Kalbfleisch JD, Li Y, Li Y (2013). *Lifetime Data Analysis* 19:490–512 | Fixed provider effects model; BAN |
| He K (2019). *Journal of Hospital Administration* 8(1):9–14 | Indirect and direct standardization |
| Wu W, Kuriakose JP, Weng W, Burney RE, He K (2023). *Health Services and Outcomes Research Methodology* 23(1):45–58 | Test-specific funnel plots |
| Hsiao C (2022). *Analysis of Panel Data*. Cambridge University Press | Linear fixed-effect (profile) estimation |
| Bates D, Mächler M, Bolker B, Walker S (2015). *Journal of Statistical Software* 67(1) | `lme4` engine for RE and CRE models |
| Firth D (1993). *Biometrika* 80(1):27–38 | Bias-reduced likelihood (not cited in the package) |
| Mundlak Y (1978). *Econometrica* 46(1):69–85 | Within–between decomposition behind CRE (not cited in the package) |

---

## 5. Current codebase (audit snapshot)

### 5.1 Repository map

| Path | Contents | Notes |
|---|---|---|
| `R/` | 41 files, 7,057 lines: about 2,000 roxygen, about 755 commented-out code, 683 blank | One file per method per class (`confint.logis_fe.R` and so on) |
| `src/` | `Fixed_effect.cpp` (677 lines), `Firth.cpp` (422), `RcppExports.cpp`, `header.h`/`header.cpp`, `myomp.h`, `Makevars`, `Makevars.win` | OpenMP plus RcppParallel/TBB link flags; `$(shell ...)` in `Makevars` is why `SystemRequirements: GNU make` exists |
| `tests/testthat/` | 11 files, 723 lines | Smoke and structure tests only (Section 5.9) |
| `vignettes/` | 5 Rmd files | Excluded from the package build by `.Rbuildignore` (`^vignettes/`); published on the pkgdown site only |
| `data/` | `ExampleDataBinary`, `ExampleDataLinear`, `ecls_data` | Section 5.8 |
| `docs/` | Committed pkgdown output | |
| `.github/workflows/` | `test-pprof-package.yml`, `rhub.yaml` | Section 5.9 |
| `configure.txt`, `cleanup.txt` | Build scripts excluded from the build | `configure.txt` is data.table's configure script (mentions `fwrite` and zlib); `myomp.h` is also copied from data.table |

### 5.2 Public API

| Export | Kind | Engine | Returns class | Notes |
|---|---|---|---|---|
| `logis_fe()` | Fit | C++ SerBIN (default) or BAN | `logis_fe` | Three input formats |
| `logis_firth()` | Fit | C++ Firth | `logis_fe` | Stopping rule fixed to `"beta"` (not exposed in R) |
| `logis_re()` | Fit | `lme4::glmer`, binomial logit | `logis_re` | Full merMod stored in `attr(fit, "model")` |
| `logis_cre()` | Fit | `lme4::glmer` | `logis_cre` | Column-name interface only, no formula |
| `linear_fe()` | Fit | R, dense centering through `Matrix::bdiag` | `linear_fe` | Argument order differs from `logis_fe`; no `cutoff`, no verbosity control |
| `linear_re()` | Fit | `lme4::lmer` | `linear_re` | |
| `linear_cre()` | Fit | `lme4::lmer` | `linear_cre` | Column-name interface only |
| `test()` | Generic | | | Provider-level tests and flags |
| `SM_output()` | Generic | | | Standardized measures |
| `data_check()` | Diagnostics | `caret`, `olsrr` | (messages) | Stops on any missing value; zero and near-zero variance; pairwise abs(r) > 0.9; VIF >= 10 |
| `caterpillar_plot()` | Plot | `ggplot2` | | Consumes `confint()` output and its attributes |
| `bar_plot()` | Plot | `ggplot2` | | Consumes `test()` output and its `"provider size"` attribute |

Registered S3 methods: `summary`, `confint`, `test`, and `SM_output` for all six classes; `plot` (funnel) for `linear_fe` and `logis_fe`; `print` for `linear_cre`, `linear_re`, and `logis_re`. `print.logis_cre` is defined but not registered.

Formula syntax: fixed effects use `y ~ x1 + x2 + id(provider)`; random effects use `y ~ x1 + x2 + (1 | provider)`; CRE models take column names (`Y.char`, `wb.char`, `other.char`, `ProvID.char`).

### 5.3 Signatures (defaults are part of the behavior)

```r
logis_fe(formula = NULL, data = NULL, Y.char = NULL, Z.char = NULL, ProvID.char = NULL,
         Y = NULL, Z = NULL, ProvID = NULL, method = "SerBIN", max.iter = 10000,
         tol = 1e-5, bound = 10, cutoff = 10, backtrack = TRUE, stop = "or",
         threads = 1, message = TRUE)
logis_firth(formula = NULL, data = NULL, Y.char = NULL, Z.char = NULL, ProvID.char = NULL,
            Y = NULL, Z = NULL, ProvID = NULL, max.iter = 1000, tol = 1e-5, bound = 10,
            cutoff = 10, threads = 1, message = TRUE)
linear_fe(formula = NULL, data = NULL, Y = NULL, Z = NULL, ProvID = NULL,
          Y.char = NULL, Z.char = NULL, ProvID.char = NULL, option.gamma.var = "simplified")
linear_re(formula = NULL, data = NULL, Y = NULL, Z = NULL, ProvID = NULL,
          Y.char = NULL, Z.char = NULL, ProvID.char = NULL, ...)  # ... passed to lmer
logis_re(...same arguments as linear_re...)                      # ... passed to glmer
linear_cre(data, Y.char, wb.char, other.char = NULL, ProvID.char, ...)
logis_cre(data, Y.char, wb.char, other.char = NULL, ProvID.char, ...)

# logis_fe methods
test(fit, parm, level = 0.95, test = "exact.poisbinom", score_modified = TRUE,
     null = "median", n = 10000, threads = 1, alternative = "two.sided")
SM_output(fit, parm, stdz = "indirect", measure = c("rate", "ratio"),
          null = "median", threads = 2)
confint(object, parm, level = 0.95, test = "exact", option = "SM", stdz = "indirect",
        null = "median", measure = c("rate", "ratio"), alternative = "two.sided")
summary(object, parm, level = 0.95, test = "wald", null = 0)
plot(x, null = "median", test = "score", target = 1, alpha = 0.05, ...)
```

### 5.4 Post-estimation behavior by family

Logistic FE (including Firth, which shares the class):

- Provider tests: `exact.poisbinom` (default, mid-p: P(O > o) + ½P(O = o), statistic `qnorm(p, lower.tail = FALSE)`); `exact.bootstrap` (n = 10,000 Bernoulli draws per provider via `rbinom`, no internal seed); `score` (modified by default; the standard version runs in C++ `Modified_score`); `wald`. `null` is `"median"` or a number.
- Standardized measures: indirect O/E and/or direct; ratio and/or rate.
- Intervals: `option = "gamma"` or `"SM"`; `test = "exact"` (default), `"score"`, or `"wald"`. Limits come from test inversion with `uniroot()` (default tolerance), brackets of width 5 around γ̂, up to three attempts, otherwise ±Inf. No-event providers get only an upper limit and all-event providers only a lower limit. SM intervals map γ limits through the standardization formula.
- Covariate inference (`summary`): Wald (default), likelihood ratio, or score; the latter two refit the model per covariate.

Linear FE:

- Provider tests: z test when γ variance is `"simplified"` (σ²/n_i, the default) or t test with df n − m − p when `"full"`. The choice is driven by an attribute on `fit$variance$gamma`, not by an argument of `test()`. `null` is `"median"`, `"mean"` (size-weighted), or a number.
- Standardized measures: indirect and direct standardized differences.
- Intervals and `summary`: t-based with df n − m − p.

Random-effect and CRE models:

- Logistic RE, logistic CRE, and linear CRE provider tests use Wald-type statistics with `lme4` conditional variances (`ranef(condVar = TRUE)`, read through the attribute name `"postVar"`). Linear RE instead uses a closed-form shrinkage standard error, sqrt(R_i σ²/n_i) with R_i = σ²_α / (σ²_α + σ²/n_i). Default `null = 0`.
- Logistic RE/CRE indirect measures use Σ fitted probabilities (including random effects) over Σ plogis(Zβ), a "predicted over expected" ratio rather than observed over expected. Linear RE indirect differences use Σ fitted − Σ Zβ.
- Direct measures and logistic RE/CRE intervals use C++ `computeDirectExp`; the interval code hard-codes `threads = 4`.
- `summary.linear_re` uses t tests with df = n − (number of fixed effects) − (number of providers) + 1.

The formulas differ across families in ways that matter (for example the "observed" term of direct standardization). Each must be captured in the Phase 0 behavior specifications rather than unified.

### 5.5 Current model objects

FE objects (`logis_fe`, `linear_fe`) contain: `coefficient` (`beta` and `gamma` as one-column matrices with dimnames), `variance` (β covariance and γ variances; in `linear_fe` the γ variance carries a `"description"` attribute), `fitted`, `observation`, `linear_pred` (Zβ), `Loglkd`, `AIC`, `BIC`, `AUC` (logistic), `sigma` and `residuals` (linear), `char_list` (`Y.char`, `ProvID.char`, `Z.char`), and `data_include` (the full processed data sorted by provider, with dummy columns and `included`, `no.events`, `all.events` indicators).

RE and CRE objects contain `coefficient$FE`, `coefficient$RE`, `variance$alpha`, `variance$FE`, `fitted`, `observation`, `linear_pred`, `Loglkd`, `AIC`, `BIC`, `char_list`, `data_include`, and the whole `lme4` fit in `attr(fit, "model")`.

No FE fit returns convergence diagnostics. The C++ fitters return only `gamma` and `beta`, except Firth, whose `iter`, `crit`, and `history` are discarded in R.

### 5.6 C++ routines

All are exported to R through `// [[Rcpp::export]]` (internal wrappers in `R/RcppExports.R`).

| Routine | File | Called from | Notes |
|---|---|---|---|
| `logis_BIN_fe_prov` | `Fixed_effect.cpp` | `logis_fe` (SerBIN) | Loop is `while (iter <= max_iter)`; OpenMP element-wise information matrix when `threads > 1`, BLAS product otherwise |
| `logis_fe_prov` | `Fixed_effect.cpp` | `logis_fe` (BAN) | Loop is `while (iter < max_iter)`; `backtrack` is an `int` and only 0 or 1 runs any iterations |
| `logis_fe_var` | `Fixed_effect.cpp` | `logis_fe`, `logis_firth` | Unpenalized information; p clamped to [1e-10, 1 − 1e-10] |
| `Modified_score` | `Fixed_effect.cpp` | `test.logis_fe(test = "score", score_modified = FALSE)` | OpenMP over providers; returns only finite z-scores |
| `computeDirectExp` | `Fixed_effect.cpp` | `SM_output` (logistic FE/RE/CRE), `confint` (logistic RE/CRE) | Nested OpenMP regions with a floating-point reduction |
| `wald_covar` | `Fixed_effect.cpp` | Commented-out code only | Dead |
| `compute_profilkd_linear` | `Fixed_effect.cpp` | Nowhere | Dead; builds dense n_i × n_i centering matrices; assumes IDs coded 1..m |
| `logis_firth_prov` | `Firth.cpp` | `logis_firth` | One large OpenMP region containing R API calls and functions that can throw |
| `Loglkd_firth` | `Firth.cpp` | Nowhere in R | Dead export |
| `logdet_info` | `Firth.cpp` | Internal C++ | Exported unnecessarily; floor 1e-12, ridge 1e-8 if Cholesky fails |
| `info_beta_tbb` (`Info_beta` worker) | `Fixed_effect.cpp` | Nowhere | The only use of RcppParallel |
| `modString` | `header.cpp` | Nowhere | Rcpp template leftover |

### 5.7 Numerical conventions register (preserve; verify each)

| Convention | Where | Value |
|---|---|---|
| Initial values | `logis_fe`, `logis_firth` | γ_i = logit(ȳ) for every provider; β = 0 |
| Provider-effect bound | SerBIN, BAN, Firth, every iteration | γ clamped to [median(γ) − bound, median(γ) + bound]; `bound = 10` |
| Weight floor in fitting | SerBIN, BAN, `Modified_score` (full model) | p(1 − p) == 0 replaced by 1e-20 |
| Weight floor in Firth | `logis_firth_prov`, `Loglkd_firth` | p(1 − p) == 0 replaced by 1e-10 |
| Probability clamp for variance | `logis_fe_var`, `wald_covar` | p in [1e-10, 1 − 1e-10] |
| Probability clamp in tests | Exact and modified score tests, `summary` score test | p in [1e-10, 1 − 1e-10] |
| Armijo backtracking | SerBIN, BAN | s = 0.01, t = 0.6 (the commented-out R version of BAN used t = 0.8) |
| Stopping rules | SerBIN, BAN, Firth | `beta`: max abs change in β; `relch`: abs(Δℓ / ℓ_new); `ratch`: abs(Δℓ / (ℓ_new − ℓ_0)); `all`: max of the three; `or`: min of the three |
| Default stopping rule | `logis_fe` / Firth | `"or"` / `"beta"`. Because `"or"` stops when any criterion falls below `tol`, a large-data fit may stop while coefficients still move by much more than `tol` (verify empirically); equivalence therefore requires reproducing the iteration path |
| Iteration limits | | `logis_fe` 10,000 (SerBIN can run max + 1); Firth 1,000 |
| Thread defaults | `SM_output` for `logis_fe`, `logis_re`, `logis_cre` | `threads = 2` by default, while fits and `test` default to 1 and RE/CRE `confint` hard-codes 4 (D-21). The fixture generator must pass `threads = 1` explicitly; the rewrite's uniform default of 1 is a recorded decision |
| Log-likelihood | C++ and R | Σ[(γ + Zβ)y − log(1 + exp(γ + Zβ))]; overflows for linear predictors above about 709 |
| Screening | `logis_fe`, `logis_firth` | Included if n_i >= `cutoff` (default 10); no-event and all-event providers flagged but kept |
| Provider ordering | All fits | Data sorted by `factor(ProvID)` levels; outputs keyed by those levels |
| Missing data | All fits | Listwise deletion on the columns used. CRE computes provider means with `na.rm = TRUE` before deletion |
| Design matrix | FE fits | `model.matrix(reformulate(Z.char), data)[, -1]`, so contrasts follow `options("contrasts")` |
| Linear FE residual variance | `linear_fe` | SSR / (n − m − p) |
| Linear FE γ variance | `linear_fe` | `"simplified"`: σ²/n_i; `"full"`: σ²(1/n_i + z̄_i'(Z'QZ)⁻¹z̄_i) |
| Two-sided p-values | Tests | 2·min(p, 1 − p) |
| Rates | Logistic `SM_output` | Ratio × population rate (%), clipped to [0, 100] |
| AUC | `logis_fe`, `logis_firth` | `pROC::auc` on fitted probabilities |

### 5.8 Bundled data

- `ExampleDataBinary`: list of `Y`, `ProvID`, `Z`; simulated; 7,994 observations, 100 providers, 5 continuous covariates.
- `ExampleDataLinear`: same structure; simulated; 7,901 observations, 100 providers, 5 continuous covariates.
- `ecls_data`: data frame of 9,101 children in 2,275 schools (Early Childhood Longitudinal Study) with `Child_ID`, `School_ID`, `Math_Score`, `Income` (18 ordinal levels treated as numeric), and `Child_Sex` (categorical). Many very small schools, so it exercises screening and factor handling.

None of these contains the extreme cases the validation suite needs, so the edge-case suite must be synthetic.

### 5.9 Tests, CI, documentation

- Tests check classes, column names, equality across the three input formats, and error messages. There are no numerical reference values, tolerances, or seeds anywhere in the tests or R code, and `test-plots.R` is empty. Reported coverage is about 59% (R Observatory; confirm with `covr`).
- CI runs `devtools::test()` on `rocker/r-ver:4.3.1` only. There is no `R CMD check` matrix and no coverage job; the R-hub workflow is manual.
- The slowest CRAN check takes about 10 minutes (r-oldrel-windows, per R Observatory), so CRAN-facing tests must stay light.
- `CONTRIBUTING.md` asks contributors to update `NEWS.md`, which does not exist.

### 5.10 Dependencies (preliminary recommendations)

| Package | Current use | Recommendation |
|---|---|---|
| `Rcpp` | R/C++ bridge | Keep |
| `RcppArmadillo` | Linear algebra | Keep; switching libraries changes numerical paths |
| `RcppParallel` | Only the unused TBB worker and link flags | Remove (confirm), which also removes the GNU make requirement |
| `stats` | Core | Keep |
| `lme4` | RE/CRE estimation, `ranef`, conditional variances | Keep; isolate behind one adapter |
| `poibin` | Exact Poisson-binomial tests, intervals, funnel limits | Keep unless replaced by an equivalence-tested implementation |
| `ggplot2` | Plots | Keep |
| `scales` | Percent labels | Keep (cheap: already required by `ggplot2`) |
| `tibble` | Little current use | Keep if tibble outputs are adopted |
| `Matrix` | `bdiag` in `linear_fe` | Remove once centering is done by demeaning (installed via `lme4` anyway) |
| `caret` | `nearZeroVar` in `data_check` only | Remove; base-R reimplementation with the same thresholds |
| `olsrr` | `ols_vif_tol` in `data_check` only | Remove; base-R VIF |
| `pROC` | AUC only; prints messages | Remove; rank-based AUC after an equality test |
| `globals` | Nothing (a dummy function silences an R CMD check note) | Remove |
| `magrittr` | `%>%` | Remove; native pipe (R >= 4.1 already required) |
| `dplyr`, `tidyselect`, `rlang` | CRE decomposition, some plotting, the `.data` pronoun | Remove from the computational core; keep in presentation only if justified |
| `generics` (new) | `tidy`, `glance`, `augment` generics without `broom` | Add |

---

## 6. Preliminary audit findings (verify in Phase 0)

### 6.1 Candidate discrepancies

Proposed classes follow the brief: A may be fixed with a regression test, B needs sign-off, C means fixing docs or messages.

| ID | Where | Finding | Proposed class |
|---|---|---|---|
| D-01 | `logis_fe`, `logis_firth` | Inclusion uses n_i >= cutoff, but the warning counts n_i <= cutoff as filtered out | C |
| D-02 | `logis_fe` docs | `backtrack` documented as default FALSE; code default is TRUE. The `stop` docs refer to `iter.max` instead of `max.iter` | C |
| D-03 | C++ fitters | SerBIN allows max_iter + 1 iterations, BAN max_iter; both print "converged" even when the limit is hit; no convergence status is returned | Preserve iteration semantics; add diagnostics (additive) |
| D-04 | `Modified_score` | Non-finite z-scores are dropped, so one bad provider shortens the result and breaks alignment with provider IDs (likely an error when the result data frame is built) | A |
| D-05 | `logis_firth_prov`, `threads > 1` | `d_beta` is thread-private, assigned in one `omp single` block and read in a later one that may run on a different thread, where it is empty (norm 0), which can stop the algorithm early. `Rcout`, `Rcpp::stop`, and throwing Armadillo calls also run inside the parallel region | A (nondeterministic); fixtures use threads = 1 |
| D-06 | `test.logis_fe` | `"robust_wald"` passes validation but the branch tests `"robust wald"`, so the call returns `NULL` | A |
| D-07 | `plot.logis_fe(test = "exact")` | Reaches `qpoibin` through rlang's `.data` pronoun outside a data mask, which errors; the path is untested | A |
| D-08 | `SM_output.logis_fe` | Uses `fit$obs`, which works only through partial matching of `fit$observation` | A (fragile) |
| D-09 | `print.logis_cre` | Defined but not registered, so printing likely dumps the whole `lme4` fit | A |
| D-10 | `summary.logis_fe` | LR and score tests refit with default settings rather than the original fit's `method`, `tol`, `bound`, `cutoff`, and `stop`; hard-code bound 10; refit twice per covariate. Wald p-values are returned as formatted character strings | B (refit settings); presentation |
| D-11 | `linear_re`, `logis_re` | The vector interface uses `cbind()`, which coerces mixed-type covariates to character; a missing final `else stop()` leads to an obscure error | A |
| D-12 | `logis_firth` | Returns class `logis_fe` with unpenalized variance, log-likelihood, AIC, and BIC | B (methodology question) |
| D-13 | CRE models | Provider means computed with `na.rm = TRUE` before complete-case filtering | B (methodology question) |
| D-14 | Several | `null` validated with `is.numeric()` in `test.logis_fe` but `class(null) == "numeric"` in `SM_output` and plots, so integer values are accepted in one place and rejected in another | A/C |
| D-15 | `test` methods | Flags are factors whose levels depend on which flags occur in the data | Presentation |
| D-16 | `test.linear_fe` | Test distribution chosen by a hidden attribute set at fit time | Preserve; make explicit |
| D-17 | `data_check` vs fits | `data_check` stops on any missing value, while fits silently delete rows | C (document) |
| D-18 | FE fits, formula path | Terms that are not plain column names (for example `log(x)` or `x1:x2`) fail the column-existence check with a misleading message. Dummy names that are not syntactic (factor levels with spaces) are likely broken because `data.frame()` rewrites column names | A |
| D-19 | `confint.logis_fe(option = "SM")` | Results are reordered with `order(as.numeric(colnames(...)))`, which assumes numeric provider IDs | A |
| D-20 | `logis_fe(threads > 1)` | Element-wise OpenMP information matrix differs slightly from the BLAS product used with one thread | Expected; tolerance |
| D-21 | `confint.logis_re`, `confint.logis_cre` | `threads = 4` hard-coded, ignoring the user and conflicting with the CRAN two-core limit | A |

### 6.2 Structural problems

- Input parsing, screening, and data preparation are duplicated across all seven fitting functions; `logis_firth` repeats about 150 lines of `logis_fe` verbatim.
- The block information computation is reimplemented at least five times: SerBIN, `logis_fe_var`, `wald_covar`, `Modified_score`, Firth (twice), plus an R version in `summary.logis_fe`.
- p-value and flag logic for the three alternatives is copied roughly 30 times across `test`, `confint`, and `summary` files.
- Post-estimation methods re-derive provider sizes and sums from `data_include` with `split()` on every call.
- Metadata is stringly typed: `char_list`, attributes such as `"provider size"`, `"description"`, `"model"`, and `"population_rate"`.
- `if (!class(x) %in% ...)` checks would break for multi-class objects (a length-greater-than-one condition errors in R >= 4.2).
- Messaging is inconsistent: a `warning()` gated by the `message` argument, C++ printing through `Rcout`, and `pROC` printing its own messages.
- About 755 lines of commented-out code, including a pure-R SerBIN/BAN implementation in `logis_fe.R`. It could serve as a slow independent reference after reconciling its differences (t = 0.8 in BAN, `> cutoff` rather than `>= cutoff`).
- C++ files use `using namespace` for Rcpp, RcppParallel, std, and arma at global scope, and mix two parallel frameworks.

### 6.3 Performance hot spots (benchmark before acting)

- `linear_fe` multiplies by `bdiag()` of dense n_i × n_i centering blocks, which is O(Σ n_i²) in memory and time. One provider with 50,000 observations alone needs about 20 GB. Direct demeaning is O(np) and mathematically equivalent. The product Z'QZ is also recomputed up to three times.
- `confint.logis_fe(option = "SM")` calls the γ-interval routine once per provider, and each call re-splits the whole dataset, which is roughly O(m·n).
- `summary.logis_fe` LR and score tests run two full refits per covariate.
- Exact tests and interval routines loop over providers in R with `by()` and `sapply()`.
- The log-likelihood is recomputed in R after the C++ fit.

---

## 7. Working conventions and file locations

| Item | Location or rule |
|---|---|
| Branch | `rewrite/v2`; one pull request per phase; stop at each gate |
| Design document | `dev/design/ARCHITECTURE.md` |
| Naming convention | `dev/NAMING.md` |
| Decision records | `dev/DECISIONS.md` |
| Discrepancy register | `dev/DISCREPANCIES.md` (seed it from Section 6.1) |
| Reference generator | `dev/reference/` (script plus isolated library setup) |
| Fixtures | `tests/testthat/fixtures/reference/` with `manifest.json` |
| Large validation suites | `validation/` (build-ignored), run in a dedicated CI job |
| Tolerances | `tests/testthat/helper-tolerances.R`, one justification per entry |
| Benchmarks | `dev/bench/` |
| Naming direction | snake_case; S3 classes prefixed `pprof_`; descriptive verbs such as `fit_logistic_fe()` (illustrative only until Phase 0); C++ in `namespace pprof` |
| C++ layout constraints | `Rcpp::compileAttributes()` scans only top-level `src/`, so Rcpp adapter files stay there. Sources in subdirectories must be listed explicitly in `OBJECTS` in both `Makevars` and `Makevars.win` (no `$(wildcard ...)`, which would reintroduce the GNU make requirement) |

---

## 8. Commands

```r
devtools::load_all()
devtools::document()
Rcpp::compileAttributes()                 # after changing // [[Rcpp::export]] signatures
devtools::test()
testthat::test_file("tests/testthat/test-<name>.R")
rcmdcheck::rcmdcheck(args = c("--as-cran", "--no-manual"))
covr::package_coverage()
tools::package_dependencies("pprof", reverse = TRUE)
options(warnPartialMatchDollar = TRUE, warnPartialMatchArgs = TRUE)  # set in test helpers
```

Rules: at most 2 threads in examples and tests; seeds set explicitly in any test that uses randomness; fixtures never regenerated without approval; heavy validation behind `skip_on_cran()`.

---

## 9. Open questions for the methodology owners

1. Which components are validated, and by what evidence? (The CRE models were added in August 2025 and the Firth correction in February 2026.)
2. Firth: keep the `logis_fe` class with unpenalized variance, log-likelihood, AIC, and BIC (D-12)?
3. CRE: should provider means be computed before or after complete-case filtering (D-13)?
4. Is the "predicted over expected" numerator for RE indirect measures the intended estimand?
5. Should `summary.logis_fe` LR and score refits inherit the original fit's settings (D-10)? This is a Class B change if yes.
6. Should screening (`cutoff`) remain specific to the logistic FE models?
7. Which input interfaces survive: formula, data plus column names, separate vectors and matrices?
8. Minimum R version, release timeline, and deprecation window.

---

## 10. Status and decision log

Update this section at the end of every phase. Move verified findings from Section 6 into `dev/DISCREPANCIES.md` and record decisions in `dev/DECISIONS.md`.

| Date | Entry |
|---|---|
| 2026-10-01 | Static audit of `main` at `5260838`; brief v2 drafted; this file created. Phase 0 not started |
| 2026-10-02 | Local setup on `rewrite/v2` (branched from `5260838`). Windows 11 Enterprise 10.0.22621; R 4.4.0 (ucrt) with Rtools44, GCC 13.3.0; OpenMP yes (`-fopenmp`). `main` is at `5260838` on both `upstream` and `origin` (fork). `devtools::test()`: 173 passed, 0 failed, 0 skipped, 0 warnings (`test-plots.R` is empty). `R CMD check --as-cran --no-manual`: 0 errors, 1 warning (CRAN incoming: version 1.0.3 already on CRAN, Date field over a month old), 5 notes (unable to verify current time; pandoc not installed; new `NEWS.md` has no versioned entry; GNU make in SystemRequirements; six logistic RE/CRE examples over 5 s). Phase 0 not started |
