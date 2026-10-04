# Phase 5 planning: does the reference's linear funnel agree with its flags?
# The limits use sigma / sqrt(n_i) (the simplified variance, normal quantiles) whatever
# option.gamma.var says, while the flags come from test.linear_fe(), which uses the full
# variance and t(n - m - p) for option.gamma.var = "full" (K-68, K-111).
args <- commandArgs(trailingOnly = TRUE)
out_file <- args[1]
.libPaths(c("dev/reference/lib", .Library))
Sys.setlocale("LC_COLLATE", "C")
suppressPackageStartupMessages(library(pprof))
lines <- character()
say <- function(...) lines <<- c(lines, paste0(...))
data(ExampleDataLinear)
lin <- data.frame(Y = ExampleDataLinear$Y, ProvID = ExampleDataLinear$ProvID, ExampleDataLinear$Z)
z <- paste0("z", 1:5)
check <- function(data, label) {
  for (option in c("simplified", "full")) {
    fit <- suppressMessages(linear_fe(data = data, Y.char = "Y", Z.char = z, ProvID.char = "ProvID",
                                      option.gamma.var = option))
    pl <- suppressMessages(suppressWarnings(plot(fit)))
    points <- pl$layers[[1]]$data
    points <- points[!is.na(points$precision), ]
    outside <- points$indicator > points$upper | points$indicator < points$lower
    flagged <- points$flag != "0"
    say(sprintf("%s, %s: %d providers; outside the 95%% limits %d, flagged %d, disagree %d", label, option,
                nrow(points), sum(outside), sum(flagged), sum(outside != flagged)))
  }
}
check(lin, "ExampleDataLinear")
# Small providers, where the full variance and t differ more from sigma^2 / n_i and the normal.
set.seed(20261004)
m <- 40
sizes <- sample(3:8, m, replace = TRUE)
id <- rep(seq_len(m), sizes)
zz <- matrix(rnorm(length(id) * 5), ncol = 5, dimnames = list(NULL, z))
shift <- rnorm(m * 5, 0, 4)[seq_len(m)]  # one shift per provider, added to every covariate
zz <- zz + shift[id]
small <- data.frame(Y = rnorm(m, 0, 1.2)[id] + drop(zz %*% c(1, -0.5, 0.3, 0, 0.2)) + rnorm(length(id)),
                    ProvID = id, zz)
check(small, "simulated, 40 providers of 3 to 8, provider-level covariate shifts (seed 20261004)")
writeLines(lines, out_file)
