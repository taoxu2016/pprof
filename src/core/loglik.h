// The logistic log-likelihood (K-11).
#ifndef PPROF_CORE_LOGLIK_H
#define PPROF_CORE_LOGLIK_H

#include "core/armadillo.h"

namespace pprof {
namespace core {

// sum((gamma_obs + z_beta) * y - log(1 + exp(gamma_obs + z_beta))), evaluated directly as
// the reference does (src/Fixed_effect.cpp:87-89): it overflows to -Inf when a linear
// predictor exceeds about 709, and Armadillo's sum accumulates the terms in the reference's
// order.
double logistic_loglik(const arma::vec& y, const arma::vec& z_beta, const arma::vec& gamma_obs);

}  // namespace core
}  // namespace pprof

#endif  // PPROF_CORE_LOGLIK_H
