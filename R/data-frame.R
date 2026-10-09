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
#
# Two copies of every column are avoided when they would change nothing (on large data, they
# were behind the fit's memory peak at the Phase 3 gate): data[rows, ] when every row is
# complete, and na.omit(), which subsets the frame even when it omits nothing, when no value
# of the frame is missing; only the storage of the frame's row names differs, which the
# response and design do not keep. `inspect`, when given, sees the frame before any row is
# omitted: survival data check there that no Surv() response is missing (R/data-survival.R).
data_model_frame <- function(terms, data, rows, inspect = NULL) {
  subset <- if (length(rows) == nrow(data)) data else data[rows, , drop = FALSE]
  frame <- stats::model.frame(terms, data = subset, na.action = stats::na.pass, drop.unused.levels = FALSE)
  if (!is.null(inspect)) inspect(frame)
  if (anyNA(frame)) {
    frame <- stats::model.frame(terms, data = subset, na.action = stats::na.omit, drop.unused.levels = FALSE)
  }
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
# map back to the input is `row_index`. When every covariate is numeric, the design is built
# from terms without an intercept instead, which gives the same columns and `assign`, since
# only the coding of factors (and of logical and character variables, which model.matrix()
# treats as factors) depends on the intercept; dropping the column would copy the design.
data_build_design <- function(terms, frame, intercept) {
  if (!intercept && ncol(frame) > 1L && all(vapply(frame[-1L], is.numeric, logical(1)))) {
    attr(terms, "intercept") <- 0L
    design <- stats::model.matrix(terms, frame)
    rownames(design) <- NULL
    return(design)
  }
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
# subsetting drops. Selecting every row in order (positions 1 to n, or all TRUE) returns the
# design itself rather than a copy, as for data already sorted by provider with no provider
# screened out.
data_subset_design <- function(design, rows) {
  n <- nrow(design)
  every_row <- length(rows) == n && (if (is.logical(rows)) all(rows) else identical(as.integer(rows), seq_len(n)))
  if (every_row) return(design)
  subset <- design[rows, , drop = FALSE]
  attr(subset, "assign") <- attr(design, "assign")
  attr(subset, "contrasts") <- attr(design, "contrasts")
  subset
}
