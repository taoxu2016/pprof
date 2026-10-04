# The layer rules (ARCHITECTURE §B.1): the code of each layer calls only functions of its own
# layer, of lower layers, and of the shared utilities. A file's layer comes from its name
# (NAMING.md §8). The reference's files are exempt until the rewrite removes them; every other
# file must have a layer.
local_strict_mode()

architecture_shared_files <- c(
  "pprof-package.R", "constants.R", "conditions.R", "messages.R", "validate.R", "results.R"
)

# R/ at the reference commit 5260838. Remove a file from this list when it is deleted.
architecture_legacy_files <- c(
  "Data.R", "RcppExports.R", "data_check.R", "pprof.R"
)

# Layers in dependency order: shared 0, data 1, model 2 (with the diagnostics), inference 3,
# profiling 4, presentation 5, compatibility 6.
architecture_layer <- function(file) {
  name <- basename(file)
  if (name %in% architecture_shared_files) return(0L)
  if (name == "RcppExports.R") return(2L)
  prefix <- sub("-.*$", "", name)
  layers <- c(data = 1L, model = 2L, check = 2L, inference = 3L, profile = 4L, present = 5L, plot = 5L, compat = 6L)
  if (prefix %in% names(layers) && grepl("-", name, fixed = TRUE)) layers[[prefix]] else NA_integer_
}

architecture_definitions <- function(file) {
  names <- character()
  for (expression in parse(file, keep.source = FALSE)) {
    if (is.call(expression) && as.character(expression[[1]]) %in% c("<-", "=") &&
          is.call(expression[[3]]) && identical(expression[[3]][[1]], as.name("function"))) {
      names <- c(names, as.character(expression[[2]]))
    }
  }
  names
}

# Names of the functions a file calls. Functions passed by name (for example to lapply())
# are not seen, because their names cannot be told apart from variables and fields without
# resolving scopes.
architecture_symbols <- function(file) {
  tokens <- utils::getParseData(parse(file, keep.source = TRUE))
  unique(tokens$text[tokens$token == "SYMBOL_FUNCTION_CALL"])
}

# Calls from a file to a function defined in a higher layer, among `files` (with layers).
# RcppExports.R only defines functions; its own calls are not checked.
architecture_violations <- function(files) {
  layers <- vapply(files, architecture_layer, integer(1))
  defined_in <- list()
  for (k in seq_along(files)) {
    for (name in architecture_definitions(files[k])) defined_in[[name]] <- layers[[k]]
  }
  violations <- character()
  for (k in seq_along(files)) {
    if (basename(files[k]) == "RcppExports.R") next
    for (symbol in intersect(architecture_symbols(files[k]), names(defined_in))) {
      if (defined_in[[symbol]] > layers[[k]]) {
        violations <- c(violations, sprintf("%s (layer %d) calls %s (layer %d)", basename(files[k]), layers[[k]],
                                            symbol, defined_in[[symbol]]))
      }
    }
  }
  violations
}

test_that("every file of the rewrite belongs to a layer, and layers call only downwards", {
  r_dir <- test_path("..", "..", "R")
  skip_if_not(dir.exists(r_dir), "package sources not available")
  files <- list.files(r_dir, pattern = "[.]R$", full.names = TRUE)
  layered <- files[!basename(files) %in% setdiff(architecture_legacy_files, "RcppExports.R")]
  layers <- vapply(layered, architecture_layer, integer(1))
  expect_identical(basename(layered[is.na(layers)]), character())
  expect_identical(architecture_violations(layered[!is.na(layers)]), character())
})

test_that("the layer check detects a call to a higher layer", {
  directory <- withr::local_tempdir()
  writeLines("data_helper <- function(model) profile_helper(model)", file.path(directory, "data-example.R"))
  writeLines("profile_helper <- function(model) data_other(model)", file.path(directory, "profile-example.R"))
  writeLines("data_other <- function(model) model", file.path(directory, "data-other.R"))
  files <- file.path(directory, c("data-example.R", "profile-example.R", "data-other.R"))
  expect_identical(architecture_violations(files), "data-example.R (layer 1) calls profile_helper (layer 4)")
  expect_identical(architecture_layer("R/logis_fe.R"), NA_integer_)
  expect_identical(architecture_layer("R/results.R"), 0L)
})

test_that("package code calls no function that only a test helper defines", {
  # devtools::test() loads the test helpers into the package's namespace, so such a call
  # passes the tests and fails in the installed package (found at the Phase 3 gate).
  r_dir <- test_path("..", "..", "R")
  skip_if_not(dir.exists(r_dir), "package sources not available")
  files <- list.files(r_dir, pattern = "[.]R$", full.names = TRUE)
  skip_if(length(files) == 0L, "package sources not available")
  package_functions <- unlist(lapply(files, architecture_definitions))
  helpers <- list.files(test_path(), pattern = "^helper-.*[.]R$", full.names = TRUE)
  helper_only <- setdiff(unlist(lapply(helpers, architecture_definitions)), package_functions)
  calls <- as.character(unlist(lapply(files, function(file) {
    used <- intersect(architecture_symbols(file), helper_only)
    if (length(used)) sprintf("%s calls %s", basename(file), used) else character()
  })))
  expect_identical(calls, character())
})
