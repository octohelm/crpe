import 'dart:convert';
import 'dart:io';

import 'package:crpe/extension.dart';
import 'package:crpe/registry.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tar/tar.dart';

import 'digest_meta.dart';
import 'progress.dart';

part '__generated__/kubepkg.freezed.dart';
part '__generated__/kubepkg.g.dart';

@freezed
class KubePkgSpec with _$KubePkgSpec {
  factory KubePkgSpec({
    required String version,
    required Map<String, String> images,
    required Map<String, Map<String, dynamic>> manifests,
  }) = _KubePkgSpec;

  factory KubePkgSpec.fromJson(Map<String, dynamic> json) =>
      _KubePkgSpec.fromJson(json);
}

@freezed
class KubePkgStatus with _$KubePkgStatus {
  factory KubePkgStatus({
    Digest? tgzDigest,
    List<DigestMeta>? digests,
  }) = _KubePkgStatus;

  factory KubePkgStatus.fromJson(Map<String, dynamic> json) =>
      _KubePkgStatus.fromJson(json);
}

@freezed
class KubePkgMetadata with _$KubePkgMetadata {
  factory KubePkgMetadata({
    required String name,
    @Default("default") String? namespace,
    Map<String, String>? labels,
    Map<String, String>? annotations,
  }) = _KubePkgMetadata;

  factory KubePkgMetadata.fromJson(Map<String, dynamic> json) =>
      _KubePkgMetadata.fromJson(json);
}

const _apiVersion = "octohelm.tech/v1alpha1";
const _kind = "KubePkg";

@freezed
class KubePkg with _$KubePkg {
  KubePkg._();

  static const annotationPlatforms = "octohelm.tech/platforms";

  factory KubePkg({
    @Default(_apiVersion) String apiVersion,
    @Default(_kind) String kind,
    required KubePkgMetadata metadata,
    required KubePkgSpec spec,
    KubePkgStatus? status,
  }) = _KubePkg;

  factory KubePkg.fromJson(Map<String, dynamic> json) => _KubePkg.fromJson({
        ...json,
        "apiVersion": _apiVersion,
      });

  String toYamlRaw() {
    var buf = StringBuffer("");

    for (var m in spec.manifests.values) {
      buf.writeln("---");
      buf.writeln(m.toYaml());
      buf.writeln("");
    }

    return buf.toString();
  }

  KubePkg withPlatforms(List<String> platforms) {
    return copyWith(
      metadata: metadata.copyWith(
        annotations: {
          ...?metadata.annotations,
          annotationPlatforms: platforms.join(","),
        },
      ),
    );
  }

  List<String> get platforms {
    return metadata.annotations?[annotationPlatforms]?.split(",") ??
        [
          "linux/amd64",
          "linux/arm64",
        ];
  }

  Future<KubePkg> resolveDigests(Registry registry) async {
    if (status?.digests?.isNotEmpty ?? false) {
      return this;
    }

    Map<Digest, DigestMeta> digests = {};

    // for helm installer
    // await _resolveImageRef(registry, digests, helmInstaller, "");

    for (var name in spec.images.keys) {
      await _resolveImageRef(
        registry,
        digests,
        name,
        spec.images[name]!,
      );
    }

    return copyWith(
      status: (status ?? KubePkgStatus()).copyWith(
        digests: digests.values.toList(),
      ),
    );
  }

  Future _resolveImageRef(
    Registry registry,
    Map<Digest, DigestMeta> state,
    String ref,
    String maybeDigest,
  ) async {
    // maybe @sha256
    var nameAndDigest = ref.split("@");
    if (nameAndDigest.length == 2) {
      return await _resolveImage(
        registry,
        state,
        nameAndDigest[0],
        digest: Digest.parse(nameAndDigest[1]),
      );
    }
    var nameAndTag = ref.split(":");
    if (nameAndTag.length == 2) {
      return await _resolveImage(
        registry,
        state,
        nameAndTag[0],
        tag: nameAndTag[1],
        digest:
            (maybeDigest != "").ifTrueOrNull(() => Digest.parse(maybeDigest)),
      );
    }
    return;
  }

  Future _resolveImage(
    Registry registry,
    Map<Digest, DigestMeta> state,
    String name, {
    Digest? digest,
    String? tag,
  }) async {
    var resp = await registry.repository(name);

    // resolve tag
    if (digest == null) {
      var t = tag ?? "latest";
      var d = await resp.tags().get(t);
      await _resolveManifestDigest(
        resp,
        state,
        d.digest!,
        tag: tag,
      );
      return;
    }

    await _resolveManifestDigest(
      resp,
      state,
      digest,
      tag: tag,
    );
  }

  Future _resolveManifestDigest(
    Repository repo,
    Map<Digest, DigestMeta> state,
    Digest digest, {
    String? tag,
    String? platform,
  }) async {
    var m = await repo.manifests().get(digest);

    var dm = DigestMeta.manifest(
      repo.name,
      digest,
      size: m.jsonRaw().length,
      tag: tag,
      platform: platform,
    );

    state[dm.digest] = dm;

    if (m is ManifestListSpec) {
      for (var sub in m.references()) {
        var normalizedPlatform = sub.platform!.normalize();
        if (platforms.contains(normalizedPlatform)) {
          await _resolveManifestDigest(
            repo,
            state,
            sub.digest!,
            platform: normalizedPlatform,
          );
        }
      }
    }

    if (m is ManifestSpec) {
      for (var l in m.references()) {
        var dm = DigestMeta.blob(
          repo.name,
          l.digest!,
          size: l.size!,
        );
        state[dm.digest] = dm;
      }
    }
  }

  List<int> get jsonRaw {
    return JsonEncoder.withIndent("  ").convert(this).codeUnits;
  }

  // # <kubepkg>.tar
  // blobs/<alg>/<hash>
  // kubepkg.json
  Future<Stream<List<int>>> tgz$(
    Registry registry, {
    Sink<Progress>? process$,
  }) async {
    Map<String, TarEntry> entries = {};

    var raw = jsonRaw;

    var kubpkgJson = TarEntry.data(
      TarHeader(
        name: "kubepkg.json",
        mode: int.parse('644', radix: 8),
      ),
      raw,
    );

    var p = Progress.fromIterable(status?.digests ?? []).incrTotal(raw.length);

    entries[kubpkgJson.header.name] = kubpkgJson;

    for (DigestMeta sd in status?.digests ?? []) {
      var r = await registry.repository(sd.name);

      var header = TarHeader(
        name: "blobs/${sd.digest.toString().replaceAll(":", "/")}",
        mode: int.parse('644', radix: 8),
      );

      var blob = await r.blobs().openRead(sd.digest);

      if (!entries.containsKey(header.name)) {
        entries[header.name] = TarEntry(header, blob.doOnData((data) {
          process$?.add(p = p.incrComplete(data.length));
        }));
      }
    }

    return Stream.fromIterable(entries.values)
        .transform(tarWriter)
        .transform(gzip.encoder);
  }

  String get tgzFileName {
    return "${metadata.name}@${spec.version}.tgz";
  }

  Stream<List<int>> helmTgz$() {
    // helm
    List<TarEntry> entries = [];

    var addFile = (String filename, String content) {
      entries.add(TarEntry.data(
        TarHeader(
          name: filename,
          mode: int.parse('644', radix: 8),
        ),
        utf8.encode(content),
      ));
    };

    var name = metadata.name;

    addFile(
        "${name}/Chart.yaml",
        ({
          "apiVersion": "v2",
          "name": metadata.name,
          "version": spec.version,
          "appVersion": spec.version
        }).toYaml());

    addFile("${name}/values.yaml", ({}).toYaml());

    for (var k in spec.manifests.keys) {
      addFile(
        "${name}/templates/${_safeFileName(k)}.yaml",
        spec.manifests[k]!.toYaml(),
      );
    }

    final entries$ = Stream.fromIterable(entries);

    return entries$.transform(tarWriter).transform(gzip.encoder);
  }

  KubePkg withTgzDigest(Digest? tgzDigest) {
    return copyWith(
      status: (status ?? KubePkgStatus()).copyWith(
        tgzDigest: tgzDigest,
      ),
    );
  }

  bool get tgzCreated {
    return status?.tgzDigest != null;
  }
}

String _safeFileName(String s) {
  return s.replaceAll("/", "__").toLowerCase();
}
