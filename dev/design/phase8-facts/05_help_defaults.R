# Phase 8 planning: the statements of default values in the help's argument descriptions against
# formals() (D-02, D-25 plan "a check of the help against formals()"). R CMD check already compares
# the \usage sections with the code (codoc); this looks at the prose. For each \item of each page's
# \arguments, find "default is", "defaults to", "default:", or "by default", take the value stated,
# parse it as R, and compare it with the default of every function on the page that has the
# argument. A statement without a value ("... by default") is listed as such.
# Run from the repository root: Rscript <this file> <output file> <library with pprof installed>
args <- commandArgs(trailingOnly = TRUE)
out_file <- args[1]
lib <- args[2]
suppressMessages(library(pprof, lib.loc = lib))
lines <- character()
say <- function(...) lines <<- c(lines, paste0(...))
db <- tools::Rd_db("pprof", lib.loc = lib)
ns <- asNamespace("pprof")

rd_text <- function(x) {
  paste(unlist(lapply(x, function(e) if (is.list(e)) rd_text(e) else as.character(e))), collapse = "")
}
# The value after the phrase, up to a full stop that ends a sentence (not a decimal point), a
# semicolon, or a comma that follows a closed expression.
stated_value <- function(statement) {
  value <- sub("^.*?(defaults? (is|to|are)|default:)\\s*", "", statement, perl = TRUE, ignore.case = TRUE)
  value <- sub("(\\.(\\s|$)|;).*$", "", value, perl = TRUE)
  value <- gsub("\\\\code\\{|\\}|`", "", value)
  trimws(sub(",\\s+(which|so|meaning|the|i\\.e\\.|e\\.g\\.).*$", "", value))
}
compare <- function(value, formal) {
  parsed <- tryCatch(str2lang(gsub(",(?=\\d{3}\\b)", "", value, perl = TRUE)), error = function(e) NULL)
  if (is.null(parsed)) return("value not parsed")
  stated <- tryCatch(eval(parsed, baseenv()), error = function(e) NULL)
  actual <- tryCatch(eval(formal, baseenv()), error = function(e) NULL)
  if (is.null(stated) || is.null(actual)) return(if (identical(parsed, formal)) "agrees" else "not comparable")
  if (identical(stated, actual) || isTRUE(all.equal(stated, actual))) "agrees" else "DISAGREES"
}

rows <- list()
for (page in names(db)) {
  rd <- db[[page]]
  tags <- vapply(rd, function(e) attr(e, "Rd_tag"), "")
  if (!any(tags == "\\arguments")) next
  aliases <- trimws(unlist(lapply(rd[tags == "\\alias"], rd_text)))
  funs <- intersect(aliases, ls(ns, all.names = TRUE))
  funs <- funs[vapply(funs, function(f) is.function(get(f, ns)), logical(1))]
  for (item in rd[[which(tags == "\\arguments")[1]]]) {
    if (!identical(attr(item, "Rd_tag"), "\\item")) next
    arg_names <- trimws(strsplit(rd_text(item[[1]]), ",")[[1]])
    text <- gsub("\\s+", " ", rd_text(item[[2]]))
    hit <- regmatches(text, regexpr("([Dd]efaults? (is|to|are)|[Dd]efault:|by default)[^;]*", text, perl = TRUE))
    if (!length(hit)) next
    by_default_only <- grepl("^by default", hit)
    value <- if (by_default_only) "" else stated_value(hit)
    for (a in arg_names) {
      owners <- funs[vapply(funs, function(f) a %in% names(formals(get(f, ns))), logical(1))]
      for (f in owners) {
        formal <- formals(get(f, ns))[[a]]
        rows[[length(rows) + 1]] <- data.frame(
          page = page, fun = f, arg = a, stated = if (by_default_only) "(no value stated)" else value,
          formal = paste(deparse(formal), collapse = " "),
          verdict = if (by_default_only) "no value stated" else compare(value, formal)
        )
      }
    }
  }
}
res <- do.call(rbind, rows)
say("pprof ", as.character(utils::packageVersion("pprof", lib.loc = lib)), " from ", lib)
say(nrow(res), " statements (function and argument) on ", length(unique(res$page)), " pages; verdicts: ",
    paste(sprintf("%s %d", names(table(res$verdict)), table(res$verdict)), collapse = ", "))
say("")
say("| Page | Function | Argument | Stated | formals() | Verdict |")
say("|---|---|---|---|---|---|")
for (i in seq_len(nrow(res))) {
  say(sprintf("| %s | %s | %s | %s | %s | %s |", res$page[i], res$fun[i], res$arg[i], res$stated[i],
              res$formal[i], res$verdict[i]))
}
writeLines(lines, out_file)
