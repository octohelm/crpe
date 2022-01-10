import 'dart:io';

import 'package:crpe/registry/core/core.dart';
import 'package:crpe/registry/remote/remote.dart';
import 'package:crpe/registry/schema/distribution.dart';
import 'package:crpe/registry/schema/errorcodes.dart';
import 'package:roundtripper/roundtripper.dart';

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
        return await remote.existsManifest(name, digest.toString());
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
      var m = await remote.getManifest(name, digest.toString());
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
