import 'dart:convert';
import 'dart:io';

import 'package:crpe/kubepkg.dart';
import 'package:crpe/registry.dart';
import 'package:crpe/registryserver.dart';
import 'package:filesize/filesize.dart';
import 'package:logr/logr.dart';
import 'package:logr/stdlogr.dart';
import 'package:path/path.dart' as path;
import 'package:rxdart/rxdart.dart';
import "package:test/test.dart";

var logger = Logger(StdLogSink("mirror"));

void main() async {
  var ctx = Logger.withLogger(logger);
  runWith<T>(T Function() action) => () => ctx.run(action);

  var registryEndpoint = Uri.parse(
    Platform.environment["CUSTOM_DOCKER_ENDPOINT"] ?? "",
  ).replace(
    userInfo: [
      Platform.environment["CUSTOM_DOCKER_USERNAME"],
      Platform.environment["CUSTOM_DOCKER_PASSWORD"],
    ].join(":"),
  );

  var registryLocal = RegistryLocal("../../.tmp/crpe");
  var registryRemote = RegistryRemote(
    RegistryRemoteOptions.fromUri(registryEndpoint.toString()),
  );

  var registryProxy = RegistryProxy(
    local: registryLocal,
    remote: registryRemote,
  );

  var kubepkg = KubePkg.fromJson(
    jsonDecode(
      await File("./test/testdata/kubepkg.json").readAsString(),
    ),
  );

  var kubepkgRegistry = KubePkgRegistry.fromRegistryLocal(registryLocal);

  test("create pkg", runWith(() async {
    var resolvedPkg = await kubepkg.resolveDigests(registryProxy);

    var p$ = PublishSubject<Progress>();

    p$.listen((p) {
      print("packing ${filesize(p.complete)}/${filesize(p.total)}");
    });

    var tgz$ = await resolvedPkg.tgz$(
      registryProxy,
      process$: p$,
    );

    try {
      await tgz$.pipe(
        File(path.join(
          registryLocal.base.path,
          kubepkg.tgzFileName,
        )).openWrite(),
      );
    } catch (e) {
      print(e);
    }
  }), timeout: Timeout(Duration(minutes: 5)));

  group("install", () {
    var f = File(path.join(
      registryLocal.base.path,
      kubepkg.tgzFileName,
    ));

    test("install kubepkg.tgz", runWith(() async {
      await kubepkgRegistry.install(
        f.openRead(),
        local: registryLocal,
      );
    }));

    test("install kubepkg.tgz again", runWith(() async {
      var d = await Digest.fromStream(f.openRead());

      await kubepkgRegistry.install(
        f.openRead(),
        local: registryLocal,
        digest: d,
      );
    }));
  });

  test("helm tgz", runWith(() async {
    var f = File(".tmp/demo.tgz");
    await f.create(recursive: true);
    await kubepkg.helmTgz$().pipe(f.openWrite());
  }));

  test("debug", runWith(() async {
    var d = Digest(
      hash: "0c77e78c933bed2feba19206badd54ef8b261c433bdaa6afad48d8db6053e9e5",
    );

    var desc = await kubepkgRegistry.stat(d);
    var tgzFile$ = await kubepkgRegistry.openRead(d);

    var f = File("../../.tmp/crpe/demo.kubupkg.tgz");
    await f.create(recursive: true);
    await tgzFile$.pipe(f.openWrite());

    var p$ = PublishSubject<Progress>();

    p$.listen((p) {
      print("packing ${filesize(p.complete)}/${filesize(p.total)}");
    });

    tgzFile$ = await kubepkgRegistry.openRead(d);
    await NodeAdapter(port: 6060).upload(
      "0.0.0.0",
      d,
      tgzFile$,
      size: desc.size,
      process$: p$,
    );
  }));
}
