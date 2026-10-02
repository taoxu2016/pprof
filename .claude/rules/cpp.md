---
paths:
  - "src/**"
---

# C++ conventions

Source: brief §5.6 and §3.5. Read those sections when in doubt.

- Layering: R API → thin Rcpp adapter → C++ numerical core.
  - Adapter files that contain `// [[Rcpp::export]]` stay at the top level of `src/`, because `Rcpp::compileAttributes()` scans only there.
  - Core sources live in subdirectories such as `src/core/`, `src/logistic/`, and `src/linear/`.
- List every subdirectory source explicitly in `OBJECTS` in both `Makevars` and `Makevars.win`. Don't use `$(wildcard ...)` or `$(shell ...)`; they are GNU make extensions.
- The core never includes Rcpp headers or uses Rcpp types, `Rcout`, `Rcpp::stop`, or the R API.
  - It takes and returns plain C++ and Armadillo types, plus result structs that carry status and diagnostics.
  - The adapter catches exceptions and converts them to R errors.
- Use C++17 and Armadillo. Changing the linear-algebra library would change numerical paths.
- Put all code in `namespace pprof`, with one sub-namespace per module.
  - Types are PascalCase; functions and variables are snake_case.
  - File names are snake_case and match their main content.
  - Rcpp-exported functions carry a distinctive prefix and stay internal to the package.
- Use RAII and const-correctness. No global state, and no `using namespace` in headers.
- Keep functions small, and format with `clang-format`.
- Give every numerical constant (floors, clamps, line-search constants) a name and a comment stating its contract. Values must match the reference (PROJECT_CONTEXT §5.7).
- Use one shared, tested routine for the block information matrix (provider diagonal, cross block, Schur complement). Fitting, variance, score tests, and Firth all call it.
- When reproducing a reference algorithm, keep its iteration semantics exactly:
  - initial values and update order;
  - Armijo constants (s = 0.01, t = 0.6);
  - clamping on every iteration;
  - the stopping rule;
  - loop bounds such as SerBIN's `iter <= max_iter`.
- Parallel code uses one backend (OpenMP).
  - Never call the R API inside a parallel region, and never let an exception escape one.
  - Results with `threads > 1` must match `threads = 1` within tolerance and be deterministic for a fixed thread count.
  - Watch thread-private variables shared across `omp single` blocks. The reference's Firth race (D-05) comes from that pattern.
- After changing an exported signature, run `Rscript -e 'Rcpp::compileAttributes()'` and commit the regenerated `RcppExports` files.
- Don't move code into or out of C++ without benchmark evidence from `dev/bench/`.
