import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'statuserror.dart';

part "__generated__/digest.freezed.dart";
part "__generated__/digest.g.dart";

class Digest {
  final String alg;
  final String hash;

  Digest({
    required this.hash,
    this.alg = "sha256",
  });

  factory Digest.fromBytes(List<int> bytes) {
    return Digest(
      hash: sha256.convert(bytes).toString(),
    );
  }

  static Future<Digest> fromStream(Stream<List<int>> input$) async {
    return Digest(
      hash: (await input$.transform(sha256).first).toString(),
    );
  }

  factory Digest.parse(String digest) {
    var parts = digest.split(":");
    if (parts.length != 2) {
      throw ErrDigestInvalid(digest: digest);
    }
    return Digest(alg: parts.first, hash: parts.last);
  }

  static Future<Digest> fromLinkFile(File f) async {
    return Digest.parse(await f.readAsString());
  }

  Future<File> putLinkFile(File f) async {
    if (!await f.exists()) {
      await f.create(recursive: true);
    }
    return await f.writeAsString(toString());
  }

  factory Digest.fromJson(String digest) => Digest.parse(digest);

  String toJson() {
    return toString();
  }

  @override
  String toString() {
    return "$alg:$hash";
  }

  @override
  int get hashCode => toString().hashCode;

  @override
  bool operator ==(Object other) {
    return other is Digest && other.hashCode == hashCode;
  }
}

@freezed
class ErrDigestInvalid with _$ErrDigestInvalid implements StatusError {
  ErrDigestInvalid._();

  factory ErrDigestInvalid({
    required String digest,
  }) = _ErrDigestInvalid;

  factory ErrDigestInvalid.fromJson(json) => _ErrDigestInvalid.fromJson(json);

  @override
  int get status => HttpStatus.notFound;

  @override
  String get code => "DIGEST_INVALID";

  @override
  String toString() => "unknown digest=$digest";
}
