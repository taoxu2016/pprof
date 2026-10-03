//#define ARMA_NO_DEBUG
#define STRICT_R_HEADERS // needed on Windows, not on macOS
#include <RcppParallel.h>
// [[Rcpp::depends(RcppParallel)]]
#define ARMA_DONT_USE_OPENMP
#include <RcppArmadillo.h>
// [[Rcpp::depends(RcppArmadillo)]]
#include <cmath>
//#include <omp.h>
#include <iostream>
#include "header.h"
#include "myomp.h"
//#include <omp.h>
#include <chrono>

// [[Rcpp::plugins(cpp11)]]
// [[Rcpp::plugins(openmp)]]
using namespace RcppParallel;
using namespace Rcpp;
using namespace std;
using namespace arma;

//` @importFrom RcppParallel RcppParallelLibs

arma::vec rep(arma::vec &x, arma::vec &each) {
  arma::vec x_rep(sum(each));
  int ind = 0, m = x.n_elem;
  for (int i = 0; i < m; i++) {
    x_rep.subvec(ind,ind+each(i)-1) = x(i) * ones(each(i));
    ind += each(i);
  }
  return x_rep;
}

double Loglkd(const arma::vec &Y, const arma::vec &Z_beta, const arma::vec &gamma_obs) {
  return sum((gamma_obs+Z_beta)%Y-log(1+exp(gamma_obs+Z_beta)));
}

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

// [[Rcpp::export]]
List compute_profilkd_linear(arma::vec& Y, arma::mat& Z, arma::vec& ID, arma::vec& n_prov) {
  if (Y.n_elem != Z.n_rows) {
    stop("Y and Z must have the same number of rows.");
  }
  if (Y.n_elem != ID.n_elem) {
    stop("Y and ID must have the same number of elements.");
  }

  int m = n_prov.n_elem;
  int n_covariates = Z.n_cols;

  arma::mat sum_first_term = arma::zeros(n_covariates, n_covariates);
  arma::vec sum_second_term = arma::zeros(n_covariates);

  for (int j = 0; j < m; ++j) {
    arma::uvec indices = arma::find(ID == j + 1);
    arma::mat temp_X = Z.rows(indices);
    arma::vec temp_Y = Y.rows(indices);

    int n = temp_Y.n_rows;
    arma::mat Qn = arma::eye(n, n) - (1.0 / n) * arma::ones(n, n);

    sum_first_term += temp_X.t() * Qn * temp_X;
    sum_second_term += temp_X.t() * Qn * temp_Y;
  }

  arma::vec beta = arma::solve(sum_first_term, sum_second_term);

  arma::vec gamma(m);

  for (int j = 0; j < m; ++j) {
    arma::uvec indices = arma::find(ID == j + 1);
    arma::mat temp_X = Z.rows(indices);
    arma::vec temp_Y = Y.rows(indices);

    double temp_y_bar = arma::mean(temp_Y);
    arma::vec temp_x_bar = arma::mean(temp_X, 0).t();

    gamma[j] = temp_y_bar - arma::as_scalar(temp_x_bar.t() * beta);
  }

  List ret = List::create(_["gamma"]=gamma, _["beta"]=beta);
  return ret;
}


// [[Rcpp::export]]
List logis_fe_var(arma::vec &Y, arma::mat &Z, arma::vec &n_prov, arma::vec &gamma, arma::vec &beta) {
  arma::vec gamma_obs = rep(gamma, n_prov);
  int m = n_prov.n_elem;
  arma::vec p = 1 / (1 + exp(-gamma_obs-Z*beta));
  p = clamp(p, 1e-10, 1-1e-10);
  int ind = 0;
  arma::vec info_gamma_inv(m);
  arma::mat info_betagamma(Z.n_cols,m);
  for (int i = 0; i < m; i++) {
    info_gamma_inv(i) = 1 / dot(p.subvec(ind,ind+n_prov(i)-1),1-p.subvec(ind,ind+n_prov(i)-1));
    info_betagamma.col(i) =
      sum(Z.rows(ind,ind+n_prov(i)-1).each_col()%(p.subvec(ind,ind+n_prov(i)-1)%(1-p.subvec(ind,ind+n_prov(i)-1)))).t();
    ind += n_prov(i);
  }
  arma::mat info_beta = Z.t()*(Z.each_col()%(p%(1-p)));
  arma::mat info_beta_inv = inv_sympd(info_beta-(info_betagamma.each_row()%info_gamma_inv.t())*info_betagamma.t());
  arma::vec se_beta = sqrt(info_beta_inv.diag());

  arma::vec se_gamma(m);
  arma::vec var_gamma(m);
  for (int i = 0; i < m; i++) {
    arma::vec mat_tmp = info_gamma_inv(i) * info_betagamma.col(i); // J_1^T
    var_gamma(i) = info_gamma_inv(i) + as_scalar(mat_tmp.t() * info_beta_inv * mat_tmp);
    se_gamma(i) = sqrt(info_gamma_inv(i) + as_scalar(mat_tmp.t() * info_beta_inv * mat_tmp)); // sqrt(I_11^-1 + J_1^T * S^-1 * J_1)
  }

  List ret;
  ret["var.beta"] = info_beta_inv;
  ret["se.beta"] = 1*se_beta;
  ret["var.gamma"] = var_gamma;
  ret["se.gamma"] = se_gamma;
  return ret;
}
