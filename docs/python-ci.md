# `python-ci.yml` — Reusable Python CI

Lint, test, and collect coverage for a Python project across a matrix of interpreter
versions.

## Stages

`Checkout → setup-python (pip cache) → install deps → lint (ruff/flake8) → pytest + coverage → upload coverage artifact → (optional) Codecov upload`

## Inputs

| Name | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `python-version-matrix` | string | no | `["3.11", "3.12"]` | JSON array of Python versions to run in parallel. |
| `working-directory` | string | no | `.` | Directory containing the project. |
| `lint-tool` | string | no | `ruff` | `ruff` or `flake8`. |
| `test-command` | string | no | `pytest --cov=. --cov-report=xml --cov-report=term-missing` | Test command. |
| `runs-on` | string | no | `ubuntu-latest` | Runner label(s). |
| `requirements-file` | string | no | `requirements.txt` | Optional pip requirements file (installed if present). |

## Secrets

| Name | Required | Description |
| --- | --- | --- |
| `CODECOV_TOKEN` | no | Codecov upload token. When empty the Codecov step is skipped (guarded via a job-level `HAS_CODECOV_TOKEN` env flag because the `secrets` context is not allowed in step `if:`). |

## Outputs

None.

## Usage

```yaml
jobs:
  python-ci:
    uses: iarsingh/github-actions-devops-templates/.github/workflows/python-ci.yml@v1
    with:
      python-version-matrix: '["3.11", "3.12"]'
      lint-tool: ruff
    secrets:
      CODECOV_TOKEN: ${{ secrets.CODECOV_TOKEN }}
```

## Notes

- `fail-fast: false` so one failing interpreter version does not cancel the others.
- The coverage artifact is named `coverage-py<version>` and uses `if-no-files-found: ignore`
  so a project without `coverage.xml` does not fail the run.
