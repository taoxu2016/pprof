#include "logistic/firth.h"

#include <algorithm>
#include <limits>
#include <stdexcept>

#include "core/clamp.h"
#include "core/constants.h"
#include "core/information_blocks.h"
#include "core/loglik.h"

namespace pprof {
namespace logistic {
namespace {

// The number of doubles that the providers' p x p terms of the Schur complement may occupy
// while they wait to be added in provider order (16 MiB). It bounds the memory of the
// buffer, not the result: the terms are added in the same order whatever the batch size.
constexpr arma::uword kSchurTermBufferDoubles = arma::uword(1) << 21;

// What the reference keeps between its passes over the providers (src/Firth.cpp:105-115),
// named after its variables:
//   p, residual, weights  per observation: p, y - p (Yp), and the floored p(1 - p) (pq);
//   diagonal_inverse      per provider: 1 / D_i (info_gamma_inv);
//   j                     columns J_i = B_i / D_i (J);
//   schur, schur_inverse  the Schur complement S and S^-1 (schur, schur_inv);
//   j2                    columns S^-1 J_i (J2);
//   score_gamma           per provider: the modified score, the sum of the modified residuals;
//   score_terms           columns J_i u_i - Z_i' r_i, the provider's term of the covariate
//                         score H (local_H accumulates them in the reference).
struct State {
  State(arma::uword n_obs, arma::uword n_providers, arma::uword n_covariates)
      : p(n_obs),
        residual(n_obs),
        weights(n_obs),
        diagonal_inverse(n_providers),
        j(n_covariates, n_providers),
        schur(n_covariates, n_covariates),
        schur_inverse(n_covariates, n_covariates),
        j2(n_covariates, n_providers),
        score_gamma(n_providers),
        score_terms(n_covariates, n_providers) {}
  arma::vec p;
  arma::vec residual;
  arma::vec weights;
  arma::vec diagonal_inverse;
  arma::mat j;
  arma::mat schur;
  arma::mat schur_inverse;
  arma::mat j2;
  arma::vec score_gamma;
  arma::mat score_terms;
};

// The data of a fit, as the passes over the providers read them.
struct Data {
  const arma::vec& y;
  const arma::mat& z;
  const core::ProviderLayout& layout;
};

// Provider i's part of the information at (gamma, beta) (src/Firth.cpp:155-183, :299-326):
// its rows of p, y - p, and the weights floored at 1e-10 (K-31), its entry of 1 / D, its
// column of J, and its term C_i - J_i B_i' of the Schur complement, written to `term`. The
// reference copies the provider's rows before computing with them, and so does this
// function, so that every product has the reference's operands.
void provider_information(const Data& data, const arma::vec& gamma, const arma::vec& beta, arma::uword i,
                          State& state, arma::mat& term) {
  const arma::uword first = data.layout.first(i);
  const arma::uword last = data.layout.last(i);
  const arma::mat z_rows = data.z.rows(first, last);
  const arma::vec y_rows = data.y.subvec(first, last);
  const arma::vec gamma_obs(last - first + 1, arma::fill::value(gamma(i)));
  const arma::vec z_beta = z_rows * beta;
  const arma::vec p = 1.0 / (1.0 + arma::exp(-gamma_obs - z_beta));
  arma::vec weights = p % (1.0 - p);
  core::floor_zero_weights(weights, core::kFirthWeightFloor);

  state.p.subvec(first, last) = p;
  state.residual.subvec(first, last) = y_rows - p;
  state.weights.subvec(first, last) = weights;

  const core::ProviderBlocks blocks = core::provider_blocks(z_rows, weights);
  const double diagonal_inverse = 1 / blocks.diagonal;
  state.diagonal_inverse(i) = diagonal_inverse;
  state.j.col(i) = blocks.cross * diagonal_inverse;
  term = blocks.covariate - state.j.col(i) * blocks.cross.t();
}

// The information at (gamma, beta) for every provider and the Schur complement
// (src/Firth.cpp:140-188, :284-331). The providers' parts are computed in parallel, in
// batches, and their terms are added in provider order, as the reference adds them with one
// thread: S = 0 + (((0 + T_1) + T_2) + ... + T_m).
void compute_information(const Data& data, const arma::vec& gamma, const arma::vec& beta, int threads,
                         State& state) {
  const arma::uword m = data.layout.n_providers();
  const arma::uword n_covariates = data.z.n_cols;
  const arma::uword by_memory = kSchurTermBufferDoubles / std::max<arma::uword>(n_covariates * n_covariates, 1);
  const arma::uword batch =
      std::max<arma::uword>(1, std::min<arma::uword>(m, std::max<arma::uword>(by_memory, threads)));
  std::vector<arma::mat> terms(batch);
  std::vector<char> failed(batch, 0);  // char, not bool: written concurrently
  arma::mat local_schur(n_covariates, n_covariates, arma::fill::zeros);
  for (arma::uword start = 0; start < m; start += batch) {
    const long count = static_cast<long>(std::min<arma::uword>(batch, m - start));
    // Each provider writes only its own rows, entries, column, and term; no exception
    // leaves the loop body.
#pragma omp parallel for num_threads(threads) schedule(dynamic)
    for (long k = 0; k < count; ++k) {
      try {
        provider_information(data, gamma, beta, start + static_cast<arma::uword>(k), state, terms[k]);
      } catch (...) {
        failed[k] = 1;
      }
    }
    for (long k = 0; k < count; ++k) {
      if (failed[k]) {
        throw std::runtime_error("the information of a provider could not be computed");
      }
      local_schur += terms[k];
    }
  }
  state.schur.zeros();
  state.schur += local_schur;
}

// Provider i's part of the Firth step (src/Firth.cpp:220-244): J2_i = S^-1 J_i; the hat value
// of each of its observations, h = w (1/D_i + J_i' J2_i - 2 z' J2_i + z' S^-1 z), the
// diagonal of the hat matrix from the block inverse of the information; the modified
// residuals y - p + h (1/2 - p) (K-32); the provider's modified score, their sum; and its
// term J_i u_i - Z_i' r_i of the covariate score.
void provider_step(const Data& data, arma::uword i, State& state) {
  const arma::uword first = data.layout.first(i);
  const arma::uword last = data.layout.last(i);
  state.j2.col(i) = state.schur_inverse * state.j.col(i);

  const arma::vec residual = state.residual.subvec(first, last);
  const arma::mat z_rows = data.z.rows(first, last);
  const arma::vec p = state.p.subvec(first, last);
  const arma::vec weights = state.weights.subvec(first, last);

  const double diagonal_term = state.diagonal_inverse(i) + arma::as_scalar(state.j.col(i).t() * state.j2.col(i));
  const arma::uword n_rows = last - first + 1;
  const arma::vec c1(n_rows, arma::fill::value(diagonal_term));
  const arma::vec c2 = -z_rows * state.j2.col(i);
  arma::vec c3(n_rows);
  for (arma::uword k = 0; k < n_rows; ++k) {
    c3(k) = arma::as_scalar(z_rows.row(k) * state.schur_inverse * z_rows.row(k).t());
  }
  const arma::vec modified = residual + weights % (c1 + c2 + c2 + c3) % (0.5 - p);

  state.score_gamma(i) = arma::sum(modified);
  state.score_terms.col(i) = state.j.col(i) * state.score_gamma(i) - z_rows.t() * modified;
}

// The covariate score term of the Firth step (src/Firth.cpp:203-251): the providers' parts in
// parallel, then H = 0 + (((0 + H_1) + H_2) + ... + H_m) in provider order, as the reference
// adds them with one thread.
arma::vec compute_step(const Data& data, int threads, State& state) {
  const arma::uword m = data.layout.n_providers();
  const long n_providers = static_cast<long>(m);
  std::vector<char> failed(m, 0);  // char, not bool: written concurrently
  // Each provider writes only its own column, entry, and term; no exception leaves the
  // loop body.
#pragma omp parallel for num_threads(threads) schedule(dynamic)
  for (long i = 0; i < n_providers; ++i) {
    try {
      provider_step(data, static_cast<arma::uword>(i), state);
    } catch (...) {
      failed[i] = 1;
    }
  }
  arma::vec local_h(data.z.n_cols, arma::fill::zeros);
  for (arma::uword i = 0; i < m; ++i) {
    if (failed[i]) {
      throw std::runtime_error("the Firth step of a provider could not be computed");
    }
    local_h += state.score_terms.col(i);
  }
  arma::vec h(data.z.n_cols, arma::fill::zeros);
  h += local_h;
  return h;
}

// S^-1, which the reference computes with inv_sympd() after every information pass
// (src/Firth.cpp:194, :337). Where the reference's inv_sympd() threw inside its parallel
// region and terminated R (D-42), this throws outside any parallel region.
void invert_schur(State& state) {
  if (!arma::inv_sympd(state.schur_inverse, state.schur)) {
    throw std::runtime_error(
        "the Schur complement of the information matrix is singular or not positive definite");
  }
}

// The penalized log-likelihood l + log det(I) / 2 at (gamma, beta), from the information
// computed there (src/Firth.cpp:196-197, :340-342). The reference passes 1 / (1 / D_i), not
// D_i, to its log-determinant, which can differ from D_i in the last bit; so does this.
double penalized_loglik(const Data& data, const arma::vec& gamma, const arma::vec& beta, const State& state) {
  const double loglik = core::logistic_loglik(data.y, data.z * beta, core::expand(gamma, data.layout));
  return loglik + 0.5 * information_log_determinant(1.0 / state.diagonal_inverse, state.schur);
}

}  // namespace

double information_log_determinant(const arma::vec& diagonal, const arma::mat& schur) {
  const double log_det_diagonal =
      arma::sum(arma::log(arma::clamp(diagonal, core::kFirthDiagonalFloor, std::numeric_limits<double>::max())));
  const arma::mat symmetric = 0.5 * (schur + schur.t());
  arma::mat factor;
  if (!arma::chol(factor, symmetric)) {
    if (!arma::chol(factor, symmetric + core::kFirthCholeskyRidge * arma::eye(symmetric.n_rows, symmetric.n_cols))) {
      throw std::runtime_error("the Cholesky factorization of the Schur complement failed");
    }
  }
  const double log_det_schur = 2.0 * arma::sum(arma::log(factor.diag()));
  return log_det_diagonal + log_det_schur;
}

FirthResult fit_firth(const arma::vec& y, const arma::mat& z, const core::ProviderLayout& layout,
                      const arma::vec& gamma_start, const arma::vec& beta_start, const FirthSettings& settings) {
  const Data data{y, z, layout};
  // The engine updates copies: the starting values can be views of the caller's memory.
  arma::vec gamma = gamma_start;
  arma::vec beta = beta_start;
  State state(layout.n_obs(), layout.n_providers(), z.n_cols);
  FirthResult result;
  result.penalized_loglik_initial = arma::datum::nan;
  result.penalized_loglik = arma::datum::nan;
  double criterion = core::kFirthInitialCriterion;
  int iter = 0;
  bool information_current = false;
  while (iter < settings.max_iter && criterion > settings.tol) {
    if (settings.before_iteration) {
      settings.before_iteration();
    }
    // The information at the starting values (src/Firth.cpp:139-201); later iterations use
    // the information computed at the end of the previous one.
    if (!information_current) {
      compute_information(data, gamma, beta, settings.threads, state);
      invert_schur(state);
      result.penalized_loglik_initial = penalized_loglik(data, gamma, beta, state);
      information_current = true;
    }
    // The step (src/Firth.cpp:203-281): beta first, then each provider effect from the same
    // covariate score H, then the clamp.
    const arma::vec h = compute_step(data, settings.threads, state);
    const arma::vec d_beta = -state.schur_inverse * h;
    beta += d_beta;
    ++iter;
    for (arma::uword i = 0; i < layout.n_providers(); ++i) {
      gamma(i) += state.diagonal_inverse(i) * state.score_gamma(i) + arma::as_scalar(state.j2.col(i).t() * h);
    }
    gamma = core::clamp_effects(gamma, settings.effect_bound);
    // The information at the new estimates and the criterion (src/Firth.cpp:283-358).
    compute_information(data, gamma, beta, settings.threads, state);
    invert_schur(state);
    const double penalized = penalized_loglik(data, gamma, beta, state);
    criterion = arma::norm(d_beta, "inf");
    result.history.push_back({criterion, penalized});
    result.penalized_loglik = penalized;
  }
  result.gamma = gamma;
  result.beta = beta;
  result.iterations = iter;
  result.criterion = criterion;
  result.converged = criterion <= settings.tol;
  return result;
}

}  // namespace logistic
}  // namespace pprof
