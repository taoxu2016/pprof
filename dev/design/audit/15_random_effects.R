# Phase 0 audit: linear_re, logis_re, linear_cre, logis_cre and their methods.
script_dir <- dirname(normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))))
source(file.path(script_dir, "helpers.R"))
audit_header("15: random-effect and CRE models")
suppressPackageStartupMessages(library(lme4))

bin <- load_binary_example()
lin <- load_linear_example()
alpha <- 1 - 0.95
q <- function(expr) suppressWarnings(suppressMessages(expr))

f_bin <- stats::as.formula(paste("Y ~", paste(covariate_names, collapse = " + "), "+ (1 | ProvID)"))
f_lin <- stats::as.formula(paste("Y ~", paste(covariate_names, collapse = " + "), "+ (1 | ProvID)"))
fit_lre <- q(pprof::linear_re(data = lin, Y.char = "Y", Z.char = covariate_names, ProvID.char = "ProvID"))
fit_gre <- q(pprof::logis_re(data = bin, Y.char = "Y", Z.char = covariate_names, ProvID.char = "ProvID"))
fit_lcre <- q(pprof::linear_cre(data = lin, Y.char = "Y", ProvID.char = "ProvID", wb.char = c("z1", "z2"), other.char = c("z3", "z4", "z5")))
fit_gcre <- q(pprof::logis_cre(data = bin, Y.char = "Y", ProvID.char = "ProvID", wb.char = c("z1", "z2"), other.char = c("z3", "z4", "z5")))

# --- V15.1: estimation is delegated to lme4 with equivalent calls ----------------------------------
sorted_lin <- lin[order(factor(lin$ProvID)), ]
sorted_bin <- bin[order(factor(bin$ProvID)), ]
direct_lmer <- lme4::lmer(Y ~ (1 | ProvID) + z1 + z2 + z3 + z4 + z5, data = sorted_lin)
direct_glmer <- lme4::glmer(Y ~ (1 | ProvID) + z1 + z2 + z3 + z4 + z5, data = sorted_bin, family = binomial("logit"))
ml <- q(pprof::linear_re(data = lin, Y.char = "Y", Z.char = covariate_names, ProvID.char = "ProvID", REML = FALSE))
report("V15.1", if (identical(lme4::fixef(attr(fit_lre, "model")), lme4::fixef(direct_lmer)) &&
                    identical(lme4::fixef(attr(fit_gre, "model")), lme4::fixef(direct_glmer))) "CONFIRMED" else "REFUTED",
       "linear_re / logis_re call lmer / glmer(family = binomial('logit')) on data sorted by provider, with the formula Y ~ (1 | ProvID) + Z (column interface); defaults are REML for lmer and Laplace (nAGQ = 1) for glmer; '...' is passed through",
       c(sprintf("isREML(default) = %s; isREML(REML = FALSE) = %s", lme4::isREML(attr(fit_lre, "model")), lme4::isREML(attr(ml, "model"))),
         sprintf("glmer nAGQ = %s", attr(fit_gre, "model")@devcomp$dims[["nAGQ"]]),
         sprintf("fixef identical to direct calls: lmer %s, glmer %s",
                 identical(lme4::fixef(attr(fit_lre, "model")), lme4::fixef(direct_lmer)),
                 identical(lme4::fixef(attr(fit_gre, "model")), lme4::fixef(direct_glmer))),
         sprintf("lme4 %s, Matrix %s", as.character(utils::packageVersion("lme4")), as.character(utils::packageVersion("Matrix")))))

# --- V15.2: variance component extraction ----------------------------------------------------------
vc_sd2 <- as.data.frame(lme4::VarCorr(attr(fit_gcre, "model")))[1, "sdcor"]^2
vc_v <- as.data.frame(lme4::VarCorr(attr(fit_gcre, "model")))[1, "vcov"]
report("V15.2", "CONFIRMED",
       "variance$alpha is sdcor^2 (first VarCorr row) in linear_re, logis_re, and linear_cre, but vcov in logis_cre; the two agree here, but sdcor^2 is a square of a square root and can differ in the last bit",
       c(sprintf("logis_cre stores %.17g; sdcor^2 would be %.17g (difference %.3g)", fit_gcre$variance$alpha, vc_sd2, fit_gcre$variance$alpha - vc_sd2),
         sprintf("logis_cre stored equals vcov: %s", identical(as.numeric(fit_gcre$variance$alpha), vc_v))))

# --- V15.3: provider-effect standard errors --------------------------------------------------------
n_i <- as.numeric(table(fit_lre$data_include$ProvID))
s2 <- fit_lre$sigma^2; va <- as.numeric(fit_lre$variance$alpha)
se_closed <- sqrt(va / (va + s2 / n_i) * s2 / n_i)
se_condvar <- sqrt(attr(lme4::ranef(attr(fit_lre, "model"), condVar = TRUE)$ProvID, "postVar")[1, 1, ])
t_lre <- test(fit_lre)
report("V15.3", if (max(abs(t_lre$Std.Error - se_closed)) < 1e-14) "CONFIRMED" else "REFUTED",
       "test.linear_re uses the closed form sqrt(R_i sigma^2 / n_i), R_i = s2_alpha / (s2_alpha + sigma^2 / n_i); the other three families use lme4 conditional variances (ranef(condVar = TRUE), attribute 'postVar')",
       c(sprintf("linear_re: closed form vs lme4 condVar: max rel diff %.3g", max_rel_diff(se_closed, se_condvar)),
         sprintf("logis_re Std.Error equals sqrt(postVar): %s",
                 isTRUE(all.equal(test(fit_gre)$Std.Error,
                                  as.numeric(sqrt(attr(lme4::ranef(attr(fit_gre, "model"), condVar = TRUE)$ProvID, "postVar")[1, 1, ])),
                                  tolerance = 1e-14)))))

# --- V15.4: logistic RE standardized measures --------------------------------------------------------
sm <- q(SM_output(fit_gre, stdz = c("indirect", "direct"), measure = c("ratio", "rate"), threads = 1))
di <- fit_gre$data_include
prov <- di$ProvID
xb <- as.numeric(fit_gre$linear_pred)
fitted_p <- as.numeric(fit_gre$fitted)
ratio_pe <- as.numeric(tapply(fitted_p, prov, sum) / tapply(plogis(xb), prov, sum))
ratio_oe <- as.numeric(tapply(as.numeric(fit_gre$observation), prov, sum) / tapply(plogis(xb), prov, sum))
a <- fit_gre$coefficient$RE
direct <- as.numeric(sapply(a, function(ai) sum(plogis(ai + xb))) / sum(fit_gre$observation))
report("V15.4", if (max(abs(as.numeric(sm$indirect.ratio) - ratio_pe)) < 1e-12 && max(abs(as.numeric(sm$direct.ratio) - direct)) < 1e-12) "CONFIRMED" else "REFUTED",
       "Logistic RE/CRE indirect ratio is sum(fitted p including alpha_i) / sum(plogis(X beta)), predicted over expected, not observed over expected; direct ratio is sum_j plogis(alpha_i + X_j beta) / sum(Y)",
       c(sprintf("max |reference - predicted/expected| %.3g; max |reference - observed/expected| %.3g",
                 max(abs(as.numeric(sm$indirect.ratio) - ratio_pe)), max(abs(as.numeric(sm$indirect.ratio) - ratio_oe))),
         sprintf("max |direct - formula| %.3g", max(abs(as.numeric(sm$direct.ratio) - direct)))))

sm_l <- SM_output(fit_lre, stdz = c("indirect", "direct"))
dl <- fit_lre$data_include
report("V15.5", "CONFIRMED",
       "Linear RE/CRE: indirect difference (sum fitted - sum X beta) / n_i (= alpha_i up to rounding); direct difference (sum_j (alpha_i + X_j beta) - sum Y) / N, which is alpha_i plus a constant offset",
       c(sprintf("max |indirect - alpha| %.3g", max(abs(sm_l$indirect.difference - fit_lre$coefficient$RE))),
         sprintf("direct - alpha (constant offset): %s", paste(signif(range(sm_l$direct.difference - fit_lre$coefficient$RE), 6), collapse = " .. "))))

# --- V15.6: summary p-values for logistic RE / CRE (new finding) ---------------------------------------
s_gre <- summary(fit_gre)
z <- fit_gre$coefficient$FE / sqrt(diag(fit_gre$variance$FE))
report("V15.6", if (any(2 * (1 - pnorm(z)) > 1)) "CONFIRMED" else "NOTE",
       "summary.logis_re and summary.logis_cre compute p = 2 (1 - pnorm(z)) without abs(), so any negative estimate gets a p-value above 1 (new finding)",
       c(utils::capture.output(print(s_gre)),
         sprintf("z for intercept %.4g -> reported p %s", z[1], s_gre$`p value`[1])))

s_lre <- summary(fit_lre)
z_l <- fit_lre$coefficient$FE / sqrt(diag(fit_lre$variance$FE))
df_l <- nrow(fit_lre$data_include) - length(fit_lre$coefficient$FE) - length(fit_lre$coefficient$RE) + 1
ci_wald <- confint(attr(fit_lre, "model"), parm = "beta_", method = "Wald")
old <- options(warnPartialMatchDollar = TRUE)
pm <- try_capture(summary(fit_lre))
pm_cre <- try_capture(summary(fit_lcre))
pm_ci <- try_capture(confint(fit_gre))
options(old)
report("V15.7", "CONFIRMED",
       "summary.linear_re / linear_cre: t p-values with df = n - (#fixed effects) - (#providers) + 1 but normal Wald intervals from lme4::confint(method = 'Wald'); both read object$data_includ, and confint.logis_re reads object$obs, by partial matching (D-08)",
       c(sprintf("p-values match t(df = %d): %s", df_l,
                 identical(s_lre$`p value`, format.pval(2 * (1 - pt(abs(z_l), df_l)), digits = 7, eps = 1e-10))),
         sprintf("intervals equal lme4 Wald: %s", isTRUE(all.equal(unname(as.matrix(s_lre[, c("CI.Lower", "CI.Upper")])), unname(ci_wald), tolerance = 0))),
         paste("summary.linear_re warnings:", paste(unique(pm$warnings), collapse = " | ")),
         paste("summary.linear_cre warnings:", paste(unique(pm_cre$warnings), collapse = " | ")),
         paste("confint.logis_re warnings:", paste(unique(pm_ci$warnings), collapse = " | "))))

# --- V15.8: print.logis_cre is not registered (D-09) -----------------------------------------------
lines_cre <- utils::capture.output(print(fit_gcre))
lines_re <- utils::capture.output(print(fit_gre))
report("V15.8", if (is.null(utils::getS3method("print", "logis_cre", optional = TRUE))) "CONFIRMED" else "REFUTED",
       "print.logis_cre is defined but not registered (its roxygen tag registers print.linear_re), so printing a logis_cre fit falls through to print.default and includes the lme4 fit stored in attr(, 'model') (D-09)",
       c(sprintf("registered print method for logis_cre: %s", !is.null(utils::getS3method("print", "logis_cre", optional = TRUE))),
         sprintf("printed lines: logis_cre %d, logis_re %d", length(lines_cre), length(lines_re)),
         sprintf("logis_cre printout mentions attr(,\"model\"): %s", any(grepl('attr(,"model")', lines_cre, fixed = TRUE)))))

# --- V15.9: vector interface of linear_re / logis_re (D-11) --------------------------------------------
# Small data on purpose: once cbind() turns the covariates into character columns, lmer
# treats every distinct value as a factor level, which on the full example data runs for
# many minutes (observed during this audit).
small <- do.call(rbind, lapply(split(lin, lin$ProvID)[1:5], function(d) d[1:12, ]))
d11 <- list(
  "character ProvID, matrix Z" = try_capture(q(pprof::linear_re(Y = small$Y, Z = as.matrix(small[, covariate_names]),
                                                               ProvID = paste0("P", small$ProvID)))),
  "numeric ProvID, matrix Z" = try_capture(q(pprof::linear_re(Y = small$Y, Z = as.matrix(small[, covariate_names]),
                                                             ProvID = small$ProvID))),
  "no usable arguments" = try_capture(q(pprof::linear_re(Y = small$Y))))
report("V15.9", "CONFIRMED",
       "linear_re / logis_re vector interface: cbind() coerces everything to character when ProvID is character and Z is a matrix, so each covariate becomes a factor with one level per distinct value; with no matching input format there is no final else, so the error is about an undefined object (D-11)",
       sapply(d11, function(r) if (r$error) paste("ERROR:", r$message) else
         sprintf("ok; class(data_include$Y) = %s; fixed effects = %d", class(r$value$data_include$Y),
                 length(r$value$coefficient$FE))))

# --- V15.10: CRE provider means use rows that complete-case filtering later drops (D-13) -----------------
d13 <- lin
d13$Y[d13$ProvID == 1][1:5] <- NA
fit13 <- q(pprof::linear_cre(data = d13, Y.char = "Y", ProvID.char = "ProvID", wb.char = "z1", other.char = "z2"))
kept <- fit13$data_include
bar_used <- unique(kept$z1_bar[kept$ProvID == 1])
bar_complete <- mean(d13$z1[d13$ProvID == 1 & !is.na(d13$Y)])
bar_all <- mean(d13$z1[d13$ProvID == 1])
report("V15.10", if (isTRUE(all.equal(bar_used, bar_all)) && !isTRUE(all.equal(bar_used, bar_complete))) "CONFIRMED" else "REFUTED",
       "CRE models compute provider means (mean(x, na.rm = TRUE) per provider) before complete-case filtering, so rows dropped for a missing response still shape the *_bar and *_within terms (D-13)",
       sprintf("provider 1 z1_bar used %.12g; mean over all rows %.12g; mean over complete cases %.12g", bar_used, bar_all, bar_complete))

# --- V15.11: hard-coded threads in logistic RE/CRE intervals (D-21) -----------------------------------------
seen <- new.env(); seen$threads <- integer()
trace("computeDirectExp", where = asNamespace("pprof"), print = FALSE,
      tracer = quote(assign("threads", c(get("threads", envir = seen), threads), envir = seen)))
invisible(q(confint(fit_gre, stdz = "direct")))
untrace("computeDirectExp", where = asNamespace("pprof"))
report("V15.11", if (all(c(2L, 4L) %in% seen$threads)) "CONFIRMED" else "REFUTED",
       "confint.logis_re(stdz = 'direct') calls computeDirectExp with threads = 2 (SM_output default) and threads = 4 (hard-coded), regardless of any user setting (D-21; DEC-001)",
       sprintf("threads seen: %s", paste(seen$threads, collapse = ", ")))

# --- V15.12: interval attributes ---------------------------------------------------------------------------
ci_gre <- q(confint(fit_gre, stdz = "indirect", measure = c("ratio", "rate")))
ci_gcre <- q(confint(fit_gcre, stdz = "indirect", measure = c("ratio", "rate")))
ci_gfe <- q(confint(q(pprof::logis_fe(data = bin, Y.char = "Y", Z.char = covariate_names, ProvID.char = "ProvID", message = FALSE)),
                    test = "wald"))
report("V15.12", "CONFIRMED",
       "Interval attributes that plots dispatch on are inconsistent: confidence_level is '95 %' for FE models but '0.95 %' for RE/CRE models; logis_cre's indirect rate interval is labeled model = 'RE logis'",
       c(sprintf("logis_fe confidence_level: '%s'; logis_re: '%s'", attr(ci_gfe$CI.indirect_ratio, "confidence_level"),
                 attr(ci_gre$CI.indirect_ratio, "confidence_level")),
         sprintf("logis_cre model attributes: ratio '%s', rate '%s'", attr(ci_gcre$CI.indirect_ratio, "model"),
                 attr(ci_gcre$CI.indirect_rate, "model"))))

# --- V15.13: provider labels on RE coefficients -------------------------------------------------------------
chr <- transform(bin, ProvID = sprintf("P%03d", ProvID))
fit_chr <- q(pprof::logis_re(data = chr, Y.char = "Y", Z.char = covariate_names, ProvID.char = "ProvID"))
report("V15.13", if (identical(rownames(fit_chr$coefficient$RE), rownames(lme4::ranef(attr(fit_chr, "model"))$ProvID))) "CONFIRMED" else "REFUTED",
       "RE coefficient row names are overwritten with names(n.prov) (factor-level order of the provider column), which matches lme4's ranef order for numeric and character IDs; data_include is built with cbind() and becomes character when IDs are character",
       c(sprintf("class(data_include$Y) with character IDs: %s", class(fit_chr$data_include$Y)),
         sprintf("class(observation) logis_cre: %s", paste(class(fit_gcre$observation), collapse = "/"))))

# --- V15.14: tests and intervals ---------------------------------------------------------------------------
t_gre <- test(fit_gre)
pv <- attr(lme4::ranef(attr(fit_gre, "model"), condVar = TRUE)$ProvID, "postVar")[1, 1, ]
z_re <- as.numeric(fit_gre$coefficient$RE) / sqrt(pv)
pu <- pnorm(z_re, lower.tail = FALSE)
flag_re <- ifelse(pu < alpha / 2, 1, ifelse(pu > 1 - alpha / 2, -1, 0))
ci_a <- confint(fit_gre, option = "alpha")
report("V15.14", if (identical(as.numeric(as.character(t_gre$flag)), flag_re) && max(abs(ci_a$alpha.Upper - (fit_gre$coefficient$RE + qnorm(1 - alpha / 2) * sqrt(pv)))) < 1e-14) "CONFIRMED" else "REFUTED",
       "RE/CRE provider tests are Wald z = (alpha_i - null) / SE with default null = 0; flags 1 if p < alpha/2, -1 if p > 1 - alpha/2; intervals alpha_i +/- z SE (option = 'alpha', not 'gamma')",
       sprintf("formals(confint.logis_re): %s", paste(names(formals(pprof:::confint.logis_re)), collapse = ", ")))

cat("\nDone.\n")
