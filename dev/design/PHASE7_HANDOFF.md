# Phase 7 handoff: documentation

Written at the end of Phase 6 (2026-10-04) for the session that plans Phase 7. This is not the plan. The first deliverable of Phase 7 is `dev/design/PHASE7_PLAN.md`, for the project lead's approval, written in the format of `PHASE6_PLAN.md`. The facts below describe the repository at `8aa85cc` (the approved Phase 6); confirm anything by running code before relying on it (CLAUDE.md).

## 1. Scope

- Brief §4: "Developer guide, user documentation, vignettes, migration guide." The brief gives Phase 7 no gate.
- Brief §8: for each breaking change, the old interface, the new interface, the migration path, and whether a wrapper remains, in a migration table and a user-facing migration vignette.
- Brief §9: roxygen2 with markdown, a pkgdown site, and vignettes built from source and checked (the reference excludes its vignettes from the build); decide whether generated site output belongs in the repository.
- Brief §12: success criterion 11, "another statistician or programmer can add a model by following the developer guide, without reverse-engineering the package", and criterion 7, "the extension proof passes, and the Group Lasso walk-through shows that Group Lasso and future group methods can be added as independent modules".
- Assigned to Phase 7 by earlier decisions and entries:
  - ARCHITECTURE §I.4: the migration guide, a vignette with the table of §I.1, worked before-and-after examples for each workflow (fit, test, standardize, intervals, plots), the list of Class A behavior changes (errors that became results), the new argument vocabulary, and the default thread count (DEC-001). DEC-008 (quiet by default) and DEC-011 (`confint()` means covariate intervals) are to be listed there too.
  - D-37 (Class C): the five vignettes contradict the code; replace them, written for the new API, and build and check them with the package.
  - D-35 (Class C): the help of `ExampleDataBinary` says 7,994 observations; the data have 7,944.
  - NAMING §3.1: the model-contract generics are "documented in the developer guide".
  - M-20 (methodology owners): whether the help or the vignettes describe the operating characteristics of the RE and CRE tests and intervals that the simulation study found (`validation/simulation-report.md`); the default preserves the procedures and adds no statement until the owners answer.
- Scoping questions for the plan:
  - The gate. Phase 6 recommended and ended with a stop although the brief requires none. For Phase 7 the argument is similar (the vignettes join the package build, which changes `R CMD check`, and the user-facing text is the owners' to approve); the project lead decides.
  - Where the developer guide lives: a vignette shipped with the package (and a pkgdown article), a document in `dev/`, or both (a vignette for people adding a model, built on the toy model of the extension proof and the Group Lasso walk-through of ARCHITECTURE §E.5; `dev/` for contributors to the package itself).
  - Which vignettes are built and checked with the package and which are pkgdown articles only: vignettes run their code in `R CMD check` (CRAN's time budget; the logistic RE and CRE fits of the example data take about 4 to 5 s each, already in the slow-examples note); heavy material can be `vignettes/articles/`, which pkgdown builds and the package build ignores.
  - The pkgdown site: `_pkgdown.yml`'s reference index lists only the old functions, so the new API has no place in it; `docs/` is committed generated output for `https://um-kevinhe.github.io/pprof/`, the upstream's site, which the fork cannot publish to; brief §9 asks whether generated output belongs in the repository. Options: regenerate `docs/` in Phase 7, or build the site in CI and remove `docs/` (repository hygiene, Phase 8), or leave publishing to the owners and only make the site build cleanly.
  - The README (GitHub and CRAN landing page): written for the old API.
  - The version number (2.0.0, brief §8) and the shape of NEWS for a release: likely Phase 8 (CRAN readiness).
  - `R/Data.R` (the reference's data documentation, on the architecture test's legacy list): fix D-35 in place, or move the documentation to a file named by NAMING §8.

## 2. What exists to build on

- The new API (exported): the fits `fit_logistic_fe()`, `fit_logistic_firth()`, `fit_linear_fe()`, `fit_linear_re()`, `fit_logistic_re()`, `fit_linear_cre()`, `fit_logistic_cre()`; profiling `provider_effects()`, `test_providers()`, `standardize_providers()`, `profile_providers()`, `funnel_limits()`; `test_coefficients()`; plots `plot_funnel()`, `plot_caterpillar()`, `plot_flags()`, `plot_volume()`; standard methods of `pprof_model` objects (`print`, `summary`, `coef`, `vcov`, `confint`, `predict`, `fitted`, `residuals`, `nobs`, `logLik`, `formula`) and `tidy()`, `glance()`, `augment()` (re-exported from generics); the developer interface `data_prepare()`, `new_pprof_model()`, `validate_pprof_model()`, and the model-contract generics (`provider_table()`, `provider_index()`, `linear_predictor()`, `observed_outcome()`, `expected_outcome()`, `predicted_outcome()`, `null_effect()`, `profile_spec()`, `inference_capabilities()`, `provider_estimates()`, `provider_estimate_se()`, `provider_test()`, `refit_without()`), documented for developers in `?data_prepare`, `?new_pprof_model`, and `?model_contract` (NEWS).
- The old API (exported, all wrappers over the new code except `data_check()`): `logis_fe()`, `logis_firth()`, `linear_fe()`, `linear_re()`, `logis_re()`, `linear_cre()`, `logis_cre()`, the generics `test()` and `SM_output()`, the `test`, `SM_output`, `confint`, `summary`, `print`, and `plot` methods of their objects, `caterpillar_plot()`, `bar_plot()`, `data_check()`. Their help says they are the interface of pprof 1.0.3 kept for existing code (check each one points to its replacement).
- Help: 66 pages in `man/`, roxygen2 markdown, examples on the bundled data.
- Vignettes (`vignettes/`, excluded from the build by `.Rbuildignore`; published on the pkgdown site only): `pprof.Rmd` ("Getting Started with pprof"), `Quick-start.Rmd`, `Risk-adjustment_Model.Rmd`, `Logis-FE.Rmd`, `Linear-FE.Rmd` (513 lines in all), written for the old API, with the contradictions of D-37. `DESCRIPTION` has knitr and rmarkdown in Suggests and no `VignetteBuilder`.
- pkgdown: `_pkgdown.yml` (Bootstrap 5; the "Getting Started" vignette; an "Appendix" menu with three articles; a reference index of the old functions only); `docs/` committed. pkgdown 2.2.1, knitr 1.52, and rmarkdown 2.32 are installed; **pandoc is not** (`rmarkdown::pandoc_available()` is FALSE), so vignettes and the site cannot be built here until it is installed, and `R CMD check` notes that README.md and NEWS.md cannot be checked without it.
- README.md: the old API; installation from GitHub; `.github/CONTRIBUTING.md`.
- Sources for the documentation: ARCHITECTURE §B (layers), §D (model objects and methods), §E (the model contract, capabilities, registration, the extension proof, the Group Lasso walk-through, a survival sketch), §I (the migration table, how the wrappers work, the timeline); NAMING §4 (argument vocabulary, including the plot arguments of Phase 6) and §5 (classes, result fields); BEHAVIOR_SPECS (what the old functions do); PROJECT_CONTEXT §5.7 (the conventions, K-IDs); the register (the Class A fixes, for the migration guide's list of behavior changes; the Class B items awaiting sign-off, which the documentation must describe as they are); NEWS (the development changes so far, written for users).
- The extension proof (`tests/testthat/test-extension-toy-model.R`, `helper-toy-model.R`): a toy model plugged in through the contract, with its profiling and plots; the natural worked example of a developer guide.
- Data: `ExampleDataBinary`, `ExampleDataLinear`, `ecls_data` (`R/Data.R`).

## 3. What Phase 7 replaces

| Item | Notes |
|---|---|
| `vignettes/*.Rmd` (5) | old API; D-37; excluded from the build |
| `README.md` | old API |
| `_pkgdown.yml` | reference index of the old functions only; articles menu |
| `R/Data.R` | D-35; legacy file of the architecture test |
| `docs/` | generated site; regenerate, move to CI, or leave (scoping question) |

New: the migration guide (vignette, ARCHITECTURE §I.4) and the developer guide (scoping question).

## 4. Conventions, register entries, and questions in play

- The documentation states what the code does, including the Class B behaviors awaiting sign-off (D-10, D-24, D-31, D-32, D-34, D-43), which the help of the affected functions already states; new text must not describe a proposed change as current behavior. A statement that contradicts the code is a Class C entry.
- Examples and built vignettes run fast and use at most 2 threads; they use the new API, except where they show a wrapper.
- Register entries: D-35 and D-37 (open, Class C, Phase 7); D-17 (`data_check()`, Phase 8 with `check_data()`); D-26 and M-7 (the "standard" score test, already described in the help); D-36 (`geom_errorbarh()` and its message, Phase 8); D-47 to D-49 (Phase 6, documented in the help and NEWS).
- Questions for the methodology owners: M-20 (above); M-7, M-8, M-9, M-10, M-11, M-14, M-16 to M-19 stay open with defaults that preserve the reference. Documentation may describe them as open but decides none.
- Decisions to cite: DEC-001, DEC-008, DEC-011, DEC-012, DEC-033 (deprecation warnings from Phase 8, so the migration guide should say when they start), DEC-036, DEC-046 to DEC-049, DEC-055 to DEC-059.

## 5. Carried over from Phase 6 (approved at its gate, 2026-10-04)

- For Phase 8: building the model once in `plot.logis_fe()` (it rebuilds it twice, about 0.04 s on 1e5 observations; DEC-039); the minimum ggplot2 version, which the plot fixtures need at 4.x, and replacing `geom_errorbarh()` (D-36); `data_check()` and `check_data()` with the removal of caret, olsrr, and globals (DEC-054); the once-per-session deprecation warnings (DEC-033); DEC-044's investigation of the 50-covariate `logis_fe()` peak.
- `rewrite/phase-6` was pushed to the fork at `8aa85cc` after the gate; its pull request goes into `rewrite/phase-5`, until the earlier phases are merged into `rewrite/v2`. `rewrite/phase-7` is not pushed.
- One-off scripts of Phase 6 (`dev/design/phase6-facts/`): the plot guard (`08_plot_guard.R`) and the renders (`07_render_new_plots.R`), which a vignette author can reuse to look at the plots.

## 6. Lessons from Phase 6

- ggplot2 4 objects: theme elements carry their S7 class, an environment that `identical()` compares by address, so a theme read back from a file never equals a new one, and `serialize()` writes about 2 MB per theme; compare checksums. `get_guide_data()` accepts a built plot, which avoids building it again.
- `git rm` stages a deletion that the next `git commit` takes along, even when only another path was added; commit with explicit paths and check `git show --stat` before moving on (a commit had to be redone locally in Phase 6).
- On this machine: Bash heredocs mangle backslashes in R code (write such scripts with the Write tool); `bench::mark()` on a function argument times a cached promise (pass a function); the Rtools `usr/bin` tools fail (`add_item ... failed`) when they come first in PATH, so put `/usr/bin` before them; R writes text with CRLF.
- Memory: 7.4 GB; a script that holds two sets of 687 built plots thrashed. Durations vary through the day: `R CMD check` with tests took 8.9 min at the Phase 5 gate and 22.9 min at the Phase 6 gate.
- Rough durations: `devtools::test()` 5 min; `R CMD check` with tests 9 to 23 min; coverage 6 min; `validation/run-reference.R` 2 min; `validation/run-differential.R` 7 min; fixture generation 2 min per set; a full benchmark run 30 min, the paired re-measurement with the `logis_re` fit 40 min.
- Write documents for their readers: user documentation in plain terms with runnable examples; the developer guide for someone who knows R and statistics but not this package.

## 7. Suggested start for the planning session

1. Follow "Starting a session" in CLAUDE.md on `rewrite/phase-7`.
2. Read the brief's Phase 7 row, §3.2, §8, §9, and §12; this file; ARCHITECTURE §B, §D, §E, and §I; NAMING §3 to §5; DEC-001, DEC-008, DEC-011, DEC-033, DEC-036; the register entries D-35 and D-37 and the Class A entries (for the migration guide); PROJECT_CONTEXT §9 (M-20).
3. Gather the plan's facts by running code: whether pandoc can be installed (ask before installing software), how long the candidate vignettes take to build and to check, what `pkgdown::check_pkgdown()` reports, which help pages lack examples or links to the new API, and how the old vignettes' code fares on the current package.
4. Write `dev/design/PHASE7_PLAN.md` (goal and scope with a recommendation for each scoping question; steps with files, approach, and checks; what the documentation may change and what it must state as is; facts gathered; risks), propose the decisions it needs from DEC-061 on, and stop for approval.
