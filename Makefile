#############################################################################
# Copyright 2026 IHP-Open-PDK Authors
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#############################################################################

SHELL := /bin/bash
.DEFAULT_GOAL := _usage

GNUGCAP_INC ?= $(shell gnucap-conf --includedir 2>/dev/null || printf %s /usr/local/include/gnucap)
GNUGCAP_VAMS ?= gnucap-mg-vams
GNUCAP ?= gnucap
GNUPLOT ?= gnuplot
TIMEOUT ?= 60
LOG_DIR ?= logs/root

OTA_DIR := models/ota
SOURCE_ROOTS := Chapter03 Chapter04 Chapter05 AppendixA common $(OTA_DIR)
CLOCK_DIR := common/clock

ALL_BUILD_DIRS := $(shell find $(SOURCE_ROOTS) -type f -name build.sh -printf '%h\n' 2>/dev/null | sort -u)
PROJECT_DIRS := $(filter-out $(CLOCK_DIR),$(ALL_BUILD_DIRS))
TEST_FILES := $(shell find $(SOURCE_ROOTS) -type f -name '*_tb.gc' 2>/dev/null | sort)
PLOT_FILES := $(shell find $(SOURCE_ROOTS) -type f -name '*.gp' 2>/dev/null | sort)
WORK_DIRS := $(shell find $(SOURCE_ROOTS) -type f \( -name build.sh -o -name '*_tb.gc' -o -name '*.gp' \) -printf '%h\n' 2>/dev/null | sort -u)

.PHONY: _usage build test plot ota clear

_usage:
	@echo "Gnucap - The Designer's Guide to Verilog-AMS examples"
	@echo
	@echo "Listings present in this repository:"
	@for root in Chapter03 Chapter04 Chapter05 AppendixA; do \
	  echo; \
	  echo "$$root:"; \
	  for listing in $$(find "$$root" -mindepth 1 -maxdepth 1 -type d -name 'Listing*' | sort); do \
	    name=$$(basename "$$listing"); \
	    modules=$$(find "$$listing" -mindepth 1 -maxdepth 1 -type d -printf '%f ' | sed 's/ $$//'); \
	    if [ -n "$$modules" ]; then printf "  %-10s %s\n" "$$name" "$$modules"; else printf "  %s\n" "$$name"; fi; \
	  done; \
	done
	@echo
	@echo "Common module:"
	@echo "  common/clock"
	@echo
	@echo "Usage:"
	@echo "  make build   Compile common/clock first, then all Listing modules"
	@echo "  make test    Run all *_tb.gc testbenches"
	@echo "  make plot    Generate plots from all .gp files"
	@echo "  make ota     Build and run the OTA example"
	@echo "  make clear   Remove generated .so, result .txt, plot .pdf, and log files"
	@echo
	@echo "Recommended order: make build -> make test -> make plot"
	@echo "For one Listing, enter its module directory and use ./build.sh and ./run.sh."

build:
	@mkdir -p "$(LOG_DIR)/build" "$(LOG_DIR)/test" "$(LOG_DIR)/plot"; \
	for d in $(WORK_DIRS); do mkdir -p "$$d/results" "$$d/plots"; done; \
	pass=0; fail=0; \
	run_build() { \
	  d="$$1"; \
	  key=$${d//\//__}; \
	  log="$(LOG_DIR)/build/$$key.log"; \
	  echo "BUILD $$d"; \
	  (cd "$$d" && GNUGCAP_INC="$(GNUGCAP_INC)" GNUGCAP_VAMS="$(GNUGCAP_VAMS)" ./build.sh) >"$$log" 2>&1; \
	  rc=$$?; \
	  if [ $$rc -eq 0 ] && ! grep -Eq 'unresolved symbol:|error:|No such file|plugin not found' "$$log"; then \
	    echo "  PASS"; \
	    pass=$$((pass+1)); \
	  else \
	    echo "  FAIL (see $$log)"; \
	    fail=$$((fail+1)); \
	  fi; \
	}; \
	run_build "$(CLOCK_DIR)"; \
	for d in $(PROJECT_DIRS); do run_build "$$d"; done; \
	echo "Build summary: PASS=$$pass FAIL=$$fail"; \
	test $$fail -eq 0

test:
	@mkdir -p "$(LOG_DIR)/build" "$(LOG_DIR)/test" "$(LOG_DIR)/plot"; \
	for d in $(WORK_DIRS); do mkdir -p "$$d/results" "$$d/plots"; done; \
	pass=0; fail=0; \
	for tb in $(TEST_FILES); do \
	  d=$$(dirname "$$tb"); \
	  f=$$(basename "$$tb"); \
	  key=$${d//\//__}; \
	  log="$(LOG_DIR)/test/$$key.log"; \
	  echo "TEST $$tb"; \
	  rm -f "$$d"/results/*.txt 2>/dev/null || true; \
	  (cd "$$d" && timeout "$(TIMEOUT)" "$(GNUCAP)" "$$f") >"$$log" 2>&1; \
	  rc=$$?; \
	  bad=0; \
	  if [ $$rc -ne 0 ]; then bad=1; fi; \
	  if grep -Eq 'zero time step|invalid nodes|no candidates found|no valid prototype found|unresolved symbol:|did not converge|non-recoverable' "$$log"; then bad=1; fi; \
	  if [ $$bad -eq 0 ]; then \
	    echo "  PASS"; \
	    pass=$$((pass+1)); \
	  else \
	    echo "  FAIL/BLOCKED (see $$log)"; \
	    fail=$$((fail+1)); \
	  fi; \
	done; \
	echo "Test summary: PASS=$$pass FAIL/BLOCKED=$$fail"; \
	test $$fail -eq 0

plot:
	@mkdir -p "$(LOG_DIR)/build" "$(LOG_DIR)/test" "$(LOG_DIR)/plot"; \
	for d in $(WORK_DIRS); do mkdir -p "$$d/results" "$$d/plots"; done; \
	pass=0; fail=0; \
	for gp in $(PLOT_FILES); do \
	  d=$$(dirname "$$gp"); \
	  f=$$(basename "$$gp"); \
	  key=$${d//\//__}; \
	  log="$(LOG_DIR)/plot/$${key}__$${f}.log"; \
	  echo "PLOT $$gp"; \
	  (cd "$$d" && "$(GNUPLOT)" "$$f") >"$$log" 2>&1; \
	  rc=$$?; \
	  if [ $$rc -eq 0 ]; then \
	    echo "  PASS"; \
	    pass=$$((pass+1)); \
	  else \
	    echo "  FAIL (see $$log)"; \
	    fail=$$((fail+1)); \
	  fi; \
	done; \
	echo "Plot summary: PASS=$$pass FAIL=$$fail"; \
	test $$fail -eq 0

ota:
	@cd "$(OTA_DIR)" && GNUGCAP_INC="$(GNUGCAP_INC)" GNUGCAP_VAMS="$(GNUGCAP_VAMS)" GNUCAP="$(GNUCAP)" GNUPLOT="$(GNUPLOT)" ./run.sh

clear:
	@find $(SOURCE_ROOTS) -type f -name '*.so' -delete; \
	rm -f common/clock/clk.txt common/clock/clk.pdf; \
	find $(SOURCE_ROOTS) -type d \( -name results -o -name plots \) -prune -exec rm -rf {} +; \
	rm -rf logs; \
	echo "Generated files and generated directories removed."
