#include "core/information_blocks.h"

#include <utility>
#include <vector>

#include "core/constants.h"

namespace pprof {
namespace core {

void floor_zero_weights(arma::vec& weights) {
  if (arma::any(weights == 0)) {
    weights.replace(0, kFitWeightFloor);
  }
}

arma::vec diagonal_sums(const arma::vec& weights, const ProviderLayout& layout) {
  return provider_sums(weights, layout);
}

arma::vec diagonal_dots(const arma::vec& p, const ProviderLayout& layout) {
  arma::vec out(layout.n_providers());
  for (arma::uword i = 0; i < layout.n_providers(); ++i) {
    const arma::uword first = layout.first(i);
    const arma::uword last = layout.last(i);
    out(i) = arma::dot(p.subvec(first, last), 1 - p.subvec(first, last));
  }
  return out;
}

arma::vec cross_block_column(const arma::mat& z, const arma::vec& p, const ProviderLayout& layout,
                             arma::uword provider) {
  const arma::uword first = layout.first(provider);
  const arma::uword last = layout.last(provider);
  // Armadillo offers each_col() only on a non-const row block. The block is only read here,
  // and taking it from z directly, as the reference does, avoids copying the rows.
  arma::subview<double> rows = const_cast<arma::mat&>(z).rows(first, last);
  return arma::sum(rows.each_col() % (p.subvec(first, last) % (1 - p.subvec(first, last)))).t();
}

arma::mat cross_block(const arma::mat& z, const arma::vec& p, const ProviderLayout& layout) {
  arma::mat out(z.n_cols, layout.n_providers());
  for (arma::uword i = 0; i < layout.n_providers(); ++i) {
    out.col(i) = cross_block_column(z, p, layout, i);
  }
  return out;
}

arma::mat covariate_block(const arma::mat& z, const arma::vec& weights, int threads) {
  if (threads <= 1) {
    return z.t() * (z.each_col() % weights);
  }
  const arma::uword p = z.n_cols;
  std::vector<std::pair<arma::uword, arma::uword>> upper;  // (row, column), row <= column
  upper.reserve(p * (p + 1) / 2);
  for (arma::uword column = 0; column < p; ++column) {
    for (arma::uword row = 0; row <= column; ++row) {
      upper.emplace_back(row, column);
    }
  }
  arma::mat out(p, p);
  const long n_pairs = static_cast<long>(upper.size());
  // Each pair writes its own two elements; nothing in the loop can throw.
#pragma omp parallel for num_threads(threads) schedule(static)
  for (long k = 0; k < n_pairs; ++k) {
    const arma::uword row = upper[k].first;
    const arma::uword column = upper[k].second;
    out(row, column) = arma::dot(z.col(row), z.col(column) % weights);
    out(column, row) = out(row, column);
  }
  return out;
}

arma::mat schur_complement(const arma::mat& covariate, const arma::mat& cross,
                           const arma::vec& diagonal_inverse) {
  return covariate - (cross.each_row() % diagonal_inverse.t()) * cross.t();
}

arma::mat scaled_cross_transposed(const arma::mat& cross, const arma::vec& diagonal_inverse) {
  return arma::trans(cross.each_row() % diagonal_inverse.t());
}

arma::mat schur_complement_serbin(const arma::mat& covariate, const arma::mat& cross,
                                  const arma::mat& scaled_transposed) {
  return covariate - scaled_transposed.t() * cross.t();
}

}  // namespace core
}  // namespace pprof
