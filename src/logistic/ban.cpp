#include "logistic/ban.h"

#include "core/clamp.h"
#include "core/constants.h"
#include "core/convergence.h"
#include "core/information_blocks.h"
#include "core/line_search.h"
#include "core/loglik.h"

namespace pprof {
namespace logistic {
namespace {

// One iteration with backtracking (src/Fixed_effect.cpp:147-246). Updates gamma and beta and
// returns the iteration's criteria.
core::IterationCriteria iterate_with_backtracking(const arma::vec& y, const arma::mat& z,
                                                  const core::ProviderLayout& layout, arma::vec& gamma, arma::vec& beta,
                                                  double loglik_initial, const core::FitSettings& settings) {
  // Provider step with beta fixed.
  arma::vec gamma_obs = core::expand(gamma, layout);
  const arma::vec z_beta = z * beta;
  const double loglik_old = core::logistic_loglik(y, z_beta, gamma_obs);
  arma::vec p = 1 / (1 + arma::exp(-gamma_obs - z_beta));
  const arma::vec yp = y - p;
  arma::vec pq = p % (1 - p);
  core::floor_zero_weights(pq);
  const arma::vec score_gamma = core::provider_sums(yp, layout);
  const arma::vec d_gamma = score_gamma / core::diagonal_sums(pq, layout);
  const double loglik_start = core::logistic_loglik(y, z_beta, gamma_obs);
  const auto gain_gamma = [&](double length) {
    return core::logistic_loglik(y, z_beta, core::expand(gamma + length * d_gamma, layout)) - loglik_start;
  };
  double v = core::armijo_step(gain_gamma, arma::dot(score_gamma, d_gamma));
  gamma += v * d_gamma;
  gamma = core::clamp_effects(gamma, settings.effect_bound);
  gamma_obs = core::expand(gamma, layout);

  // Covariate step from the new provider effects and the old linear predictor; no floor.
  p = 1 / (1 + arma::exp(-gamma_obs - z_beta));
  pq = p % (1 - p);
  const arma::vec score_beta = z.t() * (y - p);
  const arma::mat covariate = core::covariate_block(z, pq, 1);
  const arma::vec d_beta = arma::solve(covariate, score_beta, arma::solve_opts::fast + arma::solve_opts::likely_sympd);
  const double loglik_mid = core::logistic_loglik(y, z_beta, gamma_obs);
  const auto gain_beta = [&](double length) {
    return core::logistic_loglik(y, z * (beta + length * d_beta), gamma_obs) - loglik_mid;
  };
  v = core::armijo_step(gain_beta, arma::dot(score_beta, d_beta));
  beta += v * d_beta;
  const double d_loglik = core::logistic_loglik(y, z * beta, gamma_obs) - loglik_old;
  return core::iteration_criteria(v * d_beta, d_loglik, loglik_old, loglik_initial, settings.stop_rule);
}

// One iteration without backtracking (src/Fixed_effect.cpp:254-326): full Newton steps.
core::IterationCriteria iterate_full_steps(const arma::vec& y, const arma::mat& z, const core::ProviderLayout& layout,
                                           arma::vec& gamma, arma::vec& beta, double loglik_initial,
                                           const core::FitSettings& settings) {
  arma::vec gamma_obs = core::expand(gamma, layout);
  const arma::vec z_beta = z * beta;
  const double loglik = core::logistic_loglik(y, z_beta, gamma_obs);
  arma::vec p = 1 / (1 + arma::exp(-gamma_obs - z_beta));
  arma::vec yp = y - p;
  arma::vec pq = p % (1 - p);
  core::floor_zero_weights(pq);
  gamma += core::provider_sums(yp, layout) / core::diagonal_sums(pq, layout);
  gamma = core::clamp_effects(gamma, settings.effect_bound);
  gamma_obs = core::expand(gamma, layout);

  p = 1 / (1 + arma::exp(-gamma_obs - z_beta));
  pq = p % (1 - p);
  yp = y - p;
  const arma::vec score_beta = z.t() * yp;
  const arma::mat covariate = core::covariate_block(z, pq, 1);
  const arma::vec d_beta = arma::solve(covariate, score_beta, arma::solve_opts::fast + arma::solve_opts::likely_sympd);
  beta += d_beta;
  const double d_loglik = core::logistic_loglik(y, z * beta, gamma_obs) - loglik;
  return core::iteration_criteria(d_beta, d_loglik, loglik, loglik_initial, settings.stop_rule);
}

}  // namespace

core::FitResult fit_ban(const arma::vec& y, const arma::mat& z, const core::ProviderLayout& layout,
                        const arma::vec& gamma_start, const arma::vec& beta_start, const core::FitSettings& settings) {
  // The engine updates copies: the starting values can be views of the caller's memory.
  arma::vec gamma = gamma_start;
  arma::vec beta = beta_start;
  const double loglik_initial = core::logistic_loglik(y, z * beta, core::expand(gamma, layout));
  core::FitResult result;
  double criterion = core::kInitialCriterion;
  int iter = 0;
  while (iter < settings.max_iter) {
    if (criterion < settings.tol) {
      break;
    }
    if (settings.before_iteration) {
      settings.before_iteration();
    }
    ++iter;
    const core::IterationCriteria criteria =
        settings.backtrack ? iterate_with_backtracking(y, z, layout, gamma, beta, loglik_initial, settings)
                           : iterate_full_steps(y, z, layout, gamma, beta, loglik_initial, settings);
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
