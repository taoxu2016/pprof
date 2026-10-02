# The data layer reproduces the reference's processed data of every fit fixture exactly:
# rows, row order, row names, response, provider values, design columns and names,
# screening indicators, the CRE decomposition, and the provider order (Phase 2 plan).
local_strict_mode()

for (set in c("core", "full")) {
  ids <- reference_value_fit_ids(set)
  if (set == "core" && length(ids) == 0L) {
    test_that("reference fit fixtures are available", skip("Reference fixtures or jsonlite not available"))
  }
  for (id in ids) {
    local({
      case_id <- id
      case_set <- set
      test_that(paste("data layer reproduces the reference data:", case_id), {
        if (identical(case_set, "full")) skip_on_cran()
        expect_reference_data(case_id, case_set)
      })
    })
  }
}
