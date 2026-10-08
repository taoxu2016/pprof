# The last step of the Cox fixture generator (dev/reference/cox/README.md): one RDS fixture per
# staged case, with every hexadecimal double read back exactly.
#
# Usage (generate.py runs it): Rscript --vanilla convert.R <staging> <core-dir> <full-dir> <library> <case-id> ...
# Each fixture <id>.rds goes to the core or the full directory as the case's `set` says, and holds
# list(format_version, case, input, pprof_py, survival): the case definition, the input as a data
# frame, and both references' outputs as nested lists of numeric, integer, logical, and character
# vectors. generate.py then hashes the files and writes each directory's manifest.json.
args <- commandArgs(trailingOnly = TRUE)
staging <- args[[1]]
out_dirs <- c(core = args[[2]], full = args[[3]])
.libPaths(c(normalizePath(args[[4]], winslash = "/"), .Library))
ids <- args[-(1:4)]
suppressPackageStartupMessages(library(jsonlite))
format_version <- 1L

# Python's float.hex() and R's "%a" spellings, with their infinities and NaN.
hex_pattern <- "^-?(0x[0-9a-fA-F]+(\\.[0-9a-fA-F]*)?p[+-]?[0-9]+|inf|Inf|nan|NaN|NA)$"
decode <- function(x) {
  if (is.list(x)) return(lapply(x, decode))
  if (is.character(x) && length(x) && all(grepl(hex_pattern, x))) return(suppressWarnings(as.numeric(x)))
  x
}
read_staged <- function(path) read_json(path, simplifyVector = TRUE, simplifyDataFrame = FALSE, simplifyMatrix = FALSE)

for (dir in out_dirs) dir.create(dir, recursive = TRUE, showWarnings = FALSE)
for (id in ids) {
  case_dir <- file.path(staging, id)
  definition <- read_staged(file.path(case_dir, "case.json"))
  input <- read_json(file.path(case_dir, "input.json"))
  columns <- lapply(input$names, function(name) {
    v <- unlist(input$columns[[name]])
    if (identical(input$types[[name]], "double")) as.numeric(v) else as.integer(v)
  })
  names(columns) <- unlist(input$names)
  fixture <- list(format_version = format_version, case = definition,
                  input = as.data.frame(columns, optional = TRUE),
                  pprof_py = decode(read_staged(file.path(case_dir, "pprof_py.json"))),
                  survival = decode(read_staged(file.path(case_dir, "survival.json"))))
  path <- file.path(out_dirs[[definition$set]], paste0(id, ".rds"))
  saveRDS(fixture, path, compress = "xz", version = 3)
  cat(id, "->", path, "\n")
}
