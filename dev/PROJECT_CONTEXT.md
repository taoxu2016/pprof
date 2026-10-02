# pprof rewrite: project context

Living reference for the `pprof` rewrite. Requirements live in `pprof_rewrite_brief.md`; this file holds facts, conventions, and status. Section 5 began as a static read of `main` at commit `5260838`; Phase 0 verified it by running the reference (`dev/design/audit/`), and §5.7 is now the verified conventions register. The Phase 0 findings moved from §6 to `dev/DISCREPANCIES.md`.

Last updated: 2026-10-02. Status: Phase 1 gate approved (2026-10-02); DEC-019 awaits sign-off. Phase 2 (core infrastructure) not started.

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
| Reverse dependencies | None: `tools::package_dependencies("pprof", reverse = TRUE)` over Depends, Imports, LinkingTo, Suggests, and Enhances of the CRAN index returned nothing (2026-10-02). Breaking changes affect user scripts only |
| Reference oracle | 1.0.3 = `main` at `5260838` (2026-02-09, "debug for cran"), confirmed 2026-10-02: the CRAN tarball (MD5 `6fa1344f4a265811059d27a105d06d6b`, matching the CRAN index) is identical to the commit in `R/`, `src/`, `tests/`, `data/`, `man/`, and `NAMESPACE`; `DESCRIPTION` differs only by `R CMD build` normalization (DEC-002, `dev/design/audit/output/01_cran_identity.log`) |
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
- `summary`: t-based with df n − m − p. Intervals: t-based with df n − m − p for the `"simplified"` variance but normal for `"full"`, the reverse of the tests (D-32).

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

### 5.7 Numerical conventions register (verified in Phase 0)

This is the verified register: the single list of numerical conventions the rewrite must preserve. Each row was confirmed in Phase 0 either by running the reference (evidence IDs such as `V10.1` point to `dev/design/audit/output/`) or, where running adds nothing, by reading the code at `5260838` (marked "code"). The behavior specifications (`dev/design/BEHAVIOR_SPECS.md`) cite these IDs, and the rewrite gives each constant a name in `R/constants.R` or `src/core/constants.h` (ARCHITECTURE §K).

Notation: γ provider effects (fixed effects), α provider effects (random effects), β covariate coefficients, Zβ the covariate linear predictor (Xβ including the intercept for RE models), m providers, n observations, p covariates, ℓ the log-likelihood, α_sig = 1 − level the significance level.

#### Data handling

| ID | Convention | Where | Value or rule | Evidence |
|---|---|---|---|---|
| K-01 | Input formats and precedence | FE fits | formula and data (`id()` term); else data with `Y.char`, `Z.char`, `ProvID.char`; else vectors `Y`, `Z`, `ProvID`. Results identical across formats | V10.11 |
| K-02 | Formula parsing | FE fits; RE fits | Response = first variable of `terms()`. FE provider = text inside `id(...)` by regex; other term labels must be column names. RE provider = text after the term's `|`, trimmed | V10.12, code |
| K-03 | Missing data | all fits | Listwise deletion over the response, provider, and covariate columns only. CRE: provider means computed before deletion (K-54) | V10.14, V15.10 |
| K-04 | Design matrix | FE fits | `model.matrix(reformulate(Z.char), data)[, -1, drop = FALSE]`; factor coding follows `options("contrasts")`; the vector interface first passes `Z` through `data.frame()` (name checking) | V10.13 |
| K-05 | Provider order | all fits | Rows sorted by `order(factor(ProvID))` (stable within provider). Provider order = `factor()` levels: numeric IDs numerically, character IDs by the session's collation locale | V10.10 |
| K-06 | Screening | `logis_fe`, `logis_firth` | Included iff n_i ≥ `cutoff` (default 10). Excluded providers are dropped from every output, including `data_include`. Among included providers, no-events (Σy = 0) and all-events (Σy = n_i) are flagged per observation and kept | V10.8, V10.9 |
| K-07 | No screening | `linear_fe`, RE, CRE | Every provider is kept, whatever its size | code |

#### Logistic fixed effects: SerBIN and BAN (`src/Fixed_effect.cpp`)

| ID | Convention | Where | Value or rule | Evidence |
|---|---|---|---|---|
| K-10 | Initial values | `logis_fe`, `logis_firth` | γ_i = log(ȳ / (1 − ȳ)) for every provider, ȳ over included observations; β = 0 | V10.5 |
| K-11 | Log-likelihood | C++ and R | ℓ = Σ[(γ_i + z'β)y − log(1 + exp(γ_i + z'β))], computed directly (overflows to −Inf above η ≈ 709) | V10.16 |
| K-12 | SerBIN Newton step | `logis_BIN_fe_prov` | Block inverse with D_i = Σ_j w_ij (floored), cross block B_i = Σ_j z_ij p(1 − p) (unfloored), I_ββ = Z' diag(w) Z (floored), Schur complement S = I_ββ − B D⁻¹ B' solved with `arma::solve(…, likely_sympd)`; d_γ = D⁻¹U_γ + D⁻¹B'S⁻¹(BD⁻¹U_γ − U_β), d_β = S⁻¹(U_β − BD⁻¹U_γ) | V10.1 |
| K-13 | Weight floor, fitting | SerBIN (γ and β blocks), BAN (γ step only), `Modified_score` (full-model γ block only) | w = p(1 − p); entries exactly 0 replaced by 1e-20 | V10.1, V10.2, code |
| K-14 | Armijo backtracking | SerBIN, BAN when `backtrack` | s = 0.01, t = 0.6. Accept step v when ℓ(θ + v d) − ℓ(θ) ≥ s·v·λ with λ = U'd; otherwise v ← t·v, with no lower limit. SerBIN searches γ and β jointly on unclamped γ; BAN searches the γ step (β fixed) and then the β step (new γ, old Zβ as the reference ℓ) | V10.3 |
| K-15 | Provider-effect clamp | SerBIN, BAN, Firth, every iteration | After each γ update, γ ← min(max(γ, median(γ) − bound), median(γ) + bound), with the median of the updated, unclamped γ; `bound = 10` | V10.2 |
| K-16 | Stopping criteria | SerBIN, BAN | Δℓ = ℓ(after the update and the clamp) − ℓ_old, with ℓ_old at the start of the iteration and ℓ_init at the starting values. `beta` = max|v·d_β| (BAN: v of the β step; BAN without backtracking: max|d_β|); `relch` = |Δℓ / (Δℓ + ℓ_old)|; `ratch` = |Δℓ / (Δℓ + ℓ_old − ℓ_init)|; `all` = max of the three; `or` = min. Criterion starts at 100; the loop stops when criterion < tol, checked at the top of each iteration | V10.1 |
| K-17 | Iteration limits and defaults | `logis_fe` | SerBIN `while (iter <= max_iter)` (up to max_iter + 1 iterations); BAN `while (iter < max_iter)`. Defaults `method = "SerBIN"`, `max.iter = 10000`, `tol = 1e-5`, `stop = "or"`, `backtrack = TRUE`, `bound = 10`, `cutoff = 10`. BAN treats `backtrack` as an integer and runs no iterations unless it is 0 or 1 (D-23) | V10.4, V10.6 |
| K-18 | Threads in SerBIN | `logis_BIN_fe_prov` | `threads > 1`: element-wise OpenMP dot products for I_ββ; `threads == 1`: one BLAS product; `threads < 1`: uninitialized (D-22). The two valid paths agree to about 1e-15 relative | V11.2, V10.7 |
| K-19 | Default stop = "or" stops early | `logis_fe` | On large data the fit stops while provider effects still move (0.04 logit error at n = 1.2M); β is within 4e-6 of a tight fit. Equivalence therefore requires reproducing the iteration path, not only the optimum (D-24) | V11.1 |
| K-20 | Variance | `logis_fe_var` | p clamped to [1e-10, 1 − 1e-10] (no 1e-20 floor). Var(β) = S⁻¹ via `inv_sympd`; Var(γ_i) = 1/D_i + J_i'S⁻¹J_i with J_i = B_i / D_i | V10.17 |
| K-21 | Information criteria | `logis_fe`, `logis_firth` | AIC = −2ℓ + 2(m + p); BIC = −2ℓ + log(n)(m + p); n = included observations | V10.16 |
| K-22 | AUC | `logis_fe`, `logis_firth` | `pROC::auc(y, fitted)`, equal to the Mann–Whitney estimate with ties counted one half | V10.15 |
| K-23 | Fitted values | `logis_fe`, `logis_firth` | plogis(γ_i + z'β), unclamped | code |

#### Firth correction (`src/Firth.cpp`)

| ID | Convention | Where | Value or rule | Evidence |
|---|---|---|---|---|
| K-30 | Penalized log-likelihood | `logis_firth_prov` | ℓ* = ℓ + ½ log det I; log det I = Σ_i log(max(D_i, 1e-12)) + 2 Σ log diag(chol((S + S')/2)), retrying with ridge 1e-8·I if Cholesky fails, then erroring | V12.1 |
| K-31 | Weight floor | Firth | w = p(1 − p); entries exactly 0 replaced by 1e-10, in every block | V12.1, code |
| K-32 | Firth step | Firth | Modified residual y − p + h(½ − p), with hat value h_ij = w_ij x_ij' I⁻¹ x_ij from the block inverse; full Newton step d = I⁻¹U* without line search; clamp (K-15) after the γ update; information recomputed after the clamp | V12.1 |
| K-33 | Firth stopping | Firth | Criterion = max|d_β| only (rule fixed to "beta", not exposed); continue while iter < max_iter and criterion > tol (criterion starts at 1e9). Defaults `max.iter = 1000`, `tol = 1e-5`, `bound = 10`, `cutoff = 10` | V12.1, V12.4 |
| K-34 | Firth outputs | `logis_firth` | Class `logis_fe`; variance, Loglkd, AIC, BIC are the unpenalized quantities at the Firth estimates (D-12) | V12.2 |

#### Linear fixed effects (`R/linear_fe.R`)

| ID | Convention | Where | Value or rule | Evidence |
|---|---|---|---|---|
| K-40 | Estimates | `linear_fe` | β = (Z'QZ)⁻¹Z'Qy with Q = blockdiag(I − 11'/n_i) built densely with `Matrix::bdiag`; γ_i = ȳ_i − z̄_i'β. Agrees with `lm()` on provider indicators to 2e-14 | V14.1 |
| K-41 | Residual variance | `linear_fe` | σ² = SSR / (n − m − p); Var(β) = σ²(Z'QZ)⁻¹ | V14.1, V14.2 |
| K-42 | Provider-effect variance | `linear_fe` | `"simplified"` (default): σ²/n_i; `"full"`: σ²(1/n_i + z̄_i'(Z'QZ)⁻¹z̄_i). Accepted values: "simplified", "s", "full", "f" | V14.2, V14.7 |
| K-43 | Log-likelihood and criteria | `linear_fe` | ℓ = −(n/2)log(2π) − (n/2)log(SSR/n) − n/2; AIC = −2ℓ + 2(m + p + 1); BIC = −2ℓ + (m + p + 1)log(n) | V14.2 |

#### Random and correlated random effects (lme4)

| ID | Convention | Where | Value or rule | Evidence |
|---|---|---|---|---|
| K-50 | Engine calls | `linear_re`, `logis_re`, CRE | `lmer(formula, data, ...)` (REML by default); `glmer(formula, data, family = binomial(link = "logit"), ...)` (Laplace, nAGQ = 1). Data sorted by provider first. Column interface formula: `Y ~ (1| ProvID) + z1 + …`; CRE formula: `Y ~ <within> + <between> + <other> + (1 | ProvID)` | V15.1 |
| K-51 | Variance component | RE, CRE | (first row of `VarCorr` `sdcor`)² in `linear_re`, `logis_re`, `linear_cre`; `vcov` in `logis_cre` (equal on the example data) | V15.2 |
| K-52 | Effects | RE, CRE | `fixef()` (with intercept); `ranef()` conditional modes, row names reset to the provider order of K-05 | V15.13 |
| K-53 | Linear predictor and fitted | RE, CRE | linear_pred = Xβ including the intercept; fitted = lme4 `fitted()` (including α_i) | code |
| K-54 | CRE decomposition | `linear_cre`, `logis_cre` | x_bar = provider mean with `na.rm = TRUE` over every row of the input data; x_within = x − x_bar; then column selection and complete-case filtering (D-13) | V15.10 |

#### Provider tests

| ID | Convention | Where | Value or rule | Evidence |
|---|---|---|---|---|
| K-60 | Null value | all `test`, `SM_output`, `confint` | Logistic FE: `"median"` = median(γ̂) over included providers, or a number. Linear FE: also `"mean"` = Σn_iγ̂_i / n. RE/CRE: a number, default 0. Integer null accepted only by `test.logis_fe` (D-14) | V13.9, V14.3 |
| K-61 | Significance level | everywhere | α_sig = 1 − level, computed in floating point (1 − 0.95 = 0.050000000000000044); quantiles use α_sig/2 and 1 − α_sig/2 from that value | V13.15 |
| K-62 | Exact Poisson-binomial test | `test.logis_fe` (default) | p0 = plogis(γ0 + Zβ) clamped to [1e-10, 1 − 1e-10]; o = provider event count; F, f = `poibin::ppoibin`, `dpoibin`. Two-sided: upper mid-p = 1 − F(o) + ½f(o), p-value = 2 min(p, 1 − p), statistic = qnorm(p, lower.tail = FALSE). Greater: p = 1 − F(o − 1) (1 when o = 0), statistic qnorm(p, lower.tail = FALSE). Less: p = F(o), statistic qnorm(p) | V13.1, V13.2 |
| K-63 | Flag rule | all provider tests | With prob = upper-tail probability: two-sided flag 1 if prob < α_sig/2, 0 if prob ≤ 1 − α_sig/2, else −1 (RE/CRE write the same rule as "−1 if prob > 1 − α_sig/2"); greater: 1 if p < α_sig else 0; less: −1 if p < α_sig else 0, where Wald-type tests use p = 1 − prob | V13.1, V13.7, V15.14 |
| K-64 | Bootstrap test | `test.logis_fe(test = "exact.bootstrap")` | Providers in K-05 order; for each, `colSums(matrix(rbinom(n_i·n, 1, rep(p0, n)), ncol = n))` with clamped p0; two-sided p = (#{S > o} + ½#{S = o})/n; greater #{S ≥ o}/n; less #{S ≤ o}/n; default n = 10000; draws from the user's RNG stream | V13.3 |
| K-65 | Modified score test | `test.logis_fe(test = "score")` (default `score_modified = TRUE`) | z_i = Σ(y − p0) / sqrt(Σ p0(1 − p0)), p0 clamped, unrestricted β | V13.4 |
| K-66 | "Standard" score test | `Modified_score` | No refit: full-model γ̂_(−i) and β̂; p0 for provider i unclamped; V = I_αα − I_αβ (I_ββ* − I_βγ I_γγ⁻¹ I_γβ)⁻¹ I_βα with I_ββ* using null weights for provider i; full-model γ block floored at 1e-20, cross block unfloored; `inv_sympd`. Non-finite statistics dropped (D-04) | V13.5, V13.6 |
| K-67 | Wald provider test, logistic FE | `test.logis_fe(test = "wald")` | z = (γ̂ − γ0)/sqrt(Var γ̂) with K-20 variances; always warns | V13.7 |
| K-68 | Linear FE test | `test.linear_fe` | z = (γ̂ − γ0)/se; normal reference with the simplified variance, t(n − m − p) with the full variance | V14.3 |
| K-69 | Linear RE test | `test.linear_re` | se = sqrt(R_i σ²/n_i), R_i = σ²_α / (σ²_α + σ²/n_i), equal to lme4's conditional SD to 4e-16 | V15.3 |
| K-70 | Other RE/CRE tests | `test.logis_re`, `test.logis_cre`, `test.linear_cre` | se = sqrt(postVar) from `ranef(condVar = TRUE)`; z = (α̂ − null)/se | V15.3, V15.14 |

#### Standardized measures

| ID | Convention | Where | Value or rule | Evidence |
|---|---|---|---|---|
| K-80 | Logistic FE indirect | `SM_output.logis_fe` | O_i = Σy; E_i = Σ plogis(γ0 + Zβ) (unclamped); Var_i = Σ E(1 − E); ratio O_i/E_i; rate = min(max(ratio × r, 0), 100) with population rate r = 100 Σy / n over included observations | V13.12 |
| K-81 | Logistic FE direct | `SM_output.logis_fe` | E_i = Σ_j over all observations of plogis(γ̂_i + z_j'β) (`computeDirectExp`); ratio E_i / Σy; rate as K-80 | V13.12 |
| K-82 | Logistic RE/CRE | `SM_output.logis_re`, `.logis_cre` | Indirect: Σ fitted (including α_i) / Σ plogis(Xβ), predicted over expected; direct: Σ_j plogis(α̂_i + x_j'β) / Σy; rates as K-80 | V15.4 |
| K-83 | Linear FE | `SM_output.linear_fe` | Indirect difference (O_i − E_i)/n_i with E_i = Σ(γ0 + Zβ); direct difference (Σ_j(γ̂_i + z_j'β) − Σ_j(γ0 + z_j'β))/n. Both equal γ̂_i − γ0 up to rounding | V14.5 |
| K-84 | Linear RE/CRE | `SM_output.linear_re`, `.linear_cre` | Indirect (Σ fitted − ΣXβ)/n_i; direct (Σ_j(α̂_i + x_j'β) − Σy)/n | V15.5 |
| K-85 | Direct expectations threading | `computeDirectExp` | Results identical for 1 and 2 threads | V13.14 |

#### Intervals

| ID | Convention | Where | Value or rule | Evidence |
|---|---|---|---|---|
| K-90 | Logistic FE provider-effect intervals | `confint.logis_fe(option = "gamma")` | Test inversion with `uniroot()` at its defaults (tol = `.Machine$double.eps^0.25`, maxiter 1000). Upper limit bracket γ̂ + [5k, 5(k + 1)], lower γ̂ − [5(k + 1), 5k], k = 0, 1, 2, else ±Inf. Exact: the mid-p functions of K-62 set to α_sig/2. Score: (o − Σp)/sqrt(Σp(1 − p)) ± qnorm(α_sig/2, lower.tail = FALSE). No-event providers: (−Inf, U] with bracket (10 + max|Zβ|)·[−k, k], k = 1, 2, 3, solving ½∏(1 − p) = α_sig (exact) or z_α − Σp/sqrt(Σp(1 − p)) = 0 (score). All-event providers: [L, Inf) with ½∏p = α_sig (exact) or Σ(1 − p)/sqrt(Σw) − z_α = 0 with w floored at 1e-20 (score). Wald: γ̂ ± qnorm(1 − α_sig/2)·se | V13.15, code |
| K-91 | Logistic FE measure intervals | `confint.logis_fe(option = "SM")` | Indirect: [Σ plogis(γ_L + Zβ)/E_i, Σ plogis(γ_U + Zβ)/E_i]; no-event lower 0 (upper n_i/E_i when `greater`); all-event upper n_i/E_i (lower 0 when `less`). Direct: the same with sums over all observations and denominator Σy; no-event `greater` upper n/Σy; all-event upper n/Σy. Rates clipped as K-80 | code |
| K-92 | Linear FE intervals | `confint.linear_fe` | γ̂ ± c·se with c = qt(·, n − m − p) for the simplified variance and qnorm(·) for the full variance (D-32); measure intervals shift by the same amount | V14.4 |
| K-93 | RE/CRE intervals | `confint` for RE/CRE | α̂ ± qnorm(·)·se (se as K-69/K-70); logistic measure intervals map limits through plogis sums; linear through sums | V15.14, code |
| K-94 | One-sided intervals | all `confint` | Critical value qnorm(1 − α_sig) (or qt); the open side is ±Inf, or 0 and n_i/E_i for logistic measures | code |

#### Covariate summaries

| ID | Convention | Where | Value or rule | Evidence |
|---|---|---|---|---|
| K-100 | Logistic FE Wald | `summary.logis_fe` | p = 2(1 − pnorm(|z|)) returned as `format.pval(p, digits = 7, eps = 1e-10)` strings; interval β ± qnorm(1 − α_sig/2)·se | V13.20 |
| K-101 | Logistic FE LR | `summary.logis_fe(test = "lr")` | −2ℓ with γ clamped to median ± 10 in both models; null model refit by `logis_fe` with default settings; statistic −2ℓ_null − (−2ℓ_full); p = pchisq(·, 1, lower.tail = FALSE); `null` must be 0 (D-10, D-30) | V13.19 |
| K-102 | Logistic FE score | `summary.logis_fe(test = "score")` | Null refit as K-101; p clamped to [1e-10, 1 − 1e-10]; efficient information for the added covariate from the block inverse; statistic U²/I; chi-square(1) p-value | code, V13.19 |
| K-103 | Linear FE | `summary.linear_fe` | t test, df n − p − m; interval β ± qt(1 − α_sig/2, n − p − m)·se; p as strings | V14.6 |
| K-104 | Linear RE/CRE | `summary.linear_re`, `.linear_cre` | t p-values with df n − p_FE − m + 1; intervals from `lme4::confint(method = "Wald")` (normal) | V15.7 |
| K-105 | Logistic RE/CRE | `summary.logis_re`, `.logis_cre` | p = 2(1 − pnorm(z)) without `abs()` (D-31); intervals from `lme4::confint(method = "Wald")` | V15.6 |

#### Plots and diagnostics

| ID | Convention | Where | Value or rule | Evidence |
|---|---|---|---|---|
| K-110 | Logistic funnel (score) | `plot.logis_fe` | precision = E_i²/Var_i (K-80); limits target ± qnorm(1 − α/2)·sqrt(1/precision) with the user's `alpha` used directly, lower limit clipped at 0; flags from the modified score test at level 1 − alpha[1] | V13.21, code |
| K-111 | Linear funnel | `plot.linear_fe` | precision = n_i; limits target ± qnorm(1 − α/2)·σ/sqrt(n_i); flags from `test.linear_fe` | V14.8, code |
| K-112 | Caterpillar flags | `caterpillar_plot` | Higher if lower limit > reference, lower if upper limit < reference; reference 0 (differences), 1 (ratios), the population rate (rates) | V16.2, code |
| K-113 | Flag bar plot | `bar_plot` | Provider-size groups from `quantile(size, (0:g)/g)` breaks with `include.lowest = TRUE`, default g = 4, plus "Overall" | V16.2, code |
| K-120 | Data checks | `data_check` | Stop on any missing value; `caret::nearZeroVar(saveMetrics = TRUE)` defaults (freqCut 95/5, uniqueCut 10): zero variance stops, near-zero warns; |r| > 0.9 warns; `olsrr::ols_vif_tol` VIF ≥ 10 warns | V16.1, code |

#### Thread counts

| ID | Convention | Where | Value or rule | Evidence |
|---|---|---|---|---|
| K-130 | Reference thread defaults | everywhere | Fits and `test` default to 1; logistic `SM_output` defaults to 2 and is called with that default by `confint.logis_fe`, `plot.logis_fe`, and the RE/CRE intervals; RE/CRE direct intervals hard-code 4 (D-21). The fixture generator passes `threads = 1` explicitly; the rewrite defaults to 1 everywhere (DEC-001) | V15.11 |

### 5.8 Bundled data

- `ExampleDataBinary`: list of `Y`, `ProvID`, `Z`; simulated; 7,944 observations (its help says 7,994, D-35), 100 providers of 50–103 observations, 5 continuous covariates; 3 no-event providers (IDs 40, 49, 81) and no all-event provider. `ProvID` is numeric.
- `ExampleDataLinear`: same structure; simulated; 7,901 observations, 100 providers of 54–99, 5 continuous covariates.
- `ecls_data`: tibble of 9,101 children in 2,275 schools (Early Childhood Longitudinal Study) with `Child_ID`, `School_ID` (numeric), `Math_Score`, `Income` (18 ordinal levels treated as numeric), and `Child_Sex` (factor with levels "1", "2"). 1,195 schools have one child and only 334 have at least 10, so it exercises screening and factor handling.

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

## 6. Audit findings (verified in Phase 0)

The static-audit candidates that used to be listed here were all checked by running the reference in Phase 0. None was refuted; several were sharpened, and 16 new findings were added.

| Former content | Now in |
|---|---|
| §6.1 candidate discrepancies D-01 to D-21 | `dev/DISCREPANCIES.md`, verified entries D-01 to D-21, plus new entries D-22 to D-37 |
| §6.2 structural problems | `dev/design/ARCHITECTURE.md` §A.2 to §A.6 |
| §6.3 performance hot spots | `dev/design/ARCHITECTURE.md` §A.7 and §F, with measurements B1 to B5 |

Points that changed on verification:

- D-05 is worse than suspected: with two threads, Firth stopped after 1 to 5 iterations and beta was off by up to 0.57 (V12.3).
- D-19 misaligns intervals for every provider after the first no-event provider when IDs are not numeric: 61 of 100 in the example (V13.16).
- The `stop = "or"` concern (now D-24) holds for provider effects (up to 0.04 logit units at n = 1.2M) but not for beta, which stayed within 4.2e-6 of a tight fit (V11.1).
- D-20 (threads > 1 in SerBIN) is a rounding-level difference, at most 1.4e-15 relative, and deterministic (V11.2).
- D-09 is presentation-only, and the registered RE print methods also print the whole object.
- `summary.logis_fe` LR and score tests also fail with one or two covariates (D-30), and D-10 also breaks when the fit used `cutoff < 10`.

---

## 7. Working conventions and file locations

| Item | Location or rule |
|---|---|
| Branch | `rewrite/v2`; each phase on a branch off it (Phase 1: `rewrite/phase-1`) with one pull request into `rewrite/v2`; stop at each gate |
| Design document | `dev/design/ARCHITECTURE.md` (sections A–M) |
| Behavior specifications | `dev/design/BEHAVIOR_SPECS.md` |
| Phase 0 audit scripts and logs | `dev/design/audit/` (evidence IDs `Vxx.y`, `Bx`) |
| Naming convention | `dev/NAMING.md` |
| Decision records | `dev/DECISIONS.md` |
| Discrepancy register | `dev/DISCREPANCIES.md` (D-01 to D-37 after Phase 0; D-38 added in Phase 1) |
| Reference library | `dev/reference/lib/` (gitignored), built by `dev/reference/setup_reference_library.R`; recorded in `dev/reference/library-lock.json` (DEC-017) |
| Reference generator | `dev/reference/`: `datasets.R`, `cases.R`, `generate_fixtures.R`, `compare_fixtures.R` (diff report); see `dev/reference/README.md` |
| Case runner | `tests/testthat/helper-reference-cases.R`, shared by the generator and the tests (DEC-018) |
| Fixtures | Core set (shipped): `tests/testthat/fixtures/reference/` with `manifest.json` and `datasets/`; full set: `validation/fixtures/reference/` |
| Characterization tests | `tests/testthat/test-reference-*.R`, with helpers `helper-fixtures.R` and `helper-equivalence.R` |
| Large validation suites | `validation/` (build-ignored): the full fixture set, `run-reference.R`, and `equivalence-report.md`; a dedicated CI job from Phase 2 |
| Tolerances | `tests/testthat/helper-tolerances.R`, one justification per entry (the `root` entry's relative part awaits sign-off, DEC-019) |
| Benchmarks | `dev/bench/`: `scenarios.R`, `run_reference.R`, `compare_to_baseline.R`; baselines in `dev/bench/results/` |
| Naming | `dev/NAMING.md` (approved with the Phase 0 gate; authoritative) |
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

Reference capture and validation, from the repository root (`Rscript` on this machine needs the R and Rtools `bin` directories on the PATH):

```sh
Rscript dev/reference/setup_reference_library.R     # build the pinned reference library, once per machine
Rscript dev/reference/generate_fixtures.R --out-core <tmp>/core --out-full <tmp>/full   # regenerate, only with approval
Rscript dev/reference/compare_fixtures.R tests/testthat/fixtures/reference <tmp>/core --report <tmp>/core-diff.md
Rscript validation/run-reference.R                  # both fixture sets; writes validation/equivalence-report.md
Rscript dev/bench/run_reference.R                   # benchmark baseline on the reference library
Rscript dev/bench/compare_to_baseline.R dev/bench/results/<baseline>.csv <new>.csv --report <report>.md
```

Rules: at most 2 threads in examples and tests; seeds set explicitly in any test that uses randomness; fixtures never regenerated without approval; heavy validation behind `skip_on_cran()`.

---

## 9. Open questions for the methodology owners

The current list is M-1 to M-16 in `dev/design/ARCHITECTURE.md` §M, each with a proposed default that reproduces the reference. After Phase 0, new questions are added here.

| Earlier question | Now |
|---|---|
| 1. Which components are validated, and by what evidence? | M-1 |
| 2. Firth: keep the `logis_fe` class with unpenalized variance, log-likelihood, AIC, and BIC? | M-2 (D-12) |
| 3. CRE: provider means before or after complete-case filtering? | M-3 (D-13) |
| 4. Is the "predicted over expected" numerator of RE indirect measures intended? | M-14 |
| 5. Should LR and score refits inherit the original fit's settings? | M-5 (D-10) |
| 6. Should screening remain specific to the logistic FE models? | M-13 |
| 7. Which input interfaces survive? | M-6 (DEC-003) |
| 8. Minimum R version, release timeline, deprecation window | M-12 |

New in Phase 0: M-4 (default stopping rule, D-24), M-7 (the "standard" score test, D-26), M-8 (linear FE interval distribution, D-32), M-9 (exact funnel limits, D-07), M-10 (logistic RE/CRE p-values above 1, D-31), M-11 (locale-independent provider order, D-34), M-15 (α versus α/2 for extreme providers' intervals, K-90), M-16 (who signs off).

Added after Phase 0:

| ID | Question | Proposed default | Related |
|---|---|---|---|
| M-17 | With exactly collinear covariates the logistic FE fit returns unidentified coefficients with variances near 7e13 and no warning about the rank deficiency. Should the rewrite warn (numbers unchanged), stop with an error, or drop aliased columns as `glm()` does? | reproduce the numbers and add a classed warning | D-38 |

---

## 10. Status and decision log

Update this section at the end of every phase. Move verified findings from Section 6 into `dev/DISCREPANCIES.md` and record decisions in `dev/DECISIONS.md`.

| Date | Entry |
|---|---|
| 2026-10-01 | Static audit of `main` at `5260838`; brief v2 drafted; this file created. Phase 0 not started |
| 2026-10-02 | Local setup on `rewrite/v2` (branched from `5260838`). Windows 11 Enterprise 10.0.22621; R 4.4.0 (ucrt) with Rtools44, GCC 13.3.0; OpenMP yes (`-fopenmp`). `main` is at `5260838` on both `upstream` and `origin` (fork). `devtools::test()`: 173 passed, 0 failed, 0 skipped, 0 warnings (`test-plots.R` is empty). `R CMD check --as-cran --no-manual`: 0 errors, 1 warning (CRAN incoming: version 1.0.3 already on CRAN, Date field over a month old), 5 notes (unable to verify current time; pandoc not installed; new `NEWS.md` has no versioned entry; GNU make in SystemRequirements; six logistic RE/CRE examples over 5 s). Phase 0 not started |
| 2026-10-02 | Phase 0 (audit and design) complete; awaiting gate approval. Reference confirmed: the CRAN 1.0.3 tarball is identical to `5260838` (DEC-002); no reverse dependencies. Audit (`dev/design/audit/`): 76 runtime checks against the reference installed from CRAN into an isolated library; no static-audit hypothesis refuted; R ports of SerBIN, BAN, and Firth reproduce the C++ paths with the same iteration counts (beta bitwise, gamma within 2e-15). Registers: D-01 to D-21 verified, D-22 to D-37 added (16 A, 7 B awaiting sign-off, 9 C, 3 presentation-only, 2 without class); §5.7 rewritten as the verified register (69 entries, K-01 to K-130). Design: `dev/design/ARCHITECTURE.md` (A–M), `dev/design/BEHAVIOR_SPECS.md`, `dev/NAMING.md`, all proposed; decisions DEC-002 to DEC-016 proposed; open questions M-1 to M-16. Gate checks: `devtools::document()` with roxygen2 8.1.0 rewrote the formatting of `NAMESPACE` and `DESCRIPTION` only (parsed namespace identical, `man/` unchanged; both files restored, DEC-016); `devtools::test()` 173 passed, 0 failed, 0 skipped, 0 warnings; `R CMD check --as-cran --no-manual` 0 errors, 1 warning, 5 notes, the same as the setup baseline, except that the slow-examples note now lists nine logistic RE/CRE examples (elapsed 5.7–7.8 s) instead of six. On this machine `Rscript` is not on the Bash tool's PATH; prefix the R and Rtools `bin` directories. Next step: gate approval and designation of the methodology owners (M-16), then Phase 1 (reference capture) |
| 2026-10-02 | Phase 0 gate approved by the project lead. The proposed decisions DEC-002 to DEC-016, the naming convention (`dev/NAMING.md`), and the design (`dev/design/ARCHITECTURE.md`) are recorded as accepted with the gate. Open questions M-1 to M-16 remain open; no methodology owner is designated yet (M-16), so the seven Class B items stay reproduced and awaiting sign-off. Phase 1 (reference capture) started; first step is a plan for approval. Next step: plan approval, then the pinned reference library and the fixture generator |
| 2026-10-02 | Phase 1 (reference capture) complete; awaiting gate approval. The project lead approved the Phase 1 plan (snapshot pinning, CI deferred to Phase 2, branch `rewrite/phase-1` off `rewrite/v2`, shipped fixtures at most 5 MB). Reference library: pprof 1.0.3 from the MD5-checked CRAN tarball and 131 dependencies from the CRAN snapshot of 2026-10-01 (`Deriv` 4.2.0 from the CRAN Archive), isolated in `dev/reference/lib` (DEC-017). Fixtures (DEC-018): core set of 234 cases and 28 datasets (3.7 MB) in `tests/testthat/fixtures/reference/`, full set of 32 cases (6.8 MB) in `validation/fixtures/reference/`, generated at `a593a09` from a clean tree; a second generation was identical. Characterization tests: `tests/testthat/test-reference-*.R`. Equivalence report (`validation/equivalence-report.md`): all 266 cases match the reference bitwise (largest difference 0, attributes included; 703 of 703 long double vectors bitwise identical; 26 reference errors reproduced; no provider within tolerance of a flag threshold). Benchmark baseline (`dev/bench/results/reference-baseline-20261002-windows.csv`, DEC-023): 48 tasks, 47 measured and 1 recorded as infeasible (`linear_fe` with dense centering). Registers: D-38 added (collinear covariates, Class C proposed), M-17 added, DEC-017 to DEC-023 proposed; DEC-019 (relative part of the root tolerance) needs sign-off. Gate checks: `devtools::document()` again rewrote only the formatting of `NAMESPACE` and `DESCRIPTION` (parsed namespace identical: 86 imports, 12 exports, 29 S3 methods, 1 dynamic library; both restored, DEC-016; `man/` unchanged); `devtools::test()` 267 tests, 1,216 expectations, 0 failed, 0 skipped, 0 warnings (156 s); `R CMD check --as-cran --no-manual` 0 errors, 1 warning, 5 notes, the same as the Phase 0 gate (the slow-examples note lists the same nine logistic RE/CRE examples, 5.2–6.2 s), with tests taking 110 s instead of 72 s and the source tarball 4.45 MB instead of 0.84 MB. Not covered from the ARCHITECTURE §G.2 grid: `control` in RE/CRE fits, and three seeds of one bootstrap configuration (three different seeds are used across configurations); adding cases needs an approved regeneration. Next step: gate approval; then Phase 2 (core infrastructure), starting with a plan |
| 2026-10-02 | Phase 1 gate approved by the project lead. DEC-017, DEC-018, and DEC-020 to DEC-023 are recorded as accepted with the gate. DEC-019 (relative part of the root tolerance) still awaits explicit sign-off; until then `tests/testthat/helper-tolerances.R` keeps it as implemented, and on this machine every interval matches bitwise either way. The two uncovered ARCHITECTURE §G.2 grid items (`control` in RE/CRE fits; three seeds of one bootstrap configuration) remain open and need an approved regeneration. Open questions M-1 to M-17 remain open; no methodology owner is designated yet (M-16). Next step: Phase 2 (core infrastructure) starts with a plan for approval when the project lead asks for it |
