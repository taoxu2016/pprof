"""CoxPH brief, Appendix A and B1: pprof_py v0.7.0 against the R results of 05_robust_finegray.R.

1. Robust variance on (start, stop] data with tied deaths: with Breslow ties pprof_py's robust SE
   differs from survival's (its counting-process score kernel applies Efron's formulas to tied
   deaths whatever the tie method, inference/survival/robust.py:232); with Efron ties they agree.
2. Fine-Gray with delayed entry: pprof_py's finegray_transform() against survival::finegray() row
   for row, and FineGrayPH's coefficients and robust SEs against R's weighted, clustered fits.

Found on 2026-10-07: robust SE 0.4% off R's with Breslow ties, equal with Efron; the Fine-Gray
transform identical (3,469 rows, weights within 6e-15), coefficients within 2e-14, robust SE 0.36%
off with Breslow ties and equal with Efron.
Run from the repository root, after 05_robust_finegray.R:
    python dev/design/coxph-facts/05_robust_finegray.py <output file>
"""
import os
import sys

import pprof_py_env as env  # noqa: F401  (must come before pprof_py)

import numpy as np
import pandas as pd

from pprof_py import CoxPH, FineGrayPH
from pprof_py.algorithms.survival.finegray import finegray_transform

data_dir = os.path.join(env.PPROF_PY, "pprof_py", "r_reference", "data")
r = env.read_csv(os.path.join(env.SCRATCH, "r_checks.csv"))
with open(os.path.join(env.SCRATCH, "r_checks_meta.txt"), encoding="utf-8") as handle:
    out = [line.rstrip("\n") for line in handle]
out.append("")


def rel(a, b):
    return float(np.max(np.abs(np.asarray(a) - np.asarray(b)) / np.abs(np.asarray(b))))


d = env.read_csv(os.path.join(data_dir, "robust_strata_truncation.csv"))
out.append("Robust variance, robust_strata_truncation (strata, delayed entry, clusters):")
for ties in ["breslow", "efron"]:
    m = CoxPH(ties=ties).fit(d[["x1", "x2"]], start=d["start"], stop=d["stop"], event=d["event"],
                             strata=d["strata"], cluster=d["cluster"])
    rr = r[r["case"] == f"robust_strata_truncation/{ties}"]
    py = {"coef": m.coef_, "se_robust": m.standard_errors_, "se_naive": np.sqrt(np.diag(m.naive_covariance_))}
    for key in ["coef", "se_robust", "se_naive"]:
        out.append(f"  {ties:7s} {key:9s} pprof_py {np.round(np.asarray(py[key]), 6)}  R {np.round(rr[key].to_numpy(), 6)}"
                   f"  max relative difference {rel(py[key], rr[key]):.2e}")

d2 = env.read_csv(os.path.join(data_dir, "competing_risks_truncated.csv"))
fgd = finegray_transform(d2["start"].to_numpy(), d2["stop"].to_numpy(), d2["event"].to_numpy().astype(float),
                         failcode=1, id=d2["id"].to_numpy())
pyfg = pd.DataFrame({"id": np.asarray(fgd.subject), "fgstart": fgd.start, "fgstop": fgd.stop,
                     "fgstatus": fgd.status, "fgwt": fgd.weight})
rfg = env.read_csv(os.path.join(env.SCRATCH, "r_finegray_truncated.csv"))
merged = rfg.merge(pyfg, on=["id", "fgstart", "fgstop"], how="outer", suffixes=("_r", "_py"), indicator=True)
both = merged[merged["_merge"] == "both"]
weight_diff = np.abs(both["fgwt_r"] - both["fgwt_py"])
out += ["", "Fine-Gray transform with delayed entry, competing_risks_truncated, cause 1:",
        f"  rows: R {len(rfg)}, pprof_py {len(pyfg)}, matched on (id, fgstart, fgstop) {len(both)}, "
        f"only in R {int((merged['_merge'] == 'left_only').sum())}, only in pprof_py {int((merged['_merge'] == 'right_only').sum())}",
        f"  weights: largest difference {weight_diff.max():.2e}; rows differing by more than 1e-10: {int((weight_diff > 1e-10).sum())}; "
        f"status mismatches: {int((both['fgstatus_r'] != both['fgstatus_py']).sum())}"]
for ties in ["breslow", "efron"]:
    fg = FineGrayPH(ties=ties).fit(d2[["x1", "x2"]], event=d2["event"].to_numpy(), failcode=1,
                                   start=d2["start"].to_numpy(), stop=d2["stop"].to_numpy(), id=d2["id"].to_numpy())
    rr = r[r["case"] == f"finegray_truncated/{ties}"]
    out.append(f"  FineGrayPH {ties:7s}: coefficients pprof_py {np.round(np.asarray(fg.coef_), 7)} R {np.round(rr['coef'].to_numpy(), 7)}"
               f" (max relative difference {rel(fg.coef_, rr['coef']):.2e}); robust SE pprof_py {np.round(np.asarray(fg.standard_errors_), 6)}"
               f" R {np.round(rr['se_robust'].to_numpy(), 6)} (max relative difference {rel(fg.standard_errors_, rr['se_robust']):.2e})")
env.write_lines(sys.argv[1], out)
