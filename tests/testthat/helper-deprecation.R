# The interface of pprof 1.0.3 warns once per session that it is deprecated (DEC-072). The
# tests mark every warning as given before they run, so that strict mode (DEC-030) and the tests
# of the old interface see none; test-compat-deprecate.R checks each warning with its entry
# cleared.
for (deprecated_name in names(compat_replacements)) {
  assign(deprecated_name, TRUE, envir = deprecation_registry)
}
rm(deprecated_name)
