import 'dart:io' show HttpStatus;

import 'package:freezed_annotation/freezed_annotation.dart';

import 'digest.dart';
import 'statuserror.dart';

part '__generated__/errorcodes.freezed.dart';
part '__generated__/errorcodes.g.dart';

@freezed
class ErrTagUnknown with _$ErrTagUnknown implements StatusError {
  ErrTagUnknown._();

  factory ErrTagUnknown({
    required String tag,
  }) = _ErrTagUnknown;

  factory ErrTagUnknown.fromJson(json) => _ErrTagUnknown.fromJson(json);

  @override
  int get status => HttpStatus.notFound;

  @override
  String get code => "TAG_INVALID";

  @override
  String toString() => "unknown tag=$tag";
}

@freezed
class ErrRepositoryUnknown with _$ErrRepositoryUnknown implements StatusError {
  ErrRepositoryUnknown._();

  factory ErrRepositoryUnknown({
    required String name,
  }) = _ErrRepositoryUnknown;

  factory ErrRepositoryUnknown.fromJson(json) =>
      _ErrRepositoryUnknown.fromJson(json);

  @override
  int get status => HttpStatus.notFound;

  @override
  String get code => "NAME_INVALID";

  @override
  String toString() => "unknown repository name=$name";
}

@freezed
class ErrManifestUnknown with _$ErrManifestUnknown implements StatusError {
  ErrManifestUnknown._();

  factory ErrManifestUnknown({
    required String name,
    required String tag,
  }) = _ErrManifestUnknown;

  factory ErrManifestUnknown.fromJson(json) =>
      _ErrManifestUnknown.fromJson(json);

  @override
  int get status => HttpStatus.notFound;

  @override
  String get code => "MANIFEST_UNKNOWN";

  @override
  String toString() => "unknown manifest name=$name tag=$tag";
}

@freezed
class ErrBlobUnknown with _$ErrBlobUnknown implements StatusError {
  ErrBlobUnknown._();

  factory ErrBlobUnknown({
    required Digest digest,
  }) = _ErrBlobUnknown;

  factory ErrBlobUnknown.fromJson(json) => _ErrBlobUnknown.fromJson(json);

  @override
  int get status => HttpStatus.notFound;

  @override
  String get code => "BLOB_UNKNOWN";

  @override
  String toString() => "unknown blob digest=$digest";
}

@freezed
class ErrManifestUnknownRevision
    with _$ErrManifestUnknownRevision
    implements StatusError {
  ErrManifestUnknownRevision._();

  factory ErrManifestUnknownRevision({
    required String name,
    Digest? revision,
  }) = _ErrManifestUnknownRevision;

  factory ErrManifestUnknownRevision.fromJson(json) =>
      _ErrManifestUnknownRevision.fromJson(json);

  @override
  int get status => HttpStatus.notFound;

  @override
  String get code => "MANIFEST_UNKNOWN";

  @override
  String toString() => "unknown manifest name=$name revision=$revision";
}

@freezed
class ErrManifestUnverified
    with _$ErrManifestUnverified
    implements StatusError {
  ErrManifestUnverified._();

  factory ErrManifestUnverified({
    required String name,
    required String manifest,
  }) = _ErrManifestUnverified;

  factory ErrManifestUnverified.fromJson(json) =>
      _ErrManifestUnverified.fromJson(json);

  @override
  int get status => HttpStatus.badRequest;

  @override
  String get code => "MANIFEST_INVALID";

  @override
  String toString() => "unverified manifest name=$name manifest=$manifest";
}
