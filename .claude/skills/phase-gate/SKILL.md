---
name: phase-gate
description: Runs the end-of-phase gate checklist for the pprof CoxPH phase and stops for approval. Use whenever a phase's deliverables look complete, before proposing to move to the next phase, or when asked whether a phase is done or ready for review.
argument-hint: "[phase, for example C1]"
---

# Phase gate

Phase: $ARGUMENTS (if blank, take the current phase from the status line of `dev/COXPH_STATUS.md`).

Work through every step, then stop. Never start the next phase from this skill.

1. **Deliverables.** List the phase's deliverables from `dev/coxph_brief.md` §4 (and §9 for C0). Mark each one done, partial, or missing, with file paths.
2. **Checks.** Run these and record each command with its outcome:
   - `Rscript -e 'devtools::document()'`, then `git status` to confirm generated files didn't change unexpectedly.
   - `Rscript -e 'devtools::test()'`.
   - `Rscript -e 'rcmdcheck::rcmdcheck(args = c("--as-cran", "--no-manual"), error_on = "never")'`. List every error, warning, and note, and compare them with the previous gate.
   - `Rscript validation/run-reference.R`: the existing families must stay bitwise identical (brief §5.6). List the providers within tolerance of a flag threshold.
   - From C1 on: the Cox reference comparisons against the `pprof_py` fixtures, with the calibration report (brief §3.5).
   - From C2 on: `covr::package_coverage()`, and the benchmark comparison against the C1 baseline in `dev/bench/` (brief §3.7).
3. **Registers.**
   - Every difference from `pprof_py` found in this phase is in the CoxPH section of `dev/DISCREPANCIES.md` with a class and status.
   - Class B items are marked as awaiting sign-off.
   - Decisions are recorded in `dev/DECISIONS.md`; questions for the methodology owners in `dev/OPEN_QUESTIONS.md`.
4. **Documents.**
   - In `dev/COXPH_STATUS.md`: add a dated entry and update the status line.
   - Update `NEWS.md` for user-visible changes.
5. **Git.** All work is committed on the phase branch (`coxph/phase-<n>`) and the working tree is clean. Don't push.
6. **Report**, in this order: deliverables; check results; discrepancies opened and resolved; decisions; open questions for the methodology owners; risks and incomplete items; a draft pull request description.
7. **Approval.** Ask me to approve closing the gate, and wait.
