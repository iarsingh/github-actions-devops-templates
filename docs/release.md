# `release.yml` — Reusable Release

Computes the next semantic version from Conventional Commits, creates the git tag,
and publishes a GitHub Release with generated notes.

## Stages

`Checkout (full history) → compute next version (github-tag-action) → create GitHub Release (action-gh-release) → summary`

## Inputs

| Name | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `release-branch` | string | no | `main` | Branch releases are cut from. |
| `tag-prefix` | string | no | `v` | Tag prefix (`v` ⇒ `v1.2.3`). |
| `default-bump` | string | no | `patch` | Bump when no conventional signal is found. |
| `prerelease` | boolean | no | `false` | Mark the Release as a prerelease. |
| `dry-run` | boolean | no | `false` | Compute only; do not tag or publish. |
| `runs-on` | string | no | `ubuntu-latest` | Runner label(s). |

## Secrets

None — uses the automatic `GITHUB_TOKEN` via `github.token`.

## Permissions required (at the caller)

```yaml
permissions:
  contents: write   # push tags + create releases
```

## Outputs

| Name | Description |
| --- | --- |
| `new-version` | Computed version without prefix, e.g. `1.4.0`. |
| `new-tag` | Created tag, e.g. `v1.4.0`. |

## Usage

```yaml
permissions:
  contents: write

jobs:
  release:
    uses: iarsingh/github-actions-devops-templates/.github/workflows/release.yml@v1
    with:
      default-bump: patch
```

## Conventional Commits mapping

| Commit prefix | Bump |
| --- | --- |
| `fix:` | patch |
| `feat:` | minor |
| `feat!:` / `BREAKING CHANGE:` | major |

## Relationship to `scripts/bump-release.sh`

`release.yml` automates tagging inside CI. `scripts/bump-release.sh` is the manual/local
equivalent used by maintainers to bump `vX.Y.Z` **and** move the floating major tag
(`vX`) that consumers pin to — see [CONTRIBUTING.md](../CONTRIBUTING.md).
