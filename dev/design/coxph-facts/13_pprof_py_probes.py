"""CoxPH brief, Appendix B: probes of pprof_py v0.7.0's defects, each section on its own data.

B2  ProviderPenalizedCoxPH's provider-effect score ignores delayed entry.
B3  ProviderPenalizedCoxPH with Efron ties updates the provider effects with the Breslow score; and
    the level of the provider effects is not identified (only their differences are).
    Also: at lambda_max it reproduces CoxPH with provider indicators (right-censored, Breslow).
B4  calculate_standardized_measures() matches covariates by position; it reproduces R's SMR golden file.
B5  exp() is clipped at +/-700 on the uncentered linear predictor: a covariate with a large mean
    breaks residuals, predictions and the robust variance, though the coefficients are right.
B9  The discrete-time models: penalty_factor raises; case weights and (provider version) alpha ignored.
B10 The bootstrap SE's partial likelihood is wrong when times are tied.
Run from the repository root: python dev/design/coxph-facts/13_pprof_py_probes.py <output file>
"""
import json
import os
import sys
import traceback
import warnings

import pprof_py_env as env  # noqa: F401  (must come before pprof_py)

import numpy as np

import pprof_py
from pprof_py import (CoxPH, DiscreteSurvival, GroupLassoCoxPH, ProviderPenalizedCoxPH,
                      ProviderPenalizedDiscreteSurvival)
from pprof_py.algorithms.survival.cox_likelihood import cox_partial_likelihood
from pprof_py.algorithms.survival.provider_effects import compute_provider_scores
from pprof_py.utils.deviance import _loglik_from_eta_multi

warnings.simplefilter("ignore")
out = []


def section(title, body):
    out.extend(["", f"## {title}"])
    try:
        body()
    except Exception:  # record the failure and go on with the next probe
        out.append("probe failed: " + traceback.format_exc().strip().splitlines()[-1])


def b2():
    rng = np.random.default_rng(3)
    K, n = 6, 900
    prov = rng.integers(0, K, n)
    X = rng.normal(size=(n, 2))
    lp = X @ [0.5, -0.3] + np.linspace(-0.6, 0.6, K)[prov]
    D = np.eye(K)[prov]
    for truncated in (False, True):
        start = np.where(rng.uniform(size=n) < 0.5, rng.uniform(0, 1.5, n), 0.0) if truncated else np.zeros(n)
        t = start + rng.exponential(1.0 / np.exp(lp))
        c = start + rng.exponential(2.0, n)
        stop, event = np.minimum(t, c), (t <= c).astype(float)
        beta, gamma = np.array([0.4, -0.2]), rng.normal(0, 0.3, K)
        score_kernel, _ = compute_provider_scores(gamma[prov] + X @ beta, event, np.ones(n), start, stop, prov, K)
        _, score_exact, _ = cox_partial_likelihood(D, start, stop, event, gamma, offset=X @ beta, ties="breslow")
        reference = CoxPH(ties="breslow").fit(np.column_stack([X, D[:, 1:]]), start=start, stop=stop, event=event)
        fit = ProviderPenalizedCoxPH(lambda_path=1e-12, standardize=False, provider_max_iter=500, provider_tol=1e-10,
                                     outer_tol=1e-12).fit(X, start=start, stop=stop, event=event, provider_id=prov)
        g = fit.gamma_path_[0]
        out.append(f"delayed entry {truncated}: |score of the kernel - exact score| = {np.max(np.abs(score_kernel - score_exact)):.2e}; "
                   f"converged {bool(fit.converged_path_[0])} after {int(fit.n_provider_iter_path_[0])} provider iterations; "
                   f"provider contrasts against CoxPH with indicators {np.max(np.abs((g[1:] - g[0]) - reference.coef_[2:])):.2e}; "
                   f"mean provider effect {g.mean():.4g}")


def b3():
    rng = np.random.RandomState(7)
    n, K = 600, 5
    X = rng.normal(size=(n, 9))
    prov = np.sort(rng.randint(0, K, size=n))
    eta = X @ np.array([0.6, -0.45, 0.35, 0, 0, 0, 0.25, -0.18, 0.12]) + rng.normal(scale=0.4, size=K)[prov]
    t = rng.exponential(scale=np.exp(-eta))
    c = rng.exponential(scale=np.quantile(t, 0.75), size=n)
    time = np.round(np.minimum(t, c), 1) + 0.1  # heavy ties
    event = (t <= c).astype(float)
    groups = np.array([1, 1, 1, 2, 2, 2, 3, 3, 3])
    D = (prov[:, None] == np.arange(1, K)[None, :]).astype(float)
    out.append(f"{n} rows, {K} providers, {len(np.unique(time))} distinct times, {int(event.sum())} events")
    for ties in ("breslow", "efron"):
        fit = ProviderPenalizedCoxPH(penalty_type="group_lasso", groups=groups, n_lambda=8, lambda_min_ratio=0.05, ties=ties,
                                     provider_tol=1e-10, outer_tol=1e-10, provider_max_iter=500).fit(
            X, duration=time, event=event, provider_id=prov)
        exact = GroupLassoCoxPH(groups=np.r_[groups, np.zeros(K - 1, int)], lambda_path=fit.lambda_path_, outer_tol=1e-12,
                                ties=ties).fit(np.c_[X, D], duration=time, event=event)
        last = len(fit.lambda_path_) - 1
        g = fit.gamma_path_[last]
        _, score, _ = cox_partial_likelihood(D, np.zeros(n), time, event, g[1:] - g[0], offset=X @ fit.coef_path_[last], ties=ties)
        out.append(f"ties {ties}: beta against the exact {ties} fit with provider indicators "
                   f"{np.max(np.abs(fit.coef_path_ - exact.coef_path_[:, :9])):.2e}; provider contrasts "
                   f"{np.max(np.abs((fit.gamma_path_[:, 1:] - fit.gamma_path_[:, :1]) - exact.coef_path_[:, 9:])):.2e}; "
                   f"{ties} score for the provider indicators at the last lambda {np.max(np.abs(score)):.2e}; "
                   f"converged at every lambda: {bool(fit.converged_path_.all())}")
    fit = ProviderPenalizedCoxPH(n_lambda=10).fit(X, duration=time, event=event, provider_id=prov)
    out.append("median provider effect along the default path: " + " ".join(f"{v:.4f}" for v in np.median(fit.gamma_path_, axis=1)))
    g, b = fit.gamma_path_[5], fit.coef_path_[5]
    shift = (cox_partial_likelihood(X, np.zeros(n), time, event, b, offset=g[prov])[0]
             - cox_partial_likelihood(X, np.zeros(n), time, event, b, offset=g[prov] + 3.0)[0])
    out.append(f"log-likelihood change when every provider effect is shifted by 3: {shift:.1e}")
    at_max = ProviderPenalizedCoxPH(n_lambda=5, provider_tol=1e-10, provider_max_iter=500).fit(
        X, duration=time, event=event, provider_id=prov)
    indicators = CoxPH(ties="breslow").fit(D, duration=time, event=event)
    out.append(f"at lambda_max (all penalized coefficients zero: {bool(np.all(at_max.coef_path_[0] == 0))}), provider "
               f"contrasts against CoxPH with provider indicators only: "
               f"{np.max(np.abs((at_max.gamma_path_[0][1:] - at_max.gamma_path_[0][0]) - indicators.coef_)):.2e}")


def b4():
    golden = os.path.join(env.PPROF_PY, "pprof_py", "tests", "data", "cox_smr")
    d = env.read_csv(os.path.join(golden, "raw.csv"))
    with open(os.path.join(golden, "r_smr.json"), encoding="utf-8") as handle:
        r = json.load(handle)
    X = d[["x1", "x2", "x3"]]
    m = CoxPH(ties="breslow").fit(X, start=d["start"], stop=d["stop"], event=d["event"], strata=d["prov"])
    res = m.calculate_standardized_measures(X, start=d["start"], stop=d["stop"], event=d["event"], provider_id=d["prov"],
                                            stdz=["indirect", "direct"])
    indirect, direct = res["indirect"], res["direct"]
    out.append(f"R golden file ({r['note']}): coefficients {np.max(np.abs(m.coef_ - np.array(r['coef'])) / np.abs(r['coef'])):.1e}, "
               f"indirect E {np.max(np.abs(indirect['expected'] - r['indirect_expected']) / np.array(r['indirect_expected'])):.1e}, "
               f"direct E {np.max(np.abs(direct['expected'] - r['direct_expected']) / np.array(r['direct_expected'])):.1e} (relative)")
    reordered = X[["x3", "x1", "x2"]]
    res2 = m.calculate_standardized_measures(reordered, start=d["start"], stop=d["stop"], event=d["event"],
                                             provider_id=d["prov"])["indirect"]
    out.append(f"columns reordered (x3, x1, x2): predict_linear() unchanged: {bool(np.allclose(m.predict_linear(reordered), m.predict_linear(X)))}; "
               f"largest relative change in E_j from calculate_standardized_measures(): "
               f"{np.max(np.abs(res2['expected'] - indirect['expected']) / indirect['expected']):.3f}")


def b5():
    rng = np.random.default_rng(7)
    n = 300
    X = rng.normal(size=(n, 2))
    start = np.where(rng.uniform(size=n) < 0.4, np.round(rng.uniform(0, 2, n)), 0.0)
    t = start + np.ceil(rng.exponential(3.0 / np.exp(X @ [0.5, -0.4])))
    c = start + np.ceil(rng.exponential(6.0, n))
    duration, event = np.minimum(t, c) - start, (t <= c).astype(float)
    reference = CoxPH(ties="efron").fit(X, duration=duration, event=event)
    for shift in (1500.0, 2020.0):
        Xs = X.copy()
        Xs[:, 0] += shift
        m = CoxPH(ties="efron").fit(Xs, duration=duration, event=event)
        hazard = m.predict_cumulative_hazard(Xs[:3]).iloc[-1].to_numpy()
        hazard_ref = reference.predict_cumulative_hazard(X[:3]).iloc[-1].to_numpy()
        try:
            robust = CoxPH(ties="efron", robust=True).fit(Xs, duration=duration, event=event)
            robust_text = "robust SE " + " ".join(f"{v:.4g}" for v in robust.standard_errors_)
        except Exception as error:
            robust_text = f"robust variance raises {type(error).__name__}"
        out.append(f"x1 shifted by {shift:g}: coefficients change {np.max(np.abs(m.coef_ - reference.coef_)):.1e}; "
                   f"max linear predictor {np.max(Xs @ m.coef_):.0f}; martingale residuals change "
                   f"{np.max(np.abs(m.martingale_residuals_ - reference.martingale_residuals_)):.3g}; cumulative hazard "
                   f"at the last time of 3 subjects {np.round(hazard, 4)} (unshifted {np.round(hazard_ref, 4)}); {robust_text}")


def discrete_data():
    rng = np.random.RandomState(1)
    n, p, n_prov, T = 400, 5, 10, 6
    X = rng.randn(n, p)
    prov = rng.randint(0, n_prov, n)
    g = rng.randn(n_prov) * 0.4
    b = np.array([0.6, -0.4, 0.2, 0, 0])
    t, e = np.full(n, T), np.zeros(n, int)
    for i in range(n):
        for k in range(1, T + 1):
            if rng.rand() < 1 / (1 + np.exp(-(-2.5 + X[i] @ b + g[prov[i]]))):
                t[i], e[i] = k, 1
                break
    return X, t, e, prov


def b9():
    X, t, e, prov = discrete_data()
    try:
        DiscreteSurvival(penalty_factor=np.ones(5), n_lambda=5).fit(X, t, e)
        out.append("DiscreteSurvival(penalty_factor=...): no error")
    except Exception as error:
        out.append(f"DiscreteSurvival(penalty_factor=...): {type(error).__name__}: {error}")
    w = np.random.RandomState(7).uniform(0.2, 5.0, len(t))
    m0 = DiscreteSurvival(standardize=False, lambda_path=[0.05, 0.01, 0.002]).fit(X, t, e)
    m1 = DiscreteSurvival(standardize=False, lambda_path=[0.05, 0.01, 0.002]).fit(X, t, e, sample_weight=w)
    out.append(f"DiscreteSurvival with random case weights against none: largest coefficient difference "
               f"{np.max(np.abs(m0.coef_path_ - m1.coef_path_)):.1e}")
    kw = dict(lambda_path=[0.05, 0.01, 0.002], outer_tol=1e-6)
    fits = {a: ProviderPenalizedDiscreteSurvival(alpha=a, **kw).fit(X, t, e, prov) for a in (1.0, 0.2, 0.0)}
    weighted = ProviderPenalizedDiscreteSurvival(alpha=1.0, **kw).fit(X, t, e, prov, sample_weight=w)
    out.append(f"ProviderPenalizedDiscreteSurvival: alpha 1 against 0.2 {np.max(np.abs(fits[1.0].coef_path_ - fits[0.2].coef_path_)):.1e}, "
               f"against 0 {np.max(np.abs(fits[1.0].coef_path_ - fits[0.0].coef_path_)):.1e}; nonzero coefficients at alpha 0 "
               f"(ridge would keep all 5): {(fits[0.0].coef_path_ != 0).sum(1).tolist()}; with random case weights against none "
               f"{np.max(np.abs(fits[1.0].coef_path_ - weighted.coef_path_)):.1e}")


def b10():
    rng = np.random.RandomState(7)
    n = 600
    X = rng.normal(size=(n, 9))
    eta = (X @ np.r_[0.5, -0.3, np.zeros(7)])[:, None]
    t = rng.exponential(size=n)
    tied = np.round(t, 1) + 0.1
    event = (rng.uniform(size=n) < 0.6).astype(float)
    for label, time in (("tied times", tied), ("no ties", t)):
        fast = _loglik_from_eta_multi(eta, np.zeros(n), time, event, np.ones(n), np.zeros(n, int))[0]
        engine = cox_partial_likelihood(np.zeros((n, 1)), np.zeros(n), time, event, np.zeros(1), offset=eta[:, 0],
                                        ties="breslow")[0]
        out.append(f"{label}: the bootstrap SE's log-likelihood {fast:.6f}, the Breslow engine's {engine:.6f}, "
                   f"difference {fast - engine:.3g}")


section("B2: provider-effect score with delayed entry", b2)
section("B3: ProviderPenalizedCoxPH with Efron ties; the level of the provider effects", b3)
section("B4: calculate_standardized_measures(): R golden file and column order", b4)
section("B5: a covariate with a large mean", b5)
section("B9: discrete-time models", b9)
section("B10: the bootstrap SE's partial likelihood with tied times", b10)
env.write_lines(sys.argv[1], [f"pprof_py {getattr(pprof_py, '__version__', 'unknown')}"] + out)
