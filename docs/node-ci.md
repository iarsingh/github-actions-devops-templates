# `node-ci.yml` — Reusable Node.js CI

Install, lint, test, and build a Node.js project across a matrix of Node versions.

## Stages

`Checkout → setup-node (npm/yarn/pnpm cache) → install → lint → test → build → (optional) upload build artifact`

## Inputs

| Name | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `node-version-matrix` | string | no | `["18", "20"]` | JSON array of Node versions. |
| `working-directory` | string | no | `.` | Directory containing `package.json`. |
| `package-manager` | string | no | `npm` | `npm`, `yarn`, or `pnpm`. Drives cache key and install command. |
| `lint-command` | string | no | `npm run lint` | Lint command. |
| `test-command` | string | no | `npm test` | Test command. |
| `build-command` | string | no | `npm run build` | Build command. |
| `upload-build-artifact` | boolean | no | `false` | Upload the build output as an artifact. |
| `build-artifact-path` | string | no | `dist` | Path (relative to working-directory) to upload. |
| `runs-on` | string | no | `ubuntu-latest` | Runner label(s). |

## Secrets

None.

## Outputs

None.

## Usage

```yaml
jobs:
  node-ci:
    uses: iarsingh/github-actions-devops-templates/.github/workflows/node-ci.yml@v1
    with:
      node-version-matrix: '["18", "20"]'
      package-manager: npm
      upload-build-artifact: true
      build-artifact-path: dist
```

## Notes

- Uses `npm ci` / `yarn install --frozen-lockfile` / `pnpm install --frozen-lockfile`
  for reproducible installs; a lockfile is expected.
- `cache-dependency-path` is anchored to `working-directory` so monorepo sub-packages
  cache correctly.
