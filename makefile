SHELL         := /usr/bin/env bash
.DEFAULT_GOAL := current

BASE_PATH      := .
BUILD_PATH     := ./build
DATA_PATH      := ./data
CORE_PATH      := ./core

REQUIRED_PACKAGES := \
  binutils \
  debootstrap \
  squashfs-tools \
  xorriso \
  grub-pc-bin \
  grub-efi-amd64 \
  grub2-common \
  mtools \
  dosfstools

.PHONY: all fast current clean bootstrap help

help:
	@printf "%-20s %s\n" "Command" "Description"
	@printf "%-20s %s\n" "-------" "-----------"
	@printf "%-20s %s\n" "make" "Construct default language"
	@printf "%-20s %s\n" "make all" "Construct every language"
	@printf "%-20s %s\n" "make fast" "Construct quick config languages"
	@printf "%-20s %s\n" "make clean" "Eliminate build remnants"
	@printf "%-20s %s\n" "make bootstrap" "Verify setup and install prerequisites"

bootstrap:
	@if [ "$$(id -u)" -eq 0 ]; then \
	  echo "Error: Avoid executing as root user"; \
	  exit 1; \
	fi
	@if ! lsb_release -i | grep -qE "(Ubuntu|Debian|EDYOUOS)"; then \
	  echo "Error: Incompatible operating system — supports Ubuntu, Debian, or EDYOUOS only"; \
	  exit 1; \
	fi

	@absent="" ; \
	for package in $(REQUIRED_PACKAGES); do \
	  if ! dpkg -s $$package >/dev/null 2>&1; then \
	    absent="$$absent $$package"; \
	  fi; \
	done; \
	if [ -n "$$absent" ]; then \
	  echo "Uninstalled packages:$$absent"; \
	  echo "Proceeding with installation of missing components..."; \
	  sudo apt-get update && sudo apt-get install -y$$absent; \
	else \
	  echo "[MAKE] All necessary packages are present."; \
	fi

current: bootstrap
	@echo "[MAKE] Constructing default language variant..."
	@cd $(BUILD_PATH) && ./build.sh

all: bootstrap
	@echo "[MAKE] Constructing ALL language variants (all.json)..."
	@./build_all.sh -c $(DATA_PATH)/all.json

fast: bootstrap
	@echo "[MAKE] Constructing FAST language variants (fast.json)..."
	@./build_all.sh -c $(DATA_PATH)/fast.json

clean:
	@echo "[MAKE] Eliminating build remnants..."
	@./clean_all.sh
	@echo "[MAKE] Cleanup finished."