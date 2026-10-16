## Submission

pprof 2.0.0 is a major release: a rewrite of the package's architecture that preserves the
statistical behavior of pprof 1.0.3, and Cox models for time-to-event outcomes. The functions
of 1.0.3 remain and give the same results; they are deprecated and warn once per session,
naming their replacements. NEWS.md lists every change.

The Cox models are fitted by survival, which pprof imports, and the elastic-net Cox model by
glmnet, a suggested package: the functions that need glmnet raise a classed error naming it
when it is not installed, and their tests and examples are skipped without it.

Whether and when to submit is the package owners' decision; this file records the state of
the release candidate.

## Test environments

- Local: Windows 11 x64, R 4.4.0 (ucrt), Rtools44 (GCC 13.3).
- GitHub Actions (`.github/workflows/rewrite-check.yaml`, `R CMD check --as-cran`): Ubuntu
  24.04, macOS (arm64), and Windows Server 2022, each with R release (4.6.1), devel, and
  oldrel-1 (4.5.3); and R 4.4.0, the oldest version DESCRIPTION declares, on Ubuntu and
  Windows.

## R CMD check results

Local, `R CMD check --as-cran`: 0 errors | 0 warnings | 2 notes.

- The package's website, https://um-kevinhe.github.io/pprof/, is given in DESCRIPTION but is
  not yet published (404). Publishing it is part of the release; the site is built by the
  package's continuous integration.
- "unable to verify current time" (the local machine).

GitHub Actions: 0 errors and 0 warnings everywhere; no notes on Ubuntu, macOS, or Windows with
R release, devel, and oldrel-1, or on Windows with R 4.4.0. On Ubuntu with R 4.4.0, three notes:
the installed size (libs 8.6 MB, built there with debug symbols); the suggested packages caret,
glmnet, logistf, olsrr, and pROC, which that job does not install (caret, logistf, olsrr, and
pROC serve tests that compare pprof's results with theirs, glmnet fits the elastic-net Cox
model, and all are skipped without them); and, without glmnet, the help pages' links to it,
which R cannot check.

## Reverse dependencies

There are no reverse dependencies on CRAN (checked 2026-10-16).
