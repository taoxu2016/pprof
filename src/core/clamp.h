// The provider-effect clamp (K-15).
#ifndef PPROF_CORE_CLAMP_H
#define PPROF_CORE_CLAMP_H

#include "core/armadillo.h"

namespace pprof {
namespace core {

// After each update of the provider effects, every effect is clamped to
// median(gamma) - bound and median(gamma) + bound, with the median of the updated, unclamped
// effects, computed by Armadillo's median() as in the reference (src/Fixed_effect.cpp:417).
inline arma::vec clamp_effects(const arma::vec& gamma, double bound) {
  return arma::clamp(gamma, arma::median(gamma) - bound, arma::median(gamma) + bound);
}

}  // namespace core
}  // namespace pprof

#endif  // PPROF_CORE_CLAMP_H
