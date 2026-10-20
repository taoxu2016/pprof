# Logistic extensions brief, Appendix A: pprofR 0.2.0's cluster-level inference against
# independent references, for binary and binomial outcomes, on data whose clusters of rows share a
# random intercept (facts_simulate()):
#   (a) the cluster-robust (sandwich) variance of the coefficients against sandwich::vcovCL() of
#       the glm() fit with provider indicators, without small-sample adjustment (type "HC0",
#       cadjust = FALSE), at tight convergence;
#   (b) the robust standard errors of the provider effects against the formula of pprofR's help,
#       sqrt(V_i) / I_i, written here in plain R, and against the full sandwich's variances of the
#       provider effects from vcovCL(), which also carry the coefficients' uncertainty;
#   (c) the robust score test and the "stabilized" Wald and score tests against plain-R versions of
#       the formulas in pprofR's help (one within-cluster correlation matrix pooled over all clusters
#       by the position of a row in its cluster);
#   (d) what the tests depend on: the order of the rows within a cluster, a cluster label shared by
#       two providers, and the screening of providers by their number of clusters.
# Run from the repository root after 01: Rscript dev/design/logistic-facts/04_cluster_inference.R <output file>
source("dev/design/logistic-facts/facts_data.R")
args <- commandArgs(trailingOnly = TRUE)
facts_use_libraries()
suppressPackageStartupMessages({
  library(pprofR)
  library(sandwich)
})
out <- c("# 04: cluster-level inference against sandwich and plain-R formulas", "",
         sprintf("pprofR %s, sandwich %s, %s.", utils::packageVersion("pprofR"), utils::packageVersion("sandwich"),
                 R.version.string), "")

# Plain-R versions of the clustered variances of pprofR's help, from residuals r = y - n p and
# variances v = n p (1 - p) at probabilities p, with the rows of each cluster in data order.
clustered_plain <- function(d, p) {
  r <- d$y - d$N * p
  v <- d$N * p * (1 - p)
  key <- paste(d$provider, d$cluster)
  clusters <- unique(key)
  provider_of <- d$provider[match(clusters, key)]
  sums <- vapply(split(r, factor(key, levels = clusters)), sum, numeric(1))
  robust <- tapply(sums^2, provider_of, sum)
  e <- ifelse(v > 0, r / sqrt(v), 0)
  rows <- split(seq_along(r), factor(key, levels = clusters))
  dim <- max(lengths(rows))
  pooled <- matrix(0, dim, dim)
  count <- numeric(dim)
  for (k in rows) {
    s <- length(k)
    pooled[1:s, 1:s] <- pooled[1:s, 1:s] + outer(e[k], e[k])
    count[1:s] <- count[1:s] + 1
  }
  pooled <- pooled / outer(seq_len(dim), seq_len(dim), function(a, b) count[pmax(a, b)])
  stable <- vapply(rows, function(k) {
    s <- length(k)
    sum(outer(sqrt(v[k]), sqrt(v[k])) * pooled[1:s, 1:s])
  }, numeric(1))
  list(score = tapply(r, d$provider, sum), robust = robust, stable = tapply(stable, provider_of, sum),
       information = tapply(v, d$provider, sum))
}

for (binomial in c(FALSE, TRUE)) {
  d <- facts_simulate(m = 30, clusters = c(8, 30), trials = if (binomial) c(5, 20), seed = 5)
  label <- if (binomial) "binomial (5 to 20 trials a row)" else "binary"
  fit <- pprofR::logis_fe(facts_pprofr_prep(d, binomial = binomial, cutoff = 1), tol = 1e-13, stop = "beta")
  g <- stats::glm(cbind(y, n - y) ~ 0 + factor(provider) + x1 + x2 + x3, family = stats::binomial(), data = d,
                  control = stats::glm.control(epsilon = 1e-15, maxit = 100))
  sandwich_vcov <- sandwich::vcovCL(g, cluster = ~ cluster, type = "HC0", cadjust = FALSE)
  effects <- grep("^factor", names(stats::coef(g)))
  covariates <- c("x1", "x2", "x3")
  out <- c(out, facts_header(sprintf("## %s: %d rows, %d clusters, %d providers", label, nrow(d), length(unique(d$cluster)),
                                     length(unique(d$provider)))))

  # (a) the coefficients.
  robust_beta <- pprofR::summary_fe_covar(fit, test = "robust_wald")
  model_beta <- pprofR::summary_fe_covar(fit, test = "wald")
  out <- c(out, facts_row("(a) coefficients against glm()", fit$beta, stats::coef(g)[covariates]),
           facts_row("(a) robust standard errors of the coefficients against vcovCL()", robust_beta$se.beta,
                     sqrt(diag(sandwich_vcov)[covariates])),
           sprintf("| (a) robust over model-based standard error of the coefficients | %s | | |",
                   paste(sprintf("%.3f", robust_beta$se.beta / model_beta$se.beta), collapse = ", ")))

  # (b) the provider effects.
  at_fit <- clustered_plain(fit$data_include, fit$pred)
  robust_gamma <- pprofR::test_fe(fit, test = "robust_wald", null = 0)
  own <- sqrt(at_fit$robust) / at_fit$information
  full <- sqrt(diag(sandwich_vcov)[effects])
  out <- c(out, facts_row("(b) robust standard errors of the effects against sqrt(V_i) / I_i", robust_gamma$se.gamma, own),
           sprintf("| (b) against the full sandwich's (vcovCL()), ratio: median, range | %.4f, %.4f to %.4f | | |",
                   stats::median(robust_gamma$se.gamma / full), min(robust_gamma$se.gamma / full),
                   max(robust_gamma$se.gamma / full)),
           sprintf("| (b) model-based Wald standard error over the full model-based variance's (vcov(glm)), median | %.6f | | |",
                   stats::median(pprofR::test_fe(fit, test = "wald", null = 0)$se.gamma / sqrt(diag(stats::vcov(g))[effects]))))

  # (c) the robust score and the stabilized tests.
  null <- stats::median(fit$gamma)
  at_null <- clustered_plain(fit$data_include, stats::plogis(null + as.numeric(fit$linear_pred)))
  robust_score <- pprofR::test_fe(fit, test = "robust_score")
  stable_score <- pprofR::test_fe(fit, test = "stabilized_score")
  stable_wald <- pprofR::test_fe(fit, test = "stabilized_wald")
  out <- c(out, facts_row("(c) robust score statistic against U_i / sqrt(V_i)", robust_score$stat, at_null$score / sqrt(at_null$robust)),
           facts_row("(c) stabilized score statistic", stable_score$stat, at_null$score / sqrt(at_null$stable)),
           facts_row("(c) stabilized Wald standard error", stable_wald$se.gamma, sqrt(at_fit$stable) / at_fit$information),
           sprintf("| (c) flags (model-based score, robust score, stabilized score): providers flagged | %d, %d, %d | | |",
                   sum(pprofR::test_fe(fit, test = "score")$flag != 0), sum(robust_score$flag != 0),
                   sum(stable_score$flag != 0)))

  # (d) the order of rows within clusters, and a cluster label shared by two providers.
  reversed <- d[order(d$provider, d$cluster, -seq_len(nrow(d))), ]
  fit_reversed <- pprofR::logis_fe(facts_pprofr_prep(reversed, binomial = binomial, cutoff = 1), tol = 1e-13, stop = "beta")
  out <- c(out,
           facts_row("(d) rows reversed within clusters: robust score statistic", pprofR::test_fe(fit_reversed, test = "robust_score")$stat,
                     robust_score$stat),
           facts_row("(d) rows reversed within clusters: stabilized score statistic",
                     pprofR::test_fe(fit_reversed, test = "stabilized_score")$stat, stable_score$stat))
  shared <- d
  first_two <- unique(d$provider)[1:2]
  shared$cluster[shared$provider == first_two[2]][1] <- shared$cluster[shared$provider == first_two[1]][1]
  fit_shared <- pprofR::logis_fe(facts_pprofr_prep(shared, binomial = binomial, cutoff = 1), tol = 1e-13, stop = "beta")
  g_shared <- stats::update(g, data = shared)
  out <- c(out, sprintf("| (d) one cluster label in two providers: robust standard errors of the coefficients, pprofR against vcovCL() by label | %.3g | | |",
                        max(abs(pprofR::summary_fe_covar(fit_shared, test = "robust_wald")$se.beta /
                                  sqrt(diag(sandwich::vcovCL(g_shared, cluster = ~ cluster, type = "HC0", cadjust = FALSE))[covariates]) - 1))),
           sprintf("| (d) the same against vcovCL() by provider and label | %.3g | | |",
                   max(abs(pprofR::summary_fe_covar(fit_shared, test = "robust_wald")$se.beta /
                             sqrt(diag(sandwich::vcovCL(g_shared, cluster = interaction(shared$provider, shared$cluster, drop = TRUE),
                                                        type = "HC0", cadjust = FALSE))[covariates]) - 1))), "")
}

# (d) Screening: providers kept with cutoff = 10 when the cutoff counts clusters (with a cluster
# column) and when it counts rows (without).
d <- facts_simulate(m = 60, clusters = c(4, 16), seed = 6)
with_clusters <- facts_pprofr_prep(d, cutoff = 10)
without_clusters <- facts_pprofr_prep(d, cluster = FALSE, cutoff = 10)
count_kept <- function(prep) length(unique(prep$data$provider[prep$data$included == 1]))
out <- c(out, sprintf("Screening with cutoff = 10 on %d providers: %d kept counting clusters, %d counting rows.",
                      length(unique(d$provider)), count_kept(with_clusters), count_kept(without_clusters)))
writeLines(out, args[1])
