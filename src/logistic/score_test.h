// The "standard" provider score test of logistic fixed effects (K-66).
#ifndef PPROF_LOGISTIC_SCORE_TEST_H
#define PPROF_LOGISTIC_SCORE_TEST_H

#include <vector>

#include "core/armadillo.h"
#include "core/provider_layout.h"

namespace pprof {
namespace logistic {

struct ScoreTestResult {
  arma::vec statistic;       // one per requested provider, in the order requested
  std::vector<bool> failed;  // true where the adjusted information could not be inverted
};

// Score statistics for the providers in `providers` (0-based, in provider order) under the
// null effect gamma_null, without a refit, as the reference's Modified_score() computes them
// (src/Fixed_effect.cpp:510-594): the full-model estimates of the other providers and of
// beta are plugged in; the tested provider's null probabilities are not clamped; the full
// model's provider diagonal uses weights floored at 1e-20, its cross block does not; and
// the variance is V = I_aa - I_ab (I_bb* - I_bg I_gg^-1 I_gb)^-1 I_ba, where I_bb* uses the
// tested provider's null weights. Providers are computed in parallel with `threads`
// threads; each is independent, so the result does not depend on the thread count.
//
// Unlike the reference, which drops non-finite statistics so that its result no longer
// lines up with the providers (D-04), every requested provider keeps its position: a
// statistic is NaN or infinite where the reference's is, and NaN with failed = true where
// the adjusted information could not be inverted (there the reference's inv_sympd() throws
// inside its OpenMP region, which OpenMP does not allow).
ScoreTestResult standard_score_test(const arma::vec& y, const arma::mat& z,
                                    const core::ProviderLayout& layout, const arma::vec& gamma,
                                    const arma::vec& beta, double gamma_null,
                                    const arma::uvec& providers, int threads);

}  // namespace logistic
}  // namespace pprof

#endif  // PPROF_LOGISTIC_SCORE_TEST_H
