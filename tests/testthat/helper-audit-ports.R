# The Phase 0 audit's R ports of the reference engines, copied verbatim from
# dev/design/audit/ports.R, which is in the history since the rewrite closed (dev/README.md).
# They encode the conventions register (K-10 to K-17, K-30 to K-33) independently of the
# C++ core and reproduce the reference's iteration counts with estimates equal to near
# machine precision (V10.1, V12.1), so the tests use them as per-iteration oracles.
# Do not edit them here: change the audit file and copy it again.

# Line-by-line R ports of the reference C++ fitters (src/Fixed_effect.cpp at 5260838).
# Used only to confirm iteration semantics and numerical constants: if a port that
# encodes the conventions in dev/CONVENTIONS.md reproduces the C++ results and
# iteration counts, those conventions are what the C++ code does.
#
# The ports differ from the C++ only in floating-point summation order (R's sum() and
# rowsum() versus Armadillo), so agreement is expected to near machine precision, not
# bitwise.

port_loglik <- function(y, z_beta, gamma_obs) {
  eta <- gamma_obs + z_beta
  sum(eta * y - log(1 + exp(eta)))
}

port_clamp <- function(gamma, bound) {
  centre <- stats::median(gamma)
  pmin(pmax(gamma, centre - bound), centre + bound)
}

port_criteria <- function(d_beta_step, d_loglik, loglik_old, loglik_init) {
  c(beta = max(abs(d_beta_step)),
    relch = abs(d_loglik / (d_loglik + loglik_old)),
    ratch = abs(d_loglik / (d_loglik + loglik_old - loglik_init)))
}

port_crit <- function(crits, stop) {
  switch(stop,
         beta = crits[["beta"]], relch = crits[["relch"]], ratch = crits[["ratch"]],
         all = max(crits), or = min(crits),
         stop("Argument 'stop' NOT as required!"))
}

# Port of logis_BIN_fe_prov (SerBIN), Fixed_effect.cpp:338-472, threads == 1 branch.
port_serbin <- function(y, z, n_prov, gamma, beta, tol = 1e-5, max_iter = 10000,
                        bound = 10, backtrack = TRUE, stop = "or",
                        armijo_s = 0.01, armijo_t = 0.6, weight_floor = 1e-20) {
  prov <- rep(seq_along(n_prov), n_prov)
  iter <- 0
  crit <- 100
  loglik_init <- port_loglik(y, drop(z %*% beta), rep(gamma, n_prov))
  n_backtracks <- 0
  n_clamped <- 0
  trace <- list()
  while (iter <= max_iter) {                       # note: <=, so max_iter + 1 iterations are possible
    if (crit < tol) break
    iter <- iter + 1
    gamma_obs <- rep(gamma, n_prov)
    z_beta <- drop(z %*% beta)
    loglik <- port_loglik(y, z_beta, gamma_obs)
    p <- 1 / (1 + exp(-gamma_obs - z_beta))
    resid <- y - p
    pq <- p * (1 - p)
    pq[pq == 0] <- weight_floor                    # floor applies to the gamma and beta blocks
    score_gamma <- drop(rowsum(resid, prov))
    info_gamma_inv <- 1 / drop(rowsum(pq, prov))
    info_beta_gamma <- t(rowsum(z * (p * (1 - p)), prov))  # cross block uses the UNfloored weights
    score_beta <- drop(crossprod(z, resid))
    info_beta <- crossprod(z, z * pq)
    tmp1 <- t(info_beta_gamma * rep(info_gamma_inv, each = nrow(info_beta_gamma)))
    schur <- info_beta - t(tmp1) %*% t(info_beta_gamma)
    tmp2 <- solve(schur, t(tmp1))
    d_gamma <- drop(info_gamma_inv * score_gamma + t(tmp2) %*% (t(tmp1) %*% score_gamma - score_beta))
    d_beta <- drop(solve(schur, score_beta) - tmp2 %*% score_gamma)
    v <- 1
    if (backtrack) {
      lambda <- sum(score_gamma * d_gamma) + sum(score_beta * d_beta)
      d_loglik <- port_loglik(y, drop(z %*% (beta + v * d_beta)), rep(gamma + v * d_gamma, n_prov)) - loglik
      while (d_loglik < armijo_s * v * lambda) {
        v <- armijo_t * v
        n_backtracks <- n_backtracks + 1
        d_loglik <- port_loglik(y, drop(z %*% (beta + v * d_beta)), rep(gamma + v * d_gamma, n_prov)) - loglik
      }
    }
    gamma_unclamped <- gamma + v * d_gamma
    gamma <- port_clamp(gamma_unclamped, bound)
    n_clamped <- n_clamped + sum(gamma != gamma_unclamped)
    beta <- beta + v * d_beta
    d_loglik <- port_loglik(y, drop(z %*% beta), rep(gamma, n_prov)) - loglik
    crits <- port_criteria(v * d_beta, d_loglik, loglik, loglik_init)
    crit <- port_crit(crits, stop)
    trace[[iter]] <- c(iter = iter, step = v, crits)
  }
  list(gamma = gamma, beta = beta, iter = iter, n_backtracks = n_backtracks,
       n_clamped = n_clamped, trace = do.call(rbind, trace))
}

# Port of logis_fe_prov (BAN), Fixed_effect.cpp:124-335.
port_ban <- function(y, z, n_prov, gamma, beta, backtrack = 1L, max_iter = 10000,
                     bound = 10, tol = 1e-5, stop = "or",
                     armijo_s = 0.01, armijo_t = 0.6, weight_floor = 1e-20) {
  prov <- rep(seq_along(n_prov), n_prov)
  iter <- 0
  crit <- 100
  loglik_init <- port_loglik(y, drop(z %*% beta), rep(gamma, n_prov))
  n_backtracks <- 0
  if (!backtrack %in% c(0L, 1L)) {
    return(list(gamma = gamma, beta = beta, iter = 0L, n_backtracks = 0))
  }
  while (iter < max_iter) {                        # note: <, so at most max_iter iterations
    if (crit < tol) break
    iter <- iter + 1
    gamma_obs <- rep(gamma, n_prov)
    z_beta <- drop(z %*% beta)
    loglik_old <- port_loglik(y, z_beta, gamma_obs)
    p <- 1 / (1 + exp(-gamma_obs - z_beta))
    pq <- p * (1 - p)
    pq[pq == 0] <- weight_floor                    # floor applies to the gamma step only
    score_gamma <- drop(rowsum(y - p, prov))
    d_gamma <- score_gamma / drop(rowsum(pq, prov))
    v <- 1
    if (backtrack == 1L) {
      lambda <- sum(score_gamma * d_gamma)
      d_loglik <- port_loglik(y, z_beta, rep(gamma + v * d_gamma, n_prov)) - loglik_old
      while (d_loglik < armijo_s * v * lambda) {
        v <- armijo_t * v
        n_backtracks <- n_backtracks + 1
        d_loglik <- port_loglik(y, z_beta, rep(gamma + v * d_gamma, n_prov)) - loglik_old
      }
    }
    gamma <- port_clamp(gamma + v * d_gamma, bound)
    gamma_obs <- rep(gamma, n_prov)
    p <- 1 / (1 + exp(-gamma_obs - z_beta))        # beta step uses the old beta's linear predictor
    pq <- p * (1 - p)                              # no floor in the beta step
    score_beta <- drop(crossprod(z, y - p))
    info_beta <- crossprod(z, z * pq)
    d_beta <- drop(solve(info_beta, score_beta))
    v <- 1
    if (backtrack == 1L) {
      loglik <- port_loglik(y, z_beta, gamma_obs)
      lambda <- sum(score_beta * d_beta)
      d_loglik <- port_loglik(y, drop(z %*% (beta + v * d_beta)), gamma_obs) - loglik
      while (d_loglik < armijo_s * v * lambda) {
        v <- armijo_t * v
        n_backtracks <- n_backtracks + 1
        d_loglik <- port_loglik(y, drop(z %*% (beta + v * d_beta)), gamma_obs) - loglik
      }
      beta <- beta + v * d_beta
      d_loglik <- port_loglik(y, drop(z %*% beta), gamma_obs) - loglik_old
      crit <- port_crit(port_criteria(v * d_beta, d_loglik, loglik_old, loglik_init), stop)
    } else {
      beta <- beta + d_beta
      d_loglik <- port_loglik(y, drop(z %*% beta), gamma_obs) - loglik_old
      crit <- port_crit(port_criteria(d_beta, d_loglik, loglik_old, loglik_init), stop)
    }
  }
  list(gamma = gamma, beta = beta, iter = iter, n_backtracks = n_backtracks)
}

# Port of logis_firth_prov (Firth.cpp:84-416) for threads == 1. One Newton step per
# iteration on the Firth-modified score, no line search, clamp after the gamma update,
# stopping rule "beta" (the only rule logis_firth() uses).
port_firth <- function(y, z, n_prov, gamma, beta, tol = 1e-5, max_iter = 1000, bound = 10,
                       weight_floor = 1e-10) {
  prov <- rep(seq_along(n_prov), n_prov)
  info_at <- function(gamma, beta) {
    p <- 1 / (1 + exp(-rep(gamma, n_prov) - drop(z %*% beta)))
    pq <- p * (1 - p)
    pq[pq == 0] <- weight_floor                    # Firth floors every weight it uses
    d <- drop(rowsum(pq, prov))                    # I_gamma,gamma diagonal
    b <- t(rowsum(z * pq, prov))                   # I_beta,gamma (p x m)
    j <- sweep(b, 2, d, "/")                       # J_i = B_i / D_i
    schur <- crossprod(z, z * pq) - j %*% t(b)     # sum_i (C_i - J_i B_i')
    list(p = p, pq = pq, d = d, j = j, schur = schur)
  }
  logdet <- function(d, schur) {
    s <- 0.5 * (schur + t(schur))
    r <- tryCatch(chol(s), error = function(e) chol(s + 1e-8 * diag(nrow(s))))
    sum(log(pmax(d, 1e-12))) + 2 * sum(log(diag(r)))
  }
  iter <- 0
  crit <- 1e9
  st <- info_at(gamma, beta)
  while (iter < max_iter && crit > tol) {          # note: continues while crit > tol
    s_inv <- solve(st$schur)
    j2 <- s_inv %*% st$j                           # S^-1 J_i
    zj2 <- z %*% j2                                # z_ij' S^-1 J_i for every provider i (n x m)
    c1 <- (1 / st$d + colSums(st$j * j2))[prov]
    c2 <- -zj2[cbind(seq_along(prov), prov)]
    c3 <- rowSums((z %*% s_inv) * z)
    resid_adj <- (y - st$p) + st$pq * (c1 + 2 * c2 + c3) * (0.5 - st$p)
    score_gamma <- drop(rowsum(resid_adj, prov))
    h <- drop(st$j %*% score_gamma) - drop(crossprod(z, resid_adj))
    d_beta <- -drop(s_inv %*% h)
    beta <- beta + d_beta
    iter <- iter + 1
    gamma <- gamma + score_gamma / st$d + drop(crossprod(j2, h))
    gamma <- port_clamp(gamma, bound)
    st <- info_at(gamma, beta)
    crit <- max(abs(d_beta))
  }
  penalized <- port_loglik(y, drop(z %*% beta), rep(gamma, n_prov)) + 0.5 * logdet(st$d, st$schur)
  list(gamma = gamma, beta = beta, iter = iter, crit = crit, loglik_penalized = penalized)
}

# The inputs logis_fe() passes to the C++ fitters (logis_fe.R:183-218), for data that
# already satisfy every provider's n_i >= cutoff.
port_inputs <- function(data, y_name, provider_name, covariate_names) {
  data <- data[order(factor(data[[provider_name]])), ]
  n_prov <- as.numeric(table(factor(data[[provider_name]])))
  y <- data[[y_name]]
  z <- as.matrix(data[, covariate_names, drop = FALSE])
  start <- log(mean(y) / (1 - mean(y)))
  list(y = y, z = z, n_prov = n_prov, gamma = rep(start, length(n_prov)),
       beta = rep(0, ncol(z)))
}
