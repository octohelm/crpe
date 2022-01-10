import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

import 'digest.dart';
import 'errorcodes.dart';
import 'manifest.dart';
import 'platform.dart';

export 'digest.dart';
export 'platform.dart';

part '__generated__/distribution.freezed.dart';
part '__generated__/distribution.g.dart';

@freezed
class Descriptor with _$Descriptor {
  factory Descriptor({
    String? mediaType,
    Digest? digest,
    int? size,
    List<String>? urls,
    Map<String, String>? annotations,
    Platform? platform,
  }) = _Descriptor;

  static fromDigest(Digest digest) => Descriptor(digest: digest);

  factory Descriptor.fromJson(Map<String, dynamic> s) =>
      _Descriptor.fromJson(s);
}

abstract class Manifest {
  String type();

  Digest? get digest;

  List<Descriptor> references();

  List<int> jsonRaw();

  static Manifest fromManifestJsonRaw(
    String name,
    Digest digest,
    List<int> jsonRaw,
  ) {
    var json = jsonDecode(utf8.decode(jsonRaw));

    if (json["mediaType"] == null ||
        (json["schemaVersion"] == null || json["schemaVersion"] != 2)) {
      throw ErrManifestUnverified(
        name: name,
        manifest: jsonEncode(json),
      );
    }

    switch (json["mediaType"] ?? "") {
      case MediaType.ManifestList:
      case OCIMediaType.ImageIndex:
      case "": // mediaType of oci could be empty  https://github.com/opencontainers/image-spec/blob/main/image-index.md
        return ManifestListSpec.fromJson(json).copyWith(
          digest: digest,
          raw: jsonRaw,
        );
      case MediaType.Manifest:
      case OCIMediaType.ImageManifest:
        return ManifestSpec.fromJson(json).copyWith(
          digest: digest,
          raw: jsonRaw,
        );
      default:
        throw ErrManifestUnverified(
          name: name,
          manifest: jsonEncode(json),
        );
    }
  }
}
