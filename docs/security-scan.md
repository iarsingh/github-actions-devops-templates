# `security-scan.yml` — Reusable Security Scanning

Runs four independent scan jobs and uploads results as SARIF to the GitHub
code-scanning (Security) tab.

## Jobs

| Job | Tool | Purpose |
| --- | --- | --- |
| `trivy-fs` | Trivy | Filesystem/dependency vulnerability scan. |
| `gitleaks` | Gitleaks | Secret scanning across git history. |
| `codeql` | CodeQL | SAST (matrix over languages), conditional on `run-codeql`. |
| `trivy-image` | Trivy | Container image scan, conditional on `scan-image`. |

## Inputs

| Name | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `working-directory` | string | no | `.` | Directory for the filesystem scan. |
| `run-codeql` | boolean | no | `true` | Run CodeQL SAST. |
| `codeql-languages` | string | no | `["python"]` | JSON array of CodeQL languages. |
| `scan-image` | boolean | no | `false` | Run the Trivy image scan. Requires `image-ref`. |
| `image-ref` | string | no | `''` | Image to scan when `scan-image` is true. |
| `severity` | string | no | `CRITICAL,HIGH` | Trivy severities that count as findings. |
| `fail-on-findings` | boolean | no | `false` | Fail the job on findings at/above `severity`. |
| `runs-on` | string | no | `ubuntu-latest` | Runner label(s). |

## Secrets

None.

## Permissions required (at the caller)

```yaml
permissions:
  contents: read
  security-events: write  # SARIF upload
```

## Outputs

None.

## Usage

```yaml
permissions:
  contents: read
  security-events: write

jobs:
  security:
    needs: build
    uses: iarsingh/github-actions-devops-templates/.github/workflows/security-scan.yml@v1
    with:
      run-codeql: true
      codeql-languages: '["python"]'
      scan-image: true
      image-ref: ${{ needs.build.outputs.image-tag }}
```

## Notes

- The `trivy-image` job validates that `image-ref` is non-empty and fails fast with a
  clear `::error::` annotation if `scan-image` is true but no reference was supplied.
- SARIF categories (`trivy-fs`, `trivy-image`, per-language CodeQL) keep results
  separated in the Security tab.
