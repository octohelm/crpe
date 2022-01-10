import 'dart:io';

import 'package:crpe/registry.dart';
import 'package:crpe/registryserver.dart';
import 'package:logr/logr.dart';
import 'package:logr/stdlogr.dart';

var logger = Logger(StdLogSink("crpe"));

String? getEnv(List<String> keys) {
  for (var key in keys) {
    var v = Platform.environment[key];
    if (v != null) {
      return v;
    }
  }
  return null;
}

var remote = RegistryRemote(RegistryRemoteOptions(
  endpoint: getEnv(["REMOTE_DOCKER_ENDPOINT", "CUSTOM_DOCKER_ENDPOINT"]) ?? "",
  username: getEnv(["REMOTE_DOCKER_USERNAME", "CUSTOM_DOCKER_USERNAME"]),
  password: getEnv(["REMOTE_DOCKER_PASSWORD", "CUSTOM_DOCKER_PASSWORD"]),
));

void main() async {
  var storageRoot = getEnv(["STORAGE_ROOT"]) ?? "/etc/registry";
  var deviceID = getEnv(["DEVICE_ID"]) ?? "dev";
  var platforms = getEnv(["PLATFORMS"]) ?? "linux/arm64";

  var registryPort = int.parse(getEnv(["PORT"]) ?? "6000");

  var ss = await ServerSocket.bind(InternetAddress.anyIPv4, registryPort);

  var local = RegistryLocal(storageRoot);

  RegistryRoutes.serve(
    HttpServer.listenOn(ss),
    local: local,
    meta: NodeMeta(
      ip: "",
      id: deviceID,
      platforms: platforms.split(","),
    ),
    remote: remote,
    logger: logger,
  );
}
