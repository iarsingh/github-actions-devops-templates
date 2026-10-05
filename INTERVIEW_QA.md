# github-actions-devops-templates — interview questions and answers

[README](README.md) · [Project architecture](PROJECT_ARCHITECTURE.md)

Answers below use this repository’s files and implementation. They distinguish existing behavior from suggested extensions; source links let you verify each walkthrough.

## 1. What problem does github-actions-devops-templates address, and what can you demonstrate?

Reusable GitHub Actions workflows for CI, security scanning, container builds, GKE deployments, releases, and rollback.

I would demonstrate the linked implementation or examples and distinguish that evidence from any planned production features. Start with [`README.md`](README.md).

## 2. How is this repository organized?

- [`scripts/bump-release.sh`](scripts/bump-release.sh): Implementation or supporting configuration.
- [`scripts/validate-workflows.sh`](scripts/validate-workflows.sh): Implementation or supporting configuration.
- [`Makefile`](Makefile): Implementation or supporting configuration.
- [`tests/bump-release_test.sh`](tests/bump-release_test.sh): Executable checks and regression examples.
- [`.github/workflows/deploy-gke.yml`](.github/workflows/deploy-gke.yml): GitHub Actions job definitions.
- [`.github/workflows/docker-build.yml`](.github/workflows/docker-build.yml): GitHub Actions job definitions.
- [`ARCHITECTURE.md`](ARCHITECTURE.md): Project explanations or operating notes.
- [`CONTRIBUTING.md`](CONTRIBUTING.md): Project explanations or operating notes.

[PROJECT_ARCHITECTURE.md](PROJECT_ARCHITECTURE.md) contains the component diagram and the implementation walkthrough.

## 3. Is this a running application or a reference repository?

The inspected checkout contains notes, examples, or source assets rather than an identified service entry point. I would describe the actual contents and avoid inventing a backend, database, or deployment. The architecture document records the components that exist.

## 4. What would you verify before extending this repository?

I would identify an executable example or define a concrete acceptance case for the material in [`README.md`](README.md). For code, verify inputs, outputs, and failure handling; for notes or templates, verify that a reader can follow the procedure and distinguish examples from measured results.

## 5. Which files provide verification evidence?

The repository includes [`tests/bump-release_test.sh`](tests/bump-release_test.sh). I would explain the scenarios and assertions in these files, then run the matching test command from the appropriate project directory. File presence alone is not a passing test result.

## 6. How do you separate the current design from a future production design?

The current design is the source/component map in [PROJECT_ARCHITECTURE.md](PROJECT_ARCHITECTURE.md). A future deployment needs explicit input contracts, persistence decisions, authentication, monitoring, and rollback. I would present these as proposed work until the corresponding implementation and verification exist.

## 7. How would you investigate data ownership and persistence?

Trace the data/configuration files and the code that reads or writes them in the component table. Identify which files are examples, which records are mutable, and which external store is actually configured. I would document those facts before discussing retention, backup, or tenant isolation.

## 8. How would another engineer reproduce your walkthrough?

Follow [`README.md`](README.md) and the linked component documents. This documentation update does not assert an application launch command for a repository without a verified launch contract.

## 9. What does automation verify, and what does it not prove?

Inspect [`.github/workflows/deploy-gke.yml`](.github/workflows/deploy-gke.yml), [`.github/workflows/docker-build.yml`](.github/workflows/docker-build.yml), [`.github/workflows/node-ci.yml`](.github/workflows/node-ci.yml), [`.github/workflows/python-ci.yml`](.github/workflows/python-ci.yml) for triggers, permissions, and job commands. I would name the checks that those definitions run and show the latest run separately. A workflow definition alone does not establish a successful deployment, security review, or production SLO.

## 10. How would you present this project in a Forward Deployed Engineer interview?

Start with the user and operational problem described in [`README.md`](README.md). Explain one constraint that changes the implementation, show the linked code or example, and walk through a success case and a failure case. Agree on a measurable acceptance criterion before expanding the solution, and leave a handoff with data boundaries and rollback ownership. Any proposed production or business metric should be identified as a target until measured.
