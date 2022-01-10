import 'dart:convert';
import 'dart:io';

import 'package:crpe/registry/core/core.dart';
import 'package:crpe/registry/mirror/mirror.dart';
import 'package:crpe/registry/mirror/syncer.dart';
import 'package:crpe/registry/mirror/types.dart';
import 'package:crpe/registry/remote/remote.dart';
import 'package:logr/logr.dart';
import 'package:logr/stdlogr.dart';
import "package:rxdart/rxdart.dart";
import "package:test/test.dart";

var logger = Logger(StdLogSink("mirror"));

void main() {
  var ctx = Logger.withLogger(logger);
  runWith<T>(T Function() action) => () => ctx.run(action);

  var rc = RegistryRemote(RegistryRemoteOptions(
    endpoint: Platform.environment["CUSTOM_DOCKER_ENDPOINT"] ?? "",
    username: Platform.environment["CUSTOM_DOCKER_USERNAME"],
    password: Platform.environment["CUSTOM_DOCKER_PASSWORD"],
  ));

  var r = LocalRegistry("./tmp/registry");

  var mirror = RegistryMirror(r, rc, options: RegistryMirrorOptions());

  test("Syncer", runWith(() async {
    var syncer = Syncer(mirror);

    syncer.statuses$.bufferTime(const Duration(seconds: 1)).listen((jobList) {
      if (jobList.isEmpty) {
        return;
      }

      for (var job in jobList.last.values) {
        print(jsonEncode(job));
      }

      var allDone = jobList.last.values
          .where((job) =>
              job.stage == MirrorJobStage.todo ||
              job.stage == MirrorJobStage.doing)
          .isEmpty;

      if (allDone) {
        syncer.close();
      }
    });

    syncer.start();

    syncer.add(
      "docker.io/library/nginx",
      tag: "alpine",
    );

    syncer.add(
      "docker.io/querycapistio/proxyv2",
      tag: "1.13.0-distroless",
    );

    return await syncer.done$.first;
  }));
}
