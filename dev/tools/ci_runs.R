# The CI runs of the fork (taoxu2016/pprof), read through the public GitHub
# API without signing in: every workflow run; for the runs given, their jobs, the steps that did
# not succeed, the annotations, and the artifacts. Job logs and artifact downloads need a
# signed-in account (the log endpoint answers 403 without one), so they are not read here.
# The unauthenticated API allows 60 requests an hour; this script makes about 20.
# Run from the repository root: Rscript <this file> <output file> <run id> [<run id> ...]
# Set PPROF_CI_MESSAGE_CHARS to print more of each annotation (default 400 characters).
args <- commandArgs(trailingOnly = TRUE)
out_file <- args[1]
run_ids <- args[-1]
max_message <- as.integer(Sys.getenv("PPROF_CI_MESSAGE_CHARS", "400"))
lines <- character()
say <- function(...) lines <<- c(lines, paste0(...))

api <- function(path) {
  con <- url(paste0("https://api.github.com/repos/taoxu2016/pprof/", path),
             headers = c(Accept = "application/vnd.github+json"))
  on.exit(close(con))
  jsonlite::fromJSON(paste(readLines(con, warn = FALSE), collapse = "\n"), simplifyVector = FALSE)
}
# Notices that every job repeats; reported once instead of per job.
routine <- c("Node.js 20 is deprecated", "Due to capacity constraints", "will migrate to Ubuntu 26")

say("Read ", format(Sys.time(), tz = "UTC", usetz = TRUE), " from https://api.github.com/repos/taoxu2016/pprof")
runs <- api("actions/runs?per_page=100")
say("")
say("## All workflow runs (", runs$total_count, ")")
say("")
say("| Created (UTC) | Branch | Commit | Workflow | Event | Status | Conclusion | Run |")
say("|---|---|---|---|---|---|---|---|")
for (r in rev(runs$workflow_runs)) {
  say(sprintf("| %s | %s | %s | %s | %s | %s | %s | %s |", substr(r$created_at, 1, 16), r$head_branch,
              substr(r$head_sha, 1, 7), r$name, r$event, r$status,
              if (is.null(r$conclusion)) "" else r$conclusion, format(r$id, scientific = FALSE)))
}

seen_routine <- character()
for (id in run_ids) {
  run <- Filter(function(r) identical(format(r$id, scientific = FALSE), id), runs$workflow_runs)[[1]]
  say("")
  say("## Run ", id, ": ", run$name, " on ", run$head_branch, " at ", substr(run$head_sha, 1, 7), " (",
      run$status, if (!is.null(run$conclusion)) paste0(", ", run$conclusion), ")")
  jobs <- api(paste0("actions/runs/", id, "/jobs?per_page=50"))$jobs
  for (j in jobs) {
    say("")
    say("- Job \"", j$name, "\": ", j$status, if (!is.null(j$conclusion)) paste0(", ", j$conclusion), "; ",
        j$started_at, " to ", if (is.null(j$completed_at)) "(running)" else j$completed_at)
    for (s in j$steps) {
      if (!identical(s$conclusion, "success") && !identical(s$conclusion, "skipped")) {
        say("  - step ", s$number, " \"", s$name, "\": ", s$status, if (!is.null(s$conclusion)) paste0(", ", s$conclusion),
            "; ", if (is.null(s$started_at)) "" else s$started_at, " to ",
            if (is.null(s$completed_at)) "" else s$completed_at)
      }
    }
    for (a in api(paste0("check-runs/", format(j$id, scientific = FALSE), "/annotations?per_page=50"))) {
      msg <- gsub("\\s+", " ", a$message)
      hit <- routine[vapply(routine, grepl, logical(1), x = msg, fixed = TRUE)]
      if (length(hit)) {
        if (!hit[1] %in% seen_routine) seen_routine <- c(seen_routine, hit[1])
        next
      }
      title <- if (is.null(a$title) || !nzchar(a$title)) "" else paste0(a$title, " :: ")
      say("  - annotation [", a$annotation_level, "] log line ", a$start_line, ": ", title,
          substr(msg, 1, max_message))
    }
  }
  artifacts <- api(paste0("actions/runs/", id, "/artifacts"))$artifacts
  if (length(artifacts)) {
    say("")
    say("Artifacts: ", paste(vapply(artifacts, function(a) sprintf("%s (%.1f MB)", a$name, a$size_in_bytes / 1e6), ""),
                             collapse = "; "))
  }
}
say("")
say("Routine annotations seen (not repeated above): ", paste(seen_routine, collapse = "; "))
writeLines(lines, out_file)
