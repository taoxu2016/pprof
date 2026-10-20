# Logistic extensions facts

The scripts behind the evidence in the logistic extensions phase brief (`dev/logistic_brief.md`, Appendices A and B) and its Phase L0 design (`dev/design/LOGISTIC_DESIGN.md`), with the output each one produced. They run pprofR 0.2.0 (commit `f23c288`) beside pprof and independent references (`glm()`, sandwich, plain-R formulas) on synthetic data, and time them. None of them is part of the package or its tests, and none reads data other than the synthetic data of `facts_data.R` and the bundled `ExampleDataBinary`.

Each numbered script writes the output file of the same name (`.txt`). `facts_data.R` holds what they share: the libraries of 01, the synthetic data (providers, clusters of rows with a shared random intercept, and an optional number of trials per row), and the comparison table.

| Script | Shows | Brief |
|---|---|---|
| `01_libraries.R` | builds pprofR from `git archive f23c288`, pprof from the commit it runs at, and sandwich, each in its own library of the scratch directory, and runs pprofR's own tests (all pass) | Appendix A |
| `02_binary_agreement.R` | pprofR against pprof on binary outcomes, quantity by quantity: the fits (both methods, both stopping rules, two tolerances), variances, likelihood and criteria, AUC, provider tests, intervals, measures and their intervals, covariate tests; bitwise equal but where the conventions of the brief's §3.3 differ | §3.2, §3.3, Appendix A |
| `03_binomial_references.R` | pprofR on binomial outcomes against `glm()` with `cbind(y, n - y)`, and against pprof's binary code on the data expanded into one row per trial; the cost of the exact test over individual trials, against a convolution of the rows' binomial distributions | §3.1, §3.7, Appendix A |
| `04_cluster_inference.R` | pprofR's cluster-robust and "stabilized" tests against `sandwich::vcovCL()` and plain-R versions of their formulas; their dependence on the order of rows within clusters, on a cluster label shared by two providers, and the screening by the number of clusters | §3.2, §3.3, Appendix A |
| `05_direct_standardization.R` | pprofR's direct standardization algorithm against pprof's, for accuracy (against R's long-double sums) and time | §3.3 row 7, Q4, Appendix A |
| `06_stopping_rules.R` | the stopping rules "any" and "coefficients" on binomial outcomes with 1 to 1,000 trials per row, against a tight fit | Q1, Appendix A |
| `07_measure_tests.R` | the delta-method standard error of direct rates against central differences, the rates' denominator, pprofR's test of a measure against its formulas, and direct standardization with provider effects supplied by the caller | §3.2, Appendix A, B4 |
| `08_pprofr_edges.R` | what pprofR does with inputs at the edges of its features: outcomes above their trials, non-integer, zero, negative, or missing trials, no covariates, providers with one cluster, a cluster too large for the stabilized tests | §3.3, Appendix B |
| `09_pprofr_specifications.R` | the behaviors the design specifies that 02 to 08 do not show, against plain-R versions of their definitions: the bootstrap's draws with trials, the binomial score test and Wald standard errors, the robust and stabilized tests of providers with one cluster (a stabilized variance can be negative), the binomial intervals with pprof's root finder, and rows and providers with zero trials (L0) | design §A, D-94, D-95, D-100 |

## Running them

From the repository root, with R (and, for 01, Rtools) on the PATH, commit `f23c288` in the local object store (fetched read-only from the upstream repository's branch that holds it), and `LOGISTIC_FACTS_SCRATCH` set to a directory for the libraries and builds (about 60 MB). On Windows give it with forward slashes (`C:/...`) and keep it short, since the builds' paths count against the 260-character limit.

```sh
f=dev/design/logistic-facts
Rscript $f/01_libraries.R $f/01_libraries.txt      # first: builds the libraries the others load
for s in 02_binary_agreement 03_binomial_references 04_cluster_inference 05_direct_standardization \
         06_stopping_rules 07_measure_tests 08_pprofr_edges 09_pprofr_specifications; do
  Rscript $f/$s.R $f/$s.txt
done
```

01 takes about 5 minutes (two compilations and a download from CRAN), 03 about 5 (its timings of the exact test), 05 about 2, and the others under a minute each. The timings in 03 and 05 come from one Windows machine with other work on it and vary between runs; their ratios are the evidence, and later phases measure again with committed benchmarks in `dev/bench/`.

pprofR's sources are read from the repository's object store (`git archive`), never copied into the working tree: they are not part of this repository, and their documentation is not to be quoted in it (CLAUDE.md).
