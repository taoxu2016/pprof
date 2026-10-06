// BAN: block ascent Newton for logistic fixed effects (K-13 to K-17).
#ifndef PPROF_LOGISTIC_BAN_H
#define PPROF_LOGISTIC_BAN_H

#include "core/armadillo.h"
#include "core/provider_layout.h"
#include "core/types.h"

namespace pprof {
namespace logistic {

// Fits provider effects gamma and coefficients beta by alternating a Newton step for gamma
// with beta fixed and a Newton step for beta with the new gamma, from the starting values
// gamma_start and beta_start (which are copied, never changed). Reproduces the reference's logis_fe_prov() (src/Fixed_effect.cpp:124-335)
// operation by operation:
//   - the provider step floors weights that are exactly 0 at 1e-20; the covariate step
//     uses the weights without the floor (K-13);
//   - with settings.backtrack, each step's length comes from Armijo backtracking: the
//     provider step with beta fixed, then the covariate step from the new, clamped provider
//     effects with the old linear predictor as the reference log-likelihood (K-14);
//   - after the provider step the effects are clamped to median +/- effect_bound (K-15);
//   - the loop stops when the stopping rule's criterion is below tol, checked at the top
//     of each iteration (K-16), or after max_iter iterations, because the reference loops
//     while iter < max_iter (K-17). The covariate criterion is the largest change of a
//     coefficient after the line search.
// settings.threads is not used: the reference's BAN has no parallel code.
// Armadillo errors (for example a failed solve) are thrown to the caller.
core::FitResult fit_ban(const arma::vec& y, const arma::mat& z, const core::ProviderLayout& layout,
                        const arma::vec& gamma_start, const arma::vec& beta_start, const core::FitSettings& settings);

}  // namespace logistic
}  // namespace pprof

#endif  // PPROF_LOGISTIC_BAN_H
