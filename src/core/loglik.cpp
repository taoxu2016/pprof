#include "core/loglik.h"

namespace pprof {
namespace core {

double logistic_loglik(const arma::vec& y, const arma::vec& z_beta, const arma::vec& gamma_obs) {
  return arma::sum((gamma_obs + z_beta) % y - arma::log(1 + arma::exp(gamma_obs + z_beta)));
}

}  // namespace core
}  // namespace pprof
