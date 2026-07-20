# `terraform-ci.yml` — Reusable Terraform CI

Format-check, validate, lint, security-scan, and plan a Terraform root module.
Cloud access (for `plan` against a real backend) uses OIDC / Workload Identity
Federation only — no static credentials.

## Stages

`Checkout → (optional OIDC auth to GCP) → fmt -check → init → validate → tflint → checkov|tfsec (SARIF) → plan`

## Inputs

| Name | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `working-directory` | string | no | `.` | Terraform root module directory. |
| `terraform-version` | string | no | `1.9.5` | Terraform version to install. |
| `scanner` | string | no | `checkov` | `checkov` or `tfsec`. |
| `run-plan` | boolean | no | `true` | Run `terraform plan`. When `false`, `init` uses `-backend=false`. |
| `gcp-workload-identity-provider` | string | no | `''` | WIF provider resource name. Empty ⇒ skip GCP auth. |
| `gcp-service-account` | string | no | `''` | Service account email to impersonate. |
| `runs-on` | string | no | `ubuntu-latest` | Runner label(s). |

## Secrets

None — cloud auth is via OIDC.

## Permissions required (at the caller)

```yaml
permissions:
  contents: read
  id-token: write         # OIDC token minting
  pull-requests: write    # plan summary comment
  security-events: write  # scanner SARIF upload
```

## Outputs

None. (The plan is written to `tfplan` inside the job.)

## Usage

```yaml
permissions:
  contents: read
  id-token: write
  pull-requests: write
  security-events: write

jobs:
  terraform:
    uses: iarsingh/github-actions-devops-templates/.github/workflows/terraform-ci.yml@v1
    with:
      working-directory: environments/staging
      scanner: checkov
      run-plan: true
      gcp-workload-identity-provider: projects/123/locations/global/workloadIdentityPools/github-pool/providers/github-provider
      gcp-service-account: terraform-plan@my-project.iam.gserviceaccount.com
```

## Notes

- SARIF upload uses `continue-on-error: true` so scanner findings surface in the
  Security tab without hard-failing the CI job unless you choose to enforce it.
