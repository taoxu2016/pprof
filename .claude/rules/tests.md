---
paths:
  - "tests/**"
  - "dev/reference/**"
  - "validation/**"
---

# Testing and equivalence conventions

Source: the rewrite's brief §3 and §6 (in the history, `dev/README.md`); for Cox models, the CoxPH brief (`dev/coxph_brief.md`) §3 and §6. Read those sections when in doubt.

- Fixtures in `tests/testthat/fixtures/reference/` come only from the committed generator in `dev/reference/`. The generator runs the pinned reference (pprof 1.0.3, commit `5260838`) in an isolated library and a separate R session, with `threads = 1` passed explicitly and explicit seeds.
- Cox fixtures, in `tests/testthat/fixtures/cox/`, come only from their committed generator in `dev/reference/`. It runs the second reference, `pprof_py` v0.7.0 (commit `9320766`), in a pinned Python environment, and pinned R packages (`survival`, `glmnet`) in an isolated library. Their manifest records the Python and package versions too. Tests never need Python or `pprof_py` (CoxPH brief §3.1).
- Never edit fixtures by hand. Regenerating them needs my approval and a diff report, and never happens to make a failing test pass.
- Each fixture set has a `manifest.json` that records:
  - the reference commit and the R version;
  - versions of lme4, Matrix, RcppArmadillo, poibin, and other numerically relevant packages;
  - BLAS/LAPACK, OS, and compiler;
  - thread count, seeds, and the exact calls.
- Store fixtures as RDS at full precision. Keep fixtures shipped to CRAN small; put larger suites in `validation/`.
- Tests must never need the old package at run time.
- Compare with |a − b| ≤ atol + rtol·|b|, using the named tolerances in `tests/testthat/helper-tolerances.R`. Each tolerance has a one-line justification and changes only with sign-off. Tiers:
  - 0: exact (inclusion, sizes, event counts, screening indicators, ordering, dimensions, flags).
  - 1: closed-form results, rtol about 1e-10.
  - 2: iterative estimates, matched by reproducing the iteration path. Otherwise, justify the tolerance from divergence measured at default settings and at tight `tol`.
  - 3: `uniroot()` limits.
  - 4: lme4 results under pinned versions.
- Flags match exactly, except for providers within tolerance of a threshold. List those providers in the equivalence report.
- Never fix a discrepancy by loosening a tolerance, editing a fixture, or dropping a case. Every register entry gets a regression test.
- Test conditions by class, for example `expect_error(class = "pprof_error_invalid_input")`, not by message text.
- Test helpers turn on `warnPartialMatchDollar` and `warnPartialMatchArgs`. Treat those warnings as failures.
- Tests that use randomness set their own seeds. Package code never calls `set.seed()`.
- Tests use at most 2 threads.
- Put heavy tests behind `skip_on_cran()`.
- Independent-reference packages (for example logistf) go in Suggests, and their tests skip when the package is absent.
- Cover the test layers in brief §6: characterization, numerical unit, C++, integration, independent references, metamorphic, regression, and synthetic edge cases.
