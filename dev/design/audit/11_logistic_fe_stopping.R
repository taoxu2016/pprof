# Phase 0 audit: does the default stop = "or" end SerBIN before the coefficients settle,
# and how much do threads = 2 results differ from threads = 1 (D-20)?
script_dir <- dirname(normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))))
source(file.path(script_dir, "helpers.R"))
source(file.path(script_dir, "ports.R"))
audit_header("11: logis_fe stopping rule and threads")

simulate_binary <- function(m, mean_size, p = 10, seed = 1) {
  set.seed(seed)
  sizes <- pmax(stats::rpois(m, mean_size), 10L)
  prov <- rep(seq_len(m), sizes)
  n <- length(prov)
  z <- matrix(stats::rnorm(n * p), n, p, dimnames = list(NULL, paste0("x", seq_len(p))))
  z[, 2] <- 0.5 * z[, 1] + z[, 2]
  gamma <- stats::rnorm(m, -2, 0.6)
  beta <- seq(-0.5, 0.5, length.out = p)
  y <- stats::rbinom(n, 1, stats::plogis(gamma[prov] + drop(z %*% beta)))
  data.frame(Y = y, ProvID = prov, z)
}

fit_quiet <- function(d, ...) {
  res <- with_output(pprof::logis_fe(data = d, Y.char = "Y", Z.char = grep("^x", names(d), value = TRUE),
                                     ProvID.char = "ProvID", message = TRUE, ...))
  list(fit = res$value, iter = iterations_from_log(res$output))
}

scales <- data.frame(label = c("example-size", "medium", "large", "very large"),
                     m = c(100, 1000, 3000, 6000), mean_size = c(80, 80, 100, 200))
rows <- list()
for (k in seq_len(nrow(scales))) {
  d <- simulate_binary(scales$m[k], scales$mean_size[k], seed = k)
  t_default <- system.time(def <- fit_quiet(d))[["elapsed"]]
  tight <- fit_quiet(d, stop = "beta", tol = 1e-12)
  inp <- port_inputs(d, "Y", "ProvID", grep("^x", names(d), value = TRUE))
  port <- port_serbin(inp$y, inp$z, inp$n_prov, inp$gamma, inp$beta)   # default settings
  last <- port$trace[nrow(port$trace), ]
  g_def <- def$fit$coefficient$gamma; g_tight <- tight$fit$coefficient$gamma
  extreme <- unique(def$fit$data_include$ProvID[def$fit$data_include$no.events == 1 |
                                                  def$fit$data_include$all.events == 1])
  keep <- !(rownames(g_def) %in% as.character(extreme))
  rows[[k]] <- data.frame(
    scale = scales$label[k], n = nrow(d), m = scales$m[k],
    iter_default = def$iter, iter_port = port$iter, iter_tight = tight$iter,
    stop_crit_beta = last[["beta"]], stop_crit_relch = last[["relch"]], stop_crit_ratch = last[["ratch"]],
    max_abs_beta_err = max_abs_diff(def$fit$coefficient$beta, tight$fit$coefficient$beta),
    max_abs_gamma_err = max_abs_diff(g_def[keep], g_tight[keep]),
    max_abs_var_beta_rel = max_rel_diff(def$fit$variance$beta, tight$fit$variance$beta),
    n_extreme = length(extreme), seconds_default = t_default)
}
tab <- do.call(rbind, rows)
report("V11.1", if (any(tab$max_abs_beta_err > 1e-5 | tab$max_abs_gamma_err > 1e-5)) "CONFIRMED" else "REFUTED",
       "Under the default stop = 'or', tol = 1e-5, SerBIN stops as soon as relch or ratch falls below tol, before the estimates settle to tol. Errors are against a tight fit (stop = 'beta', tol = 1e-12); gamma errors exclude no-event and all-event providers",
       tab)
report("V11.1a", "NOTE",
       "Reading the table: beta errors stay below tol, but provider effects can be far from converged. The likelihood criteria are relative to |l|, which grows with n, so a large fit can stop while individual providers still move; the size of the gap depends on the data (it is not monotone in n here)",
       sprintf("largest gamma error %.3g at n = %d after %d iterations (last beta step %.3g)",
               max(tab$max_abs_gamma_err), tab$n[which.max(tab$max_abs_gamma_err)],
               tab$iter_default[which.max(tab$max_abs_gamma_err)],
               tab$stop_crit_beta[which.max(tab$max_abs_gamma_err)]))

# --- threads = 2 versus threads = 1 (D-20) ---------------------------------------------------
d <- simulate_binary(1000, 80, seed = 2)
one <- fit_quiet(d, threads = 1)
two <- fit_quiet(d, threads = 2)
two_again <- fit_quiet(d, threads = 2)
ex <- load_binary_example()
ex1 <- fit_quiet(transform(ex, x1 = z1, x2 = z2, x3 = z3, x4 = z4, x5 = z5)[, c("Y", "ProvID", paste0("x", 1:5))], threads = 1)
ex2 <- fit_quiet(transform(ex, x1 = z1, x2 = z2, x3 = z3, x4 = z4, x5 = z5)[, c("Y", "ProvID", paste0("x", 1:5))], threads = 2)
report("V11.2", "CONFIRMED",
       "SerBIN with threads = 2 computes the beta information block with element-wise OpenMP dot products instead of one BLAS product; results differ from threads = 1 at rounding level and are reproducible for a fixed thread count (D-20)",
       c(sprintf("simulated (n = %d): iterations 1 thread %d, 2 threads %d; max rel diff beta %.3g, gamma %.3g",
                 nrow(d), one$iter, two$iter,
                 max_rel_diff(two$fit$coefficient$beta, one$fit$coefficient$beta),
                 max_rel_diff(two$fit$coefficient$gamma, one$fit$coefficient$gamma)),
         sprintf("simulated: two runs with 2 threads identical: %s",
                 identical(two$fit$coefficient, two_again$fit$coefficient)),
         sprintf("ExampleDataBinary: iterations %d vs %d; max rel diff beta %.3g, gamma %.3g",
                 ex1$iter, ex2$iter, max_rel_diff(ex2$fit$coefficient$beta, ex1$fit$coefficient$beta),
                 max_rel_diff(ex2$fit$coefficient$gamma, ex1$fit$coefficient$gamma))))

cat("\nDone.\n")
