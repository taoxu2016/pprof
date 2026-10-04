//#define ARMA_NO_DEBUG
#define STRICT_R_HEADERS // needed on Windows, not on macOS
#define ARMA_DONT_USE_OPENMP
#include <RcppArmadillo.h>
// [[Rcpp::depends(RcppArmadillo)]]
#include <cmath>
//#include <omp.h>
#include <iostream>
#include "myomp.h"
//#include <omp.h>
#include <chrono>

// [[Rcpp::plugins(cpp11)]]
// [[Rcpp::plugins(openmp)]]
using namespace Rcpp;
using namespace std;
using namespace arma;

double logist(double x) {
    return 1.0 / (1.0 + exp(-x));
}

double Exp_direct(double est, const arma::vec& Z_beta) {
    double sum = 0.0;

    #pragma omp parallel for reduction(+:sum)
    for (unsigned int i = 0; i < Z_beta.n_elem; ++i) {
        sum += logist(est + Z_beta[i]);
    }

    return sum;
}

double p_binomial(double &eta) {
  return(1/(1+exp(-eta)));
}


// [[Rcpp::export]]
arma::vec computeDirectExp(const arma::vec& est, const arma::vec& Z_beta, const int &threads) {
    omp_set_num_threads(threads);
    arma::vec results(est.n_elem);

    #pragma omp parallel for schedule(static)
    for (unsigned int i = 0; i < est.n_elem; ++i) {
        results[i] = Exp_direct(est[i], Z_beta);
    }
    return results;
}
