# CoxPH brief, §3.3 rows 10 and 13: what changed in glmnet's Cox cross-validation between 4.1-8 (the
# version pprof_py was validated against) and the installed glmnet. glmnet 4.1-8's cv.coxnet() divides
# each fold's deviance by the fold's weighted number of events,
#   weights = as.vector(tapply(weights * status, foldid, sum))
# (https://raw.githubusercontent.com/cran/glmnet/4.1-8/R/cv.coxnet.R); this script prints the
# installed version's line and compares the cross-validation results that 02 regenerated with the
# committed 4.1-8 results on the same data and fold IDs.
# Found on 2026-10-07 with glmnet 5.1: each fold's deviance is divided by the fold's total weight, so
# cvm shrinks by the event fraction, the standard errors change, and lambda.1se moves from 0.0604 to
# 0.0876 while lambda.min stays. glmnet 5.1 still defaults to Breslow ties and warns that Efron is coming.
# Run from the repository root, after 02: Rscript dev/design/coxph-facts/04_glmnet_cv_normalization.R <output file>
args <- commandArgs(trailingOnly = TRUE)
pprof_py <- normalizePath(Sys.getenv("PPROF_PY", "../../pprof_py"), winslash = "/", mustWork = TRUE)
scratch <- Sys.getenv("COXPH_FACTS_SCRATCH")
if (!nzchar(scratch)) stop("Set COXPH_FACTS_SCRATCH (see README.md)")
committed <- file.path(pprof_py, "pprof_py", "r_reference", "results")
regenerated <- file.path(scratch, "r_reference", "results")
source_lines <- deparse(get("cv.coxnet", asNamespace("glmnet")))
data <- read.csv(file.path(pprof_py, "pprof_py", "r_reference", "data", "penalized_wide.csv"))
status <- if ("status" %in% names(data)) data$status else data$event
old <- read.csv(file.path(committed, "penalized_wide_cv.csv"))
new <- read.csv(file.path(regenerated, "penalized_wide_cv.csv"))
old_sel <- read.csv(file.path(committed, "penalized_wide_cv_selected.csv"))
new_sel <- read.csv(file.path(regenerated, "penalized_wide_cv_selected.csv"))
ratio <- new$cvm / old$cvm
lines <- c(
  sprintf("Installed glmnet %s; formals(glmnet)$cox.ties: %s", packageVersion("glmnet"),
          deparse(formals(glmnet::glmnet)$cox.ties)),
  "The installed cv.coxnet()'s fold weights:",
  paste0("    ", trimws(grep("tapply\\(weights", source_lines, value = TRUE))),
  "",
  sprintf("penalized_wide: %d rows, %d events (event fraction %.4f), %d lambda values",
          nrow(data), sum(status), mean(status), nrow(old)),
  sprintf("cvm installed / cvm 4.1-8 over the lambda path: min %.4f, max %.4f", min(ratio), max(ratio)),
  sprintf("cvsd installed / cvsd 4.1-8 over the lambda path: min %.4f, max %.4f",
          min(new$cvsd / old$cvsd), max(new$cvsd / old$cvsd)),
  "",
  "| | lambda.min | lambda.1se |",
  "|---|---|---|",
  sprintf("| glmnet 4.1-8 (committed) | %.6g | %.6g |", old_sel$lambda_min, old_sel$lambda_1se),
  sprintf("| glmnet %s (regenerated) | %.6g | %.6g |", packageVersion("glmnet"), new_sel$lambda_min, new_sel$lambda_1se))
writeLines(lines, args[1])
