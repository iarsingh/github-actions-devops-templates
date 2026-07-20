.DEFAULT_GOAL := help
SHELL := /usr/bin/env bash

ACTIONLINT_VERSION ?= 1.7.7

.PHONY: help
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

.PHONY: lint
lint: ## Validate all workflow YAML (actionlint if present, else Python fallback)
	@bash scripts/validate-workflows.sh

.PHONY: install-actionlint
install-actionlint: ## Download actionlint into ./bin (best-effort, for local use)
	@mkdir -p bin
	@OS=$$(uname | tr '[:upper:]' '[:lower:]'); \
	 ARCH=$$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/'); \
	 URL="https://github.com/rhysd/actionlint/releases/download/v$(ACTIONLINT_VERSION)/actionlint_$(ACTIONLINT_VERSION)_$${OS}_$${ARCH}.tar.gz"; \
	 echo "Downloading $$URL"; \
	 curl -sSL "$$URL" | tar -xz -C bin actionlint; \
	 echo "Installed bin/actionlint"

.PHONY: test
test: ## Run shell-logic tests for scripts (bump-release version math)
	@bash tests/bump-release_test.sh

.PHONY: fmt
fmt: ## Check YAML files parse (quick sanity, no tool install)
	@for f in $$(find .github/workflows examples -name '*.yml'); do \
		python3 -c "import yaml,sys; yaml.safe_load(open('$$f'))" && echo "ok  $$f" || exit 1; \
	done

.PHONY: all
all: lint test ## Run lint + test
