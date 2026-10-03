// Expected outcomes for direct standardization of logistic models (K-81).
#ifndef PPROF_LOGISTIC_DIRECT_EXPECTED_H
#define PPROF_LOGISTIC_DIRECT_EXPECTED_H

#include "core/armadillo.h"

namespace pprof {
namespace logistic {

// For each effect e_i, the expected number of events if every observation had that effect:
// the sum over all observations j of 1 / (1 + exp(-(e_i + linear_predictor_j))), added in
// observation order in double precision. This is the value the reference's
// computeDirectExp() returns (src/Fixed_effect.cpp:95-121): its inner OpenMP reduction runs
// on one thread, nested inside the loop over effects. Effects are computed in parallel with
// `threads` threads; each sum is independent, so the result does not depend on the thread
// count.
arma::vec direct_expected(const arma::vec& effects, const arma::vec& linear_predictor, int threads);

}  // namespace logistic
}  // namespace pprof

#endif  // PPROF_LOGISTIC_DIRECT_EXPECTED_H
