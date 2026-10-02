<!--
Maintainer notes (HTML comments are stripped before Claude reads this file):
- Keep this file under 200 lines. It holds what every session needs.
- Requirements: dev/pprof_rewrite_brief.md. Facts and status: dev/PROJECT_CONTEXT.md.
- Area-specific conventions live in .claude/rules/ and load only for matching files.
- Status changes go in PROJECT_CONTEXT.md §10, not here. Edit this file only when a rule changes.
-->

# pprof rewrite

`pprof` is an R package for provider profiling from the Kevin He group (University of Michigan). It fits risk-adjusted models with provider effects for units such as hospitals, facilities, transplant centers, and schools: logistic fixed effects in C++ (SerBIN, BAN, Firth), linear fixed effects in R, and random and correlated random effects through lme4. It then computes standardized measures, provider-level tests and flags, confidence intervals, and funnel and caterpillar plots.

We are rewriting the architecture, naming, R code, C++ code, tests, and documentation while preserving statistical behavior exactly. The reference is pprof 1.0.3 from CRAN, believed to be `main` at commit `5260838`. This is a software rewrite, not a statistical one: when a prettier implementation and an easier-to-audit one conflict, choose the auditable one.

## Source documents

| File | Contents | When to read |
|---|---|---|
| `dev/pprof_rewrite_brief.md` | Requirements (MUST/SHOULD), phases and gates, equivalence contract, architecture rules | The sections for the current phase before starting work, and before any design decision |
| `dev/PROJECT_CONTEXT.md` | Inventory, signatures, numerical conventions (§5.7), audit findings (§6), open questions (§9), status log (§10) | §10 at the start of each working session; §5.7 before touching numerical code |
| `dev/DISCREPANCIES.md` | Register of every behavioral difference from the reference | Before changing any output |
| `dev/DECISIONS.md` | Decision records | Before reopening a settled question |
| `dev/NAMING.md` | Naming convention and argument vocabulary (written in Phase 0) | Before naming anything |

The brief is authoritative. If this file, the context file, and the brief disagree, follow the brief and point out the conflict.

## Starting a session

1. Run `git status` and `git log --oneline -10`, then read `dev/PROJECT_CONTEXT.md` §10 to find the current phase.
2. Read the brief's deliverables for that phase (§4, plus §10 for Phase 0).
3. If a request falls outside the current phase, say so and ask before doing it.

## Non-negotiables

- The reference's statistical behavior is the specification: estimates and iteration paths, variances, tests, p-values, intervals, standardization formulas, flags, screening and inclusion, provider ordering, defaults (thread counts excepted), and the conventions in PROJECT_CONTEXT §5.7.
- Every behavioral difference, intended or found, goes in `dev/DISCREPANCIES.md` with a class:
  - A: the reference crashes, errors, returns `NULL`, misaligns results with provider IDs, or is nondeterministic. May be fixed, with a regression test.
  - B: any change to a number, flag, inclusion decision, or default. Don't make it. Reproduce the reference, record the proposal, and flag it for written sign-off by a methodology owner.
  - C: documentation or messages contradict behavior. Fix the documentation or message to match the behavior.
- Never resolve a discrepancy by loosening a tolerance, editing a fixture, or dropping a test case.
- Fixtures under `tests/testthat/fixtures/reference/` come only from the committed generator in `dev/reference/`. Never edit them by hand. Regenerate them only with my explicit approval, and produce a diff report.
- No new statistical methods. Random-effect and CRE models keep delegating estimation to lme4 with equivalent calls.
- Stop at every phase gate: run `/phase-gate`, report, and wait for my explicit approval. Never start the next phase on your own.
- Keep the old implementation until its replacement passes the full reference suite.
- When principles conflict: preserve behavior > auditability > correctness and safety > clarity > performance > aesthetics.

## When unsure

- Don't decide statistical or methodological questions. Record the question with a proposed default (in the design document during Phase 0, otherwise in PROJECT_CONTEXT §9) and ask me.
- Treat PROJECT_CONTEXT §5–6 as hypotheses from a static read. Confirm a finding by running code before relying on it.
- Look up numerical constants in §5.7 or the reference source. Never guess them.
- If you couldn't verify something (no fixture yet, check not run), say so plainly instead of implying it passed.

## How we work

- Plan first for anything that touches numerical code or more than a few files: list the files, the approach, and how equivalence will be checked, then wait for my OK.
- Keep diffs small and focused on the task. No drive-by refactors or renames.
- Report bugs and discrepancies with a minimal reproducible example. Refer to code as `path:line`.
- When you finish a task, list the commands you ran and their results.

## Git

- Work on `rewrite/v2` or short-lived branches off it. One pull request per phase.
- Never commit to `main`, rewrite published history, or delete branches or tags. Commit `5260838` must stay reachable.
- Make small commits with imperative messages scoped by area, for example `logistic-fe: add information-block routine`.
- Ask before pushing, opening pull requests, or tagging.

## Commands

Run from the repository root. R functions run through `Rscript -e`.

| Task | Command |
|---|---|
| Load and compile | `Rscript -e 'devtools::load_all()'` |
| Update roxygen docs and NAMESPACE | `Rscript -e 'devtools::document()'` |
| Update Rcpp exports after changing `// [[Rcpp::export]]` | `Rscript -e 'Rcpp::compileAttributes()'` |
| All tests | `Rscript -e 'devtools::test()'` |
| Tests in matching files | `Rscript -e 'devtools::test(filter = "logis_fe")'` |
| Full check | `Rscript -e 'rcmdcheck::rcmdcheck(args = c("--as-cran", "--no-manual"), error_on = "warning")'` |
| Coverage | `Rscript -e 'covr::package_coverage()'` |
| Lint new code | `Rscript -e 'lintr::lint("R/<file>.R")'` |

When installing packages, pass `repos = "https://cloud.r-project.org"`, because non-interactive R may have no CRAN mirror set.

## Definition of done

- The package builds and loads, `devtools::test()` passes, and `R CMD check` shows no new errors, warnings, or notes.
- From Phase 1 on, the reference suite passes under the tolerances in `tests/testthat/helper-tolerances.R`.
- New differences are in `dev/DISCREPANCIES.md`, decisions in `dev/DECISIONS.md`, and user-visible changes in `NEWS.md`.
- Generated files (`man/`, `NAMESPACE`, `R/RcppExports.R`, `src/RcppExports.cpp`) are regenerated, never edited by hand.

## Equivalence essentials

Full policy: brief §3 and §6. Test conventions load from `.claude/rules/tests.md`.

- Fixtures come from the pinned reference, run in an isolated library and a separate R session with `threads = 1`, explicit seeds, and a JSON manifest.
- Compare with |a − b| ≤ atol + rtol·|b| using named tolerances, each justified in one line:
  - discrete outputs match exactly;
  - closed-form results match to about 1e-10;
  - iterative estimates match by reproducing the reference iteration path;
  - `uniroot()` limits use the reference root-finder settings, or a tolerance justified by them;
  - lme4 results are compared under pinned versions.
- Flags match exactly, except for providers within tolerance of a decision threshold, which go in the equivalence report.
- Package code never calls `set.seed()`. Tests that use randomness set seeds themselves. Tests and examples use at most 2 threads.

## Architecture targets

Details: brief §5. Language conventions load from `.claude/rules/r-code.md` and `.claude/rules/cpp.md`.

- Layers with one-way dependencies: data → model → inference → provider profiling → presentation. All models share the data layer. Profiling is written once against the model contract, and it parameterizes differences between model families rather than homogenizing them.
- S3 objects use classes prefixed `pprof_`, built by `new_*()` and checked by `validate_*()`. Objects stay compact; large data is kept only with `keep_data = TRUE`.
- New models plug in as modules through the model contract and declare their inference capabilities. Unsupported inference fails with a classed condition.
- The numerical core uses base R. Tidy outputs come through `generics`. Plots use ggplot2 and consume only standardized result objects.
- The C++ core is free of Rcpp, lives in `namespace pprof`, and sits behind thin Rcpp adapters. Move code between R and C++ only with benchmark evidence from `dev/bench/`.

## Known traps in the reference

Verify each before relying on it (PROJECT_CONTEXT §5.7 and §6).

- `logis_fe()` defaults to `stop = "or"`, which stops as soon as any one criterion falls below `tol`, so a default fit can stop before the coefficients settle. Match the iteration path, not only the final estimates.
- SerBIN loops `while (iter <= max_iter)` and can run `max_iter + 1` iterations. BAN uses `<`.
- `SM_output()` for the logistic models defaults to `threads = 2`, and logistic RE/CRE `confint()` hard-codes 4. The fixture generator passes `threads = 1` explicitly.
- Firth with `threads > 1` has a data race (D-05). Generate Firth fixtures single-threaded.
- `SM_output.logis_fe()` reads `fit$obs`, which works only through partial matching (D-08).
- Logistic RE and CRE indirect measures divide summed fitted probabilities by expected values (predicted over expected), not observed counts.
- Weight floors differ by routine: 1e-20 in SerBIN, BAN, and the C++ score routine; 1e-10 in Firth. Probabilities are clamped to [1e-10, 1 − 1e-10] in variance and test code.
- The default R toolchain on macOS usually lacks OpenMP, so `threads > 1` runs single-threaded there. Check multithreaded behavior on Linux.

## Repository layout

- `R/`, `src/`, `tests/testthat/`, `man/`, `data/`, `vignettes/`: package sources. Vignettes are currently excluded from the build.
- `docs/`: committed pkgdown output. Don't edit it by hand.
- `dev/`: rewrite documents, plus `design/` (Phase 0), `reference/` (fixture generator), and `bench/` (benchmarks). Build-ignored.
- `tests/testthat/fixtures/reference/` and `validation/`: frozen fixtures and large validation suites, created in Phase 1.
- `.claude/`: Claude Code settings, path-scoped rules, and the `phase-gate` skill.
- Anything outside the standard package layout must be listed in `.Rbuildignore`.

## Keeping documents current

- At each gate, add a dated entry to PROJECT_CONTEXT §10, move verified findings from §6 into `dev/DISCREPANCIES.md`, and record decisions in `dev/DECISIONS.md`.
- After a session with material progress, update the status line at the top of PROJECT_CONTEXT.md and add a dated §10 entry that names the next step.
- Record project decisions and status in the `dev/` documents, not in auto memory, so they're reviewable and shared.
- Edit the brief or this file only with my explicit approval.
