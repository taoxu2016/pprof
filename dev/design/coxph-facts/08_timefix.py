"""CoxPH brief, §3.3 row 2, Q1 and Appendix A: pprof_py v0.7.0 against coxph() with timefix = TRUE and
FALSE on 06's data set A, at default and tight convergence and iterate by iterate (R side: 08_timefix.R).

pprof_py compares times exactly. With timefix = FALSE it agrees with survival to about 1e-15 (Breslow)
and 1e-12 (Efron); with coxph()'s default timefix = TRUE the two differ by about 2e-4 from the first
Newton iterate on, because aeqSurv() merges times that differ only in the last bits.
Run from the repository root, after 08_timefix.R: python dev/design/coxph-facts/08_timefix.py <output file>
"""
import os
import sys
import warnings

import pprof_py_env as env  # noqa: F401  (must come before pprof_py)

import numpy as np

from pprof_py import CoxPH

d = env.read_csv(os.path.join(env.SCRATCH, "bench_a.csv"))
r = env.read_csv(os.path.join(env.SCRATCH, "timefix_r.csv"))
with open(os.path.join(env.SCRATCH, "timefix_meta.txt"), encoding="utf-8") as handle:
    out = [line.rstrip("\n") for line in handle]
xs = [c for c in d.columns if c.startswith("x")]
X = d[xs].to_numpy()
kw = dict(start=d["start"].to_numpy(), stop=d["stop"].to_numpy(), event=d["event"].to_numpy(),
          strata=d["provider"].to_numpy(), offset=d["offset"].to_numpy(), sample_weight=d["weight"].to_numpy())


def r_coef(ties, timefix, control):
    rows = r[(r["ties"] == ties) & (r["timefix"] == timefix) & (r["control"] == control)]
    return rows["coef"].to_numpy(), int(rows["iter"].iloc[0])


def rel(a, b):
    return float(np.max(np.abs(np.asarray(a) - b) / np.abs(b)))


out += ["", "Maximum relative difference in the coefficients, pprof_py against coxph():", "",
        "| Ties | Fit | Iterations (pprof_py / R) | R, timefix = TRUE | R, timefix = FALSE |", "|---|---|---|---|---|"]
for ties in ["breslow", "efron"]:
    fits = [("default", {}), ("tight", dict(eps=1e-14, max_iter=100))]
    fits += [(f"iterate{k}", dict(eps=1e-300, max_iter=k)) for k in range(1, 5)]
    for control, options in fits:
        with warnings.catch_warnings():
            warnings.simplefilter("ignore")
            m = CoxPH(ties=ties, **options).fit(X, **kw)
        on, iter_on = r_coef(ties, True, control)
        off, iter_off = r_coef(ties, False, control)
        out.append(f"| {ties} | {control} | {m.n_iter_} / {iter_off} | {rel(m.coef_, on):.1e} | {rel(m.coef_, off):.1e} |")
    default_on, _ = r_coef(ties, True, "default")
    tight_on, _ = r_coef(ties, True, "tight")
    out.append(f"| {ties} | R default against R tight (timefix = TRUE) | | {rel(default_on, tight_on):.1e} | |")
env.write_lines(sys.argv[1], out)
