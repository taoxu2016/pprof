# Live comparison of the new API with the reference's methods of linear FE, RE, and CRE fits
# while both are in the package (Phase 5 plan, step 2): the old methods run on the Phase 4
# wrappers' objects, which hold the estimates of the new fits, so the new API on the new fits
# of the same data must reproduce them bitwise. Cases: every method fixture of the five
# families, and a grid of settings on seeded random datasets with numeric and character IDs.
#
# Temporary: removed with the old method files at the switch (Phase 5, step 3), after which
# the wrappers are compared with the fixtures.
local_strict_mode()

legacy_cache <- new.env(parent = emptyenv())

# Runs a case through the old code with the case runner, its parent fit first.
legacy_old_result <- function(case, parent_case, datasets) {
  key <- paste0("old_", parent_case$id)
  if (is.null(legacy_cache[[key]])) legacy_cache[[key]] <- run_reference_case(parent_case, datasets, list())
  run_reference_case(case, datasets, stats::setNames(list(legacy_cache[[key]]), parent_case$id))
}

# The new fit of a parent case on `datasets`.
legacy_new_fit <- function(parent_case, datasets) {
  key <- paste0("new_", parent_case$id)
  if (is.null(legacy_cache[[key]])) {
    args <- model_new_arguments(parent_case, datasets)
    legacy_cache[[key]] <- withr::with_collate("C", suppressMessages(suppressWarnings(
      do.call(model_new_fit_functions[[parent_case$fun]], args)
    )))
  }
  legacy_cache[[key]]
}

expect_legacy_case <- function(case, parent_case, datasets) {
  old <- withr::with_collate("C", legacy_old_result(case, parent_case, datasets))
  expect_identical(old$outcome, "value")
  fit <- legacy_new_fit(parent_case, datasets)
  result <- family_case_run(case, fit, parent_case$fun)
  expect_family_case(case, result, reference_fixture_value(old$raw_value, 5000L), "exact", parent_case$fun)
}

for (id in family_case_ids()) {
  local({
    case_id <- id
    test_that(paste("the new API equals the old method bitwise:", case_id), {
      skip_on_cran()
      case <- reference_fixture(case_id)$case
      parent_case <- reference_fixture(profile_case_parent_id(case))$case
      if (identical(case_id, "summary-linear-re-parm-intercept-capital")) skip("wrapper-only case (D-44)")
      datasets <- reference_datasets_for(parent_case, "core")
      expect_legacy_case(case, parent_case, datasets)
    })
  })
}

# Seeded datasets: linear outcomes with providers of 1 to 40 observations, and binary
# outcomes with a provider without events; numeric and character IDs whose C-locale order
# differs from their numeric order.
legacy_ids <- function(m) paste0(rep(c("a", "B", "c", "D"), length.out = m), sprintf("%02d", m:1))

legacy_linear_data <- function(seed, character_ids = FALSE) {
  withr::with_seed(seed, {
    m <- 30
    sizes <- sample(c(1, 2, 5:40), m, replace = TRUE)
    provider <- rep(seq_len(m), sizes)
    n <- length(provider)
    z <- matrix(stats::rnorm(n * 3), ncol = 3, dimnames = list(NULL, paste0("x", 1:3)))
    y <- stats::rnorm(m, 0, 1)[provider] + drop(z %*% c(0.5, -0.3, 0.2)) + stats::rnorm(n)
    data.frame(Y = y, ProvID = if (character_ids) legacy_ids(m)[provider] else as.numeric(provider), z)
  })
}

legacy_binary_data <- function(seed, character_ids = FALSE) {
  withr::with_seed(seed, {
    m <- 30
    sizes <- sample(20:60, m, replace = TRUE)
    provider <- rep(seq_len(m), sizes)
    n <- length(provider)
    z <- matrix(stats::rnorm(n * 3), ncol = 3, dimnames = list(NULL, paste0("x", 1:3)))
    y <- stats::rbinom(n, 1, stats::plogis(-0.7 + stats::rnorm(m, 0, 0.6)[provider] + drop(z %*% c(0.5, -0.3, 0.2))))
    y[provider == 1] <- 0L
    data.frame(Y = y, ProvID = if (character_ids) legacy_ids(m)[provider] else as.numeric(provider), z)
  })
}

legacy_datasets <- function() {
  if (is.null(legacy_cache$datasets)) {
    legacy_cache$datasets <- list(lin_a = legacy_linear_data(20261006), lin_b = legacy_linear_data(20261007),
                                  lin_chr = legacy_linear_data(20261008, TRUE), bin_a = legacy_binary_data(20261009),
                                  bin_chr = legacy_binary_data(20261010, TRUE))
  }
  legacy_cache$datasets
}

legacy_case <- function(id, fun, args) list(id = id, fun = fun, args = args, seed = NULL, tier = "exact")

legacy_grid <- function() {
  fits <- list()
  methods <- new.env(parent = emptyenv())
  covariates <- c("x1", "x2", "x3")
  for (name in names(legacy_datasets())) {
    character_ids <- grepl("chr", name)
    parm <- if (character_ids) legacy_ids(30)[c(1, 4, 30)] else c(1, 4, 30, 99)
    columns <- list(data = ref_dataset(name), Y.char = "Y", Z.char = covariates, ProvID.char = "ProvID")
    cre <- list(data = ref_dataset(name), Y.char = "Y", wb.char = "x1", other.char = c("x2", "x3"),
                ProvID.char = "ProvID")
    parents <- if (startsWith(name, "lin")) {
      list(legacy_case(paste0(name, "-fe"), "linear_fe", columns),
           legacy_case(paste0(name, "-fe-full"), "linear_fe", c(columns, list(option.gamma.var = "full"))),
           legacy_case(paste0(name, "-re"), "linear_re", columns),
           legacy_case(paste0(name, "-cre"), "linear_cre", cre))
    } else {
      list(legacy_case(paste0(name, "-re"), "logis_re", columns), legacy_case(paste0(name, "-cre"), "logis_cre", cre))
    }
    for (parent in parents) {
      fits[[parent$id]] <- parent
      fixed <- identical(parent$fun, "linear_fe")
      logistic <- parent$fun %in% c("logis_re", "logis_cre")
      nulls <- if (fixed) list("median", "mean", 0.1) else list(0, 0.1)
      add <- function(tag, fun, args) {
        methods[[paste(parent$id, tag)]] <- list(parent = parent$id,
                                                 case = legacy_case(paste(parent$id, tag), fun, args))
      }
      fit <- ref_fit(parent$id)
      for (a in c("two.sided", "greater", "less")) {
        add(paste("test", a), "test", list(fit = fit, alternative = a, level = 0.9))
        add(paste("confint sm", a), "confint", list(object = fit, stdz = c("indirect", "direct"), alternative = a))
      }
      for (k in seq_along(nulls)) {
        add(paste("test null", k), "test", list(fit = fit, null = nulls[[k]], parm = parm))
        if (fixed) {
          add(paste("sm null", k), "SM_output", list(fit = fit, stdz = c("indirect", "direct"), null = nulls[[k]]))
          add(paste("confint null", k), "confint",
              list(object = fit, stdz = c("indirect", "direct"), null = nulls[[k]], level = 0.9))
          add(paste("plot null", k), "plot", list(x = fit, null = nulls[[k]], alpha = c(0.05, 0.01)))
        }
      }
      sm <- list(fit = fit, stdz = c("indirect", "direct"), parm = parm)
      if (logistic) sm <- c(sm, list(measure = c("ratio", "rate"), threads = 1))
      add("sm parm", "SM_output", sm)
      add("confint effects", "confint", list(object = fit, option = if (fixed) "gamma" else "alpha", level = 0.9,
                                             parm = parm))
      add("confint sm parm", "confint", list(object = fit, stdz = c("indirect", "direct"), parm = parm))
      add("summary", "summary", list(object = fit, level = 0.9))
      add("summary parm", "summary", list(object = fit, parm = if (fixed) c("x3", "x1") else c("(intercept)", "x2")))
      add("summary positions", "summary", list(object = fit, parm = c(2, 1)))
    }
  }
  list(fits = fits, methods = mget(sort(ls(methods)), envir = methods))
}

grid <- legacy_grid()
for (label in names(grid$methods)) {
  local({
    entry <- grid$methods[[label]]
    test_that(paste("the new API equals the old method bitwise on seeded data:", label), {
      skip_on_cran()
      expect_legacy_case(entry$case, grid$fits[[entry$parent]], legacy_datasets())
    })
  })
}
