import 'package:registry/core/interfaces.dart';
import 'package:registry/remote/remote.dart';

import 'proxy_blob.dart';
import 'proxy_manifest.dart';
import 'proxy_tag.dart';

class ProxyRegistry implements Registry {
  RegistryRemote remote;
  Registry registry;

  ProxyRegistry({
    required this.remote,
    required this.registry,
  });

  @override
  Future<Repository> repository(name) async {
    return ProxyRepository(
      local: await registry.repository(name),
      client: remote,
    );
  }
}

class ProxyRepository implements Repository {
  RegistryRemote client;
  Repository local;

  ProxyRepository({
    required this.client,
    required this.local,
  });

  @override
  String get name => local.name;

  @override
  BlobService blobs() {
    return ProxyBlob(
      name: name,
      client: client,
      local: local.blobs(),
    );
  }

  @override
  ManifestService manifests() {
    return ProxyManifest(
      name: name,
      remote: client,
      local: local.manifests(),
    );
  }

  @override
  TagService tags() {
    return ProxyTag(
      name: name,
      client: client,
      local: local.tags(),
    );
  }
}
