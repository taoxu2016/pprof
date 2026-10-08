# Why CI's fixture-platform job (`.github/workflows/rewrite-reference.yaml`) fails the same 42
# lme4-backed reference cases on some runners and matches every case on others (D-53; found at the
# CoxPH Phase C0 gate). Eigen, which lme4 uses through RcppEigen, splits the inner dimension of a
# matrix product into blocks sized from the L1 data cache it reads from the processor at run time
# (RcppEigen's Eigen/src/Core/products/GeneralBlockPanelKernel.h, evaluateProductBlockingSizesHeuristic;
# Eigen/src/Core/util/Memory.h, queryCacheSizes), so one binary sums a long product in another
# order on a processor with another L1 data cache. lme4 forms its cross-products this way: V'V over
# the observations by rankUpdate() (lme4's src/predModule.cpp, merPredD::updateDecomp()).
# The script computes the same products with Eigen's L1 size set to 32 KB (AMD Zen 3, the failing
# runners' Family 25 Model 1) and to 48 KB (AMD Zen 5, the passing runners' Family 26 Model 2, and
# the Intel Tiger Lake, Family 6 Model 140, that produced the fixtures).
# Found on 2026-10-08 with RcppEigen 0.3.4.0.2 (the fixtures' version): from an inner dimension of
# 5,000 on, the inner blocks differ (504 rows at 32 KB, 720 to 744 at 48 KB) and so do most
# elements of the results (up to 7.7e-12 relative); up to 1,000 the blocks and the results are the
# same; at one setting the results repeat bit for bit. That lme4's fits move through this path is
# inferred from the runners' processors, not reproduced with lme4 itself.
# Run from the repository root: Rscript dev/design/coxph-facts/15_eigen_cache_blocking.R <output file>
# Needs Rcpp, RcppEigen, and a C++ toolchain (Rtools on Windows).
args <- commandArgs(trailingOnly = TRUE)
Rcpp::sourceCpp("dev/design/coxph-facts/15_eigen_cache_blocking.cpp")
sizes <- cache_sizes()
lines <- c(sprintf("%s, RcppEigen %s", R.version.string, utils::packageVersion("RcppEigen")),
           sprintf("Processor: %s; Eigen's cache sizes read from it: L1 %d, L2 %d, L3 %d bytes",
                   Sys.getenv("PROCESSOR_IDENTIFIER", "unknown"), sizes[["l1"]], sizes[["l2"]], sizes[["l3"]]),
           "",
           "Inner dimension k of a 50 x k by k x 50 product (A B) and of V'V for a k x 10 matrix V (rank update);",
           "Eigen's inner block, and the results, with its L1 size set to 32 KB and to 48 KB:")
set.seed(20261008)
for (k in c(100, 400, 1000, 5000, 7944, 20000)) {
  A <- matrix(rnorm(50 * k), 50, k)
  B <- matrix(rnorm(k * 50), k, 50)
  V <- matrix(rnorm(k * 10), k, 10)
  p32 <- product_with_l1(A, B, 32 * 1024)
  p48 <- product_with_l1(A, B, 48 * 1024)
  c32 <- crossprod_with_l1(V, 32 * 1024)
  c48 <- crossprod_with_l1(V, 48 * 1024)
  up <- upper.tri(c48, diag = TRUE)
  lines <- c(lines, sprintf(
    paste("  k = %5d: inner block %3d at 32 KB, %3d at 48 KB; A B: %4d of %d elements differ (up to %.1e relative);",
          "V'V: %2d of %d differ (up to %.1e); repeated at 48 KB, identical: %s"),
    k, inner_block(k, 50, 50, 32 * 1024), inner_block(k, 50, 50, 48 * 1024),
    sum(p32 != p48), length(p48), max(abs(p32 - p48) / abs(p48)),
    sum(c32[up] != c48[up]), sum(up), max(abs(c32[up] - c48[up]) / abs(c48[up])),
    identical(p48, product_with_l1(A, B, 48 * 1024)) && identical(c48, crossprod_with_l1(V, 48 * 1024))))
}
lines <- c(lines, "", "(7,944 is the number of rows of ExampleDataBinary, the data of the failing lme4 cases.)")
writeLines(lines, args[1])
