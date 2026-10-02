# Rewrite and Modernize the R `pprof` Package — Engineering Brief (v2)

## 0. How to use this brief

This brief states what must be achieved and which constraints are non-negotiable. Its companion file, `PROJECT_CONTEXT.md`, records facts about the current codebase: inventory, numerical conventions, preliminary audit findings, open questions, and status. Read both before acting. The audit sections of `PROJECT_CONTEXT.md` come from a static read of the code, so treat them as hypotheses to verify rather than established facts.

Requirement keywords:

- MUST / MUST NOT: hard requirements.
- SHOULD / SHOULD NOT: strong defaults; deviate only with a recorded reason in `dev/DECISIONS.md`.
- MAY: optional.

When principles conflict, resolve them in this order:

1. Preserve validated statistical behavior.
2. Keep every result auditable: reproducible, traceable to a formula, explainable.
3. Correctness and safety: no crashes, silent failures, or undefined behavior.
4. Clarity, maintainability, and extensibility.
5. Performance and memory efficiency.
6. API aesthetics and stylistic preference.

Work proceeds in phases separated by review gates (Section 4). At every gate, STOP and wait for explicit approval from the project lead.

---

## 1. Role, objective, and principles

Act as a senior R statistical-software architect, computational statistician, and modern C++ developer.

Rewrite the entire `pprof` package (R code, C++ code, package structure, naming, tests, and documentation) into a clean, modern, maintainable, and extensible foundation for current and future statistical modeling work from the Kevin He group.

This is a software-architecture rewrite, not a statistical-methodology rewrite. The current implementation is the reference specification for statistical behavior. Its architecture, naming, style, and internal algorithms are not.

Guiding principles:

- Simple architecture over fashionable architecture; explicit mathematics over clever abstraction.
- Clear names over historical abbreviations; consistency over local convenience.
- Reusable infrastructure over duplicated model-specific code; composition over inheritance.
- S3 over heavier object systems; thin Rcpp interfaces over R-specific C++ everywhere.
- Small numerical functions over giant solvers.
- Tidy-compatible outputs over tidyverse-dependent computation.
- Measurement over assumptions about where C++ is needed.
- Validated numerical equivalence over subjective "improvements."
- An architecture that makes the fifth new model easy to add, not merely the second.

---

## 2. Scope

### 2.1 In scope

The current surface (verify against the inventory in `PROJECT_CONTEXT.md` during Phase 0):

- Model fitting: `logis_fe` (SerBIN and BAN algorithms), `logis_firth`, `logis_re`, `logis_cre`, `linear_fe`, `linear_re`, `linear_cre`.
- Post-estimation: `summary`, `confint`, `test`, and `SM_output` methods for each model class; funnel `plot` methods for the fixed-effect models; `caterpillar_plot`; `bar_plot`; `data_check`.
- C++ routines in `src/`: SerBIN/BAN fitting, Firth fitting, variance computation, the standard score test, and direct-standardization expectations.
- Bundled datasets, tests, vignettes, the pkgdown site, and CI configuration.

### 2.2 Non-goals

- MUST NOT implement new statistical methods. Group Lasso, survival models, and other future methods are design targets for the extension architecture only (Section 5.3).
- MUST NOT reimplement mixed-model estimation. Random-effect and correlated-random-effect models MUST keep delegating estimation to `lme4` with equivalent calls (formula structure, family, REML/Laplace defaults, `...` pass-through).
- MUST NOT change estimands, defaults, inference procedures, or numerical conventions without sign-off (Section 3.3).
- MUST NOT add observation weights, offsets, or strata. The reference supports none of them; the data layer SHOULD NOT preclude adding them later.
- MUST NOT build the package around tidymodels (`parsnip`, `recipes`, `workflows`, `tune`) or use R6 for the model system.
- SHOULD NOT pursue performance work whose results differ from the reference beyond the tolerance policy (Section 3.4).
- A CRAN release is not part of this work unless requested, but the result MUST be CRAN-ready.

---

## 3. The equivalence contract

### 3.1 The reference oracle

- The reference is one pinned version: `pprof` 1.0.3 as published on CRAN, believed to correspond to GitHub `main` at commit `5260838`. Phase 0 MUST confirm this by diffing `R/` and `src/` against the CRAN source tarball and record the result in `PROJECT_CONTEXT.md`.
- Reference outputs MUST be captured as frozen fixtures produced by a committed generator script that runs the pinned reference in an isolated library and a separate R session. The old and new code share the package name `pprof`, and the old code will eventually be deleted, so tests MUST NOT need the old package at run time.
- Each fixture set MUST carry a manifest recording the reference commit; the R version; versions of `lme4`, `Matrix`, `RcppArmadillo`, `poibin`, and any other numerically relevant package; BLAS/LAPACK; OS and compiler; thread count; seeds; and the exact calls used.
- Fixtures MUST be generated with `threads = 1` and explicit seeds.
- Fixtures include important intermediate quantities (observed and expected components, provider sizes and event counts, screening indicators, variance components), not only final outputs.
- Regenerating fixtures requires explicit approval and MUST produce a diff report. Fixtures are never edited by hand and never regenerated to make a failing test pass.
- For `lme4`-backed models, the oracle is the pinned `pprof` plus pinned `lme4` and `Matrix` versions. Version sensitivity MUST be documented, not hidden by tolerances.
- Because the new API uses new names, old and new implementations can coexist in the package during migration and SHOULD also be compared live. Frozen fixtures remain the authority.

### 3.2 What must be preserved and what may change

Statistical behavior MUST be preserved, including:

- model definitions, likelihoods, estimating equations, and parameterizations;
- observable results of estimation: point estimates, initial values, update rules, line search, stopping rules and their defaults, iteration limits;
- variance calculations, standard errors, test statistics, p-values, and confidence intervals;
- standardization formulas (indirect and direct; ratio, rate, and difference), observed and expected quantities, population rates and their clipping;
- provider-level tests, flagging rules, and funnel limits;
- data screening and edge cases: which observations and providers are included, the treatment of providers with no events or all events, the provider-effect bound, listwise deletion of missing values;
- design-matrix construction for supported inputs (columns, names, contrasts) and provider ordering;
- default argument values (thread counts excepted; see Section 3.5);
- numerical conventions such as clamping thresholds, floors, and line-search constants (see the conventions register in `PROJECT_CONTEXT.md`);
- semantic differences between model families. Examples: indirect measures from random-effect models use summed fitted probabilities as the numerator, whereas fixed-effect models use observed counts; linear models report differences rather than ratios; the available `null` options differ by family. The shared profiling layer MUST parameterize these differences rather than homogenize them.

Presentation MAY change, with documentation:

- function, argument, and class names;
- container types and shapes (for example, tibbles instead of matrices with dimnames), column names, and row order, provided results are keyed by provider ID;
- wording of messages and warnings, and print formatting;
- internal object structure.

Before rewriting any public function, Phase 0 MUST produce a behavior specification for it: inputs and defaults, outputs, edge cases, the numerical conventions it relies on, and known discrepancies.

### 3.3 Discrepancy protocol

The preliminary audit has already found defects in the reference (`PROJECT_CONTEXT.md`, Section 6). "Preserve validated behavior" therefore cannot mean "replicate every defect," and "fix a defect" MUST NOT mean "silently change results."

- Every behavioral difference between reference and rewrite, whether intended or discovered, MUST be recorded in `dev/DISCREPANCIES.md` with an ID, the component, a description, a minimal reproducible example, affected outputs, statistical impact, options, a recommendation, the decision owner, and status.
- Class A: the reference crashes, errors, returns `NULL`, misaligns results with provider IDs, or behaves nondeterministically. These MAY be fixed, with a regression test and a register entry.
- Class B: any change to a numeric value, flag, inclusion decision, or default. These MUST NOT be made without written sign-off from a methodology owner designated by the project lead. Until sign-off, the rewrite reproduces the reference behavior.
- Class C: documentation or messages contradict behavior. Fix the documentation or message to match the behavior and record the entry.
- A discrepancy MUST NEVER be resolved by loosening a tolerance, editing a fixture, or dropping a case from the reference suite.

### 3.4 Tolerance policy

Tolerances MUST be derived from the algorithm, recorded in one place (for example `tests/testthat/helper-tolerances.R`) with a one-line justification each, and changed only with sign-off. Use combined criteria of the form |a − b| ≤ atol + rtol·|b| so that quantities near zero are handled sensibly.

- Tier 0, exact: discrete outputs such as included observations and providers, provider sizes and event counts, screening indicators, ordering, dimensions, and flags (subject to the boundary rule below).
- Tier 1, closed-form computations given identical inputs (expected counts, O/E ratios, Wald statistics given estimates and standard errors): rtol around 1e-10 unless justified otherwise.
- Tier 2, iterative estimates. The preferred strategy is to reproduce the reference iteration path (same initialization, update formulas, line search, clamping, and stopping rule), so that outputs match at near-machine precision and Tier 1 applies. This matters because the default stopping rule in `logis_fe` (`stop = "or"`) stops as soon as any one of three criteria falls below `tol`, so on large data a default fit can stop before the coefficients have settled to `tol`. Agreement of the converged solution alone is therefore not sufficient. Where the path legitimately differs (summation order, linear solver), quantify divergence both at default settings and at tight convergence (for example `tol = 1e-10` on both implementations) and justify the tolerance from that evidence.
- Tier 3, root-finding outputs such as confidence limits found with `uniroot()` at its default tolerance (about 1.2e-4): either reproduce the same root-finder settings and brackets, or use a tolerance justified by the root-finder tolerance.
- Tier 4, results from external engines (`lme4`): compare under pinned versions, with tolerances justified per quantity.
- Boundary rule for flags: flags MUST match exactly, except for providers whose test statistic or p-value lies within the applicable tolerance of a decision threshold. Such providers MUST be listed in the equivalence report.
- Cross-platform: BLAS/LAPACK and compiler differences are expected. Tolerances MUST be validated on every CI platform, not only the platform that generated the fixtures.

### 3.5 Randomness, parallelism, and determinism

- Functions MUST NOT call `set.seed()` internally or otherwise alter the user's RNG state beyond the draws they need. Stochastic procedures (for example the bootstrap-based exact test) MUST be reproducible with `set.seed()`.
- The rewrite SHOULD preserve the reference order of random draws, so that the same seed reproduces the reference exactly. If an architectural change requires a different draw order, validate distributionally (agreement within Monte Carlo error across many seeds), document it, and obtain sign-off (Class B).
- Results with `threads > 1` MUST agree with `threads = 1` within Tier 1/2 tolerances and MUST be deterministic for a fixed thread count.
- Parallel code MUST NOT call the R API from worker threads and MUST NOT let exceptions escape parallel regions. It SHOULD use a single parallel backend.
- The default is `threads = 1` everywhere. The reference defaults to 2 in `SM_output()` for the logistic models and hard-codes 4 in the random-effect interval code. Thread count is a computational setting, and results must agree across thread counts anyway, so this change is recorded in `dev/DECISIONS.md` rather than treated as Class B. The fixture generator MUST pass `threads = 1` explicitly wherever the reference default differs.
- Examples and tests MUST NOT use more than 2 threads (CRAN policy). Thread counts MUST NOT be hard-coded.

### 3.6 Performance and memory non-regression

- Phase 1 MUST create a benchmark suite (for example with `bench`) on synthetic data spanning realistic scales: numbers of observations, providers, and covariates; skewed provider sizes; rare and common outcomes. Record run time and peak memory for the reference.
- The rewrite MUST NOT be materially slower or more memory-hungry than the reference at default settings. Target: no regression worse than about 10%, with any exception documented.
- Faster algorithms are welcome where they are numerically equivalent within the tolerance policy. Example: replacing explicit dense within-provider centering matrices in the linear fixed-effect model with direct demeaning.

---

## 4. Phases and gates

Each phase is a reviewable pull request on a dedicated branch (for example `rewrite/v2`). At every phase the package MUST build, pass `R CMD check`, and pass all reference tests. The old implementation MUST NOT be deleted until its replacement passes the full reference suite.

| Phase | Deliverables | Gate |
|---|---|---|
| 0. Audit and design | Design document (Section 10): behavior specifications, verified conventions register, initial discrepancy register, naming convention, equivalence test plan, dependency decisions, open questions | STOP for approval |
| 1. Reference capture | Fixture generator, frozen fixtures and manifests, characterization tests passing against the old code, benchmark baseline | STOP |
| 2. Core infrastructure | Data layer (input parsing, validation, provider indexing, screening), conventions as named constants, result types, condition classes, test helpers, and an extension proof using a test-only toy model | STOP |
| 3. First vertical slice | Logistic fixed effects (SerBIN and BAN) end to end: new C++ core with a thin Rcpp adapter, model object, inference, provider profiling, tidy outputs, plots, and a compatibility wrapper, all passing the reference suite | STOP for architecture review |
| 4. Remaining models | Linear fixed effects, Firth, and the random-effect and CRE models through a single `lme4` adapter | STOP |
| 5. Inference and profiling | All tests, confidence intervals, standardized measures, and flags for every family, routed through the shared layers | STOP |
| 6. Visualization | `ggplot2` plotting that consumes standardized result objects | none |
| 7. Documentation | Developer guide, user documentation, vignettes, migration guide | none |
| 8. Hardening | Final compatibility wrappers, dependency reduction, dead-code removal, CRAN readiness, final equivalence and benchmark reports | STOP for final review |

The first model is rewritten as a complete vertical slice, rather than all R code first and all C++ later, so the architecture is validated end to end before it is replicated.

Maintain throughout: `NEWS.md`; `dev/DECISIONS.md` (short records of context, decision, alternatives, consequences); `dev/DISCREPANCIES.md`; and the status section of `PROJECT_CONTEXT.md`.

---

## 5. Architecture requirements

### 5.1 Layers

Use explicit layers with one-directional dependencies:

1. Data layer: input parsing (formula and any other supported interfaces), validation, missing-data handling, design-matrix construction, provider indexing, and screening. It is shared by every model; the reference duplicates this logic in each fitting function.
2. Model layer: estimation per family (linear, logistic, mixed effects, penalized, future), producing model objects.
3. Inference layer: variance, standard errors, tests, confidence intervals, and test inversion.
4. Provider-profiling layer: provider effects, observed and expected outcomes, standardized measures, provider-level tests, flags, and funnel limits. It is written once against the model contract (Section 5.3) and reused across families.
5. Presentation layer: `print`, `summary` printing, `tidy`/`glance`/`augment`, tables, plots, and reports.

A layer MUST NOT reach into the internals of a layer above it. The presentation layer consumes standardized result objects, never model internals.

### 5.2 S3 model objects

- S3 is the object system. Use class vectors such as `c("pprof_logistic_fe", "pprof_model")`, with at most one intermediate class and only where it removes real duplication. Final names are decided in Phase 0.
- Every class gets constructor and validator functions (`new_*()`, `validate_*()`). Check classes with `inherits()`, never `class(x) == ...`.
- Provide standard methods where meaningful: `print`, `summary` (returning a summary object with its own `print` method), `coef`, `vcov`, `confint`, `predict`, `fitted`, `residuals`, `nobs`, `logLik`, `formula`. Provide `tidy`, `glance`, and `augment` through the lightweight `generics` package rather than `broom`.
- Objects MUST be memory-conscious. Retain only what downstream methods need: the call, formula and terms, model specification, dimensions, estimates, variance and information components, a compact provider table (ID, size, events, inclusion and screening indicators), the compact per-observation vectors downstream methods genuinely need (for example the covariate linear predictor, the outcome, and an integer provider index), convergence diagnostics, algorithm settings, and the package version. Large objects (full design matrix, processed data, the full `lme4` fit) are kept only on request, for example `keep_data = TRUE`. For methods that need covariates (covariate-level score and likelihood-ratio tests, the standard provider score test), Phase 0 MUST decide between retaining them and requiring `data` explicitly.
- Convergence diagnostics (iterations, a converged flag, the final criterion, the stopping rule) MUST be added, since the reference returns none. This is additive and does not change estimates.

### 5.3 Extension architecture: the model contract

A new model MUST be addable as a new module (its own files plus registration) without editing unrelated core code. Phase 0 MUST define the model contract precisely, including:

- what a fit function must do: use the data layer, call its estimation engine, and build its object through the shared constructor;
- the small set of generics that the inference and profiling layers rely on (for example provider effects, the covariate linear predictor, expected outcomes under a null, provider-level tests, variance components);
- a capability mechanism through which a model declares which inference methods it supports. Penalized models such as Group Lasso typically lack standard Wald variance, so requesting unsupported inference MUST fail with a clear classed condition, never with wrong numbers.

The design document MUST walk through adding Group Lasso concretely: tuning-parameter paths and selection, coefficient paths (for example `coef(fit, lambda = ...)`), group structure, covariate standardization, what provider profiling means at a selected lambda, which inference is and is not available, and exactly which files would be added. It SHOULD also sketch a survival model, where expected outcomes come from cumulative hazards, to show that the profiling layer does not assume binary or Gaussian outcomes.

Phase 2 MUST include an extension proof: a test-only toy model implemented through the public extension points, demonstrating that no core file needs modification.

Do not force every model into one universal `fit_model()`. Share infrastructure and allow specialized implementations.

### 5.4 Naming

Design one package-wide convention in Phase 0, document it in `dev/NAMING.md`, and apply it everywhere.

- R: snake_case; verbs for functions that act, nouns for objects; S3 classes prefixed `pprof_`; internal helpers unexported and grouped by layer.
- Arguments: one vocabulary table used by every function, with a single name each for the outcome, provider identifier, confidence level, alternative hypothesis, null value, thread count, verbosity, and so on. Equivalent arguments in sibling functions MUST share names, order, and defaults. (The reference orders the same arguments differently in `logis_fe` and `linear_fe`.)
- Abbreviations come only from a documented whitelist of standard terms (candidates: `fe`, `re`, `cre`, `se`, `ci`, `id`). Historical names such as `logis`, `SM`, `Y.char`, `Z.char`, and `ProvID.char` are not carried over.
- Avoid exports so generic that they collide easily (the reference exports `test()`), and avoid argument names that shadow common functions (the reference has an argument named `message`).
- C++: all code in `namespace pprof` with sub-namespaces per module; types in PascalCase; functions and variables in snake_case; named constants; snake_case file names matching their main content. Rcpp-exported functions carry a distinctive prefix and stay internal to the R package.
- Example names elsewhere in this brief are illustrative; the Phase 0 convention is authoritative.

### 5.5 R implementation standards

- Idiomatic modern R: small cohesive functions, explicit data flow, the native pipe `|>` where it helps readability, no deeply nested pipelines, no unnecessary metaprogramming, no hidden side effects.
- The numerical core uses base R objects (vectors, matrices, lists, data frames). No tidy evaluation, `dplyr`, or `tidyr` in numerical code. Tidyverse packages MAY be used in presentation code where they materially help.
- One formula grammar across all families, parsed with `terms()` and model frames rather than regular expressions, supporting transformations, interactions, and factors consistently. Phase 0 decides how the provider identifier is specified (a formula special term or a dedicated argument) and which legacy input formats survive.
- Validate inputs at the API boundary with classed conditions (for example `pprof_error_invalid_input`) so tests can target condition classes rather than message text. Route messages through one helper governed by a single verbosity argument, with no output when verbosity is off.
- No reliance on partial matching of `$` or arguments anywhere; tests run with partial-matching warnings enabled.

### 5.6 R/C++ boundary and C++ standards

- Keep in R: formula processing, model specification, validation, orchestration, result assembly, object construction, high-level inference, plotting, reporting.
- Use C++ only where profiling shows a material gain in time, memory, numerical control, or scalability. Do not keep code in C++ merely because the reference does, and do not move code into C++ without benchmarks.
- Structure: R API, then a thin Rcpp adapter, then the C++ numerical core. The core MUST NOT include Rcpp headers or use Rcpp types, `Rcout`, or `Rcpp::stop`. It takes and returns plain C++ and Armadillo types and explicit result structs that include status and diagnostics. Errors are reported through status values or exceptions caught at the adapter.
- Keep Armadillo, which the reference uses, unless Phase 0 documents a compelling reason; changing linear-algebra libraries changes numerical paths.
- Use C++17, R's default standard since R 4.3. Later standards only with a documented need and CI proof on all CRAN platforms.
- Modern practice: RAII, const-correctness, no global state, no `using namespace` in headers, small functions, and numerical contracts (preconditions, tolerances, clamping) documented in comments.
- Consolidate duplicated numerics. The block information-matrix computation (provider-effect diagonal, cross block, Schur complement) is reimplemented in several places in the reference and MUST become one tested routine shared by fitting, variance, score tests, and Firth.
- Proposed layout, to be adjusted after the audit: `src/core/` (linear-algebra helpers, information blocks, line search, convergence), `src/logistic/`, `src/linear/`, `src/penalized/` (future), with the Rcpp adapter files at the top level of `src/`. Two build constraints shape this. `Rcpp::compileAttributes()` scans only top-level `src/` files for `// [[Rcpp::export]]`, and R compiles subdirectory sources only when they are listed in `OBJECTS` in both `Makevars` and `Makevars.win`. List them explicitly: `$(wildcard ...)` is a GNU make extension and would keep the `GNU make` system requirement that removing RcppParallel otherwise eliminates.

### 5.7 Visualization

- `ggplot2` for all plots. Plot functions return ggplot objects without printing them.
- Plots consume standardized result objects (for example a provider-profile table with provider, size, observed, expected, measure, interval, and flag), never model internals or string-valued attributes. The reference dispatches on attributes such as `"model"` and `"description"`.
- Computation such as exact funnel limits belongs in the profiling layer, not in plotting code.
- Support funnel plots, interval and caterpillar plots, flag-summary bar plots, and volume panels through shared building blocks.

### 5.8 Tidy compatibility

`tidy()`, `glance()`, `augment()`, and tibble outputs are an output convention, not a computational foundation. `pprof` owns its modeling architecture; integration with broom or tidymodels MAY come later as an optional layer that depends on `pprof`, never the reverse.

---

## 6. Testing and validation

The current test suite checks object classes, column names, agreement between input formats, and error messages. It contains no numerical reference values, so the characterization suite built in Phase 1 becomes the executable specification.

Required test layers:

- A. Characterization tests: every public function and S3 method of every model, across an argument grid (algorithms, stopping rules, standardization by measure, test types by alternative, `parm` subsets, `null` options, confidence levels), on the bundled datasets and a synthetic edge-case suite, compared with fixtures under Section 3.4.
- B. Numerical unit tests: log-likelihood, score, and information against finite differences; block-inverse and Schur-complement results against dense inverses on small problems; the Poisson-binomial distribution against brute-force convolution; standardization formulas against hand calculation; AUC against the Mann–Whitney statistic.
- C. C++ tests, through internal adapters or C++ unit tests: convergence, singular and near-singular information, providers with one observation, providers with all or no events, rare outcomes, a single provider, p ≥ n, non-finite inputs, large inputs, multithread consistency. Sanitizer (ASan/UBSan) runs SHOULD be part of CI.
- D. Integration tests: the R to Rcpp to C++ path, error propagation, and user interrupts.
- E. Independent references (in `Suggests`, skipped when unavailable): `glm()` with provider indicators for the logistic fixed-effect model on data without extreme providers; `lm()` with provider indicators for the linear fixed-effect model; `logistf` with provider indicators for Firth on small data; direct `lme4` calls for random-effect models; analytical or simulated cases with known answers; independent Python implementations where methodology overlaps. Agreement with the old `pprof` alone does not prove correctness.
- F. Metamorphic tests: invariance to row order and to provider relabeling, predictable effects of affine covariate transformations, and agreement across equivalent input interfaces.
- G. Regression tests: one per entry in the discrepancy register and one per future bug.
- H. Synthetic edge-case suite: providers just below, at, and above the screening cutoff; all-event and no-event providers; separation; collinear and constant covariates; factor covariates with unused levels or level names containing spaces; transformed and interaction terms; character, numeric, and factor provider IDs; missing values; highly unequal provider sizes; very rare and very common outcomes.

Fixtures are stored as RDS (full double precision) with a JSON manifest. Keep the fixtures shipped to CRAN small; larger validation suites live outside the build (for example in a build-ignored `validation/` directory) and run in a dedicated CI job. Target at least 90% line coverage for R code, and measure C++ coverage.

---

## 7. Dependencies

For each current dependency, the design document records why it is used, whether it is needed, whether it belongs in the core, base-R alternatives, license implications, and the decision. Rules:

- Minimize `Imports`. A package used for a single small function SHOULD be replaced by internal code, but only after an equivalence test proves identical results.
- Keep packages that carry validated numerics (`lme4`, and `poibin` unless an equivalence-tested replacement exists) and core infrastructure (`Rcpp`, `RcppArmadillo`, `ggplot2`).
- Independent-reference packages belong in `Suggests`.
- Weigh transitive cost: some candidates for removal arrive with `ggplot2` or `lme4` anyway, while others bring large dependency trees of their own.
- Do not add dependencies because they are fashionable. Preliminary per-package findings are in `PROJECT_CONTEXT.md`.

---

## 8. Backward compatibility and migration

- Design the new API first, then decide which compatibility wrappers to keep.
- Wrappers for old exported names live only in dedicated files, contain translation logic only, return the old output shapes so existing scripts keep working, emit a deprecation warning once per session, remain for at least one minor release, and are tested against the fixtures.
- For each breaking change, document the old interface, new interface, migration path, and whether a wrapper remains, in a migration table and a user-facing migration vignette.
- Compatibility concerns MUST NOT leak into the new internal architecture.
- The rewrite is a major version (for example 2.0.0).

---

## 9. Engineering standards

- `R CMD check --as-cran` with 0 errors, 0 warnings, and 0 notes (any remaining note justified) on Linux, macOS, and Windows for R release, devel, and oldrel.
- CI: check matrix, coverage, a reference-equivalence job, a sanitizer job, and a manual or nightly benchmark job. Keep CRAN check time low; heavy tests use `skip_on_cran()`.
- Style: tidyverse style guide enforced with `lintr`; `clang-format` for C++.
- Documentation: roxygen2 with markdown, a pkgdown site, and vignettes built from source and checked (the reference excludes its vignettes from the package build).
- Repository hygiene: remove dead and commented-out code after extracting anything useful as a test reference, remove leftover files copied from other packages and OS metadata files, and decide whether generated site output belongs in the repository.

---

## 10. Phase 0 deliverable: the design document

Inspect the complete repository first: the R and C++ source trees, `DESCRIPTION`, `NAMESPACE`, tests, vignettes, documentation, examples, configuration files, CI workflows, generated documentation, datasets, and all dependencies. Then write `dev/design/ARCHITECTURE.md` with companion files as named below. Contents:

- A. Current-state assessment: what is good and should be kept; what is duplicated or poorly organized; inconsistent naming; where R and C++ responsibilities are mixed; where statistical logic is mixed with data manipulation; unnecessarily complex C++; genuinely performance-critical code (measured); unnecessary dependencies; the public behavior that matters; components that can become reusable infrastructure.
- B. Proposed architecture: R and C++ module structure, layer responsibilities, dependency rules.
- C. Naming convention (`dev/NAMING.md`): functions, arguments (with the vocabulary table), classes, internal helpers, C++ functions, types and namespaces, files.
- D. Model-object design: components, what is retained and why (with a memory budget), and how standard and pprof-specific methods work.
- E. Extension architecture: the model contract, the capability mechanism, the Group Lasso walk-through, and the survival sketch.
- F. R/C++ boundary: responsibilities and their justification, with benchmark evidence.
- G. Validation strategy: fixture generation, equivalence test plan, tolerance table with justifications, independent references.
- H. Dependency strategy: per-package decisions.
- I. Migration strategy: the old-to-new mapping, wrappers, and deprecation timeline.
- J. Behavior specifications for every public function.
- K. The verified numerical conventions register.
- L. The initial discrepancy register (`dev/DISCREPANCIES.md`).
- M. Open questions for the methodology owners.

The design must be internally coherent before any large-scale rewriting begins. STOP after Phase 0.

---

## 11. Questions to raise rather than assume

Ask the methodology owners at least the following:

1. Which components are considered validated, and by what evidence (papers, simulations, internal checks)? Recently added components such as the CRE models and the Firth correction may differ in validation status from the core fixed- and random-effect models.
2. Should the Firth model keep returning a `logis_fe`-class object whose variance, log-likelihood, AIC, and BIC are the unpenalized versions?
3. In the CRE models, provider means are computed before complete-case filtering. Is that intended?
4. Which legacy input interfaces (formula; data plus column names; separate vectors and matrices) must survive?
5. What are the minimum supported R version, the target release timeline, and the deprecation window for old names?

For every other ambiguity, record it in the design document with a proposed default; do not decide silently.

---

## 12. Success criteria

The rewrite is complete only when all of the following hold:

1. All reference fixtures pass under the tolerance policy on every CI platform, and every deviation has a register entry with a decision.
2. Statistical behavior is unchanged except for signed-off Class B decisions.
3. The R code is substantially cleaner and more idiomatic, and naming is consistent, descriptive, and documented.
4. The C++ core is modern, modular, readable, free of Rcpp types outside the adapter layer, and safe under multithreading.
5. A clear S3 architecture exists, with memory-conscious objects and convergence diagnostics.
6. Tidy-compatible outputs exist without tidyverse-dependent computation; `ggplot2` is used for plots; the core has no tidymodels dependency.
7. The extension proof passes, and the Group Lasso walk-through shows that Group Lasso and future group methods can be added as independent modules without redesigning the core.
8. There are no unexplained performance or memory regressions against the benchmark baseline.
9. `R CMD check --as-cran` is clean on all platforms, and R line coverage is at least 90%.
10. Dependencies are reduced to a documented, defensible set.
11. Another statistician or programmer can add a model by following the developer guide, without reverse-engineering the package.

---

## Closing instruction

Do not confuse a software rewrite with a statistical rewrite. The existing methodology and implementation have been validated: preserve that behavior while replacing the architecture, naming, R implementation, C++ implementation, testing structure, and documentation. When choosing between a prettier implementation and one that makes statistical behavior easier to validate and audit, choose the latter.
