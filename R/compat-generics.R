# The generics of pprof 1.0.3's methods (R/test.R and R/SM_output.R in pprof 1.0.3),
# unchanged: the entry points of the old test() and SM_output() methods, kept as long as the
# compatibility methods are (ARCHITECTURE §I.3, DEC-045). The new interface is
# test_providers() and standardize_providers().

#' Generic function for hypothesis testing of provider effects
#'
#' `test` is an S3 generic function used to conduct hypothesis tests on provider effect coefficients
#' and detect outlying provider. The function dispatches to the appropriate method
#' based on the class of the input model (`fit`). This is the interface of pprof 1.0.3, kept for
#' existing code; [test_providers()] is the new interface.
#'
#' @param fit the input object, typically a fitted model, for which provider
#' effects are tested. The method applied depends on the class of this object.
#' @param ... additional arguments that can be passed to specific methods.
#'
#' @return the return depends on the method implemented for the
#' class of the input object, typically including statistical outputs for
#' provider effect coefficients and identification of outlier providers.
#'
#' @export
test <- function(fit, ...) {
  UseMethod("test")
}

#' Generic function for calculating standardized measures
#'
#' `SM_output` is an S3 generic function designed to calculate standardized
#' measures. It dispatches to the appropriate method based on the class of the
#' input (`fit`), ensuring the correct method is applied for different types of models. This is
#' the interface of pprof 1.0.3, kept for existing code; [standardize_providers()] is the new
#' interface.
#'
#' @param fit the input object, typically a fitted model, for which standardized measures
#' are calculated. The method applied depends on the class of this object.
#' @param ... additional arguments that can be passed to specific methods.
#'
#' @return the return varies depending on the method implemented for the
#' class of the input object.
#'
#' @export
SM_output <- function(fit, ...) { # nolint: object_name_linter.
  UseMethod("SM_output")
}
