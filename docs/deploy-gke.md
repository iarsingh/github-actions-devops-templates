# `deploy-gke.yml` — Reusable GKE Deployment

Deploys a Helm release to GKE using OIDC / Workload Identity Federation (no static
service-account keys), runs a retried smoke test, and **automatically rolls back** the
release if the deploy or smoke test fails.

## Stages

`Checkout → OIDC auth (WIF) → setup-gcloud + gke-gcloud-auth-plugin → get-gke-credentials → helm upgrade --install --wait → smoke test (retried curl) → helm rollback on failure → summary`

## Inputs

| Name | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `gcp-workload-identity-provider` | string | **yes** | — | WIF provider resource name. |
| `gcp-service-account` | string | **yes** | — | Deploy-only SA email to impersonate. |
| `gcp-project-id` | string | **yes** | — | Project that owns the cluster. |
| `cluster-name` | string | **yes** | — | GKE cluster name. |
| `cluster-location` | string | **yes** | — | Region or zone. |
| `release-name` | string | **yes** | — | Helm release name. |
| `chart-path` | string | **yes** | — | Chart path/reference. |
| `namespace` | string | no | `default` | Target namespace (created if missing). |
| `image` | string | **yes** | — | Image ref `name:tag` to deploy. |
| `values-file` | string | no | `''` | Optional extra values file. |
| `image-values-key` | string | no | `image.repository` | Helm key set to the image repo. |
| `health-check-url` | string | **yes** | — | URL curled by the smoke test. |
| `health-check-retries` | number | no | `10` | Smoke-test attempts (15s apart). |
| `helm-timeout` | string | no | `5m` | Timeout for `helm upgrade`/`rollback`. |
| `environment` | string | no | `''` | GitHub Environment (drives approval gates). |
| `runs-on` | string | no | `ubuntu-latest` | Runner label(s). |

## Secrets

None — auth is via OIDC.

## Permissions required (at the caller)

```yaml
permissions:
  contents: read
  id-token: write   # OIDC token minting
```

## Outputs

None. A deployment summary table is written to the job's `$GITHUB_STEP_SUMMARY`.

## Rollback semantics

The rollback step runs when:

```yaml
if: failure() && steps.deploy.outcome == 'success'
```

That is: the Helm upgrade succeeded (so a previous revision exists to roll back to) but a
**later** step failed — typically the smoke test. `helm rollback <release> 0` reverts to
the previous good revision. If the very first `helm upgrade` fails there is nothing to roll
back to, and the guard correctly skips the rollback.

## Usage

```yaml
permissions:
  contents: read
  id-token: write

jobs:
  deploy:
    uses: iarsingh/github-actions-devops-templates/.github/workflows/deploy-gke.yml@v1
    with:
      environment: production
      gcp-workload-identity-provider: projects/123/locations/global/workloadIdentityPools/github-pool/providers/github-provider
      gcp-service-account: gke-deployer@my-project.iam.gserviceaccount.com
      gcp-project-id: my-project
      cluster-name: platform-production
      cluster-location: europe-west1
      release-name: sample-app
      chart-path: ./charts/sample-app
      namespace: sample-app
      image: ghcr.io/iarsingh/sample-app:sha-abc123
      health-check-url: https://sample-app.example.com/healthz
```

## Approval gate

Set `environment: production` and configure **Required reviewers** on the `production`
GitHub Environment (Settings → Environments). GitHub then pauses the job for manual
approval before any cloud action runs.
