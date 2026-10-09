# Data for the tests of Cox models' profiling (CoxPH Phase C3): providers with delayed entry, tied
# integer times, weights (some 0), and an offset, with three special providers: p09 has no events,
# p10's rows all leave before the first event time (no expected events, K-147), and p11 has one row,
# an event.
cox_profile_data <- function(n = 400, seed = 31) {
  d <- withr::with_seed(seed, {
    provider <- sample(sprintf("p%02d", 1:10), n, replace = TRUE)
    x <- round(stats::rnorm(n) * 8) / 8
    z <- stats::rbinom(n, 1, 0.5)
    entry <- ifelse(stats::runif(n) < 0.3, floor(stats::runif(n, 0, 4)), 0)
    time <- entry + pmax(1, ceiling(stats::rexp(n, 0.08 * exp(0.5 * x - 0.4 * z))))
    data.frame(provider = provider, x = x, z = z, entry = entry, time = time, status = stats::rbinom(n, 1, 0.7),
               w = sample(c(0, 0.5, 1, 2), n, replace = TRUE, prob = c(0.05, 0.3, 0.5, 0.15)),
               o = round(stats::runif(n, -1, 1) * 4) / 4)
  })
  d$status[d$provider == "p09"] <- 0
  ten <- d$provider == "p10"
  d$entry[ten] <- 0
  d$time[ten] <- 0.5
  d$status[ten] <- 0
  rbind(d, data.frame(provider = "p11", x = 0.25, z = 1, entry = 0, time = 6, status = 1, w = 1, o = 0))
}

# The national Breslow expected events of each row, by survival: predict(type = "expected") of the
# Cox model with the linear predictor as its only term, an offset, and Breslow ties (as the Cox
# fixtures' R side computes them, dev/reference/cox/survival.R).
cox_survival_expected <- function(eta, start, stop, event) {
  f <- stats::as.formula("survival::Surv(start, stop, event) ~ offset(eta)")
  fit <- survival::coxph(f, data = data.frame(start = start, stop = stop, event = event, eta = eta - max(eta)),
                         ties = "breslow", control = survival::coxph.control(timefix = FALSE))
  unname(stats::predict(fit, type = "expected"))
}
