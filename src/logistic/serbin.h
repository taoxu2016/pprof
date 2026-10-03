// SerBIN: serial blockwise inversion Newton for logistic fixed effects (K-12 to K-18).
#ifndef PPROF_LOGISTIC_SERBIN_H
#define PPROF_LOGISTIC_SERBIN_H

#include "core/armadillo.h"
#include "core/provider_layout.h"
#include "core/types.h"

namespace pprof {
namespace logistic {

// Fits provider effects gamma and coefficients beta by Newton-Raphson on (gamma, beta)
// jointly, using the block structure of the information matrix, from the starting values
// gamma_start and beta_start (which are copied, never changed). Reproduces the reference's logis_BIN_fe_prov() (src/Fixed_effect.cpp:338-472)
// operation by operation:
//   - each iteration solves the Newton system through the Schur complement (K-12), with
//     weights that are exactly 0 floored at 1e-20 in the provider and covariate blocks
//     (K-13);
//   - with settings.backtrack, the step length comes from Armijo backtracking on gamma and
//     beta jointly, on the unclamped provider effects (K-14);
//   - after each update the provider effects are clamped to median +/- effect_bound (K-15);
//   - the loop stops when the stopping rule's criterion is below tol, checked at the top
//     of each iteration (K-16), or after max_iter + 1 iterations, because the reference
//     loops while iter <= max_iter (K-17).
// Armadillo errors (for example a failed solve) are thrown to the caller.
core::FitResult fit_serbin(const arma::vec& y, const arma::mat& z, const core::ProviderLayout& layout,
                           const arma::vec& gamma_start, const arma::vec& beta_start,
                           const core::FitSettings& settings);

}  // namespace logistic
}  // namespace pprof

#endif  // PPROF_LOGISTIC_SERBIN_H
