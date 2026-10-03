# models, summaries, and results print compactly

    Code
      print(fit)
    Output
      <pprof model: logistic_fe (serbin)>
      1,560 observations of 20 providers
      Converged after 5 iterations (stop rule "any", tol 1e-05)
      Coefficients:
          z1     z2     z3     z4     z5 
      1.0960 0.9819 1.0070 0.9841 0.9944 
    Code
      print(summary(fit))
    Output
      <pprof summary: logistic_fe (serbin)>
      1,560 observations of 20 providers
      Coefficients with Wald tests and 95% intervals:
       term estimate std_error statistic p_value  lower upper
         z1   1.0960   0.08931     12.28 < 1e-10 0.9213 1.271
         z2   0.9819   0.08879     11.06 < 1e-10 0.8079 1.156
         z3   1.0070   0.08664     11.63 < 1e-10 0.8375 1.177
         z4   0.9841   0.08803     11.18 < 1e-10 0.8116 1.157
         z5   0.9944   0.09049     10.99 < 1e-10 0.8170 1.172
      log-likelihood -590.692, AIC 1231.38, BIC 1365.2, AUC 0.904787
    Code
      print(test_providers(fit), n = 3)
    Output
      <pprof provider tests: exact, two.sided, level 95%, null -0.8613> flags: 1 higher, 16 as expected, 3 lower
       provider_id n_obs statistic p_value flag
                 1    78   -1.2670  0.2052    0
                 2    50    0.5323  0.5945    0
                 3   103   -1.3030  0.1926    0
      ... 17 more rows
    Code
      print(provider_effects(fit, "score"), n = 3)
    Output
      <pprof provider effects: score intervals at 95%>
       provider_id n_obs estimate std_error  lower   upper
                 1    78  -1.3110    0.3577 -2.000 -0.6214
                 2    50  -0.6506    0.3964 -1.417  0.1177
                 3   103  -1.2550    0.3054 -1.844 -0.6667
      ... 17 more rows
    Code
      print(standardize_providers(fit, c("indirect", "direct"), interval = "score"),
      n = 3)
    Output
      <pprof standardized measures: indirect, direct; ratio, rate, null -0.8613; score intervals at 95%>
       provider_id standardization measure n_obs observed expected variance estimate
                 1        indirect   ratio    78       31    34.66    8.184   0.8945
                 2        indirect   ratio    50       16    14.67    6.244   1.0910
                 3        indirect   ratio   103       35    39.44   11.460   0.8875
        lower upper
       0.7362 1.057
       0.7750 1.438
       0.7290 1.057
      ... 77 more rows
    Code
      print(funnel_limits(fit, c(0.95, 0.99)), n = 3)
    Output
      <pprof funnel limits: ratio, target 1, at 95%, 99%>
       level precision  lower upper
        0.95     34.44 0.6660 1.334
        0.95     66.94 0.7604 1.240
        0.95     67.89 0.7621 1.238
      ... 37 more rows
    Code
      print(profile_providers(fit), n = 3)
    Output
      <pprof provider profile: exact test, level 95%, null -0.8613> flags: 1 higher, 16 as expected, 3 lower
       provider_id n_obs observed expected statistic p_value flag
                 1    78       31    34.66   -1.2670  0.2052    0
                 2    50       16    14.67    0.5323  0.5945    0
                 3   103       35    39.44   -1.3030  0.1926    0
      ... 17 more rows
    Code
      print(test_coefficients(fit))
    Output
      <pprof coefficient tests: wald>
       term estimate std_error statistic p_value  lower upper
         z1   1.0960   0.08931     12.28 < 1e-10 0.9213 1.271
         z2   0.9819   0.08879     11.06 < 1e-10 0.8079 1.156
         z3   1.0070   0.08664     11.63 < 1e-10 0.8375 1.177
         z4   0.9841   0.08803     11.18 < 1e-10 0.8116 1.157
         z5   0.9944   0.09049     10.99 < 1e-10 0.8170 1.172

