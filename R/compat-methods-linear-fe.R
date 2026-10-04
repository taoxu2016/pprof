# Compatibility methods for the linear_fe objects of pprof 1.0.3 (ARCHITECTURE §I.2, DEC-032,
# DEC-049): each rebuilds the model from the old object, calls the new API, and returns the
# old shapes (BEHAVIOR_SPECS §7.2, §8.2, §9.2, §10, §16), building them in the reference's
# order of operations so that row names, column names, and attributes are the reference's.

# test.linear_fe() (R/test.linear_fe.R in pprof 1.0.3): the Wald test with the normal
# distribution for the simplified provider variance and t(n - m - p) for the full one (K-68).
compat_linear_fe_test <- function(fit, parm, level = 0.95, null = "median", alternative = "two.sided") {
  null_value <- compat_linear_null(null)
  compat_check_alternative(alternative, "Argument 'alternative' should be one of 'two.sided', 'less', 'greater'")
  model <- compat_model_from_linear_fe(fit, require_variance_type = TRUE)
  table <- test_providers(model, "wald", null = null_value, level = level, alternative = alternative)$table
  compat_wald_test_result(table, fit, parm)
}

# SM_output.linear_fe() (R/SM_output.linear_fe.R): the indirect and direct differences
# (K-83) with the observed and expected outcomes. The direct OE table has the automatic row
# names of data.frame(), as in the reference.
compat_linear_fe_sm_output <- function(fit, parm, stdz = "indirect", null = "median") {
  compat_check_object(fit, missing(fit), "fit", "linear_fe")
  compat_check_stdz(stdz)
  ind <- compat_parm_rows(fit, parm, "Argument 'parm' includes invalid elements.")
  null_value <- compat_linear_null(null)
  model <- compat_model_from_linear_fe(fit)
  ids <- compat_provider_labels(fit)
  methods <- c("indirect", "direct")[c("indirect" %in% stdz, "direct" %in% stdz)]
  measures <- standardize_providers(model, methods, "difference", null = null_value)$table
  return_list <- list()
  oe_list <- list()
  if ("indirect" %in% methods) {
    rows <- compat_measure_rows(measures, "indirect", "difference")
    return_list$indirect.difference <- compat_measure_matrix(rows$estimate, ids, "Indirect_standardized.difference",
                                                             ind)
    oe <- data.frame(Obs = stats::setNames(rows$observed, ids), Exp = stats::setNames(rows$expected, ids))
    oe_list$OE_indirect <- oe[ind, ]
  }
  if ("direct" %in% methods) {
    rows <- compat_measure_rows(measures, "direct", "difference")
    return_list$direct.difference <- compat_measure_matrix(rows$estimate, ids, "Direct_standardized.difference", ind)
    oe <- data.frame(Obs = rows$observed[1], Exp = rows$expected)
    oe_list$OE_direct <- oe[ind, ]
  }
  return_list$OE <- oe_list
  return_list
}

# An m x 1 matrix of the reference's standardized measures, named by provider and measure,
# with the rows `ind`.
compat_measure_matrix <- function(values, ids, column, ind) {
  out <- matrix(values)
  dimnames(out) <- list(ids, column)
  out[ind, , drop = FALSE]
}

# confint.linear_fe() (R/confint.linear_fe.R): Wald intervals for the provider effects
# (`option = "gamma"`, two-sided) or for the standardized differences, with t(n - m - p)
# for the simplified provider variance and the normal distribution for the full one, the
# reverse of the tests (K-92, D-32, awaiting sign-off).
compat_linear_fe_confint <- function(object, parm, level = 0.95, option = "SM", stdz = "indirect", null = "median",
                                     alternative = "two.sided") {
  compat_check_object(object, missing(object), "object", "linear_fe")
  if (!(identical(option, "gamma") || identical(option, "SM"))) {
    abort_invalid_input("Argument 'option' should be 'gamma' or 'SM'", arg = "option")
  }
  compat_check_stdz(stdz)
  if (identical(option, "gamma") && !identical(alternative, "two.sided")) {
    abort_invalid_input("Provider effect (option = 'gamma') only supports two-sided confidence intervals.",
                        arg = "alternative")
  }
  compat_check_alternative(alternative, "Argument 'alternative' should be one of 'two.sided', 'less', 'greater'.")
  model <- compat_model_from_linear_fe(object, require_variance_type = TRUE)
  ids <- compat_provider_labels(object)
  ind <- compat_parm_rows(object, parm, "Argument 'parm' includes invalid elements.")
  if (identical(option, "gamma")) {
    table <- provider_effects(model, interval = "wald", level = level)$table
    out <- data.frame(gamma = table$estimate, gamma.Lower = table$lower, gamma.Upper = table$upper, row.names = ids)
    colnames(out) <- c("gamma", "gamma.Lower", "gamma.Upper")
    attr(out, "description") <- "Provider Effects"
    return(out[ind, ])
  }
  null_value <- compat_linear_null(null)
  methods <- c("indirect", "direct")[c("indirect" %in% stdz, "direct" %in% stdz)]
  measures <- standardize_providers(model, methods, "difference", null = null_value, interval = "wald", level = level,
                                    alternative = alternative)$table
  return_list <- list()
  for (method in methods) {
    rows <- compat_measure_rows(measures, method, "difference")
    title <- paste0(toupper(substr(method, 1L, 1L)), substring(method, 2L))
    out <- data.frame(SM = rows$estimate, Lower = rows$lower, Upper = rows$upper, row.names = ids)
    colnames(out) <- c(paste0(title, ".Difference"), paste0(method, ".Lower"), paste0(method, ".Upper"))
    attr(out, "confidence_level") <- paste(level * 100, "%")
    attr(out, "type") <- compat_interval_type(alternative)
    attr(out, "description") <- paste(title, "Standardized Difference")
    attr(out, "model") <- "FE linear"
    return_list[[paste0("CI.", method)]] <- out[ind, ]
  }
  return_list
}

# summary.linear_fe() (R/summary.linear_fe.R): t tests and intervals with n - p - m degrees
# of freedom (K-103).
compat_linear_fe_summary <- function(object, parm, level = 0.95, null = 0) {
  compat_check_object(object, missing(object), "object", "linear_fe")
  model <- compat_model_from_linear_fe(object)
  out <- compat_summary_table(test_coefficients(model, "wald", level = level, null = null)$table)
  out[compat_summary_rows(parm, object$char_list$Z.char), ]
}
