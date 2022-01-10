TS_NODE=node --experimental-specifier-resolution=node --loader=ts-node/esm
PUB=flutter pub

gen.watch:
	$(PUB) run build_runner watch --delete-conflicting-outputs

gen:
	$(PUB) run build_runner build --delete-conflicting-outputs


#  max build number 2147483647
#                    220217115
# time build number  22011218n
#                     y m d H n=M/6
# each 6 minute could only one build
BUILD_NUMBER=$(shell TZ=UTC-8 date +%y%m%d%H)$(shell TZ=UTC-8 echo `expr $$(date +%M) / 6`)

build.android:
	flutter build apk --release \
		--target ./lib/app/main.dart \
		--target-platform android-arm64 \
		--split-per-abi \
		--build-number=$(BUILD_NUMBER)
	ls -lh ./build/app/outputs/apk/release
	cat ./build/app/outputs/apk/release/latest.json

build.ios:
	flutter build ios --release \
		--target ./lib/app/main.dart \
		--build-number=$(BUILD_NUMBER)

clean:
	flutter clean

fmt:
	dart format ./lib

dep: dep.flutter
install: install.flutter

dep.flutter:
	$(PUB) upgrade

install.flutter:
	$(PUB) get

up.registry: build.registry
	dartaotruntime ./build/registry.dart.snapshot

build.registry:
	dart compile aot-snapshot \
		-o ./build/registry.dart.snapshot \
		./bin/registry.dart

up.docker.registry:
	docker compose up