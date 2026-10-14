"""CoxPH C5 plan, §2.4 and §2.7: pprof_py v0.7.0's FineGrayPH on the scenarios of 33_finegray_cost.R, which
writes their data to $COXPH_FACTS_SCRATCH/bench-<scenario> first: the same second cause (every third event
row), cause 1, Breslow ties, the case weights, each row its own subject, stratified by provider. Times are
elapsed seconds of one run each, after a warm-up on 2,000 rows (numba compiles); finegray_transform()
alone, then the whole fit, which runs it again. Where the transform raises, its own steps, run stratum by
stratum with its decision on delayed entry, find the strata that raise and say whether a later piece would
have followed the competing event whose censoring-times-entry probability is 0 (survival's finegray()
gives such a piece a weight that is not finite, and emits nothing otherwise).

Run from the repository root, after 33_finegray_cost.R:
    python dev/design/coxph-facts/33_finegray_cost.py <output file>
"""
import json
import os
import sys
import time
import warnings

import pprof_py_env as env  # noqa: F401  (must come before pprof_py)

import numba
import numpy as np

from pprof_py import FineGrayPH
from pprof_py.algorithms.survival import finegray as transform
from pprof_py.algorithms.survival.finegray import finegray_transform

warnings.simplefilter("ignore")
out = [f"pprof_py v0.7.0, numba {numba.__version__} with {numba.get_num_threads()} threads"]


def raising_strata(start, stop, cause, ids, strata):
    """finegray_transform()'s loop, stratum by stratum: the strata whose pieces raise, and for the first
    competing event of each whose probability is 0, whether a kept breakpoint follows it."""
    labels, codes = np.unique(strata, return_inverse=True)
    first, last, delay = transform._validate_subject_structure(start, stop, cause, ids, codes)
    expand = last & (cause != 0.0) & (cause != 1.0)
    found = []
    for s in range(labels.size):
        idx = np.flatnonzero(codes == s)
        ctime, cprob = transform._curve_pair_for_stratum(start[idx], stop[idx], cause[idx], first[idx], last[idx],
                                                         delay)
        try:
            transform._build_pieces_one_group(row_ids=idx, start=start[idx], stop=stop[idx], status=cause[idx],
                                              failcode=1.0, expand=expand[idx], ctime=ctime, cprob=cprob)
        except FloatingPointError:
            breakpoints = np.concatenate([ctime, [stop[idx].max()]])
            probabilities = np.concatenate([[1.0], cprob])
            kept = np.unique(np.searchsorted(breakpoints, np.unique(stop[idx][cause[idx] == 1.0]), side="left"))
            for i in np.flatnonzero(expand[idx]):
                b = int(np.searchsorted(breakpoints, stop[idx][i], side="left"))
                if probabilities[b] <= 0.0:
                    found.append((int(labels[s]), int(idx[i]) + 1, float(stop[idx][i]), int(np.sum(kept > b))))
                    break
    return delay, found


def read(scenario):
    directory = os.path.join(env.SCRATCH, f"bench-{scenario}")
    spec = json.load(open(os.path.join(directory, "columns.json"), encoding="utf-8"))
    return spec, {name: np.fromfile(os.path.join(directory, f"{name}.f8"), dtype="<f8") for name in spec["columns"]}


warm = None
for scenario, right in (("center", False), ("covariates-5", False), ("providers-7500", False),
                        ("providers-7500", True)):
    spec, col = read(scenario)
    X = np.column_stack([col[c] for c in spec["covariates"]])
    n = X.shape[0]
    event = col["event"].astype(np.int64)
    cause = np.where(event == 1, np.where((np.arange(1, n + 1) % 3) == 0, 2, 1), 0)
    start = np.zeros(n) if right else col["start"]
    arguments = dict(event=cause, failcode=1, start=start, stop=col["stop"], id=np.arange(n),
                     strata=col["provider"].astype(np.int64), sample_weight=col["weight"])
    if warm is None:
        rows = slice(0, 2000)
        FineGrayPH(ties="breslow").fit(X[rows], event=cause[rows], failcode=1, start=np.zeros(2000),
                                       stop=col["stop"][rows], id=np.arange(2000), sample_weight=col["weight"][rows])
        warm = True
    label = f"{scenario}{', entry at 0' if right else ''} ({n} rows, {len(np.unique(arguments['strata']))} providers, {X.shape[1]} covariates)"
    t0 = time.perf_counter()
    try:
        fg = finegray_transform(arguments["start"], arguments["stop"], cause, failcode=1, id=arguments["id"],
                                strata=arguments["strata"], sample_weight=arguments["sample_weight"])
    except Exception as error:  # the outcome is what is recorded
        out.append(f"{label}: finegray_transform() {type(error).__name__}: {error}")
        delay, found = raising_strata(arguments["start"], arguments["stop"], cause.astype(float), arguments["id"],
                                      arguments["strata"])
        with_later = sum(1 for f in found if f[3] > 0)
        out.append(f"  delayed entry over all rows: {delay}; {len(found)} strata raise, {with_later} of them with a kept "
                   f"breakpoint after the competing event (a later piece)")
        for provider, row, time_, later in found[:3]:
            out.append(f"    provider {provider}: row {row}, a competing event at {time_:g}, {later} later kept breakpoints")
        env.write_lines(sys.argv[1], out)
        continue
    t1 = time.perf_counter()
    model = FineGrayPH(ties="breslow").fit(X, **arguments)
    t2 = time.perf_counter()
    out.append(f"{label}: finegray_transform() {t1 - t0:.2f} s, {fg.n_obs} rows; FineGrayPH {t2 - t1:.2f} s, "
               f"{model.n_iter_} iterations")
    env.write_lines(sys.argv[1], out)
env.write_lines(sys.argv[1], out)
