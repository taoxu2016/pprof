#include "core/convergence.h"

#include <cmath>

namespace pprof {
namespace core {

IterationCriteria iteration_criteria(const arma::vec& beta_step, double d_loglik, double loglik_reference,
                                     double loglik_initial, StopRule rule) {
  IterationCriteria criteria;
  criteria.coefficients = arma::norm(beta_step, "inf");
  criteria.relative_loglik = std::abs(d_loglik / (d_loglik + loglik_reference));
  criteria.relative_gain = std::abs(d_loglik / (d_loglik + loglik_reference - loglik_initial));
  arma::vec all(3);
  all(0) = criteria.coefficients;
  all(1) = criteria.relative_loglik;
  all(2) = criteria.relative_gain;
  switch (rule) {
    case StopRule::kCoefficients:
      criteria.rule = criteria.coefficients;
      break;
    case StopRule::kRelativeLoglik:
      criteria.rule = criteria.relative_loglik;
      break;
    case StopRule::kRelativeGain:
      criteria.rule = criteria.relative_gain;
      break;
    case StopRule::kAll:
      criteria.rule = all.max();
      break;
    case StopRule::kAny:
      criteria.rule = all.min();
      break;
  }
  return criteria;
}

}  // namespace core
}  // namespace pprof
