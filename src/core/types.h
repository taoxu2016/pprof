// Types shared by the fitting engines of the C++ core.
#ifndef PPROF_CORE_TYPES_H
#define PPROF_CORE_TYPES_H

#include <functional>
#include <vector>

#include "core/armadillo.h"

namespace pprof {
namespace core {

// Stopping rules of the logistic fixed-effect engines (K-16), named as in NAMING.md §4.
enum class StopRule {
  kAny,             // reference "or": the smallest of the three criteria is below tol
  kAll,             // reference "all": the largest of the three criteria is below tol
  kCoefficients,    // reference "beta": the largest absolute change of a coefficient
  kRelativeLoglik,  // reference "relch": the log-likelihood change relative to its new value
  kRelativeGain     // reference "ratch": the change relative to the gain since the start
};

// The three stopping criteria after an iteration (K-16), and the value of the stopping rule,
// which the engine compares with tol before the next iteration.
struct IterationCriteria {
  double coefficients;
  double relative_loglik;
  double relative_gain;
  double rule;
};

// Settings of the logistic fixed-effect engines. The defaults of the user-facing arguments
// live in the R function signatures (NAMING.md §4); the adapter sets every field.
struct FitSettings {
  int max_iter;
  double tol;
  double effect_bound;
  bool backtrack;
  StopRule stop_rule;
  int threads;
  // Called once before each iteration, never inside a parallel region. The adapter uses it
  // to check for a user interrupt, which it signals by throwing; the engines own all their
  // memory through Armadillo objects, so the exception leaks nothing.
  std::function<void()> before_iteration;
};

// The result of a fitting engine: the estimates, the number of iterations run, whether the
// stopping rule was met when the loop ended, and the criteria of every iteration.
struct FitResult {
  arma::vec gamma;
  arma::vec beta;
  int iterations;
  bool converged;
  std::vector<IterationCriteria> history;
};

}  // namespace core
}  // namespace pprof

#endif  // PPROF_CORE_TYPES_H
