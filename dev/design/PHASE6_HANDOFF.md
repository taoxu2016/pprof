# Phase 6 handoff: visualization

Written at the end of Phase 5 (2026-10-04) for the session that plans Phase 6. This is not the plan. The first deliverable of Phase 6 is `dev/design/PHASE6_PLAN.md`, for the project lead's approval, written in the format of `PHASE5_PLAN.md`. The facts below describe the repository at `9517dfa` (the approved Phase 5); confirm anything numerical by running code before relying on it (CLAUDE.md).

## 1. Scope

- Brief §4: "`ggplot2` plotting that consumes standardized result objects." The brief gives Phase 6 no gate.
- Brief §5.7: ggplot2 for all plots, which return ggplot objects without printing them; plots consume standardized result objects, never model internals or string-valued attributes (the reference dispatches on attributes such as `"model"` and `"description"`); computation such as exact funnel limits belongs in the profiling layer, not in plotting code; funnel plots, interval and caterpillar plots, flag-summary bar plots, and volume panels come from shared building blocks.
- Assigned to Phase 6 by earlier decisions: `caterpillar_plot()` and `bar_plot()`, still the reference's code (DEC-034, DEC-045); the styling of the new plot functions (DEC-045); whether rlang's `.data` pronoun stays in presentation code (ARCHITECTURE §H: "decide in Phase 6").
- Scoping questions for the plan:
  - The gate. Recommendation: end Phase 6 with `/phase-gate` and stop for the project lead even though the brief requires no gate, because Phase 6 changes user-visible output and Phase 7 documents it.
  - "Volume panels" (brief §5.7) have no counterpart in pprof 1.0.3. What they show (for example a measure, or the flag shares, by provider-volume group) and whether Phase 6 delivers them is for the project lead to decide; they draw existing results and add no statistical method.
  - The funnel wrappers `plot.logis_fe()` and `plot.linear_fe()` draw with the reference's `ppfunnel()` and `ppfunnel_linear()` code, kept unchanged in `R/compat-plots.R` as `compat_funnel_plot()` and `compat_funnel_plot_linear()` (DEC-034, DEC-045): keep that code, or rebuild the same layers from the shared building blocks.
  - `data_check()` and `check_data()` (DEC-010) are not visualization; ARCHITECTURE §B.2 places `R/check-data.R` and `R/compat-data-check.R` in a later phase, and caret and olsrr leave Imports with them (DEC-009). Recommendation: Phase 8, with the dependency reduction.

## 2. What exists to build on

- The new plot functions (Phase 3; Phase 5 made them run on the results of every family), all returning ggplot objects:
  - `plot_funnel()` (`R/plot-funnel.R`): from `funnel_limits()` or `profile_providers()` results; logistic FE (score-test limits, K-110) and linear FE (K-111, with D-43 reproduced).
  - `plot_caterpillar()` (`R/plot-caterpillar.R`): from `standardize_providers()` or `provider_effects()` results with intervals; flags against the reference line as K-112, one-sided intervals flagged only on the side tested.
  - `plot_flags()` (`R/plot-flags.R`): from `test_providers()` or `profile_providers()` results; size groups as K-113.
  - Shared helpers in `R/plot-theme.R`: `plot_theme()`, `plot_flag_factor()`, `plot_flag_legend()`, `plot_measure_label()`, `plot_check_result()`.
  - Tests: `tests/testthat/test-plots.R`, `test-present-plots.R`; the plot fixtures run in `test-reference-plots.R`.
- Result objects (DEC-012, DEC-027, DEC-036, DEC-048; NAMING §5): validated lists with a `table` keyed by provider (or by provider, standardization, and measure) and named settings (`level`, `alternative`, `null_value`, `standardization`, `measure`, `population_rate`, `indirect_numerator`, `direct_reference`, and others). Flags are integers -1, 0, 1, or missing (for example every flag of an RE or CRE fit whose provider variance is 0, M-19). `pprof_funnel` holds the limits table and `providers` (one row per provider with `precision`, `estimate`, and `flag`); `pprof_profile` holds `effects`, `tests`, `measures`, and `funnel`.
- The old plot paths:
  - `plot.logis_fe()` and `plot.linear_fe()` are wrappers (`R/compat-plots.R`): they compute through `funnel_limits()` and `test_providers()` and draw with the reference's code.
  - `caterpillar_plot()` (`R/caterpillar_plot.R`, 192 lines) and `bar_plot()` (`R/bar_plot.R`, 104 lines) are still the reference's functions. They work on the wrappers' outputs, which keep the reference's shapes and attributes (BEHAVIOR_SPECS §12, §16). `caterpillar_plot()` takes one interval table from `confint(option = "SM")` and dispatches on its attributes; `bar_plot()` takes a `test()` result with its `"provider size"` attribute.
- Fixtures: `plot` 12 cases (logistic FE and linear FE, including the R-1 cases for D-14 and D-43; `plot-binary-exact` records the classed error of D-07), `caterpillar_plot` 5, `bar_plot` 2 (`dev/reference/cases.R`, the latter two from line 473). The case runner records a ggplot as its data and, for each layer by position, the geom's class, the sorted aesthetic names, and the layer's data (`reference_ggplot_components()` in `tests/testthat/helper-reference-cases.R`). Warnings are stored but not compared (DEC-022), so the ggplot2 deprecation warning that the `bar_plot` fixtures record (D-36) need not be reproduced. A wrapper that rebuilds `caterpillar_plot()` or `bar_plot()` must give the same layers and layer data within the cases' tiers; the appearance of the new functions is free (brief §3.2).
- Dependencies (DEC-009, ARCHITECTURE §H): ggplot2 and scales stay. dplyr and magrittr are now used only by the reference plot code (`R/bar_plot.R` and the funnel drawing in `R/compat-plots.R`). rlang's `.data` pronoun is used by that code, by `R/caterpillar_plot.R`, and by the new plot functions (12 uses in `R/plot-caterpillar.R`, `R/plot-flags.R`, and `R/plot-funnel.R`), which rely on the `importFrom(rlang, .data)` that only the reference files declare: replacing those files needs the import declared elsewhere, ggplot2's own `.data`, or aesthetics by column name. `R/compat-fits.R` (lines 747–748 and 822–823) still declares dplyr and tidyselect imports that its code no longer calls; globals only silences a check note (`R/pprof.R`); caret and olsrr serve `data_check()`. Whether Phase 6 or Phase 8 removes the freed packages from Imports is a plan item (Phase 8 owns the dependency reduction).
- `plot_funnel()`'s help describes only the logistic FE funnel (the indirectly standardized ratio, flags from the modified score test), although since Phase 5 it also draws the linear FE funnel (differences, Wald flags); its axis label already follows the measure.

## 3. What Phase 6 replaces

| Reference code (lines) | Notes |
|---|---|
| `R/caterpillar_plot.R` (192) | K-112; dispatches on attributes; errors for provider-effect tables; `use_flag`, `orientation`, colors; fixtures `caterpillar-*` (5) |
| `R/bar_plot.R` (104) | K-113; dplyr and magrittr; ggplot2's `element_line(size = )` deprecation (D-36); fixtures `bar_plot-*` (2) |
| `compat_funnel_plot()` and `compat_funnel_plot_linear()` in `R/compat-plots.R` (the reference's `ppfunnel()` and `ppfunnel_linear()`, in a nolint block) | only if the plan rebuilds them (scoping question above); fixtures `plot-*` (12) |

Housekeeping that goes with the replacements: the replaced files leave `.lintr`'s exclusions and the legacy list of `tests/testthat/test-architecture.R` (DEC-031), which after Phase 5 is `Data.R`, `RcppExports.R`, `bar_plot.R`, `caterpillar_plot.R`, `data_check.R`, and `pprof.R`.

## 4. Conventions, register entries, and questions in play

- Conventions: PROJECT_CONTEXT §5.7, K-110 to K-113 (funnel, caterpillar, and flag plots), K-80 to K-85 (the measures plotted), K-60 to K-70 (the flags).
- Behavior: BEHAVIOR_SPECS §11 (`plot()` methods), §12 (`caterpillar_plot()` and `bar_plot()`), §16 (the shapes the wrappers produce).
- Register entries (status at `9517dfa`):
  - D-07 (Class A, M-9): exact funnel limits are unsupported; `plot.logis_fe(test = "exact")` and `funnel_limits()` raise `pprof_error_unsupported_inference`.
  - D-15: integer flags in the new results, factors in the wrappers' outputs.
  - D-33 (Class C): the wrappers' interval attributes, which `caterpillar_plot()` reads (`"0.95 %"`, `"RE logis"` for the `logis_cre` indirect rate).
  - D-36: `bar_plot()`'s ggplot2 deprecation warning and other messages.
  - D-43 (Class B, M-18): the linear funnel's limits use σ/sqrt(n_i) and normal quantiles while its flags use the full variance and t, so points outside the limits can be unflagged; reproduced in `funnel_limits()` and `plot.linear_fe()`, awaiting sign-off.
- Open questions for the methodology owners: M-9 (exact funnel limits), M-18 (D-43), M-19 (missing flags on fits whose provider variance is 0), M-20 (the operating characteristics of the RE flags and intervals), and from earlier phases M-8, M-10, M-11, M-14. All stay with defaults that preserve the reference.
- Decisions that constrain the design: DEC-012, DEC-013 (wrappers reproduce the reference, including items awaiting sign-off), DEC-022, DEC-027, DEC-032 and DEC-039 (wrappers rebuild from old objects), DEC-033 (deprecation warnings start in Phase 8), DEC-034, DEC-036, DEC-045, DEC-048.

## 5. Carried over from Phase 5 (approved at its gate, 2026-10-04)

- No frozen fixture covers RE or CRE fits whose provider variance is 0, where the tests return missing flags (`dev/design/phase5-facts/09_singular_re_fits.R`); regression tests and the differential tests' datasets without provider effects cover them. Fixture cases need an approved regeneration; propose them with the first regeneration a later phase needs.
- Benchmarks: `plot.linear_fe` (on `lin-1e5-m1000-p5`) is the only plot task. bench's memory profiling fails on ggplot2 code, so the harness now times such calls without it and records no allocations (`dev/bench/harness.R`). If Phase 6 replaces plot code, tasks for `plot.logis_fe`, `caterpillar_plot`, and `bar_plot` would need rows measured on the reference (`run_reference.R --only`, as DEC-051 did).
- DEC-044: the memory transient while pprof's dependencies load stays until caret leaves Imports; the 50-covariate `logis_fe()` peak is to be investigated in Phase 8.
- The once-per-session deprecation warnings of the wrappers start in Phase 8 (DEC-033); `data_check()` and `check_data()` (DEC-010) are not yet written (scoping question above).

## 6. Lessons from Phase 5

- Degenerate inputs need the reference too: the fixtures and the first differential runs had no singular RE fit, and the defect they hid (`ifelse()` returning a logical vector when every probability is missing) surfaced only in a smoke run of the simulation study. Plots have their own degenerate inputs: no flagged provider, every flag missing, one provider, one-sided intervals, rates clipped at 0 or 100.
- Before switching wrappers, compare the new code with the old live, value by value and attribute by attribute, on every fixture case and a seeded grid; the guard script of Phase 5 (`dev/design/phase5-facts/07_logistic_snapshot.R`) kept the logistic results identical through the refactoring. For plots, the comparison unit is the layer data that the fixtures record.
- Benchmark timings drift between sessions (the reference's `logis_re` fit took 17% longer two days after the baseline); decide time flags with the paired re-measurement (DEC-038), never with the comparison alone.
- Console output on this machine can be flooded with noise: write results to files, use the JUnit reporter (`testthat::JunitReporter`) for test counts and the check reporter for warnings, and write R scripts to files rather than passing code with backslashes through `Rscript -e`.
- Rough durations on the development machine: `devtools::test()` 4 min, `R CMD check` with tests 9 min, coverage 4 min, `validation/run-reference.R` 1.5 min, `validation/run-differential.R` 2.5 min, `validation/run-simulation.R` 32 min, a full benchmark run 28 min, plus 10 min for a supplementary reference baseline of 33 tasks and 27 min for a paired re-measurement of 7 tasks.

## 7. Suggested start for the planning session

1. Follow "Starting a session" in CLAUDE.md on `rewrite/phase-6`.
2. Read the brief's Phase 6 row, §3.2, §5.7, and §6; DEC-034 and DEC-045; this file; ARCHITECTURE §B.1, §B.2, §D.3, §H, and §I; BEHAVIOR_SPECS §11, §12, and §16; PROJECT_CONTEXT §5.7 K-110 to K-113; and the register entries of §4 above.
3. Gather the plan's facts by running code: the reference library is `dev/reference/lib`, and the reference's `caterpillar_plot()` and `bar_plot()` are still in `R/`.
4. Write `dev/design/PHASE6_PLAN.md` (goal and scope with a recommendation for each scoping question; steps with files, approach, and checks; equivalence and tolerances; facts gathered; risks), propose the decisions it needs from DEC-054 on, and stop for approval.
