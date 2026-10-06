// Blocks of the logistic fixed-effect information matrix (DEC-007).
//
// With one effect per provider (gamma) and p covariate coefficients (beta), the information
// matrix has three blocks: a diagonal provider block D (one value per provider), a cross
// block B (p x m), and a covariate block C (p x p). Fitting, the variances, and the
// standard score test all work with these blocks and with the Schur complement
// S = C - B diag(1 / D) B'.
//
// The routines take the weights or probabilities from the caller, because the reference
// uses different weights in different places (K-13, K-20, K-66), and each caller passes
// exactly what the reference used there. Where the reference evaluates the same quantity
// with different operations, both forms are kept as separate routines, so that every
// caller reproduces the reference's rounding: the diagonal as a sum of weights or as
// dot(p, 1 - p), and the Schur complement in two product orders.
#ifndef PPROF_CORE_INFORMATION_BLOCKS_H
#define PPROF_CORE_INFORMATION_BLOCKS_H

#include "core/armadillo.h"
#include "core/provider_layout.h"

namespace pprof {
namespace core {

// K-13: replaces weights that are exactly 0 by kFitWeightFloor.
void floor_zero_weights(arma::vec& weights);

// Replaces weights that are exactly 0 by `floor` (K-31: kFirthWeightFloor in the Firth
// routine).
void floor_zero_weights(arma::vec& weights, double floor);

// The blocks of one provider, from a copy of its rows of Z (z_rows) and of their weights,
// as the reference's Firth routine forms them (src/Firth.cpp:174-182): the diagonal entry
// D_i = sum(weights), the cross-block column B_i = the column sums of z_rows with each row
// multiplied by its weight, and the provider's part of the covariate block,
// C_i = z_rows' (z_rows with each row multiplied by its weight). The Firth routine adds the
// terms C_i - J_i B_i', with J_i = B_i (1 / D_i), in provider order to form the Schur
// complement (src/Firth.cpp:180-183).
struct ProviderBlocks {
  double diagonal;
  arma::vec cross;
  arma::mat covariate;
};
ProviderBlocks provider_blocks(const arma::mat& z_rows, const arma::vec& weights);

// D as the sum of the weights over each provider's rows (SerBIN, BAN, and the standard
// score test; src/Fixed_effect.cpp:376, :161, :535).
arma::vec diagonal_sums(const arma::vec& weights, const ProviderLayout& layout);

// D as dot(p, 1 - p) over each provider's rows (the variances; src/Fixed_effect.cpp:654).
arma::vec diagonal_dots(const arma::vec& p, const ProviderLayout& layout);

// Column i of B: the column sums of provider i's rows of Z, each row weighted by p(1 - p),
// computed from p without a floor in the reference's operation order
// (src/Fixed_effect.cpp:377-378).
arma::vec cross_block_column(const arma::mat& z, const arma::vec& p, const ProviderLayout& layout,
                             arma::uword provider);

// B, one column per provider.
arma::mat cross_block(const arma::mat& z, const arma::vec& p, const ProviderLayout& layout);

// C = Z' diag(weights) Z. With threads == 1 this is the product Z.t() * (Z.each_col() %
// weights); with threads > 1 it is the reference's element-wise dot products over the upper
// triangle, computed in parallel (src/Fixed_effect.cpp:72-85, :383-388). The two differ by
// rounding only, and each is deterministic (D-20).
arma::mat covariate_block(const arma::mat& z, const arma::vec& weights, int threads);

// S = C - B diag(diagonal_inverse) B' in the operation order of the variances and the
// standard score test: (B.each_row() % diagonal_inverse.t()) * B.t()
// (src/Fixed_effect.cpp:660, :583-584).
arma::mat schur_complement(const arma::mat& covariate, const arma::mat& cross, const arma::vec& diagonal_inverse);

// SerBIN's scaled cross block A = (B.each_row() % diagonal_inverse.t()).t(), which its
// Newton step also uses, and the Schur complement in SerBIN's order, C - A.t() * B.t()
// (src/Fixed_effect.cpp:389, :395).
arma::mat scaled_cross_transposed(const arma::mat& cross, const arma::vec& diagonal_inverse);
arma::mat schur_complement_serbin(const arma::mat& covariate, const arma::mat& cross,
                                  const arma::mat& scaled_transposed);

}  // namespace core
}  // namespace pprof

#endif  // PPROF_CORE_INFORMATION_BLOCKS_H
