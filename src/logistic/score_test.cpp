#include "logistic/score_test.h"

#include <cmath>

#include "core/information_blocks.h"

namespace pprof {
namespace logistic {

ScoreTestResult standard_score_test(const arma::vec& y, const arma::mat& z, const core::ProviderLayout& layout,
                                    const arma::vec& gamma, const arma::vec& beta, double gamma_null,
                                    const arma::uvec& providers, int threads) {
  // src/Fixed_effect.cpp:514-540: full-model and null quantities shared by every provider.
  const arma::vec gamma_obs = core::expand(gamma, layout);
  const arma::vec z_beta = z * beta;
  const arma::vec p = 1 / (1 + arma::exp(-gamma_obs - z_beta));
  arma::vec pq = p % (1 - p);
  core::floor_zero_weights(pq);
  const arma::vec p_null = 1 / (1 + arma::exp(-gamma_null - z_beta));
  const arma::vec pq_null = p_null % (1 - p_null);
  const arma::vec score_null = core::provider_sums(y - p_null, layout);
  const arma::vec diagonal_inverse_full = 1 / core::diagonal_sums(pq, layout);
  const arma::mat cross_full = core::cross_block(z, p, layout);
  const arma::uword m = layout.n_providers();

  const long n_requested = static_cast<long>(providers.n_elem);
  arma::vec statistic(providers.n_elem);
  statistic.fill(arma::datum::nan);
  std::vector<char> failed(providers.n_elem, 0);  // char, not bool: written concurrently
  // src/Fixed_effect.cpp:552-589. Each provider writes only its own elements, and no
  // exception leaves the loop body.
#pragma omp parallel for num_threads(threads) schedule(static)
  for (long k = 0; k < n_requested; ++k) {
    try {
      const arma::uword i = providers(k);
      const arma::uword first = layout.first(i);
      const arma::uword last = layout.last(i);
      const double info_alpha = arma::sum(pq_null.subvec(first, last));
      const arma::vec info_beta_alpha = core::cross_block_column(z, p_null, layout, i);

      arma::uvec others(m - 1);
      for (arma::uword j = 0, kept = 0; j < m; ++j) {
        if (j != i) others(kept++) = j;
      }
      const arma::vec diagonal_inverse = diagonal_inverse_full.elem(others);
      const arma::mat cross = cross_full.cols(others);

      arma::vec pq_tested = pq;
      pq_tested.subvec(first, last) = pq_null.subvec(first, last);
      const arma::mat covariate = core::covariate_block(z, pq_tested, 1);
      arma::mat schur_inverse;
      if (!arma::inv_sympd(schur_inverse, core::schur_complement(covariate, cross, diagonal_inverse))) {
        failed[k] = 1;
        continue;
      }
      const double variance = info_alpha - arma::as_scalar(info_beta_alpha.t() * schur_inverse * info_beta_alpha);
      statistic(k) = score_null(i) / std::sqrt(variance);
    } catch (...) {
      failed[k] = 1;
    }
  }

  ScoreTestResult result;
  result.statistic = statistic;
  result.failed.assign(failed.begin(), failed.end());
  return result;
}

}  // namespace logistic
}  // namespace pprof
