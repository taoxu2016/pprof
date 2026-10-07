"""CoxPH brief, §1 and Appendix A: pprof_py v0.7.0's PenalizedCoxPH (lasso, Breslow ties) at the lambda
values glmnet chose in 09_penalized_glmnet.R, timed and compared with glmnet's tight path.

Found on 2026-10-07 with glmnet 5.1: coefficients within 2.2e-7, the same active set at every lambda;
27 s against glmnet's 3.4 s (8.9 s at its tight threshold).
Run from the repository root, after 09_penalized_glmnet.R:
    python dev/design/coxph-facts/09_penalized_glmnet.py <output file>
"""
import os
import sys
import time

import pprof_py_env as env  # noqa: F401  (must come before pprof_py)

import numpy as np

from pprof_py import PenalizedCoxPH

d = env.read_csv(os.path.join(env.SCRATCH, "bench_pen.csv"))
lam = env.read_csv(os.path.join(env.SCRATCH, "pen_lambda.csv"))["lambda"].to_numpy()
beta_r = env.read_csv(os.path.join(env.SCRATCH, "pen_beta_r.csv")).to_numpy()
xs = [c for c in d.columns if c.startswith("x")]
X = d[xs].to_numpy()
kw = dict(start=d["start"].to_numpy(), stop=d["stop"].to_numpy(), event=d["event"].to_numpy(),
          strata=d["provider"].to_numpy(), offset=d["offset"].to_numpy(), sample_weight=d["weight"].to_numpy())
PenalizedCoxPH(alpha=1.0, lambda_path=lam[:3]).fit(X[:3000], **{k: v[:3000] for k, v in kw.items()})  # compile
times = []
for _ in range(2):
    t0 = time.perf_counter()
    m = PenalizedCoxPH(alpha=1.0, lambda_path=lam, ties="breslow").fit(X, **kw)
    times.append(time.perf_counter() - t0)
path = np.asarray(m.coef_path_)
if path.shape != beta_r.shape:
    path = path.T
diff = np.abs(path - beta_r)
same_active = bool(np.all((path != 0) == (beta_r != 0)))
env.write_lines(sys.argv[1], [
    f"PenalizedCoxPH lasso path at glmnet's {len(lam)} lambda values: median {np.median(times):.2f} s "
    f"(runs {', '.join(f'{t:.2f}' for t in times)})",
    f"Coefficient path against glmnet's tight fit: largest absolute difference {diff.max():.1e} "
    f"(at the last lambda {diff[-1].max():.1e}); the same active set at every lambda: {same_active}",
])
