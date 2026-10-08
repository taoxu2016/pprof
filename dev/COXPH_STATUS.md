# CoxPH phase: status

The dated log of the CoxPH phase (`dev/coxph_brief.md`, §0): an entry after each session with material progress, naming the next step. Newest last.

**Status:** Phase C0 (design and decisions) delivered; at the C0 gate, awaiting the project lead's approval. Phase C1 has not started.

## 2026-10-07

- The project lead approved the brief (`dev/coxph_brief.md`) and its §12 process changes (DEC-086).
- The evidence behind the brief, with its scripts and outputs, is in `dev/design/coxph-facts/` (commit `ed2e168`).
- Branch `coxph/phase-0`, from `main` at `ea7c07b`: the brief, the evidence, DEC-086, this document, and the §12 changes.
- Open: the brief's §10 questions (Q1–Q16) and the Class B items of its §3.3 still need their sign-offs; Phase C0 registers them as M-23 onward and D-56 onward. The Cox fixture folder is planned as `tests/testthat/fixtures/cox/` (protected in `.claude/settings.json`); Phase C1 confirms the path.
- Next step: Phase C0, the design document `dev/design/COXPH_DESIGN.md` (brief §9), when the project lead asks for it.

## 2026-10-08: Phase C0 at its gate

- On 2026-10-07 the project lead asked for Phase C0, delegated its decisions, the sign-offs the brief's §10 names among them ("use your best judgement or recommendation for the decisions"), and asked for the work to be pushed to `coxph/phase-0`.
- Delivered (brief §4 and §9):
  - `dev/design/COXPH_DESIGN.md`, parts A to J (`61991e7`); at the gate, two dangling cross-references were fixed (M-34, DEC-090), §F was split into subsections F.1 to F.6, which the design already cited, and §F.4 now roots the mid-p limits on pprof_py's bracket and split point (§A.4, K-141) instead of the exact limits, which need not enclose them;
  - the registers (`2bc0303`): K-131 to K-147, D-56 to D-74, M-23 to M-41, and DEC-087 to DEC-093;
  - `dev/NAMING.md` §10, and the note in `dev/design/ARCHITECTURE.md` §E.6 (`9a087c2`).
- Decided under the delegation: M-23 to M-41 as proposed, and with them the Class B items D-56 to D-61, D-64, and D-72. Each awaits confirmation by a methodology owner once M-16 names them.
- Gate checks. C0 changes no package code.
  - `devtools::document()` changed nothing.
  - `devtools::test()`: 67 files, 1,122 tests, 7,762 expectations; none failed or skipped, no warnings or errors, as at the rewrite's final gate. It took about 3 hours, with no sleep or standby in that time, on `load_all()`'s build of the C++ engines without optimization (`-O0 -g`) and with the heavy tests that `R CMD check` skips (`skip_on_cran()`). The reference suite took 98 s on the same build, so the time goes elsewhere in the suite; earlier phases did not time it, so whether it has slowed is not known.
  - `R CMD check --as-cran --no-manual`: 0 errors, 0 warnings, and the previous gate's 2 notes (the package site's address answers 404; "unable to verify current time"); 755 s.
  - `validation/run-reference.R`: 368 of 368 cases match, none skipped, and no provider lies within tolerance of a flag threshold; the report equals the committed `validation/equivalence-report.md` but for its date and commit; 98 s.
- CI on the pushed `6d18a29`: check, coverage, lint, and pkgdown passed. In `rewrite-reference` (run 37699886675), the per-platform jobs matched pprof 1.0.3 run on their runners (368 of 368 cases on Windows, macOS, and Linux), and the fixture-platform job failed the 42 lme4-backed cases it failed in four runs of Phase 8. The processor accounts for it: in the five runs of that job that record one, it failed on every AMD Zen 3 runner (32 KB L1 data cache) and passed on every Zen 5 runner (48 KB, as on the machine that produced the fixtures), and Eigen, through which lme4 forms its cross-products, sizes the blocks of its matrix products from the L1 cache, which would explain it; it is not yet reproduced with lme4 itself (D-53, updated; `dev/design/coxph-facts/15_eigen_cache_blocking.R`).
- Open for the project lead:
  - confirming the delegated decisions, or sending them to the methodology owners;
  - a remedy for the processor dependence of the fixture-platform job (D-53);
  - the brief's title still says "(draft)";
  - the manual workflow that regenerates the Cox fixtures (brief §12), which comes with the C1 generator;
  - timing `devtools::test()` per file, since COXPH_DESIGN §C.2 runs it before and after every data-layer commit of C2.
- Next step: the project lead's approval of the C0 gate; then the pull request of `coxph/phase-0` into `main`, and Phase C1 (reference capture) on `coxph/phase-1` when the lead asks for it.
