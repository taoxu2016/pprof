# The help against the code (D-02, D-25; PHASE8_PLAN F7). R CMD check compares each page's
# \usage with the functions (codoc), but not the defaults the argument descriptions state in
# prose: pprof 1.0.3's help said that `backtrack` defaulted to FALSE (D-02) and gave no default
# for logis_firth()'s `max.iter` (D-25). Every value an argument's description states as its
# default must equal the default in formals() of each function on the page with that argument.

# The parsed help pages: from man/ in the source tree, else from the installed package.
documentation_pages <- function() {
  man <- file.path(testthat::test_path(), "..", "..", "man")
  if (!dir.exists(man)) return(tools::Rd_db("pprof"))
  macros <- tools::loadRdMacros(file.path(R.home("share"), "Rd", "macros", "system.Rd"))
  files <- list.files(man, pattern = "[.]Rd$", full.names = TRUE)
  stats::setNames(lapply(files, tools::parse_Rd, macros = macros), basename(files))
}

documentation_text <- function(x) {
  paste(unlist(lapply(x, function(e) if (is.list(e)) documentation_text(e) else as.character(e))), collapse = "")
}

# The value after "default is", "default value is", "defaults to", or "default:", up to a full
# stop that ends a sentence (not a decimal point) or a semicolon, without \code{} and
# thousands separators. NA where the description says "by default" without a value.
documentation_stated_default <- function(text) {
  pattern <- "([Dd]efaults? (value )?(is|are|to)|[Dd]efault:|by default)[^;]*"
  hit <- regmatches(text, regexpr(pattern, text, perl = TRUE))
  if (!length(hit)) return(NULL)
  if (startsWith(hit, "by default")) return(NA_character_)
  value <- sub("^.*?([Dd]efaults? (value )?(is|are|to)|[Dd]efault:)\\s*", "", hit, perl = TRUE)
  value <- sub("(\\.(\\s|$)|;).*$", "", value, perl = TRUE)
  value <- gsub("\\\\code\\{|\\}|`", "", value)
  value <- trimws(sub(",\\s+(which|so|meaning|the|i\\.e\\.|e\\.g\\.).*$", "", value))
  gsub(",(?=\\d{3}\\b)", "", value, perl = TRUE)
}

documentation_defaults <- function() {
  ns <- asNamespace("pprof")
  rows <- list()
  for (page_name in names(pages <- documentation_pages())) {
    page <- pages[[page_name]]
    tags <- vapply(page, function(e) attr(e, "Rd_tag"), character(1))
    if (!any(tags == "\\arguments")) next
    aliases <- trimws(unlist(lapply(page[tags == "\\alias"], documentation_text)))
    functions <- intersect(aliases, ls(ns, all.names = TRUE))
    functions <- functions[vapply(functions, function(f) is.function(get(f, ns)), logical(1))]
    for (item in page[[which(tags == "\\arguments")[1]]]) {
      if (!identical(attr(item, "Rd_tag"), "\\item")) next
      stated <- documentation_stated_default(gsub("\\s+", " ", documentation_text(item[[2]])))
      if (is.null(stated)) next
      for (argument in trimws(strsplit(documentation_text(item[[1]]), ",")[[1]])) {
        for (f in functions) {
          if (!argument %in% names(formals(get(f, ns)))) next
          rows[[length(rows) + 1L]] <- list(page = page_name, fun = f, arg = argument, stated = stated,
                                            formal = formals(get(f, ns))[[argument]])
        }
      }
    }
  }
  rows
}

test_that("the defaults stated in the help are those of the functions (D-02, D-25)", {
  rows <- documentation_defaults()
  stated <- Filter(function(row) !is.na(row$stated), rows)
  # F7 found 31 statements with a value, without "default value is"; the count guards the
  # parser against finding nothing.
  expect_gt(length(stated), 31L)
  for (row in stated) {
    label <- sprintf("%s: %s(%s) says the default is %s", row$page, row$fun, row$arg, row$stated)
    value <- tryCatch(eval(str2lang(row$stated), baseenv()), error = function(e) e)
    expect_false(inherits(value, "error"), label = paste(label, "(a value that parses as R)"))
    if (inherits(value, "error")) next
    expect_equal(value, eval(row$formal, baseenv()), label = label)
  }
  # D-02 and D-25 among them.
  found <- vapply(stated, function(row) paste(row$fun, row$arg), character(1))
  expect_true(all(c("logis_fe backtrack", "logis_firth max.iter") %in% found))
})
