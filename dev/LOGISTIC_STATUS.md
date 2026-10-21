# Logistic extensions phase: status

The dated log of the logistic extensions phase (`dev/logistic_brief.md`, §0): an entry after each session with material progress, naming the next step. Newest last.

**Status:** Phase L0, design and decisions, is closed (2026-10-20) and in `main`. Phase L1, reference capture, is complete on `logistic/phase-1` and awaits the project lead's approval at its gate; L2 starts only after it.

## 2026-10-20: the brief

- On `logistic/phase-0`, from `main` at `fa6b290`: CLAUDE.md's "Current phase" and its confidentiality rule (`90e76f2`, approved by the project lead); the evidence behind the brief, facts 01 to 08 in `dev/design/logistic-facts/` (`9554244`); the draft brief (`8db9d76`).
- pprofR 0.2.0 was read in full at commit `f23c288`, fetched read-only; nothing of its files entered the repository, and each commit's added lines, file names, and message were searched for the production terms seen in it, with no match.
- Next step: the project lead's approval of the brief.

## 2026-10-20: the brief approved; Phase L0

- The project lead approved the brief, its recommendations, and §12's process changes: "I approve all your plan and recommendations. If no recommendations, please use your best judgement and implement the code." (DEC-143). The questions of §10 are decided as recommended, with Q4's recommendation, the merged direct standardization algorithm for every direct measure of the new interface, as the sign-off of that Class B change (DEC-144).
- Phase L0 started on the same branch: the design document, the registers, and the process changes. The phase plan stops at L0's gate before any package code (§4).
- Next step: Phase L0's deliverables and its gate.

## 2026-10-20: Phase L0's gate

- The deliverables of the brief's §4 and §9, on `logistic/phase-0`:
  - the design, `dev/design/LOGISTIC_DESIGN.md` (sections A to K), with fact 09 (`612a414`);
  - the registers (`d9a8358`): DEC-145 to DEC-155; D-82 to D-105, the differences from pprofR with their classes; M-42 to M-65, decided (DEC-144); K-150 to K-167;
  - NAMING §11, ARCHITECTURE §E.8, and the developer guide's row (`c8d84aa`);
  - §12's process changes (DEC-154): CI on `logistic/**` (`aba67f0`); CLAUDE.md, the test rules, the settings, and the phase-gate skill (`e48f331`); CLAUDE.md's equivalence essentials (`6a5a6da`). The reference workflow runs the pprofR comparisons from L1, when they exist.
- Before committing, the design and the registers were reread against the evidence:
  - the stabilized variance's memory bound was lowered to 2.5 × 10^7 doubles (200 MB, the size of R̂ itself at the largest cluster allowed);
  - D-88's summary line, and D-105's account of the cluster sums (formed in double by `rowsum()`), were corrected;
  - DEC-155 records `glm()`'s values for rows with zero trials (y/n set to 0), from a run;
  - DEC-145 states that no call of `fit_logistic_fe()` passes a fourth argument by position, which a parse of every R file, test, vignette, and help example confirmed.
- The gate's checks found one defect: `validation/run-cox-reference.R` read the register from the CoxPH section to the end of the file, so its table of the CoxPH entries also listed D-82 to D-105. Fixed in `ff21bb7`: the table ends at the register's next section.
- Checks. L0 changes no package file; it touches only `dev/`, `validation/run-cox-reference.R`, `.claude/`, `.github/`, and CLAUDE.md:
  - `devtools::document()` at `6a5a6da`: the generated files as committed;
  - `devtools::test()` at `6a5a6da`, in the verification worktree: 83 files, 1,320 tests, 12,696 expectations; none failed, errored, skipped, or warned (2,015 s, beside the tarball's build). These are the counts of the CoxPH phase's last code commits (`6df2b54`, `266bb38`);
  - `validation/run-reference.R` at `6a5a6da`: 368 of 368 cases, none skipped, no provider within tolerance of a flag threshold; the report equals the committed one but for its date and commit;
  - `validation/run-cox-reference.R` at `ff21bb7`: 1,897 comparisons, 1,871 within their tier, 26 explained by a register entry, none failing, no test failing; the report equals the committed one but for its date and commit;
  - `dev/reference/cox/calibrate.R` at `ff21bb7` reproduces `validation/cox-calibration-report.md` byte for byte (1,058 of 1,058 rows, 84 explained; 4,724 flags, none differing). This needs `PPROF_SPARK` set to pprof_spark's fixtures at `e917a68`, exported read-only;
  - `R CMD check --as-cran --no-manual`, run alone on the tarball of a clean export of `6a5a6da`, which has `ff21bb7`'s contents since that commit changes only the build-ignored `validation/`: 0 errors, 0 warnings, and the 2 notes of the previous gates (the website's address, 404; "unable to verify current time"). 539 s;
  - the tarball is 4,982,794 bytes, 17,206 under the 5,000,000 at which the check notes its size;
  - `lintr` on the changed lines of `validation/run-cox-reference.R`: clean;
  - the pprofR comparisons (from L1), coverage, and benchmarks (from L2) do not apply at L0.
- The production-term search of `main..logistic/phase-0` found no match in the added lines, the file names, the commit messages, or the branch name.
- For the project lead's attention at the gate:
  - Q4: the approval was read as signing off the merged algorithm for every direct measure of the new interface (D-89, DEC-151), a Class B change by rounding, up to 4e-12 relative. The brief's default, the new features only, remains open to the lead until L4;
  - D-100 was decided by best judgement: a provider whose rows all have zero trials raises an error;
  - DEC-150: the brief's §3.7 SHOULD is not met (the exact test over the trials);
  - DEC-153: the tarball's size goes to L2's gate;
  - DEC-145: positional calls of `fit_logistic_fe()` beyond its third argument change meaning.
- Next step: the project lead's approval of L0's gate, and of pushing `logistic/phase-0` and opening its pull request into `main`. Then L1, reference capture, on `logistic/phase-1` from `main`, its plan first (`dev/design/LOGISTIC_L1_PLAN.md`).

## 2026-10-20: Phase L0's gate closed

- The project lead approved closing L0's gate and asked for the work in `main` without a pull request: the fork's `main` takes `logistic/phase-0` as a fast-forward from `fa6b290`.
- With no pull request, `rewrite-sanitizers`, which runs on pull requests or by hand, does not run; L0 changes no package code. The other workflows run on the push.
- Next step: Phase L1, reference capture, on `logistic/phase-1` from `main`, its plan first (`dev/design/LOGISTIC_L1_PLAN.md`), for the project lead's approval.

## 2026-10-20: Phase L1 started

- The project lead approved the plan and asked to continue ("I approve the plan and continue"): Phase L1 runs on `logistic/phase-1`, from `main` at `2efb4e7`, by `dev/design/LOGISTIC_L1_PLAN.md`, adopted under that approval.
- Next step: the plan's order of work, starting with the pprofR library.

## 2026-10-21: Phase L1's deliverables

On `logistic/phase-1`, by `dev/design/LOGISTIC_L1_PLAN.md`:

- **The pprofR library** (`f0d82ce`, DEC-156): pprofR 0.2.0 from `git archive f23c288`, with Rcpp, RcppArmadillo, and poibin at the reference lock's versions; pprofR's own tests pass there (19 blocks, 102 expectations).
- **The generator and the fixtures** (`f0d82ce`, `95f9090`, `4d605f7`; DEC-157):
  - eleven synthetic cases, 492 records, 1.4 MB, in `validation/fixtures/pprofr/`;
  - two runs from one commit agree byte for byte;
  - the fixtures' strings and manifest hold none of the production terms.
- **Found while building the cases:**
  - pprofR's exact test of a provider without trials crashes R, through `poibin::ppoibin(0, numeric(0))`; added to D-100.
  - pprofR's tight fits stop short of the maximum when the line search is on (a score of 1.6e-5 at tol 1e-13), so the tight fits run without it (`95f9090`). This is a property of SerBIN's line search near the rounding error of the log-likelihood, shared by both packages, not a difference between them.
  - The many-trials case was sized to the cost of pprofR's exact intervals: 70 s a call at 1,100 to 2,200 trials a provider, 280 s at 2,000 to 4,000.
- **The calibration** (`be5a063`, DEC-158): every agreement with an independent reference is within its tier, and 187 of 196 rows pass. The nine others are controls within 10 units of their tier; M-66 asks the project lead about them:
  - the exact and score limits under `root`: one event moved, 0.22 to 8.4 units;
  - the indirect measures under `closed_form`: the null shifted by 1e-9, about 7 units.
- **The binary comparisons and CI** (`272b6a3`, DEC-159): 201 comparisons, none failing. 192 are within their tier (the largest ratio 0.615), and 9 differences are decided by D-82, D-84, and D-90. Both jobs of the reference workflow run them.
- **The benchmark baseline** (`303d88a` and this entry's commit, DEC-160): 132 measurements on six scenarios, 7 skipped with the reason. pprofR's exact intervals take up to 383 s for one provider of 10,000 trials.
- **No core set.** The smallest case is 8 KB, and every case with a binomial fit 59 KB or more, against 17 KB of room (DEC-153); the choice stays for L2's gate.
- **Next step:** L1's gate checks, then the report and the project lead's approval.

## 2026-10-21: Phase L1's gate

- The deliverables of the brief's §4 row L1, and of the plan's §1, are done:
  - the generator with its isolated library;
  - the synthetic cases, with their manifest;
  - the calibration report and the tiers' application;
  - the binary comparisons and CI;
  - the benchmark baseline;
  - the core set's measurement (the previous entry).
- Checks at `c882063`, in the verification worktree; `R CMD check` runs on a clean export of that commit, alone:
  - `devtools::document()`: the generated files as committed;
  - `devtools::test()`: 84 files, 1,326 tests, 12,897 expectations; none failed, errored, skipped, or warned (620 s). These are L0's counts and the pprofR comparisons' 6 tests and 201 expectations;
  - `validation/run-reference.R`: 368 of 368 cases, none skipped, no provider within tolerance of a flag threshold; the report changed only in its date and commit;
  - `validation/run-cox-reference.R`: 1,897 comparisons, 1,871 within their tier, 26 explained, none failing; the report changed only in its date and commit;
  - `dev/reference/cox/calibrate.R`, with pprof_spark's fixtures at `e917a68`: `validation/cox-calibration-report.md` byte for byte;
  - `validation/run-pprofr-reference.R`: 201 comparisons, 192 within their tier (the largest ratio 0.615), and 9 differences that D-82, D-84, and D-90 decide, none failing; the report changed only in its date and commit;
  - `dev/reference/pprofr/calibrate.R`: 187 of 196 calibrated rows pass, the nine others being M-66's controls; the report changed only in its header line;
  - `R CMD check --as-cran --no-manual`: 0 errors, 0 warnings, and the 2 notes of the previous gates (the website's address, 404; "unable to verify current time"), in 662 s. Its tests skip the pprofR comparisons, the fixtures being outside the package;
  - the tarball is 4,988,078 bytes, 5,284 more than at L0 (the two test files) and 11,922 under the 5,000,000 at which the check notes its size;
  - `lintr`: the new test files, the generator, the calibration, the runner, and the benchmark scripts are clean;
  - coverage and the benchmark comparison begin at L2.
- The production-term search of `main..logistic/phase-1` (9 commits before this entry, 45 files) found no match in the added lines, the file names, the commit messages, the branch name, or the strings inside the binary fixtures.
- CI has not run on these commits; the branch is not pushed.
- For the project lead's attention:
  - M-66, open: the controls that fall within 10 units of their tier;
  - pprofR's exact test crashes R on a provider without trials (D-100);
  - the line search's premature stops at tight tolerances, in both packages;
  - the tarball's room, now 11,922 bytes. The comparisons always skip under `R CMD check`, so leaving their two files out of the tarball is one option for DEC-153's choice at L2's gate.
- Next step: the project lead's approval of L1's gate, and the answer to M-66. Then L2, binomial outcomes, on `logistic/phase-2` from `main`, its plan first.
