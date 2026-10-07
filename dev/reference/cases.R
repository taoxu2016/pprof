# Reference cases: every public function and S3 method of the reference over an argument
# grid (ARCHITECTURE §G.2), on the bundled datasets and the synthetic suite in datasets.R.
#
# Requires the argument markers from tests/testthat/helper-reference-cases.R (ref_dataset(),
# ref_element(), ref_formula(), ref_fit(), ref_value(), ref_expr()).
#
# Fields of a case:
#   id      unique identifier, also the fixture file name
#   set     "core" (shipped with the package tests) or "full" (validation/ only)
#   fun     function name; S3 methods are called through their generic
#   args    arguments, with markers for datasets, formulas, and parent results
#   seed    RNG seed set immediately before the call (stochastic cases only)
#   tier    default tolerance tier for comparisons (helper-tolerances.R)
#   heavy   TRUE for slow cases, which tests skip on CRAN
#   notes   register entries (D-xx, K-xx) or audit evidence the case exercises
#   emulate "reformulate-4.5.0" for a case that records what pprof 1.0.3 does from R 4.5.0, which
#           the generator emulates on older R (generate_fixtures.R; D-30, D-54); absent otherwise
#
# Every call that has a threads argument passes threads = 1 (brief §3.1); calls that set
# threads internally (D-21) are capped by OMP_THREAD_LIMIT = 1 in the generator.

reference_cases <- function() {
  cases <- list()
  add <- function(id, fun, args, tier, set = "core", seed = NULL, heavy = FALSE, notes = "", emulate = NULL) {
    if (!is.null(cases[[id]])) stop("Duplicate case id: ", id, call. = FALSE)
    cases[[id]] <<- c(list(id = id, set = set, fun = fun, args = args, seed = seed, tier = tier,
                           heavy = heavy, notes = notes), if (!is.null(emulate)) list(emulate = emulate))
  }
  z5 <- paste0("z", 1:5)
  columns <- function(dataset, z, y = "Y", provider = "ProvID") {
    list(data = ref_dataset(dataset), Y.char = y, Z.char = z, ProvID.char = provider)
  }
  parm_ids <- c(1, 31:35, 99:101)

  # --- logis_fe ---------------------------------------------------------------------------
  F1 <- "logis_fe-binary-columns"
  add(F1, "logis_fe", c(columns("binary_example", z5), threads = 1), "iterative", notes = "K-10 to K-23")
  add("logis_fe-binary-formula", "logis_fe",
      list(formula = ref_formula("Y ~ z1 + z2 + z3 + z4 + z5 + id(ProvID)"), data = ref_dataset("binary_example"), threads = 1),
      "iterative", notes = "K-01, V10.11")
  add("logis_fe-binary-vectors", "logis_fe",
      list(Y = ref_element("binary_example_list", "Y"), Z = ref_element("binary_example_list", "Z"),
           ProvID = ref_element("binary_example_list", "ProvID"), threads = 1),
      "iterative", notes = "K-01, V10.11")
  for (s in c("beta", "relch", "ratch", "all")) {
    add(paste0("logis_fe-binary-serbin-stop-", s), "logis_fe", c(columns("binary_example", z5), stop = s, threads = 1),
        "iterative", notes = "K-16")
  }
  add("logis_fe-binary-ban", "logis_fe", c(columns("binary_example", z5), method = "BAN", threads = 1), "iterative", notes = "K-14, K-16")
  add("logis_fe-binary-ban-stop-beta", "logis_fe", c(columns("binary_example", z5), method = "BAN", stop = "beta", threads = 1),
      "iterative", notes = "K-16")
  add("logis_fe-binary-serbin-nobacktrack", "logis_fe", c(columns("binary_example", z5), backtrack = FALSE, threads = 1),
      "iterative", notes = "K-14")
  add("logis_fe-binary-ban-nobacktrack", "logis_fe", c(columns("binary_example", z5), method = "BAN", backtrack = FALSE, threads = 1),
      "iterative", notes = "K-14, K-16")
  add("logis_fe-binary-serbin-tight", "logis_fe", c(columns("binary_example", z5), tol = 1e-10, stop = "all", threads = 1),
      "iterative", notes = "Tier 2 at tight tolerance (brief §3.4)")
  add("logis_fe-binary-ban-tight", "logis_fe", c(columns("binary_example", z5), method = "BAN", tol = 1e-10, stop = "all", threads = 1),
      "iterative", notes = "Tier 2 at tight tolerance (brief §3.4)")
  add("logis_fe-binary-cutoff60", "logis_fe", c(columns("binary_example", z5), cutoff = 60, threads = 1), "iterative", notes = "K-06")
  add("logis_fe-binary-bound5", "logis_fe", c(columns("binary_example", z5), bound = 5, threads = 1), "iterative", notes = "K-15")
  add("logis_fe-binary-quiet", "logis_fe", c(columns("binary_example", z5), message = FALSE, threads = 1), "iterative",
      notes = "iteration probe")
  add("logis_fe-binary-serbin-maxiter3", "logis_fe", c(columns("binary_example", z5), max.iter = 3, tol = 1e-300, stop = "beta", threads = 1),
      "iterative", notes = "D-03, K-17")
  add("logis_fe-binary-ban-maxiter3", "logis_fe",
      c(columns("binary_example", z5), method = "BAN", max.iter = 3, tol = 1e-300, stop = "beta", threads = 1),
      "iterative", notes = "D-03, K-17")
  add("logis_fe-binary-ban-backtrack2", "logis_fe", c(columns("binary_example", z5), method = "BAN", backtrack = 2, threads = 1),
      "iterative", notes = "D-23")
  add("logis_fe-binary-bad-method", "logis_fe", c(columns("binary_example", z5), method = "XYZ", threads = 1), "exact")
  add("logis_fe-binary-bad-stop", "logis_fe", c(columns("binary_example", z5), stop = "sometimes", threads = 1), "exact")
  for (cut in c(10, 5, 11)) {
    add(sprintf("logis_fe-screening-cutoff%d", cut), "logis_fe",
        c(columns("syn_screening", c("x1", "x2", "x3")), cutoff = cut, threads = 1), "iterative", notes = "K-06, D-01")
  }
  add("logis_fe-screening-onecov", "logis_fe", c(columns("syn_screening", "x1"), threads = 1), "iterative", notes = "D-30 parent")
  add("logis_fe-screening-twocov", "logis_fe", c(columns("syn_screening", c("x1", "x2")), threads = 1), "iterative", notes = "D-30 parent")
  # D-54: from R 4.5.0, pprof 1.0.3 fits a model with no covariates (emulated on older R).
  add("logis_fe-screening-nocov", "logis_fe", c(columns("syn_screening", character(0)), threads = 1), "iterative",
      notes = "D-54", emulate = "reformulate-4.5.0")
  # The null model of x1 in summary(logis_fe-screening-twocov, test = "lr"): the expected
  # result of the D-30 fix comes from this fit and logis_fe-screening-onecov (Phase 3).
  add("logis_fe-screening-x2", "logis_fe", c(columns("syn_screening", "x2"), threads = 1), "iterative",
      notes = "D-30 expected result")
  FX <- "logis_fe-extreme"
  add(FX, "logis_fe", c(columns("syn_extreme", c("x1", "x2", "x3")), threads = 1), "iterative", notes = "K-06, K-15")
  add("logis_fe-extreme-chr", "logis_fe", c(columns("syn_extreme_chr", c("x1", "x2", "x3")), threads = 1), "iterative", notes = "K-05, D-34")
  add("logis_fe-extreme-fac", "logis_fe", c(columns("syn_extreme_fac", c("x1", "x2", "x3")), threads = 1), "iterative", notes = "D-28 parent")
  add("logis_fe-extreme-int", "logis_fe", c(columns("syn_extreme_int", c("x1", "x2", "x3")), threads = 1), "iterative", notes = "D-27 parent")
  add("logis_fe-extreme-hospital", "logis_fe",
      list(formula = ref_formula("Y ~ x1 + x2 + x3 + id(hospital)"), data = ref_dataset("syn_extreme_hospital"), threads = 1),
      "iterative", notes = "D-29 parent")
  add("logis_fe-separation", "logis_fe", c(columns("syn_separation", c("x1", "x2", "xs")), max.iter = 200, threads = 1), "iterative")
  add("logis_fe-collinear", "logis_fe", c(columns("syn_collinear", c("x1", "x2", "x3")), threads = 1), "iterative")
  add("logis_fe-constant", "logis_fe", c(columns("syn_constant", c("x1", "x2", "xc")), threads = 1), "iterative")
  add("logis_fe-factors-spaces-formula", "logis_fe",
      list(formula = ref_formula("Y ~ x1 + grp + id(ProvID)"), data = ref_dataset("syn_factors"), threads = 1), "iterative", notes = "D-18")
  # The same model with level names without spaces: the expected result of the D-18 fix for
  # the case above (Phase 3).
  add("logis_fe-factors-nospaces-formula", "logis_fe",
      list(formula = ref_formula("Y ~ x1 + grp + id(ProvID)"), data = ref_dataset("syn_factors_nospaces"), threads = 1),
      "iterative", notes = "D-18 expected result")
  add("logis_fe-factors-unused-columns", "logis_fe", c(columns("syn_factors", c("x1", "grp2")), threads = 1), "iterative")
  for (term in c("log(w)", "z1:z2", "I(z1^2)")) {
    add(paste0("logis_fe-terms-", gsub("[^a-z0-9]", "", term)), "logis_fe",
        list(formula = ref_formula(sprintf("Y ~ z1 + z2 + %s + id(ProvID)", term)), data = ref_dataset("syn_terms"), threads = 1),
        "iterative", notes = "D-18")
  }
  # The same models with the terms computed as columns: the expected results of the D-18
  # fix for the three cases above (Phase 3).
  column_terms <- c(logw = "logw", z1z2 = "z1z2", z12 = "z1sq")
  for (tag in names(column_terms)) {
    add(paste0("logis_fe-terms-", tag, "-columns"), "logis_fe",
        list(formula = ref_formula(sprintf("Y ~ z1 + z2 + %s + id(ProvID)", column_terms[[tag]])),
             data = ref_dataset("syn_terms_columns"), threads = 1),
        "iterative", notes = "D-18 expected result")
  }
  add("logis_fe-missing-formula", "logis_fe",
      list(formula = ref_formula("Y ~ x1 + x2 + id(ProvID)"), data = ref_dataset("syn_missing"), threads = 1), "iterative", notes = "K-03")
  add("logis_fe-missing-columns", "logis_fe", c(columns("syn_missing", c("x1", "x2")), threads = 1), "iterative", notes = "K-03")
  add("logis_fe-unequal", "logis_fe", c(columns("syn_unequal", c("x1", "x2")), threads = 1), "iterative")
  add("logis_fe-rare", "logis_fe", c(columns("syn_rare", c("x1", "x2")), threads = 1), "iterative")
  add("logis_fe-common", "logis_fe", c(columns("syn_common", c("x1", "x2")), threads = 1), "iterative")
  add("logis_fe-d04", "logis_fe", c(columns("syn_d04", "x1"), threads = 1), "iterative", notes = "D-04 parent")
  add("logis_fe-d04-double", "logis_fe", c(columns("syn_d04_double", "x1"), threads = 1), "iterative",
      notes = "D-04 expected-result parent")
  add("logis_fe-cutoff5", "logis_fe", c(columns("syn_cutoff5", c("x1", "x2", "x3")), cutoff = 5, threads = 1), "iterative", notes = "D-10 parent")

  # --- logis_firth ------------------------------------------------------------------------
  FF <- "logis_firth-binary-columns"
  add(FF, "logis_firth", c(columns("binary_example", z5), threads = 1), "iterative", notes = "K-30 to K-34, D-12")
  add("logis_firth-small-tight", "logis_firth", c(columns("syn_firth_small", c("x1", "x2")), tol = 1e-10, threads = 1),
      "iterative", notes = "V12.5")
  add("logis_firth-extreme", "logis_firth", c(columns("syn_extreme", c("x1", "x2", "x3")), threads = 1), "iterative")
  add("logis_firth-screening", "logis_firth", c(columns("syn_screening", c("x1", "x2", "x3")), threads = 1), "iterative", notes = "D-01")
  add("logis_firth-screening-nocov", "logis_firth", c(columns("syn_screening", character(0)), threads = 1), "iterative",
      notes = "D-54", emulate = "reformulate-4.5.0")

  # --- linear_fe --------------------------------------------------------------------------
  L1 <- "linear_fe-linear-columns"
  L2 <- "linear_fe-linear-columns-full"
  add(L1, "linear_fe", list(data = ref_dataset("linear_example"), Y.char = "Y", Z.char = z5, ProvID.char = "ProvID"),
      "closed_form", notes = "K-40 to K-43")
  add(L2, "linear_fe", list(data = ref_dataset("linear_example"), Y.char = "Y", Z.char = z5, ProvID.char = "ProvID",
                            option.gamma.var = "full"), "closed_form", notes = "K-42")
  add("linear_fe-linear-nocov", "linear_fe",
      list(data = ref_dataset("linear_example"), Y.char = "Y", Z.char = character(0), ProvID.char = "ProvID"),
      "closed_form", notes = "D-54", emulate = "reformulate-4.5.0")
  add("linear_fe-linear-formula", "linear_fe",
      list(formula = ref_formula("Y ~ z1 + z2 + z3 + z4 + z5 + id(ProvID)"), data = ref_dataset("linear_example")), "closed_form")
  add("linear_fe-linear-vectors", "linear_fe",
      list(Y = ref_element("linear_example_list", "Y"), Z = ref_element("linear_example_list", "Z"),
           ProvID = ref_element("linear_example_list", "ProvID")), "closed_form")
  add("linear_fe-ecls", "linear_fe",
      list(formula = ref_formula("Math_Score ~ Income + Child_Sex + id(School_ID)"), data = ref_dataset("ecls")), "closed_form")
  LS <- "linear_fe-syn"
  add(LS, "linear_fe", list(data = ref_dataset("syn_linear"), Y.char = "Y", Z.char = c("x1", "x2", "grp"), ProvID.char = "ProvID"),
      "closed_form")
  add("linear_fe-syn-full", "linear_fe",
      list(data = ref_dataset("syn_linear"), Y.char = "Y", Z.char = c("x1", "x2", "grp"), ProvID.char = "ProvID",
           option.gamma.var = "f"), "closed_form", notes = "K-42 (abbreviated option)")
  add("linear_fe-bad-option", "linear_fe",
      list(data = ref_dataset("syn_linear"), Y.char = "Y", Z.char = c("x1", "x2"), ProvID.char = "ProvID", option.gamma.var = "fu"),
      "exact", notes = "K-42")
  # Phase 5 (R-1): provider IDs stored as integers (D-27), and small providers whose funnel
  # limits and flags disagree with the full variance (D-43).
  LI <- "linear_fe-syn-int"
  add(LI, "linear_fe", list(data = ref_dataset("syn_linear_int"), Y.char = "Y", Z.char = c("x1", "x2", "grp"),
                            ProvID.char = "ProvID"), "closed_form", notes = "D-27 parent")
  LF <- "linear_fe-funnel-full"
  add(LF, "linear_fe", list(data = ref_dataset("syn_linear_funnel"), Y.char = "Y", Z.char = z5, ProvID.char = "ProvID",
                            option.gamma.var = "full"), "closed_form", notes = "D-43 parent")

  # --- linear_re, logis_re, linear_cre, logis_cre -----------------------------------------
  R1 <- "linear_re-linear-columns"
  add(R1, "linear_re", list(data = ref_dataset("linear_example"), Y.char = "Y", Z.char = z5, ProvID.char = "ProvID"),
      "lme4", notes = "K-50 to K-53")
  add("linear_re-linear-formula", "linear_re",
      list(formula = ref_formula("Y ~ z1 + z2 + z3 + z4 + z5 + (1 | ProvID)"), data = ref_dataset("linear_example")), "lme4")
  add("linear_re-linear-ml", "linear_re",
      list(data = ref_dataset("linear_example"), Y.char = "Y", Z.char = z5, ProvID.char = "ProvID", REML = FALSE), "lme4",
      notes = "... pass-through")
  add("linear_re-ecls", "linear_re",
      list(formula = ref_formula("Math_Score ~ Income + Child_Sex + (1 | School_ID)"), data = ref_dataset("ecls")), "lme4",
      heavy = TRUE)
  add("linear_re-syn", "linear_re", list(data = ref_dataset("syn_linear"), Y.char = "Y", Z.char = c("x1", "x2"), ProvID.char = "ProvID"),
      "lme4")
  G1 <- "logis_re-binary-columns"
  add(G1, "logis_re", list(data = ref_dataset("binary_example"), Y.char = "Y", Z.char = z5, ProvID.char = "ProvID"), "lme4",
      heavy = TRUE, notes = "K-50 to K-53")
  GX <- "logis_re-extreme"
  add(GX, "logis_re", list(data = ref_dataset("syn_extreme"), Y.char = "Y", Z.char = c("x1", "x2", "x3"), ProvID.char = "ProvID"), "lme4")
  C1 <- "linear_cre-linear"
  add(C1, "linear_cre", list(data = ref_dataset("linear_example"), Y.char = "Y", wb.char = c("z1", "z2"),
                             other.char = c("z3", "z4", "z5"), ProvID.char = "ProvID"), "lme4", notes = "K-54")
  add("linear_cre-missing", "linear_cre", list(data = ref_dataset("syn_linear_missing"), Y.char = "Y", wb.char = "z1",
                                               other.char = "z2", ProvID.char = "ProvID"), "lme4", notes = "D-13")
  K1 <- "logis_cre-binary"
  add(K1, "logis_cre", list(data = ref_dataset("binary_example"), Y.char = "Y", wb.char = c("z1", "z2"),
                            other.char = c("z3", "z4", "z5"), ProvID.char = "ProvID"), "lme4", heavy = TRUE, notes = "K-51, K-54")
  KX <- "logis_cre-extreme"
  add(KX, "logis_cre", list(data = ref_dataset("syn_extreme"), Y.char = "Y", wb.char = "x1", other.char = c("x2", "x3"),
                            ProvID.char = "ProvID"), "lme4")
  # A control object passed through `...` to lme4 (ARCHITECTURE §G.2). Nelder_Mead is not the
  # default optimizer of lmer() or glmer() and moves the estimates by far more than the lme4
  # tolerance (theta by at least 6.8e-7 relative), so a control argument that does not reach
  # lme4 fails the comparison. (bobyqa for lmer() lands within 4e-9 of the default for
  # linear_cre, which the tolerance would not detect.)
  lmer_control <- ref_expr('lme4::lmerControl(optimizer = "Nelder_Mead")')
  glmer_control <- ref_expr('lme4::glmerControl(optimizer = "Nelder_Mead")')
  add("linear_re-linear-control", "linear_re",
      list(data = ref_dataset("linear_example"), Y.char = "Y", Z.char = z5, ProvID.char = "ProvID", control = lmer_control), "lme4",
      notes = "... pass-through")
  add("logis_re-extreme-control", "logis_re",
      list(data = ref_dataset("syn_extreme"), Y.char = "Y", Z.char = c("x1", "x2", "x3"), ProvID.char = "ProvID",
           control = glmer_control), "lme4", notes = "... pass-through")
  add("linear_cre-linear-control", "linear_cre",
      list(data = ref_dataset("linear_example"), Y.char = "Y", wb.char = c("z1", "z2"), other.char = c("z3", "z4", "z5"),
           ProvID.char = "ProvID", control = lmer_control), "lme4", notes = "... pass-through")
  add("logis_cre-extreme-control", "logis_cre",
      list(data = ref_dataset("syn_extreme"), Y.char = "Y", wb.char = "x1", other.char = c("x2", "x3"), ProvID.char = "ProvID",
           control = glmer_control), "lme4", notes = "... pass-through")
  # Phase 5 (R-1): the vector interface of linear_re() and logis_re() (D-11), where the
  # reference works and where it fails; character IDs whose order depends on the collation
  # (D-34); integer IDs (D-27).
  vectors <- function(dataset, provider, z) {
    list(Y = ref_element(dataset, "Y"), Z = ref_element(dataset, z), ProvID = ref_element(dataset, provider))
  }
  add("linear_re-vectors-matrix", "linear_re", vectors("syn_linear_vectors", "ProvID", "Z_matrix"), "lme4", notes = "D-11")
  add("linear_re-vectors-df", "linear_re", vectors("syn_linear_vectors", "ProvID", "Z"), "lme4", notes = "D-11")
  add("linear_re-vectors-chr-df", "linear_re", vectors("syn_linear_vectors", "ProvID_chr", "Z"), "lme4", notes = "D-11")
  add("logis_re-vectors-matrix", "logis_re", vectors("syn_extreme_vectors", "ProvID", "Z_matrix"), "lme4", notes = "D-11")
  add("logis_re-vectors-chr-df", "logis_re", vectors("syn_extreme_vectors", "ProvID_chr", "Z"), "lme4", notes = "D-11")
  add("linear_re-vectors-chr-matrix", "linear_re", vectors("syn_linear_vectors", "ProvID_chr", "Z_matrix"), "exact",
      notes = "D-11 (reference error: cbind() makes every column text)")
  add("linear_re-vectors-incomplete", "linear_re", list(Y = ref_element("syn_linear_vectors", "Y")), "exact",
      notes = "D-11 (reference error: no input format matches)")
  GC <- "logis_re-extreme-chr"
  add(GC, "logis_re", list(data = ref_dataset("syn_extreme_chr"), Y.char = "Y", Z.char = c("x1", "x2", "x3"), ProvID.char = "ProvID"),
      "lme4", notes = "D-34")
  KI <- "logis_cre-extreme-int"
  add(KI, "logis_cre", list(data = ref_dataset("syn_extreme_int"), Y.char = "Y", wb.char = "x1", other.char = c("x2", "x3"),
                            ProvID.char = "ProvID"), "lme4", notes = "D-27 parent")

  # --- test() -----------------------------------------------------------------------------
  alts <- c("two.sided", "greater", "less")
  for (a in alts) {
    add(paste0("test-binary-exact-", a), "test", list(fit = ref_fit(F1), alternative = a, threads = 1), "iterative", notes = "K-62, K-63")
    add(paste0("test-binary-bootstrap-", a), "test", list(fit = ref_fit(F1), test = "exact.bootstrap", n = 500, alternative = a, threads = 1),
        "iterative", seed = 20261002, notes = "K-64")
    add(paste0("test-binary-score-", a), "test", list(fit = ref_fit(F1), test = "score", alternative = a, threads = 1), "iterative",
        notes = "K-65")
    add(paste0("test-binary-score-standard-", a), "test",
        list(fit = ref_fit(F1), test = "score", score_modified = FALSE, alternative = a, threads = 1), "iterative", notes = "K-66")
    add(paste0("test-binary-wald-", a), "test", list(fit = ref_fit(F1), test = "wald", alternative = a, threads = 1), "iterative",
        notes = "K-67")
  }
  # Three seeds of one bootstrap configuration (ARCHITECTURE §G.2); the first seed is
  # test-binary-bootstrap-two.sided above.
  for (k in 2:3) {
    add(sprintf("test-binary-bootstrap-two.sided-seed%d", k), "test",
        list(fit = ref_fit(F1), test = "exact.bootstrap", n = 500, alternative = "two.sided", threads = 1), "iterative",
        seed = 20261003 + k, notes = "K-64")
  }
  add("test-binary-exact-null0", "test", list(fit = ref_fit(F1), null = 0, threads = 1), "iterative", notes = "K-60")
  add("test-binary-exact-null-negative", "test", list(fit = ref_fit(F1), null = -0.5, threads = 1), "iterative", notes = "K-60")
  add("test-binary-exact-null-integer", "test", list(fit = ref_fit(F1), null = 0L, threads = 1), "iterative", notes = "D-14")
  add("test-binary-wald-null0", "test", list(fit = ref_fit(F1), test = "wald", null = 0, threads = 1), "iterative")
  add("test-binary-exact-level90", "test", list(fit = ref_fit(F1), level = 0.9, threads = 1), "iterative", notes = "K-61")
  add("test-binary-wald-level90", "test", list(fit = ref_fit(F1), test = "wald", level = 0.9, threads = 1), "iterative")
  add("test-binary-exact-parm", "test", list(fit = ref_fit(F1), parm = parm_ids, threads = 1), "iterative")
  add("test-binary-wald-parm", "test", list(fit = ref_fit(F1), test = "wald", parm = parm_ids, threads = 1), "iterative", notes = "D-15")
  add("test-binary-score-standard-parm", "test",
      list(fit = ref_fit(F1), test = "score", score_modified = FALSE, parm = parm_ids, threads = 1), "iterative")
  add("test-binary-robust-wald", "test", list(fit = ref_fit(F1), test = "robust_wald", threads = 1), "exact", notes = "D-06")
  add("test-binary-bad-null", "test", list(fit = ref_fit(F1), null = "abc", threads = 1), "exact")
  add("test-extreme-exact", "test", list(fit = ref_fit(FX), threads = 1), "iterative")
  add("test-extreme-score-standard", "test", list(fit = ref_fit(FX), test = "score", score_modified = FALSE, threads = 1), "iterative")
  add("test-extreme-wald", "test", list(fit = ref_fit(FX), test = "wald", threads = 1), "iterative")
  add("test-extreme-bootstrap", "test", list(fit = ref_fit(FX), test = "exact.bootstrap", n = 500, threads = 1), "iterative",
      seed = 20261003)
  add("test-extreme-chr-exact-parm", "test", list(fit = ref_fit("logis_fe-extreme-chr"), parm = c("a40", "B39", "D01"), threads = 1),
      "iterative")
  add("test-extreme-int-parm", "test", list(fit = ref_fit("logis_fe-extreme-int"), parm = 1:3, threads = 1), "exact", notes = "D-27")
  add("test-d04-score-standard", "test", list(fit = ref_fit("logis_fe-d04"), test = "score", score_modified = FALSE, threads = 1),
      "exact", notes = "D-04")
  add("test-d04-score-standard-others", "test",
      list(fit = ref_fit("logis_fe-d04-double"), parm = as.numeric(setdiff(1:30, 5)), test = "score", score_modified = FALSE,
           threads = 1),
      "exact", notes = "D-04 expected result: the providers other than provider 5")
  add("test-firth-exact", "test", list(fit = ref_fit(FF), threads = 1), "iterative")
  add("test-firth-wald", "test", list(fit = ref_fit(FF), test = "wald", threads = 1), "iterative")

  # --- SM_output() ------------------------------------------------------------------------
  add("SM_output-binary-default", "SM_output", list(fit = ref_fit(F1), threads = 1), "iterative", notes = "K-80")
  add("SM_output-binary-direct", "SM_output", list(fit = ref_fit(F1), stdz = "direct", threads = 1), "iterative", notes = "K-81")
  add("SM_output-binary-both", "SM_output", list(fit = ref_fit(F1), stdz = c("indirect", "direct"), measure = c("ratio", "rate"),
                                                 threads = 1), "iterative")
  add("SM_output-binary-ratio", "SM_output", list(fit = ref_fit(F1), measure = "ratio", threads = 1), "iterative")
  add("SM_output-binary-rate", "SM_output", list(fit = ref_fit(F1), measure = "rate", threads = 1), "iterative", notes = "D-08")
  add("SM_output-binary-null0", "SM_output", list(fit = ref_fit(F1), null = 0, threads = 1), "iterative")
  add("SM_output-binary-null-integer", "SM_output", list(fit = ref_fit(F1), null = 0L, threads = 1), "exact", notes = "D-14")
  add("SM_output-binary-parm", "SM_output", list(fit = ref_fit(F1), parm = parm_ids, stdz = c("indirect", "direct"), threads = 1),
      "iterative")
  add("SM_output-extreme-both", "SM_output", list(fit = ref_fit(FX), stdz = c("indirect", "direct"), threads = 1), "iterative")
  add("SM_output-extreme-chr-both", "SM_output", list(fit = ref_fit("logis_fe-extreme-chr"), stdz = c("indirect", "direct"),
                                                      threads = 1), "iterative")
  add("SM_output-firth-both", "SM_output", list(fit = ref_fit(FF), stdz = c("indirect", "direct"), threads = 1), "iterative")

  # --- confint() --------------------------------------------------------------------------
  for (tt in c("exact", "score", "wald")) {
    tier <- if (tt == "wald") "iterative" else "root"
    add(paste0("confint-binary-gamma-", tt), "confint", list(object = ref_fit(F1), option = "gamma", test = tt), tier, notes = "K-90")
    add(paste0("confint-binary-sm-", tt), "confint",
        list(object = ref_fit(F1), test = tt, stdz = c("indirect", "direct"), measure = c("ratio", "rate")), tier,
        heavy = tt != "wald", notes = "K-91")
  }
  for (a in c("greater", "less")) {
    add(paste0("confint-binary-sm-exact-", a), "confint",
        list(object = ref_fit(F1), stdz = c("indirect", "direct"), alternative = a), "root", heavy = TRUE, notes = "K-91, K-94")
  }
  add("confint-binary-sm-exact-level90", "confint", list(object = ref_fit(F1), level = 0.9), "root", heavy = TRUE)
  add("confint-binary-gamma-exact-parm", "confint", list(object = ref_fit(F1), option = "gamma", parm = parm_ids), "root")
  add("confint-binary-sm-exact-parm", "confint", list(object = ref_fit(F1), parm = parm_ids, stdz = c("indirect", "direct")), "root")
  add("confint-binary-gamma-greater", "confint", list(object = ref_fit(F1), option = "gamma", alternative = "greater"), "exact")
  add("confint-extreme-gamma-exact", "confint", list(object = ref_fit(FX), option = "gamma"), "root", notes = "K-90 extreme providers")
  add("confint-extreme-gamma-score", "confint", list(object = ref_fit(FX), option = "gamma", test = "score"), "root")
  add("confint-extreme-sm-exact", "confint", list(object = ref_fit(FX), stdz = c("indirect", "direct")), "root", notes = "K-91")
  add("confint-extreme-chr-sm-exact", "confint", list(object = ref_fit("logis_fe-extreme-chr")), "root", notes = "D-19")
  add("confint-extreme-chr-gamma-exact", "confint", list(object = ref_fit("logis_fe-extreme-chr"), option = "gamma"), "root",
      notes = "D-19")
  add("confint-extreme-fac-gamma-exact", "confint", list(object = ref_fit("logis_fe-extreme-fac"), option = "gamma"), "exact",
      notes = "D-28")
  add("confint-extreme-hospital-sm-direct", "confint", list(object = ref_fit("logis_fe-extreme-hospital"), stdz = "direct"), "exact",
      notes = "D-29")
  add("confint-firth-sm-exact", "confint", list(object = ref_fit(FF)), "root", heavy = TRUE)

  # --- summary() --------------------------------------------------------------------------
  add("summary-binary-wald", "summary", list(object = ref_fit(F1)), "iterative", notes = "K-100")
  add("summary-binary-lr", "summary", list(object = ref_fit(F1), test = "lr"), "iterative", heavy = TRUE, notes = "K-101, D-10")
  add("summary-binary-score", "summary", list(object = ref_fit(F1), test = "score"), "iterative", heavy = TRUE, notes = "K-102")
  add("summary-binary-wald-parm", "summary", list(object = ref_fit(F1), parm = c("z1", "z4", "Z5")), "iterative")
  add("summary-binary-wald-level90", "summary", list(object = ref_fit(F1), level = 0.9), "iterative")
  add("summary-binary-lr-parm", "summary", list(object = ref_fit(F1), test = "lr", parm = 2), "iterative")
  add("summary-screening-onecov-lr", "summary", list(object = ref_fit("logis_fe-screening-onecov"), test = "lr"), "iterative",
      notes = "D-30, DEC-084", emulate = "reformulate-4.5.0")
  add("summary-screening-onecov-score", "summary", list(object = ref_fit("logis_fe-screening-onecov"), test = "score"),
      "exact", notes = "D-30, DEC-084", emulate = "reformulate-4.5.0")
  add("summary-screening-twocov-lr", "summary", list(object = ref_fit("logis_fe-screening-twocov"), test = "lr"), "exact", notes = "D-30")
  add("summary-cutoff5-lr", "summary", list(object = ref_fit("logis_fe-cutoff5"), test = "lr"), "exact", notes = "D-10")
  add("summary-firth-wald", "summary", list(object = ref_fit(FF)), "iterative")

  # --- plot() for logis_fe ----------------------------------------------------------------
  add("plot-binary-score", "plot", list(x = ref_fit(F1)), "iterative", notes = "K-110")
  add("plot-binary-score-two-levels", "plot", list(x = ref_fit(F1), alpha = c(0.05, 0.01)), "iterative")
  add("plot-binary-exact", "plot", list(x = ref_fit(F1), test = "exact"), "exact", notes = "D-07")
  add("plot-binary-null-integer", "plot", list(x = ref_fit(F1), null = 0L), "exact", notes = "D-14")
  # The same plot with a double null: the expected result of the D-14 fix (Phase 3).
  add("plot-binary-null0", "plot", list(x = ref_fit(F1), null = 0), "iterative", notes = "D-14 expected result")

  # --- linear_fe methods ------------------------------------------------------------------
  for (fit_id in c(L1, L2)) {
    tag <- if (fit_id == L1) "simplified" else "full"
    for (a in alts) {
      add(sprintf("test-linear-%s-%s", tag, a), "test", list(fit = ref_fit(fit_id), alternative = a), "closed_form", notes = "K-68")
    }
    add(sprintf("confint-linear-%s-gamma", tag), "confint", list(object = ref_fit(fit_id), option = "gamma"), "closed_form",
        notes = "K-92, D-32")
    add(sprintf("confint-linear-%s-sm", tag), "confint", list(object = ref_fit(fit_id), stdz = c("indirect", "direct")),
        "closed_form", notes = "K-92")
  }
  add("test-linear-null-mean", "test", list(fit = ref_fit(L1), null = "mean"), "closed_form", notes = "K-60")
  add("test-linear-null0", "test", list(fit = ref_fit(L1), null = 0), "closed_form")
  add("test-linear-parm", "test", list(fit = ref_fit(L1), parm = parm_ids), "closed_form")
  add("test-linear-bad-null", "test", list(fit = ref_fit(L1), null = "abc"), "exact")
  for (s in c("indirect", "direct")) {
    add(paste0("SM_output-linear-", s), "SM_output", list(fit = ref_fit(L1), stdz = s), "closed_form", notes = "K-83")
  }
  add("SM_output-linear-both-mean", "SM_output", list(fit = ref_fit(L1), stdz = c("indirect", "direct"), null = "mean"), "closed_form")
  add("SM_output-linear-both-null0", "SM_output", list(fit = ref_fit(L1), stdz = c("indirect", "direct"), null = 0), "closed_form")
  for (a in c("greater", "less")) {
    add(paste0("confint-linear-simplified-sm-", a), "confint", list(object = ref_fit(L1), stdz = c("indirect", "direct"), alternative = a),
        "closed_form", notes = "K-94")
  }
  add("confint-linear-gamma-greater", "confint", list(object = ref_fit(L1), option = "gamma", alternative = "greater"), "exact")
  add("summary-linear", "summary", list(object = ref_fit(L1)), "closed_form", notes = "K-103")
  add("summary-linear-parm", "summary", list(object = ref_fit(L1), parm = c("z1", "z4", "Z5")), "closed_form")
  add("summary-linear-level90", "summary", list(object = ref_fit(L1), level = 0.9), "closed_form")
  add("plot-linear", "plot", list(x = ref_fit(L1)), "closed_form", notes = "K-111")
  add("plot-linear-two-levels", "plot", list(x = ref_fit(L1), alpha = c(0.05, 0.01)), "closed_form")
  add("test-linear-syn", "test", list(fit = ref_fit(LS)), "closed_form")
  add("SM_output-linear-syn", "SM_output", list(fit = ref_fit(LS), stdz = c("indirect", "direct")), "closed_form")
  add("confint-linear-syn-sm", "confint", list(object = ref_fit(LS), stdz = c("indirect", "direct")), "closed_form")
  # Phase 5 (R-1). An integer null, which every linear FE method rejects (D-14), with the
  # results at null = 0 that the fix must give (test and SM_output have theirs above).
  add("test-linear-null-integer", "test", list(fit = ref_fit(L1), null = 0L), "exact", notes = "D-14")
  add("SM_output-linear-null-integer", "SM_output", list(fit = ref_fit(L1), stdz = c("indirect", "direct"), null = 0L), "exact",
      notes = "D-14")
  add("confint-linear-null-integer", "confint", list(object = ref_fit(L1), stdz = c("indirect", "direct"), null = 0L), "exact",
      notes = "D-14")
  add("plot-linear-null-integer", "plot", list(x = ref_fit(L1), null = 0L), "exact", notes = "D-14")
  add("confint-linear-null0", "confint", list(object = ref_fit(L1), stdz = c("indirect", "direct"), null = 0), "closed_form",
      notes = "D-14 expected result")
  add("plot-linear-null0", "plot", list(x = ref_fit(L1), null = 0), "closed_form", notes = "D-14 expected result")
  add("confint-linear-level90", "confint", list(object = ref_fit(L1), stdz = c("indirect", "direct"), level = 0.9), "closed_form",
      notes = "K-61, K-92")
  for (a in c("greater", "less")) {
    add(paste0("confint-linear-full-sm-", a), "confint", list(object = ref_fit(L2), stdz = c("indirect", "direct"), alternative = a),
        "closed_form", notes = "K-92, K-94, D-32")
  }
  add("plot-linear-null-mean", "plot", list(x = ref_fit(L1), null = "mean"), "closed_form", notes = "K-60, K-111")
  add("plot-linear-full", "plot", list(x = ref_fit(L2)), "closed_form", notes = "K-111, D-43")
  add("plot-linear-funnel-full", "plot", list(x = ref_fit(LF)), "closed_form", notes = "D-43")
  add("SM_output-linear-parm", "SM_output", list(fit = ref_fit(L1), stdz = c("indirect", "direct"), parm = parm_ids), "closed_form")
  add("test-linear-syn-int", "test", list(fit = ref_fit(LI)), "closed_form", notes = "D-27 expected result")
  add("test-linear-syn-int-parm", "test", list(fit = ref_fit(LI), parm = 1:3), "exact", notes = "D-27")

  # --- random-effect and CRE methods --------------------------------------------------------
  mixed <- list(list(id = R1, tag = "linear-re", logistic = FALSE, heavy = FALSE),
                list(id = G1, tag = "logis-re", logistic = TRUE, heavy = TRUE),
                list(id = C1, tag = "linear-cre", logistic = FALSE, heavy = FALSE),
                list(id = K1, tag = "logis-cre", logistic = TRUE, heavy = TRUE),
                list(id = GX, tag = "logis-re-extreme", logistic = TRUE, heavy = FALSE),
                list(id = KX, tag = "logis-cre-extreme", logistic = TRUE, heavy = FALSE))
  for (mx in mixed) {
    for (a in alts) {
      add(sprintf("test-%s-%s", mx$tag, a), "test", list(fit = ref_fit(mx$id), alternative = a), "lme4", heavy = mx$heavy,
          notes = "K-69, K-70")
    }
    sm_args <- list(fit = ref_fit(mx$id), stdz = c("indirect", "direct"))
    if (mx$logistic) sm_args <- c(sm_args, list(measure = c("ratio", "rate"), threads = 1))
    add(sprintf("SM_output-%s-both", mx$tag), "SM_output", sm_args, "lme4", heavy = mx$heavy, notes = "K-82, K-84")
    add(sprintf("confint-%s-alpha", mx$tag), "confint", list(object = ref_fit(mx$id), option = "alpha"), "lme4", heavy = mx$heavy,
        notes = "K-93")
    add(sprintf("confint-%s-sm", mx$tag), "confint", list(object = ref_fit(mx$id), stdz = c("indirect", "direct")), "lme4",
        heavy = mx$heavy, notes = "K-93, D-21")
    add(sprintf("summary-%s", mx$tag), "summary", list(object = ref_fit(mx$id)), "lme4", heavy = mx$heavy, notes = "K-104, K-105, D-31")
  }
  add("test-linear-re-null", "test", list(fit = ref_fit(R1), null = 0.1, parm = parm_ids), "lme4")
  add("confint-logis-re-extreme-sm-greater", "confint", list(object = ref_fit(GX), stdz = c("indirect", "direct"), alternative = "greater"),
      "lme4", notes = "K-94")
  add("confint-linear-cre-missing-sm", "confint", list(object = ref_fit("linear_cre-missing")), "lme4", notes = "D-13")
  # Phase 5 (R-1): the grid of ARCHITECTURE §G.2 for the RE and CRE methods (one-sided and
  # level = 0.9 intervals, parm, summaries with parm), character IDs, and integer IDs.
  sm_both <- c("indirect", "direct")
  for (mx in mixed[1:4]) {
    alternatives <- if (mx$logistic) "less" else c("greater", "less")
    for (a in alternatives) {
      add(sprintf("confint-%s-sm-%s", mx$tag, a), "confint", list(object = ref_fit(mx$id), stdz = sm_both, alternative = a),
          "lme4", heavy = mx$heavy, notes = "K-93, K-94")
    }
  }
  add("confint-linear-re-alpha-level90", "confint", list(object = ref_fit(R1), option = "alpha", level = 0.9), "lme4", notes = "K-61, K-93")
  add("confint-logis-re-alpha-level90", "confint", list(object = ref_fit(G1), option = "alpha", level = 0.9), "lme4", heavy = TRUE,
      notes = "K-61, K-93")
  add("confint-linear-cre-sm-level90", "confint", list(object = ref_fit(C1), stdz = sm_both, level = 0.9), "lme4", notes = "K-61, K-93")
  add("confint-logis-cre-sm-level90", "confint", list(object = ref_fit(K1), stdz = sm_both, level = 0.9), "lme4", heavy = TRUE,
      notes = "K-61, K-93")
  add("test-logis-re-parm-level90", "test", list(fit = ref_fit(G1), parm = parm_ids, level = 0.9), "lme4", heavy = TRUE)
  add("test-linear-cre-parm-level90", "test", list(fit = ref_fit(C1), parm = parm_ids, level = 0.9), "lme4")
  add("test-logis-cre-parm-level90", "test", list(fit = ref_fit(K1), parm = parm_ids, level = 0.9), "lme4", heavy = TRUE)
  add("SM_output-linear-re-parm", "SM_output", list(fit = ref_fit(R1), stdz = sm_both, parm = parm_ids), "lme4")
  add("SM_output-logis-re-parm", "SM_output",
      list(fit = ref_fit(G1), stdz = sm_both, measure = c("ratio", "rate"), parm = parm_ids, threads = 1), "lme4", heavy = TRUE)
  add("summary-linear-re-parm-level90", "summary", list(object = ref_fit(R1), parm = c("(intercept)", "z1", "z4"), level = 0.9),
      "lme4", notes = "K-104, D-44")
  add("summary-logis-re-parm-level90", "summary", list(object = ref_fit(G1), parm = c("(intercept)", "z2"), level = 0.9),
      "lme4", heavy = TRUE, notes = "K-105, D-31, D-44")
  add("summary-linear-cre-parm-level90", "summary",
      list(object = ref_fit(C1), parm = c("(intercept)", "z1_within", "z2_bar", "z5"), level = 0.9), "lme4", notes = "K-104, D-44")
  add("summary-logis-cre-parm-level90", "summary", list(object = ref_fit(K1), parm = c(1, 4), level = 0.9), "lme4", heavy = TRUE,
      notes = "K-105, D-31")
  add("summary-linear-re-parm-intercept-capital", "summary", list(object = ref_fit(R1), parm = "(Intercept)"), "lme4", notes = "D-44")
  chr_parm <- c("S01", "S05", "S30")
  add("test-linear-re-syn-parm", "test", list(fit = ref_fit("linear_re-syn"), parm = chr_parm), "lme4")
  add("SM_output-linear-re-syn-parm", "SM_output", list(fit = ref_fit("linear_re-syn"), stdz = sm_both, parm = chr_parm), "lme4")
  add("confint-linear-re-syn-sm-parm", "confint", list(object = ref_fit("linear_re-syn"), stdz = sm_both, parm = chr_parm), "lme4")
  add("confint-linear-re-syn-alpha-parm", "confint", list(object = ref_fit("linear_re-syn"), option = "alpha", parm = chr_parm), "lme4")
  add("summary-linear-re-syn", "summary", list(object = ref_fit("linear_re-syn")), "lme4", notes = "K-104")
  add("test-logis-re-extreme-chr", "test", list(fit = ref_fit(GC)), "lme4", notes = "D-34")
  add("SM_output-logis-re-extreme-chr", "SM_output", list(fit = ref_fit(GC), stdz = sm_both, threads = 1), "lme4", notes = "D-34")
  add("confint-logis-re-extreme-chr-sm", "confint", list(object = ref_fit(GC), stdz = sm_both), "lme4", notes = "D-34")
  add("test-logis-cre-extreme-int-parm", "test", list(fit = ref_fit(KI), parm = 1:3), "exact", notes = "D-27")

  # --- caterpillar_plot(), bar_plot(), data_check() ----------------------------------------
  add("caterpillar-binary-ratio", "caterpillar_plot", list(CI = ref_value("confint-binary-sm-wald", "CI.indirect_ratio")), "iterative",
      notes = "K-112")
  add("caterpillar-binary-rate-flags", "caterpillar_plot",
      list(CI = ref_value("confint-binary-sm-wald", "CI.indirect_rate"), use_flag = TRUE, orientation = "horizontal"), "iterative")
  add("caterpillar-linear", "caterpillar_plot", list(CI = ref_value("confint-linear-simplified-sm", "CI.indirect"), use_flag = TRUE),
      "closed_form")
  add("caterpillar-logis-re-extreme", "caterpillar_plot", list(CI = ref_value("confint-logis-re-extreme-sm", "CI.indirect_ratio")),
      "lme4")
  add("caterpillar-gamma", "caterpillar_plot", list(CI = ref_fit("confint-binary-gamma-wald")), "exact")
  add("bar_plot-binary", "bar_plot", list(flag_df = ref_fit("test-binary-exact-two.sided")), "iterative", notes = "K-113")
  add("bar_plot-linear", "bar_plot", list(flag_df = ref_fit("test-linear-simplified-two.sided"), group_num = 3), "closed_form")
  add("data_check-binary", "data_check",
      list(Y = ref_element("binary_example_list", "Y"), Z = ref_element("binary_example_list", "Z"),
           ProvID = ref_element("binary_example_list", "ProvID")), "exact", notes = "K-120")
  add("data_check-missing", "data_check",
      list(Y = ref_element("syn_missing", "Y"), Z = ref_dataset("syn_missing_covariates"), ProvID = ref_element("syn_missing", "ProvID")),
      "exact", notes = "D-17")
  add("data_check-collinear", "data_check",
      list(Y = ref_element("syn_collinear", "Y"), Z = ref_dataset("syn_collinear_covariates"),
           ProvID = ref_element("syn_collinear", "ProvID")), "exact")
  add("data_check-constant", "data_check",
      list(Y = ref_element("syn_constant", "Y"), Z = ref_dataset("syn_constant_covariates"), ProvID = ref_element("syn_constant", "ProvID")),
      "exact")

  # --- Phase 6 (R-2) -------------------------------------------------------------------------
  # caterpillar_plot() on one-sided, direct, CRE, and RE tables, with a given reference line,
  # and a bad orientation; bar_plot() on an RE test and on group counts; RE and CRE fits whose
  # provider variance is 0, where every test flag is missing (M-19), with their methods and
  # both plots.
  add("caterpillar-binary-exact-greater", "caterpillar_plot",
      list(CI = ref_value("confint-binary-sm-exact-greater", "CI.indirect_ratio")), "root", heavy = TRUE,
      notes = "K-112 (upper one-sided)")
  add("caterpillar-binary-exact-less-flags", "caterpillar_plot",
      list(CI = ref_value("confint-binary-sm-exact-less", "CI.direct_rate"), use_flag = TRUE, orientation = "horizontal"),
      "root", heavy = TRUE, notes = "K-112 (lower one-sided), D-47")
  add("caterpillar-linear-greater", "caterpillar_plot",
      list(CI = ref_value("confint-linear-simplified-sm-greater", "CI.indirect"), use_flag = TRUE), "closed_form",
      notes = "K-112 (infinite upper limits)")
  add("caterpillar-binary-direct-rate", "caterpillar_plot", list(CI = ref_value("confint-binary-sm-wald", "CI.direct_rate")),
      "iterative", notes = "K-112 (population rate)")
  add("caterpillar-linear-cre-less", "caterpillar_plot",
      list(CI = ref_value("confint-linear-cre-sm-less", "CI.direct"), use_flag = TRUE), "lme4", notes = "K-112 (CRE linear)")
  add("caterpillar-logis-cre-rate", "caterpillar_plot",
      list(CI = ref_value("confint-logis-cre-sm-less", "CI.indirect_rate"), use_flag = TRUE), "lme4", heavy = TRUE,
      notes = "D-33 (labelled RE logis), D-47")
  add("caterpillar-binary-refline", "caterpillar_plot",
      list(CI = ref_value("confint-binary-sm-wald", "CI.indirect_ratio"), refline_value = 1.1, use_flag = TRUE,
           flag_color = c("#D55E00", "#999999", "#0072B2")), "iterative", notes = "K-112 (given reference)")
  add("caterpillar-bad-orientation", "caterpillar_plot",
      list(CI = ref_value("confint-binary-sm-wald", "CI.indirect_ratio"), orientation = "diagonal"), "exact")
  add("bar_plot-logis-re", "bar_plot", list(flag_df = ref_fit("test-logis-re-two.sided")), "lme4", heavy = TRUE, notes = "K-113")
  add("bar_plot-group-num-1", "bar_plot", list(flag_df = ref_fit("test-binary-exact-two.sided"), group_num = 1), "iterative",
      notes = "K-113")
  add("bar_plot-group-num-60", "bar_plot", list(flag_df = ref_fit("test-binary-exact-two.sided"), group_num = 60), "exact",
      notes = "K-113 (reference error: the quantile breaks are not unique)")
  singular <- list(list(fun = "linear_re", dataset = "syn_singular_linear", logistic = FALSE),
                   list(fun = "linear_cre", dataset = "syn_singular_linear", logistic = FALSE),
                   list(fun = "logis_re", dataset = "syn_singular_binary", logistic = TRUE),
                   list(fun = "logis_cre", dataset = "syn_singular_binary", logistic = TRUE))
  for (sg in singular) {
    id <- paste0(sg$fun, "-singular")
    tag <- paste0(sub("_", "-", sg$fun), "-singular")
    args <- if (endsWith(sg$fun, "cre")) {
      list(data = ref_dataset(sg$dataset), Y.char = "Y", wb.char = "x1", other.char = c("x2", "x3"), ProvID.char = "ProvID")
    } else {
      list(data = ref_dataset(sg$dataset), Y.char = "Y", Z.char = c("x1", "x2", "x3"), ProvID.char = "ProvID")
    }
    add(id, sg$fun, args, "lme4", notes = "M-19 parent (provider variance 0)")
    add(sprintf("test-%s", tag), "test", list(fit = ref_fit(id)), "lme4", notes = "M-19 (every flag missing)")
    sm_args <- list(fit = ref_fit(id), stdz = c("indirect", "direct"))
    if (sg$logistic) sm_args <- c(sm_args, list(measure = c("ratio", "rate"), threads = 1))
    add(sprintf("SM_output-%s", tag), "SM_output", sm_args, "lme4", notes = "M-19")
    add(sprintf("confint-%s-sm", tag), "confint", list(object = ref_fit(id), stdz = c("indirect", "direct")), "lme4",
        notes = "M-19")
  }
  add("bar_plot-singular", "bar_plot", list(flag_df = ref_fit("test-linear-re-singular")), "lme4",
      notes = "K-113, M-19 (missing flags)")
  add("caterpillar-singular", "caterpillar_plot",
      list(CI = ref_value("confint-linear-re-singular-sm", "CI.indirect"), use_flag = TRUE), "lme4",
      notes = "K-112, M-19 (intervals of width 0)")

  # --- full set (validation/) ---------------------------------------------------------------
  for (m in c("SerBIN", "BAN")) for (s in c("or", "beta", "relch", "ratch", "all")) for (bt in c(TRUE, FALSE)) {
    id <- sprintf("logis_fe-binary-grid-%s-%s-%s", tolower(m), s, if (bt) "bt" else "nobt")
    add(id, "logis_fe", c(columns("binary_example", z5), method = m, stop = s, backtrack = bt, tol = 1e-8, threads = 1),
        "iterative", set = "full", notes = "K-14, K-16")
  }
  for (a in alts) {
    add(paste0("test-binary-bootstrap-default-", a), "test", list(fit = ref_fit(F1), test = "exact.bootstrap", alternative = a, threads = 1),
        "iterative", set = "full", seed = 20261004, heavy = TRUE, notes = "K-64, default n = 10000")
  }
  for (tt in c("score", "wald")) for (a in c("greater", "less")) {
    add(sprintf("confint-binary-sm-%s-%s", tt, a), "confint",
        list(object = ref_fit(F1), test = tt, stdz = c("indirect", "direct"), alternative = a), if (tt == "wald") "iterative" else "root",
        set = "full", heavy = TRUE)
  }
  add("logis_fe-medium-default", "logis_fe", c(columns("sim_binary_medium", paste0("x", 1:10)), threads = 1), "iterative",
      set = "full", heavy = TRUE, notes = "D-24")
  add("logis_fe-medium-tight", "logis_fe", c(columns("sim_binary_medium", paste0("x", 1:10)), stop = "beta", tol = 1e-12, threads = 1),
      "iterative", set = "full", heavy = TRUE, notes = "D-24")
  add("test-medium-exact", "test", list(fit = ref_fit("logis_fe-medium-default"), threads = 1), "iterative", set = "full", heavy = TRUE)
  add("SM_output-medium-both", "SM_output", list(fit = ref_fit("logis_fe-medium-default"), stdz = c("indirect", "direct"), threads = 1),
      "iterative", set = "full", heavy = TRUE)
  add("linear_cre-ecls", "linear_cre", list(data = ref_dataset("ecls"), Y.char = "Math_Score", wb.char = "Income",
                                           other.char = "Child_Sex", ProvID.char = "School_ID"), "lme4", set = "full", heavy = TRUE)

  cases
}
