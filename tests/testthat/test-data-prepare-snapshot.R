# The existing families' data stay identical (COXPH_DESIGN §C.2; the CoxPH C2 plan, §4.1): every
# `pprof_data` object the reference cases build has the signature recorded before the CoxPH phase
# changed the data layer (dev/tools/data_prepare_snapshot.R; helper-data-snapshot.R). The signatures
# are bitwise for doubles, so they are compared on the platform that produced the reference fixtures
# (DEC-080), and the snapshot is read from validation/, which the package build leaves out.

test_that("the reference cases build the pprof_data objects of the snapshot", {
  skip_on_cran()
  path <- data_snapshot_file()
  if (!file.exists(path)) skip("no data_prepare() snapshot here (validation/fixtures/)")
  skip_off_reference_platform("core")
  snapshot <- readRDS(path)
  for (set in names(snapshot$sets)) {
    recorded <- snapshot$sets[[set]]
    if (identical(set, "full") && is.null(reference_manifest("full"))) next
    current <- data_snapshot_record(names(recorded$cases), set)
    for (id in names(recorded$cases)) {
      now <- current$signatures[current$cases[[id]]]
      before <- recorded$signatures[recorded$cases[[id]]]
      differs <- if (length(now) != length(before)) {
        sprintf("%d objects, %d in the snapshot", length(now), length(before))
      } else {
        changed <- unlist(lapply(seq_along(now), function(k) {
          names_now <- names(now[[k]])
          if (!identical(names_now, names(before[[k]]))) return(sprintf("object %d has elements %s", k,
                                                                      paste(names_now, collapse = ", ")))
          different <- names_now[now[[k]] != before[[k]]]
          if (length(different)) sprintf("object %d differs in %s", k, paste(different, collapse = ", "))
        }))
        if (length(changed)) paste(changed, collapse = "; ")
      }
      expect(is.null(differs), sprintf("%s case %s: %s", set, id, differs))
    }
  }
})
