---
name: phase-gate
description: Runs the end-of-phase gate checklist for the pprof rewrite and stops for approval. Use whenever a phase's deliverables look complete, before proposing to move to the next phase, or when asked whether a phase is done or ready for review.
argument-hint: "[phase number]"
---

# Phase gate

Phase: $ARGUMENTS (if blank, take the current phase from `dev/PROJECT_CONTEXT.md` §10).

Work through every step, then stop. Never start the next phase from this skill.

1. **Deliverables.** List the phase's deliverables from `dev/pprof_rewrite_brief.md` §4 (and §10 for Phase 0). Mark each one done, partial, or missing, with file paths.
2. **Checks.** Run these and record each command with its outcome:
   - `Rscript -e 'devtools::document()'`, then `git status` to confirm generated files didn't change unexpectedly.
   - `Rscript -e 'devtools::test()'`.
   - `Rscript -e 'rcmdcheck::rcmdcheck(args = c("--as-cran", "--no-manual"), error_on = "never")'`. List every error, warning, and note, and compare them with the previous gate.
   - From Phase 1 on: the reference suite, plus the list of providers within tolerance of a flag threshold.
   - From Phase 3 on: `covr::package_coverage()`, and the benchmark comparison against the Phase 1 baseline in `dev/bench/`.
3. **Registers.**
   - Every difference found in this phase is in `dev/DISCREPANCIES.md` with a class and status.
   - Class B items are marked as awaiting sign-off.
   - Decisions are recorded in `dev/DECISIONS.md`.
4. **Documents.**
   - In `dev/PROJECT_CONTEXT.md`: add a dated §10 entry, update the status line, and move verified findings out of §6.
   - Update `NEWS.md` for user-visible changes.
5. **Git.** All work is committed on the phase branch and the working tree is clean. Don't push.
6. **Report**, in this order: deliverables; check results; discrepancies opened and resolved; decisions; open questions for the methodology owners; risks and incomplete items; a draft pull request description.
7. **Approval.** Ask me to approve closing the gate, and wait.
