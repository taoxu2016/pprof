#!/usr/bin/env bash
# CoxPH brief, Appendix A: pprof_py's comparison tests against glmnet
# (pprof_py/tests/survival/test_penalized_r_comparison.py), run against the glmnet results that 02
# regenerated with the installed glmnet instead of the committed glmnet 4.1-8 results. The test file
# is copied to the scratch directory with its two data paths redirected; nothing else changes.
# Found on 2026-10-07 with glmnet 5.1: 12 tests pass; test_cross_validation fails on lambda_1se
# (difference 2.7e-2, tolerance 1e-6).
# Run from the repository root, after 02: bash dev/design/coxph-facts/03_glmnet_reference_tests.sh <output file>
set -euo pipefail
out="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
: "${COXPH_FACTS_SCRATCH:?Set COXPH_FACTS_SCRATCH (see README.md)}"
# An absolute path Python can read (pwd -W gives C:/... in Git Bash on Windows).
PPROF_PY="$(cd "${PPROF_PY:-../../pprof_py}" && (pwd -W 2>/dev/null || pwd))"
PYTHON="${PYTHON:-python}"
work="$COXPH_FACTS_SCRATCH/glmnet_tests"
NUMBA_CACHE_DIR="${NUMBA_CACHE_DIR:-$COXPH_FACTS_SCRATCH/nbc}"
mkdir -p "$work" "$NUMBA_CACHE_DIR"
sed -e "s#^DATA = .*#DATA = r'$COXPH_FACTS_SCRATCH/r_reference/data'#" \
    -e "s#^RESULTS = .*#RESULTS = r'$COXPH_FACTS_SCRATCH/r_reference/results'#" \
    "$PPROF_PY/pprof_py/tests/survival/test_penalized_r_comparison.py" > "$work/test_penalized_installed_glmnet.py"
redirected=$(grep -c -E "^(DATA|RESULTS) = r'" "$work/test_penalized_installed_glmnet.py" || true)
{
  echo "glmnet results: those 02 regenerated (data paths redirected in the copied test file: $redirected of 2)"
  (cd "$work" && PYTHONPATH="$PPROF_PY" PYTHONDONTWRITEBYTECODE=1 NUMBA_CACHE_DIR="$NUMBA_CACHE_DIR" \
    "$PYTHON" -m pytest test_penalized_installed_glmnet.py -q -p no:cacheprovider -rf 2>&1 |
    grep -a -E "^(FAILED|ERROR)|passed|failed|^E +AssertionError" || true)
} > "$out"
