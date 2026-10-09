"""CoxPH Phase C3 plan: pprof_py v0.7.0's mid-p limits on the data sets of 22_measures_tests.R's part D
(1,000, 3,000, and 7,500 providers), timed, and compared with the limits that script computed once per
distinct observed count (to rounding), on the Poisson-mean scale in units of pprof_py's xtol,
1e-10 max(E, 1). pprof_py's function is CoxPH.test()'s own (inference/survival/provider_tests.py:29-54),
with the theoretical null (mean 0, sd 1) at level 0.95.
Run from the repository root, after the R script, with COXPH_FACTS_SCRATCH set:
    python dev/design/coxph-facts/22_measures_tests.py <output file>
"""
import os
import sys
import time

import pprof_py_env as env  # noqa: F401  (must come before pprof_py)

import numpy as np
import pandas as pd

from pprof_py.inference.survival.provider_tests import _midp_limits

out_file = sys.argv[1] if len(sys.argv) > 1 else "22_measures_tests.txt"
lines = [f"Python {sys.version.split()[0]}, NumPy {np.__version__}"]
alpha = 1.0 - 0.95
for m in (1000, 3000, 7500):
    d = pd.read_csv(os.path.join(env.SCRATCH, f"22_midp_{m}.csv"))
    obs = d["observed"].to_numpy(dtype=float)
    exp_ = np.array([float.fromhex(v) for v in d["expected"]])
    r_lower = np.array([float.fromhex(v) for v in d["lower"]])
    r_upper = np.array([float.fromhex(v) for v in d["upper"]])
    _midp_limits(obs[:10], exp_[:10], np.zeros(10), np.ones(10), alpha)  # numba and caches warm
    start = time.perf_counter()
    lower, upper = _midp_limits(obs, exp_, np.zeros(m), np.ones(m), alpha)
    seconds = time.perf_counter() - start
    xtol = 1e-10 * np.maximum(exp_, 1.0)
    finite = np.isfinite(lower) & np.isfinite(r_lower)
    worst = max(np.max(np.abs(lower - r_lower)[finite] / xtol[finite]), np.max(np.abs(upper - r_upper) / xtol))
    lines.append(f"{m:5d} providers, {len(np.unique(obs)):4d} distinct O: pprof_py {seconds:6.2f} s, R once per "
                 f"distinct O {d['seconds'].iloc[0]:5.2f} s; largest difference {worst:.2g} xtol; "
                 f"lower limits 0 in both: {bool(np.array_equal(lower == 0, r_lower == 0))}")
env.write_lines(out_file, lines)
print("\n".join(lines))
