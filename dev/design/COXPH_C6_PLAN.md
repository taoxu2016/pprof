# CoxPH Phase C6 plan: documentation and hardening

> **Status: approved by the project lead on 2026-10-16, with the eleven decisions of §6 as recommended** (DEC-130 to DEC-140). It implements the brief's §4 row C6 (`dev/coxph_brief.md`; also §2.1 item 6, §6 D's simulation study, §8, and §11) and COXPH_DESIGN §B.3 (the volume of a Cox provider), §G.4 (the simulation), §G.5, and §I, under DEC-086 to DEC-129.

C6 is the phase's last: the user and developer documentation of the Cox models, the final equivalence and benchmark reports, the simulation study of §6 D, hardening, and the final review against the brief's §11. It changes no number of any model. Its code changes are tests, two error messages, and how the bundled data are compressed; everything else is documentation, reports, validation scripts, and CI.

The evidence (§2; `dev/design/coxph-facts/36` to `39`) settles the points the request named and finds four things that change the work:

- The tarball is 22,842 bytes under the 5,000,000 at which `R CMD check --as-cran` notes its size; the vignette and the new methods sections need about 65 KB. Resaving the bundled data with xz frees 48,217 bytes, with identical objects.
- The full Cox fixture set never runs on CI: CI checks the built tarball, without `validation/`, in CRAN mode, where those tests skip. The brief's §11 criterion 2 ("on every CI platform") holds for the core set only.
- Of 72 invalid calls to the Cox functions, 66 raise pprof's classed conditions; one message names the wrong argument (`fit_fine_gray(id = )`), and one names an internal generic (profiling a penalized fit).
- Two help examples, `fit_cox_penalized()`'s and `select_lambda()`'s, take 1.1 to 1.2 s, above DEC-068's 1 s.

§6 lists the eleven decisions the plan asks for.

## 1. Deliverables

| # | Deliverable | Where |
|---|---|---|
| 1 | The vignette "Profiling providers with time-to-event outcomes" (the brief's §8) | `vignettes/time-to-event.Rmd` (new) |
| 2 | The other user documentation, where it lists models: "Models and what they support" and "Statistical methods" gain the Cox models with the formulas of K-131 to K-149; "Getting started", the README, the package help page, DESCRIPTION's description, `_pkgdown.yml`, and `cran-comments.md` | `vignettes/models.Rmd`, `statistical-methods.Rmd`, `pprof.Rmd`; `README.md`; `R/pprof-package.R`; `DESCRIPTION`; `_pkgdown.yml`; `cran-comments.md` |
| 3 | The Cox help pages reviewed: accuracy, statements of properties (DEC-065 as amended), links, and examples under 1 s with one thread | roxygen in `R/model-cox-stratified.R`, `model-cox-penalized.R`, `model-cox-selection.R`, `model-fine-gray.R`, `check-data.R`, `data-prepare.R`, `profile-*.R`, `plot-*.R`; `man/` (generated) |
| 4 | `NEWS.md`: the Cox section in its final form | `NEWS.md` |
| 5 | The developer guide's account of delegated engines (the brief's §8 and §11 item 7); ARCHITECTURE §E.6 as built | `dev/DEVELOPER_GUIDE.md`, `vignettes/adding-a-model.Rmd`, `dev/design/ARCHITECTURE.md`; `dev/README.md`, `validation/README.md`, `dev/bench/README.md` |
| 6 | The final equivalence report of the Cox phase, generated, and run on CI | `validation/run-cox-reference.R` (new), `validation/cox-equivalence-report.md` (new); `tests/testthat/helper-cox-fixtures.R` and the four Cox reference test files; `.github/workflows/rewrite-reference.yaml` |
| 7 | The final benchmark report of the Cox phase, with the runner's last run | `dev/bench/results/cox-final-<date>.md` (new), `cox-c6-runner-<date>-linux.*` |
| 8 | The simulation study of the Cox model's provider tests | `validation/run-simulation.R`, `validation/simulation-report.md` |
| 9 | Hardening: tests for the untested branches, the two messages, the examples' time, the tarball, `rewrite-bench.yaml`'s setup, CRAN readiness | `tests/testthat/`, `R/model-fine-gray.R`, `R/model-cox-penalized.R`, `data/*.rda`, `.github/workflows/rewrite-bench.yaml` |
| 10 | The final review against the brief's §11, with the register entries awaiting a methodology owner | `dev/design/COXPH_FINAL_REVIEW.md` (new) |
| 11 | Registers, COXPH_DESIGN as built, the wording list, the status document | `dev/`, `dev/design/COXPH_C6_WORDING.md` (new) |

**Not in C6** (the request; the brief's §2.2): new models or methods; Fine–Gray-based provider measures (M-41); any change to a number of an existing family or a Cox model; fixture regeneration (none is needed); the CRAN submission. D-78 and the decisions taken under delegation in C0 stay open for a methodology owner (M-16), and reporting survival's `finegray()` case-weight defect upstream stays the project lead's decision; the final review lists both.

## 2. Evidence gathered for this plan

Gathered on 2026-10-15 and 2026-10-16 on the C1 machine (Windows 11, 8 logical cores, 7.4 GB of memory, 0.8 to 1.1 GB free), with R 4.4.0, survival 3.8-12, glmnet 5.1, lme4 2.0-6, and Matrix 1.7-6, on `coxph/phase-6` at `a919c0b` (`main`'s package code). The package was built with `R CMD build` and installed with `R CMD INSTALL --preclean` into a scratch library, and the scripts in `dev/design/coxph-facts/` ran against it.

### 2.1 The tarball (36)

- `R CMD build` gives 4,977,158 bytes, 22,842 under 5,000,000 (the C5 gate's was 4,977,843).
- Compressed file by file, the content is: the reference fixtures 3,250,886 bytes; the bundled data 760,242; the Cox core fixtures 386,240; `R/` 205,424; the test files 202,785; the built vignettes (`inst/doc`) 169,631; `man/` 112,506; the vignettes' sources 34,537; the C++ sources about 29,000.
- The three `.rda` files are gzip-compressed. Resaved with xz they take 716,480 bytes instead of 764,697, 48,217 fewer, and load as `identical()` objects (`ecls_data` 90,148 to 51,044; `ExampleDataBinary` 309,067 to 303,444; `ExampleDataLinear` 365,482 to 361,992). `R CMD build --resave-data=best` resaves only `ecls_data`, since `tools::resaveRdaFiles()` leaves gzip unless another method saves more than 10%, and gives 4,941,987 bytes (35,171 fewer). DESCRIPTION's `BuildResaveData` field overrides the command line (R 4.4.0's `tools:::.build_packages()`), so it would apply to pkgbuild's builds too, which pass `--no-resave-data`.
- A built vignette costs its source twice (`vignettes/` and `inst/doc/`), its HTML, and its R code. The getting-started vignette's six plots are 53,285 of its HTML's 65,375 compressed bytes; a plot of 6 by 4 inches is 7,492 bytes at 96 dpi and 5,403 at 72 dpi.
- From these, the C6 documentation needs about 65 KB: the vignette about 42 KB (a 30 KB source twice, its HTML with two plots, its R code), the Cox sections of "Statistical methods" about 15 KB, and the other documents, help, and tests about 8 KB. These are estimates; each documentation commit measures the tarball (§4.3).

### 2.2 A prototype of the vignette's computations (37)

- The data: `ExampleDataBinary`'s 7,944 patients of 100 hospitals and their five risk factors, with times in days simulated from a Cox model with hospital effects drawn from N(0, 0.2²): 2,514 deaths, 1,431 transplants (a competing event), 1,977 late entries, and 17,061 (start, stop] rows with 9,117 hospitalizations for the recurrent events.
- Every computation the vignette would show takes 2.8 s in all, two plots included: `check_data()` 0.13 s, the fit 0.03 s, `profile_providers()` with mid-p limits 0.03 s, the two plots 0.77 s, the Fine–Gray fit 0.39 s (19,828 expanded rows) and its cumulative incidence 0.43 s, the penalized path with 20 values of λ 0.11 s and a 5-fold cross-validation 0.63 s.
- The fit's coefficients are `identical()` to `coxph(Surv(entry, exit, died) ~ z1 + z2 + z3 + strata(hospital), ties = "breslow", timefix = FALSE)`'s; with `coxph()`'s defaults (Efron ties, `timefix = TRUE`) they differ by up to 2.9e-4.
- The mid-p test flags 5 hospitals higher and 4 lower than expected at level 0.95. The two plots are 8,808 and 6,972 bytes as PNG files.

### 2.3 `R CMD check --as-cran` at the start of C6

On the tarball of §2.1, in two runs: the first stopped during the tests at this session's 30-minute limit for background commands, and the second ran without the tests (489 s).

- The examples take 38 to 40 s in all. The Cox examples take 0.03 to 0.25 s each, except `fit_cox_penalized` (1.14 s) and `select_lambda` (1.21 s), both of which run a 5-fold cross-validation; DEC-068 asks for under 1 s.
- The five vignettes' rebuild takes 38 s ("checking re-building of vignette outputs").
- Notes: the two of every earlier gate (the website's address answers 404; "unable to verify current time"), and a third for a file `build.log` at the top level: the log of this session's first build attempt, which ran in the repository's root before R was on the PATH and was in the tree when these tarballs were built. It was deleted; it was never committed.

### 2.4 Invalid inputs (38)

72 invalid calls to the Cox functions and their methods (17 of them penalized, run with glmnet installed):

- 66 raise pprof's classed conditions, with messages that name the argument and what it must be.
- 4 raise R's own errors, which every family shares: an unused argument (`method = "efron"`, `coxph()`'s name for `ties`), a missing required argument (`cause`), `newdata` without a covariate ("object 'sex' not found", as `predict()` of `fit_logistic_fe()` and `fit_linear_fe()` models gives), and a response written with a fixed-length vector that no longer matches the rows once incomplete ones are dropped (an artificial input).
- 2 return, as designed: an increasing λ grid is sorted (K-143), and `n_lambda = 1` gives a path of one point.
- Two messages to fix: `fit_fine_gray(id = "subject")` without that column says "`cluster` names column 'subject'", because `id` reaches `data_prepare()` as its `cluster`; and `test_providers()` on a penalized fit says that the model does not support "`profile_spec()`", an internal generic, where the Fine–Gray model's says which capability it lacks.

### 2.5 A prototype of the simulation's replicate (39)

50 providers, a constant baseline hazard in days, the other families' covariates (x1 with a provider-level shift), a quarter of the patients entering late, integer days, 100 replicates per scenario:

| Scenario | Seconds per replicate | Expected events per provider (medians of the smallest, the median, and the largest) | Mid-p: size, coverage | Exact: size, coverage | Outliers: power and coverage, mid-p; exact |
|---|---|---|---|---|---|
| no provider effects, 30 to 150 patients per provider | 0.038 | 13.3, 43.1, 85.4 | 4.90%, 95.10% | 3.92%, 96.08% | |
| six outlying providers, log hazard ratios ±0.5 | 0.046 | 13.4, 42.9, 87.4 | 4.73%, 95.27% | 4.00%, 96.00% | 87.0%, 96.2%; 85.0%, 97.2% |
| no provider effects, 5 to 30 patients per provider | 0.024 | 1.7, 8.2, 18.4 | 4.70%, 95.30% | 3.14%, 96.86% | |

The Monte Carlo standard error of a size from 100 replicates is about 0.3 percentage points. The whole study at 200 replicates would take about 25 s for the Cox family; the other families take 1,952 s (the committed report).

### 2.6 What CI covers

- At `8023d8f` every workflow passed on `main` and on `coxph/phase-5` (§7's status entry): `rewrite-check`'s eleven jobs, three systems with R release, devel, and oldrel-1 and R 4.4.0 on Linux and Windows. Its two `minimal` jobs install the hard dependencies and the tests' packages only; the Linux one checks without glmnet, and its check notes "Package unavailable to check Rd xrefs: 'glmnet'".
- `rewrite-check` and `rewrite-coverage` test the built package with `NOT_CRAN` unset, so `skip_on_cran()` tests skip, and `validation/` is not in the tarball. The core Cox set runs on every platform; the full set (16 of the 23 Cox cases, among them the provider-scale, recurrent, zero-weight, and large-mean cases, six of the seven penalized ones, and the delayed-entry and weighted competing-risk ones) runs only in local `devtools::test()` runs. `rewrite-reference` runs pprof 1.0.3's fixtures only.
- `.github/workflows/rhub.yaml` is R-hub's generic workflow, from the upstream (`de109d9`), dispatched by hand with a list of R-hub platforms; it has never run on the fork.
- `cox-bench.yaml` has run twice, both for the C3 gate (runs 38003811342, failed, and 38004882689); the penalized and Fine–Gray tasks have not run on a runner. `rewrite-bench.yaml` has never run, and its setup is the one that failed `cox-bench.yaml`'s first dispatch.

### 2.7 Coverage and the branches left untested

At the C5 gate, `covr` gave 96.72% of the package, and of the R lines each phase added 95.22% (C2), 98.13% (C3), 98.50% (C4), and 97.45% (C5). The uncovered lines it listed: the codes of a cluster (`R/model-survival.R:124`) and of an `id` (`:361`) that are factors; five checks of `validate_pprof_fine_gray()`; the errors for covariates that are not finite and for `data` whose refit differs from the model; and the multi-state check of `data_survival_response()`, which `data_prepare()`'s own check makes unreachable.

### 2.8 The benchmarks and what remains

- Measured: C1's baseline (2026-10-08); the paired runs of C2 (2026-10-09), C3 (2026-10-09, and the corner with the two fits at DEC-105's line on a GitHub runner, run 38004882689), C4 (2026-10-14), and C5 (2026-10-15), each on the code it names.
- Code those runs measured that changed afterwards: since the runner's run (`54488ae`), C4 split the survival adapter's input builder (`250247c`) and C5 added the competing-risks branch of the data layer (`c5f1cc9`) and the Fine–Gray functions; both run in the stratified fits, whose results stayed bitwise identical but whose times were not measured again. The penalized and Fine–Gray code has not changed since its runs, nor has the profiling code since C3's.
- Open: `cox-bench.yaml`'s Fine–Gray tasks on providers-100 and providers-7500 (DEC-127); the fits at DEC-105's line at 7,500 providers and with 5 covariates and robust variance, where in one process the fit with its measures takes 1.107 and 1.087 times the comparator, the excess being `standardize_providers()`'s table of 7,500 providers (0.048 s, `25_fit_measures_parts.txt`); the measures' time beside pprof_py's at 10,000 rows (0.028 s against 0.009 s) and at 7,500 providers (0.20 s against 0.13 s), a SHOULD (DEC-098); and `rewrite-bench.yaml`.

### 2.9 What the documentation says now

- "Models and what they support" and "Getting started" speak of "the seven models"; the README of "binary and continuous outcomes"; DESCRIPTION's description of "linear and generalized linear models"; `?pprof` names only `fit_cox_stratified()` among the Cox fits; "Statistical methods" says that "the results are those of pprof 1.0.3"; `cran-comments.md` predates the Cox models.
- `dev/DEVELOPER_GUIDE.md`'s first rule names pprof 1.0.3 as the only reference, and the guide does not mention the Cox fixtures, their generator, the calibration, or delegated engines; "Adding a model to pprof" has the Cox hooks (`count_distribution`, `direct_by_provider`, `provider_midp`) but no account of an engine adapter; ARCHITECTURE §E.6 is a sketch followed by five "as built" paragraphs; `dev/README.md` does not index the Cox design, plans, and facts.
- The facts folder's README lacks the row and the command of fact 35.

## 3. Approach

### 3.1 The vignette (decisions 1 to 3)

`vignettes/time-to-event.Rmd`, "Profiling providers with time-to-event outcomes", in the other vignettes' style: every number in the text computed inline, one thread, a seed before the random draws, deliberate warnings shown and explained, no register IDs (DEC-064). Its outline, after the brief's §8:

1. **What the Cox models are in pprof.** The provider-stratified Cox model and He and Schaubel's two-stage measures; estimation by survival and glmnet; the definitions those of pprof_py 0.7.0, the group's Python package; where the formulas are ("Statistical methods").
2. **The data.** `Surv(time, status)` and `Surv(entry, exit, status)`; delayed entry; integer time units, and `check_data()`'s report of near-tied times, which the fits keep apart; missing values; weights of 0; offsets.
3. **The stratified model.** `fit_cox_stratified()`, `summary()`, ties, the robust variance with `cluster`; the same fit from `coxph()` with the package's settings, shown `identical()`, and how `coxph()`'s defaults differ; `baseline_hazard()` and `predict()`.
4. **Standardized measures.** Indirect ratios (SMR: observed over expected events at the national baseline) and direct ratios; person-time; a provider without expected events.
5. **Tests and flags.** The mid-p test (the default) and the exact test, their limits, levels, and multiplicity, as "Getting started" puts it.
6. **Plots.** The funnel plot, whose limits are those of the mid-p test, and the caterpillar plot; what `plot_volume()` counts (decision 4).
7. **Recurrent events.** Hospitalizations as (start, stop] rows, the robust variance clustered by patient, and the standardized hospitalization ratio (SHR) as observed over expected hospitalizations; production measures such as CMS's SHR are defined otherwise.
8. **Competing risks.** Cause-specific models, `Surv(entry, exit, status == "death")`, profiled per cause; `fit_fine_gray()` and its cumulative incidence; why the Fine–Gray model has no provider measures.
9. **Penalized models.** `fit_cox_penalized()`, `select_lambda()`, and their coefficients; no profiling at a selected λ. Evaluated only when glmnet is installed (`eval = requireNamespace("glmnet", quietly = TRUE)`), with a sentence saying so.
10. **pprof and `coxph()`'s defaults.** The brief's §3.3 in users' terms: ties; near-tied times; robust variance with non-integer weights; weights of 0; covariates the fit cannot estimate and data without events; the order of step halving; the reported baseline hazard; measures over unweighted rows at a Breslow baseline whatever the ties; the penalized cross-validation's normalization and folds; missing values; glmnet's tie default.
11. **References**, each checked against its DOI or publisher page before it is cited (DEC-065 (5)): among them He and Schaubel (2014), Andersen and Gill (1982), Lin and Wei (1989), Fine and Gray (1999), Putter, Fiocco and Geskus (2007), Simon, Friedman, Hastie and Tibshirani (2011), Garwood (1936), and Spiegelhalter (2005).

**Data** (decision 1): §2.2's, built in the vignette's first chunk from `ExampleDataBinary`, so that it costs no data file, has 100 providers, and has known effects; the help pages keep survival's `lung` and `mgus2`.

**Run time and size** (decisions 2 and 3): nothing is precomputed and nothing is left out of the build; its computations take about 3 s here. Under `R CMD check` the five vignettes' rebuild takes 38 s, about 8 s each with R's start, knitting, and pandoc, so the six should take about 46 to 48 s. Two plots. Its share of the tarball and the rebuild time are measured when it is committed (§4.3).

**Wording** (decision 10): each statement of a statistical property, here and in §3.2 to §3.4, goes into `dev/design/COXPH_C6_WORDING.md` with its source: the formula the code computes, a computation shown in the vignette, or the literature.

### 3.2 The other user documentation

- **"Models and what they support."** "The seven models" becomes "The models": the table gains a time-to-event row (`fit_cox_stratified()`, `fit_cox_penalized()`, `fit_fine_gray()`); a section on the Cox models, what each assumes and estimates; "Choosing a model" adds what bears on the choice between cause-specific and Fine–Gray models, from the literature; the capability table, computed from fits, includes the Cox fits (the penalized one when glmnet is installed); the list of differences between families adds observed against expected events with Poisson tests.
- **"Statistical methods."** Its introduction says which reference each family follows. Cox sections under its existing headings: the model, risk sets, and ties (K-131, K-132); estimation and variance, delegated to survival (K-133 to K-135); the covariate test (K-148); the measures (K-136 to K-139); the tests and flags (K-140 to K-142); the limits (K-140, K-141); the funnel limits (K-149); providers without expected events (K-147); the penalized path and cross-validation (K-143, K-144); competing risks (K-145, K-146); and rows of its table of numerical conventions. Short computations check formulas against the package on survival's `lung` data, as the vignette does for the logistic model: the expected events by hand, Σ_j E_j = O, and a mid-p p-value from `ppois()`.
- **"Getting started"**: time-to-event outcomes in its introduction, and pointers to the new vignette where it lists the others. **README**: the outcomes it handles, the vignette among "Learn more", and He and Schaubel (2014) among the references. **`?pprof`**: the penalized and Fine–Gray fits, `select_lambda()`, `baseline_hazard()`, cause-specific models, and the vignette. **DESCRIPTION**: the description names the Cox models and the packages that fit them ('survival', 'glmnet'). **`_pkgdown.yml`**: the vignette in the articles menu and index. **`cran-comments.md`**: the test environments and results as of the gate, and the new imported and suggested packages.

### 3.3 The help pages

Every page that documents a Cox function or a Cox case of a shared one: `fit_cox_stratified`, `cox_stratified_methods`, `baseline_hazard`, `fit_cox_penalized`, `select_lambda`, `cox_penalized_methods`, `fit_fine_gray`, `fine_gray_methods`, `check_data`, `data_prepare`, `model_contract`, `test_providers`, `standardize_providers`, `funnel_limits`, `profile_providers`, `plot_funnel`, `plot_caterpillar`, `plot_volume`, and `pprof-package`. Each is read against the code, and a statement that contradicts it is a Class C fix. The checks are DEC-068's: an example under 1 s with one thread (the two penalized examples get fewer λ values and folds); no register IDs in the rendered text; `@family` and `@seealso` links. Statements of properties go into the wording list.

### 3.4 `NEWS.md`

The Cox section in its final form: one account of the Cox models in the order a user meets them (the stratified model and its methods, profiling, `check_data()`, competing risks, penalized paths, the developer interface), each claim checked against the code and the final reports. The benchmark sentences move to "Performance", with the final report's numbers; glmnet and survival to "Dependencies"; the new vignette and the Cox sections to "Documentation". The opening paragraph says that 2.0.0 adds Cox models.

### 3.5 The developer guide and ARCHITECTURE (the brief's §11 item 7)

- **`dev/DEVELOPER_GUIDE.md`.** Its first rule names both references, pprof 1.0.3 for the existing families and pprof_py v0.7.0 for the Cox models, with the CoxPH section of DISCREPANCIES. "Where things are" and "Commands" add the Cox fixtures and their generator (`dev/reference/cox/`, its Python environment, `cox-fixtures.yaml`), the calibration (`calibrate.R`), the Cox equivalence report, the simulation, and the Cox benchmarks (`dev/bench/cox/`, `cox-bench.yaml`).
- **A section on delegated engines**, the account the brief's §8 asks for: when estimation is delegated (DEC-086's rule); one adapter file per engine, `R/model-<engine>.R`, with functions `<engine>_*()` (NAMING §2); the engine's lowest documented entry point that gives its user-level function's results, called as that function calls it, so that the results are bitwise the same (DEC-091, DEC-100); derived quantities from the engine's own routines on its result, not recomputed (DEC-099), and other quantities from its exported functions (DEC-113); every setting explicit; messages captured and errors classed with `engine_message`; only extracted components kept, the engine's object only with `keep_data = TRUE`; engine-identity tests under `cox_engine` (0, 0); the minimum version that has the behavior relied upon (DEC-106); a suggested engine required at the call (DEC-088); the benchmark rule against the engine call and the preparation of its inputs (DEC-105). Then, for each later model of the brief's §2.2, which layer and hooks it would use and where to start.
- **"Adding a model to pprof"** gains a section "Delegating estimation to another package" with a short runnable example: a model whose provider effects come from `glm()`, an engine-identity check of its estimates against a direct `glm()` call, and the points of the guide's account that a model author needs. Its family-specification table gains a Cox column.
- **ARCHITECTURE §E.6** becomes "Survival models, as built": the data layer's response types, the two adapters, the three models, the profiling hooks and capabilities, and what changed in shared code with defaults that keep the existing families; the five "as built" paragraphs fold into it, with COXPH_DESIGN as the record. §E.3's table is checked as final.
- **The indexes**: `dev/README.md` (the Cox design, plans, facts, generator, and reports), `validation/README.md` (the new script and reports), `dev/bench/README.md` (the final report), and the facts README (35 to 39).
- **A dry run.** A subagent without the project's context reads only the developer guide, "Adding a model to pprof", and ARCHITECTURE §E, and writes the design of two later models of the brief's §2.2: frailty Cox profiling through `coxme` (a delegated engine) and discrete-time provider models through person-period data and the logistic fixed-effect engine. The gaps it reports are fixed in the guide; its report is kept as a fact (`40_guide_dry_run.md`), as DEC-063's was for the rewrite.

### 3.6 The final equivalence report (decision 6)

`validation/run-cox-reference.R` writes `validation/cox-equivalence-report.md`, the analogue of `run-reference.R` for the Cox fixtures:

- **How.** The four Cox reference test files (`test-cox-fixtures.R`, `test-cox-reference.R`, `test-cox-penalized-reference.R`, `test-cox-fine-gray-reference.R`) compare through local helpers (`expect_cox_match()`, `expect_fine_gray_match()`, and their `differ` forms), through `expect_null(reference_compare(...))` (the fixtures' and penalized files), and through the last-step bounds of default fits. These become calls of one helper in `helper-cox-fixtures.R` that asserts exactly what each call asserted, as one expectation, and, when the script asks for it, records the comparison: file, case, record, quantity, tier, the ratio of the largest difference to the allowed one, and the register entry of an expected difference. The script runs those files and the engine-identity files (`test-model-survival.R`, `test-model-glmnet.R`, `test-model-fine-gray.R`) with `NOT_CRAN` set and both fixture sets present, and exits with status 1 on any failure. No expectation is added, removed, or changed; each file's count of expectations is checked before and after.
- **Outline.** (1) The run: date, R, system, the package's commit, survival and glmnet, the fixtures' generator commit. (2) Summary: cases, records, comparisons; within their tier, explained by a register entry, failing, skipped. (3) Against pprof_py, by case, tie method, and record: fits (iterations, default coefficients within the last Newton step, tight coefficients, variances, log-likelihoods), residuals and robust variances, baselines and curves, measures, tests, limits, flags, and funnel limits, cause-specific fits, penalized paths, cross-validation and selection, and Fine–Gray expansions, fits, and cumulative incidence: the largest ratio to the tier of each. (4) Against survival and glmnet: the installed engines against the fixtures' records, and the package against direct engine calls, bitwise. (5) The explained differences, with their entries (D-56, D-57, D-58, D-64, D-72, D-78, M-23). (6) Providers within the probability tier of a flag threshold. (7) The calibration: `calibrate.R`'s result, reproduced byte for byte. (8) The register entries D-56 to D-81 with class and status, read from DISCREPANCIES' CoxPH table, the Class B items awaiting a methodology owner marked.
- **CI.** `rewrite-reference.yaml`'s jobs run it, with glmnet installed: the fixtures' platform and the Linux, macOS, and Windows runners. That gives the brief's §11 criterion 2 for the full set.

### 3.7 The final benchmark report and its runs (decisions 7 and 8)

`dev/bench/results/cox-final-<date>.md`, hand-written from the committed CSVs and reports, as `phase8-final-20261006.md` was:

1. **The runs**: C1's baseline, the paired runs of C2 to C5, and the runner's runs (the C3 corner and C6's), each with the code it measured and the commits that changed that code afterwards (§2.8).
2. **The MUST** (the brief's §3.7, DEC-105): every fit task's verdict in every run that measured it, the fits at the line explained (fact 25), and the final runner verdicts.
3. **The SHOULD** (DEC-098): large stratified fits, the robust variance, the measures, the Fine–Gray fits, and the penalized path and cross-validation beside pprof_py.
4. **The other items of §3.7**: expected counts in closed form, mid-p limits against pprof_py's (20 to 600 times faster; the corner 256 times), the formula interfaces' cost (DEC-100, DEC-105), peak memory and objects' sizes.
5. **What stays open**, with the reasons: DEC-105's alternative 3, the measures' SHOULD at 10,000 rows and 7,500 providers.

**The runs it needs** (decision 7): one dispatch of `cox-bench.yaml` by the project lead, from `main` or the pushed phase branch, with `only` = `" fine_gray|^providers-7500 breslow$|^covariates-5 robust$|^center (breslow|robust)$"` and 2 rounds: the Fine–Gray tasks (DEC-127), and again, at the final code, the two fits at DEC-105's line, with the center as control. C6 changes none of the code they run; the message fix in `fit_fine_gray()` runs before any survival call. The project lead downloads the artifact `cox-bench-results`, and its CSV, JSON, report, and notes are committed as `cox-c6-runner-<date>-linux.*`, the notices read with `dev/tools/ci_runs.R`. Nothing is measured again on this machine: the measures' code has not changed since C3's run, whose numbers stand.

**`rewrite-bench.yaml`** (decision 8): its setup follows `rewrite-reference.yaml`'s per-platform Linux job, which builds pprof 1.0.3 on a runner and passes: current binaries from the public package manager, and the CRAN snapshot only for the reference library that `setup_reference_library.R` builds. The project lead dispatches it once with a few tasks to confirm it runs; it stays informational.

### 3.8 The simulation study (decision 5)

`validation/run-simulation.R` gains the family `cox_stratified`, with §2.5's design:

- 50 providers; a constant baseline hazard of 1/1,000 a day; follow-up of 180 to 1,095 days; a quarter of the patients entering late (days 1 to 180), so (entry, exit] rows; integer days, so tied times; the other families' covariates and coefficients.
- Three scenarios of its own: no provider effects (30 to 150 patients per provider); six outlying providers with log hazard ratios +0.5 and −0.5 (three each); no provider effects with 5 to 30 patients per provider, where the expected counts are small and the Poisson tests' discreteness shows.
- The fit at its defaults; `test_providers()` with the mid-p (default) and the exact test, and `standardize_providers()` with the matching intervals, two-sided at level 0.95. The report gets one row per scenario and test, with size, power, wrong-direction flags, missing flags, and the coverage of the indirect ratio's interval for providers without and with an effect; "effect coverage" is "—", since the model has no provider effects.
- The truth: a provider's indirect ratio is its hazard ratio, exp(effect), its expected events under its own hazard over those under the baseline hazard for its patients' time at risk. As in the other families, the truth uses the true baseline, while the measures use the national baseline estimated from every provider, outliers included; the script's header says so.
- 200 replicates per scenario, as for the other families (a Monte Carlo standard error of about 0.25 percentage points for a size), seeds as the script derives them, the Cox family last so that no other family's seeds change. The scenarios become per family; the existing families keep theirs and their order.
- It runs here: about 25 s for the Cox family and 33 minutes for the whole script. The regenerated report must give the existing families' rows unchanged: the code, lme4 2.0-6, and Matrix 1.7-6 are those of the committed report, so the rows check the existing families once more. The report stays informational (DEC-053): a departure from nominal is a question for the methodology owners.

### 3.9 Hardening (decision 9)

- **Coverage.** Tests for the factor codes of a cluster and of an `id`, each against `coxph()` with the same factor column bitwise, with an unused level among the factor's; and for the other reachable lines of §2.7 (the validator's five checks, the covariates that are not finite, `data` whose refit differs). The coverage of the R lines the CoxPH phase added (against `ea7c07b`) is measured at the gate; the brief asks for at least 90%, and the phases measured 95% to 98.5%. Lines that cannot be reached are listed in the final review, not removed.
- **Inputs and messages.** The two Cox messages of §2.4 are fixed, with regression tests: `fit_fine_gray()` checks `id` as `id` before `data_prepare()`; the penalized model gets a family specification with the required fields and no profiling hooks, as the Fine–Gray model has, so that profiling it names the capability it lacks. R's own errors of §2.4, which every family shares, stay.
- **Timing.** The two penalized examples under 1 s; the vignettes within decision 3's budget, measured at each documentation commit and at the gate.
- **CRAN readiness.** The tarball under 5,000,000 bytes (decision 2); `urlchecker::url_check()` on the documentation; the description (§3.2) and `cran-comments.md`; the two notes of every earlier gate (the website's address answers 404; "unable to verify current time") listed in the final review, the first being the owners' to clear before a release (DEC-066).
- **Other platforms.** No new workflow: CI covers three systems with four R versions, and a job checks without glmnet. One gap is CRAN's check without long doubles, under which R's sums and survival's change in their last bits: the Cox tests compare with the fixtures under the calibrated tiers and with survival's results bitwise on the same machine, which should hold there too, but no run has shown it. The project lead dispatches `rhub.yaml` once with `config` = `nold`; a failure there is investigated like any other.

### 3.10 The final review (decision 11)

`dev/design/COXPH_FINAL_REVIEW.md`:

1. **The brief's §11 criteria**, each with its evidence and status: (1) the capabilities of §2.4 and their dispositions, with the outputs not given (D-75, D-79, D-81); (2) the Cox comparisons on every CI platform (§3.6) and every difference registered; (3) the existing families bitwise identical (the snapshot, the tests, the reference suite at every commit that touched shared code, C2 to C6); (4) no estimation code that survival or glmnet provides, from a review of each computation in the Cox files and whether an engine provides it (the λ grid, the fold deviances' saturated term, the measures, the tests, the limits: the package's own, as the brief assigns them); (5) §3.7 from the final benchmark report; (6) `R CMD check` and coverage; (7) the developer guide and its dry run.
2. **The deliverables** of the brief's §2.1 and the phases' plans.
3. **The register**: D-56 to D-81 with class and status; the Class B items decided under delegation and confirmed by the project lead, which await a methodology owner (M-16), with D-78; the questions M-23 to M-41.
4. **Open items for the project lead**: the methodology owners (M-16); reporting survival's `finegray()` defect and pprof_py's defects (Appendix B) upstream; the website's address; the CRAN submission; `CLAUDE.md`'s "Current phase" once the phase closes.
5. **Known limits**: the SHOULDs not met (DEC-098), D-78's data, the Fine–Gray weights that small providers with late entries leave undefined (D-80), and what `plot_volume()` counts.

## 4. How unchanged numbers are checked

### 4.1 The commits that touch package code or data

Commits 2 to 4 of §5 (tests, the two messages, the data's compression), marked (S):

1. In the verification worktree, before any change (at `a919c0b`) and after each (S) commit: `devtools::test()`, with no failure, the previous run's tests and expectations plus the new ones; `validation/run-reference.R`, whose report must equal the committed one but for its date and commit (368 of 368 cases); and the `data_prepare()` snapshot test.
2. The Cox tests pass with their expectations unchanged; `dev/reference/cox/calibrate.R` reproduces the committed calibration report byte for byte.
3. A comparison of the installed namespace before and after (every function deparsed, the exports, the registered methods, the data), as DEC-061's guard did in the rewrite's Phase 7: commit 3 may change only `fit_fine_gray()` and add the penalized model's family specification; commit 4 only the data files' bytes, the objects `identical()`.

### 4.2 The test helpers (commit 6)

The shared comparison helper must leave every Cox reference test's expectations as they are: each file's number of expectations, before and after, and every one passing.

### 4.3 Documentation commits

`devtools::document()`, with `git status` showing only the intended generated files; `R CMD check --as-cran --no-manual`, run alone: 0 errors, 0 warnings, and the two notes of the earlier gates; the namespace comparison showing no function changed (roxygen edits change no code); the tarball's size with its room left; the vignettes' rebuild time.

### 4.4 At the end

The final equivalence report passes; the simulation report's existing rows are unchanged; the gate's checks (`/phase-gate C6`).

## 5. Commit order

Small commits on `coxph/phase-6`. (S) marks the commits after which §4.1's checks run; (D) those after which §4.3's run.

0. Before any change: §4.1's runs at `a919c0b`, and the namespace's state.
1. `docs: the CoxPH C6 plan`: this plan, facts 36 to 39 with their outputs, the facts README (35 to 39), and the status entry.
2. `tests: factor clusters and subjects, and the Cox branches left untested` (S).
3. `model: messages for a missing id column and for profiling a penalized fit` (S).
4. `data: the bundled data compressed with xz` (S), or decision 2's alternative.
5. `validation: the Cox model in the simulation study`, and the regenerated report.
6. `validation: the final Cox equivalence report`: the shared helper (§4.2), `run-cox-reference.R`, its report.
7. `ci: the Cox comparisons on every platform, and rewrite-bench's setup`.
8. `docs: the time-to-event vignette` (D).
9. `docs: the Cox models in the user documentation` (D): "Models and what they support", "Statistical methods", "Getting started", README, `?pprof`, DESCRIPTION, `_pkgdown.yml`.
   - **Check-in** (decision 10): the drafts of 8 and 9 with the wording list, for the project lead's decision on the wording, before the rest.
10. `docs: the Cox help pages reviewed` (D).
11. `docs: delegated engines in the developer guide; ARCHITECTURE §E.6 as built` (D), with the dry run.
12. `bench: the runner's last Cox run and the final benchmark report` (after the project lead's dispatch).
13. `docs: NEWS and cran-comments in their final form` (D).
14. `docs: the CoxPH final review, registers, and documents`; then the gate (`/phase-gate C6`).

Each (D) check takes about 15 minutes alone, each (S) run about 15 (the tests 10 to 13 minutes, the reference suite about 2), and the simulation 33 minutes in the background.

## 6. Decisions this plan asks for

| # | Decision | Recommendation | Register |
|---|---|---|---|
| 1 | **The vignette's data** (§2.2, §3.1). (a) Built in the vignette from `ExampleDataBinary`'s 100 hospitals and its patients' risk factors, with times in days simulated from a stated Cox model with a seed: no data file, provider-scale, known effects, 2.8 s for every computation shown. (b) survival's data sets (`lung`'s 18 institutions of 2 to 36 patients; `cgd`'s 13 hospitals; `mgus2` with sex as provider): real data, but too few providers to show profiling. (c) A new bundled data set: about 60 to 100 KB, more than the tarball's room | (a) | DEC-130 |
| 2 | **Room in the tarball** (§2.1). (a) Resave `data/*.rda` with xz: 48,217 bytes, objects `identical()`, the files' bytes change in the repository; (b) DESCRIPTION's `BuildResaveData: best`: 35,171 bytes, the repository's files unchanged; then, only if a documentation commit leaves less than 10 KB of room, (c) the vignettes' plots at 72 dpi (about 20 KB, coarser figures) and (d) one plot fewer in the new vignette (about 9 KB). Not: the vignette as a pkgdown article (DEC-062's last resort: neither installed nor checked by `R CMD check`); justifying the size note | (a), with (c) and (d) as fallbacks | DEC-131 |
| 3 | **The vignettes' budget** (DEC-062: each vignette's code at most 10 s, all five at most 30 s). The new vignette's code at most 10 s here, the six at most 40 s; its share of the tarball and the rebuild time reported at each documentation commit | adopt | DEC-132, amending DEC-062 |
| 4 | **The volume of a Cox provider in `plot_volume()`** (COXPH_DESIGN §B.3). (a) Its number of rows, as built; the help and the vignette say that with (start, stop] data the rows are intervals, not patients, and that the funnel plot puts the providers on their expected events; no code changes. (b) Its expected events, E_j, the funnel's precision: the plot would read them from the indirect measures, which a result of direct standardization lacks, and its axis would differ by family. (c) Its person-time, added to the measures' table for Cox models (a change to a result) and plotted in the data's time units | (a) | DEC-133; COXPH_DESIGN §B.3 as built |
| 5 | **The simulation study** (§2.5, §3.8). The Cox family in `run-simulation.R`: three scenarios (no provider effects; six outliers at log hazard ratios ±0.5; small providers), the mid-p and exact tests with their limits, 200 replicates, run here (about 25 s for the family, 33 minutes for the script), the existing families' rows checked unchanged; informational, as DEC-053 made the study | adopt | DEC-134 |
| 6 | **The final equivalence report** (§2.6, §3.6). (a) Generated by `validation/run-cox-reference.R` from the Cox reference tests, through one shared comparison helper that records each comparison's ratio to its tier, with the calibration and the register's CoxPH entries; run on CI's reference jobs, so that the full set is compared on every platform (criterion 2). (b) Hand-written from the test results and the calibration report: no margins for the package's own comparisons, and the full set compared on this machine only | (a) | DEC-135 |
| 7 | **The final benchmark runs** (§2.8, §3.7). (a) One dispatch of `cox-bench.yaml` by the project lead: the Fine–Gray tasks, and the two fits at DEC-105's line with a control, at the final code; nothing measured again here; DEC-105's alternative 3 not taken, and the measures' SHOULD at 10,000 rows and 7,500 providers recorded as not met (0.02 s and 0.07 s slower than pprof_py's), with the reasons. (b) (a), and alternative 3: the adapter's inputs built with fewer copies and the strata coded by an integer match, results bitwise unchanged, with a paired run before and after. (c) Every task on the runner (`only` = "."), about 3 to 4 hours of its 5.5 | (a) | DEC-136; DEC-098's and DEC-105's status |
| 8 | **`rewrite-bench.yaml`** (§2.6). (a) Its setup as `rewrite-reference.yaml`'s per-platform Linux job's, and one dispatch by the project lead with a few tasks to confirm it runs. (b) Left as it is, recorded as not working. (c) Removed: the gate benchmarks of the existing families run on the project lead's machine | (a) | DEC-137 |
| 9 | **Hardening** (§3.9): the tests of §2.7's reachable lines; the two message fixes with regression tests; R's own errors left as every family has them; the two examples under 1 s; `urlchecker`; the description and `cran-comments.md`; `rhub.yaml` dispatched once by the project lead with `nold`, no new workflow | adopt | DEC-138 |
| 10 | **Wording** (DEC-065 as amended). (a) One check-in after commits 8 and 9, with the drafts and the wording list, before the remaining documentation, as DEC-061 had for the rewrite's Phase 7. (b) The wording list reviewed at the gate only | (a) | DEC-139 |
| 11 | **The final review**: `dev/design/COXPH_FINAL_REVIEW.md` with §3.10's contents, and the gate's report pointing to it | adopt | DEC-140 |

## 7. Registers and documents updated in C6

- **`dev/DECISIONS.md`:** DEC-130 to DEC-140 as approved; DEC-062 amended by DEC-132; the status of DEC-098 and DEC-105 with the final runs.
- **`dev/DISCREPANCIES.md`:** the status of D-56 to D-81 as the final review finds it; any difference from pprof_py found while documenting. The two message fixes concern the package's own messages, not a difference from pprof_py, so they are recorded in this document's status entries and the final review, with their regression tests.
- **`dev/OPEN_QUESTIONS.md`:** the CoxPH questions as the final review finds them; any question the documentation raises, with a proposed default.
- **`dev/design/COXPH_DESIGN.md`, as built:** §B.3 (the volume), §G.4 (the simulation), §G.5 (CI), §I (the final runs), §J (C6's entries).
- **`dev/design/ARCHITECTURE.md`** §E.3 and §E.6; **`dev/NAMING.md`** if a name is added (none is planned).
- **The status document**, after each session with material progress. Its entry for this plan records `main`'s CI on `8023d8f`.
- **`CLAUDE.md`** is not edited in C6; at the gate the report proposes the text of its "Current phase" section for the project lead's approval.

## 8. Risks

- **The full Cox set on other platforms** (decision 6). It has run only on Windows with R 4.4.0. On Linux and macOS, survival's fits differ in the last bits; the tiers absorb that where the calibration measured margins of orders of magnitude, but flags near a threshold or a default fit's iteration count could differ. A failure is investigated; no tier changes without sign-off.
- **The tarball** (decision 2). The estimates of §2.1 could be off by tens of kilobytes; each documentation commit measures it, and the fallbacks are ordered.
- **The wording** (decision 10). Statements about competing risks, recurrent events, and production measures are where users read most into the text; each comes from the formulas or the literature, and the check-in shows every one.
- **The simulation's existing rows** (§3.8). If they change, the cause is found before the report is committed: the code of those families has not changed, so a change would come from the environment.
- **The dispatches.** The runner's run, `rewrite-bench.yaml`'s, and `rhub.yaml`'s need the project lead; until they run, the final reports say what is missing.
- **The shared test helper** (commit 6). Merging the four files' helpers could change what a comparison asserts; the expectation counts and the comparisons' outcomes before and after guard it.
- **Time.** About ten check runs of 15 minutes, the simulation, and the dispatches; the check-in splits the documentation into two stages.
