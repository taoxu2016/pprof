# The synthetic data sets of the pprofR fixtures (LOGISTIC_L1_PLAN §2; DEC-157).
#
# Providers with clusters of rows, whose rows share a random intercept, so that rows within a cluster
# are correlated; one trial per row (binary outcomes) or several (binomial outcomes). The data are exact
# in text: integer events, trials, and labels, and covariates on a grid of 1/64. Rows come grouped by
# provider and, within a provider, by cluster, with zero-padded labels, so that pprofR's sort (by
# provider, then by cluster) and pprof's (by provider, stable) keep the same order (D-97).
#
# Base R only. Sourced by generate.R, which builds the data sets in its own session, and by the
# calibration (calibrate.R).

pprofr_grid <- function(x) round(x * 64) / 64

# An integer from `range[1]` to `range[2]` for each of `size` draws (sample() would read a range of
# one value, c(k, k), as 1:k).
pprofr_draw <- function(range, size) range[1] + sample.int(range[2] - range[1] + 1L, size, replace = TRUE) - 1L

# `m` providers; `clusters`, the range of each provider's number of clusters, or `cluster_counts`, one
# number per provider; `rows`, the range of a cluster's number of rows; `trials`, NULL for one trial per
# row or the range of a row's trials. Covariates: x1 normal, x2 binary, x3 uniform on [-1, 1].
pprofr_simulate <- function(m, clusters = NULL, rows, trials = NULL, seed, cluster_counts = NULL, cluster_sd = 0.6,
                            effect_sd = 0.5, effect_mean = -0.8, beta = c(0.5, -0.4, 0.3)) {
  set.seed(seed)
  n_clusters <- if (is.null(cluster_counts)) pprofr_draw(clusters, m) else cluster_counts
  provider_of_cluster <- rep(seq_len(m), n_clusters)
  rows_of_cluster <- pprofr_draw(rows, length(provider_of_cluster))
  provider <- rep(provider_of_cluster, rows_of_cluster)
  cluster <- rep(seq_along(provider_of_cluster), rows_of_cluster)
  n <- length(provider)
  x <- cbind(x1 = pprofr_grid(stats::rnorm(n)), x2 = stats::rbinom(n, 1, 0.4), x3 = pprofr_grid(stats::runif(n, -1, 1)))
  gamma <- stats::rnorm(m, effect_mean, effect_sd)
  u <- stats::rnorm(length(provider_of_cluster), 0, cluster_sd)
  eta <- gamma[provider] + u[cluster] + drop(x %*% beta)
  size <- if (is.null(trials)) rep(1L, n) else pprofr_draw(trials, n)
  y <- stats::rbinom(n, size, stats::plogis(eta))
  data.frame(y = as.integer(y), n = as.integer(size), provider = sprintf("P%03d", provider),
             cluster = sprintf("C%05d", cluster), x1 = x[, "x1"], x2 = x[, "x2"], x3 = x[, "x3"],
             stringsAsFactors = FALSE)
}

# Negative controls (the brief's §3.5). One event moved between two rows of the first provider whose
# rows allow it: from its first row with an event to its last row with room for one.
pprofr_move_event <- function(d) {
  for (p in unique(d$provider)) {
    rows <- which(d$provider == p)
    from <- rows[d$y[rows] > 0L]
    to <- rows[d$y[rows] < d$n[rows]]
    if (length(from) && length(setdiff(to, from[1]))) {
      d$y[from[1]] <- d$y[from[1]] - 1L
      to <- setdiff(to, from[1])
      d$y[to[length(to)]] <- d$y[to[length(to)]] + 1L
      return(d)
    }
  }
  stop("No provider allows an event to move.")
}

# One cluster split in two: the first cluster with at least two rows, its later half relabelled.
pprofr_split_cluster <- function(d) {
  sizes <- table(d$cluster)
  target <- names(sizes)[sizes >= 2L][1]
  rows <- which(d$cluster == target)
  d$cluster[rows[seq_along(rows) > length(rows) / 2]] <- paste0(target, "b")
  d
}

# Each cluster's rows in reverse order, the clusters and providers in their order.
pprofr_reverse_clusters <- function(d) {
  order_within <- stats::ave(seq_len(nrow(d)), d$cluster, FUN = rev)
  d[order_within, , drop = FALSE]
}

# The data sets, by name.
pprofr_datasets <- function() {
  binary <- pprofr_simulate(40, c(8L, 30L), c(1L, 4L), seed = 20261021L)
  binomial <- pprofr_simulate(40, c(8L, 30L), c(1L, 4L), trials = c(1L, 20L), seed = 20261022L)
  # Providers of about 1,100 to 2,200 trials: pprofR's exact intervals cost O(T^2) per provider, about 70 s a
  # call here, against 280 s at 2,000 to 4,000 trials (LOGISTIC_L1_PLAN §2).
  many <- pprofr_simulate(12, c(15L, 30L), c(1L, 4L), trials = c(10L, 40L), seed = 20261023L)
  few <- pprofr_simulate(30, rows = c(2L, 6L), trials = c(1L, 5L), seed = 20261024L, cluster_counts = rep(1:3, 10))
  single <- pprofr_simulate(20, rows = c(3L, 8L), trials = c(1L, 5L), seed = 20261025L, cluster_counts = rep(1L, 20))
  # Null probabilities below 1e-10: every 25th row's x1 at -60 (a linear predictor near -30), with no
  # event, as in fact 02's extreme data.
  extreme <- function(d) {
    rows <- seq(1L, nrow(d), by = 25L)
    d$x1[rows] <- -60
    d$y[rows] <- 0L
    d
  }
  # Binomial providers with no events and with only events.
  edges <- pprofr_simulate(30, c(8L, 20L), c(1L, 4L), trials = c(1L, 10L), seed = 20261026L)
  edges$y[edges$provider %in% c("P001", "P002", "P003")] <- 0L
  only <- edges$provider %in% c("P004", "P005", "P006")
  edges$y[only] <- edges$n[only]
  # Rows with zero trials among others, and a provider whose rows all have zero trials.
  zero <- pprofr_simulate(30, c(8L, 20L), c(1L, 4L), trials = c(1L, 10L), seed = 20261027L)
  set.seed(20261028L)
  zero_rows <- sort(sample.int(nrow(zero), round(nrow(zero) / 10)))
  zero$n[zero_rows] <- 0L
  zero$y[zero_rows] <- 0L
  zero_provider <- zero
  zero_provider$n[zero_provider$provider == "P030"] <- 0L
  zero_provider$y[zero_provider$provider == "P030"] <- 0L
  list(
    `binary-moderate` = binary,
    `binomial-moderate` = binomial,
    `binomial-many-trials` = many,
    `few-clusters` = few,
    `one-cluster` = single,
    `extreme-binary` = extreme(binary),
    `extreme-binomial` = extreme(binomial),
    `extreme-providers` = edges,
    `zero-trials` = zero,
    `zero-trial-provider` = zero_provider,
    `binary-event-moved` = pprofr_move_event(binary),
    `binomial-event-moved` = pprofr_move_event(binomial),
    `many-event-moved` = pprofr_move_event(many),
    `binary-cluster-split` = pprofr_split_cluster(binary),
    `binomial-cluster-split` = pprofr_split_cluster(binomial),
    `binomial-reversed` = pprofr_reverse_clusters(binomial)
  )
}

# The standard populations of direct_exp() (case standard-population): a continuous linear predictor,
# one with eight repeated values and integer weights, and effects of up to ±30, with rates near 1.
pprofr_standard_populations <- function() {
  set.seed(20261029L)
  continuous <- pprofr_grid(stats::rnorm(2000, -0.5, 1.2))
  repeated <- rep(pprofr_grid(seq(-2, 1.5, by = 0.5)), each = 250)
  weights <- pprofr_draw(c(0L, 50L), length(repeated))
  list(
    effects = c(-30, -15, -5, -1, -0.25, 0, 0.5, 1, 5, 15, 30),
    continuous = continuous,
    repeated = repeated,
    weights = weights
  )
}
