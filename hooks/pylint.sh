#!/usr/bin/env bash

set -e

for file in "$@"; do
  pylint --disable=R,C,W,import-error "${file}"
done
