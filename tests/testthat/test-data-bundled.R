# The help of the bundled data states their sizes correctly (D-35: pprof 1.0.3 documented
# ExampleDataBinary as 7,994 observations; it has 7,944).
local_strict_mode()

# The text of a help page: from the sources' man/ when they are available (devtools::test()),
# otherwise from the installed package (R CMD check), with white space collapsed.
bundled_help_text <- function(topic) {
  man_file <- test_path("..", "..", "man", paste0(topic, ".Rd"))
  rd <- if (file.exists(man_file)) tools::parse_Rd(man_file) else tools::Rd_db("pprof")[[paste0(topic, ".Rd")]]
  text <- utils::capture.output(tools::Rd2txt(rd, options = list(underline_titles = FALSE)))
  gsub("[[:space:]]+", " ", paste(text, collapse = " "))
}

test_that("the help of the simulated examples states their numbers of observations, covariates, and providers", {
  for (name in c("ExampleDataBinary", "ExampleDataLinear")) {
    example <- get(utils::data(list = name, package = "pprof", envir = environment()))
    expected <- sprintf("%d observations, %d continuous covariates and %d providers",
                        length(example$Y), ncol(example$Z), length(unique(example$ProvID)))
    expect_match(bundled_help_text(name), expected, fixed = TRUE)
  }
})

test_that("the help of ecls_data states its numbers of children and schools", {
  utils::data("ecls_data", package = "pprof", envir = environment())
  children <- format(nrow(ecls_data), big.mark = ",")
  schools <- format(length(unique(ecls_data$School_ID)), big.mark = ",")
  text <- bundled_help_text("ecls_data")
  expect_match(text, sprintf("%s complete observations from %s schools", children, schools), fixed = TRUE)
  expect_match(text, sprintf("A data frame with %s observations", children), fixed = TRUE)
})
