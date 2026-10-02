# Shared runner for reference cases.
#
# This file is used in two places, so that a case is executed and processed the same way
# in both:
#   - dev/reference/generate_fixtures.R sources it in child R sessions that load the
#     reference implementation (pprof 1.0.3 from the isolated library) to create fixtures;
#   - the characterization tests (test-reference-*.R) use it to run the same cases against
#     the package under test.
# It depends only on base R, plus lme4 and ggplot2 for extracting components of objects
# that those packages create.

# --- Argument markers ---------------------------------------------------------------------
# Cases store their arguments as plain values or as these markers, resolved at run time.

ref_dataset <- function(name) structure(list(name = name), class = "pprof_ref_dataset")
ref_element <- function(name, element) structure(list(name = name, element = element), class = "pprof_ref_element")
ref_formula <- function(text) structure(list(text = text), class = "pprof_ref_formula")
ref_fit <- function(case_id) structure(list(case_id = case_id), class = "pprof_ref_fit")
ref_value <- function(case_id, element) structure(list(case_id = case_id, element = element), class = "pprof_ref_value")
# An R expression evaluated when the case runs, for arguments such as lme4 control objects
# whose structure depends on the installed lme4 version.
ref_expr <- function(text) structure(list(text = text), class = "pprof_ref_expr")

reference_resolve_arg <- function(arg, datasets, results) {
  if (inherits(arg, "pprof_ref_dataset")) return(datasets[[arg$name]])
  if (inherits(arg, "pprof_ref_element")) return(datasets[[arg$name]][[arg$element]])
  if (inherits(arg, "pprof_ref_formula")) return(stats::as.formula(arg$text, env = globalenv()))
  if (inherits(arg, "pprof_ref_expr")) return(eval(str2lang(arg$text), envir = baseenv()))
  if (inherits(arg, "pprof_ref_fit") || inherits(arg, "pprof_ref_value")) {
    parent <- results[[arg$case_id]]
    if (is.null(parent) || !identical(parent$outcome, "value")) {
      stop(sprintf("Parent case '%s' is missing or did not return a value.", arg$case_id), call. = FALSE)
    }
    if (inherits(arg, "pprof_ref_fit")) return(parent$raw_value)
    return(parent$raw_value[[arg$element]])
  }
  arg
}

reference_resolve_args <- function(args, datasets, results) {
  lapply(args, reference_resolve_arg, datasets = datasets, results = results)
}

reference_function <- function(fun) {
  switch(fun,
         confint = stats::confint,
         summary = base::summary,
         plot = base::plot,
         getExportedValue("pprof", fun))
}

reference_parse_iterations <- function(output) {
  hit <- grep("converged after [0-9]+ iterations", output, value = TRUE)
  if (length(hit) == 0) return(NA_integer_)
  as.integer(sub(".*converged after ([0-9]+) iterations.*", "\\1", hit[length(hit)]))
}

# --- Running one case ---------------------------------------------------------------------

# Evaluate one call, capturing printed output, messages, warnings, and errors.
reference_evaluate <- function(fun, args, seed = NULL, allowed_warnings = character()) {
  messages <- character()
  warnings <- character()
  if (!is.null(seed)) {
    had_seed <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
    if (had_seed) old_seed <- get(".Random.seed", envir = globalenv())
    on.exit(if (had_seed) assign(".Random.seed", old_seed, envir = globalenv())
            else rm(".Random.seed", envir = globalenv()), add = TRUE)
    set.seed(seed, kind = "Mersenne-Twister", normal.kind = "Inversion", sample.kind = "Rejection")
  }
  value <- NULL
  error <- NULL
  output <- utils::capture.output(
    value <- withCallingHandlers(
      tryCatch(do.call(reference_function(fun), args), error = function(e) {
        error <<- list(class = class(e), message = conditionMessage(e))
        NULL
      }),
      message = function(m) {
        messages <<- c(messages, conditionMessage(m))
        invokeRestart("muffleMessage")
      },
      warning = function(w) {
        msg <- conditionMessage(w)
        if (!any(vapply(allowed_warnings, grepl, logical(1), x = msg, fixed = TRUE))) {
          warnings <<- c(warnings, msg)
        }
        invokeRestart("muffleWarning")
      }
    )
  )
  list(outcome = if (is.null(error)) "value" else "error", raw_value = value, error = error,
       warnings = warnings, messages = messages, output = output)
}

# Run a case. `results` holds earlier results, so that methods can use their parent fit.
# For logistic FE and Firth fits whose call does not print the iteration log, a probe with
# message = TRUE recovers the iteration count; the probe must reproduce the estimates exactly.
run_reference_case <- function(case, datasets, results, allowed_warnings = character()) {
  args <- reference_resolve_args(case$args, datasets, results)
  res <- reference_evaluate(case$fun, args, seed = case$seed, allowed_warnings = allowed_warnings)
  res$iterations <- reference_parse_iterations(res$output)
  res$probe_identical <- NA
  if (case$fun %in% c("logis_fe", "logis_firth") && identical(res$outcome, "value") && is.na(res$iterations)) {
    probe_args <- args
    probe_args$message <- TRUE
    probe <- reference_evaluate(case$fun, probe_args, seed = case$seed, allowed_warnings = allowed_warnings)
    res$iterations <- reference_parse_iterations(probe$output)
    res$probe_identical <- identical(probe$raw_value$coefficient, res$raw_value$coefficient) &&
      identical(probe$raw_value$variance, res$raw_value$variance)
  }
  res
}

# --- Processing values for storage and comparison ------------------------------------------
# Both fixtures and the values under test go through reference_fixture_value(), so the two
# sides are always compared in the same form. Long vectors and large data frames become
# signatures (summaries plus an exact checksum); lme4 fits become their extracted
# components; ggplot objects become the data of their layers.

reference_md5 <- function(lines) {
  tmp <- tempfile()
  on.exit(unlink(tmp))
  con <- file(tmp, open = "wb")
  writeLines(enc2utf8(as.character(lines)), con, useBytes = TRUE)
  close(con)
  unname(tools::md5sum(tmp))
}

reference_signature <- function(x) {
  n <- length(x)
  idx <- unique(pmax(1L, round(seq(1, n, length.out = min(n, 25L)))))
  sig <- list(type = typeof(x), class = class(x), length = n, sample_index = idx)
  if (is.factor(x)) {
    sig$levels <- levels(x)
    sig$codes_md5 <- reference_md5(as.integer(x))
    sig$counts <- tabulate(as.integer(x), nbins = nlevels(x))
    sig$sample <- as.character(x[idx])
  } else if (is.double(x)) {
    finite <- is.finite(x)
    sig$n_na <- sum(is.na(x) & !is.nan(x))
    sig$n_nan <- sum(is.nan(x))
    sig$n_posinf <- sum(x == Inf, na.rm = TRUE)
    sig$n_neginf <- sum(x == -Inf, na.rm = TRUE)
    sig$sum <- sum(x[finite])
    sig$abs_sum <- sum(abs(x[finite]))
    sig$min <- if (any(finite)) min(x[finite]) else NA_real_
    sig$max <- if (any(finite)) max(x[finite]) else NA_real_
    sig$sample <- unname(x[idx])
    sig$bits_md5 <- reference_md5(sprintf("%a", x))
  } else {
    sig$md5 <- reference_md5(x)
    sig$sample <- unname(x[idx])
    sig$is_sequence <- is.character(x) && identical(unname(x), as.character(seq_len(n)))
  }
  structure(sig, class = "pprof_reference_signature")
}

reference_dimnames_value <- function(dn, max_full_length) {
  if (is.null(dn)) return(NULL)
  lapply(dn, function(d) if (!is.null(d) && length(d) > max_full_length) reference_signature(d) else d)
}

reference_merMod_components <- function(m, max_full_length) {
  re <- lme4::ranef(m, condVar = TRUE)
  re_list <- lapply(re, function(r) {
    post <- attr(r, "postVar")
    attr(r, "postVar") <- NULL
    list(values = reference_fixture_value(as.data.frame(r), max_full_length), post_var = post)
  })
  ll <- stats::logLik(m)
  components <- list(
    class = class(m)[1], formula = paste(deparse(stats::formula(m)), collapse = " "),
    fixef = lme4::fixef(m), ranef = re_list, varcorr = as.data.frame(lme4::VarCorr(m)),
    theta = lme4::getME(m, "theta"), sigma = stats::sigma(m),
    loglik = as.numeric(ll), loglik_df = attr(ll, "df"), aic = stats::AIC(m), bic = stats::BIC(m),
    vcov = as.matrix(stats::vcov(m)), nobs = stats::nobs(m), reml = lme4::isREML(m),
    fitted = reference_fixture_value(unname(stats::fitted(m)), max_full_length),
    convergence_messages = m@optinfo$conv$lme4$messages
  )
  structure(components, class = "pprof_reference_merMod")
}

reference_ggplot_components <- function(p, max_full_length) {
  # Layers are compared by position: ggplot2 4 names them automatically, and those names are
  # not part of the plot's content.
  layer_data <- unname(lapply(p$layers, function(layer) {
    d <- layer$data
    list(geom = class(layer$geom)[1],
         mapping = sort(names(layer$mapping)),
         data = if (is.data.frame(d)) reference_fixture_value(as.data.frame(d), max_full_length) else NULL)
  }))
  plot_data <- if (is.data.frame(p$data)) reference_fixture_value(as.data.frame(p$data), max_full_length) else NULL
  structure(list(data = plot_data, layers = layer_data), class = "pprof_reference_ggplot")
}

reference_fixture_value <- function(x, max_full_length = 5000L) {
  if (is.null(x)) return(NULL)
  if (inherits(x, "merMod")) return(reference_merMod_components(x, max_full_length))
  if (inherits(x, "ggplot")) return(reference_ggplot_components(x, max_full_length))
  if (is.data.frame(x)) {
    if (nrow(x) > max_full_length) {
      extra <- attributes(x)[setdiff(names(attributes(x)), c("names", "row.names", "class"))]
      return(structure(list(
        dim = dim(x), names = names(x), class = class(x),
        row_names = reference_signature(as.character(attr(x, "row.names"))),
        columns = lapply(x, function(col) if (length(col) > max_full_length) reference_signature(col) else col),
        attributes = lapply(extra, reference_fixture_value, max_full_length = max_full_length)
      ), class = "pprof_reference_large_df"))
    }
    out <- x
    for (a in setdiff(names(attributes(x)), c("names", "row.names", "class"))) {
      attr(out, a) <- reference_fixture_value(attr(x, a), max_full_length)
    }
    return(out)
  }
  if (is.list(x)) {
    out <- lapply(x, reference_fixture_value, max_full_length = max_full_length)
    for (a in setdiff(names(attributes(x)), "names")) {
      attr(out, a) <- reference_fixture_value(attr(x, a), max_full_length)
    }
    return(out)
  }
  if (is.atomic(x) && length(x) > max_full_length) {
    sig <- reference_signature(as.vector(x))
    sig$dim <- dim(x)
    sig$dimnames <- reference_dimnames_value(dimnames(x), max_full_length)
    sig$names <- if (!is.null(names(x))) reference_signature(names(x)) else NULL
    other <- setdiff(names(attributes(x)), c("dim", "dimnames", "names"))
    sig$attributes <- lapply(attributes(x)[other], reference_fixture_value, max_full_length = max_full_length)
    return(sig)
  }
  if (is.atomic(x) && !is.null(dimnames(x))) {
    dimnames(x) <- reference_dimnames_value(dimnames(x), max_full_length)
  }
  x
}

# The stored form of a run: the processed value plus everything needed to compare a rerun.
reference_result_record <- function(res, max_full_length = 5000L) {
  list(outcome = res$outcome,
       value = reference_fixture_value(res$raw_value, max_full_length),
       error = res$error, warnings = res$warnings, messages = res$messages, output = res$output,
       iterations = res$iterations, probe_identical = res$probe_identical)
}
