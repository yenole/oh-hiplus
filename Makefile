SHELL := /bin/sh

PRODUCT ?= default
MODULE ?= entry
BUNDLE ?= com.yenole.hiplus
ABILITY ?= EntryAbility
DEVICE ?=

DEVECO_HOME ?= /Applications/DevEco-Studio.app/Contents
SDK_HOME ?= $(DEVECO_HOME)/sdk
NODE ?= $(DEVECO_HOME)/tools/node/bin/node
HVIGORW ?= $(DEVECO_HOME)/tools/hvigor/bin/hvigorw.js
HDC ?= $(if $(wildcard $(SDK_HOME)/default/openharmony/toolchains/hdc),$(SDK_HOME)/default/openharmony/toolchains/hdc,hdc)
HAP := $(MODULE)/build/default/outputs/$(PRODUCT)/$(MODULE)-$(PRODUCT)-signed.hap
HDC_TARGET := $(if $(DEVICE),-t "$(DEVICE)")

.PHONY: help build clean rebuild install launch deploy

help:
	@printf '%s\n' \
		'make build                 Build the signed HAP' \
		'make install               Install the HAP on the connected device' \
		'make launch                Launch the application on the device' \
		'make deploy                Build, install, and launch on the device' \
		'make deploy DEVICE=<id>    Select a device when multiple devices are connected'

build:
	DEVECO_SDK_HOME="$(SDK_HOME)" HARMONYOS_SDK_HOME="$(SDK_HOME)" JAVA_HOME="$(DEVECO_HOME)/jbr/Contents/Home" NODE_HOME="$(DEVECO_HOME)/tools/node" PATH="$(DEVECO_HOME)/tools/hvigor/bin:$(DEVECO_HOME)/jbr/Contents/Home/bin:$(DEVECO_HOME)/tools/node/bin:$(DEVECO_HOME)/tools/arktsdoc/bin:$(DEVECO_HOME)/tools/ohpm/bin:$(PATH)" $(NODE) "$(HVIGORW)" --mode module -p module=$(MODULE)@default -p product=$(PRODUCT) -p requiredDeviceType=phone assembleHap --analyze=normal --parallel --incremental --no-daemon

clean:
	rm -rf "$(MODULE)/build" .hvigor/cache .hvigor/outputs

rebuild: clean build

# Install the HAP already built by DevEco Studio; do not trigger CLI signing here.
install:
	@test -f "$(HAP)" || { printf '%s\n' "HAP not found: $(HAP)" >&2; exit 1; }
	$(HDC) $(HDC_TARGET) install -r "$(HAP)"

launch:
	$(HDC) $(HDC_TARGET) shell aa start -a $(ABILITY) -b $(BUNDLE)

deploy: build install launch
