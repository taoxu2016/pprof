# Loading the pprofR reference fixtures and comparing the package with them (dev/reference/pprofr/README.md;
# LOGISTIC_L1_PLAN §3.4, §3.5; DEC-157, DEC-158).
#
# A pprofR fixture holds a case's synthetic data and its records, one per call of pprofR 0.2.0 (commit
# f23c288): list(format_version, id, description, data, records), each record list(call, seed, value, error,
# warnings, messages). The fixtures are the full set only, in validation/fixtures/pprofr/, read when present
# (no core set ships, DEC-153); PPROF_PPROFR_FIXTURES names another directory, for checking a newly generated
# set before it is committed.

pprofr_fixture_dir <- function() {
  override <- Sys.getenv("PPROF_PPROFR_FIXTURES")
  if (nzchar(override)) return(override)
  file.path(testthat::test_path(), "..", "..", "validation", "fixtures", "pprofr")
}

skip_without_pprofr_fixtures <- function() {
  testthat::skip_if_not(file.exists(file.path(pprofr_fixture_dir(), "manifest.json")),
                        "the pprofR fixtures (validation/fixtures/pprofr) are absent")
}

pprofr_fixture <- function(id) readRDS(file.path(pprofr_fixture_dir(), paste0(id, ".rds")))

# A record's value; a record that is pprofR's error fails the test that reads it.
pprofr_value <- function(fx, name) {
  record <- fx$records[[name]]
  if (is.null(record)) stop("No record ", name, " in the pprofR fixture ", fx$id, call. = FALSE)
  if (!is.null(record$error)) {
    stop("The record ", name, " of ", fx$id, " is pprofR's error: ", record$error, call. = FALSE)
  }
  record$value
}

# The tier of each kind of result in the comparisons with pprofR (LOGISTIC_L1_PLAN §3.4), as the calibration
# report validates it (validation/pprofr-calibration-report.md):
#   - counts: iteration counts, inclusion, indicators, sizes, and flags are discrete;
#   - estimates: the package reproduces pprofR's iteration path, as for pprof 1.0.3 (the brief's §3.5);
#   - closed-form results: variances given the estimates, robust and stabilized standard errors, z
#     statistics, measures and their standard errors, direct standardization, and the measure test;
#   - p-values: the probability tier, and the exact test's statistic on its tail probability (DEC-083);
#   - limits of the exact and score intervals: pprof's root finder against pprofR's (D-85).
pprofr_tiers <- c(counts = "exact", estimates = "iterative", closed_form = "closed_form", p_values = "probability",
                  limits = "root")

# The ratio of the largest difference to the tier's allowance, as cox_tier_ratio() computes it.
pprofr_tier_ratio <- function(a, b, tier) {
  a <- as.double(unlist(a))
  b <- as.double(unlist(b))
  if (length(a) != length(b)) return(Inf)
  if (!length(a)) return(0)
  tolerance <- reference_tolerance(tier)
  same <- (is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & a == b)
  ratio <- abs(a - b) / (tolerance$atol + tolerance$rtol * abs(b))
  ratio[same] <- 0
  ratio[is.na(ratio)] <- Inf
  max(ratio)
}

# Each comparison is recorded when the option pprof.pprofr_comparisons holds an environment
# (validation/run-pprofr-reference.R), with its label, tier, ratio, and the register entry that explains an
# expected difference.
pprofr_record <- function(label, tier, ratio, expected, entry = "") {
  log <- getOption("pprof.pprofr_comparisons")
  if (is.environment(log)) {
    log$rows[[length(log$rows) + 1L]] <- data.frame(file = if (is.null(log$file)) NA_character_ else log$file,
                                                    label = label, tier = tier, ratio = ratio, expected = expected,
                                                    entry = entry, stringsAsFactors = FALSE)
  }
  invisible()
}

# One comparison under a tier, as one expectation: `a` matches `b`, or, with `differ` naming the register entry
# that decides the difference, differs from it beyond the tier. Both are compared as plain numbers, in order:
# the callers align them by provider or covariate, and pprofR's names and attributes are not the package's.
expect_pprofr_tier <- function(a, b, tier, label, differ = NULL) {
  a <- as.double(unlist(a, use.names = FALSE))
  b <- as.double(unlist(b, use.names = FALSE))
  matches <- is.null(reference_compare(a, b, reference_tolerance(tier)))
  pprofr_record(label, tier, pprofr_tier_ratio(a, b, tier), if (is.null(differ)) "match" else "differ",
                if (is.null(differ)) "" else differ)
  if (is.null(differ)) {
    expect(matches, sprintf("%s: differs from pprofR beyond %s", label, tier))
  } else {
    expect(!matches, sprintf("%s: expected to differ beyond %s (%s)", label, tier, differ))
  }
}

# Providers whose pprofR p-value lies within the probability tier of the test's level: their flags may
# differ without a failure, and the report lists them (the brief's §3.5).
pprofr_near_threshold <- function(p, alpha) {
  tolerance <- reference_tolerance("probability")
  abs(p - alpha) <= tolerance$atol + tolerance$rtol * alpha
}

pprofr_record_near <- function(label, providers) {
  log <- getOption("pprof.pprofr_comparisons")
  if (is.environment(log) && length(providers)) {
    log$near[[length(log$near) + 1L]] <- data.frame(label = label, provider = as.character(providers),
                                                    stringsAsFactors = FALSE)
  }
  invisible()
}

# pprofR's names of the stopping rules and methods in the package's (NAMING §4).
pprofr_stop_rule <- c(or = "any", beta = "coefficients", all = "all", relch = "relative_loglik",
                      ratch = "relative_gain")
pprofr_method <- c(SerBIN = "serbin", BAN = "ban")
pprofr_test <- c(exact.poisbinom = "exact", exact.bootstrap = "bootstrap", score = "score", wald = "wald")

# pprofR's provider-test table as a data frame keyed by provider, its flag an integer.
pprofr_test_table <- function(x) {
  data.frame(provider_id = rownames(x), flag = as.integer(as.character(x$flag)), p_value = x$p, statistic = x$stat,
             std_error = if (is.null(x$se.gamma)) NA_real_ else x$se.gamma, stringsAsFactors = FALSE)
}
