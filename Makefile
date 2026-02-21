# =============================================================================
# LocalSip Build System
# Builds all images from vendored source with patches applied at source level.
# No external registry pulls needed.
# =============================================================================
#
# Usage:
#   make build                  # Build everything
#   make build-somleng          # Build individual image
#   make push                   # Push all images to registry
#
# Variables:
#   IMAGE_PREFIX     - Image name prefix (default: localsip)
#   REGISTRY         - Registry to push to (default: empty for local)
#   SIGNALWIRE_TOKEN - Required for FreeSWITCH build (SignalWire package access)
#   TAG              - Image tag (default: latest)
# =============================================================================

IMAGE_PREFIX     ?= localsip
REGISTRY         ?=
TAG              ?= latest
SIGNALWIRE_TOKEN ?=
BUILD_DIR        := .build

# For local builds: localsip/somleng:latest
# For registry pushes: REGISTRY/somleng:latest
ifneq ($(REGISTRY),)
  FULL_PREFIX := $(REGISTRY)
else
  FULL_PREFIX := $(IMAGE_PREFIX)
endif

# =============================================================================
# Submodule check — fail fast if vendor source is missing
# =============================================================================

.PHONY: check-submodules
check-submodules:
	@if [ ! -f vendor/somleng/Gemfile ]; then \
		echo "ERROR: vendor/somleng/ is empty. Run: git submodule update --init --recursive"; \
		exit 1; \
	fi
	@if [ ! -f vendor/somleng-switch/components/app/Gemfile ]; then \
		echo "ERROR: vendor/somleng-switch/ is empty. Run: git submodule update --init --recursive"; \
		exit 1; \
	fi

# =============================================================================
# Prepare — copy vendor source and apply patches into .build/
# =============================================================================

.PHONY: prepare-somleng
prepare-somleng: check-submodules
	@rm -rf $(BUILD_DIR)/somleng
	@mkdir -p $(BUILD_DIR)/somleng
	@cp -a vendor/somleng/. $(BUILD_DIR)/somleng/
	@# Overlay patches into source
	@cp -r somleng_patches/app $(BUILD_DIR)/somleng/
	@cp -r somleng_patches/config $(BUILD_DIR)/somleng/
	@cp -r somleng_patches/db $(BUILD_DIR)/somleng/
	@# Inject SIP trunk routes (perl for macOS/Linux portability)
	@perl -i -pe 'print "        resources :sip_trunks, only: %i[index create show update destroy]\n" if /resources :phone_numbers, only:.*index create show update destroy/' \
		$(BUILD_DIR)/somleng/config/routes.rb
	@echo "Prepared somleng source with patches in $(BUILD_DIR)/somleng/"

.PHONY: prepare-switch
prepare-switch: check-submodules
	@rm -rf $(BUILD_DIR)/switch
	@mkdir -p $(BUILD_DIR)/switch
	@cp -a vendor/somleng-switch/components/app/. $(BUILD_DIR)/switch/
	@# Apply patches directly into source
	@cp call_controller_patch.rb $(BUILD_DIR)/switch/app/call_controllers/call_controller.rb
	@cp dial_string_patch.rb $(BUILD_DIR)/switch/app/models/dial_string.rb
	@cp gateway_manager_patch.rb $(BUILD_DIR)/switch/app/web/gateway_manager.rb
	@echo "Prepared switch source with patches in $(BUILD_DIR)/switch/"

.PHONY: prepare
prepare: prepare-somleng prepare-switch

# =============================================================================
# Build images — from patched source using upstream Dockerfiles
# =============================================================================

.PHONY: build-somleng
build-somleng: prepare-somleng
	docker build -t $(FULL_PREFIX)/somleng:$(TAG) $(BUILD_DIR)/somleng/

.PHONY: build-switch
build-switch: prepare-switch
	docker build -t $(FULL_PREFIX)/switch:$(TAG) $(BUILD_DIR)/switch/

.PHONY: build-freeswitch
build-freeswitch: check-submodules
ifndef SIGNALWIRE_TOKEN
	$(error SIGNALWIRE_TOKEN is required for FreeSWITCH build. Sign up free at https://signalwire.com and get a Personal Access Token)
endif
	docker build -t $(FULL_PREFIX)/freeswitch:$(TAG) \
		--build-arg signalwire_token=$(SIGNALWIRE_TOKEN) \
		vendor/somleng-switch/components/freeswitch/

.PHONY: build-rating-engine
build-rating-engine: check-submodules
	docker build -t $(FULL_PREFIX)/rating-engine:$(TAG) \
		--target debug \
		vendor/somleng-switch/components/rating_engine/

# =============================================================================
# Composite targets
# =============================================================================

.PHONY: build
build: build-somleng build-switch build-freeswitch build-rating-engine

# Build without FreeSWITCH (when SIGNALWIRE_TOKEN is not available)
.PHONY: build-no-fs
build-no-fs: build-somleng build-switch build-rating-engine

# =============================================================================
# Push images to a registry
# =============================================================================

IMAGES := somleng switch freeswitch rating-engine

.PHONY: push
push:
ifndef REGISTRY
	$(error REGISTRY is required for push. Example: make push REGISTRY=123456789.dkr.ecr.ap-southeast-1.amazonaws.com)
endif
	@for img in $(IMAGES); do \
		echo "Pushing $(FULL_PREFIX)/$$img:$(TAG)..."; \
		docker push $(FULL_PREFIX)/$$img:$(TAG); \
	done

.PHONY: tag-and-push
tag-and-push:
ifndef REGISTRY
	$(error REGISTRY is required. Example: make tag-and-push REGISTRY=123456789.dkr.ecr.ap-southeast-1.amazonaws.com)
endif
	@for img in $(IMAGES); do \
		docker tag $(IMAGE_PREFIX)/$$img:$(TAG) $(FULL_PREFIX)/$$img:$(TAG); \
		docker push $(FULL_PREFIX)/$$img:$(TAG); \
	done

# =============================================================================
# Utilities
# =============================================================================

.PHONY: submodules
submodules:
	git submodule update --init --recursive

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)
	@for img in $(IMAGES); do \
		docker rmi $(FULL_PREFIX)/$$img:$(TAG) 2>/dev/null || true; \
	done

.PHONY: help
help:
	@echo "LocalSip Build System"
	@echo ""
	@echo "Targets:"
	@echo "  build              Build all images (needs SIGNALWIRE_TOKEN)"
	@echo "  build-no-fs        Build all except FreeSWITCH"
	@echo "  build-somleng      Build patched Somleng API"
	@echo "  build-switch       Build patched Switch app"
	@echo "  build-freeswitch   Build FreeSWITCH (needs SIGNALWIRE_TOKEN)"
	@echo "  build-rating-engine Build rating engine"
	@echo "  prepare            Prepare source with patches (no docker build)"
	@echo "  push               Push images to REGISTRY"
	@echo "  submodules         Initialize git submodules"
	@echo "  clean              Remove build dir and images"
	@echo ""
	@echo "Variables:"
	@echo "  IMAGE_PREFIX       Image prefix (default: localsip)"
	@echo "  REGISTRY           Registry for push (e.g., 123456.dkr.ecr.region.amazonaws.com)"
	@echo "  SIGNALWIRE_TOKEN   Required for FreeSWITCH build"
	@echo "  TAG                Image tag (default: latest)"
