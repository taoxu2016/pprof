# Phase 8, step 1 (D-53): pprof 1.0.3's exact test multiplies each provider's rows of the
# design by the coefficients (test.logis_fe(), exact.poisbinom), while the package multiplies
# the whole design once (the model's linear predictor). With R's reference BLAS each row's sum
# is formed the same way in both. This measures, with the BLAS of the machine it runs on, how
# many rows of the two products differ, and how far that moves the exact test's statistic with
# null 0 (two-sided, as test-binary-exact-null0), on ExampleDataBinary.
# Run from the repository root: Rscript <this file>; it prints a GitHub notice annotation.
suppressMessages(devtools::load_all(quiet = TRUE))
data(ExampleDataBinary, package = "pprof")
d <- data.frame(Y = ExampleDataBinary$Y, ProvID = ExampleDataBinary$ProvID, ExampleDataBinary$Z)
fit <- fit_logistic_fe(Y ~ z1 + z2 + z3 + z4 + z5, d, "ProvID", keep_data = TRUE)
design <- fit$data$design
attributes(design) <- list(dim = dim(design))
beta <- unname(fit$coefficients)
blocks <- split(seq_len(nrow(design)), fit$data$provider_index)
whole <- drop(design %*% beta)
per_provider <- numeric(length(whole))
for (rows in blocks) per_provider[rows] <- drop(design[rows, , drop = FALSE] %*% beta)
statistic <- function(linear_predictor) {
  vapply(blocks, function(rows) {
    p <- pmin(pmax(stats::plogis(0 + linear_predictor[rows]), 1e-10), 1 - 1e-10)
    observed <- sum(fit$data$response[rows])
    stats::qnorm(1 - poibin::ppoibin(observed, p) + 0.5 * poibin::dpoibin(observed, p), lower.tail = FALSE)
  }, numeric(1))
}
s_whole <- statistic(whole)
s_per_provider <- statistic(per_provider)
moved <- which(s_whole != s_per_provider)
relative <- abs(s_whole - s_per_provider)[moved] / abs(s_per_provider[moved])
message <- paste(
  sprintf("R %s.%s, BLAS %s, LAPACK %s.", R.version$major, R.version$minor,
          if (nzchar(extSoftVersion()[["BLAS"]])) extSoftVersion()[["BLAS"]] else "R's internal", La_version()),
  sprintf("Linear predictor: %d of %d rows differ between the whole design and per-provider products (largest %.3g).",
          sum(whole != per_provider), length(whole), max(abs(whole - per_provider))),
  sprintf("The model's stored linear predictor equals the whole-design product: %s.",
          identical(unname(fit$linear_predictor), whole)),
  sprintf("Exact test, null 0: the statistics of %d of %d providers differ%s.", length(moved), length(blocks),
          if (length(moved)) sprintf(", by at most %.3g relative", max(relative)) else ""))
cat(message, "\n")
cat(sprintf("::notice title=Linear predictor by provider (D-53)::%s\n", gsub("%", "%25", message, fixed = TRUE)))
