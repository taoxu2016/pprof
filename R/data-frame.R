# Model frame, response, and design matrix (K-03, K-04).

# Listwise deletion over the response, provider, and covariate columns only (K-03): the
# positions of the rows of `data` that are complete in `columns`.
data_complete_rows <- function(data, columns) {
  which(stats::complete.cases(data[columns]))
}

# The model frame of the complete rows. Unused factor levels are kept, as the reference's
# model.matrix() on the complete rows keeps them (K-04). Rows whose transformed variables are
# missing (for example log() of a negative value) are dropped as na.omit() does; the
# reference has no transformed terms (D-18), so this never applies to its inputs. Returns the
# frame and the positions in `data` of its rows.
data_model_frame <- function(terms, data, rows) {
  frame <- stats::model.frame(terms, data = data[rows, , drop = FALSE], na.action = stats::na.omit,
                              drop.unused.levels = FALSE)
  omitted <- attr(frame, "na.action")
  if (!is.null(omitted)) rows <- rows[-as.integer(omitted)]
  list(frame = frame, rows = rows)
}

data_response <- function(frame) {
  response <- stats::model.response(frame)
  if (is.null(response) || !is.null(dim(response)) || !(is.numeric(response) || is.logical(response))) {
    abort_invalid_input("The response in `formula` must be a numeric or logical vector.", arg = "formula")
  }
  unname(response)
}

# The covariate design matrix with model.matrix() (K-04). Without an intercept (fixed-effect
# models) the intercept column, which is always first because the formula keeps its
# intercept (data_parse_formula()), is dropped as the reference's `[, -1, drop = FALSE]`
# does; the `assign` and `contrasts` attributes are kept. Row names are not kept: the row
# map back to the input is `row_index`.
data_build_design <- function(terms, frame, intercept) {
  design <- stats::model.matrix(terms, frame)
  assign <- attr(design, "assign")
  contrasts <- attr(design, "contrasts")
  if (!intercept) {
    design <- design[, -1L, drop = FALSE]
    assign <- assign[-1L]
  }
  rownames(design) <- NULL
  attr(design, "assign") <- assign
  attr(design, "contrasts") <- contrasts
  design
}

# Rows of a design matrix, keeping the `assign` and `contrasts` attributes that matrix
# subsetting drops.
data_subset_design <- function(design, rows) {
  subset <- design[rows, , drop = FALSE]
  attr(subset, "assign") <- attr(design, "assign")
  attr(subset, "contrasts") <- attr(design, "contrasts")
  subset
}
