// Stopping criteria and rules of the logistic fixed-effect engines (K-16).
#ifndef PPROF_CORE_CONVERGENCE_H
#define PPROF_CORE_CONVERGENCE_H

#include "core/armadillo.h"
#include "core/types.h"

namespace pprof {
namespace core {

// The criteria after an iteration whose covariate step was beta_step, whose log-likelihood
// change was d_loglik (after the update and the clamp), with loglik_reference the
// log-likelihood the change is measured against and loglik_initial the log-likelihood at
// the starting values:
//   coefficients    = max |beta_step|
//   relative_loglik = |d_loglik / (d_loglik + loglik_reference)|
//   relative_gain   = |d_loglik / (d_loglik + loglik_reference - loglik_initial)|
// and the rule's value: one criterion, or for kAll and kAny the largest and the smallest of
// the three, computed with Armadillo's max() and min() as in the reference
// (src/Fixed_effect.cpp:424-464).
IterationCriteria iteration_criteria(const arma::vec& beta_step, double d_loglik, double loglik_reference,
                                     double loglik_initial, StopRule rule);

}  // namespace core
}  // namespace pprof

#endif  // PPROF_CORE_CONVERGENCE_H
