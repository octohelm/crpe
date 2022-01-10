import 'dart:io';

import 'package:crpe/registry/remote/remote.dart';
import 'package:crpe/registry/schema/distribution.dart' show Digest;
import 'package:crpe/registry/schema/manifest.dart';
import 'package:filesize/filesize.dart';
import 'package:logr/logr.dart';
import 'package:logr/stdlogr.dart';
import 'package:roundtripper/roundtripper.dart';
import 'package:test/test.dart';

var logger = Logger(StdLogSink("client"));

main() async {
  var ctx = Logger.withLogger(logger);
  runWith<T>(T Function() action) => () => ctx.run(action);

  group("docker", () {
    var rc = RegistryRemote(RegistryRemoteOptions(
      endpoint: "https://registry-1.docker.io",
      username: Platform.environment["DOCKER_USERNAME"],
      password: Platform.environment["DOCKER_PASSWORD"],
    ));

    test("flow", runWith(() async {
      await rc.apiCheck();
      await rc.apiCheck();
      var manifest = await rc.manifest("library/nginx", "alpine");
      print(manifest.type());
      print(manifest.references());
    }));
  });

  group("custom", () {
    var rc = RegistryRemote(RegistryRemoteOptions(
      endpoint: Platform.environment["CUSTOM_DOCKER_ENDPOINT"] ?? "",
      username: Platform.environment["CUSTOM_DOCKER_USERNAME"],
      password: Platform.environment["CUSTOM_DOCKER_PASSWORD"],
    ));

    test("apiCheck", runWith(() async {
      await rc.apiCheck();
    }));

    test("manifest & blob", runWith(() async {
      try {
        var manifestList = await rc.manifest(
          "docker.io/library/nginx",
          "alpine",
        ) as ManifestListSpec;

        var m = manifestList.manifests.firstWhere(
          (m) => m.platform?.architecture == "arm64",
        );

        var manifest = await rc.manifest(
          "docker.io/library/nginx",
          m.digest.toString(),
        ) as ManifestSpec;

        {
          var configBlob = await rc.blob(
            "docker.io/library/nginx",
            manifest.config.digest!,
          );

          expect(
            Digest.fromBytes(await configBlob.blob()),
            manifest.config.digest!,
          );
        }

        {
          var layer = manifest.layers.first;

          var respBlob = await rc.blob(
            "docker.io/library/nginx",
            layer.digest!,
          );

          var file = File("./lib/registry/client/__tests__/blob");

          var downloaded = 0;
          var f = file.openWrite();

          await respBlob.responseBody.takeWhile((data) {
            downloaded += data.length;
            return downloaded < 1024 * 1024;
          }).pipe(f);

          var fi = await file.stat();

          logger.info(
              "continue downloaded ${filesize(downloaded)} ${filesize(fi.size)}/${filesize(layer.size)}");

          respBlob = await rc.blob(
            "docker.io/library/nginx",
            layer.digest!,
            start: fi.size,
            end: layer.size,
          );

          f = file.openWrite(mode: FileMode.append);
          await respBlob.responseBody.pipe(f);

          fi = await file.stat();

          logger.info("done ${filesize(fi.size)}/${filesize(layer.size)}");

          {
            var f2 = file.openRead();
            expect(
              await Digest.fromStream(f2),
              layer.digest!,
            );
          }
        }
      } on ResponseException catch (e) {
        logger.error(e, e.response?.headers);
      }
    }));
  });
}
