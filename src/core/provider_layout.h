// Observations grouped by provider.
//
// The data layer sorts observations by provider (K-05), so each provider owns one block of
// consecutive rows of every per-observation vector and of the design matrix. The reference
// walks these blocks with a running offset over the provider sizes (n_prov); the layout
// stores the first and last row of each block once.
#ifndef PPROF_CORE_PROVIDER_LAYOUT_H
#define PPROF_CORE_PROVIDER_LAYOUT_H

#include <vector>

#include "core/armadillo.h"

namespace pprof {
namespace core {

class ProviderLayout {
 public:
  // sizes: the number of observations of each provider, in provider order. Throws
  // std::invalid_argument when a size is below 1.
  explicit ProviderLayout(const std::vector<int>& sizes);

  arma::uword n_providers() const { return first_.n_elem; }
  arma::uword n_obs() const { return n_obs_; }
  arma::uword first(arma::uword provider) const { return first_(provider); }
  arma::uword last(arma::uword provider) const { return last_(provider); }
  arma::span rows(arma::uword provider) const {
    return arma::span(first_(provider), last_(provider));
  }

 private:
  arma::uvec first_;
  arma::uvec last_;
  arma::uword n_obs_;
};

// One value per observation from one value per provider: each provider's value repeated
// over its rows (the reference's rep(), src/Fixed_effect.cpp:25).
arma::vec expand(const arma::vec& values, const ProviderLayout& layout);

// The sum of x over each provider's rows, as Armadillo's sum() of the row block, which is
// how the reference forms provider scores and diagonal information (for example
// src/Fixed_effect.cpp:375-376).
arma::vec provider_sums(const arma::vec& x, const ProviderLayout& layout);

}  // namespace core
}  // namespace pprof

#endif  // PPROF_CORE_PROVIDER_LAYOUT_H
