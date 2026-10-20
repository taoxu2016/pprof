---
name: phase-gate
description: Runs the end-of-phase gate checklist for the current pprof phase (named under "Current phase" in CLAUDE.md; the logistic extensions phase, L0 to L5, or the closed CoxPH phase, C0 to C6) and stops for approval. Use whenever a phase's deliverables look complete, before proposing to move to the next phase, or when asked whether a phase is done or ready for review.
argument-hint: "[phase, for example L1]"
---

# Phase gate

Phase: $ARGUMENTS (if blank, take the current phase from the status line of the status document that CLAUDE.md's "Current phase" names: `dev/LOGISTIC_STATUS.md` for phases L0 to L5, `dev/COXPH_STATUS.md` for C0 to C6).

Work through every step, then stop. Never start the next phase from this skill.

1. **Deliverables.** List the phase's deliverables from its brief's §4 (and §9 for L0 or C0): `dev/logistic_brief.md` for L0 to L5, `dev/coxph_brief.md` for C0 to C6. Mark each one done, partial, or missing, with file paths.
2. **Checks.** Run these and record each command with its outcome:
   - `Rscript -e 'devtools::document()'`, then `git status` to confirm generated files didn't change unexpectedly.
   - `Rscript -e 'devtools::test()'`.
   - `Rscript -e 'rcmdcheck::rcmdcheck(args = c("--as-cran", "--no-manual"), error_on = "never")'`. List every error, warning, and note, and compare them with the previous gate.
   - `Rscript validation/run-reference.R`: the existing families must stay bitwise identical. List the providers within tolerance of a flag threshold.
   - `Rscript validation/run-cox-reference.R`: the Cox comparisons against the `pprof_py` fixtures; `Rscript dev/reference/cox/calibrate.R` must reproduce `validation/cox-calibration-report.md`.
   - From L1 on: the pprofR comparisons against the pprofR fixtures, with the calibration report (`dev/logistic_brief.md` §3.5).
   - From L2 on (C2 in the CoxPH phase): `covr::package_coverage()` with the coverage of the lines the phase added (`dev/tools/coverage_added.R`), and the benchmark comparison against the phase's baseline in `dev/bench/`.
   - For the logistic extensions phase: the search of the phase's diff from `main`, its file names, and its commit messages for the production terms seen in pprofR (CLAUDE.md), with its result.
3. **Registers.**
   - Every difference from the phase's reference (pprofR 0.2.0 or `pprof_py` v0.7.0) found in this phase is in the phase's section of `dev/DISCREPANCIES.md` with a class and status.
   - Class B items are marked as awaiting sign-off, or as signed off with the decision that signs them off.
   - Decisions are recorded in `dev/DECISIONS.md`; questions for the methodology owners in `dev/OPEN_QUESTIONS.md`.
4. **Documents.**
   - In the phase's status document: add a dated entry and update the status line.
   - Update `NEWS.md` for user-visible changes.
5. **Git.** All work is committed on the phase branch (`logistic/phase-<n>` or `coxph/phase-<n>`) and the working tree is clean. Don't push.
6. **Report**, in this order: deliverables; check results; discrepancies opened and resolved; decisions; open questions for the methodology owners; risks and incomplete items; a draft pull request description.
7. **Approval.** Ask me to approve closing the gate, and wait.
