#include "core/provider_layout.h"

#include <stdexcept>

namespace pprof {
namespace core {

ProviderLayout::ProviderLayout(const std::vector<int>& sizes) : first_(sizes.size()), last_(sizes.size()), n_obs_(0) {
  for (std::size_t i = 0; i < sizes.size(); ++i) {
    if (sizes[i] < 1) {
      throw std::invalid_argument("every provider must have at least one observation");
    }
    first_(i) = n_obs_;
    n_obs_ += static_cast<arma::uword>(sizes[i]);
    last_(i) = n_obs_ - 1;
  }
}

arma::vec expand(const arma::vec& values, const ProviderLayout& layout) {
  arma::vec out(layout.n_obs());
  for (arma::uword i = 0; i < layout.n_providers(); ++i) {
    out(layout.rows(i)).fill(values(i));
  }
  return out;
}

arma::vec provider_sums(const arma::vec& x, const ProviderLayout& layout) {
  arma::vec out(layout.n_providers());
  for (arma::uword i = 0; i < layout.n_providers(); ++i) {
    out(i) = arma::sum(x(layout.rows(i)));
  }
  return out;
}

}  // namespace core
}  // namespace pprof
