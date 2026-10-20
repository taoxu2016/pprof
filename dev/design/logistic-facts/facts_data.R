# Shared helpers of the logistic extensions facts (README.md): the libraries the scripts load, and
# synthetic provider data with clusters of rows and, optionally, a number of trials per row.
#
# Sourced by the numbered scripts, which run from the repository root with LOGISTIC_FACTS_SCRATCH
# set; 01_libraries.R builds the libraries first.

facts_scratch <- function() {
  scratch <- Sys.getenv("LOGISTIC_FACTS_SCRATCH")
  if (!nzchar(scratch)) stop("Set LOGISTIC_FACTS_SCRATCH (see README.md)")
  normalizePath(scratch, winslash = "/", mustWork = TRUE)
}

# The libraries built by 01_libraries.R: pprofR 0.2.0 (commit f23c288), pprof from the commit
# 01 was run at, and the independent references (sandwich), ahead of the site library.
facts_use_libraries <- function() {
  scratch <- facts_scratch()
  libs <- file.path(scratch, c("lib-pprofr", "lib-pprof", "lib-ref"))
  missing <- libs[!dir.exists(libs)]
  if (length(missing) > 0L) stop("Run 01_libraries.R first; missing: ", paste(missing, collapse = ", "))
  .libPaths(c(libs, .libPaths()))
  invisible(libs)
}

# Synthetic data for a logistic model with provider effects and clusters of rows within providers:
# `m` providers with `clusters` clusters each (a range), each cluster with 1 to `max_rows` rows in
# their time order; a cluster's rows share a random intercept with standard deviation
# `cluster_sd`, so that rows within a cluster are correlated. `trials` is NULL (one trial per row,
# a binary outcome) or the range of the number of trials of a row. The rows come grouped by
# provider and, within a provider, by cluster, with zero-padded IDs, so that sorting by provider
# (pprof) and by provider and cluster (pprofR) keep the same order.
facts_simulate <- function(m = 40, clusters = c(8, 30), max_rows = 4, trials = NULL, cluster_sd = 0.6,
                           effect_sd = 0.5, effect_mean = -0.8, beta = c(0.5, -0.4, 0.3), seed = 1) {
  set.seed(seed)
  n_clusters <- sample(clusters[1]:clusters[2], m, replace = TRUE)
  provider_of_cluster <- rep(seq_len(m), n_clusters)
  rows_of_cluster <- sample(seq_len(max_rows), length(provider_of_cluster), replace = TRUE)
  provider <- rep(provider_of_cluster, rows_of_cluster)
  cluster <- rep(seq_along(provider_of_cluster), rows_of_cluster)
  n <- length(provider)
  x <- cbind(x1 = round(stats::rnorm(n), 3), x2 = stats::rbinom(n, 1, 0.4), x3 = round(stats::runif(n, -1, 1), 3))
  gamma <- stats::rnorm(m, effect_mean, effect_sd)
  u <- stats::rnorm(length(provider_of_cluster), 0, cluster_sd)
  eta <- gamma[provider] + u[cluster] + drop(x %*% beta)
  size <- if (is.null(trials)) rep(1L, n) else sample(trials[1]:trials[2], n, replace = TRUE)
  y <- stats::rbinom(n, size, stats::plogis(eta))
  data.frame(y = y, n = size, provider = sprintf("P%03d", provider), cluster = sprintf("C%05d", cluster), x,
             stringsAsFactors = FALSE)
}

# pprofR's data preparation of a data frame from facts_simulate(), quietly; `cluster` adds the
# cluster column as pprofR's `PatientID`, and `binomial` the trials as its `N`.
facts_pprofr_prep <- function(d, binomial = FALSE, cluster = TRUE, cutoff = 1) {
  arguments <- list(Y = d["y"], Z = d[c("x1", "x2", "x3")], ProvID = d["provider"], cutoff = cutoff,
                    check = FALSE, message = FALSE)
  if (binomial) arguments$N <- d$n
  if (cluster) arguments$PatientID <- d["cluster"]
  suppressWarnings(suppressMessages(do.call(pprofR::fe_data_prep, arguments)))
}

# Largest absolute and relative differences of two numeric vectors, and whether they are identical
# (bitwise, names and attributes ignored).
facts_compare <- function(a, b) {
  a <- as.numeric(a)
  b <- as.numeric(b)
  finite <- is.finite(a) & is.finite(b)
  same_nonfinite <- identical(is.finite(a), is.finite(b)) && all(a[!finite] == b[!finite] | (is.na(a[!finite]) & is.na(b[!finite])), na.rm = TRUE)
  abs_diff <- if (any(finite)) max(abs(a[finite] - b[finite])) else 0
  rel_diff <- if (any(finite)) max(abs(a[finite] - b[finite]) / pmax(abs(b[finite]), .Machine$double.xmin)) else 0
  c(max_abs = abs_diff, max_rel = rel_diff, identical = as.numeric(identical(a, b) && same_nonfinite))
}

# One line of a comparison table.
facts_row <- function(label, a, b) {
  d <- facts_compare(a, b)
  sprintf("| %s | %.3g | %.3g | %s |", label, d[["max_abs"]], d[["max_rel"]], if (d[["identical"]] == 1) "yes" else "no")
}

facts_header <- function(title) c(title, "", "| Quantity | Largest absolute difference | Largest relative difference | Identical |",
                                  "|---|---|---|---|")
