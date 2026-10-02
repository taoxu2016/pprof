#!/bin/sh
# Run every Phase 0 audit script against the reference library in $PPROF_REF_LIB.
# Usage, from the repository root: PPROF_REF_LIB=<library-dir> sh dev/design/audit/run_all.sh
set -e
: "${PPROF_REF_LIB:?set PPROF_REF_LIB to the library that holds pprof 1.0.3}"
out=dev/design/audit/output
mkdir -p "$out"
for script in 10_logistic_fe_fit 11_logistic_fe_stopping 12_firth 13_logistic_fe_inference \
              14_linear_fe 15_random_effects 16_misc 20_bench_phase0; do
  echo "== $script"
  Rscript "dev/design/audit/$script.R" > "$out/$script.log" 2>&1
  grep -E "^\[(V|B)[0-9]" "$out/$script.log" | cut -c1-100
done
