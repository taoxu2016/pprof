# pprof

pprof fits risk-adjusted models with an effect for each health care provider, such as a
hospital, dialysis facility, or transplant center (or another unit, such as a school), and
profiles the providers: it tests whether each provider's outcomes are higher or lower than
expected for its patients, computes indirectly and directly standardized measures with
their intervals, and draws funnel, caterpillar, and other plots of the results.

It handles binary and continuous outcomes with fixed, random, or correlated random
provider effects. For logistic models with many providers, the serial blockwise inversion
Newton algorithm (SerBIN) uses the block structure of the information matrix; linear
fixed-effect models are fitted within providers, without a column for each provider; and
the random-effect models are fitted with lme4.

## Installation

The release on CRAN:

``` r
install.packages("pprof")
```

The development version, with the interface described here, from GitHub:

``` r
remotes::install_github("UM-KevinHe/pprof")
```

## Example

``` r
library(pprof)
data(ExampleDataBinary)
example <- data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID, ExampleDataBinary$Z)

# A logistic model with a fixed effect for each hospital.
fit <- fit_logistic_fe(y ~ z1 + z2 + z3 + z4 + z5, data = example, provider = "hospital")

# Exact tests: hospitals higher (1) or lower (-1) than expected.
tests <- test_providers(fit)
table(tests$table$flag)

# Indirectly standardized ratios and rates with exact intervals.
measures <- standardize_providers(fit, interval = "exact")
head(measures$table)

# A funnel plot.
plot_funnel(funnel_limits(fit))
```

## Learn more

- `vignette("pprof", package = "pprof")`: getting started, a complete analysis.
- `vignette("models", package = "pprof")`: the seven models and what each supports.
- `vignette("statistical-methods", package = "pprof")`: the formulas behind the results.
- `vignette("migration", package = "pprof")`: how code written for pprof 1.0.3 maps to the
  new interface. The functions of pprof 1.0.3 (`logis_fe()`, `test()`, `SM_output()`, and
  the others) still work and give the same results.
- `vignette("adding-a-model", package = "pprof")`: adding a model to pprof.

## Getting help

If you encounter any problems or bugs, please contact us at
[xhliuu\@umich.edu](mailto:xhliuu@umich.edu), [lfluo\@umich.edu](mailto:lfluo@umich.edu),
or [kevinhe\@umich.edu](mailto:kevinhe@umich.edu).

## Contributing

We welcome contributions to the `pprof` package. Please see our
[CONTRIBUTING.md](https://github.com/UM-KevinHe/pprof/blob/main/.github/CONTRIBUTING.md)
file for detailed guidelines of how to contribute.

## References

1. Bates, D., Mächler, M., Bolker, B., & Walker, S. (2015). Fitting linear mixed-effects
   models using lme4. *Journal of Statistical Software*, 67(1), 1-48.
   <https://doi.org/10.18637/jss.v067.i01>
2. He, K., Kalbfleisch, J. D., Li, Y., & Li, Y. (2013). Evaluating hospital readmission
   rates in dialysis facilities; adjusting for hospital effects. *Lifetime Data Analysis*,
   19, 490-512. <https://doi.org/10.1007/s10985-013-9264-6>
3. He, K. (2019). Indirect and direct standardization for evaluating transplant centers.
   *Journal of Hospital Administration*, 8(1), 9-14. <https://doi.org/10.5430/jha.v8n1p9>
4. Hsiao, C. (2022). *Analysis of Panel Data* (No. 64). Cambridge University Press.
5. Wu, W., Kuriakose, J. P., Weng, W., Burney, R. E., & He, K. (2023). Test-specific funnel
   plots for healthcare provider profiling leveraging individual- and summary-level
   information. *Health Services and Outcomes Research Methodology*, 23(1), 45-58.
   <https://doi.org/10.1007/s10742-022-00285-9>
6. Wu, W., Yang, Y., Kang, J., & He, K. (2022). Improving large-scale estimation and
   inference for profiling health care providers. *Statistics in Medicine*, 41(15),
   2840-2853. <https://doi.org/10.1002/sim.9387>
