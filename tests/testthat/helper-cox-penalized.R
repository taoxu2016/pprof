# Data for the tests of the elastic-net Cox model (CoxPH Phase C4): providers with delayed entry, tied
# integer times, five covariates on a 1/8 grid (x5 a 0/1 indicator), weights on a 1/2 grid (some 0),
# and an offset on a 1/4 grid. `counting = FALSE` gives right-censored data without entry times.
cox_penalized_data <- function(n = 300, seed = 41, counting = TRUE) {
  withr::with_seed(seed, {
    x <- matrix(round(stats::rnorm(n * 4) * 8) / 8, n, 4)
    x5 <- stats::rbinom(n, 1, 0.4)
    eta <- drop(x %*% c(0.6, -0.4, 0.2, 0)) + 0.3 * x5
    entry <- if (counting) ifelse(stats::runif(n) < 0.3, floor(stats::runif(n, 0, 4)), 0) else rep(0, n)
    time <- entry + pmax(1, ceiling(stats::rexp(n, 0.08 * exp(eta))))
    d <- data.frame(provider = sample(sprintf("p%d", 1:6), n, replace = TRUE), x1 = x[, 1], x2 = x[, 2], x3 = x[, 3],
                    x4 = x[, 4], x5 = x5, entry = entry, time = time, status = stats::rbinom(n, 1, 0.7),
                    w = sample(c(0, 0.5, 1, 2), n, replace = TRUE, prob = c(0.05, 0.3, 0.5, 0.15)),
                    o = round(stats::runif(n, -1, 1) * 4) / 4)
    if (!counting) d$entry <- NULL
    d
  })
}

# The formula of cox_penalized_data() with the covariates `terms`, entry times when the data have them,
# and the offset when `offset` is TRUE.
cox_penalized_formula <- function(d, terms = c("x1", "x2", "x3", "x4", "x5"), offset = TRUE) {
  lhs <- if ("entry" %in% names(d)) "Surv(entry, time, status)" else "Surv(time, status)"
  rhs <- paste(c(terms, if (offset) "offset(o)"), collapse = " + ")
  stats::as.formula(paste(lhs, "~", rhs), env = list2env(list(Surv = survival::Surv), parent = globalenv()))
}

# glmnet called directly on the rows of `d` with positive weight, sorted by provider as data_prepare()
# sorts them, with the provider codes as strata: the engine-identity reference of a path (DEC-043's
# pattern; COXPH_DESIGN §E.2). `keep` names the columns given to glmnet and `factors` their penalty
# factors, as the adapter passes them (rescaled over the kept columns).
cox_penalized_direct_glmnet <- function(d, terms, keep = terms, factors = rep(1, length(keep)), lambda, alpha = 1,
                                        ties = "breslow", standardize = TRUE, weights = TRUE, offset = TRUE,
                                        tol = 1e-12, max_iter = 1e5) {
  rows <- if (weights) d$w > 0 else rep(TRUE, nrow(d))
  d <- d[rows, , drop = FALSE]
  d <- d[order(match(d$provider, sort(unique(d$provider))), method = "radix"), , drop = FALSE]
  surv <- if ("entry" %in% names(d)) survival::Surv(d$entry, d$time, d$status) else survival::Surv(d$time, d$status)
  x <- as.matrix(d[, keep, drop = FALSE])
  if (ncol(x) == 1L) {
    x <- cbind(x, 0)
    factors <- c(factors, factors)
  }
  glmnet::glmnet(x, glmnet::stratifySurv(surv, as.integer(factor(d$provider))), family = "cox",
                 weights = if (weights) d$w, offset = if (offset) d$o, alpha = alpha, lambda = lambda,
                 penalty.factor = factors, standardize = standardize, cox.ties = ties,
                 control = list(thresh = tol, maxit = max_iter, fdev = 0, devmax = 1))
}
