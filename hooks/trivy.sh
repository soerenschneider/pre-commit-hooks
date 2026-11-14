#!/usr/bin/env bash

set -e

# trivy scans directories recursively, so scan the whole repo once instead of
# every changed directory (pass_filenames is false in .pre-commit-hooks.yaml)
exec trivy filesystem --exit-code 1 "$@" .
