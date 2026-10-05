# Documentation of the bundled data sets, moved from pprof 1.0.3's R/Data.R; the size of
# ExampleDataBinary corrected (D-35). tests/testthat/test-data-bundled.R checks the sizes
# stated here against the data.

#' Example data with binary outcomes
#'
#' A simulated data set containing 7944 observations, 5 continuous covariates and 100 providers.
#' @name ExampleDataBinary
#' @docType data
#' @usage data(ExampleDataBinary)
#'
#' @format A list containing the following elements:
#' \describe{
#'   \item{Y}{a vector representing binary outcomes with 0 or 1.
#'   Generated from a Bernoulli distribution with the probability of success (\eqn{\boldsymbol{\mu}}),
#'   which is determined by applying the logistic function to the linear combination of provider effects
#'   and covariates.}
#'   \item{ProvID}{a vector representing identifier for each provider.
#'   The number of individuals per provider is generated from a
#'   Poisson distribution with mean 80, with a minimum value of 11.}
#'   \item{Z}{a data frame containing 5 continuous variables.
#'   Generated from a multivariate normal distribution, where the mean is calculated as
#'   \eqn{(\gamma_i - \mu_{\gamma}) \cdot \rho / \sigma_{\gamma}} with \eqn{\mu_{\gamma} = \log(4/11)}
#'   and \eqn{\sigma_{\gamma} = 0.4},
#'   and the correlation between covariates and provider effects is 0.1.}
#' }
#'
#' @examples
#' data(ExampleDataBinary)
#' head(ExampleDataBinary$Y)
#' head(ExampleDataBinary$ProvID)
#' head(ExampleDataBinary$Z)
#' # The fitting functions take a data frame with one row per observation.
#' example <- data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID,
#'                       ExampleDataBinary$Z)
#' fit <- fit_logistic_fe(y ~ z1 + z2 + z3 + z4 + z5, example, provider = "hospital")
"ExampleDataBinary"


#' Example data with continuous outcomes
#'
#' A simulated data set containing 7901 observations, 5 continuous covariates and 100 providers.
#' @name ExampleDataLinear
#' @docType data
#' @usage data(ExampleDataLinear)
#'
#' @format A list containing the following elements:
#' \describe{
#'   \item{Y}{a vector representing continuous outcomes.
#'   Generated as a linear combination of provider-specific effects, covariates, and a random error term
#'   (\eqn{\epsilon}),
#'   where \eqn{\epsilon} follows a normal distribution with mean 0 and standard deviation 1.}
#'   \item{ProvID}{a vector representing identifier for each provider.
#'   The number of individuals per provider is generated from a Poisson distribution with mean 80.}
#'   \item{Z}{a data frame containing 5 continuous variables.
#'   Generated from a multivariate normal distribution, where the mean is calculated as
#'   \eqn{(\gamma_i - \mu_{\gamma}) \cdot \rho / \sigma_{\gamma}} with \eqn{\mu_{\gamma} = \log(4/11)}
#'   and \eqn{\sigma_{\gamma} = 0.4},
#'   and the correlation between covariates and provider effects is 0.1.}
#' }
#'
#' @examples
#' data(ExampleDataLinear)
#' head(ExampleDataLinear$Y)
#' head(ExampleDataLinear$ProvID)
#' head(ExampleDataLinear$Z)
#' # The fitting functions take a data frame with one row per observation.
#' example <- data.frame(y = ExampleDataLinear$Y, hospital = ExampleDataLinear$ProvID,
#'                       ExampleDataLinear$Z)
#' fit <- fit_linear_fe(y ~ z1 + z2 + z3 + z4 + z5, example, provider = "hospital")
"ExampleDataLinear"


#' Early Childhood Longitudinal Study Dataset
#' @name ecls_data
#' @docType data
#' @usage data(ecls_data)
#'
#' @description The Early Childhood Longitudinal Study (ECLS) dataset tracks more than 18,000 children
#' from kindergarten through fifth grade, providing comprehensive student-level information.
#' See Tourangeau et al. (2015) for details.
#'
#' @details The dataset includes fifth-grade cross-sectional data, focusing on students' mathematical
#' assessment scores as the primary outcome measure. The mathematical assessment covers 18 topics
#' such as number sense, properties, operations, measurement, geometry, data analysis, and algebra.
#' These items evaluate students' competencies in conceptual knowledge, procedural knowledge, and
#' problem-solving, consolidated into a single "Math score." A higher score indicates greater proficiency.
#' The primary predictors are household income and gender, where gender is a categorical variable.
#' Household income is categorized into 18 ordinal levels, ranging from $5,000 or less (level 1) to
#' $200,000 or more (level 18). In the analysis, the income variable is treated as a continuous variable.
#' The dataset removes all records with missing values and consists of 9,101 complete observations
#' from 2,275 schools.
#'
#' @format A data frame with 9,101 observations, including:
#'   \describe{
#'   \item{Child_ID}{Unique identifier for each child in the dataset.}
#'   \item{School_ID}{Identifier for each school in the dataset.}
#'   \item{Math_Score}{Continuous variable representing the consolidated math proficiency score.}
#'   \item{Income}{Household income, categorized into 18 ordinal levels, from $5,000 or less to
#'   $200,000 or more. Treated as a continuous variable in the analysis.}
#'   \item{Child_Sex}{Binary variable indicating the gender of each student.}
#'   }
#'
#' @source Available at the following website: \url{https://nces.ed.gov/ecls/}.
#'
#' @references
#'
#' Tourangeau, K., Nord, C., Lê, T., Sorongon, A. G., Hagedorn, M. C., Daly, P.,
#' & Najarian, M. (2015). Early Childhood Longitudinal Study, Kindergarten Class of
#' 2010-11 (ECLS-K:2011): User’s manual for the ECLS-K:2011 kindergarten data file
#' and electronic codebook, public version (NCES 2015-074). National Center for
#' Education Statistics.
#' \cr
#'
#' @examples
#' data(ecls_data)
#' fit_fe <- fit_linear_fe(Math_Score ~ Income + Child_Sex, ecls_data, provider = "School_ID")
#' fit_re <- fit_linear_re(Math_Score ~ Income + Child_Sex, ecls_data, provider = "School_ID")
"ecls_data"
