#!/usr/bin/env bash
# CoxPH brief, Appendix A: pprof_py v0.7.0's survival test suite, run in its checkout without writing
# into it (no bytecode, no pytest cache; numba's cache goes to NUMBA_CACHE_DIR, by default in the
# scratch directory).
# Found on 2026-10-07 under Python 3.9.7: 283 passed, 1 skipped (lifelines is not installed), 1 failed.
# The failure is test_run_validation_end_to_end_single_stage, which runs R when Rscript is on the PATH:
# pprof_py's R-comparison harness writes Windows paths into the R script unescaped
# (diagnostics/survival/validate_against_r.py:135), and R stops on '\U'. Without Rscript on the PATH
# the test skips R and passes (284 passed).
# Run from the repository root: bash dev/design/coxph-facts/01_pprof_py_suite.sh <output file>
set -euo pipefail
out="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
: "${COXPH_FACTS_SCRATCH:?Set COXPH_FACTS_SCRATCH (see README.md)}"
PPROF_PY="${PPROF_PY:-../../pprof_py}"
PYTHON="${PYTHON:-python}"
NUMBA_CACHE_DIR="${NUMBA_CACHE_DIR:-$COXPH_FACTS_SCRATCH/nbc}"
mkdir -p "$NUMBA_CACHE_DIR"
cd "$PPROF_PY"
{
  echo "pprof_py $(git describe --tags --always) ($(git rev-parse --short HEAD))"
  "$PYTHON" -c "import sys, numpy, scipy, pandas, numba; print('Python', sys.version.split()[0], '| numpy', numpy.__version__, '| scipy', scipy.__version__, '| pandas', pandas.__version__, '| numba', numba.__version__)"
  PYTHONDONTWRITEBYTECODE=1 NUMBA_CACHE_DIR="$NUMBA_CACHE_DIR" MPLBACKEND=Agg \
    "$PYTHON" -m pytest pprof_py/tests/survival pprof_py/tests/inference/test_survival_empirical_null.py \
    -q -p no:cacheprovider -rfEs 2>&1 | grep -a -E "^(FAILED|ERROR|SKIPPED)|passed|failed" || true
  echo "Files changed in the pprof_py checkout by the run: $(git status --porcelain | wc -l)"
} > "$out"
