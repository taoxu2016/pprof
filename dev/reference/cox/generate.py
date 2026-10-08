#!/usr/bin/env python3
"""Generate the Cox reference fixtures (CoxPH brief §3.1 and §6; COXPH_DESIGN §G.1; DEC-093).

For every case of cases.py, this script writes to a staging directory the case definition, the
input, and pprof_py v0.7.0's outputs as JSON, with doubles as hexadecimal strings (exact in Python
and R); then it runs survival.R in the isolated R library for survival's and glmnet's outputs, and
convert.R, which writes one RDS fixture per case and a manifest per fixture set. The pprof_py
outputs follow pprof_spark's reference/fixtures/generate.py (MIT, commit e917a68), from which much
of this script is adapted.

Usage, from the repository root, with the generator's Python (dev/reference/cox/README.md):
    dev/reference/cox/venv/Scripts/python dev/reference/cox/generate.py
        [--out-core DIR] [--out-full DIR] [--staging DIR] [--cases ID,...] [--allow-dirty]
The default outputs are tests/testthat/fixtures/cox/ and validation/fixtures/cox/. The generator
refuses to run when its inputs have uncommitted changes, unless --allow-dirty is given with both
outputs outside the repository's fixture folders.
"""
import os

# One thread everywhere, before NumPy and numba load: their thread pools would change summation orders.
THREADS = {"NUMBA_NUM_THREADS": "1", "OMP_NUM_THREADS": "1", "OPENBLAS_NUM_THREADS": "1", "MKL_NUM_THREADS": "1"}
os.environ.update(THREADS)

import argparse
import hashlib
import json
import platform
import shutil
import subprocess
import sys
import tempfile
import warnings
from importlib import metadata

import numpy as np
import pandas as pd

import cases as case_table
from pprof_py.algorithms.survival.cox_likelihood import cox_partial_likelihood
from pprof_py.algorithms.survival.finegray import finegray_transform
from pprof_py.data.survival_data import SurvivalData
from pprof_py.data.survival_validation import validate_fit_inputs
from pprof_py.inference.survival.residuals import dfbeta_residuals, score_residuals
from pprof_py.models.survival.competing_risks import FineGrayPH
from pprof_py.models.survival.coxph import CoxPH
from pprof_py.models.survival.penalized_coxph import PenalizedCoxPH, PenalizedCoxPHCV

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
FORMAT_VERSION = 1
PPROF_PY_COMMIT = "9320766e35e5b385d596a2b75418192098a124c4"
TIES = ("breslow", "efron")
FIXED_BETA = (0.375, -0.1875, 0.0625, 0.125, -0.25)
TIGHT = {"max_iter": 100, "eps": 1e-11}
PROFILES = ((0.0, 0.0, 0.0, 0.0, 0.0), (0.5, -0.25, 0.125, 0.25, -0.5), (-1.0, 0.75, 0.5, -0.25, 0.125))
PROFILE_OFFSETS = (0.0, 0.25, -0.5)
CLUSTERS = 40  # without a cluster column, robust variances are clustered by id mod 40, as pprof_spark's


# Encoding ---------------------------------------------------------------------------------------

def hexes(values):
    return [float(v).hex() for v in np.ravel(np.asarray(values, dtype=float))]


def packed(matrix):
    m = np.asarray(matrix, dtype=float)
    return [m[i, j] for i in range(m.shape[0]) for j in range(i, m.shape[0])]


def label(value):
    return int(value) if float(value).is_integer() else str(value)


def write_json(path, value):
    with open(path, "w", encoding="utf-8", newline="\n") as handle:
        json.dump(value, handle, indent=1, sort_keys=True)
        handle.write("\n")


def encode_input(df):
    """Columns as lists: integers as such, doubles as hexadecimal strings."""
    columns, types = {}, {}
    for name in df.columns:
        values = df[name].to_numpy()
        if np.issubdtype(values.dtype, np.integer):
            columns[name], types[name] = [int(v) for v in values], "integer"
        else:
            columns[name], types[name] = hexes(values), "double"
    return {"names": list(df.columns), "types": types, "columns": columns}


# Cox cases --------------------------------------------------------------------------------------

def x_of(df, case):
    return df[case_table.features(case, df)].to_numpy(dtype=float)


def fit_arguments(df, case):
    if case.get("truncated"):
        arguments = {"start": df["entry"].to_numpy(dtype=float), "stop": df["time"].to_numpy(dtype=float),
                     "event": df["event"].to_numpy()}
    else:
        arguments = {"duration": df["time"].to_numpy(dtype=float), "event": df["event"].to_numpy()}
    if case["stratified"]:
        arguments["strata"] = df["stratum"].to_numpy()
    if case["offset"]:
        arguments["offset"] = df["offset"].to_numpy(dtype=float)
    if case["weighted"]:
        arguments["sample_weight"] = df["weight"].to_numpy(dtype=float)
    return arguments


def quiet(function, *args, **kwargs):
    """pprof_py's warnings (max_iter reached, zero expected counts) are part of what is recorded, not noise
    on the generator's output; they are captured and returned with the result."""
    with warnings.catch_warnings(record=True) as caught:
        warnings.simplefilter("always")
        result = function(*args, **kwargs)
    return result, sorted({f"{w.category.__name__}: {w.message}" for w in caught})


def pprof_fit(df, case, ties, **control):
    model, caught = quiet(lambda: CoxPH(ties=ties, **control).fit(x_of(df, case), **fit_arguments(df, case)))
    return {
        "coef": hexes(model.coef_), "se": hexes(model.standard_errors_),
        "covariance": hexes(packed(model.covariance_)),
        "loglik": hexes([model.log_likelihood_]), "loglik_null": hexes([model.log_likelihood_null_]),
        "iterations": int(model.n_iter_), "converged": bool(model.converged_),
        "z": hexes(model.z_scores_), "p": hexes(model.p_values_),
        "ci_lower": hexes(np.asarray(model.confidence_intervals_)[:, 0]),
        "ci_upper": hexes(np.asarray(model.confidence_intervals_)[:, 1]),
        "warnings": caught,
    }


def pprof_iterates(df, case, ties, count=5):
    """The fit after k iterations, k = 1 to count, for lockstep comparison of the Newton path."""
    out = []
    for k in range(1, count + 1):
        model, _ = quiet(lambda: CoxPH(ties=ties, max_iter=k).fit(x_of(df, case), **fit_arguments(df, case)))
        out.append({"iterations": int(model.n_iter_), "beta": hexes(model.coef_),
                    "loglik": hexes([model.log_likelihood_])})
    return out


def pprof_function(df, case, ties, beta):
    data = SurvivalData(**validate_fit_inputs(x_of(df, case), **fit_arguments(df, case)))
    loglik, score, information = cox_partial_likelihood(
        data.X, data.start, data.stop, data.event, np.asarray(beta, dtype=float),
        offset=data.offset, weight=data.weight, strata=data.strata_codes, ties=ties)
    return {"beta": hexes(beta), "loglik": hexes([loglik]), "score": hexes(score),
            "information": hexes(packed(information))}


def pprof_baseline(df, case, ties):
    model, _ = quiet(lambda: CoxPH(ties=ties, **TIGHT).fit(x_of(df, case), **fit_arguments(df, case)))
    raw = model._baseline_hazard_raw.sort_values(["stratum", "time"], kind="stable")
    public = model.baseline_hazard_.sort_values(["stratum", "time"], kind="stable")
    p = case["p"]
    x = np.array([profile[:p] for profile in PROFILES], dtype=float)
    offsets = np.array(PROFILE_OFFSETS, dtype=float) if case["offset"] else None
    predictions = []
    for stratum in list(dict.fromkeys(raw["stratum"].tolist()))[:2]:
        hazard, _ = quiet(lambda: model.predict_cumulative_hazard(x, offset=offsets, stratum=stratum))
        survival, _ = quiet(lambda: model.predict_survival_function(x, offset=offsets, stratum=stratum))
        predictions.append({"stratum": label(stratum), "time": hexes(hazard.index.to_numpy(dtype=float)),
                            "cumulative_hazard": [hexes(hazard[c].to_numpy()) for c in hazard.columns],
                            "survival": [hexes(survival[c].to_numpy()) for c in survival.columns]})
    weights = df["weight"].to_numpy(dtype=float) if case["weighted"] else np.ones(len(df))
    offset_mean = np.average(df["offset"].to_numpy(dtype=float), weights=weights) if case["offset"] else 0.0
    return {
        "raw": {"stratum": [label(s) for s in raw["stratum"]], "time": hexes(raw["time"].to_numpy(dtype=float)),
                "cumulative_hazard": hexes(raw["hazard"].to_numpy()), "survival": hexes(raw["survival"].to_numpy())},
        "public_cumulative_hazard": hexes(public["hazard"].to_numpy()),
        "offset_mean": hexes([offset_mean]),
        "profiles": {"x": [hexes(row) for row in x], "offset": hexes(offsets if offsets is not None else np.zeros(len(x))),
                     "linear": hexes(model.predict_linear(x, offset=offsets)),
                     "relative_hazard": hexes(model.predict_partial_hazard(x, offset=offsets))},
        "predictions": predictions,
    }


def clusters_of(df):
    return df["cluster"].to_numpy() if "cluster" in df.columns else df["id"].to_numpy() % CLUSTERS


def pprof_residuals(df, case, ties):
    X = x_of(df, case)
    arguments = fit_arguments(df, case)
    data = SurvivalData(**validate_fit_inputs(X, **arguments))
    model, _ = quiet(lambda: CoxPH(ties=ties, **TIGHT).fit(X, **arguments))
    eta = data.X @ model.coef_ + data.offset
    score = score_residuals(data.X, data.start, data.stop, data.event, eta, data.weight,
                            data.strata_codes, data.strata_labels, ties=ties)
    dfbeta = dfbeta_residuals(score, data.weight, model.naive_covariance_)
    cluster = clusters_of(df)
    per_row, _ = quiet(lambda: CoxPH(ties=ties, robust=True, **TIGHT).fit(X, **arguments))
    clustered, _ = quiet(lambda: CoxPH(ties=ties, **TIGHT).fit(X, cluster=cluster, **arguments))
    sums = pd.DataFrame(dfbeta).groupby(cluster).sum().to_numpy()
    return {
        "martingale": hexes(model.martingale_residuals_),
        "score": [hexes(score[:, j]) for j in range(score.shape[1])],
        "dfbeta": [hexes(dfbeta[:, j]) for j in range(dfbeta.shape[1])],
        "naive_covariance": hexes(packed(model.naive_covariance_)),
        "robust_per_row": hexes(packed(per_row.covariance_)),
        "robust_clustered": hexes(packed(clustered.covariance_)),
        "robust_per_row_from_dfbeta": hexes(packed(dfbeta.T @ dfbeta)),
        "robust_clustered_from_dfbeta": hexes(packed(sums.T @ sums)),
        "clusters": int(clustered.n_clusters_),
    }


def providers_of(df, case):
    """The provider of each row: the stratum when the fit is stratified (the two-stage measures),
    otherwise id mod 10, as pprof_spark's."""
    return df["stratum"].to_numpy() if case["stratified"] else df["id"].to_numpy() % 10


def measure_arguments(df, case):
    return {k: v for k, v in fit_arguments(df, case).items() if k in ("duration", "event", "start", "stop", "offset")}


def pprof_measures(df, case, ties):
    X = x_of(df, case)
    model, _ = quiet(lambda: CoxPH(ties=ties, **TIGHT).fit(X, **fit_arguments(df, case)))
    out, caught = quiet(lambda: model.calculate_standardized_measures(
        X, provider_id=providers_of(df, case), stdz=["indirect", "direct"], **measure_arguments(df, case)))
    indirect, direct = out["indirect"], out["direct"]
    return {
        "beta": hexes(model.coef_),
        "provider": [label(v) for v in indirect["provider_id"]],
        "indirect_ratio": hexes(indirect["indirect_ratio"].to_numpy()),
        "observed": hexes(indirect["observed"].to_numpy(dtype=float)),
        "expected": hexes(indirect["expected"].to_numpy()),
        "person_time": hexes(indirect["person_time"].to_numpy(dtype=float)),
        "direct_provider": [label(v) for v in direct["provider_id"]],
        "direct_ratio": hexes(direct["direct_ratio"].to_numpy()),
        "direct_expected": hexes(direct["expected"].to_numpy()),
        "total_observed": hexes([float(direct["observed"].iloc[0])]),
        "n_pop": int(direct["n_pop"].iloc[0]),
        "warnings": caught,
    }


def pprof_tests(df, case, ties):
    X = x_of(df, case)
    model, _ = quiet(lambda: CoxPH(ties=ties, **TIGHT).fit(X, **fit_arguments(df, case)))
    out = {}
    for method in ("midp", "exact"):
        res, caught = quiet(lambda: model.test(X, provider_id=providers_of(df, case), test_method=method, level=0.95,
                                               **measure_arguments(df, case)))
        flag = res["flag"].to_numpy(dtype=float)
        out[method] = {
            "provider": [label(v) for v in res.index],
            "observed": hexes(res["observed"].to_numpy(dtype=float)),
            "expected": hexes(res["expected"].to_numpy(dtype=float)),
            "estimate": hexes(res["estimate"].to_numpy()), "z_raw": hexes(res["z_raw"].to_numpy()),
            "p_value": hexes(res["p_value"].to_numpy()),
            "flag": [None if np.isnan(f) else int(f) for f in flag],
            "ci_lower": hexes(res["ci_lower"].to_numpy()), "ci_upper": hexes(res["ci_upper"].to_numpy()),
            "warnings": caught,
        }
    return out


def shifted_tie(df):
    """Moves one of two or more tied events a day later: a real defect a tolerance must catch."""
    events = df[df["event"] == 1]
    counts = events.groupby(["stratum", "time"]).size()
    stratum, time = counts[counts >= 2].index[0]
    row = events[(events["stratum"] == stratum) & (events["time"] == time)].index[0]
    shifted = df.copy()
    shifted.loc[row, "time"] = time + 1
    return shifted


def dropped_weight(df):
    """Sets the first weight different from 1 to 1."""
    changed = df.copy()
    row = changed.index[changed["weight"] != 1.0][0]
    changed.loc[row, "weight"] = 1.0
    return changed


def cox_outputs(df, case):
    reference = {}
    for ties in TIES:
        controls = {"other_ties": pprof_fit(df, case, "efron" if ties == "breslow" else "breslow", **TIGHT),
                    "shifted_tie": pprof_fit(shifted_tie(df), case, ties, **TIGHT)}
        if case["weighted"]:
            controls["dropped_weight"] = pprof_fit(dropped_weight(df), case, ties, **TIGHT)
        beta_fixed = FIXED_BETA[:len(case_table.features(case, df))]
        reference[ties] = {
            "default": pprof_fit(df, case, ties),
            "tight": pprof_fit(df, case, ties, **TIGHT),
            "beta_zero": pprof_function(df, case, ties, [0.0] * len(beta_fixed)),
            "beta_fixed": pprof_function(df, case, ties, beta_fixed),
            "iterates": pprof_iterates(df, case, ties),
            "baseline": pprof_baseline(df, case, ties),
            "measures": pprof_measures(df, case, ties),
            "tests": pprof_tests(df, case, ties),
            "negative_controls": controls,
        }
        if case.get("residuals", True):
            reference[ties]["residuals"] = pprof_residuals(df, case, ties)
    return reference


# Competing risks --------------------------------------------------------------------------------

def competing_outputs(df, case):
    """Cause-specific fits, measures, and tests (each cause, other causes censored, stratified by
    provider; M-35), and Fine-Gray fits for each cause, stratified by provider (M-41) and not."""
    reference = {}
    causes = sorted(int(c) for c in np.unique(df["event"]) if c != 0)
    for ties in TIES:
        cause_specific = {}
        for cause in causes:
            recoded = df.assign(event=(df["event"].to_numpy() == cause).astype(np.int64))
            cox_case = {**case, "stratified": True, "weighted": False, "offset": False}
            cause_specific[str(cause)] = {
                "default": pprof_fit(recoded, cox_case, ties), "tight": pprof_fit(recoded, cox_case, ties, **TIGHT),
                "measures": pprof_measures(recoded, cox_case, ties), "tests": pprof_tests(recoded, cox_case, ties),
            }
        fine_gray = {}
        for cause in causes:
            for stratified in (True, False):
                fine_gray[f"{cause}{'' if stratified else '_unstratified'}"] = pprof_fine_gray(df, case, ties, cause,
                                                                                              stratified)
        reference[ties] = {"cause_specific": cause_specific, "fine_gray": fine_gray}
    return reference


def pprof_fine_gray(df, case, ties, cause, stratified):
    X = df[case_table.features(case, df)]
    stop = df["time"].to_numpy(dtype=float)
    start = df["entry"].to_numpy(dtype=float) if case["truncated"] else np.zeros(len(df))
    times = {"start": start, "stop": stop} if case["truncated"] else {"duration": stop}
    strata = df["stratum"].to_numpy() if stratified else None
    fits = {}
    for setting, control in (("default", {}), ("tight", TIGHT)):
        model, caught = quiet(lambda: FineGrayPH(ties=ties, **control).fit(
            X, event=df["event"].to_numpy(), failcode=cause, id=df["id"].to_numpy(), strata=strata, **times))
        fit = model.model_
        fits[setting] = {
            "coef": hexes(fit.coef_), "covariance": hexes(packed(fit.covariance_)),
            "naive_covariance": hexes(packed(fit.naive_covariance_)),
            "loglik": hexes([fit.log_likelihood_]), "loglik_null": hexes([fit.log_likelihood_null_]),
            "iterations": int(fit.n_iter_), "converged": bool(fit.converged_), "warnings": caught,
        }
    tight_model = model
    # The Newton path at tight control, for comparisons within the last step (D-57).
    iterates = []
    for k in range(1, 6):
        partial, _ = quiet(lambda: FineGrayPH(ties=ties, max_iter=k, eps=TIGHT["eps"]).fit(
            X, event=df["event"].to_numpy(), failcode=cause, id=df["id"].to_numpy(), strata=strata, **times))
        iterates.append({"iterations": int(partial.model_.n_iter_), "beta": hexes(partial.model_.coef_)})
    fits["iterates"] = iterates
    model = tight_model
    fg = finegray_transform(start=start, stop=stop, event=df["event"].to_numpy(), failcode=cause,
                            id=df["id"].to_numpy(), strata=strata)
    x = np.array([profile[:case["p"]] for profile in PROFILES], dtype=float)
    incidence = []
    for stratum in ([s for s in np.unique(df["stratum"])][:2] if stratified else [None]):
        survival, _ = quiet(lambda: model.predict_survival_function(x, stratum=stratum))
        incidence.append({"stratum": None if stratum is None else label(stratum),
                          "time": hexes(survival.index.to_numpy(dtype=float)),
                          "cumulative_incidence": [hexes(1.0 - survival[c].to_numpy()) for c in survival.columns]})
    return {
        "expanded": {"row": [int(r) for r in fg.row], "start": hexes(fg.start), "stop": hexes(fg.stop),
                     "status": [int(s) for s in fg.status], "weight": hexes(fg.weight)},
        **fits,
        "profiles": [hexes(row) for row in x], "cumulative_incidence": incidence,
    }


# Penalized cases ---------------------------------------------------------------------------------

def penalized_arguments(df):
    arguments = {"event": df["event"].to_numpy()}
    if "start" in df.columns:
        arguments.update(start=df["start"].to_numpy(dtype=float), stop=df["stop"].to_numpy(dtype=float))
    else:
        arguments["duration"] = df["stop"].to_numpy(dtype=float)
    if "provider" in df.columns:
        arguments["strata"] = df["provider"].to_numpy()
    for name in ("offset1", "log_exposure"):
        if name in df.columns:
            arguments["offset"] = df[name].to_numpy(dtype=float)
    if "weight" in df.columns:
        arguments["sample_weight"] = df["weight"].to_numpy(dtype=float)
    return arguments


def path_record(model):
    return {
        "lambda": hexes(model.lambda_path_), "lambda_max": hexes([model.lambda_max_]),
        "lambda_min_ratio": hexes([model.lambda_min_ratio_]),
        "coef_path": [hexes(row) for row in np.asarray(model.coef_path_)],
        "loglik_path": hexes(model.log_likelihood_path_), "loglik_null": hexes([model.log_likelihood_null_]),
        "deviance_ratio_path": hexes(model.deviance_ratio_path_),
        "iterations_path": [int(v) for v in model.n_iter_path_], "converged_path": [bool(v) for v in model.converged_path_],
        "nonzero_path": [int(v) for v in model.n_nonzero_path_],
        "column_scale": hexes(model.column_scale_), "penalty_factor": hexes(model.penalty_factor_),
    }


def penalized_outputs(df, case):
    X = df[case_table.features(case, df)].to_numpy(dtype=float)
    arguments = penalized_arguments(df)
    factor = np.asarray(case["penalty_factor"], dtype=float) if "penalty_factor" in case else None
    fold = case_table.folds(case, df) if case["cv"] else None
    reference = {}
    for ties in TIES:
        entry = {}
        for alpha in case["alphas"]:
            key = f"alpha_{alpha:g}"
            model, caught = quiet(lambda: PenalizedCoxPH(alpha=alpha, penalty_factor=factor, ties=ties).fit(X, **arguments))
            entry[key] = {"path": {**path_record(model), "warnings": caught}}
            other, _ = quiet(lambda: PenalizedCoxPH(alpha=alpha, penalty_factor=factor,
                                                    ties="efron" if ties == "breslow" else "breslow",
                                                    lambda_path=model.lambda_path_).fit(X, **arguments))
            controls = {"other_ties": other}
            entry[key]["negative_controls"] = {k: {"coef_path": [hexes(r) for r in np.asarray(m.coef_path_)]}
                                               for k, m in controls.items()}
            if case["cv"] and alpha == 1.0:
                cv, caught = quiet(lambda: PenalizedCoxPHCV(alpha=alpha, penalty_factor=factor, ties=ties,
                                                            fold_id=fold).fit(X, **arguments))
                entry[key]["cv"] = {
                    "fold": [int(v) for v in np.asarray(cv.fold_id_)], "lambda": hexes(cv.lambda_path_),
                    "cvm": hexes(cv.cv_mean_deviance_), "cvsd": hexes(cv.cv_se_deviance_),
                    "folds_used": [int(v) for v in np.ravel(cv.cv_n_folds_)],
                    "lambda_min": hexes([cv.lambda_min_]), "lambda_1se": hexes([cv.lambda_1se_]),
                    "lambda_selected": hexes([cv.lambda_]), "coef": hexes(cv.coef_), "warnings": caught,
                }
        reference[ties] = entry
    if fold is not None:
        reference["fold"] = [int(v) for v in fold]
    return reference


# Driver ------------------------------------------------------------------------------------------

def check_pprof_py():
    """pprof_py must be 0.7.0, and every installed module must equal the file at commit 9320766 of the
    checkout in PPROF_PY (default ../../pprof_py)."""
    checkout = os.path.abspath(os.environ.get("PPROF_PY", os.path.join(ROOT, "..", "..", "pprof_py")))
    head = subprocess.run(["git", "-C", checkout, "rev-parse", "HEAD"], check=True, capture_output=True,
                          text=True).stdout.strip()
    if head != PPROF_PY_COMMIT or metadata.version("pprof_py") != "0.7.0":
        sys.exit(f"pprof_py must be 0.7.0 at {PPROF_PY_COMMIT}; the checkout {checkout} is at {head}")
    import pprof_py
    installed = os.path.dirname(pprof_py.__file__)
    differing = []
    for directory, _, names in os.walk(installed):
        for name in names:
            if name.endswith(".py"):
                path = os.path.join(directory, name)
                relative = os.path.relpath(path, os.path.dirname(installed)).replace(os.sep, "/")
                committed = subprocess.run(["git", "-C", checkout, "show", f"{PPROF_PY_COMMIT}:{relative}"],
                                           capture_output=True).stdout
                with open(path, "rb") as handle:
                    if handle.read().replace(b"\r\n", b"\n") != committed.replace(b"\r\n", b"\n"):
                        differing.append(relative)
    if differing:
        sys.exit(f"installed pprof_py differs from commit {PPROF_PY_COMMIT}: {', '.join(differing[:5])}")
    return {"version": "0.7.0", "commit": PPROF_PY_COMMIT}


def check_clean(paths):
    status = subprocess.run(["git", "-C", ROOT, "status", "--porcelain", "--", *paths], check=True,
                            capture_output=True, text=True).stdout
    return status.strip() == ""


def environment(pprof_py, clean):
    return {
        "generator_clean": clean,
        "pprof_py": pprof_py,
        "python": sys.version.split()[0],
        "python_implementation": platform.python_implementation(),
        "platform": platform.platform(),
        "machine": platform.machine(),
        "processor": os.environ.get("PROCESSOR_IDENTIFIER", platform.processor()),
        "packages": {d.metadata["Name"].lower(): d.version for d in sorted(metadata.distributions(),
                                                                          key=lambda d: d.metadata["Name"].lower())},
        "numba_threading_layer": os.environ.get("NUMBA_THREADING_LAYER", "default"),
        "generator_commit": subprocess.run(["git", "-C", ROOT, "rev-parse", "HEAD"], check=True, capture_output=True,
                                           text=True).stdout.strip(),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--out-core", default=os.path.join(ROOT, "tests", "testthat", "fixtures", "cox"))
    parser.add_argument("--out-full", default=os.path.join(ROOT, "validation", "fixtures", "cox"))
    parser.add_argument("--staging", help="keep the staging files here (default: a temporary directory)")
    parser.add_argument("--cases", help="comma-separated case IDs (default: all)")
    parser.add_argument("--allow-dirty", action="store_true")
    parser.add_argument("--python-only", action="store_true", help="stop after pprof_py's outputs (development)")
    options = parser.parse_args()

    generator_files = [os.path.relpath(HERE, ROOT)]
    clean = check_clean(generator_files)
    protected = [os.path.join(ROOT, "tests", "testthat", "fixtures", "cox"),
                 os.path.join(ROOT, "validation", "fixtures", "cox")]
    outside = all(not os.path.abspath(o).lower().startswith(os.path.abspath(p).lower())
                  for o in (options.out_core, options.out_full) for p in protected)
    if not clean and not (options.allow_dirty and outside):
        sys.exit("dev/reference/cox/ has uncommitted changes; fixtures come only from the committed generator "
                 "(--allow-dirty works only with both outputs outside the fixture folders)")
    if options.cases and not outside:
        sys.exit("--cases writes a partial fixture set, so both outputs must be outside the fixture folders")
    pprof_py = check_pprof_py()
    os.environ.setdefault("NUMBA_CACHE_DIR", os.path.join(tempfile.gettempdir(), "nbc_cox"))
    staging = options.staging or tempfile.mkdtemp(prefix="cox-staging-")
    os.makedirs(staging, exist_ok=True)
    selected = set(options.cases.split(",")) if options.cases else None

    ran = []
    for case in case_table.CASES:
        if selected and case["id"] not in selected:
            continue
        print(f"{case['id']}: pprof_py", flush=True)
        df = case_table.load(case)
        case_dir = os.path.join(staging, case["id"])
        shutil.rmtree(case_dir, ignore_errors=True)
        os.makedirs(case_dir)
        definition = dict(case, features=case_table.features(case, df), rows=len(df),
                          events=int((df["event"] != 0).sum()),
                          fixed_beta=list(FIXED_BETA[:len(case_table.features(case, df))]))
        if case["source"] != "synthetic":
            source = case_table.sources()[case["source"]]
            definition["provenance"] = {"repository": source["repository"], "commit": source["commit"],
                                        "license": source["license"], **source["files"][case["file"]]}
        write_json(os.path.join(case_dir, "case.json"), definition)
        write_json(os.path.join(case_dir, "input.json"), encode_input(df))
        if case["kind"] == "cox":
            outputs = cox_outputs(df, case)
        elif case["kind"] == "competing":
            outputs = competing_outputs(df, case)
        else:
            outputs = penalized_outputs(df, case)
        write_json(os.path.join(case_dir, "pprof_py.json"), outputs)
        ran.append(case["id"])
    write_json(os.path.join(staging, "environment.json"), environment(pprof_py, clean))
    if options.python_only:
        print(f"pprof_py outputs in {staging}", flush=True)
        return

    rscript = os.environ.get("RSCRIPT", "Rscript")
    library = os.path.join(HERE, "lib")
    print("survival and glmnet", flush=True)
    subprocess.run([rscript, "--vanilla", os.path.join(HERE, "survival.R"), staging, library, *ran], check=True)
    out_dirs = {"core": options.out_core, "full": options.out_full}
    for out_dir in out_dirs.values():
        # A full run replaces the whole set; a partial one (--cases, outside the fixture folders) adds to it.
        if not options.cases and os.path.isdir(out_dir):
            for name in os.listdir(out_dir):
                if name.endswith(".rds") or name == "manifest.json":
                    os.remove(os.path.join(out_dir, name))
    print("convert", flush=True)
    subprocess.run([rscript, "--vanilla", os.path.join(HERE, "convert.R"), staging, options.out_core,
                    options.out_full, library, *ran], check=True)
    write_manifests(staging, out_dirs, ran)
    print(f"staging files in {staging}" if options.staging else "done", flush=True)


def sha256(path):
    with open(path, "rb") as handle:
        return hashlib.sha256(handle.read()).hexdigest()


def md5(path):
    """For the tests, which check fixtures with base R's tools::md5sum()."""
    with open(path, "rb") as handle:
        return hashlib.md5(handle.read()).hexdigest()


def write_manifests(staging, out_dirs, ran):
    """One manifest per fixture set: the environments, the options, and every case with its source and the
    SHA-256 of its fixture. No timestamps, so a rerun reproduces the manifest byte for byte."""
    with open(os.path.join(staging, "environment.json"), encoding="utf-8") as handle:
        python_environment = json.load(handle)
    with open(os.path.join(staging, "r_environment.json"), encoding="utf-8") as handle:
        r_environment = json.load(handle)
    by_id = {case["id"]: case for case in case_table.CASES}
    for set_name, out_dir in out_dirs.items():
        entries = {}
        for case_id in ran:
            case = by_id[case_id]
            if case["set"] != set_name:
                continue
            with open(os.path.join(staging, case_id, "case.json"), encoding="utf-8") as handle:
                definition = json.load(handle)
            fixture = os.path.join(out_dir, f"{case_id}.rds")
            entries[case_id] = {"file": f"{case_id}.rds", "sha256": sha256(fixture), "md5": md5(fixture),
                                "kind": case["kind"], "source": case["source"], "rows": definition["rows"],
                                "events": definition["events"], "seed": definition.get("seed"),
                                "provenance": definition.get("provenance")}
        if not entries:
            continue
        write_json(os.path.join(out_dir, "manifest.json"), {
            "format_version": FORMAT_VERSION,
            "set": set_name,
            "generator": "dev/reference/cox/generate.py",
            "generator_commit": python_environment.pop("generator_commit"),
            "generator_clean": python_environment.pop("generator_clean"),
            "python": python_environment,
            "r": r_environment,
            "r_library_lock_sha256": sha256(os.path.join(HERE, "cox-library-lock.json")),
            "inputs_sources_sha256": sha256(os.path.join(HERE, "inputs", "SOURCES.json")),
            "threads": THREADS,
            "options": {"ties": list(TIES), "tight": TIGHT, "fixed_beta": list(FIXED_BETA),
                        "timefix": False, "clusters": "the cluster column, or id mod 40",
                        "zero_weights": "left out of survival's fits; kept in the measures (M-25)",
                        "glmnet_control": "list(thresh = 1e-12, maxit = 1e5, fdev = 0, devmax = 1)",
                        "cv_deviance": "coxnet.deviance(std.weights = FALSE), normalized by the held-out event weight"},
            "cases": entries,
        })
        python_environment = json.load(open(os.path.join(staging, "environment.json"), encoding="utf-8"))


if __name__ == "__main__":
    main()
