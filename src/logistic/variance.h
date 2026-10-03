// Variances of the logistic fixed-effect estimates (K-20).
#ifndef PPROF_LOGISTIC_VARIANCE_H
#define PPROF_LOGISTIC_VARIANCE_H

#include "core/armadillo.h"
#include "core/provider_layout.h"

namespace pprof {
namespace logistic {

struct Variances {
  arma::mat beta;   // covariance matrix of the coefficients, S^-1
  arma::vec gamma;  // variance of each provider effect, 1/D_i + J_i' S^-1 J_i
};

// The block inverse of the unpenalized information at (gamma, beta), with the fitted
// probabilities clamped to [1e-10, 1 - 1e-10] and no weight floor, as the reference's
// logis_fe_var() computes it (src/Fixed_effect.cpp:645-677): Var(beta) = S^-1 with S the
// Schur complement, inverted by inv_sympd(); Var(gamma_i) = 1/D_i + J_i' S^-1 J_i with
// J_i = B_i / D_i. Throws std::runtime_error when S is singular or not positive definite,
// as the reference does.
Variances logistic_fe_variance(const arma::mat& z, const core::ProviderLayout& layout,
                               const arma::vec& gamma, const arma::vec& beta);

}  // namespace logistic
}  // namespace pprof

#endif  // PPROF_LOGISTIC_VARIANCE_H
