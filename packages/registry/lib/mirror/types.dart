import 'package:registry/schema/distribution.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part '__generated__/types.freezed.dart';
part '__generated__/types.g.dart';

@freezed
class RegistryMirrorOptions with _$RegistryMirrorOptions {
  RegistryMirrorOptions._();

  factory RegistryMirrorOptions({
    @Default(["linux/amd64", "linux/arm64"]) List<String>? platforms,
  }) = _RegistryMirrorOptions;

  factory RegistryMirrorOptions.fromJson(Map<String, dynamic> json) =>
      _RegistryMirrorOptions.fromJson(json);
}

enum MirrorJobType {
  manifest,
  blob,
}

enum MirrorJobStage {
  todo,
  doing,
  success,
  failed,
}

@freezed
class MirrorJob with _$MirrorJob {
  MirrorJob._();

  static manifest(
    String name,
    Digest digest, {
    String? tag,
    String? platform,
    List<int>? raw,
  }) {
    return MirrorJob(
      type: MirrorJobType.manifest,
      name: name,
      digest: digest,
      stage: MirrorJobStage.todo,
      platform: platform,
      tag: tag,
      raw: raw,
    );
  }

  static blob(
    String name,
    Digest digest, {
    int? size,
  }) {
    return MirrorJob(
      type: MirrorJobType.blob,
      name: name,
      digest: digest,
      stage: MirrorJobStage.todo,
      size: size,
    );
  }

  factory MirrorJob({
    required String name,
    required MirrorJobStage stage,
    required MirrorJobType type,
    required Digest digest,
    // children
    List<Digest>? children,
    // manifest
    String? tag,
    List<int>? raw,
    String? platform,
    // blob
    int? size,
    int? complete,
    // when failed
    String? error,
  }) = _MirrorJob;

  factory MirrorJob.fromJson(Map<String, dynamic> json) =>
      MirrorJob.fromJson(json);
}
