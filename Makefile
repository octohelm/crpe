PKG ?= github.com/octohelm/crpe
COMMIT_SHA ?= $(shell git rev-parse --short HEAD)
TAG ?= dev

TARGET ?= crpe
ENTRYPOINT ?=./packages/$(TARGET)/bin

PLATFORMS ?= linux/arm64

up:
	PORT=6060 \
	PLATFORMS=$(PLATFORMS) \
	STORAGE_ROOT=./.tmp/crpe \
		dart run ./${ENTRYPOINT}/crpe.dart serve

PUB_HOSTED_URL ?= https://pub.dartlang.org
FLUTTER_STORAGE_BASE_URL ?= https://storage.googleapis.com

bootstrap:
	dart pub global activate pubtidy
	dart pub global activate melos
	melos bootstrap

tidy:
	melos exec -c 1 -- "pubtidy"

gen:
	melos generate

dep:
	melos dep

clean:
	melos clean

fmt:
	melos format

#  max build number 2147483647
#                    220217115
# time build number  22011218n
#                     y m d H n=M/6
# each 6 minute could only one build
BUILD_NUMBER=$(shell TZ=UTC-8 date +%y%m%d%H)$(shell TZ=UTC-8 echo `expr $$(date +%M) / 6`)

build.android:
	BUILD_NUMBER=$(BUILD_NUMBER) melos build:crpeapp:android

build.ios:
	BUILD_NUMBER=$(BUILD_NUMBER) melos build:crpeapp:ios
