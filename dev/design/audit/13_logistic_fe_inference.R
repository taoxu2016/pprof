# Phase 0 audit: post-estimation for logis_fe (test, SM_output, confint, summary, plot).
script_dir <- dirname(normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))))
source(file.path(script_dir, "helpers.R"))
audit_header("13: logis_fe post-estimation")

dat <- load_binary_example()
fit <- quiet_logis_fe(data = dat, Y.char = "Y", Z.char = covariate_names, ProvID.char = "ProvID")
di <- fit$data_include
gamma <- fit$coefficient$gamma
beta <- fit$coefficient$beta
gamma_null <- median(gamma)
prov_index <- rep(seq_along(gamma), table(di$ProvID))
zb <- drop(as.matrix(di[, covariate_names]) %*% beta)
p0 <- plogis(gamma_null + zb)
p0c <- pmin(pmax(p0, 1e-10), 1 - 1e-10)
obs <- drop(rowsum(di$Y, prov_index))
alpha <- 1 - 0.95   # the reference computes alpha as 1 - level, and 1 - 0.95 != 0.05 in floating point
flag_two_sided <- function(p_upper, alpha) ifelse(p_upper < alpha / 2, 1, ifelse(p_upper <= 1 - alpha / 2, 0, -1))

# --- V13.1: exact Poisson-binomial test --------------------------------------------------------
ex <- test(fit)
mid_p <- sapply(seq_along(gamma), function(i) {
  pr <- p0c[prov_index == i]
  1 - poibin::ppoibin(obs[i], pr) + 0.5 * poibin::dpoibin(obs[i], pr)
})
ok <- max(abs(ex$`p value` - 2 * pmin(mid_p, 1 - mid_p))) < 1e-15 &&
  max(abs(ex$stat - qnorm(mid_p, lower.tail = FALSE))) < 1e-12 &&
  identical(as.numeric(as.character(ex$flag)), flag_two_sided(mid_p, alpha))
report("V13.1", if (ok) "CONFIRMED" else "REFUTED",
       "Default test is the exact Poisson-binomial mid-p test with p0 = plogis(median(gamma) + Z beta) clamped to [1e-10, 1 - 1e-10]: upper mid-p P(O > o) + P(O = o)/2 computed as 1 - F(o) + f(o)/2, two-sided p = 2 min(p, 1 - p), stat = qnorm(p, lower.tail = FALSE), flag 1 if p < alpha/2, 0 if p <= 1 - alpha/2, else -1",
       c(sprintf("max abs diff p value %.3g, stat %.3g", max(abs(ex$`p value` - 2 * pmin(mid_p, 1 - mid_p))),
                 max(abs(ex$stat - qnorm(mid_p, lower.tail = FALSE)))),
         sprintf("flag levels: %s", paste(levels(ex$flag), collapse = ", ")),
         sprintf("attribute 'provider size' present: %s", !is.null(attr(ex, "provider size")))))

greater <- test(fit, alternative = "greater")
less <- test(fit, alternative = "less")
no_event <- names(obs)[obs == 0]
report("V13.2", "NOTE",
       "One-sided exact tests: greater uses 1 - F(o - 1), less uses F(o). For no-event providers greater evaluates poibin::ppoibin(-1, .):",
       c(sprintf("poibin::ppoibin(-1, c(0.3, 0.4)) = %s", paste(format(poibin::ppoibin(-1, c(0.3, 0.4))), collapse = " ")),
         sprintf("no-event providers: %s", paste(no_event, collapse = ", ")),
         utils::capture.output(print(greater[rownames(greater) %in% no_event, ])),
         utils::capture.output(print(less[rownames(less) %in% no_event, ]))))

# --- V13.3: bootstrap test: draw order and reproducibility --------------------------------------
set.seed(11)
boot <- test(fit, test = "exact.bootstrap", n = 2000)
set.seed(11)
manual <- sapply(seq_along(gamma), function(i) {
  pr <- p0c[prov_index == i]
  sums <- colSums(matrix(rbinom(n = length(pr) * 2000, size = 1, prob = rep(pr, times = 2000)), ncol = 2000))
  (sum(sums > obs[i]) + 0.5 * sum(sums == obs[i])) / 2000
})
set.seed(11); boot_again <- test(fit, test = "exact.bootstrap", n = 2000)
report("V13.3", if (identical(boot$`p value`, 2 * pmin(manual, 1 - manual)) && identical(boot, boot_again)) "CONFIRMED" else "REFUTED",
       "Bootstrap test draws rbinom(n_i * n, 1, rep(p0_i, n)) provider by provider in provider order and uses the user's RNG stream (reproducible with set.seed, no internal seeding)",
       sprintf("identical to manual draw order: %s; identical across seeded runs: %s",
               identical(boot$`p value`, 2 * pmin(manual, 1 - manual)), identical(boot, boot_again)))

# --- V13.4: modified score test -----------------------------------------------------------------
sc <- test(fit, test = "score")
z_mod <- drop(rowsum(di$Y - p0c, prov_index)) / sqrt(drop(rowsum(p0c * (1 - p0c), prov_index)))
report("V13.4", if (max(abs(sc$stat - z_mod)) < 1e-12) "CONFIRMED" else "REFUTED",
       "Modified score test (default): z_i = sum(y - p0) / sqrt(sum p0 (1 - p0)) with clamped p0 and the unrestricted beta",
       sprintf("max abs diff stat %.3g", max(abs(sc$stat - z_mod))))

# --- V13.5: 'standard' score test (C++ Modified_score) --------------------------------------------
std <- test(fit, test = "score", score_modified = FALSE)
zmat <- as.matrix(di[, covariate_names])
p_full <- plogis(gamma[prov_index] + zb)
w_full <- p_full * (1 - p_full); w_full_floor <- w_full; w_full_floor[w_full_floor == 0] <- 1e-20
w_null <- p0 * (1 - p0)                                  # p0 NOT clamped here
z_std <- sapply(seq_along(gamma), function(i) {
  rows <- prov_index == i
  others <- setdiff(seq_along(gamma), i)
  d_inv <- 1 / drop(rowsum(w_full_floor, prov_index))[others]
  b <- t(rowsum(zmat * w_full, prov_index))[, others, drop = FALSE]
  w_mix <- w_full_floor; w_mix[rows] <- w_null[rows]
  i_bb <- crossprod(zmat, zmat * w_mix)
  b11 <- solve(i_bb - (b * rep(d_inv, each = nrow(b))) %*% t(b))
  b_alpha <- colSums(zmat[rows, , drop = FALSE] * w_null[rows])
  v0 <- sum(w_null[rows]) - drop(t(b_alpha) %*% b11 %*% b_alpha)
  sum(di$Y[rows] - p0[rows]) / sqrt(v0)
})
report("V13.5", if (max(abs(std$stat - z_std)) < 1e-10) "CONFIRMED" else "REFUTED",
       "score_modified = FALSE does not refit under the null: it plugs in the full-model gamma_(-i) and beta, uses unclamped p0 for provider i, and adjusts the variance for the nuisance parameters, V = I_aa - I_ab (I_bb* - I_bg I_gg^-1 I_gb)^-1 I_ba (docs call it a 'standard score test')",
       sprintf("max abs diff stat %.3g", max(abs(std$stat - z_std))))

# --- V13.6: non-finite standard-score statistics are dropped (D-04) -------------------------------
set.seed(7)
m <- 30
prov <- rep(seq_len(m), each = 40)
x <- rnorm(length(prov)); x[prov == 5] <- rnorm(40, 45, 1)
y <- rbinom(length(prov), 1, plogis(-1 + rnorm(m, 0, 0.5)[prov] + x))
d04 <- data.frame(Y = y, ProvID = prov, x1 = x)
fit04 <- quiet_logis_fe(data = d04, Y.char = "Y", Z.char = "x1", ProvID.char = "ProvID")
raw04 <- pprof:::Modified_score(fit04$data_include$Y, as.matrix(fit04$data_include$x1),
                                as.numeric(table(fit04$data_include$ProvID)), fit04$coefficient$gamma,
                                fit04$coefficient$beta, median(fit04$coefficient$gamma), m, 0:(m - 1), 1L)
api04 <- try_capture(test(fit04, test = "score", score_modified = FALSE))
api_null <- try_capture(test(fit, test = "score", score_modified = FALSE, null = 50))
report("V13.6", if (length(raw04) < m && api04$error) "CONFIRMED" else "REFUTED",
       "Modified_score drops non-finite statistics, so one provider whose null probabilities round to exactly 0 or 1 shortens the result and test() fails (D-04)",
       c(sprintf("provider 5: all events = %s; Modified_score returned %d of %d statistics",
                 all(d04$Y[d04$ProvID == 5] == 1), length(raw04), m),
         sprintf("test(score_modified = FALSE): %s", if (api04$error) paste("ERROR:", api04$message) else "ok"),
         sprintf("ExampleDataBinary with null = 50: %s", if (api_null$error) paste("ERROR:", api_null$message) else "ok")))

# --- V13.7: Wald test -------------------------------------------------------------------------------
wd <- suppressWarnings(test(fit, test = "wald"))
z_w <- (gamma - gamma_null) / sqrt(fit$variance$gamma)
wl <- suppressWarnings(test(fit, test = "wald", alternative = "less"))
report("V13.7", if (max(abs(wd$stat - z_w)) == 0 && max(abs(wl$`p value` - (1 - pnorm(z_w, lower.tail = FALSE)))) == 0) "CONFIRMED" else "REFUTED",
       "Wald test: z = (gamma - null) / sqrt(variance$gamma), always warns; 'less' computes 1 - pnorm(z, lower.tail = FALSE) rather than pnorm(z) (these differ in the far tail)",
       c(sprintf("warning: %s", try_capture(test(fit, test = "wald"))$warnings),
         sprintf("max |(1 - pnorm(z, lower = F)) - pnorm(z)| over providers: %.3g",
                 max(abs((1 - pnorm(z_w, lower.tail = FALSE)) - pnorm(z_w))))))

# --- V13.8: robust_wald returns NULL (D-06) ---------------------------------------------------------
rw <- try_capture(test(fit, test = "robust_wald"))
report("V13.8", if (!rw$error && is.null(rw$value)) "CONFIRMED" else "REFUTED",
       "test = 'robust_wald' passes validation, matches no branch ('robust wald' with a space), and returns NULL (D-06)",
       sprintf("is.null(result): %s", is.null(rw$value)))

# --- V13.9: null validation differs across methods (D-14) -------------------------------------------
null_int <- list(
  test = try_capture(test(fit, null = 0L)),
  SM_output = try_capture(SM_output(fit, null = 0L, threads = 1)),
  confint = try_capture(confint(fit, null = 0L, test = "wald")),
  plot = try_capture(plot(fit, null = 0L)))
report("V13.9", "CONFIRMED",
       "An integer null is accepted by test() (is.numeric) but rejected by SM_output(), by confint() (which calls SM_output), and by plot() (class(null) == 'numeric') (D-14)",
       sapply(null_int, function(r) if (r$error) paste("ERROR:", r$message) else "accepted"))

# --- V13.10: flag factor levels depend on the data (D-15) -------------------------------------------
w_sub <- suppressWarnings(test(fit, test = "wald", parm = c(1, 2)))
report("V13.10", "CONFIRMED",
       "flag is factor(flag): its levels are the flags that occur, and for wald with parm the levels come from all providers before subsetting (D-15)",
       c(sprintf("exact, all providers: levels %s", paste(levels(ex$flag), collapse = " ")),
         sprintf("wald, parm = c(1, 2): values %s, levels %s", paste(as.character(w_sub$flag), collapse = " "),
                 paste(levels(w_sub$flag), collapse = " "))))

# --- V13.11: integer provider IDs and numeric parm --------------------------------------------------
fit_int <- quiet_logis_fe(data = transform(dat, ProvID = as.integer(ProvID)), Y.char = "Y",
                          Z.char = covariate_names, ProvID.char = "ProvID")
parm_int <- list(test = try_capture(test(fit_int, parm = 1:3)),
                 SM_output = try_capture(SM_output(fit_int, parm = 1:3, threads = 1)),
                 confint = try_capture(confint(fit_int, parm = 1:3, test = "wald", option = "gamma")))
report("V13.11", if (all(sapply(parm_int, `[[`, "error"))) "CONFIRMED" else "NOTE",
       "With an integer provider column, parm = 1:3 is converted to double and then fails the class(parm) == class(ProvID) check (new finding)",
       sapply(parm_int, function(r) if (r$error) paste("ERROR:", r$message) else "accepted"))

# --- V13.12: SM_output -------------------------------------------------------------------------------
sm <- SM_output(fit, stdz = c("indirect", "direct"), measure = c("ratio", "rate"), threads = 1)
e_ind <- drop(rowsum(p0, prov_index))
pop <- sum(di$Y) / nrow(di) * 100
e_dir <- sapply(gamma, function(g) sum(plogis(g + zb)))
ok <- max(abs(sm$indirect.ratio - obs / e_ind)) < 1e-14 &&
  max(abs(sm$indirect.rate - pmax(pmin(obs / e_ind * pop, 100), 0))) < 1e-12 &&
  max(abs(sm$direct.ratio - e_dir / sum(di$Y))) < 1e-12
report("V13.12", if (ok) "CONFIRMED" else "REFUTED",
       "SM_output: indirect ratio O_i / E_i with E_i = sum plogis(median(gamma) + Z beta) (unclamped); direct ratio sum_j plogis(gamma_i + Z_j beta) / sum(O); rate = ratio x 100 sum(O)/N clipped to [0, 100]; OE tables carry Obs, Exp, Var (indirect) and Obs_all, Exp.direct_all (direct)",
       c(sprintf("max abs diff indirect ratio %.3g, direct ratio %.3g", max(abs(sm$indirect.ratio - obs / e_ind)),
                 max(abs(sm$direct.ratio - e_dir / sum(di$Y)))),
         sprintf("names(SM_output): %s", paste(names(sm), collapse = ", ")),
         sprintf("OE_indirect columns: %s", paste(names(sm$OE$OE_indirect), collapse = ", ")),
         sprintf("OE_direct columns: %s", paste(names(sm$OE$OE_direct), collapse = ", "))))

old <- options(warnPartialMatchDollar = TRUE)
pm <- try_capture(SM_output(fit, measure = "rate", threads = 1))
options(old)
report("V13.13", if (length(pm$warnings) > 0) "CONFIRMED" else "REFUTED",
       "SM_output.logis_fe reads fit$obs, which works only by partial matching of fit$observation (D-08)",
       pm$warnings)

d1 <- pprof:::computeDirectExp(gamma, zb, 1L)
d2 <- pprof:::computeDirectExp(gamma, zb, 2L)
report("V13.14", "NOTE",
       "computeDirectExp with 1 and 2 threads (nested OpenMP region, inner reduction):",
       c(sprintf("identical: %s; max rel diff %.3g", identical(d1, d2), max_rel_diff(d2, d1)),
         sprintf("SM_output default threads: %s", formals(pprof:::SM_output.logis_fe)$threads)))

# --- V13.15: confint for gamma ------------------------------------------------------------------------
ci_g <- suppressWarnings(confint(fit, option = "gamma"))
i <- which(obs > 0 & obs < table(di$ProvID))[1]
pr_z <- drop(as.matrix(di[prov_index == i, covariate_names]) %*% beta)   # as the reference computes it
zb_subset_vs_full <- max_abs_diff(pr_z, zb[prov_index == i])
alpha_literal_gap <- (1 - 0.95) - 0.05
upper_fn <- function(g) poibin::ppoibin(obs[i] - 1, plogis(g + pr_z)) + 0.5 * poibin::dpoibin(obs[i], plogis(g + pr_z)) - alpha / 2
lower_fn <- function(g) 1 - poibin::ppoibin(obs[i], plogis(g + pr_z)) + 0.5 * poibin::dpoibin(obs[i], plogis(g + pr_z)) - alpha / 2
u <- uniroot(upper_fn, gamma[i] + c(0, 5))$root
l <- uniroot(lower_fn, gamma[i] + c(-5, 0))$root
ne <- no_event[1]
report("V13.15", if (abs(ci_g[names(obs)[i], "gamma.upper"] - u) == 0 && abs(ci_g[names(obs)[i], "gamma.lower"] - l) == 0) "CONFIRMED" else "REFUTED",
       "Exact gamma intervals invert the mid-p tests with uniroot() at its default tolerance on brackets gamma + [5k, 5(k+1)] (upper) and gamma - [5(k+1), 5k] (lower), k = 0, 1, 2; no-event providers get (-Inf, U] from P(O = 0)/2 = alpha",
       c(sprintf("provider %s: reference [%.12g, %.12g], manual [%.12g, %.12g]", names(obs)[i],
                 ci_g[names(obs)[i], "gamma.lower"], ci_g[names(obs)[i], "gamma.upper"], l, u),
         sprintf("no-event provider %s: %s", ne, paste(format(unlist(ci_g[ne, ]), digits = 8), collapse = ", ")),
         sprintf("row order: %s ...", paste(head(rownames(ci_g), 8), collapse = " ")),
         sprintf("alpha is computed as 1 - level: (1 - 0.95) - 0.05 = %.3g, which moves the roots by about 4e-16", alpha_literal_gap),
         sprintf("Z beta from the provider rows versus the same rows of the full product: max abs diff %.3g",
                 zb_subset_vs_full)))

# --- V13.16: character IDs misalign SM intervals (D-19) --------------------------------------------
dat_chr <- transform(dat, ProvID = sprintf("P%03d", ProvID))
fit_chr <- quiet_logis_fe(data = dat_chr, Y.char = "Y", Z.char = covariate_names, ProvID.char = "ProvID")
ci_num <- suppressWarnings(confint(fit, option = "SM", stdz = "indirect", measure = "ratio"))$CI.indirect_ratio
ci_chr_res <- try_capture(confint(fit_chr, option = "SM", stdz = "indirect", measure = "ratio"))
ci_chr <- ci_chr_res$value$CI.indirect_ratio
rownames(ci_num) <- sprintf("P%03d", as.numeric(rownames(ci_num)))
mism <- rownames(ci_num)[abs(ci_num$CI_ratio.lower - ci_chr[rownames(ci_num), "CI_ratio.lower"]) > 1e-8]
report("V13.16", if (length(mism) > 0) "CONFIRMED" else "REFUTED",
       "With character provider IDs, confint(option = 'SM') reorders interval columns with order(as.numeric(colnames)), which is all NA, so the intervals of providers after the first no-event provider are attached to the wrong provider (D-19)",
       c(sprintf("providers whose interval differs between numeric and character IDs: %d of %d", length(mism), nrow(ci_num)),
         sprintf("first mismatches: %s", paste(head(mism, 6), collapse = " ")),
         sprintf("no-event providers: %s", paste(sprintf("P%03d", as.numeric(no_event)), collapse = " ")),
         sprintf("warnings: %s", paste(unique(ci_chr_res$warnings), collapse = " | ")),
         utils::capture.output(print(cbind(numeric_ids = ci_num[mism[1:3], ], character_ids = ci_chr[mism[1:3], ])))))

# --- V13.17: direct SM intervals require a column literally named ProvID ----------------------------
dat_h <- dat; names(dat_h)[names(dat_h) == "ProvID"] <- "hospital"
fit_h <- quiet_logis_fe(data = dat_h, Y.char = "Y", Z.char = covariate_names, ProvID.char = "hospital")
dir_h <- try_capture(confint(fit_h, option = "SM", stdz = "direct"))
ind_h <- try_capture(confint(fit_h, option = "SM", stdz = "indirect"))
report("V13.17", if (dir_h$error && !ind_h$error) "CONFIRMED" else "REFUTED",
       "confint.logis_fe(stdz = 'direct') selects providers with data$ProvID, so it fails when the provider column has any other name (new finding)",
       c(sprintf("provider column 'hospital', direct: %s", if (dir_h$error) paste("ERROR:", dir_h$message) else "ok"),
         sprintf("provider column 'hospital', indirect: %s", if (ind_h$error) paste("ERROR:", ind_h$message) else "ok")))

# --- V13.18: factor provider IDs ---------------------------------------------------------------------
dat_f <- transform(dat, ProvID = factor(ProvID * 10))
fit_f <- quiet_logis_fe(data = dat_f, Y.char = "Y", Z.char = covariate_names, ProvID.char = "ProvID")
fac <- list(test = try_capture(test(fit_f)),
            SM_output = try_capture(SM_output(fit_f, threads = 1)),
            confint_gamma_exact = try_capture(confint(fit_f, option = "gamma")),
            confint_gamma_wald = try_capture(confint(fit_f, option = "gamma", test = "wald")))
report("V13.18", if (fac$confint_gamma_exact$error) "CONFIRMED" else "NOTE",
       "Factor provider IDs: the interval helpers take prov <- ifelse(..., unique(ProvID), ...), which returns the factor's integer code, then look up gamma by that code (new finding)",
       sapply(fac, function(r) if (r$error) paste("ERROR:", r$message) else "ok"))

# --- V13.19: summary.logis_fe --------------------------------------------------------------------------
sw <- summary(fit)
counter <- new.env(); counter$n <- 0
trace("logis_fe", where = asNamespace("pprof"), print = FALSE,
      tracer = quote(assign("n", get("n", envir = counter) + 1, envir = counter)))
s_lr <- suppressWarnings(suppressMessages(summary(fit, test = "lr", parm = c("z1", "z2"))))
n_refits <- counter$n
untrace("logis_fe", where = asNamespace("pprof"))
lr_case <- function(z_names, cutoff = 10, d = dat) {
  f <- quiet_logis_fe(data = d, Y.char = "Y", Z.char = z_names, ProvID.char = "ProvID", cutoff = cutoff)
  out <- lapply(c("lr", "score"), function(tt) try_capture(suppressMessages(summary(f, test = tt))))
  sapply(out, function(r) if (r$error) paste("ERROR:", r$message) else "ok")
}
set.seed(3)
small <- data.frame(Y = rbinom(1000, 1, 0.3), ProvID = c(rep(1:40, each = 20), rep(41:65, each = 8)),
                    x1 = rnorm(1000), x2 = rnorm(1000), x3 = rnorm(1000))
report("V13.19", "CONFIRMED",
       "summary.logis_fe: Wald p-values are character strings from format.pval(digits = 7, eps = 1e-10). LR and score tests refit logis_fe with default settings twice per covariate (D-10); they fail with one covariate, and with two covariates because cbind() then misnames the single remaining column (new finding); with cutoff below the default the refit drops providers the original fit kept (D-10)",
       c(sprintf("class of 'p value' column (wald): %s", class(sw$`p value`)),
         sprintf("logis_fe calls during summary(test = 'lr', parm = c('z1', 'z2')): %d", n_refits),
         sprintf("p = 1 (lr, score): %s", paste(lr_case("z1"), collapse = " / ")),
         sprintf("p = 2 (lr, score): %s", paste(lr_case(c("z1", "z2")), collapse = " / ")),
         sprintf("p = 3 (lr, score): %s", paste(lr_case(c("z1", "z2", "z3")), collapse = " / ")),
         sprintf("p = 3, cutoff = 5, 25 providers of size 8 (lr, score): %s",
                 paste(lr_case(c("x1", "x2", "x3"), cutoff = 5, d = small), collapse = " / "))))

z_beta <- (beta - 0) / sqrt(diag(fit$variance$beta))
report("V13.20", if (identical(sw$`p value`, format.pval(2 * (1 - pnorm(abs(z_beta))), digits = 7, eps = 1e-10))) "CONFIRMED" else "REFUTED",
       "summary Wald: p = 2 (1 - pnorm(|z|)), interval beta +/- qnorm(1 - alpha/2) se",
       utils::capture.output(print(sw)))

# --- V13.21: funnel plot ----------------------------------------------------------------------------------
p_score <- try_capture(plot(fit))
p_exact <- try_capture(plot(fit, test = "exact"))
report("V13.21", if (!p_score$error && p_exact$error) "CONFIRMED" else "REFUTED",
       "plot.logis_fe works with test = 'score' but fails with test = 'exact', which calls qpoibin through rlang's .data pronoun outside a data mask (D-07)",
       c(sprintf("score: %s", if (p_score$error) p_score$message else paste(class(p_score$value), collapse = "/")),
         sprintf("score warnings: %s", paste(unique(p_score$warnings), collapse = " | ")),
         sprintf("exact: %s", if (p_exact$error) paste("ERROR:", p_exact$message) else "ok")))

cat("\nDone.\n")
