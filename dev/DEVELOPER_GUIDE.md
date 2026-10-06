# Developer guide for contributors to pprof

For people who change pprof itself. To add a model, read the vignette "Adding a model to pprof" first (`vignettes/adding-a-model.Rmd`, `vignette("adding-a-model", package = "pprof")`); this page is the map of the repository and of the rules behind it, and links to the documents that hold the details rather than repeating them.

## The rule that comes first

pprof 2.0 is a rewrite of pprof 1.0.3 that preserves its statistical behavior exactly. The reference is pprof 1.0.3, commit `5260838`, and its results are the specification: estimates and iteration paths, variances, tests, p-values, intervals, standardized measures, flags, screening, provider order, and defaults. Every difference from it, intended or found, is recorded in `dev/DISCREPANCIES.md` with a class:

- A: pprof 1.0.3 crashed, returned `NULL`, misaligned results, or was nondeterministic. May be fixed, with a regression test.
- B: any change to a number, flag, inclusion decision, or default. Not made without written sign-off by a methodology owner; until then the code reproduces pprof 1.0.3.
- C: documentation or messages contradict behavior. The documentation is fixed.

A discrepancy is never resolved by loosening a tolerance, editing a fixture, or dropping a test case. The engineering brief (`dev/pprof_rewrite_brief.md`) states these rules in full (§3 for equivalence); `dev/DECISIONS.md` records the decisions made under them.

## Where things are

| What | Where |
|---|---|
| R code, by layer | `R/<layer>-<topic>.R`: shared utilities (`constants.R`, `conditions.R`, `messages.R`, `validate.R`, `results.R`, `pprof-package.R`), `data-*`, `model-*`, `inference-*`, `profile-*`, `present-*` and `plot-*`, and the interface of pprof 1.0.3 in `compat-*`; `dev/design/ARCHITECTURE.md` §B |
| C++ | the core in `src/core/` and `src/logistic/`, free of Rcpp types; the adapter `src/rcpp_logistic.cpp`; every object file listed in `src/Makevars` and `src/Makevars.win`; ARCHITECTURE §B.3 and §F |
| Names | `dev/NAMING.md`: functions, the argument vocabulary, classes and result fields, condition classes, C++ conventions, file names, and the checklist for a new name (§9) |
| Numerical conventions | `dev/PROJECT_CONTEXT.md` §5.7 (IDs `K-xx`), named in `R/constants.R` and `src/core/constants.h` |
| What the old functions do | `dev/design/BEHAVIOR_SPECS.md` |
| Tests | `tests/testthat/`: unit tests `test-<layer>-<topic>.R`, characterization tests against frozen results of pprof 1.0.3 `test-reference-*.R`, independent references, metamorphic tests, the extension proof (`test-extension-toy-model.R`), and the architecture test (`test-architecture.R`, which checks that each file calls only its own and lower layers); helpers `helper-*.R`, among them the named tolerances `helper-tolerances.R` and strict mode `helper-strict.R` |
| Frozen results of pprof 1.0.3 | `tests/testthat/fixtures/reference/` (shipped) and `validation/fixtures/reference/` (full set), made only by the generator in `dev/reference/` from an isolated library of pprof 1.0.3 (`dev/reference/README.md`) |
| Large validations | `validation/`: the full reference suite (`run-reference.R`), differential tests against pprof 1.0.3 (`run-differential.R`), and the simulation study (`run-simulation.R`), with their reports |
| Benchmarks | `dev/bench/` (`README.md`); results in `dev/bench/results/` |
| Status, open questions, history | `dev/PROJECT_CONTEXT.md` (§9 questions for the methodology owners, §10 log) |
| User documentation | help pages from roxygen2 comments (`man/` is generated), the vignettes in `vignettes/`, the README, and the pkgdown site configured in `_pkgdown.yml` |

## Commands

Run from the repository root.

| Task | Command |
|---|---|
| Load and compile | `Rscript -e 'devtools::load_all()'` |
| Regenerate the help and NAMESPACE | `Rscript -e 'devtools::document()'` |
| Regenerate the Rcpp glue after changing an exported C++ function | `Rscript -e 'Rcpp::compileAttributes()'` |
| All tests | `Rscript -e 'devtools::test()'` |
| Tests of some files | `Rscript -e 'devtools::test(filter = "profile")'` |
| Full check | `Rscript -e 'rcmdcheck::rcmdcheck(args = c("--as-cran", "--no-manual"), error_on = "warning")'` |
| Lint | `Rscript -e 'lintr::lint_package()'` |
| Coverage | `Rscript -e 'covr::package_coverage()'` |
| Reference suite, differential tests | `Rscript validation/run-reference.R`, `Rscript validation/run-differential.R` |
| The site | `Rscript -e 'pkgdown::build_site(override = list(destination = "<a folder outside the repository>"))'`; CI builds it on every push to a `rewrite/**` branch. pkgdown renders every Markdown file at the root, so a local build also renders `CLAUDE.md` (CI removes it first) |

Building the vignettes and the site needs pandoc. Examples, tests, and vignettes use at most two threads; package code never calls `set.seed()`.

## Changing code

- Find the layer the change belongs to; a layer calls only its own and lower layers, and the profiling and presentation layers read models only through the model contract and results only through their fields.
- Name things from the vocabulary of `dev/NAMING.md`; sibling functions share argument names, order, and defaults.
- Check arguments at the boundary and raise classed conditions (`pprof_error_*`, `pprof_warning_*`); print nothing unless `verbose = TRUE`.
- Name every numerical constant, with its contract and its reference location.
- Constructors are `new_pprof_<class>()` and validators `validate_pprof_<class>()`; constructors return their object visibly.
- If a change could alter a number, compare with the fixtures and the differential tests before anything else, and record any difference in the register before deciding what to do with it.
- Record user-visible changes in `NEWS.md`.

## Continuous integration

`.github/workflows/`, run on pushes and pull requests to `main` and `rewrite/**` (DEC-071):

- `rewrite-check.yaml`: `R CMD check --as-cran`, failing on warnings, on Linux, macOS, and Windows with R release, devel, and oldrel-1, and with R 4.4.0, the oldest version DESCRIPTION declares (DEC-081), on Linux and on Windows. The Windows R 4.4.0 job is the fixtures' platform: only there do the tests compare numbers with the committed fixtures (DEC-080); elsewhere they compare everything else and skip the numbers.
- `rewrite-reference.yaml`: the reference suite (`validation/run-reference.R`) with the committed fixtures on their platform, and on Linux, macOS, and Windows with fixtures that pprof 1.0.3, built on the runner (`dev/reference/setup_reference_library.R`), regenerates there into a scratch folder; it also reports how far pprof 1.0.3 itself moves on each platform.
- `rewrite-coverage.yaml` (R and C++ coverage, failing below 90% of R lines), `rewrite-lint.yaml` (`lintr::lint_package()`, failing on any lint), `rewrite-pkgdown.yaml` (builds the site and keeps it as an artifact; publishing it is the package owners' decision, and the site is no longer committed in `docs/`), `rewrite-sanitizers.yaml` (the C++ code under sanitizers), and `rewrite-bench.yaml` (benchmarks, on demand).

Every job copies its results into GitHub annotations (`.github/scripts/ci-annotate.R`): the failing sections of the check log, each failing test with the first line of its message, a replay of a failed installation of the dependencies, the reference suite's summary and the fixture differences, and the platform (R, OS, BLAS, LAPACK, compiler). The public GitHub API returns annotations without signing in, which the logs and artifacts need: `Rscript dev/design/phase8-facts/01_ci_runs.R <output file> <run id> ...` reads them. `dev/design/phase8-facts/08_ci_diagnosis.md` records each failure found so far, its cause, and its fix.
