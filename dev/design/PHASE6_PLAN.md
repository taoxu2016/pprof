# Phase 6 plan: visualization

Approved by the project lead on 2026-10-04, with every recommendation of "Questions for the project lead": the gate at the end of the phase (DEC-054), `plot_volume()` as defined in scoping question 2 (DEC-059), the fixture regeneration R-2 as listed in step 1, decisions DEC-054 to DEC-060 (`dev/DECISIONS.md`), including the removal of four packages from Imports in this phase (DEC-057) and the appearance of DEC-058, and the register entries D-47 and D-48 and D-36's extension. Branch `rewrite/phase-6`, created from `rewrite/phase-5` at `9517dfa` (stacked until Phases 1 to 5 are merged into `rewrite/v2`). The brief gives Phase 6 no gate; this phase ends with `/phase-gate` and a stop (DEC-054).

The facts in "Facts gathered" were confirmed by running the pinned reference (`dev/reference/lib`) and the working tree at `e3eb58d` on 2026-10-04. Treat anything else here as a hypothesis to confirm by running code before relying on it (CLAUDE.md).

## Goal and scope

Brief §4: "`ggplot2` plotting that consumes standardized result objects." Brief §5.7: ggplot2 for every plot, returned without printing; plots read result objects, never model internals or string attributes; computation belongs in the profiling layer, not in plotting code; funnel plots, interval and caterpillar plots, flag-summary bar plots, and volume panels come from shared building blocks. Earlier decisions give Phase 6 `caterpillar_plot()` and `bar_plot()` (DEC-034, DEC-045), the appearance of the new plot functions (DEC-045), and the question of rlang's `.data` pronoun (ARCHITECTURE §H).

Phase 6 delivers:

- the new plot functions finished: `plot_funnel()`, `plot_caterpillar()`, `plot_flags()`, and, if approved, `plot_volume()` (DEC-059), built from shared building blocks, with one appearance (DEC-058), on the results of every family and on degenerate inputs, with help that covers every family;
- the two computations still done in plotting code, the interval flags of the caterpillar plot (K-112) and the provider-size groups of the flag plot (K-113), written once in the profiling layer and used by the new and the old plot functions alike (DEC-056);
- `caterpillar_plot()` and `bar_plot()` as compatibility wrappers, and the four old plot functions free of dplyr, magrittr, and rlang, drawing with the reference's ggplot code (DEC-055); the reference files `R/caterpillar_plot.R` and `R/bar_plot.R` removed;
- the plot dependencies settled: `.data` imported from ggplot2; dplyr, magrittr, rlang, and tidyselect leave Imports (DEC-057).

No number or flag changes: every value a plot draws comes from the profiling API, as today.

### Scoping questions of the handoff

1. **The gate: stop with `/phase-gate`** (DEC-054). The brief requires none, but Phase 6 changes what users see, removes four packages from Imports, and replaces the last reference plot code; Phase 7 documents the result and should start from an approved state.
2. **Volume panels: deliver `plot_volume()`** (DEC-059), or defer them; the project lead decides. pprof 1.0.3 has nothing to reproduce, so the brief's two words are the whole specification. Proposed: the standardized measures of a profile plotted against provider volume (`n_obs`, log scale), one panel per standardization and measure, points coloured by the profile's test flags, each panel's reference line (1, the population rate, or 0, as K-112), and the measure intervals when the profile has them. It reads `profile_providers()` results (or `standardize_providers()` results, then without test flags), computes nothing, and uses the same building blocks as the other plots. The alternative is to defer it past 2.0.0 and record the brief's volume panels as not implemented.
3. **The funnel wrappers: keep the reference's drawing code** (DEC-055), without dplyr and magrittr. Rebuilding their layers from the shared building blocks would either tie the new functions' appearance to the reference's (the wrappers must reproduce its layers, scales, and themes) or need a parameter for every difference; the reference code is the most auditable record of the old appearance. What the funnel wrappers draw already comes from the shared code (`profile_funnel_limits()`, `standardize_providers()`, the tests); step 3 gives `caterpillar_plot()` and `bar_plot()` the same structure.
4. **`data_check()` and `check_data()`: Phase 8**, as the handoff recommends, with caret, olsrr, and globals (DEC-009). They are not visualization, and Phase 8 owns the dependency reduction.

Assigned to Phase 6 by ARCHITECTURE §H: **the `.data` pronoun stays in presentation and compatibility code, imported from ggplot2** (DEC-057), which re-exports rlang's object (F1), and rlang leaves Imports. The pronoun makes a missing column an error rather than a lookup in the calling environment; bare column names with `utils::globalVariables()` would lose that.

### Items carried over from Phase 5 (handoff §5)

- **Fixture cases for RE and CRE fits whose provider variance is 0.** Proposed with R-2 (step 1), the regeneration this phase proposes for the old plot functions, on small seeded datasets.
- **Benchmarks.** Tasks for `plot.logis_fe()`, `caterpillar_plot()`, and `bar_plot()`, measured on the reference with `run_reference.R --only` into a supplementary baseline (DEC-060, as DEC-051); the harness learns tasks whose input is the result of a method call. `plot.linear_fe()` is measured again. Plot calls are timed without memory profiling (the harness's fallback since Phase 5).
- **DEC-044** (the load-order transient, the 50-covariate peak): Phase 8, unchanged. Removing four packages from Imports changes the order in which dependencies load, so the gate's benchmarks report the transient again.
- **Deprecation warnings** (DEC-033) and **`check_data()`** (DEC-010): Phase 8. The new wrappers do not warn yet.

### Out of scope

`data_check()`, `check_data()`, caret, olsrr, and globals (Phase 8); deprecation warnings (Phase 8); vignettes and the migration guide (Phase 7); `autoplot()` methods and coefficient (forest) plots, which neither the brief nor the reference has; exact funnel limits (D-07, M-9); a minimum ggplot2 version (Phase 8, see Risks); any Class B change: D-43 stays reproduced in both funnel paths.

## Steps

Work in this order. Commit small, scoped commits, and add a dated entry to PROJECT_CONTEXT §10 at the end of each step. Check in with the project lead after step 2, with renders of the new plots, because their appearance is easier to judge from pictures than from this description.

### Step 1: Fixture regeneration R-2 (needs approval)

- **Why.** Of the 19 plot fixtures, 4 caterpillar and 2 bar plot cases return values (F2): none has a one-sided interval (the reference draws those from the bound to the estimate and flags one side only, K-112), a direct standardization, a CRE table, a given `refline_value`, an RE test, or a missing flag. Step 3 rebuilds both functions, and the frozen fixtures are the authority (brief §3.1). R-2 also adds the singular RE and CRE fits carried over from Phase 5.
- **Files.** `dev/reference/cases.R`; `dev/reference/datasets.R` (small seeded datasets whose RE and CRE fits have provider variance exactly 0, found by a recorded seed search); the regenerated fixtures and manifests; diff reports `dev/reference/diff-reports/<date>-phase6-plots-core.md` and `-full.md`.
- **Cases (about 20; parents are existing fixture cases unless stated).**
  - `caterpillar_plot()` (7): the `"upper one-sided"` and `"lower one-sided"` tables of `confint-binary-sm-exact-greater` and `-less`, one of them with `use_flag = TRUE` and `orientation = "horizontal"`; a linear one-sided table whose other limit is infinite (`confint-linear-simplified-sm-greater`); a direct rate (`confint-binary-sm-wald`, `CI.direct_rate`); a CRE table (`confint-linear-cre-sm-less`, model `"CRE linear"`); the logistic CRE indirect rate labelled `"RE logis"` (`confint-logis-cre-sm-less`, D-33); a given `refline_value` and `flag_color`; and `orientation = "diagonal"`, a reference error.
  - `bar_plot()` (3): the test of a logistic RE fit (`test-logis-re-two.sided`); `group_num = 1`; `group_num = 60`, where the reference's `cut()` fails (F10).
  - Singular fits (about 10): `linear_re()`, `linear_cre()`, and `logis_cre()` fits whose provider variance lme4 estimates as exactly 0 (new parents), with `test()` (every flag missing), `confint(option = "SM")`, and `SM_output()`, and `bar_plot()` and `caterpillar_plot()` on them.
- **Checks.** A second generation in place is identical to the first; every existing case and dataset is identical in the diff report; the new cases pass against the current tree, where the reference's plot code still runs; the core set stays under 5 MB (DEC-018; 4.43 MB now, F15): the singular fits go to the full set if they do not fit.
- If R-2 is not approved, the wrappers are checked by the guard of step 3 and the differential tests only.
- **As built (2026-10-04).** 29 cases rather than about 20: 8 of `caterpillar_plot()` (the list above has eight), 3 of `bar_plot()`, and 18 on singular fits, because the seed search (`dev/design/phase6-facts/06_singular_seed_search.R`) found data on which all four RE and CRE fits, logistic RE included, have provider variance exactly 0: four fits, their `test()`, `SM_output()`, and `confint()`, and `bar_plot()` and `caterpillar_plot()` on the linear RE fit. Datasets `syn_singular_linear` (seed 1; 20 providers, 200 rows) and `syn_singular_binary` (seed 8; 20 providers, 511 rows), from `simulate_no_provider_effects()` in `dev/reference/datasets.R`. Core set: 332 cases (36 reference errors, 2 new: `caterpillar-bad-orientation` and `bar_plot-group-num-60`), 37 datasets, 4.54 MB; full set unchanged. `dev/reference/compare_fixtures.R` now lists added and removed datasets, which its reports omitted.

### Step 2: The shared plot computations and the new plot functions

- **Files.**
  - Profiling: `R/profile-summaries.R` (new): `profile_reference_value()` (K-112's reference: 1 for ratios, the population rate for rates, 0 for differences), `profile_interval_flags()` (K-112), `profile_size_groups()` and `profile_flag_shares()` (K-113).
  - Presentation: `R/plot-blocks.R` (the shared building blocks; replaces `R/plot-theme.R`), `R/plot-funnel.R`, `R/plot-caterpillar.R`, `R/plot-flags.R`, and `R/plot-volume.R` if DEC-059 is approved.
  - Tests: `tests/testthat/test-profile-summaries.R` (new), `test-present-plots.R`; `test-architecture.R` and `test-extension-toy-model.R` pass unchanged.
  - Documents: NAMING §3.1 and §4 (the plot arguments), ARCHITECTURE §B.2.
- **Approach.**
  - **The computations (DEC-056).** K-112 and K-113 move out of the plot functions into the profiling layer, each written once and cited by its K-ID. `profile_interval_flags()` makes the reference's comparisons in the reference's order (lower before higher, one side for one-sided intervals; a missing limit gives a missing flag), so the wrapper of step 3 can use it as it is; today's `plot_caterpillar()` compares higher first, which differs only for an interval whose lower limit exceeds its upper limit. `profile_flag_shares()` keeps providers without a flag as their own category, as `bar_plot()` does (F10).
  - **Building blocks (brief §5.7).** The flag scales (colours and shapes by category name, fixed whatever flags occur, legend labels with counts, a grey "no flag" category only when a flag is missing); the reference line; the interval layer; the axis labels of measures; a subtitle stating the settings the result records (test, level, alternative, interval); the theme; the argument checks. Internal builders end in `_layer` (NAMING §3.2).
  - **Appearance (DEC-058).** One flag scale for every plot, with the reference funnel plot's Okabe–Ito colours and shapes (lower `#E69F00` square, as expected `#56B4E9` triangle, higher `#009E73` circle); one-sided intervals drawn from the bound to the estimate, as the reference draws them; infinite limits of two-sided intervals drawn to the panel edge; the flag plot's groups labelled with their size ranges; arguments `point_size`, `point_alpha`, `line_width` (renamed from `plot_funnel()`'s `line_size`, after ggplot2's `linewidth`), `label_size`, `group_count`, `orientation`, `use_flag`, `reference`, in the same order wherever they occur.
  - **Degenerate inputs.** Every flag missing (RE and CRE fits whose provider variance is 0, M-19) shows a "no flag" bar where `plot_flags()` now fails with a misleading message about size groups (F12); sizes that do not split into groups keep their classed error; no flagged provider, a single provider, rates at 0 or 100, and infinite limits draw without warnings.
  - **`plot_volume()`** as defined above (DEC-059).
  - **Help.** `plot_funnel()` describes both funnels: logistic FE (ratio, score-test limits, K-110) and linear FE (difference, Wald flags, K-111, with D-43 stated).
- **Checks.** The profiling functions against hand computation on small inputs (K-112 for each alternative and for missing limits; K-113 with ties at the breaks and missing flags); for every plot, layer data identical to the result's values by provider ID (estimates, limits, flags) and the colour of each flag fixed whatever flags occur; the results of every family; the degenerate inputs, built with `ggplot_build()` without warnings; `lintr` on the new and changed files.
- **Check-in** with the project lead, with renders of every new plot on logistic FE and linear FE results (from a script in `dev/design/phase6-facts/`; the images are not committed).
- **As built (2026-10-04).** As planned, with these details. `R/plot-blocks.R` also holds `plot_check_style()` (the sizes, opacity, and widths of the style arguments) and `plot_subtitle()`, which joins the subtitle's parts; `plot_caterpillar()` gained `line_width`. The flag plot's legend lists the categories in the order of the stack (higher, as expected, lower, then "no flag"), without counts, since its labels show shares; the other plots list lower, as expected, higher with counts. The renders come from `dev/design/phase6-facts/07_render_new_plots.R`, so the guard of step 3 is `08_plot_guard.R`. Tests: `tests/testthat/test-profile-summaries.R` (new; the K-112 and K-113 functions against hand computation and against the reference's rule written out) and `test-present-plots.R` (rewritten: layer data equal to the results' values, fixed colours whatever flags occur, one-sided and infinite limits, ties, `plot_volume()`, a singular RE fit, argument checks).

### Step 3: The old plot functions, the switch, and the dependencies

- **Files.**
  - `R/compat-plots.R`: `caterpillar_plot()` and `bar_plot()` with their help, and the funnel wrappers' data preparation and drawing code without dplyr and magrittr.
  - Removed at the switch: `R/caterpillar_plot.R`, `R/bar_plot.R`.
  - Dependencies: `@importFrom ggplot2 .data` in one place; the unused `@importFrom dplyr` and `tidyselect` tags of `R/compat-fits.R` (lines 747–748 and 822–823) removed; dplyr, magrittr, rlang, and tidyselect removed from Imports; `devtools::document()`.
  - Housekeeping: the removed files leave `.lintr`'s exclusions and the legacy list of `tests/testthat/test-architecture.R` (DEC-031).
  - The guard script `dev/design/phase6-facts/08_plot_guard.R` (`save` and `compare` modes, as Phase 5's `07_logistic_snapshot.R`).
- **Approach (DEC-055).**
  - `caterpillar_plot()` validates its input as the reference does, with classed errors where the reference fails without a message of its own (F7); translates the table's attributes into settings (`type` into the alternative; `model` and `description` into the reference value, K-112); computes the flags with `profile_interval_flags()` and labels them `"Lower"`, `"Normal"`, and `"Higher"`; and draws with the reference's ggplot code. The plot data keep the table with columns renamed `SM`, `Lower`, `Upper`, the `prov` and character `flag` columns, and the table's attributes (F4); the colours stay those of the flags present (D-47).
  - `bar_plot()` validates as the reference does, computes the shares with `profile_flag_shares()` into the reference's table (columns `size`, `category`, `count`, `value`, and `.group`; only the combinations that occur, in group and category order; F9, F13), and draws with the reference's ggplot code.
  - The funnel wrappers: `arrange()`, `cross_join()`, `select()`, `mutate()`, `filter()`, and `bind_rows()` become base R giving the same rows, row names, column types, and factor levels; nothing else changes.
  - D-36: `element_line(size = )` becomes `linewidth =`, and `guide_legend(box.linetype = )`, which ggplot2 4 ignores with a warning (F3), is dropped, provided the guard shows the built plots unchanged.
  - D-48 (Class C): the help of `bar_plot()` says that `bar_width` has no effect and names the argument `flag_df`; the help of `caterpillar_plot()` says that one-sided intervals are drawn from the bound to the estimate, not that providers with all or no events have infinite limits.
  - **Guard before the switch.** Before the first change, save for every call of the four old plot functions on the inputs of the fixture cases and on a grid (the `confint()` and `test()` outputs of every family, both standardizations, every measure, each alternative, both orientations, with and without flags, a given `refline_value`, one to three alphas, no flagged provider, one flag category, missing flags, sizes that do not split): the outcome and error class; the plot data and each layer's data; geom and stat classes; mapping expressions as text; layer parameters; each layer's built data; labels; the built scales (limits, breaks, labels, mapped values); guides; the theme. After each commit of the step, all of it must be identical; warnings are recorded, not compared.
- **Checks.** The plot fixture cases, including R-2's, at their tiers; the guard; the legacy tests of pprof 1.0.3; the architecture test; `lintr` on the changed files (the reference's drawing code stays in `nolint` blocks); `R CMD check` without tests, with no new note (such as "Namespaces in Imports field not imported from" or "no visible binding for global variable").
- **As built (2026-10-04).** In three commits, each followed by the guard (`dev/design/phase6-facts/08_plot_guard.R`; its snapshot of 687 records, 25 of them errors, was taken on the code of `d4d6a5d`): the funnel wrappers in base R (`e4fe2ec`; all 687 records identical); `caterpillar_plot()` and `bar_plot()` as wrappers and the removal of their reference files (`f2340b5`; 585 identical, 79 differing only in the class of `bar_plot()`'s plot data, a data frame instead of a grouped tibble, and 23 errors that stay errors, now classed `pprof_error_invalid_input`); the dependencies (`fc60d96`; the same). The guard compares themes by the checksum of their serialization: ggplot2 4's theme elements carry their S7 class, which `identical()` compares by address, and a first comparison of the unchanged code differed only there; it takes the guides from the built plot (`a45db9a`). D-36: dropping `box.linetype` and using `linewidth` left every built plot, guide, and theme identical; `geom_errorbarh()` stays in the horizontal caterpillar plot, because `geom_errorbar(orientation = "y")` builds a different `width` column (the bars' ends are equal), so ggplot2 4's soft deprecation (a warning in the package's own tests) and its message "`height` was translated to `width`" remain, for Phase 8's choice of minimum versions. `caterpillar_plot()` checks `orientation` with a classed error before drawing. `.data` is imported from ggplot2 in `R/plot-blocks.R`. Regression tests: `tests/testthat/test-compat-plots.R` (D-36, D-47, D-48, the plot data of `bar_plot()`, the classed errors).

### Step 4: Validation, benchmarks, and documents

- **Reference suite.** `validation/run-reference.R`, core and full.
- **Differential tests.** `validation/run-differential.R` extended to `plot()` of logistic FE fits (several alphas and nulls), `caterpillar_plot()` on the `confint()` tables of every family (each alternative, both standardizations, both orientations, with flags), and `bar_plot()` on the `test()` results of every family, including the datasets without provider effects (missing flags). They compare the components the fixtures record, at the tiers, and also each layer's built data (`ggplot_build()`), which the fixtures do not record; both sides run ggplot2 4.0.3.
- **Benchmarks (DEC-060).** Measure the new tasks on the reference (`run_reference.R --only`) into a supplementary baseline, then the working tree, the comparison, and the paired re-measurement of flagged tasks (DEC-038). Report: `dev/bench/results/phase6-gate-<date>.md`.
- **Documents.** ARCHITECTURE §B.2, §H, §I.1, and §I.2 as built; NAMING §3.1 and §4; NEWS (the new and changed plots, `caterpillar_plot()` and `bar_plot()` on the new code, four fewer dependencies); DECISIONS; DISCREPANCIES (D-36, D-47, D-48, and the statuses of D-07, D-15, D-33, and D-43); PROJECT_CONTEXT §5.10, §7, §10, and the status line.

- **As built (2026-10-04).** Reference suite: 364 of 364 cases match (core 332, full 32), 19 reference errors reproduced, 21 per-case expectations, no provider within tolerance of a flag threshold; every logistic and random-effect plot case bitwise. Differential tests (`7b75c22`): 3,510 of 3,510 cases match (2,510 bitwise), among them 880 plot cases (180 funnel, 420 caterpillar, 280 bar plots) compared with their built data, the logistic and random-effect ones bitwise and the linear FE ones within the closed-form tier. Benchmarks (`b92de7b`, `9950794`; `dev/bench/results/phase6-gate-20261004.md`): the 4 new tasks on the reference, the working tree's run of 85 tasks, the comparison with the three baselines, and the paired re-measurement: no time regression (the rerun `logis_re` fit takes the reference's time when measured alternately); `bar_plot()` faster, `caterpillar_plot()` as fast, `plot()` of `linear_fe` and `logis_fe` fits at most 0.013 s and 0.046 s slower, the latter mostly two model rebuilds (DEC-039; building it once is a Phase 8 candidate); every memory flag is DEC-044's transient, unchanged by the removal of four imports. Documents: the register (D-33, D-36, D-43, D-47, D-48), ARCHITECTURE §B.2, §H, §I.2, NEWS, PROJECT_CONTEXT §5.10 and §7 (`2aeaf3e`), NAMING (step 2).
### Step 5: Gate

`/phase-gate`, then stop for approval (DEC-054).

## Equivalence and tolerances

- **Fixtures in scope (F2).** 19 core cases: `plot` 12 (9 values; 3 reference errors: D-07's exact funnel and D-14's two integer nulls, which the wrappers fix and whose per-case expectations are the `null = 0` results), `caterpillar_plot` 5 (4 values; 1 error, for a provider-effect table), `bar_plot` 2. R-2 adds about 20. Tiers follow the parent fit: iterative (logistic FE), closed-form (linear FE), lme4 (RE and CRE), exact (errors).
- **What the fixtures record.** For each layer, by position: the geom's class, the sorted names of its aesthetics, and the data given to the layer; and the plot's own data, with its attributes and row names. Doubles are compared at the case's tier, everything else exactly (`tests/testthat/helper-equivalence.R`). The fixtures do not record built data, mapping expressions, scales, labels, guides, or themes.
- **What the wrappers must reproduce.** Every recorded component at its tier: the same plot data, columns, types, factor levels, row names, and attributes, and the same layers. Beyond the fixtures, checked by the guard in one session: the same built plot (built data, labels, scales including D-47's colours, guides, themes). Warnings are not compared (DEC-022), and D-36's are removed.
- **What the new plot functions may change.** Their appearance (brief §3.2): geoms, layers, colours, labels, legends, themes, the order of layers. Not the numbers or flags they draw: points, limits, and flags are the result's values, by provider ID (unit tests), and the K-112 and K-113 rules are the functions the wrappers use, so the fixtures check them through the wrappers.
- **Expected bitwise.** Every component of the four old plot functions against the current code: the data come from the same calls, and the base-R code reorders nothing (F13 for `bar_plot()`; the guard for the rest).
- **No tolerance changes.** Fixture regeneration only as R-2, with approval and a diff report.

## Facts gathered (2026-10-04, at `e3eb58d`)

The scripts and their outputs are in `dev/design/phase6-facts/` (run from the repository root, `Rscript <script> <output>`); F14 is a plain `devtools::test()` run.

- **F1. Environment.** The reference library and the user library have the same ggplot2 4.0.3, dplyr 1.2.1, rlang 1.3.0, scales 1.4.0, tibble 3.3.1, magrittr 2.0.5, and tidyselect 1.2.1, and the core manifest records ggplot2 4.0.3 (01, 02). ggplot2 exports `.data`, `identical()` to rlang's (03).
- **F2. The plot fixtures (01).** 19 core cases, as listed under "Equivalence". The funnel cases record no plot data and four layers (`GeomPoint`, two `GeomLine`, `GeomHline`) whose data have the columns `precision`, `indicator`, `Exp`, `flag`, `alpha`, `lower`, `upper` (`flag` and `alpha` factors); the points of `plot-linear-null0` have 101 rows, one a placeholder for a flag level that does not occur. The caterpillar cases record the plot data and three layers with inherited data; the bar plot cases the plot data and two layers.
- **F3. Warnings stored in the fixtures.** ggplot2's deprecation of `element_line(size = )` (`bar_plot-binary`; once per session) and, for `caterpillar_plot(use_flag = TRUE)`, "Arguments in `...` must be used. Problematic argument: box.linetype".
- **F4. `caterpillar_plot()`'s plot data (01, 02).** The interval table with its columns renamed `SM`, `Lower`, `Upper`, plus `prov` and `flag` (both character), and the table's attributes (`confidence_level`, `type`, `description`, `model`, and `population_rate` for rates of every family, including RE and CRE). Layers: `GeomErrorbar`, `GeomPoint`, `GeomHline`; horizontally `GeomErrorbar` with orientation `"y"` (what `geom_errorbarh()` makes in ggplot2 4) and `GeomVline`.
- **F5. Colours (02, 05).** `caterpillar_plot()` gives its default colours to the flags present, in sorted order: with all three, Higher orange, Lower blue, Normal green; with Higher and Normal (one-sided `greater`), Higher orange and Normal blue; with Lower and Normal (`less`), Lower orange; with Normal only (every logistic CRE table of the example), Normal orange. `bar_plot()` does the same with its fill colours: with every category present, higher `#66c2a5`, as expected `#fc8d62`, lower `#8da0cb`; with every provider as expected, as expected `#66c2a5`. The funnel plots colour lower orange, as expected blue, higher green (D-47).
- **F6. Interval limits (02).** One-sided bars run from the bound to the estimate. The one-sided tables of linear FE, RE, and CRE have every opposite limit infinite (100 of 100 providers); those of logistic FE and RE have finite limits (for logistic FE the bound n_i/E_i, K-91). Two-sided measure tables of every family have only finite limits, including the logistic FE providers without events.
- **F7. Reference errors of `caterpillar_plot()` (02).** A provider-effect table ("Caterpillar plot only supports standardized measure"), a matrix ("the condition has length > 1"), and `orientation = "diagonal"`.
- **F8. Caterpillar flags and test flags (04).** On the example data, the caterpillar flags (K-112) equal the test flags (K-63) for every provider: logistic FE with exact, score, and Wald intervals and tests; linear FE with either provider variance; linear RE; logistic RE. They can differ only where an interval and the test use different distributions (D-32), for a statistic between the two critical values.
- **F9. `bar_plot()`'s plot data (02).** A grouped tibble, to which ggplot2 4 adds `.group`, the index of the size group: columns `size` (levels Q1 to Qg and Overall), `category` (levels higher, as expected, lower), `count` (integer), `value`, `.group`; only the combinations that occur, in group and category order. Layers `GeomBar` (identity stat) and `GeomText`.
- **F10. `bar_plot()` on degenerate inputs (02, 05).** A single provider, `group_num = 60`, or equal sizes fail in `cut()` with "'breaks' are not unique". With every flag missing (a linear RE fit whose provider variance is 0), each group has one row with a missing category, the group's count, and value 1, and the plot builds without warnings. `bar_width` has no effect.
- **F11. Reference run times** of building the plots, 100 providers (02): `caterpillar_plot()` 0.07 s, `bar_plot()` 0.06 s, `plot.logis_fe()` 0.12 s.
- **F12. The new plot functions (03).** They run on the results of every family; funnels exist for the two fixed-effect families only, as declared. `profile_providers(interval = )` sets intervals on the measures only. With every flag missing (a singular linear RE fit), `plot_flags()` fails with "The provider sizes do not split into 4 groups", which misstates the cause; a single provider and `group_count = 60` fail with that classed error. One-sided intervals with infinite limits, logistic FE exact provider effects with infinite limits, rates at 0, and a funnel with no provider flagged build without warnings.
- **F13. `bar_plot()` without dplyr (05).** A base-R table (counts by group and category, the combinations that occur in order, shares within each group, the group index) is `identical()` to `as.data.frame()` of the reference's plot data, and the reference's drawing code on it gives `identical()` built data for both layers.
- **F14. Baseline.** `devtools::test()`: 59 files, 1,025 tests, 6,922 expectations, 0 failed, 0 skipped, 0 warnings (309 s), the Phase 5 gate's count.
- **F15. Fixture size.** The core set holds 4.43 MB of its 5 MB budget (DEC-018), in the generator's units of 2^20 bytes (4,640,561 bytes; the plan first said 4.64 MB, in millions of bytes).
- **F16. Tidyverse code in `R/` (03).** `.data` in `R/plot-funnel.R`, `R/plot-caterpillar.R`, `R/plot-flags.R`, `R/compat-plots.R`, and the two reference files; dplyr and magrittr only in `R/bar_plot.R` and `R/compat-plots.R`; tidyselect only in the unused tags of `R/compat-fits.R`; scales' `percent()` only in `R/bar_plot.R`. The funnel wrappers' layer data are base data frames with automatic row names (03). `tests/testthat/test-plots.R`, a legacy test file of pprof 1.0.3, is empty.

## Decisions proposed

Recorded in `dev/DECISIONS.md` with status "proposed":

| ID | Decision |
|---|---|
| DEC-054 | Phase 6 scope: ends with `/phase-gate` and a stop; `data_check()` and `check_data()` in Phase 8; the singular RE and CRE fixture cases with R-2 |
| DEC-055 | The old plot functions keep the reference's drawing code in `R/compat-plots.R`, draw data computed by the shared code, use base R instead of dplyr and magrittr, and are checked by a guard that compares built plots; the fixture format is unchanged |
| DEC-056 | The caterpillar plot's interval flags (K-112) and the flag plot's size groups and shares (K-113) are profiling functions, used by the new and the old plots |
| DEC-057 | `.data` imported from ggplot2; dplyr, magrittr, rlang, and tidyselect leave Imports in Phase 6 |
| DEC-058 | Appearance and arguments of the new plot functions |
| DEC-059 | Volume panels: `plot_volume()` as defined in scoping question 2 |
| DEC-060 | Benchmark tasks for the plot functions Phase 6 replaces, measured on the reference into a supplementary baseline |

## Questions for the project lead

1. The gate (DEC-054): stop at the end of Phase 6, as recommended, or go on to Phase 7 without one, as the brief allows.
2. Volume panels (DEC-059): `plot_volume()` as defined, another definition, or deferral.
3. R-2 (step 1): approve the case list, trim it, or skip it.
4. DEC-054 to DEC-060, in particular removing the four packages from Imports now rather than in Phase 8 (DEC-057), and the appearance (DEC-058), which the check-in after step 2 will show.
5. The register: D-47 (Presentation) and D-48 (Class C), recorded during planning, and D-36's extension to `caterpillar_plot()`.

## Questions for the methodology owners (defaults reproduce the reference)

No new question. In play: M-18 (D-43) in both funnel paths; M-19, where the new plots show providers without a flag as such, as the reference's `bar_plot()` keeps them; M-9 (exact funnel limits, D-07); M-8 (D-32), through which caterpillar flags could differ from test flags near a threshold (F8). M-16 (who signs off) remains open.

## Risks

- **What the fixtures see.** They record what each layer is given, not what it draws: a one-sided bar drawn from the wrong limit keeps the aesthetic's name and the data and passes. Mitigation: the guard and the differential tests compare built data.
- **ggplot2 versions.** The fixtures were recorded under ggplot2 4.0.3, where `geom_errorbarh()` makes a `GeomErrorbar`; under ggplot2 3.5 it makes a `GeomErrorbarh`, and the horizontal caterpillar cases would fail although the wrapper runs the reference's code. DESCRIPTION requires no ggplot2 version; Phase 8 sets minimum versions with the CRAN review.
- **Load order.** Removing four packages from Imports changes the order in which dependencies load, which is what causes DEC-044's transient; the benchmarks will show the effect.
- **Fixture budget.** R-2 must keep the core set under 5 MB; the singular fits go to the full set otherwise.
- **New interface without a reference.** `plot_volume()` adds API surface that nothing in pprof 1.0.3 specifies; it stays small, reads existing results only, and needs approval.
- **Appearance is a judgment.** Hence the check-in with renders after step 2.
- **Keeping a quirk.** The wrappers keep D-47's data-dependent colours on purpose, so old scripts draw what they drew; the new functions fix the mapping.

## Register items in scope

- Fix (Class C): D-48 (the help of `caterpillar_plot()` and `bar_plot()`).
- Presentation: D-36 (the old plot functions' ggplot2 warnings), D-47 (data-dependent colours: reproduced in the wrappers, fixed in the new functions), D-15 (integer flags drawn as categories).
- Reproduce, awaiting sign-off (Class B): D-43 in `plot_funnel()` and `plot.linear_fe()`; D-32 through the intervals the caterpillar plots draw.
- Unchanged: D-07 (exact funnel limits unsupported); D-33 (the wrappers read the old attributes, the new plots the settings).
