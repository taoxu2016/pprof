# Comparison of processed values (helper-reference-cases.R) with reference fixtures.
#
# reference_compare() walks both objects and returns one row per difference:
#   - structure (class, names, dimensions, attributes) must match exactly;
#   - doubles match when |a - b| <= atol + rtol * |b| elementwise, with NA, NaN, and
#     infinite values in the same positions;
#   - every other type matches exactly;
#   - signatures of long vectors (reference_signature()) match when their counts and
#     checksums of non-double data are identical and their double summaries are within
#     the tolerance implied by the elementwise rule.
# Flag columns in provider-test tables follow the boundary rule (brief §3.4): a flag may
# differ only for a provider whose p-value lies within the probability tolerance of the
# decision threshold; such rows are returned with kind "flag_boundary" and are reported,
# not treated as failures. In every family the reported p-value of a two-sided test is
# 2 * min(p, 1 - p), where p is the upper tail probability that the flag compares with
# alpha/2 and 1 - alpha/2, and that of a one-sided test is the tail the flag compares with
# alpha, so every threshold corresponds to alpha = 1 - level on the reported p-value.

reference_mismatch <- function(path, kind, detail) {
  data.frame(path = if (nzchar(path)) path else "<root>", kind = kind, detail = detail, stringsAsFactors = FALSE)
}

reference_numeric_within <- function(a, b, tol) {
  all(abs(a - b) <= tol$atol + tol$rtol * abs(b))
}

reference_compare_double <- function(a, b, tol, path) {
  if (!identical(is.na(a), is.na(b)) || !identical(is.nan(a), is.nan(b))) {
    return(reference_mismatch(path, "missing", "NA or NaN positions differ"))
  }
  inf_a <- is.infinite(a)
  if (!identical(inf_a, is.infinite(b)) || !identical(a[inf_a], b[inf_a])) {
    return(reference_mismatch(path, "infinite", "infinite values differ"))
  }
  fin <- is.finite(a)
  if (!any(fin)) return(NULL)
  diff <- abs(a[fin] - b[fin])
  bound <- tol$atol + tol$rtol * abs(b[fin])
  bad <- diff > bound
  if (!any(bad)) return(NULL)
  worst <- which.max(diff - bound)
  reference_mismatch(path, "numeric", sprintf("%d of %d values outside tolerance (atol %g, rtol %g); worst: actual %.17g, reference %.17g",
                                              sum(bad), length(diff), tol$atol, tol$rtol, a[fin][worst], b[fin][worst]))
}

reference_compare_signature <- function(a, b, tol, path) {
  exact_fields <- setdiff(names(b), c("sum", "abs_sum", "min", "max", "sample", "bits_md5", "dimnames", "names", "attributes"))
  out <- NULL
  for (f in exact_fields) {
    if (!identical(a[[f]], b[[f]])) out <- rbind(out, reference_mismatch(paste0(path, "#", f), "signature", "differs"))
  }
  for (f in intersect(c("dimnames", "names", "attributes"), names(b))) {
    out <- rbind(out, reference_compare(a[[f]], b[[f]], tol, paste0(path, "#", f)))
  }
  if (identical(b$type, "double")) {
    n <- b$length
    if (!isTRUE(abs(a$sum - b$sum) <= n * tol$atol + tol$rtol * b$abs_sum)) {
      out <- rbind(out, reference_mismatch(paste0(path, "#sum"), "signature",
                                           sprintf("sum %.17g versus %.17g", a$sum, b$sum)))
    }
    for (f in c("abs_sum", "min", "max")) {
      scale <- if (f == "abs_sum") n else 1
      if (!isTRUE(abs(a[[f]] - b[[f]]) <= scale * tol$atol + tol$rtol * abs(b[[f]]))) {
        out <- rbind(out, reference_mismatch(paste0(path, "#", f), "signature", sprintf("%.17g versus %.17g", a[[f]], b[[f]])))
      }
    }
    out <- rbind(out, reference_compare_double(a$sample, b$sample, tol, paste0(path, "#sample")))
  } else if (!identical(a$sample, b$sample)) {
    out <- rbind(out, reference_mismatch(paste0(path, "#sample"), "signature", "sample differs"))
  }
  out
}

reference_compare_attributes <- function(a, b, tol, path, skip = c("names", "row.names", "class")) {
  aa <- attributes(a)
  ba <- attributes(b)
  keys <- setdiff(union(names(aa), names(ba)), skip)
  out <- NULL
  for (k in keys) {
    if (is.null(aa[[k]]) || is.null(ba[[k]])) {
      out <- rbind(out, reference_mismatch(paste0(path, "@", k), "attribute", "present on one side only"))
    } else {
      out <- rbind(out, reference_compare(aa[[k]], ba[[k]], tol, paste0(path, "@", k)))
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
    out <- rbind(out, reference_mismatch(paste0(path, "$flag"), "flag",
                                         sprintf("flags differ for providers %s", paste(rownames(b)[differ][!near], collapse = ", "))))
  }
  out
}

reference_compare <- function(a, b, tol, path = "", alpha = NULL) {
  if (identical(a, b)) return(NULL)
  if (!identical(class(a), class(b))) {
    return(reference_mismatch(path, "class", sprintf("%s versus %s", paste(class(a), collapse = "/"), paste(class(b), collapse = "/"))))
  }
  if (inherits(b, "pprof_reference_signature")) return(reference_compare_signature(a, b, tol, path))
  out <- reference_compare_attributes(a, b, tol, path)
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
      } else {
        out <- rbind(out, reference_compare(a[[col]], b[[col]], tol, paste0(path, "$", col), alpha))
      }
    }
    return(out)
  }
  if (is.list(b)) {
    if (length(a) != length(b)) return(rbind(out, reference_mismatch(path, "length", sprintf("%d versus %d", length(a), length(b)))))
    for (k in seq_along(b)) {
      label <- if (!is.null(names(b)) && nzchar(names(b)[k])) names(b)[k] else sprintf("[[%d]]", k)
      out <- rbind(out, reference_compare(a[[k]], b[[k]], tol, paste0(path, if (nzchar(path)) "$" else "", label), alpha))
    }
    return(out)
  }
  if (!identical(typeof(a), typeof(b)) || length(a) != length(b)) {
    return(rbind(out, reference_mismatch(path, "type", sprintf("%s[%d] versus %s[%d]", typeof(a), length(a), typeof(b), length(b)))))
  }
  if (is.double(b)) {
    va <- as.vector(a)
    vb <- as.vector(b)
    return(rbind(out, reference_compare_double(va, vb, tol, path)))
  }
  if (!identical(as.vector(unclass(a)), as.vector(unclass(b)))) {
    out <- rbind(out, reference_mismatch(path, "value", sprintf("%d of %d values differ", sum(as.vector(unclass(a)) != as.vector(unclass(b)), na.rm = TRUE),
                                                                length(b))))
  }
  out
}
