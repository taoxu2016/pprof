# The snapshot of the data layer's output on the reference cases (COXPH_DESIGN §C.2; the CoxPH C2
# plan, §4.1). Every `pprof_data` object is built by new_pprof_data(), from data_prepare() or from the
# compatibility conversions (R/compat-convert.R). data_snapshot_record() replays reference cases with
# a recording binding of new_pprof_data() and returns the signature of every object each case built.
# dev/tools/data_prepare_snapshot.R recorded them before the CoxPH phase changed the data layer
# (validation/fixtures/data-prepare-snapshot.rds), and test-data-prepare-snapshot.R compares the
# current code's signatures with them, so that the existing families' data stay identical.

data_snapshot_file <- function() {
  override <- Sys.getenv("PPROF_DATA_SNAPSHOT")
  if (nzchar(override)) return(override)
  file.path(testthat::test_path(), "..", "..", "validation", "fixtures", "data-prepare-snapshot.rds")
}

# A value as lines of text that determine it bit for bit: its type and length, its attributes (by
# name, without the environment of formulas and terms), and its values: doubles in hexadecimal,
# missing values marked, language objects deparsed.
data_snapshot_lines <- function(x, path = "") {
  if (is.null(x)) return(paste(path, "NULL"))
  if (is.environment(x)) return(paste(path, "<environment>"))
  if (is.symbol(x)) return(paste(path, "symbol", as.character(x)))
  a <- attributes(x)
  a[[".Environment"]] <- NULL
  value <- x
  attributes(value) <- NULL
  body <- if (is.language(value)) {
    deparse(value, width.cutoff = 500L, control = c("keepInteger", "keepNA", "showAttributes", "niceNames"))
  } else if (is.list(value)) {
    unlist(lapply(seq_along(value), function(i) data_snapshot_lines(value[[i]], sprintf("%s[[%d]]", path, i))))
  } else if (is.double(value)) {
    sprintf("%a", value)
  } else {
    ifelse(is.na(value), "<NA>", as.character(value))
  }
  attribute_lines <- unlist(lapply(sort(names(a)), function(name) data_snapshot_lines(a[[name]], paste0(path, "@", name))))
  c(sprintf("%s %s %d", path, typeof(x), length(value)), attribute_lines, body)
}

# The signature of a `pprof_data` object: its class and an MD5 checksum of each element, in order.
data_snapshot_signature <- function(x) {
  elements <- unclass(x)
  c(class = paste(class(x), collapse = "/"),
    vapply(names(elements), function(name) reference_md5(data_snapshot_lines(elements[[name]])), character(1)))
}

# Replays the reference cases `ids` of `set` (each case's parents first, each case once) with a
# recording binding of new_pprof_data(), with the options of reference_run() (helper-fixtures.R). Returns
# `signatures`, the distinct signatures in order of first appearance, and `cases`, for each case the
# positions in `signatures` of the objects it built, in order.
data_snapshot_record <- function(ids, set = "core") {
  log <- new.env(parent = emptyenv())
  log$current <- NA_character_
  log$cases <- list()
  log$signatures <- list()
  log$keys <- character()
  real <- get("new_pprof_data", envir = asNamespace("pprof"))
  recorder <- function(...) {
    x <- real(...)
    signature <- data_snapshot_signature(x)
    key <- paste(signature, collapse = "|")
    position <- match(key, log$keys)
    if (is.na(position)) {
      log$keys <- c(log$keys, key)
      log$signatures[[length(log$signatures) + 1L]] <- signature
      position <- length(log$keys)
    }
    log$cases[[log$current]] <- c(log$cases[[log$current]], position)
    x
  }
  testthat::local_mocked_bindings(new_pprof_data = recorder, .package = "pprof")
  results <- list()
  run <- function(id) {
    if (!is.null(results[[id]])) return(results[[id]])
    case <- reference_fixture(id, set)$case
    parents <- list()
    for (parent in reference_parent_ids(case)) parents[[parent]] <- run(parent)
    previous <- log$current
    log$current <- id
    if (is.null(log$cases[[id]])) log$cases[[id]] <- integer()
    on.exit(log$current <- previous)
    old <- options(warnPartialMatchDollar = TRUE, warnPartialMatchArgs = TRUE, warnPartialMatchAttr = TRUE)
    on.exit(options(old), add = TRUE)
    withr::local_collate("C")
    results[[id]] <<- run_reference_case(case, reference_datasets_for(case, set), parents)
    results[[id]]
  }
  for (id in ids) run(id)
  list(signatures = log$signatures, cases = log$cases[ids])
}
