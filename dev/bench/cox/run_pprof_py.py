#!/usr/bin/env python3
"""The pprof_py side of the Cox benchmark baseline (CoxPH brief §3.7; COXPH_DESIGN §I).

pprof_py v0.7.0 on the scenarios of dev/bench/cox/scenarios.R, which run_engines.R writes to the data
directory first. The results are reported next to the engines' (the package should be no slower than
pprof_py); mid-p limits are the brief's explicit target (pprof_py took 50 s at 3,000 providers).

Usage, from the repository root, with the Cox generator's Python (dev/reference/cox/README.md):
    dev/reference/cox/venv/Scripts/python dev/bench/cox/run_pprof_py.py <data dir> <output csv> [--only REGEX]
Each task runs in a fresh process: a warm-up on 2,000 rows (numba compiles or loads its cache), then
the first run's time, the process's peak memory before and after it, and repeated runs (5 when the
first takes under 10 s, 3 under 60 s, else 1). numba uses its default threads, which the CSV records.
"""
import csv
import json
import os
import re
import statistics
import subprocess
import sys
import time

TASKS = ("coxph_breslow", "coxph_efron", "coxph_robust_breslow", "measures", "test_midp", "test_exact",
         "penalized_path", "penalized_cv")
PENALIZED_ONLY = {"penalized_path", "penalized_cv"}


def peak_mb():
    """The process's peak memory: the peak working set on Windows, the maximum resident set elsewhere."""
    if os.name == "nt":
        import ctypes
        from ctypes import wintypes

        class Counters(ctypes.Structure):
            _fields_ = [("cb", wintypes.DWORD), ("PageFaultCount", wintypes.DWORD),
                        ("PeakWorkingSetSize", ctypes.c_size_t), ("WorkingSetSize", ctypes.c_size_t),
                        ("QuotaPeakPagedPoolUsage", ctypes.c_size_t), ("QuotaPagedPoolUsage", ctypes.c_size_t),
                        ("QuotaPeakNonPagedPoolUsage", ctypes.c_size_t), ("QuotaNonPagedPoolUsage", ctypes.c_size_t),
                        ("PagefileUsage", ctypes.c_size_t), ("PeakPagefileUsage", ctypes.c_size_t)]
        counters = Counters()
        counters.cb = ctypes.sizeof(counters)
        kernel32 = ctypes.WinDLL("kernel32")
        kernel32.GetCurrentProcess.restype = wintypes.HANDLE
        get_info = kernel32.K32GetProcessMemoryInfo
        get_info.argtypes = [wintypes.HANDLE, ctypes.POINTER(Counters), wintypes.DWORD]
        get_info.restype = wintypes.BOOL
        if not get_info(kernel32.GetCurrentProcess(), ctypes.byref(counters), counters.cb):
            raise OSError("K32GetProcessMemoryInfo failed")
        return counters.PeakWorkingSetSize / 2 ** 20
    import resource
    return resource.getrusage(resource.RUSAGE_SELF).ru_maxrss / 1024


def child(directory, task):
    import warnings

    import numba
    import numpy as np
    from pprof_py.models.survival.coxph import CoxPH
    from pprof_py.models.survival.penalized_coxph import PenalizedCoxPH, PenalizedCoxPHCV

    warnings.simplefilter("ignore")
    spec = json.load(open(os.path.join(directory, "columns.json"), encoding="utf-8"))
    col = {name: np.fromfile(os.path.join(directory, f"{name}.f8"), dtype="<f8") for name in spec["columns"]}
    X = np.column_stack([col[c] for c in spec["covariates"]])
    times = {"start": col["start"], "stop": col["stop"], "event": col["event"].astype(np.int64)}
    provider = col["provider"].astype(np.int64)
    fit_args = dict(times, strata=provider, offset=col["offset"], sample_weight=col["weight"])

    def subset(rows):
        return {k: (v[:rows] if isinstance(v, np.ndarray) else v) for k, v in fit_args.items()}

    warm = 2000
    model = CoxPH(ties="breslow").fit(X[:warm], **subset(warm))
    if task in ("measures", "test_midp", "test_exact"):
        model.calculate_standardized_measures(X[:warm], provider_id=provider[:warm], stdz=["indirect", "direct"],
                                              start=times["start"][:warm], stop=times["stop"][:warm],
                                              event=times["event"][:warm], offset=col["offset"][:warm])
        model = CoxPH(ties="breslow").fit(X, **fit_args)
    measure_args = dict(times, offset=col["offset"])
    calls = {
        "coxph_breslow": lambda: CoxPH(ties="breslow").fit(X, **fit_args),
        "coxph_efron": lambda: CoxPH(ties="efron").fit(X, **fit_args),
        "coxph_robust_breslow": lambda: CoxPH(ties="breslow", robust=True).fit(X, **fit_args),
        "measures": lambda: model.calculate_standardized_measures(X, provider_id=provider,
                                                                  stdz=["indirect", "direct"], **measure_args),
        "test_midp": lambda: model.test(X, provider_id=provider, test_method="midp", level=0.95, **measure_args),
        "test_exact": lambda: model.test(X, provider_id=provider, test_method="exact", level=0.95, **measure_args),
        "penalized_path": lambda: PenalizedCoxPH(alpha=1.0, n_lambda=100, lambda_min_ratio=1e-4,
                                                 ties="breslow").fit(X, **fit_args),
        "penalized_cv": lambda: PenalizedCoxPHCV(alpha=1.0, n_lambda=100, lambda_min_ratio=1e-4, n_folds=10,
                                                 random_state=1, ties="breslow").fit(X, **fit_args),
    }
    if task.startswith("penalized"):
        PenalizedCoxPH(alpha=1.0, n_lambda=3, ties="breslow").fit(X[:warm], **subset(warm))
    if task.startswith("test"):
        model.test(X[:warm], provider_id=provider[:warm], test_method=task.split("_")[1], level=0.95,
                   start=times["start"][:warm], stop=times["stop"][:warm], event=times["event"][:warm],
                   offset=col["offset"][:warm])
    call = calls[task]
    before = peak_mb()
    t0 = time.perf_counter()
    call()
    first = time.perf_counter() - t0
    after = peak_mb()
    repeats = 5 if first < 10 else 3 if first < 60 else 1
    runs = []
    for _ in range(repeats):
        t0 = time.perf_counter()
        call()
        runs.append(time.perf_counter() - t0)
    print(json.dumps({"first_s": first, "median_s": statistics.median(runs), "min_s": min(runs), "max_s": max(runs),
                      "runs": len(runs), "peak_before_mb": before, "peak_after_mb": after,
                      "numba_threads": numba.get_num_threads()}))


def main():
    if sys.argv[1] == "--child":
        child(sys.argv[2], sys.argv[3])
        return
    data_root, out_file = sys.argv[1], sys.argv[2]
    only = re.compile(sys.argv[4]) if len(sys.argv) >= 5 and sys.argv[3] == "--only" else None
    scenarios = json.load(open(os.path.join(data_root, "scenarios.json"), encoding="utf-8"))
    rows = []
    for sc in scenarios:
        for task in TASKS:
            if task in PENALIZED_ONLY and not sc["penalized"]:
                continue
            label = f"{sc['id']} {task}"
            if only and not only.search(label):
                continue
            print(label, flush=True)
            proc = subprocess.run([sys.executable, __file__, "--child", os.path.join(data_root, sc["id"]), task],
                                  capture_output=True, text=True, timeout=7200)
            result = json.loads(proc.stdout.strip().splitlines()[-1]) if proc.returncode == 0 else {}
            rows.append({"scenario": sc["id"], "n": sc["n"], "providers": sc["m"], "covariates": sc["p"],
                         "task": task, "status": "ok" if proc.returncode == 0 else " ".join(proc.stderr.split())[-200:],
                         **{k: result.get(k) for k in ("first_s", "median_s", "min_s", "max_s", "runs",
                                                       "peak_before_mb", "peak_after_mb", "numba_threads")}})
            with open(out_file, "w", newline="", encoding="utf-8") as handle:
                writer = csv.DictWriter(handle, fieldnames=list(rows[0]))
                writer.writeheader()
                writer.writerows(rows)
    import platform
    from importlib import metadata
    commit = subprocess.run(["git", "rev-parse", "HEAD"], capture_output=True, text=True).stdout.strip()
    with open(out_file[:-4] + ".json", "w", encoding="utf-8", newline="\n") as handle:
        json.dump({"date": time.strftime("%Y-%m-%d"), "commit": commit, "python": sys.version.split()[0],
                   "platform": platform.platform(), "cpu": os.environ.get("PROCESSOR_IDENTIFIER", platform.processor()),
                   "logical_cores": os.cpu_count(),
                   "packages": {p: metadata.version(p) for p in ("pprof_py", "numpy", "scipy", "pandas", "numba")},
                   "threads": "numba's default (the CSV's numba_threads column)"}, handle, indent=1)
    print(f"wrote {out_file}")


if __name__ == "__main__":
    main()
