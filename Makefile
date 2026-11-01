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
.PHONY: build run test pkg dmg clean

build:
	$(SWIFT) build --product $(PRODUCT)

test:
	$(SWIFT) test

run:
	$(SWIFT) run $(PRODUCT)

pkg:
	$(SHELL) ./scripts/package.sh

dmg: pkg
	rm -rf "$(DMG_STAGING)"
	mkdir -p "$(DMG_STAGING)/licenses"
	ditto "$(APP_BUNDLE)" "$(DMG_STAGING)/$(PRODUCT).app"
	cp LICENSE.txt "$(DMG_STAGING)/LICENSE.txt"
	rm -f "$(DMG_IMAGE)"
	diskutil image create from --format UDZO --volumeName "$(PRODUCT)" "$(DMG_STAGING)" "$(DMG_IMAGE)"
	rm -rf "$(DMG_STAGING)"

clean:
	$(SWIFT) package clean
	rm -rf "$(APP_BUNDLE)" "$(DMG_IMAGE)" "$(DMG_STAGING)"
