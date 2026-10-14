"""CoxPH Phase C4 plan: pprof_py v0.7.0's PenalizedCoxPH on settings the penalized fixtures do not cover,
for 26_penalized_grid.R to compare with the plain-R construction of its lambda grid and with glmnet.

The data are two of pprof_py's own reference inputs, vendored by the fixture generator
(dev/reference/cox/inputs/pprof_py): combined.csv (900 rows, (start, stop], six strata, an offset,
weights, three covariates), with and without a constant column, and with one covariate alone; and the
first 15 rows of penalized_wide.csv (20 covariates, so fewer rows than covariates). Each setting is fitted with both tie
methods; the results go to $COXPH_FACTS_SCRATCH/26_pprof_py.json with doubles as hexadecimal strings.

Run from the repository root with the fixture generator's Python (dev/reference/cox/venv), before the R
script, with COXPH_FACTS_SCRATCH set:
    python dev/design/coxph-facts/26_penalized_grid.py
"""
import json
import os
import sys
import warnings

import pprof_py_env as env  # noqa: F401  (must come before pprof_py)

import numpy as np

from pprof_py.models.survival.penalized_coxph import PenalizedCoxPH

INPUTS = os.path.join("dev", "reference", "cox", "inputs", "pprof_py")


def hexes(values):
    return [float(v).hex() for v in np.ravel(np.asarray(values, dtype=float))]


def arguments(df):
    out = {"event": df["event"].to_numpy()}
    if "start" in df.columns:
        out.update(start=df["start"].to_numpy(dtype=float), stop=df["stop"].to_numpy(dtype=float))
    else:
        out["duration"] = df["stop"].to_numpy(dtype=float)
    if "provider" in df.columns:
        out["strata"] = df["provider"].to_numpy()
    if "offset1" in df.columns:
        out["offset"] = df["offset1"].to_numpy(dtype=float)
    if "weight" in df.columns:
        out["sample_weight"] = df["weight"].to_numpy(dtype=float)
    return out


combined = env.read_csv(os.path.join(INPUTS, "combined.csv"))
constant = combined.copy()
constant.insert(0, "x0", 1.0)
wide = env.read_csv(os.path.join(INPUTS, "penalized_wide.csv")).iloc[:15].reset_index(drop=True)

# (label, data, features, PenalizedCoxPH arguments)
SETTINGS = [
    ("constant-column", constant, ["x0", "x1", "x2", "x3"], {"penalty_factor": [1.0, 0.0, 1.0, 1.0]}),
    ("ridge", combined, ["x1", "x2", "x3"], {"alpha": 0.0}),
    ("unstandardized", combined, ["x1", "x2", "x3"], {"alpha": 0.5, "standardize": False}),
    ("given-grid", combined, ["x1", "x2", "x3"], {"lambda_path": [0.01, 0.1, 0.05]}),
    ("short-grid", combined, ["x1", "x2", "x3"], {"n_lambda": 20, "lambda_min_ratio": 0.05}),
    ("unequal-factors", combined, ["x1", "x2", "x3"], {"penalty_factor": [2.0, 1.0, 0.5]}),
    ("rows-below-columns", wide, [f"x{j}" for j in range(1, 21)], {}),
    ("one-covariate", combined, ["x2"], {}),
]

records = []
for label, df, features, settings in SETTINGS:
    for ties in ("breslow", "efron"):
        with warnings.catch_warnings(record=True) as caught:
            warnings.simplefilter("always")
            model = PenalizedCoxPH(ties=ties, **settings).fit(df[features].to_numpy(dtype=float), **arguments(df))
        records.append({
            "label": label, "ties": ties, "features": features, "settings": settings, "rows": int(len(df)),
            "events": int(df["event"].sum()),
            "lambda_max": hexes([model.lambda_max_]), "lambda_min_ratio": hexes([model.lambda_min_ratio_]),
            "lambda": hexes(model.lambda_path_), "coef_path": [hexes(row) for row in np.asarray(model.coef_path_)],
            "column_scale": hexes(model.column_scale_), "penalty_factor": hexes(model.penalty_factor_),
            "nonzero_path": [int(v) for v in model.n_nonzero_path_],
            "converged_path": [bool(v) for v in model.converged_path_],
            "warnings": [f"{w.category.__name__}: {w.message}" for w in caught],
        })
        print(label, ties, len(model.lambda_path_), "lambdas", flush=True)

with open(os.path.join(env.SCRATCH, "26_pprof_py.json"), "w", encoding="utf-8") as handle:
    json.dump({"python": sys.version.split()[0], "numpy": np.__version__, "records": records}, handle)
