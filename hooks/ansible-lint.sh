#!/usr/bin/env bash

set -e
set -o pipefail

# ansible-lint lints a whole project at once and has to run from the project's
# directory, where it finds its config, roles and collections (passing single
# files does not work, see https://github.com/ansible/ansible-lint/issues/611).
#
# pre-commit passes hook args first, followed by the changed files. Each file is
# mapped to its project: the closest directory above it that holds an
# ansible-lint config, or the repo root if there is none. Every project with a
# changed file is then linted once, so in a monorepo only ansible/ is linted
# when ansible/.ansible-lint exists, not the whole repository.
ARGS=()
FILES=()
for arg in "$@"; do
  if [[ -f "${arg}" ]]; then
    FILES+=("${arg}")
  else
    ARGS+=("${arg}")
  fi
done

if [ "${PRE_COMMIT_COLOR}" != "never" ]; then
  ARGS+=(--force-color)
fi

has_config() {
  local -r dir=$1
  [[ -f "${dir}/.ansible-lint" || -f "${dir}/.ansible-lint.yml" || -f "${dir}/.ansible-lint.yaml" ||
    -f "${dir}/.config/ansible-lint.yml" || -f "${dir}/.config/ansible-lint.yaml" ]]
}

# prints the project directory of a file, relative to the repo root
project_of() {
  local dir
  dir=$(dirname "$1")
  while [[ "${dir}" != "." ]]; do
    if has_config "${dir}"; then
      echo "${dir}"
      return
    fi
    dir=$(dirname "${dir}")
  done
  echo "."
}

exit_code=0
while IFS= read -r project; do
  (cd "${project}" && ansible-lint ${ARGS[@]+"${ARGS[@]}"}) || exit_code=$?
done < <(for file in ${FILES[@]+"${FILES[@]}"}; do project_of "${file}"; done | sort -u)

exit ${exit_code}
