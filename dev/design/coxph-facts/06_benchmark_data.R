# CoxPH brief, Appendix A: synthetic provider-profiling survival data for 07, 08 and 09, shaped like
# SMR/SHR data: heavy-tailed provider sizes, delayed entry, times at daily resolution stored as
# fractions of a year (start + k/365, so some equal times differ in the last bits), an offset, and
# non-integer case weights. Writes three CSV files to the scratch directory:
#   bench_a.csv: 200,000 rows, 3,000 providers, 6 covariates (seed 11)
#   bench_b.csv: 1,000,000 rows, 7,500 providers, 10 covariates (seed 23)
#   bench_pen.csv: 100,000 rows, 500 providers, 50 covariates (seed 7)
# Run from the repository root: Rscript dev/design/coxph-facts/06_benchmark_data.R <output file>
suppressMessages(library(data.table))
args <- commandArgs(trailingOnly = TRUE)
scratch <- Sys.getenv("COXPH_FACTS_SCRATCH")
if (!nzchar(scratch)) stop("Set COXPH_FACTS_SCRATCH (see README.md)")
make_data <- function(n, m, p, seed) {
  set.seed(seed)
  size <- rlnorm(m, 0, 1)
  prov <- sample.int(m, n, replace = TRUE, prob = size / sum(size))
  gamma <- rnorm(m, 0, 0.25)
  X <- matrix(rnorm(n * p), n, p)
  colnames(X) <- sprintf("x%02d", seq_len(p))
  beta <- rep(c(0.3, -0.2, 0.15, -0.1, 0.05), length.out = p)
  eta <- drop(X %*% beta) + gamma[prov]
  off <- log(runif(n, 0.5, 2))
  start <- round(runif(n, 0, 1) * 365) / 365
  t_ev <- rexp(n, rate = 0.4 * exp(eta + off))
  t_cen <- runif(n, 0.2, 3)
  stop <- start + pmax(round(pmin(t_ev, t_cen) * 365), 1) / 365
  event <- as.integer(t_ev <= t_cen)
  w <- runif(n, 0.5, 1.5)
  data.table(provider = prov, start = start, stop = stop, event = event, offset = off, weight = w, X)
}
cases <- list(list(file = "bench_a.csv", n = 200000L, m = 3000L, p = 6L, seed = 11L),
              list(file = "bench_b.csv", n = 1000000L, m = 7500L, p = 10L, seed = 23L),
              list(file = "bench_pen.csv", n = 100000L, m = 500L, p = 50L, seed = 7L))
lines <- character()
for (case in cases) {
  d <- make_data(case$n, case$m, case$p, case$seed)
  fwrite(d, file.path(scratch, case$file), showProgress = FALSE)
  lines <- c(lines, sprintf("%s: %d rows, %d providers with data, %d covariates, %d events, %d distinct stop times (seed %d)",
                            case$file, nrow(d), uniqueN(d$provider), case$p, sum(d$event), uniqueN(d$stop), case$seed))
}
writeLines(lines, args[1])
