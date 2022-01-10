import 'dart:convert';
import 'dart:io';

import 'package:crpe/registry.dart';
import 'package:path/path.dart' as path;
import 'package:tar/tar.dart';

import 'digest_meta.dart';
import 'kubepkg.dart';

class KubePkgRegistry {
  factory KubePkgRegistry.fromRegistryLocal(RegistryLocal local) =>
      KubePkgRegistry(
        Directory(path.join(local.base.absolute.path, "kubepkg")),
      );

  Directory workspace;

  KubePkgRegistry(this.workspace);

  Future<List<KubePkg>> list() async {
    var root = Directory(path.join(workspace.absolute.path, "_installed"));

    try {
      List<KubePkg> list = [];

      var currentFiles = await root.list();
      var files = await currentFiles.toList();

      for (var i = 0; i < files.length; i++) {
        var file = files[i];

        var content = await File(file.absolute.path).readAsString();

        var kubePkg = KubePkg.fromJson(jsonDecode(content));

        list.add(kubePkg);
      }

      return list;
    } catch (e) {}

    return [];
  }

  StoreBlob? _blob;

  StoreBlob get blob {
    _blob ??= StoreBlob(workspace);
    return _blob!;
  }

  Future<Stream<List<int>>> openRead(Digest tgzDigest, {int? start, int? end}) {
    return blob.openRead(tgzDigest, start: start, end: end);
  }

  Future<Descriptor> stat(Digest tgzDigest) {
    return blob.stat(tgzDigest);
  }

  Future install(
    Stream<List<int>> tgz$, {
    required RegistryLocal local,
    Digest? digest,
  }) async {
    var d = await upload(
      tgz$,
      digest: digest,
    );

    var kubePkg = await extractTo(
      await blob.openRead(d),
      local,
      tgzDigest: d,
    );

    var f =
        (PathPkgInstalledLink(kubePkg.metadata.name).path(workspace) as File);
    await f.create(recursive: true);
    await f.writeAsBytes(kubePkg.jsonRaw);
  }

  Future<KubePkg> extractTo(
    Stream<List<int>> tgz$,
    RegistryLocal local, {
    required Digest tgzDigest,
  }) async {
    KubePkg? kubePkg;
    Map<Digest, DigestMeta>? digests;

    await TarReader.forEach(tgz$.transform(gzip.decoder), (entry) async {
      if (entry.header.name.endsWith("kubepkg.json")) {
        kubePkg = KubePkg.fromJson(
          jsonDecode(await entry.contents.transform(utf8.decoder).join()),
        );
      }

      if (entry.header.name.contains("blobs/")) {
        if (kubePkg == null) {
          throw Exception(
              "invalid kubepkg.tgz, kubepkg.json must at first before all");
        }

        digests ??= (kubePkg!.status?.digests?.reversed ?? [])
            .fold({}, (ret, e) => {...?ret, e.digest: e});

        var parts = entry.header.name.split("/").reversed.toList();
        var sd = digests![Digest(hash: parts[0], alg: parts[1])]!;
        var repo = await local.repository(sd.name);

        await repo.blobs().upload(entry.contents, digest: sd.digest);

        if (sd.tag != null) {
          await repo.tags().tag(
                sd.tag!,
                Descriptor(
                  digest: sd.digest,
                ),
              );
        }
      }
    });

    if (kubePkg == null) {
      throw Exception("invalid kubepkg.tgz, missing kubepkg.json");
    }

    return kubePkg!;
  }

  Future link(PathSpec pathSpec, Digest digest) async {
    var p = pathSpec.path(workspace) as File;
    await p.create(recursive: true);
    p.writeAsString(digest.toString());
  }

  Future<Digest> upload(
    Stream<List<int>> inputs, {
    Digest? digest,
    String? uuid,
  }) async {
    return await blob.upload(inputs, uuid: uuid, digest: digest);
  }
}

class PathPkgInstalledLink implements PathSpec {
  String name;

  PathPkgInstalledLink(this.name);

  @override
  FileSystemEntity path(Directory root) {
    return File("${root.path}/_installed/${name}.json");
  }
}
