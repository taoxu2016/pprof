# Calibrate the comparison rules of the pprofR fixtures (dev/logistic_brief.md §3.5; LOGISTIC_L1_PLAN
# §3.3; DEC-158).
#
# Usage, from the repository root:
#   Rscript dev/reference/pprofr/calibrate.R [report] [fixture dir]
# Defaults: validation/pprofr-calibration-report.md and validation/fixtures/pprofr.
#
# A value a matches its reference b when |a - b| <= atol + rtol * |b|, elementwise, with the tiers of
# tests/testthat/helper-tolerances.R (loaded by devtools::load_all()). For each case and kind of result,
# the report gives the ratio of the largest observed difference to the allowed one:
#   - pprofR's result against an independent reference: glm(), sandwich::vcovCL(), pprof's binary code
#     on the data expanded into trials, or a plain-R version of pprofR's definition evaluated at
#     pprofR's own estimates, which isolates the computation from the fit's convergence: at most 1;
#   - each negative control (one event moved between rows, one cluster split in two, the null shifted
#     by 1e-9) against pprofR's own result: at least 10, so that a defect of that size fails the tier.
# A kind that fails either bound is reported, not widened (the brief's §3.5); nothing here changes a
# tier. Rows marked "information" show a computation the comparisons will not use, such as pprof's
# root finder (D-85) or another algorithm for the exact test (DEC-150).

args <- commandArgs(trailingOnly = TRUE)
report_file <- if (length(args) >= 1) args[[1]] else file.path("validation", "pprofr-calibration-report.md")
fixture_dir <- if (length(args) >= 2) args[[2]] else file.path("validation", "fixtures", "pprofr")
suppressMessages(devtools::load_all(quiet = TRUE))
stopifnot(requireNamespace("sandwich", quietly = TRUE), requireNamespace("poibin", quietly = TRUE))
started <- proc.time()[["elapsed"]]
alternatives <- c("two.sided", "greater", "less")

# --- Fixtures and comparisons ---------------------------------------------------------------------

fixture <- function(id) readRDS(file.path(fixture_dir, paste0(id, ".rds")))
value <- function(fx, name) {
  r <- fx$records[[name]]
  if (is.null(r)) stop("No record ", name, " in ", fx$id, call. = FALSE)
  if (!is.null(r$error)) stop("Record ", name, " of ", fx$id, " is an error: ", r$error, call. = FALSE)
  r$value
}
tolerance <- function(tier) if (is.list(tier)) tier else pprof_tolerances[[tier]]
# DEC-050's tolerance for estimates against glm(): atol and rtol 1e-10.
glm_estimates <- list(atol = 1e-10, rtol = 1e-10)

# The largest ratio of |a - b| to atol + rtol |b|, elementwise. Named vectors are aligned by name, on
# the names they share; the ratio is Inf when they differ in length or in their non-finite elements.
tier_ratio <- function(a, b, tier) {
  tol <- tolerance(tier)
  if (!is.null(names(a)) && !is.null(names(b)) && is.null(dim(a)) && is.null(dim(b))) {
    common <- intersect(names(a), names(b))
    a <- a[common]
    b <- b[common]
  }
  a <- as.numeric(unlist(a))
  b <- as.numeric(unlist(b))
  if (length(a) != length(b)) return(Inf)
  fa <- is.finite(a)
  fb <- is.finite(b)
  if (!identical(fa, fb)) return(Inf)
  na <- a[!fa]
  nb <- b[!fb]
  if (!all((is.na(na) & is.na(nb)) | (!is.na(na) & !is.na(nb) & na == nb))) return(Inf)
  if (!any(fa)) return(0)
  max(abs(a[fa] - b[fa]) / (tol$atol + tol$rtol * abs(b[fa])))
}

store <- new.env()
store$rows <- list()
add <- function(case, kind, quantity, reference, tier, agreement, controls = numeric(), note = "") {
  tier_name <- if (is.list(tier)) "DEC-050" else tier
  weakest <- if (length(controls)) min(controls) else NA_real_
  ok <- agreement <= 1 && (is.na(weakest) || weakest >= 10)
  if (identical(note, "information")) ok <- NA
  weakest_name <- if (length(controls)) names(controls)[which.min(controls)] else ""
  controls_text <- if (length(controls)) {
    paste(sprintf("%s %s", names(controls), formatC(controls, format = "g", digits = 3)), collapse = "; ")
  } else {
    ""
  }
  store$rows[[length(store$rows) + 1L]] <- data.frame(case = case, kind = kind, quantity = quantity,
                                                      reference = reference, tier = tier_name, agreement = agreement,
                                                      control = weakest_name, weakest = weakest,
                                                      controls = controls_text, ok = ok, note = note,
                                                      stringsAsFactors = FALSE)
}
# A control's ratio only on the two-sided test; the one-sided ones share its draws or tails.
two_sided_only <- function(alternative, controls) if (alternative == "two.sided") controls else numeric()

# --- A fit's rows and estimates, in pprofR's order --------------------------------------------------

# The included rows of a prepared data set (pprofR's data_include, sorted by provider and, with clusters,
# by cluster label), with a fit's estimates. Cluster codes are (provider, label) pairs, numbered in order
# of first appearance (pprofR's cluster_codes()).
fit_view <- function(prep, fit) {
  ch <- prep$char_list
  d <- prep$data[prep$data$included == 1, , drop = FALSE]
  n <- if (!is.null(ch$N.char) && ch$N.char %in% names(d)) as.numeric(d[[ch$N.char]]) else rep(1, nrow(d))
  z <- as.matrix(d[, ch$Z.char, drop = FALSE])
  levels <- rownames(fit$df.prov)
  provider <- as.character(d[[ch$prov.char]])
  code <- match(provider, levels)
  beta <- stats::setNames(as.numeric(fit$beta), ch$Z.char)
  gamma <- stats::setNames(fit$df.prov$gamma_est, levels)
  cluster <- NULL
  if (!is.null(ch$PatientID.char)) {
    key <- paste(code, as.character(d[[ch$PatientID.char]]), sep = "\t")
    cluster <- match(key, unique(key))
  }
  eta <- if (!is.null(fit$linear_pred)) as.numeric(fit$linear_pred) else drop(z %*% beta)
  by_level <- factor(provider, levels = levels)
  list(y = as.numeric(d[[ch$Y.char]]), n = n, provider = provider, code = code, levels = levels, z = z, eta = eta,
       beta = beta, gamma = gamma, cluster = cluster,
       no_events = as.numeric(tapply(d$no.events, by_level, max)) == 1,
       all_events = as.numeric(tapply(d$all.events, by_level, max)) == 1)
}
by_provider <- function(x, v) stats::setNames(as.numeric(rowsum(x, v$code, reorder = TRUE)), v$levels)
fitted_p <- function(v, gamma = v$gamma) stats::plogis(gamma[v$code] + v$eta)
null_p <- function(v, gamma0) stats::plogis(gamma0 + v$eta)
# p(1 - p) without cancellation for p near 1.
p_q <- function(x) stats::plogis(x) * stats::plogis(-x)

# K-20 with the trials (design §A.3): p clamped to [1e-10, 1 - 1e-10], weights n p(1 - p), the block
# inverse. `clamp = FALSE, floor = 1e-20` gives pprofR's Wald routine (design §A.4).
k20 <- function(v, clamp = TRUE, floor = 0) {
  p <- fitted_p(v)
  if (clamp) p <- pmin(pmax(p, 1e-10), 1 - 1e-10)
  w <- v$n * p * (1 - p)
  if (floor > 0) w[w == 0] <- floor
  info_gamma <- by_provider(w, v)
  cross <- rowsum(w * v$z, v$code, reorder = TRUE)
  info_beta <- crossprod(v$z * sqrt(w))
  schur <- info_beta - crossprod(cross / sqrt(info_gamma))
  schur_inv <- solve(schur)
  ratio <- cross / info_gamma
  list(beta = schur_inv, gamma = stats::setNames(1 / info_gamma + rowSums((ratio %*% schur_inv) * ratio), v$levels))
}

# pprofR's z-test output (design §A.4): two-sided p = 2 min(upper, 1 - upper), one-sided the tail.
z_p <- function(z, alternative) {
  upper <- stats::pnorm(z, lower.tail = FALSE)
  switch(alternative, two.sided = 2 * pmin(upper, 1 - upper), greater = upper, less = stats::pnorm(z))
}

# The exact test's tail, statistic, and p-value of a provider over its individual trials.
exact_one <- function(o, pr, alternative) {
  if (alternative == "two.sided") {
    tail <- 1 - poibin::ppoibin(o, pr) + 0.5 * poibin::dpoibin(o, pr)
    return(c(tail, stats::qnorm(tail, lower.tail = FALSE), 2 * min(tail, 1 - tail)))
  }
  if (alternative == "greater") {
    tail <- 1 - poibin::ppoibin(o - 1, pr)
    return(c(tail, stats::qnorm(tail, lower.tail = FALSE), tail))
  }
  tail <- poibin::ppoibin(o, pr)
  c(tail, stats::qnorm(tail), tail)
}
exact_test <- function(v, gamma0, alternative) {
  p0 <- null_p(v, gamma0)
  out <- t(vapply(seq_along(v$levels), function(i) {
    r <- which(v$code == i)
    exact_one(sum(v$y[r]), rep(p0[r], v$n[r]), alternative)
  }, numeric(3)))
  dimnames(out) <- list(v$levels, c("tail", "stat", "p"))
  out
}

# The same tail by convolving the rows' binomial distributions (fact 03), for information (DEC-150).
convolution_tail <- function(v, gamma0) {
  p0 <- null_p(v, gamma0)
  vapply(seq_along(v$levels), function(i) {
    r <- which(v$code == i)
    density <- 1
    for (j in r) density <- stats::convolve(density, rev(stats::dbinom(0:v$n[j], v$n[j], p0[j])), type = "open")
    density <- pmax(density, 0)
    o <- sum(v$y[r])
    sum(density[seq_along(density) > o + 1]) + 0.5 * density[o + 1]
  }, numeric(1))
}

# The bootstrap's draws, replayed with the record's seed (design §A.4).
bootstrap_test <- function(v, gamma0, alternative, n, seed) {
  p0 <- null_p(v, gamma0)
  set.seed(seed)
  vapply(seq_along(v$levels), function(i) {
    r <- which(v$code == i)
    size <- if (all(v$n[r] == 1)) 1 else rep(v$n[r], times = n)
    sums <- colSums(matrix(stats::rbinom(length(r) * n, size = size, prob = rep(p0[r], times = n)), ncol = n))
    o <- sum(v$y[r])
    if (alternative == "greater") return(sum(sums >= o) / n)
    if (alternative == "less") return(sum(sums <= o) / n)
    tail <- (sum(sums > o) + 0.5 * sum(sums == o)) / n
    2 * min(tail, 1 - tail)
  }, numeric(1))
}

# Cluster sums (design §A.5): V_i = Σ_k (Σ_{j∈k} r_j)^2 and U_i = Σ_{j∈i} r_j.
cluster_meat <- function(v, r) {
  r_k <- as.numeric(rowsum(r, v$cluster, reorder = TRUE))
  provider_of_cluster <- v$code[!duplicated(v$cluster)][order(unique(v$cluster))]
  stats::setNames(as.numeric(rowsum(r_k^2, provider_of_cluster, reorder = TRUE)), v$levels)
}

# The stabilized meat (design §A.5): R̂ pooled over all clusters by row position, W_k = a_k' R̂ a_k.
stabilized_meat <- function(v, r, w) {
  e <- ifelse(w > 0, r / sqrt(w), 0)
  a <- sqrt(w)
  position <- stats::ave(seq_along(r), v$cluster, FUN = seq_along)
  n_clusters <- max(v$cluster)
  e_mat <- a_mat <- present <- matrix(0, n_clusters, max(position))
  e_mat[cbind(v$cluster, position)] <- e
  a_mat[cbind(v$cluster, position)] <- a
  present[cbind(v$cluster, position)] <- 1
  r_hat <- crossprod(e_mat) / crossprod(present)
  w_k <- rowSums((a_mat %*% r_hat) * a_mat)
  provider_of_cluster <- v$code[!duplicated(v$cluster)][order(unique(v$cluster))]
  stats::setNames(as.numeric(rowsum(w_k, provider_of_cluster, reorder = TRUE)), v$levels)
}
information <- function(v, p) {
  w <- v$n * p * (1 - p)
  w[w == 0] <- 1e-20
  by_provider(w, v)
}

# The measures of SR_output() (design §A.7), on the proportion scale.
measures <- function(v, gamma0, n_pop) {
  p0 <- null_p(v, gamma0)
  observed <- by_provider(v$y, v)
  expected <- by_provider(v$n * p0, v)
  direct <- vapply(v$gamma, function(g) sum(v$n * stats::plogis(g + v$eta)), numeric(1))
  numer_se <- vapply(v$gamma, function(g) sum(v$n * p_q(g + v$eta)), numeric(1))
  clip <- function(x) pmin(pmax(x, 0), 1)
  rate <- sum(v$y) / n_pop
  list(indirect_ratio = observed / expected, indirect_rate = clip(observed / expected * rate),
       expected = expected, variance = by_provider(v$n * p0 * (1 - p0), v),
       direct_ratio = direct / sum(v$y), direct_rate = clip(direct / sum(v$y) * rate), direct = direct,
       numer_se = numer_se)
}

# pprofR's exact and score limits (design §A.6), with its root finder or pprof's (K-90, D-85).
gamma_limits <- function(v, test, alpha = 0.05, finder = "pprofr") {
  q2 <- stats::qnorm(alpha / 2, lower.tail = FALSE)
  root_pprofr <- function(f, a, b) {
    width <- b - a
    for (k in 0:5) {
      fa <- f(a)
      fb <- f(b)
      if (is.finite(fa) && is.finite(fb) && sign(fa) != sign(fb)) {
        return(stats::uniroot(f, c(a, b), tol = 1e-8)$root)
      }
      a <- a - width
      b <- b + width
    }
    NA_real_
  }
  root_pprof <- function(f, a, b) stats::uniroot(f, c(a, b))$root
  out <- t(vapply(seq_along(v$levels), function(i) {
    r <- which(v$code == i)
    zb <- v$eta[r]
    nt <- v$n[r]
    o <- sum(v$y[r])
    g <- v$gamma[[i]]
    if (test == "exact") {
      trials <- function(effect) rep(stats::plogis(effect + zb), nt)
      upper_fun <- function(effect) {
        p <- trials(effect)
        poibin::ppoibin(o - 1, p) + 0.5 * poibin::dpoibin(o, p) - alpha / 2
      }
      lower_fun <- function(effect) {
        p <- trials(effect)
        1 - poibin::ppoibin(o, p) + 0.5 * poibin::dpoibin(o, p) - alpha / 2
      }
    } else {
      z_of <- function(effect) {
        p <- stats::plogis(effect + zb)
        (o - sum(nt * p)) / sqrt(sum(nt * p * (1 - p)))
      }
      upper_fun <- function(effect) z_of(effect) + q2
      lower_fun <- function(effect) z_of(effect) - q2
    }
    if (v$no_events[i] || v$all_events[i]) return(c(NA_real_, NA_real_))
    span <- 10 + max(abs(zb))
    if (finder == "pprofr") return(c(root_pprofr(lower_fun, g - span, g), root_pprofr(upper_fun, g, g + span)))
    # K-90's brackets: gamma ± [5k, 5(k + 1)], k = 0, 1, 2.
    bracket <- function(f, sign) {
      for (k in 0:2) {
        ends <- sort(g + sign * c(5 * k, 5 * (k + 1)))
        if (f(ends[1]) * f(ends[2]) < 0) return(root_pprof(f, ends[1], ends[2]))
      }
      sign * Inf
    }
    c(bracket(lower_fun, -1), bracket(upper_fun, 1))
  }, numeric(2)))
  dimnames(out) <- list(v$levels, c("lower", "upper"))
  out
}

# The data expanded into trials: each row into n rows of which the first y have the event.
expand_trials <- function(v) {
  row <- rep(seq_along(v$y), v$n)
  within <- sequence(v$n)
  data.frame(y = as.integer(within <= v$y[row]), provider = v$provider[row], v$z[row, , drop = FALSE],
             stringsAsFactors = FALSE)
}

glm_tight <- function(v) {
  dat <- data.frame(y = v$y, n = v$n, provider = factor(v$provider, levels = v$levels), v$z)
  formula <- stats::as.formula(paste("cbind(y, n - y) ~ 0 + provider +", paste(colnames(v$z), collapse = " + ")))
  fit <- suppressWarnings(stats::glm(formula, family = stats::binomial(), data = dat,
                                     control = stats::glm.control(epsilon = 1e-14, maxit = 100)))
  # DEC-050: the covariance of glm() restarted at its estimates.
  again <- suppressWarnings(stats::glm(formula, family = stats::binomial(), data = dat, start = stats::coef(fit),
                                       control = stats::glm.control(epsilon = 1e-14, maxit = 1)))
  list(fit = fit, data = dat, gamma = stats::setNames(stats::coef(fit)[paste0("provider", v$levels)], v$levels),
       beta = stats::coef(fit)[colnames(v$z)], vcov = stats::vcov(again))
}

# --- The moderate cases and the many-trials case -----------------------------------------------------

calibrate_fits <- function(id, fx, fit, v) {
  # pprofR's tight fit against glm() and against pprof's binary code on the expanded data.
  tight <- value(fx, "unclustered/tight/fit")
  vt <- fit_view(value(fx, "prep"), tight)
  g <- glm_tight(vt)
  moved <- value(fx, "control/event-moved/unclustered/fit/default")
  controls <- c(`event moved` = tier_ratio(c(moved$df.prov$gamma_est, as.numeric(moved$beta)),
                                           c(fit$df.prov$gamma_est, as.numeric(fit$beta)), "iterative"))
  estimates <- c(vt$gamma, vt$beta)
  add(id, "estimates", "γ, β (tight fit)", "glm()", glm_estimates,
      tier_ratio(estimates, c(g$gamma, g$beta), glm_estimates), controls)
  add(id, "estimates", "γ, β (tight fit)", "glm()", "iterative", tier_ratio(estimates, c(g$gamma, g$beta), "iterative"),
      controls)
  # Newton's full steps, as the tight fits (cases.R, pprofr_tight()): the line search can stop short of the maximum.
  binary <- fit_logistic_fe(stats::as.formula(paste("y ~", paste(colnames(vt$z), collapse = " + "))),
                            expand_trials(vt), "provider", tol = 1e-12, stop_rule = "all", backtrack = FALSE,
                            min_provider_size = 1, threads = 1)
  expanded <- c(provider_estimates(binary)[vt$levels], stats::coef(binary)[colnames(vt$z)])
  add(id, "estimates", "γ, β (tight fit)", "pprof's binary fit of the trials", "iterative",
      tier_ratio(estimates, expanded, "iterative"), controls)
  # Variances given the estimates.
  add(id, "variances", "Var(β) (tight fit)", "glm() at its estimates (DEC-050)", "closed_form",
      tier_ratio(value(fx, "unclustered/tight/vcov"), g$vcov[colnames(vt$z), colnames(vt$z)], "closed_form"))
  add(id, "standard errors", "Wald se(β) (tight fit)", "glm() at its estimates (DEC-050)", "closed_form",
      tier_ratio(value(fx, "unclustered/tight/covar/wald")$se.beta, sqrt(diag(g$vcov))[colnames(vt$z)],
                 "closed_form"))
  vc <- value(fx, "unclustered/vcov")
  reference <- k20(v)
  moved_vcov <- value(fx, "control/event-moved/unclustered/vcov")
  pprofr_variances <- c(as.numeric(vc), attr(vc, "var.gamma"))
  add(id, "variances", "Var(β), Var(γ)", "K-20 in plain R at pprofR's estimates", "closed_form",
      tier_ratio(pprofr_variances, c(as.numeric(reference$beta), reference$gamma), "closed_form"),
      c(`event moved` = tier_ratio(c(as.numeric(moved_vcov), attr(moved_vcov, "var.gamma")), pprofr_variances,
                                   "closed_form")))
  reference
}

calibrate_tests <- function(id, fx, v) {
  gamma0 <- stats::median(v$gamma)
  shifted <- function(test) value(fx, sprintf("control/null-shifted/unclustered/test/%s/shifted/two.sided", test))
  for (alternative in alternatives) {
    t <- value(fx, sprintf("unclustered/test/exact.poisbinom/median/%s", alternative))
    ref <- exact_test(v, gamma0, alternative)
    add(id, "p-values", sprintf("exact, %s", alternative), "poibin over the trials, at pprofR's estimates",
        "probability", tier_ratio(t$p, ref[, "p"], "probability"),
        two_sided_only(alternative, c(`null shifted` = tier_ratio(shifted("exact.poisbinom")$p, t$p, "probability"))))
    add(id, "exact statistic (DEC-083)", sprintf("exact, %s", alternative), "the same, on the tail probability",
        "probability", tier_ratio(stats::pnorm(-abs(t$stat)), stats::pnorm(-abs(ref[, "stat"])), "probability"))
  }
  add(id, "p-values", "exact two-sided tail", "convolution of the rows' binomials (DEC-150)", "probability",
      tier_ratio(exact_test(v, gamma0, "two.sided")[, "tail"], convolution_tail(v, gamma0), "probability"),
      note = "information")
  n_resamples <- if (id == "binomial-many-trials") 2000 else 10000
  for (alternative in alternatives) {
    record <- fx$records[[sprintf("unclustered/test/exact.bootstrap/median/%s", alternative)]]
    add(id, "p-values", sprintf("bootstrap, %s", alternative), "the draws replayed with the record's seed",
        "probability", tier_ratio(record$value$p, bootstrap_test(v, gamma0, alternative, n_resamples, record$seed),
                                  "probability"))
  }
  p0 <- null_p(v, gamma0)
  z_score <- by_provider(v$y - v$n * p0, v) / sqrt(by_provider(v$n * p0 * (1 - p0), v))
  for (alternative in alternatives) {
    t <- value(fx, sprintf("unclustered/test/score/median/%s", alternative))
    add(id, "p-values", sprintf("score, %s", alternative), "the score statistic in plain R", "probability",
        tier_ratio(t$p, z_p(z_score, alternative), "probability"),
        two_sided_only(alternative, c(`null shifted` = tier_ratio(shifted("score")$p, t$p, "probability"))))
  }
  se_wald <- sqrt(k20(v, clamp = FALSE, floor = 1e-20)$gamma)
  t <- value(fx, "unclustered/test/wald/median/two.sided")
  moved <- value(fx, "control/event-moved/unclustered/test/wald/median/two.sided")
  add(id, "standard errors", "Wald se(γ)", "the block inverse in plain R, unclamped (design §A.4)", "closed_form",
      tier_ratio(t$se.gamma, se_wald, "closed_form"),
      c(`event moved` = tier_ratio(moved$se.gamma, t$se.gamma, "closed_form")))
  for (alternative in alternatives) {
    t <- value(fx, sprintf("unclustered/test/wald/median/%s", alternative))
    add(id, "p-values", sprintf("Wald, %s", alternative), "z = (γ - γ0) / se in plain R", "probability",
        tier_ratio(t$p, z_p((v$gamma - gamma0) / se_wald, alternative), "probability"),
        two_sided_only(alternative, c(`null shifted` = tier_ratio(shifted("wald")$p, t$p, "probability"))))
  }
}

calibrate_measures <- function(id, fx, v) {
  sr <- value(fx, "unclustered/sr/median")
  m <- measures(v, stats::median(v$gamma), sr$N_pop)
  shifted <- value(fx, "control/null-shifted/unclustered/sr/shifted")
  moved <- value(fx, "control/event-moved/unclustered/sr/median")
  indirect <- sr$OE$OE_indirect
  add(id, "measures", "indirect expected, variance, ratio, rate", "sums in plain R", "closed_form",
      tier_ratio(c(indirect$Exp.indirect_provider, indirect$Var.indirect_provider, sr$indirect.ratio, sr$indirect.rate),
                 c(m$expected, m$variance, m$indirect_ratio, m$indirect_rate), "closed_form"),
      c(`null shifted` = tier_ratio(shifted$OE$OE_indirect$Exp.indirect_provider, indirect$Exp.indirect_provider,
                                    "closed_form"),
        `event moved` = tier_ratio(moved$OE$OE_indirect$Exp.indirect_provider, indirect$Exp.indirect_provider,
                                   "closed_form")))
  add(id, "measures", "direct expected, ratio, rate, numer_se", "sums in plain R (long double)", "closed_form",
      tier_ratio(c(sr$OE$OE_direct$Exp.direct_all, sr$direct.ratio, sr$direct.rate, sr$numer_se),
                 c(m$direct, m$direct_ratio, m$direct_rate, m$numer_se), "closed_form"),
      c(`event moved` = tier_ratio(moved$OE$OE_direct$Exp.direct_all, sr$OE$OE_direct$Exp.direct_all,
                                   "closed_form")))
}

calibrate_limits <- function(id, fx, v, reference) {
  regular <- !(v$no_events | v$all_events)
  for (test in c("exact", "score")) {
    ci <- value(fx, sprintf("unclustered/confint/gamma/%s", test))
    limits <- c(ci$gamma.lower[regular], ci$gamma.upper[regular])
    moved <- value(fx, sprintf("control/event-moved/unclustered/confint/gamma/%s", test))
    controls <- c(`event moved` = tier_ratio(c(moved$gamma.lower, moved$gamma.upper),
                                             c(ci$gamma.lower, ci$gamma.upper), "root"))
    ref <- gamma_limits(v, test)
    add(id, "limits", sprintf("%s limits of γ", test), "pprofR's equations and root finder in plain R", "root",
        tier_ratio(limits, c(ref[regular, "lower"], ref[regular, "upper"]), "root"), controls)
    ref <- gamma_limits(v, test, finder = "pprof")
    add(id, "limits", sprintf("%s limits of γ", test), "pprof's root finder (K-90; D-85)", "root",
        tier_ratio(limits, c(ref[regular, "lower"], ref[regular, "upper"]), "root"), note = "information")
  }
  ci <- value(fx, "unclustered/confint/gamma/wald")
  half <- stats::qnorm(0.975) * sqrt(reference$gamma)
  add(id, "limits", "Wald limits of γ", "γ ∓ z se, se from K-20 (clamped)", "closed_form",
      tier_ratio(c(ci$gamma.lower, ci$gamma.upper), c(v$gamma - half, v$gamma + half), "closed_form"))
}

calibrate_clusters <- function(id, fx) {
  cprep <- value(fx, "clustered/prep")
  cv <- fit_view(cprep, value(fx, "clustered/fit/default"))
  gamma0 <- stats::median(cv$gamma)
  p <- fitted_p(cv)
  r <- cv$y - cv$n * p
  info <- information(cv, p)
  wald_se <- list(robust_wald = sqrt(cluster_meat(cv, r)) / info,
                  stabilized_wald = sqrt(stabilized_meat(cv, r, cv$n * p * (1 - p))) / info)
  p_null <- null_p(cv, gamma0)
  r0 <- cv$y - cv$n * p_null
  u0 <- by_provider(r0, cv)
  score_z <- list(robust_score = u0 / sqrt(cluster_meat(cv, r0)),
                  stabilized_score = u0 / sqrt(stabilized_meat(cv, r0, cv$n * p_null * (1 - p_null))))
  split <- function(test) value(fx, sprintf("control/cluster-split/clustered/test/%s/median/two.sided", test))
  shifted <- function(test) value(fx, sprintf("control/null-shifted/clustered/test/%s/shifted/two.sided", test))
  for (test in names(wald_se)) {
    t <- value(fx, sprintf("clustered/test/%s/median/two.sided", test))
    add(id, "standard errors", sprintf("%s se(γ)", test), "the cluster sums in plain R", "closed_form",
        tier_ratio(t$se.gamma, wald_se[[test]], "closed_form"),
        c(`cluster split` = tier_ratio(split(test)$se.gamma, t$se.gamma, "closed_form")))
  }
  for (test in c(names(wald_se), names(score_z))) {
    z <- if (test %in% names(wald_se)) (cv$gamma - gamma0) / wald_se[[test]] else score_z[[test]]
    for (alternative in alternatives) {
      t <- value(fx, sprintf("clustered/test/%s/median/%s", test, alternative))
      controls <- c(`cluster split` = tier_ratio(split(test)$p, t$p, "probability"),
                    `null shifted` = tier_ratio(shifted(test)$p, t$p, "probability"))
      add(id, "p-values", sprintf("%s, %s", test, alternative), "the statistic in plain R", "probability",
          tier_ratio(t$p, z_p(z, alternative), "probability"), two_sided_only(alternative, controls))
    }
  }
  # The robust covariance of the coefficients against sandwich::vcovCL(), both at tight fits.
  cvt <- fit_view(cprep, value(fx, "clustered/tight/fit"))
  robust <- sandwich::vcovCL(glm_tight(cvt)$fit, cluster = cvt$cluster, type = "HC0", cadjust = FALSE)
  split_covar <- value(fx, "control/cluster-split/clustered/covar/robust_wald")
  default_covar <- value(fx, "clustered/covar/robust_wald")
  add(id, "standard errors", "robust se(β) (tight fit)", "sandwich::vcovCL(type = \"HC0\", cadjust = FALSE)",
      "closed_form",
      tier_ratio(value(fx, "clustered/tight/covar/robust_wald")$se.beta, sqrt(diag(robust))[colnames(cvt$z)],
                 "closed_form"),
      c(`cluster split` = tier_ratio(split_covar$se.beta, default_covar$se.beta, "closed_form")))
}

calibrate_case <- function(id, clustered = TRUE) {
  fx <- fixture(id)
  fit <- value(fx, "unclustered/fit/default")
  v <- fit_view(value(fx, "prep"), fit)
  reference <- calibrate_fits(id, fx, fit, v)
  calibrate_tests(id, fx, v)
  calibrate_measures(id, fx, v)
  calibrate_limits(id, fx, v, reference)
  if (clustered) calibrate_clusters(id, fx)
}

# --- The other cases ------------------------------------------------------------------------------------

calibrate_few_clusters <- function() {
  fx <- fixture("few-clusters")
  note <- c(clustered = "",
            `one-cluster` = "one cluster each: robust variances of rounding size (D-94), stabilized negative (D-95)")
  for (part in names(note)) {
    v <- fit_view(value(fx, paste0(part, "/prep")), value(fx, paste0(part, "/fit/default")))
    p <- fitted_p(v)
    r <- v$y - v$n * p
    info <- information(v, p)
    meats <- list(robust_wald = cluster_meat(v, r), stabilized_wald = stabilized_meat(v, r, v$n * p * (1 - p)))
    for (test in names(meats)) {
      t <- value(fx, sprintf("%s/test/%s/median/two.sided", part, test))
      ref <- suppressWarnings(sqrt(meats[[test]]) / info)
      add("few-clusters", "standard errors", sprintf("%s se(γ) (%s)", test, part), "the cluster sums in plain R",
          "closed_form", tier_ratio(t$se.gamma, ref, "closed_form"), note = note[[part]])
    }
  }
}

calibrate_extreme <- function() {
  fx <- fixture("extreme-probabilities")
  for (part in c("binary", "binomial")) {
    v <- fit_view(value(fx, paste0(part, "/prep")), value(fx, paste0(part, "/fit/default")))
    gamma0 <- stats::median(v$gamma)
    t <- value(fx, sprintf("%s/test/exact.poisbinom/median/two.sided", part))
    add("extreme-probabilities", "p-values", sprintf("exact, two-sided (%s)", part),
        "poibin over the trials, unclamped", "probability",
        tier_ratio(t$p, exact_test(v, gamma0, "two.sided")[, "p"], "probability"))
    t <- value(fx, sprintf("%s/test/score/median/two.sided", part))
    score <- function(p0) by_provider(v$y - v$n * p0, v) / sqrt(by_provider(v$n * p0 * (1 - p0), v))
    p0 <- null_p(v, gamma0)
    add("extreme-probabilities", "p-values", sprintf("score, two-sided (%s)", part), "the score statistic, unclamped",
        "probability", tier_ratio(t$p, z_p(score(p0), "two.sided"), "probability"))
    add("extreme-probabilities", "p-values", sprintf("score, two-sided (%s)", part),
        "the score statistic, clamped (K-65; D-82)", "probability",
        tier_ratio(t$p, z_p(score(pmin(pmax(p0, 1e-10), 1 - 1e-10)), "two.sided"), "probability"),
        note = "information")
  }
}

calibrate_standard_population <- function() {
  fx <- fixture("standard-population")
  p <- fx$data$populations
  cases <- list(continuous = list(p$continuous, 1), repeated = list(p$repeated, 1),
                `repeated/weights` = list(p$repeated, p$weights), single = list(0.25, 7))
  for (name in names(cases)) {
    eta <- cases[[name]][[1]]
    w <- rep_len(cases[[name]][[2]], length(eta))
    d <- value(fx, paste0("direct_exp/", name))
    expected <- vapply(p$effects, function(g) sum(w * stats::plogis(g + eta)), numeric(1))
    variance <- vapply(p$effects, function(g) sum(w * p_q(g + eta)), numeric(1))
    add("standard-population", "direct standardization", sprintf("direct_exp(), %s", name),
        "sums over the rows in plain R (long double)", "closed_form",
        tier_ratio(c(d$Exp, d$Var), c(expected, variance), "closed_form"))
  }
}

# The test of a measure (design §A.9): its statistic, p-value, and interval by the formulas.
calibrate_measure_tests <- function() {
  fx <- fixture("measure-tests")
  inputs <- value(fx, "inputs")
  m <- inputs$rate
  for (se_type in names(inputs$se)) {
    se <- inputs$se[[se_type]]
    for (transform in c("identity", "logit")) {
      logit <- transform == "logit"
      g <- if (logit) stats::qlogis else identity
      dg <- if (logit) function(x) 1 / (x * (1 - x)) else function(x) rep(1, length(x))
      g_inverse <- if (logit) stats::plogis else identity
      for (null in list(c(0, 1), c(0.5, 1.5))) {
        for (alternative in alternatives) {
          name <- sprintf("test_SM/%s/%s/%g-%g/%s", se_type, transform, null[1], null[2], alternative)
          t <- value(fx, name)
          z <- (g(m) - g(inputs$reference)) / (dg(m) * se)
          f <- stats::pnorm((z - null[1]) / null[2])
          p <- switch(alternative, two.sided = 2 * pmin(f, 1 - f), greater = 1 - f, less = f)
          crit <- if (alternative == "two.sided") stats::qnorm(0.975) else stats::qnorm(0.95)
          lower <- g_inverse(g(m) - (null[1] + crit * null[2]) * dg(m) * se)
          upper <- g_inverse(g(m) - (null[1] - crit * null[2]) * dg(m) * se)
          if (alternative == "greater") upper <- rep(g_inverse(Inf), length(upper))
          if (alternative == "less") lower <- rep(g_inverse(-Inf), length(lower))
          label <- sub("^test_SM/", "", name)
          add("measure-tests", "measure test", sprintf("z, limits (%s)", label), "the formulas in plain R (§A.9)",
              "closed_form", tier_ratio(c(t$z, t$lower, t$upper), c(z, lower, upper), "closed_form"))
          add("measure-tests", "measure test", sprintf("p (%s)", label), "the formulas in plain R", "probability",
              tier_ratio(t$p, p, "probability"))
        }
      }
    }
  }
}

# The delta-method standard error of the direct rates (fact 07): numer_se / N_pop against the
# derivative of the rate in γ, by central differences with Richardson's extrapolation of two steps.
calibrate_delta <- function() {
  fx <- fixture("binomial-moderate")
  v <- fit_view(value(fx, "prep"), value(fx, "unclustered/fit/default"))
  sr <- value(fx, "unclustered/sr/median")
  rate_at <- function(g) vapply(g, function(x) sum(v$n * stats::plogis(x + v$eta)), numeric(1)) / sr$N_pop
  derivative <- function(h) (rate_at(v$gamma + h) - rate_at(v$gamma - h)) / (2 * h)
  richardson <- (4 * derivative(5e-4) - derivative(1e-3)) / 3
  add("binomial-moderate", "standard errors", "d rate / dγ (numer_se / N_pop)", "central differences, extrapolated",
      "closed_form", tier_ratio(as.numeric(sr$numer_se) / sr$N_pop, richardson, "closed_form"))
}

# --- Run and report ------------------------------------------------------------------------------------

calibrate_case("binary-moderate")
calibrate_case("binomial-moderate")
calibrate_case("binomial-many-trials", clustered = FALSE)
calibrate_few_clusters()
calibrate_extreme()
calibrate_standard_population()
calibrate_measure_tests()
calibrate_delta()

table <- do.call(rbind, store$rows)
manifest <- jsonlite::read_json(file.path(fixture_dir, "manifest.json"))
format_ratio <- function(x) ifelse(is.na(x), "", ifelse(is.infinite(x), "Inf", formatC(x, format = "g", digits = 3)))
verdict <- ifelse(is.na(table$ok), "information", ifelse(table$ok, "yes", "**no**"))
failing <- table[!is.na(table$ok) & !table$ok, ]
header <- sprintf(paste("Generated by `dev/reference/pprofr/calibrate.R` from the fixtures in `%s` (pprofR %s,",
                        "commit %s; generated at %s), with pprof %s from the working tree at commit %s, %s, %s;",
                        "%.0f s."),
                  fixture_dir, manifest$reference$version, substr(manifest$reference$git_commit, 1, 7),
                  substr(manifest$generator$git_commit, 1, 7), as.character(utils::packageVersion("pprof")),
                  system2("git", c("rev-parse", "--short", "HEAD"), stdout = TRUE), R.version.string,
                  utils::sessionInfo()$running, proc.time()[["elapsed"]] - started)
rule <- paste("A value a matches its reference b when |a - b| <= atol + rtol |b|, elementwise, with the tiers of",
              "`tests/testthat/helper-tolerances.R` (and DEC-050's for estimates against `glm()`). *Agreement* is the",
              "largest ratio of the difference between pprofR's result and the independent reference to the allowed",
              "one: at most 1. *Weakest control* is the smallest, over the negative controls, of the largest such",
              "ratio between a control's result and pprofR's own: at least 10, so that a change of that size fails",
              "the tier (the brief's §3.5); the column *Controls* gives each. Rows marked *information* show",
              "computations the comparisons will not use. Nothing here changes a tier.")
lines <- c("# pprofR tolerance calibration", "", header, "", rule, "",
           sprintf("Result: %d of %d calibrated rows pass; %d rows of information.", sum(table$ok, na.rm = TRUE),
                   sum(!is.na(table$ok)), sum(is.na(table$ok))), "",
           paste("| Case | Kind | Quantity | Reference | Tier | Agreement (≤ 1) | Weakest control (≥ 10) | Controls |",
                 "OK | Note |"),
           "|---|---|---|---|---|---|---|---|---|---|",
           sprintf("| %s | %s | %s | %s | `%s` | %s | %s | %s | %s | %s |", table$case, table$kind, table$quantity,
                   table$reference, table$tier, format_ratio(table$agreement), format_ratio(table$weakest),
                   table$controls, verdict, table$note))
if (nrow(failing)) {
  lines <- c(lines, "", "## Rows that fail a bound", "",
             sprintf("- %s, %s, %s against %s: agreement %s, weakest control %s (%s).", failing$case, failing$kind,
                     failing$quantity, failing$reference, format_ratio(failing$agreement),
                     format_ratio(failing$weakest), failing$control))
}
writeLines(lines, report_file)
cat(sprintf("Wrote %s: %d of %d calibrated rows pass; %d of information\n", report_file, sum(table$ok, na.rm = TRUE),
            sum(!is.na(table$ok)), sum(is.na(table$ok))))
