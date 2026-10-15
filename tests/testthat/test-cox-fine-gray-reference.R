# The Fine-Gray model against the competing-risk fixtures (the CoxPH brief's §6 A; the CoxPH C5 plan,
# §4.2): pprof_py v0.7.0's FineGrayPH, stratified by provider and not, under the calibrated tiers
# (DEC-097, DEC-125), with one regression test per register entry Phase C5 applies to the model. The core
# set's competing-simple always; the full set's competing-truncated and competing-weights when present,
# behind skip_on_cran(). validation/cox-calibration-report.md holds the same comparisons for survival's
# own records.
local_strict_mode()

fine_gray_reference_ids <- function(set) {
  manifest <- cox_manifest(set)
  if (is.null(manifest)) return(character())
  ids <- names(manifest$cases)
  ids[vapply(ids, function(id) identical(cox_fixture(id, set)$case$kind, "competing"), logical(1))]
}

fine_gray_matches <- function(a, b, tier) {
  is.null(reference_compare(as.double(unlist(a)), as.double(unlist(b)), reference_tolerance(tier)))
}

expect_fine_gray_match <- function(a, b, tier, label) {
  expect(fine_gray_matches(a, b, tier), sprintf("%s: differs from the reference beyond %s", label, tier))
}

expect_fine_gray_differ <- function(a, b, tier, label) {
  expect(!fine_gray_matches(a, b, tier), sprintf("%s: expected to differ beyond %s", label, tier))
}

# The records whose differences from pprof_py the calibration report explains (validation/
# cox-calibration-report.md). D-57: pprof_py halved the last Newton step of these tight fits, so they are
# compared with survival's records and with pprof_py's within the last step. D-58: in the weighted case,
# pprof_py counts zero-weight events among Efron's tied deaths; those fits are survival's on the rows of
# positive weight, and differ from pprof_py's where such events tie (cause 1, and cause 2 without strata)
# and equal them elsewhere.
fine_gray_d57 <- c("competing-simple efron 2", "competing-simple efron 2_unstratified",
                   "competing-weights breslow 1_unstratified")
fine_gray_d58 <- function(fx, ties) isTRUE(fx$case$weighted) && identical(ties, "efron")
fine_gray_d58_tied <- c("1", "1_unstratified", "2_unstratified")

for (set in c("core", "full")) {
  local({
    set_name <- set

    test_that(sprintf("Fine-Gray fits of the %s competing-risk cases match pprof_py's (D-56, D-57, D-58)", set_name), {
      ids <- fine_gray_reference_ids(set_name)
      if (!length(ids)) skip(sprintf("no %s competing-risk fixtures here", set_name))
      if (identical(set_name, "full")) skip_on_cran()
      for (id in ids) {
        fx <- cox_fixture(id, set_name)
        for (ties in c("breslow", "efron")) {
          for (key in names(fx$pprof_py[[ties]]$fine_gray)) {
            label <- paste(id, ties, key)
            py <- fx$pprof_py[[ties]]$fine_gray[[key]]
            r <- fx$survival[[ties]]$fine_gray[[key]]
            default <- fine_gray_case_fit(fx, key, ties)
            tight <- fine_gray_case_fit(fx, key, ties, tight = TRUE)
            expect_identical(default$convergence$iterations, as.integer(py$default$iterations), label = label)
            expect_identical(tight$convergence$iterations, as.integer(py$tight$iterations), label = label)
            d57 <- label %in% fine_gray_d57
            d58 <- fine_gray_d58(fx, ties)
            # survival's records, which the fits reproduce whatever pprof_py does.
            expect_fine_gray_match(coef(tight), r$tight$coef, "cox_coefficient", paste(label, "coefficients, survival"))
            expect_fine_gray_match(cox_packed_upper(vcov(tight)), r$tight$covariance, "cox_variance",
                                   paste(label, "robust covariance, survival"))
            expect_fine_gray_match(cox_packed_upper(tight$naive_vcov), r$tight$naive_covariance, "cox_variance",
                                   paste(label, "model-based covariance, survival"))
            expect_fine_gray_match(tight$loglik, c(r$tight$loglik_null, r$tight$loglik), "cox_function",
                                   paste(label, "log-likelihoods, survival"))
            if (d58) {
              if (key %in% fine_gray_d58_tied) {
                expect_fine_gray_differ(coef(tight), py$tight$coef, "cox_coefficient", paste(label, "pprof_py (D-58)"))
              } else {
                expect_fine_gray_match(coef(tight), py$tight$coef, "cox_coefficient", paste(label, "coefficients"))
              }
              next
            }
            if (d57) {
              bound <- cox_last_step_bound(coef(tight), py$tight$coef, py$iterates, py$tight$iterations)
              expect_lte(max(abs(unname(coef(tight)) - unlist(py$tight$coef))), bound, label = paste(label, "(D-57)"))
            } else {
              expect_fine_gray_match(coef(tight), py$tight$coef, "cox_coefficient", paste(label, "coefficients"))
              bound <- cox_last_step_bound(coef(default), py$default$coef, py$iterates, py$default$iterations)
              expect_lte(max(abs(unname(coef(default)) - unlist(py$default$coef))), bound,
                         label = paste(label, "default"))
            }
            expect_fine_gray_match(cox_packed_upper(tight$naive_vcov), py$tight$naive_covariance, "cox_variance",
                                   paste(label, "model-based covariance"))
            expect_fine_gray_match(tight$loglik, c(py$tight$loglik_null, py$tight$loglik), "cox_function",
                                   paste(label, "log-likelihoods"))
            # D-56: with Breslow ties pprof_py's robust variance applies Efron's formulas to tied deaths, and every
            # Fine-Gray fit is on (start, stop] data.
            if (identical(ties, "breslow")) {
              expect_fine_gray_differ(cox_packed_upper(vcov(tight)), py$tight$covariance, "cox_variance",
                                      paste(label, "robust covariance (D-56)"))
            } else {
              expect_fine_gray_match(cox_packed_upper(vcov(tight)), py$tight$covariance, "cox_variance",
                                     paste(label, "robust covariance"))
            }
          }
        }
      }
    })

    test_that(sprintf("Fine-Gray expansions of the %s competing-risk cases are pprof_py's (K-145)", set_name), {
      ids <- fine_gray_reference_ids(set_name)
      if (!length(ids)) skip(sprintf("no %s competing-risk fixtures here", set_name))
      if (identical(set_name, "full")) skip_on_cran()
      for (id in ids) {
        fx <- cox_fixture(id, set_name)
        def <- fx$case
        for (key in names(fx$pprof_py$breslow$fine_gray)) {
          label <- paste(id, key)
          stratified <- !endsWith(key, "_unstratified")
          d <- fine_gray_case_data(fx, stratified)
          lhs <- if (isTRUE(def$truncated)) "Surv(entry, time, .status)" else "Surv(time, .status)"
          f <- stats::as.formula(paste(lhs, "~", paste(unlist(def$features), collapse = " + ")),
                                 env = list2env(list(Surv = survival::Surv), parent = globalenv()))
          prepared <- data_prepare(f, d, ".provider", response_type = "competing_risks",
                                   weights = if (isTRUE(def$weighted)) "weight", cluster = "id")
          cause <- match(sub("_unstratified", "", key, fixed = TRUE), prepared$settings$states)
          ours <- survival_fine_gray_expand(prepared, cause, survival_fine_gray_subjects(prepared))
          theirs <- fx$pprof_py$breslow$fine_gray[[key]]$expanded
          # The same rows of the input (0-based in the fixture), each in time order.
          input_row <- prepared$row_index[ours$row] - 1L
          order_ours <- order(input_row, ours$start)
          order_theirs <- order(unlist(theirs$row), unlist(theirs$start))
          expect_identical(input_row[order_ours], as.integer(unlist(theirs$row))[order_theirs], label = label)
          expect_identical(ours$status[order_ours], as.double(unlist(theirs$status))[order_theirs], label = label)
          expect_fine_gray_match(ours$start[order_ours], unlist(theirs$start)[order_theirs], "closed_form",
                                 paste(label, "start"))
          expect_fine_gray_match(ours$stop[order_ours], unlist(theirs$stop)[order_theirs], "closed_form",
                                 paste(label, "stop"))
          expect_fine_gray_match(ours$weight[order_ours], unlist(theirs$weight)[order_theirs], "closed_form",
                                 paste(label, "weights"))
        }
      }
    })

    test_that(sprintf("cumulative incidences of the %s competing-risk cases match pprof_py's (D-57, D-58)", set_name), {
      ids <- fine_gray_reference_ids(set_name)
      if (!length(ids)) skip(sprintf("no %s competing-risk fixtures here", set_name))
      if (identical(set_name, "full")) skip_on_cran()
      for (id in ids) {
        fx <- cox_fixture(id, set_name)
        features <- unlist(fx$case$features)
        for (ties in c("breslow", "efron")) {
          for (key in names(fx$pprof_py[[ties]]$fine_gray)) {
            label <- paste(id, ties, key)
            py <- fx$pprof_py[[ties]]$fine_gray[[key]]
            r <- fx$survival[[ties]]$fine_gray[[key]]
            fit <- fine_gray_case_fit(fx, key, ties, tight = TRUE, keep_data = TRUE)
            # D-57 and D-58 records: pprof_py's coefficients differ, and the curves with them.
            against_survival <- label %in% fine_gray_d57 || fine_gray_d58(fx, ties)
            for (k in seq_along(py$cumulative_incidence)) {
              block <- py$cumulative_incidence[[k]]
              reference <- if (against_survival) r$cumulative_incidence[[k]] else block
              provider <- if (is.null(block$stratum)) 0L else block$stratum
              for (i in seq_along(py$profiles)) {
                newdata <- as.data.frame(as.list(stats::setNames(unlist(py$profiles[[i]]), features)))
                newdata$.provider <- provider
                ours <- predict(fit, newdata = newdata, type = "cumulative_incidence")
                values <- unlist(reference$cumulative_incidence[[i]])
                where <- sprintf("%s provider %s profile %d", label, provider, i)
                if (against_survival) {
                  # survival's curves have every time of the provider, censoring times too: ours, its event
                  # times, are among them.
                  at <- match(sprintf("%a", ours$time), sprintf("%a", unlist(reference$time)))
                  expect_false(anyNA(at), label = paste(where, "times"))
                  expect_fine_gray_match(ours$cumulative_incidence, values[at], "cox_baseline", where)
                } else {
                  # pprof_py's curves are at its event times, which in the weighted case include those of
                  # zero-weight events, which survival's fit leaves out (M-25, D-58).
                  at <- match(sprintf("%a", unlist(reference$time)), sprintf("%a", ours$time))
                  if (!isTRUE(fx$case$weighted)) expect_false(anyNA(at), label = paste(where, "times"))
                  expect_fine_gray_match(ours$cumulative_incidence[at[!is.na(at)]], values[!is.na(at)], "cox_baseline",
                                         where)
                }
              }
            }
          }
        }
      }
    })

    test_that(sprintf("coefficient tests of the %s Fine-Gray fits use the robust variance (DEC-101)", set_name), {
      ids <- fine_gray_reference_ids(set_name)
      if (!length(ids)) skip(sprintf("no %s competing-risk fixtures here", set_name))
      if (identical(set_name, "full")) skip_on_cran()
      for (id in ids) {
        fx <- cox_fixture(id, set_name)
        fit <- fine_gray_case_fit(fx, "1", "efron", tight = TRUE)
        table <- test_coefficients(fit)$table
        expect_identical(table$std_error, unname(sqrt(diag(vcov(fit)))), label = id)
        expect_identical(table$p_value, 2 * stats::pnorm(abs(table$statistic), lower.tail = FALSE), label = id)
      }
    })
  })
}
