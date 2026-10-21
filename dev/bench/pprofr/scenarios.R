# The scenarios of the pprofR benchmark baseline (LOGISTIC_L1_PLAN §3.7; LOGISTIC_DESIGN §I; DEC-160): one factor at a
# time around a centre of 100,000 rows, 1,000 providers of equal size, 10 trials a row, 5 covariates, and clusters of 1
# to 4 rows whose rows share a random intercept. The data of a scenario are made once, with its seed, and kept as RDS
# in a data directory, so that every task reads the same rows.

pprofr_bench_scenarios <- data.frame(
  scenario = c("centre", "binary", "trials-100", "rows-1e4", "rows-1e6", "covariates-20"),
  n = c(1e5, 1e5, 1e5, 1e4, 1e6, 1e5),
  m = c(1000, 1000, 1000, 100, 1000, 1000),
  trials = c(10, 1, 100, 10, 10, 10),
  p = c(5, 5, 5, 5, 5, 20),
  seed = c(301, 302, 303, 304, 305, 306),
  stringsAsFactors = FALSE
)

pprofr_bench_scenario <- function(scenario) {
  sc <- pprofr_bench_scenarios[pprofr_bench_scenarios$scenario == scenario, ]
  if (nrow(sc) != 1L) stop("Unknown scenario: ", scenario)
  sc
}

# The rows of a scenario: providers of n / m rows; clusters of 1 to 4 consecutive rows, cut at the providers'
# boundaries (clusters are (provider, label) pairs); covariates on a grid of 1/64.
pprofr_bench_make <- function(scenario) {
  sc <- pprofr_bench_scenario(scenario)
  set.seed(sc$seed)
  n <- sc$n
  provider <- rep(seq_len(sc$m), each = n / sc$m)
  sizes <- sample.int(4L, n, replace = TRUE)
  label <- rep(seq_along(sizes), sizes)[seq_len(n)]
  cluster <- match(paste(provider, label), unique(paste(provider, label)))
  x <- matrix(round(stats::rnorm(n * sc$p) * 64) / 64, n, sc$p, dimnames = list(NULL, paste0("x", seq_len(sc$p))))
  beta <- seq(0.4, -0.4, length.out = sc$p)
  gamma <- stats::rnorm(sc$m, -0.8, 0.5)
  u <- stats::rnorm(max(cluster), 0, 0.6)
  eta <- gamma[provider] + u[cluster] + drop(x %*% beta)
  trials <- rep(as.integer(sc$trials), n)
  y <- stats::rbinom(n, trials, stats::plogis(eta))
  data.frame(y = as.integer(y), n = trials, provider = sprintf("P%04d", provider), cluster = sprintf("C%07d", cluster),
             x, stringsAsFactors = FALSE)
}

pprofr_bench_data <- function(dir, scenario) readRDS(file.path(dir, paste0(scenario, ".rds")))
