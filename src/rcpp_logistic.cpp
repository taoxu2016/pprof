// Rcpp adapters for the logistic fixed-effect core (src/core, src/logistic).
//
// Each adapter checks dimensions, wraps R's vectors and matrices in Armadillo objects
// without copying them (the core takes them as const references and never writes to them),
// calls the core, and converts the result into an R list. The core neither sees R objects
// nor calls the R API. Exceptions from the core reach R as errors through the code that
// Rcpp::compileAttributes() generates; the R callers turn them into classed conditions.
// The adapters are internal: R code calls them only from the model and profiling layers.
#include <Rcpp.h>

#include <stdexcept>
#include <string>
#include <vector>

#include "core/armadillo.h"
#include "core/provider_layout.h"
#include "core/types.h"
#include "logistic/ban.h"
#include "logistic/direct_expected.h"
#include "logistic/score_test.h"
#include "logistic/serbin.h"
#include "logistic/variance.h"

namespace {

using pprof::core::FitResult;
using pprof::core::FitSettings;
using pprof::core::ProviderLayout;
using pprof::core::StopRule;

arma::vec view(Rcpp::NumericVector x) {
  return arma::vec(x.begin(), static_cast<arma::uword>(x.size()), false, true);
}

arma::mat view(Rcpp::NumericMatrix x) {
  return arma::mat(x.begin(), static_cast<arma::uword>(x.nrow()), static_cast<arma::uword>(x.ncol()), false,
                   true);
}

void require(bool condition, const char* message) {
  if (!condition) {
    throw std::invalid_argument(message);
  }
}

ProviderLayout layout_of(Rcpp::IntegerVector provider_sizes) {
  return ProviderLayout(std::vector<int>(provider_sizes.begin(), provider_sizes.end()));
}

StopRule stop_rule_of(const std::string& rule) {
  if (rule == "any") return StopRule::kAny;
  if (rule == "all") return StopRule::kAll;
  if (rule == "coefficients") return StopRule::kCoefficients;
  if (rule == "relative_loglik") return StopRule::kRelativeLoglik;
  if (rule == "relative_gain") return StopRule::kRelativeGain;
  throw std::invalid_argument("unknown stopping rule: " + rule);
}

void check_estimates(const ProviderLayout& layout, Rcpp::NumericMatrix design, Rcpp::NumericVector gamma,
                     Rcpp::NumericVector beta) {
  require(static_cast<arma::uword>(design.nrow()) == layout.n_obs(),
          "the design matrix needs one row per observation of the provider sizes");
  require(static_cast<arma::uword>(gamma.size()) == layout.n_providers(), "gamma needs one value per provider");
  require(beta.size() == design.ncol(), "beta needs one value per column of the design matrix");
}

void check_model(const ProviderLayout& layout, Rcpp::NumericVector response, Rcpp::NumericMatrix design,
                 Rcpp::NumericVector gamma, Rcpp::NumericVector beta) {
  check_estimates(layout, design, gamma, beta);
  require(response.size() == design.nrow(), "the response needs one value per row of the design matrix");
}

FitSettings settings_of(int max_iter, double tol, double effect_bound, bool backtrack, const std::string& stop_rule,
                        int threads) {
  require(threads >= 1, "threads must be at least 1");
  FitSettings settings;
  settings.max_iter = max_iter;
  settings.tol = tol;
  settings.effect_bound = effect_bound;
  settings.backtrack = backtrack;
  settings.stop_rule = stop_rule_of(stop_rule);
  settings.threads = threads;
  settings.before_iteration = [] { Rcpp::checkUserInterrupt(); };
  return settings;
}

Rcpp::List fit_result_list(const FitResult& result) {
  const int n = static_cast<int>(result.history.size());
  Rcpp::NumericMatrix history(n, 4);
  for (int k = 0; k < n; ++k) {
    history(k, 0) = result.history[k].coefficients;
    history(k, 1) = result.history[k].relative_loglik;
    history(k, 2) = result.history[k].relative_gain;
    history(k, 3) = result.history[k].rule;
  }
  history.attr("dimnames") = Rcpp::List::create(
      R_NilValue, Rcpp::CharacterVector::create("coefficients", "relative_loglik", "relative_gain", "rule"));
  return Rcpp::List::create(Rcpp::Named("gamma") = Rcpp::NumericVector(result.gamma.begin(), result.gamma.end()),
                            Rcpp::Named("beta") = Rcpp::NumericVector(result.beta.begin(), result.beta.end()),
                            Rcpp::Named("iterations") = result.iterations,
                            Rcpp::Named("converged") = result.converged, Rcpp::Named("history") = history);
}

}  // namespace

// SerBIN (src/logistic/serbin.h) from the starting values gamma and beta. Observations are
// sorted by provider; provider_sizes gives each provider's number of observations.
// [[Rcpp::export]]
Rcpp::List cpp_logistic_fe_serbin(Rcpp::NumericVector response, Rcpp::NumericMatrix design,
                                  Rcpp::IntegerVector provider_sizes, Rcpp::NumericVector gamma,
                                  Rcpp::NumericVector beta, int max_iter, double tol, double effect_bound,
                                  bool backtrack, std::string stop_rule, int threads) {
  const ProviderLayout layout = layout_of(provider_sizes);
  check_model(layout, response, design, gamma, beta);
  const FitSettings settings = settings_of(max_iter, tol, effect_bound, backtrack, stop_rule, threads);
  return fit_result_list(
      pprof::logistic::fit_serbin(view(response), view(design), layout, view(gamma), view(beta), settings));
}

// BAN (src/logistic/ban.h), with the same arguments as cpp_logistic_fe_serbin().
// [[Rcpp::export]]
Rcpp::List cpp_logistic_fe_ban(Rcpp::NumericVector response, Rcpp::NumericMatrix design,
                               Rcpp::IntegerVector provider_sizes, Rcpp::NumericVector gamma,
                               Rcpp::NumericVector beta, int max_iter, double tol, double effect_bound,
                               bool backtrack, std::string stop_rule, int threads) {
  const ProviderLayout layout = layout_of(provider_sizes);
  check_model(layout, response, design, gamma, beta);
  const FitSettings settings = settings_of(max_iter, tol, effect_bound, backtrack, stop_rule, threads);
  return fit_result_list(
      pprof::logistic::fit_ban(view(response), view(design), layout, view(gamma), view(beta), settings));
}

// Variances of the estimates (src/logistic/variance.h): the covariance matrix of beta and
// the variance of each provider effect.
// [[Rcpp::export]]
Rcpp::List cpp_logistic_variance(Rcpp::NumericMatrix design, Rcpp::IntegerVector provider_sizes,
                                 Rcpp::NumericVector gamma, Rcpp::NumericVector beta) {
  const ProviderLayout layout = layout_of(provider_sizes);
  check_estimates(layout, design, gamma, beta);
  const pprof::logistic::Variances variances =
      pprof::logistic::logistic_fe_variance(view(design), layout, view(gamma), view(beta));
  return Rcpp::List::create(
      Rcpp::Named("beta") = Rcpp::NumericMatrix(static_cast<int>(variances.beta.n_rows),
                                                static_cast<int>(variances.beta.n_cols), variances.beta.begin()),
      Rcpp::Named("gamma") = Rcpp::NumericVector(variances.gamma.begin(), variances.gamma.end()));
}

// The standard score test (src/logistic/score_test.h) for the providers at the 1-based
// positions `providers`.
// [[Rcpp::export]]
Rcpp::List cpp_logistic_score_standard(Rcpp::NumericVector response, Rcpp::NumericMatrix design,
                                       Rcpp::IntegerVector provider_sizes, Rcpp::NumericVector gamma,
                                       Rcpp::NumericVector beta, double gamma_null,
                                       Rcpp::IntegerVector providers, int threads) {
  const ProviderLayout layout = layout_of(provider_sizes);
  check_model(layout, response, design, gamma, beta);
  require(threads >= 1, "threads must be at least 1");
  arma::uvec positions(static_cast<arma::uword>(providers.size()));
  for (R_xlen_t k = 0; k < providers.size(); ++k) {
    require(providers[k] >= 1 && static_cast<arma::uword>(providers[k]) <= layout.n_providers(),
            "provider positions must be between 1 and the number of providers");
    positions(static_cast<arma::uword>(k)) = static_cast<arma::uword>(providers[k] - 1);
  }
  const pprof::logistic::ScoreTestResult result = pprof::logistic::standard_score_test(
      view(response), view(design), layout, view(gamma), view(beta), gamma_null, positions, threads);
  Rcpp::LogicalVector failed(result.failed.size());
  for (std::size_t k = 0; k < result.failed.size(); ++k) {
    failed[k] = result.failed[k];
  }
  return Rcpp::List::create(
      Rcpp::Named("statistic") = Rcpp::NumericVector(result.statistic.begin(), result.statistic.end()),
      Rcpp::Named("failed") = failed);
}

// Expected outcomes for direct standardization (src/logistic/direct_expected.h): one value
// per effect, summed over every observation's linear predictor.
// [[Rcpp::export]]
Rcpp::NumericVector cpp_logistic_direct_expected(Rcpp::NumericVector effects, Rcpp::NumericVector linear_predictor,
                                                 int threads) {
  require(threads >= 1, "threads must be at least 1");
  const arma::vec expected = pprof::logistic::direct_expected(view(effects), view(linear_predictor), threads);
  return Rcpp::NumericVector(expected.begin(), expected.end());
}
