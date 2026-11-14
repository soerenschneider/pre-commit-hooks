#!/usr/bin/env bash

set -e
set -o pipefail

# pre-commit passes hook args first, followed by the filenames. Filenames
# always end in .tf (see `files` in .pre-commit-hooks.yaml), everything
# else is passed through to checkov.
ARGS=()
FILES=()
for arg in "$@"; do
  if [[ "${arg}" == *.tf && -f "${arg}" ]]; then
    FILES+=("${arg}")
  else
    ARGS+=("${arg}")
  fi
done

if [ "${PRE_COMMIT_COLOR}" = "never" ]; then
  export ANSI_COLORS_DISABLED=true
fi

# terraform resources span all files of a module, so scan each directory once
exit_code=0
while IFS= read -r dir; do
  checkov -d "${dir}" ${ARGS[@]+"${ARGS[@]}"} < /dev/null || exit_code=$?
done < <(for file in ${FILES[@]+"${FILES[@]}"}; do dirname "${file}"; done | sort -u)

exit ${exit_code}
