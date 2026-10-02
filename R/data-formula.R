# Formula handling for the data layer (DEC-003).
#
# Every family uses one formula grammar: the response on the left and the covariates on the
# right, parsed with terms() rather than regular expressions, so that transformations,
# interactions, and factors work the same way everywhere (D-18). The provider is the
# separate `provider` argument, never a formula term.

# Terms of `formula` for `data`, with the checks every fit needs. `intercept = FALSE` is the
# fixed-effect case, where provider effects absorb the intercept: the formula must keep its
# intercept so that factors are coded with a reference level, as in the reference
# (`model.matrix(reformulate(Z.char), data)[, -1]`, K-04), and the data layer then drops the
# intercept column.
data_parse_formula <- function(formula, data, provider, intercept) {
  terms <- tryCatch(
    stats::terms(formula, data = data),
    error = function(e) {
      abort_invalid_input(sprintf("`formula` cannot be used with `data`: %s", conditionMessage(e)), arg = "formula")
    }
  )
  if (attr(terms, "response") != 1L) {
    abort_invalid_input("`formula` must have a response on its left-hand side.", arg = "formula")
  }
  if (!is.null(attr(terms, "offset"))) {
    abort_invalid_input("`formula` must not contain offset() terms.", arg = "formula")
  }
  if (!intercept && attr(terms, "intercept") == 0L) {
    abort_invalid_input(
      "Provider effects absorb the intercept in fixed-effect models: remove `- 1` or `+ 0` from `formula`.",
      arg = "formula"
    )
  }
  response <- as.list(attr(terms, "variables"))[[2L]]
  response_variables <- all.vars(response)
  covariate_variables <- unique(unlist(lapply(attr(terms, "term.labels"), function(label) all.vars(str2lang(label)))))
  variables <- unique(c(response_variables, covariate_variables))
  missing <- setdiff(variables, names(data))
  if (length(missing) > 0L) {
    abort_invalid_input(
      sprintf("`formula` uses variables that are not columns of `data`: %s.", paste(missing, collapse = ", ")),
      arg = "formula"
    )
  }
  if (provider %in% variables) {
    abort_invalid_input(sprintf("The provider column '%s' must not also appear in `formula`.", provider),
                        arg = "provider")
  }
  list(terms = terms, variables = variables, response_name = deparse1(response))
}
