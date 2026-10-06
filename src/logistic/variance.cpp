#include "logistic/variance.h"

#include "core/constants.h"
#include "core/information_blocks.h"

namespace pprof {
namespace logistic {

Variances logistic_fe_variance(const arma::mat& z, const core::ProviderLayout& layout, const arma::vec& gamma,
                               const arma::vec& beta) {
  const arma::vec gamma_obs = core::expand(gamma, layout);
  arma::vec p = 1 / (1 + arma::exp(-gamma_obs - z * beta));
  p = arma::clamp(p, core::kVarianceProbabilityClamp, 1 - core::kVarianceProbabilityClamp);
  const arma::vec diagonal_inverse = 1 / core::diagonal_dots(p, layout);
  const arma::mat cross = core::cross_block(z, p, layout);
  const arma::mat covariate = core::covariate_block(z, p % (1 - p), 1);

  Variances out;
  out.beta = arma::inv_sympd(core::schur_complement(covariate, cross, diagonal_inverse));
  out.gamma.set_size(layout.n_providers());
  for (arma::uword i = 0; i < layout.n_providers(); ++i) {
    const arma::vec j = diagonal_inverse(i) * cross.col(i);
    out.gamma(i) = diagonal_inverse(i) + arma::as_scalar(j.t() * out.beta * j);
  }
  return out;
}

}  // namespace logistic
}  // namespace pprof
