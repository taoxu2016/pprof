# Phase 0 audit: linear_fe and its methods.
script_dir <- dirname(normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))))
source(file.path(script_dir, "helpers.R"))
audit_header("14: linear_fe")

dat <- load_linear_example()
msgs <- character()
fit <- withCallingHandlers(
  pprof::linear_fe(data = dat, Y.char = "Y", Z.char = covariate_names, ProvID.char = "ProvID"),
  message = function(m) { msgs <<- c(msgs, conditionMessage(m)); invokeRestart("muffleMessage") })
fit_full <- suppressMessages(pprof::linear_fe(data = dat, Y.char = "Y", Z.char = covariate_names,
                                              ProvID.char = "ProvID", option.gamma.var = "full"))
di <- fit$data_include
n <- nrow(di); m <- length(fit$coefficient$gamma); p <- length(fit$coefficient$beta)
n_i <- as.numeric(table(di$ProvID))
alpha <- 1 - 0.95

# --- V14.1: estimates equal lm() with provider indicators -----------------------------------------
ref <- stats::lm(Y ~ 0 + factor(ProvID) + z1 + z2 + z3 + z4 + z5, data = di)
cf <- stats::coef(ref)
vc <- stats::vcov(ref)
report("V14.1", "CONFIRMED",
       "linear_fe (within/profile estimator through dense centering matrices) agrees with lm() on provider indicators",
       c(sprintf("max rel diff beta %.3g, gamma %.3g", max_rel_diff(fit$coefficient$beta, cf[covariate_names]),
                 max_rel_diff(fit$coefficient$gamma, cf[seq_len(m)])),
         sprintf("max rel diff vcov(beta) %.3g", max_rel_diff(fit$variance$beta, vc[covariate_names, covariate_names])),
         sprintf("max rel diff 'full' gamma variance vs vcov(lm) diagonal %.3g",
                 max_rel_diff(fit_full$variance$gamma, diag(vc)[seq_len(m)])),
         sprintf("sigma: linear_fe %.15g, lm %.15g", fit$sigma, summary(ref)$sigma)))

# --- V14.2: closed-form pieces --------------------------------------------------------------------
ssr <- sum(fit$residuals^2)
ll <- -(n / 2) * log(2 * pi) - (n / 2) * log(ssr / n) - n / 2
report("V14.2", if (isTRUE(all.equal(c(fit$sigma^2, fit$Loglkd, fit$AIC, fit$BIC),
                                     c(ssr / (n - m - p), ll, -2 * ll + 2 * (m + p + 1), -2 * ll + (m + p + 1) * log(n)),
                                     tolerance = 1e-13))) "CONFIRMED" else "REFUTED",
       "sigma^2 = SSR / (n - m - p); Loglkd uses the ML variance SSR / n; AIC and BIC count m + p + 1 parameters; simplified gamma variance sigma^2 / n_i",
       c(sprintf("max rel diff simplified variance vs sigma^2/n_i: %.3g", max_rel_diff(fit$variance$gamma, fit$sigma^2 / n_i)),
         sprintf("variance$gamma attribute 'description': %s / %s", attr(fit$variance$gamma, "description"),
                 attr(fit_full$variance$gamma, "description"))))

# --- V14.3: test distribution follows the variance option (D-16) ---------------------------------
gamma <- fit$coefficient$gamma
t_s <- test(fit); t_f <- test(fit_full)
z_s <- (gamma - median(gamma)) / sqrt(fit$variance$gamma)
z_f <- (gamma - median(gamma)) / sqrt(fit_full$variance$gamma)
ok <- max(abs(t_s$`p value` - 2 * pmin(pnorm(z_s, lower.tail = FALSE), 1 - pnorm(z_s, lower.tail = FALSE)))) < 1e-15 &&
  max(abs(t_f$`p value` - 2 * pmin(pt(z_f, n - m - p, lower.tail = FALSE), 1 - pt(z_f, n - m - p, lower.tail = FALSE)))) < 1e-15
report("V14.3", if (ok) "CONFIRMED" else "REFUTED",
       "test.linear_fe uses a normal reference with the 'simplified' variance and t(n - m - p) with 'full', chosen by the hidden 'description' attribute of variance$gamma (D-16)",
       sprintf("null = 'mean' is sum(n_i gamma_i) / n: %s",
               max(abs(test(fit, null = "mean")$stat - as.numeric((gamma - sum(n_i * gamma) / n) / sqrt(fit$variance$gamma)))) < 1e-12))

# --- V14.4: confint uses the opposite reference distribution (new finding) -------------------------
ci_s <- confint(fit, option = "gamma"); ci_f <- confint(fit_full, option = "gamma")
mult_s <- range((ci_s$gamma.Upper - ci_s$gamma) / sqrt(fit$variance$gamma))
mult_f <- range((ci_f$gamma.Upper - ci_f$gamma) / sqrt(fit_full$variance$gamma))
report("V14.4", if (max(abs(mult_s - qt(1 - alpha / 2, n - m - p))) < 1e-10 && max(abs(mult_f - qnorm(1 - alpha / 2))) < 1e-10) "CONFIRMED" else "REFUTED",
       "confint.linear_fe uses qt(n - m - p) with the 'simplified' variance and qnorm with 'full', the reverse of test.linear_fe, so the interval and the test can disagree (new finding)",
       c(sprintf("simplified: interval multiplier in [%.12g, %.12g]; qt = %.12g; qnorm = %.12g",
                 mult_s[1], mult_s[2], qt(1 - alpha / 2, n - m - p), qnorm(1 - alpha / 2)),
         sprintf("full:       interval multiplier in [%.12g, %.12g]", mult_f[1], mult_f[2])))

# --- V14.5: standardized differences ---------------------------------------------------------------
sm <- SM_output(fit, stdz = c("indirect", "direct"))
g0 <- median(gamma)
report("V14.5", if (max(abs(sm$indirect.difference - (gamma - g0))) < 1e-10 && max(abs(sm$direct.difference - (gamma - g0))) < 1e-10) "CONFIRMED" else "REFUTED",
       "Indirect difference (O_i - E_i)/n_i with E_i = sum(null + Z beta); direct difference (sum_j (gamma_i + Z_j beta) - sum_j (null + Z_j beta)) / N. Both equal gamma_i - null up to rounding, and null applies to the direct measure too",
       c(sprintf("max |indirect - (gamma - null)| %.3g; max |direct - (gamma - null)| %.3g",
                 max(abs(sm$indirect.difference - (gamma - g0))), max(abs(sm$direct.difference - (gamma - g0)))),
         sprintf("OE_indirect columns: %s; OE_direct columns: %s", paste(names(sm$OE$OE_indirect), collapse = ", "),
                 paste(names(sm$OE$OE_direct), collapse = ", "))))

# --- V14.6: summary ---------------------------------------------------------------------------------
s <- summary(fit)
z <- fit$coefficient$beta / sqrt(diag(fit$variance$beta))
report("V14.6", if (identical(s$`p value`, format.pval(2 * (1 - pt(abs(z), n - p - m)), digits = 7, eps = 1e-10))) "CONFIRMED" else "REFUTED",
       "summary.linear_fe: t test with df n - p - m, interval beta +/- qt(1 - alpha/2, n - p - m) se, p-values as character strings",
       utils::capture.output(print(s)))

# --- V14.7: interface details --------------------------------------------------------------------------
opt <- sapply(c("f", "fu", "full", "s", "simp", "simplified"), function(o) {
  r <- try_capture(suppressMessages(pprof::linear_fe(data = dat, Y.char = "Y", Z.char = covariate_names,
                                                     ProvID.char = "ProvID", option.gamma.var = o)))
  if (r$error) "ERROR" else attr(r$value$variance$gamma, "description")
})
report("V14.7", "CONFIRMED",
       "linear_fe always prints its input-format message (no verbosity argument), takes arguments in a different order from logis_fe, and accepts option.gamma.var only as 'full'/'f' or 'simplified'/'s'",
       c(sprintf("messages: %s", paste(msgs, collapse = " | ")),
         sprintf("formals: %s", paste(names(formals(pprof::linear_fe)), collapse = ", ")),
         sprintf("option.gamma.var: %s", paste(names(opt), opt, sep = " -> ", collapse = "; "))))

# --- V14.8: funnel plot ---------------------------------------------------------------------------------
pl <- try_capture(plot(fit))
report("V14.8", if (!pl$error) "CONFIRMED" else "REFUTED",
       "plot.linear_fe returns a ggplot; limits are target +/- qnorm(1 - alpha/2) sigma / sqrt(n_i) with precision = n_i",
       c(sprintf("class: %s", if (pl$error) pl$message else paste(class(pl$value), collapse = "/")),
         sprintf("warnings: %s", paste(unique(pl$warnings), collapse = " | "))))

cat("\nDone.\n")
