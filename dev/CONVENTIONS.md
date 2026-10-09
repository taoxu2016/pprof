# Numerical conventions

The numerical conventions of pprof 1.0.3 (commit `5260838`) that the package reproduces, with IDs `K-xx`. Each was verified in Phase 0 of the v2 rewrite, either by running the reference (evidence IDs such as `V10.1`, the logs of the Phase 0 audit, which `dev/README.md` locates) or, where running adds nothing, by reading its code (marked "code"). `dev/design/BEHAVIOR_SPECS.md` and the code cite these IDs, and each constant has a name in `R/constants.R` or `src/core/constants.h` (ARCHITECTURE §K). A change to any of them changes results and is a Class B change (`dev/DISCREPANCIES.md`). This register was §5.7 of the rewrite's PROJECT_CONTEXT.

Notation: γ provider effects (fixed effects), α provider effects (random effects), β covariate coefficients, Zβ the covariate linear predictor (Xβ including the intercept for RE models), m providers, n observations, p covariates, ℓ the log-likelihood, α_sig = 1 − level the significance level.

## Data handling

| ID | Convention | Where | Value or rule | Evidence |
|---|---|---|---|---|
| K-01 | Input formats and precedence | FE fits | formula and data (`id()` term); else data with `Y.char`, `Z.char`, `ProvID.char`; else vectors `Y`, `Z`, `ProvID`. Results identical across formats | V10.11 |
| K-02 | Formula parsing | FE fits; RE fits | Response = first variable of `terms()`. FE provider = text inside `id(...)` by regex; other term labels must be column names. RE provider = text after the term's `|`, trimmed | V10.12, code |
| K-03 | Missing data | all fits | Listwise deletion over the response, provider, and covariate columns only. CRE: provider means computed before deletion (K-54) | V10.14, V15.10 |
| K-04 | Design matrix | FE fits | `model.matrix(reformulate(Z.char), data)[, -1, drop = FALSE]`; factor coding follows `options("contrasts")`; the vector interface first passes `Z` through `data.frame()` (name checking) | V10.13 |
| K-05 | Provider order | all fits | Rows sorted by `order(factor(ProvID))` (stable within provider). Provider order = `factor()` levels: numeric IDs numerically, character IDs by the session's collation locale | V10.10 |
| K-06 | Screening | `logis_fe`, `logis_firth` | Included iff n_i ≥ `cutoff` (default 10). Excluded providers are dropped from every output, including `data_include`. Among included providers, no-events (Σy = 0) and all-events (Σy = n_i) are flagged per observation and kept | V10.8, V10.9 |
| K-07 | No screening | `linear_fe`, RE, CRE | Every provider is kept, whatever its size | code |

## Logistic fixed effects: SerBIN and BAN (`src/Fixed_effect.cpp`)

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

## Firth correction (`src/Firth.cpp`)

| ID | Convention | Where | Value or rule | Evidence |
|---|---|---|---|---|
| K-30 | Penalized log-likelihood | `logis_firth_prov` | ℓ* = ℓ + ½ log det I; log det I = Σ_i log(max(D_i, 1e-12)) + 2 Σ log diag(chol((S + S')/2)), retrying with ridge 1e-8·I if Cholesky fails, then erroring | V12.1 |
| K-31 | Weight floor | Firth | w = p(1 − p); entries exactly 0 replaced by 1e-10, in every block | V12.1, code |
| K-32 | Firth step | Firth | Modified residual y − p + h(½ − p), with hat value h_ij = w_ij x_ij' I⁻¹ x_ij from the block inverse; full Newton step d = I⁻¹U* without line search; clamp (K-15) after the γ update; information recomputed after the clamp | V12.1 |
| K-33 | Firth stopping | Firth | Criterion = max|d_β| only (rule fixed to "beta", not exposed); continue while iter < max_iter and criterion > tol (criterion starts at 1e9). Defaults `max.iter = 1000`, `tol = 1e-5`, `bound = 10`, `cutoff = 10` | V12.1, V12.4 |
| K-34 | Firth outputs | `logis_firth` | Class `logis_fe`; variance, Loglkd, AIC, BIC are the unpenalized quantities at the Firth estimates (D-12) | V12.2 |

## Linear fixed effects (`R/linear_fe.R`)

| ID | Convention | Where | Value or rule | Evidence |
|---|---|---|---|---|
| K-40 | Estimates | `linear_fe` | β = (Z'QZ)⁻¹Z'Qy with Q = blockdiag(I − 11'/n_i) built densely with `Matrix::bdiag`; γ_i = ȳ_i − z̄_i'β. Agrees with `lm()` on provider indicators to 2e-14 | V14.1 |
| K-41 | Residual variance | `linear_fe` | σ² = SSR / (n − m − p); Var(β) = σ²(Z'QZ)⁻¹ | V14.1, V14.2 |
| K-42 | Provider-effect variance | `linear_fe` | `"simplified"` (default): σ²/n_i; `"full"`: σ²(1/n_i + z̄_i'(Z'QZ)⁻¹z̄_i). Accepted values: "simplified", "s", "full", "f" | V14.2, V14.7 |
| K-43 | Log-likelihood and criteria | `linear_fe` | ℓ = −(n/2)log(2π) − (n/2)log(SSR/n) − n/2; AIC = −2ℓ + 2(m + p + 1); BIC = −2ℓ + (m + p + 1)log(n) | V14.2 |

## Random and correlated random effects (lme4)

| ID | Convention | Where | Value or rule | Evidence |
|---|---|---|---|---|
| K-50 | Engine calls | `linear_re`, `logis_re`, CRE | `lmer(formula, data, ...)` (REML by default); `glmer(formula, data, family = binomial(link = "logit"), ...)` (Laplace, nAGQ = 1). Data sorted by provider first. Column interface formula: `Y ~ (1| ProvID) + z1 + …`; CRE formula: `Y ~ <within> + <between> + <other> + (1 | ProvID)` | V15.1 |
| K-51 | Variance component | RE, CRE | (first row of `VarCorr` `sdcor`)² in `linear_re`, `logis_re`, `linear_cre`; `vcov` in `logis_cre` (equal on the example data) | V15.2 |
| K-52 | Effects | RE, CRE | `fixef()` (with intercept); `ranef()` conditional modes, row names reset to the provider order of K-05 | V15.13 |
| K-53 | Linear predictor and fitted | RE, CRE | linear_pred = Xβ including the intercept; fitted = lme4 `fitted()` (including α_i) | code |
| K-54 | CRE decomposition | `linear_cre`, `logis_cre` | x_bar = provider mean with `na.rm = TRUE` over every row of the input data; x_within = x − x_bar; then column selection and complete-case filtering (D-13) | V15.10 |

## Provider tests

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

## Standardized measures

| ID | Convention | Where | Value or rule | Evidence |
|---|---|---|---|---|
| K-80 | Logistic FE indirect | `SM_output.logis_fe` | O_i = Σy; E_i = Σ plogis(γ0 + Zβ) (unclamped); Var_i = Σ E(1 − E); ratio O_i/E_i; rate = min(max(ratio × r, 0), 100) with population rate r = 100 Σy / n over included observations | V13.12 |
| K-81 | Logistic FE direct | `SM_output.logis_fe` | E_i = Σ_j over all observations of plogis(γ̂_i + z_j'β) (`computeDirectExp`); ratio E_i / Σy; rate as K-80 | V13.12 |
| K-82 | Logistic RE/CRE | `SM_output.logis_re`, `.logis_cre` | Indirect: Σ fitted (including α_i) / Σ plogis(Xβ), predicted over expected; direct: Σ_j plogis(α̂_i + x_j'β) / Σy; rates as K-80 | V15.4 |
| K-83 | Linear FE | `SM_output.linear_fe` | Indirect difference (O_i − E_i)/n_i with E_i = Σ(γ0 + Zβ); direct difference (Σ_j(γ̂_i + z_j'β) − Σ_j(γ0 + z_j'β))/n. Both equal γ̂_i − γ0 up to rounding | V14.5 |
| K-84 | Linear RE/CRE | `SM_output.linear_re`, `.linear_cre` | Indirect (Σ fitted − ΣXβ)/n_i; direct (Σ_j(α̂_i + x_j'β) − Σy)/n | V15.5 |
| K-85 | Direct expectations threading | `computeDirectExp` | Results identical for 1 and 2 threads | V13.14 |

## Intervals

| ID | Convention | Where | Value or rule | Evidence |
|---|---|---|---|---|
| K-90 | Logistic FE provider-effect intervals | `confint.logis_fe(option = "gamma")` | Test inversion with `uniroot()` at its defaults (tol = `.Machine$double.eps^0.25`, maxiter 1000). Upper limit bracket γ̂ + [5k, 5(k + 1)], lower γ̂ − [5(k + 1), 5k], k = 0, 1, 2, else ±Inf. Exact: the mid-p functions of K-62 set to α_sig/2. Score: (o − Σp)/sqrt(Σp(1 − p)) ± qnorm(α_sig/2, lower.tail = FALSE). No-event providers: (−Inf, U] with bracket (10 + max|Zβ|)·[−k, k], k = 1, 2, 3, solving ½∏(1 − p) = α_sig (exact) or z_α − Σp/sqrt(Σp(1 − p)) = 0 (score). All-event providers: [L, Inf) with ½∏p = α_sig (exact) or Σ(1 − p)/sqrt(Σw) − z_α = 0 with w floored at 1e-20 (score). Wald: γ̂ ± qnorm(1 − α_sig/2)·se | V13.15, code |
| K-91 | Logistic FE measure intervals | `confint.logis_fe(option = "SM")` | Indirect: [Σ plogis(γ_L + Zβ)/E_i, Σ plogis(γ_U + Zβ)/E_i]; no-event lower 0 (upper n_i/E_i when `greater`); all-event upper n_i/E_i (lower 0 when `less`). Direct: the same with sums over all observations and denominator Σy; no-event `greater` upper n/Σy; all-event upper n/Σy. Rates clipped as K-80 | code |
| K-92 | Linear FE intervals | `confint.linear_fe` | γ̂ ± c·se with c = qt(·, n − m − p) for the simplified variance and qnorm(·) for the full variance (D-32); measure intervals shift by the same amount | V14.4 |
| K-93 | RE/CRE intervals | `confint` for RE/CRE | α̂ ± qnorm(·)·se (se as K-69/K-70); logistic measure intervals map limits through plogis sums; linear through sums | V15.14, code |
| K-94 | One-sided intervals | all `confint` | Critical value qnorm(1 − α_sig) (or qt); the open side is ±Inf, or 0 and n_i/E_i for logistic measures | code |

## Covariate summaries

| ID | Convention | Where | Value or rule | Evidence |
|---|---|---|---|---|
| K-100 | Logistic FE Wald | `summary.logis_fe` | p = 2(1 − pnorm(|z|)) returned as `format.pval(p, digits = 7, eps = 1e-10)` strings; interval β ± qnorm(1 − α_sig/2)·se | V13.20 |
| K-101 | Logistic FE LR | `summary.logis_fe(test = "lr")` | −2ℓ with γ clamped to median ± 10 in both models; null model refit by `logis_fe` with default settings; statistic −2ℓ_null − (−2ℓ_full); p = pchisq(·, 1, lower.tail = FALSE); `null` must be 0 (D-10, D-30) | V13.19 |
| K-102 | Logistic FE score | `summary.logis_fe(test = "score")` | Null refit as K-101; p clamped to [1e-10, 1 − 1e-10]; efficient information for the added covariate from the block inverse; statistic U²/I; chi-square(1) p-value | code, V13.19 |
| K-103 | Linear FE | `summary.linear_fe` | t test, df n − p − m; interval β ± qt(1 − α_sig/2, n − p − m)·se; p as strings | V14.6 |
| K-104 | Linear RE/CRE | `summary.linear_re`, `.linear_cre` | t p-values with df n − p_FE − m + 1; intervals from `lme4::confint(method = "Wald")` (normal) | V15.7 |
| K-105 | Logistic RE/CRE | `summary.logis_re`, `.logis_cre` | p = 2(1 − pnorm(z)) without `abs()` (D-31); intervals from `lme4::confint(method = "Wald")` | V15.6 |

## Plots and diagnostics

| ID | Convention | Where | Value or rule | Evidence |
|---|---|---|---|---|
| K-110 | Logistic funnel (score) | `plot.logis_fe` | precision = E_i²/Var_i (K-80); limits target ± qnorm(1 − α/2)·sqrt(1/precision) with the user's `alpha` used directly, lower limit clipped at 0; flags from the modified score test at level 1 − alpha[1] | V13.21, code |
| K-111 | Linear funnel | `plot.linear_fe` | precision = n_i; limits target ± qnorm(1 − α/2)·σ/sqrt(n_i); flags from `test.linear_fe` | V14.8, code |
| K-112 | Caterpillar flags | `caterpillar_plot` | Higher if lower limit > reference, lower if upper limit < reference; reference 0 (differences), 1 (ratios), the population rate (rates) | V16.2, code |
| K-113 | Flag bar plot | `bar_plot` | Provider-size groups from `quantile(size, (0:g)/g)` breaks with `include.lowest = TRUE`, default g = 4, plus "Overall" | V16.2, code |
| K-120 | Data checks | `data_check` | Stop on any missing value; `caret::nearZeroVar(saveMetrics = TRUE)` defaults (freqCut 95/5, uniqueCut 10): zero variance stops, near-zero warns; |r| > 0.9 warns; `olsrr::ols_vif_tol` VIF ≥ 10 warns | V16.1, code |

## Thread counts

| ID | Convention | Where | Value or rule | Evidence |
|---|---|---|---|---|
| K-130 | Reference thread defaults | everywhere | Fits and `test` default to 1; logistic `SM_output` defaults to 2 and is called with that default by `confint.logis_fe`, `plot.logis_fe`, and the RE/CRE intervals; RE/CRE direct intervals hard-code 4 (D-21). The fixture generator passes `threads = 1` explicitly; the rewrite defaults to 1 everywhere (DEC-001) | V15.11 |

## Cox models (pprof_py v0.7.0)

The conventions of pprof_py v0.7.0 (commit `9320766`) that the Cox models reproduce (DEC-086), with the choices decided where `survival` and pprof_py differ. They were verified in CoxPH Phase C0, by running pprof_py and R (the scripts in `dev/design/coxph-facts/`, cited by number) or by reading pprof_py's code (marked "code", with paths under `pprof_py/`). `dev/design/COXPH_DESIGN.md` §A states them in full. A change to any of them is a Class B change against pprof_py.

Notation: η_i = x_i'β̂ + o_i (offset), r_i the risk score, (start_i, stop_i] the interval at risk, δ_i the event, O_j and E_j the observed and expected events of provider j, X ~ Poisson(E).

| ID | Convention | Where | Value or rule | Evidence |
|---|---|---|---|---|
| K-131 | Times, ties, and risk sets | Cox fits, measures | Right-censored times are (0, time] with time > 0; counting-process data need start < stop (negative starts allowed). Event times, ties, and strata are identified by exact equality, with no `timefix` (M-23). At an event time t the risk set is {i : start_i < t ≤ stop_i}: a row entering at t is not at risk, one leaving at t is | 08; code (`data/survival_validation.py`, `algorithms/survival/risk_sets.py:88, 99`) |
| K-132 | Tie methods | Cox fits | Breslow by default; Efron as `survival`'s `agfit4`. Tied deaths are counted among the rows with positive weight; rows with weight 0 are left out of the fit (M-25, D-58) | 12; code (`algorithms/survival/ties.py`) |
| K-133 | Estimation control | Cox fits | β⁽⁰⁾ = 0; convergence when \|1 − ℓ_old/ℓ_new\| ≤ `tol` = 1e-9, within `max_iter` = 20 iterations; `survival`'s step halving (D-57); reaching `max_iter` warns | 12, 14 |
| K-134 | Variance | Cox fits, Fine–Gray | Model-based, the inverse information, unless robust variance is requested; non-integer weights do not switch it on. Robust: V (Σ_c s_c s_cᵀ) V, s_c the cluster sum of weighted score (dfbeta) residuals; without a cluster each row is its own cluster; the tie method is respected (D-56) | 05, 14 |
| K-135 | Linear predictor | Cox fits | η = x'β̂ + o on the scale of the input covariates, uncentered; coefficients for the input covariates | code (`models/survival/coxph.py`) |
| K-136 | The national baseline of the measures | measures, tests | Only β̂ is used: not the fit's strata, ties, or weights (M-29). r_i = exp(η_i − max η), not clipped. Over all rows, unweighted: Λ0(t_k) = Σ_{l≤k} d(t_l)/RS(t_l), d(t) the number of event rows at t, RS(t) = Σ r_i 1(start_i < t ≤ stop_i), computed as the difference of two suffix sums (which loses precision only when risk scores span about e^20 or more); Λ0 right-continuous, 0 before the first event time | 07; code (`measures/survival/coxph.py:47-104`) |
| K-137 | Indirect measure | measures | O_j = Σ_{i∈j} δ_i; E_j = Σ_{i∈j} r_i [Λ0(stop_i) − Λ0(start_i)]; ratio O_j/E_j (NaN for 0/0, ∞ when only E_j = 0); Σ_j E_j = O; null variance E_j (Poisson). A numeric `null` c scales every E_j by exp(c) (M-40) | 07, 13 (`r_smr.json` to 1e-14) |
| K-138 | Direct measure | measures | E^(j) = Σ over provider j's event rows i of RS(t_i)/RS_j(t_i), RS_j the risk-set sum over provider j's rows (one term per event row); ratio E^(j)/O, O the total number of events; 0 for a provider without events | 13; code (`measures/survival/coxph.py:88-102`) |
| K-139 | Person-time | measures | Σ_{i∈j} (stop_i − start_i); the population size of direct standardization is the number of rows | code |
| K-140 | Exact Poisson test and limits | tests, intervals | α = 1 − level. p_ex = min(0.999, 2P(X ≥ O)) if O/E > 1, else min(0.999, 2P(X ≤ O)) (so O = E always reaches the cap); z = sign(O − E) Φ̄⁻¹(p_ex/2); reported p = 2Φ̄(\|z\|), which is 1 when O = E. Limits on the ratio, by E: E < 100, Garwood, `qchisq(α/2, 2O)/(2E)` (0 if O = 0) and `qchisq(1 − α/2, 2(O+1))/(2E)`; E ≥ 100, Byar, (O/E)(1 − 1/(9O) − z/(3√O))³ (0 if O = 0) and ((O+1)/E)(1 − 1/(9(O+1)) + z/(3√(O+1)))³ with z = Φ⁻¹(1 − α/2). Byar's limits can disagree with the flag at the boundary and its lower limit can be negative at high levels (reproduced) | code (`inference/survival/inference.py:61-180`), C0 specification review |
| K-141 | Mid-p test and limits | tests, intervals | p_min = 2F(O;E) − f(O;E); p_max = 2(1 − F(O−1;E)) − f(O;E), with `1 - ppois()` as written; p* = max(1e-6, min(p_min, p_max)/2); z = Φ⁻¹(p*) if p_min ≤ p_max, else −Φ⁻¹(p*) (\|z\| ≤ 4.7534); reported p = 2Φ̄(\|z\|) under the theoretical null. Limits: the roots in the Poisson mean t of 2Φ̄(\|z(t)\|) − α, bracketed from 1e-10 max(E, 1) to 10(O + E + 10) (multiplied by 10 while z > −4.75 and below 1e12), split at the root of z(t), with Brent tolerances 1e-12 max(E, 1) (split) and 1e-10 max(E, 1) (limits); lower 0 and upper ∞ where the equation has no sign change; ratio limits L/E and U/E | code (`inference/survival/empirical_null.py:188-207`, `provider_tests.py:29-54`), C0 specification review |
| K-142 | Flags | tests, funnel | +1 when p < α and z > 0, −1 when p < α and z < 0, else 0; strict inequality; the theoretical null (mean 0, sd 1); level 0.95 by default; tests two-sided only | code (`inference/decision.py:66-101`) |
| K-143 | Penalized objective, scaling, and grid | penalized paths | −ℓ/Σw + λ Σ pf_j [α\|β_j\| + ½(1−α)β_j²]; columns with weighted population variance below 10ε are left out with a warning (coefficient 0); with `standardize`, the others are divided by their weighted population SD, not centered; penalty factors rescaled over the remaining columns to sum to their number. λ_max = max_{pf_j > 0} \|U_j/Σw\|/pf_j at the null point (unpenalized columns fitted), divided by max(α, 1e-3); grid exp(linspace(log λ_max, log(r λ_max), n_lambda)), r = 1e-2 if n < p (remaining columns) else 1e-4; n_lambda = 100 | 09; code (`models/survival/penalized_coxph.py:92-356`, `algorithms/survival/coordinate_descent.py:361-429`) |
| K-144 | Penalized cross-validation | `select_lambda()` | Folds: event rows, then censored rows, each in row order, get a random permutation of the labels 1..K repeated to their number (K = 10 by default; given folds may have K ≥ 2); each fold's path on its training rows over the full-data grid; D_kj = [2(lsat_all − ℓ_all(β_kj)) − 2(lsat_T − ℓ_T(β_kj))]/W_k with W_k the held-out event weight and lsat = −Σ_strata Σ_t w_t log w_t, in this Breslow form for both tie methods (glmnet 4.1-8's `coxnet.deviance2`; glmnet 5.x's `coxnet.deviance()` agrees only for Breslow ties, its Efron saturated term differing by a constant, Phase C1), and ℓ the tie method's partial likelihood; cvm = Σ_k W_k D_kj / Σ_k W_k; cvsd = √(Σ_k W_k (D_kj − cvm)² / Σ_k W_k / (K − 1)); λ with a non-finite fold deviance dropped; λ_min the first (largest) λ at the minimum; λ_1se the first λ with cvm ≤ cvm(λ_min) + cvsd(λ_min); the default rule λ_1se (M-30) | 03, 04; code (`models/survival/penalized_coxph.py:795-926`) |
| K-145 | Fine–Gray | `fit_fine_gray()` | `survival::finegray()`'s expansion and weights (censoring and entry distributions per stratum, on the integer time scale with events shifted by −0.2; competing-event rows extended with weight curve(t)/curve(s)); case weights multiply the weights only; the Cox fit weighted, stratified by provider (M-41), robust with clusters by subject; Breslow ties by default; cumulative incidence 1 − exp(−H(t)) | 05 |
| K-146 | Cause-specific models | `fit_cox_stratified()` | The event of interest, other causes censored (M-35) | code (`models/survival/competing_risks.py:119-131`) |
| K-147 | Providers with no expected events | measures, tests | E_j = 0: ratio NaN (O_j = 0) or ∞; mid-p lower limit NaN and upper ∞; exact limits 0 and ∞; one `pprof_warning_zero_expected` warning (D-70) | code, C0 specification review |
| K-148 | Covariate Wald test | Cox fits: `test_coefficients()`, `confint()` | z = β̂/se, se from the model-based or robust variance (K-134); p = 2Φ̄(\|z\|) computed as an upper tail, `2 * pnorm(abs(z), lower.tail = FALSE)`, so that p-values below 1e-16 are not 0 (DEC-101; the rule `p_value = "two_sided_upper"`); interval β̂ ∓ Φ⁻¹(1 − α/2)·se, α = 1 − level, level 0.95 by default | code (`inference/survival/inference.py:39-45`); C1 fixture `lt-stratified` (z = 9.15, p = 5.5e-20) |
| K-149 | Funnel limits | `funnel_limits()`, `plot_funnel()` | Points O_j/E_j with precision E_j. At each E > 0 and level, o_lo the largest count in 0, …, n that the funnel's test (mid-p) flags low and o_hi the smallest it flags high, n = ⌈E + 40√E + 50⌉, found by bisection (the flags are monotone in the count); limits (o_lo + ½)/E and (o_hi − ½)/E, −∞ and ∞ where no count is flagged; flags from the test at the first level, so a provider lies outside its limits exactly when it is flagged; target 1; no limits for E = 0. pprof_py's search for a provider also covers its O_j, which matters only where no count up to n is flagged (a level of 0.999998 or more for the mid-p test); its curves are on a 200-point geometric grid of E, the package's table at the providers' distinct E (DEC-107) | 23; code (`inference/survival/provider_tests.py:142-172`, `inference/funnel.py`) |

In the package (Phase C2): K-131 in `R/data-survival.R` (`data_survival_response()` and `data_check_survival_values()`) and the adapter's `timefix = FALSE`; K-132 to K-134 in the survival adapter, `R/model-survival.R` (`survival_fit_rows()`, `survival_run_fitter()`, `survival_robust_vcov()`, `survival_cluster_codes()`), with K-133's warning in `fit_cox_stratified()` (`R/model-cox-stratified.R`); K-135 in `predict.pprof_cox_stratified()`; K-148 in `R/inference-coefficients.R` with the family's rule in `profile_spec.pprof_cox_stratified()`. The iterations reported are those run, at most `max_iter`, as pprof_py counts them; survival's `coxph()` reports `iter.max + 1` for a right-censored fit that does not converge.

In the package (Phase C3): K-136 and K-137 in `cox_expected_events()` (`R/model-cox-measures.R`), which `fit_cox_stratified()` calls once and keeps as `expected_events`, with `expected_outcome.pprof_cox_stratified()` and `null_effect.pprof_cox_stratified()` scaling them by exp(c) (M-40); K-138 in `cox_direct_expected()`, the family's `direct_by_provider`, with RS_j from suffix sums within each provider rather than pprof_py's composite sums, which agree with them within `closed_form` on the fixtures (the C3 plan, §2.7); K-139 in the data layer's provider table (Phase C2); K-140 to K-142 in `R/inference-poisson.R` (`infer_poisson_exact_statistic()`, `infer_poisson_midp_statistic()`, `infer_poisson_p_value()`, `infer_poisson_flag()`, `infer_poisson_exact_limits()`, `infer_poisson_midp_limits()`), which the profiling layer calls when the family's `count_distribution` is `"poisson"` (DEC-108), with their constants in `R/constants.R`; K-147's warning in `profile_warn_zero_expected()` (`R/profile-spec.R`), once per call and once in all from `profile_providers()`; K-149 in `infer_poisson_funnel_limits()` and `profile_poisson_funnel_limits()` (`R/profile-funnel.R`). K-141's limits on the Poisson-mean scale depend on O alone, so the package finds the two roots of each distinct observed count once, to rounding, by bisection over all the distinct counts at once, keeps pprof_py's decisions of 0 and ∞ at its bracket ends for each provider, and divides by E_j: within 0.25 of pprof_py's xtol of its limits (DEC-110).
