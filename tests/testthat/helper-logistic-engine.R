# Inputs of the logistic fixed-effect engines for reference cases (Phase 3).
#
# Translates a logis_fe() fixture case into what the C++ adapters take: the response, the
# design matrix, and the provider sizes from the data layer; the reference's starting values
# (K-10: the logit of the overall event rate for every provider, beta = 0); and the case's
# settings, with the reference's defaults (K-17) and its stopping-rule names translated to
# NAMING.md §4.

engine_stop_rules <- c(or = "any", all = "all", beta = "coefficients", relch = "relative_loglik",
                       ratch = "relative_gain")

engine_case_inputs <- function(case, datasets) {
  translation <- reference_data_translation(case, datasets)
  inputs <- engine_prepared_inputs(do.call(data_prepare, translation$call))
  args <- reference_resolve_args(case$args, datasets, list())
  setting <- function(name, default) if (is.null(args[[name]])) default else args[[name]]
  inputs$method <- setting("method", "SerBIN")
  inputs$max_iter <- as.integer(setting("max.iter", 10000))
  inputs$tol <- setting("tol", 1e-5)
  inputs$bound <- setting("bound", 10)
  inputs$backtrack <- setting("backtrack", TRUE)
  inputs$stop_rule <- engine_stop_rules[[setting("stop", "or")]]
  inputs$threads <- as.integer(setting("threads", 1))
  inputs
}

engine_fit <- function(inputs, threads = inputs$threads) {
  engine <- if (identical(inputs$method, "BAN")) cpp_logistic_fe_ban else cpp_logistic_fe_serbin
  engine(inputs$response, inputs$design, inputs$sizes, inputs$gamma, inputs$beta, inputs$max_iter, inputs$tol,
         inputs$bound, inputs$backtrack, inputs$stop_rule, threads)
}

# The criterion the reference printed at each iteration ("Iter k: ... is 1.234e-01;"), as
# text, from a fixture's captured output.
engine_reference_log <- function(output) {
  lines <- grep("^Iter [0-9]+: ", output, value = TRUE)
  sub("^Iter [0-9]+: .* is (.*);$", "\\1", lines)
}

# The same text for an engine's criterion history: C++ streams with scientific notation and
# precision 3 print as formatC(format = "e", digits = 3) does.
engine_log <- function(fit) {
  formatC(fit$history[, "rule"], format = "e", digits = 3)
}

# Engine inputs for a dataset stored with the fixtures, prepared as logis_fe() prepares it
# (screening at min_provider_size, starting values K-10).
engine_dataset_inputs <- function(dataset, covariates, min_provider_size = 10) {
  data <- readRDS(reference_locate(file.path("datasets", paste0(dataset, ".rds")), "core"))
  prepared <- data_prepare(stats::reformulate(covariates, response = "Y"), data, "ProvID",
                           min_provider_size = min_provider_size, event_counts = TRUE)
  engine_prepared_inputs(prepared)
}

engine_prepared_inputs <- function(prepared) {
  y <- as.numeric(prepared$response)
  design <- prepared$design
  attributes(design) <- list(dim = dim(design))
  sizes <- prepared$providers$n_obs[prepared$providers$included]
  start <- log(mean(y) / (1 - mean(y)))
  list(response = y, design = design, sizes = as.integer(sizes), gamma = rep(start, length(sizes)),
       beta = rep(0, ncol(design)), method = "SerBIN", max_iter = 10000L, tol = 1e-5, bound = 10,
       backtrack = TRUE, stop_rule = "any", threads = 1L)
}

# Seeded random data for the logistic engines, sorted by provider: between 5 and 40
# providers of 1 to 80 observations (sizes 1 and 2 included), 1 to 6 covariates on varying
# scales, event rates from rare to common, and, in most scenarios, one provider with no
# events and one with only events.
engine_random_inputs <- function(seed) {
  withr::with_seed(seed, {
    m <- sample(5:40, 1L)
    sizes <- sample(c(1L, 2L, 5:80), m, replace = TRUE)
    p <- sample(1:6, 1L)
    n <- sum(sizes)
    provider <- rep(seq_len(m), sizes)
    z <- matrix(stats::rnorm(n * p, sd = sample(c(0.5, 1, 2), 1L)), n, p)
    gamma <- stats::rnorm(m, sample(c(-3, -1, 0, 1.5), 1L), 0.8)
    beta <- stats::rnorm(p, 0, 0.6)
    y <- stats::rbinom(n, 1L, stats::plogis(gamma[provider] + drop(z %*% beta)))
    if (stats::runif(1L) < 0.8) {
      y[provider == 1L] <- 0
      y[provider == 2L] <- 1
    }
  })
  start <- log(mean(y) / (1 - mean(y)))
  list(response = as.numeric(y), design = z, sizes = as.integer(sizes), gamma = rep(start, m), beta = rep(0, p),
       method = "SerBIN", max_iter = 10000L, tol = 1e-5, bound = 10, backtrack = TRUE, stop_rule = "any",
       threads = 1L)
}

# Logistic fixed-effect fit cases whose reference call returned a value, except the D-23
# case: there the reference ran no iterations because backtrack = 2 selects no branch of its
# BAN loop, which the adapter's logical argument cannot express (the wrapper rejects the
# value instead).
engine_reference_ids <- function(set = "core", fun = "logis_fe") {
  manifest <- reference_manifest(set)
  if (is.null(manifest)) return(character())
  keep <- vapply(manifest$cases, function(entry) {
    identical(entry[["fun"]], fun) && identical(entry[["outcome"]], "value")
  }, logical(1))
  setdiff(vapply(manifest$cases[keep], `[[`, character(1), "id"), "logis_fe-binary-ban-backtrack2")
}

# --- Firth (Phase 4) ------------------------------------------------------------------------

# Inputs of the Firth engine for a logis_firth() fixture case: the data and starting values
# as logis_fe() prepares them (logis_firth() copies that code, BEHAVIOR_SPECS §3), and the
# case's settings with the reference's Firth defaults (K-33: max.iter = 1000).
firth_case_inputs <- function(case, datasets) {
  inputs <- engine_case_inputs(case, datasets)
  max_iter <- reference_resolve_args(case$args, datasets, list())[["max.iter"]]
  inputs$max_iter <- as.integer(if (is.null(max_iter)) 1000 else max_iter)
  inputs
}

firth_fit <- function(inputs, threads = inputs$threads, max_iter = inputs$max_iter, tol = inputs$tol,
                      bound = inputs$bound) {
  cpp_logistic_firth(inputs$response, inputs$design, inputs$sizes, inputs$gamma, inputs$beta, as.integer(max_iter),
                     tol, bound, as.integer(threads))
}

# The criterion of every iteration as the reference printed it (see engine_log()).
firth_log <- function(fit) {
  formatC(fit$history[, "coefficients"], format = "e", digits = 3)
}
