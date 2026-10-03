# Modified score statistics for provider effects, and the clamp of null probabilities
# (K-62, K-65). The standard score test (K-66) is computed in C++ through provider_test().

# Null probabilities clamped to [probability_clamp, 1 - probability_clamp] for the exact,
# bootstrap, and modified score tests (K-62, K-64, K-65; R/test.logis_fe.R:104, :182,
# :214).
infer_clamp_probabilities <- function(probabilities) {
  pmin(pmax(probabilities, probability_clamp), 1 - probability_clamp)
}

# Modified score statistics (K-65): per provider, the sum of y - p0 over the square root of
# the sum of p0 (1 - p0), with clamped null probabilities p0 and the unrestricted
# coefficients (R/test.logis_fe.R:181-184). `index` gives each observation's row of the
# provider table and `providers` the rows tested.
infer_score_modified <- function(response, probabilities, index, providers) {
  data_provider_sums(response - probabilities, index, providers) /
    sqrt(data_provider_sums(probabilities * (1 - probabilities), index, providers))
}
