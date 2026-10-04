# Compatibility methods for the linear_re, logis_re, linear_cre, and logis_cre objects of
# pprof 1.0.3 (ARCHITECTURE §I.2, DEC-032, DEC-049): one implementation per method for the
# four classes, which rebuilds the model from the old object, calls the new API, and returns
# the old shapes (BEHAVIOR_SPECS §7.3, §8.3, §8.4, §9.3, §9.4, §10, §16), built in the
# reference's order of operations. The labels of each class are those of the reference,
# including its inconsistencies (D-33).

# --- Implementations -------------------------------------------------------------------------

# The labels of each class's interval tables (`model` attributes) and summaries.
compat_mixed_labels <- list(
  linear_re = list(logistic = FALSE, model = "RE linear"),
  logis_re = list(logistic = TRUE, model = "RE logis", indirect_rate = "RE logis"),
  linear_cre = list(logistic = FALSE, model = "CRE linear"),
  logis_cre = list(logistic = TRUE, model = "CRE logis", indirect_rate = "RE logis")
)

# test() for the four classes (R/test.linear_re.R, R/test.logis_re.R, and their CRE
# versions): the Wald test with the standard deviations of K-69 (linear RE) or K-70.
compat_mixed_test <- function(fit, parm, level = 0.95, null = 0, alternative = "two.sided") {
  null_value <- compat_mixed_null(null)
  compat_check_alternative(alternative, "Argument 'alternative' should be one of 'two.sided', 'less', 'greater'")
  model <- compat_model_from_mixed(fit, effect_sd = TRUE)
  table <- test_providers(model, "wald", null = null_value, level = level, alternative = alternative)$table
  compat_wald_test_result(table, fit, parm)
}

# SM_output() for the four classes (R/SM_output.linear_re.R, R/SM_output.logis_re.R, and
# their CRE versions): predicted over expected (K-82, K-84), as differences for linear
# models and as ratios and rates for logistic models; `measure` and `threads` apply to
# logistic models only.
compat_mixed_sm_output <- function(fit, parm, stdz = "indirect", measure = c("rate", "ratio"), threads = 2,
                                   class = compat_mixed_class(fit)) {
  compat_check_object(fit, missing(fit), "fit", class)
  logistic <- compat_mixed_labels[[class]]$logistic
  compat_check_stdz(stdz)
  if (logistic && !"rate" %in% measure && !"ratio" %in% measure) {
    abort_invalid_input("Argument 'measure' NOT as required!", arg = "measure")
  }
  ind <- compat_parm_rows(fit, parm, "Argument 'parm' includes invalid elements.")
  model <- compat_model_from_mixed(fit)
  ids <- compat_provider_labels(fit)
  methods <- c("indirect", "direct")[c("indirect" %in% stdz, "direct" %in% stdz)]
  if (!logistic) return(compat_mixed_differences(model, methods, ids, ind))
  measures <- standardize_providers(model, methods, c("ratio", "rate"), threads = threads)$table
  response <- compat_response_vector(fit$observation)
  return_list <- list()
  oe_list <- list()
  for (method in methods) {
    ratio <- compat_measure_rows(measures, method, "ratio")
    rate <- compat_measure_rows(measures, method, "rate")
    title <- paste0(toupper(substr(method, 1L, 1L)), substring(method, 2L))
    oe <- if (identical(method, "indirect")) {
      data.frame(Obs.indirect_provider = ratio$observed, Exp.indirect_provider = ratio$expected)
    } else {
      data.frame(Obs_all = compat_typed_sum(ratio$observed, response), Exp.direct_all = ratio$expected)
    }
    rownames(oe) <- ids
    oe_list[[paste0("OE_", method)]] <- oe[ind, ]
    if ("ratio" %in% measure) {
      return_list[[paste0(method, ".ratio")]] <- compat_measure_matrix(ratio$estimate, ids,
                                                                       paste0(title, "_standardized.ratio"), ind)
    }
    if ("rate" %in% measure) {
      return_list[[paste0(method, ".rate")]] <- compat_measure_matrix(rate$estimate, ids,
                                                                      paste0(title, "_standardized.rate"), ind)
    }
  }
  return_list$OE <- oe_list
  return_list
}

# The standardized differences of linear RE and CRE models (K-84) in the shape of the
# reference's SM_output(): the indirect OE table named by provider, the direct one with the
# automatic row names of data.frame().
compat_mixed_differences <- function(model, methods, ids, ind) {
  measures <- standardize_providers(model, methods, "difference")$table
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

# confint() for the four classes (R/confint.linear_re.R, R/confint.logis_re.R, and their CRE
# versions): Wald intervals for the provider effects (`option = "alpha"`, two-sided) or for
# the standardized measures (K-93, K-94). The direct limits of logistic models use one
# thread, where the reference hard-codes 4 (D-21; the results do not depend on it, K-85).
# `measure` applies to logistic models only.
compat_mixed_confint <- function(object, parm, level = 0.95, option = "SM", measure = c("rate", "ratio"),
                                 stdz = "indirect", alternative = "two.sided", class = compat_mixed_class(object)) {
  compat_check_object(object, missing(object), "object", class)
  labels <- compat_mixed_labels[[class]]
  if (!(identical(option, "alpha") || identical(option, "SM"))) {
    abort_invalid_input("Argument 'option' should be 'alpha' or 'SM'", arg = "option")
  }
  compat_check_stdz(stdz)
  if (identical(option, "alpha") && !identical(alternative, "two.sided")) {
    abort_invalid_input("Provider effect (option = 'alpha') only supports two-sided confidence intervals.",
                        arg = "alternative")
  }
  compat_check_alternative(alternative, "Argument 'alternative' should be one of 'two.sided', 'less', 'greater'")
  model <- compat_model_from_mixed(object, effect_sd = TRUE)
  ids <- compat_provider_labels(object)
  ind <- compat_parm_rows(object, parm)
  if (identical(option, "alpha")) {
    table <- provider_effects(model, interval = "wald", level = level)$table
    out <- data.frame(alpha = table$estimate, alpha.Lower = table$lower, alpha.Upper = table$upper, row.names = ids)
    colnames(out) <- c("Estimate", "alpha.Lower", "alpha.Upper")
    attr(out, "description") <- "Provider Effects"
    return(out[ind, ])
  }
  methods <- c("indirect", "direct")[c("indirect" %in% stdz, "direct" %in% stdz)]
  scales <- if (labels$logistic) c("ratio", "rate") else "difference"
  result <- standardize_providers(model, methods, scales, interval = "wald", level = level, alternative = alternative,
                                  threads = 1)
  # D-33: the RE and CRE tables give the level as a proportion ("0.95 %").
  annotate <- function(table, description, model_label, population_rate = NULL) {
    attr(table, "confidence_level") <- paste(level, "%")
    attr(table, "type") <- compat_interval_type(alternative)
    attr(table, "description") <- description
    attr(table, "model") <- model_label
    if (!is.null(population_rate)) attr(table, "population_rate") <- population_rate
    table
  }
  return_list <- list()
  for (method in methods) {
    title <- paste0(toupper(substr(method, 1L, 1L)), substring(method, 2L))
    if (!labels$logistic) {
      rows <- compat_measure_rows(result$table, method, "difference")
      out <- data.frame(SM = rows$estimate, Lower = rows$lower, Upper = rows$upper, row.names = ids)
      colnames(out) <- c(paste0(title, ".Difference"), paste0(method, ".Lower"), paste0(method, ".Upper"))
      out <- annotate(out, paste(title, "Standardized Difference"), labels$model)
      return_list[[paste0("CI.", method)]] <- out[ind, ]
      next
    }
    if ("ratio" %in% measure) {
      rows <- compat_measure_rows(result$table, method, "ratio")
      out <- data.frame(SR = rows$estimate, Lower = rows$lower, Upper = rows$upper, row.names = ids)
      colnames(out) <- c(paste0(title, ".Ratio"), "Ratio.Lower", "Ratio.Upper")
      out <- annotate(out, paste(title, "Standardized Ratio"), labels$model)
      return_list[[paste0("CI.", method, "_ratio")]] <- out[ind, ]
    }
    if ("rate" %in% measure) {
      rows <- compat_measure_rows(result$table, method, "rate")
      out <- data.frame(SR = rows$estimate, Lower = rows$lower, Upper = rows$upper, row.names = ids)
      colnames(out) <- c(paste0(title, ".Rate"), "Rate.Lower", "Rate.Upper")
      model_label <- if (identical(method, "indirect")) labels$indirect_rate else labels$model
      out <- annotate(out, paste(title, "Standardized Rate"), model_label, result$population_rate)
      return_list[[paste0("CI.", method, "_rate")]] <- out[ind, ]
    }
  }
  return_list
}

# summary() for the four classes (R/summary.linear_re.R, R/summary.logis_re.R, and their
# CRE versions): the intercept included; t p-values with n - p - m + 1 degrees of freedom for
# linear models (K-104) and 2 (1 - pnorm(z)) for logistic models (K-105, D-31); lme4's Wald
# intervals. `parm` names the intercept "(intercept)" (D-44).
compat_mixed_summary <- function(object, parm, level = 0.95, null = 0, class = compat_mixed_class(object)) {
  compat_check_object(object, missing(object), "object", class)
  chars <- object$char_list
  labels <- if (is.null(chars$within_terms)) {
    c("(intercept)", chars$Z.char)
  } else {
    c("(intercept)", chars$within_terms, chars$between_terms, chars$other.vars)
  }
  model <- compat_model_from_mixed(object)
  out <- compat_summary_table(test_coefficients(model, "wald", level = level, null = null)$table)
  out[compat_summary_rows(parm, labels), ]
}
