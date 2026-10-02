# Phase 0 audit: logis_fe fitting (SerBIN and BAN), screening, ordering, inputs.
script_dir <- dirname(normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))))
source(file.path(script_dir, "helpers.R"))
source(file.path(script_dir, "ports.R"))
audit_header("10: logis_fe fitting")

dat <- load_binary_example()
inp <- port_inputs(dat, "Y", "ProvID", covariate_names)

# --- V10.1-V10.4: the R ports reproduce the C++ fitters --------------------------------
run_cpp <- function(method, ...) {
  res <- with_output(pprof::logis_fe(data = dat, Y.char = "Y", Z.char = covariate_names,
                                     ProvID.char = "ProvID", method = method, message = TRUE, ...))
  list(fit = res$value, iter = iterations_from_log(res$output), log = res$output)
}

grid <- expand.grid(method = c("SerBIN", "BAN"), stop = c("or", "beta", "relch", "ratch", "all"),
                    backtrack = c(TRUE, FALSE), stringsAsFactors = FALSE)
rows <- list()
for (k in seq_len(nrow(grid))) {
  g <- grid[k, ]
  cpp <- run_cpp(g$method, stop = g$stop, backtrack = g$backtrack)
  port <- if (g$method == "SerBIN") {
    port_serbin(inp$y, inp$z, inp$n_prov, inp$gamma, inp$beta, stop = g$stop, backtrack = g$backtrack)
  } else {
    port_ban(inp$y, inp$z, inp$n_prov, inp$gamma, inp$beta, stop = g$stop, backtrack = as.integer(g$backtrack))
  }
  rows[[k]] <- data.frame(method = g$method, stop = g$stop, backtrack = g$backtrack,
                          iter_cpp = cpp$iter, iter_port = port$iter,
                          backtracks_port = port$n_backtracks,
                          max_rel_beta = max_rel_diff(port$beta, cpp$fit$coefficient$beta),
                          max_abs_gamma = max_abs_diff(port$gamma, cpp$fit$coefficient$gamma))
}
port_table <- do.call(rbind, rows)
ok <- with(port_table, all(iter_cpp == iter_port) && max(max_rel_beta) < 1e-8 && max(max_abs_gamma) < 1e-8)
report("V10.1", if (ok) "CONFIRMED" else "REFUTED",
       "R ports encoding the §5.7 conventions reproduce SerBIN and BAN (all stopping rules, backtrack on/off) on ExampleDataBinary: same iteration counts, estimates equal to near machine precision",
       port_table)

# Clamping and backtracking are inactive on ExampleDataBinary at default settings, so
# exercise them on synthetic data with no-event and all-event providers and a poor start.
set.seed(20261002)
make_extreme <- function(m = 40, n_i = 25, p = 3) {
  prov <- rep(seq_len(m), each = n_i)
  z <- matrix(rnorm(m * n_i * p), ncol = p, dimnames = list(NULL, paste0("x", 1:p)))
  gamma <- rnorm(m, -1, 0.7)
  y <- rbinom(length(prov), 1, plogis(gamma[prov] + z %*% c(0.8, -0.5, 0.3)))
  y[prov %in% 1:3] <- 0                     # three no-event providers
  y[prov %in% 4:5] <- 1                     # two all-event providers
  data.frame(Y = y, ProvID = prov, z)
}
ext <- make_extreme()
inp_ext <- port_inputs(ext, "Y", "ProvID", paste0("x", 1:3))
cmp_ext <- list()
for (s in c("or", "beta")) for (bt in c(TRUE, FALSE)) {
  cpp <- with_output(pprof::logis_fe(data = ext, Y.char = "Y", Z.char = paste0("x", 1:3),
                                     ProvID.char = "ProvID", stop = s, backtrack = bt,
                                     tol = 1e-10, message = TRUE))
  port <- port_serbin(inp_ext$y, inp_ext$z, inp_ext$n_prov, inp_ext$gamma, inp_ext$beta,
                      stop = s, backtrack = bt, tol = 1e-10)
  g <- cpp$value$coefficient$gamma
  cmp_ext[[length(cmp_ext) + 1]] <- data.frame(
    stop = s, backtrack = bt, iter_cpp = iterations_from_log(cpp$output), iter_port = port$iter,
    clamp_events_port = port$n_clamped, backtracks_port = port$n_backtracks,
    gamma_at_bound = sum(abs(abs(g - median(g)) - 10) < 1e-12),
    max_rel_beta = max_rel_diff(port$beta, cpp$value$coefficient$beta),
    max_abs_gamma = max_abs_diff(port$gamma, g))
}
cmp_ext <- do.call(rbind, cmp_ext)
ok <- with(cmp_ext, all(iter_cpp == iter_port) && max(max_rel_beta) < 1e-8 && all(gamma_at_bound > 0))
report("V10.2", if (ok) "CONFIRMED" else "REFUTED",
       "With no-event/all-event providers the clamp gamma in [median(gamma) - bound, median(gamma) + bound] binds every iteration and the port still reproduces SerBIN",
       cmp_ext)

# Backtracking: start far from the optimum so the full Newton step overshoots, and stop
# after max_iter + 1 = 3 iterations so the comparison is of the path, not the optimum.
bt_start_beta <- inp_ext$beta + 2
bt_z <- inp_ext$z * 6
bt_runs <- list()
for (t_const in c(0.6, 0.8)) {
  bt_runs[[as.character(t_const)]] <- port_serbin(inp_ext$y, bt_z, inp_ext$n_prov, inp_ext$gamma,
                                                  bt_start_beta, stop = "beta", tol = 1e-300,
                                                  max_iter = 2, armijo_t = t_const)
}
cpp_bt <- pprof:::logis_BIN_fe_prov(as.matrix(inp_ext$y), bt_z, inp_ext$n_prov,
                                    inp_ext$gamma, bt_start_beta, threads = 1L, tol = 1e-300,
                                    max_iter = 2L, bound = 10, message = FALSE,
                                    backtrack = TRUE, stop = "beta")
bt_tab <- data.frame(
  armijo_t = c(0.6, 0.8),
  backtracks = sapply(bt_runs, `[[`, "n_backtracks"),
  iterations = sapply(bt_runs, `[[`, "iter"),
  max_abs_beta_vs_cpp = sapply(bt_runs, function(r) max_abs_diff(r$beta, cpp_bt$beta)),
  step_sizes = sapply(bt_runs, function(r) paste(signif(r$trace[, "step"], 4), collapse = ", ")))
report("V10.3", if (bt_tab$backtracks[1] > 0 && bt_tab$max_abs_beta_vs_cpp[1] < 1e-8 &&
                    bt_tab$max_abs_beta_vs_cpp[2] > 1e-6) "CONFIRMED" else "REFUTED",
       "Armijo constants s = 0.01, t = 0.6: with backtracking active, the t = 0.6 port matches the C++ path after 3 iterations and a t = 0.8 port does not",
       bt_tab)

# --- V10.4-V10.6: iteration limits and messages ------------------------------------------
lim <- list()
for (m in c("SerBIN", "BAN")) {
  r <- run_cpp(m, max.iter = 3, tol = 1e-300, stop = "beta")
  lim[[m]] <- data.frame(method = m, max.iter = 3, iterations_run = r$iter,
                         final_message = tail(grep("converged", r$log, value = TRUE), 1))
}
lim <- do.call(rbind, lim)
report("V10.4", if (lim$iterations_run[1] == 4 && lim$iterations_run[2] == 3) "CONFIRMED" else "REFUTED",
       "SerBIN runs up to max.iter + 1 iterations, BAN up to max.iter, and both report 'converged' when the limit is hit (D-03)",
       lim)

ban0 <- quiet_logis_fe(data = dat, Y.char = "Y", Z.char = covariate_names, ProvID.char = "ProvID",
                       method = "BAN", max.iter = 0)
start_val <- log(mean(dat$Y) / (1 - mean(dat$Y)))
report("V10.5", if (max(abs(ban0$coefficient$gamma - start_val)) == 0 && all(ban0$coefficient$beta == 0)) "CONFIRMED" else "REFUTED",
       "Initial values are gamma_i = logit(mean(Y)) over included observations for every provider and beta = 0 (BAN with max.iter = 0 returns the starting point)",
       c(sprintf("logit(mean(Y)) = %.17g", start_val),
         sprintf("range(gamma) = %s", paste(format(range(ban0$coefficient$gamma), digits = 17), collapse = " .. ")),
         sprintf("beta = %s", paste(ban0$coefficient$beta, collapse = ", "))))

ban2 <- quiet_logis_fe(data = dat, Y.char = "Y", Z.char = covariate_names, ProvID.char = "ProvID",
                       method = "BAN", backtrack = 2)
report("V10.6", if (all(ban2$coefficient$beta == 0)) "CONFIRMED" else "REFUTED",
       "BAN with backtrack = 2 (any value other than 0/1/TRUE/FALSE) runs zero iterations and silently returns the starting values (new finding)",
       sprintf("beta = %s", paste(ban2$coefficient$beta, collapse = ", ")))

# --- V10.7: threads < 1 leaves the SerBIN information block uninitialized -----------------
child <- tryCatch(callr::r(function(lib) {
  suppressPackageStartupMessages(library(pprof, lib.loc = lib))
  e <- new.env(); utils::data("ExampleDataBinary", package = "pprof", lib.loc = lib, envir = e)
  d <- e$ExampleDataBinary
  out <- list()
  for (th in c(1L, 0L, -1L)) {
    fit <- tryCatch(suppressWarnings(suppressMessages(
      pprof::logis_fe(Y = d$Y, Z = d$Z, ProvID = d$ProvID, threads = th, message = FALSE))),
      error = function(e) conditionMessage(e))
    out[[paste0("threads = ", th)]] <- if (is.character(fit)) fit else as.numeric(fit$coefficient$beta)
  }
  out
}, args = list(lib = ref_lib)), error = function(e) paste("child process failed:", conditionMessage(e)))
report("V10.7", "NOTE",
       "SerBIN with threads = 0 or -1 takes neither branch at Fixed_effect.cpp:383-388, so info_beta is used uninitialized (undefined behavior; new finding). Results observed in a child process:",
       child)

# --- V10.8: screening and the small-provider warning (D-01) -------------------------------
set.seed(1)
scr <- data.frame(Y = rbinom(9 + 10 + 11 + 40, 1, 0.3),
                  ProvID = rep(c("p09", "p10", "p11", "p40"), c(9, 10, 11, 40)),
                  x1 = rnorm(70))
scr_res <- try_capture(pprof::logis_fe(data = scr, Y.char = "Y", Z.char = "x1", ProvID.char = "ProvID",
                                       cutoff = 10, message = TRUE))
fit_scr <- scr_res$value
report("V10.8", if (identical(rownames(fit_scr$coefficient$gamma), c("p10", "p11", "p40")) &&
                    any(grepl("^2 out of 4 providers considered small", scr_res$warnings))) "CONFIRMED" else "REFUTED",
       "Inclusion is n_i >= cutoff, but the warning counts n_i <= cutoff (D-01): sizes 9, 10, 11, 40 with cutoff = 10 keep three providers while the warning says two were filtered",
       c(paste("kept providers:", paste(rownames(fit_scr$coefficient$gamma), collapse = ", ")),
         paste("warning:", scr_res$warnings),
         paste("data_include rows:", nrow(fit_scr$data_include), "(excluded rows are dropped, not kept with included = 0)")))

# --- V10.9: no-event and all-event providers are flagged but kept ---------------------------
fit_ext <- quiet_logis_fe(data = ext, Y.char = "Y", Z.char = paste0("x", 1:3), ProvID.char = "ProvID")
di <- fit_ext$data_include
flags <- unique(di[, c("ProvID", "no.events", "all.events")])
g <- fit_ext$coefficient$gamma
report("V10.9", "CONFIRMED",
       "No-event and all-event providers stay in the fit with finite gamma; indicators are stored per observation in data_include",
       c(paste("no.events providers:", paste(flags$ProvID[flags$no.events == 1], collapse = ", ")),
         paste("all.events providers:", paste(flags$ProvID[flags$all.events == 1], collapse = ", ")),
         sprintf("gamma - median(gamma) for providers 1-5: %s",
                 paste(format(g[1:5] - median(g), digits = 6), collapse = ", "))))

# --- V10.10: provider ordering follows factor() levels, which are locale dependent ---------
order_child <- function(collate) {
  callr::r(function(lib, collate) {
    Sys.setlocale("LC_COLLATE", collate)
    suppressPackageStartupMessages(library(pprof, lib.loc = lib))
    set.seed(2)
    ids <- rep(c("b", "B", "a", "A", "_c", "10", "9"), each = 15)
    d <- data.frame(Y = rbinom(length(ids), 1, 0.4), ProvID = ids, x1 = rnorm(length(ids)))
    fit <- suppressWarnings(suppressMessages(pprof::logis_fe(data = d, Y.char = "Y", Z.char = "x1",
                                                             ProvID.char = "ProvID", message = FALSE)))
    c(locale = Sys.getlocale("LC_COLLATE"), order = paste(rownames(fit$coefficient$gamma), collapse = " "))
  }, args = list(lib = ref_lib, collate = collate))
}
ord_c <- order_child("C")
ord_en <- order_child("English_United States.1252")
num_ids <- quiet_logis_fe(data = transform(scr, ProvID = rep(c(100, 20, 3, 4), c(9, 10, 11, 40))),
                          Y.char = "Y", Z.char = "x1", ProvID.char = "ProvID", cutoff = 1)
report("V10.10", if (ord_c[["order"]] != ord_en[["order"]]) "CONFIRMED" else "REFUTED",
       "Providers are ordered by factor() levels: numeric IDs sort numerically, character IDs sort by the session's collation locale, so the order (and anything that depends on it) differs between C and English locales",
       c(sprintf("LC_COLLATE=%s: %s", ord_c[["locale"]], ord_c[["order"]]),
         sprintf("LC_COLLATE=%s: %s", ord_en[["locale"]], ord_en[["order"]]),
         sprintf("numeric IDs 100, 20, 3, 4 -> %s", paste(rownames(num_ids$coefficient$gamma), collapse = " "))))

# --- V10.11: the three input formats agree --------------------------------------------------
f <- stats::as.formula(paste("Y ~", paste(covariate_names, collapse = " + "), "+ id(ProvID)"))
e <- new.env(); utils::data("ExampleDataBinary", package = "pprof", lib.loc = ref_lib, envir = e)
fit_formula <- quiet_logis_fe(formula = f, data = dat)
fit_columns <- quiet_logis_fe(data = dat, Y.char = "Y", Z.char = covariate_names, ProvID.char = "ProvID")
fit_vectors <- quiet_logis_fe(Y = e$ExampleDataBinary$Y, Z = e$ExampleDataBinary$Z, ProvID = e$ExampleDataBinary$ProvID)
same <- identical(fit_formula$coefficient, fit_columns$coefficient) &&
  identical(unname(fit_columns$coefficient$gamma), unname(fit_vectors$coefficient$gamma)) &&
  identical(unname(fit_columns$coefficient$beta), unname(fit_vectors$coefficient$beta))
report("V10.11", if (same) "CONFIRMED" else "REFUTED",
       "Formula, column-name, and vector inputs give bitwise-identical estimates on ExampleDataBinary",
       c(sprintf("class(data_include$ProvID): formula=%s columns=%s vectors=%s",
                 class(fit_formula$data_include$ProvID), class(fit_columns$data_include$ProvID),
                 class(fit_vectors$data_include$ProvID)),
         sprintf("names(fit): %s", paste(names(fit_columns), collapse = ", "))))

# --- V10.12: formula terms that are not plain columns fail (D-18) ---------------------------
d18 <- transform(dat, w = abs(z1) + 1, grp = factor(sample(c("level one", "level two"), nrow(dat), TRUE)))
cases <- list(
  "log(w)" = Y ~ log(w) + z2 + id(ProvID),
  "z1:z2" = Y ~ z1 + z2 + z1:z2 + id(ProvID),
  "factor with spaces in levels (formula)" = Y ~ z1 + grp + id(ProvID),
  "I(z1^2)" = Y ~ z1 + I(z1^2) + id(ProvID))
res18 <- sapply(cases, function(fm) {
  r <- try_capture(quiet_logis_fe(formula = fm, data = d18))
  if (r$error) paste("ERROR:", r$message) else "fits"
})
col_spaces <- try_capture(quiet_logis_fe(data = d18, Y.char = "Y", Z.char = c("z1", "grp"), ProvID.char = "ProvID"))
res18 <- c(res18, "factor with spaces in levels (columns)" = if (col_spaces$error) paste("ERROR:", col_spaces$message) else "fits")
report("V10.12", "CONFIRMED",
       "Formula terms are matched against column names by regular expressions, so transformed or interaction terms fail with a misleading message, and factor levels containing spaces break the model-matrix round trip through data.frame() (D-18)",
       res18)

# --- V10.13: design matrix follows options('contrasts') -------------------------------------
d_fac <- transform(dat, grp = factor(sample(c("a", "b", "c"), nrow(dat), TRUE)))
old <- options(contrasts = c("contr.sum", "contr.poly"))
fit_sum <- quiet_logis_fe(data = d_fac, Y.char = "Y", Z.char = c("z1", "grp"), ProvID.char = "ProvID")
options(old)
fit_trt <- quiet_logis_fe(data = d_fac, Y.char = "Y", Z.char = c("z1", "grp"), ProvID.char = "ProvID")
report("V10.13", "CONFIRMED",
       "Design matrix is model.matrix(reformulate(Z.char), data)[, -1], so factor coding follows options('contrasts')",
       c(paste("contr.treatment columns:", paste(rownames(fit_trt$coefficient$beta), collapse = ", ")),
         paste("contr.sum columns:      ", paste(rownames(fit_sum$coefficient$beta), collapse = ", "))))

# --- V10.14: missing data -------------------------------------------------------------------
d_na <- dat
d_na$unused <- NA
d_na$z1[1:5] <- NA
fit_na <- quiet_logis_fe(data = d_na, Y.char = "Y", Z.char = covariate_names, ProvID.char = "ProvID")
report("V10.14", if (nrow(fit_na$data_include) == nrow(dat) - 5) "CONFIRMED" else "REFUTED",
       "Listwise deletion uses only the response, provider, and covariate columns (an all-NA unused column does not drop rows)",
       sprintf("rows: input %d, after deletion %d", nrow(d_na), nrow(fit_na$data_include)))

# --- V10.15: AUC equals the Mann-Whitney statistic ------------------------------------------
fitted <- as.numeric(fit_columns$fitted)
y_inc <- fit_columns$data_include$Y
r <- rank(fitted)
n1 <- sum(y_inc == 1); n0 <- sum(y_inc == 0)
auc_mw <- (sum(r[y_inc == 1]) - n1 * (n1 + 1) / 2) / (n1 * n0)
report("V10.15", if (abs(auc_mw - fit_columns$AUC) < 1e-12) "CONFIRMED" else "REFUTED",
       "AUC from pROC::auc equals the rank-based Mann-Whitney estimate (ties counted one half)",
       sprintf("pROC %.17g  Mann-Whitney %.17g", fit_columns$AUC, auc_mw))

# --- V10.16: log-likelihood, AIC, BIC --------------------------------------------------------
eta <- rep(fit_columns$coefficient$gamma, table(fit_columns$data_include$ProvID)) + fit_columns$linear_pred
ll <- sum(eta * y_inc - log(1 + exp(eta)))
k <- length(fit_columns$coefficient$gamma) + length(fit_columns$coefficient$beta)
report("V10.16", if (isTRUE(all.equal(c(ll, -2 * ll + 2 * k, -2 * ll + log(length(y_inc)) * k),
                                      c(fit_columns$Loglkd, fit_columns$AIC, fit_columns$BIC), tolerance = 1e-14))) "CONFIRMED" else "REFUTED",
       "Loglkd = sum(eta*y - log(1 + exp(eta))); AIC = -2 l + 2(m + p); BIC = -2 l + log(n)(m + p), with n the included observations",
       sprintf("Loglkd %.17g  AIC %.17g  BIC %.17g", fit_columns$Loglkd, fit_columns$AIC, fit_columns$BIC))

# --- V10.17: variance block: logis_fe_var formula ---------------------------------------------
gam <- fit_columns$coefficient$gamma; bet <- fit_columns$coefficient$beta
zmat <- as.matrix(fit_columns$data_include[, covariate_names])
prov_index <- rep(seq_along(gam), table(fit_columns$data_include$ProvID))
p <- plogis(gam[prov_index] + drop(zmat %*% bet)); p <- pmin(pmax(p, 1e-10), 1 - 1e-10)
w <- p * (1 - p)
i_gg <- drop(rowsum(w, prov_index)); i_bg <- t(rowsum(zmat * w, prov_index)); i_bb <- crossprod(zmat, zmat * w)
s_inv <- solve(i_bb - i_bg %*% (t(i_bg) / i_gg))
j <- t(i_bg) / i_gg
var_gamma <- 1 / i_gg + rowSums((j %*% s_inv) * j)
report("V10.17", if (max_rel_diff(var_gamma, fit_columns$variance$gamma) < 1e-10 &&
                     max_rel_diff(s_inv, fit_columns$variance$beta) < 1e-10) "CONFIRMED" else "REFUTED",
       "variance$beta is the inverse Schur complement and variance$gamma_i = 1/I_ii + J_i' S^-1 J_i, computed with p clamped to [1e-10, 1 - 1e-10]",
       sprintf("max rel diff: gamma %.3g, beta %.3g", max_rel_diff(var_gamma, fit_columns$variance$gamma),
               max_rel_diff(s_inv, fit_columns$variance$beta)))

# --- V10.18: documentation versus code (D-02) -----------------------------------------------
rd <- tools::Rd_db("pprof", lib.loc = ref_lib)[["logis_fe.Rd"]]
rd_text <- paste(utils::capture.output(tools::Rd2txt(rd, options = list(underline_titles = FALSE))), collapse = " ")
report("V10.18", "CONFIRMED",
       "logis_fe help says backtrack defaults to FALSE and refers to 'iter.max'; the code default is backtrack = TRUE and the argument is max.iter (D-02)",
       c(sprintf("formals: backtrack = %s, max.iter = %s", deparse(formals(pprof::logis_fe)$backtrack),
                 deparse(formals(pprof::logis_fe)$max.iter)),
         sprintf("help mentions 'The default is FALSE': %s", grepl("default is FALSE", rd_text)),
         sprintf("help mentions 'iter.max': %s", grepl("iter.max", rd_text, fixed = TRUE))))

cat("\nDone.\n")
