# dev/

Developer documents and tools for pprof. Not part of the package (`.Rbuildignore`).

| Path | Contents |
|---|---|
| `coxph_brief.md` | The CoxPH phase brief: requirements and gates for adding Cox models (approved 2026-10-07) |
| `COXPH_STATUS.md` | The CoxPH phase's status: a dated log of each session, naming the next step |
| `DEVELOPER_GUIDE.md` | How the package is built, tested, and extended; start here to add a model |
| `NAMING.md` | The naming convention and argument vocabulary |
| `CONVENTIONS.md` | The numerical conventions of pprof 1.0.3 that the package reproduces (`K-xx`) |
| `DISCREPANCIES.md` | Every behavioral difference from pprof 1.0.3, with its class and status (`D-xx`) |
| `DECISIONS.md` | Decision records (`DEC-xxx`) |
| `OPEN_QUESTIONS.md` | Questions for the methodology owners (`M-xx`) |
| `DOMAIN.md` | Glossary and methodological references |
| `design/` | `ARCHITECTURE.md` (the design, with notes on how it was built) and `BEHAVIOR_SPECS.md` (what each function of pprof 1.0.3 does) |
| `reference/` | The generator of the frozen results of pprof 1.0.3 in `tests/testthat/fixtures/reference/` and `validation/fixtures/reference/`, with its diff reports |
| `bench/` | Benchmarks against pprof 1.0.3, with results |
| `tools/ci_runs.R` | Reads the fork's CI runs, jobs, and annotations through the public GitHub API, without signing in |

## The v2 rewrite's working documents

The rewrite of pprof 1.0.3 into version 2.0.0 ran in phases 0 to 8 and closed on 2026-10-07. Its working documents were removed then: the engineering brief (`dev/pprof_rewrite_brief.md`), the status document (`dev/PROJECT_CONTEXT.md`), the phase plans, handoffs, and wording list (`dev/design/PHASE*.md`), the Phase 0 audit with its evidence logs (`dev/design/audit/`, IDs `Vxx.y` and `Bx`), the scripts that gathered each phase's facts (`dev/design/phase5-facts/` to `phase8-facts/`), and the final review (`dev/design/FINAL_REVIEW.md`). The registers, ARCHITECTURE, and BEHAVIOR_SPECS still cite them as the record of how each decision was reached.

They are in the repository's history at commit `5977087`, the last commit of the rewrite, which `main` contains: for example `git show 5977087:dev/pprof_rewrite_brief.md`, `git show 5977087:dev/design/FINAL_REVIEW.md`, or `git ls-tree -r --name-only 5977087 -- dev/design`. PROJECT_CONTEXT's lasting sections moved: §5.7 to `CONVENTIONS.md`, §9 to `OPEN_QUESTIONS.md`, §3 and §4 to `DOMAIN.md`.
