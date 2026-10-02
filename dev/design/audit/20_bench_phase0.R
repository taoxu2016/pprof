# Phase 0 preliminary timings for the R/C++ boundary (ARCHITECTURE §F).
# Not the Phase 1 benchmark suite: one machine, few repetitions, single thread.
script_dir <- dirname(normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))))
source(file.path(script_dir, "helpers.R"))
source(file.path(script_dir, "ports.R"))
audit_header("20: preliminary timings")
suppressPackageStartupMessages(library(bench))

# The expression is captured unevaluated and re-evaluated on every iteration; passing it
# through as a promise would time only the first evaluation.
time_it <- function(expr, iterations = 3) {
  code <- substitute(expr)
  env <- parent.frame()
  b <- bench::mark(eval(code, env), iterations = iterations, check = FALSE, memory = TRUE,
                   filter_gc = FALSE)
  c(median_s = as.numeric(b$median), r_alloc_mb = as.numeric(b$mem_alloc) / 2^20)
}

simulate_binary <- function(m, mean_size, p = 10, seed = 1) {
  set.seed(seed)
  sizes <- pmax(stats::rpois(m, mean_size), 10L)
  prov <- rep(seq_len(m), sizes)
  z <- matrix(stats::rnorm(length(prov) * p), ncol = p, dimnames = list(NULL, paste0("x", seq_len(p))))
  y <- stats::rbinom(length(prov), 1, stats::plogis(stats::rnorm(m, -2, 0.6)[prov] + drop(z %*% seq(-0.5, 0.5, length.out = p))))
  data.frame(Y = y, ProvID = prov, z)
}

# --- B1: SerBIN in C++ versus the line-by-line R port, same path ------------------------------------
rows <- list()
for (cfg in list(c(m = 1000, size = 80), c(m = 3000, size = 100))) {
  d <- simulate_binary(cfg[["m"]], cfg[["size"]])
  inp <- port_inputs(d, "Y", "ProvID", paste0("x", 1:10))
  cpp <- time_it(pprof:::logis_BIN_fe_prov(as.matrix(inp$y), inp$z, inp$n_prov, inp$gamma, inp$beta,
                                           threads = 1L, tol = 1e-5, max_iter = 10000L, bound = 10,
                                           message = FALSE, backtrack = TRUE, stop = "or"))
  port <- time_it(port_serbin(inp$y, inp$z, inp$n_prov, inp$gamma, inp$beta))
  whole <- time_it(quiet_logis_fe(data = d, Y.char = "Y", Z.char = paste0("x", 1:10), ProvID.char = "ProvID"))
  rows[[length(rows) + 1]] <- data.frame(n = nrow(d), m = cfg[["m"]], p = 10,
                                         cpp_core_s = cpp[["median_s"]], r_port_s = port[["median_s"]],
                                         r_port_alloc_mb = port[["r_alloc_mb"]],
                                         logis_fe_total_s = whole[["median_s"]],
                                         logis_fe_alloc_mb = whole[["r_alloc_mb"]])
}
report("B1", "NOTE",
       "SerBIN: C++ core versus an R port with identical iterations (stop = 'or'), and the whole logis_fe() call; R allocations only (C++ allocations are not tracked)",
       do.call(rbind, rows))

# --- B2: linear_fe dense centering versus direct demeaning ------------------------------------------------
lin_rows <- list()
for (size in c(250, 500, 1000)) {
  set.seed(size)
  m <- 20
  prov <- rep(seq_len(m), each = size)
  z <- matrix(rnorm(length(prov) * 5), ncol = 5, dimnames = list(NULL, paste0("x", 1:5)))
  d <- data.frame(Y = rnorm(m)[prov] + drop(z %*% rep(1, 5)) + rnorm(length(prov)), ProvID = prov, z)
  ref <- time_it(suppressMessages(pprof::linear_fe(data = d, Y.char = "Y", Z.char = paste0("x", 1:5), ProvID.char = "ProvID")), 2)
  demean <- function() {
    zc <- z - rowsum(z, prov)[prov, ] / size
    yc <- d$Y - (rowsum(d$Y, prov) / size)[prov]
    solve(crossprod(zc), crossprod(zc, yc))
  }
  dm <- time_it(demean(), 3)
  fit <- suppressMessages(pprof::linear_fe(data = d, Y.char = "Y", Z.char = paste0("x", 1:5), ProvID.char = "ProvID"))
  lin_rows[[length(lin_rows) + 1]] <- data.frame(m = m, n_i = size, sum_n_i_sq = m * size^2,
                                                 linear_fe_s = ref[["median_s"]], linear_fe_alloc_mb = ref[["r_alloc_mb"]],
                                                 demean_beta_s = dm[["median_s"]], demean_alloc_mb = dm[["r_alloc_mb"]],
                                                 max_rel_beta_diff = max_rel_diff(demean(), fit$coefficient$beta))
}
report("B2", "NOTE",
       "linear_fe builds n_i x n_i centering blocks with Matrix::bdiag, so time and memory grow with sum(n_i^2); demeaning gives the same beta at O(np)",
       do.call(rbind, lin_rows))

# --- B3: direct-standardization expectations: C++ versus vectorized R --------------------------------------
d <- simulate_binary(1000, 80)
fit <- quiet_logis_fe(data = d, Y.char = "Y", Z.char = paste0("x", 1:10), ProvID.char = "ProvID")
zb <- as.numeric(fit$linear_pred)
g <- as.numeric(fit$coefficient$gamma)
cpp_d <- time_it(pprof:::computeDirectExp(g, zb, 1L))
r_d <- time_it(vapply(g, function(gi) sum(plogis(gi + zb)), numeric(1)))
report("B3", "NOTE",
       "computeDirectExp (m x n logistic evaluations) in C++ versus vapply() over providers in R",
       c(sprintf("n = %d, m = %d: C++ %.3f s, R %.3f s (R allocations %.1f MB)", length(zb), length(g),
                 cpp_d[["median_s"]], r_d[["median_s"]], r_d[["r_alloc_mb"]]),
         sprintf("max rel diff %.3g", max_rel_diff(vapply(g, function(gi) sum(plogis(gi + zb)), numeric(1)),
                                                   pprof:::computeDirectExp(g, zb, 1L)))))

# --- B4: post-estimation scaling -----------------------------------------------------------------------------
post <- list()
for (m in c(100, 200, 400)) {
  d <- simulate_binary(m, 60, p = 5, seed = m)
  f <- quiet_logis_fe(data = d, Y.char = "Y", Z.char = paste0("x", 1:5), ProvID.char = "ProvID")
  post[[length(post) + 1]] <- data.frame(
    m = m, n = nrow(d),
    test_exact_s = time_it(test(f), 1)[["median_s"]],
    test_score_standard_s = time_it(test(f, test = "score", score_modified = FALSE), 1)[["median_s"]],
    confint_gamma_exact_s = time_it(confint(f, option = "gamma"), 1)[["median_s"]],
    confint_SM_exact_s = time_it(confint(f, option = "SM"), 1)[["median_s"]],
    summary_lr_s = time_it(suppressMessages(summary(f, test = "lr")), 1)[["median_s"]])
}
report("B4", "NOTE",
       "Post-estimation run time as the number of providers grows (provider size about 60, p = 5, one run each)",
       do.call(rbind, post))

# --- B5: object size of a reference fit versus the proposed compact fields -------------------------
size_rows <- list()
for (cfg in list(c(m = 1000, size = 80), c(m = 3000, size = 100))) {
  d <- simulate_binary(cfg[["m"]], cfg[["size"]])
  f <- quiet_logis_fe(data = d, Y.char = "Y", Z.char = paste0("x", 1:10), ProvID.char = "ProvID")
  n <- nrow(f$data_include); m <- length(f$coefficient$gamma); p <- length(f$coefficient$beta)
  compact <- list(coefficients = setNames(as.numeric(f$coefficient$beta), rownames(f$coefficient$beta)),
                  provider_effects = setNames(as.numeric(f$coefficient$gamma), rownames(f$coefficient$gamma)),
                  vcov = unname(f$variance$beta), provider_effect_variance = as.numeric(f$variance$gamma),
                  providers = data.frame(provider_id = rownames(f$coefficient$gamma), n_obs = as.integer(table(f$data_include$ProvID)),
                                         n_events = as.integer(rowsum(f$data_include$Y, f$data_include$ProvID)),
                                         included = TRUE, no_events = FALSE, all_events = FALSE),
                  response = as.integer(f$data_include$Y), linear_predictor = as.numeric(f$linear_pred),
                  provider_index = rep.int(seq_len(m), table(f$data_include$ProvID)))
  size_rows[[length(size_rows) + 1]] <- data.frame(
    n = n, m = m, p = p,
    reference_object_mb = as.numeric(utils::object.size(f)) / 2^20,
    reference_data_include_mb = as.numeric(utils::object.size(f$data_include)) / 2^20,
    reference_fitted_plus_linear_pred_mb = as.numeric(utils::object.size(f$fitted) + utils::object.size(f$linear_pred)) / 2^20,
    compact_mb = as.numeric(utils::object.size(compact)) / 2^20,
    design_matrix_mb = 8 * n * p / 2^20)
}
report("B5", "NOTE",
       "Size of a reference logis_fe object versus the compact fields proposed in ARCHITECTURE §D (keep_data = FALSE); the design matrix is what keep_data = TRUE would add",
       do.call(rbind, size_rows))

cat("\nDone.\n")
