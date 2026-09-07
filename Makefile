SHELL := /bin/sh

PRODUCT ?= default
MODULE ?= entry
BUNDLE ?= com.yenole.hiplus
ABILITY ?= EntryAbility
DEVICE ?=

DEVECO_HOME ?= /Applications/DevEco-Studio.app/Contents
HVIGORW ?= $(if $(wildcard $(DEVECO_HOME)/tools/hvigor/bin/hvigorw),$(DEVECO_HOME)/tools/hvigor/bin/hvigorw,hvigorw)
HDC ?= $(if $(wildcard $(DEVECO_HOME)/sdk/default/openharmony/toolchains/hdc),$(DEVECO_HOME)/sdk/default/openharmony/toolchains/hdc,hdc)
HAP := $(MODULE)/build/default/outputs/$(PRODUCT)/$(MODULE)-$(PRODUCT)-signed.hap
HDC_TARGET := $(if $(DEVICE),-t "$(DEVICE)")

.PHONY: help build install launch deploy

help:
	@printf '%s\n' \
		'make build                 Build the signed HAP' \
		'make install               Install the HAP on the connected device' \
		'make launch                Launch the application on the device' \
		'make deploy                Build, install, and launch on the device' \
		'make deploy DEVICE=<id>    Select a device when multiple devices are connected'

build:
	DEVECO_SDK_HOME="$(DEVECO_HOME)/sdk" HARMONYOS_SDK_HOME="$(DEVECO_HOME)/sdk" $(HVIGORW) assembleHap --mode module -p product=$(PRODUCT)

install: build
	@test -f "$(HAP)" || { printf '%s\n' "HAP not found: $(HAP)" >&2; exit 1; }
	$(HDC) $(HDC_TARGET) install -r "$(HAP)"

launch:
	$(HDC) $(HDC_TARGET) shell aa start -a $(ABILITY) -b $(BUNDLE)

deploy: install launch
