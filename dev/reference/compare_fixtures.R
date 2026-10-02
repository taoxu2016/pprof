# Compare two fixture directories and write a Markdown diff report.
#
# Usage, from the repository root:
#   Rscript dev/reference/compare_fixtures.R <old-dir> <new-dir> [--report FILE]
#
# Used for every regeneration of committed fixtures (CLAUDE.md: regeneration needs approval
# and a diff report) and for the determinism check, where two independent generations must
# be identical. Exit status is 1 when anything differs.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) stop("Usage: Rscript compare_fixtures.R <old-dir> <new-dir> [--report FILE]", call. = FALSE)
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
  attr_a <- attributes(a)
  attr_b <- attributes(b)
  for (nm in setdiff(union(names(attr_a), names(attr_b)), c("names", "class"))) {
    if (!identical(attr_a[[nm]], attr_b[[nm]])) {
      out <- rbind(out, object_diff(attr_a[[nm]], attr_b[[nm]], paste0(path, "@", nm)))
    }
  }
  if (!identical(names(a), names(b))) {
    out <- rbind(out, data.frame(path = here, kind = "names", detail = "names differ"))
  }
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
    same_na <- identical(is.na(va), is.na(vb)) && identical(is.nan(va), is.nan(vb))
    fin <- is.finite(va) & is.finite(vb)
    abs_diff <- if (any(fin)) max(abs(va[fin] - vb[fin])) else 0
    rel_diff <- if (any(fin)) max(abs(va[fin] - vb[fin]) / pmax(abs(vb[fin]), .Machine$double.xmin)) else 0
    inf_differs <- !identical(va[!fin & !is.na(va)], vb[!fin & !is.na(vb)])
    detail <- sprintf("%d of %d values differ; max abs %.3g, max rel %.3g%s%s", sum(va != vb | xor(is.na(va), is.na(vb)), na.rm = TRUE),
                      length(va), abs_diff, rel_diff, if (!same_na) "; NA pattern differs" else "",
                      if (inf_differs) "; infinite values differ" else "")
    return(rbind(out, data.frame(path = here, kind = "numeric", detail = detail)))
  }
  rbind(out, data.frame(path = here, kind = "value", detail = sprintf("%d of %d values differ",
                                                                      sum(as.character(va) != as.character(vb), na.rm = TRUE), length(va))))
}

read_manifest <- function(dir) jsonlite::read_json(file.path(dir, "manifest.json"))
old_manifest <- read_manifest(old_dir)
new_manifest <- read_manifest(new_dir)
old_ids <- vapply(old_manifest$cases, `[[`, character(1), "id")
new_ids <- vapply(new_manifest$cases, `[[`, character(1), "id")

lines <- c(sprintf("# Fixture comparison: `%s` versus `%s`", old_dir, new_dir), "",
           sprintf("- Old: generated %s from commit %s", old_manifest$generated_at, old_manifest$generator$git_commit),
           sprintf("- New: generated %s from commit %s", new_manifest$generated_at, new_manifest$generator$git_commit), "")

env_old <- old_manifest$numerically_relevant_packages
env_new <- new_manifest$numerically_relevant_packages
env_changes <- union(names(env_old), names(env_new))
env_changes <- env_changes[vapply(env_changes, function(p) !identical(env_old[[p]], env_new[[p]]), logical(1))]
lines <- c(lines, "## Environment", "",
           if (length(env_changes)) sprintf("- %s: %s -> %s", env_changes, vapply(env_old[env_changes], function(x) if (is.null(x)) "-" else x, ""),
                                            vapply(env_new[env_changes], function(x) if (is.null(x)) "-" else x, ""))
           else "- Numerically relevant package versions unchanged.", "")

removed <- setdiff(old_ids, new_ids)
added <- setdiff(new_ids, old_ids)
common <- intersect(old_ids, new_ids)
changed <- list()
for (id in common) {
  a <- readRDS(file.path(old_dir, paste0(id, ".rds")))
  b <- readRDS(file.path(new_dir, paste0(id, ".rds")))
  d <- object_diff(a$result, b$result)
  if (!identical(a$case, b$case)) d <- rbind(data.frame(path = "case", kind = "case", detail = "case definition changed"), d)
  if (!is.null(d) && nrow(d)) changed[[id]] <- d
}
old_ds <- vapply(old_manifest$datasets, function(x) x$md5, character(1))
names(old_ds) <- vapply(old_manifest$datasets, function(x) x$name, character(1))
new_ds <- vapply(new_manifest$datasets, function(x) x$md5, character(1))
names(new_ds) <- vapply(new_manifest$datasets, function(x) x$name, character(1))
ds_changed <- names(new_ds)[names(new_ds) %in% names(old_ds) & new_ds[names(new_ds)] != old_ds[names(new_ds)]]

lines <- c(lines, "## Summary", "",
           sprintf("- Cases: %d old, %d new; %d identical, %d changed, %d added, %d removed.",
                   length(old_ids), length(new_ids), length(common) - length(changed), length(changed), length(added), length(removed)),
           sprintf("- Datasets changed: %s.", if (length(ds_changed)) paste(ds_changed, collapse = ", ") else "none"), "")
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
identical_all <- !length(changed) && !length(added) && !length(removed) && !length(ds_changed)
cat(sprintf("%s\n", if (identical_all) "Fixtures identical." else "Fixtures differ."))
quit(status = if (identical_all) 0L else 1L)
