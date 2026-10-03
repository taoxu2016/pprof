// Named numerical conventions of the C++ core (ARCHITECTURE §K, DEC-025).
//
// Each constant is a value that the reference implementation (pprof 1.0.3, commit 5260838)
// uses, named here once, with its entry in the conventions register (dev/PROJECT_CONTEXT.md
// §5.7) and the reference location it reproduces. Changing a value changes results and is
// a Class B change (brief §3.3). The R-side conventions are in R/constants.R.
#ifndef PPROF_CORE_CONSTANTS_H
#define PPROF_CORE_CONSTANTS_H

namespace pprof {
namespace core {

// K-13: observation weights p(1 - p) that are exactly 0 (a probability that rounded to 0 or
// 1) are replaced by kFitWeightFloor in the provider-effect diagonal of SerBIN, of BAN's
// provider step, and of the standard score test's full model, and in SerBIN's covariate
// block. The cross block, BAN's covariate step, and the standard score test's null weights
// use the weights without the floor.
// Reference: src/Fixed_effect.cpp:155, :262, :369, :520.
constexpr double kFitWeightFloor = 1e-20;

// K-14: Armijo backtracking. A step of length v along the Newton direction d is accepted
// when the log-likelihood gain is at least kArmijoSufficientIncrease * v * lambda, with
// lambda = U'd; otherwise v is multiplied by kArmijoShrink, without a lower limit.
// Reference: src/Fixed_effect.cpp:141, :354.
constexpr double kArmijoSufficientIncrease = 0.01;
constexpr double kArmijoShrink = 0.6;

// K-16: the stopping criterion before the first iteration. The loop stops when the
// criterion is below tol, checked at the top of each iteration, so the first iteration
// always runs.
// Reference: src/Fixed_effect.cpp:130, :346.
constexpr double kInitialCriterion = 100.0;

// K-20: before the variances are computed, fitted probabilities are clamped to
// [kVarianceProbabilityClamp, 1 - kVarianceProbabilityClamp]; no weight floor applies.
// Reference: src/Fixed_effect.cpp:649.
constexpr double kVarianceProbabilityClamp = 1e-10;

}  // namespace core
}  // namespace pprof

#endif  // PPROF_CORE_CONSTANTS_H
