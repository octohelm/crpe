COMMIT_SHA ?= $(shell git rev-parse --short HEAD)
NAMESPACES ?= docker.io/octohelm
PUSH ?= true
TAG ?= dev

PLATFORMS ?= linux/arm64

DOCKER_BUILDX_BUILD = docker buildx build \
	--label=org.opencontainers.image.source=https://github.com/octohelm/crpe \
	--label=org.opencontainers.image.revision=$(COMMIT_SHA) \
	--platform=$(PLATFORMS)

ifeq ($(PUSH),true)
	DOCKER_BUILDX_BUILD := $(DOCKER_BUILDX_BUILD) --push
endif

up:
	STORAGE_ROOT=./.tmp/registry \
		dart run ./packages/registry/bin/registry.dart

PUB_HOSTED_URL ?= https://pub.dartlang.org
FLUTTER_STORAGE_BASE_URL ?= https://storage.googleapis.com

dockerx.registry:
	$(DOCKER_BUILDX_BUILD) \
		--build-arg=PUB_HOSTED_URL=${PUB_HOSTED_URL} \
       	--build-arg=FLUTTER_STORAGE_BASE_URL=${FLUTTER_STORAGE_BASE_URL} \
		$(foreach namespace,$(NAMESPACES),--tag=$(namespace)/registry:$(TAG)) \
		--file=packages/registry/bin/Dockerfile .

#  max build number 2147483647
#                    220217115
# time build number  22011218n
#                     y m d H n=M/6
# each 6 minute could only one build
BUILD_NUMBER=$(shell TZ=UTC-8 date +%y%m%d%H)$(shell TZ=UTC-8 echo `expr $$(date +%M) / 6`)

bootstrap:
	dart pub global activate melos && melos bootstrap

gen:
	melos generate

build.android:
	melos build:crpeapp:android

build.ios:
	melos build:crpeapp:ios

clean:
	melos clean

fmt:
	melos format