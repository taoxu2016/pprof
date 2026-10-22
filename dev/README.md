# dev/

Developer documents and tools for pprof. Not part of the package (`.Rbuildignore`).

| Path | Contents |
|---|---|
| `logistic_brief.md` | The logistic extensions phase brief: requirements and gates for bringing the features of pprofR 0.2.0 (commit `f23c288`) into pprof (approved 2026-10-20) |
| `LOGISTIC_STATUS.md` | The logistic extensions phase's status: a dated log of each session, naming the next step |
| `DEVELOPER_GUIDE.md` | How the package is built, tested, and extended; start here to add a model |
| `NAMING.md` | The naming convention and argument vocabulary |
| `CONVENTIONS.md` | The numerical conventions of pprof 1.0.3 that the package reproduces (`K-xx`) |
| `DISCREPANCIES.md` | Every behavioral difference from pprof 1.0.3, with its class and status (`D-xx`) |
| `DECISIONS.md` | Decision records (`DEC-xxx`) |
| `OPEN_QUESTIONS.md` | Questions for the methodology owners (`M-xx`) |
| `DOMAIN.md` | Glossary and methodological references |
| `design/` | `ARCHITECTURE.md` (the design, with notes on how it was built) and `BEHAVIOR_SPECS.md` (what each function of pprof 1.0.3 does); the logistic extensions phase's design (`LOGISTIC_DESIGN.md`), its phases' plans (`LOGISTIC_L<n>_PLAN.md`), and the evidence behind them and its brief (`logistic-facts/`) |
| `reference/` | The generator of the frozen results of pprof 1.0.3 in `tests/testthat/fixtures/reference/` and `validation/fixtures/reference/`, with its diff reports; in `reference/cox/`, the generator of the Cox fixtures from pprof_py v0.7.0 and the pinned survival and glmnet, with the calibration of the Cox tolerance tiers; in `reference/pprofr/`, the generator of the pprofR fixtures from pprofR 0.2.0 in an isolated library, with the calibration of the comparisons with it |
| `bench/` | Benchmarks against pprof 1.0.3, in `bench/cox/` the paired Cox benchmarks against the engine calls, and in `bench/pprofr/` the pprofR baseline, with results |
| `tools/ci_runs.R` | Reads the fork's CI runs, jobs, and annotations through the public GitHub API, without signing in |
| `tools/data_prepare_snapshot.R` | Records the signatures of the `pprof_data` objects of every reference case, which `tests/testthat/test-data-prepare-snapshot.R` compares the code with |
| `tools/namespace_compare.R` | Which functions, exports, methods, and data a change touched, between the namespaces installed from an old commit and from the working tree |
| `tools/coverage_added.R` | The test coverage of the R lines added since a commit |

## The v2 rewrite's working documents

The rewrite of pprof 1.0.3 into version 2.0.0 ran in phases 0 to 8 and closed on 2026-10-07. Its working documents were removed then: the engineering brief (`dev/pprof_rewrite_brief.md`), the status document (`dev/PROJECT_CONTEXT.md`), the phase plans, handoffs, and wording list (`dev/design/PHASE*.md`), the Phase 0 audit with its evidence logs (`dev/design/audit/`, IDs `Vxx.y` and `Bx`), the scripts that gathered each phase's facts (`dev/design/phase5-facts/` to `phase8-facts/`), and the final review (`dev/design/FINAL_REVIEW.md`). The registers, ARCHITECTURE, and BEHAVIOR_SPECS still cite them as the record of how each decision was reached.

They are in the repository's history at commit `5977087`, the last commit of the rewrite, which `main` contains: for example `git show 5977087:dev/pprof_rewrite_brief.md`, `git show 5977087:dev/design/FINAL_REVIEW.md`, or `git ls-tree -r --name-only 5977087 -- dev/design`. PROJECT_CONTEXT's lasting sections moved: §5.7 to `CONVENTIONS.md`, §9 to `OPEN_QUESTIONS.md`, §3 and §4 to `DOMAIN.md`.

## The CoxPH phase's working documents

The CoxPH phase added the Cox models in phases C0 to C6. It closed on 2026-10-16, and its Class B items and questions were signed off on 2026-10-19 (DEC-142). Its working documents were removed on 2026-10-22:

- the brief (`dev/coxph_brief.md`) and the status log (`dev/COXPH_STATUS.md`);
- the design (`dev/design/COXPH_DESIGN.md`) and the phases' plans (`dev/design/COXPH_C1_PLAN.md` to `COXPH_C6_PLAN.md`);
- the wording list of its documentation (`dev/design/COXPH_C6_WORDING.md`) and its final review (`dev/design/COXPH_FINAL_REVIEW.md`);
- the scripts and outputs behind its evidence (`dev/design/coxph-facts/`).

Code comments, tests, and the registers cite them as the CoxPH brief, COXPH_DESIGN, the C1 to C6 plans, and facts by number. The Cox models as built are described in `design/ARCHITECTURE.md` (§E.3, §E.6, and §E.7) and `DEVELOPER_GUIDE.md`.

They are in the repository's history at commit `447398e`, the last commit that holds them, which `main` contains. For example: `git show 447398e:dev/coxph_brief.md`, `git show 447398e:dev/design/COXPH_FINAL_REVIEW.md`, or `git ls-tree -r --name-only 447398e -- dev/design/coxph-facts`.
