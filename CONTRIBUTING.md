# Contributing

Thanks for improving the CI/CD pipeline library. This repo is consumed by many other
repositories, so changes must preserve backward compatibility or be released under a new
major version.

## Adding a new reusable workflow

1. Create `.github/workflows/<name>.yml` with `on: workflow_call`.
2. Define an explicit **inputs / secrets / outputs contract**:
   - Every input has a `description`, `type`, and (unless required) a sensible `default`.
   - Declare only the secrets you actually use — avoid relying on `secrets: inherit`.
   - Set the **minimum** `permissions:` the workflow needs.
3. Add a doc under `docs/<name>.md` (inputs table, secrets, outputs, usage snippet).
4. Add at least one caller under `examples/` demonstrating a real `with:` / `secrets:` block.
5. Update `docs/pipeline-stages.md` and `ARCHITECTURE.md` if the stage graph changes.
6. Run `make lint` (and `make test` if you touched script logic).

### Contract consistency rule

An example caller that passes an input the reusable workflow does not declare — or a
reusable workflow that references `needs.<job>.outputs.<x>` without declaring that output —
is a real bug. `make lint` (actionlint) catches the local cases; cross-check example callers
against the target workflow's `inputs:` block by hand for remote `uses:` references.

## Local validation

```bash
make lint      # actionlint if installed, else a Python YAML + structural fallback
make fmt       # quick YAML parse sanity check
make test      # bump-release version-math tests
```

To install actionlint locally:

```bash
make install-actionlint   # downloads ./bin/actionlint
export PATH="$PWD/bin:$PATH"
make lint
```

## Versioning & tagging convention for consumers

Consumers pin `uses:` references to one of:

| Ref | Meaning | Who |
| --- | --- | --- |
| `@v1` | Floating major — latest non-breaking release | Most consumers |
| `@v1.4.0` | Immutable exact release | Reproducibility-sensitive repos |
| `@main` | Bleeding edge (may break) | This repo's own examples / testing |

We follow **Semantic Versioning**:

- `fix:` → patch, `feat:` → minor, `feat!:`/`BREAKING CHANGE:` → major.
- Breaking an input/secret/output contract (rename, remove, change required-ness) is a
  **major** bump.

Maintainers cut a release with either the `release.yml` workflow or locally:

```bash
scripts/bump-release.sh minor --push
```

`bump-release.sh` creates the new `vX.Y.Z` tag **and moves the floating `vX` tag** so
`@v1` consumers pick up the change.

## Testing a workflow change before merging

Because reusable workflows only run when called, test on a branch:

1. Push your change to a feature branch, e.g. `feat/new-cache`.
2. In a scratch/consumer repo, temporarily pin the caller to your branch:
   `uses: iarsingh/github-actions-devops-templates/.github/workflows/python-ci.yml@feat/new-cache`.
3. Trigger the consumer workflow and confirm the run is green.
4. Revert the scratch pin, open the PR, and let CI + review complete before merge.

## Commit style

Conventional Commits (`feat:`, `fix:`, `docs:`, `ci:`, `refactor:`, `chore:`) so
`release.yml` can compute the correct version bump.
