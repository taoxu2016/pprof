# Provider indexing and the provider table (K-05).
#
# Providers are the levels of factor() applied to the provider values of the complete
# observations: numeric IDs in numeric order, character IDs in the collation order of the
# session's locale (D-34, preserved until sign-off), factor IDs in their level order, with
# unused levels dropped. Observations are sorted by provider with a stable sort, as the
# reference's data[order(factor(ProvID)), ] does.

data_index_providers <- function(values) {
  provider_factor <- factor(values)
  codes <- as.integer(provider_factor)
  list(levels = levels(provider_factor), codes = codes, order = order(codes, method = "radix"))
}

# One row per provider in provider order: `provider_id` (the factor level, character),
# `provider_value` (the ID as it appears in the data, keeping its type), and `n_obs`, the
# number of complete observations. `codes` are the sorted provider codes of the
# observations and `values` their provider values in the same order.
data_provider_table <- function(levels, codes, values) {
  first <- match(seq_along(levels), codes)
  providers <- data.frame(provider_id = levels, stringsAsFactors = FALSE)
  providers$provider_value <- values[first]
  providers$n_obs <- tabulate(codes, nbins = length(levels))
  providers
}
