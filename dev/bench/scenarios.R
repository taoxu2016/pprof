# Benchmark scenarios (brief §3.6): synthetic data over realistic scales of observations,
# providers, and covariates, with balanced and skewed provider sizes and rare, moderate, and
# common outcomes.

bench_set_seed <- function(seed) {
  set.seed(seed, kind = "Mersenne-Twister", normal.kind = "Inversion", sample.kind = "Rejection")
}

# Provider sizes summing to about n: balanced (Poisson around n/m) or skewed (log-normal).
bench_sizes <- function(n, m, skewed) {
  if (skewed) {
    w <- stats::rlnorm(m, 0, 1.2)
    sizes <- pmax(round(w / sum(w) * n), 1L)
  } else {
    sizes <- pmax(stats::rpois(m, n / m), 1L)
  }
  as.integer(sizes)
}

bench_data <- function(scenario) {
  bench_set_seed(scenario$seed)
  sizes <- bench_sizes(scenario$n, scenario$m, scenario$skewed)
  prov <- rep(seq_along(sizes), sizes)
  n <- length(prov)
  p <- scenario$p
  z <- matrix(stats::rnorm(n * p), n, p, dimnames = list(NULL, paste0("x", seq_len(p))))
  beta <- seq(-0.5, 0.5, length.out = p)
  effect <- stats::rnorm(length(sizes), 0, 0.5)
  eta <- effect[prov] + drop(z %*% beta)
  if (identical(scenario$outcome, "binary")) {
    # Intercept chosen so that the mean probability is close to the target event rate.
    target <- scenario$rate
    intercept <- stats::uniroot(function(a) mean(stats::plogis(a + eta)) - target, c(-20, 20))$root
    y <- stats::rbinom(n, 1, stats::plogis(intercept + eta))
  } else {
    y <- eta + stats::rnorm(n)
  }
  data.frame(Y = y, ProvID = prov, z)
}

bench_scenarios <- function() {
  s <- function(id, outcome, n, m, p, skewed = FALSE, rate = 0.1, seed) {
    list(id = id, outcome = outcome, n = n, m = m, p = p, skewed = skewed, rate = rate, seed = seed)
  }
  list(
    s("bin-1e4-m100-p5", "binary", 1e4, 100, 5, seed = 1),
    s("bin-1e5-m1000-p5", "binary", 1e5, 1000, 5, seed = 2),
    s("bin-1e5-m1000-p20", "binary", 1e5, 1000, 20, seed = 3),
    s("bin-1e5-m1000-p5-skewed", "binary", 1e5, 1000, 5, skewed = TRUE, seed = 4),
    s("bin-1e5-m1000-p5-rare", "binary", 1e5, 1000, 5, rate = 0.01, seed = 5),
    s("bin-1e5-m1000-p5-common", "binary", 1e5, 1000, 5, rate = 0.5, seed = 6),
    s("bin-1e5-m10000-p5", "binary", 1e5, 10000, 5, seed = 7),
    s("bin-1e6-m1000-p5", "binary", 1e6, 1000, 5, seed = 8),
    s("bin-1e6-m10000-p5", "binary", 1e6, 10000, 5, seed = 9),
    s("bin-1e6-m1000-p50", "binary", 1e6, 1000, 50, seed = 10),
    s("lin-1e4-m100-p5", "continuous", 1e4, 100, 5, seed = 11),
    s("lin-1e5-m1000-p5", "continuous", 1e5, 1000, 5, seed = 12),
    s("lin-1e5-m10000-p5", "continuous", 1e5, 10000, 5, seed = 13),
    s("lin-1e5-m100-p5", "continuous", 1e5, 100, 5, seed = 14),
    s("lin-1e6-m100000-p5", "continuous", 1e6, 1e5, 5, seed = 15)
  )
}

# Which functions run on which scenario. `fit` is the fit a method needs first (not timed).
bench_tasks <- function() {
  binary <- function(ids, fun, args = list(), fit = NULL) lapply(ids, function(id) list(scenario = id, fun = fun, args = args, fit = fit))
  small <- "bin-1e4-m100-p5"
  medium <- "bin-1e5-m1000-p5"
  all_binary <- c(small, medium, "bin-1e5-m1000-p20", "bin-1e5-m1000-p5-skewed", "bin-1e5-m1000-p5-rare",
                  "bin-1e5-m1000-p5-common", "bin-1e5-m10000-p5", "bin-1e6-m1000-p5", "bin-1e6-m10000-p5", "bin-1e6-m1000-p50")
  fe_fit <- list(fun = "logis_fe", args = list())
  lin_fit <- list(fun = "linear_fe", args = list())
  c(
    binary(all_binary, "logis_fe"),
    binary(c(small, medium, "bin-1e6-m1000-p5"), "logis_fe", list(method = "BAN")),
    binary(c(small, medium, "bin-1e6-m1000-p5"), "logis_firth"),
    binary(c(small, medium), "logis_re"),
    binary(small, "logis_cre"),
    binary(c(small, medium), "test", list(test = "exact.poisbinom"), fe_fit),
    binary(c(small, medium), "test", list(test = "score"), fe_fit),
    binary(c(small, medium), "test", list(test = "score", score_modified = FALSE), fe_fit),
    binary(c(small, medium), "test", list(test = "wald"), fe_fit),
    binary(c(small, medium), "SM_output", list(stdz = "indirect"), fe_fit),
    binary(c(small, medium), "SM_output", list(stdz = "direct"), fe_fit),
    binary(c(small, medium), "confint", list(option = "gamma"), fe_fit),
    binary(small, "confint", list(option = "SM"), fe_fit),
    binary(c(small, medium), "summary", list(test = "wald"), fe_fit),
    binary(small, "summary", list(test = "lr"), fe_fit),
    binary(c("lin-1e4-m100-p5", "lin-1e5-m1000-p5", "lin-1e5-m10000-p5", "lin-1e5-m100-p5", "lin-1e6-m100000-p5"), "linear_fe"),
    binary(c("lin-1e4-m100-p5", "lin-1e5-m1000-p5"), "linear_re"),
    binary("lin-1e4-m100-p5", "linear_cre"),
    binary("lin-1e5-m1000-p5", "test", list(), lin_fit),
    binary("lin-1e5-m1000-p5", "SM_output", list(stdz = c("indirect", "direct")), lin_fit),
    binary("lin-1e5-m1000-p5", "confint", list(), lin_fit)
  )
}

# linear_fe builds dense n_i x n_i centering blocks (B2): skip configurations whose
# sum of squared provider sizes would need more memory than the machine has.
bench_linear_fe_feasible <- function(sizes, max_sum_sq = 2e7) sum(as.numeric(sizes)^2) <= max_sum_sq
