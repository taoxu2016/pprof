# The closed-form sums behind the standardized measures of the provider-stratified Cox model (the CoxPH
# brief's §1 and §5.3; COXPH_DESIGN §F.1, §F.2; K-136 to K-138): He and Schaubel's two-stage measures as
# pprof_py v0.7.0 computes them (pprof_py/measures/survival/coxph.py:47-104). They use the fitted
# coefficients alone, not the fit's strata, ties, or weights: every row counts once, rows with weight 0
# included, and the baselines are Breslow's whatever ties fitted the coefficients (M-25, M-29). The fit
# computes the expected events once (`expected_events`), and the family specification hands the
# direct expectations to the profiling layer (`direct_by_provider`).

# K-136, K-137: each observation's expected events at the national baseline, r_i [L0(stop_i) -
# L0(start_i)], where r = exp(eta - max eta), not clipped, and L0 is the Breslow estimator over all rows
# with eta as offset, at the distinct event times by exact equality: the cumulative sum of d(t) / RS(t),
# d(t) the number of event rows at t and RS(t) = sum of r over the rows with start < t <= stop,
# computed as the difference of the suffix sums of r by exit and by entry, as pprof_py computes it.
# Every quantity is invariant to a common factor in exp(eta), and the counts add up to the events.
cox_expected_events <- function(eta, start, stop, event) {
  risk <- exp(eta - max(eta))
  events <- event == 1
  times <- sort(unique(stop[events]))
  deaths <- tabulate(match(stop[events], times), length(times))
  at_risk <- cox_suffix_sums(stop, risk, times) - cox_suffix_sums(start, risk, times)
  cumulative <- c(0, cumsum(deaths / at_risk))
  risk * (cumulative[findInterval(stop, times) + 1L] - cumulative[findInterval(start, times) + 1L])
}

# For each value in `query`, the sum of `values` over the rows whose key is at least that value: the
# suffix sums of `values` with the rows sorted stably by key, read at the first key not below the
# query (pprof_py's _suffix_sums() and searchsorted(side = "left")).
cox_suffix_sums <- function(keys, values, query) {
  order <- order(keys, method = "radix")
  sums <- c(rev(cumsum(rev(values[order]))), 0)
  sums[findInterval(query, keys[order], left.open = TRUE) + 1L]
}

# K-138: the directly standardized expected events of the providers in `rows` (rows of the provider
# table): E(j) = sum over provider j's event rows i of RS(t_i) / RS_j(t_i), with RS the national
# risk-set sums of exp(eta) and RS_j those of provider j's own rows; 0 for a provider without events.
# E(j) is the number of events the whole population would have with provider j's baseline. RS_j comes
# from suffix sums within each provider's rows, so that no provider's sum is a difference of sums over
# other providers' rows. The family specification's `direct_by_provider` (DEC-108).
cox_direct_expected <- function(model, rows) {
  eta <- model$linear_predictor
  if (!is.null(model$offset)) eta <- eta + model$offset
  risk <- exp(eta - max(eta))
  provider <- model$provider_index
  events <- which(model$response == 1)
  times <- sort(unique(model$stop[events]))
  national <- cox_suffix_sums(model$stop, risk, times) - cox_suffix_sums(model$start, risk, times)
  # Keys that order the rows by provider, then time: the provider code times the number of distinct
  # times, plus the time's rank, exact in a double.
  grid <- sort(unique(c(model$start, model$stop)))
  span <- length(grid) + 1
  key <- function(time, index) index * span + match(time, grid)
  query <- key(model$stop[events], provider[events])
  own <- cox_provider_suffix_sums(key(model$stop, provider), risk, provider, query, provider[events]) -
    cox_provider_suffix_sums(key(model$start, provider), risk, provider, query, provider[events])
  data_provider_sums(national[match(model$stop[events], times)] / own, provider[events], rows)
}

# For each query (a key and the provider it belongs to), the sum of `values` over that provider's rows
# whose key is at least the query's. The suffix sums run within each provider's rows.
cox_provider_suffix_sums <- function(keys, values, provider, query, query_provider) {
  order <- order(keys, method = "radix")
  sorted_provider <- provider[order]
  within <- unlist(lapply(split(values[order], sorted_provider), function(x) rev(cumsum(rev(x)))),
                   use.names = FALSE)
  position <- findInterval(query, keys[order], left.open = TRUE) + 1L
  inside <- position <= length(order)
  inside[inside] <- sorted_provider[position[inside]] == query_provider[inside]
  out <- numeric(length(query))
  out[inside] <- within[position[inside]]
  out
}
