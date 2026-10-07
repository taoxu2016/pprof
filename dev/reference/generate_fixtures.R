# Generate the reference fixtures (brief §3.1, ARCHITECTURE §G.1).
#
# Usage, from the repository root:
#   Rscript dev/reference/generate_fixtures.R [--set core|full|all] [--lib DIR]
#           [--out-core DIR] [--out-full DIR] [--allow-dirty]
#
# Defaults: --set all, --lib dev/reference/lib, --out-core tests/testthat/fixtures/reference,
# --out-full validation/fixtures/reference.
#
# Fixtures must come from the committed generator: unless --allow-dirty is given (only for
# runs into a scratch directory), the script refuses to run when the generator's inputs have
# uncommitted changes. Regenerating committed fixtures needs the project lead's approval and
# a diff report from compare_fixtures.R (CLAUDE.md).
#
# Each set runs in one child R session whose library path is only the isolated reference
# library (setup_reference_library.R) and base R, with no site library, with LC_COLLATE = C
# (as testthat 3e uses for tests), OMP_THREAD_LIMIT = 1 (one thread even where the reference
# hard-codes more, D-21), and threads = 1 passed explicitly in every call that accepts it
# (cases.R).
#
# Cases marked `emulate = "reformulate-4.5.0"` record what pprof 1.0.3 does from R 4.5.0, where
# reformulate() of no terms gives an intercept-only formula instead of an error (D-30, D-54).
# On an R older than 4.5.0, such a case runs with pprof 1.0.3's imported reformulate() replaced
# by R 4.5.0's change alone, applied to the installed function (R 4.5.0,
# src/library/stats/R/models.R: `if(intercept && !length(termlabels)) termlabels <- "1"`), and
# the manifest says so; on R 4.5.0 and later the case runs unchanged.

fixture_format_version <- 1L
generator_inputs <- c("dev/reference/generate_fixtures.R", "dev/reference/cases.R", "dev/reference/datasets.R",
                      "dev/reference/library-lock.json", "tests/testthat/helper-reference-cases.R")

# --- Arguments --------------------------------------------------------------------------------
opts <- list(set = "all", lib = "dev/reference/lib", out_core = "tests/testthat/fixtures/reference",
             out_full = "validation/fixtures/reference", allow_dirty = FALSE)
args <- commandArgs(trailingOnly = TRUE)
i <- 1
while (i <= length(args)) {
  key <- args[[i]]
  if (key == "--allow-dirty") {
    opts$allow_dirty <- TRUE
    i <- i + 1
    next
  }
  value <- args[[i + 1]]
  switch(key, "--set" = opts$set <- value, "--lib" = opts$lib <- value, "--out-core" = opts$out_core <- value,
         "--out-full" = opts$out_full <- value, stop("Unknown argument: ", key, call. = FALSE))
  i <- i + 2
}
stopifnot(opts$set %in% c("core", "full", "all"), dir.exists(opts$lib))
ref_lib <- normalizePath(opts$lib, winslash = "/")
stopifnot(requireNamespace("callr", quietly = TRUE), requireNamespace("jsonlite", quietly = TRUE))

# --- Provenance ---------------------------------------------------------------------------------
git <- function(...) system2("git", c(...), stdout = TRUE, stderr = TRUE)
git_commit <- git("rev-parse", "HEAD")
dirty <- git("status", "--porcelain", "--", generator_inputs)
if (length(dirty) && !opts$allow_dirty) {
  stop("Generator inputs have uncommitted changes; commit them first (fixtures must come from the committed generator):\n",
       paste(dirty, collapse = "\n"), call. = FALSE)
}

source("tests/testthat/helper-reference-cases.R")
source("dev/reference/datasets.R")
source("dev/reference/cases.R")

all_cases <- reference_cases()
sets <- if (opts$set == "all") c("core", "full") else opts$set
datasets <- reference_datasets(ref_lib, include_full = "full" %in% sets)

# Case ids that a case depends on through ref_fit() and ref_value(), and dataset names.
case_parents <- function(case) {
  ids <- unlist(lapply(case$args, function(a) {
    if (inherits(a, "pprof_ref_fit") || inherits(a, "pprof_ref_value")) a$case_id else NULL
  }))
  unique(ids)
}
case_datasets <- function(case) {
  unique(unlist(lapply(case$args, function(a) {
    if (inherits(a, "pprof_ref_dataset") || inherits(a, "pprof_ref_element")) a$name else NULL
  })))
}
with_ancestors <- function(ids) {
  repeat {
    more <- unique(unlist(lapply(all_cases[ids], case_parents)))
    new <- setdiff(more, ids)
    if (!length(new)) break
    ids <- c(ids, new)
  }
  names(all_cases)[names(all_cases) %in% ids]   # keep the order of cases.R
}
format_arg <- function(a) {
  if (inherits(a, "pprof_ref_dataset")) return(sprintf('ref_dataset("%s")', a$name))
  if (inherits(a, "pprof_ref_element")) return(sprintf('ref_element("%s", "%s")', a$name, a$element))
  if (inherits(a, "pprof_ref_formula")) return(sprintf('ref_formula("%s")', a$text))
  if (inherits(a, "pprof_ref_fit")) return(sprintf('ref_fit("%s")', a$case_id))
  if (inherits(a, "pprof_ref_value")) return(sprintf('ref_value("%s", "%s")', a$case_id, a$element))
  if (inherits(a, "pprof_ref_expr")) return(a$text)   # the expression as evaluated
  paste(deparse(a, width.cutoff = 500L), collapse = " ")
}
format_call <- function(case) {
  sprintf("%s(%s)", case$fun, paste(names(case$args), vapply(case$args, format_arg, character(1)), sep = " = ", collapse = ", "))
}

# --- The child session ----------------------------------------------------------------------------
run_set_in_child <- function(run_ids, target_ids, max_full_length) {
  callr::r(function(cases, datasets, runner, ref_lib, run_ids, target_ids, max_full_length) {
    Sys.setlocale("LC_COLLATE", "C")
    # callr's profile gives the child the parent's site library (R_HOME/site-library, where CI
    # runners install packages), whatever R_LIBS_SITE says; the child drops it before loading
    # anything but base R, so that its library path is only the reference library and base R.
    .libPaths(ref_lib, include.site = FALSE)
    lib_paths <- normalizePath(.libPaths(), winslash = "/")
    allowed <- c(normalizePath(ref_lib, winslash = "/"), normalizePath(R.home("library"), winslash = "/"))
    if (!all(lib_paths %in% allowed)) stop("Child library path is not isolated: ", paste(lib_paths, collapse = "; "))
    suppressPackageStartupMessages(library(pprof))
    if (!startsWith(normalizePath(find.package("pprof"), winslash = "/"), allowed[1]) ||
        !identical(as.character(utils::packageVersion("pprof")), "1.0.3")) {
      stop("The child did not load pprof 1.0.3 from the reference library.")
    }
    source(runner, local = TRUE)
    # R 4.5.0's reformulate() for cases marked emulate = "reformulate-4.5.0" (see the header).
    imports <- parent.env(asNamespace("pprof"))
    reformulate_installed <- get("reformulate", envir = imports)
    reformulate_450 <- function(termlabels, response = NULL, intercept = TRUE, env = parent.frame()) {
      if (intercept && !length(termlabels)) termlabels <- "1"
      reformulate_installed(termlabels, response = response, intercept = intercept, env = env)
    }
    set_reformulate <- function(f) {
      unlockBinding("reformulate", imports)
      assign("reformulate", f, envir = imports)
      lockBinding("reformulate", imports)
    }
    results <- list()
    records <- list()
    emulated <- character()
    for (id in run_ids) {
      emulate <- identical(cases[[id]]$emulate, "reformulate-4.5.0") && getRversion() < "4.5.0"
      if (emulate) {
        set_reformulate(reformulate_450)
        emulated <- c(emulated, id)
      }
      results[[id]] <- run_reference_case(cases[[id]], datasets, results)
      if (emulate) set_reformulate(reformulate_installed)
      if (id %in% target_ids) records[[id]] <- reference_result_record(results[[id]], max_full_length)
    }
    env <- list(
      r_version = R.version.string, platform = R.version$platform, os = utils::sessionInfo()$running,
      blas = utils::sessionInfo()$BLAS, lapack = La_library(), lapack_version = La_version(),
      ext_soft = as.list(extSoftVersion()), collate = Sys.getlocale("LC_COLLATE"), locale = Sys.getlocale(),
      omp_thread_limit = Sys.getenv("OMP_THREAD_LIMIT"), omp_num_threads = Sys.getenv("OMP_NUM_THREADS"),
      rng_kind = RNGkind(), lib_paths = .libPaths(),
      packages = {
        ip <- utils::installed.packages(lib.loc = ref_lib)
        stats::setNames(as.list(unname(ip[, "Version"])), ip[, "Package"])
      }
    )
    list(records = records, environment = env, emulated = emulated)
  },
  args = list(cases = all_cases, datasets = datasets, runner = normalizePath("tests/testthat/helper-reference-cases.R"),
              ref_lib = ref_lib, run_ids = run_ids, target_ids = target_ids, max_full_length = max_full_length),
  libpath = ref_lib,
  env = c(callr::rcmd_safe_env(), LC_COLLATE = "C", OMP_THREAD_LIMIT = "1", OMP_NUM_THREADS = "1"),
  user_profile = FALSE, system_profile = FALSE, show = FALSE)
}

compiler_version <- tryCatch(system2("g++", "--version", stdout = TRUE)[1], error = function(e) NA_character_)
makeconf <- file.path(R.home("etc"), .Platform$r_arch, "Makeconf")
openmp_flags <- if (file.exists(makeconf)) {
  line <- grep("^SHLIB_OPENMP_CXXFLAGS\\s*=", readLines(makeconf), value = TRUE)
  if (length(line)) trimws(sub("^SHLIB_OPENMP_CXXFLAGS\\s*=", "", line[1])) else NA_character_
} else NA_character_

# --- Generate each set -------------------------------------------------------------------------------
for (set in sets) {
  out_dir <- if (set == "core") opts$out_core else opts$out_full
  targets <- names(all_cases)[vapply(all_cases, function(cs) cs$set == set, logical(1))]
  run_ids <- with_ancestors(targets)
  max_full_length <- 5000L   # vectors longer than this are stored as signatures (DEC-018)
  cat(sprintf("Set %s: %d target cases (%d with ancestors) -> %s\n", set, length(targets), length(run_ids), out_dir))
  started <- Sys.time()
  child <- run_set_in_child(run_ids, targets, max_full_length)
  elapsed <- as.numeric(difftime(Sys.time(), started, units = "secs"))

  unlink(out_dir, recursive = TRUE)
  dir.create(file.path(out_dir, "datasets"), recursive = TRUE, showWarnings = FALSE)
  used_datasets <- sort(unique(unlist(lapply(all_cases[run_ids], case_datasets))))
  dataset_entries <- lapply(used_datasets, function(name) {
    path <- file.path(out_dir, "datasets", paste0(name, ".rds"))
    saveRDS(datasets[[name]], path, compress = "xz", version = 3)
    list(name = name, file = file.path("datasets", paste0(name, ".rds")), md5 = unname(tools::md5sum(path)),
         class = class(datasets[[name]]), rows = NROW(datasets[[name]]),
         source = "dev/reference/datasets.R::reference_datasets()")
  })
  case_entries <- lapply(targets, function(id) {
    case <- all_cases[[id]]
    rec <- child$records[[id]]
    path <- file.path(out_dir, paste0(id, ".rds"))
    saveRDS(list(format_version = fixture_format_version, case = case, result = rec), path, compress = "xz", version = 3)
    entry <- list(id = id, file = paste0(id, ".rds"), md5 = unname(tools::md5sum(path)), fun = case$fun,
                  call = format_call(case), parents = case_parents(case), datasets = case_datasets(case),
                  seed = case$seed, tier = case$tier, heavy = case$heavy, notes = case$notes, outcome = rec$outcome,
                  error = if (!is.null(rec$error)) rec$error$message else NULL,
                  iterations = if (is.na(rec$iterations)) NULL else rec$iterations,
                  probe_identical = if (is.na(rec$probe_identical)) NULL else rec$probe_identical)
    # Whether this R ran the case with R 4.5.0's reformulate() in place of its own (see the header).
    if (!is.null(case$emulate)) entry <- c(entry, list(emulate = case$emulate, emulated = id %in% child$emulated))
    entry
  })
  manifest <- list(
    fixture_set = set, format_version = fixture_format_version,
    generated_at = format(Sys.time(), tz = "UTC", usetz = TRUE), generation_seconds = round(elapsed, 1),
    generator = list(git_commit = git_commit, dirty = length(dirty) > 0, inputs = generator_inputs,
                     command = paste("Rscript dev/reference/generate_fixtures.R", paste(args, collapse = " "))),
    reference = list(package = "pprof", version = "1.0.3", git_commit = "5260838", source = "CRAN tarball",
                     md5 = "6fa1344f4a265811059d27a105d06d6b"),
    library = list(path = "dev/reference/lib", lock = "dev/reference/library-lock.json",
                   lock_md5 = unname(tools::md5sum("dev/reference/library-lock.json")),
                   snapshot = jsonlite::read_json("dev/reference/library-lock.json")$snapshot),
    environment = c(child$environment[setdiff(names(child$environment), "packages")],
                    list(compiler = compiler_version, openmp_flags = openmp_flags)),
    numerically_relevant_packages = child$environment$packages[intersect(
      c("lme4", "Matrix", "Rcpp", "RcppArmadillo", "RcppParallel", "poibin", "pROC", "caret", "olsrr", "nloptr", "minqa",
        "MASS", "ggplot2", "dplyr"), names(child$environment$packages))],
    packages = child$environment$packages,
    threads = 1L, max_full_length = max_full_length,
    datasets = dataset_entries, cases = case_entries
  )
  jsonlite::write_json(manifest, file.path(out_dir, "manifest.json"), auto_unbox = TRUE, pretty = TRUE, null = "null", digits = NA)
  size_mb <- sum(file.size(list.files(out_dir, recursive = TRUE, full.names = TRUE))) / 2^20
  n_err <- sum(vapply(case_entries, function(e) identical(e$outcome, "error"), logical(1)))
  cat(sprintf("Set %s: wrote %d cases (%d reference errors) and %d datasets, %.2f MB, in %.0f s\n",
              set, length(case_entries), n_err, length(dataset_entries), size_mb, elapsed))
  if (set == "core" && size_mb > 5) warning(sprintf("Core fixtures are %.2f MB, above the 5 MB budget (DEC-018).", size_mb))
}
