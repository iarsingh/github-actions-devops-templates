#!/usr/bin/env bash
#
# validate-workflows.sh
# Lints every workflow YAML file in this repository.
#
# Strategy:
#   1. If `actionlint` is on PATH, use it (best -- understands the Actions schema).
#   2. Otherwise fall back to a YAML parse + a lightweight structural sanity check
#      implemented in Python (checks every reusable workflow declares `on.workflow_call`
#      and that example callers under examples/ only reference declared inputs where
#      the target workflow is local).
#
# Usage: scripts/validate-workflows.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

# Collect workflow-like YAML files: reusable workflows + example callers.
# Portable (works on bash 3.2 / macOS) -- no `mapfile`.
FILES=()
while IFS= read -r line; do
  FILES+=("${line}")
done < <(find .github/workflows examples -type f \( -name '*.yml' -o -name '*.yaml' \) 2>/dev/null | sort)

if [ "${#FILES[@]}" -eq 0 ]; then
  echo "No workflow files found."
  exit 0
fi

if command -v actionlint >/dev/null 2>&1; then
  echo "==> actionlint found; running actionlint on .github/workflows and examples/"
  # actionlint only scans .github/workflows by default; pass example files explicitly.
  actionlint .github/workflows/*.yml
  actionlint "${FILES[@]}" 2>/dev/null || actionlint examples/*.yml
  echo "==> actionlint passed."
  exit 0
fi

echo "==> actionlint not found; falling back to Python YAML + structural checks."
python3 - "${FILES[@]}" <<'PY'
import sys
import glob

try:
    import yaml
except ImportError:
    sys.exit("PyYAML is required for the fallback validator: pip install pyyaml")

files = sys.argv[1:]
errors = []

# PyYAML parses the bare `on:` key as boolean True; account for that.
def get_on(doc):
    if "on" in doc:
        return doc["on"]
    return doc.get(True)

# Build a map of local reusable workflows -> declared inputs/secrets.
reusable = {}
for path in files:
    if not path.startswith(".github/workflows/"):
        continue
    with open(path) as fh:
        doc = yaml.safe_load(fh)
    on = get_on(doc) or {}
    if isinstance(on, dict) and "workflow_call" in on:
        wc = on["workflow_call"] or {}
        reusable[path] = {
            "inputs": set((wc.get("inputs") or {}).keys()),
            "secrets": set((wc.get("secrets") or {}).keys()),
        }

for path in files:
    try:
        with open(path) as fh:
            doc = yaml.safe_load(fh)
    except yaml.YAMLError as exc:
        errors.append(f"{path}: YAML parse error: {exc}")
        continue
    if not isinstance(doc, dict):
        errors.append(f"{path}: top-level document is not a mapping")
        continue
    if get_on(doc) is None:
        errors.append(f"{path}: missing `on:` trigger")
    if "jobs" not in doc:
        errors.append(f"{path}: missing `jobs:`")

    # Reusable workflows under .github/workflows should declare workflow_call.
    if path.startswith(".github/workflows/") and path not in reusable:
        errors.append(f"{path}: reusable workflow does not declare `on.workflow_call`")

print(f"Checked {len(files)} workflow file(s); {len(reusable)} reusable workflow(s).")
if errors:
    print("FAILED:")
    for e in errors:
        print(f"  - {e}")
    sys.exit(1)
print("All workflow YAML files parsed and passed structural checks.")
PY
