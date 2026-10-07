<!--
Maintainer notes (HTML comments are stripped before Claude reads this file):
- Keep this file under 200 lines. It holds what every session needs.
- Lasting records are indexed in dev/README.md. Each phase's requirements and status live in its own brief and status document, named under "Current phase".
- Area-specific conventions live in .claude/rules/ and load only for matching files.
- Status changes go in the phase's status document, not here. Edit this file only when a rule changes or a phase starts.
-->

# pprof

`pprof` is an R package for provider profiling from the Kevin He group (University of Michigan). It fits risk-adjusted models with provider effects for units such as hospitals, facilities, transplant centers, and schools: logistic fixed effects in C++ (SerBIN, BAN, Firth), linear fixed effects in R, and random and correlated random effects through lme4. It then computes standardized measures, provider-level tests and flags, confidence intervals, and funnel and caterpillar plots.

Version 2.0.0 is the completed rewrite of pprof 1.0.3 (CRAN, commit `5260838`): a new interface (`fit_*()`, `profile_providers()`, `test_providers()`, `standardize_providers()`, `test_coefficients()`, `check_data()`, and the `plot_*()` functions), with the functions of 1.0.3 kept as deprecated wrappers that reproduce its results. The rewrite's equivalence rules stay in force for every existing model.

## Current phase

Between phases. The next phase adds Cox proportional hazards (CoxPH) models, following the approach taken in `pprof_py`. Its brief, plan, and status document are not written yet; until the project lead approves them, don't start CoxPH work. When they exist, name them here: the brief (requirements and gates) and the status document (dated log of the phase).

## Source documents

| File | Contents | When to read |
|---|---|---|
| `dev/README.md` | Index of `dev/`, and where the rewrite's working documents went | First, in a new session |
| `dev/DISCREPANCIES.md` | Every behavioral difference from pprof 1.0.3, with class and status (`D-xx`) | Before changing any output |
| `dev/DECISIONS.md` | Decision records (`DEC-xxx`) | Before reopening a settled question |
| `dev/CONVENTIONS.md` | Numerical conventions of pprof 1.0.3 that the package reproduces (`K-xx`) | Before touching numerical code |
| `dev/OPEN_QUESTIONS.md` | Questions for the methodology owners (`M-xx`) | Before any methodological change |
| `dev/NAMING.md` | Naming convention and argument vocabulary | Before naming anything |
| `dev/DEVELOPER_GUIDE.md` | How the package is built, tested, and extended | Before adding a model |
| `dev/design/ARCHITECTURE.md`, `dev/design/BEHAVIOR_SPECS.md` | The design as built; what each function of pprof 1.0.3 does | Before changing a layer or an old function |
| `dev/DOMAIN.md` | Glossary and methodological references | When a term is unclear |

Code comments and the registers cite the rewrite's brief (`brief §…`), PROJECT_CONTEXT, and phase documents; they are in the history at commit `5977087` (`dev/README.md`).

## Starting a session

1. Run `git status` and `git log --oneline -10`.
2. Read the current phase's brief and status document (named under "Current phase").
3. If a request falls outside the current phase, say so and ask before doing it.

## Non-negotiables

- The statistical behavior of the existing models is the specification: pprof 1.0.3's, as the reference fixtures freeze it, with the exceptions decided in `dev/DISCREPANCIES.md`. This covers estimates and iteration paths, variances, tests, p-values, intervals, standardization formulas, flags, screening and inclusion, provider ordering, defaults (thread counts excepted), and the conventions in `dev/CONVENTIONS.md`.
- Every behavioral difference in an existing model goes in `dev/DISCREPANCIES.md` with a class:
  - A: the reference crashes, errors, returns `NULL`, misaligns results with provider IDs, or is nondeterministic. May be fixed, with a regression test.
  - B: any change to a number, flag, inclusion decision, or default. Don't make it. Reproduce the reference, record the proposal, and flag it for written sign-off by a methodology owner.
  - C: documentation or messages contradict behavior. Fix the documentation or message to match the behavior.
- Never resolve a discrepancy by loosening a tolerance, editing a fixture, or dropping a test case.
- Fixtures under `tests/testthat/fixtures/reference/` come only from the committed generator in `dev/reference/`. Never edit them by hand. Regenerate them only with my explicit approval, and produce a diff report.
- New models and statistical methods enter only as an approved phase brief specifies them, through the model contract (`dev/DEVELOPER_GUIDE.md`), with the validation the brief names. Random-effect and CRE models keep delegating estimation to lme4.
- Stop at every phase gate: run `/phase-gate`, report, and wait for my explicit approval. Never start the next phase on your own.
- When principles conflict: preserve behavior > auditability > correctness and safety > clarity > performance > aesthetics.

## When unsure

- Don't decide statistical or methodological questions. Record the question with a proposed default in `dev/OPEN_QUESTIONS.md` (or the phase's design document) and ask me.
- Confirm a finding by running code before relying on it.
- Look up numerical constants in `dev/CONVENTIONS.md` or the reference source. Never guess them.
- If you couldn't verify something (no fixture yet, check not run), say so plainly instead of implying it passed.

## How we work

- Plan first for anything that touches numerical code or more than a few files: list the files, the approach, and how equivalence will be checked, then wait for my OK.
- Keep diffs small and focused on the task. No drive-by refactors or renames.
- Report bugs and discrepancies with a minimal reproducible example. Refer to code as `path:line`.
- When you finish a task, list the commands you ran and their results.

## Git

- `main` holds the finished state of each phase. Work on short-lived branches off `main`, one per phase (for example `coxph/phase-0`), and one pull request per phase into `main`.
- Every GitHub action goes to the fork (`origin`, taoxu2016/pprof); never touch the upstream UM-KevinHe/pprof.
- Ask before pushing, merging into `main`, opening pull requests, tagging, or deleting branches.
- Never rewrite published history. Commit `5260838` must stay reachable (it is in `main`'s history).
- Make small commits with imperative messages scoped by area, for example `logistic-fe: add information-block routine`.

## Commands

Run from the repository root. R functions run through `Rscript -e`.

| Task | Command |
|---|---|
| Load and compile | `Rscript -e 'devtools::load_all()'` |
| Update roxygen docs and NAMESPACE | `Rscript -e 'devtools::document()'` |
| Update Rcpp exports after changing `// [[Rcpp::export]]` | `Rscript -e 'Rcpp::compileAttributes()'` |
| All tests | `Rscript -e 'devtools::test()'` |
| Tests in matching files | `Rscript -e 'devtools::test(filter = "logis_fe")'` |
| Reference suite and report | `Rscript validation/run-reference.R` |
| Full check | `Rscript -e 'rcmdcheck::rcmdcheck(args = c("--as-cran", "--no-manual"), error_on = "warning")'` |
| Coverage | `Rscript -e 'covr::package_coverage()'` |
| Lint new code | `Rscript -e 'lintr::lint("R/<file>.R")'` |
| Read the fork's CI without signing in | `Rscript dev/tools/ci_runs.R <output file> <run id> ...` |

When installing packages, pass `repos = "https://cloud.r-project.org"`, because non-interactive R may have no CRAN mirror set.

## Definition of done

- The package builds and loads, `devtools::test()` passes, and `R CMD check` shows no new errors, warnings, or notes.
- The reference suite passes under the tolerances in `tests/testthat/helper-tolerances.R`.
- New differences are in `dev/DISCREPANCIES.md`, decisions in `dev/DECISIONS.md`, and user-visible changes in `NEWS.md`.
- Generated files (`man/`, `NAMESPACE`, `R/RcppExports.R`, `src/RcppExports.cpp`) are regenerated, never edited by hand.

## Equivalence essentials

Test conventions load from `.claude/rules/tests.md`.

- Fixtures come from the pinned reference, run in an isolated library and a separate R session with `threads = 1`, explicit seeds, and a JSON manifest.
- Compare with |a − b| ≤ atol + rtol·|b| using named tolerances, each justified in one line:
  - discrete outputs match exactly;
  - closed-form results match to about 1e-10;
  - iterative estimates match by reproducing the reference iteration path;
  - `uniroot()` limits use the reference root-finder settings, or a tolerance justified by them;
  - lme4 results are compared under pinned versions;
  - the exact test's statistic is compared on its tail probability (DEC-083).
- The fixtures' numbers are compared on the platform that produced them; CI compares other platforms with pprof 1.0.3 run there (DEC-080).
- Flags match exactly, except for providers within tolerance of a decision threshold, which go in the equivalence report.
- Package code never calls `set.seed()`. Tests that use randomness set seeds themselves. Tests and examples use at most 2 threads.

## Architecture

Details: `dev/design/ARCHITECTURE.md` and `dev/DEVELOPER_GUIDE.md`. Language conventions load from `.claude/rules/r-code.md` and `.claude/rules/cpp.md`.

- Layers with one-way dependencies: data → model → inference → provider profiling → presentation. All models share the data layer. Profiling is written once against the model contract, and it parameterizes differences between model families rather than homogenizing them.
- S3 objects use classes prefixed `pprof_`, built by `new_*()` and checked by `validate_*()`. Objects stay compact; large data is kept only with `keep_data = TRUE`.
- New models plug in as modules through the model contract and declare their inference capabilities. Unsupported inference fails with a classed condition.
- The numerical core uses base R. Tidy outputs come through `generics`. Plots use ggplot2 and consume only standardized result objects.
- The C++ core is free of Rcpp, lives in `namespace pprof`, and sits behind thin Rcpp adapters. Move code between R and C++ only with benchmark evidence from `dev/bench/`.

## Known traps in the reference

See `dev/CONVENTIONS.md` and `dev/DISCREPANCIES.md`.

- `logis_fe()` defaults to `stop = "or"`, which stops as soon as any one criterion falls below `tol`, so a default fit can stop before the coefficients settle (D-24); with no covariates it stops after one iteration (D-55). Match the iteration path, not only the final estimates.
- SerBIN loops `while (iter <= max_iter)` and can run `max_iter + 1` iterations. BAN uses `<`.
- `SM_output()` for the logistic models defaults to `threads = 2`, and logistic RE/CRE `confint()` hard-codes 4. The fixture generator passes `threads = 1` explicitly.
- Firth with `threads > 1` has a data race (D-05). Generate Firth fixtures single-threaded.
- Logistic RE and CRE indirect measures divide summed fitted probabilities by expected values (predicted over expected), not observed counts.
- Weight floors differ by routine: 1e-20 in SerBIN, BAN, and the C++ score routine; 1e-10 in Firth. Probabilities are clamped to [1e-10, 1 − 1e-10] in variance and test code.
- pprof 1.0.3's behavior with no covariates depends on the R version (`reformulate()` changed in R 4.5.0; D-30, D-54); the generator emulates R 4.5.0 for the cases marked for it.
- The default R toolchain on macOS usually lacks OpenMP, so `threads > 1` runs single-threaded there. Check multithreaded behavior on Linux.

## Repository layout

- `R/`, `src/`, `tests/testthat/`, `man/`, `data/`, `vignettes/`: package sources.
- `dev/`: developer documents and tools (`dev/README.md`): the registers, the design, the fixture generator (`reference/`), benchmarks (`bench/`), and `tools/`. Build-ignored.
- `tests/testthat/fixtures/reference/` and `validation/`: frozen fixtures, the full reference suite, the differential and simulation studies, and their reports.
- `.claude/`: Claude Code settings, path-scoped rules, and the `phase-gate` skill.
- Anything outside the standard package layout must be listed in `.Rbuildignore`.

## Keeping documents current

- Record decisions in `dev/DECISIONS.md`, differences in `dev/DISCREPANCIES.md`, and methodological questions in `dev/OPEN_QUESTIONS.md`, not in auto memory, so they're reviewable and shared.
- During a phase, keep its status document current: a dated entry after each session with material progress, naming the next step.
- Edit this file only with my explicit approval.
