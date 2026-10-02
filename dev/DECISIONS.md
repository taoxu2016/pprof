# Decision records

Short records of decisions that shape the rewrite, newest last. Changes to statistical behavior don't belong here: they go in DISCREPANCIES.md and need methodology sign-off.

## Template

### DEC-NNN: Title

- Date:
- Status: proposed | accepted | superseded by DEC-NNN
- Context:
- Decision:
- Alternatives considered:
- Consequences:

---

### DEC-001: Default `threads = 1` in every function

- Date: 2026-10-02
- Status: accepted (brief §3.5)
- Context: The reference defaults to `threads = 2` in `SM_output()` for the logistic models, hard-codes 4 in logistic RE/CRE `confint()`, and defaults to 1 elsewhere. CRAN allows at most 2 cores in examples and tests.
- Decision: Every function defaults to `threads = 1`, and thread counts are never hard-coded. This is a computational setting rather than a Class B change, because results must agree across thread counts within Tier 1/2 tolerances.
- Alternatives considered: Keep each function's reference default. This was rejected because it's inconsistent, and the hard-coded 4 violates CRAN policy.
- Consequences: The fixture generator passes `threads = 1` explicitly. The migration guide notes the change.
