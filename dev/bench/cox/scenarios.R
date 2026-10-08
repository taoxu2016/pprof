# Scenarios of the Cox benchmark baseline (CoxPH brief §3.7; COXPH_DESIGN §I).
#
# One factor at a time around a center of 100,000 rows, 1,000 providers, and 20 covariates, and the
# corner the brief requires (1,000,000 rows, 7,500 providers, 50 covariates): 8 scenarios instead of
# a 27-cell grid. Every scenario has delayed entry for about half the rows, times in whole days
# (daily ties), an offset on a 1/16 grid, case weights on a 1/2 grid, lognormal provider sizes, and
# provider effects. cox_bench_write() writes a scenario once to `dir`: each column as raw
# little-endian doubles (`<column>.f8`) and `columns.json`, which R and NumPy both read exactly.

cox_bench_scenarios <- function() {
  grid <- data.frame(
    id = c("center", "rows-1e4", "rows-1e6", "providers-100", "providers-7500", "covariates-5", "covariates-50",
           "corner"),
    n = c(1e5, 1e4, 1e6, 1e5, 1e5, 1e5, 1e5, 1e6),
    m = c(1000, 1000, 1000, 100, 7500, 1000, 1000, 7500),
    p = c(20, 20, 20, 20, 20, 5, 50, 50),
    seed = 101:108
  )
  grid$penalized <- grid$id == "covariates-50"
  grid
}

cox_bench_data <- function(n, m, p, seed) {
  set.seed(seed)  # a development script: package code never calls set.seed()
  size <- stats::rlnorm(m, 0, 1)
  provider <- sample.int(m, n, replace = TRUE, prob = size / sum(size)) - 1L
  gamma <- stats::rnorm(m, 0, 0.25)
  x <- matrix(round(stats::rnorm(n * p) * 64) / 64, n, p)
  beta <- rep(c(0.3, -0.2, 0.15, -0.1, 0.05), length.out = p) / sqrt(p / 5)
  offset <- round(stats::runif(n, -8, 8)) / 16
  weight <- sample(1:4, n, replace = TRUE) / 2
  eta <- drop(x %*% beta) + gamma[provider + 1L] + offset
  entry <- ifelse(stats::runif(n) < 0.5, floor(stats::runif(n, 0, 365)), 0)
  event_time <- ceiling(stats::rexp(n, rate = 0.002 * exp(eta)))
  censor_time <- ceiling(stats::runif(n, 30, 3 * 365))
  stop <- entry + pmax(pmin(event_time, censor_time), 1)
  event <- as.numeric(event_time <= censor_time)
  out <- data.frame(provider = provider, start = entry, stop = stop, event = event, weight = weight, offset = offset)
  colnames(x) <- sprintf("x%02d", seq_len(p))
  cbind(out, x)
}

cox_bench_write <- function(scenario, dir) {
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  if (file.exists(file.path(dir, "columns.json"))) return(invisible(dir))
  d <- cox_bench_data(scenario$n, scenario$m, scenario$p, scenario$seed)
  for (name in names(d)) {
    con <- file(file.path(dir, paste0(name, ".f8")), "wb")
    writeBin(as.double(d[[name]]), con, size = 8, endian = "little")
    close(con)
  }
  jsonlite::write_json(list(n = nrow(d), columns = names(d), covariates = grep("^x", names(d), value = TRUE)),
                       file.path(dir, "columns.json"), auto_unbox = TRUE)
  invisible(dir)
}

cox_bench_read <- function(dir) {
  spec <- jsonlite::read_json(file.path(dir, "columns.json"), simplifyVector = TRUE)
  columns <- lapply(spec$columns, function(name) {
    con <- file(file.path(dir, paste0(name, ".f8")), "rb")
    on.exit(close(con))
    readBin(con, "double", n = spec$n, size = 8, endian = "little")
  })
  names(columns) <- spec$columns
  d <- as.data.frame(columns)
  d$provider <- as.integer(d$provider)
  attr(d, "covariates") <- spec$covariates
  d
}
