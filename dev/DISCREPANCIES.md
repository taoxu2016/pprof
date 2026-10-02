# Discrepancy register

Every behavioral difference between the reference (pprof 1.0.3, commit 5260838) and the rewrite, whether intended or discovered.

Classes (brief §3.3):

- A: the reference crashes, errors, returns NULL, misaligns results with provider IDs, or behaves nondeterministically. May be fixed, with a regression test.
- B: any change to a numeric value, flag, inclusion decision, or default. Not made without written sign-off from a methodology owner. Until then, the rewrite reproduces the reference.
- C: documentation or messages contradict behavior. Fix the documentation or message to match the behavior.

A discrepancy is never resolved by loosening a tolerance, editing a fixture, or dropping a test case.

Status values: candidate, verified, decided (fix, preserve, or awaiting sign-off), resolved (with a regression test).

Candidates D-01 to D-21 are listed in PROJECT_CONTEXT.md §6.1. Phase 0 verifies them and moves them here.

## Template

### D-NN: Short title

- Component:
- Class (proposed): A | B | C
- Description:
- Minimal reproducible example:
- Affected outputs:
- Statistical impact:
- Options:
- Recommendation:
- Decision owner:
- Status:
- Regression test:
