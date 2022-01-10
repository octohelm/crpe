import 'dart:io';

import 'package:logr/logr.dart';
import 'package:logr/stdlogr.dart';
import 'package:registry/proxy/proxy.dart';
import 'package:registry/registry.dart';
import 'package:registry/remote/registry_remote.dart';
import 'package:registry/remote/remote.dart';

var l = Logger(StdLogSink("crpe"));

String? getEnv(List<String> keys) {
  for (var key in keys) {
    var v = Platform.environment[key];
    if (v != null) {
      return v;
    }
  }
  return null;
}

var rr = RegistryRemote(RegistryRemoteOptions(
  endpoint: getEnv(["REMOTE_DOCKER_ENDPOINT", "CUSTOM_DOCKER_ENDPOINT"]) ?? "",
  username: getEnv(["REMOTE_DOCKER_USERNAME", "CUSTOM_DOCKER_USERNAME"]),
  password: getEnv(["REMOTE_DOCKER_PASSWORD", "CUSTOM_DOCKER_PASSWORD"]),
));

void main() async {
  var storageRoot = getEnv(["STORAGE_ROOT"]) ?? "/etc/registry";
  var registryPort = int.parse(getEnv(["REGISTRY_PORT"]) ?? "6000");

  var ss = await ServerSocket.bind(InternetAddress.anyIPv4, registryPort);

  Registry registry = LocalRegistry(storageRoot);

  if (rr.options.endpoint != "") {
    registry = ProxyRegistry(
      registry: registry,
      remote: rr,
    );

    l.info("remote fallback (${rr.options.endpoint}) enabled.");
  }

  RegistryRoutes.serve(
    HttpServer.listenOn(ss),
    registry,
    l,
  );
}
