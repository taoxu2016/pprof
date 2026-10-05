# Phase 8 planning: what data_check() computes with caret::nearZeroVar() and olsrr::ols_vif_tol(),
# and whether base-R versions of the two give identical() results (DEC-009: each replaced function
# needs an equality test against the original). The base-R versions are written from the
# definitions of caret:::nzv() and olsrr:::viftol(), which data_check() reaches through the
# exported functions. Inputs: the two example data sets and variants with a rare category, ties for
# the most frequent value, an integer covariate, near and exact collinearity, a constant column, one
# and two covariates, and character provider IDs.
# Run from the repository root: Rscript <this file> <output file> <library with pprof installed>
args <- commandArgs(TRUE)
out <- args[1]
suppressMessages(library(pprof, lib.loc = args[2]))
lines <- character()
say <- function(...) lines <<- c(lines, paste0(...))

# Base-R candidates, written from the definitions of caret:::nzv() and olsrr:::viftol().
near_zero_metrics <- function(x, freq_cut = 95 / 5, unique_cut = 10) {
  if (is.null(dim(x))) x <- matrix(x, ncol = 1)
  freq_ratio <- apply(x, 2, function(v) {
    counts <- table(v[!is.na(v)])
    if (length(counts) <= 1) return(0)
    w <- which.max(counts)
    max(counts, na.rm = TRUE) / max(counts[-w], na.rm = TRUE)
  })
  n_unique <- apply(x, 2, function(v) length(unique(v[!is.na(v)])))
  percent_unique <- 100 * n_unique / apply(x, 2, length)
  zero_var <- (n_unique == 1) | apply(x, 2, function(v) all(is.na(v)))
  data.frame(freqRatio = freq_ratio, percentUnique = percent_unique, zeroVar = zero_var,
             nzv = (freq_ratio > freq_cut & percent_unique <= unique_cut) | zero_var)
}
vif_table <- function(model) {
  m <- as.data.frame(model.matrix(model))[, -1]
  nam <- names(m)
  p <- length(model$coefficients) - 1
  tol <- numeric()
  for (i in seq_len(p)) {
    tol[i] <- 1 - summary(lm(as.formula(paste0("`", nam[i], "` ~ .")), data = m))$r.squared
  }
  data.frame(Variables = nam, Tolerance = tol, VIF = 1 / tol)
}
# A second VIF candidate that regresses each column on the others without building formulas.
vif_direct <- function(x) {
  x <- as.data.frame(x)
  tol <- vapply(seq_along(x), function(i) {
    1 - summary(lm(x[[i]] ~ ., data = x[-i]))$r.squared
  }, numeric(1))
  data.frame(Variables = names(x), Tolerance = tol, VIF = 1 / tol)
}

data(ExampleDataBinary, package = "pprof", lib.loc = args[2])
data(ExampleDataLinear, package = "pprof", lib.loc = args[2])
set.seed(20261005)
zb <- ExampleDataBinary$Z
n <- nrow(zb)
inputs <- list(
  binary = list(Y = ExampleDataBinary$Y, Z = zb, ProvID = ExampleDataBinary$ProvID),
  linear = list(Y = ExampleDataLinear$Y, Z = ExampleDataLinear$Z, ProvID = ExampleDataLinear$ProvID),
  near_zero = list(Y = ExampleDataBinary$Y, Z = cbind(zb, rare = c(rep(1, 30), rep(0, n - 30))), ProvID = ExampleDataBinary$ProvID),
  ties_max = list(Y = ExampleDataBinary$Y, Z = cbind(zb, tie = rep(c(0, 1, 1, 2, 2), length.out = n)), ProvID = ExampleDataBinary$ProvID),
  integer_cov = list(Y = ExampleDataBinary$Y, Z = cbind(zb, count = rpois(n, 2)), ProvID = ExampleDataBinary$ProvID),
  collinear = list(Y = ExampleDataBinary$Y, Z = cbind(zb, z12 = zb[, 1] + zb[, 2] + rnorm(n, sd = 0.01)), ProvID = ExampleDataBinary$ProvID),
  exact_collinear = list(Y = ExampleDataBinary$Y, Z = cbind(zb, z12 = zb[, 1] + zb[, 2]), ProvID = ExampleDataBinary$ProvID),
  constant = list(Y = ExampleDataBinary$Y, Z = cbind(zb, const = 1), ProvID = ExampleDataBinary$ProvID),
  one_covariate = list(Y = ExampleDataBinary$Y, Z = zb[, 1, drop = FALSE], ProvID = ExampleDataBinary$ProvID),
  two_covariates = list(Y = ExampleDataBinary$Y, Z = zb[, 1:2], ProvID = ExampleDataBinary$ProvID),
  character_ids = list(Y = ExampleDataBinary$Y, Z = zb, ProvID = paste0("P", ExampleDataBinary$ProvID))
)

say("caret ", as.character(packageVersion("caret")), ", olsrr ", as.character(packageVersion("olsrr")),
    ", ", R.version.string)
for (nm in names(inputs)) {
  inp <- inputs[[nm]]
  say("")
  say("== ", nm)
  # What data_check() does with these inputs (messages, warnings, error).
  msgs <- character(); warns <- character()
  err <- tryCatch(withCallingHandlers(
    { data_check(inp$Y, inp$Z, inp$ProvID); NULL },
    message = function(m) { msgs <<- c(msgs, trimws(conditionMessage(m))); invokeRestart("muffleMessage") },
    warning = function(w) { warns <<- c(warns, conditionMessage(w)); invokeRestart("muffleWarning") }
  ), error = function(e) conditionMessage(e))
  say("data_check(): ", length(msgs), " messages; warnings: ", if (length(warns)) paste(warns, collapse = " || ") else "none",
      "; error: ", if (is.null(err)) "none" else err)
  # The same intermediate objects as data_check().
  data <- as.data.frame(cbind(inp$Y, inp$ProvID, inp$Z))
  colnames(data)[1:2] <- c("Y", "ProvID")
  zc <- colnames(inp$Z)
  if (!is.numeric(data[[3]])) { say("columns are ", class(data[[3]]), " after cbind(); the checks below are skipped"); next }
  ref_nzv <- caret::nearZeroVar(data[, zc], saveMetrics = TRUE)
  new_nzv <- near_zero_metrics(data[, zc])
  say("nearZeroVar metrics identical(): ", identical(ref_nzv, new_nzv),
      if (!identical(ref_nzv, new_nzv)) paste0(" (all.equal: ", paste(all.equal(ref_nzv, new_nzv), collapse = "; "), ")") else "")
  say("  row names: ", paste(rownames(ref_nzv), collapse = ", "), "; nzv: ", paste(ref_nzv$nzv, collapse = ", "))
  m_lm <- lm(as.formula(paste("Y ~", paste(zc, collapse = "+"))), data = data)
  ref_vif <- tryCatch(olsrr::ols_vif_tol(m_lm), error = function(e) paste("error:", conditionMessage(e)))
  new_vif <- tryCatch(vif_table(m_lm), error = function(e) paste("error:", conditionMessage(e)))
  dir_vif <- tryCatch(vif_direct(data[, zc, drop = FALSE]), error = function(e) paste("error:", conditionMessage(e)))
  say("ols_vif_tol: ", if (is.character(ref_vif)) ref_vif else paste(signif(ref_vif$VIF, 6), collapse = ", "))
  say("  formula version identical(): ", identical(ref_vif, new_vif),
      "; direct version identical(): ", identical(ref_vif, dir_vif),
      if (is.data.frame(ref_vif) && is.data.frame(dir_vif) && !identical(ref_vif, dir_vif))
        paste0(" (largest relative VIF difference ", signif(max(abs(dir_vif$VIF / ref_vif$VIF - 1), na.rm = TRUE), 3), ")") else "")
}
writeLines(lines, out)
