"""The cases of the Cox fixture generator and their inputs (COXPH_DESIGN §G.1; COXPH_C1_PLAN §2).

A case is a dict with an `id`, a `kind` ("cox", "competing", or "penalized"), the `set` it is
shipped in ("core", with the package tests, or "full", with validation/), its `source`, and the
flags the outputs depend on. `load(case)` returns its input as a data frame whose double columns
are exact: integer times, covariates on binary grids, or values read from the vendored files.

Cox inputs have the columns id, stratum (the provider), [entry], time, event, weight, offset,
[cluster], x1, ..., xp, as pprof_spark's (its reference/fixtures/generate.py, MIT, from which the
six imported cases come). Synthetic inputs are drawn with NumPy's PCG64 from fixed seeds, so the
generator reproduces them exactly.
"""
import hashlib
import json
import os

import numpy as np
import pandas as pd

HERE = os.path.dirname(os.path.abspath(__file__))
INPUTS = os.path.join(HERE, "inputs")


def _imported(case_id, p, stratified, weighted, offset, truncated=False, set_="full"):
    return {"id": case_id, "kind": "cox", "set": set_, "source": "pprof_spark", "file": f"{case_id}.csv", "p": p,
            "stratified": stratified, "weighted": weighted, "offset": offset, "truncated": truncated}


def _synthetic(case_id, seed, p, truncated=False, weighted=False, offset=False, set_="full", **extra):
    return {"id": case_id, "kind": "cox", "set": set_, "source": "synthetic", "seed": seed, "p": p,
            "stratified": True, "weighted": weighted, "offset": offset, "truncated": truncated, **extra}


# The settings of the penalized-settings case (Phase C4; dev/design/coxph-facts/26): each fits pprof_py's
# PenalizedCoxPH with these arguments, on the case's covariates (x0, constant, and x1 to x3) or those named.
PENALIZED_SETTINGS = (
    {"label": "constant-column", "penalty_factor": [1.0, 0.0, 1.0, 1.0]},
    {"label": "ridge", "features": ["x1", "x2", "x3"], "alpha": 0.0},
    {"label": "unstandardized", "features": ["x1", "x2", "x3"], "alpha": 0.5, "standardize": False},
    {"label": "given-grid", "features": ["x1", "x2", "x3"], "lambda_path": [0.01, 0.1, 0.05]},
    {"label": "short-grid", "features": ["x1", "x2", "x3"], "n_lambda": 20, "lambda_min_ratio": 0.05},
    {"label": "unequal-factors", "features": ["x1", "x2", "x3"], "penalty_factor": [2.0, 1.0, 0.5]},
    {"label": "one-covariate", "features": ["x2"]},
)


CASES = (
    # pprof_spark's six cases (its ADR-0005), inputs vendored unchanged.
    _imported("tiny-ties", 1, False, False, False, set_="core"),
    _imported("rc-unstratified", 3, False, False, False),
    _imported("rc-stratified", 3, True, False, False, set_="core"),
    _imported("rc-stratified-weights-offset", 3, True, True, True),
    _imported("lt-stratified", 3, True, False, False, truncated=True, set_="core"),
    _imported("lt-weights-offset", 3, True, True, True, truncated=True),
    # New cases of COXPH_DESIGN §G.1.
    _synthetic("recurrent", 11, 2, truncated=True, clustered=True),
    _synthetic("near-ties", 12, 2, near_ties=True, set_="core"),
    _synthetic("zero-weights", 13, 3, weighted=True, offset=True),
    _synthetic("large-mean", 14, 2),
    _synthetic("empty-providers", 15, 2, set_="core"),
    _synthetic("provider-scale", 16, 5, truncated=True, residuals=False),
    {"id": "competing-simple", "kind": "competing", "set": "core", "source": "pprof_py",
     "file": "competing_risks_simple.csv", "p": 2, "truncated": False, "providers": 5},
    {"id": "competing-truncated", "kind": "competing", "set": "full", "source": "pprof_py",
     "file": "competing_risks_truncated.csv", "p": 2, "truncated": True, "providers": 5},
    # Phase C5 (the C5 plan's decision 6): case weights with zeros, and several rows per subject.
    {"id": "competing-weights", "kind": "competing", "set": "full", "source": "synthetic", "seed": 17, "p": 2,
     "truncated": True, "weighted": True},
    {"id": "penalized-wide", "kind": "penalized", "set": "full", "source": "pprof_py", "file": "penalized_wide.csv",
     "folds": "penalized_wide_foldid.csv", "alphas": [1.0, 0.5], "cv": True},
    {"id": "penalized-strata", "kind": "penalized", "set": "core", "source": "pprof_py", "file": "strata.csv",
     "alphas": [1.0], "cv": False},
    {"id": "penalized-offset", "kind": "penalized", "set": "full", "source": "pprof_py", "file": "offset.csv",
     "alphas": [1.0], "cv": False},
    {"id": "penalized-weights", "kind": "penalized", "set": "full", "source": "pprof_py", "file": "weights.csv",
     "alphas": [1.0], "cv": False},
    {"id": "penalized-truncation", "kind": "penalized", "set": "full", "source": "pprof_py",
     "file": "left_truncation.csv", "alphas": [1.0], "cv": False},
    {"id": "penalized-combined", "kind": "penalized", "set": "full", "source": "pprof_py", "file": "combined.csv",
     "alphas": [1.0, 0.5], "cv": True, "fold_seed": 21, "penalty_factor": [0.0, 1.0, 1.0]},
    # Phase C4 (the C4 plan's decision 5): settings the penalized cases above lack, on combined.csv with a
    # constant column; and few events per covariate (D-78), the first 15 rows of penalized_wide.csv.
    {"id": "penalized-settings", "kind": "penalized", "set": "full", "source": "pprof_py", "file": "combined.csv",
     "constant_column": "x0", "cv": False, "settings": PENALIZED_SETTINGS},
    {"id": "penalized-few-events", "kind": "penalized", "set": "full", "source": "pprof_py",
     "file": "penalized_wide.csv", "first_rows": 15, "cv": False, "settings": ({"label": "default"},)},
)


def sources():
    with open(os.path.join(INPUTS, "SOURCES.json"), encoding="utf-8") as handle:
        return json.load(handle)


def _read_vendored(case):
    """A vendored input, after checking its SHA-256 against inputs/SOURCES.json."""
    path = os.path.join(INPUTS, case["source"], case["file"])
    with open(path, "rb") as handle:
        content = handle.read()
    expected = sources()[case["source"]]["files"][case["file"]]["sha256"]
    if hashlib.sha256(content).hexdigest() != expected:
        raise SystemExit(f"{path} does not match its SHA-256 in inputs/SOURCES.json")
    # Round-trip parsing reads every decimal as the double nearest to it, as R's fixtures will hold it.
    return pd.read_csv(path, float_precision="round_trip")


def _grid(rng, size, half_width=128, step=64):
    """Integers in [-half_width, half_width] over `step`: exact binary fractions."""
    return rng.integers(-half_width, half_width + 1, size=size) / step


def _recurrent(case):
    """Several (start, stop] rows per patient, hospitalizations as a Poisson process in days, patients
    nested in providers, clustered by patient (SHR-shaped)."""
    rng = np.random.Generator(np.random.PCG64(case["seed"]))
    patients, providers, p = 240, 12, case["p"]
    rows = []
    for patient in range(patients):
        x = _grid(rng, p, 64, 32)
        rate = 0.004 * np.exp(x @ np.array([0.5, -0.25][:p]))
        start = int(rng.integers(0, 30))
        end = start + int(rng.integers(60, 400))
        t = start
        while t < end:
            gap = int(np.ceil(-np.log(rng.random()) / rate))
            stop = min(t + max(gap, 1), end)
            rows.append([patient % providers, t, stop, int(stop < end), patient, *x])
            t = stop
    df = pd.DataFrame(rows, columns=["stratum", "entry", "time", "event", "cluster"] + [f"x{j + 1}" for j in range(p)])
    df.insert(0, "id", np.arange(len(df)))
    df.insert(5, "weight", 1.0)
    df.insert(6, "offset", 0.0)
    return df


def _standard(case, n, strata, max_time, beta, x_mean=0.0, ties_rate=4.0):
    """pprof_spark's synthetic design: integer event times from an exponential model, uniform censoring,
    covariates on a 1/64 grid, offsets on a 1/16 grid, weights on a 1/2 grid, and optional delayed entry."""
    rng = np.random.Generator(np.random.PCG64(case["seed"]))
    p = case["p"]
    x = _grid(rng, (n, p))
    x[:, 0] += x_mean
    stratum = rng.integers(0, strata, size=n)
    offset = rng.integers(-8, 9, size=n) / 16.0 if case["offset"] else np.zeros(n)
    weight = rng.integers(1, 5, size=n) / 2.0 if case["weighted"] else np.ones(n)
    eta = (x - np.array([x_mean] + [0.0] * (p - 1))) @ np.array(beta[:p]) + offset
    t_event = np.ceil(-np.log(rng.random(n)) / np.exp(eta) * max_time / ties_rate)
    t_censor = rng.integers(1, max_time + 1, size=n)
    time = np.clip(np.minimum(t_event, t_censor), 1, max_time).astype(np.int64)
    event = (t_event <= t_censor).astype(np.int64)
    df = pd.DataFrame({"id": np.arange(n), "stratum": stratum, "time": time, "event": event,
                       "weight": weight, "offset": offset})
    if case["truncated"]:
        delayed = rng.random(n) < 0.5
        df.insert(2, "entry", np.where(delayed, rng.integers(0, time), 0).astype(np.int64))
    for j in range(p):
        df[f"x{j + 1}"] = x[:, j]
    return df, rng


def _near_ties(case):
    """Times in days stored as fractions of a year, with some event times repeated up to a relative 1e-12,
    as two computations of the same date can give: distinct to pprof_py and to timefix = FALSE, merged by
    survival's default timefix = TRUE (M-23)."""
    df, rng = _standard(case, 300, 8, 400, [0.5, -0.25])
    years = df["time"].to_numpy() / 365.25
    events = np.flatnonzero(df["event"].to_numpy() == 1)
    partners = rng.choice(events, size=24, replace=False)
    nudged = years.copy()
    nudged[partners[12:]] = years[partners[:12]] * (1 + 1e-12)
    df["time"] = nudged
    return df


def _zero_weights(case):
    """Weights on the 1/2 grid with about 5% zeros, one of them on an event tied with others in its
    stratum, where pprof_py's Efron count includes it (B7, M-25)."""
    df, _ = _standard(case, 600, 25, 60, [0.5, -0.25, 0.125])
    weight = df["weight"].to_numpy().copy()
    weight[df["id"].to_numpy() % 20 == 7] = 0.0
    events = df[df["event"] == 1]
    counts = events.groupby(["stratum", "time"]).size()
    stratum, time = counts[counts >= 3].index[0]
    weight[events[(events["stratum"] == stratum) & (events["time"] == time)].index[0]] = 0.0
    df["weight"] = weight
    return df


def _competing_weights(case):
    """Competing risks with case weights and several rows per subject (the CoxPH C5 plan, decision 6): 360
    subjects in 6 providers of 60, in weeks; about a quarter enter late; about a third have two or three
    contiguous (start, stop] rows, between which x2 changes; causes 1 and 2 on a subject's last row only;
    case weights on a 1/2 grid, the same on every row of a subject, 0 for about 5% of the subjects and for
    one subject whose event of cause 1 is tied with another in its provider, where pprof_py's Efron count
    includes it (B7, M-25)."""
    rng = np.random.Generator(np.random.PCG64(case["seed"]))
    subjects, providers = 360, 6
    rows = []
    for subject in range(subjects):
        x1 = rng.integers(-64, 65) / 32
        entry = int(rng.integers(1, 9)) if rng.random() < 0.25 else 0
        rate1, rate2 = 0.03 * np.exp(0.5 * x1), 0.015 * np.exp(-0.25 * x1)
        t_event = int(np.ceil(-np.log(rng.random()) / (rate1 + rate2)))
        cause = 1 if rng.random() < rate1 / (rate1 + rate2) else 2
        t_censor = int(rng.integers(4, 61))
        duration = max(min(t_event, t_censor), 1)
        status = cause if t_event <= t_censor else 0
        end = entry + duration
        pieces = int(rng.integers(2, 4)) if duration >= 3 and rng.random() < 1 / 3 else 1
        cuts = sorted(int(c) for c in rng.choice(np.arange(entry + 1, end), size=min(pieces, duration) - 1,
                                                 replace=False))
        bounds = [entry, *cuts, end]
        weight = rng.integers(1, 5) / 2
        for k in range(len(bounds) - 1):
            last = k == len(bounds) - 2
            rows.append([subject, subject % providers, bounds[k], bounds[k + 1], status if last else 0, weight, x1,
                         rng.integers(-64, 65) / 32])
    df = pd.DataFrame(rows, columns=["id", "stratum", "entry", "time", "event", "weight", "x1", "x2"])
    df.loc[df["id"] % 20 == 7, "weight"] = 0.0
    events = df[(df["event"] == 1) & (df["weight"] > 0)]
    counts = events.groupby(["stratum", "time"]).size()
    stratum, time = counts[counts >= 2].index[0]
    tied = events[(events["stratum"] == stratum) & (events["time"] == time)]
    df.loc[df["id"] == tied["id"].iloc[0], "weight"] = 0.0
    return df


def _empty_providers(case):
    """Provider 0 without events, provider 1 whose rows all leave before the first event time
    (expected events 0), and provider 2 with a single row."""
    df, _ = _standard(case, 300, 10, 60, [0.5, -0.25])
    df["time"] = np.maximum(df["time"].to_numpy(), 2)
    df.loc[df["stratum"] == 0, "event"] = 0
    df.loc[df["stratum"] == 1, ["time", "event"]] = [1, 0]
    two = np.flatnonzero(df["stratum"].to_numpy() == 2)
    df.loc[two[1:], "stratum"] = 3
    df.loc[two[0], "event"] = 1
    return df


def load(case):
    if case["source"] in ("pprof_spark", "pprof_py"):
        df = _read_vendored(case)
        if "first_rows" in case:
            df = df.iloc[:case["first_rows"]].reset_index(drop=True)
        if "constant_column" in case:
            df.insert(0, case["constant_column"], 1.0)
    elif case["id"] == "recurrent":
        df = _recurrent(case)
    elif case["id"] == "near-ties":
        df = _near_ties(case)
    elif case["id"] == "zero-weights":
        df = _zero_weights(case)
    elif case["id"] == "large-mean":
        # A covariate near 3,000: the fitted linear predictor passes pprof_py's clipping at 700 (D-64).
        df, _ = _standard(case, 300, 6, 60, [0.375, -0.25], x_mean=3000.0)
    elif case["id"] == "empty-providers":
        df = _empty_providers(case)
    elif case["id"] == "provider-scale":
        df, _ = _standard(case, 20000, 1000, 365, [0.5, -0.25, 0.125, 0.25, -0.125], ties_rate=8.0)
    elif case["id"] == "competing-weights":
        df = _competing_weights(case)
    else:
        raise ValueError(case["id"])
    if case["kind"] == "competing" and case["source"] == "pprof_py":
        # The Cox cases' column names, and a provider for the stratified fits (M-35, M-41).
        df = df.rename(columns={"start": "entry", "stop": "time"})
        df.insert(0, "stratum", (df["id"].to_numpy() - 1) % case["providers"])
    return df


def features(case, df):
    if case["kind"] == "cox" or case["kind"] == "competing":
        return [f"x{j + 1}" for j in range(case["p"])]
    return [c for c in df.columns if c.startswith("x")]


def folds(case, df):
    """Fold IDs 1..K of a penalized case's cross-validation: vendored, or drawn once from a fixed seed as
    pprof_py draws them (event rows, then censored rows, each a permutation of the labels)."""
    if "folds" in case:
        return _read_vendored({**case, "file": case["folds"]})["fold_id"].to_numpy()
    rng = np.random.Generator(np.random.PCG64(case["fold_seed"]))
    fold = np.empty(len(df), dtype=np.int64)
    for group in (np.flatnonzero(df["event"].to_numpy() == 1), np.flatnonzero(df["event"].to_numpy() == 0)):
        labels = np.tile(np.arange(1, 11), len(group) // 10 + 1)[:len(group)]
        fold[group] = rng.permutation(labels)
    return fold
