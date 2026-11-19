# Local build helpers for the firefox-passkeys fork branch.
# Usage: make help

BRANCH      := firefox-passkeys
UPSTREAM    := upstream
BROWSER_DIR := apps/browser
ZIP         := $(BROWSER_DIR)/dist/oss-dist-firefox.zip
INSTALL_DIR := $(HOME)/.local/share/bitwarden-firefox
XPI         := $(INSTALL_DIR)/bitwarden-passkeys.xpi

.DEFAULT_GOAL := help
.PHONY: help update deps build dev package install all

help: ## Show this help
	@grep -E '^[a-z-]+:.*##' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-10s %s\n", $$1, $$2}'

update: ## Rebase the patch branch onto upstream/main
	@test -z "$$(git status --porcelain --untracked-files=no)" || { echo "Working tree not clean"; exit 1; }
	git checkout $(BRANCH)
	git fetch $(UPSTREAM) main
	git rebase $(UPSTREAM)/main

node_modules/.package-lock.json: package-lock.json
	npm ci

deps: node_modules/.package-lock.json ## Install npm deps when the lockfile changed

build: deps ## Production build of the Firefox extension
	cd $(BROWSER_DIR) && npm run build:prod:firefox

dev: deps ## Dev build in watch mode (use with about:debugging)
	cd $(BROWSER_DIR) && npm run build:watch:firefox

package: deps ## Build and zip the extension
	cd $(BROWSER_DIR) && npm run dist:firefox

install: package ## Copy the zip to $(XPI)
	mkdir -p $(INSTALL_DIR)
	cp $(ZIP) $(XPI)
	@echo "Installed: $(XPI)"
	@echo "Firefox: about:addons > gear > Install Add-on From File..."

all: update install ## update + install
