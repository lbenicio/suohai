# Makefile for the Suohai menu bar app

# Binaries
SWIFT ?= swift
SHELL := /bin/bash

# Project
PRODUCT := Suohai

# Paths
APP_BUNDLE := .build/$(PRODUCT).app
DMG_IMAGE := .build/$(PRODUCT).dmg
DMG_STAGING := .build/dmg-staging

# Targets
.DEFAULT_GOAL := pkg
.PHONY: help build run test pkg dmg clean

help: ## Show available targets.
	@printf 'Usage: make <target>\n\nTargets:\n'
	@awk 'BEGIN { FS = ":.*##" } /^[a-zA-Z0-9_-]+:.*##/ { printf "  %-10s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

build: ## Build the Swift package executable.
	$(SWIFT) build --product $(PRODUCT)

test: ## Run the Swift package tests.
	$(SWIFT) test

run: ## Run the menu bar app.
	$(SWIFT) run $(PRODUCT)

pkg: ## Create the macOS app bundle.
	$(SHELL) ./scripts/package.sh

dmg: pkg ## Create the app disk image.
	rm -rf "$(DMG_STAGING)"
	mkdir -p "$(DMG_STAGING)/licenses"
	ditto "$(APP_BUNDLE)" "$(DMG_STAGING)/$(PRODUCT).app"
	cp LICENSE.txt "$(DMG_STAGING)/LICENSE.txt"
	rm -f "$(DMG_IMAGE)"
	diskutil image create from --format UDZO --volumeName "$(PRODUCT)" "$(DMG_STAGING)" "$(DMG_IMAGE)"
	rm -rf "$(DMG_STAGING)"

clean: ## Remove SwiftPM and generated app/disk-image artifacts.
	$(SWIFT) package clean
	rm -rf "$(APP_BUNDLE)" "$(DMG_IMAGE)" "$(DMG_STAGING)"
