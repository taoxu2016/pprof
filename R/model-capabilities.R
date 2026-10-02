# Inference capabilities (ARCHITECTURE §E.3).
#
# A model declares the inference it supports with a method for inference_capabilities().
# Every inference and profiling entry point calls require_capability() before computing, so a
# model never receives a request it has not declared: a penalized model, for example, cannot
# return a Wald number by accident. Models may declare capabilities beyond this list for
# inference of their own (ARCHITECTURE §E.6).

capability_names <- c(
  "coef_wald", "coef_lr", "coef_score",
  "provider_exact", "provider_bootstrap", "provider_score", "provider_score_standard", "provider_wald",
  "interval_exact", "interval_score", "interval_wald",
  "standardize_indirect", "standardize_direct",
  "funnel"
)

require_capability <- function(model, capability) {
  capabilities <- inference_capabilities(model)
  if (!is.character(capabilities)) {
    abort_invalid_input(
      sprintf("inference_capabilities() for class '%s' must return a character vector.", class(model)[1]),
      arg = "model"
    )
  }
  if (!capability %in% capabilities) abort_unsupported_inference(model, capability)
  invisible(model)
}
