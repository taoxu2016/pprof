// Armijo backtracking (K-14).
#ifndef PPROF_CORE_LINE_SEARCH_H
#define PPROF_CORE_LINE_SEARCH_H

#include "core/constants.h"

namespace pprof {
namespace core {

// The step length along a Newton direction. gain(v) returns the log-likelihood gain of the
// step of length v, and lambda = U'd is the gain's slope at v = 0. The first length is 1;
// a length is accepted when gain(v) >= kArmijoSufficientIncrease * v * lambda, and is
// otherwise multiplied by kArmijoShrink, without a lower limit, as in the reference
// (src/Fixed_effect.cpp:402-415). A gain that is NaN accepts the current length, because the
// comparison is false, as in the reference.
template <typename Gain>
double armijo_step(const Gain& gain, double lambda) {
  double v = 1.0;
  double d_loglik = gain(v);
  while (d_loglik < kArmijoSufficientIncrease * v * lambda) {
    v = kArmijoShrink * v;
    d_loglik = gain(v);
  }
  return v;
}

}  // namespace core
}  // namespace pprof

#endif  // PPROF_CORE_LINE_SEARCH_H
