#!/usr/bin/env bash

set -e

for file in "$@"; do
  yamllint --no-warnings "./$(dirname "${file}")"
done
