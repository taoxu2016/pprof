# Final review, D-53 (DEC-083): how last-bit differences in the linear predictor move the exact
# test's statistic, and what the comparison rules accept. For each exact-test case, the
# statistics are recomputed as the reference computes them (R/test.logis_fe.R:211-226) from the
# package's fit, then with the linear predictor perturbed in its last bit in about one row in
# ten (as a BLAS that groups rows differently does, D-53), and with the null shifted by 1e-9 and
# 1e-6 on the logit scale (a real error). Each perturbed set is compared with the unperturbed one
# under the case's tolerance and under the tail-probability rule of DEC-083.
# Run from the repository root: Rscript <this file> <output file>
args <- commandArgs(trailingOnly = TRUE)
suppressMessages(devtools::load_all(".", quiet = TRUE, helpers = TRUE, export_all = TRUE))
sink(args[1])
tol <- reference_tolerance("iterative")
within_tier <- function(z, z0) abs(z - z0) <= tol$atol + tol$rtol * abs(z0)
within_rule <- function(z, z0) {
  q <- stats::pnorm(-abs(z))
  q0 <- stats::pnorm(-abs(z0))
  within_tier(z, z0) | (sign(z) == sign(z0) & abs(q - q0) <= tol$atol + tol$rtol * q0)
}
run_case <- function(id, set) {
  fixture <- reference_fixture(id, set)
  fit <- reference_run(fixture$case$args$fit$case_id, set)$raw_value
  expected <- reference_expected_result(id, set)$value
  data <- fit$data_include
  y <- data[[fit$char_list$Y.char]]
  prov <- data[[fit$char_list$ProvID.char]]
  null <- fixture$case$args$null
  gamma_null <- if (is.null(null)) stats::median(fit$coefficient$gamma) else null
  lp <- as.vector(unname(as.matrix(data[, fit$char_list$Z.char])) %*% fit$coefficient$beta)
  stat <- function(lp) {
    vapply(split(seq_along(y), factor(prov, levels = unique(prov))), function(i) {
      p <- pmin(pmax(stats::plogis(gamma_null + lp[i]), 1e-10), 1 - 1e-10)
      o <- sum(y[i])
      stats::qnorm(1 - poibin::ppoibin(o, p) + 0.5 * poibin::dpoibin(o, p), lower.tail = FALSE)
    }, numeric(1))
  }
  z0 <- stat(lp)
  cat(sprintf("%s: %d providers, |z| from %.3g to %.3g; recomputed against the fixture: largest |dz| %.3g\n", id,
              length(z0), min(abs(z0)), max(abs(z0)), max(abs(z0 - expected$stat))))
  set.seed(1)
  for (r in 1:5) {
    flip <- sample(c(-1, 0, 1), length(lp), replace = TRUE, prob = c(0.05, 0.9, 0.05))
    z1 <- stat(lp * (1 + flip * .Machine$double.eps))
    k <- which.max(abs(z1 - z0))
    cat(sprintf(paste("  last-bit noise, run %d: largest |dz| %.3g at z = %.6g (p-value %.3g);",
                      "outside the tolerance %d, outside the rule %d\n"),
                r, abs(z1 - z0)[k], z0[k], 2 * stats::pnorm(-abs(z0[k])), sum(!within_tier(z1, z0)),
                sum(!within_rule(z1, z0))))
  }
  for (shift in c(1e-9, 1e-6)) {
    cat(sprintf("  null shifted by %g: %d of %d providers outside the rule\n", shift,
                sum(!within_rule(stat(lp + shift), z0)), length(z0)))
  }
}
run_case("test-binary-exact-null0", "core")
run_case("test-extreme-exact", "core")
run_case("test-medium-exact", "full")
cat("\n", R.version.string, "; ", utils::sessionInfo()$running, "; BLAS: ", utils::sessionInfo()$BLAS, "\n", sep = "")
sink()
