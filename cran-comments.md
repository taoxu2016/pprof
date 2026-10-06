## Submission

pprof 2.0.0 is a major release: a rewrite of the package's architecture that preserves the
statistical behavior of pprof 1.0.3. The functions of 1.0.3 remain and give the same results;
they are deprecated and warn once per session, naming their replacements. NEWS.md lists every
change.

Whether and when to submit is the package owners' decision; this file records the state of
the release candidate.

## Test environments

- Local: Windows 11 x64, R 4.4.0 (ucrt), Rtools44 (GCC 13.3).
- GitHub Actions (`.github/workflows/rewrite-check.yaml`): Ubuntu 24.04, macOS (arm64), and
  Windows Server 2022, each with R release, devel, and oldrel-1; and R 4.4.0, the oldest
  version DESCRIPTION declares, on Windows and Linux.

The results on GitHub Actions are recorded at the final review of the rewrite
(`dev/design/FINAL_REVIEW.md`, not part of the package).

## R CMD check results

Local, `R CMD check --as-cran`: see the final review for the results of the release
candidate.

Notes that may remain:

- The package's website, https://um-kevinhe.github.io/pprof/, is given in DESCRIPTION but is
  not yet published (404). Publishing it is part of the release; the site is built by the
  package's continuous integration.

## Reverse dependencies

There are no reverse dependencies on CRAN (checked 2026-10-05).
