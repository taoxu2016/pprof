# Phase 6, step 3: the guard that the old plot functions draw the same plots after they move
# to the compatibility layer and lose dplyr, magrittr, and rlang (DEC-055).
#
# For plot() of logis_fe and linear_fe fits, caterpillar_plot(), and bar_plot(), on the inputs
# of the reference's plot fixture cases (run through the working tree with the fixtures' case
# runner) and on a grid of every family's outputs, saves: the outcome and error class; the
# plot's data (its class, and the data as a data frame) and mapping; for each layer the geom,
# stat, and position classes, the mapping expressions as text, the parameters, the data given
# to the layer, and the built data; the labels; the built non-position scales (limits, breaks,
# labels, mapped values); the guides' data; and the theme. Warnings are not recorded.
# Run before step 3 to save the snapshot, and after each commit of step 3 to compare: every
# record must be identical, except the class of bar_plot()'s plot data, which is a grouped
# tibble from dplyr in the reference and a data frame without dplyr (the data are identical),
# and the class and message of errors where the wrappers raise classed errors (reported
# separately). Themes are compared by the checksum of their serialization (theme_record()).
#
# Usage, from the repository root:
#   Rscript dev/design/phase6-facts/08_plot_guard.R save <snapshot.rds>
#   Rscript dev/design/phase6-facts/08_plot_guard.R compare <snapshot.rds> <report.txt>
args <- commandArgs(trailingOnly = TRUE)
mode <- args[1]
snapshot_file <- args[2]
Sys.setlocale("LC_COLLATE", "C")
Sys.setenv(OMP_THREAD_LIMIT = "1")
suppressMessages(devtools::load_all(quiet = TRUE))
source("tests/testthat/helper-reference-cases.R")
quiet <- function(expr) suppressMessages(suppressWarnings(expr))

# --- What is recorded of a plot ----------------------------------------------------------------
expression_text <- function(q) paste(deparse(rlang::quo_get_expr(q)), collapse = " ")
without_functions <- function(x) if (is.list(x)) x[!vapply(x, is.function, logical(1))] else x

scale_record <- function(scale) {
  position <- any(scale$aesthetics %in% c("x", "y", "xmin", "xmax", "ymin", "ymax", "xend", "yend"))
  limits <- tryCatch(scale$get_limits(), error = function(e) conditionMessage(e))
  list(aesthetics = scale$aesthetics, class = class(scale)[1], limits = limits,
       breaks = tryCatch(scale$get_breaks(), error = function(e) conditionMessage(e)),
       labels = tryCatch(scale$get_labels(), error = function(e) conditionMessage(e)),
       mapped = if (!position && scale$is_discrete()) tryCatch(scale$map(limits), error = function(e) NULL))
}

plot_record <- function(p) {
  built <- quiet(ggplot2::ggplot_build(p))
  layers <- lapply(seq_along(p$layers), function(k) {
    layer <- p$layers[[k]]
    list(geom = class(layer$geom)[1], stat = class(layer$stat)[1], position = class(layer$position)[1],
         mapping = vapply(layer$mapping, expression_text, ""), aes_params = without_functions(layer$aes_params),
         geom_params = without_functions(layer$geom_params), stat_params = without_functions(layer$stat_params),
         data = if (is.data.frame(layer$data)) as.data.frame(layer$data) else NULL, built = built$data[[k]])
  })
  # From the built plot, which gives the same guide data as the plot without building it again.
  guides <- lapply(c("colour", "fill", "shape", "linetype"), function(aesthetic) {
    tryCatch(quiet(ggplot2::get_guide_data(built, aesthetic)), error = function(e) conditionMessage(e))
  })
  names(guides) <- c("colour", "fill", "shape", "linetype")
  list(outcome = "value", data_class = class(p$data),
       data = if (is.data.frame(p$data)) as.data.frame(p$data) else NULL,
       mapping = vapply(p$mapping, expression_text, ""), layers = layers, labels = ggplot2::get_labs(p),
       scales = lapply(built$plot$scales$scales, scale_record), guides = guides, theme = theme_record(p$theme))
}

# The theme as the checksum of its serialization: ggplot2 4's theme elements carry their S7
# class, an environment that identical() compares by address, so a theme read back from a
# file is never identical() to a new one; their serializations are, but take about 2 MB each,
# because the class environments are written out with every theme.
theme_record <- function(theme) {
  if (is.character(theme)) return(theme)
  file <- tempfile()
  on.exit(unlink(file))
  connection <- file(file, "wb")
  serialize(theme, connection)
  close(connection)
  unname(tools::md5sum(file))
}

capture <- function(expr) {
  value <- tryCatch(quiet(expr), error = function(e) e)
  if (inherits(value, "error")) {
    return(list(outcome = "error", class = class(value), message = conditionMessage(value)))
  }
  plot_record(value)
}

results <- list()
keep <- function(label, expr) {
  results[[label]] <<- capture(expr)
}

# --- The inputs of the reference's plot fixture cases -------------------------------------
fixture_dir <- "tests/testthat/fixtures/reference"
manifest <- jsonlite::read_json(file.path(fixture_dir, "manifest.json"))
datasets <- list()
for (entry in manifest$datasets) datasets[[entry$name]] <- readRDS(file.path(fixture_dir, entry$file))
fixtures <- lapply(manifest$cases, function(entry) readRDS(file.path(fixture_dir, entry$file)))
names(fixtures) <- vapply(manifest$cases, `[[`, "", "id")
computed <- list()
run_case <- function(id) {
  if (!is.null(computed[[id]])) return(computed[[id]])
  case <- fixtures[[id]]$case
  parents <- unique(unlist(lapply(case$args, function(a) {
    if (inherits(a, "pprof_ref_fit") || inherits(a, "pprof_ref_value")) a$case_id
  })))
  parent_results <- list()
  for (parent in parents) parent_results[[parent]] <- run_case(parent)
  computed[[id]] <<- run_reference_case(case, datasets, parent_results)
  computed[[id]]
}
plot_cases <- names(fixtures)[vapply(fixtures, function(f) f$case$fun %in% c("plot", "caterpillar_plot", "bar_plot"),
                                     logical(1))]
for (id in plot_cases) {
  res <- run_case(id)
  results[[paste0("fixture:", id)]] <- if (identical(res$outcome, "error")) {
    list(outcome = "error", class = res$error$class, message = res$error$message)
  } else {
    plot_record(res$raw_value)
  }
}

# --- A grid on the outputs of every family ------------------------------------------------
data(ExampleDataBinary)
data(ExampleDataLinear)
bin <- data.frame(Y = ExampleDataBinary$Y, ProvID = ExampleDataBinary$ProvID, ExampleDataBinary$Z)
lin <- data.frame(Y = ExampleDataLinear$Y, ProvID = ExampleDataLinear$ProvID, ExampleDataLinear$Z)
z <- paste0("z", 1:5)
fe_args <- function(d) list(data = d, Y.char = "Y", Z.char = z, ProvID.char = "ProvID")
cre_args <- function(d) list(data = d, Y.char = "Y", ProvID.char = "ProvID", wb.char = c("z1", "z2"),
                             other.char = c("z3", "z4", "z5"))
extreme <- datasets$syn_extreme
singular <- datasets$syn_singular_linear
fits <- list(
  logis_fe = quiet(do.call(logis_fe, c(fe_args(bin), message = FALSE))),
  logis_fe_extreme = quiet(logis_fe(data = extreme, Y.char = "Y", Z.char = c("x1", "x2", "x3"), ProvID.char = "ProvID",
                                    message = FALSE)),
  linear_fe = quiet(do.call(linear_fe, fe_args(lin))),
  linear_fe_full = quiet(do.call(linear_fe, c(fe_args(lin), option.gamma.var = "full"))),
  linear_re = quiet(do.call(linear_re, fe_args(lin))),
  logis_re = quiet(do.call(logis_re, fe_args(bin))),
  linear_cre = quiet(do.call(linear_cre, cre_args(lin))),
  logis_cre = quiet(do.call(logis_cre, cre_args(bin))),
  linear_re_singular = quiet(linear_re(data = singular, Y.char = "Y", Z.char = c("x1", "x2", "x3"),
                                       ProvID.char = "ProvID"))
)

# plot() of logis_fe and linear_fe fits.
alphas <- list(a1 = 0.05, a2 = c(0.05, 0.01), a3 = c(0.1, 0.05, 0.01), none = 1e-6)
for (name in c("logis_fe", "logis_fe_extreme", "linear_fe", "linear_fe_full")) {
  fit <- fits[[name]]
  nulls <- if (startsWith(name, "linear")) list("median", "mean", 0.5) else list("median", 0, -0.2)
  for (a in names(alphas)) for (k in seq_along(nulls)) {
    keep(sprintf("plot:%s:%s:null%d", name, a, k), plot(fit, null = nulls[[k]], alpha = alphas[[a]]))
  }
  keep(sprintf("plot:%s:styled", name),
       plot(fit, target = if (startsWith(name, "linear")) 0.1 else 1.1, labels = c("low", "mid", "high"),
            point_colors = c("red", "grey", "blue"), point_shapes = c(1, 2, 3), point_size = 3, point_alpha = 0.5,
            line_size = 1.2, target_line_type = "dotted"))
}
keep("plot:logis_fe:exact", plot(fits$logis_fe, test = "exact"))

# caterpillar_plot() on the confint() tables of every family.
for (name in names(fits)) {
  fit <- fits[[name]]
  tests <- if (startsWith(name, "logis_fe")) c("wald", "score", "exact") else "default"
  for (tt in tests) for (alternative in c("two.sided", "greater", "less")) {
    ci_args <- list(fit, option = "SM", stdz = c("indirect", "direct"), alternative = alternative)
    if (tt != "default") ci_args$test <- tt
    cis <- tryCatch(quiet(do.call(confint, ci_args)), error = function(e) NULL)
    if (is.null(cis)) {
      results[[sprintf("confint:%s:%s:%s", name, tt, alternative)]] <- list(outcome = "error")
      next
    }
    for (element in names(cis)) {
      ci <- cis[[element]]
      for (orientation in c("vertical", "horizontal")) for (flag in c(FALSE, TRUE)) {
        keep(sprintf("caterpillar:%s:%s:%s:%s:%s:%s", name, tt, alternative, element, orientation, flag),
             caterpillar_plot(ci, use_flag = flag, orientation = orientation))
      }
    }
  }
}
ci <- quiet(confint(fits$logis_fe, option = "SM", test = "wald"))$CI.indirect_ratio
keep("caterpillar:styled", caterpillar_plot(ci, point_size = 3, point_color = "black", refline_value = 0.9,
                                            refline_color = "red", refline_size = 2, refline_type = "dotted",
                                            errorbar_width = 0.4, errorbar_size = 1, errorbar_alpha = 0.9,
                                            errorbar_color = "grey", use_flag = TRUE,
                                            flag_color = c("red", "green", "blue")))
keep("caterpillar:styled-horizontal", caterpillar_plot(ci, refline_value = 1.2, orientation = "horizontal",
                                                       use_flag = TRUE, errorbar_width = 0.3))
keep("caterpillar:gamma", caterpillar_plot(quiet(confint(fits$logis_fe, option = "gamma", test = "wald"))))
keep("caterpillar:matrix", caterpillar_plot(as.matrix(ci)))
keep("caterpillar:tibble", caterpillar_plot(tibble::as_tibble(ci)))
keep("caterpillar:diagonal", caterpillar_plot(ci, orientation = "diagonal"))
keep("caterpillar:missing", caterpillar_plot())
no_type <- ci
attr(no_type, "type") <- "unknown"
keep("caterpillar:unknown-type", caterpillar_plot(no_type))
no_reference <- ci
attr(no_reference, "description") <- "Indirect Standardized Something"
keep("caterpillar:no-reference", caterpillar_plot(no_reference))
keep("caterpillar:no-reference-given", caterpillar_plot(no_reference, refline_value = 1))

# bar_plot() on the test() results of every family.
for (name in names(fits)) {
  for (alternative in c("two.sided", "greater", "less")) {
    tests <- tryCatch(quiet(test(fits[[name]], alternative = alternative)), error = function(e) NULL)
    if (is.null(tests)) next
    for (g in c(1, 3, 4)) keep(sprintf("bar:%s:%s:%d", name, alternative, g), bar_plot(tests, group_num = g))
  }
}
tests <- quiet(test(fits$logis_fe))
keep("bar:styled", bar_plot(tests, bar_colors = c("red", "grey", "blue"), bar_width = 0.3, label_color = "white",
                            label_size = 6))
keep("bar:group-num-60", bar_plot(tests, group_num = 60))
one <- tests[1, , drop = FALSE]
attr(one, "provider size") <- attr(tests, "provider size")[1]
keep("bar:one-provider", bar_plot(one))
no_size <- tests
attr(no_size, "provider size") <- NULL
keep("bar:no-size", bar_plot(no_size))
keep("bar:matrix", bar_plot(as.matrix(tests)))
keep("bar:missing", bar_plot())
only_expected <- tests
only_expected$flag <- factor(rep(0, nrow(tests)))
keep("bar:only-expected", bar_plot(only_expected))

# --- Save or compare ------------------------------------------------------------------------
rm(computed, fits)
invisible(gc())
if (mode == "save") {
  saveRDS(results, snapshot_file)
  cat(sprintf("Saved %d records (%d errors) to %s\n", length(results),
              sum(vapply(results, function(r) identical(r$outcome, "error"), logical(1))), snapshot_file))
} else {
  old <- lapply(readRDS(snapshot_file), function(record) {
    if (!is.null(record$theme)) record$theme <- theme_record(record$theme)
    record
  })
  lines <- sprintf("Guard: %d records saved, %d now", length(old), length(results))
  errors_changed <- character()
  missing_now <- setdiff(names(old), names(results))
  added <- setdiff(names(results), names(old))
  if (length(missing_now)) lines <- c(lines, paste("Missing now:", paste(missing_now, collapse = ", ")))
  if (length(added)) lines <- c(lines, paste("New:", paste(added, collapse = ", ")))
  identical_count <- 0L
  expected_count <- 0L
  for (label in intersect(names(old), names(results))) {
    a <- old[[label]]
    b <- results[[label]]
    if (identical(a, b)) {
      identical_count <- identical_count + 1L
      next
    }
    # Errors that stay errors, with a different class or message: the wrappers' classed
    # errors where the reference fails without a message of its own.
    if (identical(a$outcome, "error") && identical(b$outcome, "error")) {
      errors_changed <- c(errors_changed, sprintf("%s: %s (%s) -> %s (%s)", label, a$class[1], a$message,
                                                  b$class[1], b$message))
      next
    }
    differing <- union(names(a), names(b))[!mapply(identical, a[union(names(a), names(b))], b[union(names(a), names(b))])]
    if (identical(differing, "data_class") && (startsWith(label, "bar:") || startsWith(label, "fixture:bar_plot"))) {
      expected_count <- expected_count + 1L
      next
    }
    detail <- if ("layers" %in% differing) {
      layer_diff <- vapply(seq_len(max(length(a$layers), length(b$layers))), function(k) {
        la <- a$layers[[k]]
        lb <- b$layers[[k]]
        parts <- union(names(la), names(lb))
        paste(parts[!mapply(identical, la[parts], lb[parts])], collapse = "+")
      }, "")
      paste0(" (layers: ", paste(sprintf("%d:%s", seq_along(layer_diff), layer_diff)[nzchar(layer_diff)], collapse = ", "), ")")
    } else ""
    lines <- c(lines, sprintf("DIFFERS %s: %s%s", label, paste(differing, collapse = ", "), detail))
  }
  if (length(errors_changed)) lines <- c(lines, "Errors that stay errors, with another class or message:",
                                         paste0("  ", errors_changed))
  lines <- c(lines, sprintf("Identical: %d of %d; only the expected data class of bar_plot(): %d; errors with another class or message: %d",
                            identical_count, length(intersect(names(old), names(results))), expected_count,
                            length(errors_changed)))
  writeLines(lines, args[3])
  cat(tail(lines, 1), "\n")
}
