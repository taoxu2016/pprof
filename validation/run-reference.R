# Run every reference fixture (core and full sets) against the in-repo package and write the
# equivalence report (brief §3.4, ARCHITECTURE §G.3).
#
# Usage, from the repository root:
#   Rscript validation/run-reference.R [report-file]
# Default report: validation/equivalence-report.md
#
# The report lists, per case, the outcome and the largest absolute and relative differences
# from the reference, and the providers whose reference p-value lies within the probability
# tolerance of a flag threshold (the boundary rule: their flags may legitimately differ).

args <- commandArgs(trailingOnly = TRUE)
report_file <- if (length(args)) args[[1]] else file.path("validation", "equivalence-report.md")
Sys.setenv(PPROF_REFERENCE_CORE = normalizePath(file.path("tests", "testthat", "fixtures", "reference"), winslash = "/"),
           PPROF_REFERENCE_FULL = normalizePath(file.path("validation", "fixtures", "reference"), winslash = "/"))
suppressMessages(devtools::load_all(quiet = TRUE))
for (f in c("helper-reference-cases.R", "helper-tolerances.R", "helper-equivalence.R", "helper-fixtures.R")) {
  source(file.path("tests", "testthat", f))
}
withr::local_collate("C")

# Largest differences between two processed values (doubles, including those in attributes
# such as the lme4 components of RE fits, and the summaries of double signatures), and how
# many double signatures have identical bit checksums, that is, bitwise identical vectors.
max_difference <- function(a, b) {
  out <- c(abs = 0, rel = 0, signatures = 0, bitwise = 0)
  walk <- function(x, y) {
    if (is.null(x) || is.null(y)) return(invisible())
    if (inherits(y, "pprof_reference_signature")) {
      if (identical(y$type, "double")) {
        walk(c(x$sum, x$min, x$max, x$sample), c(y$sum, y$min, y$max, y$sample))
        out[["signatures"]] <<- out[["signatures"]] + 1
        out[["bitwise"]] <<- out[["bitwise"]] + identical(x$bits_md5, y$bits_md5)
      }
      return(invisible())
    }
    if (is.list(y) && is.list(x) && length(x) == length(y)) {
      for (k in seq_along(y)) walk(x[[k]], y[[k]])
    } else if (is.double(y) && is.double(x) && length(x) == length(y)) {
      fin <- is.finite(x) & is.finite(y)
      if (any(fin)) {
        d <- abs(x[fin] - y[fin])
        out[["abs"]] <<- max(out[["abs"]], d)
        out[["rel"]] <<- max(out[["rel"]], d / pmax(abs(y[fin]), .Machine$double.xmin))
      }
    }
    for (nm in setdiff(names(attributes(y)), c("names", "row.names", "class", "dim", "dimnames", "levels"))) {
      walk(attr(x, nm, exact = TRUE), attr(y, nm, exact = TRUE))
    }
    invisible()
  }
  walk(a, b)
  out
}

rows <- list()
boundary <- list()
prob_tol <- reference_tolerance("probability")
for (set in c("core", "full")) {
  m <- reference_manifest(set)
  for (entry in m$cases) {
    id <- entry$id
    fixture <- reference_fixture(id, set)
    case <- fixture$case
    expected <- fixture$result
    status <- "compared"
    if (identical(case$tier, "lme4") && !reference_lme4_matches(set)$ok) status <- "skipped (lme4 or Matrix version differs)"
    diffs <- NULL
    mx <- c(abs = NA_real_, rel = NA_real_, signatures = NA_real_, bitwise = NA_real_)
    outcome <- NA_character_
    if (status == "compared") {
      res <- reference_run(id, set)
      actual <- reference_result_record(res, m$max_full_length)
      outcome <- actual$outcome
      if (!identical(actual$outcome, expected$outcome)) {
        status <- sprintf("FAIL: outcome %s, reference %s", actual$outcome, expected$outcome)
      } else if (identical(expected$outcome, "value")) {
        level <- if (!is.null(case$args$level)) case$args$level else 0.95
        diffs <- reference_compare(actual$value, expected$value, reference_tolerance(case$tier), alpha = 1 - level)
        mx <- max_difference(actual$value, expected$value)
        failures <- if (!is.null(diffs)) diffs[diffs$kind != "flag_boundary", , drop = FALSE] else NULL
        if (!is.null(failures) && nrow(failures)) status <- sprintf("FAIL: %s", paste(failures$path, collapse = ", "))
        if (!is.na(expected$iterations) && !identical(actual$iterations, expected$iterations)) {
          status <- sprintf("FAIL: %s iterations, reference %s", actual$iterations, expected$iterations)
        }
      }
    }
    rows[[length(rows) + 1]] <- data.frame(set = set, id = id, fun = case$fun, tier = case$tier, outcome = expected$outcome,
                                           iterations = if (is.na(expected$iterations)) "" else as.character(expected$iterations),
                                           max_abs = mx[["abs"]], max_rel = mx[["rel"]], signatures = mx[["signatures"]],
                                           bitwise = mx[["bitwise"]], status = status, stringsAsFactors = FALSE)
    # Boundary providers, from the reference values themselves.
    val <- expected$value
    if (identical(case$fun, "test") && is.data.frame(val) && all(c("flag", "p value") %in% names(val))) {
      level <- if (!is.null(case$args$level)) case$args$level else 0.95
      alpha <- 1 - level
      near <- which(abs(val[["p value"]] - alpha) <= prob_tol$atol + prob_tol$rtol * alpha)
      if (length(near)) {
        boundary[[length(boundary) + 1]] <- data.frame(set = set, id = id, provider = rownames(val)[near],
                                                       p_value = sprintf("%.17g", val[["p value"]][near]), alpha = sprintf("%.17g", alpha),
                                                       flag = as.character(val$flag[near]), stringsAsFactors = FALSE)
      }
    }
  }
}
tab <- do.call(rbind, rows)
bnd <- if (length(boundary)) do.call(rbind, boundary) else NULL

fmt <- function(x) ifelse(is.na(x), "", sprintf("%.3g", x))
lines <- c("# Equivalence report: package under test versus the pprof 1.0.3 reference", "",
           sprintf("Generated %s by `validation/run-reference.R` on %s, %s.", format(Sys.time(), tz = "UTC", usetz = TRUE),
                   R.version.string, utils::sessionInfo()$running),
           sprintf("Package under test: pprof %s from the working tree at commit %s.", as.character(utils::packageVersion("pprof")),
                   system2("git", c("rev-parse", "--short", "HEAD"), stdout = TRUE)),
           sprintf("Fixtures: core set generated at %s, full set generated at %s.",
                   substr(reference_manifest("core")$generator$git_commit, 1, 7), substr(reference_manifest("full")$generator$git_commit, 1, 7)),
           "", "## Summary", "",
           sprintf("- Cases: %d (core %d, full %d).", nrow(tab), sum(tab$set == "core"), sum(tab$set == "full")),
           sprintf("- Compared and matching: %d; failing: %d; skipped: %d.", sum(tab$status == "compared"),
                   sum(startsWith(tab$status, "FAIL")), sum(startsWith(tab$status, "skipped"))),
           sprintf("- Largest absolute difference over all compared values: %s; largest relative difference: %s.",
                   fmt(max(tab$max_abs, na.rm = TRUE)), fmt(max(tab$max_rel, na.rm = TRUE))),
           sprintf("- Long double vectors stored as signatures: %d; bitwise identical (same checksum of every value's bits): %d.",
                   as.integer(sum(tab$signatures, na.rm = TRUE)), as.integer(sum(tab$bitwise, na.rm = TRUE))),
           sprintf("- Reference errors reproduced: %d.", sum(tab$outcome == "error" & tab$status == "compared")),
           "", "## Providers within tolerance of a flag threshold", "",
           "A provider is listed when its reference p-value lies within the probability tolerance of alpha = 1 - level (brief §3.4). Its flag may differ between implementations without counting as a failure.", "")
if (is.null(bnd)) {
  lines <- c(lines, "None.", "")
} else {
  lines <- c(lines, "| Set | Case | Provider | p-value | alpha | Reference flag |", "|---|---|---|---|---|---|",
             sprintf("| %s | `%s` | %s | %s | %s | %s |", bnd$set, bnd$id, bnd$provider, bnd$p_value, bnd$alpha, bnd$flag), "")
}
bitwise_col <- ifelse(is.na(tab$signatures) | tab$signatures == 0, "", sprintf("%d of %d", as.integer(tab$bitwise), as.integer(tab$signatures)))
lines <- c(lines, "## Cases", "",
           "Bitwise signatures: of the long double vectors stored as signatures, how many are bitwise identical to the reference.", "",
           "| Set | Case | Function | Tier | Reference outcome | Iterations | Max abs diff | Max rel diff | Bitwise signatures | Status |",
           "|---|---|---|---|---|---|---|---|---|---|",
           sprintf("| %s | `%s` | %s | %s | %s | %s | %s | %s | %s | %s |", tab$set, tab$id, tab$fun, tab$tier, tab$outcome, tab$iterations,
                   fmt(tab$max_abs), fmt(tab$max_rel), bitwise_col, tab$status))
writeLines(lines, report_file)
cat(sprintf("Wrote %s: %d cases, %d failing, %d skipped, %d boundary providers\n", report_file, nrow(tab),
            sum(startsWith(tab$status, "FAIL")), sum(startsWith(tab$status, "skipped")), if (is.null(bnd)) 0L else nrow(bnd)))
