#include "logistic/serbin.h"

#include "core/clamp.h"
#include "core/constants.h"
#include "core/convergence.h"
#include "core/information_blocks.h"
#include "core/line_search.h"
#include "core/loglik.h"

namespace pprof {
namespace logistic {
namespace {

// The Newton direction at (gamma, beta) and what the line search and the stopping rule need.
struct NewtonStep {
  double loglik;  // log-likelihood at (gamma, beta)
  arma::vec score_gamma;
  arma::vec score_beta;
  arma::vec d_gamma;
  arma::vec d_beta;
};

// src/Fixed_effect.cpp:363-399: the score, the information blocks, and the block-inverse
// solve of the Newton system, in the reference's operation order.
NewtonStep newton_step(const arma::vec& y, const arma::mat& z, const core::ProviderLayout& layout,
                       const arma::vec& gamma, const arma::vec& beta, int threads) {
  const arma::vec gamma_obs = core::expand(gamma, layout);
  const arma::vec z_beta = z * beta;
  NewtonStep step;
  step.loglik = core::logistic_loglik(y, z_beta, gamma_obs);
  const arma::vec p = 1 / (1 + arma::exp(-gamma_obs - z_beta));
  const arma::vec yp = y - p;
  arma::vec pq = p % (1 - p);
  core::floor_zero_weights(pq);

  step.score_gamma = core::provider_sums(yp, layout);
  const arma::vec diagonal_inverse = 1 / core::diagonal_sums(pq, layout);
  const arma::mat cross = core::cross_block(z, p, layout);
  step.score_beta = z.t() * yp;
  const arma::mat covariate = core::covariate_block(z, pq, threads);
  const arma::mat scaled = core::scaled_cross_transposed(cross, diagonal_inverse);
  const arma::mat schur = core::schur_complement_serbin(covariate, cross, scaled);

  const arma::mat schur_solve_scaled = arma::solve(schur, scaled.t(), arma::solve_opts::likely_sympd);
  step.d_gamma = diagonal_inverse % step.score_gamma +
                 schur_solve_scaled.t() * (scaled.t() * step.score_gamma - step.score_beta);
  const arma::vec schur_solve_score = arma::solve(schur, step.score_beta, arma::solve_opts::likely_sympd);
  step.d_beta = schur_solve_score - schur_solve_scaled * step.score_gamma;
  return step;
}

}  // namespace

core::FitResult fit_serbin(const arma::vec& y, const arma::mat& z, const core::ProviderLayout& layout,
                           const arma::vec& gamma_start, const arma::vec& beta_start,
                           const core::FitSettings& settings) {
  // The engine updates copies: the starting values can be views of the caller's memory.
  arma::vec gamma = gamma_start;
  arma::vec beta = beta_start;
  const double loglik_initial = core::logistic_loglik(y, z * beta, core::expand(gamma, layout));
  core::FitResult result;
  double criterion = core::kInitialCriterion;
  int iter = 0;
  while (iter <= settings.max_iter) {
    if (criterion < settings.tol) {
      break;
    }
    if (settings.before_iteration) {
      settings.before_iteration();
    }
    ++iter;
    const NewtonStep step = newton_step(y, z, layout, gamma, beta, settings.threads);
    double v = 1.0;
    if (settings.backtrack) {
      const double lambda = arma::dot(step.score_gamma, step.d_gamma) + arma::dot(step.score_beta, step.d_beta);
      const auto gain = [&](double length) {
        const arma::vec gamma_obs_trial = core::expand(gamma + length * step.d_gamma, layout);
        const arma::vec z_beta_trial = z * (beta + length * step.d_beta);
        return core::logistic_loglik(y, z_beta_trial, gamma_obs_trial) - step.loglik;
      };
      v = core::armijo_step(gain, lambda);
    }
    gamma += v * step.d_gamma;
    gamma = core::clamp_effects(gamma, settings.effect_bound);
    const arma::vec gamma_obs = core::expand(gamma, layout);
    beta += v * step.d_beta;
    const double d_loglik = core::logistic_loglik(y, z * beta, gamma_obs) - step.loglik;
    const core::IterationCriteria criteria =
        core::iteration_criteria(v * step.d_beta, d_loglik, step.loglik, loglik_initial, settings.stop_rule);
    result.history.push_back(criteria);
    criterion = criteria.rule;
  }
  result.gamma = gamma;
  result.beta = beta;
  result.iterations = iter;
  result.converged = criterion < settings.tol;
  return result;
}

}  // namespace logistic
}  // namespace pprof
