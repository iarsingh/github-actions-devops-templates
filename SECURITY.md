# Security

This library is designed so that consuming repositories inherit strong security defaults
without extra effort.

## OIDC over static cloud credentials

`terraform-ci.yml` and `deploy-gke.yml` authenticate to Google Cloud with
**Workload Identity Federation** via `google-github-actions/auth@v2`. No service-account
JSON keys are ever stored in GitHub secrets. The runner exchanges its short-lived GitHub
OIDC token for a short-lived Google access token scoped to a specific service account.

Requirements at the consumer:

```yaml
permissions:
  id-token: write   # allow the runner to mint an OIDC token
  contents: read
```

## Least-privilege Workload Identity

- Bind the WIF provider to a **specific repository** (and ideally a specific branch or
  environment) via the provider's attribute condition, e.g.
  `attribute.repository == 'iarsingh/sample-app'`.
- Grant the impersonated service account only the roles it needs:
  - Terraform plan SA: read + plan roles.
  - GKE deploy SA: `roles/container.developer` (deploy) — not cluster-admin.
- Use **separate** service accounts and WIF bindings per environment (staging vs prod).

## Secret handling: `secrets: inherit` vs explicit pass-through

- **Explicit pass-through (preferred here):** each reusable workflow declares the exact
  secrets it accepts (e.g. `CODECOV_TOKEN`, `registry-username/password`) and the caller
  passes only those. This keeps the blast radius minimal and the contract auditable.
- **`secrets: inherit`:** forwards *all* caller secrets to the reusable workflow. Convenient
  but broad — avoid it for third-party or wide-scope workflows. Prefer naming secrets.
- Optional secrets are guarded: `python-ci.yml` maps `CODECOV_TOKEN` to a job-level
  `HAS_CODECOV_TOKEN` env flag (the `secrets` context is not permitted in step `if:`), so
  the upload step is skipped cleanly when the token is absent.

## Scanning coverage

| Layer | Tool | Where |
| --- | --- | --- |
| SAST | CodeQL | `security-scan.yml` |
| Dependencies / filesystem | Trivy (fs) | `security-scan.yml` |
| Container image | Trivy (image) | `security-scan.yml` |
| Secrets in git history | Gitleaks | `security-scan.yml` |
| IaC misconfiguration | Checkov / tfsec | `terraform-ci.yml` |
| Action/dep freshness | Dependabot | `.github/dependabot.yml` |

All code/dependency/container findings are uploaded as **SARIF** to the GitHub code-scanning
(Security) tab with distinct categories.

## Environment approvals

Production deploys bind to a GitHub **Environment**. Configure *Required reviewers* and, if
desired, a wait timer and deployment-branch restriction on that environment so a human must
approve before any production cloud action executes.

## Pinned dependencies

Every third-party action is pinned to a released version; Dependabot opens grouped PRs to
move them forward. For higher assurance, consumers may pin actions to a commit SHA.

## Reporting a vulnerability

Please **do not** open a public issue for security problems. Report privately via GitHub
Security Advisories ("Report a vulnerability" on the repo's Security tab) or email the
maintainer. Include reproduction steps and affected workflow/version. We aim to acknowledge
within 3 business days and to ship a fix or mitigation promptly, crediting reporters who
wish to be named.
