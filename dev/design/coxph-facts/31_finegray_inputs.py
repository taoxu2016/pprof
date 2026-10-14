"""CoxPH C5 plan, §2.1 to §2.4: pprof_py v0.7.0's side of 31_finegray_inputs.R, on the same small data.

- finegray_transform() and FineGrayPH with a repeated id on right-censored data, a subject whose rows
  change stratum, zero sample weights, and a status with one event type;
- the provider of part C of the R script, within both strata and alone: pprof_py decides delayed entry
  over all rows, as survival's stratified call does;
- part D: where survival's finegray() gives weights that are not finite, pprof_py raises
  FloatingPointError, and it also raises when no extension piece follows the competing events, where
  survival's weights are finite.

Run from the repository root: python dev/design/coxph-facts/31_finegray_inputs.py <output file>
"""
import sys

import pprof_py_env as env  # noqa: F401  (must come before pprof_py)

import numpy as np

from pprof_py import FineGrayPH
from pprof_py.algorithms.survival.finegray import finegray_transform

out = []


def attempt(label, function):
    try:
        result = function()
    except Exception as error:  # the outcome is what is recorded
        out.append(f"  {label}: {type(error).__name__}: {error}")
        return None
    return result


def pieces(fg, ids):
    return [f"    row {int(ids[r])} ({s:g}, {t:g}] status {int(st)} weight {float(w)!r}"
            for r, s, t, st, w in zip(fg.row, fg.start, fg.stop, fg.status, fg.weight)]


out.append("pprof_py v0.7.0, finegray_transform() and FineGrayPH, cause 1")
out.append("")
out.append("B. Inputs:")
stop = np.array([5.0, 3, 4, 6, 2, 1, 7, 8])
event = np.array([0.0, 1, 2, 0, 2, 1, 1, 0])
x = np.column_stack([np.linspace(-1, 1, 8), np.cos(np.arange(8))])
fg = attempt("right-censored data with a repeated id",
             lambda: finegray_transform(np.zeros(8), stop, event, failcode=1, id=np.array([1, 1, 2, 3, 4, 5, 6, 7])))
if fg is not None:
    out.append(f"  right-censored data with a repeated id: {fg.n_obs} rows")
start2 = np.array([0.0, 4, 0, 0, 0, 0, 0, 0])
stop2 = np.array([4.0, 9, 3, 6, 2, 1, 7, 8])
event2 = np.array([0.0, 2, 1, 0, 2, 1, 1, 0])
fg = attempt("a subject (id 1, rows (0, 4] and (4, 9]) whose rows change stratum",
             lambda: finegray_transform(start2, stop2, event2, failcode=1, id=np.array([1, 1, 2, 3, 4, 5, 6, 7]),
                                        strata=np.array([1, 2, 1, 1, 2, 2, 1, 2])))
if fg is not None:
    out.append(f"  a subject whose rows change stratum: {fg.n_obs} rows")
fg = finegray_transform(np.zeros(8), stop, event, failcode=1, sample_weight=np.array([1, 0, 1, 1, 0.5, 1, 1, 2.0]))
out.append(f"  zero sample weights (rows 2 and 5 of weight 0 and 0.5): {fg.n_obs} rows, weights "
           f"{[round(float(w), 4) for w in fg.weight]} (rows of weight 0 stay, with weight 0, and reach CoxPH)")
model = attempt("a status with one event type", lambda: FineGrayPH().fit(x, event=(event == 1).astype(float),
                                                                          failcode=1, duration=stop))
if model is not None:
    out.append(f"  a status with one event type (0/1), failcode 1: FineGrayPH fits it, coefficients {model.coef_}")

out.append("")
out.append("C. The provider of the R script's part C, in a call stratified by provider and alone:")
ids = np.arange(1, 11)
start = np.array([0.0, 10, 5, 0, 0, 2, 0, 0, 4, 0])
stop = np.array([10.0, 30, 20, 25, 40, 35, 1, 3, 8, 12])
cause = np.array([2.0, 0, 1, 0, 1, 2, 0, 1, 2, 1])
strata = np.array([1, 1, 1, 1, 1, 1, 2, 2, 2, 2])
both = finegray_transform(start, stop, cause, failcode=1, id=ids, strata=strata)
keep = np.isin(both.row, np.flatnonzero(strata == 1))
out.append("  within both strata (provider 1's rows):")
out += pieces(type(both)(**{k: getattr(both, k)[keep] for k in ("row", "subject", "start", "stop", "status",
                                                                  "weight", "added")}), ids)
alone = finegray_transform(start[:6], stop[:6], cause[:6], failcode=1, id=ids[:6])
out.append("  alone:")
out += pieces(alone, ids)

out.append("")
out.append("D. Where the censoring-times-entry curve is 0 at a competing event:")
for label, cause_time in (("provider 43 of rows-1e4", 286.0), ("the same with its cause-1 event at 30", 30.0)):
    rows = np.array([909, 3072, 3478, 5394, 5811, 6390, 8822])
    fg = attempt(label, lambda: finegray_transform(np.array([0.0, 0, 0, 192, 352, 0, 0]),
                                                   np.array([65.0, 44, cause_time, 250, 385, 68, 162]),
                                                   np.array([0.0, 2, 1, 2, 2, 2, 0]), failcode=1, id=rows))
    if fg is not None:
        out.append(f"  {label}: {fg.n_obs} rows")
        out += pieces(fg, rows)

env.write_lines(sys.argv[1], out)
