# Architecture

This repository is a **library of GitHub Actions reusable workflows** (`on: workflow_call`).
Application and infrastructure repositories across the org do **not** copy pipeline YAML;
they *call into* these workflows with a small `with:` / `secrets:` block. One place to fix,
one place to harden, one place to upgrade an action version.

## How a downstream repo calls in

```mermaid
flowchart TB
    subgraph consumer["Consumer repo (e.g. sample-app)"]
        cw[".github/workflows/ci-cd.yml<br/>(caller)"]
    end

    subgraph lib["iarsingh/github-actions-devops-templates"]
        py["python-ci.yml"]
        node["node-ci.yml"]
        tf["terraform-ci.yml"]
        db["docker-build.yml"]
        sec["security-scan.yml"]
        gke["deploy-gke.yml"]
        rel["release.yml"]
    end

    cw -- "uses: ...python-ci.yml@v1" --> py
    cw -- "uses: ...docker-build.yml@v1" --> db
    cw -- "uses: ...security-scan.yml@v1" --> sec
    cw -- "uses: ...deploy-gke.yml@v1" --> gke

    gke -- "OIDC / WIF" --> gcp[("GCP: WIF pool<br/>+ GKE cluster")]
    db -- "push image" --> reg[("Container registry<br/>GHCR / Artifact Registry")]
    sec -- "SARIF" --> ghsec[("GitHub code scanning")]
```

Consumers pin to a **floating major tag** (`@v1`) for automatic non-breaking updates, or to
`@main` for bleeding edge, or to an immutable `@v1.4.0` for maximum reproducibility.

## Full stage pipeline (chained via `needs:`)

```mermaid
flowchart LR
    A[Checkout] --> B[Lint]
    B --> C[Unit test]
    C --> D[Coverage]
    D --> E[SAST / CodeQL]
    E --> F[Dependency + Secret scan]
    F --> G[Docker build]
    G --> H[Container scan]
    H --> I[Push image]
    I --> J[Deploy staging]
    J --> K{Prod approval<br/>environment gate}
    K -->|approved| L[Deploy production]
    L --> M[Smoke test]
    M -->|failure| N[helm rollback]
    M -->|success| O[Done]
```

## Job dependency graph in `examples/app-ci-cd.yml`

```mermaid
flowchart LR
    ci[ci: python-ci] --> build[build: docker-build]
    build --> security[security: security-scan]
    build --> ds[deploy-staging: deploy-gke]
    security --> ds
    ds --> dp[deploy-production: deploy-gke<br/>needs build + deploy-staging]
    build -. image-tag output .-> ds
    build -. image-tag output .-> dp
    build -. image-tag output .-> security
```

## Design decisions

| Decision | Rationale |
| --- | --- |
| Reusable workflows over composite actions | Reusable workflows can define whole jobs, matrices, and their own permissions; composite actions run inside a single job's step list. |
| OIDC / Workload Identity Federation | No long-lived cloud keys stored as GitHub secrets. |
| Inputs have sane defaults | A consumer can adopt a workflow with a two-line call and override only what differs. |
| Outputs on `docker-build` | Downstream `security-scan` / `deploy-gke` consume the exact built `image-tag`, avoiding tag drift between build and deploy. |
| `fail-fast: false` on matrices | One interpreter/runtime failure still lets the rest report. |
| Rollback guarded by `steps.deploy.outcome == 'success'` | Only roll back when a previous good revision actually exists. |
| Pinned action versions + Dependabot | Reproducible runs, with a managed upgrade path. |

## Repository layout

```
.github/workflows/   # the 7 reusable workflows (the product)
examples/            # caller workflows a consumer copies into their repo
docs/                # per-workflow contracts + pipeline-stages.md
scripts/             # validate-workflows.sh, bump-release.sh
tests/               # shell-logic tests for bump-release
Makefile             # make lint / make test / make fmt
.github/dependabot.yml
```
