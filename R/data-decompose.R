# Within-between decomposition for correlated random-effect models (K-54).
#
# For each covariate v in `within_between`, the decomposition adds the column v_bar, the
# provider mean of v over every row of `data` with missing values of v removed, and
# v_within = v - v_bar. The means are computed before any row is dropped for missing values,
# as in the reference (D-13, signed off 2026-10-04), and rows with a missing provider form their
# own group, as dplyr::group_by() does in the reference; those rows are dropped later.

data_decompose_within_between <- function(data, provider, variables) {
  groups <- as.integer(factor(data[[provider]], exclude = NULL))
  new_columns <- c(paste0(variables, "_within"), paste0(variables, "_bar"))
  clash <- intersect(new_columns, names(data))
  if (length(clash) > 0L) {
    abort_invalid_input(
      sprintf("`data` already has columns named %s, which the within-between decomposition creates.",
              paste(clash, collapse = ", ")),
      arg = "within_between"
    )
  }
  for (variable in variables) {
    values <- data[[variable]]
    if (!is.numeric(values)) {
      abort_invalid_input(sprintf("`within_between` variable '%s' must be numeric.", variable), arg = "within_between")
    }
    group_means <- vapply(split(values, groups), function(x) mean(x, na.rm = TRUE), numeric(1))
    means <- unname(group_means[as.character(groups)])
    data[[paste0(variable, "_bar")]] <- means
    data[[paste0(variable, "_within")]] <- values - means
  }
  data
}

# The formula of the decomposed covariates, in the reference's term order (K-50): the
# within parts, then the provider means, then the other covariates in formula order.
data_decompose_formula <- function(terms, variables) {
  labels <- attr(terms, "term.labels")
  missing <- setdiff(variables, labels)
  if (length(missing) > 0L) {
    abort_invalid_input(
      sprintf("`within_between` must name covariate terms of `formula`; not terms: %s.",
              paste(missing, collapse = ", ")),
      arg = "within_between"
    )
  }
  right_side <- c(paste0(variables, "_within"), paste0(variables, "_bar"), setdiff(labels, variables))
  response <- as.list(attr(terms, "variables"))[[2L]]
  formula <- stats::reformulate(right_side, response = response, intercept = attr(terms, "intercept") == 1L)
  environment(formula) <- environment(terms)
  formula
}
