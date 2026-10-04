# Data-layer equivalence with the reference (Phase 2 plan).
#
# Every reference fit stores its processed data in `data_include`: the rows it used, in
# provider order, with the response, the provider, the design columns, and for the logistic
# fixed-effect models the screening indicators. For each fit fixture, these helpers
# translate the reference's arguments into a data_prepare() call, as the compatibility
# wrappers will, rebuild `data_include` from the pprof_data object the way each reference
# fit builds it, and compare the two exactly. They also compare the design column names
# (`char_list`) and the provider order (the row names of the provider effects).

reference_fit_functions <- c("logis_fe", "logis_firth", "linear_fe", "linear_re", "logis_re", "linear_cre", "logis_cre")

# The data_prepare() arguments for a reference fit case, and what the rebuild needs to know.
reference_data_translation <- function(case, datasets) {
  # Arguments are looked up with [[ ]]: `args$Y` would partially match `Y.char`.
  args <- reference_resolve_args(case$args, datasets, list())
  fun <- case$fun
  fixed <- fun %in% c("logis_fe", "logis_firth", "linear_fe")
  correlated <- fun %in% c("linear_cre", "logis_cre")
  if (!is.null(args[["formula"]])) {
    interface <- "formula"
    terms <- stats::terms(args[["formula"]])
    labels <- attr(terms, "term.labels")
    provider_term <- if (fixed) grep("^id\\(", labels, value = TRUE) else grep("\\|", labels, value = TRUE)
    provider <- if (fixed) sub("^id\\((.*)\\)$", "\\1", provider_term) else trimws(sub(".*\\|", "", provider_term))
    response <- as.character(attr(terms, "variables"))[2]
    covariates <- setdiff(labels, provider_term)
    data <- args[["data"]]
  } else if (!is.null(args[["Y.char"]])) {
    interface <- "columns"
    response <- args[["Y.char"]]
    provider <- args[["ProvID.char"]]
    covariates <- if (correlated) c(args[["wb.char"]], args[["other.char"]]) else args[["Z.char"]]
    data <- args[["data"]]
  } else if (!correlated && !is.null(args[["Y"]])) {
    interface <- "vectors"
    # The reference's variable names, so that data.frame() and cbind() name the columns as
    # it does: data.frame(Y, ProvID, Z) in the FE fits, as.data.frame(cbind(Y, ProvID, Z)) in
    # the RE fits, which keeps each column's type only when Z is a data frame (D-11).
    data <- local({
      Y <- args[["Y"]] # nolint: object_name_linter.
      ProvID <- args[["ProvID"]] # nolint: object_name_linter.
      Z <- args[["Z"]] # nolint: object_name_linter.
      if (fixed) data.frame(Y, ProvID, Z) else as.data.frame(cbind(Y, ProvID, Z))
    })
    response <- "Y"
    provider <- "ProvID"
    covariates <- colnames(args[["Z"]])
  } else {
    stop("No data translation for case ", case$id)
  }
  logistic_fixed <- fun %in% c("logis_fe", "logis_firth")
  cutoff <- args[["cutoff"]]
  list(
    fun = fun, interface = interface, response = response, provider = provider, data = data,
    call = list(
      formula = stats::reformulate(covariates, response = response),
      data = data,
      provider = provider,
      within_between = if (correlated) args[["wb.char"]] else NULL,
      min_provider_size = if (logistic_fixed) (if (is.null(cutoff)) 10 else cutoff) else NULL,
      intercept = !fixed,
      event_counts = logistic_fixed
    )
  )
}

# `data_include` as the reference fit `fun` builds it, from a pprof_data object.
reference_rebuild_data_include <- function(prepared, translation) {
  fun <- translation$fun
  response <- prepared$response
  ids <- prepared$providers$provider_value[prepared$provider_index]
  # The reference keeps the input's row names, in their stored type (integer for
  # automatic row names). A tibble has no row names, so subsetting one renumbers its rows.
  row_names <- attr(translation$data, "row.names")[prepared$row_index]
  tibble_input <- inherits(translation$data, "tbl_df")
  design <- prepared$design
  attr(design, "assign") <- NULL
  attr(design, "contrasts") <- NULL
  if (fun %in% c("logis_fe", "logis_firth", "linear_fe")) {
    # data.frame(Y, ProvID, Z): the response and provider columns are named after the
    # reference's variables, and data.frame() rewrites non-syntactic names (D-18).
    out <- data.frame(response, ids, design)
    response_name <- if (translation$interface == "formula") translation$response else "Y"
    provider_name <- if (translation$interface == "vectors") "ProvID" else translation$provider
    names(out) <- make.names(c(response_name, provider_name, colnames(design)), unique = TRUE)
    if (fun != "linear_fe") {
      out$included <- 1
      out$no.events <- as.numeric(prepared$providers$no_events[prepared$provider_index])
      out$all.events <- as.numeric(prepared$providers$all_events[prepared$provider_index])
    }
    attr(out, "row.names") <- row_names
    return(out)
  }
  columns <- data.frame(response, ids, stringsAsFactors = FALSE)
  names(columns) <- c(translation$response, translation$provider)
  if (fun %in% c("linear_re", "logis_re")) {
    # as.data.frame(cbind(Y, ProvID, model.matrix(fit))) with one-column matrices of the
    # sorted data: their row names are the input row names, or, for a tibble, none, in
    # which case cbind() takes the positions 1..n from lme4's model matrix.
    if (tibble_input) {
      rownames(design) <- as.character(seq_len(nrow(design)))
    } else {
      attr(columns, "row.names") <- as.character(row_names)
      rownames(design) <- as.character(row_names)
    }
    return(as.data.frame(cbind(as.matrix(columns[1]), as.matrix(columns[2]), design)))
  }
  # CRE: the reference's data are a tibble, so the row names are the positions 1..n of the
  # model frame.
  rownames(design) <- as.character(seq_len(nrow(design)))
  if (fun == "linear_cre") {
    return(as.data.frame(cbind(as.matrix(columns[1]), as.matrix(columns[2]), design)))
  }
  as.data.frame(cbind(columns[1], columns[2], design))
}

# Design column names as the reference's `char_list` records them.
reference_char_list_covariates <- function(fixture_value, fun) {
  char_list <- fixture_value[["char_list"]]
  if (fun %in% c("linear_cre", "logis_cre")) {
    return(c(char_list[["within_terms"]], char_list[["between_terms"]], char_list[["other.vars"]]))
  }
  char_list[["Z.char"]]
}

# Fit cases of a fixture set whose reference call returned a value.
reference_value_fit_ids <- function(set = "core") {
  manifest <- reference_manifest(set)
  if (is.null(manifest)) return(character())
  keep <- vapply(manifest$cases, function(entry) {
    entry[["fun"]] %in% reference_fit_functions && identical(entry[["outcome"]], "value")
  }, logical(1))
  vapply(manifest$cases[keep], `[[`, character(1), "id")
}

expect_reference_data <- function(id, set = "core") {
  fixture <- reference_fixture(id, set)
  case <- fixture$case
  expected <- fixture$result$value
  translation <- reference_data_translation(case, reference_datasets_for(case, set))
  prepared <- do.call(data_prepare, translation$call)

  rebuilt <- reference_fixture_value(reference_rebuild_data_include(prepared, translation),
                                     reference_manifest(set)$max_full_length)
  diffs <- reference_compare(rebuilt, expected[["data_include"]], reference_tolerance("exact"), path = "data_include")
  testthat::expect(is.null(diffs),
                   sprintf("Case %s: data_include differs:\n%s", id,
                           paste(sprintf("  %s [%s] %s", diffs$path, diffs$kind, diffs$detail), collapse = "\n")))

  # The reference records design column names (FE: the model.matrix() names; RE: the
  # coefficient names without the intercept) or, for CRE, the formula terms.
  covariates <- if (case$fun %in% c("linear_cre", "logis_cre")) {
    attr(prepared$terms, "term.labels")
  } else {
    setdiff(colnames(prepared$design), "(Intercept)")
  }
  testthat::expect(identical(covariates, reference_char_list_covariates(expected, case$fun)),
                   sprintf("Case %s: design column names differ from the reference", id))

  coefficient <- expected[["coefficient"]]
  fixed <- case$fun %in% c("logis_fe", "logis_firth", "linear_fe")
  effects <- if (fixed) coefficient[["gamma"]] else coefficient[["RE"]]
  included_ids <- prepared$providers$provider_id[prepared$providers$included]
  testthat::expect(identical(rownames(effects), included_ids),
                   sprintf("Case %s: provider order differs from the reference", id))
  invisible(prepared)
}
