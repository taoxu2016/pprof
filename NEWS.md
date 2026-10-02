# pprof (development version)

- Work has started on pprof 2.0.0, a rewrite of the package's architecture that preserves its statistical behavior. The functions of pprof 1.0.3 are unchanged.
- The test suite now checks every exported function and every method except `print()` against frozen results of pprof 1.0.3 (`tests/testthat/fixtures/reference/`). These tests use the new suggested packages jsonlite and withr.
- A developer interface for adding models is exported, ahead of the user-facing functions: `data_prepare()` prepares a model's data, `new_pprof_model()` builds the model object, and the model-contract generics (`provider_table()`, `expected_outcome()`, and others) connect a model to the profiling code. It is documented for developers in `?data_prepare`, `?new_pprof_model`, and `?model_contract`, and may still change before 2.0.0.
