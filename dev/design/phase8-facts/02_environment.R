# Phase 8 planning: what differs between this machine and the CI jobs, without the CI logs.
# - the R versions that r-lib/actions resolves for release, oldrel-1, and devel;
# - the local versions of the packages pprof uses against CRAN's current ones, with the R
#   versions those need, and the fixture manifest's numerically relevant packages;
# - whether rcmdcheck sets NOT_CRAN (which decides how many tests the CI check jobs run);
# - the CRAN snapshot that rewrite-reference.yaml installs from: lme4 and Matrix there;
# - the Node.js runtime of the GitHub actions the workflows use;
# - reverse dependencies of pprof on CRAN.
# Run from the repository root: Rscript <this file> <output file>
args <- commandArgs(trailingOnly = TRUE)
out_file <- args[1]
lines <- character()
say <- function(...) lines <<- c(lines, paste0(...))
fetch <- function(address) {
  con <- url(address)
  on.exit(close(con))
  paste(readLines(con, warn = FALSE), collapse = "\n")
}

say("Run ", format(Sys.time(), tz = "UTC", usetz = TRUE), " on ", R.version.string, ", ", utils::osVersion,
    "; collation ", Sys.getlocale("LC_COLLATE"))
say("")
say("## R versions on CI (api.r-hub.io/rversions, as r-lib/actions/setup-r resolves them)")
for (v in c("release", "oldrel/1", "devel")) {
  r <- jsonlite::fromJSON(fetch(paste0("https://api.r-hub.io/rversions/resolve/", v)))
  say("- ", v, ": R ", r$version, if (!is.null(r$date)) paste0(" (", substr(r$date, 1, 10), ")"))
}

say("")
say("## rcmdcheck and NOT_CRAN")
ns <- asNamespace("rcmdcheck")
hits <- Filter(function(f) is.function(get(f, ns)) && any(grepl("NOT_CRAN", deparse(get(f, ns)), fixed = TRUE)),
               ls(ns, all.names = TRUE))
say("- rcmdcheck ", as.character(utils::packageVersion("rcmdcheck")), ": functions that mention NOT_CRAN: ",
    if (length(hits)) paste(hits, collapse = ", ") else "none", "; default `env` argument: ",
    deparse(formals(rcmdcheck::rcmdcheck)$env))
crp <- fetch("https://raw.githubusercontent.com/r-lib/actions/refs/tags/v2/check-r-package/action.yaml")
envs <- regmatches(crp, gregexpr("_R_CHECK_[A-Z_]+_\" = \"[a-z]+\"", crp))[[1]]
say("- r-lib/actions/check-r-package@v2 sets: ", paste(unique(envs), collapse = "; "),
    "; NOT_CRAN mentioned: ", grepl("NOT_CRAN", crp, fixed = TRUE))

say("")
say("## Packages: this machine, CRAN today, and the fixture manifest")
manifest <- jsonlite::read_json("tests/testthat/fixtures/reference/manifest.json")$numerically_relevant_packages
db <- utils::available.packages(repos = "https://cloud.r-project.org")
pkgs <- c("Rcpp", "RcppArmadillo", "lme4", "Matrix", "MASS", "nlme", "minqa", "nloptr", "reformulas", "poibin",
          "ggplot2", "scales", "tibble", "generics", "caret", "olsrr", "globals", "pROC", "logistf", "testthat",
          "withr", "jsonlite", "knitr", "rmarkdown", "covr", "lintr", "pkgdown", "roxygen2", "rcmdcheck")
say("")
say("| Package | Local | CRAN | Manifest | CRAN's R requirement |")
say("|---|---|---|---|---|")
for (p in pkgs) {
  loc <- tryCatch(as.character(utils::packageVersion(p)), error = function(e) "-")
  cran <- if (p %in% rownames(db)) db[p, "Version"] else "-"
  dep <- if (p %in% rownames(db)) regmatches(db[p, "Depends"], regexpr("R ?\\([^)]*\\)", db[p, "Depends"])) else ""
  say(sprintf("| %s | %s | %s | %s | %s |", p, loc, cran, if (is.null(manifest[[p]])) "" else manifest[[p]],
              if (length(dep)) dep else ""))
}
rev_deps <- tools::package_dependencies("pprof", db = db, reverse = TRUE, which = "all")[[1]]
say("")
say("- pprof on CRAN: ", db["pprof", "Version"], "; reverse dependencies of any type: ",
    if (length(rev_deps)) paste(rev_deps, collapse = ", ") else "none")
# The packages installed with pprof: its Imports and LinkingTo with their recursive hard
# dependencies on CRAN today, base packages excluded.
desc <- read.dcf("DESCRIPTION", fields = c("Imports", "LinkingTo"))
direct <- trimws(sub("\\(.*", "", unlist(strsplit(paste(desc, collapse = ","), ","))))
direct <- direct[nzchar(direct)]
base_pkgs <- rownames(utils::installed.packages(priority = "base"))
tree <- function(p) {
  deps <- tools::package_dependencies(p, db = db, recursive = TRUE, which = c("Depends", "Imports", "LinkingTo"))
  setdiff(unique(c(p, unlist(deps))), base_pkgs)
}
say("- packages installed with pprof (recursive Depends, Imports, LinkingTo; base excluded): ", length(tree(direct)),
    "; without caret, olsrr, and globals: ", length(tree(setdiff(direct, c("caret", "olsrr", "globals")))))

say("")
say("## The CRAN snapshot of rewrite-reference.yaml")
snapshot <- "https://packagemanager.posit.co/cran/__linux__/noble/2026-10-01"
packages <- read.dcf(url(paste0(snapshot, "/src/contrib/PACKAGES")), fields = c("Package", "Version"))
for (p in c("lme4", "Matrix", "devtools", "jsonlite")) {
  say("- ", p, ": ", paste(packages[packages[, "Package"] == p, "Version"], collapse = ", "),
      if (!is.null(manifest[[p]])) paste0(" (manifest ", manifest[[p]], ")"))
}
status <- tryCatch({
  con <- url("https://cdn.posit.co/r/ubuntu-2404/pkgs/r-4.4.0_1_amd64.deb", open = "rb")
  close(con)
  "reachable"
}, error = function(e) conditionMessage(e))
say("- Posit's build of R 4.4.0 for Ubuntu 24.04: ", status)

say("")
say("## Node.js runtime of the actions")
for (a in list(c("actions/checkout", "v4"), c("actions/checkout", "v5"), c("actions/checkout", "v6"),
               c("actions/upload-artifact", "v4"), c("actions/upload-artifact", "v5"),
               c("actions/upload-artifact", "v6"))) {
  yml <- tryCatch(fetch(sprintf("https://raw.githubusercontent.com/%s/refs/tags/%s/action.yml", a[1], a[2])),
                  error = function(e) "")
  using <- regmatches(yml, regexpr("using: *'?node[0-9]+", yml))
  say("- ", a[1], "@", a[2], ": ", if (length(using)) gsub("using: *'?", "", using) else "not found")
}
writeLines(lines, out_file)
