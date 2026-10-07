"""Shared setup for the Python fact scripts: import this before pprof_py.

Puts the pprof_py checkout named by PPROF_PY (default ../../pprof_py, relative to the repository
root) on sys.path, and keeps numba's JIT compiler but turns off its on-disk cache and Python's
bytecode files, so that nothing is written into that checkout. SCRATCH is the directory the R and
Python scripts share for generated data and intermediate results (COXPH_FACTS_SCRATCH).
"""
import os
import sys

import numba

PPROF_PY = os.path.abspath(os.environ.get("PPROF_PY", os.path.join("..", "..", "pprof_py")))
SCRATCH = os.environ.get("COXPH_FACTS_SCRATCH", "")
if not SCRATCH:
    raise SystemExit("Set COXPH_FACTS_SCRATCH to a scratch directory (see README.md).")
os.makedirs(SCRATCH, exist_ok=True)

sys.dont_write_bytecode = True
_njit = numba.njit


def _njit_without_cache(*args, **kwargs):
    kwargs.pop("cache", None)
    return _njit(*args, **kwargs)


numba.njit = _njit_without_cache
sys.path.insert(0, PPROF_PY)


def read_csv(path):
    """Read a CSV the way R does: pandas' default parser can differ from R's by one unit in the
    last place, which can change which times are tied."""
    import pandas as pd

    return pd.read_csv(path, float_precision="round_trip")


def write_lines(path, lines):
    with open(path, "w", encoding="utf-8", newline="\n") as handle:
        handle.write("\n".join(lines) + "\n")
