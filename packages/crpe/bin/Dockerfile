FROM --platform=${BUILDPLATFORM} dart:2.16.1-sdk AS setup

ARG PUB_HOSTED_URL=https://pub.dartlang.org
ARG FLUTTER_STORAGE_BASE_URL=https://storage.googleapis.com

WORKDIR /app

COPY ./packages/crpe .

ENV PUB_CACHE=/app/.cache

RUN dart pub get
RUN dart run build_runner build --delete-conflicting-outputs

FROM dart:2.16.1-sdk AS builder

ENV PUB_CACHE=/app/.cache

COPY --from=setup /app /app

WORKDIR /app

ARG TARGETARCH
RUN dart compile exe -o ./crpe-linux-${TARGETARCH} ./bin/crpe.dart

FROM scratch

COPY --from=builder /runtime/ /

ARG TARGETARCH
COPY --from=builder /app/crpe-linux-${TARGETARCH} /bin/crpe


ENV REMOTE_DOCKER_ENDPOINT=""
ENV REMOTE_DOCKER_USERNAME=""
ENV REMOTE_DOCKER_PASSWORD=""

ARG TARGETPLATFORM
ENV PLATFORMS=${TARGETPLATFORM}
ENV PORT=6060

# mount ${STORAGE_ROOT}/docker for container registry
ENV STORAGE_ROOT="/etc/crpe"

EXPOSE 6060

CMD ["serve"]
ENTRYPOINT ["/bin/crpe"]


