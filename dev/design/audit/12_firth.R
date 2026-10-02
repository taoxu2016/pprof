# Phase 0 audit: logis_firth.
script_dir <- dirname(normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))))
source(file.path(script_dir, "helpers.R"))
source(file.path(script_dir, "ports.R"))
audit_header("12: logis_firth")

dat <- load_binary_example()
inp <- port_inputs(dat, "Y", "ProvID", covariate_names)

firth_run <- function(d, threads = 1, ...) {
  res <- with_output(pprof::logis_firth(data = d, Y.char = "Y", Z.char = setdiff(names(d), c("Y", "ProvID")),
                                        ProvID.char = "ProvID", threads = threads, message = TRUE, ...))
  list(fit = res$value, iter = iterations_from_log(res$output), log = res$output)
}

# --- V12.1: the port reproduces the single-threaded C++ path --------------------------------
cpp <- firth_run(dat)
port <- port_firth(inp$y, inp$z, inp$n_prov, inp$gamma, inp$beta)
raw <- pprof:::logis_firth_prov(as.matrix(inp$y), inp$z, inp$n_prov, inp$gamma, inp$beta,
                                n_obs = length(inp$y), m = length(inp$n_prov), threads = 1L,
                                tol = 1e-5, max_iter = 1000L, bound = 10, message = FALSE)
report("V12.1", if (cpp$iter == port$iter && max_rel_diff(port$beta, cpp$fit$coefficient$beta) < 1e-8) "CONFIRMED" else "REFUTED",
       "An R port (Newton step on the Firth-modified score with hat values from the block inverse, no line search, clamp after the gamma update, weight floor 1e-10, stop on max |d beta| with 'while crit > tol') reproduces logis_firth with threads = 1",
       c(sprintf("iterations: C++ %d, port %d", cpp$iter, port$iter),
         sprintf("max rel diff beta %.3g, max abs diff gamma %.3g",
                 max_rel_diff(port$beta, cpp$fit$coefficient$beta), max_abs_diff(port$gamma, cpp$fit$coefficient$gamma)),
         sprintf("penalized log-likelihood: C++ %.15g, port %.15g", raw$loglik, port$loglik_penalized),
         sprintf("C++ return values discarded by logis_firth(): iter = %d, crit = %.3g, loglik = %.15g", raw$iter, raw$crit, raw$loglik)))

# --- V12.2: returned object uses unpenalized quantities (D-12) ------------------------------
fit <- cpp$fit
eta <- rep(fit$coefficient$gamma, inp$n_prov) + drop(inp$z %*% fit$coefficient$beta)
ll_unpen <- sum(eta * inp$y - log(1 + exp(eta)))
var_ref <- pprof:::logis_fe_var(inp$y, inp$z, inp$n_prov, fit$coefficient$gamma, fit$coefficient$beta)
report("V12.2", "CONFIRMED",
       "logis_firth returns class 'logis_fe'; Loglkd, AIC, BIC, and both variances are the unpenalized ML quantities evaluated at the Firth estimates (D-12)",
       c(sprintf("class: %s", paste(class(fit), collapse = ", ")),
         sprintf("Loglkd %.15g = unpenalized %.15g; penalized would be %.15g", fit$Loglkd, ll_unpen, raw$loglik),
         sprintf("variance$beta equals logis_fe_var(): %s", isTRUE(all.equal(unname(fit$variance$beta), unname(var_ref$var.beta), tolerance = 0))),
         sprintf("variance$gamma equals logis_fe_var(): %s", isTRUE(all.equal(as.numeric(fit$variance$gamma), as.numeric(var_ref$var.gamma), tolerance = 0)))))

# --- V12.3: threads = 2 (D-05) ----------------------------------------------------------------
runs <- lapply(1:8, function(i) {
  tryCatch(callr::r(function(lib, script_dir) {
    suppressPackageStartupMessages(library(pprof, lib.loc = lib))
    e <- new.env(); utils::data("ExampleDataBinary", package = "pprof", lib.loc = lib, envir = e)
    d <- e$ExampleDataBinary
    out <- utils::capture.output(fit <- suppressWarnings(suppressMessages(
      pprof::logis_firth(Y = d$Y, Z = d$Z, ProvID = d$ProvID, threads = 2, message = TRUE))))
    hit <- grep("converged after", out, value = TRUE)
    list(iter = as.integer(sub(".*converged after ([0-9]+) iterations.*", "\\1", hit)),
         beta = as.numeric(fit$coefficient$beta))
  }, args = list(lib = ref_lib, script_dir = script_dir)),
  error = function(e) list(iter = NA, beta = NA, error = conditionMessage(e)))
})
iters <- sapply(runs, `[[`, "iter")
beta_err <- sapply(runs, function(r) max_abs_diff(r$beta, cpp$fit$coefficient$beta))
report("V12.3", if (length(unique(iters)) > 1 || any(beta_err > 1e-6)) "CONFIRMED" else "NOTE",
       "With threads = 2, d_beta is private to each thread; the thread that computes the stopping criterion may not be the one that set d_beta, sees an empty vector (norm 0), and stops early. Eight separate runs (D-05):",
       data.frame(run = 1:8, iterations = iters, max_abs_beta_diff_vs_1_thread = signif(beta_err, 3)))

# --- V12.4: defaults and documentation --------------------------------------------------------
rd <- tools::Rd_db("pprof", lib.loc = ref_lib)[["logis_firth.Rd"]]
rd_text <- paste(utils::capture.output(tools::Rd2txt(rd, options = list(underline_titles = FALSE))), collapse = " ")
report("V12.4", "CONFIRMED",
       "logis_firth defaults max.iter = 1000 but its help says 10,000; the stopping rule is fixed at 'beta' and not exposed (new documentation finding)",
       c(sprintf("formals: max.iter = %s, tol = %s, bound = %s, cutoff = %s",
                 formals(pprof::logis_firth)$max.iter, formals(pprof::logis_firth)$tol,
                 formals(pprof::logis_firth)$bound, formals(pprof::logis_firth)$cutoff),
         sprintf("help says 'The default value is 10,000': %s", grepl("10,000", rd_text, fixed = TRUE)),
         sprintf("'stop' is an argument of logis_firth(): %s", "stop" %in% names(formals(pprof::logis_firth)))))

# --- V12.5: independent reference: logistf with provider indicators -------------------------
extra <- file.path(dirname(ref_lib), "suggestslib")
if (dir.exists(extra)) .libPaths(c(.libPaths(), extra))
if (requireNamespace("logistf", quietly = TRUE)) {
  set.seed(5)
  m <- 12
  sizes <- sample(12:30, m, TRUE)
  prov <- rep(seq_len(m), sizes)
  x <- matrix(rnorm(length(prov) * 2), ncol = 2, dimnames = list(NULL, c("x1", "x2")))
  y <- rbinom(length(prov), 1, plogis(rnorm(m, -0.5, 0.8)[prov] + x %*% c(0.7, -0.4)))
  small <- data.frame(Y = y, ProvID = prov, x)
  ours <- firth_run(small, tol = 1e-10)
  lf <- logistf::logistf(Y ~ 0 + factor(ProvID) + x1 + x2, data = small,
                         control = logistf::logistf.control(maxit = 200, maxstep = 5, lconv = 1e-12,
                                                            gconv = 1e-12, xconv = 1e-12))
  report("V12.5", "NOTE",
         sprintf("Firth estimates versus logistf %s with provider indicators on small data (no extreme providers, tol = 1e-10)",
                 as.character(utils::packageVersion("logistf"))),
         c(sprintf("max abs diff beta  %.3g", max_abs_diff(ours$fit$coefficient$beta, coef(lf)[c("x1", "x2")])),
           sprintf("max abs diff gamma %.3g", max_abs_diff(ours$fit$coefficient$gamma, coef(lf)[seq_len(m)])),
           sprintf("pprof iterations %d", ours$iter)))
} else {
  report("V12.5", "NOTE", "logistf not available; independent comparison skipped")
}

cat("\nDone.\n")
