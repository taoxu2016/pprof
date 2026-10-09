"""CoxPH Phase C3 plan: pprof_py v0.7.0's own funnel limits for the Cox model, CoxPH.funnel_limits()
(models/survival/coxph.py through inference/survival/provider_tests.py:142-172 and
inference/funnel.py:poisson_funnel_limits), which the C0 design did not record (M-39 assumed pprof_py
had none).

For two Cox fixture cases, rc-stratified (core set) and provider-scale (full set), with their inputs
rebuilt by the fixture generator's cases.py, and both tie methods: the tight fit as the generator makes
it, then funnel_limits() with the mid-p and the exact test at level 0.95 and the curve levels 0.95 and
0.998. Writes, to COXPH_FACTS_SCRATCH, one CSV of the providers (observed, expected, estimate,
precision, lower, upper, flag) and one of the curves per case, tie method, and test; 23_funnel_limits.R
compares them with the package's options and writes the output.
Run from the repository root, with COXPH_FACTS_SCRATCH set: python dev/design/coxph-facts/23_funnel_limits.py
"""
import os
import sys
import warnings

import pprof_py_env as env  # noqa: F401  (must come before pprof_py)

import numpy as np

from pprof_py.models.survival.coxph import CoxPH

sys.path.insert(0, os.path.join("dev", "reference", "cox"))
import cases as case_table  # noqa: E402

TIGHT = {"max_iter": 100, "eps": 1e-11}
for case_id in ("rc-stratified", "provider-scale"):
    case = next(c for c in case_table.CASES if c["id"] == case_id)
    df = case_table.load(case)
    X = df[case_table.features(case, df)].to_numpy(dtype=float)
    times = ({"start": df["entry"].to_numpy(dtype=float), "stop": df["time"].to_numpy(dtype=float)}
             if case["truncated"] else {"duration": df["time"].to_numpy(dtype=float)})
    event = df["event"].to_numpy()
    provider = df["stratum"].to_numpy()
    for ties in ("breslow", "efron"):
        with warnings.catch_warnings():
            warnings.simplefilter("ignore")
            model = CoxPH(ties=ties, **TIGHT).fit(X, event=event, strata=provider, **times)
            for test in ("midp", "exact"):
                limits = model.funnel_limits(X, event=event, provider_id=provider, test_method=test, level=0.95,
                                             levels=[0.95, 0.998], **times)
                stem = os.path.join(env.SCRATCH, f"23_{case_id}_{ties}_{test}")
                providers = limits.providers.copy()
                providers.insert(0, "provider", providers.index.to_numpy())
                providers["flag"] = providers["flag"].astype("float")
                providers.to_csv(stem + "_providers.csv", index=False, float_format="%.17g")
                limits.curves.to_csv(stem + "_curves.csv", index=False, float_format="%.17g")
                print(case_id, ties, test, len(providers), "providers;", len(limits.curves), "curve points;",
                      dict(limits.attrs)["limit_rule"])
