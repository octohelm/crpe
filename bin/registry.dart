import 'dart:io';

import 'package:crpe/registry/proxy/proxy.dart';
import 'package:crpe/registry/registry.dart';
import 'package:crpe/registry/remote/registry_remote.dart';
import 'package:crpe/registry/remote/remote.dart';
import 'package:logr/logr.dart';
import 'package:logr/stdlogr.dart';

var l = Logger(StdLogSink("crpe"));

void main() async {
  var ss = await ServerSocket.bind(InternetAddress.anyIPv4, 6000);

  l.info("registry serve on ${ss.address.host}:${ss.port}");

  var rc = RegistryRemote(RegistryRemoteOptions(
    endpoint: Platform.environment["CUSTOM_DOCKER_ENDPOINT"] ?? "",
    username: Platform.environment["CUSTOM_DOCKER_USERNAME"],
    password: Platform.environment["CUSTOM_DOCKER_PASSWORD"],
  ));

  var registry = ProxyRegistry(
    registry: LocalRegistry("./tmp/registry"),
    remote: rc,
  );

  RegistryRoutes.serve(
    HttpServer.listenOn(ss),
    registry,
    l,
  );
}
