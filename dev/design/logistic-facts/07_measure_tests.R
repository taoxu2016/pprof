# Logistic extensions brief, Appendix A: the standard errors of direct rates and the test of a
# standardized measure in pprofR 0.2.0, checked against their definitions:
#   (a) the delta-method standard error of a direct rate, numer_se / N_pop * se(gamma_i), against
#       the derivative of the direct rate with respect to the provider's effect by central
#       differences, and the effect of the denominator N_pop;
#   (b) test_SM(), the z-test of a measure against a reference value on the identity or logit
#       scale with a null distribution N(location, scale^2): its statistic, p-value, and flag
#       against their formulas, and whether its interval excludes the reference exactly when the
#       flag is not 0;
#   (c) direct standardization with provider effects supplied by the caller (a longer vector of
#       effects in place of the fit's), and what indirect standardization does with them.
# Run from the repository root after 01: Rscript dev/design/logistic-facts/07_measure_tests.R <output file>
source("dev/design/logistic-facts/facts_data.R")
args <- commandArgs(trailingOnly = TRUE)
facts_use_libraries()
suppressPackageStartupMessages(library(pprofR))
out <- c("# 07: standard errors of direct rates, and the test of a measure", "",
         sprintf("pprofR %s, %s.", utils::packageVersion("pprofR"), R.version.string), "")

d <- facts_simulate(m = 40, trials = c(1, 12), seed = 9)
fit <- pprofR::logis_fe(facts_pprofr_prep(d, binomial = TRUE, cutoff = 1), tol = 1e-10, stop = "beta")
sr <- pprofR::SR_output(fit, stdz = "direct", measure = c("ratio", "rate"))
gamma <- as.numeric(fit$gamma)
eta <- as.numeric(fit$linear_pred)
n_trials <- fit$data_include$N
rate_at <- function(g) sum(n_trials * stats::plogis(g + eta)) / sum(n_trials)
h <- 1e-5
derivative <- vapply(gamma, function(g) (rate_at(g + h) - rate_at(g - h)) / (2 * h), numeric(1))
out <- c(out, facts_header("## (a) The delta-method standard error of direct rates"),
         facts_row("numer_se / N_pop against the central difference of the direct rate (h = 1e-5)",
                   sr$numer_se / sr$N_pop, derivative),
         facts_row("the direct rate against sum(N p(gamma_i)) / sum(N)", sr$direct.rate, vapply(gamma, rate_at, numeric(1))))
half <- pprofR::SR_output(fit, stdz = "direct", measure = "rate", N_pop = 2 * sum(n_trials))
out <- c(out, facts_row("N_pop doubled: the rate halves", half$direct.rate, sr$direct.rate / 2),
         facts_row("N_pop doubled: numer_se is unchanged", half$numer_se, sr$numer_se), "")

# (b) test_SM() on the direct rates with the robust standard errors of the effects.
se_rate <- as.numeric(sr$numer_se / sr$N_pop) *
  pprofR::test_fe(fit, test = "robust_wald", null = 0)$se.gamma
measure <- as.numeric(sr$direct.rate)
reference <- sum(fit$obs) / sum(n_trials)
out <- c(out, facts_header("## (b) test_SM() against its formulas"))
for (transform in c("identity", "logit")) for (null in list(c(0, 1), c(0.3, 1.5))) {
  r <- pprofR::test_SM(measure, se_rate, reference, transform = transform, location = null[1], scale = null[2])
  g <- if (identical(transform, "logit")) stats::qlogis else identity
  slope <- if (identical(transform, "logit")) 1 / (measure * (1 - measure)) else 1
  z <- (g(measure) - g(reference)) / (slope * se_rate)
  prob <- stats::pnorm(z, null[1], null[2])
  crit <- stats::qnorm(0.975)
  flag <- ifelse((z - null[1]) / null[2] > crit, 1, ifelse((z - null[1]) / null[2] < -crit, -1, 0))
  excludes <- r$lower > reference | r$upper < reference
  label <- sprintf("%s, null N(%g, %g^2)", transform, null[1], null[2])
  out <- c(out, facts_row(paste(label, "statistic"), r$z, z), facts_row(paste(label, "p-value"), r$p, 2 * pmin(prob, 1 - prob)),
           sprintf("| %s: flags differing from the formula; flags not 0 | %d; %d | | |", label, sum(r$flag != flag),
                   sum(r$flag != 0)),
           sprintf("| %s: providers whose interval excludes the reference but are not flagged, and the reverse | %d, %d | | |",
                   label, sum(excludes & r$flag == 0), sum(!excludes & r$flag != 0)))
}
out <- c(out, "")

# (c) Provider effects supplied by the caller: the fit's effects and two more providers.
extended <- fit
extended$gamma <- rbind(fit$gamma, matrix(c(2, 2.5), dimnames = list(c("extra-1", "extra-2"), "gamma")))
direct_extended <- tryCatch(pprofR::SR_output(extended, stdz = "direct", measure = "rate")$direct.rate,
                            error = function(e) conditionMessage(e))
indirect_extended <- tryCatch(dim(pprofR::SR_output(extended, stdz = "indirect", measure = "ratio")$indirect.ratio),
                              error = function(e) conditionMessage(e))
out <- c(out, "## (c) Provider effects supplied by the caller", "",
         sprintf("- direct, with the fit's %d effects and 2 more: %s rates; the fit's providers' rates unchanged: %s",
                 length(gamma), if (is.character(direct_extended)) direct_extended else length(direct_extended),
                 if (is.character(direct_extended)) "-" else identical(direct_extended[seq_along(gamma)], as.numeric(sr$direct.rate))),
         sprintf("- indirect, with the same effects: %s",
                 if (is.character(indirect_extended)) paste("error:", indirect_extended) else paste(indirect_extended, collapse = " x ")),
         sprintf("- the median of the effects, the indirect null, moves from %.6f to %.6f", stats::median(gamma),
                 stats::median(as.numeric(extended$gamma))))
writeLines(out, args[1])
