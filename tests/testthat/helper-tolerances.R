# Named tolerances for comparisons with the reference fixtures (brief §3.4; ARCHITECTURE §G.4).
#
# A value a matches its reference b when |a - b| <= atol + rtol * |b|, elementwise.
# Each tolerance has a one-line justification and changes only with sign-off. A failing
# comparison is never fixed by loosening a tolerance (brief §3.3).

pprof_tolerances <- list(
  exact = list(
    tier = 0, atol = 0, rtol = 0,
    why = paste("Discrete outputs (inclusion, sizes, event counts, screening indicators, ordering, dimensions,",
                "iteration counts, flags) must match exactly.")
  ),
  closed_form = list(
    tier = 1, atol = 1e-12, rtol = 1e-10,
    why = paste("Closed-form recomputations with a different summation order differed by at most 1.1e-14 relative",
                "in Phase 0 (V10.17, V13.12, V14.1, B2); four orders of margin for BLAS and compiler differences.")
  ),
  iterative = list(
    tier = 2, atol = 1e-12, rtol = 1e-10,
    why = paste("Iterative estimates reproduce the reference iteration path (same iteration count); ports with",
                "identical paths differed by at most 2e-15 (V10.1, V10.2, V12.1).")
  ),
  probability = list(
    tier = 1, atol = 1e-14, rtol = 1e-10,
    why = paste("p-values need an absolute floor near 0; 1e-14 is above the recomputation noise observed in Phase 0",
                "(V13.4: 2.7e-15 in statistics).")
  ),
  root = list(
    tier = 3, atol = 2.5e-4, rtol = 2.5e-4,
    why = paste("Twice the default uniroot() tolerance (1.22e-4) on the provider-effect scale, also applied",
                "relatively so it carries over to ratio and rate limits (DEC-019); roots matched bitwise in Phase 0",
                "(V13.15).")
  ),
  lme4 = list(
    tier = 4, atol = 1e-10, rtol = 1e-8,
    why = paste("lme4-backed results under the pinned lme4 and Matrix versions; identical calls gave identical",
                "results in Phase 0 (V15.1), and the margin covers optimizer sensitivity to rounding across platforms.")
  )
)

# The statistic of the exact Poisson-binomial test (DEC-083, D-53) is qnorm() of a tail
# probability computed as 1 - ppoibin(), whose absolute error of a few units in the last place
# of 1 the quantile multiplies by 1 / dnorm(z) (2e14 at z = 8). So it is compared on the scale it
# is computed on: a statistic matches when it is within the case's tolerance, or when it has the
# reference's sign and its tail probability pnorm(-|z|) is within the case's tolerance of the
# reference's, as the p-value is. The rule applies to no other statistic.
pprof_exact_statistic <- list(
  scale = "tail probability",
  why = paste("Last-bit noise in the linear predictor, as OpenBLAS's grouping of rows makes (D-53), moved up to 16",
              "of 1,000 exact statistics by up to 4.2e-3 (at z = 7.8) beyond the iterative tolerance and none beyond",
              "it on the tail probability, where a shift of the null by 1e-9 still fails 68% to 93% of providers.")
)

reference_tolerance <- function(tier) {
  tol <- pprof_tolerances[[tier]]
  if (is.null(tol)) stop("Unknown tolerance tier: ", tier, call. = FALSE)
  tol
}
