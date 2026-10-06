# Deprecation of the interface of pprof 1.0.3 (brief §8, DEC-033, DEC-072): each exported name
# of pprof 1.0.3 warns once per session, with class pprof_deprecated, before it computes
# anything, naming the function that replaces it. The methods of base generics for the old
# classes (confint(), summary(), plot(), print()) do not warn: their objects come from an old
# fitting function, which has warned, and those generics are not deprecated.

# The old exported names and what replaces each (ARCHITECTURE §I.1).
compat_replacements <- c(
  logis_fe = "fit_logistic_fe()",
  logis_firth = "fit_logistic_firth()",
  linear_fe = "fit_linear_fe()",
  linear_re = "fit_linear_re()",
  logis_re = "fit_logistic_re()",
  linear_cre = "fit_linear_cre()",
  logis_cre = "fit_logistic_cre()",
  test = "test_providers()",
  SM_output = "standardize_providers()",
  caterpillar_plot = "plot_caterpillar()",
  bar_plot = "plot_flags()",
  data_check = "check_data()"
)

compat_deprecate <- function(name) {
  warn_deprecated(name, sprintf(paste0(
    "`%s()` is deprecated as of pprof 2.0.0; use `%s` instead (see vignette(\"migration\", ",
    "package = \"pprof\")). This warning is shown once per session."
  ), name, compat_replacements[[name]]))
}
