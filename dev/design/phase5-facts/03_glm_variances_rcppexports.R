# Phase 5 planning, second pass: glm() variances at the final estimates, and the
# RcppExports includes once src/Fixed_effect.cpp is gone (dry run on a scratch copy).
# Run from the repository root: Rscript <this file> <output file> <scratch directory>; the
# copy of the package goes to <scratch directory>/pkgcopy.
args <- commandArgs(trailingOnly = TRUE)
out_file <- args[1]
scratch <- args[2]
suppressMessages(devtools::load_all(quiet = TRUE))
lines <- character()
say <- function(...) lines <<- c(lines, paste0(...))
rel <- function(a, b) max(abs(a - b) / pmax(abs(b), 1e-300))

data(ExampleDataBinary)
bin <- data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID, ExampleDataBinary$Z)
f <- y ~ z1 + z2 + z3 + z4 + z5
events <- tapply(bin$y, bin$hospital, sum)
sizes <- tapply(bin$y, bin$hospital, length)
keep <- as.numeric(names(events)[events > 0 & events < sizes])
d <- bin[bin$hospital %in% keep, ]
d$hospital <- factor(d$hospital)
fe <- fit_logistic_fe(f, d, "hospital", tol = 1e-12, stop_rule = "all", min_provider_size = 1)
g <- stats::glm(y ~ 0 + hospital + z1 + z2 + z3 + z4 + z5, family = stats::binomial(), data = d,
                control = stats::glm.control(epsilon = 1e-14, maxit = 100))
# One more iteration started from glm's estimates: its weights, and so its covariance, are
# evaluated at those estimates.
g2 <- stats::glm(y ~ 0 + hospital + z1 + z2 + z3 + z4 + z5, family = stats::binomial(), data = d,
                 start = stats::coef(g), control = stats::glm.control(epsilon = 1e-14, maxit = 1))
m <- nlevels(d$hospital)
for (h in list(list(g, "glm"), list(g2, "glm restarted at its estimates"))) {
  v <- diag(stats::vcov(h[[1]]))
  say(sprintf("%s: Var(beta) rel %.2g; Var(gamma) rel %.2g; estimates beta rel %.2g gamma abs %.2g", h[[2]],
              rel(diag(fe$vcov), unname(v[paste0("z", 1:5)])), rel(unname(fe$provider_effect_variance), unname(v[seq_len(m)])),
              rel(unname(fe$coefficients), unname(stats::coef(h[[1]])[paste0("z", 1:5)])),
              max(abs(unname(fe$provider_effects) - unname(stats::coef(h[[1]])[seq_len(m)])))))
}

# compileAttributes() on a copy of the package without src/Fixed_effect.cpp.
copy <- file.path(scratch, "pkgcopy")
unlink(copy, recursive = TRUE)
dir.create(copy)
file.copy(c("DESCRIPTION", "NAMESPACE"), copy)
dir.create(file.path(copy, "R"))
dir.create(file.path(copy, "src"))
file.copy("R/RcppExports.R", file.path(copy, "R"))
cpp <- setdiff(list.files("src", pattern = "\\.(cpp|h)$"), c("Fixed_effect.cpp", "RcppExports.cpp", "header.cpp",
                                                                 "header.h", "myomp.h"))
file.copy(file.path("src", cpp), file.path(copy, "src"))
Rcpp::compileAttributes(copy)
generated <- readLines(file.path(copy, "src", "RcppExports.cpp"))
say(sprintf("RcppExports.cpp without Fixed_effect.cpp: includes %s",
            paste(grep("^#include", generated, value = TRUE), collapse = "; ")))
say(sprintf("  exports %s", paste(sub("^// ", "", grep("^// cpp_", generated, value = TRUE)), collapse = ", ")))
say(sprintf("  mentions RcppArmadillo: %s", any(grepl("RcppArmadillo", generated))))
writeLines(lines, out_file)
