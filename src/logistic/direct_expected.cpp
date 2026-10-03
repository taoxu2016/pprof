#include "logistic/direct_expected.h"

#include <cmath>

namespace pprof {
namespace logistic {

arma::vec direct_expected(const arma::vec& effects, const arma::vec& linear_predictor, int threads) {
  arma::vec out(effects.n_elem);
  const long n_effects = static_cast<long>(effects.n_elem);
  const arma::uword n_obs = linear_predictor.n_elem;
  const double* lp = linear_predictor.memptr();
#pragma omp parallel for num_threads(threads) schedule(static)
  for (long i = 0; i < n_effects; ++i) {
    const double effect = effects[i];
    double sum = 0.0;
    for (arma::uword j = 0; j < n_obs; ++j) {
      const double x = effect + lp[j];
      sum += 1.0 / (1.0 + std::exp(-x));
    }
    out[i] = sum;
  }
  return out;
}

}  // namespace logistic
}  // namespace pprof
