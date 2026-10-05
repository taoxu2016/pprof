# Phase 7 planning: the developer interface as a developer guide would use it. (1) Which classes
# have methods for each model-contract generic. (2) The fields of each family's specification
# and its declared capabilities. (3) The toy model of the extension proof
# (tests/testthat/helper-toy-model.R) defined and profiled from outside the package, with
# pprof attached by library() as in a vignette, not through devtools::load_all(), which also
# exposes internal functions: whether exported functions suffice.
# Run from the repository root: Rscript <this file> <output file> <library with pprof installed>
args <- commandArgs(trailingOnly = TRUE)
out_file <- args[1]
lib <- args[2]
Sys.setlocale("LC_COLLATE", "C")
grDevices::pdf(NULL) # plots are built on a null device, so no Rplots.pdf is written
suppressPackageStartupMessages(library(pprof, lib.loc = lib))
lines <- character()
say <- function(...) lines <<- c(lines, paste0(...))
run <- function(label, expr) {
  outcome <- tryCatch({
    withCallingHandlers(force(expr), warning = function(w) invokeRestart("muffleWarning"),
                        message = function(m) invokeRestart("muffleMessage"))
    "ok"
  }, error = function(e) sprintf("error %s: %s", class(e)[1], conditionMessage(e)))
  say("  ", label, ": ", outcome)
}

generics <- c("provider_table", "provider_estimates", "provider_index", "linear_predictor", "observed_outcome",
              "expected_outcome", "predicted_outcome", "null_effect", "profile_spec", "inference_capabilities",
              "provider_estimate_se", "provider_test", "refit_without")
table <- get(".__S3MethodsTable__.", envir = asNamespace("pprof"))
registered <- ls(table)
say("## 1. Classes with a method for each contract generic (pprof's S3 table)")
for (g in generics) {
  classes <- sub(paste0("^", g, "[.]"), "", grep(paste0("^", g, "[.]"), registered, value = TRUE))
  say(g, ": ", paste(classes, collapse = ", "))
}

say("")
say("## 2. Family specifications and capabilities")
data(ExampleDataBinary)
data(ExampleDataLinear)
binary <- data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID, ExampleDataBinary$Z)
linear <- data.frame(y = ExampleDataLinear$Y, hospital = ExampleDataLinear$ProvID, ExampleDataLinear$Z)
binary20 <- binary[binary$hospital <= 20, ]
f <- y ~ z1 + z2 + z3 + z4 + z5
quiet <- function(expr) suppressMessages(suppressWarnings(expr))
fits <- list(
  logistic_fe = quiet(fit_logistic_fe(f, binary, "hospital")),
  logistic_firth = quiet(fit_logistic_firth(f, binary, "hospital")),
  linear_fe = quiet(fit_linear_fe(f, linear, "hospital")),
  linear_re = quiet(fit_linear_re(f, linear, "hospital")),
  logistic_re = quiet(fit_logistic_re(f, binary20, "hospital")),
  linear_cre = quiet(fit_linear_cre(f, linear, "hospital", within_between = "z1")),
  logistic_cre = quiet(fit_logistic_cre(f, binary20, "hospital", within_between = "z1"))
)
for (name in names(fits)) {
  spec <- profile_spec(fits[[name]])
  say(name, " class: ", paste(class(fits[[name]]), collapse = " > "))
  say("  specification fields: ", paste(names(spec), collapse = ", "))
  say("  capabilities: ", paste(inference_capabilities(fits[[name]]), collapse = ", "))
  say("  object fields: ", paste(names(fits[[name]]), collapse = ", "))
}

say("")
say("## 3. The toy model of the extension proof, from outside the package")
source(file.path("tests", "testthat", "helper-toy-model.R"), local = TRUE)
uses <- unique(unlist(lapply(c(list(toy_fit, toy_effect_position, register_toy_model), toy_methods), function(fn) {
  calls <- all.names(body(fn))
  calls[grepl("^[a-z_]+$", calls)]
})))
pprof_uses <- intersect(uses, ls(asNamespace("pprof"), all.names = TRUE))
say("pprof functions the toy model calls: ", paste(sort(pprof_uses), collapse = ", "))
say("of which not exported: ", paste(setdiff(pprof_uses, getNamespaceExports("pprof")), collapse = ", "),
    if (!length(setdiff(pprof_uses, getNamespaceExports("pprof")))) "none")
register_toy_model()
toy <- toy_fit(y ~ 1, toy_model_data(), "hospital")
say("class: ", paste(class(toy), collapse = " > "), "; validate_pprof_model() returns it unchanged: ",
    identical(validate_pprof_model(toy), toy))
run("test_providers()", test_providers(toy))
run("test_providers('score')", test_providers(toy, "score"))
run("standardize_providers()", standardize_providers(toy))
run("provider_effects()", provider_effects(toy))
run("funnel_limits()", funnel_limits(toy))
run("profile_providers()", profile_providers(toy))
run("plot_funnel(profile_providers()) built", ggplot2::ggplot_build(plot_funnel(profile_providers(toy))))
run("plot_flags(test_providers(), group_count = 2) built",
    ggplot2::ggplot_build(plot_flags(test_providers(toy), group_count = 2)))
run("plot_volume(profile_providers()) built", ggplot2::ggplot_build(plot_volume(profile_providers(toy))))
run("tidy(test_providers())", tidy(test_providers(toy)))
run("print(toy)", utils::capture.output(print(toy)))
run("test_providers('wald') (undeclared)", test_providers(toy, "wald"))
run("provider_effects(interval = 'exact') (undeclared)", provider_effects(toy, interval = "exact"))
run("standardize_providers('direct') (undeclared)", standardize_providers(toy, "direct"))
run("coef(toy)", coef(toy))
run("summary(toy)", summary(toy))
run("confint(toy)", confint(toy))
writeLines(lines, out_file)
