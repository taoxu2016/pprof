# Phase 5 planning: facts from the current code (working tree, devtools::load_all()).
# Run from the repository root: Rscript <this file> <output file>
args <- commandArgs(trailingOnly = TRUE)
out_file <- args[1]
Sys.setlocale("LC_COLLATE", "C")
suppressMessages(devtools::load_all(quiet = TRUE))
lines <- character()
say <- function(...) lines <<- c(lines, paste0(...))
quiet <- function(expr) suppressMessages(suppressWarnings(expr))
say("lme4 ", as.character(packageVersion("lme4")), ", Matrix ", as.character(packageVersion("Matrix")))

data(ExampleDataLinear)
data(ExampleDataBinary)
lin <- data.frame(y = ExampleDataLinear$Y, hospital = ExampleDataLinear$ProvID, ExampleDataLinear$Z)
bin <- data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID, ExampleDataBinary$Z)
f <- y ~ z1 + z2 + z3 + z4 + z5

new_fits <- list(
  linear_fe = fit_linear_fe(f, lin, "hospital"),
  linear_re = quiet(fit_linear_re(f, lin, "hospital")),
  logistic_re = quiet(fit_logistic_re(f, bin, "hospital")),
  linear_cre = quiet(fit_linear_cre(f, lin, "hospital", within_between = c("z1", "z2"))),
  logistic_cre = quiet(fit_logistic_cre(f, bin, "hospital", within_between = c("z1", "z2")))
)

say("")
say("## 1. Capabilities and entry points of the Phase 4 models")
for (name in names(new_fits)) {
  fit <- new_fits[[name]]
  caps <- inference_capabilities(fit)
  outcomes <- vapply(c("test_providers(fit, test = 'wald')", "standardize_providers(fit)", "provider_effects(fit)",
                       "funnel_limits(fit)", "summary(fit)", "confint(fit)", "test_coefficients(fit)"), function(call) {
    tryCatch({ eval(parse(text = call)); "value" }, error = function(e) class(e)[1])
  }, character(1))
  say(sprintf("%s: %d capabilities; provider table columns %s", name, length(caps),
              paste(names(provider_table(fit)), collapse = ", ")))
  say(sprintf("  %s", paste(names(outcomes), outcomes, sep = " -> ", collapse = "; ")))
}

say("")
say("## 2. The new direct expectations on random-effect inputs (alpha, X beta with intercept)")
for (name in c("logistic_re", "logistic_cre")) {
  fit <- new_fits[[name]]
  alpha <- unname(fit$provider_effects)
  xb <- fit$linear_predictor
  new <- cpp_logistic_direct_expected(alpha, xb, 1L)
  old <- as.numeric(computeDirectExp(alpha, xb, 1L))
  say(sprintf("%s: cpp_logistic_direct_expected() identical to computeDirectExp(): %s; 2 threads identical: %s", name,
              identical(new, old), identical(new, cpp_logistic_direct_expected(alpha, xb, 2L))))
  pred <- expected_outcome(fit, unname(fit$provider_effects))
  say(sprintf("  fitted (lme4) identical to expected_outcome(model, provider effects): %s", identical(fit$fitted, pred)))
}
for (name in c("linear_re", "linear_cre")) {
  fit <- new_fits[[name]]
  pred <- expected_outcome(fit, unname(fit$provider_effects))
  say(sprintf("%s: fitted (lme4) identical to expected_outcome(model, provider effects): %s", name, identical(fit$fitted, pred)))
}

say("")
say("## 3. Independent check of logistic FE against glm() with provider indicators (ARCHITECTURE G.5)")
glm_check <- function(data, label) {
  data$hospital <- factor(data$hospital)
  fe <- fit_logistic_fe(f, data, "hospital", tol = 1e-12, stop_rule = "all", min_provider_size = 1)
  g <- stats::glm(y ~ 0 + hospital + z1 + z2 + z3 + z4 + z5, family = stats::binomial(), data = data,
                  control = stats::glm.control(epsilon = 1e-14, maxit = 100))
  gamma_glm <- unname(stats::coef(g)[seq_len(nlevels(data$hospital))])
  beta_glm <- unname(stats::coef(g)[paste0("z", 1:5)])
  var_beta_glm <- unname(diag(stats::vcov(g))[paste0("z", 1:5)])
  var_gamma_glm <- unname(diag(stats::vcov(g))[seq_len(nlevels(data$hospital))])
  rel <- function(a, b) max(abs(a - b) / pmax(abs(b), 1e-300))
  say(sprintf("%s: %d obs, %d providers; iterations %d (glm %d); beta max abs %.2g rel %.2g; gamma max abs %.2g rel %.2g;",
              label, nrow(data), nlevels(data$hospital), fe$convergence$iterations, g$iter,
              max(abs(unname(fe$coefficients) - beta_glm)), rel(unname(fe$coefficients), beta_glm),
              max(abs(unname(fe$provider_effects) - gamma_glm)), rel(unname(fe$provider_effects), gamma_glm)))
  say(sprintf("  Var(beta) rel %.2g; Var(gamma) rel %.2g; loglik diff %.2g",
              rel(diag(fe$vcov), var_beta_glm), rel(unname(fe$provider_effect_variance), var_gamma_glm),
              abs(fe$loglik - as.numeric(stats::logLik(g)))))
}
events <- tapply(bin$y, bin$hospital, sum)
sizes <- tapply(bin$y, bin$hospital, length)
keep <- names(events)[events > 0 & events < sizes]
glm_check(bin[bin$hospital %in% as.numeric(keep), ], "example without extreme providers")
set.seed(20261004)
m <- 60
sizes <- sample(20:120, m, replace = TRUE)
hospital <- rep(seq_len(m), sizes)
z_sim <- matrix(rnorm(length(hospital) * 5), ncol = 5, dimnames = list(NULL, paste0("z", 1:5)))
eta <- rnorm(m, -0.5, 0.4)[hospital] + drop(z_sim %*% c(0.3, -0.2, 0.1, 0.4, -0.3))
sim <- data.frame(y = rbinom(length(eta), 1, plogis(eta)), hospital = hospital, z_sim)
glm_check(sim, "simulated (seed 20261004)")

say("")
say("## 4. Model files and reference method files")
say(sprintf("compat-methods.R lines: %d", length(readLines("R/compat-methods.R"))))

writeLines(lines, out_file)
