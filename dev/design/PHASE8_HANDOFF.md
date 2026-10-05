# Phase 8 handoff: hardening

Written at the end of Phase 7 (2026-10-05) for the session that plans Phase 8. This is not the plan. The first deliverable of Phase 8 is `dev/design/PHASE8_PLAN.md`, for the project lead's approval, written in the format of `PHASE7_PLAN.md`. The facts below describe the repository at `0e3cb3c` (the approved Phase 7); confirm anything by running code before relying on it (CLAUDE.md).

## 1. Scope

- Brief §4: "Final compatibility wrappers, dependency reduction, dead-code removal, CRAN readiness, final equivalence and benchmark reports", with the gate "STOP for final review". It is the last phase: its gate reviews the whole rewrite against the success criteria of brief §12.
- Brief §7 (dependencies: minimize Imports; replace a package used for one small function only after an equivalence test; keep lme4, poibin, Rcpp, RcppArmadillo, ggplot2), §8 (wrappers in dedicated files, translation only, old output shapes, a deprecation warning once per session, kept for at least one minor release, tested against the fixtures; the rewrite is a major version), and §9 (`R CMD check --as-cran` with 0 errors, 0 warnings, and 0 notes, any remaining note justified, on Linux, macOS, and Windows for R release, devel, and oldrel; CI with a check matrix, coverage, a reference-equivalence job, a sanitizer job, and a benchmark job; lintr; clang-format for C++; repository hygiene).
- Brief §12: all eleven success criteria, in particular 1 (every reference fixture passes on every CI platform), 8 (no unexplained performance or memory regression against the baseline), 9 (`R CMD check --as-cran` clean on all platforms; R line coverage at least 90%), and 10 (a documented, defensible set of dependencies).
- Assigned to Phase 8 by earlier decisions and entries:
  - DEC-033: the wrappers call `warn_deprecated()` (defined in `R/conditions.R`, never called yet), once per session, tested on every wrapper. DEC-064: the migration vignette runs old calls, which will then warn; Phase 8 decides how the vignette shows that. ARCHITECTURE §I.3 gives the timeline (2.0.0 warns; at least one more minor release with the wrappers; removal as the owners decide, M-12).
  - DEC-010, DEC-009, DEC-054: `check_data(formula, data, provider)` returning a `pprof_data_check` object (`R/check-data.R`, ARCHITECTURE §B.2), with `data_check()` as a wrapper that keeps the reference behavior (D-17); caret, olsrr, and globals leave Imports, each replaced function (`caret::nearZeroVar()`, `olsrr::ols_vif_tol()`) with an equality test against the original first. With olsrr goes the "Registered S3 method overwritten by 'car'" message at attach (D-36), and with caret the load-order memory transient of DEC-044.
  - DEC-039: build the model once in `plot.logis_fe()` (it rebuilds it twice), and revisit the rebuild cost of the compatibility methods when the wrappers are final.
  - DEC-044: investigate the temporary memory of the logistic FE engine and variance routine (the 50-covariate `logis_fe()` peak).
  - D-36: the minimum ggplot2 version (the plot fixtures need ggplot2 4) and replacing `geom_errorbarh()`, whose ggplot2 4 message the horizontal `caterpillar_plot()` still triggers.
  - D-02, D-25: a check of the help against `formals()`, planned "with the documentation of Phase 8".
  - DEC-015, brief §9: dead code. Left from the reference: `R/data_check.R` and `R/pprof.R` (the `useDynLib` directive and `.fix_unused_globals()`, which exists only to use globals); `R/RcppExports.R` is generated. The architecture test lists the legacy files.
  - DEC-066 (corrected in Phase 7, step 6): no site is served at `https://um-kevinhe.github.io/pprof/` (HTTP 404). pkgdown needs the address in `_pkgdown.yml` and DESCRIPTION, and `R CMD check --as-cran` lists it as a possibly invalid URL. Before a CRAN release, either the owners publish the site there or the address leaves both files.
  - The version (2.0.0, brief §8; DESCRIPTION still says 1.0.3 with Date 2026-02-08) and NEWS's release shape (NEWS has no versioned heading, which `R CMD check` notes).
  - Final reports: `validation/equivalence-report.md` (`run-reference.R`), `validation/differential-report.md` (`run-differential.R`), `validation/simulation-report.md` (`run-simulation.R`), and the benchmarks against the Phase 1 baseline (`dev/bench/results/reference-baseline-20261002-windows.*`; `dev/bench/README.md`, DEC-038 for paired runs).
- Scoping questions for the plan:
  - **CI first (found 2026-10-05, see §2).** The fork's `rewrite-check`, `rewrite-reference`, and `rewrite-coverage` have failed on every push since Phase 2; the gates relied on local checks on Windows with R 4.4.0. Criteria 1 and 9 cannot be met until CI passes. The job logs need a signed-in GitHub account (the project lead can download them; the GitHub CLI is not installed, and installing it is the project lead's decision).
  - Which wrappers stay (brief §8: "decide which compatibility wrappers to keep"); ARCHITECTURE §I.3 keeps all of them through 2.0.0 and at least one minor release.
  - The version number on the branch (2.0.0, or a development number until the owners release) and what "CRAN readiness" covers: the submission itself is the owners' decision.
  - The minimum R version (M-12; `Depends: R (>= 4.1.0)`) and the minimum versions of lme4, Matrix, and ggplot2.
  - The seven slow examples of the old logistic RE and CRE functions (over 5 s; an `R CMD check` note): smaller data, `\donttest{}`, or the new interface in their examples.
  - clang-format (brief §9): the repository has no `.clang-format`; formatting the C++ files changes no number but touches every line of the core.
  - The methodology sign-offs the final review needs (§4).

## 2. State at the end of Phase 7

- Branches on the fork (`origin`, taoxu2016/pprof): `rewrite/phase-1` to `rewrite/phase-7`, each stacked on the previous one; `rewrite/phase-7` at `0e3cb3c`, its pull request into `rewrite/phase-6` opened by the project lead through the compare page; `rewrite/v2` at `56ec1c5`. Nothing has been merged into `rewrite/v2`; nothing touches the upstream (UM-KevinHe/pprof). `rewrite/phase-8` is created from `rewrite/phase-7`, not pushed.
- Local checks at `a5f3c46` (Windows 11, R 4.4.0; PROJECT_CONTEXT §10, Phase 7 step 6): `devtools::test()` 64 files, 1,094 tests, 7,365 expectations, 0 failed, 0 skipped, 0 warnings; `R CMD check --as-cran --no-manual` 0 errors, 1 warning (CRAN incoming: the version, the Date, the site address's 404), 3 notes (the current time cannot be verified; NEWS.md has no news entries; seven old logistic RE/CRE examples over 5 s); coverage 96.29% (rewrite R code 96.09% of 3,198 lines, C++ core 98.86% of 437); reference suite 364 of 364 cases, no boundary providers.
- CI on the fork, from the GitHub API (2026-10-05):

  | Workflow | Result | What is known |
  |---|---|---|
  | `rewrite-check` | failure on every push from `rewrite/phase-2` to `rewrite/phase-6`; running for `rewrite/phase-7` when this was written | at `rewrite/phase-6`: "R CMD check found ERRORs" on all five jobs (Windows, macOS, and Linux release; Linux oldrel-1 and devel); the Linux jobs also report Armadillo's "median(): detected NaN" |
  | `rewrite-reference` | failure on every push | fails in `r-lib/actions/setup-r-dependencies` (R 4.4.0, the lme4 and Matrix of the fixture manifest), before the suite runs |
  | `rewrite-coverage` | failure on every push | the tests fail under covr on Linux (`testthat.Rout.fail`) |
  | `rewrite-pkgdown` | success (first run, `rewrite/phase-7`) | the site is an artifact of the run |
  | `rewrite-sanitizers`, `rewrite-bench` | no run in the fork's history | triggered by pull requests and on demand |

  The annotations also warn that `actions/checkout@v4` and `actions/upload-artifact@v4` target the deprecated Node.js 20, and that `ubuntu-latest` moves to Ubuntu 26 from 2026-10-19. The causes are not known; read the logs before guessing. Plausible leads to test, not conclusions: the check jobs run the full test suite (`NOT_CRAN`) with current lme4, Matrix, and ggplot2 against fixtures made with pinned versions; R 4.5 on CI against 4.4.0 here; the NaN in an Armadillo `median()`.
- Imports: Rcpp, stats, utils, caret, olsrr, poibin, generics, ggplot2, lme4, scales, tibble, globals; LinkingTo Rcpp, RcppArmadillo; Suggests jsonlite, knitr, logistf, pROC, rmarkdown, testthat (>= 3.0.0), withr. PROJECT_CONTEXT §5.10 and ARCHITECTURE §H record the dependency decisions.
- Every function of pprof 1.0.3 except `data_check()` runs on the new code (ARCHITECTURE §I.2); the wrappers do not warn yet.
- Documentation (Phase 7): help pages for the new interface, five vignettes built and checked, the README with its test, the pkgdown configuration and CI build, `dev/DEVELOPER_GUIDE.md`.

## 3. What Phase 8 replaces or finishes

| Item | Notes |
|---|---|
| `R/data_check.R` | `check_data()` (DEC-010) and a wrapper in `R/compat-*.R`; D-17; caret and olsrr out |
| `R/pprof.R` | `useDynLib` and the imports move to `R/pprof-package.R`; `.fix_unused_globals()` and globals go |
| The wrappers | once-per-session deprecation warnings (DEC-033), tests on every wrapper; the migration vignette (DEC-064) |
| `R/compat-plots.R` | one model build in `plot.logis_fe()` (DEC-039); `geom_errorbarh()` (D-36) |
| DESCRIPTION | Version, Date, Imports, minimum versions, URL (DEC-066) |
| `.github/workflows/` | passing CI on every platform; action versions |
| Reports | final equivalence, differential, simulation, and benchmark reports |

## 4. Conventions, register entries, and questions in play

- The non-negotiables of CLAUDE.md hold to the end: no number, flag, inclusion decision, or default changes without a methodology owner's written sign-off (Class B); fixtures are regenerated only with the project lead's approval.
- Class B items awaiting sign-off: D-10, D-24, D-31, D-32, D-34, D-43. The final review needs either the owners' decisions or their explicit agreement that the reference behavior stays; M-16 (who the methodology owners are) is still open.
- Open questions for the methodology owners (PROJECT_CONTEXT §9 and ARCHITECTURE §M; confirm the list there): M-12 (minimum R version, release timeline, deprecation window) bears directly on Phase 8; M-16; M-9, M-17 to M-19; M-20's question whether the RE operating characteristics are intended. The methodology wording of the help and vignettes (`dev/design/PHASE7_WORDING.md`) was approved by the project lead and awaits a methodology owner's review.
- Register entries in scope: D-17, D-36, D-02, D-25 (above), and any entry whose component a Phase 8 step touches. The next new entry is D-52, the next decision DEC-070, the next question M-22.
- Decisions to cite: DEC-001 (threads default 1), DEC-008 (quiet by default), DEC-009, DEC-010, DEC-015, DEC-026 (CI), DEC-031 (lintr), DEC-033, DEC-038 (paired benchmarks), DEC-039, DEC-044, DEC-054, DEC-064, DEC-066.

## 5. Carried over from Phase 7 (approved at its gate, 2026-10-05)

- For Phase 8 (the gate's list): the version and NEWS's release shape; publishing the site or dropping its address; `check_data()` (the migration guide tells users to keep `data_check()` until then); the removal timeline of the old interface (M-12); the seven slow old logistic RE/CRE examples.
- The namespace guard `dev/design/phase7-facts/07_code_unchanged.R` compares the functions, exports, S3 methods, and data of two commits; reusable to show which functions a Phase 8 step changed.
- `rewrite-pkgdown.yaml` removes `CLAUDE.md` before building, because pkgdown renders every Markdown file at the root; a local `build_site()` renders it.

## 6. Lessons from Phase 7

- Check external facts by fetching them: the plan said the upstream served a site that returns 404. Check CI on GitHub at every gate, not only the local checks: CI had failed on every push since Phase 2 without being noticed. The public GitHub API gives run and job results and annotations without signing in (`curl https://api.github.com/repos/taoxu2016/pprof/actions/runs?branch=<branch>`, then `/actions/runs/<id>/jobs` and `/check-runs/<job id>/annotations`); logs need a signed-in account.
- A subagent with no project context was a good test of the developer guide (criterion 11): it found nine gaps that review had missed.
- R scripts that `setwd()` must `force()` path arguments first (lazy evaluation bit the namespace guard). `covr` installs from the source directory and compiles in place, so `src/` holds `.gcda`/`.gcno` files while it runs; it cleans up after.
- On this machine: python is not installed; Bash heredocs mangle backslashes in R code (use the Write tool); commit with explicit paths and check `git show --stat`; R writes CRLF.
- Rough durations (Windows, 8 cores, 7.4 GB): `devtools::test()` 7 min; `R CMD check` with tests and vignettes 14 min; coverage 6 min; `validation/run-reference.R` 2.5 min; the namespace guard 6 min; `pkgdown::build_site()` 4.5 min. Load-all jobs must not run in parallel; `R CMD check` and covr can run alongside one.

## 7. Suggested start for the planning session

1. Follow "Starting a session" in CLAUDE.md on `rewrite/phase-8`.
2. Read the brief's Phase 8 row, §3, §7, §8, §9, and §12; this file; ARCHITECTURE §B.2, §H, and §I; DEC-009, DEC-010, DEC-015, DEC-026, DEC-033, DEC-039, DEC-044, DEC-054, DEC-064, DEC-066; the register entries D-17 and D-36 and the Class B entries; PROJECT_CONTEXT §5.10, §9, and §10 (the Phase 7 entries).
3. Gather the plan's facts by running code and reading CI: the state of the latest CI runs on the fork and, with the logs the project lead provides, the cause of each failure; whether the full test suite passes locally under the CI's package versions; which functions `caret::nearZeroVar()` and `olsrr::ols_vif_tol()` compute for `data_check()`, and how to test a base-R replacement against them; what `R CMD check --as-cran` reports with the version set to 2.0.0; the slow examples' timings; how long the final reports take.
4. Write `dev/design/PHASE8_PLAN.md` (goal and scope with a recommendation for each scoping question; steps with files, approach, and checks; what may change and what must stay; facts gathered; risks), propose the decisions it needs from DEC-070 on, and stop for approval.
