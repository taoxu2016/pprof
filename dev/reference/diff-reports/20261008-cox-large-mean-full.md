# Cox fixture comparison: `validation/fixtures/cox` versus `C:/Users/taoxu/AppData/Local/Temp/claude/c--Users-taoxu-python-KevinHe-pprof-rewrite-pprof/f3853950-3403-4f83-9cac-87cc60d5229f/scratchpad/regen/full`

- Old: generator commit 59c9dc048822f4a83513a56d5dceb5c293aaae97
- New: generator commit bcab1b8ab0389832ec173847b3b7abfe69f91d71

## Environment

- Unchanged.

## Summary

- Cases: 13 old, 13 new; 6 identical, 7 changed, 0 added, 0 removed.

## Changed cases

### large-mean

| Path | Kind | Detail |
|---|---|---|
| `input$x1` | numeric | 300 of 300 values differ; max abs 1e+03, max rel 0.334 |
| `pprof_py$breslow$baseline$predictions$[[1]]$cumulative_hazard$[[1]]` | numeric | 19 of 19 values differ; max abs 2.45e-255, max rel 8.7e+48 |
| `pprof_py$breslow$baseline$predictions$[[1]]$cumulative_hazard$[[2]]` | numeric | 19 of 19 values differ; max abs 2.95e-255, max rel 8.7e+48 |
| `pprof_py$breslow$baseline$predictions$[[1]]$cumulative_hazard$[[3]]` | numeric | 19 of 19 values differ; max abs 1.63e-255, max rel 8.7e+48 |
| `pprof_py$breslow$baseline$predictions$[[2]]$cumulative_hazard$[[1]]` | numeric | 15 of 15 values differ; max abs 1.67e-255, max rel 7.78e+48 |
| `pprof_py$breslow$baseline$predictions$[[2]]$cumulative_hazard$[[2]]` | numeric | 15 of 15 values differ; max abs 2e-255, max rel 7.78e+48 |
| `pprof_py$breslow$baseline$predictions$[[2]]$cumulative_hazard$[[3]]` | numeric | 15 of 15 values differ; max abs 1.11e-255, max rel 7.78e+48 |
| `pprof_py$breslow$baseline$profiles$linear` | numeric | 2 of 3 values differ; max abs 1.11e-16, max rel 3.01e-16 |
| `pprof_py$breslow$baseline$public_cumulative_hazard` | numeric | 111 of 111 values differ; max abs 2.82e-255, max rel 8.81e+48 |
| `pprof_py$breslow$baseline$raw$cumulative_hazard` | numeric | 111 of 111 values differ; max abs 2.82e-255, max rel 8.81e+48 |
| `pprof_py$breslow$beta_fixed$loglik` | numeric | 1 of 1 values differ; max abs 8.36e+04, max rel 0.889 |
| `pprof_py$breslow$beta_zero$information` | numeric | 2 of 3 values differ; max abs 6.52e-09, max rel 2.26e-11 |
| `pprof_py$breslow$beta_zero$score` | numeric | 1 of 2 values differ; max abs 6.55e-11, max rel 8.12e-13 |
| `pprof_py$breslow$default$ci_lower` | numeric | 2 of 2 values differ; max abs 2.78e-16, max rel 1.05e-15 |
| `pprof_py$breslow$default$ci_upper` | numeric | 2 of 2 values differ; max abs 1.53e-16, max rel 4.51e-15 |
| `pprof_py$breslow$default$coef` | numeric | 1 of 2 values differ; max abs 1.94e-16, max rel 1.3e-15 |
| `pprof_py$breslow$default$covariance` | numeric | 3 of 3 values differ; max abs 4.77e-18, max rel 1.65e-15 |
| `pprof_py$breslow$default$loglik` | numeric | 1 of 1 values differ; max abs 2.27e-13, max rel 3.34e-16 |
| `pprof_py$breslow$default$p` | numeric | 2 of 2 values differ; max abs 6.77e-17, max rel 2.04e-14 |
| `pprof_py$breslow$default$se` | numeric | 2 of 2 values differ; max abs 4.16e-17, max rel 7.05e-16 |
| `pprof_py$breslow$default$z` | numeric | 2 of 2 values differ; max abs 3.55e-15, max rel 8.76e-16 |
| `pprof_py$breslow$iterates$[[1]]$beta` | numeric | 2 of 2 values differ; max abs 5.55e-17, max rel 1.86e-16 |
| `pprof_py$breslow$iterates$[[1]]$loglik` | numeric | 1 of 1 values differ; max abs 2.27e-13, max rel 3.34e-16 |
| `pprof_py$breslow$iterates$[[2]]$beta` | numeric | 2 of 2 values differ; max abs 5.27e-16, max rel 3.53e-15 |
| `pprof_py$breslow$iterates$[[2]]$loglik` | numeric | 1 of 1 values differ; max abs 2.27e-13, max rel 3.34e-16 |
| `pprof_py$breslow$iterates$[[3]]$beta` | numeric | 1 of 2 values differ; max abs 1.94e-16, max rel 1.3e-15 |
| `pprof_py$breslow$iterates$[[3]]$loglik` | numeric | 1 of 1 values differ; max abs 2.27e-13, max rel 3.34e-16 |
| `pprof_py$breslow$iterates$[[4]]$beta` | numeric | 1 of 2 values differ; max abs 1.94e-16, max rel 1.3e-15 |
| `pprof_py$breslow$iterates$[[4]]$loglik` | numeric | 1 of 1 values differ; max abs 2.27e-13, max rel 3.34e-16 |
| `pprof_py$breslow$iterates$[[5]]$beta` | numeric | 1 of 2 values differ; max abs 1.94e-16, max rel 1.3e-15 |
| `pprof_py$breslow$iterates$[[5]]$loglik` | numeric | 1 of 1 values differ; max abs 2.27e-13, max rel 3.34e-16 |
| `pprof_py$breslow$measures$beta` | numeric | 1 of 2 values differ; max abs 1.94e-16, max rel 1.3e-15 |
| `pprof_py$breslow$measures$direct_expected` | numeric | 6 of 6 values differ; max abs 4.21e-12, max rel 1.63e-14 |
| `pprof_py$breslow$measures$direct_ratio` | numeric | 6 of 6 values differ; max abs 1.89e-14, max rel 1.63e-14 |
| `pprof_py$breslow$measures$expected` | numeric | 6 of 6 values differ; max abs 4.97e-13, max rel 1.48e-14 |
| `pprof_py$breslow$measures$indirect_ratio` | numeric | 6 of 6 values differ; max abs 1.75e-14, max rel 1.48e-14 |
| `pprof_py$breslow$negative_controls$other_ties$ci_lower` | numeric | 2 of 2 values differ; max abs 5.55e-17, max rel 2.93e-16 |
| `pprof_py$breslow$negative_controls$other_ties$ci_upper` | numeric | 2 of 2 values differ; max abs 2.78e-16, max rel 2.53e-15 |
| `pprof_py$breslow$negative_controls$other_ties$coef` | numeric | 2 of 2 values differ; max abs 1.67e-16, max rel 5.46e-16 |
| `pprof_py$breslow$negative_controls$other_ties$covariance` | numeric | 3 of 3 values differ; max abs 5.64e-18, max rel 2.46e-15 |
| `pprof_py$breslow$negative_controls$other_ties$loglik` | numeric | 1 of 1 values differ; max abs 1.14e-13, max rel 1.69e-16 |
| `pprof_py$breslow$negative_controls$other_ties$p` | numeric | 2 of 2 values differ; max abs 5.03e-17, max rel 9.13e-15 |
| `pprof_py$breslow$negative_controls$other_ties$se` | numeric | 2 of 2 values differ; max abs 4.86e-17, max rel 8.23e-16 |
| `pprof_py$breslow$negative_controls$other_ties$z` | numeric | 2 of 2 values differ; max abs 1.78e-15, max rel 6.8e-16 |
| `pprof_py$breslow$negative_controls$shifted_tie$ci_lower` | numeric | 2 of 2 values differ; max abs 2.78e-16, max rel 1.05e-15 |
| `pprof_py$breslow$negative_controls$shifted_tie$ci_upper` | numeric | 1 of 2 values differ; max abs 1.94e-16, max rel 5.7e-15 |
| `pprof_py$breslow$negative_controls$shifted_tie$coef` | numeric | 2 of 2 values differ; max abs 2.5e-16, max rel 1.67e-15 |
| `pprof_py$breslow$negative_controls$shifted_tie$covariance` | numeric | 2 of 3 values differ; max abs 3.04e-18, max rel 8.74e-16 |
| `pprof_py$breslow$negative_controls$shifted_tie$loglik` | numeric | 1 of 1 values differ; max abs 2.27e-13, max rel 3.34e-16 |
| `pprof_py$breslow$negative_controls$shifted_tie$p` | numeric | 2 of 2 values differ; max abs 9.02e-17, max rel 1.27e-14 |
| `pprof_py$breslow$negative_controls$shifted_tie$se` | numeric | 2 of 2 values differ; max abs 2.78e-17, max rel 4.71e-16 |
| `pprof_py$breslow$negative_controls$shifted_tie$z` | numeric | 2 of 2 values differ; max abs 3.11e-15, max rel 1.22e-15 |
| `pprof_py$breslow$residuals` | names | names differ |
| `pprof_py$breslow$residuals` | length | 9 vs 8 |
| `pprof_py$breslow$tests$exact$ci_lower` | numeric | 6 of 6 values differ; max abs 1.25e-14, max rel 1.48e-14 |
| `pprof_py$breslow$tests$exact$ci_upper` | numeric | 6 of 6 values differ; max abs 2.38e-14, max rel 1.47e-14 |
| `pprof_py$breslow$tests$exact$estimate` | numeric | 6 of 6 values differ; max abs 1.75e-14, max rel 1.48e-14 |
| `pprof_py$breslow$tests$exact$expected` | numeric | 6 of 6 values differ; max abs 4.97e-13, max rel 1.48e-14 |
| `pprof_py$breslow$tests$exact$p_value` | numeric | 6 of 6 values differ; max abs 4.97e-14, max rel 1.35e-13 |
| `pprof_py$breslow$tests$exact$z_raw` | numeric | 6 of 6 values differ; max abs 8.82e-14, max rel 1.84e-13 |
| `pprof_py$breslow$tests$midp$ci_lower` | numeric | 6 of 6 values differ; max abs 1.27e-14, max rel 1.47e-14 |
| `pprof_py$breslow$tests$midp$ci_upper` | numeric | 6 of 6 values differ; max abs 2.35e-14, max rel 1.47e-14 |
| `pprof_py$breslow$tests$midp$estimate` | numeric | 6 of 6 values differ; max abs 1.75e-14, max rel 1.48e-14 |
| `pprof_py$breslow$tests$midp$expected` | numeric | 6 of 6 values differ; max abs 4.97e-13, max rel 1.48e-14 |
| `pprof_py$breslow$tests$midp$p_value` | numeric | 6 of 6 values differ; max abs 4.83e-14, max rel 1.44e-13 |
| `pprof_py$breslow$tests$midp$z_raw` | numeric | 6 of 6 values differ; max abs 9.06e-14, max rel 1.49e-13 |
| `pprof_py$breslow$tight$ci_lower` | numeric | 2 of 2 values differ; max abs 2.78e-16, max rel 1.05e-15 |
| `pprof_py$breslow$tight$ci_upper` | numeric | 2 of 2 values differ; max abs 1.53e-16, max rel 4.51e-15 |
| `pprof_py$breslow$tight$coef` | numeric | 1 of 2 values differ; max abs 1.94e-16, max rel 1.3e-15 |
| `pprof_py$breslow$tight$covariance` | numeric | 3 of 3 values differ; max abs 4.77e-18, max rel 1.65e-15 |
| `pprof_py$breslow$tight$loglik` | numeric | 1 of 1 values differ; max abs 2.27e-13, max rel 3.34e-16 |
| `pprof_py$breslow$tight$p` | numeric | 2 of 2 values differ; max abs 6.77e-17, max rel 2.04e-14 |
| `pprof_py$breslow$tight$se` | numeric | 2 of 2 values differ; max abs 4.16e-17, max rel 7.05e-16 |
| `pprof_py$breslow$tight$z` | numeric | 2 of 2 values differ; max abs 3.55e-15, max rel 8.76e-16 |
| `pprof_py$efron$baseline$predictions$[[1]]$cumulative_hazard$[[1]]` | numeric | 19 of 19 values differ; max abs 6.54e-265, max rel 2.26e+39 |
| `pprof_py$efron$baseline$predictions$[[1]]$cumulative_hazard$[[2]]` | numeric | 19 of 19 values differ; max abs 7.91e-265, max rel 2.26e+39 |
| `pprof_py$efron$baseline$predictions$[[1]]$cumulative_hazard$[[3]]` | numeric | 19 of 19 values differ; max abs 4.3e-265, max rel 2.26e+39 |
| `pprof_py$efron$baseline$predictions$[[2]]$cumulative_hazard$[[1]]` | numeric | 15 of 15 values differ; max abs 4.54e-265, max rel 2.03e+39 |
| `pprof_py$efron$baseline$predictions$[[2]]$cumulative_hazard$[[2]]` | numeric | 15 of 15 values differ; max abs 5.5e-265, max rel 2.03e+39 |
| `pprof_py$efron$baseline$predictions$[[2]]$cumulative_hazard$[[3]]` | numeric | 15 of 15 values differ; max abs 2.98e-265, max rel 2.03e+39 |
| `pprof_py$efron$baseline$profiles$linear` | numeric | 2 of 3 values differ; max abs 5.55e-17, max rel 2.91e-16 |
| `pprof_py$efron$baseline$public_cumulative_hazard` | numeric | 111 of 111 values differ; max abs 7.36e-265, max rel 2.28e+39 |
| `pprof_py$efron$baseline$raw$cumulative_hazard` | numeric | 111 of 111 values differ; max abs 7.36e-265, max rel 2.28e+39 |
| `pprof_py$efron$beta_fixed$loglik` | numeric | 1 of 1 values differ; max abs 8.36e+04, max rel 0.889 |
| `pprof_py$efron$beta_fixed$score` | numeric | 1 of 2 values differ; max abs 0, max rel 0; NA pattern differs |
| `pprof_py$efron$beta_zero$information` | numeric | 2 of 3 values differ; max abs 2.56e-08, max rel 8.87e-11 |
| `pprof_py$efron$beta_zero$score` | numeric | 1 of 2 values differ; max abs 5.09e-11, max rel 6.08e-13 |
| `pprof_py$efron$default$ci_lower` | numeric | 2 of 2 values differ; max abs 5.55e-17, max rel 2.93e-16 |
| `pprof_py$efron$default$ci_upper` | numeric | 2 of 2 values differ; max abs 2.78e-16, max rel 2.53e-15 |
| `pprof_py$efron$default$coef` | numeric | 2 of 2 values differ; max abs 1.67e-16, max rel 5.46e-16 |
| `pprof_py$efron$default$covariance` | numeric | 3 of 3 values differ; max abs 5.64e-18, max rel 2.46e-15 |
| `pprof_py$efron$default$loglik` | numeric | 1 of 1 values differ; max abs 1.14e-13, max rel 1.69e-16 |
| `pprof_py$efron$default$p` | numeric | 2 of 2 values differ; max abs 5.03e-17, max rel 9.13e-15 |
| `pprof_py$efron$default$se` | numeric | 2 of 2 values differ; max abs 4.86e-17, max rel 8.23e-16 |
| `pprof_py$efron$default$z` | numeric | 2 of 2 values differ; max abs 1.78e-15, max rel 6.8e-16 |
| `pprof_py$efron$iterates$[[1]]$beta` | numeric | 2 of 2 values differ; max abs 1.11e-16, max rel 3.58e-16 |
| `pprof_py$efron$iterates$[[1]]$loglik` | numeric | 1 of 1 values differ; max abs 1.14e-13, max rel 1.69e-16 |
| `pprof_py$efron$iterates$[[2]]$beta` | numeric | 2 of 2 values differ; max abs 8.88e-16, max rel 5.78e-15 |
| `pprof_py$efron$iterates$[[2]]$loglik` | numeric | 1 of 1 values differ; max abs 1.14e-13, max rel 1.69e-16 |
| `pprof_py$efron$iterates$[[3]]$beta` | numeric | 2 of 2 values differ; max abs 1.67e-16, max rel 5.46e-16 |
| `pprof_py$efron$iterates$[[3]]$loglik` | numeric | 1 of 1 values differ; max abs 1.14e-13, max rel 1.69e-16 |
| `pprof_py$efron$iterates$[[4]]$beta` | numeric | 2 of 2 values differ; max abs 1.67e-16, max rel 5.46e-16 |
| `pprof_py$efron$iterates$[[4]]$loglik` | numeric | 1 of 1 values differ; max abs 1.14e-13, max rel 1.69e-16 |
| `pprof_py$efron$iterates$[[5]]$beta` | numeric | 2 of 2 values differ; max abs 1.67e-16, max rel 5.46e-16 |
| `pprof_py$efron$iterates$[[5]]$loglik` | numeric | 1 of 1 values differ; max abs 1.14e-13, max rel 1.69e-16 |
| `pprof_py$efron$measures$beta` | numeric | 2 of 2 values differ; max abs 1.67e-16, max rel 5.46e-16 |
| `pprof_py$efron$measures$direct_expected` | numeric | 6 of 6 values differ; max abs 1.28e-12, max rel 6.77e-15 |
| `pprof_py$efron$measures$direct_ratio` | numeric | 6 of 6 values differ; max abs 5.66e-15, max rel 6.69e-15 |
| `pprof_py$efron$measures$expected` | numeric | 6 of 6 values differ; max abs 2.91e-13, max rel 7.05e-15 |
| `pprof_py$efron$measures$indirect_ratio` | numeric | 6 of 6 values differ; max abs 6.11e-15, max rel 7.01e-15 |
| `pprof_py$efron$negative_controls$other_ties$ci_lower` | numeric | 2 of 2 values differ; max abs 2.78e-16, max rel 1.05e-15 |
| `pprof_py$efron$negative_controls$other_ties$ci_upper` | numeric | 2 of 2 values differ; max abs 1.53e-16, max rel 4.51e-15 |
| `pprof_py$efron$negative_controls$other_ties$coef` | numeric | 1 of 2 values differ; max abs 1.94e-16, max rel 1.3e-15 |
| `pprof_py$efron$negative_controls$other_ties$covariance` | numeric | 3 of 3 values differ; max abs 4.77e-18, max rel 1.65e-15 |
| `pprof_py$efron$negative_controls$other_ties$loglik` | numeric | 1 of 1 values differ; max abs 2.27e-13, max rel 3.34e-16 |
| `pprof_py$efron$negative_controls$other_ties$p` | numeric | 2 of 2 values differ; max abs 6.77e-17, max rel 2.04e-14 |
| `pprof_py$efron$negative_controls$other_ties$se` | numeric | 2 of 2 values differ; max abs 4.16e-17, max rel 7.05e-16 |
| `pprof_py$efron$negative_controls$other_ties$z` | numeric | 2 of 2 values differ; max abs 3.55e-15, max rel 8.76e-16 |
| `pprof_py$efron$negative_controls$shifted_tie$ci_lower` | numeric | 2 of 2 values differ; max abs 5e-16, max rel 1.85e-15 |
| `pprof_py$efron$negative_controls$shifted_tie$ci_upper` | numeric | 2 of 2 values differ; max abs 4.16e-16, max rel 1.08e-14 |
| `pprof_py$efron$negative_controls$shifted_tie$coef` | numeric | 2 of 2 values differ; max abs 4.44e-16, max rel 2.88e-15 |
| `pprof_py$efron$negative_controls$shifted_tie$covariance` | numeric | 2 of 3 values differ; max abs 1.3e-18, max rel 8.21e-16 |
| `pprof_py$efron$negative_controls$shifted_tie$loglik` | numeric | 1 of 1 values differ; max abs 2.27e-13, max rel 3.38e-16 |
| `pprof_py$efron$negative_controls$shifted_tie$p` | numeric | 2 of 2 values differ; max abs 1.7e-16, max rel 2.44e-14 |
| `pprof_py$efron$negative_controls$shifted_tie$se` | numeric | 1 of 2 values differ; max abs 1.39e-17, max rel 2.36e-16 |
| `pprof_py$efron$negative_controls$shifted_tie$z` | numeric | 2 of 2 values differ; max abs 6.66e-15, max rel 2.55e-15 |
| `pprof_py$efron$residuals` | names | names differ |
| `pprof_py$efron$residuals` | length | 9 vs 8 |
| `pprof_py$efron$tests$exact$ci_lower` | numeric | 6 of 6 values differ; max abs 4.33e-15, max rel 7.1e-15 |
| `pprof_py$efron$tests$exact$ci_upper` | numeric | 6 of 6 values differ; max abs 8.44e-15, max rel 7e-15 |
| `pprof_py$efron$tests$exact$estimate` | numeric | 6 of 6 values differ; max abs 6.11e-15, max rel 7.01e-15 |
| `pprof_py$efron$tests$exact$expected` | numeric | 6 of 6 values differ; max abs 2.91e-13, max rel 7.05e-15 |
| `pprof_py$efron$tests$exact$p_value` | numeric | 6 of 6 values differ; max abs 2.7e-14, max rel 5.88e-14 |
| `pprof_py$efron$tests$exact$z_raw` | numeric | 6 of 6 values differ; max abs 4.44e-14, max rel 6e-14 |
| `pprof_py$efron$tests$midp$ci_lower` | numeric | 6 of 6 values differ; max abs 4.44e-15, max rel 7.17e-15 |
| `pprof_py$efron$tests$midp$ci_upper` | numeric | 6 of 6 values differ; max abs 8.44e-15, max rel 7.07e-15 |
| `pprof_py$efron$tests$midp$estimate` | numeric | 6 of 6 values differ; max abs 6.11e-15, max rel 7.01e-15 |
| `pprof_py$efron$tests$midp$expected` | numeric | 6 of 6 values differ; max abs 2.91e-13, max rel 7.05e-15 |
| `pprof_py$efron$tests$midp$p_value` | numeric | 6 of 6 values differ; max abs 2.41e-14, max rel 5.84e-14 |
| `pprof_py$efron$tests$midp$z_raw` | numeric | 6 of 6 values differ; max abs 4.23e-14, max rel 5.16e-14 |
| `pprof_py$efron$tight$ci_lower` | numeric | 2 of 2 values differ; max abs 5.55e-17, max rel 2.93e-16 |
| `pprof_py$efron$tight$ci_upper` | numeric | 2 of 2 values differ; max abs 2.78e-16, max rel 2.53e-15 |
| `pprof_py$efron$tight$coef` | numeric | 2 of 2 values differ; max abs 1.67e-16, max rel 5.46e-16 |
| `pprof_py$efron$tight$covariance` | numeric | 3 of 3 values differ; max abs 5.64e-18, max rel 2.46e-15 |
| `pprof_py$efron$tight$loglik` | numeric | 1 of 1 values differ; max abs 1.14e-13, max rel 1.69e-16 |
| `pprof_py$efron$tight$p` | numeric | 2 of 2 values differ; max abs 5.03e-17, max rel 9.13e-15 |
| `pprof_py$efron$tight$se` | numeric | 2 of 2 values differ; max abs 4.86e-17, max rel 8.23e-16 |
| `pprof_py$efron$tight$z` | numeric | 2 of 2 values differ; max abs 1.78e-15, max rel 6.8e-16 |
| `survival$breslow$default$coef` | numeric | 1 of 2 values differ; max abs 5.55e-17, max rel 1.89e-16 |
| `survival$breslow$default$se` | numeric | 1 of 2 values differ; max abs 1.39e-17, max rel 2.35e-16 |
| `survival$breslow$default$covariance` | numeric | 2 of 3 values differ; max abs 1.73e-18, max rel 9.45e-16 |
| `survival$breslow$default$loglik` | numeric | 1 of 1 values differ; max abs 1.14e-12, max rel 1.67e-15 |
| `survival$breslow$tight$coef` | numeric | 1 of 2 values differ; max abs 5.55e-17, max rel 1.89e-16 |
| `survival$breslow$tight$se` | numeric | 1 of 2 values differ; max abs 1.39e-17, max rel 2.35e-16 |
| `survival$breslow$tight$covariance` | numeric | 2 of 3 values differ; max abs 1.73e-18, max rel 9.45e-16 |
| `survival$breslow$tight$loglik` | numeric | 1 of 1 values differ; max abs 1.14e-12, max rel 1.67e-15 |
| `survival$breslow$basehaz$hazard` | numeric | 136 of 137 values differ; max abs 2.82e-255, max rel 1.27e+53 |
| `survival$breslow$residuals$martingale` | numeric | 298 of 300 values differ; max abs 1.83e-13, max rel 4.93e-12 |
| `survival$breslow$residuals$score$[[1]]` | numeric | 296 of 300 values differ; max abs 7.96e-12, max rel 1.06e-10 |
| `survival$breslow$residuals$score$[[2]]` | numeric | 297 of 300 values differ; max abs 3.39e-13, max rel 1.16e-10 |
| `survival$breslow$residuals$dfbeta$[[1]]` | numeric | 298 of 300 values differ; max abs 2.77e-14, max rel 3.28e-10 |
| `survival$breslow$residuals$dfbeta$[[2]]` | numeric | 298 of 300 values differ; max abs 3.65e-15, max rel 2.59e-11 |
| `survival$breslow$residuals$robust_per_row` | numeric | 3 of 3 values differ; max abs 3.16e-16, max rel 5.5e-13 |
| `survival$breslow$residuals$robust_clustered` | numeric | 3 of 3 values differ; max abs 9.76e-16, max rel 1.6e-12 |
| `survival$breslow$residuals$naive_covariance` | numeric | 2 of 3 values differ; max abs 1.73e-18, max rel 9.45e-16 |
| `survival$breslow$expected$at_r_beta$row` | numeric | 300 of 300 values differ; max abs 2.49e-13, max rel 8.86e-14 |
| `survival$breslow$expected$at_r_beta$provider_expected` | numeric | 6 of 6 values differ; max abs 3.69e-13, max rel 1.1e-14 |
| `survival$breslow$expected$at_pprof_py_beta$row` | numeric | 300 of 300 values differ; max abs 2.85e-13, max rel 1.4e-13 |
| `survival$breslow$expected$at_pprof_py_beta$provider_expected` | numeric | 6 of 6 values differ; max abs 3.77e-13, max rel 9.12e-15 |
| `survival$breslow$beta_zero$score` | numeric | 1 of 2 values differ; max abs 3.18e-11, max rel 3.95e-13 |
| `survival$breslow$beta_fixed$loglik` | numeric | 1 of 1 values differ; max abs 2.39e-12, max rel 3.5e-15 |
| `survival$breslow$beta_fixed$score` | numeric | 2 of 2 values differ; max abs 1.17e-10, max rel 5.31e-12 |
| `survival$breslow$beta_fixed$information` | numeric | 2 of 3 values differ; max abs 1.14e-13, max rel 3.98e-16 |
| `survival$efron$default$coef` | numeric | 1 of 2 values differ; max abs 5.55e-17, max rel 3.61e-16 |
| `survival$efron$default$se` | numeric | 1 of 2 values differ; max abs 1.39e-17, max rel 2.36e-16 |
| `survival$efron$default$covariance` | numeric | 2 of 3 values differ; max abs 1.73e-18, max rel 9.37e-16 |
| `survival$efron$tight$coef` | numeric | 1 of 2 values differ; max abs 5.55e-17, max rel 3.61e-16 |
| `survival$efron$tight$se` | numeric | 1 of 2 values differ; max abs 1.39e-17, max rel 2.36e-16 |
| `survival$efron$tight$covariance` | numeric | 2 of 3 values differ; max abs 1.73e-18, max rel 9.37e-16 |
| `survival$efron$basehaz$hazard` | numeric | 136 of 137 values differ; max abs 7.36e-265, max rel 3.31e+43 |
| `survival$efron$residuals$martingale` | numeric | 257 of 300 values differ; max abs 1.55e-13, max rel 9.37e-13 |
| `survival$efron$residuals$score$[[1]]` | numeric | 296 of 300 values differ; max abs 1.35e-11, max rel 7.71e-10 |
| `survival$efron$residuals$score$[[2]]` | numeric | 226 of 300 values differ; max abs 1.74e-13, max rel 2.65e-13 |
| `survival$efron$residuals$dfbeta$[[1]]` | numeric | 298 of 300 values differ; max abs 4.71e-14, max rel 4.93e-10 |
| `survival$efron$residuals$dfbeta$[[2]]` | numeric | 298 of 300 values differ; max abs 6.27e-15, max rel 6.52e-11 |
| `survival$efron$residuals$robust_per_row` | numeric | 3 of 3 values differ; max abs 9.22e-16, max rel 2.82e-12 |
| `survival$efron$residuals$robust_clustered` | numeric | 3 of 3 values differ; max abs 2.35e-15, max rel 1.82e-12 |
| `survival$efron$residuals$naive_covariance` | numeric | 2 of 3 values differ; max abs 1.73e-18, max rel 9.37e-16 |
| `survival$efron$expected$at_r_beta$row` | numeric | 300 of 300 values differ; max abs 1.5e-13, max rel 1.12e-13 |
| `survival$efron$expected$at_r_beta$provider_expected` | numeric | 6 of 6 values differ; max abs 1.56e-13, max rel 3.41e-15 |
| `survival$efron$expected$at_pprof_py_beta$row` | numeric | 300 of 300 values differ; max abs 2.72e-13, max rel 2.14e-13 |
| `survival$efron$expected$at_pprof_py_beta$provider_expected` | numeric | 6 of 6 values differ; max abs 3.48e-13, max rel 1.04e-14 |
| `survival$efron$beta_zero$score` | numeric | 1 of 2 values differ; max abs 2.02e-10, max rel 2.42e-12 |
| `survival$efron$beta_zero$information` | numeric | 1 of 3 values differ; max abs 7.11e-15, max rel 1.87e-16 |
| `survival$efron$beta_fixed$loglik` | numeric | 1 of 1 values differ; max abs 1.59e-12, max rel 2.36e-15 |
| `survival$efron$beta_fixed$score` | numeric | 2 of 2 values differ; max abs 3.37e-10, max rel 1.77e-11 |
| `survival$efron$beta_fixed$information` | numeric | 2 of 3 values differ; max abs 2.84e-13, max rel 9.89e-16 |

### lt-weights-offset

| Path | Kind | Detail |
|---|---|---|
| `survival$breslow$expected$at_r_beta$row` | numeric | 175 of 600 values differ; max abs 1.78e-15, max rel 1.16e-14 |
| `survival$breslow$expected$at_r_beta$provider_expected` | numeric | 6 of 10 values differ; max abs 7.11e-15, max rel 2.37e-16 |
| `survival$breslow$expected$at_pprof_py_beta$row` | numeric | 247 of 600 values differ; max abs 8.88e-16, max rel 1.33e-14 |
| `survival$breslow$expected$at_pprof_py_beta$provider_expected` | numeric | 8 of 10 values differ; max abs 7.11e-15, max rel 2.31e-16 |
| `survival$efron$expected$at_r_beta$row` | numeric | 172 of 600 values differ; max abs 2.66e-15, max rel 1.42e-14 |
| `survival$efron$expected$at_r_beta$provider_expected` | numeric | 6 of 10 values differ; max abs 7.11e-15, max rel 2.08e-16 |
| `survival$efron$expected$at_pprof_py_beta$row` | numeric | 351 of 600 values differ; max abs 1.78e-15, max rel 1.36e-14 |
| `survival$efron$expected$at_pprof_py_beta$provider_expected` | numeric | 10 of 10 values differ; max abs 2.13e-14, max rel 4.82e-16 |

### provider-scale

| Path | Kind | Detail |
|---|---|---|
| `survival$breslow$expected$at_r_beta$row` | numeric | 3334 of 20000 values differ; max abs 3.55e-15, max rel 6.64e-14 |
| `survival$breslow$expected$at_r_beta$provider_expected` | numeric | 497 of 1000 values differ; max abs 7.11e-15, max rel 7.46e-16 |
| `survival$breslow$expected$at_pprof_py_beta$row` | numeric | 3321 of 20000 values differ; max abs 7.11e-15, max rel 9.21e-14 |
| `survival$breslow$expected$at_pprof_py_beta$provider_expected` | numeric | 480 of 1000 values differ; max abs 8.88e-15, max rel 5.64e-16 |
| `survival$efron$expected$at_r_beta$row` | numeric | 3835 of 20000 values differ; max abs 5.33e-15, max rel 9.45e-14 |
| `survival$efron$expected$at_r_beta$provider_expected` | numeric | 585 of 1000 values differ; max abs 1.07e-14, max rel 8.78e-16 |
| `survival$efron$expected$at_pprof_py_beta$row` | numeric | 8550 of 20000 values differ; max abs 7.11e-15, max rel 8.64e-14 |
| `survival$efron$expected$at_pprof_py_beta$provider_expected` | numeric | 769 of 1000 values differ; max abs 2.31e-14, max rel 1.59e-15 |

### rc-stratified-weights-offset

| Path | Kind | Detail |
|---|---|---|
| `survival$breslow$expected$at_r_beta$row` | numeric | 166 of 600 values differ; max abs 4.44e-16, max rel 4.29e-15 |
| `survival$breslow$expected$at_r_beta$provider_expected` | numeric | 4 of 25 values differ; max abs 3.55e-15, max rel 2.05e-16 |
| `survival$breslow$expected$at_pprof_py_beta$row` | numeric | 223 of 600 values differ; max abs 8.88e-16, max rel 1.73e-15 |
| `survival$breslow$expected$at_pprof_py_beta$provider_expected` | numeric | 11 of 25 values differ; max abs 3.55e-15, max rel 2.17e-16 |
| `survival$efron$expected$at_r_beta$row` | numeric | 239 of 600 values differ; max abs 1.78e-15, max rel 1.01e-15 |
| `survival$efron$expected$at_r_beta$provider_expected` | numeric | 17 of 25 values differ; max abs 3.55e-15, max rel 2.16e-16 |
| `survival$efron$expected$at_pprof_py_beta$row` | numeric | 293 of 600 values differ; max abs 8.88e-16, max rel 1.05e-15 |
| `survival$efron$expected$at_pprof_py_beta$provider_expected` | numeric | 11 of 25 values differ; max abs 3.55e-15, max rel 2.31e-16 |

### rc-unstratified

| Path | Kind | Detail |
|---|---|---|
| `survival$breslow$expected$at_r_beta$row` | numeric | 116 of 400 values differ; max abs 4.44e-16, max rel 1.35e-15 |
| `survival$breslow$expected$at_r_beta$provider_expected` | numeric | 2 of 10 values differ; max abs 3.55e-15, max rel 1.31e-16 |
| `survival$breslow$expected$at_pprof_py_beta$row` | numeric | 113 of 400 values differ; max abs 4.44e-16, max rel 1.43e-15 |
| `survival$breslow$expected$at_pprof_py_beta$provider_expected` | numeric | 2 of 10 values differ; max abs 7.11e-15, max rel 2.01e-16 |
| `survival$efron$expected$at_r_beta$row` | numeric | 111 of 400 values differ; max abs 4.44e-16, max rel 1.77e-15 |
| `survival$efron$expected$at_r_beta$provider_expected` | numeric | 1 of 10 values differ; max abs 3.55e-15, max rel 1.17e-16 |
| `survival$efron$expected$at_pprof_py_beta$row` | numeric | 109 of 400 values differ; max abs 1.33e-15, max rel 1.43e-15 |
| `survival$efron$expected$at_pprof_py_beta$provider_expected` | numeric | 4 of 10 values differ; max abs 3.55e-15, max rel 1.3e-16 |

### recurrent

| Path | Kind | Detail |
|---|---|---|
| `survival$breslow$expected$at_r_beta$row` | numeric | 258 of 506 values differ; max abs 1.78e-15, max rel 2.87e-14 |
| `survival$breslow$expected$at_r_beta$provider_expected` | numeric | 10 of 12 values differ; max abs 7.11e-15, max rel 3.29e-16 |
| `survival$breslow$expected$at_pprof_py_beta$row` | numeric | 166 of 506 values differ; max abs 8.88e-16, max rel 2.32e-14 |
| `survival$breslow$expected$at_pprof_py_beta$provider_expected` | numeric | 5 of 12 values differ; max abs 7.11e-15, max rel 3.29e-16 |
| `survival$efron$expected$at_r_beta$row` | numeric | 264 of 506 values differ; max abs 1.78e-15, max rel 3.06e-14 |
| `survival$efron$expected$at_r_beta$provider_expected` | numeric | 11 of 12 values differ; max abs 7.11e-15, max rel 2.75e-16 |
| `survival$efron$expected$at_pprof_py_beta$row` | numeric | 186 of 506 values differ; max abs 8.88e-16, max rel 3.19e-14 |
| `survival$efron$expected$at_pprof_py_beta$provider_expected` | numeric | 11 of 12 values differ; max abs 7.11e-15, max rel 2.95e-16 |

### zero-weights

| Path | Kind | Detail |
|---|---|---|
| `survival$breslow$expected$at_r_beta$row` | numeric | 310 of 600 values differ; max abs 8.88e-16, max rel 1.4e-15 |
| `survival$breslow$expected$at_r_beta$provider_expected` | numeric | 15 of 25 values differ; max abs 3.55e-15, max rel 2.16e-16 |
| `survival$breslow$expected$at_pprof_py_beta$row` | numeric | 320 of 600 values differ; max abs 1.33e-15, max rel 1.96e-15 |
| `survival$breslow$expected$at_pprof_py_beta$provider_expected` | numeric | 13 of 25 values differ; max abs 3.55e-15, max rel 2.16e-16 |
| `survival$efron$expected$at_r_beta$row` | numeric | 177 of 600 values differ; max abs 8.88e-16, max rel 1.35e-15 |
| `survival$efron$expected$at_r_beta$provider_expected` | numeric | 5 of 25 values differ; max abs 3.55e-15, max rel 2.17e-16 |
| `survival$efron$expected$at_pprof_py_beta$row` | numeric | 530 of 600 values differ; max abs 2.22e-15, max rel 2.83e-15 |
| `survival$efron$expected$at_pprof_py_beta$provider_expected` | numeric | 25 of 25 values differ; max abs 1.42e-14, max rel 6.39e-16 |

