# Survival data in the data layer (COXPH_DESIGN §C.1; DEC-092; K-131, K-139).
#
# data_prepare(response_type = "survival") reads a Surv() response of type "right" or "counting":
# the status becomes the response, and each observation's entry and exit times become `start` (0
# for right-censored data) and `stop`. The provider is the strata of the Cox models, so the formula
# has none of survival's special terms. Case weights, clusters, and offset() terms come with it.
# None of this runs for the existing families, which pass none of the new arguments (§C.2).

#' @importFrom survival Surv
#' @export
survival::Surv

# survival's special terms of a coxph() formula, which a Cox formula of the package must not
# contain: the provider is the strata, and clusters and weights are arguments.
data_survival_specials <- c("strata", "cluster", "tt", "frailty", "ridge", "pspline")

# Whether `x` is a call to survival's Surv(), written Surv() or survival::Surv().
data_is_surv_call <- function(x) {
  is.call(x) && (identical(x[[1L]], as.name("Surv")) || identical(x[[1L]], quote(survival::Surv)))
}

# The terms of a Cox formula: a Surv() response and no special terms (data_parse_formula()).
data_check_survival_terms <- function(terms) {
  specials <- attr(terms, "specials")
  used <- names(specials)[!vapply(specials, is.null, logical(1))]
  if (length(used) > 0L) {
    abort_invalid_input(
      sprintf(paste("`formula` must not contain %s terms: the provider is the strata of the Cox model, and",
                    "clusters and weights are arguments."), paste0(used, "()", collapse = ", ")),
      arg = "formula"
    )
  }
  if (!data_is_surv_call(as.list(attr(terms, "variables"))[[2L]])) {
    abort_invalid_input("The response of a Cox model must be Surv(time, status) or Surv(start, stop, status).",
                        arg = "formula")
  }
  invisible(terms)
}

# The variables of the offset() terms of `terms`.
data_offset_variables <- function(terms) {
  variables <- as.list(attr(terms, "variables"))[-1L]
  unique(unlist(lapply(attr(terms, "offset"), function(i) all.vars(variables[[i]]))))
}

# Evaluates `expr` without the warnings that survival's Surv() gives when it turns an invalid
# status, or a start time not below its stop time, into NA (`dev/design/coxph-facts/19`): the data
# layer reports those rows itself (data_survival_frame_problems()). Other warnings pass.
data_without_surv_warnings <- function(expr) {
  withCallingHandlers(expr, warning = function(w) {
    if (data_is_surv_call(conditionCall(w))) invokeRestart("muffleWarning")
  })
}

# The rows of a model frame of complete rows whose Surv() response is missing, which only Surv()
# itself can have made so: an invalid status (Surv() accepts 0/1, logical, and 1/2 codings, and reads
# 0/1/2 as 1/2 coding with the 0s missing), or a time that is not a number or, for counting-process
# data, a start time not below its stop time.
data_survival_frame_problems <- function(frame) {
  response <- stats::model.response(frame)
  if (!inherits(response, "Surv")) return(list(status = integer(), times = integer()))
  values <- unclass(response)
  status <- is.na(values[, ncol(values)])
  times <- !status & rowSums(is.na(values[, -ncol(values), drop = FALSE])) > 0L
  list(status = which(status), times = which(times))
}

# data_prepare()'s check of the frame: invalid responses are errors, not rows to delete.
data_check_survival_frame <- function(frame) {
  problems <- data_survival_frame_problems(frame)
  counts <- lengths(problems)
  if (sum(counts) == 0L) return(invisible(frame))
  what <- c(status = "a status that is not 0/1, FALSE/TRUE, or 1/2",
            times = "a time that is not a number, or a start time not below its stop time")
  abort_invalid_input(
    sprintf("The Surv() response is invalid in %s.",
            paste(sprintf("%d row%s with %s", counts[counts > 0L], ifelse(counts[counts > 0L] == 1L, "", "s"),
                          what[counts > 0L]), collapse = " and ")),
    arg = "formula"
  )
}

# The parts of the Surv() response of a model frame: `start` (0 for right-censored data), `stop`,
# and `status` (0/1), and whether the data are counting-process data. Only the types the Cox models
# take: right-censored and counting-process data with a 0/1 status.
data_survival_response <- function(frame) {
  response <- stats::model.response(frame)
  if (!inherits(response, "Surv")) {
    abort_invalid_input("The response of a Cox model must be a Surv() object.", arg = "formula")
  }
  type <- attr(response, "type")
  if (!type %in% c("right", "counting")) {
    hint <- if (type %in% c("mright", "mcounting")) {
      " For one of several events, write it in Surv(), for example Surv(time, status == 1)."
    } else {
      ""
    }
    abort_invalid_input(
      sprintf(paste0("The response must be right-censored, Surv(time, status), or counting-process data, ",
                     "Surv(start, stop, status), with a 0/1 or logical status, not of type \"%s\".%s"), type, hint),
      arg = "formula"
    )
  }
  values <- unclass(response)
  counting <- identical(type, "counting")
  stop_time <- unname(values[, if (counting) "stop" else "time"])
  list(start = if (counting) unname(values[, "start"]) else rep(0, length(stop_time)), stop = stop_time,
       status = unname(values[, "status"]), counting = counting)
}

# pprof_py's rules for the times (COXPH_DESIGN §A.1, K-131): right-censored times finite and above
# 0; counting-process times finite, with start below stop. Rows with missing times are gone by now.
data_survival_invalid_times <- function(parts) {
  if (parts$counting) {
    !is.finite(parts$start) | !is.finite(parts$stop) | parts$start >= parts$stop
  } else {
    !is.finite(parts$stop) | parts$stop <= 0
  }
}

data_check_survival_values <- function(parts) {
  invalid <- data_survival_invalid_times(parts)
  if (any(invalid)) {
    abort_invalid_input(
      sprintf(if (parts$counting) {
        "Entry and exit times must be finite, with the entry below the exit: %d row%s are not."
      } else {
        "Right-censored times must be finite and above 0: %d row%s are not."
      }, sum(invalid), if (sum(invalid) == 1L) " is" else "s"),
      arg = "formula"
    )
  }
  invisible(parts)
}

# A column argument of data_prepare() (`weights`, `cluster`): NULL, or a string naming a column.
data_check_column_argument <- function(data, column, arg) {
  if (is.null(column)) return(invisible(NULL))
  check_string(column, arg)
  check_column(data, column, arg)
}

# Case weights: finite and at least 0 (zeros are allowed; the Cox fits leave those rows out, M-25).
data_case_weights <- function(values, column) {
  if (!is.numeric(values) || !all(is.finite(values)) || any(values < 0)) {
    abort_invalid_input(sprintf("The weights column '%s' must hold finite numbers of at least 0.", column),
                        arg = "weights")
  }
  as.double(values)
}

# Cluster codes as survival's coxph() makes them from a column: a factor keeps its codes and levels,
# and other values become integers in the order of their first appearance (DEC-100), so that the
# robust variance sums the clusters in coxph()'s order.
data_cluster_codes <- function(values, column) {
  if (!is.atomic(values) || !is.null(dim(values))) {
    abort_invalid_input(sprintf("The cluster column '%s' must be an atomic vector or a factor.", column),
                        arg = "cluster")
  }
  if (is.factor(values)) values else match(values, unique(values))
}

# The offset of each row of a model frame: the sum of the formula's offset() terms, finite, or NULL
# without offset() terms.
data_offset <- function(frame) {
  offset <- stats::model.offset(frame)
  if (is.null(offset)) return(NULL)
  if (!is.numeric(offset) || !all(is.finite(offset))) {
    abort_invalid_input("The offset() terms of `formula` must give finite numbers.", arg = "formula")
  }
  unname(as.double(offset))
}

# K-139: each provider's person-time, the sum of stop - start over its observations in their stored
# order, as data_event_indicators() sums the events.
data_person_time <- function(providers, start, stop, codes) {
  groups <- data_provider_factor(codes, seq_len(nrow(providers)))
  providers$person_time <- vapply(split(stop - start, groups), sum, numeric(1), USE.NAMES = FALSE)
  providers
}
