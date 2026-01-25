# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------

# Shell settings: fail on error, pipefail
SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

# Swift Format Settings
SWIFT_FORMAT_OPTIONS := -i -p --ignore-unparsable-files --configuration .swift-format
SWIFT_FORMAT_TARGETS := ./Sources ./Tests

# Docker Settings
DOCKER_IMAGE := swift:latest

# Visuals
RED    := \033[31m
GREEN  := \033[32m
YELLOW := \033[33m
RESET  := \033[0m

# ------------------------------------------------------------------------------
# Meta Targets
# ------------------------------------------------------------------------------

.PHONY: all help check-clean merge-main format test-on-linux generate build test

# Default target runs help
all: help

# auto-doc: Parses comments starting with '##' to generate a help menu
help:
	@echo "$(YELLOW)Available commands:$(RESET)"
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(RESET) %s\n", $$1, $$2}'

# ------------------------------------------------------------------------------
# Git Operations
# ------------------------------------------------------------------------------

check-clean: ## Check if there are uncommitted changes
	@echo "$(YELLOW)Checking for uncommitted changes...$(RESET)"
	@git diff-index --quiet HEAD -- || (echo "$(RED)Error: Uncommitted changes detected. Commit or stash them first.$(RESET)" && exit 1)
	@echo "$(GREEN)Clean.$(RESET)"

merge-main: check-clean ## Merge current branch into main and push
	$(eval BRANCH := $(shell git branch --show-current))
	@if [ "$(BRANCH)" == "main" ]; then \
		echo "$(RED)Error: You are already on main.$(RESET)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Merging $(BRANCH) into main...$(RESET)"
	git checkout main
	git pull origin main
	git merge "$(BRANCH)"
	git push origin main
	@echo "$(GREEN)Successfully merged $(BRANCH) into main and pushed.$(RESET)"
	@# Optional: switch back to the original branch
	@# git checkout "$(BRANCH)"

# ------------------------------------------------------------------------------
# Build
# ------------------------------------------------------------------------------

build-for-ios:
	/Users/atacan/Developer/Repositories/agent-files/scripts/build_and_summarize.sh --platform ios AppFeature

build-for-macos:
	/Users/atacan/Developer/Repositories/agent-files/scripts/build_and_summarize.sh AppFeature

# ------------------------------------------------------------------------------
# Code Quality
# ------------------------------------------------------------------------------

format: check-clean ## Run swift-format on Sources and Tests
	@echo "$(YELLOW)Formatting Swift files...$(RESET)"
	@which swift-format > /dev/null || (echo "$(RED)swift-format not found.$(RESET)" && exit 1)
	@find $(SWIFT_FORMAT_TARGETS) -name "*.swift" -not -path "*/GeneratedSources/*" \
		| xargs swift-format $(SWIFT_FORMAT_OPTIONS)
	@git add .
	@echo "$(GREEN)Formatting complete. Changes staged.$(RESET)"

en-xcloc:
	xcodebuild -exportLocalizations -localizationPath ./localisations/ -exportLanguage en -sdk iphoneos17.0

move-xcloc: check_uncommitted
	unzip -o ~/Downloads/export.zip -d ./localisations/
	# remove the zip file so that the new download will have the same name
	rm ~/Downloads/export.zip

import-xcloc: check_uncommitted
	for lang in de nl fr it ja pl pt es tr sq zh ko ru; do \
		if [ -d "./localisations/$$lang.xcloc/" ]; then \
			xcodebuild -importLocalizations -localizationPath ./localisations/$$lang.xcloc/ -sdk iphoneos17.0 ; \
		else \
			echo "Directory ./localisations/$$lang.xcloc/ does not exist." ; \
		fi ; \
	done
