FROM --platform=${BUILDPLATFORM} dart:2.16.1-sdk AS setup

ARG PUB_HOSTED_URL=https://pub.dartlang.org
ARG FLUTTER_STORAGE_BASE_URL=https://storage.googleapis.com

WORKDIR /app

COPY ./packages/registry .

ENV PUB_CACHE=/app/.cache

RUN dart pub get
RUN dart run build_runner build --delete-conflicting-outputs

FROM dart:2.16.1-sdk AS builder

ENV PUB_CACHE=/app/.cache

COPY --from=setup /app /app

WORKDIR /app

RUN dart compile exe -o ./registry ./bin/registry.dart

FROM scratch
COPY --from=builder /runtime/ /
COPY --from=builder /app/registry /bin/registry

ENV REGISTRY_PORT=6060

ENV REMOTE_DOCKER_ENDPOINT=""
ENV REMOTE_DOCKER_USERNAME=""
ENV REMOTE_DOCKER_PASSWORD=""
ENV STORAGE_ROOT="/etc/registry"

EXPOSE 6060

ENTRYPOINT ["/bin/registry"]


