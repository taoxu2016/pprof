"""CoxPH brief, §3.7 and Appendix A: pprof_py v0.7.0's CoxPH and its standardized measures on 06's data
sets A and B, timed, and compared with 07_cox_fit_timing.R's survival results; and the time of
pprof_py's mid-p provider test with intervals on data set A (3,000 providers).

The coefficients differ from survival's by about 2e-4 here because coxph() merges near-equal times
by default (timefix = TRUE) and pprof_py does not; 08 shows that this is the whole difference.
Found on 2026-10-07: at 1,000,000 rows and 7,500 providers, CoxPH 9.4 s (Breslow) and 10.1 s
(Efron), the measures 3.4 s; on data set A the mid-p test with intervals 50 s (80 s in an earlier run
with other work running).
Run from the repository root, after 07_cox_fit_timing.R:
    python dev/design/coxph-facts/07_cox_fit_timing.py <output file>
"""
import os
import sys
import time
import warnings

import pprof_py_env as env  # noqa: F401  (must come before pprof_py)

import numpy as np
import numba
import pandas as pd

from pprof_py import CoxPH

out = [f"Python {sys.version.split()[0]}, numpy {np.__version__}, pandas {pd.__version__}, numba {numba.__version__}"]


def arguments(d):
    return dict(start=d["start"].to_numpy(), stop=d["stop"].to_numpy(), event=d["event"].to_numpy(),
                strata=d["provider"].to_numpy(), offset=d["offset"].to_numpy(), sample_weight=d["weight"].to_numpy())


for case in ["a", "b"]:
    d = env.read_csv(os.path.join(env.SCRATCH, f"bench_{case}.csv"))
    xs = [c for c in d.columns if c.startswith("x")]
    X = d[xs].to_numpy()
    kw = arguments(d)
    label = f"{case.upper()} ({len(d)} rows, {d['provider'].nunique()} providers, {len(xs)} covariates)"
    for ties in ["breslow", "efron"]:  # compile the numba kernels outside the timings
        CoxPH(ties=ties).fit(X[:2000], **{k: v[:2000] for k, v in kw.items()})
    for ties in ["breslow", "efron"]:
        times = []
        for _ in range(3):
            t0 = time.perf_counter()
            m = CoxPH(ties=ties).fit(X, **kw)
            times.append(time.perf_counter() - t0)
        rc = env.read_csv(os.path.join(env.SCRATCH, f"bench_{case}_r_coef_{ties}.csv"))
        coef_rel = np.max(np.abs(m.coef_ - rc["coef"].to_numpy()) / np.abs(rc["coef"].to_numpy()))
        se_rel = np.max(np.abs(m.standard_errors_ - rc["se"].to_numpy()) / rc["se"].to_numpy())
        out.append(f"{label} CoxPH {ties:7s} median {np.median(times):.2f} s (runs {', '.join(f'{t:.2f}' for t in times)}), "
                   f"{m.n_iter_} iterations; against coxph(): coefficients {coef_rel:.1e}, SEs {se_rel:.1e} (relative)")
        if ties == "breslow":
            fitted = m
    t0 = time.perf_counter()
    measures = fitted.calculate_standardized_measures(X, start=kw["start"], stop=kw["stop"], event=kw["event"],
                                                      provider_id=kw["strata"], offset=kw["offset"])
    t_measures = time.perf_counter() - t0
    indirect = measures["indirect"]
    re = env.read_csv(os.path.join(env.SCRATCH, f"bench_{case}_r_expected.csv"))
    merged = re.merge(indirect, left_on="provider", right_on="provider_id")
    rel = np.max(np.abs(merged["expected_x"] - merged["expected_y"]) / merged["expected_x"])
    out.append(f"{label} calculate_standardized_measures(): {t_measures:.2f} s; {len(merged)} providers; expected counts "
               f"against the R computation (with survival's coefficients) {rel:.1e} (relative); observed counts equal: "
               f"{bool((merged['observed_x'] == merged['observed_y']).all())}")
    if case == "a":
        t0 = time.perf_counter()
        with warnings.catch_warnings():
            warnings.simplefilter("ignore")
            tests = fitted.test(X, start=kw["start"], stop=kw["stop"], event=kw["event"], provider_id=kw["strata"],
                                offset=kw["offset"])
        out.append(f"{label} test() (mid-p, theoretical null, with intervals): {time.perf_counter() - t0:.1f} s "
                   f"for {len(tests)} providers")
    del d, X, kw, m, fitted
env.write_lines(sys.argv[1], out)
