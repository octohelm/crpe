import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

import 'digest.dart';
import 'distribution.dart';

part '__generated__/manifest.freezed.dart';
part '__generated__/manifest.g.dart';

var acceptedManifests = [
  OCIMediaType.ImageIndex,
  OCIMediaType.ImageManifest,
  MediaType.ManifestList,
  MediaType.Manifest,
];

abstract class OCIMediaType {
  static const Descriptor = "application/vnd.oci.descriptor.v1+json";
  static const LayoutHeader = "application/vnd.oci.layout.header.v1+json";
  static const ImageManifest = "application/vnd.oci.image.manifest.v1+json";
  static const ImageIndex = "application/vnd.oci.image.index.v1+json";
  static const ImageLayer = "application/vnd.oci.image.layer.v1.tar";
  static const ImageLayerGzip = "application/vnd.oci.image.layer.v1.tar+gzip";
  static const ImageLayerNonDistributable =
      "application/vnd.oci.image.layer.nondistributable.v1.tar";
  static const ImageLayerNonDistributableGzip =
      "application/vnd.oci.image.layer.nondistributable.v1.tar+gzip";
  static const ImageConfig = "application/vnd.oci.image.config.v1+json";
}

abstract class MediaType {
  static const Manifest =
      "application/vnd.docker.distribution.manifest.v2+json";
  static const ManifestList =
      "application/vnd.docker.distribution.manifest.list.v2+json";
  static const ImageConfig = "application/vnd.docker.container.image.v1+json";
  static const PluginConfig = "application/vnd.docker.plugin.v1+json";
  static const Layer = "application/vnd.docker.image.rootfs.diff.tar.gzip";
  static const ForeignLayer =
      "application/vnd.docker.image.rootfs.foreign.diff.tar.gzip";
  static const UncompressedLayer =
      "application/vnd.docker.image.rootfs.diff.tar";
}

@freezed
class ManifestSpec with _$ManifestSpec implements Manifest {
  ManifestSpec._();

  factory ManifestSpec({
    @Default(2) int schemaVersion,
    @Default(MediaType.Manifest) String mediaType,
    required Descriptor config,
    required List<Descriptor> layers,
    required Map<String, String>? annotations, // oci only

    @JsonKey(ignore: true) Digest? digest,
    @JsonKey(ignore: true) List<int>? raw,
  }) = _ManifestSpec;

  factory ManifestSpec.fromJson(Map<String, dynamic> json) =>
      _ManifestSpec.fromJson(json);

  @override
  String type() {
    return mediaType;
  }

  @override
  List<Descriptor> references() {
    return [
      config,
      ...layers,
    ];
  }

  @override
  List<int> jsonRaw() {
    return raw ?? utf8.encode(jsonEncode(this));
  }
}

@freezed
class ManifestListSpec with _$ManifestListSpec implements Manifest {
  ManifestListSpec._();

  factory ManifestListSpec({
    @Default(2) int schemaVersion,
    @Default(OCIMediaType.ImageIndex) String mediaType,
    required List<Descriptor> manifests,
    @JsonKey(ignore: true) Digest? digest,
    @JsonKey(ignore: true) List<int>? raw,
  }) = _ManifestListSpec;

  factory ManifestListSpec.fromJson(Map<String, dynamic> json) =>
      _ManifestListSpec.fromJson(json);

  @override
  List<Descriptor> references() {
    return [...manifests];
  }

  @override
  String type() {
    return mediaType;
  }

  @override
  List<int> jsonRaw() {
    return raw ?? utf8.encode(jsonEncode(this));
  }
}

@freezed
class ManifestPlatform with _$ManifestPlatform {
  ManifestPlatform._();

  factory ManifestPlatform({
    required String architecture,
    required String os,
    String? variant,
    List<String>? features,
    @JsonKey(name: "os.version") String? osVersion,
    @JsonKey(name: "os.features") List<String>? osFeatures,
  }) = _ManifestPlatform;

  factory ManifestPlatform.fromJson(Map<String, dynamic> json) =>
      _ManifestPlatform.fromJson(json);

  String normalize() {
    return [
      normalizeOS(os),
      ...normalizeArch(architecture, variant ?? ""),
    ].join("/");
  }
}

String normalizeOS(String os) {
  os = os.toLowerCase();

  switch (os) {
    case "macos":
      return "darwin";
  }

  return os;
}

List<String> normalizeArch(String arch, String variant) {
  arch = arch.toLowerCase();
  variant = variant.toLowerCase();

  switch (arch) {
    case "i386":
      arch = "386";
      variant = "";
      break;
    case "x86_64":
    case "x86-64":
      arch = "amd64";
      variant = "";
      break;
    case "aarch64":
    case "arm64":
      arch = "arm64";
      switch (variant) {
        case "8":
        case "v8":
          variant = "";
      }
      break;
    case "armhf":
      arch = "arm";
      variant = "v7";
      break;
    case "armel":
      arch = "arm";
      variant = "v6";
      break;
    case "arm":
      switch (variant) {
        case "":
        case "7":
          variant = "v7";
          break;
        case "5":
        case "6":
        case "8":
          variant = "v$variant";
          break;
      }
  }

  if (variant == "") {
    return [arch];
  }

  return [arch, variant];
}
