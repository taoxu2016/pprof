// Firth-corrected logistic fixed effects (K-30 to K-33).
#ifndef PPROF_LOGISTIC_FIRTH_H
#define PPROF_LOGISTIC_FIRTH_H

#include <functional>
#include <vector>

#include "core/armadillo.h"
#include "core/provider_layout.h"

namespace pprof {
namespace logistic {

// Settings of the Firth engine. Its stopping rule is fixed: the largest absolute change of a
// coefficient (K-33). The defaults of the user-facing arguments live in the R function
// signatures (NAMING.md §4); the adapter sets every field.
struct FirthSettings {
  int max_iter;
  double tol;
  double effect_bound;
  int threads;  // at least 1
  // Called once before each iteration, never inside a parallel region (as in
  // core::FitSettings): the adapter checks for a user interrupt there.
  std::function<void()> before_iteration;
};

// One iteration: its stopping criterion, max |d_beta|, and the penalized log-likelihood at
// the estimates after the iteration.
struct FirthIteration {
  double coefficients;
  double penalized_loglik;
};

// The result of the Firth engine. The reference returned only the estimates to R and
// discarded the rest (D-03, D-12).
struct FirthResult {
  arma::vec gamma;
  arma::vec beta;
  int iterations;
  bool converged;                   // the last criterion is at most tol
  double criterion;                 // the last criterion; kFirthInitialCriterion if no iteration ran
  double penalized_loglik_initial;  // at the starting values; NaN if no iteration ran
  double penalized_loglik;          // at the returned estimates; NaN if no iteration ran
  std::vector<FirthIteration> history;
};

// The log-determinant of the information matrix from its blocks (K-30), as the reference's
// logdet_info() computes it (src/Firth.cpp:25-47): the sum of log(max(D_i, 1e-12)) over the
// provider diagonal `diagonal`, plus 2 sum(log(diag(R))) for the Cholesky factor R of the
// symmetrized Schur complement (schur + schur') / 2. When that factorization fails it is
// retried once with 1e-8 added to the diagonal; when the retry fails too, throws
// std::runtime_error.
double information_log_determinant(const arma::vec& diagonal, const arma::mat& schur);

// Fits provider effects gamma and coefficients beta by Firth's penalized likelihood, from the
// starting values gamma_start and beta_start (which are copied, never changed). Reproduces the
// reference's logis_firth_prov() with stop = "beta" (src/Firth.cpp:84-416) operation by
// operation, in the order in which the reference computes with one thread:
//   - the information blocks use the weights p(1 - p), with weights that are exactly 0
//     replaced by 1e-10 in every block (K-31); each provider's term of the Schur complement
//     and of the covariate score is added in provider order;
//   - each iteration takes a full Newton step on the modified score, whose residuals are
//     y - p + h (1/2 - p) with the hat values h from the block inverse, without a line
//     search (K-32);
//   - after each update the provider effects are clamped to median +/- effect_bound (K-15)
//     and the information is recomputed at the clamped effects;
//   - the loop continues while fewer than max_iter iterations have run and the criterion,
//     max |d_beta| (initially 1e9), is above tol (K-33);
//   - the penalized log-likelihood, l + log det(I) / 2 (K-30), is computed after every
//     iteration and at the starting values, as in the reference, although the stopping rule
//     does not use it.
// Providers are processed in parallel with settings.threads threads, but every sum over
// providers is added in provider order, so the result does not depend on the number of
// threads (the reference's parallel region raced, D-05). Throws std::runtime_error when the
// Schur complement of the information cannot be inverted or factorized (where the reference
// terminated R, D-42), or when a provider's computation fails; nothing is thrown inside a
// parallel region.
FirthResult fit_firth(const arma::vec& y, const arma::mat& z, const core::ProviderLayout& layout,
                      const arma::vec& gamma_start, const arma::vec& beta_start, const FirthSettings& settings);

}  // namespace logistic
}  // namespace pprof

#endif  // PPROF_LOGISTIC_FIRTH_H
