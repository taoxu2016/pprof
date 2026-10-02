# pprof (development version)

- Work has started on pprof 2.0.0, a rewrite of the package's architecture that preserves its statistical behavior. No user-visible changes yet.
- The test suite now checks every exported function and every method except `print()` against frozen results of pprof 1.0.3 (`tests/testthat/fixtures/reference/`). These tests use the new suggested packages jsonlite and withr.
