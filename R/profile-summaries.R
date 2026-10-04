# Summaries of profiling results that plots draw (DEC-056): the reference value a measure is
# compared with and the flags of intervals against it (K-112), and the shares of flags by
# provider-size group (K-113). The new plot functions and the compatibility wrappers of
# pprof 1.0.3's plots both use them, so each rule is written once.

# K-112: the value a standardized measure is compared with: 1 for ratios, the population rate
# for rates, and 0 for differences. NULL for a rate without a population rate.
profile_reference_value <- function(measure, population_rate = NULL) {
  switch(measure, ratio = 1, rate = population_rate, difference = 0,
         abort_invalid_input(sprintf("No reference value for the measure \"%s\".", measure), arg = "measure"))
}

# K-112: the flag of each interval against the reference value, with the comparisons of
# pprof 1.0.3's caterpillar_plot() in its order: for two-sided intervals -1 when the upper
# limit is below the reference, else 1 when the lower limit is above it, else 0; a one-sided
# interval is flagged on its side only (`greater`: 1 or 0 from the lower limit; `less`: -1 or
# 0 from the upper limit). A missing limit that decides the flag gives a missing flag.
profile_interval_flags <- function(lower, upper, reference, alternative = "two.sided") {
  switch(alternative,
         two.sided = ifelse(upper < reference, -1L, ifelse(lower > reference, 1L, 0L)),
         greater = ifelse(lower > reference, 1L, 0L),
         less = ifelse(upper < reference, -1L, 0L),
         abort_invalid_input("`alternative` must be one of \"two.sided\", \"greater\", \"less\".", arg = "alternative"))
}

# K-113: providers grouped at the quantiles of their sizes,
# cut(n_obs, quantile(n_obs, (0:g) / g), include.lowest = TRUE), labelled Q1 to Qg, as
# pprof 1.0.3's bar_plot() groups them. Sizes whose quantiles coincide cannot be split.
profile_size_groups <- function(n_obs, group_count) {
  breaks <- stats::quantile(n_obs, probs = (0:group_count) / group_count, na.rm = TRUE, names = FALSE)
  if (anyDuplicated(breaks) > 0L) {
    abort_invalid_input(sprintf("The provider sizes do not split into %d groups; use a smaller `group_count`.",
                                group_count), arg = "group_count")
  }
  cut(n_obs, breaks = breaks, include.lowest = TRUE, labels = paste0("Q", seq_len(group_count)))
}

# K-113: the providers of each size group and of all groups ("Overall") by flag, as
# bar_plot() counts them: one row per group and category that occurs, in the order of the
# groups and of the categories (higher, as expected, lower, then a missing flag), with the
# number of providers (`count`) and their share of the group (`share`). Providers without a
# flag stay, with a missing category.
profile_flag_shares <- function(flag, n_obs, group_count) {
  groups <- c(paste0("Q", seq_len(group_count)), "Overall")
  group <- profile_size_groups(n_obs, group_count)
  category <- factor(flag, levels = c(1L, 0L, -1L), labels = c("higher", "as expected", "lower"))
  group <- factor(c(as.character(group), rep("Overall", length(flag))), levels = groups)
  category <- c(category, category)
  counts <- as.data.frame(table(group = group, category = category, useNA = "ifany"), responseName = "count",
                          stringsAsFactors = FALSE)
  counts <- counts[counts$count > 0L, , drop = FALSE]
  counts$group <- factor(counts$group, levels = groups)
  counts$category <- factor(counts$category, levels = levels(category))
  counts <- counts[order(counts$group, counts$category), , drop = FALSE]
  counts$count <- as.integer(counts$count)
  counts$share <- counts$count / stats::ave(counts$count, counts$group, FUN = sum)
  rownames(counts) <- NULL
  counts
}
