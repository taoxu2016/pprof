#!/usr/bin/env python3
"""Copy the Cox generator's imported inputs into dev/reference/cox/inputs/ from the pinned commits.

Files are read from the commits with `git show`, not from working trees, and inputs/SOURCES.json
records each one's repository, commit, path, license, and SHA-256; generate.py checks the hashes
before it reads an input. Rerun only to change a pin (with the project lead's approval).

Usage, from the repository root, with checkouts of pprof_spark and pprof_py:
    python dev/reference/cox/vendor_inputs.py <pprof_spark checkout> <pprof_py checkout>
"""
import hashlib
import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SOURCES = {
    "pprof_spark": {
        "repository": "https://github.com/UM-KevinHe/pprof_spark",
        "commit": "e917a68",
        "license": "MIT",
        "files": {f"{case}.csv": f"fixtures/cox/{case}/input.csv" for case in (
            "tiny-ties", "rc-unstratified", "rc-stratified", "rc-stratified-weights-offset",
            "lt-stratified", "lt-weights-offset")},
    },
    "pprof_py": {
        "repository": "https://github.com/UM-KevinHe/pprof_py",
        "commit": "9320766e35e5b385d596a2b75418192098a124c4",
        "license": "MIT",
        "files": {f"{name}.csv": f"pprof_py/r_reference/data/{name}.csv" for name in (
            "penalized_wide", "penalized_wide_foldid", "strata", "offset", "weights", "left_truncation",
            "combined", "competing_risks_simple", "competing_risks_truncated")},
    },
}


def main():
    checkouts = {"pprof_spark": sys.argv[1], "pprof_py": sys.argv[2]}
    record = {}
    for source, spec in SOURCES.items():
        out_dir = os.path.join(HERE, "inputs", source)
        os.makedirs(out_dir, exist_ok=True)
        files = {}
        for name, path in spec["files"].items():
            content = subprocess.run(["git", "-C", checkouts[source], "show", f"{spec['commit']}:{path}"],
                                     check=True, capture_output=True).stdout
            with open(os.path.join(out_dir, name), "wb") as handle:
                handle.write(content)
            files[name] = {"path": path, "sha256": hashlib.sha256(content).hexdigest()}
        record[source] = {k: v for k, v in spec.items() if k != "files"} | {"files": files}
    with open(os.path.join(HERE, "inputs", "SOURCES.json"), "w", encoding="utf-8", newline="\n") as handle:
        json.dump(record, handle, indent=1, sort_keys=True)
        handle.write("\n")


if __name__ == "__main__":
    main()
