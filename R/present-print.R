# print() methods of models and results (ARCHITECTURE §D.3). Printing formats numbers for
# display only; objects keep them unrounded.

#' @export
print.pprof_model <- function(x, ...) {
  method <- if (is.null(x$spec$method)) "" else sprintf(" (%s)", x$spec$method)
  cat(sprintf("<pprof model: %s%s>\n", x$spec$family, method))
  cat(sprintf("%s observations of %s providers", present_count(x$n_obs), present_count(x$n_providers)))
  if (isTRUE(x$n_excluded_providers > 0L)) {
    cat(sprintf("; %s providers with %s observations excluded", present_count(x$n_excluded_providers),
                present_count(x$n_excluded_obs)))
  }
  cat("\n")
  convergence <- x$convergence
  if (!is.null(convergence$iterations)) {
    status <- if (isTRUE(convergence$converged)) "Converged" else "Not converged"
    cat(sprintf("%s after %d iterations (stop rule \"%s\", tol %s)\n", status, as.integer(convergence$iterations),
                convergence$stop_rule, format(convergence$tol)))
  }
  if (length(x$coefficients) > 0L) {
    cat("Coefficients:\n")
    print(signif(x$coefficients, 4))
  }
  invisible(x)
}

#' @export
print.pprof_summary <- function(x, ...) {
  cat(sprintf("<pprof summary: %s%s>\n", x$family, if (is.null(x$method)) "" else sprintf(" (%s)", x$method)))
  fit <- x$fit
  cat(sprintf("%s observations of %s providers\n", present_count(fit$n_obs), present_count(fit$n_providers)))
  cat(sprintf("Coefficients with Wald tests and %s intervals:\n", present_level(x$level)))
  print(present_coefficient_table(x$table), row.names = FALSE)
  statistics <- c("loglik", "aic", "bic", "auc")
  statistics <- statistics[!is.na(unlist(fit[statistics]))]
  if (length(statistics)) {
    values <- vapply(statistics, function(name) format(signif(fit[[name]], 6)), character(1))
    cat(paste(sprintf("%s %s", c(loglik = "log-likelihood", aic = "AIC", bic = "BIC", auc = "AUC")[statistics],
                      values), collapse = ", "), "\n", sep = "")
  }
  invisible(x)
}

# A data check lists the problems it found, one line for each kind (check_data()).
#' @export
print.pprof_data_check <- function(x, ...) {
  cat(sprintf("<pprof data check: %s observations, %s complete>\n", present_count(x$n_obs),
              present_count(x$n_complete)))
  missing <- x$table[x$table$n_missing > 0L, , drop = FALSE]
  design <- x$design
  correlations <- x$correlations
  high_vif <- design[!is.na(design$vif) & design$vif >= x$vif_threshold, , drop = FALSE]
  near_zero <- design$near_zero_variance & !design$zero_variance
  lines <- c(
    if (nrow(missing)) sprintf("Missing values: %s", paste(sprintf("%s (%s)", missing$variable,
                                                                   present_count(missing$n_missing)), collapse = ", ")),
    if (any(design$zero_variance)) {
      sprintf("No variation: %s", paste(design$term[design$zero_variance], collapse = ", "))
    },
    if (any(near_zero)) sprintf("Near-zero variance: %s", paste(design$term[near_zero], collapse = ", ")),
    if (nrow(correlations)) {
      sprintf("Correlation above %s in absolute value: %s", format(x$correlation_threshold),
              paste(sprintf("%s and %s (%s)", correlations$term_1, correlations$term_2,
                            format(signif(correlations$correlation, 4))), collapse = ", "))
    },
    if (nrow(high_vif)) {
      sprintf("Variance inflation factor of %s or more: %s", format(x$vif_threshold),
              paste(sprintf("%s (%s)", high_vif$term, format(signif(high_vif$vif, 4))), collapse = ", "))
    }
  )
  cat(if (length(lines)) lines else "No problems found.", sep = "\n")
  invisible(x)
}

#' @export
print.pprof_result <- function(x, n = 10L, ...) {
  cat(present_result_header(x), "\n", sep = "")
  table <- x$table
  shown <- utils::head(table, n)
  print(present_numeric_columns(shown), row.names = FALSE)
  if (nrow(table) > nrow(shown)) cat(sprintf("... %s more rows\n", present_count(nrow(table) - nrow(shown))))
  invisible(x)
}

present_count <- function(value) format(value, big.mark = ",", scientific = FALSE, trim = TRUE)

present_level <- function(level) sprintf("%s%%", format(100 * level, trim = TRUE))

present_result_header <- function(x) {
  null <- if (is.null(x$null_value)) "" else sprintf(", null %s", format(signif(x$null_value, 4)))
  interval <- if (is.null(x$interval) || identical(x$interval, "none")) {
    ""
  } else {
    sprintf("%s intervals at %s", x$interval, present_level(x$level))
  }
  switch(class(x)[1],
    pprof_provider_tests = sprintf("<pprof provider tests: %s, %s, level %s%s> flags: %s", x$test, x$alternative,
                                   present_level(x$level), null, present_flag_counts(x$table$flag)),
    pprof_provider_effects = sprintf("<pprof provider effects%s>", if (nzchar(interval)) paste(":", interval) else ""),
    pprof_measures = sprintf("<pprof standardized measures: %s; %s%s%s>", paste(x$standardization, collapse = ", "),
                             paste(x$measure, collapse = ", "), null,
                             if (nzchar(interval)) paste(";", interval) else ""),
    pprof_funnel = sprintf("<pprof funnel limits: %s, target %s, at %s>", x$measure, format(x$target),
                           paste(present_level(unique(x$table$level)), collapse = ", ")),
    pprof_profile = sprintf("<pprof provider profile: %s test, level %s%s> flags: %s", x$test, present_level(x$level),
                            null, present_flag_counts(x$table$flag)),
    pprof_coefficient_tests = sprintf("<pprof coefficient tests: %s>", x$test),
    sprintf("<%s>", class(x)[1])
  )
}

present_flag_counts <- function(flag) {
  counts <- c(sum(flag == 1L, na.rm = TRUE), sum(flag == 0L, na.rm = TRUE), sum(flag == -1L, na.rm = TRUE))
  text <- sprintf("%d higher, %d as expected, %d lower", counts[1], counts[2], counts[3])
  if (anyNA(flag)) text <- sprintf("%s, %d missing", text, sum(is.na(flag)))
  text
}

# Numbers rounded to 4 significant digits for display, and p-values formatted, with those
# below p_value_display_eps shown as "< 1e-10".
present_numeric_columns <- function(table) {
  for (column in names(table)) {
    if (identical(column, "p_value")) {
      table[[column]] <- format.pval(table[[column]], digits = 4L, eps = p_value_display_eps)
    } else if (is.double(table[[column]])) {
      table[[column]] <- signif(table[[column]], 4)
    }
  }
  table
}

# The coefficient table for display, with p-values formatted as the reference formats them
# (K-100).
present_coefficient_table <- function(table) {
  shown <- present_numeric_columns(table)
  shown$p_value <- format.pval(table$p_value, digits = p_value_display_digits, eps = p_value_display_eps)
  shown
}
