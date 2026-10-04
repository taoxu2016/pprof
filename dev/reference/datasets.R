# Datasets for the reference fixtures.
#
# Each dataset is built deterministically: bundled datasets are read from the reference
# library; synthetic ones use base R's RNG with fixed seeds and explicit RNG kinds. The
# generator stores every dataset with the fixtures, so tests never depend on regenerating
# them (brief §6).

reference_set_seed <- function(seed) {
  set.seed(seed, kind = "Mersenne-Twister", normal.kind = "Inversion", sample.kind = "Rejection")
}

# Binary outcome with provider effects; sizes is a vector of provider sizes.
simulate_binary_providers <- function(sizes, beta, gamma_sd = 0.5, intercept = -1, seed) {
  reference_set_seed(seed)
  m <- length(sizes)
  prov <- rep(seq_len(m), sizes)
  n <- length(prov)
  p <- length(beta)
  z <- matrix(stats::rnorm(n * p), n, p, dimnames = list(NULL, paste0("x", seq_len(p))))
  gamma <- stats::rnorm(m, 0, gamma_sd)
  y <- stats::rbinom(n, 1, stats::plogis(intercept + gamma[prov] + drop(z %*% beta)))
  data.frame(Y = y, ProvID = prov, z)
}

reference_datasets <- function(ref_lib, include_full = FALSE) {
  bundled <- new.env()
  for (name in c("ExampleDataBinary", "ExampleDataLinear", "ecls_data")) {
    utils::data(list = name, package = "pprof", lib.loc = ref_lib, envir = bundled)
  }
  ds <- list()

  # Bundled data, as distributed and as data frames.
  ds$binary_example_list <- bundled$ExampleDataBinary
  ds$binary_example <- data.frame(Y = bundled$ExampleDataBinary$Y, ProvID = bundled$ExampleDataBinary$ProvID,
                                  bundled$ExampleDataBinary$Z)
  ds$linear_example_list <- bundled$ExampleDataLinear
  ds$linear_example <- data.frame(Y = bundled$ExampleDataLinear$Y, ProvID = bundled$ExampleDataLinear$ProvID,
                                  bundled$ExampleDataLinear$Z)
  ds$ecls <- bundled$ecls_data

  # Screening boundary: sizes 5, 9, 10, 11 next to regular providers; rows shuffled so that
  # sorting by provider is exercised.
  scr <- simulate_binary_providers(c(5, 9, 10, 11, rep(25, 26)), beta = c(0.6, -0.4, 0.2), seed = 101)
  reference_set_seed(102)
  ds$syn_screening <- scr[sample(nrow(scr)), ]
  rownames(ds$syn_screening) <- NULL

  # No-event and all-event providers (three of each kind of extreme is not needed: three
  # no-event, two all-event).
  ext <- simulate_binary_providers(rep(25, 40), beta = c(0.8, -0.5, 0.3), gamma_sd = 0.7, seed = 103)
  ext$Y[ext$ProvID %in% 1:3] <- 0
  ext$Y[ext$ProvID %in% 4:5] <- 1
  ds$syn_extreme <- ext
  # Same data with character IDs whose C-locale order differs from numeric and English order
  # (D-19, D-34), with factor IDs (D-28), integer IDs (D-27), and a provider column with
  # another name (D-29).
  chr_ids <- paste0(rep(c("a", "B", "c", "D"), length.out = 40), sprintf("%02d", 40:1))
  ds$syn_extreme_chr <- transform(ext, ProvID = chr_ids[ProvID])
  ds$syn_extreme_fac <- transform(ext, ProvID = factor(ProvID * 10))
  ds$syn_extreme_int <- transform(ext, ProvID = as.integer(ProvID))
  hosp <- ext
  names(hosp)[names(hosp) == "ProvID"] <- "hospital"
  ds$syn_extreme_hospital <- hosp

  # Quasi-separation: in providers 1-3 the outcome is 1 exactly when xs > 0.
  sep <- simulate_binary_providers(rep(30, 20), beta = c(0.5, 0.3), seed = 104)
  reference_set_seed(105)
  sep$xs <- stats::rnorm(nrow(sep))
  sep$Y[sep$ProvID %in% 1:3] <- as.integer(sep$xs[sep$ProvID %in% 1:3] > 0)
  ds$syn_separation <- sep

  # Collinear and constant covariates.
  col <- simulate_binary_providers(rep(30, 20), beta = c(0.5, 0.3), seed = 106)
  col$x3 <- col$x1 + col$x2
  ds$syn_collinear <- col
  con <- simulate_binary_providers(rep(30, 20), beta = c(0.5, 0.3), seed = 107)
  con$xc <- 1
  ds$syn_constant <- con
  # Covariates alone, for data_check(Y, Z, ProvID).
  ds$syn_collinear_covariates <- col[, c("x1", "x2", "x3")]
  ds$syn_constant_covariates <- con[, c("x1", "x2", "xc")]

  # Factor covariates: level names with spaces (D-18) and an unused level; character IDs.
  fac <- simulate_binary_providers(rep(30, 20), beta = 0.5, seed = 108)
  reference_set_seed(109)
  fac$grp <- factor(sample(c("level one", "level two", "level three"), nrow(fac), replace = TRUE))
  fac$grp2 <- factor(sample(c("a", "b"), nrow(fac), replace = TRUE), levels = c("a", "b", "unused"))
  fac$ProvID <- sprintf("H%02d", fac$ProvID)
  ds$syn_factors <- fac
  # The same data with the level names of grp written without spaces, in the same level
  # order: the reference fits it with a formula, which gives the expected result of the
  # D-18 fix for syn_factors (Phase 3, per-case expectations). No random numbers are drawn.
  fac_nospaces <- fac
  levels(fac_nospaces$grp) <- gsub(" ", "_", levels(fac_nospaces$grp), fixed = TRUE)
  ds$syn_factors_nospaces <- fac_nospaces

  # Transformed and interaction terms (D-18).
  trm <- simulate_binary_providers(rep(30, 20), beta = c(0.5, -0.3), seed = 110)
  trm$w <- abs(trm$x1) + 1
  names(trm)[names(trm) %in% c("x1", "x2")] <- c("z1", "z2")
  ds$syn_terms <- trm
  # The same data with the transformed and interaction terms computed as columns, as
  # model.matrix() computes them: the reference fits it with plain column names, which gives
  # the expected results of the D-18 fix for syn_terms (Phase 3, per-case expectations).
  ds$syn_terms_columns <- transform(trm, logw = log(w), z1z2 = z1 * z2, z1sq = z1^2)

  # Missing values in the response, a covariate, and the provider; plus an all-NA column
  # that no model uses.
  mis <- simulate_binary_providers(rep(30, 20), beta = c(0.5, -0.3), seed = 111)
  mis$Y[c(3, 50, 99, 200, 401)] <- NA
  mis$x1[c(7, 77, 177, 277, 377)] <- NA
  mis$ProvID[c(15, 315, 515)] <- NA
  mis$unused <- NA
  ds$syn_missing <- mis
  ds$syn_missing_covariates <- mis[, c("x1", "x2")]

  # Very unequal provider sizes; rare and common outcomes.
  reference_set_seed(112)
  ds$syn_unequal <- simulate_binary_providers(c(1500, sample(10:30, 39, replace = TRUE)), beta = c(0.5, -0.3),
                                              seed = 113)
  ds$syn_rare <- simulate_binary_providers(rep(60, 30), beta = c(0.5, -0.3), intercept = -4, seed = 114)
  ds$syn_common <- simulate_binary_providers(rep(60, 30), beta = c(0.5, -0.3), intercept = 3.5, seed = 115)

  # A provider whose covariate pushes every null probability to exactly 1 (D-04, V13.6).
  reference_set_seed(7)
  m <- 30
  prov <- rep(seq_len(m), each = 40)
  x <- stats::rnorm(length(prov))
  x[prov == 5] <- stats::rnorm(40, 45, 1)
  y <- stats::rbinom(length(prov), 1, stats::plogis(-1 + stats::rnorm(m, 0, 0.5)[prov] + x))
  ds$syn_d04 <- data.frame(Y = y, ProvID = prov, x1 = x)
  # The same data with the provider IDs stored as doubles, which the reference's `parm` can
  # select (D-27): its standard score test of the providers other than provider 5 gives the
  # expected statistics of the D-04 fix for syn_d04 (Phase 3 gate). No random numbers are drawn.
  ds$syn_d04_double <- transform(ds$syn_d04, ProvID = as.numeric(ProvID))

  # Small data for Firth (no extreme providers), as in V12.5.
  reference_set_seed(5)
  sizes <- sample(12:30, 12, replace = TRUE)
  prov <- rep(seq_len(12), sizes)
  xf <- matrix(stats::rnorm(length(prov) * 2), ncol = 2, dimnames = list(NULL, c("x1", "x2")))
  yf <- stats::rbinom(length(prov), 1, stats::plogis(stats::rnorm(12, -0.5, 0.8)[prov] + xf %*% c(0.7, -0.4)))
  ds$syn_firth_small <- data.frame(Y = yf, ProvID = prov, xf)

  # Providers of size 8 next to providers of size 20, for a fit with cutoff = 5 (D-10).
  reference_set_seed(3)
  ds$syn_cutoff5 <- data.frame(Y = stats::rbinom(1000, 1, 0.3), ProvID = c(rep(1:40, each = 20), rep(41:65, each = 8)),
                               x1 = stats::rnorm(1000), x2 = stats::rnorm(1000), x3 = stats::rnorm(1000))

  # Continuous outcome: providers of size 1 and 2, character IDs, a factor covariate.
  reference_set_seed(116)
  lin_sizes <- c(1, 2, sample(5:60, 28, replace = TRUE))
  prov <- rep(seq_len(30), lin_sizes)
  n <- length(prov)
  lin <- data.frame(ProvID = sprintf("S%02d", prov), x1 = stats::rnorm(n), x2 = stats::rnorm(n),
                    grp = factor(sample(c("north", "south", "west"), n, replace = TRUE)))
  lin$Y <- stats::rnorm(30, 0, 1)[prov] + 0.8 * lin$x1 - 0.5 * lin$x2 + 0.3 * (lin$grp == "south") + stats::rnorm(n)
  ds$syn_linear <- lin[, c("Y", "ProvID", "x1", "x2", "grp")]

  # Continuous outcome with missing responses inside one provider (D-13).
  lm2 <- ds$linear_example[ds$linear_example$ProvID <= 30, ]
  lm2$Y[lm2$ProvID == 1][1:5] <- NA
  rownames(lm2) <- NULL
  ds$syn_linear_missing <- lm2

  # Phase 5 (R-1). No random numbers are drawn for the first three.
  # The vector interface of linear_re() and logis_re() (D-11): the outcome, numeric and
  # character provider IDs, and the covariates as a data frame and as a matrix.
  ds$syn_linear_vectors <- list(Y = ds$syn_linear$Y, ProvID = as.numeric(sub("S", "", ds$syn_linear$ProvID)),
                                ProvID_chr = ds$syn_linear$ProvID, Z = ds$syn_linear[, c("x1", "x2")],
                                Z_matrix = as.matrix(ds$syn_linear[, c("x1", "x2")]))
  ds$syn_extreme_vectors <- list(Y = ext$Y, ProvID = as.numeric(ext$ProvID), ProvID_chr = chr_ids[ext$ProvID],
                                 Z = ext[, c("x1", "x2", "x3")], Z_matrix = as.matrix(ext[, c("x1", "x2", "x3")]))
  # syn_linear with the provider IDs stored as integers (D-27).
  ds$syn_linear_int <- transform(ds$syn_linear, ProvID = as.integer(sub("S", "", ProvID)))
  # Small providers whose covariate means differ, where the linear funnel's limits and flags
  # disagree with the full provider variance (D-43; dev/design/phase5-facts/05_linear_funnel_flags.R).
  # Only the first m of the m * 5 shifts are used; all are drawn, as in that script.
  reference_set_seed(20261004)
  m <- 40
  sizes <- sample(3:8, m, replace = TRUE)
  prov <- rep(seq_len(m), sizes)
  zf <- matrix(stats::rnorm(length(prov) * 5), ncol = 5, dimnames = list(NULL, paste0("z", 1:5)))
  shift <- stats::rnorm(m * 5, 0, 4)[seq_len(m)]
  zf <- zf + shift[prov]
  ds$syn_linear_funnel <- data.frame(Y = stats::rnorm(m, 0, 1.2)[prov] + drop(zf %*% c(1, -0.5, 0.3, 0, 0.2)) +
                                       stats::rnorm(length(prov)), ProvID = prov, zf)

  if (include_full) {
    # About 80,000 observations in 1,000 providers (as V11.1, "medium"): default versus
    # tight convergence (D-24).
    reference_set_seed(2)
    sizes <- pmax(stats::rpois(1000, 80), 10L)
    prov <- rep(seq_len(1000), sizes)
    n <- length(prov)
    z <- matrix(stats::rnorm(n * 10), n, 10, dimnames = list(NULL, paste0("x", 1:10)))
    z[, 2] <- 0.5 * z[, 1] + z[, 2]
    gamma <- stats::rnorm(1000, -2, 0.6)
    yb <- stats::rbinom(n, 1, stats::plogis(gamma[prov] + drop(z %*% seq(-0.5, 0.5, length.out = 10))))
    ds$sim_binary_medium <- data.frame(Y = yb, ProvID = prov, z)
  }
  ds
}

# Which fixture set each dataset belongs to; core datasets ship with the package.
reference_dataset_set <- function(name) {
  if (name %in% c("sim_binary_medium")) "full" else "core"
}
