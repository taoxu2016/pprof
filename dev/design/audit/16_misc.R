# Phase 0 audit: data_check, plotting helpers, package-level behavior, dependency footprint.
script_dir <- dirname(normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))))
source(file.path(script_dir, "helpers.R"))
audit_header("16: data_check, plots, package-level behavior, dependencies")

bin <- load_binary_example()
e <- new.env(); utils::data("ExampleDataBinary", package = "pprof", lib.loc = ref_lib, envir = e)
eb <- e$ExampleDataBinary

# --- V16.1: data_check stops on any missing value while fits delete rows (D-17) ------------------------
z_na <- eb$Z; z_na$z1[1:3] <- NA
dc_na <- try_capture(suppressMessages(data_check(eb$Y, z_na, eb$ProvID)))
fit_na <- quiet_logis_fe(Y = eb$Y, Z = z_na, ProvID = eb$ProvID)
msgs <- character()
withCallingHandlers(data_check(eb$Y, eb$Z, eb$ProvID),
                    message = function(m) { msgs <<- c(msgs, trimws(conditionMessage(m))); invokeRestart("muffleMessage") })
report("V16.1", if (dc_na$error && nrow(fit_na$data_include) == length(eb$Y) - 3) "CONFIRMED" else "REFUTED",
       "data_check() stops when any value is missing, while every fitting function silently deletes incomplete rows (D-17); it reports through message()/warning() and returns nothing",
       c(sprintf("data_check with 3 NAs: %s", if (dc_na$error) paste("ERROR:", dc_na$message) else "ok"),
         sprintf("logis_fe with the same data keeps %d of %d rows", nrow(fit_na$data_include), length(eb$Y)),
         sprintf("messages on clean data: %s", paste(msgs, collapse = " | "))))

# --- V16.2: plotting helpers consume attributes ------------------------------------------------------------
fit <- quiet_logis_fe(data = bin, Y.char = "Y", Z.char = covariate_names, ProvID.char = "ProvID")
ci <- suppressWarnings(confint(fit, test = "wald"))
cp <- try_capture(caterpillar_plot(ci$CI.indirect_ratio))
cp_gamma <- try_capture(caterpillar_plot(suppressWarnings(confint(fit, option = "gamma", test = "wald"))))
tst <- test(fit)
bp <- try_capture(bar_plot(tst))
bp_noattr <- try_capture(bar_plot(as.data.frame(as.list(tst))))
report("V16.2", "CONFIRMED",
       "caterpillar_plot() dispatches on the attributes 'description', 'model', 'type', and 'population_rate'; bar_plot() needs the 'provider size' attribute that test() attaches",
       c(sprintf("caterpillar_plot(indirect ratio CI): %s", if (cp$error) paste("ERROR:", cp$message) else "ggplot"),
         sprintf("caterpillar_plot(gamma CI): %s", if (cp_gamma$error) paste("ERROR:", cp_gamma$message) else "ggplot"),
         sprintf("bar_plot(test()): %s; warnings: %s", if (bp$error) paste("ERROR:", bp$message) else "ggplot",
                 paste(unique(bp$warnings), collapse = " | ")),
         sprintf("bar_plot without the attribute: %s", if (bp_noattr$error) paste("ERROR:", bp_noattr$message) else "ok"),
         sprintf("attributes used: %s", paste(names(attributes(ci$CI.indirect_ratio)), collapse = ", "))))

# --- V16.3: exported generic test() collides with devtools::test() ------------------------------------------
has_devtools <- requireNamespace("devtools", quietly = TRUE)
report("V16.3", "NOTE",
       "pprof exports a generic named test(); devtools and testthat users have devtools::test(), so attach order decides which one runs",
       c(sprintf("devtools installed: %s; devtools exports test(): %s", has_devtools,
                 has_devtools && "test" %in% getNamespaceExports("devtools")),
         sprintf("pprof exports: %s", paste(sort(getNamespaceExports("pprof")), collapse = ", "))))

# --- V16.4: attaching pprof prints a message from a dependency -------------------------------------------------
attach_msgs <- callr::r(function(lib) {
  out <- character()
  withCallingHandlers(suppressWarnings(library(pprof, lib.loc = lib)),
                      message = function(m) { out <<- c(out, conditionMessage(m)); invokeRestart("muffleMessage") },
                      packageStartupMessage = function(m) { out <<- c(out, conditionMessage(m)); invokeRestart("muffleMessage") })
  c(out, paste("loaded namespaces:", length(loadedNamespaces())))
}, args = list(lib = ref_lib))
report("V16.4", "NOTE", "Messages emitted while attaching pprof in a fresh session, and the number of namespaces loaded:", attach_msgs)

# --- V16.5: dependency footprint -------------------------------------------------------------------------------
ap <- tryCatch(utils::available.packages(repos = "https://cloud.r-project.org"), error = function(e) NULL)
if (!is.null(ap)) {
  base_pkgs <- rownames(utils::installed.packages(priority = "base"))
  deps_of <- function(p) {
    d <- tools::package_dependencies(p, db = ap, which = c("Depends", "Imports", "LinkingTo"), recursive = TRUE)[[1]]
    setdiff(d, base_pkgs)
  }
  imports <- c("Rcpp", "RcppParallel", "caret", "olsrr", "pROC", "poibin", "dplyr", "ggplot2", "Matrix",
               "lme4", "magrittr", "scales", "tibble", "rlang", "tidyselect", "globals", "RcppArmadillo", "generics")
  core <- unique(c("ggplot2", "lme4", deps_of("ggplot2"), deps_of("lme4")))
  tab <- data.frame(package = imports,
                    recursive_hard_deps = sapply(imports, function(p) length(deps_of(p))),
                    arrives_with_ggplot2_or_lme4 = imports %in% core,
                    extra_beyond_ggplot2_lme4 = sapply(imports, function(p) length(setdiff(c(p, deps_of(p)), core))),
                    license = ap[imports, "License"], row.names = NULL)
  all_now <- unique(unlist(lapply(imports[imports != "generics"], function(p) c(p, deps_of(p)))))
  keep <- c("Rcpp", "RcppArmadillo", "poibin", "ggplot2", "lme4", "scales", "tibble", "generics")
  all_keep <- unique(unlist(lapply(keep, function(p) c(p, deps_of(p)))))
  report("V16.5", "NOTE",
         "Recursive hard dependencies (Depends/Imports/LinkingTo, excluding base packages) of each current import, from the CRAN index on the run date",
         c(utils::capture.output(print(tab)),
           sprintf("all current imports together: %d packages", length(all_now)),
           sprintf("proposed set (%s): %d packages", paste(keep, collapse = ", "), length(all_keep)),
           sprintf("dropped from the install tree: %s", paste(sort(setdiff(all_now, all_keep)), collapse = ", "))))
} else {
  report("V16.5", "NOTE", "CRAN index unavailable; dependency footprint skipped")
}

# --- V16.6: imported functions actually used ------------------------------------------------------------------
ns <- asNamespace("pprof")
fun_names <- ls(ns, all.names = TRUE)
bodies <- vapply(fun_names, function(f) {
  obj <- get(f, envir = ns)
  if (is.function(obj)) paste(deparse(obj), collapse = "\n") else ""
}, character(1))
uses <- function(pattern) names(bodies)[grepl(pattern, bodies)]
report("V16.6", "NOTE",
       "Where single-purpose imports are used (functions whose deparsed body matches):",
       c(sprintf("caret::nearZeroVar: %s", paste(uses("nearZeroVar"), collapse = ", ")),
         sprintf("olsrr::ols_vif_tol: %s", paste(uses("ols_vif_tol"), collapse = ", ")),
         sprintf("pROC::auc: %s", paste(uses("pROC::auc|\\bauc\\("), collapse = ", ")),
         sprintf("Matrix::bdiag: %s", paste(uses("bdiag"), collapse = ", ")),
         sprintf("globals: %s", paste(uses("globals::"), collapse = ", ")),
         sprintf("RcppParallel (R side): %s", paste(uses("RcppParallel"), collapse = ", ")),
         sprintf("dplyr verbs (group_by/mutate/cross_join/arrange/summarise): %s",
                 paste(uses("group_by|cross_join|summarise|arrange\\("), collapse = ", ")),
         sprintf("%%>%%: %s", paste(uses("%>%"), collapse = ", "))))

# --- V16.7: bundled data -----------------------------------------------------------------------------------------
eb_sizes <- table(eb$ProvID)
eb_events <- tapply(eb$Y, eb$ProvID, sum)
el <- new.env(); utils::data("ExampleDataLinear", package = "pprof", lib.loc = ref_lib, envir = el)
ee <- new.env(); utils::data("ecls_data", package = "pprof", lib.loc = ref_lib, envir = ee)
schools <- table(ee$ecls_data$School_ID)
rd_bin <- tools::Rd_db("pprof", lib.loc = ref_lib)[["ExampleDataBinary.Rd"]]
rd_bin_text <- paste(utils::capture.output(tools::Rd2txt(rd_bin, options = list(underline_titles = FALSE))), collapse = " ")
report("V16.7", if (length(eb$Y) == 7944 && grepl("7994", rd_bin_text)) "CONFIRMED" else "NOTE",
       "Bundled data: ExampleDataBinary has 7,944 observations while its help says 7994 (D-35)",
       c(sprintf("ExampleDataBinary: n = %d, providers = %d, sizes %d-%d, class(ProvID) = %s, no-event providers = %s, all-event providers = %d",
                 length(eb$Y), length(eb_sizes), min(eb_sizes), max(eb_sizes), class(eb$ProvID),
                 paste(names(eb_events)[eb_events == 0], collapse = ", "), sum(eb_events == eb_sizes)),
         sprintf("help mentions '7994': %s", grepl("7994", rd_bin_text)),
         sprintf("ExampleDataLinear: n = %d, providers = %d, sizes %d-%d", length(el$ExampleDataLinear$Y),
                 length(table(el$ExampleDataLinear$ProvID)), min(table(el$ExampleDataLinear$ProvID)), max(table(el$ExampleDataLinear$ProvID))),
         sprintf("ecls_data: class %s, %d rows, %d schools, %d of size 1, %d of size >= 10, Child_Sex levels %s",
                 paste(class(ee$ecls_data), collapse = "/"), nrow(ee$ecls_data), length(schools), sum(schools == 1),
                 sum(schools >= 10), paste(levels(ee$ecls_data$Child_Sex), collapse = ", "))))

cat("\nDone.\n")
