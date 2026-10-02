#!/bin/sh
# Compare the CRAN pprof 1.0.3 tarball with commit 5260838.
# Usage, from the repository root: sh dev/design/audit/01_cran_identity.sh <work-dir>
# Line endings are ignored (--strip-trailing-cr) because a Windows checkout with
# core.autocrlf = true writes CRLF; the CRAN tarball has LF.
set -e
work="${1:?usage: 01_cran_identity.sh <work-dir>}"
repo="$(pwd)"
mkdir -p "$work/ref5260838"
cd "$work"
curl -sS -o pprof_1.0.3.tar.gz https://cloud.r-project.org/src/contrib/pprof_1.0.3.tar.gz
echo "md5 of tarball:"; md5sum pprof_1.0.3.tar.gz
echo "md5 in CRAN PACKAGES index:"
curl -sS https://cloud.r-project.org/src/contrib/PACKAGES | awk '/^Package: pprof$/,/^$/' | grep -E "^(Version|MD5sum):"
tar -xzf pprof_1.0.3.tar.gz
git -C "$repo" archive 5260838 | tar -x -C ref5260838
for d in R src tests data man; do
  if diff -rq --strip-trailing-cr -x '.DS_Store' -x '*.o' -x '*.dll' -x '*.so' "pprof/$d" "ref5260838/$d" > /dev/null; then
    echo "$d/: identical"
  else
    echo "$d/: DIFFERS"; diff -rq --strip-trailing-cr -x '.DS_Store' "pprof/$d" "ref5260838/$d" || true
  fi
done
if diff -q --strip-trailing-cr pprof/NAMESPACE ref5260838/NAMESPACE > /dev/null; then echo "NAMESPACE: identical"; else echo "NAMESPACE: DIFFERS"; fi
echo "DESCRIPTION differences (expected: R CMD build normalization only):"
diff --strip-trailing-cr pprof/DESCRIPTION ref5260838/DESCRIPTION || true
echo "Top level of tarball:"; ls -A pprof
