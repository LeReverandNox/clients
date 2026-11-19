# Local build helpers for the firefox-passkeys fork branch.
# Usage: make help

BRANCH      := firefox-passkeys
UPSTREAM    := upstream
BROWSER_DIR := apps/browser
ZIP         := $(BROWSER_DIR)/dist/oss-dist-firefox.zip
ADDON_ID    := bitwarden-passkeys@lereverandnox.local
# Firefox profiles to install into, separated by ':' (paths may contain
# spaces). Each needs xpinstall.signatures.required=false (Developer Edition /
# Nightly only).
FF_DIR      := $(HOME)/.mozilla/firefox
PROFILES    ?= $(FF_DIR)/653g2622.dev-edition-default:$(FF_DIR)/Np2HLnKR.Profile 1

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

install: package ## Install the build into the Firefox profile(s); restart Firefox to apply
	@IFS=:; for p in $(PROFILES); do \
		mkdir -p "$$p/extensions" && \
		cp $(ZIP) "$$p/extensions/.$(ADDON_ID).xpi.tmp" && \
		mv -f "$$p/extensions/.$(ADDON_ID).xpi.tmp" "$$p/extensions/$(ADDON_ID).xpi" && \
		echo "Installed into $$p"; \
	done
	@echo "Restart Firefox to load the new version."

all: update install ## update + install
