# CoxPH Phase C4 plan: the elastic-net Cox model

> **Status: approved by the project lead on 2026-10-14, with the eight decisions of §6 as recommended** (DEC-113 to DEC-120). It implements the brief's §4 row C4 (`dev/coxph_brief.md`; also §2.1 item 3, §2.4, §3.2's penalized Cox, §3.3 rows 10, 11, and 13, §3.5, §3.6, §3.7, §5.4, §6, §7, and §10's Q8, Q12, and Q15) and COXPH_DESIGN §A.5, §B.1, §B.2, §D.4, §E.2, §G, and §I, under DEC-086 to DEC-112.

C4 adds `fit_cox_penalized()`, pprof_py's elastic-net Cox path fitted by `glmnet` on pprof_py's λ grid, and `select_lambda()`, pprof_py's cross-validation computed in the package from `glmnet`'s fold paths. The model declares no inference (M-34). `glmnet` stays in Suggests (DEC-088). The existing families and the stratified Cox model stay bitwise identical.

The evidence (§2; `dev/design/coxph-facts/26` to `28`) confirms the C0 design and makes it precise in four places:

- `glmnet` refuses a design of one column.
- On data with few events per covariate, `glmnet` 5.1 stops before the end of the grid with Breslow ties, and with Efron ties it diverges without a warning, where pprof_py converges.
- The cross-validation's partial likelihoods cost more than the fold paths unless `glmnet` evaluates every grid point at once.
- pprof_py reports a few path outputs that the design leaves out.

§6 lists the eight decisions the plan asks for, these four among them.

## 1. Deliverables

| # | Deliverable | Where |
|---|---|---|
| 1 | The `glmnet` adapter: the availability check, the inputs, degenerate columns, the call, the handling of an early stop or a failed solution, the score at the null point, and the deviances of the cross-validation | `R/model-glmnet.R` (new) |
| 2 | `fit_cox_penalized()`: pprof_py's λ grid (K-143), the path, the `pprof_cox_penalized` object, its validator, its methods, and its capabilities (none, M-34) | `R/model-cox-penalized.R` (new) |
| 3 | `select_lambda()`, a generic, with its method: the folds (D-61), the fold paths, pprof_py's fold deviances and summaries (K-144), and the λ_min and λ_1se rules | `R/model-cox-selection.R` (new) |
| 4 | Shared additions, each new code beside unchanged code: the partial log-likelihood of given linear predictors from survival's fitter; the penalized constants; the warning for degenerate covariates; the print, tidy, and glance methods | `R/model-survival.R`, `R/constants.R`, `R/conditions.R`, `R/present-print.R`, `R/present-tidy.R` |
| 5 | Tests (§4) | `tests/testthat/`: `test-model-glmnet.R`, `test-model-cox-penalized.R`, `test-model-cox-selection.R`, `test-cox-penalized-reference.R` (new); `helper-cox-fixtures.R` (extended) |
| 6 | Two penalized cases in the fixture generator, and the full set regenerated (decision 5) | `dev/reference/cox/cases.py`, `generate.py`, `survival.R`; `validation/fixtures/cox/`; `dev/reference/diff-reports/` |
| 7 | Calibration rows for the λ grid and the new cases (decision 4) | `dev/reference/cox/calibrate.R`, `validation/cox-calibration-report.md` |
| 8 | Benchmarks: each fit against its `glmnet` calls and the preparation of their inputs (DEC-105), beside C1's `glmnet` and pprof_py times (decision 6) | `dev/bench/cox/run_paired.R`, `summarize_paired.R`, `.github/workflows/cox-bench.yaml`, `dev/bench/results/` |
| 9 | Registers, help pages, `NEWS.md`, `_pkgdown.yml`, NAMING §2 and §10, COXPH_DESIGN as built, ARCHITECTURE §E.3 and §E.6, the status document | `dev/`, `man/` (generated), `NEWS.md`, `_pkgdown.yml` |

**Not in C4** (the brief's §4): competing risks (C5); provider profiling at a selected λ (M-34, the brief's Q12); the penalized provider models of the later briefs (§2.2); the vignette (C6); pprof_py's bootstrap standard error of the cross-validated deviance (D-67).

## 2. Evidence gathered for this plan

The evidence was gathered on 2026-10-14 on the C1 machine, with R 4.4.0, survival 3.8-12, and glmnet 5.1, and with the fixture generator's Python environment, which holds pprof_py at `9320766`. The machine was paging (0.7 GB of 7.4 GB free), so the times are indicative. The scripts and their outputs are in `dev/design/coxph-facts/`:

- 26 writes pprof_py's λ grid in plain R from engine calls and compares it and `glmnet`'s paths with pprof_py. It covers the six penalized fixture cases and eight settings the fixtures lack, which `26_penalized_grid.py` runs through pprof_py.
- 27 computes pprof_py's cross-validation from `glmnet`'s fold paths on the two fixture cases that hold it.
- 28 times the parts of a path and of a cross-validation on the benchmark's penalized scenario.

1. **The grid comes from engine calls.** The grid needs the score at the null point. It comes from `glmnet`'s exported `coxgrad()`, the gradient in the linear predictor, times the scaled design (26, parts A and B).
   - The score agrees with survival's score residuals within 3.7e-14.
   - λ_max is within 9e-15 of pprof_py's on all 16 paths of the fixtures and all 16 runs of the settings. The grids are within 1.1e-14 and the column scales within 5.6e-16.
   - With an unpenalized column (`penalized-combined`), survival's fitter reproduces pprof_py's λ_max within 9.6e-16 when it runs at pprof_py's eps 1e-9 and 100 iterations. At eps 1e-12 it moves by 1.5e-11, pprof_py's own convergence error.
2. **glmnet's paths on that grid agree with pprof_py's** (26, parts A and B).
   - On the fixtures they are within 0.213 units of `penalized_path`, as C1 found on pprof_py's own grid (0.21). On the settings they are within 0.067, apart from the few-events setting (item 6).
   - They are within 3.6e-15 of `glmnet`'s paths on pprof_py's grid.
   - Sorting the rows by provider, as `data_prepare()` does, moves them by at most 2.8e-16.
3. **Degenerate columns must be left out before the call** (26, part B).
   - Given a constant column with its penalty factor, `glmnet` keeps it at 0. But it rescales the penalty factors over all columns, so the path lies 1e4 units from pprof_py's.
   - With the column left out, the path is within 0.067 units. pprof_py warns (`DegenerateFeatureWarning`) and rescales over the remaining columns.
4. **glmnet refuses one column** ("x should be a matrix with 2 or more columns"). Given a column of zeros beside the covariate, with the same penalty factor, it reproduces pprof_py's one-covariate path within 0.008 units (26, part B). `glmnet` leaves the constant column out of the fit, and the equal factor leaves the rescaling unchanged.
5. **D-72 at λ_max** (26, part A).
   - With an unpenalized column, `glmnet`'s first grid point has exact zeros, where pprof_py has penalized coefficients of order 1e-12 (3.3e-12 and 4.8e-12 with Breslow ties).
   - Where λ_max is the exact boundary, `glmnet` can leave one penalized coefficient of rounding size there: up to 6e-16, on 6 of the 16 paths. pprof_py does the same once (−5.2e-17 on `penalized-offset`).
6. **Few events per covariate** (26, part C). The data are the first 15 rows of `penalized_wide.csv`: 8 events and 20 covariates. pprof_py converges at all 100 grid points, and its largest coefficient is 3.2 to 3.3 in absolute value.
   - With Breslow ties, `glmnet` stops at the 73rd point with a warning: its iteration limit (`maxit` = 1e5) counts passes over all points together. Up to the 72nd its largest coefficient is pprof_py's to three digits (2.01). With 1e6 passes it reaches every point and pprof_py's largest coefficient (3.22).
   - With Efron ties, `glmnet` 5.1 follows pprof_py to the 54th point (largest coefficient 1.12 on both sides). At the 55th it diverges without a warning: coefficients near 9.9e35 and a deviance ratio of −1.7e35, a deviance far above the null deviance, which no solution of the penalized problem has. It does so with 1e6 passes and on its own grid too.
   - On 19 and 25 rows, `glmnet`'s own grid also stops early with both tie methods. From 40 rows it does not.
   - Where both sides have solutions, the paths agree within `penalized_path` to the 30th point (Efron) and the 34th (Breslow). Beyond, on these ill-conditioned data, they part by up to 1.3e-3.
7. **The cross-validation** (27; `penalized-wide` with its 8 vendored folds and `penalized-combined` with 10; pprof_py's grid; both tie methods).
   - survival's fitter with no covariates and the linear predictor as offset, called as `coxph()` calls it, reproduces the generator's R side bitwise: fold deviances, cvm, and cvsd.
   - Against pprof_py, cvm is within 0.128 units of `penalized_path`, cvsd within 0.018, and λ_min and λ_1se are equal, as C1 calibrated.
   - `glmnet`'s `coxnet.deviance()` accepts every grid point's linear predictor at once and returns one deviance per column, equal bitwise to one call per column. With Breslow ties its saturated term is pprof_py's, within 1e-11. With Efron ties it differs by a constant of the rows: 830.15 on `penalized-combined`, the same for 100 linear predictors within 1e-11.
   - So one `coxnet.deviance()` call per fold and set of rows, moved to pprof_py's saturated term by one survival evaluation per set of rows, is within 3.2e-13 of the fitter's fold deviances, and gives the same λ_min and λ_1se.
   - Sorting the rows by provider moves the fold deviances by 1.3e-14.
8. **Cost** (28: `covariates-50`, 100,000 rows, 1,000 providers, 50 covariates; Breslow ties).

   | Part | Time |
   |---|---|
   | The grid | 0.3 s |
   | `glmnet`'s path, 100 grid points | 16 s |
   | One fold's path | 14 s |
   | One partial-likelihood evaluation, survival's fitter or `coxnet.deviance()` | 0.08 to 0.12 s |
   | One partial-likelihood evaluation, `coxph()` | 0.4 to 0.5 s |
   | `coxnet.deviance()` of all 100 grid points at once | 3.0 to 3.7 s |

   A 10-fold `select_lambda()` is estimated at 211 s with one `coxnet.deviance()` call per fold and set of rows. With one fitter evaluation per fold and grid point it is 333 s, the evaluations taking 57% of the time. pprof_py's cross-validation took 1,717 s in C1.

## 3. Approach

### 3.1 The glmnet adapter (`R/model-glmnet.R`; COXPH_DESIGN §E.2; DEC-088)

**Availability.** `glmnet_require()` raises `pprof_error_invalid_input` naming `glmnet` (≥ 5.0) when it is missing or older (DEC-088). `fit_cox_penalized()` and `select_lambda()` call it first.

**Inputs.** The rows with positive weight, in `data_prepare()`'s order (M-25):
- the design's columns that are not degenerate;
- `y = glmnet::stratifySurv(Surv(stop, status), codes)`, or `Surv(start, stop, status)` for counting-process data, with the provider codes as strata;
- the weights and the offset, or `NULL`.

**Degenerate columns** (K-143). A column whose weighted population variance is below 10ε, with the weights normalized to sum to 1, is left out before the call, as pprof_py leaves it out (§2.3):
- one `pprof_warning_degenerate_covariates` names such columns, and they get coefficient 0 at every λ;
- if every column is degenerate, the fit raises `pprof_error_data`.

**The call.** `glmnet::glmnet()` with family `"cox"`, the weights and offset, `alpha`, `lambda = grid`, `penalty.factor`, `standardize`, `cox.ties = ties`, and `control = list(thresh = tol, maxit = max_iter, fdev = 0, devmax = 1)`.
- `penalty.factor` holds pprof_py's factors, rescaled over the kept columns.
- With one kept column, a column of zeros goes beside it with the same factor, and its coefficient is dropped from the result (§2.4).

**After the call** (decision 3). The path ends:
- at the last grid point `glmnet` returned, when it stops early, and its warning is caught;
- before the first point whose coefficients are not finite, or whose deviance ratio is below −√ε, a deviance above the null deviance, which no solution of the penalized problem has.

The fit then warns once with `pprof_warning_not_converged`, naming the first grid point not reached and suggesting a larger `max_iter`. Other `glmnet` errors become `pprof_error_convergence` with `engine_message`, as survival's do.

**The engine's other calls.**
- The score at the null point: `glmnet::coxgrad(eta, y, w, std.weights = TRUE, cox.ties = ties)`, times the scaled design (§2.1).
- The deviances of the cross-validation: `glmnet::coxnet.deviance(pred = <one column per grid point>, y, weights, std.weights = FALSE, cox.ties = ties)` (§2.7).

### 3.2 pprof_py's λ grid (K-143; COXPH_DESIGN §A.5)

- **Scales.** With w̃ = w/Σw over the fitted rows, the weighted population variance v_j of each column; degenerate below 10ε; the divisor √v_j with `standardize`, and 1 otherwise or for a degenerate column. The object keeps them as `column_scale`.
- **Penalty factors.**
  - The user's are finite, at least 0, and named by coefficient; coefficients not named get 1.
  - They must not be all 0 among the kept columns.
  - They are rescaled over the kept columns to sum to their number.
- **The null point.**
  - The penalized coefficients are 0.
  - The unpenalized ones (factor 0) come from survival's fitter, through the survival adapter as `coxph()` calls it (DEC-100). It runs on the kept unpenalized columns divided by their scales, with the fit's ties, at pprof_py's eps 1e-9 and 100 iterations (§2.1; named constants).
  - If that fit finds aliased unpenalized columns, `fit_cox_penalized()` raises `pprof_error_data` naming them (M-26). If it does not converge, it warns.
- **λ_max** = max over j with pf_j > 0 of |c U_j| / pf_j, divided by max(α, 1e-3), with c U the score of §3.1 at the null point.
- **The grid.**
  - It is exp(seq(log λ_max, log(λ_max · r), length.out = n_lambda)), with r = `lambda_min_ratio`, or else 1e-2 if n < p and 1e-4 otherwise.
  - p counts the kept columns. n counts every observation, those with weight 0 too, as pprof_py's `n_obs` does.
  - `n_lambda = 1` gives λ_max alone.
  - A given `lambda` must hold distinct, finite, positive values, as pprof_py requires, and is sorted in decreasing order.
- **No events** among the rows with positive weight raise `pprof_error_data` before any engine call.

### 3.3 `fit_cox_penalized()` and the `pprof_cox_penalized` object (COXPH_DESIGN §B.1, §B.2, §D.4)

**The signature** is the design's: `fit_cox_penalized(formula, data, provider, weights = NULL, alpha = 1, lambda = NULL, n_lambda = 100, lambda_min_ratio = NULL, penalty_factor = NULL, standardize = TRUE, ties = "breslow", max_iter = 100000, tol = 1e-12, keep_data = FALSE, verbose = FALSE)`.

The data come from `data_prepare(response_type = "survival", weights, allow_offset = TRUE, event_counts = TRUE)`, as for the stratified model, with no change to the data layer.

**The object.**
- **Shared fields:**
  - `coefficients`, at the selected λ, or before selection at the last grid point reached; degenerate covariates 0;
  - `vcov`, a matrix of NA;
  - `provider_effects = NULL`;
  - `response`, the status;
  - `linear_predictor`, x'β at that λ;
  - the provider table, with `n_events` and `person_time`;
  - `convergence`: `iterations` (`glmnet`'s passes over the data), `converged` (every grid point reached), `grid_points` (the points reached), `stop_rule = "relative_objective"` (`glmnet`'s: the largest change in the objective below `tol` times the null deviance), `tol`, and `max_iter`.
- **Own fields:**
  - `start`, `stop`, `weights`, and `offset`, as the stratified model keeps them;
  - `lambda`, the grid reached, and `lambda_max` and `lambda_min_ratio`;
  - `coefficient_path`, one row per coefficient and one column per λ, on the covariates' scale;
  - `alpha`, `penalty_factor` (the user's, by coefficient), `standardize`, `ties`, `column_scale`, and `degenerate` (the names left out);
  - `n_events` and `n_zero_weight`;
  - `selected` and `cross_validation`, `NULL` until `select_lambda()`;
  - with `keep_data = TRUE`, `engine_fit`, `glmnet`'s object.

**Capabilities.** None (M-34). The profiling functions, `test_coefficients()`, `summary()`, and `confint()` raise `pprof_error_unsupported_inference`, and so does `augment()`.

**Methods** (decisions 7 and 8):
- `coef(object, lambda = NULL)`: the path, or the coefficients at a λ of the grid; a λ off the grid raises `pprof_error_invalid_input`, as the design has it.
- `predict(object, newdata = NULL, type = c("linear_predictor", "risk"), lambda = NULL)`: at the selected λ, or at a λ of the grid for `newdata`.
- `nobs()`: the number of events, as for the stratified model (the brief's §5.2).
- `print()`, `tidy()` (`term` and `estimate` at the selected λ), and `glance()`.

### 3.4 `select_lambda()` (K-144; COXPH_DESIGN §A.5, §E.2; M-30, D-61)

**The call.** `select_lambda(model, folds = NULL, n_folds = 10, rule = "1se", data = NULL)` is a generic. Its default raises `pprof_error_invalid_input`. The method takes the covariates from `keep_data = TRUE` or from `data`, which `model_prepared_data()` checks is the fit's data (DEC-005).

**Folds.**
- **Given.** One per row of the data the model was fit to, ignoring rows dropped for missing values. The labels are 1..K or 0..K−1, with K ≥ 2, as pprof_py accepts.
- **Drawn** (D-61). Event-stratified, with R's random numbers. The observations with events, then those without, each in the input order, get a random permutation of the labels 1..K repeated to their number, by `sample.int()`. `n_folds` must be at least 3. Package code never sets a seed.
- A fold whose held-out events have no positive weight raises `pprof_error_data`.

**Each fold k.**
- **The path.** The adapter on the training observations with positive weight. The fold has its own scales, degenerate columns (their warnings muffled, as pprof_py does), and penalty-factor rescaling. The grid is the model's (the full-data grid), with the model's α, ties, `standardize`, `tol`, and `max_iter`.
- **Linear predictors.** η = X B_k + offset for every observation with positive weight; the training rows' are a subset of them.
- **Deviances** (decision 2). D_kj = [dev_all(j) − dev_T(j)] / W_k.
  - dev comes from one `coxnet.deviance()` call per set of rows over all the fold's grid points.
  - It is moved to pprof_py's saturated term by dev − [dev(offset) − 2(lsat − ℓ(offset))].
  - lsat is pprof_py's Breslow form, −Σ w_t log w_t over each provider's distinct event times, summed in the package.
  - ℓ(offset) is the offsets' partial log-likelihood, from survival's fitter with no covariates, as `coxph()` calls it.
- **Early stops.** A fold path that ended early leaves the later points' deviances missing.

**Summaries and selection** (K-144).
- cvm and cvsd as pprof_py computes them. A λ with a fold deviance that is not finite gets no cvm or cvsd, and `n_folds_used` counts the finite folds.
- λ_min is the first λ at the smallest cvm, and λ_1se the first with cvm ≤ cvm(λ_min) + cvsd(λ_min).
- `rule` is `"1se"` (the default, M-30) or `"min"`.
- The model returns with:
  - `selected`: the λ, its grid index, and the rule;
  - `cross_validation`: the grid, cvm, cvsd, the fold deviances, the held-out event weights, the folds, `n_folds_used`, λ_min, λ_1se, and the rule;
  - `coefficients` and `linear_predictor` at the selected λ.
- One `pprof_warning_not_converged` names the folds whose paths ended early.

### 3.5 Shared additions

Each addition is new code; no existing caller reaches it.

- **`R/model-survival.R`:** `survival_partial_loglik()`. It gives the partial log-likelihood of given linear predictors on given rows from survival's fitter with no covariates, called as `coxph()` calls it.
- **`R/constants.R`:** the penalized constants, each with its K number and pprof_py's location:
  - the degenerate threshold, 10ε;
  - the floor of α in λ_max, 1e-3;
  - the default ratios, 1e-2 and 1e-4;
  - the null fit's eps 1e-9 and 100 iterations;
  - the deviance-ratio floor, −√ε.
- **`R/conditions.R`:** `warn_degenerate_covariates()`, whose condition carries `covariates`.
- **`R/present-print.R`, `R/present-tidy.R`:** the penalized model's methods.
- **Generated and index files:** `NAMESPACE` and the help, generated; `_pkgdown.yml`'s reference index.

Nothing changes in the data, inference, or profiling layers.

## 4. How equivalence is checked

### 4.1 The existing families and the stratified Cox model stay bitwise identical

1. `devtools::test()` and `validation/run-reference.R` run in the verification worktree. They run at `main` (`38dad40`) before any change, and again after each commit marked (S) in §5. Each run must have no failure, the previous run's tests and expectations plus the new ones, and an equivalence report equal to the committed one but for its date and commit (368 of 368 cases).
2. The `data_prepare()` snapshot test runs unchanged: C4 does not touch the data layer.
3. The stratified model's tests pass unchanged: `test-model-survival.R`, `test-model-cox-stratified.R`, `test-model-cox-measures.R`, `test-profile-cox.R`, `test-cox-reference.R`, `test-inference-poisson.R`, and `test-cox-fixtures.R`. No existing expectation is edited.

### 4.2 Against pprof_py: the penalized fixtures (`test-cox-penalized-reference.R`)

The core set (`penalized-strata`) always runs. The full set runs when present (`skip_on_cran()`): `penalized-wide`, `-offset`, `-weights`, `-truncation`, and `-combined`, and decision 5's two cases. Every case runs with both tie methods and every α. Unstratified cases are fitted with one provider.

| Quantity | How | Tier |
|---|---|---|
| The grid, λ_max, the column scales | the package's defaults against pprof_py's | `closed_form` (decision 4) |
| Paths | on the package's own grid, and on pprof_py's grid given as `lambda` | `penalized_path` (DEC-097) |
| Degenerate covariates (their warning and names), the penalty factors as given | the new settings case | `exact` |
| Active sets | per λ, except coefficients within `penalized_path` of 0 on either side (D-72) | `exact` |
| cvm, cvsd | `select_lambda()` with pprof_py's folds (D-61) | `penalized_path` |
| λ_min, λ_1se, `n_folds_used` | the same | `exact` |
| The selected coefficients | against pprof_py's `coef_` at λ_1se | `penalized_path` |
| Few events per covariate (D-78) | the package warns, and its path ends where §3.1 says: at the 72nd point with Breslow ties, before the 55th with Efron ties. The points up to the 30th are compared with pprof_py's, where §2.6 found the paths within the tier | `exact` for the warning and the end point; `penalized_path` |

### 4.3 Engine identity (the brief's §6 B; DEC-043's pattern)

- **The path** equals `glmnet::glmnet()` called directly with the adapter's inputs (`cox_engine`, bitwise). The cases cover strata, offsets, weights, (start, stop] data, both tie methods, α of 1, 0.5, and 0, penalty factors, `standardize = FALSE`, a dropped degenerate column, and the one-column device.
- **The fold paths** of `select_lambda()` equal direct `glmnet()` calls on the training rows (`cox_engine`).
- **`survival_partial_loglik()`** equals `coxph(Surv(...) ~ offset(eta) + strata(provider), weights, ties, timefix = FALSE)$loglik` (`cox_engine`).
- **The fold deviances, cvm, and cvsd** are checked against the generator's R side, which used survival's partial likelihood per evaluation on the same `glmnet` fold paths (`closed_form`; §2.7: within 3.2e-13).

### 4.4 Unit, metamorphic, and edge-case tests (the brief's §6 C, E, F)

- **The grid.**
  - λ_max is checked against a transcription in the test that takes the score from survival's score residuals, not from `coxgrad()`.
  - Also tested: the switch of r at n < p, the given grid sorted, `n_lambda = 1`, the α floor at α = 0, and the null fit of an unpenalized column.
- **Penalty factors:** named and partial; rescaled; errors for negative, non-finite, all-zero, and unknown names.
- **Degenerate columns:** the warning; zeros at every λ; every column degenerate; `standardize = FALSE`.
- **Rows with weight 0** (M-25, D-58): they are left out of every engine call, and the fit equals the fit of the other rows.
- **The folds.**
  - Given folds: 1..K, 0..K−1, and K = 2.
  - Drawn folds: each fold's number of events is ⌊m/K⌋ or ⌈m/K⌉, and `set.seed()` in the test reproduces them (D-61).
  - Errors: a fold without event weight, labels that are not contiguous, the wrong length, and `n_folds` < 3.
- **The cross-validation** against a plain-R transcription of K-144 in the test, which uses `coxph()` per evaluation, independently of the adapter (`closed_form`). Also tested: λ with a deviance that is not finite dropped, and both rules.
- **Metamorphic:**
  - row order and provider relabeling (`closed_form`, with given folds);
  - covariate order (`penalized_path`: `glmnet`'s coordinate order changes);
  - time rescaled by a power of 2 (identical);
  - a constant added to the offset (`closed_form`);
  - duplicated rows against weight 2 with Breslow ties (`closed_form`).
- **Edge cases:**
  - no events;
  - one covariate;
  - an unpenalized covariate aliased with another;
  - `glmnet` missing, raising the classed error (through a mocked availability check);
  - `glmnet` stopping early, and the Efron divergence (D-78);
  - every unsupported inference raising `pprof_error_unsupported_inference`.

**One regression test per register entry:**

| Entry | Regression test |
|---|---|
| D-58, M-25 | rows with weight 0 left out of the path and of the fold deviances |
| D-61 | cross-validation with pprof_py's fold IDs against its cvm and cvsd; the balance of drawn folds |
| D-67 | `select_lambda()` offers no bootstrap standard error |
| D-72 | exact zeros at λ_max on `penalized-combined`; active sets compared within `penalized_path` of 0 |
| D-78 (decision 3) | the early stop and the Efron divergence end the path, with one warning |
| D-79 (decision 7) | a λ off the grid raises; the object has no per-λ log-likelihood |
| K-143, K-144 | the grid, scales, and factors; the fold deviances and summaries, against the fixtures and the transcriptions |

### 4.5 Calibration (DEC-097)

`calibrate.R` gains rows, and C1's rows stay unchanged.
- **The grid.** pprof_py's λ_max and grid against the plain-R construction of fact 26, written again in `calibrate.R`, under `closed_form`. The negative control is the other tie method's grid, from the fixture's other record.
- **The new cases' paths.** pprof_py against `glmnet` under `penalized_path`, with the other tie method's path at the same grid as the negative control, as C1's path rows have.
- **Predictions from fact 26.** The grid lies within 1.1e-14 relative, 1e-4 of the tier. The controls' λ_max differ by 5.5% to 9.7%, at least 5e8 units. The new cases' paths lie within 0.07 units, except the few-events case beyond the 30th point, whose rows the report explains by D-78.

### 4.6 Benchmarks (the brief's §3.7; DEC-038, DEC-105; decision 6)

`run_paired.R` gains two tasks. They run in fresh processes that alternate the sides on the same data, with the package installed with `--preclean`.

- **`penalized_path`.**
  - The fit side is `fit_cox_penalized()`.
  - The engine side is the `glmnet` call, plus the preparation of its inputs: the data layer's preparation, the stratified response, the scales, and pprof_py's grid (`coxgrad()`, and the unpenalized fit when there is one).
  - The estimates must be equal bitwise.
- **`penalized_cv`.**
  - The fit side is `select_lambda()` with given folds, on a fit made outside the timing.
  - The engine side is each fold's `glmnet` call and two `coxnet.deviance()` calls, the survival evaluations of the saturated-term shift, and the preparation of their inputs (the training rows and the linear predictors), with the summaries in plain R.
  - The fold deviances must be equal bitwise.
- **The rule** is DEC-105's: too slow when, in every round, the median and fastest run are more than 10% above the engine side and the median at least 0.05 s above it.
- **Scenarios.** `covariates-50`, the design's §I scenario and C1's penalized one, for both tasks; `rows-1e4` for the path, where fixed costs show.
- **Reported, not a gate:** C1's `glmnet` path and 10-fold cross-validation (14.3 s and 204 s, on `glmnet`'s own grid) and pprof_py's (89.9 s and 1,717 s), with peak memory and the object's size.
- **Where.** On this machine first. Then `cox-bench.yaml`, which needs `any::glmnet` among its packages, measures on a GitHub runner when the project lead dispatches it. GitHub dispatches only `main`'s copy of the job, so that run comes after the phase reaches `main`, as C3's corner run did, unless the lead takes the job change into `main` earlier.

## 5. Commit order

Small commits on `coxph/phase-4`. (S) marks the commits after which §4.1's checks run.

0. Before any change: §4.1's runs at `38dad40`.
1. `docs: the CoxPH C4 plan`: this plan, fact scripts 26 to 28 with their outputs and README rows, and the status entry.
2. `reference: two penalized cases in the Cox fixture generator` (decision 5): `cases.py`, `generate.py`, and `survival.R` record pprof_py's paths and `glmnet`'s for the new cases, the R side calling `glmnet` as the adapter will (§3.1: degenerate columns left out, the column of zeros, the end of a failed path). The full set is regenerated, with `compare.R`'s diff reports: the core set unchanged, the full set with only the two cases added. A second generation reproduces the first.
3. `tests: the C4 calibration rows`: `calibrate.R`'s new rows and the regenerated report.
4. `model: the glmnet adapter` (S): `R/model-glmnet.R`; `survival_partial_loglik()`; the constants and the warning; `test-model-glmnet.R`.
5. `model: fit_cox_penalized() and its object` (S): `R/model-cox-penalized.R`; the print, tidy, and glance methods; `NAMESPACE`, help, and `_pkgdown.yml`; `test-model-cox-penalized.R`.
6. `model: select_lambda()`: `R/model-cox-selection.R`, `test-model-cox-selection.R`.
7. `tests: penalized Cox paths and cross-validation against the fixtures`: `test-cox-penalized-reference.R`, `helper-cox-fixtures.R`.
8. `bench: penalized paths and cross-validation against glmnet and pprof_py`: `run_paired.R`, `summarize_paired.R`, `cox-bench.yaml`, and the results.
9. `docs: the CoxPH C4 registers and documents`; then the gate (`/phase-gate C4`).

## 6. Decisions this plan asks for

| # | Decision | Recommendation | Register |
|---|---|---|---|
| 1 | **The adapter's other calls** (§3.1, §3.2): the score at the null point from `glmnet`'s exported `coxgrad()`; the unpenalized coefficients from survival's fitter at pprof_py's eps 1e-9 and 100 iterations; degenerate columns left out before the call; a column of zeros beside a single covariate, which `glmnet` refuses alone (§2.1, §2.3, §2.4) | adopt | DEC-113; K-143's note |
| 2 | **The fold deviances** (§3.4). (a) One `coxnet.deviance()` call per fold and set of rows over every grid point, moved to pprof_py's saturated term by one survival evaluation per set of rows: within 3.2e-13 of (b), and about 1.6 times faster on `covariates-50` (§2.7, §2.8). (b) One survival evaluation per fold, set of rows, and grid point, as the generator computed them | (a) | DEC-114; K-144's note |
| 3 | **`glmnet`'s early stops and failed solutions** (§2.6; new D-78, Class B: pprof_py returns a converged solution at every point). (a) End the path at the last point `glmnet` reached, and before the first point whose coefficients are not finite or whose deviance exceeds the null deviance (on §2.6's data, exactly where the Efron divergence starts), with one `pprof_warning_not_converged` that suggests a larger `max_iter`. (b) Only `glmnet`'s own early stop, so the Efron divergence passes through silently. (c) Refuse data with fewer events than covariates, which pprof_py fits | (a) | DEC-115; D-78 |
| 4 | **Tiers** (no tier changes). `closed_form` for the grid, λ_max, and the column scales against pprof_py, with calibration rows (§4.5). `closed_form` for the fold deviances, cvm, and cvsd against the generator's R side. `penalized_path` for paths, cvm, cvsd, and the selected coefficients against pprof_py, as DEC-097 calibrated it. `exact` for λ_min, λ_1se, the folds, and the degenerate covariates. Active sets compared exactly except within `penalized_path` of 0 (D-72) | adopt (applying a tier needs sign-off) | DEC-116, applying DEC-097 |
| 5 | **The fixtures.** (a) Two penalized cases in the full set, both tie methods, with the full set regenerated and diff reports (only additions expected; the core set unchanged): `penalized-settings` (pprof_py's `combined.csv` with a constant column; the eight settings of fact 26's part B) and `penalized-few-events` (the first 15 rows of `penalized_wide.csv`; D-78). (b) None; those settings are checked against transcriptions and direct `glmnet` calls only | (a) | DEC-117; the diff reports |
| 6 | **Benchmarks** (§4.6). The 10% rule compares `fit_cox_penalized()` with its `glmnet` call and the preparation of its inputs, pprof_py's grid included. It compares `select_lambda()` with its fold paths, its `coxnet.deviance()` calls, the shift's survival evaluations, the preparation of their inputs, and the summaries in plain R. Scenarios `covariates-50` (path and cross-validation) and `rows-1e4` (path). Measured here, then on `cox-bench.yaml` with `glmnet` added, which the project lead dispatches. C1's `glmnet` and pprof_py times are reported beside them | adopt | DEC-118 |
| 7 | **pprof_py outputs C4 leaves out** (new D-79, Class B by D-75's precedent: outputs pprof_py gives that the package does not): the partial log-likelihood and deviance ratio at each λ (`log_likelihood_path_`, `deviance_ratio_path_`); coefficients between grid points (pprof_py's `coef_at()` interpolates in log λ; the design gives grid points only, and ARCHITECTURE §E.5 reports only solutions); convergence flags and iteration counts per λ (solver-specific; the package reports `glmnet`'s passes and the points reached). (a) Leave them out, as the approved design does. (b) Add the log-likelihood and deviance ratio (from `glmnet`'s deviances and survival's null log-likelihood, with calibration rows) and the interpolation | (a) | DEC-119; D-79 |
| 8 | **Interface details** (§3.3, §3.4): `glmnet` joins NAMING §2's whitelist for adapter names, as `lme4` did; `select_lambda()` is a generic; `folds` holds one value per row of the data; `penalty_factor` is named and may be partial; `nobs()` counts events; `summary()`, `confint()`, and `augment()` raise `pprof_error_unsupported_inference`; `tidy()` gives the coefficients at the selected λ; the convergence record has `grid_points` and `stop_rule = "relative_objective"`; zero weights follow M-25 in the path and the folds | adopt | DEC-120; NAMING §2 and §10 |

## 7. Registers and documents updated in C4

- **`dev/DECISIONS.md`:** DEC-113 to DEC-120 as approved, with status notes on DEC-088 (implemented) and DEC-097 (applied to the grid and the new cases).
- **`dev/CONVENTIONS.md`:** where K-143 and K-144 are in the package, with the score from `coxgrad()`, the null fit's settings, and the saturated-term shift.
- **`dev/DISCREPANCIES.md`:**
  - D-58 extended to the penalized model;
  - D-61 and D-72 implemented, with their tests;
  - D-67's status;
  - D-78 and D-79;
  - any difference found.
- **`dev/OPEN_QUESTIONS.md`:** M-30 and M-34, implemented as decided.
- **`dev/NAMING.md`:**
  - §2: `glmnet` in adapter names;
  - §10: `select_lambda()` as a generic, the object's fields, `folds`, `grid_points`, `stop_rule = "relative_objective"`, and the new constants;
  - `pprof_warning_degenerate_covariates`'s `covariates`.
- **`dev/design/COXPH_DESIGN.md`, as built:**
  - §A.5: the one-column device and `glmnet`'s early stops;
  - §B.1 and §B.2: the signatures and fields;
  - §D.4;
  - §E.2: the calls of decisions 1 and 2;
  - §G.1: the new cases;
  - §G.2: the tiers applied;
  - §I: the benchmarks.
- **Other documents:**
  - `dev/design/ARCHITECTURE.md` §E.3 (the penalized model's column: no capability) and §E.6;
  - `NEWS.md`: the elastic-net Cox model;
  - the help pages, with examples behind `requireNamespace("glmnet")`;
  - `_pkgdown.yml`;
  - the status document.

## 8. Risks

- **`glmnet`'s robustness** (D-78). The check of §3.1 catches solutions that are not finite or whose deviance exceeds the null's, not every poor solution. Where `glmnet` and pprof_py part on ill-conditioned data (§2.6), the tests document the cases found rather than assert agreement.
- **`glmnet`'s versions.** The engine-identity tests hold the package to the installed `glmnet` bitwise, and CI installs the current release (5.1).
  - A later `glmnet` that changes its saturated term is absorbed by the shift, which is measured at every call.
  - A change to its partial likelihood would show in the comparisons with the fixtures.
- **Regenerating the fixtures** (decision 5). The generator reproduces every file byte for byte (DEC-096), and the change adds two cases, so the diff reports should show additions only. Any other difference stops the work for the project lead.
- **A grid of zeros.** When every penalized score at the null point is exactly 0, pprof_py's grid is all zeros. The implementation reproduces it, checks what `glmnet` does with it, and registers any difference.
- **Test time.** The full set's cross-validation takes a few seconds per case and tie method (§2.7) and stays behind `skip_on_cran()`. The unit tests use small data.
- **Benchmark time.** Each `select_lambda()` on `covariates-50` takes about 3.5 minutes, so the cross-validation task, both sides in two rounds, takes about 15 minutes here, and the machine pages, as at the C3 gate. The runner's measurement needs `cox-bench.yaml` on `main` (§4.6).
- **The tarball.** The core fixtures do not change, and the new R code and help add a few kilobytes to C3's 4,921,651 bytes, which are 78 KB under the 5 MB at which `R CMD check --as-cran` notes the size.
