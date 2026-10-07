"""CoxPH brief, §3.3 row 7, B6 and Appendix A: pprof_py v0.7.0's Newton-Raphson against coxph().

1. The seven committed reference fits of pprof_py/r_reference (survival 3.5-8; 02 shows 3.8-12 gives
   the same numbers): iteration counts, coefficients, standard errors and log-likelihoods at default
   settings.
2. Iterates 1 to 6 on two of them, against 12_newton_path.R. pprof_py's path is R's until the last
   step, where pprof_py halves a step that lowers the log-likelihood at rounding level before it
   tests convergence, and R tests convergence first.

Found on 2026-10-07: equal iteration counts at default settings; coefficients within about 1e-14
where the last step was not halved and within 5e-9 where it was; earlier iterates equal to about
1e-14. When the iteration cap stops a right-censored fit (basic_efron, which survival fits with
coxfit6), coxph() reports one iteration more than the cap, though its estimate is the cap-th iterate,
as the agreement with pprof_py's shows; the counting-process fit (combined, agfit4) reports the cap.
Run from the repository root, after 12_newton_path.R: python dev/design/coxph-facts/12_newton_path.py <output file>
"""
import os
import sys
import warnings

import pprof_py_env as env  # noqa: F401  (must come before pprof_py)

import numpy as np

from pprof_py import CoxPH

base = os.path.join(env.PPROF_PY, "pprof_py", "r_reference")
data_dir, results = os.path.join(base, "data"), os.path.join(base, "results")


def data(name):
    return env.read_csv(os.path.join(data_dir, f"{name}.csv"))


basic, combined = data("basic"), data("combined")
cases = [
    ("basic", "breslow", basic[["x1", "x2", "x3"]], dict(duration=basic["time"], event=basic["event"])),
    ("basic_efron", "efron", basic[["x1", "x2", "x3"]], dict(duration=basic["time"], event=basic["event"])),
]
d = data("left_truncation")
cases.append(("left_truncation", "breslow", d[["x1", "x2"]], dict(start=d["start"], stop=d["stop"], event=d["event"])))
d = data("strata")
cases.append(("strata", "breslow", d[["x1", "x2"]], dict(duration=d["stop"], event=d["event"], strata=d["provider"])))
d = data("offset")
cases.append(("offset", "breslow", d[["x1", "x2"]], dict(duration=d["stop"], event=d["event"], offset=d["log_exposure"])))
d = data("weights")
cases.append(("weights", "breslow", d[["x1", "x2"]], dict(duration=d["stop"], event=d["event"], sample_weight=d["weight"])))
combined_args = dict(start=combined["start"], stop=combined["stop"], event=combined["event"], strata=combined["provider"],
                     offset=combined["offset1"], sample_weight=combined["weight"])
cases.append(("combined", "breslow", combined[["x1", "x2", "x3"]], combined_args))

out = ["Reference fits at default settings (pprof_py against coxph()):", "",
       "| Case | Ties | Iterations (pprof_py / R) | Coefficients (max rel) | SEs (max rel) | Log-likelihood (abs) |",
       "|---|---|---|---|---|---|"]
for name, ties, X, kw in cases:
    m = CoxPH(ties=ties).fit(X, **kw)
    rc = env.read_csv(os.path.join(results, f"{name}_coefficients.csv"))
    rm = env.read_csv(os.path.join(results, f"{name}_meta.csv"))
    coef_rel = np.max(np.abs(m.coef_ - rc["coef"].to_numpy()) / np.abs(rc["coef"].to_numpy()))
    se_rel = np.max(np.abs(m.standard_errors_ - rc["se_coef"].to_numpy()) / rc["se_coef"].to_numpy())
    out.append(f"| {name} | {ties} | {m.n_iter_} / {int(rm['n_iter'].iloc[0])} | {coef_rel:.1e} | {se_rel:.1e} | "
               f"{abs(m.log_likelihood_ - rm['loglik_beta'].iloc[0]):.1e} |")

r = env.read_csv(os.path.join(env.SCRATCH, "newton_path_r.csv"))
out += ["", "Iterates from beta = 0 (max relative difference of the coefficients):", "",
        "| Case | Iteration cap | Iterations (pprof_py / R) | pprof_py against R |", "|---|---|---|---|"]
for name, ties, X, kw in [("combined", "breslow", combined[["x1", "x2", "x3"]], combined_args),
                          ("basic_efron", "efron", basic[["x1", "x2", "x3"]], dict(duration=basic["time"], event=basic["event"]))]:
    for k in range(1, 7):
        with warnings.catch_warnings():
            warnings.simplefilter("ignore")
            m = CoxPH(ties=ties, max_iter=k).fit(X, **kw)
        rr = r[(r["case"] == name) & (r["iter_max"] == k)]
        coef = rr["coef"].to_numpy()
        out.append(f"| {name} | {k} | {m.n_iter_} / {int(rr['iter'].iloc[0])} | {np.max(np.abs(m.coef_ - coef) / np.abs(coef)):.1e} |")
env.write_lines(sys.argv[1], out)
