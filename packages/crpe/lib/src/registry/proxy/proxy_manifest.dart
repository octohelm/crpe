import 'package:roundtripper/roundtripper.dart';

import 'package:crpe/src/registry/core.dart';
import 'package:crpe/src/registry/remote.dart';
import 'package:crpe/src/registry/schema.dart';

class ProxyManifest implements ManifestService {
  RegistryRemote remote;
  ManifestService local;
  String name;

  ProxyManifest({
    required this.name,
    required this.remote,
    required this.local,
  });

  @override
  Future<bool> exists(digest) async {
    try {
      return await local.exists(digest);
    } catch (e) {
      try {
        return (await remote.existsManifest(name, digest.toString())) != "";
      } on ResponseException catch (e) {
        if (e.statusCode == HttpStatus.notFound) {
          throw ErrManifestUnknownRevision(name: name, revision: digest);
        }
        rethrow;
      }
    }
  }

  @override
  Future<Manifest> get(digest) async {
    try {
      return await local.get(digest);
    } catch (e) {
      var m = await remote.getManifest(name, tagOrDigest: digest.toString());
      await local.put(digest, m);
      return m;
    }
  }

  @override
  Future<void> delete(digest) async {
    return;
  }

  @override
  Future<Digest> put(digest, manifest) async {
    return digest;
  }
}
