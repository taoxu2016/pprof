// The single Armadillo configuration of the C++ core.
//
// Every file of the core includes Armadillo through this header, never directly, so that
// all of them see the same configuration. Where a setting affects results, it reproduces
// the configuration under which the reference implementation (pprof 1.0.3, commit 5260838)
// compiled its numerical code with RcppArmadillo:
//   - BLAS and LAPACK are called directly (RcppArmadillo's ARMA_USE_BLAS, ARMA_USE_LAPACK,
//     and ARMA_DONT_USE_WRAPPER), so products, solves, and inverses go to R's BLAS and
//     LAPACK as in the reference.
//   - Armadillo's own OpenMP parallelisation is off, as the reference's
//     #define ARMA_DONT_USE_OPENMP has it (src/Fixed_effect.cpp:5). With it on, Armadillo
//     would split large sums across threads and accumulate them in another order.
//   - Index words are 32 bits, as in RcppArmadillo.
// The core never prints. Armadillo's warnings are off (ARMA_WARN_LEVEL 0); in Armadillo
// 15.6 the level gates only messages and the symmetry check that inv_sympd() runs before
// its message, so no computation changes. Armadillo's output streams discard everything,
// so the core refers neither to Rcpp's streams nor to std::cout or std::cerr.
//
// src/Makevars sets ARMA_DONT_USE_OPENMP and ARMA_WARN_LEVEL for every file of the package,
// including those that still include RcppArmadillo, because the linker keeps a single copy
// of each Armadillo template that several files instantiate (DEC-035). The definitions
// below take effect when the core is compiled on its own.
#ifndef PPROF_CORE_ARMADILLO_H
#define PPROF_CORE_ARMADILLO_H

#include <ostream>

namespace pprof {
namespace core {

// A stream that discards what is written to it: it has no buffer, so every write fails
// silently. Nothing writes to it while warnings are off.
inline std::ostream& discard_stream() {
  static std::ostream stream(nullptr);
  return stream;
}

}  // namespace core
}  // namespace pprof

#define ARMA_USE_BLAS
#define ARMA_USE_LAPACK
#define ARMA_DONT_USE_WRAPPER
#ifndef ARMA_DONT_USE_OPENMP
#define ARMA_DONT_USE_OPENMP
#endif
#define ARMA_32BIT_WORD 1
#ifndef ARMA_WARN_LEVEL
#define ARMA_WARN_LEVEL 0
#endif
#define ARMA_COUT_STREAM pprof::core::discard_stream()
#define ARMA_CERR_STREAM pprof::core::discard_stream()

#include <armadillo>

#endif  // PPROF_CORE_ARMADILLO_H
