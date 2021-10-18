#!/usr/bin/env bash

set -e

# Disable output not usually helpful when running in automation (such as guidance to run plan after init)
export TF_IN_AUTOMATION=1

# Store and return last failure from validate so this can validate every directory passed before exiting
VALIDATE_ERROR=0

for dir in $(echo "$@" | xargs -n1 dirname | sort -u | uniq); do
  echo "--> Running 'terraform validate' in directory '$dir'"
  pushd "$dir" >/dev/null
  terraform init -backend=false || VALIDATE_ERROR=$?
  terraform validate || VALIDATE_ERROR=$?
  popd >/dev/null
done

exit ${VALIDATE_ERROR}
