import 'dart:async';

import 'package:registry/schema/distribution.dart';
import 'package:registry/schema/errorcodes.dart';

import 'interfaces.dart';

class StoreManifest implements ManifestService {
  final BlobService blobService;
  String name;

  StoreManifest({
    required this.name,
    required this.blobService,
  });

  @override
  Future<Digest> put(digest, manifest) async {
    var file = await blobService.openWrite(digest);
    await Stream.fromIterable([manifest.jsonRaw()])
        .map((bytes) => bytes.toList())
        .pipe(file);
    file.close();
    return digest;
  }

  @override
  Future<bool> exists(digest) async {
    try {
      await blobService.stat(digest);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Manifest> get(digest) async {
    try {
      var raw = await blobService.get(digest);
      return Manifest.fromManifestJsonRaw(name, digest, raw);
    } catch (e) {
      throw ErrManifestUnknownRevision(
        name: name,
        revision: digest,
      );
    }
  }

  @override
  Future<void> delete(Digest digest) {
    return blobService.delete(digest);
  }
}