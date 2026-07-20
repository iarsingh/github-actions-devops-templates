# `docker-build.yml` — Reusable Docker Build & Push

Build (and optionally push) a container image with Buildx, using the GitHub Actions
cache backend to avoid redundant layer rebuilds. Exposes the image tag and digest as
job **outputs** so downstream jobs (scan, deploy) can consume them.

## Stages

`Checkout → (QEMU if multi-arch) → Buildx → registry login → metadata (tags/labels) → build-push-action (cache-from/to gha)`

## Inputs

| Name | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `image-name` | string | **yes** | — | Fully-qualified image name without tag. |
| `context` | string | no | `.` | Build context path. |
| `dockerfile` | string | no | `Dockerfile` | Dockerfile path relative to the context. |
| `platforms` | string | no | `linux/amd64` | Comma-separated target platforms. |
| `push` | boolean | no | `true` | Push to the registry (else build/load only). |
| `registry` | string | no | `ghcr.io` | Registry to log in to. Empty ⇒ skip login. |
| `build-args` | string | no | `''` | Newline-separated build args. |
| `runs-on` | string | no | `ubuntu-latest` | Runner label(s). |

## Secrets

| Name | Required | Description |
| --- | --- | --- |
| `registry-username` | no | Defaults to `github.actor`. |
| `registry-password` | no | Defaults to the automatic `GITHUB_TOKEN` (works for `ghcr.io`). |

## Outputs

| Name | Description |
| --- | --- |
| `image-tag` | Primary reference `image-name:sha-<commit>`. |
| `image-digest` | Content-addressable digest from `build-push-action`. |

## Usage (with downstream consumption)

```yaml
jobs:
  build:
    uses: iarsingh/github-actions-devops-templates/.github/workflows/docker-build.yml@v1
    with:
      image-name: ghcr.io/iarsingh/sample-app
      platforms: linux/amd64
      push: true

  deploy:
    needs: build
    uses: iarsingh/github-actions-devops-templates/.github/workflows/deploy-gke.yml@v1
    with:
      image: ${{ needs.build.outputs.image-tag }}
      # ...remaining deploy inputs
```

## Notes

- QEMU is only set up when `platforms` contains `arm`, keeping single-arch builds fast.
- `load` is enabled only for single-platform, non-push builds (Buildx cannot `--load`
  a multi-platform image).
- Caller must grant `permissions: packages: write` for GHCR pushes.
