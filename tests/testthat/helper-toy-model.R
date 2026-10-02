# A test-only model plugged in through the public extension points (ARCHITECTURE §E.4,
# DEC-024).
#
# A binary outcome with provider effects and no covariates, fit in closed form: each
# provider's effect is the logit of its event rate. It uses only functions that pprof exports
# for model developers (data_prepare(), new_pprof_model(), and the model-contract generics),
# and it registers its contract methods with .S3method(), the run-time equivalent of the
# S3method() directives a package would put in its NAMESPACE. No file of pprof refers to it.
# Later phases extend test-extension-toy-model.R as they add profiling and plotting functions.

toy_fit <- function(formula, data, provider, min_provider_size = 1) {
  prepared <- pprof::data_prepare(formula, data, provider, min_provider_size = min_provider_size, event_counts = TRUE)
  if (ncol(prepared$design) > 0L) stop("The toy model has no covariates.")
  providers <- prepared$providers[prepared$providers$included, , drop = FALSE]
  effects <- stats::qlogis(providers$n_events / providers$n_obs)
  names(effects) <- providers$provider_id
  pprof::new_pprof_model(
    prepared,
    coefficients = numeric(),
    vcov = matrix(numeric(), 0L, 0L),
    provider_effects = effects,
    linear_predictor = rep(0, length(prepared$response)),
    spec = list(family = "toy", min_provider_size = min_provider_size),
    class = "pprof_toy_model"
  )
}

# The position of each observation's provider among the included providers.
toy_effect_position <- function(model) {
  match(pprof::provider_index(model), which(pprof::provider_table(model)$included))
}

toy_methods <- list(
  inference_capabilities = function(model) c("provider_exact", "standardize_indirect"),
  expected_outcome = function(model, effect, ...) {
    effect <- if (length(effect) == 1L) rep(effect, length(pprof::provider_estimates(model))) else effect
    stats::plogis(effect[toy_effect_position(model)] + pprof::linear_predictor(model))
  },
  null_effect = function(model, null, ...) {
    if (identical(null, "median")) stats::median(pprof::provider_estimates(model)) else null
  },
  profile_spec = function(model) {
    list(family = "toy", effect = "gamma", null_options = "median", indirect_numerator = "observed", measures = "ratio")
  }
)

register_toy_model <- function() {
  for (generic in names(toy_methods)) .S3method(generic, "pprof_toy_model", toy_methods[[generic]])
  invisible(TRUE)
}

# Five providers of 10 to 14 observations, none with all or no events.
toy_model_data <- function() {
  sizes <- 10:14
  events <- c(3L, 5L, 2L, 8L, 6L)
  hospital <- rep(sprintf("hospital %d", 1:5), sizes)
  y <- unlist(Map(function(n, k) c(rep(1, k), rep(0, n - k)), sizes, events))
  data.frame(y = y, hospital = hospital, stringsAsFactors = FALSE)
}
