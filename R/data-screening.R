# Screening by provider size and event indicators (K-06, K-07).

# A provider is included when it has at least `min_provider_size` complete observations
# (K-06). `min_provider_size = NULL` includes every provider, as the linear fixed-effect and
# the random-effect models do (K-07).
data_screen_providers <- function(providers, min_provider_size) {
  providers$included <- if (is.null(min_provider_size)) {
    rep(TRUE, nrow(providers))
  } else {
    providers$n_obs >= min_provider_size
  }
  providers
}

# Event counts per provider and, among included providers, the indicators of providers with
# no events and with only events (K-06). The sums are computed as the reference computes
# them, sapply(split(y, provider), sum) == 0 for no events and the same sum of 1 - y for
# only events, so that the indicators agree for any numeric response.
data_event_indicators <- function(providers, response, codes) {
  groups <- data_provider_factor(codes, seq_len(nrow(providers)))
  providers$n_events <- vapply(split(response, groups), sum, numeric(1), USE.NAMES = FALSE)
  non_events <- vapply(split(1 - response, groups), sum, numeric(1), USE.NAMES = FALSE)
  providers$no_events <- providers$included & providers$n_events == 0
  providers$all_events <- providers$included & non_events == 0
  providers
}
