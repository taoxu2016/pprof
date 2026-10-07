# Comparison of processed values (helper-reference-cases.R) with reference fixtures.
#
# reference_compare() walks both objects and returns one row per difference:
#   - structure (class, names, dimensions, attributes) must match exactly;
#   - doubles match when |a - b| <= atol + rtol * |b| elementwise, with NA, NaN, and
#     infinite values in the same positions;
#   - every other type matches exactly;
#   - signatures of long vectors (reference_signature()) match when their counts and
#     checksums of non-double data are identical and their double summaries are within
#     the tolerance implied by the elementwise rule; at the exact tier (atol and rtol 0),
#     the checksums of the bits of every double must also be identical, since summaries
#     can absorb a change in one element. Vectors whose bit checksums are identical match
#     without comparing their summaries.
# Flag columns in provider-test tables follow the boundary rule (brief §3.4): a flag may
# differ only for a provider whose p-value lies within the probability tolerance of the
# decision threshold; such rows are returned with kind "flag_boundary" and are reported,
# not treated as failures. In every family the reported p-value of a two-sided test is
# 2 * min(p, 1 - p), where p is the upper tail probability that the flag compares with
# alpha/2 and 1 - alpha/2, and that of a one-sided test is the tail the flag compares with
# alpha, so every threshold corresponds to alpha = 1 - level on the reported p-value.
# With `exact_statistic = TRUE` (the exact Poisson-binomial tests, DEC-083), the `stat` column
# of a data frame is compared by reference_compare_exact_statistic().
# With `numeric = FALSE` (on a platform other than the fixtures', DEC-080), finite doubles,
# the double summaries of signatures, and numbers the reference kept as text are not compared;
# everything else is, as above: classes, names, dimensions, attributes, row names, the
# positions of NA, NaN, and infinite values, every other value, and flags.

reference_mismatch <- function(path, kind, detail) {
  data.frame(path = if (nzchar(path)) path else "<root>", kind = kind, detail = detail, stringsAsFactors = FALSE)
}

reference_numeric_within <- function(a, b, tol) {
  all(abs(a - b) <= tol$atol + tol$rtol * abs(b))
}

reference_compare_double <- function(a, b, tol, path, numeric = TRUE) {
  if (!identical(is.na(a), is.na(b)) || !identical(is.nan(a), is.nan(b))) {
    return(reference_mismatch(path, "missing", "NA or NaN positions differ"))
  }
  inf_a <- is.infinite(a)
  if (!identical(inf_a, is.infinite(b)) || !identical(a[inf_a], b[inf_a])) {
    return(reference_mismatch(path, "infinite", "infinite values differ"))
  }
  fin <- is.finite(a)
  if (!numeric || !any(fin)) return(NULL)
  diff <- abs(a[fin] - b[fin])
  bound <- tol$atol + tol$rtol * abs(b[fin])
  bad <- diff > bound
  if (!any(bad)) return(NULL)
  worst <- which.max(diff - bound)
  detail <- sprintf("%d of %d values outside tolerance (atol %g, rtol %g); worst: actual %.17g, reference %.17g",
                    sum(bad), length(diff), tol$atol, tol$rtol, a[fin][worst], b[fin][worst])
  reference_mismatch(path, "numeric", detail)
}

# Whether a case is an exact Poisson-binomial test (test()'s default for logistic FE and Firth
# fits), whose statistic is compared on its tail probability (pprof_exact_statistic, DEC-083);
# `fit_fun` is the function of the case that made the fit.
reference_exact_statistic_case <- function(case, fit_fun) {
  identical(case$fun, "test") && isTRUE(fit_fun %in% c("logis_fe", "logis_firth")) &&
    (is.null(case$args$test) || identical(case$args$test, "exact.poisbinom"))
}

# The statistic of an exact test (pprof_exact_statistic, DEC-083): each value within the
# tolerance, or of the reference's sign with its tail probability pnorm(-|z|) within the
# tolerance of the reference's.
reference_compare_exact_statistic <- function(a, b, tol, path, numeric = TRUE) {
  out <- reference_compare_double(a, b, tol, path, numeric = FALSE)
  if (!is.null(out) || !numeric) return(out)
  fin <- is.finite(b)
  za <- a[fin]
  zb <- b[fin]
  direct <- abs(za - zb) <= tol$atol + tol$rtol * abs(zb)
  qa <- stats::pnorm(-abs(za))
  qb <- stats::pnorm(-abs(zb))
  tail <- sign(za) == sign(zb) & abs(qa - qb) <= tol$atol + tol$rtol * qb
  bad <- !(direct | tail)
  if (!any(bad)) return(NULL)
  worst <- which(bad)[which.max(abs(qa - qb)[bad])]
  detail <- sprintf(paste("%d of %d exact statistics outside tolerance (atol %g, rtol %g), also on the tail",
                          "probability; worst: actual %.17g, reference %.17g"),
                    sum(bad), length(zb), tol$atol, tol$rtol, za[worst], zb[worst])
  reference_mismatch(path, "numeric", detail)
}

# Text holding numbers that the reference formatted (the p-values of the old summaries, and the
# columns of the data of RE fits with character provider IDs, D-11): every value parses as a
# number and some have a decimal point or an exponent, which provider IDs and labels do not.
reference_formatted_numbers <- function(x) {
  values <- x[!is.na(x)]
  if (!is.character(values) || length(values) == 0L) return(FALSE)
  numbers <- suppressWarnings(as.numeric(sub("^[<>]\\s*", "", values)))
  !anyNA(numbers) && any(grepl("[.eE]", values))
}

reference_compare_signature <- function(a, b, tol, path, numeric = TRUE) {
  special_fields <- c("sum", "abs_sum", "min", "max", "sample", "bits_md5", "dimnames", "names", "attributes")
  # Off the fixtures' platform, formatted numbers are numbers: their checksum and sample are not compared.
  formatted <- !numeric && identical(b$type, "character") && reference_formatted_numbers(b$sample)
  exact_fields <- setdiff(names(b), c(special_fields, if (formatted) "md5"))
  out <- NULL
  for (f in exact_fields) {
    if (!identical(a[[f]], b[[f]])) out <- rbind(out, reference_mismatch(paste0(path, "#", f), "signature", "differs"))
  }
  for (f in intersect(c("dimnames", "names", "attributes"), names(b))) {
    out <- rbind(out, reference_compare(a[[f]], b[[f]], tol, paste0(path, "#", f), numeric = numeric))
  }
  if (identical(b$type, "double") && !numeric) return(out)
  if (identical(b$type, "double")) {
    n <- b$length
    # Identical bits mean identical values, whose summaries then agree by definition. The
    # summaries are not compared, because sum() accumulates in long double, which has extra
    # precision on x86_64 (where the fixtures were made) but not on arm64 macOS, so the same
    # values can sum differently in the last digits there.
    if (!is.null(b$bits_md5) && identical(a$bits_md5, b$bits_md5)) return(out)
    if (tol$atol == 0 && tol$rtol == 0 && !identical(a$bits_md5, b$bits_md5)) {
      out <- rbind(out, reference_mismatch(paste0(path, "#bits_md5"), "signature", "values are not bitwise identical"))
    }
    if (!isTRUE(abs(a$sum - b$sum) <= n * tol$atol + tol$rtol * b$abs_sum)) {
      out <- rbind(out, reference_mismatch(paste0(path, "#sum"), "signature",
                                           sprintf("sum %.17g versus %.17g", a$sum, b$sum)))
    }
    for (f in c("abs_sum", "min", "max")) {
      scale <- if (f == "abs_sum") n else 1
      if (!isTRUE(abs(a[[f]] - b[[f]]) <= scale * tol$atol + tol$rtol * abs(b[[f]]))) {
        detail <- sprintf("%.17g versus %.17g", a[[f]], b[[f]])
        out <- rbind(out, reference_mismatch(paste0(path, "#", f), "signature", detail))
      }
    }
    out <- rbind(out, reference_compare_double(a$sample, b$sample, tol, paste0(path, "#sample")))
  } else if (!formatted && !identical(a$sample, b$sample)) {
    out <- rbind(out, reference_mismatch(paste0(path, "#sample"), "signature", "sample differs"))
  }
  out
}

reference_compare_attributes <- function(a, b, tol, path, skip = c("names", "row.names", "class"),
                                         numeric = TRUE) {
  aa <- attributes(a)
  ba <- attributes(b)
  keys <- setdiff(union(names(aa), names(ba)), skip)
  out <- NULL
  for (k in keys) {
    if (is.null(aa[[k]]) || is.null(ba[[k]])) {
      out <- rbind(out, reference_mismatch(paste0(path, "@", k), "attribute", "present on one side only"))
    } else {
      out <- rbind(out, reference_compare(aa[[k]], ba[[k]], tol, paste0(path, "@", k), numeric = numeric))
    }
  }
  out
}

# Flags of a provider-test table may differ only at the decision threshold.
reference_compare_flags <- function(a, b, tol, path, alpha) {
  fa <- as.character(a$flag)
  fb <- as.character(b$flag)
  differ <- which(fa != fb)
  if (!length(differ)) return(NULL)
  prob_tol <- reference_tolerance("probability")
  p <- b[["p value"]][differ]
  near <- abs(p - alpha) <= prob_tol$atol + prob_tol$rtol * alpha
  out <- NULL
  if (any(near)) {
    out <- rbind(out, reference_mismatch(paste0(path, "$flag"), "flag_boundary",
                                         sprintf("providers %s: p-value within tolerance of alpha = %.17g",
                                                 paste(rownames(b)[differ][near], collapse = ", "), alpha)))
  }
  if (any(!near)) {
    detail <- sprintf("flags differ for providers %s", paste(rownames(b)[differ][!near], collapse = ", "))
    out <- rbind(out, reference_mismatch(paste0(path, "$flag"), "flag", detail))
  }
  out
}

reference_compare <- function(a, b, tol, path = "", alpha = NULL, numeric = TRUE, exact_statistic = FALSE) {
  if (identical(a, b)) return(NULL)
  if (!identical(class(a), class(b))) {
    detail <- sprintf("%s versus %s", paste(class(a), collapse = "/"), paste(class(b), collapse = "/"))
    return(reference_mismatch(path, "class", detail))
  }
  if (inherits(b, "pprof_reference_signature")) return(reference_compare_signature(a, b, tol, path, numeric))
  out <- reference_compare_attributes(a, b, tol, path, numeric = numeric)
  if (!identical(names(a), names(b))) {
    return(rbind(out, reference_mismatch(path, "names", "names differ")))
  }
  if (is.data.frame(b)) {
    if (!identical(attr(a, "row.names"), attr(b, "row.names"))) {
      out <- rbind(out, reference_mismatch(path, "row.names", "row names differ"))
    }
    flag_table <- !is.null(alpha) && all(c("flag", "p value") %in% names(b)) && nrow(a) == nrow(b)
    for (col in names(b)) {
      if (flag_table && col == "flag") {
        if (!identical(levels(a$flag), levels(b$flag))) {
          out <- rbind(out, reference_mismatch(paste0(path, "$flag"), "levels", "flag levels differ"))
        }
        out <- rbind(out, reference_compare_flags(a, b, tol, path, alpha))
      } else if (exact_statistic && col == "stat" && is.double(a[[col]]) && is.double(b[[col]]) &&
                   length(a[[col]]) == length(b[[col]]) && identical(attributes(a[[col]]), attributes(b[[col]]))) {
        out <- rbind(out, reference_compare_exact_statistic(a[[col]], b[[col]], tol, paste0(path, "$", col), numeric))
      } else {
        out <- rbind(out, reference_compare(a[[col]], b[[col]], tol, paste0(path, "$", col), alpha, numeric,
                                            exact_statistic))
      }
    }
    return(out)
  }
  if (is.list(b)) {
    if (length(a) != length(b)) {
      return(rbind(out, reference_mismatch(path, "length", sprintf("%d versus %d", length(a), length(b)))))
    }
    for (k in seq_along(b)) {
      label <- if (!is.null(names(b)) && nzchar(names(b)[k])) names(b)[k] else sprintf("[[%d]]", k)
      child <- paste0(path, if (nzchar(path)) "$" else "", label)
      out <- rbind(out, reference_compare(a[[k]], b[[k]], tol, child, alpha, numeric, exact_statistic))
    }
    return(out)
  }
  if (!identical(typeof(a), typeof(b)) || length(a) != length(b)) {
    detail <- sprintf("%s[%d] versus %s[%d]", typeof(a), length(a), typeof(b), length(b))
    return(rbind(out, reference_mismatch(path, "type", detail)))
  }
  if (is.double(b)) {
    va <- as.vector(a)
    vb <- as.vector(b)
    return(rbind(out, reference_compare_double(va, vb, tol, path, numeric)))
  }
  if (!numeric && reference_formatted_numbers(b)) {
    if (!identical(is.na(a), is.na(b))) out <- rbind(out, reference_mismatch(path, "missing", "NA positions differ"))
    return(out)
  }
  if (!identical(as.vector(unclass(a)), as.vector(unclass(b)))) {
    differing <- sum(as.vector(unclass(a)) != as.vector(unclass(b)), na.rm = TRUE)
    out <- rbind(out, reference_mismatch(path, "value", sprintf("%d of %d values differ", differing, length(b))))
  }
  out
}
