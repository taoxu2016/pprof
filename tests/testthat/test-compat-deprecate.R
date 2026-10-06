# The deprecation warnings of the interface of pprof 1.0.3 (brief §8, DEC-033, DEC-072): each
# exported name of pprof 1.0.3 warns once per session, with class pprof_deprecated and the
# name as its id, naming the function that replaces it; the second call does not warn, and the
# warning changes nothing in the result.
local_strict_mode()

# Providers 1 to 30 of the binary example, for speed. The calls use the old default exact
# test, since the old Wald test warns whenever it is used, as in pprof 1.0.3.
deprecation_binary <- function() {
  data(ExampleDataBinary, package = "pprof", envir = environment())
  data <- data.frame(Y = ExampleDataBinary$Y, ProvID = ExampleDataBinary$ProvID, ExampleDataBinary$Z)
  data[data$ProvID <= 30, ]
}

deprecation_linear <- function() {
  data(ExampleDataLinear, package = "pprof", envir = environment())
  data.frame(Y = ExampleDataLinear$Y, ProvID = ExampleDataLinear$ProvID, ExampleDataLinear$Z)
}

# Binary data small enough for fast glmer() fits.
deprecation_small_binary <- function() {
  withr::local_seed(4)
  n <- 600
  data.frame(Y = stats::rbinom(n, 1, 0.3), ProvID = rep(sprintf("P%02d", 1:30), each = 20),
             x1 = stats::rnorm(n), x2 = stats::rnorm(n))
}

deprecation_fe_fit <- function() {
  logis_fe(data = deprecation_binary(), Y.char = "Y", Z.char = c("z1", "z2"), ProvID.char = "ProvID",
           message = FALSE)
}

# Clears `name`'s entry, calls `call` twice, and restores the entry as the helper set it.
expect_deprecated_once <- function(name, call, value = identity) {
  rm(list = name, envir = deprecation_registry)
  on.exit(assign(name, TRUE, envir = deprecation_registry), add = TRUE)
  first <- NULL
  warning <- expect_warning(first <- call(), class = "pprof_deprecated")
  expect_identical(warning$id, name)
  expect_match(conditionMessage(warning), sprintf("`%s()` is deprecated as of pprof 2.0.0", name), fixed = TRUE)
  expect_match(conditionMessage(warning), sprintf("use `%s` instead", compat_replacements[[name]]), fixed = TRUE)
  expect_match(conditionMessage(warning), "once per session", fixed = TRUE)
  second <- NULL
  expect_no_warning(second <- call(), class = "pprof_deprecated")
  expect_identical(value(second), value(first))
}

test_that("every exported name of pprof 1.0.3 has a replacement and is exported", {
  expect_setequal(names(compat_replacements),
                  c("logis_fe", "logis_firth", "linear_fe", "linear_re", "logis_re", "linear_cre", "logis_cre",
                    "test", "SM_output", "caterpillar_plot", "bar_plot", "data_check"))
  expect_true(all(names(compat_replacements) %in% getNamespaceExports("pprof")))
  replacements <- sub("\\(\\)$", "", compat_replacements)
  expect_true(all(replacements[names(replacements) != "data_check"] %in% getNamespaceExports("pprof")))
})

test_that("the fixed-effect fitting functions warn once per session (DEC-072)", {
  binary <- deprecation_binary()
  expect_deprecated_once("logis_fe", function() {
    logis_fe(data = binary, Y.char = "Y", Z.char = c("z1", "z2"), ProvID.char = "ProvID", message = FALSE)
  }, function(fit) fit$coefficient)
  expect_deprecated_once("logis_firth", function() {
    logis_firth(data = binary, Y.char = "Y", Z.char = c("z1", "z2"), ProvID.char = "ProvID", message = FALSE)
  }, function(fit) fit$coefficient)
  linear <- deprecation_linear()
  expect_deprecated_once("linear_fe", function() {
    suppressMessages(linear_fe(data = linear, Y.char = "Y", Z.char = c("z1", "z2"), ProvID.char = "ProvID"))
  }, function(fit) fit$coefficient)
})

test_that("the random-effect and correlated random-effect fitting functions warn once per session (DEC-072)", {
  linear <- deprecation_linear()
  small <- deprecation_small_binary()
  expect_deprecated_once("linear_re", function() {
    suppressMessages(linear_re(data = linear, Y.char = "Y", Z.char = c("z1", "z2"), ProvID.char = "ProvID"))
  }, function(fit) fit$coefficient)
  expect_deprecated_once("logis_re", function() {
    suppressMessages(logis_re(data = small, Y.char = "Y", Z.char = c("x1", "x2"), ProvID.char = "ProvID"))
  }, function(fit) fit$coefficient)
  expect_deprecated_once("linear_cre", function() {
    linear_cre(data = linear, Y.char = "Y", wb.char = "z1", other.char = "z2", ProvID.char = "ProvID")
  }, function(fit) fit$coefficient)
  expect_deprecated_once("logis_cre", function() {
    logis_cre(data = small, Y.char = "Y", wb.char = "x1", other.char = "x2", ProvID.char = "ProvID")
  }, function(fit) fit$coefficient)
})

test_that("the generics test() and SM_output() warn once per session, whatever the method (DEC-072)", {
  fit <- deprecation_fe_fit()
  expect_deprecated_once("test", function() test(fit))
  expect_deprecated_once("SM_output", function() SM_output(fit))
})

test_that("caterpillar_plot() and bar_plot() warn once per session (DEC-072)", {
  fit <- deprecation_fe_fit()
  intervals <- confint(fit, option = "SM")$CI.indirect_ratio
  expect_deprecated_once("caterpillar_plot", function() caterpillar_plot(intervals), function(plot) plot$data)
  flags <- test(fit)
  expect_deprecated_once("bar_plot", function() bar_plot(flags), function(plot) plot$data)
})

test_that("the methods of base generics for the old classes do not warn (DEC-072)", {
  fit <- deprecation_fe_fit()
  registry <- as.list(deprecation_registry)
  on.exit({
    for (name in names(registry)) assign(name, registry[[name]], envir = deprecation_registry)
  }, add = TRUE)
  rm(list = ls(deprecation_registry), envir = deprecation_registry)
  expect_no_warning(summary(fit), class = "pprof_deprecated")
  expect_no_warning(confint(fit, option = "SM"), class = "pprof_deprecated")
  expect_no_warning(plot(fit), class = "pprof_deprecated")
})
