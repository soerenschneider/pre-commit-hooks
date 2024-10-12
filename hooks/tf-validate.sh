#!/usr/bin/env bash

set -e

# Disable output not usually helpful when running in automation (such as guidance to run plan after init)
export TF_IN_AUTOMATION=1

# Store and return last failure from validate so this can validate every directory passed before exiting
VALIDATE_ERROR=0

# Check if OpenTofu is available, otherwise fall back to Terraform
TOOL="tofu"
if ! command -v $TOOL &> /dev/null; then
  TOOL="terraform"
fi

for dir in $(echo "$@" | xargs -n1 dirname | sort -u | uniq); do
  echo "--> Running '$TOOL validate' in directory '$dir'"
  pushd "$dir" >/dev/null
  $TOOL init -backend=false || VALIDATE_ERROR=$?
  $TOOL validate || VALIDATE_ERROR=$?
  popd >/dev/null
done

exit ${VALIDATE_ERROR}
