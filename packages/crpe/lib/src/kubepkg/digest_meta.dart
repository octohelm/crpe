import 'package:crpe/src/registry.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part '__generated__/digest_meta.freezed.dart';
part '__generated__/digest_meta.g.dart';

enum DigestType {
  manifest,
  blob,
}

@freezed
class DigestMeta with _$DigestMeta {
  DigestMeta._();

  factory DigestMeta.manifest(
    String name,
    Digest digest, {
    required int size,
    String? tag,
    String? platform,
  }) {
    return DigestMeta(
      type: DigestType.manifest,
      name: name,
      digest: digest,
      platform: platform,
      size: size,
      tag: tag,
    );
  }

  factory DigestMeta.blob(
    String name,
    Digest digest, {
    required int size,
  }) {
    return DigestMeta(
      type: DigestType.blob,
      name: name,
      digest: digest,
      size: size,
    );
  }

  factory DigestMeta({
    required Digest digest,
    required DigestType type,
    required String name,
    required int size,
    String? tag,
    String? platform,
  }) = _DigestMeta;

  factory DigestMeta.fromJson(Map<String, dynamic> json) =>
      _DigestMeta.fromJson(json);
}
