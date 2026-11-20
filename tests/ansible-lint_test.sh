#!/usr/bin/env bash

set -u

hook="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)/hooks/ansible-lint.sh"
work=$(mktemp -d)
trap 'rm -rf "${work}"' EXIT

# A stub ansible-lint records the directory it runs in and its arguments.
mkdir -p "${work}/bin"
cat > "${work}/bin/ansible-lint" <<'EOF'
#!/usr/bin/env bash
echo "$(pwd -P) $*" >> "${CALLS}"
exit "${STUB_EXIT:-0}"
EOF
chmod +x "${work}/bin/ansible-lint"
export PATH="${work}/bin:${PATH}"
export CALLS="${work}/calls"
export PRE_COMMIT_COLOR=never

# repo/
#   site.yml                    no config above it: the repo root is its project
#   ansible/.ansible-lint       a project
#   ansible/roles/a/tasks/main.yml
#   ansible/roles/b/tasks/main.yml
#   other/.config/ansible-lint.yml
#   other/play.yml
#   terraform/main.tf
repo="${work}/repo"
mkdir -p "${repo}/ansible/roles/a/tasks" "${repo}/ansible/roles/b/tasks" "${repo}/other/.config" "${repo}/terraform"
touch "${repo}/site.yml" "${repo}/ansible/.ansible-lint" "${repo}/ansible/roles/a/tasks/main.yml" \
  "${repo}/ansible/roles/b/tasks/main.yml" "${repo}/other/.config/ansible-lint.yml" "${repo}/other/play.yml" \
  "${repo}/terraform/main.tf"
repo=$(cd "${repo}" && pwd -P)

failures=0

# expect <expected calls, one per line> -- <hook args...>
expect() {
  local -r expected=$1
  shift 2
  : > "${CALLS}"
  (cd "${repo}" && "${hook}" "$@") > /dev/null 2>&1
  local -r actual=$(sort "${CALLS}")
  if [ "${actual}" != "$(echo "${expected}" | sort)" ]; then
    echo "FAIL: $*"
    echo "  expected: ${expected}"
    echo "  actual:   ${actual}"
    failures=$((failures + 1))
  fi
}

expect "${repo}/ansible " -- ansible/roles/a/tasks/main.yml
expect "${repo}/ansible " -- ansible/roles/a/tasks/main.yml ansible/roles/b/tasks/main.yml
expect "${repo}/ansible " -- ansible/.ansible-lint
expect "${repo}/other " -- other/play.yml
expect "${repo} " -- site.yml
expect "${repo} " -- terraform/main.tf
expect "${repo}/ansible --offline" -- --offline ansible/roles/a/tasks/main.yml
expect "${repo}/ansible --profile production" -- --profile production ansible/roles/a/tasks/main.yml
expect "$(printf '%s \n%s ' "${repo}/ansible" "${repo}/other")" -- ansible/roles/a/tasks/main.yml other/play.yml
expect "" --

# a failing project fails the hook, but every project is still linted
: > "${CALLS}"
(cd "${repo}" && STUB_EXIT=2 "${hook}" ansible/roles/a/tasks/main.yml other/play.yml) > /dev/null 2>&1
rc=$?
if [ "${rc}" -eq 0 ] || [ "$(wc -l < "${CALLS}")" -ne 2 ]; then
  echo "FAIL: a failing project must fail the hook after all projects ran (rc=${rc})"
  failures=$((failures + 1))
fi

if [ "${failures}" -gt 0 ]; then
  echo "${failures} test(s) failed"
  exit 1
fi
echo "all tests passed"
