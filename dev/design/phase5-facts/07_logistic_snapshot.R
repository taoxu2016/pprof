# Phase 5, step 2: the guard that logistic FE and Firth results do not change.
#
# Saves every result of the logistic FE and Firth methods: the reference's method cases on
# logis_fe() and logis_firth() fits, run through the compatibility wrappers of the working
# tree with the fixtures' case runner, and a grid of calls of the new API on fits of the
# example data and of 12 seeded datasets with providers with no events or only events.
# Run before step 2 to save the snapshot, and after each commit of step 2 to compare: every
# result must be identical().
#
# Usage, from the repository root:
#   Rscript dev/design/phase5-facts/07_logistic_snapshot.R save <snapshot.rds>
#   Rscript dev/design/phase5-facts/07_logistic_snapshot.R compare <snapshot.rds> <report.txt>
args <- commandArgs(trailingOnly = TRUE)
mode <- args[1]
snapshot_file <- args[2]
Sys.setlocale("LC_COLLATE", "C")
suppressMessages(devtools::load_all(quiet = TRUE))
source("tests/testthat/helper-reference-cases.R")
results <- list()
keep <- function(label, expr) {
  results[[label]] <<- tryCatch(suppressWarnings(suppressMessages(expr)),
                                error = function(e) list(error = class(e), message = conditionMessage(e)))
}

# --- The reference's method cases on logis_fe() and logis_firth() fits ---------------------
fixture_dir <- "tests/testthat/fixtures/reference"
manifest <- jsonlite::read_json(file.path(fixture_dir, "manifest.json"))
datasets <- list()
for (entry in manifest$datasets) datasets[[entry$name]] <- readRDS(file.path(fixture_dir, entry$file))
fixtures <- lapply(manifest$cases, function(entry) readRDS(file.path(fixture_dir, entry$file)))
names(fixtures) <- vapply(manifest$cases, `[[`, "", "id")
parent_of <- function(case) {
  ids <- unlist(lapply(case$args, function(a) if (inherits(a, "pprof_ref_fit") || inherits(a, "pprof_ref_value")) a$case_id))
  if (length(ids)) ids[1] else NA_character_
}
root_fun <- function(id) {
  case <- fixtures[[id]]$case
  parent <- parent_of(case)
  if (is.na(parent)) case$fun else root_fun(parent)
}
logistic <- names(fixtures)[vapply(names(fixtures), function(id) root_fun(id) %in% c("logis_fe", "logis_firth"), logical(1))]
case_results <- list()
for (id in logistic) {
  case_results[[id]] <- suppressWarnings(suppressMessages(run_reference_case(fixtures[[id]]$case, datasets, case_results)))
  # Processed as the fixtures process values (ggplot objects become their layers' data), but
  # with every vector in full.
  results[[paste("case", id)]] <- reference_result_record(case_results[[id]], .Machine$integer.max)
}

# --- The new API on fits of the example data and of seeded datasets -------------------------
seeded <- function(seed) {
  set.seed(seed)
  m <- 25
  sizes <- sample(15:60, m, replace = TRUE)
  provider <- rep(seq_len(m), sizes)
  z <- matrix(rnorm(length(provider) * 3), ncol = 3, dimnames = list(NULL, paste0("x", 1:3)))
  y <- rbinom(length(provider), 1, plogis(-0.8 + rnorm(m, 0, 0.6)[provider] + drop(z %*% c(0.5, -0.4, 0.2))))
  y[provider == 1] <- 0
  y[provider == 2] <- 1
  data.frame(y = y, hospital = sprintf("H%02d", provider), z)
}
example <- data.frame(y = datasets$binary_example$Y, hospital = datasets$binary_example$ProvID,
                      datasets$binary_example[paste0("z", 1:5)])
inputs <- c(list(example = list(data = example, formula = y ~ z1 + z2 + z3 + z4 + z5)),
            lapply(stats::setNames(20261005 + 1:12, sprintf("seed%d", 1:12)),
                   function(s) list(data = seeded(s), formula = y ~ x1 + x2 + x3)))
for (name in names(inputs)) {
  input <- inputs[[name]]
  for (fitter in c("fit_logistic_fe", "fit_logistic_firth")) {
    fit <- suppressWarnings(do.call(fitter, list(input$formula, input$data, "hospital", keep_data = TRUE)))
    tag <- function(...) paste(name, fitter, ...)
    for (null in list("median", 0)) {
      for (alternative in c("two.sided", "greater", "less")) {
        for (test in c("exact", "score", "wald")) {
          keep(tag("test", test, null, alternative), test_providers(fit, test, null = null, alternative = alternative))
        }
        keep(tag("test standard", null, alternative),
             test_providers(fit, "score", null = null, alternative = alternative, score_type = "standard"))
        keep(tag("test bootstrap", null, alternative),
             withr::with_seed(1, test_providers(fit, "bootstrap", null = null, alternative = alternative, n_resamples = 200)))
        for (interval in c("none", "exact", "score", "wald")) {
          keep(tag("measures", interval, null, alternative),
               standardize_providers(fit, c("indirect", "direct"), c("ratio", "rate"), null = null, interval = interval,
                                     alternative = alternative, level = 0.9))
        }
      }
      keep(tag("funnel", null), funnel_limits(fit, level = c(0.95, 0.99), null = null))
    }
    for (interval in c("none", "exact", "score", "wald")) {
      keep(tag("effects", interval), provider_effects(fit, interval = interval, level = 0.9))
    }
    keep(tag("profile"), profile_providers(fit, interval = "score"))
    keep(tag("coefficients wald"), test_coefficients(fit, "wald", level = 0.9))
    keep(tag("confint"), confint(fit, level = 0.9))
    keep(tag("summary"), summary(fit))
    keep(tag("tidy"), tidy(fit))
    keep(tag("glance"), glance(fit))
    if (name %in% c("example", "seed1")) {
      keep(tag("coefficients lr"), test_coefficients(fit, "lr"))
      keep(tag("coefficients score"), test_coefficients(fit, "score"))
    }
  }
}

if (identical(mode, "save")) {
  saveRDS(results, snapshot_file)
  cat(sprintf("Saved %d results to %s\n", length(results), snapshot_file))
} else {
  saved <- readRDS(snapshot_file)
  labels <- union(names(saved), names(results))
  same <- vapply(labels, function(label) identical(saved[[label]], results[[label]]), logical(1))
  report <- c(sprintf("%d results compared; %d identical; %d differ or are missing", length(labels), sum(same),
                      sum(!same)), paste("differs:", labels[!same]))
  writeLines(report, args[3])
}
