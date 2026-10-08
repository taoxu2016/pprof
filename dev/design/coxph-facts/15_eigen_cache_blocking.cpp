// The C++ half of 15_eigen_cache_blocking.R: Eigen's matrix products computed with Eigen's L1
// cache size set to a given value, and the inner-dimension block size Eigen chooses for it.
// [[Rcpp::depends(RcppEigen)]]
#include <RcppEigen.h>

// Sets Eigen's L1 cache size, keeping its L2 and L3 sizes; returns the previous L1 size.
static std::ptrdiff_t set_l1(std::ptrdiff_t l1) {
  std::ptrdiff_t l1_old, l2, l3;
  Eigen::internal::manage_caching_sizes(Eigen::GetAction, &l1_old, &l2, &l3);
  Eigen::setCpuCacheSizes(l1, l2, l3);
  return l1_old;
}

// The cache sizes Eigen read from this processor.
// [[Rcpp::export]]
Rcpp::NumericVector cache_sizes() {
  return Rcpp::NumericVector::create(Rcpp::_["l1"] = Eigen::l1CacheSize(),
                                     Rcpp::_["l2"] = Eigen::l2CacheSize(),
                                     Rcpp::_["l3"] = Eigen::l3CacheSize());
}

// The block size along the inner dimension k of an m x k by k x n double product, single-threaded.
// [[Rcpp::export]]
double inner_block(double k, double m, double n, double l1) {
  std::ptrdiff_t l1_old = set_l1(static_cast<std::ptrdiff_t>(l1));
  Eigen::Index kc = static_cast<Eigen::Index>(k), mc = static_cast<Eigen::Index>(m),
               nc = static_cast<Eigen::Index>(n), threads = 1;
  Eigen::internal::computeProductBlockingSizes<double, double, 1>(kc, mc, nc, threads);
  set_l1(l1_old);
  return static_cast<double>(kc);
}

// A general product A B.
// [[Rcpp::export]]
Eigen::MatrixXd product_with_l1(const Eigen::MatrixXd& A, const Eigen::MatrixXd& B, double l1) {
  std::ptrdiff_t l1_old = set_l1(static_cast<std::ptrdiff_t>(l1));
  Eigen::MatrixXd C = A * B;
  set_l1(l1_old);
  return C;
}

// The cross-product V'V by a rank update, the form in which lme4 accumulates its cross-products.
// [[Rcpp::export]]
Eigen::MatrixXd crossprod_with_l1(const Eigen::MatrixXd& V, double l1) {
  std::ptrdiff_t l1_old = set_l1(static_cast<std::ptrdiff_t>(l1));
  Eigen::MatrixXd VtV = Eigen::MatrixXd::Zero(V.cols(), V.cols());
  VtV.selfadjointView<Eigen::Upper>().rankUpdate(V.adjoint());
  set_l1(l1_old);
  return VtV;
}
