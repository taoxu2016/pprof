# Competing-risk data and direct survival calls for the Fine-Gray tests (the CoxPH C5 plan, §4.3 and §4.4;
# test-model-survival.R and test-model-fine-gray.R).

# Subjects in providers, in integer times with ties: about a quarter entering late, about a third (with
# `split`) with two or three contiguous (start, stop] rows between which x2 changes, causes 1 and 2 on a
# subject's last row, case weights on a 1/2 grid, 0 for the subjects whose id is 3 modulo 17, and a
# factor status `cause` whose first level is censoring.
fine_gray_data <- function(subjects = 240, providers = 6, seed = 23, split = TRUE, late = 0.25) {
  withr::with_seed(seed, {
    rows <- vector("list", subjects)
    for (s in seq_len(subjects)) {
      x1 <- round(stats::rnorm(1) * 8) / 8
      entry <- if (stats::runif(1) < late) sample(5L, 1L) else 0L
      rate1 <- 0.06 * exp(0.5 * x1)
      rate2 <- 0.03 * exp(-0.25 * x1)
      t_event <- ceiling(stats::rexp(1, rate1 + rate2))
      cause <- if (stats::runif(1) < rate1 / (rate1 + rate2)) 1L else 2L
      duration <- max(min(t_event, sample(4:40, 1L)), 1)
      status <- if (t_event <= duration) cause else 0L
      end <- entry + duration
      cuts <- if (split && duration >= 3 && stats::runif(1) < 1 / 3) {
        sort(sample(seq(entry + 1, end - 1), min(sample(2L, 1L), duration - 1)))
      } else {
        numeric()
      }
      bounds <- c(entry, cuts, end)
      k <- length(bounds) - 1L
      rows[[s]] <- data.frame(id = s, provider = sprintf("p%02d", (s - 1L) %% providers + 1L),
                              start = bounds[-length(bounds)], stop = bounds[-1L],
                              status = c(rep(0L, k - 1L), status), w = sample(c(0.5, 1, 1.5, 2), 1L), x1 = x1,
                              x2 = round(stats::rnorm(k) * 8) / 8)
    }
    d <- do.call(rbind, rows)
    d$w[d$id %% 17L == 3L] <- 0
    d$cause <- factor(d$status, levels = 0:2)
    d
  })
}

# data_prepare() of competing-risk data, as fit_fine_gray() calls it.
fine_gray_prepare <- function(formula, data = fine_gray_data(), ...) {
  data_prepare(formula, data, "provider", response_type = "competing_risks", ...)
}

# survival's finegray() called once on the prepared observations, stratified by provider, with the subjects
# as `id` for (start, stop] data and timefix = FALSE: the stratified call of COXPH_DESIGN §E.3, which the
# adapter's chunks must reproduce (DEC-122), with the case weights multiplied after the call (DEC-123).
fine_gray_direct_expansion <- function(prepared, cause) {
  counting <- identical(prepared$settings$survival_type, "counting")
  levels <- 0:max(length(prepared$settings$states), 2L)
  rows <- seq_along(prepared$response)
  frame <- data.frame(.start = prepared$start, .stop = prepared$stop,
                      .status = factor(prepared$response, levels = levels), .row = rows,
                      .provider = prepared$provider_index,
                      .id = if (is.null(prepared$cluster)) rows else as.integer(prepared$cluster))
  env <- list2env(list(Surv = survival::Surv, strata = survival::strata), parent = globalenv())
  if (counting) {
    f <- stats::as.formula("Surv(.start, .stop, .status) ~ .row + strata(.provider)", env = env)
    fg <- survival::finegray(f, data = frame, etype = as.character(cause), id = .id, timefix = FALSE)
  } else {
    f <- stats::as.formula("Surv(.stop, .status) ~ .row + strata(.provider)", env = env)
    fg <- survival::finegray(f, data = frame, etype = as.character(cause), timefix = FALSE)
  }
  weight <- if (is.null(prepared$weights)) fg$fgwt else fg$fgwt * prepared$weights[fg$.row]
  list(row = fg$.row, start = fg$fgstart, stop = fg$fgstop, status = fg$fgstatus, weight = weight)
}

# coxph() of the Fine-Gray model on an expansion's rows with positive weight, clustered by subject, as
# COXPH_DESIGN §E.3 wrote it: the engine-identity reference of the fit (DEC-121).
fine_gray_direct_coxph <- function(prepared, expansion, ties, tol = 1e-9, max_iter = 20) {
  keep <- expansion$weight > 0
  rows <- expansion$row[keep]
  d <- data.frame(fgstart = expansion$start[keep], fgstop = expansion$stop[keep], fgstatus = expansion$status[keep],
                  fgwt = expansion$weight[keep], provider = prepared$provider_index[rows],
                  id = if (is.null(prepared$cluster)) rows else prepared$cluster[rows])
  covariates <- colnames(prepared$design)
  for (name in covariates) d[[name]] <- unname(prepared$design[rows, name])
  right_side <- paste(c(covariates, "strata(provider)"), collapse = " + ")
  # survfit() of the fit evaluates its data again in the formula's environment, which therefore holds them.
  f <- stats::as.formula(paste("Surv(fgstart, fgstop, fgstatus) ~", right_side),
                         env = list2env(list(Surv = survival::Surv, strata = survival::strata, d = d),
                                        parent = globalenv()))
  survival::coxph(f, data = d, weights = fgwt, cluster = id, ties = ties,
                  control = survival::coxph.control(eps = tol, iter.max = max_iter, timefix = FALSE))
}
