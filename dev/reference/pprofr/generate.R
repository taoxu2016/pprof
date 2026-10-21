# Generate the pprofR reference fixtures (LOGISTIC_L1_PLAN §3; DEC-157): run each case of cases.R on the
# data sets of datasets.R with pprofR 0.2.0 from its isolated library (setup_pprofr_library.R), one
# child session per case, and write one RDS per case and manifest.json.
#
# Usage, from the repository root:
#   Rscript dev/reference/pprofr/generate.R [--out DIR] [--only REGEX] [--allow-dirty]
# Default output: validation/fixtures/pprofr. Fixtures must come from the committed generator: unless
# --allow-dirty is given, which writes only to a directory other than the default, the script stops
# when its inputs have uncommitted changes. Regenerating the committed fixtures needs the project
# lead's approval and a diff report (compare.R; CLAUDE.md).
#
# Each child session's library path is the pprofR library and base R only (the site library dropped),
# with LC_COLLATE=C, OMP_THREAD_LIMIT=1, threads = 1 in every call that takes it, R's default random
# number generators, and an explicit seed before every call that draws random numbers.

default_out <- file.path("validation", "fixtures", "pprofr")
opts <- list(out = default_out, only = NULL, allow_dirty = FALSE)
args <- commandArgs(trailingOnly = TRUE)
i <- 1L
while (i <= length(args)) {
  key <- args[[i]]
  if (key == "--allow-dirty") {
    opts$allow_dirty <- TRUE
  } else if (key %in% c("--out", "--only") && i < length(args)) {
    opts[[sub("^--", "", key)]] <- args[[i + 1L]]
    i <- i + 1L
  } else {
    stop("Unknown argument: ", key, call. = FALSE)
  }
  i <- i + 1L
}
stopifnot(requireNamespace("callr", quietly = TRUE), requireNamespace("jsonlite", quietly = TRUE))

generator_dir <- file.path("dev", "reference", "pprofr")
inputs <- file.path(generator_dir, c("datasets.R", "cases.R", "generate.R", "pprofr-library-lock.json"))
git <- function(...) system2("git", c(...), stdout = TRUE)
git_commit <- git("rev-parse", "HEAD")
dirty <- git("status", "--porcelain", "--", inputs)
if (length(dirty) && !opts$allow_dirty) {
  stop("The generator's inputs have uncommitted changes:\n", paste(dirty, collapse = "\n"), call. = FALSE)
}
out_dir <- opts$out
same_as_default <- identical(normalizePath(out_dir, winslash = "/", mustWork = FALSE),
                             normalizePath(default_out, winslash = "/", mustWork = FALSE))
if (opts$allow_dirty && same_as_default) {
  stop("--allow-dirty writes only to a directory other than ", default_out, ".", call. = FALSE)
}

lib_dir <- normalizePath(file.path(generator_dir, "lib"), winslash = "/", mustWork = FALSE)
installed <- if (dir.exists(lib_dir)) utils::installed.packages(lib.loc = lib_dir) else matrix(nrow = 0, ncol = 0)
if (!"pprofR" %in% rownames(installed) || installed["pprofR", "Version"] != "0.2.0") {
  stop("Run dev/reference/pprofr/setup_pprofr_library.R first: no pprofR 0.2.0 in ", lib_dir, call. = FALSE)
}

source(file.path(generator_dir, "datasets.R"))
source(file.path(generator_dir, "cases.R"))
datasets <- pprofr_datasets()
populations <- pprofr_standard_populations()
ids <- pprofr_case_ids
if (!is.null(opts$only)) ids <- grep(opts$only, ids, value = TRUE)
if (!length(ids)) stop("No case matches --only.", call. = FALSE)
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
cases_file <- normalizePath(file.path(generator_dir, "cases.R"), winslash = "/")
child_env <- c(callr::rcmd_safe_env(), LC_COLLATE = "C", OMP_THREAD_LIMIT = "1", OMP_NUM_THREADS = "1")

# The child's setup, shared by the case runs and the session record: an isolated library path.
child <- function(fun, args) {
  callr::r(function(fun, args, lib) {
    Sys.setlocale("LC_COLLATE", "C")
    .libPaths(lib, include.site = FALSE)
    lib_paths <- normalizePath(.libPaths(), winslash = "/")
    allowed <- c(normalizePath(lib, winslash = "/"), normalizePath(R.home("library"), winslash = "/"))
    if (!all(lib_paths %in% allowed)) stop("Child library path is not isolated: ", paste(lib_paths, collapse = "; "))
    suppressPackageStartupMessages(library(pprofR))
    from_library <- startsWith(normalizePath(find.package("pprofR"), winslash = "/"), allowed[1])
    if (!from_library || !identical(as.character(utils::packageVersion("pprofR")), "0.2.0")) {
      stop("The child did not load pprofR 0.2.0 from its library.")
    }
    if (!identical(RNGkind(), c("Mersenne-Twister", "Inversion", "Rejection"))) stop("Not R's default generators.")
    do.call(fun, args)
  }, args = list(fun = fun, args = args, lib = lib_dir), libpath = lib_dir, env = child_env, user_profile = FALSE,
  system_profile = FALSE)
}

session <- child(function() {
  versions <- vapply(c("pprofR", "Rcpp", "RcppArmadillo", "poibin"), function(p) as.character(utils::packageVersion(p)),
                     character(1))
  list(r_version = R.version.string, platform = R.version$platform, running = utils::sessionInfo()$running,
       compiler = system2(file.path(R.home("bin"), "R"), c("CMD", "config", "CXX17"), stdout = TRUE),
       blas = extSoftVersion()[["BLAS"]], lapack = La_version(), long_double_bytes = .Machine$sizeof.longdouble,
       rng_kind = RNGkind(), lc_collate = Sys.getlocale("LC_COLLATE"),
       omp_thread_limit = Sys.getenv("OMP_THREAD_LIMIT"), lib_paths = length(.libPaths()), packages = as.list(versions))
}, list())

entries <- list()
for (id in ids) {
  started <- proc.time()[["elapsed"]]
  fixture <- child(function(id, datasets, populations, cases_file) {
    source(cases_file)
    pprofr_run_case(id, datasets, populations)
  }, list(id = id, datasets = datasets, populations = populations, cases_file = cases_file))
  fixture <- c(list(format_version = 1L), fixture)
  path <- file.path(out_dir, paste0(id, ".rds"))
  saveRDS(fixture, path, version = 3)
  records <- fixture$records
  errors <- names(records)[vapply(records, function(r) !is.null(r$error), logical(1))]
  seeds <- unlist(lapply(records, `[[`, "seed"))
  entries[[length(entries) + 1L]] <- list(
    id = id, file = basename(path), md5 = unname(tools::md5sum(path)), description = fixture$description,
    data = names(fixture$data), records = length(records), errors = as.list(errors),
    seeds = if (length(seeds)) as.list(unname(seeds)) else list(),
    calls = lapply(records, `[[`, "call")
  )
  cat(sprintf("%-22s %4d records (%d errors) in %5.1f s\n", id, length(records), length(errors),
              proc.time()[["elapsed"]] - started))
}

manifest <- list(
  format_version = 1L,
  purpose = paste("The pprofR reference fixtures of the logistic extensions phase (dev/logistic_brief.md §3.1;",
                  "LOGISTIC_L1_PLAN; DEC-152, DEC-157)."),
  created = format(Sys.time(), tz = "UTC", usetz = TRUE),
  reference = list(package = "pprofR", version = "0.2.0", git_commit = "f23c2889b59108f9506da3f91327c3f239945a63",
                   source = "git archive of the commit, built in dev/reference/pprofr/lib"),
  generator = list(git_commit = git_commit, dirty = length(dirty) > 0, inputs = inputs),
  library = list(lock = file.path(generator_dir, "pprofr-library-lock.json"),
                 lock_md5 = unname(tools::md5sum(file.path(generator_dir, "pprofr-library-lock.json")))),
  session = session,
  threads = 1L,
  cases = entries
)
jsonlite::write_json(manifest, file.path(out_dir, "manifest.json"), auto_unbox = TRUE, pretty = TRUE, null = "null",
                     digits = NA)
cat(sprintf("wrote %d cases to %s\n", length(entries), out_dir))
