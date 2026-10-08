# Cox fixture comparison: `tests/testthat/fixtures/cox` versus `C:/Users/taoxu/AppData/Local/Temp/claude/c--Users-taoxu-python-KevinHe-pprof-rewrite-pprof/f3853950-3403-4f83-9cac-87cc60d5229f/scratchpad/regen/core`

- Old: generator commit 59c9dc048822f4a83513a56d5dceb5c293aaae97
- New: generator commit bcab1b8ab0389832ec173847b3b7abfe69f91d71

## Environment

- Unchanged.

## Summary

- Cases: 7 old, 7 new; 2 identical, 5 changed, 0 added, 0 removed.

## Changed cases

### empty-providers

| Path | Kind | Detail |
|---|---|---|
| `survival$breslow$expected$at_r_beta$row` | numeric | 53 of 300 values differ; max abs 4.44e-16, max rel 3.53e-15 |
| `survival$breslow$expected$at_pprof_py_beta$row` | numeric | 111 of 300 values differ; max abs 4.44e-16, max rel 1.24e-15 |
| `survival$breslow$expected$at_pprof_py_beta$provider_expected` | numeric | 1 of 10 values differ; max abs 1.11e-16, max rel 7.03e-16 |
| `survival$efron$expected$at_r_beta$row` | numeric | 120 of 300 values differ; max abs 4.44e-16, max rel 9.31e-16 |
| `survival$efron$expected$at_r_beta$provider_expected` | numeric | 1 of 10 values differ; max abs 1.78e-15, max rel 1.14e-16 |
| `survival$efron$expected$at_pprof_py_beta$row` | numeric | 105 of 300 values differ; max abs 8.88e-16, max rel 8.37e-16 |
| `survival$efron$expected$at_pprof_py_beta$provider_expected` | numeric | 4 of 10 values differ; max abs 3.55e-15, max rel 1.83e-16 |

### lt-stratified

| Path | Kind | Detail |
|---|---|---|
| `survival$breslow$expected$at_r_beta$row` | numeric | 287 of 600 values differ; max abs 3.55e-15, max rel 2.5e-14 |
| `survival$breslow$expected$at_r_beta$provider_expected` | numeric | 10 of 10 values differ; max abs 2.84e-14, max rel 4.9e-16 |
| `survival$breslow$expected$at_pprof_py_beta$row` | numeric | 110 of 600 values differ; max abs 1.78e-15, max rel 1.49e-14 |
| `survival$breslow$expected$at_pprof_py_beta$provider_expected` | numeric | 2 of 10 values differ; max abs 3.55e-15, max rel 1.19e-16 |
| `survival$efron$expected$at_r_beta$row` | numeric | 173 of 600 values differ; max abs 2.66e-15, max rel 2.4e-14 |
| `survival$efron$expected$at_r_beta$provider_expected` | numeric | 8 of 10 values differ; max abs 1.42e-14, max rel 3.59e-16 |
| `survival$efron$expected$at_pprof_py_beta$row` | numeric | 164 of 600 values differ; max abs 2.66e-15, max rel 2.4e-14 |
| `survival$efron$expected$at_pprof_py_beta$provider_expected` | numeric | 6 of 10 values differ; max abs 1.42e-14, max rel 4.79e-16 |

### near-ties

| Path | Kind | Detail |
|---|---|---|
| `survival$breslow$expected$at_r_beta$row` | numeric | 142 of 300 values differ; max abs 8.88e-16, max rel 1.8e-15 |
| `survival$breslow$expected$at_r_beta$provider_expected` | numeric | 5 of 8 values differ; max abs 3.55e-15, max rel 1.57e-16 |
| `survival$breslow$expected$at_pprof_py_beta$row` | numeric | 110 of 300 values differ; max abs 8.88e-16, max rel 1.6e-15 |
| `survival$breslow$expected$at_pprof_py_beta$provider_expected` | numeric | 4 of 8 values differ; max abs 3.55e-15, max rel 1.57e-16 |
| `survival$efron$expected$at_r_beta$row` | numeric | 85 of 300 values differ; max abs 8.88e-16, max rel 5.19e-15 |
| `survival$efron$expected$at_r_beta$provider_expected` | numeric | 2 of 8 values differ; max abs 3.55e-15, max rel 1.57e-16 |
| `survival$efron$expected$at_pprof_py_beta$row` | numeric | 53 of 300 values differ; max abs 4.44e-16, max rel 5.22e-16 |
| `survival$efron$expected$at_pprof_py_beta$provider_expected` | numeric | 1 of 8 values differ; max abs 3.55e-15, max rel 1.57e-16 |

### rc-stratified

| Path | Kind | Detail |
|---|---|---|
| `survival$breslow$expected$at_r_beta$row` | numeric | 310 of 600 values differ; max abs 8.88e-16, max rel 1.24e-15 |
| `survival$breslow$expected$at_r_beta$provider_expected` | numeric | 19 of 25 values differ; max abs 3.55e-15, max rel 2.12e-16 |
| `survival$breslow$expected$at_pprof_py_beta$row` | numeric | 118 of 600 values differ; max abs 4.44e-16, max rel 2.48e-15 |
| `survival$breslow$expected$at_pprof_py_beta$provider_expected` | numeric | 4 of 25 values differ; max abs 3.55e-15, max rel 2e-16 |
| `survival$efron$expected$at_r_beta$row` | numeric | 174 of 600 values differ; max abs 4.44e-16, max rel 1.31e-15 |
| `survival$efron$expected$at_r_beta$provider_expected` | numeric | 5 of 25 values differ; max abs 3.55e-15, max rel 2.06e-16 |
| `survival$efron$expected$at_pprof_py_beta$row` | numeric | 246 of 600 values differ; max abs 8.88e-16, max rel 1.24e-15 |
| `survival$efron$expected$at_pprof_py_beta$provider_expected` | numeric | 12 of 25 values differ; max abs 3.55e-15, max rel 2.2e-16 |

### tiny-ties

| Path | Kind | Detail |
|---|---|---|
| `survival$efron$expected$at_r_beta$row` | numeric | 1 of 8 values differ; max abs 1.11e-16, max rel 1.4e-16 |
| `survival$efron$expected$at_r_beta$provider_expected` | numeric | 1 of 8 values differ; max abs 1.11e-16, max rel 1.4e-16 |

