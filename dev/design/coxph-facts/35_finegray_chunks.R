# CoxPH C5 plan, §2.8: finegray() once per chunk of providers against one call stratified by provider.
# survival 3.8-12's finegray() computes each stratum from that stratum's rows alone, but for one decision
# made over all rows: whether entry is delayed (some subject's first entry later than the smallest exit),
# which brings in the entry distribution in every stratum. So one call per provider can differ from the
# stratified call (31_finegray_inputs.R, part C). Here every chunk decides it as all rows do: when the
# whole data have delayed entry, each chunk also holds the provider of the smallest exit and the provider
# of a subject whose first entry is later; each provider's rows are kept from the chunk that owns it, and
# the chunks' rows are put in provider order, as the stratified call orders them.
# The cases: the counterexample of 31, part C, in chunks of one provider; the two competing-risk fixtures,
# each cause, in chunks of one provider; and the benchmark's data with 33_finegray_cost.R's second cause,
# cause 1, in chunks of 50 providers: rows-1e4, center, and providers-7500 as generated (with delayed
# entry, and weights that are not finite in rows-1e4 and providers-7500), and providers-7500 with every
# entry at 0. identical() compares the outputs, NaN and infinite weights included. One run each.
# Run from the repository root: Rscript dev/design/coxph-facts/35_finegray_chunks.R <output file>
suppressMessages(library(survival))
source(file.path("dev", "bench", "cox", "scenarios.R"))
out <- character()
say <- function(...) {
  out <<- c(out, paste0(...))
  writeLines(out, commandArgs(TRUE)[1])
}
columns <- c(".row", "fgstart", "fgstop", "fgstatus", "fgwt")

# The providers every chunk must also hold so that it decides delayed entry as all rows do: none without
# delayed entry over all rows (no chunk then has it either: each chunk's smallest exit is at least the
# smallest over all rows), and otherwise the provider of the smallest exit and that of the first subject,
# in subject order, whose first entry is later than it.
anchor_providers <- function(d, counting) {
  if (!counting) return(integer())
  order_by_subject <- order(d$id, d$stop)
  first_rows <- order_by_subject[!duplicated(d$id[order_by_subject])]
  late <- first_rows[d$start[first_rows] > min(d$stop)]
  if (length(late) == 0L) return(integer())
  unique(c(d$provider[which.min(d$stop)], d$provider[late[1]]))
}

chunked <- function(d, cause, counting, size) {
  providers <- sort(unique(d$provider))
  anchors <- anchor_providers(d, counting)
  groups <- split(providers, ceiling(seq_along(providers) / size))
  formula <- if (counting) {
    Surv(start, stop, .status) ~ .row + provider + strata(provider)
  } else {
    Surv(stop, .status) ~ .row + provider + strata(provider)
  }
  parts <- lapply(groups, function(own) {
    e <- d[d$provider %in% c(own, anchors), ]
    if (!any(e$.status == cause)) return(NULL)
    fg <- if (counting) {
      finegray(formula, data = e, etype = cause, id = id, timefix = FALSE)
    } else {
      finegray(formula, data = e, etype = cause, timefix = FALSE)
    }
    fg[fg$provider %in% own, c(columns, "provider")]
  })
  result <- do.call(rbind, parts)
  result <- result[order(match(result$provider, providers), method = "radix"), columns]
  rownames(result) <- NULL
  result
}

single <- function(d, cause, counting) {
  formula <- if (counting) Surv(start, stop, .status) ~ .row + strata(provider) else Surv(stop, .status) ~ .row + strata(provider)
  fg <- if (counting) {
    finegray(formula, data = d, etype = cause, id = id, timefix = FALSE)
  } else {
    finegray(formula, data = d, etype = cause, timefix = FALSE)
  }
  fg <- fg[, columns]
  rownames(fg) <- NULL
  fg
}

compare <- function(label, d, cause, counting, size) {
  t1 <- system.time(a <- single(d, cause, counting))
  t2 <- system.time(b <- chunked(d, cause, counting, size))
  say(sprintf("%-42s one call %7.2f s (%6.2f s processor); chunks of %2d providers %6.2f s (%5.2f s processor); identical: %s (%d rows, %d weights not finite)",
              label, t1[["elapsed"]], t1[["user.self"]] + t1[["sys.self"]], size, t2[["elapsed"]],
              t2[["user.self"]] + t2[["sys.self"]], identical(a, b), nrow(a), sum(!is.finite(a$fgwt))))
}

say(sprintf("%s, survival %s", R.version.string, packageVersion("survival")))
e <- data.frame(provider = c(1, 1, 1, 1, 1, 1, 2, 2, 2, 2), .row = 1:10, id = 1:10,
                start = c(0, 10, 5, 0, 0, 2, 0, 0, 4, 0), stop = c(10, 30, 20, 25, 40, 35, 1, 3, 8, 12),
                cause = c(2, 0, 1, 0, 1, 2, 0, 1, 2, 1))
e$.status <- factor(e$cause, levels = 0:2)
compare("31's part C", e, "1", TRUE, 1)
for (path in c("tests/testthat/fixtures/cox/competing-simple.rds", "validation/fixtures/cox/competing-truncated.rds")) {
  fx <- readRDS(path)
  d <- fx$input
  counting <- isTRUE(fx$case$truncated)
  d$start <- if (counting) d$entry else 0
  d$stop <- d$time
  d$provider <- d$stratum
  d$.row <- seq_len(nrow(d))
  d$.status <- factor(d$event, levels = 0:2)
  d <- d[order(d$provider, method = "radix"), ]
  for (cause in c("1", "2")) compare(sprintf("%s, cause %s", fx$case$id, cause), d, cause, counting, 1)
}
grid <- cox_bench_scenarios()
for (run in list(list("rows-1e4", FALSE), list("center", FALSE), list("providers-7500", FALSE),
                 list("providers-7500", TRUE))) {
  s <- grid[grid$id == run[[1]], ]
  d <- cox_bench_data(s$n, s$m, s$p, s$seed)
  if (run[[2]]) d$start <- 0
  d$cause <- ifelse(d$event == 1, ifelse(seq_len(nrow(d)) %% 3 == 0, 2L, 1L), 0L)
  d$.status <- factor(d$cause, levels = 0:2)
  d$.row <- seq_len(nrow(d))
  d$id <- d$.row
  d <- d[order(d$provider, method = "radix"), c("provider", "start", "stop", ".status", ".row", "id")]
  compare(sprintf("%s%s", s$id, if (run[[2]]) ", every entry at 0" else ""), d, "1", !run[[2]], 50)
}
