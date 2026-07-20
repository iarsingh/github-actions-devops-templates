#!/usr/bin/env bash
#
# Tests for scripts/bump-release.sh version math.
# Creates a throwaway git repo, seeds a tag, runs the (local, no --push) bump,
# and asserts the resulting tags.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="${REPO_ROOT}/scripts/bump-release.sh"
FAILURES=0

run_case() {
  local seed="$1" bump="$2" expect_tag="$3" expect_major="$4"
  local tmp
  tmp="$(mktemp -d)"
  (
    cd "${tmp}"
    git init -q
    git config user.email t@t.io
    git config user.name test
    git commit -q --allow-empty -m init
    if [ -n "${seed}" ]; then
      git tag "${seed}"
    fi
    bash "${SCRIPT}" "${bump}" >/dev/null 2>&1
    if ! git rev-parse -q --verify "refs/tags/${expect_tag}" >/dev/null; then
      echo "FAIL: seed=${seed} bump=${bump}: expected tag ${expect_tag} not created"
      exit 1
    fi
    if ! git rev-parse -q --verify "refs/tags/${expect_major}" >/dev/null; then
      echo "FAIL: seed=${seed} bump=${bump}: expected floating tag ${expect_major} not created"
      exit 1
    fi
    echo "PASS: seed=${seed:-<none>} bump=${bump} -> ${expect_tag} (+${expect_major})"
  ) || FAILURES=$((FAILURES + 1))
  rm -rf "${tmp}"
}

run_case "v1.2.3" patch "v1.2.4" "v1"
run_case "v1.2.3" minor "v1.3.0" "v1"
run_case "v1.2.3" major "v2.0.0" "v2"
run_case ""        patch "v0.0.1" "v0"

if [ "${FAILURES}" -gt 0 ]; then
  echo "${FAILURES} test case(s) failed."
  exit 1
fi
echo "All bump-release test cases passed."
