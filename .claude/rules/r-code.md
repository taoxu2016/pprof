---
paths:
  - "R/**/*.R"
---

# R code conventions

Source: brief §5.2, §5.4, §5.5, and §8. Read those sections when in doubt.

- Follow `dev/NAMING.md` (written in Phase 0) and its argument vocabulary. Sibling functions share argument names, order, and defaults.
- Use snake_case throughout: verbs for functions that act, nouns for objects.
- Use only whitelisted abbreviations (candidates: `fe`, `re`, `cre`, `se`, `ci`, `id`). Don't carry over `logis`, `SM`, `Y.char`, `Z.char`, or `ProvID.char`.
- Use S3 only. Classes are prefixed `pprof_`, with at most one intermediate class. Every class has `new_*()` and `validate_*()`. Check classes with `inherits()`.
- Respect the layers: data → model → inference → provider profiling → presentation. Never reach into a layer above. Presentation code consumes standardized result objects, never model internals or string-valued attributes.
- Numerical code uses base R vectors, matrices, lists, and data frames, with no tidy evaluation, dplyr, tidyr, or magrittr. Use the native pipe `|>` only where it helps readability.
- Parse formulas with `terms()` and model frames, never with regular expressions.
- Validate inputs at the API boundary with classed conditions, for example `pprof_error_invalid_input`.
- Route messages through the single verbosity helper, and print nothing when verbosity is off.
- Never rely on partial matching of `$` or of arguments.
- Don't create hidden side effects: no `set.seed()` and no global `options()` changes. Restore anything you change with `on.exit()`.
- Thread counts come only from the `threads` argument, which defaults to 1.
- Keep model objects compact (brief §5.2). Keep the full design matrix, processed data, or lme4 fit only when `keep_data = TRUE`.
- Compatibility wrappers for old names live only in their dedicated files and contain only translation logic.
- Document exports with roxygen2 markdown. Examples run fast and use at most 2 threads.
