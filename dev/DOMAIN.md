# Domain primer and references

Terms and sources for provider profiling as pprof implements it. This was §3 and §4 of the rewrite's PROJECT_CONTEXT.

## Glossary

| Term | Meaning in pprof |
|---|---|
| Provider | The unit being profiled: the `provider` argument of the new functions, `ProvID.char` or `ProvID` in those of pprof 1.0.3 |
| Provider effect | Fixed-effect models: γ_i, one estimated parameter per provider. Random-effect models: α_i, a random intercept predicted by `lme4` |
| Risk adjustment | Covariate coefficients β, which describe the patient mix |
| Logistic FE model | logit P(Y_ij = 1) = γ_i + Z_ij'β |
| SerBIN | Serial blockwise inversion Newton: Newton–Raphson updating (γ, β) jointly, using the block structure of the information matrix and its Schur complement |
| BAN | Block ascent Newton: alternates γ updates with β fixed and β updates with γ fixed |
| Firth correction | Penalized likelihood ℓ(θ) + ½ log det I(θ), which reduces small-sample bias and keeps estimates finite |
| Screening | Logistic FE only: providers with fewer than `cutoff` observations are excluded; providers with no events or all events are flagged but kept, and their γ stay finite because each iteration clamps γ to median(γ) ± `bound` |
| Linear FE ("profile" method) | β from the within-provider (demeaned) regression; γ_i = ȳ_i − z̄_i'β |
| CRE | Correlated random effects (Mundlak): chosen covariates are split into provider means (`*_bar`) and within-provider deviations (`*_within`), then fitted with `lme4` |
| Indirect standardization | Compares a provider with what its own patients would experience at a reference ("null") provider. Logistic: ratio O_i/E_i; rate = ratio × population rate in %, clipped to [0, 100] |
| Direct standardization | Applies each provider's effect to the whole population: E_i(direct) / ΣO |
| Standardized difference | Linear models report differences rather than ratios |
| Null (population norm) | Reference provider effect: median of γ̂ by default for FE models; 0 for RE models |
| Flag | 1 = higher than expected, 0 = as expected, −1 = lower than expected |
| Exact Poisson-binomial test | Under the null, a provider's event count given covariates is Poisson-binomial; pprof uses a mid-p version |
| Modified score test | Score test that plugs in the unrestricted β̂ to avoid refitting (default in pprof) |
| Funnel plot | Standardized measure against precision, with control limits |

## Methodological references

| Reference | Underpins |
|---|---|
| Wu W, Yang Y, Kang J, He K (2022). *Statistics in Medicine* 41(15):2840–2853. doi:10.1002/sim.9387 | SerBIN; score and exact tests at scale |
| He K, Kalbfleisch JD, Li Y, Li Y (2013). *Lifetime Data Analysis* 19:490–512 | Fixed provider effects model; BAN |
| He K (2019). *Journal of Hospital Administration* 8(1):9–14 | Indirect and direct standardization |
| Wu W, Kuriakose JP, Weng W, Burney RE, He K (2023). *Health Services and Outcomes Research Methodology* 23(1):45–58 | Test-specific funnel plots |
| Hsiao C (2022). *Analysis of Panel Data*. Cambridge University Press | Linear fixed-effect (profile) estimation |
| Bates D, Mächler M, Bolker B, Walker S (2015). *Journal of Statistical Software* 67(1) | `lme4` engine for RE and CRE models |
| Firth D (1993). *Biometrika* 80(1):27–38 | Bias-reduced likelihood (not cited in the package) |
| Mundlak Y (1978). *Econometrica* 46(1):69–85 | Within–between decomposition behind CRE (not cited in the package) |
