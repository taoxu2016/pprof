# Compare two Cox fixture directories and write a Markdown diff report.
#
# Usage, from the repository root:
#   Rscript dev/reference/cox/compare.R <old-dir> <new-dir> [--report FILE]
#
# Used for every regeneration of committed Cox fixtures (CLAUDE.md: regeneration needs approval and
# a diff report) and for the determinism check, where two generations must be identical. The exit
# status is 1 when anything differs. object_diff() is dev/reference/compare_fixtures.R's.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) stop("Usage: Rscript compare.R <old-dir> <new-dir> [--report FILE]", call. = FALSE)
old_dir <- args[[1]]
new_dir <- args[[2]]
report_file <- if (length(args) >= 4 && args[[3]] == "--report") args[[4]] else NULL
stopifnot(requireNamespace("jsonlite", quietly = TRUE), dir.exists(old_dir), dir.exists(new_dir))

# Recursive structural and numerical difference between two R objects.
object_diff <- function(a, b, path = "") {
  if (identical(a, b)) return(NULL)
  here <- if (nzchar(path)) path else "<root>"
  if (!identical(class(a), class(b))) {
    return(data.frame(path = here, kind = "class", detail = sprintf("%s vs %s", paste(class(a), collapse = "/"),
                                                                    paste(class(b), collapse = "/"))))
  }
  out <- NULL
  if (is.list(a) && !is.null(names(a)) && !is.null(names(b)) && !identical(names(a), names(b))) {
    # Named lists with different elements: the elements added and removed, by name, and the common ones
    # compared, so that an added output (the funnel limits of Phase C3) does not hide a change elsewhere.
    added <- setdiff(names(b), names(a))
    removed <- setdiff(names(a), names(b))
    common <- intersect(names(a), names(b))
    if (length(added)) out <- data.frame(path = here, kind = "added", detail = paste(added, collapse = ", "))
    if (length(removed)) {
      out <- rbind(out, data.frame(path = here, kind = "removed", detail = paste(removed, collapse = ", ")))
    }
    if (!identical(common, intersect(names(b), names(a)))) {
      out <- rbind(out, data.frame(path = here, kind = "order", detail = "the common elements are in another order"))
    }
    for (k in common) out <- rbind(out, object_diff(a[[k]], b[[k]], paste0(path, if (nzchar(path)) "$" else "", k)))
    return(out)
  }
  if (!identical(names(a), names(b))) out <- data.frame(path = here, kind = "names", detail = "names differ")
  if (is.list(a)) {
    if (length(a) != length(b)) {
      return(rbind(out, data.frame(path = here, kind = "length", detail = sprintf("%d vs %d", length(a), length(b)))))
    }
    keys <- if (!is.null(names(a)) && identical(names(a), names(b))) names(a) else seq_along(a)
    for (k in seq_along(a)) {
      label <- if (is.character(keys)) keys[[k]] else sprintf("[[%d]]", k)
      out <- rbind(out, object_diff(a[[k]], b[[k]], paste0(path, if (nzchar(path)) "$" else "", label)))
    }
    return(out)
  }
  if (length(a) != length(b)) {
    return(rbind(out, data.frame(path = here, kind = "length", detail = sprintf("%d vs %d", length(a), length(b)))))
  }
  va <- unclass(a)
  vb <- unclass(b)
  attributes(va) <- NULL
  attributes(vb) <- NULL
  if (identical(va, vb)) return(out)
  if (is.double(va) && is.double(vb)) {
    fin <- is.finite(va) & is.finite(vb)
    abs_diff <- if (any(fin)) max(abs(va[fin] - vb[fin])) else 0
    rel_diff <- if (any(fin)) max(abs(va[fin] - vb[fin]) / pmax(abs(vb[fin]), .Machine$double.xmin)) else 0
    detail <- sprintf("%d of %d values differ; max abs %.3g, max rel %.3g%s",
                      sum(va != vb | xor(is.na(va), is.na(vb)), na.rm = TRUE), length(va), abs_diff, rel_diff,
                      if (!identical(is.na(va), is.na(vb))) "; NA pattern differs" else "")
    return(rbind(out, data.frame(path = here, kind = "numeric", detail = detail)))
  }
  differing <- sum(as.character(va) != as.character(vb), na.rm = TRUE)
  rbind(out, data.frame(path = here, kind = "value", detail = sprintf("%d of %d values differ", differing, length(va))))
}

old_manifest <- jsonlite::read_json(file.path(old_dir, "manifest.json"))
new_manifest <- jsonlite::read_json(file.path(new_dir, "manifest.json"))
package_changes <- function(old, new) {
  keys <- union(names(old), names(new))
  keys <- keys[vapply(keys, function(k) !identical(old[[k]], new[[k]]), logical(1))]
  if (!length(keys)) return(character())
  sprintf("- %s: %s -> %s", keys, vapply(old[keys], function(x) if (is.null(x)) "-" else x, ""),
          vapply(new[keys], function(x) if (is.null(x)) "-" else x, ""))
}
env_lines <- c(package_changes(old_manifest$python$packages, new_manifest$python$packages),
               package_changes(old_manifest$r$packages, new_manifest$r$packages),
               if (!identical(old_manifest$python$platform, new_manifest$python$platform)) {
                 sprintf("- platform: %s -> %s", old_manifest$python$platform, new_manifest$python$platform)
               })
old_ids <- names(old_manifest$cases)
new_ids <- names(new_manifest$cases)
removed <- setdiff(old_ids, new_ids)
added <- setdiff(new_ids, old_ids)
changed <- list()
for (id in intersect(old_ids, new_ids)) {
  parts <- c("case", "input", "pprof_py", "survival")
  d <- object_diff(readRDS(file.path(old_dir, paste0(id, ".rds")))[parts],
                   readRDS(file.path(new_dir, paste0(id, ".rds")))[parts])
  if (!is.null(d) && nrow(d)) changed[[id]] <- d
}
lines <- c(sprintf("# Cox fixture comparison: `%s` versus `%s`", old_dir, new_dir), "",
           sprintf("- Old: generator commit %s%s", old_manifest$generator_commit,
                   if (isTRUE(old_manifest$generator_clean)) "" else " (with uncommitted changes)"),
           sprintf("- New: generator commit %s%s", new_manifest$generator_commit,
                   if (isTRUE(new_manifest$generator_clean)) "" else " (with uncommitted changes)"), "",
           "## Environment", "", if (length(env_lines)) env_lines else "- Unchanged.", "",
           "## Summary", "",
           sprintf("- Cases: %d old, %d new; %d identical, %d changed, %d added, %d removed.", length(old_ids),
                   length(new_ids), length(intersect(old_ids, new_ids)) - length(changed), length(changed),
                   length(added), length(removed)), "")
if (length(added)) lines <- c(lines, "## Added cases", "", paste0("- ", added), "")
if (length(removed)) lines <- c(lines, "## Removed cases", "", paste0("- ", removed), "")
if (length(changed)) {
  lines <- c(lines, "## Changed cases", "")
  for (id in names(changed)) {
    d <- changed[[id]]
    lines <- c(lines, sprintf("### %s", id), "", "| Path | Kind | Detail |", "|---|---|---|",
               sprintf("| `%s` | %s | %s |", d$path, d$kind, d$detail), "")
  }
}
if (is.null(report_file)) cat(lines, sep = "\n") else writeLines(lines, report_file)
identical_all <- !length(changed) && !length(added) && !length(removed)
only_additions <- length(changed) && !length(added) && !length(removed) &&
  all(vapply(changed, function(d) all(d$kind == "added"), logical(1)))
cat(if (identical_all) "Fixtures identical.\n" else if (only_additions) {
  "Fixtures differ only by added outputs.\n"
} else {
  "Fixtures differ.\n"
})
quit(status = if (identical_all) 0L else 1L)
