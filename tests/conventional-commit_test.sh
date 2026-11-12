#!/usr/bin/env bash

set -u

hook="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)/hooks/conventional-commit.sh"
tmp=$(mktemp)
trap 'rm -f "${tmp}"' EXIT

failures=0

# expect <pass|fail> <message>
expect() {
    local -r expected=$1
    local -r msg=$2
    local actual=pass

    printf '%b' "${msg}" > "${tmp}"
    "${hook}" "${tmp}" > /dev/null 2>&1 || actual=fail

    if [ "${actual}" != "${expected}" ]; then
        echo "FAIL: expected ${expected}, got ${actual}: ${msg}"
        failures=$((failures + 1))
    fi
}

expect pass 'feat: add x'
expect pass 'fix: x'
expect pass 'feat(foo): a'
expect pass 'feat(api-v2): add x'
expect pass 'fix(hooks/yamllint): lint files only'
expect pass 'feat!: drop support'
expect pass 'feat(foo)!: drop support'
# shellcheck disable=SC2016 # backticks are part of the message
expect pass 'fix: `cmd` broken'
expect pass 'revert: undo x'
expect pass 'docs: update\n\nlonger body that does not matter\n'
expect pass '\n# leading comment\n\nchore: bump'
expect pass "Merge branch 'main' into feature"
expect pass 'Revert "feat: add x"'
expect pass 'fixup! feat: add x'
expect pass 'squash! feat: add x'
expect pass '# only comments\n'
expect pass 'feat: x\n# ------------------------ >8 ------------------------\ndiff --git a/x b/x'

expect fail 'add x'
expect fail 'feature: add x'
expect fail 'Feat: add x'
expect fail 'feat:add x'
expect fail 'feat: '
expect fail 'feat:  x'
expect fail 'feat: x '
expect fail 'feat(): x'
expect fail 'feat(a b): x'
expect fail '# comment\nwip'

if [ "${failures}" -ne 0 ]; then
    echo "${failures} test(s) failed"
    exit 1
fi

echo "all tests passed"
